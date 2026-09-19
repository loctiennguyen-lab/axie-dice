---
label: wayfinder:grilling
status: resolved
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

---

## Resolution (2026-09-19)

**Headless Godot on a server is the referee** — option A. Full reasoning, costs (~$4–6/month for
one small Linux box) and the two sub-decisions this ticket demanded are in
[ADR-0004](../../../docs/architecture/adr-0004-headless-godot-is-the-referee.md):

- **Undo divergence: accepted as-is, no fix.** It only matters if two rule sets must agree
  bit-for-bit — i.e. under option C. With the Godot build judging itself, rewinding the RNG on
  undo *is* the rule, and it is the stricter one.
- **ENGINE_VERSION equivalent: required and built.** `ActionLog.RULES_VERSION` +
  `content_version` from part_faces.json, with `t_rules_version` refusing to let the constant
  fall behind the files.

Built and measured in the same session: `ActionLog`, `RunVerifier`, `tools/verify_run.tscn`,
`tools/record_sample_run.tscn`, `RunBot`; run-level replay unblocked by moving shop/event RNG
ownership into `RunState`. A whole run (seed 991237, 391 actions) verifies to the same score
across a process boundary, and seven tamper injections are refused.

Unblocks [ticket H](H-cutover-acceptance-gate.md) → `production/cutover-gate.md`.
