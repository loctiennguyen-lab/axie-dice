# BLOODLINE SYSTEM — Design Spec v1.2
### Axie Dice Tactics · Hệ Part → Die Face, Class Sub-Pool, và Content Engine cho Season

> Doc này giải quyết **rủi ro content cadence**. Nó mở rộng `AUDIT_AND_SPEC_v1.md` (§B2 vocabulary, §B5 Class × Tier, §D2 Rare Dice).
> **v1.1** — đã qua một vòng kiểm chứng độc lập đối chiếu từng dòng với dữ liệu nguồn. 14 lỗi được phát hiện và sửa; thay đổi lớn nhất nằm ở §0 (con số content), §4 (định nghĩa COMBO) và §9 (bốn rủi ro bị bỏ sót). Nhật ký sửa ở Phụ lục B.
>
> **v1.2** — đồng bộ với quyết định kiến trúc **Phương án A** đã duyệt (`ECONOMY_AND_PROGRESSION` §1.2): **rarity là thuộc tính của mặt xúc xắc trong ván, không phải của part.** Viết lại §5.1 (bỏ Universal pool; lên tier = nâng bậc mặt hiện có thay vì ghi lại die) và §5.2 (mỗi part tồn tại ở cả 4 bậc); thêm luật đường lên Mythic ở §5.3. **§4 (CHAIN/COMBO) đã được gác lại** theo thống nhất — giữ trong doc để tham chiếu, không nằm trong scope build.

---

## 0. TÓM TẮT ĐIỀU HÀNH

**Vấn đề:** Axie Dice có 50 mặt xúc xắc và 44 relic. Ở nhịp season 6 tuần, chúng ta cạn ý tưởng và cạn ngân sách art trước tháng thứ 12. Sản xuất content theo mô hình *cộng* có chi phí tuyến tính và không bền.

**Điều phát hiện được:** Axie Infinity đã có sẵn **273 body part**, trong đó **192 part core** phân bố **hoàn toàn đối xứng** — mỗi class đúng 32 part, chia đúng 6 loại part trùng với vocabulary die của chúng ta. Mỗi part có tên riêng, art riêng, hiệu ứng card đã được thiết kế và tôi luyện qua nhiều năm, và một cộng đồng đã nhận diện chúng từ 2018.

**Giải pháp:** Chuyển bài toán content từ *phát minh* sang *chuyển thể*.

| | Hiện tại | Sau Bloodline |
|---|---|---|
| Mặt xúc xắc **có cơ học riêng** | 50 (tự nghĩ) | **192** (có sẵn tên + art + card text để chuyển thể) |
| **Skin cosmetic** cho mặt | 0 | **45** (japan/summer/xmas/bionic — cùng slot, khác tên & art) |
| Keyword | 15 | **~27** (12 cái mới thu hoạch từ card thật) |
| Class pool | dùng chung | **6 bloodline riêng, mỗi cái 32 part** |
| Tầng Mythic | khái niệm trừu tượng | **36 Mystic** — khớp đúng 6 class × 6 slot; chuyển từ cosmetic sang **cơ học** (§5.3.1). Hiệu ứng vẫn phải tự thiết kế · **hoãn sang Phase 2** |
| Class mới | kẹt vì thiếu art | **Dusk / Mech / Dawn gần như miễn phí** (hybrid bloodline, zero part mới) |
| Nguồn theme season | phải tự nghĩ | 5 dòng part đặc biệt có sẵn + hệ Evolution |

> ⚠️ **Phân biệt hai đơn vị đếm — quan trọng khi trình bày.** 192 part core là **mặt có cơ học riêng biệt**; 81 part đặc biệt là **skin thuần cosmetic**, cùng slot, không có card effect riêng (chính Axie xác nhận chúng "function identically during gameplay"). Đừng cộng hai số này thành "273 mặt content". Luận điểm của doc đứng vững hoàn toàn trên 192 — không cần thổi số để thắng.

**Ba thứ đắt giá nhất, xếp theo thứ tự:**

1. **Bản sắc class không cần phát minh.** Mỗi class Axie đã có một archetype riêng, được đội thiết kế Axie tôi luyện qua 6 năm và hàng triệu người chơi kiểm chứng. Chúng ta *đọc ra* nó từ dữ liệu chứ không đoán. (§5.3)
2. **12 keyword mới, mỗi cái nhân với toàn bộ pool.** Content tầng nhân, không phải tầng cộng. (§3.3)
3. **Hệ bậc trong run** — mỗi part lớn lên qua 4 bậc, giữ nguyên danh tính. Đây là thứ làm cho việc lên tier có cảm giác *hoá thân* và làm cho Lead Axie khả thi. (§5.1-5.2)

> **[GÁC LẠI]** Hệ **CHAIN / COMBO** ở §4 không nằm trong scope build. Doc giữ lại để tham chiếu; mọi mục còn nhắc tới nó đều được đánh dấu **[GÁC LẠI]**.

---

## 1. DỮ LIỆU NỀN (đã xác minh)

**Nguồn:** `parts.json` trong npm package `agp-npm` (Axie Gene Parser) — bảng part cộng đồng dùng để decode gene Axie on-chain. Dữ liệu máy đọc, không phải wiki gõ tay.

```
273 part tổng
├── 192 core          (6 class × 32) ....... có card effect, là content cơ học
├──  36 mystic        (6 class × 6 loại) ... skin, đối xứng tuyệt đối
├──  18 japan         (3 mỗi class, đều) ... skin
├──  18 summer-2022   (9 gốc + 9 biến thể ✨) skin, lệch class nặng
├──   6 xmas .......................... skin
└──   3 bionic ........................ skin
```

> ⚠️ **Cần xác minh trước khi build:** agp-npm là package **do cộng đồng làm**, không phải API chính thức của Sky Mavis. Nó khớp mọi mẫu đối chiếu được, nhưng vì đây là nội bộ Sky Mavis, hãy đối chiếu một lần với bảng part chính thức của team Origins. Rẻ, và loại bỏ hẳn một giả định nền.

**Cấu trúc mỗi class:**

| Loại part | Số lượng/class |
|---|---|
| Horn · Back · Tail · Ears | 6 mỗi loại |
| Mouth · Eyes | **4** mỗi loại |
| **Tổng** | **32** |

### 1.1 Cardinality khớp — semantics thì không

Axie có đúng 6 loại part; die của chúng ta có đúng 6 loại mặt. **Số lượng khớp hoàn hảo, ý nghĩa thì không.**

Spec §B2 gán Back = shield, Ears = mana, Horn = dmg nặng. Nhưng dữ liệu thật phản bác điều đó ở khắp nơi: Beast·Back *Furball* là "đánh 3 lần", Beast·Ears *Belieber* là "đánh 3 đòn", Aqua·Horn *Teal Shell* là shield, Reptile·Horn *Bumpy* là hồi giáp. Đếm trên chính các ví dụ ở §3.2: **13/20 part không khớp vai trò mặc định của slot nó.**

**Kết luận thiết kế:** part-type ánh xạ sang **định danh và art của mặt xúc xắc**, còn **vai trò cơ học do designer gán từng part một**. Bảng §B2 hạ cấp từ *luật* xuống *thiên hướng thống kê* (Back *thường* là shield, không *luôn* là shield).

