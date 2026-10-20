# Nghiên cứu: Lõi trong Võ Đài (LoL Arena) và Lõi Nâng Cấp + Cổng của Đấu Trường Chân Lý (TFT)

Ngày 20/10/2026. Người viết: agent nghiên cứu (web). Phần ARAM Hỗn Loạn do agent khác làm, xem `design/research/lol-aram-mayhem-augments.md`; ở đây chỉ nhắc tới ARAM khi nó giải thích được chuyện của Arena/TFT.

Quy ước: "Lõi" = augment. Bậc LoL/TFT là Bạc / Vàng / Lăng Kính, tương ứng Rêu / Hổ Phách / Tinh Thể của Axie Dice. Chỗ nào chỉ dựa vào hiểu biết chung của tôi (không đọc được trang gốc) thì ghi **(trí nhớ)**. Nhiều trang wiki và Mobalytics chặn bot (403), nên một phần số liệu Lõi lấy từ bài tổng hợp, không phải bản gốc.

## 0. Đọc nhanh

1. **Bộ Lõi có thưởng bộ thật ra không có trong Arena.** Nó là của ARAM Hỗn Loạn (26.3), và Riot đã bỏ ở 26.12 vì nó làm mọi ván ra cùng một kiểu: chọn Lõi nào cũng dẫn về cùng hiệu ứng bộ, người chơi chọn vì bộ chứ không vì tướng. Đây là cảnh báo trực tiếp cho bộ Lõi 2.6 của Axie Dice.
2. **Ngẫu nhiên theo ván, không theo người.** Cả Arena lẫn TFT cho mọi người trong trận cùng một bậc ở cùng một lượt chọn. Dev TFT viết thẳng: biến động nên đến giữa các ván, không phải giữa các người chơi. Với game một người như Axie Dice thì đọc là: bậc theo mốc, không để người chơi "kéo" bậc lên bằng cách chơi an toàn.
3. **Luật cả ván (Cổng TFT, Khách Mời Arena) là thứ được khen nhất**, Riot giữ vĩnh viễn. Bài học kèm theo: luật nên là "rắc thêm chút gia vị" chứ không bẻ cong cả game; luật phức tạp (The Sump, House Lightshield, Noxkraya) bị chê. Nhưng luật quá nhạt thì người chơi cũng chán, họ muốn luật mạnh ngay từ đầu.
4. **Chống lối trội không bằng nerf mà bằng cách không cho lặp build:** đồ mạnh nhất (Lăng Kính) không mua được, chỉ được đưa ra ngẫu nhiên; reroll dùng chung một túi cho Lõi và đe; một Lõi không hiện quá 4 lần mỗi trận; Lõi không hợp tướng không bao giờ hiện. TFT bỏ hệ Legends vì người chơi giỏi tối ưu hết, 5-7/8 người chọn cùng một Legend.
5. **Arena mùa 2 (2026) cho Lõi lên cấp và thay Lõi**: đầy 4 ô thì lần chọn sau là "nâng cấp một Lõi đang có" hoặc "bỏ một Lõi, lấy Lõi cao hơn một bậc". Mục đích Riot nói rõ: để người chơi bỏ được Lõi không còn hợp. Đây là thứ Axie Dice nên mượn thay cho bộ Lõi.

---

## 1. Võ Đài (Arena 2v2v2v2, nay có cả 3x6 và 4v4)

### 1.1 Khung một trận

- 8 đội x 2 người (từ 14.9 tăng từ 4 lên 8 đội). Mỗi vòng: mua sắm ngắn, rồi đánh với một đội. Đội thua mất "máu đội" (15 ở vòng 1-4, 20 ở 5-8, 30 ở 9-12, 35 ở 13-16). Máu về 0 là bị loại.
- Lịch theo trang hỗ trợ Riot (bảng hơi vỡ khi đọc, nhưng cột Lõi rõ): **chọn Lõi ở vòng 1, 3, 5, 7, 10, 12, 14, 16+**; vòng 2 có **bỏ phiếu Khách Mời** và **một món Lăng Kính**; vòng 8 bỏ phiếu Khách Mời lần 2; các vòng chẵn còn lại cho 2500 vàng.
- Bài hướng dẫn 2026 (dodge.gg, loltheory) ghi lịch khác: chọn ở vòng 1, 5, 8, 11, cộng một đe Lăng Kính miễn phí vòng 3 và đe chỉ số Lăng Kính chắc chắn ở vòng 7 và 10. Hai nguồn lệch nhau vì Riot đổi lịch theo mùa. Điểm ổn định: **4-8 lần chọn mỗi trận, xen giữa là vòng tiền/đồ, không có hai lần chọn liền nhau.**

### 1.2 Bậc và reroll

- Ba bậc Bạc / Vàng / Lăng Kính, "cường độ tăng dần".
- **Bậc của một lượt chọn là ngẫu nhiên nhưng cả trận giống nhau**: khi đến lượt Lăng Kính thì cả 16 người cùng chọn Lăng Kính. Reroll giữ nguyên bậc.
- Ba thẻ trong một lượt luôn cùng bậc.
- Reroll: khoảng 4 lần cơ bản mỗi trận (dodge.gg), thêm 1 từ cấp Danh Vọng 5, thêm nữa nếu chơi "Bravery" (tướng ngẫu nhiên). Từ 14.9, **reroll Lõi dùng chung túi với reroll đe**, nên người chơi phải chọn tiêu reroll vào đâu. Riot gọi đây là "đánh liều hay lấy chắc".
- Lọc: Lõi không hợp tướng không hiện (Lõi sức mạnh phép không ra cho tướng không dùng phép). **Một Lõi không xuất hiện quá 4 lần trong cả trận** (giữa 16 người).
- Tối đa thường là 4 Lõi; có nguồn ghi 6 (thêm từ Khách Mời và hiệu ứng đặc biệt).

### 1.3 Mùa 2 năm 2026: Lõi có cấp, thay Lõi, vòng chế tạo

Theo dev blog "Leveling Up Arena" (26.9):
- Nhiều Lõi có 3 cấp. Lên cấp thì mạnh hơn, đến cấp 3 thì đổi dạng, có thêm hiệu ứng mới. Ví dụ Fan the Hammer bắn thêm đạn mỗi cấp.
- **Sau khi đã có 2 Lõi lên cấp được, các lượt chọn sau có thể ra "nâng cấp Lõi X" thay cho Lõi mới.**
- Đầy ô (thường 4): lượt chọn chỉ còn hai kiểu: nâng cấp một Lõi đang có, hoặc **bỏ một Lõi để lấy Lõi cao hơn một bậc**.
- Vì vậy lượt chọn Lõi xuất hiện dày hơn trước.
- **Vòng 8 là vòng chế tạo:** chọn hoặc thêm 1 ô Lõi, hoặc bỏ 1 Lõi để nâng cấp một Lõi còn lại.
- Riot nói lý do: cho người chơi "bỏ được Lõi không còn phục vụ mục đích của mình".

### 1.4 Bộ Lõi: Arena không có, ARAM có rồi bỏ

Đề bài hỏi bộ Lõi trong Arena. Tôi không tìm thấy nguồn nào nói Arena từng có bộ Lõi. Bộ (trait/set) là của **ARAM Hỗn Loạn**, ra ở 26.3, bỏ ở 26.12. Bài Inven gọi nhầm là "Arena". Chi tiết ở file ARAM; ở đây chỉ chép lý do Riot bỏ, vì nó đụng thẳng mục 2.6 của `depth-v3-design.md`:

1. **Build bị đồng hoá:** các Lõi trong một bộ dù khác loại vẫn dẫn về cùng một trải nghiệm. Ví dụ bộ Pháo Hoa (Firecracker): chọn món nào rồi cuối cùng cũng là bắn pháo hoa ra xung quanh.
2. **Ván nào cũng giống ván nào:** Lõi thuộc bộ hiện nhiều nên nhịp ván lặp lại.
3. **Mất bản sắc tướng:** thưởng bộ mạnh quá, người chơi chọn Lõi vì bộ chứ không vì nó hợp tướng.
4. **Lõi lẻ hết hấp dẫn:** thưởng bộ nổi bật quá làm từng Lõi riêng nhạt đi.

Patch note 26.12 viết gọn hơn: High Roller và Archmage được yêu thích, nhưng hệ bộ "làm giảm sự đa dạng của lựa chọn Lõi". Riot giữ phần hay bằng cách biến vài thưởng bộ thành Lõi lẻ, và thay bằng **Lõi kỹ năng** (nâng một kỹ năng cụ thể của tướng) và **Lõi nhiệm vụ nhiều nấc** (tiến hoá vài lần).

Ba nguyên tắc cân bằng Riot công bố cùng lúc: mỗi tướng phải có một build mạnh để nhắm tới; build đó **không phải ván nào cũng làm được**; một build mạnh **không được tự quyết định cả trận**.

### 1.5 Lõi nhiệm vụ

