# Vòng lặp ngoài trận (Event / Shop / Treasure / Post-combat Reward / Result) — UX Backlog

**Ngày**: 2026-09-19
**Phạm vi**: các màn hình do `godot/scenes/run_map/RunMapController.gd` dựng (event, shop,
treasure, post-combat reward) + `godot/scenes/result/ResultView.gd` (Victory/Defeat).
**Không phạm vi**: hoạt hình/màu sắc/asset (→ `art-director`), luật chơi/balance (→ `game-designer`
— các mục có yếu tố này được ghi rõ riêng bên dưới), nút thiếu hover/pressed (đã fix), phản hồi
ô xúc xắc/node bản đồ (cố ý chưa làm).
**Phương pháp**: đọc 8 ảnh chụp màn hình thật + đối chiếu code (`RunMapController.gd`,
`reward_generator.gd`, `ResultView.gd`, `ContentDB.gd`, `DangoTheme.gd`) để xác nhận từng vấn đề
là thật, không suy đoán từ ảnh không.

---

## P0 — Người chơi chọn sai vì UI

### P0-1. Shop: nút "đã mua" và "không đủ tiền" DÙNG CHUNG một style disabled — không phân biệt được
**Màn**: Shop (`05_shop_open.png` → `06_shop_after_buy.png`)
**Bằng chứng cụ thể**: Sau khi mua Lunacia Ultima (200 → 20 Gene Shard), 3 item còn lại
(Bloomscale 75, Serum 40, Instinct 110) đều vượt quá 20 Shard hiện có — TẤT CẢ 4 nút giờ trông
**y hệt nhau về màu/độ mờ** (chỉ khác chữ "BOUGHT" vs "BUY (n)"). Xác nhận trong code:
`RunMapController.gd:824-827` — `bought or not afford` gộp chung thành **một** boolean
`button_disabled`, và `DangoTheme.gd` chỉ có 1 stylebox `DISABLED` cho mọi lý do disable
(`style_button()` gọi `..._button_style(warning, ButtonState.DISABLED)`, không có tham số phân
biệt "sở hữu rồi" với "chưa đủ tiền").
**Vì sao là P0**: hai trạng thái có ý nghĩa khác hẳn nhau cho quyết định tiếp theo của người chơi
— "đã mua, đừng bấm nữa" (vĩnh viễn) vs "chưa đủ tiền, có thể quay lại mua sau nếu kiếm thêm
Shard" (tạm thời) — nhưng chỉ phân biệt được bằng cách ĐỌC CHỮ nhỏ trong nút, không phải bằng
mắt lướt nhanh. Người chơi quét nhanh dễ kết luận nhầm "shop hết hàng"/"shop lỗi".
**Sửa thế nào**: tách 2 trạng thái — "BOUGHT" nên giữ độ sáng bình thường + icon dấu tick (không
mờ đi, vì đây là kết quả THÀNH CÔNG chứ không phải bị khoá), chỉ "không đủ tiền" mới dùng style
mờ/disabled hiện tại. Cần 1 tham số mới trong `_add_card()`/`style_button()` (ví dụ
`ButtonState.OWNED` khác `ButtonState.DISABLED`) — màu cụ thể cần art-director duyệt, logic thuộc
ui-programmer.
**Công sức**: S–M (thêm 1 state, sửa 1 điểm gọi trong `_render_shop()`).

### P0-2. Event / Shop / Reward / Treasure: MỌI lựa chọn dùng chung 1 khung thẻ, không phân biệt độ hiếm/mức tác động
**Màn**: cả 4 màn (`02_event_prompt`, `05_shop_open`, `08_treasure_reveal`, `10_post_combat_reward`)
**Bằng chứng cụ thể**:
- Shop: "Serum" (buff nhỏ, +10 Max HP một Axie, 40 Shard) và "Lunacia Ultima" (skill chủ động
  gây 40 dmg xuyên giáp + khiên cả đội, 180 Shard) và "Bloomscale" (relic đổi LUẬT vĩnh viễn cho
  cả run, 75 Shard) — cả ba hiện y hệt nhau: cùng màu tiêu đề cam, cùng cỡ chữ, cùng khung, chỉ
  khác số trong nút bấm.
- Lunacia Shrine (event): "Accept the blessing" (thuần lợi, không đánh đổi), "Make the wager"
  (đánh đổi rủi ro cao: mất 20% Max HP cả đội đổi lấy 1 relic Legendary ẩn danh), "Pray" (lợi vừa,
  không rủi ro) — ba loại quyết định có BẢN CHẤT khác nhau (an toàn / gamble / trung tính) nhưng
  trình bày giống hệt nhau.
