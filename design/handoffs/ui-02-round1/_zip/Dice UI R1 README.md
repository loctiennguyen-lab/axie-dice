# UI request 02 — Round 1 · delivery

**Normative document for Round 1.** If a mockup frame and this file disagree, this file wins and the frame is a bug. Replaces the look of request 01 / v2 mockups; Ascension items (§7) come in Round 2.

All numbers are canvas px at 1920 × 1080. "Taller window" = 1920 × 1240 (game uses *expand*; extra height is added, never scaled).

Tags: **[OBS]** observed from attached files (renders, brief, Cosmetics 01). **[INF]** inferred by us — confirm or change.

## Files

| File | Holds |
|---|---|
| `Dice UI R1 - Style Sheet.dc.html` | 00 · palette, type, outlines/shadow, buttons, panels/chips/bars/badges, icons, motion + reduce-flashing |
| `Dice UI R1 - Land Hub.dc.html` | 01a Savannah day 1 · 01b unfinished run · 01c Moon Card popup · 01d Arctic at 1920×1240 |
| `Dice UI R1 - Combat.dc.html` | 02a–02l combat states · 03a–03c defeat |
| `Dice UI R1 contact sheet.png` | all 19 states at 0.42 |
| `hl/icons/*.svg` + `.png` | NEW icons, 128 px, transparent: `spike`, `attrition`, `lethal`, `aid`, `gift`, `mooncard`, `reroll`, `skip` |
| `hl/b/`, `hl/e/`, `hl/r/`, `hl/i/` | copies of library art used (paths below) |

Tip: append `#f=02c` (comma list allowed) to a mockup URL to show only those frames.

## 1. Style sheet (summary — the HTML page is the full spec)

**Sampled palette [OBS]** (dominant pixel, 16-step bins): Portal stone `#D8C8A8`, Portal roof `#F86838`, Portal band `#B83828`, House roof `#88C858`, stall wood `#C88848`, Savannah plot `#F8B848`, Echo pot glass `#B8E8F8`. Arctic snow plot sampled `#98D8B8` / `#288878`.

**UI surfaces [INF, derived from samples]:** cream-50 `#FFF8EA` (lightest; no pure white anywhere) · cream-100 `#F8EBD2` / cream-200 `#EBD3A8` (panel gradient top → bottom) · cream-300 `#DDBF8C` (inset well) · wood band `#D79A58 → #B87440` · dusk plate `#3B2618` · line `#8A3E22` · outline `#24140B` · ink `#3A2214` / `#6E4A30` / `#9A7650` (disabled) · bar track `#4A2A1A` · scrim `#24140B` @ 55% (62% on defeat).

**Accents:** primary `#FF9345` (pressed `#E8742A`) · gold `#FFC445` · threat `#D9472B` (tabs/glyphs, no text on it) · enemy HP `#F58A5E → #D9472B` · party HP `#86D65E → #4FA62F` · shield `#6CB8EC` (chip fill `#CFE7F7`) · info `#5FCFCB` · **Lunar Gem `#A27BEA`, button `#C2A6F4 → #9A72E6`, ink `#1E1236`, shelf `#4E2E8A` — paid surfaces only.** Ascension badge `#C9302B` + `#FFF8EA` (5.6:1, the one dark-red fill with cream ink).

**Rarity [OBS]:** as brief; dark ink; Mythic border `#0A0408`, ink `#2A0F2E`.

**Type:** Baloo 2 800 — Display 56/1.0 · H1 36/1.1 · H2 26/1.15 · H3 20/1.2 · Label 15 caps +.06em · Numeral L 34 · Numeral S 17. Work Sans 600 — Body 16/1.45 · Small 14/1.4 · Micro 12/1.35 (in-frame captions only).

**Outlines:** panels 4 px `#8A3E22` · chips, buttons, dice, badges 3 px `#24140B` · anything ≤ 24 px 2 px `#24140B` · numerals over the 3D scene: 2 px 8-way `#24140B` text outline + 2/4 drop (3 px + 3/6 for ≥ 48 px).

