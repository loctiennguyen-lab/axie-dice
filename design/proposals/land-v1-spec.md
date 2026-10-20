# Land v1 — spec thực thi (20/10/2026)

Căn cứ: "Liam trả lời (20/10 khuya)" trong `land-meta-loop-brainstorm.md`. Hạn 2 ngày, 2 làn song song (~1.5 ngày code).
Chưa chạy sim kinh tế; giá Shard bên dưới là số khởi điểm, nằm hết trong JSON để chỉnh.

## 1. Phạm vi v1

Làm:
- Chế tạo đồ trang trí (decor) bằng Shard. Không currency mới.
- Chế độ "Sửa Land": thả tự do, xoay, cất lại, lưu qua SaveStore.
- Điểm thẩm mỹ + 8 mốc, thưởng cosmetic/danh hiệu/khung.
- Raid R1 ghost: lưu đội phòng thủ, người khác "Thách đấu Land", thưởng huy hiệu + điểm Raid.

Ràng buộc từ Liam (kiểm lại khi review): Land không cho sức mạnh, thường = Ranked; không stamina; không xưởng nguyên liệu/trang bị; không faucet Stone mới; Lõi/Luật run không gắn Land; thua raid không ai mất gì.

Cắt (ghi bump sau):
- Ô công trình theo tier (thay Inns): KHÔNG làm. Bump sau. Gallery (`PLOTS`, min_tier 5) giữ nguyên là stand-in, không đụng.
- Xem Land người khác / đi thăm: không. Raid chỉ hiện tên + đội ghost, không dựng Land của họ.
- Ghost replay thật (phát lại từng đòn của người khác): không. Xem mục 6.
- Server verify kết quả raid bằng replay engine: không (Worker hiện cũng chưa replay, chỉ kiểm hash chain, xem `leaderboard.js` đầu file). Vì thưởng chỉ là huy hiệu/điểm nên chấp nhận.
- Xoay tự do mọi góc: chỉ 8 hướng (bước 45 độ). Chồng món lên nhau: không (không có tầng).
- Món decor có animation/âm thanh/hiệu ứng: không.
- Chia sẻ/bán/trao đổi decor: không.

## 2. Chế tạo decor

Nguyên liệu: chỉ Shard (`MetaState.spend("shard", n)`, đã có). Thẻ trùng Echo Box KHÔNG dùng để chế (tránh phải sửa bảng Echo Box; Land ±3% đã chốt ở `project_echobox-two-box-split`). Một món chế được nhiều lần (mỗi lần +1 bản sở hữu) tới mức trần bản mỗi loại (cột `max_own`).

Danh sách v1, 16 món, id đặt `decor_*`. Đường dẫn dưới `res://assets/land/homeland/scenes/HomeLand_Asset/`. Có 3 độ hiếm: C(common), R(rare), E(epic).

| id | độ hiếm | scene (dưới Environment/ trừ khi ghi khác) | Shard | max_own |
|---|---|---|---|---|
| decor_sav_tree | C | Savannah/Tree/S_Tree01_Allside | 40 | 6 |
| decor_sav_shrub | C | Savannah/Shrub/S_Shrub01_Allside | 20 | 8 |
| decor_sav_rock | C | Savannah/Rock/SavannahRock_01 | 25 | 6 |
| decor_sav_flower | C | Savannah/Ground/Flower/Cattail2 | 20 | 8 |
| decor_sav_path | C | Savannah/Decoration/StonePath/S_StonePath_Straight | 30 | 10 |
| decor_for_tree | C | Forest/Tree/F_Tree1_AllSide | 40 | 6 |
| decor_for_flower | C | Forest/Ground/Flower/Flower_RandomColor | 25 | 8 |
| decor_arc_stone | R | Arctic/Props/Stone_01 | 90 | 4 |
| decor_arc_tree | R | Arctic/Tree/A_Tree01_AllSide | 100 | 4 |
| decor_mys_tree | R | Mystic/Tree/M_Tree_01_Allside | 120 | 4 |
| decor_mys_rock | R | Mystic/Rock/Rock_01 | 100 | 4 |
| decor_gen_tree | R | Genesis/Tree/SM_Tree_G_01 | 140 | 3 |
| decor_luna_rock | R | LunaLanding/Rock/SM_Rocks_Luna_A1 Variant | 140 | 3 |
| decor_luna_tree | E | LunaLanding/Tree/Luna_Landing_Tree_1 Variant | 300 | 2 |
| decor_terrarium_a4c | E | Item/NFT_Item/A4c/Terrarium_a4c | 450 | 2 |
| decor_terrarium_f19a | E | Item/NFT_Item/F19a/Terrarium_f19a | 450 | 2 |

