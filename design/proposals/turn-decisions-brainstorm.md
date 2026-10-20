# Brainstorm: quyết định trong lượt (chi phí cơ hội)

Trạng thái: BRAINSTORM, chờ Liam duyệt. Chưa có gì được làm. Không đụng code.
Ngày: 2026-10-20. Người viết: game-designer.
Bằng chứng gốc: `my-game-wt/SB/production/qa/sim/sim-2026-10-20-main_final_A0.md` (2000 run/bot, Short A0):
random 20.6%, spam 22.8%, expert 28.6%. Tay nghề chỉ +8 điểm. Beam sâu hơn không thắng thêm, bật Hold làm
expert tệ đi ~4 điểm, reroll tốn mana không giúp, chọn Lõi theo combo không tạo khác biệt rõ.

Mục tiêu Liam: người biết chơi và ghép Lõi thắng 15-25%, bừa/spam <=5%, tay nghề >=15 điểm, run sau khác run trước,
dice + vị trí + Lõi + mana khớp nhau, Lõi tác động thấy được.

---

## 1. Chẩn đoán cấu trúc

Một câu: **trong lượt này, dùng mọi viên luôn là đúng, và mỗi viên đúng độc lập với viên khác**. Không có cái gì phải
từ bỏ. Chi tiết, dẫn engine (`godot/scripts/core/combat_engine.gd`):

1. **Dùng viên không có giá.** `use_die` (dòng 1160) chỉ kiểm: đang EXECUTE, viên còn sống, đã tung, chưa dùng, không
   bị Hold. Không tốn mana, không tốn lượt, không giới hạn số viên. Viên không dùng thì mất hẳn khi `begin_end_turn`
   (1711). Vậy bỏ một viên chỉ có mất, không có được. Đây là gốc rễ: chi phí cơ hội = 0.
2. **Giá trị tuyến tính, cộng độc lập.** `_face_value` (1392): value + growth, nhân thêm chỉ khi vital, overdrive,
   cộng hiveMind, và **cộng hưởng chỉ x1.15** (`RESONANCE_MULT`, dòng 34, áp ở 1416). Viên A không đổi giá trị
   viên B (trừ vài relic). Tổng sát thương = tổng các viên, thứ tự dùng không đổi kết quả. `first_used` (1332) chỉ
   phục vụ relic firstEcho, ngoài ra thứ tự không có nghĩa gì trong luật.
3. **Mục tiêu gần như hiển nhiên.** Đánh dmg: dồn vào con yếu nhất / con sắp chết; shield/heal: vào Axie sắp bị đánh
   (intent hiện sẵn, `_pick_enemy_intent` 650-689). Quái chọn mục tiêu ngẫu nhiên trong hàng trước (hoặc đánh kẻ
   yếu nhất nếu assassin) nên người chơi không phải đoán gì khó. Và vì giá trị tuyến tính, không có ngưỡng để "vừa đủ"
   hay "dư thừa": sát thương dư không tạo ra thứ gì khác ngoài sát thương dư.
4. **Mana không có chỗ tiêu hay.** Mana chỉ tăng ở mặt mana (1616). Chỗ tiêu chính là reroll: 1 lần free
   (`reroll_free_per_turn` 917), từ lần 2 tốn 2 mana, tối đa 4 lần (`reroll_is_payable` 923, `reroll_mana_cost` 928).
   Tung lại một viên đang tốt = mất, viên xấu thì ít khi cứu được cả lượt. Sim xác nhận: reroll tốn mana không giúp.
5. **Hold không có lời.** `stash` (1278): cất 1 viên (cap 1, knob `stash.cap`), nó giữ mặt sang lượt sau, "No mana".
   Nhưng viên đó mất hành động lượt này và lượt sau nó vẫn chỉ là một viên giá trị y nguyên. Hold = hoãn, trả giá
   một viên hôm nay, không đổi lại gì. Khớp với sim: bật Hold làm expert tệ hơn ~4 điểm. Chỉ có Core (steady_hold,
   tundra) mới biến Hold thành có lợi, nên Hold hiện là cái bẫy cho người chưa có Core đó.
6. **Vị trí chỉ phòng thủ, không phải quyết định tấn công.** Hàng trước/sau (`front_row_targets` 718) chỉ chọn ai bị
   đánh. Không có gì buộc người chơi đổi hàng giữa trận hay đặt Axie theo vai trò tấn công. Xếp một lần đầu run
   rồi thôi.
7. **Undo miễn phí** (`undo_last`, 1301) nên người thật thử sai thoải mái. Không phải lỗi, nhưng nghĩa là "quyết định"
   phải nằm ở thứ undo không cứu được (mana đã tiêu, Hold, số viên dùng được, ngưỡng quái).
8. **Đội thống trị kết quả** (reptile_bug 38% vs aqua_plant 13.5%): vì giá trị là tổng tuyến tính, đội có tổng
   dmg cao thắng, tay nghề chỉ là phần nhỏ. Muốn tay nghề quan trọng thì phải có thứ mà tổng thô không giải quyết được.

**Reviewer sửa / bổ sung (20/10, đã grep code + đọc file sim):**

