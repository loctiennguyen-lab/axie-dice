# Axie Dice Tactics — Godot port: what is still missing

**Why this document exists.** On 2026-09-18 a session finished every item on the numbered list
in `production/session-state/godot-port-active.md` and reported that "the implementation
backlog is empty". That was wrong, and wrong in a way worth recording: the list in that file
held only the work someone had previously thought to write down. It was never a map of the
port. Clearing it was like finishing the notes stuck to the fridge and declaring the house
clean.

This file is the map. Every number in it was measured on 2026-09-19 by reading
`src/client.html`, `src/data.js`, `src/engine.js` and `api/` against `godot/` — not estimated,
and not carried over from an earlier document.

> **How to read the sizes.** SMALL = under a session. MEDIUM = one to two. LARGE = three or
> more. These are honest guesses about effort, not commitments.

---

## 1. Screens — the headline number, corrected twice

The first correction: `src/client.html` defines **34** functions named `sc*`. That is not 34
screens. One (`scheduleSyncPush`) merely shares the prefix and is not UI at all; eight are
fragments rendered *inside* another screen (`*Body`, `scSubmitBox`); one is a pointer widget;
one is a router; one is a background layer. **22 are real screens or modals.**

The second correction: counting Godot's five `.tscn` files understates it badly, because one
Godot scene carries several JS screens. `RunMap.tscn` alone covers the map, the reward pick,
events, the shop and treasure. `MainMenu.tscn` covers the menu, team select, the Lunacia Pass
and Unlocks.

| Coverage | Count | Screens |
|---|---|---|
| Full | **5** | scCombat, scMap, scReward, scEvent, scShop |
| Partial | **6** | scMenu, scTeam, scEnd, scBP, scInfo, scCombatShell |
| None | **9** | scGate, scCollection, scProfile, scAccount, scTour, scCodex, scSettings, scNameModal, scAvatarModal |
| Partial (2026-09-19) | 2 | **scVaultHub** — the VAULT tab is built (list, 3D preview, RE-SCAN flag, remove); LEADERBOARD and HISTORY tabs deliberately not copied, they depend on the unresolved replay-verify decision. **scUnitInfo** — built as the in-combat inspect panel. |

**Godot covers 13 of 22** (5 full + 8 partial) as of 2026-09-19, up from 11 when this file was
first measured. Still about half — not the ~17% that "5 scenes vs 30 screens" implied.

`DevReview.tscn` is a sixth Godot scene with no JS counterpart; it is a developer tool and does
not belong in this comparison in either direction.

### What "partial" means, precisely

| Screen | Present | Missing |
|---|---|---|
| `scMenu` | seed, mode, ascension, BEGIN/CONTINUE RUN, Pass, Unlocks | entry points to Collection, Echo Box, Tour, Codex, Vault, Profile — because none of those exist |
| `scTeam` | 5 tier-1 slots, duplicates allowed, full die shown | class passive text, right-click-to-clear |
| `scEnd` | outcome, progress, shards, relics, roster, pass XP | damage / turns / kills / biggest-hit (never accumulated at run level), and the Ranked submit box |
| `scBP` | 30 levels, claim buttons, blocked-with-reason rows | a screen of its own; it is inline in MainMenu |
| `scInfo` | a one-line control hint | the real six-tab panel: party dice, enemy dice, relics, and the three rules tabs |
| `scCombatShell` | Combat.tscn persists behind RunMap overlays | nothing functional |

---

## 2. Systems at 0%, grouped by whether they block anything

### 2.1 Blocks a player from understanding the game

