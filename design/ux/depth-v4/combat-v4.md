# Combat UX cho dice depth v4 (BỘ, LIỀU, MẶT TẠM, Overcast)

Trạng thái: DRAFT chờ Liam duyệt (21/10/2026). Tác giả: ux-designer.
Nguồn luật: `design/gdd/dice-depth-v4.md` mục 3.0, 3.5-3.8, 9. API/event: `/Users/loc.tien.nguyen/my-game-wt/V4/production/v4-impl-brief.md` (Bước 1, 2).
Luật UI: `godot/CLAUDE.md`. Spec này KHÔNG chọn màu/hình (art-director), KHÔNG viết code (ui-programmer). Số hệ số, % Nứt, giá mana đều đọc từ engine/knob, UI không tự tính.

## 0. Nguyên tắc (để khỏi rối, để vui)

1. Một câu một cơ chế. Mọi chữ trên UI lấy từ bảng 3.0 của GDD, không viết lại.
2. Thấy trước khi bấm: bấm gì cũng có dòng "bây giờ -> sau khi bấm" (số, %, giá). Không có bất ngờ xấu ngoài ý muốn; bất ngờ duy nhất là ván xúc xắc.
3. Vui nằm ở khoảnh khắc ra Bộ, không nằm ở việc đọc bảng. Chữ nhỏ cho thông tin, chữ to + nhịp cho phần thưởng.
4. Thua một ván Liều không được "phạt" bằng âm thanh/chữ đỏ. Nứt là kết quả của lựa chọn, không phải lỗi.
5. Mọi màu mã hoá part/cơ chế đi kèm glyph (luật chung). Nhóm Bộ nhận ra được khi nhìn xám (grayscale).

## 1. BỘ

### 1.1 Chip part trên mỗi viên
- Góc trên-trái thẻ viên (thẻ trong tray ở `smoke_b1196_10`): chip 32x32 (design px) có glyph part (Miệng, Sừng, Lưng, Đuôi, Mắt, Tai theo `SLOT_ORDER`). Luôn hiện từ stage 1. Chip không bấm được; tooltip: tên part + "3 viên cùng part thì thành BỘ".
- Viên mặt `blank`/mana-cantrip (Tai) vẫn có chip, nhưng không bao giờ nằm trong nhóm.

### 1.2 Nhóm trong tray
Nguồn dữ liệu: `bo` (mảng `{part,size,uids,hi,m100}`) và `EventBus.bo_changed(groups)`. UI chỉ vẽ lại khi event bắn.

| Trạng thái | Vẽ | Nhãn |
|---|---|---|
| Đôi (2 viên cùng part) | nét đứt nối 2 viên, màu part + glyph | không chip chữ (coach C2 nói thay, tránh thêm chữ vào tray); tooltip "Đôi: cần thêm 1 viên cùng part" |
| Bộ ba / bốn / năm | khung liền bao các viên + thanh nối, màu part + glyph, bóng cứng (không blur) | nhãn 24px đặt trên khung: "BỘ BA ×1.4" (số lấy từ `m100/100`) |
| Viên không nhân được (mana, debuff) nhưng cùng part | nằm trong khung, có dấu gạch chéo nhỏ | tooltip "Không nhân" (edge 18) |
| Viên Nứt | RA KHỎI khung (xem 2.4) | |

