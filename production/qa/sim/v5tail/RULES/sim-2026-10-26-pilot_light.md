# Sim balance pilot_light

Runs: 126, wall 185.2s (1.47s/run).

## Muc tieu (Short A0)

- expert 15-25%: 4.0% -> CHUA DAT



## Phieu chet theo node (song sot tich luy)

- **expert** (n=126): r3 battle -1 (con 99%); r4 battle -13 (con 89%); r5 elite -17 (con 75%); r5 battle -4 (con 72%); r6 boss -11 (con 63%); r7 battle -2 (con 62%); r8 battle -8 (con 56%); r9 elite -11 (con 47%); r9 battle -1 (con 46%); r10 battle -2 (con 44%); r11 battle -2 (con 43%); r12 boss -24 (con 24%); r13 battle -1 (con 23%); r15 elite -10 (con 15%); r15 battle -2 (con 13%); r16 battle -4 (con 10%); r17 battle -1 (con 10%); r18 boss -7 (con 4%)


## Metric nhay (moi run = 1 diem; +- = 95% CI)

| policy | n | dmg/luot | V dau luot | V sau quyet dinh | sd dmg/luot | luot ha boss (run toi boss) | HP con sau boss (run thang boss) | win % | 
|---|---|---|---|---|---|---|---|---|
| expert | 126 | 16.51 +-1.05 | 18.12 +-0.94 | 24.27 +-1.24 | 15.43 +-1.23 | 5.76 +-0.53 | 0.50 +-0.09 | 4.0 +-3.4 | 

### Chenh lech so voi expert (cap seed; chi cac seed ca hai ben deu co so lieu)

| policy | n cap | d dmg/luot | d V dau luot | d V sau quyet dinh | d sd dmg/luot | d luot ha boss (run toi boss) | d HP con sau boss (run thang boss) | d win % | 
|---|---|---|---|---|---|---|---|---|


## Mana (buoc 0): nhan / tieu / thua moi luot

Nhan = mat mana + cantrip + Loi/relic khi dung xuc xac + dau luot/dau tran (start_mana, hook) + khac. 'Loi/khac' khong tach duoc neu khong sua engine. Tieu = An toan + Mat Tam + Overcast + Lieu(0) + khac (hook). Thua = mana con truoc end_turn (chi luot chua ket thuc tran).

| policy | runs | luot/run | nhan/luot | tieu/luot | thua/luot | tieu/nhan % | thua/nhan % | nhan: mat | cantrip | Loi dung | dau luot | khac |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 126 | 30.67 | 1.20 | 1.23 | 4.84 | 102 | 403 | 0.45 | 0.00 | 0.01 | 0.04 | 0.70 |

### Tieu mana vao dau (% tong mana tieu) va so lan mua moi tran

| policy | An toan lan 1 | An toan lan 2+ | Mat Tam | Overcast | Lieu/khac | mua AT1/tran | AT2+/tran | AT mien phi/tran | Mat Tam/tran | Overcast/tran | Lieu/tran |
|---|---|---|---|---|---|---|---|---|---|---|---|
| expert | 16 | 6 | 18 | 24 | 36 | 5.38 | 0.98 | 21.67 | 3.41 | 4.48 | 10.28 |

### Mat Tam theo size nhom luc bam, va co hoi Overcast-ca-BO (neu P1)

| policy | Mat Tam n=2 (->3) | n=3 (->4) | n=4 | luot co BO % | co BO + >=3 mana dau luot % | co BO + >=3 mana sau quyet dinh % |
|---|---|---|---|---|---|---|
| expert | 0% (0) | 100% (430) | 0% (0) | 33.9 | 17.4 | 10.6 |

Mat mana lan ra (san sang dung) moi luot, sau quyet dinh: expert 0.00; 

## Win-rate theo chinh sach x Ascension

| policy | asc | win |
|---|---|---|
| expert | 0 | 4.0% (5/126) |


## Win-rate theo chinh sach x doi