| System | JS entry point | Size | Note |
|---|---|---|---|
| **Tutorial / onboarding** | `client.html:3024` `enterMenu()` → `startTutorial()` `:3028` | LARGE | ~200 lines JS + 40 CSS. Godot has nothing, and `docs/godot-port-inventory.md` §5 never listed it — by that file's own standard ("nothing here is an oversight"), it was one. |
| **scCodex** — the rule book | `client.html:6540`, body `:6575-6852` | LARGE | 10 tabs, 278 lines, 26 tables. Content must be re-audited against Godot's rules, not copied: the JS codex says "12 waves" and describes JS undo, and **both are false in this build**. |
| ~~**scUnitInfo** — inspect one Axie~~ | `client.html:6945` | ✅ **DONE 2026-09-19** | Built as an in-combat inspect panel: all six faces at their REAL values (growth/weaken/blind/vital/overdrive applied), class passive, status, role. Closes the gap this row described — enemy dice used to be learnable only by being hit. Gated by `t_unit_inspect`. |
| **scInfo** — in-combat panel | `client.html:7018` | MEDIUM | Three of its six tabs are shared with the Codex, so it is cheaper after that lands. |
| ~~**GUIDES** — starter teams~~ | `data.js:1040` | ✅ **DONE 2026-09-19** | `ContentDB.GUIDES` + `ContentDB.ARCH` (all 10, copied whole), `scenes/guides/Guides.tscn`, USE THIS TEAM hands the roster to MainMenu via `static var pending_team`. Gated by `t_guides_daily`. |

### 2.2 Requested by the user, blocks nothing else

| System | JS entry point | Size | Note |
|---|---|---|---|
| **part_faces** | `src/part_faces.js` (one 54,885-char line), generated by `tools/gen_faces.mjs` | SMALL | 81 signature + 204 variant + 285 scarcity — **the project docs' figures are correct here, verified.** Copy the JSON and load it; do not port the generator. |
| **Vault / Import Axie** | `engine.js:275` `axieToDie()`, `client.html:3226`/`3312`/`3332` | 3 of 4 layers **DONE 2026-09-19** | (a) `axie_to_die.gd` pure algorithm ✅ · (b) 3D preview from GENES ✅ · (c) store + screen + ranked block ✅ · (d) **network layer NOT built** — decided (Godot calls the Axie GraphQL endpoint directly, bypassing `api/axie.js`, which serves the live JS build), see wayfinder ticket C. The import field is on screen, disabled, with the reason printed next to it. Gated by `t_axie_to_die` / `t_axie_gene_preview` / `t_vault`. |

### 2.3 Gates merging into the live `main` branch

| System | JS entry point | Size | Note |
|---|---|---|---|
| **Leaderboard + replay verify** | `api/submit-run.js:71`, `api/_engine.js:23` | LARGE | See §3 — this is an architecture decision, not a porting task. |
| **Ranked action log** | `client.html:4630` `logAction()`, 11 call sites | MEDIUM | **Can be built today, independently of every decision in §3**, and doing so produces the evidence that decision needs. |
| **Account / Gate / cloud sync** | `client.html:5909`/`5923`, `api/auth.js`, `api/sync-save.js` | LARGE | Mostly server work. Godot saves locally only. |

### 2.4 Nice to have, blocks nothing

| System | Size | Note |
|---|---|---|
| **Run history** | MEDIUM | Local-only by deliberate JS decision (`client.html:2915-2923`) — do not "fix" that by adding sync. Needs a run-level stat accumulator Godot lacks. |
| **scCollection** | MEDIUM | 155 cells (94 relics + 55 faces + 6 bosses). Cannot reach 100% while FACE_POOL is unported, which matters because Echo Box unlocks on completion. |
| **Telemetry** | SMALL | Two fire-and-forget calls. Needs an auth token, so it follows Account. |
| ~~**Daily mission**~~ | ✅ **DONE 2026-09-19** | 60 shards on the first run FINISHED each UTC day — win, loss or quit, as the JS does it. `MetaState.daily_date`/`claim_daily_mission()`, shown on Result only on the day it lands. Gated by `t_guides_daily`. |
| **scSettings** | SMALL | Volume backend exists; missing sliders, reduce-flash, ABANDON RUN. |

### 2.5 Recommended NOT to port (with reasons)

