# Kế hoạch QA beta (qa-lead, 26/10/2026)

Chạy sau R-CF (~22-26/11), trước khi giao Liam polish (~27/11). Nguồn: `production/beta-plan.md`, 5 brainstorm đã duyệt, 9 review `production/qa/review-*-2026-10.md`, `production/session-state/active.md` (mục 26/10).
Mục tiêu một câu: không còn crash, không còn chỗ mất tiền/tiến độ vô lý, và không còn chỗ người chơi hỏi "vừa xảy ra chuyện gì?" mà game không trả lời.

Giới hạn của bản kế hoạch này: mình chưa chạy gì (không Godot). Các "lỗ hổng đã biết" lấy từ review, chưa kiểm lại bằng cách chạy. Sau R1 phải đối chiếu lại với code thật vì một số làn (SR0 phần 2, N-C, AT, LD-A) đang nằm ở nhánh chưa merge.

## 0. Quy tắc chung

- **Một run mở mỗi tài khoản** (chỉ mục duy nhất `0002_runs.sql`). FLOW trên tài khoản Liam chạy NỐI TIẾP, và chỉ chạy khi Liam không chơi. Muốn song song thì dùng tài khoản phụ.
- **Hai loại tài khoản.** (1) Tài khoản Liam: chỉ cho FLOW cần tiến độ thật (stage, chuỗi thắng, số dư lớn). (2) Tài khoản phụ `qa-fresh` (tạo mới, cần Liam gật, xem câu hỏi cuối): người mới, tutorial, khách, đăng nhập máy khác, thử reset. Tài khoản Liam chỉ tiêu Shard cho cược N1/N2 và những gì FLOW ghi rõ; ghi số dư trước/sau mỗi FLOW. Reset R3 xoá hết nên mất Shard không phải vấn đề, nhưng KHÔNG xoá cloud save, KHÔNG đổi tên/mật khẩu, KHÔNG bỏ run Full dở của Liam nếu có.
- Mọi lỗi ghi ngay vào `production/qa/bugs/` (mục 4), không để trong đầu. Ảnh cho UI: 1920x1080 và 1280x720.
- QA không sửa code. Lỗi giao lại làn/agent sở hữu file (bảng mục 2 của `beta-plan.md`).
- CPU là giới hạn thật: suite (a) và soak (b) KHÔNG chạy cùng lúc. Soak chạy ở worktree riêng, ban đêm. Mọi lần chạy Godot qua `with_lock.sh`, `AXIE_HANG_KILL` 120 (lẻ) / 500 (suite) / 900 (soak lô).
- QA tổng chạy trên bản đã deploy R-CF. Thêm một lượt QA nhỏ (chỉ FLOW của hệ thống đó + smoke) ở mỗi đợt R1, R2, R-Atia, R3, R-CF để lỗi không dồn tới cuối.

## 1. Phạm vi theo hệ thống

"Bẫy" = chỗ đã thấy trong review hoặc dễ sai; QA phải cố tình chạm vào.

### 1.1 Nhiệm vụ 6 bậc (N-S, N-W, N-C)
- Thang N1-N6, mở bậc bằng chuỗi thắng (N6 cần thêm một run Full thắng), cọc/trả/lãi ròng, "ước tính", cảnh báo N3+, màn thua đọc được, chip luật cùng chữ với thẻ.
- Anchor trong Nhiệm vụ (Liam cho 26/10, đổi kết quả run, vào bump `-u`): màn chọn Anchor có hiện trong run Nhiệm vụ không, chọn xong chip/thức tỉnh có chạy, replay có qua.
- Bẫy:
  - Còn khoá `_tmp` trong `missions.json` (cổng `AXIE_RELEASE=1`; plan §5).
  - Bậc bị tắt từ server hiện nhãn khoá sai: client chưa đọc `locked_reason` (review N-C), người chơi thấy "thắng N1 1/1" trong khi đã thắng.
  - Hoàn cược khi bump: điều kiện abandon phải theo `run_id` (review N-C), nếu không có thể huỷ nhầm run khác luật.
  - `fetch_unlocks` lỗi mạng: cache giữ nguyên, nhưng UI nói gì?
  - N6 Full có thể vượt 3h (tab qua đêm, nghỉ giữa run): chuyện gì xảy ra với cược.
  - Kill-switch từng bậc (`enabled:false`, hoặc `MISSION_TIERS_OFF`) và việc mất nó (review N-W).
  - Bậc chưa mở mà gửi `rules: []` hoặc rules sai: server từ chối, client hiện chữ gì.
  - Mua khi đang có run mở; mua khi không đủ Shard; mua hai lần liên tiếp (double click).
  - Số "ước tính" trên thẻ so với kết quả thật sau ~10 run: chỉ ghi nhận, không phải lỗi số (số do N-S khoá).

