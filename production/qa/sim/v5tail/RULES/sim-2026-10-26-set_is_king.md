# Sim balance set_is_king

Runs: 126, wall 163.8s (1.30s/run).

## Muc tieu (Short A0)

- expert 15-25%: 4.8% -> CHUA DAT



## Phieu chet theo node (song sot tich luy)

- **expert** (n=126): r4 battle -6 (con 95%); r5 elite -17 (con 82%); r5 battle -3 (con 79%); r6 boss -25 (con 60%); r8 battle -6 (con 55%); r9 elite -16 (con 42%); r9 battle -3 (con 40%); r11 battle -1 (con 39%); r12 boss -23 (con 21%); r13 battle -1 (con 20%); r14 battle -1 (con 19%); r15 elite -10 (con 11%); r18 boss -8 (con 5%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 126 | 16.30 +-1.24 | 12.97 +-0.89 | 19.43 +-1.44 | 13.84 +-1.25 | 6.65 +-0.52 | 0.52 +-0.08 | 4.8 +-3.7 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 126 | 29.60 | 0.70 | 0.91 | 2.57 | 130 | 370 | 0.32 | 0.00 | 0.01 | 0.04 | 0.33 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 25 | 5 | 19 | 21 | 30 | 6.27 | 0.60 | 6.54 | 2.65 | 2.79 | 15.25 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (334) | 0% (0) | 29.0 | 13.4 | 5.2 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.01; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 4.8% (6/126) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 5.6% (1/18) |
| expert | beast_bird | 11.1% (2/18) |
| expert | mixed_dmg | 0.0% (0/18) |
| expert | mixed_std | 0.0% (0/18) |
| expert | reptile_bug | 0.0% (0/18) |
| expert | tank_heavy | 0.0% (0/18) |
| expert | thorn_shield | 16.7% (3/18) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 4.8% (2/42) |
| expert | greedy_axis | 4.8% (2/42) |
| expert | random | 4.8% (2/42) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 3.2 luot (n=692)
- expert|boss: 6.5 luot (n=163)
- expert|elite: 4.3 luot (n=110)

## Chet theo node (chinh sach|loai row)

- expert|battle r11: 1
- expert|battle r13: 1
- expert|battle r14: 1
- expert|battle r4: 6
- expert|battle r5: 3
- expert|battle r8: 6
- expert|battle r9: 3
- expert|boss r12: 23
- expert|boss r18: 8
- expert|boss r6: 25
- expert|elite r15: 10
- expert|elite r5: 17
- expert|elite r9: 16

Tran ket > 20 luot hoac khong ket thuc: 0 / 965

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 40.5% | 12.7% | 31% | 12.7% | 100% | 12.5% (2/16) |  |
| c_dewdrop | stat | 0 | 46.0% | 19.8% | 43% | 19.8% | 100% | 4.0% (1/25) |  |
| c_elder_trunk | stat | 0 | 42.9% | 20.6% | 48% | 20.6% | 100% | 7.7% (2/26) |  |
| c_prime_chain | dice | 0 | 21.4% | 7.9% | 37% | 7.1% | 90% | 0.0% (0/10) |  |
| c_finisher | dice | 0 | 28.6% | 13.5% | 47% | 13.5% | 100% | 17.6% (3/17) |  |
| c_bastion | pos | 0 | 59.5% | 23.8% | 40% | 23.8% | 100% | 3.3% (1/30) |  |
| c_tidecaller | mana | 0 | 36.5% | 3.2% | 9% | 1.6% | 50% | 0.0% (0/4) |  |
| c_mana_pool | mana | 0 | 32.5% | 7.9% | 24% | 7.9% | 100% | 0.0% (0/10) |  |
| c_nest | rule | 0 | 43.7% | 19.8% | 45% | 19.8% | 100% | 4.0% (1/25) |  |
| c_spore_burst | rule | 0 | 54.0% | 24.6% | 46% | 24.6% | 100% | 12.9% (4/31) |  |
| c_fossil | rule | 0 | 23.8% | 5.6% | 23% | 4.8% | 86% | 0.0% (0/7) |  |
| c_meme_copycat | dice | 0 | 20.6% | 7.1% | 35% | 6.3% | 89% | 11.1% (1/9) |  |
| c_meme_nametag | rule | 0 | 57.9% | 11.1% | 19% | 10.3% | 93% | 7.1% (1/14) |  |
| c_meme_jumpy | dice | 0 | 23.0% | 5.6% | 24% | 5.6% | 100% | 0.0% (0/7) |  |
| c_bloodline_ward | pos | 0 | 35.7% | 7.1% | 20% | 0.0% | 0% | 11.1% (1/9) | DEAD |
| c_smoldering | mana | 0 | 46.8% | 10.3% | 22% | 0.0% | 0% | 0.0% (0/13) | DEAD |
| c_hunters_reward | dice | 0 | 27.8% | 10.3% | 37% | 4.0% | 38% | 0.0% (0/13) |  |
| rule_none | run_rule | 0 | 12.7% | 0.0% | 0% | 0.0% | - | - |  |
| rule_cheap_mana | run_rule | 0 | 8.7% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_tundra | run_rule | 0 | 7.9% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_quick_beat | run_rule | 0 | 9.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_starfall | run_rule | 0 | 11.1% | 0.0% | 0% | 0.0% | - | - |  |
| rule_heavy_finish | run_rule | 0 | 8.7% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_wasteland | run_rule | 0 | 12.7% | 0.0% | 0% | 0.0% | - | - |  |
| rule_dry_steppe | run_rule | 0 | 4.8% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_rising_tide | run_rule | 0 | 8.7% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_upside_down | run_rule | 0 | 15.1% | 0.0% | 0% | 0.0% | - | - |  |
| rule_old_forest | run_rule | 0 | 19.8% | 0.0% | 0% | 0.0% | - | - |  |
| rule_crow | run_rule | 0 | 8.7% | 0.0% | 0% | 0.0% | - | - | LOW |
| rule_hard_shell | run_rule | 0 | 18.3% | 0.0% | 0% | 0.0% | - | - |  |
| rule_balance | run_rule | 0 | 22.2% | 0.0% | 0% | 0.0% | - | - |  |
| rule_pack_alpha | run_rule | 0 | 21.4% | 0.0% | 0% | 0.0% | - | - |  |
| rule_high_stakes | run_rule | 0 | 9.5% | 0.0% | 0% | 0.0% | - | - | LOW |
| c_prism | dice | 1 | 7.1% | 3.2% | 44% | 1.6% | 50% | 0.0% (0/4) | LOW |
| c_steady_hold | dice | 1 | 7.1% | 3.2% | 44% | 3.2% | 100% | 0.0% (0/4) | LOW |
| c_kindle | dice | 1 | 4.8% | 0.8% | 17% | 0.8% | 100% | 0.0% (0/1) | LOW |
| c_sonic_shield | dice | 1 | 9.5% | 2.4% | 25% | 2.4% | 100% | 0.0% (0/3) | LOW |
| c_fissure | dice | 1 | 3.2% | 1.6% | 50% | 1.6% | 100% | 0.0% (0/2) | LOW |
| c_field_medic | dice | 1 | 9.5% | 0.8% | 8% | 0.8% | 100% | 100.0% (1/1) | LOW |
| c_plague_spread | dice | 1 | 4.0% | 3.2% | 80% | 3.2% | 100% | 0.0% (0/4) | LOW |
| c_gatekeeper | pos | 1 | 22.2% | 10.3% | 46% | 10.3% | 100% | 7.7% (1/13) |  |
| c_thorn_growth | pos | 1 | 19.0% | 7.9% | 42% | 7.9% | 100% | 10.0% (1/10) |  |
| c_thorn_shield | stat | 1 | 59.5% | 15.1% | 25% | 12.7% | 84% | 5.3% (1/19) |  |
| c_growing_shell | pos | 1 | 17.5% | 8.7% | 50% | 7.9% | 91% | 9.1% (1/11) |  |
| c_backline_glow | pos | 1 | 21.4% | 11.1% | 52% | 11.1% | 100% | 7.1% (1/14) |  |
| c_mana_ward | mana | 1 | 21.4% | 6.3% | 30% | 5.6% | 88% | 0.0% (0/8) |  |
| c_overflow | mana | 1 | 19.8% | 7.1% | 36% | 4.0% | 56% | 22.2% (2/9) |  |
| c_thorn_pact | mana | 1 | 14.3% | 4.8% | 33% | 4.8% | 100% | 0.0% (0/6) |  |
| c_dry_well | quest | 1 | 27.0% | 3.2% | 12% | 3.2% | 100% | 0.0% (0/4) |  |
| c_night_watch | quest | 1 | 19.8% | 1.6% | 8% | 1.6% | 100% | 0.0% (0/2) |  |
| c_key_strike | quest | 1 | 20.6% | 2.4% | 12% | 0.8% | 33% | 0.0% (0/3) |  |
| c_collector | quest | 1 | 28.6% | 7.9% | 28% | 7.9% | 100% | 0.0% (0/10) |  |
| c_chimera_hunt | quest | 1 | 23.8% | 10.3% | 43% | 4.8% | 46% | 0.0% (0/13) |  |
| c_golden_egg | rule | 1 | 10.3% | 9.5% | 92% | 9.5% | 100% | 8.3% (1/12) |  |
| c_dim_stone | rule | 1 | 10.3% | 2.4% | 23% | 2.4% | 100% | 0.0% (0/3) |  |
| c_cache_plate | dice | 1 | 7.9% | 1.6% | 20% | 0.0% | 0% | 50.0% (1/2) | LOW DEAD |
| c_golden_thread | mana | 1 | 17.5% | 7.1% | 41% | 5.6% | 78% | 11.1% (1/9) |  |
| c_melting_pot | pos | 1 | 14.3% | 4.8% | 33% | 2.4% | 50% | 0.0% (0/6) |  |
| c_support_hand | dice | 1 | 10.3% | 4.0% | 38% | 2.4% | 60% | 20.0% (1/5) |  |
| c_cracked_glass | dice | 1 | 11.1% | 4.0% | 36% | 1.6% | 40% | 20.0% (1/5) |  |
| c_mirror_face | dice | 2 | 7.9% | 1.6% | 20% | 2.4% | 100% | 0.0% (0/2) | LOW |
| c_sixth_die | dice | 2 | 8.7% | 2.4% | 27% | 2.4% | 100% | 0.0% (0/3) | LOW |
| c_whittle | dice | 2 | 7.1% | 1.6% | 22% | 1.6% | 100% | 50.0% (1/2) | LOW |
| c_three_dice | dice | 2 | 9.5% | 7.1% | 75% | 7.1% | 100% | 0.0% (0/9) | LOW |
| c_concord | dice | 2 | 4.0% | 2.4% | 60% | 2.4% | 100% | 0.0% (0/3) | LOW |
| c_toxic_still | dice | 2 | 4.0% | 0.8% | 20% | 0.8% | 100% | 0.0% (0/1) | LOW |
| c_living_wall | pos | 2 | 15.9% | 8.7% | 55% | 8.7% | 100% | 9.1% (1/11) |  |
| c_thorn_rebound | rule | 2 | 9.5% | 2.4% | 25% | 1.6% | 67% | 0.0% (0/3) | LOW |
| c_open_ranks | pos | 2 | 13.5% | 2.4% | 18% | 3.2% | 100% | 33.3% (1/3) |  |
| c_descend | pos | 2 | 11.1% | 2.4% | 21% | 2.4% | 100% | 0.0% (0/3) |  |
| c_hollow_core | mana | 2 | 21.4% | 5.6% | 26% | 4.0% | 71% | 0.0% (0/7) |  |
| c_deep_current | mana | 2 | 18.3% | 5.6% | 30% | 4.0% | 71% | 0.0% (0/7) |  |
| c_blood_sign | rule | 2 | 7.9% | 3.2% | 40% | 3.2% | 100% | 0.0% (0/4) | LOW |
| c_loop | rule | 2 | 8.7% | 3.2% | 36% | 3.2% | 100% | 25.0% (1/4) | LOW |
| c_cascade | rule | 2 | 11.1% | 6.3% | 57% | 6.3% | 100% | 0.0% (0/8) |  |
| c_sacrifice | rule | 2 | 11.1% | 5.6% | 50% | 6.3% | 100% | 28.6% (2/7) |  |
| c_last_testament | rule | 2 | 5.6% | 1.6% | 29% | 1.6% | 100% | 50.0% (1/2) | LOW |
| c_high_roller | rule | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 70.6% (89/126)

Win-rate khi co Loi (n >= 8). Top 10:
- c_sacrifice: 25.0% (2/8)
- c_overflow: 22.2% (2/9)
- c_finisher: 17.6% (3/17)
- c_spore_burst: 12.9% (4/31)
- c_early_scales: 12.5% (2/16)
- c_meme_copycat: 11.1% (1/9)
- c_golden_thread: 11.1% (1/9)
- c_bloodline_ward: 11.1% (1/9)
- c_thorn_growth: 10.0% (1/10)
- c_growing_shell: 9.1% (1/11)

Bottom 10:
- c_collector: 0.0% (0/10)
- c_chimera_hunt: 0.0% (0/13)
- c_smoldering: 0.0% (0/13)
- c_cascade: 0.0% (0/8)
- c_mana_ward: 0.0% (0/8)
- c_hunters_reward: 0.0% (0/13)
- c_three_dice: 0.0% (0/9)
- c_prime_chain: 0.0% (0/10)
- c_mana_pool: 0.0% (0/10)
- c_bastion: 3.3% (1/30)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_early_scales + c_elder_trunk: 22.2% (2/9)
- c_early_scales + c_thorn_shield: 12.5% (1/8)
- c_dewdrop + c_thorn_shield: 10.0% (1/10)
- c_elder_trunk + c_thorn_shield: 9.1% (1/11)
- c_dewdrop + c_elder_trunk: 7.7% (1/13)
- c_golden_egg + c_nest: 0.0% (0/10)
- c_bastion + c_thorn_growth: 0.0% (0/8)
- c_backline_glow + c_bastion: 0.0% (0/8)
- c_nest + c_spore_burst: 0.0% (0/12)
- c_dewdrop + c_elder_trunk: 7.7% (1/13)
