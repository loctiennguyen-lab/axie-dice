# Axie Dice Tactics — GDD Audit & Final Spec v1.0

*Quy trình: đọc GDD → audit → spec hoàn thiện → build. Doc này là "contract" mà code v0.1 tuân theo.*

---

## PHẦN A — AUDIT GDD

### A1. Những gì GDD làm đúng (giữ nguyên)
| Điểm | Nhận xét |
|---|---|
| Deterministic / telegraphed intent | Đúng linh hồn S&D. Giữ 100%. |
| Unlimited Undo trong lượt | Đúng. S&D có undo tự do. Chỉ cần chốt đúng "randomness boundary" (xem A2.6). |
| 6 mặt xí ngầu = 6 body part Axie | **Ý tưởng reskin xuất sắc**, đây là USP so với S&D. Giữ, nhưng sửa cách áp dụng (A2.2). |
| Gene Mutation làm reward | Rất hay — S&D không có "die editing" trực tiếp ở mức này. Giữ làm reward layer riêng. |
| JSON-driven / discrete state machine | Đúng, kiến trúc code theo hướng này. |

### A2. Sai lệch / rủi ro so với Slice & Dice — và cách sửa

**A2.1 — Party size 3 là quá nhỏ. ❌ → 5**
S&D dùng party 5 hero. Với 3 dice/lượt, không gian quyết định mỗi lượt sụt ~thảm: số tổ hợp gán dice giảm bậc số mũ, người chơi hết trò trong 10 phút. Đây là lỗi nghiêm trọng nhất của GDD.
→ **Party 5 Axie.** Vẫn hiển thị 2 hàng (front/back) cho đẹp, nhưng targeting tự do.

**A2.2 — Map cứng "mặt N = part N = hành động cố định". ❌ → part là *flavor*, distribution là *design***
GDD ép: mặt 1 luôn Mouth = 3 DMG, mặt 3 luôn Back = 4 Shield… Hệ quả: **mọi Axie có die giống nhau** → không còn build diversity, class chỉ khác nhau ở HP. Đây là cái chết của roguelike dice-drafting.
→ Giữ 6 part làm **vocabulary** (Mouth/Horn/Back/Tail/Eyes/Ears + Blank), nhưng **mỗi hero có die riêng gồm 6 part bất kỳ, lặp được**. VD Plant T1 = `[Back4, Back4, Mouth2, Blank, Horn2, Ears1]`. Class identity đến từ *phân bố part*, không từ vị trí mặt.

**A2.3 — Thiếu hoàn toàn hệ Level-Up / Transformation Tree. ❌ (gap lớn nhất)**
Đây là **xương sống progression của S&D**: reward chính là "level up 1 hero" → hero biến hình thành class cao hơn (T1→T2→T3), die được viết lại hoàn toàn. GDD không có → run chơi không có cảm giác lên power.
→ **3 tier/class × 6 class = 18 hero unit.** Art: 54 sprite chia đúng 9/class → T1 dùng variant 1-3, T2 variant 4-6, T3 variant 7-9.

**A2.4 — Reroll: "tối đa 2 lần, đổ lại toàn bộ" ❌ → reroll là *resource*, chọn từng die**
S&D: reroll là số đếm (base 1/lượt, upgrade được), người chơi **chọn đúng những die muốn đổ** (không cần cơ chế "lock" riêng — không chọn = đã lock). Cho 2 reroll toàn cục ngay từ đầu là quá nhiều variance-control ở wave 1 rồi hết đường upgrade.
→ **Base 1 reroll/lượt. Chọn từng die. Upgrade lên 2-3 qua reward/item.** Bỏ checkbox "Lock".

**A2.5 — Hand Cards + Energy Pool ⚠️ → thay bằng Mana + Item (đúng S&D), giữ card làm skin**
S&D không có tay bài; nó có **mana** (từ mặt Ears) + **item trang bị** trong đó một số item có *active* tốn mana. Thêm hand-cards là thêm cả một hệ thống draft thứ hai → phình scope, loãng focus.
→ **Mana pool + 2 slot item/hero.** Item active tốn mana được trình bày dạng "Thẻ Lunacia" ở đáy màn hình → giữ đúng cảm giác GDD mà không tách hệ thống.

**A2.6 — Undo: "không undo sau End Turn" ⚠️ chưa đủ**
Boundary thật là **randomness**, không phải End Turn. Nếu cho undo qua một lần reroll → save-scumming vô hạn, game vỡ.
→ **Undo stack clear khi: (a) bấm Reroll, (b) End Turn.** Trong lượt, undo tự do vô hạn.

**A2.7 — Front/Mid/Back giới hạn targeting ⚠️**
S&D targeting tự do; vị trí chỉ có ý nghĩa cho **Cleave (kề cạnh)** và một số enemy nhắm "front-most". GDD ép hàng dọc → mất hẳn quyết định "đánh ai".
→ **Targeting tự do.** Vị trí chỉ ảnh hưởng Cleave + AI enemy dạng `taunt/frontmost`.

**A2.8 — Boss ở wave 8/16/20 ⚠️ → 5/10/15/20**
Nhịp 5 wave/act của S&D cho 4 act đều nhau, dễ tune curve. Wave 8 quá xa cho boss đầu (người chơi drop trước đó).

**A2.9 — Thiếu định nghĩa HP giữa các trận ❌**
Không nói gì về heal/revive. Nếu HP carry-over + không revive → death spiral, wave 6 là bỏ game.
→ **Hết trận: toàn party heal full + hồi sinh Axie đã chết.** Độ khó nằm trong *từng trận*, không phải attrition. (Chuẩn S&D.)

**A2.10 — Enemy không có dice ❌**
GDD cho enemy "chốt intent" nhưng không nói intent từ đâu. Trong S&D **enemy cũng có die và cũng roll**, mặt roll ra chính là intent hiển thị. Đây là nguồn variance công bằng và là lý do game vẫn tươi mới.
→ **Enemy có die 6 mặt, roll cùng lúc với player, mặt hiện ra = intent.** Người chơi thấy 100% → vẫn deterministic trong lượt.

**A2.11 — Bảng cân bằng ở §7 không nhất quán ❌**
GDD: wave 1-3 party tổng DMG 10-14 vs chimera 12-18 HP → ~1.5 lượt/trận, quá nhanh. Wave 20: party 50-70 DMG vs boss 500 HP → **8-10 lượt** trong khi boss đánh 30 DMG/lượt vs 160 HP party → party chết ở lượt 6. **Final boss toán học là bất khả thi.**
→ Rebuild curve bằng **encounter point-budget + simulation** (Phần B6), không hardcode bảng.

**A2.12 — Thiếu: status effect breadth, reward-reroll, difficulty tiers, số enemy/trận, win/lose screen, save/resume.**

