# Rule Spec — Axie Dice Tactics (nền tảng cho việc port sang Godot 4)

> **Mục đích tài liệu này**: mô tả đúng luật chơi HIỆN TẠI của Axie Dice, độc lập với cách
> code JS (`engine.js`/`data.js`) được tổ chức, để làm đầu vào cho bước thiết kế kiến trúc
> Godot (Bước 1: plan mode + subagent review, TRƯỚC khi viết GDScript thật — xem bảng
> "Quyết định thiết kế đã chốt cho bản port Godot" ở cuối file này).
> KHÔNG dùng tài liệu này để "dịch" code JS từng dòng — dùng nó để dựng lại đúng luật chơi
> theo kiến trúc scene/node tự nhiên của Godot.
>
> Trích xuất trực tiếp từ `src/engine.js` (1278 dòng, đọc toàn bộ), `src/data.js` (1071 dòng,
> đọc toàn bộ), `design/gdd/game-concept.md`, `design/gdd/economy-progression.md`,
> `design/gdd/part-skill-identity.md`, `docs/axiedice-source/ORIGINAL_PROJECT_CLAUDE.md`.
> Khi code và tài liệu cũ lệch nhau, **code luôn là nguồn sự thật** (xem mục Discrepancy ở cuối).

---

## 1. Core loop tổng thể

```
NEW GAME(seed, team 5 hero-key, mode Short|Full, ascension 0-10)
  → xây roster (5 Axie), phase='map', gọi nextStep()

MỖI STEP (1..len):
  - step 1            → LUÔN 1 node bắt buộc: {battle}  (không có lựa chọn)
  - step ∈ bossSteps   → LUÔN 1 node bắt buộc: {boss}
  - mọi step khác      → 2 node được đề nghị (KHÔNG có lựa chọn thứ 3):
                          option A = {battle} hoặc {elite} (elite nếu step nằm trong eliteSteps)
                          option B = 1 trong {event, event, treasure, (shop nếu step≥3),
                                     (elite nếu step≥4 và A không phải elite)} — LUÔN khác type A
                          thứ tự hiển thị A/B bị xáo ngẫu nhiên (50/50)
  Người chơi chọn 1 trong các node → vào combat / event / shop / treasure

SAU MỖI NODE (afterNode()):
  - nếu step vừa xong là boss cuối (step>=len) → phase='won', RUN THẮNG
  - ngược lại → nextStep() sinh step kế tiếp

COMBAT (xem §3) → thắng: nhận reward (chọn 1/N) → afterNode()
                → thua (mọi Axie thật đều hp=0, token/egg không tính): phase='lost', RUN THUA NGAY (không có "mạng" hay tiếp tục)
EVENT: chọn 1/3 lựa chọn text → áp dụng hiệu ứng → afterNode()
SHOP: mua 0-N item bằng Gene Shard (không bắt buộc mua) → bấm "xong" → afterNode()
TREASURE: nhận reward miễn phí (tier 1) → afterNode()
```

**Độ dài run**: `RUN_LEN.short = {len:12, boss:[4,8,12], elite:[3,6,10]}`,
`RUN_LEN.full = {len:20, boss:[5,10,15,20], elite:[3,7,12,17]}` (Full mở khoá qua `u_full`,
120 Shard). Boss giữa (không phải boss cuối) có 50% cơ hội bị thay bằng 1 trong
`BOSS_ALT=['frost_lord','mirror']` mỗi run. Đây KHÔNG phải nguồn RNG duy nhất ảnh hưởng
cấu trúc run: mỗi step non-boss còn roll loại node option B ngẫu nhiên từ pool (`pick()`,
`nextStep()`) và thứ tự hiển thị A/B (`rnd()<0.5`); ở Ascension≥9, vị trí Elite bổ sung cũng
được chọn ngẫu nhiên (`ri(rl.len-1)`, `newGame()`).
Boss cuối luôn là `agony` (NIGHTMARE AGONY, 2 phase).

**⚠️ Bản JS hiện tại KHÔNG có bản đồ phân nhánh thật** (không có node graph 2D, không có
nhiều đường đi hội tụ/phân kỳ, không có preview toàn bộ tuyến đường). Nó là một **chuỗi
tuyến tính các "step"**; tại mỗi step, người chơi chỉ chọn giữa 2 *loại* node cho chính step
đó, không chọn đường đi xa hơn.
→ **Quyết định đã chốt cho bản Godot**: xây RunMap graph phân nhánh thật kiểu Shroom and
Gloom/Slay the Spire (nhiều node hiện cùng lúc, nhiều đường hội tụ về boss) — đây là
**thiết kế mới**, không phải port 1:1. Chi tiết cấu trúc graph (số node/hàng, thuật toán
sinh, cách giữ nguyên độ khó đã balance theo `pw` ở §9) được thiết kế riêng ở bước kiến
trúc — xem `/Users/loc.tien.nguyen/.claude/plans/mellow-scribbling-mochi.md` (kiến trúc
Godot đã duyệt) §7.

