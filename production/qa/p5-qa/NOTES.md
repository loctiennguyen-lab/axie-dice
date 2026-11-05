# p5-qa: run co Anchor toi shop / Make room / boss (5/11)

Chay lai (khong sua game; bot = `expert` cua `godot/tools/sim_balance.gd`, Anchor auto, team mixed_std, A0, Short):
- Quet seed: `AXIE_SKIP_RULES_FINGERPRINT=1 godot/tools/with_lock.sh <Godot> --headless --path godot res://tests/qa_p5_anchor_run.tscn -- --from=1000 --n=40`
  (in dong `P5ROW seed,anchor,end,nodes,shop_visits,shop_buys,room,boss_fights,boss_won`). 40 seed 1000..1039 ~ 1 phut.
- Anh: `AXIE_P5_SEED=1013 ADT_EVIDENCE_DIR=$PWD/production/qa/p5-qa godot/tools/shot.sh res://tests/qa_p5_shots.tscn 1920x1080` (va 1280x720). Can cua so that, khong headless.
- Ca hai la qa_* (cham, can cua so), khong vao run_tests.sh.

Ket qua quet 1000..1039: 4 WON (1013, 1019, 1026, 1039), 17/40 co shop (mua duoc), 13/40 co Make room (Core thu 7), 31/40 toi boss.
Seed 1013: shop (2 lan) + Make room + 3 boss thang, WON. Seed 1010: shop + Make room + thua boss thu 3.
Anh: shop / make_room / boss_intro / boss_result_won o 1920x1080 + 1280x720; seed1010/boss_result_lost (1920).
