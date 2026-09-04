# Axie Dice Tactics: Lunacia Mutants
## Overview — v2.0 · trạng thái ĐÃ SHIP, đo ngày 2026-09-05

*Bản v1.0 (`docs/axiedice-source/design/SDD_GDD_OVERVIEW_v1.md`) được viết **trước khi
implement**. Nó vẫn là tài liệu lịch sử tốt về ý định thiết kế, nhưng không còn dùng
được để hiểu game hiện tại.*

**Mọi con số trong bản này được đo từ code, không chép từ tài liệu.** Chỗ nào là ý
định chưa build thì ghi rõ. Cách kiểm lại: `node tools/ci.mjs` (11 gate) và các truy
vấn nêu trong từng mục.

---

## 0. Bản v1.0 lệch ở đâu — đọc mục này trước

Nó lệch theo **cả hai chiều**, nên không thể dùng "trừ bớt" để suy ra hiện tại.

### Có trong v1.0 nhưng CHƯA BAO GIỜ ĐƯỢC BUILD

| Hệ | v1.0 mô tả | Thực tế trong code |
|---|---|---|
| **Mastery** + Pin | §7.4, một trong bốn trụ meta | `grep -ic mastery` = **0** |
| **Meta Morph** | §5, "van xả bắt buộc" | **0** |
| **DECLARE (Gọi mặt)** | §8, phương án combo được chọn | **0** (chữ "declare" duy nhất là comment CSS) |
| **Axie Forge** | §7.4, ghép 6 part thành Lead | **0** — "forge" trong code là lựa chọn ở event campfire (`+30%` cho 1 Axie), việc khác hoàn toàn |
| **Moon Dust** (tiền cứng) | §7.3 | **0** |
| **Gauntlet** + vé | §7.3, §12 | **0** |
| **`economy_config.json`** | §11, "mọi số đọc từ file này" | File **không tồn tại**. Số cân bằng nằm trong `src/data.js`; dữ liệu ngoài duy nhất là `assets/data/part_faces*.json`, và nó là **file sinh ra**, không phải config sửa tay |

Hệ quả: **toàn bộ §7.5 (monetization) và phần lớn §7.3–7.4 của v1.0 là thiết kế trên
giấy.** Game hiện tại chưa có đường kiếm tiền nào.

### KHÔNG có trong Phase 1 của v1.0 nhưng ĐÃ SHIP

| Hệ | v1.0 nói | Thực tế |
|---|---|---|
| **Leaderboard** | §12: "không có trong Phase 1" | Đã ship, có **chống gian lận bằng replay phía server** |
| **Lớp NFT / import Axie thật** | §12: Phase 2 | Đã ship — `scImportAxie`, `api/axie.js`, gate `t_vault` |
| **Tài khoản người chơi** | Không nhắc | Đã ship, và là **cửa bắt buộc** trước khi chơi (§8) |
| **Secret class** Dawn/Dusk/Mech | §5: Phase 2, "gần như miễn phí" | Đã có trong catalog part (9 class, không phải 6) |
| **Nhạc nền** | Không nhắc | Đã ship (§9) |

---

## 1. Tổng quan

**Thể loại:** roguelike chiến thuật theo lượt, xúc xắc, **tất định**
**Nền tảng:** web, một file HTML tự chứa (~2,4MB), deploy Vercel
**Bản chạy:** https://axiedice.vercel.app
**IP:** Axie Infinity — tên part, class, art part gốc

Trụ cột giữ nguyên từ v1.0 và **đã được thực thi đúng**: người chơi thấy 100% ý định
địch trước khi hành động (địch roll trước, hiện rõ mặt *và* mục tiêu), có preview sát
thương chính xác trước khi bấm, và `UNDO` tự do trong lượt.

Đây là lát cắt thị trường thật: Slay the Spire và Dicey Dungeons đều dựa trên **ẩn**
thông tin. Game này đi ngược hẳn.

---

## 2. Vòng lặp

```
MACRO : Unlock (10 mục) · Collection · Lunacia Pass (30 mốc) · Echo Points · Vault
MESO  : một RUN — 12 wave (~15 phút) hoặc 20 wave (~35 phút)
MICRO : một LƯỢT — Roll → Reroll → Execute → End Turn
```

