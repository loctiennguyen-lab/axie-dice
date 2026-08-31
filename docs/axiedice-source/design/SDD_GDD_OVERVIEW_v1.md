# Axie Dice Tactics: Lunacia Mutants
## System Design Document / GDD Overview — v1.0 (tổng hợp)

*Doc này gom lại toàn bộ những gì đã chốt qua các vòng thiết kế — GDD gốc, audit, spec engine, hệ Bloodline, economy/progression, combo, UI — thành một bản tổng quan duy nhất. Mục đích: một người mới vào dự án đọc xong doc này là nắm được toàn bộ hệ thống, không cần lục lại 8 tài liệu con. Chi tiết triển khai và lý do từng quyết định vẫn nằm ở các doc gốc, doc này chỉ dẫn chiếu khi cần.*

---

## 1. Tổng quan

**Tên:** Axie Dice Tactics: Lunacia Mutants
**Thể loại:** Single-player tactical roguelike, dice-drafting, deterministic (kiểu Slice & Dice)
**Nền tảng:** Web browser, Phase 1. Mobile ở Phase 2.
**Mô hình thương mại:** Free-to-play, không pay-to-win — cam kết này là một ràng buộc thiết kế cứng, không phải slogan marketing (xem §7).
**IP:** Axie Infinity — nhân vật, 6 class, 6 loại body part, art part gốc.

Game xuất phát từ một GDD viết theo cảm hứng Slice & Dice, nhưng bản GDD đầu có hai lỗi làm sụp gameplay (party 3 hero, mọi Axie có die giống hệt nhau) và thiếu ba hệ thống xương sống của thể loại này (level-up tree, enemy có dice, item/mana). Toàn bộ các doc sau GDD là một chuỗi audit sửa lại từ nền, và bản thiết kế hiện tại đã qua ba vòng kiểm chứng độc lập, mỗi vòng đều lật lại ít nhất một kết luận trước đó. Đây không phải điểm yếu — đó là lý do các con số trong doc này đáng tin hơn một bản thiết kế viết một lần rồi ship thẳng.

---

## 2. Trụ cột thiết kế

Giữ nguyên tinh thần GDD gốc, đã qua audit:

- **Deterministic & minh bạch tuyệt đối.** Người chơi thấy 100% ý định của địch trước khi hành động, được thử nghiệm và Undo tự do trong lượt. Ranh giới Undo là **randomness**, không phải nút bấm: undo stack bị xoá khi Reroll hoặc End Turn, còn lại thì undo vô hạn.
- **6 mặt xúc xắc = 6 body part Axie.** Đây là USP thật sự so với Slice & Dice — không game dice-drafting nào khác có sẵn một hệ thống part ăn khớp tự nhiên đến vậy với vocabulary Axie.
- **Rarity là đầu ra của build, không phải đầu vào.** Người chơi không mua may mắn — họ tạo ra khoảnh khắc may mắn bằng cách chơi giỏi (đẩy một mặt lên bậc cao, gọi đúng combo, chọn đúng reward). Nguyên tắc này là gốc rễ của toàn bộ hệ kinh tế ở §7.
- **AI-native architecture.** Engine là state machine rời rạc, dữ liệu JSON-driven, không có vật lý thời gian thực — thiết kế để một AI coding assistant build được toàn bộ, đúng tinh thần "vibe coding" ban đầu.

---

## 3. Vòng lặp game

```
MACRO   : Meta-progression — mở khoá part, sưu tầm Axie, Mastery, Battle Pass, mùa
MESO    : Một RUN — 12 wave (mặc định) hoặc 20 wave (Full Run, unlock được)
MICRO   : Một LƯỢT chiến đấu — Roll → Reroll → Execute → End Turn
```

### 3.1 Cấu trúc một run

