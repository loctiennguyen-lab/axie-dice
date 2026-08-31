# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Custom — no game engine/framework. Single self-contained HTML file, assembled by string concatenation (`build.py`), no bundler, no `node_modules` for the game itself.
- **Language**: Vanilla JavaScript (ES6+), no TypeScript, no framework (no React/Vue/etc.)
- **Rendering**: DOM + CSS (no `<canvas>`, no WebGL)
- **Physics**: N/A — deterministic, turn-based dice-combat roguelike; no physics simulation

> **Deviation from template default**: this project predates the Godot/Unity/Unreal
> assumption baked into this template's engine-specialist agents. There is no
> `docs/engine-reference/` for it and no engine-specialist subagent applies. Route
> code work to generic agents (`gameplay-programmer`, `ui-programmer`, `lead-programmer`)
> instead of `godot-*`/`unity-*`/`ue-*` specialists. See `docs/axiedice-source/ORIGINAL_PROJECT_CLAUDE.md`
> for the authoritative build/architecture rules (source-of-truth import).

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: Web / Browser (desktop-first; deploys as a single static HTML file to Vercel/Netlify/S3)
- **Input Methods**: Mouse (drag-and-drop dice onto targets) primary; touch supported; keyboard accessibility in progress (Tab focus, Q–T target hotkeys — see HANDOVER §2, not yet complete)
- **Primary Input**: Mouse/touch drag-and-drop
- **Gamepad Support**: None
- **Touch Support**: Partial — playable, but phone portrait hides the play field and shows a "rotate your device" prompt (game is landscape-only)
- **Platform Notes**: 3 real breakpoints (1199 / 899 / 599px); `--ui-scale` via `zoom` on `#app` is a final polish layer only, applied when `innerWidth >= 1200`

## Naming Conventions

- **Classes**: N/A (no OOP class hierarchy — `engine.js` is pure functions over plain data)
- **Variables**: `camelCase`
- **Signals/Events**: `engine.js` emits a flat event stream `s.ev` (array of typed events: damage, shield, poison, death, …); `fx.js` replays it for animation without re-rendering. Any new mechanic that doesn't emit an event will be numerically correct but invisible to the player.
- **Files**: lowercase, one module per concern (`engine.js`, `ui.js`, `fx.js`, `data.js`, `audio.js`, `icons.js`, `art.js`, `devtools.js`, `style.css`)
- **Scenes/Prefabs**: N/A — `ui.js` re-renders each screen (`sc*` functions) fully on every state change
- **Constants**: CSS design tokens use `--kebab-case` (e.g. `--t1..--t6`, `--die-num`); the removed `--faint` token must never be reintroduced

## Performance Budgets

- **Target Framerate**: 60fps UI interactions (DOM-based, no fixed simulation tick)
- **Frame Budget**: N/A (not frame-simulated; turn/event driven)
- **Draw Calls**: N/A (DOM/CSS rendering, not a GPU-batched renderer)
- **Memory Ceiling**: [TO BE CONFIGURED — no budget documented yet; `art.js` sprite data is ~230KB as a single line]

## Testing

- **Framework**: Custom Node scripts in `tools/` — no test runner framework (no Jest/Vitest). `tools/verify.mjs` checks the 8 UI rules below; `tools/soak.mjs` / `tools/soakm.mjs` run extended-play regression soaks (desktop/mobile pointer paths); `tools/sim.js` is a headless engine simulator.
- **Minimum Coverage**: `verify.mjs` must hold at 29/30 checks passing or improve — never regress
- **Required Tests**: Balance formulas (engine.js combat math), UI rule compliance (contrast, tap targets, no layout shift, no `undefined`/`NaN` leaks — see the 8 UI rules in `docs/axiedice-source/ORIGINAL_PROJECT_CLAUDE.md`), soak tests after any change touching `.die`/`.unit` element lifecycle (known regression source for drag/drop)

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
- **Language/Code Specialist**: `gameplay-programmer` (`engine.js` combat rules, `data.js`), `ui-programmer` (`ui.js`, `fx.js`, `style.css`)
- **Shader Specialist**: N/A — no shaders (DOM/CSS rendering only)
- **UI Specialist**: `ui-programmer` for implementation; `ux-designer` / `art-director` for spec and visual review
- **Additional Specialists**: `accessibility-specialist` (open a11y debt — see HANDOVER §2), `technical-artist` for `icons.js`/`art.js` sprite data if visual fidelity work is needed
- **Routing Notes**: No engine reference docs apply (`docs/engine-reference/godot/` is irrelevant to this project). Skip any skill step that checks engine-version knowledge gaps.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code — `engine.js`, `data.js` | `gameplay-programmer` |
| Game code — `ui.js`, `fx.js` | `ui-programmer` |
| `style.css` | `ui-programmer` + `art-director` (visual review) |
| `audio.js` | `sound-designer` (design) / `gameplay-programmer` (impl) |
| `art.js`, `icons.js` (sprite/icon data) | `technical-artist` |
| `build.py`, `tools/*` (build & verify scripts) | `devops-engineer` / `tools-programmer` |
| Shader / material files | N/A — none in this project |
| Scene / prefab / level files | N/A — no scene system; screens are `sc*` functions in `ui.js` |
| Native extension / plugin files | N/A |
| General architecture review | Primary (`lead-programmer`) |
