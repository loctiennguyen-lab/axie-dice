# UI request 02 — Round 3: meta and menu screens (+ Round 2 addendum)

Soạn 12/10/2026. Liam dán phần tiếng Anh (từ "BRIEF" tới hết "Delivery") vào Claude Design, kèm file đính kèm ở cuối.
Phần tiếng Việt là ghi chú cho Liam, không gửi. Hạn nhận R3: 24/10 (`production/l1-sprint-plan.md`, L1 = 3/11, bản nội bộ).
Nguồn: `design/proposals/{core-loop-v2,economy-v2,echobox-pass-v2,monetization-v1,nhiem-vu-risk-to-earn,ascension-v2}.md`
(khối "QUYẾT ĐỊNH LIAM" ở đầu mỗi file ưu tiên hơn thân file), `design/handoffs/cosmetics-01/REVIEW.md`,
`design/handoffs/ui-02-round1/REVIEW.md`, `design/handoffs/ui-02-round1b/_zip/Dice UI R1 README.md` (hệ hình ảnh duy nhất),
`Ascension v2 README.md` (nội dung dùng lại), `production/l1-sprint-plan.md`, `production/l1-interfaces.md`.
Chỗ nào tôi suy ra mà tài liệu không nói: đánh dấu **[INF]**.

---

# BRIEF (English — paste this)

**From:** Axie Dice dev (Liam) · **To:** Claude Design · **Date:** 2026-10-12
**Status:** ready to hand over. This is Round 3 of UI request 02 (`ui-redesign-request-02.md`, §6 there was one paragraph;
this file replaces it). It also contains a short Round 2 addendum (§B).

## 0. What this is

Round 1 (corrected) is accepted as the **only** visual system: `Dice UI R1 README.md` + `Dice UI R1 - Style Sheet.dc.html`.
Use its tokens, type scale, outlines, buttons, panels, chips, bars, badges and motion rules exactly. Do not add colours,
sizes or styles that are not on that sheet; if you truly need one, add it to the sheet in this delivery and list it.
The old `meta-screens-v2.html` look is dead: every screen here is drawn from scratch. The Ascension v2 delivery
(`Ascension Meta v2`) is reusable as **content and logic only** (rule list, picker states, copy), restyled to Homeland
cream / wood / dusk with `#24140B` outlines.

Platform, canvas, anchoring, "sizes are exact numbers", "name the full set where you write every", HTML mockups +
normative README + contact sheet + new icons: all as in `ui-redesign-request-02.md` §0 and §8. Tag every statement in the
README **[OBS]** (read from attached files) or **[INF]** (inferred). 3D characters stay labelled placeholders.

**Release context.** The first build (L1, 3 Nov 2026) is an internal playtest on Windows + macOS, ~50 invited people.
It has no real-money store: the Lunar Gem is given for free (see M7/M8). Design the full game, but every screen needs the
**"L1 playtest"** variant described where it matters. Cuts decided for L1 (Liam, 12 Oct): **no 7-day Moon Card trial** (the Moon Card is
shown but its buy button is disabled like every real-money action); **the seasonal Echo Box ships after L1** (its tab shows
"Season box — coming later"; the regular box is complete); **Nhiệm vụ ships N1–N3 only and the Missions house cannot be upgraded**
(N4–N6 are shown locked, each with its reason). Draw the full later-state frames too (seasonal box, N4–N6, house levels, Pass premium).

## 1. Shared rules for every meta screen

1. **Shell.** A panel over the Land blurred 12 px (the only blur), scrim `#24140B` @ 55%. The shortcut bar stays visible and
   usable behind it. Panel = nine-slice, corner 28, border 4, wood header band 52 (dusk 56–72 for paid surfaces, violet for Gem).
   Header: house thumbnail 36 · title H1 · optional sub-line · **Back** button (secondary, M 48) at the left of the header and
   **Esc**. Back always returns to the hub, never to a previous panel except inside a screen's own sub-view (then "Back" =
   one step, header shows the path). Sizes: wide panels 1520 × 880 centred; modals 600–800 wide. Tall window: extra height is
   added to the panel body, header stays put. Nothing scrolls at 1920×1080 except long lists (Leaderboard, Vault grid, Pass
   track, Codex body), which scroll inside a visible scroll area with a visible bar; say which.
2. **Every screen defines these states, and the README table lists them per screen:** normal · empty · locked · newcomer
   (first 5 runs) · L1 playtest · loading from server · error / offline · guest. Draw the ones that differ visibly.
   - **Loading:** skeleton plates (cream-300 wells, no spinner-only screens); header and Back stay live; numbers show "—".
   - **Error / offline:** a banner inside the panel under the header (dusk plate, warning glyph, one plain sentence, one
     primary "Try again" button, one secondary "Back to Land"). Cached data stays visible and greyed with "Last updated hh:mm".
     Never an empty panel with only an error. Server-owned actions (open box, claim, stake, buy) are disabled with the reason.
   - **Guest (not signed in):** a guest has no wallet, no real rewards and no leaderboard entry (architecture decision). Reading is
     allowed everywhere; every action that needs a wallet or server (Echo Box open, Nhiệm vụ, Ranked, Daily claim, Gem claim, Store buy)
     shows a "Sign in to use this" plate with a "Sign in" button (opens M13). Desktop has no account until the player signs in.
   - **Newcomer** = the account has fewer than 5 created runs that finished at least one fight. Ranked and Nhiệm vụ are locked
     ("Opens after 5 runs · n of 5"). No paid Aid offers anywhere in a run (see §B), except the one free Continue sample
     (A0–A2, first elite or boss loss, once per account). Run Setup hides the Kit/Boon strip. The
     Store stays reachable like any house (no nudges beyond the rules in M7).
3. **Currencies.** Gene Shard (Echo tickets, Nhiệm vụ stakes, shop in runs), Land Stone (Land upgrades only), Lunar Gem
   (paid/free-gift surfaces only: violet). Never mix them. Gem is violet only on paid surfaces; USD buttons are orange primary.
   A price always shows its currency icon; a paid button always has a same-size "Not now / Close" button next to it.
4. **Trust rules** (apply to Store, Echo Box, Nhiệm vụ, Moon Card): prices and caps always visible; no countdown timers
   anywhere (dates are written as dates); no "limited time", no pulsing, no pre-selected purchase; odds and pity published
   in the screen; first purchase each session asks for confirmation (Gem price + ≈USD); no "18+" text anywhere in the game.
5. **Fairness line, verbatim**, next to every Aid price list (Store M7 and Codex M10, Aid tray already has it):
   "Aid makes you stronger for one run. Players who buy more can win more. The Pure leaderboard only counts runs without Aid."
6. **Seasonal items are never sold directly.** No price, no "Buy" on any seasonal-series item anywhere. They come only from the
   seasonal Echo Box.
