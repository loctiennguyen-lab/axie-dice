# Đột biến combo + Lõi chủ v1: bản hợp nhất (đề xuất, chờ Liam duyệt)

Ngày 21/10/2026. Chưa sửa code, chưa đổi knob, chưa commit. Bản này thay cho hai bản viết song song:
`design/proposals/keystones-v1.md` (6 Lõi chủ) và `design/proposals/combo-mutation-brainstorm.md` (hướng B). Phần nào hai bản cũ
còn đúng mà ở đây không nhắc lại (luật chọn bộ ba theo seed, chống câu bộ ba, các test chống lách của Lõi chủ) thì vẫn lấy theo
`keystones-v1.md` mục 2 và 4. Chỗ nào lệch thì lấy bản này.

Phản hồi Liam sau b1393: "chưa đủ hay, còn RỜI RẠC, thiếu ĐỘT BIẾN khi chọn được combo Lõi đặc biệt". Liam ghét nội dung vô hình
và độ phức tạp làm người mới bỏ cuộc. Độ khó đang đúng mục tiêu, phải giữ.

Luật nền đang chạy (RULES `-r`): BỘ ba/bốn/năm ×1.3 / ×2.2 / ×2.6, `m_cap` 3.0; Overcast 2 mana, +0.5 cho cả BỘ, 1 lần/lượt (stage 3);
Mặt Tạm chỉ 3→4, 2 mana, 1 lần/trận; Liều Nứt 30%; An toàn 1 mana rồi 3 mana; Hold 1 viên; `enemy_dmg_mult` 1.55; 14 combo trong
`core_combos.json`. Mana nhận ~1.5/lượt, trong đó mặt mana ~0.6/lượt (`v4-mana-decisions.md` Vòng 2). Sim: expert 18.8, random 11.0,
spam 10.5, free_hold 10.5.

Mọi số ở đây là số tay để chọn hướng. Sim quyết.

## 1. Mô hình 2 tầng (cộng một bước thưởng)

Một ý xuyên suốt: **mỗi Lõi chủ là một "nhà"**. 14 combo chia vào 6 nhà, mỗi nhà đúng một Lõi chủ. Người chơi không phải học thêm
khái niệm "gia đình": thẻ combo và thẻ Lõi thường chỉ mang dấu (icon) của Lõi chủ chủ nhà.

| Tầng | Một câu luật | Khi nào | Lưu state? |
|---|---|---|---|
| (a) **Lõi chủ** = trục của run | Đầu run chọn 1 trong 3 Lõi chủ: nó đổi một luật xúc xắc suốt run và đánh dấu 5 Lõi thường là **Lõi ruột** của nó. | Stage 3 | Có (`pick_keystone`, như keystones-v1 mục 2) |
| (b) **Đột biến Cặp** | Ráp Cặp một combo thì bật đột biến của nhà combo đó; ráp Đủ, hoặc thêm một Cặp cùng nhà, thì đột biến lên nấc 2. | Stage 2 trở lên, không cần Lõi chủ | Không, tính từ Lõi đang có |
| (c) **Thức tỉnh** | Có 2 Lõi ruột của Lõi chủ đang giữ thì Lõi chủ thức tỉnh: thêm một luật mới, một lần mỗi run, không tắt. | Stage 3 | Không, tính từ Lõi đang có |

Mỗi tầng một cơ chế, không tầng nào đổi cùng một luật với tầng khác trong cùng nhà (kiểm ở cột "Không đụng" bảng 2.1).
Cặp của một combo trong nhà luôn gồm 2 Lõi ruột, nên **ráp Cặp đúng nhà = vừa đột biến vừa thức tỉnh cùng lúc**: đó là khoảnh khắc
lớn nhất của run. Nhưng thức tỉnh không bắt buộc đúng cặp combo, chỉ cần 2 Lõi ruột bất kỳ (lý do ở mục 3.2: tần suất).

Lõi ruột = 2 Lõi Cặp của mọi combo trong nhà, cộng thêm Lõi hợp chủ đề cho đủ 5. Một Lõi có thể là ruột của nhiều Lõi chủ (Khiên Gai
nằm trong 4 combo), không sao vì mỗi run chỉ giữ một Lõi chủ.

Offer: Lõi ruột có trọng số ×`ks_bias` trong cùng bậc (không đổi xác suất bậc, không đổi near-miss), thẻ hiện chip "Hợp Lõi chủ".
Lượt chọn Lõi đầu tiên sau khi có Lõi chủ có ít nhất một thẻ ruột (`ks_seed_pick`, thay một thẻ cùng bậc; bậc đó không có Lõi ruột
thì dời sang lượt chọn sau).

Giữ nguyên từ luật hiện có: banner Cặp/Đủ, +1 reroll Lõi ở lần ráp đầu, không lộ bậc kế (thẻ chỉ hiện nhãn PAIR/FULL).

## 2. Bảng

### 2.1 Sáu Lõi chủ

Luật nền giữ theo keystones-v1 mục 1 trừ Mỏ Mana (sửa giá, xem ghi chú reviewer). Thức tỉnh viết lại cho 3 cái. Số chi tiết và knob
nằm ở keystones-v1, ở đây chỉ ghi câu luật hiện trong game.