Party gồm **5 Axie** (không phải 3 như GDD gốc — 3 hero với 3 dice mỗi lượt làm không gian quyết định sụp theo cấp số mũ, đây là lỗi nghiêm trọng nhất của bản gốc). Một Lead Axie do người chơi chọn sẵn từ bộ sưu tập, bốn chỗ còn lại tuyển dọc đường.

Nhịp trận: **elite và boss chia đều theo 4 act**, không dồn vào cuối như GDD gốc (wave 8/16/20 quá xa, người chơi rơi rụng trước khi thấy boss đầu tiên).

- **Short Run (mặc định):** 12 wave, elite @3/6/10, boss @4/8/12. Run ~20-30 phút — đòn retention chính, học từ Balatro (30 phút) thay vì Slay the Spire (60 phút, friction lớn hơn).
- **Full Run (unlock):** 20 wave, elite @3/7/12/17, boss @5/10/15/20.
- **Hết trận, không phải hết run, mới là nơi độ khó nằm ở đó:** heal full + hồi sinh toàn bộ Axie đã chết sau mỗi trận. Không có attrition giữa các trận — nếu có, death spiral xuất hiện và người chơi bỏ game giữa chừng (phát hiện trong audit đầu tiên).

### 3.2 Một lượt chiến đấu

```
1. ROLL     : 5 die của party + toàn bộ die địch roll đồng thời. Cantrip tự kích hoạt.
2. REROLL   : chọn từng die muốn đổi (không có khái niệm "lock" riêng — không chọn = giữ
              nguyên). Base 1 charge/lượt, nâng lên 2-3 qua reward. [Undo stack bị xoá]
3. EXECUTE  : click die → click target → thực thi. Dùng item/thẻ tốn mana. Undo tự do.
4. END TURN : resolve ý định địch theo thứ tự vị trí → tick status effect → check thắng/thua.
              [Undo stack bị xoá]
```

**Địch cũng có die và cũng roll** — ý định hiển thị chính là mặt địch vừa roll ra. Đây là nguồn variance công khai và bằng chứng cho pillar "minh bạch tuyệt đối" — GDD gốc bỏ sót chi tiết này và không giải thích ý định địch từ đâu ra.

**Targeting tự do**, không giới hạn theo hàng dọc front/mid/back như GDD gốc — vị trí chỉ ảnh hưởng tới Cleave (lan sang mặt kề cạnh) và một số AI địch dạng taunt/frontmost.

---

## 4. Cấu trúc xúc xắc

Mỗi Axie có một die 6 mặt, mỗi mặt tương ứng một body part: **mouth · horn · back · tail · eyes · ears**.

Điểm mấu chốt (khác GDD gốc hoàn toàn): **loại part quyết định tên và art của mặt, không quyết định cơ chế.** GDD gốc ép "back luôn là shield, horn luôn là dmg nặng" — khi đối chiếu với card text thật của Axie Origins, 13/20 part mẫu không khớp vai trò mặc định của slot (`Furball` — Beast·Back — là đánh 3 lần, không phải shield; `Teal Shell` — Aqua·Horn — là shield, không phải dmg). Vai trò cơ học (`role`) được gán riêng cho từng part, đọc từ card text gốc.

**Không gian tổ hợp:** 6⁴ × 4² = 20.736 tổ hợp/class, 124.416 toàn game (Mouth và Eyes chỉ có 4 part/class, các slot khác có 6).

### 4.1 Từ khoá kỹ năng (keyword)

Bắt đầu từ 15 keyword tự nghĩ trong bản audit đầu, sau khi đối chiếu với 192 part core thật của Axie thì thu hoạch thêm 12 keyword mới — nâng lên **27 keyword**, mỗi cái tự động nhân với toàn bộ pool part và relic (một keyword mới rẻ hơn nhiều so với thêm 150 relic mới).

Nhóm cũ: `cleave` · `pierce` · `aoe` · `cantrip` · `heavy` · `growth` · `decay` · `vital` · `lifesteal` · `multi:N` · `scatter:N` (đổi tên từ `chain:N` — chữ "chain" trong Axie có nghĩa khác) · `selfharm:N` · `rerollup` · `mana:N`.