Đây không phải thất bại — đó chính là điều §A2.2 của audit đã chốt: *"part là flavor, distribution là design"*. Hệ quả này từng là rủi ro lớn ở mô hình cũ (lên tier = ghi lại die). **Phương án A xoá nó về mặt cấu trúc** (§5.1): lên tier không còn thay part. Ràng buộc còn lại chỉ áp cho Gene Mutation.

> 🔧 **Khoá dữ liệu:** khoá thật là `partId` (`horn-anemone`), **không phải tên**. 7 tên trùng giữa các slot: *Anemone* (Aqua horn+back), *Nut Cracker* (Beast mouth+tail+ears), *Nimo* (Aqua tail+ears), *Leaf Bug* (Bug horn+ears), *Peace Maker* (Bird mouth+ears), *Little Owl* (Bird mouth+eyes), *Puppy* (Beast eyes+ears).
>
> 🔧 **Dữ liệu bẩn cần sanitize:** `partId` **`eyes-kotaro?`** chứa dấu `?`, và **9 tên chứa ký tự `✨`**. Cả hai sẽ vỡ khi dùng làm tên file, URL hoặc khoá CSV. Thêm một bước slugify trong pipeline asset.

---

## 2. BA LUẬT THIẾT KẾ

**Luật 1 — Giữ FANTASY, dịch MECHANIC.**
Origins là game thẻ bài 3v3 có năng lượng, tay bài, chain/combo. Axie Dice là game gán xúc xắc 5 unit không tay bài. Số liệu Origins **không được copy** — Origins đã rebalance nhiều lần và cùng một part có số khác nhau giữa các patch. Cái được copy là *động từ*: hút máu, phản đòn, độc, tăng mana, đánh nhiều lần, tự hại. Người chơi phải nhận ra "à, Ronin đúng là Ronin" mà không cần con số giống nhau.

**Luật 2 — Tên part bất khả xâm phạm, số liệu tự do.**
Giá trị IP nằm ở cái tên và art. Cân bằng là việc của sim.

**Luật 3 — Bloodline tạo bản sắc, không tạo nhà tù.**
Nếu Plant chỉ bao giờ nhận part Plant, build hội tụ và game chết. Van xả là bắt buộc, và phải **luôn có mặt**, không phải hiếm (§5.4).

---

## 3. QUY TẮC CHUYỂN THỂ: PART → MẶT XÚC XẮC

> ⚠️ **Sửa 2026-09-01 — §3 dưới đây ĐÃ LỖI THỜI.** Quyết định sản phẩm mới: part chỉ cho danh tính (tên/class/slot/art), hiệu ứng mặt xúc xắc **không được trích từ card text Origins/Classic** nữa — kể cả 12 keyword "thu hoạch" ở §3.3. Phương pháp hiện hành (36 template do `game-designer` tự thiết kế theo slot×class, không đọc card text) nằm ở `design/gdd/part-tier-system.md` §2a. Giữ nguyên §3 dưới đây làm tài liệu lịch sử/tham khảo (một số ý tưởng keyword ở §3.3 vẫn có thể hữu ích làm cảm hứng thiết kế sau này, miễn là không gắn nhãn "chuyển thể từ card thật" nữa) — **không dùng nó làm quy trình sống**.

### 3.1 Quy trình 3 bước (LỊCH SỬ — xem cảnh báo trên)

```
1. TRÍCH ĐỘNG TỪ   : đọc card text Origins, rút ra hành vi cốt lõi
2. ÁNH XẠ KEYWORD  : map vào keyword có sẵn (§B3)
3. NẾU KHÔNG CÓ    : → đây là một KEYWORD MỚI cần thiết kế
```

Bước 3 là điểm quan trọng nhất của cả doc. Nó biến thư viện part thành **một bản brief thiết kế keyword có sẵn**: chúng ta không ngồi nghĩ "cần keyword gì nữa", mà đọc 192 card và để dữ liệu chỉ ra chỗ thiếu.

**Phạm vi áp dụng:** quy trình này chỉ chạy được trên **192 part core**. 81 part đặc biệt không có card text — chúng đi vào hệ thống với tư cách **skin**, không phải cơ học.

### 3.2 Ví dụ đã chuyển thể (part thật, card text đã đối chiếu)

| Part | Class·Loại | Card text Origins | → Mặt xúc xắc |
|---|---|---|---|
| **Furball** | Beast·Back | Strike 3 times | `multi:3` — có sẵn |
| **Cottontail** | Beast·Tail | Gain 1 energy | `mana:1 cantrip` — có sẵn |
| **Catfish** | Aqua·Mouth | Heal by damage inflicted | `lifesteal` — có sẵn |
| **Indian Star** | Reptile·Back | Reflect 40% melee damage | `thorns` — có sẵn |
| **Grass Snake** | Reptile·Tail | Apply Poison | `poison` — có sẵn |
| **Post Fight** | Bird·Tail | Inflict 30% of max HP to self | `selfharm` — có sẵn |
| **Ronin** | Beast·Back | Guaranteed crit when comboed with 2+ cards | `combo:3 → crit` — **mới** |
| **Anemone** | Aqua·Horn+Back | Restore 50 HP *for each Anemone part* | `resonance` — **mới** |
| **Risky Beast** | Beast·Back | Deal 150% if in Last Stand | `desperate` — **mới** |
| **Pliers** | Bug·Horn | 30% more damage to shielded targets | `breaker` — **mới** |
| **Teal Shell** | Aqua·Horn | Add 30% shield when attacking | `bulwark:N` — **mới** |
| **Tri Feather** | Bird·Back | Attack twice if this Axie has any debuffs | `spite` — **mới** |
| **Tiny Dino** | Reptile·Tail | Deal 150% damage after round 4 | `ramp:N` — **mới** |
| **Red Ear** | Reptile·Back | Add 15% of shield to adjacent teammates | `share:N` — **mới** |
| **Kestrel** | Bird·Horn | Disable target's horn cards next round | `deny:<part>` — **mới** |
| **Yam** | Plant·Tail | Apply Poison when used to attack **or defend** | `sentinel` — **mới** |
| **Scarab** | Bug·Back | Target cannot be healed until next round | `antiheal` — **mới** |
| **Clover** | Plant·Ears | Enables summoning 1 Clover | `summon` (mở cho phe ta) — **mới** |
| **Bidens** | Plant·Back | Remove all debuffs from this Axie | `cleanse` — **mới** |
| **Bumpy** | Reptile·Horn | Recover 20 shield per turn | `shieldregen` — **mới** |

### 3.3 Thu hoạch: 12 keyword mới (15 → 27)

Keyword là code thuần: không art, không asset, và mỗi cái tự động mở ra một họ relic mới trên hệ hook đã có (`modFace / modDmg / onKill / onShield / onHit / onTurnStart`). Đi từ 15 lên 27 keyword nhân với 192 mặt và 44 relic — **mức tăng content lớn hơn việc thêm 150 relic mới, với khoảng một phần năm chi phí.**

Cột "bằng chứng" ghi trung thực số part core thật sự hỗ trợ keyword đó. Keyword có `n=1` là **ngoại suy**, không phải chuyển thể — đánh dấu rõ để không tự lừa mình.

