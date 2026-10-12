# UI request 01 — Ascension v2 · delivery

**Normative document for this request.** If a mockup frame and this file disagree, this file wins and the frame is a bug. Nothing here supersedes any item in FIX-PASS-01/02/03; it only adds to the three v2 mockups.

Canvas 1920×1080, every number below is in canvas px. All fonts and colours are the ones already in the v2 mockups (Baloo 2 numerals/labels, Work Sans prose at 600, pure-black outlines, hard shelf shadows).

## Files

| File | Extends | Holds |
|---|---|---|
| `Ascension Meta v2.dc.html` | `meta-screens-v2.html` | 3.1-a … 3.1-e |
| `Ascension Combat v2.dc.html` | `combat-v2.html` | 3.2-a/b, 3.3 (all states), 3.5-b |
| `Ascension Run Flow v2.dc.html` | `run-flow-v2.html` | 3.2-c, 3.4-a…d, 3.5-a, 3.6-a…c, 3.7-a/b, 3.8-a…d |
| `Ascension v2 contact sheet.png` | — | All states at 0.45 scale (some tiles near a page bottom are cropped; the HTML is the reference) |
| `asc/new-icons/*.svg` + `.png` | — | NEW icons, 128 px, transparent |

Every frame names its own data state under the title. Party Axies and monsters are left as dashed frames labelled **AXIE 3D** / **ATIA MONSTER 3D** at the combat-v2 box sizes.

## Shared element: the rule list

Used by 3.1 (Run Setup) and 3.2 (badge popover). One row per active rule A1…An, cumulative.

- Row: height 26, radius 7, padding 0 6, gap 8, rows gap 2. Icon 18 · code w26 Baloo 13/800 `#FFC79B` · name w98 Baloo 12/800 `#FFF8EA` nowrap · line Work Sans 12/600 `#C7CED9` (one line, max ~50 chars).
- Container: `#10131A`, border 3 #000, radius 12, padding 6 (Run Setup) / 8 (popover, on `#1B1F27`).
- **Overrides are rewritten, never hidden:** at A9+ the A4 row reads "Enrage from turn 8 (A9)…"; at A10 the A6 row is greyed (`#5C6573`, icon opacity .4) and reads "Replaced by A10 — every boss requires a pact".
- Row copy (A1→A10): see `RULES` in any of the three files; identical in all three.
- Icons: A1 `shop` · A2 `elite` · A3 `reroll` · A4 NEW `boss-clock` · A5 NEW `eternal` · A6 NEW `pact` · A7 `chest` · A8 NEW `lock` · A9 `elite` · A10 NEW `pact`.

Ascension badge colour everywhere: fill `#C9302B` (the boss plate red already in run-flow-v2), ink `#FFF8EA`, caret `#FFC3C0`.

## 3.1 Ascension panel in Run Setup

Replaces the −/A0/+ stepper and the four `ascStats` tiles in RUN SETUP (Main Menu, `top:78 right:84 width:566`). SEED and RUN LENGTH unchanged.

- **Label row** (h 26): "ASCENSION" left as today; right: "LADDER" 11/800 `#6F7887` + two goal chips "A5 TITLE", "A10 TITLE" (h 26, radius 7, border 2, padding 0 9 0 6). Earned `#3FCD3C`/`#07260A` + white ✓ dot 14; not yet `#10131A`/`#8C95A4`, empty dot.
- **Picker:** 11 chips A0–A10, 42×44, radius 10, border 3, gap 6 (row 522). Selected `#FF9345`/`#2A1505` + shelf `0 4px 0 rgba(0,0,0,.45)`. Unlocked `#262C36`/`#F3E7D3`. Locked `#10131A`/`#4A525F` + `lock.svg` 16 at top −6 right −6. Baloo 16/800.
- **Title:** margin-top 13, "A6 · FIRST PACT" Baloo 24/800; right "6 RULES ACTIVE" 12/800 `#8C95A4`. Below (mt 5) one line "ENEMY HP ×1.21 · ENEMY DMG ×1.10 · BOSS HP ×1.15", 12/800 `#A6B0BF`. Multipliers are cumulative products: HP ×1.1 at A1, A6, A10; DMG ×1.1 at A3, A8, A10; boss HP ×1.15 from A4.
- **List:** margin-top 9. The selected level's row is filled `#FF9345`, ink `#2A1505`/`#3A1E07`, with a "NEW" tag (h 18, `#2A1505`/`#FFC79B`, 11/800).
- Panel grows to ≈744 tall at A10 (bottom ≈822). Nav tiles start at 893. **Nothing scrolls.**