- Mục 1, 4, 5, 7 đúng. Dòng code dẫn ra đều khớp (`use_die` 1160, `RESONANCE_MULT` 34/1417, `stash` 1278,
  `undo_last` 1301, `begin_end_turn` 1711).
- Mục 2-3 **cũ so với depth v3** (đã merge ở 759cabc, sim chạy trên bản này vì có Lõi): `combat_traits.gd` đã có
  Plating (mỗi đòn đơn mục tiêu bị trừ P, tối thiểu 1, debuff/poison tắt Plating vài lượt), Ward, Mend, Spite và
  Charge (đòn nạp báo trước 1 lượt, x2.5, chỉ phá được bằng stun/freeze: `charge_on_stun` dòng 312). Tức là game
  **đã có** phi tuyến và thứ tự (debuff trước rồi mới đánh). Câu hỏi đúng không phải "thiếu phi tuyến" mà là
  "vì sao Plating/Charge đã có mà tay nghề vẫn chỉ +8". Giả thuyết: (a) Plating chỉ ở vài quái (cap trait), cách
  phá nó là thuộc tính của đội (`team_can_break`) chứ không phải quyết định trong lượt; (b) Charge chỉ ở Elite có
  affix và chỉ stun phá được, đội không có stun thì không có gì để quyết; (c) chưa rõ bot expert có biết đánh debuff
  trước để mở Plating và để dành stun cho lượt nạp không. Cần kiểm (c) trước khi kết luận.
- Thêm từ file sim: **boss cuối r18 là bức tường chung**. Tới r18 random còn 46%, thắng 21%; expert còn 58%,
  thắng 29%. Cả hai đều mất khoảng một nửa ở boss cuối, tức tay nghề không giúp gì ở trận quan trọng nhất. Phần
  chênh lệch +8 đến từ Elite và boss giữa. Phương án nào được chọn cũng phải làm boss cuối thành bài đọc nhịp.
- Trận ngắn: battle trung bình 3.5 lượt, boss 6.9. Thứ gì trả lời "lượt sau" (Hold ủ) chỉ có đất ở boss/elite.
- "Lõi combo không khác biệt": trong sim expert **chỉ chạy với Lõi combo**, nên chưa đo được Lõi có giúp expert
  không. Các bot khác: combo hơn random 2-3 điểm với n~665 mỗi nhánh (sai số chênh lệch ~2.3), tức là chưa kết luận
  được gì, không phải "đã chứng minh bằng 0".
- `attack_only` đã 5.0%: anti-spam của v3 có tác dụng với lối chơi suy biến nhất, chỉ chưa đủ với bừa có pha trộn.

Hệ quả: người bừa (dùng hết, mục tiêu tuỳ ý) và người giỏi chỉ khác ở mục tiêu, mà mục tiêu ít quan trọng. Cộng thêm
bot random thắng 20% nghĩa là **game đang quá dễ với người không suy nghĩ**: cần cả "có quyết định" lẫn "bỏ quyết định
thì trả giá".

Lưu ý quan trọng cho mọi phương án: muốn random <=5% thì độ khó nền phải tăng ở chỗ "bừa" bị phạt, không phải tăng
đều (tăng đều làm expert cũng tụt xuống dưới 15%).

---

## 2. Các phương án tạo chi phí cơ hội

Quy ước chi phí: S <= 1 ngày engine + test, M ~ 2-4 ngày, L > 1 tuần. "Replay": mọi luật đổi trong `scripts/core/`
đều phải bump `RULES_VERSION` + deploy Worker (theo godot/CLAUDE.md); hành động MỚI (người chơi bấm gì đó mới) còn phải
vào `ActionLog` và `RunVerifier` (t_replay, Worker verify). Tôi chưa đọc code Worker, mục "Worker" ghi mức dự đoán.

### P1. Ngân sách hành động (Action Budget)
- **Mô tả:** mỗi lượt chỉ dùng được N viên (mặc định N=3 trên 5). Viên không dùng không mất trắng: chọn một trong
  (a) đổi thành 1 mana, (b) Hold (cap vẫn 1), (c) Phòng thủ: +khiên nhỏ (vd 2) cho chính Axie đó. Lõi/relic tăng N hoặc
  làm lợi cho viên thừa.
- **Ví dụ lượt:** tung ra dmg 6, dmg 4, poison 3, shield 5, heal 4. Quái A sắp đánh 9 vào Axie shield. Chọn 3: dmg 6 +
  dmg 4 (giết con yếu) + shield 5, bỏ poison và heal (thành 2 mana). Hoặc dmg 6 + poison 3 + heal 4 nếu mình chịu được.
- **Quyết định tạo ra:** viên nào đáng dùng nhất lượt này, viên thừa thành mana / Hold / khiên, trade dmg-vs-phòng thủ.
- **Vì sao bot bừa thua:** random dùng 3 viên ngẫu nhiên, bỏ viên mạnh nhất khoảng 40% số lượt. Spam (dùng theo thứ tự cố định) cũng không biết bỏ viên nào. Expert chọn tập con tối ưu: gap rõ.
- **Chi phí:** M. Chặn trong `use_die`, thêm hành động "đổi viên thành mana/khiên" (action mới).
- **Replay/Worker:** có. Hành động mới + RULES_VERSION. Worker verify phải học action mới.
- **Rủi ro:** cảm giác "bị cấm" với người mới; giảm sát thương tổng nên phải chỉnh lại HP quái; tutorial phải dạy.
  Giảm: N=4 cho bậc đầu, N=3 từ run 2.
