---
name: YouDumb
description: A free brain game where you climb 60 years of AI, one rival era at a time.
colors:
  plum-black: "#0d0710"
  plum-raised: "#180c1c"
  glass: "rgba(255,236,246,0.045)"
  glass-raised: "rgba(255,236,246,0.085)"
  line: "rgba(255,61,139,0.16)"
  line-strong: "rgba(255,61,139,0.34)"
  hot-magenta: "#ff3d8b"
  magenta-deep: "#c4135f"
  magenta-soft: "rgba(255,61,139,0.15)"
  correct-cyan: "#2de2e6"
  wrong-orange: "#ff7a3d"
  star-yellow: "#ffd23f"
  text: "#fbeef5"
  text-muted: "#b89fb1"
  text-dim: "#947a8d"
  ink: "#0d0710"
typography:
  display:
    fontFamily: "'Big Shoulders Display', 'Arial Narrow', system-ui, sans-serif"
    fontSize: "clamp(3.1rem, 7.6vw, 5.9rem)"
    fontWeight: 900
    lineHeight: 0.88
  headline:
    fontFamily: "'Big Shoulders Display', 'Arial Narrow', system-ui, sans-serif"
    fontSize: "clamp(2.3rem, 5.4vw, 3.6rem)"
    fontWeight: 900
    lineHeight: 0.92
  title:
    fontFamily: "'Big Shoulders Display', 'Arial Narrow', system-ui, sans-serif"
    fontSize: "1.55rem"
    fontWeight: 800
    lineHeight: 1
  question:
    fontFamily: "'Onest', system-ui, sans-serif"
    fontSize: "clamp(1.25rem, 3.6vw, 1.55rem)"
    fontWeight: 700
    lineHeight: 1.3
  body:
    fontFamily: "'Onest', system-ui, -apple-system, 'Segoe UI', sans-serif"
    fontSize: "15.5px"
    fontWeight: 400
    lineHeight: 1.55
  label:
    fontFamily: "'Onest', system-ui, sans-serif"
    fontSize: "0.74rem"
    fontWeight: 700
    letterSpacing: "0.08em"
  code:
    fontFamily: "'JetBrains Mono', ui-monospace, Menlo, monospace"
    fontSize: "0.88rem"
rounded:
  tag: "4px"
  key: "8px"
  small-button: "11px"
  button: "14px"
  answer: "15px"
  tile: "18px"
  panel: "22px"
  pill: "999px"
spacing:
  sm: "10px"
  md: "16px"
  lg: "24px"
  section: "56px"
components:
  button-primary:
    backgroundColor: "{colors.hot-magenta}"
    textColor: "{colors.ink}"
    typography: "{typography.title}"
    rounded: "{rounded.button}"
    padding: "14px 24px"
  button-ghost:
    backgroundColor: "{colors.glass}"
    textColor: "{colors.text}"
    rounded: "{rounded.button}"
    padding: "14px 24px"
  answer:
    backgroundColor: "{colors.glass}"
    textColor: "{colors.text}"
    rounded: "{rounded.answer}"
    padding: "15px 16px"
  answer-locked:
    backgroundColor: "{colors.hot-magenta}"
    textColor: "{colors.ink}"
  answer-correct:
    backgroundColor: "{colors.correct-cyan}"
    textColor: "{colors.correct-cyan}"
  answer-wrong:
    backgroundColor: "{colors.wrong-orange}"
    textColor: "{colors.wrong-orange}"
  panel:
    backgroundColor: "{colors.glass}"
    textColor: "{colors.text}"
    rounded: "{rounded.panel}"
  arena-tile:
    backgroundColor: "{colors.glass}"
    textColor: "{colors.text}"
    rounded: "{rounded.tile}"
  level-node-cleared:
    backgroundColor: "{colors.hot-magenta}"
    textColor: "{colors.ink}"
    rounded: "{rounded.pill}"
---

# Design System: YouDumb

## Overview

**Creative North Star: "The Neon Game Show"**

The game is staged like a quiz show: a title card, a live warm-up question, a board of categories, a prize ladder of levels, and a lock-in moment before every reveal. The colours and shapes, though, are a neon arcade: plum-black ground, hot magenta for everything that belongs to the player, cyan for correct, orange for wrong, on soft rounded glass panels. Big condensed caps announce, and a friendly grotesk handles everything the player reads.

The layout is phone-first: the title, then the question, then the action. Moments stay big and the density stays low.

**Key Characteristics:**
- Plum-black ground with a magenta glow from the top right and a faint cyan glow from the left.
- Rounded glass panels (22px) and answers (15px). Buttons have a pressed magenta edge.
- Lock-in sequence: the chosen answer fills magenta, a short beat, then cyan for correct or orange for wrong.
- Quiz-show structure: arena board, era panels with winding dotted level paths, lessons as a running list.

## Colors

