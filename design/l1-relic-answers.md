# L1: trả lời câu hỏi spec của lane B (relic)

> **QUYẾT ĐỊNH LIAM (12/10):** `relaybaton` **truyền bonus dọc chuỗi** đúng chữ spec (sim sau xem có quá mạnh) · boss **miễn nhiễm chết ngay**, áp cả `apexferal` (vẫn mạnh với quái thường/elite).

Người viết: game-designer (lane D) · 12/10/2026. Trả lời 8 câu của lane B. Nguồn luật gốc là `design/proposals/relic-set-v2.md`
(bộ relic đã khoá, Liam 11/10). File này chỉ lấp chỗ spec còn hở và sửa vài chỗ spec tự mâu thuẫn. Chỗ nào lệch spec có
nhãn **[LỆCH SPEC]**. Con số vẫn là số đoán đầu, chốt sau sim (relic-set §6).

Chưa sửa code, chưa sửa `relic-set-v2.md`. Nếu file này và relic-set-v2 khác nhau ở chỗ có nhãn [LỆCH SPEC] thì lấy file này.

---

## 1. Tiền tố id

**Xác nhận: giữ `r_`.** Passive và pact đều là `r_<id>` (ví dụ `r_claw`, `r_bloodpact`, `r_twinfates`); active giữ `a_<id>`.
Cột id trong relic-set-v2 là id logic không có tiền tố, chỉ cần thêm `r_` khi tạo file `.tres`, field `id` và `hook_key`.

- Tên file: `godot/resources/relics/r_<id>.tres`.
- Xoá 6 file: `r_rotbite`, `r_tinderbox`, `r_openwound`, `r_voidgene`, `r_spines`, `r_swarmnest`.
- Số relic **mới theo spec** là **44** (không phải 45 của bản cũ): `tithepurse` đã bị Liam bỏ, không tạo file `r_tithepurse.tres`.
  Nhưng số **file `.tres` mới** là **45** = 44 relic mới + `r_festermark` (id mới do merge `rotbite`+`tinderbox`+`openwound`, spec để nó ở bảng 1.4).
  Nên lane B có 45 file mới là đúng, không xoá file nào. Cách kiểm: pool cuối = 94 cũ − 6 xoá + 45 mới = 133 relic. Chỉ xoá 6 file ở trên.
- Run save cũ có id đã xoá thì bị bỏ khi nâng `SAVE_VERSION` (interfaces §1.5), lane B không cần migrate.

---

## 2. Tên và mô tả cuối (tiếng Anh, player-facing)

### 2.0 Từ khoá dùng trong mô tả (UI phải giải thích được khi rê chuột)

| Từ | Nghĩa (hiện trong tooltip) |
|---|---|
| **Wounded** | Địch dưới 50% HP (hoặc có ≥5 Poison khi đang giữ Carrion Call). Một hàm duy nhất cho mọi relic |
| **Tweak** | Thao tác sửa mặt đã roll của relic Dice. Cả đội relic dùng chung **2 Tweak mỗi lượt**, Undo không hoàn lại |
| **[Global]** | Relic chiếm ô Global (tối đa 1). Nhân mọi mặt sát thương của Axie |
| **[Axis: X]** | Relic chiếm 1 trong 2 ô Axis, nhân riêng trục X. Các nguồn cùng trục thì cộng với nhau |
| **PACT** | Relic chỉ ra ở boss, có Drawback chạy suốt run, chiếm 1 ô passive |
| Thời hạn "through the enemy phase" | Bonus tạm của lượt kéo dài qua pha địch và hết ở đầu lượt kế của người chơi (xem câu 7) |

Quy ước viết: số rõ ràng, "damage face" = mặt sát thương, bonus "+N" là cộng thẳng sau khi tính hết nhân trừ khi ghi khác.
Rarity: C / R / E / L (0..3 trong `.tres`). Chi phí Mana của active là field riêng, không ghi trong mô tả.

### 2.1 Relic mới (44)

**Duo (12)**

| id | Name | R | Description |
|---|---|---|---|
| `r_fumeblossom` | Fumeblossom | L | Each Burn tick on an enemy adds 1 Poison. Each Poison tick on a burning enemy adds 1 Burn. Each direction triggers once per enemy per turn. |
| `r_sporegale` | Spore Gale | R | Cleave and AoE faces apply 1 Poison to every secondary target. At each Poison tick, every poisoned enemy spreads 1 Poison to the enemies next to it. |
| `r_firestormveil` | Firestorm Veil | E | AoE faces apply 2 Burn to every enemy they hit. Burning enemies take +1 damage from AoE faces. |
| `r_spikedbulwark` | Spiked Bulwark | R | When an Axie gains Shield, its Thorns get +1 for every 5 Shield it has (max +4), through the enemy phase. |
| `r_aegiscapacitor` | Aegis Capacitor | E | Every 2 Mana you spend in a combat, the Axie with the least Shield gains 4 Shield. |
| `r_breakersward` | Breaker's Ward | R | When your attack removes enemy Shield, the Axie with the least Shield gains that much Shield (max 8 per hit). |
| `r_assassinsneedle` | Assassin's Needle | L | Pierce faces get +25% Crit chance. A Pierce crit applies Weaken 2 and refunds 1 Mana. |
| `r_coupmark` | Coup Mark | E | A crit on a Wounded enemy that leaves it at 25% Max HP or less kills it instantly. Bosses are immune. |
| `r_broodbloom` | Brood Bloom | E | At end of turn, each Egg gains +1 Growth. A newly hatched Egg starts with the Growth of your highest-Growth Egg. |
| `r_wellspringroots` | Wellspring Roots | R | Every 2 Mana you spend: all your faces gain +1 Growth for this combat (max +4). |
| `r_thornling` | Thornling | E | Eggs have Thorns 3 from the moment they appear. Each time an Egg reflects Thorns, the Axies next to it gain 2 Shield. |
| `r_carrioncall` | Carrion Call | E | Enemies with 5 or more Poison count as Wounded for every effect that checks "below 50% HP". They no longer count as healthy for Dawn Lance. |

