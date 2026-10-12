# UI request 02 — Axie Dice visual redesign (hub, combat, run flow, meta)

Soạn 12/10/2026 từ: ý của Liam (`design/ux/ui-direction-liam-draft.md`), nghiên cứu đã qua review
(`design/ux/ui-direction-research.md`), 8 câu Liam trả lời 12/10. Gộp và thay thế `ascension-ui-request-01.md`.
Liam dán phần tiếng Anh dưới đây vào Claude Design, kèm file đính kèm ở cuối.

---

**From:** Axie Dice dev (Liam) · **To:** Claude Design · **Date:** 2026-10-12
**Status:** ready to hand over. This brief is the single normative document for this request. It **replaces**
UI request 01 (Ascension screens); those items are folded into §7 below.

## 0. What this is

Axie Dice is a turn-based dice-combat roguelike. A run is a map of nodes (combat, elite, boss, shop, event,
treasure). The player brings **5 Axies**; each Axie has a die whose faces come from its body parts. Each
turn the player rolls, picks a die face, then picks a target. Between runs the player lives in a **3D Land**
(their home base); its houses are the entrances to every meta feature.

The current UI is not good enough and we are redoing the visual direction **before** building many new screens.
- **Menu / meta screens: redraw from scratch.** Do not reuse the look of `meta-screens-v2.html` at all.
- **Combat and run flow: redraw for a 3D presentation.** `combat-v2.html` may be read only for *what information
  the screen must carry*. `run-flow-v2.html` may be reused as a base for the *contents* of the reward / shop /
  event / treasure / result panels, but the frame, scene and look are new and must follow your style sheet.

Platform: **Windows + macOS desktop**, mouse + keyboard. Design canvas **1920 × 1080 as the minimum**; the
game uses "expand" stretch, so taller windows add vertical space. Anchor bars to screen edges and express
positions as relationships ("16 px above the tray"), not absolute y values. Sizes, paddings, radii, font sizes
and colours are exact numbers. Button heights are fixed numbers (Godot buttons have no line-height control).
Where you write "every", name the full set. Ship specs and HTML mockups; any code is labelled UNTESTED. Mobile comes later; do not design
for it now, but avoid anything that obviously cannot shrink.

## 1. Visual direction (decided)

- **Style: Sky Mavis Homeland.** Soft gradients, warm red-brown linework, friendly rounded shapes, cream and
  warm wood/stone materials, like the Homeland renders attached. The cosmetics set you delivered in
  Cosmetics 01 already uses this language; the UI should feel like the same world.
- **Bold dark outline at small sizes.** Anything that must read at small size (chips, icons, numbers, dice
  faces, status badges) gets a strong dark outline so it reads over a busy 3D scene.
- **Combat HUD is minimal.** The 3D scene is the star. HUD lives at the screen edges, never floats over the
  middle of the scene except for the few items listed in §3.
- **Readability rules that stay from the old system:** text on a coloured fill uses dark ink unless the fill is
  dark; never white text on a mid-tone colour. A colour never stands alone for a mechanic: every status,
  intent and face type carries its glyph. Baloo 2 for titles, labels and every numeral; Work Sans for prose.
  Rarity colours: Common `#C6CEDA`, Uncommon `#40CC3D`, Rare `#33B8FF`, Epic `#BF6BFF`, Legendary `#FF9445`,
  Mythic `#FF3D6E` (chips/borders/tier names/frames only, dark ink on it, never white; never for numbers, HP
  bars, intent or damage text; its night field is `#2A0F2E`, use a near-black border at small size).
- **Look anchors** (so every screen reads as one world): sample the palette from the attached Homeland renders and
  Cosmetics 01 and list the sampled hexes on the style sheet; one light direction (top-left) and one soft contact
  shadow style everywhere; scene/illustration linework is warm red-brown, small UI elements get the bold dark
  outline above; rounded plates, no sci-fi glass, no neon, no grunge, no pure white. Must be buildable in Godot
  (nine-slice plates, gradients as textures); the only blur is the Land behind meta panels.
