# Land bản beta: brainstorm

> **Liam duyệt 26/10 (trả lời từng câu):** (1) nâng nhà Nhiệm vụ: HOÃN, nhà giữ cấp 1, mở bậc bằng chuỗi thắng. (2) KHOÁ SỐ theo sim bot luôn, KHÔNG chờ Liam chơi ~30 run hiệu chuẩn. (3) BẬT cược Shard (cả các bậc, không chờ server kiểm hết; việc Worker kiểm rules/mở bậc vẫn làm nhưng không chặn bật). (4) GIỮ "heavy không lãi N1-N4"; N6 bậc danh hiệu. (5) Gói beta Land: CÓ. (6) Beta chạy CHỦ YẾU DESKTOP; SẼ XOÁ TIẾN ĐỘ sau beta (→ được hạ tier 2 xuống 20k; web nhẹ ưu tiên thấp hơn). (7) Reroll: PB (xúc xắc bay ngay, kết quả về lúc lăn) sau khi đo RTT thật từ VN; RTT quá cao thì PA (gửi trước cả lượt). (8) Số dư Shard/Stone/unlock: RESET (M1). (9) KHÔNG trần payout theo ngày (Liam chấp nhận rủi ro mint giữa B1-B3; chỉ còn kiểm tối thiểu ở run_close). (10) Khách: chỉ tutorial + run thường, không ranked/Nhiệm vụ, đăng ký chỉ mang lịch sử run.

## Số chốt LD-D (26/10)

Economy-designer, làn LD-D trong `production/beta-plan.md`. Chưa code, chưa sửa JSON; LD-B sửa data theo bảng dưới. Số tính tay từ công thức `land_decor.gd:178-193` + `decor.json` + `economy-v2.md` §6.3, chưa chạy sim (không cần sim: Land không có yếu tố ngẫu nhiên). Cần systems-designer review.

### 1. Giá tier

| Tier | Biome | Giá cũ (bước) | **Giá mới (bước)** | Tổng cộng dồn mới |
|---|---|---|---|---|
| 1 | Savannah | 0 | 0 | 0 |
| 2 | Forest | 40.000 | **20.000** | 20.000 |
| 3 | Arctic | 100.000 | 100.000 | 120.000 |
| 4 | Mystic | 180.000 | 180.000 | 300.000 |
| 5 | Genesis | 500.000 | 500.000 | 800.000 |
| 6 | Luna | 1.000.000 | 1.000.000 | 1.800.000 |

Tier 3-6 giữ nguyên. Lý do: (1) Liam chỉ chốt tier 2, các số còn lại là thang dài hạn và beta xoá tiến độ nên không ai dùng tới tier 4+; (2) giữ nguyên thì đường ~1 năm của heavy chỉ nhẹ đi 20k/1.82M = 1,1% (52,3 -> ~51,7 tuần), không phải sim lại; (3) tier 3 (cộng dồn 120k) vẫn là mục tiêu thật cho tester chơi đều, không bị mở trong tuần đầu. Hệ quả cần biết: bước tier 2 -> 3 từ gấp 2,5 thành gấp 5, đúng vùng chết đã ghi ở mục 1, nhưng 2 Rare tier 2 lo phần điểm (mục 2 dưới).

Phương án tôi không chọn: hạ tier 3 xuống 60k (cộng dồn 80k) để tester regular thấy tier 3 trong ~5 tuần. Chỉ nên làm nếu Liam cho beta > 6 tuần; còn không thì tier 3 vẫn chỉ heavy chạm. Báo Liam nếu muốn.

**Thời gian tới tier** (Stone/tuần §6.3: casual 12.398-14.462, regular 15.737-17.826, heavy 33.798-35.968; lấy dải theo hành vi mùa không/nửa/đủ):

| | Tier 2 (20k) | Tier 3 (120k) |
|---|---|---|
| Casual | 1,4-1,6 tuần (~10-11 ngày) | 8,3-9,7 tuần |
| Regular | 1,1-1,3 tuần (~8-9 ngày) | 6,7-7,6 tuần |
| Heavy | 0,56-0,59 tuần (~4 ngày) | 3,3-3,6 tuần (~23-25 ngày) |

Số trung bình cả hành trình; tuần đầu thực tế thấp hơn một chút (tái chế vé tăng dần), cộng thêm vài ngày. Với beta vài tuần: mọi người thấy tier 2 trong tuần 1-2; tier 3 chỉ heavy (và regular nếu beta >= 7 tuần). Nên beta được đánh giá trên tier 1-2, đúng giả định cũ, chỉ nhanh hơn.

### 2. Điểm tối đa theo tier và thang mốc

Tính theo công thức: điểm = sum(điểm_hiếm x min(số bản, 3)) + 2 x số biome; số món đặt <= `tier_caps` (10/16/24/32/42/54); mỗi id chỉ tính tối đa 3 bản và bị chặn bởi `max_own` (E của Luna `max_own` 2). Bộ mới = 7 common cũ + 8 common mới (đều Savannah/Forest nên không thêm biome) + 2 Rare `min_tier 2` (mỗi id Rare 3 điểm x 3 bản).