**Class upgrader (6)**

| id | Name | R | Description |
|---|---|---|---|
| `r_heartrootgrove` | Heartroot Grove | E | Plant's Bulwark gives Thorns 3 (was 2) from 6 Shield (was 10). At end of turn, each Plant Axie with 10+ Shield gives 3 Shield to each Axie next to it. |
| `r_alphafang` | Alpha's Fang | E | Beast's Feral triggers below 65% HP (was 50%); the ×1.6 stays. When a Beast Axie's face kills an enemy, refund 1 Reroll (once per turn). |
| `r_tidecaller` | Tidecaller's Conch | E | Aqua's Conduit gives 1 Reroll per 3 Mana spent (was 4), and these Rerolls may go up to 2 above your max. Aqua Mana faces give +1 Mana. |
| `r_shedskin` | Shed Skin | E | Reptile's Scales give Thorns 4 (was 2) and reflected Thorns apply Poison 2 (was 1). A Reptile Axie hit while it has no Shield gains 4 Shield (once per turn per Axie). |
| `r_venomlineage` | Venom Lineage | E | Bug's Virulent adds 3 Poison (was 2) to an already-poisoned target. The first Poison a Bug Axie applies each turn also spreads 1 Poison to the enemies next to the target. |
| `r_falconhood` | Falconer's Hood | E | Bird's Talon gives Pierce +5 (was +3). Pierce faces of Bird Axies ignore Thorns. |

**Pact (8, cộng `r_bloodpact` ở bảng rework)**

| id | Name | R | Description |
|---|---|---|---|
| `r_brittledice` | Brittle Dice | E | PACT. All damage faces +4. Drawback: all Shield and Heal faces are halved (rounded down). |
| `r_devilsreroll` | Devil's Reroll | E | PACT. +3 max Rerolls. Drawback: every Reroll costs 1 Mana. With no Mana you cannot Reroll. |
| `r_hollowchalice` | Hollow Chalice | E | PACT. +1 active slot (4 total) and every active costs 2 less Mana (min 1). Drawback: Mana faces give 0 Mana. |
| `r_twinfates` | Twin Fates | L | PACT. Each Axie rolls 2 faces and keeps the one with the higher main value (tie keeps the first). Drawback: max Rerolls become 0 and no Reroll source works. |
| `r_lonewolf` | Lone Wolf Contract | E | PACT. The Axie in slot 1 deals +100% damage on all its damage faces [Global]. Drawback: the other 4 Axies cannot Reroll. |
| `r_patientfang` | Patient Fang | L | PACT. Each turn after the first, all damage faces get +2 more (turn 2 = +2, turn 3 = +4, max +14). Drawback: on turn 1 all damage faces deal 0. |
| `r_tithepips` | Tithe of Pips | E | PACT. +3 Mana each turn. Drawback: after every roll, your lowest-value face is blanked and cannot be used. Reroll it to escape. |
| `r_ironvow` | Iron Vow | E | PACT. All Shield you create +50% [Axis: Shield], and your whole team gains +2 Thorns. Drawback: all damage faces −2 (min 1). |

**Dice (6)**

| id | Name | R | Description |
|---|---|---|---|
| `r_amberdie` | Amber Die | R | At end of turn, pick 1 unused die. Next turn that Axie keeps this exact face (no new roll; you can still Reroll it). Free, once per turn. |
| `r_mirrorpip` | Mirror Pip | E | Tweak: copy the rolled face of one Axie onto another. The target's old face is lost. |
| `r_pipfile` | Pip File | C | Tweak: change the main value of one rolled face by +1 or −1 (min 1). |
| `r_twinswap` | Twin Swap | R | Tweak: swap the rolled faces of two Axies that have not used their face yet. |
| `r_loadeddie` | Loaded Die | R | When you get this, choose 1 face of 1 Axie. That face is 3× as likely to roll (37.5% instead of 16.7%) for the rest of the run. |
| `r_flipside` | Flipside Die | E | Tweak: flip one rolled face to the opposite side of its die. |

**Positional (5). Slot 1 là Axie ngoài cùng bên trái**

| id | Name | R | Description |
|---|---|---|---|
| `r_linkstone` | Linkstone | C | Each Axie standing next to a living Axie that shows the same face type (damage, shield, heal, poison, mana) gets +2 on that face. Rechecked after every Reroll. |
| `r_bookend` | Bookend Pennants | C | The Axies in slot 1 and slot 5 get +3 on all damage faces. |
| `r_keystone` | Keystone | E | The Shield, Heal and Mana faces of the Axie in slot 3 also give 50% (rounded down) to each Axie next to it. For Mana: +50% extra Mana per living neighbour. |
| `r_relaybaton` | Relay Baton | E | After an Axie uses a face, the Axie in the next slot to its right gets +2 on its next damage face this turn. |
| `r_symmetrycharm` | Symmetry Charm | E | If the Axies in slots 1 and 5 show the same face type, both get +3 on that face. Same for slots 2 and 4. If both pairs match, slot 3 gets +1. Rechecked after every Reroll. |