| Lõi chủ (nhà) | Luật nền (một câu) | Combo ruột | Lõi ruột (5) | Thức tỉnh (một câu) | Không đụng |
|---|---|---|---|---|---|
| **Tam Tấu** `ks_volley` | Mỗi lượt BỘ ba+ nổ một lần: mọi quái nhận 30/55/80% tổng giá trị gốc của BỘ (tối đa 16); đổi lại BỘ −0.15. | Lò Khiên Phản Đòn, Thành Trì Rùa Vàng, Hoa Độc Hộ Vệ, Lột Xác | `c_sonic_shield`, `c_thorn_shield`, `c_living_wall`, `c_backline_glow`, `c_descend` | **Bão Gai**: BỘ nổ thêm lần hai khi bạn dùng viên cuối của BỘ, và vụ nổ xuyên Khiên quái. | Cặp nhà này đổi Khiên thành Gai, không đụng vụ nổ |
| **Con Bạc** `ks_gambler` | Liều sạch (từ 2 viên, không viên nào Nứt): mọi BỘ lượt này +0.30 (tối đa +0.60); đổi lại Liều Nứt 40%. | Da Gai Dày, Cần Câu Đáy Hồ | `c_elder_trunk`, `c_thorn_shield`, `c_hollow_core`, `c_mana_ward`, `c_thorn_pact` | **Ván Gỡ**: mỗi lượt một lần, Liều làm Nứt thì các viên Nứt được tung lại ngay, miễn phí. | Cặp cho mana khi Nứt, không đổi % Nứt hay số lần tung |
| **Mỏ Mana** `ks_mana_mine` | Lượt đầu có BỘ tự nhiên: +1 mana, và Overcast chỉ tốn 1; đổi lại mặt mana cho ít đi 1. | Vòng Mana Bất Tận, Triều Dâng | `c_mana_pool`, `c_deep_current`, `c_tidecaller`, `c_overflow`, `c_dewdrop` | **Nhịp Đôi**: Overcast dùng được hai lần mỗi lượt (lần hai 2 mana). | Cặp xả mana cuối lượt, không đụng Overcast |
| **Đồng Tộc** `ks_kin` | BỘ có từ 3 viên cùng class +0.40; BỘ không đạt −0.25. | Ổ Nổ Trứng Vàng, Rùa Ngàn Tuổi | `c_nest`, `c_golden_egg`, `c_living_wall`, `c_early_scales`, `c_squad_up` | **Đồng Thanh**: lượt đầu mỗi trận, các Axie cùng class tung ra cùng một part (tối đa thành BỘ bốn). | Cặp cho Khiên khi có BỘ, không đụng class |
| **Giữ Lửa** `ks_embers` | Hold được 2 viên; viên Hold dùng ở lượt sau +0.50. | Cháy Chậm, Nhát Chốt | `c_three_dice`, `c_overflow`, `c_finisher`, `c_chimera_hunt`, `c_kindle` | **Lửa Truyền**: mỗi lượt một viên Hold mang sang nhập được vào BỘ bất kỳ như Mặt Tạm, không tốn mana (tối đa BỘ bốn). | Cặp thưởng viên dùng cuối, không đụng Hold |
| **Bàn Tay Lớn** `ks_big_hand` | BỘ ba không còn thưởng; BỘ bốn và năm thêm +0.40. | Cầu Vồng Xúc Xắc, Mưa Đòn Lunacia (jackpot) | `c_collector`, `c_sixth_die`, `c_cascade`, `c_prism`, `c_finisher` | **Bàn Tay Thứ Sáu**: mỗi lượt có BỘ bốn trở lên, tung thêm một viên thưởng dùng ngay lượt đó (viên thưởng không vào BỘ). | Cặp giảm giá An toàn, không đụng hệ số BỘ |

Ghi chú bảng:
- Đồng Tộc không có combo nào theo class trong 14 combo hiện tại. Nhà của nó là "đội hình" (Trứng, hàng trước), thêm `c_squad_up`
  (Lõi duy nhất theo class còn được offer cùng Đồng Tộc, vì `c_concord` bị lọc hai chiều). Nếu Liam muốn nhà class thật thì cần một
  combo mới (ví dụ `c_squad_up` + `c_nest`), để vòng sau.
- Bàn Tay Lớn chỉ có một combo Cặp thật (Mưa Đòn là jackpot, ~0.1% run). Thức tỉnh của nó vẫn đủ tần suất vì tính theo Lõi ruột,
  không theo combo. Phương án đổi: chuyển Nhát Chốt sang Bàn Tay Lớn (dùng nhiều viên), Giữ Lửa lấy Cần Câu Đáy Hồ (Đủ là Kindle),
  Con Bạc còn một combo. Tôi giữ bảng trên vì Con Bạc + Cần Câu (Hollow Core: mọi lần tung lại) hợp chủ đề nhất.
- Bỏ `c_three_dice` khỏi nhóm Bàn Tay Lớn (keystones-v1 để ở đó): tối đa 3 viên mỗi lượt là ngược hẳn "săn BỘ bốn".

### 2.2 Sáu đột biến Cặp (mỗi nhà một cái)

Đột biến chỉ dùng động từ đã mở ở stage 2 (BỘ, Liều/Nứt, An toàn, Hold, Khiên/Gai, mana), không đụng Overcast (stage 3).
Nấc 2 = Đủ của một combo trong nhà, hoặc Cặp thứ hai cùng nhà. Hai nhà khác nhau thì cùng bật được.