| Tier | Cap | Điểm tối đa CŨ | Điểm tối đa MỚI | Cách ra số mới |
|---|---|---|---|---|
| 1 | 10 | 14 | 14 | 10 common + 2 biome x2 |
| 2 | 16 | 20 | **32** | 6 Rare (18) + 10 common (10) + 4 |
| 3 | 24 | 42 | **54** | 12 Rare (36: 2+2 id) + 12 common + 6 (3 biome) |
| 4 | 32 | 64 | **76** | 18 Rare (54) + 14 common + 8 |
| 5 | 42 | 76 | **94** | 21 Rare (63) + 21 common + 10 |
| 6 | 54 | 143 | **163** (155 chưa có Trophy) | 24 Rare (72) + 6 E x2 bản (48) + Trophy (8) + 23 common + 12 |

Ghi chú: bảng cũ trong mục "Việc cho bước plan" ghi tier 5 cũ là 82; tính lại theo công thức ra 76. Số MỚI 54/76/94 khớp với doc cũ, nên kết luận không đổi. Chênh lệch tier 6 (143 -> 163) chủ yếu do 2 Rare mới và 2 slot common thêm vì có nhiều id common hơn.

Mốc cũ 5/12/20/30/42/55/70/90, mỗi mốc tới được ở tier nào:

| Mốc | Điểm cũ | Tier tới được (cũ) | (a) giữ nguyên số | (b) nâng m6-m8 = 60/80/100 |
|---|---|---|---|---|
| m1 | 5 | 1 | 1 | 1 |
| m2 | 12 | 1 | 1 | 1 |
| m3 | 20 | 2 | 2 | 2 |
| m4 | 30 | 3 | **2** (32) | **2** (32) |
| m5 | 42 | 3 | 3 (54) | 3 (54) |
| m6 | 55 | 4 | **4** (T3 max 54, thiếu 1) | 4 (T3 54 < 60 <= T4 76) |
| m7 | 70 | 5 | **4** (76) | 5 (T4 76 < 80 <= T5 94) |
| m8 | 90 | 6 | **5** (94) | 6 (T5 94 < 100 <= T6 155) |

Chọn **(b)**: m6 = 60, m7 = 80, m8 = 100; m1-m5 giữ nguyên. Lý do:
- (a) dồn m6 + m7 vào tier 4 và m8 vào tier 5, tier 6 (bước 1.000.000 Stone, lớn nhất cả thang) không còn mốc nào để đuổi. Tiến triển dài hạn phẳng đúng chỗ đắt nhất. Ngoài ra m6 chỉ hơn trần tier 3 có 1 điểm, tester dễ hiểu nhầm là "lỡ một chút".
- (b) giữ nguyên ánh xạ gốc: m4 T2, m5 T3, m6 T4, m7 T5, m8 T6, mỗi tier mở đúng một mốc mới (trừ T1 hai mốc dễ). Tỷ lệ mốc/trần: m4 30/32 (94%), m5 42/54 (78%), m6 60/76 (79%), m7 80/94 (85%), m8 100/155 (65%): mỗi mốc cần lấp phần lớn ô của tier, không rỗng.
- Tier 2 là chỗ tester thật sự ở (mục 1): m4 30 vs trần 32 là sát nhưng đạt được (chỉ cần đủ 2 Rare x3 + 10 common mỗi loại 1 bản + cả 2 biome), chi phí Shard chỉ ~800 (xem dưới), nên m4 là "mục tiêu tier 2" rõ ràng chứ không bị khoá bằng Shard.

**Mốc mới (LD-B ghi vào `decor.json`):**

| id | Điểm | Đổi? | Phần thưởng (giữ nguyên, LD-R lo trùng pool) |
|---|---|---|---|
| m1 | 5 | không | title:Gardener |
| m2 | 12 | không | frame_u_vine |
| m3 | 20 | không | die_u_moss |
| m4 | 30 | không | title:Landscaper |
| m5 | 42 | không | frame_r_snowglobe |
| m6 | **60** | 55 -> 60 | die_e_spore |
| m7 | **80** | 70 -> 80 | title:Land Architect |
| m8 | **100** | 90 -> 100 | frame_l_sunburst + decor_trophy |

Việc theo sau (LD-B / I): `t_decor_milestones.gd:30` (`"m8 needs 90"` -> 100, sửa cả thông báo), kiểm `t_decor_score` còn xanh với dữ liệu mới. Nhớ: Trophy (E, 8 điểm, thưởng từ m8) nằm trong số 163 của tier 6, nên m8 = 100 nhận được trước khi có Trophy (155 >= 100).

Shard để đạt trần tier 2 (32 điểm): 3 x 80 + 3 x 90 (Rare) = 510; 10 common mỗi id 1 bản, 10 id rẻ nhất ~25 trung bình = ~250; tổng ~760-820 Shard, tức ~3-4 vé (vé TB 220-278 Shard, §2). Rẻ so với thu nhập Shard (6.4k-26k/tuần), nên **mốc Land bị chặn bởi Stone (tier), không bởi Shard**; không phá cân bằng Shard/vé của economy-v2.

### 3. Decor mới

Nguồn scene: `asset-library/godot-ready/scenes/HomeLand_Asset/...` (đã liệt kê bằng glob, đều có thật). Cột "Có sẵn" = đã có bản trong `godot/assets/land/homeland/scenes/HomeLand_Asset/` (đang load được, `Land.gd` BIOMES dùng); "Chép" = chưa có, LD-B chép cả thư mục dependencies cần thiết. `scene` trong json bỏ tiền tố `HomeLand_Asset/`, giống bản cũ. `footprint_r` và `scale` là số tạm lấy theo món cùng loại, LD-B chỉnh khi nhìn trong Land (không phải số kinh tế).