**Scaling / Economy / Payoff (7)**

| id | Name | R | Description |
|---|---|---|---|
| `r_crescendofang` | Crescendo Fang | C | Each damage face you use this turn gives your next damage face +1 (stacks). Resets at end of turn. |
| `r_tideglass` | Tideglass | E | Every 3 Mana you spend: all damage faces get +1 for this combat (max +6). |
| `r_heirloom` | Heirloom Seed | R | Each Elite or Boss you defeat: all damage faces get +1 for the rest of the run (max +5). |
| `r_merchantscale` | Merchant's Scale | C | Shops offer 3 relics instead of 2. Prices and sell values do not change. |
| `r_fortuneledger` | Fortune's Ledger | R | +1 reward reroll on every reward screen. This extra reroll costs 25 Gene Shards. |
| `r_scavengereye` | Scavenger's Eye | R | Battle and Elite rewards show 4 cards instead of 3. Treasure gives 1 extra relic card. |
| `r_towershield` | Tower Shield | C | An Axie with Shield gets +1 damage on its damage faces for every 4 Shield (max +6). |

### 2.2 Relic rework (19)

| id | Name | R | Description |
|---|---|---|---|
| `r_claw` | Razor Claw | C | Each turn, the lowest-value damage face on your team gets +4 (rechecked after every Reroll). Ties go to the Axie further left. |
| `r_carapace` | Stone Carapace | C | The first Shield face you use each turn gives +5 Shield. |
| `r_cleaveall` | Sweeping Tail | C | Cleave and AoE faces deal +1 damage for each living enemy (3 enemies = +3). |
| `r_barbedhide` | Barbed Hide | C | Each time you use a Shield face, that Axie gains +1 Thorns through the enemy phase (stacks up to +3). |
| `r_ear` | Keen Ears | C | Mana faces give +1 Mana. The first time each turn you use an active, refund 1 Mana. |
| `r_gustwing` | Gustwing | C | Cleave hits secondary targets for 75% damage. Secondary targets also get the Poison, Burn or Weaken from the main hit. |
| `r_heart` | Lunacia Heart | C | +8 Max HP for the whole team. At turn start, each Axie below 30% HP gains 6 Shield. |
| `r_talonedge` | Talon Edge | C | Pierce +2. A Pierce hit on a shielded enemy removes all of that enemy's remaining Shield. |
| `r_eggshell` | Eggshell Ward | C | At end of turn, each living Egg gives 3 Shield to each Axie next to it. |
| `r_luckycharm` | Lucky Scale | C | +20% Crit chance. Each non-crit damage hit adds +10% Crit chance to that Axie until it crits (resets on crit and at combat end). |
| `r_apexbrood` | Apex Brood | E | A newly hatched Egg copies the highest-value damage face currently showing on your team into one of its slots. Eggs deal +2 damage. |
| `r_regrow` | Regrowth Bud | E | Each time you use a Shield or Heal face, that Axie gains +1 Growth for this combat (max +4). |
| `r_fang` | Venom Fang | E | Poison faces apply +1 Poison. If the target already has 5 or more Poison, apply +2 more. |
| `r_cullingorder` | Culling Order | E | Each kill refunds 1 Reroll (max 2 per turn) and gives your next damage face +3. |
| `r_hollowbone` | Hollow Bone | E | Pierce ignores Thorns. The first Pierce face each turn also hits the lowest-HP enemy for 50% damage (this extra hit triggers no relics). |
| `r_soulforge` | Soul Forge | L | Shield has no cap. For every 10 Shield on an Axie, its damage faces get +1 (max +6). |
| `r_apexpredator` | Apex Predator | L | Crits deal ×3 instead of ×2 [Axis: Crit]. Each crit refunds 1 Reroll (max 2 per turn). |
| `r_ancientgene` | Ancient Gene | L | All damage faces +30% [Global]. Every face that already has Growth gains +1 Growth. |
| `r_bloodpact` | Blood Pact | L | PACT. All damage faces +60% [Global]. Drawback: max Rerolls −2 (min 0). |

### 2.3 Merge và relic có đổi luật nhân (9)

| id | Name | R | Description |
|---|---|---|---|
| `r_festermark` | Festering Mark | R | Enemies with Poison or Burn take +2 damage from each hit. Enemies with both take +4. |
| `r_infinitedie` | Infinite Die | E | +2 max Rerolls and +1 Mana on turn 1. You can Undo past a Reroll. |
| `r_broodpouch` | Brood Pouch | C | Start each combat with 1 Egg. On turn 3, if you have fewer than 3 Eggs, gain 1 Egg. |
| `r_scalecrown` | Scale Crown | L | Your whole team gains Scales (Thorns 2, reflected Thorns apply 1 Poison) and every Axie has at least 2 Thorns. |
| `r_hearthcore` | Hearthcore | E | Burn deals +70% damage [Axis: Burn]. |
| `r_solarcore` | Solar Core | L | Burn deals +100% damage [Axis: Burn]. |
| `r_venomengine` | Venom Engine | L | Poison deals +100% damage per tick [Axis: Poison]. |
| `r_mirrorshell` | Mirror Shell | L | Thorns deal +100% damage [Axis: Thorns]. |
| `r_dawnlance` | Dawn Lance | L | Hits on an enemy that is not Wounded deal +90% damage [Axis: Opener]. |

