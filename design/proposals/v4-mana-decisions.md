# V4: làm cho mana có nghĩa (đề xuất, chờ Liam duyệt)

Ngày 21/10/2026. Chưa đổi code, chưa đổi knob. Số "VTĐ" dùng đúng đơn vị của `v4-decisions-pay.md` (1 VTĐ ~ giá trị một viên dmg trung bình).
Mọi số EV dưới đây là ước lượng tay từ knob A+, chỉ để chọn hướng. Sim quyết, không dùng số tay làm bằng chứng.

Nguồn số đo: `sim-v4-metric-aplus.md` (8 bot x 200 run, cặp seed 1000-1199). Knob: `combat_tune.json` (V4).

## 1. Vì sao ba cơ chế đóng góp ~0

Đóng góp đo được (expert - bản tắt, dmg/lượt): Liều +1.4 ±1.5, Mặt Tạm -0.6 ±1.6, Overcast 0.0 ±1.4. Cả ba nằm trong sai số.
Khoảng cách tay nghề (expert - legacy +5.05, expert - free_hold +5.5) chủ yếu đến từ việc chọn viên để reroll và săn Bộ bằng reroll An toàn,
tức hành động rẻ (An toàn lần đầu 1 mana) đã ăn gần hết giá trị. Ba thứ còn lại chỉ nhặt phần thừa.

Giá trị mỗi mana (knob A+: Bộ ba +0.3, bốn +1.2, năm +1.6; mỗi viên trong nhóm được cộng):

| Cách tiêu | Mana | Lãi gộp (VTĐ) | VTĐ / mana | Ghi chú |
|---|---|---|---|---|
| An toàn lần 1, săn ba -> bốn | 1 | ~1.7 (từ v4-decisions-pay) | ~1.7 | rẻ nhất, ai cũng mua |
| An toàn lần 2 | 3 | thấp hơn lần 1 (bàn đã chốt bớt) | <= 0.6 | chỉ đáng khi chưa có ba |
| Mặt Tạm đôi -> ba | 3 | 3 x 0.3 = 0.9 | 0.3 | lỗ so với An toàn |
| Mặt Tạm ba -> bốn | 3 | 4 x 1.2 - 3 x 0.3 = 3.9 | 1.3 | rất lời, nhưng cần đúng ba viên cùng part + một viên rảnh chưa dùng + còn 3 mana |
| Overcast 1 viên | 3 | 0.5 x 1 viên = 0.5 | 0.17 | tệ nhất |
| Liều (miễn mana) | 0 | ~0.9 ròng (trừ Nứt 30%) | vô hạn | gần hoà với An toàn lần 2 |

Đọc bảng:
- **Overcast**: 0.17 VTĐ/mana, thua mọi lựa chọn khác. Expert (và bot nào tính đúng) gần như không mua. Bản tắt và bản bật chơi y hệt, nên chênh = 0. Đây là lỗi giá trị, không phải lỗi bot.
- **Mặt Tạm**: lưỡng cực. Đôi -> ba chỉ 0.3/mana nên bỏ; ba -> bốn 1.3/mana nên mua. Nhưng điều kiện (ba chuẩn + viên rảnh + 3 mana sau khi đã trả An toàn) hiếm, và bị cấm làm bốn -> năm. Tần suất mua nhân lãi ra gần 0, hoặc âm nếu bot mua sai lúc (-0.6 ±1.6). Cần kiểm chính sách bot (câu hỏi 3 ở mục 5).
- **Liều**: có tác dụng nhẹ (+1.4) vì nó miễn mana, và gần hoà với An toàn lần 2 nên là chỗ duy nhất có chút lựa chọn thật. Giữ nguyên.
- **Mana dùng vào đâu khác**: relic active (`used_actives`), Conduit (`mana_spent / conduit_step`). Chưa có số đo tỉ lệ.
- **Mana nhận mỗi lượt thừa hay thiếu**: CHƯA ĐO. Sim hiện chỉ ghi dmg/V/win, không ghi mana nhận và mana tiêu (GDD 4.4 đặt mục tiêu "expert tiêu >= 70%, dư cuối trận < 40%" nhưng chưa ai đo). Nguồn gồm mặt Tai (cantrip), Conduit +1, Lõi mana. Giả thuyết: đủ cho 1 An toàn rẻ + 1 khoản 3 mana mỗi lượt, tức mana thiếu để mua cả Mặt Tạm lẫn Overcast, càng khiến Overcast (tệ nhất) bị bỏ. Bước 0 của kế hoạch sim là đo chỗ này.