| System | Why not |
|---|---|
| **Cosmetics + Echo Box** | 97 items across four pools. Touches no gameplay; **20 of the 46 decor/background items are CSS-only and would have to be re-drawn, not ported**; and its unlock gate is `collectionComplete()`, which requires all 55 FACE_POOL faces — deferred by the user. Even fully built, no Godot player could open the box. |
| **World Tour** | 2 chapters × 10 tiles, but 17 of 20 rewards are cosmetics from the pool above, so it is blocked behind a system that should not be built. Also needs two META fields Godot lacks (`full_asc_max`, `bosses[]`). |
| **scGate (login)** | Not a teaching screen; it is authentication, and it needs the whole server stack. **Consequence: the tutorial's trigger must change** from "after first login" to "first launch on this machine". That is a design decision, not an implementation detail. |
| **NFT HP bonus** | Listed as missing in the project docs, but it is **dead code in the live JS build**: `nftHpBonusPct()` is only reachable via `opt.nftPreselect`, and the only caller is `tools/sim.js` — a headless balance probe. No real player has ever received a point of HP from it. Porting it would be porting a feature that has never existed for players. |
| **Ronin wallet in the submit box** | A display string; `submit-run.js:172` truncates it and verifies nothing. |
| **Server-side run history sync** | The JS build explicitly declined it. |

---

## 3. The leaderboard question, stated properly

The live build's anti-cheat works because the **client never sends a score**. It sends the
seed, the team, and the full list of moves; `api/submit-run.js` loads `src/engine.js` and
`src/data.js` from disk into a Node VM, replays the run, and computes the score from the state
*it* arrives at. Cheating requires actually playing well.

That mechanism cannot be pointed at this port: the rules now live in 3,066 lines of GDScript,
and a Node VM cannot run GDScript. **Whoever owns this has to answer one question: who is the
referee?**

Options, with their trade-offs — this document does not choose:

| | Approach | Gains | Costs |
|---|---|---|---|
| A | Headless Godot as the referee | One set of rules, can never drift; the existing 24-test suite already guards that code | Cannot run on a Vercel Function; needs new hosting |
| B | Export the engine to WebAssembly, run it in Node | Keeps the current hosting | Heavy runtime, complex boundary, nobody here has done it |
| C | Re-implement the engine in TypeScript | No infrastructure change | Two rule sets that must stay bit-identical forever — the exact failure class behind most bugs in `godot-port-inventory.md` §6 |
| D | Server-signed seeds, client-reported scores | Cheapest | Not anti-cheat at all; a regression from what players have today |
| E | Two separate boards, JS and Godot | Does not disturb the live board, and the scores are not comparable anyway | Splits the community; still needs A/B/C for the new board |
| F | No ranked board in the Godot build | Unblocks everything else immediately | Loses a feature players currently have |

**Required whichever is chosen:** the action log (§2.3); a decision on undo, which rewinds the
RNG in Godot and does not in JS; an `ENGINE_VERSION` equivalent; and a decision on the map,
because 18 rows versus 12 means the two builds' scores were never comparable to begin with.

---

## 4. Corrections to earlier project documents

Recorded because this project has repeatedly been misled by its own notes.

1. **"The implementation backlog is empty"** (session state, 2026-09-18) — false, as this
   document shows. Corrected in place with a warning.
2. **"JS ~30 screens, Godot 5"** — 22 real screens; Godot covers 11 of them.
3. **"Battle Pass and Unlocks are missing"** — both exist, inline in `MainMenu.gd`.
4. **The gap table's "JS" column was grep hit counts**, which reads as a content count. Cosmetics
   showed "28"; the real figure is **97 items**. Leaderboard showed "22"; roughly 44 mentions.
5. **"+34% difficulty from the 18-row map"** — measured at **+47%** at the final boss, because
   `power_level` counts nodes *completed* and is 17 at the final boss, not 18. And the final
   boss was never the worst case: the **mid-boss was +75%**.
6. **`t_tutorial` recorded as 28 gates** in `.claude/docs/technical-preferences.md`; it is **31**.
7. **`design/gdd/onboarding-tutorial.md` still says "Draft — awaiting implementation"**; the JS
   feature is fully implemented and gated in CI.
8. **`.claude/docs/technical-preferences.md` cites `docs/gdd/onboarding-tutorial.md`** — that
   path does not exist; it is `design/gdd/`.
9. **The same file says `ci.mjs` "runs all 11 gates" and, two lines later, "must be 12/12".**
10. **`docs/godot-port-inventory.md` §9 numbering skips item 6.**
11. **`client.html:4624` lists 10 logged verbs; there are 11** — `eventDone` is missing from a
    comment that describes itself as "kept in sync manually". A missing call site silently
    invalidates every submission by that player.
