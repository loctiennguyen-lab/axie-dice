# RELIC REBALANCE — Round 2 (2026-09-07): định giá lại drawback của relic "pact"

> **Status**: Draft for review — chờ product owner chốt trước khi lead-programmer implement
> **Author**: game-designer, 2026-09-07
> **Quan hệ với `relic-system.md`**: đây là **bản vá bổ sung**, không thay thế. `relic-system.md`
> (2026-09-03, đã implement, `t_relic.mjs` 94/94 INV-1) vẫn là nguồn sự thật cho taxonomy, mload,
> ex/exSub, tier monotonicity (§3.12). File này chỉ sửa **một khoảng trống trong công thức §4**:
> cách định giá drawback của loại relic `pact` (đánh đổi HP lấy buff).
> **Nguồn**: `src/data.js` (`RELICS`, dòng 423-730), `src/engine.js` (`buildUnit` :60, `startCombat`
> :383-398, `checkEnd` :943-946), `design/gdd/relic-system.md` (toàn bộ, đặc biệt §3.1/§3.2/§3.6/§4/§4.7/§14),
> `design/gdd/relic-roster-expansion.md`.

## 0. Vì sao file này tồn tại — trả lời thẳng câu hỏi của product owner

Product owner xác nhận đã biết `relic-system.md` (2026-09-03) nhưng **vẫn thấy relic linh tinh
sau bản đó**, với ví dụ cụ thể: *"các buff như mất 20% máu nhận lại một chút bonus dame thật sự
không đáng."*

Rà soát toàn bộ 94 relic trong `RELICS` (78 passive + 16 active) để tìm **mọi** relic có cơ chế
đánh đổi (mất HP/Shield/tài nguyên đổi lấy buff) cho kết quả: **chỉ đúng một relic khớp mẫu này** —
`r_bloodpact` (Blood Pact, LEGENDARY). Đây không phải giới hạn của việc rà soát — đây là sự thật
cấu trúc: taxonomy của `relic-system.md` §3.1 định nghĩa loại `pact` là **"chỉ có ở LEGENDARY"**,
và roster hiện tại chỉ ship đúng 1 relic loại đó. Không có relic COMMON/RARE/EPIC nào mất HP/Shield
để đổi buff — đã kiểm tra toàn bộ 94 entry, không sót.

Relic gần nhất về *cảm giác* với ví dụ product owner đưa ("mất 20% máu") là lựa chọn "Make the
wager" ở event **LUNACIA SHRINE** (`EVENTS`, không phải `RELICS`) — mất 20% Max HP đổi một Legendary
relic ngẫu nhiên. Đây **không thuộc biến `RELICS`** nên ngoài phạm vi việc được giao (biến `RELICS`
trong `src/data.js`); được ghi lại ở §6 làm follow-up, không sửa trong bản vá này.

**Phát hiện chính**: `r_bloodpact` **đã được `relic-system.md` §4.5 ví dụ 6 tính toán và chấm "="
(không đổi)** — mô hình RP hiện tại cho nó 35.60, nằm trong dải LEGENDARY [31.77, 42.97]. Về mặt
số học đội hình cũ, relic này **đã "đúng."** Nhưng mô hình đó định giá drawback bằng **kỳ vọng
tuyến tính (EV)** — nó không tính đến việc mất Max HP là một khoản lỗ **vĩnh viễn xuyên suốt mọi
trận còn lại của run**, làm tăng **rủi ro toàn diệt** (không chỉ kỳ vọng damage bị hụt) ở mọi trận
tương lai. Đây chính là khoảng trống công thức mà bản vá này lấp — không phải một relic "bị bỏ sót",
mà là **một lỗi trong chính công thức đã dùng để duyệt nó.**

Rà soát thêm các loại "linh tinh" khác (mơ hồ, quá yếu, quá mạnh, trùng ý tưởng) theo yêu cầu (3):
đối chiếu với bảng chẩn đoán sẵn có trong `relic-system.md` (§4.7 ba mispricing đã sửa: APEX,
INFERNO, PLAGUE) và `relic-roster-expansion.md` (§6.7.x: `r_hivequeen`, `r_dawnlance`, `r_ironmaiden`
từng bị chấm "quá yếu"/"vi phạm nặng" — cả ba đã được retune và **xác nhận khớp bản ship hiện tại
trong `data.js`**, không cần sửa thêm). Không tìm thấy relic nào khác bị bỏ sót ngoài lỗi công thức
drawback nói trên.

