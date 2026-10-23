# Anti-spam v5: bot "attack spam" thắng dưới 10%

Trạng thái: ĐỀ XUẤT, chờ Liam duyệt. Chưa code, chưa đụng `combat_tune.json`. Ngày 23/10/2026.
Mục tiêu (Short A0, theo `production/session-state/active.md`): spam 15.5% xuống dưới 10%, expert tự chọn 24.1% về 17-23%, random giữ ≤12% (đang 10.0%).
Ràng buộc của Liam: không "3 strikes + auto-bank", không làm quái mạnh chung chung, phải là cơ chế xúc xắc/xác suất, thưởng kỹ năng, mỗi phiên bản khó hơn.

## 1. Chẩn đoán: vì sao spam còn thắng 15.5%

Đọc `godot/tools/sim_balance.gd` (`_move_attack_spam`, `_play_turn`): bot này KHÔNG phải "chỉ đánh". Nó dùng mặt dmg đầu tiên còn sẵn, nhắm quái ít HP nhất; hết mặt dmg thì `_move_random` dùng nốt mọi viên còn lại (khiên, độc, hồi, mana) lên mục tiêu ngẫu nhiên. Tức là mỗi lượt nó dùng 100% số viên. Nó chỉ không làm bốn việc: không tung lại, không Hold, không Mặt Tạm / Overcast, không tiêu mana.

Số liệu (`production/qa/sim/sim-2026-10-21-oc2-all.md`, bản trước Anchor, spam 10.5%): dmg/lượt spam 18.6, expert 29.2. "V đầu lượt" spam 19.3, expert 23.0 rồi lên 30.2 sau quyết định; V của spam trước và sau quyết định bằng nhau (nó không có quyết định). Boss 1 hạ sau 6.8 lượt (spam) và 4.7 lượt (expert). Kỹ năng hiện chỉ đáng khoảng +57% dmg mỗi lượt, và 43% còn lại là đủ cho spam.

Bốn nguyên nhân:

1. **Sàn quá cao.** Chơi đủ mọi viên mỗi lượt đã cho gần hết giá trị. Kỹ năng chỉ cộng thêm, không có thứ gì mà "không quyết định" là trả giá. Spam hơn random (15.5 so với 10.0) chỉ nhờ dồn đòn đúng quái và dùng hết viên.
2. **Quái thường là miễn phí cho spam.** Spam mất 1-7% sống sót ở mỗi trận thường, cái chết nằm ở Elite (r5, r9, r15: -23, -26, -19) và boss (r6, r12, r18: -31, -25, -29). Các cơ chế v3 (Giáp, Khiên Hồi, Hồi Ngắt, Phản Đòn, Đòn Nạp) chỉ nằm trên quái có trait, tối đa 2 con mỗi trận (1 trước Elite đầu, `traits.cap_early`). Phần lớn trận không có gì chống spam.
3. **Sức mạnh không cần kỹ năng đến từ build.** Anchor MVP (sửa lỗi đếm node ảo) nâng mọi số lên khoảng 5-10 điểm. Spam bốc Anchor ngẫu nhiên và Lõi theo `mix` (một phần ba run dùng `combo`, `greedy_axis`), nên hưởng cả thức tỉnh Anchor (42-60%) và Volley (hợp với khiên, mà spam vẫn dùng ngẫu nhiên). Volley là Anchor ít cần kỹ năng nhất (ép: 20.8 so với Mana Mine 20.0, Gambler 19.6).
4. **Mana không tạo áp lực.** Spam chơi mặt mana đều đều nhưng không bao giờ tiêu, mà không có gì phạt việc đó. Overcast, Mặt Tạm, Liều An toàn, Mana Mine đều là "tuỳ chọn thêm", không phải thứ buộc phải quản lý.

Knob hiện có và vì sao chưa đủ:

| Knob | Tình trạng |
|---|---|
| `plating`, `ward`, `mend`, `spite`, `charge`, `boss_rhythm` | Chỉ bám quái có trait / Elite / boss, và chủ yếu bắt người ta đổi loại mặt, không bắt quản lý xúc xắc. |
| `run_rules.dmg_use_soft_cap` (2), `dmg_overuse_penalty` (2), `nondmg_mana` (1) | Là luật run R13, chỉ xuất hiện khi rút trúng. Mình grep `dmg_use_soft_cap` trong `godot/**/*.gd` không thấy chỗ nào đọc (`production/depth-v3-contract.md` ghi "chưa cài"); cần lead-programmer xác nhận R13 có chạy thật không trước khi tin số sim. |
| `difficulty.enemy_dmg_mult` 1.55 | Nâng lên làm cả spam lẫn expert chết, khoảng cách không rộng ra. Đúng như Liam nói, không dùng. |
| `bo.*`, `overcast`, `wild`, `reroll` | Thưởng kỹ năng, nhưng spam không mất gì khi bỏ qua nên chúng không kéo spam xuống. |

