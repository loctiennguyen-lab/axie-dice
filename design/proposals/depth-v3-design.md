# Depth v3: Lõi, mặt dice, vị trí, mana (thiết kế + plan 3 ngày)

Trạng thái: ĐỀ XUẤT, chờ Liam duyệt. Chưa sửa code, chưa sửa GDD nào, chưa commit. Đã qua review thiết kế độc lập (creative-director, 20/10): sửa thẳng trong bài, chỗ sửa ghi "(reviewer)", tóm tắt ở 9c. Review vòng 2 (20/10 tối, sau khi viết lại mục 2 + 2b): sửa ghi "(vòng 2)", tóm tắt ở 9d.
Bối cảnh: Liam chọn Gói 3 nhưng gói gọn, làm trong 3 ngày, tối đa 4 agent song song. Game hiện tại cực dễ, relic chán. North star: hệ Lõi (augment) của ARAM Hỗn Loạn và Võ Đài trong LoL.
Chỗ nào chưa kiểm được số hoặc code thì ghi "cần kiểm". Không đoán thành sự thật.

Đã đọc: depth-brainstorm-2026-10-20.md, `ContentDB.gd` (budget, boss, hero, enemy), `combat_engine.gd` (reroll, mana, intent, resonance, hold_pick), `reward_generator.gd`, `relic_def.gd`, `relic_slots.gd`, `run_map_generator.gd`, `combat_tune.json`, `ascension.json`, `worker/src/run_core.js`, INV trong `build-spec.md`. Chưa đọc lại `part-skill-identity.md` / `part-tier-system.md` / `bloodline-system.md` trong lượt này; chỗ nào dựa vào chúng đã ghi rõ.

## 0. Việc cắt so với Gói 3 (và vì sao)

| Cắt / gộp | Lý do |
|---|---|
| 2c gán mặt chồng lên một Axie | Đổi mô hình + UI kéo-thả mới, bloodline §4.4 ước 4-6 tuần. Không vào 3 ngày. Thay bằng "Mồi / Kết" (mục 3), cùng mục đích là xúc xắc nói chuyện với nhau mà không đổi mô hình gán. |
| 1c Rune chọn chủ động | Va `part-skill-identity.md` §3.4b (reviewer ghi chú 3) và ngoài bảng giá F4. Lõi gắn keyword theo vị trí slot đã thay vai trò, và nằm trong data của Lõi, không đụng `part_faces.json`. |
| 4c Forge node mới | Campfire event đã có "Forge" (+30% sáu mặt, `ContentDB.gd` ~603). Thêm node mới chạm INV-3/4 và shard sink. Giữ campfire như hiện tại. |
| 4b Thử thách | Làm sau. Cần cân phần thưởng, và Lõi đã là phần thưởng chính. |
| 5a Mutator | Cần field header action log + từng mutator là luật mới. Để đợt 2. |
| 1a Bond | Bộ Lõi đã bỏ ở 20/10 (mục 2.6). Việc "thưởng đội đồng class" do Lõi Hợp Đội / Đồng Tâm làm, việc "thưởng đội nhiều class" do Luật run Đại Hội Muôn Loài và Kẻ Lạc Loài (bump 2); không cần class-threshold riêng (reviewer ghi chú 4: không chồng F5). |
| 3c hành vi role quái | Chưa kiểm code, không đủ sức trong 3 ngày. |
| Thay toàn bộ relic engine | Không cần. `RelicHooks`, `RelicDef` (có sẵn `hidden_from_pool`), `RelicSlots` dùng lại. Chỉ thay NỘI DUNG và luồng nhận (mục 2.9). Đây là chỗ tiết kiệm lớn nhất. |

Giữ: Hold + Focus (gộp), mana-reroll, hàng trước/sau, affix Elite, nhịp boss, reward trên node (4a), Lõi (toàn bộ), sửa INV-6.

## 1. Nguyên tắc rút từ Lõi LoL

Nguồn tra (20/10): wiki LoL (Arena/Augments, ARAM Mayhem/Augments), trang hỗ trợ Riot về ARAM Mayhem, vài bài Mobalytics/AFK Gaming. Các nguồn này hơi mâu thuẫn nhau về mốc cụ thể (ví dụ cấp 3/7/11/15 hay không có cấp 3), và không xác nhận được tỉ lệ rơi hay giá reroll, nên tôi chỉ rút những gì ổn định: 3 bậc (Bạc/Vàng/Lăng Kính), mỗi lần hiện 3 lựa chọn, bậc của lần chọn là do game định chứ không do người chơi, có reroll rất ít (ARAM Mayhem: 1), tổng số ô nhỏ (khoảng 4-5), và có bộ Lõi cho thưởng khi gom cùng chủ đề. Lõi nhiệm vụ và Lõi đổi luật có trong cả hai chế độ theo hiểu biết chung, tôi không có số để trích.

Chín nguyên tắc áp dụng cho game xúc xắc theo lượt:

1. **Ít lần chọn nhưng mỗi lần nặng.** 4-6 lần chọn cả run, không phải 20 món nhỏ. Mỗi lần chọn là một ngã rẽ build, không phải "lấy cái nào cao hơn".
2. **Bậc do mốc quyết định, không do người chơi.** Mốc sớm ra bậc thấp, mốc muộn ra bậc cao. Người chơi biết trước mốc sau tốt hơn nên dám chọn Lõi "bắt đầu" hơi yếu mà hợp hướng.
3. **Ba lựa chọn phải khác nhau về hướng, không chỉ về số.** Ba thẻ có ba trục khác nhau (mặt, vị trí, mana...). Nếu ba thẻ cùng kiểu thì chọn là tính toán, không phải quyết định.
4. **Reroll hiếm và có giá.** Ít (2 lần cả run), mỗi lần đổi đúng một thẻ (bản 20/10 tối, theo Riot; bản đầu là đổi cả bộ ba). Hiếm để mỗi lần reroll là một quyết định "đổi cái chắc lấy cái may", và đổi từng thẻ thì quyết định là "cược ở thẻ nào".
5. **Lõi đổi luật mạnh hơn Lõi cộng số.** Phần lớn Lõi phải làm người chơi chơi khác (đổi cách gán xúc xắc, cách xếp đội, cách dùng mana). Lõi cộng chỉ số chỉ là đệm ở bậc thấp.
6. **Có đường build-around lộ ra, nhưng không bằng bộ.** (sửa vòng 2: bộ Lõi đã bỏ ở 2.6.) Đường build lộ ra từ Lõi đánh đổi và Lõi khuếch đại cái đội đang có (Kết, hàng trước, mana), không từ thưởng gom bộ.
7. **Lõi nhiệm vụ: rủi ro trước, thưởng sau.** Nhận sớm, hoàn thành điều kiện thì đổi thành một Lõi cao bậc. Thất bại không mất gì ngoài cơ hội. Tạo mục tiêu nhỏ giữa run.
8. **Tách bạch giữa pool và run, "run này khác run trước" đến từ bốn nguồn:** Luật run (2b), chuỗi bậc rút một lần mỗi run, 3 thẻ rút từ pool 46 Lõi, và các Lõi đổi luật làm cùng một đội chơi ra hai kiểu khác nhau. Không cần nhiều nội dung để run khác nhau, cần nhiều Lõi đổi hành vi.
9. **Không câu được Lõi cụ thể.** (sửa vòng 2: anti-repeat qua meta đã cắt.) Lõi đã hiện thì không hiện lại trong run (`core_seen`), không bao giờ hiện hai Lõi cùng trục trong cùng một bộ ba trừ khi pool hết.

### Một run trông thế nào (rút gọn, chế độ Short: 18 hàng, boss ở hàng 6/12/18, `run_map_generator.gd:47`)

- **Trước hàng 1.** Chọn đội 5 Axie. Chọn 1 trong 2 Luật run (từ run thứ 2 của tài khoản). Hiện 3 Lõi bậc Rêu. Ví dụ ba thẻ: "Chuỗi Mồi" (mặt), "Thành Trì" (vị trí), "Hồ Mana" (mana). Người chơi có đội 2 Plant 2 Aqua 1 Bird. Chọn Thành Trì: Plant xếp hàng trước. Quyết định thật đầu tiên: đội xếp thế nào.
- **Hàng 2-4.** Trận thường. Mỗi node trên map hiện biểu tượng loại phần thưởng (4a): level-up, hp, mảnh mặt. Người chơi đi đường có level-up cho Plant.
- **Hàng 5, Elite có affix "Gấp".** Elite này hiện công khai ngay trên map (lượt 3 nó đánh hai lần). Đội chưa có khiên tốt có thể né (và mất thưởng bậc cao hơn) hoặc nhận. Lõi lần 2 đến dù né hay nhận; thắng Elite có affix thì lần 2 lên một bậc so với chuỗi bậc (2.1).
- **Hàng 6, boss đầu.** Boss có nhịp 3 lượt công khai: Chuẩn bị, Đòn, Hở. Lượt Hở nhận thêm sát thương. Người chơi bắt đầu giữ (Hold) viên dmg 5 ở lượt Chuẩn bị để mở bằng nó đúng lượt Hở. Xong boss: Lõi lần 3 (bậc theo chuỗi, 65% run là Tinh Thể ở lần này).
- **Hàng 7-11.** Lõi nhiệm vụ đã nhận ở lần 2: Hồ Cạn "tiêu tổng 40 mana". Người chơi reroll nhiều hơn bình thường để xong sớm, vì phần thưởng là một lần chọn Hổ Phách giữa run.
- **Hàng 12, boss hai.** Lõi lần 4. Đội có 4 Lõi + 1 Luật run, mỗi Lõi một trục khác nhau là chuyện thường (không còn bộ).
- **Hàng 13-17.** Quyết định xếp đội lại trước mỗi trận (xếp lại miễn phí trước trận, đã có `reorder_party`).
- **Hàng 18, boss cuối.** Thắng. Run khác: người chơi kia nhận Lõi khác, có thể không bao giờ thấy Chuỗi Mồi.

Chế độ Full (30 hàng, boss 8/15/23/30) thêm hai lần chọn: sau Elite hàng 18 và sau boss 3.

## 2. Hệ Lõi mới

### 2.1 Cách nhận (viết lại 20/10 tối, theo nghiên cứu ARAM Hỗn Loạn + Võ Đài/TFT)

**Mốc chọn** (không đổi so với bản trước): lần 1 trước trận đầu; lần 2 sau node hàng 5 (Short); lần 3 sau boss 1; lần 4 sau boss 2; Full thêm lần 5 sau Elite hàng 18 và lần 6 sau boss 3. Lần 2 xảy ra dù người chơi né Elite (không mất lần chọn vì né), nhưng thắng Elite có affix (+) thì bậc lần 2 lên một bậc (chồng lên chuỗi bậc bên dưới, tối đa Tinh Thể).

**Bậc: chuỗi rút một lần lúc `new_run`** (kiểu TFT, thay bảng xác suất từng lần của bản cũ). Bậc của lần chọn là do game định, người chơi không chọn được. Lúc `new_run` rút một chuỗi bậc cho cả run bằng `Rng.new(seed ^ TIER_SALT)` từ bảng sau (Short, 4 lần chọn; mọi thẻ trong một lần chọn cùng bậc):

| Chuỗi (lần 1,2,3,4) | Trọng số | Ghi chú |
|---|---|---|
| R H T H | 30 | đỉnh giữa, người chơi biết trước lần 4 yếu hơn lần 3 |
| R H H T | 20 | đỉnh cuối |
| R R T H | 15 | |
| R H T T | 10 | run "điên", 2 đỉnh |
| R R T T | 10 | |
| R R H T | 10 | |
| R H H H | 5 | không đỉnh, hiếm |

R Rêu, H Hổ Phách, T Tinh Thể. (vòng 2 đổi trọng số: bản trước để "đỉnh cuối" nặng nhất, tức 50% run chỉ có T sau boss 2, dùng được cho 6 hàng cuối; nghiên cứu Võ Đài/TFT nguyên tắc 2 nói đỉnh phải tới trước boss 2. Giờ 65% run có T ở lần 3.) Trung bình 1.15 lần Tinh Thể mỗi run Short, 20% run có 2 lần, 5% không có (bản cũ trung bình ~6 thẻ T lộ ra, reviewer chê pool T bị đốt ngay run đầu). Quy tắc: lần 1 luôn là Rêu (trừ Luật run Mưa Sao); chuỗi không bao giờ rút T trước boss 1. T trước boss 1 chỉ có khi người chơi trả giá: thắng Elite có affix, Hoá Thạch, Luật Mưa Sao (cộng nhiều nguồn thì vẫn tối đa T). **Trần Tinh Thể** (vòng 2, knob `core_t_cap`): sở hữu tối đa 3 Lõi T ở Short, 4 ở Full, tính cả T từ nhiệm vụ, Hòn Đá Mờ, Quạ Đưa Tin. Lần chọn T khi đã đủ trần thì hạ xuống H. Lý do: có tới 7 đường cộng bậc (chuỗi, Elite, Hoá Thạch, Hòn Đá Mờ, Mưa Sao, Quạ Đưa Tin, nhiệm vụ), không có trần thì người chơi giỏi gom 5 T và game lại dễ. Full: chuỗi 4 như trên + hai lần cuối rút từ {H T 40, T T 25, H H 35}, tối đa 3 T cả run. Người chơi KHÔNG thấy chuỗi, chỉ thấy bậc của lần chọn hiện tại và (gợi ý UI, cần Liam duyệt) hiện chấm bậc của lần kế tiếp để dám chọn Lõi "bắt đầu" hợp hướng (nguyên tắc 2 của mục 1). Chuỗi nằm trong run save (như `PACT_SEED_SALT`, `RunState.gd` to_dict/from_dict), không thêm draw vào `_rng` chung.

**Số thẻ và chọn**: mỗi lần hiện 3 thẻ (4 thẻ ở lần 1 nếu đã mở perk relic khởi đầu, đã chốt 20/10), chọn 1, không có "bỏ qua".

**Reroll từng thẻ** (Riot: mỗi thẻ một lần): người chơi có **2 reroll Lõi cả run**. Mỗi reroll đổi ĐÚNG MỘT thẻ, thẻ mới cùng bậc, cùng trục với thẻ cũ nếu pool còn (hết thì một trục chưa có trong bộ ba), và mỗi vị trí thẻ chỉ reroll một lần mỗi lần chọn. Thẻ bị đổi ra không bao giờ quay lại trong run. KHÔNG bán reroll Lõi bằng tiền (Liam 20/10). Kỹ thuật (cần kiểm, lane B): `reroll_rewards` hiện đổi cả bộ; cần thêm tham số chỉ số thẻ, kiểm `ALLOWED_FNS` args ở GD + Worker + `t_replay`. Nếu tham số chỉ số thẻ làm đổi schema action quá nhiều thì lùi về "đổi cả bộ ba, cùng bậc" ở bump 1 và để từng-thẻ cho bump 2. **Đã chốt (Liam 20/10 khuya, câu 7): lùi được.** Khi lùi: 2 reroll vẫn là 2 lần đổi cả bộ ba, thẻ mới cùng bậc, mọi thẻ đã hiện vào `core_seen`, bỏ ràng buộc "cùng trục với thẻ cũ" và "mỗi vị trí một lần".

**Lõi đã hiện thì không hiện lại trong run** (thay anti-repeat qua meta, đã cắt): run save giữ `core_seen` (mọi id đã hiện, kể cả thẻ bị reroll). Chỉ trong run, không đụng meta save, nên không cần `MetaState.reload_from_store()`. Hệ quả có chủ ý: người chơi không thể "chờ Lõi X quay lại" hay ép build đã biết đáp án (nguyên tắc 12 ARAM).

**Ô**: 6 ô Lõi + 1 ô Luật run riêng. Short dùng tối đa 4 lần chọn + 1 nhiệm vụ nên không bao giờ đầy; Full 6 lần chọn + 1 nhiệm vụ = 7 > 6 nên đầy ô là chuyện Full. Bump 1: nếu đầy ô thì lần chọn đó hiện thẻ thường nhưng người chơi phải bán một Lõi cũ (dùng lại `RelicSlots.check_add`). **Bump 2**: kiểu Arena mùa 2, lần chọn khi đầy ô cho "nâng cấp Lõi" hoặc "bỏ một Lõi lấy Lõi cao hơn một bậc"; để sau vì cần data cấp 2 và loại thẻ mới. Cần kiểm: `RelicTuning` hiện 8 passive + 3 active + 1 G + 2 A ô nhân; chế độ Lõi đặt lại còn 6 + 1 và bỏ ô nhân/axis.

**Bậc dùng tên Axie**: **Rêu**, **Hổ Phách**, **Tinh Thể** (tên tạm; giữ `RelicDef.rarity` 0/1/2).

**Lõi nhiệm vụ** hoàn thành thì biến mất và trả thưởng theo bảng nhiệm vụ ở 2.7 (nhiều nấc, mỗi nấc trả riêng). Nhiệm vụ không tính vào các lần chọn và không đổi chuỗi bậc. Phần thưởng là thẻ chọn Lõi bậc Hổ Phách (nấc nhỏ) hoặc Tinh Thể (nấc cuối), chọn 1 trong 3 như thường, và áp các luật lọc / chống trùng / trần T như mọi lần chọn (luật rút thẻ ở 2.2, không có luật riêng).

**Thiếu pool**: nếu trục được rút không còn Lõi ở bậc của lần chọn sau khi lọc đội (2.2) và `core_seen`: lấy bậc gần nhất cùng trục; trục hết hẳn thì mới đổi trục. Bộ ba còn dưới 2 thẻ hợp lệ thì lấp bằng Lõi `stat` bậc Rêu (vẫn không lặp `core_seen`).

### 2.2 Hiện thẻ: ba thẻ khác trục

Mỗi thẻ có đúng 1 `axis`: `stat`, `dice` (mặt), `pos` (vị trí), `mana`, `quest`, `rule` (đổi luật). Luật rút:
- Thẻ 1: "thẻ theo hướng đang đi": một trục trùng với trục của Lõi đã sở hữu (nếu chưa có Lõi thì rút ngẫu nhiên).
- Thẻ 2: một trục khác thẻ 1, trong số trục người chơi chưa sở hữu.
- Thẻ 3: ngẫu nhiên thật, nhưng không trùng trục thẻ 1 hoặc 2 nếu pool còn.
- Lõi `quest` không xuất hiện ở lần chọn 1. Tối đa 1 thẻ `quest` mỗi bộ ba, và không được sở hữu hơn 1 Lõi `quest` chưa hoàn thành cùng lúc.
- Lõi `stat` chỉ ở bậc Rêu, tối đa 1 thẻ `stat` mỗi bộ ba (đệm yếu cho người cần).
- **Lọc Lõi chết, cho MỌI Lõi (mở rộng từ 3 Lõi của reviewer):** mỗi Lõi trong data có dòng `requires` (và tuỳ chọn `excludes`), kiểm trên đội và Luật run hiện tại TRƯỚC khi rút. Ví dụ `requires`: Hợp Đội cần 2+ Axie cùng class; Vòng Lặp cần mặt `cantrip`; Hàng Sau Phát Sáng cần hàng sau có mặt buff/heal/mana; Đồng Tâm cần 2+ Axie cùng class; Sóng Khiên cần 2+ mặt shield/heal; Xuống Trận cần một Axie hàng sau có mặt heal/buff; Mai Lớn Dần cần hàng trước có Axie; Chữ Ký Máu cần mặt poison. Thêm ở vòng 2: Trứng Vàng cần một nguồn Egg (đã sở hữu Tổ Ấm, hoặc đội có part sinh Egg); Đội Hình Mở cần đã sở hữu ít nhất 1 Lõi hàng trước; Đa Sắc cần dice của đội có ít nhất 4 loại mặt; Nhà Sưu Tầm cần ít nhất 5 loại mặt. `excludes`: Bức Tường Sống và Đội Hình Mở loại nhau; Lõi Rỗng và Khế Ước Gai loại nhau (cả hai thay giá reroll); Lõi hàng trước (Thành Trì, Mũi Giáo, Kẻ Gác Cổng, Mai Lớn Dần, Bức Tường Sống, Đội Hình Mở) loại khi Luật run là Thế Giới Lộn Ngược; Đội Hình Mở loại khi Luật là Thuỷ Triều Lên (không còn hàng sau thì luật mất nghĩa, còn -25% sát thương áp cả đội); Hồ Mana, Bể Tràn, Mạch Ngầm loại khi Luật là Thảo Nguyên Khô; Lõi Rỗng, Khế Ước Gai loại khi Luật là Mana Rẻ hoặc Băng Nguyên (luật phá spam reroll, Lõi trả lại spam reroll); Giữ Vững loại khi Luật là Băng Nguyên (luật đã cho giữ 2 viên); Thác Đổ loại khi Luật là Thế Cân Bằng R13. (Dòng "Hợp Đội, Đồng Tâm loại khi Đại Hội Muôn Loài" bỏ vì R12 cũ đã thay.) **Run đầu của tài khoản** (vòng 2, theo 9c.5): không hiện Lõi `quest` và hai Lõi cược (Hoá Thạch, Hòn Đá Mờ), vì "Lõi không làm gì ngay" là thứ người mới đọc không hiểu. Nguyên tắc (Võ Đài 4, ARAM 3): lọc "Lõi không làm được gì", KHÔNG lọc "Lõi tốt nhất cho đội". Đội mạnh về hướng nào cũng không được bảo đảm thẻ hợp hướng đó (tránh biến thành Legend của TFT). Cờ `disabled` trong data mỗi Lõi (tắt bằng data khi sim/chơi thử thấy hỏng, không cần build).