## 1. Overview

Bản vá này sửa cách hệ RP-budget (`relic-system.md` §4) định giá **drawback vĩnh viễn** của relic
loại `pact` (hiện có đúng 1: `r_bloodpact`). Mô hình cũ dùng kỳ vọng tuyến tính (bao nhiêu damage
mà lượng HP mất đi có thể đã chặn ở MỘT trận); mô hình mới nhân thêm hệ số rủi ro `κ_risk` phản
ánh việc mất Max HP là **vĩnh viễn xuyên suốt run** và làm tăng **xác suất toàn diệt** ở mọi trận
tương lai — một chi phí mà kỳ vọng tuyến tính không đo được. Áp dụng công thức mới cho
`r_bloodpact` cho thấy relic hiện tại (mất 25% Max HP, damage ×1.6) đang được định giá **cao hơn
giá trị thật của nó** theo góc nhìn rủi ro — khớp với cảm nhận "không đáng" của product owner.
Đề xuất cụ thể: giảm mức Max HP mất từ 25% xuống 15%, giữ nguyên damage ×1.6, đưa RP thực (theo
mô hình rủi ro mới) về giữa dải LEGENDARY.

## 2. Player Fantasy

*"Tôi dám đánh cược, và tôi biết chính xác cái giá — không phải một cái giá bị đo sai."*

`pact` là relic duy nhất trong game cho phép người chơi **chủ động chọn rủi ro thật** để đổi lấy
sức mạnh vượt trần — đây là aesthetics **Challenge** và **Expression** (MDA): một quyết định định
danh phong cách chơi ("tôi là kiểu người chơi liều"), không phải một stat tốt hơn. Cảm giác này
chỉ đúng khi:

1. **Cái giá phải cảm nhận được là thật** — nếu drawback quá nhỏ so với reward, `pact` không còn
   là quyết định, nó là "buff miễn phí có tên hoa mỹ." Vi phạm Autonomy (SDT): không còn là lựa
   chọn có ý nghĩa vì không có gì để cân nhắc.
2. **Cái giá không được định giá SAI đến mức người chơi cảm thấy bị lừa** — đây là lỗi ngược:
   nếu công thức duyệt một relic là "cân bằng" nhưng mọi người chơi thực tế đều thấy nó "không
   đáng," thì bản thân công thức đang đo sai một chi phí thật (rủi ro toàn diệt tăng ở MỌI trận
   sau, không chỉ một trận), và điều đó phá vỡ Competence (SDT): người chơi không thể học "khi
   nào nên đánh đổi" nếu tín hiệu số bị lệch khỏi tín hiệu cảm nhận.

Mục tiêu của bản vá: đưa công thức về đúng với cảm nhận, để `pact` tiếp tục là quyết định thật, có
giá thật, không phải bẫy toán học.

## 3. Detailed Rules

### 3.1 Phạm vi rà soát và kết quả

Quét toàn bộ 94 entry `RELICS` (`src/data.js:423-730`) tìm mọi relic có field làm giảm một tài
nguyên (`u.maxHp`, `u.shield`, `s.mana`, v.v.) như một phần cơ chế bắt buộc (không điều kiện) để
đổi lấy buff khác. Kết quả: **duy nhất `r_bloodpact`** (dòng 633-635) khớp mẫu:

```
{id:'r_bloodpact', n:'Blood Pact', rar:3, a:'exec',
  d:'RISK: the whole party loses 25% Max HP, but all your damage is multiplied by 1.6.',
  mload:2, ex:['dmgMult'], mfPhase:'add', dmgMult:1.6,
  modFace:u=>{u.maxHp=Math.max(4,Math.round(u.maxHp*0.75));}}
```

Không relic COMMON/RARE/EPIC nào có drawback dạng này — đúng với luật taxonomy §3.1 của
`relic-system.md`: *"`pact` chỉ có ở LEGENDARY, và drawback phải là vĩnh viễn trong run, không
phải 'mất lượt này'."* Đây là do thiết kế, không phải thiếu sót.

### 3.2 Sự thật engine làm cho drawback này "vĩnh viễn xuyên trận", không phải "một lần"

