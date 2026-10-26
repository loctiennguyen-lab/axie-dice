# Review cosmetics frames round 6 (technical-artist, độc lập, 26/10)

Đã review: `cosmetics-frames-round6-brainstorm.md` + `design/handoffs/cosmetics-3d/PROMPT-ROUND-6.md`.
Đối chiếu với: `godot/assets/cosmetics/frames/`, `cosmetics_manifest.json`, `tests/t_cosmetics.gd`, `echobox.json`, `decor.json`, `land-v1-spec.md:94`, PROMPT-EPIC-ECHOBOX / ROUND-4. Không chạy Godot, không sửa file nào.

## Verdict: APPROVE WITH CHANGES

Số đếm đúng, spec kỹ thuật gần như khớp. Có 1 lỗ logic ở chỗ Snow Globe (chặn) và 1 chỗ mâu thuẫn về số layer Mythic. Sửa xong là gửi Claude Design được.

## CHẶN

**B1. Snow Globe bị bỏ rơi, không còn nguồn nào.** Brainstorm §1/§4 và prompt "Why" vừa bảo Snow Globe "ở yên chỗ cũ" (prompt dòng 13), vừa bảo nó "rời Rare box" (prompt dòng 12, brainstorm §4.3 thay `frame_r_snowglobe` bằng `frame_r_cairn` trong `rare`). Nếu m5 đổi sang `frame_r_land_arctic` và Snow Globe ra khỏi `art_map.rare` thì không còn đường nào ra Snow Globe (`grep` chỉ còn manifest, decor, echobox). Là một khung đã có file, đã duyệt, bỏ phí.
Lý do gốc để bỏ Snow Globe khỏi box là Land đang dùng nó (vi phạm `land-v1-spec.md:94`). Land có khung riêng rồi thì lý do đó hết. Đề xuất: GIỮ Snow Globe trong box, Cairn thêm vào làm khung Rare thứ 5 (hoặc Cairn rơi, còn 7 khung). Phải để Liam chọn. Nếu chọn giữ: Rare 4 -> 5, tổng Echo Box C6 U3 R5 E6 L3 M2, bỏ câu "bù chỗ Snow Globe" trong prompt, và bỏ bước thay dòng ~172.

## NÊN SỬA

**S1. Số layer Mythic mâu thuẫn.** Prompt §3 ghi Mythic "up to 3 motion layers" (= 4 file), §4 ghi "3 layers max / Mythic may use 3 layers (base + 2 motion...)". Thật: crystal và eclipse đều có 3 file (base + 2 động), và 9/27 khung hiện có 3 file; không khung nào 4. Brainstorm dòng 57 cũng nói mơ hồ. Chốt một câu: tối đa 3 file kể cả base, kể cả Mythic. Nếu muốn 4 file thì phải hỏi trước (thêm tải mỗi khung 4 PNG, và `CosmeticArt` chưa test case đó).

**S2. Prompt thiếu luật mà test đang buộc.** `t_cosmetics.gd` chỉ chấp nhận anim `spin`/`pulse`/`sweep`, mỗi layer động phải có `reduce_static`, mọi layer là normal blend (`not l.add`, tức KHÔNG dùng additive cho glow), pulse `period >= 1.4`. Prompt chỉ nói "motion no faster than 1.4 s" và gợi ý `_orbit`/`_drift` mà không nói layer phải diễn đạt được bằng 3 kiểu đó. Claude Design dễ làm "orbit" cần path riêng hoặc glow dùng screen blend rồi mất khi vào game. Thêm 2 dòng vào §4.

**S3. Edge: nói "alpha = 0 chính xác".** Test là `edge_max == 0.0` cho 4 px ngoài cùng (alpha 1/255 cũng đỏ). Prompt bảo "fade to 0 at 4 px" và "print max alpha" nhưng không nói acceptance = 0 trên cả 4 cạnh. Round 4 hỏng đúng chỗ này (eclipse bị cắt, 13 file). Viết thẳng: print 4 số mỗi layer, mọi số phải = 0, và gửi kèm script check (alpha > 24 phải nằm >= 5.5 px trong, và xoay không vượt r 124). Test thật còn buộc `r <= 70` trong cửa sổ trong suốt (dễ hơn Ø162, không lệch).

**S4. Cách rasterize không có lệnh.** Prompt §4 chỉ nói "Chrome headless". README cosmetics-3d và ROUND-4/EPIC không có lệnh/flag cụ thể. Ghi rõ: viewport 256, `--force-device-scale-factor=1`, `--default-background-color=00000000`, không để Chrome premultiply làm viền sáng; hoặc yêu cầu họ nộp luôn script rasterize.

**S5. Ngân sách 341 KiB/layer quá rộng.** 98 file trong `frames/` gồm 49 PNG, lớn nhất 65 KiB, tất cả đúng 256x256 (đo bằng header PNG). Web build và Land chip dùng nhiều khung cùng lúc. Gợi ý siết: <= 100 KiB/layer, 8 khung x 3 layer ~ 1.5 MB tối đa. Con số 341 chỉ copy từ round trước.

**S6. Thiếu đoạn "việc phía game" bước đặt id.** Brainstorm §4.7 nói id "tạm", đổi sau. Test `t_cosmetics` quét mọi `frame_...` trong `assets/data/economy/*.json` và đòi `has_art`; nếu đổi tên sau khi `art_map` đã commit thì phải đổi đồng thời manifest + file PNG (tên file mang id). Nên chốt tên file/id cuối trước khi import, chỉ đổi `name` hiển thị sau.