Party **5 Axie**. Hết mỗi trận: heal đầy + hồi sinh toàn bộ Axie đã chết — không có
attrition giữa các trận.

| | Wave | Elite @ | Boss @ | Thời lượng |
|---|---|---|---|---|
| SHORT RUN | 12 | 3 · 6 · 10 | 4 · 8 · 12 | ~15 phút |
| FULL RUN | 20 | 3 · 7 · 12 · 17 | 5 · 10 · 15 · 20 | ~35 phút |

Boss theo thứ tự cố định: `gooey_king → frost_lord → agony` (short) ·
`gooey_king → mecha → plague_mother → agony` (full). Tổng **6 boss**, **22 monster
thường**, **6 event**, **10 mức Ascension**.

Input thật là **click-click**: click mặt đã roll → click mục tiêu hợp lệ. **Không có
kéo-thả** (`grep -c "dragstart\|draggable"` = 0) — v1.0 và một bản `.claude/docs/technical-preferences.md`
cũ từng ghi sai chỗ này.

---

## 3. Part → mặt xúc xắc: hệ đã được xây lại

Đây là thay đổi lớn nhất so với v1.0.

**Bug gốc:** `axieToDie()` cũ tra mặt trong bảng 36 ô `(slot × class)`, nên **hai Axie
cùng class ra viên xúc xắc y hệt nhau**. Đo lại, 36 ô đó co về **19 mặt phân biệt được
ở tầng engine** — mọi Axie trong game dùng chung một mặt `ears: mana 1 cantrip`.

**Hiện tại: 285/285 mặt phân biệt, 0 mặt bị trùng**, giống nhau ở cả hai profile ngân
sách (`B[C]` = 2.80 và 6.00).

| | |
|---|---|
| Part trong catalog | **285** |
| Mặt signature (part có mặt riêng) | **81** |
| Mặt theo biến thể family | **204** |
| Class trong catalog | **9** — 6 class chơi được + `dawn`/`dusk`/`mech` |
| Bậc khan hiếm | C 174 · O 75 · P 18 · X 18 |
| Thang `specialGenes` | 11 bậc (`normal … mystic`, `agamogenesis`) |

Secret class map về class gốc khi vào trận: `dawn→beast`, `dusk→reptile`, `mech→bug`.

**`src/part_faces.js` là FILE SINH RA — không sửa tay.** Nguồn cùng một lần chạy:
`assets/data/part_faces.json`, sinh bởi `tools/gen_faces.mjs`. Muốn đổi bảng mặt thì
sửa generator rồi regen:

```bash
node tools/gen_faces.mjs                     # ghi lại .json và .js
node tools/gen_faces.mjs --check --strict    # verify, không ghi
```

### Keyword

**29 keyword** thật xuất hiện trên các mặt (v1.0 dự kiến 27, danh sách đã đổi):

```
aoe bastion blind burn cantrip chain cleave crit decay echo exec freeze growth
heavy lifesteal mana multi overflow pierce plague poison regen rerollup selfharm
thorns undying vital vulnerable weaken
```

Phân bố loại mặt: `dmg` 110 · `shield` 34 · `mana` 29 · `debuff` 20 · `heal` 16 ·
`poison` 15 · `summon` 3 · `buff` 1.

---

## 4. Relic: hệ đã được xây lại

Cũng là một đợt làm lại từ nền. **Không có GDD nào tồn tại trước đó**, và đo ra thì
35/44 relic nằm ngoài dải bậc của chính nó, 61/92 vi phạm tính đơn điệu theo bậc. Dải
±20% cũ làm chồng lấn là **chắc chắn về mặt số học**: `(1+τ)/(1−τ) = 1.50 > 1.4130`.
Ca tệ nhất: `a_ult` đạt 95.0 RP (2,2× trần LEGENDARY) mà vẫn được thang điểm cũ chấm
"+9%, đúng"; và `a_wall` là một RARE mạnh hơn mọi LEGENDARY.

**Hiện tại: 94 relic, 0 vi phạm, các dải rời nhau do cấu trúc ở τ=0.15.**

