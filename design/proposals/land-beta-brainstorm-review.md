# Review: Land bản beta (brainstorm 26/10)

Reviewer độc lập: creative-director, 26/10/2026. Không sửa brainstorm, không sửa code.
Đã đối chiếu: `Land.gd`, `LandUpgradeScreen.gd`, `LandNav.gd`, `MetaState.upgrade_land`, `land_decor.gd`, `land_tiers.json`, `decor.json`, `houses.json`, `echobox.json`, `pass_v2.json`, `missions.json`, `team_presets.gd`, `RaidScreen.gd`, `ProfileView.gd`, `economy-v2.md` §6, `land-meta-loop-brainstorm.md` 237-244, `land-v1-spec.md`, `build-spec.md` INV-1..7, `nhiem-vu-beta-brainstorm.md`, `phase-plan-v1.md`, session-state archive (spike Land).

## Verdict: APPROVE WITH CHANGES

Hướng đúng và đúng luật Liam: không sức mạnh, không thêm Stone, Land là chiều rộng. Phát hiện "beta chỉ thấy tier 1-2" là phát hiện tốt nhất của doc và đúng số. Nhưng có hai chỗ Liam sẽ quyết trên tiền đề sai (câu 2 và câu 3), và ngân sách web dựng trên phép ngoại suy trong khi Land web đang chạy thật, đo được ngay. Sửa 3 mục CHẶN rồi mới gửi Liam.

## 1. Số liệu: đúng / sai

Đúng (đã kiểm): Stone/tuần theo §6.3 (`economy-v2.md` 298-306); bảng tuần tới tier 2/3; giá tier 40k/100k/180k/500k/1M và cộng dồn 140k, 820k (`land_tiers.json`); điểm tối đa tier 1 = 14, tier 2 = 20 (`land_decor.gd:178-193`, trần `decor.json:3-10`); m2/m3/m4 = 12/20/30; 46k Stone nhà Nhiệm vụ (`missions.json:152-171`); 1,1%; món khởi đầu 90 Shard.

Sai hoặc thiếu:
- Dòng 69 + 125: "+8 decor common kéo m3 ra khỏi chỗ vừa đúng 20" là **sai**. Điểm = 1 × số món + 2 × số biome. Trần tier 2 là 16 món, cả 8 món mới đều Savannah/Forest, nên tối đa vẫn 16 + 4 = 20 dù có 7 hay 15 loại. Thêm common chỉ thêm lựa chọn, không nới m3.
- Dòng 16, 58: "nâng xong không thấy gì, đây là lỗi". Thực tế bấm Back gọi `LandNav.back_to_land()` (`LandNav.gd:79-81`), đổi cảnh, Land dựng lại ở tier mới. Vấn đề là thiếu khoảnh khắc và thừa một cú bấm, không phải lỗi. Không đổi thứ tự làm, nhưng đừng gọi là "vá lỗi" khi trình Liam.
- Dòng 60 (B3): màn nâng cấp **đã có** thanh tiến độ và dòng "X / Y Land Stone for Forest" (`LandUpgradeScreen.gd:115-136`) và cột "thêm gì" (`ADDS`, dòng 12-18). B3 chỉ còn là một chip trên HUD Land dẫn vào đó, công S. `ADDS` thiếu trần decor và nhà lv mới, nên sửa câu chữ luôn.
- Dòng 126: tier 2 ở 20k cho casual là 1,4-1,6 tuần (20.000/14.462 tới 20.000/12.398), không phải "~1,4".
- Dòng 126 "thang 1-2 năm đã chấp nhận": §6.4 cho casual nửa bộ 2,6 năm, regular 2,1 năm; khối Liam chốt 10/10 (dòng 39) ghi 1,9/1,5. Chính `economy-v2` đang lệch với nó. Không ảnh hưởng kết luận 1,1%, nhưng đừng trích "1-2 năm".
- Dòng 12: 16 món chế được + trophy (không chế), không phải "17 decor craft".
- Dòng 41: giá nhà Nhiệm vụ còn 3k/8k/20k Shard, cũng tranh với Shard chế decor.

## 2. CHẶN (sửa trước khi gửi Liam)

