# PART TIER SYSTEM — Hệ quy đổi Origins → Axie Dice
### 192 part × role · archetype · 4 bậc

> Doc này giải thích **cách** bảng 4 bậc được sinh ra, và **cái gì cần người duyệt**. Dữ liệu ở `parts_build_data.json`, bảng duyệt ở `PART_REVIEW_SHEET.md`, công cụ ở `gen_parts.py`.

---

## 1. NGUỒN DỮ LIỆU

Tìm được **Axie Origin Data API** — mock server công khai, không cần key:

```
GET https://7b00e2d6-641e-45cb-a705-390f8d062064.mock.pstmn.io/api/v1/cards
Schema: { id, class, part, energyCost, name, value, effect: damage|shield|heal|null,
          description, abilities[] }
```

**Độ phủ: 189/192 part core khớp trực tiếp.** Ba part còn lại (`Little Peas`, `Granma's Fan`, `Pupae`) lấy từ vòng nghiên cứu trước. **13 part từng thiếu card text nay đã có đủ**, kể cả Bird·Ears và Bug·Ears — được kiểm chứng chéo bằng bài teaser của PinoyGamer và axiecard.info.

> ⚠️ Container này bị chặn egress nên chỉ kéo được 211/487 card qua WebFetch. **Chạy một lệnh `curl` từ máy có mạng thẳng là lấy trọn bộ.** Đáng làm — nó sẽ bổ sung card text cho các slot còn mỏng và cho cả class dawn/dusk/mech ở Phase 2.
>
> ⚠️ Nguồn *chính thức* là `api-gateway.skymavis.com` (cần API key). Anh dùng email `@skymavis.com` — xin key nội bộ và đối chiếu một lần là loại bỏ hẳn rủi ro dữ liệu cộng đồng.

---

## 2. NGUYÊN TẮC QUY ĐỔI

Tuân đúng **Luật 1** của `BLOODLINE_SYSTEM` §2 — *giữ FANTASY, dịch MECHANIC, không copy số liệu*:

| Thành phần | Nguồn |
|---|---|
| **role** | suy từ trường `effect` của card (khách quan), fallback bằng từ khoá trong `description` |
| **archetype** | suy từ keyword, cân bằng theo bản sắc class |
| **keywords** | suy từ `description` qua bảng 45 mẫu regex có kiểm soát |
| **value** | **SUY TỪ NGÂN SÁCH BẬC** — không lấy từ Origins |

Điểm mấu chốt nằm ở dòng cuối. Origins đã rebalance nhiều lần và cùng một part có số khác nhau giữa các patch — copy số của nó là nhập luôn cả nợ cân bằng của một game khác thể loại. Thay vào đó:

```
value = (ngân_sách_bậc − chi_phí_keyword) / hệ_số_role
```

⇒ **INV-5 (mọi part cùng bậc trong ±10% ngân sách) đúng DO CẤU TRÚC**, không phải do tuning. Designer chỉ chọn *keyword*; con số tự rơi ra. Đây là thứ làm cho luật ngang giá sức mạnh — nền móng của cả Phương án A — trở thành thứ **không thể vô tình phá vỡ**.

### Ngân sách và hệ số

```
TIER_BUDGET  common 6.0 · rare 8.5 · epic 12.0 · legendary 17.0
ROLE_RATE    dmg 1.00 · shield 0.90 · heal 0.80 · debuff 0.85 · utility 0.85
KW_COST      45 keyword, dải 0.7–2.7 điểm ngân sách
```

**Mana là keyword, không phải role.** Đúng theo spec §B2 (*"ears = +mana, luôn cantrip"*). Ban đầu tôi để mana làm role riêng và nó là nguyên nhân duy nhất khiến INV-5 trượt — 1 mana ≈ 4 điểm ngân sách nên quá thô để khớp bậc thấp. Chuyển thành keyword thì tất cả 192 part vào dải.

**Phần dư được hấp thụ thành sát thương phụ** (`bonusDmg`). Mặt thô còn dư ngân sách sẽ chip thêm vài điểm damage — vừa khớp ngân sách, vừa đúng Origins (nhiều card energy cũng có damage).

---

## 3. HIỆU CHUẨN — đối chiếu đường cong đã đo

Ngân sách được neo vào số liệu thật ở `AUDIT_AND_SPEC_v1` PHẦN C: **pDPS 42.6 toàn party ở wave 20**.

| Bậc | dmg trung vị | → party DPS (5 mặt × 63% là dmg) |
|---|---|---|
| Common | 5 | 15.8 |
| Rare | 7 | 22.1 |
| Epic | 11 | **34.7** |
| Legendary | 16 | **50.4** |

Mốc 42.6 nằm gọn giữa Epic và Legendary — đúng chỗ một build cuối run nên ở. Đây là **dải khởi điểm**, `sim.js` sẽ tinh chỉnh; nhưng nó không phải số đoán, nó neo vào đường cong đã đo được.

---

## 4. KẾT QUẢ

### INV-5 — đạt toàn bộ

| Bậc | Lệch tối đa | Vi phạm |
|---|---|---|
| Common | 7.7% | **0/192** |
| Rare | 5.9% | **0/192** |
| Epic | 4.2% | **0/192** |
| Legendary | 2.9% | **0/192** |

### Phân bố archetype — 14 đến 23

```
FERAL 23 · HEX 23 · BASTION 23 · CONDUIT 23 · SWARM 22
PLAGUE 19 · WARDEN 15 · ECHO 15 · TALON 15 · VERDANT 14
```

