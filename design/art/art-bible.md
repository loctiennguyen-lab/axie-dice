# Axie Dice — Art Bible

> **Status**: 1–4 đã duyệt (28/10), 5–9 nháp. Mục 8 do technical-artist soạn riêng. Số đo pixel thật: `design/art/palette-measured.md` (28/10); mục 4 chờ Liam chọn màu class trước khi thay hex.

Người soạn: art-director. Nguồn style duy nhất: art chính thức của Sky Mavis trong `asset-library/design-library/` (art-2d, renders) và Axie 3D đang chạy trong game. Không lấy style game khác (Liam).

Cách đọc: mỗi mục có "Test" để kiểm một ảnh có đúng chất không. Ảnh nào trượt test thì làm lại, không ngồi cãi "đẹp hay xấu".

Ghi chú về số liệu màu: hex có đánh dấu **[code]** là đọc từ code/test đang chạy (đúng 100%). Hex đánh dấu **[mắt]** là ước bằng mắt từ contact sheet. Liam đã duyệt đo chính xác bằng lấy mẫu pixel (28/10); số đo sẽ nằm ở `design/art/palette-measured.md` và được gộp vào mục 4 sau. Đến lúc đó, [mắt] chỉ là số tạm.

---

## 1. Tuyên bố nhận diện hình ảnh

**Một câu:** Axie Dice trông như một thế giới Lunacia: tròn, ấm, sáng, và mọi thứ quan trọng đọc được trong một cái liếc.

(Liam 28/10: không buộc style vào một chất liệu cụ thể như đất sét hay sơn bóng. Chỉ giữ tròn, ấm, sáng, dễ đọc.)

Ba nguyên tắc. Mỗi cái có một test cho lúc mơ hồ.

### 1.1 Đọc được trước, đẹp sau (trụ cột minh bạch)

Game hứa "không giấu gì". Hình ảnh cũng không được giấu: người chơi phải thấy ngay con nào, đòn nào, vào ai, bao nhiêu.

- Mỗi Axie/quái là một silhouette riêng, đọc được khi thu nhỏ. Mỗi icon đọc được ở cỡ nhỏ nhất nó xuất hiện (face 64px, part badge 24–48px, chip nhà 20–24px).
- Chi tiết thêm vào chỉ được giữ nếu nó đổi cách người chơi quyết định. Trang trí không đổi quyết định thì bỏ hoặc làm mờ.
- **Test:** khi mơ hồ, chọn phương án mà nếu thu nhỏ còn 64px (hoặc cỡ nhỏ nhất thật của nó) và làm mờ nhẹ, người xem vẫn nói đúng nó là gì. Ví dụ: nhiều chi tiết nhỏ hay một hình khối to? Chọn khối to.

### 1.2 Tròn, ấm, sáng, dễ đọc (nhận diện Axie)

Axie và đồ Homeland có chung một cảm giác: khối tròn, bo góc, màu bão hoà ấm, sáng, một hướng sáng, viền bằng màu đậm của chính vật đó. Không gắn với chất liệu nào (không "gốm", không "đất sét", không "bóng loáng").

- Không có góc nhọn trên thân, không kim loại lạnh, không chrome, không "công nghệ".
- Nguy hiểm thể hiện bằng màu và nhịp (đỏ, tím, gai) chứ không bằng vẻ đáng sợ. Boss Chimera có thể gai và to, nhưng vẫn là sinh vật Lunacia, không phải quái kinh dị.
- **Test:** khi mơ hồ, chọn phương án mô tả được bằng chữ "tròn, ấm, sáng" và không giống ảnh chụp hay minh hoạ "ngầu". Nếu phải dùng chữ "sắc, lạnh, tối, kim loại" thì làm lại.

### 1.3 Một thế giới, một bàn tay (nhất quán)

Mọi thứ trên màn hình (Axie, quái, nền, icon, khung thẻ, UI) phải như do cùng một xưởng làm.

- Cùng một hướng sáng: từ trên-trái. Cùng kiểu bóng: mềm, một lớp, hơi lệch xuống-phải.
- Cùng ngôn ngữ viền và chất liệu (mục 3 và 4).
- **Test:** khi mơ hồ, đặt asset mới cạnh một asset chính thức (một Axie 3D hoặc một item art-2d như `a16a`). Nếu mắt nhảy ra khỏi ảnh mới vì "khác xưởng" (bóng gắt hơn, viền khác, màu bẩn hơn) thì làm lại. Không "để tạm".

---

## 2. Mood và không khí theo trạng thái game

Quy tắc chung: game sáng và thân thiện. Căng thẳng đến từ nhịp và tương phản cục bộ (boss, danger), không từ việc tối cả màn. Nền không tối hơn #2A2118 [mắt] ở bất kỳ màn nào. Vùng tối chỉ nằm trong khung UI.

| Trạng thái | Cảm xúc | Ánh sáng | 3–5 từ mô tả | Năng lượng | Một vật mang cảm xúc |
|---|---|---|---|---|---|
| **Land hub** | Về nhà, thong thả, tự hào | Ấm, nắng chiều vàng. Tương phản thấp. Nền trời xanh nhạt xuống kem (như ảnh Land hiện tại). | ấm, gọn, thân thuộc, có người ở | Thấp | Cổng đá đỏ (cổng vào run) và các nhà nhỏ có chuyển động nhẹ (cú bay, khói) |
| **Bản đồ run** | Hành trình, tò mò, hơi hồi hộp | Ấm-mát trung tính, ánh sáng từ chân trời. Tương phản vừa. Màu theo biome (mục 4.5). | mở, có đường đi, có mốc, có sương | Thấp-vừa | Con đường vẽ nối các mốc (đất, đá, dây), mốc boss to hơn ở cuối |
| **Combat thường** | Tập trung, rõ ràng, hơi vui | Sáng, nắng nhẹ từ trên-trái. Nền biome thấp bão hoà để Axie nổi. Tương phản vừa. | sáng, gọn, rõ, nhịp đều | Vừa | Axie của mình, màu class rực hơn nền đúng một bậc |
| **Boss** | Áp lực, đáng nể, không kinh dị | Mát và tối hơn combat thường một bậc, vùng sáng cục bộ quanh boss (rim light tím/hồng). Tương phản cao ở boss, nền vẫn thấy rõ. | to, gai, tím, nặng, uy | Cao | Boss Chimera chiếm 1/4 màn, bóng đổ lớn, aura theo phase |
| **Thắng** | Nhẹ nhõm, tự hào, "tôi tính đúng" | Rất ấm, vàng, tia sáng toả từ trên. Tương phản thấp, glow mềm. | ấm, vàng, rộng, ăn mừng nhẹ | Vừa-cao rồi hạ | Tia sáng (rays) toả lên và đống thưởng, nền biome vừa thắng |
| **Thua** (Liam duyệt 28/10: lắng nhưng vẫn ấm, không đỏ, không đen) | Tiếc, nhưng biết tại sao (không phạt cảm xúc) | Ấm giảm sáng, hơi chuyển lạnh xanh-tím nhạt. Vẫn sáng hơn #3A2F26 [mắt]. Không đen, không đỏ. | lắng, mềm, nghiêng, vẫn ấm | Thấp | Axie ngồi/nghiêng nhưng còn nguyên, ánh sáng tắt dần chứ không đổi sang đỏ |
| **Gacha / Echo Box** | Mong chờ, lấp lánh, hứng | Sân khấu: nền tối ấm vừa (nâu tím), một nguồn sáng mạnh từ rương. Tương phản cao nhất game. Mỗi độ hiếm có màu sáng riêng. | sân khấu, lấp lánh, nén rồi nổ | Cao nhất | Rương Echo Box (đã vẽ tay) với tia sáng và hạt theo tier |
| **Menu meta** (Missions, Pass, Run setup, Codex...) | Bình tĩnh, có việc để làm, "bảng thông báo của làng" | Ấm, mờ như nền cảnh Land bị lấy nét xa. Tương phản thấp để UI nổi. | ấm, mờ, gọn, có chất liệu (giấy, gỗ) | Thấp | Nền là cảnh Lunacia mờ (quầy, bảng gỗ, sân), không phải màu trơn |

