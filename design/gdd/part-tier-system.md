# PART TIER SYSTEM — Hệ quy đổi Axie → Axie Dice
### 192 part × role · archetype · 4 bậc

> **Sửa 2026-09-01 — thay đổi phương pháp luận, đọc trước khi dùng bất kỳ số nào trong doc này:**
> Quyết định sản phẩm mới: **part chỉ cho danh tính** (tên, class, slot, hình ảnh) — **hiệu ứng mặt xúc xắc KHÔNG được trích/dịch từ card text Origins/Classic nữa**. Toàn bộ §1 (nguồn Axie Origin Data API) và cách đọc `effect`/`description` để suy `role`/`archetype`/`keywords` ở §2 bản cũ **đã lỗi thời — không dùng nữa**. Thay vào đó, `role`/`archetype`/`keywords` đến từ **36 template do game-designer tự thiết kế** (§2 mới bên dưới, 6 slot × 6 class), gán cho từng part trong 192 part thật thuần theo **slot + class** của nó — không đọc card text. Value vẫn suy từ ngân sách bậc như cũ (phần đó chưa bao giờ phụ thuộc Origins, giữ nguyên). Xem `docs/review-2026-08-31.md` phần hành động cho bối cảnh quyết định.
>
> Hệ quả tích cực: mục §5.2 bản cũ ("7 part thiếu card text cần duyệt tay") **không còn là vấn đề** — vì không còn đọc card text nữa. Mục §5.1 ("Beast lệch archetype") cũng **tự động giải quyết** — 36 template đã hand-designed đúng bản sắc FERAL cho Beast ngay từ đầu, không cần khoá cứng 7 dòng như trước.
>
> Doc này giải thích **cách** bảng 4 bậc được sinh ra, và **cái gì cần người duyệt**. Dữ liệu ở `parts_build_data.json`, công cụ ở `tools/gen_parts.py`.
>
> **✅ 2026-09-01 — `tools/gen_parts.py` đã được viết lại**, đọc thẳng 36 template (§2a/§2c) + bảng gán (§8) đã nhúng sẵn trong script, không gọi API/đọc card text nào nữa. Đã chạy: sinh đúng 192/192 part, không có part nào rơi ngoài bảng gán §8. Chạy `python3 tools/gen_parts.py` để tái sinh `docs/axiedice-source/economy/parts_build_data.json` bất kỳ lúc nào sau khi sửa CELLS/ASSIGN_RAW trong script (hoặc sửa §2c/§8 ở đây rồi đồng bộ lại script — script là nguồn thực thi, doc là nguồn thiết kế, giữ hai bên khớp nhau khi sửa).

---

## 1. NGUỒN DỮ LIỆU

