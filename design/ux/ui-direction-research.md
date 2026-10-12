# UI direction research cho Axie Dice (12/10/2026)

Trạng thái: nháp để Liam đọc và chọn hướng. Chưa viết mockup prompt.
Người viết: ux-designer. Không đụng game code hay doc cũ.
Review: creative-director 12/10 (độc lập). Đã sửa vài claim sai về game tham khảo, bỏ những câu hỏi đã có quyết định,
và gom §5 còn 8 câu. Chỗ nào sửa có ghi "(sửa review)".

## 0. Cách đọc file này

Nguồn có 3 mức, mình đánh dấu để Liam biết cái nào tin được:

- **[S]** = có trong kết quả search ngày 12/10/2026 (link ở mục 6). Search chỉ ra review và guide, rất ít
  teardown UI thật, nên [S] vẫn là mức "người ngoài mô tả", không phải dev nói.
- **[M]** = mình nhớ từ lúc chơi / từ kiến thức cũ, search không xác nhận được. Cần ai đó mở game ra
  kiểm lại trước khi dựa vào.
- **[?]** = không tìm được, không biết.

Giới hạn thật: không có GDC talk hay postmortem UI nào tìm ra được cho Hades, Monster Train 2, Backpack Battles,
Dicey Dungeons. Phần lớn "pattern" bên dưới là quan sát của mình, không phải lời dev. Doc cũ
`design/ux/combat-screen-shroom-gloom-inspired.md` (18/9) cũng viết từ quan sát, không phải nguồn gốc.

Lưu ý quan trọng về Shroom and Gloom: nó là game **thẻ bài** góc nhìn thứ nhất, không có dice [S]. Nó dạy cho mình
về "bàn tay của người chơi nằm trong cảnh" và về bản đồ cầm trên tay, không dạy về dice.

### 0.1 Những gì đã chốt, file này không mở lại (sửa review)

- **Combat** (`ui-direction-liam-draft.md`): đồ hoạ trận đều 3D; 5 Axie nửa dưới quay lưng, quái/boss nửa trên quay mặt;
  mỗi biome một sân ghép từ bộ mảnh Homeland; thắng → đội chạy xuyên chỗ quái → cổng `SM_Portal_01` mở → chuyển cảnh
  (loé sáng), máy quay không bám theo; **xúc xắc ở khay dưới đáy, mỗi viên thẳng hàng với Axie của nó**.
- **Nền tảng**: Windows + macOS trước, web song song, mobile sau (`core-loop-v2.md`, khối quyết định 10/10). Canvas mockup
  1920×1080, chuột + bàn phím. Gamepad hiện **không** nằm trong phạm vi (`technical-preferences.md`).
- **Hub**: màn chính là Land 3D sống (Axie đi lại), các nhà là lối vào (`active.md`, `core-loop-v2.md` P2).
- **Monetization**: chỉ trong run; Aid chào đúng khoảnh khắc đau, có trần công khai, không đếm ngược, không popup chặn,
  khay Aid cách xa END TURN (`monetization-v1.md` §2.0–§2.2). Pháp lý Sky Mavis đã duyệt hướng này (12/10).
- **Boss clock / enrage**: đã có spec (`ascension-v2.md` §2.4, `monetization-v1.md` §1.2-C): bộ đếm trên nameplate boss
  "Enrage in N" rồi "Enrage ×1.4"; có bản nhẹ ở A0 (lượt 14).
- **Map che node xa** (18/9, `combat-screen-shroom-gloom-inspired.md` §5.4): node cách 2+ hàng hiện "?" và mờ; hàng chọn
  được luôn hiện đủ icon. Aid R7 Scout bán đúng phần bị che này (3 hàng kế).
- **Cosmetics**: giữ style Homeland, chỉ ép viền đậm ở cỡ nhỏ (`design/handoffs/cosmetics-01/REVIEW.md`, A1).
- **Damage preview khi hover** đã có trong game (`CombatView.gd`, `HPBar.set_preview()`), mặc định bật. Giữ.

## 1. Các game đã xem và bài học (ngắn)

