# L1: 8 Boon (monetization R8)

Người viết: game-designer (lane D) · 12/10/2026. Lane A sở hữu `godot/assets/data/rules/boons.json` và chép từ file này.
Nguồn luật: `design/proposals/monetization-v1.md` (R8, R9, Q2, Q3, MON-12, MON-13) và `production/l1-interfaces.md` §3.1, §3.3.

## 1. Luật chung (đã chốt trong monetization, nhắc lại để lane A không phải đi tìm)

- Boon **không phải relic**: không chiếm ô relic, không có rarity, không hiện trong Codex relic, không bán được.
- **Tối đa 1 Boon mỗi run từ mọi nguồn** (R8 mua lẻ, Kit R9, VIP hằng ngày, Starter, mercy). Boon chiếm **1 ô** trong trần tổng Aid (6 ở A0–A8, 4 ở A9–A10).
- **Không Boon nào áp ở run Nhiệm vụ** (MON-12), dù mua hay tặng. Run kiểu `mission` thì `boon_id` bị bỏ.
- Giá 38 Gem (R8). Mục tiêu sức mạnh: mỗi Boon nâng tỉ lệ thắng run khoảng **+1,5 điểm %** (monetization §9, ngân sách ΔP của R8). Số bên dưới là
  số đoán đầu; sim phải chỉ ra không Boon nào vượt ~1,5 điểm, vượt thì hạ số (Boon còn lại giữ nguyên).
- **MON-13:** Boon là loadout đầu run. `RunState` đổi nó thành **các số thuần** truyền vào `combat_setup` / hàm reward / shop. Không file luật
  nào được đọc `boon_id` hay `boon_source`. Hiệu ứng áp bằng số, trận không biết số đó từ Boon hay từ chỗ khác.
- Boon chỉ cộng, không bao giờ trừ hay làm xấu thứ khác. Không đụng HP (HP hồi đầy mỗi trận, ascension-v2 §1) và không đổi tiền, giá, giá bán
  (tiền in-run là Gene Shard, relic-set §3.7), nên không phải faucet.
- Cách chạm vào run có **đếm trận (`fight_index`)**: mọi trận combat (Battle, Elite, Boss) đánh số từ 1 theo thứ tự đánh trong run.
  Hồi sinh bằng Continue vẫn là **cùng một trận**, `fight_index` không đổi, nên bonus vẫn còn. "First Boss" = boss đầu tiên của run.
- Boon đã dùng hết hiệu ứng thì ô UI của Boon trên HUD mờ đi (người chơi biết nó đã hết, đúng "radical transparency"); lane U vẽ, lane A chỉ cần
  trả `boon_state` qua `hud_state()` là số (còn lại / đã hết), không phải cờ cho luật.

## 2. Tám Boon

Tất cả hiệu ứng nằm ở chỗ người chơi **thật sự chết**: trận đầu (làm quen), nhịp 3 trận đầu, và boss đầu tiên. Không có Boon nào nằm ở chỗ run có thể không bao giờ
tới (Elite, shop, event đều không chắc xuất hiện). Lưu ý (sửa khi review): #7 và #8 vẫn mất tác dụng nếu run chết trước boss đầu, nên
"luôn nhận được thứ mình mua" chỉ đúng chắc cho #1–#6.

| # | id | Name | Hiệu ứng chính xác (English trên thẻ) | Phạm vi |
|---|---|---|---|---|
| 1 | `boon_quick_hands` | Quick Hands | +1 max Reroll in your first fight. | Trận 1 |
| 2 | `boon_iron_welcome` | Iron Welcome | Every Axie starts turn 1 of your first fight with 5 Shield. | Trận 1, lượt 1 |
| 3 | `boon_spark` | Spark | Start each of your first 3 fights with +2 Mana. | Trận 1–3 |
| 4 | `boon_opening_strike` | Opening Strike | In your first 3 fights, the first damage face you use each turn gets +3 damage. | Trận 1–3, mỗi lượt |
| 5 | `boon_hatchling` | Hatchling | Start your first fight with 1 Egg. | Trận 1 |
| 6 | `boon_wide_choice` | Wide Choice | The reward screen after your first Battle shows 1 extra card. | Reward của Battle đầu |
| 7 | `boon_boss_breath` | Boss Breath | +1 max Reroll in your first Boss fight. | Boss đầu |
| 8 | `boon_boss_ward` | Boss Ward | Every Axie starts turn 1 of your first Boss fight with 5 Shield. | Boss đầu, lượt 1 |

