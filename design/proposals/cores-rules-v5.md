# Đề xuất v5: 12 Lõi mới + 5 Luật run mới (chờ Liam duyệt, chưa code)

Ngày 23/10. Người viết: game-designer. Trạng thái: **ĐỀ XUẤT**, chưa đụng data, chưa đụng engine. Chưa có reviewer khác người viết đọc lại (theo CLAUDE.md phải có trước khi báo xong).

Không đụng: các Lõi "ít kích hoạt" đang sửa ở làn khác (`design/proposals/core-visibility-fix.md`). Không Lõi nào dưới đây thay thế hay sửa Lõi cũ.

## 0. Đọc nhanh: mấy điều tôi thấy khi đọc data, ảnh hưởng thẳng tới đề xuất

1. **Nhà Kin gần như không có Lõi "cùng class".** 5 Lõi nhà Kin hiện là Tổ Ấm, Trứng Vàng, Bức Tường Sống, Vảy Sớm, Hợp Đội (`anchors.json`). Chỉ Hợp Đội đụng class. Bức Tường Sống còn *phá* Kin: chỉ còn 1 ô hàng trước nên khó đứng cạnh Axie cùng class. Hợp Đội đang `disabled` ở 2.10 nhưng vẫn nằm trong `house_cores` của Kin (id `c_squad_up`; file `.tres` hiện vẫn có, cần Liam/làn khác xác nhận nó còn bật không). Nên Kin sau khi bật sẽ thiếu Lõi ruột. Mục 3 đề nghị đổi.
2. **BỘ BA tự nhiên chỉ khoảng 21% ở lần tung đầu** (tôi tự tính: 5 viên, 6 ô part đều nhau, xác suất có ít nhất 3 viên cùng ô = 1656/7776; chưa kiểm bằng `part_faces.json` thật và chưa tính reroll). Hệ quả: mọi Lõi/Luật "thưởng khi có BỘ" phải đi kèm cách *săn* BỘ (reroll, Wild, Hold) thì mới nổ đều. Tôi đã tính điều này vào từng Lõi.
3. **Mat Tam (Wild Face) bị khoá `depth_stage < 2`** (`wild_block_reason`, `combat_engine.gd:1484`) và chỉ cho BỘ BA lên BỘ BỐN, không bao giờ ra BỘ NĂM. Lõi nào đụng Wild phải có `requires` stage, không thì trận đầu là Lõi chết.
4. **Crack = giá trị mặt ÷2 làm tròn lên tới lần tung kế** (`value_div`, `combat_engine.gd:1811`), không phải mất viên. Nên "Crack thành tài nguyên" làm được mà không cần cơ chế mới.
5. Mọi bonus phẳng vẫn tính vào trần +10/mặt; mọi cộng M vẫn dưới `m_cap`=3.0 (`m100_for`). Tôi không đề xuất đổi trần nào.

## 1. Mười hai Lõi mới

Ghi chú chung. Bậc: R Rêu, H Hổ Phách, T Tinh Thể. Số đặt cho dice tier-1, **chưa sim**. "Nhà" nối tới `anchors.json`/`houses.json`. "Mới/đã có" ở cột hook: *có* = đã thấy trong `RelicHooks.TABLE`; *MỚI* = phải viết. Tên Việt để narrative-director chỉnh.

### Nhà Kin (BỘ cùng class)

**K1. Bloodline Ward / Phòng Thủ Huyết Thống** (`c_bloodline_ward`), R, trục `pos`
- Luật: khi một Axie nhận Khiên (từ mặt shield), mỗi Axie liền kề *cùng class* nhận 50% số Khiên đó (làm tròn lên, không phải Khiên từ mặt thì không lan, không lan chéo vòng).
- Nhà: Kin. Thay Bức Tường Sống trong `house_cores` của Kin (xem mục 3).
- Combo mở: Bức Tường Hợp Xướng (Cặp với Khiên Gai; khiên lan sang hàng xóm rồi Khiên Gai đổi thành Gai cuối lượt, cả hàng cùng class thành bức tường gai, không cần luật thêm).
- Quyết định mới: xếp Axie cùng class *đứng cạnh nhau* và dùng mặt shield trên viên đứng giữa, thay vì chỉ lo BỘ. Kin có thêm đường phòng thủ, không còn là "đánh BỘ cùng class hoặc bị phạt".
- Phá: lối "một Axie carry nhận hết Khiên"; làm Kin không chỉ là đánh.
- Hook: `on_shield` (có). `requires = class_pair`. Độ khó **S**.

**K2. Last Testament / Di Chúc** (`c_last_testament`), T, trục `rule`
- Luật: khi một Axie ngã trong trận, mọi Axie còn sống *cùng class với nó* nhận +2 mọi mặt tới hết trận (cộng dồn, tối đa +6) và 5 Khiên. Egg chết không tính.
- Nhà: Kin. Cặp Hoả Táng với Nổ Bào Tử (Axie ngã vừa nổ AoE vừa buff anh em).
- Quyết định mới: một Axie yếu cùng class thành "ngòi nổ" có chủ ý, thay vì cứu bằng mọi giá. Đội Kin chấp nhận hy sinh để lật trận. Cược: sai thì mất người thật.
- Phá: lối "giữ cả 5 Axie sống bằng mọi giá, trận chậm"; đồng thời là lối "đánh đổi" mà Cores T cần.
- Hook: dùng chung đường "Axie ngã" mà Nổ Bào Tử (`c_spore_burst`) đang dùng (cần kiểm tên hook, tôi chưa đọc). `requires = class_pair`, `first_run_hidden = true`. Cần kiểm: Axie ngã trong trận có chết hẳn qua trận sau không (Kẻ Gác Đêm ghi "có thể mất Axie"), vì nếu chết hẳn thì thẻ này đắt hơn nhiều. Độ khó **M**.

