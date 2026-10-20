# QA plan: dice depth v4 (BỘ, LIỀU/Nứt, MẶT TẠM, Overcast, part hiếm, 5 Lõi chủ, mở dần)

QA lead, 21/10/2026. Trước khi code (shift-left). Đã đọc: `design/gdd/dice-depth-v4.md` (bản nháp 20/10, chưa có code),
`production/depth-v3-contract.md` mục Làn OC + nhánh `depth/OC` (e037166), và đối chiếu `combat_engine.gd`
(`reroll_dice`, `_rerollable`, `_spawn_phantom_dice`, `_state_dict`), `core_hooks.gd` (`c_thorn_shield`),
`action_log.gd`, `run_verifier.gd`, `worker/src/run_core.js`, `worker/src/epoch_args.json`.
(Lưu ý: `epoch_args.json` nằm ở `worker/src/`, không ở `godot/assets/data/rules/`.)

Cách đọc mức: **CHẶN** = không được code/merge tiếp khi chưa sửa. **NẶNG** = phải đóng trước khi build đưa QA tay. **VỪA** = đóng trước release, có test.

Điều kiện chung với Liam (bài học relic "vô hình", overlay Lõi): mọi mục trong ma trận mục 3 đánh dấu **FLOW** phải
có một test đi qua UI như người chơi bấm (bấm nút thật, đọc chữ/ảnh thật trên màn), không chỉ gọi hàm engine.
Xanh 166 test mà người chơi không thấy là chưa xong.

---

## 0. Hai phát hiện đối chiếu code (không phải suy đoán)

1. **Viên thứ 6 ảo KHÔNG có `is_token`.** `_spawn_phantom_dice` copy Axie thật, `hp = 1`, chỉ đánh dấu `custom_state = {"phantom": true, ...}`
   (combat_engine.gd ~594-620). GDD 3.2 loại "viên ảo" nhưng nếu dev lọc theo `is_token` (như Egg/token) thì viên ảo lọt vào
   Bộ, và còn cùng class với viên gốc nên đè lên Concord. Lọc phải theo `custom_state.phantom`.
2. **`c_thorn_shield` đổi khiên thành thorn không trần** (core_hooks.gd ~836-845: `t = shield / 2`, thêm `thorns:t`).
   Bộ nhân khiên (bước 4) rồi Lõi này đổi thành thorn. GDD edge 21 ghi "thorn không bị Bộ nhân" chỉ đúng cho thorn trên mặt;
   đường gián tiếp qua khiên thì bị nhân.

---

## 1. Lỗ hổng luật (adversarial)

Cột "GDD": nếu đã chặn thì ghi mục; "chưa" nghĩa là GDD không nói hoặc nói chưa đủ.