Kết luận thiết kế: cần cơ chế mà **không quyết định thì mất, có quyết định thì không mất** (hạ sàn, giữ trần), chứ không thêm thưởng (thêm thưởng cũng làm spam mạnh hơn một chút qua BỘ tự nhiên). Cả ba phương án dưới đều theo nguyên tắc đó; mỗi cái dùng một nguồn quyết định khác nhau.

## 2. Ba phương án

### Phương án A: Mana Quá Tải (mana phải tiêu, không tích)

- **Luật một câu:** Cuối lượt người chơi, mỗi điểm mana vượt 3 gây 2 sát thương xuyên khiên lên một Axie ở hàng trước rồi mất điểm đó (tối đa 6 sát thương mỗi lượt).
- **Knob mới** (`combat_tune.json`, khối `mana_heat`):
  - `enabled` 1 (0/1)
  - `keep` 3, dải sim 2 / 3 / 4
  - `dmg` 2, dải 1 / 2 / 3
  - `per_turn_cap` 6, dải 4-8
  - `pierce` 1
  - `target_front` 1 (nhắm Axie đang ở hàng trước, `rows.front_size` 2; hoà thì HP cao nhất)
  - `anchor_mine_keep_add` 2 (Mana Mine thức tỉnh được giữ thêm 2, vì Anchor đó sinh mana làm tính năng chính)
- **Vì sao spam thua, expert không:** spam chơi mặt mana nhưng không bao giờ tiêu, mana chạm trần 3 sau 1-2 lượt rồi mỗi lượt dư vài điểm, tức là tự đấm vào đội hàng trước mỗi lượt, kể cả ở trận thường (khác các cơ chế v3 chỉ ở quái có trait). Expert tiêu mana vào reroll An toàn (2, rồi 3), Mặt Tạm (2), Overcast (3), nên gần như không bao giờ dư; và nó cũng có thể đơn giản không bấm mặt mana khi không cần.
- **Quyết định mới:** "Mặt mana này bấm hay để đó?", "tiêu sớm vào reroll hay giữ 3 cho Overcast?", "ai đứng hàng trước để hứng quá tải?" (vị trí Axie bắt đầu có nghĩa). Với Aqua (Tai nhiều mặt mana) thành đánh đổi thật: sinh mana nhiều thì phải có chỗ tiêu.
- **UI một dòng:** cạnh thanh mana vạch đỏ ở mức 3 và chữ "Mana trên 3 cuối lượt: -2 máu mỗi điểm (hàng trước)", hiện số dự báo ngay khi hover nút Kết thúc lượt.
- **Rủi ro:**
  - Mana Mine (Anchor) và Lõi sinh mana có thể bị phạt oan; đã có `anchor_mine_keep_add`, sim phải kiểm Mana Mine ép không tụt quá 3 điểm so với hai Anchor kia.
  - Có thể trở thành "không bao giờ bấm mặt mana" = mặt mana mất giá trị. Theo dõi tỉ lệ mặt mana bị bỏ không dùng.
  - Bấm tiêu mana vô nghĩa (reroll thừa chỉ để đốt mana) là quyết định giả; reroll An toàn vốn đã tốn 2-3 nên tự giới hạn.
  - Cần xác nhận mana có mang qua các lượt trong một trận (đọc `eng.mana` thì có vẻ có) và có reset giữa trận không.
- **Chi phí làm:** thấp nhất (một hook cuối lượt, một khối knob, một dòng UI).

### Phương án B: Vỏ Cộng Hưởng (BỘ mới phá được vỏ Elite/boss)

- **Luật một câu:** Elite và boss có thêm Vỏ bằng 40% Max HP, đòn phải đi qua Vỏ trước; mặt dmg không thuộc BỘ chỉ tính 50% lên Vỏ, còn mặt thuộc BỘ, poison, pierce và sát thương Lõi tính đủ.
- **Knob mới** (khối `shell`):
  - `enabled` 1
  - `pct` 40, dải 30 / 40 / 50 (phần trăm Max HP làm Vỏ)
  - `off_set_pct` 50, dải 35 / 50 / 65 (hiệu suất mặt dmg ngoài BỘ lên Vỏ)
  - `elite` 1, `boss` 1
  - `boss_open_turn_off` 1 (lượt Hở giáp của boss bỏ Vỏ, khớp `boss_rhythm`)
