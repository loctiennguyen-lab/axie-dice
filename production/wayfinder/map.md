---
label: wayfinder:map
tracker: local-markdown
created: 2026-09-18
---

# Godot Port — Cutover Readiness (Wayfinder Map)

## Destination

`godot-port` reaches feature parity with the live JS build (`src/`, `main`) — content,
Vault import, save/continue, audio, art pipeline — **and** has an anti-cheat/
replay-verify equivalent to the JS server-side verify (`api/_engine.js`), so that
`godot-port` can be merged into `main` and replace the live production build without
regressing ranked-leaderboard integrity.

Reaching this destination means: nothing architectural or process-level is left
undecided that the remaining Phase 2/3 *execution* backlog is quietly blocked on, and
there is a concrete, testable gate for "ready to cut over."

## Notes

- Domain: Godot 4.7.2 game port (GDScript), branch `godot-port`, repo
  `Donchitos/Claude-Code-Game-Studios`. Live JS build (`main`) is unaffected by this map.
- **Pure execution/content backlog is not ticketed here** — the remaining 73/94 relic
  `.tres` authoring, icon/asset copying, save-run implementation, Battle Pass/unlock
  ladder, and FACE_POOL's actual porting *if greenlit* (see [ticket I](tickets/I-facepool-port-decision.md)
  for the port-or-not call itself). That work is already tracked and sequenced in
  [`production/session-state/godot-port-active.md`](../session-state/godot-port-active.md)
  and is architecturally unblocked. This map exists only for the *decisions* that
  backlog is implicitly waiting on — that gap (not the backlog itself) is the actual
  source of the fragmentation the user flagged.
- Grounding docs every ticket should treat as authoritative:
  [rule spec](../../design/gdd/godot-port-rule-spec.md),
  [architecture plan](/Users/loc.tien.nguyen/.claude/plans/mellow-scribbling-mochi.md),
  [build inventory](../../docs/godot-port-inventory.md) (2026-09-18 — a freshly
  *measured* snapshot of what's built; treat it as primary over the narrative log in
  `godot-port-active.md` wherever the two disagree on a number),
  [session log](../session-state/godot-port-active.md).
- Tracker: local-markdown (this directory). No native blocking UI — blocking is a
  `blocked_by:` line in each ticket's header; the frontier is open + unblocked +
  unclaimed tickets under `tickets/`.
- Root `CLAUDE.md` collaboration protocol applies to all work done against this map:
  ask before Write/Edit, show drafts before requesting approval, no commits without
  explicit instruction.

## Decisions so far

<!-- Pre-existing decisions made before this map was charted. Indexed here, not
     re-filed as tickets — the docs linked already hold them in full. -->