`startCombat()` (`engine.js:385`) chạy `s.party = s.roster.map(r=>buildUnit(r,s))` ở **đầu mỗi
trận** — không chỉ đầu run. `buildUnit()` (`engine.js:60-79`) áp lại toàn bộ `modFace` của relic
đang giữ (dòng 75) rồi luôn kết ở `u.hp = u.maxHp` (dòng 77) — tức mỗi trận, Axie được hồi đầy đủ
lên đúng **mức Max HP đã bị relic hạ thấp**. Hệ quả thiết kế quan trọng, cần nói rõ vì dễ hiểu sai
theo hai hướng:

- **Không đúng**: "Blood Pact làm bạn vào trận sau với HP thấp vì trận trước bị thương." (HP không
  carry-over giữa các trận — mỗi trận hồi đầy.)
- **Đúng**: "Blood Pact hạ TRẦN Max HP xuống 25% cho **mọi trận còn lại của run**, kể cả boss cuối."
  Đây là lý do nó phải được định giá như một khoản lỗ **lặp lại N lần** (N = số trận còn lại sau
  khi nhặt, trung bình 5-8 trận ở Full Run), không phải một khoản lỗ **một lần**.

Mô hình RP hiện tại (`relic-system.md` §4.5 ví dụ 6) định giá drawback bằng kỳ vọng damage mà
lượng HP đó "đáng ra đã chặn được" **trong một trận đại diện** — đúng phương pháp cho stat số
thường (vì hầu hết relic khác đều tính theo một trận đại diện), nhưng **sai phương pháp cho một
khoản lỗ áp dụng lại ở MỌI trận sau**: rủi ro thật không phải "kỳ vọng damage hụt mất", mà là
**xác suất toàn diệt** (`checkEnd()`, `engine.js:945`: `s.phase='lost'` khi không còn Axie nào
sống) tăng lên ở từng trận, và rủi ro đó **cộng dồn theo số trận**, không phải cộng thẳng theo kỳ
vọng tuyến tính của một trận.

### 3.3 Sửa: hệ số rủi ro `κ_risk` cho drawback loại "vĩnh viễn, làm giảm sàn sống còn"

Áp dụng đúng logic mà `relic-system.md` §4.7 đã dùng cho APEX (`κ_rng`) và INFERNO (`κ_dot`): khi
một cơ chế có chi phí/lợi ích thật khác với kỳ vọng tuyến tính đơn giản, thêm hệ số điều chỉnh
riêng thay vì sửa số thô. Ở đây theo chiều ngược lại — APEX/INFERNO cần κ < 1 để relic đó được
phép **rẻ hơn** (lợi ích bị đánh giá cao hơn thực tế); pact permanent-HP-loss cần **κ_risk > 1** để
drawback được tính **đắt hơn** (cái giá đang bị đánh giá thấp hơn thực tế).

`κ_risk = 2.0` (xem §4 để có công thức và ví dụ số). Không đổi taxonomy, không đổi mload/ex, không
đổi luật "pact chỉ LEGENDARY" — chỉ vá cách tính một số hạng trong công thức RP.

### 3.4 Relic cụ thể: `r_bloodpact` — trước/sau

| | Trước (2026-09-03) | Sau (đề xuất) |
|---|---|---|
| Mất Max HP | **25%** | **15%** |
| Damage nhân | ×1.6 (không đổi) | ×1.6 (không đổi) |
| `mload` | 2 (không đổi) | 2 (không đổi) |
| `ex` | `['dmgMult']` (không đổi) | `['dmgMult']` (không đổi) |
| RP theo mô hình EV cũ | 35.60 | không áp dụng nữa (mô hình thay) |
| RP theo mô hình rủi ro mới | 29.2 *(nếu vẫn giữ 25%)* — dưới sàn LEGENDARY | **34.32** — trong dải [31.77, 42.97] |
| Code cần đổi | `u.maxHp*0.75` | `u.maxHp*0.85` |
| Text cần đổi | *"loses 25% Max HP"* | *"loses 15% Max HP"* |

Không đổi `dmgMult` vì đây đã là multiplier toàn cục (`mload` 2, trần theo §3.6 của
`relic-system.md`) — bồi thêm sức mạnh ở đây sẽ đẩy relic ra khỏi triết lý "nâng sàn thay vì nâng
trần" mà chính `relic-system.md` §4.7(4) đã chọn cho các đền bù khác. Giảm cái giá (không phải
tăng phần thưởng) cũng khớp trực tiếp với câu phàn nàn của product owner: *"mất X% máu... không
đáng"* — vấn đề nằm ở vế chi phí, sửa vế chi phí.

