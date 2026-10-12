Trạng thái: ĐỀ XUẤT — chờ Liam review (§5.1 sửa 12/10 theo B1, chưa sim)

> **QUYẾT ĐỊNH LIAM (12/10, B1) — ưu tiên hơn thân file:** độ khó Ascension đi theo nhịp **răng cưa kiểu Angry Birds**:
> bậc thường giảm win rate 2–4 điểm, **bậc cổng A3/A6/A9 nhảy 6–8 điểm** (bậc thêm cơ chế mới); trong một run giữ
> đầu dễ, về sau khó. **§5.1 là bảng độ khó duy nhất**; `monetization-v1.md` chỉ tham chiếu (creative-director BLOCKER 1).
> Số trong §5.1 là mục tiêu sim đầu, **chưa sim**. **Liam 12/10 (sau re-review creative-director):** A4/A5 giữ là bậc
> thường (cổng vẫn A3/A6/A9); khoảng cách heavy − regular giữ 22; bỏ cột bot A; **casual A0 nâng 37 → 40** (cả cột casual
> +3), chỉ chỉnh bằng núm áp cho mọi người; **luật Continue hồi 25% từ A6 bật ngay trong sim đầu** (§2.5 mới).
> Cùng đợt sửa: A4 là **clock đầy đủ thay bản nhẹ A0** (Liam duyệt
> clock nhẹ A0 ngày 11/10, OQ-B). A4 Boss Clock và A5 Eternal cũng thêm cơ chế mới nhưng là bậc thường: **không đổi**,
> đưa vào câu hỏi 11 ở §6.

> **QUYẾT ĐỊNH LIAM (11/10, 10 câu):** (1) hạ HP/dmg, luật gánh độ khó · (2) pact bắt buộc ở A6 và A10 · (3) A1 giữ
> cả giá shop ×1,15 (Gene Shard thật) và bán relic 40% · (4) chưa có sticker Rental · (5) mốc enrage 10/8 chốt sau
> sim · (6) duyệt chung H6, H8, hệ ô 8/3 trong một lần bump `RULES_VERSION` · (7) thưởng ladder = danh hiệu cosmetic
> ở A5 và A10 · (8) giữ reroll −1 ở A3 · (9) UI mới cần mockup — Claude viết request chi tiết cho Claude Design, dựa
> trên asset Axie có sẵn · (10) Ascension cho ranked: để tới bước ranked, Claude đề xuất.

# Ascension v2 (bước 3b của relic redesign)

Tác giả: game-designer · 2026-10-10. Chưa có code, không sửa file nào khác. Mọi con số là số đoán đợt đầu, chưa qua sim. Chỗ nào chưa kiểm trên code thì ghi "chưa verify".

## 0. Đọc nhanh

- Ascension giờ là **10 luật cố định**, mỗi level một luật chính, cộng dồn. Số HP/dmg địch vẫn còn nhưng nhỏ hơn: A10 từ ×1.452 xuống ×1.331. Phần khó còn lại do luật gánh.
- Luật nhắm vào **cách người chơi dựng build** (tiền, ô relic, reroll, pact, sticker) và **nhịp trận** (đồng hồ enrage ở boss). Không có luật nào giấu thông tin, không có trait khắc chế trên địch, không đụng luật HP (hồi đầy mỗi trận).
- Mọi luật là hàm của một số duy nhất: `ascension`. Không có lựa chọn của người chơi, không có RNG riêng. Replay-verify chỉ cần header `ascension` đã có sẵn.
- Phần lớn nằm trong nhóm file `scripts/core` + `RunState`, nên dùng **chung một lần bump `RULES_VERSION`** với bộ relic (đúng quyết định B3 của Liam).
- Có 3 chỗ phụ thuộc vào bộ relic mà Liam chưa duyệt (hook H6 `relic_state`, hook H8 `run_economy`, và ô relic 8/3). Ghi rõ ở §3.

| Lv | Tên | Luật mới (cộng dồn) | Số giữ lại |
|---|---|---|---|
| A1 | Lean Pack | Shop đắt hơn, bán relic được ít hơn | HP địch +10% |
| A2 | Elite Escort | Elite có thêm 1 quái | (giữ nguyên luật cũ) |
| A3 | Short Dice | Reroll gốc −1 | dmg địch +10% |
| A4 | Boss Clock | Boss có đồng hồ enrage **đầy đủ** hiện sẵn (thay bản nhẹ A0, §2.4) | HP boss +15% |
| A5 | Eternal Gift | Relic từ elite bị sticker Eternal; weaken đầu trận có báo trước | (weaken giữ nguyên) |
| A6 | First Pact | Boss đầu tiên bắt buộc nhận 1 pact | HP địch +10% |
| A7 | Narrow Offer | Reward còn 2 thẻ | (giữ nguyên luật cũ) |
| A8 | Cramped Pack | 7 ô passive thay vì 8 | dmg địch +10% |
| A9 | Hunted | Thêm 2 elite trên tuyến; đồng hồ boss nhanh hơn | (+2 elite giữ nguyên) |
| A10 | Last Stand | Mọi boss bắt buộc pact; không còn reroll reward | HP +10%, dmg +10% |

## 1. Mục tiêu thiết kế

### 1.1 Mỗi level dạy hoặc thử cái gì

