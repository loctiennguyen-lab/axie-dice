Trạng thái: REVIEW — chờ Liam

> **QUYẾT ĐỊNH LIAM (12/10) — ưu tiên hơn thân file:**
> A1 giữ style Homeland cho cosmetic (hợp thế giới 3D), chỉ ép viền đậm ở cỡ nhỏ · A2 (a) vẽ lại cả 21 khung cùng một
> style, lấy 5 khung của Liam (khung mẫu HomeLand) làm tham chiếu · A3 khung Legendary = mặt trời vàng (`sunburst`) ·
> A4 duyệt Mythic `#FF3D6E` (chỉ chip/viền/tên tier, cấm chữ trắng) + một nền đêm `#2A0F2E` · A5 đợt giao sau có lớp
> glow/MAX riêng cho Epic+.

# Review độc lập: Cosmetics 01 v6 (Claude Design) so với brief

Người review: Art Director · 11/10/2026 · Không sửa file art nào.

**Cách đọc:** những gì tôi nhìn trực tiếp (OBSERVED) là 20 plate PNG, 5 frame PNG, 6 contact sheet biome, manifest, README, `reroll_die.gd`. Phần FX tôi chỉ đọc spec trong manifest, chưa chạy prototype HTML (`Cosmetics 01 v6.dc.html`). Contrast tôi lấy theo số trong manifest, chỉ tự tính tay lại cho màu Mythic. Preview 104/64/36 và contact sheet tổng không có trong repo (README không nhắc), nên 36 px dưới đây là nhận định bằng mắt từ plate 512, chưa phải kiểm trên preview thật.

---

## 1. Verdict

| Hạng mục | Verdict |
|---|---|
| Die skin (20 plate) | **ACCEPT WITH FIXES** |
| Dice FX (14 spec) | **ACCEPT WITH FIXES** (dùng làm spec để dựng lại trong Godot, kèm 6 việc phải sửa/chốt ở mục 7) |
| Avatar frame | **REJECT như một bản giao đủ**: mới 5/21, và 3/5 sai theme so với ID. Giữ 5 file làm tham chiếu style, không ship |
| Màu Mythic `#FF3D6E` | **APPROVE có điều kiện** (mục 5) |

Lý do ngắn: 20 plate đủ ID, đủ số lượng theo tier, đúng quy tắc "chỉ đổi plate/border", bộ khá nhất quán và đọc được. Lỗi chủ yếu là kỹ thuật (mipmap, lớp animation chưa tách) và vài chi tiết lấn calm zone. Frame thì thiếu nhiều và lệch theme. FX là code canvas, không dùng trực tiếp được, và 3 FX thiếu màu face-type.

---

## 2. Completeness vs brief

| Kiểm tra | Kết quả |
|---|---|
| Die skin 20/20, đúng ID | Đủ. Tier: C3 U3 R6 E3 L3 M2 khớp §6 |
| 6 Mastery (plant, beast, aqua, reptile, bug, bird) | Đủ, đúng 6 class, đúng tier Rare |
| Pass S1 | `die_e_s1_founder` có. `frame_e_s1_founder` và `frame_l_sovereign` **chưa có** |
| Frame 5/21 | Thiếu 16 (liệt kê ở mục 6). **Tier Rare không có frame nào**, Mythic có 1/2, Legendary 1/2 |
| FX 14/14 spec | Đủ, nhưng **không có sprite PNG** (canvas vẽ bằng code), không có prototype tách riêng từng FX trong package |
| Deliverable theo §3.3 / §7 | Thiếu: `glow.png` cho Epic+, mô tả idle dạng layer, `preview_104_64_36.png`, `contact-sheet.png`, `mythic-colour.md` (đề xuất màu nằm trong README, được) |
| Manifest | Mảng `"frames"` liệt kê 6 ID (`frame_c_plant`, `frame_u_mushroom`, `frame_r_frost`...) không khớp `frames_with_art` (bird, pond, runering, sunburst, eclipse). Mảng này cũ, nên xoá hoặc sửa |

---

## 3. Findings theo item ID

Mức độ: **H** = phải sửa trước khi code dùng, **M** = nên sửa trong lần giao sau, **L** = polish.

Calm zone tính trên plate 512: x 51–461, y 225–410. Hàng value + chip thực tế chiếm khoảng x 90–420, y 245–390.

### 3.1 Die skin