| # | Keyword | Ý nghĩa | Part làm bằng chứng | n |
|---|---|---|---|---|
| 1 | `combo:N` | Thưởng nếu ≥N mặt cùng loại part gán cho **cùng một hero** | Ronin, Square Teeth, Twin Tail, Tiny Turtle, Nut Cracker (mouth+tail), Perch, Rice, Nimo·tail | 8 |
| 2 | `desperate` | Thưởng khi chủ nhân HP thấp | Risky Beast, Jaguar, Shiba, Lam, Piranha, Hungry Bird, Kingfisher, Axie Kiss, Pupae | 9 |
| 3 | `breaker` | Thưởng khi mục tiêu có shield | Pliers, Caterpillars, Tri Spikes | 3 |
| 4 | `bulwark:N` | Mặt sát thương đồng thời tạo shield | Teal Shell, Merry, Timber | 3 |
| 5 | `spite` | Thưởng khi **chính mình** đang bị debuff | Tri Feather, Feather Fan, The Last One, Post Fight | 4 |
| 6 | `sentinel` | Kích hoạt **cả khi phòng thủ** | Yam, Snail Shell, Fish Snack, Curved Spine, Goldfish | 5 |
| 7 | `cleanse` | Gỡ debuff | Bidens, Mint, Seaslug, Gecko | 4 |
| 8 | `summon` | Gọi đồng minh tạm cho phe ta | Clover, Hollow, Mavis, Robin | 4 |
| 9 | `shieldregen` | Hồi shield mỗi lượt | Bumpy, Wall Gecko, Snake Jar | 3 |
| 10 | `deny:<trục>` | Khoá một **trục** của địch ở lượt sau | Kestrel *(theo part)*, Hot Butt *(theo part)*, Gravel Ant *(theo melee)*, Hatsune *(theo ranged)* | 4 ⚠️ |
| 11 | `resonance` | Giá trị tăng theo số bản sao part này trong đội | **Anemone** | **1** ⚠️ |
| 12 | `ramp:N` / `antiheal` / `share:N` | Scale theo vòng · chặn hồi máu · lan sang kề cạnh | Tiny Dino · Scarab · Red Ear | **1 mỗi cái** ⚠️ |

⚠️ **Ghi chú trung thực:**
- `deny` — Axie khoá theo **hai trục khác nhau**: theo loại part (Kestrel, Hot Butt) và theo loại sát thương (Gravel Ant "melee", Hatsune "ranged"). Axie Dice không có khái niệm melee/ranged. Chọn **một trục duy nhất — theo loại part** — và chuyển 2 part kia sang cơ học khác. Đừng nhập cả hai.
- `resonance`, `ramp`, `antiheal`, `share` mỗi cái chỉ có **1 part** làm bằng chứng. Chúng vẫn đáng làm, nhưng phải gọi đúng tên: **phát minh có cảm hứng từ dữ liệu**, không phải "đọc ra từ dữ liệu".

> 🔧 **Xung đột đặt tên, sửa ngay:** spec §B3 hiện dùng `chain:N` = "N đòn vào địch ngẫu nhiên". Trong Axie, *chain* nghĩa hoàn toàn khác. Đổi keyword hiện tại thành **`scatter:N`**. Rẻ nếu làm bây giờ.

---

## 4. CHAIN & COMBO — nhập khẩu linh hồn Origins

Trong Axie Origins, hai cơ chế định hình toàn bộ chiều sâu:
- **Chain** — nhiều thẻ **cùng class**, trên **nhiều Axie**, trong cùng lượt
- **Combo** — nhiều thẻ trên **cùng một Axie**

Axie Dice hiện không có gì tương đương: mỗi mặt được đánh giá độc lập. Đó là lý do decision density mỗi lượt thấp hơn tiềm năng — người chơi đang giải 5 bài toán nhỏ song song thay vì 1 bài toán lớn.

### 4.1 Ánh xạ (đã sửa ở v1.1)

| Origins | Axie Dice | Phạm vi | Trục build |
|---|---|---|---|
| Chain | **BLOODCHAIN** — ≥2 Axie **cùng class** dùng mặt trong lượt | **toàn đội** | Xếp đội mono-class |
| Combo | **COMBO** — ≥N mặt **cùng loại part** gán cho **cùng một hero** | **một hero** | Tập trung hoả lực & build theo part |

> **Sửa quan trọng so với v1.0:** bản đầu định nghĩa COMBO là "≥N mặt cùng loại part trong lượt" — tức đếm toàn đội. Khi đó BLOODCHAIN và COMBO trở thành **cùng một phép đếm toàn cục, chỉ khác khoá nhóm**, và một đội mono-class toàn Horn kích hoạt cả hai mọi lượt mà không phải đánh đổi gì. Hai trục "vuông góc" thực ra là một trục xoay hai lần. Định nghĩa per-hero khôi phục tính vuông góc thật: BLOODCHAIN thưởng *chiều rộng đội hình*, COMBO thưởng *chiều sâu trên một hero*, và hai thứ đó cạnh tranh nhau để giành cùng một tài nguyên — số mặt bạn có trong lượt.

**Điều kiện tiên quyết:** COMBO per-hero chỉ có nghĩa nếu **một hero có thể nhận nhiều hơn một mặt trong lượt**. Hiện tại mô hình là 1 hero = 1 die = 1 mặt. Cần một trong hai:
- **(a)** Cho phép gán mặt của hero khác **vào** một hero (nhập thành combo trên hero đó) — gần Origins nhất, và ăn khớp tự nhiên với hình học xúc xắc d8/d12 đã bàn ở brainstorm.
- **(b)** COMBO tính theo mặt cùng loại part **đánh vào cùng một mục tiêu**.

Khuyến nghị **(a)** — nó bảo toàn fantasy của Origins và tạo quyết định "dồn hay dàn" mỗi lượt. Nhưng đây là thay đổi mô hình, không phải một hàm kiểm tra: **phải chốt trước khi bắt đầu build.**

### 4.2 Vì sao đáng làm

Hệ này tạo hai trục build mới, vuông góc với 10 archetype hiện có:

- *"Đội tôi 4 Plant → mặt Plant +20%"* → người chơi có lý do từ chối một hero mạnh hơn nhưng khác class. Đây là loại quyết định roguelike sống nhờ vào.
- *"Tôi dồn 3 mặt Horn vào Beast này"* → reroll trở thành bài toán xác suất thật, không chỉ là "đổi mặt xấu".

Quan trọng nhất: **nó biến reroll từ công cụ sửa sai thành công cụ theo đuổi.** Người chơi reroll để *săn* cấu hình, không phải để tránh mặt tệ. Đó là khác biệt cảm xúc lớn và nó nâng trần kỹ năng — đúng liều thuốc cho vấn đề skill plateau.

### 4.3 Bốn ràng buộc bắt buộc

1. **Cộng, không nhân, và có trần.** `bonus = min(chain + combo, CAP)`. Spec §C đã ghi lại bài học rằng scale nhân trên hiệu ứng tích luỹ tạo tường bất khả thi (bug poison wave 15). Đừng lặp lại với cơ chế mới.
2. **Chuẩn hoá ngưỡng COMBO theo pool size.** Mouth và Eyes chỉ có 4 part/class so với 6 của các loại khác → build "toàn Mouth" có xác suất combo thấp hơn 33% **vĩnh viễn**, không sửa được bằng tuning. Hoặc hạ ngưỡng N cho Mouth/Eyes, hoặc gộp Mouth+Eyes thành một nhóm combo "utility".
3. **Luật cho secret class.** Hero Dusk rút từ hai bloodline — nó tính là Reptile hay Aquatic khi chain? Đề xuất: **chain được với cả hai, hệ số 0.5.** Nếu tính đủ cả hai thì Dusk mạnh vô lý; nếu không tính thì nó không bao giờ chain được và §6 sai khi gọi nó là class linh hoạt nhất.
4. **BLOODCHAIN đẩy mạnh hội tụ build.** Xem §9 #2 — đây là rủi ro 🔴, không phải 🟠.

