// YouDumb AI question service (Cloudflare Pages Function → served at /api/ai).
// The OpenRouter key lives ONLY in Cloudflare's project secrets (OPENROUTER_API_KEY), never in the page or the repo.
// POST /api/ai  {mode:'gen', arena, d, avoid:[stems]}   → {questions:[...]}
// POST /api/ai  {mode:'verify', items:[{q, code, options}]} → {answers:[index|null]}

const MODEL_DEFAULT = 'anthropic/claude-haiku-5.5';
// Only pages served from this same site (any domain it runs on) may call the AI.

const ARENAS = {
  logic: {name: 'Logic & puzzles', topics: ['seating and ordering puzzles', 'knights and knaves', 'syllogisms', 'lateral-thinking riddles with a fair twist', 'calendar and clock puzzles', 'river-crossing style constraints', 'truth tables in plain words', 'counting traps (fence posts, handshakes)', 'pattern and sequence rules', 'family-relation puzzles', 'worst-case / pigeonhole', 'cause vs correlation traps']},
  math: {name: 'Math', topics: ['mental arithmetic shortcuts', 'percentages and reverse percentages', 'ratios and proportions', 'speed, distance and time', 'work and rates', 'simple probability', 'fractions and decimals', 'exponents and powers of two', 'averages', 'area and volume scaling', 'simple and compound interest', 'divisibility and remainders']},
  apt: {name: 'Aptitude (placement-test style)', topics: ['number series', 'letter series and coding-decoding', 'blood relations', 'direction sense', 'clocks and calendars', 'profit and loss', 'time and work', 'pipes and cisterns', 'mixtures and alligation', 'ages', 'analogies', 'data sufficiency in plain words']},
  biz: {name: 'Business & product', topics: ['conversion funnels', 'unit economics and CAC/LTV', 'pricing and discounts', 'retention and churn', 'MRR/ARR', 'A/B test reading', 'break-even', 'markup vs margin', 'prioritization frameworks', 'market sizing', 'runway and burn', 'growth rates']},
  street: {name: 'Street smarts', topics: ['spotting scams', 'deals and fake discounts', 'reading statistics in the news', 'loans, EMIs and interest', 'inflation and buying power', 'insurance and expected value', 'subscription traps', 'tipping and splitting bills', 'misleading charts', 'base rates and risk', 'negotiation basics', 'everyday time and money maths']},
  words: {name: 'Words & language', topics: ['synonyms', 'antonyms', 'commonly confused words', 'subject-verb agreement', 'idioms and meanings', 'irregular plurals', 'spelling traps', 'one-word substitutes', 'word roots and prefixes', 'odd one out', 'analogies between words', 'punctuation that changes meaning']},
  data: {name: 'Data & stats', topics: ['mean vs median vs mode', 'weighted averages', 'percentiles', 'correlation vs causation', 'reading a table', 'rates per capita', 'sampling bias', 'independent probability', 'percentage points vs percent', 'moving averages', 'outliers', 'choosing the right chart']},
  code: {name: 'Coding', topics: ['JavaScript output prediction', 'Python output prediction', 'SQL query results', 'Big-O of a snippet', 'git commands', 'HTTP status codes', 'array and string methods', 'truthy and falsy values', 'off-by-one loops', 'recursion tracing', 'bitwise operators', 'scope and closures']},
};
const NON_CODE = Object.keys(ARENAS).filter(k => k !== 'code');
const SETTINGS = ['a cricket match', 'a college canteen', 'a startup office', 'a train journey', 'a wedding', 'an online sale', 'a gym', 'a road trip', 'a bakery', 'a hostel', 'a football club', 'a farm', 'a hospital shift', 'a movie theatre', 'an exam hall', 'a food delivery app', 'a library', 'a music festival', 'a space mission', 'a chess club', 'a monsoon day', 'a stock market app', 'a video game', 'a zoo', 'a coffee shop'];
const LEVEL = {1: 'easy: one step, but with a tempting wrong answer', 2: 'medium: two steps', 3: 'hard: several steps or a subtle trap', 4: 'very hard: needs careful multi-step reasoning'};

// Light per-instance rate limit so a stranger can't drain the key.
const hits = new Map();
function limited(ip) {
  const now = Date.now(), win = 10 * 60 * 1000, max = 40;
  const arr = (hits.get(ip) || []).filter(t => now - t < win);
  arr.push(now); hits.set(ip, arr);
  if (hits.size > 5000) hits.clear();
  return arr.length > max;
}

const json = (obj, status = 200) => new Response(JSON.stringify(obj), {status, headers: {'content-type': 'application/json', 'cache-control': 'no-store'}});
const pick = a => a[Math.floor(Math.random() * a.length)];
const shuffle = a => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
const clip = (s, n) => String(s ?? '').replace(/\s+/g, ' ').trim().slice(0, n);

async function callModel(env, site, messages, maxTokens, temperature) {
  const res = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {'authorization': 'Bearer ' + env.OPENROUTER_API_KEY, 'content-type': 'application/json', 'HTTP-Referer': site, 'X-Title': 'YouDumb'},
    body: JSON.stringify({model: env.OPENROUTER_MODEL || MODEL_DEFAULT, messages, max_tokens: maxTokens, temperature, response_format: {type: 'json_object'}}),
  });
  if (!res.ok) throw new Error('upstream ' + res.status);
  const data = await res.json();
  const text = data?.choices?.[0]?.message?.content || '';
  const m = text.match(/\{[\s\S]*\}/);
  if (!m) throw new Error('no json');
  return JSON.parse(m[0]);
}