| ID | Mức | Vấn đề | Cách sửa |
|---|---|---|---|
| `die_c_reed` | M | Đan nan với viền cam + vạch trắng bóng chạy khắp mặt, tần số cao, vào calm zone. Contrast đạt (6.1:1) nhưng ở 36 px thành nhiễu | Giảm độ tương phản đường viền nan trong vùng giữa, chỉ giữ nan rõ ở nửa dưới |
| `die_c_sunwood` | L | 19% trên cùng là mảng nâu phẳng (chắc chắn bị band che nên không sao). Vân gỗ và 2 đinh ổn | Không cần |
| `die_c_clay` | L | Đơn giản đúng tier. Dấu ngón tay hình vòm giống nhau, hơi lặp | Không cần |
| `die_u_moss` | L | Đá nhìn tốt. Lá xanh bị cắt ở mép trái/phải | Chấp nhận (mép sẽ bị border 20 px che), nhưng kiểm lại sau khi mask bo góc |
| `die_u_bark` | L | Vòng gỗ toả từ góc trái dưới, đọc rõ. Nhánh non nhỏ nhưng OK | Không cần |
| `die_u_berry` | M | "Jam chảy" hai bên trông như hai ống màu hồng hơn là jam. Màu hồng đậm `#F0507A` gần với chip ATTACK đỏ | Làm giọt chảy ngắn, tròn đầu hơn. Giữ jam ở dưới và hai cạnh, không cần thêm |
| `die_r_plant` | L | Tốt. Lá mờ trong calm zone ở mức thấp, dây leo ở dưới | Không cần |
| `die_r_beast` | L | Tốt. Móng vuốt và dấu chân ở trên calm zone (đúng). Lông ruff dưới đẹp | Không cần |
| `die_r_aqua` | M | Vảy teal vẽ đậm đều khắp mặt (nét 4 px), cạnh tranh với nét chữ số. Bong bóng bên trái chạm biên calm zone | Làm mờ vảy trong calm zone khoảng 40%, hoặc chỉ vẽ vảy đầy đủ ở nửa dưới |
| `die_r_reptile` | M | Lưới lục giác lilac đều khắp mặt, cùng vấn đề như aqua. Ngoài ra màu tím đang trùng hệ màu Epic `#BF6BFF` | Giảm contrast lưới trong calm zone. Cân nhắc đổi màu scute sang xanh lá-nâu để khỏi gần Epic, hoặc chấp nhận vì tím là màu class Reptile (cần Liam quyết) |
| `die_r_bug` | M | Vạch giữa dọc (x=255, y 125–420) chạy thẳng qua tâm hàng value+chip. Vỏ bọ cánh cứng đỏ `#FF6E5E→#D83A30` gần màu ATTACK `#F54540` | Cắt vạch giữa ngắn lại, dừng trước y 225. Shell nằm dưới calm zone nên chấp nhận được, nhưng đây là skin dễ nhầm type chip nhất |
| `die_r_bird` | L | Quạt lông hồng/xanh đẹp, nằm dưới calm zone. Sóng xanh nhạt ổn | Không cần |
| `die_e_rune` | M | Rune dưới bị đè một phần bởi cuộn xoắn vàng (rune thứ nhất bị cắt). Rune, gem, vòng xoắn đều nằm ngoài calm zone (đúng). Idle `glow.png` **chưa giao** | Dời cuộn xoắn ra ngoài hoặc dịch dãy rune sang phải. Giao `glow.png` + plate tĩnh tách lớp |
| `die_e_spore` | M | Nấm lớn bên trái/phải lấn góc calm zone (mũ nấm cao đến y ≈ 325). Bào tử và halo bị **bake sẵn vào plate**, nên khi thêm lớp glow Add sẽ nhân đôi | Hạ nấm thấp xuống một chút. Giao plate nền không có bào tử/halo, rồi `glow.png` riêng |
| `die_e_s1_founder` | M | Dải "SEASON 1" vẽ bằng chữ serif nghiêng, **trái spec** (ghi Baloo 2 800) và trái quy tắc "Baloo 2 cho mọi nhãn". Cao khoảng 7 px ở 104 px, không đọc được ở 64/36. Hai sao vàng góc trên bake sẵn nhưng idle lại là sao nhấp nháy, cần tách | Đổi sang Baloo 2, hoặc bỏ chữ và dùng huy hiệu số "1". Tách sao thành lớp riêng. Đầu dải ruy băng gần chạm vùng bo góc 92 px, kiểm lại |
| `die_l_gold` | M | Tia mặt trời mọc từ dưới **lấn vào calm zone** (đỉnh tia cao đến y ≈ 350, chạm đáy chữ số). Chưa có `glow.png` sheen. Với Legendary, vẫn hơi gần Epic về độ phức tạp (chỉ thêm mặt trời và tia) | Hạ mặt trời xuống để tia dừng ở y ≥ 410. Thêm lớp sheen riêng. Có thể thêm họa tiết khắc đá cổ ở hai góc để Legendary thấy rõ hơn |
| `die_l_relic_stone` | M | Đẹp, khoá đá + vết nứt vàng ở hai bên và đáy, nằm ngoài calm zone. Nhưng vết nứt phát sáng **đang bake vào plate tĩnh**, chưa có lớp `glow.png` để nhịp. Gạch có đường vữa chạy qua calm zone, 8.4:1 nên vẫn OK | Giao nền đá không có vết nứt sáng + `glow.png` vết nứt (Add) |
| `die_l_kingdom` | L | Skin đẹp nhất bộ, hợp "LUNACIA SOVEREIGN". Vương miện ở dưới, họa tiết kim cương mờ. Sheen chưa giao | Giao `glow.png` sheen |
| `die_m_redcrystal` | M | Dùng plate sáng đúng yêu cầu (kem `#FFF4E4→#F4DCC4`, viền nâu đỏ, vừa calm zone). Có nét "nhãn dán" nổi trên nền đêm, nhưng đúng chủ đích và đọc rõ. Border nâu đỏ `#6B2B2B` trên nền navy đậm: ở 36 px viền **gần như biến mất ở đáy**, mất cảm giác "outlined". Mặt trăng khuyết và pha lê nằm ngoài vùng chữ. Pha lê dùng hồng `#FF8A98→#C02848`, không dùng màu Mythic `#FF3D6E` | Dùng border đen hoặc rất đậm cho Mythic dark skin. Đưa `#FF3D6E` vào một chi tiết (ví dụ lõi pha lê). Tách lớp trăng khuyết → trăng tròn và pha lê cho khoảnh khắc MAX |
| `die_m_moon` | M | Ý tưởng có signature rõ nhất bộ: mặt trăng ngủ, số nằm giữa. Điểm hay. Nhưng border `#2E2266` gần như cùng sắc/độ sáng với nền đêm `#30246A`: ở góc, viền mất. Mắt/miệng ở trên/dưới hàng chữ có thể bị đọc như mặt người "đọc" số, nhưng đây là chủ ý | Border đen cho skin này. Giao riêng lớp mắt mở (MAX) và lớp halo |

