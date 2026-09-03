# RELIC SYSTEM — Axie Dice Tactics

> **Status**: Draft for review (chưa duyệt — cần product owner chốt trước khi implement)
> **Author**: systems-designer, 2026-09-03
> **Implements Pillar**: Minh bạch triệt để (Deterministic / Telegraphed Intent)
> **Nguồn**: đọc trực tiếp `src/data.js` (`PASSIVE`, `ARCH`, `HEROES`, `FACE_POOL`, `RELICS`, `TUNE`,
> `CURVE`, `UNLOCKS`), `src/engine.js` (mọi điểm tiêu thụ field relic), `src/ui.js:233/2505/2722`,
> `design/gdd/game-concept.md`, `design/gdd/economy-progression.md`, `design/gdd/combo-decision-memo.md` §3,
> `design/gdd/part-skill-identity.md` §3.7/§3.7a/§4.
> **Không sửa file nào khác** — mọi thay đổi cần thiết được liệt kê ở §11 SUPERSEDES / REQUIRED CHANGES.

---

## 0. SUPERSEDES / INVALIDATES

Doc này là **nguồn sự thật đầu tiên** cho hệ relic. Trước nó, relic chỉ tồn tại dưới dạng
mảng literal `RELICS` (`src/data.js:357`) với description một dòng, cộng vài câu nhắc trong
GDD khác. Không có doc nào bị *thay thế toàn bộ*, nhưng ba chỗ bị **vô hiệu hoá cục bộ**:

| Chỗ | Nội dung cũ | Trạng thái |
|---|---|---|
| `game-concept.md` §Core Rules — Relic | "44 relic hoạt động qua hệ hook…" | **Sai số lượng** sau doc này (**94**). Câu mô tả hook vẫn đúng. |
| `bloodline-system.md` §13 (2 chỗ) | "44 relic" dùng làm mẫu số tính content | Cập nhật thành **94** |
| `data.js:354-356` comment hook list | Liệt kê `onRollEnd · onTurnEnd · onDmgTaken · onPoison` | `onTurnEnd`, `onDmgTaken`, `onPoison` **chưa bao giờ được gọi** trong `engine.js`. Comment đang nói dối. Xem §10. |

**Ba defect gốc được sửa tận rễ trong doc này** (không phải patch bề mặt):

1. `exec` không có entry trong `ARCH` → `ARCH` lên **11 archetype**, thêm `exec` = FERAL.
2. `faceArch()` không bao giờ trả `thorns`/`exec` → viết lại thành **bảng ưu tiên tường minh** (§3.4).
3. Không có trần cho việc cộng dồn multiplier → **Multiplier Load (`mload`) cap = 2** (§3.6).

---

## 1. Overview

Relic là **tầng đổi-luật** của Axie Dice Tactics: vật phẩm mang theo suốt một run, mỗi cái
sửa một luật của engine (không phải chỉ cộng số) cho **toàn party**. Chúng là phương tiện chính
để 11 archetype trong `ARCH` chuyển từ "nhãn trên tracker UI" thành "build có thể đuổi theo".

Doc này định nghĩa: (a) **taxonomy** 5 loại relic và quyền hạn của từng bậc rarity, (b) một
**mô hình ngân sách RP/VPM** khiến giá trị relic suy ra từ công thức chứ không từ khẩu vị
designer, (c) **mục tiêu phủ archetype** theo từng bậc rarity, (d) hai luật chống suy biến —
**anti-stacking (`mload`)** và **de-duplication (`ex`)**, (e) **retune/retag toàn bộ 44 relic
đang có, id giữ nguyên**, và (f) các fix gốc cho `ARCH`/`faceArch()`/`exec`/`thorns`.

**Roster đích: 94 relic** (78 passive + 16 active) = 44 đã có (§6, retune) + 48 entry của
`design/gdd/relic-roster-expansion.md` (đã audit và kê thay đổi ở §6.7) + 2 entry PLAGUE bắt buộc
thêm (§6.7.7). Con số 94 là *đầu ra* của Nourishment Contract (§3.10) cộng với bất biến đơn điệu
(§3.12), không phải quota — xem §5.1. Bản trước của doc này ghi 84 và giả định expansion viết 40
entry; expansion thực tế viết 48.

**Bổ sung sau khi product owner nêu yêu cầu cứng (§3.12):** doc này còn định nghĩa (g) **bất biến
đơn điệu theo bậc** — không relic bậc thấp nào được mạnh hơn relic bậc cao, kiểm được bằng máy và
**đúng do cấu trúc công thức** chứ không do rà soát.

Nguyên tắc bao trùm, kế thừa từ `combo-decision-memo.md` §3: **hai hệ không được thưởng trên
cùng một trục đại lượng.** Relic đã là hệ nhân-damage lớn nhất trong game; vì vậy mọi trần
trong doc này được đặt trên *tích* các multiplier, không trên từng multiplier riêng lẻ.

## 2. Player Fantasy

*"Tôi không nhặt được món đồ mạnh hơn. Tôi nhặt được một luật chơi khác."*

Relic là nơi người chơi cảm thấy mình **đang lắp một cỗ máy**, không phải đang tăng chỉ số.
Ba cảm giác cụ thể mà hệ này phải tạo ra:

1. **Nhận diện engine** — cầm `Bastion Plate` xong, người chơi hiểu ngay "từ giờ Shield là
   damage", và mọi quyết định gán mặt sau đó đổi theo. Đó là khoảnh khắc build *bật lên*.
2. **Đuổi theo có phương hướng** — tracker archetype phải nói được "anh đang đi PLAGUE, còn
   thiếu 1 relic nữa". Muốn vậy mọi relic phải có tag đúng và mọi archetype phải có relic để
   tìm. Đây là lý do §5 (phủ archetype) là phần quan trọng nhất của doc, không phải §4.
3. **Trần rõ ràng thay vì trần ẩn** — người chơi được phép có build "phá game", nhưng phải
   thấy được vì sao nó dừng ở đâu. `mload` là trần *hiển thị được*; compounding vô hạn là
   trần ẩn (biểu hiện dưới dạng "run này thắng dễ vô lý, run kia không").

**Điều fantasy này KHÔNG bao gồm**: relic không được **cấp thẳng** bởi meta-currency; chúng luôn
là **đầu ra của run** (`economy-progression.md` §Tầng run), giống rarity của mặt.

> **Ghi chú sau quyết định "chấp nhận pay-to-win" của product owner (2026-09-03).** Ràng buộc trên
> **không** phải lập luận chống chi tiêu, và nếu trước đây nó được hiểu như vậy thì cách hiểu đó bị
> huỷ. Lý do thật là **đo lường**: mô hình RP ở §4 định giá relic theo `Act`, `Ω`, `E`, `D` —
> toàn bộ là đại lượng *trong một trận ở power-level `pw*`*. Một relic đến từ ngoài run (mua thẳng,
> bỏ qua `relicPool`) sẽ **bỏ qua cả `mload` cap lẫn `ex` de-dup**, vì cả hai được thi hành **tại
> điểm phát** (`relicPool`, §3.6/§3.7) chứ không tại điểm tính. Khi đó `RP` của một bộ relic không
> còn bị chặn và §3.12 mất hiệu lực.
> ⇒ **Đường bán hợp lệ**: bán *quyền tiếp cận* (mở sớm `u_relic1`/`u_relic2`, thêm lượt reroll shop,
> tăng số lựa chọn reward) — mọi thứ vẫn đi qua `relicPool` nên `mload`/`ex`/`RELIC_CAP` vẫn giữ.
> **Đường bán không hợp lệ**: gán thẳng `s.relics.push(id)`. Đây là ràng buộc **kỹ thuật về tính
> đo được**, không phải phán xét về monetization, và nó không nới lỏng §3.12 một chút nào.

## 3. Detailed Rules

### 3.1 Taxonomy — 5 loại relic

Mỗi relic thuộc **đúng một** loại. Loại quyết định (a) field engine nào được dùng,
(b) bậc rarity nào được phép, (c) cách tính ngân sách ở §4.

| Loại | `cat` | Định nghĩa (luật vào loại) | Field engine hợp lệ | Rarity được phép |
|---|---|---|---|---|
| **Stat-scaler** | `scale` | Đổi **giá trị số** của mặt hoặc của một đại lượng, không đổi luật nào. Người chơi vẫn ra quyết định y như cũ, chỉ với số khác. | `modFace` (chỉ `f.v`, `u.maxHp`), `critBonus`, `piercePlus`, `hiveMind`, `dr` | 0, 1, 2, 3¹ |
| **Rule-changer** | `rule` | Thêm/bỏ **một luật** — mặt hoặc trạng thái làm thứ trước đó nó không làm. Đổi *tập hành động hợp lệ* hoặc *cách resolve*, chứ không chỉ độ lớn. | `modFace` (chỉ `f.k`), `modDmg`, `onHit`, `onKill`, `onShield`, `burnSlow`, `burnSpread`, `poisonSpread`, `plague`, `healShield`, `noShieldCap`, `firstEcho`, `manaOverflow`, `safeReroll`, `poisonTicks` | 0², 1, 2, 3 |
| **Engine-starter** | `engine` | Cấp **tài nguyên khởi đầu hoặc mỗi lượt** để một archetype khởi động mà không cần chờ draw. | `startSummon`, `rerollUp`, `onTurnStart` | 1, 2, 3 |
| **Active card** | `act` | Thẻ Lunacia — tốn Mana, 1 lần/lượt, người chơi chủ động dùng. | `act:{cost,kind,v,tgt,…}` | 0, 1, 2, 3 |
| **Pact (risk/reward)** | `pact` | Có **drawback thật, không điều kiện** ghi vào state của run, đổi lấy một multiplier lớn. | mọi field + một drawback trong `modFace` | 3 |

¹ **`scale` ở rarity 3 phải mang `mload ≥ 1`** — một scaler lớn đến mức xứng LEGENDARY *là*
một multiplier trên thực tế và phải bị `mload` đếm. Ví dụ hợp lệ duy nhất trong roster hiện
tại: `r_apexpredator` (`critBonus:35 + critMult:3`, mload 1+1=2).

² **`rule` ở COMMON chỉ được là `rule-narrow`**, định nghĩa hẹp và kiểm được bằng máy:

```
rule-narrow  ⇔  relic CHỈ dùng modFace để f.k.push(kw) và CHỈ lên một slot part
                 (f.p === 'horn' | 'tail' | 'mouth' | 'back' | 'eyes' | 'ears'),
                 với kw NGOÀI kwPure  (⇒ không thể vi phạm Direction Law),
                 và KHÔNG có field hook nào (onHit/onKill/onShield/modDmg/…)
```

Đây là ngoại lệ **cần thiết**, không phải nới lỏng: Nourishment Contract điều khoản (c) đòi
mỗi archetype có một entry-point COMMON, nhưng 4 archetype (`pierce` `aoe` `exec` và
`poison` — Superlinear Axis Law §4.6) **không có scaler COMMON hợp lệ nào**. `rule-narrow`
là dạng đổi-luật duy nhất đủ nhỏ để nằm trong band 13 RP: nó bị chặn trên bởi `p_slot`
(cao nhất `mouth` = 0.278) nhân chi phí keyword. Ba relic COMMON hiện tại thuộc dạng này:
`r_pierceall` (12.8), `r_cleaveall` (14.2), `r_bloodmouth` (10.4). Đây là AC-9 mở rộng.

> 🔒 **`cat` là NHÃN TÀI LIỆU, không phải field. Nó KHÔNG được ship vào `src/data.js`.**
> §11 mục 3 bản trước yêu cầu *"thêm field `cat`, `mload`, `ex` cho cả 44"*. Yêu cầu đó **mâu thuẫn
> với INV-9** (§6.2a) của chính doc này: một field không ai đọc là **DEAD**, và INV-9 cấm ship field
> DEAD. `mload`/`ex` có người đọc (`relicPool`/`relicConflict`, §3.6/§3.7); **`cat` thì không** —
> không có điểm đọc nào trong `src/engine.js`, và nó không điều khiển hành vi nào. Ship nó ra sẽ bị
> `t_relic.mjs` phân loại `FIELD-DEAD` và **gate chuyển RED**. `cat` sống ở đây (§3.1) và ở cột
> `cat` của các bảng §6.1-§6.4, nơi nó là **phân loại để lập luận**, không phải cơ chế.
>
> ⚠️ **Bẫy grep — ghi lại vì người sau sẽ vấp đúng chỗ này.** `grep -n "\.cat"` trong `src/` **có**
> trả về hai dòng: `ui.js:967` và `ui.js:996`, cả hai đọc `(r.cat||'').toUpperCase()`. Trông như
> `cat` đã có người tiêu thụ. **Không phải.** Hai dòng đó render `echoBoxResult`/`echoFuseResult` —
> đối tượng do `fuseCosmetics()` (`ui.js:304`) tạo ra, hình dạng `{cat, rar, key, n}`, trong đó
> `cat` là **hạng mục cosmetic** (`ECHO_BOX_CATEGORIES`/`COSMETIC_POOLS`), **không** phải relic.
> Đây là trùng tên, không phải điểm đọc. Kết luận "cat đã có consumer ⇒ ship được" là **sai**, và
> nó là loại sai lầm mà chỉ đọc kỹ định nghĩa của `r` mới bắt được.

**Luật cứng theo loại:**

- **`scale` không được sửa `f.k`.** Thêm keyword là đổi luật (và có thể vi phạm Direction Law
  §3.5) → phải là `rule` (hoặc `rule-narrow` nếu ở COMMON).
- **`rule` không được mang multiplier toàn cục.** `dmgMult`, `critMult`, `thornsMult`,
  `burnMult` chỉ hợp lệ ở rarity 3, và tính vào `mload` (§3.6).
- **`engine` không được vừa cấp tài nguyên vừa nhân nó lên.** `startSummon` + `hiveMind` trên
  cùng một relic là lỗi thiết kế đã có thật (`r_hivemind` hiện tại) — nó biến một relic thành
  hai và làm ngân sách gấp đôi trần.
- **`pact` chỉ có ở LEGENDARY**, và drawback phải là *vĩnh viễn trong run*, không phải "mất
  lượt này". Drawback tạm thời không phải rủi ro, chỉ là độ trễ.

### 3.2 Rarity contract — mỗi bậc được phép làm gì

| Rarity | Tên | Được làm | **Cấm** | Ngân sách RP (§4) | `mload` tối đa |
|---|---|---|---|---|---|
| 0 | COMMON | Một trục số duy nhất (`scale`), **hoặc** một `rule-narrow` (§3.1 ghi chú ²). Đọc xong hiểu ngay, không cần suy luận. | Hook nào cũng cấm (`onHit`/`onKill`/`onShield`/`modDmg`) · keyword kwPure · bất kỳ multiplier | **13** ±20% | 0 |
| 1 | RARE | Một luật nhỏ, phạm vi hẹp (một slot part, hoặc một status) | Multiplier toàn cục · nhiều luật cùng lúc | **18** ±20% | 1 |
| 2 | EPIC | Một luật lớn, phạm vi toàn party. Đây là bậc "bật engine". | Multiplier toàn cục (≥1.3× trên mọi damage) | **26** ±20% | 1 |
| 3 | LEGENDARY | Multiplier toàn cục · phá 1 luật cân bằng · `pact` | Nhiều multiplier trên một relic | **37** ±20% | 2 |

