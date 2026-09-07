# Echo Box "Double Gacha" — Chest-Roll UX Spec

Status: draft, reconstructed 2026-09-07 (previous pass was chat-only, not
written to file). Ready for PM/product-owner review.

Author: ux-designer
Scope: UX/interaction/copy only. No currency, cost, or Shard-economy change —
`ECHO_FUSE_COST`, `echoCost()` growth, and the dup→fuse mechanic are untouched
and out of scope (owned by `economy-designer`). No CSS/visual-style decisions
made here beyond naming existing rarity/tier conventions — final color/glow
per chest grade is `art-director`'s call.

## 0. Source references (traceability)

- `scEchoBox()` — `src/client.html:3053`
- `echoBoxOpen()` / `rollEchoRarity()` — `src/client.html:2342-2390`
- `ECHO_BOX_RARITY_ODDS`, `ECHO_BOX_CATEGORIES`, `ECHO_FUSE_COST` — `src/cosmetics.js:76-85`
- `ECHO`, `ECHO_TIER_NAMES`, `ECHO_TITLES` — `src/data.js:847-852`
- `RARITY` (Common/Rare/Epic/Legendary/Mythic labels) — `src/data.js:13`
- Chest art (6 files, already delivered): `chest_bronze.png`, `chest_silver.png`,
  `chest_gold.png`, `chest_platinum.png`, `chest_diamond.png`, `chest_lunacian.png`
- Existing "Tier" UI copy that collides with the new system, confirmed still
  present as of this pass: `client.html:2946` (`'Echo Tier: '+ECHO_TIER_NAMES[...]`,
  profile screen) and `client.html:3066` (`Tier: ${tierName} · ${inTier}/${ECHO.tierSize}
  to next tier`, `scEchoBox()` header)

## 1. What this changes

Today, `OPEN BOX` spends Shard and immediately resolves one cosmetic pull via
`rollEchoRarity()` (flat `ECHO_BOX_RARITY_ODDS`). This spec inserts one new RNG
step **before** that reveal: which of 6 chest grades (Bronze → Lunacian) the
player rolled. The chest grade then re-weights (and, for the top 4 grades,
floors) the rarity odds of the cosmetic inside it. Same click, same cost, same
underlying dup→fuse mechanic — one extra anticipation beat and one extra
visual payoff per pull.

## 2. Naming collision — resolved

The project already has an unrelated permanent, account-level, non-random
meta-progression: `echoTier()` / `ECHO_TIER_NAMES` (Waning → Eclipse, gates
`ECHO_TITLES`), currently labeled "Tier" in two places in the UI. The new
chest grade is a per-pull, non-cumulative RNG outcome. Both happen to have 6
levels and both currently want the word "Tier" — left alone, players will
misread two unrelated meters as one progress bar.

**Decision (final, no further discussion needed):**
- The existing account system is relabeled **"Rank"** everywhere it displays
  copy: `client.html:2946` → `'Echo Rank: '+ECHO_TIER_NAMES[...]`; `client.html:3066`
  → `Rank: ${tierName} · ${inTier}/${ECHO.tierSize} to next rank`. No variable,
  function, or field renames — `echoTier()`, `ECHO_TIER_NAMES`, `ECHO_TITLES`
  stay exactly as they are in code. Display copy only.
- The new per-pull system is always labeled **"Chest"** ("Chest Grade" where
  it needs a noun) and must never appear as a bare "Tier" anywhere in new UI:
  "BRONZE CHEST", "You rolled a Gold Chest", "Chest Grade: Lunacian."
- Why this pairing and not the reverse: "Rank" already reads correctly as a
  persistent account status (military/ladder connotation — matches its
  gated-title, never-decreases behavior). "Chest" is the concrete physical
  object already sitting on screen once the player has 6 pieces of chest art
  to look at — no new vocabulary to learn, and it can never be confused with
  "Rank" because it names an object, not a level.
- This is a copy-only decision, made unilaterally per delegated authority —
  not re-opened as a question below.

## 3. Two-step reveal flow

**Step 1 — Roll Chest** (replaces the current instant reveal)
1. Player clicks `OPEN BOX` (cost deducted immediately — unchanged; `SFX.hover()`
   on focus, matching existing button).
2. A locked chest silhouette appears center-stage and does a brief shake/pulse
   anticipation loop, ~500-700ms (same tension-beat length class as existing
   `hitstop()` calls, not a new timing system).
3. Silhouette resolves into one of the 6 chest sprites, scaled in with the
   rarity-appropriate SFX split already used elsewhere in this screen (`r.rar>=3
   ? SFX.legend() : SFX.coin()` at `client.html:3076`) — apply the same split
   by chest grade (Gold/Platinum/Diamond/Lunacian = `SFX.legend()`, Bronze/Silver
   = `SFX.coin()`). All flash/hitstop-style feedback routes through the existing
   `flashScreen()`/`hitstop()`, already gated by `wantsLessFlash()` — no new
   accessibility path.
4. Big label under the chest: `"<GRADE> CHEST"` (see naming rule above) plus
   the one-line copy from §5.