- **Reviewer: cách trình bày để không thấy "bị cấm" (khuyến nghị thay cho bản trên):**
  - Đừng gọi là "chỉ dùng 3 trên 5". Gọi là **3 Đòn + Nạp**: mỗi lượt có 3 ô "Đòn"; viên nào không ra đòn thì
    **tự Nạp** khi kết thúc lượt, không cần bấm thêm. Mọi viên đều làm gì đó, người chơi vẫn được tung đủ 5 viên.
  - Nạp ra thứ gì thì theo **class của Axie**, không cho chọn (vd aqua/bird: +1 mana; reptile/plant: khiên nhỏ cho
    chính nó; beast/bug: +1 growth cho mặt đó). Lợi: không có hành động mới (chỉ RULES_VERSION, không đụng
    ActionLog/Worker verify), class có thêm bản sắc, và việc chọn "viên nào Nạp" có hai chiều (mất đòn gì, được gì).
  - Giá trị Nạp nên tăng theo mặt tung được (vd mặt >= 5 Nạp gấp đôi), để bỏ một viên to là đau thật mà vẫn có lời.
    Nếu Nạp chỉ là +1 cố định, viên to luôn được ra đòn và quyết định lại thành hiển nhiên.
  - UI: viên đã Nạp hiện trước "-> +1 mana" khi trỏ vào; thanh 3 ô Đòn sáng dần. Chữ là "Nạp", không phải "bỏ".
  - Cảnh báo: sát thương mỗi lượt giảm ~40% nên battle 3.5 lượt sẽ thành 5-6 lượt nếu không giảm HP quái. Chỉnh
    HP cùng lúc, đừng để game chậm đi. Plating (trừ theo từng đòn) cũng nhẹ đi vì ít đòn hơn, phải tune lại.

### P2. Mana thành tiền tệ chính: Overcast
- **Mô tả:** trả mana để "nạp" một viên: 2 mana = x1.5 giá trị (làm tròn lên), hoặc đổi mục tiêu thành AoE, hoặc
  dùng viên lần 2 nửa giá trị (Echo). Reroll vẫn giữ nhưng không còn là chỗ tiêu chính. Mặt mana trở thành "mặt
  vàng" thay vì mặt kém.
- **Ví dụ:** có 4 mana. Dmg 6 vào boss, Overcast (2) = 9. Heal 4, Overcast (2) = 6 vì Axie sau sắp chết. Còn 0 mana,
  lượt sau phải tung được mặt mana mới.
- **Quyết định:** tiêu mana ở đâu (tấn công / phòng thủ / dành cho lượt boss), có nên giữ mana qua lượt không.
  Đây là loại quyết định có chi phí cơ hội thật (mana không tiêu được hai lần).
- **Vì sao bot bừa thua:** random tiêu mana bừa vào viên yếu; spam không bao giờ tiêu mana hoặc tiêu hết lập tức. Expert
  nhắm vào viên đổi được điểm giá trị cao nhất so với giá.
- **Chi phí:** M. `mana` đã có trong state (dòng 306, 1618); thêm hành động.
- **Replay/Worker:** có (action mới).
- **Rủi ro:** snowball (mana + Overcast + Lõi x giá trị); cần trần Overcast 1 lần/viên. Mana nghèo hiện nay (chỉ
  vài mặt mana) phải tăng nguồn, nên đụng cân bằng part.

### P3. Cặp mặt (Pair/Link thật sự)
- **Mô tả:** hiện đã có cộng hưởng nhưng chỉ x1.15 (dòng 34/1416), quá nhỏ để đổi quyết định. Làm thành cặp có
  hiệu ứng: dùng hai viên liên tiếp cùng loại (dmg+dmg) thì viên sau x1.5; hoặc cặp khác loại có tên (poison rồi dmg =
  "Độc nổ": dmg viên sau + stack độc hiện có; shield rồi heal = "Ủ ấm": heal gấp đôi lên Axie có khiên).
  Cặp theo class (vd Plant+Aqua) thêm hiệu ứng riêng.
- **Ví dụ:** dice: poison 3, dmg 4, dmg 5, shield 5, heal 3. Chuỗi A: poison trước rồi dmg 5 vào cùng mục tiêu: nổ
  thêm +3. Chuỗi B: dmg 5 rồi dmg 4 (cùng loại) = 5 + 6. Mỗi chuỗi đòi mục tiêu và thứ tự cụ thể.
- **Quyết định:** nhìn 5 viên nào ghép được với nhau, hy sinh viên nào để chuỗi đứt, đặt target để cặp hợp lệ.
- **Vì sao bot bừa thua:** random xác suất đúng thứ tự + đúng mục tiêu thấp, mất bonus lớn. Spam theo thứ tự cố định
  chỉ thi thoảng ăn.