**Nhận xét chung cho 20 plate**
- **Nhất quán:** tốt. Cùng một mẫu "trường nền + đường/ornament dọc đáy", viền nâu đỏ `#6B2B2B` bên trong, tia lấp lánh. Nhìn ra ngay là cùng một bộ.
- **Style:** plate dùng gradient airbrush và nét nâu đỏ kiểu Homeland, **không phải** "flat fill + viền đen" như brief và v2 UI. Border ngoài của mặt xúc xắc (code) vẫn đen, nên khi ghép vẫn ổn, nhưng đây là hai ngôn ngữ trong cùng một viên. Tôi đề xuất chấp nhận vì khớp với thế giới 3D Homeland/Axie (xem câu hỏi 1).
- **Motif ở 76% dưới:** đạt. Mọi ornament chính nằm dưới y ≈ 123 (band 24%). Phần đỉnh ít chi tiết.
- **Bo góc:** plate vuông đầy tràn, code sẽ phải mask bo góc 0.18 s (≈92 px ở 512) và border 4 px (≈20 px). Các ornament ở góc dưới (nấm, cuộn xoắn, việt quất, pha lê, ruy băng) sẽ bị cắt một phần. Cần test sau khi dựng.
- **36 px:** tôi chưa thấy preview thật. Các họa tiết tần số cao (reed, vảy aqua, lục giác reptile, gạch đá) sẽ thành nhiễu ở 36 px, nhưng chữ số lớn và có plate sáng nên vẫn đọc. Cần chụp thử trong Godot.
- **Chuyển màu theo tier:** Rare dùng màu class (xanh lá, cam, teal, tím, đỏ, xanh trời), nên **không đọc được là "Arctic/xanh băng"**. Đúng với brief (Mastery gắn class), nhưng tier Rare không còn tín hiệu chung. Gợi ý: thêm một chi tiết băng nhỏ chung (đường viền xanh `#33B8FF` hoặc mảnh tuyết ở một góc) cho cả 6 Rare.

### 3.2 Frame (chi tiết ở mục 6)

