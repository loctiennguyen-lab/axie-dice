# AXIE DICE TACTICS — BUILD SPEC v1.0
## Implementation contract cho Economy & Progression (Phase 1)

> **Đọc doc này trước khi viết code.** Đây là hợp đồng triển khai, không phải doc thiết kế.
> Lý do đằng sau từng quyết định nằm ở `ECONOMY_AND_PROGRESSION_v2.md` — chỉ đọc khi cần hiểu *tại sao*.
>
> **Tất cả 16 quyết định thiết kế (D1-D16) đã được duyệt.** Không tự ý đổi.

### Tệp đi kèm

| Tệp | Dùng làm gì |
|---|---|
| `economy_config.json` | **Mọi hằng số cân bằng.** Không hardcode số trong `engine.js` / `ui.js` |
| `parts_build_data.json` | 192 part core + card text Origins + khung 4 bậc để designer điền |
| `bloodlines.json` | Pool part theo class × slot |
| `ECONOMY_AND_PROGRESSION_v2.md` | Doc thiết kế (lý do) |
| `BLOODLINE_SYSTEM_v1.md` | Hệ part → mặt xúc xắc, bản sắc 6 class |
| `AUDIT_AND_SPEC_v1.md` | Spec engine gốc — **đọc kèm Phụ lục D của doc Economy**, 17 mục đã bị thay thế |

---

## 1. BẤT BIẾN — vi phạm là bug, không phải lựa chọn

Bảy luật này phải đúng ở mọi thời điểm. Viết assert cho từng cái.

```
INV-1  Bộ sưu tập chỉ chứa DANH TÍNH part. Không có trường rarity/power nào
       trên bản ghi sưu tập.
INV-2  Mọi part vào run ở bậc COMMON. Không ngoại lệ, kể cả Lead Axie và NFT.
INV-3  Lên tier KHÔNG BAO GIỜ thay partId. Chỉ nâng bậc mặt hiện có.
INV-4  Gene Mutation là cơ chế duy nhất đổi partId trong run, và nó LUÔN
       hạ mặt về COMMON.
INV-5  Mọi part ở CÙNG MỘT BẬC phải nằm trong ±10% ngân sách sức mạnh của bậc đó.
INV-6  Không có đường nào từ TIỀN THẬT → SỨC MẠNH. Tiền chỉ mua tốc độ và cosmetic.
INV-7  Run thường không bao giờ bị gate bởi năng lượng, vé, hay cooldown.
```

**INV-5 phải là một test tự động chạy trong CI**, không phải review thủ công. Nó là điều kiện sống còn của cả kiến trúc: vi phạm nó là đưa gradient sức mạnh vào tầng sưu tầm và biến game thành pay-to-win.

---

## 2. MÔ HÌNH DỮ LIỆU

