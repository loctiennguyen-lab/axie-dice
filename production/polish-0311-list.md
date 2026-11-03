# Danh sách polish đề xuất, 3/11/2026 (trước closed beta)

Nguồn: 3 run thật trên bản live (s7 có shop + make-room, s59 Anchor awaken, s23), mỗi run 1920 và 1280; `run.log` (QA_CLIP / QA_ANOMALY); `liam-notes.md`; lỗi QA2 còn mở trong `next-session-2026-11-02.md`; luật UI trong `godot/CLAUDE.md`.
Chưa sửa gì. Liam chọn mục nào thì mới làm.

Đường dẫn ảnh viết tắt: `P/` = `/Users/loc.tien.nguyen/my-game/production/qa/polish-0311/`. Tên file đầy đủ có dạng `flow-win-anchor--<tên>-<cỡ>.png`.

Cỡ: S = dưới nửa ngày, M = 1–2 ngày, L = hơn thế.

## Đọc log QA_CLIP trước (để khỏi mất công)

Log có rất nhiều dòng CLIP/OFFSCREEN, phần lớn **không phải lỗi thật**, đã nhìn ảnh đối chiếu:
- `Victory` band rect x=-288 rộng 2496: đó là băng chạy ngang màn, cố ý.
- Các dòng `CoresPlate/ScrollContainer/OwnedList` y > 1000: nằm trong ScrollContainer, đang cuộn, ảnh map thấy bình thường (hơi bất tiện, xem mục 14).
- Nhãn `PSN 3` / `WEA2` y = -30 trên enemy: có thể là nhãn trạng thái của kẻ địch lệch lên mép trên lúc enemy-turn. Chưa thấy trong ảnh, cần xem video/chụp lại (mục 17).
- Nút `Hold / Wild / Overcast` "need=137–319 have=64": nút tròn 64 px, chữ lý do không hiện trong nút (mục 5).
- Màn Result (s59): `CardScroll` nằm dưới màn, cuộn được. Nhưng ảnh `result` chụp ra chỉ thấy nền Land, không thấy bảng kết quả (xem mục 3).
- **Thật sự cần xem: 40 dòng QA_CLIP ở màn login** (mục 1).

## Liam quyết (3/11)
- Làm **cả 22 mục** trong file này.
- Đợt polish này **làm lại mọi art do AI vẽ trước đây**. Không còn art AI nào sau đợt này.
- Nguyên tắc: kho asset (design-library, Sky Mavis) dùng trước. Chỉ phần kho không có mới vẽ mới. Mọi brief art kèm bảng tồn kho, và Liam xem bảng trước khi gửi.
- Phần kho không có: **Claude Design vẽ lại nhưng phải BÁM KHO**, tức tô hoặc ghép từ asset chính thức, theo đúng style đồ kho. Liam duyệt từng món.
- Khung thẻ theo bậc, crest, socket, hiệu ứng hạt của UI-06 (Claude Design vẽ) cũng tính là art AI, **làm lại luôn** đợt này.

## Nhóm A. Nên sửa trước playtest

