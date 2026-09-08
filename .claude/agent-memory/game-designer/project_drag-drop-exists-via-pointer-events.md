---
name: drag-drop-exists-via-pointer-events
description: technical-preferences.md's "no drag-and-drop, grep dragstart|draggable=0" claim is misleading — a full custom pointer-event drag-and-drop path (bindDrag/dragging/pointerup->doTarget) exists and is fully functional alongside click-click.
metadata:
  type: project
---

`.claude/docs/technical-preferences.md` states: "There is no drag-and-drop:
`grep -c "dragstart\|draggable" src/client.html` returns 0" and calls click-click
"the core interaction." That grep is technically correct but tests the wrong thing —
it only checks for the native HTML5 drag API (`dragstart`/`draggable` attribute).
The actual code uses a **hand-rolled pointer-event drag implementation** that the
native-API grep can never find:

- `function bindDrag()` (~line 6264): on `.diebox .die` pointerdown, starts a
  `dragging={uid,x0,y0,moved,el,need}` state (guarded by `!playing && !rollAnim`).
- `document.addEventListener('pointermove', ...)` (~line 6283): once moved >7px,
  adds `.dragging` to body, shows an aim-line (`aimShow`), highlights `.unit.tgt`
  under the pointer via `.hovtgt`.
- `document.addEventListener('pointerup', ...)` (~line 6295): on release over a
  valid `.unit.tgt`, calls the SAME `doTarget(+t.dataset.uid)` that a click-click
  target-confirm calls — this is a fully real, working alternate input path, not
  just cosmetic. A short pointerdown-then-up-without-move (`!d.moved`) falls back
  to normal click-to-select/click-to-use behavior, so click-click and drag are two
  paths into the same functions, not competing systems.
- `postRender()` calls `bindDrag()` on every render (~line 3163), so it's live on
  every combat screen, not experimental/hidden.

**Why this matters:** any task briefing (including the 2026-09-08 tutorial-design
task) that says "no drag-and-drop, confirmed by grep" is repeating a stale/incomplete
claim baked into `technical-preferences.md` — which is loaded into every session via
CLAUDE.md, so it will keep misinforming agents until the doc itself is corrected.
Same category of issue as [[dawn-dusk-mech-identity-gap]] and
[[class-passive-already-universal]] — a project doc that doesn't match running code.

**How to apply:** before designing or describing the EXECUTE-step interaction (or
any input-method assumption), verify against `bindDrag`/`dragging`/`pointerup` in
`src/client.html`, not just the dragstart/draggable grep. Any tutorial, onboarding
copy, or UX spec describing "how to attack" should teach or at least not contradict
BOTH click-click and drag-to-target, since both are real, working, and already used
in in-game reference text (`scCodex()` CX_BODY 'basic' tab already says "Click a die
then click a target, or drag it straight onto the target" — the in-game text is
actually more accurate here than the project's own technical-preferences.md).
Consider flagging technical-preferences.md itself for a correcting edit next time
it's touched (not done in this session — this was a discuss-only pass, no files
written to src/ or .claude/docs/).
