# FIX PASS 03 — the whole UI, as one normative spec

**Tóm tắt cho người đọc (VN):** Đây là bản duy nhất có hiệu lực. Ba pass trước đã bị hiểu sai
vì chúng viết toạ độ tuyệt đối, mâu thuẫn với nhau, và không nói rõ một luật áp dụng cho
*những cái nào*. File này viết lại toàn bộ 13 màn hình theo **quan hệ giữa các thành phần**
(không phải toạ độ), mỗi mục có ID, có câu "Applies to" liệt kê đủ tập hợp, và có cách kiểm
tra. Khi file này khác các file cũ — file này thắng.

---

**Status:** normative. **Supersedes:** `FIX-PASS-01.md`, `FIX-PASS-02.md`,
`FIX-PASS-02-START-HERE.md`, `consistency-sweep.md`, and every `.gd` file shipped with those
passes. Those are now historical; do not re-read them for intent. Anything in them that is not
restated here is **dropped, deliberately** — see §10 for the short list of things I know were
open and am explicitly closing.

**Source of this spec:** the three design files, as of 20 Sep 2026:
`Godot Combat v2`, `Godot Run Flow v2`, `Godot Meta Screens v2`. Thirteen screens.

**What I can and cannot claim.** I am writing from the design files, not from a capture of your
build. So **nothing below is labelled OBSERVED-in-game.** Every item is a TARGET plus a CHECK.
Read the check first: if the build already satisfies it, tick the item and move on — a large
fraction of this document may already be true, and that is a good outcome, not a wasted pass.
Where I state that something is *currently wrong*, I say what I am inferring it from.

---

## 0 · How to read one item

Every item below has the same five fields. None of them is decorative.

| Field | Meaning |
| --- | --- |
| **ID** | Quote it in commits and in questions back to me. |
| **Applies to** | The **complete** set. If it says "every nameplate, party and enemy", implementing it for enemies only is a failed item, not a partial one. This field exists because that exact failure happened in pass 02. |
| **Target** | What it should be. Positions are stated as relationships; sizes, paddings, radii, borders and type sizes are absolute numbers and should be typed in as written. |
| **Check** | How you know it is done. Prefer the cheapest one that discriminates. |
| **Visible** | `player` = someone playing will see the difference. `internal` = they will not. Do not schedule a block of `internal` items and expect the screen to look different afterwards. |

**If an item is ambiguous, stop and ask.** One question costs a message. A guess costs a round
trip, and three of those are why this file exists.

---

## 1 · The four facts, and the one that keeps breaking things

| | |
| --- | --- |
| Engine | Godot 4.7.2, GDScript, source under `godot/`. |
| Canvas | `stretch/mode="canvas_items"`, `stretch/aspect="expand"`, base 1920×1080. **Keep `expand`. Do not change it to `keep`.** |
| Tokens | `godot/scenes/shared/DangoTheme.gd`. Every colour, surface, chip and button in this document already has a token there. Use the token, never a fresh literal. |
| Shell | `godot/scenes/shared/DangoScreen.gd` — safe area, content column, footer, fit-or-scroll. |
| Gate | `godot/tools/run_tests.sh`. Red gate does not ship. |

**`expand` does not letterbox.** It keeps horizontal scale and grows the logical viewport
vertically. On a 2387×1540 window the game lays out in roughly 1920×1238 logical pixels. So:

> **1920×1080 is the minimum canvas, not the design canvas.**

Consequences that are binding on every item in this file:

- **No item below gives a y coordinate**, and none should be invented from the design files.
  Where I write "28px below the run card", that is the spec — not a starting point for
  measuring a pixel offset off a mockup.
- **Full-bleed objects** (combat top bar, combat deck, meta footer) anchor to a real viewport
  edge and stretch. Everything else lives inside the content column.
- **Content column:** centred, width `min(viewport_w − 2 × 84, max_w)`. Per-screen `max_w` is
  given in each screen's header row below. Extra width becomes margin, never stretch.
- **Vertical slack goes to the bottom.** A screen whose content fits is top-aligned inside the
  safe area with honest empty artwork below it. Empty *painted background* is fine; empty
  *panel* is not.

---

## 2 · What changed since pass 02 — read this even if you read nothing else

Three of these came in from review today and contradict earlier passes. They win.

| ID | Change | Was |
| --- | --- | --- |
| **G-01** | A colour block never stands alone for a mechanic. Every type/status/effect swatch carries that effect's icon inside it. | Plain coloured square |
| **G-02** | A portrait never overlaps type. On the Result nameplate the overlap is **8px**, not 16, and the plate's top padding rises to 16. | 16px overlap, name clipped |
| **G-03** | No decorative Axie sprite on the Run Map. Player position is the ring + the `YOU ARE HERE` chip, nothing else. | A bobbing back-view Axie at the current node |
| **G-04** | Combat nameplates are **176 wide** — 64 tall enemy, 68 tall party. | Pass 02 said `196×64`. That number is dead. |

---

## 3 · Global laws — true on all thirteen screens

These are the rules that make the screens look like one game. A widget that matches its own
redline and breaks one of these is wrong.

**L1 · One outline, pure `#000000`.** 3px on chips, bars, small tiles. 4px on cards, rails,
buttons, ribbons. 5–6px on hero objects (reward cards, modal, node "here" ring, big CTAs).
Never a translucent hairline, never a coloured border except the two named exceptions:
the party nameplate's 6px class-coloured top edge, and a warning button's `DANGER` outline.

**L2 · Two flat tones per surface, no gradients.** A base fill and at most one lighter block —
a solid band, not a ramp. The only gradients in the whole game are the background scrims.
The map node's three tones (base / top 44% / lip 19%) are three *blocks*, not a gradient.

**L3 · Shadows are hard shelves.** `shadow_size = 0`, `shadow_offset = Vector2(0, n)`,
n ∈ {3,4,5,6,7,8}. A blurred shadow anywhere is a defect. A pressed button *drops its shelf and
translates down by the same amount* — the shelf being taken away is the press.

**L4 · Colour is a solid fill, never a wash.** No 8–20% alpha tints of a status colour. The one
sanctioned tint in the system is `DangoTheme.primary_divider_alpha()` for hairline dividers.

**L5 · Ink is chosen per fill, never by desaturating the fill.** `DangoTheme.ink_on(fill)`.
A contrast failure is fixed by changing the ink or putting the text on a plate — never by
muting a class colour, a rarity colour or a status colour.

**L6 · Type.** Baloo 2 for every title, every button label, every chip label and **every
numeral, everywhere**. Work Sans for prose only — log lines, passive text, item descriptions,
event copy. No per-`Label` font overrides; it all resolves through the one Theme.
Floor: 12px and only for an all-caps chip label; 13px for captions; 15px for anything read
mid-combat. Multi-line Baloo needs `DangoTheme.leading_for()` or it opens a 0.6em hole.