Nhóm mới (thu hoạch từ card text Origins): `combo:N` · `desperate` · `breaker` · `bulwark:N` · `spite` · `sentinel` · `cleanse` · `summon` · `shieldregen` · `deny:<part>` · `resonance` · `ramp:N` / `antiheal` / `share:N`.

Status effect: `shield` (không tự hết, cap = maxHP) · `poison` · `burn` · `regen` · `stun` · `blind` · `weaken` · `vulnerable` · `thorns` · `undying` · `lock`.

**Bài học từ simulation (không thấy được bằng đọc spec):** status/debuff không được scale tuyến tính theo độ khó — một con boss ở wave 15 với `poison aoe` scale ×3 từng cho winrate 0% trên toàn bộ 500 run test. Fix: face gây hiệu ứng theo thời gian scale `s^0.50`, buff/debuff scale `s^0.45` — damage tích luỹ nhiều lượt không được scale như damage một lần.

---

## 5. Hệ Bloodline — bản sắc 6 class

Đây là hệ thống thay thế hoàn toàn cách GDD gốc định nghĩa class ("Plant tank, Beast dame cao..."). Thay vì tự nghĩ, dữ liệu 192 part core thật của Axie Origins (6 class × 32 part) được đọc và dịch sang mặt xúc xắc, và bản sắc class **nổi lên từ dữ liệu** thay vì bị áp đặt:

| Class | Bản sắc (đọc ra từ card text) |
|---|---|
| **Plant** | Shield trả cổ tức + cleanse + summon — shield không chỉ để chịu đòn, nó là điều kiện kích hoạt |
| **Beast** | Crit + "cùng đường" (thưởng khi HP thấp — desperate) |
| **Aquatic** | Tempo + mana engine + chống hồi sinh |
| **Reptile** | Tiêu hao + giáp bền (shieldregen) + phản đòn + scale muộn trong trận |
| **Bug** | Phá giáp (breaker) + debuff + poison + chống hồi máu |
| **Bird** | Tự làm hại mình để đổi lấy sức mạnh — archetype phản trực giác nhất, không đội thiết kế nào tự nghĩ ra trong một buổi họp, nhưng có sẵn trong dữ liệu và đã được hàng triệu người chơi Axie kiểm chứng là vui |

Quy trình dịch: đọc card text thật (qua Axie Origin Data API, 189/192 part khớp trực tiếp) → trích động từ cốt lõi → map vào keyword có sẵn hoặc tạo keyword mới nếu chưa có. **Giá trị số không copy từ Origins** — Origins đã rebalance nhiều lần qua các năm, copy số của nó là nhập luôn nợ cân bằng của một game khác thể loại. Giá trị được suy ngược từ ngân sách sức mạnh của từng bậc (xem §6).

**Van xả bắt buộc: Meta Morph.** Mỗi class chỉ dùng part trong bloodline riêng của mình (32 part, độc quyền) — nếu không có van xả, build hội tụ mono-class là chiến lược trội duy nhất. Meta Morph (tên và cơ chế lấy thẳng từ Axie Origins) cho phép ghép một part từ bloodline khác. Phải **luôn có mặt trong reward pool với trọng số vừa**, không phải phần thưởng hiếm — vì sau khi loại bỏ pool part chung, đây là van xả off-class duy nhất trong toàn game. Mục tiêu ~80% part từ bloodline / 20% từ Meta Morph, đo bằng chỉ số archetype diversity chứ không phải winrate.

**Secret class (Phase 2, gần như miễn phí):** Dusk (Reptile×Aquatic) · Mech (Bug×Beast) · Dawn (Plant×Bird) — trong Axie thật, các class lai không có part riêng, chỉ đổi màu body và thừa hưởng part từ 2 class bố mẹ. Dịch sang game: một hero secret class rút part từ 2 bloodline, nhưng chỉ được **3/6 slot mỗi bên** (buộc chia đôi, không lấy phần tinh tuý của cả hai) — đây là đối trọng bắt buộc, nếu không secret class chỉ là "pool 64 part, không nhược điểm".