Hai dòng `r_hearthcore`/`r_solarcore` trong `.tres` vẫn có thể cài là "tick lần 2" như spec; số cuối giống hệt khi gộp theo trục
(1 + 0,70 + 1,00 = ×2,7), chỉ khác chữ trên thẻ. Dùng chữ "+70%" cho khớp với cách UI hiện tổng trục.

### 2.4 Active thay đổi (4)

| id | Name | R | Description (cost là field riêng) |
|---|---|---|---|
| `a_chaos` | Chaos Gene | R | +4 Rerolls this turn. Actives give at most 6 Rerolls per turn in total. (1 Mana) |
| `a_perfectstrike` | Perfect Strike | R | Deal 8 damage. Always crits. (4 Mana, was 5) |
| `a_coupdegrace` | Coup de Grâce | E | Deal 15 Execute damage. (4 Mana, was 5) |
| `a_nova` | Gene Nova | L | Deal 12 damage to all enemies. (7 Mana, was 8) |

Các relic giữ nguyên (45 passive + 12 active còn lại; 7 trong 52 passive "giữ nguyên" của spec §1.1 đã nằm ở 2.3 vì đổi luật nhân/merge) giữ mô tả hiện có trong `.tres`. Hai nhóm chỉ đổi dữ liệu, không đổi chữ trên thẻ:
`bloodmouth`, `echostone` chỉ đổi tag; `keeneye`, `quickenroot` chỉ đổi thời điểm chạy (relic-set §5 H1).

### 2.5 Chỗ spec còn hở mà mô tả ở trên đã chốt

Lane B copy mô tả như trên, và cài đặt theo các luật dưới đây. Đây là luật, không phải chữ trên thẻ.

1. **Hòa (tie) luôn ưu tiên Axie ở slot nhỏ hơn** (bên trái hơn). Áp cho `claw`, `aegiscapacitor`, `breakersward`, `tithepips`,
   `twinfates`. Không bao giờ rút ngẫu nhiên để phá hòa (tránh thêm RNG vào luật).
2. **`twinfates`**: so sánh **giá trị chính dạng số**, không phân biệt loại mặt (3 Shield thua 5 Damage). Hòa giữ mặt roll trước.
   UI nên hiện mặt bị bỏ mờ ở góc die để không giấu thông tin (đề xuất cho U/lane B, không chặn).
3. **`lonewolf`** **[LỆCH SPEC]**: chỉ nhân mặt **sát thương** của Axie slot 1 (spec ghi "mọi mặt"). Lý do: trục G là chỉ mặt
   sát thương (Liam, Q2), nếu `lonewolf` nhân cả Shield thì mô tả G trên thẻ không đúng. Slot 1 là slot trong đội lúc dựng, nếu
   Axie đó chết thì bonus mất cùng nó.
4. **`keystone`**: "kề" của slot 3 là slot 2 và slot 4. Shield/Heal: mỗi Axie kề nhận `floor(50% × giá trị mặt)`. Mana là kho
   chung nên thành "+`floor(50% × Mana của mặt)` cho mỗi Axie kề còn sống" (tối đa +100%). Làm tròn xuống ở cả ba.
5. **`relaybaton`**: +2 phẳng cho Axie ngay bên phải mỗi lần dùng mặt (bất kể loại mặt). Chỉ cộng dồn khi một Axie nhận nhiều lần
   (ví dụ dùng hai lần nhờ `echostone`). Không chuyển tiếp bonus dọc chuỗi. Hết lượt thì mất, slot 5 không trao cho ai.
   **[LỆCH SPEC, mình thêm nhãn khi review]** spec §1.5 viết "cộng dồn đi trái sang phải" và §6.5 mục 6 nói "chuỗi cộng dồn trái sang phải
   có thể ra số lớn"; cách đọc ở đây (không truyền) làm chuỗi không cộng dồn xuyên slot. Nếu Liam muốn đúng ý spec (bonus của Axie
   được truyền tiếp sang Axie kế), phải đổi luật này và test lại số trần. Chờ Liam quyết (xem mục 9).
6. **`apexbrood`**: lúc Egg nở, chép mặt sát thương có giá trị cao nhất **đang hiện** trên đội. Nếu chưa có mặt nào đang roll
   (nở lúc `on_combat_start`) thì lấy mặt sát thương cao nhất trong template die của đội.
7. **`thornling`** **[LỆCH SPEC so với bản lane B đã làm]**: xem câu 7.
8. **Duo gating**: chỉ cần tập relic đang giữ **có đủ cả hai tag**; một relic mang cả hai tag (ví dụ `glassspine` thorns + shield)
   tự đủ cho `spikedbulwark`. Không cần hai relic khác nhau. Class đội vẫn không tính (đã chốt).
9. **`patientfang`**: đếm theo lượt **trong trận hiện tại** (reset mỗi trận). Bonus = `min(14, 2 × (turn − 1))`. Xem câu 6.
10. **Làm tròn**: `floor` cho "bằng một nửa/chia" (keystone, brittledice); `round_half_up` cho phần trăm của
    Shield/Heal/status (ironvow ×1,5, Venom/Burn tick); `ceil` cho nhân mặt sát thương (câu 3).