| # | Mức | Kịch bản tái hiện | Cách chặn đề xuất | GDD |
|---|---|---|---|---|
| 1 | **CHẶN** | Làn OC (đã code ở depth/OC) nhân x1.5 SAU `face_final`, ngoài trần +10 (contract OC dòng "áp SAU face_final ... không bị trần đó chặn"). GDD 3.4/3.7 muốn Overcast là `oc_add +0.50` trong túi M. Merge nguyên OC: Bộ năm (x3) + Overcast x1.5 độc lập = mặt dmg 6 đi 21 (M cắt 3.5), 25 (LINK), 33 (Lõi), 43 (cộng phẳng), rồi OC x1.5 thành ~65 chưa tính crit, vượt đỉnh 43 mà GDD tự tính (edge 15). | Sửa OC đọc túi M (đổi `overcast_mult()` thành `oc_add`), xoá nhân x1.5 riêng ở combat_engine.gd ~1501, cập nhật `t_overcast`. Chốt Q1 với Liam trước. | 3.7 và Q1 đã nêu, chưa chốt. Thêm: OC từ chối viên `frozen` và giá trị 0, GDD 3.7 không nói frozen. Chốt một bên. |
| 2 | **CHẶN** | Key `mode` trong `epoch_args.json` là enum `["short","full"]` (dùng cho `run_start`). GDD 3.5 bảo ghi `mode = "free"/"safe"` vào `_reroll_args`. Server từ chối (`code: mode`), mọi reroll online hỏng; hoặc dev nới enum và run_start nhận "free". | Dùng key mới (vd `rmode`, enum `free/safe`, chỉ kind `reroll`), sửa `epoch_args.json` + `t_remote_epoch_ui_run` (fake remote đọc cùng file). Trong ActionLog ghi `mode` dạng int 0/1 như `from_aid` ("canon has no bool", `_restore_ints` giả định arg là id/index/list id). | Chưa. |
| 3 | **NẶNG** | **Liều "nhìn trước rồi đổi ý"**: với relic `safeReroll` (undo qua reroll được, `reroll_k` quay về) người chơi bấm LIỀU, thấy Nứt, undo, bấm AN TOÀN trả 2 mana: cùng seed (server pin theo turn+k) nên cùng mặt, không Nứt. Liều thành quyền chọn có thông tin: chỉ trả mana khi sẽ Nứt (kỳ vọng 0.25 x 2 mana/viên, rẻ hơn nhiều so với giá cắt rủi ro). Tương tự save/load: nếu autosave cho phép nạp lại bản trước reroll thì mọi người đều làm được. | (a) Engine ghi `reroll_mode[k]` trong `_state_dict`, từ chối đổi mode cho cùng `(turn,k)`. (b) Server: khi pin đã có, so `rmode` và `uids` với dòng pin, lệch thì `pin_mismatch`. Hiện server chỉ LƯU `uids` (run_core.js ~314, 344) chứ không so. (c) GDD 3.5 câu "không thể undo để lăn lại" chỉ đúng với `reroll_k` quay về, chưa chặn đổi mode. | Một phần (3.5), chưa đủ. |
| 4 | **NẶNG** | **Fishing seed bằng đổi danh sách viên**: cùng `(turn,k)` seed bị pin, nhưng `uids` không so lại, nên nạp lại save cũ và tung tập viên khác sẽ ra kết quả khác; Nứt làm "kết quả xấu" nhiều dạng hơn nên đáng fish hơn. | Như 3(b): server khoá `uids` theo pin; client engine khoá `uids` đã tung cho `(turn,k)`. Thêm tamper. | Chưa. |
| 5 | **NẶNG** | **Con Bạc**: thưởng `+0.25` mỗi "Liều không Nứt", chỉ cần tung lại 1 viên (65% sạch). Hai lần tung 1 viên xấu ngoài Bộ = 42% có +0.50 cho MỌI Bộ cả lượt, rủi ro chỉ trên 1 viên đã không dùng được. Tối ưu thành "Liều 1 viên rác" hai lần, không phải đặt cược thật. | Chỉ tính "Liều sạch" khi số viên tung lại >= 2 (hoặc >= số viên trong Bộ -1), hoặc thưởng tỉ lệ số viên tung lại. Đưa vào sim Lõi này riêng. | Mục 10.2 nói "tối đa +0.50", không nói số viên. Chưa. |
| 6 | **NẶNG** | **Tam Tấu nổ nhiều lần**: "một lần mỗi Bộ mỗi lượt", nhưng Bộ chụp lại sau reroll (ba Sừng thành bốn Sừng). Nếu coi là Bộ mới thì nổ hai lần (ba 35% rồi bốn 70%). Nổ `src = null` đi qua `DamagePipeline`: thiếu null-guard ở thorn/spite/`on_kill`/relic hook sẽ crash (lỗi S1). Cap 20 mỗi quái chặn trước hay sau pipeline (vulnerable, crit-boss, mod_dmg nhân thêm) cũng chưa nói. | Định nghĩa: mỗi lượt tối đa một vụ nổ mỗi part (hoặc một vụ mỗi lượt), lưu cờ trong `_state_dict`. Cap áp SAU pipeline. Test với `src = null` đi qua mọi hook `on_kill/on_hit`. | Chưa (10.1 chỉ nói "một lần mỗi Bộ"). |
| 7 | **NẶNG** | **Khiên Bộ thành thorn không trần** (phát hiện #2 ở mục 0): Bộ năm khiên x3, Lõi `c_thorn_shield` đổi khiên thành thorn vô trần, boss/elite thorn-phản đòn. Cộng Rebound (dồn thorn). | Chọn một: cap thorn do `c_thorn_shield` tạo ra, hoặc `c_thorn_shield` đọc khiên GỐC trước M, hoặc ghi chấp nhận kèm số sim. Thêm vào danh sách tổ hợp cấm của sim. | Chưa (edge 21 sai về đường gián tiếp). |
| 8 | **NẶNG** | **Poison nhân Bộ**: M áp lên `poison value` (3.4). Poison cộng dồn nhiều lượt; Bộ năm x3 + Overcast +cộng phẳng R12 (Vỏ Cứng +2 trước M) tạo stack lớn một lần dùng. Không thấy cap poison trong `combat_tune.json` (chỉ `thorns.cap = 0`). | Đo trong sim: tổng damage poison/lượt tối đa; cân nhắc `M` không áp poison hoặc cap stack theo act. | Chưa. |
| 9 | **NẶNG** | **Aid reroll bỏ qua Liều và `max_total`** (3.5: Aid "như hiện tại", không Nứt). Aid là tài nguyên meta mua được; Liam 11/10 định bán giải pháp (P2W trong ranked). Aid reroll = Bộ không Nứt, không tốn mana, không tính `reroll_nonaid`. | Liam quyết: Aid có tính vào cap tổng, tối đa X lần mỗi lượt/trận không; Aid có áp Nứt không. | Chưa. Câu hỏi mới (mục 4). |
| 10 | **NẶNG** | **Viên ảo Sixth Die lọt Bộ** (mục 0 #1). Ảo copy class thật nên cũng phá luật Concord "một viên mỗi class" nếu đếm. Viên ảo còn tung lại và Overcast được (GDD 3.7 chỉ cấm token). | Lọc theo `custom_state.phantom` ở `recompute_bo`, `wild_face`, `overcast` (hay chốt Overcast ảo được hay không). `bo.phantom_counts = 0` phải được test cả hai chiều. | 3.2 chặn đúng ý; cách lọc chưa nói. |
| 11 | **NẶNG** | **Mặt Tạm lên viên không đếm do Concord**: Concord cho mỗi class một viên đếm. Viên bị loại gắn Mặt Tạm (slot bất kỳ) có đếm lại không? Nếu có thì Mặt Tạm đi vòng qua Concord (Bộ ba ra từ ba viên cùng class). | Viên bị loại bởi Concord không nhận Mặt Tạm (từ chối, không tốn mana), và `recompute_bo` kiểm Concord SAU khi áp `wild_slot`. | Chưa. |
| 12 | **NẶNG** | **Ghost raid không phải "không có lượt người chơi"**: ghost chỉ thay `enemies` (combat_engine.gd ~227-232); người tấn công vẫn chơi bằng đội của mình, nên Bộ áp lên người tấn công, và quái ghost (phe "e") dùng AI cũ. GDD edge 30 và dependency "raid đặt `bo.enabled = 0`" dựa trên tiền đề sai, và `bo.enabled=0` sẽ làm raid yếu đi so với trận thường. | Hỏi làn RV: raid dùng Bộ hay không. Nếu có: kiểm sim độ khó ghost; nếu không: test `bo.enabled=0` chỉ cho raid. | Sai tiền đề, cần sửa GDD. |
| 13 | **NẶNG** | **Mỏ Mana vòng mana**: cờ `mana_bo_paid` mỗi lượt. Nếu cờ không nằm trong `_state_dict`/ảnh undo, thì undo (hoàn mana) rồi dựng lại Bộ = nhận +1 lần nữa; save/load giữa lượt cũng reset cờ. Mặt Tạm đã loại khỏi trả +1 nhưng `tweak/loaded_pick` tạo Bộ tự nhiên mới vẫn trả. | Cờ vào state/undo/save. Test undo-redo 20 vòng, mana không tăng ròng. | Chặn một phần (mục 10.3, 5.33). |
| 14 | VỪA | **Mana âm / tràn**: `reroll_dice` hiện check `mana >= hook_cost + paid` rồi mới trừ (đúng); wild/OC phải giống. Rủi ro: Mỏ Mana giảm giá OC còn 2, hook `reroll_mana_cost` giảm giá (có thể âm = tăng mana?), relic "rút mana"; `maxi(0,...)` chỉ có ở `reroll_mana_cost`. Mana không có trần được nêu: Mỏ Mana +1/lượt cộng với faucet khác. | Mọi giá qua `maxi(0)`; mọi action check trước khi đổi state; test property: mana không < 0 và không đổi khi action trả false. Ghi trần mana nếu có. | Edge 12 đã chặn âm; trần chưa nói. |
| 15 | VỪA | **Concord (Đồng Tâm) với BỘ**: viên đếm là "đủ điều kiện đứng đầu `party`". Nứt viên được đếm thì viên kế tiếp thành viên đếm: đổi nhóm không báo. Đồng Tộc + Concord: GDD chỉ chặn ở pool Lõi chủ, nhưng Concord có thể nhận GIỮA run từ offer Lõi/relic. | Test `t_bo_concord` thêm kịch bản Nứt viên đếm. Chặn cả chiều ngược: offer Concord bị lọc khi đã có Đồng Tộc. | 3.2/31 một phần. |
| 16 | VỪA | **Hold làm "máy rửa Nứt"**: Hold viên bị Nứt, lượt sau mặt cũ, hết Nứt (3.5), giá trị đầy đủ lại. Giá là mất lượt dùng viên đó, nhưng với viên mặt mạnh thì rẻ hơn mất nửa giá trị. Hold anchor (Giữ Lửa 2 viên cùng part mang sang) tăng xác suất Bộ lượt sau: 2 viên sẵn cùng part có P(ba+) ~ 42-45% trước reroll. | Chấp nhận có ghi, hoặc viên Nứt không Hold được. Sim phải có bot Hold-anchor. | Edge 23/34 gần đúng, chưa nói rửa Nứt. |
| 17 | VỪA | **Thứ tự Mặt Tạm rồi reroll**: GDD 4.2 tính Mặt Tạm "nâng đúng một bậc" trước reroll, nhưng gắn Mặt Tạm TRƯỚC khi tung lại (khoá viên đó làm neo) rồi tung lại phần còn lại cho kết quả cao hơn bảng 4.2. | Bot sim phải thử cả hai thứ tự. Nếu quá mạnh: Mặt Tạm chỉ cho khi `reroll_k` đã hết, hoặc gỡ khi reroll. | Chưa. |
| 18 | VỪA | **Overcast rồi reroll cùng viên**: GDD 3.7 không nói cờ Overcast có mất khi viên được tung lại. Hiện `_rerollable` (combat_engine.gd 943) không loại viên Overcast. Overcast giữ trên mặt mới (nhân thứ mình chọn sau khi biết kết quả) hoặc rơi vào mặt mana (lãng phí 3 mana, vô hình với người chơi). | Chốt: viên Overcast không tung lại được (giống Mặt Tạm), UI nói rõ. Test mỗi chiều. | Chưa. |
| 19 | VỪA | **Mặt Tạm slot = Tai / viên Tai không cantrip**: Tai gần như luôn cantrip nên không bao giờ nằm lại; nhưng Mặt Tạm chọn slot Tai tạo "Bộ Tai". Nếu một class có Tai non-cantrip (GDD 4.2 thừa nhận "gần như"), ba viên Tai thật nằm trên bàn là Bộ mana: không nhân, nhưng Mỏ Mana +1 mana khi có Bộ tự nhiên = farm mana. | UI chỉ gợi ý slot hợp lệ; Mỏ Mana chỉ tính Bộ có ít nhất một mặt nhân được. Test mọi class có part Tai non-cantrip. | Chưa. |
| 20 | VỪA | **Egg/token nở giữa lượt**: Egg nở thành Axie thật (hp>0, đã tung) sau lần chụp Bộ; lần `recompute_bo` kế (reroll) đếm Axie vừa nở. | Chấp nhận (nở là đáng thưởng) nhưng có test và ghi rõ; hoặc cờ `hatched_this_turn`. | 3.2 loại token; trạng thái sau nở chưa nói. |
| 21 | VỪA | **Mặt đổi sau chụp Bộ**: 3.3 chỉ recompute sau lệnh relic. Mọi chỗ khác ghi mặt viên (chaos reroll, hiệu ứng đổi mặt khi dùng viên, `face_swap`, Loaded) không làm `bo` mới, nên viên đã đổi thành mana/khiên vẫn nhận M của nhóm cũ, hoặc ngược lại. | Grep mọi writer của `current_face`/`roll_face_index` ngoài `roll_all/reroll/relic edit`; thêm recompute hoặc ghi danh sách chấp nhận. Test `t_bo_timing` có case "mặt đổi bởi hiệu ứng". | 3.3 liệt kê 4 thời điểm; chưa quét hết writer. |
| 22 | VỪA | **Free reroll tích luỹ**: `rerolls` cộng thêm từ relic/Chaos (`relic_reroll_given`, `chaos_reroll_given`) đi qua `rerolls`, KHÔNG qua `max_total` (3.5). Nhiều relic => 4-5 lần an toàn => Bộ ~90%, vượt bảng 4.2. | Cap cứng số lần an toàn mỗi lượt (đã có "reroll caps" ở RULES -f, kiểm lại sau khi `max_total` thành 3). Test cộng đủ relic. | Chưa. |
| 23 | VỪA | **Hold/viên đã dùng làm mỏ neo Bộ**: viên đã dùng vẫn đếm; dùng viên yếu trước làm "neo" rồi tung lại các viên còn lại để lên Bộ. Chủ ý theo GDD (edge 8) nhưng cần số sim. | Chỉ theo dõi: số liệu lượt Expert dùng neo. | Edge 8 chấp nhận. |
| 24 | **NẶNG** | **depth_stage bị khai gian (anti-cheat)**: stage nằm trong header client gửi; Worker KHÔNG chạy luật ("It never runs game rules", run_core.js đầu file). Khai stage 3 để có Lõi chủ trong ranked. Tương tự cờ `newcomer` hiện có. | Worker tự tính stage từ meta tài khoản (mirror `newcomer()`), so với header; hoặc ranked chỉ nhận stage tính server. Verifier phía client từ chối action cần stage cao hơn header. | Dependencies nêu "Worker cần biết stage" (Q7), chưa chốt. |
| 25 | VỪA | **`first_boss_won`/`runs_with_battle` mất hoặc lệch**: guest, đăng nhập tài khoản khác máy, xoá save, cloud-save conflict làm người cũ về stage 1 hoặc người mới lên stage 3. Quên `MetaState.reload_from_store()` (CLAUDE.md gốc). | Test đi qua `SaveStore`: ghi, reload, đổi tài khoản; field mới có trong `reload_from_store`. Chốt khi conflict: lấy giá trị lớn hơn. | 3.8 nêu migrate; conflict chưa nói. |
| 26 | VỪA | **Làm tròn / M<1**: Đồng Tộc -0.25 và core_add âm; Mỏ Mana mặt mana -1 "tối thiểu 1"; M luôn >= 1.00 (chỉ Đồng Tộc nói). Số nguyên `(v*M100+99)/100` với v=0 cho 0 nhưng `v>=1` Nứt phải còn >=1. | Test biên: v=0,1,2; M100 = 100..350; Nứt rồi nhân. | Công thức có, biên chưa. |

Tổng: 26 mục. CHẶN 2, NẶNG 12 (3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 24), VỪA 12.

---

## 2. Anti-cheat / replay

Hiện trạng đã kiểm: Worker chỉ cấp seed theo `(battle, attempt, turn, k)`, pin seed cho cùng khoá, ghi `uids` nhưng không so; không chạy luật.
Run được tái hiện bởi `RunVerifier` phía client từ action log (+ chuỗi hash). Hệ quả: bất cứ thứ gì Worker không kiểm
và không nằm trong seed thì client khai gì cũng được; verifier chỉ cho biết log tự nhất quán.

| Hạng mục | Trạng thái GDD | Việc cần làm |
|---|---|---|
| Nứt lấy từ seed server | CÓ (3.5: "rút `_rng.next_int(100)` từ chính luồng seed của lần reroll đó ... client không tự rút", sau `_resolve_cantrips`, một số mỗi viên theo thứ tự uid, luôn rút đủ). | Test: thứ tự rút cố định dù viên chết/không tung; replay ra cùng Nứt. Không dùng `randi()`/`randf()` toàn cục ở bất cứ chỗ mới nào (grep trong PR). |
| Mọi ngẫu nhiên mới | GDD chỉ có Nứt, 5 Lõi chủ rút "bằng seed của run" (mục 10), Tam Tấu/Mỏ Mana không ngẫu nhiên. | Xác nhận Lõi chủ rút từ `run_start` seed hoặc epoch kind mới (vì `epoch_args.json` đóng từ vựng, kind mới cần thêm). Chưa rõ: GDD không nói kind nào. Phải sửa. |
| `mode` vào args | 3.5 nói có; xung đột với enum `mode` (lỗ hổng 2) | key mới `rmode`; `epoch_args.json` + fake remote + `KINDS` |
| Khoá `(rmode, uids)` theo pin | KHÔNG | server so với dòng pin, lỗ hổng 3-4 |
| Action mới `wild_face`, `overcast` | GDD edge 11 nói vào ActionLog; chưa nêu ALLOWED_FNS | Thêm vào **3 chỗ**: `ActionLog.ALLOWED_FNS` (action_log.gd:75), `ALLOWED_FNS` trong `worker/src/run_core.js:21`, và nhánh `match` trong `run_verifier.gd` (~255-275; hiện chưa có `overcast`/`wild_face`, nhánh `reroll_dice` chỉ đọc `args[0]`,`args[1]`, phải đọc `args[2]` = mode). Ba bản cùng một commit; thêm tên vào danh sách chú thích đầu `action_log.gd`. |
| Dòng 161 của verifier | `"use_die", "play_active", "reroll_dice", ... "stash"` là danh sách action đi qua đường "cần engine" | thêm `wild_face`, `overcast` |
| `RULES_VERSION` | GDD nêu bump | Bump (hiện `...-o`) + `t_rules_version` chỉ bắt ở cây chính, worktree dùng `AXIE_SKIP_RULES_FINGERPRINT=1`: bắt buộc chạy một lần ở cây chính trước merge. Deploy Worker hỏi Liam. |
| `depth_stage` | header ActionLog | xem lỗ hổng 24 |
| Header `newcomer` | đã có | `depth_stage` đi cùng chỗ |

**Tamper bắt buộc** (bổ sung vào 7 tamper cũ của `t_replay`, mỗi cái phải bị bắt đúng chỗ, không "mất tích"):
T1 đổi `mode` safe thành free (hoặc ngược lại) ở một reroll; T2 đổi `slot` của `wild_face`; T3 `wild_face` thừa (lần 2 trong lượt);
T4 `overcast` lên viên mặt mana; T5 `overcast`/`wild_face` khi mana thiếu; T6 chèn `wild_face` vào run stage 1 (header stage 1); T7 sửa header `depth_stage` lên 3;
T8 xoá một `wild_face` khỏi log (digest lệch); T9 đổi `uids` của reroll sau Liều (Nứt khác); T10 Aid reroll giả (`from_aid=1` mà không có ledger Aid).
Mỗi tamper: assert RunVerifier báo lệch VÀ lệch tại action đó (không chỉ "digest cuối khác").

---

## 3. Ma trận test bắt buộc

Loại: U = unit, I = integration, UI = giao diện, **FLOW** = đi qua UI như người chơi bấm (kiểu real-flow smoke đã bắt lỗi overlay Lõi). Mọi test mới thêm vào `godot/tools/run_tests.sh`; đổi con số sàn ở `technical-preferences.md` cùng commit.

### 3.1 Test GDD đã liệt kê (mục 8.1), kèm assert chính

| Test id | Loại | GDD | Assert chính |
|---|---|---|---|
| `t_bo_groups` | U | 3.2, edge 1-5, 25-27 | nhóm theo `fi`; 3/4/5; Nứt/blank/chết/ngủ/sideline/token/Egg/**viên ảo (lọc theo `custom_state.phantom`, không `is_token`)** không đếm; đã dùng, Hold, frozen, heavy, `reroll_allowed=false` có đếm; 0-2 viên không Bộ |
| `t_bo_timing` | U | 3.3 | `bo` chỉ đổi ở 4 thời điểm; use_die/chết/Hold/hồi sinh không đổi; chụp sau cantrip; **mặt bị đổi bởi hiệu ứng khác** (lỗ hổng 21) |
| `t_bo_order` | U | 3.4, 4.1 | số cụ thể bước 1-8; 5x1.5=8, 4x2=8, 3x1.5=5; trần 3.5; +10, +8 không đổi; mặt mana/debuff/summon không nhân; thorn trên mặt không nhân; **thorn từ `c_thorn_shield` ghi số thực** (lỗ hổng 7); biên v=0,1,2 |
| `t_crack` | U | 3.5 | chỉ viên vừa tung lại ở Liều; không Nứt ở free/An toàn/Aid; ceil(v/2), v>=1 còn >=1; Nứt ra khỏi Bộ; hết ở `roll_all`; Hold không mang Nứt; luôn rút đủ 1 số/viên (so vị trí RNG sau reroll khi một viên chết) |
| `t_reroll_modes` | U | 3.5 | chọn kiểu theo `rerolls`; `max_total=3`; giá 2 + hook; stage 1 `mode=free` trả false state không đổi; relic free reroll cộng thêm có cap (lỗ hổng 22) |
| `t_wild_face` | U | 3.6, edge 6-7 | giá 2, 1/lượt; từ chối đã dùng/Hold/Nứt/cantrip/token/**viên ảo**/slot=part thật/part đã đủ 5/n<3; khoá reroll+Hold hai chiều; hết hiệu lực lượt sau; hiệu ứng mặt nguyên; mana không âm; **viên bị Concord loại bị từ chối** (lỗ hổng 11) |
| `t_bo_overcast` | U | 3.7, edge 14 | bốn+OC = M 2.50 (không 3.0); OC+Mặt Tạm cùng viên = 2.00 với Bộ ba; mặt mana không áp; năm+OC+part hiếm cắt 3.5; **không còn nhân x1.5 sau `face_final`** (lỗ hổng 1); OC + reroll (lỗ hổng 18) |
| `t_bo_concord` | U | 3.2, edge 24 | mỗi class một viên đếm; thứ tự `party`; Nứt viên đếm chuyển cho viên kế; sau reroll vẫn đúng |
| `t_bo_undo` | U | edge 9 | undo giữ `bo`, Nứt, `wild_slot`, `overcast`, `wild_used`, mana, **`mana_bo_paid`**; `safeReroll` undo ra cùng kết quả; **đổi mode cùng `k` bị từ chối** (lỗ hổng 3) |
| `t_bo_saveload` | I | edge 10 | digest trước/sau save-load tại MỖI action của một lượt có Bộ+Nứt+Mặt Tạm+OC (fuzz mỗi bước); `bo` đọc từ save không tính lại; `reroll_k`, `reroll_nonaid`, `depth_stage` giữ |
| `t_bo_replay` | I | edge 11 | RunVerifier replay run có Bộ, Liều, Mặt Tạm, OC ra cùng digest; mọi tamper T1-T10 bắt đúng chỗ |
| `t_bo_stage` | I | 3.8 | `depth_stage` 1/2/3 từ meta; tài khoản cũ (`runs_with_battle>=5`) thẳng stage 3; đóng băng giữa run (thắng boss không mở); action cao ở stage thấp trả false; qua `SaveStore` + `reload_from_store` (lỗ hổng 25) |
| `t_core_keystones` | U | 10 | số + thời điểm + giới hạn một lần cho từng Lõi chủ; Tam Tấu cap sau pipeline, một vụ mỗi lượt, `src=null` không crash qua mọi hook; Con Bạc cần >=2 viên (nếu chốt); Mỏ Mana `mana_bo_paid`; Đồng Tộc không rút khi có Concord, hai chiều; Giữ Lửa cap 2, không Hold lại viên vừa mang |
| `t_rule_text_from_knobs` | U | 7.1 | câu luật sinh từ knob; đổi knob đổi chữ |
| `t_rules_version` | U | 6 | xanh ở cây chính sau bump |

### 3.2 Test bổ sung QA đề xuất (còn thiếu trong GDD)

| Test id | Loại | GDD/lỗ hổng | Assert chính |
|---|---|---|---|
| `t_bo_property_fuzz` | U | mọi | 200 seed x chuỗi action ngẫu nhiên hợp lệ: mana >= 0; M trong [1, 3.5]; action false không đổi digest; `bo` trùng `recompute_bo()` ngay sau 4 thời điểm; digest live == replay == save-load mỗi bước |
| `t_bo_stacking_ceiling` | U | edge 15, lỗ hổng 1,7,8 | tổ hợp xấu nhất (Bộ năm + OC + part hiếm + Lõi x1.5 + LINK + cộng phẳng + crit) không vượt trần ghi trong GDD; poison/thorn đỉnh |
| `t_reroll_epoch_pin` | I | lỗ hổng 2-4 | fake remote từ chối `rmode` sai, từ chối `(turn,k)` cũ với `rmode`/`uids` khác; pin trả cùng seed |
| `t_depth_epoch_args_contract` | U | lỗ hổng 2 | `epoch_args.json` có `rmode`; `mode` giữ enum short/full; Worker `node --test` thêm case |
| `t_bo_raid` | I | lỗ hổng 12 | đặt theo quyết định RV: raid có/không Bộ, chạy hết một trận ghost |
| `t_hold_crack_cleanse` | U | lỗ hổng 16 | Hold viên Nứt: lượt sau sạch Nứt, ghi nhận hành vi theo quyết định |
| `t_aid_reroll_depth` | U | lỗ hổng 9 | Aid reroll theo luật Liam chốt |
| `t_worker_stage_mirror` (Worker) | U | lỗ hổng 24 | Worker tính stage từ meta, từ chối header lệch |

### 3.3 Test LUỒNG THẬT (FLOW) bắt buộc (đi qua UI, như người chơi bấm)

Cách làm theo mẫu real-flow smoke của `fix/core-overlay` (dựng cảnh trận thật, đẩy input qua nút, không gọi engine trực tiếp để "đặt" kết quả; dùng seed cố định chọn trước để ra tình huống). Mỗi test chụp 1920x1080 và 1280x720 vào `production/qa/evidence/`, và `t_ui_laws` xanh.

| Test id | Loại | Người chơi làm gì | Assert (nhìn thấy được) |
|---|---|---|---|
| `t_flow_bo_visible` | FLOW | Vào trận đầu, tung, seed cho ra 3 Sừng | chip part hiện trên MỌI viên; viền nhóm + thanh nối; banner "BA SỪNG x1.5!" xuất hiện trong <= 0.5s và đủ 0.6s; số trên viên đổi "5 -> 8" khớp `preview_damage`; dòng log đúng; bấm viên rồi mục tiêu thì sát thương thật = số hiển thị. Nhóm đôi: nét đứt + "ĐÔI, cần thêm 1"; token/viên ảo không có viền |
| `t_flow_bo_upgrade` | FLOW | Tung lại bấm nút "TUNG LẠI (miễn phí)" từ Bộ ba lên bốn | banner mới "BỐN SỪNG x2!"; số nhảy lên; hết lần miễn phí thì nút đổi |
| `t_flow_liều_crack_pct` | FLOW | Stage 2, hết lần miễn phí, chọn 2 viên | HAI nút "LIỀU" và "AN TOÀN 2"; dòng phụ "ít nhất 1 viên Nứt: 44%" đổi theo số viên chọn (1: 25%, 2: 44%, 3: 58%); AN TOÀN xám + lý do "cần 2 mana" khi mana <2; bấm Liều: viên Nứt có hình vết nứt + chip "1/2", số đã giảm, rời viền nhóm, tooltip đúng chữ; `reroll_k` đúng; chữ % khớp `crack.pct` đổi bằng knob |
| `t_flow_wild_face` | FLOW | Có đôi + >=2 mana; bấm MẶT TẠM, bấm viên, xem 6 chip | các viên hợp lệ sáng, viên không hợp lệ không; mỗi chip có "-> BỘ BA x1.5" / "không đổi" đúng; bấm chip xác nhận (không hộp thứ hai); huy hiệu "?" + glyph part, khoá icon tung lại; mana -2; nút xám "đã dùng lượt này" (1/1); Undo hoàn mana và gỡ huy hiệu |
| `t_flow_overcast_bo` | FLOW | Có Bộ ba, bấm OVERCAST 3, chọn viên trong Bộ | preview "5 -> 10" (túi cộng M 2.0, không 11.25); sau khi dùng sát thương thật bằng số đó; mặt mana: nút xám "không áp lên mặt mana"; Overcast + Mặt Tạm cùng viên; Overcast + Nứt |
| `t_flow_keystone_pick` | FLOW | Stage 3, bắt đầu run | màn ba thẻ hiện TRƯỚC node đầu; mỗi thẻ có tên, glyph, câu một dòng, ví dụ, nhãn "hợp với"; không bấm chọn thì không đi tiếp (bắt buộc chọn); chọn xong Lõi hiện trong HUD/rail và hiệu ứng có thật khi chơi (ví dụ Tam Tấu nổ thấy được số trên quái, không chỉ trong log); sau lưu/nạp run vẫn còn Lõi; chạy đủ 5 Lõi. (Đây là đúng loại lỗi của overlay Lõi.) |
| `t_flow_newcomer_gating` | FLOW | Tài khoản mới (stage 1) chơi trận 1; sau đó bơm meta lên stage 2, stage 3 | stage 1: có BỘ + chip part, KHÔNG có nút Liều/Mặt Tạm/Overcast, KHÔNG có chip Lõi chủ, chỉ có "TUNG LẠI THÊM: 2 mana"; coach C1-C4 xuất hiện đúng sự kiện, một bong bóng cùng lúc, không chặn bấm, mỗi cái một lần cho cả tài khoản (cờ META), có nút bỏ; stage 2: có Liều/Mặt Tạm/Overcast, chưa có Lõi chủ, coach C5-C7; stage 3: có màn Lõi chủ; thắng boss act 1 giữa run KHÔNG mở ngay, màn kết hiện "Mới mở"; run sau mở; tài khoản cũ `runs_with_battle>=5` vào thẳng stage 3. Kiểm thêm Codex: trang "Luật xúc xắc" khoá phần chưa mở |
| `t_flow_cheat_stage` | FLOW | Gửi action stage cao ở stage thấp qua đường UI bị khoá (gọi trực tiếp) | engine trả false, không đổi state, UI không báo lỗi lạ |
| `t_flow_online_reroll` | FLOW | Bản online (fake remote) bấm Liều rồi An toàn qua UI | `request_reroll_dice` gửi `rmode` đúng; kết quả Nứt khớp seed; mất mạng/`pin_mismatch` hiện thông báo, không treo (no hung tasks) |
| `t_flow_run_replay` | FLOW | Chơi trọn một run bằng nút (bot bấm UI) có Bộ/Liều/Mặt Tạm/OC/Lõi chủ, rồi `RunVerifier` | 0 lệch; kết quả cuối khớp |

---

## 4. Câu hỏi / khoảng trống trong GDD (designer sửa TRƯỚC khi code)

| # | Khoảng trống | Đề xuất |
|---|---|---|
| G1 | Overcast cộng hay nhân (Q1) đang mâu thuẫn với code OC đã viết (nhân sau `face_final`). Chặn merge OC. | Chốt cộng vào túi M; yêu cầu làn OC sửa; GDD ghi rõ OC từ chối `frozen`/giá trị 0 hay không |
| G2 | Seed/args cho `mode`: GDD không nhận ra xung đột với enum `mode` trong `epoch_args.json`; không nói `uids`/`rmode` có bị khoá theo pin. | Thêm mục "Epoch" vào 3.5: key `rmode`, server so `rmode+uids` với pin |
| G3 | Chống nhìn-trước-đổi-ý (Liều rồi undo/save-load rồi An toàn): GDD khẳng định đã chặn nhưng chỉ chặn đường `reroll_k` quay về. | Ghi luật: mode khoá theo `(turn,k)`; Liều là điểm không quay lại kể cả với `safeReroll` hoặc cho `safeReroll` tách riêng |
| G4 | Aid reroll: có áp Nứt/`max_total` không; có giới hạn mỗi lượt không (liên quan bán Aid, P2W ranked). | Liam quyết; đề xuất Aid cũng tính vào cap tổng 3 lần |
| G5 | Ghost raid: tiền đề "không có lượt người chơi" sai. | Hỏi RV; đề xuất raid giữ Bộ (người tấn công vẫn chơi) hoặc `bo.enabled=0` có chủ ý + sim |
| G6 | Viên ảo: lọc theo `custom_state.phantom` (không `is_token`); Overcast/reroll viên ảo cho hay không. | Viên ảo: không Mặt Tạm, không Overcast, có tung lại (như nay) |
| G7 | Mặt Tạm + Concord: viên bị Concord loại có nhận Mặt Tạm không. | Từ chối, hoặc Concord chạy SAU Mặt Tạm |
| G8 | Overcast + reroll: viên Overcast tung lại được không; Overcast có Hold-loại-trừ hai chiều. | Viên Overcast không tung lại (như Mặt Tạm) |
| G9 | Tam Tấu: "một Bộ" sau lên bậc; cap trước/sau pipeline; `src=null` an toàn; "mọi loại có số" gồm mana/Nứt không. | Mỗi lượt một vụ nổ; cap sau pipeline; chỉ cộng dmg/shield/heal/poison, tính giá trị sau Nứt hay gốc phải ghi |
| G10 | Con Bạc: số viên tung lại tối thiểu để tính "Liều sạch". | >= 2 viên |
| G11 | `c_thorn_shield`/poison nhân Bộ (lỗ hổng 7, 8). | Cap hoặc đọc giá trị gốc; ghi số sim chấp nhận |
| G12 | Mỏ Mana: `mana_bo_paid` trong state/undo/save; Bộ chỉ toàn mặt không nhân (Tai) có trả mana không; trần mana. | Cờ vào `_state_dict`; Bộ phải có >=1 mặt nhân được |
| G13 | Lõi chủ rút bằng "seed của run": epoch kind nào (từ vựng đóng). | Thêm kind (`keystone`) vào `epoch_args.json`, hoặc rút từ `run_start` |
| G14 | Stage khai gian: Worker không chạy luật nên ai bảo đảm stage? | Worker mirror `newcomer()`/stage từ meta; ranked kiểm header |
| G15 | Lõi chủ cấp GIỮA run (relic/offer) lọc Đồng Tộc vs Concord hai chiều; hiện chỉ lọc pool đầu run. | Lọc ở `core_offer` cả hai chiều |
| G16 | Hold viên Nứt rửa Nứt; Hold neo. | Chấp nhận có ghi, kèm sim |
| G17 | Giới hạn tổng số lần tung lại an toàn gồm relic (`rerolls` ngoài `max_total`). | Cap tổng cứng mỗi lượt |
| G18 | Mất/lệch `first_boss_won` khi guest/đổi máy/xung đột cloud. | Lấy max; test qua `SaveStore` |
| G19 | Bảng xác suất 4.2 là xấp xỉ (nói thẳng trong GDD), nhưng tiêu chí 8.2 cần "khớp ±2 điểm". | Test engine đếm chính xác (liệt kê 6^5/5^5) cho lần tung đầu và Monte Carlo 1e6 cho phần reroll, hoặc nới ngưỡng xấp xỉ |
| G20 | GDD ghi "Chưa có dòng code nào" nhưng Overcast đã code ở depth/OC; backlink `depth-v3-design.md`, `onboarding-tutorial.md`, `systems-index.md`, spec OC chưa thêm. | Cập nhật trạng thái; thêm backlink (rule bidirectional) |
| G21 | Mục 8 (Acceptance) có thang sim nhưng thiếu tiêu chí tự động cho UI (đủ 8 section: mục 8 có, nhưng "Cảm giác ra Bộ trong 0.5s" không đo được). | Đo bằng thời gian giữa emit sự kiện Bộ và hiện banner, test trên FLOW |

---

## 5. Tiêu chí "xong" (definition of done) cho đợt này

Bắt buộc đạt TẤT CẢ trước khi báo Liam, và có agent senior KHÁC người làm audit lại (quy tắc 11/10):

1. **Chặn đóng:** lỗ hổng 1 (OC vào túi M) và 2 (`rmode`) đã sửa, có test; G1-G14 GDD đã được designer + Liam chốt bằng chữ (không "xem sau").
2. **Mọi lỗ hổng NẶNG** (3-13, 24) có test xanh hoặc quyết định ghi chấp nhận của Liam kèm số sim. VỪA có test hoặc ghi chú trong GDD.
3. **Ma trận 3.1 + 3.2 xanh**, và `godot/tools/run_tests.sh` = số sàn mới (đo thật, đổi `technical-preferences.md` cùng commit); Worker `node --test` xanh (thêm case `rmode`, pin mismatch, stage mirror); `--import` chạy trước (parse error làm headless treo).
4. **Mọi FLOW test ở 3.3 xanh**, có ảnh 1920x1080 và 1280x720 trong `production/qa/evidence/` và Liam hoặc UX lead xem ảnh. Một lượt **smoke chơi thật bằng tay** do người (không bot) chạy: run 1 stage 1, run stage 2, run stage 3 mỗi Lõi chủ một lần, kiểm không có thứ "vô hình" (mọi hệ số, chip, nút trong GDD mục 9 thấy được trong màn thật).
5. **Anti-cheat:** `ALLOWED_FNS` ở cả ba chỗ khớp nhau (có test so sánh danh sách), tamper T1-T10 bị bắt, `t_replay` 7 tamper cũ vẫn bị bắt đúng chỗ, `RULES_VERSION` bumped và `t_rules_version` xanh ở cây chính. Deploy Worker chỉ sau khi Liam bảo.
6. **Sim** (mục 8.2) đạt, gồm bot thử các lối khai thác ở lỗ hổng 5, 16, 17 (neo, Liều 1 viên, Mặt Tạm trước reroll); chênh winrate giữa Lõi chủ <= 5 điểm. Chưa sim thì chưa merge UI (GDD mục 12: sim trước UI).
7. **Playtest** mục 8.3: 6/8 người mới nói được "Bộ là gì"; 0 lệch replay trong 200 run; 0 NaN/undefined trên số hệ số (`t_ui_laws`).
8. **Không S1/S2 mở.** Mọi bug tìm ra ghi vào `production/qa/bugs/` theo `/bug-report`, S1-S2 sửa xong và có test hồi quy.
9. **Save thật không bị chạm:** chạy test ở worktree/`with_lock.sh` (override.cfg), không hang, không gọi mạng thật.
10. Không commit/push/deploy khi Liam chưa bảo.

---

## Việc QA làm tiếp (nếu Liam duyệt)

- Gửi mục 1-4 cho designer; chờ chốt G1-G14.
- Viết sườn test (chưa code engine) cho `t_bo_groups`, `t_bo_order`, `t_crack`, `t_reroll_epoch_pin`, `t_flow_*` để dev code theo test.
- Nhờ làn RV trả lời G5; hỏi làn Worker về G2/G14.