| policy | team | win |
|---|---|---|
| expert | aqua_plant | 5.6% (1/18) |
| expert | beast_bird | 0.0% (0/18) |
| expert | mixed_dmg | 11.1% (2/18) |
| expert | mixed_std | 0.0% (0/18) |
| expert | reptile_bug | 5.6% (1/18) |
| expert | tank_heavy | 5.6% (1/18) |
| expert | thorn_shield | 0.0% (0/18) |


## Win-rate theo chinh sach x cach chon Loi

| policy | core_policy | win |
|---|---|---|
| expert | combo | 11.9% (5/42) |
| expert | greedy_axis | 0.0% (0/42) |
| expert | random | 0.0% (0/42) |


## So luot trung binh moi tran (chinh sach|loai)

- expert|battle: 3.5 luot (n=718)
- expert|boss: 5.6 luot (n=157)
- expert|elite: 4.8 luot (n=97)

## Chet theo node (chinh sach|loai row)

- expert|battle r10: 2
- expert|battle r11: 2
- expert|battle r13: 1
- expert|battle r15: 2
- expert|battle r16: 4
- expert|battle r17: 1
- expert|battle r3: 1
- expert|battle r4: 13
- expert|battle r5: 4
- expert|battle r7: 2
- expert|battle r8: 8
- expert|battle r9: 1
- expert|boss r12: 24
- expert|boss r18: 7
- expert|boss r6: 11
- expert|elite r15: 10
- expert|elite r5: 17
- expert|elite r9: 11

Tran ket > 20 luot hoac khong ket thuc: 0 / 972

## Tan suat Loi / Luat run (% run)

Cot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.

