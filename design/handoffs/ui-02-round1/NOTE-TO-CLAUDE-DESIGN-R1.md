# Ghi chú gửi Claude Design — UI request 02, sau Round 1

Soạn 12/10/2026 từ `REVIEW.md` §7 (art-director, audit ux-designer) + quyết định Liam 12/10 (ngày mùa 30/11, nhận 5 nhà,
làm tròn ≥ .5 lên). Liam dán phần dưới đường kẻ vào Claude Design.

---

```
Round 1 review — thanks, the direction is right and consistent. Verdict: ACCEPT WITH FIXES for the style sheet, hub, combat and defeat. Please send a corrected Round 1 before Round 2.

A. Fixes for Round 1

1. Numbers must reconcile (02e, 02f, 03a-c, README). Our rule: enrage % and attrition % are ADDED, then multiplied once: intent = base x (1 + enrage% + attrition%) x spike_mult (spike_mult = 1 when no spike is due). "84 = 38 x 2.0 x 1.25" is wrong either way (38 x 2.25 = 85.5; round half up: .5 and above rounds up, below .5 rounds down, so 85.5 shows 86). The recap line "Smash 52 incl. enrage +60%" at turn 12 also matches neither (38 x (1 + 0.6 + 0.25) = about 70). Pick a base, compute once with this formula, and put the table in the README. The intent on the plate, on the clock tab ("incl. in N") and in the recap must be the same number.
2. Attrition is +5% on turn 6, +10% on turn 7, ... +25% MAX on turn 10. Frames at turn 7 show +5% and 03a-c (turn 14) show +5%. Fix 02b, 02c, 02d, 02k, 02l, 03a-c.
3. Illegal-target reason (02b, 02c, 02k, 02l): "Airborne - needs a ranged face" is not a rule in our game (and we do not use counter-traits by design). Use a real reason, for example "Heal face: allies only" or "Blank face: nothing to use", and keep the dim-with-reason treatment.
4. 03b (free gift) is only for A0-A2, but the frame shows the A6 badge and the A6 heal. Redraw it at A1 (badge A1, heal 40%) and keep 03a / 03c at A6 (heal 25%). Re-export the contact sheet: tiles 03a-c still show the old "40%" text; the HTML source already says 25%.
5. Prices changed after the brief was sent (final, PA-1):
   - Continue 90, boss fight 180, VIP -25% (so 68 and 135). 180 Gem is about 2.00 USD, 135 about 1.50 USD, 90 about 1.00 USD.
   - Extra reroll 15 (02g, 02h, 02i; Pay 15, about 0.17 USD, "Your Gem 35 -> 20").
   - Delay boss clock 60 (02f, 02h). Swap pact 15, Shop refresh 18, Scout 12, Boon 38, Run Kit 60.
   - Show the real price on disabled rows in the Aid tray too.
   - Extra reroll cap from A3 is 1 per fight (you drew "of 2" on an A6 run). Aid cap is 6, and 4 at A9-A10: add an "of 4" variant. At most 1 Boon per run, and it counts toward the cap.
6. Add this line plainly next to the Aid price list (Aid tray footer, and note for Store/Codex in Round 3): "Aid makes you stronger for one run. Players who buy more can win more. The Pure leaderboard only counts runs without Aid."
7. 02h: the Aid tray covers Axie 1 and the top of the first tray column. Keep the panel off the tray (bottom >= 8 px above the tray top), or narrow it, and keep its top >= 16 px below the lowest monster box.
8. Text size: too many things at 11-12 px (shortcut key hints, NEXT label, intent action label, Aid footer, tray status chips and face strip). Use 12 px as the floor for anything a player must read (action label, "used n of 6", caps, disabled reasons), and say in the README which items are decorative-only. Disabled ink #9A7650 on #DDBF8C / #E8D6B4 is about 2.4:1. That is fine for a disabled button, not for "Reroll - 0 left" or the locked-building labels, so use a darker ink there (e.g. #6E4A30).
9. 02c: the lethal chip replaces the "Big hit in N" tab while hovered. Keep both visible; the player must not lose the spike information when previewing a hit.
10. The "Reroll FX" file is not in the README. Say whether it is part of the delivery. If yes, document it; if no, remove it.
11. "Season 1 - ends 30 Nov 2026" is fine as the working date for now (keep it, mark it as provisional in the README).
12. Missing: Undo. The game has a free undo inside a turn (until reroll or a new turn). Please draw where it sits (right side, near Reroll, far from Aid), its key, and its disabled state.
13. Missing: keyboard map for combat (no gamepad support planned) (die select, target confirm, Aid tray open, Esc to close the tray and the 02i modal, focus ring on every state, Tab order across tray, Reroll, END TURN, Aid). Keyboard-only must work.
14. Each Aid offer should show both caps: the item cap (e.g. 1 per boss) and the run cap ("used n of 6"). In 02f only the run cap is shown.

B. Reminders for Round 2

- Use the Round 1 style sheet only. The Ascension v2 mockups are dark slate with pure black outlines: keep their content and logic, redraw them in the Homeland cream/wood/dusk look with #24140B outlines. Re-outline the five new icons (boss-clock, eternal, pact, drawback, lock) and check them at 24 px.
- Map and pact screens go on the 3D diorama / shared arena frame, not on a 2D background.
- Light boss clock for A0-A3: same tab, 3 pips, starts turn 14, +10% per turn, max +30%. Draw all its states, and show the clock tab at A0-A3 as well.
- Cap of 6 Aid uses (4 from A9), 1 Boon per run counted in it. Remaining Aid offers: Scout 12 (3/run), Shop refresh 18 (2/run), Swap pact 15 (1/pact), Kit 60 / Boon 38 in the Run Setup strip. Every offer shows price and "used / cap", decline button the same size as buy, no countdown.
- Seasonal items are only from the seasonal Echo Box; never show a direct price for them.
- New accounts (first 5 runs that finished at least one fight) have no paid Aid offers, no attrition and no light boss clock. Show that state: no Aid button, no attrition card, no clock tab. Do not draw a dead or greyed Aid button there.
- Keep reduce-flashing variants for every animated element.
- Keep README tags [OBS] / [INF] and mark invented rules and dates.

C. Decisions from our side on your Round 1 open points: the five building choices are accepted (Missions = Weaponsmith,
Echo Box = Alchemy, Vault = GemStorage, Store = Jeweler, Mastery Hall = Armorsmith). The light boss clock for A0–A3 uses
the same tab with 3 pips (from turn 14, +10% per turn, max +30%). All damage numbers use round half up.
```
