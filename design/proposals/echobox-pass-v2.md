Trạng thái: ĐỀ XUẤT — chờ Liam review

> **QUYẾT ĐỊNH LIAM (10/10, sau bản sửa Dota): Echo Box TÁCH LÀM 2 PHẦN.** (1) **Hộp thường** — giữ công
> thức cũ (pool lớn, tỉ lệ cố định, pity) và dùng asset SẴN CÓ (thư viện 3D: decor, thú cưng, phụ kiện...).
> (2) **Hộp mùa** — áp dụng mô hình Dota 2 "Trove of Terror" (tỉ lệ tăng dần, quà mốc 40 lượt, đủ bộ có
> giới hạn) cho các vật phẩm CỰC HIẾM và THEO MÙA. Lý do: tối ưu hơn một hộp duy nhất.
> **QUYẾT ĐỊNH LIAM (10/10, danh sách A–D):**
> - A1 5 unlock chỉ số vào Pass S1 + vẫn bán shop + hoàn Shard cho người đã mua: ĐỒNG Ý.
> - A2 giá unlock cũ ×3 (3.450 → 10.350): ĐỒNG Ý.
> - A3 Pass 8 tuần, các mùa nối liền: ĐỒNG Ý — **thêm vòng lặp mốc sau level 30 để nhận thêm một phần
>   nhỏ Shard (giống LoL)**.
> - A4 XP dư sau level 30: KHÔNG bỏ — dùng cho vòng lặp mốc kiểu LoL ở A3.
> - A5 "Việc tuần" của Pass tách khỏi Nhiệm vụ cược: TÁCH.
> - A6 tài khoản mới tặng 3 vé, không tặng vé ngày: ĐỒNG Ý.
> - A7 cosmetic độc quyền Season 1 quay lại Echo Box từ mùa 3 (huy hiệu "Season 1"): CHO QUAY LẠI.
> - A8 ngày không chơi vẫn mua vé: ĐỒNG Ý.
> - A9 guest: Stone thưởng ngày chờ 7 ngày, cấp khi đăng nhập: ĐỒNG Ý.
> - A10 Echo Market (sink Shard cho người cày): HOÃN.
> - A11 vé bundle sau này có ra Stone: ĐỒNG Ý, **KHÔNG tính vào giới hạn 20 lượt/ngày**.
> - **E (tách 2 hộp):** E1 giá hộp mùa = **GẤP 5** hộp thường (không phải 3 như đề xuất) · E2 chấp nhận việc
>   người mua đủ bộ mỗi mùa lên Land chậm hơn (economy-designer tính lại mức chậm ở ×5) · E3 nhịp hộp mùa
>   **12 tuần** · E4 hộp thường giữ Mythic (decor/thú), die/frame/FX Mythic chỉ ở hộp mùa · E5 dành ~15 món
>   Epic+ của thư viện cho các mùa sau. E6 (1 nhà 2 tab?) và E7 (3 câu nhỏ): chưa trả lời.
> **Liam xác nhận (10/10):** Land tier 4 = **500.000** Land Stone (OQ-2 đã trả lời). Tổng tới LunaLanding = 1.820.000.
> **QUYẾT ĐỊNH LIAM (10/10, thêm vào tách 2 hộp): hộp mùa phải ĐẮT HƠN RẤT NHIỀU hộp thường cho mỗi lượt mở.**
> Đề xuất của game-designer: vé Mùa riêng, giá Shard gấp **3×** vé Echo ở mọi bậc (300 so với 100, cùng độ dốc 1,05), xem §2.4. Tỉ lệ 3× là con số tôi chọn, chờ Liam xác nhận (OQ-27).

# Axie Dice — Echo Box v2 (2 hộp, 2 loại vé), Battle Pass v2, Thưởng ngày

Tác giả: game-designer · 10/10/2026 · Không sửa file nào khác, không có code.
Đầu vào: khối "QUYẾT ĐỊNH CỦA LIAM SAU REVIEW" trong `economy-v2.md` và `core-loop-v2.md` (ưu tiên hơn phần thân), `cosmetics-art-request-01.md`, `ContentDB.gd` (BP_TRACK dòng 1009–1042, UNLOCKS dòng 769–786), `MetaState.gd`.
Mọi con số là first-pass, chưa qua sim. Economy-designer sẽ chỉnh số cuối (danh sách ở §8). Số nào lấy từ file cũ thì ghi nguồn.

**Bản sửa 10/10 (lần 2):** phần Echo Box được viết lại theo mô hình treasure của Dota 2 (Trove of Terror, ra 6–7/10/2026) mà Liam gửi qua ảnh Slack.
**Bản sửa 10/10 (lần 3 — tách 2 hộp):** theo quyết định mới của Liam ở đầu file, Echo Box thành **hộp thường** (công thức cũ: pool lớn, tỉ lệ cố định, pity, mảnh vé, số của `economy-v2.md`) và **hộp mùa** (mô hình Dota của lần 2, thu nhỏ cho đồ cực hiếm). Những mục đã sửa có dòng "SỬA 10/10 — tách 2 hộp" ở tiêu đề. Phần Battle Pass (§3) và Thưởng ngày (§4) giữ nguyên, chỉ đổi các dòng nhắc tới vé (Pass trả 2 loại vé) và một dòng tham chiếu mục.

---

## 0. Đọc nhanh — SỬA 10/10 — tách 2 hộp

1. **Hai hộp, hai loại vé, hai thang giá.** Hộp thường dùng `echo_ticket`, hộp mùa dùng `season_ticket`. Vé không đổi chéo, nên không ai mở nhầm hộp (§2.3). Mỗi vé có thang giá Shard riêng, reset 00:00 UTC: Echo 100 × 1,05^(k−1), tối đa 30/ngày; Mùa **300** × 1,05^(k−1), tối đa 8/ngày. **Mỗi lượt mở hộp mùa đắt gấp 3 lần hộp thường** theo quyết định mới của Liam (§2.4).
2. **Hộp thường = công thức cũ, 223 món, dùng asset 3D sẵn có.** 6 tầng Savannah → LunaLanding, tỉ lệ cố định 62 / 25 / 9,5 / 2,7 / 0,7 / 0,1%, pity 15 / 60 / 200 / 1.000, trùng đổi mảnh (10 mảnh = 1 vé). Số Land của `economy-v2.md` §3 giữ nguyên (§2.7).
3. **Hộp mùa = mô hình Dota cho đồ cực hiếm.** Series 1 chỉ 12 món (6 Epic, 3 Legendary, 2 Mythic, cộng 1 Mythic độc quyền ở lượt mở 40), tất cả là art đã đặt ở art request 01. Xác suất leo dần có trần cứng: **đủ 11 món chắc chắn trong ≤ 80 lượt mở** (điển hình ~55), Mythic đầu chắc chắn ≤ 40. Trùng: 6 món = 1 vé mùa (§2.8).
4. **Đồ trùng của hộp nào chỉ đổi vé hộp đó.** Hai vòng tách rời, mỗi vòng hồi < 1 vé mỗi lượt, không có cầu nối nên không có vòng vô hạn (§2.5).
5. **Land Stone: hộp thường là động cơ, hộp mùa gần như trung tính.** Cửa sổ 20 lượt/ngày giữ nguyên và chỉ áp cho hộp thường. Hộp mùa không cho Stone mỗi lượt, chỉ cho một khoản nhỏ một lần khi nhận món mới (S1: 9.300). Cấu trúc này giữ mục tiêu Land (heavy ~1 năm, regular ~1,5 năm, casual ~1,9 năm) trong ±3% (§2.6).
6. **Hộp mùa theo nhịp 12 tuần** (đề xuất, không cùng nhịp 8 tuần của Pass để mỗi ~4 tuần có thứ mới). Series cũ vào Vault: mở được, odds chậm gấp đôi, vẫn lấy được độc quyền (§2.10).
7. **Một tòa nhà Echo Box, hai tab** ("Thường" / "Mùa"), một thanh hiện cả hai loại vé (§2.11).
8. **Battle Pass 30 level, season 8 tuần.** Tổng 32.400 XP. XP từ run có trần theo ngày nên người chơi nặng nhất vẫn cần ≥ 14 ngày. Pass trả 12 vé mỗi mùa: 8 vé Echo + 4 vé Mùa (§3).
9. **5 unlock cộng chỉ số vào Pass ở level 4/8/12/16/20, chỉ ở Season 1.** Ai đã mua rồi được hoàn Shard. Mùa sau không còn. Ranked vẫn tắt hết (§3).

---

## 1. Nghiên cứu

> **Cập nhật 10/10:** các hàng Dota liên quan Echo Box trong bảng dưới là bản trước khi Liam gửi ảnh Slack. Bản nghiên cứu mới (Trove of Terror) nằm ở **§2.1** và áp cho **hộp mùa**. Các hàng "tái chế thành mảnh" và "LoL Hextech" vẫn là nguồn của **hộp thường** (mảnh vé, pity nhẹ). Phần LoL Event Pass cho Battle Pass vẫn dùng như cũ.

Cột "Độ tin" ghi rõ nguồn chính thức hay không. Tôi không có công cụ mở thẳng trang, chỉ có kết quả tìm kiếm, nên mọi số dưới đây là số trong snippet.