**Light + shadow:** light top-left. One contact shadow: `x+3…4, y+4…6, blur 0, #4A220E @ 30–35%`. Raised surfaces add `inset 2px 2px 0 rgba(255,248,234,.65)`. Gradients are vertical 2-stop (Godot: GradientTexture2D). Only blur: Land behind meta panels, 12 px.

**Buttons:** heights L 60 · M 48 · S 36; radius 14 / 12 / 10; border 3. Primary: `#FFB070 → #FF8A3A`, ink `#2A1505`, shelf `3px 5px 0 #8A3E22`. Hover: `#FFC48E → #FF9A50`, translateY −2, shelf y 7. Pressed: flat `#E8742A`, translateY +3, shelf 1/2. Disabled: `#DDBF8C`, border + ink `#9A7650`, no shelf. Owned: `#A8D878 → #7DBE4E`, ink `#183A0C`, ✓ disc 22. Secondary: `#FFF8EA → #EBD3A8`, ink `#3A2214`. Focus: hover look + 3 px `#FFC445` ring, offset 3. A decline button next to a paid button is always the same width and height.

**Panels:** nine-slice, corner 28, border 4, header band 52 (wood) or 56–72 (dusk / violet for paid / Moon Card), body padding 18–28. **Chips:** h 30 (tray/plates: 26), r 9 (8), border 3 (2), icon 20 (18), Baloo 16 (14); more than 4 → "+N" dusk chip. **HP bar:** r 9, border 3, track `#4A2A1A`; numerals centred, outlined. Damage preview = gold hatched segment (`#FFC445`/`#E8A23A`, 135°, 6 px).

**Motion + reduce flashing:** table on the style sheet; every animated element has a static variant. Speed control 1× / 2× / Skip (Space) on every resolve.

## 2. Land hub (01a–01d)

**Camera:** fixed. Land diamond centred on x 960; top tip 180 + dy, height 820, inset 60 each side; cliff = same diamond 36 lower (`#B87440 → #8A4E28`; Arctic `#7FA8A8 → #5A8384`). `dy = (H − 1080) / 2` — the Land stays centred, bars stay on their edges.

**Top bar (shortcut bar):** left 16, right 16, top 16, h 68, r 20, panel style. Order: Profile chip (avatar 40, name, Land tier) · shortcuts (h 52, r 12, render thumb 36, label Baloo 15, key hint 11) — Run 1 · Teams 2 · Missions 3 · Echo Box 4 · Pass 5 · Vault 6 · Store 7 · Mastery 8 · Gallery 9 · currencies (h 44): Gene Shard, Land Stone, Lunar Gem + "+" (26, violet) · Codex 48 · Settings 48. Badge on a shortcut = 18 px orange dot. Locked shortcuts: fill `#E8D6B4`, border `#9A7650`, opacity .8, key hint replaced by the tier that builds it. Keyboard: 1–9 open; Tab walks the bar left → right.

**Buildings** (centre-x, base-y at 1080; box w × h; image bottom-aligned in the box):

| Entry | Render [OBS path] | cx, base | box |
|---|---|---|---|
| Portal → Run Setup | `godot-ready/thumbs/.../Portal/SM_Portal_01.png` | 960, 640 | 360 × 360 (biggest) |
| House → team presets | `renders/buildings/house/House_lv2.png` | 560, 470 | 250 × 230 |
| Missions | `renders/buildings/weaponsmith/Weaponsmith_lv3.png` **[INF]** | 1360, 470 | 210 × 250 |
| Echo Box | `renders/buildings/alchemy/SM_Alchemy_lv2_Prefab.png` **[INF]** | 470, 770 | 190 × 230 |
| Season Pass | `renders/buildings/equipmentstall/EquipmentStall_lv2.png` | 1450, 770 | 210 × 230 |
| Vault | `renders/buildings/gemstorage/GemStorage_lv2.png` **[INF]** | 235, 650 | 200 × 200 |
| Store | `renders/buildings/jeweler/Jeweler_lv3.png` **[INF — proposal]** | 1685, 650 | 190 × 230 |
| Mastery Hall (Arctic+) | `renders/buildings/armorsmith/Armorsmith_lv3.png` **[INF]** | 760, 340 | 170 × 190 |
| Gallery (Genesis+) | — plot only in Round 1 | 1160, 330 | plot 200 × 108 |