- [RunMap: real branching graph, path-walking generator](../../design/gdd/godot-port-rule-spec.md): Slay-the-Spire-style branching, not a 1:1 port of the old linear step system; 10 invariants gated by `t_map.gd` (10,000 seeds).
- [No inter-combat camp/rest healing](../../design/gdd/godot-port-rule-spec.md): keep the JS behavior — full heal before every fight, no attrition mechanic added.
- [Combat architecture redesigned freely, numbers held fixed](../../design/gdd/godot-port-rule-spec.md): scene/node organization is new-idiom Godot; formulas/values stay exactly as verified in the rule spec.
- [RNG: mulberry32, not Godot's default PCG32](/Users/loc.tien.nguyen/.claude/plans/mellow-scribbling-mochi.md): bit-exact port from `engine.js`, gated by `t_rng.gd` (10,000-draw comparison). RNG lives on `RunState`/`CombatEngine`, never an autoload.
- [`combat_seed` derived per node](/Users/loc.tien.nguyen/.claude/plans/mellow-scribbling-mochi.md): `hash(run_seed, node_id, turn)` instead of a continuous stream, so DevReview's jump-to-combat stays reproducible.
- [Undo = snapshot-restore-in-place, not action-replay](/Users/loc.tien.nguyen/.claude/plans/mellow-scribbling-mochi.md): required to preserve the JS semantic where undo does not rewind the RNG stream — replay-safety depends on this.
- [3-tier state ownership, data-only handoff between tiers](/Users/loc.tien.nguyen/.claude/plans/mellow-scribbling-mochi.md): Persistent (`MetaState`) / In-run (`RunState`) / In-combat (`CombatEngine`); `to_data()`/`from_data()` round-trip-tested from the first commit.
- [Relic hooks: dictionary lookup, not bound Callables on Resources](/Users/loc.tien.nguyen/.claude/plans/mellow-scribbling-mochi.md): avoids `ResourceLoader` cache aliasing bugs; `sort_index` is explicit data, never filesystem order.
- [Fixed visual/design calls](../../design/gdd/godot-port-rule-spec.md): Axie faces away from camera (3/4 turn proposal already rejected by user), no Spine2D runtime, dedicated `OmniLight3D` eye-glow (kept separate from `AxieMysticGlow`), single unbroken HP bar (no segments).
- [Core run loop complete and measured](../../docs/godot-port-inventory.md): 18/18 tests green (~1,400 assertions); `t_full_run_loop` 157 checks / 8 seed-walks proves new run → branching map → combat → reward → next node → final boss → won; content parity measured at 18/18 heroes (0 die-face mismatches), 21/22 enemies, 6/6 bosses, 21/94 relics, 5/6 events.
- [Monster/boss art is Chimera-only — never Axie mascot models](../../docs/godot-port-inventory.md): enforced by `t_assets.test_no_monster_or_boss_wears_a_hero_identity()`, added after `gooey_king` was found silently using the Bug-class hero's own model (identity compared, not just key).
- [Icons must match the live web build](../../docs/godot-port-inventory.md): sourced from `src/art7.js` → `godot/assets/icons/web/`; never substitute Origins Kit icons for status/node/resource/die-face icons.
- [Audio pipeline already decided and built — closed without a grilling session](../../docs/godot-port-inventory.md): 118 audio files imported, `CombatAudio` die-face→sound mapping written and covered by `t_assets`, music loops enabled. Remaining work is wiring `CombatView` to `EventBus` and playing — execution backlog (inventory §9 #1), not a decision. [Ticket F](tickets/F-audio-pipeline-approach.md) closed once this came to light.
- [Game-content art/texture pipeline already decided and built — closed without a grilling session](../../docs/godot-port-inventory.md): monster/boss sprites via `tools/spine_to_sprites.py`, icons from `src/art7.js`, backdrops composited from the Origins Kit — 52MB in `godot/assets/`, gated by `t_assets` (356 checks). Only `cosmetics.js`/Echo Box porting remains genuinely open (moved to fog below). [Ticket G](tickets/G-art-asset-pipeline-decision.md) closed once this came to light.

## Not yet specified

- Godot-side CI gate list once more of Phase 2/3 lands — a parallel to JS's
  `tools/ci.mjs` 12-gate bar. Not sharp enough to ticket until more systems are ported.
- What happens to `src/`'s live ranked-leaderboard history after cutover (migrate,
  freeze, or sunset) — depends on tickets [A](tickets/A-anti-cheat-replay-verify-strategy.md)
  and [H](tickets/H-cutover-acceptance-gate.md) resolving first.
- Godot build/export and hosting pipeline — the current JS build deploys a single
  static HTML file to Vercel; Godot needs export templates and a hosting decision.
  Genuinely unexplored so far.
- Exact RunMap row-count / `TUNE.base`/`growth` / K (distinct-path count) /
  Ascension≥9 elite-placement values — graduates into a Grilling ticket once
  [ticket B](tickets/B-runmap-retune-sim-data.md)'s sim data exists to react to.
- Whether/when `cosmetics.js` (Echo Box gacha cosmetics, a live-JS-only
  meta-progression system) gets ported to Godot at all — narrowed out of the closed
  art-pipeline ticket (G); not yet clear it belongs in this port's scope at all, so not
  sharp enough to ticket.

## Out of scope

- Suspected RNG-not-restored bug on live `main` (production JS) — already spun into
  its own task (`task_ec329666`) per the architecture plan's own scoping note. It's a
  bug in the *live* build, not a decision on the road to Godot cutover.
- Ongoing live-JS feature work on `main` (World Tour, Echo Box, Lunacia Pass, etc.) —
  outside this map's destination; continues under its own process, unaffected by the
  port.