| ID | Mức | Vấn đề | Cách sửa |
|---|---|---|---|
| `frame_c_bird` | M | Đúng theme Bird, màu cam hợp Savannah. Nhưng khá giàu chi tiết cho Common (hoa hồng lớn, bướm, chim con): ngang một frame Epic. Cửa sổ Ø434/600 = 72% (brief 65.6%) | Giữ làm tham chiếu. Nếu dùng, giảm bớt chi tiết cho Common |
| `frame_u_pond` | L | Đúng theme (ếch + lá sen), hợp Uncommon, silhouette rõ ở 40 px | OK. Ếch trên cùng làm khung không tròn, cần dành chỗ trong layout |
| `frame_e_runering` | H | **Sai theme**: ID là vòng rune xoay, nhưng art là SS2 Fancy (gem + cuộn xoắn + bát tím). Không có rune. Silhouette có "cái bát" kéo dài phía dưới, không phải vòng | Vẽ mới đúng theme, hoặc đổi ID/tên theo art và giao `frame_e_runering` riêng |
| `frame_l_sunburst` | H | **Sai theme**: ID là sunburst Genesis, art là vòng bạc-xanh với bánh răng cam. Màu chủ đạo xanh bạc, ở 40 px đọc như Rare chứ không phải Legendary vàng. FX `fx_l_sunfire` lại nói "khớp với frame_l_sunburst" (mặt trời + cánh) nên hai thứ **đang mâu thuẫn** | Vẽ lại với mặt trời/tia vàng, hoặc đổi theme FX cho khớp. Cần thống nhất một bên |
| `frame_m_eclipse` | H | **Sai theme Mythic**: art SS3 màu teal/kem/gỗ với trăng khuyết trên đỉnh, chỉ một nút thắt đỏ nhỏ. Không có pha lê đỏ, không có palette Mythic `#FF3D6E`. Cửa sổ Ø381/600, hình bầu dục rộng hơn tròn | Vẽ lại frame Mythic theo palette crimson/đêm. Giữ trăng khuyết trên đỉnh nếu Liam thích |

### 3.3 FX (chi tiết ở mục 7)

| ID | Mức | Vấn đề | Cách sửa |
|---|---|---|---|
| `fx_c_dust` | L | Đủ | Giữ |
| `fx_c_leaf` | M | Cap cứng 40/die, không còn dư địa | Hạ cap xuống ≤ 34 |
| `fx_c_pebble` | L | Đủ | Giữ |
| `fx_u_petal` | M | Cap cứng 40/die | Hạ cap xuống ≤ 34 |
| `fx_u_splash` | M | Cap cứng 40/die | Hạ cap xuống ≤ 34 |
| `fx_u_ember` | M | Ngọn lửa nhấp nháy 12 fps, 3 hình, spec ghi "reduced: giống hệt" | Reduced: giữ một hình tĩnh hoặc ≤ 6 fps |
| `fx_r_frost` | **H** | Spec settle **không có "bits [face type, ...]"** (thiếu màu face-type, brief bắt buộc). Gai băng giữ 0.35 s | Thêm 8 bits màu face-type, spawn đầu tiên |
| `fx_r_bubble` | M | Cap cứng 40/die | Hạ cap ≤ 34 |
| `fx_r_spark` | M | Tia điện re-jag 24 fps sáng vàng, đúng là ở dạng strobe nhẹ. Reduced đã giữ hình cố định (tốt) | Giữ. Test nhìn bằng mắt |
| `fx_e_rune` | **H** | **Không có bits màu face-type** trong settle. Vòng + cột sáng dài 0.9 s | Thêm bits face-type. Cột sáng và vòng phải nằm phía sau mặt xúc xắc và không che chữ |
| `fx_e_spore` | L | Có bits mint + face-type | Giữ |
| `fx_l_sunfire` | M | Nói "khớp frame_l_sunburst" nhưng frame thật là bánh răng (xem trên). Tint vàng 0.25 trong 0.2 s phủ lên cả xúc xắc? | Làm rõ tint chỉ trên nền, không trên mặt. Chốt lại theme cùng frame |
| `fx_l_starfall` | M | Sao rơi "ở lại và nhấp nháy" sau settle, phải có quy tắc dọn khi reroll/chốt | Thêm điều kiện xoá. Reduced đã tắt nhấp nháy (tốt) |
| `fx_m_lunar` | **H** | Thiếu bits face-type. Làm tối khay 60% ở MAX: phải **không** làm tối xúc xắc. Sheen quét qua mặt 0.32 s (> 0.25 s). 5 xúc xắc cùng MAX sẽ chồng 5 hiệu ứng nhật thực | Thêm bits. Dim nằm dưới xúc xắc. Sheen ≤ 0.25 s. Chỉ một nhật thực cho mỗi lượt roll |

