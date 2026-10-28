# Art gap audit — 28/10/2026

Người làm: art-director, chỉ đọc (không sửa file game, không chạy game).
Nguồn xem: 40+ ảnh trong `design/handoffs/ui-05-figma/send/ui04-built/` (UI-04 build) + đọc thư mục asset và code.
Không xem được hết 77 ảnh: tôi xem kỹ Anchor pick, Core offer, run map, awaken, combat, boss, defeat, run setup, result, missions, Echo Box, Pass, Land. Những màn khác (menu, codex, store, profile, tutorial) chưa xem, ghi rõ ở "Chưa kiểm".

## Kết luận ngắn

Liam đúng: phần "ngoài Axie 3D, Land 3D và rương Echo Box" gần như toàn là glyph phẳng + chữ trên nền nâu/navy trơn. Chỗ nặng nhất là thứ người chơi gặp mỗi run: Anchor, Core, run rule, node bản đồ, enemy. UI-05 (layout, màu, chữ, motion) sửa được cảm giác sạch/đẹp nhưng không tạo ra được hình minh hoạ. Cần một đợt art riêng, chạy song song.

Đã có sẵn và còn ổn (đừng làm lại): Axie 3D, Land 3D (HomeLand/Atia), rương Echo Box (`godot/assets/echobox/chests/`), 6 ảnh nền result biome (`ui3/result_bg/`), khung và xúc xắc cosmetic (3D, có normal/emission), VFX tấn công theo class (`assets/vfx/`, 42 file).

## 1. Bảng khoảng trống

Mức tác động: High = thấy mỗi run và gắn với fantasy/tiền; Med = thấy thường xuyên hoặc chỉ ở màn tiền; Low = ít thấy.