Gate mở khoá: món biome X chỉ chế được khi Land đã đạt tier của biome đó (Savannah+Forest từ L1... xem cột `min_tier` trong JSON: sav/for = 1, arc = 3, mys = 4, gen = 5, luna/terrarium = 6). Làn L kiểm lại id scene bằng `t_decor_assets` (mọi scene phải load được). Terrarium là NFT_Item, làn L xem 2 món có nhìn được ở góc camera Land không, không thì đổi sang món khác trong `Item/NFT_Item/`.

Dữ liệu: `godot/assets/data/land/decor.json` (id, name, rarity, scene, min_tier, shard_cost, max_own, footprint_r). Không hardcode.

## 3. Đặt tự do trên Land

Chỗ gắn: `godot/scenes/land/Land.gd` (class `LandHub`). Đã có sẵn thứ dùng lại: `_blocked`, `_footprints` ({p,r}), `_lanes` (đường Axie đi), `_bld_rects`, `LAND_EDGE_MARGIN = 0.4`, `_cam` + `_g/_right` (ray từ chuột xuống mặt đất), `_scene_cache`, `_nodes3d`. Prop ngẫu nhiên hiện có (cây/bụi/đá theo `BIOMES`) tự tránh các vùng này; decor người chơi đặt thì phải được ưu tiên: khi có decor đặt thì prop ngẫu nhiên gần đó bị bỏ (kiểm tra `_footprints` đã gồm decor trước khi rải prop).

Vào/ra: nút "Sửa Land" ở HUD góc dưới (`_hud_bl`/`_hud_br`), phím `E`. Esc hoặc nút "Xong" thoát. Trong chế độ sửa: tắt click vào công trình, tắt Axie lang thang (đỡ vướng), hiện panel decor bên phải (UI3, đọc `godot/CLAUDE.md`: lưới 8 px, chữ 18/24, 1 primary).

Thao tác:
- Panel liệt kê decor đã sở hữu + số còn lại chưa đặt. Chọn món rồi click mặt đất = đặt tại điểm chuột. Kéo món đã đặt = di chuyển (dùng pointer events như `bindDrag`, cùng cơ chế click-click là đường dự phòng cho cảm ứng).
- Snap: lưới 0.5 đơn vị thế giới (1 ô = 0.5). Giữ Shift = không snap. Lý do: lưới nhỏ vẫn "tự do" đủ cho Liam nhưng không bị lệch so le, test được bằng số.
- Xoay: `R` hoặc nút, bước 45 độ, lưu `rot` 0..7.
- Cất lại: kéo ra panel hoặc `Delete`/nút thùng rác. Cất không mất gì (món về kho, 0 Shard hoàn vì chưa tiêu thêm).
- Hợp lệ nếu: (a) tâm nằm trong hình thoi Land cách mép >= `LAND_EDGE_MARGIN + footprint_r`; (b) không chồng footprint của công trình, plot trống (Gallery), Portal; (c) cách `_lanes` >= 1.0; (d) không chồng decor khác quá 50% bán kính tổng; (e) chưa vượt trần số món. Không hợp lệ thì ghost đỏ + tooltip nói lý do (luật "disabled phải nói lý do").
- Vùng cấm trên màn: Portal và hub (`_hub`), 3x3 lưới công trình, plot Gallery, `_lanes`, mép Land.

Trần số món đặt cùng lúc theo tier Land: `[10, 16, 24, 32, 42, 54]` cho tier 1..6 (khoá trong `decor.json`/`land_decor_rules.json`). Tier thấp hơn sau này thì không bị tụt (Land chỉ lên).

Lưu: field mới `land_decor_placed: Array` (mỗi phần tử `{id, x, z, rot}`, x,z làm tròn 0.01) và `land_decor_owned: Dictionary` (id -> số bản) trong `MetaState`. BẮT BUỘC sửa cả `MetaState.reload_from_store()` và hàm gộp dict ghi save (dòng ~900, cạnh `cosmetics_owned`), ghi qua SaveStore. Validate khi load: id lạ bị bỏ, vị trí ngoài vùng hợp lệ thì đẩy món về kho (không xoá), vượt trần thì cất bớt phần cuối. `MetaState` nằm trong fingerprint `t_rules_version` nên cây chính phải bump `ActionLog.RULES_VERSION` và deploy Worker: ĐÂY LÀ BƯỚC PHẢI HỎI LIAM. Nếu làn L không muốn đụng fingerprint, đặt logic Land decor ở `scripts/land/land_decor.gd` (ngoài thư mục bị fingerprint) và chỉ để 2 field thô trong MetaState; field thô vẫn tính là đụng. Quyết: chấp nhận bump, gộp chung 1 lần bump với làn RV.

