# Màu đo thật (thay các hex [mắt] trong art-bible mục 4)

Cách đo: đọc PNG gốc bằng python (`-I`, tự giải PNG), lấy median của vùng 9x9 pixel (chỉ pixel alpha > 250) ở vùng phẳng, sáng đều, không viền/bóng. Nguồn trong `asset-library/design-library/` (viết tắt DL) và `godot/assets/`.
Lưu ý: ảnh là art vẽ tay nên mỗi vùng một sắc; cột "đo" là vùng đại diện, cột ghi chú nói khoảng dao động.

## A. Màu bảng chính / biome

| Tên | Hex cũ [mắt] | Hex đo | Nguồn + vùng (x,y) | Ghi chú |
|---|---|---|---|---|
| Kem (mặt xúc xắc, chữ) | #FFE9C2 | **#FFE5B4** | `design/handoffs/ui-05-figma/send/ui04-built/01-combat-player-turn-1920x1080.png`, 4 mặt xúc xắc (600,905) (770,925) (940,905) (1280,925) | cả 4 ra cùng giá trị. Lệch nhẹ so với #FFE9C2, nên dùng #FFE5B4 |
| Xanh cỏ (bụi f12a / Forest) | #7BCB2E | **#73DB27** (thân), #98E12B (nền sáng), #BEF366 (điểm sáng giữa) | DL/art-2d/items/f12a.png (100,130) (200,170) / (300,120) / (190,120) | #7BCB2E gần, hơi tối và ít bão hoà hơn. Chọn #73DB27 |
| Xanh băng (a14a) | tương tự #5FCFCB | **#6EE6D5** (mặt chính), #94E7E6 (mặt sáng), #B4F3EA (cạnh sáng), #289499 (mặt tối) | DL/art-2d/items/a14a.png (200,120) (250,100) / (120,60) / (60,100) / (100,300) | #5FCFCB (L_INFO) tối hơn băng thật. Băng thật sáng và xanh lục hơn |
| Trắng-xanh băng (Arctic) | #CFEFF5 | **#C9F1F6** | DL/renders/terrain/arctic/TileSnow_01.png (150,120); (100,100) = #C5EEF6 | đúng gần như tuyệt đối. Dùng #C9F1F6 |
| Vàng đất Savannah | #F2B632 | **#FAAB3B** (trục chính), #F9B245 (sáng hơn), #F9B040 | DL/renders/terrain/savannah/S_Plot_Module_2x2.png (240,20) (150,60) (300,100) / (330,70); S_TileGrass_01.png (100,100) = #F9B040 | thực tế cam hơn, không vàng chanh. #F2B632 sai nghiêng vàng. Dùng #FAAB3B |
| Đá be-hồng | #B59A8A | **#AA9886** (sáng), #9B8772 (thân) | DL/renders/environment/savannah/SavannahRock_01.png (150,100) (220,230) / (130,200) (90,150) | nâu-xám ấm, ít hồng hơn ước. Dùng #AA9886 |
| Terracotta (đá 02) | #D9814A | **#C58959** (đỉnh), #C9905E, #BB8251, #A9723E (thân tối) | DL/renders/environment/savannah/SavannahRock_02.png (150,60) (200,130) (280,110) (100,150) | đá thực tế vàng-nâu, kém đỏ hơn #D9814A |
| Terracotta (thùng a9a) | #D9814A | **#C77551** (thân), #B27458, #AB684C | DL/art-2d/items/a9a.png (150,300) (60,280) / (100,250) / (220,300) | thùng đỏ hơn đá. Nếu cần "terracotta" thật, dùng #C77551 |
| Xanh olive (Savannah) | #8AA33A | **chưa đo được** | không tìm ra ảnh nguồn có tên trong bible | nên bỏ [mắt] hoặc chỉ định ảnh nguồn |
| Plate UI (nâu ấm) | #3A2418..#24140B | **#2D2219** (plate), #2C2118, #2D2119; mặt thẻ tối #3E2618 | ui04-built 01-combat-player-turn-1920x1080 (560,825) (700,825) (1560,1040) (1700,60); (1190,925) | các plate thực chạy ra #2D2219 (nâu tối, hơi trung tính hơn #3A2418). Nằm trong dải 4.4 |
| Tím nền boss | (không có hex) | **#52305D** .. #704578 | ui04-built 06-combat-boss-1920x1080 (100,500) (960,300) (960,400) (1500,500) | tham chiếu cho Mystic/boss: #57355F, #613766, #704578 |

## B. 6 class chính thức (đo từ art Axie 3D trong repo)

Nguồn: `godot/assets/axie/back-<class>.png` (lưng Axie, thân phẳng) và `godot/assets/portraits/<class>.png` (256x256). Vùng: thân (50,100) (120,100) (100,130), và portrait (90,150) (170,150). Hai nguồn trùng nhau.

| Class | Hex UI đang dùng [code] | **Hex đo (art chính thức)** | Ghi chú |
|---|---|---|---|
| Aqua | #39C5F3 | **#00DFF3** | UI nhạt hơn, ít bão hoà hơn |
| Beast | #FFB23F | **#FDB014** | UI nhạt hơn một chút |
| Bird | #8BDCFF (sai) | **#FF78B4** (hồng) | đo ở `portraits/bird.png` (128,225) (90,150) (170,150). Hồng đậm hơn #FF8FB8 đề xuất. Mào (red) #F74745 |
| Bug | #F2624F | **#FF433E** | rất gần #D9472B danger. Tách bằng hình/icon như bible đã nói |
| Plant | #7DC943 | **#AFDB1B** | lệch nhiều: Plant thật là vàng-chanh, UI xanh lá. Đáng xem lại vì #AFDB1B gần cỏ #98E12B của nền Forest |
| Reptile | #B679F7 | **#9967FB** | thật đậm và xanh-tím hơn UI |

Kết luận: tất cả 6 class UI đều lệch so với art thật (UI nhạt/pastel hơn). Cần Liam chọn: (a) giữ màu UI pastel (đã hợp nền kem/nâu) hoặc (b) dùng đúng màu chính thức. Gợi ý của tôi: dùng màu chính thức cho chip class và viền xúc xắc để người chơi Axie nhận ra ngay, kiểm lại độ tương phản với chữ trên chip.

## C. Hex [mắt] không đo được từ ảnh

| Tên | Hex | Lý do |
|---|---|---|
| Moss / Amber / Crystal (độ hiếm Core) | #7DAA48 / #F2A33A / #7FB6F0 | đây là quyết định thiết kế, không có ảnh nguồn. Tôi không tìm thấy hex trong code UI. Nên đổi nhãn [mắt] thành [thiết kế]. |
| Nền không tối hơn | #2A2118 | ngưỡng thiết kế, không phải màu lấy mẫu. Nhưng plate thực đo #2D2219, nên ngưỡng này thực sự tối hơn cái đang có |
| Thua, sáng hơn | #3A2F26 | ngưỡng thiết kế |
| Olive | #8AA33A | xem bảng A |