7. **Season dates.** Pass season = 8 weeks; seasonal box series = 12 weeks. Show the end as a date ("Season 1 · ends 29 Dec 2026"),
   never a countdown. Season 1 starts 3 Nov 2026 and the Pass ends 29 Dec 2026 (Liam, 12 Oct); the seasonal series end 26 Jan 2027 is **[INF]** (3 Nov + 12 weeks); the old
   "30 Nov 2026" is withdrawn. Put the date in one place in the README so we can change it.
8. **Rarity** (chips, borders, tier names, frames only; dark ink on fill; never for numerals, HP bars, intent, damage):
   Common `#C6CEDA`, Uncommon `#40CC3D`, Rare `#33B8FF`, Epic `#BF6BFF`, Legendary `#FF9445`, Mythic `#FF3D6E`.
   **Mythic rules:** never white text on it (≈3.4:1); ink `#2A0F2E`; border near-black `#0A0408` at small size; its night field
   is `#2A0F2E` (one night colour only); always with the word "MYTHIC" or a crystal glyph, never colour alone; Mythic dice,
   frames and FX come only from the seasonal Echo Box; the regular box's Mythic is decor, pets, accessories or titles.
9. **Keyboard + gamepad.** Every screen is fully usable with keyboard only and gamepad only: draw the focus ring (4 px `#FFC445`
   + 3 px `#24140B`) on the first focus target, give a Tab order line in the README, Esc = back one step. Hub keys from R1:
   Run 1 · Teams 2 · Missions 3 · Echo Box 4 · Pass 5 · Vault 6 · Store 7 · Mastery 8 · Gallery 9. New **[INF]** keys:
   Codex C · Profile P · Daily D · Leaderboard B · Land upgrade L · Settings = Esc on the hub when nothing is open.
10. **Text floor 12 px** for anything the player must read; list decorative-only exceptions. Disabled-but-informative ink `#6E4A30`.
11. **Reduce-flashing variant** for every animated element (box opening, claim bursts, badges, level-up).
12. **Notifications and badges (one rule set, drawn once on the style sheet addendum).** A badge is the R1 pill (FREE, CLAIM,
    NEW, VIP) on a house plate and an 18 px orange dot on the matching shortcut. Sources: Pass "CLAIM" when a level reward is
    claimable; Echo Box "FREE" when the player holds ≥ 1 ticket he has not used (tickets from gifts), "NEW" when a new series
    starts; Missions "NEW" when the daily board changed and the player has not opened it today (UTC); Daily chip "CLAIM" when
    today's reward or the Gem gift is unclaimed; Store "VIP" per R1; Vault "NEW" never. At most one badge per house. A badge
    clears when the player opens the screen, except CLAIM which clears when claimed. No red numbers, no counters, no blinking.
    A toast (dusk plate, 4 s, dismissible, no sound pressure) confirms claims and errors; it never carries a sale.

## 2. Entry map (what opens what, and how it returns)

| Screen | Opens from | Key | Returns to |
|---|---|---|---|
| M1 Run Setup | Portal (centre) / Run plate | 1 | Land; "Begin run" goes to the run map |
| M2 Team presets | House | 2 | Land (or back to M1 if opened from it) |
| M6 Nhiệm vụ | Missions house (Weaponsmith) | 3 | Land; after a mission run, the result returns here |
| M5 Echo Box | Echo Box house (Alchemy) | 4 | Land |
| M4 Season Pass | Pass stall (EquipmentStall) | 5 | Land |
| M3 Vault | Vault (GemStorage) | 6 | Land |
| M7 Store | Store (Jeweler) | 7 | Land |
| Mastery / Gallery | later phases: locked plots only (R1) | 8 / 9 | — |
| M8 Daily | gift chip in the top bar, next to the currencies **[INF]** | D | Land |
| M9 Leaderboard | button in M1 header and in M12 **[INF]** | B | the screen it came from |
| M10 Codex / Guides | top bar Codex button; Guides is a tab inside it | C | Land |
| M11 Settings | top bar Settings button | Esc on hub | Land (or the run, when opened in a run) |
| M12 Profile | Profile chip, top bar left | P | Land |
| M13 Account / sign-in | Profile chip when guest; Settings → Account; any "Sign in" plate | — | where it came from |
| M14 Cosmetics | tab in M12 Profile **[INF]** | — | M12 |
| M15 Land upgrade | Land Stone chip, or Land tier label in the Profile chip **[INF]** | L | Land |
| Moon Card popup | already in R1 (01c) | — | reference only, do not redraw |

## 3. Screens

Each screen below lists: purpose · information · actions · states · data. All numbers are final unless tagged [INF].

### M1 Run Setup (Portal)

**Purpose.** One place to start a run: party, mode, length, Ascension, optional Kit/Boon. It replaces the old main menu stepper.
Size 1520 × 880, three columns: Party (left), Mode and length (middle), Ascension (right); footer bar with the Begin button.

**Party of 5.** Five slots in a row, each 272 wide (same rhythm as the combat tray). Slot: class icon + name, a die with its six faces
(face strip as in the tray), source tag "Starter / Vault / NFT". Actions: pick an Axie for a slot (opens a picker grid with the starter
roster + Vault Axies), swap, clear, "Load preset" (opens M2 list inline), "Save as preset". NFT Axies from the Vault are usable in every
run, including Ranked and Nhiệm vụ; they carry an "NFT" tag, no other treatment. Empty slot shows "Pick an Axie". Begin is disabled until 5 are set,
with the reason under the button. Duplicate rules: **[INF]** the same Axie cannot sit in two slots.

**Mode** (segmented control, 3 options, each with a one-line rule):
- **Normal** — free choice of everything.
- **Daily** — same seed for everyone, max 3 tries per UTC day (confirmed), shows "Tries left 3 of 3", resets 00:00 UTC (date, not countdown).
- **Ranked** — counts for the leaderboards (M9). Locked for newcomers ("Opens after 5 runs · n of 5").
In Daily and Ranked the Kit/Boon strip stays available (Aid is allowed in ranked) **[INF]**.
**Length:** Short (3 bosses) / Full (4 bosses). Full is locked until the player wins a Short run ("Win a Short run to unlock Full").
**Seed** line: shows "Random" or the daily seed; no editing in Ranked.