**Chốt chuyển trạng thái:** đổi mood bằng ánh sáng và màu nền, không đổi bảng màu class. Một Axie Plant luôn xanh lá dù đang thắng hay thua.

**Nền menu meta (Liam duyệt 28/10):** Echo Box, Pass, Missions, Run setup dùng cảnh Homeland render mờ thay cho navy trơn. Nền trơn là lỗi. Lưu ý: việc này mở rộng phạm vi "chỉ dùng art có sẵn" của UI-05 cho phần nền. Cảnh nguồn lấy từ render Homeland/Land 3D, làm mờ, phủ ấm nhẹ.

---

## 3. Ngôn ngữ hình khối

### 3.1 Axie: silhouette

Nhận ra Axie = một thân tròn mập + vài bộ phận nhô ra có hình đặc trưng.

- **Thân:** hình trứng/cầu, rộng hơn cao một chút, không có cổ. Thân chiếm khoảng 55–65% bề rộng silhouette.
- **Sáu bộ phận đọc được ở 64px:**
  - Mắt (eyes) và Tai (ears): ở trên đầu, đọc bằng hình nhô lên.
  - Sừng (horn): nhô lên/ra từ đỉnh đầu, đọc bằng hướng và độ cong.
  - Miệng (mouth): ở mặt trước, đọc bằng hình mỏ/răng/hàm.
  - Lưng (back): nhô trên lưng, đọc bằng silhouette phía sau thân.
  - Đuôi (tail): nhô phía sau-dưới, đọc bằng hình cuối đuôi.
- **Quy tắc đọc 64px (Test A):** đổ Axie ra đen đặc trên nền trắng, thu nhỏ còn 64px cao. Phải thấy: một thân tròn, đúng 1 đuôi, đúng 1 lưng, tai/sừng nhô lên đúng số. Nếu không đếm được, silhouette hỏng.
- **Giải phẫu cố định:** 2 mắt, 1 miệng, 1 sừng chính, 1 cặp tai, 1 lưng, 1 đuôi. Axie không có thêm chân/tay. Thân dưới là một dải tròn có 4 chân ngắn hoặc không thấy chân. Không bao giờ thêm tay, cánh thừa, đuôi đôi.
- **Mỗi bộ phận có class:** màu và hoạ tiết của bộ phận theo class của nó (mục 4.3). Axie có thể có bộ phận khác class thân: đó là điều game muốn người chơi đọc ("lắp ráp bản sắc"). Hình khối phải cho phép nhìn thấy bộ phận khác màu.

### 3.2 Axie so với quái (Chimera và quái Atia)

Người chơi phải biết ai là phe mình trong 0,5 giây, kể cả khi bỏ màu.

| | Axie (phe mình) | Quái / Chimera |
|---|---|---|
| Thân | Cầu mập, bo tròn, trơn | Thân bất đối xứng, có gai/vảy/bướu, một nửa bo một nửa góc |
| Hình học nổi | Vòng cung, ellipse | Hình tam giác/gai/răng cưa là điểm nhấn |
| Tỉ lệ | Cao ≈ rộng | Quái thường và elite cỡ gần bằng Axie (lệch tối đa ±10%), không quá to hay quá nhỏ (Liam 28/10). Boss Chimera giữ cỡ hiện có |
| Mặt | Mắt to, thân thiện | Mắt nhỏ/lệch/nhiều hơn 2 mắt, hoặc che mắt |
| Màu | Bão hoà theo class, sáng | Bảng riêng: tím-hồng-xanh đậm (Chimera) hoặc màu đất (quái Atia thường), thấp bão hoà hơn Axie một bậc |
| Viền sáng | Rim sáng ấm trên-trái | Thêm rim lạnh hoặc tối phía ngược sáng |

- **Test B:** làm silhouette đen. Axie phải trông "tròn mềm", quái phải có ít nhất 2 điểm nhọn hoặc 1 mảng bất đối xứng rõ.
- **Quái thường:** dùng bộ Atia (Liam). Bộ này thân thiện hơn Chimera, nên phải thêm dấu hiệu phe địch bằng màu đỏ-tím ở intent/aura và ở thanh máu, không chỉ bằng hình dáng.
- **Elite:** thêm một lớp viền hoặc aura màu (đã chốt dùng tím-vàng, mục 4.4). Không đổi hình model.
- **Điểm cần sửa (audit):** gà vàng và chuột trắng đang nhìn như đồ placeholder. Không dùng lại khi đã có bộ Atia.

### 3.3 Môi trường

- Hình khối to, bo, ít cạnh: đồi tròn, cây tán xốp, đá bo, bụi cỏ. (Xem `renders/environment/savannah` và các cây `f10a`, `f12a` của art-2d: tán dạng đám mây, đá có rêu.)
- Vùng đi lại và vùng đứng của Axie phẳng và sáng. Vật to, nặng nhìn chung nằm ở rìa và xa, không che hàng đứng.
- Đường chân trời thấp trong combat để Axie nằm trên nền sáng ổn định.
- Công trình Homeland: mái cong, cửa vòm, khối chồng như bánh. Không thẳng đứng cứng, không gạch vuông sắc.
- **Test C:** nền combat đổ xám và làm mờ. Axie và quái vẫn là hai vật rõ nhất, không bị nền "ăn" mất. Nếu có vật nền nào tương phản với Axie hơn chính Axie, giảm nó.

### 3.4 UI echo lại thế giới

- Plate/khung thẻ: góc bo lớn (bán kính ≥ 12px ở 1080p), dày, trông như tấm gỗ/da/vải có độ dày. Không góc vuông, không đường mảnh 1px kiểu app.
- Nút chính: bo lớn, có độ dày (bóng đáy cứng), trông "bấm được". Hình nút gần với thân Axie hơn là hình chữ nhật dashboard.
- Icon: khối đơn giản, bo, có 3 lớp (nền, ký hiệu, highlight), viền cùng hue đậm. Không glyph đơn sắc, không emoji kiểu kiếm-khiên viền đen.
- Đường nét UI cùng ngôn ngữ với Axie: nhịp tròn, không đường chéo lạnh.
- **Test D:** đặt nút/khung bên cạnh một item art-2d (ví dụ `a19b` hộp gỗ). Nếu khung UI trông như một vật trong cùng thế giới, qua. Nếu trông như web app, trượt.

### 3.5 Vai chính và vai phụ

Thứ tự ưu tiên nhìn, từ trên xuống:
1. Axie mình và quái đang bị nhắm (hình to nhất, màu rực nhất, bóng mạnh nhất).
2. Thông tin quyết định (xúc xắc, intent của địch, số sát thương).
3. Nút hành động chính (một nút chính mỗi màn).
4. Nền và trang trí.

Công cụ: hình to và đơn giản = vai chính. Hình nhỏ, nhiều chi tiết, thấp bão hoà = vai phụ. Vai phụ không được có tương phản sáng-tối lớn hơn vai chính.

---

## 4. Hệ màu

### 4.1 Bảng màu chính

Lấy theo art Homeland chính thức và các token đang chạy trong game.