11. **`r_tidecaller` ra khỏi danh sách trần Reroll relic** **[LỆCH SPEC]**: relic-set §3.6 vừa liệt kê `tidecaller` vào trần 4/lượt, vừa
    nói chuyển Mana→Reroll của CONDUIT không tính. Hai câu mâu thuẫn vì `tidecaller` chỉ làm cho chuyển đổi đó rẻ hơn.
    Chốt: chuyển Mana→Reroll (cả bản gốc lẫn bản `tidecaller`) **không** tính vào trần; Mana đã là trần tự nhiên.
12. **`tithepips` blank**: chỉ xét die của Axie đang sống (Egg không tính), bỏ qua die đã dùng. Luôn đúng **1** mặt bị blank
    sau mỗi lần roll/reroll (tính lại ở `on_roll_settled`), kể cả khi mặt mới reroll lại là mặt thấp nhất.
13. **`r_devilsreroll`**: Reroll mua bằng Aid (R2) cũng tốn 1 Mana (luật không phân biệt nguồn, đúng interfaces §3.3).

---

## 3. Trục G ×2,5 và "cộng trong trục" (lane A cài, lane B cấp dữ liệu)

**Ai làm:** lane A viết hàm tính `G_axie` và chặn ×2,5 (nằm trong `RunState`/build die + `damage_pipeline`, vì `ascend`/`forge`
là mutation do `RunState` giữ). Lane B chỉ cấp dữ liệu relic: `mult_axis = "G"` và hệ số `mult_bonus` (0,30 / 0,60 / 1,00).
Lane B không tự nhân G ở handler relic.

### 3.1 Công thức G (mỗi Axie, chỉ mặt sát thương)

```
relic_g(axie)  = mult_bonus của relic chiếm ô G (0 nếu không có),
                 riêng lonewolf: chỉ tính khi axie đứng ở slot 1, các Axie khác = 0
G_axie         = min( 2.5 , 1 + relic_g(axie) + 0.25 × ascend_n(axie) + 0.30 × forge_n(axie) )
```

- `ascend_n`, `forge_n` là số lần **chính Axie đó** nhận `ascend` (reward, người chơi chọn Axie) / `forge` (event, Axie ngẫu nhiên).
- Hệ số relic: `ancientgene` 0,30 · `bloodpact` 0,60 · `lonewolf` 1,00 (chỉ slot 1).
- Tối đa 1 relic trong ô G (luật cũ, không đổi). Egg dùng `relic_g` như Axie (trừ `lonewolf`) và `ascend_n = forge_n = 0`.
- **Mặt sát thương** = mặt có hiệu ứng chính là sát thương trực tiếp (dmg, Cleave, AoE, Pierce, Execute). Mặt Poison/Shield/
  Heal/Mana **không** phải mặt sát thương.

### 3.2 Chỗ áp dụng

1. Lúc dựng die: mutation `oc` của `ascend`/`forge` **không còn nhân** mặt sát thương. Mặt sát thương không có `oc`.
   +6 Max HP của `ascend` giữ nguyên.
2. Trong `damage_pipeline` thứ tự giữ như relic-set §3.4: Execute ×1,6 → Pierce → **×G_axie** → `mod_dmg` (cộng phẳng + Opener) → Crit.
   G thêm đúng **một** bước nhân. Làm tròn bước đó bằng **`ceil`** (giống `ceil(v*1.6)` của Execute ở `damage_pipeline.gd:48` và `ceil(v*mult)`
   của `oc` hiện tại; chỗ này thay chỗ cũ chứ không phải chỗ mới nên không dùng `round_half_up`). Mỗi bước nhân sau đó làm tròn riêng
   như pipeline đang làm. **Làm bằng số nguyên, không float:** `G100 = min(250, 100 + relic_g100 + 25×ascend_n + 30×forge_n)`,
   rồi `ceil(v × G100 / 100) = (v × G100 + 99) / 100` (chia nguyên). Float kiểu `ceil(5 × 1.6)` dễ ra 8.000000001 → 9.
3. Mặt Shield/Heal/Mana/Poison: vẫn nhân `oc` dồn `ceil(v × Π mult)` lúc dựng die như hôm nay, nhưng tích `Π mult` chặn **×2,0**
   (Liam câu 16). `G_axie` không áp lên các mặt này.

### 3.3 Ví dụ

Axie X đã `ascend` 2 lần, đang giữ `bloodpact` (+0,60), có mặt Horn giá trị 5. Axie Y chưa ascend.

- `G_X = min(2,5 ; 1 + 0,60 + 0,25×2) = 2,10`. `G_Y = 1 + 0,60 = 1,60`.
- Mặt Horn 5 của X: `ceil(5 × 2,10) = 11`. Cùng mặt của Y: `ceil(5 × 1,60) = 8`.
- Đánh vào địch không Wounded với `dawnlance` (+90% = ×1,9): X `ceil(11 × 1,9) = 21`. Y `ceil(8 × 1,9) = 16`.
- Chạm trần: X nhận thêm 2 `ascend` nữa (4 lần) và 1 `forge`: tổng `1 + 0,60 + 1,00 + 0,30 = 2,90` → chặn **2,5**. Ascend trên Axie
  khác không làm X chạm trần nhanh hơn.
- Mặt Shield 4 của X: nhân `oc` = 1,25² = 1,5625 → `ceil(4 × 1,5625) = 7`, không qua G. Nếu X đã ascend 4 lần: 1,25⁴ = 2,44 → chặn 2,0 → `ceil(4×2) = 8`.

### 3.4 "Cộng trong trục" cho trục A

