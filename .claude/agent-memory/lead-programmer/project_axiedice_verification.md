---
name: project-axiedice-verification-baselines
description: Axie Dice Tactics test-suite gotchas — ci.mjs is the entry point, harnesses hardcode src paths (incl. source-text assertions), soak needs build/
metadata:
  type: project
---

Axie Dice Tactics (vanilla-JS, `build.py` string-concat, no bundler) verification gotchas that
cost real time and are not visible from the code:

- **`tools/ci.mjs` is the single entry point** and does the build + serve dance for you
  (11 steps). Prefer it over invoking suites by hand. It needs `npm install` first.
  `--fast` skips the browser suites.
- **Node harnesses hardcode `src/` paths, in TWO different ways** — both break on a file
  move and both fail in ways that look like logic bugs:
  1. `tools/sim.js`, `tools/t_import.mjs`, `t_relic*.mjs` build a `vm` context from an
     explicit array of `src/*.js`. A new `src/` module must be added to every array or the
     symbol is silently `undefined`.
  2. `tools/t_relic_behaviour.mjs` `readFileSync`s a source file and regex-asserts over its
     TEXT (proving `migrateMeta()` is wired into `loadMeta`). A refactor that moves code
     between files keeps behaviour correct but makes this throw ENOENT.
- **`tools/verify.mjs` needs the repo root served on 5173.** `tools/serve.py` hardcodes an
  absolute path from another machine and will not work — use
  `python3 -m http.server 5173 --directory <worktree>`. Run bare it gives
  ERR_CONNECTION_REFUSED, which reads like a code failure and is not.
- **`tools/soak.mjs` / `soakm.mjs` load `build/index.html`**, which `build.py` does not
  produce (it writes to the repo root). `soakm.mjs` reports 5 NOPROGRESS runs on unmodified
  HEAD — pre-existing, not a regression signal.
- **`tools/known-failures.json` is two-sided**: a declared failure that STOPS occurring
  breaks the build as STALE. After merging someone else's fix, re-check the allowlist.

**Why:** the product owner's standard is "tôi không muốn bị bug hay bị lỗi gì cả, tôi cần một
sự hoàn hảo", so a red check must be diagnosed to root cause, never waved through — but several
of these reds are environmental and will burn a whole session if mistaken for code defects.

**How to apply:** before reporting any suite failure in this repo, reproduce it against a
scratchpad build of `git show HEAD:src/*` to separate pre-existing flake from your change.
Baselines as of 2026-09-04 (post main-merge): ci 11/11, verify 37/37 (stable over 4 runs),
`sim.js 300` 18.3%, `sim.js 300 vault=5` 26.7%, `gen_faces --check --strict` GREEN on both
profiles. Note `.claude/docs/technical-preferences.md` still cites an old "29/30" verify
floor — that number is stale.

Related: [[feedback-large-design-docs]]