- **Radical transparency.** The player always sees what each enemy will do next and every rule affecting
  them. No design may hide information.
- **3D characters are live in the game.** Wherever an Axie or monster appears, draw a labelled placeholder
  ("Axie 3D", "Atia monster 3D", "Boss 3D") at the right size and position. Do not draw the creatures.

Start the delivery with a **one-page style sheet**: palette (UI surfaces, ink, accents, rarity), type scale,
outline weights, button states (normal / hover / pressed / disabled / owned), panel and chip styles, icon
style. Every screen after it must use only what is on that sheet.

## 2. Land hub (replaces the main menu)

- The game opens on the player's **Land**: a 3D diorama seen from a **fixed camera** (no walking). Axies
  wander around it (placeholders).
- **Each house is a big clickable entrance** with a name label and an optional badge. Houses:
  | House | Opens |
  |---|---|
  | **Portal** (Homeland `SM_Portal_01`), **centre of the Land** | **Run** — this is the main action and the biggest target on screen. "Going through the portal = going into a run" means the same thing here and in combat |
  | House | Saved team presets (parties of 5). Clicking the **Portal** opens the Run Setup panel: party, mode (normal / **Daily** / **Ranked**), short/full, Ascension, Kit/Boon |
  | Mission house | Nhiệm vụ (hard staked missions) |
  | Echo Box house | Echo Box (loot boxes: regular + seasonal) |
  | Pass stall | Season Pass |
  | Vault warehouse | Vault (import and manage Axies) |
  | Store | Store (Lunar Gem, VIP, bundles, cosmetics) — house model to be chosen, propose one from the renders |
  | Mastery hall, Gallery | later phases — show as locked/under construction |
- **Shortcut bar**: a slim bar at a screen edge with the same entries as the houses, plus Settings, Codex/Guides,
  Profile, currencies (Gene Shard, Land Stone, Lunar Gem). Keyboard reachable.
- Badges: "new item", "reward to claim", "free box ready". Season end shown **as a date**, never as a ticking
  countdown.
- **VIP (Moon Card) offer:** a **popup on the second day's login** plus a badge on the Store house. Design the
  popup: clear price (4.99 USD = 420 Gem), what you get (30 days; 20 Gem/day claimed manually, no stacking;
  1 ticket/day; 1 Boon/day; Continue once per run at -25%; no Shard/Stone boost), a close button the same size
  as the buy button, no countdown, shown at most once per day. Never shown on the defeat screen.
- Land tiers change the look of the ground (Savannah → Forest → Arctic → Mystic → Genesis → LunaLanding); show
  the hub on Savannah and one higher tier. Houses appear by tier: Savannah already has Portal, House, Mission house, Echo Box,
  **Pass stall, Vault** and Store (new players must see the free Pass); Arctic adds Mastery hall; Genesis adds Gallery. A not-yet-built house is an
  empty plot / construction site, not a hidden entry. The hub must stay readable as a static image (web fallback).
- Run needs a visible state when the player has an unfinished run (continue vs new).

## 3. Combat screen

Layout (decided by Liam):
- **Full 3D.** The 5 Axies stand in the **lower half**, **backs to the camera**. Monsters / boss in the
  **upper half**, **facing the camera**. The arena is an open, wide, airy outdoor space built from the Homeland
  kit of the current biome (one arena per biome).
- **Dice tray at the bottom edge**, 5 columns, each column aligned under its Axie. A column holds that Axie's
  **die**, **HP bar** and **status chips**. This is the main HP readout for the party.
- **Party HP lives only in the tray.** No floating bars over the Axies' heads. Rule: no party UI element may ever
  overlap a monster, its nameplate or its intent.
- Everything in the tray and on nameplates is anchored to screen edges; environment props must never hide intent
  or HP. Keyboard focus order: Axie column, then die, then target.