```
axis_total(trục) = 1 + Σ mult_bonus của mọi relic đang giữ thuộc trục đó
```

Trục khác nhau thì nhân với nhau (chỉ có ý nghĩa khi hai trục cùng áp lên một nguồn, ví dụ Opener × Crit trên cùng một mặt).

Ví dụ: `hearthcore` (+0,70) + `solarcore` (+1,00) cùng trục Burn → `axis_burn = 1 + 0,70 + 1,00 = 2,7`. Burn tick gốc 6:
`6 × 2,7 = 16,2` → `round_half_up` → **16**. Đây là tick, không qua G. Hai relic cùng trục chiếm cả 2 ô A. Hai relic khác trục
thì mỗi cái một ô và không cộng với nhau (ví dụ `venomengine` Poison + `solarcore` Burn: tick Poison nhân 2,0 và tick Burn nhân 2,0, độc lập).

Trục A đang có: `poison` (venomengine +1,00), `burn` (hearthcore +0,70, solarcore +1,00), `thorns` (mirrorshell +1,00),
`crit` (apexpredator: hệ số crit 2 → 3, tức +1,00), `opener` (dawnlance +0,90), `shield` (ironvow +0,50).

Crit chance (khác hệ số crit): các nguồn gộp kiểu `1 − Π(1 − pᵢ)`, chặn 75% (spec §3.3).

---

## 4. Trần Reroll của `a_chaos` và của relic

Hai bộ đếm **độc lập**, đặt trong `relic_combat` (nằm trong `_state_dict`, nên Undo **không** hoàn lại), **reset đầu mỗi lượt của người chơi**.

### 4.1 Trần active (`active_reroll_gained`, trần 6/lượt)

- `a_chaos` yêu cầu +4. Lượng thực nhận `g = min(4, 6 − active_reroll_gained)`. Cộng `g` vào `rerolls` hiện tại (không chặn ở max), cộng `g` vào bộ đếm.
- `g = 0` (đã đủ 6) thì nút `a_chaos` bị mờ với lý do "Active Reroll cap reached (6/6)" và **không** tốn Mana.
- `g` từ 1 đến 3 thì vẫn tốn đủ 1 Mana, UI hiện "+g" trên nút trước khi bấm (thông tin thật, không đợi bấm mới biết).
- Ví dụ với `conduitcrown` (active dùng 2 lần/lượt): lần 1 +4 (4/6), lần 2 +2 (6/6), hết.
- Bộ đếm này chỉ cho nguồn **active**. Hiện chỉ `a_chaos`; tên field tổng quát để active Reroll sau này dùng chung.

### 4.2 Trần relic (`relic_reroll_gained`, trần 4/lượt, núm `relic_reroll_cap`)

- Tính: `cullingorder`, `apexpredator`, `alphafang`. Mỗi lần hoàn: `g = min(yêu_cầu, cap − relic_reroll_gained)`, cộng `g` vào `rerolls` (không chặn ở max) và vào bộ đếm. `g = 0` thì không hoàn và hiện chữ nổi "Relic Reroll cap (4/4)".
- Mỗi relic còn có trần riêng của nó trong mô tả (cullingorder và apexpredator max 2/lượt, alphafang 1/lượt); trần chung 4 đứng ngoài.
- **Không tính:** `a_chaos` (trần riêng 4.1), chuyển Mana→Reroll của CONDUIT (gốc và `tidecaller`), `infinitedie`/`tidalbrand`/`devilsreroll` (là max, không phải hoàn), Reroll mua bằng Aid R2 (`from_aid`).
- Tổng tối đa một lượt từ hai trần: 6 + 4 = 10 Reroll thêm, ngoài Reroll gốc và Aid.

---

## 5. `coupmark`

**Chấp nhận `hp_before = hp + dealt`**, với điều kiện: `dealt` là **HP thật đã mất** sau Shield (không tính phần Shield hấp thụ,
không tính phần overkill). Khi đó `hp + dealt` đúng bằng HP trước đòn.

- Nếu pipeline đã giữ sẵn HP trước đòn thì dùng luôn, đúng hơn. Dùng `hp + dealt` chỉ vì đỡ sửa pipeline.
- Điều kiện kiểm tra: crit **và** `is_wounded(tgt)` tính trên HP **trước đòn** **và** HP sau đòn `≤ 25% Max HP` **và** địch còn sống sau đòn. Đòn đã giết thì không cần.
- Nếu đòn toàn bị Shield nuốt (`dealt = 0`): `hp_before = hp`, kiểm điều kiện bình thường; dĩ nhiên HP sau đòn chưa tụt nên thường không kích.
- Poison/Burn tick không phải crit, không kích.

**Có áp cho boss không: KHÔNG, boss miễn nhiễm chết ngay.** Lý do: trong code hiện tại Execute chỉ là ×1,6 sát thương
(`damage_pipeline.gd:48`), "chết ngay" là cơ chế mới, và boss có phase (`boss_phase`), có đồng hồ enrage; giết tức thì phá luôn
thiết kế phase và chiến thắng boss mà Liam muốn đọc được (monetization §1). Luật này dùng chung cho **`apexferal`** (≤15% HP chết
ngay) và mọi "chết ngay" sau này: `if tgt.is_boss: không kích`. Elite vẫn bị kích. Trên thẻ ghi rõ "Bosses are immune"
cho `coupmark`; `apexferal` thêm cùng câu vào mô tả khi lane B cập nhật (mô tả hiện có của relic giữ nguyên thì thêm một câu cuối).