- Chỗ đặt nhãn/banner (1280x720, xem `smoke_b1196_10`): thẻ viên nằm y~595-705, nhãn FRONT/BACK ở y~568. Nhãn "BỘ BA ×1.4" KHÔNG đè nhãn FRONT/BACK và KHÔNG che số viên: đặt trong dải phía trên thẻ, nhãn FRONT/BACK mờ đi khi có nhãn Bộ. Banner bốn/năm nằm trên dải đó (khoảng y~500-540), không bao giờ phủ lên thẻ.
- Hiện NGAY khi viên dừng lăn (sau `on_roll_settled`/DiceRoller3D settle), không đợi người chơi bấm. Đây là chỗ người mới "ồ".
- Hai nhóm khác part không được chồng viền: viên nào cũng chỉ thuộc một nhóm. Tray vẫn giữ thứ tự cũ; không tự xếp lại viên (mất mental model). Nếu hai viên cùng nhóm không kề nhau thì thanh nối đi dưới các viên giữa, không đổi thứ tự.
- Đôi chỉ vẽ ở stage 1-2 tới khi người chơi tự ra Bộ lần đầu; sau đó đôi giảm xuống chỉ nét đứt, không chip chữ (giảm ồn).

### 1.3 Preview trên viên
- Số trên viên: không Bộ "5"; có Bộ "5 -> 8" (cỡ số 28/20 theo luật; phần "-> 8" dùng 20). Hai số đều đến từ `preview_damage`/`_face_value`.
- Lúc hover/focus viên trong Bộ: tooltip một dòng "Bộ ba Sừng ×1.4: 5 -> 8".
- Hệ số tiến lên khi thêm Mặt Tạm/Overcast: số trên viên cập nhật tức thì (cùng nguồn), không chờ bấm.

### 1.4 Khoảnh khắc "trúng" (nhịp theo bậc)
Mục tiêu: hiếm thì to, thường thì nhẹ, để không mệt và để bốn/năm thật sự là "trúng gacha".

| Bậc | Nhịp (từ lúc viên cuối dừng) | Chữ | Gợi ý cho sound/VFX |
|---|---|---|---|
| Ba | 0.15s trễ, khung vẽ ra 0.2s, số "ticks" lên 0.25s. Tổng ~0.6s, không chặn bấm | nhãn nhóm 24px "BỘ BA ×1.4", KHÔNG banner | 1 tiếng "ting" tông thấp; viên trong Bộ nhảy 8px một lần; thêm một vòng sáng chạy dọc khung 0.3s và 3-4 đốm sáng nhỏ (lề khung, không phủ số). Nhẹ nhưng vẫn "được thưởng" |
| Bốn | như trên rồi banner | banner 36px giữa trên tray "BỐN SỪNG ×1.8!", giữ 0.8s | 2 nốt "ting-ting" tông lên; viên nhảy nối đuôi nhau (0.05s lệch); vài mảnh sáng bay khỏi khung |
| Năm | banner giữ 1.2s, viên nhảy lần lượt hết hàng, số tick lần lượt | "BỘ NĂM SỪNG ×2.6!!" 36px | 3 nốt tăng + hợp âm; VFX lớn nhất của combat, nhưng KHÔNG nhấp nháy toàn màn |
| Lên bậc sau tung lại (ba lên bốn) | như bậc mới, chỉ phần thêm: khung giãn ra, banner mới thay banner cũ | "BỐN SỪNG ×1.8!" | tiếng cao hơn lần trước một nấc |
| Tung lại làm mất Bộ | khung mờ dần 0.2s, im lặng | không chữ | không âm (không phạt) |

- Bốn/năm "đã" hơn mà không che số: số trên viên to lên 1 nhịp (scale 1.15 rồi về 1.0, không đổi cỡ chữ), khung đổi sang nét dày + glyph part sáng, bốn/năm giữ khung "sáng" tới hết lượt (ba thì không) để ván nhìn khác hẳn. Cấm hiệu ứng chồng lên vùng số.
- Banner không chặn bấm; nếu người chơi bấm viên trong lúc banner, banner thu nhanh 0.15s.
- Banner khác GDD 9.1: GDD ghi banner cho cả Bộ ba. Ở đây ba chỉ có nhãn, bốn/năm mới banner, vì Bộ ba ra thường xuyên (xem GDD 4.2) và banner mỗi lượt sẽ thành nhiễu. CẦN LIAM DUYỆT.
- Hiệu ứng tuân theo cài đặt flash/giảm chuyển động hiện có: tắt thì còn khung + chữ + số, bỏ particle/nhảy. Không nhấp nháy > 3 lần/giây.
- Dòng log chiến đấu: "BỘ BA SỪNG ×1.4: Beast 5 -> 8, Aqua 3 -> 5" (GDD 9.1), ghi một lần khi nhóm hình thành ở trạng thái cuối lượt tung, không ghi mỗi lần tung lại.
- Audio: sound-designer làm theo bảng trên; yêu cầu duy nhất của UX là tông tăng theo bậc và có biến thể "mất Bộ" = không âm.