| Khu vực | Đang có (file, cách vẽ) | Sai ở đâu | Tác động | Cần gì |
|---|---|---|---|---|
| **Anchor / House** (pick, chip, awaken) | 6 SVG `ui3/icons/house_*.svg` (kin, embers, big_hand, gambler, mana_mine, volley). Một glyph đơn sắc trong vòng tròn 72px (Kin = 3 chấm nối, Embers = ngọn lửa, Big Hand = bàn tay). Thẻ Anchor pick chỉ có chữ rule/price/awakens trong 3 ô nâu giống hệt nhau. | Không có minh hoạ. 3 nhà nhìn cùng tông nâu, chỉ khác màu glyph. Không có cảm giác "chọn một phe". Chip trong HUD chỉ 20px, không đọc được. Màn awaken (21/22): khung nâu + glyph Kin to + hàng chục chip Moss xanh rải bừa che cả tên "Unison". Không có biến thể awakened. | **High** (mọi run, và là điểm bán của V5) | 6 emblem nhà 256px, nhiều lớp (nền, ký hiệu, viền), mỗi nhà một bảng màu + hoạ tiết riêng; thêm 6 biến thể awakened (phát sáng/nở). 6 ảnh minh hoạ thẻ pick ~512x320. Bộ chip 24/48px sinh từ emblem. |
| **Core icon** | `CorePanel.AXIS_ICON` = 7 icon dùng chung theo trục: stat=`face_buff` (mũi tên xanh lên), dice=`face_dmg`, pos=`face_summon`, mana=`face_mana` (tia chớp tím), quest=`node_treasure`, rule=`face_debuff` (mũi tên đỏ xuống), run_rule=`ui_settings` (bánh răng). Hàng trăm file `.tres` trong `godot/resources/relics/`, không có trường icon riêng trong `RelicDef`. | 65+ Core chỉ có 7 hình. Nest (Moss/stat) và mọi Core stat khác đều là mũi tên xanh; Golden Egg và mọi Core rule đều là mũi tên đỏ xuống, dễ đọc thành "giảm". Slot trong HUD lúc nào cũng là mũi tên. Không có chuyện "nhớ mặt Core". Core "Nest", "Golden Egg" tên gợi hình rất rõ nhưng không có hình trứng/tổ. | **High** (Core là hệ thống chính, và là thứ cần "nhìn thấy khi nổ") | 65+ icon Core riêng (cộng thêm Core thêm sau này), 128px nguồn, xuất 48/96. Ít nhất đầu tiên làm 30 Core hay gặp, phần còn lại dùng khung nhà + biểu tượng nhỏ. Cần thêm trường `icon` trong `RelicDef` (việc code, ngoài phạm vi art). |
| **Tier Core Moss/Amber/Crystal** | Chip chữ + 1/2/3 "mảnh" xanh nhỏ (`UI3.gd`, hình vuông bo góc 16px), viền màu xanh lá/cam/xanh dương. Crystal có viền khung 3 lớp. Thẻ offer: nền nâu phẳng, ô icon viền màu. | Ba tier chỉ khác màu viền và số mảnh. Không có chất liệu: Moss không giống rêu, Crystal không giống pha lê. Khung thẻ Crystal là thứ duy nhất có chút "hiếm". Thẻ không có chiều sâu/ánh sáng. Cảm giác "mở thẻ" không bằng một game gacha thương mại. | **High** (màn Core offer mỗi vài fight) | 3 bộ khung thẻ Core (Moss = rêu/gỗ, Amber = nhựa hổ phách, Crystal = pha lê) ~ 480x640, có lớp nền, viền, góc, hiệu ứng ánh (lớp riêng cho shader). 3 chip tier 64px có chất liệu. 3 sprite mảnh (shard) cho tier. |
| **Run rule** | 1 icon bánh răng (`ui_settings`) + chữ "RUN RULE: Upside Down" trong khung viền xanh (ảnh 14). | Mọi run rule đều là bánh răng. Không có hình cho "Upside Down", không phân biệt rule này với setting. Đây là điều kiện của cả run mà không có mặt. | **Med-High** (thấy trên HUD mỗi run, chọn ở đầu run) | Mỗi run rule một icon 96px + 1 banner/emblem 256px cho màn chọn. Số rule: chưa đếm chính xác trong code (`t_run_rule_catalog`), cần xác nhận. |
| **Mặt xúc xắc / face** | `ui3/icons/face_*.png/svg` (dmg thanh kiếm, shield, heal, poison, summon, buff, debuff, mana, blank) hỗn hợp PNG + SVG, kiểu khác nhau; icon trong bảng `assets/icons/web/` (đồ hoạ cũ từ bản web) trùng chức năng. | Hai bộ icon cùng nghĩa với hai kiểu vẽ (PNG pixel/đen viền vs SVG phẳng) cùng tồn tại. Kiếm, khiên trắng đen viền dày kiểu "emoji", không cùng ngôn ngữ với Axie mềm, tròn, sáng. Mặt xúc xắc kem + icon trên nền kem nhạt, tương phản thấp ở số. | **High** (thấy mọi lượt, chiếm màn hình nhiều nhất) | 1 bộ icon face duy nhất, ~12 icon (dmg, shield, heal, poison, burn, summon, buff, debuff, mana, wild, blank, hold) 128px nguồn, xuất 64/96, viền mềm, bóng nhẹ, cùng kiểu với Axie. Thay hai bộ cũ bằng 1 bộ. |
| **Huy hiệu bộ phận (part badge)** | `assets/icons/web/part/*.svg`: 6 loại (mouth, horn, back, tail, eyes, ears) x 6 class = 36 SVG. Hiện ở góc trái trên thẻ xúc xắc (24px, ảnh 01/06). | 36 SVG nhỏ, bên trong đọc không ra (cầu mắt, hàm…), 24px nên chỉ thấy là "một mảng màu". Đây là thứ người chơi dùng để ghép SET, nên đọc được là quan trọng cho gameplay. | **Med-High** | 36 badge 64px (hoặc 6 hình bộ phận x 6 màu class) với silhouette bộ phận Axie thật; có thể lấy từ model 3D Axie render ra. |
| **Enemy intent / status icon** | `assets/icons/web/*.png` (poison, burn, weaken, vuln, blind, stun, freeze, regen, thorns, undying...) + `ui3/icons/status_*.png`; trong ảnh combat thẻ intent bên phải có khoảng trống bên trái, chưa thấy portrait enemy. | Khung intent có vùng trống (ảnh 01, 06: không có avatar) trông như thiếu ảnh. Status icon là PNG đa nguồn, kiểu không đồng nhất. Icon nhỏ 14-16px trên badge tối, khó đọc. | **High** (mọi fight) | Avatar enemy 96px trên thẻ intent (render 3D từ model enemy/Monster Atia, xem phần nguồn). Bộ status icon ~16 cái, 64px, thống nhất kiểu với face icon. |
| **Enemy / boss (3D)** | 3D model: ảnh 01 có gà vàng, chuột trắng trên đường, trông như placeholder; boss (ảnh 06) là model Chimera tím gai, hợp. Ghi chú bộ nhớ trước: enemy placeholder-capsule đã từng là lỗi. | Enemy thường nhìn không giống "kẻ thù của Axie": con gà và chuột trắng đứng trên đồng cỏ, không phân biệt bằng mắt đâu là quân tinh nhuệ/thường. Không có biểu tượng elite. Chưa kiểm tính đa dạng giữa 5 biome. | **High** | Danh sách enemy theo biome (cần số từ `godot/assets/data`), chọn từ Atia `Monster` (235 mô hình) cho đủ ~20-30 loại, cộng 3-4 boss. Viền/aura phân biệt elite. |
| **Node bản đồ** | `ui3/icons/node_*.png` + `assets/icons/node/*.png` (battle=mặt mèo/sói, elite, event, shop, treasure, boss) trong vòng tròn 70px; node chưa mở chỉ là "?" trong vòng tối. Nền map = ảnh `backgrounds/` phong cảnh tím hồng. | 2 bộ icon node trùng nhau (`ui3/icons` và `icons/node`). Mặt mèo trên node battle bị đọc là "một con mèo", không phải "trận đánh". Cả bản đồ là chấm tròn + đường đứt nét, không có cảm giác hành trình (đường, biển, cột mốc). Map nền phong cảnh đẹp nhưng icon không ăn nhập. | **High** (mỗi run, 18 tầng) | 7 icon node (battle, elite, boss, event, shop, treasure, rest/unknown) 128px kiểu thống nhất, có viền, bóng, chất liệu; 3 trạng thái (đã qua, hiện tại, khoá). Đường nối dạng vẽ (đường đất/dây). 1 nền map riêng cho mỗi biome (5). |
| **Rương / Echo Box / pity** | `echobox/chests/tiers/` (6: bronze → lunacian), `echobox/chests/themed/` (10 rương theme). Ảnh 31: rương vàng lớn có nét vẽ tay, vòng sáng nâu mờ phía sau. Thanh pity bar màu xanh chữ nhật phẳng; ô pool 6 rương nhỏ. | Rương đẹp nhất game (vẽ tay), nhưng bao quanh nó là vòng tròn nâu phẳng và nền navy đen. Không có hiệu ứng mở (chưa kiểm cảnh mở), hộp "last open" là chữ. Các cosmetic ra được hiển thị trong reveal (`GachaReveal`) chưa thấy ảnh. Rương 6 tier có thể khác nhau chưa đủ rõ trong ô nhỏ. | **High** (đây là chỗ thu tiền) | Nền sân khấu Echo Box (bệ, ánh sáng, hạt), bộ frame reveal cho 6 độ hiếm (6 x 1 màn), nắp/rương mở 2-3 frame hoặc sprite sheet, ảnh preview cosmetic. |
| **Tiền tệ** | `ui3/icons/cur_*.png`: shard (lục giác xanh có tinh thể nhỏ), stone (cục đá bạc), gem (kim cương), ticket (vé vàng), fragment (mảnh xanh). Có bản 16/24/32/64. | Shard 24px là lục giác tối viền xanh, trông như nút nguồn; Stone là hình cầu xám, kém hấp dẫn so với Gem, trong khi Stone là currency chính của Land. Ba loại khác phong cách (hex + sphere + kim cương trong suốt). Không có "đống" (stack) khi nhận nhiều, ở màn Result hạt shard rải đè lên chữ (ảnh 28). | **High** (xuất hiện mọi màn) | 5 icon tiền thống nhất bóng/chất liệu (256px nguồn, xuất 24-64), thêm bản "đống" nhỏ/vừa/lớn cho phần thưởng, và 1 sprite hạt cho hiệu ứng. |
| **Cosmetics: khung** | `assets/cosmetics/frames/`: khoảng 21 khung (c_ class, u_ mushroom/pond/campfire/vine, r_ aurora/frost/icicle/snowglobe, e_ firefly/runering/s1_founder/reef_01..06, l_ sunburst/sovereign, m_ crystal/eclipse), nhiều lớp base/glow/rays. Round 6 đang chờ Claude Design. | Đã có chất, chủ yếu thiếu số lượng + cách trình bày. Pool Echo Box ghi 223 cosmetic; số khung/xúc xắc có art 3D còn thấp hơn nhiều. Chưa kiểm cách khung hiển thị trên Profile/leaderboard. | **Med-High** (monetisation) | Tiếp tục round 6 (Claude Design). Cần đếm art_id còn thiếu so với 223 pool (xem `CosmeticArt.manifest()`), lập danh sách nốt. |
| **Cosmetics: xúc xắc** | `assets/cosmetics/dice/die_*` ~30 skin (clay, reed, sunwood, rune, spore, gold, kingdom, moon, redcrystal, theo class, reef) có albedo/normal/emission/sheen, 36/56/88px trim. | Chất tốt. Vấn đề là chỉ 2D "trim" ở trong tray, skin 3D chỉ thấy khi lăn; ở thẻ tray (ảnh 01) skin mặc định kem trơn. | **Med** | Thêm skin cho từng độ hiếm còn thiếu; ảnh thumbnail 256px cho shop/Echo Box (render từ 3D). |
| **Cosmetics: title / danh hiệu** | Chỉ là chữ (`New title: Người Giữ Ẩn` trong thanh nâu, ảnh 28). `Cosmetics.art_id` trả "" cho `fx_*` và title. | Không có huy hiệu, màu, khung. Title là thứ người chơi khoe, mà không có hình. Ghi chú: title tiếng Việt lẫn trong UI tiếng Anh (lỗi nội dung, không phải art). | **Med** | Bộ banner/ribbon title theo độ hiếm (5 kiểu) + icon nhỏ cho ~10 title đầu. |
| **Pass reward** | Chỉ chữ: "LV 1 · 300 Shard", "Unlock: Survival Instinct", ô nâu cùng cỡ (ảnh 34). | Mốc 30 level không có hình thưởng nào. Không phân biệt thưởng thường (Shard) và thưởng lớn (Bloodline, cosmetic). Nền navy phẳng. Chỗ này chạy dài cả mùa, là nơi giữ chân. | **Med-High** | 30 ô thưởng cần: ảnh thưởng (dùng tiền tệ, Core icon, cosmetic thumbnail), khung mốc lớn mỗi 5 level, 1 minh hoạ banner mùa 1920x300, 1 nhân vật/mascot. |
| **Land decor / prop** | Land 3D (ảnh 23): nhà cỏ xanh, cổng đá đỏ, lều tím, cây, đá, thùng. Đất vàng savannah có noise texture. HomeLand/Atia tại `asset-library/godot-ready/`. `godot/assets/land/houses.json`. | Land là phần đẹp nhất nhưng: có nhiều đối tượng ngẫu nhiên không cùng tỉ lệ (con cú bay, con Axie xanh đè lên cây), nền đất lặp, không có biome khác nhìn ra sao ở tier 2+ (chưa kiểm ảnh 24). Plot khoá là ô đứt nét có ổ khoá nhỏ. | **Med** (hub, thấy mỗi lần mở game) | Chọn thêm decor có chủ ý, tạo 5 bộ biome (Savannah/Forest/Arctic/Mystic/Genesis) từ `asset-library/godot-ready/scenes/` + `design-library/renders/environment/<biome>/`. Biểu tượng plot khoá 3D. |
| **Nền từng màn** | Combat/Result: 3D scene + nền mờ. Ảnh result_bg 6 biome có (jpg). Echo Box, Pass, Missions, Run setup, Defeat: nền trơn `#12161c` navy hoặc nâu. Anchor pick/Core offer: nền mờ từ 3D. Map: ảnh vẽ tím hồng (`backgrounds/plant_landscape.png`, chỉ 1 file). | 5 màn "menu phụ" đều là nền đen xanh phẳng. Chỉ có 1 ảnh nền cho map. Cảm giác "app quản lý", không phải game. | **High** | 1 nền cho mỗi nhóm màn: Echo Box (sân khấu), Pass/Missions (bảng thông báo/giấy), Run setup (bàn chọn). 5 nền map theo biome. Kích thước 2560x1440 jpg/webp, nén vừa phải (build web đang 190MB). |
| **VFX texture / particle** | `assets/vfx/<class>_<action>.png` 42 file (bite, gore, slash, smash, cast, projectile, throw x 6 class) = đòn tấn công. Hạt Moss (chip xanh 16px) và hạt Shard (lục giác) dùng cho hiệu ứng awaken và result. | Hạt awaken (ảnh 21) là chip Moss xanh rải bừa trên mọi nhà; lẽ ra theo màu và hình của nhà (lửa cho Embers). Result (ảnh 28): hạt Shard rơi đè chữ, không có glow/mờ dần, rõ là sprite đơn lẻ. Chưa có tia sáng (rays), vòng sáng, lấp lánh, đốm sáng dùng chung. | **Med-High** | Bộ texture hạt dùng chung: tia sáng (ray) 1024, vòng sáng (halo) 512, sparkle 4 kiểu, hạt khói/ngọn lửa, mảnh pha lê 3 kiểu. Hạt riêng theo nhà (6). Tất cả tách lớp, nền trong suốt. |
| **Portrait Axie 2D** | `assets/portraits/` 6 ảnh (1 mỗi class). Run setup dùng ảnh Axie thật (cắt nửa người, nền xám phẳng, ảnh 39). | Nền thẻ xám phẳng không có tag/class/viền; ảnh bị cắt ở ngực. Class chỉ hiện bằng chữ "Plant · Starter". | **Med** | Khung thẻ Axie theo class (6), nền riêng theo class. |
| **Tutorial / hướng dẫn** | Chưa kiểm ảnh (có `t_tutorial_*` test, `tutorial coach`). Dựa vào chữ. | Chưa kiểm. Dự đoán: không có mascot hay hình minh hoạ. | **Med** (người mới) | Cần Liam hoặc agent xem màn tutorial rồi quyết. Dự kiến 6-8 ảnh minh hoạ bước + 1 mascot. |
| **App icon / store art** | Chưa tìm thấy trong `godot/assets/` (không có thư mục icon hay splash). | Chưa kiểm kỹ. Ghi vào danh sách cần xác nhận. | **Med** (khi lên store/web share) | App icon 1024, favicon, ảnh chia sẻ 1200x630, key art 1920x1080, ảnh capsule. |
| **Màn Menu chính / loading** | `scenes/` có MainMenu nhưng chưa xem screenshot (UI-04 index không có). Ghi chú từ audit 19/9: MainMenu "zero art direction". | Chưa kiểm lại sau UI-04. | **High** (ấn tượng đầu) | Key art / logo Axie Dice, nền động nhẹ từ Land 3D. |