- **Chi phí:** M (luật) + UI chỉ thị "LINK" rõ (đã có `float_text` LINK).
- **Replay/Worker:** chỉ RULES_VERSION, không action mới (chỉ sửa công thức).
- **Rủi ro:** bảng cặp lớn nên khó học; mở bằng 3 cặp. Người chơi mới thấy rối nếu không có gợi ý "viên này nối được với
  viên kia".

### P4. Thứ tự có thưởng: Mồi / Kết / Chuỗi
- **Mô tả:** viên dùng đầu tiên trong lượt là "Mồi" (hiệu ứng trước), viên cuối là "Kết". Mặt có keyword Mồi mạnh hơn
  khi dùng đầu (vd debuff, poison), mặt Kết mạnh hơn khi dùng cuối (dmg mạnh x1.5 nếu mọi viên khác đã dùng). Chuỗi:
  mỗi viên cùng class liên tiếp +1 giá trị cho viên tiếp.
- **Ví dụ:** vulnerable (Mồi) trước, rồi 2 dmg, cuối cùng dmg Kết x1.5. Đổi thứ tự = mất khoảng 30% tổng.
- **Quyết định:** sắp xếp thứ tự là một bài toán; Kết nên dành cho viên nào.
- **Vì sao bot bừa thua:** thứ tự random ăn bonus 1/n! số lần; spam theo slot cố định có thể trùng nhưng sai khi tung đổi.
- **Chi phí:** M. Có chỗ gắn sẵn (`first_used`, 1332).
- **Replay/Worker:** chỉ RULES_VERSION.
- **Rủi ro:** làm UI thứ tự dùng rõ (hiện viên "Kết" bị khoá đến khi dùng hết viên khác?). Người thật mất nhiều click hơn.
  Nên gộp chung với P3 để khỏi hai hệ thứ tự.

### P5. Hold biến thành "ủ" (Hold có lời)
- **Mô tả:** viên Hold qua lượt thì +50% giá trị (+100% sau 2 lượt, trần). Đổi lại: chiếm cap, chết là mất, quái có
  affix có thể phá. Giữ cap 1 (Core nới lên).
- **Ví dụ:** dmg 5 hiện chưa giết được boss 14 HP. Hold, lượt sau nó thành 8 cùng 2 viên khác = giết gọn. Nhưng
  trong lúc đó mình lỡ mất 5 dmg lượt này và quái đánh trước.
- **Quyết định:** đầu tư vào tương lai hay ăn ngay, đặt cược vào nhịp boss (biết trước nhịp, nên Hold trước lượt vulnerable/Hollow).
- **Vì sao bot bừa thua:** random không Hold hoặc Hold sai chỗ (sim hiện đã thấy Hold sai làm tụt ~4 điểm).
  Expert Hold đúng nhịp boss thắng rõ.
- **Chi phí:** S. `stash` và `_face_value` có sẵn, thêm bộ đếm lượt Hold.
- **Replay/Worker:** chỉ RULES_VERSION (không action mới).
- **Rủi ro:** thấp. Nếu một mình, Hold lời + vài lượt boss có thể thành chiến thuật chủ đạo (đỏ: "Hold mọi lượt"): cap 1 + giá
  trị tối đa ngăn.

### P6. Ngưỡng làm choáng (Stagger): giá trị phi tuyến
- **Mô tả:** quái có "Đòn nạp/đe doạ" (đã có intent, `_pick_enemy_intent`): nếu một viên dmg ĐƠN LẺ chạm ngưỡng T (vd
  8) hoặc tổng sát thương lượt này lên con đó đủ T, intent bị huỷ (hoặc yếu đi nửa). Dưới ngưỡng thì vô ích với cái
  intent đó. Tương tự "khiên đủ dày": nếu tổng khiên >= intent thì quái bị phản (Thorn đã có, uncapped).
- **Ví dụ:** Brute chuẩn bị đánh 14 vào Axie sau lưng. Mình có dmg 6, 5, 4. Dồn cả ba vào Brute (15 >= 12) huỷ đòn, hoặc
  chia cho con lẻ 5 HP và chịu 14. Ngưỡng làm "dư/thiếu" thành có nghĩa.
- **Quyết định:** dồn hay chia, giết con nào, kiểm soát hay chịu đòn rồi giết nhanh. Rất giống Into the Breach (xem
  quái định làm gì rồi bẻ nó).
- **Vì sao bot bừa thua:** random chia đều, không bao giờ chạm ngưỡng, ăn đủ đòn đe doạ mỗi lượt.
- **Chi phí:** M (engine + data quái), UI: thanh ngưỡng trên intent (UX cần cho).
- **Replay/Worker:** chỉ RULES_VERSION (không action mới).
- **Rủi ro:** nếu ngưỡng hơi dễ chạm thì vô nghĩa, quá khó thì thành cô lập; cần sim để tune. Boss đã có nhịp (Hollow)
  nên đừng chồng 2 hệ.