- Enemy nameplates above/below each monster: name, HP bar, status chips, **intent badge** (what it will do next
  and the number). Boss HP bar shows **phase marks at 66% and 33%**.

Must be visible (each one is a game rule that cannot ship without it):
- **Boss enrage clock** on the boss nameplate: before enrage "Enrage in N"; after, the stack level (escalating,
  up to 5) and the bonus folded into the boss intent number. First-pass numbers (will be tuned): light version
  from A0 starts turn 14, +10% per turn, max 3 stacks; full version from A4 starts turn 10 (turn 8 from A9),
  +20% per turn, max +100%. Design for any start turn 1–20.
- **Spike counter** on monsters that have a scheduled big hit: "Big hit in N", the big hit's number shown.
- **Attrition counter** in a corner of the arena: from turn 6 every enemy deals +5% per turn, max +25%.
- **One combined damage number** per enemy for next turn (enrage + attrition + spike already folded in). Never
  make the player add numbers.
- **Damage preview** when a die is dragged / hovered over a target, and a "will die" mark when it is lethal.
- Relic bar (8 passive + 3 active slots, so A8 can lock the 8th), rerolls left, END TURN, Ascension badge (e.g. "A6", opens the rule list).
- **Aid tray** (paid in-run help, §5) in its own spot **far from END TURN** so it can never be mis-clicked.
- Interaction feedback: selected die lifts with a glow, legal targets light up, illegal ones dim **with a reason**
  (not only by colour).
- Resolve feedback (numbers flying up, counters ticking, short hit-stop) with a skip / fast-forward control.
- Reduce-flashing variant for anything that pulses.

States to draw: player turn (nothing selected), die selected with targets, hover on a lethal target, enemy turn,
boss enraged at max stacks, Aid tray open, victory moment, **defeat screen** (see §5).

## 4. Run flow

Decided sequence after a won fight:
1. **Pick the reward right there on the now-empty arena** (party still standing in the scene, reward panel on
   top).
2. **Run map**: a **3D diorama / tabletop map** of the act (nodes as small 3D props on a path, the party token on
   its node). Node types: battle, elite, boss, event, shop, treasure (existing icons; no rest node exists). The row
   the player can choose from is always fully shown; the visited path is always visible; nodes 2+ rows ahead are
   **fogged** (edges visible, type shown as "?"), **elites included**; the **act boss is always visible**. A paid
   Scout reveals node types for the next 3 rows (§5).
   Include a legend, HP / currency top bar and the Ascension badge.
3. Player picks the next node.
4. The Axies **run straight through where the enemies stood, the Portal opens, they run in**, a **flash**, and the
   next scene opens with the party already in place. (Camera does not follow; it is a cut on the flash.)

**One shared frame** for Reward, Shop, Event and Treasure: the party in the current arena + a panel. Only
the panel changes. Design the panel for each: reward (3 cards; 2 at A7+), shop (relics, refresh; prices in Gene
Shard), event (text + 2–3 choices with their cost shown), treasure. Plus the **run result** screen (win) with run
stats, an "Aid used" line and a small "Pure" mark when no Aid was used. (A Rest panel is not in scope: the game
has no rest node.)

## 5. Paid in-run help ("Aid") and the defeat screen

The game is hard on purpose and sells in-run help for real money (Lunar Gem). Trust rules are non-negotiable:
prices and caps always visible, no countdown pressure, the decline button is the same size as the buy button,
first purchase each session asks for confirmation (Gem price with approx. USD, about 90 Gem per USD), an option
to hide suggestions (in Settings). Each offer is made once per moment. Max 6 Aid uses per run (4 from Ascension 9),
at most 1 Boon per run from any source and it counts toward the cap; draw the counter as "N of cap". New accounts see no
paid offers for their first runs (5 is the working number).

