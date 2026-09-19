---
label: wayfinder:task
status: open
claimed_by: null
blocks: []
blocked_by: []
created: 2026-09-18
---

## Question

HITL task — needs the user, not just an agent. From `godot-port-active.md`: the user
said the JS build's boss art (e.g. Chimera) is placeholder-quality and will supply real
assets from a shared Drive folder
(`1RjgfuL5t0yuGNbyYtitVQtw63bew1eGr`, containing `1. Character`, `2. Equipment`,
`3. Environment/Props`, `Nightmare Realm Map`, `NPC Playtest 2`). Interim guidance
already given: handle normal monsters first, boss art later once supplied.

Checklist for the user (or an agent with Drive access, if the connected Drive account
has access to this specific folder — check before assuming HITL is required):

- [ ] Confirm which of the 5 subfolders are ready to pull now vs. still in progress.
- [ ] Pull/export the needed files into `assets/_incoming/` (there's already a
      convention for this — see `assets/_incoming/origins-kit-full/`,
      `assets/_incoming/lunacia-terrain-art-2026-09-17/`, etc. — follow the existing
      naming pattern, dated where the source dumps are dated).
- [ ] Note which files map to which boss/character (the mapping isn't obvious from
      filenames alone in past drops per the audit notes).

Resolve with: what was pulled, where it landed under `assets/_incoming/`, and what's
still pending from the user. This unblocks final visual-parity sign-off for Phase 2,
not the architecture work — nothing else on this map depends on it.
