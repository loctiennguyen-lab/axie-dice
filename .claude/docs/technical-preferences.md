# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine (current/primary, since 2026-09-18)**: **Godot 4.7.2**, GDScript. All new gameplay/
  UI/content work happens under `godot/` on branch `godot-port`. Architecture:
  `/Users/loc.tien.nguyen/.claude/plans/mellow-scribbling-mochi.md`. Rule spec (ported-from
  game rules, verified against the legacy JS source):
  `design/gdd/godot-port-rule-spec.md`. Current status/backlog:
  `production/session-state/godot-port-active.md`.
- **Engine (legacy, still live in production)**: Custom — no game engine/framework. Single
  self-contained HTML file, assembled by string concatenation (`build.py`), no bundler, no
  `node_modules` for the game itself. Vanilla JavaScript (ES6+), DOM+CSS rendering. This is
  the build **currently deployed and serving real players** (ranked leaderboard, etc.) — kept
  running as-is, `main` branch, until the Godot port reaches feature parity and an
  anti-cheat/replay-verify equivalent exists (see the Godot backlog file above). Bugfixes to
  the *live* game, or anything explicitly scoped to `src/`, still target this stack.
- **Rendering (Godot)**: 3D via `godot/addons/axie_mixer_3d*` (Axie/Sapidae characters,
  glTF/GLB), 2D UI/HUD/backgrounds via Control nodes + painted Lunacia art.
- **Rendering (legacy JS)**: DOM + CSS (no `<canvas>`, no WebGL).
- **Physics**: N/A in both — deterministic, turn-based dice-combat roguelike; no physics
  simulation beyond incidental Godot node transforms (no `RigidBody`/collision gameplay).

