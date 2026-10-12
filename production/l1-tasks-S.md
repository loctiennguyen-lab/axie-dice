# Lane S — việc còn lại sau review security (12/10)

Đã sửa trong l1/S: mục 1, 2, 3, 4, 5, 6, 9 và các LOW. Còn lại, chưa làm:

## Mục 7 — shop_roll không mua thì soft-lock
`shop_roll` được tiêu thụ bởi `shop_buy`. Người chơi xin seed (món có random) rồi rời shop mà không mua thì epoch không bao giờ
được tiêu thụ, luật "không xin chồng" chặn mọi epoch sau. Cần: cho `shop_done` cũng tiêu thụ `shop_roll` (và xem lại các kind khác
có cùng kiểu: `reward_reroll`, `event_choice`), hoặc xin `shop_roll` chỉ lúc đã chắc mua. Quyết cùng làn A (hợp đồng 1.3).

## Mục 8 — danh tính token và khoá
- `kid` trong run token + quy trình xoay `RUN_TOKEN_KEY` (hiện chỉ một khoá, đổi khoá = mọi token đang sống chết).
- `jti` / thu hồi token: token sống tới 2 giờ, chưa có cách thu hồi khi đổi thiết bị hay khoá tài khoản.
- `hello` phải hỏi D1: session còn sống, tài khoản không bị khoá (ADR 4.6, "hỏi lại D1 ở hello và mọi thao tác tiền").
  Hiện RunCore chỉ kiểm chữ ký token.

## Mục 10 — socket chưa hello
Socket mở mà không gửi `hello` ngồi mãi (giữ DO thức). Cần `alarm()` đóng socket chưa auth sau ~10 giây (alarm là timer duy nhất
được dùng, ADR F12). Hiện chỉ có token bucket và đóng khi gửi message khác trước hello.

## Khác (đã ghi trong code, chưa phải của review)
- Verifier phải kiểm `(turn, k)` của mỗi epoch `reroll` khớp vị trí thật trong log (ghi ở `argsProblem`, run_core.js).
- Hook `charge` ví chưa nối (chờ quyết định Gem ở server). Mọi yêu cầu trả tiền đang bị từ chối.
- Bearer cho desktop, tài khoản khách, `row_types`, đối soát `pending_aid` ở hello.
- Tên key của `args` cho `event_choice`, `reward_reroll`, `shop_roll` là đoán (whitelist ARG_KEYS): chốt với làn A rồi siết lại.