| Aid | Price (Gem, first pass) | Cap | When it is offered |
|---|---|---|---|
| Continue (Second Wind) — party revives at 40% HP (25% from Ascension 6), the button shows the boss HP left and the heal amount, enemies keep HP and phase and spike counter; enrage and attrition reset | 90 (boss fight 180; VIP -25%) | 1/run | Defeat screen |
| Extra reroll (+1 this turn) | 15 | 4/run, 2/fight (1/fight from Ascension 3) | When rerolls hit 0 |
| Delay boss clock (+2 turns) | 60 | 1/boss | When enrage is 2 turns or less away, and boss intro |
| Swap pact (reroll one forced pact offer) | 15 | 1/pact | Forced pact screen |
| Shop refresh | 18 | 2/run | Shop |
| Scout (reveal types of the next 3 rows) | 12 | 3/run | Run map |
| Starting Boon / Run Kit | 38 / 60 | 1 Boon/run from any source, counts toward the cap | Run setup |

Variants to draw: a free sample Continue (once per account, A0–A2, first loss at an elite or boss; labelled as a
gift), and the VIP-discounted Continue.

**Defeat screen:** a recap first (which turn the party fell, which hit killed whom, how much HP the boss had
left), then Continue with its price and the remaining Aid count, and a same-size "End run" button. No VIP offer
on this screen.

## 6. Meta screens inside the houses (redraw from scratch)

Each opens from its house as a panel over the blurred Land, with a clear way back:
Team Select / Run Setup (party of 5, short/full, Ascension picker — see §7), Vault, Season Pass (free track from
season 1; premium track exists from season 2 — design both, mark premium as "Season 2"), Echo Box (regular box +
seasonal box with set progress and pity shown), Nhiệm vụ (stake tiers, difficulty, reward, time), Store (6 Gem
tiers 0.99 / 4.99 / 9.99 / 19.99 / 49.99 / 99.99 USD, first-purchase Starter Pack, VIP Moon Card, ticket
bundles of 6/15/40/100, cosmetics at fixed price; **seasonal items are NOT sold directly — only obtainable from the seasonal Echo Box**;
no loot box sold directly: Echo Box is opened with tickets). Next to the Aid price list (Store and Codex) show this line plainly: "Aid makes you stronger
for one run. Players who buy more can win more. The Pure leaderboard only counts runs without Aid.", Codex/Guides, Settings (incl. hide Aid suggestions and a self-set spending limit),
Profile.

## 7. Ascension (folded in from request 01)

Ascension 0–10, cumulative rules: A1 shop ×1.15 and relic sell 40%; A2 elites bring +1 monster; A3 base rerolls
2 → 1; A4 full boss clock; A5 relics from elites carry an **Eternal** sticker (cannot be sold, max 2) and the
Axie that starts a fight weakened is **announced before** the fight; A6 first boss forces a pact; A7 reward shows
2 cards; A8 passive relic slots 8 → 7; A9 +2 elites and a faster boss clock; A10 every boss forces a pact and the
reward reroll is gone. Draw:
1. Ascension picker in Run Setup: level 0–10 (locked levels visible but disabled), list of all active rules with
   icons, the new rule highlighted ("NEW at A6"), cosmetic titles at A5 and A10 as goals. Variants A0, A6, A10, a
   locked level.
2. In-run Ascension badge (combat + run map) opening the same list read-only.
3. Eternal sticker: on the reward card before picking, on relic chips, in the sell flow (sell disabled with the
   reason), and when the 2-Eternal limit is reached.
4. Weaken warning on the selected map node and on the fight intro; weaken chip from turn 1.
5. Forced pact screen: 3 pact cards (name, effect, drawback in a distinct colour, slot it takes), the "pact
   required — Ascension 6" variant, and the Swap pact Aid.
6. Shop prices showing the +15% honestly (one method, used everywhere) and sell value 40% vs 50%.
7. 2-card reward layout (no empty slot), reroll button absent at A10, 8th relic slot locked at A8 with the reason.

