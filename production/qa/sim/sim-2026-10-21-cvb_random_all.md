# Sim balance cvb_random_all

Runs: 400, wall 0.0s (0.00s/run).

## Muc tieu (Short A0)

- random_legal <= 5%: 9.2% -> CHUA DAT


## Phieu chet theo node (song sot tich luy)

- **random_legal** (n=400): r3 battle -2 (con 100%); r4 battle -34 (con 91%); r5 battle -10 (con 88%); r5 elite -56 (con 74%); r6 boss -51 (con 62%); r7 battle -4 (con 61%); r8 battle -16 (con 57%); r9 elite -43 (con 46%); r9 battle -4 (con 45%); r10 battle -3 (con 44%); r11 battle -6 (con 43%); r12 boss -42 (con 32%); r13 battle -1 (con 32%); r14 battle -3 (con 31%); r15 elite -27 (con 24%); r15 battle -4 (con 24%); r18 boss -57 (con 9%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| random_legal | 400 | 18.74 +-0.93 | 19.22 +-0.59 | 19.22 +-0.59 | 13.76 +-0.86 | 6.18 +-0.29 | 0.51 +-0.05 | 9.2 +-2.8 | 


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| random_legal | 400 | 32.17 | 1.36 | 0.91 | 6.88 | 67 | 507 | 0.73 | 0.00 | 0.26 | 0.05 | 0.32 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| random_legal | 6 | 0 | 5 | 6 | 84 | 1.48 | 0.07 | 4.75 | 0.70 | 0.82 | 7.82 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| random_legal | 0% (0) | 100% (280) | 0% (0) | 15.4 | 7.5 | 7.5 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: random_legal 0.01; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| random_legal | 0 | 9.2% (37/400) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| random_legal | aqua_plant | 1.7% (1/60) |
| random_legal | beast_bird | 6.7% (4/60) |
| random_legal | mixed_dmg | 11.7% (7/60) |
| random_legal | mixed_std | 11.7% (7/60) |
| random_legal | reptile_bug | 15.0% (9/60) |
| random_legal | tank_heavy | 8.0% (4/50) |
| random_legal | thorn_shield | 10.0% (5/50) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| random_legal | random | 9.2% (37/400) |


## So luot trung binh moi tran (chinh sach|loai)

- random_legal|battle: 3.4 luot (n=2423)
- random_legal|boss: 5.9 luot (n=563)
- random_legal|elite: 4.3 luot (n=321)

## Chet theo node (chinh sach|loai row)

- random_legal|battle r10: 3
- random_legal|battle r11: 6
- random_legal|battle r13: 1
- random_legal|battle r14: 3
- random_legal|battle r15: 4
- random_legal|battle r3: 2
- random_legal|battle r4: 34
- random_legal|battle r5: 10
- random_legal|battle r7: 4
- random_legal|battle r8: 16
- random_legal|battle r9: 4
- random_legal|boss r12: 42
- random_legal|boss r18: 57
- random_legal|boss r6: 51
- random_legal|elite r15: 27
- random_legal|elite r5: 56
- random_legal|elite r9: 43

Tran ket > 20 luot hoac khong ket thuc: 2 / 3307

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 39.5% | 11.0% | 28% | 11.0% | 100% | 20.5% (9/44) |  |
| c_dewdrop | stat | 0 | 38.8% | 14.2% | 37% | 14.2% | 100% | 10.5% (6/57) |  |
| c_elder_trunk | stat | 0 | 40.5% | 11.5% | 28% | 11.5% | 100% | 19.6% (9/46) |  |
| c_prime_chain | dice | 0 | 22.2% | 7.0% | 31% | 7.0% | 100% | 7.1% (2/28) |  |
| c_finisher | dice | 0 | 22.2% | 7.8% | 35% | 7.5% | 97% | 3.2% (1/31) |  |
| c_bastion | pos | 0 | 65.2% | 21.2% | 33% | 21.0% | 99% | 9.4% (8/85) |  |
| c_tidecaller | mana | 0 | 47.2% | 19.8% | 42% | 1.5% | 8% | 10.1% (8/79) |  |
| c_mana_pool | mana | 0 | 38.5% | 11.8% | 31% | 11.0% | 94% | 8.5% (4/47) |  |
| c_nest | rule | 0 | 34.8% | 10.8% | 31% | 10.8% | 100% | 14.0% (6/43) |  |
| c_spore_burst | rule | 0 | 31.0% | 9.2% | 30% | 9.2% | 100% | 35.1% (13/37) |  |
| c_fossil | rule | 0 | 24.0% | 7.8% | 32% | 6.2% | 81% | 9.7% (3/31) |  |
| c_meme_copycat | dice | 0 | 23.8% | 8.5% | 36% | 6.8% | 79% | 11.8% (4/34) |  |
| c_meme_nametag | rule | 0 | 26.8% | 9.2% | 35% | 8.8% | 95% | 13.5% (5/37) |  |
| c_meme_jumpy | dice | 0 | 22.0% | 6.5% | 30% | 6.5% | 100% | 11.5% (3/26) |  |
| rule_none | run_rule | 0 | 8.8% | 3.2% | 37% | 0.0% | 0% | 7.7% (1/13) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 12.8% | 7.2% | 57% | 6.8% | 93% | 3.4% (1/29) |  |
| rule_tundra | run_rule | 0 | 11.5% | 5.8% | 50% | 0.0% | 0% | 4.3% (1/23) | DEAD |
| rule_quick_beat | run_rule | 0 | 15.8% | 8.5% | 54% | 7.2% | 85% | 11.8% (4/34) |  |
| rule_starfall | run_rule | 0 | 12.8% | 7.0% | 55% | 7.0% | 100% | 14.3% (4/28) |  |
| rule_heavy_finish | run_rule | 0 | 11.0% | 6.0% | 55% | 6.0% | 100% | 8.3% (2/24) |  |
| rule_wasteland | run_rule | 0 | 11.2% | 5.0% | 44% | 5.0% | 100% | 10.0% (2/20) |  |
| rule_dry_steppe | run_rule | 0 | 11.8% | 6.0% | 51% | 6.0% | 100% | 4.2% (1/24) |  |
| rule_rising_tide | run_rule | 0 | 12.0% | 7.2% | 60% | 7.2% | 100% | 17.2% (5/29) |  |
| rule_upside_down | run_rule | 0 | 11.8% | 5.5% | 47% | 5.5% | 100% | 9.1% (2/22) |  |
| rule_old_forest | run_rule | 0 | 21.5% | 10.5% | 49% | 10.5% | 100% | 11.9% (5/42) |  |
| rule_crow | run_rule | 0 | 11.0% | 5.0% | 45% | 3.5% | 70% | 5.0% (1/20) |  |
| rule_hard_shell | run_rule | 0 | 21.2% | 7.5% | 35% | 7.5% | 100% | 16.7% (5/30) |  |
| rule_balance | run_rule | 0 | 27.0% | 15.5% | 57% | 15.5% | 100% | 4.8% (3/62) |  |
| c_prism | dice | 1 | 9.5% | 4.2% | 45% | 2.8% | 65% | 11.8% (2/17) | LOW |
| c_steady_hold | dice | 1 | 9.0% | 2.2% | 25% | 0.0% | 0% | 11.1% (1/9) | LOW DEAD |
| c_kindle | dice | 1 | 8.2% | 2.8% | 33% | 0.0% | 0% | 0.0% (0/11) | LOW DEAD |
| c_sonic_shield | dice | 1 | 8.0% | 2.0% | 25% | 2.0% | 100% | 37.5% (3/8) | LOW |
| c_fissure | dice | 1 | 8.5% | 2.2% | 26% | 2.2% | 100% | 11.1% (1/9) | LOW |
| c_field_medic | dice | 1 | 8.8% | 3.2% | 37% | 3.2% | 100% | 7.7% (1/13) | LOW |
| c_plague_spread | dice | 1 | 5.2% | 1.8% | 33% | 1.8% | 100% | 14.3% (1/7) | LOW |
| c_gatekeeper | pos | 1 | 17.0% | 4.0% | 24% | 4.0% | 100% | 18.8% (3/16) |  |
| c_thorn_growth | pos | 1 | 16.5% | 7.5% | 45% | 7.5% | 100% | 26.7% (8/30) |  |
| c_thorn_shield | stat | 1 | 57.5% | 14.8% | 26% | 14.5% | 98% | 23.7% (14/59) |  |
| c_growing_shell | pos | 1 | 19.8% | 7.0% | 35% | 4.2% | 61% | 17.9% (5/28) |  |
| c_backline_glow | pos | 1 | 18.5% | 6.2% | 34% | 5.8% | 92% | 16.0% (4/25) |  |
| c_mana_ward | mana | 1 | 22.2% | 8.8% | 39% | 6.8% | 77% | 22.9% (8/35) |  |
| c_overflow | mana | 1 | 19.5% | 6.5% | 33% | 4.2% | 65% | 7.7% (2/26) |  |
| c_thorn_pact | mana | 1 | 16.2% | 6.5% | 40% | 6.2% | 96% | 15.4% (4/26) |  |
| c_dry_well | quest | 1 | 16.5% | 6.8% | 41% | 6.8% | 100% | 14.8% (4/27) |  |
| c_night_watch | quest | 1 | 16.8% | 6.5% | 39% | 6.5% | 100% | 19.2% (5/26) |  |
| c_key_strike | quest | 1 | 18.5% | 5.8% | 31% | 0.0% | 0% | 4.3% (1/23) | DEAD |
| c_collector | quest | 1 | 14.8% | 4.5% | 31% | 4.5% | 100% | 16.7% (3/18) |  |
| c_chimera_hunt | quest | 1 | 19.0% | 6.5% | 34% | 4.8% | 73% | 30.8% (8/26) |  |
| c_golden_egg | rule | 1 | 4.5% | 1.2% | 28% | 1.2% | 100% | 0.0% (0/5) | LOW |
| c_dim_stone | rule | 1 | 8.8% | 3.0% | 34% | 3.0% | 100% | 8.3% (1/12) | LOW |
| c_mirror_face | dice | 2 | 6.5% | 3.2% | 50% | 3.2% | 100% | 23.1% (3/13) | LOW |
| c_sixth_die | dice | 2 | 7.8% | 2.0% | 26% | 2.0% | 100% | 37.5% (3/8) | LOW |
| c_whittle | dice | 2 | 7.8% | 3.0% | 39% | 3.0% | 100% | 8.3% (1/12) | LOW |
| c_three_dice | dice | 2 | 9.2% | 1.8% | 19% | 1.8% | 100% | 14.3% (1/7) | LOW |
| c_concord | dice | 2 | 7.5% | 2.8% | 37% | 2.5% | 82% | 0.0% (0/11) | LOW |
| c_toxic_still | dice | 2 | 6.2% | 3.0% | 48% | 3.2% | 100% | 25.0% (3/12) | LOW |
| c_living_wall | pos | 2 | 23.5% | 7.5% | 32% | 7.8% | 100% | 23.3% (7/30) |  |
| c_thorn_rebound | rule | 2 | 8.2% | 2.5% | 30% | 2.8% | 90% | 0.0% (0/10) | LOW |
| c_open_ranks | pos | 2 | 5.2% | 0.8% | 14% | 0.8% | 100% | 0.0% (0/3) | LOW |
| c_descend | pos | 2 | 10.8% | 3.2% | 30% | 3.5% | 100% | 38.5% (5/13) |  |
| c_hollow_core | mana | 2 | 23.8% | 8.0% | 34% | 7.2% | 91% | 12.5% (4/32) |  |
| c_deep_current | mana | 2 | 23.2% | 6.2% | 27% | 4.8% | 72% | 8.0% (2/25) |  |
| c_blood_sign | rule | 2 | 8.2% | 2.5% | 30% | 2.5% | 100% | 10.0% (1/10) | LOW |
| c_loop | rule | 2 | 6.5% | 2.2% | 35% | 1.8% | 67% | 11.1% (1/9) | LOW |
| c_cascade | rule | 2 | 7.8% | 3.5% | 45% | 4.0% | 93% | 14.3% (2/14) | LOW |
| c_sacrifice | rule | 2 | 11.5% | 3.0% | 26% | 3.2% | 100% | 16.7% (2/12) |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 48.0% (192/400)

Win-rate khi co Loi (n >= 8). Top 10:
- c_sixth_die: 37.5% (3/8)
- c_sonic_shield: 37.5% (3/8)
- c_descend: 35.7% (5/14)
- c_spore_burst: 35.1% (13/37)
- c_chimera_hunt: 30.8% (8/26)
- c_thorn_growth: 26.7% (8/30)
- c_thorn_shield: 23.7% (14/59)
- c_toxic_still: 23.1% (3/13)
- c_mirror_face: 23.1% (3/13)
- c_mana_ward: 22.9% (8/35)

Bottom 10:
- c_thorn_rebound: 0.0% (0/12)
- c_kindle: 0.0% (0/11)
- c_concord: 0.0% (0/12)
- c_finisher: 3.2% (1/31)
- c_key_strike: 4.3% (1/23)
- c_prime_chain: 7.1% (2/28)
- c_field_medic: 7.7% (1/13)
- c_overflow: 7.7% (2/26)
- c_deep_current: 7.7% (2/26)
- c_whittle: 8.3% (1/12)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_nest + c_thorn_shield: 50.0% (4/8)
- c_spore_burst + c_thorn_shield: 50.0% (6/12)
- c_living_wall + c_spore_burst: 50.0% (4/8)
- c_early_scales + c_thorn_shield: 40.0% (4/10)
- c_chimera_hunt + c_tidecaller: 40.0% (4/10)
- c_deep_current + c_tidecaller: 0.0% (0/8)
- c_backline_glow + c_bastion: 0.0% (0/12)
- c_mana_pool + c_tidecaller: 7.7% (1/13)
- c_dewdrop + c_thorn_shield: 9.1% (1/11)
- c_overflow + c_tidecaller: 10.0% (1/10)