12. ~~The Origins Kit 3D assets cannot render a specific NFT Axie.~~ **This entry was WRONG, and
    it was mine — corrected 2026-09-19 after the user pushed back on it.** The reasoning behind
    it (no mapping from real part names like "Anemone" to kit ids `S00_Aquatic02_L1_Back`) was
    true and irrelevant: **the route is not part names, it is GENES.**
    `AxieDescriptor.from_genes()` is a complete 512-bit decoder — main class, body type, body
    skin, primary colour, and per-part skin/class/variant/stage — feeding `AxieCharacter3D`
    directly. Verified by decoding four real NFTs from the addon's own goldens (#123, #922,
    #4154, #1000) and rendering them: body type and colour matched the goldens exactly,
    including a `Fuzzy` body, and the four came out visibly distinct.
    So an imported Axie is built with the SAME rig the party already uses — no CDN fetch, no
    image cache, and it looks like it belongs on the battlefield instead of like a pasted-in
    sprite. Evidence: `production/qa/evidence/2026-09-19_vault-from-genes.png`.

    **Measured fidelity, re-measured 2026-09-19 and CORRECTED: 9 of 10 Axies render complete,
    and all 54 decodable parts resolve — the kit covers 100% of real Axie parts.** The figure
    previously recorded here, "54/60 (90%)", counted the six phantom parts of sample #1, whose
    gene is literally `0x0` and which the vendor marks `skip` / `skip_reason: "short_genes"`.
    There is no kit coverage gap; there is one sample carrying no gene. The "variant 00 the kit
    does not ship" story was a *consequence* of decoding an empty gene, not a separate cause.
    `AxiePartResolver` falls back across skin and level but NEVER across variant, so where a part
    genuinely is missing the failure mode is a MISSING part, never a wrong one. A bare body still
    has to be detected rather than shipped as "a strange-looking Axie" — that is what
    `AxieGenePreview.inspect()` and the `t_axie_gene_preview` gate (420 checks) now enforce.

    One consequence for later: `api/axie.js` currently queries `class` and `parts` but NOT
    `genes`. That file serves the LIVE build, so adding the field is a production change to
    decide deliberately — or Godot can query the GraphQL API directly and skip the proxy.

---

## 5. Suggested order

Sequenced for the stated goal — *the game should work now; the UI gets a pass later.*

1. ~~Difficulty re-tune~~ — **done 2026-09-19**, `TUNE.growth` 1.15 → 1.125 (wayfinder ticket B).
2. ~~scUnitInfo~~ — **done 2026-09-19.** Clicking any unit that is not a legal target opens a
   panel with its six faces at live values. It also surfaced a bug that had made five pieces of
   content inert: `Unit.growth` was written with integer keys and read with string ones.
3. ~~part_faces~~ — **done 2026-09-19**, loaded into `ContentDB` with a drift gate against the
   generated source. → **Vault / Import Axie** (LARGE): layers (a)(b)(c) landed 2026-09-19; only
   the network layer (d) remains, and its architecture decision is already made.
   The four layers, and why they were built in this order — each one provable before the next
   depended on it: (a) `axie_to_die.gd`, the pure algorithm, tested bit-exact against the JS ✅ ·
   (b) the 3D preview from genes, using the addon's own `AxieAvatarRenderer` ✅ · (c) vault
   storage in `MetaState` plus the screen and the ranked block ✅ · (d) the network layer LAST,
   because it was the only part that needed a decision — now made: Godot calls the Axie GraphQL
   endpoint directly rather than extending `api/axie.js`, which serves the live JS build.
   **Note for whoever builds (d):** the addon's goldens cannot substitute for the API. They carry
   real genes but no part NAMES ("Anemone", …), and `AxieToDie` needs part names — a die built
   from goldens would look plausible and be wrong.
4. ~~**Daily mission** + **GUIDES**~~ ✅ **DONE 2026-09-19.**
5. **Ranked action log** + a self-replay test — independent of every §3 decision, and it is the
   evidence that decision needs.
6. **scCodex**, then **scInfo**'s rules tabs — large, and must be audited against Godot's own
   rules rather than copied.
7. **Tutorial** — last of the teaching cluster; it consumes scUnitInfo, the reward screen and
   step-lock. Its trigger needs a decision first (see §2.5, scGate).
8. Everything in §3, once the referee question is answered.

Explicitly not scheduled: §2.5.