Kết luận: ba cơ chế không "hỏng", chỉ là ba cách tiêu 3 mana mà hai cái (Overcast, Mặt Tạm đôi) lời ít hơn hẳn cái còn lại, và An toàn lần 1 ngốn trước. Không có chỗ nào người chơi phải cân nhắc.

## 2. Phương án (đơn giản)

Mục tiêu chung: ba cách tiêu mana có VTĐ/mana cùng cỡ 0.5-1.3 trong cùng một tình huống (đã có ba), để chọn cái nào thì tuỳ bàn.

### P1. Overcast áp lên CẢ BỘ

Luật đổi: Overcast (3 mana, 1 lần/lượt) cộng `oc_add` vào mọi viên đang trong Bộ chốt, không còn nhắm 1 viên. Không có Bộ thì không bấm được (nút xám, lý do "cần Bộ"). `oc_add` hạ từ 0.5 xuống 0.4. Một câu cho người chơi: "3 mana: cả Bộ mạnh thêm +0.4."

Công thức: `bonus_OC = oc_add x n_bo` (n_bo = số viên trong Bộ chốt), `M_i = min(1 + bo_add + oc_add, m_cap)` cho mỗi viên trong Bộ.

| Symbol | Type | Range | Mô tả |
|---|---|---|---|
| oc_add | float | 0.3-0.5 | cộng vào hệ số M mỗi viên trong Bộ |
| n_bo | int | 3-5 | số viên trong Bộ chốt |
| bo_add | float | 0.3 / 1.2 / 1.6 | thưởng Bộ ba / bốn / năm |
| m_cap | float | 3.0 | trần M (knob có sẵn) |
| bonus_OC | float | 1.2-2.0 | lãi gộp VTĐ (với v ~ 1 mỗi viên) |

Giới hạn: bộ năm 1 + 1.6 + 0.4 = 3.0 vừa chạm `m_cap`, không bị cắt. Ví dụ (oc_add 0.4): Bộ ba +1.2, bốn +1.6, năm +2.0 VTĐ cho 3 mana, tức 0.4-0.67 VTĐ/mana (cũ 0.17).

Tạo lựa chọn thật: khi đã có ba và còn 3 mana, người chơi chọn giữa Mặt Tạm ba -> bốn (3.9, nhưng cần viên rảnh), Overcast Bộ (1.2-1.6, chắc, không cần viên rảnh), và An toàn lần 2 (săn thêm, có rủi ro không ra). Mỗi cái thắng ở một tình huống. Overcast cũng tự nối với việc săn Bộ: Bộ càng lớn Overcast càng lời, nên người săn tốt được thưởng kép.
Rủi ro làm dễ đi: vừa-cao (xem Ghi chú reviewer: +1.2-2.0 VTĐ mỗi lượt có Bộ, tương đương +24-40% sức mạnh đội 5 viên, chỉ bị mana chặn). Chỉ người nào mua mới mạnh lên; spam/free_hold không mua mana nên gần như không đổi, nhưng random tiêu mana bừa (GDD 4.4) nên có thể ăn lây, cần đo. Kéo độ khó bằng `enemy_dmg_mult` (1.5 -> khoảng 1.55-1.65, sim quyết) hoặc hạ `oc_add` 0.3.
Code: S. Làn OC đã đổi sang "cộng vào túi M"; chỉ đổi nhắm một viên thành nhắm Bộ, bỏ cờ `overcast` trên viên, thay bằng cờ `bo_overcast` cả lượt. Undo hoàn mana + cờ như cũ. Replay có đổi (action `overcast` bỏ `uid`), tăng `RULES_VERSION`.
Đo: expert - expert_no_overcast >= +2 dmg/lượt (CI ±1.4 với 200 run, cần ~+2.8 trung bình để chắc; xem mục 4 về cỡ mẫu).