**K3. Melting Pot / Nồi Lẩu Thập Cẩm** (`c_melting_pot`), H, trục `pos`
- Luật: một BỘ có từ 3 class khác nhau trở lên: +0.25 M cho cả BỘ.
- Nhà: **không thuộc nhà nào, và là "phản Kin"**. `excludes = anchor:a_kin, owned:c_concord`. Dùng làm lối cho đội nhiều class mà không có Anchor BỘ-class.
- Combo mở: Nồi Lẩu (Cặp với Lăng Kính `c_prism`, Đủ Nhà Sưu Tầm `c_collector`: đội đủ class, đủ loại mặt).
- Quyết định mới: đội 5 class khác nhau là một lối chơi thật, ngược Kin. Người chơi chọn "gom class" hay "đa class" ngay lúc chọn Lõi/Anchor.
- Phá: lối "luôn gom một class cho an toàn".
- Hook: `set_add` (MỚI, xem 6). Token mới `classes_distinct:3`. Độ khó **S**. Rủi ro: đội ngẫu nhiên đa class sẵn nên +0.25 gần như miễn phí, nên giữ ở H và xem tỉ lệ chọn (chống trùng 2.3: >60% thì đổi thành đánh đổi).

### Nhà Embers (giữ viên sang lượt)

**E1. Smoldering Coals / Than Âm Ỉ** (`c_smoldering`), R, trục `mana`
- Luật: cuối lượt, mỗi viên đang được Giữ cho +1 mana (tối đa +2 mỗi lượt).
- Nhà: Embers, nối sang Mỏ Mana (Hold nuôi Overcast).
- Combo mở: Lửa Gửi (Cặp với Giáp Cất).
- Quyết định mới: Giữ viên không còn là "hy sinh tempo". Giữ 2 viên = +2 mana = gần đủ một Overcast (giá 3). Người chơi cân giữa dùng viên ngay và để dành.
- Phá: lối "dùng hết 5 viên mỗi lượt, không bao giờ Giữ" (đúng lối spam).
- Hook: `on_turn_end` (có), đếm viên `held`. `excludes = rule:rule_dry_steppe` (mana cuối lượt bị xoá). Độ khó **S**.

**E2. Cache Plate / Giáp Cất** (`c_cache_plate`), H, trục `dice`
- Luật: khi bạn Giữ một viên đang ra mặt shield, Axie của viên đó nhận ngay 50% Khiên của mặt (làm tròn lên, tối thiểu 2, không nhân M, tối đa 6). Lượt sau viên vẫn dùng đủ.
- Nhà: Embers. Cặp Lửa Gửi (với Than Âm Ỉ), Đủ Cất Lửa (Kindle).
- Quyết định mới: viên shield ở lượt đầu là viên đáng Giữ nhất (nhận khiên hai lần), nên mặt phòng thủ cạnh tranh với mặt đánh cho 1-2 ô Hold. Đúng tinh thần "giữ lửa" mà không cần thêm sát thương.
- Phá: lối chỉ giữ viên đánh mạnh nhất; làm Embers có kiểu chơi phòng thủ.
- Hook: `on_stash` (có). `requires = face:shield`. Độ khó **S**. Rủi ro **TB**: nếu 50% thấy yếu thì thử +2 phẳng thay vì %; nếu có Giữ Vững (giữ 2 lượt) thì nhận khiên mỗi lần Giữ, chấp nhận vì tốn tempo.

**E3. Magma Seed / Hạt Dung Nham** (`c_magma_seed`), T, trục `dice`
- Luật: một viên đã Giữ *hai lượt liền* rồi mới dùng sẽ thành Phun Trào: mặt dmg của nó trúng **tất cả quái**, xuyên giáp, giá trị ×1.5 (làm tròn lên). Cộng được với Focus của Cất Lửa/Giữ Vững.
- Nhà: Embers. Cặp Núi Lửa với Giữ Vững (`c_steady_hold`), Đủ Nhát Kết (Final Blow: viên Phun Trào dùng cuối lượt nhận +4).
- Quyết định mới: bỏ 2 lượt hành động của một viên để đổi lấy một cú quét cả màn. Người chơi tính trận còn mấy lượt, boss có lượt Hở không (Cất Lửa đã nhắm cùng chỗ này).
- Phá: lối "trận nhanh, đánh ngay từ lượt 1"; ngược hẳn spam attack vì tốn hai lượt.
- Hook: `on_stash` + `on_face_used` (có) nhưng cần **đếm số lượt đã Giữ liền** trên unit (MỚI, `custom_state`, vào save và replay). `requires = owned:c_steady_hold`, `excludes = rule:rule_tundra`, `first_run_hidden = true`. Độ khó **M**. Rủi ro **Cao**: AoE xuyên giáp ×1.5 trên viên lớn nhất; cần sim trước khi bật.

### Nhà Big Hand (BỘ bốn/năm)

**B1. Hunter's Reward / Tiền Săn** (`c_hunters_reward`), R, trục `dice`
- Luật: lần đầu mỗi lượt, một reroll trả phí làm BỘ *xuất hiện hoặc lớn lên* (không có thành BA, BA thành BỐN, BỐN thành NĂM): +2 mana và 3 Khiên cho mọi Axie trong BỘ.
- Nhà: Big Hand. Cặp Khâu Bộ với Sợi Chỉ Vàng; Cặp Bàn Tay Chơi Lớn với Tay Chơi Lớn.
- Quyết định mới: reroll không còn chỉ "để tìm mặt to", mà là săn BỘ có lãi; trả mana reroll được hoàn lại một phần nếu trúng, nên khuyến khích reroll *có chủ đích* thay vì bấm tìm sát thương.
- Phá: lối "reroll tới khi ra viên đánh mạnh" (ngược lại thưởng reroll theo cấu trúc BỘ).
- Hook: `on_roll_settled` (có, ctx có `rerolled_uids`); cần so `bo` trước/sau (đọc `combat.bo`, không cần hook mới). Độ khó **S-M**.