### 2.3 Chống trùng lặp

1. Không bao giờ nhận Lõi đã sở hữu.
2. Mỗi bộ ba khác trục (2.2).
3. Run khác run: bản cũ có "meta nhớ 12 Lõi cuối" và "chủ đề thiên vị ẩn x1.3". **Cả hai đã cắt** (Liam 20/10 bù thời gian cho Luật run; reviewer cũng nói x1.3 ẩn không ai cảm nhận được). Nguồn khác biệt giữa các run giờ là: (a) **Luật run** nhìn thấy được, mục 2b; (b) chuỗi bậc rút một lần mỗi run (2.1); (c) `core_seen` làm pool lộ dần trong run; (d) pool 46 Lõi với 15 Tinh Thể và nhiều Lõi đánh đổi, nên cùng một đội ra hai kiểu chơi.
4. Anti-repeat qua meta (tránh Lõi vừa thấy ở run trước) để bump 2 nếu chơi thử thấy người chơi gặp cùng 2-3 Lõi nhiều quá.

(reviewer, vẫn đúng) Chống trùng chỉ làm *thẻ* khác nhau chứ không làm *run* khác nhau; thứ làm run khác là Luật run và Lõi đánh đổi. Khi chơi thử phải theo dõi: Lõi nào được chọn trên 60% lần nó hiện thì đổi thành đánh đổi trước khi nerf số (nghiên cứu Võ Đài 5d.3).

### 2.4 Loại Lõi

| Loại | Vai trò | Số lượng đầu |
|---|---|---|
| stat | Đệm yếu, bậc Rêu (có một Lõi đánh đổi nhẹ) | 3 |
| dice (mặt) | Đổi cách mặt hoạt động, Mồi/Kết/Focus, bỏ mặt | 12 |
| pos (vị trí) | Hàng trước/sau, liền kề, đổi vai Axie | 9 |
| mana | Mana là tài nguyên chính, trả bằng máu | 7 |
| quest | Làm gì đó, nhiều nấc, trả thưởng giữa run | 5 |
| rule (đổi luật, gồm 2 Lõi cược bậc) | Một luật mới, ít nhưng mạnh | 10 |

**Tổng 46** (giữ 35 Lõi bản cũ, trong đó 15 đã được reviewer viết lại; thêm 11 Lõi mới từ hai bản nghiên cứu; bỏ 11 Lõi yếu/trùng/đã cắt). Phân bậc (đếm lại vòng 2 từ bảng 2.7): Rêu 13, Hổ Phách 18, Tinh Thể 15 (bản cũ 9 T). Theo trục ở bậc H thì `rule` chỉ có Trứng Vàng và Hòn Đá Mờ, `stat` không có; ở bậc T `mana` chỉ có Lõi Rỗng và Mạch Ngầm, nên lọc đội có thể làm trục đó hết và rơi vào luật "thiếu pool" 2.1, chuyện bình thường. Mọi Lõi Tinh Thể là luật hoặc đánh đổi, không cộng số thuần (Võ Đài nguyên tắc 4). Có Lõi đánh cược lên bậc (Hòn Đá Mờ, Hoá Thạch), Lõi nhiệm vụ nhiều nấc (Săn Chimera), Lõi tích luỹ cả run (Mai Lớn Dần), Lõi biến thất bại thành tài nguyên (Nổ Bào Tử). Bộ Lõi: bỏ, xem 2.6.

### 2.5 Từ vựng keyword mới dùng trong bảng (định nghĩa chi tiết ở mục 3)

- **Mồi** (prime): mặt có Mồi khi dùng sẽ "mồi" mặt dùng kế tiếp của Axie liền kề: +N giá trị.
- **Kết** (finish): mặt dùng cuối cùng trong lượt (viên cuối còn lại). 
- **Giữ** (hold): xem mục 3.2.
- **Focus**: mặt đang bị Giữ, lượt sau +N.
- **Hàng trước / hàng sau**: mục 4. Trước = roster 0-1, sau = roster 2-4.
- Giá trị trong bảng được đặt cho dice Common của Axie tier 1 (mặt dmg 2-5, shield 2-4, `ContentDB.gd` 227-250). Cần kiểm lại bằng sim sau khi hệ chạy được.

### 2.6 Bộ Lõi: BỎ ở bump 1 (quyết định 20/10 tối)

**Quyết định: bỏ bộ Lõi, không làm lại.** Lý do:
- Riot bỏ bộ Lõi ở ARAM 26.12 sau 4 tháng vì người chơi chọn Lõi để gom bộ, các build quy về cùng một kiểu, và Lõi lẻ bị coi là yếu. Bốn bộ ở bản cũ (Triều = 3 Lõi mana, Gai = 3 Lõi hàng trước, Nanh = 3 Lõi Kết, Tổ = 3 Lõi Egg) đúng là gom cùng một hành vi, tức chơi một kiểu ba lần. Đây cũng chính là lối "một chiều" Liam nói.
- Làm lại theo khung "ba món khác trục, thưởng nhỏ chỉ khuếch đại từng món" (nghiên cứu Võ Đài 5b) tốn thêm tracker bộ, text, UI tiến độ bộ, mà bump 1 đang gấp. Nó còn tạo một mục tiêu "săn đủ bộ" đúng thứ Riot vừa gỡ.
- Lõi lên cấp (Arena mùa 2) là hướng thay thế đúng hơn cho "đi sâu một hướng" và nằm ở **bump 2** cùng với "đầy ô thì nâng cấp" (2.1). Khi làm, mỗi Lõi cần data cấp 2; nên chọn trước 10-12 Lõi dễ lên cấp (Chuỗi Mồi, Kết Cục, Cất Lửa, Thành Trì, Mũi Giáo, Ngọn Triều, Hồ Mana...).
- Hệ quả cho bảng: bỏ cột "bộ" và `core_set`; `RelicDef` chỉ cần `core_axis` + `quest` + `requires`/`excludes`. Hai ý hay của bộ cũ gộp vào món lẻ cho khỏi mất: "Egg chết: mặt dmg kế tiếp của đội +3" thành dòng phụ của Trứng Vàng; "Phản Công" (mặt dmg kế tiếp +2 mỗi lần hàng trước nhận đòn đơn, tối đa +6) thành dòng phụ của Kẻ Gác Cổng. Hai Lõi Rêu Mạch Đá, Răng Mài, Móng Nhẹ cắt (chỉ cộng số).

### 2.7 Danh sách 46 Lõi (35 giữ từ bản cũ, 11 mới)

Bậc: R Rêu, H Hổ Phách, T Tinh Thể. Số đặt cho tier-1 Common; tất cả "cần kiểm bằng sim". "Kết hợp" nói Lõi nối với gì khác trong bảng hoặc mặt dice. Số `#` trong các bảng cũ là số cũ, KHÔNG đánh lại (tra theo tên). Chữ "(Gai)/(Triều)/(Nanh)/(Tổ)" cạnh tên là dấu vết của bộ đã bỏ, bỏ qua. Lõi mới của bản 20/10 tối nằm ở bảng "Lõi mới" cuối mục này (mã N1-N11). Các Lõi bị cắt khỏi bản cũ: Mạch Đá, Răng Mài, Móng Nhẹ, Mặt Đảo (Liam cắt), Hai Mặt (thay bằng Sóng Khiên), Đổi Chỗ (Liam cắt), Nợ Mana (thay bằng Khế Ước Gai), Mana Là Máu (trùng Búp Bê/Khế Ước), Vẹn Toàn (thay bằng Săn Chimera), Mẻ Trứng, Nhịp Nhanh (đã là Luật run Nhịp Gấp). Mọi Lõi có điều kiện đội có `requires`/`excludes` ở 2.2. Mọi Lõi có cờ `disabled`.

**stat (còn 2 trong bảng này + 1 mới N4 = 3)**

| # | Tên | B | Hiệu ứng | Thưởng lối chơi | Kết hợp |
|---|---|---|---|---|---|
| 2 | Vảy Sớm (Gai) | R | Đầu trận, Axie hàng trước có 5 khiên | Mở đầu an toàn | Thành Trì, Bức Tường Sống |
| 4 | Giọt Sương (Triều) | R | +1 mana đầu mỗi lượt | Mana, reroll trả mana | Hồ Mana |

**dice - mặt (7 trong bảng này + Ba Viên, Đồng Tâm ở bảng T bên dưới + N1-N3 = 12)**

| # | Tên | B | Hiệu ứng | Thưởng lối chơi | Kết hợp |
|---|---|---|---|---|---|
| 6 | Chuỗi Mồi | R | Mọi mặt shield/mana/buff có Mồi: mặt dmg dùng kế tiếp của Axie liền kề +3 | Dùng shield trước rồi đánh, thứ tự gán là quyết định | Hold, Thành Trì |
| 7 | Kết Cục (Nanh) | R | Mặt Kết (viên dùng cuối cùng trong lượt) +1 cho mỗi viên đã dùng trước nó trong lượt (đếm số viên, không đếm loại; tối đa +4) | Dùng hết 5 viên, dồn viên mạnh nhất cuối | Hold, Luật Kết Nặng (R5) |
| 8 | Đa Sắc | H | (reviewer sửa: bản cũ trùng Kết Cục và Chuỗi Mồi, cũng là "+N cho mặt sau") Cuối lượt, nếu đã dùng ít nhất 4 loại mặt khác nhau (dmg, shield, heal, poison, mana, debuff): cả đội +3 khiên và +2 mana | Đội đa loại, thưởng phòng thủ thay vì sát thương, kéo ngược với Thác Đổ | Nhà Sưu Tầm |
| 9 | Giữ Vững | H | Hold: giữ được 2 viên mỗi lượt thay vì 1, và được giữ cùng một viên 2 lượt liền (mục 3.2) | Lập kế hoạch dài hơi | Cất Lửa, boss nhịp |
| 10 | Cất Lửa | H | Mặt bị Giữ có Focus: lượt sau +4 (tối đa +8 khi giữ 2 lượt liền, cần Giữ Vững) | Tích đòn lớn cho lượt Hở của boss | Giữ Vững |
| 13 | Mặt Gương | T | (reviewer sửa: bản cũ "lặp nửa giá trị ở mục tiêu ngẫu nhiên" quá yếu cho bậc T) Viên dùng đầu tiên mỗi lượt không bị tiêu: dùng thêm được 1 lần nữa trong lượt, tự chọn mục tiêu. Lần hai không nhận Mồi, Kết, Focus | Mỗi lượt có một viên đánh hai lần, giữ viên tốt nhất để mở lượt | Hold, Thác Đổ |
| 14 | Con Xúc Xắc Thứ Sáu | T | Đầu lượt, thêm 1 viên phụ: roll mặt của Axie ngẫu nhiên còn sống (không tính Axie ngủ của Hiến Tế), dùng được lượt này, mất cuối lượt | Thêm 1 hành động mỗi lượt, đội 5 thành 6 viên | Đa Sắc |

**pos - vị trí (6 trong bảng này + Đội Hình Mở + N5, N6 = 9)**

| # | Tên | B | Hiệu ứng | Thưởng lối chơi | Kết hợp |
|---|---|---|---|---|---|
| 15 | Thành Trì (Gai) | R | Axie hàng trước nhận -2 mọi sát thương đơn mục tiêu | Đội tank trước, dps sau | Vảy Sớm, Kẻ Gác Cổng |
| 16 | ~~Mũi Giáo (Nanh)~~ **TẮT (2.10)** | R | Axie hàng trước: mặt dmg +2 | Đội đánh trước, chấp nhận nhận đòn | (tắt, không tính) |
| 17 | Kẻ Gác Cổng | H | Địch đánh đơn mục tiêu hàng trước chịu 3 thorns, xuyên giáp. **Phản Công** (từ bộ Gai cũ): mỗi lần hàng trước nhận đòn đơn (kể cả khiên chặn hết), mặt dmg kế tiếp của đội +2, cộng dồn tối đa +6, mất cuối lượt | Phòng thủ chủ động, biến đòn nhận thành sát thương | Thành Trì |
| 18 | Hàng Sau Phát Sáng | H | Axie hàng sau: mặt buff, heal, mana +50% (làm tròn lên) | Support sau lưng | Giọt Sương |
| 20 | ~~Hợp Đội~~ **TẮT (2.10)** | H | Axie đứng liền kề ít nhất một Axie cùng class: mọi mặt dmg +2 (không cộng dồn theo số cặp) (reviewer: +1 quá nhỏ, không ai đổi đội vì +1) | Đội đồng class (thay Bond) | Resonance |
| 21 | Bức Tường Sống | T | (reviewer thay Cánh Kép: Cánh Kép gần như trùng luật nền mục 4, quái đã chỉ đánh đơn hàng trước) Hàng trước chỉ còn 1 ô (roster 0). Axie ô 0 +12 Max HP, Thorns 2. Bốn Axie còn lại là hàng sau. Chỉ đổi knob số ô hàng trước + chỉ số | Một tank gánh, bốn Axie đánh an toàn; mất tank là vỡ trận | Thành Trì, Kẻ Gác Cổng, Vảy Sớm |

**mana (6 trong bảng này + N7 = 7)**

| # | Tên | B | Hiệu ứng | Thưởng lối chơi | Kết hợp |
|---|---|---|---|---|---|
| 22 | Ngọn Triều (Triều) | R | Mỗi 3 mana tiêu: 2 dmg tất cả địch (reviewer hạ từ 4: 4 AoE trên 2-3 quái là 8-12 dmg, bằng cả đội đánh một lượt đầu run, quá mạnh cho bậc Rêu) | Tiêu mana liên tục | Hồ Mana, Lõi Rỗng |
| 23 | Hồ Mana (Triều) | R | (reviewer viết lại, vì mana đã không cap và đã giữ qua lượt, chỉ reset đầu trận `combat_engine.gd:180`) **Lãi mana**: mặt mana +1; cuối lượt, cứ mỗi 3 mana chưa tiêu thì nhận thêm 1 mana (tối đa +3 mỗi lượt) | Để dành hay tiêu: kéo ngược với Ngọn Triều | Ngọn Triều, Bể Tràn, Mạch Ngầm |
| 25 | Đổi Mana Lấy Khiên | H | Cuối lượt, tự tiêu mana chưa dùng (tối đa 6): mỗi 2 mana thành 3 khiên cho mỗi Axie hàng trước. (reviewer sửa: bản cũ không tiêu mana mà mana không cap, cộng Hồ Mana là khiên vô hạn cho cả đội) | Mana thành phòng thủ | Bức Tường Sống |
| 26 | Bể Tràn | H | Mana vượt 8: phần dư lập tức thành sát thương xuyên giáp toàn địch (mana về 8). Dùng lại đường xả `manaOverflow` có sẵn (`:1370-1376`) | Burst mana | Hồ Mana |
| 27 | Lõi Rỗng | T | (reviewer viết lại: bản cũ "mặt mana đổi thành reroll" là đổi 1 mana lấy 1 reroll, nhỏ cho bậc T) Không còn reroll miễn phí. Mọi reroll tốn 1 mana, trần reroll mỗi lượt từ 4 lên 8. Mặt mana +1. (vòng 2 thêm, vì bản trên gần trùng Luật run Mana Rẻ mà lại là Lõi T) Mỗi lần reroll một viên, viên đó +1 giá trị tới hết lượt (cộng dồn, trong trần +10) | Run "câu" mặt: đội mana reroll tới khi ra đúng mặt cần, câu lâu thì viên càng nặng | Hồ Mana, Mạch Ngầm, Ngọn Triều |
| 28 | Mạch Ngầm | T | (reviewer thay Thuế Tái Sinh: hồi sinh chỉ là bảo hiểm, không đổi cách chơi) Mana dư cuối trận được mang sang trận sau, tối đa 12 (không reset đầu trận). Cần field trong `RunState` + save, đi qua replay như các số run khác | Chơi tiết kiệm ở trận thường để dồn mana cho Elite và boss | Hồ Mana, Bể Tràn, Lõi Rỗng |

**quest - nhiệm vụ (4 trong bảng này + N8 Săn Chimera = 5)** Hoàn thành -> một lần chọn bonus: bậc Hổ Phách cho nhiệm vụ Rêu/Hổ Phách một nấc (Nhà Sưu Tầm, Hồ Cạn, Trọng Điểm), Tinh Thể cho Kẻ Gác Đêm (khó nhất, có thể mất Axie). Chọn 1 trong 3, rút theo đúng luật 2.2 (vòng 2 sửa: bản trước ghi "khác trục với Lõi đang giữ", ngược với thẻ 1 của 2.2), có trần T. Nhiệm vụ trả thưởng NGAY khi xong (giữa run, còn dùng được), không đợi hết run. Nhiệm vụ hỏng không phạt, chỉ mất cơ hội; nếu điều kiện không thể đạt nữa (hết trận còn lại) nhiệm vụ tự biến mất và nhường ô.

| # | Tên | B | Điều kiện (đếm trên các trận kế tiếp) | Khi chưa xong cho | Kết hợp |
|---|---|---|---|---|---|
| 30 | Nhà Sưu Tầm | R | Dùng 5 loại mặt khác nhau trong một lượt, ở 3 trận khác nhau (reviewer sửa từ "3 loại, 4 trận": 3 loại là dmg + shield + mana, lượt nào cũng có, nhiệm vụ cho không) | +1 mana mỗi lượt | Đa Sắc |
| 31 | Hồ Cạn | H | Tiêu tổng 40 mana qua các trận | +2 mana đầu trận (reviewer sửa: bản cũ "cap +2" mà mana không có cap) | Hồ Mana |
| 32 | Kẻ Gác Đêm | H | Thắng boss kế tiếp mà không mất Axie nào (reviewer sửa từ "1 Elite": sau lần chọn 2 có thể không còn Elite trên đường, nhiệm vụ thành không làm được) | Hàng trước +3 Max HP | Thành Trì |
| 33 | Trọng Điểm | H | Dùng một viên đã Giữ gây >= 9 sát thương, 3 lần (reviewer hạ từ 12: tier-1 mặt dmg 2-5, không có Cất Lửa thì 12 gần như không đạt, nhiệm vụ thành bẫy; số chốt bằng sim) | Hold: được giữ cùng một viên 2 lượt liền | Cất Lửa |

**rule - đổi luật (6 trong bảng này + Hiến Tế + N9-N11 = 10)**