8 common (`rarity C`, `min_tier 1`, 1 điểm, `craftable true`):

| id | Tên | Biome | Giá Shard | max_own | Scene nguồn | Có sẵn | footprint / scale tạm |
|---|---|---|---|---|---|---|---|
| decor_sav_tree2 | Savannah Tree B | savannah | 40 | 6 | Environment/Savannah/Tree/S_Tree02_Allside | Có sẵn | như decor_sav_tree (0.85 / 0.4678) |
| decor_sav_tree3 | Savannah Tree C | savannah | 40 | 6 | Environment/Savannah/Tree/S_Tree03_Allside | Có sẵn | như decor_sav_tree |
| decor_sav_shrub2 | Dry Shrub | savannah | 20 | 8 | Environment/Savannah/Shrub/S_Shrub02_Allside | Có sẵn | như decor_sav_shrub (0.7 / 0.339) |
| decor_sav_shrub3 | Round Shrub | savannah | 20 | 8 | Environment/Savannah/Shrub/S_Shrub03_Allside | Chép | như decor_sav_shrub |
| decor_sav_rock2 | Savannah Rock B | savannah | 25 | 6 | Environment/Savannah/Rock/SavannahRock_02 | Có sẵn | như decor_sav_rock (0.75 / 0.5357) |
| decor_for_shrub1 | Forest Bush | forest | 20 | 8 | Environment/Forest/Shrub/F_Shrub01_Allside | Có sẵn | 0.7 / 0.6 (xem lại) |
| decor_for_shrub2 | Fern Bush | forest | 20 | 8 | Environment/Forest/Shrub/F_Shrub02_Allside | Có sẵn | 0.7 / 0.6 (xem lại) |
| decor_for_plant | Forest Plant | forest | 25 | 8 | Environment/Forest/Decoration/Plant01/F_Plant01 | Chép | 0.5 / 1.0 (xem lại) |

2 Rare (`rarity R`, **`min_tier 2`**, 3 điểm, `craftable true`, `max_own 4`):

| id | Tên | Biome | Giá Shard | Scene nguồn | Có sẵn | footprint / scale tạm |
|---|---|---|---|---|---|---|
| decor_for_tree2 | Elder Forest Tree | forest | 80 | Environment/Forest/Tree/F_Tree2_AllSide | Có sẵn | 0.65 / 0.5728 (như decor_for_tree) |
| decor_sav_tree3a | Grand Savannah Tree | savannah | 90 | Environment/Savannah/Tree/S_Tree03a_Allside | Có sẵn | 0.85 / 0.4678 (như decor_sav_tree) |

Lý do giá Rare 80/90: nằm giữa common cao nhất (40) và Rare Arctic tier 3 (90/100), giữ thứ tự giá theo tier. Chỉ Shard, không Stone, không sức mạnh combat.

Rủi ro art để technical-artist kiểm: `S_Tree03` (common) và `S_Tree03a` (Rare) có thể nhìn gần giống nhau, vì Rare phải "trông hiếm hơn". Nếu giống thì đổi common `decor_sav_tree3` sang món khác (ví dụ `S_Shrub01` biến thể) hoặc Rare sang `Environment/Forest/Quarry/F_Quarry_01` (cần chép). Không đổi số điểm.

Tổng sau khi thêm: 27 entry (16 craftable cũ + 8 + 2 + Trophy). `t_decor_data.gd:7` đang kiểm `defs.size() != 17`, đổi thành 27 và sửa thông báo.

**Món khởi đầu (90 Shard giá trị):** `MetaState.grant_land_gift_once(decor_id)` (`MetaState.gd:331`) hiện cấp **đúng 1 bản của 1 id** rồi đặt `land_gift_granted`, nên không cho ra 3 món/90 Shard được. Hai cách:
- **Khuyến nghị:** I đổi hàm nhận `Array` id (cấp mỗi id 1 bản, một cờ), vì thay đổi nhỏ và cùng một chủ file. Bộ quà: `decor_sav_tree2` (40) + `decor_sav_rock2` (25) + `decor_for_plant` (25) = **90 Shard** đúng số Liam chốt. Cả 3 `min_tier 1`, common 1 điểm, thấy ngay ở Land tier 1. Điểm: quà này cho 3 điểm + biome, tức tặng m1 nửa đường; chấp nhận được, m1 (5) là mốc dễ.
- Nếu không đổi hàm: cấp 1 món, `decor_sav_tree2` (40 Shard, giá trị thật là 40 chứ không phải 90). Vẫn hợp lệ nhưng nên báo Liam số 90 không còn đúng.
Quà là decor (không phải Shard/Stone), nên không thêm tiền tệ mới, hợp với quy tắc "không thêm nguồn".

### 4. Kiểm INV-1..7 (`build-spec.md`) và nguồn Stone

- INV-1..5 (part, tier part, mutation, ngân sách part): không đụng. Land không có field part/power.
- INV-6 (tiền thật không ra sức mạnh): decor/tier chỉ cho thẩm mỹ, mốc ra title/cosmetic; không SKU mới. Giữ nguyên.
- INV-7 (run thường không bị gate): không đụng; Stone/Shard chỉ dùng cho Land.
- Không thêm nguồn Stone: chỉ giảm giá một sink (tier 2). Tốc độ Stone/tuần theo §6.3 không đổi. Nhà Nhiệm vụ hoãn nâng nên không có sink 46k tranh với tier 2 trong beta.
- Quà khởi đầu là decor một lần, không phải faucet lặp; Rare chỉ mua bằng Shard.

