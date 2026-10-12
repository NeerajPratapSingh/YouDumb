---
name: YouDumb
description: A prime-time quiz show where every rival is an AI from a different year.
colors:
  stage-navy: "#050a1a"
  stage-navy-raised: "#0a1330"
  panel-hi: "#14234d"
  panel-lo: "#0b1534"
  tile-hi: "#1d3f96"
  tile-lo: "#112763"
  rim: "#2c4a98"
  rim-lit: "#6d93ff"
  spotlight-gold: "#ffc940"
  gold-deep: "#b98300"
  lock-in-amber: "#ff9a1f"
  correct-green: "#33d67e"
  wrong-red: "#ff5568"
  wrong-red-deep: "#b3192d"
  cue-blue: "#8fb0ff"
  studio-white: "#eef2ff"
  muted-blue: "#a9b8de"
  dim-blue: "#8796c0"
  ink: "#07102a"
typography:
  display:
    fontFamily: "'Big Shoulders Display', 'Arial Narrow', system-ui, sans-serif"
    fontSize: "clamp(3.1rem, 7.6vw, 5.9rem)"
    fontWeight: 900
    lineHeight: 0.88
    letterSpacing: "0.005em"
  headline:
    fontFamily: "'Big Shoulders Display', 'Arial Narrow', system-ui, sans-serif"
    fontSize: "clamp(2.3rem, 5.4vw, 3.6rem)"
    fontWeight: 900
    lineHeight: 0.92
    letterSpacing: "0.01em"
  title:
    fontFamily: "'Big Shoulders Display', 'Arial Narrow', system-ui, sans-serif"
    fontSize: "1.55rem"
    fontWeight: 800
    lineHeight: 1
    letterSpacing: "0.02em"
  question:
    fontFamily: "'Onest', system-ui, sans-serif"
    fontSize: "clamp(1.25rem, 3.6vw, 1.55rem)"
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: "-0.01em"
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
    fontWeight: 500
rounded:
  tag: "4px"
  tile: "10px"
  field: "10px"
  panel: "18px"
  pill: "999px"
spacing:
  xs: "6px"
  sm: "10px"
  md: "16px"
  lg: "24px"
  section: "56px"
components:
  button-primary:
    backgroundColor: "{colors.spotlight-gold}"
    textColor: "{colors.ink}"
    typography: "{typography.title}"
    padding: "15px 30px"
  button-ghost:
    backgroundColor: "{colors.panel-hi}"
    textColor: "{colors.studio-white}"
    typography: "{typography.title}"
    padding: "15px 30px"
  answer-lozenge:
    backgroundColor: "{colors.panel-hi}"
    textColor: "{colors.studio-white}"
    padding: "15px 30px 15px 26px"
  answer-lozenge-locked:
    backgroundColor: "{colors.lock-in-amber}"
    textColor: "{colors.ink}"
  answer-lozenge-correct:
    backgroundColor: "{colors.correct-green}"
    textColor: "{colors.ink}"
  answer-lozenge-wrong:
    backgroundColor: "{colors.wrong-red-deep}"
    textColor: "{colors.studio-white}"
  panel:
    backgroundColor: "{colors.panel-hi}"
    textColor: "{colors.studio-white}"
    rounded: "{rounded.panel}"
  category-tile:
    backgroundColor: "{colors.tile-hi}"
    textColor: "{colors.studio-white}"
    rounded: "{rounded.tile}"
  chip:
    backgroundColor: "{colors.stage-navy-raised}"
    textColor: "{colors.muted-blue}"
    rounded: "{rounded.pill}"
---

# Design System: YouDumb

## Overview

**Creative North Star: "The Prime-Time Studio"**

YouDumb is staged as a night-time TV quiz show. The page is the studio set: deep stage navy, follow-spots falling from the rig, lit blue panels, and answer lozenges hanging on rails. Every rival is an AI from a different year, and the player is the contestant under the gold light. The world is dark by brand commitment and loud in a broadcast way, through scale, caps and light. It does not rely on neon glow or glass.

The system is phone-first. A first-time visitor sees the show's title card, a live warm-up question on a real answer panel, and the gold play button, in that order. Density stays low and moments stay big: one question, four lozenges, one verdict. Gold always belongs to the player: their action, their current level, their stars, their score.