- **Reviewer:** đừng làm hệ mới. Charge (depth v3) đã là "đòn nạp báo trước", chỉ thiếu cách phá thứ hai. Làm P6 =
  **mở rộng Charge**: lượt quái đang nạp, dồn đủ T sát thương vào nó thì phá (hoặc giảm nửa), ngoài stun như cũ.
  Rẻ hơn (data + UI thanh ngưỡng đã gắn với icon nạp), dạy một lần, và đây là chỗ hợp nhất để biến boss cuối r18
  thành bài đọc nhịp. Đội không có stun lúc đó cũng có lựa chọn.

### P7. Hộ vệ và quái hỗ trợ (ưu tiên mục tiêu)
- **Mô tả:** một số quái là Hộ vệ: khi nó sống, các quái khác nhận -50% (hoặc Cap 1 sát thương/viên) từ đòn đơn mục
  tiêu, trừ AoE/pierce. Quái hỗ trợ (healer, buffer) ở hàng sau của quái, khó chạm (cần AoE/pierce hoặc giết Hộ vệ). Giết
  nhầm thứ tự = đánh thùng rỗng.
- **Ví dụ:** 3 quái: Guardian 8 HP, Healer 5 HP, Brute 12 HP. Đánh Brute trước thì Healer hồi + Guardian giảm. Phải
  xử lý Guardian trước hoặc AoE.
- **Quyết định:** ai chết trước, có đáng tốn Axie AoE/pierce vào đây không. Làm cho đội hình (Axie nào mang AoE) quan trọng
  hơn.
- **Vì sao bot bừa thua:** random đánh lung tung thì bị giảm sát thương liên tục. Spam đánh "mục tiêu đầu danh sách" thì
  thắng nếu Guardian nằm đầu, nên vị trí Guardian phải ngẫu nhiên theo trận.
- **Chi phí:** M (data quái + 1 trạng thái "guarded").
- **Replay/Worker:** chỉ RULES_VERSION.
- **Rủi ro:** làm UI dễ đọc ai đang được bảo vệ; trên mobile/nhỏ khó đọc. Nếu Guardian xuất hiện mọi trận thì thành thủ tục.

### P8. Đổi hàng trong lượt (vị trí thành quyết định)
- **Mô tả:** mỗi lượt có 1 lần đổi chỗ hai Axie (tốn 1 mana, hoặc free ở Lõi). Hàng trước/sau ảnh hưởng ai nhận
  đòn (đã có) và thêm: mặt "Reach" chỉ tấn công được từ hàng sau, mặt "Rush" mạnh hơn từ hàng trước. Axie bị đánh
  còn sống thì giữ đội cho đúng hàng trước lượt kế.
- **Ví dụ:** quái nhắm hàng trước. Đổi Axie mỏng máu ra sau, đưa Tank ra, mất 1 mana nhưng giảm thương vong; hoặc
  để Axie mỏng ở trước làm mồi nhử vì đã có khiên.
- **Quyết định:** tiêu 1 mana vào vị trí hay vào Overcast/reroll; vị trí động theo intent (đặt Axie yếu khỏi tầm đánh).
- **Vì sao bot bừa thua:** random đổi bừa mất mana và hàng sai; spam không đổi nên ăn đòn vào Axie yếu.
- **Chi phí:** M-L (action mới + UI kéo hàng; Hàng đã có `row_of` 700).
- **Replay/Worker:** có (action mới).
- **Rủi ro:** UI rối; một số quái (assassin, AoE) vô hiệu hoá toàn bộ lợi ích; chỉ có ý nghĩa nếu P2 cho mana chỗ tiêu.

### P9. Ô nhận xúc xắc kiểu Dicey Dungeons (slot)
- **Mô tả:** mỗi Axie (hoặc mỗi hàng) có một "ô" với điều kiện: "nhận mặt >= 4: nhân đôi", "nhận mặt chẵn: +khiên".
  Người chơi không chọn mục tiêu cho viên mà chọn viên nào vào ô nào.
- **Quyết định:** ghép đúng viên vào đúng ô, nên ô là phần chính của Lõi.
- **Chi phí:** L và đổi hẳn cách người chơi nhìn lượt (hiện mỗi viên thuộc về một Axie, ô sẽ lệch với hệ part-face).
- **Rủi ro:** phá giá trị bản sắc part (mỗi Axie đã có xúc xắc riêng). Ghi lại để biết, **không khuyến nghị** làm lúc này.

### P10 (reviewer thêm). Lõi chủ (Keystone) đặt điều kiện cho lượt
- **Mô tả:** giống ngọc chính trong LoL (Electrocute, Conqueror): mỗi run chọn **một** Lõi chủ trong 3, nó đặt một
  điều kiện về **hình dạng lượt**, đạt thì nổ hiệu ứng lớn. Ví dụ: "Sấm: 3 Đòn khác loại vào cùng một quái trong
  lượt -> +6 sát thương lên nó"; "Thuỷ triều: lượt có ít nhất 2 viên Nạp -> lượt sau +1 Đòn"; "Gai đá: kết thúc lượt
  mà khiên đội >= tổng intent -> phản bằng Thorn". 49 Lõi hiện có làm ngọc phụ, Lõi nào móc vào Lõi chủ thì mạnh lên.