### P2. Mặt Tạm 2 mana nhưng 1 LẦN MỖI TRẬN

Luật đổi: `wild.cost` 3 -> 2, `wild.per_turn` 1 -> 1 nhưng thêm `wild.per_battle` = 1. Vẫn cấm bốn -> năm. Một câu: "Mặt Tạm: 2 mana, 1 lần mỗi trận."

Công thức: `V_wild = max(0, (n+1) x bo_add(n+1) - n x bo_add(n))` với n = size nhóm hiện tại (3 hoặc 2 coi bo_add(2) = 0).

| Symbol | Type | Range | Mô tả |
|---|---|---|---|
| n | int | 2-3 | size nhóm trước Mặt Tạm (n = 4 bị cấm) |
| bo_add(k) | float | 0 / 0.3 / 1.2 | thưởng Bộ size k (k = 2: 0) |
| V_wild | float | 0.9-3.9 | lãi gộp VTĐ |

Ví dụ: n = 3 cho 3.9, n = 2 cho 0.9. Giá 2 mana => 1.95 hoặc 0.45 VTĐ/mana.

Tạo lựa chọn thật: quyết định chuyển từ "có bấm được không" sang "dùng ở lượt nào của trận này", vì chỉ có một viên đạn mỗi trận. (Reviewer sửa: bản gốc viết "giữ cho boss", nhưng `per_battle` reset đầu MỖI trận nên không để dành tới boss được; muốn để dành thật phải là per_run hoặc per_tầng, xem Ghi chú reviewer.) Người mới hiểu được ("còn 1 Mặt Tạm"). Cũng tách Mặt Tạm khỏi cạnh tranh mỗi lượt với Overcast: Overcast mỗi lượt, Mặt Tạm 1 lần.
Rủi ro làm dễ đi: thấp-vừa (tối đa 1 lần mỗi trận, lãi tối đa 3.9 VTĐ ~ +0.4-0.8 VTĐ/lượt trung bình trên trận 5-7 lượt). Rủi ro tạo cảm giác "mất": người chơi quên dùng. Giảm bằng UI hiện "Mặt Tạm: còn 1".
Code: S-M. Thêm biến `wild_used_battle` vào `_state_dict` + save + undo, reset đầu trận (không phải đầu lượt). Bot expert phải biết "giữ" (hiện bot tính theo từng lượt, cần sửa policy). Replay có đổi? Không đổi action, chỉ đổi luật chấp nhận, nhưng vẫn tăng `RULES_VERSION` vì fingerprint rule file.
Đo: expert - expert_no_wild >= +1.0 dmg/lượt (reviewer hạ từ +2: trần lý thuyết 3.9 VTĐ chia 5-7 lượt chỉ 0.56-0.78 VTĐ/lượt, nhân tần suất đủ điều kiện thì không tới +2 dmg). Lưu ý: 1 lần mỗi trận trần lãi thấp; nếu sim vẫn ~0 thì nghi bot dùng sai lúc (xem mục 4).

### P3. Liều đổi dốc: Nứt 15% lần đầu, 40% lần sau

Luật đổi: `crack.pct` thành hai bậc: lần Liều thứ nhất mỗi lượt 15%, lần thứ hai 40% (`crack.pct_1`, `crack.pct_2`). Giữ An toàn lần 1 = 1 mana, lần 2 = 3 mana. Một câu: "Liều: miễn phí, 15% mỗi viên Nứt, lần hai 40%."

