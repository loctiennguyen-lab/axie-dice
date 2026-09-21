<p align="center">
  <h1 align="center">Axie Dice</h1>
  <p align="center">
    <i>Lunacia Mutants</i>
    <br />
    A deterministic tactical roguelike. Every Axie is a six-sided die, and every face is a body part.
  </p>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/engine-Godot%204.7.2-478cbf?logo=godotengine&logoColor=white" alt="Godot 4.7.2">
  <img src="https://img.shields.io/badge/language-GDScript-355570" alt="GDScript">
  <img src="https://img.shields.io/badge/tests-53%2F53-brightgreen" alt="53 of 53 tests pass">
</p>

## The game

Axie genetics map onto a die almost exactly: one Axie has six body parts, one die has six
faces. So that is what an Axie is here. Eyes, Ears, Mouth, Horn, Back, Tail, one per face,
each with its own action and value drawn from that Axie's real class and parts.

You pick five Axies, roll all five dice at once, reroll the faces you don't want, then spend
each face on a target. The enemies roll first and show you exactly what they are about to do
and to whom. Nothing in combat is hidden.

That is the bet the game makes. Slay the Spire and Dicey Dungeons both build tension out of
information you do not have; this builds it out of a known outcome you have to solve. Every
turn is a small puzzle with the answer visible and the arithmetic left to you.

A run is a branching map of 18 rows (Short) or 30 rows (Full), with battle, elite, boss, event
and shop nodes. After each node you pick one of up to three rewards. Losing ends the run but
keeps the Gene Shard and the meta progression you earned.

You can also import a real Axie by ID from the Axie GraphQL gateway. Its six actual body parts
become its six faces, and the 3D model on the field is that Axie, not a stand-in.

## Running it locally

You need [Godot 4.7.2](https://godotengine.org/download) (stable, standard build; no C# or
.NET build required).

```bash
git clone <this repo>
cd axie-dice
```

Then either open the `godot/` folder as a project in the Godot editor and press F5, or run it
from a terminal:

```bash
godot --path godot
```

First launch imports the assets, which takes a minute or two. It opens on the main menu; a
first-time save is sent through the tutorial automatically.

### Tests

```bash
godot/tools/run_tests.sh
```

53 headless test scenes covering the rules engine, the run loop, save/replay, the UI laws and
the screens. `GODOT=/path/to/godot godot/tools/run_tests.sh` if the script cannot find your
binary. `godot/tools/play.sh` launches the game with the same binary resolution.

### Web export

`godot/export_presets.cfg` has a Web preset that writes to `web/`. Export it from the editor
(Project, Export, Web) or with `godot --path godot --headless --export-release Web`, which
needs the matching export templates installed.

