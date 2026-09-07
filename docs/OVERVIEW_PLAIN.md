# Axie Dice Tactics: Lunacia Mutants
## Tổng quan game — bản dễ hiểu (cập nhật 2026-09-05)

*Đây là bản viết lại không dùng thuật ngữ kỹ thuật, dành cho bất kỳ ai muốn hiểu game đang có những gì, mạnh ở đâu, và đang thiếu gì — không cần biết lập trình. Bản kỹ thuật đầy đủ (có trích dẫn code, để đội ngũ phát triển dùng) nằm ở file riêng.*

---

## Game này là gì

Một game nhập vai chiến thuật chơi một mình, chơi theo lượt, trên trình duyệt web. Mỗi Axie trong đội của bạn là một viên xúc xắc 6 mặt — mỗi mặt tương ứng với một bộ phận cơ thể thật của Axie đó (miệng, sừng, lưng, đuôi, mắt, tai), và mỗi bộ phận cho một khả năng khác nhau.

Điểm đặc biệt nhất: **quái vật cũng roll xúc xắc trước, và bạn nhìn thấy hết** — thấy nó sẽ đánh ai, đánh bao nhiêu — rồi mới tới lượt bạn quyết định. Không có gì bị giấu. Đây là hướng đi ngược hẳn với phần lớn game roguelike nổi tiếng khác (Slay the Spire, Dicey Dungeons) — nơi bạn phải đoán rồi mới biết kết quả. Ở đây bạn tính toán trước khi hành động, không phải đoán mò.

Bạn cũng có thể **hoàn tác** bất kỳ lựa chọn nào trong lượt của mình trước khi bấm kết thúc lượt — thử sai không mất gì.

## Chơi như thế nào

Mỗi lượt chơi: xúc xắc của cả bạn và quái vật cùng roll → bạn được đổi lại một vài viên nếu không ưng ý → bạn dùng từng mặt đã roll lên mục tiêu → kết thúc lượt, quái vật ra đòn.

Một ván chơi (gọi là "run") có hai độ dài để chọn:
- **Ngắn:** 12 trận, khoảng 15 phút.
- **Dài:** 20 trận, khoảng 35 phút.

Đội của bạn có 5 Axie. Sau mỗi trận thắng, cả đội được hồi đầy máu và sống lại toàn bộ — không bị dồn thiệt hại từ trận này sang trận khác, để bạn không bị rơi vào vòng xoáy thua liên tục.

## Bản kế hoạch cũ đã lỗi thời — và lỗi thời theo cả hai chiều

Trước khi làm ra game, đội ngũ có viết một bản kế hoạch thiết kế đầy đủ. Bây giờ so lại với game thật thì thấy: **bản kế hoạch đó sai theo cả hai hướng**, không phải chỉ thiếu vài chi tiết.

**Nhiều thứ kế hoạch nói "sẽ có" nhưng chưa bao giờ được làm ra:** một hệ thống rèn luyện Axie qua thời gian, một cơ chế ghép bộ phận khác dòng máu, một cơ chế "tuyên bố mục tiêu" trong combat, một loại tiền tệ cứng thứ hai, một chế độ chơi đặc biệt có vé tham gia. Tất cả những cái này **không tồn tại trong game hiện tại**. Kéo theo đó, toàn bộ phần kế hoạch kiếm tiền trong bản cũ cũng chỉ là ý tưởng trên giấy — **game hiện tại chưa có cách nào kiếm tiền cả.**

**Ngược lại, có những thứ kế hoạch nói "để sau" thì lại đã làm xong rồi:** bảng xếp hạng cạnh tranh (có cơ chế chống gian lận điểm số phía máy chủ), khả năng nhập Axie thật (NFT) của người chơi vào game, hệ thống tài khoản người chơi, và nhạc nền. Đặc biệt, hệ thống tài khoản này còn là một **cửa bắt buộc** — mục quan trọng nhất, nói ở dưới.

## Những gì đã có, đo được bằng số thật

**Bộ phận & khả năng.** Trước đây có một lỗi khiến hai Axie cùng loại (dù khác bộ phận) tạo ra viên xúc xắc **giống hệt nhau** — nghĩa là hàng trăm Axie khác nhau chơi y như nhau. Lỗi này đã được sửa: hiện tại có **285 tổ hợp mặt khác nhau**, không còn cái nào trùng.

**Vật phẩm ma thuật (relic).** Trước đây không có tài liệu thiết kế nào cho hệ thống này cả, và khi kiểm lại thì thấy nhiều vật phẩm hiếm yếu hơn vật phẩm thường, có vật phẩm mạnh gấp đôi mức nó nên có. Đã làm lại từ đầu: hiện có **94 vật phẩm**, chia đều theo 4 mức độ hiếm, không còn vật phẩm nào lệch mức.

**Sức mạnh đội hình.** Có một cơ chế thưởng khi hai Axie đứng cạnh nhau trong đội hình cùng roll ra loại mặt giống nhau — Axie đánh sau sẽ mạnh hơn 15%. Cơ chế này khiến việc **sắp xếp thứ tự đội hình** trở thành một quyết định chiến thuật thật sự, chứ không chỉ là chọn Axie mạnh nhất.

**Độ khó.** Đo bằng máy chơi tự động (không phải người thật) qua 500 ván: tỉ lệ thắng ván ngắn khoảng **20%**, ván dài khoảng **8%**. Con số ván dài này đã **đạt mục tiêu đề ra**, không cần chỉnh thêm.

