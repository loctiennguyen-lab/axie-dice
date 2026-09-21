# FIX PASS 01 — Godot build vs. v2 handoff

Reviewed 2026-09-20 against the QA captures in `production/qa/evidence/2026-09-20_*.png`.
Read this **with** `design_handoff_axie_dice_ui/README.md`. Where the two disagree, **this file wins**.

---

## 0. Read this first

The token work is fine. `DangoTheme.gd` is correct, the colours are correct, the fonts are
correct, individual widgets (die cards, team cards, the Result stat ribbon, node tones) match
their redlines. **Nothing in this pass asks you to change a token value.**

What is wrong is one level above the widgets: **how a screen is composed.** The v2 spec redlined
elements and did not write down the laws that govern the screen those elements sit on, so the
build has elements that are individually right and screens that are collectively wrong. Six
symptoms repeat on almost every scene:

1. A panel is anchored to the bottom of the viewport, so a short list leaves 300–400px of empty
   panel (Pass, Guides, Vault).
2. A list is *not* anchored, so its last row is sliced by the viewport edge with no scrollbar
   (Unlocks, Vault, Main Menu team row).
3. `BACK` is a free-floating button at `PRESET_BOTTOM_LEFT` sitting on top of art or on top of
   content (Pass, Unlocks, Guides, Vault).
4. Every item in a list wears the same loud fill, so no state is legible — 24 identical green
   Pass tiles, 10 identical orange Unlocks prices.
5. White text on a saturated fill (die-card headers, END TURN, team-card headers) — 2.2–2.4:1.
6. The black outline + hard shelf is on half the objects. Cream cards have it; dark chrome
   (top bar, mana card, relic slots, unlock rows, pass tiles) does not, so the two halves of the
   game look like they came from two projects.

**Work in this order:** §1 laws on every scene first, then §2 per-screen defects. Do not start
with §2 — most of §2 disappears once the laws are in.

---

## 1. Screen laws — apply to EVERY scene before any per-screen fix

These are new. They are not in the v2 spec and that is why they were missed.

### L1 · Safe area
Every screen has a **48px** margin on all four sides (Combat's top bar and deck bar are the only
full-bleed objects in the game). Nothing may be positioned, anchored or clipped outside it. The
current screens use 84px left/right and **0px bottom**, which is where the clipping comes from.
Left/right may stay 84; **bottom must become 48 and must be respected.**

### L2 · A screen either fits or scrolls — never both empty and clipped
For any content region:
- Measure the content's natural height.
- If it fits: the container hugs it (L3) and the region is **top-aligned**, leaving honest empty
  art below. Empty painted background is fine. Empty *panel* is not.
- If it does not fit: `ScrollContainer`, `clip_contents = true`, **and a visible scrollbar** —
  `style_scrollbars()` is applied in several scenes but the bar has no width, so it is invisible.
  Add `custom_minimum_size.x = 10` to the VScrollBar and a 24px fade at the bottom edge of the
  panel so the player can see there is more.

A row cut in half by the bottom of the screen with no scrollbar (`2026-09-20_meta-v2_unlocks.png`,
row 10) is the single worst defect in this build. It reads as a crash.

### L3 · A panel hugs its content
Do not anchor a content panel to `anchor_bottom = 1.0` with a negative offset. Let the child
container set the height and cap it at the safe area:

```gdscript
panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
panel.offset_top = 202.0
panel.offset_left = 84.0
panel.offset_right = -84.0
# NOT: panel.anchor_bottom = 1.0; panel.offset_bottom = -96.0
# height comes from the grid; if it would exceed (1080 - 202 - 48 - footer), wrap in a scroll
```

`PassView._build_track_panel()` is the exact case: 5 rows of tiles in a panel that reaches the
bottom of the screen = 400px of empty `PANEL`. Same pattern in `GuidesView` (cards stretched to
the column height, 350px of empty cream under each CTA) and `VaultView`.

### L4 · `BACK` lives in a footer, never on the art
One shared footer on every meta screen:
- Full width, **72px** tall, anchored to the bottom safe area, `Surface.PANEL` fill, black 3px
  **top border only**, no shelf (it is frame, not an object).
- `BACK` is a `secondary_button_style()` at the left inside it, min height 44.
- The primary action of that screen, if it has one, sits at the right of the same bar.

Build it once as `DangoTheme.build_footer(host) -> HBoxContainer` and call it from Pass, Unlocks,
Guides, Vault, Codex and Settings. The content region's bottom limit becomes `-48 - 72`.

### L5 · One loud state per list
In any repeated list, **at most one state carries a saturated fill.** The others step down. Use
this ladder, which is already fully tokenised:

| meaning | fill | ink |
| --- | --- | --- |
| actionable now | `SUCCESS` / `PRIMARY` solid | `INK_ON_SUCCESS` / `INK_ON_PRIMARY` |
| already done | `CREAM_TRACK` | `INK_ON_CREAM_MUTED` |
| available but unaffordable | `DISABLED_FILL` | ink at **full** strength |
| locked / future | `WELL` | `FAINT_TEXT` |

A screen where every row is orange, or every tile is green, is a screen with no hierarchy. The
Pass currently shows *claimed* and *claimable* as the identical green tile, which is not a style
problem — it is wrong information.

### L6 · Ink on fill, never white on colour
`DangoTheme.ink_on(fill)` exists. Any text sitting on `PRIMARY`, a class colour, a rarity colour
or a status colour goes through it. Three known violations:
- `END TURN` — the call site passes `Color.WHITE`. **Delete the argument**; `style_button(btn, true)`
  already inks primary buttons at `INK_ON_PRIMARY` (11.4:1).
- Die-card headers (`Olek` white on `#7DC943`, 2.4:1) → `ink_on(class_color(cls))`.
- Team-select and Result nameplate headers — same fix.

### L7 · Outline and shelf are not optional
Every object that is not the page frame gets **pure black** border and a hard shelf
(`shadow_size = 0`, y-offset only). Chips 3px, cards and rails 4px, hero objects 5–6px.
Currently missing on: Combat top bar and its utility buttons, the mana card, the relic-active
slots, Result's stat ribbon and info strip, Unlocks rows, Pass tiles, Vault's import panel, the
Main-Menu meta nav tiles. These all render as flat dark rectangles and are the reason those
areas still look like the pre-redesign dashboard.

### L8 · Type floor
**12px absolute minimum**, and 12 only for an all-caps chip label. Body captions are 13.
Anything a player reads mid-combat is 15+. Violations to fix: Combat enemy nameplates (~11),
the intent `-> Buba` line (~10), Main-Menu meta tile captions (11), Result stat-ribbon labels
(11), Guides difficulty tags (11), Vault's `AxieCharacter3D · FROM GENES` placeholder (11).

---

## 2. Per-screen defects

Evidence file in brackets. Fixes are ordered by how much they change the screen.

### 2.1 COMBAT — `scenes/combat/CombatView.gd`, `Combat.tscn`
[`2026-09-20_real-flow-varied-enemies.png`]

**C1 · Enemy nameplates are half size and unreadable.** Currently ~130×36 with ~11px text. Spec:
**176×64**, name 17px display/700, HP 15px, class dot 10px, black 3px, shelf 4, `PANEL_DEEP`.

**C2 · HP bars ignore `hp_color()`.** Every bar on screen is `SUCCESS` regardless of percentage,
enemy and party alike. Route every fill through `DangoTheme.hp_color(pct)`. This is a
*mechanical* regression, not a visual one — the threat read is gone.

**C3 · Intent badges are detached and sometimes empty.** They float ~90px above the model with
no connection to the unit, they vary in width, and Pyrewing renders an **empty black plate**.
Fix: anchor the intent badge to the top edge of its nameplate with a 6px gap, same 176px width,
and `hide()` the node when there is no intent rather than drawing an empty box.

**C4 · Target text is 10px unreadable art overlay.** `-> Buba` in cream directly on the
background. Move it inside the intent badge: `[icon] 7 → Buba` at 14px, inked with `ink_on()`
against the badge fill. Use `→`, not `->`.

**C5 · The front-line rule spans the entire 1920 with diamond end caps.** It currently reads as a
divider across the whole screen. It marks the front rank only: inset to the party bounding box
+80px each side, 3px black at 55%, **no end caps**.

**C6 · Bottom-left is still two v1 panels.** `MANA` and `RELIC ACTIVES 0/4` are separate floating
boxes. v2 consolidates: one full-width `DECK` bar behind the die cards, mana at its left end,
relic actives at its right end, die cards centred. The four empty relic slots must be `WELL`
squares with a black 3px outline — right now they are pure-black holes that read as missing art.

**C7 · The wave track is a raw stripe bar.** No container, no states. `WELL_TRACK` trough,
radius 8, black 3px; pips: cleared `CREAM_TRACK`, current `CREAM_HI`, future `FUTURE`, boss
`DANGER`. Today it reads as a loading bar.

**C8 · Top bar and utility buttons have no outline or shelf.** `Undo / Info / Log / Sound / Quit`
are ghost outlines at ~32px tall. Make them `PANEL_RAISED` + black 3 + shelf 4, min height 40,
label 15px display. The `YOUR TURN | TURN 1` pill also has a stray dark circle bleeding out of
its left edge — rebuild it as one chip: `PRIMARY` segment with `INK_ON_PRIMARY`, `PANEL_RAISED`
segment, one shared black outline.

