# Combo "đột biến": brainstorm (21/10/2026)

Chỉ là đề xuất để Liam chọn, chưa sửa code, chưa commit. Số trong doc là điểm xuất phát, sim sẽ chỉnh.
Nguồn đã đọc: `core_combos.json`, `production/gacha-contract.md`, `dice-depth-v4.md` mục 3.0 và 10, mô tả 32 Lõi trong `resources/relics/c_*.tres`, `production/qa/sim/combo-draw-sim.md`.
`design/proposals/keystones-v1.md` CHƯA có trong repo lúc viết; phần nối Lõi chủ dựa trên 5 Lõi chủ ở `dice-depth-v4.md` mục 10 (Tam Tấu, Con Bạc, Mỏ Mana, Đồng Tộc, Giữ Lửa). Nếu bản keystones-v1 đổi tên/luật thì đối chiếu lại mục 3.

## 0. Học từ game khác (chọn lọc)

- **Hades Duo/Legendary**: chỉ xuất hiện khi mình đã có đúng Boon tiền đề; nó đổi cách một đòn chạy chứ không chỉ cộng số; và nó có thể bị "hứa mà chưa tới" (đủ điều kiện vẫn chưa chắc ra), nên người chơi săn nó. Keepsake chỉ tăng tỉ lệ gặp, không cho không. (Search xác nhận phần tiền đề + tăng tỉ lệ.)
- **ARAM Mayhem augment sets** (không phải Arena; search không thấy bộ trong Arena): sưu đủ 2 rồi 4 món cùng bộ thì mở hiệu ứng mới ở mỗi mốc (vd Fireworks: 2 món nảy 2 lần, 4 món nảy 3 lần). Đây đúng là hình dạng Cặp rồi Đủ của mình.
- **Balatro, TFT hero augment, Slay the Spire, Monster Train**: search không ra phân tích "build thành", phần này mình nói theo trí nhớ, Liam coi là tham khảo. Điểm chung: lúc build thành thì LUẬT hiển thị trên màn hình đổi ngay (joker retrigger, hero augment đổi kỹ năng tướng, deck ra combo vô hạn), không phải một con số nhỏ đứng sau.

## 1. Vì sao hiện "rời rạc" và "không đột biến"

1. Lõi thường cộng nhỏ và độc lập: mỗi Lõi một dòng riêng (Thành Trì: +12 HP slot 1; Khiên Gai: Khiên dư thành Gai...), không Lõi nào nói chuyện với Lõi khác, và không Lõi nào chạm vào BỘ / Liều / Mặt Tạm / Overcast, tức là phần xúc xắc người chơi đang học ở v4. Hai hệ đứng cạnh nhau, không dính.
2. Ráp Cặp/Đủ hiện chỉ có banner + nhãn + 1 reroll Lõi (phương án B cũ, không sức mạnh). Trong trận, `combo_fired` chỉ bật tên combo 1 giây rồi mọi thứ chạy y như trước. Khoảnh khắc "build thành" có đèn mà không có điện.
3. Cặp rơi khá thường (30-72% run, sim hunt/random), Đủ hiếm (2.5-13.6%) nên Đủ lẽ ra phải là cú nổ, nhưng nó cũng chỉ là banner vàng hơn. Và 14 combo dùng chung Lõi (Khiên Gai nằm trong 4 combo, Sonic Shield 2, Prime Chain 2): người chơi không thấy "mỗi combo là một kiểu build", chỉ thấy cùng vài Lõi quay vòng.

## 2. Ba hướng

Quy ước chung cho cả 3: không rng mới; mutation tính từ `combo_done` + Lõi đang sở hữu (không lưu thêm state, replay tự đúng); mọi hệ số cộng vào túi M của v4 và nằm dưới `bo.m_cap`; mutation tắt khi mất một Lõi của Cặp; không lộ bậc kế (giữ luật 22/10); chỉ chạy từ stage >= 2 (xem câu hỏi 4).

