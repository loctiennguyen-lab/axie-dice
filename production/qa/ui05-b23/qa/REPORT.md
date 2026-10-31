# QA luồng thật UI-05 đợt 2+3 (u5b-qa @ dedd7a6) — BẢN DỞ, cập nhật dần

Trạng thái: phần 1 (chụp) xong, phần xem ảnh CHƯA làm, nên chưa có lỗi nào được xác nhận bằng mắt. Không có "OK" nào dưới đây là OK về mặt hình ảnh.

## Đã chạy
- Import sạch (0 Parse Error / SCRIPT ERROR).
- 33 scene capture `qa_ui5_*_capture` chạy ở cửa sổ thật (không headless) 1920x1080 và 1280x720: tất cả rc=0, 0 SCRIPT ERROR, 0 dòng QA_CLIP/QA_ANOMALY. Ảnh: `production/qa/ui05-b23/qa/{1920,1280}/<scene>/` (330 ảnh mỗi cỡ, `_run.log` cạnh ảnh). Capture ghi thêm bản `--1280` ngay trong thư mục 1920 (tự ghim scale).
- `t_soak_verify`: PASS 24 checks (`qa/t_soak_verify.log`).
- Luồng cả run qua UI (`qa_ui5_flow_capture`: win/free/paid/boost/reduce motion): chạy nền, kết quả ở `qa/flows/_summary.txt` (chưa đọc).
- `soak_matrix.sh run` bản giảm (N_FAST=3, N_EXPERT=2, ngày 2026-10-31-ui5b23): chạy nền, chưa report.

## Chưa kiểm được / lỗi của chính capture
- `qa_ui5_anchor_capture` và `qa_ui5_codex_capture` KHÔNG ghi vào thư mục đã truyền (ghi cứng vào `r3/` và `s13/`); đã chép ảnh sang `qa/anchor/`, `qa/codex/`. Ghi lại để làn sửa.
- Không có capture riêng cho Land HUD chính (chỉ overlay first-visit/offline), Settings reduce-motion đi moment, đăng nhập thật (cần Liam), `live_smoke` (cấm).
- `qa_real_flow_capture` chỉ là chụp 1 trận combat, không phải luồng nhiều màn.

## Đã xem bằng mắt (chỉ 3 contact sheet: moments b2/b3, core offer selected, treasure opened, echo mythic)
Chưa xem: phần lớn 660 ảnh còn lại (meta screens, 1280 hàng loạt, Land, Settings, Store...). Báo cáo này KHÔNG xác nhận chúng OK.

### Chặn kiểm chứng (không phải lỗi game đã chứng minh)
0. Luồng CẢ RUN qua UI không đi được: `qa_ui5_flow_capture` (win 1920, win 1280, free 1920; paid/boost/reduce cùng kẹt) dừng ngay ở màn "Choose a run rule" (bản đồ run, power level 0, run ranked stage 3 seed 59): driver không nhận ra overlay rule offer mới của R2b (`[Scrim, ScreenContent]`, 124 anomaly, "no progress 90 s", 0 trận). Ảnh: `flows/win-1920/flow-win--unknown-overlay-0-1920x1080.png`. Màn bản thân trông đúng (không chọn sẵn, "Pick a rule" tắt), nhưng driver chưa xử lý nên KHÔNG có run nào do UI đi được đưa qua `RunVerifier` ở đợt này, không có ảnh combat/reward/shop/event/result thật liên tiếp, và reduce-motion qua flow không chạy được. Cần sửa driver (thêm nhánh rule offer, chọn thẻ 0 + Take) rồi chạy lại: `QA_FLOW=win QA_SEED=59 ... shot.sh res://tests/qa_ui5_flow_capture.tscn`. Tôi không sửa code theo luật.
   Thẻ rule này hiện kicker "Run rule" rồi lại nhãn "Rule" ngay dưới tiêu đề (trùng, nhỏ).

### Chặn deploy
Chưa thấy lỗi game nào chặn deploy trong phần đã xem; nhưng phần chưa xem + luồng cả run chưa kiểm nên KHÔNG đủ cơ sở kết luận cho phép deploy.

