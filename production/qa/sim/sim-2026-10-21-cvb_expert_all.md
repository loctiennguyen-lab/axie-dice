# Sim balance cvb_expert_all

Runs: 400, wall 0.0s (0.00s/run).

## Muc tieu (Short A0)

- expert 15-25%: 13.5% -> CHUA DAT


## Phieu chet theo node (song sot tich luy)

- **expert** (n=400): r4 battle -6 (con 98%); r5 elite -27 (con 92%); r6 boss -28 (con 85%); r7 battle -4 (con 84%); r8 battle -3 (con 83%); r9 elite -49 (con 71%); r9 battle -2 (con 70%); r10 battle -1 (con 70%); r11 battle -2 (con 70%); r12 boss -70 (con 52%); r13 battle -3 (con 51%); r14 battle -4 (con 50%); r15 elite -40 (con 40%); r15 battle -2 (con 40%); r17 battle -1 (con 40%); r18 boss -104 (con 14%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 400 | 26.75 +-1.08 | 22.65 +-0.65 | 28.40 +-0.84 | 20.15 +-0.94 | 5.13 +-0.23 | 0.54 +-0.05 | 13.5 +-3.4 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 400 | 33.89 | 1.45 | 1.20 | 4.64 | 82 | 319 | 0.59 | 0.00 | 0.22 | 0.08 | 0.56 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 14 | 5 | 19 | 22 | 40 | 5.13 | 0.94 | 17.34 | 3.85 | 4.52 | 10.98 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (1538) | 0% (0) | 30.8 | 16.7 | 8.9 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.01; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 13.5% (54/400) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 6.7% (4/60) |
| expert | beast_bird | 11.7% (7/60) |
| expert | mixed_dmg | 13.3% (8/60) |
| expert | mixed_std | 10.0% (6/60) |
| expert | reptile_bug | 30.0% (18/60) |
| expert | tank_heavy | 6.0% (3/50) |
| expert | thorn_shield | 16.0% (8/50) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | random | 13.5% (54/400) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 2.7 luot (n=2955)
- expert|boss: 4.9 luot (n=803)
- expert|elite: 3.9 luot (n=442)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 1
- expert|battle r11: 2
- expert|battle r13: 3
- expert|battle r14: 4
- expert|battle r15: 2
- expert|battle r17: 1
- expert|battle r4: 6
- expert|battle r7: 4
- expert|battle r8: 3
- expert|battle r9: 2
- expert|boss r12: 70
- expert|boss r18: 104
- expert|boss r6: 28
- expert|elite r15: 40
- expert|elite r5: 27
- expert|elite r9: 49

Tran ket > 20 luot hoac khong ket thuc: 3 / 4200

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 51.2% | 16.2% | 32% | 16.2% | 100% | 27.7% (18/65) |  |
| c_dewdrop | stat | 0 | 49.2% | 15.0% | 30% | 15.0% | 100% | 18.3% (11/60) |  |
| c_elder_trunk | stat | 0 | 46.5% | 15.5% | 33% | 15.5% | 100% | 24.2% (15/62) |  |
| c_prime_chain | dice | 0 | 26.8% | 7.2% | 27% | 6.5% | 90% | 20.7% (6/29) |  |
| c_finisher | dice | 0 | 22.8% | 6.5% | 29% | 6.5% | 100% | 11.5% (3/26) |  |
| c_bastion | pos | 0 | 68.8% | 22.0% | 32% | 22.0% | 100% | 9.1% (8/88) |  |
| c_tidecaller | mana | 0 | 49.8% | 18.0% | 36% | 9.0% | 50% | 11.1% (8/72) |  |
| c_mana_pool | mana | 0 | 46.0% | 16.8% | 36% | 14.2% | 85% | 13.4% (9/67) |  |
| c_nest | rule | 0 | 43.2% | 16.8% | 39% | 16.8% | 100% | 20.9% (14/67) |  |
| c_spore_burst | rule | 0 | 34.5% | 10.2% | 30% | 10.2% | 100% | 61.0% (25/41) |  |
| c_fossil | rule | 0 | 25.8% | 7.8% | 30% | 7.5% | 97% | 12.9% (4/31) |  |
| c_meme_copycat | dice | 0 | 22.5% | 8.2% | 37% | 7.8% | 94% | 18.2% (6/33) |  |
| c_meme_nametag | rule | 0 | 37.5% | 13.0% | 35% | 12.2% | 94% | 19.2% (10/52) |  |
| c_meme_jumpy | dice | 0 | 21.5% | 6.2% | 29% | 6.2% | 100% | 16.0% (4/25) |  |
| rule_none | run_rule | 0 | 8.0% | 4.2% | 53% | 0.0% | 0% | 11.8% (2/17) | LOW DEAD |
| rule_cheap_mana | run_rule | 0 | 11.5% | 6.2% | 54% | 5.2% | 84% | 8.0% (2/25) |  |
| rule_tundra | run_rule | 0 | 13.2% | 6.8% | 51% | 6.8% | 100% | 3.7% (1/27) |  |
| rule_quick_beat | run_rule | 0 | 12.0% | 6.2% | 52% | 6.0% | 96% | 4.0% (1/25) |  |
| rule_starfall | run_rule | 0 | 10.5% | 5.0% | 48% | 5.0% | 100% | 10.0% (2/20) |  |
| rule_heavy_finish | run_rule | 0 | 9.8% | 5.5% | 56% | 5.5% | 100% | 13.6% (3/22) | LOW |
| rule_wasteland | run_rule | 0 | 12.5% | 7.2% | 58% | 7.2% | 100% | 13.8% (4/29) |  |
| rule_dry_steppe | run_rule | 0 | 15.5% | 8.8% | 56% | 8.8% | 100% | 8.6% (3/35) |  |
| rule_rising_tide | run_rule | 0 | 15.5% | 8.0% | 52% | 8.0% | 100% | 18.8% (6/32) |  |
| rule_upside_down | run_rule | 0 | 12.8% | 7.2% | 57% | 7.2% | 100% | 20.7% (6/29) |  |
| rule_old_forest | run_rule | 0 | 20.5% | 9.2% | 45% | 9.2% | 100% | 21.6% (8/37) |  |
| rule_crow | run_rule | 0 | 11.8% | 4.5% | 38% | 4.5% | 100% | 16.7% (3/18) |  |
| rule_hard_shell | run_rule | 0 | 18.2% | 8.8% | 48% | 8.8% | 100% | 17.1% (6/35) |  |
| rule_balance | run_rule | 0 | 28.2% | 12.2% | 43% | 12.2% | 100% | 14.3% (7/49) |  |
| c_prism | dice | 1 | 9.8% | 3.0% | 31% | 1.0% | 33% | 0.0% (0/12) | LOW |
| c_steady_hold | dice | 1 | 10.8% | 3.0% | 28% | 3.0% | 100% | 8.3% (1/12) |  |
| c_kindle | dice | 1 | 11.0% | 5.0% | 45% | 4.8% | 95% | 15.0% (3/20) |  |
| c_sonic_shield | dice | 1 | 11.5% | 3.5% | 30% | 3.2% | 93% | 35.7% (5/14) |  |
| c_fissure | dice | 1 | 6.5% | 1.8% | 27% | 1.8% | 100% | 14.3% (1/7) | LOW |
| c_field_medic | dice | 1 | 10.2% | 3.2% | 32% | 3.2% | 100% | 7.7% (1/13) |  |
| c_plague_spread | dice | 1 | 5.5% | 1.8% | 32% | 1.5% | 86% | 28.6% (2/7) | LOW |
| c_gatekeeper | pos | 1 | 21.0% | 7.5% | 36% | 7.5% | 100% | 13.3% (4/30) |  |
| c_thorn_growth | pos | 1 | 25.8% | 9.2% | 36% | 9.0% | 97% | 18.9% (7/37) |  |
| c_thorn_shield | stat | 1 | 72.8% | 22.2% | 31% | 20.5% | 92% | 19.1% (17/89) |  |
| c_growing_shell | pos | 1 | 20.5% | 5.2% | 26% | 4.8% | 90% | 9.5% (2/21) |  |
| c_backline_glow | pos | 1 | 27.5% | 9.2% | 34% | 8.5% | 92% | 13.5% (5/37) |  |
| c_mana_ward | mana | 1 | 28.5% | 8.0% | 28% | 5.8% | 72% | 12.5% (4/32) |  |
| c_overflow | mana | 1 | 25.0% | 8.8% | 35% | 5.2% | 60% | 14.3% (5/35) |  |
| c_thorn_pact | mana | 1 | 23.2% | 6.8% | 29% | 6.0% | 89% | 14.8% (4/27) |  |
| c_dry_well | quest | 1 | 22.0% | 6.8% | 31% | 6.8% | 100% | 18.5% (5/27) |  |
| c_night_watch | quest | 1 | 24.5% | 8.5% | 35% | 8.5% | 100% | 29.4% (10/34) |  |
| c_key_strike | quest | 1 | 21.2% | 6.2% | 29% | 1.0% | 16% | 4.0% (1/25) |  |
| c_collector | quest | 1 | 18.5% | 6.0% | 32% | 6.0% | 100% | 16.7% (4/24) |  |
| c_chimera_hunt | quest | 1 | 24.2% | 7.5% | 31% | 4.8% | 63% | 10.0% (3/30) |  |
| c_golden_egg | rule | 1 | 8.2% | 2.5% | 30% | 1.5% | 60% | 30.0% (3/10) | LOW |
| c_dim_stone | rule | 1 | 13.8% | 4.5% | 33% | 4.5% | 100% | 5.6% (1/18) |  |
| c_mirror_face | dice | 2 | 11.2% | 4.5% | 40% | 4.8% | 100% | 22.2% (4/18) |  |
| c_sixth_die | dice | 2 | 9.2% | 3.8% | 41% | 3.8% | 100% | 20.0% (3/15) | LOW |
| c_whittle | dice | 2 | 13.0% | 4.2% | 33% | 4.2% | 100% | 23.5% (4/17) |  |
| c_three_dice | dice | 2 | 11.5% | 5.2% | 46% | 5.8% | 100% | 4.8% (1/21) |  |
| c_concord | dice | 2 | 8.0% | 3.0% | 38% | 3.0% | 100% | 0.0% (0/12) | LOW |
| c_toxic_still | dice | 2 | 6.8% | 0.8% | 11% | 0.8% | 100% | 0.0% (0/3) | LOW |
| c_living_wall | pos | 2 | 32.8% | 10.2% | 31% | 10.2% | 100% | 14.6% (6/41) |  |
| c_thorn_rebound | rule | 2 | 14.5% | 5.5% | 38% | 4.8% | 77% | 0.0% (0/22) |  |
| c_open_ranks | pos | 2 | 4.8% | 1.5% | 32% | 1.5% | 100% | 16.7% (1/6) | LOW |
| c_descend | pos | 2 | 15.8% | 4.5% | 29% | 4.5% | 94% | 11.1% (2/18) |  |
| c_hollow_core | mana | 2 | 23.2% | 6.5% | 28% | 5.8% | 85% | 23.1% (6/26) |  |
| c_deep_current | mana | 2 | 31.0% | 10.8% | 35% | 8.0% | 74% | 23.3% (10/43) |  |
| c_blood_sign | rule | 2 | 8.8% | 2.5% | 29% | 3.0% | 100% | 20.0% (2/10) | LOW |
| c_loop | rule | 2 | 13.0% | 4.0% | 31% | 4.8% | 94% | 12.5% (2/16) |  |
| c_cascade | rule | 2 | 15.5% | 6.2% | 40% | 6.8% | 100% | 20.0% (5/25) |  |
| c_sacrifice | rule | 2 | 14.8% | 5.8% | 39% | 6.5% | 100% | 4.3% (1/23) |  |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 59.5% (238/400)

Win-rate khi co Loi (n >= 8). Top 10:
- c_spore_burst: 61.0% (25/41)
- c_sonic_shield: 35.7% (5/14)
- c_golden_egg: 30.0% (3/10)
- c_night_watch: 29.4% (10/34)
- c_early_scales: 27.7% (18/65)
- c_elder_trunk: 24.2% (15/62)
- c_whittle: 23.5% (4/17)
- c_deep_current: 23.3% (10/43)
- c_hollow_core: 22.2% (6/27)
- c_cascade: 22.2% (6/27)

Bottom 10:
- c_thorn_rebound: 0.0% (0/24)
- c_prism: 0.0% (0/12)
- c_concord: 0.0% (0/12)
- c_sacrifice: 3.8% (1/26)
- c_key_strike: 4.0% (1/25)
- c_three_dice: 4.3% (1/23)
- c_dim_stone: 5.6% (1/18)
- c_field_medic: 7.7% (1/13)
- c_steady_hold: 8.3% (1/12)
- c_bastion: 9.1% (8/88)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_elder_trunk + c_spore_burst: 75.0% (6/8)
- c_deep_current + c_spore_burst: 75.0% (6/8)
- c_meme_nametag + c_spore_burst: 66.7% (6/9)
- c_early_scales + c_spore_burst: 63.6% (7/11)
- c_bastion + c_spore_burst: 62.5% (5/8)
- c_overflow + c_tidecaller: 0.0% (0/8)
- c_bastion + c_growing_shell: 0.0% (0/10)
- c_bastion + c_living_wall: 0.0% (0/9)
- c_living_wall + c_tidecaller: 0.0% (0/9)
- c_bastion + c_chimera_hunt: 0.0% (0/9)
