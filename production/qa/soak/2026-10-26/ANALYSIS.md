# Soak 2026-10-26 — phân tích nhanh (lane I)

- 27.495 run (381 ô), bản production + hotfix BUG-0003. Kết thúc: WON 1.321, LOST 26.171, STUCK_TURNS 3, không crash (không thấy cột lỗi SCRIPT ERROR trong tổng hợp — kiểm lại khi có log).
- Verify (replay qua RunVerifier): ok 11.459; lệch 1.546 (rejected 1.431 + diff 115); skip_forced 14.490 (ô ép Anchor/Luật không có trong offer tự nhiên → không replay được, CHƯA phủ — cần sửa harness hoặc ép qua seed tự nhiên).
- Run Nhiệm vụ lệch ~85% mọi policy (fastM/expM) → đang điều tra (nghi verifier/harness không áp luật M hoặc Anchor trong Nhiệm vụ).
- Run thường lệch 14/11.205 (0,1–0,5%) → điều tra cùng.
- Không thấy Anchor/Luật nào lệch riêng (lệch rải đều, đi theo ô Nhiệm vụ).