### 1.2 Land (LD-A, LD-B)
- Nâng tier xong về Land, banner một lần, chip HUD Stone, Axie của mình đi lại, món khởi đầu 90 Shard một lần, mục Land ở Profile, 8 decor common + 2 Rare tier 2, mốc m1-m8, thưởng mốc không trùng pool.
- Bẫy:
  - Banner bỏ qua khi có modal khác (NetNotice, Moon card, AccountWelcome), lần sau hiện lại: kiểm đúng một lần thật, không lặp sau đăng xuất/nhập lại và sau cloud save.
  - Bàn phím/gamepad: modal tier mới có tự lấy focus không (review LD-A nói chưa kiểm).
  - Lệch plan: bỏ "raid defense" khi chọn Axie (comment "dropped for beta"). Liam phải biết; QA ghi lại hành vi thật (preset 0 -> ngẫu nhiên).
  - Preset/cloud save lỗi kiểu (`presets[0]` không phải Dictionary): dùng tài khoản phụ có save lạ nếu dựng được.
  - Rare đặt được ở tier 1 (kiểm `min_tier`), quà 3 món = 7 điểm qua m1 ngay (báo Liam), decor trùng tên (S_Tree03 vs S_Tree03a, F_Tree1 vs F_Tree2).
  - Profile: cỡ chữ 16/18/24/32 và chữ bị cắt ở 1280x720.
  - Web nhẹ (nếu LD-A làm kịp): số Axie, đèn, không đen màn. Nếu chưa có thì ghi "chưa có", không tính lỗi.
  - Đủ Stone để nâng tier 2 (20k): tài khoản Liam có thể không đủ. Dùng tài khoản phụ + save dựng bằng công cụ dev, hoặc hỏi Liam.

### 1.3 Quái Atia mới (AT, bump `-v`)
- 6 quái: anemone, shiitake (jellyfin), slimes_04, pangolord, e_golem, e_seahorse. Đa dạng mục tiêu ~5/5/7-8/17 (pw 0/1/2/>=10).
- Bẫy:
  - Thiếu clip hit/die ở shiitake, slimes_04, e_golem...: quái bị đánh/chết mà đứng im có làm người chơi tưởng treo không (chụp video/ảnh liên tiếp).
  - 6 quái có vào run thường ở stage thấp thật không (Liam từng không thấy relic rework; xem memory "new content must be visible"). Chơi >= 10 run thường, đếm quái mới gặp.
  - Run dài bất thường: review AT thấy 18-23 lượt ở vài seed (anti-stall do đội đi kèm). Ghi số lượt trung bình và run dài nhất; nếu run thường hay > ~15 lượt thì báo S3 "nhịp".
  - Tex/kích thước pck: ghi MB trước/sau, > 5% xem lại (plan §7).
  - Elite mới = Elite gốc (cùng chỉ số): nhìn khác nhưng đánh y hệt, hỏi ux xem người chơi có thấy "lừa" không.
  - Boss Chimera và màn giới thiệu boss không bị ảnh hưởng (CL xoá 3 thư mục `assets/atia/*`): vào đủ 5 boss, không thiếu model.