Ladder đi theo thứ tự "học một thứ mới mỗi level", không phải "thêm một số to":

| Giai đoạn | Level | Người chơi phải học |
|---|---|---|
| Quản lý tài nguyên | A1–A2 | Tiền và HP của quái đều quý hơn; elite là rủi ro có chủ đích |
| Quản lý dice | A3–A4 | Không dựa được vào reroll vô tội vạ; trận không kéo dài mãi được |
| Đánh đổi build | A5–A6 | Relic không phải lúc nào cũng thay được; pact là quyết định thật, không phải lựa chọn bỏ qua |
| Chọn lọc | A7–A8 | Ít lựa chọn hơn, ít chỗ chứa hơn: build phải gọn |
| Tổng kiểm | A9–A10 | Mọi thứ trên cùng lúc, tuyến đường nguy hiểm, mọi boss đều đòi một pact |

### 1.2 Tuân theo pillar, không giấu thông tin

Mỗi luật phải qua 4 câu hỏi trước khi vào bảng:

1. **Nhìn thấy trước khi quyết định.** Người chơi biết luật trước khi vào run (màn chọn level liệt kê luật), và biết con số cụ thể ngay lúc nó có tác dụng (giá đã cộng, đồng hồ enrage hiện trên boss, sticker hiện trên thẻ trước khi chọn).
2. **Không thêm trait khắc chế cho địch.** Luật nằm ở phía người chơi (tiền, ô, reroll, pact) hoặc là một đồng hồ chung cho mọi boss. Không có chuyện "quái có Thorns nên build crit bị phạt".
3. **Enemy-agnostic.** Không luật nào nhắc tên quái, class quái, hay sprite. Đồng hồ enrage đọc số lượt của trận và chỉ số boss hiện tại, nên quái Atia 3D thay Chimera vẫn chạy nguyên.
4. **Tất định.** Không có chọn ngẫu nhiên ẩn. Chỗ cũ có chọn ngẫu nhiên (weaken đầu trận) vẫn dùng `combat_seed`, và giờ được báo trước.

Hệ quả cố ý: mình **không** dùng các ý sau, dù có trong research:
- Hades Heat tự chọn (đã bị Liam loại ở Q12).
- Relic "Perishable" biến mất sau N trận hay "random purge": mất đồ không báo trước là cảm giác bị phạt vô lý, và làm khó replay.
- Mọi thứ đánh vào HP carry.
- Affix địch kiểu StS "elite có thêm hiệu ứng".

### 1.3 Quyết định mới nào được tạo ra (MDA)

Mục tiêu aesthetic là **Challenge + Expression**. Mỗi luật chuyển một câu hỏi từ "build có đủ mạnh không" sang "build có gọn và đủ linh hoạt không":

| Luật | Quyết định mới |
|---|---|
| Shop +15%, bán 40% | Mua relic thử rồi đổi hay giữ tiền cho món chắc chắn |
| Reroll gốc −1 | Đầu tư vào relic Reroll hay xây build không cần reroll |
| Boss Clock | Build chậm (growth, thorns, shield) phải đổi thành build có điểm kết thúc |
| Eternal | Nhận relic elite miễn phí nhưng khoá một ô, hay bỏ qua |
| Pact bắt buộc | Chọn drawback nào hợp build nhất (Reroll/Dice/Mana), đã có 3 nhóm để chọn |
| 2 thẻ reward, 7 ô | Bán gì để vừa, và có dám bỏ thẻ để giữ ô trống |

## 2. Bảng A1–A10

Cột "Số kept" là số nhỏ giữ lại từ ladder hiện tại. Cột "Áp lực" là archetype/kiểu chơi bị nhắm. Cột "Vì sao công bằng" là lý do người chơi tự đổi cách chơi được, không phải chỉ chịu trận.

### 2.1 Bảng chi tiết