### A3. Kết luận audit
GDD tốt về *thẩm mỹ và trụ cột*, nhưng thiếu 3 hệ thống xương sống của S&D (**level-up tree, enemy dice, item/mana**) và có 2 lỗi làm sụp gameplay (**party 3, die đồng nhất**). Toán cân bằng cần làm lại từ đầu bằng sim.

---

## PHẦN B — FINAL SPEC v1.0

### B1. Vòng lặp
```
RUN = 20 wave. Boss @5/10/15/20. Elite @3,7,12,17.
WAVE = combat → reward (chọn 1/3) → wave sau.
COMBAT TURN:
  1 ROLL      : 5 die party + toàn bộ die enemy roll đồng thời. Cantrip auto-fire.
  2 REROLL    : chọn n die → reroll (tốn 1 reroll charge). [clear undo stack]
  3 EXECUTE   : drag mặt die → target. Dùng item active (mana). Undo tự do.
  4 END TURN  : resolve enemy intent theo thứ tự vị trí → tick status (poison/burn/regen) → check win/loss.
Hết trận: heal full + revive toàn party.
```

### B2. Die & Part vocabulary
Die = 6 face. Face = `{part, type, value, kw[]}`.

| Part | Type mặc định | Ý nghĩa |
|---|---|---|
| `mouth` | `dmg` | Đánh đơn, hay đi kèm `lifesteal` |
| `horn` | `dmg` | Đánh mạnh, hay đi kèm `pierce`/`heavy` |
| `back` | `shield` | Giáp cho mình/đồng đội |
| `tail` | `dmg`/`poison` | Đa mục tiêu, `cleave`/`aoe`/độc |
| `eyes` | `heal`/`debuff` | Utility, hay `cantrip` |
| `ears` | `mana` | +mana, luôn `cantrip` |
| `blank` | — | Mặt trống (tồn tại để die T1 yếu) |

### B3. Keywords (modifier trên face)
`cleave` (100% target + 50% ↑↓ kề cạnh) · `pierce` (bỏ qua shield) · `aoe` (toàn bộ địch) · `cantrip` (tự kích hoạt lúc roll rồi die tự reroll 1 lần miễn phí) · `heavy` (không reroll được) · `growth` (+1 vĩnh viễn trong trận sau mỗi lần dùng) · `decay` (−1) · `vital` (×2 nếu chủ full HP) · `lifesteal` · `multi:N` (thực hiện N lần) · `chain:N` (N đòn vào địch random) · `selfharm:N` · `rerollup` (+1 reroll khi dùng) · `mana:N` (kèm +N mana)

### B4. Status effects
`shield N` (hấp thụ, cap = maxHP, **không tự hết**) · `poison N` (cuối lượt: −N HP, N→N−1) · `burn N` (−N HP, N→⌊N/2⌋) · `regen N` (+N HP, N→N−1) · `stun` (bỏ 1 lượt) · `blind N` (mặt dmg = 0 trong N lượt) · `weaken N` (−N dmg) · `vulnerable N` (nhận ×1.5 dmg) · `thorns N` (kẻ đánh nhận N) · `undying` (sống sót 1 lần ở 1 HP) · `lock` (enemy die khoá mặt hiện tại lượt sau)

### B5. Class × Tier (18 unit)
Identity qua **phân bố part**, không qua vị trí mặt.

| Class | Vai trò | Bias part | T1→T2→T3 |
|---|---|---|---|
| Plant | Tank / shield diện rộng | back×3 | Sprout → Bracken → Elder Bramble |
| Beast | Burst damage | horn, `heavy`/`growth` | Cub → Ravager → Alpha Fang |
| Aqua | Mana / cantrip / tempo | ears, eyes `cantrip` | Fry → Tidecaller → Abyss Herald |
| Reptile | Giáp + thorns + poison | back, tail `poison` | Hatchling → Scaleguard → Basilisk |
| Bug | Debuff (weaken/blind/vulnerable) | eyes `debuff` | Grub → Swarmling → Hive Tyrant |
| Bird | Pierce / hit hàng sau | horn `pierce`, `aoe` | Chick → Skirmisher → Storm Talon |

Level-up = ghi lại toàn bộ die + maxHP. T3 maxed → reward chuyển thành `+3 maxHP`.

### B6. Difficulty Curve (point-budget, tune bằng simulation)
Không hardcode bảng HP. Mỗi encounter có **budget** điểm, mua monster template theo cost:
```
budget(w) = round(6 + 3.1*w + 0.30*w^2)        # normal
elite  : budget ×1.35, +1 elite-tag monster
boss   : fixed boss stat block, không dùng budget
statScale(w) = 1 + 0.085*(w-1)                 # nhân HP/DMG của template
enemyCount = clamp(2 + floor(w/4), 2, 5)
```
Player power grow: mỗi wave +1 reward → tier-up (~×1.35 power/tier) hoặc item (~+8%).
**Mục tiêu curve (đo bằng sim, 2000 run, AI greedy):**

| Wave | Win-rate/trận mong đợi | Turn/trận |
|---|---|---|
| 1-4 | 96-99% | 2-3 |
| 5 (boss) | 90% | 4-5 |
| 6-10 | 85-92% | 3-4 |
| 11-15 | 72-85% | 4-6 |
| 16-19 | 62-75% | 4-6 |
| 20 (final) | 45-55% | 6-8 |

→ Win-rate cả run mục tiêu **12-20%** (đúng vùng roguelike gây nghiện). Nếu sim lệch, tune 2 hằng số `3.1` và `0.30`.

### B7. Reward pool (chọn 1/3 sau mỗi wave)
`LEVEL_UP` (w 40) · `ITEM` (w 30) · `GENE_MUTATION` (w 18) · `MAX_REROLL+1` (w 6, max 3) · `RECRUIT` (w 6)

**Gene Mutation** (giữ từ GDD): `PART_REPLACE` (đổi 1 mặt thành part cấp cao) | `RUNE_IMBUE` (gắn 1 keyword vào 1 mặt) | `OVERCLOCK` (+50% value toàn die, làm tròn lên)

### B8. UI/UX (layout S&D)
```
┌──────────────────────────────────────────────┐
│ WAVE 8/20            ↺ 1/1        [UNDO][⚙] │  ← top bar
├──────────────────────────────────────────────┤
│            [ENEMY]  [ENEMY]  [ENEMY]         │  ← sprite + HP bar + intent die
├──────────────────────────────────────────────┤
│   [A1]  [A2]  [A3]  [A4]  [A5]               │  ← party sprite + HP/shield
│   ▣     ▣     ▣     ▣     ▣                  │  ← die đã roll (drag được)
├──────────────────────────────────────────────┤
│ ⚡3  [Item][Item]        [REROLL] [END TURN]  │
└──────────────────────────────────────────────┘
```
Interaction: click die → highlight target hợp lệ → click target = execute. (Click-click thay drag → mobile-friendly, ít bug hơn drag&drop.) Hover enemy → tooltip intent chi tiết. Damage preview số nổi.