| Game | Bài học dùng được | Nguồn |
|---|---|---|
| Shroom and Gloom | Góc nhìn thứ nhất, bạn là người cầm bài; map là thứ cầm trên tay; tường hầm 3D + minh họa 2D viền dày xếp lớp tạo chiều sâu; intent hiện rõ: giao diện cho biết gần như chính xác sát thương sẽ nhận sau lượt; HP rất hẹp, đầu game ít block nên mỗi lựa chọn có giá. Có 2 deck (chiến đấu và khám phá). Early Access trên Steam từ 10/9/2026 (Devolver phát hành) | [S]. Con số "91% tuần đầu" bản trước ghi: **không xác minh được** (sửa review), đã bỏ |
| Slay the Spire 2 | Intent gần như full info; nhiều hành động của 1 quái xếp **ngang** thay vì chồng lên như bản 1; damage tấn công hiện số chính xác; xem được draw/discard pile; map có legend, hover icon legend thì highlight mọi node loại đó; thanh trên cùng map hiện HP, tiền, thời gian | [S] (guide cộng đồng, không phải dev) |
| Slay the Spire 1 | Map dọc, đường nối đơn giản, 1 màn hình = 1 quyết định; reward 3 thẻ + Skip | [M] |
| Balatro | Không hiện trước điểm **cuối cùng** sau joker (loại tay + chip × mult gốc thì có hiện). Theo phân tích GMTK, lý do là giữ độ căng và màn "cỗ máy Rube Goldberg" lúc tính điểm, tức niềm vui nằm ở **lúc xem điểm chạy**, không phải trước khi chơi (sửa review). GMTK coi đây là điểm thiết kế gây tranh cãi. Khi resolve thì cho thấy từng thứ kích hoạt cái gì; feedback nhiều lớp (animation thẻ, counter chạy, hiệu ứng màn hình, hạt, âm thanh); UI sạch. Axie Dice đi ngược ở chỗ che điểm (minh bạch), chỉ học phần feedback | [S] |
| Dicey Dungeons | Mỗi góc màn hình giữ 1 thứ chính; mỗi equipment là 1 hộp có chỗ trống lớn ở giữa để thả dice, hành động nằm dưới; slot ghi rõ dice nào hợp lệ (lẻ, chẵn, số cụ thể) | [S] |
| Monster Train 1 và 2 | Quái báo trước cách tấn công; game **tính trước kết quả** của lượt và đánh dấu quái/đồng minh nào sẽ chết trước khi commit. Có từ bản 1, không phải tính năng mới của bản 2 (sửa review). Laura Michet (blog cá nhân) nói đây là tính năng quan trọng nhất với cô, vì không có nó phải tự cộng 5–10 số mỗi vòng. Câu bản trước "cả game được thiết kế quanh tính năng này" không xác minh được, đã bỏ. Map icon và shop UI bản 2 gọn hơn | [S] |
| Backpack Battles | Review khen UI trực quan và quản lý balo; làm bằng Godot (Wikipedia); phần còn lại không xác minh được | [S] một phần |
| Hades (hub) | Hub chia khu theo chức năng (Great Hall, phòng ngủ có Mirror, Contractor, Broker...), các việc sau run là các hoạt động tách riêng; Mirror dùng 2 icon-màu cho nhánh cơ bản và nhánh thay thế. **Chưa xác nhận** cách tương tác (mình nhớ là đi tới và bấm 1 nút) | [S] liệt kê khu; [M] cách tương tác |
| Cult of the Lamb (hub) | Lời chê: lưới đặt đồ khó chịu, menu nâng cấp bố cục chưa rõ, base có lúc giống "quản lý khách sạn"; lời khen: cấu trúc quản lý minh bạch. Bài học: hub 3D không được biến thành việc vặt | [S] |
| Marvel Snap | Pass kiểu "interleaved" (free track làm quảng cáo cho premium). **Sửa review:** bản trước ghi "không khóa thẻ sau paywall" là sai. Thẻ mới của mùa thường nằm ở track Premium (Thor 7/2022, Black Panther 11/2022, Ghost-Spider 6/2023 đều vậy); người không trả tiền thường phải đợi thẻ vào pool sau | [S] pass; UI shop [?] |
| Clash Royale | Pass Royale 2.0 (2023) làm doanh thu tăng 41% so với tháng trước rồi tụt nhanh; người dùng hoạt động xuống thấp nhất từ 9/2021. Report cho rằng một phần do pass đắt hơn mà giá trị thấp hơn, phần thưởng nâng cấp bị đẩy sang IAP. Nguồn là Liquid & Grit, **không phải** Deconstructor of Fun như bản trước ghi (sửa review) | [S] |
| Hero battler mobile (AFK Journey, Epic Seven, Honkai Star Rail) | Không tìm được nguồn về bố cục "lưng quay camera vs quái quay mặt". AFK Journey là top-down grid, power gauge đầy thì chạm icon rồi chọn chỗ. Star Rail: thứ tự lượt nằm **bên trái** màn hình [S]; ultimate dùng bằng cách chạm chân dung nhân vật, basic/skill là nút góc phải dưới, auto và x2 góc phải trên [M] (sửa review: bản trước ghi "chạm chân dung để dùng skill", search không xác nhận). Epic Seven: thanh turn order, HP quái trên đầu, buff boss ở trên cùng | [S]/[M] như ghi |