**Ascension picker** (reuse Ascension v2 3.1 logic, restyle): 11 chips A0–A10 (42 × 44, locked ones visible with lock icon),
title "A6 · First Pact", "6 rules active", multiplier line "Enemy HP ×1.21 · Enemy DMG ×1.10 · Boss HP ×1.15" (HP ×1.1 at A1, A6, A10;
DMG ×1.1 at A3, A8, A10; boss HP ×1.15 from A4), the full cumulative rule list (one row per A1…An with icon, code, name, one line; overrides
rewritten, never hidden: A9+ the A4 row reads "Enrage from turn 8"; A10 greys the A6 row "Replaced by A10 — every boss requires a pact"),
the selected level's row highlighted with a "NEW" tag. Goal chips "A5 TITLE" and "A10 TITLE" (cosmetic titles, earned / not yet).
Rules A1–A10: A1 shop ×1.15, relic sell 40% · A2 elites +1 monster · A3 base rerolls 2→1 · A4 full boss clock (from turn 10, +20%/turn, max +100%;
light clock before A4: from turn 14, +10%/turn, max +30%) · A5 Eternal sticker on elite relics (cannot be sold, max 2) and weakened Axie announced ·
A6 first boss forces a pact · A7 reward shows 2 cards · A8 passive slots 8→7 · A9 +2 elites, clock from turn 8 · A10 every boss forces a pact, no reward reroll.
Variants: A0 (one sentence "No ascension rules at A0…"), A6, A10, locked level on hover/focus (dashed preview + "Win a run at A{n} to unlock A{n+1}"),
and the unlocked-level maximum is the player's best win + 1.

**Kit / Boon strip** (paid, violet surface, hidden for newcomers; every price shows its Gem and ≈USD): Starting Boon 38 Gem (pick 1 of 3 small Boons)
and Run Kit 60 Gem (2 extra rerolls + 1 Scout + 1 Boon, ≈25% cheaper than buying them apart). Rules shown on the strip: max 1 Boon per run from any source
(Boon, Kit, VIP, Starter), the Boon counts toward the Aid cap (6, or 4 at A9–A10) "Aid this run 0 of 6", no Boon in Nhiệm vụ runs. The strip carries the fairness line (§1.5) because it is an Aid price list. Each item has Add / Remove (toggle,
nothing is charged until Begin; the Begin button shows the total Gem to be charged and the first purchase of the session confirms). The VIP daily Boon appears
as a free "Moon Card Boon (first normal run today)" row when active. Boon names are **[INF] placeholders** (eight Boons are not written yet): use
"+1 reroll in the first fight", "Shield in turn 1 of the first fight", etc.

**Unfinished run.** If a run is open, the panel opens in a "Run in progress" state: Continue run (primary L 60: act · floor · Ascension · party standing)
and New run (secondary M 48, with the note "A new run asks to confirm before it ends the current run. Aid you used is not refunded."). Choosing New run
reveals the normal setup. If the open run is a Nhiệm vụ run, New run is replaced by "Abandon (stake is lost)" with a confirmation.
**States:** loading (checking for an open run, skeleton), offline (Normal can start with local dice only if the build allows **[INF]**: otherwise Begin disabled
"Needs a connection to roll dice"), guest, newcomer, L1 playtest (Gem strip uses the free Gem balance and says so).
**Return:** Begin → run map (R2). Back → Land.

### M2 Team presets (House)

**Purpose.** Save and reuse parties of 5. Grid of preset cards (3 slots at Savannah **[INF]**, more at higher Land tiers: 6, 9 **[INF]**, from `core-loop-v2` §4.4;
locked slots show the Land tier that opens them). Card: name (editable, 16 chars), five class icons in a row, optional NFT tag, "Best Ascension won with it" **[INF]**.
Actions: new, rename, edit (opens the 5-slot editor = the M1 party component), duplicate, delete (confirm), "Use for next run" (returns to M1 with it loaded), reorder.
Also the "Sample teams" list from Guides (four compositions that work, "Use this team" button) as a read-only second tab.
**States:** empty ("No saved teams yet" + "Build your first team"), slots full, locked slots, a preset that uses a Vault Axie that was removed (card shows the gap, "Pick a replacement"), guest (presets are local until sign-in).
**Return:** Land, or M1.

### M3 Vault (Vault warehouse)

**Purpose.** Import and manage real Axies so they can be used in runs. NFT Axies are usable in every run.
Layout: left = collection grid (max 20 entries, counter "n / 20 imported", caption "FULL" at 20); right = detail / import panel.
**Import:** ID field (placeholder "e.g. 11778888") + Scan; states: idle, "Looking up Axie #…", found (3D preview placeholder "Axie 3D", class, six body parts → six die faces with
type glyphs, a "Secret · plays as {class}" badge when applicable), not found, "came back without gene data, so there is nothing to build a die from", network error, vault full ("VAULT FULL 20/20").
Actions: Add to Vault / Update entry, Use in team (goes to M1 with this Axie placed), Remove (confirm). Detail shows the die with its six faces and the part names.
**States:** empty ("No Axies imported yet" with a one-line explanation and the import field focused), loading, offline (grid readable, Scan disabled), guest (vault is local; "Sign in to keep it across devices").
**Return:** Land.

### M4 Season Pass (Pass stall)

**Purpose.** Show Season 1 progress and claim rewards. Free track from Season 1; premium track exists from Season 2 and is shown as **"Season 2"** (greyed, ribbon, no price, no buy button).
Header: "Season 1 · ends {date}" (date only), level badge, XP bar "xp / need" (level L needs 500 + 40 × (L−1) XP; level 1 = 500, level 30 = 1,660; total 32,400).
Body: horizontal track of 30 level nodes, free row on top, premium row below (all locked "Season 2"). Node states: locked, reached-unclaimed (CLAIM), claimed (green ✓), future.
"Claim" per node and "Claim all". After level 30: loop row "every 2,000 XP = 50 Shard" with the current progress bar and a running total.
**Free track rewards (final):** lv1 300 Shard · 2 1 ticket · 3 1,000 Stone · 4 unlock `u_reroll` · 5 `fx_c_leaf` + 300 Shard · 6 1 ticket · 7 1,500 Stone · 8 unlock `u_hp` · 9 `frame_u_vine` ·
10 500 Shard + 1 ticket **+ 90 Gem** · 11 1,500 Stone · 12 unlock `u_start` · 13 500 Shard · 14 1 ticket · 15 `fx_r_bubble` + 2,000 Stone · 16 unlock `u_reroll2` · 17 500 Shard · 18 1 ticket ·
19 2,000 Stone · 20 unlock `u_hp2` + 500 Shard **+ 90 Gem** · 21 `die_u_moss` · 22 500 Shard · 23 2 tickets · 24 2,500 Stone · 25 `die_e_s1_founder` + 500 Shard · 26 600 Shard ·
27 `frame_e_s1_founder` · 28 1 ticket + 3,000 Stone · 29 600 Shard · 30 `frame_l_sovereign` + title "LUNACIA SOVEREIGN" + 4 tickets + 3,000 Stone.
Totals: 4,800 Shard, 16,500 Stone, 12 tickets, 180 Gem (the two 90 Gem nodes are a gift: "Season gift" tag, violet, claim by hand, never expires), 5 stat unlocks, 7 cosmetics + 1 title.
The 5 stat unlocks carry a small "Stat unlock" badge (they count in ranked); text: "If you already own it, you get its Shard price instead."
Reward detail on hover/focus: icon, name, rarity chip, what it does. Cosmetic Season-1 items carry a "Season 1" tag. Epic+ items show the Epic/Legendary rarity colours per rules in §1.8.
Weekly tasks: 3 tasks per week, each 500 XP (e.g. "Finish 5 runs", "Win 2 runs", "Reach a boss once"), a small strip under the header; unfinished tasks stay claimable until the season ends **[INF]** layout.
XP sources line: run XP is capped per UTC day (full up to 1,500, then 20%, max 2,000/day); first run each day +100 XP.
**States:** empty (level 0, nothing reached, "Finish a run to earn XP"), claimable, all claimed, season over (read-only, "Season 1 ended {date}"), loading, offline (claims disabled), guest (progress is local, "Sign in so it follows you"), L1 (same).
**Return:** Land.