---

## 4. Tier escalation và biome

- **Common → Uncommon:** cùng độ phức tạp, ổn (đúng brief: một chất liệu, họa tiết đơn giản).
- **Rare:** đúng "hai chất liệu" (trường nền + dải chất liệu dưới). Tuy nhiên chỉ là thêm một dải ở đáy.
- **Epic:** có ornament ở góc/rim (cuộn xoắn, nấm, laurel). Đạt về tĩnh.
- **Legendary:** gold hơi gần Epic, `relic_stone` và `kingdom` giàu hơn rõ. Cả ba thiếu lớp glow riêng (brief yêu cầu "ornament + light layer").
- **Mythic:** có signature thật (trăng ngủ, trăng khuyết + pha lê). Phân biệt rõ với Legendary nhờ nền đêm tối. Tốt nhất ở hai tier trên.
- **Biome theo contact sheet:**
  - Savannah (cam vàng, cỏ lau kem): reed/sunwood/clay đúng hướng.
  - Forest (xanh lá): moss/bark/berry đọc được.
  - Arctic (xanh băng nhạt, bụi cây xanh bạc hà): Rare **không** đọc được vì dùng màu class (đã nêu).
  - Mystic (tím oải hương, cây hồng/cam): rune và spore khớp.
  - Genesis (cầu vồng, ngọc lam, vàng): vàng/đá/hoàng gia đọc được là Legendary, ít cảm giác Genesis. Chấp nhận.
  - LunaLanding (pha lê đỏ cam, đá xám-trắng, trăng đá): redcrystal khớp phần pha lê, thiếu đá xám-trắng làm đế.
- README nói Claude Design không nhận được contact sheet, nên hướng biome là suy luận từ mô tả. Kết quả vẫn ổn, nhưng nếu giao đợt 2 phải gửi ảnh.

---

## 5. Màu Mythic: `#FF3D6E` (Luna Crimson) + `#2A0F2E`

Tôi tính tay (xấp xỉ):

| So với | Kết quả |
|---|---|
| 5 màu rarity (`#C6CEDA #40CC3D #33B8FF #BF6BFF #FF9445`) | Khác rõ. Gần nhất là Epic tím (cách khoảng 70° hue, cùng độ sáng) và Legendary cam (cách ≈ 40° hue, nhưng Mythic tối hơn rõ) |
| `DANGER` đỏ sát thương `#F54540` | **Gần nhất**: hue lệch chỉ ≈ 17°, độ sáng gần như bằng nhau (L ≈ 0.26 vs 0.24). Với người mù màu đỏ-lục sẽ gần như một màu |
| `DEBUFF_PINK` `#FF8FC7` | Khác rõ nhờ độ sáng (Mythic tối hơn nhiều) và hue lệch ≈ 15° |
| Ink `#1A1206` trên `#FF3D6E` | ≈ 5.4:1, đạt ≥ 4.5. Dùng `ink_on()` như các màu khác. **Chữ trắng trên màu này chỉ ≈ 3.4:1, cấm** |
| Viền đen trên `#FF3D6E` | ≈ 6:1, ổn |

**Khuyến nghị: APPROVE `#FF3D6E`, kèm 3 điều kiện.**
1. Màu Mythic chỉ dùng cho chip/viền rarity, tên tier, frame; **không dùng cho số, thanh HP, intent, chữ báo sát thương trong combat**.
2. Luôn đi kèm từ "MYTHIC" hoặc glyph pha lê, không dựa vào màu đơn lẻ (theo quy tắc 6 của `godot/CLAUDE.md`).
3. FX `fx_m_lunar` dùng `#FF3D6E` trong combat, cạnh số sát thương đỏ. Giữ màu face-type (mục 7) và đừng để dải crimson chạy qua vùng số.

Phương án khác nếu Liam muốn tách khỏi đỏ sát thương hơn: `#FF4F8B` (hue ≈ 337°, ink ≈ 6:1). Lệch thêm khoảng 8° nên lợi ích nhỏ; tôi không khuyến nghị đổi.

Màu cặp `#2A0F2E` (tím mận) chưa được dùng ở plate nào: các skin Mythic đang dùng navy `#14204A`, tím đêm `#2E2266`, kem teal ở frame. Cần chốt **một** nền đêm cho Mythic (câu hỏi 4).

---

## 6. Frame: 5 file đã có và 16 file còn thiếu

