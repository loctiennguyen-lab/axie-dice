# Game Concept — Axie Dice Tactics: Lunacia Mutants

> **Status**: Approved (retroactively documented — matches shipped build)
> **Author**: Original design team (retrofit vào format template bởi Claude Code, 2026-08-31)
> **Last Updated**: 2026-08-31
> **Implements Pillar**: Minh bạch triệt để (Deterministic / Telegraphed Intent)
> **Nguồn**: viết lại toàn bộ từ `docs/axiedice-source/design/AUDIT_AND_SPEC_v1.md` (Phần B–F, các quyết định đã chốt qua v0.1→v0.3.1) và `docs/axiedice-source/guide/PLAYER_GAME_GUIDE_v1.md`, đối chiếu trực tiếp với `src/engine.js`/`src/data.js`/`src/ui.js` để đảm bảo khớp code đang chạy. **Đây là bản thay thế hoàn toàn** cho `game-concept.md` phiên bản trước — bản cũ mô tả một thiết kế đã bị chính đội ngũ audit và sửa lại từ v0.1 (xem game-designer review 2026-08-31 trong `docs/review-2026-08-31.md`).

---

## Overview

Axie Dice Tactics: Lunacia Mutants là một game roguelike chiến thuật xác định (deterministic), chạy trong trình duyệt, đóng gói thành một file HTML tự chứa (không engine, không bundler — xem `.claude/docs/technical-preferences.md`). Mỗi Axie trong đội 5 con là một viên xúc xắc sáu mặt; mỗi mặt là một bộ phận cơ thể thật của Axie (mouth/horn/back/tail/eyes/ears), quyết định một hành động. Đầu mỗi lượt, cả phe người chơi lẫn địch cùng roll dice; mặt địch roll ra hiển thị công khai làm intent. Người chơi chọn reroll (giới hạn) rồi gán từng mặt đã roll vào mục tiêu, với undo tự do trong lượt. Người chơi dẫn dắt đội vượt qua một chuỗi trận đánh (12 hoặc 20 wave) chống lại quái vật Chimera, thu thập phần thưởng (level-up, item/relic, gene mutation) sau mỗi trận.

## Player Fantasy

*"Không có gì trong game này bị giấu khỏi bạn. Mọi thất bại đều là do bạn tính sai."*

Đây là điểm khác biệt cốt lõi so với roguelike deck-builder thông thường (Slice & Dice, Slay the Spire): **minh bạch triệt để**. Kẻ địch không giấu bài — trước khi hành động, người chơi đã biết chính xác địch sắp đánh ai, bao nhiêu sát thương. Player fantasy không phải "may mắn thắng" mà là "nhà chiến thuật đọc vị chính xác" — cảm giác thắng đến từ việc tính toán đúng một tình huống đã biết trước 100% thông tin, không phải từ RNG có lợi.

Bổ trợ cho fantasy chính: "lắp ráp bản sắc" — mỗi Axie là tổ hợp 6 bộ phận cụ thể, người chơi có thể đọc con Axie của mình theo đúng nghĩa đen qua các mặt xúc xắc nó mang.

## Detailed Rules

### Core Rules — Vòng lặp một trận