```ts
// ---------- TĨNH (data.js, không đổi lúc runtime) ----------

type Slot  = 'mouth'|'horn'|'back'|'tail'|'eyes'|'ears'
type Klass = 'beast'|'aquatic'|'plant'|'reptile'|'bug'|'bird'
type Tier  = 'common'|'rare'|'epic'|'legendary'|'mythic'
type Role  = 'dmg'|'shield'|'heal'|'mana'|'debuff'|'utility'

interface PartDef {                    // 192 bản ghi, từ parts_build_data.json
  partId: string                       // 'back-ronin' — KHOÁ THẬT, không dùng name
  name: string                         // 'Ronin' — có thể trùng giữa các slot
  class: Klass
  slot: Slot
  role: Role                           // gán từ cardText, KHÔNG suy từ slot (xem §3)
  archetype: string                    // 1 trong 10 archetype
  tiers: Record<Exclude<Tier,'mythic'>, FaceDef>
}

interface FaceDef {                    // định nghĩa một part TẠI một bậc
  value: number
  keywords: Keyword[]                  // vd [{k:'shieldregen', n:5}]
  powerBudget: number                  // dùng cho INV-5
}

interface MythicDef {                  // 36 bản ghi — PHASE 2
  class: Klass; slot: Slot
  name: string                         // 'Hasagi' — tên hiển thị của bậc Mythic
  ruleBreak: RuleBreakEffect
}

// ---------- SƯU TẦM (server-authoritative, vĩnh viễn) ----------

interface PlayerProfile {
  unlockedParts: Set<string>           // partId. INV-1: KHÔNG có tier ở đây
  savedAxies: SavedAxie[]
  mastery: Record<string, number>      // partId -> số lượt dùng tích luỹ
  pinnedPartId: string | null
  leadSlots: 1 | 2
  geneShard: number
  moonDust: number
  gauntletTickets: number
  cosmetics: Set<string>
  nftLinkedParts?: Set<string>         // Phase 2
}

interface SavedAxie {
  id: string
  name: string
  class: Klass
  parts: Record<Slot, string>          // ĐÚNG 6 slot, mỗi slot đúng 1 partId
}

// ---------- RUN (tạm thời, huỷ khi run kết thúc) ----------

interface FaceInstance {               // một mặt trên một viên xúc xắc TRONG run
  partId: string
  tier: Tier                           // ← SỨC MẠNH SỐNG Ở ĐÂY
  mutated: boolean
}

interface Hero {
  uid: string
  class: Klass
  heroTier: 1|2|3
  isLead: boolean
  die: FaceInstance[]                  // độ dài 6
  hp: number; maxHp: number; shield: number
  statuses: Status[]
}
```

**Ranh giới then chốt:** `PlayerProfile` không có trường `tier` ở bất kỳ đâu. `FaceInstance` không tồn tại ngoài `RunState`. Nếu thấy `tier` rò rỉ sang phía profile — đó là bug INV-1/INV-2.

---

## 3. CẠM BẪY DỮ LIỆU — đọc kỹ, đây là chỗ dễ sai nhất

**3.1 `role` KHÔNG suy được từ `slot`.** Spec gốc §B2 nói `back = shield`, `ears = mana`. **Sai với dữ liệu thật:**

| Part | Slot | Role thật |
|---|---|---|
| `Furball` | back | dmg (`multi:3`) |
| `Ronin` | back | dmg + crit |
| `Risky Beast` | back | dmg |
| `Teal Shell` | horn | shield |
| `Bumpy` | horn | shield |
| `Belieber` | ears | dmg (3 đòn) |

13/20 part mẫu không khớp vai trò mặc định của slot. **Luôn đọc `role` từ `parts_build_data.json`.** Slot chỉ quyết định tên và art.

**3.2 Khoá bằng `partId`, không bao giờ bằng `name`.** 7 tên trùng hợp lệ giữa các slot: `Anemone` (aqua horn+back) · `Nut Cracker` (beast mouth+tail+ears) · `Nimo` (aqua tail+ears) · `Leaf Bug` (bug horn+ears) · `Peace Maker` (bird mouth+ears) · `Little Owl` (bird mouth+eyes) · `Puppy` (beast eyes+ears).

**3.3 Sanitize khi dựng đường dẫn asset.** `partId` `eyes-kotaro?` chứa `?`. 9 tên part đặc biệt chứa `✨`. Cả hai vỡ khi làm tên file / URL / khoá CSV. Slugify trước khi dùng.

**3.4 Mouth và Eyes chỉ có 4 part/class**, các slot khác có 6. Đừng giả định 6 ở mọi nơi.

---

## 4. THUẬT TOÁN

### S1 — Sinh Axie trong run

```js
function generateAxie(profile, klass, rng) {
  const parts = {}
  for (const slot of SLOTS) {
    const pool = bloodlines[klass][slot]
                  .filter(p => profile.unlockedParts.has(p.partId))
    parts[slot] = rng.pick(pool)          // pool không bao giờ rỗng: 60 part khởi đầu
  }
  return { class: klass, heroTier: 1,
           die: SLOTS.map(s => ({ partId: parts[s], tier: 'common', mutated: false })) }
}
```
Bộ sưu tập rộng → **đa dạng hơn, không mạnh hơn**. Đây là INV-2 tại chỗ.

