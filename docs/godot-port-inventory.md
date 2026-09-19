# Axie Dice Tactics — Godot Port: Build Inventory

**Purpose of this document.** A complete, standalone account of what exists in the Godot port
today, what is verified, and what is not built yet. It is written to be handed to someone (or
something) with no prior context as the input to a planning pass. Every number here was
measured, not estimated; where a figure is uncertain it says so.

| | |
|---|---|
| Branch | `godot-port` (never merged to `main`) |
| Engine | Godot 4.7.2 (`/Users/loc.tien.nguyen/Desktop/Godot.app`) |
| Language | GDScript, statically typed |
| Project root | `godot/` |
| Source of truth for rules | `src/engine.js` + `src/data.js` (the live JS game on `main`) |
| Rule spec | `design/gdd/godot-port-rule-spec.md` |
| Architecture | `/Users/loc.tien.nguyen/.claude/plans/mellow-scribbling-mochi.md` |
| Session state / handover | `production/session-state/godot-port-active.md` |
| Commit status | **Nothing committed.** All of `godot/` is untracked. |
| Date of this inventory | 2026-09-18 |

The JS build on `main` is still live in production with real players. The Godot port is the
primary development target; the two are independent until an anti-cheat/replay-verify ADR
exists.

---

## 1. Current state in one line

The full core loop is playable and verified end to end — new run → branching map → combat with
real monsters and bosses → rewards → next node → final boss → run won. Art and UI are largely
in. Audio is wired and audible (2026-09-18). Several JS subsystems are deliberately unported.

**Test suite: 27/27 green**, ~2,700 individual assertions.

---

## 2. Code inventory

| Area | Files | Lines |
|---|---|---|
| `godot/autoload/` | 5 | 1,355 |
| `godot/scripts/core/` | 7 | 3,066 |
| `godot/scripts/data_models/` | 6 | 646 |
| `godot/scenes/` | 13 | 5,012 |
| `godot/tests/` | 24 | 4,009 |

**Autoloads:** `EventBus`, `MetaState`, `ContentDB`, `RunState`, `RelicRegistry`, `AxieMixerBoot`.

**Scenes:** `combat/Combat`, `run_map/RunMap`, `main_menu/MainMenu`, `result/Result`,
`dev_review/DevReview`, `shared/CombatStage3D`, `shared/UnitPortrait`.

### Core modules

| File | Responsibility |
|---|---|
| `scripts/core/combat_engine.gd` | Turn FSM (roll/reroll/execute/end-turn), encounter generation, boss traits, active-relic execution, undo, win/loss |
| `scripts/core/damage_pipeline.gd` | The 13-step `dealDamage()` port, shield/heal, thorns, boss on-damage traits |
| `scripts/core/status_engine.gd` | All 11 status effects, apply + per-turn tick |
| `scripts/core/relic_hooks.gd` | Relic event hooks + the INV-5 `modFace` ordering pass |
| `scripts/core/rng.gd` | mulberry32, bit-exact with `src/engine.js` |
| `scripts/core/run_map_generator.gd` | Branching map graph (path-walking, 10 invariants) |
| `scripts/core/reward_generator.gd` | Post-combat reward cards, shop stock |
| `autoload/RunState.gd` | One run's state: roster, map, relics, boss plan, rewards, phases |
| `autoload/ContentDB.gd` | All static content tables |
| `scripts/data_models/monster_art.gd` | Monster/boss key → Chimera sprite |
| `scripts/data_models/combat_audio.gd` | Combat event → sound file, incl. the sprite-derived voice monsters need (they have no class) |
| `scenes/combat/CombatAudioDirector.gd` | Plays it: owns the Music/SFX buses and the voice pool, listens to EventBus |
| `scenes/shared/BattleBackdrop.gd` | Per-region battle backdrop |

### Tooling (new, all repeatable)

| Tool | What it does |
|---|---|
| `godot/tools/run_tests.sh` | Single entry point; runs both scene tests (`t_*.tscn`) and SceneTree tests (`t_*.gd`) |
| `godot/tools/check_syntax.sh` | Whole-project GDScript syntax preflight, seconds — see the trap in §8 |
| `tools/spine_to_sprites.py` | Converts Spine 3.8 skeletons → flat PNGs (no Spine runtime, no licence) |
| `godot/tools/render_portraits.tscn` | Renders one face portrait per hero class from the 3D rig. Must run **without** `--headless` |