**5 file là art của chính Liam** (frame 1–3, SS2/SS3 Fancy), chỉ đổi tên theo ID. Đánh giá theo brief:

| Tiêu chí brief | Thực tế |
|---|---|
| Canvas 256×256 | Không: 600×(643–664), không vuông |
| Cửa sổ Ø168 ở giữa (65.6% bề rộng) | Cửa sổ 60–79% bề rộng, tâm không ở giữa. Phải dùng toạ độ trong manifest để scale riêng từng frame |
| Frame đè cửa sổ tối đa 8 px | Không kiểm được |
| Đọc ở 40 px | Hầu hết đọc được nhờ màu khối riêng (cam / xanh lá / tím / bạc-xanh / kem-teal). `sunburst` bạc-xanh dễ lẫn Rare |
| Phù hợp tier | `c_bird`, `u_pond` hợp. `e_runering`, `l_sunburst`, `m_eclipse` sai theme và (Mythic) sai palette |
| Layer animation | Không có (rune xoay, đom đóm, sunburst idle cần layer rời) |
| Silhouette | Có chỗ lồi ra ngoài vòng tròn (hoa Bird, mũ ếch, bát tím, đỉnh trăng). Với canvas 256 vuông, đưa về cửa sổ Ø168 sẽ làm `runering` và `eclipse` cao hơn 256 px (~298 và ~293) |

**16 frame còn thiếu:**

| Tier | Thiếu |
|---|---|
| Common (5) | `frame_c_plant`, `frame_c_beast`, `frame_c_aqua`, `frame_c_reptile`, `frame_c_bug` |
| Uncommon (3) | `frame_u_vine`, `frame_u_mushroom`, `frame_u_campfire` |
| Rare (4) | `frame_r_frost`, `frame_r_snowglobe`, `frame_r_aurora`, `frame_r_icicle` |
| Epic (2) | `frame_e_firefly`, `frame_e_s1_founder` |
| Legendary (1) | `frame_l_sovereign` |
| Mythic (1) | `frame_m_crystal` |

Cộng thêm 3 frame sai theme (runering, sunburst, eclipse) cần vẽ lại thì thực tế là **19 frame cần vẽ**, chưa kể layer animation cho Epic+.

**Mỗi frame mới cần:**
- PNG 256×256 vuông, trong suốt, cửa sổ Ø168 chính giữa, có thể đè lên mép cửa sổ ≤ 8 px (viền chính xác theo brief).
- Preview 40/96/256 px quanh avatar giả. Silhouette hoặc khối màu phải khác frame cùng tier hàng xóm.
- Epic+: base tĩnh + layer động rời + spec loop. Có biến thể Reduce flashing.

**Có nên để Claude Design vẽ không?** Có, nhưng cần quyết định về style trước (câu hỏi 2). 5 frame của Liam là tranh vẽ tay có nét rung, bóng mềm. Plate của Claude Design là vector gradient. Nếu Claude Design vẽ 16 cái còn lại bằng SVG, bộ frame sẽ có hai chất lượng khác nhau (5 vẽ tay, 16 vector). Hai hướng:
- **A (khuyến nghị):** Claude Design vẽ cả 21 frame theo một style vector duy nhất khớp plate, dùng 5 frame của Liam làm tham chiếu hình dáng/màu, chứ không tái sử dụng bitmap. Bộ đồng nhất và đúng canvas 256.
- **B:** giữ 5 frame của Liam, Claude Design vẽ 16 cái theo cách gần nhất có thể, chấp nhận lệch.

Tham chiếu cần gửi kèm: 5 frame trong `godot/assets/cosmetics/frames/`, contact sheet 6 biome (nhất là Arctic cho Rare, LunaLanding cho Mythic), `reroll_die.gd` không cần. Với Rare cần chú ý: 4 frame Rare phải phân biệt được với nhau và với Uncommon xanh lá ở 40 px.

---

## 7. FX: 14 spec, và những gì bản Godot phải giữ

Chúng là **code canvas**, không phải asset. Không có sprite PNG, không có prototype từng cái. Godot phải dựng lại (đề xuất vẽ bằng `_draw` như `fx_bits.gd`, `Line2D` cho dải comet, không dùng texture).

**Đánh giá so với brief**

