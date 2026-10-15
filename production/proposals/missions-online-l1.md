# Nhiệm vụ N1–N3 chơi online ở L1: 3 cách làm (câu L1 trong `l1-plan-16-10.md`)

economy-designer · 16/10/2026 · chỉ đọc code, chưa sửa gì. Cần Liam chọn một cách trước khi ai code.

## Tình hình thật
- Worker production từ chối `kind=mission` (`not_available`, `runs.js` dòng 44). Cờ `ALLOW_GATED_MODES` chỉ bật ở staging. **Đừng bật nó trên production**: cờ này cũng tắt luôn cổng người mới của Ranked (`runs.js` dòng 50).
- Đã có sẵn: mission không bị tính vào trần 20 run/ngày, mission không mua được Aid (`run_core.js` dòng 303), bảng `wallet_ledger` có cột `currency` + khoá idem. Chưa có số dư Shard trên server.
- Cược N1–N3 = 300 / 500 / 800 Shard, trả 645 / 1.200 / 2.880 (`missions.json`). Stone thưởng vẫn nằm ở save của client trong mọi cách.
- Chưa có verifier: thắng/thua là lời khai của client (cùng mức tin như leaderboard). **Không cách nào dưới đây chống được việc sửa save để có Shard**, vì Shard chưa có số dư ở server. Chỉ "Shard lên server" (P0, sau L1) mới chữa được. Với ~50 người test nội bộ, Shard chưa đổi ra tiền thật, nên chấp nhận được.

## Ba cách

| | **B. Chỉ mở cổng** | **C. Mở cổng + server ghi sổ** | **A. Server giữ ký quỹ** |
|---|---|---|---|
| Ý chính | Worker bỏ `not_available` cho mission, gắn `mode=mission`. Cược/trả vẫn do client như hôm nay | B, thêm: client gửi `mission{tier, stake}` lúc tạo run; server kiểm với bảng riêng, ghi `wallet_ledger` (currency `shard`, `mission_stake:{run}` / `mission_payout:{run}`), kẹp payout theo bảng khi đóng run | Server nắm trạng thái cược: ghi cược cùng batch D1 với run, tự tính payout khi đóng, client chỉ cộng số server trả về. Cược chỉ trừ ở client sau khi server xác nhận |
| Công | ~1 ngày | ~2–2,5 ngày | ~5–6 ngày |
| Worker | tách cổng khỏi cờ staging (vài dòng) + sửa test `runs.test.mjs` | + kiểm bảng cược, ghi sổ lúc tạo/đóng/bỏ, `srv.mission` trong summary, lọc `/api/wallet` chỉ lấy `gem` (hiện không lọc, dòng Shard sẽ lẫn vào) | + migration 0007 (cột/bảng ký quỹ), tạo/đóng/bỏ/hoàn khi `infra_error`, `/api/run/open` trả lại ký quỹ |
| Client | gần như không đổi; kiểm lại đường remote + câu báo lỗi | gửi thêm `tier`, `stake` | đổi thứ tự: tạo run trước, trừ cược sau; payout lấy từ `closed`; đường resume từ máy khác |
| Deploy | Worker (không migration) | Worker + bản build mới (không migration) | Worker + **migration D1 production** + bản build mới |
| Gian lận L1 | sửa Shard, khai thắng. Server không thấy cược | như B, nhưng payout không thể vượt bảng, không trả hai lần, cược lệch bảng bị từ chối | như C, thêm nhất quán giữa hai máy. Vẫn sửa Shard được |
| Số B4 | mode có, tier/cược của run bỏ giữa chừng **không biết**, cược/payout là lời khai | có cược của mọi run kể cả bỏ, payout đã kẹp, cờ khi lời khai lệch bảng | chính xác nhất |
| Rủi ro lịch | thấp | thấp | cao: chạm đường tạo run (đường làm hỏng 3 bản build vừa rồi), ăn vào tuần live smoke mở rộng và B7 Windows, freeze 29/10 |

Cách (b) trong kế hoạch cũ (Nhiệm vụ chạy xúc xắc local) tôi loại: trái quyết định "server tung xúc xắc ở mọi chế độ", và bài test risk-to-earn không còn ý nghĩa nếu client chọn được seed.

## Đề xuất: C, làm B trước
B xong trong 1 ngày là Nhiệm vụ chơi được, live smoke N1 chạy luôn. Phần ghi sổ của C cộng thêm sau trên cùng chỗ đó. Lý do một dòng: A tốn thêm ~4 ngày để bảo vệ thứ chưa có (số dư Shard trên server), còn C cho Liam số liệu thật về cược/payout với chi phí nhỏ và không cần migration.

Cần Liam: chọn B, C hay A. Deploy Worker vẫn hỏi Liam trước.
