# QA plan: Anchor MVP (QA trước code)

Ngày 21/10/2026. Người viết: qa-lead. Chưa sửa code, chưa commit. Nguồn: `design/proposals/mutation-and-keystones-v1.md` (kể cả hai ghi chú reviewer và "Liam chốt 23/10"), `design/proposals/core-visibility-fix.md` (R1), `keystones-v1.md` mục 2 và 4, `production/gacha-contract.md`, và code đã đọc: `core_offer.gd`, `core_combos.gd`, `combat_engine.gd` (m100_for, recompute_bo, _bo_dice, undo_last, reroll_dice, overcast), `RunState.gd` (_open_core_offer, to_data, start_run_with_epoch), `action_log.gd`, `run_verifier.gd`, `worker/src/run_core.js`, `combat_tune.json`, `status_engine.gd`.

Phạm vi MVP đã chốt: 3 Anchor (Tam Tấu, Con Bạc, Mỏ Mana), đột biến Cặp cho cả 6 nhà, Thức tỉnh cho 3 Anchor, sửa rút trục Lõi R1, MỘT lần bump RULES_VERSION. Chưa chạy sim, chưa chạy test nào. Chỗ nào chưa kiểm ghi "chưa kiểm".

## 0. Phát hiện từ code, lệch với giả định của doc (đọc trước)

- **Thorns KHÔNG có trần tổng.** `combat_tune.json` có `thorns.cap = 0` (Liam 21/10: không trần, `status_engine.gd:21`), và thorns không bao giờ decay. Chỉ có `thorn.shield_transfer_cap` 6 (mỗi lần chuyển Khiên→Gai của một Axie) và poison `face_cap` 8 / `stack_cap` 15. Đề bài và doc cùng giả định "thorn có trần": sai với thorn.
- **Mana không có trần.** Không có knob `mana.max`; `mana += v` (`combat_engine.gd:2096`) không clamp. Test `t_keystone_mana_combo` trong keystones-v1 ("không vượt mana.max") đang dựa vào thứ không tồn tại.
- **Hệ số M có hai chỗ clamp.** `recompute_bo()` clamp nhóm về `bo_cap100()`, rồi `m100_for()` cộng Overcast và clamp lần nữa. Comment ở `m100_for`: "Core adds (design 10) are not done yet". Mọi nguồn hệ số mới (Con Bạc, Nhát Cuối, Tam Tấu −0.15, Bàn Tay Lớn) chưa có chỗ cắm.
- **Combo chia sẻ Lõi.** `c_thorn_shield` nằm trong 4 combo, `c_living_wall` trong 2. Luật "Cặp thứ hai cùng nhà" (nấc 2) rẻ hơn doc tưởng.
- **Ruột loại nhau.** Con Bạc: `c_hollow_core` và `c_thorn_pact` loại nhau (owned). Mỏ Mana: `rule_dry_steppe` loại `c_mana_pool`, `c_deep_current`, `c_overflow` (chỉ còn `c_tidecaller`, `c_dewdrop`). `rule_cheap_mana` và `rule_tundra` loại `c_hollow_core`, `c_thorn_pact`.
- **Copycat đã kiểm OK**: `_bo_dice` bỏ viên `copycat_turn == turn` (đúng như ghi chú reviewer 2).

## 1. Lỗ hổng luật (adversarial)

Mức: **CHẶN** = không merge nếu chưa có cách bịt + test. **NẶNG** = phải bịt trước build cho Liam chơi. **VỪA** = bịt trước release, hoặc ghi rõ chấp nhận. Cột cuối: doc đã chặn chưa (Có / Một phần / Chưa).

