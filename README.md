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
  <img src="https://img.shields.io/badge/stack-vanilla%20JS%2FHTML%2FCSS-yellow" alt="Vanilla JS/HTML/CSS">
  <img src="https://img.shields.io/badge/deploy-Vercel-black?logo=vercel" alt="Deploys to Vercel">
  <img src="https://img.shields.io/badge/CI-11%2F11%20gates-brightgreen" alt="11/11 CI gates">
</p>

<p align="center">
  <b><a href="https://axiedice.vercel.app">Play it now →</a></b>
</p>

---

## What this is

Axie genetics map onto this game almost exactly: **1 Axie = 6 body parts, 1 die = 6 faces**
(Eyes, Ears, Mouth, Horn, Back, Tail). Pick 5 Axies, roll all five dice at once, reroll what you
don't like, then commit each face to a target. **Enemies roll and telegraph their move first** —
you always see exactly who they'll hit and for how much before you act. Nothing in combat is
hidden. That's a deliberate departure from the genre: Slay the Spire and Dicey Dungeons both build
tension out of *hidden* information; this game bets the other way — tension from calculating a
known outcome, not guessing an unknown one.

Runs are 12 waves (Short, ~15 min) or 20 waves (Full, ~35 min), map-based with
battle/elite/boss/event/shop nodes. Losing ends the run but keeps every Gene Shard and point of
progression you earned — the loop is built around "lost, try again," not attrition.

## Play now