## 4. Điểm thẩm mỹ + mốc

Điểm mỗi món đặt: C = 1, R = 3, E = 8.
Chống spam: mỗi `id` chỉ tính tối đa N = 3 bản đầu (bản thứ 4 trở đi 0 điểm, vẫn đặt được). Chồng/đặt sát nhau không cộng thêm.
Điểm đa dạng: +2 cho mỗi biome khác nhau có >= 1 món đặt (tối đa 6 biome = +12). Khuyến khích trộn.
`aesthetic = sum(rarity_pts * min(count_id, 3)) + 2 * distinct_biomes`.
Ví dụ: 3 cây Savannah (3) + 2 đá Arctic R (6) + 1 Terrarium E (8) + 2 biome (4) = 21.
Trần lý thuyết: 16 món x 3 bản tối đa, nhưng trần số món theo tier chặn lại; điểm tối đa thực tế ~ 100 ở tier 6.

Tính từ `land_decor_placed` mỗi lần mở Land (không lưu riêng, tránh lệch). Mốc đã nhận lưu `land_milestones_claimed: Array[String]`.

| mốc | điểm | thưởng (KHÔNG Stone, KHÔNG sức mạnh) |
|---|---|---|
| m1 | 5 | danh hiệu "Gardener" |
| m2 | 12 | khung avatar `frame_land_1` |
| m3 | 20 | 1 cosmetic dice-skin thường (tên chốt ở làn L, lấy từ pool Echo Box COSMETIC_POOLS KHÔNG phải thứ gián tiếp bán, xem lưu ý) |
| m4 | 30 | danh hiệu "Landscaper" |
| m5 | 42 | khung `frame_land_2` |
| m6 | 55 | cosmetic arena/nền run |
| m7 | 70 | danh hiệu "Land Architect" |
| m8 | 90 | khung `frame_land_3` + decor E độc quyền `decor_trophy` (không chế được, chỉ từ mốc) |

Lưu ý: dùng cosmetic/title/frame có sẵn trong `Cosmetics`/`TitleNames` (kiểm chỗ `cosmetics_owned` ở MetaState ~dòng 337, 685). Thưởng mốc phải thêm vào kho qua đúng đường `cosmetics_owned`, và không được trùng pool đang bán/roll ở Echo Box (làm lệch giá Echo Box; tiền lệ ở `project_world-tour-milestone-design`). Nhận mốc thì claim thủ công ở panel Sửa Land (thấy được mốc kế tiếp).

## 5. Ô công trình theo tier

Không làm trong v1. Ghi bump: sau khi decor ổn, thêm `PLOTS` theo `min_tier` (Land.gd:55) nhưng chưa có công trình nào cần ô mới, nên chờ có feature.

## 6. Raid R1 (ghost)

Cách rẻ nhất trong 1 ngày: KHÔNG phát lại ghost. Dùng "đội phòng thủ = snapshot đội, chạy bằng AI quái": client dựng trận thường, phe địch là 3 unit từ snapshot (class, hp, 3 die face, skin), điều khiển bằng AI enemy hiện có (chọn hành động theo luật enemy sẵn). Người tấn công chơi trận thường, không cần replay đòn của người phòng thủ. Rủi ro: enemy engine quen đọc `monster` data chứ không đọc unit-người, làn RV phải làm 1 hàm `ghost_to_enemies(snapshot)` ánh xạ unit -> enemy def (hp, mỗi face thành 1 intent, passive class bỏ qua nếu không map được). Nếu sau 3 giờ chưa chạy ổn thì lùi về phương án B: ghost chỉ là "boss trận 1 lần" lấy template quái cố định, tên/skin của người phòng thủ chỉ để hiển thị (vẫn đạt "đánh ghost của người khác", ít công hơn, đây là điểm dừng an toàn).

Rule: không ai mất gì, thua vẫn được 1 điểm Raid thấp, thắng được nhiều hơn. Mỗi người tấn công mỗi ghost tối đa 3 lần/ngày UTC, tổng 5 raid/ngày (chống farm, không phải stamina; ghi rõ trong UI vì Liam bỏ stamina, nên để đây là "giới hạn điểm" chứ không chặn chơi: quá hạn vẫn đánh được, chỉ không cộng điểm). Điểm Raid dùng cho huy hiệu (5 mốc Raid, danh hiệu/khung, không Stone), không vào kinh tế.