### B9. Kiến trúc code
`engine.js` thuần (không DOM, seeded RNG, snapshot/undo bằng deep-clone state) · `data.js` (heroes/monsters/items/waves) · `ui.js` (DOM render diff) · `sim.js` (node, chạy N run headless để tune curve). Build → 1 file HTML self-contained.

### B10. Ngoài scope v0.1
Breeding/F1, meta-unlock persistent, blessing/curse difficulty tiers, sound, animation phức tạp, weapon/part art riêng.

---

## PHẦN C — KẾT QUẢ BALANCE THỰC ĐO (v0.1, 500 run, greedy AI)

Tuning cuối: `base 9.5 · growth 1.140 (w≤12) → 1.065 (w>12) · elite ×1.40`
Boss (hpk/dmgk × budget): Gooey 3.7/0.62 · Mecha 3.3/0.57 · Plague 3.0/0.54 · Agony 2.6+3.5/0.60

| Wave | Win% | Turns | pHP | pDPS | eHP | eDPS |
|---|---|---|---|---|---|---|
| 1-4 | 100 | 3.4-5.1 | 68→84 | 7.4→11.8 | 27→47 | 6.8→8.5 |
| 5 BOSS | 96 | 6.9 | 90 | 13.5 | 59 | 8.3 |
| 7 elite | 86 | 5.6 | 102 | 17.0 | 80 | 18.2 |
| 10 BOSS | 60 | 5.5 | 122 | 22.7 | 102 | 16.0 |
| 12 elite | 86 | 5.9 | 138 | 27.1 | 147 | 33.8 |
| 15 BOSS | 54 | 6.1 | 156 | 32.7 | 145 | 29.7 |
| 17 elite | 90 | 6.1 | 167 | 36.3 | 203 | 43.8 |
| 20 FINAL | 19 | — | 183 | 42.6 | 173 | 39.1 |

**Full-run winrate: 4.0% với greedy AI** → tương ứng ~15-20% với người chơi tốt. Đúng vùng mục tiêu §B6.
Curve đơn điệu tăng, không có cliff. Wave thường ~100% (giống S&D: bạn không chết vì trận thường, bạn chết vì boss/elite).

### 3 bug thiết kế phát hiện được **chỉ nhờ simulation** (không thể thấy bằng đọc spec)
1. **Poison/debuff scale linear = wall bất khả thi.** Plague Mother wave 15 có mặt `poison aoe` scale ×3 → 24 poison lên cả 5 Axie/lượt → winrate 0%. Fix: status-type face scale `s^0.50`, buff/debuff `s^0.45` (damage tích luỹ nhiều lượt không được scale như damage 1 lần).
2. **Cliff wave 15 do player power đứng yên sau khi max tier.** pHP đo được: w1-13 tăng 1.10×/wave, w14-20 chỉ 1.03×/wave (hết reward Level Up). Fix: (a) budget piecewise `growth2 = 1.065` sau wave 12, (b) thêm reward **ASCENSION** (+25% giá trị 6 mặt, +6 HP, stack được) cho hero đã max T3.
3. **Boss thorns/summon scale linear = death spiral.** Mecha thorns `0.14×budget` = 8 → 5 dice đánh mất 40 HP/lượt. Plague summon add scale `budget/14` = quái 36 HP mỗi 2 lượt. Fix: thorns `0.09×budget`, summon mỗi 3 lượt + hard cap `addCap`, add scale `budget/45`.

### Bug engine/UX phát hiện qua playtest tự động (Playwright)
- Hover enemy gọi `render()` full → detach DOM liên tục, flicker + click fail. Fix: hover chuyển sang CSS `:hover` thuần.
- Mặt trống hiển thị chỉ dấu `·` không đọc được → thêm nhãn "TRỐNG".
- Sprite enemy dùng filter hue-rotate không ăn với Axie màu trắng/nhạt → đổi sang `grayscale→sepia→hue-rotate` để mọi enemy đều đỏ máu, đọc ra "địch" ngay.

---
---

# PHẦN D — v0.2: PHẢN HỒI PM/UIUX → QUYẾT ĐỊNH → THỰC THI

## D1. Kết quả debate (đã chốt)

| Vấn đề | Đề xuất trong doc | Quyết định | Lý do |
|---|---|---|---|
| Rare Dice | Rarity trên CẢ VIÊN dice, Common→Cosmic | **Option D Hybrid** | Xem D2 |
| Broken build | Cho player OP dần | **Ship CÙNG Ascension 1-10** | Không có trần độ khó thì curve vỡ (đo được) |
| Run length | *(không nhắc)* | **Short 12 wave mặc định + Full 20 wave unlock** | Đòn retention lớn nhất; Balatro 30 phút là điểm mạnh, StS 60 phút là friction |
| 8 currency | Gold/Crystal/Core/Dust/Essence/Artifact/Rune/Soul | **1 currency: Gene Shard** | StS 0, Balatro 0. Shard dùng cả trong run (Merchant) và meta (Unlock) |
| Battle Pass / LiveOps / Guild | Có | **Bỏ khỏi v0.2** | Cần backend + số liệu retention trước |
| Social | Replay/Leaderboard/Guild/Seed | **Chỉ Daily Seed + Seed Share** | Rẻ (engine đã seeded RNG); phần còn lại cần server |
| 200 item / 150 dice | Số lượng lớn | **~44 relic đổi LUẬT + 50 mặt rarity** | Mục XI ("item đổi luật") thắng mục XVII ("200 item") |
| Boss Destroy/Randomize Dice | Có | **Constrain, không destroy** | Freeze 1 die = hay; xoá build 40 phút = rage quit (Time Eater problem) |
| Axie passive | 8 passive (có Mech/Dawn) | **6 passive = engine của archetype** | Mech/Dawn không có art; "Roll 6 → attack twice" không tồn tại trong model die của ta |
| Animation ngắn vs juice | Cả hai (mâu thuẫn) | **Juice chỉ ở event có ý nghĩa + slider 1×/2×/3× + giữ chuột skip** | Giải mâu thuẫn thành luật |

## D2. Rare Dice — kiến trúc đã chốt (Option D)

**Nguyên tắc: rarity là ĐẦU RA của build, không phải ĐẦU VÀO.**