**L7 · G-01, stated as a law.** Any square/round swatch that encodes a *mechanic* — die face
type, status, intent, relic slot — contains that mechanic's icon from `assets/fx/`, sized to
about 60–65% of the swatch. The fill carries the colour, the glyph carries the meaning. A
swatch that encodes *rarity* or *class* is exempt: those are identities, not mechanics, and
they are always adjacent to their own name.

**L8 · One loud state per list.** At most one row state in any repeated list gets a saturated
fill. Ladder: `ACTIONABLE` (loud) → `DONE` (`CREAM_TRACK`) → `UNAFFORDABLE` (`DISABLED_FILL`,
ink at full strength) → `LOCKED` (`WELL`). Already in `DangoTheme.ListState`.

**L9 · Portraits and type do not overlap.** Where a plate tucks under a portrait, the overlap
is at most 8px and the plate's top padding absorbs it. (G-02.)

**L10 · Every screen paints plate → scrim → UI, in that order**, via
`DangoTheme.build_plate()`. Never darken the plate to win a contrast fight; give the text a
plate of its own.

---

## 4 · COMBAT

Content: full-bleed. Top bar and bottom deck are the only two objects in the game allowed to
touch the viewport edge. Everything between them is the stage.

**Vertical structure, top to bottom:** top bar (60, anchored top) · enemy band · front line ·
party band · deck (216, anchored bottom). The two bands split the remaining height; the front
line sits on the boundary. Enemy and party columns are bottom-aligned to their band, so units
of different heights stand on one floor.