### 1.4 Server RNG, PB, khoá input, kinh tế server, reset, khách (SR0, SR1, B4)
- SR0 (đã deploy R0): token vào hello cần login sống, `closeSanity` chỉ-ghi. SR0 phần 2 (PB bay ngay + `[epoch_rtt]`) vào R1. SR1 (R3): ví server cho Shard/Stone/vé/unlock/pity, idempotency, bỏ offline, cổng mở game, reset M1, khách không ví.
- Bẫy:
  - Khoá input khi chờ seed: bấm die/target/undo/hold/overcast/END TURN/reroll lúc `epoch_pending` (6 guard mới chưa có test CombatView, review SR0).
  - Reroll với RTT chậm; seed lỗi (ngắt mạng) giữa lúc xúc xắc đang bay; thoát trận khi đang chờ (review SR0b: cần QA tay có 3D).
  - Token chưa ràng đúng session (`sid`): đăng xuất ở máy A khi máy B còn login -> token máy A còn sống? Đăng nhập máy khác giữa run.
  - Cookie/login hết hạn giữa run (30 ngày, khó tái hiện; dùng thu hồi session phía server nếu có cách an toàn) -> thông báo gì, run có đóng sạch không, cược có hoàn không.
  - Offline: thông báo "offline" nói gì; sau B4 không còn đường chơi local (kiểm `override.cfg`/cờ không mở được lại ở bản release).
  - Nguồn tiền: PUT `shards = 999999` không đổi số dư (test Worker có, QA thử thêm bằng tay trên tài khoản phụ nếu có công cụ), hai thiết bị cùng mua một món (double-spend), mua khi mạng đứt giữa chừng.
  - Reset M1 (R3): sau reset Shard/Stone/unlock/tier Land/chuỗi thắng/Gem/lịch sử run = 0; đăng nhập máy khác và đăng xuất/nhập lại vẫn 0 (cloud save bị ghi đè); không lặp reset lần hai; run dở lúc reset xử lý sao. Chụp snapshot trước (R3 là điểm không quay lại).
  - Khách: chơi được tutorial + run thường, KHÔNG ví, KHÔNG ranked, KHÔNG Nhiệm vụ (cả tạo run trực tiếp, không chỉ ẩn nút); đăng ký xong chỉ mang lịch sử run, không mang tiền.
  - Ranked: gửi điểm, bảng xếp hạng không bị `run_close` sanity chặn nhầm người chơi thật (ngưỡng "đoán", review SR0).

### 1.5 Khung cosmetics (CF, R-CF) và LD-R
- 8 khung mới (C6 U3 R5 E6 L3 M2 theo brainstorm), nối vào Echo Box/Pass/Cosmetics/Profile; 5 thưởng mốc Land thay mới.
- Bẫy: khung cắt mép (round 4 từng lỗi); khung hiện đúng ở Profile, Cosmetics, Echo Box mở hộp, Leaderboard (nếu có avatar) ở 2 cỡ; Legendary box giờ có khung (từng 0); id trùng pool; `t_land_rewards_not_in_pools` xanh; thưởng mốc Land nhận được và hiện trong kho; khung đã sở hữu ra sao khi mở lại hộp (trùng -> đổi gì, có chữ giải thích không).

### 1.6 V5 Anchor (6 Anchor)
- Kin, Volley, Gambler, Mana Mine, Embers, Big Hand; Luật run (Pack Alpha, High Stakes bật; Set Is King, Pilot Light, Magma Seed có thể bật nếu sim đạt); Vỏ Cộng Hưởng.
- Bẫy:
  - Liam không nhớ đã chọn Anchor nào -> Anchor chưa đủ nổi. Kiểm: màn chọn, chip trong HUD, thức tỉnh, màn kết quả, Codex có đủ để người chơi biết "mình đang chơi Anchor X".
  - Cổng mở: stage 2 trở lên (Mana Mine stage 3), thẻ khoá hiện lý do.
  - Embers, Big Hand còn yếu/bot chưa chơi tốt: ghi cảm giác tay người chơi, không kết luận số.
  - Magma Seed tắt dựa trên `--force` (14/126 lần bắn): nếu bật, kiểm nó hiện trong run (thấy được khi bắn).
  - Vỏ: nhãn SHELL, coach C8 chỉ lần đầu, float "Outside a SET" có rõ nghĩa không.

### 1.7 Hồi quy toàn game
Run thường (Short, Full, stage 1/2/3+, Ascension A0-A9), ranked (+ bảng xếp hạng), daily (nhận, reset), tutorial (đủ bước, bỏ qua, chơi lại), Echo Box (mở thường/Legendary, pity, vé), Pass (nhận mốc, mở khoá), Store (mua bằng Shard/Gem), account (đăng ký, đăng nhập web + desktop PKCE, đăng xuất, đổi máy), cloud save (đẩy/kéo, xung đột hai máy), Profile (stat, danh hiệu, Land), Codex (tab Anchor, quái, Lõi), Settings (âm thanh, phím tắt, ngôn ngữ nếu có), Aid, Vault, Cosmetics, boss intro, màn thua/thắng/kết quả, tiếp tục run dở (đóng tab, mở lại).

## 2. Ba tầng kiểm thử