---

## 3. What is built and verified

### 3.1 Combat — faithful to the JS original

Verified line-by-line against `src/engine.js` by three independent audits, then by tests:

- **Turn FSM**: roll → reroll → execute → end turn. Cantrip auto-resolution (6-iteration guard),
  crit decided at roll time, reroll charges with used/heavy/frozen restrictions, free undo.
- **13-step damage pipeline**, in exact JS order: exec threshold → pierce → dmgMult →
  `modDmg` hook → crit → vulnerable → damage reduction → shield absorb → HP → undying →
  `onDmgTaken` → thorns (+ Reptile poison) → `onHit` → death / boss-phase check.
- **Face value chain**: growth, `vital` ×2 at full HP, weaken, boss overdrive ×1.5, blind
  zeroing, hiveMind, Formation Resonance ×1.15 (adjacency by roster index).
- **11/11 status effects**, including the asymmetries: `plague` is enemy-only one-way; burn
  halves unless `burnSlow`; thorns never decays and caps at 8; freeze means
  no-reroll for the player but stun for an enemy.
- **32/32 die-face keywords** handled.
- **6/6 class passives**.
- **RNG**: mulberry32, 10,000/10,000 draws bit-exact with `src/engine.js mkRng(12345)`.
- **Enemy AI intent**: random default, assassin lowest hp+shield, bruiser 50% highest,
  healer weakest ally — with a *stable* tie-break (Godot's `sort_custom` is not stable; ties
  were resolving differently from JS and breaking replay determinism).

### 3.2 Run loop

- Branching map graph (Slay-the-Spire style, a deliberate redesign, not a 1:1 port of JS's
  linear step chain). Short = 18 rows, boss rows 6/12/18. **10 invariants hold over 10,000 seeds.**
- Boss plan picked once per run: `BOSS_ORDER_12/20`, mid bosses 50% swapped against
  `BOSS_ALT`, final boss always `agony`.
- Post-combat rewards with a real choice, reward-set reroll, treasure offering a 3-card pick.
- Events, shop with real JS prices, ascension 0–10.
- Run can be **won** (final boss → `RunPhase.WON`) and **lost** (any combat defeat ends the run).

### 3.3 Content

| Category | In Godot | In JS | Note |
|---|---|---|---|
| Heroes | **18** (6 classes × 3 tiers) | 18 | machine-diffed: 108 die faces, **0 mismatches** |
| Enemies | **21** (incl. 4 elites) | 22 (incl. egg token) | egg token stored separately |
| Bosses | **6** | 6 | all six, with traits |
| Events | **5** | 6 | `merchant` is a shop node here, deliberately |
| Relics | **94** `.tres` (+1 pseudo-relic) | 94 | complete as of 2026-09-18 — see §5 |
| Pools / tables | `normal_pool`, `elite_pool`, `boss_order_12/20`, `boss_alt`, `tier_up` | — | all present |

### 3.4 Art and audio assets (`godot/assets/`, 52 MB)

| Asset | Count | Origin |
|---|---|---|
| Monster/boss sprites | 20 | Axie Origins Kit Chimeras, converted from Spine 3.8 by `tools/spine_to_sprites.py` |
| Web icons | 26 | extracted from `src/art7.js` — the live JS build's own icons, unchanged |
| Body-part icons | 36 | 6 slots × 6 classes, same source |
| Run-map node icons | 6 | — |
| Battle backdrops | 7 scenes | Origins Kit story backdrops, composited |
| Class backgrounds | 7 | Origins Kit (6 classes + shop) — used by the shop/event/crypt overlays |
| Die-card portraits | 6 | rendered from each class's own 3D rig by `tools/render_portraits.tscn` |
| Combat SFX | 78 | 6 classes × 13 attack/phase sounds — wired |
| Status SFX | 35 | 18 mapped, 17 spare — wired |
| Music | 5 | looping; `pve_1/2/3`, `boss`, `home` — wired, picked per node by hash |

### 3.5 UI

- **Combat**: top resource bar (wave + progress track, turn, reroll, shard, mana, undo/info/log),
  per-unit nameplates (name, HP number, HP bar, status pills attached to their owner),
  enemy intent badges (icon + damage + target), dice cards (class badge, name,
  READY/SPENT state, HP, six-face track with the rolled face ringed, big current face),
  per-region backdrop.