### Hướng A: "Duo & Thức tỉnh" riêng từng combo (kiểu Hades)

- Cơ chế: mỗi combo có một **luật Duo** (Cặp) viết riêng, và một **Thức tỉnh** (Đủ) viết riêng, kèm một khoảnh khắc nổ trong trận (1 lần mỗi trận, hiện trên combat view).
- Ví dụ 1, Thành Trì Rùa Vàng (Living Wall + Khiên Gai, Đủ = Gatekeeper). Duo: Khiên dư cuối lượt của Axie slot 1 thành Gai mà KHÔNG mất Khiên (Gai tối đa 8). Thức tỉnh: lần đầu mỗi trận Axie slot 1 sắp chết thì còn 1 HP, và toàn bộ Gai của nó nổ lên mọi quái ("Mai Rùa Vàng").
- Ví dụ 2, Cầu Vồng Xúc Xắc (Collector + Con Xúc Xắc Thứ Sáu, Đủ = Prism). Duo: nếu Hold viên thứ sáu thì nó ở lại sang lượt sau. Thức tỉnh: nếu đã dùng 4 loại mặt trong lượt, viên thứ sáu lượt kế là viên Vàng, người chơi CHỌN mặt của nó.
- Cảm giác: mạnh nhất, mỗi combo một câu chuyện riêng, đúng "Legendary boon". Hợp Explorer/Achiever.
- Cân bằng: dễ vỡ nhất vì 14 combo x 2 tầng = 28 luật bespoke, 28 chỗ sai số; mỗi luật là một điểm có thể trội.
- Chi phí: **L** (28 hook trong `CoreHooks`/`RelicHooks.TABLE`, 28 chuỗi text qua `UI3.describe()`, test từng cái). Đụng RULES_VERSION chắc chắn. Ví dụ 2 thêm hành động người chơi mới (chọn mặt): phải thêm vào ALLOWED_FNS đủ 3 chỗ (`action_log.gd`, `run_verifier.gd`, `worker/src/run_core.js`) + Worker.

### Hướng B: Combo viết lại BỘ / Liều / Mặt Tạm / Overcast (cầu nối sang v4)

- Cơ chế: 14 combo chia 4 **gia đình**, mỗi gia đình gắn với một động từ của dice v4. Cặp đổi một THAM SỐ của động từ đó; Đủ đổi LUẬT của nó. Tất cả dùng hook v4 đã có hoặc đã thiết kế (`core_add`, `oc_add`, giá Overcast, giá Mặt Tạm, `crack_pct`).

| Gia đình | Combo | Cặp ("Duo") | Đủ ("Thức tỉnh") |
|---|---|---|---|
| Mana | Vòng Mana Bất Tận, Triều Dâng, Cần Câu Đáy Hồ | Overcast tốn 2 mana thay vì 3 | Overcast dùng được 2 lần mỗi lượt (lần 2 tốn 3) |
| Thủ/Gai | Thành Trì Rùa Vàng, Lò Khiên Phản Đòn, Lột Xác, Da Gai Dày, Rùa Ngàn Tuổi | viên mặt khiên khi Liều Nứt 15% thay vì 30% | viên mặt khiên không bao giờ Nứt, và BỘ có viên khiên +0.25 hệ số |
| Chốt/Nổ | Nhát Chốt, Ổ Nổ Trứng Vàng, Hoa Độc Hộ Vệ | viên dùng cuối lượt trong BỘ +0.25 hệ số | viên cuối lượt trong BỘ nổ thêm 50% sát thương lên mọi quái |
| Xúc xắc/Nhịp | Cầu Vồng Xúc Xắc, Cháy Chậm, Mưa Đòn (jackpot, không có tầng Cặp nên chỉ nhận tầng Đủ) | Mặt Tạm tốn 1 mana thay vì 2 | lượt đầu mỗi trận có bộ ba thì tự lên bộ bốn miễn phí (1 lần/trận) |