**Tiến triển dài hạn.** Có hệ thống mở khoá nội dung, một "mùa giải" 30 mốc thưởng không giới hạn thời gian và không có nhánh trả tiền để đi nhanh hơn (một quyết định thiết kế tử tế, đáng giữ), và một hệ tiêu điểm cho người chơi lâu năm.

**Nhạc nền và âm thanh.** Trước đây game hoàn toàn không có nhạc, chỉ có tiếng động khi đánh nhau. Vừa thêm một bản nhạc nền: phần mở đầu bài hát chỉ phát một lần khi vào game, sau đó chuyển sang đoạn lặp — cắt ghép cẩn thận để không nghe thấy chỗ nối. Nhạc là phần **tuỳ chọn**: nếu vì lý do gì đó không tải được, game vẫn chạy bình thường, chỉ là im lặng, không bị lỗi hay đơ.

**Hiệu ứng hình ảnh.** Vừa thêm một hiệu ứng đặc biệt khi một đòn đánh hạ được từ 2 quái trở lên cùng lúc, hoặc gây được ít nhất một nửa máu của trùm — màn hình rung mạnh hơn, chữ "OVERKILL" hiện lớn, để khoảnh khắc đó cảm giác "đã" hơn hẳn một đòn đánh bình thường.

## Rào cản lớn nhất: bắt buộc phải đăng nhập mới được chơi

Đây là điều quan trọng nhất cần biết, và bản kế hoạch cũ không hề nhắc tới.

Ngay màn hình đầu tiên, người chơi mới **chỉ thấy nút Đăng nhập / Đăng ký** — không có cách nào chơi thử trước, không có chế độ khách. Đây là một quyết định có chủ đích (để đồng bộ tiến trình và chuẩn bị cho bảng xếp hạng), không phải lỗi. Nhưng nó đi kèm rủi ro: bản hiện tại **chưa có cách khôi phục mật khẩu**, nên ai quên mật khẩu là mất luôn quyền chơi, không chỉ mất đồng bộ dữ liệu.

Nhìn theo góc độ sản phẩm: những game cùng thể loại thành công (Slay the Spire, Balatro, Luck be a Landlord) đều cho chơi ngay lập tức, không cần tài khoản. Bảng xếp hạng là thứ giữ chân người đã thích game rồi — nhưng ở đây nó đang bị đặt làm **điều kiện đầu tiên** trước khi ai biết game có vui hay không. Đây là thứ đáng cân nhắc sửa trước tiên, vì nó ảnh hưởng tới việc có bao nhiêu người chịu thử game ngay từ đầu.

## Rủi ro cần biết trước khi công bố rộng rãi

- **Nghiêm trọng nhất:** hệ thống nộp điểm lên bảng xếp hạng hiện **chưa xác minh ai đang nộp điểm**. Về mặt kỹ thuật, điểm số không thể làm giả (máy chủ tính lại toàn bộ), nhưng bất kỳ ai cũng có thể nộp điểm **dưới tên người khác**, vì hệ thống không kiểm tra danh tính người gửi. Cần sửa trước khi quảng bá bảng xếp hạng rộng rãi.
- Bộ kiểm tra tự động của game hiện chỉ soi kỹ **2 trong số 27 màn hình** (màn chính và màn chiến đấu). Các màn như Cửa hàng, Kho báu, Bảng xếp hạng chưa từng được rà soát tự động về lỗi hiển thị.
- Game hiện **chưa chơi được bằng bàn phím** — chỉ chơi được bằng chuột/chạm. Đây là vấn đề khả năng tiếp cận đã được ghi nhận từ lâu, chưa xử lý.
- Có một báo cáo lỗi (ngày 2026-09-05): người chơi bị "đơ" giữa trận, không đánh được, phải bỏ ván đang chơi mới thoát ra được. Đã thu hẹp thời gian chờ tự khôi phục xuống còn **5 giây** (trước đó có thể lên tới 14 giây) để người chơi không phải chờ lâu — nhưng nguyên nhân gốc gây ra hiện tượng đó **vẫn chưa tìm ra**. Nếu gặp lại: đợi vài giây, đừng thoát ván ngay.

## Nên làm gì tiếp theo, theo thứ tự ưu tiên

1. **Bỏ yêu cầu đăng nhập bắt buộc cho chế độ chơi thường** — chỉ yêu cầu tài khoản khi cần nộp điểm lên bảng xếp hạng. Đây là việc có tác động lớn nhất và tốn ít công sức nhất, quyết định việc có bao nhiêu người chịu thử game.
2. Vá lỗ hổng xác minh danh tính khi nộp điểm bảng xếp hạng.
3. Mở rộng bộ kiểm tra tự động ra thêm các màn hình quan trọng (Cửa hàng, Kho báu, Bảng xếp hạng).
4. Làm cho game chơi được bằng bàn phím.
5. Điều tra nguyên nhân gốc của lỗi "đơ" giữa trận.

## Tổng kết

**Điểm mạnh nhất:** chiều sâu xây dựng đội hình là có thật — 94 vật phẩm thay đổi hẳn luật chơi (không chỉ cộng số), nhiều hướng xây dựng đội khác nhau, và cách chống gian lận điểm số (máy chủ tính lại từ đầu mọi hành động) là một giải pháp thông minh, hiếm gặp ở game indie.

**Điểm yếu nhất:** mọi thứ hay ho ở trên chỉ dành cho người **đã ở trong game rồi**. Cánh cửa đăng nhập bắt buộc đang chặn ngay từ đầu — dù bên trong có hay đến đâu, số người thật sự chạm được tới nó đang bị giới hạn nghiêm trọng ngay từ bước đầu tiên.