### 2a. Tự động (chặn)
Chạy trên cây chính SAU khi R-CF đã merge, máy rảnh, không soak song song.
1. `godot/tools/run_tests.sh` KHÔNG cờ `AXIE_SKIP_RULES_FINGERPRINT`, và một lần nữa với `AXIE_RELEASE=1`. Sàn: lấy số ở `technical-preferences.md` (235 + test mới của các làn; ghi số đo thật, không chép). Test đỏ vì môi trường (vd `t_desktop_signin`) phải có nguyên nhân gốc, không "bỏ qua cho xanh".
2. `cd worker && node --test test/*.test.mjs` (sàn 236, nay lớn hơn: ghi số thật).
3. Trước đó, theo plan §5: `grep -c '_tmp' godot/assets/data/economy/missions.json` = 0.
4. Kiểm các test mà review ghi là "chưa chạy": `t_anchor_awaken`, `t_anchor_rules`, `t_enemy_phase_pacing`, `t_overcast` sau khi AT đổi seed; test CombatView cho 6 guard (nếu chưa có, ghi bug S2 thiếu test Logic).
5. Kiểm Logic/Integration có test: mỗi story Logic của các làn phải có test trong `godot/tests/` (bảng test evidence); thiếu là chặn.
6. `--import` sạch, không `SCRIPT ERROR`/`Parse Error` trong log suite; grep `CONFLICT` trong repo.

### 2b. Bot soak lớn (headless, không mạng)
Công cụ: `godot/tools/sim_balance.sh` (cờ `--mode`, `--mission`, `--rules`, `--anchor`, `--force_run_rule`, CSV) + `run_bot.gd`. **Khoảng trống thật:** `sim_balance.gd` hiện không gọi `RunVerifier`/replay (grep không thấy). Cần một việc nhỏ trước: gắn bước "ghi action log -> `RunVerifier` replay -> so kết quả" vào cuối mỗi run (hoặc chạy `verify_run.gd` trên log), ghi `verify=FAIL` kèm seed vào CSV. Giao godot-gdscript-specialist, review lead-programmer. Chưa có bước này thì soak chỉ bắt crash, chưa bắt lệch replay.

Cách phủ (không nhân đủ mọi chiều, vì Anchor x Luật x stage x A x mode x bậc là vài chục nghìn ô):
| Khối | Ô | Run mỗi ô | Chính sách | Tổng ước |
|---|---|---|---|---|
| Run thường | 6 Anchor x {Short, Full} x A0-A9 (stage đủ mở Anchor) | >= 20 | random_legal + attack_spam | ~2.400 mỗi chính sách |
| Luật run | mỗi Luật đang bật x 6 Anchor (bắt cặp) | >= 15 | random_legal + expert | ~ (số luật x 6 x 15) |
| Stage | stage 1, 2, 3+ (đổi cổng Anchor/Vỏ/High Stakes/Mana Mine) | >= 100 mỗi stage | expert | ~300 |
| Nhiệm vụ | N1-N6 x 6 Anchor (N6 chỉ Full, chậm) | >= 100 (N6 >= 30) | random_legal + expert | ~3.600 |
| Quái Atia | seed quét rộng, đếm quái mới bốc ra, độ dài run | >= 1.000 | random_legal | 1.000 |
Mục tiêu tổng: >= 20.000 run bot nhanh (~0,08s/run) và >= 3.000 run expert (~0,9s/run), chia lô <= 600s. Seed liệt kê trong CSV để tái hiện.
Phải bắt:
- Crash, `SCRIPT ERROR`, `Parse Error`, `push_error` lạ trong stdout (đếm theo loại).
- Treo/kẹt: quá `MAX_TURNS`/`MAX_NODES`, hoặc N hành động liên tiếp không đổi trạng thái; màn chọn Anchor/Lõi/offer chờ mãi (tiền lệ: `after_node` đếm node ảo khi Anchor đang chờ).
- Replay lệch: `RunVerifier` không khớp.
- Bất thường số: run thắng bằng 0 lượt, điểm âm, Shard/Stone âm, NaN.
- Phân bố: không ô nào 0 thắng hay 100% thắng ở chính sách expert (báo N-S, không tự sửa); mỗi Anchor/Luật xuất hiện thật ở ô nó cần.
Ngưỡng qua: 0 crash/SCRIPT ERROR/treo/replay-fail trong toàn bộ. Một lỗi hiếm (1/5.000) vẫn là S2 vì sẽ gặp trên production. Chạy lại lô lỗi với cùng seed để chứng minh tái hiện, rồi lưu seed vào bug.