| # | màn | thấy gì (cụ thể) | đề xuất sửa | cỡ | ai làm | ảnh bằng chứng |
|---|---|---|---|---|---|---|
| 1 | Đăng nhập (người chơi quay lại / chưa đăng nhập) | Chỉ có logo AXIE DICE trên nền Land mờ. Không có nút Google, không có "Play as guest". Log: panel `SignInPanel` có rect y = -3555, tức là bị phình rồi trôi lên khỏi màn (cả 40 dòng ở s7 1920, và ở s59). Đây đúng là lỗi "cột nâu trống" đã ghi trong next-session. | Kiểm xem hotfix đã nằm trên bản live chưa. Nếu rồi mà vẫn thấy thế thì chưa hết lỗi: giới hạn kích thước panel, kiểm khi CHƯA đăng nhập (ẩn danh). Đây là cửa vào của mọi tester ngoài. | S–M | code | `P/s7-1280x720/flow-win-anchor--login-returning-guest-1280x720.png`, `P/s7-1280x720/flow-win-anchor--login-returning-guest-1p6s-1280x720.png`, `P/s59-1920x1080/run.log` dòng 19–25 |
| 2 | Make room (Boss Pact) + Slot swap | Hai chỗ nói số slot khác nhau: slot-swap ghi "Passive slots are full (9 of 8)" (9/8 vô lý); Make room trong Pact ghi "Slots are full. Sell one relic" (không có số; từ "relic" lẫn với "Core"). Lone Wolf có thể tốn 2 slot (đã ghi ở QA2). Dùng 3 từ khác nhau: relic / Core / pact. | Chốt cách đếm slot (Core nào tốn mấy slot), viết lại một câu chung: "Cores: 8 of 8. Sell one to take X". Thống nhất từ "Core". | S (chữ) + Liam quyết cách đếm | Liam quyết + code | `P/s7-1280x720/flow-win-anchor--slot-swap-1280x720.png`, `P/s7-1280x720/flow-win-anchor--pact-make-room-1280x720.png` |
| 3 | Kết quả run (Result) | Ảnh chụp màn kết quả chỉ thấy nền Land mờ, không thấy bảng. Có thể chụp trước khi fade xong, nhưng log đã thấy các node `ResultPlate/CardScroll`. Nếu thật là bảng xuất hiện trễ hoặc nằm dưới màn thì người chơi vừa thắng boss xong nhìn vào khoảng trống. | Chụp lại ở 2 s sau khi vào Result; kiểm bảng nằm đúng trong màn và có nút chính (Continue) thấy ngay không cần cuộn. | S (kiểm) | code | `P/s7-1280x720/flow-win-anchor--result-1280x720.png`, `P/s59-1920x1080/flow-win-anchor--result-1920x1080.png` |
| 4 | Combat, Lõi kích hoạt | Liam: đường/mũi tên từ ô Lõi xuống Axie (vòng sáng ở ô Lõi, đường chấm, chấm chạy tới unit) nhìn rất xấu. | Brief Claude Design thử 2–3 hướng thay cho đường chấm. Kho asset có thể đã có: bộ VFX/glow nhỏ, ngọc/emblem Lõi (đã dùng cho icon), tia sáng ở `design-library` (cần kiểm trước). Chỉ vẽ phần kho không có, ví dụ cách "nối" Lõi với Axie. Có thể đơn giản nhất là bỏ đường, chỉ nháy ô Lõi + pulse nhẹ trên Axie. | M | **cần Claude Design** (kèm bảng tồn kho asset trước) + Liam duyệt hướng | `/Users/loc.tien.nguyen/my-game/production/qa/bugs/liam-notes.md` dòng 5; chưa có ảnh riêng, chụp tại lúc Lõi bắn (`P/s7-1920x1080/flow-win-anchor--turn1-battle-2-1920x1080.png` có Lõi trên HUD) |
| 5 | Combat, bốn nút công cụ (Undo / Hold / Wild / Overcast) | Nút chỉ là vòng tròn 64 px + nhãn một từ. Lý do tắt ("Wild: need 2 mana", "Overcast: Needs a Set", "Hold: pick a die") nằm trong text của nút nhưng không hiện ra, chỉ thấy "Pick a target" dưới End turn. Vi phạm luật "nút tắt nói lý do". Người mới không hiểu vì sao Wild/Overcast xám. | Hiện lý do ở một dòng dưới cụm nút (giống "Pick a target") hoặc trong tooltip khi hover/focus; nhãn dưới nút 14 px. | S–M | code | `P/s7-1280x720/flow-win-anchor--die-picked-1280x720.png`, `P/s7-1920x1080/run.log` (QA_CLIP die-picked: Wild need=165, Overcast need=195 have=64) |
| 6 | Bản đồ run + Boss | Tên boss bị cắt ("NIGHTMARE AGO…") ở tiêu đề NodeDetail và caption dưới node boss (lỗi đã biết). | Cho caption xuống 2 dòng hoặc rút gọn tên boss khi quá dài; tiêu đề NodeDetail wrap. | S | code | `/Users/loc.tien.nguyen/my-game/production/next-session-2026-11-02.md` mục ui06/finish; bản chụp cũ `03-run-map--boss-next`; trong 3 run này boss là "GOOEY KING" nên không thấy lỗi (`P/s7-1280x720/flow-win-anchor--map-pw6-1280x720.png`) |
| 7 | Shop | Cột Sell: tên bị cắt ("Lone Wolf Contract · ..."), giá cuối dòng không hiện ở dòng dài; mọi hàng đều dùng icon mũi tên/đỏ-xanh chung nên không phân biệt được Core nào. Nửa dưới màn trống ~40%. Cột Supplies chỉ 3 thẻ. | Tách giá ra một cột phải cố định, để tên xuống 2 dòng hoặc rút; dùng icon Lõi thật (như ở Make room thấy rõ có icon riêng). | M | code | `P/s7-1280x720/flow-win-anchor--shop-1280x720.png` |