- Ví dụ 1, Vòng Mana Bất Tận: ráp Mana Pool + Deep Current thì Overcast của BỘ rẻ hơn hẳn, người chơi bắt đầu giữ mana để Overcast thay vì xài hết; ráp thêm Loop thì Overcast hai lần, lượt đó BỘ x1.8 có thể lên gần x2.6 + hai lần +0.5.
- Ví dụ 2, Lò Khiên Phản Đòn (Sonic Shield + Khiên Gai, Đủ = Prime Chain): Liều viên khiên gần như an toàn, người chơi dám Liều nhiều hơn, thay đổi hành vi trong lượt (đây là "dynamic" mình muốn, không phải "mechanic").
- Cảm giác: người chơi thấy Lõi thường chạm vào bàn xúc xắc, nút Overcast / Mặt Tạm đổi giá ngay trước mắt (UI v4 đã hiện giá, chỉ đổi số). Ít "wow" thị giác hơn A, đổi lại hiểu ngay.
- Cân bằng: an toàn nhất vì nằm trong túi M và `bo.m_cap`; 8 hiệu ứng thay vì 28. Rủi ro: chồng với Lõi chủ cùng tham số (Mỏ Mana cũng đổi giá Overcast về 2): quy tắc lấy giá thấp nhất, không cộng dồn. Điểm yếu: trong gia đình, combo na ná nhau (Thủ có 5 combo).
- Chi phí: **M** (8 hiệu ứng, 1 bảng data `combo_mutations.json` trong `assets/data/rules/`, hook vào chỗ tính giá Overcast/Mặt Tạm/Nứt đã có hoặc sắp có, UI: dòng "Mutation" trên thẻ combo và tooltip). RULES_VERSION: bump 1 lần (thêm một chữ cái sau `-r`) + SUPPORTED_RULE_VERSIONS + fingerprint. Không thêm hành động mới.

### Hướng C: Lõi tiến hoá / hợp nhất khi ráp (kiểu TFT item combine)

- Cơ chế: Cặp thì 2 Lõi gộp thành 1 **Lõi hợp nhất** (icon mới, tên mới, chữ mới, hai icon cũ bay vào nhau); Đủ thì Lõi thứ ba nhập vào, thành bản vàng với một mệnh đề thứ ba. Lõi hợp nhất giữ cả hai hiệu ứng gốc và thêm một luật đổi cách hai Lõi đó chạy.
- Ví dụ 1, Triều Dâng (Tidecaller + Overflow) thành "Triều Cường": mana vượt 8 vẫn nổ pierce nhưng chỉ rơi về 4 chứ không về 8, nên mana là một cái hồ tích rồi xả, không phải trần cứng.
- Ví dụ 2, Rùa Ngàn Tuổi (Living Wall + Early Scales, Đủ = Growing Shell) thành "Mai Ngàn Tuổi": 5 Khiên đầu trận của Axie slot 1 không bị tan giữa lượt, và mỗi quái nó giết cộng thêm 1 Khiên đầu trận cho các trận sau.
- Cảm giác: thị giác mạnh nhất (Core panel đổi hình, Codex đẹp, share card hay). Hợp Collector/Expression.
- Cân bằng: khó nhất về logic: Khiên Gai nằm trong 4 combo thì hợp nhất vào cái nào? Cần luật "ai ráp trước thắng, Lõi đã hợp nhất bị khoá khỏi combo khác", mà luật đó lại giết bớt hướng xây dựng.
- Chi phí: **L** (14 Lõi hợp nhất mới + tầng Đủ = tối đa 28 asset/icon/text, đổi danh sách Lõi sở hữu giữa run nên đụng `owned_relic_ids`, replay, save, Codex, near-miss, `CoreOffer`), RULES_VERSION bump, và có thể kéo theo hỗ trợ cho `t_core_catalog`.

## 3. Khuyến nghị: B làm nền, thêm Thức tỉnh riêng cho vài combo, nối Lõi chủ

