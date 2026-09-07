# Quick Design Spec: Formation Resonance (Cộng Hưởng Đội Hình)

**Type**: New Small System (Addition vào Core Combat Loop — bước EXECUTE)
**System**: Combat — Roll → Reroll → Execute → End Turn
**GDD Reference**: `design/gdd/game-concept.md` → Detailed Rules → "Core Rules — Vòng lặp một trận" (bước 3 EXECUTE) và "Core Rules — Die & Part vocabulary"
**Date**: 2026-09-01
**Estimated Implementation**: ~4–6 giờ (`src/engine.js` ~40-50 dòng mới/sửa, `src/data.js` +1 hằng số, `src/ui.js`/`src/fx.js` hiển thị preview + 1 sự kiện mới)

---

## Overview

Formation Resonance là một luật MỚI cho bước EXECUTE: nếu hai Axie **liền kề nhau trong đội hình** (thứ tự chọn ở màn "CHOOSE YOUR TEAM") cùng roll ra mặt **cùng loại giá trị** (dmg/shield/heal/poison/mana) trong CÙNG một lượt, thì lần thực thi thứ hai của cặp đó nhận **+15% giá trị mặt** (`RESONANCE.mult`). Đây là cơ chế đầu tiên khiến **thứ tự sắp xếp đội hình của người chơi** và **thứ tự click thực thi các mặt trong lượt** trở thành quyết định có ý nghĩa — hiện tại cả hai điều này không ảnh hưởng gì tới luật chơi.

## Vì sao đây là mechanic MỚI (không lặp lại thứ đã có dưới tên khác)

| So sánh với | Đặc điểm đã có | Formation Resonance khác ở đâu |
|---|---|---|
| Class passive (FERAL, TALON, BULWARK...) | Cố định theo class, luôn có sẵn trên 1 Axie đơn lẻ, không phụ thuộc Axie khác | Là **liên-Axie** (cross-unit), phụ thuộc vị trí đội hình + kết quả roll của Axie *khác*, không thuộc về class nào cả — mọi class đều hưởng như nhau |
| Archetype tracker (PLAGUE/TEMPEST/...) | Tích lũy qua cả build (đếm keyword đang dùng), không đổi trong 1 lượt | Là trạng thái **theo-lượt** (per-turn), reset mỗi turn, không liên quan tới build tổng thể |
| Cantrip / echo / chain / multi | Nhân bản hoặc lặp lại hành động của **cùng một mặt** | Resonance nối **hai mặt của hai Axie khác nhau** |
| Reroll hiện tại | Chỉ có tác dụng "sửa roll xấu" | Reroll giờ có thêm lý do chiến thuật mới: chủ động fish để 2 Axie liền kề ra cùng loại mặt |
| Thứ tự click thực thi (EXECUTE) | Không có ý nghĩa gì — click theo thứ tự nào cũng ra kết quả giống nhau | **Lần đầu tiên** thứ tự thực thi ảnh hưởng tới kết quả (ai thực thi SAU trong cặp mới được cộng) |
| Thứ tự chọn đội ở màn hình Team Select | Không có ý nghĩa gì — chỉ là thứ tự hiển thị | **Lần đầu tiên** trở thành một quyết định build thật (đặt 2 Axie cùng thiên hướng loại mặt cạnh nhau) |

Kết luận: đây là một trục chiến thuật hoàn toàn chưa tồn tại (vị trí đội hình + thứ tự thực thi), không phải một biến thể đổi tên của passive/archetype/keyword hiện có.

## Player Fantasy liên quan (MDA)

Aesthetic chính: **Challenge** (tính toán thứ tự tối ưu) + **Discovery** (nhận ra cặp Axie nào "ăn ý" theo loại mặt) — bổ trợ trực tiếp cho pillar "Minh bạch triệt để": toàn bộ trạng thái resonance phải hiển thị TRƯỚC khi người chơi click, không phải là hiệu ứng bất ngờ sau khi đã hành động (xem Dependencies §UI Preview bắt buộc).