**B2. Golden Thread / Sợi Chỉ Vàng** (`c_golden_thread`), H, trục `mana`
- Luật: Mat Tam (Wild Face) rẻ hơn 1 mana (tối thiểu 1) và dùng được **2 lần mỗi trận** (thay vì 1). BỘ BỐN do Mat Tam tạo ra +0.20 M.
- Nhà: Big Hand, và nối Mỏ Mana (Mỏ Mana đã đặt giá Wild 3 mana: Lõi này kéo về 2).
- Combo mở: Khâu Bộ (Cặp với Tiền Săn, Đủ Con Xúc Xắc Thứ Sáu: 6 viên thì có BỘ BA thứ hai để Mat Tam lần hai).
- Quyết định mới: dùng mana để *làm* BỘ BỐN thay vì chờ may, mỗi lượt cân Mat Tam hay Overcast.
- Phá: lối "chỉ dựa tung tự nhiên"; làm BỘ BỐN thành thứ chọn được.
- Hook: `wild_cost` và `wild_per_battle` (value hook MỚI, hai dòng quanh `combat_engine.gd:1467-1475`). Token mới `stage_min:2` (Mat Tam khoá ở stage 1). Độ khó **S**.

**B3. Support Hand / Tay Hộ Pháp** (`c_support_hand`), H, trục `dice`
- Luật: trong một BỘ BỐN trở lên, mỗi viên có mặt shield, heal hay mana nhận +2 (ngoài M, tính trần +10).
- Nhà: Big Hand. Cặp Hộ Pháp Hậu Phương với Hàng Sau Phát Sáng, Đủ Khiên Sóng.
- Quyết định mới: BỘ BỐN không còn mặc định là BỘ sát thương; đội support gom 4 viên hỗ trợ là kiểu thắng thật. **Đối nghịch có chủ ý với Lăng Kính** (Lăng Kính cần 4 loại mặt khác nhau, BỘ BỐN thì cùng ô part), buộc chọn.
- Phá: lối "BỘ BỐN luôn là BỘ đánh" (phá spam attack ngay trong nhà Big Hand).
- Hook: `mod_face` (có) cộng `set_add`/biết viên thuộc BỘ ≥4 (đọc `combat.bo`). `requires = face:shield|heal|mana`. Độ khó **S-M**.

### Nhà Gambler và Mỏ Mana (lối nối chéo)

**G1. Cracked Glass / Kính Nứt** (`c_cracked_glass`), H, trục `dice`
- Luật: viên đang Crack khi dùng còn bắn mảnh: 3 sát thương xuyên giáp lên tất cả quái, tối đa 3 lần mỗi lượt.
- Nhà: Gambler. Combo Cược Vỡ: Cặp với Lõi Rỗng (`c_hollow_core`, T, nhà Gambler), Đủ Mana Ward.
- Quyết định mới: Crack (30%/viên, hoặc 15% với Anchor Gambler) từ rủi ro thành *một nửa lãi*. Người chơi Gamble nhiều viên hơn vì thất bại vẫn có sát thương.
- Phá: lối chỉ dùng reroll an toàn (Safe); làm Gamble thành lựa chọn thật.
- Hook: `on_face_used` (có), đọc `u.cracked`. Độ khó **S**. Rủi ro **TB**: nếu Gamble thành miễn phí thì Lõi này làm Gamble luôn có lãi; cần kiểm Gamble có tốn mana không (tôi chưa xác nhận) và có giới hạn 3 lần/lượt.

**G2. High Roller / Tay Chơi Lớn** (`c_high_roller`), T, trục `rule`
- Luật: một Gamble từ 3 viên trở lên: nếu không viên nào Crack thì mọi viên trong lần đó +2 tới hết lượt; nếu *một* viên Crack thì **cả** lần Gamble đó Crack hết.
- Nhà: Gambler. Cặp Bàn Tay Chơi Lớn với Tiền Săn.
- Tính nhẩm (chưa sim): Anchor Gambler Crack 15%/viên, 3 viên sạch = 61% (+6 tổng, cộng thêm thưởng sạch của Anchor); trượt 39% nhưng Second Wind (khi đã thức tỉnh) tung lại miễn phí viên Crack nên mất ít. Không có Anchor Gambler (Crack 30%): sạch chỉ 34%, kỳ vọng âm. **Lõi này chỉ đáng với Gambler, đó là chủ ý** (đột biến cho đúng build).
- Quyết định mới: Gamble 2 viên (an toàn) hay 3 viên (cược tất tay).
- Phá: lối Gamble 2 viên đều đều.
- Hook: `on_gamble` (MỚI, chỗ `_anchor_after_gamble`, `combat_engine.gd:1920`; ctx `n`, `cracked`) + một hook ghi đè kết quả Crack. `first_run_hidden = true`. Độ khó **M**.