**Làm B trước** (cầu nối sang v4, M, an toàn), rồi nếu sim và playtest ổn thì thêm một **Thức tỉnh cá biệt** kiểu A cho 4-5 combo hay nhất (vd Thành Trì Rùa Vàng, Cầu Vồng Xúc Xắc, Vòng Mana Bất Tận, Hoa Độc Hộ Vệ, Mưa Đòn) thay cho hiệu ứng gia đình ở tầng Đủ. Tức là: Cặp = Duo theo gia đình (rẻ, đọc được), Đủ = cú nổ riêng có khoảnh khắc trong trận (hiếm, nên được phép mạnh và được phép tốn công). Không làm C bây giờ (đắt, xung đột Lõi dùng chung); hình ảnh "hợp nhất" có thể làm sau chỉ ở Codex/banner.

Điểm này đảo lại chốt 22/10 "Cặp không sức mạnh". Mình cho là cần đảo, vì không có sức mạnh thì không thể đột biến. Giữ được lời chốt "không lộ bậc kế": mutation chỉ bật khi đã ráp, thẻ sắp làm đủ vẫn chỉ hiện nhãn PAIR/FULL như cũ.

**Nối Lõi chủ để hết rời rạc.** Lõi chủ là mỏ neo, mỗi gia đình có một Lõi chủ "ruột":

| Lõi chủ (v4 mục 10) | Gia đình ruột | Nối thế nào |
|---|---|---|
| Mỏ Mana | Mana | giá Overcast dùng giá thấp nhất, không cộng dồn |
| Con Bạc | Thủ/Gai | Liều là cờ bạc, khiên là bảo hiểm; Nứt 35% mà viên khiên chỉ Nứt 15% thì Liều hai lần mới đáng |
| Tam Tấu | Chốt/Nổ | BỘ nổ AoE gặp viên cuối nổ thêm: tận dụng đội nhiều quái |
| Giữ Lửa | Xúc xắc/Nhịp | giữ viên lâu, Mặt Tạm rẻ |
| Đồng Tộc | chưa có | không combo nào hiện theo class; xin hỏi tác giả keystones-v1 có muốn thêm combo class |

Ba chỗ nối: (1) **Cộng hưởng**: combo thuộc gia đình ruột của Lõi chủ thì tham số mutation x1.5 (có trần); (2) **thiên vị offer** (như keepsake Hades): Lõi thuộc gia đình ruột có trọng số xuất hiện +25% trong offer, tính trước lúc bốc nên không phá rng đã seed; (3) chip "With:" đã có trên thẻ Core thêm tên Lõi chủ khi Lõi đó thuộc gia đình ruột. Kết quả: lúc vào run người chơi chọn Lõi chủ, thấy luôn "mình săn cái gì", và Lõi thường biến thành mảnh ghép của một hướng chứ không còn lơ lửng.

Giới hạn chống chồng, vì Khiên Gai thuộc 4 combo: mỗi gia đình tối đa 1 mutation; mỗi run tối đa 2 Duo + 1 Thức tỉnh đang bật.

**Giữ độ khó** (expert 18.8%, random 11%): (a) Đủ chỉ 2.5-13.6% run nên cú mạnh tầng Đủ ít kéo trung bình; Cặp 30-72% nên Cặp phải nhẹ. Ngân sách đề nghị: Duo ≈ một Lõi Hổ Phách, Thức tỉnh ≈ một Lõi Tinh Thể. (b) Mỗi mutation có điều kiện (mất Lõi nào của Cặp là tắt) và một cái giá nhỏ khi mạnh (Thức tỉnh một lần mỗi trận, trần Gai, Overcast lần 2 đắt hơn). (c) Sau khi sim, chỉnh `enemy_dmg_mult` (đang 1.55) một lần cho tổng quay về mục tiêu: dự đoán sẽ nhích lên khoảng 1.6-1.7 nếu bot săn combo thắng thêm 3-4 pp. Đây là con số đoán, sim mới quyết.

## 4. Đo được thế nào

