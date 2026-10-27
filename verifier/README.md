# Verifier B2 (chạy bóng)

Replay một run log bằng chính luật của game (RunVerifier), tính lại điểm. Bước đầu chỉ chạy bóng: so với điểm client, KHÔNG chặn, KHÔNG quyết định bảng xếp hạng.

## CLI (đã có, đã test: `t_verify_cli`)
`Godot --headless --path godot res://tools/verify_run.tscn -- --in=log.json --out=result.json`
(`--in=-` đọc stdin). Exit: 0 hợp lệ, 1 bị từ chối, 2 input hỏng/quá trần.
Kết quả luôn đúng 8 khoá: `ok, reason, rules_version, outcome(won|lost|rejected|invalid), score, nodes, log_len, ms`.
Trần: input 8 MB, 20.000 action, reason <= 64 ký tự. Không có message tự do. Mã nằm ở `godot/tools/verify_cli.gd`.

## Yêu cầu cứng (brainstorm mục 3, P3)
1. Không mạng ra (`--network none`, hoặc Container tắt được egress; không tắt được thì máy riêng V2).
2. Không secret trong env/image. Không `.env`, không token.
3. Chỉ nhận job có ký: chữ ký kiểm ở lớp ngoài (queue consumer) TRƯỚC khi đặt `in.json`. Verifier không tự lấy log.
4. Không ghi D1: lớp ngoài đọc `out.json`, kiểm schema (`VerifyCli.check_schema` hoặc bản JS tương đương), rồi mới ghi bảng `verify_results` (migration `0012_verify`).
5. User không root (uid 10001), filesystem chỉ /work.

## Build (dự thảo, chưa chạy)
1. `bash verifier/build.sh` -> `verifier/verifier.pck` (cần export preset phù hợp; hiện chưa có preset pack-only cho verifier).
2. Điền `GODOT_SHA256` trong Dockerfile. `docker build -t axie-verifier verifier/`.
3. Chạy thử: `docker run --rm --network none -v $PWD/job:/work axie-verifier` (job/in.json -> job/out.json).
Pck phải cùng commit với bản game đang chạy; `rules_version` trong kết quả giúp lớp ngoài phát hiện lệch.

## Chạy bóng
Với mỗi run online xong: queue đẩy log + tape đã ký -> verifier -> so `score`/`outcome` với điểm Worker/client ghi. Ghi lệch vào log, không đổi điểm thật. Run bị `rules_version_mismatch` loại khỏi thống kê (không phải gian lận).

## Tiêu chí thoát khỏi chế độ bóng
- 0 lệch (mọi run hợp lệ cho cùng điểm).
- >= 500 run thật MỖI nền tảng (web, mac, Windows).
- >= 7 ngày chạy liên tục.
- Chi phí/run và p95 thời gian (đo ở Container, mục tiêu < 5 s) được Liam duyệt.

## Chưa làm / cần quyết
Tài khoản và chi phí Cloudflare Containers, kiểm egress thật, export pck, queue consumer + `verify_queue.js`, migration 0012. Xem `production/qa/verifier-timing-2026-10.md` và `production/qa/verifier-determinism-risks-2026-10.md` (rủi ro tất định chéo nền tảng).