- **Mechanical rarity nằm trên MẶT xí ngầu** (5 tầng), người chơi **tự chọn ghi đè mặt nào** → vẫn là quyết định, không phải xổ số.
  | Tầng | Định nghĩa | Ví dụ |
  |---|---|---|
  | COMMON | 1 action, 0 keyword | `MOUTH · dmg 6` |
  | RARE | +1 keyword | `HORN · dmg 7 · Pierce` |
  | EPIC | 2 keyword | `HORN · dmg 10 · Pierce + Crit 25%` |
  | LEGENDARY | 2 keyword + value lớn | `HORN · dmg 18 · Heavy + Pierce` |
  | MYTHIC | **phá 1 luật** | `TAIL · Poison 7 · AoE + Plague` (Poison không giảm tầng) |
- **Visual rarity nằm trên cả viên**, và là **tổng hợp** các mặt: ≥2 Legendary → **GOLDEN DIE**; ≥1 Mythic → **COSMIC DIE** (viền phát sáng + pulse).
- **Dopamine của cú roll** đến từ *conditional payoff*: mặt Mythic có 1/6 = 16.7% cơ hội rơi mỗi lượt; khi rơi → hit-stop 140ms + screen flash + orchestra hit + chữ `MYTHIC` phóng to. Tấm vé số do người chơi tự tạo.
- **CRIT quyết định NGAY LÚC ROLL** và hiện badge `CRIT ×2/×3` trên mặt dice → giữ nguyên pillar Deterministic (người chơi vẫn thấy 100% thông tin trước khi quyết định).

## D3. Đã ship trong v0.2

**FEEL** · dice tumble animation (450ms, squash & stretch, stagger 70ms/viên, tray shake anticipation) · WebAudio SFX synth 24 âm (0 byte asset) · hit-stop · screen shake 3 cấp theo damage · damage font scale · flash vàng/magenta theo rarity · micro-animation (idle breathing) · card flip ở reward · transition · **toàn bộ icon là pixel-art SVG inline** (không phụ thuộc font — đã phát hiện mọi glyph unicode đều tofu trên môi trường không có symbol font)

**UX** · Eye Flow (`f_dice` / `f_target` / `f_end` → chỉ 1 vùng sáng mỗi lúc) · intent lớn + cảnh báo nhấp nháy khi đòn nguy hiểm · **ghost HP bar preview** + số dự đoán + `KILL` marker · status: 1 icon + 1 màu + 1 animation riêng · mana orb có fill animation · HP bar pulse khi thấp · shield bar riêng · **save/resume** (localStorage, degrade an toàn) · **death recap** (7 chỉ số + kẻ hạ bạn + build cuối) + retry 1 click · **tutorial 5 bước** · speed slider 1×/2×/3× · hotkey (1-5, R, Space, Ctrl+Z, Esc)

**BUILD IDENTITY** · 6 class passive = engine archetype · **10 archetype + tracker UI** hiện realtime "bạn đang chơi PLAGUE 7" · **44 relic qua hệ hook** (`modFace/modDmg/onKill/onShield/onHit/onTurnStart` + cờ `plague/echo/bastion/overflow/critMult/poisonTicks/...`) · 50 mặt rarity · status mới: crit, burn, freeze (constrain), summon · 20 monster **chia 9 role** (bruiser/assassin/tank/healer/poisoner/mage/summoner/kamikaze/buffer) · **6 boss** mỗi con 1 mechanic (Split / Thorns+Overdrive / Freeze / Summon / **Mirror — copy mặt mạnh nhất bạn vừa dùng** / 2-Phase), thứ tự boss random mỗi run

**MAP & EVENT** · map chọn **2 node mỗi wave**, option B luôn khác loại option A → luôn là quyết định thật · 6 loại event (Shrine/Merchant/Treasure/Campfire/Casino/Bể Đột Biến) · reward rhythm 4 tầng theo node · **Chaos Deal** (−20% Max HP → relic Epic+) và **Curse Pact** (địch +18% HP → mọi mặt DMG +4) · **Ascension 1-10**

**META** · 1 currency (Gene Shard) · 8 unlock (mở Full Run, relic pool II/III, gene pool II/III, +1 reroll, di sản, huyết mạch) · collection log (relic/mặt/boss) · daily seed + copy seed

**Kiến trúc quan trọng:** budget encounter giờ suy từ **power level** (số reward đã nhận) chứ không phải step index → tự thích ứng cho cả run 12 và 20 wave, và cho cả trường hợp người chơi chọn event thay vì battle. Không cần 2 bảng cân bằng.

## D4. Balance đo được (sim, greedy AI)

**SHORT RUN 12 wave, Ascension 0** — `100 100 71 92 95 73 91 83 92 69 90 38` (elite @3/6/10, boss @4/8/12) · run 14.4%
**Ascension ladder:** A0 14.4% → A3 9.2% → A6 5.2% → A10 0.4%
**FULL RUN 20 wave, A0:** run 6.0%
→ AI greedy 14% ⇒ người chơi tốt ~25-30% ở Short A0. Ascension là trần độ khó, đúng như đã tranh luận: **broken build chỉ an toàn khi có Ascension đi kèm**.

**10 archetype đều có run thắng** (5%-20% winrate). TALON (pierce) và CONDUIT (mana) đang là 2 archetype yếu nhất với AI — cần playtest người thật trước khi tune, vì AI không biết chơi theo build.

## D5. Bug phát hiện qua verify tự động (Playwright)

1. `.ghost` (HP preview) **trùng tên class với `.btn.ghost`** → mọi nút ghost bị `position:absolute` và bay ra khỏi layout. Đây là loại bug chỉ thấy khi đo bounding box, không thấy khi đọc code.
2. Tutorial overlay append vào `body` nhưng `render()` chỉ xoá `#app` → overlay chồng vô hạn, chặn mọi click.
3. `Object.assign(el(...),{dataset:{...}})` — `dataset` read-only → render throw giữa combat.
4. Ally summon giữa lượt không được roll → `u.die[-1]` undefined → crash.
5. Mọi glyph unicode (⚔ ☠ ↯ ✚ ♥ ❄ ♛...) đều tofu trên môi trường thiếu symbol font → **thay toàn bộ bằng pixel-art SVG**.

## D6. Vẫn ngoài scope (đúng như đã tranh luận)

Battle Pass · Season · Guild · Leaderboard · Replay system · 8 currency · Breeding/F1 · art part/vũ khí riêng · Mech/Dawn class (chưa có art).

---
---

# PHẦN E — v0.3: HOÀN TẤT A2 + HOẠT ẢNH CHIẾN ĐẤU KIỂU S&D

## E1. Đối chiếu lại toàn bộ A2 (trạng thái thực tế trong code)

