# UX Specification: Combat Screen — "Shroom & Gloom"-Inspired Mood Pass

> **Status**: Ready for review — all 4 creative decisions resolved (Section 15), including one
> deliberate, scoped exception to the "minh bạch triệt để" pillar (RunMap distant-node type only —
> see Section 0 callout and Section 5.4). Combat intent transparency is unchanged.
> **Author**: ux-designer
> **Last Updated**: 2026-09-18
> **Screen / Flow Name**: `Combat` (`godot/scenes/combat/Combat.tscn` / `CombatView.gd`), with a
> companion adaptation for `RunMap` (`godot/scenes/run_map/RunMap.tscn` / `RunMapController.gd`)
> **Platform Target**: PC / Web (desktop-first, per `technical-preferences.md`); this spec adds
> nothing gamepad/touch cannot already do (see Section 11)
> **Related GDDs**: `design/gdd/godot-port-rule-spec.md` §2 ("minh bạch triệt để" — public enemy
> intent, the pillar this spec is not allowed to violate), §9 (encounter budget / RunMap graph)
> **Related ADRs**: none yet — architecture is `/Users/loc.tien.nguyen/.claude/plans/mellow-scribbling-mochi.md`
> §3/§6/§7 (scene ownership, CombatStage3D, RunMap graph generator)
> **Related UX Specs**: none yet exist under `design/ux/`. This document also covers the RunMap
> graph visual (Section 5.4) as a companion adaptation rather than a full screen spec — if RunMap
> grows scope beyond its graph visual, split it into its own `design/ux/run-map.md` later.
> **Accessibility Tier**: Basic (see Section 12 — this project has no screen-reader/reduced-motion
> settings infrastructure yet; this is a tracked, honestly-stated gap, not something this single
> spec can close)

---

## 0. Inspiration Source & Adaptation Principle

> Research input (coordinator-provided, from direct observation of Shroom and Gloom
> gameplay/key art — see task brief): first-person hand-of-cards view, consistent thick black
> comic-style outline on every element, cold-dark environment art with one warm focal light
> source, neon glowing monster eyes, layered claustrophobic cave rooms, Slay-the-Spire-style
> branching node map, and a clean sword/shield + number intent bubble over enemy heads.

Axie Dice Tactics cannot and should not copy this 1:1 — five constraints are load-bearing and
already confirmed against the real repo (not assumed):

| S&G element | Why we can't/shouldn't copy it literally | What we borrow instead |
|---|---|---|
| Hand-of-cards, first-person | Axie Dice is dice-based (5 Axie rolling faces), no card hand | The dice tray already sits screen-bottom, the natural "your hands" zone — kept, not re-architected |
| Thick black comic outline on everything | Axie has full-rig 3D models (`AxieCharacter3D`, `axie_mixer_3d` addon) with painterly Lunacia art, not 2D hand-drawn sprites — outlining every model would fight the existing pipeline for no material gain | Outline stays reserved for the *existing* Cosmic/Mythic cosmetic tier hook (`outline_inflate.gdshader`/`mystic_outline.gdshader`, already shipped in the addon for rare-die visual tier) — never applied game-wide |
| Neon eyes on hand-painted 2D creatures | Same 3D-vs-2D mismatch — a hand-painted outline glow reads wrong on a lit 3D mesh | A real, small `OmniLight3D` per unit at eye height, tinted by **existing** class palette (plant/beast/aqua/reptile/bug/bird), see Section 5.1 |
| Cold-dark cave rooms, single warm torch | Current Lunacia backgrounds (`Desert_Battle_BG final.png` etc.) are flat, bright, single-layer daylight paintings — no parallax layers exist to build real depth from | A dynamic 2D vignette that darkens/cools the *battlefield only* (never the UI) and re-centers its warm falloff on whichever unit is acting — code-only, reuses the exact `GradientTexture2D` pattern `CombatView._build_gradient_textures()` already uses |
| Branching node map, obscured-until-close node identity | Axie Dice's pillar (`godot-port-rule-spec.md` §2) "minh bạch triệt để" governs **combat** (enemy intent) and does not change. For the **RunMap**, the user made a deliberate, informed call to lean into S&G's mystery instead of extending that pillar to map exploration (see callout below) | RunMap graph gets real curved edges and a torch-lit/fog-of-cave read (Section 5.4); node type is obscured (a plain "?" glyph) for any node **2+ rows beyond** the player's current position, and always fully revealed for the row the player is actually choosing from right now |
| Sword+number / shield+number intent bubble | N/A — already matches | `UnitHeadHUD.set_intent()` already does exactly this with real Origins art. **No change proposed.** |