| ID | Item |
| --- | --- |
| **CB-01** | **Top bar.** Full-bleed, height 60, `PANEL`, 4px black **bottom** border only, **no shelf**, inner padding 0/18, gap 11. It is frame, not an object — use `DangoTheme.frame_bar_style(SIDE_BOTTOM)`.<br>**Applies to** the combat top bar only. **Check** no rounded corners, no side borders, no shadow offset. **Visible** player. |
| **CB-02** | **Node chip** (left): height 36, `PANEL_RAISED`, 3px black, radius 11. Inside: 31px square tile in the node's own colour (3px black, radius 9) holding a 20px node icon; then a two-line block — eyebrow `BATTLE NODE` 9px w700 tracking .15em `MUTED_TEXT`, and `WAVE 3` Baloo 19px `CREAM_RAISED` with ` / 12` in `#7C8695`. **Visible** player. |
| **CB-03** | **Wave track**, immediately right of the node chip: height 33, `WELL_TRACK`, 3px black, radius 10, inner padding 0/8, pip gap 4. One pip per wave, height 10, radius 4, 2px black. Width 11 normally, **17 for the current wave**, 14 for the boss. Fill: past `PRIMARY`, current `CREAM_HI`, boss `DANGER`, future `FUTURE`.<br>**Applies to** every wave in the run, boss included — the track is generated from the wave count, never a fixed twelve. **Visible** player. |
| **CB-04** | **Turn pill**, horizontally centred in the bar and independent of the widths either side of it: height 40, radius 999 (the only pill in combat), `PRIMARY`, 3px black, shelf 4. Contents: a 9px `INK_ON_PRIMARY` dot blinking 1.6s, `YOUR TURN` Baloo 16 tracking .1em, a 2px divider at 35% ink, `TURN n` Baloo 15 in `#5A3310`. On the enemy's turn the pill reads `ENEMY TURN` on `DANGER` with `CREAM` ink and the dot stops. **Visible** player. |
| **CB-05** | **Right cluster**, in this order: relic chips → shard chip → utility buttons. Relic chip 33×33, radius 9, 3px black, filled with the relic's rarity colour, 18px icon centred. Shard chip height 33, `CREAM`, 3px black, 19px shard icon + Baloo 18 `INK`. Utility button height 33, min width 33, `PANEL_RAISED`, 3px black, radius 9, label Baloo 13; **hover fills `PRIMARY` and inks `INK_ON_PRIMARY`**.<br>**Applies to** all four utilities (UNDO, INFO, LOG, audio). **Visible** player. |
| **CB-06** | **Front line.** A 6px black rule inset 40px from each side, with a 2px `CREAM` @16% highlight one pixel below it inset 44px, and a 14px black square rotated 45° at each end, centred on the rule. It is not a panel and never eats a click. **Visible** player. |
| **CB-07** | **Unit column, enemy.** Width 186, children bottom-aligned, gap 8, in this order: intent badge → status strip → nameplate → model. **Applies to** every enemy including bosses and summons. **Visible** player. |
| **CB-08** | **Unit column, party.** Width 180, gap 5, in this order: status strip → nameplate → model. The party has no intent badge; the enemy has no incoming-damage chip. **Applies to** all five party slots. **Visible** player. |
| **CB-09** | **Nameplate geometry — G-04.** **176 wide.** Enemy 64 tall; party 68 tall (the extra 4 is the class edge). Both: `PANEL_DEEP`, 3px black, radius 12, shelf 4, padding 5/10, `box-sizing` border-box so the width is the outer width. The party plate additionally has a **6px top border in the Axie's class colour** — this is L1's first named exception.<br>**Applies to EVERY nameplate in combat — all five party plates and every enemy plate.** One width, one height per side, regardless of how long the name is. No text-measured widths. **Check** five party plates measure identical rects. **Visible** player. |
| **CB-10** | **Nameplate contents.** Row 1, height 20: name Baloo **700** 17px, ellipsised, left; then (party only) the incoming chip; then HP `cur/max` Baloo **800** 18px in `hp_color(pct)`, right, never shrinking or wrapping. Row 2, 4px below: HP bar, height 8, radius 5, trough `WELL_DEEP`, 2px black, fill `hp_color(pct)`, width animates over .3s. Row 3, 4px below: **shield bar**, identical geometry, fill `INFO`, width = `shield / max_hp` clamped to 100%.<br>**Applies to** every nameplate. Shield is its own bar under HP — it is never a segment inside the HP track and never a badge overlapping the HP number. **Visible** player. |
| **CB-11** | **At-risk slice** (party only): inside the HP bar, a `AT_RISK` block occupying the right end of the current fill, width = `min(hp, max(0, incoming − shield)) / max_hp`. It sits **on** the fill, not beside it, so the player reads "this much of what I have is already spoken for". **Applies to** every party member with committed incoming damage. **Visible** player. |
| **CB-12** | **Incoming chip** (party only): between the name and the HP number, height 18, radius 6, `DANGER`, no border, 12px `dmg` icon + Baloo 14 `CREAM_RAISED`. Hidden entirely when incoming is 0 — hidden, not dimmed. **Visible** player. |
| **CB-13** | **Status strip.** A centred row, fixed height 28 whether or not it holds anything, so the nameplate below it never moves as statuses come and go. Chip: height 28, radius 9, 3px black, solid status colour, 16px icon + count Baloo 16 inked by `ink_on()`. **Shield appears here too**, first in the row, as an `INFO` chip. **Applies to** party and enemy alike. **Visible** player. |
| **CB-14** | **Intent badge** (enemy only): height 36, radius 10, padding 0/9/0/5, fill `DANGER` for damage or `INFO` for shield/support, 3px black, shelf 4. Contents: a 22px round-ish inner tile at 26% black holding the 16px intent icon, the value Baloo 20 `INK`, a 2px divider at 28% black, and the **target line inside the same badge** — Baloo 11 tracking .04em, `#2A0806`, non-wrapping, written `→ BUBA` with a real arrow.<br>**Applies to** every enemy intent badge. There is no party equivalent. The target text is never a sibling floating on the artwork. **Visible** player. |
| **CB-15** | **Targetable ring.** When a die is selected, every legal target gets a ring inset −10 from its model box: 4px `PRIMARY` for enemies, 4px `SUCCESS` for party, with 3px black both outside and inside the coloured stroke. Illegal targets get nothing — no dimming of the rest of the board. **Applies to** both rows. **Visible** player. |
| **CB-16** | **Status aura.** A unit carrying a status stands on a **solid ellipse** in that status colour with a 3px black edge, ~152×30 under enemies and ~156×30 under the party, under the existing black contact shadow. It is a floor decal with a hard edge — never a soft radial wash, which reads as dirt. **Visible** player. |
| **CB-17** | **Damage floats.** Baloo 800, 58px over enemies / 54px over party, colour = the face type's colour, outlined in black on all four sides (not a blur), rising ~72px and fading over 1.15s. **Applies to** damage, heal, shield and mana events alike. **Visible** player. |
| **CB-18** | **Deck bar.** Full-bleed, height 216, `DECK`, 4px black **top** border only, no shelf, no radius. Inner region inset 16 top/bottom, 24 left/right, three columns bottom-aligned with gap 18: left rail 272 fixed, die row flexible and centred, right rail 272 fixed. **Visible** player. |
| **CB-19** | **Mana row** (left rail, top): height 54, `WELL`, 2px black, radius 13, padding 0/12. A 40px circle in `MANA_PURPLE` with 2px black holding the current mana Baloo 21 `INK`; `MANA` Baloo 17 tracking .1em; and a right-aligned two-line 11px Work Sans caption in `MUTED_TEXT` reading `only spent / on actives`. **Visible** player. |
| **CB-20** | **Relic actives rack** (left rail, below mana, 9px gap): `WELL`, 2px black, radius 13, padding 9/11/11. Header row: `RELIC ACTIVES` Baloo 13 tracking .14em `MUTED_TEXT`, and `n / 4` right, `INFO_TEXT_ON_WELL`. Then **always exactly four 55×55 slots**, radius 12, 2px black, gap 7, each a centred icon over its cost line Baloo 12.<br>Slot states: affordable = `MANA_PURPLE` fill, `INK` cost; unaffordable = `DISABLED_FILL` fill, cost in `#FF9A96` at **full strength** (the cost is the reason the slot is dim — never drop its alpha); empty = `#161A22` with the icon at 28% and an em-dash. Holding more than four collapses the fourth into a `+n` slot; the rack never grows and never shifts the die row.<br>**Applies to** every combat, including one where the player holds zero actives. **Visible** player. |
| **CB-21** | **Die card.** 180 wide × 158 tall, `CREAM`, 4px black, radius 15, shelf 6. Row gap in the die row is 14. **Applies to** all five cards; a spent card keeps its slot. **Visible** player. |
| **CB-22** | **Die card header:** height 36, fill = the Axie's class colour, 3px black bottom border, top corners 11. Holds a 26px round portrait (`CREAM_RAISED`, 3px black, image cover) and the name Baloo 18 `INK`, ellipsised. **Applies to** all five. **Visible** player. |
| **CB-23** | **Die card face row:** height 62, padding 9/10/0. A 41px part tile (`CREAM_RAISED`, 3px black, radius 11) holding the **part icon at 28px**, then the face value Baloo 38 with 0.9 leading, then a **26×26 type swatch: radius 8, 3px black, filled with the type colour, containing the 16px type icon** (L7/G-01), then under the value a 9px Baloo 700 caption `BACK · SHIELD` in `INK_ON_CREAM_MUTED`. A buff/debuff face shows `•` as its value. **Applies to** every die card and every face. **Visible** player. |
| **CB-24** | **Die card keyword row:** height 24, padding 0/10, gap 4. Each keyword is a pill: height 20, radius 999, filled with **the face's own type colour**, 3px black, label Baloo 12 tracking .03em inked by `ink_on()`. The row keeps its height when the face has no keywords. **Visible** player. |
| **CB-25** | **Die card face track:** six equal bars, height 10, radius 5, 2px black, gap 4, padding 4/10/0. The rolled face's bar is its type colour; the other five are `CREAM_TRACK`. This is the only place the whole die is visible during combat, so it is never abbreviated to fewer than six. **Visible** player. |
| **CB-26** | **Die card states.** Selected: the card translates **up 16px** (.16s, overshoot easing) and gains a ring inset −6, 4px `PRIMARY` + 3px black, radius 21. Spent: opacity .55, no ring, not clickable. Selection is exclusive; clicking the selected card deselects. **Visible** player. |
| **CB-27** | **REROLL button** (right rail, above END TURN, gap 10): height 56, `PANEL_RAISED`, 3px black, radius 14, shelf 4, padding 0/16. Left group: 22px reroll icon + `REROLL` Baloo 20. Right: a count chip, height 28, radius 9, 2px black — `PRIMARY`/`INK_ON_PRIMARY` when rerolls remain, `WELL_TRACK`/`FAINT_TEXT` at zero, written `×2`. **It is a count, not pips** — relics and the Aqua passive make the maximum open-ended. Hover fills `PRIMARY`; press drops the shelf to 2 and translates down 2. **Visible** player. |
| **CB-28** | **END TURN**: height 72, `PRIMARY`, 4px black, radius 15, shelf 6. Label Baloo 26 tracking .08em **`INK_ON_PRIMARY`** — never white, never `CREAM`. A `SPACE` chip sits inside it at the right: height 24, radius 7, fill `INK_ON_PRIMARY`, text Baloo 13 `CREAM_HI`. Hover `#FFAC6B`; press `#E2761F`, shelf 2, translate down 4. **Visible** player. |
| **CB-29** | **Turn banner**: centred on the stage, `DANGER`, 5px black, radius 20, shelf 7, padding 18/64. Eyebrow Baloo 16 tracking .3em in `#3A0A08`; title Baloo 56 `CREAM_RAISED`. Scales in, holds, fades out over ~1.5s and never blocks a click. **Visible** player. |
| **CB-30** | **Unit inspector.** Scrim `rgba(11,13,18,.82)` over the whole viewport, closing on click. Panel 500 wide, centred, `CREAM`, 5px black, radius 20, shelf 8, clipped so the header band's corners are cut by the card, not rounded separately.<br>Header: fill = class colour (or `DANGER` for an enemy), 4px black bottom border, padding 13/18 — a 54px round portrait (`CREAM_RAISED`, 3px black), name Baloo 27 `INK`, meta line Work Sans 13 at 74% ink, and a class chip pinned right (fill `INK`, text `CREAM`, radius 999, Baloo 12).<br>Body: a passive block on `CREAM_RAISED`, 3px black, radius 12 — `PASSIVE · NAME` Baloo 13 in `#B4600C` over Work Sans 13 `INK_ON_CREAM_SOFT`. Then `ALL SIX FACES · LIVE VALUES` Baloo 13 `INK_ON_CREAM_MUTED`. Then **six rows**, height 44, `CREAM_RAISED`, 3px black, radius 11: 32px part tile, value Baloo 24 in a fixed 30px column so the column aligns, **22px type swatch with its 14px icon** (G-01), caption ellipsised, and `ROLLED` in `#2E7D2B` on the currently-rolled face. Close button height 50, `PRIMARY`.<br>**Applies to** party and enemy inspection; an enemy has no faces, so the face list is absent, not empty-stated. **Visible** player. |

