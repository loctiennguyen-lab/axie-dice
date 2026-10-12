Trạng thái: REVIEW — chờ Liam

# Review: Monetization v1 (creative-director, 11/10/2026)

Review cho `design/proposals/monetization-v1.md` (game-designer viết, economy-designer định giá §9). Mình không sửa file proposal.
Đã đọc: proposal (cả 701 dòng), `active.md` mục "HƯỚNG SẢN PHẨM MỚI", `ascension-v2.md` (§1.2, §2, §5.1), `economy-v2.md` (ECO-1..20), `echobox-pass-v2.md` (đầu file).
Không bàn lại các hướng Liam đã chốt: tạo ức chế trong run rồi bán giải pháp, dùng được trong ranked, Land không cho sức mạnh, không bán gì quanh Nhiệm vụ, server tung dice, game phải thật khó, Continue kiểu B. Review này chỉ xét **làm có tốt không** trong khung đó.

## Kết luận: APPROVE WITH CHANGES

Hướng đi được thể hiện tốt. Sáu công cụ ức chế đều đọc được trước (có bộ đếm, có vạch phase), không dựa vào trait khắc chế, không gắn tên quái, khớp luật của `ascension-v2`. Aid tách hẳn khỏi relic, có trần, server cấp và ghi log. Phần định giá có số thật, tự tìm ra chỗ vỡ của chính mình (§9.9) chứ không giấu. Cảm giác chung: đây là "game khó, có lối tắt trả tiền, nói thẳng điều đó", không phải "game bị bóp để bán". Đó đúng là ranh giới phải giữ.

Chưa duyệt thẳng được vì 3 việc sẽ làm hỏng bước sim và bước code nếu để nguyên:
1. Hai bảng win rate mục tiêu đang mâu thuẫn nhau (proposal §9.4 và `ascension-v2` §5.1), và bảng mới phá luật bước của Ascension. Sim không thể nhắm hai đích.
2. Cách sửa BREAK-1 ("sau Continue boss giết đội nhanh hơn") viết mơ hồ. Nếu ai đó làm thành luật chỉ bật sau khi mua Continue, thì độ khó phụ thuộc vào việc trả tiền. Đó là thứ proposal tự cấm.
3. Thân file (§0, §1.4, §2, §3) vẫn ghi số cũ, mâu thuẫn với §9. Người code đọc §2.1 sẽ làm VIP 2 Continue, R10 3 lần, Pass 900.

Sửa ba việc này là vào sim được. Các mục MAJOR bên dưới sửa song song, không cần làm lại thiết kế.

## Bảng phát hiện

