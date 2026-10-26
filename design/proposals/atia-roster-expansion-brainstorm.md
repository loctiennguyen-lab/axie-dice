# Thêm quái Atia 3D cho đa dạng — brainstorm

Ngày 26/10/2026 · game-designer · Chỉ brainstorm, chưa sửa code/asset/data, đợi Liam chọn hướng.

**Đã sửa theo review 26/10** (`atia-roster-expansion-review.md`, APPROVE WITH CHANGES): (1) tính lại pool đầu run theo luật bốc thật, có bảng và test cứng;
(2) kiểm clip + nguồn bằng đường đúng, **bắt được 2 con trùng với quái đang có (Strawberry = spikelet, Onion = broodmaw), đã thay**, N giảm 13 -> 12;
(3) cost giữ bằng mẫu; (4) thêm mục tiêu sim, danh sách test, quyết định RULES_VERSION; (5) bỏ hướng C và "đợt 2 biome" khỏi đề xuất, chỉ còn ghi chú sau beta;
(6) dung lượng ghi rõ là ước.

Nguồn đã đọc: `monster_art.gd`, `atia_models.json`, `ContentDB.gd` (quái + pool), `combat_engine.gd:3631-3724`, `arenas.json`, `t_atia_coverage.gd`,
`t_rules_version.gd`, `pck-size-audit-2026-10-16.md`, thư mục `godot/assets/atia/<key>/`, FBX trong `asset-library/godot-ready/src/Atia_Asset/DeliveryAssets/Character/Monster/`.
(Đường kho đúng là `asset-library/godot-ready/src/...`; `asset-library/src/` không tồn tại. Checkout của tôi CÓ `godot/assets/atia/<key>/` cho 24 key.)

## 0. Điều cần biết trước

- "235 quái" trong README kho là 235 FILE. Đếm theo thư mục chỉ có ~28 họ quái.
- Quái KHÔNG gắn biome. Biome (savannah, forest, arctic, mystic, genesis, luna) chỉ đổi arena theo đoạn run. Quái chọn theo power level `pw`.
  Nên "mỗi biome một bộ quái" là hệ thống mới (ghi chú cuối file), không nằm trong đề xuất này.