```
RUN = 12 wave (Short) hoặc 20 wave (Full, mở khoá sau).
  Short: boss @4,8,12 · elite @3,6,10
  Full:  boss @5,10,15,20 · elite @3,7,12,17
WAVE = combat → chọn 1/3 phần thưởng → wave sau.
COMBAT TURN (4 bước):
  1. ROLL    — 5 die của party + toàn bộ die địch roll đồng thời. Mặt có `cantrip` tự kích hoạt ngay.
  2. REROLL  — chọn từng die muốn đổi (không chọn = giữ nguyên, không có checkbox "Lock" riêng),
               tốn 1 charge/lần. Reroll xoá undo stack (trừ khi có relic đặc biệt).
  3. EXECUTE — click mặt đã roll → click mục tiêu hợp lệ (click-click, không bắt buộc kéo-thả).
               Dùng active của relic (tốn Mana). Undo tự do trong bước này.
               Formation Resonance: hai Axie liền kề trong đội hình (`s.roster`) cùng roll mặt cùng
               loại (dmg/shield/heal/poison/mana) trong cùng lượt → Axie thực thi SAU trong cặp nhận
               +25% giá trị mặt (xem `design/quick-specs/formation-resonance-2026-09-01.md`).
  4. END TURN — địch thực hiện intent theo thứ tự vị trí → tick status (poison/burn/regen) →
               kiểm tra thắng/thua.
Hết trận (thắng hoặc thua): toàn party hồi đầy máu + Axie đã chết sống lại trước wave kế tiếp.
Độ khó nằm ở TỪNG TRẬN, không phải hao mòn đội hình qua nhiều trận.
```

### Core Rules — Die & Part vocabulary

Die = 6 mặt. Mặt = `{part, type, value, keywords[], rarity}`. Part là **vocabulary** dùng chung cho mọi class, nhưng **phân bố part trên từng die là bản sắc riêng của mỗi hero** — không có ánh xạ cứng "mặt N luôn = part N".

| Part | Type mặc định | Ý nghĩa |
|---|---|---|
| `mouth` | dmg | Đánh đơn, hay kèm `lifesteal` |
| `horn` | dmg | Đánh mạnh, hay kèm `pierce`/`heavy` |
| `back` | shield | Giáp cho mình/đồng đội |
| `tail` | dmg/poison | Đa mục tiêu, `cleave`/`aoe`/poison |
| `eyes` | heal/debuff | Utility, hay `cantrip` |
| `ears` | mana | +mana, luôn `cantrip` |
| (blank) | — | Mặt trống — tồn tại để die T1 yếu hơn |

**Keywords chính** (xác nhận trong `src/data.js` dòng 5-7): `cleave` `pierce` `aoe` `cantrip` `heavy` `growth` `decay` `vital` `lifesteal` `exec` `multi:N` `chain:N`(→ N đòn ngẫu nhiên, tên gọi lịch sử `scatter:N`) `selfharm:N` `rerollup` `mana:N` `shieldself:N`. Status effect có thể gắn qua keyword tương ứng: `burn:N` `crit:N` `freeze` `stun` `blind:N` `weaken:N` `vulnerable:N` `thorns:N` `regen:N` `poison:N`.

### Core Rules — Class × Tier (6 class × 3 tier = 18 unit)

Bản sắc class đến từ **phân bố part + passive**, không từ vị trí mặt. Xác nhận trực tiếp trong `src/data.js`:

| Class | Passive (n:PASSIVE) | Hiệu ứng passive | Tiến hoá T1→T2→T3 |
|---|---|---|---|
| Plant | BULWARK | Mọi Shield tạo ra +2. Axie có ≥10 Shield nhận Thorns 2. | Sprout → Bracken → Elder Bramble |
| Beast | FERAL | Đòn đánh vào mục tiêu <50% HP gây thêm 60% sát thương. | Cub → Ravager → Alpha Fang |
| Aqua | CONDUIT | Mọi Mana nhận +1. Mỗi 4 Mana tiêu tốn cho 1 Reroll. | Fry → Tidecaller → (T3) |
| Reptile | SCALES | Luôn có Thorns 2. Thorns của bạn cũng gây Poison 1. | Hatchling → Scaleguard → (T3) |
| Bug | VIRULENT | Poison chồng lên Poison đã có +2 stack thay vì +1. | Grub → Swarmling → (T3) |
| Bird | TALON | Đòn Pierce +3 sát thương. Mặt `aoe` cũng nhận Pierce. | Chick → Skirmisher → (T3) |

Level-up (thưởng `LEVEL_UP`) = ghi lại toàn bộ die + maxHP của hero lên tier kế tiếp. Hero T3 đã max → thưởng chuyển thành `+3 maxHP` (không có tier 4).