| # | Mức | Mục | Vấn đề | Cách sửa |
|---|---|---|---|---|
| 1 | **BLOCKER** | §1.4, §9.4 vs `ascension-v2` §5.1 | Có hai bảng mục tiêu cho cùng một sim. Ascension: bot trung bình A6 32%, A10 20%, người giỏi A6 57%, A10 35–40%. Monetization: regular A6 24%, heavy A6 50%, heavy A10 28%. Bảng monetization còn phá luật bước của Ascension ("mỗi bước giảm 2–4 điểm, không bước nào > 5"): regular A3→A6 rớt 20 điểm qua 3 bước (6,7/bước), heavy A3→A6 cũng 6,7/bước, regular A0→A3 5,3/bước. Nghĩa là A4–A6 sẽ thành một bức tường, đúng thứ Ascension muốn tránh. | Một bảng duy nhất, đặt ở `ascension-v2` §5.1 (Ascension là hệ sở hữu đường cong độ khó), có cột theo hồ sơ người chơi casual/regular/heavy lấy từ §9.4. Monetization chỉ tham chiếu. Hai cách: (a) dàn đều độ rớt cho đủ luật bước. Khi đó regular A6 lên khoảng 29–30% (60 − 6 × 5), nên phải tính lại MON-11 và mức nâng Aid ở §9.4. (b) Liam nới luật bước thành ≤ 7 điểm để giữ bảng "thật khó" của §9.4 và chấp nhận A3–A6 dốc. Liam chọn (Q1). |
| 2 | **BLOCKER** | §9.4, §9.9 BREAK-1(a) | Câu "sau Continue boss giết đội nhanh hơn" có hai cách hiểu. Cách hiểu tốt: chỉnh đường dốc phase 3 và giữ bộ đếm spike, áp cho **mọi người**, có mua hay không. Cách hiểu xấu: một luật chỉ bật khi đã Continue. Cách xấu là độ khó theo hành vi mua, trái tinh thần MON-5, và người chơi sẽ cảm thấy "mua xong nó đánh mạnh hơn". Chỉ cần một bài Reddit kiểu đó là mất niềm tin. Hệ quả phụ của cách hiểu tốt: phase 3 dốc hơn thì người không trả tiền cũng khó hơn, nên phải chạy lại sàn casual A0. | Thêm **MON-13**: "Không luật chiến đấu nào đọc trạng thái Continue/Aid, trừ danh sách reset công khai của Continue B (đội hồi 40%, clock và attrition về 0, stream dice mới). Bộ đếm spike và ngưỡng phase giữ nguyên trạng thái lúc chết." Test tĩnh: hàm sinh dmg/phase không có input `continue_used`. BREAK-1 chỉ được sửa bằng thay đổi áp cho mọi người, và sim phải chạy lại sàn 35% sau khi chỉnh. |
| 3 | **BLOCKER** (cho bước bàn giao) | §0, §1.4, §2.1, §2.4, §3.1 | Thân file chưa cập nhật theo §9: R1 "1/run (VIP 2)", R8 "(VIP 2)", R10 vẫn "3" ở E5 gợi ý, T2 "900 Gem" và T2b vẫn là sản phẩm, T3 vẫn "Continue 2/run, 1 Boon thêm/run", bảng §1.4 vẫn là số cũ, §0 vẫn đưa Pass vào top 5 dù OQ-10 khuyến nghị chờ mùa 2. Người làm sẽ đọc §2 trước §9. | Trước khi bàn giao: sửa §0–§3 theo §9, hoặc thêm một dòng đầu mỗi bảng "số chốt ở §9.x, bảng này là lịch sử". Một nguồn sự thật cho mỗi số. |
| 4 | MAJOR | §4, `economy-v2` ECO-13 | ECO-13 nói "unlock chỉ số = 0 khi Ranked", tức là sức mạnh kiếm bằng cày meta bị tắt trong ranked. Proposal này lại cho Aid mua bằng tiền thật dùng trong ranked. Kết quả: trong ranked, cày không tính nhưng ví thì tính. Người chơi là nhân viên Sky Mavis sẽ thấy ngay chỗ này, và đây là loại mâu thuẫn làm hỏng niềm tin hơn mọi con số giá. | Liam chọn (Q3): (a) bỏ ECO-13, cho unlock meta tính trong ranked (khớp hướng mới "đồ mua dùng được ranked"), hoặc (b) giữ ECO-13 nhưng khi đó ranked phải hiện Aid rõ hơn (bộ lọc Pure mặc định bật cho bảng công ty). Mình nghiêng (a): đơn giản, nhất quán, cày luôn có giá trị. |
| 5 | MAJOR | §1.2 C+D, §1.5 | Attrition (+5%/lượt từ lượt 6, tối đa +25%) và Boss Clock (+20%/lượt, tối đa +100% ở A4; bản nhẹ ở A0) cùng nhân dmg boss nhưng chưa nói cộng hay nhân. Ở A4 lượt 14: cộng = ×2,25, nhân = ×2,5. Thêm phase 3 và spike 1,6–2,0× nữa thì một đòn có thể ×5. Người chơi phải tự nhân bốn con số trong đầu, trái luật "đọc được". | Định nghĩa một công thức gộp (khuyến nghị: cộng các % rồi nhân một lần) và **một số duy nhất** hiện trên địch ("dmg lượt sau: 34"). Đây là yêu cầu cho ux-designer, ghi vào §1.5 mục 5. |
| 6 | MAJOR | §1.2 D, OQ-B/OQ-E vs `relic-set-v2` | Attrition từ A0 và clock nhẹ ở A0 đánh vào build chậm (`patientfang`, `worldtree`, `heartwood`, plague) ở **mọi** level, không chỉ A4+ như Ascension tính. Relic-set đã khóa với cổng "chênh archetype mạnh–yếu ≤ 25 điểm". Hai công cụ mới có thể phá cổng đó mà không ai đo. | Sim phải chạy lại cổng archetype của relic-set với D + clock A0 bật. Nếu build chậm rớt quá cổng, chỉnh `attrition_start` (6 → 8) chứ không sửa relic. Thêm vào cổng chấp nhận §9.10. |
| 7 | MAJOR | §2.1 R6, §5.4 MON-2, §9.5 | `economy-v2` A1 ghi R = 450 "đã trừ shop trong run", tức shop trong run tiêu Shard. Vậy R6 coupon là đường Gem → Shard trực tiếp (~30 Shard/lần, economy đã tự nêu). §2.5 lại nói MON-2 "tuyệt đối". Nhỏ về số, nhưng là câu sai trong một bất biến, và đây đúng là chỗ người ngoài sẽ soi. | Đổi hiệu ứng R6 thành "làm mới hàng shop 1 lần" (giải cùng nỗi đau "shop không có thứ mình cần", không chạm Shard). Nếu giữ giảm giá, sửa MON-2 thành có ngưỡng rõ thay vì "tuyệt đối". |
| 8 | MAJOR | §2.1 R9, §9.2 | Run Kit "không tính vào trần 8" nhưng trong Kit có R2×2 và R7. Đọc chữ thì người mua Kit dùng được 2 R2 của Kit cộng 4 R2 mua lẻ và 8 Aid khác. Toàn bộ phép tính MON-11 (trần 8 cho biên 5,1 điểm) dựa trên trần này. | Ghi rõ: Kit chỉ là trả trước; mỗi R2/R7 lấy từ Kit vẫn tính vào trần từng loại và trần tổng 8 (Boon trong Kit thì không, như R8). |
| 9 | MAJOR | §2.2, §2.4 T3 | Lịch chào có ba chỗ nghiêng về ép: (a) Moon Card chào "sau thua run lần 2": bán gói 30 ngày ngay lúc người ta đang bực là đúng mẫu bị gọi là predatory; Continue ở màn thua thì ổn vì nó giải đúng cái đau đó, thẻ tháng thì không. (b) Nút R2 "cạnh END TURN": bấm nhầm là mất tiền, mà END TURN là nút bấm nhiều nhất trong game. (c) §9.1 viết thẳng là cố ý để dư Gem "để giữ người chơi nạp lại". | (a) Moon Card chỉ chào ở store, ở màn kết quả sau trận **thắng**, hoặc lần đăng nhập ngày thứ 2; không bao giờ ở màn thua. (b) Mọi Aid nằm trong một khay riêng, cách xa END TURN; lần đầu mỗi phiên phải xác nhận (hiện giá Gem kèm ≈ USD), có tùy chọn "tắt gợi ý Aid" trong Settings. (c) Bỏ câu đó khỏi doc. Giữ giá đã tính, nhưng cho Pass mua thẳng bằng USD không qua Gem. |
| 10 | MAJOR | §1.4, §1.3, §2.6 | Hồ sơ "casual" của bot không phải người mới. Người mới thật trong 3–5 run đầu thường yếu hơn casual bot, nên ở A0 họ có thể chỉ thắng 15–20%, cùng lúc phải học attrition, clock A0 và thấy nút Aid. Trải nghiệm đầu bị ức chế dày nhất đúng lúc chưa có lý do để ở lại. MON-5 cấm chỉnh theo ví và theo chuỗi thua, nhưng không cấm chỉnh theo **thâm niên tài khoản**. | Liam chọn (Q4): một "giai đoạn học luật" theo thâm niên, ví dụ attrition và clock A0 chỉ bật sau khi tài khoản thắng run đầu hoặc chơi đủ 5 run, và không chào Aid trả phí trong run hướng dẫn. Không đổi độ khó theo ví hay chuỗi thua nên vẫn giữ MON-5. Đây là chỉnh nhỏ cho OQ-E của Liam, nên mình đưa ra để Liam quyết chứ không tự áp. |
| 11 | MAJOR | §1.2 "suýt thắng", §7.3 | Mục tiêu "trung vị boss còn 15–30% HP lúc thua" là mục tiêu độ khó hợp lý, nhưng nó cũng chính là con số tối ưu cho tỉ lệ mua Continue B. Lâu dần team sẽ có xu hướng chỉnh độ khó theo doanh thu mà không nhận ra. | Thêm **MON-14**: mọi chỉnh `TUNE`/boss chỉ được đánh giá trên dữ liệu run không có Aid và trên sim; không A/B độ khó nào lấy chuyển đổi mua làm chỉ số chính. Ghi vào §7.3. |
| 12 | MAJOR | §9.8 | Mô hình doanh thu dùng hành vi thị trường mobile chung (3% payer, 6% whale chiếm 54%). Nhưng một trong bốn mục tiêu của game là "cạnh tranh trong công ty". Nếu phần lớn người chơi là đồng nghiệp, thì vài người nạp nhiều leo bảng công ty là rủi ro danh tiếng, không chỉ rủi ro tập trung doanh thu. | Tách mô hình thành hai nhóm (nội bộ / công khai) khi có số. Với bảng công ty: hiện biểu tượng Aid trên từng dòng và cân nhắc để Pure làm tab mặc định (OQ-4). Không có giải thưởng có giá trị trên ranked trước khi có ý kiến pháp lý (§6.2 mục 3). |
| 13 | MINOR | §2.1 R2, `ascension-v2` A3 | A3 có câu kiểm thiết kế: "đầu tư relic Reroll hay xây build không cần reroll". R2 thêm đáp án thứ ba là trả tiền. Trần 2/trận giữ được mức nhỏ, nhưng ở A3+ nó làm mờ đúng luật mà level đó giới thiệu. | Cân nhắc R2 1/trận ở A3+ (vẫn 4/run). ΔP gần như không đổi vì người mua thật dùng ≤ 1 Aid/run (§9.6). |
| 14 | MINOR | §2.1 R3, R7 | R3 trùng chức năng relic `fortuneledger`; R7 Scout gắn với "elite" nhưng §1.2 E nói elite luôn hiện trên map, nên Scout thật ra chỉ lộ event/node khác. Hai Aid này yếu về lý do tồn tại. | R7: viết lại mô tả theo đúng thứ nó lộ ra. R3: để v1.1 cùng R10, bớt nút cho UI v1. |
| 15 | MINOR | §9.3 T5 vs T6 | Epic mua thẳng ở store (T5) giá 400 Gem, Epic hộp mùa mua thẳng (T6) giá 200 Gem. Người chơi sẽ thấy đồ mùa (hiếm hơn) rẻ hơn đồ thường. | Thống nhất một bậc giá theo độ hiếm, hoặc ghi rõ lý do (T6 không cho Stone nên rẻ hơn? lý do đó ngược chiều). Economy chốt. |
| 16 | MINOR | §2.4 T6 | T6 chỉ chào "sau ≥ 10 lượt" hộp mùa. Nếu đường mua thẳng bị khóa sau gacha, nó yếu đi đúng ở vai trò lá chắn pháp lý/niềm tin. | T6 luôn có trong store từ ngày đầu mùa; điều kiện 10 lượt chỉ dùng cho việc chào. |
| 17 | MINOR | §3.1, OQ-1 | "Lunar Gem", "Moon Card", "Moon Dust", "LunaLanding": bốn tên cùng một chủ đề, rất dễ nhầm cái nào là tiền thật. | Đặt tên tiền cao cấp khác hẳn chủ đề trăng; Moon Card có thể giữ. |
| 18 | MINOR | §1.2 C, `ascension-v2` A4 | Clock nhẹ ở A0 làm A4 không còn "giới thiệu" luật mới, chỉ là clock mạnh hơn. Sim G (ablation) của Ascension sẽ đo sai delta của A4. | Sửa dòng A4 trong `ascension-v2` thành "clock đầy đủ (lượt 10, +20%, tối đa +100%) thay bản nhẹ A0", và tính ablation so với bản nhẹ. |
| 19 | MINOR | §7.3 | Thiếu chỉ số hối tiếc: người mua Continue mà vẫn thua, rồi bỏ game. | Thêm "churn D7 sau một Continue trả phí bị thua" so với nhóm thua không mua. Nếu cao hơn rõ, giá Continue hoặc độ dốc sau Continue đang sai. |
| 20 | MINOR | OQ-14, §6.2 mục 6 | Khuyến nghị "Steam trước" nhưng game đang chạy web (axiedice.fun, Cloudflare). Chọn kênh thanh toán kéo theo cả việc làm bản Steam. | Đưa lên thành câu hỏi riêng cho Liam + technical-director (Q6). |