## 2. Reroll, LIỀU, Nứt, khoá

### 2.1 Nút
Chỗ hiện nút: cột phải dưới (cạnh End turn trong `smoke_b1196_10`). End turn giữ là nút primary DUY NHẤT của combat. Hold, Undo, Reroll hạ thành secondary/icon.

| Trạng thái | Nút hiện | Ghi chú |
|---|---|---|
| Còn lần miễn phí | "TUNG LẠI · miễn phí 1/1" | y như bản hiện tại, một nút |
| Hết miễn phí, stage 1 | "TUNG THÊM · 2 MP" | không có chữ Liều/Nứt (chưa mở) |
| Hết miễn phí, stage >= 2 | "TUNG THÊM" mở thanh chọn (2.2) | |
| Hết lượt tung | nút xám + lý do (2.5) | |

Giá lần 2/3 do engine báo (`mana_cost_2`=2, `mana_cost_3`=3 qua `reroll_mana_cost`); UI đọc, không hardcode.

### 2.2 Thanh chọn Liều / An toàn (stage >= 2)
Luồng: (1) bấm "TUNG THÊM" -> vào chế độ chọn viên (như Hold hiện tại: viên tung lại được có dấu tick glyph, viên không tung được xám + lý do tooltip). (2) chọn n viên (bấm lại để bỏ). (3) hai nút hiện cạnh nhau ngay trên End turn:

```
[ LIỀU · miễn phí ]   [ AN TOÀN · 2 MP ]
 ít nhất 1 viên Nứt: 51%   không có rủi ro
```

- Hai nút ngang cấp (secondary, cùng cỡ). Chúng THAY CHỖ nút "TUNG LẠI" (không hiện cùng lúc) nên màn vẫn đúng luật: 1 primary + 2 secondary. Hold, Undo, Mặt Tạm, Overcast là tertiary: nút vuông >= 44x44 (1920 design px; ở 1280 vẫn bấm được), glyph + nhãn ngắn cỡ 18 bên dưới hoặc tooltip bắt buộc (Hold: "Giữ viên", Undo: "Hoàn tác" + phím tắt), có tên đọc được cho screen reader. Không icon trơn không chữ. CẦN LIAM DUYỆT.
- Dòng phụ dưới Liều = "ít nhất 1 viên Nứt: X%", X = `1-(1-crack_pct/100)^n` (n=1: 30%, 2: 51%, 3: 66%, 4: 76%, 5: 83% ở knob mặc định). Số sinh từ knob. Khi n=0: "chọn viên để xem %". Mỗi viên Nứt 30% cũng hiện ở tooltip nút: "Mỗi viên tung lại có 30% Nứt (còn nửa số, không vào Bộ)".
- Glyph: Liều = xúc xắc + vết nứt; An toàn = giọt mana + số giá. Màu chỉ đi cùng glyph; không dùng đỏ cho Liều (đỏ là danger; Nứt là đánh đổi, dùng amber cảnh báo + glyph vết nứt).
- Focus ban đầu: An toàn nếu đủ mana, ngược lại Liều (tránh Enter vô tình tiêu mana; Liều vô tình không mất mana nhưng người chơi thấy % trước nên vẫn ổn). Esc thoát chế độ chọn trước, rồi mới mở menu in-run.
- Sau khi bấm: tung ngay, không hộp xác nhận (có % hiện sẵn; reroll xoá undo, nên dòng phụ chính là xác nhận). Nếu n=5 và Liều: dòng phụ đổi "83% có Nứt" cùng cỡ chữ, không thêm cảnh báo.
- Không có nút "đổi sang An toàn" sau khi đã tung (khoá, 2.5).