| | |
|---|---|
| Tổng | **94** — 78 bị động (`r_`) + 16 chủ động (`a_`) |
| Theo bậc | active 16 · rar1 29 · rar2 28 · rar3 21 |
| Trần giữ trong 1 run | **10** (`RELIC_CAP`) |
| Trần chống stack | `mload` tổng ≤ **2** |
| Giá shop | 45 · 75 · 120 · 180 · 260 |

Đợt này cũng sửa 4 cặp "dead draw" tìm được bằng cách **chạy `modFace` trên toàn bộ
68 mặt thật**, không phải bằng đọc: `r_spines`/`r_scalecrown` trùng hệt luật và giá
trị; `r_gorehook ⊂ r_apexferal`; `r_windlash ⊂ r_stormcall`;
`r_pierceall ⊂ r_worldpiercer`.

Và một bug im lặng: `ARCH` thiếu `exec`, khiến `archScore()` **luôn trả 0 cho mọi hero
Beast**.

---

## 5. Combo: Formation Resonance, không phải DECLARE

v1.0 chọn DECLARE. **DECLARE chưa bao giờ được build.** Cơ chế thật là **Formation
Resonance**: hai Axie **liền kề trong đội hình** cùng roll ra mặt **cùng loại** trong
cùng một lượt → Axie thực thi **sau** nhận bonus giá trị mặt.

```js
RESONANCE = { mult: 1.15, types: ['dmg','shield','heal','poison','mana'] }
```

**Là +15%, không phải +25%.** Spec (`design/quick-specs/formation-resonance-2026-09-01.md`)
cho dải an toàn 1.15–1.40 và chỉ định 1.15 khi team dmg-stack quá mạnh; code ra đời đã
là 1.15 (commit `5f54429`), chưa bao giờ là 1.25. Chỗ **thật sự còn lệch** là §Formulas
của spec vẫn ghi "1.25 (mặc định)" trong mọi ví dụ tính toán.

Đây là cơ chế đầu tiên khiến **thứ tự sắp đội hình** và **thứ tự click thực thi** trở
thành quyết định có ý nghĩa.

Ngoài ra: **11 archetype** có tracker, **10 rune**, **4 keyword Mythic** (`plague`
`echo` `bastion` `overflow`), **5 bậc rarity** gồm cả `MYTHIC` (v1.0 xếp Mythic vào
Phase 2 — nó đã có trong `RARITY`).

---

## 6. Cân bằng — số đo, không phải mục tiêu

| | Short Run (12 wave, A0) | Full Run (20 wave, A0) |
|---|---|---|
| Winrate | **19.8%** | **8.0%** |

Đo bằng `node tools/sim.js 500 mode=X asc=0`, ghi trong `design/gdd/game-concept.md`.
Trước đợt tune 2026-09-01 là 16.4% / 3.6%; hạ `growth2` 1.065→1.05 và `eliteMult`
1.40→1.25 đưa lên số hiện tại. **Full Run 8.0% đang VƯỢT mục tiêu ≥6%** — đừng "sửa"
nó.

**Cảnh báo quan trọng khi đọc con số này:** `tools/ci.mjs` in ra headline **18.3%**, và
đó là winrate của **bot heuristic** (`threat()` + tự reroll mặt xấu), không phải của
người chơi. Header của chính nó ghi *"balance probe, not a gate"*. Khoảng cách giữa bot
ngây thơ và người giỏi là **có chủ đích** — nó là chỗ để người chơi cảm thấy mình giỏi lên.

Ba lỗi chỉ tìm ra được bằng chạy sim (giữ nguyên từ v1.0, vẫn đúng):
1. Status/debuff scale tuyến tính tạo tường bất khả thi — fix: mặt hiệu ứng theo thời
   gian scale `s^0.50`, buff/debuff `s^0.45`.
2. Player power đứng yên sau khi hero max tier → cliff wave 14–20 — fix: budget
   piecewise + reward **Ascension**.
3. Thorns/summon của boss scale tuyến tính → death spiral — fix: giảm hệ số + hard cap.

Hero: **18** (6 class × 3 tier), `FACE_POOL` 55 mặt.

---

## 7. Meta-progression — cái gì thật sự có