---

## 6. `patientfang` lượt 1: hiện "0"

**Hiện, không giấu.** Mặt hiển thị đã là `0` (xám, có icon của Patient Fang) ngay khi roll, nên người chơi thấy trước khi dùng.
Khi dùng mặt, chữ nổi cũng là `0`. Ẩn chữ nổi sẽ giống bug ("đòn trượt mất"), trái "radical transparency".

Luật chi tiết (lane B cài):
- Sát thương cuối của mặt sát thương trong lượt 1 **bị đặt về 0 sau khi tính hết mọi bonus** (G, +N, Opener, Crit). Không âm, không cần min.
- Vẫn là một đòn: gắn trạng thái rider (Burn của `wildfire` trên Horn, Weaken của `marrowdrill`, Poison của `rotmouth`), vẫn kích HIT, vẫn dùng hết die. Không có "bỏ qua đòn".
- Từ lượt 2: bonus `+2 × (lượt − 1)` tới trần +14 (lượt 8), cộng vào cùng chỗ với `+N` phẳng (sau G), nên không bị Opener nhân.
- Nếu `ironvow` cùng giữ: `−2` rồi `patientfang` đặt về 0 ở lượt 1; các lượt sau `ironvow` vẫn trừ 2 (sàn 1) trước khi cộng `patientfang`.

---

## 7. `spikedbulwark` và `thornling`

### 7.1 `spikedbulwark`: chấp nhận cách đã làm, thêm chốt tính toán

"Hết lượt" trong spec dễ hiểu sai: nếu bonus hết ngay lúc bấm End Turn thì nó không bao giờ có tác dụng, vì Thorns chỉ phản
trong pha địch. Cách lane B làm (**bonus gỡ ở đầu lượt kế của người chơi, sống qua pha địch**) là đúng.
Chuẩn hoá thành một luật chung cho mọi Thorns tạm của lượt (`spikedbulwark`, `barbedhide`): mô tả dùng chữ "through the enemy phase".

Cách tính, để hai lần Shield trong một lượt không cộng dồn lệch:
```
bonus_thorns(axie) = max( bonus hiện có , min(4, floor(Shield hiện có của axie / 5)) )
```
Tính lại mỗi lần Axie đó nhận Shield. Không cộng dồn giữa các lần nhận; chỉ lên chứ không xuống trong cùng lượt (Shield bị phá giữa
pha địch không làm bonus tụt giữa chừng, tránh người chơi không hiểu vì sao Thorns đổi).

### 7.2 `thornling`: **SỬA** (không chấp nhận bản "Egg nở giữa lượt có Thorns 3 từ lượt sau")

Egg nở giữa lượt (ví dụ `a_clutch`, `broodmother` khi kill) mà phải đợi tới lượt sau mới có Thorns thì địch đánh vào Egg ngay pha địch
của lượt đó, đúng lúc relic phải làm việc, mà Egg lại trần. Người chơi đọc thẻ "Eggs have Thorns 3" và thấy Egg không phản là bug.

Luật chốt: **Egg có Thorns 3 ngay khi tồn tại**, không phụ thuộc lượt nào. Cài bằng hook sinh Egg (gán `thorns = max(thorns, 3)` lúc spawn)
cộng một lần gán cho các Egg đang có khi nhận relic hoặc lúc `on_combat_start`. Nếu cách này tốn hơn dự kiến, lane B báo lại,
không tự giữ phiên bản trễ một lượt. Mô tả trên thẻ giữ nguyên ("from the moment they appear").
Phần "Egg phản Thorns thì Axie kề nhận 2 Shield" giữ như spec.

---

## 8. Offer pool cho L1 (nhắc gọn cho lane B)

Nguồn: relic-set §4. Chỉ ghi số và luật; hàm thuần, tất định, số nguyên.

### 8.1 Hai bước: chọn rarity theo nguồn, rồi chọn relic trong rarity

| Nguồn | C | R | E | L | Ghi chú |
|---|---|---|---|---|---|
| Battle thường (pw ≤ 6) | 65 | 35 | | | |
| Battle thường (pw > 6) | 50 | 38 | 12 | | |
| Mốc mỗi 3 step | | 70 | 30 | | |
| Elite | | 45 | 40 | 15 | |
| Boss, thẻ relic thường | | | 70 | 30 | |
| Boss, thẻ Pact | | | | | Không theo rarity (xem 8.4) |
| Shop (2 relic, 3 nếu `merchantscale`) | 35 | 40 | 22 | 3 | Giá 45/75/120/180 |
| Treasure | | 50 | 40 | 10 | |
| Event `chest` | | 55 | 45 | | **Bỏ Legendary khỏi chest** |
| Event `bet_small` | | | 70 | 30 | Thua −10% Max HP, giữ như cũ |
| Event `gamble_legend` | | | | 100 | Kèm −20% Max HP, giữ như cũ |

Rarity không còn relic hợp lệ thì bỏ ra khỏi bảng và chuẩn hoá lại. Không có pity Legendary ở L1 (Liam câu 9: chờ sim).

### 8.2 Loại cứng (không bao giờ offer)