### 4.4 Chi phí thực (đã thống nhất ở v1.1)

| Hạng mục | Ước tính |
|---|---|
| Resolver trong `engine.js` | 2-3 ngày |
| UI & feedback (chỉ báo combo, tooltip, hiệu ứng khi trigger) | 1-2 tuần |
| Rebalance + chạy lại sim | 2-3 tuần |
| **Tổng** | **~4-6 tuần**, không phải "2-3 ngày" |

*(v1.0 ghi "2-3 ngày dev" ở §4 nhưng "sim phải chạy lại toàn bộ — Lớn" ở §8. Con số dưới đây là con số thống nhất.)*

---

## 5. KIẾN TRÚC BLOODLINE

### 5.1 Cấu trúc pool

> 🔄 **Đã viết lại ở v1.2** theo quyết định kiến trúc **Phương án A** (`ECONOMY_AND_PROGRESSION` §1.2, đã duyệt): **rarity là thuộc tính của MẶT XÚC XẮC trong một ván, không phải của PART.** Bộ sưu tập mở khoá danh tính part; sức mạnh kiếm trong run và mất khi run kết thúc. Bản v1.1 gán mỗi part vào một bậc rarity cố định — cách đó đưa gradient sức mạnh vào tầng sưu tầm và biến bộ sưu tập thành pay-to-win.

```
Mỗi hero rút mặt từ:
  BLOODLINE của class nó   32 part   (độc quyền, tạo bản sắc)
+ META MORPH               van xả off-class (§5.5)

Mọi part vào run ở bậc COMMON. Bậc được nâng TRONG run.
```

**Universal pool đã bị bỏ.** Nó tồn tại ở v1.1 để giữ early game dễ đọc và để chữa bẫy toán học ở Mouth/Eyes. Cả hai lý do đều biến mất: mọi part giờ đều vào ở bậc Common nên early game tự nhiên đơn giản, và Mouth/Eyes không còn phải chia 4 part cho 4 bậc. Vai trò "giữ dễ đọc cho người mới" chuyển sang **bộ sưu tập khởi đầu 60 part** (`ECONOMY` §2).

**Lên tier = nâng BẬC của chính các mặt đang có, không ghi lại die.**

| | v1.1 (bỏ) | **v1.2** |
|---|---|---|
| T1 → T2 | Ghi lại die bằng part Rare của bloodline | **Nâng 2-3 mặt hiện có từ Common lên Rare** |
| T2 → T3 | Ghi lại die bằng part Epic | **Nâng tiếp lên Epic/Legendary** |
| Danh tính hero | Bị xoá mỗi lần lên tier | **Giữ nguyên suốt run** |

Đây không chỉ là dọn dẹp. Nó sửa ba thứ cùng lúc:

- **Lead Axie trở nên khả thi.** Ở v1.1, danh tính của Lead bị xoá ngay lần lên tier đầu tiên — đúng thứ người chơi mang theo thì mất, đúng vào lúc đáng nhớ nhất.
- **Ràng buộc §1.1 tự động được thoả mãn.** Không còn "thay part theo slot" thì cũng không còn nguy cơ hero tank mất sạch shield vì bốc trúng Furball/Ronin/Risky Beast. Cảnh báo cũ ở đây trở nên thừa.
- **Lên tier có cảm giác *hoá thân*, không phải *thay máu*.** `Ronin` của anh mạnh dần lên chứ không bị một part khác thế chỗ.

**Gene Mutation** giữ nguyên vai trò cũ và giờ là cơ chế **đổi danh tính** duy nhất trong run: *"Thay mặt 3 → **Ronin** (Beast · Back)"*. Rarity của mặt đó được bảo toàn khi đổi.

### 5.2 Các bậc của một part

Rarity không còn phân bổ **giữa các part**. Mỗi part tồn tại ở **mọi bậc**, theo một mẫu leo thang chung:

| Bậc | Quy tắc | Ví dụ — `Bumpy` (Reptile · Horn) |
|---|---|---|
| COMMON | Hiệu ứng gốc + **keyword đặc trưng ở giá trị tối thiểu** | shield 4 · `shieldregen:3` |
| RARE | Giá trị tăng | shield 6 · `shieldregen:5` |
| EPIC | Keyword đầy đủ theo card text thật | shield 8 · `shieldregen:8` |
| LEGENDARY | Giá trị lớn + 1 keyword phụ | shield 12 · `shieldregen:10` · `share:3` |
| **MYTHIC** | Hiệu ứng phá luật của cặp `class × slot` (§5.3.1) | + ⟨`PINKU UNKO`⟩ |

> ⚠️ **COMMON phải có keyword, không được là số trần.** Bản vá đầu của v1.2 ghi COMMON = "0 keyword". Hệ quả: đầu mỗi run cả 30 mặt trên bàn đều là số trần — `Furball` không đánh 3 lần, `Catfish` không hút máu, `Bumpy` không hồi giáp — và **sáu bản sắc class ở §5.4, thứ đắt giá nhất của cả doc, đều được định nghĩa bằng keyword nên không class nào phân biệt được với class nào trong nửa đầu run.** Bản sắc bloodline phải bật từ lượt đầu tiên. Gradient sức mạnh chuyển sang **giá trị số + keyword phụ**, không phải sang việc *có hay không có* keyword.

Điều này **xoá bỏ bẫy toán học ở Mouth/Eyes** mà v1.1 phải chữa bằng cách vay Universal pool: hai loại này chỉ có 4 part/class, và ở mô hình cũ việc chia 4 part cho 4 bậc khiến pool Legendary·Mouth của một class chỉ còn đúng 1 part cố định. Giờ cả 4 part đều tồn tại ở cả 4 bậc, và vấn đề không còn.

