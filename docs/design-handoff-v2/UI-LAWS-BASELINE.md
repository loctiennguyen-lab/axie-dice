# `t_ui_laws` — first honest measurement, 2026-09-20

`godot/tests/t_ui_laws.tscn` now runs and reports. **150 violations.** That number is the point
of this file: until now there was no measurement at all, and every pass was argued from
screenshots.

## Three defects had to be fixed before it could measure anything

The test shipped with FIX-PASS-02 and had never been executed. In order of how badly each one hid
the truth:

1. **It hung instead of failing.** `extends SceneTree` run via `--script` starts Godot *without
   autoloads*, and the test needs `SaveGuard`, which reads `MetaState.SAVE_PATH`. Resolving that
   at script-load time never returns — so the file printed nothing at all, forever. Two processes
   were found stuck at 29 and 18 minutes, and because `run_tests.sh` globs `tests/t_*`, one hang
   took the whole 45-file suite with it. **Fixed** by converting it to a scene test
   (`extends Node` + `t_ui_laws.tscn`), which is what every other autoload-touching test in this
   project already is, for exactly this reason.
2. **Two of its seven laws never ran.** `_check_control()` called
   `Control.get_theme_stylebox_list()` — a **Godot 3** API that does not exist in Godot 4. It
   threw on every Control the walk visited, so the shadow rule and the black-border rule were
   silently skipped while the test still printed a tidy violation total. A test that errors per
   node and reports a clean number is worse than one that fails outright. **Fixed** by listing the
   stylebox keys this project actually uses.
3. **It wrote to the player's real save.** It instantiates `Result.tscn`, whose `_ready()` reaches
   `MetaState.save_to_disk()`. The project's own `t_vault` gate caught this on the first run.
   **Fixed** with `SaveGuard`.

A fourth thing was not a defect in the test but in how it was satisfied: its `PlateHost` and
`Footer` checks used `has_node()`, which does not recurse, and `Combat.tscn` / `RunMap.tscn` have
`Node2D` roots whose real UI lives under `CanvasLayer/Root`. The first response was to add **empty
`PlateHost` and `Footer` Controls** to both scenes purely to turn the assertions green. Those
decoys have been deleted and the checks now search recursively. An assertion that passes against a
node with nothing in it is a test made to lie.

## The baseline

| Scene | L0 no plate | L1 outside safe area | L3 type in combat | L8 type floor |
| --- | --- | --- | --- | --- |
| TeamSelect | | 1 | | **60** |
| Combat | 1 | **23** | 1 | 1 |
| Unlocks | | 14 | | |
| RunMap | | 11 | | 3 |
| Tutorial | | 6 | | |
| Vault | | 3 | | 6 |
| Result | | 5 | | |
| Guides | | 5 | | |
| Settings | | 3 | | |
| Pass | | 3 | | |
| Codex | | 3 | | |
| MainMenu | 1 | | | |

**Zero L7 violations** — no blurred shadow and no non-black border anywhere in twelve scenes.
That is the one thing the last pass did measurably achieve: deleting `panel_style()`,
`BG_PANEL` and `BG_PANEL_SOFT` forced every call site onto `surface_style()`, and the law that
could not be enforced while the old API was callable is now clean on its first real measurement.

## How to read the two big numbers

- **TeamSelect L8 × 60** is one repeated element, not sixty problems: the face-grid labels are set
  at 10px and there are six of them per Axie across five Axies, twice over. One value changed in
  one function clears the whole column.
- **Combat L1 × 23** is the safe-area law meeting a screen that is legitimately full-bleed in
  places. Some of those 23 are real (die cards sitting under the bottom edge — FIX-PASS-02 §6
  calls this out), and some are the law being too blunt: the test's `_is_full_bleed()` exempts
  nodes by NAME (`TopBar`, `DeckBar`, `Content`…), so a legitimately full-bleed child with a
  different name is reported. Triage these before fixing them; do not move a bar to satisfy a
  name list.

## What this changes about how the next pass works

Every previous round was argued from screenshots, which is how four findings in FIX-PASS-01 turned
out to be false positives. There is now a number. A pass that claims to improve the UI should move
it, and a pass that moves it back has broken something — which is the whole reason FIX-PASS-02 §7
asked for this file in the first place.

    Godot --headless --path godot res://tests/t_ui_laws.tscn
