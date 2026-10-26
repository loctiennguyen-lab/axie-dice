# Cosmetics frames round 6: brainstorm (art-director, 26/10)

**Đã sửa theo review 26/10** (`cosmetics-frames-round6-review.md`, APPROVE WITH CHANGES): giữ Snow Globe trong Rare box, Cairn làm Rare thứ 5; Mythic tối đa 3 file; thêm luật test buộc, script kiểm viền, lệnh rasterize, ngân sách 100 KiB; id/tên file chốt luôn; chốt 8 khung (không còn câu hỏi Liam).

Nháp, chưa duyệt. Liam cho tự chọn số lượng. Prompt dán Claude Design: `design/handoffs/cosmetics-3d/PROMPT-ROUND-6.md`.

## 1. Khoảng trống và con số

Đã kiểm trong code (26/10):

| Nguồn | Common | Uncommon | Rare | Epic | Legendary | Mythic |
|---|---|---|---|---|---|---|
| Khung trong `art_map` Echo Box thường | 6 | 3 | 4 | 6 | **0** | 1 |
| Pool id (`echobox.json` pool) | 61 | 55 | 47 | 28 | 20 | 12 |
| Dice trong `art_map` | | | | | 2 (gold, kingdom) | 1 |

Ba chỗ hở:
1. **Legendary box thường có 20 id mà 0 khung**. Người mở ra Legendary chỉ bao giờ thấy 2 xúc xắc. Đây là hở nặng nhất.
2. **Thưởng mốc Land trùng pool khác** (vi phạm `land-v1-spec.md:94`): m2 `frame_u_vine` (đang ở Pass), m5 `frame_r_snowglobe` (Rare trong Echo Box), m8 `frame_l_sunburst` (Legendary box season). Land cần 3 khung riêng. Dice mốc (m3 moss, m6 spore) cũng trùng, nhưng đợt này chỉ làm khung, việc dice để sau.
3. Snow Globe **ở yên trong Rare box** (lý do trùng Land hết khi Land có khung riêng). Không để món nào mất nguồn.
4. Mythic 1 khung (crystal) cho 12 id, nên thêm 1.

**Tổng chọn: 8 khung.**

| Nhóm | Số | Bậc | Căn cứ |
|---|---|---|---|
| Mốc Land | 3 | U, R, L | khớp 3 mốc khung hiện tại (m2, m5, m8), giữ bậc cũ để không đổi cân bằng |
| Echo Box Legendary | 3 | L | từ 0 lên 3 khung (thêm 2 dice = 5 art cho 20 id, mỗi art lặp 4 lần; khớp mức Epic 12 art cho 28 id) |
| Echo Box Mythic | 1 | M | 1 lên 2 khung, đủ cảm giác "chase" cho 12 id |
| Echo Box Rare | 1 | R | Cairn làm khung Rare thứ 5 (4 -> 5), Snow Globe giữ nguyên |

Không thêm Common/Uncommon/Epic: Common 6 / Uncommon 3 / Epic 6 đã đủ cho thứ tự mod; thêm chỉ tốn scope. Không nhắm tới 223 id placeholder (câu cũ, để riêng).

Sau đợt này, khung trong Echo Box: C6 U3 R5 E6 L3 M2. Tổng 27 -> 35 khung trong repo.

## 2. Chủ đề

Sáu biome Land (Savannah, Forest, Arctic, Mystic, Genesis, LunaLanding) là bộ khung xương. Mỗi biome đúng 1 khung, không trùng:
- Land: **Forest (U)**, **Arctic (R)**, **Genesis (L)**. Theo thứ tự mở khoá dần từ rẻ đến hiếm, đúng nhịp mốc 12 / 42 / 90 điểm.
- Echo Box Legendary: **Savannah, Mystic, Luna Landing**. Dùng ba biome còn lại; người mở box nhận cảm giác "một góc Land".
- Mythic: **Event Horizon**, không thuộc biome nào, tím #B04DFF đúng màu bậc.
- Rare: **Cairn** (đá xếp, rêu), chủ đề trung tính để Rare box không có thêm băng.

Rủi ro đụng nhau (đã ghi vào prompt):
- Arctic Rare: Rare đã có Frost, Icicle, Snow Globe, Aurora. Khung mới chỉ dùng cành thông phủ tuyết + quả đỏ, cấm tinh thể băng.
- Genesis Legendary: Sunburst đã chiếm tia nắng / mặt trời. Genesis dùng hạt nảy mầm + rễ sáng.
- Mystic: không tím (Mythic) và không rune (Lunar Echo). Dùng chàm + cyan nhạt.
- Luna: không có mũ trăng (Eclipse).
- Legendary dùng viền vàng #FFB444 (art bible chưa có file ở `design/art/`; luật tier lấy từ tokens_ui3.json và prompt R5). Savannah thân ocher/umber để vàng band vẫn nổi.

Màu tier: Uncommon #0094FF, Rare #2DC661, Epic #27C0CA (Deep Reef giữ), Legendary #FFB444, Mythic #B04DFF (`tokens_ui3.json:168-191`).