Store proposal: **Jeweler** — a gem tent reads as "where Lunar Gem is sold" and its violet roof matches the Gem colour. Alternative considered: `ConsumableStall` (potion tower — reads as a shop for consumables, which the Store does not sell).

**Name plate:** under the box, overlap −4; padding 5 14 6; r 12; border 3 `#24140B`; key chip 20 (dusk) + name Baloo 19; optional sub-line Work Sans 12. **Badge:** top-right of the box (right 6, top 4), h 30, pill, border 3: FREE `#8CC85A`/`#183A0C` + gift · CLAIM `#FF9345`/`#2A1505` · NEW `#FFC445`/`#3A2A12` · VIP `#A27BEA`/`#1E1236` + moon card. Season end on the Pass plate as a date: "Season 1 · ends 30 Nov 2026" — never a countdown.

**Empty plot (not yet built):** Savannah plot render at 200 × 108, opacity .75, saturate .6, 3 px dashed `#8A3E22` diamond, lock sign (32 plate + post), plate `#E8D6B4` with "Builds at Arctic Land" / "Builds at Genesis Land". Never hidden.

**Run plate (under the Portal):** 340 × 84, r 18, border 4, primary. "RUN" Baloo 38 + "Enter the Portal · Run Setup" + key chip "Enter". **Unfinished run (01b):** 420-wide panel: Continue run (h 68, primary; line: act · floor · Ascension · party standing) + New run (h 48, secondary) + note "New run asks to confirm before it ends the current run."

**Tiers:** Savannah ground `#FAD27C → #F2B652 → #DE9A3C`; Arctic `#F4FBF9 → #D6ECE8 → #B4D6D2`; decor swaps to the biome set (`renders/environment/<biome>/`). Savannah has Portal, House, Missions, Echo Box, Pass, Vault, Store [OBS brief]; Arctic adds Mastery Hall; Genesis adds Gallery.

**Axies:** 3 wandering placeholders, 96 × 78 dashed ellipses, kept off name plates and the Run plate.

**Moon Card popup (01c):** 800 wide, centred, top 210 + dy, r 28. Header 64 dusk-violet `#4A3570 → #33244F`. Price block: "4.99 USD" Baloo 48 + "= 420 Lunar Gem". Benefit grid 2 × 3 (rows ≥ 52): 20 Gem a day (claim yourself · no stacking) · 1 Echo ticket a day · 1 Boon a day (counts toward the 1-Boon-per-run limit) · Continue at −25% once per run · *No Gene Shard boost* · *No Land Stone boost* (greyed, stated so nobody assumes them). Buttons: Close and Buy · 4.99 USD, both 352 × 60. Footer: "Shown at most once a day. The Moon Card is always in the Store. Esc closes." Trigger: second day's login, max once per day, never on the defeat screen [OBS brief]. The ticket wording "Echo ticket" is **[INF]** (brief says "1 ticket/day").

## 3. Combat (02a–02l)

**Anchors.** Top: HUD + nameplates measure from y 0. Bottom: tray, Axies, Aid, END TURN measure from y H. Extra height opens between monsters and party.

**Top HUD (top 12, h 64, r 16, border 3 `#24140B`):**
- Relic bar, left 16: 8 passive slots 44 × 44 (r 10, border 2) · divider 3 × 44 `#8A3E22` · 3 active slots 48 × 48 (r 12, border 3) with a charge badge 20 at −6/−6. A spent active: fill `#E8D6B4`, icon .4.
- Turn plate, centred, 300 wide: "TURN n" Baloo 26 + "Act · Floor · fight type" 12.
- Right 16: Ascension badge 44 h ("A6 ▾", opens the rule list — Round 2) · Gene Shard · Menu 44.
- **Attrition card:** right 16, top 88, 310 × 60. Before turn 6: "ATTRITION · NOT YET / starts turn 6 · +5%/turn · max +25%". Active: "ATTRITION +N%". At max: fill `#FFE3A6`, "+25% · MAX".