### 3.5 Các relic khác đã rà soát — xác nhận không cần sửa thêm

Ba relic từng bị chính `relic-roster-expansion.md` (§6.7.x, viết trước khi implement) chấm "quá
yếu"/"vi phạm nặng" đã được kiểm tra chéo với bản ship hiện tại trong `data.js` và xác nhận **đã
được sửa đúng như đề xuất, không còn tồn đọng**:

- `r_hivequeen` (từng 12.10 RP = 36% một LEGENDARY) → bản ship hiện tại (`data.js:665-666`,
  `eggInherit:1, tokenCap:6, mload:2`) khớp đúng bản sửa "Axie Egg nhận mọi hiệu ứng `modFace`,
  tối đa 6 Egg" — RP mục tiêu 38.00. Không cần sửa thêm.
- `r_dawnlance` (từng định giá sai điều kiện "full HP" → chỉ 6.80 RP) → bản ship hiện tại
  (`data.js:660-662`, điều kiện `hp>maxHp*0.5`) khớp đúng bản sửa "trên 50% HP" — RP mục tiêu
  38.90. Không cần sửa thêm.
- `r_ironmaiden` (từng 66.50 RP = 155% trần LEGENDARY, "một mình kết thúc encounter") → bản ship
  hiện tại (`data.js:667-673`, nhắm một địch nhiều HP nhất, cap thorns tại 7 qua hằng
  `IRONMAIDEN_CAP`) khớp đúng bản sửa — RP mục tiêu 33.25. Không cần sửa thêm.

Không tìm thêm relic nào khác bị định giá sai theo kiểu "mơ hồ/trùng ý tưởng/quá mạnh" ngoài lỗi
công thức drawback ở §3.2-3.4. Hệ thống dedup (`ex`/`exSub`, §3.7/§3.7a của `relic-system.md`) và
tier monotonicity (§3.12) đã đóng kín các lỗ hổng loại đó ở bản 2026-09-03.

## 4. Formulas

### 4.1 Công thức EV cũ (đã dùng để duyệt `r_bloodpact`, `relic-system.md` §4.5 ví dụ 6)

```
reward(dmgMult)      = D × (dmgMult − 1)                     D = 70  (tổng HP địch/trận, §4.0)
drawback_EV(pct)     = N × (pct × H̄) × p_hit × w_def
  N     = 5      (số Axie trong party)
  H̄     = 17     (Max HP trung bình 1 Axie, suy từ 4.25 = 0.25 × 17)
  p_hit = 0.86    (xác suất bị đánh trúng/trận — đo từ dữ liệu MON, §4.0)
  w_def = 0.35    (trọng số quy đổi 1 HP phòng thủ ra RP — hệ số phòng thủ chuẩn của mô hình)

RP_net_cũ = reward(dmgMult) − drawback_EV(pct)
```

Với `r_bloodpact` (`dmgMult=1.6`, `pct=0.25`):
```
reward  = 70 × 0.6              = 42.0
drawback_EV(0.25) = 5 × (0.25×17) × 0.86 × 0.35 = 5×4.25×0.86×0.35 = 6.4
RP_net_cũ = 42.0 − 6.4           = 35.6      → trong dải LEGENDARY [31.77, 42.97] ✓ (đã duyệt)
```

### 4.2 Vấn đề: `drawback_EV` chỉ đo MỘT trận, drawback thật kéo dài N_fight trận

`drawback_EV` trả lời câu "lượng HP mất đi có thể đã chặn bao nhiêu damage, ở MỘT trận đại diện."
Nhưng theo §3.2, cái giá thật là: Max HP bị hạ **ở mọi trận còn lại của run**, làm tăng xác suất
toàn diệt (`checkEnd`) tích luỹ qua nhiều trận — một đại lượng phi tuyến (rủi ro tăng nhanh hơn
tuyến tính khi HP buffer giảm, vì burst damage/AoE của elite và boss dễ vượt ngưỡng chịu đựng hơn
khi trần thấp hơn). Mô hình cũ không có hạng nào đại diện cho việc này.

### 4.3 Công thức mới: nhân thêm `κ_risk`

