# Axie Dice Tactics: Lunacia Mutants

> **Sửa 2026-08-31**: gỡ mục "Gọi mặt" (Declare) khỏi guide này. Cơ chế này được
> `combo-decision-memo.md` đề xuất và `bloodline-system.md` v1.0/v1.1 mô tả, nhưng
> `bloodline-system.md` v1.2 §"Tóm tắt thay đổi" đã ghi rõ **§4 CHAIN/COMBO bị gác
> lại, không nằm trong scope build** — và `engine.js`/`data.js` xác nhận không có
> implementation nào. Guide trước đó mô tả nó như tính năng đang chạy; đây là lỗi
> đồng bộ tài liệu, không phải mô tả tính năng thật. Nếu quyết định gỡ gác lại
> được đảo ngược, thêm lại mục này sau khi xác nhận đã ship.

Axie Dice Tactics là một game roguelike chiến thuật chơi trên trình duyệt, lấy cảm hứng từ Slice & Dice và xây dựng bằng thế giới Axie Infinity. Mỗi Axie trong đội của bạn là một viên xúc xắc sáu mặt, mỗi mặt là một bộ phận cơ thể thật của Axie. Bạn tung xúc xắc, quyết định dùng mặt nào vào đâu, và dẫn năm Axie vượt qua một chuỗi trận đánh với quái vật Chimera.

Điều làm game này khác với roguelike thông thường là tính minh bạch. Kẻ địch không giấu bài. Trước khi bạn hành động, bạn đã biết chính xác chúng sắp làm gì, đánh ai, bao nhiêu sát thương. Mọi thất bại đều là do bạn tính sai, không phải do xui.

## Một trận đánh diễn ra như thế nào

Mỗi lượt có bốn bước.

Đầu lượt, cả năm Axie của bạn và toàn bộ quái vật cùng tung xúc xắc. Mặt quái vật tung ra chính là ý định của nó trong lượt này, và bạn nhìn thấy ngay lập tức.

Sau đó bạn được đổi lại những mặt xúc xắc chưa ưng ý. Số lần đổi có hạn, mặc định một lần mỗi lượt, có thể tăng lên qua phần thưởng trong trận.

Khi đã ưng bộ mặt trên tay, bạn gán từng mặt vào mục tiêu: đánh địch, tạo giáp cho đồng đội, hồi máu, hay bất cứ hiệu ứng nào mặt đó mang lại. Trong lúc này bạn có thể thử nghiệm và bấm Undo thoải mái, miễn là chưa đổi xúc xắc lần nữa hoặc chưa kết thúc lượt.

Cuối cùng bạn kết thúc lượt, quái vật thực hiện đúng ý định đã báo trước, và trận đấu tiếp tục.

Không có gì trong game này bị giấu khỏi bạn cho tới khi bạn tự nguyện tung xúc xắc lần tiếp theo.

## Xúc xắc và sáu bộ phận

Mỗi Axie có một viên xúc xắc sáu mặt: mouth, horn, back, tail, eyes, ears. Đây đúng là sáu loại bộ phận của một Axie thật, và mỗi mặt mang tên và hình ảnh của một bộ phận có thật trong game Axie Infinity gốc.

Tên bộ phận không quyết định nó làm gì. Một mặt back thường tạo giáp, nhưng có back đánh ba lần liên tiếp, có back gây sát thương xuyên giáp. Điều này giữ đúng bản chất của Axie Infinity, nơi mỗi bộ phận đều có bài riêng và không có công thức cố định theo vị trí. Bạn sẽ phải đọc kỹ từng mặt xúc xắc thay vì đoán theo tên.

Mỗi mặt còn có thể mang thêm một hoặc nhiều từ khóa kỹ năng, ví dụ cleave lan sát thương sang mục tiêu kề cạnh, poison rút máu dần theo lượt, cantrip tự kích hoạt ngay khi tung trúng mà không cần bạn thao tác gì thêm. Càng chơi bạn sẽ càng quen mặt nào làm gì chỉ qua icon và màu sắc.

## Sáu class, sáu lối chơi

Mỗi class Axie có một bản sắc chiến thuật riêng, lấy thẳng từ cách các bộ phận đó hoạt động trong Axie Infinity gốc.