## Kiểm theo yêu cầu

1. **Spec khớp pipeline:** 256x256 RGBA (đúng, mọi PNG hiện có), tâm (128,128), cửa sổ Ø162 (manifest `window_diameter_px: 162`), `frame_scale 1.5`, viền >= 4 px (test đúng 4 px = 0), tên `<short>_<layer>.png`, loop >= 1.4 (test chỉ kiểm pulse), flat vào `frames/` — đều khớp. Lệch: S1, S2, S3, S5. Khung hiện có chỉ có layer base + tối đa 2 layer động.
2. **Số đếm đúng.** Manifest có 27 khung (C6, U4 gồm vine, R4, E9 gồm runering/firefly/s1_founder, L2, M2). `art_map`: C6 U3 R4 E6 L0 M1 khung; pool 61/55/47/... như brainstorm. 27 -> 35 đúng. Sau đợt: C6 U3 R4 E6 L3 M2 đúng (nếu theo B1 thì R5). Dice: legendary 2, mythic 1 đúng; "5 art cho 20 id" = lặp 4 lần, Mythic 3 art cho 12 id cũng 4 lần, hợp lý.
3. **3 mốc Land:** m2 `frame_u_vine` (Pass, `pass_v2.json:114`), m5 snowglobe, m8 sunburst (season box) — thay hết 3 trùng thì sạch. Vine ở yên Pass, sunburst ở yên season: đúng. Chỗ trống mới duy nhất là Snow Globe (B1). `t_cosmetics_equip` dùng vine, vẫn đúng. Dice m3 moss / m6 spore vẫn trùng pass/season; brainstorm đã ghi hoãn, ok nhưng nên có ticket.
4. **Prompt đủ để làm một lần?** Gần đủ. Hay sai: S1-S4. Thêm: "neutral-1" (outline 8 px) không ghi giá trị màu; "Reduce flashing = no Tweens" câu khó hiểu, nên viết "layer động đứng yên ở giá trị `reduce_static` đã ghi". Yêu cầu ảnh biome đính kèm là tốt, nhưng prompt cũng nên nói Genesis/Mystic chưa có render nên họ sẽ tự đoán nếu không đính.
5. **Việc phía game:** brainstorm §4 đủ (manifest + `frames.size() == 35`, art_map, decor label, QA 2 độ phân giải). Thiếu: (a) chạy `godot --import` để sinh `.png.import` cho 8 khung, tên mới chưa được registrar nếu bỏ qua (có hang-guard trong CLAUDE); (b) quay lại test count `named.size()` tự động ok; (c) Land milestone panel: kiểm khung Uncommon/Rare/Legendary hiển thị đúng ở chip 48px (holder 72) vì Land chip nhỏ hơn Profile; (d) QA Reveal thật: Legendary box có 20 id, mở tới pity mới thấy; nên có test đơn vị `art_map` chỉ rõ id Legendary nào ra khung nào, thay vì chỉ chụp màn hình.

## GỢI Ý
- Thêm 1 dòng acceptance cho prompt: "mỗi khung nộp kèm bảng manifest `anim` (layer, type, period, lo/hi)" để import khỏi đoán.
- Cân nhắc đặt Land frames `source: Land milestone` trong manifest để Profile hiển thị đúng nguồn.
- Genesis Land (L) và Sunburst (L) cùng bậc nhưng Genesis chỉ từ Land: đảm bảo màn Profile không gom nhầm vào "chưa mở được" cho người chưa chơi Land.

## Vòng 2 (26/10): kiểm lại bản đã sửa

Verdict vòng 2: **APPROVE** (còn 2 gợi ý nhỏ, không chặn).
- B1 đóng: prompt và brainstorm đều giữ Snow Globe trong Rare box, Cairn là Rare thứ 5, C6 U3 R5 E6 L3 M2, 27 -> 35. Bước art_map ghi rõ dòng ~172 không đổi, có thêm test đơn vị art_map. Đã bỏ câu "Snow Globe is leaving".
- S1-S5 đã vào prompt: Mythic tối đa 3 file (base + 2), chỉ spin/pulse/sweep, normal blend, edge alpha = 0 chính xác, lệnh Chrome có flag, <= 100 KiB, bảng anim, id/tên file chốt. Không thấy mâu thuẫn mới giữa prompt và brainstorm.
- `check_frame.py` (đọc code, không chạy): logic đúng. Viền dùng 4 lambda T/B/L/R cho 4 px ngoài cùng, window dùng hypot tâm pixel (x+.5) <= 70 khớp test (test chỉ lấy 3 điểm, script chặt hơn, tốt), size assert 256. Vòng for Python thuần 65k px x 6 lần mỗi layer, vài giây, chấp nhận được.
- Gợi ý 1: cờ OK chỉ gồm edge và window. Hai điều kiện còn lại (alpha > 24 phải cách mép >= 5.5 px; layer `spin` có max r <= 124) chỉ in số `max r`, không tự FAIL. Nên thêm vào `ok`, ví dụ `rmax <= 124` cho mọi layer (an toàn cả layer tĩnh vì viền đã cách 4 px) hoặc ghi "tự đọc max r". Prompt hiện đã nói bằng chữ nên không chặn.
- Gợi ý 2: `Image.convert("RGBA")` cho PNG 16-bit hoặc palette vẫn đọc được alpha, ok; chỉ cần nhắc nộp 8-bit RGBA như các round trước.
- Brainstorm dòng 74 (mục 6) còn câu "snowglobe tại mốc Land" hơi cũ nghĩa, vô hại.
