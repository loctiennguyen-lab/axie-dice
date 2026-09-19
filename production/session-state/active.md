# Session State

> ## ⚠️ ĐANG Ở NHÁNH `godot-port`? ĐỌC FILE KHÁC.
> File này track nhánh **`main`** (bản JS đang live). Nếu `git branch` ra `godot-port`,
> file bạn cần là **`production/session-state/godot-port-active.md`** — mở nó và đọc mục
> "⇢ BẮT ĐẦU TỪ ĐÂY" ở đầu.
>
> (Hook mở phiên chỉ đọc file NÀY, nên con trỏ này là cách duy nhất phiên mới trên nhánh
> `godot-port` tìm được trạng thái của nó.)

<!-- STATUS -->
Epic: Battle UI redesign (design_handoff_battle_ui, Battle-UI-A-Grid-v2 handoff)
Feature: 3 gap còn lại so với README (bản sửa 2, 2 thiếu sót của chính README đã được sửa
  trong bản đó) đã implement xong trong src/client.html: (1) die block bỏ faceCaption()/.dcap,
  thêm .kwtags chip band; (2) Formation Resonance viết lại thành .resband+.resrail trong mỗi
  die block (bỏ .reslink circle+placeResLinks() đo DOM cũ) — bridge nối 2 rail qua gap bị BỎ
  (không làm theo literal spec) vì .unit{overflow:hidden} sẽ clip nó, xem comment tại .resband;
  (3) scUnitInfo() viết lại thành panel 560px riêng (§7), KHÔNG đụng faceRow() (còn 2 chỗ dùng
  khác trong scInfo()) — dùng inspFaceRow() mới.
  Bonus fix ngoài scope: --board-w sai ở cả 3 breakpoint hẹp (1199/899/599px — công thức cardW
  mới không khớp giá trị --board-w cũ, tràn ngang 300-700px) — đã tính lại đúng theo padding
  thật của #app tại từng ngưỡng, xem comment cạnh mỗi --board-w.
  Bug fix thêm (báo bởi user sau khi xong 3 gap): nút reroll (.rsel) trong die
  không bấm được — bindDrag()'s pointerdown trên cả .die (7395) bubble từ .rsel
  lên, needsTarget()=true thì gọi render() NGAY trên pointerdown (comment tại
  chỗ đó tự giải thích lý do), render() phá DOM node .rsel trước khi click kịp
  bắn. Fix: rs.onpointerdown=e=>e.stopPropagation() (partyCard(), cạnh rs.onclick
  đã có). Bug này KHÔNG do 3 fix trên gây ra — bindDrag()/.rsel có từ trước,
  verify bằng real mouse click qua Browser tool, u.rsel toggle đúng, sel không bị set nhầm.
Task: node tools/ci.mjs 12/12 GREEN (kể cả t_tutorial, đã hết fail). Sim winrate 19.0% không đổi.
  CHƯA commit — src/client.html/engine.js/t_tutorial.mjs đang unstaged, chờ user duyệt.
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

## Lịch sử phiên trước — chỉ là index, chi tiết xem git log

- 2026-09-07 (`5ac6a22`+deploy): PROGRESS xuống dòng, Echo Box tên bị cắt,
  locked-chip dimming, Relic Blood Pact 25%→15%, Leaderboard `upstash()` lỗi
  không check `.error`, icon pixel audit (BLOCKED sourcing thật).
- 2026-09-08 (implement xong, CHƯA commit lúc đó): World Tour v6
  (`design/gdd/world-tour.md`), World Map redesign (`design/ux/world-tour-map.md`,
  `scTourMap()`), Chimera monster art (`MON_ART` trong `art3.js`, 22 key).

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

---

# ⚠️ ĐANG Ở NHÁNH `godot-port`? FILE NÀY KHÔNG PHẢI THỨ BẠN CẦN.

Mọi thứ phía trên track nhánh **`main`** (bản JS đang live). Hook mở phiên chỉ hiện
20 dòng CUỐI của file này, nên khối này phải nằm ở đây — biển báo ở đầu file hook
không bao giờ hiện, và một phiên mới trên `godot-port` từng bị chỉ thẳng sang
`src/client.html` và nhánh `main`, tức sai cả file lẫn nhánh.

```bash
git branch --show-current     # ra `godot-port`? -> đọc file dưới, BỎ QUA phần trên
```

→ **`production/session-state/godot-port-active.md`**, mục "⇢ BẮT ĐẦU TỪ ĐÂY".
→ Kiểm kê việc còn thiếu (đo thật): **`docs/godot-port-gap-inventory.md`**.
→ Quyết định còn treo: `production/wayfinder/map.md`.