| Lv | Luật mới | Loại | Số kept | Áp lực lên | Vì sao công bằng |
|---|---|---|---|---|---|
| **A1** Lean Pack | Giá shop ×1.15 (làm tròn, §2.2). Bán relic lấy 40% giá gốc (thay 50%) | Shop/reward | HP địch ×1.10 | Build đổi relic liên tục, relic economy; run nào cũng cần chọn kỹ hơn | Giá hiện sẵn ở shop, tiền không mất bí ẩn. Bỏ qua shop vẫn là lựa chọn hợp lệ |
| **A2** Elite Escort | Elite có +1 quái (luật cũ, giữ) | Elite | — | Build chậm hoặc cần hồi sức; nhấn việc có nên đánh elite | Số quái hiện rõ trên map; người chơi chọn đi hay né elite |
| **A3** Short Dice | Số Reroll gốc −1 mỗi lượt (tính trước relic, sàn gốc 1; §2.3) | Dice/reroll | dmg địch ×1.10 | Build câu crit, build sống nhờ reroll (`tidalbrand`, `infinitedie`) | Mọi nguồn reroll từ relic vẫn cộng bình thường, nên đổi build được |
| **A4** Boss Clock | Boss có **Enrage đầy đủ**: từ lượt 10, mỗi lượt dmg của boss +20% (cộng dồn, tối đa +100%). **Thay bản nhẹ A0** (lượt 14, +10%/lượt, tối đa 3 cộng dồn, §2.4), không cộng thêm lên trên. Bộ đếm hiện trên boss | Boss | HP boss ×1.15 | Build chậm: Plant growth, Thorns/Shield chờ trận kéo dài, poison tick yếu | Bộ đếm hiện từ lượt 1; người chơi tính trước được. Đây là đồng hồ, không phải trait |
| **A5** Eternal Gift | (a) Relic nhận từ **elite** có sticker **Eternal**: không bán/không đổi được (tối đa 2 relic Eternal mỗi run; relic elite thứ 3 trở đi không sticker). (b) Axie bị weaken đầu trận được báo trước lượt 1 | Sticker + trận | weaken cũ giữ nguyên | Build cần tuỳ biến ô; build dùng relic yếu để chờ thay | Sticker hiện trên thẻ **trước khi** chọn; relic Eternal vẫn là relic miễn phí |
| **A6** First Pact | Boss **đầu tiên** của run: màn Pact không còn nút "bỏ cả 3", phải nhận 1 (§4.4 relic-set). Pact chiếm ô passive như cũ | Pact | HP địch ×1.10 | Build đã đầy ô; build đã dựa vào reroll (nhóm drawback Reroll đau hơn) | Vẫn chọn 1/3, mỗi nhóm drawback một cái. Drawback không đụng HP |
| **A7** Narrow Offer | Reward chỉ còn **2 thẻ** thay vì 3 (luật cũ, giữ) | Reward | — | Build cần một relic cụ thể để mở combo; người thích "vá" | Reroll reward vẫn còn; "thẻ dẫn" nghiêng theo build vẫn có (§3.3) |
| **A8** Cramped Pack | **7 ô passive** thay vì 8. Ô active giữ 3 | Slot | dmg địch ×1.10 | Build tham lam nhiều relic nhỏ; build 2-3 engine | Mọi relic đã cân theo 8 nên giảm ô là núm sạch (relic-set §8). Ô đầy thì bán đổi, hiện rõ |
| **A9** Hunted | Tuyến có thêm **2 node elite** (luật cũ `extra_elite`, giữ). Đồng hồ Boss Clock bắt đầu **lượt 8** thay vì 10 | Map + boss | — | Build chậm ở boss (áp lực thời gian, không phải HP, vì HP vẫn hồi đầy) | Vị trí elite hiện trên map trước khi đi; đồng hồ vẫn hiện sẵn |
| **A10** Last Stand | **Mọi** boss bắt buộc nhận 1 pact (nếu còn pact hợp lệ). **Không còn reroll reward** | Pact + reward | HP ×1.10 và dmg ×1.10 | Mọi build: phải sống với tối đa 3 drawback cùng lúc | Mỗi pact một lần/run (9 pact, tối đa 4 boss), nên luôn còn ≥3 pact hợp lệ ở mọi boss. Không offer `fortuneledger` (A10 không có reroll thẻ). SỬA SAU REVIEW 11/10 |

### 2.2 Số cụ thể của A1

Giá mua tính từ giá gốc rarity (relic-set §3.1): `price = round_half_up(base × 1.15)`:

| Rarity | Gốc | Ở A1+ | Bán (40% giá gốc, làm tròn xuống) |
|---|---|---|---|
| Common | 45 | 52 | 18 |
| Rare | 75 | 86 | 30 |
| Epic | 120 | 138 | 48 |
| Legendary | 180 | 207 | 72 |

SỬA SAU REVIEW 11/10: `merchantscale` không còn đổi giá hay tỉ lệ bán (nó thêm 1 slot relic trong shop, relic-set §1.5), nên giá Ascension là giá cuối và tỉ lệ bán A1 là 40%, không có phần "trả lại 10 điểm".

### 2.3 Reroll ở A3

`reroll_max_final = max(0, max(1, base − 1) + Σ relic)`. Chỗ "sàn 1" chỉ bảo vệ **phần gốc** để Ascension không biến Axie thành 0 reroll từ đầu. Relic như `bloodpact` (−2, sàn 0) vẫn có thể kéo xuống 0 vì đó là lựa chọn của người chơi. **Chưa verify:** số reroll gốc hiện tại ở Godot (đọc từ `MetaState` + `RunState.bonus_reroll`), cần xác nhận lúc làm để A3 không rơi quá thấp so với phần unlock meta.

### 2.4 Enrage ở A4 (chi tiết)

```
turn = số lượt của trận, đếm từ 1
clock_start = 10 (A4–A8), 8 (A9–A10)
nếu turn >= clock_start:
    stacks = min(5, turn - clock_start + 1)
    boss_dmg_mult *= (1 + 0.20 * stacks)
```

- **Bản nhẹ ở A0–A3** (Liam duyệt 11/10, `monetization-v1.md` §1.2-C): `clock_start` = 14, +10%/lượt, tối đa 3 cộng dồn (+30%), cùng bộ đếm hiện sẵn. Từ A4 công thức trên **thay hẳn** bản nhẹ, không cộng chồng. Tắt trong giai đoạn làm quen của tài khoản mới (5 run đầu). Hệ quả cho sim G: delta của A4 đo **so với bản nhẹ A0**, không so với "không có clock".
- Đếm theo **lượt của trận**, không reset khi boss sang phase 2 (Nightmare Agony có 2 phase). Chưa reset là cố ý: reset sẽ cho người chơi kéo dài trận.
- Chỉ áp cho node kind `boss`. Đồng hồ nhân với dmg của boss, không phải với mặt dice của người chơi.
- Hiện trên boss nameplate "Enrage in N" rồi "Enrage ×1.4". Đây là UI mới, cần mockup (§4.3).