| Nhà | Đột biến (nấc 1) | Điều kiện | Giá / giới hạn | Nấc 2 | Khoảnh khắc trong trận |
|---|---|---|---|---|---|
| Tam Tấu | **Khiên Gai Nảy**: 1/3 Khiên của viên mặt khiên trong BỘ đổi thành Gai (làm tròn xuống, tối đa 4) tới hết lượt quái | viên mặt khiên nằm trong BỘ | mất đúng phần Khiên đó; Gai này không nhân BỘ lần nữa | Gai giữ nguyên số, Khiên không bị trừ | Khiên vỡ thành gai trên Axie, quái đánh vào thì Gai bật số |
| Con Bạc | **Nứt Ra Mana**: lần đầu mỗi lượt có viên Nứt, +1 mana | có viên Nứt vì Liều | 1 lần/lượt; viên vẫn mất nửa giá trị | +2 mana | vết Nứt rơi ra giọt mana bay vào thanh mana |
| Mỏ Mana | **Mana Tràn**: cuối lượt còn từ 3 mana thì tự tiêu 1 mana, mọi quái nhận 2 sát thương | còn ≥3 mana lúc hết lượt | tốn 1 mana; 1 lần/lượt; chạy sau Mana Pool và Mana Ward | 4 sát thương | sóng mana quét qua hàng quái |
| Đồng Tộc | **Che Chắn**: lần đầu mỗi lượt có BỘ, Axie hàng trước ít máu nhất (kể cả Trứng) nhận Khiên = 2 × số viên BỘ | có BỘ | 1 lần/lượt; Khiên này không nhân BỘ | 3 × số viên | Khiên bay từ BỘ sang Axie hàng trước |
| Giữ Lửa | **Nhát Cuối**: viên bạn dùng cuối lượt, nếu thuộc BỘ, +0.30 hệ số | viên cuối (định nghĩa như `c_finisher`) nằm trong BỘ | phải để dành viên BỘ tới cuối; vẫn dưới `m_cap` | +0.60 | dấu "NHÁT CUỐI" đóng lên đòn, số to hơn |
| Bàn Tay Lớn | **Săn Bốn**: lượt đang có đúng BỘ ba, lần An toàn đầu tiên miễn phí | có BỘ ba (không phải bốn+) | 1 lần/lượt; vẫn tính vào tổng 3 lần tung | An toàn lần hai chỉ 1 mana | nút An toàn hiện "0" kèm dấu nhà; ra BỘ bốn thì banner BỘ |

### 2.3 Mười bốn combo

| Combo | Cặp | Đủ | Nhà | Đột biến Cặp (nấc 1 / nấc 2) |
|---|---|---|---|---|
| Lò Khiên Phản Đòn | Shield Wave + Thorn Shield | Prime Chain | Tam Tấu | Khiên Gai Nảy 1/3 (tối đa 4) / không trừ Khiên |
| Thành Trì Rùa Vàng | Living Wall + Thorn Shield | Gatekeeper | Tam Tấu | như trên |
| Hoa Độc Hộ Vệ | Shield Wave + Backline Glow | Blood Sign | Tam Tấu | như trên |
| Lột Xác | Take The Field + Thorn Shield | Bastion | Tam Tấu | như trên |
| Da Gai Dày | Elder Trunk + Thorn Shield | Thorn Pact | Con Bạc | Nứt Ra Mana +1 / +2 |
| Cần Câu Đáy Hồ | Hollow Core + Mana Ward | Kindle | Con Bạc | như trên |
| Vòng Mana Bất Tận | Mana Pool + Deep Current | Loop | Mỏ Mana | Mana Tràn 2 sát thương / 4 |
| Triều Dâng | Rising Wave + Overflow | Backline Glow | Mỏ Mana | như trên |
| Ổ Nổ Trứng Vàng | Nest + Golden Egg | Spore Burst | Đồng Tộc | Che Chắn 2×viên / 3×viên |
| Rùa Ngàn Tuổi | Living Wall + Early Scales | Growing Shell | Đồng Tộc | như trên |
| Cháy Chậm | Overflow + Three Dice | Dewdrop | Giữ Lửa | Nhát Cuối +0.30 / +0.60 |
| Nhát Chốt | Final Blow + Chimera Hunt | Prime Chain | Giữ Lửa | như trên |
| Cầu Vồng Xúc Xắc | Collector + Sixth Die | Prism | Bàn Tay Lớn | Săn Bốn: An toàn 1 miễn phí / An toàn 2 chỉ 1 mana |
| Mưa Đòn Lunacia (jackpot) | không có Cặp | Cascade + Sixth Die + Thorn Shield | Bàn Tay Lớn | vào thẳng nấc 2 |

Combo bị ẩn bởi luật run (`hide_if_rules`) thì không bật đột biến, nhưng Lõi của nó vẫn tính là Lõi ruột cho thức tỉnh.
Số combo theo nhà lệch (Tam Tấu 4, các nhà khác 2): đột biến nhà Tam Tấu sẽ hay gặp nhất. Sim đo; nếu lệch quá thì hạ số Khiên Gai Nảy
chứ không chuyển combo.

## 3. Thấy được

### 3.1 Bốn điểm hiện cho mọi đột biến và thức tỉnh