### S2 — Nâng bậc một mặt

```js
const NEXT = { common:'rare', rare:'epic', epic:'legendary', legendary:'mythic' }

function upgradeFace(face, cfg) {
  if (face.tier === 'legendary' && cfg.tiers.mythicEnabledInPhase > cfg._meta.phase)
    return face                          // Phase 1: legendary là trần
  if (face.tier === 'mythic') return face
  face.tier = NEXT[face.tier]            // partId GIỮ NGUYÊN — INV-3
  return face
}
```

### S3 — Lên tier hero

```js
function levelUpHero(hero, rng, cfg) {
  hero.heroTier = Math.min(3, hero.heroTier + 1)
  const n = rng.int(cfg.tiers.tierUpFacesPerHeroLevel.min,
                    cfg.tiers.tierUpFacesPerHeroLevel.max)
  rng.sample(hero.die, n).forEach(f => upgradeFace(f, cfg))
  // KHÔNG thay partId. KHÔNG ghi lại die. INV-3.
}
```

### S4 — Gene Mutation

```js
function geneMutate(face, newPartId) {
  face.partId = newPartId
  face.tier   = 'common'                 // INV-4 — luôn hạ về Common
  face.mutated = true
}
```
Không có luật này, người chơi đẩy một mặt bất kỳ lên Legendary rồi Mutate ngay trước boss.

### S5 — Lead Axie

```js
function buildParty(profile, leadAxieId, rng) {
  const lead = profile.savedAxies.find(a => a.id === leadAxieId)
  const hero = {
    class: lead.class, heroTier: 1, isLead: true,
    die: SLOTS.map(s => ({ partId: lead.parts[s], tier: 'common', mutated: false }))
  }                                      // bậc COMMON — INV-2
  return [hero]                          // 4 chỗ còn lại tuyển trong run
}
```
Lead mang **danh tính**, không mang chỉ số. `leadSlots` tối đa **2**, đọc từ config, **không bán bằng tiền**.

### S6 — Axie Forge (3 ràng buộc bắt buộc)

```js
function validateForge(profile, draft) {
  if (Object.keys(draft.parts).length !== 6) return 'THIẾU_SLOT'
  for (const slot of SLOTS) {
    const p = PARTS[draft.parts[slot]]
    if (!p || p.slot !== slot)                     return 'SAI_SLOT'
    if (!profile.unlockedParts.has(p.partId))      return 'CHƯA_MỞ_KHOÁ'
    if (p.class !== draft.class && !isSecretClassPair(draft.class, p.class))
                                                    return 'SAI_CLASS'
  }
  return 'OK'
}
```
**Bỏ bất kỳ ràng buộc nào là mở một lỗ khai thác đã biết:**
- Bỏ *1 part/slot* → forge Axie 6 mặt `Anemone`, mà `Anemone` là *"restore 50 HP for each Anemone part"* ⇒ resonance cực đại vĩnh viễn từ T1.
- Bỏ *đơn class* → splash off-class miễn phí vĩnh viễn, vô hiệu hoá Meta Morph.

### S7 — Mở khoá part

```js
function unlockPart(profile, partId, cfg) {
  const cost = cfg.collection.partUnlockCost.default   // PHẲNG cho mọi part — D10
  if (profile.geneShard < cost) return 'THIẾU_SHARD'
  profile.geneShard -= cost
  profile.unlockedParts.add(partId)
}
```
Không định giá theo rarity. Bộ sưu tập không chứa rarity (INV-1).

### S8 — Mastery