### Chưa kiểm (không có ảnh hoặc chưa mở): Menu chính, Codex, Store/Daily, Profile, Leaderboard, Vault, tutorial, Land tier 3-6, rương mở thật (hoạt ảnh). Nên chụp thêm trước khi lập kế hoạch cuối.

## 2. Top 10 theo tác động

1. **Icon Core riêng (65+)** thay cho 7 icon trục dùng chung.
2. **Emblem 6 nhà Anchor** (nhiều lớp + biến thể awakened) và thẻ Anchor pick có minh hoạ.
3. **Khung thẻ Core 3 tier** (Moss/Amber/Crystal) có chất liệu, không chỉ đổi màu viền.
4. **Bộ icon xúc xắc/face + status thống nhất** (thay 2 bộ PNG/SVG lệch phong cách).
5. **Icon node bản đồ + đường nối vẽ + nền map theo biome**.
6. **Enemy thường theo biome** (thay gà/chuột placeholder) + avatar enemy trên thẻ intent.
7. **Tiền tệ 5 loại thống nhất + "đống" thưởng + hạt**.
8. **Nền cho các màn phụ** (Echo Box, Pass, Missions, Run setup, Defeat).
9. **Sân khấu Echo Box + reveal theo độ hiếm + ảnh preview cosmetic**.
10. **Icon run rule + huy hiệu part (36) + hạt VFX dùng chung (rays/halo/sparkle)**. (Gộp vì cùng loại việc icon/sprite nhỏ.)

