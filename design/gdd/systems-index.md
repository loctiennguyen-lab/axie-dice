# Systems Index

> File này chưa tồn tại trước khi tạo lần này (2026-09-07, tạo bởi game-designer subagent khi viết `world-tour.md`, theo yêu cầu `design/CLAUDE.md`). Danh sách bên dưới liệt kê toàn bộ file trong `design/gdd/` tại thời điểm tạo — mô tả 1 dòng lấy từ tiêu đề/header thật của từng file, KHÔNG suy diễn nội dung chưa đọc kỹ. Cột Status chỉ điền khi có bằng chứng trực tiếp trong file (dòng `> **Status**:`); nếu không có, để "Không rõ — xem file".

| System | File | Mô tả ngắn | Status |
|---|---|---|---|
| Game Concept | `game-concept.md` | Tổng quan game, core loop, pillar "Minh bạch triệt để", formulas XP/budget/reroll | Approved (retroactively documented) |
| Build Spec | `build-spec.md` | Axie Dice Tactics — Build Spec v1.0 | Không rõ — xem file |
| Bloodline System | `bloodline-system.md` | Hệ part → mặt xúc xắc theo class (Bloodline) v1.2 | Không rõ — xem file |
| Axie Body Parts | `axie-body-parts.md` | Nguồn dữ liệu chính thức part Axie Infinity | Không rõ — xem file |
| Part Tier System | `part-tier-system.md` | Hệ quy đổi Axie → Axie Dice theo tier | Không rõ — xem file |
| Part Skill Identity | `part-skill-identity.md` | Signature Parts + Variant Families — thay thế phần "part → face" của `part-tier-system.md` | Thiết kế mới, chưa implement |
| Relic System | `relic-system.md` | Relic hook system (modFace/modDmg/onKill/...) | Draft for review (chưa duyệt) |
| Relic Roster Expansion | `relic-roster-expansion.md` | 50 relic mới (48 + 2 bắt buộc từ audit) | Không rõ — xem file |
| Combo Decision Memo | `combo-decision-memo.md` | Memo quyết định về hệ COMBO | Không rõ — xem file |
| Economy & Progression | `economy-progression.md` | Economy tổng thể, Lunacia Pass, Echo Box, NFT/Vault, faucet-sink, monetization — Design Spec v2.0 | Hỗn hợp — nhiều mục ✅ CHỐT, một số 🔬 CẦN SIM, một số đã bị amend (xem §10.2b, §10.3 amendments trong file) |
| Player Accounts | `player-accounts.md` | Player Accounts & Progression Sync | Không rõ — xem file |
| Leaderboard System | `leaderboard-system.md` | Bảng xếp hạng, anti-cheat qua deterministic replay | MVP implemented (2026-09-01) |
| **World Tour ("Lunacia Atlas")** | `world-tour.md` | Bản đồ tiến trình meta persistent, milestone deterministic dựa trên `META.runs`, phân biệt rõ với Lunacia Pass (XP) và Echo Box (gacha) | **Draft — chờ product owner xác nhận 3 câu hỏi mở cuối file** |
| **Onboarding Tutorial (Mandatory)** | `onboarding-tutorial.md` | Tutorial bắt buộc 6 bước (~90-120s) sau lần đăng ký/đăng nhập đầu tiên, dùng `newGame(seed,...)` dựng mock battle 5-Axie deterministic; xóa code `TUT[]`/`tutOverlay()` cũ đã chết | **Draft — chờ implement** |

## Ghi chú

- File này KHÔNG tự động cập nhật — mỗi khi thêm/sửa một GDD, người viết (agent hoặc con người) cần tự tay thêm/sửa dòng tương ứng ở đây.
- Cột Status của các file có sẵn (không phải `world-tour.md`) được điền dựa trên dòng `> **Status**:` đọc trực tiếp trong từng file tại thời điểm 2026-09-07; nếu file đó được sửa sau này mà status không cập nhật lại ở đây, coi bảng này là CŨ cho hàng đó — luôn ưu tiên đọc header thật của file gốc.
- Thứ tự bảng hiện tại là thứ tự liệt kê thư mục (không phải "design order" Foundation→Core→Feature→Presentation→Polish theo `design/CLAUDE.md`) — cần một lượt sắp xếp lại nếu dùng file này cho việc lập kế hoạch theo thứ tự phụ thuộc.
