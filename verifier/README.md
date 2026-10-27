# Verifier SR-V (chạy bóng)

Replay lại một run đã đóng bằng chính luật của game (`RunVerifier`), tính lại điểm, rồi báo cho Worker so với điểm client. **Chỉ ghi nhận.** Không đổi điểm, thưởng hay bảng xếp hạng.

Lược đồ job/kết quả giữa Worker và runner: `verifier/JOB_SCHEMA.md` (do làn Worker viết, nằm ở nhánh `srv/worker`).

## Nó làm gì, không làm gì
Làm:
- Kéo job từ `POST /api/verify/next`, replay bằng Godot headless, nộp 8 khoá kết quả vào `POST /api/verify/result`.
- Header do server quyết (`rules_version, mode, ascension, ranked, depth_stage, mission`). Server báo `header_mismatch` thì từ chối luôn, `reason = header_mismatch`.
- Bonus (reroll, HP, relic đầu) lấy từ `server_loadout.bonuses`, không bao giờ từ client. `anchor, rules_on, core_off, boon_id` lấy từ `client_header.loadout`, riêng `forced` của server đè lên (ranked ép `rules_on=true, core_off=false, anchor=false`).
- Perk của Pass cũ không được tính khi economy do server giữ (`axie/econ="remote"`). Economy local và test không đổi.

Không làm:
- Không chặn mạng cho Godot trên macOS (xem dưới). Code verifier không gọi mạng, nhưng hệ điều hành không cấm nó.
- Không quyết định gì thay Worker. Không ghi D1, không đụng save thật.
- Chưa kiểm `mission_id` (server không lưu), chỉ so tier + rules.
- Bonus chỉ đúng khi economy do server giữ (unlock nằm ở D1). Trước R3 bảng `unlocks` trống thì mọi run đều replay với bonus 0.

## Cài trên máy Liam
1. Lấy khoá HMAC (cùng giá trị với secret `VERIFY_HMAC_KEY` của Worker; secret chỉ đặt bằng `wrangler secret put`). Lưu ra file ngoài repo:
   ```
   mkdir -p ~/.axie-verifier && chmod 700 ~/.axie-verifier
   printf '%s' '<khoá>' > ~/.axie-verifier/hmac_key && chmod 600 ~/.axie-verifier/hmac_key
   ```
   Runner từ chối chạy nếu file không phải mode 600 hoặc nằm trong repo. Khoá không bao giờ được in ra hay đưa vào dòng lệnh.
2. Checkout repo ở đúng commit đang chạy production (cùng `RULES_VERSION`). Runner dùng Godot ở `/Users/loc.tien.nguyen/Desktop/Godot.app`; đổi bằng `GODOT_BIN`.
3. Thử một lần: `bash verifier/runner.sh --once` (exit 0 = xử lý một job, 3 = hết job, khác = lỗi).
4. Chạy liên tục: `bash verifier/runner.sh` (dừng bằng Ctrl-C). Hoặc chạy nền bằng launchd: sửa `verifier/com.axiedice.verifier.plist.template` (REPO_PATH, USER_HOME), chép vào `~/Library/LaunchAgents/com.axiedice.verifier.plist`, `launchctl load ...`; dừng bằng `launchctl unload ...`. Mẫu này chưa cài.
5. Log: màn hình, hoặc `~/.axie-verifier/runner.log` nếu chạy qua launchd. Mỗi job một dòng (`job <run_id>: godot exit N, nộp -> HTTP 200`).

Biến môi trường: `AXIE_VERIFY_URL` (mặc định https://axiedice.fun), `AXIE_VERIFY_KEY_FILE`, `GODOT_BIN`, `AXIE_VERIFY_ROOT`, `AXIE_VERIFY_POLL` (giây nghỉ khi hết job, mặc định 15), `AXIE_VERIFY_JOB_KILL` (giây tối đa cho một lần replay, mặc định 120).

Save thật: Godot chạy qua `godot/tools/with_lock.sh`, nên dùng user dir cô lập (`AxieDice-test-<repo>` ở cây chính, hoặc user dir của `override.cfg` trong worktree), tự chụp và trả lại save, có hang-kill. Vẫn nên chạy runner trên checkout riêng, đừng chạy cùng lúc với lúc Liam chơi.

Không có kết quả hợp lệ (Godot treo, crash) thì runner không nộp; lease 300 giây hết thì job được kéo lại, tối đa 3 lần.

## Godot không bị chặn mạng trên macOS
Linux có `--network none` trong container. macOS không có cách tương đương cho một tiến trình, nên Godot trên máy Liam **có quyền ra mạng**. Giảm rủi ro: verifier là code của mình, không có lệnh HTTP, input là JSON đã qua kiểm schema, kết quả ra chỉ là 8 khoá cố định. Muốn cách ly thật thì dùng Docker (`Dockerfile`, `build.sh`, vẫn là dự thảo chưa chạy) hoặc máy riêng có firewall.

## CLI
`Godot --headless --path godot res://tools/verify_run.tscn -- --in=job.json --out=result.json` (`--in=-` đọc stdin).
`job.json` là `payload` của job (schema 1), hoặc một log bundle trần (`header/entries/tape`) như trước.
Exit: 0 hợp lệ, 1 bị từ chối, 2 input hỏng/quá trần.
Kết quả luôn đúng 8 khoá: `ok, reason, rules_version, outcome(won|lost|rejected|invalid), score, nodes, log_len, ms`.
Trần: input 8 MB, 20.000 action, reason <= 64 ký tự. Không có message tự do.

## Client
`run_close` gửi thêm `log_header` (`team_keys, content_version, local_secret, loadout{anchor, rules_on, core_off, boon_id}`, <= 2 KB), vì server không có header của log. Worker cũ bỏ qua field này. Không gửi bonus.

## Test
- `godot/tests/t_verify_cli` (CLI + job schema 1, header_mismatch, bonus của server, forced), `t_verify_cross_platform` (golden), `t_perks_remote_econ`, `t_run_session` (log_header).
- `bash verifier/test_runner.sh`: chạy `runner.sh` với server giả cục bộ (`stub_server.py`), kiểm HMAC, job khớp, job `header_mismatch`, file khoá sai mode, khoá không bị in. ~20 giây.

## Tiêu chí thoát khỏi chế độ bóng
- 0 lệch (mọi run hợp lệ cho cùng điểm).
- >= 500 run thật mỗi nền tảng (web, mac, Windows).
- >= 7 ngày chạy liên tục.
- Chi phí/run và p95 thời gian (mục tiêu < 5 s) được Liam duyệt.

Rủi ro tất định chéo nền tảng và đo thời gian: `production/qa/verifier-determinism-risks-2026-10.md`, `production/qa/verifier-timing-2026-10.md`.