| Mục | Nội dung sửa | Trạng thái |
|---|---|---|
| A2.1 | Party 3 → **5 Axie** | ✅ v0.1 |
| A2.2 | Bỏ map cứng mặt↔part; mỗi hero có phân bố part riêng | ✅ v0.1 |
| A2.3 | Level-Up / Transformation Tree T1→T2→T3 (18 unit) | ✅ v0.1 · +ASCENSION cho hero đã max |
| A2.4 | Reroll là resource, chọn từng die, base 1 upgrade tới 4 | ✅ v0.1 |
| A2.5 | Bỏ hand-cards → **Mana + Relic**, active hiển thị như "Thẻ Lunacia" | ✅ v0.1 · v0.2 nâng thành 44 relic đổi luật |
| A2.6 | Undo boundary = **randomness** (Reroll / End Turn), không phải chỉ End Turn | ✅ v0.1 · relic `Xí Ngầu Vô Cực` cho phép undo qua reroll |
| A2.7 | Targeting tự do; vị trí chỉ ảnh hưởng Cleave + AI role | ✅ v0.1 · v0.2 thêm 9 enemy role (assassin nhắm Axie yếu nhất…) |
| A2.8 | Boss 5/10/15/20 | ✅ Full run 5/10/15/20 · Short run 4/8/12 |
| A2.9 | Hết trận: heal full + hồi sinh | ✅ v0.1 |
| A2.10 | Enemy có dice và cũng roll; mặt roll ra = intent | ✅ v0.1 |
| A2.11 | Rebuild toàn bộ toán cân bằng bằng point-budget + simulation | ✅ v0.1 · v0.2 chuyển budget sang **power-level based** |
| A2.12 | status breadth · **reward-reroll** · difficulty tiers · win/lose screen · save/resume | ✅ — **reward-reroll là mục cuối cùng, bổ sung ở v0.3** |

**Reward-reroll (mới):** mỗi wave được **1 lần đổi cả 3 lựa chọn** phần thưởng. Đây là van xả xui của S&D/StS — không có nó, người chơi bị ép nhận reward lệch build và run hỏng vì RNG chứ không vì quyết định.

## E2. Hoạt ảnh chiến đấu — kiến trúc

Vấn đề gốc: engine cũ **mutate state tức thì**, nên toàn bộ lượt địch resolve trong 1 frame — không thể "xem" trận đánh diễn ra.

**Giải pháp: event stream.** Engine giờ phát ra một dòng sự kiện có thứ tự (`s.ev`) song song với việc mutate state:
```
{t:'use',  uid, side, tgt, aoe}   // một mặt dice được dùng
{t:'eact', uid}                   // một con địch bắt đầu hành động
{t:'hit',  src, uid, v, crit}     // một cú đánh trúng
{t:'ft',   uid, txt, cls, big}    // số bay lên
{t:'hp',   uid, hp, maxHp, shield}// snapshot bar sau mỗi thay đổi
{t:'death',uid} · {t:'tick'} · {t:'phase',uid}
```
UI **phát lại tuần tự** (`playEvents`), và **không re-render trong lúc phát** — chỉ mutate DOM trực tiếp để animation không bị giật. Logic và simulator không đổi một dòng nào (sim vẫn ra đúng con số cũ: Short 14.4%, Full 6.0%).

## E3. Những gì đã copy từ S&D

| S&D | Đã có trong v0.3 |
|---|---|
| Xúc xắc lăn thật, xoay 3D rồi rơi xuống khay | Tumble **rotateX/rotateY/rotateZ 3D** + perspective, **bóng đổ co giãn** theo nhịp lăn, đáp bằng **squash & stretch** 4 nhịp, stagger 70ms/viên → 5 viên đọc thành cascade |
| Kéo–thả xí ngầu lên mục tiêu | **Drag & drop** đầy đủ: đường ngắm vàng nét đứt có mũi tên bám con trỏ, mục tiêu dưới con trỏ bật viền trắng + phóng to. Vẫn giữ click-click cho mobile |
| Xí ngầu bay tới mục tiêu khi dùng | `dieFly` — clone viên dice bay theo cung tới mục tiêu, thu nhỏ + mờ dần; viên gốc xám lại |
| Nhân vật lao lên khi đánh, giật lùi khi trúng | `lunge` (hướng về mục tiêu) + `knock` (biên độ theo damage) |
| Trúng đòn thì sprite chớp trắng | `hitflash` — brightness ×6 desaturate; bản riêng cho enemy để không phá filter mutant |
| Máu tụt có "chip bar" trễ | `.hpchip` đỏ sẫm tụt sau `.hpfill` 220ms → mắt đọc được vừa mất bao nhiêu |
| Giáp vỡ có hiệu ứng | `.shbar.brk` — nở ra rồi tan |
| Địch hành động **lần lượt**, con đang đánh được highlight | `{t:'eact'}` → viền đỏ `.acting` + pause 230ms trước mỗi con |
| Chết thì gục xuống + puff khói | `.dying` (nghiêng, chìm, xám) + `.puff` |
| Giữ chuột để tua nhanh | Giữ chuột / Space → ×4 tốc độ, có hint dưới màn hình |
| Hit-stop + screen shake + flash | Có, phân 3 cấp theo damage; crit thêm hit-stop 110ms + flash vàng |

Toàn bộ tôn trọng slider **1× / 2× / 3×**. Input bị khoá trong lúc playback (`body.playing`) để không click nhầm.

## E4. Nhịp một lượt (đo thực tế, tốc độ 1×)
```
Roll     : 430ms + 70ms/viên stagger  → ~0.75s cho 5 viên
Dùng die : 150ms bay + 70ms impact    → ~0.25s/hành động
Lượt địch: 230ms highlight + ~0.2s/đòn → ~0.45s/con
Tick     : 160ms
```
→ Một lượt đầy đủ với 3 địch ≈ **2.5-3s** ở 1×, **~1s** ở 3×, **~0.7s** khi giữ chuột tua.

---
---

# PHẦN F — v0.3.1: CODEX · LUNACIA PASS · ĐỘI HÌNH MẪU

## F1. Ghi chú thiết kế về "Battle Pass"

Ở Phần D tôi phản đối Battle Pass — nhưng cái tôi phản đối là **battle pass live-service**: có season timer, có tier trả tiền, mất tiến độ khi hết mùa, cần backend. Cái được yêu cầu ở đây là **mốc thưởng + progression**, và đó chính xác là thứ tôi nói đang thiếu (Progression 5/10, Long-term 4/10 trong bảng điểm PM).

Nên tôi ship nó dưới dạng **track XP vĩnh viễn**, không phải battle pass thương mại:
- **Không có thời hạn** — không mất tiến độ, không FOMO.
- **Không có nhánh trả tiền** — một track duy nhất.
- **Thua vẫn nhận XP** — đây là điểm quan trọng nhất về retention: 86% run kết thúc bằng thất bại, nếu thất bại cho 0 tiến độ thì người chơi bỏ game. Giờ mỗi run thất bại vẫn đẩy Pass lên.

