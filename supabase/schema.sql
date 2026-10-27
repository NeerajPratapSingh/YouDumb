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

-- ═════════ Humans vs AI: daily battle, ratings, fronts (added Oct 2026) ═════════
alter table public.profiles add column if not exists rating int not null default 1000;
alter table public.profiles add column if not exists battles int not null default 0;
alter table public.profiles add column if not exists front text;
do $$ begin
  alter table public.profiles add constraint profiles_front_len check (front is null or length(front) between 2 and 40);
exception when duplicate_object then null; end $$;

-- One battle per day, written by the daily job (scripts/make-battle.mjs) with the service key.
-- questions: [{q, code, options[4], answer, why, how[], cat, rating, ai:[{model, pick}]}]
create table if not exists public.battles (
  day date primary key,
  questions jsonb not null,
  created_at timestamptz not null default now()
);
create table if not exists public.battle_answers (
  user_id uuid not null references public.profiles on delete cascade,
  day date not null,
  idx int not null check (idx between 0 and 4),
  choice int not null check (choice between -1 and 3),
  correct boolean not null,
  ms int not null,
  delta int not null,
  front text,
  created_at timestamptz not null default now(),
  primary key (user_id, day, idx)
);
create index if not exists battle_answers_day_idx on public.battle_answers (day);
alter table public.battles enable row level security;          -- no policies: answers stay server-side
alter table public.battle_answers enable row level security;
drop policy if exists "read own answers" on public.battle_answers;
create policy "read own answers" on public.battle_answers for select using (auth.uid() = user_id);

-- Today's battle without the answer key, plus what the caller already answered.
create or replace function public.get_battle(p_day date default null)
returns jsonb language plpgsql security definer set search_path = public stable as $$
declare d date := coalesce(p_day, current_date); b jsonb; mine jsonb;
begin
  select questions into b from battles where day = d;
  if b is null then return null; end if;
  select coalesce(jsonb_agg(jsonb_build_object('idx', a.idx, 'choice', a.choice, 'correct', a.correct, 'delta', a.delta,
           'answer', (b -> a.idx ->> 'answer')::int, 'why', b -> a.idx -> 'why', 'how', b -> a.idx -> 'how', 'ai', b -> a.idx -> 'ai') order by a.idx), '[]'::jsonb)
    into mine from battle_answers a where a.user_id = auth.uid() and a.day = d;
  return jsonb_build_object('day', d,
    'questions', (select jsonb_agg(jsonb_build_object('q', x -> 'q', 'code', x -> 'code', 'options', x -> 'options', 'cat', x -> 'cat', 'rating', x -> 'rating') order by n)
                  from jsonb_array_elements(b) with ordinality as t(x, n)),
    'mine', mine);
end $$;

-- Answer one round. Checked and rated on the server; returns the key, the AI's picks and the rating change.
create or replace function public.answer_battle(p_day date, p_idx int, p_choice int, p_ms int)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid(); b jsonb; q jsonb; ans int; ok boolean; qr int; r int; e numeric; dlt int; fr text;
begin
  if uid is null then raise exception 'not signed in'; end if;
  select rating, front into r, fr from profiles where id = uid for update;
  if r is null then raise exception 'pick a username first'; end if;
  if p_day <> current_date then raise exception 'battle closed'; end if;
  select questions into b from battles where day = p_day;
  if b is null or p_idx < 0 or p_idx >= jsonb_array_length(b) then raise exception 'no such round'; end if;
  if exists (select 1 from battle_answers where user_id = uid and day = p_day and idx = p_idx) then raise exception 'already answered'; end if;
  q := b -> p_idx; ans := (q ->> 'answer')::int; ok := p_choice = ans;
  qr := coalesce((q ->> 'rating')::int, 1000);
  e := 1 / (1 + power(10, (qr - r) / 400.0));
  dlt := round(20 * ((case when ok then 1 else 0 end) - e));
  if ok and dlt < 1 then dlt := 1; end if;
  update profiles set rating = greatest(100, rating + dlt), battles = battles + (case when p_idx = 0 then 1 else 0 end) where id = uid;
  insert into battle_answers (user_id, day, idx, choice, correct, ms, delta, front)
    values (uid, p_day, p_idx, p_choice, ok, least(greatest(coalesce(p_ms, 0), 0), 600000), dlt, fr);
  return jsonb_build_object('correct', ok, 'answer', ans, 'why', q -> 'why', 'how', q -> 'how', 'ai', q -> 'ai', 'delta', dlt, 'rating', greatest(100, r + dlt));