| # | Lỗ hổng | Kịch bản | Mức | Cách chặn đề xuất | Doc |
|---|---|---|---|---|---|
| 1 | "giữ ĐÚNG 2 Lõi ruột" mơ hồ | Nếu hiểu là `== 2`, người chơi nhặt Lõi ruột thứ 3 thì Thức tỉnh TẮT; còn lại chỉ rơi vào "đủ 2 là bật". Hai cách hiểu cho hai game khác nhau | CHẶN | Chốt `>= 2`, không bao giờ tắt vì có nhiều hơn. Banner "x/2" kẹp ở 2/2. Hỏi Liam xác nhận chữ "ĐÚNG" | Chưa |
| 2 | Thức tỉnh bật/tắt khi bán, mất, đổi Lõi ruột | Doc tự mâu thuẫn: mục 1 nói Thức tỉnh "không tắt", mục 5.4 nói "tính từ Lõi đang có, không lưu state". Đường làm mất Lõi có thật: `sell_relic`, `swap_on_full`, bán trong `pact_pick`, `c_dim_stone` thay Lõi, `c_fossil` tự xoá. Bán ruột giữa run để tắt/bật theo ý, hoặc bán rồi mua lại để kích lại banner và popup "lần đầu" | CHẶN | Chốt một: (a) Thức tỉnh đóng băng theo trận (đếm ruột lúc `setup_new`, không đổi giữa trận) và lưu một cờ `awakened` theo run, hoặc (b) tính sống nhưng popup "lần đầu" lưu ở RunState. Khuyến nghị (a)+cờ, vì Liam ghi "không tắt". Bán ruột sau khi Thức tỉnh: chưa kiểm sell_relic có gọi được giữa trận không | Mâu thuẫn |
| 3 | Anchor lọt vào ranked / online / daily / mission | MVP "chỉ offline", nhưng doc không nói CHẶN ở đâu. Online không ranked cũng có `run_id` và Worker. Daily dùng seed chung: Anchor làm bảng không so được | CHẶN | Một cổng duy nhất trong `RunState.start_run_with_epoch`: `anchor_id` chỉ nhận khi `epoch is LocalEpochSource` và `not ranked` và `run_kind == "normal"` (daily/mission: hỏi Liam, mặc định chặn). Màn chọn Anchor không hiện ở các loại run kia (không chỉ ẩn nút: `pick` trả false). Verifier: `header.loadout.anchor_id != ""` → `bad_header` | Một phần (nói "MVP offline", không nói cơ chế) |
| 4 | Nguồn hệ số mới lách `m_cap` 3.0 | Con Bạc +0.30..0.60, Nhát Cuối +0.30/0.60, Tam Tấu −0.15, Bàn Tay Lớn +0.40 cộng SAU clamp cuối, hoặc cộng ở `damage_pipeline` như hệ số riêng, thì vượt 300. Đã có tiền lệ: `m100_for` còn ghi "Core adds not done yet" | CHẶN | Mọi nguồn cộng vào `add` trong `m100_for` trước `clampi(…, 100, bo_cap100())`, một đường duy nhất. Tam Tấu −0.15 cũng đi đường này (sàn 100). Cấm nguồn M nào ngoài hàm này | Một phần (nói "dưới m_cap", chưa nói chỗ cắm) |
| 5 | Khiên Gai Nảy: Gai "tới hết lượt quái" nhưng thorns không decay và không trần | Cách làm dễ nhất là `status["thorns"] += n`: thành Gai VĨNH VIỄN, cộng dồn mỗi lượt, không trần (`thorns.cap` 0). Nấc 2 "không trừ Khiên" + `c_thorn_shield` (cũng đổi Khiên→Gai, trần 6/lần) cho Khiên + Gai + `Tam Tấu` đếm giá trị mặt khiên vào vụ nổ: một mặt khiên ăn ba lần | CHẶN | Gai tạm là field riêng (`custom_state.tmp_thorns`), xoá ở đầu lượt người chơi kế, nằm trong snapshot undo và save. Hoặc đặt `thorns.cap` (đổi chốt Liam 21/10, cần hỏi). Test cộng dồn qua 5 lượt. Chốt: mặt khiên đã đổi sang Gai có tính vào base vụ nổ Tam Tấu không | Một phần (chặn "không nhân BỘ lần hai", chưa chặn vĩnh viễn) |
| 6 | Field mới không vào save / undo snapshot | Tally mới: `mana_bo_paid`, cờ Nứt-Ra-Mana 1/lượt, Mana Tràn 1/lượt, tally Liều sạch, Overcast lần hai, `tmp_thorns`, `anchor_id`, cờ Thức tỉnh. Quên một cái trong `_apply_state_dict` thì Hoàn tác = nhận thưởng lại; quên trong `RunState.to_data/from_data` thì load giữa trận = reset tally | CHẶN | Danh sách field phải có trong cả hai chỗ (checklist ở mục 3, test T-06, T-07). `undo_last` hiện giữ `reroll_lock` qua undo: tally Liều sạch phải rewind CÙNG `reroll_k` | Một phần (có test `t_mutation_derived`, nhưng "tính từ Lõi" không bao gồm tally theo lượt) |
| 7 | Ván Gỡ / lần tung lại nội bộ: nguồn seed | Thức tỉnh Con Bạc: Liều làm Nứt thì tung lại ngay miễn phí. Lần tung này lấy ngẫu nhiên từ đâu? Online mỗi `reroll_dice` tiêu một epoch (Worker `KINDS.reroll`); thêm lần tung không có epoch thì replay không khớp, hoặc client tự chọn seed | CHẶN | Chỉ nhận nếu seed dẫn xuất từ CÙNG epoch của lần Liều (ví dụ `seed ^ (k+1)`), `reroll_k` tăng, khoá `(rmode, uids, k)` giữ kết quả. Vì Anchor offline, không cần Worker, nhưng quy tắc vẫn phải viết trước để mở ranked sau này không phải đổi luật. Test: undo + Liều lại ra đúng kết quả cũ | Một phần (khoá có, nguồn seed chưa nói) |
| 8 | Tam Tấu nổ nằm NGOÀI `m_cap` | Vụ nổ là kênh sát thương riêng (`from_burst`, 16/quái, base value gốc), không bị M cap. 5 quái × 16 = 80/lượt, Bão Gai nổ hai lần + xuyên Khiên = 160. Mặt khiên/hồi nằm trong base | NẶNG | Giữ `tt.cap`; chốt base chỉ tính mặt sát thương hay cả khiên (keystones-v1 để "sim quyết"); Bão Gai: lần hai chỉ khi mọi viên BỘ dùng cùng lượt (doc đã có). Test trần theo số quái | Một phần |
| 9 | Vòng Nứt → mana → Overcast | Con Bạc-nhà (Nứt Ra Mana) + Mỏ Mana (Overcast 1 mana, +1 mana khi BỘ tự nhiên) + Mana Pool/Tidecaller. Liều không tốn mana, Nứt 30-40%. Liam chốt "nấc 2 Con Bạc chỉ +1" nhưng nấc 1 cũng +1: nấc 2 thành no-op. Không có `mana.max` để chặn tích luỹ | NẶNG | Chốt nấc 2 khác nấc 1 ở thứ khác (xem mục 4). Mana từ Nứt tối đa 1 lần/lượt, mọi nguồn "mana khi BỘ/Nứt" nằm trong tally riêng. Đề xuất thêm kiểm sim `mana_in - mana_spent` theo lượt và log. Test: 3 lượt liên tiếp mana ròng ≤ +1/lượt khi chỉ Overcast | Một phần |
| 10 | Mana Tràn: sát thương không cần quyết định | Cuối lượt còn ≥3 mana thì quét 2/4 sát thương mọi quái, miễn phí quyết định: người đánh bừa không tiêu mana vẫn được thưởng. Thứ tự với Mana Pool / Mana Ward / Deep Current | NẶNG | Thứ tự cố định Mana Pool → Mana Ward → Mana Tràn (doc có). Thêm: Mana Tràn không chạy ở lượt thắng trận (quái chết hết), không hơn 1 lần/lượt, undo hoàn mana. Sim: spam ≤12 (doc có) | Có (thứ tự), chưa (spam) |
| 11 | Câu offer / save-scum quanh Anchor | Thứ tự: Anchor chọn TRƯỚC `_open_opening_offers`, offer đầu = `Rng(_core_base_seed ^ SALT)`, offer đầu phụ thuộc Anchor (bias). Offline `p_seed` là `randi()` mỗi run nên bỏ run = seed mới (câu được tuỳ ý, offline chấp nhận). Nhưng: (a) daily seed chung thì xem offer của cả ba Anchor bằng cách bỏ run; (b) thoát giữa màn chọn Anchor rồi vào lại có đổi offer không | NẶNG | Anchor khoá ngay khi chọn và lưu vào save ngay trước khi offer đầu sinh. Daily/mission chặn Anchor (#3). Pin theo `(account, runs_with_battle)` của keystones-v1 chỉ cần khi Anchor bị rút theo seed (sau MVP, MVP hiện đủ 3) | Một phần |
| 12 | Nấc 2 rẻ vì Cặp chung Lõi | "Cặp thứ hai cùng nhà": Tam Tấu có 4 combo, `c_thorn_shield` nằm trong cả 4. Ba Lõi (`c_thorn_shield` + `c_living_wall` + `c_sonic_shield`) đã là 2 Cặp → nấc 2 | NẶNG | Nấc 2 = Đủ, hoặc 2 Cặp KHÔNG chung Lõi. Đo bằng `sim_combo_draw`: P(nấc 2) theo nhà. Đồng thời "Tam Tấu hay gặp nhất" (doc có) cần số | Chưa |
| 13 | Bias + reroll Lõi + thưởng reroll combo = săn ruột | `ks_bias` ×2 + `ks_seed_pick` + 2 reroll từ combo + reroll Lõi gốc. Người săn ép Thức tỉnh gần chắc (doc ước 64% người săn trước khi tính reroll) | NẶNG | `reroll_card` có áp bias không: chốt (đề xuất: KHÔNG, reroll dùng pool thường). Sim S1 phải chạy kèm reroll. Mục tiêu giữ theo doc 3.2 (người săn ≤65%) | Chưa |
| 14 | R1 đổi offer của MỌI run | `_axis_order` đổi tiêu thụ rng: cùng seed ra bộ thẻ khác; replay cũ lệch; run đang dở bị từ chối resume (rules_version check ở save) | VỪA | Một lần bump duy nhất (doc đã chốt), SUPPORTED_RULE_VERSIONS ở worker, fingerprint. Báo người chơi "run dở không tiếp tục được" nếu bump giữa phiên. Test có kỳ vọng offer cố định sẽ phải sửa | Có |
| 15 | Cổng stage | Doc nói stage <3 không thấy Anchor, đột biến từ stage 2. `depth_stage` mặc định 3 khi params thiếu (`RunState.gd:482`), nên test/tool/replay mặc định stage 3. Offline stage đến từ `MetaState.depth_stage()` | VỪA | Test ranh giới 1/2/3: stage 1 không đột biến, không Anchor; stage 2 có đột biến, không Anchor; stage 3 đủ. Anchor `pick` ở stage <3 trả false (không chỉ ẩn UI). Tài khoản cũ vào thẳng stage 3 | Một phần |
| 16 | Lõi nhiệm vụ xong có tính "giữ"? | `core_quest_done`: rời slot, `owned_relic_ids` không còn, nhưng combo vẫn tính. Ruột của 3 Anchor MVP không có quest Core, nhưng đột biến 6 nhà có (`c_chimera_hunt` ở Nhát Chốt, `c_collector` ở Cầu Vồng) | VỪA | Chốt nhất quán với combo: có tính (đã quyết cho combo ở gacha-contract). Dùng chung một hàm `held_cores()` = owned + quest_done cho cả đột biến và Thức tỉnh, cấm đếm riêng | Chưa |
| 17 | Cap nuốt nguồn = nội dung vô hình | BỘ 4 có part bậc cao: 100+120+25=245, +50 Overcast = 295, Con Bạc +30 chỉ còn +5. BỘ 5: 285 + OC chỉ +15. Con Bạc / Nhát Cuối gần như vô nghĩa ở BỘ 4-5 | VỪA | Sim: log "M bị cap nuốt" theo nguồn; điều kiện "thấy được ≥70%" của doc 3.1 phải đo phần hệ số THỰC nhận chứ không đếm lần kích. Số: tay, chưa kiểm | Chưa (reviewer 2 có nêu, chưa có test) |
| 18 | Jumpy / Copycat × BỘ tự nhiên | Jumpy đổi mặt 2 viên SAU khi BỘ chốt rồi `_snap_bo()`: có thể tạo/phá BỘ. Mỏ Mana "BỘ tự nhiên" và Con Bạc "Liều sạch" cần định nghĩa tự nhiên: BỘ do Jumpy tạo có tính không | VỪA | Chốt: BỘ do Jumpy/Mặt Tạm/Copycat tạo KHÔNG tính tự nhiên (không +1 mana). Test với Jumpy + Mỏ Mana. Copycat: chỉ assert không ra BỘ bốn (doc có). Chưa kiểm Jumpy có đủ điều kiện tạo BỘ từ 2+1 không | Một phần |
| 19 | Combo ẩn bởi `hide_if_rules` | Không đột biến nhưng Lõi vẫn là ruột (doc 2.3 đã chốt). Dễ lệch ở đường code: hàm đột biến dùng `CoreCombos.all(owned)` (lọc ẩn), hàm Thức tỉnh phải KHÔNG lọc | VỪA | Hai hàm tách bạch, test cả hai cùng một trạng thái | Có (chốt), chưa test |
| 20 | Anchor không phải Lõi: đường xử lý Lõi chạm vào | `sell_relic`, `swap_on_full`, sell list của `pact_pick`, `RelicRegistry` không biết id `ks_*`, tên relic `r_keystone` đã có trong save người chơi | VỪA | Anchor sống ngoài `owned_relic_ids` (field riêng), từ chối mọi đường bán/đổi, không đụng `r_keystone`. Test: sell Anchor id → false, save cũ có `r_keystone` load bình thường | Một phần |
| 21 | Ruột không với tới được | Mỏ Mana + `rule_dry_steppe`: 3/5 ruột bị loại. Con Bạc + `rule_cheap_mana`/`rule_tundra`: 2/5 bị loại; `c_hollow_core` ↔ `c_thorn_pact` loại nhau. Tam Tấu ruột nhiều Lõi có cổng mặt (`face:shield`, `back_face:heal`): phụ thuộc đội | VỪA | Chốt: không cho chọn Anchor nếu Run Rule làm số ruột còn lại <2 (UI ghi lý do), hoặc chấp nhận và hiện "x/2" kẹt. Đo tần suất ruột hợp lệ theo đội mẫu | Chưa |
| 22 | Meta / cloud save | Thống kê Thức tỉnh / số lần đột biến phát ("Màn kết run") và Sổ Lõi nếu có cột Anchor. Mọi ghi phải qua `SaveStore`, thêm field vào `MetaState.reload_from_store()` (CLAUDE.md) | VỪA | Test `reload_from_store` có field mới; không ghi thẳng file | Chưa |
| 23 | Banner chồng, popup chặn nhịp | Ráp Cặp cùng lúc Thức tỉnh = 2 banner (Cặp 1.6 s + Thức tỉnh). `_apply_and_finish` chờ banner `finished`, có `_taking` chống Take hai lần | VỪA | Thứ tự: Cặp → Thức tỉnh, một hàng đợi; bấm/Space tua cả hai; không để node kẹt khi tua | Một phần |

**Tổng: 23 lỗ hổng = 7 CHẶN (1-7), 6 NẶNG (8-13), 10 VỪA (14-23).**

**Năm cái nặng nhất:** (2) Thức tỉnh bật/tắt khi mất Lõi ruột, doc tự mâu thuẫn; (3) Anchor lọt ranked/online/daily, chưa nói cổng chặn ở đâu; (4) nguồn hệ số mới lách `m_cap`, hiện chưa có chỗ cắm; (5) Gai tạm vĩnh viễn vì thorns không decay và không trần; (7) tung lại nội bộ của Ván Gỡ không có nguồn seed.

## 2. Anti-cheat / replay

Cách xác minh hiện tại (đã đọc): Worker cấp seed theo epoch và kiểm chuỗi hash của log + `fn` trong ALLOWED_FNS (`run_core.js`); việc tái hiện toàn run là `RunVerifier` phía client/headless, chỉ nhận run `ranked` (`not_ranked` cho run khác).

**Anchor được chọn ghi vào đâu (đề xuất cho MVP offline):**
- KHÔNG thêm action vào log, KHÔNG thêm field vào header. `anchor_id` là field của `RunState`, lưu trong run save (`to_data` / `from_data`), mất khi run kết thúc. Lý do: MVP chỉ offline, không ai xác minh run này; thêm `pick_anchor` vào ALLOWED_FNS thì phải đổi đồng thời 3 chỗ (`action_log.gd`, `run_verifier.gd`, `worker/src/run_core.js`, hiện đang khớp) và làm tăng bề mặt tấn công mà MVP không cần.
- Hệ quả bắt buộc: mọi đường ranked/online phải TỪ CHỐI Anchor chứ không "lờ đi" (xem tamper bên dưới). Khi mở ranked sau MVP mới thêm `pick_anchor [index]`, kèm epoch kind riêng, Worker tính lại bộ ba theo seed, mã `pin_mismatch` / `stage_mismatch`. Khi đó đổi RULES_VERSION lần nữa.
- Cần Liam/lead-programmer xác nhận lựa chọn này (mục 4, G2).

**Đột biến Cặp không cần action mới**: tính từ Lõi đang có và trạng thái trận, tất định. Nhưng nó ÁP DỤNG cả ở ranked (không cần Anchor), nên engine phải replay đúng bằng `RunVerifier`: vì vậy phải bump RULES_VERSION và chạy lại `t_replay` + `t_full_run_loop`.

**Ngẫu nhiên mới và seed của chúng:**
| Nguồn | Có rng mới? | Seed / điều kiện |
|---|---|---|
| 6 đột biến Cặp | Không | tất định |
| 3 luật nền + 3 Thức tỉnh | Không, TRỪ Ván Gỡ | Ván Gỡ tung lại: phải dẫn xuất từ epoch của lần Liều (lỗ hổng #7); crack roll vẫn dùng `_rng` của engine như `reroll_dice` hiện nay (`combat_engine.gd:941`, mỗi viên một lần gọi, kể cả viên không tung, để không phụ thuộc trạng thái) |
| `ks_bias` trong `core_offer` | Không thêm | cùng luồng `Rng((base ^ CORE_SALT) ^ pick*0x9E3779B1)`; yêu cầu: đúng MỘT `next_int` mỗi thẻ (trọng số là `next_int(tổng)`, không gọi lặp) |
| `ks_seed_pick` (thay một thẻ cùng bậc) | Không | dùng chỉ số thẻ cố định hoặc một lần `next_int` ở vị trí cố định SAU các thẻ; không đổi số lần gọi theo kết quả. Chưa kiểm tiêu thụ rng hiện tại của `reroll_card` |
| R1 (trọng số trục) | Đổi cách tiêu thụ | `_axis_order` hoán vị có trọng số: số lần `next_int` thay đổi → mọi bộ thẻ đổi so với bản `-r` (đã biết, cần bump) |

**Bump đồng bộ (một lần):** `ActionLog.RULES_VERSION` (hiện `godot-2026-10-23-r` → hậu tố kế), `SUPPORTED_RULE_VERSIONS` trong `worker/src/run_do.js`, fingerprint trong `t_rules_version`. File dữ liệu mới (`keystones.json`, `family` trong `core_combos.json`) phải nằm trong `res://assets/data/rules/` (thư mục này được fingerprint tự động, `WATCHED_DIRS`); đặt ở `assets/data/ui/` thì đổi luật mà fingerprint không bắt.

**Tamper bắt buộc (thêm vào `t_run_tamper_v4`-kiểu, mỗi cái phải ra đúng mã lỗi):**
1. Log ranked có `header.loadout.anchor_id` khác rỗng → `bad_header`.
2. Log có action `pick_anchor` (hoặc fn lạ bất kỳ) → verifier `unknown_action`; gửi lên Worker → `fn`.
3. Log ranked khai `depth_stage` < 3 rồi dùng Cặp stage-3 → `stage_mismatch` hoặc `action_rejected` đúng index (đã có tiền lệ T6/T7).
4. Đổi `rules_version` về `-r` trong log mới → `rules_version_mismatch`.
5. Log ranked mà tape bị tráo seed một epoch `reroll` có Liều → `action_rejected` (kiểm Ván Gỡ không tạo kênh seed ngoài tape; áp dụng khi có đường replay cho Anchor, hiện chỉ để chặn ở mức "Anchor không vào ranked").
6. Replay một run ranked CÓ đột biến Cặp (đội ép ráp Cặp) cho đúng điểm số/state digest với run gốc (không phải tamper, là assert tương đương).
7. Bản `-r` cũ còn trong SUPPORTED nhưng replay bằng engine mới → từ chối `rules_version_mismatch`, không âm thầm tính khác.

## 3. Ma trận test bắt buộc

Quy ước: file `godot/tests/t_*.tscn`, chạy qua `with_lock.sh`, test KHÔNG chạm mạng, không để lại save thật. Sàn suite tăng đúng bằng số file mới, sửa `technical-preferences.md` cùng commit. "Luồng thật" = đi qua UI/controller thật như người chơi, không gọi thẳng hàm engine.

| ID | Loại | Assert chính | Lỗ hổng |
|---|---|---|---|
| T-01 `t_anchor_flow_pick` | **LUỒNG THẬT** (như `t_core_overlay_flow`) | Mở run stage 3 offline → màn chọn Anchor hiện đúng 3 thẻ (Tam Tấu, Con Bạc, Mỏ Mana), mỗi thẻ có 5 icon ruột → bấm chọn → vào map; HUD có huy hiệu Anchor và "Lõi ruột 0/2"; thẻ không chọn lần hai được; offer Core đầu sinh SAU khi chọn | 3, 11 |
| T-02 `t_anchor_flow_gut_progress` | **LUỒNG THẬT** | Qua overlay chọn Lõi, nhận 1 Lõi ruột → HUD "1/2"; nhận Lõi không ruột → vẫn 1/2; nhận ruột thứ hai → 2/2 + banner THỨC TỈNH + khung vàng, đúng thứ tự sau banner Cặp nếu cùng lúc; nhận ruột thứ ba → vẫn Thức tỉnh (không tắt, kẹp "2/2") | 1, 23 |
| T-03 `t_anchor_flow_pair_mutation` | **LUỒNG THẬT** | Ép đội + offer để ráp một Cặp (mỗi nhà một lần, tham số hoá 6 nhà) qua overlay: banner Cặp có dòng tên đột biến + một câu luật; vào trận, đột biến phát lần đầu có popup to và hiệu ứng ở cột "Khoảnh khắc", lần sau popup nhỏ không chặn input; `combo_fired` có phát | 17, 23 |
| T-04 `t_anchor_flow_awaken_in_combat` | **LUỒNG THẬT** | Đủ 2 ruột → vào trận: popup Thức tỉnh lần đầu, hiệu ứng riêng từng Anchor chạy (Bão Gai nổ, Ván Gỡ tung lại, Nhịp Đôi Overcast hai lần), HUD không quay về "x/2"; màn kết run có dòng "Thức tỉnh: … (trận N)" + số lần đột biến | 2, 23 |
| T-05 `t_anchor_gate` | Unit/integration | Anchor `pick` trả false khi: stage 1, stage 2, ranked, epoch từ xa (fake remote source), run_kind daily/mission, chọn lần hai, index ngoài 0..2; true ở normal offline stage 3. Màn không hiện ở các trường hợp false | 3, 15 |
| T-06 `t_anchor_save_load` | Integration | Lưu giữa trận rồi `from_data`: `anchor_id`, cờ Thức tỉnh, mọi tally theo lượt (`mana_bo_paid`, cờ Nứt-Ra-Mana, Mana Tràn, Liều sạch, Overcast đã dùng, `tmp_thorns`) bằng nhau; chơi tiếp cho cùng kết quả như không lưu | 6 |
| T-07 `t_anchor_undo` | Unit | Với từng tally ở T-06: thực hiện hành động → `undo_last` → mọi giá trị, mana, thorns về đúng như trước; Liều + undo + Liều lại cho cùng kết quả (`reroll_lock`) | 6, 7, 9 |
| T-08 `t_anchor_geq2` | Unit | Ruột 0/1 → chưa; 2 → có; 3, 5 → vẫn có; Cặp đúng nhà (2 ruột) = đột biến + Thức tỉnh cùng lúc | 1 |
| T-09 `t_anchor_loss_midrun` | Unit | Bán/đổi/mất Lõi ruột (`sell_relic`, `swap_on_full`, pact sell, `c_dim_stone`, `c_fossil`) trước, trong, sau trận: Thức tỉnh theo luật đã chốt ở G1 (đóng băng theo trận + cờ); không bật/tắt giữa trận; mua lại không phát lại popup "lần đầu" | 2 |
| T-10 `t_anchor_held_cores` | Unit | `held_cores()` dùng chung: quest Core đã xong tính; combo `hide_if_rules` không đột biến nhưng vẫn ruột; Lõi bị `disabled` không tính | 16, 19 |
| T-11 `t_anchor_mcap` | Unit, bảng tham số | Mọi tổ hợp nguồn (BỘ 3/4/5 × part cao bậc × Overcast × Con Bạc 0/1/2 × Nhát Cuối × Tam Tấu −0.15) cho `m100_for` ≤ 300 và ≥ 100 cho MỌI viên; assert từng nguồn có thể bị cap nuốt hoàn toàn được log (cho sim); không có hệ số M nào tính ở ngoài `m100_for` | 4, 17 |
| T-12 `t_anchor_volley` | Unit | Tam Tấu: nổ 1/lượt, cap 16/quái theo số quái 1..5, thorn quái không phản (`from_burst`), base không đổi khi bật Overcast / Con Bạc / Mặt Tạm, viên ảo và Copycat không vào base; Bão Gai dùng `is_finisher`, lần hai chỉ khi mọi viên BỘ dùng cùng lượt, xuyên Khiên quái nhưng Plating boss vẫn chặn | 8 |
| T-13 `t_anchor_gambler` | Unit | Liều sạch chỉ từ 2 viên, Nứt 40%; +0.30 mỗi lần, tối đa +0.60; Liều An toàn không tính; Ván Gỡ 1/lượt, không vượt `hard_cap`, kết quả dẫn xuất từ epoch của Liều (replay cùng seed cho cùng kết quả) | 7, 9 |
| T-14 `t_anchor_mana_mine` | Unit | +1 mana chỉ ở BỘ tự nhiên đầu tiên mỗi lượt (BỘ mất/hiện không trả lần hai; BỘ do Mặt Tạm/Jumpy tạo không tính); Overcast tốn 1; Mặt Tạm vẫn 2 mana per_battle 1 (giá Mặt Tạm 3 là knob dự phòng, KHÔNG bật); Nhịp Đôi lần hai tốn 2; mana ròng/lượt khi chỉ Overcast không dương | 9, 18 |
| T-15 `t_mut_mana_loop` | Unit | Nứt Ra Mana 1 lần/lượt; chuỗi Con Bạc-nhà + Mỏ Mana + `c_mana_pool` + `c_deep_current` + `c_tidecaller`: 10 lượt, mana không tăng không giới hạn, ghi mana_in/mana_spent; thứ tự cuối lượt Mana Pool → Mana Ward → Mana Tràn; Mana Tràn không chạy lượt quái chết hết | 9, 10 |
| T-16 `t_mut_shield_thorn` | Unit | Khiên Gai Nảy: 1/3 Khiên (làm tròn xuống, tối đa 4) thành Gai; Gai không nhân BỘ lần hai; hết lượt quái Gai biến mất (5 lượt liên tiếp thorns không cộng dồn); nấc 2 không trừ Khiên; cùng `c_thorn_shield`: tổng Gai ≤ cap đã chốt; mặt khiên đã đổi tính/không vào base Tam Tấu đúng quyết định G3 | 5 |
| T-17 `t_mut_tier2` | Unit | Nấc 2 khi Đủ; khi 2 Cặp KHÔNG chung Lõi; ba Lõi tạo 2 Cặp chung Lõi KHÔNG lên nấc 2 (nếu chốt theo đề xuất); hai nhà khác nhau bật cùng lúc; Mưa Đòn (jackpot) vào thẳng nấc 2 | 12 |
| T-18 `t_mut_six_houses` | Unit, tham số hoá | Mỗi 6 nhà: điều kiện, giới hạn 1/lượt, không đụng Overcast, giá/số đúng bảng 2.2 (Che Chắn lên Trứng; Nhát Cuối đúng `is_finisher`; Săn Bốn với Hollow Core làm lần tung đó 0 mana) | 9, 17 |
| T-19 `t_anchor_offer_bias` | Unit | `ks_bias` chỉ đổi trọng số trong cùng bậc: xác suất bậc, near-miss, `core_skipped_t` không đổi; đúng 1 `next_int` mỗi thẻ (đo số lần gọi rng); `ks_seed_pick` luôn có ≥1 ruột ở lượt đầu nếu bậc có ruột; reroll_card theo quyết định G5; offer vẫn tất định theo seed; `t_gacha_guards` xanh | 13 |
| T-20 `t_core_axis_weight` (R1) | Unit | Trọng số trục theo cỡ ô; mỗi Lõi dice ≥ 10% run (phụ thuộc sim, đây chỉ assert luật rút: tối đa 1 stat/1 quest/1 meme mỗi offer, không lặp trục thừa, offer không rỗng); các test có kỳ vọng offer cố định được sửa | 14 |
| T-21 `t_anchor_not_core` | Unit | Anchor không ở `owned_relic_ids`, không chiếm slot, không vào `core_offer`/gacha, bán/đổi trả false, save cũ có `r_keystone` load bình thường | 20 |
| T-22 `t_anchor_filters` | Unit | Copycat + Anchor nào cũng không ra BỘ bốn; Jumpy + Mỏ Mana đúng T-14; với `rule_dry_steppe`/`rule_cheap_mana`/`rule_tundra` hành vi theo G6 | 18, 21 |
| T-23 `t_anchor_ranked_refuse` | Integration (tamper) | 7 tamper ở mục 2: đúng mã lỗi; `ALLOWED_FNS` khớp 3 chỗ; không thêm fn | 3 |
| T-24 `t_rules_version` | Gate có sẵn | Fingerprint mới (đã gồm `keystones.json`), RULES_VERSION bump, worker SUPPORTED cập nhật; Worker `node --test` xanh | 14 |
| T-25 `t_anchor_meta_save` | Integration | Field thống kê mới đi qua `SaveStore`, có trong `MetaState.reload_from_store()`, đăng nhập đổi tài khoản không rò | 22 |
| T-26 `t_replay` + `t_full_run_loop` | Gate có sẵn | Replay run ranked có đột biến Cặp cho cùng state digest; 8 seed-walk không lệch | mục 2 |

**Sim bắt buộc trước khi cho Liam chơi (không phải test, nhưng là cổng):** S0 mốc theo stage, S1 tần suất Thức tỉnh theo chính sách × `ks_bias` × reroll, S2 ép Cặp (lift theo nhà, tần suất đột biến phát), S3 ép từng Anchor `awaken_off/on`, S4 chọn tự do: expert 20 ±3, random/spam ≤12, expert − random ≥6, spam theo dõi riêng Tam Tấu và Mana Tràn. Bot phải có chính sách cho từng luật mới (Liều ăn mana khi có Nứt Ra Mana, để dành viên BỘ cho Nhát Cuối, Overcast hai lần), nếu không sim báo yếu giả.

**Smoke luồng thật bắt buộc (người chạy, không chỉ test):** (1) run mới stage 3, chọn từng Anchor, chơi tới boss đầu; (2) cố tình ráp Cặp mỗi nhà một lần, xem popup và hiệu ứng; (3) đủ 2 ruột, xem banner và hiệu ứng trong trận; (4) thoát giữa trận rồi tiếp tục; (5) Hoàn tác sau mỗi hành động có thưởng; (6) mở run ranked và online, xác nhận KHÔNG thấy Anchor; (7) tài khoản stage 1 và 2. Mỗi mục có ảnh chụp ở `production/qa/evidence/`.

## 4. Khoảng trống cần chốt trước khi code

| ID | Câu hỏi | Đề xuất của QA |
|---|---|---|
| G1 | "ĐÚNG 2 Lõi ruột": `==2` hay `>=2`? Và Thức tỉnh "không tắt" (mục 1) hay "tính sống từ Lõi đang có" (mục 5.4)? | `>=2`; đóng băng theo trận + cờ `awakened` theo run lưu save. Cần Liam xác nhận chữ "ĐÚNG" |
| G2 | Anchor ghi vào đâu? | Chỉ field RunState + save, không action/header; ranked/online từ chối (mục 2). `pick_anchor` + epoch kind chỉ làm khi mở ranked |
| G3 | Mặt khiên đã đổi sang Gai có tính vào base vụ nổ Tam Tấu không? Gai tạm lưu ở đâu, có cần `thorns.cap`? | Base chỉ tính mặt sát thương HOẶC tính giá trị gốc trước khi đổi (chốt một); Gai tạm là field riêng xoá đầu lượt người; không đổi `thorns.cap` (chốt Liam 21/10) |
| G4 | Nấc 2 của Nứt Ra Mana: Liam chốt "+1" mà nấc 1 cũng +1 | Nấc 2 = vẫn +1 mana nhưng viên Nứt được giữ nguyên nửa giá trị khác (hoặc nấc 2 = Cặp thứ hai thêm lượt dùng, không thêm mana). Cần Liam chọn, đừng để nấc 2 no-op |
| G5 | `reroll_card` có áp `ks_bias` không? `ks_seed_pick` dùng rng hay vị trí cố định? | Không áp bias ở reroll; seed_pick vị trí cố định (thẻ cuối cùng bậc), không thêm rng |
| G6 | Run Rule làm ruột còn <2 (dry_steppe, cheap_mana, tundra): chặn chọn Anchor hay chấp nhận kẹt? | Hiện lý do và vô hiệu hoá thẻ Anchor đó trong run đó |
| G7 | Daily / mission có Anchor không? | Không trong MVP (seed chung, thưởng riêng) |
| G8 | Nấc 2 từ "Cặp thứ hai cùng nhà" khi hai Cặp chung Lõi | Chỉ Đủ, hoặc hai Cặp rời nhau |
| G9 | BỘ do Mặt Tạm/Jumpy/Copycat tạo có phải "BỘ tự nhiên" cho Mỏ Mana và Con Bạc? | Không |
| G10 | Mana không có trần: giữ nguyên hay thêm `mana.max`? Đổi luật nền, cần Liam | Giữ nguyên, nhưng sim bắt buộc log mana_in/mana_spent; sửa `t_keystone_mana_combo` thành "không có chuỗi vô hạn" thay vì "không vượt mana.max" |
| G11 | Chỗ cắm hệ số M cho Core adds (`m100_for`): ai viết, một đường duy nhất | `gameplay-programmer` tạo hook `bo_core_add` trong `m100_for`, test T-11 là cổng |
| G12 | Chỉ tiêu "thấy được ≥70%" đo lần kích hay hệ số thực nhận? | Hệ số thực nhận sau cap |
| G13 | Chưa kiểm: `sell_relic` gọi được giữa trận không; tiêu thụ rng của `reroll_card`; Jumpy có tạo BỘ từ chọn 2 viên không; offline `depth_stage` lấy từ đâu khi tạo run local | Làn code xác nhận trước khi viết test T-09, T-19, T-22, T-05 |

## 5. Chốt cách bịt (agent điều phối, 23/10 — theo các quyết định Liam đã duyệt)
- #1: Thức tỉnh khi số Lõi ruột **>= 2** (Liam "đúng 2 Lõi ruột bất kỳ" = 2 Lõi ruột nào cũng được, không phải ==2). Chip "x/2" kẹp ở 2/2.
- #2: Thức tỉnh KHOÁ theo run: cờ `RunState.anchor_awakened` bật lần đầu đạt >=2 (đếm lúc nhận Lõi), lưu save + replay, không bao giờ tắt; popup/banner "lần đầu" theo cờ này.
- #3: Một cổng duy nhất (đề xuất của QA): Anchor chỉ khi epoch offline + not ranked + run_kind normal; daily/mission CHẶN; verifier `anchor_id != ""` ở run online → bad_header.
- #4: Mọi hệ số mới cộng vào `m100_for` trước clamp `bo_cap100()` — không nguồn M nào khác. Test.
- #5: Gai tạm = `custom_state.tmp_thorns`, xoá đầu lượt người chơi kế, trong snapshot/save; mặt khiên đổi sang Gai KHÔNG tính vào base nổ Tam Tấu (base nổ chỉ mặt sát thương). Không đổi `thorns.cap`.
- #6: Checklist field mới trong `_apply_state_dict` + `RunState.to_data/from_data`; test T-06/T-07.
- #7: Ván Gỡ tung lại dùng seed dẫn xuất từ cùng epoch lần Liều (`seed ^ (k+1)`), `reroll_k` tăng, khoá giữ kết quả; test undo.
- #8: Base nổ Tam Tấu = chỉ mặt sát thương; giữ `tt.cap` 16/quái; Bão Gai lần 2 chỉ khi mọi viên BỘ dùng cùng lượt.
- #9: Giữ nấc 2 Con Bạc "+1 mana cho 2 lần Nứt đầu mỗi lượt" (phải chịu 2 viên Nứt); sim đo mana ròng/lượt, nếu > +1 trung bình thì hạ.
- #10: Mana Tràn không chạy ở lượt thắng trận, tối đa 1 lần/lượt, undo hoàn mana.
- #11: Anchor khoá + lưu save NGAY khi chọn, trước khi sinh offer đầu.
- #12: Nấc 2 = có Đủ, HOẶC 2 Cặp cùng nhà KHÔNG chung Lõi nào.
- #13: `reroll_card` KHÔNG áp bias nhà (pool thường).
- G6: Luật run làm Lõi ruột hợp lệ < 2 → thẻ Anchor đó vô hiệu + lý do.
- VỪA (14-23): theo đề xuất trong bảng; #23 hàng đợi banner Cặp → Thức tỉnh (gộp một moment theo UX chốt).
