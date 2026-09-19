# Visual Polish Backlog — Godot Port Core Screens (2026-09-19)

**Bối cảnh**: user vừa chơi thử bản Godot port và nói thẳng UI/UX "cực kì xấu và mất thẩm mĩ".
Đây là audit thị giác thuần tuý (không sửa code) trên 3 nhóm màn cốt lõi — Combat, RunMap,
Main Menu/Lunacia Pass — dựa trên 7 ảnh chụp thật hôm nay cộng đối chiếu với
`godot/scenes/shared/DangoTheme.gd`, `design/ux/combat-screen-shroom-gloom-inspired.md`, và đọc
trực tiếp `RunMapController.gd`/`CombatStage3D.gd`/`MainMenu.gd`/`CombatView.gd` để trích dẫn
nguyên nhân chính xác thay vì đoán. Không file code nào bị sửa trong quá trình audit này.

**Ảnh dùng để audit**:
- Combat: `production/qa/evidence/2026-09-18_real-flow-check.png`,
  `2026-09-18_real-flow-varied-enemies.png`, `2026-09-18_combat-die-tray-and-lines.png`
- RunMap: `production/qa/evidence/2026-09-19_reward-loop_01_map_start.png`,
  `2026-09-18_runmap-graph-after-advance.png`
- Main Menu: `production/qa/evidence/2026-09-19_menu-result_01_mainmenu_default.png`,
  `2026-09-19_menu-result_03_mainmenu_team_and_button.png`

**Thang đo effort**: S = sửa trong 1 hàm/1 chuỗi, dưới 1 ngày · M = vài ngày, chạm nhiều điểm hoặc
cần nội dung/asset đã có sẵn · L = nhiều ngày/1 tuần, cần asset mới hoặc thiết kế lại.

**Xếp hạng**: theo mức "cải thiện cảm nhận / công sức" trong từng nhóm P0 > P1 > P2 — mục rẻ mà
nâng nhiều được xếp lên đầu mỗi nhóm.

---

## Tổng quan nhanh theo màn hình

| Màn | Đánh giá 1 dòng |
|---|---|
| Combat (nơi chơi 90% thời gian) | Xương sống tốt (die-tray, intent bubble, color coding đã đúng thiết kế) nhưng bị lộ rõ 1 gap nội dung (quái không có art → capsule trơn) và thiếu neo thị giác (không bóng đổ) |
| RunMap | Màn tệ nhất trong 3 nhóm — camera cắt cụt node, đồ thị dồn vào 1 góc, lộ ID kỹ thuật ra UI |
| Main Menu / Lunacia Pass | Không có sự cố "hỏng" nào nhưng gần như zero art direction — đọc như 1 form cấu hình/spreadsheet, không giống cửa ngõ của 1 game |

---

## P0 — Trông hỏng

### 1. RunMap — node bị camera cắt cụt, toàn bộ đồ thị dồn vào một góc màn hình
**Vấn đề**: `_update_camera()` (`godot/scenes/run_map/RunMapController.gd:457-497`) chỉ đưa
`current_node_id` + các node đang "reachable now" vào tập điểm để tính khung hình (`pts`) — các
hàng node mờ ("?" , 2+ hàng phía trước, vẫn được vẽ theo đúng spec) KHÔNG nằm trong `box_size`.
Khi đồ thị dài ra theo run, các hàng xa bị đẩy ra ngoài khung camera đã fit. Ảnh
`runmap-graph-after-advance.png` cho thấy đúng hệ quả: 1 node "?" bị cắt cụt ngay mép trên màn
hình, đè lên cả thanh "Power level: 1 — visited: 1". Cả 2 ảnh RunMap còn cho thấy toàn bộ đồ thị
chỉ chiếm dải hẹp x≈875-1210px (trên tổng 1920px ngang) — 85% màn hình là nền art bỏ trống,
không giống một "bản đồ nhánh" chút nào.

**Sửa**: đưa TẤT CẢ node đã render (kể cả node mờ 2+ hàng) vào `pts` trong `_update_camera()`,
không chỉ current+reachable — giữ nguyên logic zoom-to-fit đã có (`_CAMERA_MARGIN := Vector2(240,
280)`, `_CAMERA_ZOOM_MIN/MAX := 0.6/1.9`), chỉ đổi tập điểm đầu vào. Có thể cần nới `_CAMERA_ZOOM_MAX`
một chút nếu đồ thị nhiều hàng khiến zoom-out vượt trần hiện tại. Verify lại bằng đúng 2 ảnh QA
này (node top-row không còn bị cắt, đồ thị lấp được phần lớn bề ngang màn hình).