| Tên | Hex | Nguồn |
|---|---|---|
| Kem (chữ, mặt xúc xắc) | #FFE9C2 [mắt] | mặt xúc xắc và chữ trong `01-combat-player-turn` (không dùng trắng thuần) |
| Cam CTA (nút chính) | #FF9345 [code] | `L_PRIMARY` trong `t_ui_laws.gd`, nút "End turn", "Start run" |
| Vàng thưởng / điểm nhấn | #FFC445 [code] | `L_GOLD` |
| Nâu đậm (viền UI) | #24140B [code] | `L_OUTLINE` |
| Nâu viền sáng (đường kẻ) | #8A3E22 [code] | `L_LINE` |
| Nâu mực nhạt (chữ phụ) | #9A7650 [code] | `L_INK_3` |
| Xanh lục tươi (cây, thành công) | #5DBB3A [code] | `L_SUCCESS`, và bụi/cỏ art-2d `f12a` ≈ #7BCB2E [mắt] |
| Xanh ngọc (info) | #5FCFCB [code] | `L_INFO`, tương tự khối băng `a14a` [mắt] |
| Đỏ cam (danger, đe doạ) | #D9472B [code] | `L_DANGER`/`L_THREAT` |
| Vàng đất (savannah) | #F2B632 [mắt] | nền đất `renders/terrain/savannah` |
| Đá be-hồng | #B59A8A [mắt] | `SavannahRock_01` |
| Terracotta | #D9814A [mắt] | `SavannahRock_02`, thùng gỗ `a9a` |

**Quy tắc dùng:**
- Nền (đất, trời, tường) chiếm 60%, màu bão hoà vừa. Vật chính (Axie, thẻ, nút) 30%, bão hoà cao. Điểm nhấn (CTA, thưởng, danger) 10%, bão hoà tối đa.
- Không bao giờ dùng trắng #FFFFFF hay đen #000000 thuần. Trắng nhất là kem, đen nhất là nâu đậm #24140B.
- Bóng luôn là màu đậm cùng hue pha tím/nâu, không phải xám trung tính.

### 4.2 Màu ngữ nghĩa

**6 class (quy ước chính thức của Axie Infinity).** Mỗi class một màu chủ đạo, người chơi Axie biết sẵn:

| Class | Màu | Hex đang dùng trong UI [code] | Ghi chú |
|---|---|---|---|
| Plant | xanh lá | #7DC943 | đúng |
| Beast | cam | #FFB23F | đúng |
| Aqua | xanh dương | #39C5F3 | đúng |
| Reptile | tím | #B679F7 | đúng |
| Bug | đỏ | #F2624F | đúng, nhưng gần màu danger #D9472B |
| Bird | **hồng** (chốt 28/10) | UI đang dùng #8BDCFF (xanh nhạt) | **Cần sửa code**: đổi sang hồng. #8BDCFF quá gần Aqua #39C5F3. |

**Quyết định (Liam 28/10): Bird = HỒNG ở mọi nơi** (màu chính thức của Axie). Hex tạm #FF8FB8 [mắt], sẽ lấy số đo.

**Việc cần sửa (code, ngoài phạm vi art-director):** `CombatView.gd` ~dòng 664–665 và `t_ui_laws.gd` ~dòng 84–85 đang gán Bird = #8BDCFF. `CombatStage3D.gd` dòng 63–84 đã dùng hồng. Sửa hai chỗ đầu về hồng, và sửa test `t_ui_laws` cùng lúc (đổi số kỳ vọng trong cùng commit).

Bug và Danger đều là đỏ: phải tách bằng vị trí và hình, không bằng màu. Danger luôn đi với icon cảnh báo/thanh máu địch. Bug luôn là nền chip class hoặc hoa văn bộ phận. Không dùng màu Bug làm cảnh báo.

**Độ hiếm Core:**

| Tier | Màu | Chất liệu (không chỉ đổi màu) |
|---|---|---|
| Moss | xanh rêu #7DAA48 [mắt] | gỗ/rêu thô, mờ, ít bóng |
| Amber | cam-hổ phách #F2A33A [mắt] | nhựa trong, sáng vàng, có bọt khí |
| Crystal | xanh lơ-tím lạnh #7FB6F0 [mắt] | pha lê cắt cạnh, bóng, phản chiếu |

Độ hiếm đọc theo thứ tự: Moss thấp bão hoà, Crystal sáng nhất và lạnh nhất. Đây là chỗ duy nhất trong game dùng ánh sáng lạnh để báo "hiếm".

**Độ hiếm cosmetic** (Echo Box, 6 tier rương): dùng dãy bronze → silver → gold → ... → lunacian đã có trên rương (`godot/assets/echobox/chests/tiers/`). Giữ đúng màu của art rương, không đổi bảng khác. Quy tắc: tier càng cao càng nhiều ánh sáng và hạt, không chỉ đổi màu viền.

**Danger:** #D9472B [code]. Chỉ dùng cho mối đe doạ, mất máu, nguy hiểm thật (chốt `FIX-PASS`: "red only for danger").

**Elite địch:** tím-vàng (aura). **Boss:** đỏ-tím đậm, thanh máu có vạch phase.

**Gem (tiền thật):** tím #4E2E8A [code, `L_GEM_SHELF`] với viền tím sáng hơn. Chỉ xuất hiện ở bề mặt trả tiền (Gem, Buy, gói). Không dùng tím này cho thứ miễn phí. Tím class Reptile #B679F7 sáng hơn và nhạt hơn nhiều; phân biệt bằng độ đậm và vị trí (Reptile là chip class trên nền sáng, Gem là nền đậm của nút/ô tiền).

### 4.3 Nhiệt độ màu theo biome

Sáu biome theo thứ tự hành trình (`godot/assets/atia/arenas.json`). Giữ Axie luôn là phần bão hoà nhất của khung hình.

| Biome | Nhiệt độ | Màu nền chủ đạo | Ghi chú |
|---|---|---|---|
| Savannah | Ấm | vàng đất #F2B632 [mắt], xanh olive #8AA33A [mắt], terracotta | nắng, cỏ khô, thân cây baobab |
| Forest | Mát-ấm | xanh lá #7BCB2E [mắt], nâu gỗ, rêu | combat thường trong ảnh `01-combat` |
| Arctic | Lạnh | trắng-xanh băng #CFEFF5 [mắt], xanh ngọc, tím nhạt | khối băng như `a14a` |
| Mystic | Lạnh-lung linh | tím, hồng san hô, ngọc lam | như ảnh boss `06-combat-boss`: tím nền + hồng cam cây |
| Genesis | Trung tính-sáng | trắng ngà, vàng nhạt, xanh dịu | cảm giác "khởi nguyên", ít bão hoà nhất |
| Luna | Lạnh-huyền bí | tím xanh sáng, hồng, kem (xem 6.2) | biome cuối + boss cuối (hàng 16–18 run Full); lạ nhất trong 6 biome, vẫn ấm ở viền Axie |

Quy tắc: nền combat thấp bão hoà hơn Axie ít nhất một bậc. Biome lạnh không được làm Aqua (xanh dương) mất tách biệt khỏi nền: ở Arctic, thêm viền sáng ấm cho Axie Aqua.

### 4.4 Màu UI so với màu thế giới