---

## 6. Hệ bậc (rarity) trong run

Nguyên tắc trung tâm (Phương án A, đã duyệt): **rarity nằm ở tầng RUN, bộ sưu tập chỉ mở khoá danh tính.**

| Bậc | Quy tắc |
|---|---|
| COMMON | Hiệu ứng gốc + keyword đặc trưng ở giá trị tối thiểu — **không phải 0 keyword**. Nếu Common vô danh tính, sáu bản sắc class không phân biệt được trong nửa đầu run |
| RARE | Giá trị tăng |
| EPIC | Keyword đầy đủ theo card text thật |
| LEGENDARY | Giá trị lớn + 1 keyword phụ |
| MYTHIC *(Phase 2)* | Hiệu ứng phá luật, gắn theo cặp `class × slot` — không gắn theo part cụ thể |

**Lên bậc = nâng bậc mặt hiện có, không bao giờ đổi `partId`.** Đây là điểm sửa quan trọng nhất so với bản v1.1 trước đó (từng thiết kế lên tier = ghi lại toàn bộ die bằng part mới — làm mất danh tính Lead Axie ngay lần lên tier đầu tiên, đúng lúc đáng nhớ nhất của run). Gene Mutation là cơ chế **duy nhất** đổi danh tính trong run, và nó **luôn hạ mặt về Common** khi đổi — nếu không, người chơi chỉ cần đẩy bất kỳ mặt nào lên Legendary rồi Mutate ngay trước boss, biến "giữ part suốt run" thành zero-cost.

**Ngân sách sức mạnh mỗi bậc phải nằm trong ±10% (INV-5), và điều này được đảm bảo do cấu trúc, không phải do tuning tay:** công thức sinh giá trị part là `value = (ngân_sách_bậc − chi_phí_keyword) / hệ_số_role`, nghĩa là designer chỉ chọn keyword, con số tự rơi ra đúng ngân sách. Kết quả đo trên 192 part: lệch tối đa 7.7% (Common) xuống 2.9% (Legendary), 0 vi phạm. Bài kiểm này chạy tự động trong CI — vi phạm nó là đưa gradient sức mạnh vào tầng sưu tầm và biến bộ sưu tập thành pay-to-win, nên không được để lọt qua review thủ công.

**Mythic (Phase 2):** 36 hiệu ứng, khớp đúng ma trận 6 class × 6 slot của Mystic part thật trong Axie. Bất kỳ part nào đạt Legendary đều lên được Mythic của đúng ô class×slot đó, giữ nguyên tên gốc kèm huy hiệu (`RONIN ⟨HASAGI⟩`). Chủ sở hữu Axie Mystic thật trên chain nhận art gốc độc quyền ở mọi bậc — người chơi thường thấy bản "awakened" chung. Không bán skin Mystic ở cửa hàng (rủi ro IP bên thứ ba: Hasagi = Yasuo/Riot, Namek Carrot = Dragon Ball).

---

## 7. Kinh tế & Meta-progression

### 7.1 Hai tầng tách biệt

> **Tầng sưu tầm** (vĩnh viễn) → bề rộng: part nào xuất hiện được, Axie nào mang theo được, skin nào hiển thị.
> **Tầng run** (tạm thời) → sức mạnh: bậc mặt, tier hero, relic, gene mutation.

Một tính năng đứng cả hai chân là lỗi thiết kế. Ngoại lệ có chủ đích duy nhất: **Lead Axie**, cho phép tầng sưu tầm chạm vào bản sắc khởi đầu — nhưng bị cô lập ở 1-2 slot và phải đo bằng sim trước khi tăng trần.

### 7.2 Bảy bất biến (invariant) — vi phạm là bug