**Việc đổi theo cho làn LD-B / I (không phải tôi sửa):**
1. `godot/assets/data/economy/land_tiers.json`: tier 2 `cost_stone` 40000 -> 20000; sửa `_source` (tổng 1.800.000).
2. **`godot/scripts/meta/economy_db.gd:208-209`** kiểm `total != 1820000` -> phải đổi 1.800.000, nếu không economy_db báo lỗi. File này nằm trong fingerprint (`scripts/meta/`): ghim lại FINGERPRINT, "Run result: NO", không bump.
3. `godot/tests/t_land_upgrade.gd`: dòng 51 (`land_tier_cost(1) == 40000` -> 20000, kiểm cả chỗ tier 1/2), dòng 65-69 (`stone = 40000`, `-40000` -> 20000), dòng 85 (`stone = 1820000` -> 1800000, kiểm ngữ cảnh). Grep thêm `40000` / `140000` trong `godot/` trước khi merge (còn chỗ nào trích số cũ).
4. `decor.json`: 10 entry mới + m6/m7/m8 = 60/80/100; test `t_decor_data` (17 -> 27), `t_decor_milestones` (m8 100), và nên thêm assert "aesthetic tier 2 đạt 32, tier 3 đạt 54" (theo bảng trên) vào `t_decor_score` hoặc `t_land_milestones`.
5. LD-A khi sửa `ADDS` (`LandUpgradeScreen`): ghi tier 2 = trần 16 món + 2 Rare mới mở.

---

Ngày 26/10/2026. Game-designer. Chỉ brainstorm, chưa plan, chưa code, chưa sửa GDD. Số trong doc là số thô từ `economy-v2.md`, `decor.json`, `land_decor.gd`, chưa sim lại.

**Đã sửa theo review 26/10** (`land-beta-brainstorm-review.md`, APPROVE WITH CHANGES):
- Bỏ câu sai "+8 decor common nới được m3". Điểm = 1 x số món + 2 x số biome, nên thêm common chỉ thêm lựa chọn. Vùng chết m3 → m4 xử lý bằng 2 decor Rare `min_tier 2`.
- Bỏ chữ "lỗi" cho chuyện nâng tier (Back đã dựng lại Land tier mới) và bỏ "thiếu thanh tiến độ" (màn nâng cấp đã có). Còn thiếu là khoảnh khắc và lối vào từ HUD Land.
- Hạ giá tier 2 thành phương án phụ, ghi rõ nó mở lại số Liam xác nhận 10/10 và không sửa vùng chết.
- Gallery bỏ khỏi beta, mốc Land khoe ở Profile.
- Web nhẹ: bước 0 là đo bản web đang deploy, ngân sách chỉ chốt sau đo; bỏ trần decor 20; sửa nhận định về bóng.
- Thêm vào gói beta: 5 thưởng mốc Land đang trùng pool Echo Box/Pass.
- "Đội preset đang chọn" không tồn tại, đổi nguồn Axie đi lại.
- Polish tách ra (lễ camera, landmark, FX, chỉnh màu), bỏ Settings Auto/Light/Full. Mỗi mục gói beta có tiêu chí QA.
- Câu hỏi Liam: bỏ câu Gallery, thêm câu "web hay desktop, có xoá tiến độ không". Nhà Nhiệm vụ gom thành một câu chung với doc Nhiệm vụ.

Đã đọc: `land-meta-loop-brainstorm.md` (Liam trả lời 20/10), `land-v1-spec.md`, `phase-plan-v1.md` GĐ9, `Land.gd`, `LandUpgradeScreen.gd`, `LandNav.gd`, `land_decor.gd`, `decor.json`, `land_tiers.json`, `team_presets.gd`, `economy-v2.md` §6, `nhiem-vu-risk-to-earn.md` §3.3, review. Không chạy Godot.

Ràng buộc Liam đã chốt, giữ nguyên: Land không cho sức mạnh combat, là tài sản free, màn chính là Land 3D sống và các nhà là lối vào. Web chạy bản nhẹ, desktop đầy đủ. Windows + macOS trước, web song song. Combat đã đủ sâu cho beta, Land là chiều rộng, niềm tự hào, cảm giác tiến triển. Không thêm nguồn Stone.

## 1. Hiện trạng và vấn đề lớn nhất

Đã có:
- 6 biome theo tier (trời, đất, vách, cây, decor NFT), nhà lv1-4 theo tier.
- Land v1: Sửa Land thả tự do, 16 decor chế bằng Shard (cộng 1 trophy chỉ từ mốc), điểm thẩm mỹ + 8 mốc, raid ghost.
- Màn nâng cấp (`LandUpgradeScreen`) đã có thanh tiến độ "X / Y Land Stone for Forest" và cột ADDS (dòng 12-18). Bấm Back gọi `LandNav.back_to_land()`, Land dựng lại ở tier mới.
- 5 Axie đi lại (`WANDERERS = 5`), nhưng là Axie ngẫu nhiên (`_spawn_axie`), không liên quan người chơi.