### 2.5 Luật Continue từ A6 (MỚI 12/10, Liam, theo B2 và re-review creative-director)

Hiệu ứng Continue (do `monetization-v1.md` định nghĩa: đội sống lại, địch giữ HP/phase, enrage/attrition về 0, dice mới) có **tỉ lệ hồi HP của đội là hàm của `ascension`**: **A0–A5 hồi 40%, từ A6 hồi 25%**. Luật này **bật ngay trong sim đầu**, không còn là dự phòng.
- Mọi người như nhau: không đọc ví, không đọc việc đã mua Continue hay chưa, không đọc chuỗi thua (MON-5, MON-13). Chỉ có một chỗ đọc `ascension`.
- Hiện cho người chơi: nút Continue hiện **HP boss còn lại và mức hồi** (40% hay 25%) trước khi trả tiền.
- Không đổi luật HP "hồi đầy mỗi trận": Continue là hồi sinh trong trận, không mang qua trận.
- Ghi vào `ascension_mods()` như một trường `continue_heal_pct` (40 hoặc 25), thuộc đợt bump `RULES_VERSION` chung.
- Sàn thắng khi mua Continue ở boss (telemetry của monetization): A0–A5 50–80%, A6–A10 35–60%.

## 3. Tương tác với relic và economy

### 3.1 Với relic (bản `relic-set-v2.md`)

| Luật | Chạm vào | Hệ quả / cần gì |
|---|---|---|
| A1 giá + bán | §3.1 bán 50% | SỬA SAU REVIEW 11/10: `merchantscale` giờ chỉ thêm 1 slot relic trong shop (3 thay 2), không đổi giá hay giá bán, và `tithepurse` đã bị bỏ, nên A1 không còn tương tác với relic economy. A1 làm thẳng trong `RunState`, không cần hook `price_mod` |
| A3 reroll | `tidalbrand`, `infinitedie`, `tidecaller`, `devilsreroll`, `twinfates`, `bloodpact` | Relic Reroll giá trị cao hơn ở A3+. `twinfates` (tắt Reroll cộng) không bị ảnh hưởng thêm |
| A4/A9 Enrage | Build chậm: `patientfang`, `worldtree`, `heartwood`, plague slow | Không đổi relic; có thể làm `patientfang` yếu ở boss. Cần sim C |
| A5 Eternal | Cần field `sticker` cho relic trong run. Hook **H6 `relic_state`** là chỗ lưu | **Phụ thuộc H6.** Nếu Liam bỏ H6, Eternal lưu ở một cờ riêng trong `RunState` (cùng save, cùng replay). Ghi trong ActionLog khi nhận relic |
| A6/A10 Pact bắt buộc | §4.4 cho phép bỏ cả 3 | **Đổi luật chọn pact ở Ascension**, không đổi pact nào. SỬA SAU REVIEW 11/10 (Q3): luật pact là "mỗi PACT một lần/run" nên 9 pact chia cho tối đa 4 boss: luôn còn ≥3 pact hợp lệ tới boss cuối, thẻ không còn co 3→2→1. Thẻ Pact chỉ bị bỏ nếu pool hợp lệ rỗng (rất hiếm). Pact ép khi ô đầy: **hộp bán bắt buộc, không có nút hủy**, chỉ bán được relic không-Eternal (relic-set §3.1). Pact không thể đặt hợp lệ bị lọc khỏi thẻ ngay từ offer |
| A10 reroll thẻ thưởng + `fortuneledger` | Hạ tầng reroll thẻ đã có (`reroll_pending_rewards`, `reward_reroll_max` = 1 từ meta) | SỬA SAU REVIEW 11/10 (F-06): A10 đặt `reward_reroll_max` = 0. `fortuneledger` (cộng +1 charge) **không offer ở A10**, vì cộng vào 0 vẫn là charge thừa trái luật A10. Các level khác không đổi |
| A7 2 thẻ | `scavengereye` (+1 thẻ), H8 `reward_card_count` | `count = 3 − (A≥7 ? 1 : 0) + bonus từ relic`. Scavenger Eye ra 3 thẻ ở A7+. "Thẻ dẫn" luôn là thẻ relic đầu tiên |
| A8 7 ô | 8 ô passive (§3.1), pact chiếm ô | Pact + Eternal chiếm 3 ô nên còn 4 ô tự do ở A10 (nếu 2 Eternal + nhiều pact). Đây là cái giá cố ý |
| Trần G ×2.5 | không đổi | Mình **không** dùng trần G làm luật Ascension (§5.5): ít build chạm trần (≤5% theo mục tiêu sim), luật này gần như vô hình |

### 3.2 Không có relic mới nào bị đòi