```
INV-1  Bộ sưu tập chỉ chứa DANH TÍNH part, không có tier/power.
INV-2  Mọi part vào run ở bậc COMMON, không ngoại lệ (kể cả Lead, kể cả NFT).
INV-3  Lên tier không bao giờ thay partId.
INV-4  Gene Mutation luôn hạ mặt về COMMON.
INV-5  Mọi part cùng bậc nằm trong ±10% ngân sách sức mạnh.
INV-6  Không có đường từ TIỀN THẬT → SỨC MẠNH.
INV-7  Run thường không bao giờ bị gate bởi năng lượng, vé, hay cooldown.
```

### 7.3 Ba loại tiền tệ

| Tiền | Kiếm bằng | Tiêu vào | Mua bằng tiền thật? |
|---|---|---|---|
| **Gene Shard** (mềm) | Run, wave, daily quest | Mở part (giá phẳng ~400, không theo rarity) · Pin · Forge · reroll shop | Không |
| **Moon Dust** (cứng) | Mua / nhỏ giọt từ Battle Pass free track | Cosmetic · Battle Pass · mở part trực tiếp | Có |
| **Gauntlet Ticket** | 3 vé/ngày miễn phí, BP, mua | Vào seed mới của Gauntlet | Có |

Bốn luật cứng: (1) không bao giờ gate run thường bằng năng lượng/vé — đây là cuộc tranh luận với C-Level chắc chắn sẽ xảy ra, và lập luận phải chuẩn bị sẵn: chặn nó là chặn chính vòng lặp "thua rồi chơi lại ngay" nuôi sống roguelike; (2) không bán chỉ số dưới mọi hình thức; (3) không có tỷ giá quy đổi Shard ↔ Moon Dust; (4) vé Gauntlet mua **seed mới**, không mua lượt thử lại trên seed cũ — nếu không, engine seeded RNG biến vé thành lợi thế bảng xếp hạng mua được.

### 7.4 Bộ sưu tập & Mastery

- Tài khoản mới mở sẵn **60 part** (10/class) — không có thì người mới chỉ gặp ~16 hình dạng Axie trong nhiều giờ đầu, đây là điều kiện onboarding chứ không phải quà tặng.
- **Axie Forge** (ghép 6 part thành một Axie đặt tên, lưu làm Lead) có 3 ràng buộc bắt buộc: đúng 1 part/slot, đơn class, luôn vào ở bậc Common. Bỏ bất kỳ ràng buộc nào là mở lỗ khai thác đã biết (VD: 6 mặt cùng `Anemone`, mà `Anemone` là "hồi 50 HP cho mỗi part Anemone" → resonance cực đại vĩnh viễn từ T1).
- **Mastery:** dùng part tích luỹ lượt dùng → mở **biến thể** (cùng ngân sách sức mạnh, khác keyword) và cosmetic. Không bao giờ cộng chỉ số hoặc tăng tần suất xuất hiện — mốc từng có ý định làm việc này (M5) đã bị cắt vì nó là mốc duy nhất bán được sức mạnh và tự triệt tiêu ở endgame. **Pin** một part → Mastery gấp đôi, cho quyền chủ động mà không cho sức mạnh.
- **1 slot Lead Axie khi ra mắt, trần cứng 2**, không bao giờ có 3. Giá trị thật của một slot Lead **chưa đo được bằng lý luận** (câu hỏi S1, mọi mô hình đưa ra số khác nhau tuỳ hằng số tự đặt, dao động +14% đến +120%) — quyết định trần 2 là quyết định thận trọng, chờ sim xác nhận. Slot thứ hai mở bằng chơi, không bao giờ bán bằng tiền.

### 7.5 Monetization

Season Pass (~$8.99, 4-6 tuần) · cosmetic ($2-8) · Starter/Collector Bundle (bán tốc độ mở part) · tiện ích (tăng tốc Mastery, slot Pin) · Gauntlet Ticket. Mục tiêu Phase 1: conversion ≥3%, ARPDAU ≥$0.02.