```
drawback_risk(pct) = drawback_EV(pct) × κ_risk        κ_risk = 2.0   (Tuning Knob §7)

RP_net_mới = reward(dmgMult) − drawback_risk(pct)
```

**Vì sao κ_risk = 2.0, không phải một số khác:** đây là biên độ **thận trọng, tối thiểu** để nhóm
`pact` không bị over-nerf trong lần sửa đầu — cùng cỡ độ lớn với hệ số đã dùng cho APEX
(`1/κ_rng = 1/0.75 = 1.33×`), nhân thêm hệ số ước lượng **1.5×** cho tính chất "áp dụng lặp lại ở
mọi trận tương lai" (≈ trung bình 5-8 trận còn lại sau khi nhặt LEGENDARY ở Full Run, quy về một
hệ số nhân đơn thay vì mô hình hoá chi tiết theo N_fight — xem §7 để biết vì sao chọn hệ số đơn
thay vì hàm theo N_fight). `1.33 × 1.5 ≈ 2.0`.

Kiểm tra với `pct = 0.25` (giá trị đang ship):
```
drawback_risk(0.25) = 6.4 × 2.0           = 12.8
RP_net_mới           = 42.0 − 12.8         = 29.2   → DƯỚI sàn LEGENDARY (31.77), lệch −8.1% ✗
```
Xác nhận đúng cảm nhận product owner: theo giá rủi ro thật, relic đang ship **định giá cao hơn**
giá trị thật của nó — tức người chơi trả (rủi ro) nhiều hơn cái họ nhận, và cảm thấy "không đáng"
là đúng, không phải cảm tính.

### 4.4 Giải ngược: tìm `pct` mới để về giữa dải

```
RP_net_mới(pct) = 42.0 − (25.6 × pct × κ_risk) = 42.0 − 51.2×pct

Chọn điểm neo: 34.0  (giữa-dưới dải LEGENDARY [31.77, 42.97], không neo giữa tuyệt đối 37.37
                       vì drawback vẫn phải cảm nhận được là "đắt", không chọn cạnh trên)

pct = (42.0 − 34.0) / 51.2 = 0.156  → làm tròn xuống mốc dễ đọc, dễ nói bằng lời: pct = 0.15 (15%)

Kiểm tra lại: RP_net_mới(0.15) = 42.0 − 51.2×0.15 = 42.0 − 7.68 = 34.32   ✓ trong dải [31.77, 42.97]
```

**Kết luận công thức**: đổi `r_bloodpact` từ **mất 25% Max HP** → **mất 15% Max HP**, giữ
`dmgMult:1.6`. RP thực theo mô hình rủi ro mới: **34.32**.

## 5. Edge Cases

- **`pct = 0`**: không hợp lệ theo định nghĩa — một relic `pact` không có drawback thật không còn
  là `pact`, phải đổi loại (`cat`) sang `scale`/`rule`. Không áp dụng cho `r_bloodpact` (luôn > 0).
- **Làm tròn Max HP**: `Math.max(4, Math.round(u.maxHp*0.85))` — giữ nguyên sàn bảo vệ `4` đã có
  (tránh Max HP về 0 hoặc âm với Axie Max HP gốc rất thấp, ví dụ Axie tier 1 mới `hp` thấp cộng
  `bonusHp` âm nếu có debuff khác). Sàn 4 không đổi so với bản cũ.
- **Token/Egg không bị ảnh hưởng trực tiếp**: `mkAlly()` không đi qua `buildUnit()` nên không nhận
  `modFace` của `r_bloodpact`, trừ khi `r_hivequeen` (`eggInherit`) cũng đang giữ. Nhưng
  `r_bloodpact` (`mload:2`) + `r_hivequeen` (`mload:2`) = 4 > `RELIC_MLOAD_CAP` (2) → **không bao
  giờ được đề nghị cùng lúc** (`relicPool()` chặn ở điểm phát, §3.6 của `relic-system.md`) — không
  cần xử lý case này, đã bị hệ mload chặn cấu trúc.