| id | truc | bac | offered | picked | picked/offered | fired | fired/picked | win khi chon | co |
|---|---|---|---|---|---|---|---|---|---|
| c_early_scales | stat | 0 | 40.5% | 13.5% | 33% | 13.5% | 100% | 0.0% (0/17) |  |
| c_dewdrop | stat | 0 | 42.9% | 21.4% | 50% | 21.4% | 100% | 3.7% (1/27) |  |
| c_elder_trunk | stat | 0 | 42.9% | 18.3% | 43% | 18.3% | 100% | 4.3% (1/23) |  |
| c_prime_chain | dice | 0 | 21.4% | 10.3% | 48% | 9.5% | 92% | 7.7% (1/13) |  |
| c_finisher | dice | 0 | 32.5% | 14.3% | 44% | 14.3% | 100% | 5.6% (1/18) |  |
| c_bastion | pos | 0 | 57.9% | 23.0% | 40% | 23.0% | 100% | 3.4% (1/29) |  |
| c_tidecaller | mana | 0 | 37.3% | 4.0% | 11% | 2.4% | 60% | 0.0% (0/5) |  |
| c_mana_pool | mana | 0 | 35.7% | 10.3% | 29% | 8.7% | 85% | 15.4% (2/13) |  |
| c_nest | rule | 0 | 47.6% | 21.4% | 45% | 21.4% | 100% | 14.8% (4/27) |  |
| c_spore_burst | rule | 0 | 50.8% | 18.3% | 36% | 18.3% | 100% | 17.4% (4/23) |  |
| c_fossil | rule | 0 | 23.0% | 6.3% | 28% | 5.6% | 88% | 0.0% (0/8) |  |
| c_meme_copycat | dice | 0 | 16.7% | 4.0% | 24% | 3.2% | 80% | 0.0% (0/5) |  |
| c_meme_nametag | rule | 0 | 57.1% | 13.5% | 24% | 13.5% | 100% | 0.0% (0/17) |  |
| c_meme_jumpy | dice | 0 | 21.4% | 3.2% | 15% | 3.2% | 100% | 0.0% (0/4) |  |
| c_bloodline_ward | pos | 0 | 42.9% | 7.9% | 19% | 1.6% | 20% | 0.0% (0/10) |  |
| c_smoldering | mana | 0 | 43.7% | 11.1% | 25% | 0.0% | 0% | 0.0% (0/14) | DEAD |
| c_hunters_reward | dice | 0 | 25.4% | 8.7% | 34% | 5.6% | 64% | 0.0% (0/11) |  |
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
| c_prism | dice | 1 | 11.9% | 4.8% | 40% | 3.2% | 67% | 0.0% (0/6) |  |
| c_steady_hold | dice | 1 | 8.7% | 0.8% | 9% | 0.8% | 100% | 0.0% (0/1) | LOW |
| c_kindle | dice | 1 | 9.5% | 4.0% | 42% | 3.2% | 80% | 40.0% (2/5) | LOW |
| c_sonic_shield | dice | 1 | 4.0% | 2.4% | 60% | 2.4% | 100% | 0.0% (0/3) | LOW |
| c_fissure | dice | 1 | 7.1% | 3.2% | 44% | 2.4% | 75% | 0.0% (0/4) | LOW |
| c_field_medic | dice | 1 | 6.3% | 3.2% | 50% | 3.2% | 100% | 0.0% (0/4) | LOW |
| c_plague_spread | dice | 1 | 7.1% | 2.4% | 33% | 2.4% | 100% | 0.0% (0/3) | LOW |
| c_gatekeeper | pos | 1 | 21.4% | 11.9% | 56% | 11.9% | 100% | 6.7% (1/15) |  |
| c_thorn_growth | pos | 1 | 22.2% | 6.3% | 29% | 6.3% | 100% | 0.0% (0/8) |  |
| c_thorn_shield | stat | 1 | 57.1% | 15.1% | 26% | 14.3% | 95% | 0.0% (0/19) |  |
| c_growing_shell | pos | 1 | 27.8% | 11.9% | 43% | 11.1% | 93% | 0.0% (0/15) |  |
| c_backline_glow | pos | 1 | 25.4% | 13.5% | 53% | 12.7% | 94% | 0.0% (0/17) |  |
| c_mana_ward | mana | 1 | 19.0% | 4.8% | 25% | 3.2% | 67% | 0.0% (0/6) |  |
| c_overflow | mana | 1 | 14.3% | 4.0% | 28% | 1.6% | 40% | 20.0% (1/5) |  |
| c_thorn_pact | mana | 1 | 18.3% | 11.1% | 61% | 10.3% | 93% | 7.1% (1/14) |  |
| c_dry_well | quest | 1 | 30.2% | 4.8% | 16% | 4.8% | 100% | 16.7% (1/6) |  |
| c_night_watch | quest | 1 | 19.8% | 2.4% | 12% | 2.4% | 100% | 0.0% (0/3) |  |
| c_key_strike | quest | 1 | 22.2% | 3.2% | 14% | 3.2% | 100% | 0.0% (0/4) |  |
| c_collector | quest | 1 | 27.8% | 4.8% | 17% | 4.8% | 100% | 0.0% (0/6) |  |
| c_chimera_hunt | quest | 1 | 32.5% | 6.3% | 20% | 4.0% | 62% | 12.5% (1/8) |  |
| c_golden_egg | rule | 1 | 15.1% | 14.3% | 95% | 14.3% | 100% | 11.1% (2/18) |  |
| c_dim_stone | rule | 1 | 11.9% | 2.4% | 20% | 2.4% | 100% | 0.0% (0/3) |  |
| c_cache_plate | dice | 1 | 7.9% | 2.4% | 30% | 0.0% | 0% | 0.0% (0/3) | LOW DEAD |
| c_golden_thread | mana | 1 | 13.5% | 3.2% | 24% | 0.8% | 25% | 0.0% (0/4) |  |
| c_melting_pot | pos | 1 | 14.3% | 3.2% | 22% | 2.4% | 75% | 0.0% (0/4) |  |
| c_support_hand | dice | 1 | 8.7% | 2.4% | 27% | 0.8% | 33% | 0.0% (0/3) | LOW |
| c_cracked_glass | dice | 1 | 11.1% | 2.4% | 21% | 0.0% | 0% | 0.0% (0/3) | DEAD |
| c_mirror_face | dice | 2 | 7.9% | 3.2% | 40% | 4.8% | 100% | 0.0% (0/4) | LOW |
| c_sixth_die | dice | 2 | 11.9% | 4.0% | 33% | 4.0% | 100% | 0.0% (0/5) |  |
| c_whittle | dice | 2 | 7.1% | 3.2% | 44% | 3.2% | 100% | 0.0% (0/4) | LOW |
| c_three_dice | dice | 2 | 6.3% | 1.6% | 25% | 1.6% | 100% | 0.0% (0/2) | LOW |
| c_concord | dice | 2 | 4.0% | 1.6% | 40% | 1.6% | 100% | 0.0% (0/2) | LOW |
| c_toxic_still | dice | 2 | 4.0% | 1.6% | 40% | 1.6% | 100% | 0.0% (0/2) | LOW |
| c_living_wall | pos | 2 | 19.8% | 7.9% | 40% | 7.9% | 100% | 0.0% (0/10) |  |
| c_thorn_rebound | rule | 2 | 9.5% | 5.6% | 58% | 4.0% | 71% | 0.0% (0/7) | LOW |
| c_open_ranks | pos | 2 | 9.5% | 2.4% | 25% | 2.4% | 100% | 33.3% (1/3) | LOW |
| c_descend | pos | 2 | 11.1% | 5.6% | 50% | 5.6% | 100% | 0.0% (0/7) |  |
| c_hollow_core | mana | 2 | 19.8% | 7.9% | 40% | 4.8% | 60% | 20.0% (2/10) |  |
| c_deep_current | mana | 2 | 22.2% | 4.0% | 18% | 4.0% | 100% | 0.0% (0/5) |  |
| c_blood_sign | rule | 2 | 7.1% | 3.2% | 44% | 4.0% | 100% | 0.0% (0/4) | LOW |
| c_loop | rule | 2 | 10.3% | 7.9% | 77% | 7.1% | 90% | 20.0% (2/10) |  |
| c_cascade | rule | 2 | 8.7% | 4.8% | 55% | 4.8% | 100% | 16.7% (1/6) | LOW |
| c_sacrifice | rule | 2 | 15.9% | 4.8% | 30% | 4.8% | 100% | 0.0% (0/6) |  |
| c_last_testament | rule | 2 | 7.1% | 2.4% | 33% | 2.4% | 100% | 0.0% (0/3) | LOW |
| c_high_roller | rule | 2 | 0.0% | 0.0% | - | 0.0% | - | - | LOW |