**C9 · `END TURN` is white on orange.** See L6. Delete the `Color.WHITE` argument at the call
site. (The note in `DangoTheme.gd` saying this is "out of scope" is now out of date — it is in
scope; fix it.)

**C10 · Die cards have a dead centre.** ~40px of empty cream under the numeral, and the keyword
chips from the mockup are absent. Add the chips (`kw_chip_style()` is already written and unused
here) or drop the card height to 132 and close the gap. Header ink per L6.

### 2.2 RUN MAP — `scenes/run_map/RunMapController.gd`
[`2026-09-20_run_map_v2.png`]

**R1 · `SAVE & QUIT` is a second floating panel** 200px below the rail. The rail is one object:
merge it in as the bottom row of the same `PANEL_DEEP`, rail top 32 → bottom 32, width 344.

**R2 · Node tokens are single-tone squares.** `NODE_TONES` returns three tones (base / top block
/ lip) and only the base is being used, so tokens read as flat stickers instead of objects.
Draw the top block over the upper 44% and the lip over the lower 19%. Radius 14, black 4,
shelf 5.

**R3 · Art bleeds out from behind the current node** — a green axie head is visible above the
purple token. Clip node art to the token rect and fix the z-order.

**R4 · Exactly one node has a type label** (`BATTLE`) and it is not the current node, so it looks
like a bug. Either label every revealed node or make the label follow hover.

**R5 · Edges are 10px dashed black railway track** and are the loudest thing on the screen.
4px, black at 70%, dash 10/8. The edge into the current node is `PRIMARY`.

**R6 · Party rows:** HP bars ignore `hp_color()` (same as C2); portraits need black 3 + radius 10.

**R7 · Fog nodes use grey `PANEL_RAISED`** instead of the `"fog"` entry that already exists in
`NODE_TONES`.

### 2.3 RESULT — `scenes/result/ResultView.gd`
[`2026-09-20_menu-result_05_result_victory.png`]

**S1 · The nameplate covers the bottom third of the art tile.** Spec: 186px art band, nameplate
**below** it, not overlapping. Art tile also needs the black 4px outline it is missing.

**S2 · Class identity is carried only by the art-tile background.** The nameplate should be the
class-colour band with `ink_on()` ink, per the Result redline.

**S3 · Stat ribbon:** structure is right (6 cells, one panel). Dividers run the full inner height
and touch the border — inset 14px top and bottom and use `primary_divider_alpha()`. Labels are
11px → 13px `CAPTION_MUTED`.

**S4 · "This run was not Ranked…" is a 30px strip of dead chrome** across the full width. Fold it
into the GENE SHARD card as a caption line.

**S5 · `RELICS CARRIED` chips overflow and wrap 2+1,** and they are the only blue objects on the
screen. Fill each with `rarity_color(rar)` + `ink_on()`, lay out as a 2-column grid, and let the
panel hug them.

**S6 · A black band along the bottom edge** — the plate is not covering the viewport. Force
`EXPAND_IGNORE_SIZE` + `STRETCH_KEEP_ASPECT_COVERED` and check the source texture's aspect.

### 2.4 MAIN MENU — `scenes/main_menu/MainMenu.gd`
[`2026-09-20_menu-result_01_mainmenu_default.png`]

**M1 · The team row is clipped by the bottom of the screen** (L1/L2). Lift it to `-48` and cap
the card at 220px, or reduce the row to portraits + name.

**M2 · The six meta nav tiles are 11px, 44px tall, outline-less, and one is empty** (`COLLECTION —`).
`PANEL_ON_ART` + black 3 + shelf 4, label 13, value 20, min height 64. **Remove any tile with no
value** — an empty tile is worse than a missing one.

**M3 · `?` and gear buttons are 36px.** 44 minimum.

**M4 · The SHORT/FULL toggle uses a muddy brown fill** that is not a token. Selected = solid
`PRIMARY` + `INK_ON_PRIMARY`; unselected = `PANEL_RAISED` + `TEXT`.

**M5 · The ascension stepper is 380px of empty field** between two unoutlined 56px squares.
Compress the whole control to ~220px and give the `−`/`+` buttons the standard raised treatment.

### 2.5 TEAM SELECT — `scenes/main_menu/TeamSelect.gd`
[`2026-09-20_menu-result_03_teamselect_default.png`]

This screen is the closest to the mockup in the build. Three things:

**T1 · The `Olek (Plant)` dropdown is stock Godot chrome** sitting on cream. Restyle it or remove
it — the class is already in the header and in the art.

**T2 · Card headers are white on class colour** (L6).

**T3 · `CONFIRM TEAM` has no shelf** while every card next to it does.

### 2.6 LUNACIA PASS — `scenes/pass/PassView.gd`
[`2026-09-20_meta-v2_pass.png`]