**10 Archetype** (đọc từ tổ hợp keyword đang dùng nhiều nhất trong đội, hiển thị realtime qua tracker UI): PLAGUE(poison) · INFERNO(burn) · BULWARK(shield) · CONDUIT(mana) · TALON(pierce) · APEX(crit) · EVOLVE(growth) · SWARM(summon) · TEMPEST(aoe) · AEGIS(thorns).

### Core Rules — Rarity (5 bậc, trên MẶT xúc xắc, không trên cả viên)

Xác nhận `RARITY = ['COMMON','RARE','EPIC','LEGENDARY','MYTHIC']` trong `data.js`. Nguyên tắc: **rarity là đầu ra của build trong-run, không phải đầu vào mua được** — mỗi trận bắt đầu lại từ Common, người chơi tự chọn ghi đè mặt nào lên bậc cao hơn qua reward.

| Tầng | Định nghĩa | Ví dụ |
|---|---|---|
| COMMON | 1 action, 0 keyword | `MOUTH · dmg 6` |
| RARE | +1 keyword | `HORN · dmg 7 · Pierce` |
| EPIC | 2 keyword | `HORN · dmg 10 · Pierce + Crit 25%` |
| LEGENDARY | 2 keyword + value lớn | `HORN · dmg 18 · Heavy + Pierce` |
| MYTHIC | phá 1 luật cân bằng thông thường | `TAIL · Poison 7 · AoE + Plague` |

Visual: ≥2 mặt Legendary trên một die → **Golden Die**; ≥1 mặt Mythic → **Cosmic Die** (viền phát sáng + pulse).

### Core Rules — Reward pool (chọn 1/3 sau mỗi wave)

**SỬA 2026-09-01 — đối chiếu lại với `genRewards()`/`mkReward()` (`src/engine.js:650-669`), bảng weight cố định 40/30/18/6/6 cũ KHÔNG khớp code thật, đã sửa lại đúng cơ chế đang chạy:**

Không phải bảng % cố định — là 1 pool token (mỗi loại xuất hiện nhiều lần tuỳ trọng số), rút ngẫu nhiên 3 phần thưởng khác nhau không lặp loại đã có trong 3 lựa chọn đang hiện:
- `LEVEL_UP` ×2 token (nếu còn hero chưa max tier trong roster) — **không còn ai lên tier được thì thay bằng `ASCEND` ×2** (không có trong `game-concept.md` bản cũ, đã bỏ sót).
- `RELIC` ×2, `GENE_MUTATION` (`face`) ×2, `RUNE_IMBUE` (`rune`) ×1 — luôn có.
- `MAX_REROLL+1` (`reroll`) ×1 — chỉ khi `maxRerolls<4` (cap thật là 4, không phải "3 lần upgrade" như bản cũ ghi).
- `HP` (bonus maxHP) ×1 — luôn có, không có trong bảng cũ.
- Từ tier ≥2: thêm `RELIC`/`GENE_MUTATION`/`chaos` mỗi loại +1 token. Từ tier ≥3: thêm cả `curse` +1 token nữa.
- **`RECRUIT` KHÔNG tồn tại trong code** — đã xoá khỏi tài liệu, không phải reward type thật.

Mỗi wave có **1 lần reroll cả 3 lựa chọn phần thưởng** (van xả xui — người chơi không bị ép nhận reward lệch build).

**Gene Mutation**: `PART_REPLACE` (đổi 1 mặt thành part khác, mặt về lại Common) · `RUNE_IMBUE` (gắn 1 keyword vào 1 mặt) · `OVERCLOCK` (+50% value toàn die, làm tròn lên).

### Core Rules — Ascension (trần độ khó, 10 mức)

Xác nhận trực tiếp `src/data.js` (mảng `ASCENSION`): mỗi mức cộng dồn độ khó (HP địch, sát thương địch, số elite, v.v.), mở khoá sau khi hoàn thành Full Run lần đầu. Đây là van an toàn cho phép build mạnh dần qua các mùa mà không phá curve — broken build chỉ an toàn khi có trần Ascension đi kèm.

