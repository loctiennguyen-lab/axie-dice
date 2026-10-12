# Quyết định đang chờ Liam (cập nhật 12/10/2026)

Liam đã trả lời 23 câu ngày 12/10. Câu đã chốt đã ghi vào đầu file nguồn:
`design/handoffs/cosmetics-01/REVIEW.md` (A1–A5), `design/proposals/monetization-v1.md` (B2–B5, B8),
`docs/architecture/server-authoritative-rng.md` (C1–C10). B1, B6 (bỏ R10), C8, D đã chốt 12/10 (lần 2). Còn mở:

| # | Câu hỏi | Trạng thái |
|---|---|---|
| B7 | Pass premium chờ mùa 2 (đã chốt). Liam hỏi Gem là gì, sao có Gem | Đã giải thích, chờ Liam: giữ Gem hay bán thẳng USD; có tặng 120 Gem/mùa không |

## Việc sau khi Liam trả lời
1. `technical-director` sửa `server-authoritative-rng.md` theo 2 review + quyết định C → review lại (lead-programmer hoặc security-engineer). **C đã chốt đủ, làm được ngay.**
2. `game-designer` sửa `monetization-v1.md` (đồng bộ §0–§3 với §9, MON-13, B1–B7) → `economy-designer` chỉnh số →
   review lại (creative-director). Chờ B1, B6, B7.
3. Gửi Claude Design ghi chú sửa Cosmetics (bản tiếng Anh trong `REVIEW.md`, sửa theo A1–A5) + contact sheet biome. **Làm được ngay.**
4. A4 đã duyệt: thêm Mythic vào `DangoTheme.RARITY_COLORS`/`RARITY_NAMES` (+ test). **Làm được ngay.**
5. Sau đó: viết lại kế hoạch phase cho cả dự án, rồi bắt đầu triển khai.