| Hệ | Trạng thái |
|---|---|
| **Unlock** | 10 mục, tổng **3.450 shard** |
| **Lunacia Pass** | **30 mốc**, XP mỗi mốc `45 + 22(n−1)`, **không giới hạn thời gian, không nhánh trả tiền** |
| **Echo Points** | Sink cuối game — 5 bậc (`Waning · Crescent · Gibbous · Full · Eclipse`), 6 title |
| **Collection** | Có |
| **Vault** (import Axie NFT thật) | Có, kèm migration schema-2 |
| Gene Shard | Đồng tiền **duy nhất** |
| Moon Dust · Gauntlet · Mastery · Forge · Meta Morph | **Chưa build** |

Battle Pass không giới hạn thời gian và không có nhánh trả tiền là **thiết kế đạo
đức đáng giữ** — đừng đổi nó khi thêm monetization.

---

## 8. Tài khoản: cửa đăng nhập BẮT BUỘC

Không có trong v1.0. Đây là **rào cản lớn nhất của game hiện tại**, nên phải nêu rõ.

`src/client.html:4162` → `if(!authToken) screen='gate'`. Màn hình đầu tiên của người
chơi mới **chỉ có LOG IN / REGISTER**: không gameplay, không demo, không chế độ khách.

Đây là **chủ đích** (`design/gdd/player-accounts.md` §3, bản sửa ADR-0002 ngày
2026-09-01), không phải bug. Nhưng GDD tự ghi nhận rủi ro: **beta không có luồng khôi
phục mật khẩu**, nên quên mật khẩu là mất quyền chơi game, không chỉ mất đồng bộ.

Đánh giá thiết kế: Slay the Spire, Balatro, Luck be a Landlord đều cho chơi ngay.
Leaderboard là tính năng **giữ chân** người đã thích game, nhưng ở đây nó đang bị đặt
làm cửa **thu hút** người chưa biết game là gì. Hạ tầng để bỏ gate đã có sẵn (engine
vốn offline-first) — sửa gần như là một dòng.

Ba comment trong code vẫn ghi *"Entirely additive to guest play"* / *"guests never see
server calls"* — **đã lỗi thời**, sót lại từ thiết kế trước bản sửa ADR.

---

## 9. Audio — SFX tổng hợp + nhạc nền file ngoài

**26 SFX**, toàn bộ **tổng hợp thời gian thực** bằng Web Audio (oscillator + noise lọc),
0 byte asset: `ui hover tray tumble land heavy hit crit heal shield mana poison burn die
kill reroll legend levelup passClaim mythic warn boss win lose coin open`.

**Nhạc nền là asset ngoài, tải lười** — audio là loại asset duy nhất mà luật "một file"
hết đáng: một loop dùng được nặng 1–3MB so với trang 2,4MB tải trong một request.

```
intro   5,1675s → 17,4000s   (6 ô nhịp, 12,23s)  — chạy MỘT lần mỗi session
loop   17,4000s → 86,7174s   (34 ô nhịp, 69,32s) — lặp mãi
```

Cắt trên lưới nhịp đo được từ nguồn: **117,719 BPM**, ô nhịp 4/4 = **2,0387s**,
downbeat ở `1,0900 + n × 2,0387`. Chỗ nối dùng crossfade **50ms equal-power** ghép phần
chạy tiếp sau điểm kết vào đầu loop — đo được bước nhảy 1181 so với p95 1405 của chính
bài, tức không nghe thấy. Tổng **1,3MB AAC**.

Tách intro/loop không phải sở thích: thân bài không đạt mức âm lượng đầy đủ trước giây
17,2, nên loop bắt đầu sớm hơn sẽ thấp hơn thân 33–50% RMS, mà nâng lên cho bằng thì
**clip** (peak đã 30k/32767, cần ×2).

Nhạc **là tuỳ chọn theo thiết kế**: không có file, sai codec, load qua `file://`,
autoplay bị chặn — mọi đường đều dẫn tới game im lặng nhưng chạy hoàn hảo. `build.py`
quét `assets/audio/` và tiêm `AUDIO_MANIFEST`; client **không bao giờ request file
không có trong manifest**, vì `<audio>` 404 bị chính browser log và làm gate A11
("không có console error") không thể xanh.

Chi tiết + quy trình cắt loop: `assets/audio/README.md`.

---

## 10. FX / juice