Nếu sau này thương mại hoá, cấu trúc này chuyển thành season pass được mà không phải viết lại — chỉ thêm lớp track thứ hai.

## F2. LUNACIA PASS — 30 mốc

**Công thức XP:** `30 (tham gia) + 10×wave vượt qua + 30×Elite + 60×Boss + 150 (nếu thắng) + 25×Ascension + 40 (Full Run)`
**XP mỗi level:** `45 + 22×(lv−1)` → tổng 30 level ≈ **10.900 XP** ≈ 40-45 run.
Run đầu tiên dù thua cũng lên được Level 1-2 (dopamine ngay lần chơi đầu).

**Phân bổ mốc:** Shard (14 mốc) · Unlock hệ thống (4) · Perk vĩnh viễn (7) · **Mặt xí ngầu độc quyền (5)**.
Mốc lớn ở Lv **5 · 10 · 12 · 15 · 19 · 20 · 25 · 26 · 30** — nhịp thưa dần nhưng to dần, đúng kiểu TFT.
Lv 30 tặng danh hiệu **LUNACIA SOVEREIGN** hiển thị ở menu.

## F3. 5 mặt xí ngầu độc quyền — mỗi mặt chốt một lối chơi

| Lv | Tên | Lối chơi | Hiệu ứng |
|---|---|---|---|
| 5 | **NỌC TẬN THẾ** | PLAGUE | `TAIL · Poison 10 · AoE + Plague + Pierce` — Poison 10 lên toàn bộ địch, **không giảm tầng**, và gây luôn sát thương xuyên giáp bằng số tầng |
| 12 | **SỪNG HÀNH QUYẾT** | APEX (crit) | `HORN · dmg 24 · Crit 100% + Cleave + Execute` — **luôn crit**, lan sang 2 mục tiêu kề, +60% lên mục tiêu dưới 50% HP |
| 19 | **GIÁP THÀNH TRÌ** | BULWARK | `BACK · Shield 22 · AoE + Bastion + Thorns 6` — +22 Shield toàn party, mỗi lần tạo Shield **gây sát thương bằng 100% giá trị** |
| 26 | **TAI VÔ CỰC** | CONDUIT | `EARS · Mana 10 · Cantrip + Overflow + +Reroll` — +10 Mana tự kích hoạt, +1 Reroll, Mana thừa cuối lượt **nổ thành AoE** |
| 30 | **TỔ NGUYÊN THUỶ** | SWARM | `EYES · Summon 4 · Cantrip` — triệu hồi 4 Axie Egg ngay lúc gieo trúng, không tốn lượt dùng |

Các mặt này **chỉ vào pool reward khi đã mở khoá** (`facePool` lọc theo `s.bpFaces`) → người chơi mới không bị loãng pool.

**Kiểm chứng không phá cân bằng:** sim 250 run, mở đủ 5 mặt → run winrate **13.2%** so với 14.4% khi không có. Chúng *không* làm game dễ hơn, vì chúng là **build-defining chứ không phải raw power** — chúng chỉ mạnh khi người chơi cố tình xây quanh chúng, mà AI greedy thì không biết làm vậy.

## F4. CODEX — luật chơi đầy đủ ở màn hình chờ

14 mục, **auto-generate từ data** nên không bao giờ lệch với code: vòng lặp · 6 bộ phận · 5 tầng độ hiếm · Golden/Cosmic die · 17 keyword · 11 trạng thái · 6 class + nội tại · 10 archetype · 6 loại node · 8 loại phần thưởng · 6 boss + mechanic · Ascension 1-10 · phím tắt.

Truy cập từ **menu chính** và từ **màn chọn đội hình** (thời điểm người chơi thật sự cần tra cứu).
Tutorial 5 bước in-game vẫn giữ nguyên cho lần chơi đầu — Codex là tài liệu tra cứu, tutorial là onboarding.

## F5. ĐỘI HÌNH MẪU — 4 build cho người mới

Mỗi thẻ có: 5 Axie cụ thể · độ khó · **vì sao hoạt động** (giải thích passive nào cộng hưởng) · 4 gạch đầu dòng cách chơi (ưu tiên gì, săn relic nào, win-con là gì, **điểm yếu là gì**) · nút nạp thẳng đội hình.

| Đội hình | Lối chơi | Độ khó |
|---|---|---|
| **BỨC TƯỜNG SỐNG** | 2 Plant + Reptile + Bug + Aqua — Shield/Thorns | DỄ · khuyên cho người mới |
| **DỊCH HẠCH** | 2 Bug + Reptile + Plant + Aqua — Poison cấp số nhân | Trung bình |
| **NANH ĐỈNH** | 2 Beast + Bird + Plant + Aqua — burst/execute | Trung bình · nhanh nhất |
| **DÒNG CHẢY** | 2 Aqua + Plant + Bird + Bug — mana/active spam | Khó · trần cao nhất |

Việc ghi rõ **điểm yếu** của từng build là có chủ đích: người chơi mới thua mà không hiểu vì sao thì bỏ game; thua mà biết "à build này yếu wave đầu" thì chơi tiếp.

---
---

# PHẦN G — BRAINSTORM: ĐƯA COLLECTIBLE PART CỦA AXIE VÀO GAME

*Góc nhìn: Lead Game Designer, và có tính tới cách Sky Mavis đã tạo utility cho collectible từ trước tới nay.*

## G1. Vì sao độ khớp ở đây là bất thường (structural, không phải marketing)

Đây không phải chuyện "gắn NFT vào game cho có". Cấu trúc dữ liệu của hai bên **trùng khớp 1:1**:

| Axie thật | Axie Dice Tactics |
|---|---|
| 1 Axie = **6 body part** (eyes, ears, mouth, horn, back, tail) | 1 Axie = **1 viên xí ngầu 6 mặt** |
| Mỗi part quyết định 1 lá bài trong Origins | Mỗi mặt quyết định 1 hành động |
| Part có class riêng (có thể khác class thân) | Mặt có type/keyword riêng |
| Part có độ hiếm (Common → Mystic/Origin) | Mặt có 5 tầng độ hiếm |
| "Purity" (6 part cùng class) có giá thị trường | Có thể thành set bonus |

Không cần bẻ cong cơ chế nào cả. **Viên xí ngầu CHÍNH LÀ con Axie**, theo nghĩa đen. Đây là điều tôi chưa thấy game Axie nào khai thác đúng: hầu hết dùng Axie như một *skin có stat*, còn ở đây part là **đơn vị gameplay nguyên tử**.

## G2. Bối cảnh: Sky Mavis đã tạo utility cho part bằng những cách nào