Điều thật sự rút ra, gom lại:

1. **Intent/kết quả báo trước** là thứ mọi game thành công cùng thể loại làm (STS2, Monster Train, Shroom and Gloom).
   Axie Dice đã có nguyên tắc "minh bạch triệt để" nên phải giữ.
2. **Thứ đang được chọn phải to nhất và nằm gần chuột** (Dicey Dungeons [S]; còn Star Rail chỉ là [M]).
3. **Feedback nhiều lớp khi resolve** (Balatro) mới là thứ làm game "sướng", không phải khung đẹp.
4. **Hub không được thành chỗ làm việc vặt** (Cult of the Lamb) [S].
5. **Monetization** (sửa review): hướng đã chốt là bán giải pháp cho ức chế trong run. Bài học từ Clash Royale không phải
   "đừng bán sức mạnh" mà là: người chơi phản ứng khi giá trị **giảm** so với cái họ đã quen. Với Axie Dice, nghĩa là
   ức chế phải công bằng, đọc được trước, có cách vượt miễn phí, và trần/giá không được lặng lẽ đổi xấu đi.
   Marvel Snap cho thấy ngay cả game "nhẹ tay" vẫn khóa thứ mới sau premium; điểm khác là nó nói rõ từ đầu.

## 2. Khu vực 1: Menu / Meta hub (Land 3D thay main menu)

### 2.1 Game tốt làm gì

- Hades: hub là một không gian, mỗi chức năng gắn với một nhân vật/vật thể ở đúng chỗ, chạy lại là hết run
  → vào run lại rất nhanh. [S+M]
- Cult of the Lamb: cho thấy rủi ro ngược lại, hub phải có việc tự động/ít việc, nếu bắt người chơi làm lặp thì thành gánh nặng. [S]
- Marvel Snap / Clash Royale: menu chính là 1 thanh tab dưới + nút "Play" cực to; shop, pass, nhiệm vụ nằm trong tab. [M]
  Con số tap: vào trận phải ≤ 2 tap từ lúc mở game. Điểm này mình không có nguồn, là quy ước thường thấy.
- Pass/Shop: dùng chấm đỏ (badge) chỉ chỗ có việc. [M]

### 2.2 Hợp / không hợp Axie Dice

Hợp:
- Nhà là cửa vào, Echo Box, Pass, Nhiệm vụ, Vault, Store: giống bố cục theo chức năng của Hades.
- Một nút "Bắt đầu run" luôn nhìn thấy, ở chỗ cố định.

Không hợp / rủi ro:
- Đi bộ 3D để tới cửa hàng mỗi lần sẽ chậm với người chơi lâu năm. Cần cách nhảy thẳng (menu nhanh).
- Bàn phím: hub 3D phải điều hướng được bằng focus giữa các nhà, không chỉ bằng chuột. (Gamepad chưa trong phạm vi.)
- Web: camera hub 3D nặng (spike Land: chế độ Compatibility chậm ~10×); cần mức "Land tĩnh" fallback cho web.
- Nhiệm vụ rủi ro cao và gacha nằm cùng chỗ với nút Play → dễ làm người chơi thấy hub là chợ. Cần phân cấp.