Còn thiếu:
- Nâng tier xong chỉ có toast, rồi người chơi phải tự bấm Back mới thấy cảnh đổi. Không phải lỗi, nhưng là khoảnh khắc đắt nhất của meta mà không có gì đặc biệt.
- ADDS thiếu trần decor và nhà lv mới. Land HUD không có lối vào tiến độ: muốn biết tới đâu phải mở màn nâng cấp.
- Chưa biết Land web đang chạy thế nào (chưa ai đo, xem mục 3).
- Stone và `land_tier` chỉ ở client. Số dư phía server thuộc hệ "Server RNG/kinh tế server" làm sau, chỉ ghi phụ thuộc.
- Gallery = "Coming soon" (không làm trong beta, xem mục 2).
- 5 thưởng mốc Land mượn cosmetic đang nằm trong pool Echo Box/Pass (mục 2, gói beta).

Ba câu hỏi người chơi:
1. Land có sống chưa? Nửa chừng: có Axie đi lại nhưng không phải của mình.
2. Nâng tier có đã không? Chưa: thiếu khoảnh khắc, nhưng đã có thanh tiến độ và dòng "thêm gì".
3. Có lý do quay lại Land không? Có vài thứ, nhưng có một vùng chết ở mốc thẩm mỹ, xem bên dưới.

### Phát hiện chính: beta chỉ thấy tier 1-2

Stone/tuần trung bình cả hành trình (`economy-v2.md` §6.3): casual ~12.400-14.500, regular ~15.700-17.800, heavy ~33.800-36.000. Tier 2 = 40.000, tier 3 cộng dồn = 140.000.

| | Tới tier 2 (40k) | Tới tier 3 (140k) |
|---|---|---|
| Casual | ~2,8-3,2 tuần | ~10 tuần |
| Regular | ~2,2-2,5 tuần | ~8 tuần |
| Heavy | ~1,1-1,2 tuần | ~4 tuần |

Tuần đầu thực tế thấp hơn trung bình một chút (tái chế vé tăng dần). Nên tuần đầu chỉ heavy thấy tier 2, và beta vài tuần gần như chỉ heavy chạm tier 3. Hệ quả:
- Beta được đánh giá trên tier 1-2. Đó là chỗ cần đẹp và nhiều thứ làm nhất.
- Gallery (tier 5, cộng dồn 820k) người beta không bao giờ thấy.
- Tier 1-2 chỉ có 7 decor chế được (5 Savannah + 2 Forest, đều common 1 điểm). Công thức (`land_decor.gd:178-193`): `điểm = sum(điểm_độ_hiếm x min(số_bản, 3)) + 2 x số_biome`. Trần tier 1 (10 món): 10 + 4 = 14. Trần tier 2 (16 món): 16 + 4 = 20. Thêm bao nhiêu loại common cũng vậy, vì trần là số món (16) chứ không phải số loại. Nên m2 (12) chạm được ở tier 1, m3 (20) vừa khít khi đầy 16 ô tier 2, **m4 (30) cần decor Rare = tier 3**: vùng chết ~6-8 tuần với casual/regular.
- Nhà Nhiệm vụ tiêu Stone (4k/12k/30k, tổng 46k, gần bằng tier 2) và Shard (3k/8k/20k, tranh với Shard chế decor).

**Cách bịt vùng chết (không tốn Stone):** thêm 2 decor **Rare** `min_tier: 2`, dùng asset đã có trong `BIOMES` (ví dụ `F_Tree2`, `F_Shrub02`), Shard ~80-100, `max_own` 3. Tier 2 khi đó tối đa 6 x 3 + 10 x 1 + 4 = **32 >= 30**, m4 tới được ở tier 2, chỉ tốn Shard. Cần economy-designer xem m5-m8 có bị kéo theo không. Đây là việc trong luật đã chốt (chỉ Shard, không sức mạnh) nên chỉ báo Liam, không hỏi.

## 2. Hướng cho beta

Công: S ~1-2 ngày, M ~3-5 ngày (thô). Mỗi hướng có phần "beta" và phần "polish". Polish làm sau QA.

### Hướng A: "Đây là Land của tôi" (Axie của mình đi lại)

Thay 5 Axie ngẫu nhiên bằng Axie của người chơi.
- **Nguồn đội**: "đội preset đang chọn" không tồn tại (`RaidScreen.current_party()` chỉ có `team_index` tạm). Thứ tự ưu tiên: (1) đội phòng thủ raid đã lưu (hợp nghĩa nhất: Axie canh Land của mình), (2) preset 0, (3) Axie ngẫu nhiên như hiện nay. Starter free được lặp ghế (`team_presets.gd:54`) nên **phải bỏ trùng**, nếu không có 5 con giống hệt nhau đi lại.
- Tách rng của Axie khỏi rng của prop (hiện chung `_rng.seed = 7`), không thì vị trí prop đổi theo số lần gọi rng.
- Được: "của mình" rẻ nhất có thể, dùng tài sản có sẵn. Mất: phải map key trong `party` sang `AxieDescriptor` (có Vault/NFT). Công S-M.
- Hiệu năng: desktop không tăng; web theo số đo ở mục 3. NFT load lần đầu có thể giật, spawn rải mỗi khung hình 1 con.

### Hướng B: "Nâng tier là một khoảnh khắc"