- Đối chiếu code: `RunMapController.gd:656-697` (`_add_card`) style tiêu đề luôn
  `DangoTheme.PRIMARY`, cỡ 18, không đọc field `rar` (rarity) mà `reward_generator.gd` **đã có
  sẵn** trong data (`"rar": 0..4`, xem `_make_reward()`/`_make_level_reward()`/`_make_curse_reward()`
  v.v.). Bằng chứng là màn Result (`ResultView.gd:194-215`) ĐÃ CÓ badge rarity màu
  ("Epic"/"Rare"...) — component này tồn tại nhưng bị bỏ quên đúng ở màn hình mà nó cần nhất: lúc
  ra quyết định.
**Vì sao là P0**: đây không phải polish — người chơi phải đọc hết từng dòng chữ mới biết được
"độ nặng" của lựa chọn; lướt nhanh (hành vi tự nhiên khi đã quen game) rất dễ đánh giá thấp một
lựa chọn ăn tiền lớn/relic hiếm, hoặc coi nhẹ một cú đánh đổi rủi ro cao vì nó "trông giống" một
lựa chọn an toàn bên cạnh.
**Sửa thế nào**: tái sử dụng chip rarity đã có ở Result, gắn vào mỗi thẻ trong `_add_card()`
(dùng field `rar` sẵn có trong dict reward/shop-item — chỉ thiếu cho event option, cần bổ sung).
Cân nhắc thêm icon loại (relic/skill/stat-buff/gamble) — đây có thể cần input từ game-designer về
phân loại, nhưng riêng việc hiển thị rarity là thuần UX, không đổi luật.
**Công sức**: M (sửa 1 hàm dùng chung cho cả 4 màn — ROI cao vì 1 lần sửa ảnh hưởng toàn bộ vòng
lặp ngoài trận).

### P0-3. Reward "LEVEL UP": mũi tên "X -> X" đọc như lỗi, và không cho xem trước cái sắp thay đổi
**Màn**: Treasure (`08`) và Post-combat reward (`10`) — cả hai đều roll ra "Pomodoro -> Pomodoro"
**Bằng chứng cụ thể**: `reward_generator.gd:205-207` — `"desc": "%s -> %s" % [_hero_name(picked),
String(next_def.get("n", next_key))]`. Đối chiếu `ContentDB.gd:208,251,255`: hero tier 1/2/3 của
dòng "bug" ĐỀU tên "Pomodoro" — xác nhận đây **không phải bug dữ liệu**, mà là thiết kế có chủ ý
(hero không đổi tên khi lên tier, chỉ đổi mặt xúc xắc + Max HP). Vấn đề nằm ở CÁCH TRÌNH BÀY: dấu
mũi tên `->` là ký hiệu quy ước cho "biến đổi", nhưng khi hai vế giống hệt nhau, người chơi đọc
thành "không có gì thay đổi" / "chắc là lỗi hiển thị". Thêm nữa, dòng phụ "Rewrites all six faces
and Max HP" không cho xem TRƯỚC bất kỳ mặt xúc xắc mới nào — đây là quyết định build quan trọng
nhất trong một roguelike xúc xắc, mà lại là thẻ mù mờ nhất trong toàn bộ vòng lặp.
**Sửa thế nào**:
1. (S) Đổi cách viết thành thể hiện TIER thay vì tên: ví dụ "Pomodoro — Tier 1 → Tier 2" để mũi
   tên gắn với thứ THỰC SỰ đổi (tier), không phải tên (thứ không đổi).
2. (M) Thêm preview 6 mặt mới cạnh 6 mặt cũ (dữ liệu đã có sẵn ở
   `ContentDB.heroes[next_key]`/faces — chỉ cần lấy ra và hiển thị, không cần data mới).
**Công sức**: S cho bước 1 (làm ngay, rẻ), M cho bước 2 (giá trị cao hơn nhưng cần thêm UI diff).

---

## P1 — Người chơi phải đoán

### P1-1. Result: "Power level reached" và "Nodes visited" đặt cùng nhóm nhưng có thể đọc mâu thuẫn
**Màn**: Result — Defeat (`2026-09-19_result-daily.png`)
**Bằng chứng cụ thể**: "Power level reached: 7 · Nodes visited: 0" xuất hiện cùng dòng dưới header
PROGRESS. Với người chơi, "power level 7" nghe như đã tiến khá xa, nhưng "nodes visited: 0" nghe
như chưa đi được bước nào — hai con số đo hai thứ khác nhau (power level tính theo tiến trình
trong TRẬN đang đánh, node visited chỉ tính khi hoàn thành cả node) nhưng không có chú thích nào
giải thích sự khác biệt này ngay tại chỗ.
**Sửa thế nào**: thêm 1 dòng phụ giải thích ngắn, hoặc tách "Power level" ra khỏi việc trông giống
một chỉ số "đường đi trên bản đồ" (đổi nhãn cho rõ ý nghĩa, ví dụ ghi chú "(trong trận vừa thua)"
cạnh Power level khi Nodes visited = 0).
**Công sức**: S.

