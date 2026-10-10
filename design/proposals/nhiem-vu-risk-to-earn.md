Trạng thái: ĐỀ XUẤT — chờ Liam review

> **QUYẾT ĐỊNH CỦA LIAM SAU REVIEW (10/10) — ưu tiên hơn nội dung bên dưới:**
> - Thứ tự làm: **Economy → Relic → Nhiệm vụ** (Nhiệm vụ thiết kế lại SAU khi economy + relic chốt).
> - **Echo Box**: reset theo NGÀY (UTC), tăng số lượt quay được nhưng hạ tương đối tỉ lệ đồ hiếm.
>   KHÔNG quay trực tiếp bằng Shard: dùng Shard **mua vé**, quay bằng vé. Cosmetic trùng **phân tách
>   thành vé** để quay tiếp. Học cơ chế gacha mới của **Dota 2** (người chơi rất hài lòng) và kết
>   hợp với các ý trên. Vé được thiết kế để sau này có thể bán bundle vé riêng (chưa có store).
> - **Land chỉ trả bằng Land Stone.** Con số hiển thị phải TO: 40.000 / 100.000 / 180.000 /
>   500.000 (Liam xác nhận 10/10) / 1.000.000. Người chơi nhiều
>   tới LunaLanding mất ~**1 năm**. Muốn lên Land nhanh thì phải chơi gacha nhiều (Echo Box là
>   faucet Stone).
> - Land Stone sink sau LunaLanding / Land Wonders: Liam tự tính sau, chưa cần.
> - **Daily**: đồng ý đề xuất. Ngày tính theo **giờ UTC**, server xác nhận.
> - **Battle Pass**: đổi đường cong XP; học **Battle Pass của LoL** — chơi càng nhiều lên càng
>   nhanh, nhưng chơi nhiều nhất cũng mất ~2 tuần mới xong. Đưa một số cosmetic vào làm thưởng Pass.
>   **5 unlock cộng chỉ số vẫn đưa vào Battle Pass được** — tinh chỉnh khéo cho hợp (Ranked profile
>   vẫn tắt chúng).
> - **Nhiệm vụ**: CÓ trả Land Stone nhưng lượng rất nhỏ. **Bỏ** hai luật thêm (lỗ ngày ≤1R, stake
>   ≤40% số dư): người chơi được phép lỗ cả 5 nhiệm vụ. Đường cong độ khó và đường cong thưởng phải
>   đi cùng nhau: muốn kiếm nhiều thì phải chấp nhận khó và bỏ nhiều tiền. Mục đích: kiểm tra người
>   chơi có chấp nhận risk to earn không.
> - Ba điều trong thiết kế Nhiệm vụ: (1) chạy trên ranked profile — đồng ý; (2) đổi tên Daily
>   Mission +60 thành "Thưởng ngày" — đồng ý; (3) save-scum — Liam chưa thấy vấn đề, đang hỏi lại.


# Nhiệm vụ (risk-to-earn) — thiết kế chi tiết

Tác giả: game-designer · 2026-10-10 · Thay thế §7 của `design/proposals/core-loop-v2.md` (bản nháp cũ). Chưa sửa file nào khác, chưa có code.
Mọi con số là first-pass, chưa qua sim. Chỗ nào chưa tự kiểm được trong code thì ghi "chưa verify". **R (Shard trung bình mỗi run) đang được đo, tôi không đoán giá trị**: mọi bảng đều ghi theo bội số của R, kèm ví dụ R=300 và R=550.

---

## 0. Đọc nhanh

1. Mua Nhiệm vụ = trả Shard (stake) trước, chơi **đúng 1 run** với một điều kiện phụ, đạt thì nhận `stake × m`, không đạt thì mất stake, không hoàn.
2. Thang: 4 bậc, stake 0.2R / 0.4R / 0.7R / 1.0R, hệ số m 1.5 / 2.2 / 3.2 / 4.0. Người chơi trung bình lỗ nhẹ, người giỏi lãi vừa, người yếu lỗ nặng nếu cố mua bậc cao, nên có thêm hàng rào chống "đuổi theo khoản lỗ".
3. Chỉ **Shard** được cược và được thưởng. Tôi khuyên Nhiệm vụ **không** trả Land Stone (lý do ở §9).
4. Muốn xác minh được thì Nhiệm vụ phải chạy trên run **ranked profile** (không unlock cộng chỉ số), seed do server cấp. Đây là ràng buộc kỹ thuật lớn nhất, xem §7.
5. Phần thất bại phải rõ như ban ngày: stake bị trừ ngay lúc mua (không phải lúc thua), nút bắt đầu ghi thẳng "không hoàn nếu thất bại", không có hiệu ứng "suýt thắng".

---

## 1. Facts (đã có trong repo) và Proposals

### Facts

| # | Fact | Nguồn |
|---|---|---|
| F1 | `run_stats` có `dmg, taken, turns, kills, max_hit, dmg_dealt_clamped`. `max_hit` là MAX, không cộng dồn, và không tính poison/thorns; `dmg` thì có tính. | `RunState.gd:44`, `RunState.gd:407-416` |
| F2 | Khi lưu/khôi phục run, `run_stats` chỉ nạp lại đúng 6 key cố định. Key mới thêm vào mà không sửa dòng đó sẽ **mất âm thầm sau resume**. | `RunState.gd:930` |
| F3 | Run còn lưu: mode, ascension, `visited_node_ids`, `power_level`, relic đang có, đội hình (`team_keys` trong header action log). | `RunState.gd:32-46`, `action_log.gd:81-111` (theo brief, chưa đọc hết) |
| F4 | Shard của run = tổng thưởng từng trận (25 / 45 / 90) + event − tiền tiêu shop, bank khi `end_run()`. Run short thắng ~560 trước khi tiêu (ghi chú review của Claude trong core-loop-v2). | `combat_engine.gd:1207`, `RunState.gd:386,783-787,447` |
| F5 | `end_run()` cho **Daily Mission +60 Shard ở mọi lần kết thúc run** (thắng, thua, bỏ). Đây là thứ khác với Nhiệm vụ cược. | `RunState.gd:461-464`, `MetaState.gd:634-640` |
| F6 | `RunVerifier` chỉ xác minh được run **ranked**. Run thường bắt đầu bằng unlock cục bộ (reroll, HP, relic khởi đầu) mà server không thấy; replay sẽ ra run khác. `run_bonuses(true)` trả toàn số 0. | `run_verifier.gd:24-29`, `MetaState.gd:345-348`, `action_log.gd:106-117` |
| F7 | Lệch `rules_version` hoặc `content_version` thì verifier trả `rules_version_mismatch`, và comment trong code nói rõ: đó **không phải gian lận**, chỉ là log không đọc được. | `run_verifier.gd:52-60` |
| F8 | Có save/resume run (`has_saved_run`, `resume_combat` kể cả giữa trận). | `RunState.gd:106-111,994` |
| F9 | Party hồi đầy máu mỗi trận (quyết định có chủ đích). Nhiệm vụ không được đụng luật này. | rule-spec ~dòng 64, 321 |
| F10 | Có tài khoản Google + cloud save + chế độ guest. | `AccountService.gd`, `worker/src/accounts.js` |