> ⚠️ **Chi phí:** 192 part × 4 bậc. Đây **không phải** 768 thiết kế riêng — mỗi part có một hiệu ứng gốc cộng một bảng leo thang theo mẫu trên. Ước tính **+3-4 person-week**. Đây là cái giá của Phương án A và đã được tính vào quyết định.
>
> ⚠️ **Điều kiện sống còn:** mọi part **ở cùng một bậc** phải nằm trong cùng ngân sách sức mạnh (±10%). Vi phạm điều này là đưa gradient trở lại tầng sưu tầm và huỷ toàn bộ luận điểm. Phải kiểm **tự động trong CI**, không phải review thủ công (`ECONOMY` §9, §11 #1).

### 5.3 Mystic = tầng Mythic

36 Mystic part phân bố **đúng 6 mỗi class, đúng 1 mỗi loại part** — một ma trận 6×6 đầy đủ, không cần cắt gọt. Spec §D2 định nghĩa Mythic là mặt "phá một luật" và là nguồn dopamine trung tâm của cú roll. Mystic là thứ hiếm và uy tín nhất trong vũ trụ Axie, nguồn cung đã đóng vĩnh viễn.

Tên đã có sẵn và tự nó là juice:

| Class | Mystic (Mouth · Horn · Back · Tail · Eyes · Ears) |
|---|---|
| **Beast** | Skull Cracker · Winter Branch · **Hasagi** · Sakura Cottontail · Calico Zeal · Pointy Nyan |
| **Aquatic** | Lam Handsome · Candy Babylonia · Crystal Hermit · Kuro Koi · Insomnia · Red Nimo |
| **Plant** | Humorless · Golden Bamboo Shoot · Pink Turnip · **Namek Carrot** · Dreamy Papi · The Last Leaf |
| **Reptile** | Venom Bite · Pinku Unko · Rugged Sail · Escaped Gecko · Crimson Gecko · Deadly Pogona |
| **Bug** | Feasting Mosquito · Laggingggggg · Starry Shell · **Fire Ant** · Broken Bookworm · Vector |
| **Bird** | Mr. Doubletalk · Golden Shell · Starry Balloon · Snowy Swallow · **Sky Mavis** · Heart Cheek |

Khi mặt `HASAGI` rơi ra và màn hình chớp trắng, đó không phải một con số lớn — đó là một người chơi Axie nhận ra thứ họ đã không mua nổi suốt nhiều năm. Không relic tự nghĩ nào mua được cảm xúc đó.

### 5.3.1 Đường lên Mythic — luật chốt

> ⚠️ **Bản vá đầu của v1.2 sai ở đây và đã được viết lại.** Nó nói *"nâng lên Mythic nếu part đó có bản Mystic tương ứng"* — nhưng **ánh xạ đó không tồn tại**: 36 Mystic là 36 `partId` **độc lập** trong `parts.json`, không phải phiên bản nâng cấp của part core nào. `Hasagi` không phải "bản Mystic của Ronin", nó là một Beast·Back riêng. Tệ hơn, luật đó biến việc lên Mythic thành một **cú đổi danh tính** (`Ronin` → `Hasagi`) — đúng thứ mà §5.1 vừa tuyên bố đã diệt tận gốc, và xảy ra ở đúng khoảnh khắc đắt giá nhất của run.

**Luật đúng: Mythic gắn với `class × slot`, không gắn với part.**

> Mỗi cặp (class, slot) có **đúng một hiệu ứng Mythic phá luật**, mang tên và art của Mystic part tương ứng. **Bất kỳ** part nào của class đó, ở slot đó, khi đạt **LEGENDARY**, đều có thể được nâng lên **MYTHIC** và nhận hiệu ứng ấy.
>
> Mặt **giữ nguyên `partId` và tên gốc**, hiển thị thêm huy hiệu Mythic: `RONIN ⟨HASAGI⟩`.

Ma trận 6×6 của Mystic khớp chính xác với 6 class × 6 slot — **không cần bảng ánh xạ nào cả**, chỉ cần đọc đúng chiều. Và ba vấn đề tan cùng lúc: danh tính được bảo toàn (§5.1 không bị bác), mọi part đều có đường lên bậc cao nhất (không có 26 part ngõ cụt mỗi class), và người chơi không cần biết trước part nào "có số phận".

**Nguồn nâng lên Mythic:** chỉ qua nguồn hiếm trong run — node **Bể Đột Biến**, boss reward, relic chuyên dụng. ⇒ Mythic là **thành tựu trong ván**, không phải tài sản mang theo. Ai cũng có cơ hội; không ai mua được.

> 🔧 **Ràng buộc bắt buộc cho Gene Mutation.** §5.1 nói Mutation *"bảo toàn rarity khi đổi part"*. Ghép với luật trên thì người chơi chỉ cần đẩy **bất kỳ** mặt nào lên Legendary rồi Mutate ngay trước boss — "giữ part tới cuối run" thành zero-cost. **Sửa: Gene Mutation hạ mặt về COMMON khi đổi danh tính.** Nhất quán với luật gốc (danh tính do sưu tập, sức mạnh do run) và biến Mutation thành một đánh đổi thật thay vì reroll miễn phí.

**Secret class:** Dusk/Mech/Dawn không có Mystic part riêng. Hero secret class **chọn một trong hai** hiệu ứng Mythic của class bố mẹ cho slot đó, không phải cả hai — nếu không nó có 12 đường Mythic so với 6 của class thường.

**Chủ sở hữu Axie Mystic thật** nhận **art Mystic nguyên bản** (art NFT thật + khung + VFX riêng), áp lên mặt tương ứng ở **mọi bậc**, không chỉ Mythic. Người chơi thường lên Mythic thấy biến thể "awakened" chung. Đây là ranh giới giữ lớp NFT sạch: chủ sở hữu có **vẻ ngoài khan hiếm** vĩnh viễn và độc quyền; **sức mạnh** thì ai cũng phải chơi mới có.

> ⚠️ **Nói cho rõ chi phí — v1.0 đã bán quá lời chỗ này.** Mystic part **không có card effect riêng** trong Axie; chúng là skin. Nghĩa là ở tầng cao nhất, khó nhất, đắt nhất của hệ rarity, **cả 36 hiệu ứng đều phải thiết kế 100% từ đầu.** Cái được kế thừa là **cái tên, art, và khung đối xứng 6×6** — vẫn rất giá trị, nhưng đó là giá trị *naming và cấu trúc*, không phải giá trị *tiết kiệm design*. Ước tính: 36 mặt "phá luật" ≈ **3-4 person-week** thiết kế + sim.
>
> ⚠️ **Lệch canon, cần chốt ở cấp thương hiệu:** trong Axie thật Mystic thuần cosmetic. Cho Mystic là tầng mạnh nhất là quyết định có chủ đích. Tôi ủng hộ — đây là điều cộng đồng vẫn *ước* là đúng — nhưng phải nêu rõ khi xin duyệt IP, không để lộ ra sau như một sự cố. Xem thêm §9 #4.

### 5.4 Bản sắc 6 class — đọc ra từ dữ liệu

Các archetype dưới đây **không do tôi nghĩ ra.** Chúng nổi lên khi đọc 192 card thật. Đội thiết kế Axie đã tôi luyện chúng qua nhiều năm với hàng triệu người chơi — chúng ta đang kế thừa một tài sản thiết kế đã được kiểm chứng.

| Class | Archetype | Part làm bằng chứng | Độ chắc |
|---|---|---|---|
| **Plant** | **Shield trả cổ tức + Cleanse + Summon.** Shield không chỉ để chịu đòn — nó là điều kiện kích hoạt. | Pumpkin (thưởng nếu shield *không* vỡ) vs Beech & Carrot (thưởng nếu shield *vỡ*) — **hai chiều đối lập trong cùng một class = quyết định thật**. Bidens/Mint (cleanse), Clover/Hollow (summon), Shiitake/Rose Bud/Strawberry Shortcake (heal) | Chắc |
| **Beast** | **Crit + Cùng đường (desperate).** | Dual Blade, Imp, Ronin, Little Branch (crit) · Risky Beast, Jaguar, Shiba, Pupae (Last Stand → `desperate`) · **Nut Cracker ở 3 slot, trong đó 2 slot (mouth, tail) thưởng khi combo với bản sao của chính nó** — synergy được IP tặng, rất hợp game xúc xắc | Chắc |
| **Aquatic** | **Tempo + Mana + Chặn hồi sinh.** | Nimo (tail+ears), Cottontail-tương đương, Rice (mana engine) · Ranchu/Tadpole/Granma's Fan (chill/jinx) · **Oranda + Shoal Star** (chống Last Stand) | Chắc |
| **Reptile** | **Tiêu hao + Giáp bền + Phản đòn + Scale muộn.** | Bumpy, Wall Gecko, Snake Jar (`shieldregen`) · Red Ear (`share`) · Indian Star + Scaly Spoon (phản melee/ranged riêng biệt) · **Tiny Dino (150% sau vòng 4) = build "cầm cự để thắng"** — fantasy hiện chưa có trong game | Chắc |
| **Bug** | **Phá giáp + Debuff + Poison + Chống hồi máu.** | Pliers & Caterpillars (`breaker` — **mật độ cao nhất**, dù Reptile·Tri Spikes cũng đọc shield) · Garish Worm (poison) · Lagging (`speed-`) · Scarab (`antiheal`) · Spiky Wing, Buzz Buzz | Vừa — **6 Bug·Ears chưa có card text** |
| **Bird** | **Tự làm hại mình để đổi lấy sức mạnh.** Archetype thú vị nhất và ta hoàn toàn chưa có. | Feather Fan (**shield theo số debuff trên chính mình**) · Tri Feather (đánh 2 lần nếu bản thân bị debuff) · The Last One (tự áp 2 Attack−) · Post Fight (tự mất 30% max HP) · Eggshell (tự kéo aggro) | Vừa — **5 part xác minh / 26 có text; 6 Bird·Ears chưa có text** |

Bird là ví dụ hoàn hảo cho luận điểm của cả doc: **chúng ta sẽ không bao giờ tự đề xuất một archetype self-harm trong một cuộc họp thiết kế** — nó quá phản trực giác để nói ra tay không. Nhưng nó nằm sẵn trong dữ liệu, đã được chơi, đã được chứng minh là vui.

> ⚠️ **Hai lưu ý về độ chắc:** (1) Bird và Bug đang được kết luận trên dữ liệu khuyết — 12 part Ears không có card text công khai. Nội bộ Sky Mavis chắc chắn có; lấy từ team Origins thay vì đoán. (2) Bird chia sẻ trục `summon` với Plant (Mavis, Robin vs Clover, Hollow) — cần phân hoá, nếu không bản sắc Plant bị loãng.

### 5.5 Van xả: Meta Morph

Van xả **cũng là một cơ chế Axie có thật**:

> **Meta Morph** (Axie Origins): đổi card của một part sang card của bất kỳ Axie nào bạn sở hữu, tốn Class Badge + SLP, tỉ lệ thành công phụ thuộc collection tier.

Trong Axie Dice, Meta Morph cho phép **ghép một part từ bloodline khác lên hero của bạn**. Đây là cơ chế "splash off-class" mà mọi deckbuilder cần, dùng đúng tên và đúng fantasy Axie, và về sau là chỗ móc nối tự nhiên nhất cho lớp collection/Web3 — không chạm vào power curve ở Phase 1.

> ⚠️ **Sửa so với v1.0:** Meta Morph **không được là "reward hiếm"**. Bloodline độc quyền 32 part **tự nó** đã là một incentive mono-class luôn bật, kể cả khi không có BLOODCHAIN — và sau khi bỏ Universal pool, **Meta Morph là nguồn off-class duy nhất trong toàn game**. Một van xả hiếm không thể cân bằng điều đó. Meta Morph phải xuất hiện đều đặn — đề xuất: có mặt trong reward pool mọi wave với trọng số vừa, cộng thêm một event node chuyên dụng. Tỷ lệ mục tiêu ~**80% mặt từ bloodline, 20% từ Meta Morph & event**, tune bằng sim với **archetype diversity là chỉ số nghiệm thu**, không phải winrate.

---

## 6. SECRET CLASS GẦN NHƯ MIỄN PHÍ — gỡ blocker art

Spec §D6 liệt kê "Mech / Dawn class (chưa có art)" là ngoài scope. Dữ liệu gỡ blocker này.

**Secret class trong Axie không có part riêng.** Chúng thừa hưởng part từ hai class bố mẹ; khác biệt là **màu body** và base stats.

```
Dusk = Reptile × Aquatic
Mech = Bug     × Beast
Dawn = Plant   × Bird
```

Dịch sang Axie Dice:

> **Một hero secret class là một hero có quyền rút mặt từ HAI bloodline.**

- **Zero part mới cần thiết kế** — 64 part của hai class bố mẹ đã sẵn sàng.
- **Art là recolor**, không phải sprite mới — đúng như Axie thật làm.
- Các cặp lai tự nó đã thú vị: **Dawn = Plant × Bird** ghép "shield trả cổ tức" với "tự hại để lấy payoff" — một class mà bạn tự làm mình yếu đi để nạp shield. Archetype hoàn chỉnh, sinh ra miễn phí từ phép giao hai pool.
- **Cần một đối trọng**, nếu không secret class chỉ là "pool 64 part thay vì 32, không nhược điểm" — một nâng cấp thuần. Vì BLOODCHAIN đã gác lại, đối trọng phải độc lập với nó: đề xuất **chỉ rút được 3/6 slot từ mỗi bloodline bố mẹ** (buộc phải chia đôi, không được lấy phần tinh tuý của cả hai), và chỉ chọn **một** trong hai hiệu ứng Mythic của class bố mẹ (§5.3.1).

Ba class mới với chi phí design gần bằng không là **một drop lớn cho một season**, đến từ việc đọc dữ liệu chứ không phải từ ngân sách.

---

## 7. CONTENT ENGINE: LỘ TRÌNH SEASON 18 THÁNG

Mỗi season 6 tuần, ngân sách design ~4-6 person-week.

| Season | Chủ đề | Nội dung chính | Nguồn asset |
|---|---|---|---|
| **S0** *(launch)* | Bloodline | 6 bloodline × 32 part · **4 bậc/part** · 12 keyword mới · bộ sưu tập + Mastery | ✅ có sẵn (192) |
| **S1.5** | Mythic | **36 hiệu ứng Mystic** (class × slot) + art + skin cho chủ NFT | 🔴 hiệu ứng mới hoàn toàn |
| **S1** | Lunacia Festival | 18 **Japan part** + Season Mutation + relic | ✅ có sẵn — **dòng duy nhất đều 3/class** |
| **S2** | *Drop lớn:* Hình học xúc xắc | d4 / d8 / d12 — nhân với toàn bộ pool | ⚙️ thuần cơ chế |
| **S3** | Tide & Sun | 9 **Summer part** gốc (+9 biến thể ✨ làm skin cao cấp) | ✅ có sẵn ⚠️ **Plant 0, Bird 0** |
| **S4** | Frost | 6 **Xmas part** + boss mùa đông | ✅ có sẵn ⚠️ **Aquatic 0** |
| **S5** | *Drop lớn:* Secret Class | **Dusk · Mech · Dawn** — hybrid bloodline | ✅ gần như miễn phí (§6) |
| **S6** | MEO Corp | 3 **Bionic part** → chủ đề boss/event máy móc | ✅ có sẵn ⚠️ **chỉ 3/6 class** |
| **S7** | Evolution | Level-2 part — **giới hạn 1 tier/class (36 part)**, không phải toàn bộ 192 | 🔴 **content mới hoàn toàn** |
| **S8** | *Drop lớn:* — | Trục Ascension thứ hai **hoặc** chế độ mới | ⚙️ mở |

**Đếm đúng: 6/9 season dùng asset có sẵn** — và trong 6 đó, **4 season (S1, S3, S4, S6) là skin thuần, zero cơ học mới.** Nghĩa là chúng **bắt buộc** phải ghép với Season Mutation + relic mới; nếu chỉ thả part vào, người chơi sẽ thấy season rỗng.

> 🔴 **S7 Evolution — v1.0 dán nhãn sai.** Bảng gốc ghi nguồn là "×2 trên pool có sẵn". Sai: `parts.json` **không tồn tại evolved part nào** — không trường, không entry. "Mỗi part core có phiên bản tiến hoá" nghĩa là **192 art mới + 192 effect mới**, tức season đắt nhất trong cả 18 tháng. Đã thu hẹp xuống **1 tier/class = 36 part**, và phải được ước tính chi phí như content mới hoàn toàn.

### 7.1 Ma trận special-gene × class — vì sao không season nào được đứng một mình

| Dòng | Beast | Aqua | Plant | Bird | Bug | Reptile | Tổng |
|---|---|---|---|---|---|---|---|
| mystic | 6 | 6 | 6 | 6 | 6 | 6 | **36** ✅ đều |
| japan | 3 | 3 | 3 | 3 | 3 | 3 | **18** ✅ đều |
| summer (gốc) | 3 | 1 | **0** | **0** | 1 | 4 | **9** ❌ |
| xmas | 2 | **0** | 1 | 1 | 1 | 1 | **6** ❌ |
| bionic | **0** | 1 | **0** | **0** | 1 | 1 | **3** ❌ |

Chỉ **Mystic và Japan** công bằng giữa 6 class. Đó là lý do S1 = Japan: đây là dòng special-gene duy nhất có thể mang một season mà không bỏ rơi ai. Các season còn lại phải bù bằng cơ học, không bằng part.

---

## 8. TÁC ĐỘNG LÊN SPEC HIỆN CÓ

| Khu vực | Thay đổi | Mức độ |
|---|---|---|
| `data.js` | Thay pool 50 mặt bằng 6 bloodline × 32 = **192 part core** (+36 hiệu ứng Mythic theo class×slot ở Phase 2) | Lớn, thuần data |
| `data.js` | **Bảng leo thang 4 bậc cho 192 part** — hạng mục lớn nhất của Phương án A | **Lớn** |
| `engine.js` | **Hàm nâng bậc mặt** (Common→Rare→Epic→Legendary) | Vừa |
| **CI** | **Kiểm ngân sách sức mạnh ±10% theo từng bậc** | **Vừa — điều kiện sống còn** |
| `engine.js` | `face` thêm `partId`, `bloodline`, `rarity` | Nhỏ |
| ~~`engine.js`~~ | ~~Mô hình gán mặt — nhiều mặt trên một hero~~ | **[GÁC LẠI]** |
| ~~`engine.js`~~ | ~~Resolver CHAIN/COMBO~~ | **[GÁC LẠI]** |
| `engine.js` | 12 keyword mới trên hệ hook đã có | Vừa, tăng dần |
| §B2 | Bảng part→role hạ cấp từ luật xuống thiên hướng | Nhỏ, nhưng đổi cách nghĩ |
| §B3 | Đổi tên `chain:N` → `scatter:N` | Nhỏ, **làm ngay** |
| §B5 | Level-up **KHÔNG thay mặt** — nâng bậc 2-3 mặt hiện có. Bỏ toàn bộ logic thay part khi lên tier | Vừa |
| §B7 | Gene Mutation đề nghị part có tên thật | Nhỏ, giá trị lớn |
| `sim.js` | **Chạy lại toàn bộ** — hệ 4 bậc đổi cơ bản đường cong DPS; cộng thêm định giá slot Lead (`ECONOMY` §9) | **Lớn** |
| UI | Tên part + art trên mặt; tooltip; chỉ báo chain/combo; **quản lý cognitive load** | **Lớn — xem §9 #1** |
| Art | Asset part tách lớp + pipeline slugify | **Rủi ro — §9 #5** |

---

## 9. RỦI RO & VIỆC CẦN CHỐT

Bốn rủi ro đầu **không có trong v1.0** — chúng do vòng kiểm chứng độc lập bổ sung, và hai trong số đó nghiêm trọng hơn mọi rủi ro đã liệt kê trước đó.

| # | Rủi ro | Mức | Xử lý |
|---|---|---|---|
| 1 | **Cognitive load / legibility.** Doc đề xuất **192 part × 4 bậc ≈ 768 cấu hình mặt** có tên riêng + 27 keyword, cho một game **gán xúc xắc**. Phương án A **nhân** tải nhận thức lên, không giảm. Đây là rủi ro có thể giết game **cao hơn** rủi ro IP — vì rủi ro IP chặn dự án trước khi tốn tiền, còn cái này để dự án ship ra rồi mới chết. | 🔴 | Bộ sưu tập khởi đầu 60 part (`ECONOMY` §2) là điều kiện cần nhưng **chưa đủ**. Cần thêm: giới thiệu bloodline **theo lớp** qua meta-unlock; mặt hiển thị **icon + số trước, tên sau**; bậc hiển thị bằng **màu viền**, không bằng chữ; và **playtest legibility là tiêu chí ship, không phải nice-to-have** |
| 2 | **Bloodline đẩy build hội tụ.** Bloodline độc quyền 32 part là một incentive mono-class luôn bật, và sau khi bỏ Universal pool thì Meta Morph là van xả duy nhất. *(BLOODCHAIN đã gác lại — rủi ro hạ từ 🔴 xuống 🟠.)* | 🟠 | Meta Morph phải **luôn có mặt**, không hiếm (§5.5). Nghiệm thu bằng **archetype diversity trong sim**, không phải winrate. Nếu diversity sụt, tăng tần suất Meta Morph trước khi động vào Bloodline |
| 3 | **IP bên thứ ba nằm trong chính tên part.** Danh sách Mystic có **Hasagi** (Yasuo — Riot), **Namek Carrot** (Namek — Dragon Ball), **Pinku Unko**; dòng japan có Kabuki, Geisha, Dango. Sky Mavis dùng được vì đó là skin cosmetic trong game của họ; đưa lên làm **tên tầng power cao nhất kèm VFX màn hình chớp trắng** ở một game khác là mức phơi nhiễm khác. | 🟠 | **Legal review riêng**, không gộp vào "xin duyệt IP nội bộ" |
| 4 | **Kỳ vọng quyền sở hữu của cộng đồng Mystic.** Người **đã** mua Mystic (giá cao, nguồn cung đóng) sẽ hỏi: *"tôi sở hữu Hasagi on-chain, sao trong Dice ai cũng roll ra được?"* | 🟠 | Chuẩn bị câu trả lời **trước khi ra mắt**, không phải sau. Một hướng: chủ sở hữu Mystic thật nhận **skin/khung/hiệu ứng riêng** cho mặt tương ứng — zero power, đúng nguyên tắc Web3 đã thống nhất, và biến rủi ro thành lợi ích |
| 5 | **Quyền IP dùng tên + art part** | 🔴 | Nội bộ Sky Mavis nên khả thi, nhưng **phải là yêu cầu chính thức, chốt trước khi build.** Cả chiến lược content đứng trên giả định này |
| 6 | **Asset part có tách lớp được không** | 🟠 | Axie render là composite từ layer part → về lý thuyết có. **Xác nhận với team art trước.** Dự phòng: mặt dùng icon crop nhỏ thay vì render đầy đủ |
| 7 | Chain/combo phá đường cong đã tune | 🟠 | Bonus cộng có trần, chạy lại sim trước khi ship (§4.3) |
| 8 | Copy nhầm số liệu Origins | 🟠 | Effect text chỉ là **tham chiếu định tính**; số do sim quyết định. Ghi thành luật quy trình |
| 9 | **Thời lượng lượt tăng.** Reroll trở thành công cụ theo đuổi → người chơi tính lâu hơn → run dài ra. Trên mobile, thời lượng run là chỉ số retention | 🟠 | Đo thời lượng lượt trong playtest; cân nhắc gợi ý combo tự động cho người chơi mới |
| 10 | Dữ liệu khuyết: 13 part không có card text (Bird·Ears ×6, Bug·Ears ×6, Plant·Lotus) | 🟢 | Lấy từ team Origins nội bộ, đừng đoán |
| 11 | Nguồn là package cộng đồng, không phải API chính thức | 🟢 | Đối chiếu một lần với bảng part chính thức |
| 12 | Trùng tên giữa slot · ký tự bẩn (`?`, `✨`) | 🟢 | Khoá bằng `partId`; thêm bước slugify |
| 13 | Special-gene lệch class | 🟢 | Ma trận §7.1; mỗi season ghép part + mutation + relic |

### Sáu quyết định cần chốt trước khi build

1. **Xin được quyền dùng tên + art part chưa?** — Blocker số một. Không có nó, doc này chỉ là bài tập.
2. **COMBO đi theo phương án (a) nhiều mặt trên một hero, hay (b) theo mục tiêu?** — Đây là **thay đổi mô hình**, không phải một hàm. Chốt trước khi viết dòng code nào. Khuyến nghị: (a).
3. **Chain/Combo vào S0 hay S1?** — Khuyến nghị **S0**. Nhét vào sau sẽ phải tune lại toàn bộ đường cong lần thứ hai.
4. **Mystic là tầng mạnh nhất, hay giữ thuần cosmetic đúng canon?** — Khuyến nghị: mạnh nhất. Nhưng đây là quyết định thương hiệu, gắn với rủi ro #3 và #4, phải do người có thẩm quyền chốt.
5. **Team art xác nhận part sprite tách lớp được không?** — Quyết định giữa "render đầy đủ" và "icon crop".
6. **Ngân sách playtest legibility.** — Rủi ro #1 là 🔴 và mitigation duy nhất là playtest người thật. Nếu không có ngân sách cho nó, phải cắt scope số lượng mặt xuống.

---

## PHỤ LỤC A — Tệp dữ liệu

- **`bloodlines.json`** — 228 entry: 6 bloodline × 32 part core + 6 Mystic mỗi class, cấu trúc sẵn cho `data.js`, khoá bằng `partId`. Đã kiểm khớp 100% với nguồn.
- **`AXIE_BODY_PARTS_DB.md`** — 192 part core **kèm card text Origins** (**179/192** có effect) + 81 part đặc biệt **chỉ có tên, không có card text**.

**Nguồn:** `agp-npm` v1.0.11 → `package/dist/assets/parts.json`
Tải lại: `https://registry.npmjs.org/agp-npm/-/agp-npm-1.0.11.tgz`

**Khoảng trống dữ liệu đã biết (13 part):** Bird·Ears ×6 (Curly, Early Bird, Owl, Peace Maker, Pink Cheek, Risky Bird) · Bug·Ears ×6 (Beetle Spike, Ear Breathing, Earwing, Larva, Leaf Bug, Tassels) · Plant·Ears Lotus. Tên chắc chắn đúng, chỉ thiếu effect text.

---

## PHỤ LỤC B — Nhật ký sửa v1.0 → v1.1

Doc v1.0 đã qua một vòng kiểm chứng độc lập đối chiếu từng dòng với `parts.json`. **Nền dữ liệu đúng 100%** — cấu trúc 6/6/6/6/4/4, ma trận Mystic 6×6, 7 tên trùng, phân bố special-gene, toàn bộ 20 dòng §3.2, và `bloodlines.json` đều kiểm được từng dòng. Lỗi nằm ở tầng **diễn giải** và **thiết kế**:

| # | Lỗi v1.0 | Sửa ở v1.1 |
|---|---|---|
| 1 | Headline "273 mặt có bản sắc" — thổi phồng 42%; 81 part đặc biệt là skin, không có cơ học | §0 tách rõ 192 cơ học / 81 cosmetic |
| 2 | Bán Mystic như "món quà miễn phí" — thực tế cả 36 hiệu ứng phải tự thiết kế | §5.3 nêu rõ chi phí 3-4 person-week |
| 3 | Khẳng định part-type khớp 1:1 vocabulary die — 13/20 ví dụ của chính doc phản bác | §1.1 mới: cardinality khớp, semantics không |
| 4 | COMBO định nghĩa toàn đội → trùng với BLOODCHAIN, hai trục "vuông góc" thực ra là một | §4.1 đổi COMBO thành **per-hero**; thêm §4.3 bốn ràng buộc |
| 5 | Nimo bị gán sai là part `resonance` | §5.4 sửa; `resonance` chỉ còn n=1 (Anemone) |
| 6 | "Nut Cracker 3 slot đều thưởng combo" — Ears thực ra là "+6 Damage" | §5.4 sửa thành 2/3 slot |
| 7 | 4/5 nguồn của `bloodchain` sai (Koi=combo, Little Branch=cross-class, Spear=tag Lunge) | §3.3 đếm lại còn 12 keyword; đánh dấu n=1 |
| 8 | "7/9 season dùng asset có sẵn"; S7 Evolution dán nhãn "×2 pool có sẵn" | §7 sửa thành 6/9; S7 thu hẹp còn 36 part, đánh dấu 🔴 |
| 9 | Cảnh báo lệch class thiếu Bird, thiếu Aqua, đếm nhầm do biến thể ✨ | §7.1 thêm ma trận đầy đủ |
| 10 | §4 nói "2-3 ngày dev", §8 nói "sim phải chạy lại — Lớn" | §4.4 thống nhất ~4-6 tuần |
| 11 | Phóng đại "class duy nhất", "cả một class"; Blue Moon gán sai là anti-Last-Stand | §5.4 hạ giọng, thêm cột độ chắc |
| 12 | Phụ lục A ghi "273 part kèm card text"; sai số 180/192 | Sửa thành 192 kèm text (179/192) + 81 chỉ tên |
| 13 | Dẫn số thị trường Mystic (6,3 ETH · 1.337 Axie) không có nguồn trong dữ liệu | Bỏ số, giữ định tính |
| 14 | §9 thiếu 4 rủi ro lớn (legibility, hội tụ do chain, IP bên thứ ba, kỳ vọng chủ sở hữu Mystic) | §9 viết lại, 13 rủi ro, 2 cái 🔴 mới |
