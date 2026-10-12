# Review Round 1 sửa (Claude Design, 12/10/2026)

Trạng thái: REVIEW R1 sửa — chờ Liam

Verdict: **ACCEPT WITH FIXES** (chỉ còn lỗi nhỏ trong README, không cần vẽ lại frame).

## A1–A14

| # | Kết quả | Ghi chú |
|---|---|---|
| A1 | Đạt | Bảng §3a đúng công thức, tính lại khớp: 38×2.25=85.5→86, 38×1.85=70, 20×2.05=41, 38×1.35=51. Plate, tab "incl. in 86", recap cùng số. |
| A2 | Đạt | Turn 7 = +10%, turn 8 = +15%, turn 10+ = +25% MAX. Không còn "+5%" sai chỗ (chỉ còn ở thẻ "starts turn 6 · +5%/turn"). |
| A3 | Đạt | Grep "Airborne" = 0. 02m dùng "Heal face: allies only". |
| A4 | Đạt | 03b ở A1, heal 40%, clock nhẹ, "Enrage in 14". Contact sheet 22 tile, tile 03b ghi A1 / 40%, 03a/c 25%. |
| A5 | Đạt | Continue 90/180, Moon Card 68/135, reroll 15, "Pay 15", "Gem 35 → 20", delay 60, swap 15. Hàng disabled có giá. Reroll 1/fight từ A3. Biến thể "of 4" có (02n). Không còn "of 2" trên A6. |
| A6 | Đạt | Câu fairness nguyên văn ở Aid tray footer (Combat dòng 235). |
| A7 | Đạt (theo README + contact sheet) | Panel 252 rộng, đáy cách tray 8 px, không đè Axie 1. Chưa đo pixel. |
| A8 | Gần đạt | Combat HTML: không còn font-size dưới 12 px. Disabled ink #6E4A30 dùng cho các chỗ cần đọc. Còn lỗi README bên dưới. |
| A9 | Đạt | Tab "big hit" giữ, chip WILL DIE nằm dưới. |
| A10 | Đạt | Reroll FX ghi là thuộc delivery, README §5. |
| A11 | Đạt | Ngày mùa ghi provisional. |
| A12 | Đạt | Undo bên phải, trên Reroll, phím Z, 3 trạng thái. |
| A13 | Đạt | Keymap + Tab order + focus ring (02o, 02h, 02i). Binding là [INF], đã ghi. |
| A14 | Đạt | Offer có cả cap theo item và cap theo run (02f, 02g). |

## Còn sai / mới phát hiện (nhỏ)

1. README §2 (Top bar) vẫn ghi "key hint 11" và locked shortcut "opacity .8", mâu thuẫn §1 (đã nâng 12 px, bỏ opacity .8). README nói nó thắng frame, nên phải sửa cho khớp. Trong HTML Hub không thấy 11 px, nên chỉ là README cũ.
2. Style Sheet HTML còn nhiều chữ 11 px (dòng 68–76, 193–203...). Có vẻ là nhãn swatch/spec, nhưng README §1 không liệt kê vào mục "decorative-only". Cần ghi rõ.
3. Chưa cần làm: kiểm pixel A7 trên 02h/02n bằng trình duyệt nếu Liam muốn chắc (mình chỉ đối chiếu số trong README và contact sheet).

## Note gửi Claude Design (tiếng Anh)

```
Round 1 corrected - thanks, A1-A14 all check out (numbers reconcile, prices, Undo, keyboard map, caps, fairness line, 03b at A1). Two small README fixes before we close Round 1:
1. README section 2 (top bar) still says shortcut key hint 11 px and locked shortcuts at opacity .8. Section 1 says 12 px and no opacity drop. Please make section 2 match.
2. The Style Sheet page still has 11 px text (swatch / spec captions). If it is spec-only, list it under "decorative only" in README section 1 text floor; otherwise raise to 12.
No frame changes needed. Send only the updated README (and Style Sheet if you raise the captions).
```