### P1-2. Result: thứ tự đọc đặt số liệu tiền tệ/XP (meta) trước bản build đặc trưng của run (relic)
**Màn**: Result — cả Victory và Defeat
**Bằng chứng cụ thể**: Thứ tự hiện tại (từ `ResultView.gd` build order, khớp với cả 2 ảnh):
RUN → PROGRESS → GENE SHARD → LUNACIA PASS → **RELICS COLLECTED** → YOUR PARTY. Hai khối đầu
(Gene Shard, Lunacia Pass) là số liệu meta-currency có ở MỌI run, không đặc trưng cho ván vừa
chơi; khối "RELICS COLLECTED" — thứ thực sự kể câu chuyện "mình đã build gì trong run này" — lại
nằm gần cuối, sau khi mắt đã lướt qua 2 khối số liệu ít ý nghĩa hơn.
**Sửa thế nào**: đổi thứ tự — OUTCOME → RELICS COLLECTED (build recap, đáng nhớ nhất) → PROGRESS
→ GENE SHARD/LUNACIA PASS (currency) → PARTY. Đây thuần là quyết định về THỨ TỰ (information
architecture), không đụng màu/font — có thể làm độc lập với art-director.
**Công sức**: S (đổi thứ tự các block đã dựng sẵn trong `_build_ui()`).

### P1-3. Result: xác nhận CÓ THẬT lỗ hổng thiếu dmg/turns/kills/biggest-hit — đây KHÔNG phải chuyện nhỏ
**Màn**: Result — đặc biệt màn Defeat
**Xác nhận**: đã đọc `ResultView.gd:12-21` — comment trong code đã tự nhận: các số liệu này
"genuinely untracked at run level", không tồn tại ở đâu để đọc ra (không phải chuyện quên hiển
thị, mà là dữ liệu chưa từng được cộng dồn).
**Đánh giá mức độ nghiêm trọng**: **CÓ THẬT và ĐÁNG KỂ**, không phải chuyện nhỏ — lý do: đây là
roguelike, vòng lặp học hỏi cốt lõi của thể loại là "vì sao lần này thua, lần sau đổi gì". Màn
Defeat hiện tại chỉ trả lời "bạn kiếm được bao nhiêu Shard/XP" (câu hỏi về kinh tế) chứ không trả
lời được "trận đấu diễn ra thế nào" (câu hỏi về kỹ năng/chiến thuật) — hai câu hỏi hoàn toàn khác
nhau, và câu thứ hai mới là câu người thua thực sự muốn biết. Thiếu nó, màn Defeat chỉ còn tác
dụng thông báo, không có tác dụng dạy.
**Sửa thế nào**: đây KHÔNG phải lỗi UI thuần — phần thu thập số liệu (dmg dealt/taken, turns,
kills, biggest hit cộng dồn ở cấp run) là việc của `gameplay-programmer` (CombatEngine cần expose
các counter này ra RunState). Phần hiển thị (thêm khối "COMBAT" trước RELICS) chỉ làm được sau khi
data tồn tại — thuộc về ux-designer/ui-programmer, đã có vị trí gợi ý ở P1-2.
**Công sức**: L tổng thể (chủ yếu nằm ở phần data, không phải phần hiển thị) — **cần bàn giao cho
gameplay-programmer trước**.

### P1-4. Shop/Event: thuật ngữ luật chơi (face-slot, keyword) xuất hiện trần trụi, không có tra cứu
**Màn**: Shop (`05`), Event (`02`)
**Bằng chứng cụ thể**: mô tả "Bloomscale" — "RULE: every Back and Eyes face gains Growth, and
Growth faces grow by 4 instead of 1." — dùng liền 3 thuật ngữ hệ thống (Back/Eyes = vị trí mặt
xúc xắc, Growth = tên keyword) không giải thích. Đối chiếu code: hệ thống keyword chip/tooltip ĐÃ
TỒN TẠI ở Combat (`godot/scenes/combat/CombatView.gd`, `Combat.tscn`, `DangoTheme.gd`) nhưng
`RunMapController.gd` (nơi dựng event/shop/treasure/reward) không gọi tới nó ở đâu cả. Nghĩa là
người chơi có thể gặp thuật ngữ này LẦN ĐẦU ở màn Shop — TRƯỚC KHI vào trận — mà không có cách
tra cứu nào.
**Sửa thế nào**: tái dùng component tooltip/keyword-chip đã có ở Combat, áp cho phần mô tả trong
`_add_card()`.
**Công sức**: M.