---

## Detailed Rules

1. **Vị trí đội hình (formation position)** của một Axie = chỉ số (index) của nó trong `s.roster` (thứ tự đã chọn ở màn Team Select, cố định trong suốt run — không đổi khi Axie chết/hồi sinh/level up). Ally token (summon) KHÔNG có vị trí đội hình và không tham gia Resonance.
2. **Loại đủ điều kiện** (`RESONANCE.types`): `dmg`, `shield`, `heal`, `poison`, `mana`. Mặt `buff`/`debuff`/`blank` không đủ điều kiện (giá trị của chúng đến từ keyword cố định, không đi qua `faceValue()`, xem Formulas §3).
3. Hai Axie A và B được coi là **liền kề** khi và chỉ khi `|pos(A) − pos(B)| === 1`. Không có wraparound (vị trí 0 và vị trí 4 không bao giờ liền kề). Axie đã chết ở giữa **không bị bỏ qua** — vị trí 1 và vị trí 3 không liền kề dù vị trí 2 đang chết.
4. Đầu mỗi lượt (sau `rollAll`), một cặp được coi là **"đang mở" (open)** nếu: cả hai Axie còn sống, đã roll (`rolled>=0`), chưa dùng mặt (`!used`), liền kề, và mặt hiện tại của cả hai có cùng `type` thuộc `RESONANCE.types`. Trạng thái mở này được UI đọc lại (không lưu riêng) bất cứ lúc nào ở bước EXECUTE và REROLL để hiển thị preview — xem Dependencies.
5. Khi người chơi thực thi mặt của Axie X (bấm die → bấm target):
   - Engine kiểm tra: có Axie liền kề Y đã **thực thi trước đó trong cùng lượt này** với mặt cùng `type`, và bản ghi đó **chưa được tiêu thụ**?
   - Nếu có: X nhận **Resonance Bonus** cho lần thực thi này (xem Formulas §1), và bản ghi của Y được đánh dấu **đã tiêu thụ**. X **không** tạo bản ghi mới (X đã là "nửa sau" của cặp, không thể làm "nửa đầu" cho một cặp khác cùng lượt).
   - Nếu không có: X không nhận bonus, nhưng hành động của X được **ghi lại** thành một bản ghi "mở" (`{pos, type, used:false}`) để một Axie liền kề thực thi SAU có thể khớp với nó.
6. Mỗi bản ghi chỉ được tiêu thụ **đúng một lần**. Nếu 3 Axie liền kề cùng loại mặt (vị trí 1-2-3 đều `dmg`), chỉ **một cặp** được thưởng (ví dụ 1↔2), Axie thứ 3 không tự động chain thêm — xem Edge Cases.
7. Resonance Bonus **không hồi tố**: Axie thực thi trước (nửa đầu của cặp) luôn nhận giá trị gốc, không được cộng lại sau khi cặp khớp. Chỉ nửa sau nhận bonus. Đây là chủ đích thiết kế — không có "sửa lại kết quả đã hiện ra" để giữ đúng pillar minh bạch/deterministic.
8. Reroll không xóa các bản ghi đã tạo bởi Axie đã thực thi (những Axie đó không thể reroll vì `doReroll` đã lọc `!u.used`). Reroll chỉ ảnh hưởng tới các Axie CHƯA thực thi, nên không có rủi ro "bản ghi ma" bị lệch dữ liệu.
9. Trạng thái Resonance được reset về rỗng vào đầu mỗi lượt mới (ngay trước khi roll lại dice cho lượt kế tiếp), và khi bắt đầu trận đấu mới.
10. Địch (`side==='e'`) và ally token không bao giờ tham gia Resonance, dù ở vai trò nguồn hay đích.

---

## Formulas

### 1. Resonance value multiplier