- Dạng chung: "Nhiệm vụ: làm X. Thưởng: Y mạnh". Ví dụ (esports.net, Arena):
  - **Angel of Retribution** (Vàng): hồi máu hoặc chặn 2500 sát thương cho đồng đội. Xong thì đánh thường gây thêm sát thương phép theo sức mạnh hồi máu/khiên. Biến người hỗ trợ thành người gây sát thương.
  - **Steel Your Heart**: có món Heartsteel và đạt 325 máu cộng thêm, thưởng máu và hồi máu.
  - **Urf's Champion**: 10 lần hạ gục tham gia, thưởng Golden Spatula (một món rất mạnh).
- Mùa 2 thêm **Tooth Fairy** (gây nhiều sát thương trong thời gian ngắn thì nhận răng, răng cộng xuyên giáp/kháng phép, cộng dồn) và **Support Main** (hồi/khiên đủ thì hồi/khiên của mình còn cho thêm hồi máu theo thời gian).
- Từ 26.12 (ARAM, và có vẻ cả Arena), nhiệm vụ có **nhiều nấc**: xong nấc 1 nhận một phần, làm tiếp lên nấc 2, 3. Lý do: một ngưỡng duy nhất thì hoặc là quá dễ hoặc là không bao giờ xong.
- **Phenomenal Evil** là kiểu nhiệm vụ không có đích: mỗi lần trúng kỹ năng cộng vĩnh viễn một ít sức mạnh phép. **Stackosaurus Rex** nhân các Lõi cộng dồn kiểu đó.

### 1.6 Đe và đồ Lăng Kính

- **Đồ Lăng Kính không mua được.** Chỉ được đưa ra ở vòng định sẵn hoặc qua đe Lăng Kính (4000 vàng, chọn 1 trong 3 ngẫu nhiên). Riot (bài "Arena Round Three", 14.9): làm vậy để người chơi **không lặp được cùng một build mỗi ván**, thưởng cho thích nghi thay vì đi theo kịch bản.
- Lead designer Phroxzon nói thẳng: người chơi không được toàn quyền với đồ Lăng Kính; ai roll được món tốt thì xếp hạng trung bình sẽ cao hơn. Người chơi giỏi vẫn thắng được với món không lý tưởng.
- **Đe huyền thoại** (2000-2250): chọn lớp (đấu sĩ, pháp sư, xạ thủ...), ra 3 món ngẫu nhiên trong lớp đó. Rẻ hơn mua thẳng. Người chơi chọn hướng, game chọn món cụ thể.
- **Đe chỉ số** (750): 3 lựa chọn chỉ số thô, có bản Bạc/Vàng/Lăng Kính. Để tiêu vàng thừa. Đây là chỗ duy nhất Arena để cộng số thuần.
- Đe reroll được (dùng chung túi reroll với Lõi).

### 1.7 Luật cả trận: Khách Mời Danh Dự, Sự kiện, sân

**Khách Mời Danh Dự** (từ 25.05) là bản Arena của Cổng TFT. Bỏ phiếu 2 lần, trước vòng 2 và vòng 8. Mỗi lần hiện 3 khách ngẫu nhiên, khách thắng đổi luật cho đến hết trận. Đợt đầu có 21 khách (13 cho lần 1, 7 cho lần 2, Riven ra được cả hai). Danh sách (esports.net, loltheory):

| Khách | Lúc | Luật |
|---|---|---|
| Darius | vòng 2 | Mọi đội mất 50 máu đội ngay; mỗi khi có đội bị loại, các đội còn lại hồi 5 |
| Vladimir | vòng 2 | Mọi người nhận cùng một Lõi ngẫu nhiên |
| Swain | vòng 2 | Nhặt quạ trong trận; số quạ quyết định bậc các lượt Lõi sau |
| Katarina | vòng 2 | Mọi người +5 reroll |
| Rell | vòng 2 | Đe Lăng Kính rẻ hơn 1000 |
| Xin Zhao | vòng 2 | Dưới 60 máu đội: nhận đe chỉ số Vàng; lần đầu sắp bị loại: đe Lăng Kính |
| Ambessa | vòng 2 | Hiến máu đội qua vài vòng, đổi lại một Lõi thưởng theo lượng máu đã hiến |
| Briar | vòng 2 | Thua mất thêm 5; thắng khi đang sắp bị loại thì hồi 15 |
| Alistar | vòng 2 | Lần đầu bị loại thì về 1 máu thay vì chết |
| Kled | vòng 2 | Đánh xong được một phép phá các trận khác đang diễn ra |
| Draven | vòng 2 | Đe chỉ số dễ ra bậc cao, nhất là khi đang chuỗi thắng |
| Riven | 2 hoặc 8 | Không đổi luật gì |
| Mel | vòng 8 | Thêm 4 cổng dịch chuyển trên sân mỗi trận |
| Elise | vòng 8 | Hồi sinh thành kén, đồng đội phải đập kén |
| Mordekaiser | vòng 8 | Mỗi trận một người mỗi đội bị kéo vào cõi chết (1v1) |
| Samira | vòng 8 | Ai đánh trúng trước được 2 bình nước (4 nếu đang chuỗi thắng) |
| Sion | vòng 8 | Vòng lửa tới sớm 15 giây rồi co nhanh, trôi đi |
| Talon | vòng 8 | Mỗi đội một người +20% sát thương nhưng ai hạ người đó được 250 vàng |
| Cassiopeia | vòng 8 | Mỗi vòng mỗi đội mất 5 máu (không loại được ai) |
| LeBlanc | vòng 8 | Mỗi 25 giây mọi người tàng hình 3 giây |
| Sahn Uzal | vòng 8 | Không còn hồi sinh |
| Trundle | vòng 8 | Khoá đồ huyền thoại cả trận, chỉ còn đe huyền thoại |

Mùa 2 thêm hơn 20 khách mới (Kayle, Fiddlesticks, Yone, Ornn, Nocturne...), tạm tắt các khách cũ để xoay vòng. 26.12 bỏ Swain khỏi vòng 2.

Đáng để ý: **Swain, Ambessa, Katarina, Vladimir là luật đổi chính hệ Lõi** (bậc theo thành tích, bán máu lấy Lõi, nhiều reroll, Lõi chung). Luật run của Axie Dice nên có cả loại này.

**Sự kiện (mùa 2):** mỗi patch một thể thức: 3x6 (6 đội x 3 người, để có tuyến trên/tuyến dưới), Bravery (chọn tướng ngẫu nhiên, đổi lại thêm reroll), Swift (2 đội x 4, gặp lại nhau nhiều). Riot nói sự kiện để "tự nhiên tạo thay đổi meta".

**Sân:** vòng lửa co lại, hoa năng lượng (đánh vỡ được khiên/hồi/mana/giảm hồi chiêu), Bulwark Blossom (thưởng gấp đôi khi bị đánh đông), trụ đổ, bom lăn, cầu hoa có lúc. Đây là biến động trong từng trận, không phải luật run, nhưng có một ý đáng mượn: **thưởng lật kèo gấp đôi khi đang yếu thế**.

**Lõi "Lời Nguyền"** (curse augments): một nhóm Lõi Arena bị tắt dịp nghỉ lễ. Riot nói chúng "hơi quá mạnh với vài tướng" nhưng xếp hạng trung bình lại thuộc loại thấp nhất, và tạo đội hình câu giờ thống trị. Bài học: Lõi có hai mặt (mạnh với ít người, tệ với đa số) vừa khó cân bằng vừa tạo lối chơi khó chịu.

**Lõi bị cắt trước khi ra** (AMA của dev): Shiitake Happens (nấm chỉ chủ thấy, ai cũng giẫm được) gây thế giằng co không ai dám vào; Pass-a-Fist (bỏ đánh thường, chia 50% công cho đồng đội) quá phụ thuộc cặp tướng và người chơi không hiểu chuyện gì đang xảy ra. Bài học: Lõi làm người chơi không hiểu vì sao mình thắng/thua thì cắt.

### 1.8 Lõi Arena tiêu biểu (tóm bằng lời tôi)

Cột "Kiểu": **Luật** = thêm cơ chế/đổi cách chơi, **Đánh đổi** = được cái này mất cái kia, **Trễ** = trả sau, **Số** = cộng chỉ số. Lõi có nguồn đọc được ghi (n), còn lại là (trí nhớ), số cụ thể có thể lệch theo patch.