**Vì sao 4 con số 13/18/26/37**: chúng là `SIG_BUDGET` của `part-skill-identity.md` §F7
(`6.0 / 8.5 / 12.0 / 17.0`, tỷ lệ `1.000 / 1.417 / 2.000 / 2.833`) nhân với anchor COMMON
= 13 RP. Anchor 13 không phải số chọn tay: nó là RP đo được của `r_claw` (Razor Claw, "mọi
mặt damage +1") — relic COMMON lâu đời nhất và là thứ duy nhất trong bậc COMMON hiện tại mà
mọi người đồng ý là "vừa đúng". Xem §4.3 ví dụ 1.

MYTHIC (rarity 4) **không tồn tại cho relic**. `relicPool()` cap ở 3 và `RARITY[4]` chỉ dùng
cho mặt xúc xắc; `chaos`/`curse` reward hiển thị `rar:4` nhưng đó là nhãn *của deal*, không
phải rarity của relic bên trong. Doc này giữ nguyên quy ước đó.

### 3.3 `ARCH` lên 11 — thêm `exec`

`PASSIVE.beast.a === 'exec'` nhưng `ARCH` không có key `exec`. Hệ quả đo được: Beast là class
duy nhất mà `archScore()` (`engine.js:885`) cộng vào một key không tồn tại — `sc[a]!=null`
false → **Beast góp 0 điểm cho mọi archetype**, còn 2 relic `r_deathmark`/`r_bloodpact` hiển
thị em-dash ở `ui.js:2505`/`:2722`.

**Fix:** thêm vào `ARCH` (`src/data.js:38`), giữ nguyên 10 entry cũ:

```js
exec: {n:'FERAL', ic:'✖', c:'#ff6b5f', d:'Wound them, then delete them. Every kill feeds the next.'},
```

| Trường | Giá trị | Lý do |
|---|---|---|
| `n` | `FERAL` | Trùng tên `PASSIVE.beast.n` → Beast lần đầu có archetype mang đúng tên passive của mình. Tiền lệ: `plant`/`BULWARK` và `bird`/`TALON` đã trùng tên; `bug`/`reptile` thì không. |
| `ic` | `✖` | Không trùng 10 icon đang dùng (`☠ ♨ ⛨ ↯ ➤ ✦ ⇗ ✥ ✷ ✷`). Lưu ý `aoe` và `thorns` **đang trùng icon `✷`** — xem §11 mục 4. |
| `c` | `#ff6b5f` | Không trùng semantic gameplay color; đủ xa `#ffc857` (r3) và `#ff5f8f` (r4). Cần `art-director` xác nhận contrast. |

Sau fix: `Object.keys(ARCH).length === 11`, và mọi `PASSIVE[cls].a` đều có entry
(`shield exec mana thorns poison pierce` ⊂ `ARCH`). Đây là AC-1.

### 3.4 `faceArch()` — bảng ưu tiên tường minh

Hiện tại `faceArch()` (`engine.js:755`) là một if-chain 9 nhánh, và thứ tự của nó là một
**luật precedence không được viết ở đâu cả**: `poison` trước `crit` nên mặt poison+crit không
bao giờ đọc là crit; `shield` trước `crit` cũng vậy. Ngoài ra nó **không bao giờ trả `thorns`
hay `exec`**, nên AEGIS là archetype không mặt nào nuôi được, và Reptile không nuôi nổi chính
archetype của mình qua mặt.

**Luật mới — `ARCH_PRIORITY`, khớp đầu tiên thắng, không có nhánh nào ngầm:**

| # | Điều kiện | Trả về | Vì sao ở vị trí này |
|---|---|---|---|
| 1 | `f.t === 'summon'` | `summon` | Type độc quyền, không keyword nào chia sẻ. Không thể nhầm. |
| 2 | `f.t === 'poison' \|\| hasKw(f,'poison')` | `poison` | Poison là **bậc hai** (§4.2). Tín hiệu build mạnh nhất trong game — mọi mặt có poison là mặt PLAGUE trước đã. |
| 3 | `hasKw(f,'thorns')` | `thorns` | **Thorns không bao giờ giảm** (`addStatus` cộng dồn, `tickStatus` không giảm — `part-skill-identity.md` E10). Một mặt mang `thorns:N` là accumulator vĩnh viễn, tín hiệu mạnh hơn shield. **Đây là fix cho defect 3.** |
| 4 | `hasKw(f,'burn')` | `burn` | Burn cần mật độ mới hoạt động (halve mỗi lượt) → phải được đếm ở mọi mặt có nó. |
| 5 | `hasKw(f,'exec')` | `exec` | **Mới.** `exec` là keyword đắt nhất sau `pierce`/`cleave` (cost 2.00, §F4) và cộng dồn ×1.6 với FERAL. |
| 6 | `hasKw(f,'crit')` | `crit` | Sau `exec` vì `exec` là điều kiện, `crit` là xác suất — điều kiện đọc được, xác suất thì không. |
| 7 | `hasKw(f,'growth')` | `growth` | |
| 8 | `hasKw(f,'pierce')` | `pierce` | |
| 9 | `f.t === 'mana' \|\| hasKw(f,'mana')` | `mana` | Type-based, xuống dưới keyword-based. |
| 10 | `f.t === 'shield'` | `shield` | Sau `thorns` (#3) — có chủ ý. |
| 11 | `hasKw(f,'aoe') \|\| hasKw(f,'cleave')` | `aoe` | Cuối cùng: `aoe` là *phạm vi*, phụ thuộc mặt, không phải bản sắc. Mọi mặt AoE có bản sắc khác đã bị bắt ở trên. |
| 12 | — | `''` | `dmg`/`heal`/`debuff`/`buff` trơn không có archetype. Đúng: chúng là mặt trung tính. |

**Luật phát biểu bằng lời (để test đối chiếu):** *"Archetype của một mặt là archetype **hiếm
nhất và khó thay thế nhất** mà nó thuộc về. Keyword trước type; accumulator (poison/thorns)
trước burst; điều kiện (exec) trước xác suất (crit); phạm vi (aoe) cuối cùng."*

**Delta đo được trên `FACE_POOL` (55 mặt hiện tại) khi đổi sang bảng này:**

| Mặt | Trước | Sau | Ghi chú |
|---|---|---|---|
| `back shield 9 aoe thorns:3` (Indian Star, r2) | `shield` | **`thorns`** | AEGIS lần đầu có mặt nuôi |
| `back shield 15 aoe thorns:5` (Tri Spikes, r3) | `shield` | **`thorns`** | |
| `mouth dmg 9 exec` (Lam, r2) | `''` | **`exec`** | trước đây không nuôi archetype nào |
| `horn dmg 14 cleave exec` (Kestrel, r3) | `aoe` | **`exec`** | |
| `horn dmg 26 heavy vital exec` (Pocky, r4) | `''` | **`exec`** | |
| `bp_bulwark` (`back shield 22 aoe bastion thorns:6`) | `shield` | **`thorns`** | Xung đột với `BP_FACES.bp_bulwark.arch = 'shield'` — xem §11 mục 5 |
| 49 mặt còn lại | — | không đổi | |

`PART_VARIANT_MODS.shield[1]` thêm `thorns:1` (`data.js:185`) → mọi mặt shield biến thể B của
Axie import cũng trở thành mặt `thorns`. Đó là **cách Reptile nuôi archetype của mình qua mặt**
(cùng với `HEROES.reptile1/2.eyes = buff thorns:2/3`, vốn cũng chưa bao giờ được `faceArch`
đọc vì `buff` không có nhánh).

### 3.5 kwPure Direction Law — ràng buộc bắt buộc cho relic tiêm keyword

`doFace()` (`engine.js:487-489`) lọc `kwPure` rồi `addStatus()` lên **target của mặt đó**:

```
dmg / debuff          → addStatus(kwPure) lên ĐỊCH
shield / heal / buff  → addStatus(kwPure) lên ĐỒNG MINH
poison                → KHÔNG BAO GIỜ truyền kwPure  (nhánh :510-514 không gọi addStatus(kwPure))
mana / summon         → KHÔNG gọi addStatus → kwPure VÔ HIỆU
```

**Luật cho relic** (mọi relic dùng `modFace` để `f.k.push(...)` phải qua bảng này):

| Relic tiêm keyword vào mặt type… | Được tiêm | **Cấm tiêm** | Nếu vi phạm |
|---|---|---|---|
| `dmg`, `debuff` | `burn:N` `poison:N` `weaken:N` `vulnerable:N` `blind:N` `stun` `freeze` — và mọi keyword **ngoài** kwPure (`pierce` `cleave` `lifesteal` `growth` `exec` `vital` `multi` `chain` `crit` `aoe` `heavy` `rerollup` `mana:N`) | `thorns:N` `regen:N` `undying` `enrage` | **Buff địch.** `dmg+thorns:3` = mỗi lần bạn đánh, bạn tự ăn 3 damage. Không crash, không test nào hiện có bắt được. |
| `shield`, `heal`, `buff` | `thorns:N` `regen:N` `undying` + keyword ngoài kwPure | `burn:N` `poison:N` `weaken:N` `vulnerable:N` `blind:N` `stun` `freeze` | **Debuff đồng minh mình.** |
| `poison` | **chỉ** keyword ngoài kwPure (`aoe` `pierce` `multi:N`) | mọi kwPure | **Vô hiệu âm thầm** — nhánh poison không truyền `kwPure`. Tooltip nói có, engine không làm. |
| `mana`, `summon` | **chỉ** `cantrip` `mana:N` `rerollup` `growth` `decay` `selfharm:N` `vital` | mọi kwPure | Vô hiệu âm thầm. |

5 relic đang tiêm keyword — `r_pierceall` (`pierce`), `r_cleaveall` (`cleave`),
`r_bloodmouth` (`lifesteal`), `r_growthcore` (`growth`), `r_stormcall` (`cleave`) — **tất cả
đều tiêm keyword nằm ngoài kwPure**, nên hiện tại 5/5 an toàn. Doc này giữ đúng tính chất đó
và thêm 3 relic tiêm kwPure, tất cả **đúng hướng**:

- `r_barbscale` / `r_ironhide`: tiêm `thorns:N` vào mặt **`shield`** → lên đồng minh ✓
- `r_ember`: **không** dùng `modFace`, dùng `onHit` → `addStatus` lên `ctx.tgt` (địch) ✓

Ràng buộc này là AC-5, kiểm được bằng máy: với mọi relic có `modFace` sửa `f.k`, mô phỏng
`modFace` trên một unit giả có đủ 8 type mặt rồi assert không có cặp (type, keyword) nào
nằm trong ô "Cấm tiêm".

### 3.6 Anti-stacking — Multiplier Load (`mload`)

**Vấn đề đo được (defect 6):** `s.relics` không có trần, và các field multiplier compound
theo nhiều đường khác nhau:

| Field | Cách engine gộp | Compound? |
|---|---|---|
| `dmgMult` | `rmul_` — **nhân dồn** (`engine.js:319, 358`) | **Có, không trần** |
| `critMult` | `rmax` (`:321`) | Không — nhưng relic thứ 2 là *dead draw* |
| `thornsMult` | `rmax` (`:341`) | Không — dead draw |
| `burnMult` | `rmax` (`:652`) | Không — dead draw |
| `poisonTicks` | `rmax` (`:641`) | Không — dead draw |
| `critBonus` | `rsum` — **cộng dồn** (`:247`) | Có, và bão hoà ở 100% |
| `piercePlus` | `rsum` (`:318`) | Có |
| `dr` | `rsum` (`:325`) | Có, và **tiến tới bất tử** ở tổng ≥1.0 |
| `hiveMind` | `rsum` × số token (`:411`) | Có, **nhân với số token** |
| `modFace` `f.v *= k` | tuần tự → **nhân dồn** | **Có** |

Ba trong số này (`dmgMult`, `modFace ×k`, `dr`) là compounding thật sự không trần. `r_bloodpact`
(`dmgMult:1.6`) + `r_ancientgene` (`×1.4` mọi mặt) + `r_apexpredator` (`critMult:3`) hiện cho
**×1.6 × 1.4 × 1.5 = ×3.36** trên một đòn crit, trước cả `exec` (×1.6) và FERAL (×1.6).

**Luật: Multiplier Load.** Mỗi relic mang một số nguyên `mload ∈ {0,1,2}`. Tổng `mload` của
những relic đang giữ **không được vượt `RELIC_MLOAD_CAP = 2`**.

```
mload(relic) =
  2  multiplier TOÀN CỤC — nhân MỌI output, không cần điều kiện nào:
        dmgMult · dr · modFace nhân f.v trên toàn die
  1  multiplier PHẠM VI ARCHETYPE — chỉ nhân khi build đã cam kết vào trục đó,
     bằng 0 nếu không có trục đó:
        critMult · critBonus · thornsMult · burnMult · burnSlow · burnSpread ·
        poisonTicks · plague · poisonSpread · piercePlus · hiveMind
  0  mọi trường hợp khác (cộng phẳng, thêm keyword, engine-starter, active)
```

**Vì sao `critMult`/`burnMult`/`thornsMult`/`poisonTicks` là 1 chứ không phải 2** — đây là chỗ
dễ sai nhất và làm sai thì luật anti-stacking sẽ phản tác dụng: chúng nhân *một tập con có
điều kiện* (chỉ các đòn crit / chỉ tick burn / chỉ đòn thorns / chỉ tick poison) và **bằng
đúng 0 nếu build không có trục đó**. Nếu xếp chúng mload 2 thì cặp kinh điển
`critBonus + critMult` = 4 > cap và luật sẽ **cấm chính build APEX** — archetype đang yếu nhất
theo sim (10% winrate). Xem §4.5 ví dụ 6.

Thi hành ở **điểm phát**, không ở điểm tính: `relicPool()` loại bỏ mọi relic mà
`mloadHeld(s) + r.mload > 2`. Người chơi vì thế **không bao giờ được đề nghị** một relic họ
không thể dùng an toàn — không có UI mới, không có màn "chọn bỏ relic nào", và không phá
determinism (pool là hàm thuần của `s.relics`).

**Hệ quả thiết kế, phát biểu tường minh:** bạn được chọn **một** multiplier toàn cục
(mload 2, dùng hết trần) **hoặc hai** multiplier phạm vi archetype (2 × mload 1). Bạn không
bao giờ có `Blood Pact` + `Apex Predator` + `Ancient Gene` cùng lúc. Đó là mất mát có ý thức:
nó đổi "run may mắn thắng dễ vô lý" lấy "trần sức mạnh nhìn thấy được".

**Trần thứ hai, dự phòng: `RELIC_CAP = 10`.** Khi `s.relics.length >= 10`, `mkReward(t='relic')`
và `mkReward(t='chaos')` trả `null`. `genRewards()` đã có vòng `while(out.length<n && g++<80)`
bỏ qua `null` và fallback sang `'hp'` (`engine.js:701-706`), nên không cần code mới ngoài
một điều kiện. Cap 10 gần như không bao giờ chạm ở Short Run (12 wave ≈ 11 reward, relic là
2/9 token) và chạm ở khoảng wave 16-20 của Full Run — đúng chỗ cần một cái thắng.

### 3.7 De-duplication — `ex` token

**Vấn đề đo được (defect 7):** ba cặp relic/keyword mà engine gộp bằng `||` hoặc `Math.max`,
nên cái thứ hai đóng góp **đúng 0**:

| Cặp | Điểm gộp | Mức trùng |
|---|---|---|
| `r_manaflood` (`manaOverflow`) ↔ keyword `overflow` | `engine.js:618` — `rhas(manaOverflow) \|\| party có mặt overflow` | **100% dead** |
| `r_plaguelord` (`plague`) ↔ keyword `plague` | `:648` — `plague \|\| mặt có plague \|\| party có mặt plague` | **100% dead** |
| `r_echostone` (`firstEcho`) ↔ keyword `echo` | `:468` — `reps = Math.max(reps, 2)` | **Dead khi mặt echo được dùng đầu lượt** |
| `r_spines`/`r_barbscale`/`r_ironhide` (thorns floor) | `:376` — `Math.max(u.st.thorns, N)` | **Dead với cái N nhỏ hơn** |
| Mọi cặp cùng field `rmax` (`critMult`, `thornsMult`, `burnMult`, `poisonTicks`) | `:24` | **Dead với cái nhỏ hơn** |

`r_bastionplate` (`onShield` splash 0.6) ↔ keyword `bastion` (splash 1.0) **không** thuộc danh
sách này: chúng cộng dồn (160% shield → damage), là stacking có giá, không phải dead draw.
Được giữ nguyên và có giá ở §4.

**Luật: `ex` token.** Mỗi relic mang `ex: [tokens]`. Một relic **không được đề nghị** nếu bất
kỳ token của nó đã được sở hữu, từ **một trong hai nguồn**:

1. Relic khác đang giữ (`s.relics`), hoặc
2. **Một keyword đang có trên mặt nào đó của party** — bảng `KW_EX`:

```
KW_EX = { overflow:'overflow', plague:'plague', echo:'echoRule', bastion:null }
```

`bastion: null` là có ý thức: nó cộng dồn, không trùng.

Kiểm tra keyword phải chạy trên `buildUnit(re, s)` của cả roster (mặt sau mutation), **không**
trên `HEROES[key].die`, vì mặt Mythic đến từ `muts`. `relicPool()` được gọi ở 6 chỗ
(`genRewards`, `mkReward` ×2, `applyEventFx` ×3, `genShop`) → chỉ cần một hàm `relicConflict(s,r)`.

`ex` token đầy đủ được liệt kê ở §6 theo từng relic. Nguyên tắc đặt token: **một token cho
mỗi *luật*, không cho mỗi field.** Ví dụ `thornsFloor` dùng chung cho mọi relic đặt sàn Thorns
bằng `Math.max`, dù chúng khác giá trị N.

#### 3.7a `exSub` — dead-draw BẤT ĐỐI XỨNG (phán quyết D2 của roster §17.5)

Roster §17.5 **D2** để ngỏ: `ex` đối xứng, nhưng LEGENDARY dạng "mọi mặt `dmg` nhận X" tạo
dead-draw **một chiều**. Mục này phán quyết D2, và con số bên dưới là **đo bằng máy trên tập mặt
thật**, không phải suy từ bảng type.

**Phép đo.** Chạy `modFace`/`modFace2` của cả 94 relic trên **68 mặt phân biệt** `(slot, type, kw)`
lấy từ 18 hero `HEROES` + `FACE_POOL`, rồi so *tập mặt* nhận cùng một keyword. Kết quả: **4 cặp
dead-draw đang sống trong build** — doc trước đó dự đoán 0.

| # | Quan hệ | Cặp | Tập mặt |
|---|---|---|---|
| 1 | **TRÙNG KHÍT** | `r_spines` ↔ `r_scalecrown` — cả hai đặt `st.thorns = Math.max(…, 2)` | cùng luật, cùng N |
| 2 | **TẬP CON** | `r_pierceall` ⊂ `r_worldpiercer` (`pierce`) | 9 ⊂ 29 |
| 3 | **TẬP CON** | `r_gorehook` ⊂ `r_apexferal` (`exec`) | 17 ⊂ 31 |
| 4 | **TẬP CON** | `r_windlash` ⊂ `r_stormcall` (`cleave`) | 15 ⊂ 26 |

> 🔒 **Vì sao cặp `pierce` bị bỏ sót, và đây là bài học dùng lại được.** Đọc theo *hệ type*,
> `r_pierceall` (mọi mặt `horn`) và `r_worldpiercer` (mọi mặt `dmg`) là **độc lập**: `horn ∧ shield`
> thuộc cái đầu, `mouth ∧ dmg` thuộc cái sau. Nhưng `horn ∧ shield` **không tồn tại**: đo trên mặt
> thật, `horn` chỉ mang `dmg` (§4.4b), nên "mọi mặt horn" nằm **trọn** trong "mọi mặt dmg". Hai
> token khác nhau (`pierceInject` vs `pierceInjectAll`) vì thế dựa trên một tính độc lập **lý
> thuyết, không có thật**. ⇒ **Luật chung: mọi kiểm quan hệ giữa relic tiêm keyword phải chạy trên
> tập mặt SHIP, không trên tích Descartes slot × type.** Một probe tổng hợp đủ 6 slot × 8 type sẽ
> báo *false negative* ở đây.

**Vì sao KHÔNG dùng `ex` đối xứng cho cặp 2-4 — đây là chỗ bản vá hiển nhiên làm hỏng game.**
`ex` đối xứng chặn **cả hai chiều**: giữ `r_gorehook` (COMMON, 11.88 RP, entry-point của FERAL)
sẽ **cấm `r_apexferal` (LEGENDARY) xuất hiện**. Một món nhặt sớm rẻ tiền xoá mất phần thưởng cuối
build — đảo ngược chính đường tiến bộ mà §3.12 tồn tại để bảo vệ. Đừng "đơn giản hoá" mục này
thành một token chung.

**Luật: `exSub: [tokens]`.** Đọc là *"đừng đề nghị tôi nếu một superset đã được giữ"*.

```
relicConflict(s, r) = true  nếu  ∃ t ∈ r.ex     : t đã sở hữu (relic khác HOẶC KW_EX)   ← đối xứng
                    ∨  ∃ t ∈ r.exSub  : t ∈ ex của một relic ĐANG GIỮ                    ← MỘT CHIỀU
```

Superset **vẫn được đề nghị** khi đang giữ subset (nó là nâng cấp thật). Cặp 1 **trùng khít**, không
có chiều nâng cấp, nên vẫn dùng `ex` đối xứng (`thornsFloorFlat`) — đúng như D1 đã duyệt.

⚠️ **Giới hạn `exSub` KHÔNG sửa, nói ra để khỏi bị tưởng là đã xong.** Nếu người chơi lấy **subset
trước** rồi lấy superset sau, subset vẫn thành 0 **hồi tố**. Chặn điều đó cần cơ chế hoàn trả
(refund/xoá relic) — là **content thật**, không phải một luật pool. `exSub` mua đúng nửa có giá trị
hơn: game **không bao giờ đề nghị** một relic đã chết sẵn. Nửa còn lại là nợ đã ghi, không phải nợ
bị giấu.

**Token một chủ sở hữu là HỢP LỆ — đừng dọn.** Đo trên bản ship: 36 token, **35 có đúng một chủ**.
Suy ra "một chủ ⇒ token vô nghĩa ⇒ xoá" là **sai**, vì ba lý do độc lập:

1. **`KW_EX` là đường bắn thứ hai.** §3.7 cho token kích hoạt từ **keyword trên mặt party**, không
   chỉ từ relic khác. `echoRule`, `overflow`, `plague` vì vậy **đang sống hôm nay** với đúng một
   chủ relic.
2. **Có cặp token được thiết kế để KHÔNG va nhau.** `poisonAmpFlat` (`r_rotbite`) và `poisonAmpPct`
   (`r_openwound`) tách *cố ý* — hai luật khác nhau cùng tồn tại được — đồng thời ép relic amp thứ
   ba phải chọn phe. Gộp hoặc xoá chúng là tái tạo lại đúng lỗi mà chúng ngăn.
3. **Có token giữ chỗ có chủ đích.** `undyingGrant` (`r_lastwall`) — relic thứ hai cấp `undying`
   sẽ trùng luật 100%; token đặt trước để lúc đó không ai phải nhớ ra.

Kiểm bằng máy thay cho rà tay: nhóm relic theo **luật thật sự cấp** (field engine gộp bằng
`rmax`/`||` · sàn `st.X = Math.max(…)` **trong thân hook** · tập mặt nhận keyword đo bằng thực thi),
rồi đối chiếu với token. Cặp 1 chỉ lộ ra ở tín hiệu thứ hai — nó là **hành vi trong thân hook**,
không phải field khai báo, nên mọi kiểm dựa trên khai báo đều mù với nó. Đây là AC-19 mở rộng.

### 3.8 Vòng đời & xác định (determinism)

| Thời điểm | Cái gì chạy | Ghi chú replay |
|---|---|---|
| `buildUnit()` mỗi đầu trận | `modFace(u)` theo **thứ tự `s.relics`** | Thứ tự có ý nghĩa với multiplier (`f.v*1.25` rồi `+1` ≠ `+1` rồi `*1.25`). `s.relics` là mảng có thứ tự nhận → tất định ✓ |
| `startCombat()` | `rsum('startSummon')` → `mkAlly` ×N, rồi `rcall('onTurnStart')`, rồi `rollAll` | `mkAlly` dùng `scaleDie` (không RNG) nhưng `rollUnit` dùng `ri(6)` → **nằm trong seeded RNG** ✓ |
| `rollAll()` | `rcall('onRollEnd')` — hiện **không relic nào dùng** | Giữ hook, không dùng ở v1 |
| mỗi `execFace` | `firstEcho`, `modDmg`, `dmgMult`, `critMult`, `piercePlus`, `onHit`, `onShield`, `onKill` | `onKill.explode` dùng `dealDamage(null, …)` → không RNG ✓. `onShield.splash` dùng `pick(es)` → **có RNG, nằm trong seed** ✓ |
| `endTurn()` | `manaOverflow`, rồi `tickStatus` (`poisonTicks`, `plague`, `burnMult`, `burnSlow`, `burnSpread`), rồi `rcall('onTurnStart')` | `burnSpread` đọc `aliveE(s)` theo index → tất định ✓ |
| `doReroll()` | `safeReroll` quyết định có xoá `s.undo` | |

**Không relic nào được phép**: đọc `Date`/`performance`, gọi `Math.random` (phải là `rnd()`),
đọc DOM, hoặc phụ thuộc thứ tự lặp của object. Cả 52 relic ở §6 tuân thủ. Đây là AC-8.

### 3.9 Relic phải phát event

`fx.js` replay `s.ev` để animate. **Một relic không phát event là đúng số nhưng vô hình.**
Kiểm kê 52 relic theo khả năng nhìn thấy:

| Nhóm | Ví dụ | Trạng thái event |
|---|---|---|
| **Tự phát qua pipeline** | `onKill.explode`, `onShield.splash`, `onHit.addStatus`, `poisonTicks`, `burnSpread`, `healShield`, `startSummon` | ✓ Đã có (`hit`/`hp`/`death`/`ft` từ `dealDamage`/`applyShield`/`addStatus`) |
| **Số bị gộp im lặng** | `dmgMult`, `modDmg`, `critMult`, `piercePlus`, `hiveMind`, `dr`, `thornsMult`, `burnMult` | ⚠ Con số trong event `hit` đã đúng, nhưng **không quy được cho relic nào**. Người chơi thấy "-31" mà không biết 12 trong đó do relic. |
| **Hoàn toàn vô hình** | `plague` (không giảm stack), `noShieldCap`, `safeReroll`, `firstEcho`, `modFace` | ✗ Không event nào |

→ **Cần một event type mới `relic`** (§10 mục E1). Đây không phải tuỳ chọn: 14 relic hiện
không có cách nào để `fx.js` biết chúng vừa hoạt động.

### 3.10 Nourishment Contract — luật gốc giải thích defect 1

Đây là phần "thiếu logic" thật sự, sâu hơn cả việc đếm relic lệch. `archScore()`
(`engine.js:880-889`) nuôi archetype từ **đúng ba nguồn**: relic đang giữ (`r.a`), class
passive của roster (`PASSIVE[cls].a`), và mặt mutation (`faceArch(m.face)`). Kiểm kê ba nguồn
đó cho 11 archetype, đối chiếu với playrate đo thật (`tools/sim.js`, 300 run, SHORT, asc 0):

| archetype | class passive | mặt (`faceArch`) | relic | playrate đo | winrate đo |
|---|---|---|---|---|---|
| poison PLAGUE | bug ✓ | ✓ | 5 | **30%** | 16% |
| shield BULWARK | plant ✓ | ✓ | 6 | 20% | 31% |
| mana CONDUIT | aqua ✓ | ✓ | 7 | 12% | 29% |
| crit APEX | **✗** | ✓ | 4 | 10% | **10%** |
| burn INFERNO | **✗** | ✓ | 4 | 10% | **10%** |
| aoe TEMPEST | **✗** | ✓ | 4 | 7% | 18% |
| pierce TALON | bird ✓ | ✓ | **2** | 5% | 14% |
| summon SWARM | **✗** | ✓ | **2** | 4% | 33% |
| growth EVOLVE | **✗** | ✓ | **2** | 1.7% | 20% |
| thorns AEGIS | reptile ✓ | **✗** | **2** | 1.3% | 25% |
| exec FERAL | beast ✓ | **✗** | 2 (chip lỗi) | **không đo được** | — |

Ba kết luận, tất cả đối chiếu được với số:

1. **Số relic điều khiển ACCESS, không điều khiển POWER.** Bốn archetype có 2 relic là đúng
   bốn archetype ít được chơi nhất — nhưng SWARM (33%) và AEGIS (25%) có winrate **trên
   baseline 20%**. Chúng *không tới được*, không phải *yếu*. Suy ra: fix phủ relic là fix đúng
   một vấn đề đo được, nhưng **không được coi "thêm relic" = "buff archetype"**, và relic mới
   cho SWARM/AEGIS phải nằm ở **cạnh dưới** dải ngân sách (§4.6 `bias`).
2. **Class passive là điều kiện gần-như-cần cho playrate cao.** Ba archetype được chơi nhiều
   nhất (poison 30%, shield 20%, mana 12%) đều có class engine. Năm archetype **không có class
   nào** (crit, burn, aoe, summon, growth) cộng lại chỉ 32.7% playrate. Nhưng nó không đủ:
   TALON có Bird mà chỉ 5% (thiếu relic), AEGIS có Reptile mà chỉ 1.3% (thiếu **cả** relic
   **và** đường mặt — `faceArch` không bao giờ trả `thorns`).
3. **Playrate ≠ winrate, và CONDUIT là phản ví dụ cho chính defect 1.** CONDUIT có *nhiều
   relic nhất* (7) mà playrate chỉ 12%; PLAGUE có 5 mà chiếm 30% số run. Nên phân bố lệch là
   thật nhưng **không phải nguyên nhân duy nhất** — poison tự hút người chơi bằng scaling bậc
   hai của chính nó (§4.2), ở winrate 16%. Đó là một **mispricing**, xử lý ở §4.7.

**Luật (Nourishment Contract).** Một archetype được coi là *reachable* khi và chỉ khi:

```
(a) tồn tại ≥1 đường faceArch trả về nó                             — cấu trúc
(b) có ≥6 relic phủ đủ 4 bậc rarity (≥1 C, ≥2 R, ≥2 E, ≥1 L)        — access
(c) có class passive trong PASSIVE  HOẶC  ≥1 relic COMMON là
    "entry-point" — relic cấp thẳng luật cốt lõi của archetype       — engine khởi động
(d) có ≥1 active card mang tag của nó                                — bề mặt Mana
```

(a) được (§3.4) đảm bảo cho cả 11. (c) là lý do mục tiêu "≥1 COMMON mỗi archetype" ở §5
**không phải quota tuỳ ý**: năm archetype không có class engine bắt buộc phải mua được engine
đó bằng một relic COMMON, nếu không chúng chỉ khởi động khi may mắn draw đúng mặt. (d) là lý
do actives không được dồn hết vào `mana` (§5.3).

### 3.11 Phạm vi doc này vs. `relic-roster-expansion.md`

Doc này sở hữu **framework**; `design/gdd/relic-roster-expansion.md` (game-designer, song song)
sở hữu **entry relic mới**.

| Thuộc doc này | Thuộc `relic-roster-expansion.md` |
|---|---|
| Taxonomy (§3.1), rarity contract (§3.2) | Mọi relic **mới** (id `r_*`/`a_*` chưa tồn tại) |
| Fix `ARCH`/`faceArch`/`exec`/`thorns` (§3.3-3.4) | Chọn tên, flavour, art hint |
| Direction Law (§3.5), `mload` (§3.6), `ex` (§3.7) | Gán `cat`/`mload`/`ex`/`κ` cho relic mới **theo luật §3.1/§3.6/§3.7** |
| Mô hình ngân sách RP/VPM (§4) | Số cụ thể của relic mới, phải nằm trong dải §4.6 |
| Mục tiêu phủ archetype (§5) | Danh sách đạt mục tiêu đó |
| **Retune/retag 44 relic đang có, id giữ nguyên** (§6) | — |
| Migration `META.relics` (§7, §11) | — |
| Tuning knobs (§9), Engine work (§10), AC (§12) | — |

AC ở §12 nghiệm thu **roster hợp nhất** (44 cũ + expansion), không nghiệm thu riêng doc nào.

### 3.12 Bất biến đơn điệu theo bậc — TIER MONOTONICITY

> **Yêu cầu của product owner (2026-09-03, nguyên văn):** *"đảm bảo rằng game design agent tinh
> chỉnh, cân đối để đảm bảo sự balance của từng các buff… có tình trạng buff tier dưới mạnh hơn
> tier trên."*

Phần này biến yêu cầu đó thành một **bất biến kiểm được bằng máy**, và — quan trọng hơn — làm nó
**đúng do cấu trúc công thức**, không phải do designer soi từng dòng. Trước phần này, doc đã có
`RP_target(a,r)` với dung sai ±20%; nhưng dung sai ±20% quanh một tâm chỉ cách nhau 1.41× **vẫn
chồng lấn**: `13 × 1.2 = 15.6 > 18 × 0.8 = 14.4`. Nghĩa là một COMMON đỉnh dải vẫn mạnh hơn một RARE
đáy dải, và khiếu nại của owner **tự tái sinh bên trong hệ mới**. Đó là lỗ hổng §3.12 đóng lại.

#### INV-1 — Đơn điệu nghiêm ngặt, TOÀN CỤC (không theo archetype)

```
Với mọi bậc r ∈ {0,1,2,3}, gọi Band[r] = [L_r, U_r] là dải RP tuyệt đối của bậc r.
INV-1:   U_r  <  L_{r+1}        ∀ r ∈ {0,1,2}
         và  ∀ relic x:  RP(x) ∈ Band[rar(x)]
⇒        ∀ x, y:  rar(x) < rar(y)  ⇒  RP(x) < RP(y)
```

| Ký hiệu | Kiểu | Miền | Nghĩa |
|---|---|---|---|
| `r` | int | {0,1,2,3} | bậc rarity (COMMON…LEGENDARY) |
| `L_r`, `U_r` | float | 11.22 – 42.98 RP | cận dưới / cận trên **tuyệt đối** của bậc `r` |
| `RP(x)` | float | 11.22 – 42.98 | giá trị RP đo được của relic `x` (§4.4) |
| `rar(x)` | int | {0,1,2,3} | bậc của relic `x` |

**Đầu ra bị chặn hai đầu**, có chủ đích: một relic không nằm trong dải nào **không hợp lệ** —
nó phải bị đổi số hoặc đổi bậc. Không có trạng thái "gần đúng".

**Chọn TOÀN CỤC, không phải theo archetype.** Đây là quyết định trung tâm và nó có giá.
Phương án theo-archetype (`U_r(a) < L_{r+1}(a)` cho từng `a`) yếu hơn và **không đáp ứng yêu cầu**:
với `bias ∈ [0.85, 1.15]`, một COMMON của APEX (`13.2 × 1.15 × 1.15 = 17.5`) vẫn vượt một RARE của
SWARM (`18.7 × 0.85 × 0.85 = 13.5`). Người chơi không đọc relic theo archetype — họ đọc **màu
rarity**. Nếu màu không nói được sức mạnh, chuỗi màu là một lời nói dối, và đó chính xác là điều
owner mô tả. Vì vậy `bias` **bị đẩy ra khỏi định nghĩa dải** (§4.6) thay vì bị bỏ.

#### INV-2 — Dải suy ra từ công thức, không đặt tay

```
C_r = ANCHOR × SIG[r] ,  ANCHOR = 13.2 ,  SIG = [1.0000, 1.4154, 2.0000, 2.8308]
Band[r] = [ C_r × (1 − τ) , C_r × (1 + τ) ] ,  τ = 0.15
```

Điều kiện đủ để INV-1 đúng **do số học**, không cần kiểm từng relic:

```
(1 + τ) / (1 − τ)  <  min_r ( C_{r+1} / C_r )  =  1.4130
⇔  τ  <  (1.4130 − 1) / (1.4130 + 1)  =  0.1712
```

`τ = 0.15` cho `1.15 / 0.85 = 1.3529 < 1.4130` ⇒ **biên an toàn 4.4%**. Bất kỳ ai sau này muốn
nới dung sai đều bị chặn bởi bất đẳng thức trên, không bởi ý kiến. Đó là điểm khác biệt so với
`±20%` cũ: `±20%` cho `1.5 > 1.4130` ⇒ **chồng lấn là chắc chắn**, không phải rủi ro.

`ANCHOR = 13.2` là **RP đo được của `r_claw`** (§4.5 ví dụ 1), không phải 13 làm tròn. Dùng số đo
thật thay số tròn là bắt buộc ở đây: nhiều cơ chế rơi đúng vào 15.0 RP ("+2 trên trục đã cam kết"),
và với anchor 13 thì `U_0 = 14.95` loại chúng vì lệch 0.3% — một biên giới do làm tròn đặt ra,
không do thiết kế.

#### INV-2b — Luật làm tròn cạnh dải: LÀM TRÒN VÀO TRONG, 2 chữ số

`C_1 = 13.2 × 1.4154 = 18.68328` và `C_3 = 13.2 × 2.8308 = 37.36656` không phải số 2 chữ số, nên
cạnh dải thô là `15.880788 / 21.485772 / 31.761576 / 42.971544`. In số làm tròn thông thường tạo
**bất đồng giữa spec và máy**: `15.88 < 15.880788` sẽ *nhận* những relic mô hình từ chối, và
`42.98 > 42.971544` cũng vậy. Đây đúng loại lỗi đã tạo ra `FACE_POOL.length === 63`.

```
INV-2b:  L_r = ceil( C_r × 0.85 × 100 ) / 100        (làm tròn LÊN)
         U_r = floor( C_r × 1.15 × 100 ) / 100       (làm tròn XUỐNG)
```

**Giá trị sau khi làm tròn vào trong là NORMATIVE** — `tools/t_relic.mjs` dùng đúng bảng dưới,
không tự tính lại từ `ANCHOR`. Làm tròn vào trong **không bao giờ** tạo chồng lấn: nó chỉ có thể
làm dải hẹp đi và vùng cấm rộng ra, nên INV-1 vẫn đúng a fortiori.

| bậc | `C_r` (chính xác) | `Band[r]` **normative** | rộng | vùng cấm phía trên |
|---|---|---|---|---|
| 0 COMMON | 13.20000 | **[11.22, 15.18]** | 1.353× | (15.18, 15.89) |
| 1 RARE | 18.68328 | **[15.89, 21.48]** | 1.352× | (21.48, 22.44) |
| 2 EPIC | 26.40000 | **[22.44, 30.36]** | 1.353× | (30.36, 31.77) |
| 3 LEGENDARY | 37.36656 | **[31.77, 42.97]** | 1.352× | — |

#### INV-3 — Vùng cấm (forbidden zone)

Ba khoảng `(U_r, L_{r+1})` là **vùng cấm**: không relic nào được có RP nằm trong đó. Phát biểu
thiết kế: *"không tồn tại relic ở giữa hai bậc."* Một relic rơi vào vùng cấm phải được đẩy vào
một trong hai bậc kề — bằng số, bằng rider (INV-6), hoặc bằng đổi `rar`. Vùng cấm rộng 4.4% dải
nên nó **không bao giờ nuốt một thiết kế hợp lý**; nó chỉ bắt những thiết kế đang lửng lơ phải
tự khai mình thuộc bậc nào.

#### INV-4 — Active và passive dùng CHUNG một thước

`relicPool()` rút active và passive **từ cùng một pool, cùng một bậc rarity**. Nên bất biến phải
áp cho hợp của cả hai tập, không cho từng tập. VPM (§4.3c) **không thể** diễn đạt INV-1: hai relic
cùng VPM nhưng khác `cost` có tổng đầu ra khác nhau hàng lần, vì active dùng lại **mỗi lượt**.
§4.4a định nghĩa `RP_act` trên đúng thang RP của passive; INV-1 kiểm trên `RP ∪ RP_act`.

#### INV-5 — Thứ tự `modFace` tất định và độc lập thứ tự nhặt

`buildUnit` (`src/engine.js:54`) chạy `for(const r of rlist(s)) if(r.modFace) r.modFace(u)`, và
`rlist = s => (s.relics||[]).map(id=>RELIC_BY_ID[id])` (`:21`) là **thứ tự nhặt**. Đây không phải
lỗi replay (cùng thứ tự nhặt ⇒ cùng kết quả) nhưng **nó phá INV-1 trực tiếp**: hai người chơi cùng
bộ relic có RP khác nhau, nên "RP của một relic" không còn là một hàm của relic. Bất biến RP chỉ
có nghĩa nếu RP là **hàm của tập relic**, không của dãy.

```
INV-5:  ∀ tập relic S, ∀ hai hoán vị π₁, π₂ của S:
        buildUnit(re, S theo π₁).die  ≡  buildUnit(re, S theo π₂).die
```

**Thứ tự tất định được định nghĩa như sau** (thay cho `rlist` order, xem §10 R2 và §11 mục 17):

```
mfPhase ∈ {'kw', 'add', 'mul'}    — field KHAI BÁO trên mỗi relic, không suy từ thân hàm
Thứ tự chạy modFace = sắp xếp ổn định theo khoá gộp:
    key(r) = [ PHASE_RANK[r.mfPhase] , r.rar , RELIC_INDEX[r.id] ]
    PHASE_RANK = { kw: 0, add: 1, mul: 2 }
    RELIC_INDEX[id] = chỉ số của id trong mảng RELICS (hằng, không phụ thuộc save)
```

Ba tầng khoá đều là hằng của dữ liệu, **không** chứa `s.relics`. Vì vậy kết quả độc lập tuyệt đối
với thứ tự nhặt, với thứ tự shop, và với `bet_big` (§7 E8). `mfPhase` mặc định `'add'` nếu thiếu.
Ba pha đúng thứ tự toán học: thêm keyword → cộng phẳng → nhân, nên `(v+1)×1.3` là kết quả duy nhất
và `v×1.3+1` không còn tồn tại. **Đây là thay đổi hành vi ⇒ nằm trong lần bump `ENGINE_VERSION`
duy nhất** (§10). Đây cũng là lời giải cho `ENG-0` mà `relic-roster-expansion.md` §16 để ngỏ, và
cho `r_thousandcuts` (vừa sửa `f.v` vừa thêm keyword): nó khai **hai** entry `modFace` — một
`mfPhase:'kw'` (thêm `multi`), một `mfPhase:'add'` (chia `v`) — thay vì một hàm chạy ở "cuối pha kw".

#### INV-6 — Luật cấu thành (Composition Rule)

Dải rộng 1.353× thay vì 2.03× nên **độ hạt** của cơ chế trở thành ràng buộc thật: nhiều bước tăng
nhỏ nhất (+1 shield = 5.48 RP, +1 stack poison = 22.5 RP) nhảy qua cả dải. Van xả là **rider** —
một cơ chế phụ nhỏ trên cùng relic — nhưng rider không được biến một relic thành hai:

```
INV-6:  số cơ chế tính RP trên một relic  ≤ 2 (rar 0-1)  |  ≤ 3 (rar 2-3)
        AND  max_i(RP_i) / RP_total  ≥  0.45
```

Cơ chế lớn nhất phải chiếm ≥45% RP ⇒ relic vẫn có **một** bản sắc đọc được. Đây không phải nới
lỏng luật taxonomy §3.1: rider vẫn phải hợp lệ theo `cat` và theo Direction Law §3.5.

#### INV-7 — Luật sàn phơi nhiễm (Exposure Floor Law)

Mọi relic gắn hiệu ứng vào một **vị từ trên mặt** phải định giá bằng phơi nhiễm của **đúng vị từ
đó**, đo trên bảng §4.4b — **không** bằng `p_slot` khi hiệu ứng chỉ dùng được trên một tập con
type của slot đó.

```
INV-7:  RP = Act × p(P) × ΔV × R × κ     với p(P) tra từ bảng §4.4b
        Nếu p(P) < 0.10 thì relic PHẢI có ΔV ≥ Band[r].L / (Act × p(P)) hoặc bị loại.
```

Đây là tổng quát hoá của §7 E1 (`r_voidgene` = 0 RP vì mặt `blank` không tồn tại). Ba nạn nhân đo
được của INV-7 nằm ngay trong doc này trước bản sửa: `r_cleaveall` tiêm `cleave` vào slot `tail`
(`p_slot = 0.111` nhưng `p(tail ∧ dmg) = 0.028` — `cleave` **không làm gì** trên mặt `poison`),
`r_wildfire` tiêm `burn:3` cũng vào `tail ∧ dmg`, và `r_voidgene` tiêm `rerollup` vào mặt `mana`.
Cả ba từng được định giá ở `p_slot` và **cao gấp 3-4 lần giá trị thật**.

#### INV-8 — `bias` không được đẩy relic ra khỏi dải

Xem §4.6. `bias(a)` chuyển từ **hệ số nhân dải** thành **vị trí đích trong dải**, với biên độ
`τ_aim = 0.10 < τ = 0.15`. Nhờ vậy mọi `RP_target(a,r)` nằm **hoàn toàn bên trong** `Band[r]` với
mọi `a`, và INV-1 không phụ thuộc vào `bias` — kể cả khi `bias` được đo lại sau mỗi lần ship (K7).

## 4. Formulas

### 4.0 Đơn vị và hằng số — mọi con số suy từ dữ liệu thật

**Đơn vị: RP (Relic Point). 1 RP ≡ 1 điểm damage gây ra cho địch trong một trận ở power-level
tham chiếu.** Chọn damage làm đơn vị neo để đồng nhất với `part-skill-identity.md` §F3, nơi
`R[dmg] = 1.00` là đơn vị neo của hệ mặt. Hai hệ vì thế dùng **cùng một thước**.

| Ký hiệu | Nghĩa | Giá trị | Nguồn (không phải phỏng đoán) |
|---|---|---|---|
| `pw*` | power-level tham chiếu | **8** | Trung điểm Short Run (12 wave ≈ 11 reward) |
| `Bgt` | encounter budget tại `pw*` | **32.1** | `CURVE.budget(8) = 10.5 × 1.15^8` |
| `Ω` | số lượt/trận | **5** | Đội 5 die × ~4 mặt hữu ích; sim: trận thường kết thúc lượt 4-6 |
| `n` | số die party | **5** | `roster` luôn 5 (`newGame`) |
| `Act` | số lần kích hoạt mặt/trận | **25** | `Ω × n` |
| `E` | số địch/trận | **4** | `CURVE.count(8) = max(2, min(5, 2+2)) = 4` |
| `D` | tổng damage party/trận | **70** | Xem kiểm chéo dưới |
| `T_in` | tổng damage party nhận/trận | **70** | Đối xứng với `D` ở winrate ~50%/wave |
| `H` | số đòn địch đánh vào party/trận (hiệu dụng) | **10** | `E × Ω × 0.67` (4/6 mặt địch là dmg) × 0.75 (địch chết dần) |
| `M_gen` / `M_com` | mana thu/trận, generic / CONDUIT | **4.2** / **30** | `Act × p_mana × v̄_mana`, xem §4.4 |

**Kiểm chéo `D = 70` bằng hai đường độc lập:**

```
Đường 1 (từ phía địch — bạn phải giết hết):  HP địch tổng ≈ 2.2 × Bgt = 70.6
Đường 2 (từ phía bạn — output mặt):          Act × p_dmg × v̄_dmg = 25 × 0.528 × 5.3 = 70.0
```

Hai đường lệch 0.9%. Đây là bằng chứng mô hình neo vào dữ liệu thật, không vào ý muốn designer
(cùng phương pháp `part-skill-identity.md` §F2 dùng để hiệu chuẩn `SlotMod`).

**`p_t` — tần suất type mặt, ĐO TỪ `HEROES` tier-1** (6 hero × 6 mặt = 36 mặt; tier-1 là
anchor đúng vì workstream part song song đang re-anchor giá trị mặt về sức mạnh hero tier-1):

| type | đếm/36 | `p_t` | | slot | đếm/36 | `p_slot` |
|---|---|---|---|---|---|---|
| `dmg` | 19 | **0.528** | | `mouth` | 10 | **0.278** |
| `shield` | 7 | **0.194** | | `horn` | 8 | **0.222** |
| `mana` | 4 | **0.111** | | `back` | 7 | **0.194** |
| `poison` | 3 | **0.083** | | `tail` | 4 | **0.111** |
| `heal` | 1 | **0.028** | | `ears` | 4 | **0.111** |
| `buff` | 1 | **0.028** | | `eyes` | 3 | **0.083** |
| `debuff` | 1 | **0.028** | | | | |

**`R_t` — role rate, COPY NGUYÊN từ `part-skill-identity.md` §F3.** Không suy lại, không sửa:

```
R = { dmg 1.00 · heal 1.00 · shield 0.86 · poison 1.55 · mana 2.25 · buff/debuff 2.60 · summon 4.20 }
```

`R` là "bao nhiêu điểm ngân sách cho 1 đơn vị output". Nên **1 điểm shield = 0.86 RP**,
**1 mana = 2.25 RP**, **1 egg-point = 4.20 RP**. Chi phí keyword `KW(k)` cũng copy nguyên
§F4 (`pierce` 2.30 · `cleave` 3.10 · `lifesteal` 1.50 · `exec` 2.00 · `growth` 0.00¹ · `aoe`
3.60 · `rerollup` 1.40 · `thorns:N` 0.70N · `burn:N` 0.55N · `crit:N` 0.045N · `vital` 1.00).

¹ §F4 không định giá `growth` riêng — §4.3 ví dụ 5 chứng minh vì sao: ở `Ω=5` giá trị thực
của `growth` gần 0.

### 4.1 Exposure — luật quan trọng nhất của mô hình

Một relic chỉ đáng giá bằng **số lần luật của nó có cơ hội bật**. Đây là chỗ mọi mô hình relic
nghiệp dư sai: định giá theo "nghe mạnh cỡ nào" thay vì theo tần suất.

```
p_eff(t, a) = max( p_t , P_COMMIT )        nếu t là trục của archetype a mà relic mang tag
            = p_t                          nếu không
P_COMMIT = 0.30
```

**`P_COMMIT = 0.30` suy ra, không chọn tay**: một build đã cam kết đưa được archetype của nó
lên ~3 trong 6 mặt của ~3 trong 5 Axie → `9/30 = 0.30`. Định giá ở exposure *đã cam kết* là
bắt buộc: nếu định giá ở exposure generic, mọi relic archetype sẽ đúng giá với người không
chơi archetype đó và **quá mạnh với người chơi nó** — tức đúng chế độ hỏng mà
`combo-decision-memo.md` §3 đã ghi nhận một lần (mono-class ăn cả hai trục).

**Ngoại lệ có đo:** hai trục sống trên đúng một slot nên không lên nổi 0.30 —
`burn` (chỉ `tail` trong `FACE_POOL`) và `growth` (chỉ 2 mặt trong pool). Với chúng
`P_COMMIT = 0.20`. Đây là một *phát hiện*, không phải miễn trừ: nó là một nửa lời giải thích
cho winrate 10% của INFERNO (§4.7).

**Trần cộng dồn class (thay cho việc mô hình hoá `CLS_SURCHARGE`).** Định giá dùng exposure
đã cam kết nhưng **thành phần class generic**. Bù lại, mọi relic phải qua thêm một kiểm:

```
RP_class(relic) ≤ 2.2 × RP_band[rarity]
```

`RP_class` = RP tính lại với class passive khớp nhất trong party. `2.2` là trần đo được, không
phải mong muốn: relic tiêm `pierce` với Bird TALON (+3 damage mỗi đòn pierce, `engine.js:318`)
đạt đúng ~2.05×, và đó là trường hợp cộng dồn class mạnh nhất tồn tại trong engine. Vượt 2.2
nghĩa là relic đó thực chất là hai relic — phải thu hẹp phạm vi.

### 4.2 `κ` — hệ số chiết khấu theo độ tin cậy

Hai hiệu ứng có cùng EV **không** đáng giá bằng nhau trong một roguelike có tường (sim: boss
cuối chỉ 37% pass, 101/300 run chết ở đó). Khi thất bại là "không vượt được một ngưỡng", phương
sai là chi phí, và độ trễ cũng là chi phí. Mô hình phải nói ra điều đó bằng số.

```
RP = raw_value × κ
```

| `κ` | Loại hiệu ứng | Giá trị | Lý do (có dòng code) |
|---|---|---|---|
| `κ_det` | Tất định, tức thời | **1.00** | Neo. `+v` phẳng, `dmgMult`, `piercePlus` |
| `κ_choice` | Có điều kiện nhưng **người chơi chọn** | **0.95** | `exec`/`modDmg` — bạn chọn target dưới 50% HP |
| `κ_def` | Cần bị đánh mới có giá | **0.85** | `shield` `dr` `thorns`: `applyShield` tạo giá trị chỉ khi có đòn tới; overshield mất trắng |
| `κ_psn` | Trễ, **tích luỹ** trên target bạn chọn | **0.90** | `tickStatus:645-650` — mất 1 lượt mới tick, nhưng stack cộng dồn |
| `κ_tok` | Cần một token còn sống | **0.70** | `hiveMind` đọc `party.filter(token && hp>0)` (`:411`); egg chết vì AoE |
| `κ_rng` | Bernoulli **engine quyết, không có agency** | **0.75** | `rollUnit:254` chốt `u.critNow` **lúc roll** — người chơi không đuổi được |
| `κ_dot` | Trễ **và suy giảm**, dễ mất trên target sắp chết | **0.60** | `tickStatus:658` halve mỗi lượt; địch chết trước khi tick → 0 |

`κ_rng = 0.75` và `κ_dot = 0.60` là hai con số duy nhất trong doc này *mới*, và chúng là
**cơ chế sửa giá cho APEX và INFERNO** (§4.7). Chúng nói: để lấp cùng một dải ngân sách, một
relic crit phải cho nhiều EV hơn 33% so với relic tất định, và một relic burn phải cho nhiều
hơn 67%. Đó chính xác là mức buff mà hai archetype 10%-winrate cần — và nó **suy ra từ luật
chung**, không phải một buff gán tay.

### 4.3 Ba cơ chế cần công thức riêng

**(a) Poison — P-model (bậc hai). Bắt buộc dùng, không dùng `R_poison` tuyến tính.**

`R_poison = 1.55` là giá **thiết kế mặt** (một mặt, một lần). Relic đổi poison *ở quy mô*,
nơi số hạng bậc hai chi phối, nên định giá relic phải mô phỏng tích luỹ thật:

```
PSN(v, a, Ω) : stack ← 0
               mỗi lượt j = 1..Ω:  stack ← stack + a·v ;  dmg_j ← stack ;  stack ← stack − 1
               PSN = Σ dmg_j
a = Act × p_eff(poison) / Ω    (số lần áp/lượt, dồn vào MỘT target — lối chơi đúng, xem GUIDES 'plague')
```

Với `p_eff = 0.30` → `a = 1.5/lượt`. `v` nền = 4 (mặt poison giữa run).
`PSN(4) = 6+11+16+21+26 = 80`. `PSN(5) = 7.5+14+20.5+27+33.5 = 102.5`. **Δ(+1 stack) = 22.5**.

So sánh với ước lượng tuyến tính `Act × 0.30 × 1 × 1.55 = 11.6`: P-model cho **gấp 1.94×**.
Đó là lý do defect 5 tồn tại — `r_fang` (+2 stack) được định giá như thể poison tuyến tính.

**(b) Thorns — accumulator không suy giảm.**

`addStatus` cộng dồn `thorns` (`:394-395`) và `tickStatus` **không có nhánh giảm thorns**.
Nên thorns là accumulator vĩnh viễn trong trận:

```
THORNS_floor(N) = H × N × κ_def                       (relic đặt sàn qua Math.max, onTurnStart)
THORNS_inject(N, p) = H × N × (Act × p / 2) / Ω × κ_def   (relic tiêm thorns:N vào mặt → tích dần)
THORNS_mult(m) = H × N_base × (m − 1) × κ_def ,  N_base(committed) = 4
```

`N_base = 4` đo từ build cam kết: SCALES 2 (Reptile, `startCombat:232`) + một relic sàn 2.

**(c) Active card — VPM, tính THEO LƯỢT.**

`s.usedActives = []` chạy ở `engine.js:633`, ngay sau `s.turn++`. Nên **mọi active dùng được
1 lần MỖI LƯỢT, mọi lượt, chặn duy nhất bởi mana** (`:564`). Bất kỳ định giá theo
"1 lần/trận" đều sai nghiêm trọng.

Vì tổng output của một active tỉ lệ thuận với thu nhập mana (thứ do thiết kế **mặt** quyết,
không do relic), bất biến đúng để định giá là **hiệu suất chuyển đổi**, không phải tổng:

```
VPM(active) = V_out × κ / cost
V_out = Σ output × R_t   (nhân số target: dmgall/poisonall × E=4 · shieldall × n=5)
```

`VPM = 2.25` là điểm hoà vốn (bằng đúng `R_mana` — không hơn gì việc để ngân sách đó lên mặt).
Active phải hơn hoà vốn (linh hoạt, chọn target, không tốn die) nhưng có trần:

```
VPM_band = { COMMON 3.5 · RARE 4.5 · EPIC 5.5 · LEGENDARY 7.0 }   ±20%
```

Tỉ lệ `1.00 / 1.29 / 1.57 / 2.00` — **cố tình phẳng hơn** dải passive (1.00/1.42/2.00/2.83):
tổng sức mạnh của active đã tự scale theo mana, nên nếu rarity cũng scale dốc thì Legendary
active sẽ áp đảo tuyệt đối. Đây là lý do `a_ult` (MP10) hiện đúng giá còn `a_plague` (MP4)
lệch +325%.

**Ràng buộc cứng cho active**: `act.kind` phải ∈ **8 giá trị đã implement**
(`engine.js:566-575`): `heal · dmg · ult · shieldall · dmgall · poisonall · stun · reroll`.
Không có nhánh `else` → **`kind` lạ vẫn trừ mana, vẫn tiêu slot của lượt, và không làm gì**.
`kind` mới = engine work (§10). Ba ghi chú nữa: `kind:'ult'` **hardcode `applyShield(…,10)`**
trong engine nên `act.v` chỉ điều khiển damage; `poisonall` **có** truyền source nên VIRULENT
+2 áp dụng; `dmg`/`dmgall`/`ult` đều truyền `attack:true` nên **ăn thorns địch và ăn crit**.

### 4.4 Bảng cơ chế → RP (tra là dùng được)

Mọi relic phải quy về một hoặc tổng vài dòng dưới đây. `Δv` = lượng cộng; `m` = multiplier.

| Cơ chế | Công thức RP | Giá trị số |
|---|---|---|
| `modFace` +Δv mọi mặt `dmg` | `Act × 0.528 × Δv × 1.00 × 1.00` | **13.2 · Δv** |
| `modFace` +Δv mọi mặt `shield` | `Act × 0.30 × Δv × 0.86 × 0.85` | **5.48 · Δv** |
| `modFace` +Δv mọi mặt `mana` | `Act × 0.30 × Δv × 2.25 × 1.00` | **16.9 · Δv** |
| `modFace` +Δv mọi mặt `heal` | `Act × 0.30 × Δv × 1.00 × 0.85` | **6.38 · Δv** |
| `modFace` tiêm keyword `k` vào slot `s` | `Act × p_slot × KW(k) × κ` | vd `pierce`→`horn`: `25×0.222×2.30 = 12.8` |
| `modFace` tiêm keyword `k` vào type `t` | `Act × p_eff(t) × KW(k) × κ` | vd `cleave`→`dmg`: `25×0.528×3.10 = 40.9` |
| `modFace` nhân `f.v × m` toàn die | `(D + Shd×0.86 + …) × (m−1)`; tổng output nền ≈ **120** | **120 · (m−1)** |
| `dmgMult: m` | `D × (m−1) × 1.00` | **70 · (m−1)** |
| `critBonus: c` (c = điểm %) | `D × (c/100) × (critMult−1) × κ_rng` | **0.525 · c** (ở `critMult`=2) |
| `critMult: m` | `D × p_crit_com × (m−2) × κ_rng`; `p_crit_com = 0.45` | **23.6 · (m−2)** |
| `piercePlus: k` | `Act × 0.30 × k × 1.00` + 5 (bỏ qua thorns) | **7.5 · k + 5** |
| `dr: x` | `T_in × x × κ_def` | **59.5 · x** |
| `modDmg` +x% có điều kiện, exposure `q` | `D × q × x × κ_choice` | vd +30%, q=0.85: **17.0** |
| `modDmg` +k phẳng có điều kiện, exposure `q` | `Act × p_dmg × q × k × κ_choice` | **13.2 × q × k × 0.95** |
| `onHit` áp `burn:N` mọi đòn | `(Act × p_dmg) × 2N × κ_dot` | **15.8 · N** |
| `onKill` explode `k` | `kills(3) × k × (E−1 còn lại ≈ 2) × 0.95` | **5.7 · k** |
| `onKill` +Δv mọi mặt dmg | `Δv × Σ(activation còn lại sau mỗi kill) = Δv × 15.8` | **15.8 · Δv** |
| `onShield` splash `m` | `Shd_com(45) × m × 1.00` | **45 · m** |
| `onTurnStart` sàn `regen: N` | `n × N × Ω × 1.00 × κ_def × 0.7`(overheal) | **10.4 · N** |
| `onTurnStart` sàn `thorns: N` | `H × N × κ_def` | **8.5 · N** |
| `startSummon: k` | `k × egg_RP`; `egg_RP = (2.7 đòn × 4.6 dmg + 7.6 hp × 0.86) × κ_tok` | **13.0 · k** |
| `hiveMind: k` | `Act × p_dmg × k × tokens_com(3) × κ_tok` | **27.7 · k** |
| `poisonTicks: 2` | `PSN(4) × 1 × κ_psn × 0.75`(overkill) | **54** |
| `plague` | `[PSN_nodecay(4) − PSN(4)] × κ_psn` | **13.5** |
| `poisonSpread` | `PSN(4) × 0.55 × κ_psn` | **39.6** |
| `burnMult: m` | `Burn_base(40) × (m−1) × κ_dot/κ_dot` | **40 · (m−1)** |
| `burnSlow` | `[Σ(N..1) − 2N] × apps(5) × κ_dot`, N=4 | **9.0** |
| `burnSpread` | `Burn_base(40) × 0.60 × κ_dot/κ_dot` | **24.0** |
| `healShield` | `Heal_com(25) × 0.86 × κ_def` | **18.3** |
| `noShieldCap` | rất ít khi chạm `maxHp×2` | **5.0** |
| `firstEcho` | `Ω × v̄_best_face(8.1)` | **40.5** |
| `manaOverflow` | `(mana dư 4/lượt × E) × Ω × 0.30`(chi phí cơ hội vs active) | **30.0** |
| `rerollUp: k` | `k × Ω × 1.40` | **7.0 · k** |
| `safeReroll` | giá trị thông tin, không định giá được → hằng | **8.0** |
| `+Δ maxHp` (mọi Axie) | `n × Δ × 0.86 × 0.35`(chỉ có giá khi sắp chết) | **1.5 · Δ** |
| `act` | **`RP_act`, §4.4a** — VPM một mình không diễn đạt được INV-1 | — |
| `weaken:N` / `vulnerable:N` / `blind:N` áp mỗi lần | `Act × p_eff × W(N)` ; `W(N) = 1.5N × κ_def = 1.275N` | **31.9 · N × p_eff** |
| `growthAll: N` (§10 G1) | `N × (Ω−1) × n × p_dmg` | **10.56 · N** |
| `growthPlus: N` (mỗi mặt `growth` tăng thêm N) | `15.7 × p_eff(growth) × N` | **3.14 · N** ở `p_eff = 0.20` |
| `thornsPlus: N` (cộng SAU khi nhân) | `H × N × κ_def` | **8.5 · N** |
| `burnTicks: m` | `Burn_base(40) × (m − 1) × ρ_tick` | **40 · (m−1) · ρ** |
| `+N Mana đầu mỗi lượt | `N × Ω × R_mana` | **11.25 · N** |
| `+N Mana đầu mỗi trận | `N × R_mana` | **2.25 · N** |
| `undying` sàn 1/lượt | `P(cứu)(0.6) × giá trị Axie còn lại(25) × κ_def` | **12.75** |

`W(N)`, `growthAll`, `growthPlus`, `thornsPlus`, `burnTicks` là **năm dòng mới**; ba dòng cuối là
hệ quả trực tiếp của `R_mana = 2.25`. `W(N) = 1.5N` vì `weaken` giảm 1 stack/lượt (`tickStatus`)
nên tổng damage chặn được ≈ `N + (N−1) + …` nhưng bị chặn bởi tần suất địch đánh (`H/Ω = 2`/lượt)
⇒ xấp xỉ `1.5N` trên một target. `KW(weaken:N)` **không** có trong `part-skill-identity.md` §F4 —
đây là bổ sung bắt buộc, phải được đồng bộ ngược về §F4 (§11 mục 18).

### 4.4a Active — `RP_act`, cùng thang với passive

`VPM` (§4.3c) đo **hiệu suất chuyển đổi mana**. Nó đúng cho việc so hai active với nhau ở cùng
`cost`, nhưng **không thể** diễn đạt INV-1, vì tổng đầu ra của một active còn phụ thuộc `cost`
(nó quyết định bao nhiêu mana thẻ đó *hút được*) và phụ thuộc **bão hoà** (đánh 200 shield vào một
trận chỉ có 70 damage vào là ném đi 130). Bỏ qua hai thứ đó là lý do §6.5 bản cũ kết luận
`a_ult` "+9%, đúng giá" trong khi nó thực chất **tự kết thúc trận**.

```
Θ(c)      = min( Ω , ⌊ M_com / c ⌋ )            số lần cast tối đa trong một trận
Value(N)  = Σ_i  min( N × V_i , Sat_i )         tổng giá trị N lần cast, chặn bởi nhu cầu trận
RP_act    = max_{N = 1..Θ(c)} [ Value(N) − N × VPM_0 × c ]
```

| Ký hiệu | Kiểu | Miền | Nghĩa |
|---|---|---|---|
| `c` | int | 1 – 20 | `act.cost` (mana) |
| `Ω` | int | 4 – 7 | số lượt/trận, = **5** (§4.0) |
| `M_com` | float | 4.2 – 30 | mana thu được/trận ở **exposure đã cam kết** = **30** (§4.0) |
| `V_i` | float | 0 – 80 | giá trị đầu ra thành phần `i` của **một** lần cast, `= output × R_t × κ` |
| `Sat_i` | float | 70 hoặc ∞ | nhu cầu tối đa của trận cho thành phần `i` |
| `VPM_0` | float | 2.25 | chi phí cơ hội của 1 mana = `R_mana` (điểm hoà vốn) |
| `N` | int | 1 – 5 | số lần cast người chơi chọn |
| `RP_act` | float | 11.22 – 42.98 | RP của active, **cùng thước với passive** |

`Sat_i`: thành phần sát thương → `Sat = D = 70` (tổng HP địch/trận); thành phần phòng ngự
(shield/heal) → `Sat = T_in = 70`; thành phần tiện ích (`reroll`, `stun`) →
`Sat = ∞` (không có "thừa"). `M_com = 30` là **exposure đã cam kết**, đúng nguyên tắc §4.1: một
active được định giá cho người chơi thật sự dùng được nó. Hệ quả phải nói ra: **active bị
under-power với build không đọc Mana**, và đó là lý do điều khoản (d) của Nourishment Contract
(§3.10) đòi mỗi archetype có ≥1 active để có *bề mặt tiêu*, **không** để có thêm sức mạnh.

**Ví dụ chạy đủ 1 — `a_wall` (RARE, `shieldall`, MP 6, 5 Shield cả party).**
```
V_def = n × 5 × R_shield × κ_def = 5 × 5 × 0.86 × 0.85 = 18.28 ;  Sat_def = 70 ;  Θ(6) = min(5, 5) = 5
N=1: 18.28 − 13.5 = 4.78 | N=2: 36.55 − 27.0 = 9.55 | N=3: 54.83 − 40.5 = 14.33
N=4: min(73.1,70) − 54.0 = 16.00 ←max | N=5: 70 − 67.5 = 2.50
RP_act = 16.00 ∈ Band[1] = [15.88, 21.48] ✓   đích BULWARK R = 16.81, lệch 0.81 ≤ 2.80 ✓
```
Lượt cast thứ 5 **âm giá trị** — mô hình tự nói ra rằng spam đến bão hoà là sai lầm, và đó là
thông tin thiết kế mà VPM không bao giờ cho được.

**Ví dụ chạy đủ 2 — `a_ult` là mispricing lớn nhất roster.**
```
Hiện tại (MP 10, 40 pierce + 10 Shield toàn party):
  V_dmg = 40 ; V_def = 5 × 10 × 0.86 × 0.85 = 36.55 ; Θ(10) = min(5, 3) = 3
  N=1: 76.55 − 22.5 = 54.05 | N=2: (70 + 70) − 45.0 = 95.00 ←max | N=3: 140 − 67.5 = 72.5
  RP_act = 95.00   vs   Band[3].U = 42.98      →  +121%  ✗✗✗
```
Hai lần cast a_ult **giết trọn encounter và hấp thụ trọn sát thương vào** — cho 20 trong 30 mana.
Kể cả ép về 1 lần/trận ở MP 10 thì vẫn là 54.05, tức vẫn ngoài dải. Chỉ **giá** mới sửa được:
`MP 18` ⇒ `Θ(18) = 1` ⇒ `RP_act = 76.55 − 40.5 = 36.05` ∈ Band[3] ✓, đích CONDUIT L = 33.63,
lệch 2.42 ≤ 5.61 ✓. Xem §6.5.

**`VPM_band` cũ (`3.5 / 4.5 / 5.5 / 7.0`, ±20%) bị bãi bỏ.** Kiểm nhanh cho thấy nó không thể
thoả INV-1 ở bất kỳ dung sai thực tế nào: tỉ lệ nhỏ nhất giữa hai bậc kề là `5.5/4.5 = 1.222`
⇒ `τ_act < 0.100`, tức ±10% trên một đại lượng bị lượng tử hoá bởi `cost` nguyên. VPM vẫn dùng
được như **số chẩn đoán** (`VPM = Value(1)/c`) nhưng không còn là tiêu chí nghiệm thu.

### 4.4b Bảng phơi nhiễm `p(slot ∧ type)` — đo từ `HEROES` tier-1

INV-7 đòi phơi nhiễm của **đúng vị từ** relic dùng. Bảng dưới đếm trực tiếp 36 mặt của 6 hero
tier-1 (`T1` = `plant1 beast1 aqua1 reptile1 bug1 bird1`, `src/data.js:110`). Tổng kiểm chéo:
`mouth∧dmg + horn∧dmg + tail∧dmg = 10 + 8 + 1 = 19 = p_dmg × 36` ✓ khớp §4.0.

| vị từ | đếm/36 | `p` | Ghi chú dùng được ngay |
|---|---|---|---|
| `mouth ∧ dmg` | 10 | **0.278** | mọi mặt `mouth` tier-1 đều là `dmg` ⇒ `p_slot(mouth) = p(mouth∧dmg)` |
| `horn ∧ dmg` | 8 | **0.222** | mọi mặt `horn` đều là `dmg` ⇒ tiêm keyword vào `horn` an toàn về giá |
| `back ∧ shield` | 7 | **0.194** | mọi mặt `back` đều là `shield` |
| `ears ∧ mana` | 4 | **0.111** | mọi mặt `ears` đều là `mana` + `cantrip` |
| `tail ∧ poison` | 3 | **0.083** | |
| `tail ∧ dmg` | **1** | **0.028** | ⚠ **`p_slot(tail) = 0.111` gấp 4× giá trị dùng được cho keyword damage** |
| `eyes` (heal/buff/debuff) | 3 | **0.083** | không mặt `eyes` nào là `dmg` ⇒ mọi keyword damage tiêm vào `eyes` = **0 RP** |
| `dmg ∧ pierce` (generic) | 2 | 0.056 | committed TALON ⇒ `p_eff = P_COMMIT = 0.30` |
| `dmg ∧ growth` (generic) | 1 | 0.028 | committed EVOLVE ⇒ `p_eff = 0.20` (ngoại lệ §4.1) |
| `dmg ∧ lifesteal` (generic) | 0 | 0.000 | tier-1 không có; xuất hiện từ `plant2` |

**Ba hệ quả bắt buộc:**
- Tiêm keyword **damage** (`cleave` `pierce` `exec` `burn:N` `crit:N` `multi`) chỉ hợp lệ về giá ở
  `mouth`, `horn` — và **không bao giờ** ở `eyes`. Ở `tail` thì `p = 0.028`, tức gần như vô giá trị.
- Tiêm keyword **kwPure phòng ngự** (`thorns:N` `regen:N` `undying`) chỉ hợp lệ ở `back` (0.194)
  và `eyes` (0.083) — đúng chiều Direction Law §3.5.
- Sàn thực tế cho một relic COMMON tiêm keyword: `p ≥ Band[0].L / (Act × KW_max) = 11.22 / (25 ×
  3.60) = 0.125`. Chỉ `mouth`, `horn`, `back` vượt sàn. Đây là INV-7 ở dạng số.

### 4.5 Sáu ví dụ chạy đủ

**Ví dụ 1 — `r_claw` (anchor của cả hệ).** COMMON, `scale`, "mọi mặt damage +1".
```
RP = Act × p_dmg × Δv × R_dmg × κ_det = 25 × 0.528 × 1 × 1.00 × 1.00 = 13.2
```
Band COMMON = 13 → lệch **+1.5%** ✓. Đây là relic dùng để **định nghĩa** anchor 13:
nó là stat-scaler một trục thuần khiết nhất tồn tại, và không ai trong đội cho rằng nó lệch.

**Ví dụ 2 — defect 5 giải quyết bằng số.** Ba relic COMMON hiện tại, cùng bậc:
```
r_claw     (dmg +1)      = 13.2                                  → +1.5%   ✓ ĐÚNG BẬC
r_carapace (shield +3)   = 5.48 × 3 = 16.4                        → +26%    ✗ QUÁ MẠNH
r_fang     (poison +2)   = PSN(6) − PSN(4) = 125 − 80 = 45 × 0.90 = 40.5  → +212%  ✗✗ SAI BẬC HOÀN TOÀN
```
Ba relic cùng bậc COMMON trải từ 13.2 đến 40.5 RP — **hệ số 3.07×**. Sửa:
`r_carapace` → +2 (10.96, −16% ✓); `r_fang` → +1 stack và **lên RARE** (22.5 vs band 18,
+25%… vẫn hở) → +1 stack ở **EPIC** (22.5 vs 26, **−13%** ✓). Kết luận suy ra từ mô hình, không
từ khẩu vị: **không tồn tại relic poison COMMON hợp lệ** — bước tăng poison nhỏ nhất khả thi
(+1 stack) đã là EPIC. Đây là **Superlinear Axis Law** (§4.6).

**Ví dụ 3 — `a_plague`, sai giá lớn nhất trong roster.** EPIC active, hiện `[MP 4] Poison 8 mọi địch`.
```
V_out = E × PSN_single(8, m=4 lượt còn) = 4 × (8+7+6+5) = 104
VPM   = 104 × κ_psn(0.90) / 4 = 23.4        band EPIC 5.5 → +325%  ✗✗✗
Sửa: Poison 3 → V_out = 4 × (3+2+1) = 24 ;  VPM = 24 × 0.90 / 4 = 5.40  → −2%  ✓
```
Và đây là chỗ luật per-turn cắn: ở `M_com = 30` mana/trận, MP4 cho **5 lần cast/trận** (mỗi
lượt một lần), không phải 1. Định giá "1 lần/trận" sẽ cho VPM đúng band và ship một relic
mạnh gấp 5.

**Ví dụ 4 — `r_hivemind`, overtune lớn nhất trong nhóm passive.** LEGENDARY, `hiveMind:2 + startSummon:1`.
```
hiveMind: Act × p_dmg × k × tokens × κ_tok = 25 × 0.528 × 2 × 3 × 0.70 = 55.4
startSummon:1                                                          = 13.0
RP = 68.4        band LEGENDARY 37 → +85%  ✗
```
Và nó vi phạm luật taxonomy §3.1 ("`engine` không được vừa cấp tài nguyên vừa nhân nó lên").
Sửa: bỏ `startSummon`, `hiveMind:1` → `27.7` → **EPIC** (+6.5% ✓). SWARM `bias` = 0.85 (§4.6,
vì winrate đo 33% > baseline) → target `26 × 0.85 = 22.1`; `27.7` lệch **+25%** ✗ → phải hạ
tiếp. Chốt: `hiveMind:1` **EPIC** với `tokens_com` giới hạn còn 2 bằng cách **không** đi kèm
`startSummon` → `18.5`, lệch **−16%** ✓. Đây là ví dụ `bias` ngăn "fix phủ" biến thành buff.

**Ví dụ 5 — `r_growthcore` chứng minh EVOLVE yếu về cấu trúc.** EPIC, "mọi mặt dmg nhận `growth`".
`growth` cộng `u.growth[fi] += 1` cho **đúng mặt đó**. Muốn có lợi, mặt phải được roll **lại**.
```
Mỗi die roll Ω = 5 lần trên 6 mặt. Số cặp trùng mặt kỳ vọng = C(5,2)/6 = 1.67
Mỗi cặp trùng cho +1 damage → 1.67 RP/die → × n = 5  →  RP = 8.3
band EPIC 26 → −68%  ✗✗
```
Kết luận: `growth` ở `Ω=5` **gần như vô giá trị**, và không có cách nào đưa một relic
`growth`-thuần vào band EPIC bằng field hiện có. Đó là lý do EVOLVE playrate 1.7%. Fix cấu trúc
(không phải fix số) ở §10 mục G1: cần accumulator theo-die, không theo-mặt.

**Ví dụ 6 — `mload` chặn đúng chỗ.** Bộ ba đang có thể cùng tồn tại hôm nay:
```
r_bloodpact  dmgMult 1.6   → RP 70×0.6 = 42 ,  drawback −25% maxHp = −(5×4.25×0.86×0.35) = −6.4  → 35.6
r_ancientgene f.v × 1.4    → RP 120×0.4 = 48
r_apexpredator critBonus35 + critMult3 → 0.525×35 + 23.6×1 = 18.4 + 23.6 = 42.0
Cùng giữ: hệ số nhân thực tế trên một đòn crit = 1.6 × 1.4 × 1.5 = ×3.36   (trước exec ×1.6 và FERAL ×1.6)
mload:  bloodpact 2 (dmgMult toàn cục) + ancientgene 2 (f.v×k toàn cục) = 4 > cap 2  → KHÔNG BAO GIỜ ĐỀ NGHỊ CẢ HAI
        apexpredator = critBonus(1) + critMult(1) = 2  → hợp lệ MỘT MÌNH, và loại mọi mload-2 khác
```
Lưu ý `critMult` được xếp **mload 1**, không phải 2: nó chỉ nhân *các đòn crit*, tức là
multiplier **phạm vi archetype**, vô giá trị nếu không có crit chance. Nhờ vậy cặp kinh điển
`critBonus + critMult` (1+1=2) vẫn hợp lệ — nếu xếp cả hai là mload 2, luật anti-stacking sẽ
**cấm chính build APEX**, đúng archetype đang yếu nhất. Cùng lý do: `thornsMult`, `burnMult`,
`poisonTicks`, `plague`, `poisonSpread`, `burnSlow`, `burnSpread`, `piercePlus`, `hiveMind`
đều là mload 1.

### 4.6 Dải nghiệm thu — dải TUYỆT ĐỐI + `bias` là VỊ TRÍ, không phải hệ số nhân

**Bản cũ của phần này (`RP_target = RP_band[r] × bias(a)`, dung sai ±20%) đã bị thay hoàn toàn.**
Lý do nằm ở §3.12 INV-1: dung sai ±20% quanh tâm cách nhau 1.41× **luôn** chồng lấn, và `bias`
nhân vào dải làm chồng lấn thêm 1.35× nữa. Hai khuyết tật đó cộng lại tạo ra đúng hiện tượng
product owner mô tả. Mô hình mới tách hai vai trò mà `bias` đang gánh chung.

#### 4.6.1 Dải cứng — hàm của bậc, KHÔNG của archetype

```
ANCHOR = 13.2                       (RP đo được của r_claw, §4.5 ví dụ 1)
SIG    = [1.0000, 1.4154, 2.0000, 2.8308]      (SIG_BUDGET, part-skill-identity.md §F7)
C_r    = ANCHOR × SIG[r]
τ      = 0.15                       (< 0.1712, cận trên do INV-2)
Band[r] = [ C_r × 0.85 , C_r × 1.15 ]
```

| Ký hiệu | Kiểu | Miền | Nghĩa |
|---|---|---|---|
| `ANCHOR` | float | 12.0 – 14.5 | RP của relic COMMON tham chiếu (`r_claw`) |
| `SIG[r]` | float | 1.00 – 2.83 | tỉ lệ ngân sách giữa các bậc, copy §F7, **không được đổi riêng lẻ** |
| `τ` | float | 0.00 – 0.1712 | nửa bề rộng dải, tính theo tỉ lệ tâm |
| `C_r` | float | 13.20 – 37.37 | tâm dải bậc `r` |
| `Band[r]` | khoảng | [11.22, 42.98] | dải hợp lệ tuyệt đối |

Cạnh dải in ra **đã làm tròn vào trong theo INV-2b** và là giá trị normative:

| bậc | `C_r` (chính xác) | `Band[r]` normative |
|---|---|---|
| 0 COMMON | 13.20000 | **[11.22, 15.18]** |
| 1 RARE | 18.68328 | **[15.89, 21.48]** |
| 2 EPIC | 26.40000 | **[22.44, 30.36]** |
| 3 LEGENDARY | 37.36656 | **[31.77, 42.97]** |

**Ví dụ chạy đủ (INV-1).** `r_pierceall` (COMMON, `horn → pierce`):
`RP = Act × p(horn ∧ dmg) × KW(pierce) × κ_det = 25 × 0.222 × 2.30 × 1.00 = 12.77`.
`12.77 ∈ [11.22, 15.18]` ✓. Relic RARE yếu nhất toàn roster là `a_wall`/`a_clutch` ở `16.00`;
`15.18 < 15.88 ≤ 16.00` ⇒ **không tồn tại** cặp (COMMON, RARE) nào vi phạm, không cần duyệt cặp.

#### 4.6.2 `bias(a)` — vị trí đích trong dải

```
bias(a) = clamp( 1 + β × (WR_base − WR_a) / WR_base , 0.85 , 1.15 ) ,  β = 0.5 , WR_base = 0.20
bias(a) = min( bias(a), 1.00 )    NẾU playrate(a) > 2 × (1/|ARCH|)          ← MỚI, xem dưới
pos(a)  = clamp( (bias(a) − 1) / 0.15 , −1 , +1 )
τ_aim   = 0.10                                   (< τ = 0.15 ⇒ đích luôn nằm trong dải)
RP_target(a, r) = C_r × ( 1 + τ_aim × pos(a) )
```

| Ký hiệu | Kiểu | Miền | Nghĩa |
|---|---|---|---|
| `WR_a` | float | 0.00 – 1.00 | winrate đo được của archetype `a` (`tools/sim.js`) |
| `bias(a)` | float | 0.85 – 1.15 | hệ số cân bằng theo archetype |
| `pos(a)` | float | −1.00 – +1.00 | vị trí chuẩn hoá trong dải |
| `τ_aim` | float | 0.00 – 0.15 | biên độ tối đa `bias` được dịch đích |
| `RP_target` | float | 0.90·C_r – 1.10·C_r | RP đích, **luôn ⊂ Band[r]** |

**Trần `bias ≤ 1.00` cho archetype bẫy — luật mới, và nó là câu trả lời cho một mâu thuẫn có
thật giữa hai doc.** Công thức `bias` chỉ đọc winrate, nên PLAGUE (16% WR) nhận `bias = 1.10`,
tức *tăng* ngân sách. Nhưng §4.7(3) chẩn đoán PLAGUE là archetype **bẫy**: 30% playrate ở winrate
dưới baseline nghĩa là nó được **chọn quá nhiều**, không phải **quá yếu** — và
`relic-roster-expansion.md` §1.2 nói thẳng "không thêm sức mạnh vào đây". Trần đóng đúng vòng phản
hồi mà §13 rủi ro 3 lo ngại. Ngưỡng `2 × fair share` = `2/11 = 18.2%`; chỉ PLAGUE (30%) vượt.
⇒ **PLAGUE: `bias 1.10 → 1.00`, `pos = 0`.**

| archetype | WR | playrate | `bias` | `pos` | C | R | E | L |
|---|---|---|---|---|---|---|---|---|
| crit APEX | 10% | 10% | 1.15 | **+1.000** | 14.52 | 20.55 | 29.04 | 41.11 |
| burn INFERNO | 10% | 10% | 1.15 | **+1.000** | 14.52 | 20.55 | 29.04 | 41.11 |
| pierce TALON | 14% | 5% | 1.15 | **+1.000** | 14.52 | 20.55 | 29.04 | 41.11 |
| aoe TEMPEST | 18% | 7% | 1.05 | **+0.333** | 13.64 | 19.30 | 27.28 | 38.62 |
| poison PLAGUE | 16% | **30%** | **1.00**¹ | **0.000** | 13.20 | 18.68 | 26.40 | 37.37 |
| growth EVOLVE | 20% | 1.7% | 1.00 | 0.000 | 13.20 | 18.68 | 26.40 | 37.37 |
| exec FERAL | — | — | 1.00 | 0.000 | 13.20 | 18.68 | 26.40 | 37.37 |
| thorns AEGIS | 25% | 1.3% | 0.875 | **−0.833** | 12.10 | 17.12 | 24.20 | 34.26 |
| mana CONDUIT | 29% | 12% | 0.85 | **−1.000** | 11.88 | 16.81 | 23.76 | 33.63 |
| shield BULWARK | 31% | 20% | 0.85 | **−1.000** | 11.88 | 16.81 | 23.76 | 33.63 |
| summon SWARM | 33% | 4% | 0.85 | **−1.000** | 11.88 | 16.81 | 23.76 | 33.63 |

¹ trần archetype bẫy (`bias` thô là 1.10).

#### 4.6.3 Hai mức nghiệm thu

```
CỨNG   (BLOCKING, INV-1):  RP(x) ∈ Band[rar(x)]
MỀM    (ADVISORY):         | RP(x) − RP_target(a, rar(x)) |  ≤  0.15 × C_rar(x)
TRUNG BÌNH THEO ARCHETYPE (BLOCKING):
        | mean_{x ∈ a} ( RP(x) / C_rar(x) )  −  (1 + τ_aim × pos(a)) |  ≤  0.05
```

Dung sai mềm đo bằng **RP tuyệt đối** (`0.15 × C_r`), không bằng phần trăm của đích: nếu đo theo
phần trăm của đích thì dung sai của archetype `pos = +1` sẽ tràn qua cận trên dải. Ba giá trị:
C ±1.98 · R ±2.80 · E ±3.96 · L ±5.61.

Ràng buộc **trung bình theo archetype** là nơi `bias` thực sự cắn. Một relic lệch đích là chuyện
nhỏ; cả một archetype lệch đích là "fix phủ đã biến thành buff" — đúng thứ §3.10 kết luận 1 cấm.
Nó chặn ở mức tổng nên không bóp nghẹt từng thiết kế.

`bias` phải được **đo lại sau mỗi lần ship** (§9 knob K7). Nó là ảnh của trạng thái balance
hiện tại, không phải hằng số thiết kế. `exec` = 1.00 vì `archScore` chưa từng đếm được nó nên
không có số — sau khi §3.3 ship, đo lại trước khi tune.

#### 4.6.4 Giá phải trả — nói thẳng cho product owner

Không gian thiết kế **bị nén thật**, và đây là con số:

| | Mô hình cũ (toàn cục) | Mô hình mới | Δ |
|---|---|---|---|
| Bề rộng dải COMMON | [8.84, 17.94] = 2.03× | [11.22, 15.18] = 1.353× | **−33% bề rộng** |
| Trần LEGENDARY | 42.6 × 1.2 = **51.1 RP** | **42.98 RP** | **−16% trần** |
| Sàn COMMON | 11.1 × 0.8 = **8.84 RP** | **11.22 RP** | **+27% sàn** |
| Số RP hợp lệ liên tục | toàn dải [8.84, 51.1] | 4 khoảng rời, 3 vùng cấm | — |

Cụ thể: **relic mạnh nhất trong game bị hạ trần 16%**, và **relic yếu nhất bị nâng sàn 27%**. Đổi
lại, chuỗi màu rarity lần đầu là một phát biểu đúng về sức mạnh. Ba hệ quả thiết kế phải chấp nhận:

1. **Một số trục không còn relic ở một số bậc.** Bước nhỏ nhất của `poison` (+1 stack = 22.5 RP)
   chỉ vừa EPIC ⇒ PLAGUE **không thể** có scaler COMMON hay RARE (Superlinear Axis Law, §4.6.5).
   Bước nhỏ nhất của `growth` (~3 RP) **quá nhỏ cho mọi bậc** ⇒ EVOLVE bắt buộc phải dùng
   `growthAll` (§10 G1), không có lối khác.
2. **Rider trở thành công cụ thường trực, không phải ngoại lệ.** 9 relic trong §6 và 21 relic
   trong §6.7 cần một cơ chế phụ để rơi vào dải. INV-6 giới hạn nó để không thành "hai relic dán lại".
3. **Vùng cấm sẽ bắt các thiết kế "vừa đủ hay".** Ví dụ có thật: `r_windlash` (mouth → cleave) rơi
   đúng 21.55, cách trần RARE 0.07 RP. Nó **phải** lên EPIC kèm rider, không được ở lại RARE.

#### 4.6.5 Superlinear Axis Law (giữ nguyên, phát biểu lại theo dải mới)

Nếu bước tăng nhỏ nhất khả thi trên một trục đã vượt `Band[0].U = 15.18`, trục đó **không có
relic COMMON dạng scaler**; nếu vượt `Band[1].U = 21.48` thì cũng không có RARE. Áp dụng:
`poison` (+1 stack = 22.5 ⇒ sớm nhất là EPIC), `dr` (+0.10 = 5.95 nhưng chỉ hợp lệ ở LEGENDARY do
§3.2), `startSummon` (+1 egg = 13.0 ⇒ COMMON là bậc duy nhất, +2 = 26.0 ⇒ EPIC, **không có RARE**).
Hệ quả bắt buộc: entry-point COMMON của PLAGUE và SWARM phải là `rule` phạm vi hẹp hoặc một `act`,
không phải scaler.

**Superlinear Axis Law.** Nếu bước tăng nhỏ nhất khả thi trên một trục đã vượt
`RP_target(a, 0) × 1.2`, trục đó **không có relic COMMON dạng scaler**. Áp dụng cho:
`poison` (+1 stack = 22.5 > 14.3×1.2 = 17.2). Hệ quả: entry-point COMMON của PLAGUE **phải**
là `rule` phạm vi hẹp hoặc một `act`, không phải scaler. Đây là ràng buộc bắt buộc cho
`relic-roster-expansion.md`.

### 4.7 Chẩn đoán ba mispricing mà sim chỉ ra

**(1) APEX 10% winrate — `crit:N` @ `0.045N` đúng EV, sai risk-adjusted.**
EV của `crit:30` trên mặt `v=8` = `0.30 × 8 = +2.4` damage với giá 1.35 ngân sách → tỉ số
value/cost = 1.78, tức crit trông **rẻ**. Nhưng `rollUnit:254` chốt `u.critNow` **lúc roll**:
crit là biến Bernoulli mà người chơi **không đuổi được bằng reroll có mục đích** — đúng thứ
`combo-decision-memo.md` §1 gọi là "stat do RNG phát, không phải quyết định". Ở baseline
winrate 20% với tường ở boss cuối, thất bại là *không vượt ngưỡng*, nên phương sai là chi phí
thật. ⇒ Giá `0.045N` **không sai với mặt**, nhưng relic crit phải được định giá qua
`κ_rng = 0.75`, và APEX thêm `bias = 1.15`. Tích: relic crit được phép **lớn hơn 53%** so với
relic tất định cùng bậc (`1/0.75 × 1.15`). Đó là buff APEX cần, suy ra từ luật.

**(2) INFERNO 10% winrate — `burn:N` @ `0.55N` sai vì luật halve, không vì giá.**
`tickStatus:658` làm `u.st.burn = floor(u.st.burn/2)` → tổng ≈ `2N`, **không** tích luỹ được.
Poison thoát bẫy này nhờ decay tuyến tính (−1/lượt) cho phép stack chồng; burn thì không, nên
INFERNO **không có win condition scaling** — nó chỉ có một cục damage trễ. Cộng `κ_dot = 0.60`
(burn mất trắng trên target chết trong lượt) và `P_COMMIT = 0.20` (burn chỉ sống trên slot
`tail`). ⇒ **Sửa giá một mình không cứu được INFERNO.** Hai lối:
- **Lối thiết kế (không cần engine work, khuyến nghị):** `burnSlow` — thứ biến burn từ `2N`
  thành `N(N+1)/2`, tức quadratic như poison — hiện nằm ở `r_wildfire` RARE. Phải đảm bảo nó
  là **entry-point COMMON/RARE bắt buộc** của INFERNO (Nourishment Contract (c)), không phải
  một draw may mắn ở EPIC. `relic-roster-expansion.md` phải đặt ≥1 relic cấp `burnSlow` ở bậc
  thấp nhất mà ngân sách cho phép (`burnSlow` = 9.0 RP → hợp COMMON của INFERNO, target 15.0,
  lệch −40% ✗ → cần ghép thêm một scaler nhỏ trên cùng relic để lấp band).
- **Lối engine (knob K9, §9):** đổi decay nền thành `x − max(1, floor(x/3))`. Đây là thay đổi
  balance **toàn game** (ảnh hưởng `MON.pyrewing`, `BOSSES`, `FACE_POOL` r1-r4) → phải qua
  `sim.js` và bump `ENGINE_VERSION`. Không khuyến nghị trong cùng patch với hệ relic.

**(3) PLAGUE 30% playrate / 16% winrate — archetype bẫy, và tracker đang tiếp tay.**
Poison hút 30% số run mà thắng dưới baseline. Hai nguyên nhân, cả hai nằm trong phạm vi doc này:
- **Định giá**: `r_fang` +2 stack = 40.5 RP ở bậc COMMON (ví dụ 2). Người chơi nhặt một relic
  COMMON và thấy poison "bùng" → tín hiệu sai rằng build đang mạnh. P-model sửa việc này.
- **Tín hiệu tracker**: `faceArch` ưu tiên `poison` ở vị trí #2 (§3.4), nên **mọi** mặt có dính
  poison đều đọc là PLAGUE, và `archScore` cộng `1/2/3` theo rarity chứ không theo sức mạnh
  thật. Tracker vì thế báo "anh đang đi PLAGUE" sớm hơn và mạnh hơn thực tế. Sửa bằng knob K8
  (`archScore` cân theo `RP_band` thay vì `rar`), **không** bằng cách hạ ưu tiên poison ở
  `faceArch` — vị trí #2 là đúng về cấu trúc (poison là tín hiệu build khó thay thế nhất).

**(4) Chi phí dự kiến của `mload` cap, nói thẳng.** Ở baseline 20% với 101/300 run chết ở boss
cuối, những run *thắng* rất có thể là những run đã cộng dồn multiplier. Cap 2 cắt đúng cái đuôi
đó. **Dự báo: winrate tổng giảm 20.0% → khoảng 14-17%** (chưa đo — phải chạy
`node tools/sim.js 500 mode=short asc=0` trước khi ship, đây là AC-12). Đền bù đặt ở **ba** chỗ
đã có trong doc, không phải ở việc nới cap:
1. `bias ≥ 1.15` cho ba archetype yếu nhất (crit, burn, pierce) — nâng sàn thay vì nâng trần.
2. `κ_rng`/`κ_dot` làm relic crit/burn lớn hơn 33-67% ở cùng bậc.
3. Phủ archetype (§5) nâng **playrate**, và ba archetype winrate cao nhất (SWARM 33%, BULWARK
   31%, CONDUIT 29%) lần đầu có đủ relic để với tới — dịch phân bố người chơi ra khỏi PLAGUE.
Nếu sau sim winrate vẫn < 14%, knob đầu tiên được nới là `RELIC_MLOAD_CAP` 2 → 3 (§9 K5),
**không** phải hạ `bias` — vì đó là knob duy nhất có tác dụng đơn điệu và đo được một mình.

## 5. Mục tiêu phủ archetype

### 5.1 Mục tiêu — suy từ Nourishment Contract, không phải quota

```
Với MỌI a ∈ ARCH (11 archetype):
    passive:  ≥1 COMMON · ≥2 RARE · ≥2 EPIC · ≥1 LEGENDARY      = ≥6
    active:   ≥1 (bất kỳ bậc)                                    = ≥1
    ⇒ ≥7 relic/archetype ,  tổng ≥ 66 passive + 11 active = 77
```

Lý do từng con số (mỗi cái map vào một điều khoản §3.10):

| Ô | Số tối thiểu | Vì sao đúng con số đó |
|---|---|---|
| COMMON | **1** | Điều khoản (c): 5 archetype (crit, burn, aoe, summon, growth) **không có class engine**. Relic COMMON là chỗ duy nhất chúng mua được engine khởi động. Ở band đầu run `[0, 1]` (`engine.js:691`), COMMON là bậc duy nhất chắc chắn xuất hiện trước wave 4. |
| RARE | **2** | Band `[1,2]`/`[1,3]` là nơi người chơi *quyết định* theo archetype nào (wave 3-8). Một lựa chọn duy nhất không phải quyết định — cần ≥2 để pool còn cái thứ hai sau khi `relicPool` loại cái đã giữ và các `ex`/`mload` conflict. |
| EPIC | **2** | EPIC là bậc "bật engine" (§3.2). Với `mload` cap 2 và `ex` loại trừ, một archetype chỉ có 1 EPIC sẽ **chết hẳn** nếu EPIC đó xung đột với thứ đang giữ. ≥2 là dự phòng cấu trúc, không phải nội dung thừa. |
| LEGENDARY | **1** | Chỉ mở qua `u_relic2` (cost 280) hoặc event; ≥2 sẽ làm loãng bậc cao và phá cảm giác capstone. |
| active | **1** | Điều khoản (d). Hôm nay **6/11 archetype không có active nào** — nghĩa là 6 archetype đó không có bề mặt chi tiêu Mana, và mọi Mana họ thu được chỉ chảy về relic tag `mana`. Đó là một nửa lý do CONDUIT có 7 relic mà chỉ 12% playrate: nó **độc quyền** bề mặt active, nên các archetype khác không có lý do gì để đọc Mana. |

**Trần trên, cũng bắt buộc:** không archetype nào được vượt **10 relic**, và
`max(count) / min(count) ≤ 1.6`. Hôm nay tỉ số này là `8 / 2 = 4.0` (mana vs thorns/growth/
summon) — đó là phát biểu định lượng của defect 1.

### 5.2 Trạng thái sau khi retune 44 relic hiện có (§6), và khoảng trống còn lại

Bảng dưới là **hợp đồng cho `relic-roster-expansion.md`**: mỗi ô "cần" là số entry mới doc đó
phải viết, ở đúng `RP_target(a, r)` của §4.6.

| archetype | `bias` | C có/cần | R có/cần | E có/cần | L có/cần | act có/cần | mới |
|---|---|---|---|---|---|---|---|
| exec FERAL | 1.00 | 2 / — | 1 / **+1** | 0 / **+2** | 1 / — | 0 / **+1** | **4** |
| crit APEX | 1.15 | 0 / **+1** | 1 / **+1** | 0 / **+2** | 2 / — | 0 / **+1** | **5** |
| pierce TALON | 1.15 | 1 / — | 0 / **+2** | 1 / **+1** | 0 / **+1** | 1 / — | **4** |
| shield BULWARK | 0.85 | 1 / — | 1 / **+1** | 3 / — | 1 / — | 1 / — | **1** |
| thorns AEGIS | 0.875 | 0 / **+1** | 1 / **+1** | 0 / **+2** | 1 / — | 0 / **+1** | **5** |
| poison PLAGUE | 1.10 | 0 / **+1**¹ | 2 / — | 0 / **+2** | 2 / — | 1 / — | **3** |
| burn INFERNO | 1.15 | 0 / **+1**² | 2 / — | 1 / **+1** | 1 / — | 0 / **+1** | **3** |
| mana CONDUIT | 0.85 | 0 / **+1**³ | 1 / **+1** | 2 / — | 1 / — | 4 / — | **2** |
| aoe TEMPEST | 1.05 | 1 / — | 0 / **+2** | 1 / **+1** | 1 / — | 1 / — | **3** |
| growth EVOLVE | 1.00 | 0 / **+1** | 0 / **+2** | 1 / **+1** | 1 / — | 0 / **+1** | **5** |
| summon SWARM | 0.85 | 0 / **+1** | 0 / **+2** | 2 / — | 0 / **+1** | 0 / **+1** | **5** |
| **TỔNG** | | 5 / +7 | 9 / +13 | 11 / +11 | 11 / +2 | 8 / +6 | **40** |

> ⚠️ **Bảng trên là hợp đồng đã được `relic-roster-expansion.md` thực hiện — nhưng doc đó viết 48
> entry, không phải 40, và phân bố bậc thực tế khác bảng này sau khi §6.7 áp bất biến §3.12.**
> Trạng thái phủ archetype **đúng và cuối cùng** nằm ở **§6.7.8**. Bảng dưới giữ lại làm hồ sơ
> của hợp đồng ban đầu.

**Roster hợp nhất (số cũ, đã lỗi thời): 44 + 40 = 84 relic** (73 passive + 11 active). Số thật
sau §6.7 là **94** (78 passive + 16 active). Nằm trong dải tham chiếu
75-90 của product owner. Con số này không phải mục tiêu — nó là *đầu ra* của "≥6 passive +
≥1 active mỗi archetype" cộng với 11 relic dư ở LEGENDARY/EPIC mà 44 relic cũ đã có.

¹ **PLAGUE COMMON phải là `cat: rule` phạm vi hẹp, không phải `scale`** — Superlinear Axis Law
(§4.6): bước poison nhỏ nhất (+1 stack) = 22.5 RP, đã là EPIC.
² **INFERNO COMMON phải cấp `burnSlow` hoặc tương đương** — §4.7(2): không có nó, INFERNO
không có win condition scaling. `burnSlow` một mình = 9.0 RP (< target 15.0) nên phải ghép
thêm một scaler nhỏ trên **cùng một relic**, không tách thành hai.
³ **CONDUIT COMMON phải là passive** (4 active hiện có đều tag `mana`, nhưng điều khoản (c)
đòi một *engine-starter/scaler* mua được ở COMMON, không phải một sink).

### 5.3 Actives — 6 archetype đang trống, và giá của việc lấp

`act.kind` chỉ có **8 giá trị đã implement** (§4.3c). Ánh xạ archetype → kind khả dụng:

| archetype | kind dùng được hôm nay | Cần kind mới? |
|---|---|---|
| pierce, exec, crit | `dmg` (có `pierce:1` flag) | Không — nhưng `dmg` không phân biệt được exec/crit ⇒ ba archetype dùng chung một kind, chỉ khác số. Chấp nhận cho exec/pierce; **crit thì không** (không có cách nào cấp crit qua active). |
| aoe | `dmgall` | Không |
| shield | `shieldall` | Không |
| poison | `poisonall` | Không |
| mana | `reroll`, `heal`, `stun`, `ult` | Không |
| **burn** | — | **Có**: `burnall` |
| **thorns** | — | **Có**: `thornsall` |
| **summon** | — | **Có**: `summonally` |
| **growth** | — | **Có**: `growthall` |
| **crit** | — | **Có**: `critall` |

⇒ **5 `act.kind` mới** = engine work, spec ở §10 mục A1-A5. `relic-roster-expansion.md` được
phép dùng chúng nhưng **phải đánh dấu rõ là chưa build được**, vì không có nhánh `else` trong
`playerUseRelic` — một `kind` lạ **vẫn trừ mana, vẫn tiêu slot của lượt, và không làm gì**
(`engine.js:566-575`). Đó là chế độ hỏng tệ nhất có thể: người chơi trả giá và không nhận gì,
không có thông báo lỗi.

### 5.4 Luật gán tag cho active (giải quyết defect 8 bằng luật, không bằng sửa tay)

```
a.tag = archetype của OUTPUT nếu output có archetype:
          dmgall → aoe · shieldall → shield · poisonall → poison ·
          dmg + pierce:1 → pierce · burnall → burn · thornsall → thorns ·
          summonally → summon · growthall → growth · critall → crit
        ngược lại (heal · stun · reroll · ult) → mana
```

Lý do `mana` là fallback chứ không phải `''`: `ARCH.mana` được định nghĩa đúng là
*"Spam active cards. Never run out of Mana"* — một active không có bản sắc output nào **chính
là** nội dung CONDUIT. Luật này sửa `a_freeze` (stun, hiện tag `mana` — **đúng theo luật, giữ
nguyên**) và `a_ult` (hiện tag `crit`, **sai** — nó không cấp crit gì cả; `ult` → `mana`), và
sửa `a_chomp` (hiện `mana`, nhưng `pierce:1` → `pierce`).

## 6. Retune / retag 44 relic hiện có — ID GIỮ NGUYÊN

**Không id nào bị xoá hoặc đổi tên.** Đây là ràng buộc cứng vì `META.relics` lưu tiến độ
Collection xuyên save (`ui.js:233`) và một id biến mất sẽ thành entry mồ côi không bao giờ
đếm được. Migration cho việc *thêm* relic: §7 E7.

Cột **Δ**: `=` không đổi · `T` retune số · `A` retag archetype · `R` đổi rarity · `F` đổi
chức năng. Cột **RP/VPM** là giá trị sau retune; **%** là lệch so với `RP_target(a,r)` (§4.6).

> **Cột đọc thế nào.** `RP` = giá trị theo §4.4/§4.4a/§4.4b. `Band` = `Band[rar]` (§4.6.1).
> `Δaim` = `|RP − RP_target(a,rar)|`, so với dung sai mềm `0.15 × C_r` (C 1.98 · R 2.80 ·
> E 3.96 · L 5.61). Mọi giá trị dưới đây **đã** thoả INV-1 (không dòng nào nằm trong vùng cấm)
> và INV-6 (≤2 cơ chế ở C/R, ≤3 ở E/L, cơ chế lớn nhất ≥45% RP).

### 6.1 COMMON — Band [11.22, 15.18] (5 passive → 5 passive)

| id | Tên | arch | `cat` | Hiệu ứng chính xác sau retune | Field | RP | Δaim | `mload`/`ex`/`mfPhase` | Δ |
|---|---|---|---|---|---|---|---|---|---|
| `r_claw` | Razor Claw | **exec** | scale | Mọi mặt `dmg` +1 | `modFace` (`f.v`) | **13.20** | 0.00 ✓ | 0 / — / `add` | **A** |
| `r_carapace` | Stone Carapace | shield | scale | Mọi mặt `shield` **+2** (từ +3); mọi mặt `heal` **+2** | `modFace` (`f.v`) | **12.15** | 0.27 ✓ | 0 / — / `add` | **T** |
| `r_pierceall` | Piercing Horn | pierce | rule | Mọi mặt `horn` nhận `pierce` | `modFace` (`f.k`) | **12.77** | 1.75 ✓ | 0 / `pierceInject` / `kw` | **R** |
| `r_cleaveall` | Sweeping Tail | aoe | scale | **+2 damage cho mọi mặt `dmg` đã có `cleave` hoặc `aoe`** (bỏ hẳn mệnh đề tiêm `cleave` vào `tail`) | `modFace` (`f.v`) | **15.00** | 1.36 ✓ | 0 / — / `add` | **F T R** |
| `r_bloodmouth` | Bloodmouth | **exec** | rule | Mọi mặt `mouth` nhận `lifesteal`; **+2 Max HP mỗi Axie** | `modFace` (`f.k`+`u.maxHp`) | **13.43** | 0.23 ✓ | 0 / — / `kw` | **A R T** |

> **Entry-point COMMON của INFERNO KHÔNG phải `r_wildfire`** — xem hộp "AC-9 cắn" ngay dưới §6.2.
> Nó là `r_tinderbox` (roster, §6.7.6), giữ nguyên ở COMMON với `mload 0`.

**`r_cleaveall` là ca INV-7 nặng nhất trong 44 relic.** Hiệu ứng cũ tiêm `cleave` vào slot `tail`,
định giá ở `p_slot(tail) = 0.111` → 8.60 RP. Nhưng `p(tail ∧ dmg) = 0.028` (§4.4b) — 3/4 số mặt
`tail` tier-1 là `poison`, và nhánh `poison` của `doFace` **không bao giờ đi qua `hit()`** nên
`cleave` ở đó là no-op im lặng. Giá thật: `25 × 0.028 × 3.10 = 2.17` RP, cộng rider "+2 tail dmg"
`= 1.40` ⇒ tổng **3.57 RP**, tức **27% của một COMMON**. Đây là `r_voidgene` thứ hai (§7 E1) và
không ai phát hiện được nếu định giá bằng `p_slot`. Hiệu ứng mới ("+2 damage cho mặt đã có
`cleave`/`aoe`") định giá ở `p_eff(aoe) = P_COMMIT = 0.30` ⇒ 15.00, và nó là **entry-point COMMON
của TEMPEST** — vai trò `r_gustwing` không thể nhận (§6.7).

Keyword tiêm ở bậc này (`pierce`, `lifesteal`) đều **ngoài kwPure** ⇒ Direction Law an toàn
tuyệt đối (§3.5) ✓.

> 🔒 **`r_pierceall` nhận thêm `exSub: ['pierceInjectAll']` (§3.7a cặp 2).** Đo trên mặt thật:
> `r_worldpiercer` tiêm `pierce` lên **29** mặt, `r_pierceall` lên **9**, và **9 ⊂ 29** — giữ cả
> hai thì `r_pierceall` đóng góp đúng 0. Nó **không** dùng chung `ex` với `r_worldpiercer`: token
> chung là đối xứng và sẽ khiến một COMMON **cấm** một LEGENDARY. `ex: ['pierceInject']` giữ nguyên.
`r_carapace` +2 vẫn cộng dồn với BULWARK +2 của Plant (`engine.js:376`)
→ `RP_class` = 12.15 × 1.45 = 17.6 = 1.33× band ✓ dưới trần 2.2.

### 6.2 RARE — Band [15.89, 21.48] (10 passive → 11 passive)

| id | Tên | arch | `cat` | Hiệu ứng chính xác sau retune | Field | RP | Δaim | `mload`/`ex`/`mfPhase` | Δ |
|---|---|---|---|---|---|---|---|---|---|
| `r_heart` | Lunacia Heart | **shield** | scale | **+12** Max HP mỗi Axie (từ +10) | `modFace` (`u.maxHp`) | **18.00** | 1.19 ✓ | 0 / — / `add` | **A R T** |
| `r_ear` | Keen Ears | mana | scale | Mọi mặt `mana` +1 | `modFace` (`f.v`) | **16.90** | 0.09 ✓ | 0 / `manaFaceBoost` / `add` | **R** |
| `r_spines` | Sharp Spines | thorns | engine | Cả party luôn có Thorns **2** (từ 3) | `onTurnStart` | **17.00** | 0.12 ✓ | 0 / `thornsFloorFlat` | **T** |
| `r_luckycharm` | Lucky Scale | crit | scale | Crit chance **+35%** (từ 20%) | `critBonus:35` | **18.38** | 2.17 ✓ | **1** / `critChance` | **T** |
| `r_ember` | Ember | burn | rule | Đòn gây **≥4** damage cũng áp `burn:2` | `onHit` | **19.60** | 0.95 ✓ | 0 / — | **T** |
| `r_openwound` | Open Wound | poison | rule | Mục tiêu có Poison nhận **+30%** damage | `modDmg` | **17.00** | 1.68 ✓ | 0 / `poisonAmpPct` | **=** |
| `r_deathmark` | Death Mark | exec | rule | Mỗi khi một địch chết, mọi mặt `dmg` **+1** đến hết trận; **+2 Max HP mỗi Axie** | `onKill` + `modFace`(`u.maxHp`) | **18.80** | 0.12 ✓ | 0 / — / `add` | **T R** |
| `r_holyfont` | Sacred Font | shield | rule | Heal cũng cấp Shield bằng lượng đã heal | `healShield:1` | **18.30** | 1.49 ✓ | 0 / `healShield` | **R** |
| `r_hivemind` | Hive Mind | summon | scale | Mỗi Axie Egg còn sống cho cả party **+1** damage (bỏ `startSummon`) | `hiveMind:1` | **18.50** | 1.69 ✓ | **1** / `hiveMind` | **T R** |
| `r_wildfire` | Wildfire | burn | rule | `burnSlow:1` (Burn chỉ mất 1 stack/lượt); mọi mặt **`horn`** type `dmg` cũng áp **`burn:6`** | `burnSlow` + `modFace`(`f.k`) | **19.99** | 0.56 ✓ | **1** / `burnDecay` / `kw` | **T** |
| `r_voidgene` | Void Gene | **mana** | engine | **+2 Max Reroll**; **+1 Mana khi bắt đầu mỗi trận** | `rerollUp:2` + `onTurnStart` (guard `s.turn===1`) | **16.25** | 0.56 ✓ | 0 / — | **F T R** |

> **AC-9 cắn, và nó quyết định INFERNO khởi động ở bậc nào.** Draft trước đặt `r_wildfire` ở
> COMMON (14.49 RP) để thoả §5.2 ghi chú ² ("INFERNO phải có COMMON cấp `burnSlow`"). Nhưng
> `burnSlow` là **`mload 1`** (§3.6 — nó biến burn từ `≈2B` thành `B(B+1)/2`, tức khuếch đại siêu
> tuyến tính thật), và **AC-9 quy định `mload > 0 ⇒ rar ≥ 1`**. Hai phát biểu normative trong cùng
> một doc không được mâu thuẫn.
>
> **Kết luận suy ra, không chọn tay: RARE là bậc THẤP NHẤT mà `burnSlow` có thể tồn tại.**
> `mload` và §3.12 cùng nhau *quyết định* vị trí engine của INFERNO; không có lựa chọn thiết kế
> nào ở đây. Vì vậy §5.2 ghi chú ² được sửa: *"entry-point cấp `burnSlow` của INFERNO nằm ở
> **RARE**, không phải COMMON"*. Nhịp độ vẫn đạt: `mkReward` band đầu run là `[0, 1+(pwr>6?1:0)]`
> (`engine.js:691`) ⇒ **rarity 1 xuất hiện ngay từ wave 1**, thoả yêu cầu "engine online trước
> wave 10" của roster §1.2.
>
> Hệ quả dây chuyền: INFERNO cần một COMMON khác, và nó **không được** mang `mload > 0`.
> `r_tinderbox` (roster) là ứng viên duy nhất — `modDmg` phẳng, `mload 0` — nên nó **ở lại COMMON
> tại `+2` (13.79 RP)**, huỷ đề nghị "→ RARE, +3" của §6.7.6. INFERNO sau đó: C 1 · R 2
> (`r_wildfire`, `r_ember`) · E 2 · L 1 · active 1 = **7** ✓ AC-4.
>
> Số của `r_wildfire` ở RARE: `burnSlow` 9.00 + `burn:6` vào `horn ∧ dmg`
> (`25 × 0.222 × KW(burn:6)=3.30 × κ_dot 0.60 = 10.99`) = **19.99**, đích INFERNO RARE 20.55,
> lệch 0.56 ✓. Direction Law: `burn` là kwPure nhưng tiêm vào mặt `dmg` ⇒ `addStatus` lên **địch**
> ✓; guard `f.t === 'dmg'` vẫn bắt buộc vì `FACE_POOL`/`muts` có thể thêm mặt `horn` type khác.

**Hai relic xuống RARE từ EPIC (`r_holyfont` 18.30, `r_hivemind` 18.50)** — không phải nerf, là
**đặt đúng bậc**: cả hai vốn nằm ở 18.3/18.5 RP trong bản EPIC trước, tức dưới sàn EPIC 22.44 và
trên sàn RARE 15.88. Ở dải cũ (`±20%` quanh 26/22.1) chúng "lệch −17%/−16%" và được cho qua; ở dải
mới chúng **không hợp lệ ở EPIC**. Lợi ích phụ, đo được: việc này lấp đúng ô "shield cần +1 RARE"
và một trong hai ô "summon cần +2 RARE" của §5.2, **không tốn một entry nội dung mới nào** — đúng
điều `relic-roster-expansion.md` §18/D4 đề nghị (lấp slot bằng retag/re-rarify, không bằng content).

**`r_deathmark` +2 Max HP là rider bắt buộc, không phải trang trí.** `onKill +1 dmg` = 15.80 RP,
tức **cách sàn RARE 0.08 RP** — nằm ngay trong vùng cấm nếu để nguyên. Bước tiếp theo của cơ chế
(`+2 dmg`) = 31.60, tức LEGENDARY. INV-3 không cho phép "ở lửng lơ", nên rider là lối duy nhất.
Đây là minh hoạ trực tiếp cho §4.6.4 hệ quả 2.

`r_fang` lên EPIC (§6.3) — bước poison nhỏ nhất đã vượt trần RARE (Superlinear Axis Law §4.6.5).

### 6.2a `r_voidgene` hỏng BA LẦN theo cùng một cách — mẫu hình quan trọng hơn bản vá

Ba phiên bản liên tiếp của cùng một id, mỗi phiên bản được viết để sửa phiên bản trước, và cả ba
đều **định giá một cơ chế không tồn tại**:

| # | Hiệu ứng | RP tuyên bố | RP thật | Vì sao bằng 0 |
|---|---|---|---|---|
| 1 | Mặt `blank` thành `mana 2` | (chưa bao giờ tính) | **0.00** | `HEROES` **không có mặt `blank` nào** trên cả 18 hero. Hằng `B` chỉ xuất hiện trong `MON.die`/`BOSSES.die` và trong `axieToDie()` khi Axie import thiếu part (§7 E1) |
| 2 | Mọi mặt `mana` cũng cấp `rerollup` | 24.50 | **3.89** | Định giá ở `p_eff = 0.30` thay vì `p(ears ∧ mana) = 0.111` (INV-7). Và nó **trùng 100%** với `r_tidalbrand` của roster ⇒ dead draw §3.7 |
| 3 | Mỗi Reroll chưa dùng → 1 Mana (`rerollRefund`) | 25.25 | **0.00** | `rerollRefund` **không tồn tại**: grep toàn `src/` = 0 lần; không có trong §10 engine work; không có trong `ENG-0..ENG-17` của roster. Ship như viết thì relic chỉ làm `rerollUp:2` = **14.00 RP đứng trong dải EPIC** — tái tạo đúng lỗi §3.12 sinh ra để diệt |

**Nguyên nhân chung, phát biểu thành luật (INV-9):**

```
INV-9 (Realised-Mechanism Law) — ba trạng thái, không phải hai:

  LIVE     field có ≥1 điểm đọc trong src/engine.js
           (rhas / rsum / rmax / rmul_ / rcall / truy cập trực tiếp)
           ⇒ được tính RP đầy đủ.

  PENDING  field CHƯA có điểm đọc, NHƯNG relic mang `eng: '<ENG-id>'`
           trỏ tới một mục có thật trong bảng engine work
           (§10 E1/R1/R2/G1/G2/A1-A5 của doc này, hoặc ENG-0..ENG-17 của roster)
           kèm spec hành vi chính xác
           ⇒ được tính RP, và relic bị gate: KHÔNG ship trước khi mục đó land.

  DEAD     không LIVE và không PENDING
           ⇒ đóng góp RP = 0, và relic phải được định giá lại mà không có nó.
```

Ba trạng thái là **cố ý** và khớp đúng cách `tools/t_relic.mjs` kiểm: chỉ **DEAD** hard-fail;
**PENDING** pass với cảnh báo và được đối chiếu với id engine-work. Nếu chỉ có hai trạng thái
(sống/chết) thì mọi relic gate bởi `ENG-*` sẽ fail sai, và cả 18 relic của roster phụ thuộc engine
work sẽ bị chặn oan. `eng` là **field khai báo trên relic**, không suy được từ thân hàm — cùng lý
do `mfPhase` phải khai (INV-5).

`rerollRefund` là **DEAD**, không phải PENDING: nó không mang `eng` và không có mục engine-work nào
tương ứng ở bất kỳ đâu (grep `src/` = 0; §10 = 0; `ENG-0..ENG-17` = 0). Đó là toàn bộ khác biệt
giữa nó và `growthAll` (PENDING, `eng: 'G1'`) hay `burnTicks` (PENDING, `eng: 'ENG-7'`) — hai field
cũng chưa tồn tại trong `src/` nhưng **được tính RP một cách hợp lệ**.

Đây không phải luật mới về nội dung — nó là **§7 E1 mở rộng từ "điều kiện tần suất 0" sang "cơ chế
tần suất 0"**. E1 chỉ bắt trường hợp điều kiện không bao giờ đúng; nó không bắt trường hợp *field
không bao giờ được đọc*. Ba lần hỏng của `r_voidgene` đều nằm ở khoảng trống đó, cùng với
`shieldself:N` (§7 E2), `onTurnEnd`/`onPoison` (§10 G2), và toàn bộ mệnh đề `cleave → tail` của
`r_cleaveall` (§6.1). Kiểm bằng máy: **AC-22**.

**Bản chốt (thứ tư) cố tình KHÔNG phát minh gì.** `rerollUp` được `startCombat` đọc thật;
`onTurnStart` được `rcall` thật tại `engine.js:235` và `:635`; `s.mana += 1` là một phép cộng.
Hai cơ chế, **0 engine work**, RP = `14.00 + 2.25 = 16.25` — và **16.25 là RARE, không phải EPIC**.
Đó là câu trả lời trung thực cho "relic này thực sự làm gì hôm nay". Việc nó tụt một bậc là *kết
quả*, không phải nhượng bộ: ba phiên bản trước chỉ giữ được bậc EPIC nhờ ngân sách vay từ một cơ
chế không tồn tại.

**Hệ quả phụ, và nó giải quyết luôn câu hỏi mở của §6.7.8:** CONDUIT chuyển từ
C 1 / R 1 / E 3 / L 2 sang **C 1 / R 2 / E 2 / L 2** — thoả AC-4 đầy đủ, **không thêm content
mới, không đụng `r_infinitedie`**. Cả hai phương án (a) và (b) ở §6.7.8 đều bị huỷ; xem §6.7.8.

### 6.3 EPIC — Band [22.44, 30.36] (12 passive → 9 passive)

| id | Tên | arch | `cat` | Hiệu ứng chính xác sau retune | Field | RP | Δaim | `mload`/`ex`/`mfPhase` | Δ |
|---|---|---|---|---|---|---|---|---|---|
| `r_fang` | Venom Fang | poison | scale | Mọi mặt `poison` **+1** stack (từ +2) | `modFace` (`f.v`) | **22.50** | 3.90 ✓ | 0 / — / `add` | **T R** |
| `r_regrow` | Regrowth Bud | shield | engine | Cả party có Regen 2 mỗi lượt; **+2 Max HP mỗi Axie** | `onTurnStart` + `modFace`(`u.maxHp`) | **23.80** | 0.04 ✓ | 0 / `regenFloor` / `add` | **T R** |
| `r_bastionplate` | Bastion Plate | shield | rule | Tạo Shield → gây **50%** (từ 60%) giá trị đó cho 1 địch ngẫu nhiên | `onShield` | **22.50** | 1.26 ✓ | 0 / `shieldSplash` | **T** |
| `r_hollowbone` | Hollow Bone | pierce | scale | Đòn `pierce` bỏ qua Thorns và **+3** damage (từ +4) | `piercePlus:3` | **27.50** | 1.54 ✓ | **1** / `piercePlus` | **T** |
| `r_pyroclasm` | Pyroclasm | burn | rule | Burn khi gây damage lan **một nửa** stack sang 2 target liền kề; **mọi mặt `horn` type `dmg` +1** | `burnSpread:1` + `modFace`(`f.v`) | **29.55** | 0.51 ✓ | **1** / `burnSpread` / `add` | **T** |
| `r_chainreact` | Chain Reaction | aoe | rule | Địch chết nổ **5** (từ 8) damage lên mọi địch còn lại | `onKill` | **28.50** | 1.22 ✓ | 0 / — | **T** |
| `r_growthcore` | Growth Core | growth | rule | Mọi mặt `dmg` nhận `growth`, **+1 damage**, **+2 Max HP mỗi Axie** | `modFace`(`f.k`+`f.v`+`u.maxHp`) | **24.50** | 1.90 ✓ | 0 / `growthInject` / `kw`+`add` | **T** |
| `r_swarmnest` | Swarm Nest | summon | engine | Bắt đầu mỗi trận với 2 Axie Egg | `startSummon:2` | **26.00** | 2.24 ✓ | 0 / — | **=** |
| `r_infinitedie` | Infinite Die | **mana** | engine | +2 Max Reroll; reroll không xoá undo history; **+1 Mana khi bắt đầu mỗi trận** | `rerollUp:2` + `safeReroll:1` + `onTurnStart`(turn 1) | **24.25** | 0.49 ✓ | 0 / `safeReroll` | **A R T** |

**`r_voidgene` chuyển xuống RARE — xem §6.2a để biết vì sao relic này hỏng ba lần liên tiếp.**

**`r_hollowbone` 4 → 3 và `r_pyroclasm` + rider — hai chiều của cùng một ràng buộc.** `piercePlus:4`
= 35.00 RP, vượt trần EPIC 30.36 và rơi vào Band[3] ⇒ hoặc lên LEGENDARY, hoặc hạ số. Chọn hạ vì
TALON đã có 2 LEGENDARY từ expansion (`r_worldpiercer`, `r_dawnlance`) và §5.1 giới hạn L ≥1 chứ
không khuyến khích ≥3. Ngược lại `burnSpread` một mình = 24.00, hợp lệ nhưng lệch đích INFERNO
(29.04) **5.04 > 3.96** ⇒ trượt dung sai mềm; rider `+1 horn dmg` (5.55) đưa về 29.55, lệch 0.51.
Hai ca này cho thấy dải hẹp cắt **cả hai đầu**, không chỉ đầu trên.

### 6.4 LEGENDARY — Band [31.77, 42.97] (9 passive → 11 passive)

| id | Tên | arch | `cat` | Hiệu ứng chính xác sau retune | Field | RP | Δaim | `mload`/`ex`/`mfPhase` | Δ |
|---|---|---|---|---|---|---|---|---|---|
| `r_echostone` | Echo Stone | crit | rule | Mặt đầu tiên mỗi lượt kích hoạt 2 lần | `firstEcho:1` | **40.50** | 0.61 ✓ | 0 / `echoRule` | **R** |
| `r_apexpredator` | Apex Predator | crit | scale | +35% crit chance; crit ×3 thay vì ×2 | `critBonus:35` + `critMult:3` | **41.98** | 0.87 ✓ | **1+1=2** / `critChance`,`critMult` | **=** |
| `r_bloodpact` | Blood Pact | exec | **pact** | Cả party mất 25% Max HP; mọi damage ×1.6 | `modFace`(`u.maxHp`) + `dmgMult:1.6` | **35.60** | 1.77 ✓ | **2** / `dmgMult` / `add` | **=** |
| `r_venomengine` | Venom Engine | poison | rule | Poison gây damage 2 lần mỗi lượt | `poisonTicks:2` | **39.60** | 2.23 ✓ | **1** / `poisonTicks` | **R** |
| `r_plaguelord` | Plague Lord | poison | rule | Poison **không bao giờ** mất stack; mọi mặt `poison` +1 stack | `plague:1` + `modFace`(`f.v`) | **36.00** | 1.37 ✓ | **1** / `plague` / `add` | **T** |
| `r_mirrorshell` | Mirror Shell | thorns | rule | Thorns của bạn gây damage **×2** (từ ×3) | `thornsMult:2` | **34.00** | 0.26 ✓ | **1** / `thornsMult` | **T R** |
| `r_solarcore` | Solar Core | burn | rule | Burn gây damage ×2 (bỏ mệnh đề `onHit`) | `burnMult:2` | **40.00** | 1.11 ✓ | **1** / `burnMult` | **T** |
| `r_soulforge` | Soul Forge | shield | rule | Shield **không có trần**; nhận ít hơn **30%** (từ 25%) damage; mọi mặt `shield` +2 | `noShieldCap:1` + `dr:0.30` + `modFace`(`f.v`) | **33.81** | 0.18 ✓ | **2** / `dr` / `add` | **T** |
| `r_stormcall` | Storm Call | aoe | rule | Mọi mặt `dmg` đơn mục tiêu nhận `cleave` | `modFace`(`f.k`) | **40.90** | 2.28 ✓ | 0 / `cleaveInject` / `kw` | **=** |
| `r_manaflood` | Mana Flood | mana | rule | Mana chưa dùng cuối lượt gây damage đó lên mọi địch; **+3 Mana khi bắt đầu mỗi trận** | `manaOverflow:1` + `onTurnStart`(turn 1) | **36.75** | 3.12 ✓ | 0 / `overflow` | **T R** |
| `r_ancientgene` | Ancient Gene | growth | rule | Cả 6 mặt mọi Axie mạnh hơn **30%** (từ 40%) | `modFace` (`f.v × 1.3`) | **36.00** | 1.37 ✓ | **2** / `globalFaceMult` / **`mul`** | **T** |

**`r_soulforge` `dr` 0.25 → 0.30 là buff, và nó an toàn vì `mload` — không vì may mắn.**
Bản cũ = 30.90 RP, dưới sàn LEGENDARY 31.76 ⇒ vùng cấm. §7 E11 cảnh báo `dr` cộng dồn tiến tới bất
tử ở `Σdr ≥ 1.0`; nhưng `dr` là `mload 2` = hết trần, nên **tối đa một relic `dr` tồn tại được
trong một run** ⇒ trần cứng `Σdr = 0.30 < 1.0`. Nói cách khác: `mload` cho phép nâng số này một
cách có kiểm soát, đúng như §7 E11 dự đoán ("`mload` đóng một lỗ hổng số học, không chỉ một lỗ hổng
cân bằng"). Nếu K5 nới `RELIC_MLOAD_CAP` lên 3 thì `dr` phải quay về **0.25 hoặc thấp hơn** —
ghi vào §9 K5 như một ràng buộc kèm.

**`r_ancientgene` là relic duy nhất trong 44 mang `mfPhase: 'mul'`.** Nó chạy sau mọi cơ chế
`add` ⇒ `(v + Σ add) × 1.3`, là kết quả **duy nhất** có thể xảy ra sau INV-5. Trước INV-5, cùng bộ
relic cho `v×1.3+1` hoặc `(v+1)×1.3` tuỳ thứ tự nhặt (chênh 1 damage/mặt ở `v=5`, và tới 1.5
damage/mặt ở `v=10` theo phép đo `ENG-0` của roster) — tức RP của `r_claw` **không phải một số**,
mà là một khoảng. Bất biến RP không có nghĩa cho tới khi điều đó được sửa.

### 6.5 ACTIVE (8 → 8) — định giá bằng `RP_act` (§4.4a), CÙNG THANG với passive

Nhắc lại ràng buộc quyết định, đã xác minh lại từ source: `s.turn++` ở `engine.js:632`, ngay dòng
sau là `s.usedActives=[]` (`:633`) → **mỗi active dùng 1 lần MỖI LƯỢT**, chặn duy nhất bởi
`if(s.usedActives.includes(id)||s.mana<it.act.cost) return false` (`:564`). Không có bất kỳ cơ chế
"1 lần/trận" nào trong engine.

| id | Tên | arch | `rar` | Hiệu ứng sau retune | `kind` | `V_out` (1 cast) | `N*` | **`RP_act`** | Δaim | Δ |
|---|---|---|---|---|---|---|---|---|---|---|
| `a_restore` | Anemone Restore | **shield** | **0 C** | `[MP 2]` Heal 1 Axie **9** HP (từ 10) | `heal` | 9×1.00×0.75 = 6.75 | 5 | **11.25** | 0.63 ✓ | **A T** |
| `a_freeze` | Cryo Spore | mana | **0 C** | `[MP 4]` Stun 1 địch | `stun` | 12×0.95 = 11.4 | 5 | **12.00** | 0.12 ✓ | **R** |
| `a_chaos` | Chaos Gene | mana | **1 R** | `[MP 1]` (từ 2) **+4** Reroll (từ +2) lượt này | `reroll` | 4×1.40 = 5.6 | 5 | **16.75** | 0.06 ✓ | **T R** |
| `a_wall` | Lunacia Wall | shield | **1 R** | `[MP 6]` (từ 3) **5** Shield (từ 8) cả party | `shieldall` | 5×5×0.86×0.85 = 18.28 | 4 | **16.00** | 0.81 ✓ | **T** |
| `a_plague` | Spore Bloom | poison | 2 E | `[MP 6]` (từ 4) Poison **3** (từ 8) mọi địch | `poisonall` | 4×(3+2+1)×0.90 = 21.6 | 3 | **24.30** | 2.10 ✓ | **T** |
| `a_chomp` | Chomp Strike | **pierce** | **2 E** | `[MP 3]` 12 damage xuyên giáp | `dmg` | 12×1.00 = 12.0 | 5 | **26.25** | 2.79 ✓ | **A R** |
| `a_nova` | Gene Nova | aoe | **3 L** | `[MP 8]` (từ 5) **10** (từ 12) damage mọi địch | `dmgall` | 4×10×0.95 = 38.0 | 2 | **34.00** | 4.62 ✓ | **T R** |
| `a_ult` | LUNACIA ULTIMA | **mana** | 3 L | `[MP 18]` (từ 10) 40 damage xuyên giáp + 10 Shield cả party | `ult` | 40 + 36.55 = 76.55 | 1 | **36.05** | 2.42 ✓ | **A T** |

`N*` = số lần cast tối ưu (§4.4a). Đơn điệu trong nội bộ actives: `12.00 < 16.00 < 24.30 < 34.00`
✓, và mọi giá trị nằm trong đúng `Band[rar]` chung với passive ⇒ INV-4 ✓.

**Bốn phát hiện mà VPM che mất, và cả bốn đều là chế độ hỏng owner mô tả:**

1. **`a_ult` (`RP_act` 95.0 ở MP 10) là mispricing lớn nhất toàn roster — gấp 2.2× trần LEGENDARY.**
   VPM chấm nó "+9%, đúng giá". Sai lầm là bỏ qua bão hoà: **hai** lần cast phủ trọn `D = 70` sát
   thương *và* trọn `T_in = 70` sát thương vào, hết 20/30 mana. Chỉ giá sửa được. **MP 18** ⇒
   `Θ = 1` ⇒ 36.05 ✓. Đây là thay đổi lớn nhất trong §6 và nó **phải** đi kèm ghi chú UI: `a_ult`
   trở thành thẻ một-lần-mỗi-trận trên thực tế, đúng nghĩa "ultimate".
2. **`a_wall` ở MP 6 / 8 Shield = 78.7 RP.** Một active `shieldall` spam được mỗi lượt tạo 200
   shield/trận trong một trận chỉ có 70 damage vào — 130 điểm ném đi, nhưng 70 điểm đầu **vô hiệu
   hoá toàn bộ sát thương của encounter**. Hạ xuống 5 Shield đưa `N*` về 4 và RP về 16.00.
3. **`a_chaos` ở +2 Reroll = 2.75 RP — 24% của một COMMON.** Phù hợp với ghi chú đo được tại
   `data.js:552` ("reroll ảnh hưởng gần như 0 tới winrate qua nhiều seed"). Ở +4 Reroll nó thành
   16.75 và **là một RARE thật**, không phải một COMMON chết.
4. **`a_freeze` không còn là outlier.** Ở mô hình cũ nó "lệch −37%" và phải được miễn trừ bằng tay.
   Với `RP_act` nó là **12.00 = một COMMON đúng dải** (lệch 0.12 so với đích CONDUIT COMMON), trong
   khi vẫn giữ nguyên MP 4 — tức lý do chống stun-lock (3/6 boss có `addCap: 0`) được **giữ nguyên
   mà không cần ngoại lệ nào**. Ngoại lệ biến mất vì mô hình đúng hơn, không vì luật lỏng hơn.
   K10 vì vậy không còn là knob "cố tình sai giá" mà là knob "chọn bậc": hạ về MP 3 sẽ đẩy
   `RP_act` lên 20.25 = RARE, và mở lại stun-lock.

**Retag `a_restore` `mana → shield` — sửa §5.4.** Luật §5.4 cũ đẩy `heal`/`stun`/`reroll`/`ult` về
`mana` làm fallback. Nhưng `heal` **có** archetype output: nó là giảm thiểu sát thương, tức
BULWARK. Giữ nó ở `mana` đẩy CONDUIT lên **11 relic**, vượt trần 10 của §5.1. Luật §5.4 sửa thành:
`heal → shield`; `stun`/`reroll`/`ult` giữ fallback `mana`. Sau sửa: CONDUIT 10, BULWARK 10 ✓.

**Ba lưu ý engine cho actives, đã verify lại từ source (`engine.js:566-575`):**
- `kind:'ult'` **hardcode `applyShield(t, 10)`** (`:569`) — `act.v` chỉ điều khiển damage. Vì vậy
  `a_ult` **chỉ có `cost` là knob**; đó là lý do bản sửa dùng giá chứ không dùng payload.
- `kind:'poisonall'` **có** truyền source (`addStatus(...,u)`, `:572`) → VIRULENT +2 của Bug áp dụng
  → `a_plague` với 2 Bug là `RP_class` ≈ 1.6× ✓ dưới trần 2.2.
- `kind:'stun'` **không** truyền source (`addStatus(s,tgt,['stun'])`, `:573` — thiếu tham số thứ 4).
  Vô hại hôm nay; §11 mục 8.

**Ba lưu ý engine cho actives, đã verify:**
- `kind:'ult'` **hardcode `applyShield(t, 10)`** trong `engine.js:569` — `act.v` chỉ điều khiển
  damage. Một active `ult` thứ hai **không thể** đặt lượng shield khác mà không sửa engine.
- `kind:'poisonall'` **có** truyền source (`addStatus(..., u)`) → VIRULENT +2 của Bug áp dụng
  → `a_plague` với 2 Bug là `RP_class` ≈ 1.6× ✓ dưới trần 2.2.
- `kind:'stun'` **không** truyền source (`addStatus(s,tgt,['stun'])`, thiếu tham số thứ 4) —
  vô hại hôm nay (`stun` không đọc `src`) nhưng là bất nhất cần sửa trước khi có relic nào
  đọc `src` trong nhánh stun. §11 mục 8.

### 6.6 Tổng hợp thay đổi trên 44 relic + kiểm INV-1

| Loại thay đổi | Số relic | ID |
|---|---|---|
| **Không đổi gì** (`=`) | **4** | `r_openwound` `r_swarmnest` `r_apexpredator` `r_bloodpact` `r_stormcall` |
| Retune số (`T`) | 24 | `r_carapace` `r_bloodmouth` `r_wildfire` `r_heart` `r_spines` `r_luckycharm` `r_ember` `r_deathmark` `r_hivemind` `r_fang` `r_voidgene` `r_regrow` `r_bastionplate` `r_hollowbone` `r_pyroclasm` `r_chainreact` `r_growthcore` `r_infinitedie` `r_plaguelord` `r_mirrorshell` `r_solarcore` `r_soulforge` `r_manaflood` `r_ancientgene` `a_restore` `a_chaos` `a_wall` `a_nova` `a_plague` `a_ult` |
| Retag (`A`) | 5 | `r_claw` `r_bloodmouth` `r_heart` `r_infinitedie` `a_chomp` `a_ult` `a_restore` |
| Đổi rarity (`R`) | **17** | `r_pierceall`↓ `r_cleaveall`↓ `r_bloodmouth`↓ `r_wildfire`↓↓ `r_heart`↑ `r_ear`↑ `r_deathmark`↓ `r_holyfont`↓ `r_hivemind`↓ `r_fang`↑ `r_voidgene`↓↑ `r_regrow`↑ `r_infinitedie`↓ `r_echostone`↑ `r_venomengine`↑ `r_mirrorshell`↑ `r_manaflood`↑ `a_freeze`↓ `a_chaos`↑ `a_chomp`↑ `a_nova`↑ |
| **Thay chức năng** (`F`) | **2** | `r_voidgene` (§7 E1 + INV-7), `r_cleaveall` (INV-7 — xem §6.1) |
| Bị xoá | **0** | — |
| Đổi id | **0** | — |

**Kiểm INV-1 trên 44 relic sau retune (đây là phép kiểm phải chạy được bằng máy, AC-15):**

| bậc | `Band[r]` | min RP đo | max RP đo | relic biên dưới | relic biên trên | khoảng cách tới bậc trên |
|---|---|---|---|---|---|---|
| 0 COMMON | [11.22, 15.18] | **11.25** | **15.00** | `a_restore` | `r_cleaveall` | 15.00 → 15.89 = **0.89 RP** ✓ |
| 1 RARE | [15.89, 21.48] | **16.00** | **19.99** | `a_wall` | `r_wildfire` | 19.99 → 22.44 = **2.45 RP** ✓ |
| 2 EPIC | [22.44, 30.36] | **22.50** | **29.55** | `r_fang`/`r_bastionplate` | `r_pyroclasm` | 29.55 → 31.77 = **2.22 RP** ✓ |
| 3 LEGENDARY | [31.77, 42.97] | **33.81** | **41.98** | `r_soulforge` | `r_apexpredator` | — |

⇒ `max(C) 15.00 < min(R) 16.00 < max(R) 19.60 < min(E) 22.50 < max(E) 29.55 < min(L) 33.81`.
**Không tồn tại cặp relic nào trong 44 mà bậc thấp hơn có RP cao hơn.** Đây là phát biểu định
lượng cho yêu cầu của product owner, và nó đúng cho **mọi** cặp archetype, không chỉ trong cùng
archetype (INV-1 toàn cục).

**Trước bản sửa này, đo trên chính các con số của §6 draft trước với dải mới và phơi nhiễm đúng
(§4.4b): 24/44 relic vi phạm INV-1** — 3 COMMON (`r_carapace` 10.96 dưới sàn, `r_cleaveall` 3.57
sau khi sửa phơi nhiễm, `r_bloodmouth` 10.43), 4 RARE (`r_heart` 15.00 vùng cấm, `r_fang` 22.50 ở
bậc RARE, `r_wildfire` 9.69, `r_deathmark` 15.80 vùng cấm), 7 EPIC (`r_voidgene` 17.89,
`r_regrow` 20.80, `r_holyfont` 18.30, `r_hollowbone` 35.00, `r_growthcore` 21.50, `r_hivemind`
18.50, `r_infinitedie` 22.00 vùng cấm), 2 LEGENDARY (`r_soulforge` 30.90 vùng cấm, `r_manaflood`
30.00), và **8/8 ACTIVE** (mọi active đều sai bậc dưới `RP_act`). **Sau bản sửa: 0/44.**

Con số "35/44 nằm ngoài ±20% của bậc mình" trong bản trước vẫn đúng và không mâu thuẫn: nó đo
**lệch đích**, còn 24/44 đo **vi phạm đơn điệu**. Cái thứ hai nghiêm trọng hơn vì nó là thứ người
chơi nhìn thấy trực tiếp qua màu rarity.

### 6.7 AUDIT 48 relic của `relic-roster-expansion.md` — THAY ĐỔI BẮT BUỘC

> **Doc này KHÔNG sửa `design/gdd/relic-roster-expansion.md`.** Bảng dưới là danh sách thay đổi
> đủ chính xác để một pass sau áp **nguyên văn**, không cần hỏi lại. Cột `RP trước` tính theo
> §4.4/§4.4a/§4.4b trên **đúng hiệu ứng roster đã viết**; cột `RP sau` là kết quả của thay đổi
> được kê. Mọi `RP sau` đều nằm trong `Band[rar sau]` (§4.6.1) ⇒ INV-1 ✓.
>
> **Kết quả tổng: 37/48 relic mới vi phạm INV-1 trước audit; 0/48 sau khi áp bảng này.**
> 11 relic PASS nguyên trạng: `r_talonedge`¹ `r_marrowdrill` `r_worldpiercer` `a_bloom`
> `r_broodpouch` `r_scalecrown` `r_gorehook` `r_scentofblood` `r_pandemic` `r_tinderbox`¹
> `r_bloodhymn`. (¹ hợp dải nhưng vẫn phải đổi vì AC-4 phủ bậc — ghi rõ ở cột "Lý do".)

#### 6.7.1 PIERCE — TALON (đích C 14.52 · R 20.55 · E 29.04 · L 41.11)

| id | rar trước | RP trước | Chẩn đoán | **THAY ĐỔI BẮT BUỘC (áp nguyên văn)** | rar sau | RP sau | Δaim |
|---|---|---|---|---|---|---|---|
| `r_talonedge` | 0 C | 15.00 | Hợp dải, nhưng TALON chỉ còn **1 RARE** ⇒ vi phạm AC-4 (cần ≥2) | Đổi `rar: 0 → 1`. Hiệu ứng thành: **"Mọi mặt `dmg` đã có `pierce` +2 damage; mọi mặt `horn` type `dmg` +1 damage."** (`modFace`, `mfPhase:'add'`) | 1 R | **20.55** | 0.00 |
| `r_marrowdrill` | 1 R | 19.13 | ✓ PASS | Không đổi. Thêm `mfPhase:'kw'`, `mload:0`, `ex:[]` | 1 R | 19.13 | 1.42 |
| `r_thousandcuts` | 2 E | **≈0** | **Vi phạm §7 E1 (điều kiện tần suất 0).** "Đánh 2 lần nửa damage" là *trung hoà damage*; toàn bộ giá trị đến từ bonus-phẳng-mỗi-đòn, mà party chuẩn (không Bird, không `piercePlus`) có **0** bonus phẳng ⇒ relic đáng giá 0 RP | Đổi hiệu ứng: mỗi đòn trong hai đòn gây **`ceil(f.v/2) + 2`** (thay vì `ceil(f.v/2)`). Tách thành 2 entry `modFace`: `mfPhase:'kw'` (thay `multi:N` → `multi:2N`, hoặc push `multi:2`) và `mfPhase:'add'` (`f.v = ceil(f.v/2)+2`) — xem INV-5 | 2 E | **30.00** | 0.96 |
| `r_worldpiercer` | 3 L | 42.86 | ✓ PASS nhưng **cách trần 0.12 RP** | Không đổi số. **Ghi cảnh báo**: mọi thay đổi tương lai với `KW(pierce)` hoặc `piercePlus` sẽ đẩy relic này ra khỏi dải. `mload:1`, `ex:['pierceInjectAll']` | 3 L | 42.86 | 1.75 |
| `r_dawnlance` | 3 L | **6.80** | Điều kiện "mục tiêu **full** HP" chỉ đúng ~30% số đòn pierce ⇒ 17% của một LEGENDARY. Đối xứng với FERAL bị hỏng: FERAL áp cho **mọi** đòn, `r_dawnlance` chỉ áp cho đòn `pierce` | Đổi thành: **"Mọi đòn đánh vào mục tiêu còn **trên 50% HP** gây thêm 90% damage."** (`modDmg`, không cần `ENG-1` nữa vì chỉ đọc `tgt`). Đặt **`mload: 2`**, `ex:['dmgMultCond']` — đây là multiplier toàn cục có điều kiện, cùng hạng `r_bloodpact` | 3 L | **38.90** | 2.21 |
| `a_pinning` | 1 R | 11.25 | Damage = shield phá được ⇒ 0 trước địch không giáp; kỳ vọng `V_out` chỉ 9.0 | Đổi mô tả act thành: **"[MP 3] Phá toàn bộ Shield của 1 địch và gây damage bằng lượng Shield đã phá, **tối thiểu 6**."** (`kind:'shatter'`, ENG-13 giữ nguyên). `V_out` 10.50, (`N* = 5`) — §6.7.10 | 1 R | **18.75** | 1.80 |

#### 6.7.2 GROWTH — EVOLVE (đích C 13.20 · R 18.68 · E 26.40 · L 37.37)

| id | rar trước | RP trước | Chẩn đoán | **THAY ĐỔI BẮT BUỘC** | rar sau | RP sau | Δaim |
|---|---|---|---|---|---|---|---|
| `r_seedling` | 0 C | **3.14** | `growthPlus:1` chỉ áp cho mặt **đã có** `growth` (`p_eff` = 0.20) ⇒ 24% của một COMMON. §4.5 ví dụ 5 đã chứng minh `growth` gần vô giá trị ở `Ω=5` | Thêm mệnh đề **`growthAll: 1`** (§10 G1): *"Đầu mỗi lượt, mọi mặt của mỗi Axie mạnh thêm 1 (vĩnh viễn trong trận); và mặt có `growth` tăng 2 thay vì 1."* Gate: **ENG-2 + G1** (G1 chuyển từ tuỳ chọn sang **bắt buộc**) | 0 C | **13.70** | 0.50 |
| `r_heartwood` | 1 R | **1.76** | 1 mặt ngẫu nhiên/Axie/lượt = 1/6 của `growthAll:1` ⇒ 9% của một RARE | Đổi thành **`growthAll: 2`** từ lượt 2: *"Từ lượt 2, mọi mặt của mỗi Axie mạnh thêm 2 vĩnh viễn trong trận."* Bỏ `ri(6)` ⇒ **không còn tiêu RNG**, tất định tuyệt đối. Gate: **G1** | 1 R | **21.12** | 2.44 |
| `r_bloomscale` | 1 R | **4.35** | Tiêm `growth` vào `back`+`eyes` = `p` 0.277 × 15.7 RP/đơn vị phơi nhiễm | Giữ mệnh đề tiêm, **thêm `growthPlus: 3`**: *"Mọi mặt `back` và `eyes` nhận `growth`; mặt có `growth` tăng **4** thay vì 1."* (`growthPlus` là `rsum` ⇒ cộng dồn với `r_seedling`, **không** dead draw, không cần `ex`) | 1 R | **20.05** | 1.37 |
| `r_quickenroot` | 2 E | **33.30** | Nằm trong `Band[3]`. `onRollEnd` đặt +1 growth lên đúng mặt sắp dùng ⇒ `+1` damage **ngay lượt đó** × 5 Axie × 5 lượt, cộng tích luỹ | Thêm guard **`if(s.turn <= 1) return;`** — chỉ chạy từ lượt 2 | 2 E | **28.30** | 1.90 |
| `r_worldtree` | 3 L | **≈70** | `growthKeep` **không có trần** và là relic duy nhất tích luỹ qua các trận. Đây chính là rủi ro 17.6 #1 mà roster tự ghi nhận là "chưa đo" | Thêm trần cứng vào ENG-3: **`re.grown[k]` không bao giờ vượt 3** (`re.grown[k] = Math.min(3, seeded + Math.floor(earned/2))`). Viết `GROWTH_KEEP_CAP = 3` thành hằng có tên trong `data.js`. `mload: 1` | 3 L | **39.60** | 2.23 |
| `a_bloom` | 2 E | 29.25 | ✓ PASS. Active **duy nhất** trong 8 cái mới không phải đổi giá | **Không đổi.** Giá chốt **[MP 5]** — audit bản trước không ghi cost nên `t_relic` phải mượn từ roster; nay ghi tại đây. `V_out` 21.00, `Sat_grow` 63.00, (`N* = 3`) — §6.7.10 | 2 E | 29.25 | 2.85 |

#### 6.7.3 SUMMON — SWARM (đích C 11.88 · R 16.81 · E 23.76 · L 33.63)

| id | rar trước | RP trước | Chẩn đoán | **THAY ĐỔI BẮT BUỘC** | rar sau | RP sau | Δaim |
|---|---|---|---|---|---|---|---|
| `r_broodpouch` | 0 C | 13.00 | ✓ PASS | Không đổi | 0 C | 13.00 | 1.12 |
| `r_eggshell` | 1 R | **21.90** | Vùng cấm (21.48 – 22.44) | `applyShield(s, u, 3)` → **`applyShield(s, u, 2)`**; mô tả: *"mỗi Axie Egg nhận 2 Shield đầu mỗi lượt"* | 1 R | **16.40** | 0.41 |
| `r_broodmother` | 1 R | **9.75** | Cap 4 token nuốt phần lớn số lần nở ⇒ chỉ +1.5 egg-lượt hữu ích | Thêm mệnh đề: *"…và mọi Axie Egg gây thêm **1** damage."* (áp một lần cho mỗi token qua cờ `u.eggDmg`, cùng khuôn `r_apexbrood`) | 1 R | **18.50** | 1.69 |
| `r_apexbrood` | 2 E | **20.50** | Dưới sàn EPIC | `maxHp += 4` → **`maxHp += 8`**; giữ `dmg += 2`. Mô tả: *"Axie Egg có thêm **8** Max HP và gây thêm 2 damage."* | 2 E | **23.50** | 0.26 |
| `r_hivequeen` | 3 L | **12.10** | **36% của một LEGENDARY.** Roster đã tự nghi ngờ ("có thể *quá* nhẹ"). Nguyên nhân đo được: kế thừa class chỉ có tác dụng thật với 2/6 class, và copy **1** mặt lên die 6 mặt của egg chỉ đổi ~1/6 số lần roll | Đổi hiệu ứng thành: **"Axie Egg của bạn nhận mọi hiệu ứng `modFace` của bạn; số Egg tối đa cùng lúc lên 6."** Bỏ mệnh đề class/HP/copy-face. Đặt **`mload: 2`**, `ex: ['eggInherit']`. Lưu ý §7 E9: đây là **cố ý** mở cánh cửa E9 đóng, và `mload 2` là giá của nó — relic này loại trừ mọi multiplier khác | 3 L | **38.00** | 4.37 |
| `a_clutch` | 1 R | **34.00** | Nằm trong `Band[3]`: 2 egg/lượt tới cap 4 là 52 RP giá trị token cho 8 mana | `v: 2` → **`v: 1`**; mô tả *"[MP 4] Summon 1 Axie Egg."* (`kind:'summon'`, ENG-12 giữ nguyên). `V_out` 13.00, `Sat` 52.00, (`N* = 4`) — §6.7.10 | 1 R | **16.00** | 0.81 |

#### 6.7.4 THORNS — AEGIS (đích C 12.10 · R 17.12 · E 24.20 · L 34.26)

| id | rar trước | RP trước | Chẩn đoán | **THAY ĐỔI BẮT BUỘC** | rar sau | RP sau | Δaim |
|---|---|---|---|---|---|---|---|
| `r_barbedhide` | 0 C | **17.00** | Nằm trong `Band[1]` (`thornsPlus:2` = `H × 2 × κ_def`) | `thornsPlus: 2` → **`thornsPlus: 1`**, thêm rider *"và mọi mặt `shield` +1"* (`modFace`, `mfPhase:'add'`). Mô tả: *"Thorns của bạn gây thêm 1 damage; mọi mặt `shield` +1."* ENG-4 giữ nguyên (cộng **sau** khi nhân) | 0 C | **13.98** | 1.88 |
| `r_bloodthorn` | 1 R | **14.00** | Dưới sàn RARE | Thêm rider *"và mọi mặt `shield` +1"*. **Đồng thời đổi hook `onThorns` → `onDmgTaken`** (QĐ-2 đã duyệt): *"khi một Axie bị đánh, nó hồi máu bằng 1/3 Thorns của chính nó"* — cùng số, và **gỡ `r_bloodthorn` khỏi danh sách gate của ENG-5** | 1 R | **19.48** | 2.36 |
| `r_glassspine` | 1 R | **23.80** | Nằm trong `Band[2]`. Đồng thời AEGIS chỉ có **1 EPIC** ⇒ vi phạm AC-4 | Đổi `rar: 1 → 2`. Hiệu ứng giữ nguyên (sàn Thorns 4 khi được cấp Shield). `ex: ['thornsFloorShield']` — **chấp nhận đề nghị D1 của roster**: tách khỏi `thornsFloorFlat` vì sàn-có-điều-kiện-4 nằm *trên* sàn-vô-điều-kiện-2 và cả hai cùng đóng góp | **2 E** | 23.80 | 0.40 |
| `r_retributor` | 2 E | **34.00** | Nằm trong `Band[3]`: `th 4 → d 2` × 2 lân cận × `H = 10` | Thêm điều kiện: **chỉ kích hoạt khi Axie bị đánh đang còn Shield** (`tgt.shield > 0`). Mô tả: *"Khi Thorns của một Axie **đang có Shield** gây damage, hai địch cạnh kẻ tấn công cũng nhận 1/3 lượng đó."* | 2 E | **23.80** | 0.40 |
| `r_ironmaiden` | 3 L | **66.50** | **Vi phạm nặng nhất toàn roster mới — 155% trần LEGENDARY.** `min(12, thorns) × 4 địch × 5 lượt` = 240 damage danh nghĩa, bão hoà ở `D = 70`, tức relic này **một mình kết thúc encounter** | Đổi phạm vi từ *mọi địch* thành **một địch (nhiều HP nhất)**, và cap **12 → 7**. Mô tả: *"Đầu mỗi lượt, địch có nhiều HP nhất nhận damage bằng Thorns cao nhất của bạn, tối đa **7**."* Viết `IRONMAIDEN_CAP = 7` thành hằng có tên (roster 17.6 #2 tự yêu cầu điều này) | 3 L | **33.25** | 1.01 |
| `r_scalecrown` | 3 L | 39.50 | ✓ PASS về RP. **Nhưng sàn `st.thorns = Math.max(…, 2)` của nó TRÙNG KHÍT với `r_spines`** — cùng luật, cùng N ⇒ giữ cả hai thì một cái đóng góp đúng 0 (§3.7a cặp 1) | Không đổi số. **Bắt buộc `ex: ['thornsFloorFlat']`** (D1 đã duyệt, §17.2 đã gán, bản ship bỏ sót). Giữ nguyên quyết định **không truyền `src`** vào `addStatus` (chặn VIRULENT/`poisonSpread`) | 3 L | 39.50 | 5.24 |
| `a_bramblewall` | 1 R | **27.25** | Nằm trong `Band[2]`: nâng Thorns từ ~2 lên 6 = +4 × `H` × `κ_def` | `kw: 'thorns:6'` → **`kw: 'thorns:5'`**. Mô tả: *"[MP 3] Thorns của mọi Axie thành ít nhất **5**."* Giữ `mode:'min'` (idempotent — đây là điều kiện tồn tại của thẻ, và nó là lý do `Sat = V_out` ⇒ (`N* = 1`), §6.7.10) | 1 R | **18.75** | 1.63 |

#### 6.7.5 EXEC — FERAL (đích C 13.20 · R 18.68 · E 26.40 · L 37.37)

| id | rar trước | RP trước | Chẩn đoán | **THAY ĐỔI BẮT BUỘC** | rar sau | RP sau | Δaim |
|---|---|---|---|---|---|---|---|
| `r_gorehook` | 0 C | 11.88 | ✓ PASS | Không đổi. `mfPhase:'kw'` | 0 C | 11.88 | 1.32 |
| `r_scentofblood` | 1 R | 17.56 | ✓ PASS | Không đổi | 1 R | 17.56 | 1.12 |
| `r_cullingorder` | 1 R | **96.50** | **5.2× trần RARE.** `4.5 kill × 5 Axie × (3 heal + 3 shield)` = 67 heal + 67 shield/trận, trong khi `T_in = 70`. Relic này một mình vô hiệu hoá sát thương của encounter | Đổi phạm vi từ *mọi Axie* thành **một Axie (ít HP nhất)**, nâng số 3 → **4**. Mô tả: *"Mỗi khi một địch chết, Axie có ít HP nhất hồi 4 HP và nhận 4 Shield."* Đổi `rar: 1 → 2` (FERAL chỉ có 1 EPIC ⇒ vi phạm AC-4) | **2 E** | **25.70** | 0.70 |
| `r_deathspiral` | 2 E | **45.60** | Trên trần LEGENDARY. `12 × 4 địch × κ_choice` | `12` → **`7`**. Mô tả: *"Lần đầu mỗi địch tụt xuống dưới nửa HP, nó nhận ngay **7** damage."* Giữ `src=null` (chặn đệ quy `onHit`) | 2 E | **26.60** | 0.20 |
| `r_apexferal` | 3 L | **31.73** | Vùng cấm — **thiếu 0.03 RP** so với sàn LEGENDARY 31.76. Ca sách giáo khoa cho INV-3. **Thêm: nó là superset của `r_gorehook`** (31 ⊃ 17 mặt nhận `exec`, đo trên mặt thật) ⇒ §3.7a cặp 3 | Ngưỡng xử tử **10% → 15%** Max HP. Mô tả: *"…và địch nào còn **15%** HP hoặc ít hơn sẽ chết ngay."* **Bắt buộc `ex: ['execInjectAll']`** (§17.2 đã gán, bản ship bỏ sót), và `r_gorehook` nhận **`exSub: ['execInjectAll']`** — một chiều, xem §3.7a | 3 L | **35.06** | 2.31 |
| `a_coupdegrace` | 2 E | **36.25** | Nằm trong `Band[3]` (`N* = 3` ở MP 5) | `v: 22` → **`v: 14`**. Mô tả: *"[MP 5] Gây **14** damage cho 1 địch, có Execute."* ENG-14 giữ nguyên. `V_out` 16.94 = `14 × f_exec 1.21`, (`N* = 4`) — §6.7.10 | 2 E | **22.76** | 3.64 |

#### 6.7.6 POISON · BURN · SHIELD · MANA · CRIT · AOE

| id | arch | rar trước | RP trước | Chẩn đoán | **THAY ĐỔI BẮT BUỘC** | rar sau | RP sau | Δaim |
|---|---|---|---|---|---|---|---|---|
| `r_pandemic` | poison | 2 E | 23.80 | ✓ PASS | Không đổi | 2 E | 23.80 | 2.60 |
| `r_tinderbox` | burn | 0 C | 13.79 | ✓ PASS. (Draft trước đề nghị `+2 → +3`, `rar 0 → 1`; **đề nghị đó bị HUỶ** — sau khi AC-9 buộc `r_wildfire` ở lại RARE (§6.2), INFERNO cần `r_tinderbox` làm COMMON, và nó là relic burn duy nhất có `mload 0`) | **Không đổi.** Giữ `+2`, giữ `rar: 0`, `mload: 0` | 0 C | 13.79 | 0.73 |
| `r_hearthcore` | burn | 2 E | **40.00** | Nằm trong `Band[3]`. **Và** nó nhân dồn với `r_solarcore` (`burnMult:2`) thành **×4 output burn** — cặp compounding roster không phát hiện | Tick thứ hai chỉ gây **70%**: `burnTicks:2` + `burnTickRatio:0.7` trong ENG-7. Mô tả: *"Burn gây damage 2 lần mỗi lượt; lần thứ hai gây 70%."* `mload:1` (giữ) ⇒ với `r_solarcore` (`mload 1`) là 2 = hết trần ⇒ cặp ×2×1.7 = ×3.4 được **phép** nhưng loại trừ mọi multiplier khác | 2 E | **28.00** | 1.04 |
| `a_pyre` | burn | 1 R | **43.00** | Trên trần LEGENDARY (`N* = 3` ở MP 4) | `cost: 4 → 7`, `rar: 1 → 2`. Mô tả: *"[MP 7] Áp Burn 6 cho mọi địch."* (`N* = 2`) | **2 E** | **26.10** | 2.94 |
| `r_lastwall` | shield | 1 R | **12.75** | Nằm trong `Band[0]`. Một cứu mạng/lượt ≈ 0.6 cái chết chặn được/trận | Đổi **`rar: 1 → 0`**. Hiệu ứng giữ nguyên (nó là relic duy nhất cấp `undying`, §3.3 của roster) | **0 C** | 12.75 | 0.87 |
| `a_aegisfont` | shield | 2 E | **52.30** | 2.4× trần EPIC: `5 × 18 Shield` = 90/lượt trong trận chỉ có `T_in = 70` | `cost: 6 → 8`, `v: 18 → 8`. Mô tả: *"[MP 8] Cấp 8 Shield cho cả party."* (`N* = 2`) | 2 E | **22.48** | 1.28 |
| `r_tidalbrand` | mana | 1 R | **10.50** | Dưới sàn COMMON. **Và** trùng 100% với mệnh đề `mana → rerollup` của `r_voidgene` bản draft ⇒ dead draw §3.7 (đã được giải bằng cách đổi `r_voidgene`, §6.3) | Đổi **`rar: 1 → 0`**, thêm rider: *"Mọi mặt `ears` cũng cấp 1 Reroll; bạn bắt đầu mỗi trận với +1 Reroll."* Đây là **entry-point COMMON bắt buộc của CONDUIT** (§5.2 ghi chú ³ — phải là passive, không phải sink) | **0 C** | **11.90** | 0.02 |
| `r_manaspring` | mana | 2 E | **56.25** | 2.4× trần EPIC. `+5 mana/lượt × 5 lượt × R_mana 2.25` = 56 RP — gần **nhân đôi** thu nhập mana của cả trận | Bỏ phần scale theo số Axie. Mô tả: *"Đầu mỗi lượt, nhận thêm **2** Mana."* (`s.mana += 2`) | 2 E | **22.50** | 1.26 |
| `r_conduitcrown` | mana | 3 L | **11.00** | 35% của một LEGENDARY. `actReuse` chỉ nới **trần lượt**, mà nút cổ chai thật là **mana** ⇒ lợi ích thực chỉ là `Θ(c)` tăng cho active rẻ | Thêm mệnh đề: *"…và đầu mỗi lượt bạn nhận thêm **2** Mana."* `mload: 1` — **phê chuẩn đề nghị D3 của roster** (`actReuse` nhân output của active, bằng 0 nếu build không có active ⇒ multiplier phạm vi archetype) | 3 L | **33.50** | 0.13 |
| `r_keeneye` | crit | 0 C | **15.60** | Vùng cấm (15.18 – 15.88). **Và** APEX chỉ có 1 EPIC ⇒ AC-4 | Đổi `rar: 0 → 2`, thêm: *"…đòn crit đó gây thêm **4** damage."* Mô tả: *"Nếu không Axie nào roll ra crit trong lượt, đòn đánh đầu tiên của bạn crit và gây thêm 4 damage."* `ex:['critPity']` giữ nguyên. 🔒 **Field là `critFlatPity: 4`, KHÔNG phải `critFlat: 4`** — xem hộp ngay dưới §6.7.6 | **2 E** | **27.40** | 1.64 |
| `r_predatorpoise` | crit | 1 R | **12.60** | Nằm trong `Band[0]`. Nó **gỡ một hình phạt**, không cộng damage ⇒ giá trị bằng số crit cứu được qua reroll | Đổi **`rar: 1 → 0`**. Hiệu ứng giữ nguyên. Đây là **entry-point COMMON của APEX**, và nó `mload 0` nên cùng tồn tại được với `r_apexpredator` | **0 C** | 12.60 | 1.92 |
| `r_bloodhymn` | crit | 1 R | 20.05 | ✓ PASS | Không đổi. ENG-1 giữ nguyên (cần `crit` trong ctx của `onHit`) | 1 R | 20.05 | 0.50 |
| `r_shatterpoint` | crit | 2 E | **7.10** | 27% của một EPIC. Crit bỏ qua Shield chỉ đáng `D × p_crit × tỉ lệ shield hấp thụ` | Thêm: *"…và gây thêm **5** damage."* Mô tả: *"Đòn crit bỏ qua Shield và gây thêm 5 damage."* Vẫn **không** thêm `critBonus` (giữ `mload 0`, đúng lập luận §14 của roster) | 2 E | **29.38** | 0.34 |
| `a_perfectstrike` | crit | 1 R | **39.00** | Nằm trong `Band[3]` (`N* = 3` ở MP 4) | `cost: 4 → 5`, `v: 11 → 8`. Mô tả: *"[MP 5] Gây **8** damage cho 1 địch. Đòn này luôn crit."* (`N* = 4`) | 1 R | **19.00** | 1.55 |
| `r_gustwing` | aoe | 0 C | **19.88** | Nằm trong `Band[1]`: `cleaveRatio 0.5 → 0.75` là +50% trên toàn bộ phần splash của một build đã cam kết | Đổi **`rar: 0 → 1`**. Giữ `0.75` (roster đã lập luận đúng vì sao không phải `1.0`). `mload:1`, `ex:['cleaveRatio']` | **1 R** | 19.88 | 0.58 |
| `r_windlash` | aoe | 1 R | **21.55** | Vùng cấm — **vượt trần RARE 0.07 RP**. `p(mouth ∧ dmg) = 0.278` là slot damage rộng nhất game. **Thêm: mệnh đề tiêm `cleave` của nó là tập con của `r_stormcall`** (15 ⊂ 26 mặt) ⇒ §3.7a cặp 4 | Đổi `rar: 1 → 2`, thêm rider: *"…và mọi mặt `mouth` type `dmg` +1 damage."* Nhận **`exSub: ['cleaveInject']`** — một chiều: `r_stormcall` vẫn được đề nghị khi đang giữ relic này | **2 E** | **28.50** | 1.22 |
| `r_squallmark` | aoe | 2 E | **21.80** | Vùng cấm. Ba loại mặt `eyes` có giá trị rất khác nhau khi thêm `aoe`: `debuff` 10.84 · `heal` 7.08 · `buff`(thorns) 3.89 | Thu hẹp: **chỉ mặt `eyes` type `heal` hoặc `debuff`** (bỏ `buff`), đổi `rar: 2 → 1`. Mô tả: *"Mọi mặt `eyes` gây hiệu ứng chữa trị hoặc gây suy yếu đều nhận `aoe`."* Lợi ích phụ: bỏ nhánh `buff` cũng bỏ luôn một tương tác Direction Law phải kiểm | **1 R** | **17.91** | 1.39 |

> 🔒 **`r_keeneye`: PROSE THẮNG, và field phải là `critFlatPity` — không phải `critFlat`.**
> Mâu thuẫn nội tại: prose nói *"đòn crit **đó** gây thêm 4"* (chỉ đòn pity), còn field bản ship
> khai `critFlat`, vốn là `rsum` áp cho **mọi** đòn crit. Hai cách đọc là hai relic khác nhau.
>
> **Chọn prose, vì spec engine đã tách sẵn hai field — đây không phải lựa chọn khẩu vị.** ENG-21
> (roster §16) khai **hai** field: `critFlat` (mọi crit ⇒ `r_shatterpoint`) và `critFlatPity`
> (chỉ đòn mang cờ `src.pityCrit` ⇒ `r_keeneye`). Roster §17.4 còn phát biểu kết quả mong muốn
> bằng số: giữ cả hai relic thì **`+9` trên đòn pity, `+5` trên các crit khác**. Bản ship
> (`critFlat: 4`) cho `+9` trên **mọi** crit — không khớp bất kỳ tài liệu nào.
>
> **RP KHÔNG đổi, và chính cách đọc-theo-field mới là cách làm vỡ dải.** Mệnh đề `+4` được định giá
> **11.80 RP** (27.40 − 15.60) ⇒ ≈ **2.95 lần kích hoạt/trận**, dưới `Ω = 5`: đúng hình dạng của
> một đòn pity không phải lượt nào cũng nổ. Với cách đọc theo field thì **mỗi lượt đều có ít nhất
> một crit** (pity nổ khi không có crit tự nhiên; có crit tự nhiên thì chính nó ăn `+4`) ⇒ **≥ Ω = 5**
> lần kích hoạt ⇒ **≥ +20 RP** ⇒ **≥ 35.60 RP = `Band[3]`**: một EPIC đứng trong dải LEGENDARY,
> đúng khiếu nại §3.12 sinh ra để diệt. ⇒ Sửa ở **code**, không ở số (§11 mục 27).

#### 6.7.7 Hai entry MỚI bắt buộc cho PLAGUE (roster D4 chuyển quyết định cho doc này)

`relic-roster-expansion.md` §4.1/§18/D4 cố ý dừng poison ở **1 RARE, 0 COMMON** và đề nghị doc này
lấp bằng retag. **Retag không khả thi**: sau §6, không relic nào trong 44 có RP hợp bậc *và* cơ chế
đọc được là poison để chuyển sang. Superlinear Axis Law (§4.6.5) chặn mọi scaler poison ở dưới
EPIC. Vì vậy phải thêm **2 entry**, cả hai là `rule` phạm vi hẹp và **không tạo thêm một stack
poison nào ở bậc thấp**:

| id mới | Tên | arch | rar | Hiệu ứng chính xác | Field | RP | Δaim | `mload`/`ex` |
|---|---|---|---|---|---|---|---|---|
| `r_rotbite` | Rot Bite | poison | **0 C** | Mục tiêu đang có Poison nhận thêm **2** damage từ mọi đòn của bạn | `modDmg` | **13.79** | 0.59 ✓ | 0 / `poisonAmpFlat` |
| `r_rotmouth` | Rotmouth | poison | **1 R** | Mọi mặt `mouth` type `dmg` cũng áp `poison:2` | `modFace`(`f.k`), `mfPhase:'kw'` | **19.50** | 0.82 ✓ | 0 / — |

`r_rotbite` **phẳng**, `r_openwound` **phần trăm** ⇒ không trùng luật (chính xác cùng lập luận
roster §11 dùng cho `r_tinderbox` vs `r_openwound`), nhưng cả hai phải mang `ex` khác nhau
(`poisonAmpFlat` vs `poisonAmpPct`) để tránh gộp nhầm khi ai đó thêm relic thứ ba.
`r_rotmouth` áp `poison:2` **qua `hit()`** (mặt `dmg`) nên `src` được truyền ⇒ VIRULENT của Bug
**có** áp dụng; `RP_class` = 19.50 × 1.35 = 26.3 = 1.41× band ✓ dưới trần 2.2.

⇒ **Tổng roster hợp nhất: 44 + 48 + 2 = 94 relic** (78 passive + 16 active), không phải 84.
Mọi chỗ ghi "84 relic" trong doc này và trong `game-concept.md`/`bloodline-system.md` phải thành
**94** (§11 mục 13-14).

#### 6.7.8 Phủ archetype sau audit — kiểm AC-4

| archetype | C | R | E | L | passive | active | **tổng** |
|---|---|---|---|---|---|---|---|
| pierce TALON | 1 | 2 | 2 | 2 | 7 | 2 | **9** |
| growth EVOLVE | 1 | 2 | 2 | 2 | 7 | 1 | **8** |
| summon SWARM | 1 | 3 | 2 | 1 | 7 | 1 | **8** |
| thorns AEGIS | 1 | 2 | 2 | 3 | 8 | 1 | **9** |
| exec FERAL | 3 | 2 | 2 | 2 | 9 | 1 | **10** |
| poison PLAGUE | 1 | 2 | 2 | 2 | 7 | 1 | **8** |
| burn INFERNO | 1 | 2 | 2 | 1 | 6 | 1 | **7** |
| shield BULWARK | 2 | 2 | 2 | 1 | 7 | 3 | **10** |
| mana CONDUIT | 1 | **2** | **2** | 2 | 7 | 3 | **10** |
| crit APEX | 1 | 2 | 2 | 2 | 7 | 1 | **8** |
| aoe TEMPEST | 1 | 2 | 2 | 1 | 6 | 1 | **7** |
| **TỔNG** | 14 | 22 | 23 | 19 | **78** | **16** | **94** |

`max/min = 10/7 = 1.43 ≤ 1.6` ✓ · mọi archetype `≤ 10` ✓ · **mọi ô C≥1, R≥2, E≥2, L≥1 ✓ —
không còn ngoại lệ nào.**

**CONDUIT: câu hỏi mở đã ĐÓNG, và không bằng phương án (a) hay (b).** Draft trước ghi CONDUIT
thiếu một RARE passive và đề nghị hoặc (a) tước `safeReroll` khỏi `r_infinitedie`, hoặc (b) thêm
một entry mới. **Cả hai đều bị huỷ.** Khi INV-9 (§6.2a) buộc `r_voidgene` phải được định giá theo
cơ chế *thật sự tồn tại*, nó tự rơi từ EPIC xuống **RARE (16.25 RP)**, và ô trống tự lấp:
`R = r_ear + r_voidgene`, `E = r_infinitedie + r_manaspring`. **0 content mới, 0 cơ chế bị tước,
0 engine work.** Đây là bằng chứng cho luận điểm trung tâm của doc: khi mô hình định giá đúng, các
ô phủ archetype tự đúng theo — ép ô phủ bằng tay là dấu hiệu mô hình đang sai ở chỗ khác.

Ba thay đổi dây chuyền đã được phản ánh trong bảng trên và trong §6.1/§6.2/§6.7.6:
`r_voidgene` E → **R** (INV-9) · `r_wildfire` C → **R** (AC-9, `mload 1 ⇒ rar ≥ 1`) ·
`r_tinderbox` giữ nguyên **C** (huỷ đề nghị → R, vì INFERNO cần một COMMON `mload 0`).

#### 6.7.9 PHÊ CHUẨN `mload` / `ex` cho toàn bộ 94 relic — ai sở hữu con số nào

Mục này đóng khoảng trống mà `tools/t_relic.mjs` báo là `UNDERSPECIFIED`: *"48 of 94 relics carry no
`mload`/`ex` declaration"*. Câu đó **đúng về doc này** và **sai về hệ hai-doc**: §3.11 đã giao quyền
gán `mload`/`ex` cho relic **mới** sang `relic-roster-expansion.md`, và roster §17.2 có bảng đầy đủ.

**Đo bằng máy trên bản ship** (không đếm tay — xem §13 ghi chú phương pháp):

| Nguồn khai báo | Số relic |
|---|---|
| Doc này §6.1-§6.4 (36 passive) + §6.7.7 (2 PLAGUE) | **38** |
| `relic-roster-expansion.md` §17.2 (50 relic mới) | **50** |
| Hợp (2 entry PLAGUE nằm ở cả hai) | **86** |
| **Không có khai báo ở đâu cả** | **8** |
| Bất đồng giữa hai doc | **0** |
| Lệch giữa doc và bản ship | **2** |

**Phê chuẩn 1 — 48 relic của roster: RATIFY `relic-roster-expansion.md` §17.2 nguyên trạng.**
Bảng đó là **nguồn duy nhất** cho `mload`/`ex` của 50 entry mới (§3.11). Doc này **không** chép lại
48 dòng: hai bản sao của cùng một dữ liệu sẽ trôi khỏi nhau, và trôi lệch `mload` là trôi lệch một
bất biến. Phép đo xác nhận hai doc **không mâu thuẫn một dòng nào**, nên phê chuẩn bằng tham chiếu
là an toàn. Giá trị suy luận của pass implement trùng khớp §17.2 ở **48/50** entry — tức các lớp cơ
chế §3.6/§3.7 đủ chặt để tái tạo được, đây là kết quả tích cực chứ không phải may mắn.

**Phê chuẩn 2 — 8 relic còn thiếu là 8 ACTIVE GỐC, và chúng được chốt bằng LUẬT, không bằng bảng.**
`a_restore` `a_freeze` `a_chaos` `a_wall` `a_plague` `a_chomp` `a_nova` `a_ult` — §6.5 không có cột
`mload`/`ex`, và roster không sở hữu relic cũ. Cả 8 đang ship `mload 0`, `ex []`. **Phê chuẩn, và
nâng thành luật cho cả 16 active:**

```
LUẬT ACTIVE (§3.1 loại `act`):   mload(active) = 0   ∧   ex(active) = []
```

Suy ra từ hai mệnh đề đã có, không phải quy ước mới:
1. **`mload = 0`** — §3.6 xếp `act` vào nhánh 0 tường minh (*"cộng phẳng, thêm keyword,
   engine-starter, **active***"). Không active nào mang `dmgMult`/`dr`/`critMult`/`critBonus`/… ;
   payload của chúng là `act:{cost,kind,v,…}`, engine đọc **một lần mỗi lần cast**, không gộp.
2. **`ex = []`** — `ex` chỉ cần khi engine gộp hai nguồn bằng `rmax`/`||` (§3.7). Không active nào
   khai field thuộc nhóm đó.

> **Ca duy nhất đáng nghi, đã kiểm và KHÔNG phải trùng luật:** `a_bramblewall` đặt sàn
> `thorns ≥ 5`, còn `r_spines`/`r_scalecrown` đặt sàn `thorns ≥ 2`. Ba nguồn cùng ngữ nghĩa "sàn"
> nhưng **không** dead-draw: `5 > 2` nên cả hai tầng đều đóng góp, và active phải **trả mana mỗi
> lần**, còn passive chạy mọi lượt miễn phí. Idempotence của `a_bramblewall` là **với chính nó**
> (cast lần hai trong cùng trận = 0, vì `thorns` không decay), và điều đó đã được tính vào giá qua
> `Sat = V_out` ⇒ `N* = 1` (§6.7.10) — **không** qua một `ex` token.

**Sửa 3 — hai lệch doc↔ship, cả hai là `ex` bị bỏ sót lúc implement, cả hai là bug thật:**

| id | Doc nói | Bản ship | Hệ quả |
|---|---|---|---|
| `r_scalecrown` | `ex: ['thornsFloorFlat']` (§17.2, D1 đã duyệt) | `ex: []` | `thornsFloorFlat` chỉ còn **1 chủ** (`r_spines`) ⇒ pool đề nghị cả hai ⇒ một cái đóng góp **đúng 0** (§3.7a cặp 1) |
| `r_apexferal` | `ex: ['execInjectAll']` (§17.2) | `ex: []` | superset của `r_gorehook` không mang token ⇒ `exSub` không có gì để trỏ tới (§3.7a cặp 3) |

Cả hai **không đụng RP** (`ex` không vào công thức §4.4) ⇒ **INV-1 không đổi, 94/94 giữ nguyên**.
Sửa ở code, kê ở §11 mục 24-25.

**Cảnh báo cho lần dọn dẹp tiếp theo:** đo trên bản ship, **35/36 token có đúng một chủ**. Đừng suy
ra "một chủ ⇒ vô dụng ⇒ xoá" — §3.7a liệt kê ba lý do token một chủ vẫn đang làm việc, và cú dọn
đó sẽ mở lại đúng những cặp dead-draw hệ này sinh ra để chặn.

#### 6.7.10 `V_out` / `N*` cho 8 active MỚI — `RP_act` giờ tái dẫn xuất được bằng máy

§6.7.1-§6.7.6 kê `RP_act` **sau** audit nhưng không kê `V_out`/`N*`, nên 7 active không thể tái dẫn
xuất (`t_relic` báo `UNDERSPECIFIED`). Bảng này bổ sung đúng phần thiếu. **Không con số cân bằng nào
đổi**: mọi `RP_act` dưới đây bằng đúng giá trị §6.7 đã chốt.

Công thức là §4.4a nguyên văn: `RP_act = max_{N=1..Θ(c)} [ Σ_i min(N × V_i, Sat_i) − N × 2.25 × c ]`,
`Θ(c) = min(Ω 5, ⌊M_com 30 / c⌋)`.

| id | `kind` | MP `c` | `V_out` (1 lần cast) | `Sat` | `Θ(c)` | `N*` | `RP_act` | dải |
|---|---|---|---|---|---|---|---|---|
| `a_pinning` | `shatter` | 3 | `0.25×6 + 0.75×12` = **10.50** | `D` 70 | 5 | **5** | **18.75** | R ✓ |
| `a_clutch` | `summon` | 4 | **13.00** (1 egg) | **52.00** | 5 | **4** | **16.00** | R ✓ |
| `a_bramblewall` | `kw` min | 3 | `(5−2)×10×0.85` = **25.50** | **25.50** | 5 | **1** | **18.75** | R ✓ |
| `a_perfectstrike` | `dmg` | 5 | `8×2.00×1.00` = **16.00** | `D` 70 | 5 | **4** | **19.00** | R ✓ |
| `a_coupdegrace` | `dmg` | 5 | `14×1.21` = **16.94** | `D` 70 | 5 | **4** | **22.76** | E ✓ |
| `a_pyre` | `kw` add | 7 | `4×(6+3+2+1)×0.60` = **28.80** | `D` 70 | 4 | **2** | **26.10** | E ✓ |
| `a_bloom` | `grow` | 5 | `15×1.40` = **21.00** | **63.00** | 5 | **3** | **29.25** | E ✓ |
| `a_aegisfont` | `shieldall` | 8 | `5×8×0.86×0.85` = **29.24** | `T_in` 70 | 3 | **2** | **22.48** | E ✓ |

**Vì sao tin được bảng này: nó tái tạo cả cột `RP trước` mà nó không được cho xem.** Mỗi `V_out`
được dẫn từ cơ chế bằng hằng §4.0/§4.2, rồi **thay số của bản TRƯỚC audit** vào cùng công thức:

| id | thay số bản trước | `RP_act` mô hình cho ra | §6.7 ghi `RP trước` |
|---|---|---|---|
| `a_pinning` | `V_out` 9.00 (không có sàn 6) | 11.25 | **11.25** ✓ |
| `a_clutch` | `v: 2` ⇒ `V_out` 26.00 | 34.00 | **34.00** ✓ |
| `a_bramblewall` | `thorns:6` ⇒ `(6−2)×10×0.85` = 34.00 | 27.25 | **27.25** ✓ |
| `a_perfectstrike` | MP 4, `v: 11` ⇒ 22.00 | 39.00 (`N* = 3`) | **39.00** (`N* = 3`) ✓ |
| `a_coupdegrace` | `v: 22` ⇒ 26.62 | 36.25 (`N* = 3`) | **36.25** (`N* = 3`) ✓ |
| `a_pyre` | MP 4 | 43.00 (`N* = 3`) | **43.00** (`N* = 3`) ✓ |
| `a_aegisfont` | MP 6, `v: 18` ⇒ 65.79 | 52.29 | **52.30** ✓ (lệch 0.01 làm tròn) |
| `a_bloom` | không đổi ⇒ `RP trước` = `RP sau` | 29.25 | **29.25** ✓ |

**Tám trên tám khớp, kèm cả `N*` ở ba ca doc có ghi.** `V_out` được khớp với cột `RP sau`; cột
`RP trước` **không hề tham gia vào việc khớp** — nó là tập kiểm chứng giữ riêng (held-out). Một bộ
`V_out` dò ngược cho vừa 8 con số `RP sau` không có lý do gì trúng thêm 8 con số `RP trước` bằng
**cùng** công thức khi thay số của bản cũ. ⇒ Đây là **mô hình gốc được khôi phục**, không phải số
dò ngược. Kiểm bằng máy, có gate đột biến theo AC-25(b)/(d).

**Ba hằng mới, khai báo tường minh vì chúng là knob, không phải sự thật:**

| Hằng | Giá trị | Neo | Ảnh hưởng |
|---|---|---|---|
| `V_egg` | **13.00** | §6.7.3 tự ghi *"2 egg/lượt tới cap 4 là **52** RP"* ⇒ `52 / 4` | giá của `a_clutch`, `r_broodpouch`, `r_swarmnest` |
| `Sat_grow` | **63.00** | trần giá trị `growth` hiện thực hoá được trong trận `Ω = 5`; hiệu chuẩn tại `a_bloom` `N* = 3` | mọi active/relic `grow` |
| `f_exec` | **1.21** | `1 + 0.6 × 0.35` — `exec` cho `×1.6` trên ~35% số lần cast người chơi nhắm được mục tiêu dưới ngưỡng | `a_coupdegrace`, mọi active `exec` sau này |

⚠️ **`Sat` của `grow` và `summon` KHÔNG phải `∞`** — §4.4a đã sửa. Nếu để `∞`, giá trị tuyến tính
theo `N` ⇒ `N*` luôn bằng `Θ(c)` ⇒ `a_bloom` phải là `N* = 5` và `a_clutch` `N* = 5`, mâu thuẫn với
`N*` mà §6.7 đã chốt. Trần thật của chúng là **cấu trúc**: `summon` bị chặn bởi `tokenCap` (4 egg
× `V_egg` = 52.00), `grow` bị chặn bởi số lượt còn lại để tiêu giá trị đã trồng. `reroll` và `stun`
vẫn `∞` — chúng không có khái niệm "thừa".

⚠️ **`V_out` của `a_bramblewall` phụ thuộc `Th_0 = 2` (sàn Thorns nền, từ `r_spines`/SCALES).**
Đây là knob nhạy nhất trong bảng: nếu build **không** có nguồn Thorns nền thì `Δ = 5 − 0` ⇒
`V_out = 42.50` ⇒ `RP_act = 35.75` = **`Band[3]`**, tức thẻ RARE này đứng trong dải LEGENDARY.
Giá 18.75 vì vậy là giá **cho build AEGIS đã cam kết**, đúng nguyên tắc exposure §4.1 — nhưng nó
phải được ghi ra, vì một thay đổi tương lai xoá `r_spines` khỏi pool sẽ **âm thầm** đẩy thẻ này ra
khỏi dải. Ghi vào §9 như một ràng buộc kèm.

## 7. Edge Cases

**E1 — Relic no-op vì tiền đề không tồn tại (`r_voidgene`).**
`modFace` cũ đổi mặt `f.t==='blank'` thành mana. Nhưng `HEROES` **không có mặt `blank` nào**:
hằng `B` (`data.js:9`) chỉ xuất hiện trong `MON.die`/`BOSSES.die` và trong `axieToDie()` khi
Axie import có < 6 part (`engine.js:107`). Nên relic này đáng giá **0 RP** trong mọi run đội
hình chuẩn, và > 0 chỉ với Axie import thiếu part. → thay chức năng (§6.3).
**Luật rút ra, bắt buộc cho expansion:** mọi relic có điều kiện phải nêu **tần suất đo được**
của điều kiện đó trên `HEROES` + `FACE_POOL`; điều kiện tần suất 0 = relic 0 RP.

**E2 — `addStatus()` bỏ im lặng mọi keyword không nhận diện.**
Chuỗi `if/else-if` (`engine.js:382-401`) **không có `else` cuối**. Keyword không khớp nhánh nào
bị **bỏ lặng lẽ, không log, không throw**. Nạn nhân đã biết: `shieldself:N` — xuất hiện đúng
1 lần trong toàn `src/`, ở comment `data.js:6`, không có nhánh xử lý. **Không relic nào trong
doc này hay trong expansion được dùng `shieldself`.** Danh sách trắng keyword `addStatus` thực
sự tiêu thụ: `poison thorns regen burn blind weaken vulnerable stun freeze enrage undying`.
Ngoài 11 cái đó = no-op. Đây là AC-6.

**E3 — Nhánh `poison` của `doFace()` không bao giờ truyền `kwPure`.**
`engine.js:510-514` gọi `addStatus(s, tgt, p, u)` với `p` chỉ chứa `'poison:'+v`. Nên **mọi
keyword tiêm vào mặt type `poison` đều vô hiệu** — tooltip hiển thị, engine không làm gì. Ảnh
hưởng thực tế: `r_wildfire` tiêm `burn:3` vào mặt `tail`, và `tail` là slot của **cả** mặt
`dmg` **và** mặt `poison`. Vì vậy §6.2 bắt buộc lọc `f.t==='dmg'`, không chỉ `f.p==='tail'`.

**E4 — Thứ tự `modFace` đổi kết quả.**
`buildUnit:54` chạy `for(const r of rlist(s)) if(r.modFace) r.modFace(u)` theo **thứ tự
`s.relics`** = thứ tự nhận được. `r_ancientgene` (`f.v × 1.3`) trước `r_claw` (`+1`) cho
`(v×1.3)+1`; ngược lại cho `(v+1)×1.3`. Với `v=5`: 7.5→7 vs 7.8→8. **Chênh 1 damage/mặt.**
Tất định (mảng có thứ tự) nên replay an toàn, nhưng **không công bằng có thể đọc được**.
→ §10 mục R2: sắp `rlist()` theo `cat` (`scale` cộng phẳng trước, `rule`/`pact` nhân sau) để
kết quả độc lập với thứ tự nhặt. Đây là thay đổi hành vi → bump `ENGINE_VERSION`.

**E5 — `relicPool()` cạn vì `ex`/`mload`/cap.**
Sau khi thêm 3 tầng lọc, pool có thể rỗng. `mkReward(t='relic')` đã trả `null` khi
`!p.length` và `genRewards` bỏ qua `null` (vòng `g++<80`, fallback `'hp'`) → **không crash**.
Nhưng `applyEventFx('gamble_legend')` làm `pick(relicPool(s,3).filter(rar>=3))` rồi
`p.length ? pick(p) : pick(relicPool(s,2))` — nếu **cả hai** rỗng thì `pick([])` trả
`undefined` và `it.n` **throw**. Đã có guard `if(it)` cho `s.relics.push` nhưng **không** cho
`it.n` ở câu return (`engine.js:825`). Với roster 94 relic và cap 10 thì gần như không xảy ra,
nhưng đây là crash thật. → §11 mục 7.

**E6 — `__curse_dmg` là pseudo-relic ngoài `RELICS`.**
`RELIC_BY_ID['__curse_dmg']` được gán sau (`engine.js:806`) và **không** nằm trong mảng
`RELICS`. Hệ quả: không vào `relicPool`, không đếm Collection, `a:''`. Mọi AC ở §12 **phải
loại trừ id bắt đầu bằng `__`**, nếu không AC-2 (không relic nào untagged) sẽ fail vào nó.
Nó cũng **không có `mload`** dù mang `modFace f.v+=4` — nhưng đó là cộng phẳng, `mload 0` ✓.

**E7 — Migration `META.relics` khi roster lên 94.**
`collectionComplete()` (`ui.js:233`) là `META.relics.length >= RELICS.length`. Roster 44→94
làm **mọi người chơi đang 44/44 tụt xuống 44/94 và mất quyền vào Echo Box** — sink cuối game
họ đã mở khoá. Đây là mất mát tiến độ, không phải chi tiết.

**Spec migration (bắt buộc ship cùng):**
```
1. Không xoá / không đổi id nào (§6) ⇒ không có entry META mồ côi. 0 dữ liệu bị mất.
2. Thêm cờ META: collectionGrandfathered (bool, default false)
3. Khi load save: nếu META.relics.length >= 44  →  collectionGrandfathered = true
   (44 = RELICS.length trước patch này; ghi hằng RELIC_COUNT_PRE_EXPANSION = 44 vào data.js,
    KHÔNG dùng RELICS.length vì nó đã đổi)
4. collectionComplete() = collectionGrandfathered
                       || (META.faces.length >= FACE_POOL.length
                           && META.relics.length >= RELICS.length
                           && META.bosses.length >= BOSSES.length)
5. Người chơi grandfathered giữ Echo Box; thanh tiến độ Collection vẫn hiện 44/94 thật
   (không nói dối), kèm nhãn "Hoàn thành trước bản mở rộng".
```
Không grandfather = lấy lại thứ đã bán. Grandfather bằng cách sửa `>=` thành `>= 44` cứng =
người chơi mới không bao giờ phải hoàn thành gì. Cờ là cách duy nhất đúng cả hai phía.

**E8 — Mất relic giữa run (`bet_big`).**
`applyEventFx('bet_big')` làm `s.relics.splice(ri(len), 1)` → có thể xoá một relic
`mload 2`. Sau đó `mloadHeld(s)` giảm và pool mở lại đúng — vì cả hai luật được tính **tại
thời điểm phát**, không cache. Không cần code thêm. Nhưng lưu ý: relic bị mất **vẫn ở trong
`s.seen.relics`** → vẫn tính Collection. Đó là hành vi hiện có và đúng.

**E9 — Egg/token không nhận `modFace`.**
`mkAlly()` (`engine.js:239-244`) tạo unit trực tiếp, **không** gọi `buildUnit`, nên **không
relic `modFace` nào áp lên Axie Egg**. `r_claw` không buff egg; `hiveMind` buff *party* từ
egg, không buff egg. Đây là hành vi hiện có, và nó **giữ SWARM khỏi bùng nổ bậc hai** (nếu egg
nhận `modFace` thì `startSummon` × `modFace` sẽ nhân nhau). **Giữ nguyên có ý thức** —
expansion không được giả định egg nhận buff mặt.

**E10 — Đệ quy `onKill`.**
`r_chainreact` explode có thể giết địch khác → `onEnemyDeath` → `onKill` → explode nữa. Chặn
bởi cờ `e._dead` (`engine.js:361`) nên hữu hạn, nhưng độ sâu đệ quy = số địch (≤7). An toàn.
Thorns cũng có thể giết và gọi `onEnemyDeath` từ **trong** `dealDamage` (`:348`), tức `onKill`
chạy trước khi `dealDamage` gốc kết thúc. Relic mới dùng `onKill` **không được giả định
`s.ev` đã đóng** hoặc target gốc đã chết.

**E11 — `dr` cộng dồn tiến tới bất tử.**
`rsum(s,'dr')` (`:325`) cộng dồn; ở tổng ≥ 1.0 công thức thành `Math.max(1, ceil(v×0))` = 1
damage/đòn. Không chia 0, không crash, nhưng gần bất tử. Với `mload` cap 2 và `dr` = mload 2,
**chỉ một relic `dr` tồn tại được** → trần cứng 0.25. Đây là ví dụ rõ nhất về việc `mload`
đóng một lỗ hổng số học, không chỉ một lỗ hổng cân bằng.

**E12 — Thorns của địch không bị `thornsMult` của người chơi buff.**
`:341` chỉ nhân khi `tgt.side==='p'`. Nên `r_mirrorshell` không làm boss `mecha` (trait
`thorns`) mạnh hơn. Đúng, giữ nguyên. Nhưng `r_spines`/`onTurnStart` lặp `s.party` → cũng chạm
**egg** (`u.hp>0`, không lọc `token`) → egg có Thorns 2. Đó là buff nhỏ ngoài dự kiến cho
SWARM+AEGIS; đo được, giữ nguyên, ghi vào rủi ro §13.

**E13 — Relic đổi luật giữa lượt và `undo`.**
`SNAP` (`:547`) clone `party` nên `r_deathmark` sửa `u.die[].v` được undo đúng. Nhưng
`s.relics` **không** nằm trong `SNAP` — đúng, vì không hành động nào trong lượt thêm/bớt relic
(`playerUseRelic` chỉ dùng active). Expansion **không được** tạo relic tự thêm relic khác giữa
trận, nếu không undo sẽ lệch và replay server sẽ từ chối.

**E14 — Đội hình 5 Axie cùng class và `RP_class`.**
`newGame` cho phép `teamKeys` trùng (`GUIDES` có `['plant1','plant1',…]`). Đội 5 Plant làm
`RP_class` của relic `shield` đạt trần: `r_carapace` +2 với BULWARK +2 mỗi lần
`applyShield` → 1.43×. Vẫn dưới 2.2 ✓. Nhưng đây là chỗ trần 2.2 phải được **đo lại** khi
expansion thêm relic shield mới.

## 8. Dependencies

| Hệ | Quan hệ | File |
|---|---|---|
| **Relic Roster Expansion** | Doc này định nghĩa framework + target; doc kia viết 40 entry mới lấp target. **Hai chiều bắt buộc**: expansion không hợp lệ nếu vi phạm §3.1/§3.5/§3.6/§4.6. | `design/gdd/relic-roster-expansion.md` |
| Game Concept | Nguồn sự thật cho core loop, `TUNE`/`CURVE`, rarity 5 bậc, reward pool. Doc này **sửa** con số "44 relic" ở §Core Rules — Relic. | `design/gdd/game-concept.md` |
| Part Skill Identity | **Nguồn của `R_t` và `KW(k)`** — copy nguyên §F3/§F4, không suy lại. Cũng là nguồn của kwPure Direction Law (§3.7a) và của phương pháp hiệu chuẩn ngân sách. Lưu ý doc đó đang giữa kỳ sửa: face value sẽ re-anchor về hero tier-1 (base ≈ 2.8, **không** phải 6.0 đang viết ở đó). | `design/gdd/part-skill-identity.md` |
| Economy & Progression | `UNLOCKS` `u_relic1`/`u_relic2` điều khiển `s.unlockRelicMax` = trần rarity của pool; `ECHO` gate phụ thuộc `RELICS.length` (§7 E7). | `design/gdd/economy-progression.md` |
| Combo Decision Memo | §3 là **tiền lệ ràng buộc**: hai hệ không thưởng trên cùng trục. Đó là gốc của `mload` (§3.6) và của việc `κ_rng` tồn tại. | `design/gdd/combo-decision-memo.md` |
| Leaderboard / ADR-0001 | Mọi thay đổi math trong `engine.js` phải bump `ENGINE_VERSION` (`engine.js:9`), nếu không replay server từ chối submission cũ. Doc này đòi **≥4** thay đổi engine → **1 lần bump duy nhất**, ship cả gói. | `design/gdd/leaderboard-system.md` |
| Formation Resonance | `RESONANCE.mult` nhân `faceValue` **trước** `dmgMult`/`modDmg`. Relic active **không** đi qua `faceValue` nên không ăn Resonance — đã ghi là scope-out. | `design/quick-specs/formation-resonance-2026-09-01.md` |
| `fx.js` | Tiêu thụ `s.ev`. Event type `relic` mới (§10 E1) cần một nhánh replay, nếu không 14+ relic vô hình. | `src/fx.js` |

## 9. Tuning Knobs

| # | Knob | Giá trị đề xuất | Dải an toàn | Ảnh hưởng nếu chỉnh sai |
|---|---|---|---|---|
| K1 | `ANCHOR` (tâm dải COMMON) | **13.20** (= RP đo của `r_claw`) | 12.0 – 14.5, **giữ nguyên `SIG` ratio** | Toàn bộ 4 dải scale theo. Đổi **tỉ lệ** `SIG` → vi phạm INV-2 (`(1+τ)/(1−τ) < min ratio`) và bậc rarity mất nghĩa |
| K1b | **`τ` (nửa bề rộng dải)** | **0.15** | **0.05 – 0.1712 (CỨNG)** | `τ ≥ 0.1712` ⇒ **INV-1 vỡ về mặt số học**, không phải rủi ro mà là chắc chắn. Đây là knob duy nhất trong doc có cận trên chứng minh được; mọi giá trị ngoài dải phải bị `t_relic.mjs` từ chối |
| K1c | `τ_aim` (biên độ `bias` dịch đích) | **0.10** | 0.00 – `τ` − 0.02 | `τ_aim ≥ τ` ⇒ đích của archetype biên nằm ngoài dải ⇒ AC-16 luôn fail cho archetype đó |
| K2 | `P_COMMIT` | **0.30** | 0.25–0.35 | Quá thấp → relic archetype quá mạnh với người chơi archetype đó (chế độ hỏng §3 memo). Quá cao → relic archetype vô dụng với người chưa cam kết ⇒ không ai bắt đầu build |
| K3 | ~~Tolerance ngân sách ±20%~~ | **BÃI BỎ** — thay bằng K1b (`τ` cứng) + dung sai mềm `0.15 × C_r` | — | Dung sai ±20% là **nguyên nhân trực tiếp** của khiếu nại "buff tier dưới mạnh hơn tier trên": `1.2/0.8 = 1.5 > 1.4130` ⇒ dải chồng lấn là **tất yếu**. Không được khôi phục |
| K3b | Dung sai **mềm** (lệch đích archetype) | **0.15 × C_r** | 0.10 – 0.20 × C_r | Đây là knob ADVISORY. Siết < 0.10 ⇒ độ hạt cơ chế (bước +1 shield = 5.48 RP) làm hầu hết relic fail; nới > 0.20 ⇒ `bias` mất tác dụng và §3.10 kết luận 1 không còn được thi hành |
| K3c | Trần `bias` cho archetype bẫy | **1.00 khi playrate > 2× fair share (18.2%)** | ngưỡng 1.5× – 3.0× fair share | Hạ ngưỡng → nhiều archetype bị kẹp `bias 1.00` và mất công cụ nâng sàn; nâng ngưỡng → PLAGUE lại được cấp ngân sách lớn hơn dù đang hút 30% người chơi ở winrate dưới baseline |
| K4 | `κ_rng` / `κ_dot` | **0.75** / **0.60** | 0.70–0.85 / 0.55–0.75 | Đây là **hai knob buff APEX/INFERNO**. Nâng lên → relic crit/burn nhỏ lại → hai archetype 10% tiếp tục yếu |
| K5 | `RELIC_MLOAD_CAP` | **2** | 2–3 | **Knob nới đầu tiên** nếu sim cho winrate < 14%. 3 mở lại cặp `dmgMult`+`f.v×k`; ≥4 = không có trần |
| K6 | `RELIC_CAP` | **10** | 8–14 | < 8 chạm ở Short Run và biến relic thành reward chết; > 14 không bao giờ chạm ⇒ knob vô nghĩa |
| K7 | `bias(a)` β | **0.5** | 0.3–0.7 | **Phải đo lại sau mỗi lần ship** — `bias` là ảnh của balance hiện tại, không phải hằng thiết kế. β cao → dao động (over-correct qua từng patch) |
| K8 | Trọng số `archScore` | đổi `rar>=3?3:rar>=2?2:1` → tỉ lệ `RP_band` (1 / 1.4 / 2 / 2.8) | — | Sửa việc tracker báo PLAGUE quá sớm (§4.7(3)). **Không** sửa bằng cách hạ ưu tiên `poison` trong `faceArch` — vị trí #2 là đúng cấu trúc |
| K9 | Burn base decay | giữ `floor(x/2)` | `x − max(1, floor(x/3))` là ứng viên | Thay đổi balance **toàn game** (`MON.pyrewing`, 4 boss, `FACE_POOL` r1-r4). **Không ship cùng patch relic** — không tách được nguyên nhân khi đo |
| K10 | `a_freeze` cost | **4** (cố tình đắt) | 3–5 | Hạ về 3 = đúng band nhưng tạo stun-lock trên 3/6 boss không có add |
| K11 | Trần `RP_class` | **2.2×** | 1.8–2.5 | Hạ xuống 1.8 → phải thu hẹp mọi relic tiêm `pierce` (Bird TALON +3 là ca nặng nhất) |
| K12 | `Ω` (số lượt/trận) | **5** | 4–7 | Là mẫu số của gần như mọi công thức §4.4. Boss thật dài hơn (~8) ⇒ relic scaling-theo-lượt (`plague`, `growth`, `thorns`) bị **dưới-định-giá** ở đánh boss. Đo `Ω` thật bằng `sim.js` trước khi tune bất kỳ knob khác |

## 10. Cần engine work mới (không dùng được hôm nay)

Mọi mục dưới đây **chưa build được**. Không relic nào ở §6 phụ thuộc chúng; `relic-roster-expansion.md`
được phép dùng A1-A5 và G1 nhưng phải đánh dấu rõ.

**E1 — Event type `relic` (BLOCKING cho §3.9).**
```
Thêm:  function EVrelic(s, id, uid){ EV(s, {t:'relic', id, uid: uid||null}); }
Gọi tại 14 chỗ, ngay TRƯỚC khi luật của relic có hiệu lực:
  dealDamage  — sau dmgMult (:319), sau vòng modDmg (:320), sau critMult (:321),
                sau piercePlus (:318), sau dr (:325), sau skipThorns (:338)
  faceValue   — sau hiveMind (:411)
  applyShield — sau nhánh noShieldCap (:377)
  tickStatus  — sau poisonTicks (:641), sau nhánh keepFull/plague (:648), sau burnMult (:652)
  execFace    — sau firstEcho (:468)
  buildUnit   — một lần cho mỗi modFace đã áp (:54)
  startCombat — sau vòng startSummon (:227)
Payload chỉ chứa id + uid ⇒ tất định, không ảnh hưởng math, KHÔNG cần bump ENGINE_VERSION
(server replay so sánh state, không so sánh s.ev).
fx.js: nhánh mới hiện badge tên relic cạnh unit trong ~600ms, throttle 1 badge/relic/lượt.
```

**R1 — `relicConflict(s, r)` trong `relicPool()` (BLOCKING cho §3.6 + §3.7).**
```
function partyKeywords(s){                 // mặt SAU mutation, không phải HEROES[key].die
  const out = new Set();
  for(const re of s.roster) for(const f of buildUnit(re, s).die) for(const k of f.k){
    const t = KW_EX[k.split(':')[0]]; if(t) out.add(t);
  }
  return out;
}
const mloadHeld = s => rlist(s).reduce((a,r) => a + (r.mload||0), 0);

function relicConflict(s, r){
  if(s.relics.length >= RELIC_CAP) return true;                      // §3.6 trần thứ hai
  if(mloadHeld(s) + (r.mload||0) > RELIC_MLOAD_CAP) return true;     // §3.6
  const owned = new Set();
  for(const h of rlist(s)) for(const t of (h.ex||[])) owned.add(t);
  for(const t of partyKeywords(s)) owned.add(t);                     // §3.7 nguồn 2
  return (r.ex||[]).some(t => owned.has(t));
}
relicPool: RELICS.filter(r => r.rar <= Math.min(maxR, cap)
                           && !s.relics.includes(r.id)
                           && !relicConflict(s, r));
```
`partyKeywords` gọi `buildUnit` cho 5 roster entry mỗi lần `relicPool` chạy (6 call site) —
`buildUnit` gọi `clone()` = `JSON.parse(JSON.stringify)`. Ở 94 relic × 5 unit đây vẫn là
micro-giây, nhưng nếu đo thấy chậm thì cache theo `(s.step, s.roster.length)`. **Tất định** ✓
(`buildUnit` không dùng RNG). **Đây là thay đổi hành vi drop → BUMP `ENGINE_VERSION`.**

**A1-A5 — 5 `act.kind` mới.** Không có nhánh `else` trong `playerUseRelic` (`:566-575`) nên
`kind` lạ **trừ mana + tiêu slot của lượt + không làm gì**. Spec chính xác, chèn cùng chuỗi
`else if`, tất cả trước `if(!ok)`:
```
A1  burnall     : aliveE(s).slice().forEach(t => addStatus(s, t, ['burn:'+a.v], u));
A2  thornsall   : aliveP(s).forEach(t => addStatus(s, t, ['thorns:'+a.v], u));
                  // hướng: buff ALLY ✓ đúng Direction Law
A3  summonally  : for(let i=0;i<a.v;i++) if(s.party.filter(x=>x.token&&x.hp>0).length<4){
                     const al = mkAlly(s); rollUnit(s, al); al.used = true; s.party.push(al); }
                  // copy nguyên nhánh summon của doFace (:532) — GIỮ cap 4 token và used=true
A4  growthall   : s.party.forEach(p => { if(p.hp>0 && !p.token)
                     p.die.forEach((f,i) => { if(f.v>0) p.growth[i] = (p.growth[i]||0) + a.v; }); });
                  // đây CŨNG là nửa của G1 — growth theo DIE, không theo mặt
A5  critall     : s.party.forEach(p => { if(p.hp>0 && p.rolled>=0
                     && p.die[p.rolled].t==='dmg' && !p.used) p.critNow = true; });
                  // KHÔNG dùng rnd() — cấp crit tất định cho lượt này. Đây là điểm mấu chốt:
                  // nó cho APEX một đường crit CÓ AGENCY, tức κ = κ_choice(0.95) chứ không
                  // phải κ_rng(0.75) → đúng thứ §4.7(1) chẩn đoán là gốc của winrate 10%
```
Cả 5 tất định. `a.v` đọc từ data ⇒ không lặp lỗi hardcode của `kind:'ult'`.
**Bump `ENGINE_VERSION`.**

**G1 — Growth accumulator theo die (sửa EVOLVE về cấu trúc).**
`growth` hiện cộng `u.growth[fi]` cho **đúng mặt vừa dùng**, nên ở `Ω=5` giá trị ≈ 0 (§4.5
ví dụ 5). Field mới:
```
growthAll: N   →  trong endTurn(), sau rollAll (engine.js:637):
                  s.party.forEach(p => { if(p.hp>0 && !p.token)
                    p.die.forEach((f,i) => { if(f.v>0) p.growth[i] = (p.growth[i]||0) + N; }); });
                  EVrelic(s, id, p.uid);
RP(growthAll: N) = N × Σ_{j=1}^{Ω-1} (n × p_dmg) = N × 4 × 2.64 = 10.6 · N   (chỉ tính mặt dmg)
⇒ N=2 → 21.1 RP → hợp EPIC của EVOLVE (target 26.0, −19% ✓)
```
Không có field này thì **EVOLVE không thể có relic EPIC hợp lệ** — mọi thiết kế growth-thuần
đều dưới band. Đây là lý do §5.2 vẫn ghi EVOLVE cần +1 EPIC dù đã có `r_growthcore`.

**G2 — Ba hook đã khai báo nhưng chưa bao giờ được gọi.**
Comment `data.js:355` liệt kê `onRollEnd · onTurnEnd · onDmgTaken · onPoison`. Thực tế:
`onRollEnd` **có** được gọi (`engine.js:277`) nhưng không relic nào dùng; `onTurnEnd`,
`onDmgTaken`, `onPoison` **không có `rcall` nào**. Comment đang nói dối. Hai lựa chọn:
```
(a) Xoá 3 tên đó khỏi comment  — chi phí 0, khuyến nghị cho patch này
(b) Gọi chúng:  onTurnEnd   → rcall(s,'onTurnEnd',null) đầu endTurn, trước vòng địch (:622)
                onDmgTaken  → rcall(s,'onDmgTaken',{src,tgt,dealt}) trong dealDamage sau
                              `if(tgt.side==='p') s.stat.taken+=dealt` (:336)
                onPoison    → rcall(s,'onPoison',{tgt,stacks}) trong addStatus nhánh poison (:391)
```
`onDmgTaken` là hook mở ra cả một họ relic AEGIS/BULWARK ("khi bị đánh, …") mà hôm nay
**không tồn tại đường nào** để viết — đó là một phần lý do thorns chỉ có 2 relic. Nếu producer
muốn AEGIS có nội dung thật ở EPIC, (b) là điều kiện.

**R2 — Sắp thứ tự `modFace` theo `cat`** (§7 E4). `rlist()` sắp `scale` trước `rule`/`pact`.
Bump `ENGINE_VERSION`.

**M1 — Migration `META.relics`** — spec đầy đủ ở §7 E7. Không phải engine work
(`ui.js`/`saveMeta`), nhưng **phải ship cùng** patch đổi `RELICS.length`.

**Tổng: 1 lần bump `ENGINE_VERSION` duy nhất** cho R1 + A1-A5 + G1 + R2. E1 và M1 không cần.

## 11. SUPERSEDES / REQUIRED CHANGES — việc phải làm ở file khác

Doc này **không sửa file nào**. Danh sách chính xác để một pass sau thực thi:

| # | File · symbol | Thay đổi | Lý do |
|---|---|---|---|
| 1 | `src/data.js` · `ARCH` | Thêm entry `exec` (§3.3) | `PASSIVE.beast.a='exec'` không có entry ⇒ Beast góp 0 cho mọi archetype |
| 2 | `src/engine.js` · `faceArch()` | Viết lại theo bảng 12 dòng §3.4 | `thorns`/`exec` không bao giờ trả về được; precedence là luật không viết |
| 3 | `src/data.js` · `RELICS` | 44 entry: retune/retag/rerarify theo §6. Thêm field `mload`, `ex` cho cả 44. **KHÔNG thêm `cat`** — nó là nhãn tài liệu, không có điểm đọc, và ship nó vi phạm INV-9 (§3.1 hộp `cat`). **Không xoá, không đổi id.** | §6 · INV-9 |
| 4 | `src/data.js` · `ARCH.aoe.ic` / `ARCH.thorns.ic` | **Cả hai đang là `✷`** — hai archetype khác nhau cùng icon. Đề xuất `thorns` → `✜` | Vi phạm "mỗi ký hiệu nói một điều"; cần `art-director` chốt |
| 5 | `src/data.js` · `BP_FACES.bp_bulwark.arch` | `'shield'` → `'thorns'` (hoặc chấp nhận lệch có ghi chú) | Sau §3.4, `faceArch(bp_bulwark.face)` trả `thorns`; field `arch` tự khai là nhãn hiển thị ⇒ hai nguồn nói khác nhau về cùng một mặt |
| 6 | `src/engine.js` · `relicPool()` | Thêm `relicConflict()` (§10 R1) | §3.6 + §3.7 |
| 7 | `src/engine.js:825` · `applyEventFx('gamble_legend')` | Guard `it` trước `it.n` ở câu return | `pick([])` → `undefined.n` throw khi cả 2 pool rỗng (§7 E5) |
| 8 | `src/engine.js:573` · `kind:'stun'` | Truyền source: `addStatus(s, tgt, ['stun'], u)` | Bất nhất với 7 kind còn lại; vô hại hôm nay, bẫy về sau |
| 9 | `src/data.js:354-356` | Xoá `onTurnEnd`/`onDmgTaken`/`onPoison` khỏi comment **hoặc** implement (§10 G2) | Comment nói dối về API |
| 10 | `src/ui.js:233` · `collectionComplete()` | Cờ `collectionGrandfathered` (§7 E7) | 44→94 làm mất Echo Box của người chơi đã hoàn thành |
| 11 | `src/ui.js:2496` · filter archetype | `Object.keys(ARCH)` → tự lên 11 nút. **Kiểm tràn layout** `cxfilter` | 11 nút thay vì 10 |
| 12 | `src/ui.js:2498` · `[3,2,1,0].forEach` | Không đổi logic, nhưng `chip('-')` fallback ở `:2505`/`:2722` sẽ **không bao giờ chạy nữa** sau khi AC-2 pass | Giữ fallback làm lưới an toàn, không xoá |
| 13 | `design/gdd/game-concept.md` §Core Rules — Relic | "44 relic" → "**94 relic**", thêm 1 câu về `mload`/`ex` **và 1 câu về bất biến đơn điệu §3.12** | Số sai sau patch |
| 14 | `design/gdd/bloodline-system.md` §13 (2 chỗ) | "44 relic" → "**94 relic**" | Dùng làm mẫu số tính content |
| 15 | `src/engine.js:9` · `ENGINE_VERSION` | Bump **một lần** cho cả gói | ADR-0001: replay dùng đúng engine build |
| 16 | `tools/verify.mjs` **hoặc** `tools/t_relic.mjs` (mới) | Implement AC-1..AC-11 **và AC-15..AC-21** (§12) | Không có test nào hiện kiểm relic. `verify.mjs` phải giữ **32/32** |
| 17 | `src/data.js` · mọi entry `RELICS` có `modFace` | Thêm field **`mfPhase: 'kw' \| 'add' \| 'mul'`** (mặc định `'add'`) | INV-5. **Không** được suy pha bằng cách đọc thân hàm |
| 17b | `src/data.js` · 18 entry `RELICS` phụ thuộc engine work | Thêm field **`eng: '<ENG-id>'`** trỏ tới đúng mục trong §10 hoặc `ENG-0..ENG-17` (12 field, ánh xạ liệt kê ở AC-22) | INV-9 / AC-22. Không có `eng` thì `t_relic.mjs` phân loại field là **DEAD** và hard-fail — đó là điều đã bắt được `rerollRefund` |
| 18 | `src/engine.js:54` · `buildUnit` | Thay `for(const r of rlist(s))` bằng vòng sắp theo `[PHASE_RANK[mfPhase], rar, RELIC_INDEX[id]]` (§3.12 INV-5). `r_thousandcuts` khai **hai** entry `modFace` ở hai pha | Kết quả `modFace` phải độc lập thứ tự nhặt, nếu không RP không phải hàm của tập relic |
| 19 | `src/engine.js:858` · `genShop` | `cost:[45,75,120,180][r.rar]||60` → **`cost: RELIC_SHOP_COST[r.rar]`** với `RELIC_SHOP_COST = [45,75,120,180,260]` khai trong `data.js`. Bỏ hẳn `||60` | AC-21 + QĐ-3. Bậc cao hơn phải đắt hơn — cùng bất biến với §3.12, ở tầng kinh tế |
| 20 | `design/gdd/relic-roster-expansion.md` | **37 thay đổi** kê nguyên văn ở §6.7 + **2 entry mới** (`r_rotbite`, `r_rotmouth`) ở §6.7.7 | Doc này không sửa file đó |
| 21 | `design/gdd/part-skill-identity.md` §F4 | Thêm `KW(weaken:N) = 0.60N`, `KW(vulnerable:N) = 0.75N`, `KW(blind:N) = 0.50N`; và ghi chú rằng giá **áp dụng mỗi lần áp** là `W(N) = 1.275N` (§4.4) | §F4 không định giá 3 keyword này, nhưng `r_marrowdrill` và mọi relic debuff tương lai cần chúng. Hai doc phải dùng **cùng một bảng** |
| 22 | `src/engine.js` · `dealDamage` | Thêm `rcall(s,'onDmgTaken',{src,tgt,dealt})` sau `if(tgt.side==='p') s.stat.taken+=dealt` (`:336`) | QĐ-2. Sau đó `r_bloodthorn` chuyển từ `onThorns` sang `onDmgTaken` (§6.7.4) ⇒ **`ENG-5` thu hẹp còn 2 relic** (`r_retributor`, `r_scalecrown`), không bỏ được hẳn vì cả hai cần `th` và `src` của cú phản đòn — thứ `onDmgTaken` không có |
| 23 | `src/data.js` · `RELICS` | Thêm 2 entry `r_rotbite` (rar 0) và `r_rotmouth` (rar 1) — §6.7.7 | PLAGUE thiếu C và thiếu 1 R; retag không khả thi (Superlinear Axis Law) |
| **24** | `src/data.js` · `r_scalecrown` | `ex: []` → **`ex: ['thornsFloorFlat']`** | §3.7a cặp 1. Sàn `st.thorns = Math.max(…, 2)` **trùng khít** `r_spines` ⇒ giữ cả hai thì một cái đóng góp **đúng 0**. Không đụng RP |
| **25** | `src/data.js` · `r_apexferal` | `ex: []` → **`ex: ['execInjectAll']`** | §3.7a cặp 3. Superset của `r_gorehook` (31 ⊃ 17 mặt) cần token để `exSub` trỏ tới. Không đụng RP |
| **26** | `src/data.js` · 3 relic subset | Thêm **`exSub`**: `r_pierceall` → `['pierceInjectAll']` · `r_gorehook` → `['execInjectAll']` · `r_windlash` → `['cleaveInject']` | §3.7a cặp 2-4. Ba cặp dead-draw **một chiều** đo được trên mặt thật. `ex` đối xứng sẽ khiến COMMON/RARE **cấm** LEGENDARY ⇒ phải là `exSub`. Không đụng RP |
| **27** | `src/data.js` · `r_keeneye` | `critFlat: 4` → **`critFlatPity: 4`**; `d` thành *"…your first attack this turn crits and deals 4 more damage."* | §6.7.6 hộp `r_keeneye`. `critFlat` là `rsum` áp **mọi** crit ⇒ relic thành ≥35.60 RP = `Band[3]`. ENG-21 đã khai sẵn `critFlatPity` cho đúng ca này. **Sửa code, RP giữ 27.40** |
| **28** | `src/engine.js` · `relicConflict()` (mục 6) | Thi hành `exSub` **một chiều**: không đề nghị `r` nếu `∃ t ∈ r.exSub` nằm trong `ex` của relic **đang giữ**. Superset **vẫn** được đề nghị khi đang giữ subset | §3.7a. ~5 dòng trong hàm mục 6 vốn đã phải viết. Giới hạn đã biết: lấy subset **trước** rồi superset sau vẫn kẹt subset hồi tố — cần refund, là content thật, **không** làm ở đây |

## 12. Acceptance Criteria

AC-1..AC-11 là **kiểm tĩnh trên roster hợp nhất** (44 đã retune + 40 từ
`relic-roster-expansion.md`), viết được thành `tools/t_relic.mjs` chạy trên
`require('../src/data.js')`. AC-12..AC-14 là kiểm động qua `tools/sim.js`.

Mọi AC **loại trừ id khớp `/^__/`** (pseudo-relic `__curse_dmg`, §7 E6).

| # | Phát biểu kiểm được | Gate |
|---|---|---|
| **AC-1** | **GIVEN** `ARCH` và `PASSIVE`, **WHEN** duyệt mọi class, **THEN** `ARCH[PASSIVE[c].a] !== undefined` với cả 6 class; **AND** `Object.keys(ARCH).length === 11`; **AND** mọi `ARCH[k].ic` là duy nhất | BLOCKING |
| **AC-2** | **GIVEN** `RELICS`, **WHEN** duyệt mọi entry, **THEN** `r.a` không rỗng **VÀ** `ARCH[r.a]` tồn tại. (0 relic untagged — hôm nay có 4: `r_claw` `r_heart` `r_bloodmouth` `r_infinitedie`; 2 relic tag `exec` không phân giải) | BLOCKING |
| **AC-3** | **GIVEN** `faceArch()` và bảng §3.4, **WHEN** chạy trên cả `FACE_POOL` + mọi mặt `HEROES` + `SLOT_CLASS_TEMPLATE` + `PART_VARIANT_MODS`, **THEN** kết quả khớp bảng ưu tiên 12 dòng; **AND** tồn tại ≥1 mặt trả `thorns` **AND** ≥1 mặt trả `exec`; **AND** tập giá trị trả về ⊆ `keys(ARCH) ∪ {''}` | BLOCKING |
| **AC-4** | **GIVEN** mục tiêu §5.1, **WHEN** đếm theo `(a, rar)`, **THEN** mọi `a ∈ ARCH` có ≥1 C, ≥2 R, ≥2 E, ≥1 L passive **AND** ≥1 relic có `act`; **AND** `max(count_a)/min(count_a) ≤ 1.6`; **AND** `count_a ≤ 10` ∀a | BLOCKING |
| **AC-5** | **GIVEN** mọi relic có `modFace` sửa `f.k`, **WHEN** áp `modFace` lên unit giả có đủ 8 type mặt, **THEN** không cặp (type, keyword) nào nằm trong ô "Cấm tiêm" của bảng §3.5; **AND** không keyword nào bị tiêm vào mặt type `poison`, `mana`, `summon` mà thuộc kwPure (vô hiệu âm thầm) | BLOCKING |
| **AC-23** | **GIVEN** mọi relic có `modFace`/`modFace2`, **WHEN** chạy chúng trên **tập mặt THẬT** (mọi mặt của `HEROES` + `FACE_POOL`, khử trùng lặp theo `(slot, type, kw)`) và so *tập mặt* nhận cùng một keyword, **THEN** với mọi cặp mà tập này ⊆ tập kia: hoặc hai relic dùng chung một `ex` token (trùng khít), hoặc relic nhỏ hơn mang `exSub` chứa một `ex` token của relic lớn hơn (tập con thật sự). 🔒 **Phải chạy trên mặt thật, KHÔNG trên tích Descartes slot × type**: probe tổng hợp 6 × 8 báo `r_pierceall` ⊄ `r_worldpiercer` vì nó bịa ra `horn ∧ shield`, mặt không tồn tại — một **false negative** giấu nguyên một cặp dead-draw. Xem §3.7a | BLOCKING |
| **AC-24** | **GIVEN** mọi relic, **WHEN** gom theo *luật thật sự cấp* — (a) field engine gộp bằng `rmax`/`\|\|`, (b) sàn `st.X = Math.max(…, N)` **viết trong thân hook**, (c) tập mặt nhận keyword (AC-23) — **THEN** mọi nhóm ≥2 relic cùng một luật phải chung ≥1 `ex` token. Tín hiệu (b) là tín hiệu **duy nhất** bắt được cặp `r_spines` + `r_scalecrown`: sàn đó là **hành vi trong thân hàm**, không phải field khai báo, nên mọi kiểm dựa trên khai báo đều mù với nó | BLOCKING |
| **AC-25** | 🔒 **LUẬT KIỂM CỦA KIỂM (meta).** **GIVEN** bất kỳ check tự động nào của dự án, **THEN** nó chỉ được tính là hợp lệ khi thoả **cả ba**: (a) **đo thực tại đã ship**, không đo mô hình sinh ra nó — chạy trên `RELICS`/`HEROES`/`FACE_POOL` thật, **không** trên miền lý tưởng hoá hay tích Descartes tự sinh; (b) **chứng minh nó BIẾT FAIL** — có ít nhất một input hỏng đã biết làm nó đỏ, kiểm bằng đột biến (mutation), vì một check chưa từng fail không phân biệt được với một check không kiểm gì; (c) **không pattern-match cú pháp của lỗi** — bắt *hành vi sai*, không bắt *chuỗi ký tự của lần sai trước*, nếu không nó sẽ mù đúng vào lúc lỗi được sửa; **AND** (d) phép kiểm đột biến ở (b) phải so **TẬP đơn vị fail**, không so **SỐ LƯỢNG** — một đột biến rơi vào đơn vị **đang fail sẵn** không làm số đếm đổi, và gate sẽ kết luận "check không thể fail" trong khi nó vừa bắt được đột biến; **AND** (e) khi một check đọc dữ liệu có cấu trúc (cột bảng, chỉ số mảng), nó phải **tự kiểm tra kiểu của ô nó vừa đọc** — một cột lệch trả về giá trị *hợp lệ nhưng sai nghĩa* (đọc `rar` 1 thay cho `RP` 43.00) và không có gì báo động | BLOCKING |
| **AC-6** | **GIVEN** mọi keyword mà relic tiêm hoặc truyền qua `onHit`/`act`, **THEN** nó ∈ danh sách trắng `addStatus` (11 keyword, §7 E2) **hoặc** ∈ danh sách keyword ngoài kwPure `doFace` tiêu thụ; **AND** `shieldself` không xuất hiện ở relic nào | BLOCKING |
| **AC-7** | **GIVEN** `RP_implied` tính theo §4.4 và `RP_target(a,r)` theo §4.6, **THEN** `\|RP_implied − RP_target\|/RP_target ≤ 0.20` cho **mọi** relic passive; **AND** cho active, `\|VPM − VPM_band\|/VPM_band ≤ 0.20`. Ngoại lệ được phép: tối đa **2** relic, mỗi cái phải có dòng lý do trong doc (hiện: `a_freeze` −37%, §6.5) | BLOCKING |
| **AC-8** | **GIVEN** mã nguồn `RELICS`, **THEN** không entry nào chứa `Math.random`, `Date`, `performance`, `document`, `window`; **AND** mọi ngẫu nhiên đi qua `rnd()`/`pick()`/`ri()`; **AND** chạy cùng seed 2 lần cho `s.ev` byte-identical | BLOCKING |
| **AC-9** | **GIVEN** `mload` và `ex`, **THEN** ∀ relic: `mload ∈ {0,1,2}` **AND** khớp phân loại §3.6 (relic có `dmgMult`/`dr`/`modFace`-nhân ⇒ 2; có `critMult`/`critBonus`/`thornsMult`/`burnMult`/`burnSlow`/`burnSpread`/`poisonTicks`/`plague`/`poisonSpread`/`piercePlus`/`hiveMind` ⇒ 1); **AND** `mload > 0 ⇒ rar >= 1`; **AND** mọi relic dùng field gộp bằng `rmax` có ≥1 `ex` token | BLOCKING |
| **AC-10** | **GIVEN** de-dup §3.7, **WHEN** với mọi cặp relic `(x,y)` mô phỏng giữ cả hai, **THEN** không cặp nào cùng cấp một luật mà engine gộp bằng `\|\|` hoặc `rmax` (đóng góp cái thứ hai = 0); **AND** ∀ relic có `ex` token ∈ `values(KW_EX)`, `relicConflict` trả `true` khi party mang keyword tương ứng | BLOCKING |
| **AC-11** | **GIVEN** mọi relic có `act`, **THEN** `act.kind` ∈ 8 giá trị đã implement (`heal dmg ult shieldall dmgall poisonall stun reroll`) **hoặc** được đánh dấu tường minh `needsEngine: true` **và** không có mặt trong `RELICS` được ship; **AND** `act.cost >= 1`; **AND** `act.tgt ∈ {ally, enemy, self}` | BLOCKING |
| **AC-12** | **GIVEN** `node tools/sim.js 500 mode=short asc=0`, **WHEN** so với baseline đo 2026-09-03 (**winrate tổng 20.0%** trên 300 run — con số này là mốc "trước", không phải một ngưỡng trừu tượng), **THEN** winrate tổng ≥ **14.0%** (= `0.70 × 20.0%`). Nếu < 14.0% → nới K5 (`RELIC_MLOAD_CAP` 2→3, **và đồng thời hạ `r_soulforge.dr` về 0.25**) rồi đo lại, **không** hạ `bias` | BLOCKING |
| **AC-13** | **GIVEN** cùng sim ≥300 run, **WHEN** đọc playrate từng archetype, **THEN** **mọi** archetype ≥ **4.0%** playrate (baseline đo: growth 1.7% **fail**, thorns 1.3% **fail**, còn lại pass); **AND** `max/min playrate ≤ 8.0×` (baseline `30.0 / 1.3 = 23.1×` **fail**) | BLOCKING |
| **AC-14** | **GIVEN** cùng sim, **WHEN** đọc winrate từng archetype, **THEN** mọi archetype trong dải **[0.60×, 1.60×] × winrate tổng** (baseline: APEX 10% và INFERNO 10% = 0.50× **fail**; SWARM 33% = 1.65× **fail**; 8 archetype còn lại pass). Đây là AC bắt `bias` làm đúng việc: nó phải **nâng sàn** (crit, burn) đồng thời **không nâng trần** (summon, shield) | ADVISORY (đo, không chặn merge — cần ≥2 lần đo để tách nhiễu seed) |

### 12.1 AC của bất biến đơn điệu — AC-15..AC-20

Sáu AC dưới đây là **lý do §3.12 tồn tại** và là phần product owner yêu cầu trực tiếp. Tất cả chạy
tĩnh trên `RELICS` sau khi `data.js` được cập nhật, viết thành `tools/t_relic.mjs`. Mỗi tiêu chí
nêu **con số kỳ vọng chính xác**, không nêu "hợp lý" hay "gần đúng".

| # | Phát biểu kiểm được — với con số chính xác | Gate |
|---|---|---|
| **AC-15** | **KHÔNG CHỒNG LẤN GIỮA BẬC (INV-1).** Với `BAND = [[11.22,15.18],[15.89,21.48],[22.44,30.36],[31.77,42.97]]` (**đã làm tròn vào trong theo INV-2b — test phải dùng đúng mảng này, không tự tính lại từ `ANCHOR`**), **THEN** `max(RP of rar r) < min(RP of rar r+1)` với cả `r ∈ {0,1,2}`. Giá trị kỳ vọng sau retune trên **94 relic**: `max(C) = 15.00` (`r_cleaveall`) · `min(R) = 16.00` (`a_wall`, `a_clutch`) · `max(R) = 21.12` (`r_heartwood`) · `min(E) = 22.48` (`a_aegisfont`) · `max(E) = 30.00` (`r_thousandcuts`) · `min(L) = 33.25` (`r_ironmaiden`). **Số cặp vi phạm kỳ vọng: 0** | **BLOCKING** |
| **AC-16** | **MỌI RELIC TRONG DẢI CỦA CHÍNH NÓ (INV-1, vế 2).** `∀ x: BAND[x.rar][0] ≤ RP(x) ≤ BAND[x.rar][1]`. **Số relic ngoài dải kỳ vọng: 0 / 94.** Đối chứng "trước": chạy cùng assertion trên roster hiện tại + roster expansion chưa sửa phải cho **61 / 92 fail** (24 trong 44, 37 trong 48) — nếu con số đối chứng khác, `RP()` trong test đã lệch khỏi §4.4 và test sai, không phải data sai | **BLOCKING** |
| **AC-17** | **VÙNG CẤM RỖNG (INV-3).** Không relic nào có `RP ∈ (15.18,15.89) ∪ (21.48,22.44) ∪ (30.36,31.77)`. **Số relic trong vùng cấm kỳ vọng: 0.** (Trước sửa: 6 — `r_heart` 15.00→gap, `r_deathmark` 15.80, `r_infinitedie` 22.00, `r_soulforge` 30.90, `r_eggshell` 21.90, `r_keeneye` 15.60, `r_windlash` 21.55, `r_squallmark` 21.80, `r_apexferal` 31.73) | **BLOCKING** |
| **AC-18** | **ĐỘC LẬP THỨ TỰ NHẶT (INV-5).** Với 200 tập relic ngẫu nhiên có seed cố định, mỗi tập ≤ `RELIC_CAP` và thoả `mload`, **THEN** `JSON.stringify(buildUnit(re, S).die)` **giống hệt** cho **cả 2 hoán vị đảo ngược và 3 hoán vị xáo**. **Số khác biệt kỳ vọng: 0 / 200.** Chạy trên `t_relic.mjs` **trước** và **sau** patch: trước phải fail ≥1 (cặp `r_claw` + `r_ancientgene` ở `v ≥ 7`), nếu không thì test chưa chạm đúng đường | **BLOCKING** |
| **AC-19** | **KHÔNG TRÙNG LUẬT (dead-draw, §3.7 mở rộng).** ∀ cặp `(x,y)` cùng có mặt trong pool: (a) không cặp nào cùng ghi vào một field đọc bằng `rmax` mà **không** chia sẻ ≥1 `ex` token; (b) không relic nào cấp một keyword mà một relic khác **hoặc** một mặt `FACE_POOL` đã cấp trên **cùng tập slot∧type**; (c) không relic nào cấp một luật mà `KW_EX` đã ánh xạ. **Số cặp vi phạm kỳ vọng: 0.** Đối chứng "trước": ≥4 (`r_voidgene`↔`r_tidalbrand` trên `ears→rerollup`; `r_spines`↔`r_glassspine` nếu gộp `thornsFloor`; `r_manaflood`↔keyword `overflow`; `r_plaguelord`↔keyword `plague`) | **BLOCKING** |
| **AC-20** | **CẤU THÀNH & PHƠI NHIỄM (INV-6, INV-7).** ∀ relic: số cơ chế tính RP ≤ **2** nếu `rar ≤ 1`, ≤ **3** nếu `rar ≥ 2`; **AND** `max_i(RP_i)/RP_total ≥ 0.45`; **AND** ∀ relic dùng `modFace` gắn với vị từ slot: phơi nhiễm dùng để tính RP **bằng đúng** giá trị trong bảng §4.4b (sai số ≤ 0.001), **không** bằng `p_slot` khi vị từ hẹp hơn slot. **Số relic vi phạm kỳ vọng: 0.** Đối chứng "trước": 3 (`r_cleaveall`, `r_wildfire`, `r_voidgene` — cả ba định giá ở `p_slot`) | **BLOCKING** |

| **AC-21** | **GIÁ SHOP CŨNG PHẢI ĐƠN ĐIỆU THEO BẬC.** `genShop` (`src/engine.js:858`) dùng `cost:[45,75,120,180][r.rar]||60` — với `r.rar === 4` biểu thức cho `undefined` ⇒ `||60` ⇒ **60**, tức một relic Mythic **rẻ hơn một relic RARE (75)**. Đây là **cùng một khiếu nại của product owner, ở tầng kinh tế**: bậc cao hơn phải đắt hơn, đúng như bậc cao hơn phải mạnh hơn. **THEN** `∀ r: cost(r) = RELIC_SHOP_COST[r.rar]` với `RELIC_SHOP_COST = [45, 75, 120, 180, 260]` và **`cost` tăng nghiêm ngặt theo `rar`** (`45 < 75 < 120 < 180 < 260`); **AND** không nhánh fallback `||60` nào tồn tại; **AND** `∀ r: RELIC_SHOP_COST[r.rar] !== undefined`. **Số relic có giá không đơn điệu kỳ vọng: 0.** (Hôm nay roster ship 0 relic `rar:4` nên lỗi chưa kích hoạt, nhưng nó **chặn hẳn tầng Mythic** — sửa theo QĐ-3 §14.1) | **BLOCKING** |

| **AC-22** | **KHÔNG ĐỊNH GIÁ CƠ CHẾ KHÔNG TỒN TẠI (INV-9, §6.2a) — kiểm 3 trạng thái.** Với mọi field mà RP của một entry `RELICS` phụ thuộc vào, phân loại: **LIVE** = có ≥1 điểm đọc trong `src/engine.js` (`rhas`/`rsum`/`rmax`/`rmul_`/`rcall`/truy cập trực tiếp) · **PENDING** = không LIVE nhưng entry mang `eng: '<ENG-id>'` và id đó **phân giải được** trong bảng engine work (§10 `E1`/`R1`/`R2`/`G1`/`G2`/`A1`-`A5`, hoặc `ENG-0`..`ENG-17` của roster) · **DEAD** = còn lại. **THEN** chỉ **DEAD** fail. **Số field DEAD kỳ vọng: 0.** **Số field PENDING kỳ vọng: 12** (`growthAll`→G1, `growthPlus`→ENG-2, `growthKeep`→ENG-3, `thornsPlus`→ENG-4, `onThorns`→ENG-5, `onShield.tgt`→ENG-6, `burnTicks`+`burnTickRatio`→ENG-7, `critPierce`→ENG-8, `cleaveRatio`→ENG-9, `critPreserve`→ENG-15, `actReuse`→ENG-16, `onDmgTaken`→§11 mục 22), mỗi cái phải có entry mang `eng` khớp. Đối chứng "trước" phải bắt **≥4 DEAD**: `rerollRefund` (`r_voidgene` bản 3 — grep `src/` = 0, §10 = 0, `ENG-*` = 0), face type `blank` (`r_voidgene` bản 1 — 0/18 hero), `shieldself` (§7 E2), `onTurnEnd`/`onPoison` (§10 G2). Đây là §7 E1 mở rộng từ *điều kiện* tần suất 0 sang *cơ chế* tần suất 0 | **BLOCKING** |
| **AC-9b** | **`mload` KHỚP BẬC (làm rõ AC-9, vế bị vi phạm).** `∀x: x.mload > 0 ⇒ x.rar ≥ 1`. **Số vi phạm kỳ vọng: 0.** Đối chứng "trước": **1** — `r_wildfire` từng được đặt ở COMMON với `mload 1` (`burnSlow`). Hệ quả suy ra chứ không chọn tay: **`burnSlow` không thể tồn tại dưới RARE**, nên entry-point engine của INFERNO nằm ở RARE (§6.2) | **BLOCKING** |

**Bằng chứng bắt buộc để đóng story** (theo `.claude/docs/coding-standards.md`):
- `tools/t_relic.mjs` mới — AC-1..AC-11 và AC-15..AC-22, **BLOCKING**. Mọi AC loại trừ id khớp `/^__/`.
- `production/qa/smoke-[date].md` ghi output `node tools/sim.js` **trước/sau**, dùng **20.0%** (300 run, SHORT, asc 0, đo 2026-09-03) làm mốc "trước" — AC-12..AC-14.
- `tools/verify.mjs` giữ **32/32 PASS** (baseline đúng đo sau khi cài `node_modules`; các con số 29/30 và 28/30 từng lưu hành trong project là **cũ**, không dùng).
- `tools/t_import.mjs` giữ **23/23 PASS**.
- `tools/soak.mjs` + `tools/soakm.mjs` phải chạy sau INV-5 (đổi thứ tự `modFace` chạm vòng đời `.die`).
- **Không gate** vào `tools/t_fit.mjs`: nó vừa được sửa khỏi hardcoded path và đang lộ một lỗi layout 1280×720 **có từ trước, không liên quan relic**, đang được xử lý riêng.

> **Vì sao AC-25 tồn tại: cùng một lỗi đã xảy ra NĂM lần trong dự án này, mỗi lần một dạng khác.**
> Không lần nào là lỗi số học — cả năm đều là **một check không nhìn thấy được thứ nó tự nhận là
> đang kiểm**:
>
> | # | Sự cố | Vì sao check mù |
> |---|---|---|
> | 1 | Checksum có **ba** sai số **triệt tiêu lẫn nhau** | tổng đúng, mọi thành phần sai |
> | 2 | `AC-16` khẳng định một `FACE_POOL.length` **không bao giờ có thể đúng** | tiêu chí lấy từ mô hình, không từ dữ liệu |
> | 3 | `I14` hard-fail trên một luật **đã bị rút** | check sống lâu hơn luật nó bảo vệ |
> | 4 | `AC-21` pattern-match **cú pháp của lỗi** ⇒ mù ngay khi lỗi được sửa | bắt chuỗi ký tự, không bắt hành vi |
> | 5 | Token audit gọi `pierce` là "độc lập" | suy trên **hệ type**, không trên **tập mặt đã ship** |
> | 6 | Script kiểm §6.7.10 đọc **nhầm cột**: lấy `rar` (1) làm `RP trước` (43.00) | bảng 8 cột và 9 cột lẫn nhau; giá trị đọc ra **hợp lệ nhưng sai nghĩa** ⇒ không có gì báo động |
> | 7 | Gate đột biến của chính script đó kết luận **"check không thể fail"** trong khi nó **vừa bắt được** đột biến | nó so **số lượng** đơn vị fail; đột biến rơi trúng `a_pyre` vốn **đang fail sẵn** vì sự cố 6 ⇒ đếm không đổi |
>
> Sự cố 5 là của chính mục §3.7a này; **6 và 7 là của chính phép kiểm viết ra để chứng minh mục
> §6.7.10** — và 7 là loại tệ nhất: một gate được xây để phát hiện "check mù" đã **mù về chính sự
> mù của nó**. Cả hai chỉ lộ ra khi một người đọc **đối chiếu output với văn bản gốc** thay vì tin
> con số. Bài học gói lại thành một câu, và đó là AC-25: **một check phải được kiểm chứng bằng thực
> tại đo được, không bằng chính mô hình đã sinh ra nó.** Ba hệ quả thực hành rẻ nhất: (b) bắt mọi
> check mới **fail được một lần** trên input hỏng cố ý trước khi tin nó lúc xanh; (d) so **tập**
> đơn vị fail chứ không so **số đếm**; (e) mọi lần đọc theo chỉ số cột phải **tự kiểm kiểu ô**.
>
> **Kết quả sau khi sửa 6 và 7:** `V_out` của §6.7.10 được khớp với 8 con số `RP sau`, rồi cùng
> công thức đó tái tạo đúng **8/8** con số `RP trước` — một cột **không hề được dùng để khớp**.
> Đó là lý do §6.7.10 được coi là **mô hình khôi phục**, không phải số dò ngược.

## 13. Rủi ro đã chấp nhận & câu hỏi mở

**Rủi ro #0 — Đơn điệu nghiêm ngặt NÉN KHÔNG GIAN THIẾT KẾ. Product owner cần biết trước khi duyệt.**

Đây là cái giá trực tiếp của yêu cầu "không bậc dưới nào mạnh hơn bậc trên", và nó không thể tránh
được bằng cách viết công thức khéo hơn — nó là hệ quả số học của việc bốn tâm dải chỉ cách nhau
1.41×. Bốn hệ quả cụ thể:

1. **Trần LEGENDARY giảm 16%** (51.1 → 42.98 RP) và **sàn COMMON tăng 27%** (8.84 → 11.22 RP).
   Relic mạnh nhất game yếu đi; relic yếu nhất mạnh lên. Khoảng cách giữa "relic tệ nhất" và
   "relic mạnh nhất" co từ **5.8×** xuống **3.8×**. Người chơi sẽ cảm thấy LEGENDARY *ít choáng
   hơn* — đó là đánh đổi có ý thức để đổi lấy việc màu rarity nói đúng sự thật.
2. **Bề rộng mỗi bậc co từ 2.03× xuống 1.353×.** Hệ quả vận hành: **30/94 relic** cần một *rider*
   (cơ chế phụ nhỏ) chỉ để rơi vào dải, vì bước tăng tự nhiên của cơ chế nhảy qua cả dải. Ví dụ
   thật: `+2 Shield` = 10.96 (dưới sàn), `+3 Shield` = 16.44 (trên trần) — **không có giá trị
   nguyên nào hợp lệ** cho `r_carapace` nếu không thêm rider. INV-6 chặn rider khỏi biến relic
   thành hai relic, nhưng nó **không** làm cho rider bớt vụn.
3. **Ba trục mất hẳn một số bậc.** `poison` không thể có scaler ở COMMON *hoặc* RARE (bước nhỏ
   nhất = 22.5 RP). `startSummon` không có RARE (1 egg = 13.0 = COMMON, 2 egg = 26.0 = EPIC).
   `growth` **không có bậc nào** nếu không có `growthAll` (§10 G1) — nên G1 chuyển từ *nên có*
   sang **bắt buộc**, và EVOLVE không tồn tại được nếu G1 bị cắt scope.
4. **`a_ult` mất 80% giá bán được cảm nhận.** MP 10 → MP 18 biến thẻ ký hiệu của game thành
   một-lần-mỗi-trận. Về số học đây là bản sửa đúng (ở MP 10 nó là 95 RP = 2.2× trần LEGENDARY và
   **tự kết thúc encounter** trong 2 lần cast), nhưng nó là thay đổi *cảm giác* lớn nhất trong
   toàn patch và nên được playtest riêng.

**Lối thoát nếu owner thấy nén quá tay:** knob duy nhất đúng là **K1 `ANCHOR`** (scale cả bốn dải
lên, giữ tỉ lệ) — nó nới trần LEGENDARY mà **không** phá INV-1. Knob **sai** là K1b `τ`: nới `τ`
lên 0.20 khôi phục đúng khuyết tật owner đã khiếu nại. Nếu cần "LEGENDARY choáng hơn", câu trả lời
là `ANCHOR 13.2 → 15.0` (trần L thành 48.8), **không** phải nới dung sai.

**Ba rủi ro lớn nhất tiếp theo, chấp nhận có ý thức:**

1. **`mload` cap 2 sẽ hạ winrate tổng, và mức hạ chưa được đo.** Ở baseline 20% với 101/300
   run chết ở boss cuối, những run thắng gần chắc chắn là những run cộng dồn multiplier. Dự
   báo 14-17%, **chưa xác nhận**. Nếu thực tế < 14% thì hệ relic mới *khó hơn* hệ cũ dù công
   bằng hơn — và "công bằng hơn nhưng thắng ít hơn" là một cú đánh vào cảm nhận người chơi mà
   người chơi không nhìn thấy nguyên nhân. Van xả: K5.
2. **`Ω = 5` dưới-định-giá mọi relic scaling-theo-lượt ở đánh boss.** `plague`, `growth`,
   `thorns` (accumulator không giảm) và `startSummon` đều đáng giá hơn nhiều ở trận boss dài
   ~8 lượt — đúng chỗ run được quyết định. Nghĩa là relic AEGIS/PLAGUE/EVOLVE có thể mạnh hơn
   band ở đúng trận quan trọng nhất. Cần đo `Ω` thật theo loại encounter (K12) trước khi tune
   tiếp; doc này cố tình **không** đoán con số đó.
3. **`bias(a)` là vòng phản hồi có thể tự dao động.** Nó lấy winrate đo được để đặt ngân sách
   relic, và ngân sách relic lại đổi winrate. Với β = 0.5 và đo lại mỗi patch, hệ có thể lắc
   qua hai bên thay vì hội tụ. Giảm nhẹ: chỉ đo lại `bias` sau **≥2** lần sim 500-run ở hai
   seed khác nhau, và không bao giờ đổi `bias` cùng patch với đổi `κ` hay `RP_band`.

**Đã gác lại có chủ ý (không phải bỏ sót):**

- **Không thiết kế relic-slot economy** (giới hạn số slot + cho tráo relic). Nó giải quyết
  defect 6 êm hơn `mload` và tạo một quyết định mới thật sự, nhưng cần **UI mới** (màn chọn
  bỏ relic), một bề mặt hành động mới trong action log, và do đó rủi ro replay. `mload` đạt
  cùng mục tiêu chống-compound với **0 UI mới** và 1 hàm. Nếu product owner muốn thêm bề mặt
  quyết định thì slot economy là bước kế tiếp đúng, và §3.6 nên bị thay chứ không đắp thêm.
- **Không tách/gộp archetype nào ngoài việc thêm `exec`.** Có lý lẽ tốt để gộp
  `thorns` vào `shield` (chúng chia sẻ mặt `back`) hoặc tách `aoe` thành `cleave`/`aoe`. Nhưng
  sim cho AEGIS **winrate 25%, trên baseline** — nó không hỏng, nó không tới được. Gộp một
  archetype đang thắng để sửa vấn đề access sẽ là chẩn đoán sai.
- **Không định giá `echo`/`plague`/`bastion`/`overflow` như keyword.** Chúng là rule-break
  Mythic, được `part-skill-identity.md` §F4 miễn định giá. Doc này định giá **relic** cấp các
  luật đó (`firstEcho` 40.5, `plague` 13.5, `manaOverflow` 30.0) nhưng không định giá keyword
  trên mặt — đó là phạm vi doc kia.
- **Chưa viết 40 relic mới.** Thuộc `design/gdd/relic-roster-expansion.md` (§3.11).

**Câu hỏi mở cần product owner chốt:**

1. **`RELICS.length` 44 → 94 và Echo Box.** §7 E7 đề xuất cờ `collectionGrandfathered`. Có
   chấp nhận việc thanh Collection hiện `44/94` (thật) trong khi Echo Box vẫn mở, hay muốn
   ẩn/reset thanh đó? Đây là quyết định UX, không phải kỹ thuật.
2. **G2 `onDmgTaken`** — không có hook này thì AEGIS/BULWARK không có đường viết relic
   "khi bị đánh, …", tức 4 ô EPIC/RARE của hai archetype đó phải lấp bằng cơ chế gián tiếp
   yếu hơn. Có duyệt implement (b) không?
3. **K9 burn decay.** §4.7(2) kết luận sửa giá một mình không cứu INFERNO. Lối thiết kế
   (`burnSlow` làm entry-point) ship được ngay; lối engine (đổi decay nền) mạnh hơn nhưng là
   thay đổi balance toàn game. Ship lối thiết kế trước và đo, hay làm cả hai?
4. **A5 `critall`.** Nó cấp crit **tất định** (không `rnd()`), biến APEX từ archetype phương
   sai thành archetype có agency — đúng thứ §4.7(1) chẩn đoán. Nhưng nó cũng làm loãng bản sắc
   "crit là xổ số". Có muốn APEX đổi bản sắc theo hướng đó không?

---

## 14. QUYẾT ĐỊNH CỦA PRODUCT OWNER — 2026-09-03

Ba câu hỏi mở ở §13 đã được product owner phán. Đây là **quyết định đã chốt**, không phải đề xuất — mọi mục ở §13 và ở `relic-roster-expansion.md` §17.5 trái với bảng này đều bị bảng này thay thế.

| # | Câu hỏi | Quyết định | Hệ quả thi công |
|---|---|---|---|
| **QĐ-1** | Relic hook trong `data.js` có được gọi hàm của `engine.js` (`dealDamage`, `addStatus`, `mkAlly`…)? | **ĐƯỢC PHÉP.** Căn cứ: đã xác minh cả 3 đường load đều nối `data.js` + `engine.js` vào **một scope** — `build.py` (`FILES` nối `%DATA%` rồi `%ENGINE%`), `tools/t_import.mjs:11`, `tools/sim.js:10`. | Giải phán `A5` của roster: **9 relic** (`r_heartwood`, `r_broodmother`, `r_eggshell`, `r_apexbrood`, `r_hivequeen`, `r_cullingorder`, `r_deathspiral`, `r_ironmaiden`, `r_manaspring`) giữ trạng thái **"chạy hôm nay"**, không chuyển sang engine work. |
| **QĐ-2** | Có implement hook `onDmgTaken` không? | **CÓ.** Lý do: thiếu nó thì AEGIS/BULWARK không có cách nào diễn đạt "khi bị đánh thì…", và đó là một nguyên nhân cấu trúc khiến `thorns` chỉ có 2 relic. | Thêm `onDmgTaken` vào danh sách engine work **bắt buộc**, cùng lượt bump `ENGINE_VERSION`. Đồng thời sửa comment `src/data.js:354-356` cho đúng sự thật (bỏ `onPoison`/`onTurnEnd` nếu không implement, **thêm `onHit`** vốn đang bị thiếu) — xem `ENG-17` của roster. |
| **QĐ-3** | 3 bug có sẵn (giá shop `rar:4`, `a_ult` không crit được, `modFace` phụ thuộc thứ tự nhặt) | **SỬA CẢ 3** trong cùng bản relic này. | Gộp vào cùng một lượt bump `ENGINE_VERSION`. Cả 3 đã được xác minh trực tiếp từ source — xem §14.1. |

### 14.1 Ba bug có sẵn — bằng chứng đã xác minh

| Bug | Vị trí | Bằng chứng | Loại |
|---|---|---|---|
| **Giá shop `rar:4`** | `src/engine.js:858` | `cost:[45,75,120,180][r.rar]||60`. Với `r.rar===4` thì `[...][4]` là `undefined` → `||60` → **60**. Một relic Mythic sẽ **rẻ hơn một relic RARE (75)**. | Chưa kích hoạt (roster ship 0 relic `rar:4` đúng chủ đích), nhưng chặn hẳn tầng Mythic. |
| **`a_ult` không crit được** | `src/engine.js:569` | `dealDamage(s,u,tgt,a.v,{pierce:1,attack:true})` — opts **thiếu `crit`**, khác với `hit()` trong `doFace` vốn truyền `crit`. Nhưng `a_ult` gắn `a:'crit'`. | Sai tag + sai hành vi. Là `ENG-14` của roster. |
| **`modFace` phụ thuộc thứ tự nhặt** | `src/engine.js:54` | `for(const r of rlist(s)) if(r.modFace) r.modFace(u)`, và `rlist = s => (s.relics||[]).map(...)` — tức **thứ tự nhặt**. Nên `r_claw` (+1) rồi `r_ancientgene` (×1.4) ra `(v+1)×1.4`, đảo lại ra `v×1.4+1`. | **Không phải lỗi replay** — cùng thứ tự nhặt vẫn tất định nên ranked an toàn. Là **lỗi cân bằng**: hai người cùng bộ relic có sức mạnh khác nhau tuỳ thứ tự nhặt. Là `ENG-0` của roster. |

### 14.2 Còn mở, chưa phán

- **Echo Box UX** (§13) — chưa quyết. Không chặn implement: migration `collectionGrandfathered` đã đủ để không ai bị thu hồi.
- **Có đổi base burn decay không** (§13) — chưa quyết. Nên đo sau khi roster mới vào sim, vì `INFERNO` ở 10% winrate có thể do nguyên nhân khác (xem chẩn đoán §3.5 của roster).
- **APEX có nên thành archetype crit tất định qua `critall`** (§13) — chưa quyết. Roster đã ship 4 relic APEX theo hướng sửa 4 defect độc lập; nên đo trước khi thêm hướng thứ 5.
