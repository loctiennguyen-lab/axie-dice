# Sim balance expert_none_1000

Runs: 40, wall 68.6s (1.72s/run).

## Muc tieu (Short A0)

- expert 15-25%: 20.0% -> DAT



## Phieu chet theo node (song sot tich luy)

- **expert** (n=40): r4 battle -1 (con 98%); r5 elite -3 (con 90%); r6 boss -2 (con 85%); r7 battle -1 (con 82%); r8 battle -1 (con 80%); r9 battle -1 (con 78%); r9 elite -3 (con 70%); r12 boss -9 (con 48%); r15 elite -2 (con 42%); r18 boss -9 (con 20%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 40 | 25.90 +-3.88 | 22.95 +-2.41 | 28.85 +-3.60 | 19.98 +-3.52 | 5.17 +-0.65 | 0.41 +-0.15 | 20.0 +-12.6 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 40 | 35.10 | 1.39 | 1.18 | 5.07 | 85 | 364 | 0.51 | 0.00 | 0.11 | 0.11 | 0.67 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 13 | 5 | 21 | 24 | 37 | 4.70 | 0.88 | 19.27 | 4.33 | 4.97 | 9.07 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (173) | 0% (0) | 31.7 | 16.8 | 10.3 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 20.0% (8/40) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 16.7% (1/6) |
| expert | beast_bird | 16.7% (1/6) |
| expert | mixed_dmg | 16.7% (1/6) |
| expert | mixed_std | 0.0% (0/6) |
| expert | reptile_bug | 16.7% (1/6) |
| expert | tank_heavy | 40.0% (2/5) |
| expert | thorn_shield | 40.0% (2/5) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 16.7% (2/12) |
| expert | greedy_axis | 21.4% (3/14) |
| expert | random | 21.4% (3/14) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.8 luot (n=298)
- expert|boss: 5.0 luot (n=81)
- expert|elite: 4.1 luot (n=37)

## Chet theo node (chinh sach|loai row)

- expert|battle r4: 1
- expert|battle r7: 1
- expert|battle r8: 1
- expert|battle r9: 1
- expert|boss r12: 9
- expert|boss r18: 9
- expert|boss r6: 2
- expert|elite r15: 2
- expert|elite r5: 3
- expert|elite r9: 3

Tran ket > 20 luot hoac khong ket thuc: 0 / 416

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 35.0% | 12.5% | 36% | 12.5% | 100% | 20.0% (1/5) |  |
| c_dewdrop | stat | 0 | 40.0% | 22.5% | 56% | 22.5% | 100% | 11.1% (1/9) |  |
| c_elder_trunk | stat | 0 | 67.5% | 25.0% | 37% | 25.0% | 100% | 10.0% (1/10) |  |
| c_prime_chain | dice | 0 | 22.5% | 2.5% | 11% | 2.5% | 100% | 100.0% (1/1) |  |
| c_finisher | dice | 0 | 30.0% | 5.0% | 17% | 5.0% | 100% | 50.0% (1/2) |  |
| c_bastion | pos | 0 | 60.0% | 22.5% | 38% | 22.5% | 100% | 22.2% (2/9) |  |
| c_tidecaller | mana | 0 | 52.5% | 10.0% | 19% | 2.5% | 25% | 25.0% (1/4) |  |
| c_mana_pool | mana | 0 | 42.5% | 22.5% | 53% | 22.5% | 100% | 33.3% (3/9) |  |
| c_nest | rule | 0 | 45.0% | 15.0% | 33% | 15.0% | 100% | 33.3% (2/6) |  |
| c_spore_burst | rule | 0 | 45.0% | 20.0% | 44% | 20.0% | 100% | 25.0% (2/8) |  |
| c_fossil | rule | 0 | 25.0% | 12.5% | 50% | 12.5% | 100% | 20.0% (1/5) |  |
| c_meme_copycat | dice | 0 | 25.0% | 2.5% | 10% | 2.5% | 100% | 100.0% (1/1) |  |
| c_meme_nametag | rule | 0 | 27.5% | 2.5% | 9% | 2.5% | 100% | 100.0% (1/1) |  |
| c_meme_jumpy | dice | 0 | 25.0% | 0.0% | 0% | 0.0% | - | - |  |
| rule_none | run_rule | 0 | 5.0% | 5.0% | 100% | 0.0% | 0% | 100.0% (2/2) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 15.0% | 7.5% | 50% | 7.5% | 100% | 0.0% (0/3) |  |
| rule_tundra | run_rule | 0 | 7.5% | 5.0% | 67% | 5.0% | 100% | 0.0% (0/2) | LOW |
| rule_quick_beat | run_rule | 0 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_starfall | run_rule | 0 | 15.0% | 12.5% | 83% | 12.5% | 100% | 20.0% (1/5) |  |
| rule_heavy_finish | run_rule | 0 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| rule_wasteland | run_rule | 0 | 12.5% | 7.5% | 60% | 7.5% | 100% | 66.7% (2/3) |  |
| rule_dry_steppe | run_rule | 0 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_rising_tide | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| rule_upside_down | run_rule | 0 | 20.0% | 12.5% | 62% | 12.5% | 100% | 0.0% (0/5) |  |
| rule_old_forest | run_rule | 0 | 15.0% | 10.0% | 67% | 10.0% | 100% | 25.0% (1/4) |  |
| rule_crow | run_rule | 0 | 15.0% | 10.0% | 67% | 10.0% | 100% | 25.0% (1/4) |  |
| rule_hard_shell | run_rule | 0 | 32.5% | 12.5% | 38% | 12.5% | 100% | 20.0% (1/5) |  |
| rule_balance | run_rule | 0 | 27.5% | 12.5% | 45% | 12.5% | 100% | 0.0% (0/5) |  |
| c_prism | dice | 1 | 10.0% | 2.5% | 25% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_steady_hold | dice | 1 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_kindle | dice | 1 | 7.5% | 5.0% | 67% | 5.0% | 100% | 0.0% (0/2) | LOW |
| c_sonic_shield | dice | 1 | 12.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_fissure | dice | 1 | 7.5% | 7.5% | 100% | 7.5% | 100% | 0.0% (0/3) | LOW |
| c_field_medic | dice | 1 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_plague_spread | dice | 1 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_gatekeeper | pos | 1 | 22.5% | 10.0% | 44% | 10.0% | 100% | 25.0% (1/4) |  |
| c_thorn_growth | pos | 1 | 10.0% | 5.0% | 50% | 5.0% | 100% | 50.0% (1/2) |  |
| c_thorn_shield | stat | 1 | 80.0% | 25.0% | 31% | 25.0% | 100% | 30.0% (3/10) |  |
| c_growing_shell | pos | 1 | 22.5% | 2.5% | 11% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_backline_glow | pos | 1 | 22.5% | 15.0% | 67% | 12.5% | 83% | 16.7% (1/6) |  |
| c_mana_ward | mana | 1 | 30.0% | 12.5% | 42% | 7.5% | 60% | 40.0% (2/5) |  |
| c_overflow | mana | 1 | 27.5% | 10.0% | 36% | 0.0% | 0% | 50.0% (2/4) | DEAD |
| c_thorn_pact | mana | 1 | 27.5% | 17.5% | 64% | 17.5% | 100% | 28.6% (2/7) |  |
| c_dry_well | quest | 1 | 30.0% | 5.0% | 17% | 5.0% | 100% | 50.0% (1/2) |  |
| c_night_watch | quest | 1 | 22.5% | 2.5% | 11% | 2.5% | 100% | 0.0% (0/1) |  |
| c_key_strike | quest | 1 | 27.5% | 2.5% | 9% | 2.5% | 100% | 0.0% (0/1) |  |
| c_collector | quest | 1 | 22.5% | 5.0% | 22% | 5.0% | 100% | 50.0% (1/2) |  |
| c_chimera_hunt | quest | 1 | 20.0% | 5.0% | 25% | 0.0% | 0% | 0.0% (0/2) | DEAD |
| c_golden_egg | rule | 1 | 5.0% | 5.0% | 100% | 5.0% | 100% | 0.0% (0/2) | LOW |
| c_dim_stone | rule | 1 | 25.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_mirror_face | dice | 2 | 7.5% | 5.0% | 67% | 5.0% | 100% | 50.0% (1/2) | LOW |
| c_sixth_die | dice | 2 | 17.5% | 2.5% | 14% | 2.5% | 100% | 100.0% (1/1) |  |
| c_whittle | dice | 2 | 15.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_three_dice | dice | 2 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_concord | dice | 2 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_toxic_still | dice | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_living_wall | pos | 2 | 25.0% | 10.0% | 40% | 10.0% | 100% | 25.0% (1/4) |  |
| c_thorn_rebound | rule | 2 | 17.5% | 5.0% | 29% | 5.0% | 100% | 0.0% (0/2) |  |
| c_open_ranks | pos | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_descend | pos | 2 | 15.0% | 10.0% | 67% | 10.0% | 100% | 25.0% (1/4) |  |
| c_hollow_core | mana | 2 | 30.0% | 7.5% | 25% | 7.5% | 100% | 33.3% (1/3) |  |
| c_deep_current | mana | 2 | 37.5% | 20.0% | 53% | 12.5% | 62% | 12.5% (1/8) |  |
| c_blood_sign | rule | 2 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_loop | rule | 2 | 7.5% | 5.0% | 67% | 5.0% | 100% | 100.0% (2/2) | LOW |
| c_cascade | rule | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_sacrifice | rule | 2 | 12.5% | 7.5% | 60% | 7.5% | 100% | 33.3% (1/3) |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 67.5% (27/40)

Win-rate khi co Loi (n >= 8). Top 10:
- c_mana_pool: 33.3% (3/9)
- c_thorn_shield: 30.0% (3/10)
- c_spore_burst: 25.0% (2/8)
- c_bastion: 22.2% (2/9)
- c_deep_current: 12.5% (1/8)
- c_dewdrop: 11.1% (1/9)
- c_elder_trunk: 10.0% (1/10)

Bottom 10:
- c_elder_trunk: 10.0% (1/10)
- c_dewdrop: 11.1% (1/9)
- c_deep_current: 12.5% (1/8)
- c_bastion: 22.2% (2/9)
- c_spore_burst: 25.0% (2/8)
- c_thorn_shield: 30.0% (3/10)
- c_mana_pool: 33.3% (3/9)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