**Effort**: S

### 2. RunMap — nhãn node in thẳng ID kỹ thuật ra màn hình người chơi
**Vấn đề**: `RunMapController.gd:347` — `btn.text = "%s\n%s" % [node.node_type.capitalize(),
node.id]` in `node.id` (vd `"r1_c0"`, `"r2_c1"`) làm dòng phụ đề dưới icon. Thấy rõ trong cả 2
ảnh: "Battle r1_c0", "Event r2_c0" — đọc như debug label bị lọt ra, không phải copy cho người chơi.

**Sửa**: bỏ `node.id` khỏi text hiển thị. Icon + `node_type.capitalize()` (vd "Battle") là đủ —
map đã nhỏ, thêm 1 dòng ID kỹ thuật chỉ gây rối, không mang thông tin gì cho người chơi.

**Effort**: S

### 3. Main Menu (Lunacia Pass) — ghi chú nội bộ dev hiển thị y nguyên cho người chơi
**Vấn đề**: `MainMenu.gd:536` — chuỗi cứng kết thúc bằng `"(needs the mutation pool, not in this
build)"` hiện nguyên văn trong ảnh `menu-result_03_mainmenu_team_and_button.png`: *"Lv 5 — Gene:
bp_plague (needs the mutation pool, not in this build)"*. Đây là ghi chú lập trình viên, không
phải copy sản phẩm — và đứng cạnh 5 dòng CLAIM khác trông hoàn toàn bình thường nên rất dễ bị
người chơi đọc thấy và thắc mắc.

**Sửa**: (a) ẩn hẳn dòng này khỏi danh sách phần thưởng cho tới khi hệ thống mutation pool tồn
tại, hoặc (b) đổi copy sang ngôn ngữ hướng người chơi kiểu "Sắp ra mắt" — không bao giờ để lộ
chuỗi tiếng Anh kỹ thuật "not in this build" ra UI thật.

**Effort**: S

### 4. Combat — quái chưa có mapping Chimera hiện thành một viên nang (capsule) trơn, không thân không mặt
**Vấn đề**: `CombatStage3D._make_placeholder()` (dòng 461-471) dùng `CapsuleMesh` (radius 0.4,
height 1.4) tô màu phẳng `_ENEMY_PLACEHOLDER_COLOR := Color(0.55, 0.2, 0.2)` khi quái không có
`_CLASS_PART_CLASS` — đúng trường hợp quái ContentDB cơ bản như "Gooey Slime" (`cls==""`, xem
`_build_parts()` dòng 478-482). Trong ảnh `real-flow-check.png`/`combat-die-tray-and-lines.png`,
cả 2 "Gooey Slime" chỉ là 2 khối tròn xám-nâu lơ lửng phía trên bảng tên, không thân, không mặt,
không có điểm chung nào với hình dạng "slime" — nhìn như model bị lỗi load, ngay trên màn hình
người chơi nhìn nhiều nhất.

**Sửa**: đây là gap nội dung (thiếu art Chimera cho quái cơ bản) hơn là bug hiển thị, nhưng vì
đây là fallback MẶC ĐỊNH cho MỌI quái chưa map, nó sẽ tiếp tục lộ ra ở bất kỳ quái mới nào bị
thiếu dữ liệu. Đề xuất 2 lớp: (a) ưu tiên hoàn thiện mapping Chimera cho slime/quái cơ bản —
`docs/art/chimera-monster-art-mapping-2026-09-08.md` đã có đề xuất DRAFT, việc còn thiếu là chốt
& implement chứ không phải tìm asset mới; (b) làm bản thân placeholder bớt "trông hỏng" hơn (việc
cho `technical-artist`, không phải hôm nay) — thay `CapsuleMesh` phẳng bằng 1 hình blob quen mắt
hơn + gradient/noise nhẹ thay vì màu phẳng tuyệt đối, để placeholder vẫn đọc được là "một sinh
vật" chứ không phải "một khối lỗi".

**Effort**: M (phần content-mapping đã có kế hoạch sẵn; phần placeholder-mesh là code nhỏ nhưng
thuộc `technical-artist`/`gameplay-programmer`)

### 5. Main Menu & Lunacia Pass — gần như zero art direction, đọc như form cấu hình
**Vấn đề**: cả 2 ảnh main menu là nền đen phẳng tuyệt đối (`DangoTheme.BG`, `#13161B`) — không
ảnh nền, không logo art, không icon nào cho SEED/MODE/ASCENSION/UNLOCKS, toàn bộ chỉ là Label +
Button trần trên nền trơn. Đây là màn hình ĐẦU TIÊN mọi người chơi thấy — nơi ảnh hưởng "cảm nhận
xấu" nhiều nhất trên mỗi giây xem.