- **Vì sao hơn P3:** P3 bắt người chơi học cả bảng cặp. P10 chỉ có một điều kiện, của riêng mình, hiện trên HUD. Đây
  là chỗ trực tiếp làm "chọn Lõi theo combo" có ý nghĩa: Lõi chủ đổi tập viên tối ưu mỗi lượt, nhất là khi có P1
  (3 Đòn = đúng 3 đòn của Sấm).
- **Thấy được:** icon Lõi chủ cạnh thanh Đòn, đếm 1/3, 2/3, nổ to khi đạt.
- **Chi phí:** M (6-8 Lõi chủ, luật chỉ là đếm trong lượt, `first_used` / bộ đếm lượt đã có). Chỉ RULES_VERSION.
- **Rủi ro:** điều kiện quá dễ thì thành +X; quá khó thì không ai chọn. Mỗi Lõi chủ cần một điều kiện mà random
  đạt < 20% số lượt, expert đạt > 60% (đo được bằng sim).

Tham khảo nên đặt cạnh mọi phương án: **Slice & Dice** có đúng cấu trúc này (5 nhân vật, mỗi người 1 viên 6 mặt).
Cái làm nó sâu là khoá/tung lại có giới hạn trước khi chốt, cộng intent quái hiện chính xác để chặn vừa đủ. Reroll
ở mình đang vô ích; nếu sau P1 reroll vẫn vô ích thì đổi sang "khoá viên, tung lại phần còn lại" kiểu S&D.

Ý phụ (S, ghép vào gói nào cũng được, chưa đưa thành phương án): **giảm dần cùng loại**, mỗi lần dùng một loại mặt thêm trong
lượt, các lần sau -15%. Chống spam dmg, buộc pha trộn.

---

## 3. Liên kết với Lõi

Vấn đề hiện nay: Lõi hầu như là "+X" lên một công thức tuyến tính, nên chọn Lõi theo combo không tạo khác biệt (sim
xác nhận). Mỗi phương án tạo ra **cạnh** để Lõi móc vào:

| Phương án | Lõi làm gì (ví dụ cụ thể) | Thấy được |
|---|---|---|
| P1 ngân sách | Lõi +1 viên dùng được; Lõi biến viên thừa thành khiên/mana x2; Lõi "viên thừa tung lại free" | Số ô sáng trên thanh viên, viên thừa có hiệu ứng riêng |
| P2 Overcast | Lõi giảm giá Overcast; Lõi "Overcast dmg cũng AoE"; Lõi hoàn mana khi giết | Vòng mana + chữ OVERCAST trên viên |
| P3 cặp | Lõi thêm cặp mới (vd poison+heal = Hồi độc); Lõi nới cặp lên khác loại | Đường nối giữa hai viên, nhãn tên cặp |
| P4 thứ tự | Lõi cho thêm "Mồi" thứ hai; Kết không khoá | Huy hiệu 1/Kết trên viên |
| P5 Hold ủ | Lõi tăng cap Hold, ủ nhanh hơn (đã có steady_hold, tundra: đổi sang tăng tốc ủ) | Viên Hold phát sáng theo số lượt ủ |
| P6 Stagger | Lõi giảm ngưỡng, hoặc dmg dư sau stagger chuyển thành Thorn | Thanh ngưỡng trên intent đầy lên |
| P7 Hộ vệ | Lõi pierce miễn nhiễm Guard; Lõi "Guard bị phá nhận dmg thêm" | Khiên vàng trên quái được bảo vệ |
| P8 đổi hàng | Lõi đổi hàng free; hàng sau cũng nhận buff hàng trước | Mũi tên đổi chỗ |

Điều kiện để ghép Lõi quan trọng: Lõi phải cùng một "ngôn ngữ" với phương án đã chọn. Vì thế **một gói nhỏ có chủ đề**
tốt hơn rải đều 9 phương án. Quy tắc cho 49 Lõi: Lõi nào không móc vào ít nhất một trong các cạnh trên (viên dùng,
mana tiêu, cặp, thứ tự, Hold, ngưỡng, mục tiêu) thì xem lại, vì đó là Lõi "+X" không tạo khác biệt.
Kiểm bằng sim bot "Lõi đúng combo" vs "Lõi ngẫu nhiên" (mục 4).

---

## 4. Gói đề xuất, khuyến nghị, kế hoạch đo

### Gói A "Đánh đổi" (kinh tế lượt): P1 + P5 + P2
Dice -> hành động / mana / ủ. Viên thừa có chỗ đi: mana (nuôi Overcast), Hold (ủ lời), hoặc khiên. Một vòng khép kín.
- Mạnh: đập thẳng vào gốc rễ (chi phí cơ hội = 0); Lõi có 3 cạnh để móc.
- Yếu: nặng cho người mới; thêm 2 action mới (đổi viên, Overcast) nên đụng replay/Worker; chỉnh lại HP quái.
- Chi phí: M+S+M ~ 1-1.5 tuần.