| # | Lõi | Bậc | Làm gì | Kiểu |
|---|---|---|---|---|
| 1 | Back to Basics | Lăng Kính | Mất chiêu cuối; các chiêu thường mạnh hơn và hồi nhanh hơn (trí nhớ) | Đánh đổi |
| 2 | Blade Waltz | Lăng Kính | Chiêu cuối bị thay bằng một chuỗi lướt chém không chọn được làm mục tiêu (n: 26.12 có sửa) | Luật |
| 3 | Ultimate Roulette | Bạc/Vàng | Mỗi lần dùng chiêu cuối là một chiêu cuối ngẫu nhiên của tướng khác (trí nhớ) | Luật |
| 4 | Draw Your Sword | Lăng Kính | Biến tướng đánh xa thành cận chiến, đổi lại chỉ số lớn; 26.12 cho thưởng theo tầm đánh gốc (n) | Đánh đổi |
| 5 | Goliath | Lăng Kính | +35% máu +15% sát thương, nhưng người to ra, dễ trúng đòn (n) | Đánh đổi |
| 6 | Giant Slayer | Lăng Kính | Người nhỏ lại, nhanh hơn, đánh thêm sát thương vào kẻ to hơn (n) | Luật |
| 7 | Mad Scientist | Bạc/Vàng | Mỗi vòng ngẫu nhiên: to (trâu) hoặc nhỏ (nhanh, đau) (trí nhớ) | Luật |
| 8 | Nesting Doll | Lăng Kính | Thêm vài lần hồi sinh, mỗi lần nhỏ và yếu hơn, hồi sinh đẩy lùi địch (n) | Luật |
| 9 | Dive Bomber | Vàng | Chết thì phát nổ tại chỗ gây sát thương lớn (trí nhớ) | Luật |
| 10 | Self Destruct | Lăng Kính? | Đầu vòng gắn bom lên mình, sau 13 giây nổ (n: 15 → 13 giây ở 26.12) | Luật |
| 11 | Contract Killer | Bạc | Mỗi vòng đánh dấu một địch; hạ nó thì thêm vàng và đội nó mất thêm máu (n) | Luật |
| 12 | Center of the Universe | Lăng Kính | Ba ngôi sao quay quanh người, chạm ai gây sát thương (n) | Luật |
| 13 | Spellwake | Lăng Kính | Chiêu trúng để lại vệt, vệt nổ sau một lúc (n) | Luật |
| 14 | Jeweled Gauntlet | Lăng Kính | Chiêu được chí mạng (n) | Luật |
| 15 | Typhoon / Fan the Hammer | Vàng | Đánh/chiêu bắn thêm tia sang địch gần; mùa 2 có cấp, mỗi cấp thêm đạn (n) | Luật |
| 16 | Sonic Boom | Bạc | Buff/hồi/khiên cho đồng đội thì gây sát thương chuẩn và làm chậm địch quanh đó (n) | Luật |
| 17 | Holy Fire | Vàng | Hồi/khiên thì bắn tên lửa gây bỏng (n) | Luật |
| 18 | It's Killing Time | Vàng | Chiêu cuối đánh dấu mọi địch, tích sát thương rồi nổ sau (n) | Luật |
| 19 | Erosion | Bạc | Mỗi lần gây sát thương bào giáp/kháng, tối đa 30% (n) | Luật nhẹ |
| 20 | Slap Around | Bạc | Mỗi lần khống chế địch cộng dồn công/phép trong vòng (n) | Luật |
| 21 | Phenomenal Evil | Vàng | Mỗi chiêu trúng cộng vĩnh viễn sức mạnh phép (n) | Trễ |
| 22 | Wisdom of Ages | Lăng Kính | +1 cấp ngay, rồi cứ 2 vòng +1 cấp (n) | Trễ |
| 23 | Transmute: Prismatic / Gold / Silver / Chaos | nhiều | Đổi lượt chọn này lấy Lõi bậc cao hơn hoặc Lõi ngẫu nhiên (n: có Transmute Silver ở mùa 2) | Liều |
| 24 | Angel of Retribution | Vàng | Nhiệm vụ hồi/chặn 2500, thưởng biến hồi máu thành sát thương (n) | Nhiệm vụ |
| 25 | Urf's Champion | ? | Nhiệm vụ 10 lần hạ gục, thưởng một món siêu mạnh (n) | Nhiệm vụ |
| 26 | Bread and Butter | Vàng | +150 hồi chiêu cho riêng chiêu Q (n) | Số, nhưng hướng chơi |
| 27 | Dual Wield / Ethereal Weapon | ? | Đòn đánh thêm hiệu ứng; có cấp, 26.12 thêm cấp 3 cho Ethereal Weapon (n) | Luật có cấp |
| 28 | Witchful Thinking / Blunt Force | Bạc | +70 phép / +15% công (n) | Số |
| 29 | Thread the Needle / Recursion | Vàng | +25% xuyên giáp / +60 hồi chiêu (n) | Số |

Nhận xét: phần lớn Lõi Lăng Kính là **Luật** hoặc **Đánh đổi**, Lõi **Số** chủ yếu ở Bạc/Vàng. Nhiều Lõi hay nhất gắn với **cái chết, kích cỡ, tầm đánh, chiêu cuối** tức là gắn vào cái tướng vốn có rồi bẻ nó đi. Bên Axie Dice, thứ tương đương là: mặt part (mouth/horn/back/tail/eyes/ears), hàng trước/sau, Hold, Kết, mana, Egg, cái chết của Axie.

---

## 2. Đấu Trường Chân Lý (TFT)

### 2.1 Khi nào chọn, bậc ra sao

- Lõi ra từ Set 6 (Gizmos & Gadgets), thành vĩnh viễn từ Set 8. **Ba lượt chọn: 2-1, 3-2, 4-2** (đầu giai đoạn 2, 3, 4). Mỗi lượt 3 thẻ, chọn 1, giữ đến hết ván. Người khác không thấy bạn chọn gì.
- **Ba thẻ trong một lượt cùng bậc, và cả 8 người trong trận cùng bậc ở lượt đó** (Mobafire, cùng cách Riot ghi cho Arena). Ví dụ nếu 2-1 là Lăng Kính thì cả bàn đều chọn Lăng Kính.
- Bậc **không độc lập giữa các lượt**: tỉ lệ ở 3-2 và 4-2 phụ thuộc bậc đã ra. Số cộng đồng đo (Set 16, tftodds):

| Bậc | 2-1 | 3-2 | 4-2 |
|---|---|---|---|
| Bạc | 28% | 35% | 6% |
| Vàng | 62% | 45% | 74% |
| Lăng Kính | 10% | 20% | 20% |

  Ví dụ một chuỗi: Vàng-Vàng-Vàng khoảng 22%. Bạc-Bạc-Vàng 5%. Lăng Kính ở 2-1 thì lượt sau ít khi Lăng Kính nữa. Tức là game **điều phối tổng sức mạnh cả ván**, ván nào cũng có "một chỗ cao" chứ không phải xổ số độc lập. Chính bảng phân phối được viết sẵn thành vài chục chuỗi có xác suất (18 chuỗi), không phải ba lần tung riêng.
- Lõi kinh tế bị khoá theo lượt: Rich Get Richer chỉ ở 2-1, bản + chỉ ở 3-2 (Mort, Set 7). Lõi tiền chỉ ra sớm, lúc tiền còn có thời gian sinh lãi.

### 2.2 Reroll

- Từ 13.12 (Set 9): **mỗi thẻ reroll riêng được một lần** ở mỗi lượt chọn. Tức là giữ thẻ tốt, đổi thẻ xấu. Trước đó là reroll cả bộ ba.
- Lõi Anh Hùng (Set 8) có túi reroll riêng 4 lần.

### 2.3 Ba loại Lõi theo vai trò (tôi gom lại, nhiều tên lấy từ trí nhớ)

**a) Định hướng đội hình** (nói cho bạn biết nên đi đội nào):
- +1 tộc/hệ: Heart (+1 cho hệ), Crown (+1 và một tướng), Soul. Dev Set 9: không cho +1 vào các hệ dọc lớn (Noxus, Ionia) để Lăng Kính của chúng vẫn hiếm. Từ Set 10: chỉ bao giờ +1 cho một hệ từ Lõi, không cộng chồng.
- Ấn (emblem): biến một tướng thành thêm một hệ.
- Lõi Anh Hùng (Set 8): Lõi gắn vào một tướng cụ thể, ví dụ biến tướng đỡ đòn thành chủ lực. Dev khen vì tạo lối chơi carry mới cho Warwick, Sett, Swain.
- Built Different: tướng **không kích hoạt hệ nào** được máu và tốc đánh. Ép chơi ngược lại tư duy "gom hệ".
- Featherweights: tướng 1-2 vàng nhanh hơn. Ép đội reroll tướng rẻ.
- Exiles: tướng không có ai đứng kề được khiên. Ép xếp đội tản ra.
- Long Distance Pals: hai tướng nối với nhau, càng xa càng được thưởng (trí nhớ).

**b) Kinh tế** (đổi sức mạnh bây giờ lấy tiền/tài nguyên về sau):
- Rich Get Richer: tiền ngay, trần lãi tăng.
- Trade Sector: mỗi vòng một lần làm mới cửa hàng miễn phí.
- Hedge Fund, Spoils of War, Golden Ticket (đổi cửa hàng có cơ hội được miễn phí), Patient Study (nhận kinh nghiệm theo thời gian).
- Level Up!: mua kinh nghiệm được nhiều hơn.
- Tiniest Titan: chủ tướng chạy nhanh, hồi máu chủ tướng, có bản + thêm 8 vàng (n, Set 9.5).