States: **3.1-b A0** — list box holds one sentence: "No ascension rules at A0. Standard enemies, standard prices, 3 reward cards, 8 relic slots. Win a run at A0 to unlock A1." **3.1-c A6** — as above. **3.1-d A10** — 10 rows, both titles earned. **3.1-e locked** — locked chips are visible but not selectable; hover or keyboard focus draws a 3 px dashed `#FFC79B` outline (offset 2) and previews that level's rules at opacity .55 (no NEW tag) under a 32 px strip `#262C36`: "LOCKED · WIN A RUN AT A{best} TO UNLOCK A{best+1}". Selection and BEGIN RUN subtitle stay on the last unlocked pick.

## 3.2 Ascension indicator during a run

- **Combat top bar:** chip after the wave track (gap 11). h 33, padding 0 8 0 10, radius 9, border 3, Baloo 18/800 "A6" + "▾" 12/800.
- **Run Map rail:** the existing "SHORT · A0" chip splits: "SHORT" stays in the title row (h 27, `#FF9345`), the level becomes a 27-tall badge right-aligned on the SEED row (Baloo 14/800).
- Hover/focus/open: 3 px `#FFC79B` outline, offset 2. Click or Enter opens; Esc / click outside closes.
- **Popover:** 560 wide, top 72 (8 below the top bar), left aligned to the badge. Header `#C9302B` padding 13 16 12: "ASCENSION 10 · LAST STAND" 22/800 + "LOCKED FOR THIS RUN" 11/800 `#FFC3C0` + the multipliers line. Then the rule list (no NEW highlight), footer `#161A21` 12/600.
- **A0: hidden.** No rules exist, and a neutral "A0" chip would read as a rule set. The level is still stated once per run by the rail's existing "SHORT · A0" chip and the Result banner "ASCENSION 0".

## 3.3 Boss Clock (A4–A10)

Attaches to the enemy nameplate (combat-v2: 176×64, radius 12, border 3).