**[axiedice.vercel.app](https://axiedice.vercel.app)** — single URL, nothing to install.

An account is required before you can play (this is a deliberate design choice for save-sync and
the ranked Leaderboard, not a bug — see [Known limitations](#known-limitations)).

## Features

- **9 classes** (6 playable — Plant/Beast/Aqua/Reptile/Bug/Bird — plus 3 secret classes that map
  onto them at battle time), each with a passive that defines its playstyle.
- **285-part catalog, 0 duplicate dice** — every part maps to its own distinct face (81
  signature faces + 204 family-variant faces), so two Axies of the same class no longer roll
  identical dice, unlike an earlier build where 36 slot×class combinations collapsed to 19
  effective faces.
- **94 relics that change rules, not just numbers** — passives and actives that rewrite how a face
  resolves (`modFace`/`onKill`/`onHit`/`onDmgTaken`), verified to have zero rarity-band
  violations across all 94.
- **Formation Resonance** — two Axies adjacent in your formation rolling the same face *type* in
  one turn grant the second executor a **+15%** value bonus. The first mechanic where formation
  order and execution order both matter.
- **Import Axie (Vault)** — paste a real Axie NFT's ID and its 6 actual body parts become a
  playable die, usable in any team. Prototype scope: any public Axie ID works, no wallet-signature
  ownership gating yet.
- **Ranked Run + Leaderboard** — an opt-in mode that zeroes every Unlock/Pass bonus (so every
  submission plays the same baseline) and submits your result. The server never trusts a
  client-sent score — it replays your exact recorded action log through `src/engine.js` and
  computes the score itself, deterministically.
- **Deterministic & seeded** — every run can be replayed exactly from its seed.
- **Free undo within a turn** — try a face on a target, take it back, decide again, before you
  commit to ending the turn.
- **Background music** (optional, external asset, graceful no-op if it fails to load) plus 26
  synthesized SFX (zero audio bytes — generated in real time via Web Audio).

## Known limitations

Honesty over polish — these are real, current gaps, not hidden:

- **Mandatory account gate, no password recovery yet.** The very first screen is Log In /
  Register — there's no guest/demo mode. This is intentional (see
  `design/gdd/player-accounts.md`), but it does mean the biggest single UX risk right now is
  losing access to a forgotten password before recovery ships.
- **Landscape-only.** Phone portrait shows a "rotate your device" prompt; the board is fixed at
  five columns wide.
- **Mouse/touch is click-click, not drag-and-drop.** Click a rolled face, then click a legal
  target. Full keyboard play (Tab to a die/target, Enter/Space to act) works end-to-end as of
  2026-09-05.
- **Automated UI scanning covers 6 of 27 screens** (menu, combat, shop, event, vault, leaderboard).
  The rest are covered by manual QA only.

## Engineering rigor

This is a prototype, but it isn't undertested. `node tools/ci.mjs` is the single entry point —
**11/11 gates**, every one of them a real check against the actual served build, not a smoke test:

| Gate | Current floor |
|---|---|
| Relic invariant (all 94 relics, correct rarity band) | 94 / 94 |
| Relic behaviour proofs | 38 / 38 |
| Part→face generator (0 duplicate dice, both budget profiles) | GREEN |
| Part-skill face pins | 44 / 44 |
| Import-Axie mapping unit tests | 43 / 43 |
| Vault (NFT import) migration | 8 / 8 |
| UI rules (contrast, tap-target size, layout shift, no `undefined`/`NaN` leaks) across 6 screens | 65 / 65 |
| Viewport fit (4 desktop sizes + a dedicated boss-screen case) | PASS |
| Headless balance sim | winrate 19.8% (Short, Ascension 0) / 8.0% (Full, Ascension 0) over 500 runs — informational, not a gate |

Balance numbers are **measured, not guessed**: `node tools/sim.js 500` runs real games against a
heuristic bot and reports winrate/archetype breakdown, which is what tuning decisions are made
against (see `design/gdd/game-concept.md`).

## Playing locally

No build tooling, no `npm install` needed for the game itself.

```bash
python3 build.py          # writes AxieDiceTactics.html (includes dev tools)
python3 build.py public   # writes index.html (public build, dev tools stripped)
```

Open the generated HTML file directly in a browser — it's a single self-contained file. The
**Import Axie** feature needs the Vercel serverless proxy and won't fetch real NFT data when the
file is opened standalone; everything else works fully offline.

## Testing

```bash
npm install && npx playwright install chromium   # needed once, for verify.mjs/soak.mjs/t_*.mjs
node tools/ci.mjs            # the only command you need — runs all 11 gates
node tools/ci.mjs --fast     # 7 logic-only gates, skips the browser-driven ones
```

Run `tools/ci.mjs` rather than any individual script — this project's own history includes real
regressions that slipped through because a suite was invoked standalone and its result silently
went stale.

## Deploying

```bash
vercel deploy --prod --yes --scope axielatro
```

`--scope` is required (the project belongs to the `axielatro` Vercel team, not a personal
account). This uploads the local working tree directly — no push or GitHub import needed.
`vercel.json` points Vercel at `tools/vercel-build.sh`, which runs `build.py public` and copies
`assets/audio/` into the output.

For the Leaderboard to persist scores (it computes them correctly either way), set two
environment variables in the Vercel project (Settings → Environment Variables) from a free
[Upstash Redis](https://upstash.com) database:

```
UPSTASH_REDIS_REST_URL=...
UPSTASH_REDIS_REST_TOKEN=...
```

Without them, Ranked Run scores are still computed correctly — the API just responds
`stored:false` instead of erroring.

## Tech stack

Vanilla JavaScript (ES6+), no framework, no bundler. `build.py` assembles everything below into
one HTML file by string concatenation. Rendering is DOM + CSS — no `<canvas>`, no WebGL.

```
src/
  client.html    ALL client code in one file: CSS, UI screens, FX/animation, audio, icons,
                 battle log — see the comment at the top of the file for why
  engine.js      combat rules, run/wave state — pure functions over plain data
  data.js        classes, parts, relics, tuning constants
  part_faces.js  GENERATED by tools/gen_faces.mjs — never hand-edited
  devtools.js    dev-only in-game inspector; build.py public strips this out
  art.js         base64-embedded sprite data (~1.8MB, one line — don't open in an editor)
  cosmetics.js   base64-embedded cosmetic assets
api/
  auth.js / _auth.js       account creation, login, token verification
  axie.js                  Import Axie proxy (Axie Infinity GraphQL → JSON; the game's only
                            outbound network call besides the game files themselves)
  submit-run.js / _engine.js / leaderboard.js   Leaderboard: replays a submitted action log
                            through engine.js/data.js in a Node VM and computes the score itself
  sync-save.js             cross-device save sync
  telemetry.js / admin-stats.js   anonymous play telemetry + an admin-only dashboard
tools/
  ci.mjs         single entry point — all 11 gates
  sim.js         headless balance simulator
  verify.mjs     UI/UX rule checker (Playwright)
  soak.mjs / soakm.mjs   extended-play regression soak (keyboard-driven / real-mouse-driven)
  gen_faces.mjs  generates src/part_faces.js from assets/data/part_faces.json
  t_*.mjs        unit/invariant tests (relics, part-skill, import mapping, vault, AoE, viewport)
```

Engine/data are kept out of `client.html` on purpose: `api/_engine.js` loads them straight off
disk into a Node VM to replay-verify Leaderboard scores server-side — merging them into the
client bundle would break that anti-cheat path.

## Controls

Mouse/touch: click a rolled face, then click a legal target — no drag-and-drop.

| Key | Action |
|---|---|
| `Tab` | Move keyboard focus between dice, targets, and other interactive elements |
| `Enter` / `Space` | Activate whatever is focused (select a die, confirm a target) — or, with nothing focused, end the turn |
| `1`–`5` | Select a die by party position directly |
| `R` | Reroll marked dice |
| `Ctrl`/`Cmd`+`Z` | Undo (cleared on reroll and end turn) |
| `I` | Toggle the info panel |
| `L` | Toggle the Battle Log |
| `Esc` | Close a modal / deselect |

## License

MIT — see [LICENSE](LICENSE).
