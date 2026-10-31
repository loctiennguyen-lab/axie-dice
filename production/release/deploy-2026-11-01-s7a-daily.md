# Deploy 1/11/2026: S7a Leaderboard + Daily online + nút "Upgrade Land"

Liam duyệt 1/11 ("Deploy ngay").

- `godot-port` @ **247f283** (code = merge `1a04951`; sau đó chỉ commit docs). Push `axiedice` main: 4e93363..247f283.
- Nội dung:
  - S7a Leaderboard (`12eceba`);
  - Daily online lấy trạng thái từ server, server tự trả thưởng tuần ở lần nhận daily thứ 4 trong tuần, nút Claim online có cờ chờ;
  - nút LandPlate chỉ ghi "Upgrade Land", chi tiết chuyển vào tooltip (`1a04951`).
- RULES_VERSION không đổi (`godot-2026-10-26-v`). Không migration D1 (`migrations list --remote`: không có gì chờ).
- Gate: `tools/release_gate.sh --suite` (AXIE_RELEASE=1, không cờ skip) chạy ở worktree u5b-0 @ 247f283: **331/331**, Worker 397/397.
- Worker: **ed4c90bb-8c01-4c51-92c4-5202e4e5f3b6**. Bản trước: e3dda1c3 (ghi ở `build/web-prev/WORKER_VERSION.txt`).
- Web:
  - pck md5 **037b5087657722b5aff15662157e673e** (364942828 byte, 2 part). Bản trước: 318463f0, chép ở `build/web-prev/`.
  - html 21e32f3a, js e923d4fb, wasm 8b163661 khớp local.
  - Range 0-99 trả 206, đúng 100 byte.
- Desktop: không build lại. `/download` vẫn là b1841 (08cab37, trước UI-05). Worker mới tương thích bản cũ: block `daily` thêm vào là trường mới, client cũ bỏ qua.
- Smoke web trên pane trình duyệt, phiên của Liam đã đăng nhập sẵn, không đăng nhập lại:
  - Tap to start, vào Land. `/api/me`, `wallet`, `econ` ×2, `save`, `run/daily` đều 200.
  - `/api/econ` có `daily` = {day 2026-10-31, claimed true, week 2026-10-26, days 1, weekly_paid false}.
  - Màn Daily: nút "Claim · Claimed today" tắt, thẻ tuần "1 of 4 days", Day 1 claimed.
  - LandPlate ghi "Upgrade Land".
  - Chưa mở Leaderboard trên site.

## Rollback
- Web: chép `build/web-prev/index.*` về `web/`, chạy `deploy-r2.sh --pck-only` rồi `--rest`, kiểm md5 pck = 318463f0.
- Worker: `npx wrangler@4.151.3 rollback e3dda1c3-12fe-4dfd-9ef6-bbe1d77794cf`.
  - Bản cũ không gửi `daily`. Client mới khi đó giữ cache cũ: không hỏng, chỉ quay về lỗi hiển thị cũ.
  - Thưởng tuần đã trả vẫn nằm trong ledger, không trả lại lần hai, vì op key `claim:weekly:<tuần>` giữ nguyên.
- Git: `git revert -m 1 1a04951` và `git revert -m 1 12eceba` trên godot-port.