### Chưa verify (cần kiểm trước khi chốt)
- Server có phải nơi giữ số dư Shard chính thức không, hay cloud save chỉ là ảnh chụp ghi đè? Quyết định cách escrow (§7).
- Có thể bỏ qua reward (không nhận relic) không? Ảnh hưởng mission "Tối giản".
- Loại node của `visited_node_ids` có suy ra được từ seed + map generator không? Ảnh hưởng mission "Đường vòng".
- Run seed hiện sinh ở client hay đã có đường server cấp?

---

## 2. Mục tiêu, trải nghiệm, và thứ nó không được trở thành

**Aesthetic chính (MDA)**: Challenge và Expression. Người chơi tự nói "run này tôi chơi theo luật khó hơn", và game trả công cho lời nói đó.
**SDT**: Autonomy (tự chọn mức rủi ro, loại phong cách), Competence (điều kiện đo được, biết vì sao thắng/thua).

**Vị trí trong core loop** (xem `core-loop-v2.md` §2): thêm lớp mục tiêu ở tầng MESO (1 run). Run vẫn tự trả thưởng như cũ; Nhiệm vụ là phần **chồng thêm**, không thay thế. Thua Nhiệm vụ không làm mất Shard mà run đã kiếm.

**Giá trị mới**: đa số run hiện nay có cùng một mục tiêu (thắng). Nhiệm vụ cho 15 mục tiêu khác nhau, thúc người chơi thử archetype/class họ thường bỏ qua.

**Nó KHÔNG được trở thành**:
- Máy đánh bạc. Không có hệ số tăng liên tiếp, không "gấp đôi hoặc mất hết", không đòn bẩy sau khi thua.
- Đường tắt kiếm Shard cho người giỏi (xem trần ở §5.6).
- Cách ép chơi. Không có Nhiệm vụ hết hạn gây FOMO, không phạt vì không mua.
- Lách luật combat. Nhiệm vụ chỉ **đọc** dữ liệu run, không đổi HP, archetype, tỉ lệ rơi.

---

## 3. Nghiên cứu: game thật xử lý cược/rủi ro thế nào

Số liệu nào nguồn không chính thức tôi ghi rõ. Tôi không tìm được bảng chính thức cho vài game, nên chỗ đó là mô tả cơ chế chứ không dựa vào con số.

