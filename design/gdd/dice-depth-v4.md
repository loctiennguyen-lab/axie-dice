# Dice depth v4: BỘ + LIỀU + MẶT TẠM (+ Overcast, 5 Lõi chủ)

Trạng thái: BẢN NHÁP để Liam duyệt (20/10/2026, vá lỗ hổng QA 21/10/2026). Chưa có code của BỘ/LIỀU/MẶT TẠM/Lõi chủ. Riêng Overcast
đã có code ở nhánh `depth/OC` (e037166, chưa merge) và PHẢI sửa theo 3.10.1 trước khi merge. Số là điểm xuất phát, sim chỉnh lại.
Bảng "G# đã xử lý ở mục nào" nằm cuối file. Mục 3.10 gom mọi luật chống lách (G1-G21): đọc nó trước khi code.
Nguồn: `design/proposals/dice-depth-v4-brainstorm.md` (kể cả "Ghi chú reviewer" và 5 câu hỏi), lời Liam 20-22/10.
Code đã đọc để viết doc này: `combat_engine.gd` (roll_all, _share_class_rolls, reroll_dice, _face_value, _do_face, stash),
`damage_pipeline.gd`, `core_hooks.gd` (FLAT_CAP), `axie_to_die.gd` (SLOT_ORDER), `combat_tune.json`.

Thứ tự đọc cho người đang vội: mục 1, rồi bảng "luật một câu" ở mục 3.0, rồi ví dụ một lượt ở mục 3.9,
rồi mục 12 (câu hỏi cần Liam trả lời).

---

## 1. Overview

Hôm nay xúc xắc trong game gần như chỉ có một quyết định: dùng viên nào vào ai. Reroll thì "vô ích" vì dùng hết mọi viên
đã là gần tối ưu. Bump này thêm ba thứ nối với nhau:

- **BỘ**: sau khi tung, nếu có từ 3 viên trở lên rơi cùng một part (cùng Sừng, cùng Lưng, ...) thì mỗi viên trong nhóm
  mạnh hơn (ba x1.5, bốn x2, năm x3). Đây là thứ để người chơi đuổi theo.
- **LIỀU**: reroll lần đầu miễn phí và an toàn. Từ lần thứ hai, hoặc liều (miễn phí, mỗi viên tung lại có 30% bị Nứt:
  còn nửa giá trị và không vào Bộ), hoặc trả 2 mana cho chắc. Đây là chỗ có rủi ro.
- **MẶT TẠM**: trả 2 mana, một viên chưa dùng được tính như part bạn chọn khi đếm Bộ (hiệu ứng thật giữ nguyên).
  Đây là cách dùng mana mua độ chắc chắn, cạnh tranh với Overcast (3 mana, x1.5 một viên) và reroll an toàn.

Cộng thêm 5 Lõi chủ (chọn 1 trong 3 khi bắt đầu run; TÁCH sang bump sau, mục 10) và mở dần theo tiến độ tài khoản để người mới không bị ngợp.
Bộ nâng trần sức mạnh của mọi người chơi kể cả bot bừa, nên độ khó phải kéo lại bằng quái nền +25% rồi chỉnh bằng sim
(mục 7, mục 8). Mục tiêu thắng: random <= 10%, spam <= 12%, expert 18-23%, expert trừ random >= 12.

Không nằm trong bump này (để sau): Sảnh, Cược, Đổi mặt, Nóng/Lạnh, thưởng đội hình (hàng trước/sau), Trọn bộ,
Khoá-tích ngoài Lõi Giữ Lửa, Nhiệt tăng dần, Lõi chủ Cầu Thang và Thợ Rèn Mặt.

---

## 2. Player Fantasy

Cảm giác muốn tạo (MDA: Challenge + Sensation, phụ là Expression):

- Nhìn 5 viên vừa tung và THẤY một mục tiêu ("hai Sừng rồi, kiếm thêm một Sừng nữa là Bộ ba"). Hôm nay người chơi
  nhìn xong chỉ thấy 5 con số.
- Khoảnh khắc "BA SỪNG!" là phần thưởng chính: chữ to, viền sáng nối các viên, số nhảy lên. Gacha vui nằm ở lúc ra Bộ,
  KHÔNG nằm ở hình phạt.
- Reroll là một quyết định có giá: đuổi Bộ hay giữ cái khiên đang cần. Liều có hồi hộp nhưng nhìn thấy trước % rủi ro,
  nên thua thì tự nhận mình đã liều, không thấy bị game cướp.
- Mana là thứ đáng giữ: 2 mana mua một Bộ chắc, 3 mana mua x1.5. Hôm nay mana gần như vô nghĩa.
- Người mới: "tao hiểu rồi" sau 1-2 lượt đầu. Người giỏi: tính xác suất, biết dừng đúng lúc.
- Tự quyết (SDT Autonomy): có 3-5 nước đi hợp lý mỗi lượt, không có nước nào luôn đúng. Năng lực (Competence):
  người chơi biết vì sao mình thắng/thua, vì mọi % và hệ số hiện ra trước khi bấm.

Giới hạn giữ cảm giác đó: mọi cơ chế giải thích được trong một câu (mục 3.0). Nếu một luật cần hai câu thì nó đang quá phức tạp.

---

## 3. Detailed Rules

### 3.0 Luật một câu (chữ này là chữ hiện trong game và trong Codex)

| Cơ chế | Một câu cho người mới |
|---|---|
| BỘ | "3 viên cùng part thì mỗi viên trong nhóm mạnh hơn (3 viên x1.4, 4 viên x1.8, 5 viên x2.6)." |
| Tung lại (lần 1) | "Mỗi lượt tung lại 1 lần miễn phí, không rủi ro." |
| LIỀU | "Tung lại tiếp thì trả mana cho chắc (2, rồi 3), hoặc liều miễn phí (mỗi viên tung lại có 30% bị Nứt)." |
| Nứt | "Viên Nứt còn nửa số và không vào Bộ, hết sau lượt." (Chỉ viên vừa tung lại ở Liều mới Nứt: luật ở 3.5, không nằm trong câu cho người mới.) |
| MẶT TẠM | "2 mana: một viên chưa dùng được tính là part bạn chọn để ghép Bộ. 1 lần mỗi lượt." |
| Overcast | "3 mana: một viên chưa dùng được cộng thêm +0.5 vào hệ số (cộng với Bộ, không nhân chồng). 1 lần mỗi lượt." |
| Lõi chủ | Mỗi Lõi một câu riêng ở mục 10. |

Số trong bảng là bản khởi điểm (`bo.scale = 0.8`, mục 7.2). Mọi ví dụ trong doc dùng số danh nghĩa (scale 1.0: x1.5 / x2 / x3) cho dễ tính; chữ trong game sinh từ knob.

**Đếm khái niệm mới ở run 1 (stage 1): 3.** (1) mỗi viên thuộc một part, (2) BỘ = 3 viên cùng part thì nhân số, (3) tung thêm tốn mana. Mana, tung lại lần 1, Hold đã có từ trước. Ngưỡng chốt: tối đa 4 khái niệm mới mỗi lần mở. Stage 2 mở 2 (Liều + Nứt là một cặp, Mặt Tạm), stage 3 mở Overcast, part cao bậc, Lõi chủ (xem 3.8, đã dời Overcast và part cao bậc xuống stage 3 để stage 2 không bị 5 thứ cùng lúc).

### 3.1 Dữ liệu nền (đã có trong code, chỉ dùng lại)

- Mỗi viên có đúng 6 mặt, xếp theo `SLOT_ORDER = [mouth, horn, back, tail, eyes, ears]` = Miệng, Sừng, Lưng, Đuôi, Mắt, Tai.
  Chỉ số mặt `fi` (0..5) chính là "part" của mặt đó. `roll_face_index()` trả `fi`. Mọi chỗ trong doc này nói "part" = `fi`.
  Lập trình viên kiểm: `die.size() == 6` và `die[fi]` đúng thứ tự SLOT_ORDER (axie_to_die.gd:340). Mặt `type == "blank"`
  (part thiếu dữ liệu) không bao giờ vào Bộ.
- Loại mặt (`type`) gắn với part theo từng class: Miệng và Sừng luôn dmg; Tai gần như luôn mana (và mang keyword
  `cantrip`); Lưng/Đuôi/Mắt tuỳ class (khiên, dmg, độc, hồi, debuff). Nghĩa là Bộ có thể là Bộ dmg, Bộ khiên, Bộ hồi, Bộ độc.
- Mặt có keyword `cantrip` tự dùng ngay lúc tung rồi viên tung lại (`_resolve_cantrips`). Hệ quả cho xác suất: Tai gần như
  không bao giờ nằm yên trên bàn, nên thực tế mỗi viên chỉ rơi vào 5 part ổn định, không phải 6 (xem 4.2).

### 3.2 Ai được đếm vào Bộ ("viên đủ điều kiện")

Một viên đủ điều kiện khi TẤT CẢ đúng:

1. thuộc phe người chơi (`side == "p"`), Axie thật (không phải token/Egg, không phải viên ảo của Lõi Sixth Die; viên ảo nhận
   biết bằng `custom_state.phantom`, KHÔNG phải `is_token`, vì viên ảo copy Axie thật và không có `is_token`; xem 3.10.5),
2. còn sống (`hp > 0`) tại lúc tính lại Bộ (3.3),
3. đang có mặt trên bàn (`has_rolled()`), không phải viên ngủ/không tung,
4. mặt hiện tại không phải `blank`,
5. không bị Nứt,
6. không bị bỏ ngoài băng ghế (`is_sidelined`).

Các trường hợp hay bị hỏi (chốt luôn):

- Viên ĐÃ DÙNG vẫn đếm (mặt vẫn nằm trên bàn).
- Viên đang Hold (stash) vẫn đếm lượt này; lượt sau nó mang mặt cũ sang và đếm lại như viên tung sẵn. (Nó không được dùng
  lượt này nên cái giá vẫn thật.)
- Viên đóng băng (`frozen`) vẫn đếm.
- Token, Egg, viên triệu hồi: KHÔNG đếm, KHÔNG được hưởng hệ số.
- Viên ảo của Lõi Sixth Die (viên thứ 6): KHÔNG đếm và KHÔNG được hưởng hệ số (knob `bo.phantom_counts = 0`). Lý do: giữ
  trần Bộ là năm; nếu bật lên thì xác suất phải tính lại với 6 viên (Q3 mục 12).
- Quái (`side == "e"`): không bao giờ có Bộ.
- Ghost raid (phòng thủ Land): NGƯỜI TẤN CÔNG vẫn chơi bình thường bằng đội của mình nên Bộ áp lên họ như trận thường. Ghost chỉ
  thay danh sách `enemies` bằng quái dựng từ snapshot, tức là phe "e", và phe "e" không bao giờ có Bộ. (Bản nháp cũ viết ngược:
  "raid không có lượt người chơi, đặt `bo.enabled = 0`". Sai, đã bỏ. Chi tiết 3.10.4.)

Part của viên khi đếm = `wild_slot` nếu viên đó đang có Mặt Tạm, nếu không thì `roll_face_index()`.

Lõi Concord ("Đồng Tâm", hook `roll_share_class`) ép các Axie cùng class ra cùng `fi`, tức là ra Bộ chắc chắn. Luật chặn:
nếu có Concord, mỗi class chỉ có MỘT viên được đếm vào Bộ (viên đủ điều kiện đứng đầu trong thứ tự `party`); các viên cùng
class còn lại vẫn dùng bình thường nhưng không đếm và không được hưởng hệ số. Luật này đúng cả sau reroll, nên không cần
nhớ viên nào bị Concord ép.

### 3.3 Bộ được tính khi nào ("Bộ chốt")

Bộ KHÔNG tính lại mỗi lần dùng viên. Engine giữ một ảnh chụp `bo` (danh sách nhóm: part, size, danh sách uid) và chỉ chụp
lại ở đúng các thời điểm sau, bằng một hàm thuần `recompute_bo()`:

1. cuối `roll_all()`: sau `_share_class_rolls()`, `_spawn_phantom_dice()` và `_resolve_cantrips()`;
2. cuối mỗi `reroll_dice()`: sau `_resolve_cantrips()` và sau bước Nứt (3.5);
3. sau `wild_face()` (Mặt Tạm, 3.6);
4. sau mọi lệnh đổi mặt của relic (`tweak`, `loaded_pick`, `hold_pick` nếu nó đổi mặt);
5. sau BẤT KỲ chỗ nào khác ghi lại mặt của một viên (chaos reroll, `face_swap`, hiệu ứng đổi mặt khi dùng viên, Loaded...). Lập trình
   viên phải grep mọi writer của `current_face` / `roll_face_index` ngoài `roll_all`/`reroll_dice`/lệnh relic ở mục 4 và cho
   mỗi cái gọi `recompute_bo()`, hoặc ghi vào danh sách "chấp nhận không tính lại" ở đây kèm lý do. Không được để viên đã
   đổi thành mặt mana/khiên vẫn nhận hệ số của nhóm cũ (hay ngược lại). Test: `t_bo_timing` có ca "mặt bị đổi bởi hiệu ứng".