```
v_final = ceil(v_base × RESONANCE.mult)      nếu Axie đang ở trạng thái "resonantNow"
v_final = v_base                              nếu không
```
- `v_base` = giá trị mặt sau khi đã áp dụng mọi modifier khác đã có (vital ×2, weaken trừ, overdrive ×1.5, hiveMind cộng thêm — xem `faceValue()` hiện tại trong `src/engine.js`).
- `RESONANCE.mult` = 1.15 (mặc định, xem Tuning Knobs — giá trị đã shipped trong `src/client.html` từ commit `5f54429`, chưa bao giờ là 1.25).
- Áp dụng cho MỌI type đủ điều kiện (dmg/shield/heal/poison/mana) bằng cùng một công thức — không cần nhánh riêng theo type vì `faceValue()` đã trả về `v` thống nhất cho các type này.
- **Không áp dụng** cho giá trị của keyword cố định gắn kèm (vd. `weaken:2`, `burn:3`, `vulnerable:1`) — các giá trị này đọc trực tiếp từ chuỗi keyword trong `addStatus()`, không đi qua `faceValue()`, nên không bị nhân.

**Ví dụ tính toán**:
- Axie A (vị trí 1) roll mặt `HORN · dmg 10`, thực thi trước → gây 10 sát thương (không bonus, đây là nửa đầu).
- Axie B (vị trí 2) roll mặt `MOUTH · dmg 8`, thực thi sau, cùng type `dmg`, liền kề A → `v_final = ceil(8×1.15) = 10` sát thương thay vì 8.
- Nếu A có Vital active (đủ máu, mặt có keyword `vital`) và cũng resonant: `v = 8(base)×2(vital)=16 → ceil(16×1.15)=19`. Thứ tự nhân: vital trước, resonance sau cùng (resonance luôn là bước nhân cuối cùng trong `faceValue()`).

### 2. Trigger detection (pseudocode cho `checkResonance`)

```
function formationPos(s, u):
    if u.token: return -1
    return index of u.uid in s.roster   // -1 nếu không tìm thấy (địch, token)

function checkResonance(s, u, f):
    if u.side != 'p' or u.token: return false
    if f.t not in RESONANCE.types: return false
    pos = formationPos(s, u)
    if pos < 0: return false
    idx = find first entry e in s.resonanceLog where:
        e.used == false AND e.t == f.t AND abs(e.pos - pos) == 1
    if idx found:
        s.resonanceLog[idx].used = true
        return true
    return false

function logResonanceAttempt(s, u, f, wasConsumer):
    if u.side != 'p' or u.token: return
    if f.t not in RESONANCE.types: return
    if wasConsumer: return   // nửa sau không tạo bản ghi mới
    pos = formationPos(s, u)
    s.resonanceLog.push({pos, t: f.t, used: false})
```

### 3. Điểm tích hợp chính xác trong `src/engine.js`

- `execFace(s,u,tgtUid)`: ngay sau dòng `if(f.t==='blank') return false;`, thêm:
  ```js
  const isResonant = checkResonance(s,u,f);
  u.resonantNow = isResonant;
  if(isResonant) ft(s,u,'LINK ×'+RESONANCE.mult,'buf');
  ```
  Sau khi `doFace` gọi thành công (`const ok=doFace(...)` trả `true`), thêm:
  ```js
  logResonanceAttempt(s,u,f,isResonant);
  if(isResonant) EV(s,{t:'resonance',uid:u.uid});
  ```
  Tại vị trí reset `if(u.side==='p'&&u.critNow) u.critNow=false;` cuối hàm, thêm dòng `u.resonantNow=false;`.
- `faceValue(s,u,fi)`: ngay trước `return v;` (dòng cuối hàm), thêm:
  ```js
  if(u.side==='p'&&u.resonantNow) v=Math.ceil(v*RESONANCE.mult);
  ```