- **Vì sao spam thua, expert không:** BỘ phải được xây (reroll về cùng part, Mặt Tạm 2 mana, Overcast cho cả BỘ, Liều chấp nhận Nứt 30%); spam chỉ thấy BỘ khi roll tự nhiên ra, mà đội trộn part (mixed_std) hiếm khi tự có BỘ ba. Vỏ làm đúng khúc chết của spam (Elite, boss) kéo dài thêm khoảng 20% số lượt đánh ở Vỏ, trong khi expert (V sau quyết định 30 so với 19) đi qua gần hết ở hiệu suất đủ.
- **Quyết định mới:** dùng reroll để tìm BỘ hay để tìm mặt mạnh; Liều (miễn phí, Nứt 30%) hay An toàn (2 mana) để hoàn thành BỘ trước khi đánh Elite; giữ Mặt Tạm cho Vỏ của boss; Hold viên để dồn BỘ vào lượt Hở giáp. Nối thẳng vào BỘ, Liều, Mặt Tạm, Overcast.
- **UI một dòng:** thanh HP quái có đoạn Vỏ gạch chéo và chữ "Vỏ 16: cần BỘ / độc / xuyên (mặt thường tính nửa)", đòn xem trước hiện "x0.5 Vỏ" hoặc "BỘ".
- **Rủi ro:**
  - Khác Giáp (M1, trừ phẳng) nhưng cùng vùng Elite/boss, có thể chồng thành tường; luật chồng phải thêm vào 6.7b (Giáp Sắt + Vỏ cùng một Elite thì chỉ cho một cái; sim đo độ dài trận, mốc không quá 14 lượt).
  - Đội Aqua/Plant ít BỘ và 0 poison (đã biết từ v3); sàn 50% đảm bảo không kẹt, nhưng đội đó sẽ chịu nhiều nhất. Sim ép từng đội, không chỉ trung bình.
  - Với đội đã có BỘ tự nhiên thì phương án này nhẹ tay; hiệu quả phụ thuộc xác suất BỘ tự nhiên của spam, phải đo trực tiếp (số lượt spam có BỘ).
  - Spam có thể hưởng BỘ tự nhiên với đội 3 Axie cùng loại (beast_bird có 3 beast1): xem tỉ lệ thắng theo đội.
- **Chi phí làm:** trung bình (lớp Vỏ trong damage pipeline, bảng event cho UI, test thông tin `t_shell`).

### Phương án C: Chuỗi Xen (thứ tự mặt trong lượt có giá trị)

- **Luật một câu:** Mặt dùng ngay sau một mặt khác loại trong cùng lượt được +15% mỗi bậc chuỗi (bậc tối đa 3, tính sau BỘ), còn mặt cùng loại với mặt trước bị -10% và chuỗi về 0.
- **Knob mới** (khối `chain`):
  - `enabled` 1
  - `step_pct` 15, dải 10 / 15 / 20
  - `max` 3
  - `repeat_pct` -10, dải 0 / -10 / -20
  - `types` ["dmg", "shield", "heal", "poison", "debuff", "mana"] (mana tính như một loại)
- **Vì sao spam thua, expert không:** spam xếp dmg trước, dồn các mặt cùng loại liên tiếp, nên dính -10% cho mỗi viên dmg thứ hai trở đi và chuỗi luôn 0; các mặt còn lại thì ngẫu nhiên. Expert chọn thứ tự (khiên, rồi dmg, rồi độc, rồi dmg ...) để đạt bậc 3 (+45%) và có thêm quyết định Hold viên nào chờ chen loại nào.
- **Quyết định mới:** thứ tự dùng viên mỗi lượt là một câu đố nhỏ (có undo nên an toàn); chia đội để có đủ loại mặt (Aqua/Plant giờ có lý do vào đội hơn "toàn dmg"). Nối với "Mặt Tạm" (đổi loại mặt) và Overcast chọn viên nào ở bậc cao nhất.
- **UI một dòng:** biểu tượng chuỗi cạnh nút lượt "Chuỗi 2: mặt kế khác loại +30%", mỗi viên hiện "+15%" hoặc "-10% (cùng loại)" khi hover.
- **Rủi ro:**
  - Có thể thành thói quen cơ học ("luôn xen kẽ") và tăng gánh nhận thức, trái pillar đọc được ngay; phải là hai đến ba mức chứ không phải cả bảng.
  - Đội toàn dmg (beast_bird, mixed_dmg) bị phạt nặng; có thể ép chọn đội trộn, tốt hay xấu cần Liam quyết.
  - Đụng `preview_damage`, undo, Echo/multi, Thác Đổ; nhiều chỗ nhất để lệch số xem trước và số thật (`t_replay` phải bắt).
  - Mặt cuối bị tính chuỗi sai nếu viên bị Hold/đóng băng; cần quy tắc rõ.