```js
function onRunEnd(profile, facesUsed, cfg) {
  for (const [partId, uses] of facesUsed) {
    const mult = (profile.pinnedPartId === partId) ? cfg.mastery.pinMultiplier : 1
    profile.mastery[partId] = (profile.mastery[partId] || 0) + uses * mult
  }
}
```
Mastery mở khoá **biến thể** (mặt khác cùng ngân sách sức mạnh) và **cosmetic**. **Không bao giờ cộng chỉ số, không bao giờ tăng tần suất xuất hiện.** Mốc M5 cũ đã bị cắt (D9).

### S9 — Offer phần thưởng

```js
function rollOffers(pool, rng, cfg) {
  const offers = []
  const byArch = {}
  while (offers.length < cfg.rewards.offersPerReward) {
    const c = rng.pick(pool)
    if ((byArch[c.archetype] || 0) >= cfg.rewards.maxOffersSameArchetype) continue
    byArch[c.archetype] = (byArch[c.archetype] || 0) + 1
    offers.push(c)
  }
  return offers
}
```
Trần 2/3 cùng archetype (D16) chặn kịch bản mở khoá lệch hẳn về một build rồi mọi offer đều rơi trúng nó.

### S10 — Meta Morph

Van xả off-class **duy nhất** sau khi bỏ Universal pool. Phải **luôn có mặt** trong reward pool (trọng số vừa) cộng một event node chuyên dụng — không phải reward hiếm. Mục tiêu ~20% mặt đến từ ngoài bloodline.

---

## 5. BẬC MYTHIC — Phase 2, viết stub ngay từ Phase 1

```
Mỗi cặp (class, slot) có ĐÚNG MỘT hiệu ứng Mythic phá luật, mang tên Mystic part
tương ứng. BẤT KỲ part nào của class đó ở slot đó, khi đạt LEGENDARY, đều có thể
lên MYTHIC và nhận hiệu ứng ấy.

Mặt GIỮ NGUYÊN partId và tên gốc, hiển thị thêm huy hiệu:  RONIN ⟨HASAGI⟩
```

Ma trận Mystic là 6 class × 6 slot — khớp chính xác, **không cần bảng ánh xạ**. Dữ liệu ở `parts_build_data.json → mythicBySlot`.

**Không** implement Mythic như một `partId` riêng. Nếu làm vậy, lên Mythic thành một cú đổi danh tính — phá INV-3 ở đúng khoảnh khắc đắt giá nhất của run.

Nguồn nâng lên Mythic: chỉ node **Bể Đột Biến**, boss reward, relic chuyên dụng.

**Art Mystic nguyên bản** chỉ dành cho chủ sở hữu Axie Mystic on-chain, áp ở **mọi bậc**. Người chơi thường lên Mythic thấy biến thể *awakened* chung. **Không bán skin Mystic** (rủi ro IP bên thứ ba: `Hasagi` = Yasuo/Riot, `Namek Carrot` = Dragon Ball).

---

## 6. THỨ TỰ TRIỂN KHAI

| # | Mốc | Nội dung | Xong khi |
|---|---|---|---|
| **M0** | Dữ liệu | Nạp 192 part vào `data.js`; điền 4 bậc; gán `role` + `archetype` | CI kiểm INV-5 xanh |
| **M1** | Bậc trong run | `FaceInstance.tier`, `upgradeFace`, `levelUpHero` mới (bỏ logic ghi lại die), Gene Mutation hạ Common | Chạy được một run đủ 12 wave, danh tính hero không đổi |
| **M2** | Sưu tầm | `PlayerProfile`, unlock part, 60 part khởi đầu, Gene Shard faucet/sink, server save | Mở được part, tồn tại qua session |
| **M3** | Forge + Lead | Forge có validate, lưu Axie, chọn Lead trước run | Lead vào run ở Common, giữ đúng 6 part |
| **M4** | Mastery | Tích luỹ, mốc M1-M3, Pin, Collection Log | Đủ mốc mở được biến thể |
| **M5** | Sim | Chạy lại toàn bộ đường cong; trả 4 món nợ S1-S4 | Mọi chỉ số §7 nằm trong dải |
| **M6** | Monetization | Season 0 BP, cửa hàng cosmetic ~15 SKU, Moon Dust | Mua được, entitlement đúng |
| **M7** | Gauntlet | Pool build, Daily Seed, replay-verify server | Vé mua **seed mới**, không mua lượt thử lại |

