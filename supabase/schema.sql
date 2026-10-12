-- YouDumb accounts + global leaderboard.
-- Run this once in Supabase: Dashboard → SQL Editor → New query → paste → Run.
-- Players never write tables directly: every score goes through the functions below, which check the input.

-- ───────── Tables ─────────
create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  username text not null unique check (username ~ '^[A-Za-z0-9_]{3,16}$'),
  created_at timestamptz not null default now()
);

create table if not exists public.progress (
  user_id uuid not null references public.profiles on delete cascade,
  arena text not null check (arena in ('mix','logic','math','apt','biz','street','words','data','code')),
  levels jsonb not null default '{}'::jsonb,           -- {"1":3,"2":2,...} best stars per level
  stars int not null default 0 check (stars between 0 and 90),
  updated_at timestamptz not null default now(),
  primary key (user_id, arena)
);

create table if not exists public.star_events (       -- feeds the weekly board
  id bigserial primary key,
  user_id uuid not null references public.profiles on delete cascade,
  arena text not null,
  level int not null check (level between 1 and 30),
  gained int not null check (gained between 1 and 3),
  created_at timestamptz not null default now()
);
create index if not exists star_events_created_idx on public.star_events (created_at);

create table if not exists public.daily_results (
  user_id uuid not null references public.profiles on delete cascade,
  day date not null,
  score int not null check (score between 0 and 6),
  seconds numeric not null check (seconds > 0 and seconds < 3600),
  created_at timestamptz not null default now(),
  primary key (user_id, day)                            -- one shot per day
);

-- ───────── Row level security ─────────
alter table public.profiles enable row level security;
alter table public.progress enable row level security;
alter table public.star_events enable row level security;
alter table public.daily_results enable row level security;

drop policy if exists "read own profile" on public.profiles;
create policy "read own profile" on public.profiles for select using (auth.uid() = id);
drop policy if exists "create own profile" on public.profiles;
create policy "create own profile" on public.profiles for insert with check (auth.uid() = id);
drop policy if exists "rename own profile" on public.profiles;
create policy "rename own profile" on public.profiles for update using (auth.uid() = id);

drop policy if exists "read own progress" on public.progress;
create policy "read own progress" on public.progress for select using (auth.uid() = user_id);
drop policy if exists "read own daily" on public.daily_results;
create policy "read own daily" on public.daily_results for select using (auth.uid() = user_id);
-- No insert/update policies on progress, star_events or daily_results: only the functions below write them.

-- ───────── Write functions ─────────
create or replace function public.record_level(p_arena text, p_level int, p_stars int)
returns int language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  cur jsonb; prev int; total int; recent int; perfect int;
begin
  if uid is null then raise exception 'not signed in'; end if;
  if not exists (select 1 from profiles where id = uid) then raise exception 'pick a username first'; end if;
  if p_level not between 1 and 30 or p_stars not between 1 and 3 then raise exception 'bad input'; end if;

  select count(*) into recent from star_events where user_id = uid and created_at > now() - interval '1 minute';
  if recent >= 8 then raise exception 'too fast'; end if;

  insert into progress (user_id, arena) values (uid, p_arena) on conflict do nothing;
  select levels into cur from progress where user_id = uid and arena = p_arena for update;

  if p_level > 1 and coalesce((cur ->> (p_level - 1)::text)::int, 0) = 0 then
    raise exception 'previous level not cleared';
  end if;
  if p_level > 25 then   -- the frontier needs a perfect 1–25
    select count(*) into perfect from jsonb_each_text(cur) where key::int between 1 and 25 and value::int = 3;
    if perfect < 25 then raise exception 'frontier locked'; end if;
  end if;

  prev := coalesce((cur ->> p_level::text)::int, 0);
  if p_stars <= prev then return prev; end if;

  cur := cur || jsonb_build_object(p_level::text, p_stars);
  select coalesce(sum(value::int), 0) into total from jsonb_each_text(cur);
  update progress set levels = cur, stars = total, updated_at = now() where user_id = uid and arena = p_arena;
  insert into star_events (user_id, arena, level, gained) values (uid, p_arena, p_level, p_stars - prev);
  return p_stars;
end $$;