- **Main menu**: team picker across the 6 T1 heroes with their full die shown, mode picker,
  ascension 0–10 with live effect text, seed entry.
- **Result**: outcome, run info, progress, shards, relics collected, final roster.

---

## 4. Test suite — 27 tests, all green

| Test | What it proves |
|---|---|
| `t_full_run_loop` | **157 checks / 8 seed-walks.** Walks the real path `start_new_run → map → enter_node → CombatEngine → reward → after_node → … → final boss`. Splits "can the party survive?" (reported, not asserted — a balance question) from "does the loop close?" (asserted) |
| `t_assets` | **356 checks.** Every monster/boss maps to a sprite that loads *and* every sprite has a user; every required icon exists; every die face maps to a real sound; no monster/boss art may share a hero's identity |
| `t_relic_completeness` | **533 checks.** Every relic's `hook_key` resolves to a real `RelicHooks.TABLE` entry declaring exactly the events `src/data.js` declares; no TABLE entry is orphaned; every relic has a description; every active card's `kind` is one `play_active()` actually dispatches |
| `t_meta_progression` | **106 checks.** The Lunacia Pass curve, claiming, the unlock ladder, and — the one that matters — that a RANKED run receives no meta bonus at all, with a counter-check that an unranked run does, so the assertion cannot pass because the code path is never taken |
| `t_run_save` | **154 checks.** Every assertion round-trips through real `JSON.stringify`/`parse_string`, which is the only way to see that integer dictionary keys do not survive a save file; also covers mid-combat resume, a finished run leaving no save, and a wrong-version file being refused without clobbering the live run |
| `t_midcombat_spawn_visuals` | **56 checks.** Opens a real fight, spawns a unit into it, and requires that newcomer to have a nameplate, head HUD, 3D slot, audio voice *and* an HP readout matching the engine — plus no two units sharing a position. Verified to fail (8 failures) with the fix removed |
| `t_relic_behaviour` | **169 checks.** Owns each relic and runs the real `CombatEngine`, requiring an observable difference — the wiring test cannot see a body that throws, and this one caught `r_broodmother` calling a method that does not exist |
| `t_combat_audio_wiring` | **296 checks.** Every enemy and boss ContentDB can spawn resolves to a sound file that exists — the invariant is stated over *content*, not over files, which is why it catches what `t_assets` cannot; the `hit` phase never substitutes the swing; mute reaches the buses, not just the save file; the director builds nothing at all in test mode |
| `t_mod_face` | **280 checks.** The build-time die-mutation pass runs, and its result is independent of relic pickup order (INV-5) |
| `t_content_expansion` | **174 checks.** Content drives the real engine, not a re-implementation |
| `t_event_effects` | **114 checks.** Every option the game *offers* actually *does* something |
| `t_boss_encounters` | **62 checks.** All 6 bosses spawn with correct stats; mecha thorns + overdrive; agony phase 2; gooey_king SPLIT and its cap; frost_lord freeze; mirror copy; pool gating by power level; ascension HP not double-counted |
| `t_map_invariants` | 10,000 seeds × 10 invariants |
| `t_rng` | 10,000 draws bit-exact with JS |
| `t_reward_generator` | 2,000 seeds |
| `t_combat_roundtrip` | 200/200 save/restore round-trips |
| `t_vertical_slice`, `t_combatview_smoke`, `t_stage3d_pick`, `t_stage3d_facing`, `t_run_map_fog`, `t_face_used_log_tag`, `t_axie_parts_smoke`, `t_axie_mixer_smoke` | Integration and smoke coverage |

**Why the test count matters more than it looks.** Before this work the suite was 13/13 green
and *no test had ever traversed the real path* — every test built a `CombatEngine` by hand and
skipped `RunState` entirely. That is how a game where the run could never be won stayed green.
`t_full_run_loop` exists to close that hole.

---

## 5. What is NOT built — with the reason

Nothing in this section is an oversight; each is a recorded decision.

> **This section is not the full list, and long claimed to be.** It never mentioned the
> tutorial, the Codex, enemy-die inspection, the Vault, the leaderboard or account system —
> all at 0%. The complete, measured gap lives in **`docs/godot-port-gap-inventory.md`**
> (2026-09-19). Read that one before concluding anything about what is left.

