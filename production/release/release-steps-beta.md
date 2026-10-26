# Các bước phát hành beta (web + Worker + D1 + desktop)

Viết 26/10 (làn DL). Dựa trên `production/beta-plan.md` mục 5, `deploy-2026-10-23.md` (lỗi 300 MiB, pck cũ
còn trên R2) và `deploy-2026-10-26-r0.md` (không có trong nhánh này; xem chỗ chưa làm). Đây là checklist,
KHÔNG phải lệnh chạy sẵn. Mỗi đợt làn I (hoặc Liam) đi từ trên xuống, dừng ở lỗi đầu tiên.

## 0. Cổng trước mọi đợt có Nhiệm vụ (R1+)

- [ ] `bash tools/release_gate.sh --suite` xanh: `missions.json` không còn `_tmp` và suite Godot chạy
      với `AXIE_RELEASE=1` không cờ skip, Worker test xanh. Chạy khoảng 20 phút, `AXIE_HANG_KILL=1200`.
- Hiện trạng 26/10: gate ĐỎ, 8 dòng `_tmp` trong `godot/assets/data/economy/missions.json`. R1 bị chặn
  tới khi N-S ghép số thật. Đây là đúng thiết kế, không phải lỗi gate.
- [ ] Cây sạch: `git status` không có sửa đổi trong `godot/` và `worker/src/`, HEAD đã merge vào
      `godot-port` và đã được review độc lập (xem `production/agent-lane-rules.md`).

## 1. Worker và D1 (trước web nếu đợt có migration hoặc bump)

- [ ] `cd worker && node --test test/*.test.mjs` xanh (26/10: 307/307 sau khi thêm `download_route`).
- [ ] `npx wrangler d1 migrations list axie-dice-db --remote`. Đọc SQL của mọi file chờ. Chỉ `apply`
      khi SQL chỉ ADD (CREATE, ALTER ADD COLUMN). Không có DROP, DELETE, UPDATE hàng loạt.
- [ ] `npx wrangler d1 migrations apply axie-dice-db --remote`.
- [ ] Ghi version Worker đang chạy để rollback: `npx wrangler deployments list` (lưu id vào
      `build/web-prev/WORKER_VERSION.txt`).
- [ ] `cd worker && npx wrangler deploy`. Cảnh báo "multiple environments" là đã biết (không truyền `--env`).
- [ ] Lưu ý thứ tự: Worker có `SUPPORTED_RULE_VERSIONS` chứa bản luật mới TRƯỚC khi web lên. Client cũ
      vẫn gửi bản luật cũ nên không bị ảnh hưởng. Đợt có bump thì xem mục Rollback.

## 2. Web

- [ ] Giữ bản web đang chạy: `build/web-prev/` gồm `index.*`, `*.worklet.js`, và md5 của `index.pck`
      (hoặc `pck/` + `index.pck.parts.json` đang có trên R2). Phải lưu cả bộ, không chỉ html.
- [ ] Tắt Godot editor (Cmd+Q). `bash export-web.sh`.
- [ ] **Đề xuất sửa `export-web.sh`** (file gitignored ở cây chính, không sửa tại đây). Thêm ngay sau
      bước 1 và trước `--export-release`:

      ```bash
      bash "$ROOT/tools/release_gate.sh" || { echo "Dừng: cổng phát hành chưa đạt."; exit 1; }
      ```

      Gate này chỉ kiểm bảng số (nhanh). `--suite` chạy ở mục 0.
- [ ] Kiểm kích thước: `index.pck` khoảng 360 MB, `index.wasm` khoảng 37 MB. Nếu pck tăng > 5% so với
      đợt trước thì ghi lại và báo Liam (quy tắc beta-plan mục 7).
- [ ] `bash deploy-r2.sh --pck-only`: up `pck/index.pck.NNN` và manifest. Dừng nếu một part lỗi,
      không lên html/js/wasm.
- [ ] **Đề xuất sửa `deploy-r2.sh`** (gitignored): đầu script thêm cùng dòng gate như trên, và ghim
      `W=(npx --yes wrangler@4.151.3)` thay cho `@latest`. Lần 23/10 `@latest` resolve sang 4.151.3
      nhưng bản đó không được ghim ở đâu, nên lần sau có thể khác.
- [ ] `bash deploy-r2.sh --rest`: html, js, wasm, worklet, ảnh. Idempotent, chạy lại được.
- [ ] Kiểm byte, không chỉ HTTP 200:
      `curl -s -o /dev/null -w '%{size_download}\n' https://axiedice.fun/index.pck` = kích thước local,
      và `curl -s https://axiedice.fun/index.pck | md5` = `md5 -q web/index.pck`. Kiểm
      `Range: bytes=0-99` trả 206 và đúng 100 byte.