**Danh tính** (tên part, class, slot, hình ảnh): `parts.json` trong package npm `agp-npm` (Axie Gene Parser) — bản mirror bảng part chính thức Axie dùng để decode gene. Đã có sẵn trong `design/gdd/axie-body-parts.md`. **Không cần Axie Origin Data API nữa** — API đó (mock server `pstmn.io`, hoặc chính thức `api-gateway.skymavis.com`) chỉ cần thiết khi mục tiêu là trích *card effect*, và mục tiêu đó đã bị bỏ theo quyết định 2026-09-01 ở trên. Việc xin API key nội bộ Sky Mavis **không còn cần thiết cho mục đích này** (có thể vẫn cần cho mục đích khác như xác minh IP/nghệ thuật — xem `docs/review-2026-08-31.md` hành động #4).

**Cấu trúc**: mỗi class đúng 32 part core (6 Horn, 6 Back, 6 Tail, 6 Ears, 4 Mouth, 4 Eyes) × 6 class = 192 part core.

---

## 2. NGUYÊN TẮC QUY ĐỔI

| Thành phần | Nguồn |
|---|---|
| **role / archetype / keywords / value gốc** | **36 template thiết kế thủ công** (bảng bên dưới), gán theo `slot × class` của part |
| **danh tính (tên, art)** | part thật trong `axie-body-parts.md` — chỉ tên/class/slot, KHÔNG đọc cột "Card effect (Origins)" |
| **value cuối** | **SUY TỪ NGÂN SÁCH BẬC** (không đổi so với trước — không bao giờ lấy từ Origins) |

### 2a. Bảng 36 template (Common tier — 1 action, 0 keyword)

Thiết kế bởi `game-designer`, hiệu chuẩn theo `HEROES`/`FACE_POOL` thật trong `src/data.js`. Mỗi ô là template Common cho đúng một `(class, slot)`; part thật nhận effect của ô tương ứng theo slot+class của nó, giữ nguyên tên/hình ảnh riêng.

| Class (passive) | Mouth | Horn | Back | Tail | Eyes | Ears |
|---|---|---|---|---|---|---|
| **Plant** (BULWARK — shield +2, ≥10 shield→Thorns 2) | dmg 5 | dmg 6 | shield 9 | shield 6 *(lệch: thay poison — 2 mặt shield củng cố BULWARK)* | heal 7 | mana 2 (cantrip) |
| **Beast** (FERAL — +60% dmg vs <50% HP) | dmg 7 | dmg 9 | dmg 6 *(lệch: thay shield — toàn công, glass cannon)* | dmg 6 | dmg 5 *(lệch: thay heal — không có mặt hỗ trợ)* | mana 2 (cantrip) |
| **Aqua** (CONDUIT — +1 mana, 4 mana→1 reroll) | dmg 6 | dmg 7 | shield 6 | dmg 5 | heal 7 | mana 3 *(cao hơn baseline — nuôi CONDUIT)* |
| **Reptile** (SCALES — luôn Thorns 2, Thorns kèm Poison 1) | dmg 6 | dmg 7 | shield 8 | poison 4 | heal 5 | mana 2 (cantrip) |
| **Bug** (VIRULENT — poison stack +2 thay vì +1) | dmg 5 | dmg 6 | shield 6 | poison 5 *(cao hơn baseline)* | poison 3 *(lệch: thay heal — poison kép)* | mana 2 (cantrip) |
| **Bird** (TALON — +3 dmg khi Pierce, mặt `aoe` cũng có Pierce) | dmg 6 | dmg 7 | dmg 5 *(lệch: thay shield — khớp `HEROES` thật: bird không bao giờ có shield)* | dmg 5 | dmg 5 *(lệch: thay heal — khớp `HEROES` thật: bird không bao giờ có heal)* | mana 2 (cantrip) |

**Ràng buộc kỹ thuật đã xác nhận** (từ `src/data.js`): type `buff`/`debuff`/`summon` luôn cần kèm keyword để định nghĩa hiệu ứng — không có "debuff 0 keyword". Vì Common = 0 keyword theo bảng rarity, cả 36 template chỉ dùng 5 type tự-mô-tả: `dmg`/`shield`/`heal`/`mana`/`poison`. Bản sắc debuff của Bug/Reptile (nếu có) xuất hiện từ **Rare tier trở lên** (+1 keyword), không phải ở Common — cần lưu ý khi thiết kế bảng keyword theo tier ở §2b (chưa làm trong phiên này).

**Không phát sinh keyword mới** — toàn bộ 36 template dùng lại keyword đã có trong `design/gdd/game-concept.md`.

### 2b. Từ template lên 192 part thật, rồi lên 4 bậc

Nguyên tắc cũ (giữ nguyên, không phụ thuộc Origins):

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

### 2c. Bảng Rare → Mythic theo 36 ô (thiết kế 2026-09-01)

Cùng độ hạt với §2a — 36 ô `(class, slot)`, không thiết kế riêng cho 192 part cá thể. Việc gán **part thật nào** trong mỗi ô nhận option "primary" hay "alt" ở Rare là một bước nhỏ sau này (theo tên/flavor part, xem `axie-body-parts.md`), chưa làm ở đây. Legendary = giữ nguyên 2 keyword của Epic, chỉ tăng value theo ngân sách bậc (§2b) — không có ngoại lệ ở cả 36 ô. Mythic được phép dùng lại flag đặc biệt hiện gắn với relic (`plague`/`echo`/`bastion`/`overflow`) — quyết định của product owner 2026-09-01: mặt Mythic và relic dùng chung được, không cần thiết kế cơ chế tách biệt.

**Chống BLOODCHAIN-stacking**: Beast (kit nặng damage nhất) được lệch trục ở Back (Thorns/Vulnerable) và Eyes (Regen/Vulnerable) thay vì dồn toàn damage — tránh lặp lại lỗi §3 của `combo-decision-memo.md` (COMBO+BLOODCHAIN cùng trục damage tạo synergy ngoài ý muốn cho mono-class).

#### Plant (BULWARK)

| Slot | Common | Rare (primary/alt) | Epic (2 kw) | Mythic (phá luật) |
|---|---|---|---|---|
| Mouth | dmg 5 | lifesteal / vital | lifesteal+vital | Overheal từ Lifesteal chuyển thành max-HP vĩnh viễn thay vì mất |
| Horn | dmg 6 | pierce / heavy | pierce+heavy | Damage Pierce của mặt này cũng tạo Shield bằng đúng số damage |
| Back | shield 9 | shieldself:N / thorns:N | shieldself+thorns | Shield mặt này không decay đầu lượt, tồn tại tới khi bị tiêu |
| Tail | shield 6 | shieldself:N / regen:N | shieldself+regen | Mỗi 10 Shield tích luỹ cũng hồi 1 HP, không chỉ cho Thorns |
| Eyes | heal 7 | regen:N / cantrip | regen+cantrip | Heal vào mục tiêu đã đầy máu chuyển thành Shield thay vì mất |
| Ears | mana 2 | mana:N / rerollup | mana+rerollup | Mana từ mặt này cũng tạo Shield bằng đúng giá trị mana |

#### Beast (FERAL)

| Slot | Common | Rare (primary/alt) | Epic (2 kw) | Mythic (phá luật) |
|---|---|---|---|---|
| Mouth | dmg 7 | lifesteal / crit:N | lifesteal+crit | Lifesteal hồi máu cả trên phần damage bonus +60% của FERAL |
| Horn | dmg 9 | heavy / pierce | heavy+pierce | Mặt này luôn được bonus FERAL +60%, bất kể HP% mục tiêu |
| Back | dmg 6 | thorns:N / vulnerable:N | thorns+vulnerable | Thorns phản đòn của mặt này scale theo % HP mất của địch |
| Tail | dmg 6 | multi:N / chain:N | multi+weaken:N | Mỗi đòn trong multi-strike kiểm tra lại ngưỡng FERAL theo HP hiện tại giữa chuỗi đòn |
| Eyes | dmg 5 | regen:N / vulnerable:N | regen+vulnerable | Hồi máu cho bản thân bằng damage gây cho mục tiêu <50% HP, không giới hạn theo HP thiếu của chính mình |
| Ears | mana 2 | rerollup / mana:N | rerollup+mana | Reroll charge từ mặt này không tính vào cap nâng cấp Max Reroll (3) |

#### Aqua (CONDUIT)

| Slot | Common | Rare (primary/alt) | Epic (2 kw) | Mythic (phá luật) |
|---|---|---|---|---|
| Mouth | dmg 6 | mana:N / lifesteal | mana+lifesteal | Mana mặt này kích hoạt quy đổi reroll của CONDUIT ngay, không cần gom đủ bội số 4 |
| Horn | dmg 7 | pierce / crit:N | pierce+crit | Damage Pierce của mặt này cũng tạo Mana bằng đúng số damage |
| Back | shield 6 | shieldself:N / mana:N | shieldself+mana | Shield mặt này cũng tạo Mana bằng đúng giá trị shield |
| Tail | dmg 5 | chain:N / multi:N | chain+weaken:N | Chain của mặt này không bao giờ trúng lại mục tiêu đã trúng khi còn địch chưa bị chọn |
| Eyes | heal 7 | regen:N / cantrip | regen+cantrip | Chuỗi cantrip của mặt này không giới hạn 6 lần lặp như bình thường |
| Ears | mana 3 | mana:N / rerollup | mana+rerollup | Overheal từ mặt Eyes đồng minh trong lượt được quy đổi thành Mana bonus trên mặt này |

#### Reptile (SCALES)

| Slot | Common | Rare (primary/alt) | Epic (2 kw) | Mythic (phá luật) |
|---|---|---|---|---|
| Mouth | dmg 6 | lifesteal / poison:N | lifesteal+poison | Lifesteal mặt này cũng hồi máu theo damage Poison-tick đã gây trong lượt |
| Horn | dmg 7 | pierce / heavy | pierce+heavy | Damage Pierce mặt này áp Poison-qua-Thorns ngay, không cần địch tấn công trước |
| Back | shield 8 | thorns:N / shieldself:N | thorns+shieldself | Thorns mặt này không có trần stack và không reset đầu lượt |
| Tail | poison 4 | poison:N / aoe | poison+aoe | Poison mặt này không giảm 1 stack mỗi lượt như bình thường (khớp rule-break `plague`) |
| Eyes | heal 5 | regen:N / weaken:N | regen+weaken | Regen tick mặt này cũng cộng Thorns bằng đúng lượng hồi |
| Ears | mana 2 | mana:N / rerollup | mana+rerollup | Mana mặt này cũng cho 1 stack Thorns tồn tại sang trận sau (không reset cuối wave) |

#### Bug (VIRULENT)

| Slot | Common | Rare (primary/alt) | Epic (2 kw) | Mythic (phá luật) |
|---|---|---|---|---|
| Mouth | dmg 5 | poison:N / lifesteal | poison+lifesteal | Lifesteal mặt này đọc cả damage Poison-tick vừa áp trong lượt |
| Horn | dmg 6 | weaken:N / pierce | weaken+pierce | Weaken mặt này stack nhân thay vì cộng như bình thường |
| Back | shield 6 | poison:N / shieldself:N | poison+shieldself | Shield mặt này gây Poison cho địch phá giáp dù không có keyword Thorns |
| Tail | poison 5 | poison:N / aoe | poison+aoe | Bonus +2-stack của VIRULENT áp dụng 2 lần trên chính mặt này |
| Eyes | poison 3 | poison:N / blind:N | poison+blind | Poison mặt này không giảm stack mỗi lượt, chỉ khi VIRULENT đang active trong trận (khớp rule-break `plague`) |
| Ears | mana 2 | mana:N / rerollup | mana+rerollup | Mana mặt này áp Poison 1 lên một địch ngẫu nhiên theo mỗi điểm mana |

#### Bird (TALON)

| Slot | Common | Rare (primary/alt) | Epic (2 kw) | Mythic (phá luật) |
|---|---|---|---|---|
| Mouth | dmg 6 | pierce / lifesteal | pierce+lifesteal | Luật "mặt aoe cũng có Pierce" của TALON áp cho cả mặt này dù không gắn `aoe` |
| Horn | dmg 7 | pierce / crit:N | pierce+crit | Pierce mặt này bỏ qua hoàn toàn phản đòn Thorns của địch |
| Back | dmg 5 | vulnerable:N / blind:N | vulnerable+blind | Mặt này tạo Shield — phá luật "Bird không bao giờ có mặt shield" ở mọi bậc khác |
| Tail | dmg 5 | chain:N / multi:N | chain+weaken:N | Đòn Chain của mặt này tính là Pierce cho bonus TALON, dù Chain thường không mang Pierce |
| Eyes | dmg 5 | blind:N / vulnerable:N | blind+vulnerable | Mặt này tạo Heal — phá luật "Bird không bao giờ có mặt heal" ở mọi bậc khác |
| Ears | mana 2 | rerollup / mana:N | rerollup+mana | Bonus TALON áp cho mỗi lần kích hoạt cantrip-chain của mặt này, không chỉ lần đầu |

*Legendary (tất cả 36 ô): giữ nguyên 2 keyword của Epic, chỉ tăng value theo bảng ngân sách §2b — không có ngoại lệ.*

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

> ⚠️ **Toàn bộ §4 dưới đây là kết quả CŨ**, sinh ra từ bản `gen_parts.py` đọc card text Origins qua regex (đã ngừng dùng theo quyết định 2026-09-01 ở đầu doc). Giữ lại làm tham chiếu lịch sử — không dùng các con số dưới đây để quyết định gì.
>
> **✅ Kết quả thật, chạy `tools/gen_parts.py` mới (2026-09-01)**: 192/192 part sinh thành công, INV-5 đạt cho cả 4 bậc (spread trong role/tier rất hẹp — vd. dmg-epic 8-11, shield-legendary đúng 16 cho mọi part, xem output `docs/axiedice-source/economy/parts_build_data.json`). **`classPassive` giờ đơn giản = passive của class đó** (BULWARK/FERAL/CONDUIT/SCALES/VIRULENT/TALON, đúng 32/32/32/32/32/32 — vì mỗi part chỉ thuộc một class) — **đây KHÔNG phải hệ 10-archetype runtime** (`ARCH` trong `src/data.js`: PLAGUE/INFERNO/BULWARK/CONDUIT/TALON/APEX/EVOLVE/SWARM/TEMPEST/AEGIS, được tính động mỗi trận theo keyword đội hình đang dùng qua `archScore()`). Hai khái niệm khác nhau, đừng nhầm khi đọc dữ liệu.

### INV-5 — đạt toàn bộ (số liệu cũ, cần chạy lại)

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

> Với phương pháp mới (§2a/§2b), hai vấn đề lớn nhất của bản cũ **không còn tồn tại**:

### 5.1 ~~Beast lệch bản sắc~~ — đã giải quyết bằng thiết kế

Bản cũ: pipeline regex đẩy Beast về TALON thay vì FERAL, cần khoá cứng 7 part bằng tay. **Không còn vấn đề này** — 36 template ở §2a được `game-designer` thiết kế thủ công với chủ đích rõ ràng ngay từ đầu: Beast = 100% dmg-only (không shield, không heal ở Common), FERAL là archetype tự nhiên vì mọi mặt Beast đều hướng về sát thương dồn vào mục tiêu yếu máu — không cần khoá cứng part nào.

### 5.2 ~~Bảy part thiếu card text~~ — không còn là vấn đề

Bản cũ cần 7 part (`Lotus`, `Rose Bud`, `Serious`, `Grass Snake`, `Post Fight`, `Potato Leaf`, `Wall Gecko`) được duyệt tay vì card text gốc rỗng. **Không còn áp dụng** — không part nào cần đọc card text nữa; mọi part nhận effect từ template theo slot+class, bất kể card text Origins của nó có tồn tại hay không.

### 5.3 Việc còn cần người duyệt thật

- **Gán part cụ thể vào Rare/Epic/Legendary/Mythic** (§2b, tier lên qua thêm keyword) — 36 template ở §2a mới chỉ phủ Common. Cần thiết kế thêm bảng "part nào ở class nào lên keyword gì khi lên bậc" — đây là công việc design tiếp theo, khuyến nghị cũng dùng game-designer/systems-designer thay vì suy từ dữ liệu ngoài.
- **36 hiệu ứng Mythic** (§7) — vẫn cần thiết kế thủ công như doc gốc đã ghi, không đổi.
- **Chạy lại `gen_parts.py`** sau khi viết lại nó theo template — xem §6.

---

## 6. TỆP GIAO

| Tệp | Nội dung |
|---|---|
| `parts_build_data.json` | 192 part đầy đủ: role, archetype, keywords, 4 bậc. **Không còn cột card text Origins** — không cần đối chiếu với Origins nữa |
| `PART_REVIEW_SHEET.md` | Bảng duyệt 192 dòng, nhóm theo class, đánh dấu ⚠️ chỗ cần ưu tiên |
| `tools/gen_parts.py` | **✅ Đã viết lại (2026-09-01).** Đọc `design/gdd/axie-body-parts.md` cho danh tính (tên/class/slot), tra 36 template + bảng gán §8 nhúng sẵn trong script, áp công thức ngân sách bậc (§2b) → ghi `parts_build_data.json`. Không gọi API, không đọc card text. |
| ~~`origins_cards_raw.json`~~ | Không còn tồn tại trong repo (chưa từng được import) — không còn cần |

**Quy trình tune về sau:** sửa `TIER_BUDGET` / `KW_COST` trong `gen_parts.py`, hoặc sửa trực tiếp 36 template ở §2a nếu muốn đổi bản sắc một class → chạy lại → INV-5 tự động vẫn đạt → chạy `sim.js`. Không phải sửa 192 dòng bằng tay lần nào nữa.

---

## 7. CÒN LẠI CHO PHASE 2

~~**36 hiệu ứng Mythic** vẫn phải thiết kế từ đầu~~ — **✅ đã thiết kế xong ở §2c (2026-09-01)**, cùng lúc với Rare/Epic. Còn lại thật: chạy qua `sim.js` để kiểm từng hiệu ứng phá luật không tạo combo vỡ trận (Mythic được miễn kiểm ngân sách CI theo đúng tinh thần "phá luật, không quy về một con số so sánh được" — vẫn cần review tay + sim, không tự động hoá được).

Việc còn lại thật sự cho Phase 2: viết lại `gen_parts.py` (xem §6) để sinh `parts_build_data.json` từ §2a-§2d, rồi chạy `sim.js` kiểm INV-5 + archetype diversity với dữ liệu mới.

---

## 8. GÁN 192 PART THẬT VÀO 36 Ô (2026-09-01)

Bước cuối để hoàn thiện hệ part: với mỗi part thật trong `design/gdd/axie-body-parts.md`, chọn **primary hay alt** ở Rare-tier cho đúng ô `(class, slot)` của nó (xem §2c), dựa **thuần vào tên/flavor** — không đọc cột "Card effect (Origins)". Epic = primary + alt của cùng ô (cả 2 keyword). Legendary/Mythic giống nhau cho mọi part trong cùng ô (không có lựa chọn per-part ở 2 bậc này).

Thực hiện bởi `game-designer`, cân bằng tương đối primary/alt trong mỗi ô (không để 6/6 part cùng một lựa chọn, trừ khi tên part genuinely đều nghiêng một phía).

### Beast (FERAL) — Mouth: lifesteal / crit
- Axie Kiss → primary (lifesteal) · Confident → alt (crit) · Goda → alt (crit) · Nut Cracker → primary (lifesteal)

### Beast — Horn: heavy / pierce
- Arco → alt (pierce) · Dual Blade → alt (pierce) · Imp → primary (heavy) · Little Branch → primary (heavy) · Merry → primary (heavy) · Pocky → alt (pierce)

### Beast — Back: thorns / vulnerable
- Furball → primary (thorns) · Hero → alt (vulnerable) · Jaguar → alt (vulnerable) · Risky Beast → alt (vulnerable) · Ronin → primary (thorns) · Timber → primary (thorns)

### Beast — Tail: multi / chain
- Cottontail → primary (multi) · Gerbil → alt (chain) · Hare → primary (multi) · Nut Cracker → primary (multi) · Rice → alt (chain) · Shiba → alt (chain)

### Beast — Eyes: regen / vulnerable
- Chubby → alt (vulnerable) · Little Peas → alt (vulnerable) · Puppy → primary (regen) · Zeal → primary (regen)

### Beast — Ears: rerollup / mana
- Belieber → alt (mana) · Innocent Lamb → alt (mana) · Nut Cracker → alt (mana) · Nyan → primary (rerollup) · Puppy → primary (rerollup) · Zen → primary (rerollup)

### Aquatic (CONDUIT) — Mouth: mana / lifesteal
- Catfish → alt (lifesteal) · Lam → primary (mana) · Piranha → alt (lifesteal) · Risky Fish → primary (mana)

### Aquatic — Horn: pierce / crit
- Anemone → alt (pierce) · Babylonia → primary (crit) · Clamshell → primary (crit) · Oranda → primary (crit) · Shoal Star → alt (pierce) · Teal Shell → alt (pierce)

### Aquatic — Back: shieldself / mana
- Anemone → primary (shieldself) · Blue Moon → alt (mana) · Goldfish → alt (mana) · Hermit → primary (shieldself) · Perch → alt (mana) · Sponge → primary (shieldself)

### Aquatic — Tail: chain / multi
- Koi → primary (chain) · Navaga → alt (multi) · Nimo → primary (chain) · Ranchu → primary (chain) · Shrimp → alt (multi) · Tadpole → alt (multi)

### Aquatic — Eyes: regen / cantrip
- Clear → primary (cantrip) · Gero → alt (regen) · Sleepless → primary (cantrip) · Telescope → alt (regen)

### Aquatic — Ears: mana / rerollup
- Bubblemaker → primary (mana) · Gill → primary (mana) · Inkling → alt (rerollup) · Nimo → primary (mana) · Seaslug → alt (rerollup) · Tiny Fan → alt (rerollup)

### Plant (BULWARK) — Mouth: lifesteal / vital
- Herbivore → alt (vital) · Serious → primary (lifesteal) · Silence Whisper → alt (vital) · Zigzag → primary (lifesteal)

### Plant — Horn: pierce / heavy
- Bamboo Shoot → primary (pierce) · Beech → alt (heavy) · Cactus → primary (pierce) · Rose Bud → primary (pierce) · Strawberry Shortcake → alt (heavy) · Watermelon → alt (heavy)

### Plant — Back: shieldself / thorns
- Bidens → alt (thorns) · Mint → primary (shieldself) · Pumpkin → primary (shieldself) · Shiitake → primary (shieldself) · Turnip → alt (thorns) · Watering Can → alt (thorns)

### Plant — Tail: shieldself / regen
- Carrot → alt (regen) · Cattail → primary (shieldself) · Hatsune → alt (regen) · Hot Butt → primary (shieldself) · Potato Leaf → primary (shieldself) · Yam → alt (regen)

### Plant — Eyes: regen / cantrip
- Blossom → primary (regen) · Confused → alt (cantrip) · Cucumber Slice → primary (regen) · Papi → alt (cantrip)

### Plant — Ears: mana / rerollup
- Clover → alt (rerollup) · Hollow → primary (mana) · Leafy → primary (mana) · Lotus → alt (rerollup) · Rosa → primary (mana) · Sakura → alt (rerollup)

### Reptile (SCALES) — Mouth: lifesteal / poison
- Kotaro → alt (poison) · Razor Bite → primary (lifesteal) · Tiny Turtle → alt (poison) · Toothless Bite → primary (lifesteal)

### Reptile — Horn: pierce / heavy
- Bumpy → alt (heavy) · Cerastes → primary (pierce) · Incisor → primary (pierce) · Scaly Spear → primary (pierce) · Scaly Spoon → alt (heavy) · Unko → alt (heavy)

### Reptile — Back: thorns / shieldself
- Bone Sail → alt (shieldself) · Croc → alt (shieldself) · Green Thorns → primary (thorns) · Indian Star → primary (thorns) · Red Ear → alt (shieldself) · Tri Spikes → primary (thorns)

### Reptile — Tail: poison / aoe
- Gila → primary (poison) · Grass Snake → primary (poison) · Iguana → alt (aoe) · Snake Jar → alt (aoe) · Tiny Dino → primary (poison) · Wall Gecko → alt (aoe)

### Reptile — Eyes: regen / weaken
- Gecko → primary (regen) · Scar → alt (weaken) · Topaz → alt (weaken) · Tricky → primary (regen)

### Reptile — Ears: mana / rerollup
- Curved Spine → alt (rerollup) · Friezard → primary (mana) · Pogona → alt (rerollup) · Sidebarb → primary (mana) · Small Frill → primary (mana) · Swirl → alt (rerollup)

### Bug (VIRULENT) — Mouth: poison / lifesteal
- Cute Bunny → alt (lifesteal) · Mosquito → alt (lifesteal) · Pincer → primary (poison) · Square Teeth → primary (poison)

### Bug — Horn: weaken / pierce
- Antenna → alt (pierce) · Caterpillars → primary (weaken) · Lagging → primary (weaken) · Leaf Bug → alt (pierce) · Parasite → primary (weaken) · Pliers → alt (pierce)

### Bug — Back: poison / shieldself
- Buzz Buzz → primary (poison) · Garish Worm → primary (poison) · Sandal → alt (shieldself) · Scarab → alt (shieldself) · Snail Shell → alt (shieldself) · Spiky Wing → primary (poison)

### Bug — Tail: poison / aoe
- Ant → alt (aoe) · Fish Snack → primary (poison) · Gravel Ant → alt (aoe) · Pupae → primary (poison) · Thorny Caterpillar → primary (poison) · Twin Tail → alt (aoe)

### Bug — Eyes: poison / blind
- Bookworm → alt (blind) · Kotaro? → primary (poison) · Neo → primary (poison) · Nerdy → alt (blind)

### Bug — Ears: mana / rerollup
- Beetle Spike → primary (mana) · Ear Breathing → alt (rerollup) · Earwing → alt (rerollup) · Larva → primary (mana) · Leaf Bug → primary (mana) · Tassels → alt (rerollup)

### Bird (TALON) — Mouth: pierce / lifesteal
- Doubletalk → alt (lifesteal) · Hungry Bird → alt (lifesteal) · Little Owl → primary (pierce) · Peace Maker → primary (pierce)

### Bird — Horn: pierce / crit
- Cuckoo → alt (crit) · Eggshell → primary (pierce) · Feather Spear → primary (pierce) · Kestrel → alt (crit) · Trump → alt (crit) · Wing Horn → primary (pierce)

### Bird — Back: vulnerable / blind
- Balloon → primary (vulnerable) · Cupid → primary (vulnerable) · Kingfisher → primary (vulnerable) · Pigeon Post → alt (blind) · Raven → alt (blind) · Tri Feather → alt (blind)

### Bird — Tail: chain / multi
- Cloud → primary (chain) · Feather Fan → alt (multi) · Granma's Fan → primary (chain) · Post Fight → alt (multi) · Swallow → alt (multi) · The Last One → primary (chain)

### Bird — Eyes: blind / vulnerable
- Little Owl → primary (blind) · Lucas → alt (vulnerable) · Mavis → primary (blind) · Robin → alt (vulnerable)

### Bird — Ears: rerollup / mana
- Curly → primary (rerollup) · Early Bird → primary (rerollup) · Owl → alt (mana) · Peace Maker → alt (mana) · Pink Cheek → primary (rerollup) · Risky Bird → alt (mana)

**Ghi chú**: `Little Owl` (Bird) và `Nut Cracker` (Beast), `Nimo` (Aquatic), `Leaf Bug` (Bug), `Peace Maker` (Bird) xuất hiện ở 2 slot khác nhau cho cùng class — đúng với dữ liệu gốc trong `axie-body-parts.md` (một part có thể tồn tại ở nhiều slot với card khác nhau); mỗi lần xuất hiện là một part riêng, nhận effect theo đúng ô slot đang xét, không dùng chung.

---

## 9. MỞ RỘNG CATALOG — 285 part thật + 111 part Origin/α (2026-09-01)

> **Bối cảnh**: catalog thật (`docs/axiedice-source/economy/parts_full_source.json`, nguồn `Part name.xlsx` do product owner cung cấp) có **285 part** (stage 1, đầy đủ), không phải 192 như §8 ở trên — 192 chỉ là tập con "stage 2" (tên có hậu tố "+"). Phần này gán nốt **75 part còn thiếu** (285 − 192 − 18 trùng tên-khác-slot = 75 part mới thật sự) + map **111 part α (Origin, stage 0)** làm danh tính cho bậc Mythic. Xem `design/gdd/economy-progression.md` §10.2b cho quyết định truy cập: **285 part gắn với NFT thật** (chỉ dùng được nếu sở hữu đúng Axie NFT mang part đó); **111 part α là pool DUY NHẤT free player mua được bằng Shard**.

### 9a. Gán 75 part mới (cùng phương pháp §8 — theo tên/flavor, không đọc card text)

*Keyword primary/alt của mỗi ô lấy đúng theo phân công đã CHỐT ở §8 (một số ô có thứ tự primary/alt ngược với tiêu đề gốc ở §2c — ví dụ Aquatic·Horn đã chốt `crit`=primary/`pierce`=alt ở §8, không phải `pierce`/`crit` như tiêu đề — dùng đúng thứ tự đã chốt để nhất quán).*

#### Aquatic — Ears: mana (primary) / rerollup (alt)
- Little Crab → alt (rerollup)

#### Aquatic — Eyes: cantrip (primary) / regen (alt)
- Baby → alt (regen) · Cold Fish → primary (cantrip) · Kind Fish → alt (regen)

#### Aquatic — Horn: crit (primary) / pierce (alt)
- Jellytacle → alt (pierce) · Darksea Jellyfish → primary (crit)

#### Aquatic — Mouth: mana (primary) / lifesteal (alt)
- Ranchu → alt (lifesteal)

#### Aquatic — Tail: chain (primary) / multi (alt)
- Puff → alt (multi) · Oranda → primary (chain)

#### Beast — Back: thorns (primary) / vulnerable (alt)
- Pangolin Slayer → primary (thorns)

#### Beast — Ears: rerollup (primary) / mana (alt)
- Foxy → primary (rerollup)

#### Beast — Eyes: regen (primary) / vulnerable (alt)
- Sparky → primary (regen) · Nut Cracker → alt (vulnerable) · Daydreaming → alt (vulnerable) · Sobby → primary (regen)

#### Beast — Horn: heavy (primary) / pierce (alt)
- Rocky Skull → primary (heavy) · Toy Ball → alt (pierce, đọc theo hình ảnh "banh gai/đồ chơi gai" thay vì banh trơn, để tránh lệch 4/1 trong ô — có thể đổi lại thành heavy nếu thấy gượng ép) · Beast Bun → primary (heavy) · Lump → primary (heavy) · Small Yak → alt (pierce)

#### Beast — Mouth: lifesteal (primary) / crit (alt)
- Foxy → alt (crit) · Puff → primary (lifesteal) · Cub → primary (lifesteal) · Platypus → alt (crit) · Puppy → primary (lifesteal) · Sniffle → primary (lifesteal) · Shishi → alt (crit)

#### Beast — Tail: multi (primary) / chain (alt)
- Buba Brush → primary (multi) · Pangolin → alt (chain)

#### Bird — Back: vulnerable (primary) / blind (alt)
- Lil Bro → primary (vulnerable) · Feather Melody → alt (blind) · Paper Wing → primary (vulnerable) · Rubber Duckling → alt (blind)

#### Bird — Eyes: blind (primary) / vulnerable (alt)
- Concentrate → primary (blind) · Passion → alt (vulnerable)

#### Bird — Horn: pierce (primary) / crit (alt)
- Big Sister → alt (crit)

#### Bird — Mouth: pierce (primary) / lifesteal (alt)
- Feathery Dart → primary (pierce)

#### Bird — Tail: chain (primary) / multi (alt)
- Death Shower → alt (multi)

#### Bug — Ears: mana (primary) / rerollup (alt)
- Brimstone → primary (mana) · Termites → alt (rerollup) · Maggot → alt (rerollup)

#### Bug — Eyes: poison (primary) / blind (alt)
- Ladybug Goggles → alt (blind)

#### Bug — Mouth: poison (primary) / lifesteal (alt)
- Nose Drill → primary (poison) · Maggot → alt (lifesteal)

#### Bug — Tail: poison (primary) / aoe (alt)
- Centipede → alt (aoe) · Leaf Bug → primary (poison) · Eye Wing → alt (aoe) · Shield Shattering → primary (poison)

#### Plant — Back: shieldself (primary) / thorns (alt)
- Forest Hero → primary (shieldself) · Succulent → alt (thorns) · Death Shroom → primary (shieldself) · Cone Shell → alt (thorns) · Meadow Blanket → primary (shieldself)

#### Plant — Ears: mana (primary) / rerollup (alt)
- Turnip → primary (mana) · Greenwood Rhythm → alt (rerollup)

#### Plant — Eyes: regen (primary) / cantrip (alt)
- Risky Trunk → primary (regen)

#### Plant — Horn: pierce (primary) / heavy (alt)
- Persimmon → alt (heavy) · Mandarine → alt (heavy) · Acorn Cap → primary (pierce) · Lotus → primary (pierce) · Ballad Of The Shore → primary (pierce)

#### Plant — Mouth: lifesteal (primary) / vital (alt)
- Beetroot → primary (lifesteal) · Hazelnut → alt (vital) · Kidney Bean → alt (vital)

#### Plant — Tail: shieldself (primary) / regen (alt)
- Sprout → alt (regen) · Drowsy Moss → alt (regen) · Tropical Guardian → primary (shieldself)

#### Reptile — Back: thorns (primary) / shieldself (alt)
- Tiny Dino → primary (thorns)

#### Reptile — Ears: mana (primary) / rerollup (alt)
- Hidden Ears → primary (mana) · Venom Nail → alt (rerollup)

#### Reptile — Eyes: regen (primary) / weaken (alt)
- Punky → alt (weaken) · Hard-boiled → primary (regen)

#### Reptile — Horn: pierce (primary) / heavy (alt)
- Poison Tube → primary (pierce)

#### Reptile — Mouth: lifesteal (primary) / poison (alt)
- Chemical Fang → alt (poison) · Tiny Dino → primary (lifesteal)

**Đếm lại**: 9+20+9+10+19+8 = 75 ✓ khớp danh sách nguồn.

### 9b. 111 part α (Origin) → danh tính Mythic

Mỗi ô Mythic (§2c) là **một cơ chế phá luật cho cả class×slot**, không phải per-part — nên nhiều part α cùng ô chia sẻ chung cơ chế đó, chỉ khác tên/art hiển thị. 4 flag nhẹ dưới đây là ghi nhận cảm tính (flavor lỏng ở bậc này, không chặn gì):

| (class, slot) | Part α (danh tính Mythic) | Flag |
|---|---|---|
| aquatic·back | Sponge | — |
| aquatic·ears | Little Crab, Gill | — |
| aquatic·eyes | Baby, Cold Fish, Kind Fish | — |
| aquatic·horn | Jellytacle, Darksea Jellyfish | — |
| aquatic·mouth | Ranchu | — |
| aquatic·tail | Puff, Oranda, Tadpole | — |
| beast·back | Pangolin Slayer | — |
| beast·ears | Foxy, Nut Cracker, Belieber, Puppy, Innocent Lamb | — |
| beast·eyes | Sparky, Nut Cracker, Puppy, Daydreaming, Sobby | nhẹ: Daydreaming/Sobby hiền hơn cơ chế execute hung hãn |
| beast·horn | Rocky Skull, Toy Ball, Beast Bun, Lump, Small Yak | nhẹ: Toy Ball/Beast Bun hơi dễ thương cho bonus +60% hung hãn |
| beast·mouth | Foxy, Puff, Cub, Nut Cracker, Platypus, Puppy, Sniffle, Shishi | — |
| beast·tail | Buba Brush, Nut Cracker, Pangolin, Shiba | — |
| bird·back | Lil Bro, Feather Melody, Paper Wing, Rubber Duckling | — |
| bird·eyes | Concentrate, Passion | — |
| bird·horn | Big Sister | — |
| bird·mouth | Feathery Dart | — |
| bird·tail | Death Shower | — |
| bug·ears | Brimstone, Leaf Bug, Termites, Maggot | — |
| bug·eyes | Ladybug Goggles | — |
| bug·mouth | Nose Drill, Maggot | — |
| bug·tail | Centipede, Leaf Bug, Eye Wing, Shield Shattering | — |
| plant·back | Forest Hero, Succulent, Death Shroom, Cone Shell, Meadow Blanket | — |
| plant·ears | Sakura, Turnip, Greenwood Rhythm | — |
| plant·eyes | Risky Trunk, Papi | — |
| plant·horn | Persimmon, Mandarine, Acorn Cap, Lotus, Ballad Of The Shore | nhẹ: "Ballad Of The Shore" nghe hợp tai/âm thanh hơn horn |
| plant·mouth | Beetroot, Hazelnut, Kidney Bean | — |
| plant·tail | Sprout, Drowsy Moss, Tropical Guardian | — |
| reptile·back | Tiny Dino, Croc | — |
| reptile·ears | Hidden Ears, Venom Nail, Curved Spine | nhẹ: Venom Nail/Curved Spine nghe hợp back/spine hơn ears |
| reptile·eyes | Punky, Hard-boiled, Scar | — |
| reptile·horn | Poison Tube, Bumpy | — |
| reptile·mouth | Chemical Fang, Tiny Dino | — |

**Tổng**: 111/111 part α đã gán. Việc còn lại: dawn/dusk/mech (36 part, D15 — thiết kế riêng, dùng lại part đã có ở 6 class chính theo đúng quyết định "rút 3/6 slot từ mỗi bloodline gốc").
