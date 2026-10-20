# Nghiên cứu: Lõi (augment) trong ARAM: Hỗn Loạn (ARAM Mayhem) của LoL

Ngày: 20/10/2026. Người làm: agent nghiên cứu, cho Liam đọc trước khi chốt hệ Lõi của depth-v3 (`design/proposals/depth-v3-design.md` mục 2).

Cách làm: tra web (patch notes chính thức của Riot, trang hỗ trợ Riot, dev blog "Augmentmaxxing", bài trên Inven Global, esports.net, games.gg, earlygame, trang thống kê arammayhem.com, vài bản lưu thread Reddit). Wiki LoL và vài trang lớn (u.gg, mobalytics, sheepesports) chặn bot nên không đọc trực tiếp được, tôi dùng bản tóm qua bài khác. Tất cả tên và hiệu ứng dưới đây là tôi tóm lại bằng lời mình, không chép.

Độ tin cậy, nói trước:
- Cơ chế chung (mốc chọn, 3 thẻ, 1 reroll, 3 bậc, không trùng): chắc, nhiều nguồn khớp nhau, có cả trang Riot.
- Số cụ thể của từng Lõi: lấy từ arammayhem.com (cập nhật 19/10/2026, patch 26.20) và patch notes. Khá chắc, nhưng Riot chỉnh số liên tục, nên coi số là "cỡ chừng".
- Tỉ lệ ra từng bậc: **không nguồn nào công bố**. Đừng dựa vào con số nào cho chỗ này.
- Xếp hạng mạnh/yếu: là thống kê pick rate và ý kiến người viết guide, không phải số thắng chính thức.

---

## 1. Cơ chế

### 1.1 Dòng thời gian

