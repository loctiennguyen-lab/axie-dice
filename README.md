<p align="center">
  <h1 align="center">Axie Dice Tactics</h1>
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
</p>

---

## What this is

Pick 5 Axies. Each Axie is a die with 6 faces — one per body part (Eyes, Ears, Mouth, Horn, Back,
Tail). Roll all five dice at once, reroll what you don't like, then commit each face to a target.
Enemies show their intent before you act — nothing in this game hides information from the player.

Runs are 12 waves (Short) or 20 waves (Full), map-based with battle/elite/boss/event/shop nodes.
Losing ends the run but keeps every Gene Shard and point of Lunacia XP you earned — the loop is
built around "lost, try again," not attrition.

## Features

- **6 classes, 3 tiers each** — Plant/Beast/Aqua/Reptile/Bug/Bird, each with a passive that defines
  its playstyle (Bulwark, Feral, Conduit, Scales, Virulent, Talon).
- **396-part catalog** — 285 regular parts + 111 rarest "Origin" parts, all with real Axie Infinity
  names.
- **Formation Resonance** — two adjacent Axies in your formation rolling the same face type in one
  turn grant the second executor a value bonus. The first mechanic where formation order and
  execution order actually matter.
- **Import Axie** — paste a real Axie NFT's ID and its 6 actual body parts become a playable die,
  stored in your local Vault and usable in any team. See [Import Axie](#import-axie) below.
- **Battle Log** — every action this combat, compiled into readable lines, frozen and reopenable as
  a "Battle Report" after a loss.
- **Ranked Run + Leaderboard** — an opt-in run mode that plays with every Unlock/Pass bonus zeroed
  out (so every submission is on the same baseline) and submits your result to a real leaderboard.
  The server never trusts a client-sent score — it replays your exact recorded actions through
  `src/engine.js` and computes the score itself. See [Leaderboard](#leaderboard--ranked-run) below.
- **Deterministic & seeded** — every run can be replayed exactly from its seed; a Daily Seed mode is
  built in.
- **Accessible** — full keyboard navigation, reduced-motion/reduced-flash settings, WCAG AA contrast
  throughout.

## Playing locally

No build tooling, no `npm install` needed for the game itself.

```bash
python3 build.py          # writes AxieDiceTactics.html (includes dev tools)
python3 build.py public   # writes index.html (public build, dev tools stripped)
```

Open the generated HTML file directly in a browser — it's a single self-contained file.

The **Import Axie** feature needs the Vercel serverless proxy (see below) and won't fetch real NFT
data when the HTML file is opened standalone or served with a plain static server; everything else
works fully offline.

## Deploying

```bash
git push origin <branch>
```

then import the repo into Vercel (not just the built HTML file — the `api/*.js` serverless
functions need to deploy alongside the static build for Import Axie and the Leaderboard to work).
`vercel.json` already points Vercel at the right build command and output directory.

For the Leaderboard to actually save scores (not just compute them), also set these two
environment variables in the Vercel project (Settings → Environment Variables) from a free
[Upstash Redis](https://upstash.com) database:

```
UPSTASH_REDIS_REST_URL=...
UPSTASH_REDIS_REST_TOKEN=...
```

Without them the game still works fully — Ranked Run scores are computed correctly, the API just
responds `stored:false` instead of erroring.

## Tech stack

Vanilla JavaScript (ES6+), no framework, no bundler. `build.py` assembles `src/*.js`/`src/style.css`
into one HTML file by string concatenation. Rendering is DOM + CSS — no `<canvas>`, no WebGL. The
only network call in the project is the Import Axie proxy (`api/axie.js`, a Vercel serverless
function); everything else is 100% client-side.

```
src/
  engine.js    combat rules, run/wave state — pure functions over plain data
  data.js      classes, parts, relics, tuning constants
  ui.js        every screen (menu, team select, combat, codex, ...)
  fx.js        replays engine.js's event stream for animation
  log.js       Battle Log — compiles the same event stream into readable lines
  audio.js     procedural SFX (no audio files)
  icons.js     inline-SVG icon set
  art.js       base64-embedded sprite data
  devtools.js  dev-only in-game inspector (stripped from public builds)
  style.css    all styling — design tokens in :root
api/
  axie.js        Vercel serverless proxy for Import Axie (Axie Infinity GraphQL → JSON)
  submit-run.js  Leaderboard: replays a submitted action log through engine.js, computes the score
  leaderboard.js Leaderboard: read-only top-100 per (mode, ascension)
  _engine.js     shared helper — loads data.js+engine.js into a Node vm context for replay
tools/
  sim.js       headless balance simulator (node tools/sim.js 500)
  verify.mjs   UI/UX rule checker, needs Playwright (node tools/verify.mjs)
  soak.mjs / soakm.mjs   extended-play regression soak (desktop/mobile)
  t_import.mjs   unit tests for the Import Axie part→face mapping (node tools/t_import.mjs)
```

## Testing

```bash
npm install                # playwright, for verify.mjs/soak.mjs only
node tools/sim.js 500      # balance sim — winrate, archetype breakdown
node tools/verify.mjs      # 8 UI rules (contrast, tap targets, no layout shift, ...)
node tools/soak.mjs 10     # extended play, checks for crashes/stalls
```

## Import Axie

Axie genetics map onto this game almost exactly: 1 Axie = 6 body parts, 1 die = 6 faces. Paste a
real Axie's ID and the game fetches its 6 parts from the Axie Infinity API (proxied through
`api/axie.js` since the API itself blocks CORS), maps each part to a face by `(slot, part's own
class)`, and adds it to your Vault. This is the **prototype scope** — anyone can import any public
Axie ID, no wallet signature or ownership gating. See `design/gdd/economy-progression.md` §10.2b for
the full NFT-vs-free economy design this could grow into.

## Leaderboard / Ranked Run

Toggle **RANKED RUN** in Team Select before starting. It forces every Unlock/Battle-Pass bonus to
zero and blocks Vault (Import Axie) picks from your team, so every submitted run plays against the
exact same baseline no matter how much local progression a player has — the server has no way to
verify per-player Unlocks/Shard state (it's never synced anywhere), so this sidesteps that instead
of trusting it. Win or lose, the end screen lets you enter a display name (and optionally connect a
Ronin wallet for a badge next to it) and submit. View standings from the **LEADERBOARD** tile on the
main menu, filterable by Mode and Ascension.

This ships as an MVP: one board per (mode, ascension) rather than the full Standard/Collector split
in `design/gdd/leaderboard-system.md`, and no Daily-seed view yet — see
`docs/architecture/adr-0001-leaderboard-backend-infrastructure.md` for why and what a full
implementation would still need (syncing meta-progression to a server).

## Controls

Mouse/touch drag-and-drop is primary; keyboard works throughout.

| Key | Action |
|---|---|
| `1`–`5` | Select a die by position |
| `R` | Reroll marked dice |
| `Space` / `Enter` | End turn |
| `Ctrl`/`Cmd`+`Z` | Undo (cleared on reroll and end turn) |
| `I` | Toggle the info panel |
| `L` | Toggle the Battle Log |
| `Esc` | Close a modal / deselect |
| `Tab` | Move focus between interactive elements |

## License

MIT — see [LICENSE](LICENSE).