### P1-5. Lunacia Shrine — "Make the wager" giấu tên relic Legendary trong khi 2 lựa chọn kia nói rõ hiệu ứng
**Màn**: Event (`02_event_prompt.png`)
**Quan sát**: "Accept the blessing" và "Pray" đều ghi rõ chính xác hiệu ứng số. "Make the wager"
chỉ ghi "Receive a Legendary relic" — không nói relic nào, để ngỏ hoàn toàn.
**Cần làm rõ trước khi sửa**: nếu đây là chủ ý thiết kế (yếu tố bất ngờ/gamble của một "wager"),
đây KHÔNG phải lỗi UX — chỉ cần thêm 1 chữ nhỏ kiểu "(ngẫu nhiên)" để người chơi hiểu đây là bí ẩn
có chủ đích chứ không phải thiếu thông tin do lỗi. Nếu KHÔNG phải chủ ý, cần xem lại tại sao 2
lựa chọn kia không giấu gì mà lựa chọn thứ 3 lại giấu. **→ cần `game-designer` xác nhận ý đồ trước
khi đóng mục này.**
**Công sức**: S (chỉ thêm 1 chữ, nếu xác nhận là chủ ý).

---

## P2 — Đánh bóng

### P2-1. Post-combat reward: nền bản đồ (ô "?") lộ ra phía sau overlay, viền ô trông như nút bấm
**Màn**: Post-combat reward (`10_post_combat_reward.png`)
**Quan sát**: theo code (`_show_reward_overlay` với `backdrop=null` — cố ý dim ngay trên bản đồ vì
người chơi "đang đứng ở đó"), các ô node "?" phía sau vẫn có viền rõ như một nút bấm dù bị khoá
tương tác trong lúc overlay mở. Gây nhiễu thị giác nhẹ, mắt có thể bị hút sang góc trên thay vì
tập trung vào thẻ reward.
**Sửa thế nào**: tăng alpha lớp dim, hoặc thêm blur nhẹ cho nền khi overlay mở.
**Công sức**: S.

### P2-2. Shop: giá tiền chỉ nằm trong nút, khó so sánh nhanh giữa 4 item
**Màn**: Shop (`05`)
**Quan sát**: giá (`BUY (180)`, `BUY (75)`...) nằm bên trong nút ở lề phải; mô tả nằm bên trái —
khi so sánh "món nào đáng tiền", mắt phải quét qua lại 2 cột thay vì đọc dọc 1 cột giá.
**Sửa thế nào**: lặp lại giá ở cuối dòng mô tả/sub-text để dễ quét dọc.
**Công sức**: S. (Không chặn quyết định — giá vẫn thấy được, chỉ hơi tốn công quét mắt.)

---

## Màn ổn — không cần sửa

- **Event RESULT screen** (`03_event_result.png`): 1 thông điệp + 1 nút CONTINUE, không có gì
  thừa, hậu quả của lựa chọn trước đó được nói rõ bằng câu hoàn chỉnh ("You permanently gain 1
  maximum Reroll.") — đúng tinh thần "thấy được cái vừa xảy ra sau khi bấm". Không cần đổi.
- **VICTORY/DEFEAT banner**: dùng cả màu (xanh/đỏ) LẪN chữ ("VICTORY"/"DEFEAT") — không phụ
  thuộc màu sắc để phân biệt thắng/thua, đạt yêu cầu accessibility (functional without color
  alone).
- **Result — nút cuối**: chỉ có đúng 1 CTA "BACK TO MAIN MENU", không có lựa chọn giả/gây phân
  vân — đúng nguyên tắc giảm tải quyết định ở màn tổng kết.
- **Shop feedback sau khi mua**: tổng Gene Shard cập nhật ngay (200 → 20) và nhãn nút đổi
  "BOUGHT" — phản hồi tức thời là có thật, chỉ riêng CÁCH thể hiện disabled bị gộp chung với
  "không đủ tiền" (xem P0-1) chứ bản thân việc có phản hồi là ổn.

---

## Ghi nhận thêm (không tính vào backlog UX — cần người khác xác nhận)

- **Roster trùng lặp trên màn Defeat**: `2026-09-19_result-daily.png` liệt kê "Olek (Plant, T1) ·
  17 Max HP" **hai lần** trong YOUR PARTY. Có thể là (a) thiết kế cho phép 2 bản sao cùng hero
  trong đội hình (hợp lệ), hoặc (b) lỗi dữ liệu roster. Đây không phải quyết định UI — cần
  `gameplay-programmer` xác nhận trước khi biết có phải sửa gì không. Nếu (a) đúng, gợi ý UX kèm
  theo: nên có cách phân biệt 2 bản sao (ví dụ số thứ tự) vì hiện tại không thấy được đâu là đâu.