Đứng sau: Pass reward art, title/banner, key art + app icon, decor Land.

## 3. Chi tiết top 10

Style chung: Axie/Lunacia = mềm, tròn, sáng, viền đậm dày vừa phải, bóng đổ nhẹ, màu bão hoà ấm. Mục tiêu "mobile thương mại": mỗi icon có 3 lớp (nền, ký hiệu, highlight), không dùng glyph đơn sắc. Giữ cùng một hướng sáng (từ trên-trái) cho mọi icon.

### 1. Icon Core (65+)
- Số lượng: 65+ (đếm chính xác từ `godot/resources/relics/c_*.tres` bỏ `c_test_*`, cần chốt), nên làm trước 30 Core hay gặp.
- Định dạng: PNG trong suốt, nguồn 256x256, xuất 96 và 48. Godot import ở 2x. SVG không hợp vì nhiều lớp.
- Style: mỗi Core một vật thể dễ gọi tên (trứng vàng, tổ, vảy, ngọn nến, bia mộ...). Nền hình tròn/khiên theo tier, ký hiệu màu theo nhà.
- Nguồn đề xuất: (a) Claude Design vẽ bộ mẫu 6-8 icon để chốt kiểu; (b) tạo tiếp bằng AI sinh ảnh + dọn tay (tách nền, thống nhất khung) theo mẫu đã chốt; (c) các vật thể có trong Atia/HomeLand (`asset-library/design-library/icons/` 65 icon Homeland: trứng, quặng, thỏi vàng... dùng làm tham chiếu hoặc dùng thẳng với khung riêng). Nếu Liam muốn chất lượng thương mại thật, thuê hoạ sĩ cho phần 30 icon đầu.

