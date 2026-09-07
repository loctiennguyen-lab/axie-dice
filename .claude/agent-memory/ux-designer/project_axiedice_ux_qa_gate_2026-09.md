---
name: project-axiedice-ux-qa-gate-2026-09
description: Findings from the 2026-09-01 strict UX quality-gate review of src/ui.js (all sc* screens), requested because PM wants "UI/UX must be perfect"
metadata:
  type: project
---

PM (loc.tien.nguyen) escalated from "UI vẫn xấu" (see [[project_axiedice_combat_hierarchy]]) to an explicit strict pre-commit quality gate: "tôi muốn UIUX phải hoàn hảo," running in parallel with art-director. PM does hands-on browser QA personally (not just reading code) — the Collection-screen complaint in this request was based on directly observing a fresh save in a browser, not a code read. Expect this level of rigor and expect the PM to already know roughly what's wrong before asking; verify the exact reported symptom in code rather than assuming it's exaggerated.

**Confirmed real, not exaggerated**: `scCollection()` in `src/ui.js` renders three section headers ("RELIC (0/44)", "DIE FACES (0/55)", "BOSSES DEFEATED (0/6)") each followed by an empty `.colgrid` div with zero children when `META.*` arrays are empty — no empty-state message, no visual cue that the grid is scrollable/tappable or just empty-by-design. This is inconsistent with the project's own established `iempty` pattern already used in `scInfo()`'s relic tab. See [[reference_axiedice_ui_rules]] for the pattern location.

**Why:** a genuinely fresh save (0 progress) is the very first thing every new player sees when they click COLLECTION from the menu — this is not an edge case, it's the default first-session state.

**How to apply:** any future review of menu/meta screens (Unlocks, Collection, Pass) should specifically load/simulate a zero-progress save and check for bare empty grids before approving.

Other findings from the same pass (2026-09-01), for [[gameplay-programmer]]/[[ui-programmer]] follow-up:
- **Codex/engine desync**: `src/ui.js` Codex "basic" tab step-2 REROLL row says "You get one reroll per turn by default," but `src/engine.js` `newGame()` sets `rerolls:2, maxRerolls:2+(opt.bonusReroll||0)` — actual default is 2, not 1. This is the exact area the PM said was "recently changed" (turn/reroll logic) — the Codex copy was not updated in that pass. Everything else cross-checked in the Codex (Infinite Die's `safeReroll` breaking undo-clear-on-reroll, REROLL+1 cap at 4, keyboard shortcut list) matched the engine correctly.
- **No accessibility toggle for full-screen flash/hitstop** — FIXED as of a later pass (confirmed 2026-09-07): `scSettings()` now has a `META.reduceFlash` toggle (button text "FLASH: REDUCED"/"FLASH: NORMAL", `client.html` ~line 5029) and `wantsLessFlash()=META.reduceFlash||prefersReducedMotion()` (~line 2642) gates both `flashScreen()` and `hitstop()`, plus `.rbadge` CSS has an explicit reduced-motion branch. Do not re-flag this as a gap — check `wantsLessFlash()` still exists before repeating this finding. Any NEW feature that adds screen-flash/hitstop-style feedback (e.g. a gacha chest reveal) should route through the existing `flashScreen()`/`hitstop()` calls rather than inventing a parallel accessibility path.
- **Inconsistent back/exit label+style** across secondary screens: `scUnlocks`/`scCollection`/`scGuide`/`scBP` use `btn('','BACK',...)`; `scCodex` uses `btn('sm ghost','BACK',...)`; `scTeam` uses the same "return to menu" action but labels it `'MENU'` instead of `'BACK'`. Minor but real — same action, three different labels/styles.
- **Esc does not universally "go back"**: the global `keydown` handler only clears `modal` or `sel`/`selRelic`; on non-modal top-level screens (Unlocks/Collection/Guide/BP/Codex) Esc does nothing, even though the modal system elsewhere trains the player that Esc reliably backs out.

Full verdict delivered to the orchestrator: **NEEDS REVISION** (not approved as-is). Collection empty-state and the Codex reroll-count line are cheap, concrete, blocking-before-ship fixes; the keyboard-only gap and flash-toggle gap are real accessibility-checklist failures but pre-existing/larger-scope debt worth their own task rather than blocking this pass.