Có sẵn: **shake 3 cấp** theo damage, **hitstop 110ms** khi crit, số damage bay lên to
hơn khi crit hoặc ≥25 dmg, HP bar đổi màu, xúc xắc đã dùng làm mờ, badge relic có
throttle, và **"HOLD MOUSE OR SPACE TO FAST FORWARD"**.

**Tier OVERKILL** (mới): một đòn giết ≥2 địch **hoặc** lấy ≥50% max HP của boss →
`hitstop(260)` + `flashScreen('myth')` + `shake(3)` + `bigText('OVERKILL ×N')`. 260ms
cao hơn crit (110) và mythic (140) nên đọc ra là một nhịp riêng. Tái dùng toàn bộ
primitive có sẵn nên **thừa hưởng miễn phí hợp đồng photosensitivity** (`wantsLessFlash()`).

Phát hiện đáng ghi lại: `death` event chỉ mang `uid`, **không mang phe**
(`engine.js:533`), và `thorns` (`engine.js:548`) phản damage có thể giết chính người
đánh. Đếm death một cách hồn nhiên sẽ **ăn mừng khi quân mình chết**. Nên
`overkillMarks()` tra ngược qua `byUid()` và lọc `u.side==='p'`.

---

## 11. Kiến trúc

v1.0 mô tả `engine.js / data.js / ui.js / sim.js` rời nhau. **Đã gộp lại** (2026-09-03,
10 file → 6):

```
src/client.html    TOÀN BỘ client: CSS + audio + icons + log + ui + fx + music
                   (có mốc /* ─── name.js ─── */ ở biên module cũ)
src/engine.js      luật chơi, thuần logic, seeded RNG, undo bằng deep-clone
src/data.js        cân bằng: 94 relic, 22 monster, 6 boss, curve, BP, unlock
src/part_faces.js  SINH RA bởi tools/gen_faces.mjs — không sửa tay
src/devtools.js    build.py public STRIP file này
src/art.js         1,8MB base64 (art.js là 1 dòng 232.878 ký tự) — đừng đọc
src/cosmetics.js
```

Bốn file cố tình **không** gộp, mỗi cái một lý do cứng:

- `engine.js` + `data.js` — `api/_engine.js` đọc chúng **từ đĩa** vào Node VM để replay
  lại điểm Leaderboard. Gộp vào client là mất chống gian lận.
- `devtools.js` — `devGo()` nhảy được mọi màn và tự cấp `META.shards=900` + relic.
  Gộp vào là ship bộ cheat lên production trong khi Leaderboard ranked đang chạy.
- `art.js`/`cosmetics.js` — base64 thuần, gộp vào chỉ làm mọi lần đọc file tốn context
  vô ích.

**27 màn hình** là các hàm `sc*` trong `client.html`; không có scene system, mỗi lần đổi
state là re-render cả màn.

**Backend** (Vercel Functions + Upstash Redis), 9 endpoint: `auth` `_auth` `_engine`
`axie` `leaderboard` `submit-run` `sync-save` `telemetry` `admin-stats`.

### Build & deploy

```bash
python3 build.py            # → AxieDiceTactics.html (bản dev, CÓ devtools)
python3 build.py public     # → index.html (đã strip devtools)
bash tools/vercel-build.sh  # đúng cái Vercel chạy; dựng build/ + copy nhạc
```

`vercel.json` chỉ gọi script, vì `buildCommand` bị Vercel giới hạn **256 ký tự** —
chuỗi inline từng dài 293 và làm mọi deploy fail trước khi build kịp chạy.

```bash
vercel deploy --prod --yes --scope axielatro
```

`--scope` là **bắt buộc** (project thuộc team `axielatro`, CLI mặc định dùng tài khoản
cá nhân). Deploy **không cần commit, không cần push** — nó upload thư mục local.

---

## 12. QA — 11 gate

`tools/ci.mjs` là **entry point duy nhất**. Chạy suite lẻ là cách ba suite từng mục
rữa mà không ai biết.

```bash
npm install && npx playwright install chromium   # BẮT BUỘC, xem bẫy #1
node tools/ci.mjs            # cả 11 gate
node tools/ci.mjs --fast     # 7 gate logic, không browser
```

