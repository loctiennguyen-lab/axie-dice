# Session State

<!-- STATUS -->
Epic: Skill/Part + Relic
Feature: per-part Axie skills (285 face) + relic rebuild (94)
Task: Đã merge main, đã deploy, đã verify prod khớp main từng byte — chờ việc mới
<!-- /STATUS -->

> **Giữ file này DƯỚI 100 DÒNG.** Hai hook đọc hai đầu ngược nhau của chính nó:
> `session-start.sh` đọc **`tail -20`** (20 dòng CUỐI) khi mở phiên; `pre-compact.sh`
> đọc **`head -100`** khi hết context. Dài hơn 100 dòng thì khúc giữa **không hook
> nào đọc được**. Chi tiết để ở `docs/` và `design/gdd/`, đây chỉ trỏ đường.

## Cấu trúc nguồn

**Code client = sửa ĐÚNG 1 file: `src/client.html`** (CSS + audio/icons/log/ui/fx,
có mốc `/* ─── name.js ─── */`). `build.py` ghép thành 1 file HTML.

Luật chơi/cân bằng ở **`src/engine.js` + `src/data.js`** — không gộp được vì
`api/_engine.js` đọc chúng từ đĩa để chống gian lận Leaderboard. `src/devtools.js`
riêng vì `build.py public` phải strip được nó.

**`src/part_faces.js` là FILE SINH RA — KHÔNG sửa tay.** Nguồn cùng một lần chạy:
`assets/data/part_faces.json`. Muốn đổi bảng face thì sửa `tools/gen_faces.mjs`:

```bash
node tools/gen_faces.mjs                    # ghi lại cả .json và .js
node tools/gen_faces.mjs --check --strict    # verify, không ghi
```

## Nguồn sự thật

- **`design/gdd/part-skill-identity.md`** (3487 dòng) — hệ part→skill, 285 face.
- **`relic-system.md`** (2462) + **`relic-roster-expansion.md`** (1977) — relic 94.
- `docs/fixes-2026-09-03.md` — đợt layout + Formation Resonance (đợt trước).
- `docs/session-notes-2026-09-02-leaderboard.md` — backlog Leaderboard, VẪN CÒN.

## Trạng thái 2026-09-04

`main` = `de6c987`. **Đã verify production khớp main từng byte**: md5
`948ba31a53e0409d1c97c0daca526e5a`, 2.404.807 B, giống nhau giữa local
`build.py public` và `https://axiedice.vercel.app/`. Runtime trên prod: 94 relic
(78 passive + 16 active), 285 face (81 sig + 204 variant), `ARCH` có `exec`,
`devGo` undefined (devtools strip đúng), 3 Axie cùng class ra 3 dice khác nhau.

Gate: **`node tools/ci.mjs` = 11/11**, verify từ checkout SẠCH (đã xoá
`AxieDiceTactics.html` rồi chạy lại). `--fast` = 7/7. `verify` 37/37 · `t_partskill` 44/0 · `t_import` 43/0 · `t_vault`
8/0 · `t_relic` 94/94 INV-1 · `t_relic_behaviour` 38 proof · `gen_faces
--check --strict` GREEN cả 2 profile.

## Việc còn mở (không chặn)

- [ ] `data.js:765` comment ghi `+25%` trong khi `:766` là `mult: 1.15` (+15%).
- [ ] `soak.mjs:11`/`soakm.mjs:10` trỏ `build/index.html`. File đó do
      `buildCommand` trong `vercel.json` tạo, `build.py` KHÔNG tạo — nên chạy
      local phải truyền URL http.
- [ ] `soakm.mjs` 5 `NOPROGRESS` — có từ trước, chưa điều tra.
- [ ] `t_fit.mjs:15` lấy node đầu tiên trong `[battle,elite,boss]` nên gần như
      luôn là battle thường; bug boss từng vô hình vì thế. Thêm case boss thật.
- [ ] Backlog Leaderboard — xem file lưu trữ ở trên.

## Build / verify / deploy

```bash
npm install && npx playwright install chromium   # BẮT BUỘC, xem bẫy #1
node tools/ci.mjs                                # 1 entry point, cả 11 gate
node tools/ci.mjs --fast                         # chỉ suite logic, không browser
```

Deploy: Vercel tự chạy `build.py public` qua `buildCommand` trong `vercel.json`.

```bash
cd /Users/loc.tien.nguyen/my-game && vercel deploy --prod --yes
```

---

## ĐỌC NGAY — dành cho phiên mới

1. Code client sửa **`src/client.html`**; luật ở `engine.js`/`data.js`;
   **`src/part_faces.js` sinh tự động, đừng sửa tay.**
2. **Làm trên `main` ở checkout gốc** `/Users/loc.tien.nguyen/my-game`.
   Worktree trong `.claude/worktrees/` là nhánh CŨ, phân kỳ — mỗi cái là
   checkout riêng, khác branch, khác inode. Deploy sai worktree = ship sai code.
3. **Bốn bẫy đã ngốn thời gian thật:**
   - Chưa `npm install` → `verify`/`t_aoe`/`t_fit`/`t_vault` chết ở
     `import { chromium } from 'playwright'`: trông như 4 suite hỏng, thực ra
     thiếu 1 dependency.
   - Port **5173** (ci.mjs hardcode) bị session khác chiếm → test nhầm file
     người khác. Kiểm `lsof -nP -iTCP:5173 -sTCP:LISTEN` trước.
   - Server trỏ sai thư mục cho dấu hiệu y như bug CSS: `verify.mjs` báo `A4`
     thiếu token + `B0` "0 width query". **Đó là 404, không phải bug CSS.**
   - Một check "luôn pass" có thể là đang không chạy, hoặc chạy trên file CŨ.
     Suite dùng playwright PHẢI nằm dưới bước build trong `ci.mjs` — `t_vault`
     từng nằm trên và pass bằng build cũ. Đừng chuyển suite browser lên trên.
4. Cập nhật file này khi xong một mốc, và **giữ nó dưới 100 dòng**.