### 2.3 Chọn viên để tung lại
- Vào chế độ chọn thì TỰ CHỌN SẴN mọi viên không nằm trong khung Bộ và không Hold (cách phổ biến nhất). Người chơi chỉ bấm bỏ/thêm. Giữ viên trong Bộ là mặc định đúng. Không thêm nút "Chọn viên ngoài Bộ" (bớt 1 nút, bớt 1 bước). Nếu tự chọn ra 0 viên thì dòng phụ "Chọn viên để tung lại".
- Viên không tung lại được (đã dùng, Mặt Tạm, Overcast) xám, tooltip lý do: "Đã dùng", "Có Mặt Tạm, không tung lại", "Có Overcast, không tung lại".

### 2.4 Viên Nứt trông thế nào
- Vết nứt vẽ lên thẻ (hình, không chỉ màu) + chip "½" cỡ 18 góc phải. Không nhầm với Giáp/Frozen: Giáp là chip trên đầu QUÁI (không nằm trên thẻ viên); Frozen/khoá có glyph + tông riêng phủ cả thẻ. Nứt chỉ có đường nứt + chip ½, KHÔNG phủ màu, KHÔNG làm thẻ xám (xám = không dùng được). Art-director chốt hình; yêu cầu: grayscale vẫn phân biệt được Nứt / Frozen / xám-không-dùng-được; số đã nhỏ lại (đọc từ `_face_base`) với phần "-> số" vẫn đúng.
- Rời khỏi khung Bộ ngay khi Nứt, khung co lại (nếu còn ≥ 3 viên thì nhóm nhỏ hơn, nhãn đổi bậc; nếu < 3 thì thành đôi/mất).
- Âm: tiếng "rắc" ngắn, không chói; viên rung 4px một lần. Không banner, không chữ đỏ.
- Tooltip: "Nứt: còn nửa số, không vào Bộ. Hết ở lượt sau."
- Overcast vẫn được lên viên Nứt (GDD 3.7); Mặt Tạm thì không (viên Nứt không hợp lệ).

### 2.5 Khoá (pin) và lý do khi xám
Pin (`reroll_lock[k]`): sau lần tung k, nếu undo (relic `safeReroll`) rồi tung lại thì BẮT BUỘC cùng `rmode` + cùng viên. UI: tự chọn sẵn đúng các viên đó, nút kia xám, dòng nhỏ "Đã chốt cho lần này: LIỀU · 2 viên".

Khi nút xám phải nói lý do ngay trên nút (dòng phụ) hoặc tooltip nếu quá hẹp. Ánh xạ từ `reroll_refusal(...)`:

| Mã | Chữ hiện | Ghi chú |
|---|---|---|
| `over` | "Hết lượt tung lại" | 1 lần gốc + 2 lần lựa chọn dùng hết |
| `hard_cap` | "Đã đủ 4 lần tung lượt này" | chỉ gặp khi có relic tặng |
| `stage` | (không hiện nút) | stage thấp: Liều ẩn, không phải xám |
| `mission` | "Nhiệm vụ không cho tung lại" | |
| `none` | "Chọn viên để tung lại" | chưa chọn viên |
| `pin_mismatch` | "Lần này đã chốt Liều/An toàn và các viên đã chọn" | kèm nút "Chọn lại đúng viên" |
| `mana` | "Cần 2 mana (đang có 1)" | giá đọc từ engine |
| `veto` | "Bị chặn bởi hiệu ứng" + tên relic/boss nếu có trong data | |
| `bad_rmode` | không hiện cho người chơi | log lỗi nội bộ, UI không nên gửi |

