# Sim balance expert_a_mana_mine_1040

Runs: 40, wall 63.5s (1.59s/run).

## Muc tieu (Short A0)

- expert 15-25%: 12.5% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_mana_mine | 40 | 100.0 | 12.5 +-10.2 | 27.5 | 7.2 | 14.5 | 28.47 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 0.0% | 0.0% |
| expert | h_gambler | 10.0% | 0.0% |
| expert | h_mana_mine | 12.5% | 0.0% |
| expert | h_kin | 2.5% | 0.0% |
| expert | h_embers | 0.0% | 0.0% |
| expert | h_big_hand | 0.0% | 0.0% |
| expert | combos formed avg | 0.25 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=40): r4 battle -2 (con 95%); r5 elite -5 (con 82%); r6 boss -4 (con 72%); r7 battle -1 (con 70%); r11 battle -1 (con 68%); r12 boss -9 (con 45%); r15 elite -4 (con 35%); r18 boss -9 (con 12%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 40 | 26.71 +-3.40 | 20.72 +-1.89 | 26.92 +-2.23 | 20.03 +-2.90 | 5.28 +-0.58 | 0.26 +-0.17 | 12.5 +-10.4 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 40 | 32.05 | 2.00 | 1.44 | 6.84 | 72 | 342 | 0.55 | 0.00 | 0.40 | 0.34 | 0.71 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 14 | 3 | 24 | 24 | 35 | 5.65 | 0.70 | 18.62 | 3.62 | 7.95 | 9.47 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (145) | 0% (0) | 33.0 | 27.0 | 16.0 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 12.5% (5/40) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 0.0% (0/6) |
| expert | beast_bird | 0.0% (0/6) |
| expert | mixed_dmg | 33.3% (2/6) |
| expert | mixed_std | 16.7% (1/6) |
| expert | reptile_bug | 0.0% (0/6) |
| expert | tank_heavy | 20.0% (1/5) |
| expert | thorn_shield | 20.0% (1/5) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 8.3% (1/12) |
| expert | greedy_axis | 14.3% (2/14) |
| expert | random | 14.3% (2/14) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.8 luot (n=269)
- expert|boss: 5.2 luot (n=74)
- expert|elite: 3.6 luot (n=41)

## Chet theo node (chinh sach|loai row)

- expert|battle r11: 1
- expert|battle r4: 2
- expert|battle r7: 1
- expert|boss r12: 9
- expert|boss r18: 9
- expert|boss r6: 4
- expert|elite r15: 4
- expert|elite r5: 5

Tran ket > 20 luot hoac khong ket thuc: 0 / 384

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 35.0% | 7.5% | 21% | 7.5% | 100% | 33.3% (1/3) |  |
| c_dewdrop | stat | 0 | 42.5% | 20.0% | 47% | 20.0% | 100% | 25.0% (2/8) |  |
| c_elder_trunk | stat | 0 | 35.0% | 15.0% | 43% | 15.0% | 100% | 33.3% (2/6) |  |
| c_prime_chain | dice | 0 | 22.5% | 5.0% | 22% | 5.0% | 100% | 0.0% (0/2) |  |
| c_finisher | dice | 0 | 22.5% | 10.0% | 44% | 7.5% | 75% | 50.0% (2/4) |  |
| c_bastion | pos | 0 | 65.0% | 15.0% | 23% | 15.0% | 100% | 0.0% (0/6) |  |
| c_tidecaller | mana | 0 | 62.5% | 37.5% | 60% | 15.0% | 40% | 20.0% (3/15) |  |
| c_mana_pool | mana | 0 | 37.5% | 15.0% | 40% | 15.0% | 100% | 0.0% (0/6) |  |
| c_nest | rule | 0 | 40.0% | 15.0% | 38% | 15.0% | 100% | 33.3% (2/6) |  |
| c_spore_burst | rule | 0 | 45.0% | 12.5% | 28% | 12.5% | 100% | 40.0% (2/5) |  |
| c_fossil | rule | 0 | 30.0% | 7.5% | 25% | 7.5% | 100% | 33.3% (1/3) |  |
| c_meme_copycat | dice | 0 | 17.5% | 5.0% | 29% | 2.5% | 50% | 0.0% (0/2) |  |
| c_meme_nametag | rule | 0 | 42.5% | 12.5% | 29% | 12.5% | 100% | 20.0% (1/5) |  |
| c_meme_jumpy | dice | 0 | 17.5% | 0.0% | 0% | 0.0% | - | - |  |
| rule_none | run_rule | 0 | 5.0% | 2.5% | 50% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| rule_tundra | run_rule | 0 | 10.0% | 7.5% | 75% | 7.5% | 100% | 0.0% (0/3) |  |
| rule_quick_beat | run_rule | 0 | 7.5% | 5.0% | 67% | 5.0% | 100% | 0.0% (0/2) | LOW |
| rule_starfall | run_rule | 0 | 10.0% | 5.0% | 50% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_heavy_finish | run_rule | 0 | 12.5% | 7.5% | 60% | 7.5% | 100% | 0.0% (0/3) |  |
| rule_wasteland | run_rule | 0 | 17.5% | 15.0% | 86% | 15.0% | 100% | 0.0% (0/6) |  |
| rule_dry_steppe | run_rule | 0 | 22.5% | 7.5% | 33% | 7.5% | 100% | 33.3% (1/3) |  |
| rule_rising_tide | run_rule | 0 | 12.5% | 10.0% | 80% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_upside_down | run_rule | 0 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| rule_old_forest | run_rule | 0 | 22.5% | 7.5% | 33% | 7.5% | 100% | 66.7% (2/3) |  |
| rule_crow | run_rule | 0 | 15.0% | 7.5% | 50% | 5.0% | 67% | 0.0% (0/3) |  |
| rule_hard_shell | run_rule | 0 | 12.5% | 5.0% | 40% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_balance | run_rule | 0 | 32.5% | 15.0% | 46% | 15.0% | 100% | 33.3% (2/6) |  |
| c_prism | dice | 1 | 7.5% | 2.5% | 33% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |
| c_steady_hold | dice | 1 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_kindle | dice | 1 | 17.5% | 12.5% | 71% | 12.5% | 100% | 0.0% (0/5) |  |
| c_sonic_shield | dice | 1 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_fissure | dice | 1 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_field_medic | dice | 1 | 12.5% | 7.5% | 60% | 7.5% | 100% | 33.3% (1/3) |  |
| c_plague_spread | dice | 1 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_gatekeeper | pos | 1 | 15.0% | 5.0% | 33% | 5.0% | 100% | 50.0% (1/2) |  |
| c_thorn_growth | pos | 1 | 15.0% | 2.5% | 17% | 2.5% | 100% | 0.0% (0/1) |  |
| c_thorn_shield | stat | 1 | 62.5% | 12.5% | 20% | 12.5% | 100% | 20.0% (1/5) |  |
| c_growing_shell | pos | 1 | 22.5% | 10.0% | 44% | 5.0% | 50% | 0.0% (0/4) |  |
| c_backline_glow | pos | 1 | 35.0% | 7.5% | 21% | 7.5% | 100% | 0.0% (0/3) |  |
| c_mana_ward | mana | 1 | 35.0% | 2.5% | 7% | 2.5% | 100% | 0.0% (0/1) |  |
| c_overflow | mana | 1 | 32.5% | 12.5% | 38% | 5.0% | 40% | 0.0% (0/5) |  |
| c_thorn_pact | mana | 1 | 30.0% | 15.0% | 50% | 15.0% | 100% | 0.0% (0/6) |  |
| c_dry_well | quest | 1 | 17.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_night_watch | quest | 1 | 22.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_key_strike | quest | 1 | 15.0% | 5.0% | 33% | 5.0% | 100% | 0.0% (0/2) |  |
| c_collector | quest | 1 | 17.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_chimera_hunt | quest | 1 | 25.0% | 10.0% | 40% | 7.5% | 75% | 0.0% (0/4) |  |
| c_golden_egg | rule | 1 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_dim_stone | rule | 1 | 15.0% | 5.0% | 33% | 5.0% | 100% | 100.0% (2/2) |  |
| c_mirror_face | dice | 2 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_sixth_die | dice | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_whittle | dice | 2 | 10.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_three_dice | dice | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_concord | dice | 2 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_toxic_still | dice | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_living_wall | pos | 2 | 12.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_thorn_rebound | rule | 2 | 7.5% | 2.5% | 33% | 0.0% | 0% | 0.0% (0/1) | LOW DEAD |
| c_open_ranks | pos | 2 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_descend | pos | 2 | 22.5% | 10.0% | 44% | 7.5% | 75% | 25.0% (1/4) |  |
| c_hollow_core | mana | 2 | 22.5% | 10.0% | 44% | 12.5% | 100% | 50.0% (2/4) |  |
| c_deep_current | mana | 2 | 37.5% | 17.5% | 47% | 17.5% | 86% | 14.3% (1/7) |  |
| c_blood_sign | rule | 2 | 10.0% | 5.0% | 50% | 5.0% | 100% | 0.0% (0/2) |  |
| c_loop | rule | 2 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_cascade | rule | 2 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_sacrifice | rule | 2 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 65.0% (26/40)

Win-rate khi co Loi (n >= 8). Top 10:
- c_deep_current: 25.0% (2/8)
- c_dewdrop: 25.0% (2/8)
- c_tidecaller: 20.0% (3/15)

Bottom 10:
- c_tidecaller: 20.0% (3/15)
- c_dewdrop: 25.0% (2/8)
- c_deep_current: 25.0% (2/8)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