| # | Tên | B | Hiệu ứng | Thưởng lối chơi | Kết hợp |
|---|---|---|---|---|---|
| 34 | Tổ Ấm (Tổ) | R | Đầu trận, 1 Egg (dùng `start_eggs` có sẵn). Egg tính là hàng trước: quái đánh đơn được chọn nó. (reviewer sửa: bản cũ để Egg ở hàng sau, không bị đánh đơn, thì Trứng Vàng và bộ Tổ gần như không bao giờ kích hoạt) | Egg làm bia đỡ cho hàng trước | Trứng Vàng |
| 35 | Trứng Vàng | H | Egg chết: tạo 3 mana, 1 khiên 4 cho Axie yếu nhất, và mặt dmg kế tiếp của đội +3 (từ bộ Tổ cũ) | Egg là tài nguyên, chết là có lời | Hồ Mana, Tổ Ấm |
| 37 | Chữ Ký Máu | T | Mặt dmg gây thêm 1 poison mỗi 3 sát thương (làm tròn xuống). Mặt poison gây sát thương bằng nửa giá trị (phần sát thương này không tính là mặt dmg, không sinh poison lại) | Poison biến thành dmg lẫn nhau | Sóng Khiên, Luật Rừng Già |
| 38 | ~~Phán Quyết~~ **TẮT (2.10)** | T | Địch dưới 20% HP chết ngay (boss không). Mặt Kết luôn có Execute | Đội burst | (tắt, không tính) |
| 39 | Vòng Lặp | T | Mặt có `cantrip` roll lại và dùng thêm một lần mỗi lượt (đã có luật cantrip trong `_resolve_cantrips`) | Đội ears, mana nhiều | Hồ Mana |
| 40 | Thác Đổ | T | (reviewer thay Cổng Hai Chiều: Resonance là x1.15 trên mặt 2-5, tức +0 tới +1 sau làm tròn, không đủ cho bậc T) Mặt dmg dùng liền nhau trong lượt thành chuỗi, không cần liền kề: mặt dmg thứ 2 liên tiếp +2, thứ 3 +4, thứ 4 +6, từ thứ 5 +8. Dùng một mặt không phải dmg là đứt chuỗi | Đội dồn dmg, chơi ngược hẳn Đa Sắc / Chuỗi Mồi (dùng shield trước là phá chuỗi) | Con Xúc Xắc Thứ Sáu, Mặt Gương |

**Lõi Tinh Thể do reviewer viết (còn 4 sau khi bỏ Nhịp Nhanh và Mana Là Máu).** Lý do ở ghi chú reviewer 1: pool T quá nhỏ. Tất cả là luật mới hoặc knob, không cần action mới. Nay là Lõi chính thức của pool, không còn là "dự phòng". Ưu tiên hơn Lõi Rêu khi phải cắt.

| # | Tên | Trục | Hiệu ứng | Thưởng lối chơi |
|---|---|---|---|---|
| 41 | Hiến Tế | rule | Đầu trận, Axie ô 4 ngủ (không có viên, không bị chọn làm mục tiêu, không chết). Bốn viên còn lại mỗi mặt +2, thêm 1 reroll miễn phí mỗi lượt | Chơi 4 viên mạnh thay vì 5 viên thường; đội đổi cách xếp |
| 43 | Đội Hình Mở | pos | Không còn hàng sau: cả 5 Axie là hàng trước, quái đánh đơn chọn ngẫu nhiên như trước bản này. Mọi Lõi "hàng trước" áp cho cả đội, đủ giá trị. (vòng 2 sửa từ "nửa giá trị": luật nền đã cho đòn đơn chỉ trúng hàng trước, nên Thành Trì nửa giá trị toàn đội là -1 thay vì -2 trên cùng những đòn đó, tức Lõi T làm đội yếu đi. Giờ chỉ hiện khi đã có Lõi hàng trước, xem 2.2) | Ngược hẳn Bức Tường Sống; Thành Trì -2 cả đội, Vảy Sớm khiên cả đội, đổi lại support bị đánh đơn |
| 45 | Ba Viên | dice | Mỗi lượt chỉ được dùng tối đa 3 viên (lần dùng lại của Mặt Gương tính là một lần dùng). Viên không dùng cuối lượt tự Giữ (không tính vào giới hạn Hold) và có Focus +3 lượt sau | Chơi ít viên, tích lực; ăn khớp Cất Lửa, nhịp boss |
| 46 | Đồng Tâm | dice | Đầu lượt, mọi Axie cùng class roll ra cùng chỉ số part (cùng một lần rút cho cả class). Mỗi mặt dùng mà cùng part với mặt trước đó: +2 | Đội đồng class chơi kiểu được ăn cả ngã về không; chỉ hiện nếu đội có 2+ Axie cùng class |

**Lõi mới (11) từ nghiên cứu ARAM Hỗn Loạn + Võ Đài/TFT, 20/10 tối.** Tên mượn tinh thần Lõi LoL (cột cuối), số chưa sim, mọi bonus phẳng vẫn tính vào trần +10/mặt (mục 3.4).

| Mã | Tên | B | Trục | Hiệu ứng | Thưởng lối chơi | Kết hợp | Gốc LoL |
|---|---|---|---|---|---|---|---|
| N1 | Sóng Khiên | H | dice | Mặt shield/heal cũng gây sát thương bằng 50% giá trị (làm tròn lên) lên quái đang nhắm Axie nhận khiên/heal (không có đòn đơn thì quái ngẫu nhiên). Thay Hai Mặt | Đội support/khiên vẫn thắng bằng mặt back/eyes | Thành Trì, Hàng Sau Phát Sáng | Sonic Boom, Holy Fire |
| N2 | ~~Tích Ác~~ **TẮT (2.10)** | H | dice | Mỗi lần mặt Kết hạ một quái: mặt Kết +1 vĩnh viễn cả run, tối đa +6. Cần field run (như Mạch Ngầm) | Run mạnh dần nếu canh Kết đúng lúc kết liễu, chọn mục tiêu | Kết Cục, Cất Lửa | Phenomenal Evil |
| N3 | Gọt Xúc Xắc | T | dice | Thẻ ghi sẵn một slot part (game chọn slot có tổng giá trị mặt thấp nhất của đội). Mặt slot đó bị khoá trên mọi viên: viên ra mặt đó tự roll lại một lần. Mọi mặt còn lại +1. Chỉ đổi dữ liệu mặt lúc dựng đơn vị (`apply_mod_faces`) | Đội muốn bỏ mặt yếu, ổn định hơn; xúc xắc thành 5 mặt | Kết Cục, Thác Đổ | Back to Basics |
| N4 | Thân Cổ Thụ | R | stat | Mọi Axie +8 Max HP, mọi mặt dmg -1 (tối thiểu 1). Lõi stat duy nhất có giá | Đội rùa, trận dài | Bức Tường Sống, Sóng Khiên | Celestial Body |
| N5 | Mai Lớn Dần | H | pos | Mỗi quái bị Axie hàng trước kết liễu: Axie đó +1 Max HP vĩnh viễn trong run (không trần). Axie ngã trong trận: mất 2/3 chồng (làm tròn lên). Cần field run theo Axie; cắt nếu trễ | Tank tự đi kết liễu, đội đẩy đòn cuối cho hàng trước; cảm giác lớn dần | Thành Trì, Bức Tường Sống | Tank Engine |
| N6 | Xuống Trận | T | pos | Thẻ ghi sẵn tên Axie hàng sau có nhiều mặt heal/buff nhất. Nhận: nó chuyển vĩnh viễn lên hàng trước, mặt heal/buff thành mặt dmg cùng giá trị +2, +8 Max HP, hút máu 30% (cần kiểm hook hút máu) | Support thành đấu sĩ, đội đổi vai giữa run | Thành Trì, Kẻ Gác Cổng | Draw Your Sword |
| N7 | Khế Ước Gai | H | mana | Reroll không tốn mana mà tốn 2 HP của Axie có viên đó; Axie còn 2 HP trở xuống thì viên đó không reroll được. Axie đã mất từ 50% HP: mọi mặt +2. Thay Nợ Mana. (vòng 2 sửa: bản trước "không xuống dưới 1 HP" làm Axie hàng sau đứng ở 1 HP, không bị đòn đơn chạm, reroll miễn phí tới trần mỗi lượt và ăn +2 mọi mặt cả run) | Chơi sống mép, đội có heal | Hàng Sau Phát Sáng | Ominous Pact |
| N8 | Săn Chimera | H | quest (nhiều nấc) | Nấc 1: hạ 8 quái bằng mặt Kết -> +1 reroll Lõi (tối đa +1 cả run). Nấc 2: hạ 20 quái -> một lần chọn Lõi Hổ Phách. Nấc 3: hạ một boss bằng mặt Kết -> một lần chọn Lõi Tinh Thể. Trượt nấc nào cũng không mất gì đã nhận | Mục tiêu nhỏ suốt run, không có cảnh "trượt một ngưỡng là mất hết" | Kết Cục, Luật Kết Nặng (R5) | Urf's Champion + nhiệm vụ nhiều nấc 26.12 |
| N9 | Nổ Bào Tử | R | rule | Axie ngã thì nổ: mỗi quái mất 20% Max HP của nó (boss 8%), xuyên khiên. Egg nổ nửa giá trị | Đội chấp nhận mất người, Axie yếu hàng trước làm bom; biến thất bại thành tài nguyên | Tổ Ấm, Trứng Vàng | Dive Bomber |
| N10 | Hoá Thạch | R | rule (cược) | Không có hiệu ứng ngay, chiếm ô tạm. Lần chọn Lõi kế tiếp lên một bậc (đã là Tinh Thể thì có 4 thẻ; đã có 4 thẻ thì +1 reroll Lõi). Xong thì tự biến mất. Chỉ hiện ở lần chọn 1-2. Lên T ở lần 2 là hợp lệ (người chơi đã trả bằng một lần chọn), vẫn chịu trần T | Hi sinh sức sớm lấy đỉnh sau; rủi ro nếu boss 1 đến trước khi có Lõi hợp | Mọi Lõi T | Transmute |
| N11 | Hòn Đá Mờ | H | rule (cược) | Chọn thẻ này: không nhận gì ngay, nhận 1 Lõi Tinh Thể ngẫu nhiên (khác trục với 2 thẻ còn lại, lọc đội vẫn áp, ghi `core_seen`). Không hiện nếu chuỗi bậc đã có 2 T, không hiện ở lần chọn 2 (giữ "không T trước boss 1 mà không trả giá"), không hiện ở lần chọn cuối của chế độ, chịu trần T. Giá: đổi hai thẻ Hổ Phách biết trước lấy một Lõi T không biết trước, mà Lõi T nào cũng là đánh đổi nên có thể kéo ngược build | Người thích cược, người thiếu "đỉnh". Loại được chọn nhiều nhất ở ARAM; theo dõi tỉ lệ chọn (2.3) | Mọi Lõi T | Transmute: Prismatic |

Chưa vào bump 1 nhưng nên ghi lại (ưu tiên cho bump 2 khi có Lõi lên cấp): **Trăng Thứ Hai** (T, một lần/trận được thêm một lượt EXECUTE; cần action và log lượt mới), **Vòng Tử Sinh** (T, 70% heal thành sát thương), **Thợ Săn** (H, kết liễu thì viên quay lại tay), **Búp Bê Lồng** (T, ngã đứng dậy 40% HP nhưng mất mặt mạnh nhất), **Kẻ Lạc Loài** (H), **Hai Dạng** (T, chọn To/Nhỏ mỗi trận, cần UI chọn mỗi trận).

**Hai build phải thử đầu tiên khi chơi thử** (từ reviewer + nghiên cứu): Thác Đổ + Xúc Xắc Thứ Sáu + Mặt Gương; Bức Tường Sống + Kẻ Gác Cổng + Hàng Sau Phát Sáng (rùa). Thêm một build mới cần thử: Sóng Khiên + Hàng Sau Phát Sáng + Chữ Ký Máu (support thành sát thương).

### 2.8 Số phận relic cũ

- Hiện có **133** file `.tres` trong `godot/resources/relics/` (đếm bằng Grep dòng `layer =`, đã có từ `relic-system.md` 94 + `relic-set-v2` + hook mới). `reward_generator.gd` nhận relic qua `pick_offer_relic`, shop qua `generate_shop_items`, event qua `event_option_rarity`, boss qua `pick_pact_offer`.
- **Giữ nguyên cho dữ liệu / replay cũ:** tất cả file cũ GIỮ, đặt `hidden_from_pool = true` (đã có sẵn trong `RelicDef`). `RelicRegistry.get_def` vẫn trả được nên save/replay cũ không vỡ. Không xoá, vì xoá phá `t_relic_*` và replay cũ.
- **Tái dùng hook:** các Lõi rule/pos/mana cần hook. Phần lớn gắn vào `RelicHooks.TABLE` có sẵn (ví dụ Chữ Ký Máu gần `r_bloodmouth`/poison hook, Phán Quyết gần `r_apexferal`, Vòng Lặp gần `cantrip`). Cần kiểm từng Lõi xem hook nào đã có, hook nào phải viết (lane C).
- **Pact (boss)**: giữ cơ chế Pact hiện tại. Bump 1: pact vẫn là relic cũ (ẩn khỏi pool thường); đổi thành Lõi Tinh Thể có hại để bump 2 (mặc định, xem mục 10).
- **Shop:** bán relic cũ -> thôi. Shop vẫn mở nhưng bán: hồi máu và nhận một lần chọn Lõi bậc Rêu bằng tiền trong run (tiền trong game, không phải tiền thật; cần định giá, giao economy-designer). KHÔNG có reroll Lõi bán bằng tiền thật, không SKU mới (Liam 20/10). Event "chest", "bet_small" từng cho relic: đổi thành cho 1 lần chọn Lõi bậc tương ứng. Cần kiểm danh sách đầy đủ event có `relic` trong `ContentDB.gd`.
- **Save người chơi cũ:** RULES_VERSION bump làm run đang chơi không verify được (đã kiểm: save run mang `rules_version` `RunState.gd:1846`; lệch thì `resumable:false, reason:"rules"` `:1884`, load từ chối `:1958`, `discard_unresumable_run()` xoá file + đóng mission mirror + `discard_notice`. Đề xuất 'huỷ không phạt' đã là hành vi sẵn có; ghi chú QA 13/10 B9-3 'save không có rules_version' đã cũ). Đề xuất: run dở bị huỷ, không phạt, meta/vault/echo box giữ nguyên. Meta không giữ relic: `MetaState.gd` chỉ có perk `relic0/relic1` cho relic khởi đầu (dòng ~1113-1125). **Đã chốt (Liam 20/10): đổi thành "lần chọn Lõi 1 có thẻ thứ 4"**; người đã mở perk không mất gì, và chỉ lần 1 mới có 4 thẻ (Luật run Đất Hoang cũng cho 4 thẻ, hai thứ không chồng: tối đa 4). `echobox.json` chỉ có tên xúc xắc cosmetic `die_l_relic_stone`, không ảnh hưởng.

### 2.9 Luồng nhận trong code (chỉ để lane B làm)

Tái dùng `RunState.acquire_relic(id, source, sell_id)`; Lõi là RelicDef có `core_axis` (field mới), `requires` / `excludes` (field mới, 2.2), `disabled` (cờ), `quest` (Dictionary mới: `{kind, steps:[{target, reward_tier}]}`, nhiều nấc). Không có `core_set` (bộ đã bỏ, 2.6). Ô nhân G/A bỏ ở chế độ Lõi (đặt `mult_axis = ""`). Offer Lõi dùng hàm riêng (không dùng `RewardGenerator.generate`), rng riêng `Rng.new(epoch_reward_seed ^ CORE_SALT)`, chỉ đi chung đường `take_reward` / `reroll_rewards`; chuỗi bậc ở `Rng.new(seed ^ TIER_SALT)`. Run save thêm: `core_tier_chain`, `core_seen`, `core_reroll_left`, `core_quest_progress`, `run_rule` (2b). Không thêm draw vào `_rng` chung. Lõi cần action mới: không có Lõi nào trong 46 phải có action mới (Mặt Đảo, Đổi Chỗ đã cắt). Hai Lõi có nguy cơ cần field run/hook lạ: Mai Lớn Dần (field theo Axie/run; Tích Ác đã tắt ở 2.10), Xuống Trận (hút máu, đổi hàng vĩnh viễn); trễ thì cắt theo thứ tự đó.

### 2.10 Đổi pool Lõi để "chỉ đánh" không đủ (Liam chốt 20/10 khuya)

Giữ 46 Lõi: **tắt 4, thêm 4** (4 Lõi tắt đặt `disabled = true`, giữ data, không xoá). Lõi cắt toàn là thưởng attack thuần: Mũi Giáo (R, +2 dmg hàng trước), Hợp Đội (H, +2 dmg cùng class), Tích Ác (H, Kết +1 mỗi lần kết liễu), Phán Quyết (T, địch dưới 20% HP chết ngay). (vòng 3) Đã gỡ 4 Lõi này khỏi cột "Kết hợp" ở 2.7 và gạch tên trong bảng; danh sách cắt mục 9 không còn nhắc Tích Ác. Phân bậc sau đổi: Rêu 12, Hổ Phách 19, Tinh Thể 15 (tổng 46); trục `pos` còn 7, `dice` 15, `rule` 9. Rêu `pos` chỉ còn Thành Trì, nên luật "thiếu pool" (2.1) chạy thường hơn ở lần chọn 1; chấp nhận.

| Mã | Tên | B | Trục | Hiệu ứng | Vai |
|---|---|---|---|---|---|
| N12 | Vết Nứt | H | dice | Mặt poison/debuff trúng quái: quái đó nhận +25% từ mọi nguồn dmg tới hết lượt kế và mất Giáp (6.7 M1) | Debuff thành nguồn sát thương, phá Giáp, chống Phản Đòn |
| N13 | Y Sĩ Chiến Trường | H | dice | Mặt dmg -2 (tối thiểu 1). Mặt heal, shield, poison, mana, debuff +3 | **Đánh đổi**: attack yếu đi, mọi thứ khác mạnh lên |
| N14 | Độc Lan | H | dice | Quái đang poison chết: poison còn lại của nó lan hết cho các quái còn sống. Mặt poison +2 stack | Poison thành build chính, AoE gián tiếp |
| N15 | Lò Độc | T | dice | Mặt dmg -2 (tối thiểu 1). Cuối lượt, mọi quái đang poison nhận thêm poison bằng 50% stack hiện có (làm tròn lên, tối đa +4) | **Đánh đổi** T: bỏ attack, sống bằng poison; ngược hẳn Chữ Ký Máu về nguồn gốc nhưng cùng trục |

`requires`: Độc Lan, Lò Độc cần đội có mặt poison; Vết Nứt cần mặt poison hoặc debuff; Y Sĩ cần 2+ mặt không phải dmg. `excludes`: Y Sĩ và Lò Độc loại nhau (cùng -2 dmg), Lò Độc loại Thác Đổ. Cần kiểm: mặt poison "xuyên khiên" hiện tại có đúng không (ảnh hưởng M2 ở 6.7).

**Đã có sẵn trong pool, đếm lại cho khớp yêu cầu** (Lane C xác nhận bằng tag `rewards` trong `t_core_catalog`):
- Thưởng mặt không phải attack hoặc vị trí/Hold: Giọt Sương, Chuỗi Mồi, Đa Sắc, Giữ Vững, Cất Lửa, Thành Trì, Kẻ Gác Cổng, Hàng Sau Phát Sáng, Bức Tường Sống, Ngọn Triều, Hồ Mana, Đổi Mana Lấy Khiên, Bể Tràn, Lõi Rỗng, Mạch Ngầm, Tổ Ấm, Trứng Vàng, Hiến Tế, Ba Viên, Khế Ước Gai, cùng 4 Lõi mới ở trên và các nhiệm vụ: ước 25-27 trên 46. Kiểm test: >= 24.
- Biến mặt phụ thành sát thương: Chuỗi Mồi (shield/mana/buff mồi dmg), Sóng Khiên (shield/heal thành dmg), Chữ Ký Máu (poison thành dmg), Bể Tràn (mana thành dmg), Ngọn Triều (mana tiêu thành AoE), Xuống Trận (heal thành dmg), Vết Nứt, Độc Lan: >= 7. Kiểm test: >= 6.
- Đánh đổi "attack yếu, thứ khác mạnh": Thân Cổ Thụ, Y Sĩ Chiến Trường, Lò Độc, Hiến Tế (4 viên), Ba Viên (3 viên): >= 3.