**M1. Burnout / Cháy Máy** (`c_burnout`), T, trục `mana`
- Luật: Overcast thêm +1.0 M thay vì +0.5, nhưng mỗi Axie trong BỘ bị Overcast mất 2 HP (không xuống dưới 1, tối đa 6 HP mỗi lượt cho cả đội).
- Nhà: Mỏ Mana (Overcast rẻ 1 mana nên bấm được nhiều), nối sang Gambler (Khế Ước Gai).
- Combo mở: Lò Máu (Cặp với Khế Ước Gai, Đủ Thân Cổ Thụ: nhiều máu hơn để đốt).
- Quyết định mới: máu là thứ để *tiêu* cho cú Overcast lớn; đội có heal thì Overcast gần như miễn phí.
- Phá: lối "để dành mana, không bao giờ Overcast"; và lối tank không bao giờ mất máu.
- Hook: `overcast_add` (value hook MỚI) + `on_overcast` (event MỚI). Cần kiểm Overcast có khoá stage không (tôi chưa xác nhận). Độ khó **M**. Rủi ro **Cao**: +1.0 M dưới `m_cap` 3.0 vẫn lớn.

## 2. Bảng combo mới (10 combo)

Theo luật B1 của `core-pick-excitement-brainstorm.md`: Cặp tối đa 1 R và 1 T, không có Luật run là thành viên. `hide_if_rules` ghi dòng cuối. Đây là data của `core_combos.json`.

| Combo (EN / VI) | Cặp | Đủ | Nhà | Vui ở đâu | Ẩn khi |
|---|---|---|---|---|---|
| Chorus Wall / Bức Tường Hợp Xướng | Phòng Thủ Huyết Thống + Khiên Gai | Hợp Đội (Squad Up) | Kin x Volley | Khiên lan sang hàng xóm cùng class rồi thành Gai cuối lượt | `rule_upside_down` |
| Funeral Pyre / Hoả Táng | Di Chúc + Nổ Bào Tử | Khế Ước Gai | Kin x Gambler | Axie ngã nổ AoE và buff anh em cùng lúc | không |
| Banked Fire / Lửa Gửi | Giáp Cất + Than Âm Ỉ | Cất Lửa (Kindle) | Embers | Giữ viên khiên nhận khiên, +mana, lượt sau viên +4 | `rule_dry_steppe` |
| Volcano / Núi Lửa | Giữ Vững + Hạt Dung Nham | Nhát Kết (Final Blow) | Embers | Hai lượt không đánh, lượt ba quét cả màn | `rule_tundra` |
| Sewn Hand / Khâu Bộ | Sợi Chỉ Vàng + Tiền Săn | Con Xúc Xắc Thứ Sáu | Big Hand x Mỏ Mana | Săn BỘ, khâu BỘ bốn bằng mana, thêm viên thứ sáu | không |
| Hand of Aid / Hộ Pháp Hậu Phương | Tay Hộ Pháp + Hàng Sau Phát Sáng | Khiên Sóng | Big Hand x Volley | BỘ BỐN toàn support, hàng sau +50% | không |
| Blood Furnace / Lò Máu | Cháy Máy + Khế Ước Gai | Thân Cổ Thụ | Mỏ Mana x Gambler | Đốt máu để Overcast lớn | không (Lõi Rỗng loại Khế Ước Gai là chuyện khác, không dính cặp này) |
| Glass Bet / Cược Vỡ | Kính Nứt + Lõi Rỗng | Mana Ward | Gambler | Gamble rất nhiều viên, Crack cũng ra sát thương | `rule_cheap_mana`, `rule_tundra` (Lõi Rỗng đã loại sẵn) |
| High Roller Table / Bàn Tay Chơi Lớn | Tay Chơi Lớn + Tiền Săn | (để trống; nếu schema không cho `full=null` thì chọn Chuỗi Mồi) | Gambler x Big Hand | Gamble 3 viên tìm BỘ, trúng thì trả mana | không |
| Hot Pot / Nồi Lẩu | Nồi Lẩu Thập Cẩm + Lăng Kính | Nhà Sưu Tầm | trung lập, nối Big Hand | Đội nhiều class và nhiều loại mặt | `anchor:a_kin` |

Ghi chú: Hàng Sau Phát Sáng, Khế Ước Gai, Giữ Vững là Lõi xuất hiện ở nhiều combo; theo dõi tỉ lệ chọn >60% như 2.3. Combo "Funeral Pyre" cùng trục `rule` ở cả hai Lõi, chấp nhận (cùng lý do Ổ Nổ Trứng Vàng).

## 3. Đề nghị đổi `house_cores` để Anchor bật lên có ruột (Liam quyết)

Awakening cần 2 Lõi nhà bất kỳ (`AWAKEN_NEED = 2`), nên Lõi ruột phải đủ *gặp được*.

| Anchor | `house_cores` hiện tại | Vấn đề | Đề nghị |
|---|---|---|---|
| Kin | Tổ Ấm, Trứng Vàng, Bức Tường Sống, Vảy Sớm, Hợp Đội | 3/5 là Egg/Tường, Tường Sống phá Kin; Hợp Đội có thể đã tắt | Thay Bức Tường Sống bằng **Phòng Thủ Huyết Thống**, thêm **Di Chúc** (7 Lõi) |
| Embers | Ba Viên, Bể Tràn, Nhát Kết, Săn Chimera, Kindle | Không có Lõi nào cho Giữ lửa kiểu *phòng thủ* hoặc *mana* | Thêm **Than Âm Ỉ**, **Giáp Cất**, **Hạt Dung Nham** (8 Lõi); hoặc đổi Ba Viên (xung đột Hold 2 viên của Anchor? cần kiểm) |
| Big Hand | Nhà Sưu Tầm, Con Xúc Xắc Thứ Sáu, Thác Đổ, Lăng Kính, Nhát Kết | Thác Đổ nằm trong jackpot Mưa Đòn (lối spam); không có Lõi *săn* BỘ | Thêm **Tiền Săn**, **Sợi Chỉ Vàng**, **Tay Hộ Pháp**; cân nhắc bỏ Thác Đổ khỏi nhà |