**c) Liều** (trần cao, sàn thấp, hoặc có điều kiện):
- Cruel Pact: mua kinh nghiệm bằng máu thay vì vàng.
- Blood Money: mất máu thì được vàng.
- Pandora's Items: mỗi vòng đồ (thành phần) trên hàng chờ bị đổi ngẫu nhiên.
- Cursed Crown: +2 ô đội, nhưng thua thì mất gấp đôi máu (trí nhớ, Set 9).
- Ascension: sau 15 giây giao tranh, cả đội đánh mạnh hơn nhiều. Thưởng đội trâu, phạt đội chết sớm.
- Lõi "chờ": vài vòng sau mới trả, phải sống sót tới lúc đó.

Metabot tóm đúng tinh thần: Bạc là lợi ích khiêm tốn gần như chắc chắn; Lăng Kính "là trần, không phải bảo đảm", thường đòi điều kiện hoặc phải dồn hết vào.

### 2.4 Legends (Set 9): cho người chơi chọn trước, rồi bỏ

- Người chơi chọn một "Legend" trước trận. Legend quyết định **thẻ ngoài cùng bên trái** ở mỗi lượt chọn (thẻ cố định theo phong cách: Urf thiên về ấn và hệ chéo, Caitlyn thiên về khởi đầu sớm, Pengu thiên về kinh tế/thua chuỗi). Thẻ Legend ở 2-1 bằng sức thẻ thường, ở 3-2 và 4-2 hơi yếu hơn, làm phương án dự phòng.
- Dev khen: người chơi chọn được phong cách trước, người mới đi theo hướng dẫn dễ hơn.
- Dev chê, và là lý do bỏ: ở rank cao, tối ưu nuốt hết. Chỉ cần tin (có thể sai) rằng Ornn hơn chút xíu là bàn 8 người có 5-7 Ornn. **Biến động mà người chơi lâu năm muốn bị mất.** Lõi được bảo đảm còn làm cân bằng khó hơn (Draven, Bard bị buff quá tay), cộng với Cổng thì có tổ hợp mạnh không đỡ được (Ezreal + Ecliptic Vaults lãi chồng lãi).
- Bài học trực tiếp cho Axie Dice: **không cho người chơi chọn trước "hướng Lõi" một cách chắc chắn**. "Thẻ 1 theo hướng đang đi" ở 2.2 của depth-v3 là bản nhẹ của Legend, chấp nhận được vì nó theo Lõi đã có chứ không theo lựa chọn ngoài trận.

### 2.5 Cổng / Portal (luật vùng, đầu ván, cả bàn chung)

**Cách chọn (Set 9, 13.12):** thay vòng băng chuyền mở màn. Giữa bàn hiện **3 Cổng**, 8 người đi chủ tướng vào cổng mình muốn để bỏ phiếu. Không phải ai nhiều phiếu thắng: game rút ngẫu nhiên theo tỉ lệ phiếu (7 phiếu Noxus, 1 phiếu Piltover thì 7/8 ra Noxus). Có khoảng 30 Cổng, một số hiện thường hơn số khác. Set 9.5 thêm Cổng mới và **Cổng ghép** (hai Cổng chạy cùng lúc, chỉ ở chế độ thường). Set 10 giữ Cổng nhưng mở đầu bằng Cổng nhẹ, rồi thừa nhận sai: người chơi muốn Cổng mạnh ngay.

**Danh sách tiêu biểu** (Set 9, tracker.gg + Riot):

| # | Cổng (vùng) | Luật | Đẩy người chơi sang hướng |
|---|---|---|---|
| 1 | Jayce's Workshop (Piltover) | Mọi lượt Lõi ván này đều Lăng Kính | Ván "điên", build mạnh sớm |
| 2 | Stillwater Hold (Piltover) | Không có Lõi cả ván | Ván "thuần", kỹ năng đọc bàn |
| 3 | The University (Piltover) | Lượt Lõi đầu có một thẻ Lăng Kính | Một cơ hội nhảy vọt sớm |
| 4 | Ecliptic Vaults (Zaun) | Mỗi lượt chọn Lõi được 4 vàng cho mỗi Lõi đang có | Lấy Lõi kinh tế sớm |
| 5 | Glasc Industries (Zaun) | Mỗi món đồ hoàn chỉnh ghép ra được 3 vàng | Ghép đồ sớm thay vì giữ thành phần |
| 6 | The Sump (Zaun) | Không có lãi; từ 2-1 ai cũng +3 vàng mỗi vòng | Tiêu tiền ngay, bỏ chơi tích lãi |
| 7 | Bandle Cafeteria (Bandle) | Được xẻng ở 2-1; tướng cầm đồ cho đồng đội kề bên ăn bánh, cộng máu vĩnh viễn | Ấn sớm, xếp đội cạnh nhau |
| 8 | Scuttle Puddle (Bandle) | Mọi vòng quái thành cua, rơi nhiều đồ hơn | Ván giàu đồ |
| 9 | Yordle Pordles (Bandle) | Vòng 1 và 5 mỗi giai đoạn tặng tướng đắt | Đội hình linh hoạt |
| 10 | Yuumi's Zoom (Bandle) | Giao tranh còn 20 giây trước khi tăng tốc, dễ hoà | Đội hình đánh nhanh |
| 11 | House Lightshield (Demacia) | Vương miện +40 công +400 máu ở 2-1; người đội chết là thua trận đó | Bảo vệ một "vua" (bị chê là quá phức tạp) |
| 12 | Petricite Forest (Demacia) | Tướng to hơn 15%, +150 máu; % máu và AoE mạnh lên | Trận dài, đội trâu |
| 13 | Immortal Bastion (Noxus) | Cờ chiến: tướng kề bên +20% tốc đánh, khiên 10% máu | Xếp đội quanh một ô |
| 14 | Noxkraya (Noxus) | Mỗi lượt Lõi sinh một ô sân ngẫu nhiên, đứng đó được đồ | Xếp vị trí theo ô (bị chê phức tạp) |
| 15 | God-Willow's Grove (Ionia) | Một ô hàng chờ tính hệ như đứng trên sân | Thêm một hệ |
| 16 | The Dreaming Pool (Ionia) | Mỗi giai đoạn tặng một tướng hợp hệ đang có | Đi dọc một hướng |
| 17 | Thresh's Sanctum (Shadow Isles) | Tướng chết rơi hồn; mỗi 40 hồn được đồ | Thưởng cho trận đổ máu |
| 18 | Yorick's Graveyard (Shadow Isles) | Ai bị loại thì đồ của họ thành kho cho cả bàn | Lật kèo cuối ván |
| 19 | Warlord's Palace (Shurima) | Vòng quái 4-7 thành kho đồ, reroll không giới hạn mỗi lần 2 vàng | Để dành vàng cho một khoảnh khắc |
| 20 | Targon Prime (Targon) | Khi chủ tướng xuống 40 máu, nhận phước | Chơi thua có chủ đích |
| 21 | The Summit (Targon) | Từ giai đoạn 2, mỗi giai đoạn tặng bản sao tướng | Đội 3 sao |
| 22 | The Lavender Sea (Void) | Ô hư không đổi chỗ sau mỗi vòng: hai hàng trước giảm 20% sát thương nhận, hai hàng sau +20% sát thương | Xếp lại mỗi vòng |
| 23 | Unstable Rift (Void) | Một món đồ hoàn chỉnh, mỗi vòng biến thành món ngẫu nhiên khác | Tận dụng đồ đang có |
| 24 | The Rupture (Void) | Dịch chuyển tới một Cổng ngẫu nhiên khác | Cổng "hộp quà" |

**Bài học Riot tự rút** (dev blog Runeterra Reforged Learnings, Remix Rumble Learnings):
- Cổng "rocked": người chơi thích sự khác biệt giữa các ván, và Cổng giải quyết được vòng băng chuyền mở màn (một bài kiểm tra tốc độ tay vô vị). Cổng giờ là phần vĩnh viễn "như Lõi".
- Cổng phức tạp bị chê: House Lightshield, The Sump, Noxkraya. Người chơi muốn **game gốc cộng chút gia vị**, không muốn bẻ cong cách xếp đội và cách ra quyết định. Kết luận này khớp với Galaxies (Set 3, cơ chế luật cả ván trước đó).
- Nhưng Set 10 mở đầu bằng Cổng nhẹ thì bị chê ngược: người chơi muốn Cổng mạnh ngay. Vậy cái cần là **mạnh nhưng không phức tạp**: một luật dễ hiểu, tác động rõ.
- Cổng + Lõi + Legend + kỹ năng làm sức mạnh trung bình mỗi ván vượt dự tính (3 sao tướng 4-5 vàng thành chuyện thường), phải tăng cấp tối đa lên 10. Tức là **luật run cộng dồn với Lõi, phải cân lại độ khó nền**.
- Cổng + Lõi tạo vài tổ hợp trần quá cao. Cổng nên ảnh hưởng cách chơi hơn là nhân thẳng sức mạnh.
- Dev Remix Rumble: Cổng làm phần mở đầu "giống bắt đầu một run roguelike". Và: biến động nên **giữa các ván, không giữa các người chơi**; mọi người cùng chịu một luật.

### 2.6 Encounters (Set 11): luật ngẫu nhiên nhỏ, nhiều lần trong ván