Không luật nào yêu cầu sửa, thêm, hay bỏ relic (SỬA SAU REVIEW 11/10: chỉ có một ràng buộc offer, A10 không offer `fortuneledger`, ở bảng trên). Chỉ có **3 thứ hạ tầng** Liam chưa duyệt và phải duyệt cùng lúc:
1. Hook H6 (`relic_state`) hoặc một cờ tương đương cho Eternal.
2. Hook H8 (`reward_card_count`, `shop_relic_count`; SỬA SAU REVIEW 11/10: `price_mod` đã bỏ) cho A7. Nếu không có H8 thì A1/A7 vẫn làm được bằng cách sửa thẳng `RunState`/`reward_generator.gd` nhưng relic economy không đọc được.
3. Hệ ô 8/3 và bán 50% (cho A1, A8).

### 3.3 Với economy

- **XP**: giữ `+25×A` mỗi run. Mình không đề xuất đổi: XP là phần thưởng của việc leo ladder, và run càng khó thì càng ít người thắng nên XP thắng (+150) càng hiếm. Đủ cân rồi.
- **Gene Shard**: Ascension **không** cộng hay trừ trực tiếp. Phần thưởng 25/45/90 mỗi trận không đổi.
- **Vấn đề cần economy-designer**: spec cũ ghi shop mua bằng Gene Shard và phần chưa tiêu thì bank về meta khi `end_run`. Relic-set gọi đó là "tiền in-run" (chưa xác nhận tên). **Nếu shop trong run thực sự tiêu Gene Shard thật**, thì A1 (giá +15%) là sink Gene Shard trá hình: người chơi ở A1+ nhận ít Shard hơn một chút. Mình đề xuất: **kiểm trước**, nếu đúng thì A1 áp dụng cho "tiền in-run" riêng, hoặc economy-designer duyệt riêng. Chỗ này không tự quyết (§6 câu 3).
- Không có phần thưởng cosmetic hoặc mốc mới ở bản này; leo level đã là phần thưởng. Nếu Liam muốn mốc, mình đề xuất một danh hiệu ở A5 và A10 (không cho sức mạnh, hợp với quyết định "Land không cho sức mạnh").

## 4. Ghi chú triển khai

### 4.1 Cái gì chỉ là data

| Luật | Chỗ đặt | Loại |
|---|---|---|
| Số HP/dmg/boss_hp (A1, A3, A4, A6, A8, A10) | `ContentDB.ascension_mods()` (hiện hardcode, nên chuyển thành bảng data) | Chỉ đổi số |
| `elite_extra` (A2), `extra_elite` (A9), `rewards` (A7) | Đã có trong `ascension_mods()` | Không đổi code, chỉ giữ |
| `weaken` (A5) | Đã có (`combat_engine.gd` ~155) | Giữ |

### 4.2 Cái gì cần code engine

| Luật | Cần gì | Chạm `scripts/core`? |
|---|---|---|
| A1 giá/bán | giá shop ×1.15, tỉ lệ bán trong `RunState`, `reward_generator.gd` hoặc shop | Có, nếu shop nằm trong core (chưa verify). Phần giá nằm ngoài combat |
| A3 reroll | Đọc `ascension` khi dựng `reroll_max` | Có (`combat_engine.gd`/`unit.gd`) |
| A4/A9 Enrage | Nhân dmg boss theo lượt | Có (`combat_engine.gd`/`damage_pipeline.gd`) |
| A5 Eternal | Field sticker, từ chối bán, ghi ActionLog | Có (`RunState`, `action_log.gd`) |
| A5 weaken báo trước | Chỉ UI hiện thông tin đã có | Không |
| A6/A10 Pact bắt buộc | Màn Pact không có nút bỏ qua | `reward_generator.gd` / `RunState` (core hay không: chưa verify) |
| A7 | `reward_card_count` | Có (H8) |
| A8 7 ô | Hằng số ô passive theo `ascension` | `RunState` |

**RULES_VERSION:** hầu hết luật trên nằm trong nhóm 19 file bị fingerprint (`t_rules_version`), nên **cần bump `RULES_VERSION`**. Cách làm đúng là **gom vào cùng một lần bump** với 8 hook relic (relic-set §5), đúng quyết định B3. **Chưa verify:** `ContentDB.gd` có nằm trong danh sách fingerprint hay không. Nếu có thì đổi `ascension_mods()` cũng là bump. Người làm kiểm bằng `t_rules_version` trước khi sửa.

### 4.3 UI (cần ux-designer và mockup trước, theo luật "không bịa UI")

- Màn chọn Ascension: liệt kê luật từng level (có thể đã có chỗ, chưa verify).
- Nameplate boss: bộ đếm Enrage.
- Thẻ reward/shop: sticker Eternal.
- Màn Pact: ẩn nút bỏ ở A6/A10.
- Lượt 1: báo Axie bị weaken (A5).

### 4.4 Replay

Header action log đã có `ascension`. Luật là hàm thuần của số đó, nên replay dựng lại đúng. Cần thêm: (a) `sticker` hoặc "relic X nhận từ elite" ghi vào ActionLog khi nhận, (b) test tamper: sửa `ascension` trong header phải bị `RunVerifier` bắt (A10 giả thành A0 sẽ có giá/ô khác nên fail).

## 5. Kế hoạch cân bằng

### 5.1 Đường cong thắng mục tiêu (BẢNG ĐỘ KHÓ DUY NHẤT của game; SỬA 12/10, B1 răng cưa)

