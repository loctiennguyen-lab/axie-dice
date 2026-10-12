# UI request 02 — Round 3 · meta and menu screens (+ Round 2 addendum) · delivery

Drafted 12 Oct 2026. **Normative for Round 3.** If a mockup frame and this file disagree, this file wins. Visual system = Round 1 (`Dice UI R1 README.md` + `Dice UI R1 - Style Sheet.dc.html`) plus the addendum page `Dice UI R3 - Shared Components.dc.html`. All numbers are canvas px at 1920 × 1080; taller window = 1920 × 1240 (extra height goes to the panel body).

Tags: **[OBS]** read from the brief or attached files · **[INF]** our inference, confirm or change.

## Files

| File | Frames |
|---|---|
| `Dice UI R3 - Shared Components.dc.html` | 00b style-sheet addendum: panel shell, currency chips, price buttons, confirm modal, toast, error banner, skeleton, lock plate, Season 2 ribbon, rarity chips + Mythic card, tabs, segmented, toggle, scrollbar, date line, focus ring, badge rules |
| `R3 Land Backdrop.dc.html` | child component: Land blurred 12 px + scrim 55% + live shortcut bar (with the new Daily chip). Used under every meta frame |
| `Dice UI R3 - Run Setup.dc.html` | M1a–M1m · M2a–M2f |
| `Dice UI R3 - Vault and Pass.dc.html` | M3a–M3g · M4a–M4f |
| `Dice UI R3 - Echo Box.dc.html` | M5a–M5w |
| `Dice UI R3 - Missions.dc.html` | M6a–M6l |
| `Dice UI R3 - Store and Daily.dc.html` | M7a–M7n · M8a–M8e |
| `Dice UI R3 - Profile and Account.dc.html` | M9a–M9g · M12a–M12d · M14a–M14d · M13a–M13f |
| `Dice UI R3 - Codex Settings Land.dc.html` | M10a–M10d · M11a–M11d · M15a–M15e |
| `Dice UI R2 Addendum.dc.html` | B1a–B1d, B2, B3a–b, B4, B5a–b, B6–B10 |
| `Dice UI R3 contact sheet.png` | every frame above at 0.2 |
| `r3/chests/*.png` | copied from `godot/assets/echobox/chests/`: 6 tier chests + `mystic.png` (Series 1). `slp-chest`, `axs-chest` not copied, never drawn [OBS] |

Append `#f=M5a,M5n` to any mockup URL to show only those frames.

**New icons:** none. Every glyph reuses `hl/icons/*` (R1), `asc/new-icons/*`, `asc/fx/*`, `asc/node/*`, `asc/portrait/*`, `assets/part/*`, `hl/i/*` [OBS]. Item art in Echo Box, Store and Cosmetics is a labelled slot ("item art" / "art"), to be filled from Cosmetics 01.

## Dates — the one place to change them

- Season 1 starts **3 Nov 2026**; Season Pass ends **29 Dec 2026** (8 weeks) [OBS Liam 12 Oct].
- Seasonal box Series 1 "Lunar Echo" ends **26 Jan 2027** (3 Nov + 12 weeks) [INF].
- Old "30 Nov 2026" withdrawn; Land Hub Pass plate now reads "Season 1 · ends 29 Dec 2026".
- Daily resets 00:00 UTC; week resets Monday 00:00 UTC. Mock "today" = 12 Oct 2026.

## 0. Shared rules (apply to every R3 screen)