| Game | Cơ chế & stake | Đường payout | Chống farm / giảm feel-bad | Bài học cho Axie Dice |
|---|---|---|---|---|
| **Hades — Pact of Punishment** ([RPG Site](https://www.rpgsite.net/feature/10287-hades-pact-of-punishment-heat-modifiers-and-how-to-maximize-your-rewards), [Prima](https://primagames.com/gaming/hades-guide-pact-of-punishment-modifiers-heat)) | Tự chọn modifier, cộng thành Heat. Không có stake tiền, rủi ro là run khó hơn. | Heat càng cao, thưởng càng nhiều; vượt mức yêu cầu vẫn nhận. | Mỗi vũ khí phải leo thêm 1 Heat mới nhận lại thưởng; thưởng tính theo từng boss nên run dở vẫn có phần. | Chống farm bằng "phải nâng độ khó mới nhận lại", không bằng cấm. Áp dụng: không lặp cùng loại trong một ngày (§5.6). Run thất bại vẫn nhận thưởng nền. |
| **Hearthstone Arena** ([Game Developer](https://www.gamedeveloper.com/design/the-math-of-hearthstone-part-ii-arena-the-american-dream-), [Icy Veins](https://www.icy-veins.com/hearthstone/arena-starter-guide), [wiki](https://hearthstone.wiki.gg/wiki/Arena)) | Vé 150 Gold, mỗi lượt đảm bảo ít nhất 1 gói thẻ. Bản mới: thắng 5 trận hoàn vé. | Thưởng tăng theo số thắng; phân tích ~447.000 run thấy bước nhảy ở 7 thắng vì đủ tiền vào lượt nữa. | Người chơi vừa phải xấp xỉ hòa vốn; thua vẫn có quà tối thiểu. | Đường cong payout nên **công khai** và có điểm hòa vốn rõ. Có quà an ủi phi-tiền. Tôi không dùng quà an ủi bằng Shard vì Liam cấm hoàn. |
| **MTG Arena Quick Draft** ([Wizards](https://magic.wizards.com/en/mtgarena/draft), [Draftsim](https://draftsim.com/mtg-arena-draft-guide/)) | 5.000 Gold hoặc 750 Gem; dừng khi 7 thắng hoặc 3 thua. | Theo số thắng. Bảng một guide bên thứ ba ghi 50→950 Gem từ 0→7 thắng (**chưa xác nhận chính thức**). | Thua 0 trận vẫn nhận một phần nhỏ. | Đường cong lồi (thắng nhiều thì lợi tăng nhanh) thưởng người giỏi nhưng làm người yếu lỗ sâu. Axie Dice dùng m cố định theo bậc, đơn giản hơn. |
| **Destiny 2 Trials** ([MP1st rotation](https://mp1st.com/news/new-destiny-2-trials-of-osiris-rewards-and-map-this-week-september-27)) | Thẻ tiến độ theo số thắng; thua sau khi đã thắng sẽ xóa thắng (khi không đủ fireteam). | Reputation tăng theo số round thắng, kể cả khi thua trận; sau 7 thắng, thua không bị phạt. | Có "Passage of Mercy" (trả Glimmer để được tha 1 trận thua). | Có game bán thẳng "bảo hiểm thua". Axie Dice **không** làm (trái luật Liam). Bài học khác: tiến độ hiển thị rõ giúp thua vẫn cảm thấy công bằng. |
| **Deep Rock Galactic — Deep Dive** ([wiki](https://deeprockgalactic.wiki.gg/wiki/Deep_Dive)) | Tự chọn mức Hazard/Warning. | Hazard Bonus nhân XP; phần thưởng đặc biệt chỉ nhận 1 lần/tuần/biến thể, phần lặp chỉ còn tín dụng. | Cap theo tuần chống farm; nguồn: wiki cộng đồng, con số chính xác không xác nhận được. | Cap "thưởng đặc biệt 1 lần" tốt hơn cấm lặp. Người chơi phàn nàn khi độ khó ngẫu nhiên mỗi tuần quá cao (một thread Steam, chỉ là ý kiến). |
| **Hunt: Showdown / Tarkov** ([mein-mmo](https://mein-mmo.de/en/hunt-showdown-what-happens-when-you-die,850013), [AFK Gaming](https://afkgaming.com/esports/guide/everything-about-insurance-in-escape-from-tarkov)) | Stake là **trang bị/nhân vật**, mất khi chết trước khi rút. | Thua mất hết; tiến độ lâu dài (bloodline) không mất. Tarkov có bảo hiểm trả lại không chắc chắn. | Tách "thứ có thể mất" khỏi "tiến độ vĩnh viễn". | Vùng rủi ro của Axie Dice **chỉ là Shard**. Không bao giờ stake Land, unlock, cosmetic, Echo Box. |
| **Balatro / Monster Train** ([Dot Esports](https://dotesports.com/indies/news/all-balatro-stakes-in-unlock-order), [Seasoned Gaming](https://seasonedgaming.com/2021/03/30/review-monster-train-can-you-keep-hell-from-freezing-over/)) | Bậc độ khó cộng dồn (Balatro 8 stake; Monster Train 25 Covenant). | Phần thưởng là ghi nhận (sticker), không phải tiền. Covenant 25: dưới 10% người chơi Steam thắng (theo một review). | Người chơi bậc cao tự chọn, không có phạt tiền. | Bậc cao nhất nên là "đích để khoe" có huy hiệu, không phải nơi payout phình to. |
| **Path of Exile — Kirac** ([Maxroll](https://maxroll.gg/poe/leagues/kirac-guide)) | Bảng nhiệm vụ dựng sẵn theo bậc; chọn 1 thì bảng được làm mới. | Mỗi nhiệm vụ có bonus gắn sẵn. | Không có stake; mất lợi thế của cây Atlas là giá phải trả. | Bảng offer dựng sẵn, minh bạch, cho chọn. Không cho người chơi "xoay" bảng vô hạn để tìm điều kiện dễ. |
| **Nghiên cứu hành vi** ([thesis Saskatchewan](https://harvest.usask.ca/items/2d0daa40-da4f-4783-8892-6f1272bff45f/full), [Frontiers Psychiatry 2024](https://www.frontiersin.org/journals/psychiatry/articles/10.3389/fpsyt.2024.1322631/pdf), [luật Hàn Quốc về công bố tỉ lệ](https://shinkim.com/eng/media/newsletter/3206)) | Thesis: 300 người cược vàng ảo, vẫn thiên lệch mạnh về tránh mất. Review 2024: near-miss làm tăng ham muốn chơi tiếp, nhất là ở người có xu hướng đuổi theo khoản lỗ. | — | Hàn Quốc từ 8/2025 bắt công bố tỉ lệ loot box. | Thesis chỉ là một luận văn, near-miss chủ yếu có bằng chứng từ cờ bạc, chứ không phải game không tiền. Vẫn đủ để thiết kế phòng xa: công bố tỉ lệ, không near-miss, giới hạn lỗ ngày. |

### Sáu bài học rút ra, áp thẳng vào thiết kế

1. **Công khai điểm hòa vốn và tỉ lệ thành công** (Arena, luật công bố tỉ lệ).
2. **Tách vùng có thể mất (Shard) khỏi tiến độ vĩnh viễn** (Hunt, Tarkov).
3. **Cap kiểu "thưởng đặc biệt có hạn", không cấm lặp** (Hades, DRG).
4. **Bậc cao nhất thưởng ghi nhận, không thưởng phình** (Balatro, Monster Train).
5. **Không bán bảo hiểm thua, không near-miss, không đuổi lỗ** (Destiny Mercy là phản ví dụ; nghiên cứu hành vi).
6. **Offer dựng sẵn, minh bạch, không xoay vô hạn** (Kirac).

**Lưu ý về đối tượng**: người chơi là nhân viên Sky Mavis, không có tiền thật. Rủi ro lớn nhất không phải nghiện mà là (a) cảm giác bị lừa khi mất Shard mà không hiểu vì sao, (b) áp lực so sánh trong công ty. Nên: kết quả Nhiệm vụ để **riêng tư**, không lên bảng xếp hạng công ty (OQ-9).

---

## 4. Danh mục Nhiệm vụ (15 loại)

Cột "Dữ liệu": **có** = đã theo dõi (F1/F3); **mới** = cần thêm bộ đếm. Ngưỡng N cho từng bậc **cần sim**, tôi không điền số. Mỗi Nhiệm vụ chỉ xét **một run**, đánh giá khi run kết thúc, qua replay trên server.

| # | Tên | Điều kiện | Dữ liệu | Yếu tố làm khó | Khuyến khích |
|---|---|---|---|---|---|
| 1 | Thép | Thắng, `taken` ≤ N | có (`taken`) | N thấp dần; N phải điều chỉnh theo Ascension | BULWARK/AEGIS, Plant/Reptile |
| 2 | Chớp nhoáng | Thắng, `turns` ≤ N | có (`turns`) | N thấp dần | APEX, TALON, burst |
| 3 | Một đòn | Có ít nhất một đòn `max_hit` ≥ N. **Không cần thắng.** | có (`max_hit`) | N cao dần | APEX, crit |
| 4 | Tàn sát | `kills` ≥ N | có (`kills`) | N cao dần (không cần thắng) | SWARM, đòn lan |
| 5 | Đơn sắc | Thắng với cả đội cùng 1 class | có (đội hình) | Cần đồng class, mất đa dạng | Passive class đào sâu |
| 6 | Đa sắc | Thắng với ≥3 class khác nhau | có (đội hình) | Ép đội trộn | Relic cross-class |
| 7 | Leo thang | Thắng ở Ascension ≥ k, k chỉ ≤ `asc_max`+1 của người đó | có (`ascension`) | k cao dần | Người đã leo Ascension |
| 8 | Hành trình dài | Thắng Full mode | có (`mode`) | Run dài gấp ~1.7 lần (chưa đo) | Người thích đường dài |
| 9 | Đường vòng | Thắng mà không vào shop / chỉ qua ≥2 elite | có (nếu suy được loại node, xem "chưa verify") | Bỏ qua nguồn mạnh hoặc chọn đường nguy hiểm | Người thích tính đường |
| 10 | Tối giản | Thắng với ≤K relic (nếu reward được phép bỏ qua) | có (relic), cần xác nhận | K thấp dần | Build gọn, class passive |
| 11 | Gián tiếp | ≥X% `dmg` đến từ poison + thorns | **mới** (tách `dmg_dot`) | X cao dần | PLAGUE, Bug, Reptile, thorns |
| 12 | Cứng tay | Thắng với ≤K lần reroll xúc xắc | có (đếm từ action log) | K thấp dần | Người chơi cam kết mặt xúc xắc |
| 13 | Toàn mạng | Thắng mà không Axie nào bị hạ gục | **mới** (`ko_count`) | Phải phòng thủ/chữa/điều khiển | BULWARK, Aqua |
| 14 | Hạ boss chớp nhoáng | Hạ boss cuối trong ≤N lượt | **mới** (lượt theo từng trận) | N thấp dần | Burst, APEX, FERAL |
| 15 | Trụ vững | `power_level` ≥ N dù thua | có (`RunState.gd:46`) | N cao dần | Người mới, đội phòng thủ |

**Nhiệm vụ dành cho người yếu (bậc I, không cần thắng)**: #3, #4 và #15. Nhờ đó người yếu có bậc I khả thi (p ~45%) mà không phải mua cái chắc thua.
**Bậc 4 có thể ghép 2 điều kiện** (ví dụ Thép + Hành trình dài). Ghép làm p giảm nhân lên, nên sim phải đo riêng từng cặp, không suy ra từ hai điều kiện lẻ.

### Bộ đếm mới cần thêm (và bẫy khi thêm)
- Mới: `dmg_dot` (poison+thorns), `ko_count`, số lượt theo từng trận (để biết trận boss).
- Số reroll lấy từ action log, không cần bộ đếm.
- **Bẫy F2**: mỗi key mới phải thêm vào danh sách ở `RunState.gd:930` **và** `to_data()` (`RunState.gd:871`), nếu không sau khi resume Nhiệm vụ sẽ bị đánh giá sai.
- Đặt bộ đếm trong đường tích lũy `run_stats` hiện có, không đụng luật combat. Nếu phải đổi file combat nằm trong 19 file `t_rules_version` theo dõi thì sẽ buộc đổi `RULES_VERSION` (chưa verify), và thế là mọi run đang mở bị vô hiệu (xem F7, §5).

---

## 5. Thang độ khó, stake và thưởng

### 5.1 Nguyên tắc
- **Stake đặt theo R toàn cục** (số trung vị toàn người chơi, đặt trong data file, cập nhật theo bản patch), **không** theo thu nhập từng người. Nếu theo từng người, người chơi sẽ có động cơ cố tình chơi dở để hạ stake.
- Thưởng = `stake × m` (m **bao gồm** stake; lãi ròng = `stake × (m−1)`).
- `m` chọn sao cho điểm hòa vốn `p* = 1/m` nằm dưới tỉ lệ thành công của người "đúng tầm" khoảng 5–10 điểm phần trăm, tức EV người trung bình hơi âm: Nhiệm vụ là một **sink nhẹ của Shard**, không phải faucet.
- Làm tròn stake và thưởng xuống bội 5 Shard.

### 5.2 Thang

| Bậc | Tên | Stake | m | Thưởng (nhận lại tổng) | Hòa vốn `p*` |
|---|---|---|---|---|---|
| I | Dễ | 0.2 R | ×1.5 | 0.30 R | 67% |
| II | Vừa | 0.4 R | ×2.2 | 0.88 R | 45% |
| III | Khó | 0.7 R | ×3.2 | 2.24 R | 31% |
| IV | Cực khó | 1.0 R | ×4.0 | 4.00 R | 25% |

**Ví dụ bằng số** (làm tròn bội 5):

| Bậc | R = 300: stake → thưởng (lãi ròng) | R = 550: stake → thưởng (lãi ròng) |
|---|---|---|
| I | 60 → 90 (+30) | 110 → 165 (+55) |
| II | 120 → 265 (+145) | 220 → 485 (+265) |
| III | 210 → 670 (+460) | 385 → 1.230 (+845) |
| IV | 300 → 1.200 (+900) | 550 → 2.200 (+1.650) |

### 5.3 Giả định tỉ lệ thành công (chờ sim, đây là mục tiêu thiết kế, không phải kết quả đo)

Ba nhóm theo tỉ lệ thắng run thường: Yếu ~20%, Trung bình ~45%, Giỏi ~75%.

| Bậc | p Yếu | p TB | p Giỏi |
|---|---|---|---|
| I | 45% | 65% | 85% |
| II | 22% | 42% | 62% |
| III | 10% | 28% | 42% |
| IV | 4% | 18% | 28% |

### 5.4 EV theo từng nhóm (`EV = p·m − 1`, tính trên stake)

| Bậc | Yếu | TB | Giỏi | Giỏi, R=300 (Shard/lượt) |
|---|---|---|---|---|
| I | −32% | −2% | +28% | +17 |
| II | −52% | −8% | +36% | +44 |
| III | −68% | −10% | +34% | +72 |
| IV | −84% | −28% | +12% | +36 |

Đọc bảng: người trung bình chơi bậc I–II gần như hòa; bậc IV tốn kém với họ, nên đó là bậc của người giỏi và người thích khoe. Người yếu mua bậc III–IV là chắc chắn lỗ nặng, nên có hàng rào ở §5.6.

### 5.5 Exploit analysis

**Người giỏi farm?** Không thể farm vô hạn: mỗi Nhiệm vụ cần 1 run đầy đủ (~25 phút), tối đa 5 lượt/ngày, bậc IV ≤1/ngày, bậc III ≤2/ngày. Kỳ vọng lãi tối đa trong một ngày (1×IV + 2×III + 2×II) ≈ 0.9 R, tức khoảng +18% so với thu nhập 5 run cùng ngày. Chấp nhận được. Trường hợp may mắn thắng tất cả (xác suất ~2%) thu ròng ~7 R; chặn bằng **trần thưởng ngày 6 R** (§5.6) và công bố trên bảng.
**Người yếu phá sản?** Giới hạn lỗ ngày 1.0 R (bên dưới): không bao giờ mất quá ~1 R/ngày từ Nhiệm vụ, thấp hơn thu nhập run. Nhưng họ vẫn có thể tự làm mình khó chịu; hàng rào còn lại là thông tin trung thực (§8.1).
**Rủi ro lạm phát Shard**: nếu tỉ lệ hoàn trả toàn quần thể (RTP = tổng thưởng / tổng stake) > 100% thì Nhiệm vụ thành faucet. Mục tiêu RTP 90–95%, đo hằng tuần.

### 5.6 Trần và hàng rào (tất cả là knob, §10)

| Hàng rào | Giá trị mặc định | Vì sao |
|---|---|---|
| Số Nhiệm vụ mua/ngày | **5** (Liam chốt) | Tính theo ngày UTC của lúc mua, server đếm |
| Giới hạn theo bậc | IV ≤1, III ≤2 mỗi ngày | Chặn người giỏi chỉ chọn bậc EV cao nhất |
| Stake ≤ % số dư | 40% | Không thể đặt hết sạch tiền |
| **Giới hạn lỗ ròng/ngày** | mua mới chỉ được nếu `lỗ ròng hôm nay + stake ≤ 1.0 R` | Chặn đuổi theo khoản lỗ; ngoài luật Liam, xem OQ-3 |
| Trần thưởng ngày | 6 R (tổng thưởng ròng) | Lưới an toàn khi sim sai |
| 1 Nhiệm vụ / run | cố định | Không chồng stake |
| Không lặp | Cùng loại không xuất hiện hai lần trên bảng 1 ngày | Kiểu Hades: phải đổi lối chơi |

---

## 6. Dòng chảy trong ngày

**Bảng 5 offer mỗi ngày**: server dựng, cố định cho mọi người, seed = hash(ngày UTC, `rules_version`). Công thức: 1 bậc I, 1 bậc II, 1 bậc III, 1 bậc IV, 1 "tự do" (bậc ngẫu nhiên, ưu tiên bậc II). Mọi người thấy cùng bảng: đồng nghiệp bàn với nhau được, QA tái lập được. Offer lọc theo điều kiện người chơi (không bán Nhiệm vụ Full nếu chưa mở Full, Leo thang giới hạn k ≤ `asc_max`+1).
**Không cho xoay bảng** (bài học Kirac). Mọi offer cố định đến hết ngày UTC.

**Luồng**:
1. Vào nhà Nhiệm vụ, xem bảng, chọn offer, xem màn xác nhận (§8.1), mua. Stake bị **trừ và giữ (escrow) ngay lúc này**. Vé vào hàng chờ.
2. Chọn đội, bấm "Bắt đầu Nhiệm vụ". Màn xác nhận thứ hai. Lúc này server **cấp seed** và run bắt đầu. Từ lúc này không hủy được.
3. Chơi. HUD hiện tracker (§8.2).
4. Run kết thúc → client gửi action log → server replay → thanh toán hoặc ghi thất bại.

**Hủy trước khi bắt đầu run**: hoàn 100% stake và trả lại lượt (đây là hủy, không phải thất bại). Vé chưa bắt đầu hết hạn cuối ngày UTC **hôm sau** và hoàn 100% (không để người quên bị phạt).
**Slot Land (bề rộng, không sức mạnh)**: số vé có thể giữ trong hàng chờ cùng lúc. Land tier 1–2: 1; tier 3–4: 2; tier 5–6: 3. Mọi tier đều dùng chung trần 5 lượt/ngày. Slot chỉ cho phép mua trước khi chơi.
**Một Nhiệm vụ bao 1 run.** Nhiệm vụ nhiều run bị loại: chuỗi stake nhiều run khuyến khích sunk-cost và đuổi lỗ.
**Mode**: bậc nào cũng có thể ở Short hoặc Full. Full dùng `k_full` (~1.5, cần đo R_full / R_short) nhân stake và thưởng.

### Định nghĩa thất bại (mọi trường hợp)

| Tình huống | Kết quả | Hiển thị cho người chơi |
|---|---|---|
| Thua (đội bị hạ) | **Thất bại**, mất stake | "Nhiệm vụ không hoàn thành. Stake X đã mất." |
| Điều kiện không đạt khi run kết thúc (dù thắng) | **Thất bại** | Nêu số thực tế so với ngưỡng |
| Chọn "Bỏ run" | **Thất bại**, có hộp xác nhận ghi rõ mất stake | Xác nhận 2 bước |
| "Lưu & thoát" giữa run | Vé vẫn mở, **TTL 24 giờ** kể từ lần lưu cuối. Quá hạn thì thất bại | Đếm ngược trên nút Tiếp tục và ở menu |
| Crash / mất điện | Run đã lưu (F8) nên mở lại và chơi tiếp. Quá TTL thì thất bại | Cùng như trên |
| Mất mạng | Run chơi tiếp offline; log xếp hàng, gửi khi có mạng, hạn gửi 72 giờ | "Đang chờ xác minh" |
| Đổi máy khi vé đang mở | Run lưu cục bộ không theo sang máy khác → thất bại khi hết TTL, hiển thị trước lúc mua | Dòng cảnh báo ở màn xác nhận |
| **Lỗi hệ thống** (lệch `rules_version`, server hỏng quá hạn, bug đã xác nhận) | **Vô hiệu, hoàn stake.** Không phải thất bại, ghi riêng trong sổ | "Nhiệm vụ bị hủy do hệ thống, đã hoàn X" |

Phân biệt "thất bại" (do người chơi) và "vô hiệu" (do hệ thống) là bắt buộc: F7 nói lệch phiên bản không phải gian lận. Nếu đổi luật giữa lúc có vé mở, hoặc là chặn cập nhật khi còn vé mở, hoặc vô hiệu hóa chúng; không được phạt người chơi (OQ-5).

---

## 7. Chống khai gian và toàn vẹn

**Nguyên tắc**: client không bao giờ nói "tôi đã hoàn thành". Server chỉ tin kết quả replay từ seed + action log (F6).

1. **Run Nhiệm vụ phải là run ranked profile** (F6): không unlock cộng reroll/HP/relic khởi đầu, nên server tái hiện đúng. Phụ: bỏ luôn lợi thế "người mua nhiều unlock thắng dễ hơn" khỏi hệ thống cược. Phương án khác (ghi bonuses vào header, server đối chiếu với cloud save) dựa vào dữ liệu server chưa chắc có, nên không khuyên. OQ-2.
2. **Seed do server cấp lúc bấm Bắt đầu**: người chơi không thể thử nhiều seed rồi mới mua, không dò map.
3. **Escrow phía server**: stake bị trừ ở server lúc mua. Người chơi không thể thoát game rồi khôi phục save cũ để lấy lại stake. (Cần xác nhận server là nơi giữ số dư — "chưa verify".)
4. **Save-scum / rewind**: save giữa trận (F8) cho phép thử một trận, thua thì kill process và nạp lại. Cách xử lý: client gửi **heartbeat** (số hành động + digest trạng thái) lúc bắt đầu mỗi trận; khi nộp log, server kiểm tiền tố log khớp heartbeat. Log "quay ngược" so với heartbeat đã ghi nhận là vô hiệu → thất bại. Phương án rẻ hơn nếu không kịp làm: Nhiệm vụ chỉ cho "Lưu & thoát" ở màn map, crash giữa trận được resume tối đa 1 lần (hiển thị cho người chơi).
5. **Nhiều máy**: mỗi tài khoản chỉ 1 vé đang chạy; vé gắn với thiết bị bắt đầu run.
6. **Ranked / Daily seed**: Nhiệm vụ **không** chạy trên Daily seed hay run Ranked leaderboard, vì seed cố định cho phép dò trước. Nhiệm vụ dùng seed server cấp riêng, **không** vào bảng xếp hạng.
7. **Thay đổi luật**: `ERR_RULES_VERSION` → vô hiệu, không phải thất bại (§6).
8. **Daily Mission +60 (F5)** vẫn nhận bình thường ở run Nhiệm vụ; không nhầm với thưởng Nhiệm vụ. Tên gọi dễ nhầm: OQ-8.
9. **Nhật ký**: server lưu bản ghi bất biến mỗi vé (mua, bắt đầu, kết quả, lý do) để xử lý khiếu nại.

---

## 8. UX

Tuân thủ `godot/CLAUDE.md`: mọi màn bám mockup, không tự bịa chip hay helper text. Phần này mô tả **nội dung cần có**; hình thức do `ux-designer` làm mockup trước khi code. Màn dưới đây **chưa có mockup**, phải làm mockup trước.

### 8.1 Màn mua (nhà Nhiệm vụ)
Mỗi offer luôn hiện đủ:
- Tên, điều kiện bằng một câu đơn giản ("Thắng và nhận tối đa 12 sát thương").
- **Stake** (số Shard) và **Thưởng nếu thành công** (số Shard), lãi ròng.
- **Nếu thất bại: mất toàn bộ X Shard, không hoàn.** Dòng này luôn hiện, cùng cỡ chữ với dòng thưởng, màu trung tính.
- **Cần thành công ≥ P% để không lỗ** (hòa vốn).
- **Tỉ lệ thành công thực tế**: "Toàn server: 34% (412 lượt)" khi đủ mẫu (ngưỡng ≥200 lượt), và "Của bạn: 2/6". Khi chưa đủ mẫu hiện "Ước tính từ mô phỏng: khoảng 1/3" có nhãn "ước tính", không dùng số giả chính xác.
- Số dư sau khi mua, số lượt còn lại hôm nay, lỗ ròng hôm nay so với giới hạn.
- **Nút mua kiểu giữ-để-xác-nhận ~1 giây** cho bậc III–IV, nhấn thường cho bậc I–II.

### 8.2 Trong run
Tracker nhỏ ở HUD: điều kiện, giá trị hiện tại/ngưỡng, và dòng "Stake đang cược: X". Tracker chỉ hiện số thực, **không** có thanh "sắp đạt" lấp lánh, không rung/âm thanh khi gần ngưỡng. Nếu điều kiện đã chắc chắn không đạt được (ví dụ Thép nhưng đã quá ngưỡng), tracker chuyển sang "Không thể đạt", không để người chơi chơi tiếp trong hy vọng hão. Họ vẫn có thể chơi tiếp lấy thưởng nền của run.

### 8.3 Màn kết quả
- **Thành công**: số Shard nhận, tổng quan, không pháo hoa lớn hơn run thường.
- **Thất bại**: nêu chính xác điều kiện, giá trị thực tế, ngưỡng, số stake mất. Không nhấn mạnh phần suýt đạt, không hoạt ảnh tiếc nuối, **không** nút "Thử lại gấp đôi" hay gợi ý mua ngay. Thưởng nền của run vẫn hiện bình thường ngay bên dưới ("Run này vẫn cho bạn Y Shard").
- Sổ riêng tư: "Hôm nay: +X / −Y; tuần này: ..." để người chơi tự thấy tổng, không bị "ảo giác thắng nhiều".

### 8.4 Những thứ tuyệt đối không có
Hệ số chuỗi thắng, "hot streak", đếm ngược FOMO, bảng so sánh lãi lỗ giữa đồng nghiệp, kỷ lục "lỗ nhiều nhất", âm thanh/ánh sáng kiểu máy đánh bạc, gợi ý "bạn đã mất nhiều, hãy gỡ lại".

### 8.5 Phần thưởng phi-Shard
Chỉ ghi nhận: huy hiệu "Dấu" lần đầu hoàn thành mỗi loại × bậc (cosmetic, kiểu sticker Balatro), hiện trên hồ sơ riêng. Không là tiền, không đổi được.

---

## 9. Land Stone: Nhiệm vụ có nên trả không?

**Đề xuất: không.** Lý do:
1. Quyết định của Liam liệt kê faucet Land Stone là Echo Box, Battle Pass, daily quest. Nhiệm vụ không có trong danh sách.
2. Nhiệm vụ nhận vào Shard và trả ra Land Stone chính là **cách đổi Shard sang Land Stone** (mua Nhiệm vụ để lấy Stone). Điều này vi phạm INV-Land-1 trong core-loop-v2 §3.1 (không đổi qua lại).
3. Người giỏi có EV dương, nên sẽ đạt Land nhanh hơn người khác chỉ vì cược khéo, đi ngược việc Land là mốc cam kết lâu dài.
4. Land Stone chậm và quý; gắn nó với trò may rủi làm mất tính "cam kết".

Nếu Liam muốn có, tôi đề xuất tối thiểu: tối đa **1 Land Stone/tuần**, chỉ từ bậc IV, không phụ thuộc stake (chỉ lần hoàn thành đầu tuần), ghi là câu hỏi mở vì nằm ngoài danh sách của Liam (OQ-1).

---

## 10. Tuning knobs

Tất cả nằm trong data file ngoài code (ví dụ `assets/data/missions.json`), không hardcode.

| Knob | Loại | Mặc định | Khoảng an toàn | Ghi chú |
|---|---|---|---|---|
| `R` (Shard/run, toàn cục) | Curve | **đo xong mới điền** | — | Mọi stake/thưởng tính từ đây |
| `stake_frac[I..IV]` | Curve | 0.2 / 0.4 / 0.7 / 1.0 | 0.1–1.2 | Không vượt 1.2 R |
| `m[I..IV]` | Curve | 1.5 / 2.2 / 3.2 / 4.0 | 1.3–4.5 | Giữ `m ≤ 4.5` để tránh cảm giác xổ số |
| `k_full` | Curve | 1.5 | 1.3–2.0 | Cần đo R_full / R_short |
| `daily_limit` | Gate | 5 | cố định (Liam) | |
| `tier_daily_limit` | Gate | IV:1, III:2 | 0–5 | |
| `stake_max_balance_pct` | Gate | 40% | 25–60% | |
| `daily_loss_limit` | Gate | 1.0 R | 0.5–2 R | Có thể tắt nếu Liam không muốn (OQ-3) |
| `daily_payout_cap` | Gate | 6 R | 4–10 R | Lưới an toàn |
| `ticket_ttl_saved` | Gate | 24 giờ | 12–72 | Sau "Lưu & thoát" |
| `log_upload_ttl` | Gate | 72 giờ | 24–168 | |
| `unstarted_ttl` | Gate | hết ngày UTC hôm sau | | Hoàn 100% |
| `hint_min_samples` | Gate | 200 | 100–500 | Dưới ngưỡng thì hiện ước tính từ sim |
| `hold_confirm_ms` | Feel | 1000 | 600–1500 | Bậc III–IV |
| `rtp_target` | Curve | 90–95% | 85–100% | Đo hằng tuần; trên 100% là Nhiệm vụ đang thành faucet |
| `threshold_N[type][tier]` | Curve | từ sim | | Mục tiêu p theo §5.3 |

---

## 11. Acceptance criteria (QA kiểm được)

**Chức năng**
1. Mua một Nhiệm vụ: số dư giảm đúng bằng stake **ngay lúc mua**, trước khi bắt đầu run.
2. Mua lần thứ 6 trong cùng ngày UTC bị từ chối với thông báo rõ.
3. Mua bậc IV lần hai trong ngày bị từ chối; bậc III lần ba bị từ chối.
4. Mua khi stake > 40% số dư bị từ chối. Mua khi `lỗ ròng hôm nay + stake > 1.0 R` bị từ chối.
5. Thua run: stake không hoàn, số dư giữ nguyên trừ stake và cộng thưởng nền của run.
6. Thắng run đạt điều kiện: số dư tăng đúng `stake × m − stake` (so với trước khi mua).
7. Bỏ run (xác nhận): thất bại, stake mất. Lưu & thoát rồi để quá 24 giờ: thất bại.
8. Hủy vé trước khi bắt đầu run: hoàn 100% và trả lại lượt.
9. Đổi `rules_version` giữa lúc vé mở: vé thành **vô hiệu**, stake hoàn, không ghi thất bại.
10. Server từ chối kết quả khi log bị sửa (đổi `max_hit`, `turns`, bỏ hành động) và ghi thất bại; `t_replay` có thêm ca tamper cho từng loại điều kiện.
11. Log bị rewind (tiền tố không khớp heartbeat) bị coi vô hiệu theo §7.4.
12. Hai thiết bị cùng đăng nhập: chỉ 1 vé mở; thiết bị thứ hai không tiếp tục được run của thiết bị đầu.
13. Run Nhiệm vụ luôn dùng ranked profile: `run_bonuses(true)` trả toàn 0 và header `ranked = true`.
14. Sau khi resume, bộ đếm điều kiện (`dmg_dot`, `ko_count`, ...) cho kết quả giống hệt khi chơi liền không resume (liên quan F2).
15. Mỗi loại trong §4 (15 loại) có ít nhất một test đếm đúng trên seed cố định.
16. Mọi key mới trong `run_stats` có trong `to_data`/`from_data` (test tự động).
17. Bảng 5 offer giống nhau giữa hai tài khoản cùng ngày UTC và không có hai loại giống nhau.

**Trải nghiệm (playtest)**
18. Mỗi người chơi thử, **trước khi mua**, nói lại đúng bằng lời mình: mất bao nhiêu nếu thất bại, và nhận bao nhiêu nếu thành công. Ít nhất 9/10 người nói đúng.
19. Sau một lần thất bại, không người chơi nào nói "tôi tưởng sẽ được hoàn" hoặc "tôi không biết sẽ mất".
20. Sau 2 tuần thử nội bộ: RTP toàn quần thể trong 85–100%; không tài khoản nào đạt trần thưởng ngày hơn 1 lần/tháng; trung vị lỗ ngày của người dùng nhóm Yếu không vượt 0.5 R.
21. Khảo sát nhanh: không ai báo cảm giác "bị ép chơi tiếp để gỡ".

---

## 12. Phụ thuộc

- `RunState.gd`: thêm bộ đếm (F1, F2). `MetaState.gd`: cách trừ/cộng Shard phải đi qua đường `SaveStore` (CLAUDE.md), thêm field vào `reload_from_store()`.
- `RunVerifier` / `ActionLog`: cần header ghi `ticket_id`, hỗ trợ heartbeat; mở rộng để trả các chỉ số điều kiện.
- Server (`worker/src/`): bảng vé, escrow, cấp seed, đếm lượt ngày, dựng bảng offer.
- UI: mockup mới (nhà Nhiệm vụ, màn xác nhận, tracker, màn kết quả).
- Land (`core-loop-v2` §4): số slot theo tier; Nhiệm vụ không phụ thuộc Land để chạy bản đầu tiên (slot = 1).
- Economy-designer: chạy lại bảng §5 khi đã có R và sim.

---

## 13. Câu hỏi mở cho Liam (mỗi câu kèm đề xuất)

| # | Câu hỏi | Đề xuất |
|---|---|---|
| OQ-1 | Nhiệm vụ có trả Land Stone không? (Ngoài danh sách faucet Liam đã chốt.) | **Không** (§9). Nếu có: ≤1/tuần, chỉ bậc IV. |
| OQ-2 | Run Nhiệm vụ dùng ranked profile (không unlock cộng chỉ số) để xác minh được? | **Có.** Phương án khác cần server biết unlock thật. |
| OQ-3 | Cho phép **giới hạn lỗ ngày 1.0 R** và **stake ≤ 40% số dư**? Hai luật này hạn chế người chơi ngoài danh sách của Liam. | **Có**; đây là chỗ bảo vệ chính chống đuổi lỗ. Nếu Liam thấy không cần, có thể tắt nhưng sim yếu-nhóm sẽ lỗ sâu. |
| OQ-4 | Nhiệm vụ có bắt buộc đăng nhập tài khoản không (guest bị khóa)? | **Có**: escrow và đếm lượt phải ở server; guest chơi cục bộ không chặn được lách. |
| OQ-5 | "Hủy do hệ thống" (đổi luật, server hỏng, bug xác nhận) được hoàn stake, tách riêng khỏi "thất bại"? | **Có**, ghi rõ trong sổ. Luật "không hoàn" chỉ áp cho thất bại do người chơi. |
| OQ-6 | Seed do server cấp lúc bắt đầu run? | **Có.** Chặn dò seed. Cần xác nhận hiện seed sinh ở đâu. |
| OQ-7 | Có quà an ủi phi-Shard khi thất bại không? | Chỉ "Dấu" cosmetic khi **thành công** lần đầu; thất bại không thưởng gì ngoài thưởng nền của run. |
| OQ-8 | Tên gọi: game đã có "Daily Mission" +60 Shard (F5). Nhiệm vụ cược cũng là "Nhiệm vụ". | Giữ "Nhiệm vụ" cho loại cược ở nhà Nhiệm vụ; gọi loại +60 là "Thưởng ngày" trên UI để khỏi nhầm. Quyết định của Liam. |
| OQ-9 | Kết quả Nhiệm vụ (lãi/lỗ) có hiện trên bảng công ty không? | **Không**, giữ riêng tư. |
| OQ-10 | Nhiệm vụ Full: nhân stake theo `k_full`? | Có, chờ số đo R_full. Nếu Full quá ít người chơi thì bỏ Hành trình dài ở bản đầu. |
| OQ-11 | Số liệu R chốt khi nào? | Bảng §5 chỉ là khung. Sau khi đo R và chạy sim 10.000 run/archetype mới khóa `m`. |

---

## 14. Rủi ro

1. **Xác minh là phần tốn nhất** (heartbeat, escrow, vé, seed, offline). Nếu không kịp, bản đầu có thể chỉ cho Nhiệm vụ khi online và cấm Lưu & thoát giữa trận.
2. **p giả định ở §5.3 chưa có số đo.** Nếu thực tế người giỏi thắng nhiều hơn dự kiến, EV vọt lên cao. Trần ngày và RTP đo hằng tuần là phòng ngừa, không thay được sim.
3. **Chỗ thiếu số**: ngưỡng N cho 15 loại chưa có; cần sim theo archetype trước khi mở bảng.
4. Đụng file combat để thêm bộ đếm có thể buộc đổi `RULES_VERSION` (chưa verify), khiến run đang mở thành vô hiệu.
