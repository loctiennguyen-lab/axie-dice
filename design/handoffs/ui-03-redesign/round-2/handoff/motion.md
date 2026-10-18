# Motion — A4 Blend

All durations in ms. Godot: create_tween(), set_trans / set_ease as listed. Reduce motion = the "RM" column (usually instant). Nothing flashes more than 3 times a second.

## Combat · dice roll (≈1.5 s per die)
| Step | Property | ms | Godot | Delay | RM |
|---|---|---|---|---|---|
| Throw (stagger) | 3D dice impulse from each Axie / Egg | 480 | RigidBody3D.apply_impulse | 110 × slot index | Skip: dice appear in tray |
| Tumble faces | shown face swaps every 90 ms | ≈1080 | Timer → face mesh | 0 | Final face only |
| First bounce | land + squash (normal 1.06/0.94, crit 1.22/0.78) | 300 | physics; mesh scale TRANS_BACK EASE_OUT | — | — |
| Settle | rest on stage, show result | 180 | body sleeping | — | — |
| Crit landing | camera shake ±6 px, 3 steps | 240 | Camera3D h_offset tween TRANS_SINE | on land | No shake |
| Fly to tray | unproject_position → tray slot | 240 | Tween position TRANS_CUBIC EASE_IN_OUT | after settle | Appear in tray |
| Skip (click stage) | jump every die to its tray slot | 0 | tween.custom_step(9999) | — | — |

Sound: one noise tick per bounce (bandpass 700–1400 Hz, crit 220 Hz heavier), quiet tick on arrive. Sound toggle in Settings.

## Combat · HUD
| Trigger | Property | ms | Trans / Ease | Delay | RM |
|---|---|---|---|---|---|
| Pick a die | die lift −18 px, rotation → 0, side shadow 6 → 12, cream outline on | 120 | TRANS_CUBIC EASE_OUT | 0 | Instant |
| Put die back (Esc / click again) | reverse of pick | 120 | TRANS_CUBIC EASE_IN | 0 | Instant |
| Die used | modulate.a → 0.4, tag "· used" | 120 | TRANS_LINEAR | 0 | Instant |
| Target labels appear | "Target · X" labels fade in over each legal target | 120 | TRANS_LINEAR | 0 | Instant |
| Turn banner in / hold / out | full-width band slides from left, holds, slides out | 200 / 500 / 200 | TRANS_CUBIC EASE_OUT / EASE_IN | 0 | Fade 120 only |
| Enemy acts | acting enemy row gets cream outline; line text swaps to result | 120 | TRANS_LINEAR | 300 between enemies | Instant |
| Egg hatch | Egg 3D pops in (scale 0 → 1), its die is thrown | 240 | TRANS_BACK EASE_OUT | 0 | Appear |
| Defeat panel | scrim fade, panel scale 0.96 → 1 | 240 | TRANS_CUBIC EASE_OUT | 0; button live after 1000 | Fade |

## Run screens
| Trigger | Property | ms | Trans / Ease | Delay | RM |
|---|---|---|---|---|---|
| Card selected (Reward, Pact) | translate y 0 → −18, cream outline | 160 | TRANS_CUBIC EASE_OUT | 0 | Instant |
| Reward reroll | cards flip out (scale x 1 → 0) and back with new content | 240 | TRANS_CUBIC EASE_IN_OUT | 60 × card | Swap |
| Treasure open | lid opens, then relic card rises 40 px + fade | 600 + 240 | TRANS_BACK EASE_OUT | 0 | Show opened state |
| Scrim in / out | modulate.a 0 → 1 | 160 | TRANS_LINEAR | 0 | Instant |
| Dialog in | scale 0.96 → 1 + fade | 160 | TRANS_CUBIC EASE_OUT | 0 | Fade |
| Toast | slide down 16 px + fade in, hold 4000, fade out | 160 / 4000 / 160 | TRANS_CUBIC EASE_OUT | 0 | Fade |
| Skeleton pulse | modulate.a 0.5 ↔ 1 | 1400 loop | TRANS_SINE EASE_IN_OUT | 0 | Static 0.75 |
| Button press | translate y +2, shadow 4 → 2 | 60 | TRANS_LINEAR | 0 | Same (no motion) |

## 3D ↔ HUD hand-offs
| Trigger | What happens | ms | Trans / Ease | RM |
|---|---|---|---|---|
| Open a building (Land hub) | HUD plates fade out 120; camera dollies to the building 600; screen panel fades in 160 | 880 | TRANS_CUBIC EASE_IN_OUT | Cut to the screen |
| Enter a fight (Run map → Combat) | map fades to black 200; combat stage fades in 240; dice thrown 300 after | 740 | TRANS_LINEAR | Cut, dice appear in tray |
| Victory run through the gate (Result win) | party runs into the Portal 1200 while scrim fades in; plate appears at 900 | 1200 | TRANS_CUBIC EASE_OUT | Show plate at once |
| Hover a building | model scale 1 → 1.04, name plate gets its sub-line | 120 | TRANS_CUBIC EASE_OUT | Sub-line only |

Values marked in the design files' notes override this table only where they are more specific.
