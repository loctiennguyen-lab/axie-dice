# ECONOMY & PROGRESSION — Design Spec v2.0
### Axie Dice Tactics · Chế độ chơi chính

> **Bản hợp nhất.** Thay thế `ECONOMY_AND_PROGRESSION_v1.md`. Thân doc chỉ chứa thiết kế hiện hành; lịch sử sửa đổi nằm ở Phụ lục C.
> Doc liên quan: `BLOODLINE_SYSTEM_v1.md` (v1.2 — hệ part → mặt xúc xắc) · `AUDIT_AND_SPEC_v1.md` (engine + đường cong độ khó) · `AXIE_BODY_PARTS_DB.md` + `bloodlines.json` (dữ liệu part).

---

## 0. CÁCH ĐỌC DOC NÀY

Mỗi mục thiết kế mang một trong ba nhãn:

| Nhãn | Nghĩa | Anh cần làm gì |
|---|---|---|
| ✅ **CHỐT** | Anh đã duyệt trong quá trình làm việc | Không cần làm gì |
| ⬜ **CẦN DUYỆT** | Tôi tự quyết, cần anh thông qua hoặc phủ quyết | **Đọc §1, tick hoặc bác** |
| 🔬 **CẦN SIM** | Không ai quyết được bằng lý luận — phải chạy `sim.js` | Cấp nguồn lực, không cần quyết bây giờ |

**Nếu anh chỉ có 10 phút: đọc §1.** Toàn bộ việc cần anh làm nằm ở đó.

---

## 1. BẢNG QUYẾT ĐỊNH

### 1.1 Đã chốt — không cần đọc lại ✅

| # | Nội dung |
|---|---|
| C1 | **Quyền dùng tên + art part Axie** — được phép |
| C2 | **PvP = Gauntlet bất đồng bộ**, không làm PvP realtime |
| C3 | **Kiến trúc A cho core loop** (nâng cấp theo chiều ngang); kiến trúc B (nâng NFT theo chiều dọc) chỉ dùng cho mode riêng, **đã gác lại** |
| C4 | **Vòng lặp lai**: chọn sẵn Lead Axie trước run + nâng cấp trong run |
| C5 | **Chấp nhận rủi ro** người sở hữu NFT mạnh hơn |
| C6 | **Phương án A** — rarity nằm ở tầng RUN, bộ sưu tập chỉ mở khoá danh tính |
| C7 | **Hệ CHAIN/COMBO gác lại**, không nằm trong scope build |

### 1.2 Đã duyệt 2026-09-01 ✅ — 16 mục