### Gói B "Đọc quái" (chiến thuật mục tiêu): P6 + P7 + P4
Giữ nguyên dùng 5 viên, nhưng giá trị phi tuyến: ngưỡng làm choáng, Hộ vệ, thứ tự. Kiểu Into the Breach.
- Mạnh: không có action mới (chỉ RULES_VERSION), người mới dễ nhận ra vì quái "nói" rõ chuyện gì; tốt cho tay nghề đọc.
- Yếu: không chạm gốc rễ #1, lượt vẫn "dùng hết"; Lõi móc ít hơn (chỉ ngưỡng, thứ tự); công việc data quái nhiều.
- Chi phí: M+M+M ~ 1-1.5 tuần.

### Gói C "Combo" (ghép): P3 + P4 + P5
Cặp mặt + thứ tự + Hold ủ. Hợp tính "Lõi + vị trí ghép" nhất, kiểu Balatro. Rủi ro: bảng cặp lớn, UI dày.
- Chi phí: M+M+S, không action mới.

### Khuyến nghị
**Gói A làm lõi, thêm P6 từ gói B làm "áp lực"**: P1 làm lượt có chi phí, P6 làm cho mỗi viên có ngưỡng (phi tuyến) nên
bừa bị phạt và mana/Hold có lý do tồn tại. Làm theo thứ tự P1 -> P5 (rẻ nhất, thử sớm) -> P6 -> P2. Dừng đo sau mỗi bước, không
làm cả gói rồi mới đo. P3/P4 để sau (nếu Lõi vẫn không tạo khác biệt thì đây là bước kế). P8/P9 không làm lúc này.

Đây là suy đoán của tôi, quyết định thuộc Liam.

**Reviewer đổi thứ tự (lý do ở "Ghi chú reviewer"):**
0. Bước 0, không đổi luật: sửa bot + đo lại (xem dưới). Nếu expert hiện chưa biết mở Plating bằng debuff và để
   dành stun cho Charge thì gap thật có thể lớn hơn +8, và mọi dự đoán dưới đây phải tính lại.
1. P1 dạng "3 Đòn + Nạp tự động theo class" (không action mới), sim hai nhánh N=4 và N=3, chỉnh HP quái cùng lúc.
2. P6 dạng mở rộng Charge (phá bằng ngưỡng sát thương), áp cho cả boss cuối r18.
3. P10 Lõi chủ, 6 cái đầu, móc vào thanh Đòn / Nạp / Charge.
4. P2 Overcast chỉ làm nếu sau bước 1 mana vẫn không có chỗ tiêu tốt (nó là action mới duy nhất trong gói, gom
   Worker một lần). P5 Hold ủ để cuối: trận ngắn (3.5 lượt) nên tác động nhỏ, và nó tranh chỗ với Nạp.

### Kế hoạch đo bằng sim
Bot cần có (cộng bot mới để so):
1. `random` (hiện có), 2. `spam` (hiện có), 3. `greedy` (dùng hết theo giá trị cao -> thấp, không suy nghĩ), 4. `expert`
cập nhật: **phải được dạy hành động mới** (đổi viên, Overcast, Hold ủ, ngưỡng), nếu không sim đo bot yếu chứ không đo game.
Thêm `expert-depth1` vs `expert-depth3` để kiểm "beam sâu hơn" giờ có lợi (hiện không).

Reviewer sửa: `greedy` **đã có** (23.9% trong file sim), không cần viết. Phải thêm trước khi đo bất cứ luật nào:
- nhánh **expert x Lõi ngẫu nhiên** (hiện expert chỉ chạy Lõi combo, nên chỉ số "Lõi combo vs ngẫu nhiên" của expert
  chưa từng được đo);
- kiểm expert có đánh debuff trước để mở Plating và giữ stun cho lượt Charge không; không thì dạy trước;
- muốn thấy chênh lệch +5 giữa hai nhánh Lõi thì mỗi nhánh cần ~2000 run, không phải ~665 như hiện;
- với P1: bot phải chọn tập viên ra đòn theo giá trị Nạp, không phải "dùng 3 viên đầu". Bot spam/greedy giữ nguyên
  hành vi ngây thơ (đó là thứ ta muốn phạt).

Chỉ số thành công (Short A0, 2000 run/bot, cùng seed ghép cặp; sai số chuẩn ~1 điểm ở 20%):

| Chỉ số | Hiện tại | Mục tiêu |
|---|---|---|
| expert | 28.6% | 15-25% |
| random | 20.6% | <=5% |
| spam / greedy | 22.8% | <=5-8% |
| gap expert - spam | +6 | >= 15 |
| beam depth 3 - depth 1 | ~0 | >= +3 |
| Hold bật vs tắt (expert) | -4 | >= +2 |
| Lõi combo vs Lõi ngẫu nhiên (expert) | không rõ | >= +5 |
| gap đội mạnh nhất - yếu nhất | 38 vs 13.5 (24 điểm) | <= 15 |

Dự đoán (giả thuyết, cần sim sửa): P1 một mình đẩy random xuống ~10-12%, spam ~12%, expert giữ ~24% (gap ~12).
Thêm P6 kéo random/spam xuống ~5-7%. Thêm P5 + P2 đẩy gap trên 15 và làm Hold/mana có lời. Nếu sau P1 gap
<+10 thì dừng, kiểm bot trước khi thêm luật (có thể bot chưa biết dùng).