### Core Rules — Relic (thay cho "item")

44 relic hoạt động qua hệ hook (`modFace/modDmg/onKill/onShield/onHit/onTurnStart`), một số có active tốn Mana (hiển thị dạng "Thẻ Lunacia" ở đáy màn hình). Relic đổi **luật**, không chỉ cộng số — ví dụ `Infinite Die`: +2 Max Reroll và reroll không còn xoá undo history.

### Core Rules — 6 Boss, 9 vai trò địch

6 boss mỗi con 1 cơ chế riêng (Split / Thorns+Overdrive / Freeze-constrain / Summon / Mirror-copy-mặt-mạnh-nhất-người-chơi / 2-Phase), thứ tự random mỗi run (`BOSS_ORDER_12`/`BOSS_ORDER_20` xác nhận trong `data.js`). Địch thường chia 9 role: bruiser/assassin/tank/healer/poisoner/mage/summoner/kamikaze/buffer — assassin nhắm Axie yếu nhất, tank/frontmost ảnh hưởng targeting.

### Core Rules — Tiến trình dài hạn (meta, ngoài run)

Sưu tầm bộ phận (mở khoá thêm part cho pool), ghép Axie làm Lead Axie (vào trận giữ đúng 6 part đã chọn nhưng vẫn ở Common — mang theo bản sắc, không phải lợi thế chỉ số), độ thành thạo part (Mastery — không cộng chỉ số, chỉ mở biến thể hình ảnh khác), 1 currency duy nhất (Gene Shard), Lunacia Pass (track XP vĩnh viễn, không thời hạn, không nhánh trả tiền, thua vẫn nhận XP). Chi tiết đầy đủ: xem `design/gdd/economy-progression.md` và `design/gdd/bloodline-system.md`.

## Formulas

### 1. Encounter Budget (xác nhận trực tiếp `src/data.js` — hằng số `TUNE`)

```
budget(pw) = TUNE.base × TUNE.growth^min(pw, TUNE.knee) × TUNE.growth2^max(0, pw−TUNE.knee)
```

**Biến số** (giá trị thật trong code, KHÔNG dùng số lịch sử trong AUDIT_AND_SPEC_v1.md Phần C — đã được tune lại):

| Biến | Ký hiệu | Giá trị hiện tại | Ghi chú |
|---|---|---|---|
| Base budget | `TUNE.base` | 10.5 | |
| Growth trước knee | `TUNE.growth` | 1.150 | mỗi power-level (không phải wave index) |
| Growth sau knee | `TUNE.growth2` | **1.05** (sửa 2026-09-01, cũ 1.065) | chậm lại sau power-level 12 — Full Run đo bằng `sim.js` cho 3.6% (dưới mục tiêu 6%), sau khi giảm growth2 + eliteMult → 8.0% |
| Knee | `TUNE.knee` | 12 | power-level mà growth chuyển chế độ |
| Elite multiplier | `eliteMult` | **1.25** (sửa 2026-09-01, cũ 1.40) | nhân budget cho encounter elite — bản 1.40 làm wave 3 (elite đầu tiên) tụt còn 75% winrate trong khi mọi wave khác ≥88% |

**Xác nhận qua simulation thật** (`node tools/sim.js 500 mode=X asc=0`, không phải ước tính): Short Run 16.4%→19.8%, Full Run 3.6%→8.0%, wave 3 elite 75%→83-87%. PLAGUE archetype (poison) cũng cải thiện đáng kể (5-9%→7-19% winrate) chỉ nhờ fix này — không cần buff giá trị poison riêng ở thời điểm hiện tại. Chi tiết chẩn đoán đầy đủ (bao gồm phát hiện AI trong `tools/sim.js` bỏ qua poison trong logic finish-kill): xem lịch sử phiên làm việc 2026-09-01, chưa có file lưu riêng — nên chép lại thành ghi chú trong `docs/adoption-plan-2026-08-31.md` hoặc file balance log nếu cần tham chiếu lâu dài.