### M5 Echo Box (Alchemy)

**Purpose.** Open loot boxes with tickets. **One building, two tabs: "Regular" and "Seasonal"**, one ticket bar above the tabs. Every pull gives exactly one reward: either Land Stone or one cosmetic.
**Ticket bar** (always visible): tickets (0–999), fragments n/10 (10 fragments = 1 ticket), next ticket price, "Buy ticket" button, "Reset 00:00 UTC".
Tickets are bought with Shard: the k-th ticket bought today costs round5(200 × 1.05^(k−1)) (k=1 → 200, 5 → 245, 10 → 310, 15 → 395, 20 → 505, 30 → 825), max 30 a day; tickets from gifts, duplicates, Pass, bundles do not raise the price.
New accounts start with 3 tickets. Ticket bundles are bought in the Store (M7). A "Buy enough" shortcut appears when tickets are short, showing the total Shard; confirm when the next price is over 2× the first price of the day.
**Regular tab.** One line: "1 ticket per pull. Many items, fixed rates. 6 pulls in 10 give Land Stone." Chest art from `godot/assets/echobox/chests/tiers/`:
bronze, silver, gold, platinum, diamond, lunacian = Common … Mythic **[INF mapping]**: the chest shown on the result matches the reward's tier (cosmetic rarity; Stone 100/250 → bronze, 500 → silver, 1,000 → gold, 2,500 → platinum, 10,000 jackpot → lunacian **[INF]**).
Buttons "Open 1" and "Open 10". Panels: pity counters (cosmetic pulls only: "Rare guaranteed at cosmetic pull 15: 9/15", then 60 Epic, 200 Legendary, 1,000 Mythic), pool progress per tier (collected n / total: 61, 55, 47, 28, 20, 12 = 223 items), a "Rates" disclosure (see below).
**Seasonal tab.** One line: "5 tickets per pull. A small set of rare items. A full set is guaranteed within 80 pulls (400 tickets). Max 8 pulls a day." Themed chest art from `chests/themed/`
**excluding `slp-chest` and `axs-chest`** (never draw them); Series 1 "Lunar Echo" uses `mystic-chest.png` **[INF]**, other themed chests are future series art.
Series card: name, 11 silhouette slots in 3 tiers (6 Epic, 3 Legendary, 2 Mythic; owned slots light up, missing slots show a named silhouette, nothing hidden), "n / 11", "Pulls opened m", milestones: 12 = title, 40 = exclusive `die_m_moon` + title, full set = title + "Series 1 complete" badge,
"Max 80 pulls (400 tickets) to complete", "Series ends {date}" (date only). **Lunar bar:** Mythic counter c/40 and next-pull chance (e.g. "Pull 31/40 — 8.5% this pull — certain at 40"); thin bars for Legendary c/20 and Epic c/10; bar colour changes past 50%.
Vault of old series: a small card below ("Earlier series — odds are 2× slower"), **empty at Series 1** ("No earlier series yet").
Pulls left today "x / 8". "Open 1" / "Open N" (N = pulls left today, max 10). **The Open button always says "5 tickets"; the first seasonal pull in a session opens a confirm modal** (tickets to be spent, tickets after, pulls left today).
First visit to this tab shows a 3-line "How the seasonal box differs" modal (dismissible, once).
**Opening ceremony (draw each state, plus reduce-flashing variant):** idle chest · pressed/charging (≈0.3 s) · opening (≈1.2 s, rim colour = tier colour) · reveal: Stone result ("+1,000 Stone", stack-size colour) or cosmetic card (rarity chip, name, tag NEW / DUPLICATE "+n fragments (x/10)" / "+1 ticket") ·
Open 10 grid (10 cells opening in order, **Skip** button visible immediately) · summary (total Stone, new items, pity / Lunar bar updated; seasonal also "≤ X pulls to the exclusive", "≤ Y pulls to complete"). No full-screen flashes. Mythic gets the longest beat but still ≤ 2 s.
Duplicates → fragments: Common 3, Uncommon 5, Rare 10, Epic 20, Legendary 40, Mythic 80 per duplicate; 10 fragments = 1 ticket. A "Duplicates" help line explains it. Nothing converts to Shard or Stone.
**Rates disclosure (full tables, inside the screen, one click from the Open button):**
Regular: Stone 60% = 100 (15.30%), 250 (24.08%), 500 (13.00%), 1,000 (6.00%), 2,500 (1.60%), 10,000 (0.02%, 1 in 5,000); cosmetic 40% = Common 24.07%, Uncommon 9.72%, Rare 4.52%, Epic 1.264%, Legendary 0.360%, Mythic 0.0632% (Mythic = decor, pets, accessories, titles). Pity as above.
Seasonal: each pull tests Mythic → Legendary → Epic with a rising chance that resets on a hit (certain at the cap: Mythic 40, Legendary 20, Epic 10; formula p(c) = (2c−1)/(N²−(c−1)²) published; sample table Mythic: c=1 0.06%, 10 1.25%, 20 3.15%, 30 7.77%, 35 15.5%, 39 49.4%, 40 100%);
a pull that hits no tier gives Stone: 500 (32.74%), 1,000 (45.13%), 2,500 (17.50%), 5,000 (4.60%), 25,000 (0.03%) of Stone pulls (about 78% of pulls are Stone).
**States:** no tickets (Open disabled + "Buy ticket"), daily seasonal cap reached ("8 of 8 today · resets 00:00 UTC"), seasonal box not started / ended (read-only), series complete, loading, offline ("Opening needs a connection"; nothing is spent), guest (can look, cannot open: "Sign in to use this", a guest has no tickets or wallet), L1 (the seasonal box is not live: draw the tab locked as "Season box — coming later", no Open button; the regular tab is complete; also draw the full later-state frames).
A pull interrupted by a closed window keeps its result: on return show "Your last pull" result. **Return:** Land.