**Danh sách công khai không làm:** không gate năng lượng ở run chính · không bán mặt có chỉ số · không gacha cầu sức mạnh · không bán slot Lead thứ hai · không bán lượt thử lại cùng seed · không bán skin Mystic · không token thưởng gameplay. Cộng đồng Axie đã bỏng một lần vì P2E — ở công ty này, pay-to-win không chỉ là rủi ro thiết kế, nó là rủi ro thương hiệu.

---

## 8. Combo & tương tác giữa các mặt

GDD gốc không có cơ chế nào thưởng cho việc phối hợp nhiều mặt trong một lượt. Bốn phương án được mô hình hoá định lượng để lấp khoảng trống này (chi tiết trong `COMBO_DECISION_MEMO.md`), ba phương án đầu đều bị loại vì lý do đo được, không phải cảm tính:

- **PER-HERO** (nhiều mặt dồn vào một hero) — về mặt toán học tương đương TARGET, tốn công viết lại engine mà không đổi kết quả.
- **TARGET** (mặt cùng nhắm một mục tiêu) — chi phí cơ hội đo được ≈ 0 vì dồn hoả lực vốn đã là chiến lược trội sẵn có; với boss (1 địch) nó không tạo ra lựa chọn nào cả.
- **TEAM** (đếm số mặt cùng loại toàn đội) — quá yếu nếu giữ ngưỡng an toàn, và suy biến thành build "dồn part" nếu tăng bonus.

**Phương án chọn: DECLARE ("Gọi mặt").** Đầu lượt, người chơi tuyên bố một loại part sẽ theo đuổi trong lượt đó, dùng reroll để đuổi theo, đạt ngưỡng (3 mặt) thì nhận bonus lớn (+18-24% sức mạnh đo được), trượt thì mất trắng và đã tốn reroll. Đây là phương án duy nhất biến reroll từ công cụ *sửa sai* thành công cụ *theo đuổi* — đúng cảm giác cần có, và không đổi mô hình engine (không cần nhiều mặt trên một hero).

**BLOODCHAIN** (thưởng cho đội hình mono-class) được đo lại và phát hiện **tương quan dương** với combo theo part (party mono-class đạt combo:3 gấp 2.3 lần đội trộn class) — nếu cả hai cùng thưởng bằng damage, chúng cộng dồn và đẩy hội tụ build. Quyết định sửa: BLOODCHAIN trả bằng tài nguyên khác trục (reroll charge, mana, shield, cleanse), không phải damage.

---

## 9. Cân bằng độ khó

Không hardcode bảng chỉ số — mọi encounter mua monster theo **ngân sách điểm (point-budget)**, scale theo wave. Player power suy từ **số reward đã nhận** (power level), không phải theo step index — nhờ vậy một công thức phục vụ được cả Short Run (12 wave) lẫn Full Run (20 wave) mà không cần hai bảng riêng.

**Ba lỗi thiết kế chỉ phát hiện được bằng chạy simulation, không thấy được khi đọc spec:**

1. Status/debuff scale tuyến tính tạo bức tường bất khả thi ở wave giữa-cuối (xem §4.1).
2. Player power đứng yên sau khi hero đạt tier tối đa (không còn reward Level Up) tạo cliff ở wave 14-20 — fix bằng budget piecewise (chậm lại sau wave 12) cộng reward mới **Ascension** cho hero đã max tier.
3. Cơ chế thorns/summon của boss scale tuyến tính tạo death spiral — fix bằng giảm hệ số scale và thêm hard cap.

**Kết quả đo (500 run, AI chơi greedy, không phải người thật):**

| | Short Run 12 wave, Ascension 0 | Full Run 20 wave, A0 |
|---|---|---|
| Winrate cả run | **14.4%** | **6.0%** |