> **Đồng bộ với `build-spec.md`**: toàn bộ D1-D16 dưới đây đã được duyệt (product owner, 2026-09-01) — trước đó doc này còn đánh dấu ⬜ CẦN DUYỆT trong khi `build-spec.md` đã ghi "đã được duyệt", hai nguồn nói ngược nhau (phát hiện ở `docs/review-2026-08-31.md` mục hành động #3). Giờ khớp nhau: **cả 16 mục đều ✅ CHỐT.**

Mỗi dòng: **quyết gì · vì sao · nếu bác thì sao** (giữ nguyên nội dung gốc để tham chiếu).

| # | Quyết định | Lý do | Nếu bác |
|---|---|---|---|
| **D1** | **Phase 1 chỉ ra mắt WEB**, mobile sang Phase 2 (tháng 4-6) | Anh nói muốn cả web + mobile trong 3 tháng. Store review, IAP compliance, tax, ASO, mobile UX — không nén được. Web còn tốt hơn cho mục tiêu pitch: không mất 30% store tax, deploy hàng ngày, có số ngay tuần đầu | Phải kéo dài Phase 1 lên ~5 tháng, hoặc cắt Gauntlet + Mastery |
| **D2** | **Ra mắt với 1 slot Lead Axie, trần cứng 2**, không bao giờ có 3 | Chưa định giá được (🔬 S1), nên chọn thận trọng. Slot 2 mở bằng chơi, **không bán bằng tiền** | Nếu muốn 3+ slot thì draft roguelike mất nghĩa; phải thiết kế lại §6 |
| **D3** | **Bậc MYTHIC hoãn sang Phase 2** | 3-4 person-week hiệu ứng mới hoàn toàn; đi cùng lớp NFT vốn đã ở Phase 2; không chặn ngày ra mắt | Phase 1 đội thêm 3-4 pw, hoặc cắt Mastery |
| **D4** | **Mythic gắn với cặp `class × slot`**, không gắn với từng part | 36 Mystic khớp đúng 6 class × 6 slot. Nếu gắn theo part thì cần một bảng ánh xạ không tồn tại trong dữ liệu, và mỗi class chỉ có 6/32 part "có số phận" | Phải tự soạn bảng ánh xạ 36 dòng và chấp nhận 26 part ngõ cụt mỗi class |
| **D5** | **Gene Mutation hạ mặt về COMMON** khi đổi danh tính | Nếu bảo toàn bậc, người chơi đẩy bất kỳ mặt nào lên Legendary rồi Mutate ngay trước boss ⇒ "giữ part suốt run" thành zero-cost | Mất cơ chế đánh đổi; Mutation thành reroll miễn phí |
| **D6** | **Bậc COMMON vẫn có keyword đặc trưng** (giá trị tối thiểu), không phải số trần | Nếu Common là số trần thì đầu mỗi run cả 30 mặt vô danh tính, và 6 bản sắc class — thứ đắt giá nhất của hệ Bloodline — chỉ bật sau lần lên tier đầu | Bản sắc class thành phần thưởng giữa run, không phải trải nghiệm mở đầu |
| **D7** | **Tài khoản mới mở sẵn 60 part** (10/class) | Không có thì người mới chỉ gặp ~16 hình dạng Axie trong nhiều giờ đầu — thất bại onboarding | Phải giải bài đa dạng early game bằng cách khác |
| **D8** | **Axie Forge có 3 ràng buộc**: đúng 1 part/slot · đơn class · luôn bậc Common | Không có thì forge được Axie 6 mặt Horn hoặc 6 `Anemone` (resonance cực đại từ T1), và splash off-class miễn phí vĩnh viễn — vô hiệu hoá Meta Morph | Forge phải được đưa vào mô hình power, không còn là "hành vi sưu tầm" |
| **D9** | **Cắt mốc Mastery M5** (part xuất hiện thường xuyên hơn); thêm cơ chế **Pin** | M5 là mốc duy nhất bán được sức mạnh; nó **tự triệt tiêu** khi mọi part đạt M5; và giai đoạn nó có tác dụng thì nó đẩy hội tụ build | Giữ M5 ⇒ phải bỏ SKU "tăng tốc Mastery" và chấp nhận nó vô nghĩa ở endgame |
| **D10** | **Giá part phẳng ~400 Shard** cho mọi part | Hệ quả trực tiếp của C6: bộ sưu tập chỉ chứa danh tính nên không có cớ định giá theo sức mạnh | Nếu định giá theo rarity thì đã quay lại phương án B |
| **D11** | **Không bán skin Mystic**; art Mystic nguyên bản **độc quyền chủ NFT** | Hai lý do: cam kết với người đã mua Mystic thật, và rủi ro IP bên thứ ba (**Hasagi** = Yasuo/Riot, **Namek Carrot** = Dragon Ball) | Mất một dòng doanh thu; cần legal review nếu vẫn muốn bán |
| **D12** | **Bốn luật cứng economy** (§10.2) | Chống pay-to-win và bảo vệ vòng lặp lõi | Xem chi tiết từng luật ở §10.2 |
| **D13** | **Mục tiêu Phase 1: conversion ≥3% · ARPDAU ≥$0.02** | Con số cũ (2% / $0.05) hàm ý ARPPU $75/tháng ⇒ mỗi payer mua 12-15 gói cosmetic mỗi 6 tuần, bất khả thi với catalogue ~15 SKU | Phải mở rộng catalogue hoặc thêm SKU chiều sâu (tức đụng vào D12) |
| **D14** | **Ngân sách S0 = 8-12 person-week**, tách khỏi ngân sách season thường (4-6 pw) | S0 là launch, không phải season: 4 bậc × 192 part (3-4 pw) + chuyển thể 192 card text + 12 keyword mới | Phải cắt scope S0 hoặc chấp nhận trượt lịch |
| **D15** | **Secret class chỉ rút 3/6 slot từ mỗi bloodline bố mẹ**, và chọn **một** trong hai hiệu ứng Mythic | BLOODCHAIN — đối trọng cũ — đã gác lại. Không có đối trọng mới thì Dusk/Mech/Dawn là "pool 64 part, không nhược điểm" | Secret class thành nâng cấp thuần; phải cân bằng bằng cách khác |
| **D16** | **Mỗi lần trao thưởng 3 lựa chọn, tối đa 2 cùng archetype** | Chặn cấu trúc cho kịch bản mở khoá lệch hẳn về một build rồi mọi offer đều rơi trúng nó | Phải chặn nở lệch bằng cách khác (giới hạn tỷ lệ pool) |

### 1.3 Cần sim, không cần anh quyết bây giờ 🔬

| # | Câu hỏi | Vì sao không tự trả lời được | Chặn cái gì |
|---|---|---|---|
| **S1** | **Slot Lead Axie đáng giá bao nhiêu winrate?** | Mô hình của tôi không mô phỏng đội hình. Mọi con số tôi từng đưa ra cho Lead đều là hàm của một hằng số tự đặt, dao động +14% → +120% | D2. Nếu vượt +25% tương đối ⇒ hạ về 1 slot vĩnh viễn |
| **S2** | **Nở lệch archetype có thành sức mạnh không?** | Mô hình tôi cho −2%; audit độc lập cho +35% với hình dạng lệch khác. Chưa ai đúng | D16, và mức độ hào phóng của Collector Bundle |
| **S3** | **Sink đầu cuối** — sau 192 part + 768 mốc Mastery thì tiêu Shard vào đâu? | Cần mô hình economy theo thời gian, chưa dựng | Ship Phase 1 |
| **S4** | **Hiệu chuẩn faucet/sink** — con số ở §10.3 là dải khởi điểm | Cần đo trên engine thật | Ship Phase 1 |

---

## 2. TÓM TẮT KIẾN TRÚC

Game hiện có một vòng lặp duy nhất: một run 20-30 phút. Không có lý do quay lại ngày mai, không có gì để sở hữu, không có gì để bán. Doc này thêm **vòng ngày/tuần** và **vòng mùa**, rồi đặt monetization vào đúng chỗ chúng.

Bốn câu:

1. **Một Axie = một viên xúc xắc.** Sáu part của nó là sáu mặt. Ánh xạ 1:1 với tài sản đã có trên chain.
2. **Bộ sưu tập mở khoá DANH TÍNH của part, không mở khoá SỨC MẠNH.** Mọi part vào run ở bậc Common. Bậc kiếm được **trong** run và mất khi run kết thúc.
3. **Người chơi mang một Lead Axie chọn sẵn**, bốn chỗ còn lại tuyển dọc đường, mọi Axie lên bậc trong run.
4. **Nâng cấp part vĩnh viễn không cộng chỉ số — nó mở khoá biến thể.**

---

## 3. LUẬT GỐC — hai tầng ✅ C6

> **TẦNG SƯU TẦM** (vĩnh viễn, sở hữu được) → **BỀ RỘNG**: part nào có thể xuất hiện, Axie nào mang theo được, skin nào hiển thị.
>
> **TẦNG RUN** (tạm thời, reset mỗi ván) → **SỨC MẠNH**: tier hero, bậc của mặt, giá trị số, keyword, relic, gene mutation.

Mọi tính năng phải khai báo nó thuộc tầng nào. **Một tính năng đứng hai chân là lỗi thiết kế, không phải thoả hiệp.**

Một ngoại lệ có chủ đích và đã được duyệt: **Lead Axie** cho phép tầng sưu tầm chạm vào bản sắc khởi đầu. Nó được cô lập, giới hạn ở 1-2 slot, và phải đo (🔬 S1).

**Vì sao luật này đáng giá:** nó là thứ duy nhất cho phép bật lớp NFT ở Phase 2 mà **không cần cân bằng lại một dòng nào** — vì NFT chỉ đổ vào bề rộng. Nếu vi phạm luật này ở bất kỳ đâu, lời hứa đó mất hiệu lực.

---

## 4. MỘT AXIE = MỘT VIÊN XÚC XẮC

Mọi Axie đều có đúng sáu part: **mouth · horn · back · tail · eyes · ears**. Sáu part đó là sáu mặt.

```
Axie #12345  (Beast)              — mọi Axie vào run ở bậc COMMON
┌───────────┬───────────┬──────────┬───────────┬─────────┬─────────┐
│   MOUTH   │   HORN    │   BACK   │   TAIL    │  EYES   │  EARS   │
│Nut Cracker│Dual Blade │  Ronin   │Cottontail │  Zeal   │  Nyan   │
│  dmg 5    │ dmg 6·crit│ dmg 6    │ mana 1    │ heal 3  │ mana 1  │
└───────────┴───────────┴──────────┴───────────┴─────────┴─────────┘
```

> 🔧 **`Ronin` là part damage/crit, không phải shield.** Card text thật: *"Guaranteed crit when comboed with 2+ cards"*. Cùng nhóm với `Furball` (đánh 3 lần) và `Risky Beast` — Back nhưng không phải shield. **Loại part quyết định tên và art, không quyết định vai trò cơ học** (`BLOODLINE` §1.1).

**Không gian tổ hợp:** 6⁴ × 4² = **20.736 tổ hợp mỗi class · 124.416 trên toàn game**. Rất lớn nhưng **hữu hạn** — với 5 hero mỗi run, trùng lặp là bình thường và không nên hứa điều ngược lại.

**Sinh Axie trong run:** tuyển một Axie mới → bốc 6 part từ pool đã mở khoá của class đó, **toàn bộ ở bậc Common**. Bộ sưu tập rộng → Axie đa dạng hơn, **không mạnh hơn**.

### ⬜ D7 — Bộ sưu tập khởi đầu 60 part

Tài khoản mới được mở sẵn **10 part mỗi class**, chọn sao cho mỗi class có ít nhất hai nhánh chơi khác nhau.

Không có nó, người mới chỉ có tầng Common với pool cực hẹp và gặp khoảng **16 hình dạng Axie** trong nhiều giờ đầu tiên. Đây là điều kiện onboarding, không phải quà tặng.

---

## 5. BẬC CỦA MỘT PART ✅ C6

Mỗi part tồn tại ở **mọi bậc**, theo một mẫu leo thang chung. Bậc là thuộc tính của **mặt xúc xắc trong ván đó**.

| Bậc | Quy tắc | Ví dụ — `Bumpy` (Reptile · Horn) |
|---|---|---|
| COMMON | Hiệu ứng gốc + **keyword đặc trưng ở giá trị tối thiểu** | shield 4 · `shieldregen:3` |
| RARE | Giá trị tăng | shield 6 · `shieldregen:5` |
| EPIC | Keyword đầy đủ theo card text thật | shield 8 · `shieldregen:8` |
| LEGENDARY | Giá trị lớn + 1 keyword phụ | shield 12 · `shieldregen:10` · `share:3` |
| **MYTHIC** | Hiệu ứng phá luật của cặp `class × slot` | + ⟨`PINKU UNKO`⟩ |

**⬜ D6 — Common phải có keyword.** Nếu Common là số trần thì đầu mỗi run cả 30 mặt trên bàn đều vô danh tính, và vì **cả sáu bản sắc class đều được định nghĩa bằng keyword**, không class nào phân biệt được với class nào trong nửa đầu run. Gradient nằm ở **giá trị số + keyword phụ**, không ở việc *có hay không có* keyword.

**Đường lên bậc trong run:** tier-up hero (T1→T2→T3 nâng bậc 2-3 mặt) · Gene Mutation · relic · item · node sự kiện.

**Điều kiện sống còn:** mọi part **ở cùng một bậc** phải nằm trong cùng ngân sách sức mạnh (**±10%**). Vi phạm là đưa gradient trở lại tầng sưu tầm và huỷ toàn bộ kiến trúc. Phải kiểm **tự động trong CI**, không phải review thủ công.

### ⬜ D4 · D3 — Bậc MYTHIC

> Mỗi cặp (class, slot) có **đúng một hiệu ứng Mythic phá luật**, mang tên và art của Mystic part tương ứng. **Bất kỳ** part nào của class đó, ở slot đó, khi đạt LEGENDARY, đều có thể lên MYTHIC và nhận hiệu ứng ấy.
>
> Mặt **giữ nguyên `partId` và tên gốc**, hiển thị thêm huy hiệu: `RONIN ⟨HASAGI⟩`.

Ma trận Mystic là 6 class × 6 slot — khớp chính xác, **không cần bảng ánh xạ nào**. Mọi part đều có đường lên bậc cao nhất.

**Nguồn nâng lên Mythic:** chỉ qua nguồn hiếm trong run — node **Bể Đột Biến**, boss reward, relic chuyên dụng. ⇒ Mythic là **thành tựu trong ván**, không phải tài sản mang theo. Ai cũng có cơ hội; không ai mua được.

**⬜ D3 — hoãn sang Phase 2.** 36 hiệu ứng "phá luật" là 3-4 person-week hoàn toàn mới (Mystic part trong Axie là **skin thuần**, không có card effect để chuyển thể). Nó đi cùng lớp NFT vốn đã ở Phase 2.

---

## 6. VÒNG LẶP LAI ✅ C4

```
TRƯỚC RUN  │ Chọn 1 LEAD AXIE từ bộ sưu tập (hoặc từ ví, Phase 2)
           │ Chọn Ascension · xem Daily Mutation
           ▼
TRONG RUN  │ 4 chỗ còn lại tuyển dọc đường
           │ Mọi Axie — kể cả Lead — lên bậc: tier-up · Gene Mutation · relic · item
           ▼
SAU RUN    │ Gene Shard · Mastery cho part đã dùng · Battle Pass
           │ Build cuối đóng băng vào pool Gauntlet
```

**Lead Axie vào run ở bậc Common, giống hệt mọi hero khác.** Thứ người chơi mang theo là **sáu danh tính part** — tên, art, bản sắc — chứ không phải chỉ số. Muốn mạnh vẫn phải chơi.

**Luật lên tier:** lên tier **nâng bậc các mặt hiện có**. Engine **không bao giờ** thay `partId` khi lên tier. Danh tính Lead được bảo toàn suốt run — nếu không, người chơi mất đúng thứ họ mang theo, đúng vào lúc đáng nhớ nhất.

**⬜ D5 — Gene Mutation là cơ chế đổi danh tính duy nhất, và nó hạ mặt về COMMON.** Nếu Mutation bảo toàn bậc, người chơi chỉ cần đẩy *bất kỳ* mặt nào lên Legendary rồi Mutate ngay trước boss — mọi mục tiêu "giữ part suốt run" thành zero-cost.

**⬜ D2 — 1 slot Lead khi ra mắt, trần cứng 2.** Slot thứ hai là một trong những phần thưởng meta lớn nhất, mở **bằng chơi**, không bán bằng tiền. Không bao giờ có slot thứ ba.

> 🔬 **S1 — chưa định giá được.** Mô hình của tôi không mô phỏng đội hình nên mọi con số nó đưa ra cho Lead đều là hàm của một hằng số tự đặt (dao động +14% → +120% khi đổi tham số). Trần 2 là **quyết định thận trọng chưa có số hậu thuẫn**. Ngưỡng nghiệm thu ở §13.

---

## 7. BỘ SƯU TẬP

**Đơn vị mở khoá là PART, và cái được mở là DANH TÍNH.** 192 part core là các nguyên tử; một Axie chỉ là một tổ hợp sáu part.

```
BỘ SƯU TẬP
├── Part đã mở khoá   (theo class × slot)      → Axie sinh ra thế nào
├── Axie đã lưu       (tổ hợp 6 part, đặt tên) → ứng viên slot Lead
├── Mastery từng part (§8)                     → biến thể + skin
└── Skin & khung      (cosmetic thuần)
```

### Ba đường vào, cùng đổ vào bề rộng

| Đường | Phase | Ghi chú |
|---|---|---|
| **Chơi** — Gene Shard → mở part | 1 | Đường chính. Không cần ví |
| **Sở hữu NFT** — có Axie thật → mở ngay 6 part của nó | 2 | Cho **tốc độ**, không cho sức mạnh. *Axie Mystic mở khoá part core cùng class·slot, cộng art Mystic nguyên bản cho slot đó* |
| **Mua** — Moon Dust mở nhanh, bundle theo season | 1 | Chỉ bán tốc độ và cosmetic |

### ⬜ D8 — Axie Forge và ba ràng buộc

Người chơi ghép 6 part đã mở thành một Axie đặt tên được, lưu vào bộ sưu tập, dùng làm Lead. Đây là hành vi sưu tầm cốt lõi — nhưng nếu để tự do, nó là lỗ khai thác nghiêm trọng:

| Ràng buộc | Không có thì sao |
|---|---|
| **Đúng 1 part mỗi slot** | Forge được Axie 6 mặt Horn, hoặc 6 `Anemone` — mà `Anemone` là *"restore 50 HP for each Anemone part"*, tức resonance cực đại vĩnh viễn ngay từ T1 |
| **Đơn class** (hoặc hybrid theo luật secret class) | Splash off-class **miễn phí và vĩnh viễn**, vô hiệu hoá hoàn toàn Meta Morph — van xả có kiểm soát duy nhất |
| **Chỉ part đã mở khoá, luôn ở bậc Common** | Hệ quả bắt buộc của C6. Đây là thứ đóng kênh power creep "bề rộng × Forge" (§12) |

---

## 8. MASTERY ⬜ D9

Dùng một part trong run → part đó tích Mastery. Mastery **không** làm nó mạnh hơn.

| Mốc | Số lượt dùng | Mở khoá | Tầng |
|---|---|---|---|
| M1 | 15 | **Biến thể A** — cùng ngân sách, khác keyword | bề rộng |
| M2 | 40 | Collection Log + khung hiển thị | cosmetic |
| M3 | 90 | **Biến thể B** — nhánh chơi thứ ba | bề rộng |
| M4 | 180 | **Skin Mastery** (visual riêng, **không phải** Mystic) | cosmetic |

**Ghim part (Pin).** Người chơi ghim 1 part → part đó nhận Mastery gấp đôi. Không có nó, Mastery là grind thuần RNG không tối ưu hoá được — người chơi không chọn được part nào được offer nên đuôi coupon-collector kéo dài vô tận. Pin cho quyền chủ động mà không cho sức mạnh.

**Nhịp:** ~30 lượt dùng mặt mỗi run. M1 của một part hay dùng đến sau ~8-12 run; M4 là mục tiêu hàng trăm giờ. **192 part × 4 mốc = 768 mốc tiến trình** — đuôi dài giữ người chơi ở tháng 6 và 12, đúng lỗ hổng content cadence.

**Vì sao cách này đúng:** nó **đúng canon Axie** (*Parts Evolution / Level-2 card* là mở khoá phiên bản khác, không cộng chỉ số), và nó **bán được mà không bẩn** — bán tăng tốc, skin, slot Pin; người trả tiền **đi nhanh hơn, không mạnh hơn**.

---

## 9. LỚP NFT (Phase 2) ✅ C5

Sở hữu một Axie thật → **mở khoá ngay 6 part của nó** vào bộ sưu tập, cộng khung/skin riêng.

Vì đường này chỉ đổ vào **bề rộng**, bật nó ở Phase 2 **không cần cân bằng lại một dòng nào**. Đây là toàn bộ lý do luật §3 đáng giá.

### ⬜ D11 — Mystic: hai vật thể tách bạch

| | Ai có | Áp ở đâu |
|---|---|---|
| **Hiệu ứng Mythic** (mang tên Mystic) | Ai cũng chạm tới được trong run | Chỉ bậc Mythic. Người chơi thường thấy biến thể *awakened* chung |
| **Art Mystic nguyên bản** (art NFT thật, khung, VFX) | **Chỉ chủ sở hữu Axie Mystic on-chain** | **Mọi bậc**, không chỉ Mythic |

Đây là câu trả lời cho *"tôi sở hữu Hasagi on-chain, sao trong Dice ai cũng có?"* — họ nhận đúng thứ đã mua: **sự khan hiếm nhìn thấy được**, vĩnh viễn và độc quyền. Sức mạnh thì ai cũng phải chơi mới có.

**Không bán skin Mystic ở cửa hàng.** Hai lý do: cam kết trên, và **rủi ro IP bên thứ ba** — danh sách Mystic có **Hasagi** (Yasuo — Riot) và **Namek Carrot** (Dragon Ball). Biến những cái tên đó thành SKU $2-8 là mức phơi nhiễm pháp lý cao nhất có thể.

---

## 10. TIỀN TỆ VÀ ECONOMY

### 10.1 Ba lớp

| Tiền | Kiếm bằng | Tiêu vào | Bán? |
|---|---|---|---|
| **Gene Shard** (mềm) | Run, wave, thành tựu, daily | Mở part · Pin · Forge · reroll cửa hàng · cosmetic hạng thường | ❌ |
| **Moon Dust** (cứng) | Mua · nhỏ giọt qua BP free track | Cosmetic · Battle Pass · slot Forge · **mở part trực tiếp** | ✅ |
| **Gauntlet Ticket** | 3 vé/ngày miễn phí · BP · mua | Vào **seed mới** của chế độ có thưởng | ✅ |

### 10.2 ✅ D12 — Bốn luật cứng (đã duyệt 2026-09-01, luật 2 có sửa đổi có phạm vi)

1. **Không bao giờ gate run thường bằng năng lượng hay vé.** Đây là đề xuất C-Level sẽ đưa ra đầu tiên và anh phải có sẵn lập luận: roguelike sống nhờ khoảnh khắc *"thua rồi, chơi lại ngay"* — chặn đúng chỗ đó là chặn chính vòng lặp gây nghiện.
2. **Không bán chỉ số bằng tiền.** Không part mạnh hơn mua được bằng Shard/Moon Dust, không mặt giá trị cao hơn mua được, không gacha cầu sức mạnh.
   > ⚠️ **Sửa đổi có phạm vi, 2026-09-01**: product owner đã chủ động chấp nhận một ngoại lệ **hẹp và có công thức rõ ràng** cho luật này — xem **§10.2a NFT HP Bonus** ngay dưới đây. Đây KHÔNG phải một cánh cửa mở cho các SKU bán chỉ số khác trong tương lai; nó là một ngoại lệ đơn, gắn chặt với việc sở hữu Axie NFT thật (không mua được bằng Shard/Moon Dust trong game), và có trần rõ ràng. Bất kỳ đề xuất bán chỉ số nào khác vẫn bị luật này cấm như cũ.
3. **Gene Shard không mua được, và không có tỷ giá Moon Dust ↔ Shard.** Moon Dust mở part **trực tiếp**, không đi vòng qua Shard. Mỗi SKU chỉ định giá bằng **một** loại tiền.
4. **Vé Gauntlet mua seed mới, không mua lượt thử lại.** Mỗi seed chỉ chơi một lần dù có bao nhiêu vé. Không có luật này, engine seeded RNG biến vé thành **lợi thế bảng xếp hạng mua được**.

### 10.2a NFT HP Bonus (mới, 2026-09-01 — ngoại lệ có phạm vi của luật 2)

Bổ sung cho quyền chọn-trước ở §G8 (`AUDIT_AND_SPEC_v1.md`): mỗi Axie NFT được chọn-trước vào đội hình (không áp dụng cho Axie tuyển ngẫu nhiên giữa run) nhận thêm **bonus maxHP**, quy mô theo số lượng NFT sở hữu và độ hiếm của chính con Axie đó — theo đúng yêu cầu "vừa, theo tỷ lệ sở hữu và độ hiếm".

```
HP_bonus_% = base × ownership_mult × rarity_mult, cap tại BONUS_CAP
```

| Biến | Ký hiệu | Giá trị | Ghi chú |
|---|---|---|---|
| Bonus cơ sở / Axie chọn-trước | `base` | 3% maxHP | Tương đương độ lớn 1 mức Ascension đơn lẻ (vd. Ascension 1 = "+10% HP địch") — cùng thang đo với hệ khó đã có, không phát minh thang mới |
| Hệ số theo số NFT sở hữu | `ownership_mult` | 1.0× (1-4 con) · 1.25× (5-19 con) · 1.5× (20+ con) | Bậc thang 3 mức, không tuyến tính vô hạn — tránh whale-scaling không giới hạn |
| Hệ số theo độ hiếm Axie (số Special Gene thật — thuộc tính có sẵn của Axie Infinity, 0-3) | `rarity_mult` | 1.0× (0 gene) · 1.15× (1 gene) · 1.3× (2 gene) · 1.5× (3 gene) | Dùng thuộc tính đã tồn tại trên chain, không cần định nghĩa "độ hiếm" mới |
| Trần tổng | `BONUS_CAP` | **+20% maxHP** / Axie | Chặn worst-case: 3% × 1.5 × 1.5 = 6.75% thực tế còn xa trần — trần chỉ có tác dụng nếu sau này tăng `base`/hệ số, giữ làm rào chắn tương lai |

**Output range**: 3.15% (1 NFT, 0 gene) → 6.75% (20+ NFT, 3 gene, chưa chạm trần). **Ví dụ**: người chơi sở hữu 8 Axie NFT, chọn trước 1 con có 2 Special Gene vào đội: `3% × 1.25 × 1.3 = 4.875%` maxHP bonus cho riêng con Axie đó.

**⚠️ Chưa xác nhận qua simulation** — hệ thống chọn-trước NFT (§G8) chưa được implement trong code (`src/engine.js` hiện chưa có cơ chế nftPreselect), nên bonus này mới ở mức thiết kế trên giấy, hiệu chuẩn theo trực giác (khớp thang Ascension), không phải đo thật. **Bắt buộc chạy `node tools/sim.js` với bonus này sau khi implement**, đối chiếu lại với baseline đã có ở `docs/balance-log.md` (Full Run 8.0%) — nếu winrate lệch quá xa, hạ `base`/hệ số trước khi ship, không hạ trần `BONUS_CAP` (trần là rào chắn cuối, không phải giá trị vận hành).

### 10.2b NFT vs Free — ai được gì (tóm tắt, 2026-09-01)

Gộp lại từ C6, D7, D10, D11, §G8 (`AUDIT_AND_SPEC_v1.md`), và §10.2a ở trên — vì các quyết định này rải rác nhiều chỗ, dễ hiểu nhầm thành "NFT có part riêng". **Không đúng.** Bảng dưới đây là nguồn tóm tắt duy nhất — nếu có mâu thuẫn với suy luận từ nơi khác, bảng này thắng.

| | Người chơi Free | Người chơi sở hữu NFT |
|---|---|---|
| **Mở khoá part (danh tính/effect)** | Toàn bộ 192 part, mua bằng Gene Shard kiếm được qua chơi (~400/part, D10). Không giới hạn. | **Giống hệt** — không có part nào độc quyền NFT. Sở hữu NFT không tự động mở khoá part tương ứng trong Collection. |
| **Effect/mặt xúc xắc của một part** | Y hệt effect thiết kế trong `part-tier-system.md` §2 | **Y hệt** — cùng một effect, không có bản mạnh hơn dành riêng cho NFT |
| **Đội hình vào run** | Chọn 1 Lead Axie trước run (C4), 4 con còn lại tuyển ngẫu nhiên giữa run | Chọn trước tới 5/5 Axie NFT sở hữu (§G8) — **tiện lợi**, giảm rủi ro RNG tuyển quân, không phải sức mạnh thuần |
| **maxHP của Axie chọn-trước** | Chuẩn (100%) | **+3.15% đến +6.75%** tuỳ sở hữu/độ hiếm (§10.2a) — ngoại lệ có phạm vi, có trần, đã ghi rõ lý do |
| **Art bậc Mystic** | Cùng effect Mystic, skin thường | Art gốc độc quyền ở bậc Mystic (D11) — **thẩm mỹ**, không effect |
| **Sức mạnh tối đa lý thuyết trong 1 run** | 100% (mọi part đều mở được) | 100% part + tối đa +6.75%/Axie chọn-trước từ §10.2a |

**Kết luận dùng để trả lời câu hỏi player/nhà đầu tư**: *"NFT có mua được sức mạnh không?"* → Có, nhưng bị giới hạn nghiêm ngặt (§10.2a, trần +20%/Axie, chỉ áp dụng Axie chọn-trước) và **không đi qua part/effect** — phần lớn giá trị NFT vẫn là tiện lợi (chọn trước) và thẩm mỹ (art Mystic), không phải mở khoá nội dung độc quyền.

### 10.3 🔬 S4 — Faucet / Sink (dải khởi điểm)

**✅ D10 — Giá part phẳng ~400 Shard** (dao động 350-450 theo độ hiếm *thẩm mỹ*, không theo sức mạnh).

| Nguồn | Lượng |
|---|---|
| Hoàn thành wave | 5-8 / wave |
| Thắng run | +120 |
| Thua run | +40 — *thua vẫn phải có tiến bộ; đây là điều kiện của replay-rate* |
| Nhiệm vụ ngày | +60 / **ngày** |

Trung tâm dải: **~156 Shard/run**.

| Tiêu | Shard | Quy ra |
|---|---|---|
| Mở 1 part | ~400 | 2,6 run |
| 1 bloodline (32 part) — *tính từ 0* | 12.800 | ~82 run ≈ 27-41 giờ |
| 1 bloodline — **trừ 10 part khởi đầu** | 8.800 | **~56 run ≈ 19-28 giờ** |
| Toàn bộ 192 part — *từ 0* | 76.800 | ~492 run ≈ 164-246 giờ |
| Toàn bộ — **trừ 60 part khởi đầu** | 52.800 | **~338 run ≈ 113-169 giờ** |
| Pin / Forge / reroll | 100-200 | sink lặp lại |

> ✅ **S3 — Sink đầu cuối: Echo Points (Vọng Gene), chốt 2026-09-01.** Sau khi Collection đủ 192/192 part, mở khoá **Echo Forge** (cùng màn hình với Collection Log) — đổi Shard dư lấy **Echo Point (EP)**, một counter vĩnh viễn toàn tài khoản, không giới hạn trên, không reset. EP không mua trực tiếp gì — cứ 25 EP mở 1 **Prestige Tier**: khung viền/hiệu ứng dice-trail/danh hiệu profile (tái dùng art pipeline của Mastery M4, không cần asset mới).
>
> ```
> cost(n)       = EP.base × EP.growth^(n−1)                      [giá Shard cho EP thứ n]
> cumulative(n) = EP.base × (EP.growth^n − 1) / (EP.growth − 1)  [tổng Shard đã tiêu tới EP thứ n]
> ```
> `EP.base = 500` (gần giá 1 part, để cảm giác tự nhiên như "mua thêm 1 part") · `EP.growth = 1.035` (+3.5%/điểm, cộng dồn vĩnh viễn — đây là thứ giữ sink có nghĩa mãi mãi, không phải giá cố định như Pin/Forge).
>
> **Nhịp đo được** (dùng baseline ~156 Shard/run ở bảng trên): Tier 1 (25 EP) ≈ 46h chơi thêm sau khi hết 192 part · Tier 2 (50 EP) ≈ 157h · Tier 3 (75 EP) ≈ 418h · Tier 4 (100 EP) ≈ 1035h. Khoảng cách giữa các mốc giãn ~2.3-2.6× mỗi lần — đúng hình dạng cho một hệ giữ chân nhiều tháng/năm, không phải một bucket hữu hạn khác.
>
> **Gate**: chỉ cần Collection đủ 192/192 part (không cần Mastery M4 từng part) — kích hoạt đúng lúc Shard bắt đầu dư, không chờ hệ chậm hơn nhiều.
>
> **Rào chắn P2W (bắt buộc)**: (1) Echo Rank/Tier **không được hiện trên Gauntlet leaderboard** hay bất kỳ UI matchmaking-adjacent nào — chỉ hiện ở profile cá nhân, đúng cách §12.2 đã tách Ascension khỏi winrate thô; (2) không SKU nào được tăng Shard/giờ trực tiếp hay gián tiếp (kể cả SKU tăng tốc Mastery ở §11 mục 4) — nếu không, Echo Point âm thầm biến thành làn mua-tắt-grind. (3) Moon Dust không được mua/quy đổi ra EP hoặc Shard trực tiếp — giữ đúng luật 3 của D12.

---

## 11. MONETIZATION

| # | Sản phẩm | Giá | Ghi chú |
|---|---|---|---|
| 1 | **Season Pass** (4-6 tuần, free + premium) | ~$8.99 | Trụ cột. Thưởng: skin, Moon Dust, vé, **không có sức mạnh** |
| 2 | **Cosmetic** — skin mặt (Japan / Summer / Xmas), khung Axie, hiệu ứng roll, VFX | $2-8 | Biên cao nhất: art đã tồn tại |
| 3 | **Starter / Collector Bundle** — mở sẵn một cụm part + skin | $4.99 / $19.99 | Bán **tốc độ** |
| 4 | **Tiện ích** — tăng tốc Mastery, slot Pin thêm | $1-5 | |
| 5 | **Gauntlet Ticket** (seed mới) | $0.99+ | 3 vé/ngày miễn phí |

**Danh sách KHÔNG làm** — nên ghi thành cam kết công khai:

> Không năng lượng gate run chính · Không bán mặt xúc xắc có chỉ số · Không gacha cầu sức mạnh · Không bán slot Lead thứ hai · Không bán lượt thử lại trên cùng seed · Không bán skin Mystic · Không token thưởng cho gameplay.

Cộng đồng Axie đã bỏng một lần vì P2E. Ở công ty này, pay-to-win không chỉ là rủi ro thiết kế — **nó là rủi ro thương hiệu**.

**⬜ D13 — Mục tiêu Phase 1: conversion ≥3% · ARPDAU ≥$0.02** (ARPPU ≈ $20/tháng = Season Pass + 2-3 cosmetic). Cần đối chiếu benchmark thị trường trước khi đưa vào pitch C-Level.

---

## 12. POWER CREEP

Anh đã chấp nhận việc người sở hữu NFT mạnh hơn (✅ C5). Việc của tôi là làm cho nó thành **một núm vặn có nấc, đo được**, không phải một vách đá.

### 12.1 Bốn kênh

| Kênh | Trạng thái | Xử lý |
|---|---|---|
| **Bề rộng, khi bộ sưu tập không có gradient sức mạnh** | Trung tính **do cấu trúc**, không phải do đo | Luật §3 + phương án A |
| **Bề rộng × Forge, khi bộ sưu tập CÓ gradient** | **+11,9%** (đo được) | Kênh này bị đóng bởi C6 + ràng buộc Forge D8 |
| **Slot Lead Axie** | 🔬 **S1 — chưa định giá được** | Trần 2; phải đo |
| **Nở lệch archetype** | 🔬 **S2 — chưa ngã ngũ** (mô hình: −2%; audit độc lập: +35%) | Ràng buộc offer D16; phải phân xử |

**Nói thẳng về giá trị của mô hình.** Điều mô hình chứng minh được, và cũng là điều hữu ích duy nhất: **nếu bộ sưu tập có gradient sức mạnh và Forge được chọn lọc, bề rộng biến thành sức mạnh (+11,9%, còn tăng theo pool).** Đó là lý do phương án A tồn tại. **Trung tính không phải thứ ta phát hiện — nó là thứ ta phải thiết kế ra.**

### 12.2 Ascension là bộ điều tiết

Winrate tuyệt đối là chỉ số sai; chỉ số đúng là **người chơi ngồi ở nấc Ascension nào**. Người có bộ sưu tập lớn và 2 slot Lead sẽ leo cao hơn — họ không phá game, họ chơi ở độ khó khác. Spec đã có sẵn thang A0-A10 (A0 14,4% → A3 9,2% → A6 5,2% → A10 0,4%).

- **Gauntlet và leaderboard phân khúc theo Ascension**, không theo điểm thô — nếu không, bảng xếp hạng thành bảng xếp hạng ví tiền.
- Muốn nới trần về sau thì **thêm nấc Ascension** là công cụ đúng: rẻ, đã có sẵn, tự động hấp thụ power creep.

---

## 13. CHỈ SỐ NGHIỆM THU

Không tính năng nào được ship trước khi `sim.js` chạy đủ và các chỉ số nằm trong dải. **Mọi chỉ số winrate ghi theo % TƯƠNG ĐỐI**, không phải điểm phần trăm — trên nền A0 14,4%, "+5 pp" là +35% tương đối, một ngưỡng lỏng đến mức vô nghĩa.

| Chỉ số | Dải | Kiểm cái gì |
|---|---|---|
| Δwinrate (bộ sưu tập đầy vs khởi đầu), cùng số slot Lead | **≤ +10% tương đối** | Luật §3 có thật sự trung tính hoá bề rộng |
| Δwinrate mỗi slot Lead | **≤ +25% tương đối** | 🔬 S1. Ngoài dải ⇒ hạ trần về 1 slot vĩnh viễn |
| Δwinrate do nở lệch archetype (max/min pool = 5) | **≤ +10% tương đối** | 🔬 S2 |
| **Archetype diversity** ở bộ sưu tập đầy | ≥ 8/10 archetype có run thắng | Chống hội tụ build |
| Ngân sách sức mạnh mỗi part **ở cùng bậc** | trong ±10% | **CI tự động** — điều kiện sống còn của C6 |
| Thời gian tới part mới (người mới) | 2-3 run | Nhịp tiến bộ |
| Thời gian mở hết 1 bloodline *(từ 60 part khởi đầu)* | **19-28 giờ** | Chiều sâu không tuyệt vọng |
| **Replay-rate** (bấm chơi lại sau khi chết) | **≥ 55%** | North Star. Không đạt thì mọi thứ ở đây vô nghĩa |
| Conversion / ARPDAU | ≥ 3% / ≥ $0.02 | Mốc pitch Phase 1 |

Hai chỉ số quan trọng nhất là **replay-rate** và **archetype diversity**. Winrate chỉ nói game khó hay dễ; hai chỉ số kia nói game **có đáng chơi lại không**.

---

## 14. LỘ TRÌNH

### ⬜ D1 — Phase 1: 3 tháng, **WEB**, "Prove it"

Bộ sưu tập part + Gene Shard · **rarity 4 bậc trong run** · Axie Forge có ràng buộc · **1 slot Lead** · Mastery M1-M3 + Pin · Season 0 Battle Pass · cosmetic ~15 SKU · Gauntlet v1 + Daily Seed · account + server save + **replay-verify** · analytics + LiveOps config từ server.

**Không có:** NFT · mobile · slot Lead thứ hai · Mastery M4 · tournament · **bậc MYTHIC**.

*Vì sao web-first:* store review, IAP compliance, tax, ASO và mobile UX pass không nén được. Web còn tốt hơn cho mục tiêu pitch — không mất 30% store tax (revenue net đẹp hơn khi lên bảng), deploy hàng ngày để iterate, có số ngay tuần đầu, và cộng đồng Ronin/Axie vốn native trên web.

### Phase 2: tháng 4-9, "Scale it"

Mobile · **bậc MYTHIC** (36 hiệu ứng class×slot) · **lớp NFT** · slot Lead thứ hai qua meta-unlock sâu · Mastery M4 · nhịp season 6 tuần + Season Mutation · cosmetic NFT trên Ronin + marketplace fee · Gauntlet Tournament nếu legal thông.

### ⬜ D14 — Ngân sách

| | Person-week |
|---|---|
| **S0 (launch)** — 4 bậc × 192 part + chuyển thể 192 card text + 12 keyword mới | **8-12 pw** |
| Season thường (6 tuần) | 4-6 pw |
| Bậc Mythic (36 hiệu ứng, Phase 2) | 3-4 pw |

S0 là **ngân sách ra mắt**, không phải một season thường. Gộp chung sẽ vượt 30-100% ngay từ đầu.

---

## 15. RỦI RO

| # | Rủi ro | Mức | Xử lý |
|---|---|---|---|
| 1 | **Luật §3 bị vi phạm dần** — một part bậc Common mạnh hơn part Common khác | 🔴 | Kiểm ngân sách sức mạnh **tự động trong CI**. Điều kiện sống còn |
| 2 | **C-Level yêu cầu energy gate** | 🔴 | Chuẩn bị lập luận trước (§10.2 luật 1). Cuộc nói chuyện này chắc chắn xảy ra |
| 3 | **Slot Lead trượt lên 3+ do sức ép doanh thu** | 🔴 | Trần 2 ghi thành hằng số trong code. Không bán bằng tiền |
| 4 | **Slot Lead chưa được định giá** | 🔴 | 🔬 S1 là blocker |
| 5 | **Cognitive load** — 192 part × 4 bậc ≈ 768 cấu hình mặt + 27 keyword, cho một game gán xúc xắc | 🔴 | 60 part khởi đầu là cần nhưng **chưa đủ**. Thêm: giới thiệu bloodline theo lớp; mặt hiển thị icon + số trước, tên sau; bậc hiển thị bằng **màu viền**, không bằng chữ; **playtest legibility là tiêu chí ship** |
| 6 | Chi phí +3-4 pw cho 4 bậc × 192 part | 🟠 | Dùng mẫu leo thang, không thiết kế riêng từng bậc |
| 7 | Sink đầu cuối chưa có | 🟠 | 🔬 S3, chốt trước khi ship |
| 8 | **Gian lận economy client-side** — Shard kiếm 100% trong run của một roguelike JS | 🟠 | replay-verify trên server; thêm ngưỡng nghiệm thu tỷ lệ run bị từ chối |
| 9 | Mastery grind thành nghĩa vụ | 🟠 | Tích thụ động + Pin |
| 10 | Kỳ vọng của chủ sở hữu Mystic | 🟠 | Art Mystic độc quyền (§9) |
| 11 | IP bên thứ ba trong tên Mystic/Japan | 🟠 | Không bán làm SKU; legal review riêng |
| 12 | Bloodline đẩy build hội tụ | 🟠 | Meta Morph phải **luôn có mặt**, không hiếm. Nghiệm thu bằng archetype diversity |
| 13 | Mọi số định lượng đều là proxy | 🟠 | Xác nhận lại bằng `sim.js` trước khi ship |

---

## PHỤ LỤC A — TỔNG HỢP VIỆC CẦN LÀM

**Anh quyết (16 mục):** D1 web-first · D2 trần 2 slot Lead · D3 hoãn Mythic · D4 Mythic theo class×slot · D5 Mutation hạ về Common · D6 Common có keyword · D7 60 part khởi đầu · D8 ràng buộc Forge · D9 cắt M5 + thêm Pin · D10 giá part phẳng · D11 không bán Mystic · D12 bốn luật economy · D13 mục tiêu 3%/$0.02 · D14 ngân sách S0 · D15 secret class 3/6 slot · D16 offer tối đa 2/3 cùng archetype.

**Cần nguồn lực kỹ thuật (4 mục):** S1 định giá slot Lead · S2 phân xử nở lệch archetype · S3 thiết kế sink đầu cuối · S4 hiệu chuẩn faucet/sink.

**Cần bên ngoài:** legal review tên Mystic/Japan (IP bên thứ ba) · xác nhận với team art việc tách lớp part sprite · đối chiếu `parts.json` với bảng part chính thức của team Origins · benchmark conversion/ARPDAU thị trường.

---

## PHỤ LỤC B — ĐÃ ĐỒNG BỘ SANG DOC KHÁC

| Doc | Thay đổi |
|---|---|
| `BLOODLINE_SYSTEM_v1.md` → **v1.2** | Bỏ Universal pool · lên tier = nâng bậc, không ghi lại die · mỗi part tồn tại ở mọi bậc · luật Mythic theo class×slot (§5.3.1) · Common có keyword · CHAIN/COMBO đánh dấu [GÁC LẠI] xuyên suốt · secret class đổi đối trọng · Meta Morph đổi lập luận · sửa số pool 204 → 192 · sửa §8 bảng tác động engine |
| `AUDIT_AND_SPEC_v1.md` | Xem Phụ lục D — danh sách mục bị thay thế |

---

## PHỤ LỤC C — LỊCH SỬ SỬA ĐỔI

**v1.0 → v1.1** (sau audit độc lập vòng 1). Trụ cột chính bị bác bỏ:
tuyên bố *"bề rộng ≈ trung tính, +0,1%"* là **phép lặp thừa** — mô hình được cấu hình sao cho về mặt giải tích không thể trả kết quả nào khác 0 · ô 2×2 quan trọng nhất (bề rộng × Forge × variance) chưa từng chạy; chạy ra **+11,9%** · mâu thuẫn Lead Axie T1 · "luật cứng ngang giá" bị chính hệ rarity vi phạm · "+11%/+31%" cho slot Lead là hàm của một hằng số tuỳ tiện, **đã rút** · lỗi đơn vị (% coherence dùng như pp winrate) · Forge không ràng buộc · M5 bán được bằng tiền và tự triệt tiêu · Mystic ba đường loại trừ nhau · conversion 2% × $0.05 bất khả thi · vé Gauntlet = lượt thử lại · sơ đồ vẽ sai `Ronin`.

**v1.1 → v2.0** (sau audit chéo vòng 2 — 17 điểm). Ba lỗi nặng nhất do chính bản vá v1.2 của doc Bloodline sinh ra:
luật Mythic đầu tiên dựa trên một **ánh xạ core→mystic không tồn tại** trong dữ liệu, và biến việc lên Mythic thành cú **đổi danh tính** — đúng thứ vừa tuyên bố đã diệt · Gene Mutation bảo toàn bậc làm mục tiêu "giữ part suốt run" thành zero-cost · COMMON = 0 keyword xoá bản sắc class trong nửa đầu run.
Cộng thêm: luật lên tier ở doc Economy còn theo mô hình cũ · hai doc trả lời ngược nhau về Phase 1 có Mythic hay không · skin Mystic độc quyền tự bị phá · CHAIN/COMBO đã gác nhưng vẫn chống đỡ 2 bản sắc class và bảng minh hoạ trung tâm · secret class mất đối trọng · kinh tế Shard bỏ quên 60 part khởi đầu (sai 31%).

**Điều rút ra cho quy trình:** ba vòng audit liên tiếp đều lật ngược một kết luận chính, và cả ba đều cùng một dạng lỗi — **mô hình được dựng để xác nhận giả định thay vì kiểm định nó**. Từ v2.0, mỗi mô hình phải kèm câu trả lời tường minh cho *"cấu hình nào sẽ khiến mô hình này ra kết quả ngược lại?"* trước khi trích bất kỳ con số nào.

---

## PHỤ LỤC D — MỤC BỊ THAY THẾ TRONG `AUDIT_AND_SPEC_v1.md`

Spec gốc vẫn là contract cho engine, nhưng các mục sau **đã bị thay thế** bởi quyết định C6 (Phương án A) và hệ Bloodline. Đọc spec gốc cùng bảng này.

| Mục trong spec gốc | Nội dung cũ | Thay bằng |
|---|---|---|
| **§B2** Part vocabulary | `back` = shield, `ears` = mana… như **luật** | **Thiên hướng thống kê**, không phải luật. Vai trò cơ học gán theo từng part từ card text thật (`BLOODLINE` §1.1) |
| **§B2** mặt `blank` | Mặt trống "tồn tại để die T1 yếu" | **Bỏ vai trò này.** Die T1 yếu giờ do **bậc Common** quyết định, không do mặt trống. `blank` chỉ giữ lại như hiệu ứng nguyền rủa/bất lợi |
| **§B3** keyword `chain:N` | "N đòn vào địch ngẫu nhiên" | **Đổi tên thành `scatter:N`** — chữ *chain* trong Axie có nghĩa khác hẳn |
| **§B3** danh sách 15 keyword | 15 keyword | **+12 keyword mới** thu hoạch từ card text thật (`BLOODLINE` §3.3) |
| **§B5** "Level-up = ghi lại toàn bộ die" | Lên tier viết lại die | **Lên tier NÂNG BẬC các mặt hiện có.** Engine không bao giờ thay `partId` khi lên tier (§6) |
| **§B5** bảng bias part theo class | `Plant: back×3`, `Beast: horn`… tự nghĩ | **6 bloodline × 32 part thật của Axie**, bản sắc đọc ra từ card text (`BLOODLINE` §5.4) |
| **§B7** `PART_REPLACE` "đổi 1 mặt thành part **cấp cao**" | Đổi lên part mạnh hơn | **Gene Mutation đổi DANH TÍNH và hạ mặt về COMMON** (⬜ D5). Không còn khái niệm "part cấp cao" |
| **§B7** `OVERCLOCK` +50% value toàn die | Reward trong run | **Cần review lại** so với luật ngân sách ±10%/bậc — nó là reward trong run nên không vi phạm tầng, nhưng phải vào lại sim |
| **§B10** "meta-unlock persistent ngoài scope" | Ngoài scope v0.1 | **Là trọng tâm Phase 1** (bộ sưu tập part + Mastery) |
| **§D1** "1 currency: Gene Shard" | Một loại tiền duy nhất | **Ba lớp**: Gene Shard (mềm) · Moon Dust (cứng) · Gauntlet Ticket (§10.1). Vẫn đúng tinh thần "ít currency", nhưng F2P cần tối thiểu ba vai trò |
| **§D1** "Battle Pass / LiveOps bỏ khỏi v0.2" | Ngoài scope | **Season 0 Battle Pass + LiveOps config nằm trong Phase 1** (§14) |
| **§D2** bậc COMMON = "1 action, 0 keyword" | Common không có keyword | **Common có keyword đặc trưng ở giá trị tối thiểu** (⬜ D6) |
| **§D2** MYTHIC = mặt Mystic riêng lẻ | Ngầm hiểu Mythic gắn với mặt cụ thể | **Mythic gắn với cặp `class × slot`**; mọi part đạt Legendary đều lên được (⬜ D4) |
| **§D3** "50 mặt rarity" | 50 mặt tự nghĩ | **192 part × 4 bậc** (+36 hiệu ứng Mythic ở Phase 2) |
| **§D3** META "8 unlock" | 8 mốc mở khoá | **Bộ sưu tập 192 part + 768 mốc Mastery** (§7, §8) |
| **§D6** "Mech/Dawn chưa có art" | Ngoài scope | **Đã gỡ blocker** — secret class không có part riêng, thừa hưởng từ 2 class bố mẹ; art là recolor (`BLOODLINE` §6, ⬜ D15) |
| **§D6** "Battle Pass · Season ngoài scope" | Ngoài scope | **Trong scope Phase 1 / Phase 2** |
| **PHẦN C** kết quả balance | Đo trên mô hình cũ | **Phải chạy lại toàn bộ** — hệ 4 bậc đổi cơ bản đường cong DPS, cộng thêm định giá slot Lead (🔬 S1) |

**Không đổi, vẫn là contract:** §B1 vòng lặp combat · §B4 status effects · §B6 point-budget + `statScale` · §B8 UI layout · §B9 kiến trúc code · toàn bộ PHẦN A (audit GDD) · §D2 nguyên tắc *"rarity là ĐẦU RA của build, không phải ĐẦU VÀO"* — nguyên tắc này chính là tiền thân của Phương án A và giờ được thực thi triệt để.