- **Tab:** absolute, `left:0 right:0 top:61` (overlaps the plate's bottom border), h 29, padding 3 7 0 7, radius 0 0 10 10, border 3 #000 with no top border, shelf `0 4px 0 rgba(0,0,0,.5)`. Content: `boss-clock.svg` 16 · label Baloo 13/800 tracking .02em nowrap · pips.
- It lives in the top 29 px of the 228 px monster frame, so the 28 px status strip and the intent badge do not move.
- **States** (turn = turn of the fight from 1; start = 10 at A4–A8, 8 at A9–A10):
  - `turn < start − 1`: fill `#262C36`, ink `#FFC79B`, "ENRAGE IN {start − turn}", no pips. Works for 1–20 (two digits fit).
  - `turn = start − 1`: fill `#FFC445`, ink `#3A2A12`, "ENRAGE NEXT TURN", no pips.
  - stacks s = min(5, turn − start + 1): label "ENRAGE +{20·s}%" with 5 pips (8×12, radius 3, border 2; filled `#1A1206`). Fills by stack: 1 `#FFB23F` · 2 `#FF9345` · 3 `#F56A40` · 4 `#F54540` · 5 `#C9302B` with ink `#FFF8EA`, label "MAX +100%", pips `#FFF8EA`.
- **Intent value shows the bonus:** the number in the intent badge is the final damage (base × (1 + 0.2·s)). Right after the number, a chip h 20, radius 6, `#1A1206`, `boss-clock.svg` 13 + "+40%" Baloo 11/800 `#FFC79B`. No chip before enrage. The 3.3-a frame shows base 10 → 16 at +60%.
- **Animation (default):** when a stack is added, one 300 ms pop of the tab (scale 1 → 1.06 → 1) with a 4 px `#FFF1A8` ring at the peak (drawn in the specimen row). No loops.
- **Reduce flashing:** no pop, no ring, no colour cycling. Escalation is carried by fill, pip count and the number only (second specimen row).
- Phase 2 bosses: the clock does not reset (ascension-v2 §2.4); the tab stays.
- Run Map: a 30 px tab under the boss plate (top-right) states the clock before the fight: "ENRAGES FROM TURN 8 · PACT REQUIRED" (text follows level).

## 3.4 Eternal sticker (A5+)

- **Reward card (3.4-a):** card header kind reads "RELIC · ELITE". Sticker: h 36, radius 10, border 3, `#FFC445`, `eternal.svg` 24 + "ETERNAL" Baloo 15/800 `#3A2A12`, rotated −8°, at the icon tile's top-right (left 262, top −4 in the 396 body). Above TAKE: strip min-h 42, `#FFE7A8`, border 3, radius 11: "Eternal: cannot be sold. Taking this uses Eternal 2 of 2." (count is live).
- **Limit reached (3.4-b):** same sticker, `#E2D5BC`, dashed border, icon .35, text struck through; strip `#E2D5BC`: "Eternal limit reached (2 / 2). This relic gets no sticker and can be sold normally."
- **Relic chips (3.4-c):** `eternal.svg` 15–17 px at bottom-right −6/−7 on every relic chip: combat top bar (33 chip), map rail slots (32) and relic list (34, plus an "ETERNAL" tag h 17 `#FFC445`), pact slot strip (26), shop sell row and sell box (34).
- **Sell flow (3.4-d):** Eternal rows dim (`#161A21`, name `#8C95A4`) and the sell button becomes `#10131A` + `lock.svg` 15 + "ETERNAL — CANNOT BE SOLD" Baloo 12/800 `#FFC79B`, not focusable.

## 3.5 Weaken pre-warning (A5+)

- **Run Map, node selected (3.5-a):** first click selects (white 5 px ring, node 112), second click or FIGHT goes. A 30 px `#FF8FC7` weaken badge sits on the node's top-right. Preview card 300 wide at the node's left (left 410, top 384 for the row-5 left node), elite-purple header 40: lines for escort (A2), Eternal reward (A5), then a `#FFF8EA` box with portrait 34 + "BUBA STARTS WEAKENED" + existing weaken chip, then FIGHT button 44.
- **Fight intro (3.5-b):** the existing turn-banner block (padding 18 64, radius 20, border 5) in the node colour, with a cream strip under it (border 4, no top, radius 0 0 16 16): portrait 40 + "BUBA STARTS WEAKENED" 20/800 + "Weaken 2 from turn 1 · Ascension 5" + the weaken chip. Hold until first input or 2.4 s, whichever is later than the normal banner time.
- **In the fight:** the Axie's nameplate status strip shows the existing weaken chip (`#FF8FC7`, `weaken.png`) from turn 1. No new element.

## 3.6 Pact screen (designed here; relic-set-v2 §2.5, §4.4)

- Header block top 62: "BOSS DEFEATED · {boss}" tag + level badge (A6/A10 only), "CHOOSE A PACT" 64/800, one-line explainer, then a 44 px slot strip (8 × 26 slots).
- **Cards:** 3 × 440, gap 28, top 322. Header 46 in rarity colour: "PACT · {REROLL|DICE|MANA}" + rarity. Icon tile 88 with `pact.svg` 30 at bottom-right; name Baloo 29; chips "1 PASSIVE SLOT" and, if any, "MULT SLOT G/A". GAIN box `#FFF8EA` (label `#2E7D2B`). **COST box `#FF8FC7`**, border 3, `drawback.svg` 16 + "COST · {GROUP} · ALL RUN". Both min-h 72. TAKE PACT 60.
- **3.6-a normal (A0–A5):** "SKIP ALL THREE" (h 56) at bottom 74 + "Skipping keeps your passive slots free."
- **3.6-b forced (A6 first boss) / A10 every boss:** skip removed. In its place a plate h 66, `#C9302B`, border 4: `pact.svg` 38 + "ASCENSION 6 — A PACT IS REQUIRED" / "First boss of the run. Pick one of the three to continue." (A10: "ASCENSION 10 — EVERY BOSS REQUIRES A PACT").
- **3.6-c forced + slots full:** TAKE PACT opens "MAKE ROOM FOR {PACT}" (640 wide, modal over a .84 scrim) with **no cancel**: one row per held relic with its sell value; Eternal rows disabled (3.4-d); footer line names the locked 8th slot (A8) and the refund rate.

## 3.7 Shop and sell modifiers (A1+)

- **Chosen treatment: struck-through base + final price, on every price.** Inside the 178×56 BUY button: base Baloo 15/800 `#8A4A15` line-through 2 px · shard 20 · final 24/800 · "BUY". One header chip next to the merchant title explains it once: "A1 · PRICES +15% · SELL 40%" (h 28, `#C9302B`).
- Prices: `round_half_up(base × 1.15)` — C 45→52 · R 75→86 · E 120→138 · L 180→207 (ascension-v2 §2.2).
- **Sell row** (new, inside the shop panel above LEAVE): "SELL A RELIC" + "REFUND 40% OF BASE PRICE (A1) · ROUNDED DOWN"; one 52 px tile per relic with "SELL {n}". A0: 50% (C 22 · R 37 · E 60 · L 90, rounded down — see unknowns). A1+: 40% (18 · 30 · 48 · 72). 3.7-b shows all eight.

## 3.8 Reward variants and slot cap

- **A7+ (3.8-a):** two 440 cards, gap 28, centred (row 908, left 506). No empty slot. With `scavengereye` the existing 3-card layout returns. A tag next to the subtitle states it: "A7 · 2 CARDS".
- **A10 (3.8-b):** REROLL REWARDS is removed; SKIP stays centred alone. Tag "A10 · 2 CARDS · NO REROLL".
- **Greyed reroll (3.8-c):** only when the player holds a source that would normally grant a reward reroll: `#1B1F27`, text `#5C6573` struck, count "×0", no shelf, not focusable; a 28 px `#C9302B` reason line below: "ASCENSION 10 · REWARD REROLLS ARE OFF".
- **Slot cap (3.8-d), A8+:** wherever passive slots are listed (map rail, pact header, sell box), 8 squares are drawn; the 8th is `#0B0D12`, dashed `#4A525F` border, `lock.svg`, tooltip "Locked by A8 Cramped Pack"; count reads "5 / 7 PASSIVE". Rail caption under the strip: "Slot 8 locked · A8 Cramped Pack".

## Acceptance check

| Rule | Seen before it bites |
|---|---|
| A1 | Run Setup list; shop header chip + struck prices; sell row rate |
| A2 | Run Setup; map node preview "2 + 1 escort" |
| A3 | Run Setup; combat reroll count shows the real number |
| A4 / A9 clock | Run Setup; map boss tab "ENRAGES FROM TURN 8"; nameplate "ENRAGE IN n" from turn 1 |
| A5 | Run Setup; map preview "relic reward will be Eternal"; sticker on the card before TAKE; weaken on map + intro |
| A6 / A10 pact | Run Setup; map boss tab "PACT REQUIRED"; pact screen plate |
| A7 | Run Setup; reward tag |
| A8 | Run Setup; locked 8th slot everywhere slots are drawn |
| A9 elites | Run Setup; elites are on the map before the player paths |
| A10 reroll | Run Setup; button absent / greyed with reason |

Enemy intent is never covered except by the player-opened badge popover; the boss intent includes the enrage bonus.

## NEW icons (`asc/new-icons/`, 128 px, black outline, flat fill, transparent)

| File | Use |
|---|---|
| `boss-clock.svg/png` | Boss Clock tab, intent chip, A4 rule row, map boss tab |
| `eternal.svg/png` | Eternal sticker, chip corners, A5 rule row |
| `pact.svg/png` | Pact card corner, forced-pact plate, A6/A10 rows |
| `drawback.svg/png` | Pact COST box label |
| `lock.svg/png` | Locked ascension chips, locked 8th slot, disabled Eternal sell, A8 row. Replaces the 🔒 emoji in meta-screens-v2's FULL tile |

All other art is existing: `icons/web/*`, `icons/node/*`, `portraits/*`, `backgrounds/origins/scene/*`.

## OBSERVED vs INFERRED

- OBSERVED (read in mockup source): nameplate 176×64, status strip 28 fixed, intent badge 36, top bar 60, reroll button 272×56, reward cards 440/gap 28, shop button 178×56, RUN SETUP 566 at top 78 right 84, nav tiles top 893.
- INFERRED: run-flow-v2 has no sell UI and no pact screen, so both are new here. The shop background `shop.jpg` has no match under `backgrounds/origins/scene/`; frames use `6-river.jpg` as a stand-in.
- INFERRED: shop items use relic-set-v2 rarities (C/R/E/L); the v2 mockup's "Uncommon" Bloomscale is shown as Rare.

## Unknowns (need Liam or code)

1. **Ladder title names** for A5 and A10 — frames say "A5 TITLE" / "A10 TITLE".
2. **Weaken value and target rule** at fight start (`combat_engine.gd` ~155). Frames use Weaken 2 on Buba.
3. **Rounding of enraged intent** — the badge must show what `damage_pipeline.gd` will deal; frames use round-half-up.
4. **A0 sell rounding** at 50% (Rare 37.5 → 37 assumed, floor like A1).
5. **Greyed reroll state (3.8-c)** has no trigger today: `fortuneledger` is not offered at A10. Keep or drop once the meta `reward_reroll_max` behaviour at A10 is confirmed.
6. Pact group of `brittledice` (shown as DICE) — taken from its drawback, not from the §4.4 group table, which was not fully listed.

## Visible to the player?

All eight items are visible. Order for implementation, most-seen first: 3.3 Boss Clock + intent chip → 3.2 badge → 3.1 Run Setup → 3.7 prices → 3.8 reward re-flow + slot lock → 3.5 weaken → 3.4 Eternal → 3.6 pact (depends on the relic-UI request).