### M6 Nhiệm vụ board (Missions house, Weaponsmith)

**Purpose.** Hard staked missions: you pay a stake in Gene Shard, play one run with harder rules, win = payout, lose = the stake is gone. Nothing here is sold for real money.
Layout: header with Shard balance and "Board changes 00:00 UTC" (no countdown); six tier cards in two rows of three; right column "Rules of every mission".
**Cards (final numbers; L1 ships N1–N3, later N4–N6):**
| Tier | Mode | Ascension | Stake | m (public) | Pay if you win | Stone if you win |
|---|---|---|---|---|---|---|
| N1 | Short | A3 | 300 | ×1.60 | 480 | 4 |
| N2 | Short | A4 | 500 | ×1.95 | 975 | 8 |
| N3 | Short | A6 | 800 | ×2.45 | 1,960 | 14 |
| N4 | Short | A7 | 1,200 | ×3.30 | 3,960 | 22 |
| N5 | Short | A9 | 1,800 | ×3.78 | 6,805 | 34 |
| N6 | Full | A9 | 2,500 | ×6.48 | 16,200 | 60 |
**L1 ships N1–N3 only; the Missions house is not upgradable in L1 (Liam, 12 Oct).** N4, N5, N6 are shown locked with the reason "Not in this build"
(later: "needs Mission house level 2/3/4" and, for N6, "win a Full run at A9"). Mission house levels: 1 free (N1–N3), 2 costs 3,000 Shard + 4,000 Stone (+N4),
3 costs 8,000 Shard + 12,000 Stone (+N5), 4 costs 20,000 Shard + 30,000 Stone (+N6). Draw the house-level strip with these costs; in L1 its upgrade button is disabled "Not in this build".
Unlock rule per tier: the player must have won a run at that tier's Ascension (N1 A3, N2 A4, N3 A6, N4 A7) — locked cards show the exact requirement.
**Each card shows (before the player pays anything):** tier name, mode, Ascension, the extra rules in words, side condition if any, stake, **m currently in force** (public; "×3.30, table ×3.30, updated {date}" — it can only go down), pay if you win, Stone, win rate of all players on this tier ("Players win about 31% of the time" or "Not enough data"),
the player's own estimate ("You: about 25%" in ranges of 5, shown after ≥ 10 runs), and the line **"Expected return: about X% of your stake"** on the card itself (the personal figure if known, else the all-players figure). N5/N6 add "Test tier: on average players get back less than 100%."
**Extra rules, visible before staking** (each is a row with icon and plain text; a card has the Standard set + at most 2 extras): Standard = enemies +10% damage, elites +10% HP, **no Aid, no Continue, no Boon**.
Extras: Harsh clock (boss clock from turn 6, +20% per turn, max +100%) · Spike rush (elite/boss big hits come 1 turn sooner) · Hunted (+2 elite nodes) · Heavy blows (+15% enemy damage) · Thick boss (+25% boss HP). Two sets A/B rotate daily.
**Side conditions "One house" and "All colours"** (add to the rule list, as the third kind of row, labelled "Side condition"): "One house" = win with a team of a single class (listed class per day; N2–N4); "All colours" = win with at least 4 classes in the team (N1). A side condition replaces one extra rule (N1 adds it). **[INF] these two are not planned for L1** (`l1-sprint-plan.md` §0 lists side conditions as out of L1): design the row, but the README marks it "later".
**No-help notice** (a dusk strip on every card and in the confirm): "No Aid, no Continue, no Boon in this run. One life." Newcomers see all cards locked: "Opens after 5 runs · n of 5".
**Confirm stake modal** (600 wide, decline same size as confirm): tier, rules, "You pay 500 Shard. Win: you get 975 (+475) and 8 Stone. Lose or quit: you lose 500, no refund. Expected return for you: about 59%." Buttons "Stake 500 and play (stake is lost if you fail)" and "Not now". Balance after payment. A soft information line (not a block) when today's stakes exceed 50% of the player's estimated weekly income. Focus starts on "Not now".
Only one run can be open: if one exists the cards are disabled with "Finish or abandon your open run first".
**In-run chip** (small, top HUD of the run): tier + extra rules. **Result screen (win and lose, one screen each):** neutral and specific, no "so close", no buy-back, no discount: Win "Mission won · +975 Shard · +8 Stone · stake 500 returned in that total" with the run stats; Lose "Boss 2 beat your team on turn 9, boss clock was +60%. You lost 500 Shard." Two equal buttons "Back to missions" and "Play a normal run". Also a "Run cancelled by the server — your stake was refunded in full" variant (verifier error, no Shard reward).
**States:** empty board (all locked), loading, offline (cards disabled "Needs a connection"), guest ("Sign in to stake"), newcomer, insufficient Shard (stake button disabled, shows missing amount), the starter allowance (Shard given at the start) cannot be staked — show "Usable for stakes: n" next to the balance **[INF]**. **Return:** Land; mission result returns here.

### M7 Store (Jeweler)

