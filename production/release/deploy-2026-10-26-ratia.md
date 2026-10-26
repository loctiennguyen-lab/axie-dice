# R-Atia deploy (26/10/2026) — 6 quái Atia mới, RULES_VERSION -v

- godot-port = axiedice/main `93b15a7` (merge int/ra). RULES_VERSION `godot-2026-10-26-v`; Worker SUPPORTED giữ -t, -u, -v.
- Gate: suite `AXIE_RELEASE=1` 251/251, Worker 310/310. D1: không migration.
- Worker: `b0ed877a` -> **`baeeebf0`** (Worker lên TRƯỚC web). Bản R2 web ở `build/web-prev-r2/`.
- Web: pck md5 `af119fd26921122362df3171046a45b5` khớp local/remote; html/js/wasm khớp.
- Desktop b1696 (93b15a7): mac 277,942,148 B, win 254,371,011 B; check_export sạch, codesign ad-hoc ok, PE ok. Đăng bằng `tools/publish_desktop.sh` (đã sửa): b1678 lưu sang `downloads/old/` (sha OK cả hai) rồi mới xoá ở gốc; `/download` hiện b1696.
- QA tài khoản Liam (web): run -u dở bị báo "older version" (đúng); Start run hiện "Starting…" + "This can take a few seconds" (BUG-0002 đã sửa trên production); trận đầu gặp ngay 2 "Mire Slime" (slimes_04, quái mới), model 3D đúng.