Plant xoay quanh giáp. Giáp của Plant không chỉ để chịu đòn, nó là điều kiện để kích hoạt những hiệu ứng mạnh khác như hồi máu diện rộng và gọi thêm đồng minh.

Beast chơi crit và cửa tử. Càng nhiều bạo kích, càng máu thấp, Beast càng nguy hiểm.

Aquatic là hệ tốc độ và mana. Chúng nạp năng lượng nhanh và có nhiều mặt tự kích hoạt.

Reptile bền bỉ. Chúng tự hồi giáp mỗi lượt, phản đòn khi bị tấn công cận chiến, và mạnh dần lên khi trận kéo dài.

Bug chuyên phá giáp và gài độc, khiến quái vật yếu dần và mất khả năng tự hồi phục.

Bird là class kỳ lạ nhất: chúng tự làm mình yếu đi để đổi lấy sức mạnh lớn hơn. Nghe phi lý nhưng đây đúng là cách nhiều Axie Bird thật hoạt động, và chơi thử bạn sẽ thấy nó rất đã.

Mỗi class chỉ dùng bộ phận riêng của mình khi lên đội, nhưng thỉnh thoảng bạn sẽ được đề nghị Meta Morph, cho phép ghép một bộ phận từ class khác vào Axie của mình. Đây là cách hợp lệ duy nhất để pha trộn lối chơi giữa các class, và nó xuất hiện đều đặn chứ không phải thứ hiếm gặp.

## Độ hiếm của một mặt xúc xắc

Trong một trận, mỗi mặt xúc xắc có bốn bậc sức mạnh: Common, Rare, Epic, Legendary. Bậc càng cao thì trị số càng lớn và mặt càng có thêm từ khóa kỹ năng.

Điểm quan trọng cần nhớ: bậc sức mạnh này chỉ tồn tại trong trận bạn đang chơi. Khi trận kết thúc, mọi thứ trở về Common. Thứ bạn giữ lại vĩnh viễn là những bộ phận nào đã được mở khóa trong bộ sưu tập của bạn, không phải bậc sức mạnh của chúng.

Nói cách khác, sưu tầm nhiều bộ phận giúp bạn có nhiều lựa chọn hơn khi lên đội, không giúp bạn mạnh hơn. Sức mạnh luôn phải kiếm lại từ đầu mỗi trận, bằng cách lên tier cho Axie hoặc nhận phần thưởng trong lúc chơi. Đây là lý do một tài khoản mới và một tài khoản chơi lâu năm có thể gặp nhau ở cùng một mức độ khó công bằng.

Bậc cao nhất, Mythic, sẽ đến sau trong lộ trình phát triển. Nó gắn với từng cặp class và loại bộ phận chứ không gắn với một bộ phận cụ thể, nghĩa là bất kỳ mặt nào đạt Legendary đều có cơ hội chạm tới Mythic của đúng cặp đó. Người sở hữu Axie Mystic thật ngoài đời sẽ thấy hình ảnh gốc độc quyền cho bộ phận tương ứng, còn hiệu ứng Mythic thì ai chơi đủ giỏi cũng chạm tới được.

## Lai tạo danh tính: Gene Mutation

Trong lúc chơi bạn sẽ thỉnh thoảng được đề nghị Gene Mutation, cho phép đổi hẳn một mặt xúc xắc sang một bộ phận khác. Đổi lại, mặt đó sẽ quay về Common dù trước đó nó đã lên bậc cao đến đâu. Đây là một sự đánh đổi thật: bạn từ bỏ sức mạnh đã tích lũy để lấy một danh tính mới, thường vì bộ phận cũ không còn hợp với hướng build hiện tại.

## Chọn Lead Axie

Trước mỗi trận bạn chọn một Lead Axie từ bộ sưu tập của mình, một Axie bạn đã ghép sẵn sáu bộ phận và đặt tên. Bốn Axie còn lại sẽ được tuyển ngẫu nhiên trong lúc chơi. Lead Axie vào trận với đúng sáu bộ phận bạn đã chọn nhưng vẫn ở bậc Common như mọi Axie khác, vì vậy thứ bạn mang theo là bản sắc, không phải lợi thế chỉ số.