**C1. Câu 2 (hạ giá tier 2) dựa trên tiền đề sai, và vùng chết không được xử lý.**
Hạ 40k xuống 20k không phá INV-1..7 (Land không đụng part, tiền thật hay gate run) và không phá đường ~1 năm của heavy (52,3 tuần thành khoảng 51,7). Nhưng nó **không** sửa vùng chết m3→tier 3: m3 tới sớm hơn, tier 3 vẫn cách thêm 100k, nên vùng chết của casual còn dài ra một chút (khoảng 7 lên 7,5-8 tuần). Nó cũng là con số Liam tự xác nhận ngày 10/10 ("Con số hiển thị phải TO: 40.000...", `economy-v2.md` 35-36), nên phải trình là "mở lại quyết định của anh", không phải "chi phí gần bằng không". Tier sau không mất giá trị (tier 2 vẫn cho đúng những thứ cũ), chỉ bước tier 2→3 thành gấp 5 thay vì 2,5.
Đề xuất: tách hai việc. (a) Giá tier 2: lý do thật để hạ là người test beta (vài tuần) có thấy lần nâng đầu tiên hay không; ghi đúng như vậy. (b) Vùng chết: thêm 2 món **Rare** ở `min_tier: 2` (ví dụ `F_Tree2`, `F_Shrub02`, Shard ~80-100, `max_own` 3). Tier 2 khi đó tối đa 6×3 + 10×1 + 4 = 32 ≥ 30, m4 tới được ở tier 2, chỉ tốn Shard, không Stone. Nhờ economy-designer xem m5-m8 có bị kéo theo không.

**C2. Câu 3 (Gallery tier 5→2) làm tier 5 rỗng và trùng Profile.**
Gallery là thứ duy nhất có tên mà tier 5 cho (`ADDS[5] = "Gallery"`, `houses.json:53-58`). Kéo xuống tier 2 thì bước đắt thứ hai (500k Stone) chỉ còn đổi biome + 1 cây Genesis. Đây đúng là "tier sau mất giá trị". Thêm nữa, "phòng chiến tích" (danh hiệu, khung, thống kê run) phần lớn đã có ở Profile (`ProfileView.gd:3-10`: Overview stats, Cosmetics, Titles).
Đề xuất: không làm Gallery trong beta. Nếu cần chỗ khoe mốc Land thì thêm một mục "Land" vào Profile (mốc đã nhận, điểm thẩm mỹ, tier). Gallery giữ tier 5 cho bản sau, dành cho thứ thật sự mới (Land người khác ghé xem). Câu 3 cho Liam bỏ đi hoặc thay (xem mục 6).

**C3. Ngân sách web chưa có cơ sở đo, và có một khẳng định ngược với spike.**
0,22 ms/Axie đo trên M3 Pro với renderer **Mobile**, và ghi chú spike nói nút thắt "không phải animation/bóng/outline" (`archive/active-2026-10-12-before-rewrite.md:84-85`). Doc lại viết "bóng thật là phần tốn nhất trên Compatibility" (dòng 102), không có số. Hệ số ~10 lần là của cả khung hình, đem nhân cho từng Axie rồi áp lên laptop iGPU (yếu hơn M3 Pro nhiều) là đánh giá thấp. Chi phí nền của cảnh (đất, nhà, prop) khi 0 Axie chưa ai biết.
Đề xuất: Land đang chạy trên axiedice.fun. Bước 0 phải là **đo bản web đang deploy** (nửa ngày): 0 vs 5 Axie (qua `Land.qa`), bóng bật/tắt, tier 1 vs 6, trên M-series và một laptop Windows iGPU, ghi trung vị + p95 khung hình. Chốt ngân sách từ số đó rồi mới viết `LandQuality`.

## 3. NÊN SỬA