`budget` được suy từ **power-level** (số reward người chơi đã nhận), không từ chỉ số wave — để tự thích ứng cho cả Short (12 wave) và Full (20 wave) run, và cho cả trường hợp người chơi chọn event thay vì đánh trận.

**Output Range**: pw=0 → ~10.5 budget (wave đầu). pw=12 (knee) → ~10.5×1.15^12 ≈ 57. pw=20 → ~57×1.065^8 ≈ 94.
**Ví dụ**: pw=5 → 10.5×1.15^5 ≈ 21.1 điểm để mua monster template cho encounter đó.

```
count(pw) = max(2, min(pw≥14 ? 6 : 5, 2 + floor(pw/4)))
```
Số lượng địch trong encounter — cap 5 (hoặc 6 nếu pw≥14).

### 2. Ascension Difficulty Mods (`src/data.js`, hàm `ascMods`)

10 mức cộng dồn (không tuyến tính đơn giản — một số mức stack): +HP địch, +DMG địch, +elite, +HP boss, Weaken khởi đầu ngẫu nhiên, giảm số lựa chọn reward còn 2, thêm wave elite. Bảng đầy đủ: xem trực tiếp `src/data.js` mảng `ASCENSION` (là nguồn sự thật — không hardcode lại số ở đây để tránh lệch khi tune).

### 3. Reroll (xác nhận `src/engine.js` dòng 102, 149)

```
maxRerolls = 2 + bonusReroll(meta) + Σ(rerollUp trên die đã dùng trong lượt)
```
**Lưu ý quan trọng**: base reroll thực tế trong code là **2**, KHÔNG phải 1 như `AUDIT_AND_SPEC_v1.md` A2.4 từng đề xuất — đã được tune lại từ lúc đó. Bất kỳ tài liệu nào (kể cả `PLAYER_GAME_GUIDE_v1.md`) ghi "base 1 reroll" cần sửa theo số này.

### 4. Lunacia Pass XP

```
XP = 30 (tham gia) + 10×wave_vượt_qua + 30×Elite + 60×Boss + 150×(nếu thắng) + 25×Ascension + 40×(nếu Full Run)
XP_cần_cho_level(lv) = 45 + 22×(lv−1)
```
**Output Range**: tổng 30 level ≈ 10.900 XP ≈ 40-45 run. Run đầu tiên dù thua vẫn lên Level 1-2.
**Ví dụ**: thắng 1 Short Run (12 wave, 1 elite, 1 boss, Ascension 0) = 30 + 120 + 30 + 60 + 150 + 0 + 0 = 390 XP.

## Edge Cases

- **Undo boundary**: undo tự do trong lượt, nhưng `s.undo=[]` bị xoá khi bấm Reroll (trừ khi có relic `safeReroll`, ví dụ `Infinite Die`) hoặc khi bắt đầu lượt mới. Không cho phép undo qua một lần reroll trong điều kiện thường — nếu cho phép, save-scumming vô hạn sẽ phá game.
- **Ally summon giữa lượt**: nếu unit được triệu hồi (`summon`) mà chưa roll die, đọc `u.die[u.rolled]` với `u.rolled=-1` sẽ crash (đã ghi nhận trong QA log là bug đã sửa) — mọi code đọc mặt die phải guard `rolled≥0` trước khi đọc.
- **Cap ally slot**: `src/engine.js` dòng 396 giới hạn tối đa 4 ally-token đang sống cùng lúc (`s.party.filter(x=>x.token&&x.hp>0).length<4`) trước khi cho summon thêm — summon vượt cap bị bỏ qua lặng lẽ.
- **Hết máu giữa trận vs. hết trận**: HP không carry-over giữa các trận — thua hoặc thắng đều hồi đầy máu + hồi sinh Axie chết trước wave kế tiếp. Độ khó nằm ở từng trận, không phải hao mòn tích luỹ.
- **Poison/debuff không được scale linear theo encounter budget** — đã phát hiện qua simulation: scale linear tạo "wall bất khả thi" ở wave có mật độ AoE-poison cao (Plague Mother wave 15 từng cho winrate 0% trước khi sửa). Quy tắc: status-type face scale theo `s^0.50`, buff/debuff theo `s^0.45` — không được scale như damage một lần.
- **Boss thorns/summon không được scale linear** — cùng lý do trên, đã fix về `thorns: 0.09×budget`, summon giới hạn nhịp (mỗi 3 lượt) + hard cap.
- **Hai unit trùng ưu tiên hành động cùng lúc**: resolve theo thứ tự vị trí trong đội hình, không có tiebreak ngẫu nhiên.