## Nhóm B. Nên có

| # | màn | thấy gì (cụ thể) | đề xuất sửa | cỡ | ai làm | ảnh bằng chứng |
|---|---|---|---|---|---|---|
| 8 | Reward (thưởng sau trận) | Nửa dưới của cả ba thẻ trống (chữ chỉ chiếm ~1/3 trên). Thẻ Lõi có mô tả dài làm nút Reroll thấp hơn thẻ cạnh (art-director đã ghi). | Cho thẻ thấp hơn hoặc dồn nội dung (thêm "trước → sau" cho Level Up, vd. HP/face trước và sau) để lấp chỗ trống. | M | code (+ art-director xem) | `P/s7-1280x720/flow-win-anchor--reward-1-1280x720.png` |
| 9 | Chọn Anchor | Màn rất dày chữ ở 1280 (3 thẻ, nhiều khối "Rule / Price / Awakens"), chip House Core chỉ ~14 px, dòng chú thích dưới là 3 dòng nhỏ. Người mới khó đọc hết trước khi chọn. | Thu gọn: để Rule + Price nổi, "Awakens" và "House Cores" mở khi chọn thẻ; chú thích SET/M/Cracked đổi thành tooltip khi hover. | M | Liam quyết (độ nhiều thông tin) + code | `P/s7-1280x720/flow-win-anchor--anchor-selected-1280x720.png` |
| 10 | Run rule (Crow Herald / Rising Tide) | Thẻ rất cao, nội dung chiếm nửa trên; một ô lớn trống ở giữa. Nút "Pick a rule" xám trong khi thẻ trái có viền sáng nên trông như đã chọn nhưng nút vẫn tắt. | Hoặc thu thẻ, hoặc thêm minh hoạ (ví dụ ví dụ số: "Fight 3 won in 4 turns, pick is Rare → Epic"); cho thẻ có focus nhìn khác thẻ đã chọn. | M | code + Claude Design nếu cần hình minh hoạ | `P/s7-1920x1080/flow-win-anchor--core-1-1920x1080.png` |
| 11 | Boss Pact | Cả 3 thẻ dùng cùng một icon mặt trăng, ô icon lớn mà trông giống nhau. Nút "Skip pact" nhỏ hơn "Accept", chữ ~14 px. Phần chữ nói "benefit and drawback" khá ổn. | Dùng icon riêng cho từng pact (kho có sẵn icon Lõi/ngọc có thể dùng); nếu kho không có, nhờ Claude Design 3–4 icon pact. | M | code (dùng kho) + **Claude Design** cho phần thiếu | `P/s7-1920x1080/flow-win-anchor--pact-6-1920x1080.png` |
| 12 | Make room / Slot swap | Chip "Rare" kiểu cũ ở thẻ Brittle Dice (lỗi đã biết, ở bản chụp mới thấy Rare chữ xanh trên 2 thẻ nền). Thẻ Make room (Pact) không có icon Lõi, chỉ "Passive" + giá, trong khi Slot swap có icon và mô tả. Hai sheet này trông như hai màn khác nhau. | Dùng chung một sheet cho cả hai, cùng icon + mô tả ngắn. | M | code | `P/s7-1280x720/flow-win-anchor--pact-make-room-1280x720.png` vs `P/s7-1280x720/flow-win-anchor--slot-swap-1280x720.png` |
| 13 | Event / Rương (Ancient Crypt) | Ổn: tranh to, 2 lựa chọn rõ. Nhưng nút "Pick a choice" xám cạnh dưới phải, tách khỏi 2 lựa chọn; ảnh vuông chiếm hơn nửa màn, chữ nhỏ. Tiêu đề viết hoa khác mọi màn khác (Title Case). | Đẩy nút xuống giữa, chữ mô tả >= 14 px thật; thống nhất kiểu tiêu đề. | S | code | `P/s7-1280x720/flow-win-anchor--event-15-1280x720.png` |
| 14 | Bản đồ run, ô Cores | Danh sách Core cuộn trong ô nhỏ bên trái; ở 1280 chỉ thấy 2,5 Core, phần còn lại phải cuộn. Hàng "Iron Vow" chỉ ghi "Rare" mà không có icon hay mô tả (khác hàng khác). Hàng thiếu thông tin. | Cho mọi hàng cùng định dạng (icon + tên + headline); hoặc gọn thành lưới icon, mô tả ở tooltip. | M | code | `P/s7-1280x720/flow-win-anchor--map-pw6-1280x720.png` |
| 15 | Combat (1280) | Giữa màn nhiều khoảng trống; chữ trên thẻ xúc xắc (tên Axie, HP "Pomod...") bị cắt ở tên dài; "Name Tag" nổi giữa sân nhìn như placeholder, không biết là gì. | Rút tên bằng tên ngắn/tooltip; làm rõ "Name Tag" là Core hay nhãn kẻ địch (nếu là nhãn của quái "named foe", đánh dấu bằng icon). | S–M | code + Liam xác nhận ý nghĩa | `P/s7-1280x720/flow-win-anchor--die-picked-1280x720.png` |
| 16 | Combat, Boss | Cột boss bên phải cao, chip "ENRAGE IN 13 then +20%/turn" dễ bỏ sót; Boss Rhythm (Prep/Strike/Hollow) tốt nhưng chiếm nhiều chỗ ở góc trái. Ô Axie Egg ở xúc xắc thứ 6 hiện "- / Ears / Axie Egg 5/5" trông như xúc xắc hỏng. | Đánh dấu ô Egg decoy bằng icon trứng thay "-". | S | code | `P/s7-1920x1080/flow-win-anchor--turn1-boss-1-1920x1080.png` |
| 17 | Combat, trạng thái kẻ địch | Log: nhãn `PSN 3`, `WEA2` ở y ≈ -30 (trên mép màn) lúc enemy-turn. Không nhìn thấy trong ảnh, nhưng nếu thật thì độc/yếu bị mất khi quái đứng cao. | Chụp lại enemy-turn với quái bị Poison/Weaken; kẹp nhãn vào trong màn. | S | code | `P/s7-1920x1080/run.log` (QA_CLIP enemy-turn PSN 2 / WEA2), `P/s7-1920x1080/flow-win-anchor--enemy-turn-1920x1080.png` |
| 18 | Ngọc bậc trên strip Core | Art-director: ngọc bậc trên strip chỉ ~6 px ở 1280, khó đọc. | Phóng to hoặc dùng chữ bậc cạnh ngọc; kiểm kho có icon ngọc bậc lớn hơn. | S | code (dùng kho) | `P/s7-1280x720/flow-win-anchor--map-pw6-1280x720.png` (strip Cores) |