- **N1. Nhiệm vụ: hai doc nói ngược nhau, gom thành một câu.** Land đề xuất cấp nhà điều khiển mesh và có UI chỉ rõ chi phí (dòng 127, 134); Nhiệm vụ khuyến nghị hoãn nâng nhà (`nhiem-vu-beta-brainstorm.md:43, 151`). Thêm nữa hai doc đánh giá Stone ngược nhau: Nhiệm vụ coi 30k Stone là "không ai với tới" vì chỉ tính daily 500 + Nhiệm vụ 150/ngày (dòng 14), bỏ quên Echo Box là nguồn Stone chính; Land đúng theo §6.3 (30k ≈ 2 tuần casual). Đề xuất: doc Land ghi rõ "theo câu 1 của doc Nhiệm vụ; nếu hoãn thì giữ `fixed_lv: 1`, bỏ dòng 127 khỏi beta". Doc Nhiệm vụ sửa lý do (sink tranh với tier 2, chưa có UI), không dùng lý do "Stone quá ít". Liam chỉ trả lời một lần.
- **N2. Khung mốc đã kiểm: cả 5 món đều trùng.** `frame_u_vine`, `die_u_moss` nằm trong `pass_v2.json` (114, 278); `frame_r_snowglobe`, `die_e_spore`, `frame_l_sunburst` nằm trong `echobox.json` (172, 203, 238, 246). Vi phạm `land-v1-spec.md:94`. Đây là lỗi có sẵn, nhưng beta phải xử lý: hoặc rút khỏi pool, hoặc đổi thưởng mốc. Đưa vào gói beta, không để "kiểm khi plan".
- **N3. "Đội preset đang chọn" không tồn tại.** Không có preset nào được lưu là đang dùng; `RaidScreen.current_party()` chỉ có `team_index` tạm (dòng 64-73). Đề xuất nguồn: đội phòng thủ raid đã lưu (hợp nghĩa nhất: Axie canh Land của mình), không có thì preset 0, không có nữa thì Axie ngẫu nhiên. Starter free được lặp ghế (`team_presets.gd:54`), nên phải bỏ trùng, nếu không sẽ có 5 con giống hệt đi lại.
- **N4. Cắt phần thực chất là polish khỏi gói beta.** Liam muốn beta rồi QA, polish làm sau.
  - Giữ cho beta: đo web + cờ nhẹ (số Axie, bóng, prop); sau khi nâng tự về Land + một banner liệt kê thứ vừa mở (bản rẻ của B2); chip tiến độ trên HUD; Axie của mình; món khởi đầu; 2 Rare tier 2 (C1); xử lý N2.
  - Để polish: camera lùi/nhoáng/tween của lễ nâng; landmark + FX; chỉnh màu Savannah/Genesis (cần art-director, Claude Design); khung Land riêng.
  - Bỏ khỏi beta: Gallery (C2); tuỳ chọn Auto/Light/Full trong Settings (QA ép bằng cờ là đủ, đỡ thêm field save); trần vẽ decor 20 trên web (tier 1-3 trần chỉ 10/16/24, beta không bao giờ chạm, còn ẩn món người chơi đã đặt thì gây khó hiểu).
- **N5. Thiếu tiêu chí QA cho từng mục.** Liam muốn QA kỹ và "nội dung mới phải thấy được khi chơi". Mỗi mục cần một test hoặc bước QA: nâng tier xong tự về Land ở tier mới; Axie của mình có fallback (không preset, Axie Vault/NFT, starter trùng); `t_land_light` như doc ghi; món khởi đầu chỉ tặng một lần kể cả sau cloud save; m4 tới được ở tier 2. Kèm một lượt chơi thật trên bản deploy web.
- **N6. Cách đo web thiếu ba thứ.** Thời gian tới khung hình đầu của Land (đây là màn chính, gói web ~190 MB theo `phase-plan-v1.md:522`); bộ nhớ tab (máy RAM thấp có thể crash); Safari. Kiểm `get_rendering_info` có trả VRAM trên WebGL không trước khi dựa vào nó.

## 4. GỢI Ý

- `ADDS` trong `LandUpgradeScreen.gd` nên ghi đủ: trần decor, nhà lv, decor mới. Rẻ, và chính là "bảng tier tới cho gì".
- Dòng 135 nói gắn nhà Nhiệm vụ vào tier Land "phá luật không sức mạnh". Lý do đúng hơn là kinh tế: nhà mở bậc trả nhiều Shard/Stone hơn thì Stone quay lại sinh Stone. Nên viết đúng lý do.
- `daily.json` có `guest_stone_wait_days: 7` (A9) nhưng chưa code nào đọc. Nếu bật, khách beta không có Stone tuần đầu và bảng thời gian ở mục 1 lệch thêm. Hỏi economy-designer trạng thái.
- 5 Axie ngẫu nhiên hiện dùng `_rng.seed = 7` chung với prop. Đổi sang Axie của mình thì tách rng, nếu không vị trí prop sẽ đổi theo số lần gọi rng.

## 5. Mâu thuẫn với brainstorm Nhiệm vụ

Xem N1. Tóm lại: không mâu thuẫn về hướng nếu Liam chọn hoãn (Land không phải làm gì). Mâu thuẫn thật là cách hai doc đọc nguồn Stone. Doc Land đọc đúng `economy-v2`.

