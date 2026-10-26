# Review: atia-roster-expansion-brainstorm.md

Ngày 26/10/2026 · systems-designer (reviewer độc lập) · chỉ đọc, không sửa gì.

## Verdict: APPROVE WITH CHANGES
Hướng B đúng, không cần hệ thống mới. Nhưng bảng cost/min trong doc sẽ không cho ra cái nó hứa (đầu run), và có 2 thứ
chưa kiểm được. Sửa cost/tie-break + đo bằng sim trước khi chốt.

## Đối chiếu code (đúng / sai)
- Luật bốc đúng: `combat_engine.gd:3664-3671`, lọc `min <= pw+1`, sort cost giảm dần, hoà thì theo index pool (`_available_normal_keys`),
  bốc từ `ceil(avail*0.7)`. Tôi tự đếm lại: pw 0 = 3/3, pw 1 = 4/3, pw >= 10 = 17/12. Khớp doc.
- 5 con bị cắt từ pw >= 10: bomblet, spikelet, chomper, slime, bugling (top 12 = warden, 4 con cost 8, 2 con cost 7, 3 con cost 6, jellyfin, ravenling). Doc đúng.
- `count(pw)` đúng (`ContentDB.gd:696`). Elite bốc đều 1 key trong `elite_pool` (`:3662`) nên 4 -> 7 đúng.

## CHẶN
1. **Con rẻ không hiện ra ở đầu run như doc nói.** Hoà cost thì con có index pool cao hơn bị cắt trước. Nếu onion (cost 3) và strawberry (cost 4)
   thêm vào cuối `normal_pool`:
   - pw 0: pool 5, bốc 4 con đầu = chomper, strawberry, slime, bugling. Onion bị cắt. Được **4 loại, không phải 5**.
   - pw 1: pool 6, bốc 5 = chomper, strawberry, spikelet, slime, bugling. Onion vẫn bị cắt.
   - pw 2: pool 10, bốc 7. Slime, bugling, onion đều bị cắt; thấy 7 loại (doc ghi 8). Cải thiện thật là 5 -> 7, không phải 6 -> 8.
   Muốn pw 0-1 có 5-6 loại thật thì phải chọn: (a) đặt onion/strawberry lên đầu `normal_pool` + cost ngang slime/bugling,
   hoặc (b) đổi cost sao cho không con nào nằm đáy. Đây là chỉnh DATA, không phải sửa luật bốc. **Không** sửa 0.7 / sort:
   đó mới là hệ thống mới và đổi toàn bộ encounter đã balance ở v5.
   Phải có một test cứng: "ở pw 0, 1, 2 số loại bốc được >= X".
2. **Chưa kiểm được 2 thứ doc nói là "đủ".** Checkout này không có `asset-library/src/.../Character/Monster` (chỉ README + `.DS_Store`)
   và không có `godot/assets/atia/<key>/` (chỉ có `atia_models.json`, `arenas.json`, `atia_model.gd`). Tôi KHÔNG xác nhận được
   (a) clip Idle/Attack/GetHit/Dead của 13 con, (b) 21 model hiện có lấy từ họ nào. Bảng clip trong doc chỉ là danh sách file, chưa ai mở.
   Phải làm trước khi chốt danh sách (doc mục 0 cũng tự nhận). Rủi ro trùng cao nhất: slime, shiitake, jellyfish trong kho vs slime/jellyfin/venomaw hiện có.
   Trong 13 con đề xuất không có slime/jellyfish gốc, nhưng **Shitake** (venomaw) và **Anemone** (jellyfin, vai healer cùng hình họ thủy sinh) cần xem contact sheet.

## NÊN SỬA
1. **Giữa-run loãng.** Từ pw >= 10: 27 con, bốc `ceil(18.9)=19` (thay vì 12/17). Cắt thêm: slime, bugling, onion, chomper, strawberry,
   spikelet, bomblet + 1 trong các con cost 5. Xác suất mỗi con cost cao tụt từ 1/12 xuống 1/19: warden/stalker/pyrewing/cleaver ra ít hơn
   khoảng 37%, nghĩa là mix encounter cuối run đổi (nhiều cost 5-6 hơn). Vì `sc = budget / tổng cost` nên tổng sức mạnh gần như giữ,
   nhưng số đầu quái / loại quái đổi. Cần sim chứ không đoán.
2. **"Mượn khối chỉ số, đổi 1-2 số" mâu thuẫn với "trung tính".** Mượn nguyên khối + cost khác mẫu (vd tanuki 5 mượn ravenling 5 thì ổn, snail 6 mượn thornback 6 ổn,
   nhưng strawberry cost 4 mượn chomper 4, elephant 7 mượn bruiser 7: cùng cost thì ok). Chỉ cần ghi rõ: **cost giữ bằng mẫu, không đổi**, đổi tên/hình/thứ tự mặt.
   Con nào đổi số thì không còn là "mượn". Trait đi theo mẫu (plating/ward/mend), nhớ copy cả field `trait`, `summons`, `elite`.
3. **Mục tiêu sim (dùng `godot/tools/sim_balance.gd`, `--policies=attack_spam,greedy`, cùng seed v5 trước/sau):**
   - Tỉ lệ thắng (attack_spam và greedy) lệch <= 2 điểm % so với baseline v5 ở asc 0, theo từng đoạn stage; không được kéo attack_spam lên lại (anti-spam v5 là chốt).
   - Số trận/run kết thúc và số lượt/trận lệch <= 5%.
   - Đếm: mỗi con mới xuất hiện >= N lần trong 300+ trận ở pw tương ứng (kiểm "có hiện thật"), 3 Elite mới mỗi con ~1/7 số trận elite.
   - Soi riêng cặp elite có `plating` / mage burn (bulwark/archon) vì Elite bốc đều, đổi 4 -> 7 không đổi độ khó trung bình nếu mẫu đúng vai trò.
