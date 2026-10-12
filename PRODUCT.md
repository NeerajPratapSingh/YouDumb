# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Anyone who wants to play: no specific audience is targeted. Players arrive cold or through a shared score link and play on whatever device they have; phone is the primary device.

## Product Purpose

YouDumb is a free browser brain game. Players answer short multiple-choice questions against bots modelled on AI eras, climb a 30-level ladder per arena, and learn the trick behind every question. Success: people finish levels, come back, and share their results.

## Positioning

Two ideas, held equally: the game is you versus AI through history, climbing eras from ELIZA (1966) to today's frontier models and out-thinking each era's bot; the reason it matters is staying sharp, solving it yourself before asking an AI and keeping the trick.

## Operating Context

- Played in short sessions on phones; levels are 5 questions with a timer and human "par" times.
- Results are shared as text grids and challenge links; a daily run is the same for everyone.
- No accounts. Progress lives in the browser; save codes move it between devices.

## Capabilities and Constraints

- Single static HTML file plus about/privacy pages; no build framework. Hosting is moving from Netlify to Cloudflare Pages with a serverless `/api/ai` function.
- Nine arenas (Mixed, Logic & puzzles, Math, Aptitude, Words & language, Data & stats, Business & product, Street smarts, Coding), each with its own 30-level ladder across six AI eras; the Frontier era unlocks only after perfect scores on levels 1–25.
- Built-in question bank (hand-written and generated) plus AI-written questions verified by a second pass; no question repeats for a player.
- Lessons with drills, a playbook of tricks, mistake review, daily run, save codes, Google Analytics, two ad slots (AdSense pending approval).
- All features and content must be kept through any redesign.

## Brand Commitments

- Name: YouDumb (wordmark "youdumb").
- Voice: cheeky, self-aware roast copy ("Somewhere a GPU is laughing at you").
- Dark theme (user-confirmed).
- Phone-first.

## Evidence on Hand

No testimonials, user counts, press, or benchmarks exist; none may be invented. Bot accuracies and era years are game design values, not claims about real model performance.

## Product Principles

- The player's own thinking is the hero; AI is the opponent, never the helper.
- Every question teaches something: the answer always comes with how to get there.
- Fair play: par times and verified answers over speed tricks.
- Short, replayable sessions that respect the phone in someone's hand.