### Primary
- **Hot Magenta** (#ff3d8b): primary buttons, the locked-in answer, the current level rung, the selected arena, the player's name and score, emphasis words in headlines, the timer.

### Secondary
- **Correct Cyan** (#2de2e6): correct answers, the reveal head when right, the focus ring, how-to labels.
- **Wrong Orange** (#ff7a3d): wrong answers, the reveal head when wrong, the timer when it is nearly out. It sits far enough in hue from the magenta that the two never read as the same thing.
- **Star Yellow** (#ffd23f): stars and "learning" status only.

### Neutral
- **Plum Black** (#0d0710): the page ground, carried by the html element.
- **Glass** (4.5% white, 8.5% raised): every panel, answer, tile and rung, with a magenta-tinted 1px line.
- **Text** (#fbeef5), **Muted** (#b89fb1), **Dim** (#947a8d): every step passes 4.5:1 on the ground.

### Named Rules
**The Player Is Magenta Rule.** Magenta marks what belongs to the player: their action, their level, their score, their locked answer. The AI opponent never gets it.

**The Words With Colour Rule.** Cyan and orange always come with text ("Right", "Wrong").

## Typography

**Display Font:** Big Shoulders Display, with Arial Narrow as the fallback.
**Body Font:** Onest, with system-ui as the fallback.
**Code Font:** JetBrains Mono, for code and save codes only.

### Hierarchy
- **Display** (900, clamp(3.1rem, 7.6vw, 5.9rem), uppercase): the hero title.
- **Headline** (900, clamp(2.3rem, 5.4vw, 3.6rem), uppercase): section titles, verdict heads and lesson titles.
- **Title** (800, 1.3–2rem, uppercase): era names, arena names, buttons and reveal heads.
- **Question** (Onest 700, clamp(1.25rem, 3.6vw, 1.55rem)): questions are never set in caps.
- **Body** (Onest 400, 15.5px, 1.55): copy and explanations.
- **Label** (Onest 700, 0.74rem, 0.08em tracking, uppercase): meta lines and count labels.

### Named Rules
**The Announce and Read Rule.** Condensed caps announce. Anything the player has to read and think about is set in Onest.

## Layout

The page uses a single 1120px column with a 16px gutter and 56px between sections (44px on phones).

- **Hero:** title and actions on the left, the warm-up panel on the right. On phones the order is title, then the warm-up question, then the stacked full-width buttons, then the copy.
- **Arena board:** 3 columns, dropping to 2 at 900px.
- **Era panels:** 3, then 2, then 1, each holding a five-node path.
- **Lessons:** a single-column list.
- **Game screen:** a centred 660px column.

## Elevation & Depth

The system is flat glass with a backdrop blur (14px) on panels. Depth comes from the ambient glow behind everything. Primary buttons and cleared level nodes sit on a pressed edge.

### Shadow Vocabulary
- **Pressed edge** (`box-shadow: 0 6px 0 #c4135f, 0 14px 32px rgba(255,61,139,0.38)`): primary buttons. Cleared level nodes use a 5px version without the glow.

## Shapes

All shapes are rounded rectangles:
- **Panels:** 22px.
- **Arena tiles and lessons:** 18px.
- **Answers:** 15px.
- **Buttons:** 14px.
- **Small buttons:** 11px.
- **Level nodes:** circles.
- **Key badges and step numbers:** 8px.
- **Tags:** 4px.
- **Chips:** pills.

There are no clipped or angled silhouettes.

## Components

### Buttons
- **Primary:** a magenta fill with plum ink text in display caps. It sits on a 6px darker-magenta edge with a soft magenta glow, and lifts 1px on hover.
- **Ghost:** glass with a 1px line. On hover the line strengthens and the glass brightens.
- **Disabled:** 40% opacity.

### Answers (signature component)
- **Layout:** full-width glass rows (15px corners), each with an 8px number badge in magenta.
- **States:**
  - **Hover:** magenta border on a soft magenta fill.
  - **Locked:** a full magenta fill.
  - **Correct:** a cyan border on a soft cyan fill.
  - **Wrong:** an orange border on a soft orange fill.
  - **Others:** fade to 50%.
  - **Bot's pick:** carries a small tag.

### Level map
Each era panel has a winding dotted path (3px dotted line, magenta at 34%) linking five round level nodes (58px). Cleared nodes are solid magenta on a pressed edge, with yellow stars underneath. The current node is white, bobbing gently, with a soft magenta ring. Locked nodes are hollow. The era year sits as a huge outlined numeral in the top-right corner.

### Arena tiles
- **Style:** glass cards (18px).
- **Selected:** a magenta inset border, a soft magenta fill and a "Selected" tag.
- **Content:** a magenta progress bar and a yellow star count.

### Inputs
- **Style:** plum fields with a magenta-tinted line.
- **Focus:** the caret is magenta and the focus ring is a cyan 2px outline.

## Do's and Don'ts

### Do:
- **Do** use magenta (#ff3d8b) for the player's action, place and score, and nothing decorative.
- **Do** run the 650ms lock-in beat before each reveal, stopping the clock at the tap. Skip it under reduced motion.
- **Do** keep the ground on the html element so the glow layer stays visible.

### Don't:
- **Don't** set questions or explanations in display caps.
- **Don't** put a kicker label above a heading. Live status lines go below the heading.
- **Don't** use glyphs or emoji as icons on the page. Emoji live only in the copied share text.
- **Don't** use monospace outside code and save codes.