Công thức: `net_lieu(j) = gain_hunt - p_j x n_reroll x 0.5 x v` (p_1 = 0.15, p_2 = 0.40; n_reroll = số viên tung lại).

| Symbol | Type | Range | Mô tả |
|---|---|---|---|
| p_j | float | 0.15 / 0.40 | tỉ lệ Nứt ở lần Liều j |
| n_reroll | int | 1-4 | số viên tung lại |
| v | float | ~1 | giá trị viên (VTĐ) |
| gain_hunt | float | 0.5-1.7 | lãi săn Bộ của lần đó (như mục 1) |

Ví dụ: lần 1 với 2 viên: Nứt kỳ vọng 0.15 x 2 x 0.5 = 0.15 VTĐ, ròng ~0.6-0.75 (cũ ~0.3-0.9 với 30%). Lần 2 với 2 viên: 0.40 x 2 x 0.5 = 0.4, ròng gần 0.2-0.5, tức đáng trả 3 mana An toàn thay.

Tạo lựa chọn thật: Liều lần đầu gần như luôn đáng (rẻ), Liều lần hai buộc cân: trả 3 mana để chắc, hay chịu 40% Nứt, hay dừng. Đây là chỗ mana "bảo hiểm". Nó tạo cạnh tranh trực tiếp giữa An toàn lần 2 (3 mana) với Overcast/Mặt Tạm (cũng 2-3 mana), đúng ý "ba cách tiêu".
Rủi ro làm dễ đi: vừa (Liều lần đầu rẻ hơn nên mạnh lên cho mọi bot kể cả random). Ảnh hưởng độ khó cả người giỏi lẫn người dở, khác P1/P2. Code: S (hai knob + chỉ số Liều thứ mấy trong lượt, đã có `reroll_paid_k`). Replay đổi (Nứt rút theo ngưỡng mới): tăng `RULES_VERSION`.
Đo: expert - expert_no_lieu >= +2 dmg/lượt (hiện +1.4 ±1.5). Chỉ là bổ trợ, không đủ làm cơ chế chính.

## 3. Khuyến nghị

**P1 + P2 cùng lúc** (hai thay đổi, hai knob chính, độc lập về luật), giữ Liều như hiện tại (P3 không làm, vì Liều đã chạy được và dễ đẩy độ khó lệch). Bộ số khởi điểm:

```
overcast.mana_cost   3        (giữ)
overcast.add         0.4      (từ 0.5; nhắm cả Bộ, cần Bộ chốt)
overcast.target      "bo"     (mới: thay vì 1 viên)
wild.cost            2        (từ 3)
wild.per_battle      1        (mới)
wild.per_turn        1        (giữ)
bo.add_3/4/5         0.3 / 1.2 / 1.6   (giữ)
bo.m_cap             3.0      (giữ)
crack.pct            30       (giữ)
reroll.mana_cost_2/_3 1 / 3   (giữ)
difficulty.enemy_dmg_mult  1.5 -> thử 1.60 nếu expert vọt trên 27%
```

Lý do chọn hai cái: cả hai chạm vào hai thứ đang ~0, đúng chỗ Liam hỏi, và mỗi cái giải thích được trong một câu. Mana có nghĩa vì có ba cách tiêu 2-3 mana với giá trị cùng cỡ khi đã có ba. Dễ hiểu vì Overcast chỉ còn một câu mới ("cả Bộ") và Mặt Tạm chỉ thêm "1 lần mỗi trận". Gacha vui vì "3 mana: cả Bộ sáng lên" là khoảnh khắc ăn mừng đẹp hơn "một viên +0.5".
Không chọn P3 làm chính vì nó mở rộng sức mạnh của cả bot dở, không tạo khoảng cách tay nghề.
Giữ độ khó: chỉ expert mua mana nên tăng mạnh nhất; random/spam/free_hold gần như đứng yên. Nếu expert vọt, nâng `enemy_dmg_mult` (làm random/spam xuống thêm, vốn đang sát ngưỡng ≤ 12 nên có lợi), không hạ `bo.add`, vì hạ `bo.add` làm lại mất lãi săn Bộ vừa nâng ở A+.