- **Patch 25.21 (tháng 10/2025)**: ra mắt. ARAM bình thường (5v5, một đường, tướng ngẫu nhiên) cộng thêm Lõi lấy từ chế độ Võ Đài (Arena). Ban đầu là chế độ có hạn tới 25.24.
- **25.23**: thêm Đe chỉ số (Stat Anvil, mua bằng vàng sau cấp 9, có bản Bạc/Vàng/Lăng Kính). Bậc Bạc ít ra hơn ở lần chọn đầu, và lần 1 với lần 2 không được cùng là Bạc. Hạ yêu cầu hai Lõi nhiệm vụ (Steel Your Heart 350 xuống 300, Urf's Champion 22 xuống 18 mạng).
- **25.24**: thêm Lõi Lăng Kính từ Arena. Vài Lõi Lăng Kính mới bị giới hạn 1-2 người mỗi trận.
- **26.3 (đầu 2026)**: thêm khoảng 45 Lõi, thêm **Bộ Lõi** (set, 9 bộ, thưởng ở mốc 2/3/4 món), thêm **đường tiến trình** 32 cấp mở khoá Lõi mới và **Reroll Vàng**. Chế độ thành lâu dài. Có hotfix ngay hôm sau hạ ba bộ (Make it Rain, Archmage, Deathknell).
- **26.12 (giữa 2026)**: **bỏ hẳn Bộ Lõi**. Thêm **Lõi Kỹ Năng** (gắn vào một kỹ năng cụ thể của tướng) và thêm Lõi nhiệm vụ. Sau đó vài ngày hotfix **xoá hơn 450 tổ hợp Lõi Kỹ Năng x tướng** vì vô dụng hoặc không vui.
- **26.13 trở đi**: chỉnh số đều đặn, chuyển bậc vài Lõi (Archmage từ Vàng lên Lăng Kính, Quickstep ngược lại), xoá vài Lõi (Combusting Interest bị gỡ ở 26.14).
- Pool: 196 Lõi lúc ra, hơn 300 sau chưa tới một năm (theo bài thuyết trình của designer Riot trên Inven).

### 1.2 Chọn lúc nào, chọn mấy

- **4 lần chọn mỗi trận**: một lần đầu trận, rồi ở cấp 7, 11, 15. Nguồn lệch nhau về lần đầu (cấp 1 hay cấp 3), không quan trọng cho mình.
- **Chỉ nhận được khi đang ở nhà** (chết hoặc đứng trong vùng shop). Lõi đến lượt nhưng chưa về thì để chờ. Điều này nghĩa là chết không chỉ là thua: chết là lúc "mở quà". Bài phân tích trên games.gg nói thẳng: tướng hiếm chết (Yuumi) cuối trận có ít Lõi hơn.
- **Ô**: 4 ô cố định từ 4 lần chọn. Có ô thứ 5 chỉ dành cho vài Lõi đặc biệt (Lõi tặng thêm Lõi, Lõi nhiệm vụ).
- **Mỗi lần hiện 3 thẻ, chọn 1.** Không có bỏ qua.

### 1.3 Reroll

- Mỗi thẻ trong bộ ba **reroll được 1 lần, riêng từng thẻ** (không phải reroll cả bộ). Tức mỗi lần chọn thấy tối đa 6 Lõi. Reroll luôn ra Lõi cùng bậc.
- **Reroll Vàng** (mở ở đường tiến trình, 26.3): ở lần chọn bậc Bạc hoặc Vàng, có thể dùng lên một thẻ để **nâng thẻ đó lên một bậc** thay vì đổi sang Lõi khác. Có hai mức (cấp 13 và cấp 31 của đường tiến trình) tăng dần cơ hội lên bậc.
- Không có cách mua thêm reroll bằng tiền trong trận.

Nhận xét cho mình: reroll của Riot là "đổi một thẻ, giữ hai thẻ còn lại", không phải "đổi cả bộ". Người chơi giữ được thẻ mình đang ưng làm phương án an toàn rồi mới đánh cược ở thẻ kia. Đây là quyết định hay hơn reroll cả bộ.

### 1.4 Bậc

- **Bạc**: chỉ số và tiện ích đơn giản. **Vàng**: mạnh, thường đổi lối chơi một phần. **Lăng Kính**: hiếm, đổi hẳn tướng.
- **Cả 10 người cùng thấy một bậc** ở mỗi lần chọn, bậc này ngẫu nhiên, không theo mốc cố định. Ra Lăng Kính ở cấp 7 không đảm bảo gì cho cấp 11.
- Tỉ lệ không công bố. Chỉ biết: Bạc bị giảm ở lần đầu, và lần 1-2 không được cùng là Bạc.
- Riot chuyển bậc Lõi khi cần cân bằng (đổi bậc thay vì đổi số).

### 1.5 Trùng lặp và lọc

- **Không bao giờ thấy lại**: Lõi đã hiện trên màn chọn một lần thì không hiện lại trong trận đó (kể cả không chọn). Có lúc bug cho nhận trùng, Riot sửa ở 26.3.
- **Lọc theo tướng**: Lõi chỉ hiện nếu hợp tướng. Ví dụ Lõi "Draw Your Sword" chỉ hiện cho tướng đánh xa. Riot chia pool mỗi lớp tướng thành bốn nhóm: Tối ưu (hiếm, rất mạnh), Dùng được, Trung bình, Không hợp (lọc bỏ hẳn cho lớp đó).
- **Giới hạn người lấy**: vài Lõi Lăng Kính chỉ 1-2 người mỗi trận; Poro Blaster chỉ 1 người mỗi đội sau khi bị lạm dụng.
- Lõi mới mở khoá qua đường tiến trình được **đảm bảo hiện ở trận kế** (nếu hợp tướng, trừ Bạc), sau đó về tỉ lệ thường. Đây là cách cho người chơi "thử đồ mới" ngay.

### 1.6 Các loại Lõi

1. **Lõi chỉ số**: cộng thẳng (tầm đánh, tốc đánh, AP). Chủ yếu Bạc.
2. **Lõi tích luỹ (stack)**: mỗi lần làm gì đó thì mạnh thêm vĩnh viễn trong trận, thường mất một phần khi chết.
3. **Lõi đánh đổi**: được nhiều ở một chỗ, mất ở chỗ khác (bỏ chiêu cuối, bị khoá máu, tốn máu để dùng chiêu).
4. **Lõi biến đổi kỹ năng / Lõi Kỹ Năng**: gắn vào một kỹ năng, làm nó bắn ba tia, có bản sao dùng lại, đổi hiệu ứng.
5. **Lõi nhiệm vụ (Quest)**: làm xong một điều kiện thì nhận phần thưởng lớn (một món đồ riêng, hoặc chỉ số tăng 200%).
6. **Lõi cờ bạc**: tặng Lõi ngẫu nhiên bậc cao hơn, hoặc 2 Lõi hoàn toàn ngẫu nhiên.
7. **Lõi gắn với vật dụng chung**: nâng phép bổ trợ "Ném tuyết" mà ai cũng có, hoặc nâng một món đồ.
8. **Lõi vui / meme**: biến thành mèo con đi tìm mẹ, gọi tàu hoả khi chết, biến thành Poro. Không mạnh nhưng là thứ người ta kể lại.

### 1.7 Bộ Lõi (26.3 tới 26.12, đã bỏ)

Chín bộ, gom 2/3/4 món cùng chủ đề thì có thưởng. Ví dụ: bộ "Stackosaurus Rex" (Lõi tích luỹ tích nhanh hơn 50/100/200%), bộ "Firecracker" (đạn nảy thêm), bộ "Snowday" (nâng Ném tuyết), bộ "Deathknell" (giảm thời gian chờ hồi sinh).

**Vì sao Riot bỏ** (dev blog 26.12, tóm lại):
- Nhiều Lõi khác nhau dẫn về cùng một kiểu chơi, nên các build giống nhau.
- Người chơi chọn Lõi để gom bộ chứ không vì nó hợp tướng.
- Sức mạnh dồn vào thưởng bộ làm từng Lõi lẻ thấy yếu.
- Một hệ thống trông "tươi mới" vẫn có thể làm trận đấu đồng dạng.

Riot giữ lại vài bộ được yêu thích nhưng biến thành **một Lõi đơn** (ví dụ Stackosaurus Rex giờ là một Lõi cho tích nhanh ngay, không cần món thứ hai).

**Đây là bài học quan trọng nhất cho depth-v3**, vì bản thiết kế hiện có 4 bộ x 3 món (mục 2.6). Xem nguyên tắc 7 ở mục 4.

### 1.8 Triết lý cân bằng Riot công bố (dev blog 26.12)

Ba câu hỏi kiểm công bằng:
1. Tướng nào cũng phải có một build mạnh để nhắm tới.
2. Không tướng nào được lúc nào cũng ra build mạnh.
3. Có build mạnh chưa đủ để thắng cả trận.

Công cụ: rút Lõi làm hỏng trải nghiệm ra khỏi pool (xoay vòng), thêm Lõi cho lớp tướng thiếu, **ưu tiên buff cái yếu hơn nerf cái mạnh** (để không rơi vào vòng nerf mãi), chỉ nerf khi quá lố (ví dụ Grandma's Chili Oil hồi máu quá nhiều).

Bài trên Inven (designer Noor Amin) thêm: khi Lõi làm trận đánh kéo dài và ngại giao tranh, họ không giảm sức mạnh Lõi mà chỉnh **đường cong sát thương so với độ trâu** của cả chế độ. Kết quả là giao tranh nhỏ, nhiều hơn, trận thấy nhanh hơn. Họ cũng phân Lõi theo bốn kiểu người chơi (thích cạnh tranh, thích thử nghiệm, thích đánh tay đôi hoành tráng, thích vui vẻ) để tìm chỗ thiếu.

---

## 2. Lõi tiêu biểu (khoảng 45 cái, theo nhóm)

Số theo arammayhem.com patch 26.20 nếu không nói khác. B = Bạc, V = Vàng, L = Lăng Kính. "Hạng" là xếp hạng của trang đó trên khoảng 200 Lõi (S+ tới D).

### 2.1 Lõi tích luỹ (mạnh dần theo trận)

| Tên | Bậc | Tóm tắt | Vì sao hay |
|---|---|---|---|
| Tank Engine | V | Mỗi lần hạ hoặc hỗ trợ hạ tướng: +5% máu tối đa và to ra 5%, không trần. Chết mất 65% số chồng. | Hạng S+, pick 43%. Tank thấy mình lớn dần theo nghĩa đen. Mất 65% khi chết làm mỗi pha giao tranh có cược. |
| Shrink Engine | V | Mỗi lần hạ: +10 hồi chiêu và +2% tốc chạy, nhỏ lại 4% (tới 80%). Chết mất 65%. | Hạng S+. Cặp đối xứng với Tank Engine. Mage chạm mốc "chiêu không hồi" (Morgana khoảng 80 hồi chiêu là spam Q/W mãi). |
| Infinite Recursion | L | +60 hồi chiêu, +3 mỗi lần hạ. | Khởi đầu đã mạnh, lớn thêm theo trận. |
| Phenomenal Evil | V | Mỗi lần kỹ năng trúng tướng địch: +1 AP vĩnh viễn (giới hạn 1 lần/giây). Nếu là Lõi thứ 2 thì khởi đầu 40 chồng. | Thưởng chơi chủ động, đánh nhiều. Có cơ chế "đến muộn thì bù" (40 chồng). |
| Slap Around | B | Mỗi lần khống chế cứng tướng địch: +10 sức mạnh thích ứng, không trần. Chết mất nửa. | Biến tướng nhiều khống chế (Rell, Thresh) thành nguồn sát thương. |
| Tap Dancer | L | Kết liễu lính cho thêm sát thương đòn đánh, cộng dồn. | Thưởng việc vốn nhàm (farm lính). |
| Tooth Fairy | V | Dồn sát thương nhanh lên tướng địch làm rơi "răng", nhặt răng cho xuyên giáp/xuyên phép vĩnh viễn. | Thưởng chơi kiểu sát thủ. Bị nerf ở 26.13 (ngưỡng 20 lên 25%, mỗi răng 5 xuống 4). |
| Hubris | V | Mỗi lần hạ: cộng dồn sức công. | Lõi "lăn cầu tuyết" kinh điển. |

### 2.2 Lõi đánh đổi (được cái này, mất cái kia)

| Tên | Bậc | Tóm tắt | Vì sao hay |
|---|---|---|---|
| Back to Basics | L | Khoá vĩnh viễn chiêu cuối. Đổi lại kỹ năng thường +35% sát thương, +70 hồi chiêu, +35% hồi máu/khiên. | Hạng S. Đổi cách chơi tướng hoàn toàn. Tướng có chiêu cuối yếu (Ryze, Gangplank) hưởng lợi, tướng sống nhờ chiêu cuối thì bẫy. Người chơi phải tự đánh giá tướng mình. |
| Draw Your Sword | L | Chỉ cho tướng đánh xa: biến thành cận chiến, đổi lại +30% công, +25% tốc đánh, +30% máu, +25% tốc chạy, 20% hút máu. | Hạng S+. Xạ thủ thành đấu sĩ. Đổi vai trò, không chỉ đổi số. |
| Glass Cannon | L | Máu bị khoá ở 70% tối đa. Gây thêm sát thương chuẩn (25% cận chiến, 15% đánh xa). | Hạng D. Ví dụ đánh đổi thất bại: mất nhiều, được ít. Đã được buff ở 26.13 mà vẫn đáy. |
| Ominous Pact | L | Dùng kỹ năng tốn 5% máu hiện tại. Càng mất máu càng nhiều AP (tối đa 75-150 ở 70% máu đã mất), thêm tốc chạy và hút máu. | Chơi "sống mép". Hạng B+, chỉ hợp vài tướng. |
| Overflow | V | Mana tiêu gấp đôi. Đổi lại +10% sát thương (cộng theo mana tối đa), hồi máu/khiên mạnh hơn. | Biến mana thành tài nguyên căng. Ryze là người hưởng lợi nhất. |
| Celestial Body | V | +1250 máu, -10% sát thương gây ra. | Đánh đổi đơn giản, đọc một lần là hiểu. |
| Mad Scientist | L | Mỗi lần hồi sinh chọn một trong hai: to (công, máu, to 40%) hoặc nhỏ (hồi chiêu, tốc chạy, nhỏ 40%). | Quyết định lặp lại mỗi lần chết, theo tình hình trận. |
| Giant Slayer | L | Nhỏ đi 75%, +30% tốc chạy, thêm sát thương lên tướng to hơn mình. | Combo với Lõi làm địch to (Tank Engine của địch thành điểm yếu của nó). |

### 2.3 Lõi biến đổi kỹ năng

| Tên | Bậc | Tóm tắt | Vì sao hay |
|---|---|---|---|
| Ultimate Revolution | L | Dùng chiêu cuối xong thì hồi ngay để dùng lần hai (75 giây mới có lại, chết là có lại). | Hai chiêu cuối liền nhau là một pha "wow". Mạnh đầu trận, yếu cuối trận. |
| Jeweled Gauntlet | L | Kỹ năng chí mạng được, tỉ lệ theo AP. | Mở một hướng build không tồn tại ở game thường (pháp sư đi chí mạng). |
| Echo Cast | L | Chọn một kỹ năng; mỗi lần dùng, một bản sao chạy ra vị trí chuột và dùng lại kỹ năng đó. | Lõi Kỹ Năng điển hình. |
| Multishot / Tripleshot / Spell Split / Chain Reaction | (Lõi Kỹ Năng) | Kỹ năng bắn thêm tia, tách ra, hất tung dây chuyền. | Hạng C/D trên thống kê. Đây là nhóm bị xoá 450 tổ hợp vì nhiều cái gắn vào chiêu không hợp thì không làm gì. |
| Final Form | L | Dùng chiêu cuối: 10 giây được khiên 50% máu, 20% hút máu, 30% tốc chạy. | Biến chiêu cuối thành "chế độ cuồng". |
| Infernal Conduit | L | Kỹ năng đốt cộng dồn vô hạn, mỗi tick đốt giảm hồi chiêu. | Vòng tự nuôi: đốt nhiều thì dùng chiêu nhiều thì đốt nhiều. Bị sửa ở 26.4 (giảm hồi chiêu khi trúng nhiều địch thành cộng thay vì nhân). |
| Mystic Punch | L | Đòn đánh giảm hồi chiêu kỹ năng. | Ghép với Lõi khác thành vòng lặp. Đổi từ 20% sang 1,25 giây phẳng ở 26.3. |
| Bread and Butter | V | Kỹ năng Q được +100 hồi chiêu. | Đơn giản nhưng đổi nhịp chơi của một nút. |

### 2.4 Lõi nhiệm vụ

| Tên | Bậc | Điều kiện -> thưởng | Ghi chú |
|---|---|---|---|
| Quest: Steel Your Heart | V | Có Heartsteel và tích hơn 300 máu từ nó -> máu cộng thêm từ Heartsteel tăng 200%. | Hạng S, pick 31%. Nhiệm vụ gắn với món đồ, đi tự nhiên theo build tank. |
| Quest: Urf's Champion | L | 18 lần hạ/hỗ trợ -> nhận món "Golden Spatula" (tăng gần mọi chỉ số). | Hạ từ 22 xuống 18 vì quá khó. Giao động giữa D và S- tuỳ patch. |
| Quest: Wooglet's Witchcap | (nhiệm vụ) | Gộp hai món AP thành một. | Thưởng là một "ô đồ thêm". |
| Support Main, Tooth Fairy (bản nhiệm vụ 26.12) | | Hồi máu/khiên đồng đội đủ mức, hoặc dồn sát thương đủ lần. | Riot muốn mở rộng nhóm này. |
| King Me | L | Lần đầu chạm cổng nhà địch -> 1 Lõi Lăng Kính ngẫu nhiên + nâng món đồ huyền thoại thêm 1000 vàng chỉ số. | Hạng D. Bài học: điều kiện đến quá muộn trong trận nên thưởng vô nghĩa. |

### 2.5 Lõi cờ bạc

| Tên | Bậc | Tóm tắt | Vì sao hay |
|---|---|---|---|
| Transmute: Prismatic | V | Nhận ngay 1 Lõi Lăng Kính ngẫu nhiên (không phải 2 thẻ còn lại). | **Lõi số 1 cả chế độ** (S+, pick 64%). Người chơi rất thích đổi chắc lấy may nếu cược lên bậc cao hơn. |
| Transmute: Chaos | L | Nhận 2 Lõi hoàn toàn ngẫu nhiên (mọi bậc). | A+. Trúng thì như hai Lõi S, trượt thì như hai Lõi Bạc. |
| Transmute: Gold | B | Nhận 1 Lõi Vàng ngẫu nhiên. | Cùng ý ở bậc thấp. |
| Pandora's Box | L | Biến các Lõi thành Lõi ngẫu nhiên khác. | Hạng B. Cược quá rộng, ít người thích. |

### 2.6 Lõi gắn với cái chết và hồi sinh

| Tên | Bậc | Tóm tắt | Vì sao hay |
|---|---|---|---|
| Dive Bomber | B | Chết thì nổ, gây sát thương chuẩn 20% máu tối đa của mỗi địch quanh đó. | Chết thành một chiêu. Hạng A. |
| Self Destruct | ? | Mỗi 25 giây gắn bom lên mình, nổ hất tung địch xung quanh. | |
| Train of the Dead | ? | Chết thì một đoàn tàu lao ra. | Lõi meme, người ta nhớ. |
| Escape Plan | B | Xuống dưới 35% máu: khiên 65% máu tối đa, +150% tốc chạy, nhỏ lại, giảm dần trong 5,5 giây. Hồi 75 giây. | Hạng S-, Lõi Bạc mạnh nhất. Cứu mạng đúng lúc tạo khoảnh khắc. |
| Repulsor | ? | Dưới 35% máu: đẩy lùi và làm chậm 90% địch quanh mình. | |

### 2.7 Lõi có điều kiện / thưởng chơi theo cách cụ thể

| Tên | Bậc | Tóm tắt | Vì sao hay |
|---|---|---|---|
| Circle of Death | L | 70% lượng hồi máu của mình thành sát thương phép lên tướng địch gần nhất. | Đổi vai: tướng hồi máu thành tướng sát thương. |
| Homeguard | B | +100% tốc chạy, mất 3 giây khi bị tướng đánh. | Thưởng giữ khoảng cách. |
| Don't Change the Channel | B | Mỗi giây vận chiêu được khiên. | Lõi "ngách" cho tướng vận chiêu, chỉ hiện cho họ. |
| Heavy Hitter | B | Đòn đánh gây thêm 3,5% máu tối đa của mình. | Tank thành nguồn sát thương. |
| Big Brain | V | Khiên bằng 300% AP, làm mới mỗi 70 giây hoặc khi hồi sinh. | AP thành phòng thủ. |
| Get Excited! | V | Sau khi hạ tướng: +100% tốc chạy, +15% tốc đánh trong 4 giây. | Thưởng chuỗi hạ. |
| Executioner | V | +10% sát thương lên địch dưới 30% máu; hạ tướng thì làm mới kỹ năng thường. | Chuỗi hạ liên tiếp. |
| Spin to Win | B | Kỹ năng xoay tròn +30% sát thương, +30 hồi chiêu. | Rất hẹp, chỉ hiện cho tướng có chiêu xoay. Đúng tinh thần "khuếch đại bản sắc tướng". |

### 2.8 Lõi chỉ số (để so)

| Tên | Bậc | Tóm tắt |
|---|---|---|
| Deft | B | +60% tốc đánh |
| Leg Day | B | +50 tốc chạy, kháng làm chậm 40% |
| Witchful Thinking | B | +20-80 AP theo cấp |
| It's Critical | V | +50% chí mạng |
| Scoped Weapons / Scopier / Scopiest | B / V / L | Tầm đánh tăng theo bậc. Cùng một ý ở ba bậc. |
| Goliath | L | +35% máu, +15% sức mạnh, to 50%. |
| Mind to Matter | B | Máu cộng thêm bằng 50% mana tối đa. |

Để ý: cùng một ý có ba bậc (Scoped/Scopier/Scopiest; Transmute Gold/Prismatic). Riot dùng lại một ý ở nhiều bậc để pool trông rộng mà người chơi vẫn đọc nhanh.

### 2.9 Lõi bị coi là hỏng và cách Riot xử lý

| Lõi | Vấn đề | Riot làm gì |
|---|---|---|
| Poro Blaster | Ghép với Slap Around, Cruelty thành tích AP khổng lồ, nhiều người trong đội cùng lấy. | Chỉ 1 người mỗi đội được lấy, tích chậm hơn (hotfix 26.3). |
| Bộ Make it Rain / Archmage / Deathknell | Thưởng bộ quá mạnh ngay ngày đầu. | Hotfix ngày hôm sau: vàng thêm 30/50/100% xuống 15/30/50%; hoàn hồi chiêu 40% xuống 30%; giảm chờ hồi sinh 40% xuống 25%. Về sau bỏ cả hệ bộ. |
| Combusting Interest | Đốt ra vàng, top 5 cả chế độ. | Nerf 1% xuống 0,75% (26.13), rồi gỡ khỏi pool (26.14). |
| Tooth Fairy, Pressure Cooker, Spirit Bomb, Yowch My Coins | Quá mạnh. | Nerf số ở 26.13. |
| Infernal Conduit | Trúng nhiều địch là giảm hồi chiêu nhân lên. | Đổi công thức nhân thành cộng. |
| 450 Lõi Kỹ Năng | Gắn vào chiêu không hợp (hồi máu lên W của Master Yi, Echo Cast lên chiêu lướt của Lucian) thì không làm gì, hoặc bug. | Xoá hàng loạt bằng hotfix, sau đó sửa luật hiện thẻ để chỉ hiện trên chiêu có lợi. |
| Vàng khởi đầu +300 trên đường tiến trình | Người đã cày có lợi thế sức mạnh trong trận. | Thay bằng Reroll Vàng. |
| Glass Cannon, Pin Cushion, Twin Fire | Quá yếu. | Buff thay vì để chết. |

---

## 3. Vì sao gây nghiện, khen gì, chê gì

### 3.1 Cái làm người ta bấm "chơi tiếp"

- **Trận ngắn (10-20 phút) mà có một vòng build trọn vẹn.** Trong một trận vẫn có mở đầu, đỉnh sức mạnh, và một khoảnh khắc "build đã thành". Thua cũng chỉ mất 15 phút, nên muốn thử lại ngay với tướng khác, Lõi khác.
- **Lõi cứu được đội hình xấu.** ARAM vốn bực vì tướng ngẫu nhiên. Lõi cho người chơi một cách gỡ: đội "chắc thua" có thể lật thành đội mạnh nếu chọn khéo. Ngẫu nhiên đầu vào, nhưng có quyền quyết định sau đó.
- **Sức mạnh quá tay là chủ ý.** Nhiều người thích chính vì nó bất công và lố (tank to bằng nửa màn hình, Veigar có AP vô lý). Bài trên earlygame nói phần lớn cộng đồng không muốn chế độ "công bằng hơn", họ muốn "nhiều kiểu lố hơn".
- **Ai cũng có phần.** Riot cố cho mỗi lớp tướng có ít nhất một hướng mạnh, nên ít khi có người cầm tướng mà không có gì để mong.
- **Dễ vào.** Luật ARAM giữ nguyên, chỉ học thêm Lõi. Lõi lại được mô tả ngắn.
- **Nội dung mới đều đặn.** Pool từ 196 lên hơn 300, mỗi đợt có Lõi mới, Lõi mới mở khoá được đảm bảo xuất hiện ở trận kế. Riot nói số giờ chơi tăng theo từng bản cập nhật chứ không giảm dần như chế độ có hạn thường thấy.
- **Có chuyện để kể.** Lõi meme (tàu hoả khi chết, mèo con tìm mẹ, hoá Poro) không thắng trận nhưng làm trận đáng nhớ.

### 3.2 Những lời chê lặp lại

- **Trượt Lõi thấy tệ hơn trước.** Khi Riot đẩy sức mạnh đỉnh lên, trận "cầm Lõi xấu" thành vô vọng. Một bình luận Reddit được nhiều đồng ý: trúng thì mạnh hơn, trượt thì yếu hơn theo tỉ lệ.
- **Meta hình thành.** Sau vài tháng người chơi biết tướng nào với Lõi nào là tốt nhất, "trúng lớn" không còn hiếm. Một tank bất tử một lần thì vui, cứ cách một trận lại thấy thì mệt.
- **Lõi vô dụng trong bộ ba.** Lõi Kỹ Năng gắn vào chiêu không hợp là một thẻ chết, tức bộ ba chỉ còn hai lựa chọn thật. Đây là lý do lớn nhất của đợt xoá 450.
- **Mô tả khó đo.** Người chơi muốn biết Lõi gây/hồi bao nhiêu thật sự.
- **Hiệu ứng rối màn hình** và bug (Lõi nhận trùng, Lõi tự kích vô hạn).
- **Bộ Lõi làm build giống nhau** (Riot tự nhận).

### 3.3 Riot tránh một lối chơi trội bằng cách nào

1. **Không cho thấy lại Lõi đã hiện** trong cùng trận, nên không ai "câu" được đúng một Lõi bằng reroll.
2. **Bậc của lần chọn do game quyết và giống nhau cho cả 10 người.** Không ai chủ động chọn bậc. Kế hoạch build phải mềm.
3. **Mỗi thẻ chỉ reroll một lần**, và luôn cùng bậc.
4. **Lọc theo tướng**: bỏ hẳn Lõi vô dụng cho lớp tướng, nhưng giữ Lõi "Tối ưu" ở mức hiếm.
5. **Giới hạn số người lấy** cho vài Lõi nguy hiểm (1 người mỗi đội).
6. **Mất một phần khi chết** ở Lõi tích luỹ (50-65%). Mạnh dần nhưng không chắc chắn.
7. **Xoay vòng pool**: rút Lõi gây hỏng, thêm Lõi cho lớp thiếu. Ưu tiên buff cái yếu để có nhiều đường mạnh ngang nhau, thay vì nerf cái mạnh xuống.
8. **Chuyển bậc** thay cho chỉnh số (Archmage từ Vàng lên Lăng Kính nghĩa là nó ra hiếm hơn và đắt hơn về cơ hội).
9. **Chỉnh nền của chế độ** (đường cong sát thương/độ trâu) thay vì làm yếu từng Lõi.
10. **Bỏ hệ bộ** khi thấy nó kéo mọi người về cùng một đích.

---

## 4. Nguyên tắc thiết kế rút ra

1. **Lõi khuếch đại bản sắc cái mình đang có, không thay nó bằng một bản sắc chung.** Riot gọi Mayhem là chế độ "tướng trước tiên": Lõi tốt làm hook kéo xa hơn, tank to hơn, chứ không biến ai cũng thành cùng một thứ. Ví dụ: Spin to Win chỉ cho tướng có chiêu xoay, Heavy Hitter làm tank gây sát thương bằng chính máu của nó. Với mình: Lõi nên phóng to part, class, vị trí của đội đang cầm, không phải "+3 dmg cho ai cũng được".

2. **Đánh đổi rõ ràng tạo quyết định mạnh hơn cộng số.** Back to Basics (mất chiêu cuối, kỹ năng thường mạnh lên) và Draw Your Sword (xạ thủ thành cận chiến) nằm top vì người chơi phải tự đánh giá đội mình có hợp không. Nhưng đánh đổi phải cân: Glass Cannon mất 30% máu đổi lấy 15-25% sát thương thì nằm đáy dù được buff.

3. **Ba thẻ phải là ba lựa chọn thật.** Thẻ không làm gì với đội hiện tại là một thẻ chết. Riot xoá 450 Lõi Kỹ Năng vì lý do này và chia pool từng lớp tướng thành Tối ưu / Dùng được / Trung bình / Không hợp, bỏ hẳn nhóm cuối. Với mình: lọc theo đội (part, class, mặt) trước khi rút, depth-v3 đã có ý này ở 2.2, nên mở rộng cho mọi Lõi có điều kiện.

4. **Cho người chơi cược lên bậc cao hơn.** Lõi phổ biến nhất cả chế độ là Transmute: Prismatic, một Lõi Vàng "đổi chỗ này lấy một Lõi Lăng Kính ngẫu nhiên". Reroll Vàng cũng vậy: nâng bậc một thẻ thay vì đổi. Cược lên bậc trên luôn hấp dẫn hơn cược ngang. Pandora's Box (cược ngang, rộng) thì ít ai thích.

5. **Mạnh dần trong trận, nhưng có thể mất.** Tank Engine, Shrink Engine, Slap Around cho chồng không trần, mất 50-65% khi chết. Cảm giác lớn dần là thứ giữ người chơi trong trận, còn khả năng mất làm mỗi pha giao tranh có giá. Ví dụ đối xứng Tank/Shrink Engine còn cho thấy cùng một khung có thể ra hai Lõi khác vai.

6. **Lõi nhiệm vụ phải xong được giữa trận, và thưởng phải đến lúc còn dùng được.** Urf's Champion phải hạ yêu cầu 22 xuống 18. King Me bắt đi tới cổng nhà địch nên thưởng đến quá muộn, nằm hạng D. Steel Your Heart đi theo đúng hướng build tank sẵn có nên được chọn nhiều. Nhiệm vụ tốt là việc mình vẫn muốn làm, chỉ làm "nhiều hơn một chút".

7. **Đừng để thưởng bộ quan trọng hơn từng món.** Riot bỏ Bộ Lõi sau 4 tháng vì người chơi chọn Lõi để gom bộ, các build quy về cùng kiểu, và Lõi lẻ thấy yếu. Họ giữ ý hay nhất bằng cách gộp thành một Lõi đơn. Nếu mình giữ bộ, thưởng bộ nên nhỏ và mỗi món phải đáng lấy dù không có món còn lại.

8. **Một ý, nhiều bậc.** Scoped / Scopier / Scopiest, Transmute Gold / Prismatic. Người chơi học một lần, gặp lại ở bậc khác vẫn hiểu ngay. Pool trông rộng mà chi phí nội dung và chi phí đọc thấp.

9. **Biến thất bại thành tài nguyên.** Lõi chỉ nhận được khi về nhà, mà về nhà thường là do chết. Dive Bomber biến cái chết thành một đòn. Escape Plan biến lúc sắp chết thành pha thoát. Người chơi thua một pha vẫn có thứ để mong.

10. **Lõi vui được phép yếu, Lõi mạnh không được phép nhàm.** Mèo con, tàu hoả, Poro là thứ người ta kể lại dù không thắng. Ngược lại, khi Combusting Interest (đốt ra vàng) thành lựa chọn hiển nhiên thì Riot gỡ nó ra. Pool cần vài Lõi "để kể chuyện".

11. **Sửa lối chơi trội bằng nền và bằng xoay vòng, không chỉ bằng nerf.** Riot chỉnh đường cong sát thương/độ trâu của cả chế độ, chuyển bậc Lõi, rút Lõi ra rồi đưa vào lại, buff cái yếu. Nerf từng Lõi xuống là vòng lặp không hết.

12. **Không cho câu một Lõi cụ thể.** Lõi đã hiện thì không hiện lại, reroll mỗi thẻ một lần. Người chơi không thể ép ra build trong đầu, phải chơi với cái nhận được. Đây là chỗ khác biệt giữa "có quyết định" và "giải bài toán đã biết đáp án".

---

## 5. Chuyển sang Axie Dice

### 5.1 Đề xuất cho hệ thống (không phải Lõi cụ thể)

Đây là những chỗ tôi thấy depth-v3 mục 2 có thể học thêm từ Riot. Liam quyết.

- **Reroll từng thẻ thay vì cả bộ ba.** depth-v3 hiện là 2 reroll cả run, đổi cả bộ ba. Riot cho đổi từng thẻ (mỗi thẻ 1 lần). Đổi từng thẻ giữ lại được thẻ an toàn, nên quyết định là "đánh cược ở đâu" chứ không phải "đổi hết hay không". Gợi ý: giữ tổng 2 reroll cả run, nhưng mỗi reroll chỉ đổi 1 thẻ, cùng bậc, cùng trục.
- **Reroll Vàng**: một lựa chọn thay cho reroll thường: nâng một thẻ Rêu lên Hổ Phách (hoặc Hổ Phách lên Tinh Thể) cùng trục. Có thể là phần thưởng meta (thay perk relic khởi đầu), hoặc là phần thưởng của Lõi nhiệm vụ cấp thấp.
- **Lõi đã hiện thì không hiện lại trong run.** depth-v3 2.3 chỉ chặn Lõi đã sở hữu. Chặn luôn Lõi đã thấy làm pool lộ dần ra trong run, và chặn "chờ Lõi X quay lại".
- **Lọc theo đội cho mọi Lõi có điều kiện**, không chỉ 3 Lõi ở 2.2. Bảng mỗi Lõi một dòng `requires` (class, part, loại mặt, số Axie hàng trước...). Thà bộ ba yếu còn hơn bộ ba có thẻ chết.
- **Xem lại Bộ Lõi (2.6).** Bài học Riot nói rõ: bộ làm build giống nhau. Hai cách: (a) bỏ bộ, giữ các Lõi lẻ; (b) giữ bộ nhưng thưởng bộ nhỏ, chỉ ở 2 món, và mỗi món tự đứng được. Tôi nghiêng về (b) cho bump 1 vì đã nằm trong plan, nhưng nên ghi rõ "theo dõi tỉ lệ người chơi gom bộ, quá 50% run thì bỏ".
- **Lõi mở khoá mới đảm bảo hiện ở run kế.** Nếu sau này có đường mở Lõi (meta), đây là cách rẻ để người chơi thử ngay.
- **Chỗ chọn Lõi gắn với lúc "thất bại nhẹ".** Riot chỉ cho nhận khi về nhà, thường là sau khi chết. Mình có thể cho một lần chọn Lõi Rêu phụ khi người chơi thua một Elite nhưng còn sống (rút lui). Chỉ là ý, không cần cho bump 1.
- **Một Lõi "đổi chắc lấy may" ở mỗi bậc**, xem Lõi 1 và 2 bên dưới.

### 5.2 Lõi đề xuất (28 ý)

Quy ước như depth-v3 2.7: R Rêu, H Hổ Phách, T Tinh Thể. Số đặt cho tier-1 Common (mặt dmg 2-5, shield 2-4), cần sim. Mọi bonus phẳng vẫn nằm trong trần +10/mặt của depth-v3 3.4. Cột "Gần với" ghi Lõi đã có trong depth-v3 nếu ý trùng một phần, để Liam bỏ hoặc gộp. Cột LoL ghi Lõi gốc lấy tinh thần.

**Nhóm A: cược bậc (nguyên tắc 4)**

| # | Tên | B | Hiệu ứng | Thưởng lối chơi | Kết hợp | LoL | Gần với |
|---|---|---|---|---|---|---|---|
| 1 | Hòn Đá Mờ | H | Chọn thẻ này: không nhận gì ngay, nhận 1 Lõi Tinh Thể ngẫu nhiên (khác trục với 2 thẻ còn lại trong bộ ba). Lọc theo đội vẫn áp | Người thích cược, người đang thiếu "đỉnh" | Bất kỳ Lõi T nào | Transmute: Prismatic | - |
| 2 | Túi Hỗn Độn | T | Nhận 2 Lõi ngẫu nhiên, mỗi cái bậc ngẫu nhiên (Rêu 40 / Hổ Phách 40 / Tinh Thể 20). Chiếm 2 ô | Cược lớn cuối run | | Transmute: Chaos | - |
| 3 | Mắt Lunacia | R | Mọi lần chọn Lõi sau trong run hiện 4 thẻ thay vì 3 | Đầu tư cho sau, mất sức ngay | Lõi nhiệm vụ | (không có, ý từ "nhìn thêm") | perk relic khởi đầu (Liam đã chốt thẻ thứ 4 ở lần 1) |

**Nhóm B: đánh đổi lớn (nguyên tắc 2)**

| # | Tên | B | Hiệu ứng | Thưởng lối chơi | Kết hợp | LoL | Gần với |
|---|---|---|---|---|---|---|---|
| 4 | Gọt Xúc Xắc | T | Chọn 1 slot part (vd tail) khi nhận: mặt slot đó trên mọi viên bị khoá, viên ra mặt đó tự roll lại (xúc xắc thành 5 mặt). Mọi mặt còn lại +1 | Đội muốn bỏ mặt yếu, tăng độ ổn định | Kết Cục, Thác Đổ | Back to Basics | - |
| 5 | Xuống Trận | T | Chọn 1 Axie hàng sau khi nhận: nó chuyển vĩnh viễn lên hàng trước, mọi mặt heal/buff của nó thành mặt dmg cùng giá trị +2, +8 Max HP, hút máu 30% sát thương gây ra | Biến support thành đấu sĩ, đội đổi vai giữa run | Mũi Giáo, Thành Trì | Draw Your Sword | - |
| 6 | Thân Cổ Thụ | R | Mọi Axie +8 Max HP, mọi mặt dmg -1 (tối thiểu 1) | Đội rùa, chơi lâu | Bức Tường Sống, bộ Gai | Celestial Body | Mạch Đá (#1) là bản không có giá |
| 7 | Khế Ước Gai | H | Reroll không tốn mana mà tốn 2 HP của chính Axie có viên đó. Axie đã mất từ 50% HP: mọi mặt của nó +2 | Chơi sống mép, đội có heal | Vòng Tử Sinh (#13), Lối Thoát (#16) | Ominous Pact | Nợ Mana (#24) cũng trả máu, nhưng chỉ khi hết mana |
| 8 | Tràn Bờ | H | Reroll tốn gấp đôi mana. Đổi lại: mặt mana +2, và khi mana đầu lượt từ 6 trở lên thì mọi mặt dmg +2 lượt đó | Đội mana dồn rồi xả | Hồ Mana, Bể Tràn | Overflow | - |
| 9 | Hai Dạng | T | Đầu mỗi trận chọn 1 trong 2 dạng cho cả đội: **Lớn** (mọi Axie +6 Max HP, mặt dmg +1, mất reroll miễn phí) hoặc **Nhỏ** (+2 reroll miễn phí mỗi lượt, +1 mana đầu lượt, mọi Axie -4 Max HP). Thấy intent lượt 1 của quái trước khi chọn | Quyết định lặp lại mỗi trận, đọc trận | Lõi Rỗng, Thành Trì | Mad Scientist | - |

**Nhóm C: tích luỹ cả run, mất một phần khi ngã (nguyên tắc 5)**

Các Lõi này cần một field run (chồng mỗi Axie) trong `RunState` và save, giống Mạch Ngầm (#28). Đây là thứ duy nhất trong danh sách làm "run này khác run kia" theo thời gian, nên tôi nghĩ đáng tiền.

| # | Tên | B | Hiệu ứng | Thưởng lối chơi | Kết hợp | LoL | Gần với |
|---|---|---|---|---|---|---|---|
| 10 | Mai Lớn Dần | H | Mỗi quái bị Axie hàng trước kết liễu: Axie đó +1 Max HP vĩnh viễn trong run (không trần). Axie ngã trong trận: mất 2/3 chồng (làm tròn lên) | Tank tự đi kết liễu, đội đẩy đòn cuối cho hàng trước | Mũi Giáo, Bức Tường Sống | Tank Engine | - |
| 11 | Cánh Nhẹ Dần | H | Mỗi quái bị Axie hàng sau kết liễu: +1 chồng. Cứ 3 chồng: Axie đó +1 reroll miễn phí mỗi trận (tối đa +3). Ngã: mất 2/3 | Cặp đối xứng với #10, đội dồn kết liễu cho hàng sau | Lõi Rỗng | Shrink Engine | - |
| 12 | Vết Chàm | R | Mỗi lần mặt debuff hoặc poison của một Axie trúng quái: Axie đó +1 chồng (tối đa 1 chồng mỗi lượt). Mỗi 2 chồng: mặt dmg của nó +1 cả run (trần +5). Ngã: mất nửa | Đội khống chế/độc thành đội sát thương chậm | Chữ Ký Máu | Slap Around, Phenomenal Evil | - |
| 13 | Nanh Sưu Tầm | H | Kết liễu quái bằng đúng một mặt dmg từ đầy máu (one-shot, không tính token Egg): +1 "Nanh", mỗi Nanh = mặt dmg của cả đội có +1 xuyên giáp (trần 5) | Đội burst, dồn mặt lớn vào quái nhỏ | Kết Cục, Cất Lửa | Tooth Fairy | - |

**Nhóm D: đổi cách một part hoạt động (Lõi Kỹ Năng, nguyên tắc 1 và 3)**

Đây là bản Axie của Lõi Kỹ Năng. Mỗi Lõi gắn vào **một slot part** (mouth, horn, back, tail, eyes, ears). Bài học 450: chỉ hiện Lõi trên slot mà đội có mặt hợp (vd "Vọng Âm" chỉ hiện cho slot có mặt dmg ở ít nhất 2 Axie). Khi hiện, thẻ ghi luôn slot đã chọn sẵn, không bắt người chơi chọn slot trên thẻ.

| # | Tên | B | Hiệu ứng | Thưởng lối chơi | Kết hợp | LoL | Gần với |
|---|---|---|---|---|---|---|---|
| 14 | Vọng Âm [slot] | H | Mặt của slot này: dùng xong thì lặp lại 50% giá trị (làm tròn lên) vào một mục tiêu ngẫu nhiên hợp lệ khác | Đội có slot đó mạnh, AoE nhẹ | Hai Mặt | Echo Cast | Mặt Gương (#13) là bản T chọn mục tiêu |
| 15 | Ba Mũi [slot dmg] | H | Mặt dmg của slot này tách thành 3 đòn, mỗi đòn 40% giá trị (làm tròn lên), mục tiêu ngẫu nhiên. Mỗi đòn tính riêng cho thorns/khiên | Đội gặp nhiều quái nhỏ, phá khiên | Vết Chàm (mỗi đòn tính trúng) | Multishot / Tripleshot | - |
| 16 | Lối Thoát | R | Lần đầu mỗi trận một Axie xuống dưới 35% HP: nó nhận khiên bằng 50% Max HP, và nếu ở hàng trước thì đổi chỗ với Axie hàng sau còn nhiều HP nhất | Cứu mạng và xếp lại hàng tự động | Thành Trì, Bức Tường Sống (ngược nhau: Bức Tường Sống chỉ có 1 ô trước) | Escape Plan | - |
| 17 | Mặt Gai Ngược [back] | R | Mặt shield (thường từ back) dùng lên Axie hàng trước: Axie đó có thêm thorns bằng nửa giá trị khiên tới hết lượt quái | Shield chủ động phản đòn | bộ Gai, Kẻ Gác Cổng | Heavy Hitter (phòng thủ thành sát thương) | Hai Mặt (#12) cũng đổi shield thành dmg |
| 18 | Mắt Thôi Miên [eyes] | H | Mặt debuff của slot eyes, nếu quái bị trúng đang có intent đánh đơn: đổi mục tiêu intent đó sang Axie có nhiều khiên nhất | Điều khiển quái, thưởng đọc intent | Thành Trì, Mặt Gai Ngược | Stuck in Here with Me (kéo địch về mình) | - |

**Nhóm E: thất bại thành tài nguyên (nguyên tắc 9)**

| # | Tên | B | Hiệu ứng | Thưởng lối chơi | Kết hợp | LoL | Gần với |
|---|---|---|---|---|---|---|---|
| 19 | Nổ Bào Tử | R | Axie ngã thì nổ: mỗi quái mất 20% Max HP của chính nó (boss 8%), xuyên khiên | Đội chấp nhận mất người, đặt Axie yếu hàng trước làm bom | Tổ Ấm (Egg cũng nổ, nửa giá trị), Bức Tường Sống | Dive Bomber | - |
| 20 | Trăng Thứ Hai | T | Một lần mỗi trận, sau khi bấm kết lượt: được thêm một lượt EXECUTE ngay (roll mới, quái không hành động giữa hai lượt). Lượt quái kế tiếp gây +30% sát thương | Burst hai lượt liền, chọn đúng thời điểm (lượt Hở của boss) | Cất Lửa, Thác Đổ, nhịp boss 6.3 | Ultimate Revolution | - |
| 21 | Hình Dạng Cuối | H | Khi mặt Kết gây từ 8 sát thương trở lên: Axie dùng nó nhận khiên 50% Max HP và mặt dmg của nó hút máu 30% ở lượt sau | Chơi dồn Kết | Kết Cục, bộ Nanh | Final Form | - |

**Nhóm F: đổi vai và combo đặc biệt (nguyên tắc 1, 10)**

| # | Tên | B | Hiệu ứng | Thưởng lối chơi | Kết hợp | LoL | Gần với |
|---|---|---|---|---|---|---|---|
| 22 | Vòng Tử Sinh | T | Mỗi lần hồi máu cho Axie (kể cả phần hồi tràn): 70% lượng đó (làm tròn xuống) thành sát thương vào quái có HP thấp nhất. Sát thương này không tính là mặt dmg, không kích hút máu, để không thành vòng lặp với Xuống Trận (#5) hay Hình Dạng Cuối (#21) | Đội heal thành đội sát thương, Plant/Aqua có đường thắng | Hàng Sau Phát Sáng, Khế Ước Gai | Circle of Death | - |
| 23 | Kẻ Hạ Khổng Lồ | H | Mặt dmg vào quái có Max HP lớn hơn Axie dùng nó: +2. Vào boss: +4 | Đội nhỏ đánh boss, Axie máu thấp thành sát thủ | Thân Cổ Thụ là nghịch (làm Axie to lên) | Giant Slayer | - |
| 24 | Yên Bình | R | Axie chưa nhận sát thương nào trong trận: mọi mặt +2. Mất khi bị đánh (khiên chặn hết thì không mất) | Thưởng bảo vệ hàng sau, đầu tư khiên | Thành Trì, Vảy Sớm | Homeguard | - |
| 25 | Thợ Săn | H | Mặt dmg kết liễu một quái: viên vừa dùng quay lại tay và roll lại, dùng được tiếp (tối đa 2 lần mỗi lượt, không nhận Mồi/Kết ở lần dùng lại) | Chuỗi kết liễu, dọn quái nhỏ, chọn thứ tự đánh | Nanh Sưu Tầm, Kết Cục | Executioner | Mặt Gương (#13) cũng cho dùng hai lần, nhưng không cần kết liễu |
| 26 | Mèo Con Đi Lạc | R | Lõi vui. Axie có HP thấp nhất đội thành "mèo con": không bị quái đánh đơn chọn, mặt heal lên nó +100%. Nếu nó sống sót cả trận: +1 mana đầu trận kế | Kể chuyện, đội có một Axie yếu | Hàng Sau Phát Sáng | I'm a Baby Kitty Where is Mama | - |

**Nhóm G: Lõi nhiệm vụ (nguyên tắc 6)**

Theo bài học King Me: điều kiện phải xong trong 2-4 trận và đi cùng hướng build. Thưởng theo depth-v3 là 1 Lõi Tinh Thể, nhưng hai nhiệm vụ dưới đây thưởng bằng **nâng chính nó** (giống Steel Your Heart +200%), cho cảm giác "món đồ của mình lớn lên".

| # | Tên | B | Điều kiện -> thưởng | Khi chưa xong cho | LoL | Gần với |
|---|---|---|---|---|---|---|
| 27 | Tim Lá Sắt | H | Hàng trước chặn tổng 40 sát thương bằng khiên (đếm qua các trận) -> mọi khiên đầu trận và khiên từ mặt shield lên hàng trước x2 (vẫn trong trần +10) | Hàng trước đầu trận +3 khiên | Quest: Steel Your Heart | Vẹn Toàn (#29) cùng mảng phòng thủ |
| 28 | Cúp Vàng Lunacia | T | Kết liễu tổng 20 quái (không tính Egg, token) -> "Cúp Vàng": mọi mặt +1, +1 reroll miễn phí mỗi lượt, Max HP +5 mọi Axie | Không có gì (rủi ro cao, giống Urf's Champion) | Quest: Urf's Champion | - |

### 5.3 Nếu chỉ lấy vài cái cho bump 1

Theo tôi, theo thứ tự đáng làm (đổi cách chơi nhiều nhất trên công sức):
1. **Hòn Đá Mờ (#1)**: gần như không cần hook mới, chỉ là một Lõi trong luồng nhận gọi lại hàm rút Lõi T. Là Lõi được chọn nhiều nhất bên LoL.
2. **Trăng Thứ Hai (#20)**: đổi hẳn cách đánh boss, nối thẳng với nhịp boss 3 lượt và Hold. Cần kiểm action log (lượt EXECUTE thứ hai).
3. **Xuống Trận (#5)** hoặc **Gọt Xúc Xắc (#4)**: hai Lõi đánh đổi lớn cho bậc T, chỉ đổi dữ liệu mặt lúc dựng đơn vị (`apply_mod_faces`).
4. **Mai Lớn Dần / Cánh Nhẹ Dần (#10, #11)**: cặp tích luỹ, cần field run, nhưng là thứ duy nhất làm run dài có cảm giác "lớn dần".
5. **Thợ Săn (#25)** và **Nổ Bào Tử (#19)**: đổi thứ tự đánh và giá trị của việc mất Axie.

Phần hệ thống (5.1) đáng làm nhất: **reroll từng thẻ** và **không hiện lại Lõi đã thấy trong run**. Cả hai rẻ và chặn đúng cái Liam nói (game một chiều nếu chọn đúng cách đánh), vì người chơi không ép ra được bộ Lõi trong đầu.

Mọi số trên chưa sim. Hai build phải thử ngay khi chơi thử: Trăng Thứ Hai + Cất Lửa + Thác Đổ (burst hai lượt có thể xoá boss trong một nhịp), và Vòng Tử Sinh + Hàng Sau Phát Sáng (heal x1.5 rồi 70% thành dmg, tính cả heal tràn; đã chặn vòng lặp với hút máu ở chữ của #22, nhưng vẫn cần đo xem đội Plant/Aqua có thành trội không).

---

## Nguồn

Chính thức (Riot):
- Patch 25.21 (ra mắt ARAM Mayhem): https://www.leagueoflegends.com/en-us/news/game-updates/patch-25-21-notes/
- Patch 26.3 (45 Lõi mới, Bộ Lõi, đường tiến trình, Reroll Vàng, hotfix bộ): https://leagueoflegends.com/en-us/news/game-updates/patch-26-3-notes/
- Dev blog "Augmentmaxxing" (26.12, bỏ Bộ Lõi, Lõi Kỹ Năng, triết lý cân bằng): https://www.leagueoflegends.com/en-gb/news/dev/dev-augmentmaxxing-aram-mayhem/
- Trang hỗ trợ Riot về ARAM Mayhem: https://support.riotgames.com/league-of-legends/events/league-of-legends-aram-mayhem-game-mode

Bài phân tích và báo:
- Inven Global, designer Riot nói về cách làm Lõi: https://www.invenglobal.com/articles/25082/lol-aram-mayhem-reveals-the-secrets-of-augment-development
- Inven Global, cảm nhận người chơi lúc ra mắt: https://www.invenglobal.com/articles/20050/riots-aram-mayhem-mode-delivers-big-fun-but-players-are-asking-for-a-permanent-release
- Earlygame (tiếng Đức), Mayhem có bị "tối ưu hết vui" không: https://earlygame.com/de/news/lol/hat-aram-mayhem-den-spass-aus-sich-selbst-heraus-optimiert
- LoLTheory, cơ chế chọn/reroll/trùng: https://blog.loltheory.gg/aram-mayhem/
- esports.net, tier list và Bộ Lõi: https://www.esports.net/wiki/guides/lol-mayhem-augments-tier-list/
- games.gg, tier list và combo: https://games.gg/league-of-legends/guides/aram-mayhem-augment-tier-list-set-combos/
- Tin xoá 450 Lõi Kỹ Năng (chỉ đọc được qua kết quả tìm kiếm): https://esports.gg/news/league-of-legends/riot-removes-450-ability-augments/ và https://www.ibtimes.com/league-legends-aram-mayhem-cuts-over-450-ability-augments-live-hotfix-3804331
- u.gg về overhaul 26.12 (chỉ qua kết quả tìm kiếm): https://u.gg/lol/news/aram-mayhem-is-getting-a-big-overhaul-in-patch-26-12-with-more-mayhem-content-planned

Thống kê từng Lõi (arammayhem.com, cập nhật 19/10/2026, patch 26.20):
- Danh sách và xếp hạng: https://arammayhem.com/augments/
- Từng Lõi: https://arammayhem.com/augments/transmute-prismatic/ , /shrink-engine/ , /tank-engine/ , /infinite-recursion/ , /quest-steel-your-heart/ , /back-to-basics/ , /goliath/ , /draw-your-sword/ , /mad-scientist/ , /phenomenal-evil/ , /transmute-chaos/ , /escape-plan/ , /king-me/ , /tooth-fairy/ , /ominous-pact/ , /circle-of-death/ , /dive-bomber/ , /final-form/ , /overflow/ , /slap-around/ , /echo-cast/ , /quest-urfs-champion/ , /giant-slayer/ , /celestial-body/ , /dont-change-the-channel/ , /combusting-interest/ , /glass-cannon/ , /mind-to-matter/ , /homeguard/ , /big-brain/ , /bread-and-butter/ , /get-excited/ , /spin-to-win/ , /vulnerability/ , /ultimate-revolution/
- Patch 25.23 (Đe chỉ số, đổi phân bố bậc): https://arammayhem.com/patch/25-23/
- Patch 26.13 (sửa luật hiện Lõi Kỹ Năng, nerf/buff): https://arammayhem.com/patch/26-13/
- Lõi Kỹ Năng (bản xem trước): https://arammayhem.com/ability-augments/
- Bài tier Lăng Kính (ý kiến một người viết): https://arammayhem.com/articles/prismatic-augment-tier-list/

Cộng đồng:
- Bản lưu thread Reddit về hotfix 26.3 (Poro Blaster, trượt Lõi): https://reddit.sentinel-team.org/posts/1qx145b/snapshots/2026-02-06T04%3A31%3A18.39767Z

Không đọc được (chặn bot): wiki.leagueoflegends.com (ARAM: Mayhem và trang Augments), mobalytics.gg, sheepesports.com, u.gg. Hiệu ứng vài Lõi Võ Đài cũ (Hubris, Pandora's Box, Tap Dancer) tôi lấy từ mô tả ngắn trên tier list, chưa đối chiếu số.
