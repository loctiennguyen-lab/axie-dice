# UI-03 round 2 prompt for Claude Design

**Tóm tắt cho Liam (3 dòng):**
1. Round 2 đi tiếp đúng hướng A4 Blend trên Terrariums, dùng lại token và component của round 1, chỉ thêm component mới nếu thật sự cần.
2. Nhờ vẽ các màn/state còn thiếu (Must trước: Defeat có Continue, Reward nhiều loại, Run setup đủ, sign-in bắt buộc, Undo, status/float text), kèm hành vi thật của game để Design không bịa.
3. Sửa các chỗ round 1 giả định sai: sign-in bắt buộc (offline không chơi được), crit theo mặt xúc xắc/relic, Egg tối đa 4, boss 3 phase, Missions là bảng cọc Shard.

---

## Round 2: same direction, fill the gaps

Continue in **A4 Blend on Terrariums**. Reuse round-1 tokens.json, components.md and motion.md as they are. If you need a new component, list it first in your reply (name, variants, why existing ones don't work) before drawing screens. Deliver in the same format as round 1: one `screens/<id>/spec.md` per screen with container tree (anchors, fixed/expand), string limits, every state, focus order, Esc behaviour, checklist, flags. Number new screens after 29. For states added to an existing screen, update that screen's spec and mark the change.

### Keep from round 1
Full-screen 3D with plates over it, Amber primary, cream selected outline, Rowdies + Work Sans, 8 px grid, 1920x1080 base with uniform scale, one primary per screen, hit areas of 44 px or more, flat StyleBoxes and hard shadows, the spec container-tree style, the Combat 3D size table. Do not redraw anything that is already approved.

### Corrections to round-1 assumptions
- **Sign-in is required to play** (Liam 15/10, stays for now). Dice are rolled on the server. A guest or an expired session cannot start any run kind: Run setup shows "Sign in to play". Remove "Play as guest", "Play offline" and "Offline never blocks Normal runs" from README, 01, 16. Guests can still read rates (Echo Box) and browse.
- **Crit is not a flat 20%.** Only party damage faces can crit. The chance comes from the face's crit keyword plus relic bonuses. Show the chance on the face/info panel, not a fixed number.
- **Rerolls per turn is dynamic.** 2 is the base; ascension and relics change it. Show the live number.
- **Egg cap is 4 by default** (relics can raise it), not 6. Die select keys are 1 to 5 (Axie dice only); Egg dice are picked by click. Round 1's "6–0 for Eggs" does not exist. Other keys: R reroll, E or Space end turn, Z undo, A Aid, Esc menu.
- **Boss has 3 phases**; the HP thresholds come from data (`phase_thresholds` in combat_tune.json, today 66% and 33%). Show the phase count and the bar ticks from data, never hard-code them in copy.
- **Reward is not only relics** (see Must below).
- **Defeat is not just "See results"** (see Must).
- **Missions is a Shard stake board**, not daily/weekly quests. Daily claims live on a separate Daily screen.
- **Aid is hidden entirely for newcomers** (first 5 runs), not a free tray.
- **Currencies:** Shard is both in-run money and the stake currency (starter Shards cannot be staked). Gem violet is used only on paid surfaces. Stone art is still missing; keep the stand-in.
- The **3D physics dice throw** (RigidBody3D into the tray) is being built as you specified; Liam approved it. The result is decided by the engine RNG first, physics only plays it. Keep your spec.

### Must
1. **Defeat panel.** Whole party dead. Shows: a paid Continue (once per fight, price in the cost chip, revives the party at a set % HP; boss keeps its HP and phase, clock and attrition reset), a 6-line recap, the boss remaining (name, "% left, phase n of 3"), and End run. States: can afford, cannot afford (say why), already used, loading, error.
2. **Reward types.** Pick-one layouts for HP, +Reroll, Level, Ascend, Chaos and Curse rewards as well as relics. Chaos and Curse need a clear risk read. Include the full-slot case below.
3. **Slots full (relic slots and the 3 active slots).** Swap or sell flow when picking up a relic or active with no free slot, on Reward and Treasure (Shop already has the sell plate).
4. **Run setup completion.** Axie picker (choose party), Load preset and Save preset popups, leaderboard popup, kind choice Normal / Daily / Ranked (plus Short / Full length) with the disabled reason text and Daily tries left (max 3), and the **unfinished-run card**: starting a new run forfeits the stake, say so.
5. **Undo (Z) button** in Combat: position, enabled and disabled states.
6. **Combat unit info.** Intent badge, status chips beyond Shield/Poison (burn, weaken, etc.), float texts (CRIT, LINK, +REROLL, SUMMON). Boss phase change moment.
7. **Net errors mid-run.** Retry notice that does not lock input, plus the fatal "session expired" card with SIGN IN and BACK TO MENU.
8. **Account.** Desktop sign-in "waiting for browser" state with cancel, welcome after sign-in, account chip, Sky Mavis badge, save choice (cloud vs this machine) as a boot-time overlay, and a toast table by error code.
9. **Result additions.** Shard card, Pass XP card, relics card, stake settlement (won or lost the mission stake).
10. **In-run menu / Abandon.** Add the "you lose your stake" line to the abandon dialog.
11. **Tutorial.** Opening curtain and the final rewards screen.
12. **Land.** Toast, shared confirm dialog, first launch, online-only buttons when signed out, Gallery building (unlocks at tier 5), Leaderboard billboard, "Opens after 5 runs" locked state kept.

### Should
13. **Aid zone** (Combat, bottom left, key A, hidden for the first 5 runs): Aid button, offer cards with Gem prices, the Aid tray, first-purchase confirm modal with the fairness line, and disabled rows that still show their price.
14. **Pact:** paid card swap (what it costs, buying state, error) and sell pact.
15. **Missions (Weaponsmith, key 3) = Shard stake board.** Tiers; Stake / Pay / Stone columns; confirm modal; escrow state; locked with reason; open-run state; settle result (won or lost). Starter Shards cannot be staked.
16. **Daily screen (key D, online only):** three claim cards (Daily reward, Weekly bonus, Gem gift), guest and offline states.
17. **Unit inspector** (right-click a 3D unit, works even with a die selected, changes no state). Ask in your reply whether a touch/keyboard opener is needed.
18. **Tooltips** for relic, active and die face (hover and focus).
19. **Pass:** reward detail popup, claimed / locked / claimable states, level card, the Season gift row (Gem). Seasonal Echo Box tab is "coming later" with no Open button.
20. **Titles** pick and unlock (Profile tab, Result unlock line); Profile avatar frame and cosmetic preview; Moon Card button on Land and the "collected today" state.
21. **Echo Box** guest ("Sign in to use this", rates still readable) and offline ("nothing is spent"). **Vault** import panel (Axie ID, Scan), record panel, full state (VAULT_MAX), local-only note. **Leaderboard** row detail and replay. **Team presets** editor and slot picker.

### Could
22. Victory march with skip. 23. Guides tab and Unlocks tab own layouts (10 unlock entries). 24. Battle backdrop per node/boss (confirm whether the 3D stage replaces it).

### Rules for you
Do not invent mechanics, prices or copy that is not above; mark anything unsure as a flag. Copy that needs real data stays a placeholder with a Flag line. Keep every screen at or under 7 groups and one primary action.

**Also deliver, as in round 1:** the README screen table updated with the new ids, the .dc.html design files, one self-contained all-screens HTML, and any new tokens or components added to `tokens.json` and `components.md` (list them first in the README).