### 2c. Luồng thật trên production
Môi trường: web `axiedice.fun` (Chrome + một trình duyệt khác), desktop mac (bản vừa build, link cố định), Windows nếu có máy (câu hỏi cuối). Kiểm trước: md5 `/index.pck` đủ byte khớp deploy log. Mỗi FLOW ghi: bước, kỳ vọng, kết quả, ảnh/log.
Console: lấy dòng `[epoch_rtt]` từ web (DevTools) và desktop (log file/`--verbose` nếu có; nếu desktop không có console thì hỏi làn SR0 chỗ ghi). Chốt PB/PA: >= 100 mẫu reroll thật trên mỗi nền tảng, ở >= 2 mạng (mạng nhà, 4G/hotspot), nhiều giờ khác nhau. Ngưỡng Liam đặt: p95 > ~1,4 s thì chuyển PA (đo SR0 trước đó từ VN: p50 143-412 ms, p95 780-1860 ms trên HTTP; WS/DO sẽ >= số này). QA chỉ báo số p50/p95/max và tỉ lệ lần phải chờ "Đang kết nối lại"; quyết PB/PA là của Liam.

**Nhiệm vụ (plan §3 N-C):**
- FLOW-1: N1 mua -> chơi -> thắng. Kỳ vọng: Shard trừ cọc đúng, cộng trả đúng, đúng số trên thẻ, lãi ròng khớp, N2 mở ngay (không cần thoát/vào lại), Stone/Shard hiện đúng ở Profile và sau tải lại trang.
- FLOW-2: N1 thua; một lần khác bỏ giữa chừng. Kỳ vọng: mất cược, chữ xác nhận "mất cược và không nhận Shard của run", màn thua nêu lý do cụ thể, hai nút "Về Nhiệm vụ"/"Chơi run thường", không trừ hai lần.
- FLOW-3: N2 khi chưa thắng N1 (tài khoản phụ). Kỳ vọng: nút disabled, lý do "Thắng N1 để mở N2"; thử cách lách (tải lại, mở bằng link, sửa save nếu có công cụ) -> server từ chối, client hiện chữ rõ. Ghi nhận giới hạn Liam chấp nhận: `won` do client báo.
- FLOW-4: mất mạng giữa run Nhiệm vụ (rút dây/tắt wifi giữa lượt; đóng tab; tắt máy). Kỳ vọng: run đóng hoặc tiếp tục đúng, không mất cược hai lần, `reconcileEscrows` hiện đúng số dư khi vào lại, chữ "đang xác nhận cược" nếu chưa chắc.
- FLOW-5: bump giữa run Nhiệm vụ -> hoàn cược. Làm ở R1/R-Atia: mở run Nhiệm vụ ở bản cũ (hoặc giữ một run dở trước deploy), deploy, vào lại. Kỳ vọng: "run cũ, đã hoàn cược", số dư hoàn đủ, không mất run khác. Đây là chỗ DUY NHẤT cần phối hợp với deploy: QA chuẩn bị run dở TRƯỚC khi lane I deploy.
- FLOW-6: bản desktop cũ (giữ một bản trước R1) -> thấy màn "có bản mới", link tải mở đúng, không lỗi thô `rules_mismatch`/409. Lặp lại sau R-Atia.
- FLOW-7 (thêm): Anchor trong Nhiệm vụ: chọn Anchor, thức tỉnh, thắng, replay qua; Anchor không hiện ở Nhiệm vụ ở stage chưa đủ.
- FLOW-8 (thêm): N6 Full: mở cổng đúng (cần run Full thắng), nghỉ giữa run > 3h (nếu không tái hiện được thì kiểm bằng cách giả lập ở Worker test và ghi "chưa kiểm tay").

**Land:** FLOW-9 đủ 20k Stone -> nâng tier 2 -> tự về Land -> banner một lần -> chip HUD -> Axie của mình -> đặt decor Rare tier 2 -> mốc m4 nhận. FLOW-10 đăng xuất/nhập lại và đăng nhập máy khác: banner/món khởi đầu không lặp, nâng tier còn nguyên. FLOW-11 bàn phím/gamepad: mở modal tier bằng Enter/A. FLOW-12 Land trên desktop đầy đủ; web nhẹ nếu có.

