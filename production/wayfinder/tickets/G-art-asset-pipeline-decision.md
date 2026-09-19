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

Closed without a grilling session: `docs/godot-port-inventory.md` §3.4 (measured
2026-09-18) shows the game-content art pipeline is already decided and built —
monster/boss sprites via `tools/spine_to_sprites.py` (Spine 3.8 → flat PNG, no runtime/
licence needed), icons extracted from `src/art7.js` into `godot/assets/icons/web/`,
backdrops composited from the Axie Origins Kit. 52MB of assets, gated by `t_assets`
(356 checks: every sprite loads and has a user, every required icon exists, no
monster/boss art shares a hero's identity).

The one piece this ticket raised that is **not** covered: whether/when `cosmetics.js`
(Echo Box gacha cosmetics — a live-JS-only meta-progression system) gets ported at all.
That's narrower and not yet decidable (unclear it belongs in this port's scope), so it
moved to the map's "Not yet specified" fog instead of staying a ticket — see
[map.md](../map.md).

## Question (original, kept for record)

The architecture plan explicitly deferred this: "pipeline chuyển `art.js`/
`cosmetics.js` base64 sang texture/atlas Godot" (§9). Note this is distinct from and
narrower than the 3D character pipeline, which is already decided (CLAUDE.md:
`godot/addons/axie_mixer_3d*` for Axie/Sapidae characters via glTF/GLB, painted
Lunacia art for 2D UI via Control nodes) — this ticket is specifically about the
**2D legacy asset data** currently trapped as base64 in `src/art.js`/`src/cosmetics.js`
(per `.claude/docs/technical-preferences.md`: `art.js` is a single 232,878-character
line, never hand-edited).

Decide:

- Does anything in `art.js`/`cosmetics.js` need porting at all, or does the Godot 2D
  UI layer (icons, portraits — see `godot/assets/icons/`, `godot/assets/portraits/`)
  get entirely fresh-authored assets instead, making this base64 data JS-legacy-only
  and out of scope for the port?
- If porting is needed: batch-decode-and-convert tool (similar in spirit to the relic
  `data.js → .tres` converter checked into `tools/` and run in CI, per architecture
  plan §6) vs. one-time manual export.
- Where converted assets land — existing convention is
  `godot/assets/{portraits,icons,backgrounds,monsters}/` plus
  `assets/_incoming/icon-set-2026-09-08-stripped/` as a landing zone; confirm this
  ticket's output follows that or needs a new subfolder.

Resolving this may make it moot (answer could simply be "not needed, 3D+fresh-2D
already covers it") — that's a valid resolution, not a cop-out, as long as it's stated
explicitly rather than left silent.