| Brief | Kết quả |
|---|---|
| ≤ 40 particle/die | Bốn FX ghi "cap cứng 40" (leaf, petal, splash, bubble): đúng giới hạn nhưng không còn dư. 5 xúc xắc = 200. Mythic "mỗi layer lớn tính là 1 particle" là cách đếm đáng ngờ |
| Settle xoá mặt trong ≤ 0.25 s | Spec đi theo hướng **giữ vật xa mặt xúc xắc** (≥ 52 / 62 / 70 px) thay vì xoá nhanh. Cách này chấp nhận được vì số luôn đọc được. Ngoại lệ: sheen Mythic quét **qua mặt** 0.32 s. Vòng rune, nấm, sunfire kéo dài 0.9 s (ở sau/bên cạnh mặt) |
| Giữ màu face-type | 11/14 có "bits [face type, ...]". **Thiếu ở `fx_r_frost`, `fx_e_rune`, `fx_m_lunar`** |
| Reduce flashing | Hầu hết "giống hệt" (không đổi độ sáng): hợp lý. Có biến thể rõ cho rune, spore, sunfire, starfall, spark, lunar. Điểm yếu: `fx_u_ember` nhấp nháy 12 fps hình dạng, `fx_m_lunar` làm tối cả khay |
| Mythic có khoảnh khắc MAX | Có (nhật thực 1.9 s). Mạnh nhất bộ. Nhưng tốn: khay tối 60%, 26 sao nhấp nháy, tia sáng, chữ viền |

**Việc Godot phải giữ (preserve list)**
1. Bits màu face-type spawn **đầu tiên** trong settle, và luôn nằm ngoài ngân sách bị cắt (để cap 40 không làm mất chúng). Phải có cho cả 14 FX, kể cả frost/rune/lunar.
2. Không thêm hạt đè lên **mặt xúc xắc** sau 0.25 s. Giữ khoảng cách các vật thể so với tâm mặt: leaf/pebble/petal ≥ 60, ember ≥ 62, frost ≥ 70, spore 86–152, starfall ≥ 52, constellation Mythic ≥ 96.
3. Cap hạt mỗi xúc xắc (hạ về ≤ 36) kể cả hạt của `fx_bits.gd` hiện có.
4. Biến thể Reduce flashing: không tint, không pulse, glow ≤ 50%, Mythic dim 30%, sheen 50%, không diamond-ring blink, sao đứng yên, tia điện giữ một hình cố định.
5. Lower tier animate **trên hai khung (12 fps)**, Mythic 60 fps. Đây là cách phân biệt tier, đừng làm đều.
6. Mythic chỉ chạy một nhật thực mỗi roll (không phải mỗi xúc xắc); dim nằm dưới xúc xắc.
7. Dọn sao/hạt "ở lại" khi reroll, chốt, hoặc rời combat.
8. Không thay thế beat/stamp hiện có của reroll (đúng brief §5.1).
9. Kết thúc đúng thời gian: 0.8 s toss, 0.3 s settle mỗi die.

---

## 8. Kỹ thuật PNG

- **Cạnh, anti-alias:** sạch, không thấy artefact, banding hay halo trong các ảnh 512. Gradient mượt. Phần filter (`feTurbulence`) đã được rasterize nên không còn vấn đề ThorVG.
- **Import:** cả plate và frame đang `mipmaps/generate=false`. Plate 512 hiển thị ở 104/64/36 px, lại xoay 3D bằng affine transform khi lăn. Không có mipmap thì sẽ lấp lánh/răng cưa (nhất là reed, vảy, lục giác). **Bật mipmap + filter `linear mipmap`**, hoặc xuất thêm bản 128 px.
- **Mask:** plate đầy tràn hình vuông, cần mask bo góc 0.18 s và border 4 px do code vẽ. Chi tiết trong 20 px mép và trong cung bo góc sẽ bị cắt (xem 3.1).
- **Plate tĩnh có đủ cho Epic+ không? Chưa.** Các skin Epic+ ghi spec idle (rune pulse, spore twinkle, sheen, nứt phát sáng, mắt mở khi MAX) nhưng `glow.png` / các lớp **chưa giao**, và nhiều chi tiết phát sáng đang **bake sẵn** vào plate (bào tử, halo, vết nứt, sao). Cần: plate nền sạch + từng lớp động trong suốt riêng. Với 2 Mythic còn cần lớp MAX (trăng tròn, mắt mở, pha lê phóng to).
- **Nguồn:** SVG sinh bằng code + Chrome chụp. Tốt cho lặp lại. Giữ script `plateSVG` trong repo để xuất lại.

---

## 9. Ghi chú gửi Claude Design (sẵn sàng gửi, tiếng Anh)