- `startCombat(s,kind)`: thêm `s.resonanceLog=[];` cạnh dòng `s.undo=[]; s.log=[];`.
- `endTurn(s)`: thêm `s.resonanceLog=[];` cạnh dòng `s.rerolls=s.maxRerolls; s.usedActives=[];` (reset khi lượt mới bắt đầu, sau khi địch đã hành động và trước khi roll lại).
- `SNAP` array (dùng cho undo): thêm `'resonanceLog'` vào danh sách khóa (`u.resonantNow` không cần thêm riêng vì đã nằm trong object `u` được clone toàn bộ qua khóa `'party'` có sẵn).
- Export thêm hàm `resonancePairs(s)` (đọc bên dưới, dùng cho UI preview) trong `module.exports` ở cuối file.
- `src/data.js`: thêm hằng số mới, đặt cạnh `TUNE`:
  ```js
  const RESONANCE = { mult: 1.15, types: ['dmg','shield','heal','poison','mana'] };
  ```
  và thêm `RESONANCE` vào `module.exports` của `data.js` nếu file đó có export tương tự `TUNE`/`ASCENSION`.

### 4. Helper cho UI preview — `resonancePairs(s)`

```
function resonancePairs(s):
    out = []
    real = for each (r, i) in s.roster:
        u = s.party.find(p => p.uid === r.uid)
        if u and u.hp>0 and u.rolled>=0 and not u.used:
            push {pos: i, u}
    for i in 0..len(real)-1:
        for j in i+1..len(real)-1:
            a, b = real[i], real[j]
            if abs(a.pos - b.pos) != 1: continue
            fa = a.u.die[a.u.rolled]; fb = b.u.die[b.u.rolled]
            if fa.t in RESONANCE.types and fa.t == fb.t:
                out.push({posA: a.pos, posB: b.pos, type: fa.t})
    return out
```
UI gọi hàm này lại sau mỗi roll/reroll để vẽ 1 icon "liên kết" (dùng lại icon type hiện có trong `icons.js`, không cần art mới) giữa 2 chân dung Axie liền kề đang có cặp mở. Đây là bắt buộc, không phải nice-to-have — xem Dependencies.

---

## Edge Cases

- **3+ Axie liền kề cùng type trong 1 lượt**: chỉ 1 cặp được thưởng (cặp khớp trước theo thứ tự thực thi của người chơi); Axie dư ra thực thi bình thường không bonus, không lỗi. Đây là giới hạn chủ đích để chặn combo tuyến tính vô hạn (xem Balance Impact).
- **Formation tối đa 5 Axie → tối đa 2 cặp không chồng lấn mỗi lượt** (vd. 1-2 và 3-4, Axie 5 lẻ ra). Trần sức mạnh mỗi lượt bị chặn cứng ở +2 lần bonus, không phụ thuộc số lượng Axie dmg-heavy trong đội.
- **Axie ở đầu/cuối đội hình (vị trí 0 và vị trí 4)**: chỉ có 1 partner tiềm năng, không phải 2 — là bất lợi hình học có chủ đích (khuyến khích xếp cặp resonance vào giữa đội hình).
- **Axie ở giữa bị chết**: không tạo "cầu nối" — 2 Axie ở hai đầu của một Axie đã chết không được coi là liền kề dù về mặt hình ảnh có thể trông gần nhau.
- **Cantrip loop** (`resolveCantrips`): một Axie có mặt cantrip có thể tự thực thi nhiều mặt liên tiếp trong cùng lượt (roll lại chính nó). Vì `checkResonance` so sánh vị trí khác nhau (`abs(pos_a-pos_b)===1`), một Axie không bao giờ tự khớp với chính nó — an toàn, không cần guard thêm.
- **Echo keyword** (`reps=2`, gọi `doFace` 2 lần trong cùng `execFace`): `u.resonantNow` được set 1 lần trước cả 2 lần gọi `doFace`, nên CẢ HAI lần thực thi của echo đều nhận bonus (nhất quán với cách echo đã nhân đôi mọi hiệu ứng khác — không phải lỗi, là hành vi mong đợi).
- **Relic active (`playerUseRelic`)**: KHÔNG đi qua `execFace`/`faceValue`, nên không tham gia Resonance ở bản v1 này (relic có công thức tính riêng, đây là scope out — ghi vào Open Questions nếu muốn mở rộng sau).
- **Reward mutation làm đổi type của một mặt** (`PART_REPLACE`) giữa các trận: không ảnh hưởng gì tới Resonance vì trạng thái reset mỗi trận/mỗi lượt — không có state nào bị "kẹt" qua các lần thay đổi build.
- **Undo giữa lượt**: nếu người chơi dùng Ctrl+Z ngay sau khi X vừa nhận Resonance Bonus (tiêu thụ bản ghi của Y), `undo()` phải khôi phục `s.resonanceLog` về trạng thái trước đó (bản ghi của Y trở lại `used:false`) — đã đảm bảo vì `resonanceLog` nằm trong `SNAP`.
- **Giá trị mặt = 0** (vd. mặt `buff` lọt qua do lỗi phân loại type tương lai): `ceil(0×1.15)=0`, không crash, không có hiệu ứng — an toàn tuyệt đối trước chia/nhân với 0.
- **Ally token (summon) đứng cạnh Axie thật về mặt UI**: không tham gia Resonance dù hiển thị gần nhau trên màn hình — cần ghi rõ trong tooltip UI để tránh hiểu lầm (xem Dependencies).