1. Đã sở hữu, hoặc đã nằm trong offer đang hiện.
2. Relic con khi đang giữ relic cha: `pierceall` ⊂ `worldpiercer`, `gorehook` ⊂ `apexferal`, `windlash` ⊂ `stormcall`.
3. Pact ngoài màn Pact của boss. Pact đã từng nhận trong run (kể cả đã bán). Pact không đặt hợp lệ được (ô nhân đầy mà chỉ còn relic Eternal cùng ô).
4. Duo chưa đủ 2 tag; class upgrader khi đội không có Axie class đó; `breakersward` khi chưa giữ `talonedge` hoặc `a_pinning`.
5. `twinfates` loại hai chiều với: `tidalbrand`, `infinitedie`, `tidecaller`, `devilsreroll`, `cullingorder`, `apexpredator`, `alphafang`, `a_chaos`
   (kể cả relic khởi đầu từ meta). Giữ `twinfates` thì thẻ reward `reroll`, shop item `reroll`, event `bless_reroll` và `curse` cũng bị bỏ khỏi pool.
6. `fortuneledger` ở A10 (không còn reroll thẻ thưởng).

### 8.3 Nghiêng theo build (1/3 thẻ) và trọng số

- `score(t) = số relic đang giữ có tag t + số Axie trong đội có class gắn với t`. Ánh xạ class: plant→shield, beast→exec, aqua→mana, reptile→thorns, bug→poison, bird→pierce. Tag `uni` không tính.
- Lean tags = 2 tag có `score` cao nhất với `score ≥ 1`; hòa theo thứ tự cố định `exec shield pierce mana thorns summon growth poison crit aoe burn`. Chưa có tag nào thì chỉ dùng tag class của đội.
- Chỉ **thẻ relic đầu tiên** của mỗi lần offer là thẻ dẫn; các thẻ relic còn lại chọn trung tính.
- Trọng số `m` trong rarity đã chọn, theo thứ tự ưu tiên:
  1. Mặc định `m = 4`.
  2. Thẻ dẫn và relic chia ≥1 lean tag: `m = 12`.
  3. Relic payoff/engine/scaling mà đang giữ ≥2 enabler cùng tag: nhân thêm ×2 (tức 8 hoặc 24).
  4. **Ghi đè về `m = 1`** nếu: (a) relic payoff/engine có `score = 0` ở mọi tag archetype của nó; (b) relic nhân mà ô G/A tương ứng đã đầy; (c) đang giữ `hollowchalice` và relic là `ear` hoặc `tidecaller`.
- Chọn bằng tổng tích luỹ, danh sách ứng viên **sắp theo id tăng dần**, không float.

### 8.4 Gating và boss

- **Duo**: tập relic đang giữ (không tính chính nó) có đủ cả hai tag, một relic mang cả hai tag cũng đủ. Class đội không tính. Vào offer với `m` như thường.
- **Class upgrader**: cần ≥1 Axie class đó trong đội. Trúng lean tag của class thì nhận `m = 12` như thường.
- **Boss Pact**: nhóm Reroll (`bloodpact`, `twinfates`, `lonewolf`), Dice (`brittledice`, `patientfang`, `tithepips`, `ironvow`), Mana (`hollowchalice`, `devilsreroll`).
  Mỗi thẻ boss lấy **một pact từ mỗi nhóm** còn pact hợp lệ, bốc đều trong nhóm (pact nhân mà ô đầy: trọng số 1, còn lại 4). Còn <3 nhóm thì lấy thêm từ nhóm đã bốc cho đủ 3 pact khác nhau; còn <3 pact thì hiện bấy nhiêu; còn 0 thì bỏ thẻ Pact. Mỗi PACT một lần/run.

### 8.5 **[LỆCH SPEC]** Seed của offer

relic-set §4.5 dùng `derive_combat_seed(run_seed, node_id, salt)`. Hàm này đã bị xoá (interfaces §1.3). Offer lấy `rng: Rng`
của người gọi (seed epoch `reward`/`reward_reroll`/`node`/`shop_roll`). Hàm `pick_relic`/`pick_offer` nhận `rng` làm tham số, không tự tạo Rng.
Mỗi lần reroll thẻ thưởng được cấp một seed epoch mới nên **không còn `reroll_index` trong hash**. Phần còn lại giữ: danh sách sắp theo id,
trọng số nguyên, không phụ thuộc thứ tự UI.

---

## 9. Việc Liam cần quyết hoặc biết

Chỉ **một** việc cần Liam chọn thật sự (ở `design/l1-boons.md`): cách hiện Boon, 3 trên 8 hay cả 8.

Mình tự chốt (Liam biết là đủ, không cần trả lời; nói mình nếu muốn đổi):
1. Boss miễn nhiễm "chết ngay" (`coupmark`, `apexferal`). Hệ quả: hai relic này yếu hơn ở boss. Vẫn mạnh ở trận thường và elite.
2. `thornling`: Egg có Thorns 3 ngay lập tức, không đợi lượt sau.
3. `lonewolf` chỉ nhân mặt sát thương (spec ghi "mọi mặt"), cho khớp luật trục G.
4. `tidecaller` ra khỏi trần Reroll relic (spec tự mâu thuẫn).
5. `patientfang` lượt 1 vẫn gắn status rider, vẫn kích HIT, chỉ sát thương = 0.
6. Duo: một relic mang cả hai tag đã đủ mở duo.
7. (thêm khi review) `relaybaton` không truyền bonus dọc chuỗi, trong khi spec nói "cộng dồn đi trái sang phải". Xem mục 2.5 câu 5.
8. (thêm khi review) Boss miễn nhiễm chết ngay cũng đổi mô tả của `apexferal` (relic Legendary giữ nguyên trong spec), tức là nerf một relic ngoài danh sách 44.
