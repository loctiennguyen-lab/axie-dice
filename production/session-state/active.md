# Session State

<!-- STATUS -->
Epic: Real-art overhaul + World Tour + Echo Box UX + QA rà soát pixel toàn diện
Feature: (xem lịch sử) + Blood Pact relic fix + leaderboard save bug fix + icon audit
Task: node tools/ci.mjs 11/11 GREEN. build.py public + git commit + vercel deploy --prod đang tiến hành.
<!-- /STATUS -->

> **Giữ file này DƯỚI 100 DÒNG.** `session-start.sh` đọc `tail -20`,
> `pre-compact.sh` đọc `head -100`. Chi tiết để ở `docs/`/`design/gdd/`.

## Cấu trúc nguồn

**Code client = sửa ĐÚNG 1 file: `src/client.html`**. `build.py` ghép
`art.js/art2(house)/art3(boss)/art4(chest)/art5(tour bg)/art6(MENU_BG)` +
`cosmetics.js/data.js/part_faces.js(SINH RA, đừng sửa)/engine.js` thành 1
file HTML. `build.py` chèn `<div id="bgLayer">` NGAY TRƯỚC `<div id="app">`
— đừng xoá (lý do: comment `#bgLayer` trong client.html, bug zoom+background).
`src/engine.js`/`src/data.js` không gộp vì `api/_engine.js` đọc từ đĩa chống
gian lận Leaderboard; `src/devtools.js` riêng vì `build.py public` strip nó.

## Trạng thái tổng — phiên 2026-09-05/07, SHIPPING (commit + deploy đang chạy)

Real-art overhaul (Hero/Boss/monster, `HOUSE_ART`/`BOSS_ART`/`sprMon()`), fix gốc
rễ filter CSS nhuộm đỏ ảnh thật (`sprMonIsReal()`+class `.real`), thay mới 6 Boss,
Echo Box tách màn riêng + economy rework, Hero rename, World Tour v4, Profile
preview Decor/Background. Chi tiết đầy đủ: `git log` (commit sắp tạo) +
`design/ux/echo-box.md` + `design/gdd/world-tour.md`. Không lặp lại ở đây nữa —
mục đích của mục này chỉ còn là index, không phải nhật ký.

## Phiên 2026-09-07 (tiếp) — 6 việc do product owner giao, tất cả verify xong

12. **Fix "PROGRESS" xuống dòng**: `.menu-grid--5` 96px→112px (tile "TOUR" sub
    "Lovely Forest II" wrap 2 dòng, lệch chiều cao 5 tile). Verify: cả 5 tile
    `offsetHeight` bằng nhau (72px), 1 dòng, ở 1199/899/1440px.
13. **Fix tên vật phẩm Echo Box bị cắt chữ**: `.echoshow` 72px→88px,
    `.echoshow-n` đổi `white-space:nowrap` (ellipsis 1 dòng) → 2-dòng
    `-webkit-line-clamp:2`. "Eclipse T_" giờ đọc đủ "Eclipse Tofu".
14. **Echo Box locked-chip dimming** — art-director chốt
    `grayscale(.65) brightness(.6);opacity:.55` (spec ở `design/ux/echo-box.md`
    Open Q#1, lý do đầy đủ ở đó), ĐÃ áp vào `src/client.html`.
15. **Relic Blood Pact** (`design/gdd/relic-rebalance-2026-09-07.md`, product
    owner đã duyệt): mất Max HP 25%→15% (`data.js` dòng ~634,
    `u.maxHp*0.75`→`*0.85`), giữ `dmgMult:1.6`. `t_relic.mjs` 94/94,
    `t_relic_behaviour.mjs` 38/38 — không cần sửa test (không hardcode RP).
16. **Fix bug Leaderboard không lưu điểm** — root cause: `api/submit-run.js`
    hàm `upstash()` không check field `.error` trong response Upstash REST
    (Upstash trả HTTP 200 + `{error:...}` khi ghi thất bại — code cũ coi MỌI
    response non-null là `stored:true`). Cũng đổi GET-path-encode → POST
    JSON-body (tránh giới hạn độ dài path với payload team+relic lớn) và bọc
    try/catch quanh `fetch`/`.json()` (trước đây network fail = uncaught
    exception). Verify: script thay thế `global.fetch` giả lập cả 3 case
    (success/Upstash-error/network-fail) qua 1 replay thật (13 action, seed
    12345) — case success `stored:true`, 2 case còn lại `stored:false` kèm lý
    do thay vì báo nhầm thành công như code cũ.
17. **Icon pixel audit** (`docs/art/icon-system-redesign-2026-09-07.md`,
    art-director) — kiểm kê đủ 25 icon `IC_G`, hướng thay thế, tận dụng lại
    folder Drive "Battle Status Icon" đã tìm thấy từ
    `design/quick-specs/real-art-adoption-plan-2026-09-07.md` (6/9 ST_IC đã
    có match). BLOCKED thực thi: chưa có ảnh loại-trừ + quyền Drive — product
    owner đã chọn "bỏ qua ảnh, rà soát toàn bộ" nên spec không loại trừ gì.

`node tools/ci.mjs` 11/11 GREEN sau tất cả thay đổi trên (chạy 2026-09-07).

## Việc còn mở (không chặn)

- [ ] Test tự động "3 item World Tour không lọt COSMETIC_POOLS" chưa vào `ci.mjs`.
- [ ] World-tour.md Câu hỏi mở #2/#3 chưa chốt (xem file đó).
- [ ] `data.js:765` comment `+25%` sai (KHÔNG liên quan Blood Pact — relic/dòng
      khác), thực là `+15%`.
- [ ] Icon pixel — spec xong, thực thi (sourcing asset thật từ Drive) BLOCKED,
      cần product owner cấp quyền Drive hoặc gửi ảnh loại trừ.
- [ ] icon-system-redesign §7: `ARCH_IC`/`EV_IC` tách art riêng khỏi
      `FT_IC`/`ST_IC`? — quyết định trước khi sourcing mở rộng ngoài 25 icon.

## Build / verify / deploy

```bash
npm install && npx playwright install chromium   # BẮT BUỘC
node tools/ci.mjs                                # 1 entry point, cả 11 gate
python3 build.py                                 # build dev (AxieDiceTactics.html)
```
Deploy: `vercel deploy --prod --yes` (Vercel tự chạy `build.py public`).

---

## ĐỌC NGAY — dành cho phiên mới

1. Code client sửa **`src/client.html`**; `src/part_faces.js` SINH TỰ ĐỘNG.
2. Làm trên `main` ở checkout gốc `/Users/loc.tien.nguyen/my-game` (không phải
   `.claude/worktrees/`, đó là nhánh CŨ).
3. Bẫy đã tốn thời gian: chưa `npm install` → verify/test playwright chết;
   port 5173 bị chiếm → `lsof -nP -iTCP:5173 -sTCP:LISTEN`;
   `cosmetics.js`/`art*.js` base64 SIÊU DÀI 1 dòng — đừng `Read` cả file,
   dùng `grep -n`/`sed -n`/`awk '{print length}'`;
   **browser cache**: sau khi `python3 build.py`, `navigate` lại CÙNG URL có
   thể phục vụ bản cache cũ — luôn thêm `?nocache=`+Date.now() khi cần chắc
   chắn thấy code mới.
4. Cập nhật file này khi xong mốc, giữ dưới 100 dòng.
