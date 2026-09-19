---
label: wayfinder:grilling
status: open
claimed_by: null
blocks: [H-cutover-acceptance-gate]
blocked_by: []
created: 2026-09-18
---

## Question

Today, ranked-leaderboard integrity on the live JS build works because the server
(`api/_engine.js`) loads the real `src/engine.js`/`src/data.js` from disk into a Node
VM and replays a submitted run to verify the score independently of the client. Once
gameplay logic lives in GDScript inside a compiled Godot build, that mechanism no
longer applies as-is.

Decide: what does server-side replay-verify look like for the Godot build? Candidate
directions to weigh with the user (not exhaustive — surface more if they come up):

- Run a headless Godot export on the server and replay the action log through it.
- Maintain a second, pure-logic reimplementation of the combat rules (e.g. in a
  server-friendly language) kept in lockstep with GDScript — mirrors today's
  JS-on-server approach but doubles maintenance surface.
- Some hybrid: keep `CombatEngine`'s core/ logic engine-agnostic enough (already a
  stated goal — `core/` never touches the Node/Control tree) that it could compile or
  run outside Godot for server verification.
- Accept a different trust model for the Godot build (e.g. different anti-cheat
  posture) if the user is open to that — but this needs to be an explicit choice, not
  a silent gap.

Also needs an answer: the [architecture plan](/Users/loc.tien.nguyen/.claude/plans/mellow-scribbling-mochi.md)
already flagged that the undo semantics diverge between JS (RNG stream not restored on
undo) and Godot (snapshot-restore, which *does* restore RNG) — this ticket's resolution
must state whether that divergence is acceptable under the chosen verify strategy, or
needs its own fix.

This ticket's resolution should become (or directly inform) the two ADRs the
architecture plan says are still owed: the overall port architecture ADR and the
RNG/determinism ADR — check `docs/architecture/` for whether those exist yet before
writing new ones.

Blocks [ticket H](H-cutover-acceptance-gate.md): the cutover gate can't state its
anti-cheat-parity criterion until this is decided.