---

## 5 · RUN MAP

Content: left rail 344 fixed; the graph takes the rest. `max_w` — none; the graph region
stretches, the rail does not.

| ID | Item |
| --- | --- |
| **MAP-01** | **No Axie sprite on the map — G-03.** Delete the decorative back-view Axie and its contact shadow at the current node. Position is carried by MAP-08's ring and MAP-10's chip. **Applies to** the map only; party art still appears in the rail, in Result and in combat. **Check** no `assets/axie/back-*.png` reference in the map scene. **Visible** player. |
| **MAP-02** | **Rail.** Width 344, inset 28 from the left and from the top and bottom of the safe area. It is a column: run card at the top (hugging its content), a flexible spacer, then `SAVE & QUIT` pinned to the bottom. The spacer is what keeps the button at the bottom on a tall window — never a bottom offset. **Visible** player. |
| **MAP-03** | **Run card**: `PANEL_DEEP`, 4px black, radius 18, shelf 7, padding 19/19/17. Title `LUNACIA RUN` Baloo 28; a mode chip right (`PRIMARY`, 3px black, radius 8, height 27, Baloo 13 `INK_ON_PRIMARY`, e.g. `SHORT · A0`); seed caption Baloo 12 tracking .14em `CAPTION_MUTED`. **Visible** player. |
| **MAP-04** | **Run stats:** three equal cells, value Baloo 30, label Baloo 11 tracking .14em `CAPTION_MUTED` 6px below. Cells 2 and 3 carry a 2px left divider in `primary_divider_alpha()` and 14px left padding; cell 1 has neither. `SHARD`'s value inks `CREAM_HI`; the others `CREAM_RAISED`. **Visible** player. |
| **MAP-05** | **Party list:** one row per Axie — a 46px portrait tile (class colour fill, 3px black, radius 13, image cover), a flexible middle holding name Baloo 17 and `hp/max` Baloo 16 in `hp_color()` on one baseline, with a 9px HP bar (2px black, radius 5, `WELL_DEEP` trough) 5px under them, and a tier chip right (height 23, `PANEL_RAISED`, 2px black, radius 6, Baloo 12 `CHIP_INK_ON_WELL`). Row gap 10.<br>**Applies to** all five Axies, dead ones included — a dead Axie shows an empty bar, not a missing row. **Visible** player. |
| **MAP-06** | **Relic list:** `RELICS` eyebrow with the count right, then rows of a 34px tile (rarity colour, 3px black, radius 10, 20px icon), name Baloo 14, and a Work Sans 11 one-line description in `CAPTION_MUTED`. Section separated from the party by a 2px `primary_divider_alpha()` rule. **Visible** player. |
| **MAP-07** | **Header band**, right of the rail, top of the content: title `THE PATH` Baloo 44 with a `0 3px 0` black shadow at 60%; under it a Work Sans 13 line in `#EDF1F6` with a soft drop shadow — those two shadows are the sanctioned way to put type on open artwork, and are not L3 violations because they are type, not surfaces. Right-aligned in the same band: the boss card, height 66, `#C9302B`, 4px black, radius 16, shelf 6 — 44px `#F54540` icon tile, eyebrow Baloo 11 `#FFC3C0`, name Baloo 25. **Visible** player. |
| **MAP-08** | **Node token.** Size by state: current 122, open 106, fog 94, visited/skipped 80. Radius 24 current / 18 others; border 5 current / 4 others; shelf 8 / 6 / 4. Fill is **three flat blocks** from `DangoTheme.node_tone()`: base, a top block covering the upper 44%, a bottom lip covering the lower 19%. **Applies to** every node type including boss (boss reuses the battle tone and is told apart by size and by the header ribbon). **Visible** player. |
| **MAP-09** | **Node disc:** a centred circle, 74 / 64 / 56 / 48 px by the same state ladder, 3px black. Fill `CREAM_RAISED` normally, `CREAM_TRACK` visited, `PANEL` skipped, `WELL_DEEP` fogged. Icon 50 / 44 / 30 px at opacity 1, .5 visited, .32 skipped. A fogged node shows `?` in Baloo 32 `MUTED_TEXT` and **no icon** — the icon is not merely faded, it is absent, because a faded icon still spoils the node type. **Visible** player. |
| **MAP-10** | **Current-node ring and label.** Ring inset −11, 5px `PRIMARY` with a 3px black halo, blinking 1.8s. Blink animates opacity, so the ring must be **shown/hidden by visibility, not by a static opacity** — an opacity-0 ring still lights up on every node when the animation drives it. Label chip below the token, height 30, radius 9, 3px black, shelf 3: current = `PRIMARY` / `INK_ON_PRIMARY` / `YOU ARE HERE`; open = `CREAM_RAISED` / `INK` / the node type name. Fogged, visited and skipped nodes have no chip. **Visible** player. |
| **MAP-11** | **Visited badge:** a 30px `SUCCESS` circle, 3px black, shelf 3, overlapping the token's bottom-right corner by 7px, holding a ✓ in `INK_ON_SUCCESS`. **Applies to** every visited node. **Visible** player. |
| **MAP-12** | **Edges.** Drawn in two passes so the outline is continuous: first every edge at 14px pure black, then every edge at 6px in its own colour. Round caps. Colours: travelled `#4A525F` solid; available-from-here `CREAM_HI` solid; fogged and not-taken `#242A34` dashed 9/10. Edges are drawn **under** the tokens. **Visible** player. |
| **MAP-13** | **Graph placement.** Lanes and rows are normalised and fitted to the graph region: lanes at x = 0.0 / 0.5 / 1.0 of the region, rows evenly spaced bottom-to-top with the nearest row at the bottom. **Do not port the mockup's 780 / 1150 / 1520 or its row pixel values.** On a taller window the rows spread; the tokens do not move horizontally. **Visible** internal (it looks identical at 1080 — that is the point). |