---

## Dependencies / Integration Contract

**Hệ thống này cung cấp (provides)**:
- `resonancePairs(s)` — hàm thuần (pure, đọc `s`, không sửa state) để UI tính preview.
- Sự kiện mới trong `s.ev`: `{t:'resonance', uid}` — bắn ra đúng lúc một Axie nhận Resonance Bonus, để `fx.js` phát hiệu ứng/âm thanh riêng (khác với `{t:'hit'}`/`{t:'ft'}` đã có).
- Float text mới: chuỗi `'LINK ×1.15'` với class css `'buf'` (tái dùng class màu buff đã có, không cần màu mới).

**Hệ thống này yêu cầu (requires)** — bắt buộc để không phá pillar minh bạch:
- `ui.js` (màn hình combat): sau mỗi lần roll/reroll, gọi `resonancePairs(s)` và vẽ 1 icon nối giữa 2 chân dung Axie liền kề đang có cặp mở, TRƯỚC khi người chơi click thực thi bất kỳ mặt nào. Không được chỉ hiện float text SAU khi bonus đã áp dụng — nếu chỉ làm vậy, cơ chế trở thành "may rủi ẩn", vi phạm trực tiếp player fantasy "minh bạch triệt để" đã ghi trong `game-concept.md`.
- `ui.js` (màn hình Team Select `scTeam()`): không bắt buộc phải thêm drag-to-reorder ở v1 (thứ tự click hiện tại đã đủ để xác định `s.roster` order), nhưng NÊN thêm 1 dòng hint ngắn "Thứ tự đội hình ảnh hưởng Resonance — xem Codex" để người chơi biết quyết định này có ý nghĩa. Drag-to-reorder đầy đủ có thể để lại làm cải tiến UX sau (ghi vào Nice-to-have của `/design-review` sau này, không block bản v1).
- `fx.js`: hook riêng cho event `resonance` (một hiệu ứng glow/pulse nhỏ nối 2 chân dung, tái dùng style hiệu ứng buff/shield đã có — không cần art mới).
- `data.js`: thêm hằng số `RESONANCE` (xem Formulas §3).