The result is a static folder, and `tools/serve_web_build.py` serves it locally with the two
headers a Godot web export needs (`python3 tools/serve_web_build.py`, then
http://127.0.0.1:8099). A plain `python3 -m http.server` looks like it works and then the game
never boots.

The export is deliberately not in this repository, and it is not on Vercel either. GitHub
and Vercel both refuse any single file over 100 MB, and `index.pck` is 189 MB. The playable
build is hosted on itch.io, which allows 1 GB and is built for exactly this.

Vercel still runs `api/axie.js`, the Axie lookup proxy. The browser build cannot query the
Axie GraphQL gateway directly because it sends no CORS headers, so the Vault calls this
instead; it answers with `Access-Control-Allow-Origin: *`, which is what lets the game live
on a different domain from its API.

The export needs no cross-origin isolation: the Web preset has `thread_support` off, so it
does not use SharedArrayBuffer and any static host will serve it.

## Controls

The game is click-driven. There is one keyboard shortcut.

| Input | What it does |
| --- | --- |
| Left click a die card | Pick that Axie's face up |
| Left click a unit | Spend the held face on it. Click its nameplate or its model, both work |
| Left click a die card again | Put it back down |
| Right click any unit | Open its inspector: full die, statuses, stats |
| Space | End turn |
| Escape | Quit the fight, with a confirm dialog |

Relic actives sit in the bottom-left rack. Click one to arm it, then click the unit it should
hit; cards that need no target resolve on the press. Undo is free within a turn and restores
the random cursor with it, so redoing the same action reproduces the same result.

## Devices and browsers

Desktop only, keyboard and mouse. There is no touch input path and no gamepad support, and the
layout is built for 1920x1080 and scales from there; phone and tablet widths are not handled.

The web export runs in current Chrome, Edge, Firefox and Safari. It needs WebGL2 and about
500 MB of memory for the 3D Axie models, so an older mobile browser will not load it.

## Known issues

- **Vault import needs a proxy on the web.** The Axie GraphQL gateway does not send CORS
  headers, so the browser build routes the lookup through `api/axie.js`. Desktop builds call
  the gateway directly with `curl`. If neither is available, Import reports the feature as
  unavailable rather than failing silently.
- **Boss and monster art is pre-rendered, not live.** The Origins asset kit ships Spine 3.8
  skeletons, and no Spine runtime for Godot 4 can read 3.8 data. The monsters are sampled
  offline into sprite sheets by `tools/spine_runtime/`. Idle is deliberately not sampled: it
  would have cost 3.7 MB against 0.3 MB for the rest, so monsters stand still between actions.
- **No leaderboard.** Runs produce a verifiable action log and `run_verifier.gd` can replay
  one, but nothing is submitted anywhere yet. The result screen says so.
- **Drag and drop is not implemented.** Targeting is click, then click. The design allows for
  a drag path later; it does not exist.
- **Two reward types are specified but not built:** Gene Mutation and Rune Imbue, which
  replace or add a single die face. The codex lists them as missing rather than hiding them.
- **Audio is unbalanced.** The music loops are placeholder levels and there is no mixer.

## Repository layout

```
godot/          The game. Godot 4.7.2 project, GDScript, Forward+ renderer.
  scenes/       Screens. One folder per screen, each owning its own chrome.
  scripts/core/ The rules. No UI, no engine calls, deterministic and replayable.
  autoload/     Global state: run, meta, content tables, event bus.
  addons/       Axie Mixer 3D and its asset pack (see credits below).
  tests/        53 headless gates plus the QA capture scenes.
design/         The GDD and the system specs the port was built against.
production/     QA evidence and backlogs.
api/            One serverless function: the Axie lookup proxy for web builds.
tools/          Build, test and asset-pipeline scripts.
assets/data/    part_faces.json, the shared balance table the rules read.
```

The rules live under `godot/scripts/core/` and `godot/autoload/`, and a test fingerprints
every file in there. Change one and `t_rules_version` fails until a human says whether the
change can alter what a run produces. That is the one gate in the suite that asks a question
instead of asserting an answer.

## Credits and third-party material

See [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) for the full list with licences.

The short version: Axie Mixer 3D and the Origins art kit are Sky Mavis material, used to build
and draw the Axies. The fonts are Baloo 2 and Work Sans under the SIL Open Font License. The
Spine runtime vendored under `tools/spine_runtime/vendor/` is Esoteric Software's, used only
in the offline asset pipeline and never shipped in a build. Everything else in this repository
is original and MIT licensed.

## Disclosures

**This game was built with heavy AI assistance.** It was developed with Claude Code, working
from a written design document, with a human reviewing and directing every step. The commit
history reflects that: commit messages are long because they record why a decision was made,
including the ones that turned out wrong.

**Two builds, one game.** The project started as a single-file vanilla JavaScript prototype
and was ported to Godot. The Godot build is the game now; the JavaScript build has been
removed from this repository.

**Determinism is a design constraint, not a claim.** Every run is reproducible from its seed
and action log, and `t_replay` verifies a full run end to end on every test pass. The
anti-cheat this enables is not deployed anywhere.

## Licence

MIT, see [LICENSE](LICENSE). The licence covers the code and the original content in this
repository. It does not cover the Sky Mavis assets under `godot/addons/` and
`godot/assets/`, which remain Sky Mavis property and are used under their own terms.