- **Thứ tự nhặt (`modFaceOrder`, INV-5)**: `modFace` của `r_bloodpact` gán thẳng
  `u.maxHp = round(u.maxHp × 0.85)` (không phải phép cộng dồn tuần tự với relic khác cũng sửa
  `maxHp` theo tỉ lệ) — hiện tại không relic nào khác nhân `maxHp` theo phần trăm, nên thứ tự nhặt
  không ảnh hưởng kết quả cuối. Nếu tương lai thêm relic pact thứ hai cũng sửa `maxHp` theo %, cần
  kiểm lại tính giao hoán (nhân trước/nhân sau `r_bloodpact` cho kết quả khác nhau) — hiện tại
  không xảy ra nên không cần sửa `mfPhase`.
- **Relic pact tương lai**: nếu `relic-roster-expansion.md` hoặc bất kỳ bản mở rộng nào sau này
  thêm relic `cat==='pact'` mới, **bắt buộc** áp cùng `κ_risk` khi định giá drawback — không được
  quay lại dùng `drawback_EV` trần. Đây là lý do §4.3 viết thành công thức tổng quát, không phải
  patch số cho riêng `r_bloodpact`.
- **Tương tác với event LUNACIA SHRINE "wager"** (-20% Max HP đổi 1 Legendary ngẫu nhiên,
  `EVENTS`, không phải `RELICS`): nếu Legendary nhận được ngẫu nhiên chính là `r_bloodpact` sau
  bản vá này, tổng Max HP mất của Axie có thể là hai lần liên tiếp (20% từ event + 15% từ relic,
  không cộng dồn tuyến tính vì áp lên `maxHp` đã bị giảm lần trước) — đây là tương tác giữa hai hệ
  khác nhau (EVENTS × RELICS), **ngoài phạm vi bản vá này** (chỉ sửa biến `RELICS`). Ghi lại làm
  follow-up ở §6.

## 6. Dependencies

- **`design/gdd/relic-system.md`** — nguồn taxonomy/mload/ex, không đổi. Cần patch thêm một mục
  mới (đề xuất: §4.7bis, ngay sau §4.7 "Ba mispricing") trỏ về file này, để công thức `κ_risk`
  không bị lạc mất khỏi nguồn sự thật chính. Quan hệ hai chiều: file này phụ thuộc taxonomy của
  `relic-system.md` (định nghĩa `pact`, `mload`, dải LEGENDARY); `relic-system.md` cần dẫn ngược
  lại file này ở mục `pact` để người đọc sau biết công thức drawback đã được vá.
- **`src/data.js`** — `RELICS[r_bloodpact]` (dòng ~633-635): đổi `0.75` → `0.85`, đổi description
  string `"25%"` → `"15%"`. Không đổi field nào khác (`mload`, `ex`, `dmgMult`, `rar`).
- **`src/engine.js`** — không cần đổi. `buildUnit()`/`startCombat()`/`checkEnd()` là **bằng chứng**
  cho lý do của bản vá (§3.2), không phải nơi cần sửa.
- **`tools/t_relic.mjs`** (INV-1) — cần cập nhật giá trị RP kỳ vọng của `r_bloodpact` nếu test có
  hard-code 35.60; giá trị mới theo mô hình rủi ro là 34.32, vẫn nằm trong dải cứng
  [31.77, 42.97] nên **không cần đổi dải**, chỉ đổi số RP đo được của riêng relic này.
  `t_relic_behaviour.mjs` (38 proof hành vi) — kiểm tra lại proof nào test cụ thể giá trị `0.75`
  hoặc `25%` của `r_bloodpact`, phải cập nhật theo `0.85`/`15%`.
- **`design/gdd/relic-roster-expansion.md`** — đã xác nhận (§3.5) không có relic `pact` nào khác
  trong 48 entry mới; bản vá này không lan sang file đó.
- **EVENTS (`src/data.js`, biến `EVENTS`, mục `shrine`)** — ngoài phạm vi biến `RELICS` được giao,
  nhưng mang cùng bản chất đánh đổi HP (-20% Max HP đổi 1 Legendary). Khuyến nghị: một lượt rà
  soát riêng cho `EVENTS` áp cùng phương pháp `κ_risk`, không gộp vào bản vá này.

## 7. Tuning Knobs