> **Deliberate, scoped pillar exception (confirmed 2026-09-18)**: obscuring far-RunMap-node type
> is an intentional trade of "minh bạch triệt để" for S&G-style mystery — the user chose this
> after the trade-off was explicitly presented (this doc's earlier draft recommended the opposite,
> full transparency; the user overrode that recommendation on purpose). The exception is scoped
> tightly on all three axes: (a) it touches **RunMap node-type icons only** — nothing about
> combat; (b) the row the player is **actually choosing from right now** (`current.next_ids`) is
> always fully revealed — the player is never asked to commit to a pick with its own type
> withheld, only future/further rows stay foggy; (c) enemy intent inside Combat remains exactly
> as public and immediate as rule spec §2 requires — **zero change** there. This is a named,
> narrow exception to the pillar, not a reinterpretation of it, and it should be cited as
> precedent only for RunMap-exploration-style "not yet relevant" information, never for anything
> the player must act on immediately (like combat intent).

Two elements already fully satisfy the brief and are called out so no one re-implements them:
**enemy intent badge** (`UnitHeadHUD.gd`) and **die-slot black-border + circular corner badge**
(`CombatView._build_die_slot_badge()`). This spec does not touch either.

---

## 1. Purpose & Player Need

**What player need does this screen serve?**

The player needs to read, in under a second, three things at any moment during a turn: *which
unit is about to act or is acting right now*, *what every enemy intends to do and to whom*, and
*what their own dice currently allow*. Shroom & Gloom's cave-and-torchlight staging is effective
precisely because it does this through pure visual hierarchy (darkness hides the irrelevant,
light finds the relevant) rather than through more UI chrome. Axie Dice's combat screen already
solved the *information* half of this (intent badges, HP notches, dice tray) in the
2026-09-17 pass; what it has not yet solved is the *staging* half — right now every unit and the
whole battlefield are lit identically flat, so the player's eye has to do all the "what matters
right now" work themselves.

**The player goal**: Instantly know where to look next — the currently-acting unit or the enemy
whose intent just became relevant — without reading the turn banner text or scanning the whole
board.

**The game goal**: Reduce the perceptual cost of an already-transparent information system
(intent is always public per the rule spec) so that transparency reads as *atmosphere*, not as a
wall of simultaneous HUD elements competing for attention.

---

## 2. Player Context on Arrival

| Question | Answer |
|----------|--------|
| What was the player just doing? | Selected a `battle`/`elite`/`boss` node on RunMap, or is mid-combat already (this spec applies to the whole combat session, not just entry) |
| What is their emotional state? | Variable by phase: ROLL/REROLL is calm/tactical (reading dice), EXECUTE is focused (choosing sequence), END_TURN is tense (watching enemy intents resolve — the highest-stakes reading moment) |
| What cognitive load are they carrying? | High during EXECUTE with 5 party dice + up to ~6 enemy intents simultaneously legible (rule spec §2, §10) |
| What information do they already have? | Full enemy intent, by design — this spec must never obscure that, only stage it |
| What are they most likely trying to do? | Decide sequencing: which die to use on which target, in what order, to survive the incoming intents |
| What are they likely afraid of? | Missing an intent that will kill a low-HP ally because it wasn't visually prioritized over less-relevant board information |

**Emotional design target for this screen**: Tense and immersed, like standing in a small lit
circle in a larger dark space — but never *confused*. Every darkening this spec adds must make
the important thing easier to find, never harder.

---

## 3. Navigation Position

```
RunMap (map_graph node selection)
  └── Combat (this screen — Modal/full-scene, per architecture plan §3 "Combat.tscn")
        ├── Result (loss) — scene replace on EventBus.combat_finished(false)
        └── RunMap (win) — scene replace on EventBus.combat_finished(true), after RunState.after_node()
```

**Modal behavior**: Full-scene replace (not an overlay) — unchanged from current implementation.
No dismiss path exists mid-combat (matches rule spec §8: a combat, once entered, resolves to
win/loss; the only mid-combat exit already live is the JS build's save-and-quit, out of scope for
this visual-mood pass).

**Reachability — all entry points**:

| Entry Point | Triggered By | Notes |
|---|---|---|
| RunMap → node press | `RunMapController._refresh()` button → `RunState.enter_node(id, "battle"/"elite"/"boss")` → `EventBus.node_entered` → scene change | Only entry point today |

---

## 4. Entry & Exit Points

**Entry table**:

| Trigger | Source Screen / State | Transition Type | Data Passed In | Notes |
|---|---|---|---|---|
| Node press on RunMap | RunMap | Scene replace | `RunState.pending_combat` (Dictionary — node_id/kind/pw/ascension mods/roster/relics/combat_seed) | Unchanged — see architecture plan §4 |

**Exit table**:

| Exit Action | Destination | Transition Type | Data Returned / Saved | Notes |
|---|---|---|---|---|
| `combat_finished(true)` | RunMap | Scene replace | `RunState.apply_combat_result()` then `after_node()` | Unchanged |
| `combat_finished(false)` | Result | Scene replace | `RunState.apply_combat_result()` | Unchanged |