### 2. Emblem nhà Anchor
- Số lượng: 6 emblem x (thường + awakened) = 12, cộng 6 ảnh thẻ pick 512x320, 6 chip 48px.
- Định dạng: PNG trong suốt, 256 và 512, tách lớp (nền/ký hiệu/viền sáng) để Godot làm phát sáng.
- Style: Kin = tổ/trứng ấm xanh lá; Embers = lửa cam; Big Hand = bàn tay nâu/vàng; Gambler, Mana Mine, Volley mỗi nhà một hình + một bảng 3 màu. Phải đọc được ở 20px (silhouette đơn giản).
- Nguồn: Claude Design vẽ emblem (UI-05 có thể gộp, nhưng brief UI-05 nói "chỉ art có sẵn", nên cần mở rộng phạm vi cho phần này). Awakened = hiệu ứng lớp trên, không cần vẽ lại.

### 3. Khung thẻ Core
- Số lượng: 3 khung thẻ 480x640 + 3 chip tier 64px + 3 sprite mảnh.
- Định dạng: PNG 9-slice (nên cắt được) hoặc 1 ảnh lớn; Godot dùng `NinePatchRect` + lớp glow riêng. Texture 2x.
- Style: Moss = gỗ/rêu thô; Amber = nhựa hổ phách trong; Crystal = pha lê cắt cạnh, ánh lạnh. Khác chất liệu, không chỉ khác màu.
- Nguồn: Claude Design (khung) + AI cho texture chất liệu rồi dọn; hoặc hoạ sĩ.