### 2.3 Hướng đề xuất

**A. Land là menu, có thanh lối tắt (khuyên dùng).**
Camera cố định kiểu diorama, nhìn xuống Land, Axie vẫn đi lại trong cảnh. Mỗi nhà là 1 nút lớn có nhãn và badge. Nút "Run" to nhất ở trung tâm (cổng Portal). Bên dưới hoặc bên cạnh luôn có thanh icon lối tắt tới cùng các chỗ đó cho bàn phím/người vội.
- Ưu: không phải đi bộ; hợp mọi input; tạo cảm giác "thế giới" mà không bắt làm việc vặt; dễ dựng Land tĩnh cho web.
- Nhược: ít "nhập vai" hơn hub tự đi; cần kỹ thuật chọn nhà bằng focus.

**B. Hub đi bộ kiểu Hades (người chơi điều khiển một Axie).**
- Ưu: nhập vai.
- Nhược: chậm, tốn dev (di chuyển, va chạm, camera), làm người chơi cũ bực. Cult of the Lamb cảnh báo về việc vặt. [S]
- Chỉ nên làm sau, khi B bổ sung cho A, không thay.

~~**C. Menu phẳng đẹp + Land chỉ làm nền động.**~~ (sửa review) Bỏ: trái với quyết định "màn chính là Land 3D, nhà là lối vào".

**Khuyên: A**, với B là phần mở rộng sau. Người chơi chọn nhà bằng click/focus, camera lia mượt tới cửa nhà đó rồi mở panel.
Gợi ý thêm (creative-director): nút Run là **chính cổng `SM_Portal_01`** đặt giữa Land, cùng cổng dùng khi qua ải trong combat.
Một vật thể cho một ý nghĩa ("đi qua cổng = vào trận tiếp") nên người chơi học một lần là hiểu.

### 2.4 Chi tiết cần chốt cho hub (không phải quyết định, là danh sách)

- Phân cấp: Run (to nhất) > Nhiệm vụ / Pass / Echo Box (vừa) > Vault / Store / Cài đặt (nhỏ).
- Badge chỉ khi có việc thật (thưởng chờ nhận, lượt Echo Box miễn phí). Thời hạn mùa hiện dạng ngày ("còn 12 ngày"),
  **không** đồng hồ đếm giây (sửa review: bản trước ghi "badge và đếm ngược", trái rào "không đếm ngược ép").
- Echo Box và Store: không để cạnh nút Run; không hiện popup bán hàng khi vừa mở game. **Lưu ý:** `monetization-v1.md` T3
  ghi VIP được chào "lần đăng nhập ngày thứ 2". Hai điều này cần khớp nhau, xem §5 câu 4.
- Tài khoản / currency: một thanh trên cùng nhất quán, trùng chỗ ở mọi màn.

## 3. Khu vực 2: Run flow (map, reward, shop, event, rest, result/defeat)

### 3.1 Game tốt làm gì

- **Map** (StS1/2): một màn hình = một quyết định; đường nối rõ; legend; hover legend highlight mọi node loại đó; thanh trên hiện HP, tiền. [S cho STS2, M cho STS1]
  Mod "Route Suggest" gợi ý đường an toàn / mạo hiểm tồn tại cho thấy người chơi muốn thêm hướng dẫn đường đi. [S]
- **Shroom and Gloom**: map cầm trên tay, trong cảnh. [S] Hướng rất hợp tinh thần "bạn ở trong thế giới" nhưng ép góc nhìn thứ nhất, Axie Dice không có.
- **Reward pick**: 3 lựa chọn lớn cạnh nhau, có nút Skip rõ, thẻ to đủ đọc ở khoảng cách. [M]
- **Shop**: Monster Train 2 gọn lại shop UI so với bản đầu [S]; điểm chung của shop tốt là giá nằm sát món đồ, món mua không nổi thì mờ chứ không ẩn. [M]
- **Event**: 1 tranh + 1 đoạn chữ ngắn + 2-4 nút lựa chọn, kết quả nói trước rủi ro (kiểu STS). [M]
- **Rest**: ít lựa chọn (nghỉ / nâng cấp), phải to, ít chữ. [M]
- **Result/Defeat**: tóm tắt run (thống kê), phần thưởng meta nhận được, 1 nút "Chạy lại" cực to; defeat không đổ lỗi. [M]

