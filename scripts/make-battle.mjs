// Builds today's Humans vs AI battle: 5 questions, answered once by a panel of real AI models.
// Runs once a day (GitHub Actions), so players never trigger an AI call. Cost: a few rupees a day.
// Env: OPENROUTER_API_KEY, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
//      BATTLE_WRITER (model that writes questions), BATTLE_MODELS (comma list: the AI "army"), BATTLE_DAY (optional YYYY-MM-DD).
const KEY = process.env.OPENROUTER_API_KEY, SB = process.env.SUPABASE_URL, SRK = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!KEY || !SB || !SRK) { console.error('Missing OPENROUTER_API_KEY, SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY'); process.exit(1); }
const WRITER = process.env.BATTLE_WRITER || 'anthropic/claude-haiku-5.5';
const ARMY = (process.env.BATTLE_MODELS || 'anthropic/claude-haiku-5.5,openai/gpt-4o-mini,google/gemini-2.0-flash-001,meta-llama/llama-3.3-70b-instruct')
  .split(',').map(s => s.trim()).filter(Boolean);
const DAY = process.env.BATTLE_DAY || new Date().toISOString().slice(0, 10);
const THEMES = ['letter and word counting', 'trick wording', 'everyday probability', 'percent and money traps', 'logic puzzles with a twist', 'spatial and direction reasoning',
  'calendar and clock reasoning', 'estimation and orders of magnitude', 'reading a small table', 'misleading statistics', 'sequence patterns', 'riddles that punish pattern-matching'];
const shuffle = a => a.map(v => [Math.random(), v]).sort((x, y) => x[0] - y[0]).map(x => x[1]);

async function ask(model, messages, {json = true, max = 1500, temperature = 0.7} = {}) {
  const res = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {authorization: 'Bearer ' + KEY, 'content-type': 'application/json', 'HTTP-Referer': 'https://youdumb.netlify.app', 'X-Title': 'YouDumb battle'},
    body: JSON.stringify({model, messages, max_tokens: max, temperature, ...(json ? {response_format: {type: 'json_object'}} : {})}),
  });
  if (!res.ok) throw new Error(model + ' ' + res.status + ' ' + (await res.text()).slice(0, 200));
  const text = (await res.json())?.choices?.[0]?.message?.content || '';
  if (!json) return text;
  const m = text.match(/\{[\s\S]*\}/); if (!m) throw new Error('no json from ' + model);
  return JSON.parse(m[0]);
}

async function writeQuestions() {
  const themes = shuffle(THEMES).slice(0, 7);
  const out = await ask(WRITER, [
    {role: 'system', content: 'You write short multiple-choice questions that chatbots often get wrong but a careful human can solve in under a minute. Every question has exactly one correct answer, which you have checked step by step. Output only JSON.'},
    {role: 'user', content: `Write 7 questions, one per theme: ${themes.join('; ')}.
Mix difficulty from easy to hard. Each has 4 short options, exactly one correct. Avoid anything ambiguous, opinion-based, or dependent on current events.
Return {"questions":[{"q":"...","options":["..","..","..",".."],"answer":"exact correct option text","why":"one sentence","how":["step","step"],"cat":"2-3 word category","d":1-4}]}`},
  ], {max: 3500, temperature: 0.9});
  return (out.questions || []).filter(x => x && typeof x.q === 'string' && Array.isArray(x.options) && x.options.length === 4
    && new Set(x.options.map(String)).size === 4 && x.options.map(String).includes(String(x.answer)));
}

async function keyIsRight(q) {   // review with the key shown: much easier than solving cold
  const out = await ask(WRITER, [{role: 'user', content: `Check this answer key very carefully, step by step. Question: ${q.q}\nOptions: ${q.options.join(' | ')}\nProposed answer: ${q.answer}\nIs the proposed answer the single correct option and the question unambiguous? Return {"ok":true|false}`}], {max: 400, temperature: 0});
  return out.ok === true;
}

async function armyPick(model, q) {
  try {
    const text = await ask(model, [{role: 'user', content: `${q.q}\n${q.options.map((o, i) => 'ABCD'[i] + ') ' + o).join('\n')}\nReply with the letter of the correct answer only.`}], {json: false, max: 400, temperature: 0});
    const m = text.trim().match(/\b([ABCD])\b/); return m ? 'ABCD'.indexOf(m[1]) : -1;
  } catch (e) { console.warn('skip', model, e.message); return null; }
}

const qs = [];
for (const q of await writeQuestions()) { if (qs.length >= 5) break; try { if (await keyIsRight(q)) qs.push(q); } catch (e) {} }
if (qs.length < 5) { console.error('Only', qs.length, 'questions passed review; try again'); process.exit(1); }

const battle = [];
for (const q of qs) {
  const options = shuffle(q.options.map(String));
  const answer = options.indexOf(String(q.answer));
  const shown = {...q, options};
  const ai = [];
  for (const model of ARMY) { const pick = await armyPick(model, shown); if (pick !== null) ai.push({model: model.split('/').pop(), pick}); }
  const fail = ai.length ? ai.filter(a => a.pick !== answer).length / ai.length : 0.5;
  const d = Math.min(4, Math.max(1, +q.d || 2));
  battle.push({q: q.q, code: null, options, answer, why: q.why || '', how: (q.how || []).slice(0, 4), cat: q.cat || 'Battle',
    rating: Math.round(880 + 80 * d + 420 * fail), ai});
}
// Hardest round last: the battle builds.
battle.sort((a, b) => a.rating - b.rating);

const res = await fetch(`${SB}/rest/v1/battles?on_conflict=day`, {
  method: 'POST',
  headers: {apikey: SRK, authorization: 'Bearer ' + SRK, 'content-type': 'application/json', prefer: 'resolution=merge-duplicates'},
  body: JSON.stringify({day: DAY, questions: battle}),
});
if (!res.ok) { console.error('Supabase', res.status, await res.text()); process.exit(1); }
console.log(`Battle for ${DAY} saved:`, battle.map(b => `${b.rating} (${b.ai.filter(a => a.pick !== b.answer).length}/${b.ai.length} AI wrong)`).join(', '));