Cách đơn giản nhất: giữ 5 Lõi cũ + thêm Lõi mới vào danh sách (nhà 7-8 Lõi), không đổi gì ở `AWAKEN_NEED`. Tỉ lệ chạm 2 Lõi nhà tăng, tức đột biến/awakening xuất hiện đều hơn. Cần sim rút thẻ (đã đề xuất ở review 5 của brainstorm) trước khi chốt số.

## 4. Năm Luật run mới

Luật chung: mỗi luật có một lợi + một giá, một câu đọc được, cả run không đổi, không phải thành viên combo. Mọi bonus phẳng tính vào trần +10. Số chưa sim. Trọng số đề nghị ghi cạnh.

**R14. Set Is King / Bộ Là Vua** (`rule_set_is_king`), trọng số 2
- Luật: viên nằm trong một BỘ (3+) +2; viên không thuộc BỘ nào -1 (tối thiểu 1). Mỗi lượt thêm 1 reroll Safe miễn phí.
- Phá: **spam attack kiểu "năm viên rời, mỗi viên một mục tiêu"** (lối Liam nêu), và lối coi BỘ là phần thưởng phụ.
- Quyết định mới: ngay từ lượt đầu phải *hướng cả đội về BỘ*: giữ viên đồng ô, reroll để ghép, Mat Tam, Sợi Chỉ Vàng... Kin/Big Hand/Gambler đều có việc làm.
- Cảnh báo: BỘ tự nhiên ~21% (xem mục 0.2), nên số -1 và +1 reroll chỉ là chỗ đặt tạm; nếu BỘ tìm quá khó thì luật chỉ là phạt. Cần sim tỉ lệ có BỘ sau 3 reroll.
- Knob: `set_dice_bonus` = 2, `nonset_penalty` = 1, `free_safe` = 1. Nên `excludes` Hiến Tế (4 viên khó ra BỘ hơn, cần kiểm bằng sim). Độ khó **M**.

**R15. Pilot Light / Lửa Mồi** (`rule_pilot_light`), trọng số 1
- Luật: lượt 1 của mỗi trận, mặt dmg của bạn gây 0; nhưng bạn Giữ được tới 4 viên và mỗi viên Giữ +3 khi dùng ở lượt 2. Quái +10% HP.
- Phá: **spam attack từ lượt 1** và lối "đánh nhanh rồi xong" (Crow, Quick Beat). Đổi nhịp mỗi trận thành "chuẩn bị, rồi nổ".
- Quyết định mới: lượt 1 dùng shield/mana/Hold. Lõi Embers (Than Âm Ỉ, Giáp Cất) thành đòn bẩy rõ ràng; Embers Anchor gần như luật này tự nhiên.
- Cảnh báo: nếu trận trung bình dưới 3 lượt thì luật là phạt thuần; boss Đòn ngay lượt 1 sẽ khiến lượt chuẩn bị rất đắt. Cần xem nhịp boss.
- Knob: `t1_dmg_mult` = 0, `t1_stash_cap` = 4, `held_bonus` = 3, `enemy_hp_mult` = 1.1 (dùng chung pattern `zeroFirstTurn` đã có ở Patient Fang). Độ khó **M**.

**R16. High Stakes / Ván Bạc** (`rule_high_stakes`), trọng số 1
- Luật: mọi reroll trả phí là Gamble (không còn Safe), Crack 20%/viên. Gamble sạch: +1 mana và 3 Khiên cho từng Axie được tung lại. Reroll miễn phí vẫn là Safe.
- Phá: **reroll Safe tới khi ra mặt đẹp** (lối Liam đã nêu ở R1/R2) mà không cắt giá trị tiền: thay vì làm reroll đắt hơn, làm nó *rủi ro*.
- Quyết định mới: mỗi lần reroll là một canh bạc, phối với Kính Nứt, Tay Chơi Lớn, Anchor Gambler (hợp Luật, viền "hợp").
- Cảnh báo: Anchor Gambler đặt Crack 15% (thấp hơn 20% của luật): cần quy tắc rõ, tôi đề nghị lấy giá trị thấp hơn. Cần kiểm Safe/Gamble hiện tách bằng `rmode` ở UI thế nào (chưa đọc).
- Knob: `paid_all_gamble` = true, `crack_chance` = 0.20, `clean_mana` = 1, `clean_shield` = 3. Độ khó **M**.

**R17. Pack Alpha / Thủ Lĩnh Bầy** (`rule_pack_alpha`), trọng số 2
- Luật: mỗi trận thường và Elite, quái nhiều HP nhất là Thủ Lĩnh (đánh dấu, có HP +25%). Khi Thủ Lĩnh còn sống, quái khác nhận -50% từ mặt dmg đơn mục tiêu (AoE, poison, thorns, pierce không bị giảm). Thủ Lĩnh chết: mọi quái còn lại mất 30% HP hiện tại. Boss không áp.
- Phá: **chọn quái yếu nhất giết trước**, và lối rải sát thương lung tung / bấm attack vào mục tiêu gần nhất. Thủ Lĩnh buộc phải *chọn mục tiêu*, và AoE/poison tăng giá trị.
- Quyết định mới: tập trung hoả lực đúng chỗ; Lõi Kẻ Gác Cổng, Độc Lan, Vết Nứt, Tam Tấu (Volley) lên giá.
- Cảnh báo: -50% là số mạnh; trận chỉ có 1 quái thì vô nghĩa (Thủ Lĩnh = quái duy nhất, bỏ qua). Cần kiểm tên field `affix_dealt_mult` / luật Giáp có sẵn để dùng chung.
- Knob: `alpha_hp_mult` = 1.25, `others_single_mult` = 0.5, `alpha_death_pct` = 0.30. Độ khó **M-L** (đánh dấu UI và đọc được đòn nào bị giảm).