### 3.2 Hợp / không hợp Axie Dice

Hợp:
- Giữ khung "1 màn hình, 1 quyết định" và chữ ngắn.
- Đặt bối cảnh run flow **trong cùng thế giới 3D** của combat: Axie đứng ở cảnh thay vì nền phẳng.
- Cho phép xem lại đội (5 Axie, dice, relic) từ mọi màn.

Aid trả tiền (sửa review: phần này đã có quyết định, mockup chỉ cần làm đúng, không cần Liam chọn lại):
- Chỗ chào và trần lấy nguyên từ `monetization-v1.md` §2.1–§2.2: Continue (R1) ở màn thua trận kèm recap; reroll thêm (R2)
  khi hết reroll; hoãn đồng hồ (R4) khi enrage còn ≤ 2 lượt và ở màn intro boss; Scout (R7) ở map; làm mới shop (R6) ở
  cổng shop; R5 ở màn pact; Kit/Boon (R8/R9) ở màn chọn đội. Trần tổng 8/run (A10: 4).
- Continue dạng B: đội hồi **40%** HP, địch giữ HP và phase, enrage/attrition về 0 (bản trước ghi ví dụ "50%", sai).
- Rào UI: không đếm ngược, không popup chặn, chào 1 lần mỗi khoảnh khắc, nút từ chối ngang kích thước; mọi Aid trong
  **một khay riêng, cách xa END TURN**; lần đầu mỗi phiên phải xác nhận, hiện giá Gem kèm ≈ USD; có tùy chọn "tắt gợi ý Aid".
- VIP **không bao giờ** chào ở màn thua. 5 run đầu của tài khoản (giai đoạn làm quen) ẩn mọi chào Aid trả phí, trừ Continue miễn phí mẫu.
- Lằn ranh pháp lý/đạo đức đã chốt (pháp lý Sky Mavis duyệt 12/10), không còn là câu hỏi.

Cẩn thận:
- Map che node xa: đã chốt 18/9, mockup làm theo §5.4 của `combat-screen-shroom-gloom-inspired.md` (node 2+ hàng: mờ + "?").

### 3.3 Hướng đề xuất

**A. Map 3D đường đi trong Land/thế giới.**
Map là một con đường/đồ họa dạng diorama, node là các điểm trên đường, Axie là token/nhóm nhỏ đi dọc. Khi chọn node thì chuyển cảnh vào combat/shop/event. Giữ thanh trên cùng: HP, tiền, Shard, boss clock nếu có.
- Ưu: nhất quán với combat 3D.
- Nhược: tốn art; khó giữ icon loại node, fog "?" và legend đọc được khi nhỏ. Spec map hiện hành là RunMap trong
  `combat-screen-shroom-gloom-inspired.md` §5.4 (sửa review: `world-tour-map.md` là spec màn World Tour của bản JS cũ, không phải run map).

**B. Map 2D sơn lại theo Homeland, mở như tấm bản đồ đè lên sân 3D.**
- Ưu: rẻ, đọc rất rõ, có legend, fog và Scout làm dễ; mượn ý "bản đồ cầm tay" của Shroom and Gloom mà không cần góc nhìn thứ nhất.
- Nhược: ít "3D" hơn.

**C. Màn tĩnh dạng thẻ bài (reward/shop/event/rest dùng chung 1 khung 3D, chỉ đổi panel).**
Áp dụng cho reward/shop/event/rest, không cho map: nền là sân 3D với đội Axie đứng lưng quay camera, panel nổi lên ở nửa trên/giữa.
- Ưu: 1 bộ component dùng lại, rẻ, nhất quán, nhìn đội luôn thấy.
- Nhược: nếu panel quá to thì che cảnh; phải thiết kế vùng an toàn.

**Khuyên (sửa review): map = B cho bản đầu, A để sau; reward/shop/event/rest = C.** Result/defeat = C + khung recap,
Continue đặt cạnh nút chính, không đè lên nó.

### 3.4 Kích thước và số tap tham chiếu (đề xuất, chưa có nguồn đo)