Phần beta (rẻ):
- Sau khi nâng thành công tự về Land (`back_to_land`) thay vì chờ bấm Back.
- Một **banner trên Land** ngay khi vào ở tier mới, liệt kê thứ vừa mở (nhà, decor, ô preset, trần decor).
- **Chip tiến độ trên HUD Land** ("Stone 12.4k / 40k → Forest"), bấm vào mở thẳng màn nâng cấp. Màn đó đã có thanh tiến độ nên đây chỉ là chip dẫn vào, công S.
- Sửa ADDS ghi đủ: trần decor, nhà lv mới, decor mới. Rẻ, và chính là bảng "tier tới cho gì".
- Lễ phải kích hoạt theo **thay đổi `land_tier`**, không theo nút bấm, để khi tier sang server thì không vỡ.
- Công S-M. Hiệu năng không đáng kể (một lần).

Để polish: lễ camera lùi, nhoáng trắng 0,3 s, tween đổi trời/đất, nhà trồi lên, banner tên biome có animation, âm báo (audio-director).

### Hướng C: "Tier 1-2 phải đáng nhìn"

Phần beta:
- +8 decor common cho tier 1-2 (data-only, asset trong `BIOMES` đã load được): thêm lựa chọn trang trí, **không** nới điểm tối đa (xem mục 1).
- 2 decor Rare `min_tier 2` để bịt vùng chết (mục 1).
- Món khởi đầu: tặng 3 decor common lần đầu vào Land (~90 Shard, không Stone), tặng một lần kể cả sau cloud save.
- **Sửa 5 thưởng mốc Land đang trùng pool Echo Box/Pass** (review đã kiểm: `frame_u_vine`, `die_u_moss` nằm trong `pass_v2.json`; `frame_r_snowglobe`, `die_e_spore`, `frame_l_sunburst` nằm trong `echobox.json`). Vi phạm `land-v1-spec.md:94`: người quay ra món đó trước thì mốc thành trùng, Echo Box mất món chỉ có từ mốc. Cần thưởng riêng, nối với đợt khung cosmetics mới (`design/handoffs/cosmetics-3d/`). Nếu cosmetics chưa kịp: rút 5 món khỏi pool trước beta (cần economy-designer xem lệch EV Echo Box). Quyết cách nào là việc của plan, nhưng không được để "kiểm khi plan" nữa.
- Mục "Land" trong Profile: mốc đã nhận, điểm thẩm mỹ, tier. Profile đã có Overview/Cosmetics/Titles, thêm một mục là đủ. Đây là chỗ khoe mốc Land, thay cho Gallery.
- **Không làm Gallery trong beta.** Gallery là thứ duy nhất có tên mà tier 5 cho (`ADDS[5]`), kéo xuống tier 2 thì bước 500k Stone chỉ còn đổi biome; "phòng chiến tích" lại phần lớn trùng Profile. Giữ tier 5 cho bản sau, cho thứ thật sự mới (đi thăm Land người khác).

Để polish: landmark mỗi tier, FX nền (bụi/đom đóm/tuyết), chỉnh màu Savannah/Genesis nhạt (cần art-director/Claude Design), khung Land riêng.

### Khuyến nghị gói beta (thứ tự)

0. **Đo web đang deploy** (mục 3). Cổng cho mọi thứ thêm sau. Nửa ngày.
1. B phần beta: về Land tự động + banner + chip HUD + sửa ADDS. S-M.
2. A: Axie của mình. S-M.
3. C phần beta: +8 common, 2 Rare tier 2, món khởi đầu, mục Land trong Profile. S-M.
4. Xử lý 5 thưởng mốc trùng pool (nối đợt cosmetics). S-M tuỳ cosmetics.
5. Cờ web nhẹ theo ngân sách chốt sau đo (mục 3).

Thiếu thời gian thì cắt từ cuối lên, trừ bước 0 và 4 (4 là lỗi kinh tế có sẵn).

Polish (sau QA beta): lễ camera/tween, landmark + FX, chỉnh màu, khung Land riêng. Bỏ khỏi beta: Gallery, Settings Auto/Light/Full (QA ép bằng cờ là đủ, đỡ thêm field save), trần vẽ decor trên web (trần tier 1-3 chỉ 10/16/24, beta không chạm, còn ẩn món người chơi đã đặt thì khó hiểu).

### Tiêu chí QA từng mục gói beta

| Mục | Kiểm |
|---|---|
| 0 Đo web | Có file `production/qa/` ghi số đo (trung vị, p95, khung hình đầu, bộ nhớ tab) kèm ngày build và máy. Có ngân sách chốt từ số đó. |
| 1 Nâng tier | Test: nâng xong tự về Land, `_tier` mới, `ADDS` có trần decor + nhà lv. Chip HUD hiện số Stone đúng, bấm vào mở màn nâng cấp. Banner chỉ hiện một lần: field save mới qua `SaveStore` + `reload_from_store()`, không lặp sau save/load và cloud save. Chơi thật trên bản deploy: nâng bằng save có đủ Stone, thấy banner. |
| 2 Axie của mình | Test fallback: không đội phòng thủ, không preset, preset có Vault/NFT, starter trùng ghế (không có 5 con giống nhau). Đổi đội phòng thủ thì Land đổi theo lần vào sau. rng prop không đổi theo số Axie. |
| 3 Decor/Profile | Test: `aesthetic()` ở tier 2 đạt 32 với 6 Rare + 10 common + 2 biome, m4 nhận được ở tier 2. Món khởi đầu chỉ tặng một lần kể cả sau cloud save (field save mới qua `SaveStore` + `reload_from_store()`). 8 decor common mới load được (`t_decor_data`). Profile hiện mục Land đúng mốc đã nhận. |
| 4 Thưởng mốc | Test: không thưởng mốc Land nào nằm trong `echobox.json` hay `pass_v2.json`. Mốc nhận được và hiện trong kho. |
| 5 Web nhẹ | `t_land_light` headless: ép cờ, kiểm số Axie, đèn không shadow, prop giảm. GPU thật chỉ đo tay. Một lượt chơi Land thật trên web đã deploy. |