## Dependencies

| Hệ thống | Quan hệ | File GDD |
|---|---|---|
| Economy & Progression | game-concept định nghĩa currency/pass ở mức tổng quan; chi tiết công thức, sink/faucet, monetization | `design/gdd/economy-progression.md` |
| Bloodline (part → face mapping, content pipeline) | game-concept dùng 6-part vocabulary; bloodline-system mở rộng thành 192 part thật từ Axie Origins | `design/gdd/bloodline-system.md` |
| Part Tier System | tiering/cân bằng chi tiết cho từng part, đầu vào cho hệ rarity ở trên | `design/gdd/part-tier-system.md` |
| Axie Body Parts DB | database part đầy đủ theo class | `design/gdd/axie-body-parts.md` |
| Build Spec (Economy Phase 1) | hợp đồng implementation cho hệ economy/bloodline | `design/gdd/build-spec.md` |
| Combo Decision Memo (Declare/BLOODCHAIN) | **Đã bị gác lại** — xem `bloodline-system.md` v1.2, không nằm trong scope build hiện tại. Giữ trong `design/gdd/combo-decision-memo.md` chỉ để tham chiếu nếu quyết định được đảo ngược. | `design/gdd/combo-decision-memo.md` |
| UI/UX | UI_DESIGN_SYSTEM, UIUX_AUDIT, implementation brief — điều khiển cách các luật ở trên hiển thị | `docs/axiedice-source/uiux/` |

**Phụ thuộc ngược**: mọi GDD trên đều tham chiếu ngược lại game-concept.md làm nguồn sự thật cho core loop, class/tier, rarity 5 bậc, và cấu trúc run — nếu sửa các con số ở đây, phải rà soát lại các file trên.

## Tuning Knobs

| Knob | Giá trị an toàn | Ảnh hưởng nếu chỉnh sai |
|---|---|---|
| `TUNE.base` (10.5) | 8–13 | Quá thấp → wave đầu vô nghĩa; quá cao → chết sớm |
| `TUNE.growth` / `TUNE.growth2` (1.150 / 1.065) | growth > growth2 luôn đúng | Đảo ngược → power creep người chơi vượt curve địch, boss cuối vô nghĩa |
| `TUNE.knee` (12) | 8–16 | Đặt quá sớm → khựng power giữa game; quá muộn → cliff không được làm mềm kịp |
| `eliteMult` (1.40) | 1.2–1.6 | Quá cao → elite trở thành mini-boss ngoài dự kiến |
| `maxRerolls` base (2) | 1–3 | 1 quá gắt cho Short Run mới; ≥4 làm variance-control quá mạnh, giảm giá trị quyết định |
| Reward pool token count (xem §Core Rules — Reward pool đã sửa 2026-09-01) | `LEVEL_UP`/`ASCEND` giữ ×2, không vượt số token loại `RELIC`+`GENE_MUTATION` cộng lại | Tăng token `LEVEL_UP`/`ASCEND` quá cao làm build hội tụ về ít archetype hơn |
| `RESONANCE.mult` (1.15, hạ từ đề xuất ban đầu 1.25 sau khi đo đa-seed, xem `docs/balance-log.md`) | 1.15–1.40 | Đội hình mono-type liền kề trở nên quá mạnh nếu vượt trần |
| Ascension mods (10 mức, `ascMods`) | không đổi thứ tự, chỉ đổi độ dốc | Đảo thứ tự làm A1 khó hơn A5 — phá kỳ vọng người chơi |
| Status-effect scale exponent (poison/debuff `^0.45–0.50`) | không được đưa về `^1` (linear) | Linear → wall bất khả thi đã xác nhận qua sim (xem Edge Cases) |

