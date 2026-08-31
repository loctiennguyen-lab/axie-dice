# UI Redesign — Combat Screen (2026-09-01)

> **Trigger**: product owner phản ứng trực tiếp với screenshot UI đang chạy: "UI vẫn rất xấu vậy nên hãy nhờ UI Design cải thiện lại hoàn toàn."
> **Nguồn thiết kế**: art-director (chẩn đoán thẩm mỹ + token) + ux-designer (phân cấp/layout), chạy song song, tổng hợp và implement trực tiếp vào `src/style.css`/`src/ui.js` cùng phiên.

## Chẩn đoán gốc (art-director)

UI "xấu" không phải vì thiếu màu — mà vì **thiếu độ sâu**: mọi `box-shadow` trong hệ thống cũ chỉ gắn với state (hover/select/mythic), không có shadow nghỉ (resting state) cho bất kỳ card nào → mọi thẻ trông như vệt xám nhạt hơn nền, không phải vật thể nổi trên bàn. Đồng thời mọi loại card (enemy/unit/die) dùng chung một công thức hình khối, chỉ khác 3px viền accent → không phân biệt được "cái gì quan trọng hơn cái gì".

## Đã implement

**Độ sâu (art-director)**:
- Token mới: `--sh-card` (unit/enemy card), `--sh-hero` (die — đậm hơn, vì dice là "hero object"), `--pan-hi` (bậc bề mặt mới giữa `--pan2`/`--pan3`)
- Chia 2 "mặt phẳng": **Table** (unit/enemy/dice — có shadow) vs **Deck** (nút bấm/panel — giữ phẳng có chủ đích, không đổi)
- Sprite có bóng đổ chân (`::after` ellipse gradient) — gắn sprite vào bàn thay vì lơ lửng trong khung
- Radial gradient nhẹ dưới mỗi zone (enemies/party) — cảm giác "vùng sáng trên bàn", chỉ đổi lightness không thêm hue (không phá nguyên tắc nền trung tính)

**Phân cấp/layout (ux-designer)**:
- **Intent địch chuyển lên ĐẦU card** (không còn là chip phụ đóng khung riêng dưới card) — đúng pillar minh bạch, đây là thông tin quan trọng nhất mỗi lượt. Implement bằng `order:-1` trên `.intent` + `.unit{display:flex;flex-direction:column}` — thuần CSS, không cần sửa DOM order trong JS
- **Mỗi Axie ghép chung 1 cột với đúng die của nó** — trước đây `zone.party` và `tray` là 2 hàng riêng, chỉ thẳng cột nhờ trùng width tình cờ (dễ vỡ khi có token unit width khác). Giờ dùng `.pcol` wrapper thật trong `scCombat()`
- **Badge archetype to gấp rưỡi** (16px→24px), nằm hẳn trên bề mặt card thay vì đè viền
- **END TURN to hơn hẳn REROLL** (`--ctl-lg` thay vì `--ctl-md`) — đúng Fitts's Law cho hành động hệ trọng nhất mỗi lượt

## Đã verify

- `node tools/sim.js` — winrate không đổi (8.0-8.6% Full Run, trong dải nhiễu bình thường) — xác nhận đây thuần là thay đổi UI, không đụng gameplay
- Browser thật: chơi 1 trận, target/attack/reroll hoạt động đúng, không lỗi console
- Cả 3 breakpoint (1199/899/599px desktop/tablet/mobile-landscape) — layout co giãn đúng, không vỡ
- Mobile portrait vẫn đúng rotate-hint gate (rule 8, không đổi)

## Chưa làm (out of scope phiên này, đã flag trong 2 báo cáo agent gốc)

- **Icon body-part thật** (`docs/art/icon-spec-body-parts.md`) — cả 2 agent đều nói đây là đòn bẩy rẻ nhất còn lại ("die face đọc như stat block, không phải bộ phận quái vật lắp ráp"), nhưng cần tác giả pixel-art thật cho format `IC_G`, chưa làm trong phiên này
- Regroup top bar (tách rõ status vs utility buttons) — ux-designer đề xuất nhưng đã kiểm tra: UNDO/INFO/SET đã dùng size `xs` nhỏ sẵn, mức độ cần thiết thấp hơn 4 mục trên, hoãn lại
- Contrast re-check cho `--pan-hi` với text `--dim` — art-director tự flag "at risk", cần chạy `tools/verify.mjs` xác nhận (chưa chạy trong phiên này vì `verify.mjs` cần server + Playwright, ngoài phạm vi công cụ hiện có)

## Việc cần làm tiếp

- [ ] Chạy `tools/verify.mjs` để xác nhận contrast AA với `--pan-hi` mới (8 luật UI)
- [ ] Author pixel-art icon 6 body part theo spec đã có
- [ ] Cân nhắc quay lại top-bar regroup nếu người chơi thật vẫn thấy rối