**Sửa (rẻ, không cần asset mới)**: bọc từng section (SEED / MODE / ASCENSION / CHOOSE YOUR TEAM /
UNLOCKS) trong `PanelContainer` dùng `DangoTheme.panel_style(DangoTheme.BG_PANEL, 2, 8, 16.0)` —
game ĐÃ dùng đúng pattern này cho hero-slot card (`MainMenu.gd:344-345`, `BG_PANEL_SOFT`), chỉ
cần áp dụng lên các section còn lại thay vì để Label trần trên nền đen. Việc này tạo phân vùng
thị giác ngay lập tức, không cần vẽ thêm bất kỳ art nào. Thêm ảnh nền Lunacia thật (game đã có sẵn
art loại này, dùng ở RunMap) như 1 lớp `TextureRect` mờ phía sau `_content_root` là việc lớn hơn
(L) — nên tách riêng, không chặn phần panel hoá (S) ở trên.

**Effort**: S cho phần panel hoá · L riêng nếu muốn thêm background art thật

---

## P1 — Trông nghiệp dư

### 1. Combat — nhân vật không có bóng đổ chân đế, trông lơ lửng trên nền art rất đẹp
**Vấn đề**: cả 5 Axie phe ta lẫn quái đứng trên cát nhưng không có vùng tối/bóng dưới chân —
không có điểm neo thị giác nào giữa model 3D và nền painted-art desert, khiến các khối tròn nhiều
màu trông như dán đè lên ảnh nền hơn là đứng trong khung cảnh (đặc biệt rõ với Puffy/Pomodoro,
2 unit có kích thước lớn hơn hẳn phần còn lại mà không có gì báo hiệu chúng đang đứng ở cùng mặt
đất).

**Sửa**: thêm 1 bóng đổ mềm (radial gradient đen, alpha ~0.35, bán kính ~0.6x bề rộng model) tại
chân mỗi unit slot trong `CombatStage3D` — tái dùng đúng kỹ thuật `GradientTexture2D` mà
`_build_gradient_textures()`/vignette đã dùng, đúng pattern đã được duyệt trong
`design/ux/combat-screen-shroom-gloom-inspired.md` §8 (Data Requirements) là cách làm chuẩn của
file này. Không cần asset PNG mới.

**Effort**: S

### 2. Cả 3 màn — chữ nhãn phụ quá nhỏ / tương phản thấp, lặp lại nhiều nơi
**Vấn đề cụ thể**: (a) keyword chip trong die-tray/team card ("heavy", "cantrip", "growth",
"thorns:2") ước chừng ~9-10px, xám nhạt trên nền gần đen; (b) số HP đè lên chính thanh HP fill
màu xanh lá (ảnh `real-flow-check.png`) — chữ trắng trên nền xanh lá vừa/sáng, khó đọc; (c) nhãn
node RunMap cùng cỡ nhỏ tương tự. Đây là 1 pattern lặp lại có hệ thống, không phải lỗi riêng lẻ.

**Sửa**: đặt 1 cỡ chữ sàn 12px cho MỌI text hướng người chơi (không tính debug). Dùng `TEXT_DIM`
(alpha 0.55) chỉ cho text phụ có icon đi kèm hỗ trợ (không bắt buộc đọc ngay); dùng `TEXT` (alpha
0.93+) cho số liệu bắt buộc đọc được (HP, tên). Với số HP đè lên bar: rẻ nhất là dời số ra khỏi
vùng fill màu, đặt cạnh nameplate (chính `real-flow-varied-enemies.png` đã làm đúng cách này:
"Olek 17/17" tách khỏi bar) — rẻ hơn nhiều so với thêm outline/shadow cho từng con số.

**Effort**: S–M (rà nhiều điểm nhưng mỗi điểm sửa nhanh)

### 3. Main Menu — không có max-content-width, mỗi hàng co giãn theo luật khác nhau
**Vấn đề**: ô nhập SEED kéo full-width toàn màn hình cho 1 con số ngắn (`_seed_edit` set
`size_flags_horizontal = Control.SIZE_EXPAND_FILL` không có trần, `MainMenu.gd:171-172`); 2 nút
MODE cũng full-width; nhưng stepper ASCENSION (`-`/`A0`/`+`, các nút 44-72px) lại nhỏ, trôi dạt
bên trái với khoảng trắng lớn bên phải. 3 kiểu co giãn khác nhau trên cùng 1 cột dọc
`_content_root` — không có lưới chung, đọc như trang chưa style xong.