- Reward: ≤ 1 tap để chọn, 1 tap để skip.
- Shop: 1 tap xem, 1 tap xác nhận mua.
- Rest: 1 tap.
- Defeat → chạy lại: ≤ 2 tap.

## 4. Khu vực 3: Combat HUD trên cảnh 3D của Liam

Bố cục Liam đã chốt: 5 Axie nửa dưới, quay lưng; quái/boss nửa trên, quay mặt; môi trường rộng, thoáng; khay xúc xắc
ở đáy, mỗi viên thẳng hàng với Axie của nó.

### 4.1 Game tốt làm gì

- **Intent** (STS2, S&G, Monster Train): icon + số trên đầu quái; nhiều hành động xếp ngang; luôn hiện số. [S]
- **Tính trước kết quả** (Monster Train): đánh dấu ai sẽ chết trước khi commit. [S] Game đã có damage preview khi hover;
  bước nâng cấp đáng làm là thêm dấu "sẽ chết / còn X HP".
- **Chọn và thả** (Dicey Dungeons): slot lớn, có quy tắc hợp lệ hiện rõ. [S]
- **Hero battler**: HP quái ngay trên đầu, boss + buff ở thanh trên cùng (Epic Seven) [S]; thứ tự lượt là thanh riêng (Star Rail bên trái) [S]. Không tìm được nguồn về composition "lưng quay camera", nên phần đó mình suy luận (xem 4.3).
- **Balatro**: feedback nhiều lớp khi resolve; không che con số quan trọng bằng hiệu ứng. [S]

### 4.2 Hợp / không hợp Axie Dice

Hợp:
- Dice là vật chính: to, dễ đọc, mặt có số lớn và icon part.
- Intent trên đầu quái giữ nguyên.
- Số damage dự kiến khi hover (đã có).

Không hợp:
- HP bar nổi trên đầu 5 Axie: lưng quay camera, nhìn từ sau thì đầu Axie ở giữa màn hình, HP trên đầu dễ chồng lên quái phía sau. Nên đặt HP/status của đội **ở khay đáy**, cùng cột với dice (xem §5 câu 8).
- Nhiều text nhỏ ở cảnh rộng, thoáng: "airy" nghĩa là ít thứ chen chúc, nên HUD phải gọn.
- Quái ở nửa trên xa camera: HP/intent/status của quái phải scale để vẫn đọc được ở nhỏ nhất.

### 4.3 Nối Axie ↔ dice: đã chốt (sửa review)

Liam đã chọn: khay dưới đáy, mỗi viên thẳng hàng với Axie của nó. Đây gần như hướng A bên dưới (cột-Axie), không phải khay
chung tách rời. Hai hướng B, C dưới đây giữ lại để tham khảo, không còn là lựa chọn.

### 4.4 Hướng (giữ để tham khảo)

**A. Cột-Axie: khay đáy chia 5 cột, mỗi cột = dice + HP + status, thẳng dưới Axie (khớp quyết định Liam).**
- Ưu: mỗi cột là 1 đơn vị, khớp mental model "5 Axie, mỗi con 1 dice"; HP + status + dice ở cùng chỗ nên không phải nhìn lên xuống; Fitts's Law tốt.
- Nhược: 5 cột rộng; khi Axie chết thì cột đó phải có trạng thái rõ.

**B. Khay dice chung ở đáy + thanh HP đội mỏng.** Không chọn.

**C. Tất cả nổi trong cảnh 3D (world-space HUD).** Không chọn cho thông tin; chỉ dùng cho hiệu ứng (dice lăn trong cảnh rồi đậu vào khay là chi tiết juice, quyết sau mockup).

### 4.5 Phần tử HUD bắt buộc phải có trong mockup (sửa review: bản trước thiếu)