**Server RNG / kinh tế / khách:**
- FLOW-13 reroll thường xuyên trong 3 run (Short) ở RTT bình thường; lặp với giả lập chậm (Network Link Conditioner trên mac / throttling DevTools: Slow 3G) và ghi xúc xắc có "đứng hình" hay "nhảy sai mặt" không (mặt hiển thị đổi sau khi lăn xong là S2).
- FLOW-14 ngắt mạng giữa lượt: lúc xúc xắc đang bay; lúc chờ seed; lúc bấm END TURN; lúc ở màn thưởng. Kỳ vọng: không treo vĩnh viễn, có chữ "mất kết nối"/"kết nối lại", nối lại thì tiếp tục đúng lượt, quá 30 s -> "offline" nêu rõ cách thoát, run không bị đếm hai lần.
- FLOW-15 đăng nhập máy khác giữa run: máy A đang run, máy B đăng nhập cùng tài khoản. Kỳ vọng: một run mở, A bị kick/báo rõ hoặc B bị chặn mở run, không hỏng log, không mất cược; đăng xuất B không giết token A (bẫy `sid`).
- FLOW-16 reset M1 (R3, tài khoản phụ trước, rồi tài khoản Liam khi Liam đồng ý): trước reset ghi số dư, sau reset = 0 ở web và desktop và máy thứ hai, đăng xuất/nhập lại vẫn 0, mua lại được món khởi đầu. Xác nhận snapshot D1 + cloud save đã chụp TRƯỚC (hỏi lane I).
- FLOW-17 khách: mở game không đăng nhập, chơi tutorial + run thường, thử ranked/Nhiệm vụ/Store (bị chặn có chữ), đăng ký giữa chừng (tiền không mang sang).
- FLOW-18 cổng mở game: không mạng -> màn "Cần kết nối" (không crash, không trắng); mạng về -> vào được.

**Hồi quy (mỗi dòng một FLOW ngắn, web + desktop):** FLOW-19 run thường Short thắng tới kết quả + nhận thưởng + lên stage; FLOW-20 ranked 1 run + leaderboard; FLOW-21 daily nhận; FLOW-22 tutorial người mới trọn vẹn (tài khoản phụ); FLOW-23 Echo Box mở 3 hộp (pity, vé, trùng); FLOW-24 Pass nhận mốc; FLOW-25 Store mua 1 món rẻ; FLOW-26 đăng ký/đăng nhập/đăng xuất web + desktop PKCE; FLOW-27 cloud save hai máy (đổi Cosmetics ở máy A, thấy ở B); FLOW-28 Profile + Codex; FLOW-29 tiếp tục run dở sau đóng tab; FLOW-30 Atia: 10 run thường ghi quái gặp; FLOW-31 cosmetics: trang bị 8 khung mới, chụp ở Profile; FLOW-32 chọn từng 6 Anchor ở stage mở (ít nhất tới thức tỉnh một lần mỗi Anchor); FLOW-33 desktop: cửa sổ đổi cỡ, toàn màn hình, thoát giữa run, mở lại.
Desktop thêm: không `override.cfg` trong gói (`check_export_no_override.py`), cài/chạy trên máy sạch, tên/biểu tượng đúng, đăng nhập PKCE mở trình duyệt và quay lại app, link tải cố định dùng được.

## 3. Săn chỗ khó hiểu

Đây là hạng mục riêng vì Liam từng gặp "lỗi khó hiểu" rồi quên. Coi mỗi chỗ người chơi phải đoán là một bug, không phải "ý kiến".
- **Ai:** ux-designer + qa-tester chơi như người mới trên tài khoản phụ, KHÔNG đọc doc thiết kế trước; một lượt thứ hai ở tài khoản Liam (stage cao). Hai người chơi tách nhau để so (người thứ nhất nói to điều họ nghĩ, người thứ hai chỉ ghi).
- **Cách ghi:** mỗi màn xem >= 5 giây không bấm gì, hoặc bấm nhầm, hoặc hỏi "vừa xảy ra gì?" = ghi một dòng (màn, họ tưởng gì, thực tế gì). Gom vào bug loại `KHÓ HIỂU`. Ảnh 1920x1080 và 1280x720 cho mỗi chỗ.
- **Câu hỏi chung ở MỌI màn/khoảnh khắc:**
  1. Người chơi biết vừa có gì thay đổi không (tiền, Lõi, máu, lượt, tier)? Có chữ/âm/hiệu ứng nào nói không?
  2. Biết số liệu đó đến từ đâu (vì sao thua, vì sao +N Shard, vì sao nút xám)?
  3. Biết bước tiếp theo bấm gì không? Nút xám có lý do bằng chữ không?
  4. Có mất tiền/tiến độ mà không được cảnh báo trước không?
  5. Chữ có khớp giữa thẻ, chip, màn thua, Codex không (cùng một luật, cùng tên)?
  6. Chữ có bị cắt/đè/tràn ở 1280x720? Có `undefined`/`NaN`/khoá id thô?
  7. Khi chờ mạng, có chữ/biểu tượng báo đang chờ không, hay trông như treo?
  8. Cái mới (Anchor, quái, khung, tier) có thấy được trong run thường mà không cần chỉ đường không?