**Không đụng tới (does not modify)**:
- Semantics undo/reroll hiện có (reroll vẫn xóa undo stack như cũ; undo vẫn giới hạn trong lượt).
- Hệ rarity, reward pool, ascension, archetype scoring — Resonance không cộng điểm archetype ở v1 (có thể cân nhắc sau, xem Open Questions).
- Không thêm animation/sprite mới — chỉ tái dùng icon loại mặt (`icons.js`) và class CSS `buf` đã có.

---

## Tuning Knobs

| Knob | Giá trị mặc định | Khoảng an toàn | Loại | Rationale |
|---|---|---|---|---|
| `RESONANCE.mult` | 1.15 | 1.15 – 1.40 | Curve knob | Thấp hơn FERAL (+60% có điều kiện), cao hơn TALON (+3 flat) — vì Resonance dễ đạt hơn FERAL (không cần địch <50% HP) nhưng khó chủ động ép ra hơn TALON (cần đúng type + đúng vị trí cùng lúc). 1.15 nếu sim cho thấy team dmg-stack quá mạnh; 1.40 nếu tỷ lệ trigger thực tế trong `tools/sim.js` thấp hơn dự kiến và cơ chế bị người chơi bỏ qua vì "không đáng công sắp xếp". |
| `RESONANCE.types` (danh sách 5 type) | `[dmg,shield,heal,poison,mana]` | không nên thêm `buff`/`debuff` trừ khi các type đó được refactor để có giá trị số đi qua `faceValue()` | Gate knob | Giữ scope đúng những gì `faceValue()` thực sự kiểm soát; mở rộng sai sẽ tạo bug im lặng (nhân giá trị không tồn tại). |

---

## Balance Impact (định tính, chưa chạy sim)

- **Trần sức mạnh mỗi lượt bị chặn cứng**: tối đa 2 cặp không chồng lấn / lượt (5 Axie → tối đa 2 bonus, xem Edge Cases), nên không có rủi ro combo tuyến tính leo thang vô hạn kiểu "càng nhiều Axie cùng type càng mạnh theo cấp số nhân".
- **Chi phí cơ hội**: để chủ động ép resonance, người chơi thường phải dùng reroll cho mục đích "khớp type" thay vì "sửa roll xấu chỗ khác" — tạo đánh đổi thật giữa 2 lượt reroll giới hạn/turn, không phải buff miễn phí.
- **Tương tác với class hiện có**: không cộng dồn kiểu nhân chồng nguy hiểm với FERAL/TALON vì Resonance nhân vào `v` TRƯỚC — chuỗi nhân vẫn tuyến tính (`v×1.6×1.15` hay `v×1.15` rồi `+3` pierce của TALON, không có hiệu ứng cấp số nhân kép ẩn).
- **Rủi ro cần theo dõi qua `tools/sim.js`**: đội hình toàn Beast hoặc toàn Aqua (die thiên nhiều về 1-2 type) có thể đạt tỷ lệ trigger resonance cao hơn đội hình đa dạng type — nên chạy `node tools/sim.js 500` so sánh winrate đội "mono-type-adjacent" vs đội ngẫu nhiên sau khi implement, trước khi ship, đúng quy tắc "mọi thay đổi giá trị ship phải chạy qua sim" đã ghi trong `game-concept.md` → Tuning Knobs.
- **Đề xuất theo dõi**: nếu sim cho thấy winrate tăng >5% so với baseline chỉ nhờ xếp đội hình tối ưu resonance (không đổi build khác), hạ `RESONANCE.mult` xuống 1.15–1.20 trước khi ship.

---

## Acceptance Criteria