**R18. Carousel / Vòng Xoay** (`rule_carousel`), trọng số 1
- Luật: đầu mỗi trận, đội xoay một ô (ô 1 xuống ô 5, những ô còn lại tiến lên). Axie vào hàng trước nhận 6 Khiên; Axie rời hàng trước cho đội +2 mana.
- Phá: **"xếp đội một lần rồi quên" và lối tank cố định hàng trước** (R8 cũ cũng nhắm chỗ này nhưng chỉ đổi thưởng theo hàng, không đổi người).
- Quyết định mới: không Axie nào mãi là tank; phải chọn đội mà ai đứng trước cũng chịu được; Axie đứng cạnh nhau đổi mỗi trận nên Phòng Thủ Huyết Thống và Kin xếp lại liên tục.
- Cảnh báo: cực xung với `c_living_wall`, `c_open_ranks`, `c_descend` (đổi hàng vĩnh viễn) và `c_growing_shell`; phải `excludes`. Cần UI báo xoay và log. Chưa rõ giao diện chỉnh đội hiện cho phép thay đổi giữa trận không.
- Knob: `rotate_step` = 1, `enter_front_shield` = 6, `leave_front_mana` = 2. Độ khó **M** (logic nhỏ, UI và save lớn).

### Xác suất gặp luật khắc spam sau khi thêm 5 luật

Hiện 13 luật tổng trọng số 16; luật khắc spam trực tiếp: R10, R12, R13 (6). Thêm R14, R17 (4 nữa) và R15, R16, R18 trọng số 1 → 23 tổng, khắc spam 10. Xác suất ít nhất 1 trong 2 thẻ là luật khắc spam xấp xỉ 1 - (13/23 x 12/21) = 68% (so với 62.5% hiện nay). Chỉ là ước lượng tay, chưa sim.

## 5. Bảng tổng

| id đề xuất | Loại | Bậc | Nhà / Anchor | Độ khó code | Rủi ro cân bằng |
|---|---|---|---|---|---|
| `c_bloodline_ward` | Lõi pos | R | Kin | S | Thấp |
| `c_last_testament` | Lõi rule | T | Kin | M | Trung bình (cần kiểm Axie ngã chết hẳn?) |
| `c_melting_pot` | Lõi pos | H | trung lập (phản Kin) | S | Trung bình (+0.25 gần miễn phí) |
| `c_smoldering` | Lõi mana | R | Embers x Mỏ Mana | S | Thấp |
| `c_cache_plate` | Lõi dice | H | Embers | S | Trung bình |
| `c_magma_seed` | Lõi dice | T | Embers | M | **Cao** |
| `c_hunters_reward` | Lõi dice | R | Big Hand | S-M | Thấp-TB |
| `c_golden_thread` | Lõi mana | H | Big Hand x Mỏ Mana | S | Trung bình |
| `c_support_hand` | Lõi dice | H | Big Hand | S-M | Thấp |
| `c_cracked_glass` | Lõi dice | H | Gambler | S | Trung bình (Gamble miễn phí?) |
| `c_high_roller` | Lõi rule | T | Gambler | M | Trung bình (chủ ý chỉ hợp Gambler) |
| `c_burnout` | Lõi mana | T | Mỏ Mana x Gambler | M | **Cao** |
| `rule_set_is_king` | Luật run | - | Kin, Big Hand, Gambler | M | Trung bình (BỘ 21%) |
| `rule_pilot_light` | Luật run | - | Embers | M | **Cao** (trận ngắn thì phạt thuần) |
| `rule_high_stakes` | Luật run | - | Gambler | M | Trung bình |
| `rule_pack_alpha` | Luật run | - | mọi nhà | M-L | **Cao** (-50% quái phụ) |
| `rule_carousel` | Luật run | - | mọi nhà | M (UI/save L) | **Cao** (xung với Lõi hàng) |
| 10 combo mới | data `core_combos.json` | - | - | S | Thấp |

## 6. Hook và token engine cần (để làn code đếm việc)

Đã có (đọc từ `RelicHooks.TABLE`): `on_turn_start`, `on_turn_end`, `on_face_used`, `on_face_hit`, `on_roll_settled`, `on_reroll_paid`, `on_stash`, `on_shield`, `on_kill`, `on_dmg_taken`, `mod_face`, `face_final`, `stash_cap`, `stash_repeat`.

MỚI (đề xuất):
1. `set_add` : value hook trong `m100_for` (`combat_engine.gd:1848`), nhận die và nhóm BỘ (kích cỡ, class của các viên). Cho Nồi Lẩu và Sợi Chỉ Vàng. Comment ở dòng 1847 đã ghi "Core adds not done yet". **S**
2. `wild_cost` / `wild_per_battle` : value hook (2 hàm nhỏ ở `:1467-1475`). **S**
3. `overcast_add` (value) + `on_overcast` (event) : cho Cháy Máy. **S-M**
4. `on_gamble` : event sau Crack (`:1920`), kèm cách ghi đè "một viên Crack thì cả lần Crack". Cho Tay Chơi Lớn và Luật Ván Bạc. **M**
5. Bộ đếm "số lượt Giữ liền" trên unit, phải vào save/replay/undo (`custom_state`). Cho Hạt Dung Nham. **M**
6. Token `requires/excludes`: `classes_distinct:3`, `stage_min:2`, `anchor:<id>`. **S**
7. Luật run: knob `nonset_penalty`, `t1_dmg_mult`/`t1_stash_cap`, `crack_chance`, đánh dấu Thủ Lĩnh, `rotate_step`. Mỗi luật đụng `rule_knobs` + đọc ở engine.