**M5 chặn ship.** Không phát hành trước khi sim chạy — hiện có bốn câu hỏi cân bằng chưa ai trả lời được (§7).

---

## 7. ACCEPTANCE TEST

### 7.1 Bất biến — chạy trong CI

```js
test('INV-1  profile không chứa tier',        () => expectNoTierField(profile))
test('INV-2  mọi mặt vào run ở common',       () => run.heroes.every(h => h.die.every(f => f.tier==='common')))
test('INV-3  lên tier giữ nguyên partId',     () => { const b=ids(hero); levelUpHero(hero); expect(ids(hero)).toEqual(b) })
test('INV-4  mutation hạ về common',          () => { geneMutate(f,'back-ronin'); expect(f.tier).toBe('common') })
test('INV-5  ngân sách sức mạnh ±10%/bậc',    () => forEachTier(t => expectWithin(budgets(t), 0.10)))
test('INV-6  không SKU nào cấp sức mạnh',     () => STORE.every(s => s.grants.every(g => g.layer!=='power')))
test('INV-7  run thường không bị gate',       () => expect(startRun({tickets:0, energy:0})).toBe('OK'))
test('FORGE  chặn 6 mặt trùng slot',          () => expect(validateForge(p, sixAnemone)).toBe('SAI_SLOT'))
test('OFFER  không quá 2/3 cùng archetype',   () => manyRolls().every(o => maxSameArchetype(o) <= 2))
```

### 7.2 Cân bằng — chạy bằng `sim.js`

| Chỉ số | Dải | Ghi chú |
|---|---|---|
| Δwinrate (bộ sưu tập đầy vs khởi đầu), cùng leadSlots | ≤ **+10% tương đối** | Kiểm INV-1/INV-2 có thật sự trung tính hoá bề rộng |
| Δwinrate mỗi slot Lead | ≤ **+25% tương đối** | 🔬 **S1 — chưa ai đo.** Vượt dải ⇒ hạ `leadSlots` về 1 vĩnh viễn |
| Δwinrate do nở lệch archetype (max/min pool = 5) | ≤ **+10% tương đối** | 🔬 **S2 — chưa ngã ngũ**, hai ước lượng trái ngược (−2% vs +35%) |
| Archetype diversity | ≥ **8/10** archetype có run thắng | Chống hội tụ build |
| Replay-rate | ≥ **55%** | **North Star.** Không đạt thì mọi thứ khác vô nghĩa |
| Thời gian mở hết 1 bloodline | **19-28 giờ** | Đo **từ 60 part khởi đầu**, không phải từ 0 |
| Thời gian tới part mới (người mới) | 2-3 run | |
| Conversion / ARPDAU | ≥ 3% / ≥ $0.02 | |

> ⚠️ **Mọi chỉ số winrate ghi theo % TƯƠNG ĐỐI.** Trên nền A0 = 14,4%, "+5 điểm phần trăm" là **+35% tương đối** — một ngưỡng lỏng đến mức vô nghĩa. Đừng dùng điểm phần trăm.

### 7.3 Bốn món nợ cân bằng chưa trả

| # | Câu hỏi | Chặn |
|---|---|---|
| S1 | Slot Lead đáng giá bao nhiêu winrate? | Trần `leadSlots` = 2 |
| S2 | Nở lệch archetype có thành sức mạnh không? | Độ hào phóng của Collector Bundle |
| S3 | Sink đầu cuối — sau 192 part + 768 mốc Mastery thì tiêu Shard vào đâu? | Ship Phase 1 |
| S4 | Hiệu chuẩn faucet/sink | Ship Phase 1 |

---

## 8. TUYỆT ĐỐI KHÔNG LÀM