**HP không carry giữa các trận**: dù thắng hay thua 1 combat, trước combat kế tiếp toàn bộ
party hồi đầy máu (`buildUnit` luôn set `u.hp=u.maxHp`) và Axie đã chết "sống lại" (roster
không lưu trạng thái chết, chỉ lưu maxHp/muts/growth). Độ khó nằm ở **từng trận riêng lẻ**,
không phải hao mòn tích luỹ qua nhiều trận.
→ **Quyết định đã chốt cho bản Godot**: **giữ nguyên** — không thêm cơ chế camp/nghỉ hồi
máu dần giữa các trận, tiếp tục full-heal tự động trước mỗi trận.

**Ngoại lệ hẹp duy nhất**: relic hiếm `growthKeep` giữ lại MỘT NỬA phần "growth" (không phải
HP) mà roster kiếm được mỗi trận, qua các trận trong CÙNG một run, có trần cứng
`GROWTH_KEEP_CAP=3`/mặt (`finishCombat()`, `engine.js` ~986-993). Đây là carry-over duy nhất
giữa các combat trong game — không mâu thuẫn với luật full-heal ở trên vì đối tượng carry là
face growth của roster, không phải HP/shield/status.

**Thắng/thua run**:
- Thua 1 combat bất kỳ → `s.phase='lost'` ngay lập tức → **thua cả run** (không có
  checkpoint/"mạng").
- Đánh bại boss cuối (step == len, thuộc bossSteps) → `s.phase='won'` → **thắng run**.

---

## 2. Cơ chế xúc xắc

- Mỗi Axie = 1 viên xúc xắc **6 mặt**. Đội hình = **5 Axie** (party 5 slot cố định,
  `s.roster` length 5). Địch cũng roll die 6-mặt riêng.
- **Roll**: đầu mỗi lượt, toàn bộ Axie còn sống của cả 2 phe roll đồng thời 1 mặt ngẫu nhiên
  trong 6 mặt (`ri(6)`, RNG xorshift-based seeded, `mkRng(seed)` — **hoàn toàn deterministic
  theo seed**, không phải Math.random thật).
- **Mặt địch roll ra = intent công khai** ngay lập tức (hiển thị mặt + mục tiêu dự kiến
  `pickEnemyIntent`), người chơi luôn biết trước 100% địch sắp làm gì — pillar "minh bạch
  triệt để" của game.
- **Reroll**: giới hạn theo "charge" (`rerolls`), mặc định `maxRerolls = 2 + bonusReroll(meta)
  + Σ(relic rerollUp)`. Base thực tế trong code là **2**. Người chơi chọn từng die muốn
  reroll (không phải cả bộ); không chọn = giữ mặt cũ. Reroll **xoá sạch undo stack**
  (`s.undo=[]`) trừ khi relic mang cờ `safeReroll`. Không reroll được die đã dùng (`used`),
  có keyword `heavy`, hoặc đang `frozen`.
- **Crit quyết định ngay lúc roll** (không phải lúc đánh) — hiển thị trên mặt die luôn để
  giữ tính minh bạch.
- **Cantrip**: mặt có keyword `cantrip` tự động kích hoạt ngay khi roll ra, rồi unit đó roll
  lại mặt mới ngay — lặp tối đa 6 lần/unit/lượt để tránh vòng lặp vô hạn (`resolveCantrips`).
- **Thực thi (EXECUTE)**: click-click (click mặt đã roll → click mục tiêu hợp lệ) là input
  chính, **kéo-thả** là con đường input thứ hai thật sự tồn tại (pointer events gọi thẳng vào
  cùng hàm `clickDie()/doTarget()`, không phải HTML5 drag API). Bàn phím cũng chơi được
  (Tab + Enter/Space).
- **Undo tự do** trong lượt cho tới khi: (a) bấm Reroll (trừ relic `safeReroll`), hoặc
  (b) bắt đầu lượt mới.