## 6. Ba câu hỏi cho Liam

- Câu 1 (gói beta): giữ, nhưng trình gói đã cắt theo N4.
- Câu 2: giữ nhưng viết lại theo C1: "Hạ tier 2 còn 20k (đổi số anh chốt 10/10) để người test thấy lần nâng đầu trong 1-2 tuần?" và nói rõ nó không sửa vùng chết. Vùng chết xử lý bằng 2 Rare tier 2 thì không cần hỏi (chỉ Shard, đúng luật đã chốt), chỉ báo.
- Câu 3 (Gallery): bỏ. Thay bằng câu đang thiếu và ảnh hưởng tới cả gói: **beta chạy chủ yếu trên web hay desktop, và có xoá tiến độ sau beta không?** Nếu chủ yếu web, đo + chế độ nhẹ là việc số 0 thật. Nếu có xoá tiến độ, câu 2 nhẹ đi nhiều.
- Câu nâng nhà Nhiệm vụ: không hỏi ở đây, theo câu 1 của doc Nhiệm vụ (N1).

## Vòng 2 (26/10): kiểm bản đã sửa

**Verdict: APPROVE** (gửi Liam được). Còn 2 việc NÊN SỬA cho bước plan, không chặn câu hỏi.

CHẶN đã đóng:
- C1: đóng. Công thức ở dòng 54 khớp đúng `land_decor.gd:178-193` (`sum(điểm_độ_hiếm x min(số_bản, 3)) + 2 x số_biome`). Bản rút gọn "1 x số món + 2 x số biome" ở dòng 6 chỉ đúng cho common ≤3 bản mỗi loại, mà đó đúng là ngữ cảnh. Tier 2 tối đa 32 đúng: 2 loại Rare x 3 bản = 18, 10 common = 10, 2 biome = 4, tổng 16 món = trần. Giá tier 2 thành phương án phụ, ghi đúng là mở lại số Liam chốt và không sửa vùng chết.
- C2: đóng. Gallery giữ tier 5, mốc khoe ở Profile.
- C3: đóng. Đo bản deploy là bước 0, bỏ ngoại suy, bóng chỉ là ứng viên, có khung hình đầu + bộ nhớ tab + Safari.
- NÊN SỬA N1-N6 và gợi ý đều xử lý hợp lý. Ba câu hỏi giờ đúng câu.

Lỗi mới / việc cho plan:
- **NÊN SỬA 1: 2 Rare tier 2 đẩy cả thang mốc sớm lên một tier, không chỉ m4.** Vòng 1 tôi ghi "chỉ báo, không cần hỏi". Tính lại thì chưa đủ. Tối đa theo tier, trước → sau khi thêm 2 Rare (Rare tính 3 bản mỗi loại, thêm common cho đủ trần): tier 3 42 → 54 (m6 = 55 chỉ thiếu 1), tier 4 64 → 76 (m7 = 70 từ tier 5 về tier 4), tier 5 82 → 94 (m8 = 90 từ tier 6 về tier 5, mà m8 là mốc kết + trophy). Bớt Rare (1 loại, hoặc `max_own` 2 + hạ m4) vẫn kéo m7 về tier 4 (70-72), nên thực chất chỉ còn hai đường. Đề xuất: economy-designer chọn trước khi plan: chấp nhận thang dời sớm, hoặc nâng m6-m8 (ví dụ 60/80/100) để m7/m8 về lại tier 5/6. Vẫn chỉ Shard nên không cần hỏi Liam, nhưng phải ghi số mốc mới vào doc.
- **NÊN SỬA 2: hai field save mới chưa được ghi.** Banner "chỉ hiện một lần" theo thay đổi `land_tier` cần lưu tier đã thấy; món khởi đầu "tặng một lần kể cả sau cloud save" cần cờ đã tặng. Cả hai phải đi qua `SaveStore` và sửa `MetaState.reload_from_store()` (luật CLAUDE.md). Thêm vào cột QA mục 1 và 3.
- GỢI Ý: mục "Land" trong Profile là UI chưa có trong spec UI-03 (`godot/CLAUDE.md`: không tự bịa UI). Beta làm bản tối thiểu bằng component `UI3` sẵn có, ghi rõ để Claude Design làm lại ở polish.
- `t_decor_data` có thật (`godot/tests/t_decor_data.gd`), tham chiếu QA đúng.