### 2.1 Định nghĩa chính xác từng cái (cho lane A và test)

1. **Quick Hands**: trong trận có `fight_index == 1`, `max_rerolls` +1 (Reroll mỗi lượt thành `base + 1`). Cộng sau mọi giảm của Ascension (A3 −1) và trước hay sau relic đều được
   vì đều là cộng; cộng vào cùng chỗ `bonus_reroll` của `combat_setup`. Không tính vào trần relic Reroll (4.2 của `l1-relic-answers.md`: max không phải hoàn).
2. **Iron Welcome**: đầu lượt 1 của trận 1, mỗi Axie sống nhận 5 Shield (cộng vào Shield khởi đầu, qua cùng đường với `heart`/`carapace`, tức bị ảnh hưởng của trục Shield nếu có `ironvow`; Boon không né). Egg không nhận.
3. **Spark**: `fight_index ≤ 3`, đầu trận cộng +2 Mana (kho chung), trước khi roll lượt 1. Không bị `hollowchalice` ảnh hưởng (đó chỉ là mặt Mana).
4. **Opening Strike**: `fight_index ≤ 3`, mỗi lượt, mặt sát thương **đầu tiên** người chơi dùng trong lượt đó nhận +3 sát thương cộng phẳng (cùng chỗ với `+N`, sau G, không bị Opener nhân). Bắt đầu đếm lại mỗi lượt.
5. **Hatchling**: đầu trận 1, thêm 1 Egg thường (đúng loại Egg `broodpouch` tạo) vào phe người chơi. Nếu đội đã đầy chỗ Egg thì không thêm (không đẩy Axie ra). Gộp với `broodpouch`/`a_clutch` bình thường.
6. **Wide Choice**: màn reward **sau Battle đầu tiên** (node kind battle, `fight_index` bất kỳ nhưng là Battle đầu tiên, không phải Elite/Boss) hiện 4 thẻ thay vì 3. Cùng chỗ `reward_card_count` (H8) và cộng với `scavengereye`. Nếu A7 (2 thẻ) thì thành 3 thẻ. Thua Battle đầu thì chưa có reward, Boon vẫn còn cho Battle thắng đầu tiên.
7. **Boss Breath**: trong boss đầu tiên của run, `max_rerolls` +1, cộng cùng chỗ với #1.
8. **Boss Ward**: đầu lượt 1 của boss đầu tiên, mỗi Axie sống nhận 5 Shield. Như #2.

### 2.2 Gợi ý schema `boons.json` (lane A quyết định cuối, `effect` là số thuần)

```json
{
  "version": 1,
  "boons": [
    {"id": "boon_quick_hands",     "name_key": "boon.quick_hands",     "effect": {"scope": {"fights": [1]},       "max_reroll_bonus": 1}},
    {"id": "boon_iron_welcome",    "name_key": "boon.iron_welcome",    "effect": {"scope": {"fights": [1]},       "turn1_shield_all": 5}},
    {"id": "boon_spark",           "name_key": "boon.spark",           "effect": {"scope": {"fights": [1, 2, 3]}, "start_mana": 2}},
    {"id": "boon_opening_strike",  "name_key": "boon.opening_strike",  "effect": {"scope": {"fights": [1, 2, 3]}, "first_dmg_face_bonus": 3}},
    {"id": "boon_hatchling",       "name_key": "boon.hatchling",       "effect": {"scope": {"fights": [1]},       "start_eggs": 1}},
    {"id": "boon_wide_choice",     "name_key": "boon.wide_choice",     "effect": {"scope": {"first_battle_reward": true}, "reward_extra_cards": 1}},
    {"id": "boon_boss_breath",     "name_key": "boon.boss_breath",     "effect": {"scope": {"boss_index": 1},     "max_reroll_bonus": 1}},
    {"id": "boon_boss_ward",       "name_key": "boon.boss_ward",       "effect": {"scope": {"boss_index": 1},     "turn1_shield_all": 5}}
  ]
}
```