> **Routing**: default to Godot engine-specialist agents (`godot-gdscript-specialist`,
> `godot-specialist`, plus generic `gameplay-programmer`/`ui-programmer`/`lead-programmer` for
> work that isn't engine-specific) for anything new. Only route to the legacy-JS pattern below
> when a task explicitly targets the live `src/` build.
>
> **Legacy note (pre-2026-09-18, kept for context)**: this project long predated the
> Godot/Unity/Unreal assumption baked into this template's engine-specialist agents, and had no
> `docs/engine-reference/` populated for any engine. That gap is now closed for Godot
> (`docs/engine-reference/godot/`, pinned 4.7.2). See
> `docs/axiedice-source/ORIGINAL_PROJECT_CLAUDE.md` for the legacy JS build/architecture rules
> (still authoritative for `src/` work only).

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: Web / Browser (desktop-first; deploys as a single static HTML file to Vercel/Netlify/S3)
- **Input Methods**: Mouse/touch **click-click** — click a rolled face, then click a legal
  target (`design/gdd/game-concept.md`, EXECUTE step 3) — **and drag-and-drop**, a real
  second input path (`bindDrag()`, `client.html` ~6264+: `pointerdown`/`pointermove`/
  `pointerup` calling straight into the same `clickDie()`/`doTarget()` the click path
  uses). This line said "no drag-and-drop, `grep -c "dragstart\|draggable"` returns 0"
  until 2026-09-08 — true only for the HTML5 native drag API, which this game doesn't
  use; it missed the pointer-events implementation entirely (confirmed while building
  design/gdd/onboarding-tutorial.md, whose step-lock has to block both paths at once).
  `scCodex()`'s own in-game help text already said "Click a die then click a target, or
  drag it straight onto the target" — more accurate than this file was.
- **Keyboard**: Die-select and target-confirm **are now playable by keyboard** (fixed
  2026-09-05). `kbAct()` (`client.html` ~2069) gives `.die`/`.unit`/`.rsel`/`.nodecard`/etc.
  real `tabIndex=0` plus an Enter/Space keydown handler that invokes the element's
  `.onclick` — this already existed, but a global combat shortcut (Enter/Space → END TURN,
  ~line 4349) was ALSO bound on `document` for the same keys: focusing a die/target and
  pressing Enter fired both handlers on the same keydown, so the die/target action was
  silently discarded and the turn ended instead. Fixed by having `kbAct()` call
  `ev.stopPropagation()` after it handles the key — except while `playing` (mid-animation),
  where every `.onclick` above is already a guaranteed no-op and the event must keep
  bubbling to the Space/Enter fast-forward-FX listener (~line 5468). The global
  Enter/Space-ends-turn shortcut still works when nothing is focused. No Q-T target
  hotkeys exist; numeric `1`-`5` still selects party dice directly (unaffected by this,
  it doesn't go through focus/kbAct).
- **Primary Input**: Mouse/touch click-click
- **Gamepad Support**: None
- **Touch Support**: Partial — playable, but phone portrait hides the play field and shows a "rotate your device" prompt (game is landscape-only)
- **Platform Notes**: 3 real breakpoints (1199 / 899 / 599px); `--ui-scale` via `zoom` on `#app` is a final polish layer only, applied when `innerWidth >= 1200`

## Naming Conventions

- **Classes**: N/A (no OOP class hierarchy — `engine.js` is pure functions over plain data)
- **Variables**: `camelCase`
- **Signals/Events**: `engine.js` emits a flat event stream `s.ev` (array of typed events: damage, shield, poison, death, …); the `fx.js` section of `client.html` replays it for animation without re-rendering. Any new mechanic that doesn't emit an event will be numerically correct but invisible to the player.
- **Files** (merged 2026-09-03 — 10 source files became 6): lowercase. All client
  code lives in **one** file, `src/client.html` (CSS + audio/icons/log/ui/fx, with
  `/* ─── name.js ─── */` markers kept at the old module boundaries). Four files
  deliberately stay outside it — the reasons are in the comment at the top of
  `client.html`, read it before merging anything else in:
  - `src/engine.js`, `src/data.js` — `api/_engine.js` reads both from disk into a
    Node VM to replay-verify Leaderboard scores (server-side anti-cheat);
    `tools/sim.js` and `tools/t_import.mjs` read them directly too.
  - `src/devtools.js` — `build.py public` STRIPS this file. `devGo()` can jump to
    any screen and grant `META.shards=900` + relics/legendaries, so merging it in
    would ship a cheat toolkit in production while ranked Leaderboard is live.
  - `src/art.js`, `src/cosmetics.js` — 1.8MB of pure base64 (`art.js` is a single
    232,878-character line). Never hand-edited; merging them in would only make
    every read of the working file cost context for nothing.
- **Scenes/Prefabs**: N/A — the `ui.js` section of `client.html` re-renders each screen (`sc*` functions) fully on every state change
- **Constants**: CSS design tokens use `--kebab-case` (e.g. `--t1..--t6`, `--die-num`); the removed `--faint` token must never be reintroduced

## Performance Budgets

- **Target Framerate**: 60fps UI interactions (DOM-based, no fixed simulation tick)
- **Frame Budget**: N/A (not frame-simulated; turn/event driven)
- **Draw Calls**: N/A (DOM/CSS rendering, not a GPU-batched renderer)
- **Memory Ceiling**: [TO BE CONFIGURED — no budget documented yet; `art.js` sprite data is ~230KB as a single line]

## Testing

- **Framework**: Custom Node scripts in `tools/` — no test runner framework (no Jest/Vitest). **`tools/ci.mjs` is the single entry point** — it runs all 11 gates; use it rather than invoking suites individually, which is how three suites once rotted unnoticed. `tools/verify.mjs` checks the UI rules; `tools/gen_faces.mjs` derives every part-face value and enforces its invariants; `t_relic.mjs`, `t_partskill.mjs`, `t_vault.mjs`, `t_relic_behaviour.mjs` cover the relic and vault systems; `soak.mjs`/`soakm.mjs` run extended-play soaks; `sim.js` is a headless balance probe.
- **Minimum Coverage** *(measured 2026-09-08, not copied)*: `node tools/ci.mjs` must be **12/12**. `verify.mjs` **72/72** (grew from 65 when `docs/gdd/onboarding-tutorial.md`'s `devGo('tutorial')` screen coverage was added) · `t_partskill` 44/0 · `t_import` 43/0 · `t_vault` 8/0 · `t_tutorial` 28/0 (new gate, design/gdd/onboarding-tutorial.md) · `t_relic_behaviour` 38 proofs · `t_relic` 94/94 INV-1 · `gen_faces --check --strict` GREEN on both profiles. Never regress.
  > ⚠️ The figure here was **29/30 and wrong** until 2026-09-04 — the suite had grown to 32 and then 37 while the doc stood still. A stale floor does not merely misinform; it **authorises a real regression to pass review**. If you change the suite, change this line in the same commit.
- **Prerequisites** (both have cost hours before): `npm install` is required — without it `verify`/`t_aoe`/`t_fit` fail on `import { chromium } from 'playwright'`, which reads like three broken suites rather than one missing dependency. And `verify.mjs` needs a **served build**: `python3 build.py`, serve the repo root on port 5173, then pass `--url http://localhost:5173/AxieDiceTactics.html`. Run bare it gives `ERR_CONNECTION_REFUSED`, which looks like a code failure and is not.
- **Required Tests**: Balance formulas (engine.js combat math), UI rule compliance (contrast, tap targets, no layout shift, no `undefined`/`NaN` leaks — see the 8 UI rules in `docs/axiedice-source/ORIGINAL_PROJECT_CLAUDE.md`), soak tests after any change touching `.die`/`.unit` element lifecycle (known regression source for drag/drop)

## Test Floor — Godot port (`godot-port` branch)

- **`godot/tools/run_tests.sh` must be 39/39.** Measured 2026-09-19, not copied. It runs every
  `godot/tests/t_*.tscn` headless and fails on a non-zero exit, a `SCRIPT ERROR`, a `Parse
  Error`, an explicit FAIL, or a missing PASS.
- Notable gates and their sizes: `t_replay` **47 checks** (action log + combat replay + full-run
  replay through `RunVerifier` + seven tamper injections) · `t_rules_version` (fingerprints the
  17 rule files so `ActionLog.RULES_VERSION` cannot be silently left behind) · `t_full_run_loop`
  **197 checks** across 8 seed-walks · `t_assets` 457 · `t_codex` 71 ·
  `t_tutorial_flow` 43 · `t_vault` 275 · `t_axie_api` 98.
- Change the suite, change this number **in the same commit**. The JS half of this document
  already records what a stale floor costs: it does not merely misinform, it **authorises a
  real regression to pass review**.
- ⚠️ A GDScript parse error makes a headless run **hang** instead of failing. Run
  `Godot --headless --path godot --import` first; a new `class_name` is also invisible until
  that import registers it.

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: `lead-programmer` (no `godot-*`/`unity-*`/`ue-*` specialist applies — this is a hand-rolled vanilla-JS/HTML5 project, not a commercial engine)
- **Language/Code Specialist**: `gameplay-programmer` (`engine.js` combat rules, `data.js`), `ui-programmer` (`client.html` — CSS + UI + FX all in one file)
- **Shader Specialist**: N/A — no shaders (DOM/CSS rendering only)
- **UI Specialist**: `ui-programmer` for implementation; `ux-designer` / `art-director` for spec and visual review
- **Additional Specialists**: `accessibility-specialist` (open a11y debt — see HANDOVER §2), `technical-artist` for `art.js`/`cosmetics.js` sprite data if visual fidelity work is needed
- **Routing Notes**: No engine reference docs apply (`docs/engine-reference/godot/` is irrelevant to this project). Skip any skill step that checks engine-version knowledge gaps.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code — `engine.js`, `data.js` | `gameplay-programmer` |
| Client code — `client.html` (CSS + UI + FX + audio + icons + log) | `ui-programmer` (+ `art-director` for visual review of the CSS half) |
| Audio design inside `client.html` | `sound-designer` (design) / `gameplay-programmer` (impl) |
| `art.js`, `cosmetics.js` (sprite/cosmetic data) | `technical-artist` |
| `devtools.js` (kept separate — stripped from public builds) | `tools-programmer` |
| `build.py`, `tools/*` (build & verify scripts) | `devops-engineer` / `tools-programmer` |
| Shader / material files | N/A — none in this project |
| Scene / prefab / level files | N/A — no scene system; screens are `sc*` functions in `client.html` |
| Native extension / plugin files | N/A |
| General architecture review | Primary (`lead-programmer`) |
