# Sim balance expert_auto_1160

Runs: 40, wall 66.0s (1.65s/run).

## Muc tieu (Short A0)

- expert 15-25%: 10.0% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_gambler | 18 | 45.0 | 16.7 +-17.2 | 27.8 | 5.2 | 11.0 | 31.46 |
| expert | a_mana_mine | 6 | 15.0 | 16.7 +-29.8 | 33.3 | 5.5 | 11.0 | 28.84 |
| expert | a_volley | 16 | 40.0 | 0.0 +-0.0 | 18.8 | 6.3 | 18.0 | 27.94 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 5.0% | 2.5% |
| expert | h_gambler | 10.0% | 0.0% |
| expert | h_mana_mine | 7.5% | 2.5% |
| expert | h_kin | 2.5% | 0.0% |
| expert | h_embers | 0.0% | 0.0% |
| expert | h_big_hand | 2.5% | 0.0% |
| expert | combos formed avg | 0.30 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=40): r3 battle -1 (con 98%); r5 elite -3 (con 90%); r6 boss -7 (con 72%); r9 elite -5 (con 60%); r11 battle -2 (con 55%); r12 boss -6 (con 40%); r15 elite -2 (con 35%); r15 battle -1 (con 32%); r17 battle -1 (con 30%); r18 boss -8 (con 10%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 40 | 27.09 +-3.04 | 20.48 +-1.91 | 27.09 +-2.63 | 19.53 +-2.88 | 5.53 +-0.70 | 0.42 +-0.14 | 10.0 +-9.4 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 40 | 31.40 | 1.40 | 1.34 | 4.34 | 96 | 310 | 0.62 | 0.00 | 0.14 | 0.04 | 0.61 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 14 | 5 | 20 | 21 | 39 | 5.33 | 1.20 | 18.32 | 3.73 | 4.95 | 10.00 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (149) | 0% (0) | 34.7 | 18.4 | 10.4 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 10.0% (4/40) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 16.7% (1/6) |
| expert | beast_bird | 33.3% (2/6) |
| expert | mixed_dmg | 16.7% (1/6) |
| expert | mixed_std | 0.0% (0/6) |
| expert | reptile_bug | 0.0% (0/6) |
| expert | tank_heavy | 0.0% (0/5) |
| expert | thorn_shield | 0.0% (0/5) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 8.3% (1/12) |
| expert | greedy_axis | 7.1% (1/14) |
| expert | random | 14.3% (2/14) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.6 luot (n=278)
- expert|boss: 5.3 luot (n=70)
- expert|elite: 3.9 luot (n=39)

## Chet theo node (chinh sach|loai row)

- expert|battle r11: 2
- expert|battle r15: 1
- expert|battle r17: 1
- expert|battle r3: 1
- expert|boss r12: 6
- expert|boss r18: 8
- expert|boss r6: 7
- expert|elite r15: 2
- expert|elite r5: 3
- expert|elite r9: 5

Tran ket > 20 luot hoac khong ket thuc: 0 / 387

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 52.5% | 15.0% | 29% | 15.0% | 100% | 16.7% (1/6) |  |
| c_dewdrop | stat | 0 | 42.5% | 20.0% | 47% | 20.0% | 100% | 12.5% (1/8) |  |
| c_elder_trunk | stat | 0 | 42.5% | 17.5% | 41% | 17.5% | 100% | 14.3% (1/7) |  |
| c_prime_chain | dice | 0 | 27.5% | 5.0% | 18% | 2.5% | 50% | 0.0% (0/2) |  |
| c_finisher | dice | 0 | 27.5% | 10.0% | 36% | 10.0% | 100% | 0.0% (0/4) |  |
| c_bastion | pos | 0 | 55.0% | 17.5% | 32% | 17.5% | 100% | 0.0% (0/7) |  |
| c_tidecaller | mana | 0 | 57.5% | 10.0% | 17% | 7.5% | 75% | 0.0% (0/4) |  |
| c_mana_pool | mana | 0 | 50.0% | 20.0% | 40% | 20.0% | 100% | 0.0% (0/8) |  |
| c_nest | rule | 0 | 22.5% | 10.0% | 44% | 10.0% | 100% | 75.0% (3/4) |  |
| c_spore_burst | rule | 0 | 27.5% | 10.0% | 36% | 10.0% | 100% | 75.0% (3/4) |  |
| c_fossil | rule | 0 | 25.0% | 2.5% | 10% | 2.5% | 100% | 0.0% (0/1) |  |
| c_meme_copycat | dice | 0 | 27.5% | 5.0% | 18% | 5.0% | 100% | 0.0% (0/2) |  |
| c_meme_nametag | rule | 0 | 42.5% | 2.5% | 6% | 2.5% | 100% | 0.0% (0/1) |  |
| c_meme_jumpy | dice | 0 | 12.5% | 7.5% | 60% | 7.5% | 100% | 0.0% (0/3) |  |
| rule_none | run_rule | 0 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_cheap_mana | run_rule | 0 | 20.0% | 10.0% | 50% | 7.5% | 75% | 25.0% (1/4) |  |
| rule_tundra | run_rule | 0 | 15.0% | 5.0% | 33% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_quick_beat | run_rule | 0 | 17.5% | 10.0% | 57% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_starfall | run_rule | 0 | 10.0% | 7.5% | 75% | 7.5% | 100% | 66.7% (2/3) |  |
| rule_heavy_finish | run_rule | 0 | 10.0% | 5.0% | 50% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_wasteland | run_rule | 0 | 7.5% | 7.5% | 100% | 7.5% | 100% | 0.0% (0/3) | LOW |
| rule_dry_steppe | run_rule | 0 | 12.5% | 5.0% | 40% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_rising_tide | run_rule | 0 | 5.0% | 2.5% | 50% | 2.5% | 100% | 100.0% (1/1) | LOW |
| rule_upside_down | run_rule | 0 | 15.0% | 15.0% | 100% | 15.0% | 100% | 0.0% (0/6) |  |
| rule_old_forest | run_rule | 0 | 27.5% | 15.0% | 55% | 15.0% | 100% | 0.0% (0/6) |  |
| rule_crow | run_rule | 0 | 15.0% | 2.5% | 17% | 2.5% | 100% | 0.0% (0/1) |  |
| rule_hard_shell | run_rule | 0 | 15.0% | 0.0% | 0% | 0.0% | - | - |  |
| rule_balance | run_rule | 0 | 25.0% | 15.0% | 60% | 15.0% | 100% | 0.0% (0/6) |  |
| c_prism | dice | 1 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_steady_hold | dice | 1 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_kindle | dice | 1 | 12.5% | 5.0% | 40% | 5.0% | 100% | 0.0% (0/2) |  |
| c_sonic_shield | dice | 1 | 15.0% | 5.0% | 33% | 5.0% | 100% | 0.0% (0/2) |  |
| c_fissure | dice | 1 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_field_medic | dice | 1 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_plague_spread | dice | 1 | 7.5% | 5.0% | 67% | 5.0% | 100% | 50.0% (1/2) | LOW |
| c_gatekeeper | pos | 1 | 27.5% | 15.0% | 55% | 15.0% | 100% | 0.0% (0/6) |  |
| c_thorn_growth | pos | 1 | 20.0% | 7.5% | 38% | 7.5% | 100% | 33.3% (1/3) |  |
| c_thorn_shield | stat | 1 | 75.0% | 20.0% | 27% | 17.5% | 88% | 12.5% (1/8) |  |
| c_growing_shell | pos | 1 | 20.0% | 7.5% | 38% | 5.0% | 67% | 33.3% (1/3) |  |
| c_backline_glow | pos | 1 | 37.5% | 15.0% | 40% | 15.0% | 100% | 16.7% (1/6) |  |
| c_mana_ward | mana | 1 | 27.5% | 12.5% | 45% | 7.5% | 60% | 0.0% (0/5) |  |
| c_overflow | mana | 1 | 20.0% | 17.5% | 88% | 7.5% | 43% | 14.3% (1/7) |  |
| c_thorn_pact | mana | 1 | 25.0% | 12.5% | 50% | 12.5% | 100% | 20.0% (1/5) |  |
| c_dry_well | quest | 1 | 35.0% | 2.5% | 7% | 2.5% | 100% | 0.0% (0/1) |  |
| c_night_watch | quest | 1 | 25.0% | 5.0% | 20% | 5.0% | 100% | 0.0% (0/2) |  |
| c_key_strike | quest | 1 | 12.5% | 2.5% | 20% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_collector | quest | 1 | 20.0% | 7.5% | 38% | 7.5% | 100% | 66.7% (2/3) |  |
| c_chimera_hunt | quest | 1 | 22.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_golden_egg | rule | 1 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_dim_stone | rule | 1 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_mirror_face | dice | 2 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_sixth_die | dice | 2 | 10.0% | 2.5% | 25% | 2.5% | 100% | 100.0% (1/1) |  |
| c_whittle | dice | 2 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_three_dice | dice | 2 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_concord | dice | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_toxic_still | dice | 2 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_living_wall | pos | 2 | 32.5% | 20.0% | 62% | 20.0% | 100% | 0.0% (0/8) |  |
| c_thorn_rebound | rule | 2 | 0.0% | 0.0% | - | 2.5% | - | - | LOW |
| c_open_ranks | pos | 2 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_descend | pos | 2 | 12.5% | 7.5% | 60% | 7.5% | 100% | 33.3% (1/3) |  |
| c_hollow_core | mana | 2 | 25.0% | 15.0% | 60% | 10.0% | 67% | 0.0% (0/6) |  |
| c_deep_current | mana | 2 | 25.0% | 10.0% | 40% | 10.0% | 100% | 25.0% (1/4) |  |
| c_blood_sign | rule | 2 | 10.0% | 2.5% | 25% | 2.5% | 100% | 0.0% (0/1) |  |
| c_loop | rule | 2 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| c_cascade | rule | 2 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| c_sacrifice | rule | 2 | 12.5% | 0.0% | 0% | 0.0% | - | - |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 67.5% (27/40)

Win-rate khi co Loi (n >= 8). Top 10:
- c_thorn_shield: 12.5% (1/8)
- c_dewdrop: 12.5% (1/8)
- c_mana_pool: 0.0% (0/8)
- c_living_wall: 0.0% (0/8)

Bottom 10:
- c_living_wall: 0.0% (0/8)
- c_mana_pool: 0.0% (0/8)
- c_dewdrop: 12.5% (1/8)
- c_thorn_shield: 12.5% (1/8)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