## Loi

Run rap duoc cap (2 Loi cung truc dice/mana/pos/rule): 70.6% (89/126)

Win-rate khi co Loi (n >= 8). Top 10:
- c_hollow_core: 20.0% (2/10)
- c_loop: 20.0% (2/10)
- c_spore_burst: 17.4% (4/23)
- c_mana_pool: 15.4% (2/13)
- c_nest: 14.8% (4/27)
- c_chimera_hunt: 12.5% (1/8)
- c_golden_egg: 11.1% (2/18)
- c_prime_chain: 7.7% (1/13)
- c_thorn_pact: 7.1% (1/14)
- c_gatekeeper: 6.7% (1/15)

Bottom 10:
- c_thorn_shield: 0.0% (0/19)
- c_smoldering: 0.0% (0/14)
- c_growing_shell: 0.0% (0/15)
- c_early_scales: 0.0% (0/17)
- c_meme_nametag: 0.0% (0/17)
- c_fossil: 0.0% (0/8)
- c_backline_glow: 0.0% (0/17)
- c_living_wall: 0.0% (0/10)
- c_thorn_growth: 0.0% (0/8)
- c_hunters_reward: 0.0% (0/11)

Cap Loi bat thuong (n >= 8): top 5 / bottom 5
- c_nest + c_spore_burst: 37.5% (3/8)
- c_golden_egg + c_loop: 22.2% (2/9)
- c_golden_egg + c_nest: 14.3% (2/14)
- c_dewdrop + c_elder_trunk: 6.7% (1/15)
- c_dewdrop + c_thorn_shield: 0.0% (0/12)
- c_early_scales + c_elder_trunk: 0.0% (0/9)
- c_dewdrop + c_early_scales: 0.0% (0/9)
- c_early_scales + c_thorn_shield: 0.0% (0/11)
- c_bastion + c_gatekeeper: 0.0% (0/8)
- c_backline_glow + c_bastion: 0.0% (0/11)