1. **Lúc ráp** (màn chọn Lõi): banner Cặp hiện có, thêm dòng tên đột biến + một câu luật; thức tỉnh có banner riêng "THỨC TỈNH: <tên>"
   và huy hiệu Lõi chủ đổi khung vàng.
2. **Lần đầu phát trong trận**: popup to tên đột biến/thức tỉnh (~1.2 s) kèm hiệu ứng ở cột "Khoảnh khắc" bảng 2.2 / dòng thức tỉnh.
   Các lần sau: popup nhỏ cùng tên, không chặn nhịp. Dùng lại đường `combo_fired` đang có.
3. **Trên HUD**: huy hiệu Lõi chủ cạnh CorePanel hiện "Lõi ruột 1/2" cho tới khi thức tỉnh (tiến độ thấy được = có lý do săn);
   thẻ combo và thẻ Lõi thường mang dấu nhà. Stage 2 chưa có Lõi chủ thì dấu nhà là bóng mờ có khoá (nhá trước stage 3).
4. **Màn kết run**: "Thức tỉnh: Bão Gai (trận 4)" và số lần mỗi đột biến đã phát.

Đột biến nào không có điểm 2 thì coi như vô hình, không merge. Âm và hình cụ thể do ux-designer / audio quyết.

Chỉ tiêu "thấy được" (đo bằng sim, log sự kiện): sau khi ráp, đột biến phát ít nhất 1 lần ở ≥70% số trận; thức tỉnh phát ít nhất 1 lần
ở ≥80% số trận sau khi thức tỉnh. Dưới mức đó thì sửa điều kiện, không sửa số.

### 3.2 Tần suất thức tỉnh: mục tiêu ~1 lần / 2-3 run

Nếu chỉ thức tỉnh khi ráp đúng Cặp cùng nhà (như keystones-v1): theo `combo-draw-sim.md`, mỗi combo ráp được 3-13% run khi người chơi
săn, cộng 2 combo một nhà chỉ ~7-20%, người chơi thường còn thấp hơn. Không đủ. Nên điều kiện là **2 Lõi ruột bất kỳ**.

Ước tay: `P_aw ≈ P(Bin(N, q·ρ) ≥ 2)`, với `q = 1 − (1 − b·r/n)^3` (xác suất một lượt chọn có thẻ ruột), `r` = 5 Lõi ruột, `n` ≈ 56 Lõi
thật, `b` = `ks_bias`, `ρ` = tỉ lệ người chơi lấy thẻ ruột khi thấy, `N` = 4 lượt chọn mốc (chưa tính shop/sự kiện).

| `ks_bias` | `ks_seed_pick` | người săn (ρ 0.8) | người thường (ρ 0.6) | chọn bừa (ρ 0.33) |
|---|---|---|---|---|
| 1.5 | tắt | ~31% | ~20% | ~7% |
| 2.0 | bật | ~64% | ~44% | ~16% |

Chọn mặc định `ks_bias` 2.0 + `ks_seed_pick` bật: người thường ~1 lần / 2.3 run. Đây là số tay, chưa tính Lõi chỉ ra ở một số bậc
(Kindle 4/100 run, Loop 8/100): sim `sim_combo_draw` thêm Lõi chủ sẽ quyết. Mục tiêu sim: người thường 35-50%, chọn bừa ≥15%, người săn
≤65% (cao hơn thì thức tỉnh hết hiếm, mất cảm giác đột biến), và ≥60% số lần thức tỉnh xảy ra trước boss act 2 (thức tỉnh ở trận chót
thì không kịp thấy).

## 4. Độ khó và người mới

### 4.1 Giữ expert 20 ±3

Ngân sách ước (stage 3, điểm win expert so với không có gì mới):

| Nguồn | Có mặt | Lift khi có | Cộng trung bình |
|---|---|---|---|
| Lõi chủ nền (chọn 1 trong 3) | 100% run | ~+1 | +1 |
| Đột biến Cặp | ~40-70% run | +1.5 đến +3 | +0.6 đến +2 |
| Thức tỉnh | ~35-50% run | +3 đến +5 | +1 đến +2.5 |
| **Tổng** | | | **+2.6 đến +5.5 → expert ~21.4 đến 24.3** |

Tức sát hoặc vượt trần 23. Cách giữ, theo thứ tự, mỗi vòng sim chỉ đổi một knob:
1. Hạ số đột biến Cặp trước (rộng nhất, ai cũng có từ stage 2). Mục tiêu lift Cặp +1.5 đến +3 pp, nấc 2 +3 đến +6.
2. Hạ số thức tỉnh nhưng **giữ luật** (luật mới là thứ Liam đòi). Mục tiêu: run thức tỉnh hơn run chưa thức tỉnh cùng Lõi chủ ≤ +6 pp.
3. Tăng giá Lõi chủ nền (keystones-v1 3.2: `dt.plus` 0.35, `tt.pct` −5, `cb.step` 0.25, `mm.face_sub`).
4. Cuối cùng mới thêm `difficulty.stage_dmg_mult` theo stage (stage 2 thử 1.00-1.03, stage 3 thử 1.03-1.08). **Không** nâng
   `enemy_dmg_mult` toàn cục như brainstorm đề xuất (1.6-1.7): stage 1 không có gì mới mà vẫn bị khó thêm.

