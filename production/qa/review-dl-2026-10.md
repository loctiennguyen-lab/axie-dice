# Review làn DL (beta/dl 0365666, d081587, 767edfb), security-engineer, 26/10

Verdict: **ĐẠT CÓ ĐIỀU KIỆN**. Không có lỗ hổng chặn. 1 mục CHẶN nhẹ về hướng dẫn mở app mac (trang đang chỉ
cách cũ), còn lại NÊN SỬA. Worker test chạy lại: 307/307.

## 1. Route /download (worker/src/downloads.js)
- Path traversal: OK. Kiểm trên tên đã decode một lần: `%2e%2e`, `%2F`, `%5C`, `.`, `..`, đoạn rỗng, ký tự
  điều khiển, NUL đều bị 404. `%252e%252e` decode ra chuỗi `%2e%2e` chữ, chỉ là một key không tồn tại. R2 key
  không phải đường dẫn file nên unicode/NFC không thoát được prefix. Luôn nối `downloads/`.
- Không lộ key khác: chỉ ext zip/dmg/exe/sha256/txt/json; `downloads/latest.json` bị chặn đúng. Còn
  `downloads/old/*` tải được (chủ ý, rollback). `old/latest.json` tải được, vô hại.
- Header: Content-Type luôn octet-stream, Disposition attachment, tên bị lọc `"` và `\`, CR/LF bị chặn từ trước.
- HTML: mọi giá trị từ manifest qua `esc()`, href qua `encodeURIComponent`, `file` đã validate qua
  `downloadKeyFor`, size/sha validate. Không thấy đường XSS từ `latest.json`.
- NÊN SỬA (nhỏ): (a) tên file có ký tự > 255 (unicode) làm `new Headers` ném lỗi, ra 500 thay vì 404; thêm
  `/^[\x20-\x7e]+$/` vào `downloadKeyFor`. (b) thêm `X-Content-Type-Options: nosniff`. (c) lỗi manifest 500 in
  nguyên lý do ra ngoài; chỉ trả "unavailable", ghi lý do vào log. (d) không hỗ trợ `Range`, file 300 MB tải
  đứt là phải tải lại; ghi nhận, chưa cần cho beta nhỏ.
- Cache: zip max-age 3600 + ETag, tên chứa build nên an toàn. Trang HTML 60s. Đúng, không cần đổi.
- Giới hạn tin cậy: sha256 trên trang cùng nguồn với file, nên chỉ chống hỏng, không chống bị thay. Gói chưa ký.

## 2. publish_desktop.sh
- sha256 và cỡ tính lại bằng `shasum`, không tin file .sha256. Từ chối gói `-dirty`, từ chối commit khác HEAD
  (commit rỗng cũng bị từ chối). Không đọc/in secret, không gọi wrangler. Thứ tự put: zip rồi `latest.json` CUỐI, đúng.
- NÊN SỬA: (a) `--allow-dirty` bỏ luôn kiểm commit; nên chỉ bỏ kiểm `-dirty`. (b) so commit bằng glob prefix
  theo `rev-parse --short` (7 ký tự), nếu repo tự nới abbrev sẽ từ chối nhầm; dùng `git rev-parse HEAD` so
  tiền tố. (c) `--prev` do người chạy chỉ file tay, không bắt buộc trùng với `latest.json` đang trên R2; thêm
  bước so sha hai bản trước khi xoá file cũ. (d) STAMP không validate, chỉ cho `[A-Za-z0-9._-]+` vì nó được
  nhét vào lệnh in ra. (e) `npx wrangler` chưa ghim phiên bản (DL đã ghi).
- Lệnh upload đúng: `r2 object put axie-dice/downloads/<file> --remote`, dưới 300 MiB. Bước "DỪNG nếu get lỗi" chỉ
  là chú thích; người chạy phải tự dừng (checklist có nói "dừng ở lỗi đầu tiên").

## 3. release_gate.sh
- Chạy thực: hiện exit 1 vì 8 dòng `_tmp`, đúng. Suite chạy với `AXIE_RELEASE=1`, và test
  `t_mission_unlock_chain` thật sự đổi WARN thành FAIL khi có cờ này. Suite đỏ -> exit 1, worker đỏ -> exit 1.
- NÊN SỬA: (a) tham số lạ (`--siute`) chạy như bản nhanh và vẫn exit 0 nếu hết `_tmp`, tức bỏ qua suite mà
  người chạy tưởng đã chạy; từ chối tham số lạ. (b) `build/` chưa có thì ghi log lỗi, báo nhầm "worker test đỏ";
  `mkdir -p build`. (c) gate chưa được nối vào `export-web.sh`/`deploy-r2.sh` (gitignored), mới ở mức đề xuất:
  tới khi áp, nó chỉ là bước tay.

## 4. release-steps-beta.md
- Đủ: D1 migrations (chỉ ADD) apply TRƯỚC `wrangler deploy`, lưu id Worker để rollback, pck md5 + Range 206,
  rollback đổi `latest.json` cùng lúc Worker, cửa sổ 7 ngày `-t`.
- NÊN SỬA: (a) bước 3 "Lưu bản cũ latest.json vào build/old/" nằm sau build nhưng nên làm TRƯỚC khi up, và lấy từ
  R2 (get) chứ không dùng bản local. (b) rollback desktop cần `downloads/old/*.zip` có thật: chỉ đúng nếu đã
  chạy với `--prev`; ghi rõ "không --prev thì không có đường lùi". (c) thêm: sau rollback kiểm `/download` hiện
  lại version cũ. (d) ghim `wrangler@4.151.3` ngay trong checklist, đừng để ở "chưa làm".

## 5. Build / override.cfg / Gatekeeper
- override.cfg: có 3 lớp (preset `exclude_filter`, guard tạm trong `build_desktop.sh`, backstop
  `check_export_no_override.py` quét pck, fail closed). Chấp nhận. Lưu ý backstop chỉ báo "sạch" khi chạy; dán
  dòng log đó vào ghi chú đợt.
- **CHẶN (hướng dẫn, không phải code)**: bản mac ad-hoc, chưa notarize, tải qua trình duyệt có cờ quarantine.
  Trên macOS 15 (Sequoia) trở lên, "chuột phải > Mở" KHÔNG còn bỏ qua được cảnh báo; tester phải vào Cài đặt >
  Quyền riêng tư & Bảo mật > "Vẫn mở" (Open Anyway), hoặc chạy `xattr -dr com.apple.quarantine AxieDice.app`.
  Trang `/download` (downloads.js dòng 106) chỉ nói chuột phải > Mở, nên tester máy mới sẽ kẹt. Sửa câu đó và
  `production/qa/l1-install-guide.md` trước khi gửi link. Chip Apple Silicon chạy được nhờ chữ ký ad-hoc.
- Windows: SmartScreen "Thêm thông tin > Vẫn chạy" đúng. Nên nói tester kiểm sha256 trên trang với file tải về.
- Gói chưa ký số, tester ngoài vòng tin cậy nên cân nhắc xin Apple Developer ID trước khi mở rộng.

## Vòng 2 (a717091, ce0bf81, 0078248), 26/10
Verdict: **ĐẠT**. Worker test 310/310.
- CHẶN đóng: trang /download nay có Open Anyway cho macOS 15+, xattr cho máy cũ, và "More info > Run anyway" cho Windows.
- Đóng: tên ASCII-only (404 thay 500), nosniff mọi response, lỗi manifest chỉ vào log (503 chung), commit luôn so HEAD đầy đủ
  kể cả --allow-dirty, STAMP validate, --prev phải khớp bản trên R2 (cmp) và kiểm sha trước khi xoá, set -e, wrangler ghim,
  release_gate từ chối tham số lạ (exit 2) và mkdir build/, checklist lấy manifest từ R2 + kiểm /download sau rollback.
- Còn sót (nhỏ): mục 3 checklist vẫn ghi "chuột phải > Mở" cho bước cài thử; `l1-install-guide.md` chưa thấy sửa
  trong diff (nằm ở cây chính?). Range chưa hỗ trợ (đã nói là chấp nhận).