### 5.1 Not wired, but fully prepared
| Item | State |
|---|---|
| *(empty)* | Both entries that lived here — audio in combat, and class backgrounds for shop/event nodes — were wired on 2026-09-18. |

### 5.2 Content not authored (architecture is ready)
| Item | Gap | Blocked by |
|---|---|---|
| `FACE_POOL` | 0 of 55 faces | Not ported. Removes the `face` (Gene Mutation) reward type, the `casino`/`mutant` events, and 2 shop slots — one of the JS game's two reward axes. **Correction (2026-09-18):** this row previously also claimed the `rune` reward. It does not: `rune` draws from a separate `RUNES` array (`src/data.js:295`) via `pick(RUNES)` (`engine.js:1103-1109`) and never touches `FACE_POOL`. Two different, differently-sized gaps. |

Relics were the other row here until 2026-09-18. All 94 are now authored — see §6 #14 for what
"purely data authoring" actually turned out to mean.

### 5.3 Subsystems not started
| Item | Size of gap |
|---|---|
| **Vault / Axie NFT import** | 0%. JS has `axieToDie`, a 285-identity part-face catalog, coherence/purity, NFT HP bonus, a 20-slot vault, and an import UI. Godot has an empty persisted array. Explicitly requested by the user. |
| Anti-cheat / replay-verify ADR | Required before `godot-port` can be considered for merge into `main` |

### 5.4 Known divergences from JS (deliberate, documented)
- **Undo rewinds the RNG stream; JS does not.** Godot's behaviour is friendlier; JS's is what
  replay-verify expects. Must be resolved in the anti-cheat ADR, not patched casually.
- ~~**Map is 18 rows, JS is 12**, raising difficulty ~34%, not re-tuned.~~ **Re-tuned
  2026-09-19** (wayfinder ticket B). The map is still 18 rows; `TUNE.growth` is now 1.125
  instead of JS's 1.15.
  > The **+34% figure here was wrong**. It read `pw` at the final boss as 18 — the row number —
  > but `power_level` counts nodes *completed*, so it is 17 there. Measured, the final boss was
  > **+47%**, and it was never the worst case: the **mid-boss was +75%**, reached by a party
  > that has not had time to tier up. An unskilled auto-player went from 0 wins / 4 deaths to
  > 2 wins / 2 deaths. Full data at
  > `production/wayfinder/tickets/B-runmap-retune-sim-data.md`.

---

## 6. Bugs found and fixed during this work

Recorded because each represents a class of failure that did not crash and was not caught by
any existing check.

1. **The run could never be won.** `RunPhase.WON` was never assigned anywhere; after the final
   boss the map had no outgoing edges and every button disabled — a hard soft-lock.
2. **Bosses never spawned.** `_generate_encounter()` returned three slimes for boss nodes, so
   `is_boss` was never true and every boss mechanic was unreachable dead code.
3. **Every enemy was a slime.** The pw-gated monster pool and elite pool were unported; six
   already-ported monsters were unreachable data.
4. **Hero tier-up did not exist**, making the run mathematically unwinnable as enemy budget
   climbed. In JS this is the highest-weighted reward.
5. **A boss was one of the player's own heroes.** `gooey_king` used the `pomodoro.glb` model —
   "Pomodoro" is the Bug-class hero in the party. Nothing caught it because code compared
   *keys*, never *identities*.
6. `ContentDB.boss_stats()` wrote `max_hp2` while the pipeline read `hp2` — agony's phase 2
   could never fire.
7. `r_chainreact` detonated on the player's own party, with pierce. JS hits only enemies. The
   code comment described the bug as if it were the spec.
8. Ascension HP was applied twice (budget *and* per-monster): ~2.11× instead of 1.452× at A10.
9. `onTurnStart` never fired on turn 1 — every such relic was one turn late, forever.
10. Enemy targeting used an unstable sort where JS relies on a stable one — ties resolved
    differently, breaking replay determinism.
11. Adding `casino`/`mutant` event data made them reachable while 6 of 14 `fx` had no handler:
    the player picked an option and **nothing happened**, silently.