**Monsters (normal, 3):** centres x 600 / 960 / 1320.
- Nameplate: top 96, 320 wide, r 16, border 3 (4 when lit). Left: name Baloo 18 (+ ELITE/BOSS tag 20 h dusk) · HP bar h 24 · chips row h 26 with target "→ Bubbles" right-aligned. Right: intent block 88 wide, `#DDBF8C` (gold `#FFC445` when boosted), "NEXT" 11 · icon 26 + number Baloo 30 · action label 12.
- **The intent number is the only number the player needs:** base × enrage × attrition, spike already applied on its turn. No parts to add on the plate. (02e shows 84 = 38 × 2.0 × 1.25 only in this README, not on screen.)
- Counter tab under the plate: overlap −4, side inset 14, h 32, r 0 0 12 12, border 3 no top. Spike: `#FFE3A6`, spike icon, "BIG HIT IN n" + right "HITS 36". The tab takes the same slot as the boss clock.
- 3D box: 240 × 240, top 240 (centre − 120). Ground shadow ellipse. Plate bottom ≥ 12 px above box.

**Boss:** plate 640 wide (left 640), top 92, name Baloo 24, HP bar h 30, phase marks 3 px `#24140B` at 66% and 33%, "PHASE n OF 3" line 12; intent block 128 wide, number Baloo 44. Box 440 × 280 at top 262.
**Boss clock tab** (start turn S, any 1–20): `turn < S−1` dusk `#3B2618`, ink `#FFC79B`, "ENRAGE IN {S−turn}" + "then +20%/turn" · `turn = S−1` `#FFC445`/`#3A2A12` "ENRAGE NEXT TURN" · stacks s ≥ 1 "ENRAGE +{20s}%" with 5 pips (9 × 14, r 3, border 2) filled `#FFB23F / #FF9345 / #F56A40 / #F54540 / #C9302B` · max: `#C9302B`/`#FFF8EA`, "ENRAGE MAX +100%", pips `#FFF8EA`, right "incl. in {intent}". Light version (A0–A3: from turn 14, +10%/turn, max 3 stacks) uses the same tab with 3 pips **[INF]**.

**Party (lower half):** five 200 × 200 dashed boxes, top = trayTop − 222, centred over their tray column (x = column x + 36). No UI above heads. Damage numbers rise from the Axie (Baloo 52, `#FFD0C0` fill, 3 px outline).

**Dice tray:** 5 columns 272 × 176, gap 16, x 248 + i × 288, bottom 16 (top = H − 192). Panel style, r 20, border 3 `#8A3E22` (4 `#FFC445` selected). Padding 12, gap 10.
- Die 104 × 104, r 22, border 3, face icon 40 + Baloo 34. Fill gradient cream → face tint: attack `#FFD9C9` · shield `#CFE7F7` · heal `#D6F0C2` · buff `#F2E0FF` · poison `#DDF2C4`.
- Right: class icon 24 + name Baloo 18 · HP bar h 26 (the **only** party HP readout) · status chips (max 4, then "+N").
- Face strip: 6 faces, h 34, r 9; rolled face border `#24140B`, others `#B89A74` at .8.
- **Selected die:** translateY −26, `0 0 0 4px #FFC445, 0 0 0 7px #24140B`, halo `0 0 34px 12px rgba(255,196,69,.75)` (halo removed with reduce flashing).

**Right zone (free actions):** Reroll 200 × 56 at tray top, right 16 ("Reroll · n left"; at 0 disabled in place). END TURN 200 × 104, right 16, bottom 16, primary, border 4, sub-line "E · n dice unused". Speed control (resolve only): right 16, 66 above the tray, h 52.