- Tôi không tìm thấy script dựng `assets/atia/<key>/` (model.fbx + tex.png + anims/*.res + library.tres + wrapper `atia_model.gd`). `import_homeland.py` chỉ cho scene Homeland.
  Wrapper có comment: FBX Atia không kèm texture, wrapper gắn albedo thủ công. Cần hỏi làn C hoặc dựng lại (mục 4).

## 1. Đa dạng đang thiếu ở đâu

Luật bốc (`combat_engine.gd:3664-3671`, `_available_normal_keys`): lọc `min <= pw+1`, sort cost GIẢM dần, hoà cost thì **index pool thấp đứng trước**
(index cao bị cắt trước), rồi bốc từ `ceil(n*0.7)` con đầu. Số quái mỗi trận `2 + floor(pw/4)`, tối đa 5 (6 từ pw 14).

| pw | số loại trong pool | số loại bốc được (hiện tại) |
|---|---|---|
| 0 | 3 (slime, chomper, bugling) | 3 |
| 1 | 4 | 3 |
| 2 | 6 | 5 |
| >= 10 | 17 | 12 |

1. **Đầu run: 3 con lặp lại** (mỗi trận 2 con). Đây là lúc người chơi mới nhìn nhiều nhất.
2. **Cuối run: 5 con rơi khỏi pool** (bomblet, spikelet, chomper, slime, bugling). Thực tế cuối run chỉ có 12 loại.
3. **Elite chỉ 4 loại**, bốc đều 1 con mỗi trận elite. Boss 6 key dùng 5 GLB, giữ nguyên.

## 2. Ứng viên từ kho + kiểm trùng

### 2a. Kiểm nguồn của quái hiện có (đã làm, bằng clip + nhìn tex.png)

Wrapper giữ nguyên tên clip gốc của nguồn (spikelet có `Death`, ravenling có `Skill1`, pyrewing có `RangeAttack`), nên bộ clip trong `anims/` là dấu vân tay họ nguồn.

| Quái hiện có | Bằng chứng | Kết luận |
|---|---|---|
| spikelet | clip Death/GetHit/Idle/Skill1; `tex.png` giống hệt `T_Strawberry_C.png` (đã mở cả hai) | **= họ Strawberry** (chắc) |
| broodmaw | `tex.png` cùng bố cục `T_Onion_C.png` (đã mở cả hai); clip Attack/Dead/GetHit/Idle | **= họ Onion** (chắc) |
| jellyfin | tex tím-xanh, khác `T_Anemone_C.png` | không phải Anemone |
| venomaw | tex hoa vàng-xanh lá, khác Anemone | không phải Anemone, và clip `Attack` (Shitake dùng `Attack_1`) nên không phải Shitake |
| slime | tex xanh lá có mắt hồng; clip Attack/Dead/GetHit/Idle | giống họ Slimes_01, không phải Onion/Anemone |
| bugling, warden | clip Attack/GetHit/Idle, KHÔNG có Dead | khớp Slimes_02-04 (chỉ bản 01 có Dead) |
| ravenling, e_plague, e_ravager (+ mirror, plague_mother cũ) | clip Idle/Skill1/Dead, không GetHit | khớp kiểu họ 1100xx (Tanuki, Owl, Snail, Elephant, Phoenix, Mushroom...). **Chưa biết 3 con nào** |
| chomper, bruiser, hexeye, jellyfin, venomaw | Attack/Dead/Idle | chưa xác định họ |
| e_archon, e_bulwark, stalker, totem, cleaver, thornback, bomblet, pyrewing | các bộ clip ít | chưa xác định |

**Chưa kiểm hết**: còn ~14 model chưa đối chiếu với từng họ. Việc bắt buộc trước khi import: so `tex.png` của cả 21 model hiện có với texture nguồn của từng ứng viên
(hoặc xem contact sheet cạnh nhau). Nhóm 1100xx là rủi ro lớn nhất, vì 3 con hiện có nằm trong nhóm đó, và 6 ứng viên của tôi cũng từ nhóm đó.

### 2b. Ứng viên, clip THẬT (liệt kê tên file FBX trong kho, chưa mở nhị phân)

| Họ | Clip có | Đủ 4 (idle/attack/hit/die)? | Trùng quái hiện có? |
|---|---|---|---|
| Shitake | Idle, Attack_1, GetHit, Dead, Run | đủ | không (tên clip `Attack_1` không có ở model nào hiện có) |
| Oranda | Idle, Attack_1, GetHit, Dead, Run | đủ | không (cùng lý do) |
| Anemone | Idle, Attack, GetHit, Dead, Run | đủ | không trùng jellyfin/venomaw/slime/broodmaw/spikelet; chưa đối chiếu ~14 con còn lại |
| Cloud (+NightMare) | Idle, Skill1-4, GetHit, Dead, Stun, Run, Walk | đủ | chưa thấy trùng (con nào hiện có cũng thiếu Skill2-4) |
| Strawberry | Idle, Skill1-4, Skill2, GetHit, Death | đủ | **TRÙNG spikelet, loại** |
| Onion | Idle, Attack, GetHit, Dead | đủ | **TRÙNG broodmaw, loại** |
| 110004 Tanuki | Idle, Skill1, Dead, Run, Walk | thiếu hit | chưa rõ (nhóm 1100xx) |
| 110005 Snail | Idle, Skill1, Dead, Run, Walk | thiếu hit | chưa rõ (nhóm 1100xx) |
| 110006 Elephant | Idle, Skill1, Dead, Run, Walk | thiếu hit | chưa rõ (nhóm 1100xx) |
| 110003 Owl / 110010 BigOwl | Idle, Skill1, Dead, Stun, Run, Walk | thiếu hit | chưa rõ (nhóm 1100xx) |
| 110007 Phoenix | Idle, Skill1, Dead, Run, Walk | thiếu hit | chưa rõ (nhóm 1100xx) |
| 110009 Giant Mushroom | Idle, Skill1, Skill2, Dead, Stun, Run, Walk | thiếu hit | chưa rõ (nhóm 1100xx) |
| 500340003 AncientGolem | Idle, Skill1-4 (+biến thể), Dead, Stun | thiếu hit | chưa thấy trùng |
| 500340002 SeaHorse / 500340008 Pangolord | SeaHorse: Dead, Stun, nhiều skill; Pangolord: Idle, GetHit, Dead + ~12 skill | SeaHorse thiếu hit | để dành cho boss, không dùng |
| MiniBoss 1-4 | Idle, Run, Skill1-3 | **không có Dead** | loại; e_archon hiện có có vẻ là con trong nhóm này |
| Slimes 01-04, 110001 Slime, 110002 Shiitake, 110008 Jellyfish | | | gần chắc trùng slime/bugling/warden/jellyfin, loại |

Thiếu hit chấp nhận được: registry bỏ slot, đã có tiền lệ (chomper, bruiser). Elite cần tối thiểu `idle`.

### 2c. Đề xuất N = 12 (9 thường + 3 Elite)

Mỗi con **giữ nguyên khối chỉ số của mẫu, kể cả cost, `trait`, `summons`, `elite`**; chỉ đổi tên, hình, thứ tự mặt. Không status/role/trait mới. (Đổi số thì không còn là "mượn", phải sim như quái mới.)

| Key | Họ | Mẫu | Vai trò | cost (= mẫu) | min | Trùng? |
|---|---|---|---|---|---|---|
| gmush | 110009 Giant Mushroom | chomper | bruiser | 4 | 1 | chưa rõ |
| shitake | Shitake | bugling | poisoner | 3 | 1 | không |
| snail | 110005 Snail | slime | bruiser | 3 | 1 | chưa rõ |
| tanuki | 110004 Tanuki | ravenling | assassin | 5 | 3 | chưa rõ |
| anemone | Anemone | jellyfin | healer | 5 | 3 | không (theo 2a) |
| cloud | Cloud | totem | buffer | 6 | 6 | không thấy |
| oranda | Oranda | hexeye | mage debuff | 7 | 7 | không |
| elephant | 110006 Elephant | bruiser | bruiser nặng | 7 | 7 | chưa rõ |
| owl | 110003 Owl | pyrewing | mage burn | 8 | 8 | chưa rõ |
| e_bigowl | 110010 BigOwl | e_ravager | Elite bruiser | 11 | elite pool | chưa rõ |
| e_golem | AncientGolem | e_bulwark | Elite tank | 11 | elite pool | không thấy |
| e_phoenix | 110007 Phoenix | e_archon | Elite mage burn | 11 | elite pool | chưa rõ |

Con nào "chưa rõ" mà đối chiếu ra trùng thì thay bằng con dự phòng trong nhóm 1100xx (Tanuki/Snail/Elephant/Owl/Phoenix/Mushroom/BigOwl là 7 con cho
tối đa 6 chỗ + 3 con hiện có chiếm chỗ), hoặc bỏ con đó. N có thể tụt còn ~9-10. Con tank thường: không có ứng viên sạch, giữ 2 tank hiện có + e_golem.

### Bảng pool với vị trí + cost đề xuất (tính tay theo luật bốc, chưa chạy code)

Thứ tự index trong `normal_pool` (chỉ cần giữ thứ tự tương đối các con cũ; chỗ con mới là một phần của luật, vì quyết định tie-break):
- cost 4: **gmush đứng trước chomper**, spikelet sau chomper.
- cost 3: thứ tự **slime, shitake, snail, bugling** (bugling bị cắt trước, slime giữ ở đầu run).
- cost >= 5: con mới đặt sau con cũ cùng cost (tanuki, anemone sau jellyfin, ravenling, bomblet).

| pw | n (pool) | bốc `ceil(0.7n)` | **số loại bốc được (mới)** | hiện tại | loại bị cắt |
|---|---|---|---|---|---|
| 0 | 6 | 5 | **5** (gmush, chomper, slime, shitake, snail) | 3 | bugling |
| 1 | 7 | 5 | **5** (gmush, chomper, spikelet, slime, shitake) | 3 | snail, bugling |
| 2 | 11 | 8 | **8** (jellyfin, ravenling, tanuki, anemone, gmush, chomper, spikelet, slime) | 5 | shitake, snail, bugling |
| >= 10 | 26 | 19 | **19** (mọi con cost >= 5, gồm cả 5 con cost 5) | 12 | gmush, chomper, spikelet, slime, shitake, snail, bugling |

Ghi chú: slime chỉ còn ở pw 0-2; bugling hết ở pool (vẫn ra qua summon của broodmaw, không đi qua pool). Con mới cost 3-4 chỉ sống ở đầu run, đúng như slime/bugling hôm nay.
Ở pw >= 10 con cost cao (warden, stalker, pyrewing, cleaver) ra ít hơn: xác suất 1/12 xuống 1/19 (khoảng -37%); mix cuối run thêm nhiều con cost 5-6. `sc = budget / tổng cost` giữ tổng sức mạnh,
nhưng đổi số đầu quái và loại quái, nên **phải sim, không đoán** (mục 5).

Tôi KHÔNG đề nghị sửa 0.7 hay sort: đó là chỉnh luật đã balance ở v5.

### Test cứng đề xuất: `t_pool_diversity`
Dùng đúng hàm `_available_normal_keys(pw)` + công thức `ceil(n*0.7)` (hàm thuần, không RNG, không cần chạy combat):
1. số loại bốc được ở pw 0 >= 5, pw 1 >= 5, pw 2 >= 8, pw 10 >= 19 (ngưỡng hiện tại 3, 3, 5, 12);
2. mỗi key mới xuất hiện trong tập bốc được ở ít nhất một pw (không có con "chết trong pool");
3. mỗi key trong `normal_pool` có entry trong `ContentDB.enemies` và `cost` bằng cost của mẫu ghi trong test (chống lệch cost âm thầm);
4. elite_pool có 7 key khác nhau.

## 3. Hai hướng (còn lại sau khi bỏ C)

**A. Đổi da: nhiều model cho cùng key.** Chọn model theo hash vị trí/slot (KHÔNG dùng RNG combat, để replay không lệch). Không bump RULES_VERSION, không sim.
Mất: tên và hình lệch nhau. `monster_art.gd` ghi ý định vai trò đọc được từ hình; người chơi học "Chomper = bruiser" qua hình, nay đổi hình thì khó đọc. Cũng không thêm gì cho codex.
Công nhỏ. Dung lượng: **ước** +3-4 MB.

**B. Quái mới thật, mượn khối chỉ số (khuyến nghị).** Bảng 2c. Người chơi thấy con mới và gọi được tên, đầu run hết lặp (3 -> 5 loại), Elite 4 -> 7.
Giá: đụng `ContentDB.gd` nên **phải bump RULES_VERSION**, seed/replay/ghost cũ lệch, sim lại, sửa test. Công vừa (khoảng 1 tuần làn).
Dung lượng: **ước** +4 MB cho 12 model (0,3 MB/model từ audit 16/10, tex cap 1024), chưa đo model thật, sẽ đo ở bước làm. Dọn 3 thư mục boss cũ (~3,8 MB) chỉ làm khi đã grep chắc không ai trỏ tới.

**Khuyến nghị: B.**

## 4. Pipeline nhập

1. Đối chiếu nguồn (2a) cho cả 21 model, chốt danh sách cuối. Thay con trùng.
2. FBX -> `godot/assets/atia/<key>/` theo đúng cấu trúc hiện có (model.fbx, tex.png, anims/*.res, library.tres, `<key>.tscn` dùng `atia_model.gd` gắn albedo). Chưa có script, cần làn C hoặc `technical-artist` dựng. Không chép tay.
3. Anim: slot `idle/attack/hit/die` trỏ tên clip thật (`Attack_1`, `Skill1`, `Dead`...). Thiếu hit thì bỏ slot.
4. `atia_models.json`: `height_m` 2.2 (thường) / 2.8 (Elite), `max_width_m` 4.2, `facing_deg` chụp kiểm từng con, `fallback_sprite` bắt buộc (test kiểm file tồn tại).
   `NORMAL_KEYS` / `ELITE_KEYS` / `MONSTER_SPRITES` trong `monster_art.gd`.
5. `ContentDB.gd`: thêm 12 entry vào `enemies` (copy khối mẫu), chèn `normal_pool` / `elite_pool` theo thứ tự ở mục 2c. Comment `ContentDB.gd:25` đã cảnh báo thứ tự pool ảnh hưởng kết quả.
6. **RULES_VERSION**: `autoload/` nằm trong WATCHED_DIRS của `t_rules_version` (cùng `scripts/core`, `scripts/meta`, `resources/relics`, `assets/data/rules`, `part_faces.json`), `ContentDB.gd` nằm đó
   nên **bump RULES_VERSION + `SUPPORTED` của Worker + deploy Worker**. Theo `production/beta-plan.md`: Atia có lần bump riêng `-v` (sau `-u` của đợt R1 Nhiệm vụ + v5), đợt R-Atia, cách R3 (reset) ≥2 ngày.
   Ngưỡng 5/5 ở pw 0-1 dựa đúng 3 con min 1 (gmush, shitake, snail; gmush và snail còn "chưa rõ" trùng hay không). Nếu bước đối chiếu tex loại một con thì chọn con thay có min 1 cùng cost, không được thì hạ ngưỡng `t_pool_diversity` pw 0-1 xuống 4 và ghi lý do.
   `monster_art.gd` và `atia_models.json` không thuộc thư mục nào trong danh sách nên đổi art riêng không đụng fingerprint.

## 5. Mục tiêu sim (so với baseline v5, cùng seed, `godot/tools/sim_balance.gd --policies=attack_spam,greedy`)

- Tỉ lệ thắng của attack_spam và greedy ở asc 0 lệch **<= 2 điểm %** so với v5, theo từng đoạn stage. attack_spam **không leo lại** (anti-spam v5 là chốt).
- Số trận/run và số lượt/trận lệch **<= 5%**.
- Mỗi con mới xuất hiện >= N lần trong 300+ trận ở pw tương ứng (N đặt theo xác suất tính từ bảng, thấp nhất khoảng 300 x P(bốc)); 3 Elite mới mỗi con ~1/7 số trận elite.
- Soi riêng Elite có `plating` (e_golem mượn e_bulwark) và mage burn (e_phoenix mượn e_archon): Elite bốc đều nên 4 -> 7 không được đổi độ khó trung bình.
- Nếu lệch: chỉnh con nào (mẫu/min) trước, không chạm 0.7, không chạm số mặt.

## 6. Test bị ảnh hưởng (liệt kê theo review, tôi mới kiểm được một phần)

- `t_atia_coverage`: cứng 17/4/6 và "27 keys", đòi mọi key trong `ContentDB.enemies` nằm trong danh sách đóng băng. Sửa thành 26/7/6.
- `t_content_expansion`, `t_enemy_traits`, `t_plating`, `t_team_can_break`, `t_combat_spacing`: tham chiếu key cứng (đã thấy `t_content_expansion`, `t_combat_spacing` nhắc `ravenling`).
- Test seed-walk: `t_full_run_loop`, `t_boss_encounters`, `t_replay` (RNG ra encounter khác). `t_sim_balance_smoke`.
- `scripts/raid/raid_ghost.gd` nhắc key quái: kiểm ghost raid cũ có vỡ khi pool đổi (chưa mở file).
- Test mới: `t_pool_diversity` (mục 2c), cộng `t_atia_anim_play` chạy lại cho model mới. Số sàn `run_tests.sh` đổi cùng commit.
- Sau khi làm: `qa_atia_lineup` chụp, và 1 run thật chứng minh pw 0-2 có >= 5 loại, Elite mới ra ở Elite node.

## 7. Câu hỏi cho Liam

1. **Chọn hướng: A (đổi da, nhanh, hình lệch tên) hay B (quái mới, khuyến nghị)?**

(RULES_VERSION: tôi tự quyết gộp bump với lần Atia `-v`. Chi tiết nhỏ tôi tự quyết: tên từng con, thứ tự mặt, thứ tự import.)

## Ghi chú sau beta (không làm bây giờ)

Pool theo biome (savannah ra bộ này, arctic ra bộ kia) cho câu chuyện hành trình rõ nhất nhưng là hệ thống mới, nhân sim lên 6 lần, chồng với v5. Pangolord, SeaHorse là ứng viên boss thứ 7 nếu sau này mở thêm boss.