- **Chi phí làm:** cao nhất (đụng đường tính giá trị mặt và UI preview).

## 3. Kế hoạch sim

Công cụ: `sim_balance.gd` hiện có. Cho mỗi biến thể cùng `--seed` (ghép cặp), Short, `--asc=0`, n = 400 mỗi policy (n=200 cho CI ±4.3; ở 10% chênh 5.5 điểm cần ±3 để kết luận), gắn `--tag=<tên>`.

| Phương án | Giá trị quét (3 ô) |
|---|---|
| A. `mana_heat` | (keep 3, dmg 2) gốc; (keep 2, dmg 2); (keep 3, dmg 3) |
| B. `shell` | (pct 40, off_set 50) gốc; (pct 30, off_set 50); (pct 40, off_set 35) |
| C. `chain` | (step 15, repeat -10) gốc; (step 10, repeat -10); (step 20, repeat -20) |

Mỗi ô chạy:

1. **Cổng chính:** `--policies=attack_spam,random_legal,expert`, `--anchor=auto`. Đạt khi spam <10%, random ≤12%, expert 17-23%.
2. **Expert ép từng Anchor:** `expert --anchor=a_volley`, `a_gambler`, `a_mana_mine`. Đạt khi cả ba nằm trong 17-23 và chênh lệch giữa ba ≤ 3 điểm (hiện chênh 1.2; Mana Mine là cái dễ tụt dưới phương án A).
3. **Phụ để hiểu vì sao:** `attack_only` (dmg thuần, kiểm "chỉ bấm attack" thật), `expert_no_overcast`, `expert_no_wild`, `expert_no_lieu` (mỗi công cụ vẫn phải đáng giá, không bị phương án nuốt).

Chỉ số cần ghi thêm theo phương án (đọc từ metric sẵn có và log mới):

- A: mana dư mỗi lượt và sát thương quá tải mỗi run, số Axie chết do quá tải, tỉ lệ mặt mana bị bỏ không dùng của expert.
- B: tỉ lệ lượt spam có BỘ, độ dài trận Elite/boss (mốc ≤14 lượt, spam 8-11), lượt hạ boss.
- C: bậc chuỗi trung bình mỗi lượt của spam và expert, tỉ lệ thắng theo đội (mixed_dmg, beast_bird so với mixed_std).
- Chung: tỉ lệ thắng theo đội (7 đội trong `TEAMS`), dmg/lượt, HP còn lại sau boss, "phiếu chết theo node" (spam phải chết sớm hơn ở Elite/boss, không chết ngẫu nhiên ở trận thường).

Điều kiện dừng: nếu một phương án làm expert dưới 17% hoặc spam không xuống dưới 10% ở ô mạnh nhất thì loại hoặc ghép với phương án khác. Mọi sửa trong `assets/data/rules/` đều phải bump `RULES_VERSION` và deploy Worker (`godot/CLAUDE.md`, `t_rules_version`).

## 4. Khuyến nghị thứ tự thử

1. **A (Mana Quá Tải) đầu tiên.** Rẻ nhất, tác động mọi trận thường lẫn Elite/boss, nối thẳng vào mana/Overcast/Mặt Tạm/vị trí vốn "vô nghĩa hôm nay" (GDD v4). Rủi ro chính là Mana Mine, đo luôn được trong lượt sim đầu.
2. **B (Vỏ Cộng Hưởng) thứ hai.** Nếu A chưa đủ hoặc muốn nhắm đúng khúc Elite/boss. Cần đọc kỹ tương tác với M1/M6.
3. **C (Chuỗi Xen) cuối.** Chỉ làm nếu A+B vẫn để spam trên 10%, vì đụng nhiều chỗ nhất và dễ thành thói quen cơ học.

Có thể ghép A+B nếu mỗi cái đơn lẻ chỉ kéo spam xuống tới ~12%; ghép thì phải chạy lại ô mạnh nhất của từng cái ở mức nhẹ hơn để expert không rớt quá 17%. Quyết định cuối thuộc về Liam.

## Việc cần xác nhận trước khi sim