**Left zone (paid, Aid):** Aid button 216 × 104, left 16, bottom 16, cream → `#E6DAF6`, border 3 `#4E2E8A`: aid icon 44, "Aid ▴", "used n of 6", "Hide offers: Settings". **Distance to END TURN: 1,472 px.** Offer card: left 16, bottom 132, 216 wide; kicker "AID OFFER · ONCE", title, what + caps, Gem button 192 × 48, "Not now" 192 × 48.
**Aid tray (02h):** 520 wide, left 16, bottom = tray top + 12. Rows h ≥ 60: icon 32 · title + what · cap "used/cap" · price button 96 × 44. Not-applicable rows disabled with the reason ("Boss only", "Pact only", "On defeat"). Top edge must stay ≥ 16 px below the lowest monster box (checked at 1080: panel top ≈ 520 vs box bottom 480).
**First purchase per session (02i):** 600-wide modal, item + Gem price + "≈ 0.11 USD" (90 Gem ≈ 1 USD), "Your Gem 35 → 25", "Aid this run 2 → 3 of 6", Cancel and Pay 10 both 268 × 60.

**Targeting:** legal = gold ground ring (5 px `#FFC445` + 3 px `#24140B`) + 4 px gold plate border. Illegal = box and plate at 40% / 60% + reason chip under the plate (dusk, lock icon): e.g. "Airborne — needs a ranged face" **[INF example rule]**. Hover preview: gold hatched HP segment + chip "−12 · 38 → 26". Lethal: plate border 4 `#D9472B`, HP text "31 / 70 → 0", gold chip with skull "WILL DIE · −12 +20 vuln" (replaces the spike tab while hovered). Focus order: column → die → target.

**Enemy turn (02d):** acting monster plate gold border, intent label "ACTING"; banner 600 wide "ENEMY TURN / Mossback Grub attacks Rex for 12"; tray at 55% with "ENEMY TURN · input locked" chip; lost HP shown cream for 400 ms then ticks; 80 ms hit-stop.
**Victory (02j):** monsters dissolve, party stays; banner `#FFD78A → #FFB23F`, "VICTORY" Baloo 64, button "Pick your reward" 320 × 60 → Round 2 reward panel on the same scene.
**Taller (02k):** identical anchors; 160 px more air between monsters and party.

## 4. Defeat (03a–03c)

Panel 1320 wide, left 300, top 150 + dy, r 28; header 72 dusk-brown "Defeat · Act 1 boss · A6 · your party fell on turn 14". Two columns, gap 24.
- **Recap (left, first):** boss HP card ("Grimroot Colossus had 132 / 640 HP", bar with phase marks, "21% left · phase 3 of 3 · big hit was due in 1 turn"), then one row per lethal/decisive hit (h ≥ 44): turn · hit and number · result ("Buzz KO"). Final turn rows tinted `#FFE3A6`.
- **Second Wind (right):** "Aid used 2 of 6 · Continue 0 of 1". Card: heal per Axie as HP numbers — 40% of max at A0–A5, 25% from A6 (mock is A6, so 25%: +13 / +16 / +15 / +11 / +15) [OBS brief], "Boss stays at 132 HP, phase 3. Big hit in 1 is kept." "Enrage resets to 'Enrage in 10'. Attrition resets to 0%."
- Buttons: End run / Continue, both 302 × 72, gap 14. Prices: normal 60, boss 120 (≈ 1.33 USD) · Moon Card −25% → 90 with 120 struck (03c) · free sample (03b): green gift treatment, "A GIFT · ONCE PER ACCOUNT", "first elite or boss loss · A0–A2". Whether the gift consumes the run's 1 Continue is **[INF]** (mock says yes).
- No VIP / Moon Card sale on this screen [OBS brief].

## 5. Open points for Liam

1. Missions / Echo Box / Vault / Store building choices are proposals (table above).
2. "Airborne — needs a ranged face" is a placeholder rule for the illegal-target reason.
3. Light boss clock (A0–A3, 3 stacks) uses the same tab with 3 pips — confirm.
4. `godot/CLAUDE.md` UI rules still describe the old system; update after you accept this sheet.