**Đây là bảng duy nhất.** `monetization-v1.md` (sàn MON-11, mức nâng Aid, giá Aid) và mọi sim cân bằng chỉ **tham chiếu** bảng này, không có bảng độ khó thứ hai ở file nào khác.

**Hình dạng (Liam, B1, kiểu Angry Birds):**
- **Bậc thường** (A1, A2, A4, A5, A7, A8, A10): mỗi bước win rate giảm **2–4 điểm**.
- **Bậc cổng A3, A6, A9** (bước A2→A3, A5→A6, A8→A9): giảm **6–8 điểm**. Ba level này trùng với ba luật mới nặng nhất: A3 Short Dice, A6 First Pact, A9 Hunted.
- Trong một run vẫn giữ đầu dễ, về sau khó (xem `monetization-v1.md` §1.3). Bảng này là win rate của cả run.

**Số liệu là mục tiêu cho sim đầu, CHƯA SIM.** Ba hồ sơ (định nghĩa như `monetization-v1.md` §1.4): **casual** chọn build trung bình, ít tối ưu reroll; **regular** hiểu tag và build theo cặp; **heavy** tối ưu tốt, biết tính đồng hồ. Điểm neo A0 lấy từ mục tiêu "thật khó" của Liam (11/10): casual 40 (nâng từ 37 ngày 12/10), regular 60, heavy 82. Regular và heavy đi theo **giữa dải** (thường −3, cổng −7). Casual đi theo **đáy dải** (thường −2, cổng −6) để cả mười bước không đẩy casual xuống số âm: tổng giảm của casual 32 điểm, của regular/heavy 42 điểm.

| Level | Loại bước | Casual | Regular | Heavy | Bước casual / regular, heavy |
|---|---|---|---|---|---|
| A0 | — | **40** (sàn 35, cờ đỏ 36) | 60 | 82 | — |
| A1 | thường | 38 | 57 | 79 | −2 / −3 |
| A2 | thường | 36 | 54 | 76 | −2 / −3 |
| A3 | **CỔNG** | 30 | 47 | 69 | **−6 / −7** |
| A4 | thường | 28 | 44 | 66 | −2 / −3 |
| A5 | thường | 26 | 41 | 63 | −2 / −3 |
| A6 | **CỔNG** | 20 | 34 | 56 | **−6 / −7** |
| A7 | thường | 18 | 31 | 53 | −2 / −3 |
| A8 | thường | 16 | 28 | 50 | −2 / −3 |
| A9 | **CỔNG** | 10 | 21 | 43 | **−6 / −7** |
| A10 | thường | 8 | 18 | 40 | −2 / −3 |

Kiểm tính: casual 40 − (2+2+6+2+2+6+2+2+6+2 = 32) = 8; regular 60 − (3+3+7+3+3+7+3+3+7+3 = 42) = 18; heavy 82 − 42 = 40. Heavy A10 = 40 nằm trong mục tiêu cũ "35–40%". Khoảng cách heavy − regular không đổi, bằng 22 điểm ở mọi level (Liam giữ 22, 12/10); casual cách regular 20 điểm ở A0 và hẹp dần còn 10 ở A10.

**Casual A0 nâng 37 → 40 (Liam, 12/10):** biên so với sàn 35 là 5 điểm, lớn hơn sai số sim ±3; cả cột casual dịch +3. Nếu sim kéo casual A0 xuống dưới 40, chỉnh bằng **núm áp cho mọi người** (HP/dmg, `attrition_start`, `clock_start`). **Không** có núm riêng "bỏ clock cho casual": đó là độ khó theo hồ sơ đoán từ hành vi, trái MON-5.

**Ràng buộc (SỬA 12/10, thay "mỗi bước giảm 2–4 điểm, không bước nào >5"):**
- Bậc thường: mỗi bước giảm 2–4 điểm, không bước thường nào <2 (nếu <2 thì luật đó là nhiễu) và không >4.
- Bậc cổng A3/A6/A9: mỗi bước giảm 6–8 điểm. Cổng nhảy dưới 6 thì không còn là cổng, trên 8 là bức tường.
- **Sàn công bằng (MON-11 của monetization):** casual-không-Aid ở A0 ≥ 35% (cờ đỏ < 36%; mục tiêu 40). Casual không bao giờ < 0; A10 casual ≥ 3%.
- Chênh mạnh–yếu giữa các archetype ở bất kỳ level nào không vượt 25 điểm (cùng cổng relic-set). Archetype yếu nhất ở A10 không dưới 8% (đo bằng bot A trên 11 archetype, sim F).
- **Cột bot A của bản 11/10 bỏ** (bot trung bình 50 → 20 không khớp tổng giảm tối thiểu 32 điểm của dải mới). Sim F vẫn chạy bot A trên 11 archetype và báo cùng bảng; bot A ánh xạ vào hồ sơ nào do lần sim đầu quyết (không tự gán ở đây).
- Dùng được cho hai kiểm: win rate **không Aid**. Mức nâng của Aid là việc của `monetization-v1.md` §9.4.
- Bảng này đo **tài khoản đã qua giai đoạn làm quen** (5 run đầu tắt attrition và clock nhẹ A0, `monetization-v1.md` §1.6).

### 5.2 Sim

Dùng lại bot A–E của relic-set §6.1, thêm:

| Sim | Cách chạy | Đo gì |
|---|---|---|
| **F. Ladder sweep** | Bot A, 11 archetype, A0–A10, 300 seed mỗi ô | Đường cong §5.1, độ dốc, level nào là "bức tường" |
| **G. Ablation** | Ở A10, tắt từng luật một (mỗi luật 300 seed/archetype) | Delta winrate của từng luật. Mục tiêu **khớp bước §5.1**: bậc thường 2–4 điểm, bậc cổng (A3, A6, A9, gồm luật chính + số HP/dmg kèm) 6–8 điểm. Dưới 1,5 = bỏ hoặc gộp; trên 8 = quá nặng. Delta của A4 so với bản nhẹ A0 |
| **H. Pact bắt buộc** | A6/A10, so với cùng ladder cho phép bỏ pact | Pact nào bị chọn >60% khi bắt buộc; nhóm drawback nào bị chọn nhiều nhất (nếu 1 nhóm >70% thì drawback quá nhẹ) |
| **I. Enrage** | Trận boss với từng archetype | Tỉ lệ boss chết trước lượt 10; số lượt trung bình; TTK từng archetype; không archetype nào <35% win chỉ vì enrage |
| **J. Slot pressure** | A8 so với cùng build ở 8 ô | Winrate delta; số relic bị bán sớm; tỉ lệ run phải bán Eternal (phải =0) |

### 5.3 Tiêu chí chấp nhận

**Chức năng (tự động):**
1. Với mọi `ascension` 0–10, `ascension_mods()` trả đúng bảng §2 (test từng level).
2. Replay full-run ở A10 qua `RunVerifier` pass; header sửa ascension bị bắt.
3. Cùng `(seed, ascension)` ra cùng giá shop, cùng đồng hồ boss, cùng danh sách pact: chạy 1000 lần.
4. Không bao giờ có >2 relic Eternal; không bao giờ bán được relic Eternal; không bao giờ đổi được.
5. Ở A8+, passive không vượt 7; active vẫn tối đa 3 (4 nếu có `hollowchalice`).
6. Pact bắt buộc: ở A6 nếu người chơi không chọn thì không rời màn Pact; nếu pool pact rỗng thì màn bị bỏ, không treo.
7. `t_rules_version` và `t_full_run_loop` xanh với bộ luật mới; HP vẫn hồi đầy mỗi trận (R5 của relic-set).
8. Bot soak 2000 run A0–A10 không NaN, không treo, không vượt trần.

**Sim:** đạt §5.1 trên sim F (từng ô trong ±3 điểm, mỗi bước đúng dải: thường 2–4, cổng A3/A6/A9 6–8, casual A0 ≥ 35%); mỗi luật nằm trong dải 2–8 điểm trên sim G.

**Trải nghiệm (playtest):**
1. Người chơi nêu được luật của level hiện tại và nói mình đổi gì vì nó.
2. Ở A4+, người chơi nói được "khi nào boss bắt đầu enrage" mà không phải đoán.
3. Không ai nói luật nào là "ẩn" hay "bất công"; nếu có, luật đó bị gỡ.
4. A6+: ít nhất một lần người chơi dừng suy nghĩ lúc chọn pact.
5. Không có "level chờ qua": mỗi level phải làm người chơi đổi ít nhất một quyết định.

### 5.4 Núm chỉnh (nằm trong data, không hardcode)

| Núm | Loại | Mặc định | Khoảng | Ghi chú |
|---|---|---|---|---|
| Hệ số HP/dmg mỗi bước | curve | 10/15/10 (HP A1/A4/A6/A10) | ×1.00–1.20 | Đã giảm so với bản cũ |
| Giá shop ×, tỉ lệ bán | curve | 1.15 / 40% | 1.00–1.30 / 25–50% | A1 |
| Reroll gốc trừ | gate | −1 | 0 đến −2 | A3 |
| Enrage: lượt bắt đầu | gate | 10 / 8 | 7–14 | A4, A9 |
| Enrage nhẹ A0–A3: lượt bắt đầu, +%/lượt, tối đa | gate | 14 / +10% / 3 cộng dồn | 12–16 / +5–10% | Liam duyệt 11/10 |
| Bước đường cong §5.1 | curve | thường 2–4, cổng 6–8 | theo B1 | chỉ là mục tiêu sim, không phải núm trong data |
| Enrage: +%/lượt, tối đa | curve | +20% / ×2 | +10–30% / ×1.5–×3 | A4 |
| Số relic Eternal tối đa | gate | 2 | 1–3 | A5 |
| Pact bắt buộc: boss nào | gate | đầu (A6) / mọi (A10) | | A6, A10 |
| Số thẻ reward | gate | 3 → 2 | | A7 |
| Số ô passive | gate | 8 → 7 | 6–8 | A8 |
| Số elite thêm | gate | +1 quái / +2 node | | A2, A9 |

### 5.5 Trường hợp biên