Chưa kiểm được: hình dáng thật của biome Genesis/Mystic. Liam nên đính ảnh render từ `asset-library/design-library/` vào Claude Design, không mô tả bằng chữ.

## 3. Spec kỹ thuật (khớp pipeline R2-R5)

- 256 x 256 PNG RGBA trong suốt, tâm cửa sổ (128, 128), cửa sổ Ø162 xoá trên mọi layer, trang trí từ r 85 trở ra. Node khung = avatar x 1.5 (`frame_scale` 1.5 trong manifest).
- Viền trong suốt >= 4 px 4 phía mọi layer (alpha > 24 kết thúc >= 5.5 px trong; test `t_cosmetics.gd:45-50`). Layer xoay giữ r <= 124.
- Tên file: `<short>_base.png` + tối đa 2 layer động `<short>_<layer>.png`. **Tối đa 3 file kể cả base, Mythic cũng vậy.** Id và tên file chốt luôn trong prompt, chỉ tên hiển thị đổi sau.
- Test buộc (`t_cosmetics.gd`): anim chỉ `spin`/`pulse`/`sweep`, mỗi layer động có `reduce_static`, normal blend (không additive), pulse >= 1.4 s, 4 px ngoài cùng alpha = 0 chính xác, cửa sổ r <= 70 trong suốt. Prompt đã ghi hết, kèm script PIL để Claude Design tự kiểm.
- Ngân sách siết còn <= 100 KiB/layer (layer hiện có max 65 KiB). Outline 8 px neutral-1 + halo 4 px 40%.
- SVG có filter phải rasterize bằng Chrome headless (lệnh cụ thể trong prompt), nộp PNG + script rasterize.
- Mỗi khung có `spec.md` kiểu `frame_e_firefly/spec.md`, và README có bảng 8 tên (<= 2 từ, <= 18 ký tự, không trùng tên đang có).
- Nhớ từ R1-R5: Claude Design hay làm đè ra mép (R4 quét 13 file lỗi), nên prompt bắt in số alpha mép từng layer.

## 4. Việc phía game khi nhận zip

1. Chép PNG vào `godot/assets/cosmetics/frames/` (phẳng, như 27 khung hiện có). Kiểm tên không đè file cũ (bài học Chimera: file trùng).
1b. Chạy `godot --import` cho 8 khung mới, qua `godot/tools/with_lock.sh` (không import thì `.png.import` chưa có; parse error làm headless treo).
2. `cosmetics_manifest.json`: thêm 8 khung (layer, tier, anim). Test `t_cosmetics.gd:21` đổi `frames.size() == 27` thành 35 (dice giữ 26). Test :53-55 buộc mọi file khung phải được manifest nhắc đến.
3. `echobox.json` normal `art_map`: thêm `frame_l_biome_savannah/mystic/luna` vào `legendary` (hiện chỉ 2 dice), `frame_m_horizon` vào `mythic`, thay `frame_r_cairn` vào `rare` (Snow Globe giữ nguyên, dòng ~172 không đổi). Cập nhật `_note_art_map`. Thêm test đơn vị `art_map`: id Legendary nào ra khung nào (mod 5), Mythic, Rare.
4. `decor.json` milestones: m2 `frame_u_vine` -> `frame_u_land_forest`, m5 `frame_r_snowglobe` -> `frame_r_land_arctic`, m8 `items` `frame_l_sunburst` -> `frame_l_land_genesis`; sửa `label` ("Frame: ..."). m3/m6 (dice) chưa đụng.
5. `pass_v2.json` dòng 114 giữ `frame_u_vine` (Pass sở hữu); không đổi. Sunburst vẫn là season Legendary.
6. Hậu quả đo: id chưa dùng (frame_u_vine, snowglobe tại mốc Land) chỉ hiện ở Land trước đó; beta, tiến độ xoá sau beta nên không cần migrate. Test `t_cosmetics_equip.gd:48-59` dùng frame_u_vine, vẫn đúng.
7. Đặt tên thật: ids "tạm" như R5; Liam duyệt tên rồi mới đổi, đổi cả manifest, art_map, decor, test. File `design/handoffs/cosmetics-3d/NAMES-proposal.md` là nơi ghi tên.
7b. QA thêm: chip Land 48 px (holder 72) hiện đúng khung U/R/L ở bảng mốc; Reveal Legendary/Mythic mở tới pity trong lượt thật. Gợi ý: ghi `source: Land milestone` trong manifest và kiểm Profile không gom Genesis vào "chưa mở được" với người chưa chơi Land.
8. `echobox.json` thuộc `assets/data/economy/`, không nằm trong fingerprint `t_rules_version` (rules/, part_faces); nhưng cần chạy `run_tests.sh` và chụp Echo Box reveal + Profile + Land milestone ở 1920x1080 và 1280x720. Phải có thẻ Legendary/Mythic mới xuất hiện được trong một lượt thật (mở box tới khi pity ra) trước khi báo xong.
9. Cần review độc lập + QA flow thật theo quy trình của Liam; deploy chỉ khi Liam bảo.

## 5. Câu hỏi cho Liam

Không còn. Đã chốt 8 khung. Ticket để sau: dice mốc Land m3 (moss) và m6 (spore) vẫn trùng pool Pass/season.