## 4. Kế hoạch sim

Cùng bộ đo: 8 bot x 200 run, seed 1000-1199, lô 40, Short A0 offline. Cùng CSV schema của `sim-v4-metric-aplus.md`.

Bước 0 (trước khi đổi knob, 1 lần chạy): thêm vào sim các cột
- `mana_in` (mana nhận mỗi trận), `mana_spent` (tiêu), `mana_end` (dư cuối trận), theo bot;
- số lần mua mỗi loại mỗi lượt: An toàn lần 1, An toàn lần 2, Mặt Tạm (kèm size nhóm trước/sau), Overcast, Liều;
- với Mặt Tạm: tỉ lệ bấm lúc n = 2 (lỗ) so với n = 3 (lời).
Mục đích: biết mana thừa hay thiếu và bot có mua đúng chỗ không. Nếu expert mua Mặt Tạm lúc n = 2 thì -0.6 là lỗi bot, sửa policy trước khi đổi luật.

Vòng 1: bật P1 + P2 trên nhánh sim; bản tắt cho `expert_no_overcast`, `expert_no_wild` giữ như cũ (so cùng cặp seed). Đọc:
- (a) expert - expert_no_overcast >= +2.0 dmg/lượt, expert - expert_no_wild >= +1.0 (mục tiêu mỗi cơ chế; Overcast +2.0, Mặt Tạm +1.0);
- (b) expert - legacy >= +8 và expert - free_hold >= +9 dmg/lượt (đường tới 12-15 điểm win-rate);
- (c) expert win 20 ±3, spam <= 12, random <= 10-12 (đo win ở vòng 2 với 600 run, giống đã làm ở A+);
- (d) `mana_end` expert < 40% mana nhận, tiêu >= 70% (mục tiêu GDD 4.4).
Chú ý cỡ mẫu: CI ±1.4 ở 200 run nghĩa là chênh +2 chỉ nhỉnh hơn 1 CI. Đo cơ chế bằng cặp seed (đã dùng) và nếu cần tăng lên 400 run cho hai bản tắt để CI còn ±1.0.
Vòng 2: chỉnh `enemy_dmg_mult` cho expert về 20 ±3, rồi đo lại cả (a) và (c). Mỗi vòng chỉ đổi một knob chính (oc.add hoặc wild.cost hoặc dmg_mult), ghi vào bảng.
Cắt lỗ: nếu sau 2 vòng một cơ chế vẫn dưới +1.0, đề xuất bỏ hẳn cơ chế đó khỏi stage 2-3 thay vì tiếp tục chỉnh, vì mỗi cơ chế vô nghĩa là thêm một khái niệm cho người mới mà không đáng.

## 5. Câu hỏi cho Liam

1. Mặt Tạm giới hạn 1 lần mỗi trận (P2) được không? Mất chút tự do so với "1 lần mỗi lượt", đổi lại thành quyết định "dùng lúc nào". Khuyến nghị: được.
2. Overcast chỉ bấm được khi đã có Bộ, và nhắm cả Bộ (P1)? Hệ quả: viên lẻ không còn được Overcast. Khuyến nghị: được, vì viên lẻ +0.5 là thứ khiến nó vô nghĩa.
3. (Reviewer thay câu cũ. Câu cũ hỏi về policy bot, đó là việc kỹ thuật của làn sim, không cần Liam quyết; cứ sửa bot và làm bước 0 trước.) Nếu sau 2 vòng sim một cơ chế vẫn dưới +1.0 dmg/lượt thì bỏ hẳn khỏi stage 2-3 (quy tắc cắt lỗ ở mục 4), Liam đồng ý không? Và nếu bước 0 cho thấy mana thiếu (expert hết mana ở lượt 1-2), Liam muốn tăng nguồn mana hay chấp nhận Overcast/Mặt Tạm là món "chọn một" mỗi lượt?