| Gate | Sàn hiện tại |
|---|---|
| generator snapshot ×2 (production + reference) | GREEN |
| part-skill face pins | 44 / 0 |
| import mapping | 43 / 0 |
| relic invariant | **94 / 94 INV-1** |
| relic behaviour | **38 proof** |
| headless sim | 18.3% (thông tin, không phải gate) |
| AoE / summon | PASS |
| vault migration | 8 / 0 |
| viewport fit | PASS |
| **UI rules (build đã serve)** | **37 / 37** |

**Không được để tụt.** Sàn `tools/verify.mjs` từng ghi 29/30 trong khi suite đã lên 37 — một
con số sàn lỗi thời không chỉ sai, nó **cho phép một regression thật đi qua review**.

### Bốn bẫy đã ngốn thời gian thật

1. Chưa `npm install` → `verify`/`t_aoe`/`t_fit`/`t_vault` chết ở
   `import { chromium } from 'playwright'`. Trông như 4 suite hỏng, thực ra thiếu 1
   dependency.
2. Port **5173** (ci.mjs hardcode) bị session khác chiếm → test nhầm file người khác.
   Kiểm `lsof -nP -iTCP:5173 -sTCP:LISTEN` trước.
3. Server trỏ sai thư mục cho dấu hiệu **y như bug CSS**: `tools/verify.mjs` báo `A4` thiếu
   token + `B0` "0 width query". Đó là 404, không phải bug CSS.
4. Một check "luôn pass" có thể là đang không chạy, **hoặc chạy trên file cũ**.
   `t_vault` từng nằm trên bước build nên pass bằng build cũ. Suite dùng playwright
   PHẢI nằm dưới bước build.

### Nợ chất lượng đã biết

- 🔴 **`api/submit-run.js` không xác thực người gọi.** `displayName`/`walletAddr` lấy
  trực tiếp từ body (`:59`), file chỉ `require('./_engine')` — **không import `_auth`**,
  trong khi `api/auth.js` / `api/sync-save.js` / `api/telemetry.js` đều dùng. Ai cũng submit được điểm
  **dưới tên người khác**, và không có rate-limit. *Chống giả mạo điểm số thì làm rất
  tốt* — server replay lại toàn bộ hành động; lỗ hổng ở **danh tính**, không ở **điểm**.
- 🟠 **"37/37" nhỏ hơn tưởng.** `tools/verify.mjs` chỉ chạy bộ check đầy đủ trên **2 trong 27**
  màn (`menu`, `combat`). Shop/Vault/Leaderboard/Event/Reward/Account/Codex chưa từng
  được quét tự động.
- 🟠 **Không chơi được bằng bàn phím.** `tabindex` xuất hiện **đúng 1 lần** trong toàn
  `client.html`, và là selector CSS chứ không phải attribute. `.die`/`.unit` không
  focus được. P0 từ 2026-08-31, vẫn còn.
- 🟠 **`api/submit-run.js` là vùng vỡ nhiều nhất** — 4 commit sửa lỗi kể từ khi ra đời,
  và comment trong code tự thừa nhận một ca "replay divergence" ở production **chưa tái
  hiện được**, hiện chỉ đang vá bằng logging.
- 🟠 **`tools/soakm.mjs` 5 `NOPROGRESS`** chưa điều tra — cùng vùng drag/drop từng gây bug nặng nhất.
- 🟠 **Một ca đơ bàn chơi chưa tìm ra nguyên nhân** (báo 2026-09-05): không đánh được
  con nào cho tới khi abandon run. `body.playing` đặt `pointer-events:none` và
  `client.html:3766` chặn click khi `playing`. Watchdog chống khoá đã siết từ 12s/2s
  xuống **5s/1s** và ghi lại trạng thái lúc khoá — playback dài nhất đo được là 3,3s
  nên 5s không thể bắn oan. **Nếu tái diễn: đợi 5 giây, đừng abandon**, và lấy dòng
  `input lock released by watchdog after …` trong Console.
- 🟡 `tools/t_fit.mjs:15` lấy node đầu tiên trong `[battle,elite,boss]` nên gần như luôn test
  battle thường; bug boss từng vô hình vì thế.
- 🟡 Spec Formation Resonance vẫn ghi 1.25 trong §Formulas (xem §5).

---

## 13. UI