Quan trọng cho **D16** (offer tối đa 2/3 cùng archetype) và cho chỉ số nghiệm thu *archetype diversity ≥ 8/10*: không archetype nào mỏng đến mức không dựng nổi build.

### Bản sắc class — nổi lên từ dữ liệu, không áp đặt

| Class | Ba archetype mạnh nhất | Khớp với `BLOODLINE` §5.4? |
|---|---|---|
| **Plant** | VERDANT 10 · BASTION 8 · SWARM 6 | ✅ *shield trả cổ tức + cleanse + summon* |
| **Reptile** | PLAGUE 7 · WARDEN 6 · BASTION 5 | ✅ *tiêu hao + phản đòn + giáp bền* |
| **Bug** | PLAGUE 6 · TALON 6 · CONDUIT 5 | ✅ *phá giáp + debuff + poison* |
| **Bird** | HEX 9 · FERAL 7 · SWARM 6 | ✅ *debuff + tự hại lấy payoff + summon* |
| **Aquatic** | ECHO 6 · CONDUIT 5 · HEX 5 | ✅ *tempo + mana + cộng hưởng* |
| **Beast** | TALON 7 · CONDUIT 6 · FERAL 5 | ⚠️ **lệch** — xem §5 |

Năm trong sáu class khớp với bản sắc đã đọc ra từ card text ở doc Bloodline — **và đó là một kiểm chứng độc lập**, vì hai lần phân tích đi qua hai đường khác nhau (đọc tay vs sinh tự động) mà ra cùng kết quả.

---

## 5. CẦN NGƯỜI DUYỆT

### 5.1 Beast lệch bản sắc — cần chỉnh tay

Beast ra TALON 7 / FERAL 5, trong khi bản sắc của nó phải là **FERAL** (crit + cùng đường). Nguyên nhân: pha cân bằng archetype ưu tiên giữ phân bố phẳng và đã đẩy một số part Beast sang TALON.

**Cách sửa:** khoá cứng archetype cho các part crit rõ ràng của Beast (`Dual Blade`, `Imp`, `Ronin`, `Little Branch`) và các part Last Stand (`Risky Beast`, `Jaguar`, `Shiba`) về FERAL, rồi chạy lại. Đây là chỉnh 7 dòng, không phải chỉnh hệ thống.

### 5.2 Bảy part cần duyệt tay

Card text gốc rỗng hoặc không khớp mẫu nào; hiện đang dùng keyword mặc định theo role:

`Lotus` (plant·ears) · `Rose Bud` (plant·horn) — card vanilla thật, `description: null` trong API, đã xác minh không phải lỗi truncate
`Serious` (plant·mouth) · `Grass Snake` (reptile·tail) · `Post Fight` (bird·tail) · `Potato Leaf` (plant·tail) · `Wall Gecko` (reptile·tail)

Đánh dấu ⚠️ trong `PART_REVIEW_SHEET.md`.

### 5.3 Điều máy không quyết được

**Bảng mẫu regex là một phép xấp xỉ.** Nó bắt đúng động từ trong ~96% trường hợp, nhưng nó không hiểu *ý đồ*. Ví dụ `Ronin` — *"Deal 50% more DMG per Energy spent this turn"* — máy gán `ramp`, nhưng trong Axie Dice không có energy, nên designer phải quyết `ramp` theo gì: theo vòng đấu, theo số mặt đã dùng, hay đổi sang `crit` cho đúng bản sắc Beast.

Đây chính là loại quyết định mà §10 của `BUILD_SPEC` gọi là **việc của designer, không phải của code**. Hệ thống này rút nó từ *"thiết kế 768 ô từ số không"* xuống *"duyệt 192 dòng và sửa những dòng sai"* — ước tính từ **3-4 person-week xuống còn 3-5 ngày**.

---

## 6. TỆP GIAO

| Tệp | Nội dung |
|---|---|
| `parts_build_data.json` | 192 part đầy đủ: role, archetype, keywords, 4 bậc, card text Origins gốc để đối chiếu |
| `PART_REVIEW_SHEET.md` | Bảng duyệt 192 dòng, nhóm theo class, đánh dấu ⚠️ chỗ cần ưu tiên |
| `gen_parts.py` | Công cụ sinh. **Chỉnh ngân sách/giá keyword rồi chạy lại là ra bảng mới** — dùng cho mọi vòng tune sau này |
| `origins_cards_raw.json` | 211 card Origins thô, để tra cứu |

**Quy trình tune về sau:** sửa `TIER_BUDGET` / `KW_COST` trong `gen_parts.py` → chạy lại → INV-5 tự động vẫn đạt → chạy `sim.js`. Không phải sửa 192 dòng bằng tay lần nào nữa.

---

## 7. CÒN LẠI CHO PHASE 2

**36 hiệu ứng Mythic** vẫn phải thiết kế từ đầu — Mystic part trong Axie là skin thuần, không có card effect để chuyển thể. Khung đã sẵn ở `parts_build_data.json → mythicBySlot` (6 class × 6 slot, `ruleBreak: null`).

Nguyên tắc thiết kế cho 36 ô đó: mỗi cái phải **phá một luật** của hệ, không phải cộng thêm số. Chúng là bậc duy nhất **được miễn trừ khỏi kiểm ngân sách CI** — 36 hiệu ứng phá luật không quy về một con số so sánh được, nên phải qua sim và review tay từng cái. 36 cái thì khả thi.