## Ghi chú reviewer (game-designer, 21/10/2026)

Verdict: HƯỚNG ĐÚNG, SỬA NHẸ. Đã sửa thẳng 4 chỗ ở trên; còn 2 bất đồng để Liam/lead xem.

1. EV tay: đúng số học (Mặt Tạm 0.9 / 3.9; Overcast 0.5 -> 0.17/mana; P1 1.2/1.6/2.0, bộ năm chạm đúng m_cap 3.0). Lệch cần biết: (a) bảng dùng VTĐ (1 VTĐ ~ một viên dmg), còn tiêu chí sim đo dmg/lượt; một viên dmg không bằng 1 dmg nên "+2 dmg/lượt" cho Mặt Tạm 1 lần/trận không với tới được, đã hạ còn +1.0. (b) GDD 3.6 và 4.4 đã ghi `wild.cost = 2`, còn `combat_tune.json` V4 vẫn là 3; đề xuất gọi là "3 -> 2" mà GDD đã nói 2, cần xác nhận A+ chạy ở giá nào, tránh sim đo trên giá lệch GDD. (c) Mặt Tạm 3->4 ở 2 mana là 1.95 VTĐ/mana, hơn Overcast P1 (0.4-0.67/mana) mọi lúc nó dùng được.
2. P1 chưa hẳn "luôn bấm": nó thành "có Bộ + dư 3 mana thì bấm" vì chỉ cạnh tranh mana với An toàn lần 1 (1 mana, rẻ nhất) và Mặt Tạm (lời hơn nhưng 1 lần/trận). Nếu mana vừa đủ 1 khoản 3 mỗi lượt thì có chọn thật; nếu dư thì chỉ là nút xả mana. Quyết định thật nằm ở thứ tự trong lượt: bấm trước hay sau khi săn/Mặt Tạm làm Bộ lớn lên (bộ ba 1.2 -> bốn 1.6). Doc phải chốt: Overcast tính theo Bộ chốt lúc dùng viên (nên bấm lúc nào cũng được, không bị lock), hay lock theo n_bo lúc bấm. Khuyến nghị: tính lúc dùng viên, UI hiện số Bộ. Phụ thuộc hoàn toàn vào bước 0 (mana nhận/tiêu); chưa đo thì chưa kết luận được.
3. P2 "1 lần/trận": không thành "để dành tới boss" như bản gốc viết, vì reset mỗi trận. Thực chất nó thành "bấm ở lần đầu có ba + viên rảnh", gần như không có lý do chờ (3.9 là 3.9 ở lượt nào cũng như nhau), nên chỉ còn chọn 2 mana này với An toàn/Overcast cùng lượt. Không bị quên mà hay bị phí ở n = 2 (0.9) của người mới; nên UI chỉ sáng nút khi n = 3, hoặc chặn n = 2. Bất đồng: nếu Liam muốn quyết định để dành thật, đổi sang 1 lần mỗi run hoặc mỗi 3 trận (khớp `boss_rhythm.period` 3); đổi lại mất cảm giác "mỗi trận đều có".
4. UI/luật: P1 + P2 cộng thêm ~2 câu luật, đều ngắn. Cần: nút Overcast xám có lý do "cần Bộ", bộ đếm "Mặt Tạm: còn 1", preview "->" đã có (GDD 9.3) dùng lại được. Ổn cho stage 2-3.
5. Độ khó: Overcast lên tới +40% sức mạnh ở lượt dùng được, chồng lên +50-60% của Bộ (GDD 4.3). Kéo bằng enemy_dmg_mult 1.5 -> 1.6 có thể không đủ; chuẩn bị hạ oc_add 0.3 trước (đã nằm trong đề xuất).
6. 3 câu hỏi: Q1 chứa tiền đề sai (boss), đã viết lại ở mục 2; Q2 đúng; Q3 cũ không phải việc của Liam, đã thay.