Mọi thay đổi đều nằm trong fingerprint `t_rules_version` nên cần bump `RULES_VERSION` và deploy Worker, theo `godot/CLAUDE.md`.

## 7. Điều kiện "thấy được trong lúc chơi" (theo yêu cầu cũ của Liam)

Mỗi Lõi/Luật khi làm phải qua ba kiểm tra trước khi báo xong: (1) nó **xuất hiện** trong run thường (không bị `requires` giết cả pool); (2) nó **kích hoạt có cue nhìn thấy** (float text, nhãn Lõi sáng); (3) nó **đổi một quyết định** trong lượt. Test gợi ý: một seed cố định mỗi Lõi chứng minh có xuất hiện + có event phát ra; sim rút thẻ kiểm tỉ lệ ráp Cặp.

## 8. Cần Liam duyệt

Gạch hoặc đồng ý từng dòng. Mặc định tôi khuyến nghị làm theo thứ tự ưu tiên ở mục "Thứ tự".

**A. Lõi (12)**
- [ ] K1 Phòng Thủ Huyết Thống (R)
- [ ] K2 Di Chúc (T), cần Liam trả lời: Axie ngã trong trận có chết hẳn không?
- [ ] K3 Nồi Lẩu Thập Cẩm (H), có đồng ý "phản Kin" loại khi có Anchor Kin?
- [ ] E1 Than Âm Ỉ (R)
- [ ] E2 Giáp Cất (H)
- [ ] E3 Hạt Dung Nham (T), rủi ro Cao, có đồng ý thử sim trước khi bật?
- [ ] B1 Tiền Săn (R)
- [ ] B2 Sợi Chỉ Vàng (H), cần token `stage_min:2`
- [ ] B3 Tay Hộ Pháp (H)
- [ ] G1 Kính Nứt (H)
- [ ] G2 Tay Chơi Lớn (T)
- [ ] M1 Cháy Máy (T), rủi ro Cao

**B. Luật run (5)**
- [ ] R14 Bộ Là Vua (trọng số 2)
- [ ] R15 Lửa Mồi (trọng số 1), rủi ro nếu trận quá ngắn
- [ ] R16 Ván Bạc (trọng số 1)
- [ ] R17 Thủ Lĩnh Bầy (trọng số 2), M-L
- [ ] R18 Vòng Xoay (trọng số 1), có chấp nhận UI/save lớn không?

**C. Combo (10)**: duyệt cả bảng mục 2, hoặc gạch từng cái. Riêng "Bàn Tay Chơi Lớn" cần quyết `full = null` có hợp lệ không.

**D. Câu hỏi cần Liam quyết (các câu tôi không tự quyết)**
1. **Đổi `house_cores` cho Kin / Embers / Big Hand theo mục 3**: thêm Lõi (nhà 7-8 Lõi) hay thay Lõi cũ? Có bỏ Bức Tường Sống và Thác Đổ khỏi nhà không?
2. **Hợp Đội (`c_squad_up`) đã `disabled` ở 2.10 nhưng còn nằm trong Kin và trong combo "Chorus Wall" tôi đề xuất**: bật lại hay thay thứ khác làm Đủ?
3. **Lối chơi nên kéo về đâu**: tôi ưu tiên Lõi phá spam attack bằng cách *thưởng thứ khác* (khiên, mana, BỘ support) thay vì phạt attack. Liam có muốn thêm Lõi đánh đổi kiểu "attack -2, thứ khác +3" nữa không (đã có Y Sĩ, Lò Độc, Thân Cổ Thụ)?
4. **Chạy sim trước hay làm luôn?** Tôi đề nghị sim rút thẻ (tỉ lệ ráp Cặp) và sim BỘ (tỉ lệ BỘ sau 3 reroll) *trước* khi làm R14 và Hạt Dung Nham, vì cả hai phụ thuộc con số 21%.

**Thứ tự đề nghị (nếu Liam đồng ý tất cả):**
1. Gói rẻ dùng hook có sẵn: K1, E1, E2, B1, G1 + combo data. (S)
2. Gói cần `set_add` / `wild_*`: K3, B2, B3. (S)
3. Gói cần hook mới vừa: K2, G2, M1, E3 + R15, R16. (M)
4. Gói lớn, để sau cùng: R14 sau khi sim, R17, R18.

## 9. Theo 8 mục GDD (tóm tắt, để bản tách riêng sau khi Liam duyệt)

Đây là **đề xuất**, chưa phải GDD. Khi Liam duyệt, tách mỗi Lõi/Luật thành dòng trong `design/gdd/relic-system.md` (hoặc file Lõi mới) với 8 mục. Phần Công thức hiện chỉ có: Overcast add (+0.5 → +1.0), Set add (+0.25, +0.20), Held multiplier, Alpha (x1.25 HP, x0.5), xem từng Lõi. Phần Edge case chính: BỘ NĂM không bao giờ ra từ Mat Tam; Luật chặn chồng; Lõi bị `excludes` thì không rút; Lõi quest hoàn thành vẫn tính cho combo. Phần Acceptance: mục 7.

