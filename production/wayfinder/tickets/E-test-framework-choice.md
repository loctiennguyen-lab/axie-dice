---
label: wayfinder:grilling
status: open
claimed_by: null
blocks: []
blocked_by: []
created: 2026-09-18
---

## Question

The architecture plan explicitly deferred this: "Không quyết định ngay: GUT vs gdUnit4
cho test framework" (§9). Right now the project has hand-rolled headless test scripts
(`godot/tools/run_tests.sh`, `t_*.gd`/`t_*.tscn`) that work but don't use either
framework.

Decide: adopt GUT or gdUnit4, or keep the current hand-rolled `run_tests.sh`
convention indefinitely? Consider:

- Migration cost for the existing gates (`t_rng.gd`, `t_map.gd`, `t_full_run_loop.gd`,
  `t_boss_encounters`, `t_mod_face`, `t_event_effects`, etc.) — are they cheap to
  wrap, or does adopting a framework mean a rewrite?
- Whether either framework changes how `godot --headless --script` gates run in CI
  (root `.claude/docs/coding-standards.md` already names
  `godot --headless --script tests/gdunit4_runner.gd` as the Godot CI convention for
  this template — check whether that's a real constraint or just a template default
  that hasn't been reconciled with this project's actual `run_tests.sh` yet).
- Reporting/assertion ergonomics for the team actually writing these tests.

Low-stakes, self-contained — good candidate to resolve quickly once picked up.
