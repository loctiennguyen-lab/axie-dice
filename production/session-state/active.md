# Session State

<!-- STATUS -->
Epic: Real-art overhaul + World Tour + Echo Box UX + QA rà soát pixel toàn diện
Feature: (xem lịch sử) + đổi 6 Boss art mới, bỏ filter đỏ ảnh thật, sửa layout Echo Box
Task: Tất cả DONE, verify browser + t_import/t_vault (43/0, 8/0) — chưa build.py public + deploy, chưa commit
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

## Trạng thái 2026-09-07 (TẤT CẢ đã verify browser + test 43/0, 8/0; CHƯA commit/deploy)

1. Hero/Boss/monster real art cơ bản: `HOUSE_ART`/`BOSS_ART`/`monArt2()`/`sprMon()`.
2. Echo Box economy: bỏ gate collection, `chestGradeFor()` xác định (không đổi tỉ lệ).
3. World Tour v4 đầy đủ (`design/gdd/world-tour.md`) — xem "Việc còn mở".
4. Game-wide bg art trên `#bgLayer` (sibling #app, tránh bug zoom).
5. Echo Box tách màn riêng (`design/ux/echo-box.md`), bỏ dòng Mythic khỏi Fuse.
6. **Hero rename** → tên Axie thật (Olek/Buba/Puffy/Machito/Pomodoro/Momo).
7. **Rà soát TOÀN DIỆN 2 vòng** (tay + agent QA) mọi nơi vẽ Hero/Boss/quái vật,
   sửa **6+ chỗ sót dùng pixel trực tiếp** (Choose Your Team, Vault×2, History,
   Leaderboard, Sample Teams, Reward "LEVEL UP" — tra sai cả tier cũ/mới).
   Helper mới: `heroArtWrap(cls,tier,artIdx,cls)` cho nơi chỉ có snapshot
   {cls,tier} phẳng (History/Leaderboard/Sample Teams), không có `.key`.
8. **Fix gốc rễ quan trọng nhất**: `.unit .spr.mut` có filter CSS
   (`grayscale+sepia+hue-rotate...`) nhuộm ĐỎ ĐỒNG LOẠT mọi quái/boss — kể cả
   ảnh THẬT, xoá sạch màu sắc riêng biệt (lý do art thật "trông như chưa đổi"
   dù nguồn ảnh đã đúng). Đã thêm `sprMonIsReal(k,phase)` + class `.real` ở
   MỌI nơi gọi `sprMon()` (5 chỗ) + CSS `.spr.mut.real{filter:none}` — pixel
   fallback thuần vẫn giữ filter cũ, chỉ ảnh thật mới bỏ.
9. **Thay mới cả 6 Boss** (product owner tự chọn từ Drive "Origins-WIP" +
   "Classic"): gooey_king←Acro Beast, mecha←Untitled80, frost_lord←Untitled82,
   plague_mother←Ginger, mirror←Untitled79, agony←Kotaro. `agony2` (phase 2)
   KHÔNG đổi. Cũng thêm `object-position:center` cho `.spr.mut` (tránh lệch
   khung như đã gặp với Hero — ảnh nguồn không đồng nhất tỉ lệ).
10. Profile: thêm preview thật cho Decor (ring/frame)/Background (màu) —
    trước đó chỉ hiện chữ suông; tự sửa thêm 1 lỗi CSS mình gây ra (đè mất
    màu background do thứ tự source).
11. Sửa layout card kết quả Echo Box (`.rcard.echoresult{min-height:0}`) —
    `.rcard` gốc có `min-height:180px` (thiết kế cho reward card có icon to),
    gây khoảng trắng thừa lớn cho card chỉ 2 dòng text.

## Việc còn mở (không chặn)

- [ ] Test tự động "3 item World Tour không lọt COSMETIC_POOLS" chưa vào `ci.mjs`.
- [ ] World-tour.md Câu hỏi mở #2/#3 chưa chốt (xem file đó).
- [ ] Chưa build.py public + deploy — TOÀN BỘ việc trong phiên 09-07 CHƯA lên prod.
- [ ] Echo Box locked-chip dimming màu là placeholder, art-director chưa chốt.
- [ ] `data.js:765` comment `+25%` sai, thực là `+15%`.

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