| Knob | Loại | Giá trị hiện tại | Dải an toàn | Lý do |
|---|---|---|---|---|
| `κ_risk` | **Curve** | 2.0 | [1.5, 2.5] | Hệ số nhân giá của drawback vĩnh viễn loại "giảm sàn sống còn". Tăng nếu sau khi hạ RP mà sim (`tools/sim.js`) vẫn cho thấy archetype exec/FERAL overperform tương đối so với 10 archetype còn lại; giảm nếu winrate exec/FERAL rơi quá mạnh (over-nerf) sau khi áp dụng. Không mô hình hoá chi tiết theo số trận còn lại (N_fight) vì run có độ dài thay đổi (Short Run ≈12 wave, Full Run dài hơn) và vị trí nhặt LEGENDARY biến thiên theo RNG — một hệ số đơn, thận trọng, dễ tinh chỉnh bằng sim thực tế hơn một hàm N_fight khó đo. |
| `r_bloodpact` — % Max HP mất | **Curve** | 15% (đề xuất, hiện ship 25%) | [10%, 20%] | Trần 20%: quá 20% lặp đúng cảm giác "quá đau" mà product owner đã nêu trực tiếp bằng ví dụ 20%. Sàn 10%: dưới đó không còn là "drawback thật" theo §3.1 của `relic-system.md` — sẽ đọc như buff gần như miễn phí, phá vỡ Player Fantasy (§2) của chính loại `pact`. |
| `r_bloodpact` — `dmgMult` | **Feel** (không đổi trong bản vá này) | 1.6 | không đổi | Đây đã là multiplier toàn cục ở trần `mload` (2/2). Tăng số này cần tăng `mload` hoặc phá triết lý "nâng sàn không nâng trần" của `relic-system.md` §4.7(4) — ngoài phạm vi một bản vá công thức drawback. |
| Điểm neo giải phương trình (§4.4) | **Curve** | 34.0 (giữa-dưới dải LEGENDARY) | [32, 36] | Chọn giữa-dưới thay vì giữa dải tuyệt đối (37.37) có chủ đích: một relic có drawback thật nên nằm ở nửa dưới dải giá trị của bậc, để "cái giá" vẫn cảm nhận được ngay cả sau khi định giá đúng — không nên tối ưu hoá relic pact để trở thành lựa chọn RP cao nhất của LEGENDARY. |

## 8. Acceptance Criteria

- **AC-1 (máy đo được)**: `node tools/t_relic.mjs` báo **94/94 PASS** sau khi cập nhật giá trị RP
  kỳ vọng của `r_bloodpact` theo mô hình mới (34.32), vẫn trong dải cứng LEGENDARY
  [31.77, 42.97].
- **AC-2 (máy đo được)**: `node tools/sim.js 500 mode=short asc=0` chạy trước/sau bản vá — winrate
  và playrate của archetype **exec (FERAL)** không được lệch quá **±5 điểm phần trăm tuyệt đối**
  so với baseline trước bản vá (kiểm tra không over-nerf lẫn không under-nerf).
- **AC-3 (máy đo được)**: description string trong `data.js` của `r_bloodpact` phải khớp đúng số
  thực thi trong `modFace` (`"15%"` khớp `× 0.85`) — không được lệch số như lỗi lịch sử đã ghi
  nhận ở relic khác (`r_dawnlance` từng lệch điều kiện mô tả vs code, đã sửa).
  `t_relic_behaviour.mjs` phải có ít nhất 1 proof hành vi mô phỏng `buildUnit` với `r_bloodpact`
  đang giữ và assert `u.maxHp` giảm đúng 15% (làm tròn theo `Math.round`), không phải 25%.
- **AC-4 (playtest thủ công, không đo bằng máy được — theo `coding-standards.md`, mục Visual/Feel)**:
  hỏi trực tiếp người chơi test sau khi nhặt `Blood Pact`: *"Bạn có cảm thấy đánh đổi này đáng
  không?"* — kỳ vọng đồng thuận tích cực rõ ràng hơn so với phiên bản 25% (baseline: đúng câu
  phàn nàn đã ghi nhận từ product owner). Ghi nhận vào `production/qa/evidence/`.
- **AC-5 (quy trình, cho tương lai)**: mọi relic `cat==='pact'` mới thêm sau này (trong
  `relic-roster-expansion.md` hoặc bản kế tiếp) phải được tính RP qua công thức `κ_risk` ở §4 của
  file này trước khi duyệt — không được duyệt bằng `drawback_EV` trần của `relic-system.md` §4.5
  gốc. Thêm dòng nhắc này vào checklist review relic mới (nơi checklist đó được duy trì, ví dụ
  `design/gdd/systems-index.md` hoặc quy trình `/design-review`).