- R13 (`dmg_use_soft_cap`) có đang chạy trong engine không (grep không thấy). Nếu chưa thì "R13 có sẵn" không được tính vào baseline.
- Mana có carry qua lượt trong trận và reset giữa trận chưa (cho A).
- Có hành động đổi vị trí Axie trong trận không (mình không thấy `swap`/`move` trong `combat_engine.gd`); nếu không, "hàng trước" ở A chỉ quyết định lúc dựng đội, và câu "quyết định vị trí" nên đổi thành "chọn ai đứng hàng trước khi dựng đội".

## Trả lời kỹ thuật (23/10, nhánh depth/antispam)

1. **`run_rules.dmg_use_soft_cap` (R13): KHÔNG có chỗ nào đọc.** Grep toàn `godot/` chỉ thấy ba khoá `dmg_use_soft_cap`, `dmg_overuse_penalty`, `nondmg_mana` trong `combat_tune.json`, không có dòng GDScript nào đọc chúng. R13 chưa chạy thật, nên không được tính vào baseline sim.
2. **Mana mang qua lượt, reset giữa trận.** `mana` chỉ được đặt về 0 trong `setup_new` (đầu mỗi trận, rồi cộng `start_mana`), không bị xoá ở `finish_end_turn`/`roll_all`, nên dư lượt này sang lượt sau trong cùng một trận. Giữa các trận không mang. Trong trận mana chỉ mất khi tiêu (reroll, Mặt Tạm, Overcast, active) hoặc overflow.
3. **Không có hành động đổi vị trí Axie trong trận.** Hàng trước/sau theo `roster_index` (`row_of`: `rows.front_size` = 2), chỉ đổi được bằng `RunState.reorder_party` ngoài trận (và Core Take The Field kéo một Axie ra trước theo luật Core). Vậy "hàng trước" ở phương án A chỉ là lựa chọn lúc dựng đội, đúng như đề xuất nói.

### Cài đặt (đã có, mặc định tắt)
- A `mana_heat`: cuối lượt người chơi, mana vượt `keep` (3, +2 nếu Mana Mine thức tỉnh) gây `dmg` 2 mỗi điểm, tối đa `per_turn_cap` 6, xuyên khiên, vào Axie hàng trước có HP cao nhất; MỌI điểm vượt đều mất (cap chỉ giới hạn sát thương). Còn đi qua giảm sát thương `dr` của pipeline.
- B `shell`: Vỏ = 40% Max HP trên con Elite (enemies[0]) và boss, hấp thụ trước Khiên. Mặt dmg thường từ xúc xắc ngoài BỘ chỉ tính 50% lên Vỏ; mặt trong BỘ, pierce, poison, sát thương không nguồn (Lõi/Anchor) tính đủ; phần Vỏ không đỡ hết đổi ngược về sát thương. Lượt Hở giáp của boss bỏ Vỏ. `preview_damage` chưa tính Vỏ (việc UI sau).
- C `chain`: cộng +15% x bậc (tối đa 3) cho mặt khác loại với mặt trước, đi qua `m100_for` nên nằm dưới `bo.m_cap`; mặt cùng loại -10% (sau M, không dưới 1) và bậc về 0. Mặt đầu lượt không thưởng. Cantrip tự giải lúc tung không tính vào chuỗi. Chỉ dmg/shield/heal/poison nhận số, mana/debuff chỉ tính loại.
- Sự kiện: `EventBus.mana_heat`, `shell_changed`, `chain_changed`.

## Quyết định (23/10, theo sim trên int/v5 — Liam giao "tự quyết theo sim")
Đo trên bản gộp (6 Anchor, Lõi/Luật v5, Lõi ít kích hoạt đã sửa), Short A0 stage 3, n spam 400 / random 200 / expert tự chọn 320:
| cấu hình | expert | random | spam |
|---|---|---|---|
| tắt cả 3 | 25.0 | 14.0 | 13.8 |
| A Mana Quá Tải (mặc định) | (đo trên godot-port cũ, n nhỏ) 19.4 | 9.2 | 12.5 |
| C Chuỗi Xen (mặc định) | (godot-port cũ) 21.9 | 19.2 | 15.5 |
| B Vỏ 40% / lẻ 50% | 13.1 | 7.5 | 6.0 |
| **B Vỏ 25% / lẻ 50% (CHỌN)** | **16.2** | **11.5** | **7.2** |
| B Vỏ 40% / lẻ 70% | 12.5 | 6.5 | 8.2 |
Lý do: chỉ B hạ spam dưới 10% mà random vẫn ≤12; A không hạ spam, C làm random và spam mạnh lên (thưởng thứ tự ngẫu nhiên). B 25% giữ expert sát 17 (trong CI); bot expert chưa chủ động xây BỘ để phá Vỏ nên người chơi giỏi sẽ cao hơn. A và C để `enabled:false` (code giữ lại).
