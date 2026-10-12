# Quyết định đang chờ Liam (cập nhật 12/10/2026)

Liam đã trả lời 23 câu ngày 12/10. Câu đã chốt đã ghi vào đầu file nguồn:
`design/handoffs/cosmetics-01/REVIEW.md` (A1–A5), `design/proposals/monetization-v1.md` (B2–B5, B8),
`docs/architecture/server-authoritative-rng.md` (C1–C10). B1, B6 (bỏ R10), C8, D đã chốt 12/10 (lần 2). B7 chốt 12/10: giữ Gem, tặng 120 Gem/mùa, Pass premium từ mùa 2. Kiến trúc CHỐT 12/10 (ghi ở đầu `docs/architecture/server-authoritative-rng.md`). Không còn câu nào chờ. Đang làm: Liam draft ý tưởng UI → hỏi chi tiết → viết prompt Claude Design.

| # | Câu hỏi | Trạng thái |
|---|---|---|

## Việc sau khi Liam trả lời
1. `technical-director` sửa `server-authoritative-rng.md` theo 2 review + quyết định C → review lại (lead-programmer hoặc security-engineer). **XONG 12/10** (3 vòng review security-engineer).
2. `game-designer` sửa `monetization-v1.md` (đồng bộ §0–§3 với §9, MON-13, B1–B7) → `economy-designer` chỉnh số →
   review lại (creative-director). **Đã đủ quyết định, làm được.**
3. Gửi Claude Design ghi chú sửa Cosmetics (bản tiếng Anh trong `REVIEW.md`, sửa theo A1–A5) + contact sheet biome. **Làm được ngay.**
4. A4 đã duyệt: thêm Mythic vào `DangoTheme.RARITY_COLORS`/`RARITY_NAMES` (+ test). **Làm được ngay.**
5. Sau đó: viết lại kế hoạch phase cho cả dự án, rồi bắt đầu triển khai.

## Monetization + Ascension (creative-director APPROVE WITH CHANGES 12/10, chờ Liam)
Chi tiết khuyến nghị: báo cáo creative-director gửi Liam 12/10; nguồn `design/proposals/monetization-v1.md` §8.3,
`design/proposals/ascension-v2.md` §6 câu 11–14. Sau khi Liam chốt: game-designer sửa → economy-designer tính lại
MON-11 có Boon → sửa `echobox-pass-v2.md` INV-V10 + `core-loop-v2.md` Ranked profile theo B3 → sim F/G.

## UI request 02 (art-director review xong 12/10, chờ Liam 5 câu): `design/requests/ui-redesign-request-02.md` "Ghi chú cho Liam".