Theo luật "nhìn thấy trước" (`monetization-v1.md` §1.5 mục 5, `ascension-v2.md` §2.4): thiếu cái nào thì công cụ tương ứng
không được bật, nên mockup combat phải có đủ:
- Bộ đếm enrage trên nameplate boss ("Enrage in N" → "Enrage ×1.4").
- Bộ đếm spike (lượt "đòn lớn") trên quái/elite/boss.
- Vạch phase 66%/33% trên thanh HP boss.
- Bộ đếm attrition ở góc trận.
- **Một số dmg gộp duy nhất** trên địch cho lượt sau (đã gộp enrage + attrition + spike).
- Khay Aid riêng, cách xa END TURN.
- Màn thua có recap (lượt nào chết, đòn nào, boss còn bao nhiêu HP) + Continue.
- Các chỉ báo Ascension trong `design/requests/ascension-ui-request-01.md` (sticker Eternal, Axie bị weaken báo trước, pact bắt buộc...).

### 4.6 Phản hồi (juice) nên có

- Chọn dice: dice nhấc lên, viền sáng, các target hợp lệ nổi lên, target không hợp lệ mờ + lý do (không chỉ bằng màu).
- Hover target: hiện số dự kiến, và "sẽ chết" nếu đủ.
- Thực thi: camera nhẹ, hit-stop ngắn, số bay lên, counter đếm; có nút bỏ qua/nhanh.
- Chiến thắng: Axie chạy xuyên chỗ quái đứng, cổng mở, chuyển cảnh (Liam đã chốt). Nên cho bỏ qua sau lần đầu (polish, không chặn mockup).
- Aid: nằm trong khay Aid, không che dice.

### 4.7 Accessibility (phải qua mọi hướng)

- Không chỉ dùng màu: HP-theo-faction vẫn là nợ P0-3 chưa quyết (xem memory dự án).
- Bàn phím: focus đi theo thứ tự cột Axie → dice → target (bản Godot chưa thấy phím tắt 1–5 chọn dice như bản JS cũ; nên thêm).
- Chữ nhỏ nhất, scale UI; khay đáy neo theo cạnh màn hình, không neo theo cảnh.
- Hiệu ứng flash có tùy chọn tắt (đã có toggle).
- 3D che khuất: không cho đồ trang trí môi trường che intent/HP quái.

## 5. Câu hỏi Liam cần trả lời trước khi viết Claude Design prompt

(sửa review) Bản trước có 16 câu. Đã bỏ những câu đã có quyết định:
nền tảng (cũ 3), che node xa (cũ 8b), Aid (cũ 10), boss clock (cũ 11), vị trí dice (cũ 12), damage preview (cũ 16) — xem §0.1.
Bỏ khỏi danh sách chặn mockup vì là chi tiết juice/polish, quyết sau: dice lăn trong cảnh (cũ 14), bỏ qua cảnh qua cổng (cũ 15).
Câu "game nào bạn thích/ghét UI" (cũ 2) không bắt buộc; Liam có ảnh tham chiếu thì gửi kèm.
Gộp: cũ 1 + 4 → câu 2; cũ 5 + 6 → câu 3.

1. **Mockup mới thay hay mở rộng bộ v2?** Bộ `mockups-v2/` (combat-v2, run-flow-v2, meta-screens-v2) và
   `ascension-ui-request-01.md` (chưa giao) đều theo layout 2D cũ.
   Khuyên: combat + run flow vẽ mới theo hướng 3D; gộp nội dung request Ascension vào prompt mới thay vì gửi riêng;
   các panel trong nhà (Vault, Pass, Codex...) giữ meta-screens-v2 làm nền.
2. **Tông khung UI:** UI theo Homeland (mềm, ấm, viền đậm ở cỡ nhỏ như cosmetics) hay có tông riêng gọn hơn?
   Khuyên: theo Homeland, viền đậm ở cỡ nhỏ; HUD combat tối giản để sân 3D thở.
3. **Hub:** click thẳng vào nhà với camera cố định (A) hay điều khiển một Axie đi tới nhà (B)? Nút Run đặt ở đâu?
   Khuyên: A, nút Run là cổng Portal giữa Land, thêm thanh lối tắt cố định cho bàn phím.
4. **Chào VIP lúc đăng nhập ngày 2** (`monetization-v1.md` T3): popup, hay chỉ banner/badge trên nhà Store?
   Khuyên: không popup, chỉ banner trong nhà Store + badge trên nhà.
5. **Thứ tự sau khi thắng trận:** khuyên thắng → chọn thưởng (panel trên sân đã trống) → map → chọn node → đội chạy vào
   cổng → loé → cảnh node mới. Đồng ý không?
