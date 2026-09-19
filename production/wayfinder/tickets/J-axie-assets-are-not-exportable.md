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

---

## MEASURED 2026-09-20 — option A does NOT work. Cross it off.

Done on a copy of the project, not the real one. Deleting `.gdignore` and importing:

| | |
|---|---|
| Import time | **28 seconds**, 744/744 GLBs, no errors |
| `.godot` cache | 51MB → **123MB** |
| Exported pck | 41MB → **113MB** |
| `catalog.json` in pck | **yes** (that is why the console error changed) |
| **Raw `.glb` in pck** | **NO** |
| **Can the build make an Axie?** | **NO** |

Asked the exported package itself, because a filename appearing in a pck proves a reference
exists, not that the bytes came along:

```
PROBE catalog_exists=true
PROBE first_glb_in_catalog=bodies/Normal.glb
PROBE glb_exists=false
ERROR: AxieCatalog: cannot load scene res://addons/axie_mixer_3d_assets/bodies/Normal.glb
PROBE axie_built=false
```

**Why A fails, and it is not a detail.** `AxieCatalog.load_scene()` parses glTF at runtime with
`GLTFDocument.append_from_file()`, which needs the **original .glb**. Godot's exporter, for an
imported .glb, ships the *imported* `.scn` and drops the source. So importing the pack replaces
the file the addon reads with a file the addon cannot read. The addon's own comment says why
`.gdignore` is there in the first place:

> "Always parse the glb at runtime. The pack directory carries a .gdignore so the editor never
> imports it: the editor importer applies its own settings (track optimisation, mesh
> compression) and would make editor and exported builds diverge from the verified path."

So `.gdignore` is load-bearing, not an oversight. It also traps the obvious fix: with it in
place `include_filter` cannot see the files either, because the folder is invisible to the
resource system before any filter runs. **That is the real shape of this problem** — the assets
must reach the pck as RAW files while staying unimported, and Godot's two mechanisms for
"include this" and "do not import this" are wired to the same switch.

Remaining directions, none measured yet:
- **A2** — a per-file "keep file" import mode, if Godot 4.7 offers one for glTF, so the source
  ships unimported. Cheapest if it exists.
- **B** — ship the pack beside the build and load it from `user://`; web downloads it once.
  The addon already reads with `FileAccess`, and its own header says runtime parsing "works
  headless and from `user://`", so this may be closer than it looks.
- **E (new)** — an extension the importer ignores (`.glb.bin`), included by filter, with the
  catalog's paths adjusted. Ugly, cheap, and keeps the vendor's verified runtime path exactly.

## What still works in an exported build, measured in the same probe

The Vault's ARITHMETIC is untouched by any of this: `part_faces.json` ships, and
`AxieToDie.build()` returned `faces=6 hp=12 purity=3` inside the export — the same numbers
Axie #123 produces on the desktop. An imported Axie in an exported build would be
**mechanically correct and visually absent**. That is a different bug report than "Import Axie
is broken", and the difference matters to whoever picks this up.

Blocks [ticket H](H-cutover-acceptance-gate.md): "the web export builds clean" cannot be ticked
while the thing it builds cannot draw a character.