- **Màn trọng điểm:** thẻ Nhiệm vụ (cược/trả/lãi/ước tính/cảnh báo), màn thua Nhiệm vụ, màn "có bản mới", màn "đang xác nhận cược", chọn Anchor + chip + thức tỉnh + Result/Codex, chọn Luật run, thẻ Lõi, nhãn SHELL/"Outside a SET", banner/chip Land, màn nâng tier, Profile Land, quái Atia mới (chúng làm gì khác?), hoàn cược, "offline"/"kết nối lại", khoá input khi chờ seed (nút xám vì sao), cổng mở game, khách bị chặn (vì sao), reset M1 (người chơi biết vì sao số dư về 0 không? Có màn/thông báo giải thích không), khung cosmetics trùng, Echo Box pity.
- Cách thứ hai để bắt lỗi lúc quên: nhờ Liam chơi tự do một buổi và ghi ngay một dòng vào `production/qa/bugs/liam-notes.md` mỗi khi khựng lại (không cần giải thích đầy đủ). Mình/qa-tester biến mỗi dòng thành bug sau.

## 4. Mức lỗi, mẫu, nơi lưu, tiêu chí xong

Nơi lưu: `production/qa/bugs/BUG-NNNN.md` (thư mục chưa có, tạo khi lỗi đầu tiên được ghi) + `production/qa/bugs/INDEX.md` (một dòng/bug: ID, mức, hệ thống, trạng thái, người nhận). Bằng chứng (ảnh, log, seed) trong `production/qa/evidence/beta/<BUG-ID>/`.

| Mức | Nghĩa trong game này | Ví dụ |
|---|---|---|
| S1 | Crash, treo vĩnh viễn, mất/đúc tiền hoặc tiến độ sai, không vào được game/run, replay lệch với run thật, lộ đường gian lận | Mất cược hai lần; reset không xoá cloud; run treo sau ngắt mạng; khách mua được Nhiệm vụ |
| S2 | Tính năng hỏng, thông tin tiền/tiến độ sai hoặc gây hiểu nhầm, lỗi "khó hiểu" liên quan tiền/cược/mất tiến độ, hình hỏng nặng, thiếu test Logic/Integration | Nhãn khoá sai ("thắng N1 1/1"); mặt xúc xắc đổi sau khi lăn; banner Land lặp |
| S3 | Khó hiểu không liên quan tiền, chữ bị cắt, hình/animation thiếu, nhịp lạ, lỗi hiếm có đường thoát | Quái không có anim hit; nhãn chip khác thẻ |
| S4 | Chữ nhỏ, căn lề, gợi ý | |
Thêm cờ `KHÓ HIỂU` (độc lập mức) và `NỀN TẢNG` (web/mac/win). Lỗi chỉ ở 1 nền tảng ghi rõ.

Mẫu (theo `/bug-report`, rút gọn):
```
# BUG-NNNN: <tiêu đề ngắn>
Mức: S1-S4 | Cờ: KHÓ HIỂU? | Hệ thống: | Nền tảng: web/mac/win | Tần suất: luôn/hay/thỉnh thoảng/hiếm
Build: commit + RULES_VERSION + md5 pck | Tài khoản: Liam/qa-fresh/khách | Ngày: | Người ghi:
Điều kiện trước:
Các bước: 1. 2. 3.
Kỳ vọng:
Thực tế:
Bằng chứng: ảnh 1920x1080 + 1280x720 / log / seed / số dư trước-sau
Nghi ngờ: file, hệ thống, hồi quy từ đâu (nếu biết)
Giao: <agent/lane>   Trạng thái: Open / Fixed / Verified / Closed
```
Vòng đời: Open -> giao lane sở hữu file -> Fixed (commit) -> qa-tester verify (chạy lại đúng các bước, và FLOW liên quan) -> Closed. Không đóng khi chưa verify.

