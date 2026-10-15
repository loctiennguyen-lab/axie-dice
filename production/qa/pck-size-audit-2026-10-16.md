# Audit dung lượng pck (16/10/2026)

Đọc thẳng danh sách file trong `web/index.pck` (314 MB, 5090 file, 16/10 00:35), không đoán từ thư mục nguồn. Chưa xoá hay đổi gì. Một số mục chưa kiểm hết, có ghi "chưa rõ".

## 1. Pck đang chứa gì

| Nhóm | MB | Ghi chú |
|---|---|---|
| `.godot/imported` (texture, wav, scn đã import) | 231.6 | phần lớn pck |
| `addons/axie_mixer_3d_assets` (glb bodies/parts + webp texture) | 74.1 | webp 28.9, parts 27.2, bodies 16.3. `weapon_anims/` (144 MB trong thư mục) đã bị loại đúng |
| `.godot/exported` + scripts/scenes/khác | ~8 | nhỏ |

Theo loại: `.ctex` 189 MB (s3tc 3D 107.5 + 2D lossless ~82), `.glb` 43.5, `.sample` (wav) 33.8, `.webp` 28.9, `.scn` 10.2.
Theo nguồn (phần import): Land 72.7, Atia arena 32.8 + monster 7.9, audio 33.8 (music 19.8 + sfx 13.9), vfx 30.8, backgrounds 22.2 (origins 21.1), monsters/anim 19.0, bosses 6.7, cosmetics 2.4.

## 2. Tăng 182 -> 300 MB (+118) do đâu

File mới từ 10/10 đóng góp 116.9 MB phần import + 3.5 MB glb/scene = ~120 MB, khớp mức tăng.

| Nguyên nhân | MB | Commit chính |
|---|---|---|
| Land hub HomeLand (461 file, texture 2048/1024 s3tc) | 72.7 | a54b192, 9f3c559, fe8b549 |
| Atia arena 6 biome (`atia/arena/meshsrc`, texture HomeLand chép lần 2) | 32.8 | e1099ee |
| Atia monster mới (glb/fbx + tex) | ~7 | lane C |
| Cosmetics v7/v8 + Echo Box chest | ~3.5 | d6b8eaa, 3cff178 |

Cosmetics v8 animation frame hầu như không đáng kể (dưới 1 MB). Land + arena chiếm ~90% mức tăng.

## 3. Export filter

- Ba preset (Web, macOS, Windows) cùng filter: loại `tests/*, tools/*, prototypes/*, scenes/dev_review/*`, `weapon_anims/`, `textures/*.png` của mixer. Kiểm bằng pck: không có file nào trong các thư mục đó. Nguồn png/fbx gốc cũng không vào pck, chỉ bản đã import. Tốt.
- Chỉ xuất s3tc (`etc2_astc=false`, web `for_desktop=true`, `for_mobile=false`). Không bị nhân đôi s3tc + etc2. Hệ quả: điện thoại/Safari yếu có thể phải giải nén, chưa kiểm.
- `export_filter="all_resources"` nên asset không ai tham chiếu vẫn vào pck.
- Windows exe 424 MB là embed_pck không nén, zip còn 235 MB. macOS zip 259 MB. Cùng nội dung pck, chỉ khác runtime + cách đóng gói.
- Không loại `*.wav` hay `*.json` thừa, chưa rõ có file rác trong `include_filter="*.json"`.

## 4. Trùng lặp và asset không dùng

- Texture png trùng nội dung giữa `assets/land/homeland` và `assets/atia/arena/meshsrc`: 26 bản dư, **15.6 MB** (cây, ground Savannah/Arctic/Forest, rock Luna...). Mỗi bản có `.import` riêng nên import hai lần.
- `assets/atia/*/tex.png` + `model.fbx`: 24 monster, không trùng, ok.
- Phân tích "không ai tham chiếu" **không kết luận được**: music/sfx/vfx/monster anim/backgrounds được nạp bằng tên ghép chuỗi, và texture Land đi qua .tres/fbx import nên grep tĩnh báo sai. Chưa rõ file nào thật sự mồ côi. Nghi ngờ nên kiểm tay: `Terrain_Mask.png` (2.8 MB, Resource_Plot, vẫn được material Savannah ground tham chiếu), `goccay.png` 1.6, `land_mystic_ground_01`, `assets/backgrounds/plant_landscape.png` 1.1, `assets/backgrounds/origins` (20 MB, chỉ 1.2 MB thấy được tham chiếu tĩnh).

## 5. Danh sách cắt, xếp theo lợi (số MB là ước lượng, chưa thử)

| # | Việc | Tiết kiệm | Rủi ro |
|---|---|---|---|
| 1 | Nhạc + sfx wav -> ogg (music 19.8 + sfx 13.9 -> ~5) | ~28 | An toàn cho L1, cần nghe lại loop |
| 2 | 2D lossless `.ctex` -> lossy (vfx 31, backgrounds origins 21, monsters/anim 19, bosses 6.7). Backgrounds là jpg nên dùng Lossy/VRAM | ~35-45 | Cần art check (banding, vfx có alpha mềm) |
| 3 | Bỏ bản trùng arena meshsrc, cho material arena trỏ về `land/homeland` | ~15.6 | Cần art check + chạy t_assets/arena test |
| 4 | Texture 2048 xuống 1024: T_Billboard_Big (5.6), T_Forest3 (5.6), land_genesis_pattern (5.6), Savannah ground (2.8 x2) | ~15 | Cần art check (billboard đọc chữ?) |
| 5 | Kiểm và xoá asset mồ côi thật (mục 4, `backgrounds/origins`, `Terrain_Mask`) | ~5-20 | Chưa rõ, cần grep kỹ + chạy suite |
| 6 | Texture Land 1024 xuống 512 cho phần nhỏ (Alchemy lv1-4 1.4 MB mỗi cái, tree 1.4 MB) | ~10 | Cần art check, để sau L1 |
| 7 | Mixer: webp texture 28.9 MB + glb 43 MB, nén lại / bỏ part ít dùng | chưa rõ | Để sau L1 |
| 8 | Tách pck (Land/Atia tải sau, DLC pck) cho web | giảm tải đầu | Kiến trúc, để sau L1 |

Làm 1 + 2 + 3 + 4 cộng lại ước ~95-105 MB, pck về ~200 MB. Mục 1 và 3 gần như không đụng nhìn; 2 và 4 cần art-director xem trước.

## 6. Việc dọn nhỏ

- `prototypes/land_spike/homeland` trùng UID với `assets/land/homeland` (38 cảnh báo khi export, 22 MB trong repo). Không vào pck, nhưng nên xoá hoặc bỏ khỏi import để gọn.
- `web/_pckparts` cũ 215 MB (không phải pck mới, chỉ tốn đĩa, đã gitignore).

## Chưa rõ

- Kích thước pixel thực của từng texture (suy từ dung lượng s3tc: 5.6 MB = 2048 DXT5, 1.4 = 1024 DXT5/2048 DXT1).
- Texture mixer 3D (webp) có đang dùng cả ở độ phân giải 3D không.
- Lý do Windows exe lớn gấp ~1.6 lần pck + runtime.
- Số MB tiết kiệm chưa đo bằng export thật.