Ascension là bộ điều tiết độ khó, không phải một hằng số cố định: A0 14.4% → A3 9.2% → A6 5.2% → A10 0.4%. AI chơi greedy 14% ước tính tương đương người chơi giỏi ~25-30% ở Short Run A0 — đúng vùng roguelike gây nghiện theo mục tiêu thiết kế ban đầu (không quá dễ tới mức nhàm, không quá khó tới mức bỏ cuộc).

**Hai chỉ số quan trọng hơn cả winrate** (vì winrate chỉ nói game khó hay dễ, không nói game có đáng chơi lại không):
- **Replay-rate** (bấm chơi lại sau khi chết) ≥ 55% — North Star, không đạt thì mọi chỉ số khác vô nghĩa.
- **Archetype diversity** ≥ 8/10 archetype có run thắng — chống hội tụ build.

---

## 10. UI/UX

Bốn luật thiết kế xuyên suốt toàn bộ giao diện (`UI_DESIGN_SYSTEM_v0.8`):

1. **Nền trung tính, màu mang nghĩa.** Bảy màu ngữ nghĩa cố định (vàng = có thể hành động, đỏ = damage, xanh dương = shield, xanh lá = hồi máu, tím = mana, chanh = poison, hồng = debuff). Rarity giữ 5 màu riêng, không dùng cho việc khác.
2. **6 cỡ chữ, không hơn.** 9/11/13/17/26/40px.
3. **1 độ dày viền, 2 bán kính bo góc, spacing theo lưới 4px.**
4. **Glow chỉ đánh dấu 3 thứ:** die đang chọn, target hợp lệ, và rarity Mythic.

Layout chiến đấu gộp về một thanh header duy nhất (trước đó có 2 thanh trùng lặp thông tin), bỏ label tên part dưới mỗi die (vị trí đã nói lên die thuộc về ai), mana orb đổi từ vòng tròn sang pill có số đọc ngay. Board được scale để luôn vừa các độ phân giải laptop phổ biến (1280×720 trở lên) mà không cần cuộn trang.

**Trạng thái QA hiện tại:** 3 script Playwright tự động (regression input, kiểm layout đa độ phân giải, soak test) chạy trên build thật — 79 run hoàn chỉnh, 0 crash, 0 stall, 0 dead-end. Các bug nghiêm trọng đã sửa gồm: mặt không cần target (AoE/mana/summon) không bấm được bằng chuột — vô hiệu hoá toàn bộ archetype Conduit; một lỗi playback duy nhất từng có thể khoá cứng toàn bộ input đến hết run.

---

## 11. Kiến trúc kỹ thuật

```
engine.js  — thuần logic, không đụng DOM, seeded RNG, snapshot/undo bằng deep-clone state
data.js    — heroes / monsters / items / waves / 192 part + bảng 4 bậc, đọc từ economy_config.json
ui.js      — DOM render diff
sim.js     — chạy N run headless (node) để tune đường cong độ khó, không phải để balance bằng tay
```

Build ra một file HTML self-contained. **Không hardcode hằng số cân bằng trong engine/ui** — mọi con số đọc từ `economy_config.json`.

Data model tách rõ hai tầng: `PlayerProfile` (sưu tầm, vĩnh viễn — không có trường tier ở bất kỳ đâu) và `RunState` / `FaceInstance` (tạm thời, sức mạnh sống ở đây, huỷ khi run kết thúc). Khoá thật của mọi part là `partId`, không phải `name` — có 7 tên part trùng hợp lệ giữa các slot khác nhau (VD `Anemone` tồn tại ở cả Aqua·Horn và Aqua·Back).

**Thứ tự triển khai Phase 1** (M0 → M7): nạp dữ liệu part → bậc trong run → bộ sưu tập → Forge + Lead → Mastery → **chạy sim để xác nhận toàn bộ đường cong (mốc chặn ship)** → monetization → Gauntlet.

---

## 12. Phạm vi

### Phase 1 (Web, 3 tháng, ngân sách launch 8-12 person-week)