---

## 6 · REWARD · SHOP · EVENT · TREASURE

These four are node screens. All four: `max_w` 1440 for the header block; the card rows are
centred and may exceed it as noted.

| ID | Item |
| --- | --- |
| **RWD-01** | Header, centred: a `SUCCESS` chip (height 38, 4px black, radius 10, shelf 5, Baloo 16 tracking .2em `INK_ON_SUCCESS`), then `CHOOSE ONE REWARD` Baloo 64, then a Work Sans 15 line in `#A6B0BF`. **Visible** player. |
| **RWD-02** | **Reward card:** 440 wide, `CREAM`, 5px black, radius 20, shelf 8; row gap 28. Header band height 46 filled with the **rarity** colour, 4px black bottom border, holding the kind left and the rarity right, both Baloo, both inked by `ink_on()`. Body padding 22: a centred 132px icon well (`CREAM_RAISED`, 4px black, radius 30) with a 78px icon bobbing inside; name Baloo 31 centred; description Work Sans 14 centred with a **fixed 84px minimum height so all three cards' buttons align**; then `TAKE`, height 60, `PRIMARY`, 4px black, shelf 4. Hover lifts the card 8px.<br>**Applies to** all three reward cards and to every rarity. **Visible** player. |
| **RWD-03** | Footer, centred, 13px gap: `REROLL REWARDS` (height 56, `PANEL_RAISED`, 4px black, shelf 5, icon + label + a `PRIMARY` count chip) and ~~`SKIP` (height 56, `PANEL`, muted label that inks up on hover)~~. **SKIP WITHDRAWN 2026-09-21 by the project owner: choosing a reward is mandatory, so the button is not built.** The build has no skip-a-reward path at all — `RunState.after_node()` is reached only through `_on_reward_chosen()` — and adding one would be a new engine rule the design does not want. REROLL alone is the footer. **Visible** player. |
| **SHP-01** | **Merchant side:** the merchant art sits bottom-left over the plate with a speech plate under it — 372 wide, `PANEL`, 4px black, radius 14, shelf 5, centred text, name eyebrow Baloo 14 `MUTED_TEXT` over a Work Sans 14 quote in `INFO_TEXT_ON_WELL`. **Visible** player. |
| **SHP-02** | **Catalogue panel:** 1100 wide, right-aligned in the content column, `PANEL`, 5px black, radius 20, shelf 7, clipped. Header band `PRIMARY` with a 4px black bottom border: title Baloo 38 `INK_ON_PRIMARY`, subtitle Work Sans 13 `#5A3310`, and a purse chip right (height 52, `CREAM`, 4px black, radius 12, 28px shard icon + Baloo 30 `INK`). **Visible** player. |
| **SHP-03** | **Shop row:** `CREAM`, 4px black, radius 14, shelf 4, padding 14/16, gap 16, rows 11 apart. A 62px rarity-coloured tile (3px black, radius 14, 36px icon); a flexible middle with name Baloo 22, a rarity chip, an optional `MP n` in Baloo 13 `#6B3FA0`, and a Work Sans 14 description; then a fixed 178×56 price button, 4px black, radius 13, shelf 4 — **`PRIMARY` with shard icon + price when buyable, `SUCCESS` with a ✓ and the word `OWNED` and no shard icon when owned, `DISABLED_FILL` with the price at full ink when unaffordable**.<br>**Applies to** every shop row and every one of the four states. Owned and unaffordable are different colours on purpose (see `DangoTheme.owned_button_style`). **Visible** player. |
| **SHP-04** | `LEAVE THE SHOP`: full panel width inside the padding, height 60, `PRIMARY`, 4px black, radius 14, shelf 5. **Visible** player. |
| **EVT-01** | Header, centred column: a 92px icon tile (`INFO`, 5px black, radius 24, shelf 6), title Baloo 58, Work Sans 16 line. **Visible** player. |
| **EVT-02** | **Option row:** 1040 wide, centred, `CREAM`, 5px black, radius 16, shelf 6, clipped, rows 14 apart. Structure left→right: a 74px accent rail in the option's tag colour with a 4px black right border and a 34px icon centred; a flexible body (padding 16/20) with the option text Baloo 24 plus a tag chip (height 24, 2px black, radius 7, `ink_on()`), and a Work Sans 15 consequence line; then a fixed 64px column holding `→` Baloo 30. Hover slides the row right 8px.<br>**Applies to** every event option on every event. The consequence line is never hidden behind a hover or a tooltip. **Visible** player. |
| **TRS-01** | Header: a `#FFC445` chip, then title Baloo 58. Body: the treasure art at 240px and a 470-wide card side by side, gap 44, centred as a pair. **Visible** player. |
| **TRS-02** | **Treasure card:** `CREAM`, 5px black, radius 20, shelf 7. Header band height 46 in the rarity colour with the kind and the rarity, inked by `ink_on()`. Body padding 22: a 78px icon well (`CREAM_RAISED`, 4px black, radius 18) beside name Baloo 28 and a Work Sans 13 sub-line; then the rule text Work Sans 15; then two buttons on one row — `TAKE IT` flexible, height 56, `PRIMARY`; `SMASH` fixed 196×56, `CREAM_RAISED`, 4px black, showing the shard icon, the amount Baloo 22 `INK` and the word in Baloo 13 `INK_ON_CREAM_MUTED`. **Visible** player. |

---

## 7 · RESULT

`max_w` 1760 for the stat ribbon and the panel row; the party row is centred and intrinsic.