**Functional**:
- [ ] `GIVEN` Axie ở vị trí 0 roll mặt `dmg`, Axie vị trí 1 roll mặt `dmg`, chưa ai thực thi, `WHEN` gọi `resonancePairs(s)`, `THEN` trả về đúng 1 cặp `{posA:0,posB:1,type:'dmg'}`.
- [ ] `GIVEN` cặp trên, `WHEN` Axie 0 thực thi trước, `THEN` Axie 0 không nhận bonus (nửa đầu), `s.resonanceLog` có 1 bản ghi `{pos:0,t:'dmg',used:false}`.
- [ ] `GIVEN` trạng thái trên, `WHEN` Axie 1 thực thi sau vào cùng type, `THEN` giá trị mặt của Axie 1 = `ceil(v_base×1.15)`, bản ghi của Axie 0 chuyển `used:true`, sự kiện `{t:'resonance',uid:Axie1.uid}` xuất hiện trong `s.ev`.
- [ ] `GIVEN` 3 Axie liền kề cùng type (0,1,2 đều `dmg`), `WHEN` cả 3 thực thi theo thứ tự 0→1→2, `THEN` chỉ Axie 1 nhận bonus (khớp với 0); Axie 2 KHÔNG nhận bonus (bản ghi của Axie 1 không được tạo vì Axie 1 là "nửa sau tiêu thụ").
- [ ] `GIVEN` Axie ở vị trí 1 đã chết, `WHEN` kiểm tra liền kề giữa vị trí 0 và vị trí 2, `THEN` không được coi là liền kề (`abs(0-2)=2≠1`), không có bonus.
- [ ] `GIVEN` một hành động vừa tạo Resonance Bonus, `WHEN` người chơi bấm Undo, `THEN` `s.resonanceLog` khôi phục đúng trạng thái trước đó (bản ghi trở lại `used:false`), giá trị HP/shield liên quan cũng khôi phục đúng như cơ chế undo hiện có.
- [ ] `GIVEN` lượt kết thúc và lượt mới bắt đầu, `WHEN` roll lại dice, `THEN` `s.resonanceLog` rỗng (`[]`), không có bản ghi nào sót từ lượt trước.
- [ ] `GIVEN` một Ally token (summon) đứng liền kề một Axie thật với cùng type mặt, `WHEN` kiểm tra resonance, `THEN` KHÔNG kích hoạt (token luôn trả `formationPos=-1`).
- [ ] `GIVEN` mặt `f.t==='buff'` hoặc `'debuff'`, `WHEN` kiểm tra `checkResonance`, `THEN` luôn trả `false` (type không nằm trong `RESONANCE.types`).

**Experiential** (playtest thủ công, không tự động hóa được):
- [ ] Người chơi có thể nhìn thấy cặp resonance "đang mở" TRƯỚC khi click thực thi (kiểm tra bằng screenshot màn hình combat sau 1 lần roll có cặp khớp) — nếu không thấy được trước, FAIL pillar minh bạch, phải sửa UI trước khi ship.
- [ ] Sau 1 playtest ngắn (5-10 trận), người chơi được hỏi tự do có nhận ra "thứ tự xếp đội ở màn hình Team Select giờ có ý nghĩa" hay không — nếu không ai nhận ra sau khi được gợi ý xem hint UI, cân nhắc làm nổi bật hint hơn hoặc thêm drag-to-reorder ở bản sau.
- [ ] Chạy `node tools/sim.js 500` trước/sau khi thêm cơ chế với cùng seed range, xác nhận winrate không tăng bất thường (>5%) chỉ nhờ auto-pick đội hình resonance-tối-ưu.

---

## GDD Update Required?

**Yes.** Sau khi implement và playtest xác nhận ổn định, cần thêm 1 đoạn mới vào `design/gdd/game-concept.md`:
- Trong "Core Rules — Vòng lặp một trận", bước 3 (EXECUTE): thêm 1 câu mô tả Formation Resonance và trỏ về file quick-spec này.
- Trong bảng "Tuning Knobs" của `game-concept.md`: thêm dòng `RESONANCE.mult (1.15) | 1.15–1.40 | Đội hình mono-type liền kề trở nên quá mạnh nếu vượt trần`.

Không cần sửa Dependencies/Acceptance Criteria của `game-concept.md` (cơ chế này không đổi cấu trúc run/reward/rarity đã ghi ở đó).