### Nên sửa
1. Echo open Mythic (moment M3, ảnh `1920/moments_b3/echo-open-mythic-flip.png`): thẻ "Heart of Luna" khung art TRỐNG (tối, không có xúc xắc). Cùng màn chụp bằng `qa_ui5_echo_ceremony_capture` thì art HIỆN đủ (`1920/echo_ceremony/20-echo--reveal-mythic-1920x1080.png`, 1280 cũng vậy). Nghi: art nạp chưa kịp ở lần reveal đầu của phiên, đúng như ghi chú "ảnh M3 chụp lúc art chưa nạp". Chưa tái hiện trong chơi thật; cần Liam/làn M3 mở hộp thật 1 lần xem.
2. Pass (ảnh `1920/moments_b3/pass-level-up-mid.png`): 3 ô nhiệm vụ tuần có nút "Claim · The season has not started running" xuống 3 dòng, chật; trong khi cùng lúc thanh "Claim all · 10 levels" vẫn bật khi mùa chưa bắt đầu (đã nằm trong câu hỏi gom cho Liam).
3. Treasure-open (ảnh `1920/moments_b2/treasure-open-rest.png`): chỉ 1 thẻ "Level Up" nằm sát mép trái, tiêu đề "Choose one" cũng sát trái, nút "Pick a reward" ở giữa. Capture `event_treasure` (3 thẻ) thì căn giữa đúng, nên nghi capture M2 dựng 1 thẻ chứ không phải lỗi game; cần xác nhận khi chơi thật (treasure có 1 lựa chọn).

### Nhỏ
- Land tier-up (`1920/moments_b3/land-tier-up-mid.png`): khung hình giữa moment không thấy hở dải trên; 300 ms đầu CHƯA kiểm được (capture chụp mốc "mid", không phải t=0..300 ms).
- Core reveal (`1920/moments_b2/core-reveal-a.png`): thẻ thứ 3 đang lật bị co hẹp, bình thường cho giữa lật; chữ trong thẻ co cũng bị méo giữa chừng, không phải lỗi.

### Đã thấy OK
- Core offer selected: chọn thẻ thì nút Take bật kèm keycap Space; thẻ không được chọn sẵn ở trạng thái facedown ("Reveal the cards first" + "Pick a Core" tắt, không keycap).
- Treasure opened 1920/1280: 3 thẻ căn giữa, "Pick a reward" tắt khi chưa chọn, không chọn sẵn.
- Echo reveal Mythic ở capture ceremony: art, nút Equip/Open again/Done, keycap chỉ ở Done.
- Result win/lose mid-moment: nút "Back to Land" có Space, không thấy cắt chữ.
- Anchor awaken mid: chip + tên "Thorn Storm" hiện, không rung rõ.

## Soak / verify
- `t_soak_verify`: PASS 24 checks.
- `soak_matrix.sh run` bản giảm (N_FAST=3 N_EXPERT=2, 381 ô) đang chạy NỀN trong worktree `soak-sim1..3` (+ ra `production/qa/soak/2026-10-31-ui5b23/`). Lấy kết quả: `bash godot/tools/soak_matrix.sh report 2026-10-31-ui5b23` (chạy trong worktree u5b-qa). KHÔNG có kết quả trong báo cáo này.
- Luồng cả run qua UI (win/free/paid/boost/reduce) cũng chạy nền, kết quả `qa/flows/_summary.txt` (dòng QA_FLOW_RESULT có verify). Chưa có.

## Reduce motion / reduce flashing
Chưa kiểm (có flow `reduce-1920` trong hàng đợi, chưa xong; moment core-reveal/anchor-awaken/echo mythic với Settings bật chưa chụp).

## Soak 2026-10-31-ui5b23 (bản giảm, 381 ô)
- 2856 run, 0 run xấu (bản 28/10: 3 STUCK_TURNS), verify ok 1326, skip_forced 1530 (flow ép, bỏ verify theo thiết kế).
- 1905 dòng `ERROR: Couldn't open directory at path "user://acct"` — y hệt bản soak 28/10 (trước UI-05): nhiễu môi trường, không mới.
- Báo cáo: `production/qa/soak/2026-10-31-ui5b23/SUMMARY.md`.

## Flow UI cả run (Q2, sau khi sửa driver)
- 1920, 1280, reduce motion: hết run, 10 trận, 0 anomaly; RunVerifier raw + patched ok, `patched_matches_ui` true.
- "Khối cam" đầu lượt 1 = band Your turn đang trượt ra (đúng spec), không phải lỗi.

## Lỗi đã sửa sau QA (F1, F2)
- Daily nút Claim đè thẻ; Echo reveal art trống (giữ thumb rồi drop theo spec UI-03); tab bar focus theo tab chọn; Missions N6 cắt dòng; Echo Series tên 1 dòng; GachaFx skip ComboBanner.
- KHÔNG sửa: keycap Space trên End turn lúc lượt địch — frame round-1 vẽ nó (Space tua FX).