4. **Test bị ảnh hưởng, ngoài `t_atia_coverage` (cứng 17/4/6, "27 keys" trong comment):** `t_content_expansion`, `t_enemy_traits`, `t_plating`,
   `t_team_can_break`, `t_combat_spacing` (tham chiếu key cứng); các test seed-walk (`t_full_run_loop`, `t_boss_encounters`, `t_replay`) vì RNG ra encounter khác;
   `t_sim_balance_smoke`. `scripts/raid/raid_ghost.gd` cũng nhắc key quái: kiểm ghost raid cũ có vỡ không khi pool đổi (doc không nhắc).
5. **Thứ tự index = một phần của luật.** Comment `ContentDB.gd:25` đã cảnh báo reorder đổi kết quả. Ghi trong spec: con mới chèn ở vị trí nào trong `normal_pool` (ảnh hưởng tie-break).

## RULES_VERSION / fingerprint
- `t_rules_version.gd:21-24`: WATCHED_DIRS gồm `res://autoload` (ContentDB.gd nằm đây), `scripts/core`, `scripts/meta`, `resources/relics`, `assets/data/rules`,
  + `part_faces.json`. Ext .gd/.tres/.json. Doc đúng: đụng ContentDB là bump (hiện -t -> -u) + Worker `SUPPORTED` + deploy Worker.
- `monster_art.gd` (`scripts/data_models`) và `assets/atia/atia_models.json` KHÔNG nằm trong danh sách. Vậy đổi art registry riêng thì không đụng fingerprint;
  chỉ phần data quái + pool trong ContentDB mới bump. Đúng như doc. Đổi số sàn test cùng commit.
- Nên gộp vào cùng bump với lần chỉnh v5 kế tiếp nếu có; nếu không, một bump riêng cũng ổn (Liam đã chấp nhận nhiều lần).

## Dung lượng
+4-6 MB cho 13 model là hợp lý (0,3 MB/model x 13 ~ 4 MB, tex cap 1024), nhưng đây là ước từ audit 16/10, chưa đo model thật. Web đang ~190 MB nên không phải chặn.
Doc nhắc dọn 3 thư mục boss cũ ~3,8 MB để bù: chỉ làm nếu đã chắc không còn ai trỏ tới.

## GỢI Ý
- Hai câu hỏi cho Liam: **câu 2 (bump RULES_VERSION) không cần hỏi**, Liam đã chấp nhận nhiều lần, agent tự quyết gộp bump.
  Chỉ giữ câu 1 (chọn hướng A/B/C) vì A vs B đổi trải nghiệm; hoặc thay bằng câu: "hình có thể lệch tên ở hướng A không".
- Hướng C và đợt 2 "ưu tiên biome chỉ để hiển thị" nên bỏ khỏi doc cho đỡ rối; để lại ghi chú sau beta.
- Sau khi làm: chụp `qa_atia_lineup` + chạy 1 run thật cho thấy pw 0-2 có >= 4 loại, Elite mới ra ở Elite node (bài học relic rework).
- Số lượng 13 hợp lý; không nên nhiều hơn vì cắt 70% làm loãng.

## Vòng 2 (26/10): APPROVE (đủ để sang bước plan), 1 chỗ nên sửa
- **Phép tính 5/5/8/19: đúng.** Tôi tự chạy lại theo `combat_engine.gd:3664-3671` với pool 17 cũ + 9 con mới (min 1,1,1,3,3,6,7,7,8):
  pw 0: pool 6, bốc 5 = gmush, chomper, slime, shitake, snail (cắt bugling). pw 1: pool 7, bốc 5 = gmush, chomper, spikelet, slime, shitake.
  pw 2: pool 11, bốc 8 = 4 con cost 5 + gmush, chomper, spikelet + slime. pw >= 10: pool 26, `ceil(18.2)=19` = 1 (cost 9) + 5 (cost 8) + 4 (cost 7) + 4 (cost 6) + 5 (cost 5);
  cắt 3 con cost 4 + 4 con cost 3. Đủ 19. Ngưỡng `t_pool_diversity` (5/5/8/19) và 26/7 trong `t_atia_coverage` khớp.
- **CHẶN 2 đã đóng đủ cho plan.** Phát hiện Strawberry = spikelet, Onion = broodmaw bằng tex là kết quả thật, và danh sách còn "chưa rõ" được ghi là bước 1 bắt buộc trước import. Chấp nhận.
- **Nên sửa:** con số 5/5 ở pw 0-1 phụ thuộc đúng 3 con cost 3-4, min 1 (gmush, shitake, snail); gmush và snail đang "chưa rõ". Nếu một trong hai trùng và bị bỏ,
  pw 0 tụt còn 4. Ghi rõ trong doc: nếu mất con min-1 nào thì phải có con thay cùng cost/min (hoặc hạ ngưỡng test xuống 4 và nói thẳng với Liam), đừng để test và doc lệch nhau.
- **Lệch nhỏ về RULES_VERSION:** mục 4.6 vẫn viết "bump -t -> -u" trong khi quyết định là gộp vào `-v`. Theo `production/beta-plan.md` Atia bump riêng `-v`: sửa chữ cho khớp (chỉ là câu chữ, không chặn).
- Elite 4 -> 7 và cost giữ bằng mẫu: ổn. Bước sim vẫn bắt buộc, nhất là mix cuối run (19 slot thay 12).