Mọi mục nội dung mới phải **thấy được trong lúc chơi bình thường** (Liam từng không thấy relic rework): banner, chip, Axie, decor Rare đều phải xuất hiện ở tier 1-2 mà không cần mở cờ debug.

## 3. Chế độ web nhẹ

Land web đang chạy thật trên axiedice.fun, nên **không ngoại suy**, đo trước rồi mới chốt ngân sách.

Điều đã biết và điều chưa biết: 0,22 ms/Axie đo trên M3 Pro với renderer Mobile, và ghi chú spike (session-state cũ 12/10) nói nút thắt không phải animation/bóng/outline. Hệ số ~10 lần của Compatibility là của cả khung hình, không phải riêng từng Axie, và laptop iGPU yếu hơn M3 Pro nhiều. Chi phí nền khi 0 Axie (đất, nhà, prop) chưa ai biết. Vì vậy doc trước viết "bóng thật tốn nhất" là không có căn cứ; bóng chỉ là **một ứng viên** để thử tắt, đo xem có đáng không.

**Bước 0: đo bản web đã deploy (nửa ngày).**
- Biến: 0 vs 5 Axie (qua `Land.qa`), bóng bật/tắt, tier 1 vs 6.
- Máy: M-series + một laptop Windows iGPU (+ Safari nếu có).
- Ghi: trung vị và p95 thời gian khung hình, **thời gian tới khung hình đầu của Land** (đây là màn chính, gói web lớn), **bộ nhớ tab** (máy RAM thấp có thể crash). Kiểm `RenderingServer.get_rendering_info` có trả VRAM trên WebGL không trước khi dựa vào.
- Ra: bảng số + ngân sách chốt từ số đó. Chỉ sau đó mới viết cờ nhẹ.

**Cờ nhẹ (sau đo):** `OS.has_feature("web")` ra cờ `light` qua một hàm duy nhất. Test ép cờ qua `Land.qa` như các cờ đã có. Không có Settings cho người chơi trong beta. Các núm có thể vặn, theo thứ tự thử khi số đo không đạt: tắt FX, giảm prop rìa, tắt bóng thật (bóng giả quad dưới Axie), giảm Axie từ 5 xuống 2-3, texture giới hạn cạnh. Không hạ độ phân giải trước các thứ trên. Không giới hạn số decor vẽ (xem mục 2). Chưa biết Compatibility có `scaling_3d` ở 4.7.2 không, cần đọc docs khi plan.

**Mục tiêu (khởi điểm, chốt sau đo):** web >= 30 FPS ở 1280x720 trên laptop iGPU, >= 45 trên M-series; khung hình đầu của Land nhanh nhất có thể (số cụ thể chốt sau đo); tab không vượt RAM mà máy yếu chịu được.

## 4. Nhịp tiến triển

Không thêm nguồn Stone. Số ở mục 1: tier 2 sau ~1-3 tuần, tier 3 sau 4-10 tuần, tuần đầu thường không thấy tier 2.

Đòn trong tầm Land beta, không đụng kinh tế:
1. **Chip tiến độ trên HUD** (mục 2 B): người chơi thấy mình đang tới đâu mà không phải mở màn nâng cấp.
2. **Mốc thẩm mỹ bằng Shard**: m1 (5 điểm) trong ngày 1, m2 (12 điểm) trong vài ngày, m3 (20) khi đầy tier 2, m4 (30) nhờ 2 Rare tier 2. Đây là nhịp thật của tuần 1-6.
3. **Decor mới** cho tier 1-2 để có thứ chọn.

**Phương án phụ: hạ giá tier 2 từ 40k xuống 20k.** Không phải khuyến nghị chính. Cần biết:
- 40.000 là con số Liam tự xác nhận ngày 10/10 ("Con số hiển thị phải TO", `economy-v2.md:35-36`), nên đây là **mở lại một quyết định của Liam**, không phải chi phí gần bằng không.
- Lý do thật để hạ: người test beta (vài tuần) có thấy lần nâng đầu tiên hay không. Casual tới tier 2 ~1,4-1,6 tuần (20.000/14.462 tới 20.000/12.398), regular ~1,1-1,3, heavy ~4-6 ngày.
- Nó **không sửa vùng chết** m3 → tier 3 (tier 3 vẫn cách thêm 100k, vùng chết casual còn dài thêm chút). Bước tier 2 → 3 thành gấp 5 thay vì 2,5. Tổng hành trình nhẹ đi 20.000/1.820.000 = 1,1%, không phá đường ~1 năm của heavy (52,3 tuần thành ~51,7).
- Không phá INV-1..7. economy-designer sim lại trước khi sửa `land_tiers.json`.
- Doc kinh tế đang lệch nhau về thời gian tới Luna (§6.4 casual 2,6 năm / regular 2,1 năm so với khối Liam chốt 10/10 ghi 1,9/1,5), nên không trích "1-2 năm" làm căn cứ.
- Nếu Liam chọn một beta ngắn và xoá tiến độ sau đó (câu hỏi 2), phương án này nhẹ đi nhiều vì không phải sửa thang lâu dài.