**Sửa**: đặt trần hợp lý cho seed field (`custom_minimum_size.x` ~360px thay vì expand-fill vô
hạn) và bọc `_content_root` trong 1 container giới hạn max-width (~1000-1100px trên màn hình
1920px, căn giữa hoặc lề trái cố định) để mọi section — kể cả stepper — dùng chung 1 chiều rộng
canh lề.

**Effort**: S

### 4. RunMap — đường nối (edge) quá mảnh/mờ, chưa đúng thiết kế "đường mòn hang động" đã duyệt
**Vấn đề**: `design/ux/combat-screen-shroom-gloom-inspired.md` §5.4 rule 2 đã chốt: edge phải là
bezier có "wobble" ngẫu nhiên (seed theo `hash(from.id, to.id)`) để trông như đường mòn hang động,
không phải đường thẳng ruler. Trong cả 2 ảnh QA, đường nối hiện tại vẫn là đường thẳng mảnh, tương
phản rất thấp khi cắt ngang nền mây trắng/trời sáng phía sau — gần như biến mất ở 1 số đoạn.

**Sửa**: đây KHÔNG phải thiết kế mới cần bàn — implement đúng phần đã duyệt trong spec, tái dùng
thuật toán bezier có sẵn ở `TargetLinesLayer._draw()`/`_BOW_HEIGHT` (đã ghi rõ trong Data
Requirements §8 của spec chính là chỗ để tái dùng). Nên ưu tiên việc này trước khi đầu tư thêm bất
kỳ polish RunMap nào khác vì đã thiết kế xong, chỉ chưa lên code.

**Effort**: M (đã có thuật toán mẫu để tái dùng, không phải thiết kế từ đầu)

### 5. Main Menu (Lunacia Pass) — thanh cuộn mặc định của Godot, không theo theme
**Vấn đề**: ảnh `menu-result_03_mainmenu_team_and_button.png` — scrollbar dọc bên phải là style
mặc định OS/engine (thanh xám nhạt mảnh, không bo góc) — chi tiết DUY NHẤT không theo bảng màu
Dango trong toàn bộ khung hình tối màu.

**Sửa**: style `ScrollBar` (theme override `grabber`/`grabber_highlight`/`scroll`) dùng
`DangoTheme.BG_PANEL_SOFT` cho track và `PRIMARY` alpha ~0.5 cho grabber, bo góc 4px — set 1 lần
ở theme cấp Project (hoặc ở root của các scene có `ScrollContainer`), áp dụng toàn cục thay vì
từng nơi.

**Effort**: S

### 6. Main Menu — trạng thái khoá (FULL mode) chỉ báo bằng caption chữ nhỏ
**Vấn đề**: nút "FULL — 20 waves" bị khoá chỉ khác nút "SHORT" ở màu nền/border nhạt hơn + 1 dòng
caption xám nhỏ bên dưới ("FULL mode is locked...") — phải đọc chữ mới biết bị khoá, không có tín
hiệu tức thời (đặc biệt yếu trên 1 màn hình mà mọi nút khác đều sáng orange).

**Sửa**: thêm icon ổ khoá nhỏ (dùng đúng bộ icon web đã duyệt tại `godot/assets/icons/web/`,
không phải Origins Kit) đặt cạnh label ngay trong nút bị khoá — tín hiệu tức thời theo Gestalt,
không cần đọc caption mới hiểu trạng thái.

**Effort**: S

---

## P2 — Đánh bóng

### 1. Team-select card — tên hero lặp lại 2 lần liền kề
Header dropdown đã ghi "Olek (Plant)", ngay bên dưới lại có tiêu đề lớn "Olek" lặp lại trong
phạm vi ~40px — dư thừa, tốn diện tích card. Bỏ 1 trong 2, dời "Plant · 17 HP" lên sát header.
**Effort**: S

### 2. Nút CTA chính — chữ trắng trên nền cam, tương phản thấp
Đúng lỗi đã ghi trong `reference_dangotheme-button-state-spec.md` (~2.2:1, fail AA) — nay thấy
rõ bằng mắt thường trên "SHORT", "CONTINUE RUN/BEGIN RUN", "CLAIM". Công thức sửa đã có sẵn
(`font_color = DangoTheme.BG`, ~9.5:1), chỉ cần rollout qua `style_button(btn, true, false,
DangoTheme.BG)` ở mọi call site nút primary.
**Effort**: S (nhưng dàn trải nhiều call site)