Phải kiểm `can_reroll` trước khi bật nút; không tự đoán lý do.

## 3. MẶT TẠM

Hiện chỉ từ stage >= 2 (GDD 3.8). Nút Mặt Tạm là tertiary 44x44, glyph "?" + nhãn 18 "Mặt Tạm" và giá "2" (giá/lượt "1/1" vào tooltip, không chen vào nút).

1. Bấm nút: các viên hợp lệ sáng viền cream 4px; viên không hợp lệ xám + lý do tooltip ("Đã dùng", "Đang Nứt", "Mặt tự dùng", "Có Mặt Tạm rồi"). Dòng gợi ý 18px: "Chọn viên để đổi part".
2. Bấm một viên: bên dưới tray hiện picker 6 chip theo THỨ TỰ CỐ ĐỊNH `SLOT_ORDER` (Miệng, Sừng, Lưng, Đuôi, Mắt, Tai), mỗi chip ≥ 56x56 gồm glyph part + dòng kết quả cỡ 18 (16 chỉ dành cho key hint): "-> BỘ BA ×1.4", "-> BỘ NĂM ×2.6" hoặc "không đổi". Không xếp lại theo giá trị (giữ vị trí cố định = bấm quen tay).
3. Chip cho kết quả tốt nhất có sao glyph "tốt nhất"; nếu chọn xong không đổi gì thì chip xám nhẹ nhưng vẫn bấm được (người chơi có thể có lý do).
4. Bấm chip = xác nhận, không hộp thứ hai (có undo hoàn mana). Giá hiện trên nút, không hiện trong picker để tránh nhắc lần hai.
5. Sau khi gắn: viên có huy hiệu "?" + glyph part đã chọn; khung Bộ vẽ lại theo `bo_changed`; chạy nhịp ở 1.4 (gắn Mặt Tạm làm ra Bộ lớn hơn = banner như thường).
6. Esc/chạm ngoài: đóng picker, về bước 1. Nút xám khi: mana < 2 ("Cần 2 mana"), đã dùng ("Đã dùng lượt này"), không có viên hợp lệ ("Không có viên hợp lệ").
- Preview ở chip phải đến từ engine. Brief hiện chưa có hàm thuần cho việc này: cần một hàm kiểu `preview_wild(uid, slot)` trả `{size,m100}` không đổi state. Đã gạch vào mục Phụ thuộc.

## 4. Overcast

Chỉ từ stage 3. Giữ nút hiện có "OVERCAST · 3 MP · 1/1" và luồng chọn viên như cũ.
- Đổi preview: hiện "5 -> 8" tính bằng `overcast_preview` (đã đi qua `_face_value`, cộng +0.5 vào túi M, không nhân chồng). Bỏ `overcast_mult()` ở tooltip `CombatView:1249` (đã ghi trong brief).
- Tooltip một dòng cho phép người chơi hiểu: "+0.5 vào hệ số, cộng với Bộ, không nhân thêm." Ví dụ hiện thật: "Hệ số viên này ×1.4 -> ×1.9" (số từ engine).
- Mặt mana/cantrip: nút xám "Không áp lên mặt mana".
- Xám khác: "Cần 3 mana", "Đã dùng lượt này".
- Viên Overcast có huy hiệu "+" kèm glyph sao; không tung lại/Hold (tooltip nói thế).

## 5. Không rối HUD

### 5.1 Thứ tự ưu tiên (từ lớn tới nhỏ)
1. Giá trị viên + khung Bộ (to nhất, luôn thấy).
2. End turn (primary).
3. Tung lại / tung thêm (secondary).
4. Mana đang có (chỗ hiện hiện tại, giữ nguyên).
5. Mặt Tạm, Overcast, Hold, Undo (tertiary).
6. Preview ("->") chỉ khi chọn/hover/focus.
7. Dòng log, chip "ĐÔI".