Chặn thêm: random và spam ≤12 với mọi Lõi chủ; expert − random không hẹp dưới 6 pp (hẹp là kỹ năng hết quan trọng); expert ở stage 2
(chỉ có Cặp) không vượt 21. Theo dõi kỹ spam ở Tam Tấu và Mana Tràn: cả hai cho sát thương mà không cần quyết định, đúng kiểu đánh bừa
mà Liam đã ghét.

### 4.2 Mở dần theo stage (tối đa 4 khái niệm mới mỗi lần mở, như dice-depth-v4 3.8)

| Stage | Đang mở | Thêm từ bản này | Đếm khái niệm mới |
|---|---|---|---|
| 1 (run đầu) | BỘ, tung thêm tốn mana | không. Combo vẫn chỉ banner như bây giờ | 3 (không đổi) |
| 2 (từ 1 run xong) | Liều/Nứt, Mặt Tạm | đột biến Cặp; dấu nhà mờ trên thẻ combo | 3 |
| 3 (từ 3 run xong) | Overcast, part cao bậc | Lõi chủ (gồm Lõi ruột + thức tỉnh, dạy chung một coach: "Có 2 Lõi mang dấu này thì Lõi chủ thức tỉnh") | 3 |

Giữ chữ ít: mỗi Lõi chủ / đột biến / thức tỉnh đúng một câu trên thẻ, số và ví dụ để trong Codex. Màn chọn Lõi chủ hiện 5 icon Lõi ruột
ngay dưới mỗi thẻ (chọn có thông tin). Tài khoản cũ vào thẳng stage 3 nhận cả hai tầng cùng lúc; coach theo sự kiện, một cái mỗi lượt.
Nếu playtest thấy ngợp: chỉ mở 3 Lõi chủ trước (đúng bộ MVP dưới), 3 cái còn lại từ run thứ 6.

## 5. Chi phí, thứ tự làm, sim, rủi ro

### 5.1 Chi phí

| Phần | Việc | Cỡ |
|---|---|---|
| Data | `assets/data/rules/keystones.json` mới (luật nền, Lõi ruột, thức tỉnh, knob); thêm `family` vào `core_combos.json`; bảng đột biến theo nhà | S |
| Engine | 6 đột biến Cặp (hook nhỏ: Khiên→Gai, Nứt→mana, cuối lượt, Khiên khi BỘ, viên cuối, giá An toàn); 6 luật nền; 6 thức tỉnh; `ks_bias` + `ks_seed_pick` trong `core_offer.gd` | M-L |
| UI | màn chọn Lõi chủ (UI3), huy hiệu + "Lõi ruột x/2", dấu nhà trên thẻ, popup/banner (dùng lại combo), dòng màn kết run, Codex | M |
| Online/ranked | `pick_keystone` vào ActionLog + ALLOWED_FNS cả 3 chỗ, Worker tính lại bộ ba, bump RULES_VERSION + SUPPORTED + fingerprint | M |
| Test | khoảng 12 test mới (5.4) + sửa sàn trong `technical-preferences.md` cùng commit | M |

Tổng cả 6 Lõi chủ + ranked: ước 6-8 ngày làm.

### 5.2 MVP 2-3 ngày (chỉ offline, ranked chưa có Lõi chủ)

Ba Lõi chủ có luật rõ, dễ thấy và ít lỗ hổng nhất: **Tam Tấu, Con Bạc, Mỏ Mana** (nhà của chúng có 8/14 combo). Màn chọn hiện cả ba,
chưa cần rút theo seed.

- Ngày 1: `keystones.json`, `family` trong combo, 3 luật nền + 3 thức tỉnh + 3 đột biến Cặp, `ks_bias`/`ks_seed_pick`, chặn stage.
  Ba nhà còn lại giữ như hiện nay (chỉ banner) trong MVP.