| ID | Item |
| --- | --- |
| **RES-01** | **Portrait / nameplate overlap — G-02.** Portrait 152×152, radius 26, class-colour fill, 5px black, shelf 8, drawn **above** the plate. The nameplate is 168 wide, tucked **up by 8px only** (was 16), with **top padding 16** and bottom padding 11, radius 15, `PANEL_OVER_CLASS`, 3px black, shelf 5. The name's cap height must clear the portrait's bottom edge.<br>**Applies to all five Result nameplates.** **Check** the tallest glyph of the longest name (`Pomodoro`) is fully visible at 100% zoom. **Visible** player. |
| **RES-02** | **Nameplate contents:** name Baloo 22 `CREAM_RAISED`; 7px below, a centred row of tier Baloo 12 `CHIP_INK_ON_WELL` and `hp/max` Baloo 16 in `hp_color()`; 8px below that, a 138×9 HP bar, radius 5, 2px black, black trough. Column width 186, gap 28. **Visible** player. |
| **RES-03** | **Stat ribbon:** full content width, height 106, `PANEL_DEEP`, 4px black, radius 18, shelf 7, placed **28px below the party row**. Six equal cells, each padded 26 left, cells 2–6 carrying a 2px `primary_divider_alpha()` left divider. Value Baloo 38 (`DAMAGE DEALT` inks `DANGER`, `BIGGEST HIT` inks `PRIMARY`, `AXIES LOST` inks `SUCCESS`, the rest `CREAM_RAISED`); label Baloo 11 tracking .16em `CAPTION_MUTED` 7px below. **Applies to** all six stats. **Visible** player. |
| **RES-04** | **Panel row**, 28px below the ribbon, three panels on one row, gap 18, all radius 18 / 4px black / shelf 7: shard panel 560 fixed on `CREAM`; pass panel flexible on `PANEL_DEEP`; relics panel 392 fixed on `PANEL_DEEP`. All three are the same height — the row stretches, the panels do not float. **Visible** player. |
| **RES-05** | Shard panel: eyebrow Baloo 12 tracking .2em `#8A7450`; a 44px shard icon beside `+400` Baloo 58 `INK`; right-aligned, a Work Sans 13 breakdown with the daily portion in `#2E7D2B` and `POOL NOW n` Baloo 19. **Visible** player. |
| **RES-06** | Pass panel: eyebrow + a `SUCCESS` level-gain chip; `LV 7` Baloo 44 beside a Work Sans 13 XP line with the next reward in `CREAM_HI`; an 15px XP bar, radius 9, 3px black, `WELL_DEEP` trough, `PRIMARY` fill. **Visible** player. |
| **RES-07** | Relics panel: eyebrow `RELICS CARRIED · n`; chips wrapping, height 40, radius 11, 3px black, filled with the relic's **rarity** colour, 20px icon + name Baloo 14 inked by `ink_on()`. **Visible** player. |
| **RES-08** | Footer, centred, 16px gap, pinned above the safe area: `RUN IT AGAIN` 340×72 `PRIMARY` 5px black shelf 7 Baloo 25; `MAIN MENU` 250×72 `PANEL_ON_ART` 5px black shelf 7, label `MUTED_TEXT` inking up to `CREAM` on hover. **Visible** player. |

---

## 8 · META SCREENS

Six screens plus the Codex. All of them get `DangoScreen`'s shell, the 48/84 safe area and the
shared footer (`DangoTheme.build_footer`). **`BACK` never floats on the artwork — this applies
to all seven: Menu, Team Select, Pass, Unlocks, Vault, Guides, Codex.**

### 8.1 Main Menu — `max_w` none (a two-column screen, 84px gutters)

| ID | Item |
| --- | --- |
| **MNU-01** | The **only horizontal scrim in the game** (`DangoTheme.Scrim.MENU`): ink under the left column, art open on the right. **Visible** player. |
| **MNU-02** | Left column 640 wide: eyebrow chip (`PRIMARY`, 4px black, shelf 5, Baloo 15 tracking .24em); title Baloo **104**, two lines, leading 0.9 via `leading_for()`, `CREAM_RAISED`, `0 6px 0` black shadow at 45%; blurb Work Sans 16 `INFO_TEXT_ON_WELL` capped at 530 wide; a shard chip (height 52, `CREAM`, 4px black, shelf 5). **Visible** player. |
| **MNU-03** | `BEGIN RUN`: 530 wide, height 86, `PRIMARY`, 5px black, radius 16, shelf 7 — label Baloo 30 `INK_ON_PRIMARY` over a Work Sans 13 run-summary line in `#5A3310`, with `→` Baloo 34 right. Press drops the shelf to 3 and translates 4. `CONTINUE RUN` below it, height 68, `PANEL`, 4px black, shelf 5, title Baloo 20 `CREAM_HI`, sub-line `MUTED_TEXT`, `↺` right. Continue is **hidden**, not disabled, when there is no save. **Visible** player. |
| **MNU-04** | Run setup panel, right column, 566 wide, `PANEL`, 5px black, radius 18, shelf 7, clipped. Header sub-band on `PANEL_RAISED` with a 4px black bottom border: title Baloo 28, Work Sans 13 sub-line. Body padding 18/22/22, three groups 20 apart, each led by a Baloo 13 tracking .16em `MUTED_TEXT` eyebrow. **Visible** player. |
| **MNU-05** | Seed group: a flexible 50px `WELL` field (3px black, radius 11, Baloo 24 `CREAM`) beside a fixed 136×50 `RANDOM` button (`PANEL_RAISED`, hover `PRIMARY`). Run-length group: two equal tiles — selected on `PRIMARY` with `INK_ON_PRIMARY`, locked on `WELL` with `FAINT_TEXT` and a lock glyph, each carrying a Work Sans 12 detail line. Ascension group: a −/value/+ stepper (50px square buttons, the + on `PRIMARY`), then four equal stat tiles on `WELL` (3px black, radius 10) with a Baloo 11 key and a Baloo 19 value. **Applies to** every ascension level, not just A0. **Visible** player. |
| **MNU-06** | Nav tiles: bottom-right, 452 wide, a 3×2 grid, gap 9. Each 66 tall, `PANEL_ON_ART`, 3px black, radius 12, shelf 4, label Baloo 12 `INFO_TEXT_ON_WELL` top and a Baloo 17 value bottom. **Applies to** all six destinations (Pass, Unlocks, Vault, Guides, Codex, Settings). **Visible** player. |
| **MNU-07** | Team strip: bottom-left, `YOUR TEAM` eyebrow beside an `EDIT TEAM →` chip; five cards 220 wide, gap 13, `CREAM`, 4px black, radius 15, shelf 6 — a 34px class-colour header with name and class both Baloo and `INK`, then a 124px portrait, then a row of `TIER n` Baloo 13 `INK_ON_CREAM_MUTED` and `n HP` Baloo 19 `INK`. Hover lifts 6px. **Applies to** all five slots. **Visible** player. |

### 8.2 Team Select — `max_w` 1808