**Tiêu chí "xong QA" (giao Liam polish):**
1. Tầng 2a: suite không cờ skip và `AXIE_RELEASE=1` xanh, Worker xanh, không test nào bị tắt để xanh; số đo thật ghi vào `technical-preferences.md` (cùng commit đổi sàn).
2. Tầng 2b: soak đủ ngưỡng mục 2b, 0 crash/SCRIPT ERROR/treo/replay-fail trên bản cuối; mỗi lô lưu CSV + seed.
3. Tầng 2c: FLOW-1..33 đã chạy trên bản deploy cuối, web + mac (+ Windows nếu có), đều PASS hoặc có bug đã Closed; FLOW-5, 14, 15, 16 không thể bỏ.
4. Không còn S1 và S2 mở. S2 tồn đọng chỉ khi Liam đồng ý bằng văn bản, ghi trong báo cáo.
5. S3 mở: liệt kê toàn bộ cho Liam (Liam polish được). Tối đa không giới hạn nhưng không S3 nào "KHÓ HIỂU" liên quan tiền/cược chưa được xem.
6. Săn chỗ khó hiểu: đã chạy xong hai lượt (người mới + tài khoản Liam) trên mọi màn trọng điểm, mọi dòng đã thành bug hoặc có lý do "chủ ý".
7. RTT: có báo cáo p50/p95/max trên web và desktop, Liam đã quyết PB hay PA.
8. Báo cáo `production/qa/beta-qa-report.md`: build, số liệu từng tầng, danh sách bug mở, rủi ro còn lại, đề xuất GO/NO-GO. Mình ký; Liam quyết.

## 5. Thời gian và phân công

| Việc | Ai | Khi | Ghi chú |
|---|---|---|---|
| Gắn `RunVerifier` replay vào soak + cờ báo cáo | godot-gdscript-specialist; review lead-programmer | ngay (trước R-Atia), ~0,5 ngày | không chờ R-CF |
| Viết sẵn kịch bản FLOW-1..33 (bước, kỳ vọng, bảng ghi) | qa-lead + qa-tester | trước R1, ~0,5 ngày | dùng lại ở mỗi đợt |
| QA nhỏ mỗi đợt (FLOW của hệ thống + smoke `/smoke-check`) | qa-tester; qa-lead triage | R1 (FLOW-1..8, 13, 14, đo RTT bắt đầu), R2 (9-12), R-Atia (30, 5, 6), R3 (15-18), R-CF (31) | ~0,5 ngày mỗi đợt |
| Soak đêm (cây chính, worktree riêng) | qa-tester vận hành, bot tự chạy | đêm 1-2 sau R-CF; chạy thử nhỏ sau mỗi đợt | CPU: không chạy cùng suite |
| Suite + Worker (tầng a) | lane I / qa-tester | sáng ngày 1 sau R-CF, ~1 giờ | trước soak |
| FLOW web + mac (tầng c) | qa-tester (tài khoản phụ) + qa-tester thứ hai/qa-lead (tài khoản Liam, nối tiếp) | ngày 1-2 | song song giữa hai tài khoản và hai nền tảng |
| Windows | Liam hoặc tester có máy | ngày 2 | nếu không có: ghi "chưa kiểm Windows", rủi ro S2 chưa rõ |
| Săn chỗ khó hiểu | ux-designer + qa-tester | ngày 1-2, song song FLOW | ảnh 2 cỡ |
| Triage + giao lỗi + verify | qa-lead (triage), lane sở hữu (sửa), qa-tester (verify) | liên tục; ngày 3 là vòng sửa-verify cuối | |
| Báo cáo + ký | qa-lead | cuối ngày 3 | |

Ước tổng: 2 ngày như plan cho tầng (b) + (c) + săn khó hiểu chạy song song, nhưng **không đủ nếu có S1/S2**: mình đề nghị đặt **3 ngày** (ngày 3 = vòng sửa + verify + chạy lại FLOW bị ảnh hưởng và một lô soak ngắn). Việc không phụ thuộc R-CF (harness replay, kịch bản FLOW, QA nhỏ từng đợt, đo RTT tích luỹ từ R1) làm trước để QA tổng chỉ còn việc xác nhận.
Song song được: (b) ban đêm với (c) ban ngày; tài khoản phụ web ∥ tài khoản phụ desktop ∥ ux săn khó hiểu. Không song song được: hai FLOW trên tài khoản Liam; suite ∥ soak; FLOW-16 (reset) với bất kỳ FLOW kinh tế khác trên cùng tài khoản.

## Câu hỏi cho Liam (3)
1. Cho mình tạo 1-2 tài khoản phụ `qa-fresh` trên production (người mới, khách -> đăng ký, đăng nhập máy khác)? Khuyến nghị: có; nếu không, FLOW-3, 15, 17, 22 không làm sạch được.
2. Có máy Windows (của Liam hay tester) để chạy FLOW-26/33 và bản desktop Win không? Nếu không, ghi rõ Windows chưa kiểm.
3. Khi mình cần tài khoản Liam (FLOW-1..2, 4, 5, 9, 15, 16), Liam báo khung giờ không chơi; trong khung đó mình chạy nối tiếp và không đụng run Full dở của Liam. Được không?