-- One-time upload of progress made before signing up (counts for all-time and per-arena, not this week).
create or replace function public.sync_progress(p_arena text, p_levels jsonb)
returns int language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  cur jsonb; k text; v int; total int;
begin
  if uid is null then raise exception 'not signed in'; end if;
  if not exists (select 1 from profiles where id = uid) then raise exception 'pick a username first'; end if;
  insert into progress (user_id, arena) values (uid, p_arena) on conflict do nothing;
  select levels into cur from progress where user_id = uid and arena = p_arena for update;
  for k, v in select key, value::int from jsonb_each_text(p_levels) loop
    if k ~ '^[0-9]+$' and k::int between 1 and 30 and v between 1 and 3 and v > coalesce((cur ->> k)::int, 0) then
      cur := cur || jsonb_build_object(k, v);
    end if;
  end loop;
  select coalesce(sum(value::int), 0) into total from jsonb_each_text(cur);
  update progress set levels = cur, stars = total, updated_at = now() where user_id = uid and arena = p_arena;
  return total;
end $$;

create or replace function public.submit_daily(p_day date, p_score int, p_seconds numeric)
returns boolean language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid();
begin
  if uid is null then raise exception 'not signed in'; end if;
  if not exists (select 1 from profiles where id = uid) then raise exception 'pick a username first'; end if;
  if p_day not between current_date - 1 and current_date + 1 then raise exception 'wrong day'; end if;
  insert into daily_results (user_id, day, score, seconds) values (uid, p_day, p_score, round(p_seconds, 1))
    on conflict do nothing;
  return found;
end $$;

-- ───────── Read function (anyone can view the boards) ─────────
create or replace function public.get_leaderboard(p_kind text, p_arena text default null, p_day date default null)
returns table (rank bigint, username text, score numeric, seconds numeric, is_me boolean)
language plpgsql security definer set search_path = public stable as $$
begin
  if p_kind = 'daily' then
    return query
      with r as (
        select d.user_id, p.username, d.score::numeric as score, d.seconds,
               rank() over (order by d.score desc, d.seconds asc) as rk
        from daily_results d join profiles p on p.id = d.user_id
        where d.day = coalesce(p_day, current_date))
      select r.rk, r.username, r.score, r.seconds, r.user_id = auth.uid() from r
      where r.rk <= 50 or r.user_id = auth.uid() order by r.rk limit 51;
  elsif p_kind = 'week' then
    return query
      with s as (
        select e.user_id, sum(e.gained)::numeric as score from star_events e
        where e.created_at >= date_trunc('week', now()) group by e.user_id),
      r as (select s.user_id, p.username, s.score, rank() over (order by s.score desc) as rk
            from s join profiles p on p.id = s.user_id)
      select r.rk, r.username, r.score, null::numeric, r.user_id = auth.uid() from r
      where r.rk <= 50 or r.user_id = auth.uid() order by r.rk limit 51;
  elsif p_kind = 'arena' then
    return query
      with r as (
        select g.user_id, p.username, g.stars::numeric as score, rank() over (order by g.stars desc, g.updated_at asc) as rk
        from progress g join profiles p on p.id = g.user_id
        where g.arena = p_arena and g.stars > 0)
      select r.rk, r.username, r.score, null::numeric, r.user_id = auth.uid() from r
      where r.rk <= 50 or r.user_id = auth.uid() order by r.rk limit 51;
  else -- all time
    return query
      with s as (select g.user_id, sum(g.stars)::numeric as score from progress g group by g.user_id having sum(g.stars) > 0),
      r as (select s.user_id, p.username, s.score, rank() over (order by s.score desc) as rk
            from s join profiles p on p.id = s.user_id)
      select r.rk, r.username, r.score, null::numeric, r.user_id = auth.uid() from r
      where r.rk <= 50 or r.user_id = auth.uid() order by r.rk limit 51;
  end if;
end $$;

revoke all on function public.record_level(text, int, int) from public, anon;
revoke all on function public.sync_progress(text, jsonb) from public, anon;
revoke all on function public.submit_daily(date, int, numeric) from public, anon;
grant execute on function public.record_level(text, int, int) to authenticated;
grant execute on function public.sync_progress(text, jsonb) to authenticated;
grant execute on function public.submit_daily(date, int, numeric) to authenticated;
grant execute on function public.get_leaderboard(text, text, date) to anon, authenticated;