Bộ sưu tập part + Gene Shard · 4 bậc rarity trong run · Axie Forge có ràng buộc · 1 slot Lead Axie · Mastery (3/4 mốc) + Pin · cơ chế Declare combo · Season 0 Battle Pass · ~15 SKU cosmetic · Gauntlet v1 + Daily Seed · server save + replay-verify.

### Phase 2 (tháng 4-9)

Mobile · bậc Mythic (36 hiệu ứng) · lớp NFT (mở part qua sở hữu Axie thật, không cấp sức mạnh) · slot Lead thứ hai · secret class Dusk/Mech/Dawn · Mastery mốc cuối · nhịp season 6 tuần · Gauntlet Tournament (nếu legal thông qua).

**Không có trong Phase 1, không có ngoại lệ:** NFT · mobile · slot Lead thứ ba (không bao giờ) · bậc Mythic · bán skin Mystic (không bao giờ, ở phase nào cũng vậy) · CHAIN/COMBO kiểu Origins gốc (đã gác lại, thay bằng Declare) · Battle Pass/Guild/Leaderboard thời gian thực.

---

## 13. Rủi ro & câu hỏi còn mở

**Rủi ro cao nhất, chưa có lời giải hoàn chỉnh:**

- **Cognitive load.** 192 part × 4 bậc ≈ 768 cấu hình mặt có tên riêng, cho một game gán xúc xắc. Đây là rủi ro có thể giết game **cao hơn** rủi ro pháp lý về IP, vì nó để dự án ship ra rồi mới chết thay vì chặn từ đầu. Giảm nhẹ bằng: 60 part khởi đầu, giới thiệu bloodline theo lớp, hiển thị bậc bằng màu viền thay vì chữ, và **playtest legibility phải là tiêu chí ship, không phải nice-to-have.**
- **IP bên thứ ba lẫn trong tên Mystic part.** Hasagi = Yasuo (Riot), Namek Carrot = Dragon Ball. Cần legal review riêng, không gộp chung với xin duyệt IP Axie nội bộ.
- **Quyền dùng tên + art part Axie** — đã được chấp thuận nội bộ, nhưng vẫn là giả định nền của toàn bộ chiến lược content, cần văn bản chính thức trước khi build sâu thêm.

**Bốn câu hỏi cần simulation để trả lời, không phải để tranh luận:**

| # | Câu hỏi | Chặn gì |
|---|---|---|
| S1 | Slot Lead Axie đáng giá bao nhiêu winrate? | Trần 2 slot |
| S2 | Nở lệch archetype trong bộ sưu tập có biến thành sức mạnh không? | Độ hào phóng của Collector Bundle |
| S3 | Sau 192 part + toàn bộ mốc Mastery, Gene Shard tiêu vào đâu? | Ship Phase 1 |
| S4 | Hiệu chuẩn faucet/sink | Ship Phase 1 |

---

## Phụ lục — nguồn

Doc này tổng hợp từ: `AUDIT_AND_SPEC_v1.md` (engine, combat, độ khó) · `ECONOMY_AND_PROGRESSION_v2.md` (kinh tế, meta) · `BLOODLINE_SYSTEM_v1.md` (part → die, bản sắc class, Mythic) · `PART_TIER_SYSTEM.md` (pipeline dữ liệu, quy đổi bậc) · `COMBO_DECISION_MEMO.md` (Declare mechanic) · `BUILD_SPEC_v1.md` (contract triển khai, invariant) · `UI_DESIGN_SYSTEM_v0.8.md` · `QA_AND_BUGFIXES_v0.7.md` · GDD gốc (`GDD - Axie Dice Tactics_ Lunacia Mutants.docx`).

Mọi quyết định "đã chốt" trong doc gốc được ghi lại đúng nguyên trạng; phần suy diễn/tổng hợp khi ghép các doc lại là của bản tóm tắt này — khi có mâu thuẫn, doc gốc (`BUILD_SPEC_v1.md` §1 và §8) là contract cuối cùng.
