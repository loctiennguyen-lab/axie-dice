# Sim balance expert_a_volley_1080

Runs: 40, wall 61.8s (1.55s/run).

## Muc tieu (Short A0)

- expert 15-25%: 10.0% -> CHUA DAT


## Anchor

| policy | anchor | runs | pick% | win% | awakened% | avg aw node | avg aw combat turn | dmg/turn |
|---|---|---|---|---|---|---|---|---|
| expert | a_volley | 40 | 100.0 | 10.0 +-9.3 | 17.5 | 8.3 | 17.7 | 27.78 |

Dot bien (% run co nac >=1 / nac 2, theo nha, chi run co Anchor) va combo formed trung binh:

| policy | house | tier>=1 | tier 2 |
|---|---|---|---|
| expert | h_volley | 2.5% | 0.0% |
| expert | h_gambler | 7.5% | 2.5% |
| expert | h_mana_mine | 0.0% | 0.0% |
| expert | h_kin | 2.5% | 0.0% |
| expert | h_embers | 2.5% | 0.0% |
| expert | h_big_hand | 2.5% | 2.5% |
| expert | combos formed avg | 0.17 | |


## Phieu chet theo node (song sot tich luy)

- **expert** (n=40): r5 elite -8 (con 80%); r6 boss -5 (con 68%); r9 elite -5 (con 55%); r9 battle -1 (con 52%); r10 battle -1 (con 50%); r12 boss -8 (con 30%); r15 elite -2 (con 25%); r18 boss -6 (con 10%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 40 | 26.14 +-3.53 | 19.53 +-1.94 | 25.79 +-2.43 | 20.02 +-2.60 | 5.00 +-0.62 | 0.57 +-0.16 | 10.0 +-9.4 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 40 | 29.18 | 1.38 | 1.24 | 3.77 | 90 | 272 | 0.62 | 0.00 | 0.10 | 0.03 | 0.64 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 14 | 5 | 20 | 22 | 38 | 4.90 | 1.00 | 16.98 | 3.62 | 4.05 | 10.75 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (145) | 0% (0) | 32.2 | 18.6 | 9.2 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.01; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 10.0% (4/40) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 16.7% (1/6) |
| expert | beast_bird | 16.7% (1/6) |
| expert | mixed_dmg | 0.0% (0/6) |
| expert | mixed_std | 16.7% (1/6) |
| expert | reptile_bug | 0.0% (0/6) |
| expert | tank_heavy | 20.0% (1/5) |
| expert | thorn_shield | 0.0% (0/5) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 8.3% (1/12) |
| expert | greedy_axis | 7.1% (1/14) |
| expert | random | 14.3% (2/14) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.7 luot (n=253)
- expert|boss: 4.8 luot (n=62)
- expert|elite: 3.7 luot (n=47)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 1
- expert|battle r9: 1
- expert|boss r12: 8
- expert|boss r18: 6
- expert|boss r6: 5
- expert|elite r15: 2
- expert|elite r5: 8
- expert|elite r9: 5

Tran ket > 20 luot hoac khong ket thuc: 0 / 362

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 37.5% | 7.5% | 20% | 7.5% | 100% | 0.0% (0/3) |  |
| c_dewdrop | stat | 0 | 37.5% | 17.5% | 47% | 17.5% | 100% | 0.0% (0/7) |  |
| c_elder_trunk | stat | 0 | 45.0% | 22.5% | 50% | 22.5% | 100% | 11.1% (1/9) |  |
| c_prime_chain | dice | 0 | 27.5% | 7.5% | 27% | 7.5% | 100% | 0.0% (0/3) |  |
| c_finisher | dice | 0 | 35.0% | 10.0% | 29% | 10.0% | 100% | 25.0% (1/4) |  |
| c_bastion | pos | 0 | 77.5% | 40.0% | 52% | 37.5% | 94% | 6.2% (1/16) |  |
| c_tidecaller | mana | 0 | 40.0% | 7.5% | 19% | 0.0% | 0% | 0.0% (0/3) | DEAD |
| c_mana_pool | mana | 0 | 17.5% | 5.0% | 29% | 5.0% | 100% | 0.0% (0/2) |  |
| c_nest | rule | 0 | 22.5% | 7.5% | 33% | 7.5% | 100% | 33.3% (1/3) |  |
| c_spore_burst | rule | 0 | 20.0% | 7.5% | 38% | 7.5% | 100% | 66.7% (2/3) |  |
| c_fossil | rule | 0 | 22.5% | 10.0% | 44% | 10.0% | 100% | 0.0% (0/4) |  |
| c_meme_copycat | dice | 0 | 27.5% | 2.5% | 9% | 2.5% | 100% | 100.0% (1/1) |  |
| c_meme_nametag | rule | 0 | 22.5% | 10.0% | 44% | 10.0% | 100% | 25.0% (1/4) |  |
| c_meme_jumpy | dice | 0 | 15.0% | 2.5% | 17% | 2.5% | 100% | 0.0% (0/1) |  |
| rule_none | run_rule | 0 | 15.0% | 10.0% | 67% | 0.0% | 0% | 25.0% (1/4) | DEAD |
| rule_cheap_mana | run_rule | 0 | 10.0% | 7.5% | 75% | 5.0% | 67% | 0.0% (0/3) |  |
| rule_tundra | run_rule | 0 | 10.0% | 5.0% | 50% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_quick_beat | run_rule | 0 | 12.5% | 5.0% | 40% | 5.0% | 100% | 50.0% (1/2) |  |
| rule_starfall | run_rule | 0 | 15.0% | 10.0% | 67% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_heavy_finish | run_rule | 0 | 7.5% | 5.0% | 67% | 5.0% | 100% | 0.0% (0/2) | LOW |
| rule_wasteland | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| rule_dry_steppe | run_rule | 0 | 25.0% | 17.5% | 70% | 17.5% | 100% | 0.0% (0/7) |  |
| rule_rising_tide | run_rule | 0 | 10.0% | 5.0% | 50% | 5.0% | 100% | 0.0% (0/2) |  |
| rule_upside_down | run_rule | 0 | 7.5% | 2.5% | 33% | 2.5% | 100% | 100.0% (1/1) | LOW |
| rule_old_forest | run_rule | 0 | 30.0% | 10.0% | 33% | 10.0% | 100% | 0.0% (0/4) |  |
| rule_crow | run_rule | 0 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_hard_shell | run_rule | 0 | 25.0% | 7.5% | 30% | 7.5% | 100% | 33.3% (1/3) |  |
| rule_balance | run_rule | 0 | 22.5% | 12.5% | 56% | 12.5% | 100% | 0.0% (0/5) |  |
| c_prism | dice | 1 | 12.5% | 2.5% | 20% | 2.5% | 100% | 100.0% (1/1) |  |
| c_steady_hold | dice | 1 | 10.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_kindle | dice | 1 | 15.0% | 5.0% | 33% | 5.0% | 100% | 50.0% (1/2) |  |
| c_sonic_shield | dice | 1 | 10.0% | 7.5% | 75% | 7.5% | 100% | 66.7% (2/3) |  |
| c_fissure | dice | 1 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_field_medic | dice | 1 | 10.0% | 7.5% | 75% | 7.5% | 100% | 33.3% (1/3) |  |
| c_plague_spread | dice | 1 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |
| c_gatekeeper | pos | 1 | 25.0% | 10.0% | 40% | 10.0% | 100% | 0.0% (0/4) |  |
| c_thorn_growth | pos | 1 | 22.5% | 5.0% | 22% | 5.0% | 100% | 0.0% (0/2) |  |
| c_thorn_shield | stat | 1 | 62.5% | 22.5% | 36% | 22.5% | 100% | 0.0% (0/9) |  |
| c_growing_shell | pos | 1 | 30.0% | 15.0% | 50% | 15.0% | 100% | 0.0% (0/6) |  |
| c_backline_glow | pos | 1 | 25.0% | 12.5% | 50% | 10.0% | 80% | 0.0% (0/5) |  |
| c_mana_ward | mana | 1 | 25.0% | 2.5% | 10% | 0.0% | 0% | 0.0% (0/1) | DEAD |
| c_overflow | mana | 1 | 7.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_thorn_pact | mana | 1 | 17.5% | 5.0% | 29% | 5.0% | 100% | 0.0% (0/2) |  |
| c_dry_well | quest | 1 | 20.0% | 2.5% | 12% | 2.5% | 100% | 0.0% (0/1) |  |
| c_night_watch | quest | 1 | 22.5% | 5.0% | 22% | 5.0% | 100% | 50.0% (1/2) |  |
| c_key_strike | quest | 1 | 15.0% | 0.0% | 0% | 0.0% | - | - |  |
| c_collector | quest | 1 | 15.0% | 2.5% | 17% | 2.5% | 100% | 100.0% (1/1) |  |
| c_chimera_hunt | quest | 1 | 12.5% | 2.5% | 20% | 2.5% | 100% | 100.0% (1/1) |  |
| c_golden_egg | rule | 1 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_dim_stone | rule | 1 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_mirror_face | dice | 2 | 12.5% | 0.0% | 0% | 0.0% | - | - |  |
| c_sixth_die | dice | 2 | 20.0% | 7.5% | 38% | 7.5% | 100% | 100.0% (3/3) |  |
| c_whittle | dice | 2 | 17.5% | 5.0% | 29% | 5.0% | 100% | 0.0% (0/2) |  |
| c_three_dice | dice | 2 | 5.0% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_concord | dice | 2 | 2.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_toxic_still | dice | 2 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| c_living_wall | pos | 2 | 22.5% | 17.5% | 78% | 17.5% | 100% | 0.0% (0/7) |  |
| c_thorn_rebound | rule | 2 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| c_open_ranks | pos | 2 | 7.5% | 5.0% | 67% | 7.5% | 100% | 0.0% (0/2) | LOW |
| c_descend | pos | 2 | 20.0% | 10.0% | 50% | 10.0% | 100% | 0.0% (0/4) |  |
| c_hollow_core | mana | 2 | 25.0% | 5.0% | 20% | 5.0% | 100% | 0.0% (0/2) |  |
| c_deep_current | mana | 2 | 15.0% | 2.5% | 17% | 2.5% | 100% | 0.0% (0/1) |  |
| c_blood_sign | rule | 2 | 12.5% | 2.5% | 20% | 2.5% | 100% | 0.0% (0/1) |  |
| c_loop | rule | 2 | 7.5% | 2.5% | 33% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_cascade | rule | 2 | 5.0% | 2.5% | 50% | 2.5% | 100% | 0.0% (0/1) | LOW |
| c_sacrifice | rule | 2 | 10.0% | 5.0% | 50% | 5.0% | 100% | 50.0% (1/2) |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 65.0% (26/40)

Win-rate khi co Loi (n >= 8). Top 10:
- c_elder_trunk: 11.1% (1/9)
- c_bastion: 6.2% (1/16)
- c_thorn_shield: 0.0% (0/9)

Bottom 10:
- c_thorn_shield: 0.0% (0/9)
- c_bastion: 6.2% (1/16)
- c_elder_trunk: 11.1% (1/9)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