## Nhóm C. Để sau

| # | màn | thấy gì (cụ thể) | đề xuất sửa | cỡ | ai làm | ảnh bằng chứng |
|---|---|---|---|---|---|---|
| 19 | Nút "Reveal the cards first" | Hơi lệch (lỗi đã biết), không có trong 3 run này (cần phiên Gacha/Core pick). | Căn lại giữa theo nút chính. | S | code | `/Users/loc.tien.nguyen/my-game/production/next-session-2026-11-02.md` mục 5 |
| 20 | Hint phím | Map ghi "Arrows pick · Enter or double-click travels · Esc menu" ở góc dưới: chữ nhỏ, trong khi luật chỉ dùng Space. | Đổi cho khớp luật (Space) hoặc bỏ hẳn khi chơi chuột. | S | Liam quyết | `P/s7-1280x720/flow-win-anchor--map-pw6-1280x720.png` |
| 21 | Màn tiêu đề / Land sau đăng nhập | Logo và tagline nằm lệch trái, nền Land rất mờ; không có gợi ý bấm tiếp. | Sau khi sửa mục 1 thì kiểm lại bố cục; có thể nhờ Claude Design một bản màn đăng nhập mới. | M | **Claude Design** | `P/s7-1280x720/flow-win-anchor--after-guest-Land-1280x720.png` |
| 22 | Đồng bộ chữ giữa các màn | Tiêu đề và chữ nút dùng nhiều kiểu: "Take Big Hand", "Pick a card", "Pick a rule", "Pick a choice", "Pick one to sell". | Thống nhất "Pick…" khi chưa chọn, tên hành động khi đã chọn. | S | code + Liam duyệt chữ | các ảnh reward / core-1 / event / make-room ở trên |