- **Trận boss kéo qua lượt 10 với Plant/shield:** Enrage chặn việc tự hồi và chờ. Nếu sim I cho thấy turtle vẫn thắng thì hạ lượt bắt đầu hoặc tăng %.
- **Nhận relic Eternal khi ô đầy:** vẫn phải bán đổi một relic khác. Trường hợp xấu nhất ở A10: 7 ô = 2 Eternal + 3 pact + 2 ô tự do. Pact bán được, Eternal không, nên luôn còn ít nhất 5 ô có thể đổi. Ô tự do tối thiểu là 2, không bao giờ về 0.
- **Full run có 4 boss:** SỬA SAU REVIEW 11/10 (Q3): 9 pact, mỗi pact một lần/run, nên boss thứ 4 vẫn có ≥5 pact hợp lệ; thẻ chỉ bỏ nếu pool hợp lệ rỗng.
- **Ô passive = 7 mà đang giữ 8 relic** (không xảy ra vì Ascension cố định từ đầu run; vẫn thêm kiểm tra hợp lệ lúc load save).
- **Chuyển Ascension giữa run:** không có; Ascension khoá khi run bắt đầu (đã đúng hôm nay).
- **Trần G:** không đổi theo Ascension (không dùng làm luật).
- **A5 weaken trùng Axie đã có status:** giữ như bản cũ; báo trước lượt 1 chỉ là UI.

## 6. Câu hỏi mở cho Liam

Đề xuất của mình ở cột phải. Liam quyết.

| # | Câu hỏi | Đề xuất |
|---|---|---|
| 1 | Hạ số HP/dmg (A10 từ ×1.452 xuống ×1.331) để luật gánh độ khó. Chấp nhận, hay giữ số cũ? | **Hạ.** Số cũ cộng thêm luật mới có thể quá cao. Sim F quyết lại |
| 2 | **Pact bắt buộc** (A6 boss đầu, A10 mọi boss) đổi luật "bỏ cả 3 pact" của relic-set §4.4. Chấp nhận khác biệt này chỉ ở Ascension? | **Có.** Đây là luật Ascension hay nhất về "buộc đổi build", và drawback không đụng HP |
| 3 | Shop trong run tiêu **Gene Shard thật** hay tiền riêng? Nếu thật, A1 (giá +15%) là sink Gene Shard | **Kiểm code trước**, rồi nhờ economy-designer. Nếu thật, đổi A1 sang bán relic 40% (không đổi giá) |
| 4 | Sticker Eternal (A5) chỉ áp cho relic **elite**. Có nên thêm sticker cho shop (kiểu Rental) ở A7+? | **Chưa.** Giữ một sticker. Nếu Eternal chạy tốt ở sim thì thêm sau |
| 5 | Enrage (A4) dùng lượt 10 cho trận boss. Chưa có số lượt trung bình thật của trận boss | **Chạy sim I trước khi chốt số.** Con số 10/8 là đoán |
| 6 | Cần duyệt cùng lúc: H6 (relic_state), H8 (run_economy), 8/3 ô. Duyệt riêng được không? | **Duyệt chung** với bộ relic để chỉ một lần bump `RULES_VERSION` |
| 7 | Mốc thưởng cho người leo ladder: danh hiệu cosmetic ở A5/A10, hay không có gì | **Danh hiệu cosmetic**, không có sức mạnh |
| 8 | Reroll gốc −1 ở A3 là tương đối sớm. Dời sang A5, và đưa Eternal xuống A3? | **Giữ A3.** Người chơi nên học reroll là tài nguyên trước khi build đã khoá |
| 9 | UI mới (đồng hồ Enrage, sticker, báo weaken) cần mockup trước. Ai làm, khi nào? | `ux-designer` làm mockup sau khi Liam chốt bảng này; không code UI trước |
| 10 | Ranked/daily có dùng Ascension không, và ở level nào? | **Chưa quyết.** Luật cố định nên ranked dùng được; cần quyết ở bước ranked profile |
| 11 | **A4 Boss Clock và A5 Eternal cũng thêm cơ chế mới, nhưng là bậc thường (2–4 điểm), chỉ A3/A6/A9 là cổng.** | **ĐÃ TRẢ LỜI (Liam 12/10): giữ A4/A5 là bậc thường; cổng vẫn A3/A6/A9.** Nếu sim G cho thấy A4 hoặc A5 nhảy > 4 điểm thì báo lại, không tự đổi |
| 12 | Khoảng cách heavy − regular = 22 điểm ở mọi level (bản 11/10 ở A6 là 26) | **ĐÃ TRẢ LỜI: giữ 22.** Nếu biên MON-11 mỏng thì hạ Aid, không nâng heavy |
| 13 | Casual đi theo đáy dải (−2 / −6) | **ĐÃ TRẢ LỜI:** giữ đáy dải; **casual A0 nâng 37 → 40**, A10 = 8; khoảng cách casual–regular từ 20 xuống 10. Chỉ chỉnh bằng núm áp cho mọi người |
| 14 | Bỏ cột bot A trung bình/mạnh nhất của bản 11/10 | **ĐÃ TRẢ LỜI: đồng ý.** Bot A đo ở sim F rồi ánh xạ vào hồ sơ |

## 7. Việc tiếp theo (đợi Liam duyệt, không tự làm)

1. Liam duyệt bảng §2 và các câu §6.
2. Kiểm code các điểm "chưa verify" (số reroll gốc, ContentDB có nằm trong fingerprint không, shop tiêu loại tiền nào).
3. Chạy sim F, G trên bản data relic mới trước khi chốt số.
4. `ux-designer` làm mockup cho §4.3.
5. Gom code luật Ascension vào cùng đợt bump `RULES_VERSION` với 8 hook relic.