12. Five SVG icons were extracted with the wrong viewBox (48 vs the web build's 128), so every
    shape fell outside the visible area and the icons rendered as nothing.
13. **Every monster and boss would have been silent.** `CombatAudio.face_sfx_path()` keys off
    the unit's class, but `ContentDB` never sets one for enemies — `Unit.cls` is `""` by
    design — so the lookup returned `""` for all 27 of them: half the blows in a fight making
    no sound. `t_assets` could not catch it: it only ever asks the mapping about the six hero
    classes, proving the type fallback works without ever asking where a monster's class comes
    from. Fixed by deriving the voice from the Chimera sprite the creature already wears, so
    the sound follows the art instead of a parallel table that could drift from it.
14. **"Purely data authoring" was true for 26 of 74 relics, not all of them.** The remaining 48
    each needed a GDScript body in `RelicHooks.TABLE` (23 `modFace`, 25 event hooks). The
    architectural blockers really were gone; the function bodies were never written. Recorded
    because the inventory itself carried the optimistic claim.
15. **74 relics shipped inert and the suite stayed green.** Every new `.tres` named a
    `hook_key` before any TABLE entry existed for it. A missing key is not an error anywhere:
    `mod_face_order()` skips it, `call_hook()` returns null, `fire()` no-ops. The player is
    offered a Legendary, pays for it, and it does nothing. `t_relic_completeness` exists for
    exactly this and failed 48 the moment it was written.
16. **A wiring test is not a behaviour test.** With `t_relic_completeness` green,
    `r_broodmother` was still calling `Unit.set_used()` — the method is `mark_used()`. GDScript
    resolves that at call time on an untyped local, so neither `check_syntax.sh` nor the wiring
    test could see it; the relic would have crashed on the first enemy death.
    `t_relic_behaviour` drives the real engine and caught it.
17. **`sort_index` was one too low on 17 of the first 20 relics.** It is INV-5's tie-break —
    `phase*100000 + rarity*1000 + position in RELICS[]` — and `src/data.js` has not changed
    since the commit that introduced those relics, so the values were simply authored wrong.
    Inert while none of those 20 declared a `modFace`, and live the moment 23 more did.
18. **Units that joined a fight in progress had no visuals at all.** `CombatView` built a
    nameplate, head HUD and 3D slot once, in `_ready()`. Five places add a unit mid-combat —
    gooey_king's SPLIT, a summoner's adds, the `summon` face, the `summon` card, and the
    `r_broodmother` relic, that last one in a different file. A monster would arrive with no
    name, no HP bar, no status pills and no sound, and nothing errored: `_update_portrait()`
    returns quietly for a uid it does not know.
19. **A newly spawned unit's nameplate read `0/0`.** The first version of the fix above built
    the nameplate but did not paint it, so a monster the engine had at 9/9 displayed as an
    empty grey bar — visually "spawned dead". The test was green throughout: it asked whether
    a nameplate existed, never whether it said the right thing. Found only by looking at
    `production/qa/evidence/2026-09-18_midcombat-spawn.png`.
20. **"6 classes x 3 tiers" of portraits would have been 12 duplicates.** The rig has no
    per-tier appearance: `CombatStage3D._build_parts()` uses one fixed part variant and
    `_CLASS_COLOR_VARIANT` is keyed by class alone. Six portraits are rendered, and the die
    card shows the tier as a roman numeral instead — real information rather than a fabricated
    visual difference.
21. **A freshly written PNG is invisible to `ResourceLoader` until the project is re-imported.**
    The six portraits existed on disk and `ResourceLoader.exists()` returned false for every
    one of them, so the game would have drawn nothing. `godot --headless --path godot --import`
    is required after generating any asset.
22. **A saved run would have lost every point of growth.** `Unit.growth` and each roster
    entry's `growth` are keyed by integer face index. JSON has no integer keys, so a save
    wrote `{3: 2}` and read back `{"3": 2.0}`; `growth.get(3)` then missed and returned 0.
    Nothing errored. `t_combat_roundtrip` could not catch it — it round-trips in memory, where
    the types survive — which is why `t_run_save` serialises through real JSON.
23. **A boss changing phase mid-status-tick threw, and silently skipped every unit after it.**
    `DamagePipeline.check_boss_phase()` resets a boss's `status` to `{}`; `StatusEngine`
    then read `u.status["poison"]` directly on the next line. Poisoning agony to death aborted
    the whole tick, so every unit queued behind it lost its burn, regen and decay that turn.
    Pre-existing and unreachable until the difficulty re-tune let runs reach row 18 for the
    first time — a crash that only appears once the game gets *easier* is not one a passing
    suite can be trusted to find.

---

## 7. Invariant rules — do not re-litigate

1. **Monsters and bosses use Chimera art only.** No Axie mascot models. Enforced by
   `t_assets.test_no_monster_or_boss_wears_a_hero_identity()`, which compares identities, not keys.
2. **Icons must match the live web build**, sourced from `src/art7.js` → `godot/assets/icons/web/`.
   Do not substitute Origins Kit icons for status/node/resource/die-face.
3. **Party Axies face away from the camera.** A UI review proposed rotating them to 3/4; the
   user rejected it.
4. HP bar is one continuous bar plus a number, never segmented.
5. RunMap fogs nodes 2+ rows ahead (mystery over full transparency) — RunMap only.
6. Animation and layout take *inspiration* from Shroom & Gloom; they do not copy it.
7. No commits without an explicit instruction.

---

## 8. Traps that have cost real time

- **A GDScript parse error does not make Godot exit.** The script fails to load, `_ready()`
  never runs, nothing calls `quit()`, and the process runs forever — indistinguishable from a
  hung test. Run `./godot/tools/check_syntax.sh` after every `.gd` edit.
- **Screenshots need a real renderer.** Run capture scenes *without* `--headless`; under the
  dummy renderer `get_tree().root.get_texture()` is null.
- **Naive "unused asset" scans lie.** Sound and icon paths are built at runtime from
  `<class>_<action>_<phase>` and `<slot>_<class>`, so the filenames never appear in code. A
  scan reported 23 MB as unused; most of it was live and covered by tests.
- **A new `class_name` needs a project scan** (`godot --headless --path godot --import`) before
  other files can reference it.
- **`Unit.rolled` is an Array**, not an int as in JS. Use `has_rolled()` / `roll_face_index()` /
  `roll_used()` / `current_face()`.
- **Do not `Read` `src/art*.js` or `cosmetics.js`** — megabyte single-line base64. Use `grep -n`.
- **`check_syntax.sh` does not check method names on untyped locals.** `var x = thing()`
  followed by `x.no_such_method()` passes the preflight and throws at call time. Annotate the
  type where you can, and where you cannot, make sure a test actually *calls* the path.
- **Inserting a function in the middle of a file can swallow the rest of the enclosing one.**
  Everything after the insertion point silently becomes part of the new function; the file is
  still valid GDScript, so nothing complains. After inserting into a file, re-read the
  *boundaries* of the function you inserted into, not just the syntax result.

---

## 9. Suggested next steps

Ordered by value, with the reasoning rather than just the order.

1. ~~Wire audio into combat.~~ **Done 2026-09-18.** `CombatAudioDirector` plays attack, hit,
   death, crit, boss-phase and per-status cues off EventBus; Music/SFX buses with a persisted
   mute; battle theme picked per node by hash, never `randi()`. The connection work uncovered a
   real defect, recorded as §6 #13.
2. ~~Author relics.~~ **Done 2026-09-18** — 94/94, plus `t_relic_completeness` and
   `t_relic_behaviour`.
3. **Decide on `FACE_POOL`.** Porting it restores two reward types, two events and two shop
   slots. Not porting it is defensible, but it should be an explicit choice, not a gap.
4. ~~Balance pass on the 18-row map~~ **Done 2026-09-19** (wayfinder ticket B) — `TUNE.growth`
   1.150 → 1.125, chosen against measured auto-player outcomes rather than to match JS on paper.
5. **Vault / NFT import** — user-requested, currently 0%, and large enough to be its own epic.
   Port `part_faces` first: it is SMALL and everything else here depends on it.
6. **Enemy dice are unreadable.** `scUnitInfo` has no Godot equivalent, so a player cannot see
   what an enemy's die holds. Cheapest real improvement to decision-making, and the tutorial
   depends on it. (This list previously skipped the number 6 entirely.)
7. **Anti-cheat / replay-verify ADR** — the gate on ever merging to `main`. A Node VM cannot
   run GDScript, so this is an architecture choice, not a port: see
   `docs/godot-port-gap-inventory.md` §3 for the six options and their trade-offs.
8. **Everything else** — tutorial, Codex, leaderboard, account, run history, daily mission.
   Full measured list in `docs/godot-port-gap-inventory.md`.