## 8. Delivery (in three rounds, in this order)

1. **Round 1:** style sheet (§1) + Land hub incl. VIP popup (§2) + combat screen with all states, including the
   Aid tray and its in-fight offers (§3) + defeat screen with Continue (§5).
2. **Round 2:** run flow (§4) incl. the 3D map and the shared panel frame, remaining Aid offers (Scout, shop
   refresh, Swap pact, Kit/Boon strip), Ascension items (§7) with the Ascension picker as a component.
3. **Round 3:** meta screens (§6), including the full Run Setup screen that hosts the picker.

Each round: HTML mockups at 1920×1080 (plus one taller window, e.g. 1920×1240, for the hub and combat), a
normative `README.md` with exact numbers for every element and which statements are OBSERVED from the attached
files vs INFERRED, a contact sheet PNG of all states, and any new icons as PNG/SVG (dark outline, ≤ 128 px,
transparent) listed by name.

## 9. Acceptance

- Same visual language across hub, combat, run flow and meta; matches the Homeland renders.
- Every rule and threat (intent, enrage, spike, attrition, Ascension rules) is visible before it affects the player.
- Party HP is readable in the tray; no party UI overlaps enemies.
- The Aid tray cannot be mis-clicked for END TURN; every offer shows price and remaining cap.
- No clipping at 1920×1080; correct at the taller window too.
- Reduce-flashing variants for every animated element.

---

## File đính kèm (Liam tải lên cùng prompt)
- Render Homeland để lấy style: `asset-library/design-library/` (xem `INDEX.md`, chọn ~10 ảnh: nhà, decor, môi trường)
  và contact sheet `asset-library/godot-ready/contact_sheets/HomeLand_Asset_Environment_{Savannah,Forest,Arctic,Mystic,Genesis,LunaLanding}_1.png`
  + `HomeLand_Asset_Building_HomeLand_{Portal,House,SpyQuarter,Alchemy,EquipmentStall,GreenWarehouse,Weaponsmith,ConsumableStall}_1.png`.
- Bộ cosmetics Cosmetics 01 Claude Design đã giao (để UI cùng một ngôn ngữ).
- Icon hiện có: `godot/assets/icons/web/`, `godot/assets/icons/node/`, chân dung class `godot/assets/portraits/`.
- (Tuỳ chọn) ảnh chụp màn hình game Liam thích UI.
- Mockup v2 cũ: chỉ gửi `run-flow-v2.html` nếu muốn dùng lại nội dung panel (anh đã cho phép); không gửi combat-v2 và meta-screens-v2.

## Quyết định Liam (12/10) cho brief này (không gửi)
- Portal mở Run Setup; Daily và Ranked chọn trong màn đó. House = đội hình lưu sẵn.
- Pass và Vault có ngay từ đầu (Savannah).
- Map che loại node kể cả elite; boss cuối act luôn hiện; Scout lộ 3 hàng.
- Style mới (Homeland: gradient mềm, nét nâu đỏ, viền đậm ở cỡ nhỏ) **thay** luật UI cũ. Có mockup rồi sửa `godot/CLAUDE.md`.
- Máu Axie chỉ ở khay đáy; luật: UI của đội không bao giờ đè lên quái.
- VIP: popup ngày 2 + badge, tối đa 1 lần/ngày, nút đóng cùng cỡ, không đếm ngược, không ở màn thua.
- Đồ mùa chỉ ra từ hộp mùa (gacha), không bán thẳng (bỏ T6).
- Không có node Rest; shop chỉ relic + làm mới. Trần Aid vẽ dạng "đã dùng / trần" (số chốt ở monetization: 6, A9–A10 là 4).
- Store chưa có model nhà: để Claude Design đề xuất từ render (ví dụ `ConsumableStall`).
- Không gửi kèm `docs/design-handoff-v2/FOR-CLAUDE-DESIGN.md` (còn ghi `aspect="keep"` cũ).
