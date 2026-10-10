# HANDOVER — Thiết kế lại Part→Skill (Vault Axie) + Relic
> Cập nhật: 2026-09-03 · Worktree: `.claude/worktrees/agitated-cartwright-ae338d` · Base: `60c05ee`
> **File là bộ nhớ, không phải hội thoại.** Mọi quyết định đã nằm trong doc, không cần đọc lại chat.

## TRẠNG THÁI: Part-skill XONG (máy kiểm chứng) · Relic ĐANG CHẠY · Code game CHƯA BẮT ĐẦU

## 1. Đã hoàn tất + đã verify bằng máy
`design/gdd/part-skill-identity.md` (~3400 dòng)
- **19 → 285/285 face engine-distinct**, giống nhau ở CẢ HAI profile `B[C]=2.80` và `6.00`
  → chứng minh tính phân biệt KHÔNG phụ thuộc `B[C]`, tinh chỉnh ngân sách không thể làm sập face
- `tools/gen_faces.mjs` — generator + 25 invariant fail cứng. `--check --strict` = **GREEN**
- `tools/t_partskill.mjs` — **44/44**
- `assets/data/part_faces.json` (+ `.ref.json`, `_tuning.json`) = output đã commit

## 2. Đang chạy (2 agent nền)
| Agent | File | Việc |
|---|---|---|
`systems-designer` | `design/gdd/relic-roster-expansion.md` | Áp 37 retune bắt buộc (§6.7 của relic-system.md) + 2 entry mới → 94 relic |
`tools-programmer` | `tools/t_relic.mjs` | Dựng bộ kiểm INV-1 cho toàn 94 relic |

`design/gdd/relic-system.md` (~2100 dòng) đã XONG: INV-1, `mload`, `ex` token, ARCH→11, `faceArch()`, retune 44 relic gốc.

## 3. CHƯA LÀM — code game
Đọc §9/§10 của hai doc để lấy danh sách đầy đủ. Tóm tắt:
- `axieToDie` v2 (§3.6) · sort `SLOT_ORDER` trước `slice(0,6)` · vault migration `schema:2`
- `relicConflict()` cho `mload`/`ex` · 5 `act.kind` mới · `THORNS_CAP=8` · `onDmgTaken`
- Sửa `genRewards` (`engine.js:694`) để imported Axie nhận được ASCENSION
- **3 bug có sẵn đã được duyệt sửa** (relic-system.md §14.1): giá shop `rar:4` rơi về 60 (rẻ hơn RARE 75) · `a_ult` gắn tag crit nhưng không crit được · `modFace` chạy theo thứ tự nhặt relic
- Bump `ENGINE_VERSION` một lần cho cả gói

## 4. Quyết định product owner — ĐÃ CHỐT, KHÔNG mở lại
Ghi đầy đủ ở `relic-system.md` §14 và `part-skill-identity.md` §F1b-α.
- **Chấp nhận pay-to-win.** Bất đẳng thức "chơi > tiền" ĐÃ THU HỒI. Đừng "khôi phục như một regression".
  → Anti-cheat KHÔNG bị ảnh hưởng: replay chặn điểm *bịa*, không chặn *chi tiền*. `AC-1` vẫn BLOCKING.
- Trần `SPREAD_OWN < 2.4×`, `SG_STEP = 0.071` (thang gene 8 bậc, có hoà ở tier 4)
- `data.js` ĐƯỢC gọi hàm `engine.js` · `onDmgTaken` SẼ implement · sửa cả 3 bug có sẵn
- Ranked: mở cho vault Axie trong tương lai (§3.9, lộ trình 5 giai đoạn, gate là *provenance* không phải cân bằng hoá)

## 5. Baseline test — ĐO THẬT, không phải chép từ doc
| Suite | Kết quả | Ghi chú |
|---|---|---|
`verify.mjs` | **32/32** | Doc từng ghi 29/30 và 28/30 — **cả hai đều sai** |
`t_partskill.mjs` | 44/44 | |
`t_import.mjs` | 23/23 | |
`t_aoe.mjs` | ALL PASS | Từng chết, đã sửa |
`t_fit.mjs` | 3/4 | Bug 1280×720 có sẵn, đã khai trong `known-failures.json` |
`sim.js` | 20.0% | Mốc so sánh cho mọi thay đổi balance |
`gen_faces --check --strict` | GREEN | |

**Điều kiện tiên quyết dễ nhầm** (cả hai từng đánh lừa):
1. `npm install` — worktree không có `node_modules`, thiếu nó thì 3 suite trông như hỏng
2. `verify.mjs` cần build ĐÃ SERVE: `python3 build.py` → serve gốc repo cổng 5173 →
   `node tools/verify.mjs --url http://localhost:5173/AxieDiceTactics.html`
   Chạy trần sẽ `ERR_CONNECTION_REFUSED` — đọc như lỗi code nhưng không phải.

## 6. Bài học đã thành luật trong doc (đừng lặp lại)
- **Đếm tay tập con thì sai** — 3/3 lần sai (201 face, bộ cấm `mouth`, nhóm `SIG_LIFT`). Để máy đếm.
- **Checksum tự triệt tiêu** không phát hiện được gì (§3.5b: +4−1−3=0). Dùng 2 danh tính độc lập.
- **Ràng buộc SỐ LƯỢNG không bắt được lỗi SỐ PHẦN TỬ PHÂN BIỆT** — về cấu trúc là không thể.
- **Xoá THÂN mục đã khai tử, không chỉ gạch tiêu đề** — lập trình viên build theo thân mục.
- **Bất biến bảo vệ lập luận thiết kế phải thu hồi CÙNG LÚC với lập luận** (`I14` từng làm build đỏ vĩnh viễn).
- **Hai bảng cùng định nghĩa một thứ sẽ trôi** — đúng lỗi `part-tier-system.md` + `parts_build_data.json`.
- `known-failures.json` có ngữ nghĩa HAI CHIỀU: id liệt kê mà *pass* thì build fail vì entry cũ.