Khuyến nghị cuối: làm bước 0 (đo mana) trước khi đổi bất cứ knob nào, rồi chạy P1 + P2 trên nhánh sim. Chưa cần Liam chốt per_battle hay per_run ngay; để sim vòng 1 chạy với per_battle, nếu Mặt Tạm vẫn < +1.0 thì thử per_run.

## Quyết định (22/10) — Liam giao quyết câu 1-2 "dựa trên cơ sở, logic rõ ràng", câu 3 Liam đồng ý
Số liệu bước 0 (sim A+, expert 200 run, `../my-game-wt/SV4/production/qa/sim/sim-2026-10-21-mx0_expert_*.md`): mana nhận ~1.35/lượt (mặt mana
~0.00-0.02, đầu lượt ~0.6, khác ~0.5, Lõi ~0.2); expert tiêu 46% mana vào Overcast, 42% Mặt Tạm, 11% An toàn; Overcast/Mặt Tạm đóng góp ~0 dmg/lượt;
Mặt Tạm bấm ở n=2→3 63% (lỗ), n=3→4 37% (lời); lượt có BỘ 43.6%, có BỘ + ≥3 mana đầu lượt 21.3%.
1. **Overcast**: chỉ dùng khi có BỘ; +0.4 cho MỌI viên trong BỘ (tính theo BỘ lúc dùng viên); 3 mana; 1 lần/lượt. Lý do: Overcast 1 viên là cách tiêu
   mana tệ nhất (~0.17 VTĐ/mana) mà hút 46% mana → bẫy; cả BỘ 0.4-0.67 VTĐ/mana, cạnh tranh thật với An toàn/Mặt Tạm; chỉ 21% lượt đủ điều kiện →
   quyết định để dành mana. Luật một câu: "Overcast làm cả BỘ mạnh hơn."
2. **Mặt Tạm**: chỉ biến bộ ba thành bộ bốn (n=3→4); 2 mana; 1 lần/trận (`per_battle`); vẫn cấm tạo Bộ năm. Lý do: 63% lần dùng là n=2→3 lỗ → bỏ bẫy;
   n=3→4 là nhảy ×1.3→×2.2, gắn khoảnh khắc ăn mừng bộ bốn; 1 lần/run quá hiếm, không được thấy (bài học relic "vô hình"); 1 lần/trận = mỗi trận một
   quyết định (dùng ngay hay chờ lượt Hở boss). Luật một câu: "Có bộ ba thì trả 2 mana để thành bộ bốn (1 lần mỗi trận)."
3. Cắt lỗ: cơ chế nào sau 2 vòng chỉnh vẫn đóng góp < +1.0 dmg/lượt (expert − bản tắt, 200 run cặp seed) thì bỏ hẳn.
Theo dõi: mặt mana gần như không sinh mana (0.00-0.02/lượt) — tra nguyên nhân (bot không dùng hay mặt hiếm) ở vòng sau.
Đo: cùng bộ 8 bot × 200 run cặp seed; mục tiêu Overcast ≥ +1.5, Mặt Tạm ≥ +1.0 dmg/lượt, expert − free_hold rộng ra, expert vẫn 20±3.

## Vòng 2 (23/10) — kết quả và quyết định theo quy tắc cắt lỗ
Knob: Overcast 2 mana, +0.5 cả BỘ; enemy_dmg_mult 1.55. Sim (`../my-game-wt/OC2/production/qa/sim/sim-v4-metric-oc2.md`): Overcast +1.19 ±1.05 dmg/lượt
(400 run cặp seed) → GIỮ (≥ +1.0), sát nút, theo dõi qua playtest; Mặt Tạm +2.84 → giữ; Liều +1.49. Win: random 11.0, spam 10.5, free_hold 10.5,
expert 18.8 (400 run) — đạt cả 3 mục tiêu. expert − free_hold +7.7 dmg/lượt (vòng 1 +6.3).