```
✗ Định giá part theo rarity                    → phá INV-1
✗ Cho Lead Axie vào run ở bậc > common          → phá INV-2
✗ Thay partId khi lên tier                      → phá INV-3, xoá danh tính Lead
✗ Cho Gene Mutation giữ bậc                     → mọi mục tiêu dài hạn thành zero-cost
✗ Bậc COMMON không có keyword                   → 30 mặt đầu run vô danh tính,
                                                   6 bản sắc class biến mất nửa đầu run
✗ Gate run thường bằng năng lượng / vé          → giết vòng lặp "thua rồi chơi lại ngay"
✗ Bán slot Lead thứ hai bằng tiền               → pay-to-win trực tiếp
✗ Bán vé = lượt thử lại trên CÙNG seed          → bảng xếp hạng thành bảng xếp hạng ví tiền
✗ Bán skin Mystic ở cửa hàng                    → rủi ro IP bên thứ ba + phản bội chủ NFT
✗ Mastery cộng chỉ số hoặc tăng tần suất        → mốc M5 đã bị cắt có chủ đích
✗ Implement Mythic như partId riêng             → phá INV-3
✗ Suy `role` từ `slot`                          → sai với 13/20 part mẫu
✗ Dùng `name` làm khoá                          → 7 tên trùng hợp lệ
✗ Hardcode hằng số cân bằng trong engine/ui     → phải đọc economy_config.json
```

---

## 9. PHẠM VI

**Phase 1 (web, 3 tháng).** Bộ sưu tập part + Gene Shard · 4 bậc trong run · Axie Forge có ràng buộc · **1 slot Lead** · Mastery M1-M3 + Pin · Season 0 Battle Pass · cosmetic ~15 SKU · Gauntlet v1 + Daily Seed · account + server save + **replay-verify** · analytics + LiveOps config từ server.

**Không có ở Phase 1:** NFT · mobile · slot Lead thứ hai · Mastery M4 · tournament · **bậc MYTHIC** · secret class · CHAIN/COMBO.

**Phase 2 (tháng 4-9).** Mobile · bậc Mythic (36 hiệu ứng class×slot) · lớp NFT · slot Lead thứ hai qua meta-unlock sâu · Mastery M4 · secret class Dusk/Mech/Dawn (rút 3/6 slot từ mỗi bloodline bố mẹ) · season cadence 6 tuần · cosmetic NFT trên Ronin · Gauntlet Tournament nếu legal thông.

**Ngân sách:** S0 (launch) = **8-12 person-week** — tách khỏi ngân sách season thường 4-6 pw. Bậc Mythic thêm 3-4 pw ở Phase 2.

---

## 10. VIỆC CỦA DESIGNER, KHÔNG PHẢI CỦA CODE

Ba việc `parts_build_data.json` đang để `null` và code không thể tự điền:

1. **`role` và `archetype` cho 192 part** — đọc từ `cardText`, gán tay. 12 part không có card text công khai (Bird·Ears ×6, Bug·Ears ×6) cộng Plant·Lotus: **lấy từ team Origins nội bộ, đừng đoán.**
2. **Bảng 4 bậc cho 192 part** — theo mẫu: Common = hiệu ứng gốc + keyword đặc trưng ở giá trị tối thiểu · Rare = tăng giá trị · Epic = keyword đầy đủ theo card text · Legendary = giá trị lớn + 1 keyword phụ. Ước tính 3-4 person-week.
3. **36 hiệu ứng Mythic** (Phase 2) — Mystic part trong Axie là **skin thuần, không có card effect để chuyển thể**, nên cả 36 phải thiết kế từ đầu. Ước tính 3-4 person-week.

Ba việc cần bên ngoài: legal review tên Mystic/Japan · xác nhận với team art việc tách lớp part sprite · đối chiếu `parts.json` với bảng part chính thức của team Origins (`agp-npm` là package cộng đồng, không phải API chính thức).