- Thay Cổng ở Set 11. Hơn 80 sự kiện, mỗi ván 5 cái (từ 14.14), mỗi cái có độ hiếm riêng. Ví dụ: Ahri ban phước cả bàn (+150 máu hoặc +18 phép hoặc +15% công cho mọi tướng cả ván), Aatrox cho chọn đe thành phần / vàng / hồi máu, Amumu đổi băng chuyền thành toàn tướng 3 vàng 2 sao, có sự kiện đổi bậc Lõi (bảng tỉ lệ Lõi ghi rõ sự kiện ghi đè phân phối bình thường).
- Set 12 không giữ Encounters. Không tìm được bài dev giải thích vì sao. Tôi đoán (không có nguồn): 5 sự kiện nhỏ mỗi ván ít đọng lại hơn một Cổng lớn.

---

## 3. Vì sao nghiện, cộng đồng khen gì chê gì

### 3.1 Khen

- **Ván nào cũng khác.** Mort (Set 7): Lõi đem lại "biến động giữa các ván" và là lý do người chơi quay lại. Dev Arena: Lõi là lý do lớn nhất Arena được yêu thích. Cổng được gọi là một trong những "greatest hits" của TFT.
- **Khoảnh khắc "roll trúng".** Thấy ba thẻ Lăng Kính, hoặc đúng thẻ còn thiếu cho build, là cú hích dopamine. Thua thì người chơi tự nhủ "ván sau roll khác". Đây là chất "thêm một ván".
- **Thử thứ không làm được ở chế độ khác.** Riot đặt mục tiêu Arena: build cho phép thử nghiệm kiểu không thể ở chế độ khác (tướng xạ thủ cầm trọn bộ giáp, tướng đỡ đòn thành chủ lực).
- **Mở đầu ván có quyết định ngay.** Cổng thay vòng băng chuyền: thay vì chạy giành đồ, mọi người nghĩ "ván này luật gì".
- **Có đường build-around nhìn thấy được.** Người mới thích Legend vì đi theo hướng dẫn dễ; người chơi bộ trong ARAM thích thấy "còn thiếu 1 món nữa là đủ bộ".

### 3.2 Chê

- **May rủi quyết định quá nhiều.** Phroxzon thừa nhận: roll được Lăng Kính tốt thì xếp hạng trung bình cao hơn. Người chơi lo một số Lõi/đồ chỉ hợp vài tướng.
- **Lõi mạnh với vài người, tệ với đa số** (Lõi Lời Nguyền), hoặc **một Lõi quyết định cả trận**. Riot đặt nguyên tắc: build mạnh không được tự quyết định trận.
- **Ván nào cũng giống nhau khi một hệ quá mạnh** (bộ ARAM, Legend Ornn). Đây đúng là vấn đề "một chiều" Liam nói.
- **Lõi không hiểu nổi** (Pass-a-Fist, Cổng phức tạp): thua mà không biết vì sao.
- **Lõi chết:** Lõi đòi điều kiện quá hẹp. Riot tắt Critical Success thay vì cân lại vì nó "đòi set-up quá cụ thể".
- **Bảng thống kê làm hỏng game:** khi web tỉ lệ thắng Lõi lan ra, ai cũng chọn theo bảng. Riot thử giấu dữ liệu Lõi khỏi API (13.12), bị phản đối, phải mở lại ở 9.5. Mort thừa nhận ngây thơ. Bài học: không giấu được thông tin, phải làm cho **lựa chọn đúng phụ thuộc vào tình huống**, để bảng tỉ lệ không đúng mọi lúc.

### 3.3 Lõi hỏng và cách sửa (các mẫu)

| Vấn đề | Ví dụ | Cách Riot sửa |
|---|---|---|
| Một Lõi mạnh với vài tướng cụ thể | Scoped Weapons (TFT) quá mạnh với Nilah, Mordekaiser | Tắt hẳn |
| Đòi điều kiện quá hẹp, thường yếu, đôi khi bùng | Critical Success | Tắt, không cân |
| Câu giờ, xếp hạng thấp nhưng khó chịu | Lõi Lời Nguyền (Arena) | Tắt đến khi làm lại |
| Hồi máu quá mức | Grandma's Chili Oil | Nerf (Riot nói đây là ngoại lệ, bình thường không nerf bừa Lõi mạnh) |
| Cộng dồn chỉ số | Tons of Stats | Đổi số: tăng máu, giảm công |
| +1 hệ cộng chồng ra Lăng Kính hệ quá dễ | Heart/Crown TFT | Không cho +1 vào hệ dọc lớn; từ Set 10 chỉ +1 hệ từ Lõi |
| Thưởng bộ nuốt cả lựa chọn | Bộ ARAM | Bỏ cả hệ bộ, tách thưởng hay thành Lõi lẻ |
| Lõi được bảo đảm + Cổng ra tổ hợp chồng | Legend Ezreal + Ecliptic Vaults | Bỏ Legend |
| Lõi kinh tế lấy muộn quá mạnh/vô dụng | Rich Get Richer | Khoá theo lượt (chỉ 2-1) |

### 3.4 Cách họ chống một lối chơi trội (tổng hợp)

1. **Không cho mua thẳng thứ mạnh nhất.** Đồ Lăng Kính chỉ được đưa, 3 chọn 1. Không có "build chuẩn" lặp lại được.
2. **Lõi trội vẫn không hiện mỗi ván:** pool lớn, mỗi lượt chỉ 3 thẻ, một Lõi tối đa 4 lần mỗi trận.
3. **Bậc do game điều phối, giống nhau cho mọi người**, chuỗi bậc được viết sẵn để ván nào cũng có một đỉnh nhưng không quá nhiều đỉnh.
4. **Lọc thẻ chết** để mỗi lượt thật sự có 3 lựa chọn.
5. **Luật cả ván đổi giá trị các lối chơi**: The Sump giết lối tích lãi, Stillwater Hold giết lối dựa Lõi, Jayce's Workshop thưởng lối liều. Lối trội ván này thành lối thường ván sau.
6. **Lõi đánh đổi** (Back to Basics, Draw Your Sword, Cursed Crown) thay vì Lõi cộng: không có lựa chọn "luôn đúng", vì cái giá phụ thuộc đội.
7. **Cho bỏ/thay Lõi** (Arena mùa 2): người chơi không bị kẹt, nên Lõi có thể mạnh và lạ hơn.
8. **Tắt nhanh, sửa sau.** Lõi hỏng bị tắt trong hotfix, không đợi cân bằng hoàn hảo.
9. **Đổi thể thức định kỳ** (Sự kiện Arena mỗi patch, xoay vòng Khách Mời): meta tự đổi.

---

## 4. Nguyên tắc thiết kế rút ra (11 cái)

