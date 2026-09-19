---
name: axiedice-runloop-ux-backlog-2026-09
description: Godot port run-loop (event/shop/treasure/reward/result) UX audit 2026-09-19 — backlog at production/qa/2026-09-19_runloop-ux-backlog.md
metadata:
  type: project
---

User played the Godot port and said the whole UI/UX is ugly/unpolished ("UI/UX đang cực kì xấu
và mất thẩm mĩ"). Work was split: `art-director` owns visual (combat/map/menu), this agent
(`ux-designer`) owns the OUT-OF-COMBAT LOOP — event, shop, treasure, post-combat reward, run
result. Full backlog written 2026-09-19 to
`production/qa/2026-09-19_runloop-ux-backlog.md` (P0/P1/P2, code-grounded against
`godot/scenes/run_map/RunMapController.gd`, `godot/scripts/core/reward_generator.gd`,
`godot/scenes/result/ResultView.gd`, `godot/scenes/shared/DangoTheme.gd`).

**Why this matters**: same split pattern as [[project_axiedice_combat_hierarchy]] — keep visual
color/typography work separate from information-architecture/decision-clarity work so the two
agents don't collide on the same files.

**Top findings (all code-confirmed, not guessed from screenshots alone)**:
- P0: Shop's "BOUGHT" and "can't afford" states share one disabled StyleBox
  (`RunMapController.gd:824-827`, `DangoTheme.gd` `ButtonState.DISABLED` has no owned/unaffordable
  split) — only the button's text distinguishes them.
- P0: every choice card across event/shop/reward/treasure shares one identical template
  (`_add_card()`, `RunMapController.gd:656-697`) regardless of rarity/impact — even though a
  `rar` field already exists on every reward dict (`reward_generator.gd`) and a rarity badge
  component already exists and is used on the Result screen (`ResultView.gd:194-215`) — just not
  reused where it's actually needed (at the decision, not the recap).
- P0: "LEVEL UP" reward card shows "Pomodoro -> Pomodoro" — confirmed NOT a data bug (heroes keep
  the same display name across all 3 tiers per `ContentDB.gd` — `bug1/bug2/bug3` all "Pomodoro"),
  but the arrow notation misleadingly implies nothing changed, and there's no before/after face
  preview despite the data existing in `ContentDB.heroes`.
- P1 (confirmed, not minor): Result screen's missing dmg/turns/kills/biggest-hit is a real gap,
  not cosmetic — `ResultView.gd:12-21` already self-flags it as untracked at run level. Matters
  most on the Defeat screen (roguelike learning loop needs "why did I lose", not just currency
  earned). Data-collection part routes to `gameplay-programmer` first; display part is a follow-up
  once that lands.
- P1: keyword/tooltip system exists for Combat (`CombatView.gd`, `Combat.tscn`) but is never
  reused in the run-map overlays, so relic/shop text uses raw jargon ("Growth", "Back/Eyes
  face") with zero glossary support outside combat.
- Flagged to game-designer (not resolved by ux-designer): Lunacia Shrine's "Make the wager" hides
  which Legendary relic is granted while the other two options fully disclose effects —
  inconsistent transparency; unclear if intentional gamble-flavor or an oversight.
- Flagged to gameplay-programmer (not a UI decision): Defeat-screen roster shows "Olek" twice —
  could be intended (duplicate hero allowed) or a data bug; unresolved.

No memory update needed elsewhere yet — this is a fresh audit, no prior conversation history on
this specific backlog.