Hiện UI là nâu đậm + kem + cam, tối hơn thế giới. Điều này ổn nếu giữ hai điều:
- Plate UI dùng nâu ấm (#3A2418 đến #24140B [mắt]), không dùng navy/xám xanh như `#12161c`. Navy trơn trong Echo Box, Pass, Missions, Run setup là điểm lệch.
- UI nổi bằng tương phản hình dạng và độ dày, không bằng việc tối hơn nền quá nhiều. Plate ít hơn, mỏng hơn (đúng hướng UI-05).

UI được phép khác thế giới ở đúng ba chỗ: nâu đậm của plate, kem của chữ, cam của CTA. Mọi thứ còn lại (icon, thẻ, khung, thưởng) dùng màu thế giới.

### 4.5 Phương án cho người mù màu

Màu không bao giờ là cách duy nhất báo một thông tin.

- **Class:** thêm hoa văn/hình nhỏ cạnh chip class (lá, sừng, giọt nước, lông, bọ, vảy). Chip class luôn có chữ tắt ở chế độ trợ năng.
- **Độ hiếm Core:** Moss, Amber, Crystal đổi bằng số mảnh (1/2/3), hình khung (thô, bo, nhọn) và chất liệu. Không chỉ viền xanh/cam/lơ.
- **Danger so với Bug:** icon cảnh báo luôn đi cùng đỏ danger. Thanh máu địch có vạch/dấu riêng.
- **Aqua so với Bird:** Bird hồng, Aqua xanh dương: khác hẳn về hue. Vẫn giữ hoa văn riêng cho từng class như trên.
- **Test E:** chuyển ảnh sang thang xám. Mỗi cặp trạng thái (class cạnh class, tier cạnh tier, danger cạnh bình thường) vẫn phân biệt được bằng hình hoặc độ sáng. Nếu hai thứ thành cùng một xám, thêm một dấu hiệu hình.

---

## Dấu hiệu AI cần loại

Liam nói ảnh AI trông xấu, không tự nhiên. Danh sách dưới đây dùng để chấm điểm. Mỗi ảnh mới (đặc biệt từ AI) phải trượt 0 mục. Trượt từ 1 mục, làm lại hoặc dọn tay.

1. **Bóng nhựa (plastic gloss):** highlight lớn, chrome, bề mặt trơn như ảnh quảng cáo 3D. Art chính thức có một highlight nhỏ, mờ.
2. **Giải phẫu bộ phận sai:** Axie có thêm chân, tay, đuôi đôi, sừng ở chỗ lạ, mắt không đối xứng. (Test A đếm bộ phận.)
3. **Chi tiết thừa/nhiễu:** hoa văn li ti, texture hạt trên cả ảnh. Art chính thức: mảng màu lớn, ít chi tiết, nét vẽ có chủ ý.
4. **Gradient bẩn:** chuyển màu mờ đục, màu hai bên pha bùn xám. Art chính thức chuyển màu bằng 2–3 mảng tone (sáng, giữa, tối) rõ.
5. **Chữ giả (text-like squiggles):** nét nguệch ngoạc giống chữ trên nhãn, biển, thẻ. Mọi chữ phải là chữ thật do mình đặt, hoặc để trống.
6. **Viền không đều:** nét viền chỗ dày chỗ mỏng, đứt, hoặc có viền đen thuần ở nơi khác dùng viền cùng hue.
7. **Hướng sáng lung tung:** bóng và highlight từ nhiều phía. Mỗi ảnh một hướng, trên-trái.
8. **Bóng đổ/đáy không tồn tại:** vật lơ lửng, không có bóng tiếp đất như vật trong game.
9. **Bão hoà sai:** màu quá chói (neon) hoặc quá xỉn. Bảng màu ngoài mục 4.
10. **Tỉ lệ lệch xưởng:** thân Axie quá cao/gầy, đầu quá nhỏ, mắt thực tế. Axie mập, mắt to.
11. **Nền ngẫu nhiên:** nền có nhân vật/đồ vật không ai đặt, hoặc đồ vật kỳ lạ nhìn như mơ.
12. **Cạnh nhoè/halo khi tách nền:** viền trắng-xám quanh icon sau khi cắt nền.

Cách chấm: soi ảnh ở 100% và ở 25%. Ở 25% chỉ còn silhouette và mảng màu: nếu mất đọc được thì hỏng mục 1.1. Ở 100% đi qua 12 mục trên.

## Cách tạo ảnh đúng chất

1. **Nhân vật (Axie, quái, boss):** không bao giờ để AI vẽ. Dùng render từ model 3D thật (Axie đang chạy trong game, quái Atia, Chimera). Render bằng Blender hoặc Godot với cùng rig sáng. Kết quả là đúng giải phẫu và đúng màu.
2. **AI chỉ cho nền, hoạ tiết, hạt, texture chất liệu** (nền menu, nền map, texture khung Moss/Amber/Crystal, tia sáng). Không cho icon Core có hình sinh vật, không cho Axie.
3. **Luôn kèm ảnh tham chiếu chính thức:** 3–5 ảnh từ `asset-library/design-library/` cùng loại (ví dụ nền: `art-2d/environment` và `renders/environment/<biome>`; vật thể: `art-2d/items`). Không đưa tham chiếu từ game khác.
4. **Prompt khung cố định**, chỉ đổi phần [CHỦ ĐỀ]: "Soft rounded stylized game illustration in the style of Axie Infinity Homeland official art, round warm bright look, bold flat colour shapes with 2–3 tone shading, thin darker-hue outline of the same colour (no black outline), single light from top-left, soft contact shadow, warm saturated palette, no text, no chrome, no photo realism, [CHỦ ĐỀ]". Lưu prompt thật đã dùng cùng ảnh ra (để lặp lại và audit).
5. **Dọn tay bắt buộc:** tách nền sạch (không halo), cân lại màu về bảng mục 4, vẽ lại/xoá chi tiết thừa, thống nhất độ dày viền, đảm bảo icon 3 lớp (nền, ký hiệu, highlight).
6. **Cổng duyệt:** ảnh mới chỉ vào game sau khi qua checklist 12 mục, 5 test A–E, và so cạnh một asset chính thức. Người duyệt: art-director, sau đó Liam duyệt mẫu đầu tiên của mỗi loại trước khi làm hàng loạt.
7. **Làm mẫu trước:** mỗi loại (icon Core, emblem nhà, khung thẻ, nền menu) làm 3–6 mẫu, Liam chốt, rồi mới làm cả bộ. Đúng với Liam đã duyệt ở audit: làm sau khi UI-05 đợt 1 chốt phong cách.

---

## 5. Nhân vật (nháp)

### 5.1 Axie (phe mình)

- **Luôn là model 3D thật** hoặc ảnh render từ chính model đó. Không bao giờ AI vẽ Axie, không vẽ tay lại, không dùng ảnh Axie từ nguồn khác.
- **Tư thế:** idle nghiêng nhẹ về phía địch, trọng tâm thấp, thân hơi nhún (nhìn như sẵn sàng, không căng). Đòn đánh có anticipation rõ (lùi 0,1–0,15s rồi lao). Không tư thế "ngầu" gồng người.
- **Biểu cảm:** mắt to, mở. Thường: tò mò/tập trung. Đánh: mắt nheo hoặc miệng mở. Trúng đòn: nhắm mắt ngắn. Hết máu/thua: mắt vẫn mở, cụp tai, ngồi xuống (xem mục 2, thua). Không có biểu cảm đáng sợ hay độc ác.
- **Đọc bộ phận (6 bộ phận, xem 3.1):** camera combat phải cho thấy mắt, tai, sừng, miệng, lưng, đuôi cùng lúc, nên Axie đứng chéo 3/4 hướng về địch, không đứng thẳng ngang (che lưng) hay quay mặt thẳng (che đuôi). Không để vật nền, hiệu ứng hay UI che đuôi và lưng, vì đó là nơi người chơi đọc bộ phận khác class.
- **Ánh sáng:** rim sáng ấm từ trên-trái, cùng rig cho mọi Axie để không có con nào "khác xưởng".

### 5.2 Quái thường (bộ Atia)

- Liam chốt: quái thường lấy từ bộ quái Atia (`asset-library/godot-ready/...` mục Monster). Gà vàng và chuột trắng hiện tại là placeholder, bỏ.
- Chọn quái theo biome (mục 6) và theo test B: có ít nhất 1 nét bất đối xứng hoặc điểm nhọn so với Axie. Bộ Atia thân thiện hơn Chimera, nên dấu hiệu địch đến từ màu và UI (thanh máu, intent, vòng chân), không chỉ từ hình.
- Không tô lại màu model Atia cho đồng bộ. Dùng đúng màu chính thức, chỉ chỉnh ánh sáng và vòng chân.

### 5.3 Boss Chimera

- To (chiếm khoảng 1/4 màn), gai, bảng tím-hồng-xanh đậm, vẫn là sinh vật Lunacia (xem 1.2).
- Có phase: đổi bằng aura/rim light và mảng màu trên thân, không đổi model. Mỗi phase một màu aura riêng, và thanh máu có vạch phase.
- Camera dành chỗ cho bóng đổ lớn và aura. Không che UI quan trọng (intent, mục tiêu).

### 5.4 Phân biệt trong 0,5 giây

Bốn lớp, đi từ rẻ đến đắt. Mỗi vai phải khác ít nhất 2 lớp.

| Vai | Hình | Vòng chân / đế | Thanh máu / nhãn | Aura / rim |
|---|---|---|---|---|
| Axie phe mình | Tròn mập (3.1) | Vòng ấm xanh lá-kem | Thanh máu xanh/kem, chip class | Rim ấm trên-trái |
| Axie đang được chọn / target | như trên | Vòng sáng dày hơn, nhịp thở | Mũi tên xuống hoặc khung nhắm | Sáng hơn một bậc |
| Quái thường | Atia, bất đối xứng nhẹ | Vòng đỏ-nâu | Thanh máu đỏ, chip intent | Không |
| Elite | Cùng model, cùng cỡ quái thường (phân biệt bằng vòng chân, nhãn, aura) | Vòng tím-vàng | Nhãn "ELITE" cộng dấu hiệu hình | Aura tím-vàng mảnh, viền sáng |
| Boss | Chimera, 3–4 lần Axie | Vòng đỏ-tím đậm, rộng | Thanh máu to có vạch phase | Aura theo phase, bóng đổ lớn |

Lưu ý hợp với mục 4.5: không phân biệt chỉ bằng màu. Vòng chân khác nét (liền, đứt, đôi) và nhãn có chữ/biểu tượng.

### 5.5 LOD ở khoảng cách camera game

- Camera combat cố định, nên chỉ cần 1 mức model chi tiết cho nhân vật trong trận. Không dùng bản cao poly chỉ để khoe.
- Chi tiết dưới khoảng 3px ở 1080p không đọc được, bỏ hoặc gộp vào một mảng màu (hoa văn li ti trên bộ phận).
- Ở 1280x720 các nhân vật vẫn phải qua Test A và Test B. Nếu rơi, tăng khoảng cách vòng chân/thanh máu chứ không phóng to model.
- Texture bộ phận Axie giữ nguyên màu và hoa văn gốc. Dùng mip đủ để không lấp lánh khi camera chuyển.

### 5.6 Ảnh 2D của nhân vật (thẻ, portrait, thumbnail)

- Luôn là **render của model 3D thật** + nền vẽ. Không có Axie do AI vẽ. AI chỉ được làm phần nền (xem "Cách tạo ảnh đúng chất").
- Một rig render chung cho cả 6 class: cùng góc 3/4, cùng ánh sáng trên-trái, nền trong suốt, rồi ghép lên nền theo class (nền màu class, hoạ tiết nhẹ).
- Cắt ảnh: thấy đủ đầu và đuôi. Hiện portrait run setup cắt ở ngực với nền xám phẳng: sửa thành nền theo class và để thấy cả thân.
- Quái Atia/Chimera làm cùng cách: render 3D, nền theo biome. Avatar 96px trên thẻ intent phải qua Test B ở cỡ đó.

---

## 6. Môi trường (nháp)

### 6.1 Triết lý texture

Painted stylized, không PBR thực. Mảng màu lớn, 2–3 tone, nét chuyển rõ, ít noise. Không texture ảnh chụp, không normal map gồ ghề, không bóng phản chiếu. Vật liệu đọc được từ màu và hình (gỗ ấm nâu, đá be-hồng bo tròn, cỏ xanh vàng), không từ chi tiết bề mặt. Mọi nền phải qua Test C (xem 3.3).

### 6.2 Sáu biome

Bộ nguồn: Homeland kit (`renders/environment/<biome>/`, `renders/terrain/<biome>/`). Mỗi biome có một bảng màu, một silhouette đặc trưng và một vật mang tên biome.

| Biome | Cảm giác | Bảng màu (xem 4.3; hex đo sẽ gộp sau) | Silhouette đặc trưng | Vật mang biome |
|---|---|---|---|---|
| Savannah | Ấm, khô, rộng | vàng đất, olive, terracotta | cây tán dẹt, đồi thấp, đá be-hồng bo (`SavannahRock_01/02`, `S_Tree01–03`) | cây tán dẹt, đá lớn |
| Forest | Mát, ẩm, rậm | xanh lá, nâu gỗ, rêu | tán xốp như mây, bụi tròn | thân cây to có rêu |
| Arctic | Lạnh, sạch | trắng-xanh băng, xanh ngọc, tím nhạt | khối băng, cây phủ tuyết | khối băng bo tròn |
| Mystic | Lạnh-lung linh | tím, hồng san hô, ngọc lam | cây cong, đá phát nhẹ (`M_Tree_01`, `Rock_01`) | cây cong cánh hoa |
| Genesis | Sáng, khởi nguyên | trắng ngà, vàng nhạt, xanh dịu | cây thanh, ít vật (`SM_Tree_G_01`, `SM_Tree_G_05_01`) | cây thanh sáng |
| Luna | Lạ, xa, hơi huyền bí | tím xanh sáng, hồng, kem | địa hình lạ, đám mây Luna Landing (`art-2d/environment/luna_landing_*`) | mây Luna và cây Luna Landing |

Lưu ý: 4.3 đang liệt kê 5 biome, thiếu Luna. Khi gộp số đo màu, thêm hàng Luna vào 4.3. Luna nên là biome cuối hoặc đặc biệt (boss cuối), không phải biome đầu.

### 6.3 Mật độ vật trên mỗi màn

| Màn | Mật độ | Quy tắc |
|---|---|---|
| Combat arena | Thấp | Sàn phẳng sáng, 3–6 vật to ở rìa và xa. Tối đa 2 vật chuyển động (mây, lá). Không vật nào cao hơn hoặc tương phản hơn Axie. |
| Run map | Trung bình | Đường vẽ là vật chính. Mốc rõ. Phần nền thấp bão hoà, vật nền không vẽ đè đường và node. |
| Land hub | Cao hơn | Nơi duy nhất được nhiều chi tiết (nhà, người, thú). Vẫn giữ vùng đi lại trống. Mỗi nhà một việc, vật thừa (cú, Axie đè cây) phải có chủ ý hoặc bỏ. |
| Menu meta | Rất thấp | Nền mờ, chỉ còn mảng màu và vài khối lớn. |

### 6.4 Kể chuyện bằng môi trường

Mỗi vật nền phải nói được một điều nhỏ: biển báo bị gãy gần quái elite, dấu chân và lửa trại cạn gần node nghỉ, rễ cây bị gai Chimera xé gần boss. Đặt ở rìa, không trên đường đi. Ít nhưng thật: 1–2 vật kể chuyện mỗi màn là đủ. Nếu vật không nói gì, bỏ nó.

### 6.5 Nền bản đồ run theo biome

- 1 nền cho mỗi biome (6 nền), dựng từ render Homeland kit, góc nhìn từ trên xuống hơi nghiêng, đường chân trời thấp.
- Thấp bão hoà hơn node và đường. Vùng giữa trống để đường đi và node đọc được ở 1280x720.
- Biome đổi thì màu nền và vật đặc trưng đổi, đường vẽ và icon node giữ nguyên (người chơi học một lần).
- Nền menu meta: cảnh Homeland render mờ (mục 2), cùng nguồn nhưng làm mờ nhiều hơn.

---

## 7. UI/HUD (nháp)

Nguồn hướng: `design/handoffs/ui-05-figma/PROMPT-UI05-FIGMA.md` §2. Ba ý: mobile thương mại (chunky, dày, nút bấm được), Axie/Lunacia (mềm, tròn, ấm), ít hộp nhiều thế giới.

### 7.1 Ngôn ngữ chung

- **HUD mỏng, nổi trên 3D:** chip và cụm nhỏ ở rìa. Không panel nào lớn hơn nội dung. Trong combat, người chơi thấy nhiều arena hơn UI.
- **Ít plate:** gộp các ô thành một cụm khi cùng nghĩa. Plate là nâu ấm #24140B (đã duyệt), góc bo lớn (3.4).
- **Nút:** dày, bo lớn, bóng đáy cứng khi nhả, thấp xuống và tối hơn khi bấm. Một nút chính (cam CTA) mỗi màn. Thông số trạng thái nút theo spec DangoTheme (hover sáng hơn, pressed tối + dày + trượt xuống).
- **Chữ:** Rowdies cho tiêu đề và số lớn, Work Sans cho thân. Chữ kem, không trắng thuần. Số quan trọng (sát thương, máu, giá) to và dày, có viền nâu mỏng.
- **Màu:** quy tắc 4.4. Gem tím chỉ ở bề mặt trả tiền. Đỏ chỉ cho danger.
- **Bóng:** cứng, không blur, lệch xuống-phải nhẹ. Đồng ý với giới hạn Godot trong UI-05 (không gradient trên panel, không blur).

### 7.2 Họ icon

Một họ duy nhất cho toàn game:

- Hình **đặc (filled)**, góc bo, cạnh tròn. Không nét mảnh, không glyph đơn sắc kiểu app.
- **Viền cùng hue, đậm hơn**, dày đều theo cỡ (độ dày cụ thể ở mục 8). Không viền đen.
- **Một hướng sáng** trên-trái: highlight nhỏ ở góc trên-trái, bóng đáy phía dưới-phải.
- 3 lớp: nền (hình khung), ký hiệu (vật thể), highlight.
- Cùng độ bão hoà với Axie. Không lẫn bộ cũ PNG/SVG khác kiểu (audit: 2 bộ face, 2 bộ node đang tồn tại, giữ 1 bộ).

### 7.3 Cách làm icon hàng loạt: khung chung + ký hiệu riêng

Bắt đầu từ khung, vì khung làm một lần, ký hiệu làm nhiều.

| Loại | Số lượng | Khung chung | Ký hiệu riêng |
|---|---|---|---|
| Core | 93 | Khung theo tier: Moss gỗ/rêu thô, Amber nhựa trong, Crystal pha lê (chất liệu khác, không chỉ màu viền; xem 4.2) | Một vật dễ gọi tên (trứng vàng, tổ, vảy, nến...). Màu ký hiệu theo trục/nhà. Làm trước 30 Core hay gặp |
| Luật run | 21 | Một khung thống nhất (hình biển/ấn) khác khung Core để không lẫn | Một hình cho mỗi luật. Thấy trên HUD cả run nên phải nhận ra ở 24px |
| Emblem nhà | 6 (Kin, Embers, Big Hand, Gambler, Mana Mine, Volley) | Khung lớn: hình khiên/ấn riêng mỗi nhà, bảng 3 màu riêng | Một hình đặc trưng mỗi nhà. Có bản awakened (nở/phát sáng, làm bằng lớp thêm) và chip 20–24px đọc được |
| Part badge | 36 (6 bộ phận x 6 class) | Nền tròn màu class, viền đậm | Silhouette bộ phận lấy từ model Axie thật (cắt ra). 24–48px, hoa văn class nhỏ cho người mù màu |
| Tiền tệ | 5 | Mỗi loại một hình riêng (không cần khung chung) nhưng cùng vật liệu: bóng nhẹ, sáng | Gem sáng nhất vì là tiền thật. Shard/Stone không được xám/tối |
| Face xúc xắc | ~12 | Không khung, vì nằm trên mặt xúc xắc | Hình mềm, viền đậm, đủ đậm để đọc trên mặt kem |
| Node bản đồ | 7 loại, 3 trạng thái | Vòng đá/gỗ chung | Một hình mỗi loại. Trạng thái bằng tông (sáng, mờ, khoá) |

Chốt: người thiết kế chỉ phải vẽ khung một lần. Ký hiệu nhỏ nhất đọc được ở cỡ nhỏ nhất của nó (1.1).

### 7.4 Tranh Anchor (thẻ minh hoạ cảnh)

- Liam chốt: Anchor là thẻ bài có **tranh minh hoạ cảnh**, không phải glyph trong ô.
- Mỗi nhà một cảnh Homeland/Lunacia kể một ý của nhà: ví dụ Kin = tổ/trứng ấm, Embers = lửa trại, Big Hand = bàn tay khổng lồ, v.v. Tỉ lệ khoảng 512x320.
- Cảnh phải đọc được ở thumbnail. Một vật chính to, phông thấp bão hoà, ánh sáng trên-trái.
- Nếu có Axie trong cảnh, đó là render 3D thật (5.6). AI chỉ làm phần cảnh/nền, theo quy trình "Cách tạo ảnh đúng chất". Cảnh trượt checklist 12 mục thì làm lại.
- Màu khung theo nhà. Khung dùng chung cho cả 6 nhà, chỉ đổi màu và hoạ tiết viền.

### 7.5 Cảm giác chuyển động (animation feel)

- **Nhịp:** snappy rồi mềm. Ra nhanh (100–150ms), dừng có overshoot nhẹ và nảy lại ngắn. Không ease tuyến tính.
- **Bấm nút:** lún xuống ngay lập tức, bật lại có nảy nhỏ.
- **Thưởng:** kéo dài hơn một nhịp (số đếm lên, hạt toả, ánh sáng). Càng hiếm càng lâu và nhiều ánh sáng.
- **Hiện thẻ:** thẻ bay lên rồi lật hoặc nảy, mỗi thẻ cách nhau 60–80ms.
- **Chờ:** pulse nhẹ ở nút chính. Không nháy mạnh.
- **Giảm chuyển động:** có chế độ reduce motion (đã làm). Mọi hiệu ứng phải có phiên bản tĩnh: bỏ nảy, giữ trạng thái cuối.
- **Không** shake màn hình mạnh, không flash trắng, không đỏ nhấp nháy (an toàn thị giác).

### 7.6 UX check list (kiểm trước khi duyệt mỗi màn)

Đánh dấu từng dòng. Màn nào trượt 1 dòng thì sửa trước khi vào game.

**Đọc được ở 1280x720**
- [ ] Mọi chữ thân >= 16px, số quan trọng >= 24px.
- [ ] Mọi vùng bấm >= 44px.
- [ ] Icon nhỏ nhất vẫn đọc được (face 64px, badge 24px, chip 20px). Nếu không đọc được thì đơn giản hoá icon, không phóng to.
- [ ] Một nút chính duy nhất, mắt tìm ra trong 1 giây.
- [ ] Không có vùng UI che đuôi/lưng Axie hoặc intent của địch.

**Người mù màu**
- [ ] Xem ở thang xám: class, tier, danger vẫn phân biệt được (Test E, 4.5).
- [ ] Mỗi trạng thái có thêm dấu hiệu hình ngoài màu (hoa văn, số mảnh, biểu tượng, chữ).
- [ ] Bug với Danger tách bằng vị trí/hình.

**Tương phản**
- [ ] Chữ kem trên plate nâu: tỉ lệ >= 4,5:1 cho chữ thân, >= 3:1 cho chữ lớn.
- [ ] Chữ trên nền 3D/cảnh mờ luôn có plate hoặc viền nâu.
- [ ] Nút chính cam: chữ trên nút đạt >= 4,5:1 (đã có lỗi ở chữ trên nút chính, xem spec nút).
- [ ] Trạng thái vô hiệu (disabled) vẫn đọc được và có lý do bằng chữ.

**Khác**
- [ ] Hiệu ứng có bản reduce motion.
- [ ] Không có "undefined", "NaN", ID debug, ghi chú dev trên UI.
- [ ] Hình có chữ thật đã đặt, không có chữ giả của AI.

---

## 8. Chuẩn asset (nháp, technical-artist)
Căn cứ: Godot 4.7.2, web `gl_compatibility` + desktop, stretch `canvas_items` + `expand` ở 1920x1080. Số liệu "hiện có" lấy từ `godot/` ngày 28/10. Mục "Đề xuất" là quyết định mới, cần Liam/art-director duyệt.

### 8.1 Định dạng

| Loại | Định dạng | Hiện có | Ghi chú |
|---|---|---|---|
| Icon phẳng, nét sạch (UI, glyph cơ chế) | SVG | `assets/icons/hl/*.svg`, `assets/icons/web/` (12 svg) | Godot rasterise SVG lúc import, nên chỉ dùng SVG đơn giản (path + fill). Không filter, blur, mask, gradient phức tạp. Một số icon có thêm bản `.png` cạnh `.svg` (vd `aid.png`/`aid.svg`) |
| Art vẽ tay, tranh, thẻ, quái, boss, hậu cảnh | PNG (alpha) | `assets/cards`, `assets/monsters`, `assets/backgrounds` (vd `plant_landscape.png` 2048x1252) | Nguồn lưu PNG. Không dùng JPG (không có alpha, có vệt nén) |
| Texture 3D Axie | PNG nguồn + WebP | `addons/axie_mixer_3d_assets/textures/` có cả `.png` lẫn `.webp` | Export web/mac loại `*.png` của thư mục này (`exclude_filter`), chỉ gửi WebP. Giữ nguyên quy ước này |
| Mô hình 3D | GLB | `assets/dice/axie_die.glb` (23 KB), `assets/atia/arena_v2/*/…_arena.glb` (~1.3 MB mỗi arena) | glTF binary, một file một vật |
| Texture hạt, VFX | PNG (alpha) | `assets/vfx/<class>_<skill>.png` (38 MB tổng) | |
| Font | TTF | `assets/fonts/` | UI3 dùng Rowdies 700 + Work Sans 400; `fonts/LICENSE.md` còn ghi Baloo 2 (cũ, nên dọn) |

**WebP cho 2D:** Godot import được WebP nhưng sau import vẫn là texture trong `.godot/imported/`, nên WebP chỉ giảm dung lượng nguồn trong repo, không giảm dung lượng build (build dùng bản đã import: lossless hoặc VRAM). Đề xuất: PNG cho nguồn 2D; không đổi sang WebP trừ file 3D texture như hiện tại.

**Xung đột ideal vs engine:** art lý tưởng muốn gradient mềm, bóng blur, viền mảnh. UI3 cấm blur/gradient/mask/shader trên UI (`godot/CLAUDE.md`), nên asset UI phải là mảng phẳng + viền + bóng cứng. Tranh minh hoạ (thẻ, hậu cảnh) vẫn được vẽ tay đầy đủ vì không phải StyleBox.

### 8.2 Độ phân giải

Hiện có (đo): icon `web/armor.png` 128x128, `hl/gem.png` 256x236?, thẻ `card_hp.png` 320x320, quái `aqua-wolf.png` 256x142, portrait 256x256, hậu cảnh 2048x1252, VFX tới 2472x1752.

Đề xuất (nguồn lớn hơn một bậc so với kích thước hiển thị tối đa ở 1920x1080):

| Loại | Kích thước nguồn | Ghi chú |
|---|---|---|
| Icon glyph | SVG, hoặc PNG 64 / 128 / 256 (bội 2, vuông, hiển thị 32-64 px ở 1080p) | PNG cần 2x so với kích thước hiển thị để rõ ở màn lớn |
| Icon lớn, huy hiệu | 256 (hoặc 512 nếu hiển thị > 128) | |
| Nghệ thuật thẻ / quái / portrait | 512 x 512 (cạnh dài, giữ tỉ lệ), tối đa 1024 cho boss | 256 hiện có đủ ở 1080p nhưng mờ khi người chơi phóng to hoặc màn 4K |
| Hậu cảnh | 1920 x 1080 tối thiểu; 2x (3840 x 2160) chỉ khi cần cho màn lớn | Đề xuất: 2048 chiều ngang như `plant_landscape` là mức mặc định; 2x không cần ở web vì chiếm VRAM |
| Texture hạt | 128 - 256 | một hạt nhỏ không cần lớn hơn |
| Vật 3D (props) | texture 512 (nhỏ) - 1024 (lớn); atlas dùng chung | |

Quy tắc: kích thước là bội của 8 (lưới 8 px của UI3), nguồn PNG vuông là luỹ thừa 2 chỉ khi cần mipmap/nén VRAM. Ảnh 2D không-mipmap không bắt buộc luỹ thừa 2.

**Xung đột:** "không giới hạn dung lượng web" nhưng thời gian tải vẫn quan trọng. `assets/` đã 14 MB hậu cảnh, 34 MB boss, 55 MB atia, 85 MB land. Mỗi lần nâng 2x chi phí tăng 4 lần (VRAM và tải). Đề xuất: 1x cho hầu hết, 2x chỉ cho hero art xuất hiện một lần/màn.

### 8.3 Đặt tên

Quan sát hiện có: chữ thường, `kebab-case` cho quái (`aqua-wolf.png`, `forest-slime-fighter.png`), `snake_case` cho icon, VFX, thẻ (`card_hp.png`, `bird_bite.png`), biến thể class đứng trước (`back-aqua.png`, `bird_slash.png`). Đề xuất để thống nhất cho asset mới:

- `snake_case`, chữ thường, không dấu, không khoảng trắng.
- Mẫu: `<loại>_<tên>[_<biến thể>][_<kích thước>].png`, vd `icon_reroll_128.png`, `card_relic_r3.png`, `vfx_bird_bite.png`.
- Class: `aqua | beast | bird | bug | plant | reptile` (đúng tên enum).
- Không đổi tên file đã dùng (đường dẫn nằm trong data/test). Chỉ áp dụng quy ước cho file mới.

### 8.4 Thư mục

Giữ nguyên bố cục `godot/assets/` hiện có: `icons/{hl,web}`, `ui3/icons`, `cards`, `monsters(+anim)`, `bosses`, `portraits`, `backgrounds`, `vfx`, `dice`, `echobox`, `cosmetics`, `atia`, `land`, `fonts`, `data`, `audio`.
- Asset mới đặt vào thư mục cùng loại, không tạo thư mục gốc mới.
- Nguồn lớn / chưa xử lý ở ngoài `godot/` (`asset-library/`, `design/handoffs/`), chỉ chép bản đã làm sạch vào `godot/assets/`.
- Mỗi lô asset có manifest JSON (như `cosmetics_manifest.json`, `atia_models.json`) khi data cần tra theo id.

### 8.5 Import setting (web + desktop)

Hiện trạng: `textures/vram_compression/import_etc2_astc=true`; PNG import mặc định `compress/mode=0` (lossless), `mipmaps/generate=false`, `fix_alpha_border=true`, `premult_alpha=false`. Export Web `vram_texture_compression/for_desktop=true`, `for_mobile=false`. macOS `s3tc_bptc=true`.

| Loại | Compress | Mipmaps | Filter | Ghi chú |
|---|---|---|---|---|
| Icon, UI 2D | Lossless | Tắt | Linear (mặc định canvas) | Bỏ mipmap vì UI vẽ gần 1:1. `fix_alpha_border` giữ BẬT |
| Art thẻ / quái / hậu cảnh | Lossless; hậu cảnh lớn có thể Lossy 0.7 nếu tải chậm | Bật nếu bị thu nhỏ nhiều (stretch 1280x720 = 0.667) | Linear + mipmap | Mipmap tránh răng cưa khi scale; nó tăng 33% VRAM |
| Texture 3D | VRAM Compressed (hoặc WebP) | Bật | Linear mipmap | Axie dùng WebP + loại PNG khỏi export |
| VFX hạt | Lossless | Tắt | Linear | Bắt buộc alpha sạch (thấy rõ khi cộng màu) |
| SVG | Mặc định | Tắt | | Đặt scale import để cạnh 2x so với kích thước hiển thị |

**Xung đột:** nén VRAM (ETC2/ASTC cho mobile, S3TC cho desktop) làm màu phẳng bị dải và ăn viền alpha: art UI phẳng nên giữ Lossless. Chỉ texture 3D/hậu cảnh lớn mới cân nhắc nén. Web `gl_compatibility` không hỗ trợ một số tính năng (không compute, không SDFGI); xem mục 8.6.

### 8.6 Ngân sách 3D (đề xuất, chưa đo trên thiết bị yếu)

Chưa có số liệu đo của game; các số sau là đề xuất cần `performance-analyst` xác nhận bằng profile trên web.

| Thứ | Đề xuất |
|---|---|
| Axie (axie_mixer_3d) | không tự sửa; dùng GLB chính thức |
| Prop nhỏ (cỏ, đá, thùng) | <= 1.500 tam giác, 1 material, texture <= 512 |
| Prop vừa (cây, trụ) | <= 5.000 tam giác, texture <= 1024 |
| Một arena diorama | tổng <= 150.000 tam giác (arena hiện ~1.3 MB GLB); draw call <= 150 |
| Material | flat / toon đơn giản; không custom shader nặng, không realtime shadow thừa trên web |
| Hạt trong cảnh | <= 200 hạt cùng lúc mỗi hiệu ứng (đề xuất) |

Phong cách theo art bible: khối low-poly có cạnh vát, texture vẽ tay, không PBR thực tế.

### 8.7 Làm sạch asset do AI / Claude Design tạo

Kiểm từng bước trước khi chép vào `godot/assets/`:

1. **Nền:** alpha thật, không phải nền trắng/ca-rô giả. Mở trên nền tối và nền sáng.
2. **Viền alpha:** không quầng trắng/đen. Dùng bản `fix_alpha_border` của Godot, và xoá màu pixel trong vùng trong suốt (dilate màu viền ra ngoài, không để RGB rác).
3. **Padding:** chừa >= 4 px (icon 128) hoặc 2-3% mỗi cạnh trống quanh vật, đều nhau; không để vật chạm mép ảnh.
4. **Lưới pixel / kích thước:** đúng kích thước đặt hàng (bội 8); căn tâm nếu là icon; không bị nội suy mờ do resize bằng tay.
5. **Màu:** đo lại bằng hex trong `palette-measured.md`/mục 4. Không trắng #FFFFFF / đen #000000 thuần; nâu đậm #24140B thay cho đen.
6. **Dấu hiệu AI:** làm theo danh sách "Dấu hiệu AI cần loại" ở mục 4 (giải phẫu sai, chữ giả, chi tiết lạc hướng).
7. **Cạnh nhìn từ xa:** thu nhỏ về 50% và thang xám để kiểm đọc được (Test E).
8. **Đặt cạnh asset chính thức:** test của mục 1. Nếu mắt nhảy khỏi ảnh, làm lại.

### 8.8 Danh sách giao asset

- [ ] Tên theo 8.3, đúng thư mục 8.4.
- [ ] Kích thước theo 8.2 và là bội 8; nguồn lưu lại (ngoài `godot/`).
- [ ] Alpha sạch, padding đều, không quầng viền.
- [ ] Màu đo đúng palette; không trắng/đen thuần.
- [ ] Icon: SVG hợp lệ hoặc PNG 2x; đọc rõ ở 50%.
- [ ] Import setting theo 8.5; chạy `--import` không lỗi.
- [ ] 3D: số tam giác, texture và material trong ngân sách 8.6.
- [ ] Đã đặt trong game, chụp ở 1920x1080 và 1280x720 (`godot/tools/shot.sh`).
- [ ] Có dòng nguồn/giấy phép (AI, Claude Design, Homeland/Atia) trong manifest hoặc README.
- [ ] `godot/tools/run_tests.sh` xanh (có test `t_assets`).
- [ ] Review bởi agent khác, rồi mới báo Liam.

### Chỗ còn mở (cần Liam / art-director)

- Giữ PNG cho nguồn 2D, hay thật sự chuyển WebP? (tôi đề xuất giữ PNG.)
- Hậu cảnh 2x có cần không (ảnh hưởng tải web)?
- Ngân sách 3D ở 8.6 là đề xuất, chưa đo.
- Dọn `fonts/LICENSE.md` (còn ghi Baloo 2).

## 9. Tham chiếu (nháp)

Chỉ dùng art chính thức của Axie/Homeland/Atia (Liam). Mỗi nguồn: lấy gì, tránh gì. Xem contact sheet ở `asset-library/design-library/_sheets/` trước khi mở từng file.

1. **Biểu tượng vật phẩm Homeland:** `asset-library/design-library/icons/` (65 file, ví dụ `egg.png`, `diamond.png`, `ingot_gold.png`, `gem_red.png`, `stone_block.png`).
   - Lấy: hình khối bo tròn, viền cùng hue đậm, một highlight nhỏ, bóng đáy mềm. Đây là gốc cho họ icon (7.2). Cũng dùng được trực tiếp cho tiền tệ và vài Core (trứng).
   - Tránh: copy y nguyên làm icon Core có nghĩa khác (táo không phải Core). Không dùng thực phẩm/nông sản làm ký hiệu chiến đấu.
2. **Art 2D vật phẩm:** `asset-library/design-library/art-2d/items/` (192 file, ví dụ `a16a`, `a19b` hộp gỗ, `a9a` thùng, `a14a` khối băng).
   - Lấy: tiêu chuẩn "mảng màu lớn, 2–3 tone, nét có chủ ý". Dùng làm tham chiếu so cạnh (Test D) cho khung UI và vật thể.
   - Tránh: chi tiết nhỏ trong vài ảnh vì chỉ đọc được ở cỡ lớn. Không bắt chước bố cục nhóm đồ trong ảnh.
3. **Cây/đá/prop theo biome:** `asset-library/design-library/renders/environment/` (savannah: `S_Tree01–03`, `SavannahRock_01/02`; mystic: `M_Tree_01`, `Rock_01`; genesis: `SM_Tree_G_01`; arctic, forest, luna landing). Contact sheet: `_sheets/renders_environment_*.jpg`.
   - Lấy: silhouette biome (tán dẹt, cây cong, cây thanh), mức chi tiết thấp, bảng màu từng biome.
   - Tránh: dùng cây nguyên bản làm vật nền ngay giữa combat (che Axie). Dùng ở rìa. Không trộn vật của biome khác trong một màn trừ chủ ý.
4. **Địa hình và đường:** `asset-library/design-library/renders/terrain/` (ví dụ `atia_grass/SM_Plot_Grass_*_Prefab.png`, và nhóm savannah/mystic/arctic/forest). Contact sheet: `_sheets/renders_terrain_*.jpg`.
   - Lấy: cách mặt đất đổi màu và tone theo biome, cách đường/lối đi vẽ rõ trên cỏ. Dùng cho nền run map và arena.
   - Tránh: ô vuông lặp lộ rõ khi lát nhiều. Che lặp bằng vật rìa và vignette.
5. **Công trình và mây Homeland:** `asset-library/design-library/renders/buildings/` và `renders/environment/atia_building/`, mây ở `art-2d/environment/luna_landing_cloud_ll_cloud_*.png`. Contact sheet: `_sheets/renders_buildings_*.jpg`, `art_2d_environment.jpg`.
   - Lấy: mái cong, cửa vòm, khối chồng như bánh (3.3); mây tròn xốp cho trời và nền menu mờ.
   - Tránh: công trình nông trại (kho, máy ép) làm nền chiến đấu vì kể chuyện sai chỗ. Chỉ lấy hình dáng.

Axie, quái Atia và Chimera: tham chiếu duy nhất là model 3D đang chạy trong game và Land (không có ảnh Axie trong `design-library`, đúng quy tắc của thư viện đó).

---

## Câu hỏi còn mở cho Liam (cho mục 5–9)

1. ~~Leader~~: Liam 28/10: không có vai riêng, đã bỏ khỏi 5.4.
2. ~~Luna~~: game-designer chọn (Liam 28/10 nhờ agent): Luna là biome CUỐI (màn cuối + boss cuối), đúng như code hiện tại (`arenas.json` journey, `CombatArena3D.biome_for`). Không đổi code. Có thể thêm bản boss riêng cho Luna sau.
3. ~~Cỡ quái Atia~~: Liam 28/10: mọi quái cỡ gần bằng nhau và gần bằng Axie, không quá to quá nhỏ. Đã sửa 3.2 và 5.4.