1. **Biến động giữa các run, không phải trong tay người chơi.** Arena và TFT cho cả bàn cùng bậc ở cùng lượt; người chơi không "cày" được bậc cao bằng cách chơi an toàn. Với Axie Dice: bậc theo mốc như bảng 2.1 depth-v3 là đúng; Luật run mới là thứ đổi bậc (giống Jayce's Workshop, Swain), và người chơi thấy rõ từ đầu run.

2. **Chuỗi bậc được điều phối, không tung độc lập.** TFT viết sẵn khoảng 18 chuỗi bậc có xác suất; Lăng Kính sớm thì lượt sau ít khi Lăng Kính nữa. Mỗi ván có một "đỉnh", hiếm khi không có, hiếm khi ba. Axie Dice nên rút bậc cho cả 4 lần chọn một lần lúc `new_run` từ một bảng chuỗi, thay vì tung từng lần (ví dụ: không bao giờ 0 Tinh Thể trước boss 2, không quá 3 Tinh Thể ở Short).

3. **Thứ mạnh nhất không được chọn thẳng.** Đồ Lăng Kính Arena không mua được, chỉ được đưa 3 chọn 1. Legend TFT (chọn trước hướng Lõi) bị bỏ vì người giỏi tối ưu hết, 5-7/8 người cùng một Legend. Axie Dice: không cho perk/Aid nào bảo đảm một Lõi cụ thể; "thẻ theo hướng" chỉ tăng xác suất, không bảo đảm.

4. **Bậc thấp cộng số, bậc cao đổi luật.** Gần như mọi Lõi Lăng Kính tiêu biểu (Back to Basics, Blade Waltz, Nesting Doll, Draw Your Sword) là đổi luật hoặc đánh đổi; Lõi cộng thuần nằm ở Bạc và ở đe chỉ số. Axie Dice: Lõi `stat` chỉ ở Rêu là đúng; Tinh Thể nên 100% là luật/đánh đổi.

5. **Đánh đổi tốt hơn cộng thuần, vì nó không bao giờ "luôn đúng".** Goliath (to, trâu, dễ trúng), Draw Your Sword (mất tầm đánh), Cursed Crown (+2 ô, mất máu gấp đôi). Giá trị của nó phụ thuộc đội đang có, nên bảng tỉ lệ thắng không nói được "luôn chọn cái này". Đây là vũ khí chính chống lối trội.

6. **Luật cả run phải mạnh mà dễ hiểu.** Cổng nhẹ thì người chơi chán (Set 10), Cổng phức tạp thì bị chê (The Sump, House Lightshield, Noxkraya). Một luật nên đọc trong một câu, đổi một con số hoặc một quan hệ, và người chơi thấy tác động ngay trận đầu. Ví dụ tốt: "Mọi lượt Lõi ván này đều Lăng Kính".

7. **Luật run + Lõi cộng dồn, phải cân lại nền và thử tổ hợp.** TFT phải tăng cấp tối đa lên 10 vì Cổng + Lõi + Legend làm sức mạnh trung bình vượt dự tính; một số Cổng + Lõi có trần quá cao (Ezreal + Ecliptic Vaults). Axie Dice: mỗi luật run nên có cái giá đi kèm, và khi chơi thử phải thử luật x Lõi mạnh nhất, không chỉ Lõi.

8. **Thưởng bộ không được nuốt Lõi lẻ.** ARAM bỏ bộ vì chọn món nào cũng về cùng hiệu ứng (Pháo Hoa), và người chơi chọn vì bộ chứ không vì hợp tướng. Nếu giữ bộ: thưởng bộ nhỏ, khuếch đại cái riêng của từng món, và các món trong bộ phải khác trục (gom đủ bộ là phải chơi ba kiểu khác nhau, không phải một kiểu ba lần).

9. **Cho người chơi thoát khỏi Lõi sai.** Arena mùa 2: đầy ô thì lượt chọn sau là nâng cấp Lõi có sẵn, hoặc bỏ một Lõi lấy Lõi cao hơn một bậc. Khi người chơi biết mình sửa được, họ dám lấy Lõi lạ, và game dám làm Lõi mạnh/lạ hơn.

10. **Lọc thẻ chết, nhưng đừng lọc thành bảo đảm.** Arena không cho Lõi phép hiện với tướng không dùng phép; Riot tắt Critical Success vì nó đòi set-up quá hẹp. Nhưng lọc quá tay thành ra Legend: hướng nào cũng chắc chắn tới. Giữ quy tắc "điều kiện đội" ở 2.2 depth-v3, thêm một tầng: không lọc theo "Lõi tốt nhất cho đội", chỉ lọc "Lõi không làm được gì".

11. **Nhiệm vụ nhiều nấc và tắt nhanh khi hỏng.** Nhiệm vụ một ngưỡng thì hoặc quá dễ hoặc không bao giờ xong; 26.12 đổi sang nhiều nấc. Lõi hỏng (Scoped Weapons, Lời Nguyền) bị tắt trong hotfix rồi mới sửa. Axie Dice nên có cờ `disabled` trong data Lõi/Luật run để tắt bằng data, không cần bản build.

---

## 5. Chuyển sang Axie Dice

Đọc kèm `design/proposals/depth-v3-design.md` mục 2-5 và ghi chú reviewer 4 (8 Luật run). Tôi cố tránh trùng 8 luật đó; chỗ nào gần thì ghi rõ. Số đặt cho tier-1 Common như depth-v3 (mặt dmg 2-5, khiên 2-4), tất cả cần chơi thử. Tên theo đất Lunacia (Thảo Nguyên, Rừng, Băng Nguyên, Huyền Bí, Khởi Nguyên là 5 loại đất Axie) và Chimera, đều là tên tạm.

### 5a. Luật run (14 ý)

Mỗi luật có một cái lợi và một cái giá. Cột "Phá lối nào" nói nó làm lối chơi nào yếu đi trong run đó, vì Liam nói game đang "một chiều nếu chọn đúng cách đánh". Cột "Cần" ghi luật có chạy được chỉ bằng knob hiện có không (theo depth-v3 mục 3-5), hay cần hook mới.

**Nhóm 1: luật đổi chính hệ Lõi** (mẫu: Jayce's Workshop, Stillwater Hold, Swain, Ambessa, Katarina, Vladimir)

| # | Tên | Luật | Đẩy sang lối | Phá lối nào | Cần |
|---|---|---|---|---|---|
| 1 | **Mưa Sao Khởi Nguyên** | Lần chọn Lõi 1 là Tinh Thể. Quái thường và Elite +15% HP cả run | Build-around từ trận đầu, run "điên" | Lối an toàn dựa Lõi Rêu đệm | Knob bậc + knob HP |
| 2 | **Đất Hoang Huyền Bí** | Chỉ 3 lần chọn Lõi (bỏ lần sau Elite), mỗi lần 4 thẻ. Bù: mỗi Axie +1 level đầu run | Chơi bằng nền: Hold, reroll mana, xếp hàng | Lối dựa một combo Lõi cụ thể | Knob số lần chọn, số thẻ, level |
| 3 | **Đền Hiến Máu** | Ở mỗi lần chọn Lõi, được hiến 20% HP hiện tại của cả đội để thẻ lên 1 bậc (một lần mỗi lượt chọn, trước khi thấy thẻ mới) | Liều: đội có mặt heal (eyes) tốt, đi đường nhiều node hồi | Lối "giữ máu đầy, chơi chậm" | Hook mới ở màn chọn Lõi (một nút, không cần action trận) |
| 4 | **Quạ Đưa Tin** | Bậc lần chọn sau Elite/boss tuỳ trận đó: thắng trong ≤5 lượt và không Axie nào gục thì +1 bậc; có Axie gục thì -1 bậc | Đánh nhanh, dồn sát thương, Hold cho lượt Hở | Lối rùa (Bức Tường Sống + bộ Gai, reviewer ghi chú 2) | Đọc số lượt + số Axie gục cuối trận (đã có trong stats run?) |
| 5 | **Lễ Hội Chimera** | Đầu run nhận ngay 1 Lõi Hổ Phách ngẫu nhiên (thấy, không chọn). Lần chọn 1 vẫn diễn ra | Thích nghi quanh một Lõi bị ép | Lối "run nào cũng mở bằng cùng một Lõi" | `take_reward` sẵn có, rng tách salt |
| 6 | **Gió Đổi Chiều** | 5 reroll Lõi cả run (thay 2), nhưng mỗi lượt chọn chỉ 2 thẻ | Săn hướng có chủ đích, săn bộ | Lối nhận đại thẻ đầu tiên hợp | Knob reroll Lõi + số thẻ |

**Nhóm 2: luật đổi trận** (mẫu: The Sump, Petricite Forest, Lavender Sea, Yuumi's Zoom)

| # | Tên | Luật | Đẩy sang lối | Phá lối nào | Cần |
|---|---|---|---|---|---|
| 7 | **Băng Nguyên** | Không còn reroll miễn phí. Hold được 2 viên, viên Giữ +1 giá trị khi dùng lượt sau | Kế hoạch 2 lượt, Hold, boss nhịp | Lối spam reroll tìm mặt đẹp | Knob `free_reroll`, `stash_max`, bonus Focus (Tay Chắc của reviewer gần giống, luật này đổi giá thay vì đổi HP quái) |
| 8 | **Rừng Già** | Mọi Axie và quái +30% HP. Heal và độc +50% | Trận dài: độc, hồi, khiên | Lối dồn sát thương một lượt (Thác Đổ + Xúc Xắc Thứ Sáu) | Knob HP, nhân heal/poison |
| 9 | **Thảo Nguyên Khô** | Mana không mang qua lượt (cuối lượt mất phần dư). Bù: đầu lượt +2 mana | Tiêu mana mỗi lượt: reroll, Lõi mana | Lối tích mana (Bể Tràn, Mạch Ngầm) | Knob mana carry + start-turn mana |
| 10 | **Thuỷ Triều Lên** | Trước mỗi trận công khai một hàng được nước: hàng trước nhận -25% sát thương, hoặc mặt dmg hàng sau +2. Luân phiên theo trận | Xếp lại đội mỗi trận (`reorder_party`) | Lối xếp đội một lần cả run | Knob theo hàng, một cờ mỗi trận (rng tách salt) |
| 11 | **Thế Giới Lộn Ngược** | Quái đánh đơn mục tiêu nhắm hàng sau trước; hàng trước chỉ trúng AoE | Đặt Axie khiên/hồi ở hàng sau, đánh ở hàng trước | Lối "tank trước, carry sau" mặc định | Đảo một điều kiện trong `_pick_enemy_intent` (knob hàng ưu tiên) |
| 12 | **Sông Một Dòng** | Dùng liên tiếp hai mặt cùng loại (dmg-dmg, khiên-khiên...) thì mặt sau +1, chuỗi 3 thì +2. Đổi loại thì mất chuỗi. Resonance liền kề tắt run này | Thứ tự gán theo loại mặt, không theo vị trí | Lối Mồi/Resonance theo vị trí liền kề | Hook mới (đếm chuỗi trong lượt), nhỏ |
| 13 | **Đại Hội Muôn Loài** | Mỗi class khác nhau trong đội: đầu trận +1 mana (đội 5 class = +5). Mỗi cặp trùng class: quái +4% HP | Đội đa class | Lối gom một class (nếu đó là lối trội, cần Liam xác nhận) | Đọc class đội lúc vào trận, knob |
| 14 | **Tàn Tích Cổ** | Mỗi Axie gục (kể cả Egg) cho 1 "hồn". Đủ 6 hồn: một lượt chọn Lõi Hổ Phách thêm (không tính vào 4 lần) | Chơi bạo, chấp nhận Axie gục, Egg, Cảm Tử | Lối "không bao giờ để ai gục" | Đếm death trong run + `take_reward` |

Ghi chú:
- **Không đụng map** (theo reviewer: map dùng rng chung). Các luật trên đều rút bằng `Rng.new(run_seed ^ RULE_SALT)`, kể cả cờ theo trận của #10 (dùng salt riêng + số trận).
- Pillar minh bạch: tôi bỏ ý "intent quái ẩn số" (kiểu LeBlanc) vì trái pillar.
- Ba luật nên có ngay ở bump 1 nếu chỉ chọn ít: **#4 Quạ Đưa Tin** (phá rùa, rẻ), **#9 Thảo Nguyên Khô** (phá tích mana, chỉ knob), **#10 Thuỷ Triều Lên** (làm xếp đội thành quyết định mỗi trận, đúng chỗ reviewer chê). Cộng 8 luật reviewer là 11, đủ để 2 thẻ đầu run hiếm khi lặp trong 5 run đầu.
- Mẫu Arena: có lần bỏ phiếu thứ hai ở vòng 8. Axie Dice có thể có **luật run thứ hai sau boss 1** (chọn 1 trong 2, nhẹ hơn). Để đợt 2, vì cộng dồn khó cân (nguyên tắc 7).
- Mẫu Riven: một thẻ "Không luật" thỉnh thoảng hiện. Có ích cho người mới và cho người muốn chơi nền. Đề xuất: không hiện ở run đầu của tài khoản (lúc đó nên ép luật nhẹ), sau đó 10% thay một trong hai thẻ.

### 5b. Bộ Lõi (5 ý), kèm cảnh báo

Cảnh báo trước: ARAM bỏ bộ vì đồng hoá build (mục 1.4). Bốn bộ ở 2.6 depth-v3 đều gom ba Lõi **cùng một hành vi** (Triều = ba Lõi mana, Gai = ba Lõi hàng trước, Nanh = ba Lõi Kết, Tổ = ba Lõi Egg). Đó đúng là kiểu Pháo Hoa: gom đủ bộ là chơi một kiểu ba lần. Tôi đề xuất đổi khung bộ theo ba luật:
1. Ba món trong một bộ phải **khác trục** (mặt / vị trí / mana / quest / rule). Gom đủ bộ là phải chơi ba thứ khác nhau.
2. Thưởng bộ **khuếch đại hiệu ứng riêng của từng món**, không thêm một hiệu ứng chung mới. Như vậy thưởng bộ mạnh hay yếu tuỳ món nào bạn có.
3. Thưởng 2 món ≤ khoảng 1/3 sức một Lõi Hổ Phách. Lõi lẻ vẫn là thứ chính.

Năm bộ theo khung đó:

| Bộ | Gồm (trục) | 2 món | 3 món | Lối chơi |
|---|---|---|---|---|
| **Triều Đêm** | Lõi Hold (mặt) + Lõi mana + Lõi Kết (mặt) | Viên Giữ khi dùng cho +1 mana | Lượt nào Kết là viên vừa Giữ: hoàn 1 reroll lượt sau | Giữ một viên, tiêu mana, chốt bằng viên đó |
| **Hàng Rào Gai** | Lõi hàng trước (vị trí) + Lõi khiên (mặt) + Cảm Tử (rule) | Đòn đơn mục tiêu đầu tiên mỗi trận vào hàng trước -50% | Axie hàng trước gục: Axie hàng sau liền kề nhận khiên = giá trị mặt khiên cao nhất của nó | Hàng trước chịu đòn rồi hi sinh có ích |
| **Ổ Trứng Vàng** | Lõi Egg (rule) + Lõi mana + Tàn Tích-kiểu (quest) | Egg sinh ra với khiên 3 | Egg gục: Axie liền kề được dùng lại một mặt đã dùng lượt này (một lần mỗi lượt) | Egg là tài nguyên, không phải lá chắn |
| **Thợ Săn** | Lệnh Truy Nã (rule) + Lõi Kết (mặt) + Nhiệm vụ Thợ Săn (quest) | Quái bị đánh dấu nhận thêm +2 từ mặt Kết | Hạ quái bị đánh dấu bằng Kết: đánh dấu ngay quái khác (một lần mỗi trận) | Chọn mục tiêu, thứ tự gán |
| **Kẻ Liều** | 3 Lõi bất kỳ có nhãn "liều" (Hoá Thạch, Vương Miện Gai, Thí Nghiệm Điên, Đền Hiến Máu...) | Mỗi Lõi liều đang có: +1 reroll Lõi (một lần) | Lần chọn Lõi kế tiếp có 1 thẻ Tinh Thể | Run liều được thưởng thêm liều, không cộng chỉ số |

**Phương án thay bộ (khuyến nghị cân nhắc):** mượn Arena mùa 2, cho Lõi **lên cấp**. Từ lần chọn 3, nếu đã có ≥2 Lõi lên cấp được, một trong ba thẻ có thể là "Nâng cấp Lõi X lên cấp 2" (cấp 2 = số mạnh hơn + một hiệu ứng nhỏ). Đầy ô: lượt chọn đổi thành "nâng cấp" hoặc "bỏ một Lõi, lấy Lõi cao hơn một bậc". Lợi: người chơi đi sâu một hướng mà không ép mọi run về bốn bộ cố định; Lõi lẻ vẫn là trung tâm. Giá: mỗi Lõi lên cấp cần data cấp 2, và thêm một loại thẻ ở màn chọn. Liam quyết giữa bộ / lên cấp / cả hai.

### 5c. Lõi cụ thể dịch từ Arena/TFT (15 cái)

Ưu tiên đổi luật. Nhãn "liều" dùng cho bộ Kẻ Liều. Mọi bonus phẳng vẫn tính vào trần +10/mặt của depth-v3 3.4.

| # | Tên | Bậc | Trục | Làm gì | Từ đâu | Đẩy sang lối |
|---|---|---|---|---|---|---|
| 1 | **Hoá Thạch** (liều) | Rêu | rule | Không có hiệu ứng. Lần chọn Lõi kế tiếp lên 1 bậc; nếu đã là Tinh Thể thì có 4 thẻ | Transmute | Hi sinh sức sớm lấy đỉnh sau; khó với run sắp gặp boss |
| 2 | **Về Với Nanh Vuốt** | Tinh Thể | mana | Mặt ears không cho mana, không có cantrip. Mọi mặt dmg +2. Reroll thứ 2-3 mỗi lượt miễn phí, hết reroll thứ 4 | Back to Basics | Bỏ hẳn hệ mana, đánh thô bằng reroll |
| 3 | **Thí Nghiệm Điên** (liều) | Hổ Phách | rule | Trước mỗi trận, công khai rút: **To** (HP tối đa +25% trận này, mặt dmg -1) hoặc **Nhỏ** (mặt dmg +2, HP tối đa -20%) | Mad Scientist | Mỗi trận chơi một kiểu; Nhỏ gặp boss là phải dùng Hold kỹ |
| 4 | **Cảm Tử** | Hổ Phách | rule | Axie gục thì nổ: sát thương bằng 2 lần mặt dmg cao nhất của nó lên mọi quái | Dive Bomber | Hàng trước là bom; hợp Egg, Tàn Tích Cổ |
| 5 | **Búp Bê Lồng** | Tinh Thể | rule | Lần đầu mỗi Axie gục trong trận: đứng dậy 40% HP, nhưng mặt có giá trị cao nhất của nó thành mặt trống tới hết trận. Tối đa 2 lần mỗi trận cho cả đội | Nesting Doll | Chịu được boss Đòn, đổi bằng sức đánh |
| 6 | **Ngòi Nổ** (liều) | Hổ Phách | pos | Đầu trận gắn ngòi lên Axie ở vị trí 0. Cuối lượt 3: nổ 10 sát thương mọi quái, 5 lên chính nó (khiên chặn được) | Self Destruct | Canh khiên cho vị trí 0 đúng lượt 3; khớp nhịp boss 3 lượt |
| 7 | **Lệnh Truy Nã** | Rêu | rule | Đầu trận đánh dấu 1 quái (công khai). Hạ nó trước các quái khác: +2 mana trận sau và hồi 3 HP cả đội | Contract Killer | Chọn mục tiêu thay vì đánh con yếu nhất |
| 8 | **Sóng Khiên** | Hổ Phách | dice | Mặt khiên và heal cũng gây sát thương bằng 50% giá trị (làm tròn lên) lên quái đang nhắm Axie nhận khiên/heal | Sonic Boom, Holy Fire | Mặt back/eyes thành mặt đánh; đội hỗ trợ vẫn thắng nhanh |
| 9 | **Tích Ác** | Hổ Phách | dice | Mỗi lần mặt Kết hạ một quái: mặt Kết +1 vĩnh viễn cả run, tối đa +6 | Phenomenal Evil, Stackosaurus | Run mạnh dần nếu canh Kết đúng lúc kết liễu |
| 10 | **Già Làng** | Tinh Thể | stat-trễ | Ngay: +1 level cho Axie thấp nhất. Sau mỗi 2 trận thắng: +1 level cho Axie thấp nhất | Wisdom of Ages | Yếu lúc nhận, mạnh cuối run; kéo đội đều level |
| 11 | **Vương Miện Gai** (liều) | Tinh Thể | rule | +1 ô Lõi và lần chọn Lõi kế tiếp có 4 thẻ. Đội nhận +30% sát thương cả run | Cursed Crown | Đánh nhanh, khiên nhiều, hoặc chết |
| 12 | **Kẻ Lạc Loài** | Hổ Phách | pos | Axie không cùng class với ai trong đội: mặt +1, và có 1 reroll riêng miễn phí cho viên của nó mỗi lượt | Built Different | Đội nhiều class, phá lối gom một class |
| 13 | **Đứng Một Mình** | Rêu | pos | Axie không có đồng đội còn sống ở ô liền kề (theo roster) đầu lượt nhận khiên 3 | Exiles | Xếp thưa, bỏ ô; mạnh khi đội còn 3 Axie |
| 14 | **Bạn Phương Xa** | Hổ Phách | pos | Vị trí 0 và 4 tính là liền kề cho Mồi và Resonance. Khi một trong hai bị đánh, người kia +2 cho mặt dmg kế tiếp | Long Distance Pals | Nối hàng trước với cuối hàng sau, xếp có chủ ý |
| 15 | **Nhiệm vụ: Săn Chimera** (nhiều nấc) | quest | quest | Nấc 1: hạ 8 quái bằng mặt Kết → +1 reroll Lõi. Nấc 2: hạ 20 → một lần chọn Lõi Hổ Phách. Nấc 3: hạ một boss bằng mặt Kết → Lõi Tinh Thể | Urf's Champion + nhiệm vụ nhiều nấc 26.12 | Mục tiêu nhỏ suốt run, không có cảnh "trượt một ngưỡng là mất hết" |

Ghi chú kỹ thuật thô (để lead-programmer kiểm, tôi không đọc code): #3, #6, #7 cần một cờ theo trận rút bằng rng tách salt; #4, #5 cần hook khi Axie gục; #12 đụng reroll riêng theo viên, có thể phải thêm action. Nếu cần cắt, #12 bỏ phần reroll riêng, chỉ giữ +1.

### 5d. Chống "một chiều" cụ thể

1. **Hỏi lại Liam lối trội là gì** (gom class? dồn dmg một lượt? rùa khiên? spam reroll?). Nghiên cứu này chỉ đưa công cụ; chọn luật run và Lõi khắc chế phải dựa trên lối cụ thể.
2. **Luật run phải có ít nhất 2 luật làm yếu mỗi lối mạnh đã biết.** Bảng 5a đã ghi cột "Phá lối nào". Khi biết lối trội, bảo đảm pool có ≥2 luật khắc nó, để khoảng 1/3 số run lối đó không phải lựa chọn tốt nhất.
3. **Lõi Tinh Thể chủ yếu là đánh đổi**, để không có Lõi "luôn lấy". Nếu sau chơi thử thấy một Lõi được chọn >60% lần nó hiện, đổi nó thành đánh đổi trước khi nerf số.
4. **Không cho cộng chồng cùng một trục vô hạn** (mẫu TFT: chỉ +1 hệ từ Lõi). Ví dụ: tối đa 2 Lõi `pos` cùng tác động hàng trước.
5. **Bậc theo chuỗi điều phối** (nguyên tắc 2) để không có run quá dễ vì ra 3 Tinh Thể sớm.
6. **Ghi log lựa chọn** (Lõi hiện, Lõi chọn, luật run, thắng/thua, số lượt mỗi trận) ở bản playtest. Riot cân Lõi bằng dữ liệu xếp hạng trung bình; Axie Dice có thể đọc từ save/leaderboard sau này.
7. **Cờ `disabled` trong data** cho từng Lõi và Luật run, để tắt bằng data khi phát hiện hỏng (mẫu hotfix Riot).

### 5e. Câu hỏi cho Liam

1. Lối chơi "một chiều" cụ thể là lối nào? (cần để chọn luật run/Lõi khắc chế cho bump 1)
2. Giữ bộ Lõi theo khung mới (khác trục, thưởng khuếch đại), đổi sang Lõi lên cấp kiểu Arena mùa 2, hay cả hai? Khuyến nghị của tôi: lên cấp cho bump 2, bump 1 chỉ sửa 4 bộ cho khác trục.
3. Bậc Lõi rút theo chuỗi cả run (TFT) thay vì tung từng lần như bảng 2.1? Khuyến nghị: có, rẻ và chống được run quá dễ/quá khó.
4. Có muốn luật run thứ hai sau boss 1 (mẫu bỏ phiếu vòng 8 của Arena) ở đợt sau không?

---

## 6. Nguồn và độ tin cậy

**Tin cậy cao (Riot chính thức):**
- Trang hỗ trợ Riot "What is Arena?": https://support.riotgames.com/en-us/league-of-legends/gameplay/league-of-legends-arena-game-mode (lịch vòng, đe, sân; bảng bị vỡ khi đọc nên lịch có thể sai cột)
- /dev: Arena Round Three (14.9): https://www.leagueoflegends.com/en-gb/news/dev/dev-arena-round-three/
- /dev: Leveling Up Arena (mùa 2, 2026): https://www.leagueoflegends.com/en-us/news/dev/dev-leveling-up-arena/
- Patch 26.12: https://www.leagueoflegends.com/en-us/news/game-updates/league-of-legends-patch-26-12-notes/
- Runeterra Reforged Mechanics Overview (Cổng, Legends): https://teamfighttactics.leagueoflegends.com/en-au/news/game-updates/runeterra-reforged-mechanics-overview
- /dev: TFT Runeterra Reforged Learnings: https://teamfighttactics.leagueoflegends.com/en-au/news/dev/dev-tft-runeterra-reforged-learnings
- /dev: TFT Remix Rumble Learnings: https://teamfighttactics.leagueoflegends.com/en-us/news/dev/dev-teamfight-tactics-remix-rumble-learnings/

**Tin cậy vừa (báo/esports, tổng hợp, có thể lệch patch):**
- Inven Global, bỏ bộ Lõi (gọi nhầm là Arena, thật ra là ARAM Hỗn Loạn): https://www.invenglobal.com/articles/22318/lol-arena-set-augments-to-be-removed
- esports.net, danh sách Khách Mời: https://www.esports.net/news/lol/guest-of-honor-in-lol-arena/
- esports.net, Lõi Arena tiêu biểu: https://www.esports.net/news/lol/best-augments-lol-arena/
- loltheory.gg, Arena 2026: https://blog.loltheory.gg/what-is-arena/
- dodge.gg, Arena 2026: https://www.dodge.gg/en-US/lol/news/arena-guide-2026
- tracker.gg, danh sách Cổng Set 9: https://tracker.gg/checkpoint/articles/all-portals-in-teamfight-tactics-tft-set-9
- tftodds.com, tỉ lệ bậc Lõi (số cộng đồng đo): https://tftodds.com/augments/augments-distribution
- metabot.gg, ba bậc Lõi TFT: https://metabot.gg/en/TFT/guides/tft-augments-explained-silver-gold-prismatic
- RiftFeed, phỏng vấn Mort Set 7: https://riftfeed.gg/more/tft-set-7-dargonlands-mort-interview
- RiftFeed, Lõi Arena bị cắt: https://riftfeed.gg/lol-news/lol-these-insane-augments-were-originally-planned-for-arena
- EarlyGame, tắt Lõi Lời Nguyền: https://earlygame.com/general-news/lol-arena-riot-disables-popular-augments-for-holiday-season
- Dot Esports, Riot bỏ chặn dữ liệu Lõi: https://dotesports.com/tft/news/mortdog-admits-tfts-ban-on-augment-stats-sites-was-naive-as-riot-changes-course
- GGRecon, patch TFT 13.12 (reroll từng thẻ): https://www.ggrecon.com/guides/tft-13-12-patch-notes-runeterra-reforged-legends-augments-more/
- Dot Esports / Mobalytics về Encounters Set 11 (chỉ đọc được đoạn trích tìm kiếm): https://dotesports.com/tft/news/all-tft-set-11-encounters

**Tin cậy thấp / trí nhớ:** các Lõi ghi "(trí nhớ)" ở 1.8 và nhiều tên Lõi TFT ở 2.3 (Cruel Pact, Pandora's Items, Cursed Crown, Ascension, Exiles, Long Distance Pals...). Wiki LoL và Mobalytics trả 403 nên không đối chiếu được số. Ý tưởng cơ chế đáng tin, số cụ thể thì không.

**Mâu thuẫn chưa gỡ:** lịch chọn Lõi Arena (Riot: 1/3/5/7/10/12/14/16; hướng dẫn 2026: 1/5/8/11 + Lăng Kính 7/10), số ô Lõi (4 hay 6). Không ảnh hưởng kết luận vì Axie Dice có lịch riêng.