**Purpose.** Buy Lunar Gem, the Moon Card, bundles and cosmetics. It sells **no loot box directly** (Echo Box is opened with tickets) and **no seasonal item**.
Violet = Gem surfaces; orange = USD buttons. Tabs: Gem · Moon Card · Tickets · Cosmetics · Aid prices.
- **Gem (6 tiers, USD → Gem, bonus ≤ 20%):** 0.99 → 80 · 4.99 → 420 · 9.99 → 880 · 19.99 → 1,800 · 49.99 → 4,650 · 99.99 → 9,600. Card: Gem icon stack, Gem amount, "≈ n Gem per USD" (81 / 84 / 88 / 90 / 93 / 96), price button. Rule line: Gem cannot be turned into Shard or Land Stone, and cannot be gifted.
- **Starter Pack (first purchase only):** 0.99 USD → 160 Gem + 3 tickets + 1 Boon. Shown after the player's 3rd finished run; disappears after purchase (state: "Claimed"). One per account.
- **Moon Card:** 4.99 USD (= 420 Gem), 30 days, up to 180 days stacked. 20 Gem a day (claimed by hand, no stacking of unclaimed days), 1 ticket a day, 1 Boon a day (first normal run of the day; counts toward the 1-Boon-per-run limit), Continue once a run at −25% (68 / 135 Gem), no Shard and no Land Stone boost (greyed lines saying so). State "Active · ends {date}" with a "Claim today's 20 Gem" button. Same content as the R1 popup (01c): reference it, do not redraw the popup.
- **Ticket bundles:** 6 tickets 120 Gem · 15 tickets 285 Gem · 40 tickets 720 Gem · 100 tickets 1,700 Gem (20 / 19 / 18 / 17 Gem per ticket). Bundle tickets open both boxes like normal tickets, do not raise the Shard price ladder. "Rates" link to M5 disclosure. Show the Gem balance and "Buy Gem" shortcut when short.
- **Cosmetics at a fixed price:** dice skins, avatar frames, dice FX, Axie skins, rarity up to Epic **[INF]**, never Mythic, never items of a seasonal series or Pass. Grid of cards: art, name, rarity chip, price in Gem, state (Buy · Owned ✓ · Season-only: **no price shown**, replaced by "Only from the Seasonal Echo Box"). **Placeholder prices [INF], not final:** Common 90 · Uncommon 180 · Rare 360 · Epic 720 Gem; economy will replace them, do not design around the values. Preview on hover/focus (opens M14 preview).
- **Aid prices (read-only list, not buyable here), with the verbatim fairness line under it:** Continue 90 (boss fight 180; Moon Card 68 / 135) · Extra reroll 15 (3-pack 38; 4 a run, 2 a fight, 1 a fight from A3) · Delay boss clock 60 (1 a boss) · Swap pact 15 (1 a pact) · Shop refresh 18 (2 a run) · Scout 12 (3 a run) · Starting Boon 38 (1 a run) · Run Kit 60 · total Aid cap 6 a run (4 at A9–A10), Boon counts in it. 90 Gem ≈ 1 USD.
- **Spending limit:** a strip at the top: "This month: n USD of your limit m USD" with "Change limit" (opens M11 section). Soft warning at 100 USD a month, extra confirmation at 250, hard stop at 500 (numbers are proposals in monetization §3.6, so **[INF]**). No age text.
- **Purchase flow:** card → confirm modal (item, price, ≈USD, what you get, Gem before → after, decline same size as pay, Esc cancels) → success toast / receipt state. States: processing, failed (plain sentence + Try again), refunded **[INF]**.
- **L1 playtest variant (draw it as the main state for L1):** every USD button is disabled and says **"Playtest: purchases disabled"** (grey, ink `#6E4A30`, with the reason, not just dimmed); a strip at the top "Playtest: Gem is free" with the **daily free Gem claim: 300 Gem a day, balance cap 900** (button "Claim 300 Gem", shows balance and "next claim {date/time UTC}" as a time, not a ticking countdown); a note "Gift Gem is reset when the real store opens." the Moon Card card is shown in full but its buy button is disabled "Playtest: purchases disabled" (no free trial in L1, Liam 12 Oct). Gem-priced goods (ticket bundles, cosmetics, Aid) **can be bought with gift Gem in L1** so testers try every feature (Liam, 12 Oct): draw them enabled. Only USD buttons are disabled.
- **Other states:** newcomer (no extra nudges; Starter Pack appears only after run 3), guest (browse only, "Sign in to buy"), offline (buying disabled), loading, error.
**Return:** Land.

### M8 Daily gift / claim

**Purpose.** One small panel (800 × ~560) that collects the daily things.
Cards: **Daily reward** — "Finish 1 run today (UTC): 60 Shard + 500 Land Stone + 100 Pass XP"; states: not yet / claimable / claimed. **Weekly bonus** — "Claim the daily reward on 4 different days this week: +150 Shard + 2,000 Stone", four dots, week resets Monday 00:00 UTC.
**L1 only:** **Gem gift** — "300 Gem a day, balance cap 900", states claimable / claimed / at cap ("You hold 900, nothing to claim"). Dates and resets are written as UTC dates/times, never as a running countdown. Guest: nothing can be claimed ("Sign in to use this").
**States:** all claimed, offline, loading. **Return:** Land.

### M9 Leaderboard

