---
label: wayfinder:grilling
status: open
claimed_by: null
blocks: [H-cutover-acceptance-gate]
blocked_by: []
created: 2026-09-20
---

## Question

`godot/addons/axie_mixer_3d_assets/.gdignore` hides 249MB / 2,211 files / 744 GLBs — every Axie
body part — from Godot's resource filesystem. That is why the editor is fast and why **no
export contains a single Axie asset**. Measured 2026-09-20 on the project's first-ever export:
the web build boots, and the console says
`AxieCatalog: catalog not found at res://addons/axie_mixer_3d_assets/catalog.json`.

It is not a bug in the vendor's addon. Importing 744 GLBs is genuinely slow and generates a
large import cache, and loading them from disk at runtime is a reasonable choice for an addon
used inside the editor. It is simply incompatible with shipping a build, and nobody noticed
because nobody had exported before.

Decide how the Axie assets reach a player. Options, with what each costs:

| | Approach | Gains | Costs |
|---|---|---|---|
| A | Delete `.gdignore`, let Godot import all 744 GLBs | Everything works the normal way; one change | Long import; large `.godot` cache; slower CI; the measurement of "how long, how big" is the open question |
| B | Keep `.gdignore`, ship the folder beside the build and load it at runtime | No import cost | A web build has no filesystem — the addon would have to fetch over HTTP and parse glTF from bytes. Real work, and it is work inside someone else's addon |
| C | Import only the subset the game uses | Small pck, fast import | Import-Axie exists specifically to build ARBITRARY Axies; a missing rare part is exactly the case `AxiePartResolver` refuses to fake |
| D | A + trim what ships per platform | Best result | Most work |

Whoever takes this should answer with numbers, not preference: A is measurable in an afternoon
(copy the project, delete the file, time the import, read the cache size, export, open it).

Blocks [ticket H](H-cutover-acceptance-gate.md): "the web export builds clean" cannot be ticked
while the thing it builds cannot draw a character.