Mọi khoá trong `effect` là một con số hoặc một danh sách trận. `scope` chỉ chọn trận, không đọc trạng thái thắng/thua hay Aid.

## 3. Kiểm tra cân bằng và rủi ro

- Giá trị lớn nhất nằm ở #1, #2, #7, #8 vì chúng chỉ giúp trận khó (đầu và boss). Quick Hands/Iron Welcome dễ bị đánh giá thấp vì trận 1 gần như luôn thắng; nếu sim cho
  thấy ΔP của chúng < 0,5 điểm thì đổi phạm vi sang "trận 1–2". Người chơi mới hầu như không thấy khác biệt, đó cũng là lý do Boon phải rẻ (38 Gem).
- Boss Breath/Boss Ward là hai Boon có ΔP cao nhất (boss là chỗ run chết). Nếu sim chạm trần 1,5 điểm, hạ Boss Ward xuống 4 Shield trước.
- Chạm Aid khác: Boss Breath cho +1 Reroll **mỗi lượt cả trận boss**, nhiều hơn một lần R2 (15 Gem, +1 Reroll cho đúng một lượt, 1/trận từ A3). Nếu sim thấy Boss Breath
  ăn mất doanh thu R2 ở boss hoặc vượt 1,5 điểm, thu hẹp thành "3 lượt đầu của boss đầu". Cần sim xem hai thứ không giẫm lên nhau.
- Tập 8 Boon không có Boon nào ép chọn build, không có nút "thắng chắc", và không có Boon nào đổi luật trận (chỉ cộng tài nguyên nhỏ), đúng ý
  "Boon là tiện lợi nhỏ, không phải sức mạnh".

## 4. Việc Liam cần quyết

**Boon hiện ra thế nào ở Run Setup.** Monetization R8 viết "Chọn 1/3 Boon nhỏ (8 Boon cố định)":
- **(a) Cả 8, người chơi chọn 1 (đề xuất).** Không cần RNG, không phải giải thích "tại sao tôi chỉ thấy 3". Người trả 38 Gem biết chính xác mình mua gì (đúng "no hidden info",
  và nguyên tắc ức chế "công bằng, đọc được"). Dễ test (một danh sách cố định). Chỉ khác spec ở con số 3.
- (b) 3 trong 8, rút bởi server theo `run_id`. Giống spec R8. Nếu 3 Boon hiện ra **trước khi** trả Gem thì không phải lootbox (người chơi thấy rồi mới mua); chỉ là lootbox nếu trả trước rồi mới thấy. Bản gốc của file này nói "gần lootbox" là nói quá, bỏ ý đó.
- Cân bằng (thêm khi review): với (a), ΔP của Boon mà người chơi nhận được là ΔP của cái **mạnh nhất** trong 8 (hầu như ai cũng chọn Boss Breath/Boss Ward), không phải trung bình ~1,5 như ngân sách R8 và giá 38 Gem (MON-1) đã tính. Với (b), ít nhất còn xác suất không có boss Boon trong 3 thẻ. Nếu chọn (a) thì sim phải chứng minh Boon mạnh nhất vẫn ≤ ~1,5 điểm; nếu không thì hạ nó, không phải hạ trung bình.
- Việc này không ảnh hưởng `boons.json` (vẫn 8 mục). Lane A cứ làm file này; cách hiện là việc của lane M (Run Setup).

**Nhờ lane A:** nếu A thấy `scope` kiểu `first_battle_reward` (Boon 6) khó, báo lại, mình đổi sang "reward sau trận 1" (đơn giản hơn nhưng có thể là Elite nếu bản đồ cho phép).