**Purpose.** Rankings. Open to read for everyone; entries only for signed-in players (guest sees "Sign in to appear here").
**One board per Ascension** (tabs/chips A0–A10; the player's best Ascension preselected). Filters: **Pure** (runs with no Aid; **default tab**), All, **Nhiệm vụ** (mission runs; **[INF]** also per tier), period (Today · This week · Season). **Every created run counts**: a quit run counts as a loss, mission runs are eligible. Row: rank, name (self-chosen), Land tier badge, Aid marker (small glyph when Aid was used), score, mode/length, date; the player's own row pinned at the bottom with rank. Score formula is **not** shown **[INF]** (first pass `1000×win + 40×nodes + max(0,300−turns) + 2×HP left + 100×A`). Show "Last updated hh:mm".
Row detail (click): run summary, party class icons, relics, "Aid used n" line.
**States:** empty board ("No runs here yet"), loading skeleton, offline (cached + banner), guest, newcomer ("Ranked opens after 5 runs"), a board for a locked Ascension (visible, greyed). Pure is a text label and a glyph, not colour alone. **Return:** to where it was opened.

### M10 Codex / Guides

**Purpose.** The rule book. Left rail of 10 tabs (existing content, keep): The Basics · Dice & Body Parts · Mana & Cards · Keywords · Status Effects · Classes & Playstyles · Relic Table · Map & Rewards · Bosses · Difficulty & Keys; plus **Guides** (sample teams, "Use this team") as the 11th tab. Body = scrollable reading area (Work Sans 16), tables with striped rows, icons from the shared set; the header strip shows tab title + one-line lede.
Add to **Difficulty & Keys**: the Ascension rule list, boss clock and attrition numbers (attrition from turn 6: +5%/turn, max +25% at turn 10), and the **Aid price list with the fairness line verbatim** (same list as M7, with the Pure explanation). Search box **[INF]** (filter by keyword) optional.
**States:** loading none (static), a tab with long content scrolls with a visible bar. **Return:** Land (or the run when opened from the combat menu).

### M11 Settings

**Purpose.** Preferences, safety and account. Single column, sections with H3 headers: **Audio** (music, effects, mute) · **Accessibility** (**Reduce flashing and screen shake**, text size **[INF]** 100/115/130%, UI scale, colour-blind-safe glyph mode is already default) · **Aid and spending** (**Hide Aid suggestions** toggle with explanation "Aid stays available in the tray, only the offers stop", **Spending limit**: monthly limit in USD with presets (none / 10 / 25 / 50 / 100 / custom), current month spent, "Limit takes effect immediately; raising it takes 24 hours" **[INF]**) · **How to play** (Replay tutorial) · **Run** (Abandon run with warning: "Aid you used is not refunded"; for a Nhiệm vụ run: "You will lose your stake") · **Account** (M13) · Language **[INF]** · Controls (keyboard map view, remapping later) · About / Terms / Privacy links.
Every toggle shows its current state as text ("On/Off"), not colour alone. In L1 the spending-limit section shows "Applies when purchases open".
**States:** in-run (opened from the combat menu: Run section visible, others normal), guest, offline (Account section shows the status). **Return:** Land or the run.

### M12 Profile

**Purpose.** Who the player is and what they did. Opened from the profile chip. Header: avatar with equipped frame, name (editable, used on leaderboards), Land tier, "Sky Mavis" badge when applicable, account state. Stats: runs, wins, best Ascension, current title, Pure wins, Nhiệm vụ record (won / played, net Shard) **[INF]**, last 10 runs list (date, mode, Ascension, result, Aid marker, Pure mark). Tabs: Overview · Cosmetics (M14) · Titles. Buttons: Edit name, Equip, "Sign in" when guest.
**States:** guest (local stats + banner "Sign in to keep them"), empty (no runs: "Your first run will show here"), loading, offline. **Return:** Land.

### M13 Account / sign-in (desktop)

**Purpose.** Sign in with Google so progress, Gem, Echo Box and Nhiệm vụ follow the player. Desktop opens the **system browser** (Google sign-in), then the game catches the result on a local port.
Flow, one modal each (600 wide): **1 Choose** — "Continue with Google" (primary) + "Play as guest" (secondary, same size); one line on what guest means ("Progress stays on this computer; no Echo Box, Nhiệm vụ, Ranked or Gem"). **2 Waiting** — "A browser window opened. Finish signing in there." with "Open it again" and "Cancel"; no timer text, a 10-minute timeout message. **3 First sign-in with guest progress** — "Move progress" / "Start fresh" (both shown with what moves). **4 Conflict** — "Cloud has progress and this computer has different progress": two cards (runs, Shards, Vault, last played), "Keep this computer" / "Keep cloud", never merged; the loser is kept as a 7-day backup (say so). **5 Signed in** — name, email, Sky Mavis badge, sync state chip, Switch account, Sign out (second press to confirm; "Sync and sign out" when unsynced).
**Sync chip states:** Saved · Syncing · "Offline — will sync" (+ "Sync now") · "This account was played somewhere else" (Keep this device / Keep cloud).
**Errors** (plain sentence + a way forward): cancelled, timed out, no network, company workspace blocked (Use another account / Play as guest), session expired, save failed, sign-out failed.
**Guest state** appears as a slim "Save your progress" plate on the hub once the server has answered, closable, shown once per session. **Return:** where it was opened.

### M14 Cosmetics inventory / equip

**Purpose.** See what you own and equip it. Tab of Profile. Left: categories (Dice skins · Avatar frames · Dice FX · Axie skins/tints · Pets · Decor · Titles) **[INF categories from `core-loop-v2` §9]**; centre: grid with owned (full colour), missing (named silhouette, source line "Regular box" / "Series 1" / "Pass lv 25" / "Store"), counts "n / total"; right: preview (die plate at 104 / 64 / 36 px as used in combat, avatar with frame at 96 / 40) + Equip / Unequip.
Slots: one dice skin, one frame, one FX, one title at a time. Item chips: rarity chip with word, source tag, "Season 1" / "Series 1" tag. **Mythic items:** near-black border at small size, night field `#2A0F2E`, "MYTHIC" word, no white text.
A die skin can also be set **per class** (6 class dice) **[INF]**; keep a single global equip as the default.
**States:** empty ("Nothing here yet: open an Echo Box or claim Pass rewards"), nothing equipped (default plate), item locked by source, reduce-flashing preview for animated FX. **Return:** Profile.

### M15 Land upgrade panel

**Purpose.** Spend Land Stone to move the Land to the next tier. Land gives **no combat power**; it opens breadth only (houses, team preset slots **[INF]**, decor later).
Panel (1100 × 760): six tier rows in a vertical ladder: Savannah (current) → Forest → Arctic → Mystic → Genesis → LunaLanding, each with a thumbnail of the ground style, Stone cost (40,000 / 100,000 / 180,000 / 500,000 / 1,000,000; cumulative total shown small), and what it adds (Arctic adds the Mastery hall, Genesis adds the Gallery; other adds **[INF]**: preset slots 3→6→9, decor rarity cap). Current Stone balance and "Needs n more".
**L1 ships tier 1 only:** the Upgrade button is disabled on every row with "Not in this build" (not a lock icon alone); show all future tiers and their prices, locked, readable. Later state: button enabled when Stone ≥ cost, confirm modal ("Spend 40,000 Stone? This cannot be undone"), success toast. Land Stone comes from Echo Box, Pass and daily rewards only; never sold.
**States:** can afford (next build), cannot afford, max tier, loading, offline. **Return:** Land.

### Shared components to deliver once (on a style-sheet addendum)

Panel shell + header + Back · currency chip (Shard / Stone / Gem) with "+" where it applies · price button (normal / hover / pressed / disabled-with-reason / owned) in orange (USD or Shard), violet (Gem) · confirm modal (600) · toast · error banner · loading skeleton · lock plate · "Season 2" ribbon · rarity chip with word · date line · tab bar · segmented control · toggle with On/Off text · badge set (FREE, CLAIM, NEW, VIP, dot) · scrollbar.

## B. Round 2 addendum (run flow, Aid, Ascension)

I checked `ui-redesign-request-02.md` §4, §5, §7 against the Round 1 README and the Ascension v2 delivery. They are specified well enough for: the map sequence, fog (rows 2+ ahead, elites included), the shared Reward/Shop/Event/Treasure frame, the Aid price table with caps, the Ascension picker, the Eternal sticker, the weaken warning, the pact screen, shop price method, 2-card reward and the locked 8th slot. **Please also cover these gaps in Round 2 (they are not specified anywhere):**
1. **Boss intro and boss defeat.** There is a "boss intro" where Delay clock is offered, and a pact screen after a boss. Place both in the sequence: map → boss intro (clock line, Delay clock offer) → fight → victory → pact screen (A6 first boss / A10 every boss, Swap pact offer) → reward → map. Also draw the act-end / run-end transition.
2. **Starting Boon pick** (1 of 3 small Boons) and the Kit/Boon strip as a component. It is hosted in M1 Run Setup (Round 3); draw it here once. Boon names are placeholders.
3. **Newcomer state in a run** (first 5 runs): no Aid button, no attrition card, no light clock tab, no paid offers; do not draw a dead Aid button. Mission runs: no Aid button either, and a "No Aid in this mission" chip.
4. **In-run menu** (the Menu button in the combat HUD): Resume, Settings (M11 subset), Codex, **Abandon run** with a warning ("Aid you used is not refunded", for a mission "You lose your stake"), same-size Cancel. Not drawn anywhere yet.
5. **Connection states during a run** (dice are rolled by the server in L1): "Rolling…" under 1 s with no layout change, "Reconnecting…" banner (the run is kept, input paused, not counted as abandoned), "Offline — cannot continue" with Try again / Back to Land. Mission runs show the same and "Your stake is safe".
6. **Run result for a loss** (after End run on the defeat screen) and for a mission run (links to M6 result). The win result exists; the loss version is missing.
7. **Fog vs A9 elites.** Rows 2+ ahead hide node types including elites, but A9 promises "+2 elites visible before you path" and the node previews (A2 escort, A5 Eternal, weaken) only work on visible nodes. **[INF]** proposal: the map legend shows "Elites on this map: n (A9 +2)" as a count, positions stay fogged. Draw it and mark it [INF]; Liam decides.
8. **Relic detail card** (hover/focus on a relic chip: name, rarity, passive/active, text, Eternal sticker, sell value, tags). Needed because there are 133 relics.
9. **First-run tutorial coach-marks** (existing tutorial scene): one coach-mark component (plate + arrow + Next / Skip). Optional.
10. **Light clock at A0:** Ascension v2 hides the badge at A0 but R1 draws the light clock tab at A0–A3. Keep the clock tab; keep the badge hidden at A0 and say so.

## C. Review leftovers in Round 1 (please fix with this delivery)
1. `Dice UI R1 README.md` §2 still says shortcut **key hint 11** and locked shortcuts "**opacity .8**". Both contradict the corrected text floor: key hints are 12 px, and locked shortcuts must not drop to 80% opacity (use fill `#E8D6B4`, border `#9A7650`, ink `#6E4A30`).
1b. The Land Hub Pass plate and README §2 still say "Season 1 · ends 30 Nov 2026". Change to "ends 29 Dec 2026". Also redraw the top bar once with the new Daily gift chip (M8) so it is shown to fit.
2. The Style Sheet page still has 11 px text that the README does not list as decorative-only. Raise each to 12 px or list it explicitly in the README's decorative-only line.

## E. Decisions from our side (12 Oct)
- L1: gift Gem buys everything priced in Gem (bundles, cosmetics, Aid); only USD purchases are disabled.
- Daily: 3 tries per UTC day, same seed for everyone. Ranked allows Kit/Boon.
- Store cosmetic prices stay placeholders (90/180/360/720 Gem) for now.
- Daily chip on the top bar, new shortcut keys (C, P, D, B, L, Esc = Settings), Leaderboard opened from Run Setup and Profile: accepted.
- Fogged map at A9: show the count as text, e.g. "2 elites hidden on this map" (Ascension rules must stay visible).
- Newcomer runs (first 5): no Aid button at all; the free sample Continue still appears on the defeat screen.

## D. Delivery

Per `ui-redesign-request-02.md` §8: HTML mockups at 1920×1080 (plus one taller window, 1920×1240, for M1, M5, M6, M7), a normative README with exact numbers per element and [OBS]/[INF] tags, a contact sheet PNG of all states, new icons (dark outline, ≤ 128 px, transparent) listed by name, and a table "screen × state" showing which frames exist.
Frames: M1 (A0, A6, A10, locked level, unfinished run, newcomer, Daily, Ranked locked, L1) · M2 (empty, filled, locked slot) · M3 (empty, found, full, errors) · M4 (empty, claimable, mid-season, season over, premium "Season 2") · M5 (regular idle/open/result/Open 10/summary, seasonal idle/confirm/result, rates, no tickets, cap, offline) · M6 (board, locked N5/N6, confirm, win, lose, cancelled, newcomer) · M7 (all five tabs, L1 playtest, purchase flow, spending limit) · M8 · M9 · M10 · M11 · M12 · M13 (all five modals + errors) · M14 · M15 (L1 and later). Reduce-flashing variants.
**Acceptance:** one visual language with R1; every state above present; no screen without a way back; every price shows currency, cap and a same-size decline; no countdown; no seasonal item with a price; Mythic rules kept; 12 px floor; keyboard focus drawn.

---

# Ghi chú cho Liam (tiếng Việt, không gửi)

## File đính kèm Liam cần tải lên cùng prompt
- `design/requests/ui-redesign-request-02.md` (brief gốc, Round 3 tham chiếu §0 và §8 của nó; nếu chat Claude Design đã có file này thì không cần gửi lại).
- `Dice UI R1 README.md` (bản sửa), `Dice UI R1 - Style Sheet.dc.html`, `Dice UI R1 - Land Hub.dc.html` (cho vị trí nhà/thanh phím tắt/Moon Card).
- `Ascension Meta v2.dc.html`, `Ascension v2 README.md` (chỉ để lấy nội dung picker; nói rõ phải vẽ lại theo Homeland).
- Rương: `godot/assets/echobox/chests/tiers/*.png` (6 file) và `chests/themed/*.png` **trừ `slp-chest.png`, `axs-chest.png`**.
- Cosmetics 01 (plate, khung) để vẽ trang Cosmetics/Pass/Echo Box.
- Icon hiện có: `godot/assets/icons/web/`, `icons/node/`, `hl/icons/` (spike, attrition, lethal, aid, gift…), `asc/new-icons/` (boss-clock, eternal, pact, drawback, lock).
- Render Homeland của các nhà (Weaponsmith, Alchemy, EquipmentStall, GemStorage, Jeweler, Portal, House) để làm thumbnail đầu panel.
- Ảnh chụp các màn Godot hiện tại cần giữ nội dung: Vault, Settings, Codex (10 tab), Guides, Account (chỉ để đọc nội dung, không bắt chước giao diện).
- Không gửi `meta-screens-v2.html`, `combat-v2.html`, `docs/design-handoff-v2/FOR-CLAUDE-DESIGN.md`.

## Danh sách màn trong brief
M1 Run Setup · M2 Đội lưu sẵn · M3 Vault · M4 Season Pass · M5 Echo Box (2 tab) · M6 Nhiệm vụ · M7 Store (5 tab) · M8 Daily/Gem tặng · M9 Leaderboard · M10 Codex/Guides · M11 Settings · M12 Profile · M13 Đăng nhập desktop · M14 Cosmetics · M15 Nâng Land · quy tắc badge/thông báo + bộ component chung. Phụ lục Round 2 (10 mục thiếu) và 2 lỗi nhỏ còn lại của R1.

## Chỗ tôi tự suy ([INF] trong brief)
Phím tắt mới (C, P, D, B, L, Esc = Settings); chip Daily trên thanh trên; Leaderboard mở từ M1/Profile; Daily tối đa 3 lần/ngày; Ranked có Kit/Boon; ánh xạ rương bậc theo phần thưởng (Stone 100/250 → đồng …); rương chủ đề `mystic` cho Series 1; giá cosmetic Store là số tạm (90/180/360/720 Gem); số rương preset 3/6/9; số trần chi tiêu 100/250/500 USD; lợi ích các tier Land ngoài Mastery/Gallery; ngày mùa 29/12/2026 và 26/1/2027 (3/11 + 8 và 12 tuần), bỏ 30/11; tên 8 Boon (chưa viết); tab/ranh giới Profile–Cosmetics; điều kiện phụ Nhiệm vụ; fog vs A9 elite (đếm elite trên bản đồ).

## Câu hỏi cho Liam

Đã trả lời hết 12/10, ghi ở mục E của brief.
