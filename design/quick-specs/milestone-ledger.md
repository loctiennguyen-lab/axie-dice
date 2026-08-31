# Quick Design Spec — Milestone Ledger

> **Status**: Designed (pending review)
> **Extends**: Lunacia Pass (`design/gdd/game-concept.md` → Formulas #4, Detailed Rules → Tiến trình dài hạn)
> **Author**: game-designer (research + design pass, 2026-09-01), consolidated by Claude Code
> **Why**: 86% của mọi run kết thúc bằng thất bại (thiết kế roguelike có chủ đích — xem `docs/axiedice-source/design/AUDIT_AND_SPEC_v1.md` §D4, §B6). Lunacia Pass đã cho XP khi thua, nhưng con số trừu tượng không đủ — người chơi cần **tên cụ thể** cho tiến bộ để một lần thua vẫn cảm thấy tiến lên, không chỉ là reset. Tham khảo Hades (Mirror of Night gắn tiến bộ với mốc cụ thể, không chỉ số trừu tượng) và Slay the Spire (unlock theo hoàn thành, không chỉ theo thắng).

## Vấn đề

Lunacia Pass hiện tại (`game-concept.md` Formulas #4) tính XP từ công thức gộp (`30 + 10×wave + 30×Elite + 60×Boss + 150×thắng + 25×Ascension + 40×FullRun`) — người chơi chỉ thấy **một con số** ở cuối run, không có gì nói "đây là lần đầu bạn làm được X". Đúng dữ liệu (Mastery, Collection) đã tồn tại và tích luỹ kể cả khi thua, nhưng không được hiển thị/đặt tên tại đúng thời điểm cần nhất — màn thua.

## Detailed Rules

Một **danh sách mốc một-lần** (per-account, không reset theo run), mỗi mốc:
- Điều kiện kích hoạt (đạt được lần đầu trong bất kỳ run nào, kể cả thua)
- Thưởng: XP Pass bonus một lần (cộng thêm vào công thức XP hiện có, không thay thế)
- Tên hiển thị (toast ở màn kết thúc run)

**Nhóm mốc** (danh sách khởi điểm, có thể mở rộng):

| Mốc | Điều kiện | XP bonus | Tên hiển thị mẫu |
|---|---|---|---|
| Wave milestone | Lần đầu đạt wave 5/10/15/20 (bất kể thắng/thua) | 50 | "Lần đầu chạm tới Wave 15!" |
| Boss damaged | Lần đầu gây sát thương lên một boss cụ thể (kể cả không hạ được) | 40 | "Lần đầu đối mặt Plague Mother!" |
| Boss defeated | Lần đầu hạ một boss cụ thể | 100 | "Lần đầu hạ gục Plague Mother!" |
| Ascension attempted | Lần đầu bắt đầu run ở Ascension-N (N=1..10) | 30×N | "Lần đầu thử thách Ascension 3!" |
| Archetype first win | Lần đầu thắng run với một archetype cụ thể (trong 10 archetype ở game-concept.md) | 60 | "Chiến thắng PLAGUE đầu tiên!" |

## Formulas

```
milestone_xp_bonus = XP thường (công thức Pass hiện có) + Σ(milestone_bonus mới đạt được trong run này)
```
Mỗi mốc chỉ tính **một lần trong đời tài khoản** — dùng một set lưu trữ các milestone_id đã đạt (tương tự cách Collection lưu part đã mở khoá).

**Ví dụ**: người chơi lần đầu chơi, thua ở wave 6 sau khi gây sát thương (không hạ) boss wave 5 lần đầu, ở Ascension 0. XP = XP thường + 50 (wave milestone 5) + 40 (boss damaged lần đầu) = XP thường + 90.

## Edge Cases

- **Nhiều mốc cùng lúc trong 1 run**: cộng dồn tất cả, hiển thị toast dạng danh sách (không giới hạn số mốc/run).
- **Thua trước khi đạt mốc wave tiếp theo nhưng đã gây damage lên boss đó**: mốc "Boss damaged" vẫn tính dù chưa qua được wave đó trọn vẹn (bất kỳ lượt combat nào có gây sát thương lên boss là đủ).
- **Chơi lại cùng Ascension-N đã từng thử**: không tính lại — mốc chỉ kích hoạt lần đầu tiên tuyệt đối.
- **Tài khoản mới import từ save cũ (nếu có hệ thống save)**: cần quét lịch sử tiến trình đã có để backfill milestone đã đạt, tránh vừa cho XP trùng vừa vừa hiện toast sai cho tiến trình cũ.

## Dependencies

- **Lunacia Pass** (`game-concept.md`): milestone bonus cộng vào cùng công thức XP, không phải currency/track riêng.
- **Mastery/Collection**: đã có logic tương tự (tracking một-lần), tái dùng pattern lưu trữ.
- **Run-end screen (UI)**: cần thêm khu vực hiển thị toast — thuộc `docs/axiedice-source/uiux/` (không thiết kế UI chi tiết ở đây, chỉ yêu cầu chức năng).

## Tuning Knobs

| Knob | Giá trị khởi điểm | Ghi chú |
|---|---|---|
| Wave milestone XP | 50 | Có thể tune theo nhịp lên level Pass mong muốn |
| Boss damaged/defeated XP | 40 / 100 | Defeated cao hơn hẳn để phân biệt rõ 2 mốc |
| Ascension attempted XP | 30×N | Tuyến tính theo N, thưởng xứng đáng cho việc thử thách cao hơn |
| Archetype first win XP | 60 | Cố định cho cả 10 archetype — không thiên vị archetype nào |

## Acceptance Criteria

- **GIVEN** người chơi thua ở wave 6 lần đầu tiên trong đời tài khoản, **WHEN** run kết thúc, **THEN** màn kết thúc hiển thị toast "Lần đầu chạm tới Wave 5!" và XP Pass cộng thêm 50.
- **GIVEN** người chơi đã từng đạt milestone "Wave 10" ở một run trước, **WHEN** họ đạt wave 10 lần nữa ở run sau, **THEN** không có toast lặp lại và không cộng XP bonus lần 2.
- **GIVEN** người chơi hạ được một boss lần đầu, **WHEN** kiểm tra XP, **THEN** chỉ nhận bonus "Boss defeated" (100), không nhận thêm bonus "Boss damaged" riêng nếu boss đó cũng lần đầu bị damage trong cùng run (2 mốc merge thành 1 hiển thị cao nhất đạt được, tránh trùng lặp gây rối).

## Open Questions

- Có cần milestone cho "lần đầu unlock một Mastery tier" hay để nguyên trong hệ Mastery hiện có, không thêm vào ledger này? (Đề xuất: không thêm — Mastery đã tự hiển thị tiến độ riêng, tránh trùng lặp thông điệp.)
- Acceptance criterion thứ 3 (merge Boss damaged + defeated cùng run) cần xác nhận với UX — có thể gây khó hiểu nếu ẩn hoàn toàn mốc thấp hơn.