- Ngày 2: màn chọn, huy hiệu + tiến độ Lõi ruột, banner thức tỉnh, popup lần đầu/lần sau, dòng màn kết run. Test 5.4 phần của 3 Lõi chủ.
- Ngày 3: sim S1-S3 cho 3 Lõi chủ, chỉnh một vòng, build cho Liam chơi 5 run (mỗi run ép một Lõi chủ, hỏi: "lúc thức tỉnh mình có đổi
  cách đánh lượt kế không?").
- Sau MVP: Đồng Tộc, Giữ Lửa, Bàn Tay Lớn + nhà của chúng, rút bộ ba theo seed, ranked/Worker.

### 5.3 Kế hoạch sim

Dùng `sim_combo_draw` (tần suất, rẻ, không đánh) và `sim_balance` (win). 2000 run mỗi ô, cặp seed; chênh rơi vào vùng sát ngưỡng thì
lên 4000.
- S0 mốc: không có gì mới, đo riêng stage 2 và stage 3 (18.8 hiện chưa tách theo stage).
- S1 tần suất: P(thức tỉnh) theo Lõi chủ × chính sách (săn / thường / bừa) × `ks_bias` {1.5, 2.0} × `ks_seed_pick` {tắt, bật}; P(Cặp)
  theo nhà. Đạt mục tiêu 3.2.
- S2 ép Cặp: ép 2 Lõi của một combo vs ép 2 Lõi cùng bậc không thuộc combo nào. Lift theo 4.1 bước 1; log số lần đột biến phát (3.1).
- S3 ép Lõi chủ, `awaken_off` rồi `awaken_on`; chênh giữa các Lõi chủ trên run đã chọn ≤5 pp.
- S4 chọn tự do + chính sách săn Lõi ruột: expert 20 ±3, random/spam ≤12, expert − random ≥6.
- Bot phải biết dùng luật mới (Liều để ăn mana khi có Nứt Ra Mana, để dành viên BỘ cho Nhát Cuối, Overcast hai lần...). Mỗi luật có
  một chính sách viết tay; bot không dùng thì sim báo yếu giả. Bù bằng playtest Liam.

### 5.4 Rủi ro lỗ hổng luật

Các dòng ở keystones-v1 mục 4 vẫn giữ, trừ những dòng về thức tỉnh cũ (Bão Gai "hai BỘ", Huyết Mạch, Lửa Truyền "cùng part",
Bàn Tay Thứ Sáu `counts_full`, cờ `awakened` lưu save): thay bằng bảng dưới.

| Rủi ro | Cách bịt | Test |
|---|---|---|
| Thức tỉnh / đột biến lệch khi save, load, replay, undo | cả hai tính từ Lõi đang sở hữu, không lưu state; chỉ lưu thống kê | `t_mutation_derived`: save/load/replay cho cùng kết quả; undo trong trận không đổi |
| Một BỘ chứa nhiều viên không tự nhiên (Mặt Tạm + Lửa Truyền + Đồng Thanh) lên BỘ năm | mỗi BỘ tối đa 1 viên không tự nhiên; Lửa Truyền và Đồng Thanh tối đa BỘ bốn | `t_ks_virtual_cap` |
| Bão Gai: BỘ dùng qua hai lượt (Hold) vẫn nổ hai lần | lần nổ thứ hai chỉ khi mọi viên của BỘ dùng trong cùng lượt; mỗi vụ giữ `tt.cap` | `t_ks_volley_second` |
| Con Bạc + Nứt Ra Mana + Ván Gỡ thành vòng Nứt → mana → tung lại | mana từ Nứt 1 lần/lượt; Ván Gỡ 1 lần/lượt, khoá `(rmode, uids, k)` giữ kết quả | `t_ks_gambler_loop` |
| Mana Tràn đụng Mana Pool / Mana Ward / Deep Current | thứ tự cuối lượt cố định: Mana Pool → Mana Ward → Mana Tràn; undo hoàn mana | `t_mut_mana_order` |
| Mỏ Mana: Mana Pool (mặt mana +1) bù mất giá mặt mana −1 | cố ý (Lõi ruột là cộng hưởng), sim đo riêng cặp này | sim S3 |
| Săn Bốn với Hollow Core (mọi lần tung tốn 1 mana) | Săn Bốn làm lần tung đó 0 mana bất kể nguồn giá; 1 lần/lượt | `t_mut_hunt_four_price` |
| Khiên Gai Nảy nhân BỘ hai lần (Gai × BỘ ở 3.10.7) | Gai sinh từ Khiên đã nhân, không nhân lại | `t_mut_shield_thorn` |
| Che Chắn lên Trứng làm Trứng khó chết (Golden Egg kích ít) | chấp nhận; sim đo tỉ lệ Trứng chết | sim S2 |
| ~~Copycat + Bàn Tay Lớn: viên chép biến BỘ ba thành bốn~~ (reviewer 2: đã kiểm, KHÔNG xảy ra: `_bo_dice` loại viên Copycat khỏi BỘ, `combat_engine.gd:1831-1832`, có `t_gacha_guards`) | không cần lọc offer; chỉ thêm 1 assert Copycat + Bàn Tay Lớn không ra BỘ bốn | `t_keystone_filters` |
| Đồng Thanh + Concord | Concord đã bị lọc hai chiều với Đồng Tộc | `t_keystone_filters` |
| `ks_seed_pick` phá hợp đồng gacha (bậc, near-miss, `core_skipped_t`) | chỉ thay một thẻ cùng bậc, không đổi xác suất bậc | `t_keystone_bias` + `t_gacha_guards` xanh |
| Ranked có Lõi chủ mà Worker chưa kiểm | MVP tắt Lõi chủ ở online/ranked; bật khi Worker tính lại bộ ba + replay xong | Worker `pin_mismatch` / `stage_mismatch` |
| Replay cũ | bump RULES_VERSION, SUPPORTED_RULE_VERSIONS, fingerprint | `t_rules_version` |

## 6. Câu hỏi cho Liam

1. **Cặp có sức mạnh thật không?** (đảo chốt 22/10 "Cặp không sức mạnh"). Khuyến nghị: **có**, nhẹ, theo 6 nhà, từ stage 2. Không có
   sức mạnh thì không có đột biến, và Đủ chỉ 2.5-13.6% run nên đặt đột biến ở Đủ thì phần lớn người chơi không bao giờ thấy.
2. **Thức tỉnh khi có 2 Lõi ruột bất kỳ, hay chỉ khi ráp đúng Cặp cùng nhà?** Khuyến nghị: **2 Lõi ruột**. Chỉ Cặp cùng nhà thì ước
   ~7-20% run, không đạt "1 lần / 2-3 run". Ráp đúng Cặp vẫn là khoảnh khắc lớn nhất vì đột biến và thức tỉnh nổ cùng lúc.
3. **Ranked có dùng Lõi chủ không?** Khuyến nghị: **có, nhưng không ở MVP**. MVP chỉ offline; bật ranked khi Worker tính lại bộ ba +
   replay xong và sim cho chênh giữa các Lõi chủ ≤5 pp. Phương án dự phòng nếu bảng xếp hạng lệch: bộ ba cố định theo mùa.
4. **Tên tiếng Anh của nhóm**: "Keystone" trùng relic `r_keystone` (đã có trong save). Khuyến nghị: **giữ relic, gọi nhóm là "Anchor"**
   (đúng vai mỏ neo; tiếng Việt vẫn "Lõi chủ"). Cùng lúc đổi thức tỉnh "Huyết Mạch" thành "Đồng Thanh" vì "Bloodline" đã là tên hệ thống
   `bloodline-system.md`.
5. **Bù độ khó bằng `difficulty.stage_dmg_mult` theo stage (chỉ khi sim cần), không nâng `enemy_dmg_mult` toàn cục?** Khuyến nghị:
   **đồng ý**. Đây là knob gate mới, cần Liam duyệt trước khi thêm.

## Ghi chú reviewer (creative-director, 21/10/2026)

Đã sửa so với `keystones-v1.md`:
1. Số mana sai: bản đó viết mặt mana sinh 0.00-0.02 mana/lượt (lỗi đếm sim). Đúng là ~0.6/lượt trên tổng ~1.5/lượt. Hệ quả: giá
   "mặt mana −1" mà bản cũ bỏ đi lại là giá thật, còn giá đang dùng (Mặt Tạm 3 mana, 1 lần/trận) chỉ ~1 mana mỗi trận, quá nhẹ so với
   +1 mana mỗi lượt có BỘ và Overcast 1 mana. Đổi giá mặc định của Mỏ Mana thành mặt mana −1 (`mm.face_sub`), Mặt Tạm 3 mana thành knob dự phòng.
2. Bão Gai "BỘ nổ hai lần mỗi lượt (hai BỘ lớn nhất)": 5 viên không thể có hai BỘ ba (cần 6 viên), nên luật gần như không bao giờ chạy.
   Đổi thành nổ lần hai ở viên cuối của BỘ.
3. Nhóm mỏ neo của Đồng Tộc ghi là "Lõi theo thân/ổ cùng class", nhưng Living Wall, Elder Trunk, Early Scales... không liên quan
   class. Nói thẳng là không có combo class; nhà Đồng Tộc là "đội hình" + `c_squad_up`.
4. Bàn Tay Lớn có `c_three_dice` trong nhóm (ngược luật săn BỘ bốn): bỏ. Thêm cảnh báo Copycat.
5. Huyết Mạch (Mặt Tạm miễn phí cho BỘ ba thuần class, 1 lần/trận) hẹp, khó thấy, chồng lên Mặt Tạm, và trùng tên hệ Bloodline: thay
   bằng Đồng Thanh. Lửa Truyền "hai viên Hold tính cùng part với nhau" mơ hồ: viết lại thành viên Hold làm viên Tạm.
6. Cắt nấc "Đủ" của thức tỉnh (6 luật nữa, ít người thấy). Đủ giờ chỉ đẩy đột biến Cặp lên nấc 2.
7. Điều kiện thức tỉnh "Cặp trong `awaken_combos`" quá hiếm: đổi thành 2 Lõi ruột, thêm `ks_seed_pick`, `ks_bias` 1.5 → 2.0.
   Cờ `awakened` lưu save đổi thành trạng thái tính từ Lõi đang có (bớt một chỗ lệch replay).

Đã sửa so với `combo-mutation-brainstorm.md`:
1. Bản đó dựa trên 5 Lõi chủ cũ (dice-depth-v4 mục 10), thiếu Bàn Tay Lớn, Đồng Tộc không có nhà. 4 gia đình đổi thành 6 nhà = 6 Lõi chủ,
   mỗi Lõi chủ ≥2 combo.
2. Gia đình Mana "Overcast 2 mana thay 3" đã lỗi thời (Overcast đang là 2), và Overcast mở ở stage 3 trong khi Cặp mở ở stage 2. Đột biến
   Cặp không đụng Overcast nữa.
3. Gia đình Thủ/Gai "viên khiên Nứt 15%" đè lên chủ đề Liều của Con Bạc: chuyển thành Khiên đổi ra Gai. Gia đình Xúc xắc "Mặt Tạm 1 mana"
   và "lượt đầu BỘ ba tự lên bốn" đè lên luật Mặt Tạm và Đồng Thanh: bỏ.
4. Cắt "Cộng hưởng ×1.5" (luật nhân thứ ba, khó đọc) và trần "2 Duo + 1 Thức tỉnh" (không cần: một Lõi chủ chỉ có một thức tỉnh,
   mỗi nhà tối đa nấc 2).
5. Bỏ hướng Thức tỉnh riêng cho 4-5 combo ở tầng Đủ (kiểu A): thêm luật bespoke cho thứ chỉ 2.5-13.6% run thấy. Thức tỉnh giờ gắn
   với Lõi chủ, gặp ~1 lần / 2-3 run.
6. Bù độ khó bằng `enemy_dmg_mult` toàn cục 1.6-1.7 làm khó thêm cả stage 1: đổi sang knob theo stage, và chỉ dùng sau khi đã hạ số.
7. Lift mục tiêu của Cặp hạ từ +2..+5 xuống +1.5..+3 cho vừa ngân sách 4.1.

Chưa kiểm (cần làn code xác nhận trước khi chốt số): giá trị thật của mặt mana (−1 có biến phần lớn mặt mana thành 0 không), tần suất
offer từng Lõi ruột theo bậc, Copycat có tính vào BỘ không, định nghĩa "viên cuối" của `c_finisher`.
(Bốn điều trên đã kiểm ở mục dưới.)

## Ghi chú reviewer 2 (systems-designer, 21/10/2026)

Kiểm nhanh, đọc code đúng chỗ, không chạy sim.

- (a) Mặt mana: các mặt mana của part ears có giá trị C1 / O2 / P3 (`godot/assets/data/part_faces.json:183-230`, mặt A và B không có
  `mana:1` thêm, mặt C có `mana:1` cantrip). Vậy `mm.face_sub` −1 biến mặt Common từ 1 thành 0, chỉ Rare trở lên còn mana. Giá này nặng
  hơn ghi chú reviewer 1 tả, và nặng không đều (người xài part Common mất gần hết mana mặt; người có part P gần như không mất). Con số
  ~0.6/lượt là của `v4-mana-decisions.md` Vòng 2, tôi chưa đối chiếu lại sim. Đề nghị: sim đo `mana/lượt` trước và sau trừ, đừng ghi −1 cố định.
- (b) Copycat: cảnh báo cũ SAI. `_bo_dice()` bỏ viên có `copycat_turn == turn` (`combat_engine.gd:1831-1832`). Đã gạch dòng rủi ro, bỏ
  việc lọc offer.
- (c) "Viên cuối": `is_finisher` (`core_hooks.gd:91-104`) = viên chưa dùng cuối cùng của CẢ ĐỘI (không Hold; Three Dice thì viên dùng thứ 3).
  Tất định nhưng do người chơi chọn thứ tự dùng. Nhát Cuối khớp định nghĩa này. Bão Gai ghi "viên cuối của BỘ" là định nghĩa KHÁC
  (viên cuối trong riêng BỘ): chọn một, nên dùng đúng `is_finisher` để khỏi viết hook mới. Bão Gai khả thi vì chỉ cần để viên BỘ dùng
  sau cùng; nhưng nó xung đột với Hold (viên Hold không là finisher) nên Giữ Lửa + Nhát Cuối + `c_finisher` ăn cùng một điều kiện, đúng
  ý, ghi rõ trong Codex.
- (d) Offer (`combo-draw-sim.md`, thẻ hiện/100 run, hai profile): dưới 10% chỉ có `c_kindle` 5.3-5.5, `c_golden_egg` 5.4-7.3,
  `c_cascade` 8.0-11.8. Công thức 3.2 coi mọi Lõi ruột như nhau (r/n đều), sai: Tam Tấu có `c_thorn_shield` 77-83 và `c_backline_glow`
  ~90 nên thức tỉnh gần như tự nhiên (cao hơn 64%); Đồng Tộc có `c_golden_egg` 5-7 (và `c_squad_up` không thấy trong bảng tôi đọc, kiểm lại)
  và Bàn Tay Lớn có `c_cascade` 8-12, `c_sixth_die` 16, `c_prism` 15 thì thấp hơn nhiều. Vậy "~44% người thường" chỉ đúng trung bình,
  chênh giữa các Lõi chủ sẽ vượt "≤5 pp" ở S3. Cách sửa không đổi luật: `ks_bias` tính theo trọng số offer thật của từng nhà, hoặc thay Lõi
  ruột <10% bằng Lõi ≥25% shown.
- (e) Năm câu hỏi: Q1 và Q2 là việc Liam phải quyết (đổi chốt cũ, đổi độ hiếm thức tỉnh). Q5 đúng, vì là knob gate. Q3 thực ra đã có
  quyết định mặc định (MVP offline), không cần Liam chọn tại đây. Q4 (đổi tên "Anchor", "Huyết Mạch") là chuyện đặt tên, Liam chỉ cần gật; gộp
  vào Q-nhỏ. Thiếu một câu cần Liam: Mỏ Mana đổi giá mặt mana nặng cho người dùng part Common (xem a): chấp nhận hay đổi giá?
- (f) Vòng chồng: đột biến Cặp độc lập với Lõi chủ nên Con Bạc-nhà (Nứt Ra Mana +1/+2 mỗi lượt) cộng Mỏ Mana-Lõi chủ (Overcast 1 mana,
  Nhịp Đôi lần hai 2 mana) cho: Liều có Nứt → +2 mana → Overcast gần như miễn phí mọi lượt, nấc 2 hoàn vốn cả lần hai. Cần quy tắc:
  mana từ Nứt không dùng được cho Overcast trong cùng lượt, hoặc nấc 2 chỉ +1. Phần còn lại không vòng: BỘ chặn ở `m_cap` 3.0 (BỘ năm
  2.6 + Overcast 0.5 + Con Bạc 0.3-0.6 + Nhát Cuối 0.3-0.6 + Bàn Tay Lớn 0.4 sẽ chạm trần, nghĩa là ba-bốn nguồn cộng sau cùng thừa; sim
  nên đo xem có nguồn nào bị cap nuốt hoàn toàn). Khiên Gai Nảy × `c_thorn_shield` (4 combo, nguồn Gai chính) cần giữ luật "Gai không nhân
  BỘ lại"; Mana Tràn là sát thương không cần quyết định, giống spam, giữ theo dõi như 4.1.