### 4. Icon face + status
- Số lượng: ~12 face + ~16 status = 28 icon.
- Định dạng: PNG 128 nguồn, xuất 64/96; 16-24px bản đơn giản hoá cho status.
- Style: thay kiếm/khiên "emoji" bằng hình mềm, viền màu tối cùng hue, nền mặt xúc xắc kem nên icon cần đủ đậm để đọc.
- Nguồn: Claude Design trên nền Axie style, hoặc dùng bộ `assets/icons/web/` làm tham chiếu chức năng rồi vẽ lại. Cần đúng 1 bộ, xoá bộ kia.

### 5. Node bản đồ
- Số lượng: 7 icon x 3 trạng thái = 21 (có thể sinh trạng thái bằng shader từ 7 icon); 5 nền map; 3-4 kiểu đoạn đường.
- Định dạng: icon 128 PNG; nền 2560x1440 webp/jpg (nén, chú ý dung lượng web); đường nối là texture lặp 256x64.
- Style: node như "mốc trên bản đồ cuộc phiêu lưu": gỗ, đá, cờ; boss to hơn, có viền đỏ/tím.
- Nguồn: icon từ Claude Design; nền map theo biome dựng từ HomeLand `Environment` (`asset-library/godot-ready/scenes/`, render từ cam trên cao) hoặc AI sinh nền rồi chỉnh. Hiện chỉ có `backgrounds/plant_landscape.png`.