**Key Characteristics:**
- Stage navy ground with conic follow-spots, never flat black.
- The lozenge (hexagon-ended bar) is the show's one silhouette, used for answers, buttons, ladder rungs and controls.
- Broadcast condensed caps for everything the host would say; a clean grotesk for everything the contestant reads.
- Lock-in sequence: chosen answer goes amber, a beat of suspense, then green or red.

## Colors

The palette is a lit studio: cool blue light on navy, with warm gold reserved for the contestant.

### Primary
- **Spotlight Gold** (#ffc940): primary actions, the current ladder rung, selected arena, the player's score and name, stars, emphasis words in headlines. On gold fills, text is Ink (#07102a).

### Secondary
- **Lock-in Amber** (#ff9a1f): exists for one moment only, the locked-in answer before the reveal.
- **Correct Green** (#33d67e) and **Wrong Red** (#ff5568, filled as #b3192d): the reveal flash, result cells and score pips. They always come with text ("Right", "Wrong").
- **Cue Blue** (#8fb0ff): secondary information: category labels, "How to get there", link buttons, the warm-up label.

### Neutral
- **Stage Navy** (#050a1a): the page ground, carried by the html element so the stage lights can sit above it.
- **Panel Navy** (#14234d to #0b1534, top to bottom): every lit panel and every lozenge fill.
- **Board Blue** (#1d3f96 to #112763): category-board tiles only.
- **Rim** (#2c4a98) and **Rim Lit** (#6d93ff): lozenge edges at rest and on hover; Rim Lit also draws the answer rails.
- **Studio White** (#eef2ff), **Muted Blue** (#a9b8de), **Dim Blue** (#8796c0): text in three steps; all pass 4.5:1 on Panel Navy.

### Named Rules
**The Contestant's Gold Rule.** Gold marks what belongs to the player: their action, their place, their score. Never spend it on decoration or on the AI opponent.

**The One-Moment Amber Rule.** Amber appears only between the tap and the reveal.

## Typography

**Display Font:** Big Shoulders Display (with Arial Narrow fallback)
**Body Font:** Onest (with system-ui fallback)
**Code Font:** JetBrains Mono, for code, save codes and nothing else

**Character:** Condensed broadcast caps for the host voice set against a friendly, highly legible grotesk for the contestant's reading. Tabular figures throughout so scores and clocks never jitter.

### Hierarchy
- **Display** (900, clamp(3.1rem, 7.6vw, 5.9rem), 0.88, uppercase): the show's title card on the hero.
- **Headline** (900, clamp(2.3rem, 5.4vw, 3.6rem), 0.92, uppercase): section titles, verdict heads (2.1rem), lesson titles.
- **Title** (800, 1.3–2rem, 1, uppercase): era names, arena tiles, buttons (1.12rem), reveal heads.
- **Question** (Onest 700, clamp(1.25rem, 3.6vw, 1.55rem), 1.3): questions are read, not shouted, so they are never set in caps.
- **Body** (Onest 400, 15.5px, 1.55, max 46ch in section intros): explanations and copy.
- **Label** (Onest 700–800, 0.7–0.76rem, 0.08em tracking, uppercase): meta lines, side names, count labels.

### Named Rules
**The Host and Contestant Rule.** Big Shoulders caps are the host speaking; Onest is what the player reads. Never set a question or an explanation in display caps.

**The Mono Is For Code Rule.** JetBrains Mono appears only around code and save codes. It is never used as a "techy" label face.

## Layout

The page uses a single 1120px column with a 16px side gutter. Sections are separated by 56px of space (44px on phones), each opening with a large caps headline. The intro paragraph sits beside the headline on desktop and below it on phones.

- **Hero:** a two-column split on desktop (title and actions left, warm-up panel right under a follow-spot). On phones it reorders to title, then the question panel, then the buttons, then the copy, with the buttons stacked full width.
- **Category board:** 3 columns, 2 on tablets.
- **Prize ladder:** 3 era panels per row, 2 on tablets, 1 on phones.
- **Lessons:** a single-column running order.
- **Game layer:** a centred 660px column.

## Elevation & Depth

Depth comes from light rather than shadows:
- **Stage lights:** conic follow-spots and radial washes sit on a fixed layer behind the content.
- **Lit panels:** a vertical navy gradient with a 1px inner top highlight, and one soft drop shadow so each panel floats off the stage.
- **Lozenges:** lit by their rim colour, with no drop shadow.

### Shadow Vocabulary
- **Panel float** (`box-shadow: inset 0 1px 0 rgba(255,255,255,0.07), 0 22px 44px -18px rgba(0,0,0,0.7)`): every `.panel`.
- **Toast lift** (`box-shadow: 0 14px 30px -10px rgba(0,0,0,0.6)`): the gold toast only.

### Named Rules
**The Light Not Glow Rule.** Depth is stage lighting and panel gradients. No neon halos, no backdrop blur, no glass.

## Shapes

The lozenge is the show's silhouette. It is a hexagon-ended bar made with `clip-path`: a 16px cut by default, 14px on answers and rungs, 12px on small buttons and 10px on the close control.

- **How it is drawn:** the element's own background is the rim. The fill is a `::before` layer inset 1.5px with the same polygon, so the rim survives the angled ends.
- **Panels:** gently rounded (18px).
- **Category tiles:** 10px corners, and the board frame around them is 20px.
- **Tags and pills:** square-ish (4px).
- **Skewed parallelograms:** used for the small progress marks (score pips, streak week, result cells).

## Components

### Buttons
- **Shape:** lozenge (16px cut; 12px for `.btn-sm`).
- **Primary:** a gold gradient fill (#ffd766 → #ffc940 → #f0a800) with a pale-gold rim and Ink text in display caps (1.12rem, 0.04em tracking).
- **Ghost:** a Panel Navy fill with a Rim edge. On hover the rim turns Rim Lit and the fill lifts to #2a4590 → #172b62.
- **Disabled:** 40% opacity, with no lift.

### Answer lozenges (signature component)
- **Layout:** a full-width lozenge with a gold display-face key (1–4) and the answer text.
- **The rail:** the stack hangs between two 1px Rim Lit uprights that meet the lozenge points.
- **States:**
  - Hover lifts the fill.
  - Locked turns amber.
  - Correct flashes green twice.
  - Wrong fills deep red with white text.
  - Unchosen answers fade to 50%.
  - The bot's pick carries a small dark tag.

### Prize ladder rungs
- **Shape:** each level is a lozenge row showing its number in display caps, a status word and three stars.
- **Cleared:** gold number on a bronze rim.
- **Current:** a gold fill with Ink text.
- **Locked:** dim, with no stars.
- **Era panel header:** the era name in caps on the left, the year in gold on the right, and accuracy and speed stats below.

### Category board
A dark frame around lit blue tiles.
- **Tile content:** the arena name in display caps, a description in light blue, and a gold progress bar.
- **Selected tile:** a gold inner border, a gold name and a gold "Selected" tag.

### Cards / Containers
- **Corner Style:** gently rounded (18px).
- **Background:** the Panel Navy gradient with a 1px border (rgba(109,147,255,0.22)) and the panel float shadow.
- **Internal Padding:** 18–26px.

### Inputs / Fields
- **Style:** a Stage Navy fill with a 1px Rim Lit at 42% border and 10px corners.
- **Caret and accent:** gold.
- **Focus:** a 2px Rim Lit outline, offset by 3px.

### Chips
- **Style:** pill-shaped, with a raised navy fill, muted label text, and the value in gold.

### Navigation
- **Wordmark:** "YOU" in white and "DUMB" in gold, set in 900 caps.
- **Right side:** level and streak chips. The level chip is hidden on phones.

## Do's and Don'ts

### Do:
- **Do** give every answer-like or action-like control the lozenge silhouette.
- **Do** keep gold for the player's action, place and score (Spotlight Gold #ffc940).
- **Do** run the lock-in beat (650ms, removed under reduced motion) before every reveal, and stop the clock at the tap.
- **Do** keep the html element as the ground so stage lights at z-index -1 stay visible.
- **Do** pair every green or red state with words.

### Don't:
- **Don't** set questions, explanations or body copy in display caps.
- **Don't** add neon glows, glass blur or gradient text.
- **Don't** put a kicker or eyebrow label above a heading. Live status lines (`.onair`) go below the heading, and only when they carry live data.
- **Don't** use glyphs or emoji as icons on the page. Draw them as SVG; emoji live only in the copied share text.
- **Don't** use monospace outside code and save codes.