Giữa hai lần chụp, chết một viên (kể cả viên tự nổ `selfkill`), dùng viên, Hold, hồi sinh, KHÔNG làm Bộ đổi. Lý do: người
chơi phải đoán được hệ số trước khi bấm, và thứ tự dùng viên không được làm thay đổi nhau (không có câu đố "dùng viên nào
trước để giữ Bộ").

Bộ chụp trong `_state_dict()` (nằm trong ảnh undo và trong save), không suy ngược khi load.

Nhóm có `size >= 3` là Bộ. `size` 3, 4, 5 ứng với ba, bốn, năm. Hai viên cùng part là "đôi", không có thưởng gì cả.
Nếu có hai nhóm cùng đủ 3 (không thể với 5 viên: 3+3 cần 6) thì không xảy ra; với 5 viên nhiều nhất một Bộ.

### 3.4 Hệ số: một "túi" cộng, nhân một lần

Mỗi lần một viên được dùng (kể cả lượt Echo thứ hai và từng đòn của `multi`), engine đọc túi hệ số `M` của viên đó:

```
M = 1.00
  + bo_add        (viên nằm trong Bộ: ba +0.50, bốn +1.00, năm +2.00; ngoài Bộ: 0)
  + oc_add        (viên đang gắn Overcast: +0.50; Lõi Mỏ Mana đổi thành +1.00 nếu viên đó nằm trong Bộ)
  + part_add      (Bộ có part cao bậc: +0.25, mục 11; chỉ tính cho viên nằm trong Bộ)
  + core_add      (cộng từ Lõi chủ, mục 10)
M = min(M, M_cap)   với M_cap = bo.m_cap (khởi điểm 3.00; các ví dụ dưới viết 3.50 là số danh nghĩa cũ)
```

Các phần thưởng CỘNG vào nhau rồi nhân MỘT lần. Ví dụ Bộ bốn (+1.00) cộng Overcast (+0.50) cho M = 2.50, không phải
2.0 x 1.5 = 3.0. Lý do: dễ giải thích ("cộng các thưởng lại"), không có tầng nhân chồng làm tăng đột biến, và trần 3.5
cắt gọn trường hợp Bộ năm + Overcast.

`M` chỉ áp lên **số trên mặt** (`value`) của mặt loại `dmg`, `shield`, `heal`, `poison`. KHÔNG áp lên:

- mặt `mana` (để không có vòng mana nuôi Mặt Tạm/Overcast), mặt `debuff`, `summon`, `blank`;
- con số nằm trong keyword (`thorns:N`, `weaken:N`, `vulnerable`, `regen`...), tức là thorn không bị Bộ nhân, và
  thorn vẫn không có trần (knob `thorns.cap = 0` giữ nguyên).

Số học làm bằng số nguyên theo phần trăm để khỏi lệch dấu phẩy động: `M100` = M x 100 (150, 200, 250...);
`v_sau = (v * M100 + 99) / 100` (chia nguyên, làm tròn lên). Ví dụ `v = 5`, `M100 = 150` cho `(750 + 99) / 100 = 8`.

`M100` dựng từ đóng góp đã làm tròn từng cái MỘT lần (N11): `M100 = 100 + round(bo_add x bo.scale x 100) + round(oc_add x 100) + ...`, không
nhân `0.8 x 100` bằng số thực rồi cộng. Với mặc định `bo.scale` 0.8: Bộ ba +0.40 (M 1.40), bốn +0.80 (1.80), năm +1.60 (2.60); Bộ bốn + Overcast = 2.30
(`oc_add` không nhân `bo.scale`). Các ví dụ trong doc dùng `bo.scale` 1.0 và `m_cap` 3.5 (số danh nghĩa); test phải ghi rõ bộ knob nào (mục 8.1).

Trần poison, thorn (N6, 21/10): `poison.face_cap` áp ở CUỐI chuỗi giá trị của mặt, tức sau bước 7 (sau `M`, Resonance, `face_final`, cộng phẳng
Lõi, `first_dmg_face_bonus`) và TRƯỚC DamagePipeline. Lý do: một chỗ đo được, mọi nguồn cộng đều bị cắt, đỉnh một mặt poison luôn <= 8.

Thứ tự tính cho một mặt của người chơi (chỗ đánh dấu MỚI là chỗ thêm; còn lại đã có trong `_face_value` / pipeline):

| Bước | Việc | Ghi chú |
|---|---|---|
| 1 | giá trị gốc: `value + growth`; `vital`; dmg: blind về 0, weaken, overdrive, hiveMind | có sẵn |
| 2 | MỚI: viên Nứt thì `v = ceil(v / 2)` (v >= 1 vẫn còn >= 1) | chỉ mặt có số |
| 3 | cộng phẳng R12 (Vỏ Cứng +2 trên khiên/độc), CONDUIT aqua +1 mana | có sẵn, nằm TRƯỚC hệ số nên bị nhân |
| 4 | MỚI: nhân bởi `M` như công thức trên | không áp mặt mana/debuff |
| 5 | Resonance (LINK): `ceil(v * 1.15)` | có sẵn, chạy SAU `M`, giữ nguyên |
| 6 | hook `face_final`: Lõi cộng phẳng (cộng dồn tối đa +10 một mặt, `FLAT_CAP`), Lõi nhân x1.5 (phần tăng tối đa +8, `core.mult_cap`) | có sẵn |
| 7 | bonus dmg đầu tiên mỗi lượt (`first_dmg_face_bonus`), cộng phẳng | có sẵn |
| 8 | DamagePipeline: execute x1.6, pierce, mod_dmg, crit x2, vulnerable, boss hollow, Plating (chỉ đòn đơn), incoming_dmg, giảm sát thương, khiên hấp thụ, trừ HP | có sẵn |

Hệ quả cần ghi rõ:

- Lõi cộng phẳng đứng SAU hệ số nên KHÔNG bị Bộ nhân. Trần +10 vẫn là trần của riêng nhóm cộng phẳng. Bộ không đụng trần này.
- Resonance và Lõi x1.5 là hai tầng nhân đã tồn tại và vẫn nằm ngoài túi. Tổng trần thực tế của một mặt dmg 6 với
  Bộ năm + Overcast: túi 3.5 (21), LINK x1.15 (25), Lõi x1.5 (phần tăng tối đa +8: 33), cộng phẳng tối đa +10 (43),
  rồi crit x2. Sim phải đo xem đỉnh này có làm hỏng boss cuối không; nếu có thì hạ `M_cap` trước, không đụng trần Lõi.
- Plating chạy sau mọi hệ số nên Bộ làm Plating yếu đi một chút trên đòn đơn. Chủ ý: Bộ là đường đánh người chơi giỏi vào quái có Plating.
- Đòn Nạp (Charge của quái, ngưỡng sát thương để phá): ngưỡng so với sát thương THẬT sau Bộ, không đổi luật của nó. Bộ làm phá Nạp dễ hơn;
  sim chỉnh ngưỡng nếu cần.

### 3.5 LIỀU: ba kiểu reroll

Chỉ áp cho phe người chơi. Dùng lại biến có sẵn: `rerolls` (số lần tung miễn phí còn lại), knob `reroll.max_total`, và một biến MỚI `reroll_paid_k` (N1, 21/10):
số lần Liều/An toàn đã chọn trong lượt. `reroll_paid_k` CHỈ tăng khi người chơi chọn Liều hoặc An toàn. Lần miễn phí gốc, lần relic/Lõi/Aqua
tặng, và Aid KHÔNG làm nó tăng. (Code hiện tại tăng `reroll_nonaid` cho mọi lần không-Aid, kể cả lần free: sai với luật này, phải tách
`reroll_paid_k` ra, đừng tái dùng `reroll_nonaid` cho việc này, và `reroll_is_payable` phải đọc `reroll_paid_k`.) Điều kiện còn được chọn Liều/An toàn:
`reroll_paid_k + reroll.free < reroll.max_total`, tức `reroll_paid_k < 2` với số khởi điểm (`max_total` 3 = 1 lần gốc + 2 lần lựa chọn).
`reroll_paid_k` nằm trong `_state_dict`, ảnh undo và save, reset ở `roll_all`.

Cho mỗi lần xin reroll, engine xác định kiểu:

| Kiểu | Khi nào | Giá | Nứt |
|---|---|---|---|
| Miễn phí an toàn | còn `rerolls > 0` (1 lần gốc, cộng thêm các lần relic tặng) | 0 | không |
| Aid | đến từ Aid (tài nguyên meta, như hiện tại) | như hiện tại | không |
| LIỀU | `rerolls == 0`, `reroll_paid_k + reroll.free < max_total`, người chơi chọn "Liều" | 0 | có, `crack_pct` mỗi viên tung lại |
| AN TOÀN trả mana | như trên, người chơi chọn "An toàn" | lần lựa chọn thứ nhất (tổng lần 2) `reroll.mana_cost_2` = 2 mana; lần thứ hai (tổng lần 3) `reroll.mana_cost_3` = 3 mana (+ phụ phí hook `before_reroll`, giảm giá hook `reroll_mana_cost`) | không |

- **Giá thật cho lần 2-3 (sửa edge 32):** vì viên tung lại vốn cũng được dùng, Liều một mình gần như miễn phí; nên chỉ Nứt làm nó có giá, và Nứt phải đủ đau (30%, không phải 25%). Đường An toàn tăng giá theo lần: 2 rồi 3 mana. Chase đủ 3 reroll bằng mana tốn 5, gần hết mana một lượt, chắc chắn không còn Mặt Tạm hay Overcast. Một dòng cho người chơi: "tung thêm lần 2 tốn 2 mana, lần 3 tốn 3 mana". Không thêm luật nào khác.
- `reroll.max_total` giảm từ 4 xuống 3 (lần 1 + hai lần lựa chọn). Relic tặng lần miễn phí vẫn cộng thêm như cũ (chúng đi
  qua `rerolls`, không qua `max_total` và không làm `reroll_paid_k` tăng). Ví dụ: có relic +1 thì thấy 1 gốc + 1 relic + 2 lựa chọn = 4 =
  `hard_cap`; relic +2 thì vẫn 4 (cap cắt lần thứ 5). Giá An toàn đọc theo `reroll_paid_k` (0 thì `mana_cost_2`, 1 thì `mana_cost_3`), không theo
  tổng số lần đã tung.
- Chọn kiểu là một tham số mới của action: `reroll_dice(uids, from_aid, rmode)`. Tên key là `rmode`, KHÔNG phải `mode`, vì
  `worker/src/epoch_args.json` đã có `mode` = enum `short/full` cho `run_start`. `rmode` là số nguyên: `0` = Liều, `1` = An toàn
  (ActionLog canon không có bool/chuỗi cho arg này, giống `from_aid`). Với lần miễn phí an toàn và Aid, engine ĐỔI `rmode` thành `1`
  trước khi ghi log (không "bỏ qua"), để log và seed luôn có một giá trị rõ. `rmode` đi vào ActionLog và vào tham số xin seed
  (`_reroll_args`). Khoá và kiểm ở 3.10.2.
- Tổng số lần tung lại mỗi lượt (mọi nguồn: miễn phí gốc, relic/Chaos tặng, Aid, Liều, An toàn) không vượt `reroll.hard_cap`
  (3.10.3). `max_total` chỉ so với `reroll_paid_k` (hai lần lựa chọn Liều/An toàn, cộng `reroll.free`).
- Nứt: sau khi mọi viên được tung lại và `_resolve_cantrips()` chạy xong, với MỖI viên trong danh sách reroll (theo thứ tự
  uid người gọi truyền, đúng thứ tự log), rút một số `_rng.next_int(100)` từ chính luồng seed của lần reroll đó; nếu `< crack_pct`
  thì viên đó `cracked = true`. Luôn rút đủ một số mỗi viên dù viên đó đã chết hay không tung được, để mức tiêu thụ RNG
  không phụ thuộc trạng thái. Seed do server cấp (online-only), client không tự rút.
- Chỉ viên VỪA tung lại ở lần đó mới có thể Nứt. Viên không tung lại không bao giờ Nứt.
- Viên đang Nứt mà tung lại: Nứt cũ xoá, rồi kiểm lại Nứt cho lần mới (nếu lần này là Liều).
- Nứt hết hiệu lực ở `roll_all()` của lượt sau (viên tung mới là viên sạch). Viên Hold mang sang lượt sau cũng sạch Nứt
  (Nứt không đi qua lượt).
- Reroll vẫn xoá ngăn xếp undo (trừ relic `safeReroll`, như hiện tại). Vì vậy kết quả Liều (kể cả Nứt) là điểm không quay lại.
  Với `safeReroll`, undo qua một reroll đưa `reroll_k` về giá trị cũ, nên reroll lại xin cùng seed và ra cùng kết quả,
  không thể "undo để lăn lại" Nứt. Nhưng `reroll_k` quay về KHÔNG đủ để chặn "nhìn kết quả Liều rồi đổi sang An toàn"; phần chặn
  đó là khoá `(rmode, uids)` ở 3.10.2.

### 3.6 MẶT TẠM

- Hành động `wild_face(uid, slot)`: trả `wild.cost` = 2 mana, gắn `wild_slot = slot` (0..5) lên viên `uid`.
- Giới hạn: `wild.per_turn` = 1 lần mỗi lượt (đếm trong `wild_used`, reset ở `roll_all`). Không có Lõi nào đổi con số này
  trong bump này.
- Viên mục tiêu phải: sống, đang có mặt, CHƯA dùng, không Hold, không Nứt, không `cantrip`, không phải token/viên ảo
  (`custom_state.phantom`), CÓ đủ điều kiện đếm Bộ theo 3.2 kể cả luật Concord (viên bị Concord loại thì từ chối, không tốn mana;
  xem 3.10.5), và chưa có Mặt Tạm (Overcast cho phép cùng viên, xem edge case 14; nhưng viên Overcast không tung lại, 3.10.1).
- `slot` bất kỳ trong 6. Engine không cấm chọn part chưa có viên nào; UI chỉ gợi ý những part làm Bộ lớn lên.
- Tác dụng DUY NHẤT: khi đếm Bộ, viên đó thuộc part `slot`. Mặt thật, loại, keyword, giá trị, crit của nó giữ nguyên.
  Nó vẫn nhận hệ số của nhóm `slot` (vì nó là thành viên).
- Viên có Mặt Tạm: không tung lại được (bị loại khỏi `_rerollable`), không Hold được. Lý do: nếu tung lại thì mặt mới có
  thể làm Mặt Tạm vô nghĩa mà mana đã mất; khoá lại thì luật sạch.
- Hết hiệu lực ở `roll_all()` lượt sau. Không hoàn mana.
- Gọi `recompute_bo()` ngay sau khi gắn.
- Có undo (đẩy một ảnh trước khi gắn; hoàn lại mana). Vì không có ngẫu nhiên nên undo không gây gian lận.
- Mana: kiểm `mana >= cost` TRƯỚC khi đổi bất cứ thứ gì. Không bao giờ để mana âm.

### 3.7 Overcast (làn OC, ghép vào)

Làn OC làm riêng action và UI. Hợp đồng để ghép vào túi `M`:

- Overcast: trả 3 mana, gắn cờ `overcast = true` lên một viên chưa dùng, sống, đang có mặt, không phải mặt `mana`, không phải
  token/viên ảo, không `frozen`, `v0 >= 1`; một lần mỗi lượt. Cờ nằm trên viên cho tới khi viên được dùng hoặc hết lượt (reset ở
  `roll_all`). Luật đầy đủ, kể cả viên Overcast không tung lại/Hold: 3.10.1.
- Hệ số: đóng góp `oc_add = +0.50` vào túi `M` (3.4). Làn OC KHÔNG được tự nhân x1.5 riêng sau khi tính xong, nếu không là
  nhân chồng. **Đã chốt (Q1): cộng một túi.** Làn OC đã code nhân x1.5 sau trần Lõi thì PHẢI sửa: (a) bỏ phép nhân x1.5 đó, thay bằng `oc_add` đọc trong `M`; (b) giá trị Overcast không còn đứng sau `core.mult_cap`/`FLAT_CAP` mà nằm ở bước 4. Lý do: nhân sau trần Lõi vừa vượt `M_cap`, vừa thành x2.25 với Bộ ba (so với 2.0 trong túi), vừa làm sim khó đọc. Test `t_bo_overcast` bắt lỗi này. (Cây hiện tại không có chữ "overcast" trong `.gd`; việc kiểm xảy ra khi làn OC merge.)
- Echo/`multi`: Overcast nằm trên viên nên áp cho mọi lần dùng trong cùng một lần "dùng viên" (đã trả mana một lần).
- Viên Nứt vẫn Overcast được (nhân trên giá trị đã chia đôi). Viên có Mặt Tạm Overcast được.
- Viên có `cantrip` không Overcast được (nó đã tự dùng lúc tung).

### 3.8 Mở dần ("stage") để người mới không bị ngợp

Một số nguyên `depth_stage` 1..3 tính một lần lúc bắt đầu run và ghi vào header run (cùng chỗ với `newcomer`, ActionLog
`set_epoch_header`), để replay và Worker dựng lại đúng. Không đổi giữa run.

| Stage | Điều kiện khi bắt đầu run | Có | Ẩn |
|---|---|---|---|
| 1 | tài khoản chưa có run hoàn thành nào (`runs_completed = 0`) | BỘ, reroll lần 1 an toàn, reroll thêm chỉ bằng mana (An toàn), Hold như cũ | Liều/Nứt, Mặt Tạm, Overcast, Lõi chủ, part cao bậc |
| 2 | `runs_completed >= depth.stage2_runs` (1) | thêm Liều/Nứt, Mặt Tạm | Overcast, part cao bậc, Lõi chủ |
| 3 | `runs_completed >= depth.stage3_runs` (3) | thêm Overcast, part cao bậc (+0.25), Lõi chủ (chọn 1 trong 3; Lõi chủ là "bump sau", mục 10) | không |

`runs_completed` (N7, 21/10) = số run đã hoàn thành (thắng hoặc thua đến hết, có `run_finish`), thứ server đo được: Worker đã có dòng `run_finish` trong D1 cho
mỗi run nộp xong, nên không cần Worker chạy luật. Bỏ `first_boss_won` (Worker không kiểm được thắng boss). Run bỏ giữa chừng không có `run_finish` thì không tính.

Làn OC phải chặn Overcast ở `depth_stage < 3` (engine trả false, như mọi action stage cao). Ghi chú: các chỗ khác trong doc còn viết "Overcast ở stage 2" (9.4 C7, mục 1) thì đọc theo bảng này.

- Tài khoản cũ không còn là newcomer (`runs_with_battle >= 5`, đúng `MetaState.is_newcomer()` đã có) bắt đầu thẳng ở stage 3,
  để không bắt người đã chơi nhiều học lại (đây là lối vào duy nhất còn dùng `runs_with_battle` cho stage; server tính từ D1 như 3.10.9). Cần migrate: field mới `runs_completed` phải thêm vào cả `MetaState.reload_from_store()`
  và đi qua `SaveStore`.
- Hoàn thành run không mở ngay trong run đó (stage đóng băng ở đầu run). Màn kết run hiện "Mới mở: Liều, Mặt Tạm. Có từ run sau" (đúng phần stage kế mở ra).
- Stage 1 dùng cùng `max_total = 3` như các stage khác (một số cố định, không đổi theo stage).
- Stage ảnh hưởng tới: UI (ẩn nút), engine (action bị từ chối nếu stage thấp, trả `false`, không đổi state), và pool Lõi chủ.
  Engine không được tin UI: `reroll_dice` với `rmode = 0` (Liều) ở stage 1 trả `false`.

### 3.9 Ví dụ một lượt 5 viên (giá trị là minh hoạ, loại mặt đúng luật class)

Đội: Beast, Aqua, Bird, Plant, Reptile. Mana 3. Quái boss sắp đánh 14. Stage 3.

Tung ra (part, loại, giá trị):

| Viên | Part | Mặt |
|---|---|---|
| Beast | Sừng | dmg 5 |
| Aqua | Sừng | dmg 3 |
| Bird | Sừng | dmg 4 |
| Plant | Miệng | dmg 4 |
| Reptile | Mắt | heal 3 |

1. Ba viên Sừng: **BỘ BA x1.5**. Túi M = 1.5. Beast 5 thành 8, Aqua 3 thành 5, Bird 4 thành 6. Plant 4 và Reptile 3 ngoài Bộ.
   Tổng dmg nếu dùng ngay: 8 + 5 + 6 + 4 = 23 (thay vì 16), và không có khiên nào trước đòn 14.
2. Tung lại lần 1 (miễn phí, an toàn): chọn Plant và Reptile. Ra Plant ở Lưng (khiên 4), Reptile ở Sừng (dmg 2).
   Giờ có bốn Sừng: **BỘ BỐN x2**. Beast 10, Aqua 6, Bird 8, Reptile 4. Plant là khiên 4, ngoài Bộ.
3. Còn 3 mana, hai đường:
   - Mặt Tạm (2 mana) cho Plant tính như Sừng: **BỘ NĂM x3**. Beast 15, Aqua 9, Bird 12, Reptile 6 = 42 dmg; Plant vẫn là
     khiên (giá trị 4 x3 = 12 khiên). Còn 1 mana.
   - Overcast (3 mana) lên Beast: M = 1 + 1.00 + 0.50 = 2.50, Beast 5 x 2.5 = 12.5 thành 13. Tổng dmg 13 + 6 + 8 + 4 = 31, khiên 4.
   Mặt Tạm hơn rõ (42 dmg và 12 khiên so với 31 và 4) vì Bộ năm là x3 cho cả bốn viên và cho cả khiên. Đó chính là chỗ người giỏi thấy.
4. Nếu bước 2 hụt (ví dụ chỉ ra Sừng ở một viên), người chơi còn lần tung lại thứ hai: Liều (miễn phí, mỗi viên 30% Nứt) hay An toàn (2 mana,
   rồi không đủ 3 mana cho Overcast). Mỗi nhánh có lý, đúng mục tiêu "3-5 lựa chọn hợp lý".

### 3.10 Luật chống lách (bịt lỗ hổng QA G1-G21)

Mục này là luật chính thức, thắng mọi câu mâu thuẫn ở trên. Mỗi mục: quyết định, câu luật, edge case. Tên test trong ngoặc ở mục 8.

#### 3.10.1 Overcast nằm trong túi M (G1, G8)

- Quyết định (Liam đã chốt): Overcast cộng `oc_add = +0.50` vào túi M, rồi nhân MỘT lần cùng Bộ. KHÔNG còn phép nhân x1.5 riêng
  sau `face_final`. Code Overcast ở `depth/OC` đang nhân x1.5 ngoài trần (đủ để mặt dmg 6 đi tới ~65 với Bộ năm), làn OC phải sửa:
  đổi hàm `overcast_mult()` thành đóng góp `oc_add` đọc trong `M`, xoá phép nhân ở `combat_engine.gd` ~1501, sửa `t_overcast`.
- Điều kiện gắn Overcast (thiếu một cái là trả `false`, state không đổi, KHÔNG mất mana): viên sống, đang có mặt, chưa dùng,
  không Hold, không `cantrip`, không token, không viên ảo, KHÔNG `frozen`, mặt thuộc loại nhân được (`dmg/shield/heal/poison`),
  `v0 >= 1` (giá trị sau bước 1-3 của 3.4, tức gắn lên mặt giá trị 0 hay bị blind về 0 thì từ chối), chưa có Overcast, chưa gắn
  Overcast nào trong lượt. Lý do loại `frozen`: viên đóng băng bị loại khỏi nhiều hành động (không tung lại); không để người chơi
  trả 3 mana cho thứ mình không chắc dùng được.
- Viên Overcast KHÔNG tung lại được và KHÔNG Hold được (bị loại khỏi `_rerollable` và `stash`), loại trừ hai chiều: viên đã
  tung lại xong thì vẫn Overcast được (cờ gắn SAU lần tung), nhưng đã Overcast rồi thì khoá. Lý do: nếu tung lại sau khi gắn,
  cờ rơi vào mặt mana (mất 3 mana vô hình) hoặc người chơi nhìn kết quả rồi mới "chọn" viên để nhân.
- Cờ hết khi viên được dùng, hoặc ở `roll_all` lượt sau. Viên Overcast bị giết trước khi dùng: cờ mất, mana KHÔNG hoàn (giống Mặt Tạm).
  Undo hoàn cả mana và cờ.
- Edge: Overcast + Mặt Tạm cùng viên cho phép (tổng 5 mana, M = 1 + bo_add + 0.50). Overcast + Nứt cho phép (nhân trên giá trị đã chia đôi).
  Overcast trên viên ngoài Bộ: M = 1.50. (`t_bo_overcast`, `t_flow_overcast_bo`)

#### 3.10.2 Epoch: `rmode` và khoá `(rmode, uids)` (G2, G3, và chống fishing seed)

- Từ vựng: thêm key `rmode` vào `worker/src/epoch_args.json`, enum `[0, 1]`, chỉ cho kind `reroll`. Key `mode` giữ nguyên enum
  `short/full` cho `run_start`. Sửa cả fake remote trong `t_remote_epoch_ui_run` (nó đọc cùng file) và `KINDS` trong Worker.
- Câu luật: "Với cùng một `(battle, attempt, turn, k)`, kết quả lần tung ĐÃ THẤY là cố định: cùng `rmode`, cùng danh sách `uids`
  (đúng thứ tự), cùng mặt, cùng Nứt."
- Engine: `_state_dict` giữ `reroll_lock[k] = { rmode, uids }` cho lượt hiện tại. Xin tung lại một `k` đã có trong `reroll_lock` mà
  `rmode` hoặc `uids` khác thì trả `false`, state không đổi. Khoá này KHÔNG bị undo xoá (kể cả `safeReroll`: undo đưa `reroll_k`
  về giá trị cũ nhưng `reroll_lock` giữ nguyên, nên lần tung lại ở `k` đó chỉ được lặp đúng y chang). Khoá hết ở `roll_all` lượt sau.
- Khoá có thêm `rsrc` (N3): 0 = lần free/An toàn/Liều, 1 = Aid. `rsrc` chỉ nằm trong engine/save (không vào ActionLog, không vào pin Worker; Worker
  không biết sổ Aid). Xin tung lại ở `k` đã khoá mà `rsrc` khác thì `false`. Sổ Aid hoàn lại cùng undo (cùng ảnh undo với `reroll_k`); nếu không hoàn được
  thì lần `k` đó chỉ được lặp bằng Aid. Nên không có đường "thấy kết quả rồi đổi nguồn trả". Free relic và An toàn trả mana cùng `rmode = 1` nhưng engine
  luôn dùng lần free trước khi trả mana, nên nguồn không đổi được. Test: sổ Aid sau undo (`t_reroll_modes`, `t_aid_reroll_depth`).
- Kẹt sau undo (N2): chọn cách đơn giản, không cho nhảy `k`. Nếu khoá ở `k` còn mà người chơi đã dùng/Hold một viên trong `uids` của khoá, danh sách cũ
  không lặp lại được, thì nút tung lại xám kèm lý do "đã tung lần này với danh sách khác, bấm Hoàn tác để tung lại đúng danh sách cũ" và `reroll_dice` trả
  `false`. Người chơi vẫn có lối ra: Hoàn tác việc dùng/Hold viên đó (use_die và stash đều có undo), rồi tung lại đúng danh sách khoá, hoặc đi tiếp
  không tung. Lý do không chọn "nhảy `k+1`": với `safeReroll` nó mở đường câu seed bằng undo nhiều lần. Test: `t_reroll_modes` có ca này và ca lối ra.
- Save/load giữa lượt: `reroll_lock` và mặt đã tung nằm trong save; nạp lại là đúng viên, đúng mặt, đúng Nứt, không "chia bài lại".
  Nạp một save CŨ hơn (trước lần tung) là save-scum; đường online được chặn ở Worker (dưới), đường offline không có ranked nên bỏ qua.
- Worker: dòng pin hiện chỉ LƯU `uids`. Phải so: khi đã có pin cho `(battle, attempt, turn, k)`, request có `rmode` hoặc `uids`
  khác dòng pin thì trả `pin_mismatch` (mã lỗi mới), không cấp seed khác. Worker vẫn không chạy luật (Q7); chỉ so hai trường này.
- Nứt rút từ chính luồng seed của lần tung đó (3.5), một số mỗi viên theo thứ tự `uids`, luôn rút đủ. Cấm `randi()/randf()` toàn cục ở chỗ mới.
- Edge: kết quả Liều đã thấy thì KHÔNG đổi sang An toàn (và ngược lại) ở cùng `k`, dù undo, dù nạp save lượt đó. Người chơi
  muốn khác thì phải tiêu lượt tung kế (`k + 1`), tức trả giá thật. (`t_bo_undo`, `t_reroll_epoch_pin`, `t_depth_epoch_args_contract`, tamper T1, T9)

#### 3.10.3 Aid và tổng số lần tung lại (G4, G17)

- Quyết định tạm (CÂU HỎI CHO LIAM, mục 12 câu 5): Aid reroll là AN TOÀN: không Nứt, không tốn mana, không tính vào `reroll.max_total`
  và không làm `reroll_paid_k` tăng (3.5). Lý do: Aid là tài nguyên meta, người chơi đã trả (kể cả tiền thật, hướng bán giải pháp ngày 11/10).
  Rủi ro P2W ranked ghi thẳng ở đây: người có nhiều Aid có thêm tối đa các lần an toàn, tức Bộ chắc hơn trong ranked. Giảm rủi ro bằng
  cap cứng dưới đây, nên Aid chỉ thay chỗ trống chứ không vô hạn. Nếu Liam chọn "Aid tính vào `max_total`" thì Aid kiểu 1 trong 2 lần
  lựa chọn (không Nứt, không mana); số Aid mỗi lượt vẫn do luật Aid hiện tại giữ.
- Cap cứng: `reroll.hard_cap` = 4 lần tung lại mỗi lượt, đếm MỌI nguồn (miễn phí gốc, relic/Chaos tặng, Aid, Liều, An toàn). Hai biến đếm khác nhau,
  đừng gộp (N1): `reroll_total_turn` (mọi nguồn, so với `hard_cap`) và `reroll_paid_k` (chỉ Liều/An toàn, so với `max_total`, 3.5).
  Đạt cap thì `reroll_dice` trả `false`. Khởi điểm 4 = 1 gốc + 2 lựa chọn + 1 do relic/Aid. Với 5 viên, 4 lần an toàn đã ~90% có Bộ
  ba+, nên cap này không được nâng khi chưa sim.
- Edge: nhiều relic tặng lần miễn phí không phá cap (chúng cộng vào `rerolls`, nhưng cap cứng cắt). Đếm bằng biến riêng `reroll_total_turn`,
  nằm trong `_state_dict`, reset ở `roll_all`. (`t_reroll_modes`, `t_aid_reroll_depth`, tamper T10)

#### 3.10.4 Ghost raid (G5)

- Câu luật: "Trận raid dùng đúng luật Bộ như trận thường, cho người tấn công. Quái ghost là phe `e` nên không có Bộ."
- Hệ quả: BỎ `bo.enabled = 0` cho raid. Tắt Bộ chỉ ở raid sẽ làm raid yếu hơn trận thường một cách vô lý (người tấn công mất sức mạnh
  nhưng quái ghost không đổi). Knob `bo.enabled` chỉ còn là công tắc debug/rollback.
- Việc còn lại cho làn RV (N12, vào DoD, mục 8.2): chạy sim độ khó ghost sau khi có Bộ (quái ghost không tăng D như quái nền) TRƯỚC khi merge Bộ.
  Nếu raid dễ quá thì chỉnh cấp độ ghost, không tắt Bộ. (`t_bo_raid`: chạy hết một trận ghost, Bộ có áp cho phe `p`, không có cho phe `e`)

#### 3.10.5 Viên ảo, Mặt Tạm vs Concord, Egg (G6, G7)

- Viên ảo (Sixth Die) nhận biết bằng `custom_state.phantom == true`. Lọc theo cờ này ở `recompute_bo`, `wild_face` và `overcast`.
  Viên ảo: không đếm Bộ, không hưởng hệ số, không nhận Mặt Tạm, không nhận Overcast; vẫn tung lại và dùng bình thường như nay.
  `bo.phantom_counts = 0` phải được test cả hai chiều (0 thì lọc; 1 thì xác suất phải tính lại, mục 12 Q3). Lọc theo `is_token` là SAI.
- Mặt Tạm lên viên bị Concord loại: TỪ CHỐI (`false`, không tốn mana). Thứ tự tính trong `recompute_bo`: (1) chọn viên đếm theo
  Concord cho từng class, (2) chỉ với viên được đếm mới áp `wild_slot`, (3) nhóm theo part. Nếu sau này viên đếm của một class
  đổi (do Nứt viên đếm cũ), viên có `wild_slot` mà không còn là viên đếm thì `wild_slot` nằm im, không đếm, KHÔNG hoàn mana.
- Concord + Nứt: Nứt viên đếm thì viên đủ điều kiện kế tiếp theo thứ tự `party` thành viên đếm. UI phải báo ("Đồng Tâm: Beast thay Aqua").
- Egg/token nở giữa lượt thành Axie thật: lần `recompute_bo` kế (chỉ ở reroll/Mặt Tạm/đổi mặt) mới đếm nó. Chấp nhận, vì nở là đáng thưởng;
  test để ghi nhận hành vi. (`t_bo_groups`, `t_wild_face`, `t_bo_concord`)

#### 3.10.6 Tam Tấu, Con Bạc, Mỏ Mana (G9, G10, G12)

- **Tam Tấu**: tối đa MỘT vụ nổ mỗi LƯỢT (không phải mỗi Bộ). Cờ `tt_fired` trong `_state_dict`/undo/save, reset ở `roll_all`. Vụ nổ
  kích ở lần dùng viên đầu tiên của một viên đang nằm trong Bộ (size >= 3) khi `tt_fired == false`, theo Bộ đang chụp tại lúc đó.
  Reroll sau đó đổi ba Sừng thành bốn Sừng cũng không nổ thêm. Giá trị tính = tổng giá trị sau bước 1 (trước Nứt, trước M) của
  các viên trong Bộ, chỉ mặt loại `dmg/shield/heal/poison` (mana, debuff, summon, blank không cộng). Làm tròn lên.
  Sát thương nổ: `src` = viên kích nổ (KHÔNG null), `attack = false`, `from_burst = true`. Đi qua `DamagePipeline` đầy đủ; `tt.cap`
  (20) áp SAU pipeline lên sát thương cuối của mỗi quái, nghĩa là sau vulnerable, mod_dmg, crit-boss (nhưng nổ không tự có crit/Plating).
  Hook đọc `from_burst`: vụ nổ không kích `on_use` của viên, không kích Tam Tấu lại; `on_hit/on_kill/spite` chạy bình thường
  với `src` hợp lệ (giết bằng nổ tính cho viên kích). Thorn của QUÁI (affix elite, thorn boss) KHÔNG phản lên `src` khi `from_burst` (N9): nổ không phải
  đòn tấn công trực tiếp của viên (`attack = false`), và nếu không, một vụ nổ trúng 4 quái có thorn phản 4 lần lên viên kích, có thể giết Axie 1 HP. Lý do chọn
  "không phản" thay vì "phản một lần": một luật, không ngoại lệ. Test `t_core_keystones` có ca elite thorn: viên kích không mất HP vì nổ. Test đi qua mọi hook `on_kill/on_hit` với `src` thật; một test riêng vẫn
  gọi pipeline với `src = null` để chắc không crash nếu ai đó truyền null (S1 lịch sử). Undo hoàn cờ.
- **Con Bạc**: một lần Liều chỉ tính là "sạch" khi (a) số viên tung lại >= `cb.min_dice` = 2, và (b) không viên nào Nứt. Liều một viên
  không cộng, không phá. Lý do: Liều một viên rác hai lần cho +0.50 gần như không rủi ro. Tối đa +0.50, chỉ cho viên đang nằm trong Bộ.
- **Mỏ Mana**: cờ `mana_bo_paid` nằm trong `_state_dict`, ảnh undo và save, reset ở `roll_all`; undo (hoàn mana) rồi dựng lại Bộ
  KHÔNG nhận +1 lần nữa, vì cờ cũng được hoàn đúng giá trị trước đó, và vì +1 chỉ nhận khi cờ còn `false` lúc `recompute_bo`.
  Chỉ tính Bộ tự nhiên (không có viên Mặt Tạm) và Bộ có ÍT NHẤT một viên nhân được (mặt `dmg/shield/heal/poison` với `v0 >= 1`);
  Bộ toàn mặt mana/debuff (ví dụ ba Tai non-cantrip) không trả. Lý do: chống farm mana bằng Bộ không nhân.
  Trần mana: mọi nguồn cộng mana kẹp ở `mana.max` (7.1). (`t_core_keystones`, `t_bo_undo`)

#### 3.10.7 Thorn và Poison nhân Bộ (G11)

- Quyết định: chặn bằng cách đọc giá trị gốc + knob trần, không "chấp nhận kèm sim", vì thorn là thứ duy nhất không có trần.
- Thorn (N5, sửa 21/10): Lõi `c_thorn_shield` (đổi khiên thành thorn, `t = shield / 2`) chuyển CẢ KHO khiên của một Axie tại một thời điểm, nên không biết khiên
  nào từ mặt nào. Bỏ yêu cầu "đọc khiên gốc trước `M`". Luật đo được: thorn sinh ra từ MỘT lần chuyển của MỘT Axie bị trần `thorn.shield_transfer_cap` = 6
  (cho mỗi lần chuyển, mỗi Axie; không phải mỗi mặt). Công thức: `t_moved = min(shield_moved / 2, thorn.shield_transfer_cap)`. Phần khiên vượt trần vẫn bị
  chuyển hết (không giữ lại), để luật một câu. Ví dụ Bộ năm khiên, kho khiên 40: `t = min(20, 6) = 6`. (Tên knob cũ `thorn.shield_cap` bỏ.) Thorn nằm trên mặt (keyword) vẫn không bị `M` nhân (đúng edge 21), và
  `thorns.cap = 0` (không trần tổng) của luật cũ giữ nguyên; trần mới chỉ áp cho thorn sinh từ khiên.
- Poison (N6): `M` vẫn áp lên giá trị poison của mặt (đã chốt 3.4); trần mỗi mặt `poison.face_cap` = 8 áp ở CUỐI chuỗi giá trị, sau bước 7 (xem 3.4). Tổng poison
  đang chồng trên một quái bị trần `poison.stack_cap`, phần vượt bị cắt (không cộng dồn lượt sau). `stack_cap` KHÔNG đặt bừa 15: đặt bằng đỉnh stack
  poison mà bản cũ (không Bộ) đạt được ở tổ hợp relic hợp lệ do sim đo, để không nerf luật cũ; 15 chỉ là số tạm cho tới khi sim đo. Test: so stack đỉnh
  với bản cũ (`t_bo_stacking_ceiling`): không thấp hơn bản cũ, và Bộ không làm nó vượt `stack_cap`.
- Edge: Bộ năm (M = 3.0) + Vỏ Cứng +2 (cộng phẳng trước M) + Rebound: poison/thorn đã có trần nên đỉnh tính được. Thêm vào danh sách
  tổ hợp cấm của sim. (`t_bo_order`, `t_bo_stacking_ceiling`)

#### 3.10.8 Lõi chủ: epoch, và lọc Concord/Đồng Tộc giữa run (G13, G15)

- Rút 3 trong 5 Lõi chủ dùng epoch kind MỚI `keystone` (thêm vào từ vựng đóng `epoch_args.json`, args `{}` ngoài khoá chung, một
  lần mỗi run, `k = 0`). **Mục 10 và toàn bộ 3.10.8 là "bump sau" (Liam 21/10): giữ thiết kế, chưa code trong bump này; stage 3 chỉ mở Overcast và part cao bậc.**
  Khi làm: seed `keystone` pin theo (tài khoản, số run có trận `runs_with_battle`), KHÔNG pin theo run (N10): bỏ run trước trận rồi mở run mới thì ra cùng bộ ba,
  chỉ đổi khi run trước đã có ít nhất một trận. Nên không câu được bằng bỏ run. Client không tự rút. Test: bỏ run trước trận, run mới ra cùng bộ ba.
  Chọn là action `pick_keystone(index)` (0..2), vào ActionLog, vào `ALLOWED_FNS` ở cả ba chỗ (3.10.9); index ngoài 0..2 hoặc chọn lần hai thì `false`.
- Lõi chủ chỉ cấp lúc bắt đầu run (stage 3), KHÔNG cấp giữa run. Pool lúc rút: nếu run đã có Concord từ trước (kho/Vault khởi đầu), bỏ Đồng Tộc.
- Giữa run: offer Lõi/relic khác (`core_offer`) PHẢI lọc cả hai chiều: đã có Đồng Tộc thì không đưa Concord; đã có Concord thì không đưa
  Đồng Tộc (đã loại ở pool đầu, nhưng ghi để test). (`t_core_keystones`, `t_flow_keystone_pick`)

#### 3.10.9 Stage không tin client (G14, G18) và ba chỗ ALLOWED_FNS

- Vấn đề: Worker không chạy luật, `depth_stage` nằm ở header client gửi, nên client sửa header thành 3 để có Lõi chủ trong ranked.
- Quyết định: với run ranked/online, `depth_stage` do SERVER ghi lúc `run_start` và trả về cho client; client không đặt. Server tính từ D1
  của tài khoản (N7): `runs_completed` = số run có dòng `run_finish` trong D1; stage 2 khi `runs_completed >= depth.stage2_runs` (1), stage 3 khi
  `>= depth.stage3_runs` (3); tài khoản cũ đã qua newcomer (`runs_with_battle >= 5`, server đếm từ D1) vào thẳng stage 3. Không còn `first_boss_won`
  (server không chạy luật nên không kiểm được "thắng boss"). Test Worker: `run_finish` là điều kiện duy nhất, không chỉ `run_start`.
  `depth_stage` là HEADER của run (cạnh `newcomer`), KHÔNG phải arg trong `epoch_args.json` (N4): nên không cần thêm vào từ vựng arg, và mọi request epoch sau
  đó mang header phải bằng giá trị server đã ghi, lệch thì `stage_mismatch`. Từ vựng đóng `epoch_args.json` thêm đúng hai thứ: key `rmode` (kind `reroll`) và kind
  `keystone`. Mã lỗi mới `pin_mismatch` và `stage_mismatch` phải có trong bảng mã Worker VÀ trong fake remote của `t_flow_online_reroll` (UI hiện thông báo,
  không treo); `t_depth_epoch_args_contract` kiểm cả ba (`rmode`, `keystone`, hai mã lỗi) và rằng `depth_stage` không bị coi là arg lạ.
  RunVerifier phía client từ chối action cần stage cao hơn header (T6).
- Run online: UI lấy stage DUY NHẤT từ giá trị server trả lúc `run_start` (N8), không đọc `MetaState`. Client có stage 3 offline mà server nói 1 thì UI ẩn
  nút như stage 1 và engine từ chối action stage cao. Test `t_flow_newcomer_gating`: meta cao, server thấp.
- Rủi ro còn lại, chấp nhận có lý do: người cố ý chơi hai run ngắn để mở stage 3 sớm. Stage chỉ mở thêm lựa chọn chứ không bỏ luật, và
  hai run hoàn thành là chi phí thật (mất thời gian), thấp hơn nhiều so với sửa header. Nếu Liam sợ, nâng `depth.stage3_runs`.
- Run offline/guest (không lên bảng): client tự tính từ `MetaState`, không ảnh hưởng ranked.
- `runs_completed` và `runs_with_battle` (offline/guest dùng bản client): ghi qua `SaveStore`, thêm vào `MetaState.reload_from_store()`. Xung đột cloud/guest sang tài khoản/đổi máy: lấy giá trị LỚN HƠN
  (boolean OR, số lớn hơn); không bao giờ hạ stage đã mở. Test đi qua `SaveStore`: ghi, reload, đổi tài khoản. (`t_bo_stage`, `t_worker_stage_mirror`)
- Action mới `wild_face`, `overcast`, `pick_keystone`, và nhánh `rmode` của `reroll_dice` phải có ở BA chỗ trong CÙNG một commit:
  `ActionLog.ALLOWED_FNS` (`action_log.gd` ~75, kèm danh sách chú thích đầu file), `ALLOWED_FNS` trong `worker/src/run_core.js` (~21),
  và nhánh `match` + dòng danh sách action cần engine (~161) trong `run_verifier.gd` (nhánh `reroll_dice` hiện chỉ đọc `args[0]`, `args[1]`;
  phải đọc `args[2]` = `rmode`). Có test so sánh ba danh sách. Bump `RULES_VERSION`; chạy `t_rules_version` MỘT lần ở cây chính trước merge
  (worktree dùng `AXIE_SKIP_RULES_FINGERPRINT=1` nên không đủ). Deploy Worker: hỏi Liam.

#### 3.10.10 Hold, Mặt Tạm trước reroll (G16 và các ca VỪA)

- Hold viên Nứt "rửa" Nứt (mặt cũ sang lượt sau, sạch Nứt, giá trị đầy đủ): chấp nhận, kèm ghi, vì cái giá là mất lần dùng viên đó lượt này.
  Tạo knob `hold.allow_cracked` = 1. Sim có bot Hold-anchor; nếu Expert dùng neo + rửa Nứt > 30% số lượt thì đặt knob = 0 (viên Nứt không Hold được).
- Gắn Mặt Tạm TRƯỚC khi tung lại các viên còn lại (viên có Mặt Tạm đứng yên làm neo): cho phép; sim phải thử cả hai thứ tự (4.2 là ước tính
  "Mặt Tạm sau reroll"). Nếu thứ tự neo mạnh quá: chỉ cho Mặt Tạm khi hết `reroll`, hoặc gỡ Mặt Tạm khi tung lại viên khác. Chưa đổi luật khi chưa có số.
- Neo bằng viên đã dùng (edge 8): giữ, chỉ theo dõi tần suất Expert dùng neo.
- Mặt Tạm slot Tai: UI chỉ gợi ý slot làm Bộ lớn lên và không gợi ý Tai non-cantrip; engine không cấm.

---

## 4. Formulas

### 4.1 Biến

| Biến | Nghĩa | Khoảng |
|---|---|---|
| `n` | số viên đủ điều kiện (3.2) | 0..5 |
| `size(s)` | số viên đủ điều kiện có part `s` (kể cả Mặt Tạm) | 0..5 |
| `bo_add(size)` | 0 nếu size<3; 0.50 / 1.00 / 2.00 cho size 3 / 4 / 5 | knob `bo.add_3/4/5` |
| `oc_add` | 0.50 nếu viên có Overcast, ngược lại 0 | knob `oc.add` |
| `part_add` | 0.25 nếu Bộ có part cao bậc (mục 11), ngược lại 0 | knob `part.hi_add` |
| `core_add` | tổng cộng từ Lõi chủ (mục 10) | 0..+0.75 |
| `M` | `min(1 + bo_add + oc_add + part_add + core_add, M_cap)` | 1.00..3.50 |
| `v0` | giá trị mặt sau bước 1-3 (mục 3.4) | 0..~30 |
| `v1` | `(v0 * round(M*100) + 99) / 100` chia nguyên | |
| `c` | tỉ lệ Nứt mỗi viên tung lại ở Liều | knob `crack.pct`, mặc định 30 |
| `h` | xác suất một viên tung lại rơi đúng part mong muốn | 1/6, hoặc 1/5 nếu Tai là cantrip |

Ví dụ: Bird dmg 4 trong Bộ ba (+0.50), có Overcast (+0.50), Bộ không có part cao bậc, không Lõi chủ:
`M = 2.00`, `v1 = (4*200 + 99)/100 = 8`.
Ví dụ cắt trần: Bộ năm (+2.00) + Overcast (+0.50) + part cao bậc (+0.25) = 3.75, cắt về `M = 3.50`, mặt dmg 6 cho `(6*350+99)/100 = 21`.
Ví dụ Nứt: Plant shield 5 bị Nứt: `v0 = ceil(5/2) = 3`; nếu thêm Overcast `M = 1.5`, `v1 = (3*150+99)/100 = 5`.

### 4.2 Xác suất ra Bộ (5 viên, mỗi viên rơi đều vào các part)

Hai bảng, vì Tai mang keyword `cantrip` nên tự dùng rồi tung lại; thực tế viên chỉ dừng ở 5 part (Miệng, Sừng, Lưng, Đuôi, Mắt).
Bảng "6 part" là giới hạn thấp, bảng "5 part" là gần thực tế. Sim phải đo lại bằng dữ liệu thật (có part Tai không phải cantrip).

**Lần tung đầu, không reroll (đếm trực tiếp trên 6^5 = 7776 và 5^5 = 3125 kết quả):**

| Kết quả | 6 part | 5 part |
|---|---|---|
| năm cùng part | 6/7776 = 0.077% | 5/3125 = 0.16% |
| đúng bốn cùng part | 150/7776 = 1.93% | 100/3125 = 3.20% |
| đúng ba cùng part | 1500/7776 = 19.29% | 800/3125 = 25.60% |
| **ba trở lên** | **21.30%** | **28.96%** |
| **bốn trở lên** | **2.01%** | **3.36%** |
| chỉ có đôi (tối đa 2) | 69.44% | 66.0% |
| không trùng gì | 9.26% | 3.84% |

(6 part: ba chính xác = 3+2 là 300 + 3+1+1 là 1200; 5 part: 3+2 là 200 + 3+1+1 là 600.)

**Sau reroll theo chiến thuật "giữ nhóm lớn nhất, tung lại phần còn lại":**

Công thức một bước: nếu giữ nhóm kích cỡ `k` và tung lại `r = 5 - k` viên, mỗi viên rơi đúng part với xác suất `h`, thì số viên rơi
đúng `~ Binomial(r, h)`. Ví dụ giữ ba, tung hai: `P(lên bốn trở lên) = 1 - (1-h)^2 = 11/36 = 30.6%` khi `h = 1/6`.
Giữ đôi, tung ba: `P(lên ba trở lên) = 1 - (5/6)^3 + 5/216 = 44.4%` (cộng 5/216 vì ba viên mới có thể tự thành Bộ ba ở part khác).

| Sau | Ba+ | Bốn+ | Năm | Ghi chú |
|---|---|---|---|---|
| 0 lần tung lại (6 part) | 21.3% | 2.0% | 0.08% | đếm trực tiếp |
| 1 lần miễn phí an toàn (6 part) | 54.1% | 13.2% | 1.26% | chính xác theo mẫu hình |
| 1 lần miễn phí an toàn (5 part) | 65.0% | 19.7% | 2.37% | chính xác theo mẫu hình |
| 2 lần, cả hai an toàn (6 part) | 74.3% | 29.1% | 4.6% | xấp xỉ, bỏ qua nhóm phụ |
| 3 lần, cả ba an toàn (6 part) | 85.7% | 44.8% | 10.0% | xấp xỉ |
| 3 lần, lần 2-3 là Liều 25% (6 part) | 79.8% | 36.5% | 6.9% | xấp xỉ, `h` hiệu dụng = (1/6)(0.75) |

Bảng xấp xỉ thấp hơn thật khoảng 1-2 điểm (bỏ qua việc các viên tung lại tự tạo nhóm khác). Đội thật dùng 5 part nên cộng thêm ~8-10 điểm.

**Mặt Tạm** nâng đúng một bậc, nên xác suất lượt đó có Bộ nếu bạn sẵn lòng trả 2 mana: ba+ = P(có đôi) = 90.7% (6 part), bốn+ = P(có ba) = 21.3%
(trước reroll). Nghĩa là Mặt Tạm gần như luôn dùng được, và "Bộ chắc chắn" chỉ có khi cộng một đôi sẵn có với 2 mana.

**Nứt:** `P(không viên nào Nứt khi tung lại k viên) = (1 - c)^k`: k=1: 75%; k=2: 56%; k=3: 42%; k=4: 32%. Kỳ vọng số viên Nứt `= k * c`.

### 4.3 Sức mạnh thêm vì Bộ (để định cỡ độ khó, trần trên cho đội toàn dmg)

Số "viên tương đương" thêm vào = `sum(Bộ) size * bo_add`, chia 5 để ra phần trăm tổng sức mạnh đội:

| Tình huống (6 part) | Viên tương đương thêm | Tăng sức mạnh |
|---|---|---|
| spam, không reroll | 0.37 | +7.5% (5 part: +10.6%) |
| giữ nhóm lớn nhất + 1 reroll | 1.22 | +24% |
| 3 reroll an toàn | 3.0 | +60% |
| 3 reroll, lần 2-3 Liều | 2.5 | +50% |

Đây là con số quan trọng nhất của doc: người chơi chase đủ lượt được thêm +50-60% sức mạnh, trong khi quái nền chỉ +25%. Nếu để nguyên,
Expert dễ hơn bản cũ, trái yêu cầu Liam. Con số thật thấp hơn (đội không toàn dmg, còn cần khiên, đã trừ viên Nứt, mana có hạn), nhưng
phải xử lý khi sim (mục 7 và mục 12 Q5): hạ `bo.scale`, hạ `max_total`, hoặc tăng Nứt, trước khi tăng quái.

### 4.4 Kinh tế mana (mỗi lượt)

Nguồn (faucet): mặt mana (Tai cantrip, thêm CONDUIT +1 ở Aqua, Lõi mana), Lõi Mỏ Mana (+1 khi ra Bộ).
Nơi tiêu (sink): reroll an toàn 2; Mặt Tạm 2; Overcast 3; relic active.
Mục tiêu đo: Expert tiêu >= 70% mana nhận được (không tích trữ mãi), Random tiêu bừa nên hết mana sớm. Nếu mana dư cuối trận ở Expert
> 40% nghĩa là sink còn thiếu; nếu Expert luôn hết mana ở lượt 1-2 nghĩa là faucet quá nghèo.

### 4.5 Độ khó nền

**Sửa lỗi đọc số:** `enemy_hp_mult` và `enemy_dmg_mult` cùng nhân `D`. Trong một cuộc đua (người chơi giết quái, quái giết người chơi) độ nguy hiểm tỉ lệ với `hp_mult x dmg_mult` = `D^2`, không phải `D`. Nên "quái +25%" thật ra là nguy hiểm x1.56, và rủi ro "Bộ +50-60% còn quái +25%" ở mục 12 bị thổi phồng: so đúng là sức mạnh người chơi x(1 + gain) với nguy hiểm x`D^2`.

Công thức định cỡ (đầu vào cho sim đầu tiên):

`khó_tương_đối = D^2 / (1 + gain_thực)`, với `gain_thực` ~ 0.4-0.5 x gain ở bảng 4.3 (bảng 4.3 là trần trên: đội toàn dmg, mana dư, không Nứt).

| Symbol | Type | Range | Description |
|--------|------|-------|-------------|
| `D` | float | 1.15-1.45 | hệ số quái nền (cả hp lẫn dmg) |
| `gain_thực` | float | 0.05-0.35 | sức mạnh người chơi tăng thực vì Bộ, ước lượng theo bot |
| `khó_tương_đối` | float | > 0 | > 1 nghĩa là khó hơn bản cũ; mục tiêu: Random/Spam >= 1.4, Expert 1.15-1.35 |

Ví dụ (`D` = 1.30, `bo.scale` 0.8): Random `gain_thực` ~ 0.06 thì 1.69 / 1.06 = 1.59 (winrate 20.6% xuống ~8%); Expert `gain_thực` ~ 0.30 thì 1.69 / 1.30 = 1.30 (28.6% xuống ~20%); khoảng cách ~ 12-13 điểm. Đây là ước lượng tay, chỉ để chọn điểm khởi động; sim quyết. Khoảng cách Expert-Random chỉ mở rộng nếu `gain` của Expert thật sự cao hơn Random (Bộ phải thưởng người giỏi), không do `D` (D thu hẹp cả hai).

**Bộ số khởi điểm (sim vòng 1):** `bo.scale` 0.8 (ba x1.4, bốn x1.8, năm x2.6), `bo.m_cap` 3.0, `crack.pct` 30, `reroll.max_total` 3, giá An toàn 2 rồi 3 mana, `D` = 1.30 (hp 1.30, dmg 1.30), part cao bậc +0.25 (stage 3). Thứ tự chỉnh ở 7.2.

---

## 5. Edge Cases

Mỗi mục ghi rõ chuyện gì xảy ra. "Test" là tên test cần có (mục 8).

**Số lượng viên**

1. **0 viên đủ điều kiện** (cả đội chết/ngủ/không tung): không có Bộ; `wild_face` và Overcast bị từ chối, không tốn mana. Trận kết thúc theo luật thua cũ. Test: `t_bo_groups`.
2. **1 hoặc 2 viên đủ điều kiện**: không thể có Bộ. `wild_face` bị từ chối nếu sau khi gắn vẫn `n < 3` (vô dụng, không tốn mana); UI ghi "cần ít nhất 3 viên".
3. **Đúng 3 viên đủ điều kiện** (hai Axie chết): Bộ ba khả thi (xác suất 1/36 lần đầu, 1/6 nếu Mặt Tạm đưa hai viên cùng part về part của viên thứ ba). Hệ số tính bình thường.
4. **Toàn bộ viên bị Nứt** (5 viên, xác suất 0.30^5 = 0.24% chỉ khi tung lại cả 5 bằng Liều): không có Bộ, mọi mặt có số còn nửa giá trị. Không có luật cứu; đó là cái giá của việc liều cả 5 viên. Test: `t_crack`.
5. **Nhóm 3+2**: chỉ nhóm ba là Bộ; nhóm đôi không có gì. Một lượt không thể có hai Bộ (5 viên).

**Dùng viên, reroll, undo**

6. **Mặt Tạm lên viên đã dùng**: bị từ chối (`wild_face` trả false, mana không đổi). Mặt Tạm lên viên Hold hoặc viên đã có Mặt Tạm: từ chối.
7. **Mặt Tạm chọn part của chính mặt thật**: từ chối (vô nghĩa). Mặt Tạm chọn part có sẵn 5 viên: từ chối.
8. **Reroll sau khi đã dùng một phần**: viên đã dùng không tung lại được (như hiện tại) nhưng VẪN đếm trong Bộ. `recompute_bo()` chạy lại; viên chưa dùng nhận hệ số mới. Viên đã dùng không bị tính lại hồi tố.
9. **Undo**: `use_die`, `wild_face`, `overcast`, `stash` có undo. Ảnh undo chứa `bo`, `cracked`, `wild_slot`, `overcast`, `wild_used`, mana. Reroll xoá ngăn xếp undo (trừ relic `safeReroll`); với `safeReroll`, undo đưa `reroll_k` về giá trị cũ nên reroll lại ra đúng kết quả cũ, kể cả Nứt. Test: `t_bo_undo`.
10. **Save/load giữa lượt**: `bo`, `cracked`, `wild_slot`, `overcast`, `wild_used`, `reroll_k`, `reroll_nonaid`, `reroll_paid_k`, `reroll_lock` (có `rsrc`), `depth_stage` nằm trong `_state_dict`. Sau load, `bo` đọc từ save, KHÔNG tính lại (vì chết giữa lượt không đổi Bộ). Test: so digest trước/sau save-load ở giữa lượt, lúc có Bộ, có Nứt, có Mặt Tạm.
11. **Replay (RunVerifier)**: action mới `wild_face(uid, slot)`, `overcast(uid)`, `reroll_dice(uids, aid, rmode)` vào ActionLog (key `rmode`, không phải `mode`); Nứt rút từ seed epoch nên replay ra đúng. Phải bump `RULES_VERSION` (t_rules_version sẽ đỏ trong cây chính nếu quên). Test: `t_bo_replay`, bảy tamper cũ của `t_replay` vẫn đỏ đúng chỗ, thêm tamper T1-T10 ở 8.1.
12. **Mana không đủ / mana âm**: mọi hành động kiểm `mana >= tổng giá` (giá gốc + phụ phí hook) TRƯỚC khi đổi state; không đủ thì trả false, không tốn gì. Mana không bao giờ âm; nếu relic rút mana về dưới 0 thì kẹp ở 0.
13. **Chọn "An toàn" khi mana < 2**: nút xám kèm lý do "cần 2 mana". "Liều" vẫn bấm được (miễn phí).
14. **Overcast và Mặt Tạm cùng viên**: cho phép cả hai (tổng 5 mana). `M = 1 + bo_add(part của Mặt Tạm) + 0.50`. Ví dụ Bộ ba + Overcast = 2.00.
15. **Bộ năm với Lõi nhân**: túi M cắt 3.50; rồi Resonance x1.15; rồi Lõi x1.5 với phần tăng tối đa +8; rồi cộng phẳng tối đa +10; rồi crit x2. Ví dụ mặt dmg 6: 21, LINK 25, Lõi x1.5 nên 33 (tăng 8, đã chạm trần), cộng phẳng +10 nên 43. Đỉnh này sim phải kiểm trên boss cuối. (Số danh nghĩa `bo.scale` 1.0, `m_cap` 3.5; với mặc định 0.8 / 3.0 túi M tối đa 3.0, đỉnh mặt dmg 6 thấp hơn 43. Test chạy cả hai, 8.1.)

**Loại mặt đặc biệt**

16. **Cantrip**: dùng lúc tung, trước khi chụp Bộ, nên cantrip không bao giờ có hệ số. Nếu `_resolve_cantrips` chạm `guard = 6` và còn mặt cantrip chưa dùng, viên đó vẫn đếm là viên bình thường (hiếm đến mức bỏ qua).
17. **Echo, multi, AoE**: một lần "dùng viên" dùng một giá trị `M`; Echo lần hai, từng đòn `multi`, và mọi mục tiêu của AoE đều dùng cùng giá trị đã nhân.
18. **Mặt mana, debuff, summon trong Bộ**: viên vẫn đếm vào kích cỡ nhóm nhưng không được nhân (3.4). UI phải ghi rõ trên viên đó "không nhân". Đây là chỗ người mới dễ hiểu nhầm nên có tooltip.
19. **Nứt trên mặt không có số**: viên vẫn bị Nứt (loại khỏi Bộ) nhưng không đổi hiệu ứng (debuff dựa trên keyword). Chấp nhận: Nứt chủ yếu là mất Bộ.
20. **Tự nổ (`selfkill`) trong Bộ**: viên chết sau khi dùng; Bộ lượt này không đổi; lượt sau `roll_all` tính lại.
21. **Thorns**: không bị Bộ nhân (nằm trong keyword), vẫn không trần. Test: `t_bo_order`.
22. **Plating, shield của quái, Charge**: chạy sau Bộ (bước 8). Charge so với sát thương thật sau Bộ.

**Hold, Concord, token**

23. **Hold**: viên Hold đếm Bộ lượt này, mang mặt cũ sang lượt sau và đếm trong chụp đầu lượt sau; Nứt và Mặt Tạm không mang theo. Mặt Tạm và Hold loại trừ nhau hai chiều.
24. **Concord**: mỗi class chỉ một viên đếm. Với đội thuần class, Bộ tối đa là "1 viên đếm", tức không ra Bộ. Đó là chủ ý: Concord đổi lấy độ đều, bỏ Bộ. Test: `t_bo_concord`.
25. **Viên thứ 6 ảo (Sixth Die), Egg, token triệu hồi**: không đếm, không nhận hệ số. Viên thứ 6 vẫn dùng bình thường ở giá trị thường.
26. **Viên ngủ, đóng băng**: ngủ không tung nên không đếm; đóng băng vẫn đếm dù không tung lại được. Viên `heavy` không tung lại được vẫn đếm.
27. **Hook `reroll_allowed` trả false** cho một viên: viên đó không tung lại nhưng vẫn đếm.

**Ngoài trận / đặc biệt**

28. **Stage thấp gọi hành động stage cao** (ví dụ client sửa): engine trả false, state không đổi. Test: `t_bo_stage`.
29. **Thắng/thua giữa lượt**: mọi action Bộ trả false sau khi `won or lost`.
30. **Raid ghost / tài khoản import không có dữ liệu part**: raid KHÔNG tắt Bộ (3.10.4): người tấn công có Bộ, quái ghost (phe `e`) không có. Mặt `blank` không đếm nên Axie import thiếu dữ liệu chỉ bớt cơ hội Bộ, không lỗi.
31. **Lõi Concord lẫn Lõi Đồng Tộc**: Đồng Tộc cần 3 viên cùng class trong Bộ, Concord chỉ cho đếm một viên mỗi class; hai Lõi này không bao giờ cùng cho hiệu lực (Đồng Tộc vô dụng khi có Concord). Pool Lõi chủ không rút Đồng Tộc nếu đã có Concord.

**Chiến thuật suy biến (Sirlin) và cách chặn**

32. **"Tung lại hết mọi thứ cho tới khi ra Bộ"**: vì các viên tung lại vốn cũng được dùng, tung lại gần như miễn phí, trừ khi viên bị tung là viên bạn cần (khiên) hoặc bị Nứt. Chặn: `max_total = 3`, `reroll.hard_cap = 4`, lần 2-3 phải trả (mana hoặc Nứt 30%), Expert phải có >= 30% lượt dừng ở lần 1 (mục 8). Nếu sim thấy Expert luôn Liều tối đa thì tăng Nứt, không thêm luật.
33. **Mặt Tạm mỗi lượt**: 2 mana + 1 lần/lượt + không áp lên viên đã dùng: tối đa tăng một bậc, và trả giá bằng Overcast. Mỏ Mana có vòng mana; đã chặn bằng cách không tính Bộ có Mặt Tạm vào +1 mana của Lõi (mục 10).
34. **Hold làm mỏ neo**: giữ một viên đúng part để dùng làm thành viên hai lượt. Cái giá thật là mất lần dùng viên đó lượt này. Giữ Lửa mới cho 2 viên.

**Chống lách (bổ sung sau QA 21/10; luật đầy đủ ở 3.10, ở đây chỉ ghi kết quả cụ thể)**

35. **Đổi ý sau khi thấy Liều** (Liều, thấy Nứt, undo hoặc nạp save lượt đó, bấm An toàn ở cùng `k`): `false`, state không đổi. Chỉ còn lần `k + 1` (3.10.2). Test: `t_bo_undo`, `t_reroll_epoch_pin`.
36. **Đổi danh sách viên ở cùng `k`**: engine `false`; Worker `pin_mismatch`. Tamper T9.
37. **Mặt Tạm lên viên Concord loại, hoặc viên ảo**: `false`, mana không đổi (3.10.5). **Viên có Mặt Tạm mất tư cách đếm do Concord đổi viên đếm**: `wild_slot` nằm im, không hoàn mana.
38. **Overcast lên viên frozen / mặt mana / `v0 = 0` / viên ảo**: `false`, không mất mana. **Viên Overcast bị tung lại hoặc Hold**: `false`. **Viên Overcast chết trước khi dùng**: mất cờ và mana (3.10.1).
39. **Tam Tấu nổ lần hai** (Bộ ba lên Bộ bốn sau reroll, hoặc Bộ khác trong cùng lượt): không nổ (`tt_fired`). **Nổ giết quái**: tính cho viên kích; thorn/`on_kill` chạy với `src` hợp lệ; `tt.cap` cắt sau pipeline. **Thorn của quái không phản lên viên kích khi nổ** (`from_burst`, N9, 3.10.6).
40. **Con Bạc Liều một viên**: không tính "Liều sạch", không phá các lần sạch trước. Cần >= 2 viên tung lại.
41. **Mỏ Mana undo rồi dựng lại Bộ** 20 vòng: mana ròng không tăng. Bộ toàn mặt không nhân (ba Tai non-cantrip): không trả +1.
42. **`c_thorn_shield` sau khiên Bộ năm**: thorn = `min(khiên chuyển / 2, thorn.shield_transfer_cap = 6)` cho MỖI lần chuyển, MỖI Axie (N5; không đọc khiên gốc). **Poison**: tối đa 8 mỗi mặt, áp cuối chuỗi sau bước 7 (N6); `stack_cap` = đỉnh bản cũ do sim đo (15 chỉ là số tạm).
43. **Tổng tung lại**: relic + Aid + free + Liều + An toàn không vượt `reroll.hard_cap` = 4; đạt cap thì `false`. Relic tặng lần free không ăn vào `max_total`: có relic +1 thì 1 gốc + 1 relic + 2 lựa chọn = 4; relic +2 thì vẫn 4 (N1, `reroll_paid_k`).
44. **Aid reroll**: không Nứt, không mana, không `max_total`, nhưng CÓ tính `reroll.hard_cap` (3.10.3). Cần Liam xác nhận.
45. **Mặt đổi bởi hiệu ứng sau lần chụp** (Loaded, `face_swap`, Chaos): gọi `recompute_bo()` (3.3 mục 5); không được để viên mang hệ số của mặt cũ.
46. **Stage khai gian**: server ghi stage lúc `run_start`; header lệch thì `stage_mismatch`; engine từ chối action cần stage cao (3.10.9). **Xung đột save/cloud của `runs_completed`**: lấy số lớn hơn, không hạ stage. **Online**: UI lấy stage từ server lúc `run_start`, không từ meta (N8). **Stage mở theo `runs_completed`** (run hoàn thành, `run_finish` trong D1): 1 run thì stage 2, 3 run thì stage 3 (N7).
47. **Lõi chủ rút/chọn lại** (bump sau): `keystone` seed pin theo (tài khoản, `runs_with_battle`) nên bỏ run trước trận không đổi được bộ ba (N10); chọn lần hai hoặc index ngoài 0..2 là `false`; offer giữa run lọc Concord/Đồng Tộc hai chiều.
48. **Khoá tung lại không khớp** (N2, N3): undo rồi đổi danh sách/kiểu/nguồn ở cùng `k` thì `false`, nút xám kèm lý do, không nhảy `k`; lối ra là Hoàn tác việc dùng/Hold viên rồi tung lại đúng danh sách cũ (3.10.2). **Biên làm tròn**: `v = 0` cho 0 (không Nứt, không nhân thành 1); `v = 1` Nứt còn 1; `M100` từ 100 (M luôn >= 1.00, Đồng Tộc cũng không hạ dưới 1.00) tới `bo.m_cap x 100`; Nứt trước rồi mới nhân. Mọi giá mana qua `maxi(0)`; action trả `false` thì mana và digest không đổi.

---

## 6. Dependencies

Chiều dữ liệu: A -> B nghĩa là A cung cấp cho B. "Hợp đồng" là thứ hai bên phải giữ.

| Hệ thống | Chiều | Hợp đồng |
|---|---|---|
| `combat_engine.gd` (roll_all, reroll_dice, can_reroll, _face_value, _state_dict, stash) | doc này -> engine | thêm `recompute_bo()`, `wild_face()`, tham số `mode`, trường `cracked/wild_slot/overcast/wild_used/bo`; `reroll.max_total` 4 xuống 3. Mọi số lấy qua `tune_knob`, không hardcode. |
| `damage_pipeline.gd` | engine -> pipeline | giữ nguyên thứ tự; hệ số `M` đã nằm trong `_face_value` trước pipeline. Không thêm tầng nhân trong pipeline. |
| `core_hooks.gd` / `relic_hooks.gd` | doc này -> Lõi | `FLAT_CAP = 10` không đổi, không tính `M`. Hook mới: `bo_core_add` (Lõi chủ cộng vào túi), `stash_cap` (có sẵn, Giữ Lửa dùng). `c_concord` đọc thêm: khi sở hữu, mỗi class chỉ một viên đếm Bộ. |
| Lõi Overcast (làn OC) | OC -> doc này | OC cung cấp action + cờ `overcast`; doc này cung cấp công thức `oc_add` trong túi M. Hai bên phải thống nhất 3.7 trước khi OC merge. |
| `action_log.gd`, `run_verifier.gd`, `RULES_VERSION` | doc này -> replay | action mới `wild_face`, `overcast`, `pick_keystone` + `rmode` của `reroll_dice` ghi vào log; ba danh sách `ALLOWED_FNS` khớp nhau (3.10.9); `t_rules_version` yêu cầu bump. |
| Worker (`worker/src/runs.js`, `run_core.js`, `epoch_args.json`) | doc này -> Worker | thêm key `rmode` (enum 0/1, kind `reroll`) và kind `keystone`; so `(rmode, uids)` với dòng pin, lệch thì `pin_mismatch`; tự ghi `depth_stage` lúc `run_start` từ D1, header lệch thì `stage_mismatch` (3.10.2, 3.10.9). Worker KHÔNG chạy luật (Q7). Deploy Worker: hỏi Liam. |
| `MetaState.gd`, `RunState.gd`, `SaveStore` | doc này -> meta | field `runs_completed` (bỏ `first_boss_won`); `depth_stage` tính ở đầu run; ghi qua `SaveStore`, thêm vào `MetaState.reload_from_store()`. |
| `axie_to_die.gd` | axie_to_die -> doc này | cung cấp `die[6]` theo SLOT_ORDER và `face.r` (mục 11). Không đổi file này. |
| Hold/stash (depth v3, `depth-v3-design.md` 3.2) | cùng sở hữu | Hold nền giữ nguyên; chỉ thêm: viên Hold đếm Bộ, Mặt Tạm loại trừ Hold. |
| Plating, Đòn Nạp, boss rhythm (depth v3 6.7) | engine -> doc này | chạy sau Bộ. Sim phải chỉnh lại ngưỡng sau khi có Bộ. |
| Onboarding (`onboarding-tutorial.md`) và UI (UI-03) | doc này -> UI | mục 9. UI không tự tính Bộ, chỉ đọc `bo` từ engine và `preview_damage`. |
| `part-tier-system.md` | doc này đọc | `face.r` là nguồn "part cao bậc". |
| Land raid (`land-v1-spec.md`, làn RV) | doc này -> RV | raid KHÔNG tắt Bộ: người tấn công có Bộ, ghost (phe `e`) không (3.10.4). RV chạy sim độ khó ghost sau khi có Bộ. |
| `c_thorn_shield`, poison (`core_hooks.gd`, `combat_tune.json`) | doc này -> Lõi | trần thorn mỗi lần chuyển mỗi Axie (không đọc khiên gốc); knob `thorn.shield_transfer_cap`, `poison.face_cap`, `poison.stack_cap` (3.10.7). |
| Lõi Sixth Die (`_spawn_phantom_dice`) | engine -> doc này | viên ảo có `custom_state.phantom`, không có `is_token`: lọc theo cờ đó (3.10.5). |

Backlink phải thêm (doc kia chưa nhắc doc này; việc của designer, CHƯA làm, nằm ngoài lượt vá này): `depth-v3-design.md` (mục Hold và reroll),
`onboarding-tutorial.md` (coach Bộ), `systems-index.md` (dòng mới), spec Overcast của làn OC (nhắc sửa theo 3.10.1).

---

## 7. Tuning Knobs

Tất cả nằm trong `assets/data/rules/combat_tune.json` (mục mới `bo`, `crack`, `wild`, `oc`, `part`, `depth`), đọc qua `tune_knob`.
Loại: Feel (cảm giác), Curve (đường cong sức mạnh), Gate (nhịp/mở khoá).

### 7.1 Knob hệ thống

| Knob | Mặc định | Khoảng an toàn | Loại | Ảnh hưởng và lý do |
|---|---|---|---|---|
| `bo.enabled` | 1 | 0/1 | Gate | công tắc cho raid ghost và khi cần tắt |
| `bo.add_3 / add_4 / add_5` | 0.50 / 1.00 / 2.00 | x0.6 đến x1.0 của mặc định | Curve | độ mạnh Bộ; số điểm xuất phát (ba x1.5, bốn x2, năm x3). Bảng 4.3 cho thấy gần như chắc chắn phải hạ. |
| `bo.scale` | 0.8 | 0.5 đến 1.0 | Curve | hệ số nhân chung lên ba `add`; một nút để quét trong sim. Khởi điểm 0.8 (ví dụ trong doc dùng 1.0 cho dễ tính) |
| `bo.m_cap` | 3.00 | 2.5 đến 4.0 | Curve | trần túi M; chặn Bộ năm + Overcast + part |
| `bo.phantom_counts` | 0 | 0/1 | Gate | viên thứ 6 ảo có đếm không (0 = không) |
| `reroll.free` | 1 | 1 | Feel | lần tung lại an toàn gốc |
| `reroll.max_total` | 3 | 2 đến 4 | Curve | tổng reroll thường; sim quyết (bảng 4.2) |
| `reroll.mana_cost_2 / mana_cost_3` | 2 / 3 | 1-3 / 2-4 | Curve | giá "An toàn" ở lần lựa chọn thứ nhất / thứ hai (`reroll.mana_cost` cũ đã có sẵn; tách làm hai) |
| `crack.pct` | 30 | 20 đến 40 | Curve | Nứt mỗi viên tung lại ở Liều; thấp thì Liều thành mặc định tối ưu (edge 32) |
| `difficulty.enemy_hp_mult` / `enemy_dmg_mult` | 1.30 / 1.30 | 1.15-1.45 mỗi cái | Curve | tách riêng được: hp quyết thời gian trận, dmg quyết áp lực mỗi lượt |
| `bot.*` (nhiều lần Liều, ngưỡng dừng) | do sim đặt | | Sim | tham số bot Expert/Spam/Random cho sim; ghi tên key khi code |
| Ngưỡng Đòn Nạp, Plating nền | giữ bản cũ | chỉnh sau sim | Curve | Bộ làm phá Nạp dễ hơn; ghi tên key trong `combat_tune.json` khi code |
| `crack.value_div` | 2 | cố định | Feel | giá trị Nứt = ceil(v/2); không quét |
| `reroll.hard_cap` | 4 | 3 đến 4 | Curve | tổng lần tung lại mỗi lượt, MỌI nguồn kể cả Aid/relic (3.10.3). Không nâng khi chưa sim (4 lần an toàn ~90% có Bộ) |
| `hold.allow_cracked` | 1 | 0/1 | Gate | cho Hold viên Nứt (rửa Nứt); đặt 0 nếu sim thấy Expert lạm dụng (3.10.10) |
| `thorn.shield_transfer_cap` | 6 | 4 đến 10 | Curve | trần thorn sinh từ khiên bởi `c_thorn_shield`, cho MỖI lần chuyển, MỖI Axie (không mỗi mặt; 3.10.7, N5) |
| `poison.face_cap` / `poison.stack_cap` | 8 / 15 | 6-10 / 12-20 | Curve | trần poison mỗi mặt sau `M` / tổng chồng trên một quái; không thấp hơn đỉnh hợp lệ của bản cũ |
| `mana.max` | giữ bản hiện có (nếu chưa có: 10) | 8 đến 12 | Gate | trần mana; mọi faucet (kể cả Mỏ Mana) kẹp ở đây |
| `depth.server_stage` | 1 | 0/1 | Gate | 1 = server ghi và kiểm `depth_stage` cho run online (3.10.9) |
| `wild.cost` | 2 | 1 đến 3 | Curve | giá Mặt Tạm |
| `wild.per_turn` | 1 | 1 đến 2 | Curve | số lần Mặt Tạm mỗi lượt |
| `oc.cost` / `oc.add` | 3 / 0.50 | 2-4 / 0.25-0.75 | Curve | giao cho làn OC; doc này chỉ giữ `oc.add` trong túi |
| `part.hi_add` | 0.25 | 0 đến 0.5 | Curve | mục 11; 0 = tắt |
| `part.hi_r` | 2 | 2 đến 3 | Gate | ngưỡng `r` coi là "cao bậc" |
| `depth.stage2_runs` | 1 | 1 đến 2 | Gate | số run hoàn thành (`run_finish`) để mở stage 2: Liều/Mặt Tạm (N7) |
| `depth.stage3_runs` | 3 | 2 đến 5 | Gate | số run hoàn thành để mở stage 3: Overcast, part cao bậc (Lõi chủ sau) (N7) |
| `reroll_paid_k` (biến, không phải knob) | | | | so với `reroll.max_total`; xem 3.5 (N1) |

Câu chữ luật trong UI và Codex phải sinh từ các knob này (ví dụ "ba viên x1.5" đọc từ `1 + bo.add_3 * bo.scale`), không viết cứng,
để sim đổi số thì chữ đổi theo. Test: `t_rule_text_from_knobs`.

### 7.2 Thứ tự chỉnh bằng sim

0. Trước hết kiểm engine: xác suất Bộ đo được khớp bảng 4.2 (±2 điểm), nếu lệch thì sửa engine, không chỉnh số.
1. Chạy bộ khởi điểm (4.5): `bo.scale` 0.8, `m_cap` 3.0, `crack.pct` 30, `max_total` 3, giá 2/3, D 1.30. Đọc kết quả cả bốn bot.
2. Expert > 23%: hạ `bo.scale` (0.7, rồi 0.6) hoặc tăng `crack.pct` (35). Expert < 18%: ngược lại, tăng `bo.scale` về 0.9. Chỉ đổi MỘT knob mỗi vòng.
3. Random/Spam còn > 10% / 12% trong khi Expert đã đúng: tăng `enemy_dmg_mult` (không động hp), vì bot bừa chết do áp lực, Expert tránh được áp lực bằng khiên/hồi. KHÔNG hạ Expert thêm.
4. Khoảng cách Expert-Random < 12: tăng thưởng cho kỹ năng (`bo.add_4/5` cao hơn `add_3`, hoặc Liều ít Nứt hơn) và hạ `D` để kéo Random lên là SAI hướng; kéo Random xuống bằng áp lực quái.
5. Khoá Lõi chủ bằng số ở 7.3 rồi chạy lại cả bốn bot cho từng Lõi chủ.
6. Bot khai thác (bắt buộc trước khi merge UI): Liều 1 viên rác hai lần với Con Bạc; Hold-anchor + rửa Nứt; Mặt Tạm TRƯỚC reroll;
   neo bằng viên đã dùng; Bộ năm + Overcast + Lõi x1.5 + LINK + cộng phẳng + crit (đỉnh thật so với 43 ở edge 15); poison/thorn đỉnh một lượt.

### 7.3 Knob Lõi chủ

| Lõi | Knob | Mặc định | Khoảng |
|---|---|---|---|
| Tam Tấu | `tt.pct_3/4/5` | 35 / 70 / 105 (% tổng giá trị gốc) | 25-50 / 50-100 / 75-150 |
| Tam Tấu | `tt.cap` (sát thương tối đa mỗi quái mỗi vụ nổ) | 20 | 12-30 |
| Con Bạc | `cb.crack_pct` | 35 | 30-45 |
| Con Bạc | `cb.step` / `cb.max` | +0.25 / +0.50 | 0.15-0.30 / 0.30-0.60 |
| Con Bạc | `cb.min_dice` (số viên tung lại tối thiểu cho "Liều sạch") | 2 | 2-3 |
| Tam Tấu | `tt.per_turn` (số vụ nổ mỗi lượt) | 1 | 1 cố định |
| Mỏ Mana | `mm.mana` / `mm.oc_cost` / `mm.oc_add` / `mm.mana_face` | +1 / 2 / +1.00 / -1 | 0-1 / 2 / 0.75-1.25 / -2..0 |
| Đồng Tộc | `dt.need` / `dt.plus` / `dt.minus` | 3 / +0.50 / -0.25 | 2-3 / 0.25-0.75 / 0..-0.5 |
| Giữ Lửa | `gl.cap` / `gl.carry_add` | 2 / +0.50 | 2 / 0.25-0.75 |

---

## 8. Acceptance Criteria

### 8.1 Chức năng (test tự động, thêm vào `godot/tools/run_tests.sh`, đổi con số sàn trong `technical-preferences.md` cùng commit)

| Test | Phải chứng minh |
|---|---|
| `t_bo_groups` | nhóm theo `fi`; ngưỡng 3/4/5; ngoài Bộ thì M = 1; token/viên ảo/Nứt/blank/chết không đếm; viên đã dùng và Hold có đếm; 0-2 viên không Bộ |
| `t_bo_timing` | `bo` chỉ đổi ở 4 thời điểm 3.3; dùng viên, chết giữa lượt, Hold không đổi `bo`; Bộ chụp sau cantrip |
| `t_bo_order` | (N11: hai lần chạy, xem khối "Hai bộ knob" dưới bảng) thứ tự bước 1-8 bằng số cụ thể; trần `poison.face_cap` áp sau bước 7 (N6); thorn không nhân; mana/debuff không nhân; làm tròn số nguyên đúng ví dụ 4.1 (5 x 1.5 = 8; 4 x 2.0 = 8; 3 x 1.5 = 5); trần M 3.5; trần +10 và +8 không đổi |
| `t_crack` | Nứt chỉ trên viên vừa tung lại ở Liều; không Nứt ở lần miễn phí/An toàn/Aid; Nứt = ceil(v/2); Nứt loại khỏi Bộ; Nứt hết ở lượt sau; rút RNG đủ một số mỗi viên |
| `t_reroll_modes` | chọn kiểu đúng theo `rerolls` và `reroll_paid_k` (`max_total = 3`); giá An toàn 2 + hook; stage 1 từ chối `rmode = 0`. N1: relic +1 thì tổng 4 = `hard_cap`, relic +2 vẫn 4, và FLOW đếm số nút tung lại thấy được. N2: khoá không khớp thì nút xám có lý do, lối ra bằng Hoàn tác. N3: đổi nguồn `rsrc` ở cùng `k` bị từ chối, sổ Aid đúng sau undo |
| `t_wild_face` | giá 2, một lần mỗi lượt, từ chối viên đã dùng/Hold/Nứt/cantrip/part của chính nó/part đã đủ 5; khoá tung lại và Hold; hết hiệu lực ở lượt sau; không đổi hiệu ứng mặt; mana không âm |
| `t_bo_overcast` | Bộ bốn + Overcast ra M = 2.50 ở `bo.scale` 1.0 (2.30 ở mặc định 0.8; không phải 3.0); Overcast + Mặt Tạm cùng viên; Overcast không áp mặt mana |
| `t_bo_concord` | có Concord thì mỗi class chỉ một viên đếm; không Concord thì đếm bình thường |
| `t_bo_undo` / `t_bo_saveload` | undo và save/load giữa lượt giữ nguyên `bo`, Nứt, Mặt Tạm, mana; reroll `safeReroll` undo ra cùng kết quả |
| `t_bo_replay` | RunVerifier replay một run có Bộ, Liều, Mặt Tạm, Overcast, Lõi chủ ra cùng digest; tamper T1-T10 (dưới) bị bắt ĐÚNG action bị sửa, không chỉ "digest cuối khác"; bảy tamper cũ của `t_replay` vẫn bị bắt |
| `t_bo_stage` | tính `depth_stage` đúng ba mức; migrate tài khoản cũ lên stage 3; action stage cao ở stage thấp trả false, state không đổi; đi qua `SaveStore` + `reload_from_store`; xung đột cloud lấy giá trị lớn hơn |
| `t_core_keystones` | mỗi Lõi chủ trong mục 10: số, thời điểm, giới hạn một lần; Tam Tấu một vụ mỗi lượt, cap sau pipeline, `src` thật và cả `src = null` không crash qua mọi hook; Con Bạc cần >= 2 viên; Mỏ Mana qua undo; Đồng Tộc/Concord lọc hai chiều; Giữ Lửa cap 2. N5: Bộ năm khiên rồi `c_thorn_shield`, thorn <= `thorn.shield_transfer_cap` mỗi lần chuyển mỗi Axie. N9: nổ trúng elite thorn, viên kích không mất HP. N10: bỏ run trước trận, run mới ra cùng bộ ba. (Lõi chủ là "bump sau": bộ test này chạy khi mục 10 được code.) |
| `t_rule_text_from_knobs` | câu luật hiển thị khớp knob |
| `t_rules_version` | vẫn xanh sau khi bump, chạy một lần ở cây chính |
| `t_bo_property_fuzz` | 200 seed x chuỗi action ngẫu nhiên hợp lệ: mana trong [0, `mana.max`]; M trong [1, `bo.m_cap`]; action false không đổi digest; `bo` trùng `recompute_bo()` sau 5 thời điểm của 3.3; digest live = replay = save-load mỗi bước |
| `t_bo_stacking_ceiling` | tổ hợp xấu nhất (Bộ năm + Overcast + part hiếm + Lõi x1.5 + LINK + cộng phẳng + crit) không vượt đỉnh ghi ở edge 15; poison/thorn đỉnh dưới `poison.*`/`thorn.*` |
| `t_reroll_epoch_pin`, `t_depth_epoch_args_contract` | fake remote và Worker từ chối `rmode` sai, `(turn, k)` cũ với `rmode`/`uids` khác (`pin_mismatch`); `epoch_args.json` có `rmode` và kind `keystone`, `mode` giữ enum `short/full`, `depth_stage` là header chứ không phải arg; mã `pin_mismatch`/`stage_mismatch` có trong bảng mã Worker và fake remote (N4); `node --test` thêm ca |
| `t_worker_stage_mirror` (Worker) | server ghi `depth_stage` lúc `run_start` từ `runs_completed` (dòng `run_finish` trong D1: 1 run thì stage 2, 3 run thì stage 3; run chỉ có `run_start` không tính; tài khoản cũ qua newcomer vào stage 3); header lệch trả `stage_mismatch` (N7). N8: meta client cao, server thấp thì UI và engine theo server |
| `t_bo_raid`, `t_hold_crack_cleanse`, `t_aid_reroll_depth` | raid: Bộ có cho `p`, không cho `e`; Hold viên Nứt: lượt sau sạch Nứt (theo knob); Aid theo luật Liam chốt, `hard_cap` đúng |
| `t_allowed_fns_sync` | ba danh sách `ALLOWED_FNS` (3.10.9) bằng nhau |

**Hai bộ knob (N11):** mỗi test có ví dụ M hoặc đỉnh bằng số (`t_bo_order`, `t_bo_overcast`, `t_flow_overcast_bo`, `t_bo_stacking_ceiling`) chạy HAI lần.
(1) Cố định knob rõ trong test: `bo.scale` = 1.0, `bo.m_cap` = 3.5, số danh nghĩa (ví dụ "5 -> 10, túi 2.0", Bộ bốn + Overcast 2.50, đỉnh 43 ở edge 15).
(2) Một bản chạy knob mặc định (0.8 / 3.0) đọc số từ knob rồi so với kỳ vọng tính trong test (Bộ ba 1.40, bốn 1.80 và 2.30 với Overcast, năm 2.60).
Cả hai bộ số ghi trong test. Tính `M100` theo công thức nguyên ở 3.4 (làm tròn từng đóng góp một lần), cấm so số thực. Cấm "sửa số cho xanh": test đỏ vì knob đổi
thì sửa knob cố định, không sửa kỳ vọng.

**Tamper T1-T10** (mỗi cái: RunVerifier báo lệch VÀ chỉ đúng action đó):
T1 đổi `rmode` của một reroll (An toàn thành Liều hoặc ngược lại); T2 đổi `slot` của `wild_face`; T3 `wild_face` thừa (lần 2 trong lượt);
T4 `overcast` lên viên mặt mana; T5 `overcast`/`wild_face` khi mana thiếu; T6 chèn `wild_face` vào run header stage 1;
T7 sửa header `depth_stage` lên 3; T8 xoá một `wild_face` khỏi log (digest lệch); T9 đổi `uids` của reroll sau Liều (Nứt khác);
T10 Aid reroll giả (`from_aid = 1` mà không có ledger Aid).

**Test FLOW (đi qua UI như người chơi bấm, bắt buộc; bài học relic "vô hình" và overlay Lõi):** dựng cảnh trận thật, đẩy input qua nút,
seed chọn trước; mỗi test chụp 1920x1080 và 1280x720 vào `production/qa/evidence/`; `t_ui_laws` xanh.

| Test | Người chơi thấy / làm gì |
|---|---|
| `t_flow_bo_visible` | tung ra 3 Sừng: chip part trên mọi viên, viền nhóm, banner "BA SỪNG" trong <= 0.5s, số "5 -> 8" khớp `preview_damage`, sát thương thật bằng số hiển thị; đôi: nét đứt "cần thêm 1"; token/viên ảo không viền |
| `t_flow_bo_upgrade` | tung lại lên Bộ bốn: banner mới, số nhảy |
| `t_flow_liều_crack_pct` | stage 2 chọn 2 viên: hai nút LIỀU/AN TOÀN, dòng "ít nhất 1 viên Nứt: 51%" đổi theo n; viên Nứt có vết nứt + chip "1/2"; sau khi tung không đổi được kiểu |
| `t_flow_wild_face` | Mặt Tạm: viên hợp lệ sáng, 6 chip kèm kết quả, mana -2, nút xám "1/1 đã dùng"; viên bị Concord loại không chọn được; Undo hoàn mana |
| `t_flow_overcast_bo` | "5 -> 10" với Bộ ba (túi 2.0, không 11.25); mặt mana/viên frozen xám có lý do; viên Overcast không tung lại/Hold |
| `t_flow_keystone_pick` | stage 3: ba thẻ trước node đầu, bắt buộc chọn, Lõi hiện ở HUD và hiệu ứng thấy được trên màn (số nổ Tam Tấu trên quái); chạy đủ 5 Lõi; lưu/nạp run giữ Lõi |
| `t_flow_newcomer_gating` | stage 1 không có Liều/Mặt Tạm/Overcast/Lõi chủ, coach C1-C4 một lần mỗi tài khoản; stage 2, 3 mở đúng; thắng boss giữa run không mở ngay; Codex khoá phần chưa mở |
| `t_flow_cheat_stage` | action stage cao ở stage thấp: false, state không đổi, UI không báo lỗi lạ |
| `t_flow_online_reroll` | online (fake remote) bấm Liều rồi An toàn: gửi `rmode` đúng; `pin_mismatch`/mất mạng hiện thông báo, không treo |
| `t_flow_run_replay` | bot bấm UI chơi trọn run có Bộ/Liều/Mặt Tạm/Overcast/Lõi chủ, RunVerifier 0 lệch |

**Xác suất (G19):** lần tung đầu kiểm bằng liệt kê chính xác 6^5 và 5^5 (khớp bảng 4.2 đúng từng số, không dung sai). Phần sau reroll kiểm bằng Monte
Carlo 1e6 seed cố định; hàng "chính xác theo mẫu hình" khớp trong ±0.3 điểm, hàng "xấp xỉ" trong ±2 điểm, và sau lần chạy đầu thì thay bảng 4.2 bằng số đo
(để bảng không còn là ước tính). Chỉ tiêu "±2 điểm" ở 8.2 hiểu theo đó.

**Cảm giác 0.5s (G21):** đo được, không còn "cảm giác": từ lúc engine phát sự kiện `bo_changed` tới frame banner hiện đầy đủ <= 30 khung hình ở 60 fps (0.5s), đo trong `t_flow_bo_visible`; banner giữ >= 0.6s.

### 8.2 Sim (2000 run mỗi bot, cùng seed, mỗi Lõi chủ chạy riêng cả 4 bot; bản cũ: random 20.6, spam 22.8, expert 28.6)

| Chỉ tiêu | Ngưỡng |
|---|---|
| Random thắng | <= 10% |
| Spam thắng | <= 12% |
| Expert thắng | 18% đến 23% |
| Expert trừ Random | >= 12 điểm, nhắm 15 (nếu Expert 18% thì Random <= 6%) |
| Lượt Expert chọn khác Greedy/Spam | >= 60% |
| Lượt Expert KHÔNG dùng reroll lần 2 | >= 30% |
| Expert dùng Mặt Tạm | trong 15-60% số lượt đủ điều kiện (không dưới: thừa; không trên: Bộ miễn phí) |
| Expert tiêu mana / nhận mana | >= 70% |
| Run Random chết ở act 1-2 | >= 40% |
| Boss cuối r18: Expert tới đó nhiều hơn Random | có (bản cũ: nửa số run mọi bot) |
| Mỗi Lõi chủ được chọn | 10% đến 25% khi Expert chọn tự do; chênh winrate Expert giữa các Lõi chủ <= 5 điểm |
| Xác suất Bộ đo được | khớp bảng 4.2 trong ±2 điểm (kiểm engine, không kiểm cân bằng) |
| Ghost raid (N12, làn RV, TRƯỚC merge Bộ) | sim 2000 raid, người tấn công có Bộ vs bản cũ: tỉ lệ người tấn công thắng không tăng quá 10 điểm (số khởi điểm, Liam duyệt); vượt thì chỉnh cấp độ ghost, không tắt Bộ (3.10.4). Kết quả ghi vào doc này |

"3-8 nước đi hợp lý mỗi lượt" bỏ ở vòng sim đầu (chưa đo được); dựa vào chỉ tiêu lượt Expert khác Greedy.

### 8.3 Playtest (người thật, ghi hình hoặc telemetry)

- 8 người chưa từng chơi, run 1: sau 2 lượt đầu ít nhất 6/8 nói lại được "Bộ là gì" trong một câu mà không hỏi lại (đối chiếu câu ở 3.0). Chấm do người quan sát.
- Run 1: tỉ lệ bỏ trước node 3 không cao hơn bản hiện tại quá 3 điểm.
- 8 người ở stage 2: ít nhất 6/8 nhìn thấy % Nứt trước khi bấm Liều lần đầu (telemetry: hover/đọc nút); 0 người nói "game cướp mất viên của tôi".
- Thời gian trung vị một lượt không tăng quá 15 giây so với bản hiện tại.
- Trong 200 run ghi lại, 0 lệch replay, 0 NaN/undefined trên số hệ số (`t_ui_laws` vẫn xanh).
- Cảm giác (không tự động hoá): khoảnh khắc ra Bộ có phản hồi rõ trong 0.5 giây (viền, chữ, số nhảy); đội Beast/Bird và đội Plant/Bug/Reptile cùng cảm thấy "có thể thắng bằng Bộ" (không có đội nào bị hệ thống thiệt).

---

## 9. Giao diện và dạy người chơi

UI theo `godot/CLAUDE.md` (UI3): cỡ chữ 16/18/24/32 (36 cho banner), vùng bấm >= 44 px, nút disabled phải nói lý do, màu luôn kèm glyph, mỗi màn một nút primary. Spec chi tiết giao `ux-designer`; doc này chốt nội dung và hành vi.

### 9.1 BỘ hiện thế nào

- Mỗi viên có một chip nhỏ ghi part (icon Miệng/Sừng/Lưng/Đuôi/Mắt/Tai), luôn hiện, để người chơi tự thấy "Sừng, Sừng, Lưng...".
- Các viên cùng part: viền nhóm + thanh nối giữa các viên (màu theo part kèm glyph part). Chỉ hai viên: nét đứt + chip "ĐÔI, cần thêm 1" (nhỏ, đôi không có thưởng).
- Khi ra Bộ: banner 36px "BA SỪNG x1.5!" (0.6 giây), viên trong Bộ nhảy nhẹ, số trên viên đổi từ "5" sang "5 -> 8" (số nhân hiện sẵn), âm "ting" tăng tông theo ba/bốn/năm. Lên bậc (ba lên bốn) có banner mới "BỐN SỪNG x2!".
- Viên ngoài Bộ nhưng loại không nhân được (mana, debuff) nằm trong nhóm: hiện "không nhân" trong tooltip (edge 18).
- Mọi số hệ số hiện qua `preview_damage` / `_face_value` (không tự tính trong UI). Dòng log: "BỘ BA SỪNG x1.5: Beast 5 -> 8, Aqua 3 -> 5, Bird 4 -> 6".

### 9.2 Reroll và LIỀU

- Lần miễn phí còn: một nút "TUNG LẠI (miễn phí)".
- Hết lần miễn phí còn lần trả: hai nút cạnh nhau. "LIỀU: miễn phí, 30% Nứt mỗi viên" và "AN TOÀN: 2 mana". Khi đã chọn n viên để tung lại, dòng phụ dưới nút Liều ghi "ít nhất 1 viên Nứt: X%" (X = 1 - (1 - crack.pct/100)^n; n=1: 30%, n=2: 51%, n=3: 66%). Số sinh từ knob, không viết cứng. Sau khi đã tung, hai nút này khoá với `k` đó (3.10.2); không có nút "đổi sang An toàn".
- Nút An toàn xám khi mana < 2, kèm lý do "cần 2 mana".
- Viên Nứt: vết nứt (hình, không chỉ màu) + chip "1/2"; số đã giảm; rời viền nhóm. Tooltip: "Nứt: còn nửa giá trị, không vào Bộ. Hết ở lượt sau."
- Nút Liều chỉ có ở stage >= 2; stage 1 chỉ có "TUNG LẠI THÊM: 2 mana".

### 9.3 MẶT TẠM và Overcast (xem trước bằng "->")

- Nút "MẶT TẠM 2" trên thanh hành động. Bấm: các viên hợp lệ sáng lên; bấm một viên: hiện 6 chip part bên dưới, mỗi chip kèm kết quả: "-> BỘ BA x1.5", "-> BỘ NĂM x3", hoặc "không đổi"; bấm chip để xác nhận (không có hộp xác nhận thứ hai, vì có undo).
- Viên đã gắn Mặt Tạm có huy hiệu "?" với glyph part đã chọn, và khoá icon tung lại.
- Nút "OVERCAST 3": chọn viên, hiện "5 -> 8" (kể cả hệ số Bộ đang có, đọc từ cùng hàm). Mặt mana: nút xám "không áp lên mặt mana".
- Mọi nút hiển thị giá và số lần còn lại ("1/1"); khi dùng hết: xám, lý do "đã dùng lượt này".

### 9.4 Coach run đầu (stage 1)

Coach theo sự kiện, không theo thời gian, không chặn bấm (không modal), mỗi bong bóng một lần cho cả tài khoản (cờ trong META), có nút bỏ qua, tối đa một bong bóng cùng lúc. Câu chữ ngắn, không văn phong sách.

| Bước | Kích hoạt | Nội dung |
|---|---|---|
| C1 | lần tung đầu của trận đầu tiên | trỏ vào hàng chip part: "Mỗi viên có một part. 3 viên cùng part thì thành BỘ và mạnh hơn." |
| C2 | lần đầu có một đôi | trỏ vào đôi và nút tung lại: "Có 2 Sừng rồi. Tung lại mấy viên còn lại để kiếm thêm Sừng." |
| C3 | lần đầu ra Bộ | banner Bộ + "Số trên mỗi viên trong Bộ đã nhân." |
| C4 | lần đầu hết lần tung miễn phí và còn mana | "Tung thêm tốn 2 mana." |

Stage 2 (run đầu sau khi mở): C5 lần đầu hết lần miễn phí: giải thích Liều ("Liều: miễn phí nhưng mỗi viên 30% Nứt"). C6 lần đầu có đôi và >= 2 mana: Mặt Tạm. C7 lần đầu >= 3 mana: Overcast. Một cái mỗi lượt.
Stage 3: màn chọn Lõi chủ lúc bắt đầu run: ba thẻ, mỗi thẻ gồm tên, glyph, câu luật một dòng (mục 10), một ví dụ một dòng, nhãn "hợp với". Bắt buộc chọn một.

### 9.5 Cái gì ẩn với người mới

Xem bảng stage ở 3.8. Ẩn nghĩa là: nút không vẽ ra, chip và tooltip của chúng không có, chữ Codex tương ứng khoá. Bộ và chip part luôn hiện từ run 1. Màn kết run đầu tiên có thắng boss act 1 hiện thẻ "Mới mở".

### 9.6 Codex và kiểm tra

Trang "Luật xúc xắc" trong Codex gom bảy câu ở 3.0 (sinh từ knob). `ux-designer` làm spec màn và `/ux-review`; `t_ui_laws` kiểm (viền token, vùng bấm, không cắt hàng). Chụp 1920x1080 và 1280x720.

---

## 10. Lõi chủ (5)

> **BUMP SAU (Liam 21/10/2026).** Mục này được TÁCH khỏi bump đầu (BỘ + LIỀU + MẶT TẠM + Overcast). Giữ nguyên thiết kế để làm sau; chưa code, chưa vào sim
> vòng đầu, stage 3 chưa có Lõi chủ. Seed `keystone` khi làm phải pin theo (tài khoản, `runs_with_battle`) để không câu bằng bỏ run (3.10.8, N10).

Chọn 1 trong 3 (rút ngẫu nhiên từ 5, seed của run, không lặp) lúc bắt đầu run từ stage 3; giữ suốt run, không bán, không đổi. Lõi chủ đổi LUẬT, không phải "+X% dmg". Số là điểm xuất phát (7.3).
Điều kiện chung: mọi hệ số của Lõi cộng vào túi M (không nhân chồng); nằm dưới `bo.m_cap`; không tính vào trần cộng phẳng +10.

### 10.1 Tam Tấu

- Một câu: "Mỗi Bộ ba trở lên nổ một lần, gây sát thương cho mọi quái bằng 35% tổng số gốc trên các viên trong Bộ (bốn viên 70%, năm viên 105%)."
- Luật: nổ ở lần dùng viên ĐẦU TIÊN của Bộ đó, một lần mỗi Bộ mỗi lượt. Tổng = cộng `value` gốc (trước hệ số) của các viên trong Bộ, mọi loại có số. Làm tròn lên. Tối đa `tt.cap` = 20 mỗi quái. Sát thương nổ đi qua `DamagePipeline` với `src` = viên kích nổ (không null, 3.10.6), `attack = false` (không Plating, không crit), `from_burst = true`; một vụ nổ mỗi LƯỢT (3.10.6 thắng câu "mỗi Bộ" ở trên); thorn quái không phản lên viên kích (N9).
- Ví dụ: Ba Sừng 5+3+4 = 12, nổ `ceil(0.35 x 12)` = 5 vào mọi quái.
- Hợp với đội thấy nhiều quái, Lõi AoE, thorn, độc. Yếu khi chỉ một quái (5 sát thương chỉ như một viên nhỏ).
- Không lấn át: nổ nhỏ, có trần, không tăng sát thương đòn đơn lên boss.

### 10.2 Con Bạc

- Một câu: "Mỗi lần Liều mà không viên nào Nứt, mọi Bộ lượt này +0.25 hệ số (tối đa +0.50); đổi lại Liều Nứt 35% mỗi viên."
- Luật: `core_add` = `0.25 x (số lần Liều sạch Nứt trong lượt)`, tối đa 0.50, chỉ cho viên đang nằm trong Bộ, tính lại ở mỗi `recompute_bo()`. Một lần Liều bị Nứt không xoá các lần sạch trước đó (chỉ không cộng thêm). Reset ở `roll_all()`.
- Số: Liều 2 viên sạch Nứt = 0.65^2 = 42% (thay vì 56%).
- Hợp với đội hay Liều, khiên (đỡ khi Nứt), hồi. Rủi ro thật: Nứt nhiều. Khoảnh khắc kịch tính nhất của nhóm ("gacha vui") nhưng sát thương có chủ đích.
- Không lấn át: tối đa +0.50 và chỉ khi liều hai lần; cái giá là Nứt nhiều hơn. Sim phải đo chênh Expert-Random của riêng Lõi này.

### 10.3 Mỏ Mana

- Một câu: "Lần đầu mỗi lượt bạn có Bộ tự nhiên bạn nhận +1 mana; Overcast viên trong Bộ chỉ tốn 2 mana và cộng +1.00 thay vì +0.50; đổi lại mặt mana của bạn -1."
- Luật: +1 mana khi `recompute_bo()` lần đầu trong lượt có một Bộ KHÔNG chứa viên Mặt Tạm (cờ `mana_bo_paid` mỗi lượt, tái xuất hiện không trả lại). Giá Overcast 2 và `oc_add` 1.00 chỉ khi viên Overcast nằm trong Bộ; ngoài Bộ giữ 3 mana, +0.50. Mặt mana -1 (tối thiểu 1) cho Axie của bạn.
- Chống vòng mana: Mặt Tạm 2 mana tạo Bộ nhưng Bộ đó không trả +1; reroll An toàn không giảm giá. Tối đa +1 mana mỗi lượt từ Lõi, trong khi Overcast rẻ chỉ mới 1 lần mỗi lượt.
- Hợp với Lõi mana, Overcast, summon. Yếu khi không ra Bộ.
- Không lấn át: lợi nhỏ về mana, đánh đổi bằng giảm mặt mana; Overcast vẫn 1 lần/lượt.

### 10.4 Đồng Tộc

- Một câu: "Bộ có ít nhất 3 viên cùng class thì +0.50 hệ số; Bộ không đạt thì -0.25."
- Luật: với mỗi Bộ, đếm class của các viên trong Bộ (Mặt Tạm đếm class thật của viên). Max count >= `dt.need` (3) thì `core_add` +0.50 cho mọi viên của Bộ đó; ngược lại -0.25. Không bao giờ để M < 1.00. Không rút nếu đang có Concord (31).
- Số: Bộ ba thuần class M = 2.00, Bộ ba tạp M = 1.25.
- Hợp với đội thuần hoặc gần thuần class, Lõi Huyết Thống/class. Phạt đội đa dạng; chính vì có phạt nên không chọn bừa.
- Không lấn át: M thuần class bị cắt 3.5 và mất sự đa dạng class (passive khác nhau). Sim theo dõi tỉ lệ chọn (đội thuần class có thể trội).

### 10.5 Giữ Lửa

- Một câu: "Bạn Hold được 2 viên thay vì 1, và viên Hold sang lượt sau mạnh thêm +0.50 hệ số khi dùng."
- Luật: `stash_cap` 2 qua hook có sẵn. Viên mang sang (`stash_carry`) có `core_add` +0.50 khi dùng (mặt dmg/shield/heal/poison), không cần nằm trong Bộ. Luật cũ giữ: không Hold lại một viên vừa mang sang. Hai viên Hold đều đếm Bộ lượt hiện tại và lượt sau.
- Số: dmg 6 giữ sang lượt sau, M = 1.5, thành 9.
- Hợp với Đòn Nạp, Hồi Ngắt, boss có nhịp (giữ cho đúng lượt). Yếu act 1 (bỏ nhịp), mạnh boss.
- Không lấn át: giữ hai viên là mất hai lần dùng lượt này; tỉ lệ chọn mong đợi >= 10% dù yếu ở act 1.

### 10.6 Bảng so để chặn "một Lõi trội"

| Lõi | Mạnh nhất khi | Bẫy | Lõi dễ thành trội nhất nếu sai số |
|---|---|---|---|
| Tam Tấu | 3+ quái | một quái thì nhỏ | không |
| Con Bạc | liều hai lần | Nứt nhiều | nếu `cb.crack_pct` quá thấp |
| Mỏ Mana | ra Bộ đều | mặt mana yếu | nếu vòng mana (3 trên) lọt |
| Đồng Tộc | đội thuần class | đội đa dạng bị phạt | khả năng cao nhất (đội thuần) |
| Giữ Lửa | boss | act 1 chậm | không |

Chỉ tiêu: mục 8.2 (chọn 10-25%, chênh winrate <= 5). Nếu Đồng Tộc trội: hạ `dt.plus` xuống 0.35 trước khi bàn thêm luật.

---

## 11. Part lv1 vs lv2 trong BỘ

Liam muốn Bộ tạo khác biệt giữa part cấp thấp và part cao cấp. Kiểm game hiện có (20/10):

- Không có "level part" trong luật. `axie_to_die.gd` `build()` không đọc field `level` hay `evolve`; trường `"tier": 1` trên đơn vị là giá trị cố định.
- `AxiePartDescriptor.level` (addon `axie_mixer_3d`) tồn tại nhưng chỉ chọn model L1/L2 để vẽ (tên asset `S%02d_%s%02d_L%d_%s`), mặc định 1, không đi vào luật. Truy vấn API
  (`axie_api.gd`) chỉ lấy `parts { id name class type specialGenes }`, KHÔNG lấy level.
- Thứ gần nhất có thật: mỗi mặt đã có `r` (độ hiếm, 0 đến 4) do `resolve_face` tính từ bậc part (4 bậc, `part-tier-system.md`) cộng `r_bonus(sg_tier_eff)`
  của special gene (nấc 0-7: normal, summer, ..., origin, mystic, agamogenesis). Axie import vẫn có `r` vì `specialGenes` có trong truy vấn.
  Part thiếu dữ liệu dùng `fallback_face` với `r` sàn thấp.
- Level-2 thật của Axie (Evolution) nằm ở season S7 trong `bloodline-system.md`: chưa có data, 36 part, content mới hoàn toàn. Chưa làm.

Hai cách, đều đơn giản:

- **A (khuyến nghị): "Bộ có part hiếm thì mạnh hơn."** Nếu Bộ có ít nhất một viên có mặt `r >= 2`, Bộ đó +0.25 hệ số (một lần mỗi Bộ, không cộng dồn theo số viên). Cộng vào túi M như mọi thứ khác. Ví dụ: Ba Sừng thường M = 1.50; Ba Sừng có một Sừng hiếm M = 1.75.
  Vì sao chọn: một câu giải thích được, không đổi xác suất ra Bộ (nên sim không bị đảo), chạy trên dữ liệu có thật cho cả Axie import, không cần level từ API.
  Rủi ro: nếu phần lớn mặt đội đã `r >= 2` thì thành +0.25 cố định (hết khác biệt); phải đo phân bố `r` theo act.
- **B: "Part hiếm đếm như hai viên."** Một viên `r >= 2` đếm 2 khi tính kích cỡ nhóm (tối đa một viên đếm đôi mỗi nhóm). Khác biệt rõ hơn, nhưng đổi xác suất Bộ (Bộ ba chỉ cần hai viên khi có một viên hiếm), dễ thành "Bộ chắc chắn" với đội toàn part hiếm, và UI khó giải thích ("viên này đếm 2").

Cách C (không làm bây giờ): chờ dữ liệu level thật, khi đó `part.hi_r` đổi thành "lv2" và nguồn là field level thêm vào truy vấn API. Không cần đổi luật.

Axie import không có level: không ảnh hưởng, vì luật đọc `r` chứ không đọc level. Axie import với special gene hiếm (ví dụ origin, mystic) có `r` cao nên được `part_add`.

Dữ liệu cần xác nhận trước khi sim (Q2 mục 12): ngưỡng "r >= 2" đúng nghĩa Epic trở lên (quy mô 0-4 là Common/Rare/Epic/Legendary/Mythic chưa kiểm).

---

## 12. Câu hỏi cho Liam và rủi ro

Điểm rủi ro nhất: **Bộ nâng trần của MỌI bot (kể cả bot bừa) và người chase đủ ba reroll được +50-60% sức mạnh (bảng 4.3), trong khi
quái nền chỉ +25%.** Nghĩa là Expert có thể DỄ hơn bản cũ, trái yêu cầu "khó hơn". Cách xử lý đã chuẩn bị: hạ `bo.scale`, giảm `max_total`,
tăng Nứt, rồi mới tăng quái. Cần sim sớm, trước khi làm UI.

Rủi ro thứ hai: luật reroll "gần như miễn phí vì viên tung lại vốn cũng được dùng" (edge 32). Lần 2-3 phải thật sự có giá.

Câu hỏi cần Liam quyết (khuyến nghị nằm trong ngoặc):

**Đã chốt mặc định (reviewer 21/10, Liam đổi được bất cứ lúc nào):**

- Q1 cộng một túi, không nhân chồng (3.4, 3.7; làn OC sửa nếu đang nhân x1.5 riêng).
- Q2 part cao bậc: cách A (+0.25, `r >= 2`), chỉ từ stage 3; vẫn phải đo phân bố `r` và kiểm `r >= 2` = Epic trở lên trước sim.
- Q3 viên thứ 6 ảo không đếm Bộ (`bo.phantom_counts = 0`).
- Q4 viên Hold có đếm Bộ lượt này.
- Q7 Worker: chỉ kiểm hash luật + cấp seed epoch, KHÔNG chạy luật. Hệ quả: (a) Nứt và mọi ngẫu nhiên mới (Lõi chủ rút qua kind `keystone`) phải rút từ seed epoch, client không tự rút; (b) Worker không cần code Nứt/Mặt Tạm, chỉ nhận `rmode` (key mới, KHÔNG phải `mode`) và `uids`, khoá chúng theo pin (3.10.2); (c) `RULES_VERSION` phải bump để hash đổi; (d) SỬA so với bản trước: `depth_stage` KHÔNG còn do client khai; server ghi lúc `run_start` từ D1 và kiểm header (3.10.9); rủi ro còn lại (chơi hai run để mở sớm) chấp nhận có lý do ở đó. Không deploy Worker nếu chưa hỏi Liam.
- Q8 Tai là cantrip: chấp nhận, coi như 5 part (ba+ lần đầu ~29%).

**Còn 5 câu thật sự cần Liam quyết (gộp từ danh sách G; các G khác designer đã tự quyết ở 3.10):**

1. **Giá reroll lần 2-3 (Q5 cũ):** `max_total` 4 xuống 3; An toàn 2 mana rồi 3 mana; Liều Nứt 30%. Khuyến nghị: chấp nhận (người mới mất một lần tung trả mana, đổi lại mana có nghĩa và chase 3 lần không còn "gần miễn phí").
2. **Mở dần (Q6 cũ):** stage 2 mở Liều/Nứt + Mặt Tạm khi thắng boss act 1; stage 3 mở Overcast, part cao bậc, Lõi chủ sau 2 run. Tài khoản cũ vào thẳng stage 3, tức nhận 5 thứ mới cùng lúc. Khuyến nghị: vào stage 3 nhưng coach từng cái theo sự kiện (9.4), không chặn. Hoặc cho tài khoản cũ đi stage 2 trước.
3. **Phạm vi:** làm 5 Lõi chủ trong bump này, hay ra Bộ + Liều + Mặt Tạm + Overcast trước, sim xong khoá độ khó rồi mới thêm Lõi chủ? Khuyến nghị: tách. Mỗi Lõi chủ phải chạy lại 4 bot, làm chậm bước khoá độ khó.
4. **Bộ số khởi điểm khó hơn (4.5):** `bo.scale` 0.8 (ba x1.4, bốn x1.8, năm x2.6) thay vì x1.5/x2/x3, quái x1.30 cả hp lẫn dmg. Khuyến nghị: chấp nhận làm điểm sim vòng 1, đổi theo sim.
5. **Aid reroll (G4):** Aid là tài nguyên mua được. Luật tạm: Aid reroll an toàn (không Nứt, không mana, không tính `max_total`) nhưng CÓ tính `reroll.hard_cap` = 4 (3.10.3). Rủi ro P2W ranked: người có nhiều Aid ra Bộ chắc hơn. Chọn: (a) luật tạm (khuyến nghị: Aid chỉ lấp lần trống, cap chặn vô hạn); (b) Aid tính cả vào `max_total` (yếu hơn, ít P2W); (c) Aid tắt trong ranked.

Ý tưởng để sau (không làm trong bump này), xem tiếp ở "Ghi chú reviewer" cuối doc: Sảnh theo slot (Lõi Cầu Thang), Cược khai báo Bộ, Đổi mặt, Nóng/Lạnh, thưởng đội hình hàng trước/sau, Ascension thêm Sảnh hoặc Cược như luật mới thay vì +HP.

---

## Ghi chú reviewer (systems-designer, 21/10/2026)

Đã sửa thẳng trong doc: bảng 3.0 (rút gọn, đếm khái niệm), 3.5 (giá reroll 2/3), 3.7 (chốt cộng một túi), 3.8 (dời Overcast và part cao bậc xuống stage 3), 4.5 (công thức độ khó + bộ số khởi điểm), 7.1/7.2 (knob và thứ tự chỉnh), mục 12 (còn 4 câu).

Bất đồng và điểm cần để ý:

1. **Rủi ro "Bộ +50-60% còn quái +25%" bị đọc sai.** HP và dmg quái cùng nhân D nên độ nguy hiểm là D^2 (1.25 thành 1.56). Rủi ro có thật nhưng nhỏ hơn doc viết. Mặt khác 1.25 vẫn thiếu cho Random/Spam, vì họ chỉ nhận ~+6-10% từ Bộ. Bộ số khởi điểm ở 4.5 là ước lượng tay (hệ số `gain_thực` 0.4-0.5 lần bảng 4.3 là phỏng đoán chưa đo), sim vòng 1 mới là bằng chứng.
2. **Khoảng cách Expert-Random >= 12 là chỉ tiêu khó nhất.** D thu hẹp cả hai bot, chỉ thưởng kỹ năng mới mở khoảng cách. Nếu sim cho khoảng cách < 12 khi mọi mục khác đúng, cần Bộ thưởng cao hơn ở bốn/năm (tức khó ra, chỉ Expert chase tới), không phải thêm quái.
3. **Concord (5 class khác nhau là chuẩn) và đội thuần class:** edge 24 nói đội thuần class không ra Bộ. Đội thuần class là đội phổ biến để chơi Đồng Tộc. Hai Lõi này mâu thuẫn tới mức pool Lõi phải lọc (edge 31); sim lẫn playtest cần kiểm đội nào thiệt.
4. **Stage 2 và Mặt Tạm:** Mặt Tạm vẫn phải học cùng Liều; nếu playtest thấy quá tải, dời Mặt Tạm xuống stage 3 (không phải tăng khái niệm ở stage 2).
5. **Bảng 4.2/4.3 là ước tính**, chưa phải sim. Chỉ tiêu "Bộ đo được khớp ±2 điểm" kiểm engine, không kiểm cân bằng; chạy nó trước, trước khi đọc winrate.
6. **Số danh nghĩa x1.5/x2/x3 trong ví dụ** không khớp bản khởi điểm (x1.4/x1.8/x2.6). Đã ghi ở 3.0 và 7.1; khi code, test ví dụ phải đọc từ knob.
7. **8 mục chuẩn đủ.** Thiếu nhẹ: tên key cụ thể cho bot và ngưỡng Nạp/Plating (đã thêm hàng, tên key để điền khi code); acceptance 8.2 chưa có chỉ tiêu cho lần Liều 3 (giá 3 mana): thêm vào `t_reroll_modes` khi code.

Ý tưởng thêm (một dòng, không làm): coach C4 nên nhắc cả giá 3 mana ở lần tung thứ ba.

---

## Bảng G# đã xử lý ở mục nào (vá QA 21/10/2026)

| G | Chủ đề | Quyết định | Mục |
|---|---|---|---|
| G1 | Overcast trong túi M | +0.50 trong túi, không nhân riêng; từ chối frozen, v0 = 0, viên ảo | 3.4, 3.7, 3.10.1, edge 38 |
| G2 | key `rmode`, xung đột enum `mode` | key mới `rmode` (0/1), chỉ kind `reroll`; sửa `epoch_args.json`, fake remote, `KINDS` | 3.5, 3.10.2 |
| G3 | nhìn trước đổi ý Liều/An toàn, save/load | khoá `(rmode, uids)` theo `(turn, k)` ở engine và Worker; không undo xoá được; save giữ | 3.10.2, edge 35-36, T1, T9 |
| G4 | Aid reroll | luật tạm: an toàn, không tính `max_total`, tính `hard_cap`; ghi rủi ro P2W | 3.10.3, edge 44, **CẦN LIAM (câu 5)** |
| G5 | ghost raid | sửa tiền đề: người tấn công có Bộ, ghost (phe `e`) không; bỏ `bo.enabled = 0` ở raid | 3.2, 3.10.4, edge 30, mục 6 |
| G6 | viên ảo Sixth Die | lọc theo `custom_state.phantom`; không đếm/Mặt Tạm/Overcast | 3.2, 3.10.5 |
| G7 | Mặt Tạm vs Concord | từ chối viên bị Concord loại; thứ tự Concord rồi `wild_slot` | 3.6, 3.10.5, edge 37 |
| G8 | Overcast + reroll/Hold | viên Overcast không tung lại, không Hold, hai chiều | 3.10.1, edge 38 |
| G9 | Tam Tấu | một vụ nổ mỗi lượt, cap sau pipeline, `src` thật, `from_burst` | 3.10.6, edge 39, 7.3 |
| G10 | Con Bạc | cần >= 2 viên tung lại (`cb.min_dice`) | 3.10.6, edge 40, 7.3 |
| G11 | thorn/poison nhân Bộ | thorn trần mỗi lần chuyển mỗi Axie (`thorn.shield_transfer_cap` 6, sửa ở N5); poison `face_cap` 8 cuối chuỗi, `stack_cap` theo sim (N6) | 3.10.7, edge 42, 7.1 |
| G12 | Mỏ Mana | `mana_bo_paid` vào state/undo/save; Bộ cần mặt nhân được; `mana.max` | 3.10.6, edge 41, 7.1 |
| G13 | Lõi chủ epoch kind | kind mới `keystone`, pin theo run, `pick_keystone(index)` | 3.10.8, edge 47 |
| G14 | stage khai gian | server ghi `depth_stage` lúc `run_start`, header lệch `stage_mismatch`; rủi ro còn lại có lý do | 3.10.9, edge 46, mục 12 Q7 |
| G15 | Concord vs Đồng Tộc giữa run | lọc `core_offer` hai chiều; Lõi chủ chỉ cấp đầu run | 3.10.8, edge 47 |
| G16 | Hold rửa Nứt, Hold neo | chấp nhận có ghi, knob `hold.allow_cracked`, bot Hold-anchor | 3.10.10, 7.1, 7.2 |
| G17 | tổng lần tung lại gồm relic | `reroll.hard_cap` = 4, mọi nguồn | 3.10.3, edge 43 |
| G18 | mất/lệch `runs_completed` (trước là `first_boss_won`, N7) | lấy số lớn hơn; qua `SaveStore` + `reload_from_store` | 3.10.9, edge 46, `t_bo_stage` |
| G19 | bảng xác suất xấp xỉ vs ±2 | liệt kê chính xác lần đầu; Monte Carlo 1e6 phần sau; thay bảng bằng số đo | 8.1 (khối Xác suất) |
| G20 | trạng thái "chưa có code", backlink | cập nhật đầu file; danh sách backlink ghi ở mục 6 (CHƯA làm trong doc kia) | đầu file, mục 6 |
| G21 | cảm giác 0.5s không đo được | `bo_changed` tới banner <= 30 khung, đo trong `t_flow_bo_visible` | 8.1 (khối 0.5s) |

### Bảng N# (QA vòng 2, 21/10/2026: `production/qa/dice-depth-v4-qa-plan.md` mục 6)

| N | Chủ đề | Quyết định | Mục |
|---|---|---|---|
| N1 | relic free ăn vào `max_total` | biến riêng `reroll_paid_k` chỉ đếm Liều/An toàn; relic/Lõi/Aqua/Aid chỉ vào `hard_cap` | 3.5, 3.10.3, edge 10, 43, 8.1 `t_reroll_modes` |
| N2 | soft-lock khoá + undo | `false` + nút xám có lý do, lối ra bằng Hoàn tác; không nhảy `k` (tránh câu seed) | 3.10.2, edge 48 |
| N3 | đổi nguồn trả (Aid/free) sau khi thấy kết quả | khoá thêm `rsrc` (chỉ engine/save, không vào log/Worker); sổ Aid hoàn theo undo | 3.10.2, edge 10 |
| N4 | từ vựng `epoch_args.json`, mã lỗi | `depth_stage` là header, không phải arg; thêm `rmode`, `keystone`; mã `pin_mismatch`, `stage_mismatch` vào Worker + fake remote | 3.10.9, 8.1 |
| N5 | `c_thorn_shield` không đọc khiên gốc được | trần mỗi lần chuyển, mỗi Axie: `thorn.shield_transfer_cap` 6 | 3.10.7, edge 42, 7.1 |
| N6 | vị trí trần poison | `face_cap` sau bước 7, trước pipeline; `stack_cap` = đỉnh bản cũ do sim đo | 3.4, 3.10.7, edge 42 |
| N7 | `first_boss_won` server không kiểm được | stage theo `runs_completed` (`run_finish` trong D1): stage 2 từ 1 run, stage 3 từ 3 run; bỏ `first_boss_won`; tài khoản cũ vào stage 3 | 3.8, 3.10.9, edge 46, 7.1 |
| N8 | hai nguồn stage | run online lấy stage chỉ từ server | 3.10.9, edge 46, 8.1 |
| N9 | Tam Tấu bị thorn quái phản | `from_burst`: thorn quái không phản lên viên kích | 3.10.6, edge 39, 10.1 |
| N10 | câu bộ ba Lõi chủ bằng bỏ run | mục 10 tách sang "bump sau"; seed `keystone` pin theo (tài khoản, `runs_with_battle`) | 3.10.8, mục 10, edge 47 |
| N11 | số cũ/knob trong test | mỗi test chạy knob cố định (1.0/3.5) và knob mặc định (0.8/3.0); `M100` làm tròn từng đóng góp | 3.4, 8.1 (khối "Hai bộ knob"), edge 15 |
| N12 | raid có Bộ, ghost không đổi | DoD: sim ghost của làn RV trước merge Bộ | 3.10.4, 8.2 |

Các lỗ hổng QA không mang số G cũng đã xử lý: viên ảo/`is_token` (3.10.5), thorn qua khiên và poison (3.10.7), Mặt Tạm trước reroll,
slot Tai, Egg nở (3.10.5, 3.10.10), mặt đổi sau chụp (3.3 mục 5), mana âm/trần (edge 48, `mana.max`), biên làm tròn (edge 48),
Overcast + reroll (3.10.1), tổng tung lại (3.10.3), khoá `uids` fishing (3.10.2).
Còn mở, không thuộc GDD: sửa code Overcast ở `depth/OC` theo 3.10.1; cập nhật `t_flow_liều_crack_pct` của QA plan sang 30% (30/51/66).