## 2b. Luật run (mới, 20/10 tối)

Mẫu: Cổng của TFT (luật cả ván, chọn đầu ván, tất cả thấy) + nguyên tắc 6, 7 của nghiên cứu Võ Đài/TFT. Mục đích: run sau khác run trước từ chính trận đầu, và phá lối chơi trội bằng luật chứ không bằng nerf.

### 2b.1 Cách nhận

- Trước lần chọn Lõi 1, hiện **2 Luật run**, chọn 1. Rút từ pool 13 luật có trọng số (2b.2) bằng `Rng.new(run_seed ^ RULE_SALT)`, không lặp. **Hiện SAU khi chọn đội và vào run** (Liam chốt 20/10 khuya, giữ luồng hiện tại; không luật nào được phụ thuộc lúc dựng đội). Đã chọn rồi thì cả run không đổi, không có reroll Luật run.
- **Run đầu tiên của tài khoản không có Luật run** (reviewer 9c.5: không dạy mọi thứ cùng lúc). Từ run thứ 2: 10% một trong hai thẻ là "Không luật" (chơi nền, kiểu Riven), 90% là luật thật (**đã chốt**, Liam 20/10 khuya, câu 8). **Ascension A3+ (đã chốt)**: nền đã mất reroll miễn phí và mọi reroll tốn mana, nên R1 Mana Rẻ bỏ khỏi pool ở A3+ (luật thành vô nghĩa), R2 Băng Nguyên chỉ còn phần giữ 2 viên + Focus (ghi trong text luật khi A3+). Lõi Rỗng ở A3+ chỉ còn phần trần 8 reroll + mana +1 + dòng cộng dồn mỗi reroll; Khế Ước Gai vẫn thay giá mana bằng HP. Cờ cho người mới nhưng không bắt buộc: UI nhận biết "run đầu" bằng `META.runs == 0` (cần kiểm tên field). (vòng 2) Cùng cờ đó: run đầu không có Lõi `quest`, không có Lõi cược (2.2), và tắt affix Elite (9c.5 đã đề nghị nhưng 6.4 chưa ghi). Run đầu chỉ còn Hold, hàng, mana-reroll, nhịp boss và Lõi thường, vẫn nhiều nhưng học được.
- Làm như một Lõi ẩn: `core_axis = "run_rule"`, `hidden_from_pool`, ô riêng (ô thứ 7), nhận qua `take_reward` có sẵn, không action mới, không field header action log (theo 9b/9c). Mỗi luật chỉ chỉnh knob mà bump 1 đã tạo (hoặc dữ liệu thuần), nên làn A thêm knob, làn C viết data, làn D dùng lại màn chọn Lõi với 2 thẻ.
- Mỗi luật đọc được trong **một câu**, có một lợi và một giá. Cờ `disabled` trong data để tắt khi chơi thử thấy hỏng.
- Luật run cũng đi vào luật lọc 2.2 (`excludes`): Lõi nào vô nghĩa dưới luật đang giữ thì không được hiện.
- (vòng 2) "Không còn reroll miễn phí" ở R1, R2 chỉ bỏ reroll miễn phí của nền. Reroll miễn phí do Lõi (Hiến Tế), Aid, passive Aqua cho thì vẫn giữ. Một dòng này tránh phải viết ngoại lệ cho từng Lõi.
- Không luật nào đụng map (map dùng rng chung, 7.1). Cờ theo trận (Thuỷ Triều Lên) dùng salt riêng + số trận.

### 2b.2 Danh sách 13 luật cho bump 1 (12 cũ, R12 thay, thêm R13; trọng số: R10, R12, R13 = 2, còn lại 1)

| # | Tên | Luật (một câu) | Giá | Phá lối trội nào | Cần |
|---|---|---|---|---|---|
| R1 | Mana Rẻ | Mọi reroll tốn 1 mana, không còn reroll miễn phí, trần 5 reroll mỗi lượt | Đội không mana bị kẹt | Lối chờ reroll miễn phí tìm mặt đẹp, đội không đầu tư mana | knob `reroll_mana_cost`, `free_reroll` |
| R2 | Băng Nguyên | Không còn reroll miễn phí (reroll 2 mana). Giữ được 2 viên, viên Giữ +2 khi dùng lượt sau | Reroll đắt hơn | Lối reroll tới khi ra mặt đẹp; thưởng kế hoạch 2 lượt | knob `stash_max`, Focus |
| R3 | Nhịp Gấp | Nhịp boss chỉ 2 lượt (Đòn, Hở xen kẽ), lượt Đòn mạnh thêm 20% | Phải phòng thủ dày hơn | Lối rùa / kéo dài trận chờ boss | knob độ dài nhịp |
| R4 | Mưa Sao Khởi Nguyên | Lần chọn Lõi 1 là Tinh Thể. Quái thường và Elite +15% HP cả run | Trận dài hơn | Lối an toàn dựa Lõi Rêu đệm; ép build-around từ trận đầu | knob bậc lần 1 + knob HP |
| R5 | Kết Nặng | Mặt Kết mọi Axie +3, quái +10% sát thương | Trả giá bằng sát thương nhận | Lối không quan tâm thứ tự dùng viên | knob Kết, `enemy_dmg_mult` |
| R6 | Đất Hoang Huyền Bí | Chỉ 3 lần chọn Lõi (bỏ lần sau Elite, dùng bậc lần 1, 3, 4 của chuỗi), mỗi lần 4 thẻ. Mọi Axie +4 Max HP | Ít Lõi hơn 1 | Lối dựa một combo Lõi cụ thể: ít Lõi nên phải chơi bằng nền (Hold, reroll mana, xếp hàng) | knob số lần chọn và thẻ |
| R7 | Thảo Nguyên Khô | Mana không mang qua lượt (dư cuối lượt mất). Đầu lượt +2 mana | Không tích mana được | Lối tích mana (Bể Tràn, Mạch Ngầm, Hồ Mana) | knob `mana_carry`, mana đầu lượt |
| R8 | Thuỷ Triều Lên | Trước mỗi trận công khai một hàng được nước: hàng trước nhận -25% sát thương, hoặc mặt dmg hàng sau +2. Luân phiên theo trận | Phải xếp lại theo trận | Lối xếp đội một lần cả run (đúng chỗ reviewer chê) | knob theo hàng + cờ mỗi trận |
| R9 | Thế Giới Lộn Ngược | Quái đánh đơn mục tiêu nhắm hàng sau trước; hàng trước chỉ trúng AoE | Hàng sau mỏng manh | Lối "tank trước, carry sau" mặc định | knob hàng ưu tiên trong `_pick_enemy_intent` |
| R10 | Rừng Già | Mọi Axie và quái +30% HP. Heal và poison +50% | Trận dài, ít burst | Lối dồn sát thương một lượt (Thác Đổ + Xúc Xắc Thứ Sáu + Mặt Gương) | knob HP, nhân heal/poison |
| R11 | Quạ Đưa Tin | Trận ngay trước mỗi lần chọn Lõi (từ lần 2): thắng trong 5 lượt (boss 7, knob) mà không Axie nào gục thì lần chọn +1 bậc, có Axie gục thì -1 bậc (chồng lên chuỗi, chịu trần T, không dưới Rêu) | Thua nhanh là thiếu Lõi | Lối rùa (Bức Tường Sống + Gai): đánh nhanh mới có bậc cao | đọc số lượt + số Axie gục cuối trận (cần kiểm stats run) |
| R12 | Vỏ Cứng (thay Đại Hội Muôn Loài, Liam chốt 20/10 khuya: luật hiện SAU khi chọn đội nên không được phụ thuộc lúc dựng đội) | Mọi quái có Giáp 2 (mỗi mặt dmg đơn của Axie -2, tối thiểu 1; poison, pierce, thorns, AoE không bị). Mặt shield, poison, debuff của Axie +2 giá trị | Mặt attack đơn yếu hẳn, trận dài nếu chỉ đánh | **Spam attack**: chỉ bấm attack là cạn đòn, phải chuyển sang poison/debuff/khiên/AoE. Trọng số 2 | knob `plating_global`, `side_face_bonus` (Giáp xem 6.7 M1) |
| R13 | Thế Cân Bằng (mới) | Mỗi lượt, mặt dmg dùng từ lần thứ 3 trở đi -2 (tối thiểu 1). Mỗi mặt KHÔNG phải dmg dùng xong cho +1 mana | Không dồn 5 viên attack được | **Spam attack**: viên thứ 3 trở đi phải là khiên/poison/debuff/mana mới có lời. Trọng số 2. `excludes` Thác Đổ (chuỗi dmg phá luật) | knob `dmg_use_soft_cap`=2, `dmg_overuse_penalty`=2, `nondmg_mana`=1 |

**Phủ lối trội** (Liam chốt 20/10 khuya: lối trội = **chỉ bấm mặt attack là thắng**): spam attack: **R12 Vỏ Cứng, R13 Thế Cân Bằng, R10 Rừng Già** (poison và heal +50%, trận dài nên chỉ đánh không kịp). Cả ba trọng số 2, các luật còn lại trọng số 1 (tổng 16 trên 13 luật: xác suất ít nhất 1 trong 2 thẻ là luật khắc spam attack = 1 - (10/16 x 9/15) = 62.5%). Lối khác giữ như cũ: rùa/khiên (R3, R11), dồn burst (R5), spam reroll (R1, R2), tích mana (R7), tank trước carry sau (R9, R8), combo Lõi cố định (R6, R4). Lối gom một class không còn luật khắc (R12 cũ đã thay), không phải lối Liam nêu.

### 2b.3 Chống cộng dồn Luật run + Lõi làm game dễ lại

Reviewer cảnh báo: bản này tự nó đã nerf người chơi mạnh (bỏ 133 relic nhân chồng, reroll miễn phí 2 xuống 1, sát thương dồn vào hàng trước), và TFT phải nâng trần cấp vì Cổng + Lõi + Legend vượt dự tính. Quy tắc:
1. Mỗi luật là **lợi + giá**; không luật nào chỉ cho lợi. Luật không cộng sức mạnh thuần: chỉ đổi dạng sức mạnh (R1, R2, R7, R9...) hoặc đổi sức mạnh lấy độ khó (R3, R4, R5, R10).
2. Luật thêm giá trị phẳng lên mặt chỉ có R5 (Kết +3), R8 (+2 hàng sau, từng trận) và R2 (viên Giữ +2; vòng 2 thêm, bản trước bỏ sót), cả ba trong trần +10/mặt. Mọi luật khác không cộng sát thương.
3. Mọi bonus từ Luật run tính vào **cùng trần +10/mặt** với Lõi (mục 3.4), và `t_damage_cap` phải có ca "luật x Lõi mạnh nhất".
4. Chơi thử phải thử đúng luật x Lõi mạnh nhất: R10 x Thác Đổ + Xúc Xắc Thứ Sáu, R6 x Hoá Thạch + Hòn Đá Mờ, R4 x Hoá Thạch (hai lần Tinh Thể sớm), R7 x Lõi Rỗng... Thêm ở vòng 2: R2 x Ba Viên + Cất Lửa (viên tự Giữ ăn Focus +3, Băng Nguyên +2, Cất Lửa +4, chạm trần +10 trên mọi viên mỗi lượt); R11 x build burst (Thác Đổ): người đánh nhanh lên bậc mọi lần chọn, đúng kiểu người đã thấy game dễ lại càng mạnh, trần T là chốt chặn duy nhất; R8 x Bức Tường Sống + Mai Lớn Dần (một tank không trần HP, -25% sát thương nửa số trận). Ghi chú: R4 x Hoá Thạch ở dòng trên chỉ xảy ra khi lần 2 là Rêu (lần 1 dưới Mưa Sao là T nên Hoá Thạch không hiện), tức T ở lần 1 và lần 3. Loại bớt hoặc `excludes` cặp nào phá game.
5. Knob `enemy_dmg_mult` (6.2) và `growth` chỉnh SAU khi đã chơi thử có luật; không tăng knob độ khó và luật cùng một lúc mà không đo (reviewer 9c.7).
6. Luật run thứ hai sau boss 1 (kiểu bỏ phiếu vòng 8 của Arena): để bump 2, vì cộng dồn khó cân.

## 3. Mặt dice làm lại

### 3.1 Cách part sinh mặt (hiện tại)

Mỗi Axie 6 part (mouth, horn, back, tail, eyes, ears) cho 1 mặt, tạo ở `axie_to_die.gd` từ template trong `part_faces.json` (457 dòng khớp `"t":`/`"v":`, hằng số `B_C 2.8, S{C 1,O 1.267,P 1.6,X 1.467}, SlotMod`, ... trong `constants`). Mouth/horn/tail thường là dmg, back là shield, eyes là heal/debuff, ears là mana có cantrip (`rule-spec §7`, theo brainstorm 1.3). Một viên bất kỳ cho khoảng 3 dmg, 1 shield, 1 tiện ích, 1 mana.

**Quyết định: không sửa `part_faces.json`** (chỉ cần kiểm lại nếu Focus cần thêm template). Lý do: INV-5 (±10% ngân sách bậc) và `t_part_faces`. Mọi thứ mới đi qua keyword của Lõi, cấp theo slot.

### 3.2 Hold (tên kỹ thuật `stash` để không đè `hold_pick` của relic Amber, `combat_engine.gd:981`)

- Trong lượt EXECUTE, người chơi có thể Giữ 1 viên chưa dùng (không phải cantrip đã dùng, không phải viên Frozen). Viên đó không dùng được lượt này.
- Cuối lượt, viên Giữ giữ nguyên mặt. Đầu lượt kế, viên đó không roll lại, và dùng được ngay. Không giữ được lượt thứ hai liên tiếp (trừ Giữ Vững, hoặc Trọng Điểm khi chưa xong).
- Tối đa 1 viên Giữ cùng lúc (2 nếu có Giữ Vững). Không tốn mana.
- Hold có giá cơ hội: viên bị giữ không đánh lượt này. Chiến lược "giữ mọi lượt" bị chặn: không giữ liên tiếp cùng một viên hai lượt.
- Hold + undo: dùng `_push_undo` như các hành động khác. Hold phải ghi `_log("stash", [uid])`.
- Đụng chạm cần kiểm: Cantrip (viên có `cantrip` không Giữ được), Frozen, Resonance (viên Giữ không vào `resonance_log`), `hold_pick` relic (Amber), replay verify.

### 3.3 Focus

Gộp với Hold (Liam duyệt). Focus không phải mặt riêng mới: là keyword `focus` mà Lõi gắn lên mặt đang bị Giữ (Cất Lửa). Ban đầu không có mặt Focus trong `part_faces.json`. Nếu sau này muốn mặt Focus gốc thì đợt 2.

### 3.4 Mồi và Kết (nối các mặt)

Mở rộng Resonance (`combat_engine.gd:1066-1089`, hiện chỉ cho cùng loại liền kề, x1.15). Thêm hai keyword chỉ do Lõi cấp, không nằm trong part data:

- **Mồi**: mặt (shield/mana/buff) khi dùng ghi vào `prime_log` (mới) `{pos, used:false}`. Mặt dmg kế tiếp của Axie liền kề (|pos diff| = 1) tiêu thụ Mồi: +N (N từ Lõi, 3 với Chuỗi Mồi). Cộng, không nhân (ràng buộc 1, bloodline §4.3).
- **Kết**: viên cuối cùng được dùng trong lượt luôn là mặt Kết (không cần Lõi). Lõi cho bonus theo số viên đã dùng trước nó (Kết Cục), hoặc thêm hiệu ứng (Luật Kết Nặng; Tích Ác, Phán Quyết đã tắt ở 2.10). Cộng, có trần.
- Thứ tự dùng giờ có giá trị: quyết định gán là "viên nào trước, viên nào cuối".
- Trần (reviewer mở rộng): tổng bonus phẳng từ Lõi trên một mặt (Mồi, Kết, Focus, Thác Đổ, Phản Công, Luật run R2/R5/R8...) tối đa +10. Bản cũ chỉ chặn Mồi + Kết + Đa Sắc ở +8, để Focus +8 chồng thêm ngoài trần. Kiểm bằng `t_damage_cap` mới.

### 3.5 Reroll tốn mana

- Hiện: 2 reroll miễn phí/lượt (`combat_engine.gd:52, 207`), `rerollUp` relic và Aqua passive cho thêm.
- Mới: 1 reroll miễn phí/lượt. Reroll thứ 2 trở đi tốn **2 mana** (knob `reroll_mana_cost`), tối đa 4 reroll tổng mỗi lượt (knob).
- Mặt mana (ears) thành nguồn chính. Passive Aqua (4 mana đổi 1 reroll, `_grant_conduit_rerolls`) giữ nguyên, thành giảm giá: 3 mana đổi 1 reroll.
- Aid reroll (`from_aid`) giữ nguyên, thành "thêm reroll không tốn mana" và đáng giá hơn: monetization, cần economy-designer (reviewer ghi chú 2).
- ĐÃ KIỂM: mana KHÔNG có cap (`combat_engine.gd:1256`, `:1286` chỉ cộng; carry qua lượt, reset đầu trận `:180`). Đề xuất mana cap 8 (knob), nhưng Lõi "Hồ Mana", "Bể Tràn" đụng cap nên phải kiểm trước. (reviewer: khuyến nghị KHÔNG thêm cap chung. Reroll tốn mana đã là chỗ tiêu; các Lõi đã viết lại tự có trần riêng: Hồ Mana +3/lượt, Bể Tràn ở 8, Mạch Ngầm 12, Đổi Mana Lấy Khiên 6. Cap chung sẽ làm Bể Tràn chết và thêm một luật người mới phải học.)

### 3.6 Quan hệ mặt dice và Lõi

Lõi dice không sửa part, chỉ thêm keyword lúc dựng đơn vị: `_build_unit_from_roster` (`combat_engine.gd:1716-1779`) đã có `RelicHooks.apply_mod_faces` ở build-time; Lõi dice dùng đúng hook đó, cấp keyword theo slot (ví dụ "mọi mặt back có Mồi"). Part identity (§3.4b purity) không đổi vì Lõi không thay keyword part mà thêm keyword Lõi, và không đi qua đường "suppress". Cần kiểm lại với `part-skill-identity.md` §3.4b khi lane A đọc doc.

## 4. Vị trí Axie

