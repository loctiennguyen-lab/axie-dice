---
label: wayfinder:grilling
status: closed
claimed_by: null
blocks: []
blocked_by: []
created: 2026-09-18
closed: 2026-09-19
---

## Resolution

Closed without a grilling session: `docs/godot-port-inventory.md` §5.1 (measured
2026-09-18) shows this was already decided and built before this ticket was written —
118 audio files imported, `CombatAudio.gd` (die-face → sound mapping) written and
covered by `t_assets`'s 356 checks, music loops enabled (`pve_1/2/3`, `boss`, `home`).
No open bus-structure or asset-pipeline question remains.

The only remaining work is connection, not decision: wire `CombatView` to listen to
`EventBus` and play — tracked as execution backlog, inventory §9 item 1 ("Wire audio
into combat... Highest-value remaining work"). See
[map.md Decisions so far](../map.md) for the index entry.

## Question (original, kept for record)

The architecture plan explicitly deferred this: "audio pipeline — các mục này cần
quyết định riêng khi tới đúng bước trong checklist §8" (§9). No decision exists yet for
how audio is authored, imported, or mixed in the Godot port.

The legacy JS build's audio lives inside `client.html` (see
`.claude/docs/technical-preferences.md`'s file-extension routing: "Audio design inside
client.html" → `sound-designer` for design, `gameplay-programmer` for implementation).
There's no equivalent routing or pipeline decision for Godot yet.

Decide, with `audio-director`/`sound-designer` input:

- Bus structure (Godot `AudioStreamPlayer`/bus layout) and how it maps to the event
  stream's 10 event types (rule spec §10) that already drive Tween/FX — does audio
  hook the same `EventBus` signals, or a separate channel?
- Asset format/import pipeline for SFX and music — source format, compression,
  streaming vs. one-shot.
- Whether any of the legacy JS audio assets are reused as-is or need re-authoring.

Not urgent relative to A/C, but currently has zero decision on record, which is exactly
the kind of gap this map exists to surface.