**Shell [OBS + one new size].** Land behind blurred 12 px, scrim `#24140B` @ 55%; shortcut bar stays above the scrim, live. Wide panel 1520 × 880 at left 200, top 116 (16 under the bar); corner 28, border 4 `#8A3E22`. **Wood header band 64** on wide meta panels (R1: 52; raised so the M 48 Back fits with 8 px air — added to the sheet) [INF]. Store uses the **violet header 72** `#4A3570 → #33244F` (inside R1's 56–72). Header: Back (secondary M 48, "← Back" + Esc key chip) at left · house thumbnail 36 · title H1 36 `#2A1505` · sub-line Work Sans 14 · optional right element. Modals 600 (confirm) to 1000 (rates tables), scrim 55% over the panel only. Taller window: panel height = 880 + (H − 1080).

**States.** Loading = cream-300 skeleton wells, numbers "—", header + Back live. Error/offline = dusk banner under the header: warning glyph 28–30, one sentence (Baloo 18) + detail line with "Last updated hh:mm", primary "Try again" + secondary "Back to Land" (160–170 × 44–48); cached data stays, greyed 60–65%; server actions disabled with the reason. Guest = "Sign in to use this" plate or banner with a Sign in button (opens M13); top-bar currencies read "—". Newcomer = < 5 created runs that finished ≥ 1 fight: Ranked and Missions locked "Opens after 5 runs · n of 5", no paid offers, Run Setup hides the Kit/Boon column.

**Currencies.** Shard / Stone / Gem chips never mixed; "+" on Gem only. Gem = violet surfaces only; USD buttons orange primary. Price always with its icon. A paid action's decline is the same size: in confirm modals, on the Moon Card tab and on in-run offers. Product cards in a grid open the confirm modal, which carries the decline [INF interpretation of §1.3].

**Trust.** No countdown anywhere (all times written as dates / "00:00 UTC"), no "limited time", no pulsing, no pre-selected purchase (Kit/Boon start un-added), odds + pity inside the screen, first purchase each session confirms with Gem + ≈USD, no age text.

**Fairness line, verbatim** — on the Run Setup Kit/Boon strip, Store › Aid prices, Codex › Difficulty & Keys (and the R1 Aid tray).

**Rarity.** Chips with the word, dark ink. Mythic: `#FF3D6E` chip, border `#0A0408`, ink `#2A0F2E`; night field `#2A0F2E` with ink **`#FF9FB8`** (≈ 7.9:1) and small ink **`#F2D8E2`** — both new, added to the sheet; never white.

**Keyboard + gamepad.** Focus ring 4 px `#FFC445` + 3 px `#24140B`, drawn on the first focus target of each main frame. Esc = back one step (close modal → leave sub-view → close panel). Hub keys R1 + new [INF]: Codex C · Profile P · Daily D · Leaderboard B · Land upgrade L · Settings = Esc on the hub. Gamepad [INF]: A select · B back · X / Y screen primary / secondary · LB/RB tabs · D-pad moves focus in the Tab order below.

**Text floor 12 px.** No R3 text is under 12. Decorative-only exceptions: none in R3.

**Reduce flashing.** Box opening (M5u), claim toasts, badges, level-up, Cosmetics FX preview (M14d): static versions, 200 ms fades, no rim glow.

**New colour values on the sheet:** `#FF9FB8`, `#F2D8E2` (Mythic night ink) · Gem button hover `#D4BEF8 → #AE8CEE`, pressed `#8A62D6` · toggle On fill `#7DBE4E` (from the Owned gradient), Off `#9A7650` · Season 2 ribbon = dusk `#3B2618` + `#FFC79B` (R1 tab ink).

## 1. Entry map [OBS brief §2]

As in the brief. Additions drawn: Daily chip in the top bar between Gem-less right cluster and currencies (h 44, gift 26, "Daily" + key D, CLAIM pill 20 high at −6/−10) [INF]; Leaderboard button in the M1 header (secondary M, key chip B); Codex button shows key C.

## 2. Screens

### M1 Run Setup (Portal, key 1) — frames M1a–M1m

**Deviation [INF]:** the brief asks for three columns *and* five 272-wide party slots in a row; 5 × 272 + 4 × 16 = 1,424 needs the full body width. Party is therefore a full-width top row; the three columns (Mode + Length 440 · Ascension flex · Kit/Boon 400) sit under it.
- Body padding 14 24. Party label row 36 ("PARTY · n OF 5", Load preset / Save as preset S 36). Slots 272 × 176, r 20, border 3 `#8A3E22`: portrait 52 · name Baloo 19 · class line 12 · source tag 24 (Starter dusk / Vault cream / NFT gold) · face strip 6 × 34 (rolled face 1 outlined) · Swap / Clear S 36. Empty slot dashed, "Pick an Axie".
- Mode segmented 3 × 62 (label 18 + rule 12); detail box below (title 16 + line 13). Length segmented 2 × 54; Full locked "Win a Short run to unlock Full". Seed well 44.
- Ascension: chips 42 × 44 gap 6 (selected `#FF9345` + shelf 4 `#8A3E22`; locked `#E8D6B4`/`#9A7650` + lock 12); title H2 26 "A6 · First Pact" + "6 rules active"; multiplier line Baloo 14 `#8A3E22`; rule list rows 26, gap 2, in a cream-300 well (icon 18 · code 30 · name 112 · line 13). Selected row orange + NEW tag 18. A9+ rewrites A4 ("Enrage from turn 8 (A9)…"), A10 greys A6 ("Replaced by A10…"). Locked hover/focus: dashed chip + dashed preview row + dusk tip "Win a run at A{n−1} to unlock A{n}". Unlocked max = best win + 1. Goal chips "A5 TITLE" / "A10 TITLE" (earned green ✓).
- Kit/Boon column (violet surface cream → `#E6DAF6`, border 3 `#4E2E8A`, header 44 dusk-violet): rows ≥ 58 — Starting Boon 38 Gem ≈ 0.42 USD · Run Kit 60 Gem ≈ 0.67 USD; Add (violet S 84 × 36) / Remove; Moon Card Boon row "Added" when active. Three rule lines + fairness line. Nothing pre-added.
- Footer 84 cream-300: summary + Begin (380 × 60). Begin shows "Begin run · n Gem" + ≈USD; disabled with the reason under it ("Pick 2 more Axies to begin", "Needs a connection to roll dice").
- Daily [INF]: 3 tries per UTC day, "resets 13 Oct 2026, 00:00 UTC". Ranked keeps Kit/Boon [INF]. Offline: Begin disabled (L1 rolls on the server) [INF].
- Unfinished run (M1g): card 640 — Continue run L 60 (focused) + New run M 48 + note. Mission run (M1h): "Abandon (stake is lost)".
- Picker (M1i): sub-view modal 1000, path in header, grid 5 × 124 tiles, tabs All / Starter / Vault. Same Axie cannot be in two slots [INF].
- Tab order: Back → Leaderboard → slot 1…5 → Load / Save preset → Mode → Length → A chips → Kit rows → Begin.

### M2 Team presets (House, key 2) — M2a–M2f
Grid 3 × 3 cards (r 20): name Baloo 21 (16 chars), five seats 58 high, NFT tag, "Best Ascension won with it" [INF], Use for next run (primary S) + Edit / Copy / Delete; drag handle ⋮⋮ (keyboard Alt + ←/→) [INF]. Slots 3 at Savannah, 4–6 at Forest, 7–9 at Arctic [INF]. Removed Vault Axie: dashed "Missing" seat + "Pick a replacement". Tabs My teams / Sample teams (read-only, 4 Guides teams). Delete confirm 600, focus Keep it. Guest banner: local until sign-in.

### M3 Vault (key 6) — M3a–M3g
Left collection 5 × 4 tiles (portrait 52, name, #ID · class); "n / 20 imported", FULL chip at 20. Right 560: ID field 48 (placeholder "e.g. 11778888") + Scan 120 × 48; status plates (looking up · not found · no gene data · network error · VAULT FULL 20/20); found card: 3D placeholder 190 × 160, class chip, NFT, "Secret · plays as {class}", six parts → six die faces (rows 38). Add to Vault / Update entry (primary L) · Use in team · Remove (confirm). Empty state focuses the field. Offline: grid greyed, Scan disabled.

### M4 Season Pass (key 5) — M4a–M4f
Header right "Season 1 · ends 29 Dec 2026". Level badge 72; XP bar 26 (gold, numerals outlined); "Level L needs 500 + 40 × (L − 1) XP" (lv 1 = 500, lv 30 = 1,660, total 32,400); Claim all 220 × 60. Weekly tasks: 3 cards 64 high, 500 XP each, claimable until the season ends [INF layout]. Track: 10 nodes visible (132 × 254, gap 8), scrolls horizontally with a visible bar; node = LV chip · reward icons · label 14 · tags (rarity, Season 1, Stat unlock gold, Season gift violet) · state button (CLAIM / ✓ Claimed / Next / Reach LV n / Not claimed). Premium row: dashed, "SEASON 2" ribbon, no price. Loop row after 30: "every 2,000 XP = 50 Shard" + running total. Reward detail on focus/hover (dusk card 300). Free-track rewards exactly as the brief; stat unlocks say "If you already own it, you get its Shard price instead" in the detail [OBS].

### M5 Echo Box (key 4) — M5a–M5w
- Ticket bar 64: tickets (max 999) · fragments n/10 bar (`#5FCFCB`) · next ticket price (k-th today = round5(200 × 1.05^(k−1)); 1 → 200 · 5 → 245 · 10 → 310 · 15 → 395 · 20 → 505 · 30 → 825; max 30/day) · "Buy enough for 1 pull" shortcut when short · Buy ticket 210 × 48. Confirm when the next price > 2× the day's first [OBS].
- Tabs Regular / Seasonal (46 high). Stage 780 wide (Regular: warm radial; Seasonal: violet → `#2A0F2E`), chest 300, Open 1 / Open 10 (or Open N) L 60 + Rates 150 × 60. Right column: pity bars (cosmetic pulls only: Rare 15 · Epic 60 · Legendary 200 · Mythic 1,000), pool 6 tiles (61/55/47/28/20/12 = 223), duplicates line.
- Chest mapping [INF]: Common bronze · Uncommon silver · Rare gold · Epic platinum · Legendary diamond · Mythic lunacian; Stone 100/250 bronze, 500 silver, 1,000 gold, 2,500 platinum, 10,000 lunacian. Series 1 = `mystic-chest`.
- Ceremony: idle → pressed 0.3 s (scale .94/.9) → opening 1.2 s (rim 6 px in tier colour + 40 px glow) → reveal (Stone card 360 / cosmetic card 400) → Open 10 grid 5 × 2 cells 128 × 150 with Skip (Space) visible from the start → summary. Mythic ≤ 2 s. Reduce flashing: static 6 px rim, 200 ms fade (M5u).
- Seasonal: "Open" always says 5 tickets; first pull per session confirms (M5o); first visit explainer (M5t); series card 11 named slots (6 Epic / 3 Legendary / 2 Mythic, Mythic on night field), milestones 12 / 40 / full set, "max 80 pulls (400 tickets)". Lunar bar on `#2A0F2E`: Mythic c/40 + next-pull chance, thin Legendary c/20 and Epic c/10; fills brighten past 50%. **Note:** with p(c) = (2c−1)/(N² − (c−1)²), pull 31/40 is **8.7%** (the brief's example said 8.5%); frames use the formula.
- Rates disclosures (M5i, M5r): full tables from the brief, inside the screen.
- L1 (M5m): Seasonal tab "COMING LATER", greyed mystic chest + "Season box — coming later", no Open button. "Your last pull" after an interrupted window (M5v).

### M6 Nhiệm vụ (Missions, key 3) — M6a–M6l
Header right: Shard balance + "Usable for stakes: n" (starter allowance excluded) [INF]. House strip 48: Lv 1–4 with costs; Upgrade disabled "Not in this build" in L1. Six cards (3 × 2, `minmax(0,1fr)` rows): tier chip, mode · Ascension, m in force + "table ×m · updated 12 Oct", rule rows 24 (Standard + ≤ 2 extras + dashed Side-condition row "later"), 2 × 2 number tiles (Stake · Pay if you win (+profit) · Stone · All players win), "Expected return: about X% of your stake · your figure / all players", own estimate after 10 runs, dusk no-help strip, Stake button 40 ("Stake 500 and play / stake is lost if you fail"). Locked: rules dimmed + lock plate with reason ("Not in this build" + later requirement). Win rates used [INF placeholders]: N1 58% · N2 41% (you 30% → 59%) · N3 31% (you 25% → 61%) · N4 24% · N5 not enough data · N6 12%. Confirm modal 600 (focus Not now; soft 50% income line), Win / Lose / Cancelled results 800 with two equal buttons. Insufficient Shard: button shows the missing amount. One open run: banner + disabled cards.

### M7 Store (key 7) — M7a–M7n · **L1 main state = M7a**
Violet header 72 with Gem chip + Buy Gem. Strips: L1 "Playtest: Gem is free" (300/day, cap 900, Claim 300 Gem violet 220 × 48, next claim as a date) · spending strip 40 ("This month: n USD of your limit m USD" / L1 "applies when purchases open") + Change limit. Tabs Gem · Moon Card · Tickets · Cosmetics · Aid prices (46 high, violet). Gem: 6 cards (80 / 420 / 880 / 1,800 / 4,650 / 9,600; ≈ 81 / 84 / 88 / 90 / 93 / 96 per USD), USD button 60. Starter Pack row (after run 3, once). Moon Card tab: benefits grid as R1 01c (referenced, not the popup), price 4.99 USD = 420 Gem, Not now + Buy same size; active state "Active · ends 11 Nov 2026" + Claim today's 20 Gem. Tickets: 6/15/40/100 for 120/285/720/1,700 Gem; short → greyed "need n more Gem". Cosmetics: 4 × 2, prices placeholder [INF] 90/180/360/720; Season item shows "Only from the Seasonal Echo Box", no price. Aid prices: read-only list + cap line + fairness line. Purchase flow M7h–M7k; spending confirm at 250 USD [INF] M7l. **L1:** every USD button greyed with "Playtest: purchases disabled"; Moon Card buy disabled, no trial.

### M8 Daily (key D) — M8a–M8e
Panel 800 at (560, 180). Cards: Daily reward (60 Shard + 500 Stone + 100 Pass XP after 1 finished run) · Weekly bonus (4 dots, +150 Shard + 2,000 Stone) · L1 Gem gift (violet; at cap "You hold 900, nothing to claim"). Buttons 190 × 56.

### M9 Leaderboard (key B) — M9a–M9g
A0–A10 chips (best preselected), filters Pure (default, glyph + word) / All / Nhiệm vụ, period Today / This week / Season. Table rows 46 (rank · player · Land badge · Aid column glyph + word · score · mode · date), visible scrollbar, own row pinned 54 (`#FFE3A6`, YOU). Row detail card 420. Score formula not shown [INF].

### M10 Codex (key C) — M10a–M10d
Rail 300: search [INF optional] + 10 tabs from `CodexContent.gd` + Guides. Header strip: title 26 + lede (copy from `TAB_LEDE`) [OBS]. Body Work Sans 16, striped tables, scroll bar 14. Difficulty & Keys adds Ascension list, clock + attrition, Aid prices + fairness line. Relic rows in M10c are layout placeholders (build reads RelicRegistry).

### M11 Settings (Esc on hub) — M11a–M11d
Section index 260 + single column (max 960). Rows ≥ 56; toggles print On/Off; sliders 300; segmented for text size [INF] / UI scale / spending presets. In-run: Back to run, Run section first with the stake warning. L1: "Applies when purchases open".

### M12 Profile (key P) · M14 Cosmetics — M12a–d, M14a–d
Header card: avatar 76 inside frame 96, name 34 + Edit name, Sky Mavis badge, Land tier, title, sync chip. Stats 6 tiles 84; last 10 runs rows 42 with Aid marker + PURE pill. Cosmetics: categories 230 (counts) · grid 5 × 3 tiles 138 · preview 380 (die at 104 / 64 / 36, avatar 96 / 40, Equip + "Per class…" [INF]). Mythic preview uses the night field rules.

### M13 Account — M13a–M13f
Five 600 modals (Choose · Waiting · Move progress · Conflict · Signed in), errors sheet (cancelled, timed out, no network, company workspace blocked, session expired, save failed, sign-out failed), sync chip states, guest hub plate (once per session).

### M15 Land upgrade (key L) — M15a–M15e
Panel 1100 × 760 at (410, 176). Six tier rows: diamond thumbnail 110 × 62 · name · adds · cost + cumulative · button 190 × 48. L1: every button "Not in this build". Costs 40,000 / 100,000 / 180,000 / 500,000 / 1,000,000. Adds beyond Mastery (Arctic) and Gallery (Genesis) are [INF].

## 3. Screen × state (frames that exist)

| Screen | normal | empty | locked | newcomer | L1 | loading | offline | guest | extra |
|---|---|---|---|---|---|---|---|---|---|
| M1 | a b c e | — | d | f | m | j | k | l | g h (open run) · i (picker) · m tall |
| M2 | b | a | b | — | = normal | — | — | f | c d e |
| M3 | b d | a | — | — | = normal | c (lookup) | f | g | c errors · e full |
| M4 | b c d | a | b (premium S2) | — | = normal | — | f | — | e season over |
| M5 | a n | j (no tickets) | m s | — | m | — | k | l | b–h ceremony · i r rates · o t modals · u reduce-flash · v last pull · w tall |
| M6 | a b | g | a b | g | a | — | j | k | c d e f h i · l tall |
| M7 | b d | — | — | (no nudges) | a c f g | — | n | m | e h i j k l |
| M8 | a | — | — | — | a–c | — | e | d | b c |
| M9 | a b c | d | f | g | = normal | e | (banner as M3f) | f | b detail |
| M10 | a–d | — | — | — | — | (static) | — | — | c scroll |
| M11 | a b | — | — | — | d | — | — | d | c in-run |
| M12/M14 | a · 14a b | c · 14c | — | — | = normal | — | — | b | d titles · 14d reduce-flash |
| M13 | a–e | — | — | — | — | b | f | a | f errors + sync |
| M15 | b | — | a | — | a | — | — | — | c d e |

Not drawn because identical to a drawn state: M2/M4/M9 loading (same skeleton recipe as M1j/M9e) and offline variants listed "= banner" use the shared banner.

## 4. Round 2 addendum (§B) — `Dice UI R2 Addendum.dc.html`

1. **B1a–d** sequence: map → boss intro (clock line + Delay clock 60 Gem, decline same size) → fight → victory → pact (A6 first / A10 every) → reward → map; act-end banner "ACT 1 COMPLETE"; run-end "RUN COMPLETE" → Result.
2. **B2** Starting Boon pick: modal 1200, three cards (names [INF] placeholders), cannot be skipped once paid.
3. **B3a/b** newcomer run: no Aid button, no attrition card, no light clock tab, no offers. Mission run: mission chip in top HUD, static plate "No Aid in this mission".
4. **B4** in-run menu: Resume (focus) · Settings · Codex · Abandon run… → confirm "Aid you used is not refunded" / "You lose your stake".
5. **B5a/b** Rolling… in the turn plate (< 1 s, no layout change), Reconnecting banner (run kept, input paused, not abandoned), Offline modal (Try again / Back to Land); mission: "Your stake is safe".
6. **B6** loss result. Mission runs link to M6e.
7. **B7** [INF] legend count "Elites on this map: 5 (A9 +2)", positions fogged. Liam decides.
8. **B8** relic detail card 380.
9. **B9** coach-mark (plate + Next / Skip).
10. **B10** light clock tab kept at A0; Ascension badge hidden at A0.

## 5. Round 1 leftovers fixed (§C)

1. R1 README §2: key hint 11 → **12**; locked shortcuts no longer use opacity .8 (fill `#E8D6B4`, border `#9A7650`, ink `#6E4A30`).
1b. Land Hub Pass plate + README: "Season 1 · ends 29 Dec 2026". The Land Hub top bar now carries the Daily chip (CLAIM pill) in every frame, shown to fit at 1920.
2. Style Sheet: all 25 remaining 11 px texts raised to 12 px. Nothing in R1 is now below 12 except the decorative list already in the R1 README.

## 6. Open questions for Liam

1. L1: can gift Gem buy Gem-priced goods (ticket bundles, cosmetics)? Frames draw them **enabled** (M7e–M7h).
2. Daily tries (3/day), Ranked with Aid, offline Normal runs: confirm [INF].
3. Mission win rates and the "usable for stakes" split are placeholders.
4. Pass weekly tasks list and layout; title names for A5 / A10.
5. Fog vs A9 (B7): count in the legend, or reveal elite positions?
6. M1 layout deviation (party row on top) — accept?
7. Header band 64 on wide meta panels — accept as a sheet addition?
8. Gamepad mapping (A/B/X/Y/LB/RB) and the new keys C P D B L.