**P1 · 24 identical green tiles.** Claimed and claimable are indistinguishable. Apply L5:
claimable = `SUCCESS` + `INK_ON_SUCCESS`, and only these say `CLAIM NOW`; claimed = `CREAM_TRACK`
+ `INK_ON_CREAM_MUTED`, label `CLAIMED`; locked = `WELL` + `FAINT_TEXT`. On a max-level pass the
screen should be mostly calm cream with the few unclaimed tiles glowing — not a green wall.

**P2 · 400px of empty panel** under the grid (`_build_track_panel()`, `anchor_bottom = 1.0`,
`offset_bottom = -96`). Apply L3.

**P3 · `BACK` floats on the art** at `(84, -72)`. Apply L4.

**P4 · The level pip shifts the tile's title baseline** between 1-digit and 2-digit numbers. Fix
the pip at 32×32.

### 2.7 UNLOCKS — `scenes/unlocks/UnlocksView.gd`
[`2026-09-20_meta-v2_unlocks.png`]

**U1 · Row 10 is sliced by the bottom of the screen with no scrollbar** (L2). Highest-priority
defect in the build.

**U2 · Ten identical orange price buttons.** Affordable and unaffordable look the same. Apply L5:
affordable `PRIMARY` + `INK_ON_PRIMARY`; unaffordable `DISABLED_FILL` with the number at full
strength; owned `owned_button_style()`.

**U3 · `AVAILABLE` chips say nothing** — available is the default state, and they compete with the
price button for the same attention. Delete them. Keep `NO EFFECT YET` (`WARN_YELLOW`) and add
`OWNED`.

**U4 · Rows have no outline** (L7) and **`BACK` floats over the clipped row** (L4).

### 2.8 GUIDES / SAMPLE TEAMS — `scenes/guides/GuidesView.gd`
[`2026-09-20_meta-v2_guides.png`]

**G1 · Every card has 350–400px of empty cream below its CTA** because the cards stretch to the
column height (L3). Let them hug their content; four cards ending at different heights is
correct and honest.

**G2 · `USE THIS TEAM` sits at a different Y and a different width in each card.** If you keep
equal-height cards instead, pin the CTA to the card's bottom padding with an expanding spacer
above it and give all four the same width.

**G3 · `BACK` overlaps card 1** (L4).

**G4 · The difficulty tag is 11px** (L8) → 13px.

### 2.9 THE VAULT — `scenes/vault/VaultView.gd`
[`2026-09-20_meta-v2_vault.png`]

**V1 · One 355px column of cards in a 1920px screen,** with card 2 clipped at the bottom and 60%
of the screen empty art. Make the card area a 3-column grid filling the content region, scrolling
per L2.

**V2 · `SCAN` is a muddy brown that is not in the palette.** `PRIMARY` + `INK_ON_PRIMARY`.

**V3 · The 3D preview well is an empty cream box** with an 11px placeholder string and a
"No gene data" strip. Empty state = `WELL` fill (not cream), one 15px centred line, no
developer-facing class name on screen.

**V4 · The import panel and RANKED note have no outline** while the cream cards beside them do
(L7).

**V5 · `BACK` floats on art** (L4).

---

## 3. Do not do any of these

- Do not darken a plate to fix a contrast failure. Put the text on a plate instead.
- Do not change any value in `DangoTheme.gd`'s colour block. Add tokens only if a fix above
  genuinely has no existing token (it should not).
- Do not solve empty space by stretching a panel to fill it. Empty painted background is the
  intended result of a short list.
- Do not add a new chip, badge or eyebrow anywhere. Several screens need *fewer* labels, not more.
- Do not blanket-`modulate.a` a disabled surface. Desaturate the fill, keep the ink at full
  strength.

---

## 4. Acceptance check

Re-capture all nine QA screens and confirm each line:

- [ ] No element is clipped by any screen edge. No scrollable list without a visible scrollbar.
- [ ] No panel has more than ~80px of empty fill below its last child.
- [ ] `BACK` appears inside a footer bar on Pass, Unlocks, Guides, Vault, Codex, Settings — and
      never on top of art or content.
- [ ] No white text on `PRIMARY`, a class colour, or a rarity colour anywhere in the build.
- [ ] Every HP bar in Combat and on the Run Map changes colour at 60% and 30%.
- [ ] No text below 12px; no combat-critical text below 15px.
- [ ] Every non-frame surface has a pure-black border and a hard shelf. No blurred shadows.
- [ ] Pass, Unlocks and the Result relic list each show at least two visually distinct states.
- [ ] Combat's bottom-left is one deck bar, not two floating panels.
- [ ] No empty badge, empty tile or placeholder class name is visible on any screen.