Chống gian: seed do server cấp theo `challenge_id`. Client gửi kết quả + hash chain. Server chỉ kiểm: challenge thuộc người này, chưa dùng, trong hạn 30 phút, điểm trong ngưỡng. Thật sự replay-verify = bump sau (Worker hiện chưa làm cho Leaderboard, nên "như Leaderboard" nghĩa là như vậy).

Worker cần (nên tái dùng mẫu `leaderboard.js` + `accounts.js` shared, `isXPath` đăng ký ở `index.js:259` kiểu `isLeaderboardPath`):
- Migration `0008_raid.sql`: `raid_defense (player_id PK, team_json, skin_json, power_hint, updated_at)`, `raid_challenges (challenge_id PK, attacker_id, defender_id, seed, created_at, state, result)`, `raid_daily (attacker_id, day, count)`, `raid_points (player_id PK, points)`.
- `worker/src/raid.js`: `POST /api/raid/defense` (lưu đội, validate id/class/độ dài, giới hạn kích thước JSON), `GET /api/raid/opponents` (lấy 5 ghost khác, random, loại bản thân), `POST /api/raid/start {defender_id}` -> `{challenge_id, seed, team}`, `POST /api/raid/finish {challenge_id, won, turns, h}` -> `{points, badge?}`.
- Test: `worker/test/raid.test.mjs` (đủ nhánh 403/404/409/ngưỡng).
- DEPLOY Worker + chạy migration D1 = phải hỏi Liam trước. Làn RV chỉ chuẩn bị tới "test xanh", không deploy.

Client RV: lưu đội phòng thủ ở màn House/Team presets (nút "Đặt làm đội phòng thủ"), nút "Thách đấu Land" ở Land (đặt vào plot/board có sẵn, không công trình mới), màn kết quả. Online-only (thêm vào `ONLINE_ONLY` ở Land.gd:29), offline thì disabled kèm lý do.

## 7. Chia làn

Làn L (client Land), ~1.5 ngày:
1. `land/decor.json` + `scripts/land/land_decor.gd` (luật hợp lệ, điểm, mốc: hàm thuần, test được).
2. MetaState + `reload_from_store()` + SaveStore (3 field: placed, owned, milestones_claimed).
3. Chế tạo (UI3 panel) + chế độ Sửa Land trong `Land.gd` (+ file `LandEdit.gd` tách ra cho khỏi phình Land.gd).
4. Điểm + mốc UI.
Test: `t_decor_data` (scene load được, id duy nhất, giá > 0), `t_decor_rules` (hợp lệ/vùng cấm/trần/snap/xoay), `t_decor_score` (ví dụ số ở mục 4, cap N=3), `t_decor_save` (round-trip qua SaveStore, load id lạ/vượt trần), `t_decor_milestones`. Floor test tăng theo, sửa `technical-preferences.md` cùng commit.
Chạm: Land.gd, MetaState.gd, save_store.gd (chỉ nếu cần), assets/data/land/, scenes/land/, tests.

Làn RV (raid), ~1.5 ngày:
1. Worker: migration + `raid.js` + test (Node, không cần Godot) — song song được ngay.
2. Client: lưu đội phòng thủ, `ghost_to_enemies`, trận Raid, kết quả, huy hiệu.
3. Gắn vào Land: nút Thách đấu (làm SAU khi L merge Land.gd; trước đó chỉ làm màn riêng `scenes/raid/`).
Test: `t_raid_ghost` (snapshot -> enemy hợp lệ), `t_raid_client` (online-only/disabled), `raid.test.mjs`.
Chạm: worker/src, worker/migrations, scenes/raid/ (mới), scenes/team_presets (nút), Land.gd (1 dòng nút, đợi L), tests.

Xung đột: cả hai chạm MetaState/RULES_VERSION. Thứ tự: L xong phần MetaState trước (ngày 1), RV rebase rồi mới thêm field `raid_*`. Bump `RULES_VERSION` một lần ở cây chính sau khi cả hai merge, rồi hỏi Liam deploy Worker + migration.

## 8. Câu hỏi cho Liam

1. Giá Shard decor (mục 2) chưa sim. Mặc định: dùng số trên, chỉnh sau trong JSON. Khuyến nghị: chấp nhận, cho economy-designer sim lại sau, không chặn làn.
2. Raid có giới hạn 3 lần/ghost, 5 điểm/ngày. Liam bỏ stamina nên mình để vượt giới hạn vẫn đánh được chỉ không cộng điểm. Khuyến nghị: giữ vậy.
3. Bump `RULES_VERSION` + deploy Worker/D1 migration cho raid: đợi Liam nói. Khuyến nghị: gộp 1 lần sau khi L và RV merge xong.