Nguyên tắc: không quá 3 nút hành động nhìn thấy cùng lúc ngoài End turn ở stage 1-2 (Tung lại, Hold, Undo); stage 3 thêm 2.

### 5.1b Giảm tải khi đủ đồ (stage 3, 1280x720)
Cột phải dưới chỉ chứa: End turn, Tung lại (hoặc Liều/An toàn), một hàng tertiary nhỏ [Hold][Undo][Mặt Tạm][Overcast]. Tối đa 4 ô, cùng cỡ, xếp ngang, không xuống hàng thứ hai.
- Thông tin "chỉ khi cần": preview "->", tooltip, dòng phụ % chỉ hiện khi chọn/hover. Lúc rảnh tay tray chỉ còn số + chip part + khung Bộ.
- Đang ở chế độ chọn (tung / Mặt Tạm / Overcast): làm mờ chip Giáp/affix/nhịp boss ở cột trái-phải và ẩn coach/log; chỉ còn tray + thanh chọn. Hết chế độ thì hiện lại.
- Hộp giải thích affix góc trái (như "Plating cuts every single hit" trong `smoke_b1196_10`) chỉ mở ở trận đầu gặp affix đó hoặc khi hover/bấm hàng relic; không treo thường trực.
- Một lúc chỉ có MỘT thứ chiếm giữa trên tray: banner Bộ, hoặc bong bóng coach, hoặc picker. Ưu tiên banner > picker > coach.

### 5.2 Ẩn theo stage
| Thứ | Stage 1 | Stage 2 | Stage 3 |
|---|---|---|---|
| Chip part, khung Bộ, nhãn Bộ | hiện | hiện | hiện |
| Nét đứt Đôi | hiện | hiện (tới Bộ đầu) | không |
| "TUNG THÊM · 2 MP" (An toàn) | hiện | hiện | hiện |
| Liều, Nứt, chip "½" | ẩn | hiện | hiện |
| Mặt Tạm | ẩn | hiện | hiện |
| Overcast | ẩn | ẩn | hiện |
| Part cao bậc (+0.25), Lõi chủ | ẩn | ẩn | hiện |

Ẩn là KHÔNG vẽ nút/chip và không có tooltip, không chừa chỗ trống (nút còn lại dãn đều, không nhảy khi mở stage). Màn kết run báo "Mới mở: ... Có từ run sau" (mục 6).

### 5.3 Coach (theo sự kiện, 1 câu, 1 lần cho cả tài khoản)
Luật chung từ GDD 9.4: không modal, có "Bỏ qua", tối đa 1 bong bóng, không bật trên đầu banner (chờ banner tắt), chỉ chạy sau khi viên đã dừng lăn, tự tắt khi người chơi làm đúng việc được trỏ vào.

| Bước | Khi nào | Câu (UI đã rút gọn) | Trỏ vào |
|---|---|---|---|
| C1 | lần tung đầu trận đầu | "Mỗi viên có một part. 3 viên cùng part thì thành BỘ, mạnh hơn." | hàng chip part |
| C2 | lần đầu có đôi | "Có 2 Sừng rồi. Tung lại mấy viên còn lại để kiếm viên thứ 3." | đôi + nút Tung lại |
| C3 | lần đầu ra Bộ | "Số trên mỗi viên trong Bộ đã nhân." | số "5 -> 8" |
| C4 | lần đầu hết lần miễn phí còn mana | "Tung thêm tốn 2 mana." | nút Tung thêm |
| C5 (stage 2) | lần đầu hết lần miễn phí | "Liều: miễn phí, nhưng mỗi viên 30% bị Nứt." | nút Liều |
| C6 (stage 2) | lần đầu có đôi và >= 2 mana | "Mặt Tạm: 2 mana, một viên tính là part bạn chọn." | nút Mặt Tạm |
| C7 (stage 3) | lần đầu >= 3 mana | "Overcast: 3 mana, +0.5 vào hệ số." | nút Overcast |