**Step 2 — Open Chest**
- Default: auto-chains ~850ms after the chest lands (keeps repeat-opening fast
  for an end-game Shard sink players may click dozens of times a session).
- The chest itself is a real, focusable `<button>` (not a clickable div — keeps
  it in native tab order for keyboard/screen-reader users) that, if clicked or
  activated with Enter/Space before the auto-chain fires, opens immediately.
  This resolves the earlier open "manual vs. auto" question: default to
  low-friction auto-chain, but never block a player who wants to skip ahead —
  pure interaction-pattern call, within UX authority, no economy impact.
- Opening plays the chest-burst beat, then renders the existing `.rcard`
  result exactly as `scEchoBox()` already does today (`RARITY[r.rar]` badge,
  item name or `DUPLICATE` + fusion progress, category) — reuse, not a new
  component.
- Give the 6 chest grades their own CSS color ladder distinct from `.rcard.r0-r4`
  (6 levels vs. 5 cosmetic-rarity levels — reusing r0-r4 classes for chests
  would visually collide with cosmetic rarity colors). Exact palette is
  `art-director`'s call; this spec only requires the classes be visually
  distinct from rarity colors.

## 4. Chest → cosmetic-rarity odds table

Design rule applied: Bronze/Silver reweight only (no rarity floor — they can
still roll Common). Gold/Platinum guarantee Rare-or-better. Diamond/Lunacian
guarantee Epic-or-better. Each row sums to 100%; chest-roll column sums to 100%.

| Chest roll % | Chest grade | Common | Rare | Epic | Legendary | Mythic |
|---:|---|---:|---:|---:|---:|---:|
| 45% | Bronze | 70.0% | 24.0% | 5.5% | 0.4% | 0.1% |
| 28% | Silver | 60.0% | 28.0% | 10.0% | 1.7% | 0.3% |
| 16% | Gold | — | 55.0% | 35.0% | 8.0% | 2.0% |
| 7% | Platinum | — | 35.0% | 45.0% | 15.0% | 5.0% |
| 3% | Diamond | — | — | 55.0% | 35.0% | 10.0% |
| 1% | Lunacian | — | — | 30.0% | 45.0% | 25.0% |

**Blended system-wide odds** (chest-roll % × in-chest rarity %, summed per
column) vs. current flat `ECHO_BOX_RARITY_ODDS`:

| Rarity | Current (flat) | New (blended) | Change |
|---|---:|---:|---:|
| Common | 62.0% | 48.3% | −13.7pp |
| Rare | 27.0% | 29.9% | +2.9pp |
| Epic | 9.0% | 16.1% | +7.1pp |
| Legendary | 1.7% | 4.5% | +2.8pp (2.6×) |
| **Mythic** | **0.3%** | **1.35%** | **+1.05pp (4.5×)** |

**Final number, stated plainly**: this table raises the system-wide Mythic
rate from 0.3% to **1.35%**, a **4.5× increase**. It also raises Legendary
(2.6×) and Epic (1.8×), and lowers Common — because guaranteeing a rarity
floor on the top 4 chest grades necessarily pulls the *entire* distribution
upward, not just the Mythic tail. That system-wide upward shift, not only the
Mythic number, is what needs an economy sign-off (see §6 — Shard cost per
`echoCost()` does not change, so expected reward-per-Shard goes up).

## 5. Reveal copy

**Step 1 (chest grade), one line each:**
- Bronze — "A Bronze Chest. Steady odds inside."
- Silver — "Silver Chest. Getting warmer."
- Gold — "Gold Chest! Rare or better, guaranteed."
- Platinum — "Platinum Chest — the good stuff."
- Diamond — "Diamond Chest! Epic or better, guaranteed."
- Lunacian — "LUNACIAN CHEST!! Rarest pull in the game."

**Step 2 (opening beat, shown briefly before the `.rcard` resolves):**
- "Cracking it open…" (all grades, generic — keeps this step's authorship
  cheap; the payoff is the existing rarity reveal, not new per-grade copy)

**Existing Step-2 result copy is unchanged** (`DUPLICATE` / item name /
category / "Tier title unlocked: …" — note this last line, `client.html:3092`,
should read "Rank title unlocked: …" per §2).

## 6. Open questions (need PM / other-agent decision, not mine to make)

1. **Economy sign-off on the 4.5× Mythic / 1.8-2.6× Epic-Legendary uplift**
   (§4). Shard cost (`echoCost()`) is unchanged, so expected cosmetic value
   per Shard spent goes up — is that the intended net effect of adding this
   feature, or should the per-chest rarity tables in §4 be tuned down before
   ship? → `economy-designer` + PM.
2. **Whether raising the floor on Diamond/Lunacian devalues the existing
   dup→fuse loop** — if Epic+ becomes much more common via high chest grades,
   fusion (3 dupes → 1 tier-up) may complete faster than intended for players
   who happen to roll well on chests. Needs a balance check against
   `ECHO_FUSE_COST`. → `economy-designer`.
3. **Exact chest-grade color ladder / glow treatment** (must be visually
   distinct from `.rcard.r0-r4` rarity colors per §3, but the specific palette
   is not a UX call). → `art-director`.