6. **Map:** 2D sơn Homeland mở như tấm bản đồ đè lên sân (B), hay map 3D diorama (A)? Khuyên: B cho bản đầu.
7. **Reward/shop/event/rest** dùng chung một khung (đội đứng trong sân + panel), hay mỗi loại một màn riêng? Khuyên: dùng chung.
8. **HP và status của Axie:** trong khay đáy cùng cột với dice, hay nổi trên đầu Axie? Khuyên: trong khay đáy.

## 6. Nguồn (search 12/10/2026)

- Shroom and Gloom: https://teamlazerbeam.itch.io/shroom-and-gloom , https://www.gameinformer.com/2025/05/14/devolver-digital-announces-shroom-and-gloom-a-first-person-double-deckbuilder-roguelike , https://www.thesixthaxis.com/2026/09/10/shroom-and-gloom-early-access-review-this-fungus-packs-a-punch/ , https://www.nag.co.za/2025/05/16/first-impressions-shroom-and-gloom-demo/ , https://www.mkaugaming.com/all-review-list/shroom-and-gloom-steam-early-access-preview/ , https://www.gematsu.com/2026/08/shroom-and-gloom-launches-in-early-access-on-september-10 , https://finalboss.io/shroom-and-gloom-how-to-survive-early-runs-deck-and-upgrade-guide
- Balatro: https://gmtk.substack.com/p/balatros-cursed-design-problem , https://gameindustrylibrary.com/documents/gmtk-balatros-cursed-design-problem/insights , https://blakecrosley.com/es/guides/design/balatro
- Slay the Spire 2: https://sts2.untapped.gg/guides/how-to-read-enemy-intent , https://bossrush.net/2026/04/slay-the-spire-2-early-access-review/ , https://sts2.untapped.gg/en/guides/how-to-make-the-best-map-choices-in-slay-the-spire-2 , https://sts2.gg/mods/mod-54
- Dicey Dungeons: https://mechanicsofmagic.com/2021/04/19/visual-design-of-games-8/
- Monster Train 2: https://pcgamer.com/games/roguelike/monster-train-2-review , https://blog.lauramichet.com/monster-train-2/ , https://fullcleared.com/reviews/monster-train-2-review/
- Hades hub: https://www.pushsquare.com/guides/hades-guide-how-to-play-and-everything-you-need-to-know , https://primagames.com/gaming/hades-guide-house-of-hades-house-contractor-upgrades/2
- Cult of the Lamb: https://indiecator.org/2022/09/08/cult-of-the-lamb-is-good-but/ , https://game-wisdom.com/analysis/cult-of-the-lamb
- Marvel Snap: https://www.pocketgamer.biz/comment-and-opinion/80204/is-marvel-snaps-laid-back-monetization-working/ , https://gmdq.substack.com/p/marvel-snaps-interleaved-season-pass , https://blizzardwatch.com/2022/07/07/marvel-snap-season-2/ , https://marvelsnapzone.com/november-2023-season/
- Clash Royale: https://www.liquidandgrit.com/may-2023-core-report/ (Pass Royale 2.0, +41%). Link Deconstructor of Fun 2020 bản trước dẫn là bài về Pass Royale bản đầu, không đỡ được claim 2.0.
- Hero battlers: https://www.pocketgamer.com/afk-journey/combat-guide , https://gamepress.gg/epicseven/node/6651 , https://www.ludo.guide/guide/honkai-star-rail-2026-updates/getting-started/basic-controls-ui/touch-controls-overview , https://www.icy-veins.com/honkai-star-rail/combat-basics
- Backpack Battles: https://en.wikipedia.org/wiki/Backpack_Battles , https://vaporlens.app/app/2427700/backpack_battles.md

Không tìm được / chưa xác minh: UI chi tiết của Hades hub, composition lưng-quay-camera của hero battler mobile,
UI shop của Marvel Snap / Clash Royale, bất kỳ postmortem UI nào của dice roguelike cụ thể, STS2 map so với STS1,
cách dùng skill/ultimate của Star Rail, tỉ lệ review tuần đầu của Shroom and Gloom.
Nên có người mở thẳng game và chụp màn hình trước khi mockup dựa vào các điểm này.
