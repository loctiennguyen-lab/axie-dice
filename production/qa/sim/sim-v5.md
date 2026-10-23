# Sim v5 (int/v5, 23/10)
Short A0, lô 40, nhiều worktree song song. Raw CSV ở các worktree IVs/IVa*/IVb* (không commit, quá nhiều file).

## Chống spam (anti-spam-v5.md, Liam giao tự quyết theo sim)
| cấu hình (bản gộp) | expert tự chọn | random | spam |
|---|---|---|---|
| tắt | 25.0 | 14.0 | 13.8 |
| Vỏ 40% / lẻ 50% | 13.1 | 7.5 | 6.0 |
| **Vỏ 25% / lẻ 50% (chọn)** | **16.2** | **11.5** | **7.2** |
| Vỏ 40% / lẻ 70% | 12.5 | 6.5 | 8.2 |
A (Mana Quá Tải) không hạ spam, C (Chuỗi Xen) làm random/spam mạnh lên (đo trên godot-port trước gộp). Vỏ chỉ từ stage 2.

## Cân 6 Anchor (gộp theo Anchor thực sự cầm; sim ép Anchor giờ luôn đưa Anchor ép vào offer)
| vòng | knob | Kin | Volley | Gambler | Mana Mine | Big Hand | Embers |
|---|---|---|---|---|---|---|---|
| 0 | gốc | 24.2 | 17.6 | 10.7 | 21.1 | 17.2 | 10.9 |
| 1 | Kin .30, Gambler .45/Nứt 10, Embers .75 | 19.8 | 17.9 | 13.3 | 13.5 | 14.5 | 4.8 |
| 2 | + bot Embers không Giữ viên trong BỘ | 19.2 | 17.1 | 13.8 | 11.6 | 13.1 | 6.1 |
| 3 | Embers 1.50, Mana Mine +2 mana, Big Hand .60, Gambler .55 | 19.2 | 17.1 | 13.1 | 12.4 | 12.0 | 7.3 |
CI ±4-5 (n 246-287 mỗi Anchor ở vòng 2-3). Vòng 3: expert tự chọn 20.6, expert stage 2 ~21, random 12.5, spam 7.0, thức tỉnh 36-54% mỗi Anchor, đột biến 38-59%.
Chưa đạt: chênh giữa Anchor ~12 điểm. Buff mạnh gần như không đổi số Embers/Big Hand/Mana Mine → nghi bot chưa chơi được các Anchor này (Giữ viên đúng lúc, xây BỘ bốn). Liam chốt (23/10): deploy cả 6, anh chơi rồi chỉnh.
