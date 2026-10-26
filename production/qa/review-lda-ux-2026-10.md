# UX review LD-A + LD-B (Land beta) — ux-designer, 2026-10-26
Nhánh beta/lda 24c697d. Ảnh: `production/qa/evidence/lda/land_t{1,2}_{1920x1080,1280x720}.png`, Profile: `/Users/loc.tien.nguyen/my-game-wt/lda/production/qa/evidence/c6-m12-overview-guest-1080.png` (thực tế 1280x720, khách).
Ảnh 1280 là 1280x720 thật (đã kiểm toạ độ). Ảnh Profile chỉ có 1280, không có bản 1920.

**Verdict: APPROVE WITH CHANGES**

## (a) Chip HUD tier — đạt một nửa
- Chip "Upgrade Land · Savannah 1/6 · 0/20,000" thấy rõ ở góc trên trái, đổi sang "Forest 2/6 · 0/100,000" sau khi lên tier.
- Thiếu: không ghi đơn vị (Stone) và không có số còn thiếu. Người mới không hiểu 20,000 là gì. Đề nghị "0/20,000 Stone" (hoặc "còn 20,000 Stone").
- Chip này không có vẻ ngoài bấm được, chưa rõ có bấm được không. Nếu bấm được thì cần ≥44 và hint; nếu không thì ổn.
- 1280x720: chữ chip nhỏ (~13px thật), đọc được nhưng sát mức dưới.

## (b) Banner lên tier — đạt
- Ảnh t2: nền tối, Land đổi thật (xanh lá, cây, nhà mới), tiêu đề "Your Land is now Forest", nút "Look around" có focus. Khoảnh khắc rõ.
- Lỗi chữ: "new decor set." viết thường đầu câu, dấu chấm kiểu danh sách ("+3 preset slots. new decor set. +2 Rare decor.") đọc như 3 câu cụt. Nên viết thành một câu hoặc 3 dòng gạch đầu.
- Thân banner ở 1280 nhỏ (~12px thật). Tiêu đề và nút ổn. Nút ~40px thật ở 1280 (tỉ lệ stretch từ 1080 thì ≥44 logic, ok nếu stretch bật; Lane I xác nhận).

## (c) Axie đi lại là của mình — không chứng minh được bằng ảnh
- Code: `LandAxies.pick_keys` + `_wander_keys` lấy từ Axie của người chơi, nhưng ảnh tĩnh không thấy rõ. Không có tên/nhãn khi trỏ chuột trong ảnh. Cần lane QA chạy thật với tài khoản có Axie riêng để xác nhận.

## (d) Quà khởi đầu — báo bằng toast, KHÔNG có trong ảnh
- Code `Land.gd:223`: toast "Welcome gift: 3 decor are in your storage" 4s. Ảnh chụp không ở lần đầu nên chưa thấy. Rủi ro: 4s ngắn, và quà vào "storage" mà người chơi chưa biết storage ở đâu (Edit Land [E]). Đề nghị toast nhắc "Edit Land (E)" hoặc nhấn mạnh nút đó lần đầu.

## (e) Profile mục Land — đạt
- Có hàng "Land": Tier Savannah 1/6, Aesthetic score 0, Milestones claimed 0/8. Đọc được, không cắt chữ, chiều cao ô ~32px, không phải nút nên ok.
- Nhãn xám nhỏ ("Tier", "Aesthetic score") ~12-13px thật ở 1280, tương phản hơi yếu. "Aesthetic score 0" không giải thích; tooltip/hint sẽ hay.

## Luật UI3 / 1280x720
- Chip, nhãn Profile, thân banner nhìn dưới 16px thật ở 1280. Nếu project dùng stretch canvas_items thì cỡ logic là 16-18, chấp nhận; nếu không thì vi phạm. Lane I xác nhận.
- Bất thường ở 1280 (không có ở 1920): hai chip "Sign in to use" xếp dọc ở giữa trên (~11px, chữ rất nhỏ, đè gần đỉnh Land). Cần xem đó là gì (Raid/Codex?); nếu là nút bị khoá thì lý do "Sign in to use" có rồi nhưng cỡ chữ quá nhỏ và không có nhãn gì cho biết nút nào. Cần sửa hoặc giải thích.
- "Sign in to play" dim đúng khi banner mở. Disabled có lý do ở chỗ khác ổn.

## Cần sửa trước khi duyệt hẳn
1. Chip: thêm "Stone" + số còn thiếu.
2. Sửa câu banner (viết hoa, tách dòng).
3. Giải thích hai chip "Sign in to use" ở 1280 hoặc nâng cỡ chữ.
4. Chụp thêm lần đầu có toast quà, và xác nhận Axie đi lại là của mình.