| ID | Item |
| --- | --- |
| **TEAM-01** | Header row: title Baloo 46 + Work Sans 14 rule line left; right, `SAMPLE TEAMS` (height 54, `PANEL`, muted) and `CONFIRM TEAM` (height 54, `PRIMARY`, Baloo 20). **Visible** player. |
| **TEAM-02** | Five equal slot cards, gap 14, `CREAM`, 5px black, radius 17, shelf 7, clipped. Header 40 tall in the class colour with name Baloo 21 and class Baloo 14, both `INK`. **Applies to** all five. **Visible** player. |
| **TEAM-03** | Card body padding 12/13/14: a picker row (height 36, `CREAM_RAISED`, 3px black, radius 10, Baloo 14 `INK` + `▾`); a 186-tall portrait well filled with the **class colour** (3px black, radius 14) holding a 164px portrait, with a `TIER n` chip bottom-left on 36% black and an `n HP` chip bottom-right on `CREAM_RAISED`; then the passive block (`PRIMARY`, 3px black, radius 11, `PASSIVE · NAME` Baloo 13 `INK_ON_PRIMARY` over Work Sans 12 `#3A1E07`); then the six faces. **Visible** player. |
| **TEAM-04** | **Face cell — G-01 applies here.** 2×3 grid, gap 8. Cell: `CREAM_RAISED`, 3px black, radius 10, padding 8/9. Top row: 22px part icon, value Baloo 24 `INK`, and a **22×22 type swatch, radius 6, 3px black, filled with the type colour and containing that type's 14px icon** from `assets/fx/`. Under it: caption Baloo 10 `INK_ON_CREAM_MUTED`; under that, the keyword line Baloo 10 `#B4600C` with a 12px minimum height so the six cells stay on a grid.<br>**Applies to every face cell of every Axie on this screen — all thirty — and to the Vault's variant (VLT-05).** The swatch is never a bare colour block. **Check** a mana face shows the mana glyph, a shield face the shield glyph, and so on for all seven types. **Visible** player. |
| **TEAM-05** | Archetype bar pinned above the footer: `PANEL`, 4px black, radius 15, shelf 5, padding 14/18 — an eyebrow then one chip per lean (fill = the archetype colour, 3px black, radius 12, glyph + Baloo 15 name + Work Sans 12 line, all `INK`). **Visible** player. |

### 8.3 Lunacia Pass — `max_w` 1752

| ID | Item |
| --- | --- |
| **PASS-01** | Header: eyebrow chip + title Baloo 56 left; right, a 540-wide level panel (`PANEL`, 4px black, radius 14, shelf 5) with `LEVEL 7` Baloo 38 (` / 30` Baloo 22 `FAINT_TEXT`), a Work Sans 14 XP line, and an 18px bar (radius 10, 3px black, `WELL_DEEP` trough, `PRIMARY` fill). **Visible** player. |
| **PASS-02** | Track panel below the header: `PANEL`, 5px black, radius 18, shelf 7, padding 20; a **6-column grid**, gap 12, one tile per level. Tile height 72, radius 12, 3px black, padding 10/12 — a 38px level badge (radius 10, 3px black), the reward name Baloo 14 ellipsised, and the state line Baloo 12. **Visible** player. |
| **PASS-03** | **Tile states — L8.** `CLAIM NOW` is the **only** loud tile: `SUCCESS` fill, `INK_ON_SUCCESS` ink, badge on `CREAM_RAISED`. `CLAIMED`: `CREAM_TRACK` fill, `INK` name, `INK_ON_CREAM_MUTED` state. `NEEDS LV n`: `WELL` fill, `FAINT_TEXT` throughout, badge on `PANEL_RAISED`.<br>**Applies to all thirty tiles.** A fully-claimed pass is mostly calm cream; a maxed-XP-zero-claims save is mostly green, and that is correct rather than a bug — check against a save with a mixture before judging. **Visible** player. |

### 8.4 Unlocks — `max_w` 1200 (explicitly narrower than the screen; extra width is margin)

| ID | Item |
| --- | --- |
| **UNL-01** | Header: eyebrow chip + title Baloo 56 left; a purse chip right (height 56, `CREAM`, 4px black, radius 13, shelf 5, 30px icon + Baloo 34 `INK`). **Visible** player. |
| **UNL-02** | Rows: height 74, radius 13, 4px black, shelf 4, padding 0/16, gap 10, in a 1200-wide centred column. A 38px step badge; a flexible middle with name Baloo 20, a state tag chip (height 22, 2px black, radius 6, Baloo 12 inked by `ink_on()`) and a Work Sans 13 description; then a fixed 176×46 button, 3px black, radius 12.<br>Row fills by state, per L8: buyable `CREAM`; owned `CREAM_TRACK`; unaffordable `DISABLED_FILL` with the price at **full** ink; locked `WELL` with `FAINT_TEXT`. The button shows the shard icon + price when buyable and hides the icon otherwise.<br>**Applies to** every unlock row and all four states. **Visible** player. |

### 8.5 Vault — `max_w` none (a two-column screen, 64px gutters)

| ID | Item |
| --- | --- |
| **VLT-01** | Header: an `INFO` eyebrow chip inked `INK_ON_SHIELD`, title Baloo 56, a Work Sans 14 blurb capped at 900; right, an imported counter on `INFO` (height 56, 4px black, radius 13, shelf 5, Baloo 34 + Baloo 13, both `INK_ON_SHIELD`). **Visible** player. |
| **VLT-02** | Left panel 520 wide: `PANEL`, 4px black, radius 16, shelf 5, padding 18/20. `IMPORT BY AXIE ID` eyebrow; a 50px `WELL` input (3px black, radius 11, placeholder Work Sans 15 `FAINT_TEXT`) beside a fixed 112×50 `SCAN` button. **Visible** player. |
| **VLT-03** | The not-built notice: `DANGER` fill, 3px black, radius 11, padding 11/13 — a 20px icon beside Work Sans 13 in `INK_ON_DANGER`. It is a **solid red plate with black ink**, not red text on the panel. Below a 3px black rule, the `RANKED RUN` note on `WELL`, 3px black, radius 11, Work Sans 13 in `INFO_TEXT_ON_WELL`. **Visible** player. |
| **VLT-04** | Vault cards, right column, equal widths, gap 16: `CREAM`, 5px black, radius 17, shelf 7, clipped. Header height 44 in the class colour holding **a 28px round portrait tile (`CREAM_RAISED`, 3px black, 26px image, `object-position` top) then the name Baloo 20 ellipsised**, with a flag chip right (2px black, radius 7, Baloo 12, `ink_on()`). The portrait in the header is required — it matches the die-card header pattern (CB-22). **Applies to** every vault card. **Visible** player. |
| **VLT-05** | Card body padding 14/16/16: a Work Sans 12 meta line (`Axie #id · CLASS · n HP`) in `INK_ON_CREAM_MUTED`; a 224-tall model well (`CREAM_RAISED`, 3px black, radius 14, clipped) with a Baloo 11 `AxieCharacter3D · FROM GENES` caption top-left and the model bottom-centred at 190px; then `DIE FROM ITS SIX REAL PARTS` and a **3-column** face grid using TEAM-04's cell (21px swatch, 13px icon, **no keyword line**); then `USE IN TEAM` (flexible, height 50, `PRIMARY`) and `REMOVE` (fixed 124×50, `DANGER`, `INK_ON_DANGER`). **Visible** player. |