end $$;

-- The war score: every right answer today is a point for humanity, every miss a point for AI.
create or replace function public.get_war(p_day date default null)
returns jsonb language sql security definer set search_path = public stable as $$
  with t as (select * from battle_answers where day = coalesce(p_day, current_date))
  select jsonb_build_object(
    'humans', (select count(*) from t where correct),
    'ai', (select count(*) from t where not correct),
    'players', (select count(distinct user_id) from t),
    'fronts', coalesce((select jsonb_agg(f) from (
        select jsonb_build_object('front', front, 'humans', count(*) filter (where correct), 'ai', count(*) filter (where not correct)) as f
        from t where front is not null group by front order by count(*) desc limit 8) s), '[]'::jsonb));
$$;

-- Leaderboards: rating, today's battle and fronts join the existing kinds.
create or replace function public.get_leaderboard2(p_kind text, p_arena text default null, p_day date default null)
returns table (rank bigint, username text, score numeric, seconds numeric, is_me boolean, extra text)
language plpgsql security definer set search_path = public stable as $$
begin
  if p_kind = 'rating' then
    return query
      with r as (select p.id, p.username, p.rating::numeric as score, p.front, rank() over (order by p.rating desc) as rk from profiles p where p.battles > 0)
      select r.rk, r.username, r.score, null::numeric, r.id = auth.uid(), r.front from r
      where r.rk <= 50 or r.id = auth.uid() order by r.rk limit 51;
  elsif p_kind = 'battle' then
    return query
      with s as (select a.user_id, count(*) filter (where a.correct)::numeric as score, round(sum(a.ms) / 1000.0, 1) as secs
                 from battle_answers a where a.day = coalesce(p_day, current_date) group by a.user_id),
      r as (select s.user_id, p.username, s.score, s.secs, p.front, rank() over (order by s.score desc, s.secs asc) as rk from s join profiles p on p.id = s.user_id)
      select r.rk, r.username, r.score, r.secs, r.user_id = auth.uid(), r.front from r
      where r.rk <= 50 or r.user_id = auth.uid() order by r.rk limit 51;
  elsif p_kind = 'fronts' then
    return query
      with f as (select p.front, round(avg(p.rating))::numeric as score, count(*) as n from profiles p
                 where p.front is not null and p.battles > 0 group by p.front having count(*) >= 2)
      select rank() over (order by f.score desc), f.front, f.score, f.n::numeric,
             f.front = (select front from profiles where id = auth.uid()), f.n || ' fighters' from f order by 1 limit 50;
  else
    return query select l.rank, l.username, l.score, l.seconds, l.is_me, null::text from get_leaderboard(p_kind, p_arena, p_day) l;
  end if;
end $$;

-- Let players set their front (city or college) and see their own rating.
create or replace function public.set_front(p_front text)
returns text language plpgsql security definer set search_path = public as $$
declare f text := nullif(btrim(p_front), '');
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  if f is not null and length(f) not between 2 and 40 then raise exception 'front must be 2–40 characters'; end if;
  update profiles set front = f where id = auth.uid();
  return f;
end $$;

revoke all on function public.answer_battle(date, int, int, int) from public, anon;
revoke all on function public.set_front(text) from public, anon;
grant execute on function public.answer_battle(date, int, int, int) to authenticated;
grant execute on function public.set_front(text) to authenticated;
grant execute on function public.get_battle(date) to anon, authenticated;
grant execute on function public.get_war(date) to anon, authenticated;
grant execute on function public.get_leaderboard2(text, text, date) to anon, authenticated;
