# Session State

<!-- STATUS -->
Epic: UI/UX polish
Feature: Layout cửa sổ thấp + Formation Resonance
Task: Đã xong, đã merge vào main — chờ việc mới
<!-- /STATUS -->

> **Giữ file này DƯỚI 100 DÒNG.** Không phải thẩm mỹ — hai hook đọc hai đầu
> ngược nhau của chính file này:
>
> | Hook | Chạy khi | Đọc phần nào |
> |---|---|---|
> | `.claude/hooks/session-start.sh` | mở phiên mới | **`tail -20`** (20 dòng CUỐI) |
> | `.claude/hooks/pre-compact.sh` | **hết context / compact** | **`head -100`** (100 dòng ĐẦU) |
>
> File dài hơn 100 dòng thì khúc giữa **không hook nào đọc được**. Bản trước dài
> 165 dòng nên 20 dòng cuối mà phiên mới nhìn thấy là backlog của việc KHÁC —
> vô dụng cho việc đang làm. Chi tiết dài để ở `docs/`, đây chỉ để trỏ đường.

## Nguồn sự thật hiện tại

- **`docs/fixes-2026-09-03.md`** — đợt sửa mới nhất (layout cửa sổ thấp +
  Formation Resonance preview). Đọc file này là đủ, không cần kể lại bối cảnh.
- `docs/session-notes-2026-09-02-leaderboard.md` — ghi chú phiên Leaderboard
  (lưu trữ). Backlog trong đó VẪN CÒN, chưa làm mục nào.
- `CLAUDE.md` → `.claude/docs/technical-preferences.md` — kiến trúc, quy ước.

## Trạng thái 2026-09-03

`main` = `834a8e4`, đã chứa toàn bộ 5 commit của đợt sửa + 12 commit trước đó
mà `main` từng thiếu. **`main` giờ khớp production.**

Gate: `verify.mjs` **32/32** (3 lần liên tiếp, cả bản public) · `t_fit` 4/4 ·
`t_aoe` PASS · `t_import` 23/23 · `soak` 20 run 0 problem.

## Việc còn mở (không chặn)

- [ ] `t_fit.mjs` chỉ test trận thường → bug boss từng vô hình vì thế. Thêm case boss.
- [ ] `tools/soak.mjs` + `soakm.mjs` còn mục đường dẫn (`build/index.html` không
      bao giờ được tạo). Tạm thời truyền URL http để chạy.
- [ ] `soakm.mjs` 5 `NOPROGRESS` — có sẵn từ trước, chưa điều tra.
- [ ] Comment ghi `+25%` trong khi code là `RESONANCE.mult = 1.15` (+15%).
- [ ] Backlog Leaderboard — xem file lưu trữ ở trên.

## Quy trình build / verify / deploy

```bash
python3 build.py                                   # → AxieDiceTactics.html
python3 -m http.server 5199 --directory "$(pwd)"   # KHÔNG dùng 5173, xem bẫy #1
node tools/verify.mjs --url http://localhost:5199/AxieDiceTactics.html
node tools/t_fit.mjs
```

Deploy (Vercel tự chạy `build.py public`, upload file local — không cần push):

```bash
cd /Users/loc.tien.nguyen/my-game && vercel deploy --prod --yes
```

---

## ĐỌC NGAY — dành cho phiên mới

1. **Đọc `docs/fixes-2026-09-03.md`** trước khi làm gì. Đó là nguồn sự thật.
2. **Làm việc trên `main` ở checkout gốc** `/Users/loc.tien.nguyen/my-game`.
   `main` đã khớp production. Các worktree trong `.claude/worktrees/` là nhánh
   CŨ, phân kỳ, **không phải "cùng file"** — mỗi worktree là checkout riêng,
   khác branch, khác inode. Deploy sai worktree = ship sai code.
3. **Ba bẫy môi trường đã ngốn thời gian thật:**
   - Port **5173** bị session khác chiếm, serve build ở thư mục khác → test nhầm
     file người khác. Dùng port khác.
   - Server trỏ sai thư mục cho dấu hiệu y như bug CSS: `verify.mjs` báo `A4`
     thiếu toàn bộ token + `B0` "0 width query" + console 404. **Đó là 404, không
     phải bug CSS.**
   - `tools/t_*.mjs` từng hardcode đường dẫn Linux nên im lặng không chạy suốt
     thời gian dài. Nếu một check "luôn pass", kiểm xem nó có thực sự chạy không.
4. Cập nhật file này khi xong một mốc, và **giữ nó dưới 100 dòng**.
