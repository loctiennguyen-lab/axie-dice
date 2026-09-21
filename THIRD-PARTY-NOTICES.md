# Third-party notices

Axie Dice is MIT licensed (see `LICENSE`). That licence covers the code and original content
in this repository. It does not cover the material listed here, which belongs to its own
authors and is used under its own terms. Anyone forking this project is responsible for
checking those terms for themselves.

## Sky Mavis

### Axie Mixer 3D

`godot/addons/axie_mixer_3d/`, `godot/addons/axie_mixer_3d_assets/`,
`godot/addons/axie_mixer_3d_weapon_anims/`

A Godot 4.7 port of Sky Mavis Axie Mixer 3D 1.1.0. It assembles a rigged, coloured, animated
3D Axie at runtime from a 512-bit gene string, and it is what puts a real imported Axie on the
field instead of a class-coloured stand-in. The rigged meshes, textures, animation clips and
gene catalogue in `axie_mixer_3d_assets` and `axie_mixer_3d_weapon_anims` are Sky Mavis art,
redistributed here only so this project builds and runs.

Upstream: https://github.com/skymavis/godot-axie-mixer-3d

### Axie Origins asset kit

`godot/assets/axie/`, `godot/assets/backgrounds/origins/`, `godot/assets/bosses/`,
`godot/assets/monsters/`, `godot/assets/vfx/`, `godot/assets/cards/`, `godot/assets/icons/`,
`godot/assets/portraits/`

Backgrounds, monster and boss art, skill VFX, card frames and UI icons from the Axie Origins
asset kit. Sky Mavis material.

The monster and boss sprite sheets under `godot/assets/monsters/` are derived work: the kit
ships Spine 3.8 skeletons, no Spine runtime for Godot 4 can read 3.8 data, so the poses were
sampled offline into sheets by `tools/spine_runtime/`. The source art is still Sky Mavis.

### Axie GraphQL gateway

`graphql-gateway.axieinfinity.com`

The public Axie lookup API, read at runtime by the Vault import feature and proxied for web
builds by `api/axie.js`. Read-only, no key, no writes.

## Esoteric Software

### Spine Runtimes (spine-core 3.8)

`tools/spine_runtime/vendor/spine-core-3.8.js`
Licence: `tools/spine_runtime/vendor/SPINE-RUNTIMES-LICENSE.txt`

Used only by the offline asset pipeline, on a developer machine, to read the Origins kit's
Spine 3.8 skeletons and sample them into sprite sheets. It is not imported by the Godot
project, not referenced by any scene, and does not ship in any build of the game. The Spine
Runtimes License requires a Spine licence from the people who use the runtime; that applies to
running the pipeline, not to playing the game.

Upstream: https://github.com/EsotericSoftware/spine-runtimes

## Fonts

`godot/assets/fonts/`, full notice in `godot/assets/fonts/LICENSE.md`

| Family | Weights used | Licence |
| --- | --- | --- |
| Baloo 2 | SemiBold, Bold, ExtraBold | SIL Open Font License 1.1 |
| Work Sans | Medium, SemiBold, Bold | SIL Open Font License 1.1 |

Static instances fetched from Google Fonts on 2026-09-20.
https://scripts.sil.org/OFL

## Engine

Godot Engine 4.7.2, MIT licensed, https://godotengine.org

The engine is not vendored here. You install it yourself to build or run the project.

## Design influences

No code or assets are taken from these; they are named because the design argues with them
and it would be dishonest to pretend otherwise. Slay the Spire (Mega Crit) for the branching
map and the reward cadence. Dicey Dungeons (Terry Cavanagh) for dice as characters. Into the
Breach (Subset Games) for fully telegraphed enemy intent, which is the idea this game is
built around.
