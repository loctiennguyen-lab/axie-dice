---
label: wayfinder:grilling
status: open
claimed_by: null
blocks: []
blocked_by: [A-anti-cheat-replay-verify-strategy]
created: 2026-09-18
---

## Question

Right now "ready to cut `godot-port` over into `main`" is stated qualitatively in
`CLAUDE.md`/`godot-port-active.md` as "feature parity + an anti-cheat/replay-verify
equivalent" — true, but not yet a checklist anyone could run and get a pass/fail
answer from, the way `tools/ci.mjs`'s 12/12 gate does for the live JS build today.

Once [ticket A](A-anti-cheat-replay-verify-strategy.md) settles the anti-cheat/
replay-verify approach, define the actual cutover gate:

- Feature-parity checklist — what's the authoritative list this checks against?
  (`godot-port-active.md`'s "Chưa port" section is the current draft of this, but it's
  a working-session log, not a gate spec.)
- Anti-cheat parity criterion — direct output of ticket A.
- QA sign-off requirement — does this route through the existing `qa-lead`/
  `release-manager` process (`/launch-checklist`, `/release-checklist` skills already
  exist), or does the port need its own variant?
- Rollback plan — if `godot-port` merges into `main` and a critical issue surfaces
  post-cutover, what's the fallback? (Live ranked-leaderboard data continuity is the
  sharp edge here — ties into the "Not yet specified" fog item about post-cutover
  leaderboard history.)
- Who signs off — matches `producer`/`technical-director` per the coordination rules
  in `.claude/docs/coordination-rules.md`, or does this specific cutover need
  creative-director/user sign-off too given it retires the live production build?

This ticket's resolution is effectively the map's destination made testable — treat it
as the capstone, not routine paperwork.