Một bong bóng mỗi lượt (C5-C7 xếp hàng, lượt sau mới tới cái kế). Cờ đã xem lưu qua `SaveStore`/META (không ghi thẳng file).

## 6. Màn Result (`ResultView.gd`, thẻ Cores ~dòng 480-517)

### 6.1 Pact không còn "never fired"
Hiện `CoreImpact` rơi về `tr("never fired")` khi `impact` rỗng, nên relic thụ động (Pact) trông như hỏng.
- Ngôn ngữ: UI hiện đang tiếng Anh (xem ảnh HUD), mọi chuỗi trong spec này phải qua `tr()` với cả bản EN lẫn VI; chốt với Liam ngôn ngữ mặc định.
- Pact (không có hook `core_fired`) vẽ cùng dòng, nhưng thay chữ phải bằng nhãn "Pact · passive" (VI: "Pact · bị động"; không trộn Anh-Việt trong một nhãn) kèm một dòng mô tả ngắn từ `UI3.player_text()` (không ghép chuỗi thô, luật godot/CLAUDE.md). Muted như bây giờ.
- Pact không được tính vào "Most impact" (`CoreFeedback.top_core` bỏ Pact). Chỉ Core thật mới có thể là top.
- Nếu phải tách: dưới tiêu đề nhỏ 18px "Pact (thụ động)" nằm phía dưới các Core, cùng nền panel, không thêm nút. Phương án này chỉ cần khi có ≥ 1 Pact; run không có Pact thì không vẽ tiêu đề. Ưu tiên phương án nhãn trên dòng (ít chi tiết hơn); tách mục khi có ≥ 3 Pact.
- Core thật mà chưa bắn: giữ "Never fired", chữ rõ nghĩa hơn: "Chưa kích hoạt run này".
- ui-programmer phải xác định cách nhận biết Pact trong data (`RelicRegistry` def) trước khi làm; chỗ này tôi chưa kiểm.

### 6.2 Dòng "Bộ tốt nhất"
Thêm một dòng trong khung thống kê run (cạnh các dòng "biggest hit" hiện có): "Bộ tốt nhất: Bộ năm Sừng ×2.6" + glyph part. Đây là chỗ khoe: cỡ 24, màu accent cùng kiểu dòng nổi bật hiện có, không phải nút. Bộ bốn/năm thì thêm một lần nảy nhẹ khi dòng hiện (không banner); ba trở xuống không hiệu ứng. Đỏ không dùng ở dòng này.
- Tiêu chí chọn: bậc cao nhất, sau đó `m100` cao nhất, sau đó ra sớm nhất. Tính lúc chốt (không tính Bộ bị mất vì tung lại).
- Chưa có Bộ nào (run ngắn): "Chưa ra Bộ. Lần sau thử giữ 3 viên cùng part." (động viên, không trách).
- Nguồn: cần thêm field `best_bo {part,size,m100}` vào accumulator của `RunState` (cùng chỗ với biggest hit; test `t_run_stats_accumulator`). Đụng `scripts/meta` nên phải bump `RULES_VERSION` + deploy Worker (cảnh báo godot/CLAUDE.md). Nếu Liam không muốn đụng rules version thì dòng này đợi bump chung của v4.
- Thẻ "Mới mở: Liều, Mặt Tạm. Có từ run sau" theo GDD 3.8 nằm dưới thống kê, vẫn một nút primary duy nhất của Result.

## 7. Checklist cho ui-programmer và test UI

Chụp mọi trạng thái ở 1920x1080 và 1280x720 (`godot/tools/shot.sh`).

