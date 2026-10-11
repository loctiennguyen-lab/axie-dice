# UI request 01 — Ascension v2 screens and indicators

**From:** Axie Dice dev (Liam) · **To:** Claude Design · **Date:** 2026-10-11
**Status:** ready to hand over. This file is the single normative brief for this request.

Read `docs/design-handoff-v2/FOR-CLAUDE-DESIGN.md` first — it is the contract for how a delivery
lands in this codebase (exact numbers, specs not code, one normative document, OBSERVED vs
INFERRED). Extend the existing v2 mockups; do not restyle them:

| Mockup (in `docs/design-handoff-v2/mockups-v2/`) | Screens it owns |
|---|---|
| `combat-v2.html` | Combat: top bar, enemy nameplates + intent badge, status chips, deck, relic actives |
| `run-flow-v2.html` | Run Map, Reward, Shop, Event, Treasure, Result |
| `meta-screens-v2.html` | Main Menu, Team Select / Run Setup (has the ASCENSION picker), Vault, Pass, Unlocks, Guides, Codex |

Platform: **Windows + macOS desktop, 1920 × 1080 canvas**, mouse + keyboard (touch comes later).

---

## 1. What changed in the game (why these screens are needed)

Ascension (difficulty levels 0–10, unlocked by winning at your current top level) used to only
multiply enemy HP/damage. It now adds a **new rule per level**, cumulative. Source of truth:
`design/proposals/ascension-v2.md` (its top block holds Liam's decisions). The rules:

| Level | Name | New rule (cumulative) |
|---|---|---|
| A1 | Lean Pack | Shop prices ×1.15; selling a relic refunds 40% instead of 50% |
| A2 | Elite Escort | Every elite fight brings one extra monster |
| A3 | Short Dice | Base rerolls per turn 2 → 1 (relic bonuses still add on top) |
| A4 | Boss Clock | From turn 10 a boss **enrages**: +20% damage per turn, max +100%. A visible counter on the boss |
| A5 | Eternal Gift | Relics taken from an **elite** reward carry an **Eternal** sticker: cannot be sold (max 2 Eternal relics). The Axie that starts a fight weakened is **announced before** the fight |
| A6 | First Pact | At the first boss the player **must** take one of the 3 pacts (no skip) |
| A7 | Narrow Offer | Reward screens show 2 cards instead of 3 |
| A8 | Cramped Pack | Passive relic slots 8 → 7 |
| A9 | Hunted | +2 elites on the map; the boss clock starts at turn 8 |
| A10 | Last Stand | Every boss forces a pact; the reward reroll button is gone |

Game pillar that constrains every screen: **radical transparency** — the player always sees what an
enemy will do (intent badge) and every rule affecting them. Nothing here may hide information.

## 2. Assets you may use (send nothing new unless listed as NEW)

Ask Liam for these files; reference them by path so the implementation can use the same asset.
- Status / mechanic icons: `godot/assets/icons/web/` — weaken, stun, vuln, undying, burn, thorns,
  freeze, regen, blind, poison, shield, heal, dmg, mana, buff, debuff, reroll, shard, boss, elite,
  battle, chest, shop, event, summon, settings.
- Node icons: `godot/assets/icons/node/` (battle, boss, elite, event, merchant, treasure).
- Class portraits: `godot/assets/portraits/` (aqua, beast, bird, bug, plant, reptile).
- Backgrounds: `godot/assets/backgrounds/origins/scene/`.
- Homeland/Atia renders for decoration only: `asset-library/design-library/` (see its `INDEX.md`).
- **Axies and monsters are live 3D in the game.** Where a screen shows an Axie or a monster, leave a
  frame labelled "Axie 3D" / "Atia monster 3D" — do not draw them. Enemies are moving to Atia 3D
  monsters, so do not rely on the old Chimera sprites.
- Fonts and tokens: Baloo 2 (numerals, labels), Work Sans (prose), `DangoTheme` colours as in the
  v2 mockups; pure-black outlines; hard shelf shadows, no blur.

## 3. Screens and states to design (8 items)

For each item: the default state, every listed variant, exact sizes/positions on the 1920×1080
canvas, and where it sits relative to existing v2 elements (quote the mockup element it attaches to).

### 3.1 Ascension panel in Run Setup (`meta-screens-v2.html`, ASCENSION picker)
- Level picker 0–10 (locked levels above the player's max visible but disabled).
- **Rule list**: every active rule up to the selected level, each with an icon and one line; the
  rule added by the selected level is highlighted ("NEW at A6").
- Ladder rewards: cosmetic titles at **A5** and **A10** shown as goals (earned / not yet).
- Variants: A0 (no rules — say so plainly), A6, A10, a level the player has not unlocked.

### 3.2 Ascension indicator during a run
- A compact badge (e.g., "A6") in the combat top bar and on the Run Map rail; hover/click opens the
  same rule list as 3.1 (read-only).
- Variants: A0 (badge hidden or neutral — choose and justify), A10.

### 3.3 Boss Clock (A4, A9) on the boss nameplate (`combat-v2.html`, enemy nameplate 176 wide)
- Before enrage: turns remaining ("Enrage in 3").
- Enraged: stack level 1–5 (+20% … +100%), clearly escalating; the current damage bonus must also be
  reflected in the boss **intent value** (show how).
- The boss clock starts at turn 10 (A4–A8) or turn 8 (A9–A10) — design must work for both.
- Must not push the status chip strip (28 px fixed height) or the intent badge out of place.
- Reduce-flashing variant (no pulsing/strobe; static escalation).

### 3.4 Eternal sticker (A5+)
- On a relic **reward card** from an elite (before picking — the player must know it will be Eternal).
- On the relic chip in the combat top bar and anywhere relics are listed.
- In the sell flow: the sell action is disabled with a reason ("Eternal — cannot be sold").
- Limit reached (2 Eternal relics): how the third elite reward communicates it.

### 3.5 Weaken pre-warning (A5+)
- Before a fight starts, the Axie that will begin weakened is announced: on the Run Map when the node
  is selected, and on the fight intro. Use the existing `weaken` icon.
- In the fight, its nameplate shows the weaken chip from turn 1 (existing status chip style).

### 3.6 Forced pact (A6 first boss, A10 every boss)
- The boss reward offers 3 **pacts** (relics with a drawback on dice / reroll / mana — see
  `design/proposals/relic-set-v2.md` §2.5). Normally the player may skip all three; on these levels
  the skip is removed and the screen says why ("Ascension 6 — a pact is required").
- If the full pact screen does not exist yet in the v2 mockups, design it once here (3 pact cards:
  name, effect, drawback in a distinct colour, slot it takes) and the forced variant.

### 3.7 Shop and sell modifiers (A1+)
- Price tags show the ×1.15 modifier honestly (e.g., original price struck through + new price, or a
  small "A1 +15%" tag — choose one, apply to every price on the screen).
- Sell value shows 40% (A1+) vs 50% (A0).

### 3.8 Reward screen variants (A7, A10) and slot cap (A8)
- 2-card reward layout (A7+) — re-flow the existing 3-card layout, do not leave an empty slot.
- Reward reroll button: absent at A10 (and greyed with reason if a relic grants rerolls).
- Relic slots: 7 of 8 available at A8+ — show the 8th slot locked with the reason.

## 4. Deliverables

1. Updated mockup HTML for the three files above (or new HTML files that clearly extend them),
   with every variant in §3 visible.
2. One normative `README.md` listing each item (3.1–3.8) with exact numbers, the states, and what is
   OBSERVED vs INFERRED about the current build.
3. A contact sheet (PNG) of all states.
4. List of any NEW icons you had to draw (e.g., Eternal sticker, boss clock, pact drawback) with
   PNG/SVG files: black outline, flat fill, ≤ 128 px, transparent.

## 5. Acceptance

- Every rule A1–A10 is visible to the player somewhere before it affects them.
- Nothing hides enemy intent; the boss intent shows the enrage bonus.
- Works at the 1920×1080 canvas without clipping; fits the existing 176-wide nameplate and 28 px
  status strip.
- Reduce-flashing variants for 3.3 and any animated element.
- Uses only the assets in §2 plus the NEW icons you list.

## 6. Known dependencies (say if you disagree)

- The relic slot / sell / pact screens are part of the relic redesign that Liam is still reviewing
  (`design/proposals/relic-set-v2.md`). Design the Ascension variants (3.4, 3.6, 3.8) in a way that
  can sit on top of those screens; a separate relic-UI request will follow after the relic set is
  locked.
- Enrage turn numbers (10 / 8) and the +20% step are first-pass and will be tuned by simulation;
  design for any value 1–20 turns and 1–5 stacks.