Dùng khung sim đã có (`godot/tools/sim_combo_draw.tscn` đo xác suất ráp; sim run bot 4 loại: random/spam/expert/hunt). Thêm chế độ "ép combo": ép đúng hai Lõi của Cặp (hoặc ba của Đủ) vào run, đối chứng ép hai Lõi cùng bậc không thuộc combo nào, 2000 run mỗi ô, cùng seed.

| Chỉ tiêu | Mục tiêu khởi điểm |
|---|---|
| Lift của Cặp (ép combo vs đối chứng) | +2 đến +5 pp mỗi combo |
| Lift của Đủ | +5 đến +10 pp mỗi combo |
| Không combo nào trội | chênh giữa combo mạnh nhất và yếu nhất trong cùng bậc <= 4 pp; không combo nào lift Đủ > 12 pp |
| Săn combo thắng hơn rõ | bot hunt vs random cùng kỹ năng xúc xắc: win-rate hunt cao hơn >= 3 pp (hiện chưa đo được vì combo chưa có sức mạnh) |
| Độ khó tổng | expert 18.8% ±1.5, random 11% ±1.5 sau khi chỉnh `enemy_dmg_mult`; khoảng cách expert-random không co lại dưới 6 pp (nếu co thì mutation quá mạnh, kỹ năng thôi quan trọng) |
| Tỉ lệ chọn | thẻ hoàn thiện combo được lấy khi xuất hiện >= 55% (người chơi thấy đáng), nhưng không Lõi thường nào > 60% offer |
| Khoảnh khắc thấy được | mỗi combo log số lần mutation thực sự đổi kết quả (Overcast rẻ được dùng, Nứt né được...) >= 1 lần mỗi trận ở >= 70% trận có combo; nếu không thì mutation "vô hình" (đúng lỗi relic cũ: không thấy trong play) |

Playtest: Liam chơi 5 run, mỗi run ép một gia đình, trả lời "lúc ráp xong mình có đổi cách chơi lượt kế không?". Thêm test tự động: mỗi combo có test "ráp Cặp thì tham số X đổi, mất một Lõi thì quay về", cộng test tamper replay cho mutation.

## 5. Câu hỏi cho Liam

1. **Hướng nào?** Khuyến nghị: B làm nền (Cặp = Duo theo gia đình), thêm Thức tỉnh riêng cho 4-5 combo ở tầng Đủ sau. Hay Liam muốn A thuần (đắt hơn, mỗi combo một câu chuyện)?
2. **Cặp có sức mạnh thật không?** Khuyến nghị: có, nhẹ và có điều kiện (đảo chốt 22/10 "B không sức mạnh"). Nếu giữ Cặp không sức mạnh thì đột biến chỉ còn ở Đủ (2.5-13.6% run), khó cảm nhận.
3. **Giữ độ khó bằng cách nào?** Khuyến nghị: mỗi mutation có điều kiện + giá nhỏ, rồi chỉnh `enemy_dmg_mult` một lần sau sim. Phương án khác: chỉ bù bằng dmg_mult (đơn giản nhưng người không ráp combo bị phạt oan).
4. **Nối Lõi chủ và stage?** Khuyến nghị: có (cộng hưởng x1.5 + offer +25% cho gia đình ruột), Cặp mở từ stage 2, Đủ + Cộng hưởng từ stage 3 cùng lúc Lõi chủ xuất hiện (tránh người mới bị quá nhiều khái niệm; v4 đã chốt tối đa 4 khái niệm mới mỗi stage).

## Ghi chú

- Mọi đổi luật => bump RULES_VERSION chung lúc merge (làn GD không tự bump, theo `gacha-contract.md`); fingerprint chạm `assets/data/rules/` và `scripts/core/`.
- Đồng Tộc chưa có combo ruột: để tác giả keystones-v1 quyết.
- Việc phát sinh ngoài phạm vi: Lõi chủ mới ở stage 3 sẽ làm số người thấy Đủ + Cộng hưởng nhỏ; có thể cân nhắc Hades-style "ghim" combo yêu thích ở màn chọn Lõi, không nằm trong brainstorm này.