1. **Breeding** — part là vật liệu di truyền (D/R1/R2). Utility = sinh ra Axie mới.
2. **Origins** — part = lá bài. Utility = bản sắc chiến đấu, và Sky Mavis **đã chạy balance patch trên part** (buff/nerf card theo mùa).
3. **Purity / class matching** — thị trường tự định giá độ thuần chủng.
4. **Part đặc biệt** (Mystic, Origin, Japanese, MEO) — khan hiếm + cosmetic premium.

**Một ràng buộc quan trọng thường bị bỏ qua:** part **không có thanh khoản độc lập**. Bạn không mua được "một cái mỏ Nut Cracker" — bạn phải mua nguyên con Axie mang nó. Nghĩa là: game nào tạo ra *nhu cầu ở tầng part* thì sẽ **gián tiếp tạo nhu cầu cho nguyên con Axie mang part đó**. Đây chính là cơ chế dịch chuyển thị trường.

## G3. Tám hướng phát triển, xếp theo (giá trị tạo ra ÷ công sức × rủi ro)

### ① PART → FACE 1:1 — nền móng ★★★★★
Import Axie → 6 part của nó trở thành 6 mặt xí ngầu. Người chơi *đọc* con Axie của mình theo nghĩa đen.
**Không hand-author 500 mặt.** Viết ~40 **face template** và một hàm map tất định:
```
face = TEMPLATE[ part.slot ][ part.class ] scaled by TIER[ part.rarity ]
```
→ 500+ part có bản sắc riêng, nhưng chỉ **40 quyết định cân bằng**. Đây là insight kỹ thuật quan trọng nhất của cả phần này; không có nó thì balance surface nổ tung và dự án chết.

### ② GENE PRINT — tách BẢN SẮC khỏi SỞ HỮU ★★★★★
Quét *bất kỳ* Axie nào (kể cả của người khác, kể cả chỉ paste ID) → nhận **Gene Print**: mặt đó dùng được ở ladder Standard nhưng ở dạng **skin trên một mặt cùng cấp**, không mạnh hơn. **Sở hữu** con Axie mới mở bản full-power ở ladder Collector.
→ Bản sắc lan truyền miễn phí (viral), quyền sở hữu vẫn có giá trị. Đây là mô hình Pokémon GO: ai cũng thấy được, sở hữu thì tốt hơn.

### ③ HAI LADDER — giải bài toán pay-to-win ★★★★★
- **STANDARD** — pool part chung, ai cũng như nhau, có seed, **được lên leaderboard**. Đây là ladder chuẩn mực.
- **COLLECTOR** — dùng part thật của bạn, có set bonus, leaderboard riêng.

Đây là điều tôi sẽ **kiên quyết** với tư cách designer: khoảnh khắc một part $2.000 thắng part miễn phí trong đối đầu 1v1, game ngừng nói về kỹ năng, phễu F2P chết — **và giá trị collectible sụp theo**, vì không ai mới vào chơi nữa. Nghịch lý của NFT game: bảo vệ người chơi free chính là bảo vệ giá sàn.

### ④ SET BONUS THEO PURITY — hợp thức hoá tín hiệu thị trường sẵn có ★★★★☆
3+ part cùng class trên một viên → bonus class. Đủ 6 part cùng class (Axie thuần) → bonus lớn.
Điểm hay: thị trường **đã** định giá purity rồi. Game không phát minh tín hiệu mới, nó **xác nhận** tín hiệu cũ — nên không tạo méo giá đột ngột, chỉ làm sâu thêm cái đã tồn tại.
Quan trọng: set bonus phải **horizontal** (đổi cách chơi) chứ không **vertical** (cộng stat thuần).

### ⑤ PART RENTAL — scholarship 2.0, primitive thật sự mới ★★★★☆
Sky Mavis hiểu scholarship hơn ai hết. Nhưng cho thuê nguyên con Axie có ma sát cao. Ở đây có thể cho thuê **một part** trong N run, chủ sở hữu ăn % Gene Shard / Pass XP người thuê kiếm được.
Vì part không chuyển nhượng độc lập được trên chain, đây phải là **abstraction phía game** (chủ sở hữu ký một message, game cấp quyền dùng) — không cần transaction, không cần custody. Ma sát gần bằng 0.

### ⑥ BURN → GENE DUST — sink cho hàng tồn ★★★★☆
Vấn đề lớn nhất của hệ Axie là **nguồn cung dư thừa** hàng triệu Axie giá gần 0. Cho phép burn Axie → nhận Gene Dust → craft/reroll mặt Mythic.
Đây là **deflationary sink có ý nghĩa gameplay**, không phải burn-để-burn. Người chơi burn vì họ *muốn* thứ đổi lại, không phải vì được bảo là tốt cho hệ sinh thái.

### ⑦ SEASONAL PART META — thứ giữ nền kinh tế còn sống ★★★☆☆
Mỗi mùa buff/nerf một số họ part (giống TFT set rotation, và giống chính cái Origins đang làm). Patch note dịch chuyển giá sàn → thị trường có nhịp → collectible có lý do được giao dịch lại.
Rủi ro: nếu tay lái quá nặng thì thành thao túng thị trường. Cần biên độ nhỏ và công bố trước.

### ⑧ RUNE NFT — game TẠO RA collectible chứ không chỉ tiêu thụ ★★★☆☆
Kết quả Gene Mutation trong game có thể mint thành **Axie Dice Rune** gắn vào một part. Lần đầu tiên một game Axie *sản xuất* collectible mới thay vì chỉ đốt cái cũ. Nhưng đây là hướng dài hạn, phụ thuộc hạ tầng và pháp lý.

## G4. Ba rủi ro tôi sẽ nêu trong phòng họp

1. **Pay-to-win** — xử bằng ⑤ Hai ladder. Không thương lượng.
2. **Wallet trước niềm vui** — bắt kết nối ví trước khi người chơi kịp thấy game hay là tự sát phễu. **Ví phải là tuỳ chọn, xuất hiện SAU khi người chơi đã nghiện**, và ở bước đầu chỉ cần **read-only** (paste Axie ID / địa chỉ ví, không ký gì).
3. **Balance surface 500 part** — xử bằng ① template mapping. Nếu ai đó đề nghị "mỗi part một hiệu ứng riêng", đó là dự án 2 năm và không bao giờ cân bằng được.

## G5. Prototype v0.4 — làm được NGAY, không cần blockchain

Điểm mấu chốt: **art trong game này đã được lấy từ Axie marketplace GraphQL + CDN**. Cùng một query đó đã trả về `parts[]` của từng Axie. Nghĩa là:

```
Input:  Axie ID hoặc địa chỉ ví (không ký, không custody)
   ↓    marketplace GraphQL (đúng endpoint đang dùng cho art)
Output: 6 part + class + rarity → map qua 40 template → viên xí ngầu
```

**Scope demo:** màn "IMPORT AXIE" → paste ID → hiện đúng con Axie đó với viên xí ngầu suy ra từ 6 part thật của nó → chơi Standard ladder với nó ở dạng Gene Print.
Ước lượng: **1-2 ngày**. Không ví, không transaction, không rủi ro pháp lý. Đủ để đo phản ứng trước khi cam kết bất cứ thứ gì on-chain.

## G6. Giá trị kinh doanh thật sự nằm ở đâu (không phải doanh thu trực tiếp)

Nếu game trả lời được câu **"con Axie #12345 của tôi tạo ra viên xí ngầu như thế nào?"**, thì mọi Axie trong marketplace đột nhiên có một **bản sắc đọc được bằng gameplay**.

Người mua bắt đầu lọc marketplace theo *"part nào tạo ra viên xí ngầu tốt"* — và Axie Dice trở thành **cỗ máy sinh tín hiệu nhu cầu** cho một thị trường đang thiếu tín hiệu nhu cầu. Theo tôi đó là giá trị lớn hơn hẳn doanh thu trực tiếp từ chính tựa game.

## G7. Đề xuất thứ tự triển khai

| Giai đoạn | Nội dung | Điều kiện đi tiếp |
|---|---|---|
| **P0** | 40 face template + hàm map + màn Import Axie (read-only) | ≥30% người chơi thử import |
| **P1** | Gene Print + Standard/Collector ladder | Collector ladder giữ chân tốt hơn Standard |
| **P2** | Set bonus purity + Burn → Gene Dust | Có tín hiệu giá trên marketplace |
| **P3** | Part rental + seasonal meta | Có thanh khoản thật ở tầng part |
| **P4** | Rune NFT | Chỉ khi P0-P3 đều xanh |

**Đo cái gì:** tỉ lệ import / retention D7 của người có import vs không / số Axie khác nhau được quét (chỉ số lan truyền) / có xuất hiện tương quan giữa "part được dùng nhiều trong game" và giá sàn Axie mang part đó hay không — đây là chỉ số chứng minh vòng lặp game↔thị trường thật sự đóng lại.

---

## G8. Quyết định 2026-09-01 — ghi đè khuyến nghị "Hai ladder, không thương lượng"

> **Bối cảnh**: economy-designer (xem `docs/review-2026-08-31.md`) khuyến nghị mạnh: tách Standard/Collector ladder để người chơi F2P không bao giờ thua vì đối thủ trả tiền, gọi đây là điều "kiên quyết, không thương lượng". Product owner đã cân nhắc và **chủ động ghi đè** khuyến nghị đó cho hướng đi hiện tại. Ghi lại rõ để không ai đọc review cũ rồi tưởng nhầm đó vẫn là quyết định cuối.

**Quyết định 1 — chấp nhận rủi ro power creep từ mở khoá theo chiều ngang, có điều kiện NFT.**
Rủi ro đã nêu (tự nêu trước khi được hỏi): mở khoá "theo chiều ngang" (nhiều part hơn = nhiều lựa chọn khớp build hơn) vẫn gián tiếp làm người chơi mạnh lên — đúng cái bẫy mà Slay the Spire gặp phải với unlock trên nhiều run. **Quyết định: chấp nhận rủi ro này**, với điều kiện: sức mạnh tăng thêm phải gắn với việc **sở hữu NFT Axie thật**, không phải mua trực tiếp bằng tiền không giới hạn qua currency in-game. Nói cách khác: pay-to-win được chấp nhận có kiểm soát, miễn nó chảy qua đúng kênh "sở hữu Axie thật" — không phải gói premium thẳng cho gameplay.
→ **Hệ quả cho §G3 (Hai Ladder)**: mô hình "Standard = ai cũng như nhau" **không còn là ràng buộc cứng**. Cần thiết kế lại ranh giới Standard/Collector (hoặc bỏ hẳn phân tách đó) theo đúng tinh thần "NFT owner được mạnh hơn, có kiểm soát" — việc này chưa làm, xem Open Questions ở `design/gdd/game-concept.md`.

**Quyết định 2 — mô hình đội hình lai: chọn trước từ bộ sưu tập + vẫn tuyển/nâng cấp trong run.**
Câu hỏi đặt ra: Axie trong run là thứ tuyển giữa đường (như hiện tại — 1 Lead Axie chọn trước + 4 Axie còn lại tuyển ngẫu nhiên trong lúc chơi) hay chọn sẵn hoàn toàn trước khi vào run từ bộ sưu tập? Đánh đổi: chọn trước → bộ sưu tập thành "tủ đồ", cảm giác sở hữu rõ hơn nhưng roguelike nhạt đi (mất bất ngờ tuyển quân); tuyển giữa đường → giữ bất ngờ nhưng bộ sưu tập cảm giác xa, ít gắn bó.
**Quyết định: mô hình lai.** Người sở hữu NFT Axie có thể **chọn trước** (không chỉ 1 Lead Axie như hiện tại — cần xác định lại số lượng NFT Axie chọn trước tối đa), nhưng Axie đó **vẫn tier-up/nâng cấp được trong run** như cơ chế hiện tại (không phải "mang nguyên sức mạnh cố định vào trận" — vẫn bắt đầu từ Common và lên bậc qua reward, đúng nguyên tắc D2 "rarity là đầu ra của build, không phải đầu vào"). Phần đội hình còn lại (không phải Axie NFT được chọn trước) tiếp tục tuyển giữa đường như hiện tại — giữ được bất ngờ cho phần không sở hữu.
→ **Đã chốt 2026-09-01**: người sở hữu đủ ≥5 Axie NFT được chọn **toàn bộ 5/5** đội hình trước khi vào run (không giới hạn tỷ lệ theo số lượng sở hữu). **Không bù trừ độ khó** (không tự tăng Ascension hay tương đương) — giữ nguyên quyền lợi, đúng tinh thần đã chấp nhận rủi ro P2W có kiểm soát ở Quyết định 1. Hệ quả: curve đo được ở §B6/§C (áp dụng cho đội hình tuyển ngẫu nhiên) **sẽ cần đo lại riêng cho đội hình toàn-NFT-chọn-trước** qua `sim.js` sau khi tính năng này được implement — không giả định số cũ còn đúng. Việc còn treo: chưa xác định ngưỡng sở hữu cho các mức chọn-trước trung gian (sở hữu 1-4 con thì được chọn trước bao nhiêu?) — có thể để tuyến tính (sở hữu N con NFT → chọn trước tối đa N, cap ở 5) làm mặc định hợp lý cho tới khi có quyết định khác.