BỘ
- [ ] Mỗi viên có chip part 32px, glyph đúng `SLOT_ORDER`, xem được ở 1280x720.
- [ ] Khung Bộ vẽ lại chỉ khi `bo_changed` bắn; không tự tính nhóm trong UI.
- [ ] Nhóm 3/4/5: nhãn "BỘ BA/BỐN/NĂM x" đúng với `m100`; đôi chỉ nét đứt + chip nhỏ.
- [ ] Banner chỉ cho bốn/năm; ba chỉ nhãn (nếu Liam duyệt); không chặn input.
- [ ] Số "5 -> 8" khớp `preview_damage`; test so sánh với engine.
- [ ] Thứ tự viên trong tray không đổi khi nhóm hình thành.
- [ ] Nhóm nhận biết được khi chuyển grayscale (glyph + nhãn).
- [ ] Tắt flash/giảm chuyển động: còn khung + chữ + số, hết particle/nhảy.

Reroll
- [ ] Stage 1: không có chữ Liều/Nứt ở bất kỳ đâu (nút, tooltip, log).
- [ ] Stage >= 2: thanh hai nút Liều/An toàn, % "ít nhất 1 viên Nứt" đúng công thức cho n = 0..5, cập nhật khi chọn/bỏ chọn viên.
- [ ] Nút An toàn xám khi mana không đủ, có chữ "Cần N mana (đang có M)".
- [ ] Mỗi mã `reroll_refusal` có chữ trong bảng 2.5; test: mọi mã gọi ra một chuỗi không rỗng, không có "undefined"/"NaN".
- [ ] Pin: sau khoá, viên tự chọn lại đúng, nút kia xám đúng lý do.
- [ ] Viên Nứt: vết nứt (hình) + chip "½" + rời khung + tooltip.
- [ ] Reroll không có hộp xác nhận; không có nút đổi sang An toàn sau khi tung.
- [ ] Esc đóng chế độ chọn trước khi mở menu in-run (cập nhật `t_key_bindings` nếu thêm phím).

Mặt Tạm / Overcast
- [ ] Picker 6 chip theo thứ tự cố định, chip ≥ 56px, mỗi chip có "-> BỘ ..." hoặc "không đổi" lấy từ engine (cần `preview_wild`).
- [ ] Nút xám có lý do cho mana/đã dùng/không có viên hợp lệ.
- [ ] Huy hiệu "?" (Mặt Tạm) và "+" (Overcast) kèm glyph, khoá icon tung lại/Hold.
- [ ] Overcast preview đúng +0.5 (hệ số ×1.4 -> ×1.9), `overcast_mult()` shim đã bỏ khỏi tooltip.

Chung
- [ ] Combat chỉ có đúng 1 nút primary (End turn); secondary ≤ 2 cùng lúc (Liều/An toàn), phần còn lại tertiary icon.
- [ ] Chữ chỉ dùng cỡ 16/18/24/32/36 (+28/20 số xúc xắc); vùng bấm ≥ 44px; token, không hex.
- [ ] Dùng bàn phím hoàn toàn: Tab qua viên, Enter chọn, mũi tên trong picker, Esc thoát; focus ring amber.
- [ ] Gamepad: nếu có hỗ trợ thì cùng thứ tự focus; hiện chưa hỗ trợ (technical-preferences).
- [ ] Coach C1-C7: mỗi cái một lần, không đè banner, có Bỏ qua, cờ lưu qua `SaveStore`.
- [ ] Result: Pact có nhãn "Pact · passive", không vào Most impact; dòng "Bộ tốt nhất" hiện/ẩn đúng trường hợp không có Bộ.
- [ ] Thêm test UI mới (t_combat_v4_ui hoặc tương đương) và đổi số sàn ở `technical-preferences.md` cùng commit.

## 8. Phụ thuộc / việc ngoài UI
- Hàm `preview_wild(uid, slot)` (engine, pure) cho picker Mặt Tạm.
- `best_bo` trong `RunState` (bump RULES_VERSION).
- Cách nhận biết Pact trong data relic.
- Sound-designer: bộ cue ba/bốn/năm, Nứt, mất Bộ (im lặng), Mặt Tạm, Overcast.
- Số Bộ trong UI phải đồng bộ khi chỉnh knob `bo.scale`; không viết cứng "×1.4".