### 6. Enemy theo biome
- Số lượng: ~20-30 enemy thường/elite + 3-4 boss (cần xác nhận số hiện tại ở `godot/assets/data`), cộng avatar 96px mỗi loại.
- Định dạng: model 3D `.tscn/glb` từ thư viện; avatar render từ model, PNG 192, xuất 96.
- Style: kẻ thù Lunacia (chimera, slime, bọ, nấm...) cùng bảng màu Axie; elite có viền/aura.
- Nguồn: Atia `DeliveryAssets/Monster` (235 mô hình) tại `asset-library/godot-ready/src/Atia_Asset/...` — xem contact sheet `asset-library/godot-ready/contact_sheets/` chọn. Render avatar bằng 3D (Blender/Godot) tự động. Phải kiểm dung lượng web.

### 7. Tiền tệ
- Số lượng: 5 icon (Shard, Stone, Gem, Ticket, Fragment) x 4 cỡ + 3 "đống" mỗi loại = 35 sprite nhỏ, 5 hạt.
- Định dạng: PNG 256 nguồn → 16/24/32/64; "đống" 256.
- Style: cùng kiểu vật liệu (đá quý bóng, viền sáng), Gem là hào nhoáng nhất vì là tiền thật; Shard/Stone không được trông xám/tối.
- Nguồn: `asset-library/design-library/icons/` có sẵn diamond, ingot_gold, stone_block (có thể dùng cho Gem/Stone); Shard/Fragment cần vẽ (Claude Design). 

### 8. Nền màn phụ
- Số lượng: ~5 nền (Echo Box, Pass/Missions chung 1 hoặc 2, Run setup, Defeat/Result giữ nguyên).
- Định dạng: 2560x1440 webp/jpg, có biến thể mờ cho nền UI. 
- Style: không gian trong game (quầy hàng Lunacia, bảng nhiệm vụ, sân chọn đội), mờ nhẹ để UI nổi.
- Nguồn: render 3D từ Land/HomeLand (cảnh nhà, quầy `asset-library/godot-ready/scenes/`) rồi làm mờ; rẻ nhất, cùng phong cách game. Claude Design chỉ lo phần phủ màu/overlay trong UI-05.

### 9. Echo Box sân khấu + reveal
- Số lượng: 1 nền sân khấu, 6 khung reveal (theo độ hiếm), 2-3 frame rương mở x 6 tier, thumbnail cosmetic ~100+ (render 3D, tự động).
- Định dạng: PNG trong suốt + sprite sheet 8-12 frame; thumbnail 256.
- Style: kịch tính, ánh sáng, hạt; mỗi tier một màu và kiểu nổ.
- Nguồn: rương đã có (vẽ tay, giữ); phần ánh sáng/hạt dùng texture VFX chung (mục 10); thumbnail render từ model 3D của dice/frame đã có.

