# Session State

<!-- STATUS -->
Epic: Non-battle UI redesign (design_handoff_non_battle_ui, 12 screens, structure-only per its README)
Feature: Đã audit cả 12 màn — 9/12 đã khớp sẵn với mockup (Battle UI, Profile, Battle Pass,
  World Tour, Team Pick, Map, Main Menu, Gate/Login, Tutorial Overlay — KHÔNG cần sửa).
  3 màn thực sự cần merge thành tab-group đã làm xong: Codex+Sample Teams (scCodex, colOuter
  pattern), Collection+Unlocks+EchoBox (scCollection/colOuter, scEchoBoxBody), Vault+Leaderboard+
  History (scVaultHub/vaultOuter, scImportBody/scLeaderboardBody/scHistoryBody).
Task: node tools/ci.mjs 11/12 GREEN (t_tutorial fail = pre-existing trên main sạch, đã confirm
  bằng git stash, KHÔNG phải regression). CHƯA commit — src/client.html đang unstaged, chờ user duyệt.
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

## Phiên 2026-09-07 (tiếp, ĐÃ COMMIT `5ac6a22`+deploy) — tóm tắt, chi tiết xem git log

Fix PROGRESS xuống dòng + Echo Box tên bị cắt chữ + locked-chip dimming
(art-director) + Relic Blood Pact 25%→15% + bug Leaderboard không lưu điểm
(`upstash()` thiếu check `.error`) + icon pixel audit (`docs/art/icon-system-
redesign-2026-09-07.md`, BLOCKED sourcing thật).

## Phiên 2026-09-08 — World Tour v6 + World Map redesign + Chimera art (IMPLEMENT xong)

18. **World Tour v6** (`design/gdd/world-tour.md`) — badge Map1 dùng `fullAscMax`
    (câu hỏi mở #3), chuỗi mở Map2 đổi sang 3 TRỤC (`wins>=5`/`ascMax>=2`/
    `fullAscMax>=3`, câu hỏi mở #2, game-designer thiết kế lại sau khi bản
    4-bước-1-trục cũ bị từ chối vì có thể "nhảy cóc" bỏ qua cả chuỗi).
    `tourQuestStep()`/`tourLockReason()` (`client.html`) đã sửa khớp — verify
    bằng test vector trong browser console, đúng cả 4 mốc biên trong spec.
19. **World Map redesign** (`design/ux/world-tour-map.md`) — `scTourMap()` viết
    lại hoàn toàn: art thật full-bleed (CSS breakout `100vw`, KHÔNG cần
    `#bgLayer`), 10 node tròn bám đúng đường mòn (`TOUR_MAPS[].tiles[].node`,
    `data.js`), path SVG nét đứt, pawn "vị trí hiện tại" nội suy, boss-landmark
    dùng thẳng `sprMon()`. Cũng nâng cấp `TOUR_MAP_ART` (`art5.js`) lên bản nét
    hơn (1770×578, JPEG q88, ~415KB/ảnh — không dùng bản gốc PNG 2MB/ảnh vì quá
    nặng cho lợi ích thấy được). Verify: chụp màn hình ở 899/1440px VÀ với
    `--ui-scale:1.2` (giả lập zoom) — không seam, không crop.
20. **Chimera monster art** (`docs/art/chimera-monster-art-mapping-2026-09-08.md`)
    — `MON_ART` mới trong `art3.js` (22 key), wire vào `sprMon()`/`sprMonIsReal()`
    (ưu tiên BOSS_ART → MON_ART → monArt2() Hero-reskin cũ), KHÔNG qua
    `realArtWrap()`/badge NFT (quái không phải Vault Axie sở hữu). Verify bằng
    browser: quái thường giờ có art riêng biệt hẳn với Hero, không đỏ.

`node tools/ci.mjs` 11/11 GREEN sau tất cả (chạy 2026-09-08). CHƯA commit/deploy.

## Việc còn mở (không chặn)

- [ ] Test tự động "3 item World Tour không lọt COSMETIC_POOLS" chưa vào `ci.mjs`.
- [ ] Icon pixel — spec xong, sourcing asset thật BLOCKED, cần quyền Drive.
- [ ] World Tour `W=5` (ngưỡng `wins` bước 2) là số trực giác chưa qua đo đạc
      — cần sim/playtest thật để tinh chỉnh (xem world-tour.md §Tuning Knobs).
- [ ] Node coordinates World Map là ước lượng ban đầu (đã verify bằng mắt qua
      browser, ổn), có thể tinh chỉnh thêm nếu art-director muốn soi kỹ hơn.

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