> Thanks for Cosmetics 01 v6. The 20 die plates are in and in good shape. What we need next:
>
> **Die plates (fixes)**
> 1. Keep the value row clean. Pull the sun rays of `die_l_gold` down so nothing rises above y=410 at 512; lower the mushroom caps on `die_e_spore`; cut the vertical centre seam of `die_r_bug` short (stop before y=225); soften the scale/hex/weave lines inside the calm zone on `die_r_aqua`, `die_r_reptile`, `die_c_reed` (about 40% less contrast).
> 2. `die_e_s1_founder`: the "SEASON 1" ribbon uses a serif italic. Use Baloo 2 800 or drop the text for a numeral badge. It is unreadable below 104 px.
> 3. Mythic dark skins (`die_m_redcrystal`, `die_m_moon`): the border colour disappears into the night field at 36 px. Use a black (or near-black) border. Put `#FF3D6E` into one detail on `die_m_redcrystal`.
> 4. Epic+ layers: deliver a clean base plate with no baked glow, plus a separate transparent `glow.png` (and a MAX layer for the two Mythic skins: full moon, open eyes, grown crystals). Baked items to pull out: spore halos and spores (`die_e_spore`), seam glow (`die_l_relic_stone`), corner stars (`die_e_s1_founder`).
> 5. Give us the previews we asked for (`preview_104_64_36`) and the contact sheet, they were not in the package.
> 6. For Rare, add one small shared "frost" detail (cold-blue rim or snowflake facet) so the tier reads as Arctic across all six class skins.
>
> **Frames: 16 are missing, 3 of the 5 supplied do not match their ID**
> Missing: c_plant, c_beast, c_aqua, c_reptile, c_bug, u_vine, u_mushroom, u_campfire, r_frost, r_snowglobe, r_aurora, r_icicle, e_firefly, e_s1_founder, l_sovereign, m_crystal. Also redraw `frame_e_runering` (rune ring, not the bowl), `frame_l_sunburst` (gold sun, not gears) and `frame_m_eclipse` (crimson/night Mythic palette, not teal/cream).
> Spec per frame: 256×256 square transparent PNG, centred Ø168 window, overlap ≤ 8 px, readable at 40 px, preview at 40/96/256. Epic+ also needs the moving layer as a separate PNG plus loop spec and a Reduce-flashing variant.
> Style: please draw all 21 frames in one consistent style matching the die plates. Use the five frames in `frames/` as shape and colour reference only. The six biome contact sheets are attached this time, please use them (Arctic for Rare, LunaLanding for Mythic).
>
> **FX: spec updates (no new art)**
> Add the missing face-type colour bits to `fx_r_frost`, `fx_e_rune`, `fx_m_lunar`; cap the four "40 per die" FX at 34; make the `fx_m_lunar` sheen ≤ 0.25 s, dim only the tray under the dice, and one eclipse per roll, not per die; reduced variant of `fx_u_ember` holds a single flame shape; reconcile `fx_l_sunfire` with whatever `frame_l_sunburst` becomes.

---

## 10. Câu hỏi cho Liam

1. **Style:** plate đang dùng gradient airbrush và nét nâu đỏ kiểu Homeland, trong khi v2 UI là flat + viền đen. Bạn muốn giữ ngôn ngữ Homeland cho cosmetic (tôi nghiêng về cách này vì khớp thế giới 3D) hay ép về flat + viền đen cho thống nhất với UI?
2. **Frame:** chọn hướng A (vẽ lại cả 21 bằng một style) hay B (giữ 5 frame của bạn, vẽ 16 cái còn lại)? A đồng nhất hơn nhưng bỏ 5 frame bạn đã làm làm tham chiếu thôi.
3. **Reptile tím vs Epic tím:** `die_r_reptile` dùng lilac gần màu Epic `#BF6BFF`. Giữ vì Reptile là class tím, hay đổi?
4. **Mythic:** duyệt `#FF3D6E`? Nền đêm chốt dùng cái nào (`#2A0F2E` tím mận, navy `#14204A`, hay tím đêm `#2E2266`)?
5. **Sunburst ↔ sunfire:** frame Legendary là sunburst vàng (vẽ lại theo art FX) hay giữ bánh răng bạc-xanh và đổi theme FX?
6. **Rare:** có muốn thêm chi tiết băng chung cho cả 6 skin Rare, hay chấp nhận Rare chỉ nhận ra bằng màu class và chip rarity?
7. **Đợt giao sau:** trong lần sau, nhận lớp `glow.png`/MAX layer cho Epic+ (kèm plate sạch) hay làm animation trong Godot từ spec text?
8. **Mipmap:** tôi sẽ để ui-programmer/technical-artist bật mipmap cho plate. Bạn đồng ý không, hay muốn xuất thêm bản 128 px?