### 10. Run rule + part badge + VFX texture chung
- Run rule: số rule (xác nhận) x icon 96 + 1 emblem 256.
- Part badge: 36 icon 64px (6 phần x 6 class). Render từ model Axie 3D (cắt bộ phận) hoặc vẽ silhouette đơn giản.
- VFX chung: ~20 texture (ray, halo, sparkle 4, khói, lửa, mảnh pha lê 3, hạt theo nhà 6), nền trong suốt, 512-1024.
- Nguồn: Claude Design (icon), render 3D Axie (part), AI sinh texture hạt rồi dọn / hoạ sĩ VFX.

## 4. Câu hỏi cho Liam (tối đa 6)

1. **Ngân sách và người làm**: có thuê hoạ sĩ không, hay chỉ Claude Design + AI sinh ảnh + render 3D? Việc này quyết định top 1-3 (Core/Anchor/khung thẻ) làm theo cách nào.
2. **Phạm vi Claude Design**: UI-05 brief đang nói "chỉ dùng art có sẵn". Liam có muốn mở thêm để Claude Design vẽ emblem/icon (top 2, 4, 7) không, hay tách thành đợt art riêng?
3. **Ưu tiên**: Core icon (65+) quan trọng hơn hay màn Echo Box (thu tiền) quan trọng hơn? Nếu chỉ làm được 3 thứ trước beta thì chọn gì?
4. **Dùng AI sinh ảnh**: được phép dùng cho icon/nền không? (Có vấn đề đồng nhất kiểu và bản quyền/chính sách Sky Mavis; cần Liam xác nhận.)
5. **Enemy**: có dùng Atia `Monster` làm enemy chính thức không, hay có bộ riêng? Hiện enemy thường (gà, chuột) nhìn như placeholder.
6. **Dung lượng web**: build đang ~190MB. Có ngưỡng nào Liam chấp nhận được cho đợt art này (ví dụ +30MB)? Cần để chọn nén và số nền.

## Ghi chú kiểm chứng

- Số 65+ Core lấy từ lời Liam/brief; tôi đếm được 7 icon trục trong `CorePanel.gd` dòng 11-12, và `RelicDef` không có trường icon (grep trống).
- `AWAKEN_ICON := "face_buff"` có chú thích "stand-in for ui_awaken (art pending)" tại `CorePanel.gd` dòng 29: icon awaken thật đang chờ.
- Chưa kiểm số run rule, số enemy, số cosmetic có art so với 223 trong pool. Các số trong bảng đánh dấu "cần xác nhận" là để agent làm tiếp đếm.
- Chưa mở file ảnh game thật ngoài các PNG trong handoff; phần "khung ~21", "xúc xắc ~30" đếm từ tên file.
- Một số ảnh có khoảng trống trên thẻ intent có thể là artefact của capture; nên đối chiếu `screens-current/` trước khi ghi vào backlog (bài học 19/9: kiểm ảnh với code comment).

## Số đếm bổ sung (28/10, đếm file trong `godot/resources/relics/`)
- 249 file `.tres` tổng. Trong đó:
  - 93 Core `c_*`.
  - 117 relic cũ `r_*`, phần lớn vẫn hiện như Core.
  - 16 Anchor/active `a_*`.
  - 21 run rule `rule_*`.
- Vậy icon riêng cho Core là cỡ ~100 món, không phải 65. Nên làm theo 7 trục × tier trước (khung + nền màu), rồi mới vẽ icon riêng cho các Core hay gặp nhất.
- Liam đã chốt (28/10):
  - Nguồn art: Claude Design + thư viện HomeLand/Atia (không thuê hoạ sĩ ở bước này).
  - Anchor: tranh minh hoạ cảnh dạng thẻ bài.
  - Thời điểm: sau khi UI-05 đợt 1 chốt phong cách.
  - Còn mở các câu 3, 4, 5, 6 ở mục 4.