- **6 cỡ chữ:** `--t1..--t6` = **11 / 13 / 15 / 20 / 28 / 44 px**. (v1.0 ghi
  9/11/13/17/26/40 — đã đổi; **9px đã bị loại bỏ**, badge mặt heavy từng dùng nó đã
  được đưa về thang chữ.)
- Token `--faint` **không bao giờ được đưa lại**.
- 3 breakpoint thật: **1199 / 899 / 599px**. `--ui-scale` (qua `zoom` trên `#app`) chỉ
  là lớp polish cuối, áp dụng khi `innerWidth ≥ 1200`.
- Landscape-only; phone dọc hiện prompt "rotate your device".
- 8 luật UI bắt buộc: `docs/axiedice-source/ORIGINAL_PROJECT_CLAUDE.md`.

`engine.js` phát ra luồng event `s.ev`; phần `fx.js` của `client.html` replay lại để
làm animation. **Mọi mechanic không emit event sẽ đúng số nhưng VÔ HÌNH với người chơi** —
đây là bẫy thiết kế quan trọng nhất của kiến trúc này.

---

## 14. Đánh giá thiết kế — điều đáng làm tiếp

Theo thứ tự tác động/công sức, từ đợt review 2026-09-04:

1. **Bỏ gate đăng nhập bắt buộc cho chế độ chơi thường**, chỉ yêu cầu tài khoản khi nộp
   điểm Leaderboard. Tác động lớn nhất, công sức thấp nhất. Đây là việc duy nhất quyết
   định game **có ai chơi thử hay không**.
2. **Ràng buộc danh tính + rate-limit cho `api/submit-run.js`.** BLOCKER; càng cấp thiết
   nếu làm việc 1.
3. **Mở rộng `tools/verify.mjs`** ra Shop/Vault/Leaderboard/Event — 4 màn có tương tác
   tiền tệ và dữ liệu người dùng cao nhất.
4. **Bàn phím cho `.die`/`.unit`/`.nodecard`** — P0 treo từ 2026-08-31.
5. **Điều tra 5 `NOPROGRESS`** của `tools/soakm.mjs` và ca "replay divergence" chưa tái hiện.

### Điểm mạnh nhất

Độ sâu build là thật: **94 relic đổi LUẬT** (`modFace`/`onKill`/`onHit`/`onDmgTaken`),
không chỉ cộng số; **11 archetype**; 6 class × 3 tier với passive khác luật hẳn nhau;
Formation Resonance. Và chống gian lận bằng **replay tất định** là cách làm đẹp, hiếm
thấy ở indie — nó khai thác đúng bản chất pure-function của engine.

### Điểm yếu nhất

**Onboarding → hook.** Mọi thứ gây nghiện ở trên đều thiết kế cho người **đã ở trong
game**, nhưng gate đăng nhập chặn ngay cửa vào. Dù bên trong có hay đến đâu, số người
chạm được tới nó bị cắt nghiêm trọng ngay từ đầu phễu.

---

## Phụ lục — nguồn để đọc tiếp

| File | Nội dung |
|---|---|
| `design/gdd/part-skill-identity.md` (3487 dòng) | hệ part→skill, 285 mặt |
| `design/gdd/relic-system.md` (2462) + `relic-roster-expansion.md` (1977) | relic 94 |
| `design/gdd/game-concept.md` | concept + số winrate đo được |
| `design/gdd/player-accounts.md` | gate đăng nhập, ADR-0002 |
| `design/gdd/leaderboard-system.md` | leaderboard, replay-verify |
| `design/quick-specs/formation-resonance-2026-09-01.md` | Resonance (§Formulas còn ghi 1.25) |
| `docs/axiedice-source/ORIGINAL_PROJECT_CLAUDE.md` | 8 luật UI — nguồn sự thật |
| `assets/audio/README.md` | nhạc: quy trình cắt loop + số đo |
| `production/session-state/active.md` | trạng thái phiên, việc còn mở |
| `docs/axiedice-source/design/SDD_GDD_OVERVIEW_v1.md` | **bản v1.0 — lịch sử, đọc §0 trước** |

Khi bản này mâu thuẫn với v1.0: **bản này đúng** cho trạng thái đã ship, v1.0 đúng cho
ý định thiết kế ban đầu. Khi bản này mâu thuẫn với **code**: code đúng, và hãy sửa bản
này trong cùng commit.