- 5 slot roster = 2 hàng: **hàng trước = roster 0, 1; hàng sau = roster 2, 3, 4** (knob). Data đã có `u.slot` / `roster_index` (`combat_engine.gd:1730-1731`), xếp lại giữa trận không có, xếp lại trước trận có (`reorder_party`).
- Quái đánh đơn mục tiêu (`_pick_enemy_intent`, `combat_engine.gd:518-540`) chọn mục tiêu trong hàng trước còn sống. Chỉ khi hàng trước hết người mới đánh hàng sau. Role assassin: nhắm yếu nhất **trong hàng trước** (vẫn công khai). (reviewer đề nghị ngược lại: assassin bỏ qua hàng, nhắm Axie yếu nhất toàn đội như hiện tại. Nếu không có gì chạm được hàng sau ngoài AoE thì xếp đội là quyết định một lần mỗi run, không phải mỗi trận. Assassin + affix Đánh Lén (6.4 #9) là thứ bắt người chơi xếp lại trước trận.) AoE, cleave, pierce, poison aoe bỏ qua hàng.
- Intent vẫn hiện đúng mục tiêu như hiện tại: pillar minh bạch giữ nguyên.
- Phụ thuộc vị trí khác: Lõi `pos` (9 cái ở 2.7), Resonance/Mồi liền kề (giữ nguyên).
- Đã kiểm: Egg/token có `roster_index = -1` mặc định (`unit.gd:62`, `combat_engine.gd:419` guard `is_token`); luật hàng PHẢI xử lý `roster_index<0` tường minh. Quyết định hàng cho Egg: hàng trước (vòng 2 sửa cho khớp Tổ Ấm ở 2.7; bản trước ghi "hàng sau", ngược với Tổ Ấm).
- Bốn vấn đề UI: hiện ranh giới hàng trên màn combat, đổi vị trí ở run setup/map (đã có `reorder_party`), tooltip giải thích, tutorial. Spec UI nhỏ ở mục 8.

## 5. Mana

| Việc | Nguồn / giá | Ghi chú |
|---|---|---|
| Reroll thứ 2+ | 2 mana mỗi lần | knob `reroll_mana_cost` |
| Active relic card (`act_cost`) | giá thẻ hiện có | bump 1: bỏ khỏi pool Lõi (mana đã có chỗ tiêu), thêm lại sau nếu thiếu (mặc định, mục 10) |
| Aqua conduit | 3 mana = 1 reroll (từ 4) | knob |
| Lõi mana | mục 2.7 | tiêu mana thành sát thương/khiên/hồi sinh |
| Hold | 0 mana | free, giá cơ hội |
| Nguồn | mặt ears (~1 mana, nhiều có cantrip), Giọt Sương (+1 đầu lượt), Egg chết (Trứng Vàng), Lõi mana | |
| Mana đầu trận | `start_mana` (combat_setup) | giữ |

Cân bằng reroll / Hold / kỹ năng: reroll rẻ (2 mana), Hold miễn phí, kỹ năng (active) giữ giá cũ. Đội ít mana không bị bóp nghẹt vì còn 1 reroll miễn phí + Hold. Đội nhiều mana có lý do đầu tư. Cần sim để chỉnh `reroll_mana_cost` (1-3).

## 6. Độ khó

### 6.1 Số thật hiện tại (tính từ data, chưa chạy sim)

Công thức `ContentDB.budget(pw) = 10.5 x 1.125^min(pw,12) x 1.05^max(0,pw-12)` (`combat_tune.json`, `ContentDB.gd:683`). pw tăng 1 sau mỗi node xong, mọi loại node (đã kiểm: `RunState.gd:836` `after_node()`, field `power_level` `:48`). Short: boss hàng 6/12/18 gần pw 5/11/17.

| pw | budget | Ghi chú |
|---|---|---|
| 5 | 18.9 | boss 1 Short |
| 11 | 38.3 | boss 2 Short |
| 12 | 43.1 | knee |
| 17 | 55.0 | boss 3 Short |
| 29 | 98.9 | boss cuối Full |

Boss: `hp = hpk x budget x boss_hp x hp` (`ContentDB.boss_stats`). hpk: Agony 2.0 (pha 2: 2.5), Mirror 2.9, Plague 3.0, Frost 3.2, Mecha 3.3, Gooey 3.7. Vậy boss 1 Short có 38 (Agony) tới 70 HP (Gooey); boss 2 có 76-142; boss 3 có 110-204. Một Axie tier-1 có 11-17 HP và xúc xắc mặt dmg 2-5 (`ContentDB.gd:227-250`). Ước lượng sát thương một lượt cho cả đội ở đầu run khoảng 8-12 (cần kiểm bằng sim, tôi chỉ ước từ 5 viên x nửa số mặt là dmg x ~3). Boss 1 chết trong khoảng 4 lượt, và còn nhiều Lõi/relic nhân sát thương thêm: đó là lý do Liam thấy cực dễ. Đồng thời intent boss: Mecha mặt 13 base, `ds = 0.57 x 38.3 / 12.6 = 1.73` ở pw 11 -> mặt 22 và pierce 28, tức một đòn hạ một Axie, nhưng các đòn này chỉ có 1 trong 6 mặt và chọn mục tiêu ngẫu nhiên.

### 6.2 Đề xuất chỉnh (giai đoạn 1, chưa sim, đều là knob trong `combat_tune.json`)

| Knob | Hiện | Đề xuất | Hiệu ứng |
|---|---|---|---|
| `TUNE.growth` | 1.125 | 1.14 | budget pw 11 từ 38.3 lên 44.0 (+15%), pw 17 lên 64 |
| `TUNE.elite_mult` | 1.25 | 1.5 | Elite thật sự là cửa ải |
| boss `hpk` (6 boss) | như trên | x1.25 | boss 1 Short: 47-88 HP; boss 3: 137-255 |
| `ContentDB.count(pw)` | 2 + pw/4, tối đa 5-6 | giữ | số lượng quái đủ |
| Lõi, hệ nhân sát thương | | tổng cộng không có nhân mới; bonus Mồi/Kết cộng phẳng, trần +8/mặt | Lõi đổi luật mạnh nhưng không nhân |

Đây là mức khởi điểm để tuning bắt đầu, KHÔNG phải kết luận. Day 3 phải chạy sim (`tools/sim.js` JS đã xoá. Đã kiểm: `godot/tools` chỉ có `run_bot.gd` (bot dở cố ý, đo determinism, KHÔNG phải balance probe), `verify_run.gd`, `record_sample_run.gd`; không có soak/sim cân bằng. Phải viết mới `godot/tools/sim_balance.gd` chạy N seed bằng bot có chiến lược, ước 0.5-1 ngày, chưa nằm trong plan) chọn lại số. Mục tiêu từ `core-loop-v2` 5.2: không archetype nào thắng quá 60% hay dưới 35% ở A5; đề xuất thêm mục tiêu Short A0 thắng 45-60% người chơi có kinh nghiệm (cần Liam xác nhận mục tiêu, câu 4).

(reviewer) Hướng đúng nhưng bảng trên gần như chỉ tăng HP, mà tăng HP thì trận dài hơn chứ không khó hơn: người chơi vẫn không sợ chết, chỉ bấm nhiều hơn. Thứ làm game "cực dễ" khó lên thật sự là (a) quái gây đủ sát thương để mất Axie là chuyện thường, (b) đòn nguy hiểm đến đúng lúc và người chơi phải trả lời nó (nhịp boss, Gấp, Cuồng). Đề nghị: thêm knob sát thương quái tách khỏi HP (`enemy_dmg_mult`, khởi điểm 1.2) và để boss HP x1.25 ở mức thấp hơn (x1.1) cho tới khi có số. Ngoài ra, chính bản này đã là một cú nerf lớn mà bảng chưa tính: bỏ 133 relic nhân chồng, reroll miễn phí 2 xuống 1, sát thương đơn dồn vào 2 Axie hàng trước. Có thể chỉ riêng những thứ đó đã đủ đẩy game từ "cực dễ" về "vừa". Vì vậy không chỉnh knob trước khi chơi thử: ngày 3 nên có một vòng Liam (hoặc người chơi có kinh nghiệm) chơi 3 run Short với knob để mặc định, rồi mới chỉnh.

### 6.3 Nhịp boss (3a), chung cho cả 6 boss

Chu kỳ 3 lượt công khai, hiện trên UI (nền là boss clock có sẵn, `combat_engine.gd:1601+`):
- Lượt 1 **Chuẩn bị**: boss dùng mặt thường, hiện trước tell của lượt 2.
- Lượt 2 **Đòn**: boss dùng mặt mạnh nhất (cao nhất trong die của nó), intent công khai.
- Lượt 3 **Hở**: boss nhận +30% sát thương từ mặt dmg, mặt boss lượt đó -30%.
- (20/10 khuya, chống spam attack) **Giáp nhịp**: lượt Chuẩn bị và Đòn, boss có Giáp P (cơ chế M1, 6.7): mỗi mặt dmg đơn -P, tối thiểu 1. Lượt Hở giáp rơi hết. Đánh đều mọi lượt gần như phí hai phần ba số viên; người chơi phải Hold viên lớn sang lượt Hở, và dùng poison/debuff/pierce ở hai lượt kia. P = clamp(round(budget/12), 2, 4) như M1.

Tell riêng từng boss (dữ liệu, mở rộng `_boss_turn_traits` `combat_engine.gd:1490`; chưa kiểm), cần kiểm khớp với trait đã có (Mecha OVERDRIVE mỗi 3 lượt đã trùng chu kỳ):

| Boss | Lượt Đòn | Lượt Hở |
|---|---|---|
| Mecha | OVERDRIVE (đã có) | mất Thorns |
| Frost Lord | đóng băng 2 viên (thay vì 1) | không đóng băng |
| Gooey King | split sớm (như hiện có ở 2/3, 1/3) | boss gốc +khiên chờ phá |
| Plague Mother | summon minion (như hiện có) | poison dừng 1 lượt |
| Mirror | lặp lại mặt mạnh nhất của đội | không lặp |
| Agony | (hai pha có sẵn) | pha 2 bỏ qua nhịp, Hở ngắn hơn |

Cần kiểm: `t_boss_encounters` 62 check; boss clock hiện có "attrition/spike" (`combat_tune.json`), không được chồng lên làm game phức tạp quá. Không giấu thông tin: mọi tell hiện sớm 1 lượt (pillar minh bạch).

### 6.4 Affix Elite: bảng để Liam duyệt từng cái

Mỗi Elite khi sinh map nhận 1 affix, hiện công khai trên node. Elite có affix dấu (+) cho Lõi lần 2 chắc chắn bậc Hổ Phách (thay vì 30/70). (+) = 5, 7, 9.

Cột cuối (reviewer): affix có tạo quyết định không. Affix chỉ trừ tài nguyên mà người chơi không làm gì khác được là "thuế", gây khó chịu, không làm game sâu hơn.

| # | Tên | Hiệu ứng (số tính trên budget Elite) | Gần ranh giới "trait khắc chế"? | Quyết định tạo ra |
|---|---|---|---|---|
| 1 | Hồi Âm | Lặp lại intent lượt trước ở lượt kế, sát thương -30% | Không | Yếu: Elite này dễ hơn, chỉ cho đa dạng |
| 2 | Vỏ Sò | Bắt đầu với khiên = 40% Max HP | Hơi khắc mặt dmg thấp | Có: dồn đòn lớn / pierce / poison trước |
| 3 | Cuồng | Dưới 50% HP: dmg +25% | Không | Có: giữ đòn để đi từ trên 50% xuống 0 trong một lượt |
| 4 | Trộm Mana | Mỗi đầu lượt lấy 1 mana của người chơi (tối thiểu 0) | CÓ, khắc mana (quyết định Liam) | Ít: chỉ là "tiêu mana sớm" |
| 5 | Bầy (+) | Khi dưới 50% HP gọi thêm 2 quái nhỏ | Không | Có: chọn lúc qua ngưỡng, giữ AoE |
| 6 | Gai | Thorns 3 | Hơi khắc đội nhiều mặt nhỏ | Có, nhẹ: dùng ít mặt to |
| 7 | Gấp (+) | Lượt 3 hành động hai lần (công khai trước 1 lượt) | Không | Có: Hold, khiên đúng lượt |
| 8 | Nanh Độc | Mặt dmg của nó cộng 2 poison, **chỉ khi đòn xuyên qua khiên** (reviewer sửa: bản cũ là thuế thuần) | Không | Có (sau sửa): khiên đúng Axie bị nhắm |
| 9 | Đánh Lén (+) | Mặt dmg đơn của nó nhắm Axie yếu nhất **hàng sau** (công khai). (reviewer thay Tiên Phong: luật nền mục 4 đã bắt quái đánh hàng trước, Tiên Phong không còn tác dụng) | Hơi khắc đội hàng sau yếu | Có: xếp lại đội, dùng khiên cho hàng sau |
| 10 | Đóng Băng | Lượt 1 đóng băng 1 viên (như Frost Lord, một lần) | Không | Ít: một lần, thuế nhỏ |

Đề xuất duyệt (reviewer chỉnh): 2, 3, 5, 7, 8 (đã sửa), 9 (mới) cho bump 1. 1, 6, 10 sau. 4 Liam quyết (câu 2: Liam đã bỏ Trộm Mana).

**Thêm 20/10 khuya (chống spam attack, chi tiết cơ chế ở 6.7):**

| # | Tên | Hiệu ứng | Buộc người chơi dùng |
|---|---|---|---|
| 11 | Giáp Sắt | Giáp P+1 (6.7 M1), tắt 2 lượt khi dính debuff/poison (như M1, không phải vỡ hẳn) | debuff, poison, pierce |
| 12 | Khiên Hồi | Đầu lượt địch Elite +S khiên cho bản thân (6.7 M2) | dồn đòn lớn một lượt (Hold), poison, AoE |
| 13 | Phản Đòn | Thay Gai #6: mặt dmg đơn thứ 3+ lên Elite trong lượt, Axie đánh nhận 2 xuyên khiên (6.7 M3) | chia mục tiêu, AoE, khiên |
| 14 | Hồi Ngắt | Đầu lượt hồi 20% Max HP (tối đa 6) nếu không dính poison/stun/weaken (6.7 M4) | poison, debuff |
| 15 | Đòn Nạp | Mỗi 3 lượt nạp một lượt rồi đánh x2.5 vào một Axie công khai (6.7 M5) | stun/freeze, khiên, Hold |

**Luật chọn affix (thay "mỗi Elite 1 affix")**: nhóm A (buộc đổi mặt) = 2, 8, 9, 11, 12, 13, 14, 15; nhóm B = 3, 5, 7. Elite đầu tiên của run luôn nhận 1 affix nhóm A. Elite sau boss 1 (vòng 3 đổi từ "hàng 11 Short" để chạy đúng cả Full) nhận 1 nhóm A + 1 nhóm B, trừ cặp cấm ở 6.7b mục 9. Mọi Elite nhóm A, nghĩa là từ Elite đầu "chỉ đánh" không đủ. Đội không `team_can_break` chỉ rút nhóm A từ {2, 9, 12, 13, 15} (6.7b). **Run đầu của tài khoản**: tắt affix như đã ghi 2b.1, nhưng KHÔNG tắt chống-spam: Elite run đầu luôn nhận Giáp Sắt (#11) cố định, một câu dễ đọc, và đã có Giáp trait role (6.7). Đội run đầu không `team_can_break` thì nhận Khiên Hồi (#12) thay. Yêu cầu dạy cho làn D ở 8.6.

### 6.5 Đường cong qua các act

- **Act 1 (hàng 1-6, trước boss 1).** Số lượng quái 2-3 (`count(pw)`). Người chơi có 1-2 Lõi. Mục tiêu: học Hold, Mồi, hàng trước. Thua ở đây hiếm.
- **Act 2 (hàng 7-12).** Elite có affix, Lõi nhiệm vụ trong tay. Thua do không xếp đội đúng.
- **Act 3 (hàng 13-18).** Lõi Tinh Thể, boss cuối. Đây là nơi build-around thật sự bật. Độ khó ở đây phải đuổi kịp: tăng `growth2` từ 1.05 lên 1.06 (cần sim).
- Cưa: mỗi boss là đỉnh, đầu act kế hạ nhẹ bằng việc người chơi nhận Lõi mới.

### 6.6 Aid và monetization (INV-6, mục 8.5)

Aid hiện có: reroll Aid (`aid_prices.json`), lùi boss clock, tiếp tục sau thua (`continue`, `FREE_CONTINUE` trong `run_core.js:46`). Mới:
- Mana-reroll làm cho reroll Aid đáng tiền hơn (reviewer ghi chú 2).
- Reroll Lõi thêm (ngoài 2 lần miễn phí): bán qua Aid, giá do economy-designer định.
- Không bán Lõi cụ thể, không bán kết quả xúc xắc (xúc xắc roll trên server, đã chốt 11/10).
Giá và tên sản phẩm: giao economy-designer, Liam duyệt.

### 6.7 Phá lối "chỉ bấm attack" (Liam chốt 20/10 khuya, câu 6)

Mục tiêu: từ Elite đầu trở đi, đội chỉ đánh bằng mặt attack không thắng được hoặc thắng rất tệ. Dữ liệu thật: quái thường 7-20 HP, Elite 26-38 HP (`ContentDB.gd` ~314-446), mặt dmg Axie tier-1 2-5, boss 1 Short 38-70 HP, nên trước giờ spam attack hạ quái trước khi quái làm gì được. Sáu cơ chế, mỗi cái ghi rõ nó buộc dùng gì. Mọi số là khởi điểm, cần sim hoặc chơi thử; mọi cơ chế phải phát event (event stream) để UI hiện, không giấu (pillar minh bạch). Nguyên tắc: không cơ chế nào làm attack vô dụng hẳn (min 1), chỉ làm nó không phải lựa chọn duy nhất; mỗi cơ chế có đường phá bằng ít nhất 2 loại mặt khác nhau.

| # | Tên | Ai có | Luật + số | Buộc dùng |
|---|---|---|---|---|
| M1 | Giáp Mỏng | Quái role tank (Spikelet, Thornback, Elite Bulwark) làm trait cơ bản; Elite qua affix #11; boss qua Giáp nhịp (6.3) | Mỗi mặt dmg ĐƠN lên nó bị trừ P (tối thiểu 1), tính SAU bonus Lõi. P = clamp(round(budget/12), 2, 4) (pw 5: 2, pw 11: 3, pw 17: 4). Poison, pierce, thorns, AoE không bị trừ, mọi sát thương sinh ra từ Lõi (Sóng Khiên, Chữ Ký Máu, Bể Tràn, Ngọn Triều, Nổ Bào Tử) cũng không (vòng 3). Dính BẤT KỲ debuff nào (kể cả vulnerable, đây là debuff chính của Beast/Bird) hoặc poison: Giáp tắt 2 lượt (định nghĩa lượt ở 6.7b) | debuff, poison, pierce, AoE. Mặt dmg 3-4 thành 1-2: đánh thẳng thì chậm gấp 2-3 |
| M2 | Khiên Hồi | Quái role healer/buffer (Jellyfin, Warden, Chimera Totem) cho cả phe; Elite qua affix #12 | Đầu lượt địch: mỗi healer/buffer sống cho quái đồng minh có khiên thấp nhất S khiên, S = 3 + floor(pw/4) (pw 5: 4, pw 11: 5, tối đa 7). Elite #12 tự +S x 1.5 | dồn đòn lớn một lượt (Hold), poison (đã kiểm: tick poison đi `pierce: true` `status_engine.gd:118`, bỏ qua khiên `damage_pipeline.gd:85`), giết healer trước (quyết định chọn mục tiêu, không phải đổi loại mặt; AoE vẫn bị khiên chặn); giết healer vẫn là đường nhưng 5 mặt nhỏ rải sẽ bị khiên nuốt từng lượt |
| M3 | Phản Đòn | Quái có Thorns hiện tại nâng cấp (Phản Đòn THAY thorns cũ của nó, không cộng); Elite qua affix #13 (thay Gai #6) | Mặt dmg đơn thứ 3 trở đi lên CÙNG một quái trong một lượt: Axie đánh nhận 2 sát thương xuyên khiên (pw 8+: 3), mỗi lần. Reset đầu lượt người chơi | chia đòn ra nhiều mục tiêu, AoE, poison/debuff cho viên thứ 3, khiên cho Axie dễ vỡ. Hết kiểu dồn 5 viên vào một quái |
| M4 | Hồi Ngắt | Warden, Elite qua affix #14 | Đầu lượt địch nó hồi 20% Max HP (tối đa 6) cho bản thân/đồng minh thấp máu nhất NẾU lúc hồi (đầu lượt địch) mục tiêu không đang dính poison hay bất kỳ debuff nào (vòng 3: bỏ "ở lượt trước", mơ hồ; thêm vulnerable cho khớp M1). Trần mỗi trận: một nguồn mend hồi tổng tối đa 50% Max HP của chính nó (`mend_fight_cap`), để đội không có poison/debuff không bị kẹt trận vô hạn | debuff hoặc poison lên đúng quái được hồi. Đánh thường chỉ bù lại hồi, vẫn thắng nhưng chậm |
| M5 | Đòn Nạp | Elite qua affix #15; boss (nhịp Đòn ở 6.3 dùng cùng cơ chế) | Chu kỳ 3 lượt: lượt 1-2 đánh thường, lượt 3 "Nạp" (intent công khai, không đánh), lượt 4 đánh 1 mặt x2.5 vào MỘT Axie đã chỉ định công khai (mặt 5-6 -> 13-15, đủ hạ một Axie tier-1 11-17 HP). Ngắt: stun hoặc freeze lên nó trong lượt Nạp. Đỡ: khiên >= đòn lên Axie đó. Sát thương KHÔNG ngắt được. (vòng 3, cho rõ) Chu kỳ thật là 4 lượt địch: Nạp khi `n % 4 == 3`, đánh khi `n % 4 == 0`. Mục tiêu chốt lúc Nạp = Axie có HP+khiên thấp nhất trong số Axie quái đó được phép nhắm (hoà thì ô nhỏ nhất); chết trước lượt đánh thì chọn lại cùng luật. Boss chỉ mượn tell + chốt mục tiêu ở lượt Chuẩn bị, KHÔNG nhân 2.5 (Đòn đã là mặt mạnh nhất); stun/freeze lên boss lúc Chuẩn bị hạ Đòn về mặt thường chứ không huỷ | debuff stun/freeze, khiên, Hold viên khiên. Chỉ attack thì mất Axie |
| M6 | Giáp nhịp boss | Mọi boss (6.3) | Chuẩn bị + Đòn: Giáp P. Hở: bỏ giáp, boss nhận +30%. Debuff/poison tắt Giáp boss như M1 | Hold, poison/debuff ở hai lượt kia |

Phủ: attack dồn một mục tiêu (M1, M3), attack rải nhỏ (M2), attack đều mọi lượt (M6), attack bỏ qua đe doạ (M5). Chống degenerate: (a) AoE và pierce là đường phá chung của M1, M3, M2 nên không biến thành "chỉ AoE" vì mỗi cơ chế còn lại đường khác (poison, debuff, khiên). (b) Elite có tối đa 1 affix nhóm A (6.4) để không chồng Giáp + Khiên Hồi + Hồi Ngắt thành tường. (c) Chặn Thác Đổ đẩy sát thương qua M1: min 1 + sàn trần +10/mặt giữ nguyên. (d) `enemy_dmg_mult` 1.2 (6.2) vẫn là knob riêng, không tăng cùng lúc khi chưa chơi thử (9c.7).

Theo dõi khi chơi thử: tỉ lệ lượt người chơi dùng mặt không phải attack >= 35% từ Elite đầu; run thắng mà chỉ dùng mặt dmg trong boss 1 phải bằng 0 trong 10 run thử. Cần Liam duyệt số P, S, 20%. (vòng 3) Thêm: trận Elite với đội trộn mặt xong trong khoảng 6 lượt, spam thuần 8-11 lượt và mất ít nhất 1 Axie; không trận nào quá 14 lượt (nếu có là bế tắc, xem 6.7b). M2 Khiên Hồi là quyết định chọn mục tiêu (giết healer trước), không ép đổi loại mặt, nên không tính vào chỉ số 35%.

### 6.7b Luật chồng, chống kẹt trận, lối thoát (reviewer vòng 3)

**Tỉ lệ mặt thật** (grep `"t":` trong `part_faces.json` > `familyVariant`, 145 biến thể part): dmg 71 (49%), không-dmg 74 (51%). Theo class: Beast ~20/28 biến thể là dmg (khoảng 4 mặt dmg trên 6), Bird 14/23, Aqua 13/25, Plant 9/26, Bug 8/25, Reptile 7/20. Vậy đội "gần như toàn dmg" chỉ xảy ra với đội nặng Beast/Bird, và chính hai class đó có back debuff (vulnerable). Chỗ hổng thật nằm ở chỗ khác: mặt poison/debuff chỉ 20/145 (14%), và **Aqua, Plant có 0 mặt poison/debuff**, chỉ vài biến thể dmg mang `pierce`/`aoe` và 1 biến thể Plant có `weaken`. Đội Aqua/Plant (lối khiên/heal rất phổ biến) gặp Giáp Sắt + Hồi Ngắt thì không có gì để phá: mặt dmg 3-4 thành 1, Elite hồi 6 mỗi lượt, trận không bao giờ xong. Đó là bế tắc, không phải quyết định. Các luật dưới đây bắt buộc ở bump 1.

**`team_can_break`** (tính một lần lúc `begin_run` từ 30 mặt của đội, tất định, không rng): đội có ít nhất 1 mặt `poison` hoặc `debuff`, hoặc 1 mặt bất kỳ mang keyword `pierce`, `aoe`, `stun`, `freeze`, `weaken`, `vulnerable`, `poison:N`.

Lối thoát:
1. Sát thương sinh ra từ Lõi không bị Giáp (đã ghi ở M1): Sóng Khiên, Ngọn Triều, Bể Tràn là đường phá cho đội khiên/mana. Mana-reroll để câu mặt `pierce`/`aoe` là đường thứ hai, nhưng chỉ khi xúc xắc có mặt đó.
2. Đội không `team_can_break`: (a) R12 Vỏ Cứng không được rút (`requires: team_can_break`). (b) Affix nhóm A của Elite rút từ tập không cần poison/debuff: {2 Vỏ Sò, 9 Đánh Lén, 12 Khiên Hồi, 13 Phản Đòn, 15 Đòn Nạp} (lọc danh sách trước khi rút bằng salt affix, không thêm draw). (c) Run đầu: Elite nhận Khiên Hồi thay Giáp Sắt. (d) Nên có, cắt được: lần chọn Lõi 1 có một thẻ trục mana thì ưu tiên Ngọn Triều.
3. Chống kẹt trận: từ lượt 7 của trận (`plating_decay_turn` = 7) mọi Giáp quái -1 mỗi lượt tới 0, ward thôi cấp khiên. Boss không áp (boss đã có lượt Hở). Mend có trần mỗi trận 50% Max HP của nguồn (M4).

Luật chồng:
4. Giáp nhiều nguồn (trait tank, affix Giáp Sắt, R12, Giáp nhịp boss) lấy **max, không cộng**. Giáp Sắt = P+1 theo pw, không phải R12+1.
5. Mỗi quái tối đa **1** trait chống-spam: tank = plating, Jellyfin/Chimera Totem = ward, Warden = mend (bản trước cho healer/buffer cả ward lẫn mend, tức Warden vừa khiên vừa hồi).
6. Elite có affix nhóm A thì bỏ trait role của chính nó (Elite Bulwark + Khiên Hồi không thành Giáp + Khiên); quái đi kèm trong trận Elite không mang trait chống-spam. Kết quả: trận Elite có đúng 1 cơ chế chống-spam, sau boss 1 thêm 1 nhóm B.
7. Trận thường: trước Elite đầu tối đa 1 quái mang trait, sau đó tối đa 2. Thừa thì tắt trait của quái ở ô cao nhất (tất định).
8. Ward: không đẩy khiên mục tiêu vượt 2 x S (`ward_stack_cap`). Khiên quái hiện không thấy reset mỗi lượt (grep `.shield = 0` chỉ ra 3 chỗ đặc biệt; cần kiểm), không có trần thì ward dồn thành tường.
9. Cặp affix cấm: #15 Đòn Nạp + #7 Gấp (lượt Nạp lại hành động hai lần, mâu thuẫn); #15 + #3 Cuồng tạm cấm tới khi chơi thử (mặt 6 x 2.5 x 1.25 = 19, hạ mọi Axie tier-1).
10. R13 Thế Cân Bằng và M3 Phản Đòn cùng phạt mặt dmg thứ 3: cố ý, không chặn, nhưng chơi thử phải thử cặp này.

Attack vẫn là một lựa chọn: một mặt debuff/poison tắt Giáp 2 lượt, nên lối đúng là "1 mặt mở, 4 mặt đánh". Lõi attack còn lại sau 2.10 (Thác Đổ, Kết Cục, Cất Lửa, Mặt Gương, Xúc Xắc Thứ Sáu, Hiến Tế) vẫn thắng được với một viên mở đường, và Thác Đổ +8 trừ Giáp 3 vẫn còn 9. Nếu chơi thử thấy "1 vulnerable rồi spam" quá rẻ thì hạ `plating_off_turns` từ 2 xuống 1 trước, chưa đụng P.

## 7. Map run

Giữ cấu trúc hiện tại (`run_map_generator.gd`, K 4-6 walk, 3 cột, hàng boss/elite cố định). Thêm:

1. **Loại phần thưởng trên node (4a)**: khi sinh map (có seed) mỗi battle/elite gắn trước `reward_kind` trong {level, hp, mảnh mặt (rune cũ), shard lớn}; Lõi chỉ đến từ mốc (2.1), không nằm trên node. Reward cụ thể roll sau trận như hiện tại. Cần kiểm: reward hiện là 3 thẻ trộn (`_type_pool`), node chỉ gắn "loại thẻ chắc chắn có mặt", không phải một thẻ cố định (giữ lựa chọn). Seed và replay: ĐÃ KIỂM, KHÔNG dùng cùng rng map. `RunMapGenerator` tiêu `rng` chung và retry trên cùng instance (`run_map_generator.gd:26-29`), boss plan + map cùng stream `_rng` (`RunState.gd:438-446`), nên thêm draw vào `_build_once` dịch mọi thứ phía sau (map đổi hình, `t_map_invariants` và fixture replay đổi; chấp nhận được vì đã bump). Khuyến nghị: gán `reward_kind` SAU khi đồ thị xong bằng `Rng.new(seed ^ REWARD_KIND_SALT)` (kiểu `PACT_SEED_SALT`, `RunState.gd:146`), không tiêu stream map.
2. **Affix trên Elite** (6.4).
3. **Forge, Thử thách, Mutator**: cắt (mục 0). Campfire "Forge" giữ như event có sẵn.
4. **Treasure vs battle** (brainstorm 1.5, chưa có số): pool hàng tự do `event, event, treasure` + shop (`run_map_generator.gd:276`). Giữ nguyên ở bump 1; nếu sim Day 3 cho thấy treasure trội thì đổi `treasure` thành giảm pw (không tăng). Cần kiểm.
5. **Lõi nhiệm vụ** không phải node, nhưng đếm ở map (số trận còn lại hiện trên HUD).

## 8. Ảnh hưởng kỹ thuật

### 8.1 File luật đổi (nằm trong fingerprint `t_rules_version`)

| File | Đổi gì |
|---|---|
| `godot/scripts/core/combat_engine.gd` | stash (Hold), reroll mana, targeting hàng trước, prime_log, finish bonus, affix, nhịp boss, Lõi hooks mới |
| `godot/scripts/core/damage_pipeline.gd` | cộng Mồi/Kết (phẳng), phản gai Kẻ Gác Cổng |
| `godot/scripts/core/relic_hooks.gd` | hook mới cho Lõi (đã kiểm: `TABLE` `relic_hooks.gd:34`, đã có 17 event: on_turn_start/end, on_roll_settled/end, on_face_used, on_face_hit, on_kill, on_hit, on_active_played, on_thorns, on_shield, on_shield_break, on_combat_start/end, on_status_tick, on_dmg_taken, on_poison_applied. Chưa có: stash, prime/finish, reroll_paid, core_pick. 20 Lõi 'hook sẵn có' khả thi) |
| `godot/scripts/core/reward_generator.gd` | offer Lõi 3 thẻ khác trục, bậc theo mốc, bỏ thẻ relic/chaos/curse khỏi pool trận, shop |
| `godot/scripts/core/run_map_generator.gd` | `reward_kind` + affix |
| `godot/scripts/core/action_log.gd`, `run_verifier.gd` | action `stash` (+ `swap_slots` nếu giữ Đổi Chỗ), kiểm mana reroll |
| `godot/autoload/RunState.gd`, `ContentDB.gd`, `MetaState.gd` | Lõi sở hữu, quest, affix, perk relic0/relic1, field meta chống lặp |
| `godot/resources/relics/*.tres` | 46 Lõi mới `c_*.tres` (4 `disabled`) + 13 Luật run `rule_*.tres`; 133 file cũ `hidden_from_pool = true` |
| `godot/assets/data/rules/combat_tune.json`, `ascension.json` | knob 6.2, nhịp boss |
| `godot/assets/data/part_faces.json` | KHÔNG đổi |

`ActionLog.RULES_VERSION` bump + `worker/src/` `SUPPORTED_RULE_VERSIONS` + deploy Worker: hỏi Liam trước (CLAUDE.md). Chạy `Godot --headless --path godot --import` trước test vì class_name mới.

### 8.2 RULES_VERSION bump lần 1 (chỉ phần này)

Lõi hệ + luồng offer; Hold; mana-reroll; hàng trước/sau; Mồi/Kết; affix Elite; nhịp boss; reward_kind trên node; knob độ khó 6.2; ascension v2 đã duyệt (nếu chưa vào); các việc backlog mục B (comment Mythic, chữ trạng thái Ranked).

### 8.3 Để bump lần 2 (Liam đã chấp nhận có bump 2)

Thử thách, Mutator, Rune chọn chủ động, gán mặt chồng (2c), node Forge, mặt Focus gốc trong `part_faces.json`, thêm Lõi dự phòng (có thể vào bump 1 nếu là data thuần, vì `resources/relics` nằm trong fingerprint nên vẫn là bump).

### 8.4 Worker

- `ALLOWED_FNS` (`worker/src/run_core.js:21`) phải khớp `ActionLog.ALLOWED_FNS` (`action_log.gd:75`): thêm `stash`, và `swap_slots` nếu giữ Lõi Đổi Chỗ. Lõi pick/reroll: ĐÃ KIỂM, tái dùng được: `take_reward`/`reroll_rewards` đã trong cả hai `ALLOWED_FNS`, verifier xử lý (`run_verifier.gd:183`, `:192`), `reroll_pending_rewards` `RunState.gd:1126` dùng `_reward_reroll_salt` làm `k` epoch `reward_reroll` (`:729`). Pact boss là tiền lệ (seed epoch xor `PACT_SEED_SALT`, không kind mới): offer Lõi = seed epoch `reward` xor `CORE_SALT`. `RewardGenerator.generate` là 3 thẻ trộn `_type_pool` nên cần hàm offer Lõi riêng, chỉ đi chung đường take/reroll. Danh sách `ALLOWED_FNS` thứ ba cần khớp: `t_replay.gd:336/428`.
- Reroll epoch (`epoch_args.json:21`, `(turn,k,source)`, kiểm trong `run_core.js:82`): mỗi lượt vẫn tối đa k theo số reroll, nhưng free/mana thay đổi nguồn. `source` thêm giá trị `mana`: ĐÃ KIỂM, enum đóng `["base","aid"]` (`epoch_args.json:9`), đọc chung cả Worker và `t_remote_epoch_ui_run`; `isPaid` chỉ tính phí khi `source==='aid'`. Mana trừ trong engine (`combat_engine.gd:672`), không phải server thu, nên reroll mana vẫn là `base`: KHÔNG cần enum mới, chỉ cần verifier tái hiện chi phí. Đề xuất: không đổi enum/Worker cho việc này. Server chỉ kiểm range; verifier (`run_verifier.gd`) phải kiểm (turn,k) và mana đủ (ghi chú trong `run_core.js` dòng 81).
- Epoch roll đầu lượt với viên bị Giữ: verifier phải biết viên Giữ không roll lại. ĐÃ KIỂM: KHÔNG; `end_turn` epoch chỉ có `(turn, attempt)` (`combat_engine.gd:585`), `reroll` mới có `uids`. Không cần đổi schema: seed xác định, engine tự bỏ qua viên Hold; verifier tái hiện được nếu `stash` nằm trong log trước `end_turn`. Cần `t_replay` có stash để chắc chuỗi draw không lệch.
- Test Worker: thêm cho `stash`, `reroll` source `mana`. Số sàn Worker 152/152 (`technical-preferences.md`) đổi cùng commit.

### 8.5 INV-1..7 và INV-6

| INV | Trạng thái |
|---|---|
| INV-1 | Không đụng. Lõi/relic không vào bộ sưu tầm. |
| INV-2 | Không đụng. |
| INV-3, INV-4 | Không đụng (không có Forge mới, không đổi partId). |
| INV-5 | Không đụng, vì `part_faces.json` giữ nguyên (xác nhận bằng `t_part_faces`). |
| INV-6 | SỬA CHỮ (câu 1). |
| INV-7 | Không đụng. Lõi nhiệm vụ không gate bằng năng lượng/vé. |

**Chữ INV-6 đề xuất** (`build-spec.md` dòng 34): "INV-6. Tiền thật chỉ mua giải pháp cho độ khó (Aid: reroll, lùi boss clock, reroll Lõi, tiếp tục sau thua), kể cả trong ranked. Tiền KHÔNG mua trực tiếp một Lõi, part, hay kết quả xúc xắc cụ thể. Mọi xúc xắc roll trên server, run chỉ chơi online. Mọi SKU phải khai báo trong `aid_prices.json` với `kind` thuộc danh sách Aid." Dòng test 324 (`STORE.every grants layer!=='power'`) phải sửa theo, và `t_economy` / Worker test cần kiểm có kiểm chữ này không.

### 8.6 UI cần sửa (mỗi thay đổi một spec nhỏ, theo `godot/CLAUDE.md`; mở lại UI-03 theo Liam)

1. Màn chọn Lõi (3-4 thẻ, bậc hiện tại + chấm bậc lần kế, nút reroll trên từng thẻ + số reroll còn lại, ô nhiệm vụ nhiều nấc). Dùng lại cho Luật run (2 thẻ, không reroll). Mới. Không còn tiến độ bộ.
2. Combat: nút Hold + viên Giữ, ranh giới hàng trước/sau, giá reroll bằng mana, nhịp boss (3 chấm Chuẩn bị/Đòn/Hở), chip affix, panel Lõi đã sở hữu (6 ô).
3. Run map: icon `reward_kind`, chip affix Elite, chip Lõi nhiệm vụ (đếm).
4. Tooltip Lõi qua `UI3.describe()` / `player_text()` (không ghép chuỗi thô, `godot/CLAUDE.md`). Từ vựng Mồi/Kết/Focus/Giữ cần mục trong Codex.
5. Result screen / pause menu: danh sách Lõi thay danh sách relic.
6. Tutorial: ngắn, dạy Hold + hàng trước.
7. (vòng 3) **Dạy Giáp và các cơ chế 6.7 cho run đầu.** Một câu affix trên node không đủ: người mới không đọc chip map, thứ dạy thật là con số. Yêu cầu (làn D viết spec, Liam duyệt): (a) khi chọn/kéo viên dmg lên quái có Giáp, hiện ngay trên mục tiêu "4 → 1" (cần hàm preview không side-effect từ làn A); (b) icon Giáp + số P cạnh thanh HP quái, có glyph, không để màu đứng một mình; tương tự cho ward, mend, Phản Đòn (đếm "2/3"), Đòn Nạp (mục tiêu đã chốt); (c) lần đầu trong tài khoản đánh mặt dmg vào quái có Giáp: một dòng coach dùng hệ tutorial có sẵn, cờ meta một lần, ví dụ "Giáp trừ 3 mỗi đòn đơn. Poison hoặc debuff làm Giáp tắt 2 lượt."; (d) chữ nổi "Vỡ Giáp" khi debuff/poison tắt Giáp, và "Giáp mòn" khi chống kẹt trận (6.7b) bắt đầu; (e) tooltip affix trên node map và trên Elite trong trận. Lần gặp Giáp đầu tiên nên là trận thường có quái tank trước Elite đầu (làn A, 9 mục A.13), để người chơi học ở chỗ không mất gì.

## 9. Plan 3 ngày (4 làn song song, tối đa 4 agent)

Nguyên tắc `production/agent-token-rules.md`: mỗi làn đọc đúng chỗ, báo ≤15 dòng, commit sớm, chỉ làn lead chạy cả suite. Không commit/push/deploy khi Liam chưa bảo. Mỗi làn xong phải có agent cao cấp khác review (CLAUDE.md).

**Ngày 0 buổi sáng (trước khi bắt đầu, 1-2 giờ, người thiết kế + lead):** chốt schema `RelicDef` mới (`core_axis`, `requires`/`excludes`, `disabled`, `quest` nhiều nấc; không còn `core_set`), các field run save (`core_tier_chain`, `core_seen`, `core_reroll_left`, `core_quest_progress`, `run_rule`), knob `core_t_cap`, tên action, tên knob, thứ tự tiêu thụ Mồi/Kết. Đây là "hợp đồng" để các làn không đụng nhau.

| Làn | Phạm vi | File chạm | Phụ thuộc | Test cần có |
|---|---|---|---|---|
| **A. Engine chiến đấu** | Hold (`stash`), reroll mana, targeting hàng trước/sau, Mồi/Kết (prime_log), nhịp boss, affix engine, **knob cho Luật run**: `free_reroll`, `stash_max` + Focus, độ dài nhịp boss, `mana_carry` + mana đầu lượt, hàng ưu tiên của quái đánh đơn, bonus theo hàng theo trận, `enemy_dmg_mult` | `combat_engine.gd`, `damage_pipeline.gd`, `action_log.gd`, `run_verifier.gd`, `combat_tune.json` | Hợp đồng ngày 0 | `t_stash`, `t_reroll_mana`, `t_front_row`, `t_prime_finish`, `t_boss_rhythm`, `t_elite_affix`, mở rộng `t_replay` (stash + mana-reroll + tamper) |
| **B. Hệ Lõi + luồng nhận + Luật run (offer)** | `RelicDef` fields (`core_axis`, `requires`/`excludes`, `disabled`, `quest` nhiều nấc; KHÔNG `core_set`), offer 3 thẻ khác trục + lọc đội, **chuỗi bậc rút lúc `new_run`** (`TIER_SALT`), reroll **từng thẻ** (2/run) + `core_seen`, 6 ô + 1 ô Luật run, quest tracker nhiều nấc, hide relic cũ, shop/event, perk relic0/1 thành thẻ thứ 4 lần 1; **offer Luật run 2 thẻ** (`RULE_SALT`, Lõi ẩn `run_rule`, qua `take_reward`); Worker (`ALLOWED_FNS` nếu reroll thẻ cần chỉ số, `epoch_args`) + sửa chữ INV-6 chỉ cho khớp hiện trạng. Cắt: anti-repeat qua meta, set bonus | `reward_generator.gd`, `RunState.gd`, `relic_slots.gd`, `relic_def.gd`, `MetaState.gd` (chỉ perk), `worker/src/*`, `resources/relics/relic_tuning.tres`, `build-spec.md` (chữ INV-6, cần Liam OK) | Ngày 0 | `t_core_offer`, `t_core_tierchain`, `t_core_reroll_card`, `t_core_seen`, `t_core_filter`, `t_core_quest`, `t_run_rule_offer`, cập nhật `t_relic_*` (cũ hidden), `t_rules_version`; Worker test mới. Bỏ `t_core_set`, `t_core_antirepeat` |
| **C. Nội dung 46 Lõi + 13 Luật run** (xem "Thay đổi nội dung cho làn C" cuối mục 9) | Viết 46 `c_*.tres` + hook; 13 `rule_*.tres` (data thuần, knob); bảng text qua `UI3.describe()` | `resources/relics/c_*.tres`, `resources/relics/rule_*.tres`, `relic_hooks.gd` (hook mới, chỉ cuối file) | A (Mồi/Kết/stash + knob cho Luật run), B (schema); bắt đầu bằng ~24 Lõi chỉ dùng hook có sẵn và 8 Luật chỉ cần knob có sẵn | `t_core_catalog` (46 Lõi: có text, hook thật, `requires` hợp lệ, không NaN), `t_core_behaviour` (1 proof mỗi Lõi rule/dice), `t_run_rule_catalog` (13 luật, tổng trọng số 16: knob có thật, `excludes` khớp Lõi) |
| **D. UI + map + sim** | Màn chọn Lõi, combat HUD (Hold, hàng, nhịp boss, affix), map (reward_kind, affix), codex, sim độ khó | `godot/scenes/` (CoreOffer mới, CombatView/Hud, RunMap), `run_map_generator.gd` (chỉ phần `reward_kind`+affix), `design/handoffs` spec nhỏ | Ngày 0 hợp đồng; spec UI mỗi cái một file (Liam duyệt) | `t_ui_laws`, `t_ui3_theme`, ảnh chụp 2 cỡ (1920x1080, 1280x720), `t_runmap_*` |

Chia thời gian:
- **Ngày 1:** A, B, C bắt đầu cùng lúc (C làm ~24 Lõi chỉ dùng hook sẵn có + 8 Luật chỉ cần knob có sẵn); D viết spec UI + dựng khung màn Lõi. Cuối ngày 1: A merge stash + reroll mana + targeting (xanh); B merge schema + offer + chuỗi bậc.
- **Ngày 2:** C làm 22 Lõi còn lại (cần Mồi/Kết/field run) + 4 Luật còn lại; A: nhịp boss + affix + knob Luật run; D: HUD + map; B: quest nhiều nấc + reroll từng thẻ + `core_seen` + offer Luật run + Worker. Cuối ngày 2: tất cả merge vào nhánh tích hợp, chạy full suite một lần.
- **Ngày 3:** sim độ khó + chỉnh knob 6.2 (A + người thiết kế), review chéo từng làn (agent cao cấp khác), RULES_VERSION bump (hỏi Liam), `export-web`/deploy chỉ khi Liam bảo.

Thứ tự merge: B (schema) -> A (engine) -> C (Lõi) -> D (UI/map) -> bump/Worker cuối. Mỗi merge: merge đúng hash đã review (`lane-merge-pitfalls`), grep CONFLICT, chạy `--import`.

Rủi ro:
0. (Cập nhật 20/10 tối) Pool giờ là 46 Lõi (42 bật) + 13 Luật run + chuỗi bậc + reroll từng thẻ, nặng hơn bản 40. Bù thời gian đã chốt: cắt Mặt Đảo, Đổi Chỗ, anti-repeat qua meta, bộ Lõi, Trộm Mana. Ưu tiên cắt tiếp (theo thứ tự): reroll từng thẻ lùi về "cả bộ ba cùng bậc" (nếu schema action khó) -> Mai Lớn Dần, Xuống Trận (cần field run/hook lạ) -> Thuỷ Triều Lên, Quạ Đưa Tin (cần cờ/ stat) -> còn 10 Luật -> Lõi R/H trùng vai theo mục dưới. Luật run cần B làm offer 2 thẻ, C 13 file data, A knob, D dùng lại màn chọn Lõi: khoảng nửa ngày + knob của A.
1. 46 Lõi trong 3 ngày là chặt: nếu trễ, cắt còn 34. (vòng 2 cập nhật danh sách cắt, vì Răng Mài, Hai Mặt, Mặt Đảo, Mẻ Trứng đã không còn trong pool.) Thứ tự cắt: Mai Lớn Dần, Xuống Trận (field run/hook lạ) -> stat Vảy Sớm, Giọt Sương -> Lõi R/H trùng vai: Đổi Mana Lấy Khiên (trùng Sóng Khiên ở vai "khiên thành giá trị"), Giữ Vững (trùng nửa Luật Băng Nguyên), Nổ Bào Tử -> quest còn 3 (giữ Săn Chimera, Hồ Cạn, Kẻ Gác Đêm) -> Trứng Vàng (chết nếu không có Tổ Ấm). Giữ mọi Lõi T (41-46 nay là Lõi chính thức). Pool sau cắt vẫn phải đủ mỗi trục ít nhất 2 Lõi ở mỗi bậc nó có mặt, nếu không thì luật "thiếu pool" chạy quá thường.
2. Verifier replay cho `stash` và mana-reroll là phần dễ sai nhất: xếp A làm kiểm tamper ngay từ ngày 1.
3. Sim độ khó chưa có số baseline (Liam bỏ): phải thừa nhận đây là chỉnh bằng cảm giác + vài trăm run sim.
4. UI-03 mở lại: giữ luật `godot/CLAUDE.md`, không làm lại cả bộ.
5. Lõi nhân sát thương chồng (Mặt Gương + Chữ Ký Máu + Thác Đổ; Phán Quyết đã tắt): cần trần chung. Đưa vào `t_damage_cap`.
6. Hook cũ (133 relic) vẫn nạp: `t_relic_*` có thể sai vì relic cũ bị hidden. Lane B phải sửa test, không tắt test.

Cắt nếu trễ (thứ tự cắt, reviewer chỉnh; Đổi Chỗ, Mặt Đảo, anti-repeat qua meta, bộ Lõi, Trộm Mana ĐÃ cắt từ 20/10): reroll Lõi từng thẻ lùi về cả bộ ba -> Mai Lớn Dần / Xuống Trận -> affix chỉ còn 6 cái (6.4) -> nhịp boss chỉ làm 3 boss -> Lõi R/H theo thứ tự ở rủi ro 1 (còn 34) -> Luật run còn 10 (bỏ R11 Quạ Đưa Tin, R8 Thuỷ Triều Lên) -> Lõi T cắt sau cùng.

### Việc engine mới cho làn A (từ 6.7, 6.3, 6.4, 2b.2; giao thẳng)

Chưa kiểm code từng chỗ, chỗ nào nghi ghi "cần kiểm". Mọi file đổi nằm trong fingerprint `t_rules_version`, gộp vào bump 1.
1. **Status `plating` (M1, M6)** trên `Unit`: giá trị P, đếm `plating_off_turns`. Hook trong `DamagePipeline.resolve`: mặt dmg đơn (`attack=true`, không pierce/poison/thorns/AoE) bị trừ P, tối thiểu 1, SAU bonus Lõi. Tắt 2 lượt khi `StatusEngine.add_status` thêm stun/weaken/poison... lên nó. Knob: `plating_div`=12, `plating_min`=2, `plating_max`=4.
2. **Trait quái trong `ContentDB`**: field `traits` theo role (tank: plating; healer/buffer: ward + mend), đọc ở dựng quái. Knob: `ward_base`=3, `ward_pw_div`=4, `ward_max`=7, `mend_pct`=0.20, `mend_cap`=6.
3. **Hook đầu lượt địch**: `ward` (khiên cho đồng minh khiên thấp nhất), `mend` (hồi nếu mục tiêu không có poison/stun/weaken). Cần kiểm: poison xuyên khiên hay không.
4. **Bộ đếm `spite_hits[tgt]`** reset đầu lượt người chơi; phản đòn dùng `DamagePipeline.resolve` với `attack=false, pierce=true`. Knob: `spite_after`=3, `spite_dmg`=2 (3 từ pw 8).
5. **Intent kind `charge`** trong `_pick_enemy_intent` (`combat_engine.gd` ~518): chu kỳ 3+1 lượt, tell công khai ở lượt Nạp, mục tiêu chốt lúc Nạp, mult 2.5. Ngắt bằng stun/freeze (đã có xử lý stun bỏ intent ở ~1403, cần kiểm freeze). Event stream mới: `plating`, `ward`, `mend`, `spite`, `charge_start`, `charge_hit`. Knob: `charge_mult`=2.5, `charge_cycle`=3.
6. **Nhịp boss (6.3) dùng chung `plating` + `charge`**: cờ pha Chuẩn bị/Đòn/Hở bật tắt plating (cần kiểm `_boss_turn_traits` ~1490).
7. **Schema affix**: nhóm A/B, 5 affix mới (11-15), affix #6 đổi thành Phản Đòn, luật chọn "Elite đầu luôn nhóm A; hàng 11+ A + B"; run đầu (`META.runs == 0`, cần kiểm tên field) Elite luôn Giáp Sắt, các affix khác tắt. Sinh affix dùng salt riêng, không thêm draw vào rng chung.
8. **Knob cho Luật run mới**: R12 `plating_global`=2 (mọi quái có Giáp) và `side_face_bonus`=2 (shield/poison/debuff Axie); R13 `dmg_use_soft_cap`=2, `dmg_overuse_penalty`=2, `nondmg_mana`=1 (đếm số mặt dmg đã dùng trong lượt, reset đầu lượt).
9. **A3 (đã chốt)**: knob `free_reroll` đọc `ascension >= 3` = 0 và mọi reroll tốn mana; làn B loại R1 khỏi pool rule ở A3+.
10. **Test**: `t_plating`, `t_ward_mend`, `t_spite`, `t_charge`, `t_boss_plating_rhythm`, mở rộng `t_elite_affix` (nhóm A/B, run đầu Giáp Sắt), `t_damage_cap` thêm ca Giáp x Lõi cộng phẳng, `t_replay` có ca charge + plating (tamper). Replay phải tất định: không rng mới.
11. **Sim/chơi thử**: tỉ lệ lượt không-attack >= 35% từ Elite đầu (6.7).

(vòng 3, bổ sung cho đủ rõ; chỗ nào mâu thuẫn với 1-10 thì theo phần này)
- A.1 rõ hơn: "Lượt" = lượt người chơi. Debuff/poison lên quái đặt `plating_off_turns = 2` (đặt lại, không cộng); giảm 1 đầu mỗi lượt người chơi; Giáp bật khi = 0. Tức dính ở lượt T thì tắt hết lượt T và T+1. Mọi debuff tính, kể cả `vulnerable`. Thứ tự: giá trị + bonus phẳng (trần +10) -> nhân (vulnerable, Hở, Vết Nứt) -> trừ Giáp -> min 1 -> khiên -> HP. Chỉ mặt `t == "dmg"` đơn mục tiêu bị Giáp; sát thương từ Lõi, poison tick (đã `pierce`), thorns, AoE, mặt có keyword `pierce` thì không. Giáp nhiều nguồn lấy max (6.7b.4). Knob thêm: `plating_off_turns`=2, `plating_decay_turn`=7.
- A.2 sửa: mỗi quái tối đa 1 trait (tank plating, Jellyfin/Chimera Totem ward, Warden mend), không còn "healer/buffer: ward + mend". Role đã có field `role` trong `ContentDB.gd` ~314+. Trần số quái mang trait mỗi trận (6.7b.7), Elite affix A bỏ trait role (6.7b.6). Tất định, không rng.
- A.3 sửa: poison đã xuyên khiên (`status_engine.gd:118` pierce, `damage_pipeline.gd:85`), bỏ "cần kiểm". Ward chọn đồng minh khiên thấp nhất, hoà thì ô nhỏ nhất, trần `ward_stack_cap`=2xS. Mend kiểm status lúc hồi, trần `mend_fight_cap`=0.5 Max HP nguồn mỗi trận.
- A.4 rõ hơn: đếm theo quái bị đánh, chỉ mặt dmg đơn; Axie nhận phản đòn là Axie có viên vừa dùng; có thể làm Axie ngã. Lần dùng lại của Mặt Gương và viên thứ 6 đều tính. Quái có M3 bỏ thorns cũ. Knob `spite_pw_step`=8.
- A.5 sửa: chu kỳ 4 (`charge_period`=4, Nạp khi `n%4==3`), luật chọn và chọn lại mục tiêu, boss không nhân 2.5 và stun chỉ hạ Đòn về mặt thường (6.7 M5).
- A.7 sửa: "hàng 11+" thành "sau boss 1"; cặp cấm 15+7, 15+3; lọc nhóm A theo `team_can_break` (6.7b).
- A.12 **`team_can_break`** tính ở `begin_run` từ mặt đội, lưu trong run state (làn B đọc để lọc R12). Test `t_team_can_break`: đội Aqua/Plant thuần = false, có 1 back Beast = true.
- A.13 Run đầu: trước Elite đầu bảo đảm 1 trận thường có quái tank (encounter gen, tất định).
- A.14 **Hàm preview** sát thương không side-effect (giá trị sau Giáp) cho UI "4 → 1" (8.6 mục 7). Cần kiểm đã có chưa.
- A.15 Event thêm: `plating_off`, `plating_decay`. Test thêm: `t_plating_stack` (max không cộng, R12 x tank x Giáp Sắt), `t_anti_stall` (đội không phá Giáp gặp Elite Giáp Sắt + Warden: trận xong trong <= 14 lượt bằng bot chỉ đánh), `t_affix_pairs` (không ra 15+7, 15+3).

### Thay đổi nội dung cho làn C (Lõi + Luật run)

1. **Tắt 4 Lõi** (`disabled = true`, giữ file): Mũi Giáo, Hợp Đội, Tích Ác, Phán Quyết. Sửa `requires` còn nhắc Hợp Đội (2.2) cho khỏi trỏ vào Lõi tắt.
2. **Thêm 4 Lõi** (2.10): Vết Nứt (N12), Y Sĩ Chiến Trường (N13), Độc Lan (N14), Lò Độc (N15), kèm `requires`/`excludes` và hook mới ở cuối `relic_hooks.gd`. Vết Nứt cần hook "quái dính status" + mất Giáp (phụ thuộc A.1).
3. **Gắn tag `rewards`** cho 46 Lõi (`attack`, `nonattack`, `convert_to_dmg`, `tradeoff`) để `t_core_catalog` kiểm: >= 24 nonattack, >= 6 convert_to_dmg, >= 3 tradeoff.
4. **Luật run**: viết `rule_vo_cung.tres` (R12), `rule_the_can_bang.tres` (R13), bỏ `rule_dai_hoi_muon_loai`; thêm field `weight` vào data luật (R10, R12, R13 = 2, còn lại 1); `excludes`: R13 loại Thác Đổ (vòng 3: bỏ Lò Độc cho khớp 2b.2, Lò Độc dưới R13 là lựa chọn bỏ attack hợp lệ); R12 `requires: team_can_break` (6.7b); R1 chỉ rút khi Ascension < 3 (làn B đọc cờ). `t_run_rule_catalog` kiểm 13 luật, tổng trọng số 16.
5. **Bỏ `excludes` Hợp Đội/Đồng Tâm với luật Đại Hội** (đã gỡ ở 2.2).
6. **Text** qua `UI3.describe()`: mỗi luật/Lõi mới một câu, ghi rõ nó khắc "chỉ đánh" (vd "Mọi quái có Giáp 2: mặt dmg đơn -2").

## 9b. Ghi chú kỹ thuật (lead-programmer)

1. Làn A và B đều sửa `RunState.gd`/`action_log.gd`/`run_verifier.gd`; A (stash, mana-reroll) và B (offer Lõi, `core_*` trong save) chung 3 file này. Chia: A giữ `action_log.gd` + `run_verifier.gd`, B chỉ thêm vào `RunState.gd`; `ALLOWED_FNS` + `t_replay` list chỉ A sửa (một chỗ, một agent), B yêu cầu A thêm. `relic_hooks.gd` (2002 dòng) A và C cùng thêm hook: để C chỉ thêm hook của riêng Lõi vào cuối, A không đụng.
2. Bump RULES_VERSION phải là commit cuối của tích hợp, một lần. Mọi làn đổi file trong fingerprint (`scripts/core`, `autoload`, `resources/relics`, `assets/data/rules`, `scripts/meta`, `part_faces.json`: `t_rules_version.gd:21-24`) nên `t_rules_version` đỏ ở mọi làn; làn dùng `AXIE_SKIP_RULES_FINGERPRINT=1` (`production/l1-lanes.md`), lead chạy bản thật khi tích hợp. Worker thêm version mới vào `SUPPORTED_RULE_VERSIONS` (`run_do.js:18`), deploy Worker TRƯỚC build client.
3. Fixture replay/sample run (`record_sample_run`) và `t_full_run_loop` (8 seed-walk), `t_map_invariants`, `t_boss_encounters` sẽ đổi hết khi map/boss/offer đổi; cần ghi lại fixture sau khi A+B+C merge, không làm song song. Đây là việc ngày 3 chưa có trong plan.
4. Sim cân bằng không tồn tại (xem mục 5): thêm 0.5-1 ngày vào làn D hoặc tách việc, nếu không ngày 3 chỉ tune bằng cảm giác.
5. Tính khả thi (viết cho bản 40 Lõi; nay 46 Lõi + 13 Luật run, rủi ro 0 ở mục 9): 40 Lõi + `t_core_behaviour` + 133 relic cũ bị ẩn nhưng `t_relic_*` vẫn phải xanh, cộng 3 ngày với 4 agent: KHẢ THI chỉ ở mức cắt (nay 34 Lõi, rủi ro 1) và nếu ngày 0 chốt hợp đồng xong. Khuyến nghị cắt sẵn: Đổi Chỗ, Lõi dự phòng, affix chỉ 6, nhịp boss 3 boss. Làn D (nhiều UI mới, mỗi UI cần spec Liam duyệt) là điểm nghẽn thật, có thể trượt sang ngày 4.
6. Mục 8 đã đối chiếu: `ALLOWED_FNS` GD `action_log.gd:75` và JS `run_core.js:21` khớp hiện tại (`swap_slots` không cần nữa vì Đổi Chỗ đã cắt; thêm `stash` cả hai + `t_replay.gd:336`). Field meta mới (nếu có, ví dụ lần chọn Lõi thẻ 4 qua perk) phải vào `MetaState.reload_from_store()` (`MetaState.gd:543`, reset từng field) và ghi qua `SaveStore`.

## 9c. Ghi chú reviewer thiết kế (creative-director, 20/10)

Đã sửa thẳng vào các mục trên, chỗ nào sửa đều ghi "(reviewer)". Đây là những điểm lớn và chỗ không đồng ý với bản gốc.

1. **Lõi: bản gốc chưa tới mức "wow".** (ghi chú này viết cho bản 40 Lõi đầu tiên; bản hiện tại là 46, xem 2.4) Đếm lại 40 Lõi bản gốc: khoảng 13 cái thật sự đổi cách chơi (Chuỗi Mồi, Kết Cục, cặp Hold, Mặt Đảo, Xúc Xắc Thứ Sáu, Ngọn Triều, Nợ Mana, Tổ, Chữ Ký Máu, Phán Quyết, Vòng Lặp...), 5 nhiệm vụ, còn lại khoảng 22 là cộng số. Bậc Tinh Thể chỉ 9 cái và một nửa yếu hoặc hỏng: Cánh Kép trùng luật nền hàng trước, Cổng Hai Chiều là +0/+1 sau làm tròn, Lõi Rỗng và Thuế Tái Sinh không đổi cách chơi, Mặt Gương nửa giá trị. Đã viết lại hoặc thay 15 Lõi (#8, 13, 20, 21, 22, 23, 25, 27, 28, 30, 31, 32, 33, 34, 40), làm rõ chữ 8 Lõi (#7, 9, 10, 11, 24, 26, 29, 37), sửa 2 bộ (Gai món 3, Tổ món 3), thêm 6 Lõi Tinh Thể dự phòng (41-46). Sau sửa khoảng 20/40 Lõi đổi cách chơi, và mỗi trục đều có ít nhất một Lõi T đổi luật.
2. **Combo hỏng đã chặn:** (a) Đổi Mana Lấy Khiên bản cũ không tiêu mana, mana không cap, cộng Hồ Mana là khiên vô hạn cho cả đội. (b) Mặt Gương + Cất Lửa nhân đôi Focus: lần hai không nhận Focus. (c) Trần bonus phẳng chỉ chặn Mồi/Kết/Đa Sắc, Focus +8 nằm ngoài: gộp mọi bonus Lõi vào trần +10/mặt. Không thấy vòng lặp vô hạn nào còn lại. Mạnh nhất còn lại là Thác Đổ + Xúc Xắc Thứ Sáu + Mặt Gương (khoảng +40 dmg/lượt cuối run) và Bức Tường Sống + bộ Gai + Hàng Sau Phát Sáng (rùa): cả hai cần 3 Lõi T/H, chấp nhận được vì run "phá game" thỉnh thoảng là phần thưởng của roguelike, nhưng sim/chơi thử ngày 3 phải thử đúng hai build này.
3. **Lõi chết đã xử lý:** Hợp Đội và Vòng Lặp chết với đội không đủ điều kiện, nên thêm luật lọc ở 2.2. Bộ Tổ gần như không kích hoạt vì Egg ở hàng sau. Nhiệm vụ Kẻ Gác Đêm có thể không làm được vì hết Elite. Nhà Sưu Tầm thì cho không.
4. **Run sau có khác run trước không: chưa đủ.** Chống trùng ở 2.3 chỉ làm thẻ khác nhau; đội, quái, boss, map, luật đều như cũ. Pool T nhỏ làm "wow" lặp lại từ run thứ 2-3. Cắt Mutator là mất mát lớn nhất so với mục tiêu "các run không trùng lối chơi", lớn hơn cắt Forge, Thử thách hay Rune. Đề xuất bản tối giản (câu 5, không tự đưa vào plan):
   - Đầu run, trước lần chọn Lõi 1: hiện 2 **Luật run**, chọn 1. Rút từ 8 luật bằng `Rng.new(run_seed ^ RULE_SALT)` như chủ đề thiên vị ở 2.3.
   - Làm như một Lõi ẩn: `core_axis = "run_rule"`, `hidden_from_pool`, ô riêng, nhận qua `take_reward` có sẵn. Không action mới, không field header action log (lý do bản gốc cắt Mutator).
   - Mỗi luật chỉ chỉnh knob mà bump 1 đã tạo hoặc hook đã có. 8 luật đề xuất: **Mana Rẻ** (reroll 1 mana, không còn reroll miễn phí) · **Hàng Rộng** (hàng trước 3 ô) · **Nhịp Gấp** (nhịp boss 2 lượt) · **Lõi Sớm** (lần chọn 1 bậc Hổ Phách, chỉ 1 reroll Lõi) · **Tay Chắc** (Hold 2 viên, quái +10% HP) · **Kết Nặng** (mặt Kết +3, quái +10% sát thương) · **Cửa Hẹp** (bớt 1 lần chọn Lõi, mọi lần còn lại lên một bậc) · **Ổ Trứng** (mỗi trận 1 Egg hàng trước, mana đầu trận -1). Không có luật nào đụng map (map dùng rng chung, 7.1).
   - Ước: nửa ngày (B: offer 2 thẻ; C: 8 file data; D: dùng lại màn chọn Lõi với 2 thẻ). Nếu làm thì bỏ chủ đề thiên vị ẩn ở 2.3 #4, vì Luật run làm đúng việc đó mà người chơi thấy được.
5. **Quyết định trong lượt: đủ khó, đủ thú vị, với hai điều kiện.** Nền (chưa có Lõi) có ba quyết định thật: reroll bằng mana hay để dành, giữ viên nào cho lượt Hở của boss, xếp ai hàng trước. Mồi/Kết chỉ đến từ Lõi nên độ phức tạp tăng dần theo run, đây là điểm tốt nhất của bản này. Điều kiện 1: UI phải hiện trước giá trị (viên sắp nhận +3 Mồi, viên nào đang là Kết) khi người chơi chọn viên, nếu không thì thứ tự gán là quyết định vô hình và trái pillar minh bạch. Điều kiện 2: run đầu tiên của tài khoản không nên có cùng lúc Hold, hàng, mana-reroll, nhịp boss, affix, nhiệm vụ và bộ. Đề xuất: run đầu tắt affix Elite và không hiện Lõi `quest`; tutorial chỉ dạy Hold + hàng như 8.6 đã ghi.
6. **Không đồng ý với bản gốc về assassin (mục 4).** Nếu cả assassin cũng chỉ đánh hàng trước thì hàng sau gần như bất tử, xếp đội thành quyết định một lần mỗi run. Đề nghị assassin giữ hành vi hiện tại (yếu nhất toàn đội), và thay affix Tiên Phong bằng Đánh Lén. Game-designer chốt, không cần Liam.
7. **Độ khó (mục 6):** hướng đúng nhưng chủ yếu tăng HP, tức trận dài hơn chứ không khó hơn. Thêm knob sát thương quái, hạ boss HP x1.25 xuống x1.1, và đo bằng chơi thử trước khi chỉnh (câu 4). Bản này tự nó đã nerf người chơi mạnh (bỏ 133 relic nhân chồng, reroll miễn phí 2 xuống 1), nên tăng cả knob lẫn luật cùng lúc dễ đẩy quá tay.
8. **Cho lead-programmer (không sửa phần kỹ thuật):** Mặt Đảo (#11) là thao tác mới của người chơi, chưa có trong `ALLOWED_FNS` (đã cắt 20/10, bỏ qua). Lõi Rỗng nâng trần reroll lên 8/lượt: kiểm range `k` của epoch reroll phía server còn đủ không. Mạch Ngầm cần field mana mang qua trận trong `RunState` + save.

## 9d. Ghi chú reviewer thiết kế (vòng 2, creative-director, 20/10 tối)

Đã sửa thẳng ở mục 1, 2, 2b, 3.4, 4, 9, chỗ sửa ghi "(vòng 2)".

1. **Luật run hiện SAU khi đội đã khoá** (`begin_run` nhận `team_keys`). Vậy luật chỉ đổi cách đánh, không đổi cách dựng đội, và R12 Đại Hội Muôn Loài thành cộng/trừ trên đội có sẵn, không ai chơi khác đi. TFT hiện Cổng trước mọi thứ. Đề nghị hiện 2 Luật run trước màn chọn đội: đội 5 Axie là biến lớn nhất của run, để luật chạm vào nó là đòn bẩy rẻ nhất cho "run sau khác run trước". Liam quyết (câu 9). Nếu giữ thứ tự cũ thì thay R12 bằng luật đổi hành vi trong trận.
2. **Chuỗi bậc bản trước đặt đỉnh muộn:** 50% run chỉ có T sau boss 2. Đã đổi trọng số để 65% run có T ở lần 3, trung bình vẫn ~1.15 T (nghiên cứu Võ Đài/TFT nguyên tắc 2).
3. **Thêm trần Tinh Thể** (3 Short / 4 Full). Bản trước có 7 đường lên bậc mà không trần, người chơi giỏi gom được 4-5 T: đúng thứ làm game dễ lại.
4. **Lõi đã sửa:** Khế Ước Gai (đứng 1 HP reroll miễn phí vô hạn), Đội Hình Mở (nửa giá trị làm Lõi T yếu hơn không lấy), Lõi Rỗng (gần trùng Luật Mana Rẻ), Hòn Đá Mờ (giá ghi chưa rõ, có thể ra T trước boss 1), Hợp Đội (đếm cặp mơ hồ). Thêm `requires` cho Trứng Vàng, Đội Hình Mở, Đa Sắc, Nhà Sưu Tầm; thêm `excludes` cho Khế Ước Gai, Giữ Vững, Đội Hình Mở.
5. **Không đồng ý giữ R11 Quạ Đưa Tin không điều kiện:** nó thưởng bậc cho người đánh nhanh, tức chính người đang thấy game dễ. Giữ vì là luật duy nhất phá lối rùa bằng phần thưởng, nhưng nếu chơi thử thấy dễ thì cắt nó đầu tiên. R3 Nhịp Gấp là luật yếu nhất (chỉ chạm 3 trận boss mỗi run); thay thế dự phòng là "Hàng Rộng" (hàng trước 3 ô, 9c.4), đổi xếp đội ở mọi trận.
6. **Người mới:** run đầu giờ không luật, không quest, không Lõi cược, không affix. Lần 1 Rêu ổn: 3 thẻ khác trục đều đọc được trong một câu. Còn lại một rủi ro chưa giải: Mồi/Kết chỉ hay khi UI hiện trước giá trị (9c.5 điều kiện 1). Đây là việc làn D, không phải chuyện thiết kế.
7. **Câu 6 (lối trội là lối nào) vẫn là chỗ hổng lớn nhất.** 12 luật đang phủ 7 lối theo giả định. Nếu lối Liam thấy là thứ khác (ví dụ một part/relic cụ thể đang còn trong game), bảng 2b.2 phải xếp lại trọng số.

## 9e. Ghi chú reviewer thiết kế (vòng 3, creative-director, 20/10 khuya)

Đã sửa thẳng ở 2.7, 2.9, 2.10, 3.4, 6.4, 6.7, 6.7b (mới), 8.1, 8.6, 9; chỗ sửa ghi "(vòng 3)".

1. **Hướng đúng.** M1, M3, M5, M6 ép quyết định thật (mở Giáp rồi đánh, chia mục tiêu, khiên đúng Axie, Hold sang Hở). M2 là quyết định chọn mục tiêu, không ép đổi mặt; M4 gần là thuế với đội không có poison/debuff, nên đã thêm trần mend mỗi trận.
2. **Bế tắc thật nằm ở đội Aqua/Plant**, không phải đội "toàn dmg". Từ data: 49% biến thể part là dmg, nhưng chỉ 14% là poison/debuff và Aqua, Plant có 0. Bản trước để Giáp Sắt + Hồi Ngắt gặp đội này là trận không xong. Đã thêm `team_can_break`, lọc affix/R12, sát thương từ Lõi bỏ qua Giáp, Giáp mòn từ lượt 7 (6.7b).
3. **Chồng cơ chế:** bản trước cho Warden cả ward lẫn mend, Elite Bulwark có Giáp trait + affix. Đã đặt: 1 trait/quái, Giáp lấy max, Elite affix A thay trait, trần quái mang trait mỗi trận, cặp affix cấm.
4. **Không đồng ý nhỏ:** "1 vulnerable tắt Giáp 2 lượt" có thể quá rẻ với đội Beast/Bird, lối "1 mở + 4 spam" vẫn gần spam. Giữ vì nó là bài học đúng; chơi thử thấy rẻ thì hạ `plating_off_turns` xuống 1 trước khi tăng P.
5. **Người mới:** Giáp Sắt cố định ở run đầu chỉ dạy được nếu có preview "4 → 1" và một dòng coach; đã ghi yêu cầu làn D (8.6 mục 7) và hàm preview cho làn A (A.14).
6. **Tích lũy luật chống-spam ở boss:** R10 Rừng Già (+30% HP) + Giáp nhịp + Đòn Nạp có thể kéo boss 3 thành 12+ lượt. Chưa đặt trần; đo ở chơi thử ngày 3, nếu quá dài thì R10 không tăng HP boss.

## 10. Câu hỏi cho Liam (chỉ những chỗ phải Liam quyết)

Đã thành mặc định, không cần hỏi (Liam muốn đổi thì nói): tên bậc Rêu / Hổ Phách / Tinh Thể; Pact giữ là relic cũ ở bump 1; active relic (a_*) bỏ khỏi pool Lõi ở bump 1; có bump RULES_VERSION lần 2 cho phần cắt; Lõi T dự phòng 41-46 do reviewer viết; run dở lúc bump bị huỷ không phạt (hành vi sẵn có); Đổi Chỗ (#19) cắt khỏi bump 1; affix Elite theo danh sách 6.4.

1. **Tiền thật (INV-6 + reroll Lõi):** duyệt chữ INV-6 mới ở 8.5 (cho sửa `build-spec.md` + test kèm), và cho bán thêm reroll Lõi qua Aid ngoài 2 lần miễn phí (giá do economy-designer đề xuất, Liam duyệt sau). Khuyến nghị: duyệt cả hai. Không bán Lõi cụ thể.
2. **Affix Elite #4 Trộm Mana:** bản này biến mana thành tài nguyên chính, Trộm Mana lại gần như không tạo quyết định, chỉ khắc đội mana. Khuyến nghị: bỏ ở bump 1.
3. **Perk relic khởi đầu (`relic0/relic1`):** người chơi đã mở perk này, relic thì bị ẩn. Đổi thành "lần chọn Lõi 1 có thẻ thứ 4" hay bỏ hẳn? Khuyến nghị: thẻ thứ 4, người đã mở không mất gì.
4. **Độ khó: mục tiêu và cách đo.** Mục tiêu: Short A0, người chơi có kinh nghiệm thắng khoảng 45-60%, không archetype nào quá 60%? Cách đo: Liam (hoặc người chơi quen game) chơi 3 run Short ngày 3 rồi mới chỉnh knob, hay thêm 0.5-1 ngày viết sim (`sim_balance.gd`, chưa có)? Khuyến nghị: 45-60%, đo bằng chơi thử ngày 3; sim để sau, không kéo 3 ngày thành 4.
5. **Luật run (Mutator tối giản, ghi chú reviewer 4):** chọn 1 trong 2 luật đầu run, chỉ dữ liệu, không action mới, khoảng nửa ngày. Vào bump 1 hay để bump 2? Khuyến nghị: bump 1, đổi lấy phần đã nằm sẵn trong danh sách cắt (Mặt Đảo, Đổi Chỗ, anti-repeat qua meta) để không vượt 3 ngày. Đây là thứ đáng tiền nhất cho mục tiêu "không run nào giống run nào".

### Câu hỏi mới sau khi viết lại mục 2 + 2b (20/10 tối, chờ Liam)

6. **Lối chơi "một chiều" cụ thể là lối nào?** Tôi chưa suy ra được từ data nên 12 Luật run và Lõi khắc chế ở trên viết theo giả định (rùa khiên + Thorns, dồn burst một lượt, spam reroll, tích mana, tank trước carry sau, gom một class). Bạn nói đúng lối nào thì tôi đảm bảo pool có ít nhất 2 luật và vài Lõi đánh đổi khắc nó, và đẩy hai luật đó lên trọng số. Khuyến nghị: bạn mô tả 1-2 câu lối bạn thấy "cứ chọn đúng là thắng" (đội gì, relic/Lõi gì, đánh sao).
7. **Reroll Lõi từng thẻ: nếu kỹ thuật phải đổi schema action `reroll_rewards`, có chấp nhận lùi về "đổi cả bộ ba cùng bậc" ở bump 1 và để từng-thẻ cho bump 2 không?** Khuyến nghị: chấp nhận lùi, vì lõi cơ chế (không hiện lại Lõi đã thấy + chuỗi bậc) đã chặn "câu Lõi cụ thể" phần lớn; từng-thẻ chỉ là thêm.
8. **Run đầu tiên của tài khoản không có Luật run, và từ run 2 có 10% thẻ "Không luật".** Đồng ý không? Khuyến nghị: đồng ý (run đầu đã phải học Hold, hàng, mana-reroll cùng lúc).

### Liam trả lời (20/10 tối), đã chốt
1. Đang playtest, chưa đưa tiền thật vào sâu: KHÔNG bán reroll Lõi qua Aid, không thêm SKU mới. Aid giữ như hiện có. Chữ INV-6 chỉ sửa cho khớp hiện trạng, không mở thêm đường tiền -> sức mạnh.
2. Bỏ affix Trộm Mana.
3. Perk relic khởi đầu -> lần chọn Lõi đầu có 4 thẻ.
4. Đo độ khó bằng chơi thử (Liam: game rất dễ và **một chiều nếu chọn đúng cách đánh**, tức đang có lối đánh trội; thiết kế phải phá được nó). Sim để sau.
5. Luật run (Mutator tối giản) VÀO bump 1. Liam rất thích cơ chế chọn Lõi kiểu LoL: nghiên cứu sâu Lõi ARAM Hỗn Loạn / Võ Đài rồi áp dụng (đợt nghiên cứu 20/10 tối, kết quả ở `design/research/`). Bù thời gian bằng cắt Mặt Đảo, Đổi Chỗ, anti-repeat qua meta.

**Câu 6, 7, 8, 9 và A3 đã trả lời, xem mục cuối.** Câu 9 bỏ khỏi danh sách (Liam: luật hiện sau chọn đội; R12 đã thay bằng Vỏ Cứng, 2b.2). Câu 6 đã xử lý ở 6.7, 6.4, 2.10, 2b.2. Câu 7 và 8 đã chốt: sửa ở 2.1 và 2b.1. A3 đã chốt: 2b.1.

### Liam trả lời câu 6-9 + A3 (20/10 khuya), đã chốt
- **6. Lối một chiều = chỉ cần bấm mặt attack là thắng, quá chán.** Thiết kế phải làm cho "chỉ đánh" không đủ: quái/Elite/boss buộc dùng mặt khác (khiên, debuff, poison, mana, vị trí, Hold), Lõi thưởng mặt không phải attack, và ít nhất 2 Luật run khắc lối spam attack (đẩy trọng số).
- **9. Luật run hiện SAU khi đã chọn đội và vào run** (như luồng hiện tại). Thay R12 bằng luật khác không phụ thuộc lúc dựng đội.
- **7. Đồng ý** lùi reroll Lõi về "đổi cả bộ ba cùng bậc" ở bump 1 nếu phải đổi schema action.
- **8. Đồng ý** run đầu không có Luật run, từ run 2 có 10% thẻ "Không luật".
- **A3 (Ascension "Short Dice"):** ở A3 mất reroll miễn phí, mọi reroll tốn mana.
