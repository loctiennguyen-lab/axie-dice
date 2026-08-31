# Axie Dice Tactics — QA pass and bug fixes (v0.7)

## Automated test harness (new)

Three Playwright scripts now ship with the source. They drive the real build, not a mock.

| Script | What it does |
|---|---|
| `t_aoe.mjs` | Targeted regression: every die-input path (tap a no-target face, tap-then-target, drag-to-target, summon). |
| `t_fit.mjs` | Checks the dice tray, REROLL and END TURN stay on screen at 1280x720, 1366x768, 1440x900, 1920x1080. |
| `soak.mjs` | Plays complete runs by clicking real DOM elements. `max` argument plays with every unlock, every Battle Pass face, all perks, Ascension 0-10. |
| `soakm.mjs` | Same, but driven by real pointerdown/move/up events — the exact path a player's mouse takes. |

Final result: **79 complete runs, 0 crashes, 0 stalls, 0 dead ends.**

## Bugs found and fixed

**1. Faces that need no target could not be used with the mouse.**
`All` (area of effect), `Mana`, `Summon` and `Chain` faces were unusable by clicking or dragging. Pointerdown selected the die and immediately re-rendered, which detached the element, so the click never landed. The die stayed highlighted and did nothing. Only the number keys 1-5 worked. This silently disabled the entire Conduit (Mana) archetype and every area-of-effect face.

**2. A single playback error froze the whole board permanently.**
`playing` was set before the animation loop and cleared after it, with nothing in between to catch a failure. `body.playing #app` sets `pointer-events:none`, so any exception during playback left the player unable to click any die, any target or END TURN for the rest of the run — with stale floating numbers still on screen. Playback is now wrapped in try/finally, the roll animation has its own guard, and a watchdog releases the input lock if it is ever held longer than 12 seconds.

**3. The roll animation could throw on a die with no rolled face.**
`u.die[u.rolled]` was read without a guard when a unit's `rolled` was `-1`. The thrown error killed the animation frame loop and left `rollAnim` set, which locks the dice tray.

**4. The dice tray and END TURN fell below the fold on short windows.**
The combat screen used `min-height`, so on a 1280x720 or 1366x768 window the bottom bar scrolled off screen and the game read as unresponsive. The board now scales itself down just enough to fit, holding one scale for a whole wave so nothing jumps when a die is selected.

**5. Decorative overlays could swallow clicks.**
Damage previews, crit badges, rarity tags, floating numbers and the HP ghost bar are now `pointer-events:none`.

**6. Two pieces of Vietnamese text remained.**
The fast-forward hint in the stylesheet and the Curse Pact relic description.

## Notes for the next pass

- Run `node soak.mjs AxieDiceTactics.html 30 max` and `node soakm.mjs AxieDiceTactics.html 12` before shipping any build. A full pass takes roughly 30 minutes.
- The soak plays greedily and at random, so its win rate is not a balance signal. Use `sim.js` for balance.