Thứ tự bước: mỗi bước một nhánh riêng, chạy sim sau từng bước, không đạt chỉ số thì dừng và báo Liam.
Rủi ro đo: chỉ số `random` thấp chưa chắc là game tốt: cần người thật chơi (5 người, 3 run) để xác nhận "tay nghề có cảm
giác thắng" và chịu được tutorial.

---

## 5. Câu hỏi cho Liam (reviewer viết lại, câu quan trọng nhất đầu)

1. **3 Đòn + Nạp:** mỗi lượt ra đòn tối đa 3 viên (run đầu 4), viên còn lại tự Nạp theo class (mana / khiên / growth),
   không phải bấm thêm. Liam chịu không? Khuyến nghị: có. Đây là thứ duy nhất đánh vào gốc "dùng hết luôn đúng".
2. **Lõi chủ kiểu LoL:** mỗi run chọn 1 Lõi chủ trong 3, nó đặt điều kiện cho lượt (vd 3 Đòn khác loại vào một quái);
   49 Lõi cũ làm ngọc phụ. Khuyến nghị: có, viết 6 Lõi chủ trước thay vì sửa 15-20 Lõi "+X".
3. **Phạt bừa bằng quái, không bằng HP:** Charge phá được bằng dồn đủ sát thương (không chỉ stun), và boss cuối dùng
   nhịp này. Khuyến nghị: có, giữ độ khó nền, chỉnh HP chỉ để bù cho P1.
4. **Hành động mới:** chấp nhận thêm Overcast (tiêu mana để x1.5 một viên), tức ActionLog/RunVerifier/Worker học thêm
   một action? Khuyến nghị: để sau bước 1, chỉ làm nếu mana vẫn thừa không có chỗ tiêu.
5. **Đo trước khi đổi luật:** cho 1 bước sửa bot (expert x Lõi ngẫu nhiên, expert biết mở Plating / giữ stun) trước
   mọi thay đổi luật? Khuyến nghị: có, khoảng nửa ngày, nếu không ta có thể đang đo bot kém chứ không phải game nông.

---

## Ghi chú reviewer (creative-director, 20/10)

- **Bất đồng 1, chẩn đoán:** bản gốc nói giá trị tuyến tính, mục tiêu hiển nhiên. Không còn đúng sau depth v3:
  Plating / Charge / Ward đã là phi tuyến và có thứ tự. Vấn đề là chúng là thuộc tính của đội và quái, không phải
  quyết định mỗi lượt. Kết luận gốc (chi phí cơ hội = 0) vẫn đúng.
- **Bất đồng 2, thứ tự P1 -> P5 -> P6 -> P2:** đo P1 một mình với "đổi thành mana" là đo đổi sang thứ vô giá trị (reroll
  vô ích, chưa có Overcast), sim sẽ nói P1 tệ dù ý tưởng đúng. Vì vậy Nạp phải theo class (có khiên / growth) ngay từ
  bước 1. P5 xuống cuối vì trận ngắn.
- **Bất đồng 3, P6 là hệ mới:** không cần, mở rộng Charge là đủ và rẻ hơn.
- **Bất đồng 4, "Lõi combo không khác biệt" là kết luận:** chưa đo được với expert, và cỡ mẫu các bot khác không đủ.
- **Thêm:** boss cuối r18 lấy khoảng nửa số run của mọi bot, đó là chỗ tay nghề cần thấy rõ nhất. P10 Lõi chủ là ý
  tôi cho là đúng nhất với cái Liam thích ở LoL: một lựa chọn lớn đổi cách chơi từng lượt, không phải 1 dòng +X.
- **Đồng ý:** P1 là gốc, Gói B một mình không đủ, P8/P9 không làm lúc này, đo sau từng bước, cần người thật chơi.
- Giữ "tung xúc xắc vui": vẫn tung đủ 5 viên, mặt to vẫn là khoảnh khắc vui; quyết định chỉ đến sau khi tung. Không
  thêm click: Nạp tự động. Nếu thử chơi thấy mỗi lượt nghĩ quá 20 giây thì P10 điều kiện quá rối, cắt bớt.

## Liam trả lời (22/10 rạng sáng), đã chốt
- Bản mới đang DỄ HƠN bản cũ — sai hướng. Tỉ lệ thắng bản mới phải THẤP HƠN bản cũ 5-10 điểm (bản cũ sim: random 20.6%, spam 22.8%, expert 28.6%) và giảm nhiều.
- 1. KHÔNG làm "3 Đòn + Tự Nạp" (không hay). Tìm mechanics mới thật sự tạo độ sâu, hoặc kết hợp nhiều mechanics xác suất/xúc xắc với nhau.
- 2. Có Lõi chủ (kiểu ngọc chính LoL).
- 3. Chọn (a): thưởng người chơi giỏi thật mạnh + tăng độ khó chung; không dùng quái để "phạt" người chơi bừa.
- 4. Có Overcast (trả mana để mạnh một viên), làm độc lập, không cần đi với Tự Nạp. Lý do: mana hiện không có ý nghĩa.
- 5. Sửa bot sim tiếp tục (để đo đúng); chỉ số bản mới phải giảm rõ so với bản cũ.