- [ ] html/js/wasm khớp md5 với `web/`.
- [ ] QA tài khoản Liam trên web (đăng nhập, vào run, save). Báo Liam 3-5 dòng.

## 3. Desktop

- [ ] `bash tools/build_desktop.sh all` (mac + Windows, ~140 s, dùng khoá with_lock). Log kiểm:
      `check_export_no_override: sạch` ở cả hai, `codesign verify: ok`, `PE check: x86_64 ok`.
      Không để `-dirty` trong tên gói (nếu có: build lại từ cây sạch).
- [ ] Build phải từ commit đang deploy. `publish_desktop.sh` từ chối gói build từ commit khác HEAD.
- [ ] Cài thử: mở `AxieDice.app` từ zip (ad-hoc, chuột phải > Mở), và `AxieDice.exe` trên Windows nếu
      có máy. Đăng nhập desktop, vào run, vào Nhiệm vụ.
- [ ] `bash tools/publish_desktop.sh <tên gói> --prev <latest.json cũ>` (chỉ tạo manifest và in lệnh,
      không upload). Lưu bản cũ `latest.json` vào `build/old/` trước khi chạy.
- [ ] Làn I chạy các lệnh đã in, đúng thứ tự: lưu bản cũ vào `downloads/old/` -> up hai zip mới ->
      up `latest.json` CUỐI -> xoá file cũ ở gốc `downloads/`.
- [ ] Kiểm sau khi up: `curl -sI https://axiedice.fun/download/<zip>` trả 200 và `Content-Length` đúng
      cỡ trong manifest; `https://axiedice.fun/download` hiện đúng version, sha256; tải một file và
      `shasum -a 256` khớp.
- [ ] Link cố định `https://axiedice.fun/download` không đổi. Client đã có `DOWNLOAD_URL` trỏ vào đó.
- [ ] Mở cửa sổ 7 ngày `-t` từ lúc có link mới (beta-plan mục 5), ghi ngày vào đợt.

## 4. Sau đợt

- [ ] Ghi `production/release/deploy-<ngày>.md`: lệnh đã chạy, kết quả từng bước, md5, version Worker,
      kích thước, lỗi và cách xử lý.
- [ ] Báo Liam 3-5 dòng. Không báo "xong" khi chưa có kiểm byte và kiểm `/download`.

## 5. Rollback

Nguyên tắc: không rollback D1 (chỉ ADD). Muốn lùi, lùi Worker, web, và link desktop cùng nhau.

- **Worker:** `cd worker && npx wrangler rollback <version id trong build/web-prev/WORKER_VERSION.txt>`.
- **Web:** dựng lại từ `build/web-prev/` (cả bộ, không để pck cũ đi cùng js mới). Chạy
  `deploy-r2.sh --pck-only` với pck cũ, rồi `--rest`, rồi kiểm md5 như mục 2.
- **Desktop, khi đợt có bump:** nếu rollback Worker, đổi `downloads/latest.json` về manifest cũ CÙNG LÚC.
  Lý do: client mới gửi luật mới, Worker cũ trả 409, và client cũ gặp 409 sẽ thấy màn "có bản mới" trỏ
  vào link đang chứa bản mới. Cách làm: `build/old/latest.json` là manifest cũ. Zip cũ nằm ở
  `downloads/old/`, copy về gốc `downloads/` rồi up `latest.json` cũ, sau khi rollback Worker xong.
- **Desktop, khi không bump:** rollback web và Worker không cần đổi link desktop.
- **Sửa tiến thay vì rollback:** đợt có bump thì ưu tiên hotfix (`hotfix/*` từ `main`), vì rollback
  Worker kéo theo cả link desktop.

## Chỗ chưa làm / cần Liam quyết

1. `production/release/deploy-2026-10-26-r0.md` không có trong nhánh `beta/dl`. Nó nằm ở `godot-port` (cây
   chính), nên mục 1-2 dựa trên `deploy-2026-10-23.md` và beta-plan mục 5.
2. `export-web.sh` và `deploy-r2.sh` nằm trong `.gitignore` ở cây chính. Đề xuất sửa được ghi ở trên, chưa áp.
3. `.dmg` không đăng lên R2. Chỉ có zip. Liam quyết nếu cần dmg cho tester.
4. Chưa có khoá link cố định ở Cloudflare (dùng đường dẫn `/download` trên Worker, không cần bucket public).
5. Chưa ghim phiên bản wrangler trong `deploy-r2.sh` và `publish_desktop.sh` (xem mục 2).
6. Gói build hiện có (`build/`, b1639, commit 5ecc08f) chưa đăng. Build lại từ HEAD trước khi đăng.