Nothing in Sections 3/4 changes as part of this spec — included for completeness per the
template's screen contract, not because this pass touches navigation.

---

## 5. Layout Specification

### 5.1 Wireframe — Combat (mood pass annotations marked `**NEW**`)

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    ┌─────────────────────┐              [Log]            │ ← TopBar (unchanged)
│                    │  Turn 4 · Your Turn │                               │
│                    └─────────────────────┘                               │
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │ ← **NEW** cool-dark
│  ░░           (enemy row — far, darker)              ░░░░░░░░░░░░░░░░░░  │   read at screen edges
│  ░░     👁orange    👁orange         👁grey(boss)      ░░░░░░░░░░░░░░░░░░  │   **NEW** eye-glow pin-
│  ░░   [intent][intent]              [intent]         ░░░░░░░░░░░░░░░░░░  │   pricks (small, class/
│  ░░       ╲       ╲                  ╱                ░░░░░░░░░░░░░░░░░  │   grey-tinted OmniLight3D)
│  ░░        ╲       ╲   ✦WARM POOL✦  ╱   (bezier lines,░░░░░░░░░░░░░░░░░  │ ← **NEW** warm radial
│  ░░         ╲       ╲   currently  ╱     unchanged)   ░░░░░░░░░░░░░░░░░  │   falloff re-centers on
│  ░░          ╲       ╲ ACTING UNIT╱                   ░░░░░░░░░░░░░░░░░  │   the acting unit each
│  ░░           (party row — near, brightest at center) ░░░░░░░░░░░░░░░░░  │   phase (5.1a below)
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │
│              (Nameplates: name + HP notches + shield — unchanged)         │
├──────────────────────────────────────────────────────────────────────────┤
│  [Mana●●●○○]      { DieSlot0..4 — unchanged }        [Reroll●●○][End Turn]│ ← BottomBar: NEVER
│  fully lit, never dimmed by the vignette — see 5.1a constraint            │   dimmed (a11y-critical)
└──────────────────────────────────────────────────────────────────────────┘
```

### 5.1a The dynamic vignette/spotlight — mechanism (Decision 2 in Section 15)

Extends the existing `_vignette: TextureRect` (`CombatView._build_gradient_textures()`,
currently a static radial gradient, `fill_from=(0.5,0.5)`) rather than replacing it:

- **Scope**: applies only inside the stage band (`Stage3D` + `UnitVisualsRoot` + `TargetLines` —
  the battlefield). `TopBar`, `BottomBar` (dice tray, mana, reroll, end turn) and
  `DebugLogPanelContainer` sit on their own already-opaque panels (`DangoTheme.BG_PANEL`,
  alpha 0.82+) and are explicitly **out of scope** — per Section 12, interactive/legibility-
  critical UI must never lose contrast to this effect.
- **"Acting unit" resolution per phase** (all derivable from data `CombatView` already reads,
  no new engine state needed):
  - `EXECUTE` + a die selected (`_selected_die_uid != -1`) → that unit is the acting unit.
  - `EXECUTE` + nothing selected → falls back to the whole party row, dim pool (no single
    target — avoids implying a false "who should I use" hint, which would cross into
    gameplay-suggestion territory this spec should not enter).
  - `END_TURN` → the enemy currently resolving intent (`EventBus.enemy_intent_executed(uid)`).
  - `ROLL`/`REROLL` → whole board evenly lit (everyone is rolling at once) — no single pool.
- **Per-frame update**: in `_layout_unit_visuals()` (already re-reads `CombatStage3D` every
  frame for camera-follow, per the file's own "STATE-READ DISCIPLINE" comment — this is the
  sanctioned place to add one more camera-space read), recompute `_vignette.texture.fill_from`
  from `CombatStage3D.get_unit_screen_pos(acting_uid, CHEST_HEIGHT)`, normalized into the
  Vignette TextureRect's own 0..1 UV space. Tween the *transition* between two acting units
  (≈300ms ease-out — see Section 10), never snap, so focus reads as "the light finds them," not
  a hard cut.
- **Warm/cool color split**: gradient stop 0 (near the acting unit) stays near-transparent
  (background shows through, per current behavior); stop 1 (edges) shifts from the current flat
  `DangoTheme.BG` at 0.65 alpha to a **cooler-tinted, slightly darker** version of the same color
  (multiply blue channel up ~8%, drop value ~10%) specifically during `END_TURN` (the tense
  "enemy is acting" beat) — reverts to the current neutral dark during `EXECUTE`/`ROLL`. This is
  the "cold dark, warm point" read, achieved by re-tinting the *existing* single gradient
  texture, not by adding new art layers.

### 5.2 Zone Definitions (delta from current implementation only)

| Zone Name | Description | Change |
|---|---|---|
| `Vignette` (`CanvasLayer/Root/Vignette`) | Full-screen radial darken | Becomes dynamic: `fill_from` follows acting unit, color temperature shifts by phase (5.1a) — same node, no new Control added |
| `UnitVisualsRoot` unit slots (via `CombatStage3D`) | 3D battlefield | Gains one `OmniLight3D` child per unit slot (eye-glow, Section 5.1) — no layout change |
| `BottomBar`, `TopBar`, `DebugLogPanelContainer` | Interactive UI | **Explicitly unaffected** — hard constraint, not a zone change |

### 5.3 Component Inventory (new components only — existing ones are unchanged)

| Component Name | Type | Zone | Purpose | Required? | Reuses Existing? |
|---|---|---|---|---|---|
| Eye-glow light | `OmniLight3D` (code-created, no `.tscn` node needed) | `CombatStage3D` unit slot | Small, class-tinted (or grey/red for non-hero enemies) point light at eye height — personality accent | Yes (Decision 3 — **resolved**, see Section 15) | Extends `CombatStage3D.spawn_unit()`; reuses `_CLASS_COLOR_VARIANT`'s existing class→color mapping philosophy (not its exact table — that's a mesh recolor index, this needs an actual `Color`, see Section 8). Deliberately does NOT touch `AxieMysticGlow` — that pipeline stays reserved for its current Mythic/Cosmic-die rarity-signal meaning; reusing it here would dilute that signal (see Section 0 and Section 15 resolution) |
| Dynamic vignette re-target | Logic only (no new node) | `_vignette` (existing) | Warm-pool-follows-action staging | Yes (Decision 2) | Reuses `_build_gradient_textures()`'s `GradientTexture2D` |
| RunMap edge curves | `Line2D` per edge (code-generated) | `RunMap.tscn` | Replaces implicit list-adjacency with drawn cave-path edges | Yes (Decision 4) | Reuses `TargetLinesLayer`'s existing quadratic-bezier-sampling approach (`_STEPS`/`_BOW_HEIGHT` pattern) — see 5.4 |
| RunMap node fog/torchlight overlay + "?" glyph | `GradientTexture2D` per reachable node + a procedural `Label("?")` swapped in for the real type icon on obscured nodes | `RunMap.tscn` | Reachable (next-row, selectable-now) nodes: fully lit + full icon. Nodes 2+ rows out: dim **and** type icon replaced by a "?" glyph — "torch in a cave, unexplored tunnels ahead" | Yes (Decision 4 — **resolved**, see Section 15) | Same `GradientTexture2D` pattern again (third reuse, see Section 8); the "?" is plain text (`DangoTheme` font/color), not a new art asset — no new icon commission needed |

### 5.4 Companion Screen: RunMap Graph Visual

Current state (`RunMapController.gd`, verified 2026-09-18): `_current_choices()` only ever
renders the *immediately next* reachable row as a flat `GridContainer` of buttons — no wider
graph is drawn, even though `RunMapGraph`/`RunMapNode` already carry full `row`/`col`/`next_ids`
data for the *entire* branching map (architecture plan §7). This spec proposes rendering that
full data, not new data — with node **type** obscured for rows the player cannot yet act on
(Decision 4, resolved 2026-09-18 — see Section 0 callout and Section 15 for the full trade-off
this was chosen over).

```
┌──────────────────────────────────────────────────────────┐
│  Power level: 6 — visited: 5        [Camera2D pans/zooms]│
│                                                            │
│         (row N, far future — 2+ rows out: FOGGED)          │
│                  ?  ?                                      │
│               ╱      ╲     ← edges still drawn (branching  │
│              ╱        ╲       is visible — only TYPE is    │
│            ?            ?      hidden, not existence/shape)│
│    (2+ rows out: dim silhouette + "?" glyph instead of the  │
│     real node-type icon — connectivity/shape still readable)│
│               ╲          ╱                                  │
│      ⚔BATTLE      💰SHOP      ← next row (current.next_ids):│
│    (reachable NOW:  (reachable NOW:   ALWAYS full icon +   │
│     torch-lit,       torch-lit,        torch-lit, no matter │
│     full icon)        full icon)       how deep the run is) │
│         ╲    ...    ╱                                        │
│          ╲          ╱                                        │
│         ●CURRENT NODE (bright, player is "here")              │
│    ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄  │
│  (visited path behind — dim but ALWAYS fully visible, never   │
│   fogged; the player's OWN past is never mysterious to them,  │
│   only the unexplored future is)                              │
└────────────────────────────────────────────────────────────┘
```

**Rules** (all directly answer the brief's RunMap ask, Decision 4 — resolved):
1. Layout uses `RunMapNode.row`/`col` directly for `Node2D` position
   (`x = col * COL_SPACING`, `y = -row * ROW_SPACING`) inside a `Camera2D`-panned/zoomed
   container — replaces the `GridContainer` of only-next-row buttons.
2. Edges: one `Line2D` per `next_ids` entry, quadratic-bezier sampled (same math as
   `TargetLinesLayer._draw()`), with a small per-edge lateral wobble seeded from
   `hash(from.id, to.id)` so edges read as hand-cut cave paths, not ruler-straight lines —
   **deterministic**, so it never jitters between redraws of the same graph. Edges are drawn to
   *every* node regardless of fog state — branching shape/existence is never hidden, only node
   *type* is (rule 4).
3. **Node lighting state** (the "torch in a cave" read):
   - `visited` nodes and the edges among them: dim but always fully visible, full icon — the
     player's own path is never fogged.
   - `current_node_id`: brightest, warm radial glow under it, full icon.
   - Nodes in the row the player can act on right now (`current.next_ids`): full color + warm
     torch-glow pool, **full icon always** — this is the one row that must never be fogged,
     because the player is choosing from it this instant (see Section 0 callout, clause b).
4. **Node type fog (the resolved exception)**: any node **2+ rows beyond** `current_node_id` has
   its real `_NODE_ICON` replaced with a plain "?" glyph (`Label`, no new art asset) over the
   same dim node-color wash already defined for unlit nodes. As the run advances and
   `RunState.enter_node()`/`after_node()` moves `current_node_id` forward, a row that was "2+ out"
   becomes the new "reachable next row" and its "?" is replaced by its real icon (see reveal
   transition, Section 10) — mystery resolves progressively, it is never a one-time permanent
   reveal of the whole map.
5. Applied uniformly to every `node_type` including `boss` (no special-casing boss rows to stay
   revealed) — if this reads as *too* mysterious once in-engine (e.g. players wanting to see how
   many rows remain to the next boss), that is a tuning knob for a follow-up pass, not a reason to
   hold this spec.

---

## 6. States & Variants

| State | Trigger | Visual Change | Behavioral Change | Notes |
|---|---|---|---|---|
| Vignette: ROLL/REROLL | Phase enters ROLL or REROLL | Even lighting, no single warm pool | None | Matches "everyone rolls together" |
| Vignette: EXECUTE, die selected | `_selected_die_uid != -1` | Warm pool re-centers on that unit (≤300ms tween) | None | |
| Vignette: EXECUTE, no selection | Die deselected/used | Warm pool widens to cover the party row evenly | None | Deliberately does not spotlight a "suggested" unit |
| Vignette: END_TURN | `enemy_intent_executed(uid)` | Warm pool jumps to that enemy; edge color shifts cooler/darker | None | The tensest read — a fast, clear "eyes here now" cue |
| Eye-glow: idle | Unit spawned, alive | Small steady point light, class/grey-red tinted | None | Purely decorative — see Accessibility constraint (never sole carrier of info) |
| Eye-glow: dead | `unit_died`/`play_death_fade` | Light intensity tweens to 0 alongside the existing scale-to-zero fade | Light freed with the slot | Reuses `CombatStage3D.play_death_fade()`'s existing tween chain |
| RunMap node: reachable (choosable now) | In `current.next_ids` | Full color + torch glow + **full type icon, always** | Clickable (unchanged) | Never fogged — the player must have full info for the choice in front of them (Section 0 callout clause b) |
| RunMap node: visited | `node.visited == true` | Dim, but edges/icon fully visible | Not re-enterable (unchanged rule) | Own past is never mysterious |
| RunMap node: far future (2+ rows beyond current) | Not in `current.next_ids` and not reachable within 1 row | Reduced brightness/saturation **and** real type icon replaced by a "?" glyph | Not clickable (unchanged) | The resolved mystery exception — see Section 5.4 rule 4 |
| RunMap node: newly revealed | `after_node()` advances `current_node_id`, a former "far future" row becomes the new reachable row | "?" crossfades to the real `_NODE_ICON`, brightness ramps up | Becomes clickable | See Section 10 reveal transition |
| Reduced-motion (future toggle, not yet built — see Section 15) | Setting enabled | All tweens above collapse to instant snap | None | See Section 12 |

---

## 7. Interaction Map

No new input paths — this spec is presentation-layer only. For completeness, cross-referencing
what already exists and confirming it is unaffected:

### 7.1 Navigation Inputs (unchanged — confirmed still valid after this pass)

| Input | Platform | Action | Notes |
|---|---|---|---|
| Click/tap a die slot, then a Nameplate/3D-model/RunMap node | Mouse/touch | Select source, then target (click-click) | `CombatView._on_die_slot_pressed`/`_on_target_clicked`; `CombatStage3D.unit_clicked` (second path into same handler) — both unaffected, vignette/eye-glow are display-only |
| Tab / Enter / Space | Keyboard | Navigate/activate the same controls | Unaffected — this spec adds no new focusable elements |
| RunMap node press | Mouse/touch/keyboard-focus+Enter | `RunState.enter_node()` | New Camera2D pan does not change how a node is pressed, only how it's found on screen |

### 7.2 New Hover Behavior

| Input | Context | Response | Notes |
|---|---|---|---|
| Hover a RunMap node (reachable or not) | Mouse | Torch-glow under that node brightens slightly further, distinct from the ambient reachable-row glow | Mirrors the existing enemy-intent-hover pattern (`_on_enemy_intent_hover`) — hover = brighten, not a new mechanic |

### 7.3 State-Specific Behaviors

| State | Input Restriction | Reason |
|---|---|---|
| Any vignette/eye-glow/RunMap-fog state above | None — all purely visual | This spec must never gate an input on a mood-lighting state; confirmed no `_is_animating`-style lock is added by any of these features |

---

## 8. Data Requirements

| Data Element | Source | Update Frequency | Owner | Format | Null/Missing Handling |
|---|---|---|---|---|---|
| Acting unit uid (for vignette re-target) | Derived in `CombatView._layout_unit_visuals()` from `_combat.phase`/`_selected_die_uid`/last `enemy_intent_executed` payload | Every frame | `CombatView` (view-only derivation, writes nothing back) | `int` uid or `-1` | `-1` → vignette falls back to even/whole-row lighting, never crashes |
| Unit class → eye-glow color | New constant table in `CombatStage3D.gd`, e.g. `_EYE_GLOW_COLOR` keyed by the same `cls` strings `_CLASS_COLOR_VARIANT` already uses | Set once per `spawn_unit()` | `CombatStage3D` | `Color` | Non-hero enemy (`cls==""`) → falls back to the existing `_ENEMY_PLACEHOLDER_COLOR` family (dark red-grey) |
| `RunMapNode.row`/`col`/`node_type`/`next_ids`/`visited`/`locked` | `RunState.map_graph` (already exists, `RunMapGraph.from_data()`) | On RunMap `_ready()` | `RunState` | See `run_map_node.gd` | Already null-safe (`from_data()` has defaults for every field) |
| `RunState.current_node_id` / `visited_node_ids` / `power_level` | `RunState` (already exists) | On node entry/exit | `RunState` | `String` / `Array[String]` / `int` | Unchanged |

**Rule**: as with the rest of this project, this screen must never write directly into
`CombatEngine`/`RunState` — every element in this spec is read-only presentation over data those
systems already expose. No new event needs to be fired (Section 9).

**Dependency note**: three different features in this spec (battlefield vignette, RunMap
reachable-node glow, RunMap unreached-node fog) all reuse the same `GradientTexture2D`
radial-falloff technique already established by `_build_gradient_textures()`. If a future pass
wants to promote this to a shared helper (e.g. `MoodGradient.gd`) instead of three independent
call sites, that is an implementation-detail decision for `ui-programmer`, not this spec.

---

## 9. Events Fired

None. Every visual in this spec is a passive reaction to EventBus signals that already exist
(`turn_phase_changed`, `enemy_intent_executed`, `unit_died`, `node_entered`) or to `RunState`
fields that already exist. Nothing here fires a new event back into game logic.

---

## 10. Transition & Animation

| Transition | Trigger | Type | Duration | Easing | Interruptible? | Reduced-Motion Fallback |
|---|---|---|---|---|---|---|
| Vignette re-target | Acting unit changes | `fill_from` tween | 300ms | Ease out | Yes — retargeting mid-tween just redirects | Instant snap to new `fill_from` |
| Vignette color-temperature shift (EXECUTE↔END_TURN) | Phase change | Color lerp on gradient stop 1 | 250ms | Ease in/out | Yes | Instant |
| Eye-glow spawn | Unit spawned | Fade light energy 0→target | 150ms | Ease out | No (short) | Instant full energy |
| Eye-glow death | `unit_died` | Fade light energy →0, parallel with existing scale-to-zero | Matches `CombatStage3D._DEATH_FADE_DURATION` (0.45s) | Ease in | No | Instant to 0 |
| RunMap node hover brighten | Mouse enters node | Glow alpha bump | 120ms | Ease out | Yes | Instant |
| RunMap edge/fog reveal on `after_node()` | New node entered | Newly-reachable row's dim fog lifts, edges into it brighten | 400ms | Ease out | No | Instant reveal |
| RunMap "?" → real icon reveal | A row moves from "2+ rows out" to "reachable now" (`after_node()`) | Crossfade `Label("?")` out, `_NODE_ICON` in | 300ms | Ease out | No | Instant swap |

All durations above are short and low-amplitude by design specifically so they remain acceptable
even before a real reduced-motion setting exists (see Section 12's honest gap statement) — but a
real toggle should still collapse every row above to "Instant," not rely on the durations being
merely subtle forever.

---

## 11. Input Method Completeness Checklist

**Keyboard** — unaffected by this spec (no new focusable element is added; RunMap nodes were
already keyboard-focusable buttons and remain buttons, just repositioned by `Node2D` layout
instead of `GridContainer` flow — focus order must be re-verified after implementation, see
Section 15 open item).
- [ ] Re-verify Tab order across RunMap nodes still follows a sane reading order once positioned
      by row/col instead of `GridContainer` auto-flow (flagged, not yet verified — implementation
      task)
- [x] No action in this spec requires mouse-only input (all changes are decorative/read-only)

**Gamepad** — N/A per `technical-preferences.md` (no gamepad support in this project).

**Mouse**
- [x] Hover behavior defined (Section 7.2)
- [ ] Confirm RunMap node hit targets stay ≥44×44px after moving off `GridContainer`'s automatic
      sizing (implementation task)

**Touch** — Partial support project-wide; nothing in this spec is mouse-hover-dependent for
*correctness* (hover-brighten is a nicety, not a requirement to act) — touch users lose the hover
brighten but retain full node-press functionality.

---

## 12. Screen-Level Accessibility Requirements

**Honest baseline**: this project has no reduced-motion, colorblind-mode, or screen-reader
settings infrastructure yet (confirmed via repo search, 2026-09-18) — `technical-preferences.md`
already tracks this as open a11y debt owned by `accessibility-specialist`. This spec does not
invent settings UI to close that gap; it instead holds itself to two hard rules so it never makes
that future gap worse:

**Hard rules for every feature in this spec:**
1. **Contrast**: the battlefield vignette/spotlight (5.1a) is explicitly scoped OFF the
   `BottomBar`/`TopBar`/`DebugLogPanelContainer` — those already sit on opaque `DangoTheme` panels
   independent of this effect. No text in this spec's scope should ever be measured for contrast
   against the *dynamic* vignette, because none renders on top of it.
2. **Never color-only**: eye-glow color (class-tinted) and RunMap node lit/unlit state are
   **decorative reinforcement only**. Legal targets are still communicated by the existing
   `set_targetable()` border/scale system (Section 6 of the prior review pass, unchanged); reachable
   RunMap nodes are still communicated by the node still being a pressable `Button`/still showing
   its full-color icon, not solely by brightness. A deuteranopia player who cannot distinguish the
   eye-glow color from the enemy-grey light loses zero functional information.
3. **No flashing**: every pulse/tween in Section 10 stays under 3 transitions/second and low
   amplitude (largest single jump is the 400ms RunMap fog-lift, a one-time reveal, not a repeating
   flash) — well clear of photosensitive-seizure flash thresholds.
4. **Reduced motion, honestly scoped**: Section 10's "Reduced-Motion Fallback" column is
   specified now so that whenever a real Settings toggle exists, wiring it into these six
   transitions is a mechanical pass, not a redesign. Until that toggle exists, this spec is
   accepted with the durations in Section 10 as the permanent, always-on behavior.
5. **The RunMap "?" fog (Section 5.4) never withholds information the player needs for the
   decision in front of them.** This is the specific accessibility check this exception must pass:
   it hides only rows the player is *not currently choosing between*. The reachable row
   (`current.next_ids`) — the only one a click actually commits to — is always fully revealed
   (rule 3/Section 0 clause b). A player relying on the "?" glyph's own legibility only needs to
   read it as "not yet known," never as a specific type — it is a plain high-contrast text
   character (`DangoTheme` colors), not a color-coded or shape-coded signal that could itself be
   colorblind-unsafe.

**Colorblind-unsafe elements and mitigations:**

| Element | Risk | Mitigation |
|---|---|---|
| Eye-glow class color | Multiple CB types could see a plant vs. bug glow as similar | Decorative only (rule 2 above) — class identity is already carried by model shape/existing recolor, not by this light |
| RunMap lit/unlit node brightness | Low-vision or contrast-sensitivity could miss the brightness difference | Node type icon and clickability never depend on brightness (rule 2) |

**Cognitive load assessment**: This spec does not add a new information stream — it re-stages
*existing* streams (intent, HP, turn phase) so the highest-priority one is easiest to locate. If
anything, this should *reduce* the player's search cost within the existing 5-stream load
documented for the dice-tray/intent HUD combo (die values, enemy intents, HP/shield, status
icons, mana/reroll counters) by pre-sorting "where to look first."

---

## 13. Localization Considerations

No new text strings are introduced by this spec (all new elements are lights/gradients/lines, no
labels). Existing text elements (`TurnBannerLabel`, Nameplate name, intent target label) are
unaffected — their localization plan is unchanged from the current implementation.

---

## 14. Acceptance Criteria

**Layout & Rendering**
- [ ] Battlefield vignette re-centers on the correct acting unit in every phase per Section 6's
      state table, verified against at least one full turn cycle in DevReview
- [ ] `BottomBar` (dice tray, mana, reroll, end turn) contrast is measurably unaffected by the
      vignette at every phase (screenshot comparison before/after this pass)
- [ ] Eye-glow light is visible on every spawned unit (party and enemy) without any material
      introspection failure on the capsule-placeholder fallback path (`CombatStage3D._make_placeholder`)
- [ ] RunMap renders the full graph (not just the next reachable row) with `Line2D` edges
      positioned from real `row`/`col` data
- [ ] Every node in the currently-reachable row (`current.next_ids`) always shows its real,
      legible type icon — never a "?" glyph, at any point in a run (screenshot check)
- [ ] Every node 2+ rows beyond `current_node_id` shows a legible "?" glyph in place of its real
      type icon, over the dim node wash
- [ ] Advancing via `after_node()` correctly reveals the newly-reachable row's real icons and
      leaves everything still 2+ rows out fogged (regression check for off-by-one row math)

**Input**
- [ ] All RunMap nodes remain reachable by keyboard Tab + Enter after the layout change (Section 11)
- [ ] No feature in this spec introduces an input lock (`_is_animating`-equivalent) — verified by
      code review of the implementation diff

**Accessibility**
- [ ] No pulse/tween introduced by this spec exceeds 3 transitions/second (Section 12 rule 3)
- [ ] Removing/hiding the eye-glow light entirely (manual test) does not remove any information
      the player needs to legally act (Section 12 rule 2)

**Performance**
- [ ] One additional `OmniLight3D` per unit (≤11 concurrent) does not measurably regress frame
      time in `CombatStage3D` (already single-shared-viewport per the file's own perf-fix history)

---

## 15. Open Questions

All four original creative decisions are resolved. Two (1, 2) were sequencing/technical calls the
coordinator was delegated authority to make and did not override this document's recommended
defaults; two (3, 4) were aesthetic/identity calls that genuinely required the user's judgment,
were presented to them with the full trade-off, and were decided — one confirming this doc's
recommendation, one deliberately overriding it. Only implementation-detail items remain open.

| Question | Owner | Resolution |
|---|---|---|
| **Decision 1 — Claustrophobia**: code-only vignette/FOV now, vs. also commissioning a new foreground silhouette-frame art asset? | Coordinator (delegated, purely technical/sequencing) | **Resolved — code-only now** (Section 5.1a), confirmed by not overriding this doc's default. Silhouette-frame art remains a future, separate ask routed to `art-director`/`technical-artist` if desired, not blocking this spec. |
| **Decision 2 — Spotlight mechanism**: 2D dynamic vignette vs. a real `SpotLight3D` vs. both? | Coordinator (delegated, purely technical) | **Resolved — 2D vignette only** (Section 5.1a), confirmed by not overriding this doc's default. A 3D rim-light remains a possible P2 stretch, not required. |
| **Decision 3 — Eye-glow investment**: small per-unit `OmniLight3D` vs. reusing `AxieMysticGlow` vs. skipping this pass? | User (creative director) — aesthetic + rarity-signal identity call | **Resolved 2026-09-18 — `OmniLight3D`, matching this doc's recommendation.** `AxieMysticGlow` stays reserved exclusively for the Cosmic/Mythic-die rarity signal; reusing it for every unit's eyes would have diluted that signal. See Section 0 and Section 5.3. |
| **Decision 4 — RunMap node-type visibility**: always-visible icons (this doc's original recommendation, protecting the "minh bạch triệt để" pillar) vs. obscuring distant node types for S&G-style mystery? | User (creative director) — pillar-level trade-off | **Resolved 2026-09-18 — the user deliberately chose the mystery direction, overriding this doc's transparency recommendation, after the trade-off was explicitly presented.** Implemented as a narrow, named, scoped exception (Section 0 callout, Section 5.4): only RunMap node **type** icons 2+ rows beyond current position are obscured (a "?" glyph, not blank); the row the player can actually choose from right now is always fully revealed; combat intent transparency is completely unaffected. This exception should not be cited as precedent for hiding anything the player must act on immediately. |
| RunMap keyboard focus order after switching from `GridContainer` to free `Node2D` positioning | `ui-programmer` (implementation-time verification) | Open — flagged in Section 11, not blocking spec approval |
| Whether the three independent `GradientTexture2D` call sites (battlefield vignette, RunMap reachable-glow, RunMap fog) should be refactored into one shared helper | `ui-programmer` | Open — implementation detail, not a design decision |
| Whether `boss` node type should be exempted from the fog (always shown, since boss rows are structurally significant) | `ui-programmer`/`game-designer`, low priority | Open — this doc applies the fog uniformly including boss (Section 5.4 rule 5); revisit only if in-engine playtesting shows players want early boss-distance visibility |