function clean(x, arena) {
  if (!x || typeof x !== 'object') return null;
  const q = clip(x.q, 420), code = arena === 'code' ? String(x.code ?? '').slice(0, 700).trim() : '';
  const options = Array.isArray(x.options) ? x.options.map(o => clip(o, 90)) : [];
  const answer = clip(x.answer, 90);
  if (q.length < 8 || options.length !== 4 || new Set(options.map(o => o.toLowerCase())).size !== 4 || options.some(o => !o)) return null;
  const a = options.indexOf(answer);
  if (a < 0) return null;
  const trap = x.trap != null ? options.indexOf(clip(x.trap, 90)) : -1;
  const how = (Array.isArray(x.how) ? x.how : []).map(s => clip(s, 220)).filter(Boolean).slice(0, 5);
  const why = clip(x.why, 260);
  if (!why || how.length < 1) return null;
  return {q, code, o: options, a, trap: trap >= 0 && trap !== a ? trap : null, why, how, cat: clip(x.cat, 30) || ARENAS[arena].name};
}

async function generate(env, site, body) {
  let arena = String(body.arena || 'mix');
  if (arena === 'mix' || !ARENAS[arena]) arena = pick(NON_CODE);
  const d = Math.min(4, Math.max(1, +body.d || 2));
  const A = ARENAS[arena];
  const topics = shuffle(A.topics).slice(0, 4);
  const avoid = (Array.isArray(body.avoid) ? body.avoid : []).slice(0, 40).map(s => clip(s, 90)).filter(Boolean);
  const n = 4;
  const sys = 'You write original multiple-choice brain-game questions. Every question must have exactly one correct answer that you have checked step by step. Never write ambiguous, opinion-based or trick-wording questions. Output only JSON.';
  const user = `Write ${n} NEW questions for the "${A.name}" arena.
Difficulty: ${LEVEL[d]}.
Use these sub-topics, one each: ${topics.join('; ')}.
Set at least two of them in ${pick(SETTINGS)} or ${pick(SETTINGS)}, with fresh names and numbers (Indian and international names are both fine).
${arena === 'code' ? 'Put any code in the "code" field (plain text, max 12 lines) and keep "q" as the question about it.' : 'No code.'}
Each question needs 4 short options (max 8 words each); one is correct and one should be the tempting wrong answer most people pick ("trap").
"how" is 2–4 short steps that show how to reach the answer. "why" is one sentence with the key idea.
Do not repeat or lightly reword any of these recent questions: ${avoid.length ? avoid.map(s => '"' + s + '"').join('; ') : 'none'}.
Return {"questions":[{"q":"...","code":"","options":["..","..","..",".."],"answer":"exact text of the correct option","trap":"exact text of the trap option","how":["step 1","step 2"],"why":"...","cat":"2-3 word category"}]}`;
  const out = await callModel(env, site, [{role: 'system', content: sys}, {role: 'user', content: user}], 2200, 0.9);
  const qs = (out.questions || []).map(x => clean(x, arena)).filter(Boolean).map(q => Object.assign(q, {t: arena, d}));
  return {questions: qs};
}

// Second, independent pass: the model answers each question cold. The client keeps only questions where both passes agree.
async function verify(env, site, body) {
  const items = (Array.isArray(body.items) ? body.items : []).slice(0, 6).map(x => ({q: clip(x.q, 420), code: String(x.code || '').slice(0, 700), options: (x.options || []).slice(0, 4).map(o => clip(o, 90))}));
  if (!items.length) return {answers: []};
  const user = `Solve each question carefully, step by step in your head, then give the index (0-3) of the single correct option. If a question is ambiguous or has no correct option, give null.
${items.map((x, i) => `#${i}\n${x.q}${x.code ? '\nCODE:\n' + x.code : ''}\nOptions: ${x.options.map((o, j) => j + ') ' + o).join(' | ')}`).join('\n\n')}
Return {"answers":[index or null, ...]} in the same order.`;
  const out = await callModel(env, site, [{role: 'system', content: 'You are a careful exam checker. Output only JSON.'}, {role: 'user', content: user}], 300, 0);
  const answers = (out.answers || []).slice(0, items.length).map(v => (Number.isInteger(v) && v >= 0 && v < 4) ? v : null);
  return {answers};
}

export async function onRequestPost({request, env}) {
  const self = new URL(request.url);
  const origin = request.headers.get('origin') || request.headers.get('referer') || '';
  let host = ''; try { host = new URL(origin).host; } catch (e) {}
  if (host !== self.host && !/^(localhost|127\.0\.0\.1)(:\d+)?$/.test(host)) return json({error: 'forbidden'}, 403);
  const ip = request.headers.get('cf-connecting-ip') || 'x';
  if (limited(ip)) return json({error: 'slow down'}, 429);
  if (!env.OPENROUTER_API_KEY) return json({error: 'AI not configured'}, 503);
  let body = {}; try { body = await request.json(); } catch (e) { return json({error: 'bad json'}, 400); }
  const site = self.origin;
  try {
    return json(body.mode === 'verify' ? await verify(env, site, body) : await generate(env, site, body));
  } catch (e) {
    return json({error: 'ai failed'}, 502);
  }
}
export const onRequest = () => json({error: 'POST only'}, 405);