### 3. RunMap — dòng "Power level / visited" là 1 Label trần, không khung không icon
Confirmed tại `RunMap.tscn:47` — `StatusLabel` là `Label` thường, không style. Bọc trong 1 pill
nhỏ theo đúng phong cách turn-banner của Combat (`BG_PANEL` alpha 0.82, bo góc), thêm 1 icon nhỏ
trước con số.
**Effort**: S

### 4. Font hiển thị — mọi Label vẫn dùng font mặc định Godot
Đã là gap đã biết (ghi rõ ngay trong header `DangoTheme.gd`), KHÔNG phải ưu tiên — layout/spacing/
art-coverage ở các mục P0-P1 trên có tác động tới "cảm nhận xấu" lớn hơn nhiều so với đổi font.
Chỉ nên cân nhắc sau khi các mục trên xong, và cần duyệt asset nhị phân riêng theo đúng ràng buộc
đã nêu (thêm font = thêm asset cần user duyệt).
**Effort**: L (không chỉ thêm font — cần audit lại toàn bộ line-height/kerning sau khi đổi)

---

## Đã ổn — đừng đụng

- **Combat die-tray card** (icon + số lớn + nhãn "PART · TYPE" + keyword chip) — bố cục rõ ràng,
  màu theo đúng `DangoTheme.die_type_color()`, nhất quán. Không cần sửa.
- **Enemy intent bubble + đường bezier chỉ hướng tấn công** (`UnitHeadHUD`, `TargetLinesLayer`) —
  chính `design/ux/combat-screen-shroom-gloom-inspired.md` §0 đã xác nhận 2 thành phần này ĐÃ đạt
  yêu cầu brief, "No change proposed". Đừng redesign lại phần này dù nhìn hơi mảnh/tối giản trong
  screenshot — đó là chủ đích.
- **Axie quay lưng về camera trên sân đấu** — đúng ràng buộc đã chốt, không phát sinh vấn đề gì
  thêm từ góc nhìn thị giác.
- **Icon loại node RunMap** (kiếm-khiên cho Battle, phong bì cho Event) — bản thân icon rõ ràng,
  dễ đọc một khi hiện ra. Vấn đề của RunMap nằm ở layout/camera/text ID (mục P0 #1-2), không phải
  bộ icon.
- **Team-select die-face color chip** (viền màu theo effect type: đỏ=dmg, xanh dương=shield,
  tím=mana...) khớp 1:1 với `DangoTheme.die_type_color()` — hệ màu nhất quán xuyên suốt, giữ
  nguyên.

---

## Cần xác nhận trước khi sửa

**2 trong 3 ảnh Combat có thể đang phản ánh một build/scene CŨ hơn ảnh thứ 3, dù cùng ghi ngày.**
`real-flow-check.png` và `combat-die-tray-and-lines.png` cho thấy 1 banner lượt đơn độc (pill
"Lượt 1 · Lượt của bạn") + 1 con số không nhãn ("5" cùng hàng chấm tròn) ở góc dưới-trái — đúng
pattern mà chính comment trong code hiện tại mô tả là đã bị thay thế:
`CombatView.gd:597-598` — *"Unified top resource bar (review-uiux-godot-vs-web.md P0 #1/#2) —
replaces the old lone turn-banner pill plus the mana orb / reroll dots that used to sit unlabelled
in the bottom [corners]..."*. Ảnh thứ 3, `real-flow-varied-enemies.png`, cho thấy đúng "Unified
top resource bar" này (WAVE/REROLL/SHARD/MANA + Undo/Info/Log/Sound/Quit) — tức là khớp với code
đang có trong repo hôm nay, còn 2 ảnh kia thì không khớp.

Vì vậy: **không nên lên kế hoạch sửa phần top-bar/counter dựa trên `real-flow-check.png` /
`combat-die-tray-and-lines.png`** — 2 mục đó (banner đơn độc, counter không nhãn) rất có thể đã
được fix rồi, sửa lại sẽ là công vô ích hoặc sửa nhầm 1 màn hình không còn tồn tại trong
`CombatView` hiện tại. Đề xuất: nhờ `ui-programmer` xác nhận nguồn gốc 2 ảnh này (build cũ? scene
test riêng?) trước khi audit lại phần top-bar của Combat, và chụp evidence mới nếu cần audit tiếp
phần đó. Các phát hiện P0 #4 (quái placeholder capsule) trong danh sách trên vẫn giữ nguyên giá
trị bất kể build nào — nó nằm ở `CombatStage3D.gd`, một hệ thống khác, độc lập với top-bar.