### 8.6 Guides — `max_w` 1816

| ID | Item |
| --- | --- |
| **GDE-01** | Four equal cards, gap 14, `CREAM`, 5px black, radius 17, shelf 7, clipped, **equal height with the CTA bottom-aligned across all four** — the body is a column with the bullet list flexible, so the buttons line up regardless of copy length. **Applies to** all four compositions. **Visible** player. |
| **GDE-02** | Header band in the archetype colour, 4px black bottom border, padding 12/15: a 42px glyph tile (`CREAM_RAISED`, 3px black, radius 11), name Baloo 22 and archetype Baloo 12, both `INK`. **Visible** player. |
| **GDE-03** | Body: difficulty Baloo 12 `INK_ON_CREAM_MUTED`; a five-up team strip of square tiles (aspect 1, radius 10, 3px black, class-colour fill, portrait cover, gap 6); a Work Sans 13 "why" paragraph in `INK_ON_CREAM_SOFT`; then the "how" bullets — a 7px square bullet in the archetype colour with a 2px black border, 8px from a Work Sans 12 line in `INK_ON_CREAM_SOFT`; then `USE THIS TEAM`, height 50, `PRIMARY`, 3px black, shelf 4. **Visible** player. |

### 8.7 Codex — `max_w` none (rail + panel, 64px gutters)

| ID | Item |
| --- | --- |
| **CDX-01** | Left rail 294 wide, from under the header to the footer. Tabs: height 50, radius 11, 3px black, padding 0/15, gap 7 — label Baloo 15 ellipsised, plus a state tag chip right (height 18, 2px black, radius 5, 10px). Selected tab = `PRIMARY` / `INK_ON_PRIMARY`; unselected = `PANEL` / `MUTED_TEXT`.<br>**Applies to all ten Codex tabs.** Every tab is reachable and shows something; a tab with no content yet shows the placeholder body of CDX-04, never a blank panel. **Visible** player. |
| **CDX-02** | Content panel fills the rest: `CREAM`, 5px black, radius 18, shelf 7, clipped, a column. Header band on `CREAM_RAISED`, 4px black bottom border, padding 15/24 — title Baloo 32 `INK`, lede Work Sans 14 `INK_ON_CREAM_MUTED` capped at 900; right, a state chip (3px black, radius 7, Baloo 12) over a mono 11 binding line in `#8A7450`. **Visible** player. |
| **CDX-03** | Body scrolls, padding 18/22, and **is the only scrolling region on the screen** — the rail and the header do not move. Give it a visible bar (`DangoTheme.style_scrollbars`, 10px) and the 24px bottom fade. **Visible** player. |
| **CDX-04** | **Six body layouts**, chosen per tab: `status` (3-col icon+text cards), `grid` (3-col slot cards), `steps` (numbered rows with an art slot right), `split` (a 330-wide diagram panel left, rows right), `cards` (3-col cards with a 9px colour cap), `table` (a 2fr/1fr/1fr/3fr grid with a `#E2D2B6` head row and 52px rows).<br>Where content does not exist yet, the layout renders **labelled placeholders**: `#EADDC7` blocks, `#E2D2B6` for a title line, and a 3px dashed `#B39A72` box reading `ICON` / `ART` / the diagram name. These placeholders are a deliberate part of the spec — they say "this tab is built, its data is not", which a blank panel does not. **Applies to** all ten tabs. **Visible** player. |

---

## 9 · Order of work

Each block is a shippable slice. Do not start a block before the one above it is green.

1. **G-01 → G-04** (§2). Four small changes, all `player`-visible, all cheap. Doing them first
   means the next review looks at a screen that already moved.
2. **Combat** CB-09 … CB-13 (nameplate system) — the largest single correctness gap, and the
   one that has failed twice. Note CB-09's "applies to" before you start.
3. **Combat** CB-18 … CB-28 (the deck).
4. **Run Map** MAP-08 … MAP-13.
5. **Result** RES-01 … RES-04.
6. **Meta** in this order: Team Select → Vault → Pass → Unlocks → Menu → Guides → Codex.
7. **MAP-13** and any other `internal` item, last. They will not look like anything.

---

## 10 · Items from earlier passes that are closed here

So nothing sits in limbo the way ~20 items did after pass 02:

- **`196×64` nameplate** — superseded by **CB-09** (176×64 / 176×68). Do not implement both.
- **`aspect="keep"`** — never. `expand` stays. There is no second opinion in this file.
- **Shipped `.gd` files from pass 02** (`DangoScreen.gd`, `t_ui_laws.gd`, the patched
  `CLAUDE.md`) — this pass ships **no code**. `DangoScreen`'s shell idea stands and is already
  in the build; the test file is withdrawn, and I am not shipping a replacement. If you want a
  law test, write it against this file's IDs, free every node it creates, and wrap anything
  touching `MetaState` in `SaveGuard`.
- **Enemy-only fixes** — every item in this file states its set. Where it says *every*, it
  means every.

---

## 11 · What I could not determine

Flagged rather than guessed, per the handoff rules.

1. **Which items already hold.** I am writing from the design files, not from your build. Run
   the CHECK before the change on anything that looks already-done.
2. **Combat models vs sprites.** The design shows unit art as flat images; the repo has
   `CombatStage3D`. Everything in §4 specifies the **HUD column** — badge, status strip,
   nameplate — and the stack's order and geometry hold whether the thing below them is a
   sprite or a rendered model. If the 3D stage positions units independently of the HUD
   column, tell me and I will respec the anchor relationship.
3. **Enemy shield as a first-class stat.** CB-10 gives enemies their own shield bar. If the
   rules model does not track enemy shield separately from HP, that bar has nothing to read
   and the item should be deferred, not faked.
4. **Graph data.** MAP-13 assumes the generator can hand the view normalised lane/row positions
   (or lane index + row index). If it only emits pixel coordinates, that is a generator change
   and it is not free — flag it rather than hard-coding the mockup's numbers.
5. **Codex content.** CDX-01 says all ten tabs are reachable; I do not know how many have real
   data. The placeholder path (CDX-04) exists precisely so this is not a blocker.
6. **Asset coverage.** §4 and §8 reference `assets/fx/` glyphs for all seven face types
   (dmg, shield, heal, mana, poison, buff, debuff). If any is missing in the Godot import set,
   say which — do not substitute a colour block, which is the thing G-01 removes.
7. **States I cannot see.** The dev save owns every unlock, so `unaffordable` on Unlocks and
   Shop may have no capturable state on your machine. Those items are specified from the
   token system, not from a capture.