## Mục "cần Claude Design" và kho asset (để kiểm trước)

| Mục | Phần kho có thể đã có (kiểm `asset-library/design-library/` trước) | Phần có thể phải vẽ |
|---|---|---|
| 4 (Lõi kích hoạt) | glow/tia sáng/particle sprite, ngọc và emblem Lõi (đã dùng làm icon thư viện) | cách "nối" Lõi với Axie nếu không dùng đường chấm |
| 11 (icon Boss Pact) | icon Lõi, emblem, ngọc bậc, icon hourglass/moon đang dùng | 3–4 icon pact riêng (nhẹ, một style với bộ Core) |
| 10 (minh hoạ Run rule) | icon hourglass, icon sóng/nước (nếu kho có) | hình minh hoạ cho Rising Tide / Crow Herald (nếu cần) |
| 21 (màn đăng nhập) | nền Land, logo | bố cục màn đăng nhập mới |

Theo nguyên tắc của Liam: lập bảng tồn kho trước, chỉ giao Claude Design phần kho không có.

## Nhận xét chung về cảm giác một run

- Nhịp ổn ở phần đầu (Anchor → run rule → bản đồ → trận), nhưng ba màn chọn liên tiếp (Anchor, run rule, Core đầu) đều nhiều chữ; người mới phải đọc 3 lần luật trước khi đánh trận đầu.
- Phần giữa run (reward → map → shop → event) hơi đều và hơi trống: nhiều màn có nửa dưới bỏ không (reward, shop, run rule), trong khi màn Anchor và Pact lại chật. Cân lại độ dày chữ sẽ đỡ cảm giác lúc thừa lúc thiếu.
- Chỗ rối nhất: slot Core. Số slot, giá bán, "Passive", "relic/Core/pact" mỗi màn nói một kiểu. Tester sẽ hỏi "mình còn mấy chỗ".
- Combat nhìn rõ hơn hẳn so với các màn menu (thẻ xúc xắc to, bản đồ boss rhythm tốt), nhưng cụm nút công cụ nhỏ và không nói lý do khi tắt.
- Lỗi chắn cửa lớn nhất vẫn là màn đăng nhập trống (mục 1): sửa xong mới tính đến polish.

Lưu ý giới hạn: mình chỉ xem khoảng 15 ảnh trong 3 run (ưu tiên s7); chưa xem kỹ s59 (Anchor awaken) và s23, chưa xem hết ảnh 1920 của từng màn. Mục 3, 15 (Name Tag), 17 cần chụp lại hoặc Liam xác nhận trước khi sửa.