| Hệ thống | Cơ chế | Trùng | Bảo đảm | Vì sao hợp | Bài học cho ta | Độ tin / nguồn |
|---|---|---|---|---|---|---|
| **Dota 2 treasure, quy tắc không trùng** | Mở nhiều hộp cùng loại thì mỗi lần ra món khác; món đã nhận không ra lại cho tới khi nhận đủ. Món hiếm được miễn trừ | Gần như không có trùng | Không | Mở hộp luôn có cảm giác "mới" | Làm quy tắc không-lặp theo từng độ hiếm (§2.7, §2.8) | Cũ (2016), báo game: [PCGamesN](https://www.pcgamesn.com/dota/dota-2-treasure-chests-no-longer-hold-duplicate-items), [Gaming Nexus](https://www.gamingnexus.com/News/32474/Latest-Dota-2-update-removes-duplicate-treasures) |
| **Dota 2 xác suất leo thang** | Món hiếm: xác suất tăng theo số hộp đã mở; client hiện số chính xác qua mũi tên "escalating odds". Ví dụ Carmine Cascade: hộp đầu 1/20.000, hộp 23 là 1/10, hộp 50 khoảng 1/2 | Không nói | Không phải bảo đảm cứng, chỉ tăng dần | Người chơi nhìn thấy mình tiến gần hơn | Hiện bộ đếm và công bố số (§2.8) | [Kotaku](https://kotaku.com/valve-discloses-the-odds-for-its-new-dota-2-loot-boxes-1829854001) (báo, 2019); [Liquipedia Immortal II](https://liquipedia.net/dota2/Immortal_Treasure_II_2018) (wiki). Chưa kiểm được còn đúng với treasure 2026 |
| **Dota Plus: tái chế thành mảnh** | Đồ không cần đổi thành treasure fragment; 6 mảnh cùng treasure = 1 hộp nữa + 2.000 shard của Dota Plus | Trùng không chết: quay lại thành hộp | Có sàn: đủ 6 mảnh là chắc có 1 hộp | Đồ thừa vẫn có giá trị, tạo vòng lặp có đáy | Hộp thường: 10 mảnh = 1 vé, tự gộp, mảnh theo độ hiếm (§2.7) | Wiki, thứ cấp: [Fandom patch 17/10/2018](https://dota2.fandom.com/wiki/October_17,_2018_Patch), [Liquipedia Shards](https://liquipedia.net/dota2/Shards). Chưa có bài Valve gốc |
| **Dota Plus Shard Shop** | Treasure mua được bằng shard (Spring Treasure 2025: 10.000 hoặc 12.000 tùy nguồn) | — | — | Có đường mua đồ bằng tiền chơi mà không cần may | Shard → vé là đường cầm tay, không phụ thuộc may | [Liquipedia Spring Treasure 2025](https://liquipedia.net/dota2/Spring_Treasure_2025), [Hawk](https://hawk.live/posts/spring-treasure-2025-dota-2). Hai nguồn lệch nhau về giá |
| **Dota 2 Treasure of Wonders (Dark Carnival, 2026)** | 15 bộ: 11 Common, 2 Rare, 1 Very Rare, 1 Ultra Rare; gắn với tài khoản, không trade. Một blog bán hàng nói có tái chế hộp trùng để tích tiến độ nhận thưởng thêm | Có thể (chưa xác nhận) | Chưa xác nhận | Chưa rõ | Đây có thể là hệ "mới" Liam nói tới. **Tôi chưa xác minh được phần tái chế/tiến độ** | [GosuGamers](https://www.gosugamers.net/dota2/news/78685-dota-2-launches-dark-carnival-event-with-five-new-hero-personas-a-circus-themed-treasure-and-more) (báo); [blog shop](https://collectorscachegift.shop/blogs/dota-2-updates/treasure-of-wonders-guide) (KHÔNG chính thức) |
| **LoL Hextech** | Rương + chìa. Skin shard 50%, champion shard 25%, 3,6% ra 10 Mythic Essence. Không quá 3 rương liền không có skin shard; không quá 50 rương không có Mythic Essence | Trùng tách thành Orange Essence (theo giá shop, bảng số tôi chưa tìm được); đổi 3 shard lấy 1 shard mới | Pity nhẹ (3 rương, 50 rương) | Pity công khai, trùng không phí | Pity nhẹ + đồ trùng đổi thành tiền (hộp thường) | [Riot FAQ](https://support.riotgames.com/league-of-legends/rewards/hextech-crafting-faq) (chính thức, nhưng có thể đã cũ) |
| **Genshin Wish** | Hard pity 90 (5 sao); soft pity bắt đầu ~74 (nguồn lệch 74/75); 50/50 cho nhân vật nổi bật, thua thì lần sau chắc chắn; pity mang sang banner cùng loại | Trùng nhân vật cho vật phẩm nâng cấp | Hard pity + 50/50 | Biết chắc "tối đa bao nhiêu lượt" | Ta chỉ lấy hard pity, **không** làm 50/50 | [Genshin Wiki](https://genshin-impact.fandom.com/wiki/Wish) (fan wiki; vài trang khác trong kết quả là rác) |
| **CS2 case** | Tỉ lệ cố định: 79,92 / 15,98 / 3,20 / 0,64 / 0,26% (dao/găng) | Không xử lý | **Không pity**, mỗi lượt độc lập | Có thị trường để bán lại | Ta không có thị trường, nên không nên làm kiểu này | [case.oki.gg](https://case.oki.gg/cases) (trang giả lập bên thứ ba, KHÔNG chính thức) |
| **LoL Event Pass (2025–2026)** | Track miễn phí + trả phí. ~48 mốc, mỗi mốc 400–500 BXP (các nguồn lệch). XP từ thời gian trận (~1,3/phút theo một guide) và nhiệm vụ ngày/tuần (daily ~100 BXP; weekly 125–700). Mua trả phí muộn không mất phần đã đạt | — | Mục tiêu của Riot (qua guide): làm nhiệm vụ đều là xong track miễn phí trước khi hết mùa | Nhiệm vụ cố định làm "sàn" tiến độ; chơi nhiều thì nhanh hơn nhưng có điểm tựa là nhiệm vụ | Nhiệm vụ ngày/tuần + XP chơi; không bắt hardcore xong trong vài ngày (xem §3.2) | [Riot dev post](https://www.leagueoflegends.com/en-us/news/dev/dev-seasons-in-2025/) (chính thức, trước ra mắt); [loltheory](https://blog.loltheory.gg/how-to-level-battle-pass-lol/), [dodge.gg](https://www.dodge.gg/en-US/lol/news/event-pass-guide-2026), [DBLTAP](https://www.dbltap.com/posts/league-of-legends-event-pass-evolved-explained-01fywfy8nd33) (guide, số lệch nhau) |

**Những gì tôi KHÔNG xác minh được:**
- Dota 2 không thấy bản "thiết kế lại treasure 2024–2025" nào có thông báo chính thức. Cái gần nhất là Dota Plus Spring 2024 ([dota2.com](https://www.dota2.com/newsentry/4169840594114934858)) và Treasure of Wonders 2026.
- LoL **không có trần XP theo tuần** trong nguồn nào tôi đọc. "Trần để hardcore không xong trong vài ngày" ở §3.2 là thiết kế của ta, không phải bắt chước LoL.
- Chuyện người chơi LoL thích/ghét Pass: không tìm được nguồn đáng tin, tôi bỏ.

---

## 2. Echo Box v2 — SỬA 10/10 — tách 2 hộp

### 2.1 Nghiên cứu: Dota 2 "Trove of Terror" (6–7/10/2026) — nền của HỘP MÙA

Ảnh Slack của Liam (Tidehunter, huy hiệu "ARCANA PROGRESS") khớp với treasure **Trove of Terror**. Tôi chỉ có kết quả tìm kiếm (snippet), không mở được trang Liquipedia hay bài của Valve, và **không thấy bảng xác suất gốc của Valve**. Mọi thứ dưới đây là từ snippet; mức tin ghi từng dòng.

Nhãn: **[ẢNH]** = Liam nói trong ảnh Slack · **[XN]** = tôi tìm được nguồn khớp · **[SUY]** = tôi suy ra, chưa có nguồn.

| Chủ đề | Từ ảnh Slack của Liam | Đã xác nhận / lệch nguồn | Suy luận của tôi |
|---|---|---|---|
| Treasure là gì | Gacha Dota 2 mới, hero Tidehunter | **[XN]** Trove of Terror, treasure Halloween, ra 6–7/10/2026. Có Arcana đầu tiên của Tidehunter ("Maw of the Megalodon") và Arcana Drow Ranger quay lại ("Sepulchral Stalker"), cả hai là Ultra Rare. Mua đồ trong treasure không trade/không bán chợ được. [Liquipedia](https://liquipedia.net/dota2/Trove_of_Terror), [KeenGamer](https://www.keengamer.com/articles/news/dota-2-trove-of-terror-adds-tidehunter-arcana-and-returning-drow-ranger-arcana/), [TechTimes](https://www.techtimes.com/articles/328718/20261007/dota-2-trove-terror-releases-tidehunters-first-arcana-after-twelve-years.htm), [Dot Esports](https://dotesports.com/dota-2/news/tidehunter-arcana-trove-of-terror-update) | — |
| Cỡ bộ và độ hiếm | — | **[XN, một phần]** 15 bộ Immortal chia Regular / Rare / Very Rare, cộng Ultra Rare (2 Arcana), cộng skin Tormentor và Roshan. Rare: Curse of the Wyrmbender, Mesmer-Eye; Very Rare: Hell's Legion. **Số bộ Regular không chốt được** (nguồn lệch, snippet bị cắt). [Liquipedia](https://liquipedia.net/dota2/Trove_of_Terror), [AccountShark](https://accountshark.net/blog/dota-2-trove-of-terror-tidehunter-arcana-drop-rates-guide), [Offstage](https://www.offstage.gg/dota2/news/the-immortal-trove-trove-of-terror-has-been-released-in-dota-2-heres-a-look-at-all-the-sets) | — |
| Xác suất leo dần | "Escalating odds to ensure whales will not be mad" | **[XN]** Lượt mở đầu: Rare 1/2.000, Very Rare 1/20.000, Ultra Rare 1/100.000; tăng theo mỗi lượt mở, **reset khi trúng**. **Đảm bảo Ultra Rare ở lượt 50** nếu chưa có. Điểm mẫu Ultra Rare (một nguồn): ~1/105 ở lượt 20, ~1/17 ở lượt 49. [Timesaver](https://timesaver.gg/news/dota-2-trove-of-terror-tidehunter-arcana-drop-rates), [Liquipedia](https://liquipedia.net/dota2/Trove_of_Terror), [KeenGamer](https://www.keengamer.com/articles/news/dota-2-trove-of-terror-adds-tidehunter-arcana-and-returning-drow-ranger-arcana/). **Công thức đường cong thì không có nguồn nào cho đủ** | Đường cong của ta (§2.8) là công thức đóng do tôi chọn, không phải bản chép của Valve |
| Đảm bảo là gì | — | **[XN]** Bảo đảm là của **cả tầng Ultra Rare**, không phải riêng Tidehunter (có 2 Arcana chung tầng). [AccountShark](https://accountshark.net/blog/dota-2-trove-of-terror-tidehunter-arcana-drop-rates-guide), [Too Lazy Panda](https://toolazypanda.com/dota-2-tidehunter-arcana-maw-of-the-megalodon-is-here/) | Ta làm mạnh hơn Dota: series hữu hạn + không-lặp nên **cả bộ** chắc chắn đủ trong ≤ B lượt |
| Món độc quyền ở lượt 40 | "Exclusive items after 40 chest opens" | **[XN]** Mở 40: skin Roshan "R'shan the Eternal" + courier Baby R'shan. Mở 12: skin Tormentor "Obscene Eye Ball". [Liquipedia](https://liquipedia.net/dota2/Trove_of_Terror) | Mốc 12 là phụ, ta lấy làm danh hiệu nhỏ (§2.9) |
| Tái chế đồ trùng | "Recycle 6 to open 1 chest" | **[XN]** Tái chế 6 bộ từ treasure này nhận lại 1 treasure. [KeenGamer](https://www.keengamer.com/articles/news/dota-2-trove-of-terror-adds-tidehunter-arcana-and-returning-drow-ranger-arcana/), [Liquipedia](https://liquipedia.net/dota2/Trove_of_Terror). **Chưa rõ 6 bộ có phải cùng độ hiếm không** | Ta chọn đơn giản: 6 món trùng bất kỳ = 1 vé mùa |
| "Arcana Progress" | Huy hiệu trên hero | **Không có nguồn chữ nào nhắc.** Gần nhất: bộ đếm tới mức đảm bảo Ultra Rare | **[SUY]** Đây là giao diện của bộ đếm escalating-odds cho Arcana. Cần Liam xác nhận (OQ-13) |
| Giá / "$250" | "$250 cho tất cả, đáng tiền" | **[XN, lệch]** Giá hộp ~$4,70–5 (Valve không công bố trong bài). Một số báo (Hotspawn/RDY) nói ~50% có Tidehunter Arcana sau 40 hộp, ước $200–250. Con số 50% **không khớp** điểm mẫu của Timesaver, tôi coi là chưa chắc. [Hotspawn](https://www.hotspawn.com/dota2/news/dota-2-trove-of-terror-fans-mad), [RDY](https://rdy.gg/en/dota2/news/tidehunter-arcana-trove-of-terror-dota-2) | — |

**Cái ta lấy và cái ta không lấy (cho hộp mùa):**

| Lấy từ Dota | Ta làm thế nào |
|---|---|
| Bộ hữu hạn theo chủ đề (series) | Series 1 = 12 món, 3 độ hiếm (Epic / Legendary / Mythic) |
| Escalating odds + reset khi trúng + trần cứng | Công thức đóng, mọi tầng có trần N (§2.8) |
| Món độc quyền ở lượt 40 | `die_m_moon` (§2.9) |
| Tái chế 6 → 1 | Bộ đếm trùng, 6 → 1 vé mùa (§2.5) |
| Huy hiệu tiến độ trên hero | Thanh "Lunar" trên tab Mùa (§2.9) |
| **Không lấy:** không trade/gift | Giữ: gắn tài khoản, không chuyển, không bán |
| **Không lấy:** bảo đảm chỉ ở tầng, không bảo đảm món cụ thể | Ta bảo đảm cả bộ vì bộ nhỏ và có no-repeat |
| **Không lấy:** không công bố đường cong | Ta công bố công thức và bộ đếm |

### 2.2 Hai hộp, một cái nhìn — vì sao tách

| | **Hộp thường** (Echo Box) | **Hộp mùa** (tên tạm "Season Box") |
|---|---|---|
| Vai trò | Động cơ Land Stone + sưu tầm rộng: decor, thú cưng, phụ kiện, tòa nhà, danh hiệu, dice/khung/FX bậc thấp | Mục tiêu "đủ bộ" có hạn: ít món, rất đẹp, theo mùa |
| Công thức | Công thức cũ: tỉ lệ cố định + pity cứng 15/60/200/1.000, không-lặp theo tầng | Mô hình Dota: xác suất leo dần có trần cứng, mốc 12/40, đủ bộ có giới hạn |
| Pool | 223 món, cố định, không hết hạn | 11 món + 1 độc quyền mỗi series, series 12 tuần |
| Nguồn art | Asset 3D sẵn có + 19 món dice/khung/FX bậc thấp đã giao ở art request 01 | 12 món bậc cao từ art request 01 (S1), series sau theo §2.10 |
| Vé | `echo_ticket`, 100 Shard, ≤ 30/ngày | `season_ticket`, **300 Shard (3× Echo)**, ≤ 8/ngày |
| Trùng | Mảnh 1/2/5/15/40/100, 10 mảnh = 1 vé Echo | 6 món trùng = 1 vé Mùa |
| Land Stone | **Có mỗi lượt**, 20 lượt đầu/ngày | **Không** mỗi lượt; một khoản nhỏ một lần khi nhận món mới |
| "Xong" là khi nào | Không có điểm dừng (tầng thấp đủ trong vài tuần, tầng cao dài tới năm sau) | Có điểm dừng: ≤ 80 lượt, chi phí trần công bố được |

**Vì sao tách là tốt hơn một hộp (MDA):**
- Mục tiêu cảm xúc khác nhau. Hộp thường nhắm **khám phá và sưu tầm kéo dài** (Explorer/Achiever): "lần nào mở cũng có thể ra thứ mới, và Land lớn dần". Hộp mùa nhắm **thử thách có đích** (Achiever): "tôi biết cần tối đa bao nhiêu lượt và tôi sẽ có được nó". Một hộp duy nhất không làm được cả hai: pity cứng 1.000 làm đồ hiếm không "chắc", còn trần 100 lượt làm hộp cũ hết lý do tồn tại.
- Dota treasure thật cũng là hai thứ: tầng thường (hộp, mua nhiều) và tầng Arcana (hiếm, có bảo đảm).
- **Bảo vệ kinh tế Land.** Số của `economy-v2.md` (51,6 / 77,9 / 98,3 tuần tới LunaLanding) tính cho hộp thường. Tách ra thì hộp thường giữ nguyên số, còn hộp mùa là phần cộng thêm đo được (§2.6), thay vì xáo trộn cả bảng.
- **Chi phí nội dung rõ hơn.** Hộp mùa cần món mới mỗi mùa (rủi ro §2.10). Hộp thường dùng thư viện sẵn có nên không phụ thuộc pipeline art.

**Rủi ro tôi thấy và cách giảm:** (1) Hai hộp cạnh tranh một ví Shard (§2.6): chấp nhận như một lựa chọn có chủ đích, đã tính tác động. (2) Người chơi không biết mở hộp nào: một tòa nhà, hai tab, hai vé khác màu (§2.11). (3) Hộp thường có Mythic (decor/thú) làm loãng chữ "cực hiếm" của hộp mùa: Mythic ở hộp thường **không bao giờ** là dice/khung/FX/aura (§2.7, OQ-23).

### 2.3 Vé, bộ đếm trùng, quà khởi đầu

Hai loại vé, hai bộ đếm trùng, hoàn toàn tách nhau.

| | `echo_ticket` (Vé Echo) | `season_ticket` (Vé Mùa) |
|---|---|---|
| Mở được | Hộp thường | Hộp mùa, series nào cũng được (Active hoặc Vault, chọn lúc mở) |
| Hết hạn | Không | Không (giữ sang series sau và Vault) |
| Số lượng | 0–999 | 0–999 |
| Nguồn | mua Shard, đổi mảnh, Pass, quà khởi đầu, bundle (sau này) | mua Shard, đổi 6 trùng, Pass, quà khởi đầu, bundle (sau này) |
| Bộ đếm trùng | `echo_fragments` 0–9 (10 mảnh = 1 vé) | `season_dupe_count` 0–5 (6 trùng = 1 vé) |
| Chuyển / bán / đổi lại Shard | Không | Không |

- Mỗi vé lưu tag `origin` (`shard`, `recycle`, `pass`, `starter`, `bundle`) để kế toán và tách bundle sau này. Hành vi mở giống nhau mọi origin, trừ giá bậc thang (chỉ vé mua bằng Shard tính vào bậc).
- **Vé không đổi chéo:** vé Echo không mở được hộp mùa và ngược lại. Đây cũng là cách không ai mở nhầm hộp (§2.11).
- Quà khởi đầu: tài khoản mới nhận **3 vé Echo + 1 vé Mùa** (bản trước là 3 vé chung). Vé Mùa đầu tiên cho người mới nếm hộp mùa mà không phải hiểu ngay chuyện giá.

**Vì sao hai loại vé thay vì một (khuyến nghị, OQ-21):**

| | A. Hai loại vé (đề xuất) | B. Một loại vé, chọn hộp lúc mở |
|---|---|---|
| Kế toán | Sổ riêng, đo từng hộp | Phải suy ra mỗi vé đi hộp nào |
| Giá | Mỗi hộp một giá và trần riêng | Hai hộp cùng giá: hộp mùa quá rẻ hoặc hộp thường quá đắt |
| Chống nhầm | Vé quyết định hộp | Phải xác nhận mỗi lần |
| Bundle sau này | Bán riêng từng loại (hộp mùa có trần công bố được, §2.14) | Chỉ một bundle, mất cơ hội làm giá riêng |
| Nhược | Hai con số trên UI | Một con số |

### 2.4 Reset theo ngày, giá bậc thang, giới hạn

Ngày = ngày UTC, server xác nhận. Tất cả reset 00:00 UTC.

| Giới hạn | Hộp thường (Echo) | Hộp mùa | Để làm gì |
|---|---|---|---|
| Vé **mua bằng Shard** tối đa mỗi ngày | 30 | 8 | Chặn người thừa Shard đổ hết vào một ngày. 8 vé Mùa/ngày nghĩa là xong bộ S1 không sớm hơn ~6 ngày (§2.8) |
| Giá bậc thang | `round5(100 × 1,05^(k−1))` | `round5(300 × 1,05^(k−1))` (**3× Echo ở mọi bậc**) | Tự co giãn theo thu nhập; sáng mỗi ngày luôn rẻ. `k` đếm riêng từng loại vé |
| **Cửa sổ Stone**: số lượt đầu mỗi ngày được tính Stone | **20, chỉ hộp thường** | Không áp dụng (hộp mùa không cho Stone mỗi lượt) | Khóa tốc độ lên Land |

Không có trần số lượt mở tuyệt đối (vé giữ được thì mở được). Muốn trần thì hạ cửa sổ Stone.

Vé recycle và vé Pass không làm tăng bậc giá. Với hộp thường, chúng **có** tính vào cửa sổ Stone 20. Cửa sổ Stone là lý do recycle không phá được kinh tế: dù hồi thêm bao nhiêu vé, Stone Echo Box mỗi ngày tối đa vẫn là 20 lượt × E.

**Bảng giá hộp thường (vé k trong ngày)** (giữ nguyên bản trước và `economy-v2.md` §3.1):

| k | 1 | 5 | 8 | 10 | 12 | 20 | 30 |
|---|---|---|---|---|---|---|---|
| Giá (Shard) | 100 | 120 | 140 | 155 | 170 | 255 | 410 |
| Tổng cộng dồn | 100 | 545 | 955 | 1.258 | 1.592 | 3.307 | 6.644 |

Công thức tổng: `C(n) = 100 × (1,05^n − 1) / 0,05`. Ví dụ `C(8) = 100 × 0,4775 / 0,05 = 955`.

**Bảng giá hộp mùa (vé k trong ngày, trần 8):**

| k | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| Giá (Shard) | 300 | 315 | 330 | 345 | 365 | 385 | 400 | 420 |
| Tổng cộng dồn | 300 | 615 | 945 | 1.290 | 1.655 | 2.040 | 2.440 | 2.860 |

Công thức tổng: `C_s(n) = 300 × (1,05^n − 1) / 0,05 = 6.000 × (1,05^n − 1)`. Ví dụ `C_s(6) = 6.000 × 0,3401 = 2.041`; `C_s(8) = 6.000 × 0,4775 = 2.865` (cộng giá làm tròn 2.860).

**Tỉ lệ giá hộp mùa : hộp thường — đề xuất 3× (quyết định của Liam: "đắt hơn rất nhiều"; OQ-27).** Cùng độ dốc 1,05 nên tỉ lệ là 3× ở **mọi bậc** (vé 1: 300/100; vé 6: 385/125; vé 8: 420/140), và chi phí thật mỗi lượt khi mua 6 vé/ngày là ~340 so với ~113 Shard. Vì sao 3× (không 2×, không 5×):

| Tỉ lệ | Base | Chi phí xong Series 1 (điển hình / trần) | Phần Shard của regular trong 12 tuần | Đánh giá |
|---|---|---|---|---|
| 1,5× (bản trước) | 150 | ~7.500 / ~11.000 | ~8% | Không còn "đắt hơn rất nhiều" |
| 2× | 200 | ~10.000 / ~14.700 | ~11% | Đắt hơn nhưng chưa rõ ràng |
| **3× (đề xuất)** | **300** | **~15.000 / ~22.000** | **~17%** | Đắt rõ ràng; trần công bố còn bằng ~3 tuần thu nhập regular rải trên 12 tuần, người chơi vẫn xong được bộ |
| 5× | 500 | ~25.000 / ~37.000 | ~29% | Xong bộ là cả một cuộc đầu tư; Land của người xong bộ chậm ~15–20% (xem §2.6), mục tiêu Land vỡ |

Lý do chọn 3×: (a) hộp mùa **không cho Stone mỗi lượt**, nên giá cao không bị đọc là "mua Land đắt"; nó là giá của độ hiếm và của việc chắc chắn đủ bộ. (b) Một món hộp mùa là Epic+ cực hiếm, tương đương tầng 2,7% trở lên của hộp thường, mà vé Mùa lại chắc chắn đủ bộ ≤ 80 lượt. (c) 5× đẩy chi phí vượt khả năng của casual/regular trong một mùa, mà Shard dư của heavy (~5.000/tuần) cũng chỉ hút được một phần. (d) 3× còn giữ trần giá công khai (≈ 69 vé × giá vé) ở mức dễ nói với người chơi. Núm `season_ticket_price_base` (khoảng an toàn 200–500) là chỗ Liam đổi tỉ lệ; mọi con số tiền trong file này tính theo 300, đổi núm thì nhân tỉ lệ.

**Cách đọc "đắt hơn mỗi lượt":** có hai cách đạt được và tôi dùng cả hai: (1) vé riêng có thang giá riêng (không phải chọn hộp lúc mở, nên không ai dùng nhầm vé rẻ cho hộp đắt); (2) giá base cao hơn 3×, **không** làm vé Mùa "khan hiếm" bằng cách giới hạn cứng. Trần mua 8 vé/ngày là chỗ giữ nhịp, không phải để làm đắt.

**Vì sao hai thang giá riêng, không chung một `k` (OQ-21):** thang chung làm vé Echo đầu ngày đắt lên nếu đã mua vé Mùa, rối và làm "sáng mỗi ngày luôn rẻ" mất ý nghĩa. Thang riêng cho người chơi chia ví hai chỗ rẻ hơn một chút so với một thang chung (mua 6 Echo + 2 Mùa trong ngày tốn ~1.295 Shard cho 8 vé, so với 955 cho 8 vé Echo thuần: chênh vì vé Mùa đắt gấp ba). Phương án còn lại: một thang chung `k`, hộp mùa nhân 3.

**Chi phí cả Series 1 mùa (xem bound ở §2.8):**
- Điển hình ~55 lượt mở, ~48 vé mua (đã trừ ~7 vé hoàn từ trùng), trong đó 4 vé Pass ⇒ ~44 vé mua bằng Shard. Mua 6 vé/ngày (2.040 Shard/ngày) ≈ 7,3 ngày ≈ **~15.000 Shard** (7 × 2.040 + 2 vé 615).
- Trần (80 lượt mở) cần tối đa ~69 vé (đã trừ ~11 vé hoàn), tối đa ~65 mua bằng Shard ⇒ 10 × 2.040 + 5 vé 1.655 ≈ **~22.000 Shard**. Đây là con số tôi sẽ công bố trong game: "tối đa 80 lượt".

### 2.5 Đồ trùng và chứng minh không có vòng vô hạn

| | Hộp thường | Hộp mùa |
|---|---|---|
| Khi nào ra trùng | Khi tầng đó đã đủ món (quy tắc không-lặp, §2.7) | Khi tầng đó đã đủ món (§2.8) |
| Đổi gì | Mảnh theo độ hiếm: **1 / 2 / 5 / 15 / 40 / 100** (Common → Mythic) | **1 trùng** (bất kỳ độ hiếm) |
| Gộp | **10 mảnh = 1 vé Echo**, tự động, tồn dư < 10 giữ lại | **6 trùng = 1 vé Mùa**, tự động |
| Hồi tối đa / lượt mở | **ν_max = 0,265** (xem dưới) | **1/6 = 0,167** |
| Tổng lượt từ n vé | tối đa `1 / (1 − 0,265) = 1,36 n` | tối đa `1 / (1 − 1/6) = 1,2 n` |
| Ra Shard / thêm Stone | Không / Không | Không / Không |

`ν_max` của hộp thường lấy từ `economy-v2.md` §2.2: Σ tỉ lệ hiệu dụng × mảnh / 10 = 0,0602 + 0,0486 + 0,0565 + 0,0474 + 0,0360 + 0,0158 = 0,2645 ≈ 0,265. Con số này chỉ phụ thuộc **tỉ lệ**, không phụ thuộc số món, nên pool 223 món (thay vì 255) không đổi nó.

**Đồ trùng của hộp này có nuôi hộp kia không? Mặc định: KHÔNG (OQ-22).**
- Mảnh Echo chỉ ra vé Echo. Trùng Mùa chỉ ra vé Mùa.
- **Chứng minh không có vòng vô hạn.** Xét đồ thị: `echo_ticket →(mở)→ mảnh → echo_ticket` và `season_ticket →(mở)→ trùng → season_ticket`. Không có cạnh nào giữa hai vòng, và không cạnh nào quay về Shard (INV-V1). Mỗi vòng là một chuỗi hình học có tỉ số < 1: 0,265 và 0,167. Tổng lượt mở từ `a` vé Echo và `b` vé Mùa tối đa `1,36 a` và `1,2 b`, hữu hạn.
- Nếu sau này bật cầu một chiều (mảnh Echo → vé Mùa, tắt mặc định, `cross_feed = false`): ma trận hồi tam giác, bán kính phổ = max(0,265; 0,167) < 1 nên vẫn hội tụ, miễn là **không bao giờ** có cạnh ngược vé Mùa → Echo. Nhưng nó đổi `ν` đã tính trong `economy-v2.md` (một phần mảnh không về vé Echo), nên lệch mục tiêu Land. Tôi khuyên không bật ở bản đầu.
- Stone cũng bị chặn độc lập: Stone mỗi lượt chỉ có ở hộp thường, 20 lượt đầu mỗi ngày (INV-V4); Stone hộp mùa là khoản một lần mỗi món (INV-V21).

### 2.6 Land Stone: cấu trúc và mục tiêu Land

**Cấu trúc đã khóa:**

| | Hộp thường | Hộp mùa |
|---|---|---|
| Stone mỗi lượt | Theo độ hiếm: 80 / 160 / 400 / 1.000 / 2.500 / 8.000 | **0** |
| Cửa sổ 20 lượt/ngày | **Giữ nguyên, chỉ áp hộp thường** (kể cả vé recycle và Pass) | Không áp dụng |
| Stone một lần | Không | Có: nhận món MỚI của series lần đầu: Epic 250 / Legendary 600 / Mythic 2.000 / độc quyền 2.000 (S1 tổng **9.300**, 775/tuần nếu 12 tuần) |
| Trần Stone/ngày | 20 × E ≈ 3.960; server chặn 24.000 (`economy-v2.md` ECO-7) | Không cần cửa sổ: bị chặn bởi số món của series (INV-V21) |
| Trùng cho Stone | Không (đã tính trong Stone lượt mở) | Không |

**Vì sao cửa sổ 20 giữ nguyên cho hộp thường, không "chia lại" cho cả hai:** số Land của Liam (heavy ~1 năm, regular ~1,5 năm, casual ~1,9 năm) và toàn bộ `economy-v2.md` §2–§3 tính trên một động cơ Stone duy nhất là hộp thường. Để hộp thường nguyên vẹn thì mọi bảng tính còn đúng. Hộp mùa mà cũng có cửa sổ riêng sẽ làm tốc độ Land của heavy phụ thuộc hai núm, và Stone lượt mở của hộp mùa (lượt nào cũng ra Epic+) sẽ rất cao so với số lượt của nó.

**Ảnh hưởng tới mục tiêu Land (first-pass, tính tay, chưa sim):** có 3 lực, đều nhỏ.

1. **Chuyển Shard** từ vé Echo sang vé Mùa: làm giảm Stone hộp thường của ai mua vé Mùa. Casual và regular ~17–20% Shard (~1.250 Shard/tuần trong mùa 12 tuần nếu xong bộ, ~15.000 / 12, xem §2.4). Heavy dùng phần **Shard dư** ngoài cửa sổ nên không mất Stone.
2. **Stone một lần** của hộp mùa: +775/tuần nếu xong bộ (9.300 / 12 tuần).
3. **Pool hộp thường nhỏ lại** (255 → 223) nên tầng Epic+ đủ sớm hơn, trùng sớm hơn, `ν` tăng sớm hơn. Chưa tính ở đây, economy-designer tính lại (§8 mục 1).

| Persona (xong bộ mùa mỗi mùa) | Stone/tuần `economy-v2` | Mất vì chuyển ~1.250 Shard/tuần | + Stone một lần | Net | Tuần tới LunaLanding: cũ → mới |
|---|---|---|---|---|---|
| Casual | 18.041 | 1.250 × 1,881 = −2.351 | +775 | −1.576 (−8,7%) | 98,3 → ~107,7 |
| Regular | 22.987 | 1.250 × 2,065 = −2.581 | +775 | −1.806 (−7,9%) | 77,9 → ~84,6 |
| Heavy | 35.282 | 0 (dùng Shard dư) | +775 | +775 (+2,2%) | 51,6 → ~50,5 |

(1.881 và 2.065 là Stone mỗi 1.000 Shard của casual và regular ở `economy-v2.md` §3.3. Thời gian mới = thời gian cũ / (1 ± phần trăm), chưa tính lực 3.) Ai **không** mở hộp mùa thì giữ nguyên số cũ. **Hệ quả của giá 3×:** người casual/regular xong bộ mỗi mùa chậm lên Land thêm ~8–9% (quyết định của Liam làm hộp mùa đắt, nên đây là cái giá có chủ đích của việc chọn "đủ bộ" thay vì "lên Land"). Ai chỉ mở một phần (ví dụ ~1/3 ngân sách) chậm ~3%. Mục tiêu Land (±3%) chỉ còn đúng cho người không xong bộ mùa; economy-designer chọn một trong ba: chấp nhận, nâng `season_first_hit_stone` (nhân 2 = 18.600/series: net regular −4,5%), hoặc chỉnh lại tỉ lệ giá (OQ-27). Heavy nhanh hơn ~1 tuần là tác dụng phụ chấp nhận được và còn có lợi: hộp mùa và Vault là chỗ tiêu Shard dư của heavy (`economy-v2.md` OQ-2, heavy dư ~5.000 Shard/tuần), trần ~22.000 Shard mỗi series hút ~1/3 phần dư của mùa 12 tuần (60.000).

Núm cân bằng: `season_first_hit_stone` (đề xuất 250 / 600 / 2.000 / 2.000; khoảng 0–2×) để net của casual/regular về ~0%, và `season_ticket_price_base` (chi phí chuyển Shard). Economy-designer chốt.

### 2.7 HỘP THƯỜNG — pool, tỉ lệ, pity

**Pool 223 món, 6 tầng (tên biome), mỗi tầng chọn đều nhau trong tầng.** Nguồn: Echo ~255 món của `core-loop-v2.md` §6.3/§9 và `economy-v2.md` A4 (61 / 55 / 47 / 39 / 31 / 22), trừ 17 món Epic+ art mới đã chuyển sang hộp mùa (hoặc để dành), trừ ~15 món Epic+ "L" (tint/aura và skin tòa nhà) dành cho series mùa sau, cộng lại giữ nguyên 19 món art mới bậc thấp. Công thức: 255 − 36 (art mới) + 19 (art mới bậc Common/Uncommon/Rare ở lại) − 15 (dành cho mùa) = **223**.

| Danh mục (nguồn) | C | U | R | E | L | M | Tổng |
|---|---|---|---|---|---|---|---|
| Dice skin / khung / FX bậc thấp (19 món art request 01, không Mastery/Pass) | 5 | 8 | 6 | 0 | 0 | 0 | 19 |
| Decor đất: cây, đá, tile (sheet biome Savannah..LunaLanding, Atia Environment) | 14 | 10 | 8 | 6 | 4 | 3 | 45 |
| Decor nội thất / vật phẩm (HomeLand Item NFT_Item, Atia Environment/Furniture) | 16 | 14 | 12 | 9 | 7 | 4 | 62 |
| Thú cưng đi theo (Atia Character Mascot, 149 mascot) | 10 | 8 | 7 | 5 | 4 | 2 | 36 |
| Phụ kiện Axie (vũ khí / đồ cầm tay) | 8 | 6 | 6 | 5 | 3 | 1 | 29 |
| Skin tòa nhà (2 biến thể `_F_01/_02`, chỉ bậc thấp; Epic+ dành cho mùa) | 0 | 2 | 2 | 0 | 0 | 0 | 4 |
| Tint / aura Axie (chỉ bậc thấp; Epic+ dành cho mùa) | 4 | 3 | 3 | 0 | 0 | 0 | 10 |
| Danh hiệu (chữ, narrative-director) | 4 | 4 | 3 | 3 | 2 | 2 | 18 |
| **Tổng** | **61** | **55** | **47** | **28** | **20** | **12** | **223** |

Kiểm: C 5+14+16+10+8+0+4+4 = 61; U 8+10+14+8+6+2+3+4 = 55; R 6+8+12+7+6+2+3+3 = 47; E 0+6+9+5+5+0+0+3 = 28; L 0+4+7+4+3+0+0+2 = 20; M 0+3+4+2+1+0+0+2 = 12. Tổng hàng: 19+45+62+36+29+4+10+18 = 223. Mọi ô ≤ số có trong bảng §9 của `core-loop-v2.md` (ví dụ decor nội thất Mythic 4 ≤ 8, thú cưng Mythic 2 ≤ 3), phần còn lại của bảng §9 đi vào Mastery, contract và Pass.

Ghi chú nội dung (cần art-director/curate xác nhận khi chọn thật):
- Decor đất Savannah..Forest dồi dào ở sheet Environment; Mythic (LunaLanding) là đá pha lê đỏ, cây đỏ, mặt trăng (`HomeLand_Asset_Environment_LunaLanding_1`): đủ 3 món decor đất Mythic, không dư nhiều.
- Decor nội thất/vật phẩm lấy từ `HomeLand_Asset_Item_NFT_Item_1..5` (búp bê Matryoshka, gối, giỏ len, bình, ván lướt, xương rồng, tượng đá phủ rêu...). Bậc nên theo màu biome của món (băng → Arctic, đá phủ rêu → Forest/Mystic, tượng pha lê → LunaLanding).
- Thú cưng từ `Atia_Asset_DeliveryAssets_Character_1` (golem gốm, gấu) và mascot Terrarium (`NFT_Item_3`: Axie mochi nhồi bông, tượng thú). Mythic thú cưng 2 món nên có hiệu ứng đặc biệt (tuỳ `technical-artist`).
- **Mythic của hộp thường không bao giờ là dice/khung/FX/aura** (đó là danh tính của hộp mùa). Chỉ decor, thú, phụ kiện, danh hiệu.
- Món trùng giữa hai hộp: không có. Danh sách món hộp thường và mọi series mùa là rời nhau (INV-V20).

**Tỉ lệ cơ bản và Stone (giữ nguyên `economy-v2.md` §3.2):**

| Độ hiếm (biome) | Tỉ lệ cơ bản | Món | Stone/lượt | EV cơ bản | Tỉ lệ hiệu dụng (sau pity) | EV hiệu dụng |
|---|---|---|---|---|---|---|
| Common (Savannah) | 62,0% | 61 | 80 | 49,6 | 60,2% | 48,2 |
| Uncommon (Forest) | 25,0% | 55 | 160 | 40,0 | 24,3% | 38,9 |
| Rare (Arctic) | 9,5% | 47 | 400 | 38,0 | 11,3% | 45,2 |
| Epic (Mystic) | 2,7% | 28 | 1.000 | 27,0 | 3,16% | 31,6 |
| Legendary (Genesis) | 0,7% | 20 | 2.500 | 17,5 | 0,90% | 22,5 |
| Mythic (LunaLanding) | 0,1% | 12 | 8.000 | 8,0 | 0,158% | 12,7 |
| **Tổng** | **100%** | **223** | | **E_base = 180,1** | | **E_eff ≈ 198,9** |

(Cột "Món" là số mới. Tỉ lệ, Stone, EV là từ `economy-v2.md` §3.2. Các số này không phụ thuộc số món.)

**Pity: giữ 15 / 60 / 200 / 1.000 (quyết định của tôi, OQ-23).** Cứng, bộ đếm không reset theo ngày, tính cả vé recycle và Pass:
- 15 lượt không có ≥ Rare ⇒ lượt 15 chắc ≥ Rare. 60 lượt không có ≥ Epic ⇒ lượt 60 chắc ≥ Epic. 200 lượt không có ≥ Legendary ⇒ lượt 200 chắc ≥ Legendary. 1.000 lượt không có Mythic ⇒ lượt 1.000 chắc Mythic.
- Chạm hai ngưỡng cùng lượt ⇒ cấp độ cao nhất, reset các bộ đếm thấp hơn (`economy-v2.md` §3.2).

**Vì sao không đổi pity dù đồ cực hiếm đã sang hộp mùa:** (a) Mythic của hộp thường là decor/thú/danh hiệu, không phải dice/khung/FX nên không cạnh tranh danh tính với hộp mùa. (b) `E_eff` (198,9) và mọi bảng Land trong `economy-v2.md` tính với đúng bộ pity này, đổi pity là đổi cả bảng. (c) Mythic ~8 tuần một lần cho regular (78 lượt/tuần × 632 lượt/chu kỳ ≈ 8,1 tuần) vẫn là "hiếm thật" mà không vô vọng. Phương án thay thế: **chặn hộp thường ở Legendary** (Mythic chỉ ở hộp mùa), kéo theo bỏ 12 món Mythic và pity 1.000, `E_base` giảm 8,0 Stone/lượt, và LunaLanding decor không có đường nào ngoài mùa/Mastery. Tôi không khuyên vì làm hỏng thang "biome = độ hiếm" của hộp thường và đổi số Land.

**Không-lặp theo tầng:** khi mở ra tầng T mà T còn món chưa có, chỉ chọn trong món chưa có (đều nhau). Hết món chưa có thì lượt đó là **đồ trùng** (chọn đều trong tầng) và đổi mảnh. `no_repeat_until_tier_complete = true`.

**Thời gian tới khi đủ tầng (tỉ lệ hiệu dụng, số lượt mở)** — pool nhỏ lại nên Epic+ đủ sớm hơn bản 255 món: Common 61/0,602 = 101; Uncommon 55/0,243 = 226; Rare 47/0,113 = 416; Epic 28/0,0316 ≈ 886 (cũ 1.234); Legendary 20/0,009 ≈ 2.222 (cũ 3.444); Mythic 12/0,00158 ≈ 7.595 (cũ ~13.900). Hệ quả: vé hồi từ mảnh bắt đầu sớm hơn, `ν` tăng sớm hơn một chút; economy-designer tính lại (§8 mục 1).

**Không có series, không có mùa, không có Vault** ở hộp thường: một pool cố định. Món hộp thường là vĩnh viễn trong pool (trừ khi `content update` thêm món, khi đó pool lớn lên).

### 2.8 HỘP MÙA — series, xác suất leo dần, bound

Một **series** là bộ cosmetic cực hiếm hữu hạn, có tên, chủ đề, ngày bắt đầu, danh sách món cố định, **3 tầng (Epic = Mystic, Legendary = Genesis, Mythic = LunaLanding)** và **đúng một "tâm điểm" ở tầng Mythic**. Mỗi tầng có số món `n_t` cố định. Món Mastery và Pass S1 **không** nằm trong series nào (đã có nguồn riêng).

**Series 1 — "Lunar Echo" (tên tạm, narrative-director đặt tên thật).** Chủ đề: rune và mặt trăng, nối biome Mystic → Genesis → LunaLanding. 11 món trong pool + 1 món độc quyền. Tất cả là ID có sẵn trong `cosmetics-art-request-01.md`, **không cần art request mới**.

| Tầng (biome) | n | Món |
|---|---|---|
| Epic (Mystic) | 6 | `die_e_rune`, `die_e_spore`, `frame_e_runering`, `frame_e_firefly`, `fx_e_rune`, `fx_e_spore` |
| Legendary (Genesis) | 3 | `die_l_relic_stone`, `frame_l_sunburst`, `fx_l_starfall` |
| **Mythic (LunaLanding), tâm điểm "Lunar"** | 2 | **`fx_m_lunar`** (FX quăng xúc xắc, có khoảnh khắc MAX; **món chủ đạo**), `frame_m_eclipse` |
| **Tổng pool** | **11** | 6 + 3 + 2 |
| Độc quyền lượt mở 40 (ngoài pool) | 1 | `die_m_moon` (die skin Mythic) + danh hiệu |

Theo loại: dice 4 (`die_e_rune`, `die_e_spore`, `die_l_relic_stone`, `die_m_moon`), khung 4 (`frame_e_runering`, `frame_e_firefly`, `frame_l_sunburst`, `frame_m_eclipse`), FX 4 (`fx_e_rune`, `fx_e_spore`, `fx_l_starfall`, `fx_m_lunar`). 12 món, 4/4/4.

**Phân bổ cả 36 món art request 01 không thuộc Mastery/Pass:** 19 món C/U/R vào hộp thường (§2.7); 12 món vào Series 1; **5 món để dành cho Series 2:** `die_l_gold`, `die_l_kingdom`, `fx_l_sunfire` (Legendary), `die_m_redcrystal`, `frame_m_crystal` (Mythic). Kiểm: 19 + 12 + 5 = 36.

`aura_m_lunar` (ID mới ở bản lần 2) **bỏ**: không còn lý do vì Mythic thứ hai là `frame_m_eclipse` đã có art. OQ-15 xong.

**Cơ chế mỗi lượt mở (server, quyết định):**

Bộ đếm: mỗi series, mỗi tầng chưa đủ món `t ∈ {E, L, M}` có `c_t` = số lượt mở series này kể từ lần tầng đó trúng gần nhất (hoặc từ khi bắt đầu). Bộ đếm **không reset theo ngày, không reset khi tầng khác trúng**, không reset khi chuyển Vault.

Công thức (mỗi tầng chưa đủ có trần `N_t`, chung `k`):

```
F_t(c)  = (c / N_t)^k                            xác suất tầng t đã trúng trong c lượt kể từ lần trước
p_t(c)  = (c^k − (c−1)^k) / (N_t^k − (c−1)^k)    xác suất trúng ở lượt thứ c, biết các lượt trước trượt
k = 2   →  p_t(c) = (2c − 1) / (N_t² − (c−1)²)
p_t(N_t) = 1   (trần cứng)
lượt kỳ vọng tới khi trúng = Σ_{c=0..N−1} (1 − (c/N)^k) ≈ 2N/3 + 0,5 (k = 2)
```

`c` là số thứ tự của **lượt đang mở** tính từ lần trúng trước (lượt đầu sau khi trúng là `c = 1`). Dạng đóng, ba núm (`N_t`, `k`, `b_t`), dễ test và in thành bảng cho người chơi. Giống Dota ở hình dạng (đầu rất thấp, cuối dốc đứng) nhưng **không chép đường cong của Valve**.

**Thứ tự xử lý (giống bản lần 2, thu về 3 tầng):**
1. Mọi bộ đếm của tầng chưa đủ: `c_t += 1`.
2. **Bắt buộc trước:** nếu có tầng chưa đủ có `c_t ≥ N_t`, lấy tầng cao nhất trong số đó. Xong, bỏ qua bước 3.
3. Không có tầng nào đến hạn: bốc từ Mythic xuống Legendary. Tầng chưa đủ trúng với `p_t(c_t)`; tầng đã đủ trúng với `b_t` (cơ bản). Tầng đầu tiên trúng là kết quả; **không tầng nào trúng thì là Epic** (Epic là mặc định, như Common ở bản lần 2).
4. Chọn món: tầng chưa đủ → đều trong món chưa có; tầng đã đủ → đều trong tầng (đồ trùng).
5. Reset `c_t = 0` cho tầng vừa trúng (nếu tầng đó chưa đủ trước lượt này). Cộng `opens += 1`.

Điểm mấu chốt: **ở bước 2, "đến hạn" thắng ngẫu nhiên**, nên đồ trùng của tầng đã đủ không bao giờ chặn một lượt bắt buộc.

**Tham số Series 1 (mặc định, first-pass):**

| Tầng | n | Trần `N_t` | `p(1)` | `p` ở giữa trần | Lượt kỳ vọng / món | `b_t` (khi đã đủ) |
|---|---|---|---|---|---|---|
| Mythic | 2 | **40** | 0,06% | 3,15% (c = 20) | 27,2 | 1% |
| Legendary | 3 | 20 | 0,25% | 5,96% (c = 10) | 13,8 | 4% |
| Epic | 6 | 8 (lưới an toàn, vì Epic là mặc định) | — | — | ~1 (lượt không phải L/M là Epic) | 95% |

`k = 2`, mọi `N_t ≥ 6`.

**Bảng mẫu: tầng Mythic (`N = 40`, `k = 2`).**

| Lượt kể từ lần trúng (c) | Xác suất ở lượt này `p(c)` | Tích lũy `F(c)` = chắc đã có Mythic |
|---|---|---|
| 1 | 0,06% (1/1.600) | 0,06% |
| 10 | 1,25% | 6,25% |
| 20 | 3,15% | 25,0% |
| 30 | 7,77% | 56,3% |
| 35 | 15,5% | 76,6% |
| 39 | 49,4% | 95,1% |
| 40 | **100%** | **100%** |

Kiểm tay: `p(10) = 19 / (1.600 − 81) = 19 / 1.519 = 1,25%`; `p(30) = 59 / (1.600 − 841) = 59 / 759 = 7,77%`; `p(39) = 77 / (1.600 − 1.444) = 77 / 156 = 49,4%`; `p(40) = 79 / (1.600 − 1.521) = 79/79 = 1`. Lượt kỳ vọng: `40 − (39·40·79)/(6·1.600) = 40 − 12,84 = 27,2`.

**Bound cứng cho cả bộ.** Gọi `h_t` = số tầng cao hơn t (Mythic 0, Legendary 1, Epic 2). Lượt trúng kế của tầng t xảy ra không muộn hơn lượt trúng trước + `N_t + h_t`: tầng đến hạn sau tối đa `N_t` lượt, và chỉ bị chặn bởi các tầng cao hơn cũng đến hạn đúng lúc đó, mỗi tầng cao hơn chặn tối đa một lần (vì sau khi nó trúng bộ đếm về 0 và `N_t > h_t`). Vậy:

```
B(t) = n_t × (N_t + h_t)
Mythic 2×40 = 80 · Legendary 3×21 = 63 · Epic 6×10 = 60
B = max = 80 lượt mở
```

**Series 1 chắc chắn đủ cả 11 món trong ≤ 80 lượt mở, và Mythic đầu tiên trong ≤ 40.** Điều kiện của chứng minh: mọi `N_t ≥ 6`, `k ≥ 1`, bước 2 ưu tiên tầng đến hạn (INV-V14).

**Bản "xem lại bound khi bộ nhỏ và cao cấp" (yêu cầu của Liam):**
- Bản lần 2 (25 món, 6 tầng): bound 100, Mythic đầu ≤ 50. Bộ giờ chỉ 11 món cực hiếm nên 100 lượt là quá nhiều (đa số lượt trùng).
- **Mặc định mới: bound 80, Mythic đầu ≤ 40.** Điển hình **~55 lượt** (hai Mythic nối nhau ≈ 2 × 27,2 = 54,3; độ lệch chuẩn ≈ 13; hai Legendary/Epic đi song song, ước tay chưa sim). Xác suất xong trước lượt 40 ≈ 15%.
- Vì sao Mythic đầu ≤ 40 (không phải 50 như Dota): bộ 2 Mythic phải xong trong ~55 lượt; nếu `N_M = 50` thì bound 100 và điển hình ~68, tiền vé phình lên ~9.500 Shard. 40 vừa với mốc 40 lượt mở (bên dưới).
- Nếu muốn bộ lâu hơn: nhân mọi `N_t` với `s`. `s = 1,25` cho `N_M = 50`, bound 100, điển hình ~68.

**Thời gian xong của người chơi (12 tuần/mùa, first-pass):**

| | Vé mùa mua/ngày | Xong bộ (điển hình ~48 vé gồm 4 vé Pass) | Shard chi |
|---|---|---|---|
| Casual (4 ngày/tuần), dành ~20% Shard | ~0,5 vé/ngày ≈ 3,7 vé/tuần | ~12 tuần (sát cuối mùa) | ~15.000 |
| Regular (7 ngày/tuần), dành ~17% Shard | ~0,5 vé/ngày ≈ 3,6 vé/tuần | ~12 tuần (sát cuối mùa) | ~15.000 |
| Heavy, mua 8 vé/ngày | 8/ngày | **~6 ngày** (không sớm hơn) | ~15.000 (từ Shard dư) |

Người thường dành ~17–20% Shard thì xong sát cuối mùa; dành ~10% thì chỉ xong ~nửa bộ và phần còn lại sang Vault (odds chậm gấp đôi); muốn sớm hơn thì dành nhiều hơn. Chi phí trần công bố được (≤ 22.000 Shard).

**Rủi ro "mệt vì trùng" (OQ-26):** Epic chỉ có 6 món, ra đủ ở ~lượt 8; sau đó mỗi lượt ~85% là đồ trùng (đổi 1/6 vé) cho tới khi Legendary/Mythic tới. Giảm bằng: hiện "Trùng n/6" và thanh tiến độ mỗi lượt, mốc 12 (danh hiệu nhỏ) và 40 rải đều. Nếu playtest thấy chán: tăng Epic lên 8 món hoặc thêm mốc 25. Chưa chốt, cần playtest.

### 2.9 Mốc 12/40 và thanh Lunar (hộp mùa)

Đếm theo **số lượt mở của từng series**, không reset, không phụ thuộc kết quả. Mỗi mốc nhận đúng một lần.

| Mốc (lượt mở series) | Thưởng | Ghi chú |
|---|---|---|
| 12 | Danh hiệu nhỏ (ID đề xuất `title_s1_echo`, narrative-director đặt tên) | Từ Dota (skin Tormentor ở 12). Không có giá trị chơi |
| **40** | **`die_m_moon`** (die skin Mythic, độc quyền Series 1) + danh hiệu `title_s1_lunar40` + Stone một lần 2.000 (tính trong 9.300) | Từ Dota (skin Roshan + courier ở 40) |
| Đủ cả 11 món | Danh hiệu `title_s1_complete` + huy hiệu "Series 1 complete" | Không thêm vé, tránh faucet |

- **Không có Stone mỗi lượt và không có vé ở các mốc.** Bản cũ cho vé ở Sổ sưu tầm (1/1/2/3 theo mốc × 6 tầng = 42 vé) vẫn bỏ vì đó là faucet vé miễn phí lớn và `economy-v2.md` không tính nó. Economy-designer có thể thêm lại sau.
- Mốc 40 rơi trước đảm bảo Mythic ở lượt 40 trong phần lớn trường hợp (xong bộ điển hình ~55): người chơi đủ kiên nhẫn nhận được một Mythic độc quyền "chắc chắn" trước khi xong bộ. Đúng tinh thần Dota (độc quyền ở 40, đảm bảo Arcana ở 50).
- `die_m_moon` là Mythic nhưng **không** thuộc pool Series 1 nên không làm lệch bound 80. Nếu Liam không muốn một món Mythic làm quà mốc, đổi sang `die_l_kingdom` hoặc một Legendary (OQ-14).

**Thanh Lunar (bản "Arcana progress" của ta, **[SUY]**, OQ-13).** Hiện trên tab Mùa và trên banner chọn vé:
- `c_M / 40` kèm xác suất lượt tiếp theo `p_M(c_M + 1)` (ví dụ "Lượt 31/40 — 8,5% lượt này — chắc chắn ở lượt 40"). Hai món tâm điểm hiện bóng mờ cạnh thanh: `fx_m_lunar` (xem trước FX khi MAX), `frame_m_eclipse` (xem trước khung).
- Khi Mythic đầu đã trúng, thanh chuyển sang Mythic còn lại, đếm lại từ 0. Khi cả hai đủ, thanh thành huy hiệu "Lunar complete".
- Hai thanh mỏng cho Legendary (`c_L / 20`) và Epic, có thể gập.
- Màu thanh đổi khi `F(c) ≥ 50%` (c = 29 với Mythic, F = 52,6%) để người chơi thấy mình đã qua nửa chặng.
- Công khai, không ẩn. Số `N_t`, `k` do server gửi cho client (client không hardcode).

### 2.10 Nhịp mùa và Vault

**Nhịp: 12 tuần (khuyến nghị; OQ-16 đã đổi).** Lý do:
- **Nguồn nội dung.** Mỗi series cần ~12 món cực hiếm. Sau S1 còn 5 món để dành + ~15 món Epic+ "L" (tint/aura Epic+ 5, skin tòa nhà Epic+ 10) lấy từ thư viện 3D = ~20 món ≈ đủ S2 và nửa S3. S3 phần còn lại và các series sau cần art request 02. 12 tuần cho ~4,3 series/năm (~52 món/năm, thư viện lo ~1,7 series đầu), 8 tuần cho ~6,5 series/năm (~78 món/năm, cần art request 02 từ tuần ~8). Rủi ro nội dung của hộp mùa là thật: tôi muốn có đệm.
- **Bóng nửa nhịp.** Pass 8 tuần, hộp mùa 12 tuần: hai lịch lệch nhau (bội chung 24 tuần), nên mỗi ~4 tuần có một "mốc mới" thay vì hai mốc trùng nhau.
- **Chi phí.** Với giá 3×, điển hình ~15.000 Shard cho 12 tuần ≈ 17–20% thu nhập; 8 tuần thì đội lên ~26–30%, quá nặng. Đây là thêm một lý do chọn 12 tuần.
- Nếu pipeline art kịp và Liam muốn nhịp nhanh thì 8 tuần (khớp Pass); khi đó chỉ cần chỉnh `series_weeks`, Stone một lần mỗi năm tăng từ ~40.000 lên ~60.000 (4,3 vs 6,5 series × 9.300).

**Series cũ vào Vault (không bị "retire").**

| | Series đang mở (Active) | Vault (series cũ) |
|---|---|---|
| Số lượng | 1 tại một thời điểm, 12 tuần | Mọi series đã kết thúc |
| Mở được bằng | Vé Mùa | Vé Mùa |
| `N_t` | mặc định (E 8 / L 20 / M 40) | **nhân 2** (E 16 / L 40 / M 80; bound 160) |
| Bộ đếm, số lượt, món đã có | Riêng từng series | Riêng từng series, giữ nguyên khi chuyển |
| Mốc 12/40, độc quyền | Nhận được | **Vẫn nhận được**; mất nhãn "Mùa n" nếu đạt sau khi mùa kết thúc |
| Stone một lần | 100% | `vault_first_hit_scale` = 0,5 (đề xuất) |
| Đếm trùng | Chung (`season_dupe_count`) | Chung |

- Khi chọn vé, người chơi chọn **một series** (mặc định Active). Mỗi lượt mở ghi vào bộ đếm của series đó.
- Series mới vào, series cũ chuyển sang Vault; không xóa gì của người chơi. Ai đang ở lượt 38/40 của Mythic vẫn giữ bộ đếm của mình (và `N_t` mới ×2 chỉ có tác dụng từ lượt sau).
- Vault chậm hơn là để series hiện tại luôn là chỗ đáng tiêu vé (đủ bộ ~55 lượt so với ~110), mà không tạo FOMO: không món nào mất vĩnh viễn vì odds Vault vẫn có trần cứng. Phần "chỉ có ở mùa đó" giới hạn ở **nhãn** và **thanh Lunar** của mùa, không phải món (OQ-17).
- Vault là chỗ tiêu Shard dư của heavy: ~44.000 Shard mỗi series cũ nếu đi hết bound (trần ×2 theo giá 3×; điển hình ~30.000). Vault cũng bù cho người chơi ít không kịp series (OQ-17).
- **Món Pass S1** (`die_e_s1_founder`, `frame_e_s1_founder`, `frame_l_sovereign`): theo OQ-12, quay lại ở **hộp mùa** từ mùa 3 với huy hiệu "Season 1" (Epic/Legendary, hợp tầng hộp mùa), không vào hộp thường.

### 2.11 UX — một tòa nhà, hai tab

**Đề xuất: một tòa nhà Echo Box (`Alchemy`/`PotionMaker` ở Land, `core-loop-v2.md` §4), hai tab "Thường" và "Mùa", một thanh vé chung phía trên hiện cả hai loại vé.** Vì sao không hai tòa nhà:

| | A. Một tòa, hai tab (đề xuất) | B. Hai tòa nhà |
|---|---|---|
| Học | Một chỗ để học, so sánh hai hộp cạnh nhau | Phải tìm hai chỗ |
| Slot Land | Một slot | Chiếm thêm slot, kéo yêu cầu Land |
| Cảm giác sự kiện | Cần banner và đồng hồ để nổi bật | Tự nổi bật |
| Chi phí làm | Một màn, hai tab | Hai màn, hai prefab |

Tôi khuyên A. Có thể thêm một "lều sự kiện" trang trí trên Land chỉ hiện trong mùa và dẫn thẳng vào tab Mùa (làm sau, không bắt buộc, OQ-25).

**Làm sao người chơi biết mở hộp nào:**
- Hai loại vé có **màu và hình khác nhau** (đề xuất: Echo xanh trơn, Mùa viền vàng có trăng), xuất hiện cùng nhau trong thanh vé, mỗi cái có số lượng.
- Mỗi tab mở đầu bằng **một dòng**: Thường: "Nhiều đồ, kiếm Land Stone, tỉ lệ cố định". Mùa: "Ít đồ cực hiếm, chắc chắn đủ bộ trong tối đa 80 lượt, còn N ngày".
- Vé nào chỉ mở được hộp đó (nút "Mở" của tab Thường chỉ dùng vé Echo): không có chuyện mở nhầm.
- Mở game lần đầu có vé Mùa chưa dùng thì có chấm đỏ ở tab Mùa; có vé Echo chưa dùng thì chấm đỏ ở tab Thường.
- Lần đầu vào tab Mùa có hộp thoại ngắn "Hộp mùa khác hộp thường thế nào" (3 dòng).

**Tab Thường:**
1. Đầu tab: số vé Echo, `echo_fragments` (n/10), giá vé Echo kế tiếp, giờ reset UTC, **"Stone hôm nay: x/20 lượt"**.
2. Bảng pool theo 6 tầng và tỉ lệ công khai, bộ đếm pity 4 ngưỡng (ví dụ "Rare chắc ở lượt 15: đã 9/15").
3. Nút **Mở 1** và **Mở 10**; thiếu vé thì "Mua đủ vé" hiện tổng Shard. Xác nhận khi giá vé kế > 2× giá vé đầu ngày.

**Tab Mùa:**
1. Đầu tab: số vé Mùa, `season_dupe_count` (n/6), giá vé Mùa kế tiếp, giờ reset UTC, **không có đồng hồ Stone**.
2. Thẻ **series Active** lớn: tên, 11 ô bóng mờ theo 3 tầng (ô đã có sáng lên), thanh Lunar, "n/11 món", "Đã mở m lượt", mốc 12/40, **đồng hồ "còn N ngày"** (hết mùa), "Tối đa 80 lượt để đủ bộ". Thẻ Vault nhỏ bên dưới, bấm để xem.
3. Nút **Mở 1** và **Mở 10** như tab Thường.

**Hiệu ứng mở:** ~1,2 giây mỗi lượt, màu viền theo độ hiếm (6 màu biome, Mythic dùng hex mà art chọn). Mở 10 hiện lưới 10 ô, mở lần lượt, có nút **Bỏ qua** hiện ngay. Không chớp sáng toàn màn hình; có biến thể Reduce flashing.

**Màn kết quả mỗi ô:** tên, tag `MỚI` hoặc `TRÙNG` (Thường: "+N mảnh (x/10)"; Mùa: "Trùng n/6", và "+1 vé" khi đủ), `+N Stone` (Thường mỗi lượt; Mùa chỉ khi món MỚI, "+250 Stone lần đầu"). Cuối màn: tổng Stone, thanh pity (Thường) hoặc thanh Lunar (Mùa) đã cập nhật; Mùa thêm "Còn ≤ X lượt tới món độc quyền" (X = 40 − opens) và "Còn ≤ Y lượt để đủ bộ" (Y = bound tính lại theo món còn thiếu).

**Màn tiến độ series (bấm vào thẻ Mùa):** lưới 11 món theo 3 tầng (món chưa có hiện bóng mờ có tên, không giấu); mỗi tầng một thanh `c_t/N_t` kèm xác suất lượt tới; danh sách mốc (12, 40, đủ bộ); bảng xác suất công khai (`F(c)` ở các c chính) và dòng "Công thức: ... (công khai)".

**Màn Vault:** mỗi series một hàng với số món, số lượt mở, thanh Lunar, nhãn "×2 odds chậm hơn".

### 2.12 Chống bực

Hộp thường: pity công khai và có bộ đếm; trùng đổi mảnh ra vé; tỉ lệ in đủ; hết vé thì mua ngay trong màn; xác nhận khi giá vé > 2× giá đầu ngày; hết cửa sổ Stone thì banner "Lượt này không có Stone".
Hộp mùa: trần cứng hiện rõ và công bố (≤ 80 lượt cho cả bộ); mỗi tầng có bộ đếm; trùng chỉ có sau khi đủ tầng và đổi vé; chi phí trần công bố; vé không hết hạn.
Chung: lỡ mất ngày không phạt (Shard, vé, bộ đếm giữ nguyên); thoát giữa lúc mở không mất kết quả vì server ghi trước khi client hiện (§2.13); vé mở nhầm không tồn tại vì vé quyết định hộp.

### 2.13 Yêu cầu server

Echo Box là faucet Stone ở quy mô 1,8 triệu, nên **kết quả mở do server cấp** (Worker, `worker/src/accounts.js`), client chỉ hiện. Nếu mở ở client thì save-scum cho Stone vô hạn. Server giữ: số vé của **hai loại**, bậc giá trong ngày **từng loại**, cửa sổ Stone (chỉ Echo), `echo_fragments`, `echo_pity[4]`, `season_dupe_count`, và cho **từng series mùa**: `opens`, `c_t[3]`, danh sách món đã có, mốc đã nhận, Stone một lần đã nhận. Server gửi cho client cấu hình hộp thường (pool, tỉ lệ, pity) và từng series (danh sách món, `N_t`, `k`, `b_t`) để client vẽ bảng xác suất mà không hardcode.

Khách (guest) mở được cả hai hộp nhưng **không nhận Stone** cho tới khi đăng nhập (`economy-v2.md` OQ-9); Stone một lần của hộp mùa chờ trong hàng như thưởng ngày (§4).

Mọi chỗ ghi qua `SaveStore`. Field mới (`echo_tickets`, `season_tickets`, `echo_fragments`, `echo_pity[4]`, `season_dupe_count`, `season_series{series_id → {opens, counters[3], owned, milestones, first_hit_paid}}`, `echo_day`, `echo_bought_today{echo, season}`, `echo_stone_pulls_today`) phải có trong `MetaState.reload_from_store()`. Field cũ `collection` (Sổ sưu tầm) vẫn bỏ.

### 2.14 Bán bundle vé sau này

Chưa có store, và tôi không thiết kế store. Vé đã được làm sạch để cắm vào sau, **cho cả hai loại**:

- Một API duy nhất `grant_tickets(n, kind, origin)` với `kind ∈ {echo, season}`. Bundle chỉ là `origin = "bundle"`. (Tùy chọn sau này: vé gắn series, `series_id`.)
- Vé bundle không tăng bậc giá và không chạm giới hạn mua bằng Shard (30 Echo, 8 Mùa).
- Vé Echo bundle **có** tính vào cửa sổ Stone 20/ngày (đề xuất, OQ-5): người trả tiền không vượt được người chơi nặng về tốc độ Land, và chỉ giúp người ít Shard bù chỗ thiếu. Vé Mùa bundle không chạm Stone mỗi lượt (không có). Lên Land không cho sức mạnh combat, nên đây là pay-to-skip cosmetic, không phải pay-to-win.
- **Hộp mùa là hàng dễ bán hợp lệ hơn:** bound cứng làm trần giá công khai: cả Series 1 chắc đủ trong ≤ 80 lượt, nên "tổng tiền tối đa để đủ bộ" tính được và công bố được (giá vé × ~69 vé). Hộp thường có pity 1.000 cho Mythic nên không có trần thấp để công bố; nếu bán vé Echo, tôi khuyên công bố tỉ lệ và pity đầy đủ (yêu cầu pháp lý theo vùng, Liam quyết khi có store). Nếu chỉ bán một loại ở bản đầu, bán vé Mùa.
- Nếu bán: công bố tỉ lệ như vé thường, không có bundle "chắc Mythic", không có vé tỉ lệ khác, giới hạn số bundle/ngày/tài khoản.

---

## 3. Battle Pass v2

### 3.1 Cấu trúc

| | Hiện tại | v2 |
|---|---|---|
| Level | 30 | 30 |
| XP mỗi level | `45 + 22(lv−1)`, tổng 10.920 | `500 + 40(lv−1)`, tổng **32.400** |
| Track | một track free | một track free; mỗi mốc có trường `track: free\|premium` để sau này thêm (không làm premium bây giờ) |
| Thưởng | 4.870 Shard, 5 unlock, 6 perk, 5 `face` chưa claim được | 4.800 Shard, 16.500 Stone, 12 vé (8 Echo + 4 Mùa), 7 cosmetic + 1 danh hiệu, 5 unlock chỉ số |
| Season | không có | 8 tuần, 4 → 12 là khoảng an toàn |

Đường cong nhẹ: level 1 cần 500 XP (khoảng 1,5 run), level 30 cần 1.660. Level đầu nhanh để có thưởng sớm (onboarding), cuối chậm hơn một chút. Tổng cộng dồn `C(L) = 480L + 20L²`, kiểm `C(30) = 14.400 + 18.000 = 32.400`.

### 3.2 XP và gating

| Nguồn XP | Quy tắc | Giá trị |
|---|---|---|
| Run | XP run như hiện tại (thắng ~506, thua ~190, probe). **Trần mỗi ngày UTC**: 1.500 XP đầu tính 100%, phần sau tính 20%, tổng XP từ run không quá **2.000/ngày** | — |
| Thưởng ngày | Run đầu tiên mỗi ngày UTC | +100 XP (đã chốt ở `economy-v2.md` §5) |
| Việc tuần (mới, 3 việc/tuần) | 3 việc đơn giản, đếm được, mỗi việc 500 XP, tổng 1.500/tuần. Việc chưa làm của tuần trước vẫn nhận được tới hết mùa, không phạt | Ví dụ: hoàn thành 5 run, thắng 2 run, chạm boss 1 lần |

"Việc tuần" là một hệ nhỏ **khác** với Nhiệm vụ cược ở `core-loop-v2.md`. Không có stake, không có mất tiền. Tôi đặt tên khác để khỏi nhầm; chỉ cần 3 thứ đếm là xong (OQ-9).

**Chơi nhiều thì nhanh hơn, nhưng có đáy.** XP mỗi ngày tối đa = trần run 2.000 + thưởng ngày 100 + việc tuần chia đều 1.500/7 ≈ 214 = **2.314**. Nên `T_min = 32.400 / 2.314 = 14,0 ngày`. Đây là công thức giữ "người chơi nặng nhất cũng ≥ 2 tuần"; đổi trần run hay tổng XP thì tính lại bằng nó.

| Persona | XP/ngày (TB) | Xong level 30 |
|---|---|---|
| Casual (4 ngày/tuần, 3 run/ngày, ~332 XP/run, làm 2/3 việc tuần) | ~772 (5.400/tuần) | ~6 tuần |
| Regular (2 run/ngày, 7 ngày) | 664 + 100 + 214 = 978 | ~33 ngày (4,7 tuần) |
| Người chỉ chơi 1 run/ngày, 7 ngày | 332 + 100 + 214 = 646 | ~50 ngày (7,2 tuần), vẫn xong trong 8 tuần |
| Hardcore (8 run/ngày, 427 XP/run) | 2.000 + 100 + 214 = 2.314 | **14 ngày** |
| Hardcore cực đoan (20 run/ngày) | 2.314 (chạm trần) | 14 ngày |

Số XP/run dùng `economy-v2.md` A4 (thắng ~506, thua ~190; 45% thắng ≈ 332, 75% ≈ 427). Hardcore 8 run/ngày = 3.416 XP thô, bị trần cắt còn 2.000.

XP dư sau level 30: bỏ (không có sink XP), để Pass không thành chỗ cày thêm. OQ-8.

### 3.3 Mốc cộng dồn XP

| Lv | 1 | 4 | 8 | 12 | 16 | 20 | 24 | 28 | 30 |
|---|---|---|---|---|---|---|---|---|---|
| XP cộng dồn | 500 | 2.240 | 5.120 | 8.640 | 12.800 | 17.600 | 23.040 | 29.120 | 32.400 |
| Ngày (regular, 978 XP/ngày) | 0,5 | 2,3 | 5,2 | 8,8 | 13,1 | 18,0 | 23,6 | 29,8 | 33,1 |

### 3.4 Đặt 5 unlock cộng chỉ số

Năm unlock: `u_reroll` (+1 reroll tối đa), `u_hp` (+3 Max HP), `u_start` (relic Common ngẫu nhiên khi bắt đầu), `u_reroll2` (+1 reroll nữa), `u_hp2` (+2 Max HP nữa). Hiện mua Shard (220/400/500/600/650). `MetaState.run_bonuses(ranked)` trả 0 khi Ranked.

Các cách đặt:

| Cách | Ưu | Nhược |
|---|---|---|
| A. Vĩnh viễn, mọi mùa, chỉ qua Pass | Đơn giản | Người vào muộn không có đường tắt; mỗi mùa lại đẻ sức mạnh vĩnh viễn |
| B. Theo mùa ("Boon"): có hiệu lực trong mùa, hết mùa mất | Không tích sức mạnh qua các mùa, người mới ngang người cũ | Người đã xong Pass bị lấy mất thứ đã nhận; cảm giác mất mát |
| **C. Vĩnh viễn, chỉ trong Pass Season 1, vẫn bán Shard (đề xuất)** | Không ai mất gì; người vào muộn mua bằng Shard (~7.100 Shard theo giá ×3 của `economy-v2.md`, ≈ 1 tuần regular); Pass S2 trở đi không còn đẻ sức mạnh | Pass S1 hơi khác các mùa sau |

Quy tắc kèm theo C:
- Ai **đã sở hữu** unlock thì mốc đó trả **Shard bằng giá shop hiện hành** thay vì cấp lại. Không ai thiệt.
- Giá Shard trong shop không đổi khi Pass phát; đây là đường dự phòng vĩnh viễn, không phải FOMO.
- Pass và shop ghi trên cùng nhãn "Không áp dụng ở Ranked", cùng một huy hiệu trên mỗi mốc có unlock.
- Đặt ở level 4/8/12/16/20, tức ngày 2,3 / 5,2 / 8,8 / 13,1 / 18,0 của người chơi thường. Người chơi 1 run/ngày vẫn có đủ cả 5 trong ~4 tuần. Thứ tự: reroll trước (nhẹ, dễ cảm nhận), HP, relic Common, rồi hai bậc cao.
- `u_start` phụ thuộc thiết kế lại relic (Liam đã xếp Relic sau Economy): nếu pool relic Common đổi, mốc này đổi theo.

### 3.5 Bảng 30 level — SỬA 10/10 — tách 2 hộp (chỉ loại vé)

Cosmetic lấy ID từ `cosmetics-art-request-01.md`. Cosmetic Season 1 (`*_s1_*`, `frame_l_sovereign`) là phần thưởng độc quyền Season 1 (ý tưởng "về sau vào Echo Box" của `core-loop-v2.md` §6.1 giữ nguyên, nhưng vào **hộp mùa** từ mùa 3, §2.10, OQ-12). Món nào đã được Pass cấp thì **không nằm trong hộp thường hay series mùa nào** (§2.7, §2.8); các món Pass trong bảng dưới cũng không nằm trong Series 1. Vé Pass chia **8 vé Echo (E) + 4 vé Mùa (M)**; thay đổi duy nhất so với bản trước là loại vé ở các hàng vé.

| Lv | XP cộng dồn | Thưởng |
|---|---|---|
| 1 | 500 | 300 Shard |
| 2 | 1.040 | 1 vé Echo |
| 3 | 1.620 | 1.000 Stone |
| 4 | 2.240 | **Unlock `u_reroll`** (+1 reroll) |
| 5 | 2.900 | `fx_c_leaf` (Dice FX Common) + 300 Shard |
| 6 | 3.600 | 1 vé Echo |
| 7 | 4.340 | 1.500 Stone |
| 8 | 5.120 | **Unlock `u_hp`** (+3 Max HP) |
| 9 | 5.940 | `frame_u_vine` (khung Uncommon) |
| 10 | 6.800 | 500 Shard + 1 vé Echo |
| 11 | 7.700 | 1.500 Stone |
| 12 | 8.640 | **Unlock `u_start`** (relic Common) |
| 13 | 9.620 | 500 Shard |
| 14 | 10.640 | 1 vé Mùa |
| 15 | 11.700 | `fx_r_bubble` (FX Rare) + 2.000 Stone |
| 16 | 12.800 | **Unlock `u_reroll2`** (+1 reroll nữa) |
| 17 | 13.940 | 500 Shard |
| 18 | 15.120 | 1 vé Mùa |
| 19 | 16.340 | 2.000 Stone |
| 20 | 17.600 | **Unlock `u_hp2`** (+2 Max HP) + 500 Shard |
| 21 | 18.900 | `die_u_moss` (die skin Uncommon) |
| 22 | 20.240 | 500 Shard |
| 23 | 21.620 | 1 vé Echo + 1 vé Mùa |
| 24 | 23.040 | 2.500 Stone |
| 25 | 24.500 | `die_e_s1_founder` (die skin Epic, Season 1) + 500 Shard |
| 26 | 26.000 | 600 Shard |
| 27 | 27.540 | `frame_e_s1_founder` (khung Epic, Season 1) |
| 28 | 29.120 | 1 vé Echo + 3.000 Stone |
| 29 | 30.740 | 600 Shard |
| 30 | 32.400 | `frame_l_sovereign` (khung Legendary) + danh hiệu "LUNACIA SOVEREIGN" + 3 vé Echo + 1 vé Mùa + 3.000 Stone |

**Kiểm tổng:**
- Shard: lv 1, 5 = 300 + 300; lv 10, 13, 17, 20, 22, 25 = 500 × 6 = 3.000; lv 26, 29 = 600 × 2 = 1.200. Tổng = 600 + 3.000 + 1.200 = **4.800**.
- Stone: 1.000 + 1.500 + 1.500 + 2.000 + 2.000 + 2.500 + 3.000 + 3.000 = **16.500**.
- Vé Echo: lv 2, 6, 10 = 3; lv 23 = 1; lv 28 = 1; lv 30 = 3. Tổng = **8**. Vé Mùa: lv 14, 18 = 2; lv 23 = 1; lv 30 = 1. Tổng = **4**. Cả hai = **12** (khớp bản trước).
- Cosmetic: `fx_c_leaf`, `frame_u_vine`, `fx_r_bubble`, `die_u_moss`, `die_e_s1_founder`, `frame_e_s1_founder`, `frame_l_sovereign` = **7** + 1 danh hiệu.
- Unlock chỉ số: **5** (lv 4, 8, 12, 16, 20).
- Tác động tới `economy-v2.md`: Pass cho −4 vé Echo, +4 vé Mùa mỗi 8 tuần so với bản chỉ có Echo (−0,5 vé Echo/tuần trên ~62,8 vé/tuần của regular, ~−0,8%). Economy-designer nhớ trừ khi tính lại (§8).

Thứ bị bỏ khỏi `BP_TRACK` cũ: 5 mốc `face` (chưa claim được), 5 mốc `unlock` không chỉ số (`u_relic1/2`, `u_face1/2`, `u_full`: relic/face đã chuyển sang "mở khi gặp lần đầu", `u_full` theo OQ-7 của `economy-v2.md`), 6 mốc `perk` (reroll/relic0/hp4/rrw: thay bằng 5 unlock ở trên, không còn cấp trực tiếp). Ai đang có perk từ Pass cũ: cần Liam quyết (OQ-7 của `economy-v2.md`), tôi không đụng ở đây.

Điều này thay đổi `t_pass_unlocks` (783 check) và 3 số liệu test: số mốc `face`, tổng Shard 4.870 và số mốc `perk`. Đây là hand-off cho phần triển khai. Hai loại vé thêm một việc cho test: tổng vé Echo 8, vé Mùa 4.

---

## 4. Thưởng ngày (UTC)

Đã chốt ở `economy-v2.md` §5. Chỉ đổi Stone sang thang mới.

| Thành phần | Điều kiện | Thưởng |
|---|---|---|
| Thưởng ngày | Hoàn thành 1 run trong ngày UTC (thắng, thua hay bỏ đều tính) | **60 Shard + 500 Land Stone + 100 XP Pass** |
| Thưởng tuần | Nhận thưởng ngày ở ≥ 4 ngày khác nhau trong tuần UTC (cộng lúc nhận lần thứ 4) | **+150 Shard + 2.000 Land Stone** |
| Phạt đứt chuỗi | Không có | — |

- Ngày UTC, **server xác nhận** (đồng hồ máy không tính). Tuần = tuần UTC, reset thứ Hai 00:00 UTC.
- Guest: nhận Shard và XP nhưng **Stone chỉ nhận sau khi đăng nhập**; chưa đăng nhập thì Stone chờ trong hàng và cấp khi đăng nhập, tối đa 7 ngày gần nhất (OQ-6).
- Stone/tuần: casual 4 ngày = 4.000, regular/hardcore 7 ngày = 5.500. Đó là ~27–30% Stone/tuần của người chơi thường, ~16% của người chơi nặng.
- Hook cho Nhiệm vụ: sẽ trả Land Stone **nhỏ** (đã giả định 300 / 500 / 1.000 Stone/tuần ở `economy-v2.md` §2.3) và Shard theo stake. Không thiết kế gì thêm ở đây.

---

## 5. Tuning knobs — SỬA 10/10 — tách 2 hộp

Gốc `assets/data/`, không hardcode. Thêm `assets/data/echo_box.json` (hộp thường: pool, tỉ lệ, pity, mảnh) và `assets/data/echo_series/<series_id>` cho từng series mùa (danh sách món, `N_t`, `k`).

**Chung cho hai hộp:**

| Núm | Mặc định | Loại | Khoảng an toàn | Lý do |
|---|---|---|---|---|
| `ticket_price_growth` | 1,05 | curve | 1,03–1,10 | Độ dốc, dùng cho cả hai thang giá |
| `starter_tickets` | 3 Echo + 1 Mùa | gate | 0–10 | |
| `cross_feed` | false | gate | bool | Cho mảnh Echo nuôi vé Mùa (một chiều). Tắt: giữ số Land của `economy-v2.md` |

**Hộp thường:**

| Núm | Mặc định | Loại | Khoảng an toàn | Lý do |
|---|---|---|---|---|
| `echo_ticket_price_base` | 100 | curve | 60–200 | Chỉnh số vé/ngày của người chơi thường (`economy-v2.md` §3.1) |
| `echo_ticket_buy_cap_day` | 30 | gate | 15–50 | Trần vé mua bằng Shard |
| `stone_window_day` | 20 | gate | 10–40 | Trần tốc độ Land theo ngày: núm quan trọng nhất |
| `base_rates` | 62 / 25 / 9,5 / 2,7 / 0,7 / 0,1 | curve | Mythic 0,05–0,2 | Tỉ lệ hộp thường |
| `stone_by_rarity` | 80 / 160 / 400 / 1.000 / 2.500 / 8.000 | curve | nhân 0,5–1,5 | Quyết định `E_base` |
| `pity_thresholds` | 15 / 60 / 200 / 1.000 | gate | Mythic 500–2.000 | Sàn cứng (`economy-v2.md` §3.2) |
| `fragments_per_ticket` | 10 | curve | 6–15 | Luôn giữ ν_max < 1 |
| `salvage_fragments` | 1 / 2 / 5 / 15 / 40 / 100 | curve | — | ν_max = 0,265 |
| `pool_items` | 61 / 55 / 47 / 28 / 20 / 12 (tổng 223) | curve | ±20% mỗi tầng | Cỡ pool; thay đổi thì tính lại ν và tuần tới Land |
| `no_repeat_until_tier_complete` | true | feel | bool | Trùng chỉ có sau khi đủ tầng |
| `stone_server_guard_day` | 24.000 | gate | 15.000–30.000 | Chỉ chặn bug (ECO-7) |

**Hộp mùa:**

| Núm | Mặc định | Loại | Khoảng an toàn | Lý do |
|---|---|---|---|---|
| `season_ticket_price_base` | **300** (= 3 × `echo_ticket_price_base`) | curve | 200–500 | Quyết định của Liam: hộp mùa đắt hơn rất nhiều. Nên lưu dạng `season_price_ratio` = 3 để đổi tỉ lệ một chỗ (§2.4) |
| `season_ticket_buy_cap_day` | 8 | gate | 4–15 | Giới hạn tốc độ xong bộ (~6 ngày) |
| `escalation_k` | 2 | feel | 1,5–3 | Độ dốc cuối; k lớn thì đầu thấp hơn, cuối dốc hơn |
| `cap_N` (E / L / M) | 8 / 20 / 40 | gate | nhân 0,7–2 (mọi `N_t ≥ 6`) | Quyết định bound `B` (§2.8) |
| `series_items` | S1: 6 / 3 / 2 (+1 độc quyền) | curve | 8–24 món | Cỡ bộ; tăng thì `B` tăng theo công thức |
| `season_base_rates` (E / L / M, khi đủ tầng) | 95 / 4 / 1 | curve | M 0,5–2 | Tỉ lệ trùng sau khi đủ tầng |
| `milestone_opens` | 12 / 40 | gate | 10–15 / 30–60 | Mốc thưởng nhỏ và độc quyền |
| `season_first_hit_stone` | 250 / 600 / 2.000 / 2.000 (E / L / M / độc quyền) | curve | nhân 0–2 | Stone một lần, S1 tổng 9.300 (§2.6) |
| `vault_cap_scale` | 2 | gate | 1–3 | Odds chậm hơn của series cũ |
| `vault_first_hit_scale` | 0,5 | curve | 0–1 | Giảm Stone một lần ở Vault |
| `series_weeks` | 12 | gate | 8–16 | Nhịp series mới (§2.10) |
| `dupes_per_ticket` | 6 | curve | 4–8 | Giống ảnh Dota; trần hồi `1/dupes_per_ticket` luôn < 1 |

**Pass, thưởng ngày:**

| Núm | Mặc định | Loại | Khoảng an toàn | Lý do |
|---|---|---|---|---|
| `land_cost[5]` | 40k / 100k / 180k / 500k / 1M | curve | — | Bậc 4 đã xác nhận 500.000 |
| `daily_shard / daily_stone / daily_xp` | 60 / 500 / 100 | curve | Stone 300–1.000 | |
| `weekly_bonus` | 150 Shard + 2.000 Stone, ≥ 4 ngày | curve/gate | 3–5 ngày | |
| `pass_xp_curve` | `500 + 40(lv−1)` | curve | tổng 25.000–40.000 | |
| `pass_run_xp_cap_day` | 2.000 (1.500 đầu 100%, sau 20%) | gate | 1.500–3.000 | Cùng công thức `T_min` ở §3.2 |
| `pass_weekly_tasks_xp` | 3 × 500 | curve | 1.000–2.000 | |
| `pass_season_weeks` | 8 | gate | 4–12 | |
| `pass_totals` | 4.800 Shard / 16.500 Stone / 12 vé (8 Echo + 4 Mùa) | curve | Stone 8.000–30.000 | |

Đã bỏ khỏi bản lần 2 (không còn dùng): `cap_N` 6 tầng, `ticket_price_base` chung, Sổ sưu tầm. Đã **khôi phục** từ bản trước Dota (vì hộp thường dùng công thức cũ): `pity_thresholds`, `fragments_per_ticket`, `salvage_fragments`.

---

## 6. Bất biến (test được) — SỬA 10/10 — tách 2 hộp

| # | Bất biến |
|---|---|
| INV-V1 | Mở vé (cả hai loại) không bao giờ cộng Shard. Sau mỗi lượt: Shard không đổi, vé của hộp đó −1 (trừ khi lượt đó hoàn vé recycle: −1 + 1) |
| INV-V2 | Vé Echo thứ k mua bằng Shard trong ngày UTC giá `round5(100 × 1,05^(k−1))`, tối đa 30/ngày. Vé Mùa thứ k giá `round5(300 × 1,05^(k−1))` (≈ 3× vé Echo cùng bậc, sai số làm tròn ≤ 5 Shard), tối đa 8/ngày. Giá vé Mùa ở mọi bậc ≥ 2,9 × giá vé Echo cùng bậc. `k` đếm **riêng từng loại**, reset 00:00 UTC; vé recycle/Pass/starter/bundle không tăng k |
| INV-V3 | Recycle tách rời, không cầu nối (`cross_feed = false`): vé Echo chỉ mở hộp thường, vé Mùa chỉ mở hộp mùa. Hộp thường: hồi tối đa ν_max = Σ tỉ lệ × mảnh/10 ≈ 0,265, tổng lượt ≤ `1,36 × số vé Echo`. Hộp mùa: mỗi lượt tối đa 1 món trùng, hồi 1/6, tổng lượt ≤ `1,2 × số vé Mùa` |
| INV-V4 | Stone mỗi lượt chỉ cho hộp thường, chỉ 20 lượt đầu mỗi ngày UTC (mọi lượt vé Echo kể cả recycle/Pass); lượt 21+ cho 0 Stone. **Hộp mùa cho 0 Stone mỗi lượt** |
| INV-V5 | **Series mùa đủ trong bound:** với mọi chuỗi RNG (kể cả RNG đối kháng "luôn trượt"), mọi món của series đều có trong ≤ `B = max_t n_t (N_t + h_t)` lượt mở (Series 1: 80); tầng t có lượt trúng thứ j trong ≤ `j × (N_t + h_t)` lượt |
| INV-V6 | Với `no_repeat = true`: không ra đồ trùng khi tầng đó còn món chưa có (cả hai hộp) |
| INV-V7 | Hộp thường: `Σ base_rates = 100%` (±0,001) và `Σ b_t × stone_t` trong 180 ± 10; Hộp mùa: `Σ season_base_rates = 100%` |
| INV-V8 | `T_min = XP_total / (cap_run + xp_daily + xp_weekly/7) ≥ 14` ngày |
| INV-V9 | Pass: tổng Shard 4.800, Stone 16.500, vé 12 (8 Echo + 4 Mùa); cộng dồn XP lv 30 = 32.400; không có perk sức mạnh cấp trực tiếp |
| INV-V10 | Mọi unlock chỉ số (từ Pass hay shop) bằng 0 khi `ranked = true` |
| INV-V11 | Ai đã có unlock thì mốc Pass trả Shard bằng giá shop, không cấp lại |
| INV-V12 | Mọi Stone-bearing claim (mở, thưởng ngày, thưởng tuần, Pass, Stone một lần) kiểm ở server; ghi qua `SaveStore`; field mới nằm trong `MetaState.reload_from_store()` |
| INV-V13 | Công thức leo dần (hộp mùa): `p_t(N_t) = 1`; `p_t(c)` không giảm theo c; `F_t(c) = (c/N_t)^k` (đối chiếu bảng §2.8 ở các c chính) |
| INV-V14 | Bước 2 (tầng đến hạn) luôn thắng bước 3 (ngẫu nhiên); mọi `N_t ≥ 6` và `k ≥ 1` (điều kiện của INV-V5) |
| INV-V15 | Bộ đếm `c_t` chỉ reset khi chính tầng t trúng; không reset khi sang ngày, đổi series hay thoát game |
| INV-V16 | Mốc 12 và 40 của series phát đúng một lần khi `opens` đạt ngưỡng, kể cả khi mở 10 lượt cùng lúc; mốc không cho vé |
| INV-V17 | Món Mastery và Pass S1 không nằm trong hộp thường hay pool series nào (trừ khi OQ-12 cho quay lại từ mùa 3); `die_m_moon` không nằm trong pool Series 1 |
| INV-V18 | Series chuyển vào Vault giữ nguyên `opens`, `c_t`, món đã có; `N_t` nhân `vault_cap_scale` chỉ có tác dụng từ lượt sau, và `c_t` không tụt |
| INV-V19 | **Pity hộp thường:** lượt 15 không có ≥ Rare ⇒ lượt 15 chắc ≥ Rare; 60 ⇒ ≥ Epic; 200 ⇒ ≥ Legendary; 1.000 ⇒ Mythic; bộ đếm không reset theo ngày, tính cả vé recycle/Pass; hai ngưỡng cùng lượt ⇒ lấy cấp cao nhất và reset các bộ đếm thấp hơn |
| INV-V20 | **Rời nhau:** không món nào nằm đồng thời trong pool hộp thường và pool một series mùa; không món nào nằm trong hai series mùa (trừ re-run OQ-12 có nhãn riêng); mọi món Mythic của hộp thường không thuộc danh mục dice/khung/FX/aura |
| INV-V21 | **Stone một lần của hộp mùa:** mỗi món MỚI của series trả đúng một lần theo `season_first_hit_stone`; tổng mỗi series ≤ `Σ n_t × stone_first_t + stone_exclusive` (S1: 9.300); món trùng trả 0; mỗi series một sổ riêng |
| INV-V22 | **Vé không đổi chéo:** mở hộp thường chỉ trừ `echo_ticket`; mở hộp mùa chỉ trừ `season_ticket`; không API nào chuyển vé giữa hai loại |

---

## 7. Câu hỏi mở cho Liam

| # | Câu hỏi | Đề xuất của tôi |
|---|---|---|
| OQ-1 | ~~"Gacha mới của Dota 2" là hệ nào?~~ **Đã trả lời qua ảnh:** Trove of Terror (6–7/10/2026), xem §2.1 | — |
| OQ-2 | ~~Bậc 4 của Land~~ Đã chốt 500.000 | — |
| OQ-3 | ~~Pity cứng hay leo dần?~~ **Đã chốt theo ảnh, nay tách theo hộp:** hộp thường pity cứng 15/60/200/1.000 (§2.7); hộp mùa leo dần có trần cứng (§2.8) | — |
| OQ-4 | ~~Không-lặp hay quay thuần ngẫu nhiên?~~ **Đã chốt:** không-lặp theo từng tầng ở hộp thường, theo series ở hộp mùa, vì bound "đủ bộ" cần nó | — |
| OQ-5 | Vé bundle sau này có tính Stone và cùng cửa sổ 20 lượt/ngày không? **Đổi:** chỉ vé Echo bundle có tính cửa sổ; vé Mùa không có Stone mỗi lượt | Vé Echo bundle tính vào cửa sổ 20, vé Mùa không chạm |
| OQ-6 | Guest nhận Stone thưởng ngày (và Stone một lần của hộp mùa) bằng cách nào? | Chờ trong hàng 7 ngày, cấp khi đăng nhập |
| OQ-7 | 5 unlock chỉ số: Pass S1 + shop + hoàn Shard (C), theo mùa (B), hay vĩnh viễn mọi mùa (A)? | C |
| OQ-8 | XP dư sau level 30: bỏ hay đổi ra vé nhỏ (mỗi 2.000 XP = 1 vé, tối đa 10/mùa)? | Bỏ |
| OQ-9 | "Việc tuần" của Pass: có tách khỏi Nhiệm vụ cược không? | Tách, 3 việc đếm đơn giản, không stake |
| OQ-10 | Quà khởi đầu và vé miễn phí mỗi ngày? **Đổi:** quà khởi đầu 3 vé Echo + 1 vé Mùa | 3 Echo + 1 Mùa; **không** tặng vé ngày (bảng thưởng ngày đã chốt, thêm vé làm Stone đi sai quy mô) |
| OQ-11 | Season dài 8 tuần? Có nối liền không? | 8 tuần, nối liền; người xong sớm thì chờ mùa sau |
| OQ-12 | Cosmetic độc quyền Season 1 (Pass) có về lại không? **Đổi:** vào hộp mùa hay hộp thường? | Có, **vào hộp mùa** từ mùa 3 kèm huy hiệu "Season 1" (Epic/Legendary hợp tầng hộp mùa) |
| OQ-13 | **"Arcana Progress" trong ảnh có phải là bộ đếm escalating-odds tới mức đảm bảo Ultra Rare không?** Không nguồn chữ nào nhắc, tôi chỉ suy ra | Nếu đúng: giữ thanh Lunar như §2.9. Nếu nó là thứ khác (ví dụ tiến độ nhiệm vụ riêng), anh mô tả thêm tôi sửa §2.9 |
| OQ-14 | Món độc quyền 40 lượt là Mythic (`die_m_moon`) hay thấp hơn? | `die_m_moon` (Mythic): đủ nặng để 40 lượt có ý nghĩa như Roshan skin của Dota. Nếu không muốn, `die_l_kingdom` |
| OQ-15 | ~~`aura_m_lunar` (ID mới) hay dùng tạm `frame_m_eclipse`?~~ **Xong:** bỏ `aura_m_lunar`, Mythic thứ hai của S1 là `frame_m_eclipse` (đã có art), không cần art request 02 cho S1 | — |
| OQ-16 | **Đổi:** nhịp hộp mùa 8 tuần (khớp Pass) hay 12 tuần? | **12 tuần**: đệm nguồn nội dung (S1 + 20 món sẵn có = ~1,7 series trước khi cần art request 02), lệch nhịp Pass cho cảm giác mới cách ~4 tuần, chi phí ~17–20% Shard (giá 3×; 8 tuần sẽ ~26–30%). Nếu pipeline art kịp thì 8 tuần |
| OQ-17 | Vault: `N_t` nhân 2 (bound 160), vẫn nhận độc quyền, hay nhân 1? | Nhân 2 và vẫn nhận độc quyền; Stone một lần ×0,5. Nhân 1 thì series hiện tại mất lý do để ưu tiên |
| OQ-18 | ~~Đồ trùng tính đồng nhất hay trọng số theo độ hiếm?~~ **Đổi:** hộp thường giữ trọng số cũ (mảnh 1/2/5/15/40/100); hộp mùa đồng nhất 6 → 1 | — |
| OQ-19 | ~~Bound cứng mặc định 100 hay 150?~~ **Đổi:** bộ nhỏ, cao cấp nên bound **80** (Mythic đầu ≤ 40, điển hình ~55); `s = 1,25` cho 100 | 80 |
| OQ-20 | **Mới.** 19 món dice/khung/FX bậc Common–Rare (đã đặt art ở art request 01, không Mastery/Pass) có vào hộp thường không? Anh nói hộp thường dùng asset sẵn có; 19 món này là art mới nhưng đã giao | Có: art đã đặt và đã trả, và hộp thường cần một ít dice/khung/FX bậc thấp để người chơi không chỉ có ở Mastery. Nếu không, 19 món đó không có nguồn nào |
| OQ-21 | **Mới.** Hai loại vé với hai thang giá riêng, hay một loại vé / một thang chung (hộp mùa nhân 3)? | Hai loại vé, hai thang riêng (§2.3, §2.4). Rõ, đo riêng được và bán bundle riêng được; vé Mùa luôn đắt gấp 3 |
| OQ-27 | **Mới, theo quyết định của Liam (hộp mùa đắt hơn rất nhiều).** Tỉ lệ giá mỗi lượt hộp mùa : hộp thường là bao nhiêu? | **3×** (300 vs 100). 2× chưa đủ "rất nhiều", 5× làm Land của người xong bộ chậm ~15–20% (§2.4). Hệ quả: người xong bộ mỗi mùa chậm lên Land ~8–9%; mục tiêu Land ±3% chỉ giữ cho người không xong bộ. Liam chọn lại tỉ lệ hoặc cho phép nâng Stone một lần |
| OQ-22 | **Mới.** Đồ trùng hộp này có nuôi vé hộp kia (một chiều Echo → Mùa) không? | **Không** ở bản đầu: giữ nguyên `ν` và số Land của `economy-v2.md`. Núm `cross_feed` có sẵn, an toàn nếu một chiều (§2.5) |
| OQ-23 | **Mới.** Hộp thường còn Mythic (12 món decor/thú/phụ kiện/danh hiệu, pity 1.000) hay chặn ở Legendary? | Giữ Mythic và pity 15/60/200/1.000. Chặn ở Legendary thì đổi số Land và LunaLanding decor mất đường |
| OQ-24 | **Mới.** Chuyển ~15 món Epic+ "L" (tint/aura, skin tòa nhà) khỏi hộp thường để dành cho series mùa sau: đồng ý không? | Có: làm nguồn cho S2–S3 mà không phải đặt art mới ngay |
| OQ-25 | **Mới.** Một tòa nhà hai tab, hay hai tòa nhà? (có thể thêm "lều sự kiện" trang trí) | Một tòa, hai tab; lều sự kiện làm sau |
| OQ-26 | **Mới.** Chống "mệt vì trùng" ở hộp mùa (Epic 6 món đủ ở ~lượt 8, sau đó ~85% lượt là trùng): giữ 6 món, tăng lên 8, hay thêm mốc 25? | Giữ 6 cho S1, đo bằng playtest, sẵn sàng tăng lên 8 |

---

## 8. Hand-off cho economy-designer — SỬA 10/10 — tách 2 hộp

Cần sim và chốt chính xác các số sau, và chỉnh `design/proposals/economy-v2.md` (§3 chỉ còn mô tả hộp thường; thêm §3b cho hộp mùa). Tôi cố ý để ở dạng "cấu trúc đã khóa, số chưa khóa".

**Khóa cấu trúc (không đổi):** hai loại vé; hai thang giá bậc thang theo ngày; cửa sổ Stone 20 chỉ cho hộp thường; hộp thường = công thức cũ (tỉ lệ cố định, pity 15/60/200/1.000, mảnh, không-lặp theo tầng); hộp mùa = series hữu hạn + không-lặp + escalating odds có trần cứng `F(c) = (c/N)^k` + mốc 12/40 + Vault; đồ trùng không đổi chéo; Stone hộp mùa chỉ một lần mỗi món; Pass 30 level với trần XP/ngày.

**Phải tune:**
1. **Pool hộp thường 223 món (61 / 55 / 47 / 28 / 20 / 12)** thay cho 255 (61 / 55 / 47 / 39 / 31 / 22): tính lại thời gian đủ tầng (Epic ~886, Legendary ~2.222, Mythic ~7.595 lượt), hệ số hồi `ν` theo tiến độ và **tuần tới LunaLanding** của ba persona. Mục tiêu giữ **51,6 / 77,9 / 98,3 tuần** (±3%). `ν_max` 0,265 không đổi (chỉ phụ thuộc tỉ lệ).
2. **`E_eff`** của hộp thường: xác nhận ≈ 198,9 bằng sim 100.000 lượt (pity không phụ thuộc số món); `E_base ≈ 180,1`.
3. **Chuyển Shard sang hộp mùa** (giả định `season_shard_share`): casual/regular ~17–20% Shard nếu xong bộ (giá 3×), heavy lấy từ Shard dư. Bảng §2.6 là điểm xuất phát (net −8,7% / −7,9% / +2,2%). Mục tiêu Land ±3% **không giữ được** cho người xong bộ ở giá 3×; chọn một: chấp nhận, nâng `season_first_hit_stone` (nhân 2: regular −4,5%), hoặc hạ tỉ lệ giá. Đề xuất mặc định 250 / 600 / 2.000 / 2.000 (S1 = 9.300). Cộng lực "pool nhỏ" ở mục 1.
4. **Tỉ lệ giá hộp mùa : hộp thường = 3× (quyết định của Liam: đắt hơn rất nhiều).** `season_ticket_price_base` 300 (= 3 × 100) và `season_ticket_buy_cap_day` 8: điển hình ~48 vé / ~15.000 Shard, trần ~22.000 Shard (Vault ~30.000 / ~44.000), người thường dành ~17–20% Shard thì xong sát cuối mùa 12 tuần, heavy không xong trước ngày 6. Sim thêm 2× và 5× (bảng §2.4) để Liam thấy đường cong. Kiểm: giá vé Mùa ≥ 2,9 × giá vé Echo ở mọi bậc; tỉ lệ chi phí mỗi lượt mở thực (kể cả vé hoàn từ trùng) ≈ 3×. Thêm vào `economy-v2.md` §3b bảng giá hộp mùa và dòng "tỉ lệ 3×".
5. **`cap_N` (E 8 / L 20 / M 40) và `escalation_k` (2):** sim 100.000 chuỗi mở Series 1: tỉ lệ 100% đủ bộ ≤ 80 lượt, trung bình ~55 (đối chiếu ước tay 54,3), Mythic đầu ≤ 40; xác suất xong trước 40 ≈ 15%. Bao gồm trường hợp bộ đếm bị tầng cao chặn.
6. **`echo_ticket_price_base` / `ticket_price_growth` / `echo_ticket_buy_cap_day`:** giữ 100 / 1,05 / 30; chỉ kiểm lại số vé/ngày sau khi một phần Shard sang hộp mùa (regular ~8,76 → ~8,0 vé Echo/ngày).
7. **Cửa sổ Stone 20 và trần server 24.000:** giữ; kiểm không có đường Stone nào mới ngoài hộp thường 20 lượt/ngày và Stone một lần.
8. **Nhịp series và Vault:** `series_weeks` 12 ⇒ ~4,3 series/năm ⇒ Stone một lần ≤ ~40.000/năm (S1 mức 9.300 × 4,3); `vault_cap_scale` 2 và `vault_first_hit_scale` 0,5 (Vault ~44.000 Shard/series ở trần, hút Shard dư của heavy). Kiểm tổng Stone một lần qua cả hành trình ≤ ~3–6% của 1.820.000.
9. **Pass:** 12 vé chia 8 Echo + 4 Mùa; trừ 4 vé Echo mỗi 8 tuần khi tính lượt/tuần; tổng Stone 16.500, 4.800 Shard; cặp (`pass_xp_curve`, `pass_run_xp_cap_day`, `pass_weekly_tasks_xp`) để `T_min` giữ ≥ 14 ngày mà persona 1 run/ngày vẫn xong trong 8 tuần.
10. **Heavy dư Shard** (`economy-v2.md` OQ-2): đo phần hộp mùa + Vault hấp thụ so với ~5.000 Shard/tuần dư.
11. `daily_stone` (500), thưởng tuần (2.000 Stone): tỷ lệ với Echo Box ~15–30% (không đổi).
12. Giá trị `u_reroll / u_hp / u_start / u_reroll2 / u_hp2` trong shop (đã đề xuất ×3 ở `economy-v2.md`): chỉnh khi Pass phát miễn phí ở S1.
13. **Số món thật mỗi series mùa:** Series 1 = 11 + 1 độc quyền (6 / 3 / 2). Các series sau cần số món khác thì `B` đổi theo công thức §2.8.
14. Land Stone sau LunaLanding vẫn chưa có sink (Liam đã nói tự tính sau).

**Đã bỏ khỏi bản lần 2, economy-designer không cần tune nữa:** bảng `cap_N` 6 tầng và bound 100, Stone một lần ≈ 23.400/series (25 món), Sổ sưu tầm cho vé (42 vé). **Đã khôi phục từ bản trước Dota:** bảng pity 15/60/200/1.000 và bảng mảnh theo độ hiếm (cho hộp thường).

---

## 9. Edge cases chính — SỬA 10/10 — tách 2 hộp

**Chung hai hộp:**
- Mở qua nửa đêm UTC: bậc giá và cửa sổ tính theo lúc server nhận yêu cầu.
- Mở 10 lượt cùng lúc: kết quả từng lượt do server cấp tuần tự, mốc và pity tính từng lượt.
- Thoát giữa lúc mở: server đã ghi, mở lại thấy kết quả.
- Vé hai loại cùng có, bấm nhầm tab: nút Mở chỉ trừ vé của tab đó (INV-V22), không có vé chung để mở nhầm.
- Hết mùa mà chưa claim Pass: vẫn claim được 7 ngày (đề xuất).
- Đã có đủ unlock từ shop khi Pass S1 phát: nhận Shard hoàn theo §3.4 (không đổi).

**Hộp thường:**
- Mua 30 vé Echo rồi mở hết: 20 lượt đầu có Stone, 10 lượt sau không; UI nói rõ trước khi xác nhận.
- Pity hai ngưỡng cùng lượt (ví dụ lượt 60 cũng là lượt 15 của chu kỳ mới): lấy cấp cao nhất, reset các bộ đếm thấp hơn (INV-V19).
- Tầng đủ món trước khi pity chạm: pity của tầng đó vẫn tính, và ra đồ trùng (đổi mảnh). Không có "pity bị hoãn".
- Mảnh tồn dư (<10) giữ qua ngày; không hết hạn.
- Mythic ra trùng: đổi 100 mảnh = 10 vé Echo; lên tối đa `1,36 n` lượt vẫn hội tụ (§2.5).
- Content update thêm món vào pool: pool lớn lên, bộ đếm không đổi; tầng đã đủ có thể "chưa đủ" lại, khi đó quy tắc không-lặp áp dụng lại.

**Hộp mùa:**
- Series đủ hết 11 món: mọi lượt là trùng, tỉ lệ cơ bản `b_t`, hồi tối đa 1/6 vé/lượt, không có vòng vô hạn.
- Hai bộ đếm đến hạn cùng một lượt: tầng cao hơn thắng, tầng thấp hơn đến ở lượt sau (đã tính trong bound, §2.8).
- Một tầng đủ sớm (ví dụ Epic ở lượt ~8): bộ đếm tầng đó dừng, tầng đó trả về `b_t` phẳng; các tầng khác vẫn leo.
- Mở 10 lượt cùng lúc băng qua mốc 12 hoặc 40: phát mốc đúng một lần, hiện trong màn kết quả.
- Người chơi đã có sẵn món của series (ví dụ khuyến mãi): món đó coi là "đã có" ngay từ đầu, không trong pool chưa có; chỉ làm bộ nhanh hơn; không trả Stone một lần cho món đó (đã có sổ).
- Đổi qua Vault giữa chừng: giữ bộ đếm; `N_t` mới (×2) chỉ có tác dụng từ lượt sau, và bộ đếm không tụt.
- Trượt liên tục: bộ đếm tăng đều và chạm trần là chắc chắn trúng; test bằng RNG ép "luôn trượt" (INV-V5).
- Vé Mùa còn dư khi hết mùa: dùng được ở Vault và series sau (không hết hạn).
- Series đủ bộ rồi mà vẫn mở: được (trùng, 6 → 1 vé), vô nghĩa về món; UI nhắc "Series đã đủ, dùng vé cho series khác".
- Mùa kết thúc khi đang ở lượt 38/40: không mất gì; hộp chuyển Vault, mốc 40 vẫn nhận được (không còn nhãn mùa).

## 10. Acceptance criteria — SỬA 10/10 — tách 2 hộp

**Tự động:**
- INV-V1..V22 pass.
- Hộp thường: sim 100.000 lượt cho `E_eff` = 198,9 ± 3%; tỉ lệ chạm pity đúng 14,2 / 12,2 / 20,2 / 36,8% (±1,5 điểm); sim 10.000 chuỗi mở từ n vé Echo cho tổng lượt ≤ `1,36 n` kể cả khi mọi lượt là đồ trùng.
- Hộp mùa: sim 100.000 chuỗi mở Series 1 cho thấy 100% đủ bộ ≤ 80 lượt (trường hợp đối kháng "luôn trượt" cũng ≤ 80) và trung bình đủ bộ trong 50–60 lượt; Mythic đầu ≤ 40 lượt; 10.000 chuỗi từ vé n cho tổng lượt ≤ `1,2 n` kể cả khi mọi lượt là đồ trùng.
- Tổng hai hộp: người chơi giả xong Series 1 mỗi mùa (~48 vé Mùa, ~15.000 Shard) đưa mỗi persona tới LunaLanding trong ±15% của 98,3 / 77,9 / 51,6 tuần (tức đủ chứa mức chậm ~8–9% của §2.6 ở giá 3×); giá vé Mùa ≥ 2,9 × giá vé Echo ở mọi bậc 1–8 (test giá); người chơi giả 20 run/ngày không xong Pass trước ngày 14 và không xong bộ mùa trước ngày 6; `t_pass_unlocks` viết lại theo §3.5 và xanh (kể cả tổng 8 vé Echo + 4 vé Mùa).

**Playtest:**
- Người mới giải thích được vì sao Stone dừng ở 20 lượt mà không cần hỏi, và biết vé nào mở hộp nào (hỏi: "vé vàng có trăng mở được hộp thường không?").
- Người chơi hiểu thanh Lunar nói gì và biết "chắc chắn ở lượt 40"; tin con số này (hỏi sau khi họ mở tới lượt 30 mà chưa có Mythic: họ có thấy yên tâm không).
- Người chơi nói được hai hộp khác nhau ở đâu sau 5 phút (đo bằng câu hỏi ngắn); ít hơn 10% người chơi mở hộp "sai" so với ý định.
- Chống "mệt vì trùng": sau lượt thứ 8–25 của Series 1, không quá 30% người chơi thấy chán (OQ-26); nếu hơn thì tăng Epic lên 8 món.
- Người chơi thường xong Pass 4–6 tuần mà không thấy bị ép chơi mỗi ngày; người chơi nặng coi trần XP ngày là hợp lý, không phải bug.
- Người chơi thường xong Series 1 trong 12 tuần mà không thấy phải bỏ rơi hộp thường (đo tỉ lệ Shard chuyển sang hộp mùa so với 17–20% giả định); người chơi thấy hộp mùa "đắt rõ ràng" (hỏi: giá vé Mùa so với vé Echo có hợp lý cho đồ cực hiếm không), không thấy bị ép.