## Sưu tầm và tiến trình dài hạn

Ngoài mỗi trận đấu, bạn còn có một lớp tiến trình sống lâu hơn một run: mở khóa thêm bộ phận, ghép Axie mới cho bộ sưu tập, và tích lũy độ thành thạo cho từng bộ phận bạn hay dùng.

Tài khoản mới được mở sẵn sáu mươi bộ phận, đủ cho bạn thấy nhiều kiểu Axie khác nhau ngay từ những trận đầu tiên thay vì lặp đi lặp lại vài hình dạng quen thuộc.

Dùng một bộ phận nhiều lần qua các trận sẽ tích lũy độ thành thạo cho nó. Đủ mốc thành thạo, bạn mở ra một biến thể khác của cùng bộ phận đó, cùng mức sức mạnh nhưng đi theo hướng khác, cộng thêm khung hiển thị và hình ảnh riêng. Độ thành thạo không bao giờ cộng thêm chỉ số hay làm bộ phận đó xuất hiện thường xuyên hơn. Bạn có thể ghim một bộ phận để nó tích lũy độ thành thạo nhanh gấp đôi.

Khi đã ghép đủ sáu bộ phận ưng ý cho một Axie, bạn có thể lưu nó lại và dùng làm Lead Axie cho những lần chơi sau.

## Tiền tệ và cửa hàng

Có ba loại tiền trong game.

Gene Shard kiếm được bằng cách chơi, dùng để mở bộ phận mới, ghi và đổi Axie đã lưu. Giá mở một bộ phận là như nhau cho mọi bộ phận, không tính theo độ hiếm, vì bộ sưu tập của bạn không chứa độ hiếm.

Moon Dust là tiền mua bằng tiền thật, dùng để mở nhanh bộ phận hoặc mua vật phẩm trang trí. Nó không có tỷ giá quy đổi sang Gene Shard, và nó chỉ giúp bạn đi nhanh hơn chứ không mạnh hơn người chơi miễn phí.

Gauntlet Ticket dùng để tham gia chế độ đấu trường có bảng xếp hạng, mỗi ngày bạn được ba vé miễn phí. Mỗi vé mở một seed hoàn toàn mới, bạn không thể mua thêm lượt chơi lại trên cùng một seed.

Chúng tôi cam kết một số điều sẽ không bao giờ xuất hiện trong game này: không năng lượng giới hạn số trận bạn chơi mỗi ngày, không bán bộ phận có chỉ số cao hơn bộ phận thường, không gacha để cầu may mắn, không bán thêm slot Lead Axie, không bán lượt chơi lại trên cùng một seed đấu trường. Cộng đồng Axie từng trải qua giai đoạn play to earn không bền vững, và chúng tôi không muốn lặp lại điều đó theo bất kỳ hình thức nào.

## Độ khó và Ascension

Sau khi đã quen game, bạn có thể bật các mức Ascension để tăng độ khó, từ 0 đến 10. Mỗi mức tăng thêm sẽ khiến quái vật mạnh hơn đáng kể. Đây là cách những người chơi có bộ sưu tập lớn hoặc build mạnh vẫn tìm được thử thách phù hợp, thay vì cứ thắng dễ dàng mãi.

Có hai độ dài run để chọn. Run ngắn gồm mười hai màn, phù hợp cho một buổi chơi khoảng nửa tiếng. Run đầy đủ gồm hai mươi màn, dành cho ai muốn một hành trình dài hơn và sẽ được mở khóa sau. Dù chọn kiểu nào, khi bạn thắng hoặc thua một trận, đội hình sẽ được hồi đầy máu và Axie đã ngã xuống sẽ sống lại trước khi bước sang trận kế tiếp. Thử thách nằm ở từng trận đấu, không phải ở việc bào mòn dần đội hình của bạn qua nhiều trận.

## Sắp tới

Bậc Mythic, lớp NFT cho phép chủ sở hữu Axie thật mở khóa nhanh các bộ phận tương ứng, phiên bản chơi trên di động, và ba class bí mật lai giữa hai class gốc đang được phát triển cho các bản cập nhật sau. Chúng tôi sẽ thông báo khi từng phần sẵn sàng.
