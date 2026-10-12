# Cosmetics 01 — bàn giao từ Claude Design (v6, 11/10/2026)

Trả lời cho `design/requests/cosmetics-art-request-01.md`. Nguồn: zip "Axie Dice cosmetics art request" Liam gửi.
Giữ ở đây để tra cứu; game dùng bản đã xuất ở `godot/assets/cosmetics/`.

## Có gì

| | Số lượng | Trạng thái |
|---|---|---|
| Die skins | 20/20 | Đủ. Plate tĩnh đã xuất PNG 512 → `godot/assets/cosmetics/dice/<id>_plate.png` |
| Dice FX | 14/14 | Chỉ có dạng code canvas (`cosmetics-art-v6.js`, `mountFX`) + spec. Phải dựng lại bằng particle trong Godot |
| Avatar frames | 5/21 | Claude Design chỉ dùng art Liam gửi (Homeland frame 1–3, SS2/SS3 Fancy). 16 ID còn trống |
| Màu Mythic | — | Đề xuất **Luna Crimson `#FF3D6E`** + tím đêm `#2A0F2E` |

Manifest đầy đủ (tên, tier, contrast, spec từng skin, spec 14 FX, toạ độ ô avatar của 5 khung):
`godot/assets/cosmetics/cosmetics_manifest.json`.

## Cách xuất lại PNG

Plate là SVG sinh bằng code và dùng filter (`feTurbulence`/`feDisplacementMap`) — Godot (ThorVG) không hỗ trợ filter,
nên phải rasterize bằng trình duyệt:
1. Chạy `CosArt.plateSVG(id, {static: true, size: 512})` (script đọc `assets/part/*.svg` qua `fetch`).
2. Bọc vào HTML `body{margin:0}`, chụp bằng Chrome headless `--window-size=512,599` (Chrome lấy 87 px cho khung),
   cắt 512×512 phía trên.

## Ghi chú của Claude Design (quan sát trong file)

- Skin hiện ở cả xúc xắc trong tray và mặt thẻ die (đồng ý "both").
- Ô avatar tròn Ø168 trên khung tự do; chip tài khoản 40 px nên khung hiện ~61 px.
- Không nhận được contact sheet biome → chất liệu theo biome dựa trên mô tả trong request.
- Bản này chỉ có PNG tĩnh; lớp animation (Epic+) giao riêng ở bản đầy đủ.