- Mỗi mặt quyết định: **loại hành động** (`type`: dmg/shield/heal/mana/poison/buff/
  debuff/summon/blank), **giá trị** (`value`), **bộ phận cơ thể phát sinh mặt** (`part`:
  mouth/horn/back/tail/eyes/ears — thẩm mỹ + một số relic buff theo part), và **danh sách
  keyword** (cleave/pierce/aoe/cantrip/heavy/growth/decay/vital/lifesteal/exec/multi:N/
  chain:N/selfharm:N/rerollup/mana:N, cùng keyword gắn status:
  burn:N/crit:N/freeze/stun/blind:N/weaken:N/vulnerable:N/thorns:N/regen:N/poison:N).
- **Formation Resonance**: 2 Axie liền kề trong đội hình (theo vị trí trong `s.roster`,
  không phải vị trí trên bàn cờ combat) cùng roll mặt **cùng type** (chỉ áp dụng cho
  `dmg/shield/heal/poison/mana`) trong cùng lượt → Axie thực thi **sau** trong cặp đó nhận
  **×1.15** giá trị mặt (số thật đang chạy trong code — xem Discrepancy #1).

---

## 3. Stat của Axie & công thức combat

**Stat cơ bản mỗi unit**: `hp`, `maxHp`, `shield` (giáp tạm, hấp thụ damage trước HP), `st{}`
(bảng status: poison/burn/regen/blind/weaken/vulnerable/thorns/stun/undying...).

**Turn 4 bước**:
1. **ROLL** — cả 2 phe roll đồng thời; cantrip tự kích hoạt.
2. **REROLL** — người chơi chọn reroll từng die (giới hạn charge).
3. **EXECUTE** — click mặt → click mục tiêu (hoặc drag-drop); dùng active relic (tốn Mana); undo tự do.
4. **END TURN** — địch thực hiện intent theo thứ tự vị trí trong mảng → tick status
   (poison/burn/regen giảm dần) → kiểm tra thắng/thua → lượt mới.

**Damage pipeline `dealDamage()`** (thứ tự thực thi đúng như code — quan trọng để port chính xác):

```
v = faceValue (giá trị mặt sau khi cộng growth, ×2 nếu vital+full HP, trừ weaken,
    ×1.5 overdrive boss, v=0 nếu blind, +hiveMind, ×1.15 nếu resonant...)

NẾU nguồn (src) là phe người chơi:
  1. EXECUTE: nếu target <50% maxHP VÀ (src là class Beast HOẶC face có keyword exec)
     → v = ceil(v×1.6)
  2. PIERCE: nếu pierce, v += (3 nếu src là Bird) + Σ(relic piercePlus)
  3. dmgMult: v = ceil(v × Π(relic dmgMult))
  4. modDmg hook của từng relic (có thể override v tuỳ ý)
  5. CRIT: nếu crit, v *= max(relic critMult, 2 mặc định); rồi += Σ(relic critFlat)
     [+critFlatPity nếu pityCrit]; relic critPierce → bật pierce
PHÍA MỤC TIÊU (bất kể nguồn):
  6. nếu target có vulnerable>0: v = ceil(v×1.5)
  7. nếu target là phe người chơi: v = max(1, ceil(v×(1−Σ relic dr)))  (damage reduction)
  8. nếu KHÔNG pierce: shield hấp thụ trước (min(shield, v)), phần dư mới trừ HP
  9. trừ HP; nếu HP<=0 và có status undying → hồi về 1 HP, tiêu undying
  10. onDmgTaken hook (relic) nếu target là người chơi
  11. THORNS: nếu src có o.attack=true và target có thorns>0 và không bị pierce+piercePlus
      relic bỏ qua → phản sát thương = thorns (×relic thornsMult, +relic thornsPlus nếu
      target là người chơi) vào src; nếu target là Reptile người chơi → gắn thêm poison:1
      lên src
  12. onHit hook relic (nếu src là người chơi và dealt>0)
  13. kiểm tra chết (onEnemyDeath / checkBossPhase)
```

- **Shield**: cộng dồn, trần mặc định `maxHp×2` (trừ relic `noShieldCap`). Class Plant: mọi
  shield tự +2 (hard-coded), và nếu shield ≥10 tự nhận Thorns 2.
- **Heal**: hồi HP tới trần maxHp; nếu relic `healShield` → heal cũng tạo shield bằng đúng
  lượng hồi.
- **Status effect** (xử lý ở `tickStatus()`, cuối mỗi lượt):
  - `poison`: gây damage = số stack (pierce, bỏ qua shield), giảm 1 stack/lượt trừ khi có
    `plague` (không bao giờ giảm). Địch có thể bị tick nhiều lần/lượt nếu relic
    `poisonTicks`>1. Lưu ý: `plague` chỉ áp dụng 1 CHIỀU — chỉ giữ poison không giảm khi unit
    bị poison là ĐỊCH (`u.side==='e'`, `tickStatus()`); nếu người chơi bị poison (VD từ quái
    role `poisoner`), stack vẫn giảm bình thường dù đội đang mang relic này. KHÔNG phải luật
    đối xứng 2 chiều.
  - `burn`: gây damage = stack (×relic burnMult nếu là địch), sau đó **giảm một nửa**
    (`floor(stack/2)`) trừ khi relic `burnSlow` (chỉ giảm 1). Có thể tick thêm (relic
    `burnTicks`) với hệ số giảm `burnTickRatio` (mặc định 0.7).
  - `regen`: hồi = stack, giảm 1 stack/lượt.
  - `blind/weaken/vulnerable`: giảm 1 stack/lượt; blind = mặt dmg ra 0; weaken = trừ thẳng
    giá trị mặt dmg; vulnerable = +50% damage nhận vào.
  - `thorns`: KHÔNG tự giảm theo lượt, có trần cứng `THORNS_CAP=8`.
  - `stun`: bỏ qua lượt hành động tiếp theo của địch, rồi tự xoá.
  - `freeze`: người chơi → không reroll được lượt tới (`frozenNext`→`frozen`) nhưng vẫn dùng
    được mặt; địch → tương đương stun.
  - `undying`: sống sót 1 lần ở 1 HP khi lẽ ra chết.
  - `enrage`: buff 1 lần (không phải status theo lượt) — mọi mặt dmg +25% vĩnh viễn trong trận.

**Passive theo class** (luôn có, không cần relic — xem bảng §11).

---

## 4. Đội hình / Party

- **5 Axie cố định** mỗi run, chọn từ 18 hero (6 class × 3 tier, chỉ chọn hero T1 khi bắt
  đầu — lên tier qua reward trong-run) hoặc từ Vault (Axie NFT import, luôn ở "tier 1 hình
  thức", xem §6).
- **UID system**: mỗi unit (party, enemy, token/egg) có `uid` duy nhất từ 1 bộ đếm toàn cục
  `UID` (tăng dần, reset về 1 mỗi `newGame`). `byUid(s,uid)` tìm trong `s.party` trước rồi
  `s.enemies`. **Bug đã biết**: khi CONTINUE RUN (load save), `UID` counter không tự đồng bộ
  với uid đã tồn tại trong save → unit mới tạo có thể trùng uid với unit cũ → hành động
  target nhầm unit. Có hàm sửa `resyncUid(s)` phải gọi ngay sau khi restore save. (Port sang
  Godot: dùng cơ chế id native của engine mới, tránh lặp lại bug này bằng thiết kế, không
  chỉ bằng patch.)
- **Ally targeting**: mặt loại `shield/heal/buff` chỉ target được unit cùng phe
  (`tgt.side===u.side`), mặt `dmg/poison/debuff` chỉ target khác phe. AoE bỏ qua việc chọn
  target, áp lên toàn bộ phe liên quan.
- **AI target địch** (`pickEnemyIntent`): mặc định random trong unit người chơi còn sống;
  role `assassin` → nhắm unit yếu nhất theo `hp+shield`; role `bruiser` → 50% nhắm unit khoẻ
  nhất; role `healer` → tự hồi máu cho địch yếu nhất phe mình.
- **Token/ally (Axie Egg)**: sinh ra từ mặt `summon` hoặc relic `startSummon`, side='p',
  KHÔNG tính vào `realP()` (5 Axie thật) cho mục đích thua/thắng — thua run chỉ tính khi 5
  Axie thật đều chết, dù còn bao nhiêu token sống. Trần đồng thời 4 token sống (`tokenCap`,
  có thể tăng qua relic).
- Vị trí trong `s.roster` (thứ tự đội hình do người chơi sắp) quyết định Formation Resonance
  (liền kề) và thứ tự ưu tiên khi nhiều relic chọn "unit nguy hiểm nhất".

---

## 5. Hệ thống Relic

- Relic hoạt động qua **hệ hook thuần** gắn vào object data (không phải scripting runtime):
  `modFace(u)` (sửa die lúc build unit), `modFace2` (pha thứ 2), `modDmg({s,src,tgt,v})→v`,
  `onRollEnd(s)`, `onTurnStart(s)`, `onHit(s,{type,dealt,tgt,crit,src,addStatus})`,
  `onKill(s,{tgt,explode})`, `onShield(s,{v,tgt,splash})`, `onThorns(s,{src,tgt,th})`,
  `onDmgTaken(s,{src,tgt,dealt,attack})`, `growthAllGuard(s)→bool`. Một số có
  `act:{cost,kind,...}` = active card tốn Mana ("Thẻ Lunacia").
- **94 relic** hiện có (78 passive + 16 active; 44 relic gốc + 50 mở rộng). 5 bậc hiếm
  (Common..Mythic).
- **Thứ tự chạy `modFace`** (INV-5, quan trọng để port đúng — không phải thứ tự nhặt relic!):
  sắp theo `[PHASE_RANK(mfPhase: kw=0 < add=1 < mul=2), rarity, RELIC_INDEX cố định theo dữ
  liệu]`. Mọi relic thêm keyword chạy trước, rồi cộng phẳng, rồi nhân — luôn theo thứ tự này
  bất kể thứ tự nhặt relic (tất định, không phá replay).
- **Chống chồng chất**: `RELIC_MLOAD_CAP=2` (trần tổng "mload" của relic đang giữ),
  `RELIC_CAP=10` (trần số relic/run). `relicConflict()` loại trừ relic bị đề nghị nếu đã có
  keyword trùng chức năng trên die của đội.
- **Archetype**: mỗi relic gắn 1 trong 11 archetype (`a` field) dùng cho tracker UI và
  `archScore()` (đọc realtime độ "cam kết" của đội theo build hiện tại).
- Relic có thể: sửa mặt xúc xắc vĩnh viễn, sửa công thức damage, phản ứng theo sự kiện
  (giết địch, bị đánh, tạo shield...), hoặc cung cấp active card tốn Mana có hiệu ứng tức
  thời.

---

## 6. Hệ thống Vault (Import Axie / NFT)

- **Vault ≠ "camp nghỉ ngơi"**. Đây là tính năng **Import Axie NFT thật**: người chơi nhập
  Axie ID → server proxy (`api/axie.js`) lấy data 6 body part thật → `axieToDie()` chuyển 6
  part thành 6 mặt xúc xắc (bảng `PART_FACES`/`part_faces.js`, sinh tự động từ
  `tools/gen_faces.mjs`, 285 "identity" part → 285 mặt distinct) → lưu vào `META.vault`
  (localStorage, tối đa 20 Axie, **persistent qua mọi run**).
- Việc chuyển đổi là **thuần (pure)**: không Math.random, không Date, không I/O — bắt buộc để
  server replay-verify (chống gian lận Leaderboard).
- Mỗi Axie thật có `coherence`/`purity` (% part khớp class cơ thể) ảnh hưởng hệ số nhân giá
  trị mặt và HP (`coherenceMod`, thang 0.64–0.78×). Part hiếm hơn (`scarcityBucket` C/O/P/X
  và `specialGenes` 0-3) cho giá trị mặt/rarity cao hơn, có trần (`B_CAP0`, `B_CAP_RUN`).
- **Axie Vault-import KHÔNG lên tier được** — đứng yên "hình thức tier 1" suốt run (gap đã
  ghi nhận, đang vá bằng reward `'ascend'` cho đội trộn hero+vault).
- **Axie Vault-import KHÔNG được dùng cho Ranked Run** (`teamKeys` dạng `vault_*` bị chặn cả
  client lẫn server `api/submit-run.js`, HTTP 400): vì die của Axie import chỉ tồn tại trong
  localStorage client, server không thể replay-verify độc lập.
- **NFT HP Bonus**: chỉ áp dụng cho Axie NFT **chọn trước vào đội hình**, công thức
  `pct = min(20%, 3% × ownershipMult × rarityMult)`, `ownershipMult` = 1.0/1.25/1.5 theo mốc
  sở hữu ≥5/≥20, `rarityMult` = [1.0, 1.15, 1.3, 1.5] theo 0-3 gene thật.

---

## 7. Part-skill system

- **Hero thường** (không import): mỗi hero (18 unit) có die cố định thiết kế tay trong
  `HEROES{}` — 6 mặt gán cứng theo (part, type, value, keyword), tăng dần qua tier (level-up
  ghi đè toàn bộ die + maxHp). KHÔNG dùng hệ "part-skill-identity" (đó chỉ áp dụng cho Import
  Axie).
- **Axie import**: hệ "Part-Skill Identity" (`design/gdd/part-skill-identity.md`) — mỗi
  part-identity map tất định tới 1 mặt xúc xắc cụ thể (signature face độc bản, hoặc variant
  theo family part/class/slot, hoặc fallback Common an toàn — không bao giờ crash).
- Slot cố định 6 loại: `mouth`(dmg), `horn`(dmg, hay pierce/heavy), `back`(shield),
  `tail`(dmg/poison, hay multi-target), `eyes`(heal/debuff/utility), `ears`(mana, luôn
  cantrip). Thứ tự sort tất định theo `SLOT_ORDER` rồi theo tên part.
- Giá trị mặt của part import tính theo "budget" (bucket khan hiếm × gene tier ×
  coherence), map qua model affine `(m,c)` do generator cung cấp — không hard-code bảng giá
  trong engine.

---

## 8. Điều kiện thắng/thua

- **1 trận**: thắng khi `aliveE(s).length===0` → `finishCombat()`. Thua khi `realP(s)` (5
  Axie thật) không còn ai sống → `s.phase='lost'` **ngay lập tức, kết thúc cả run**.
- **Cả run**: thắng khi đánh bại boss ở step cuối cùng → `s.phase='won'`. Thua bất kỳ trận
  nào → thua run (không "mạng"/"checkpoint").

---

## 9. Progression giữa các trận

- **Sau mỗi combat thắng**: `s.shards += 90 (boss) / 45 (elite) / 25 (thường)`; `rewardTier` =
  3 (boss) / 2 (elite) / (1 nếu step%3===0, else 0) (thường) → sinh N reward (`genRewards`, N
  tuỳ ascension, mặc định 3) để chọn 1; **1 lần reroll** cả bộ 3 lựa chọn (`rerollReward`,
  mặc định 1/wave). `rrwMax` (trần reroll/wave) được set MỘT LẦN lúc bắt đầu run
  (`S.rerollReward=1+(P.rrw||0); S.rrwMax=S.rerollReward`) từ Battle Pass perk `rrw` (mở ở
  level 28 Lunacia Pass, xem `BP` trong `data.js` ~1029) — đây là meta-progression
  persistent, KHÔNG có relic trong-run nào chỉnh `rrwMax`.
- **Loại reward** (token-pool có trọng số): `level` (lên tier, chỉ hero có `TIER_UP`) /
  `ascend` (die +25% mọi mặt, +6 maxHP, cho unit không lên tier được) / `relic` / `face`
  (Gene Mutation) / `rune` (gắn thêm keyword vào 1 mặt có sẵn) / `reroll` (+1 max reroll vĩnh
  viễn, chỉ khi maxRerolls<4) / `hp` (bonus maxHP) / `chaos` (relic mạnh nhưng party -20%
  maxHP) / `curse` (buff địch đổi lại +dmg cho cả đội, +1 reroll).
- **Gene Shard**: currency dùng ở Shop trong-run, nhưng phần CHƯA TIÊU khi run kết thúc
  (thắng/thua/bỏ cuộc đều như nhau) được cộng THẲNG, VÔ ĐIỀU KIỆN vào `META.shards` (pool
  vĩnh viễn dùng cho Unlock/Echo Box...) qua `onRunEnd()` (`META.shards+=S.shards`,
  `client.html` ~5437). Chỉ phần đã TIÊU ở Shop trong-run mới thực sự mất — Gene Shard
  trong-run và Gene Shard meta là CÙNG MỘT pool, không phải 2 currency tách biệt. Hệ quả
  balance: không tiêu Shard trong-run (bỏ qua Shop) là một lựa chọn meta hợp lệ, không bị
  phạt mất trắng khi hết run.
- **Event node**: 6 loại (`shrine/merchant/treasure/campfire/casino/mutant`), mỗi loại 2-3
  lựa chọn text với hiệu ứng riêng. `merchant` mở màn Shop. (Lưu ý: `campfire` là TÊN loại
  event hiện có trong code, nhưng hiệu ứng của nó KHÔNG phải hồi máu dần — đọc kỹ nội dung sự
  kiện thật khi port, đừng suy diễn từ tên.)
- **Meta-progression (ngoài run, persistent)**: Gene Shard (currency toàn cục, tích luỹ qua
  daily mission +60/ngày và XP), Lunacia Pass (Battle Pass 30 level), Echo Box (gacha
  cosmetics, giá tăng dần `base×growth^n`), World Tour (2 bản đồ tuyến tính 10 ô, mốc mở dựa
  trên số run đã hoàn thành), Unlock permanent (`UNLOCKS[]`).
- **Không có "camp/nghỉ" hồi máu dần giữa các trận** (xem quyết định §1 — giữ nguyên, không
  thêm).

**Công thức XP Lunacia Pass**:
```
XP = 30 (tham gia) + 10×(số wave vượt qua) + 30×(số elite đã qua) + 60×(số boss đã qua)
     + 150×(nếu thắng cả run) + 25×Ascension + 40×(nếu Full Run)
XP_cần_level(lv) = 45 + 22×(lv−1)
```

**Công thức Encounter Budget** (độ khó mỗi trận, tăng theo "power level" `pw` = số reward đã
nhận, KHÔNG theo số wave — để tự thích ứng Short/Full và khi chọn event thay vì đánh):
```
budget(pw) = 10.5 × 1.150^min(pw,12) × 1.05^max(0,pw−12)
count(pw)  = max(2, min(pw≥14?6:5, 2+floor(pw/4)))     // số lượng địch
elite: budget × 1.25
```
> **Lưu ý cho RunMap graph mới**: công thức này neo theo `pw` (power level tích luỹ), không
> theo vị trí tuyến tính — nghĩa là về nguyên tắc nó tương thích với 1 graph phân nhánh (độ
> khó vẫn tính đúng dù người chơi đi đường nào), nhưng cần verify lại khi số node/hàng thay
> đổi so với step-count cũ.

**Ascension** (10 mức, cộng dồn không tuyến tính — bảng đầy đủ `ASCENSION[]`/`ascMods()`):
+10% HP địch (a≥1) → +1 elite/wave (a≥2) → +10% dmg địch (a≥3) → +15% HP boss (a≥4) →
weaken ngẫu nhiên đầu trận (a≥5) → +10% HP địch nữa (a≥6) → reward chỉ còn 2 lựa chọn (a≥7)
→ +15% dmg địch (a≥8) → +2 elite wave nữa (a≥9) → +20%/+20% HP/dmg địch (a≥10).

---

## 10. Event stream `s.ev` (10 loại — bắt buộc port đủ để giữ "juice" khi sang Godot Tween)

| type | Payload | Khi nào phát |
|---|---|---|
| `hp` | `{uid,hp,maxHp,shield}` | Mỗi lần HP/shield của 1 unit thay đổi |
| `hit` | `{src,uid,v,crit}` | Mỗi lần có đòn đánh trúng (trước khi trừ shield/HP) |
| `death` | `{uid}` | Unit chết (hp<=0) |
| `use` | `{uid,side,tgt,aoe,facePart,faceName,faceT}` | Unit thực thi 1 mặt |
| `resonance` | `{uid}` | Unit vừa hưởng Formation Resonance ×1.15 |
| `relic` | `{id,uid}` | Relic vừa có hiệu ứng không hiện qua số liệu bình thường — **kênh
  duy nhất** để các hiệu ứng "âm thầm về số" được animate |
| `ft` (float text) | `{uid,txt,cls,big}` | Text nổi lên trên unit (damage/CRIT/PSN/UNDYING/GROW...) |
| `phase` | `{uid}` | Boss chuyển phase |
| `eact` | `{uid}` | Địch bắt đầu thực thi intent ở END TURN |
| `tick` | `{}` | Mốc chuyển sang xử lý status-effect cuối lượt |

> **Nguyên tắc thiết kế bắt buộc từ code**: relic không phát event là ĐÚNG SỐ nhưng VÔ HÌNH.
> Khi port sang Godot, mọi effect/Tween cần bám theo đúng 10 type này, không suy diễn thêm.

---

## 11. Cơ chế đặc biệt khác

**6 Class × Passive** (luôn có, không cần relic):

| Class | Passive | Hiệu ứng |
|---|---|---|
| Plant | BULWARK | Mọi Shield tạo ra +2. Axie ≥10 Shield → Thorns 2. |
| Beast | FERAL | Đòn vào target <50% HP: +60% damage (độc lập keyword `exec`). |
| Aqua | CONDUIT | Mọi Mana nhận +1. Mỗi 4 Mana tiêu → +1 Reroll. |
| Reptile | SCALES | Luôn có Thorns 2 (đặt lại đầu mỗi trận). Thorns của Reptile gây thêm Poison 1. |
| Bug | VIRULENT | Gắn Poison lên target đã có Poison → +2 stack thay vì +1. |
| Bird | TALON | Đòn Pierce +3 damage. Mặt `aoe` tự động nhận `pierce`. |

- **10 Archetype tracker** (UI thời gian thực): PLAGUE(poison)/INFERNO(burn)/BULWARK(shield)/
  CONDUIT(mana)/TALON(pierce)/APEX(crit)/EVOLVE(growth)/SWARM(summon)/TEMPEST(aoe)/
  AEGIS(thorns) + FERAL/exec (thứ 11).
- **9 vai trò địch**: bruiser/assassin/tank/healer/poisoner/mage/summoner/kamikaze/buffer —
  chi phối AI chọn mục tiêu (không phải chỉ số riêng biệt).
- **6 Boss** ("constrain chứ không destroy"): `gooey_king` (SPLIT — sinh quái ở 2/3 và 1/3
  HP), `mecha` (THORNS + mỗi lượt thứ 3 OVERDRIVE +50% dmg), `frost_lord` (mỗi lượt đóng băng
  1 die người chơi), `plague_mother` (mỗi 3 lượt triệu hồi quái + stack poison mạnh),
  `mirror` (copy mặt damage mạnh nhất người chơi vừa dùng), `agony` (2 PHASE — chết lần 1 hồi
  đầy máu, đổi bộ die thứ 2 mạnh hơn; luôn là boss cuối).
- **Gene Mutation / Rarity 5 bậc trên MẶT** (không phải cả viên xúc xắc): COMMON (0 kw) →
  RARE (1 kw) → EPIC (2 kw) → LEGENDARY (2 kw + value lớn) → MYTHIC (phá 1 luật cân bằng
  thường, VD `plague` không giảm stack, `echo` kích hoạt 2 lần, `bastion` shield cũng gây
  damage, `overflow` mana dư cuối lượt nổ AoE). Rarity là input người chơi lắp vào build
  trong-run — mọi part khi vào run mới đều bắt đầu Common (trừ mặt Vault import, đã tính
  coherence riêng).
- **Visual tier của cả viên die**: ≥2 mặt Legendary → "Golden Die"; ≥1 mặt Mythic → "Cosmic
  Die" (viền phát sáng).
- **Battle Pass exclusive faces** (`BP_FACES`): 4 mặt Mythic độc quyền, mở khi lên level Pass
  tương ứng, thêm thẳng vào `FACE_POOL` chung.

---

## Quyết định thiết kế đã chốt cho bản port Godot

| # | Chủ đề | Quyết định | Ghi chú |
|---|---|---|---|
| 1 | RunMap | Xây **graph phân nhánh thật** (Shroom and Gloom/Slay the Spire style) | Thiết kế mới hoàn toàn, không port 1:1 từ hệ step tuyến tính. Cần thiết kế riêng: số node/hàng, thuật toán sinh graph, cách giữ đúng encounter budget theo `pw` (§9) khi không còn 1 tuyến cố định. |
| 2 | Camp/nghỉ giữa trận | **Không thêm** | Giữ nguyên full-heal tự động trước mỗi trận, đúng như bản JS hiện tại. |
| 3 | Kiến trúc combat | **Thiết kế lại** trong lúc port (không dịch nguyên cấu trúc code JS) | Rule spec này là input cho bước đó — công thức/số liệu (§2-§11) phải giữ đúng, nhưng cách tổ chức thành scene/node/class trong Godot được thiết kế mới theo idiom của engine. |
| 4 | Anti-cheat leaderboard | Server (`api/_engine.js`) replay-verify bằng cách nạp `engine.js`/`data.js` JS gốc | Khi kiến trúc combat đổi, verify server-side sẽ không còn khớp bản Godot cho tới khi cũng được cập nhật — cần lên kế hoạch riêng cho việc này trước khi bản Godot thay thế bản JS trong `src/` (xem CLAUDE.md branch `godot-port`, chưa merge vào `main`). |

---

## Ghi chú discrepancy code vs. tài liệu (đã xác nhận — luôn ưu tiên code)

1. **Formation Resonance**: `RESONANCE.mult = 1.15` trong `data.js` (có comment tường minh
   cảnh báo "đừng sửa thành 1.25"), nhưng `design/quick-specs/formation-resonance-2026-09-01.md`
   và `game-concept.md` dòng 40 vẫn ghi +25%. → **1.15 là số thật đang chạy.**
2. **Base reroll**: code = 2, tài liệu cũ `AUDIT_AND_SPEC_v1.md` từng đề xuất 1 — đã lỗi
   thời, `game-concept.md` bản mới đã tự sửa.
3. `world-tour.md` tự ghi "Draft — chờ product owner xác nhận 3 câu hỏi mở",
   `relic-system.md` tự ghi "Draft for review (chưa duyệt)" — mô tả ý định thiết kế, không
   hoàn toàn = trạng thái implement 100% (dù phần lớn đã khớp code qua đối chiếu).