## 10. Liam duyệt 23/10 (theo review systems-designer + lead-programmer) — NGUỒN CHÍNH cho làn code
Gói an toàn (giữ nguyên đề xuất): c_bloodline_ward (K1), c_smoldering (E1), c_cache_plate (E2; kiểm Giữ Vững: Giữ lại mỗi lượt KHÔNG được khiên mỗi lượt vô hạn — tối đa 1 lần/viên/lượt), c_golden_thread (B2, `stage_min:2`), rule_pack_alpha (R17, hạ Thủ Lĩnh: quái còn lại −20% HP thay vì −30%; hoà HP chọn uid nhỏ nhất).
Gói sửa:
- c_last_testament (K2): rút còn 1 vế: Axie cùng class với Axie vừa ngã +2 mọi mặt tới hết trận (tối đa +6). Axie ngã hồi ở trận sau (roster không lưu hp), nên không cần lo "mất người thật". Hook: on_dmg_taken + fell_now (như c_spore_burst).
- c_melting_pot (K3): đánh đổi: đội có ≥3 class VÀ không có 2 Axie cùng class → mọi BỘ +0.25. Token mới `classes_distinct`.
- c_magma_seed (E3): ×1.25, KHÔNG xuyên giáp, bỏ `requires owned`. Code nhưng `enabled:false` cho tới khi sim (đo ở tích hợp).
- c_hunters_reward (B1): khi trả phí reroll làm BỘ lớn lên: hoàn đúng phí vừa trả (không lãi), +3 Khiên.
- c_support_hand (B3): điều kiện BỘ 3+ (thay BỘ 4+), giữ +2.
- c_cracked_glass (G1): sát thương = 50% giá trị mặt của viên Nứt (thay 3 phẳng). Gamble không tốn mana (đã xác nhận).
- c_high_roller (G2): `requires anchor:a_gambler`, luật viết lại 1 câu.
- rule_set_is_king (R14): viên trong BỘ +2, viên lẻ −2; KHÔNG có reroll miễn phí. Code, `enabled` chỉ bật sau sim.
- rule_pilot_light (R15): không áp với boss. Code, bật sau sim.
- rule_high_stakes (R16): hoàn mana khi reroll sạch tối đa 1 lần/lượt.
BỎ: rule_carousel (R18), c_burnout (M1). Combo dính 2 món này thì bỏ hoặc thay "Đủ".
Combo: Chorus Wall thay "Đủ" (Hợp Đội đang tắt) bằng một Lõi Kin thật; Bàn Tay Chơi Lớn để `full:null` được (code hỗ trợ), thêm 1 test; Hot Pot theo c_melting_pot mới.
house_cores (duyệt): Kin = thay c_living_wall bằng c_bloodline_ward, bỏ c_squad_up (đang tắt) — thay bằng c_last_testament; Embers = thêm c_smoldering + c_cache_plate (giữ 5 cái: chọn 5 hợp nhất, ghi lý do); Big Hand = bỏ c_cascade, thêm c_hunters_reward, c_golden_thread, c_support_hand. Anchor cần đúng 5 Lõi nhà (AWAKEN_NEED=2): nếu nhà >5 thì chọn 5, ghi lý do. Sim tỉ lệ thức tỉnh ≥33% mỗi Anchor ở tích hợp.
Golden Egg "nở" (LF2): Egg triệu hồi giữa trận, tối đa 1 lần/lượt (chống farm).

**house_cores đã code (làn NC, 23/10), mỗi Anchor đúng 5 Lõi nhà:**
- Kin: c_nest, c_golden_egg, c_bloodline_ward (thay Bức Tường Sống), c_early_scales, c_last_testament (thay Hợp Đội đang tắt).
- Embers: c_kindle, c_smoldering, c_cache_plate (3 Lõi đúng chủ đề Giữ), c_three_dice (tự Giữ viên chưa dùng, nuôi Than Âm Ỉ), c_overflow (mana dư từ Than Âm Ỉ thành sát thương). Bỏ c_finisher và c_chimera_hunt: cả hai kiểu đánh nhanh / quest tấn công, ngược chủ đề Giữ.
- Big Hand: c_hunters_reward, c_golden_thread, c_support_hand (3 Lõi mới), c_sixth_die (viên thứ sáu giúp ra BỘ), c_finisher (giữ một đường sát thương cho BỘ lớn). Bỏ c_cascade (theo duyệt), c_collector (quest, cần 4 loại mặt) và c_prism (cần 4 loại mặt, ngược Tay Hộ Pháp).
- Chưa sim tỉ lệ thức tỉnh ≥33% (làm ở tích hợp). a_kin/a_embers/a_big_hand vẫn enabled:false (làn AN2 bật).
- Lõi đã code: K1 c_bloodline_ward, K2 c_last_testament, K3 c_melting_pot, E1 c_smoldering, E2 c_cache_plate, E3 c_magma_seed (disabled), B1 c_hunters_reward, B2 c_golden_thread, B3 c_support_hand, G1 c_cracked_glass, G2 c_high_roller. Combo Volcano enabled:false chờ E3.

## 11. Bật luật sau sim
`rule_set_is_king` và `rule_pilot_light` đang tắt (`disabled=true`, `hook_key` rỗng trong .tres). Muốn bật: sửa `disabled=True, needs="sim"` trong `godot/tools/gen_cores.py` (xoá hai tham số đó ở dòng `rule(...)` của luật) rồi sinh lại .tres: `python3 godot/tools/gen_cores.py godot/resources/relics rule_set_is_king rule_pilot_light`. Không lật tay trong .tres, vì `hook_key` rỗng khi `disabled` và hook sẽ không chạy. Sau đó đổi RULES_VERSION, cập nhật số luật/weight trong `t_run_rule_catalog`.
`rule_high_stakes` ở tích hợp cần thêm `requires` stage_min:2 (token từ làn NC); trong lúc chưa có, engine giữ Safe ở depth_stage 1.
