---
name: project-axiedice-verification-baselines
description: Axie Dice Tactics test-suite gotchas — harness loader lists, soak needs build/, verify flakiness root cause
metadata:
  type: project
---

Axie Dice Tactics (vanilla-JS, `build.py` string-concat, no bundler) verification gotchas that
cost real time and are not visible from the code:

- **Node harnesses hardcode their own file list.** `tools/sim.js` and `tools/t_import.mjs` each
  build a `vm` context from an explicit array of `src/*.js` paths. Adding a new `src/` module
  requires editing every harness array too, or the symbol is silently `undefined` and tests
  fail in ways that look like engine bugs.
- **`tools/soak.mjs` / `soakm.mjs` load `build/index.html`**, which `build.py` does not produce
  (it writes to the repo root). Run `python3 build.py public && mv index.html build/index.html`
  first, and symlink `node_modules` if running from outside the worktree.
- **`tools/verify.mjs` needs the repo root served on 5173.** `tools/serve.py` hardcodes an
  absolute path from another machine and will not work — use
  `python3 -m http.server 5173 --directory <worktree>`.
- **`soakm.mjs` reports 5 NOPROGRESS runs on unmodified HEAD.** Pre-existing; not a regression
  signal. Always A/B against a build of HEAD before believing a soak/verify failure.

**Why:** the product owner's standard is "tôi không muốn bị bug hay bị lỗi gì cả, tôi cần một
sự hoàn hảo", so a red check must be diagnosed to root cause, never waved through — but several
of these reds are environmental and will burn a whole session if mistaken for code defects.

**How to apply:** before reporting any suite failure in this repo, reproduce it against a
scratchpad build of `git show HEAD:src/*` to separate pre-existing flake from your change.

Related: [[feedback-large-design-docs]]