**Mọi thay đổi giá trị ship phải chạy qua `tools/sim.js` (hoặc `src/engine.js` headless), không chốt bằng đọc spec** — 3 bug thiết kế nghiêm trọng nhất trong lịch sử dự án (poison wall, cliff wave 15, boss death-spiral) chỉ phát hiện được qua simulation, không thấy được khi đọc code/spec tĩnh.

## Acceptance Criteria

- **GIVEN** một trận đấu bắt đầu, **WHEN** cả hai phe roll dice, **THEN** mặt roll ra của địch hiển thị công khai làm intent trước khi người chơi hành động (0% thông tin bị giấu).
- **GIVEN** người chơi đã dùng hết reroll trong lượt, **WHEN** họ cố reroll thêm, **THEN** hành động bị chặn, không crash (`src/engine.js` dòng 207: `if(s.rerolls<=0) return false`).
- **GIVEN** một unit chưa roll die (`rolled=-1`), **WHEN** engine cố đọc mặt hiện tại của nó, **THEN** không được throw — phải guard trước khi đọc (regression trap đã ghi nhận, xem `docs/review-2026-08-31.md` mục QA).
- **GIVEN** một trận kết thúc (thắng hoặc thua), **WHEN** wave tiếp theo bắt đầu, **THEN** toàn bộ party về đầy HP và mọi Axie đã chết được hồi sinh.
- **GIVEN** Short Run (12 wave), **WHEN** người chơi chơi tới wave 4/8/12, **THEN** encounter đó là boss; wave 3/6/10 là elite — khớp `RUN_LEN.short` trong `data.js`.
- **GIVEN** một mặt xúc xắc đạt ≥2 Legendary trên cùng một die, **WHEN** die đó được hiển thị, **THEN** nó có style Golden Die; nếu có ≥1 Mythic thì Cosmic Die.
- **GIVEN** người chơi bấm Reroll, **WHEN** không có relic `safeReroll` đang active, **THEN** undo stack bị xoá ngay sau đó.
- **GIVEN** hai wave liên tiếp trong khoảng power-level ≤12, **WHEN** so sánh budget hai wave đó, **THEN** tỷ lệ tăng phải khớp `TUNE.growth=1.150` (không phải `growth2`).
- **GIVEN** guide/GDD nào mô tả cơ chế "Gọi mặt"/Declare/BLOODCHAIN như tính năng đang chạy, **WHEN** đối chiếu với `src/engine.js`, **THEN** phải fail — cơ chế này đã bị gác lại chính thức và không được mô tả như đã ship (xem Dependencies).

## Open Questions

- `part-tier-system.md`/`axie-body-parts.md` mô tả kế hoạch mở rộng lên 192 part thật từ Axie Origins (Phương án Bloodline) — game-concept này mô tả vocabulary 6-part hiện tại đang chạy trong `data.js`. Khi Bloodline ship, phần "Die & Part vocabulary" ở trên cần cập nhật lại số lượng part thật.
- Cơ chế Declare/BLOODCHAIN (gác lại) có được xem xét lại không, và nếu có thì theo Option D của `combo-decision-memo.md` hay phương án khác? Cần người có thẩm quyền quyết định (xem `docs/review-2026-08-31.md` mục hành động #1).
- `economy-progression.md §1.2` vẫn đánh dấu 16 quyết định D1-D16 là "cần duyệt" trong khi `build-spec.md` nói đã duyệt — cần đồng bộ trước khi coi các con số economy trong game-concept này (Gene Shard, Lunacia Pass) là final.
