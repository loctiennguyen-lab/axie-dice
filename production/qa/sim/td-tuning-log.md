# TD tuning log (Short A0, seed 1000, sim_balance.sh)

Cheap rounds: random/spam n=500-1000, expert n=300 (SE ~2-4 diem). Turns = avg turns battle/boss/elite (random bot).

| Vong | Knob doi (so voi vong truoc) | random | spam | expert | gap | luot b/boss/elite |
|---|---|---|---|---|---|---|
| base | (godot-port 1461d26) | 20.8 | 24.0 | - | - | 3.4/6.1/4.9 |
| r1 | boss_rhythm.hollow_taken_pct 30->50, plating.off_turns 2->1 | 23.2 | 25.6 | - | - | 3.4/6.1/4.9 |
| r2 | difficulty.enemy_dmg_mult 1.2->1.45 | 12.7 | 14.6 | 21.3 | 8.6 | 3.4/6.0/4.6 |

Ghi chu r1: hollow +50 va off_turns 1 khong ha ti le thang (hollow la thuong cho nguoi choi, bot cung huong), nen do kho chung moi la don bay chinh.
| r3 | enemy_dmg_mult 1.45->1.55 | 12.6 | 11.8 | 16.2 | 3.6 | 3.4/6.1/4.9 |
| r4 | enemy_dmg_mult 1.55->1.5, hollow_taken_pct 50->70 | 13.1 | 13.6 | 20.0 | 6.9 | 3.5/5.8/4.5 |

Ghi chu r3: do kho chung ep gap xuong (expert roi nhanh hon random) -> gap giu bang hollow_taken cao hon (thuong Hold/danh lung).