Hỏi economy-designer thêm: `daily.json` có `guest_stone_wait_days: 7` (A9) nhưng chưa code nào đọc. Nếu bật, khách beta không có Stone tuần đầu và bảng thời gian lệch thêm.

## 5. Liên kết

### Nhiệm vụ (chung một câu với doc Nhiệm vụ)
- Nhà Nhiệm vụ hiện là Weaponsmith `fixed_lv: 1` (`Land.gd:45`); mesh lv1-4 đã có. Land từng đề xuất để cấp nhà điều khiển mesh; doc Nhiệm vụ khuyến nghị **hoãn** nâng nhà trong beta (`nhiem-vu-beta-brainstorm.md:43, 151`). **Nếu hoãn thì giữ `fixed_lv: 1` và không làm gì ở Land.** Nếu không hoãn thì cấp nhà điều khiển mesh, và UI phải chỉ rõ chi phí Stone/Shard để không đua tier 2 trong im lặng.
- Hai doc đang đọc nguồn Stone ngược nhau: doc Nhiệm vụ coi 30k Stone là "không ai với tới" vì chỉ tính daily và Nhiệm vụ, bỏ quên Echo Box (nguồn chính). Doc này theo §6.3: 30k ~2 tuần của casual. Lý do hoãn đúng hơn là "sink tranh với tier 2 và chưa có UI", không phải "Stone quá ít" (việc sửa thuộc doc Nhiệm vụ).
- Nhà Nhiệm vụ độc lập với tier Land. Lý do tách đúng nhất là kinh tế: nhà mở bậc trả nhiều Shard/Stone hơn thì Stone quay lại sinh Stone, và người chơi mất lựa chọn tiêu Stone.
- Phụ thuộc server: Stone/tier chỉ ở client. Banner và chip đọc từ `land_tier` và `MetaState.stone` để đổi nguồn sau không phải sửa lại. Không thiết kế giao thức ở đây.

### Cosmetics
Xem gói beta mục 4: thưởng mốc Land cần thưởng riêng, nối với đợt khung cosmetics mới. Profile là chỗ khoe mốc và khung.

## Việc cho bước plan

1. **2 decor Rare ở tier 2 dời cả thang mốc sớm một tier.** Điểm tối đa theo tier tăng, nên mốc tới sớm hơn: tier 3/4/5 từ 42 → 54, 64 → 76, 82 → 94; m7 về tier 4, m8 về tier 5. Hai đường: (a) chấp nhận dời sớm, (b) nâng m6-m8 (ví dụ 60/80/100). economy-designer chọn ở bước plan và ghi số mốc mới vào doc này. Không cần hỏi Liam.
2. **"Banner hiện một lần" và "món khởi đầu tặng một lần" cần field save mới.** Ghi qua `SaveStore` (không ghi file trực tiếp) và sửa `MetaState.reload_from_store()`. Phần QA mục 1 (nâng tier) và mục 3 (decor/Profile) phải kiểm thêm: field sống qua save/load và qua cloud save, banner/món khởi đầu không lặp lại sau đăng nhập máy khác.
3. **Mục "Land" trong Profile**: bản tối thiểu bằng component UI3 sẵn có (`UI3`/`UI3Meta`), không dựng component mới. Ghi lại để Claude Design làm lại ở polish.

## 6. Câu hỏi cho Liam (3 câu, chỉ hướng)

1. **Gói beta**: làm gói đã cắt ở mục 2 (đo web, nâng tier + chip HUD, Axie của mình, decor/Rare tier 2/món khởi đầu/mục Land ở Profile, sửa thưởng mốc, rồi cờ web nhẹ; polish để sau QA; không Gallery)? Khuyến nghị: **có**, cắt từ cuối lên nếu thiếu thời gian, không cắt bước đo web và sửa thưởng mốc.
2. **Beta chạy chủ yếu trên web hay desktop, và có xoá tiến độ sau beta không?** Khuyến nghị: nói rõ vì nó đổi cả gói. Nếu chủ yếu web thì đo + chế độ nhẹ là việc số 0 thật. Nếu có xoá tiến độ thì phương án hạ giá tier 2 (mục 4) nhẹ đi nhiều và có thể dùng để beta thấy lần nâng đầu; nếu không xoá thì giữ 40k.
3. **Nâng nhà Nhiệm vụ trong beta: hoãn hay làm?** Câu này **có ở cả hai doc** (Land và Nhiệm vụ), Liam trả lời một lần. Khuyến nghị: theo doc Nhiệm vụ, **hoãn** (giữ `fixed_lv: 1`, Land không phải làm gì).

Việc không hỏi (trong luật đã chốt, chỉ báo): 2 Rare tier 2 để bịt vùng chết m3 → m4 (chỉ Shard); +8 decor common; món khởi đầu 90 Shard; nguồn Axie đi lại (đội phòng thủ raid → preset 0 → ngẫu nhiên, bỏ trùng).