## Ý kiến về §9.9 và các sửa của economy-designer

- **BREAK-1 (Continue B vs MON-11):** đồng ý chẩn đoán, chỉ đồng ý cách sửa với điều kiện của dòng #2 (áp cho mọi người, có MON-13). Nếu sim không đạt, mình chọn **Continue hồi 25% ở A6+** hơn là nâng heavy A6 lên 58. Lý do: viết nó thành một luật Ascension ("từ A6, Second Wind chỉ hồi 25%") thì đọc được, khớp cách Ascension làm khó (luật đổi theo level), vẫn là Continue kiểu B, và không làm game dễ đi cho mọi người. Nâng heavy A6 thì ngược với "thật khó".
- **BREAK-2 (bỏ T2b):** đồng ý.
- **BREAK-3 (Land 14,2 tuần):** đồng ý chấp nhận theo quyết định 4 của Liam, chỉ theo dõi.
- **BREAK-4 (VIP):** đồng ý Continue 1/run giá −25% và Boon 1/ngày. Thêm: bỏ chào Moon Card ở màn thua (#9).
- **BREAK-5:** đồng ý cả ba số (880, 3.700, Kit 40).
- **BREAK-6 (A10 trần 4):** đồng ý. A10 là đỉnh kỹ năng; trần 4 giữ được ý nghĩa đó.
- **BREAK-7 (cờ đỏ casual A0 < 36%):** đồng ý.
- **R10 để v1.1:** đồng ý. Ít một nút trong trận là đỡ một chỗ người chơi cảm thấy bị chào bán giữa lúc căng. R2 đã trả lời spike.

## Nhận xét về danh mục và store (mức cao)

- Danh mục đủ, không thiếu sản phẩm hiển nhiên nào. Chỗ thừa: Boon đến từ năm nguồn (R8, Kit, VIP, Starter, mercy). Không sai, nhưng nên có một trang "Boon là gì" để người chơi không thấy rối.
- Thứ tự triển khai (R1 → VIP → Pass → …) hợp lý, nhưng Pass premium nên chờ khi kho cosmetic đủ. Theo REVIEW cosmetics-01 của art-director, khung đang REJECT 5/21. Store không nên mở trước khi có lịch nội dung (OQ-16).
- Gem tiers (bonus ≤ 18,8%), Pass 880, Moon Card 4,99, Starter 0,99, cosmetic 150–1.800 Gem: đều trong mức thường gặp, không có gì lạ. Chỉ có T5/T6 lệch nhau (#15).
- Doanh thu 3.168 USD/tháng/1k DAU: chấp nhận được làm số tham chiếu, nhưng 42,8% Gem chảy vào Aid, nghĩa là doanh thu phụ thuộc trực tiếp vào độ ức chế. Đó là lý do MON-14 cần có.

## Ý kiến về các câu hỏi mở

| # | Ý kiến của mình |
|---|---|
| OQ-15 | Đồng ý economy: chấp nhận, giữ 15%, theo dõi "% đạt LunaLanding trong 6 tháng". |
| OQ-16 | Có, và là điều kiện mở store: lịch cosmetic ít nhất 2 mùa trước khi bán cosmetic trực tiếp. |
| OQ-17 | Có, 120 Gem/mùa trên Pass free (ở một mốc giữa track, không phải hàng ngày). Người không trả tiền cần chạm vào Aid ít nhất một lần mỗi mùa thì hệ thống mới thấy là của chung, không phải của người nạp. |
| OQ-18 | Chưa chấp nhận như đang viết. Phải gộp với `ascension-v2` §5.1 thành một bảng trước (#1). |
| OQ-19 | Chỉnh boss trước (áp cho mọi người, MON-13). Nếu không đạt: Continue 25% ở A6+, viết thành luật Ascension. |
| OQ-20 | Bỏ T2b. |
| OQ-21 | Đồng ý, cộng thêm bỏ chào Moon Card ở màn thua. |
| OQ-22 | Đồng ý giá bộ; sửa lệch giá T5/T6 (#15); T6 luôn có trong store (#16). |
| OQ-23 | Giữ, nhưng cho Continue miễn phí rơi vào **lần thua đầu ở boss hoặc elite** (A0–A2), không phải lần thua đầu bất kỳ, và không trong run hướng dẫn. Mẫu thử phải rơi đúng khoảnh khắc "suýt" thì mới dạy được giá trị của Continue. |
| OQ-D | Giữ trần 8, A10 trần 4, R10 để v1.1. Thêm luật Kit tính trần (#8). |
| OQ-1 | Tên khác hẳn chủ đề trăng (#17). |
| OQ-3 | Không bán Stone ở v1. Đồng ý. |
| OQ-4 | Một bảng + biểu tượng Aid từng dòng + lọc Pure. Với bảng công ty, cân nhắc Pure là tab mặc định (#12). |
| OQ-6 | Cho dùng Aid ở A10, vẫn nhận danh hiệu A5/A10. Thêm một dấu "Pure" nhỏ trên danh hiệu nếu run đó không dùng Aid. Rẻ, không chia cộng đồng, và giữ lại tín hiệu kỹ năng cho nhóm người chơi giỏi, cũng là nhóm hay giới thiệu game cho người khác nhất. |
| OQ-7 | Cho Continue ở boss cuối, giá ×2. |
| OQ-9 | Đồng ý, pháp lý chốt. |
| OQ-10 | Chờ mùa 2 (cosmetic chưa đủ). |
| OQ-11 | Không quảng cáo ở v1. |
| OQ-12 | Có. Là cổng trước khi **mở** store, không phải cổng trước khi thiết kế. |
| OQ-13 | Giữ T6. |
| OQ-14 | Đưa lại cho Liam + technical-director: game đang là web (#20). |

## Liam cần quyết

1. **Bảng win rate nào là gốc** (#1): gộp vào `ascension-v2` §5.1 và dàn đều độ rớt (regular A6 lên ~30%, tính lại MON-11), hay nới luật bước Ascension lên ≤ 7 điểm để giữ bảng §9.4 và chấp nhận A3–A6 dốc hơn.
2. **Dự phòng BREAK-1** (#2, OQ-19): nếu chỉnh boss không đủ, Continue hồi 25% từ A6 (mình khuyến nghị) hay nâng heavy A6. Và duyệt MON-13.
3. **Ranked và ECO-13** (#4): bỏ ECO-13 cho unlock meta tính trong ranked (mình khuyến nghị), hay giữ và làm Pure mặc định.
4. **Giai đoạn học luật cho người mới** (#10): attrition và clock A0 chỉ bật sau run thắng đầu tiên hoặc sau 5 run. Đây là chỉnh nhỏ cho OQ-E của Liam.
5. **R6 coupon** (#7): đổi thành làm mới hàng shop (mình khuyến nghị), hay giữ giảm giá và sửa câu MON-2.
6. **Kênh thanh toán v1** (#20): web hay Steam, và hỏi pháp lý Sky Mavis trước khi mở store (OQ-12).
7. **Pass premium mùa 1 hay mùa 2** và **120 Gem/mùa cho người không trả tiền** (OQ-10, OQ-17).

Các mục còn lại (#3, #5, #6, #8, #9, #11, #13–#19) là việc sửa doc hoặc thêm vào cổng sim, game-designer/economy-designer tự làm được sau khi Liam duyệt.
