Trạng thái: ĐỀ XUẤT — chờ Liam review

> **QUYẾT ĐỊNH LIAM SAU REVIEW (11/10):** Q1 BỎ `tithepurse` · Q2 trần nhân G tính theo từng Axie, chỉ áp mặt sát
> thương (đúng code `oc`) · Q3 pact "mỗi PACT một lần/run" (không phải mỗi nhóm) · Q4 `linkstone` dùng điều kiện kề
> nhau cố định · Q5 giữ −Max HP ở event `gamble_legend`/`bet_small` · Q6 **KHÔNG** thêm trần mềm cho sát thương cộng
> thẳng. **Câu 15 (11/10): CÓ** — thẻ thưởng `reroll`, shop `reroll`, event `bless_reroll` vào loại trừ với `twinfates`.
> **Liam 11/10: ĐỒNG Ý** đổi `ascend`/`forge` trên MẶT SÁT THƯƠNG từ nhân dồn (oc, 1,25ⁿ) sang cộng vào ô nhân G của
> từng Axie (1 + 0,25n, trần ×2,5) — đổi hành vi reward hiện có. **Câu 15 phần `curse`: CÓ** (cũng loại khi giữ
> `twinfates`) · **Câu 16: CÓ** — mặt Shield/Heal/Mana vẫn nhân `oc` dồn nhưng chặn ×2,0.
>
> ## 🔒 BỘ RELIC ĐÃ KHOÁ VỀ THIẾT KẾ (Liam, 11/10). Các con số (+N, trần, tỉ lệ) vẫn là số đoán đầu, CHỐT SAU SIM (§6).

> **QUYẾT ĐỊNH LIAM (11/10, §7 câu 1–8) — ĐỒNG Ý CẢ 8:** (1) Blood Pact là rework thứ 19, bỏ −Max HP · (2) hạ 6
> relic rework Rare → Common · (3) `ascend` + `forge` vào ô nhân G, tổng trần ×2,5 · (4) FERAL ×1,6 và LINK ×1,15
> nằm ngoài ô nhân, class upgrader không nâng · (5) tweak xúc xắc kiểu click-click, 2/lượt (nhờ ui-programmer ước
> lượng) · (6) pact chiếm ô passive, mỗi nhóm drawback 1 lần/run · (7) kill do relic gây chỉ kích relic 1 tầng ·
> (8) duo chỉ đếm tag của relic đang giữ. **Câu 9–14 (11/10):** (9) pity Legendary: chưa, chờ sim · (10) giữ 134 ·
> (11) tiền trong run là Gene Shard, không thêm loại mới · (12) giữ `fortuneledger`, thêm nút reroll phần thưởng ·
> (13) `twinfates` vào danh sách "không đưa ra khi đang giữ" (cùng relic cộng reroll) · (14) Liam đã review.
> **LIAM DUYỆT BỘ RELIC (11/10)** — yêu cầu game-designer audit/review lại thêm một lần trước khi khoá cho code.

> **SỬA SAU REVIEW 11/10 (bản khoá).** Áp 22 phát hiện của `relic-set-v2-review.md` + Q1–Q6 của Liam. Trạng thái từng
> phát hiện nằm ở đầu file review. Các đoạn đã sửa có nhãn "SỬA SAU REVIEW 11/10". Quyết định số (6) "mỗi nhóm drawback 1 lần/run"
> và (10) "giữ 134" ở trên **bị thay**: pact giờ là "mỗi PACT một lần/run" (Q3, §4.4), tổng còn **133** vì bỏ `tithepurse` (Q1,
> không thay thế). Số mới: **133** (117 passive + 16 active) · mới **44** · rarity C 26 · R 31 · E 51 · L 25 · layer economy 3.
> Còn mở: nguồn reroll không phải relic (thẻ `reroll`, shop `reroll`, event `bless_reroll`) có vào loại trừ với `twinfates` không
> (§7 câu 15, chưa áp).

# Relic set v2 (bước 3a của relic redesign)

Tác giả: game-designer · 2026-10-10. Chưa có code, không sửa file nào khác. Ascension là bước 3b, ở đây chỉ ghi chỗ relic chạm Ascension (§8).

## 0. Đọc nhanh

Bộ relic mới theo đúng 12 quyết định Liam đã chốt ở đầu `relic-audit-research.md`. Tóm tắt:

| Mục | Số |
|---|---|
| **Tổng** (SỬA SAU REVIEW 11/10) | **133** (117 passive + 16 active). Bỏ `tithepurse`, không thay |
| Mới hoàn toàn | **44** (12 duo, 6 class-up, 8 pact, 6 dice, 5 positional, 3 scaling, 3 economy, 1 payoff) |
| Giữ nguyên (chỉ sửa tag/ô nhân nếu ghi) | 68 (52 passive + 16 active, trong đó 3 active được BUFF) |
| Rework | 19 (18 từ audit + `bloodpact`, §7 câu 1) |
| Merge | 7 relic cũ → 4 kết quả (2 id mới/giữ: `festermark`, `infinitedie`; 2 relic hấp thụ: `scalecrown`, `broodpouch`); 6 id biến mất |
| Cắt | 0 |
| Rarity | C 26 · R 31 · E 51 · L 25 (không cần bậc Mythic) |
| Layer | enabler 32 · payoff 23 · scaling 7 · engine 14 · pact 9 · duo 12 · dice 6 · positional 5 · class-up 6 · economy 3 · active 16 |

E hơi nặng (51) vì Epic chứa cả 6 pact boss-only và 6 class upgrader/6 duo có gating. Pool Epic mà offer thường nhìn thấy (trừ pact) là 45.

Số relic theo tag (relic hai tag đếm hai lần): exec 11 · shield 17 · pierce 11 · mana 16 · thorns 12 · summon 9 · growth 11 · poison 11 · crit 9 · aoe 9 · burn 9 · uni 25 · class 6 (SỬA SAU REVIEW 11/10: uni 26 → 25 vì bỏ `tithepurse`).

**Những luật chịu tải (đọc hết §3–§5 sau khi đọc phần này):**
1. 8 ô passive + 3 ô active; hết ô thì bán 50% đổi.
2. 1 ô G (nhân toàn cục) + 2 ô A (nhân theo trục); cộng trong trục, nhân giữa trục; tổng trục G **tính theo từng Axie, chỉ mặt sát thương**, chặn ×2.5 (gồm `ascend`/`forge` của Axie đó). Sát thương cộng thẳng **không có trần** (Liam, Q6). (SỬA SAU REVIEW 11/10)
3. Damage do relic gây: không kích HIT/DMG/crit, độ sâu KILL 1.
4. Offer: chọn rarity theo trọng số rồi chọn relic; 1 trong 3 thẻ nghiêng theo tag đang giữ; duo cần 2 tag; deterministic theo seed.
5. Pact chỉ ở boss, chọn 1/3 (mỗi nhóm drawback Reroll/Dice/Mana một cái khi còn đủ nhóm), mỗi PACT một lần/run, drawback không đụng HP. (SỬA SAU REVIEW 11/10)
6. 8 hook mới, một lần bump `RULES_VERSION`.

**Khác audit §5.3 và lý do:** audit nhắm 28 Common/42 Rare/38 Epic/22 Legendary; bản này ra 26/31/51/25 vì (a) 7 merge lấy mất Rare, (b) pact và class upgrader đều Epic/Legendary, (c) không có thêm Common ngoài 6 relic nhỏ cố ý đơn giản (đã bỏ `tithepurse`). Mình thấy lệch này chấp nhận được; Liam muốn Common nhiều hơn thì hạ thêm rework (§7 câu 2).

**Chưa kiểm trên code (lấy từ audit hoặc suy luận, cần xác nhận lúc làm):** boss có miễn nhiễm stun / chết ngay không (liên quan `a_freeze`+`hollowchalice`, `coupmark`, `apexferal`); số dòng chèn hook; cách `Unit` biết slot trong đội (relic positional cần); định nghĩa "kề" của LINK; kill do tick/relic có kích `on_kill` hiện nay hay không (§3.5 giả định kích với kill do tick); tên đồng tiền in-run; UI reorder đội ở Map chưa có. Không chạy sim nào, không có số winrate mới.

## 1. Bảng pool cuối (133 relic)

**Cách đọc.** Rarity giữ 4 bậc đang dùng (C Common, R Rare, E Epic, L Legendary). Mình **không cần bậc Mythic**: "engine" là tầng chức năng (layer), nằm ở Legendary, và pact là layer riêng. Thêm bậc mới sẽ đụng giá shop 45/75/120/180, màu rarity UI và code `pick_relic`, mà không có lợi gì thêm.

Tag: archetype `exec shield pierce mana thorns summon growth poison crit aoe burn`, class `plant beast aqua reptile bug bird`, và `uni` (relic chung, không thuộc kiểu chơi nào). Tối đa 2 tag/relic.
Layer: enabler, payoff, scaling, engine, pact, duo, dice, positional, class-up, economy, active.
Trigger: BUILD (`mod_face` lúc dựng die) · T-START · ROLL-END · DMG (`mod_dmg`) · HIT · KILL · SHIELD · THORNS · TAKEN · TICK (status tick) · AGG (field aggregate) · ACT (active, tốn Mana) · **NEW HOOK H1..H8** (§5) · **NEW FIELD** (field aggregate mới, không phải hook).
Slot nhân: **G** = ô nhân toàn cục (tối đa 1 relic), **A** = ô nhân archetype (tối đa 2 relic), `-` = không chiếm ô (§3).
Kết quả tổng: 52 giữ nguyên + 19 rework + 2 kết quả merge + 44 mới + 16 active = **133** (117 passive + 16 active). (SỬA SAU REVIEW 11/10: từ 134, bỏ `tithepurse`.)

### 1.1 Passive giữ nguyên (52). Chỉ sửa tag/ô nhân nếu ghi

| id | Tên | R | Tag | Layer | Trigger | Effect | Slot |
|---|---|---|---|---|---|---|---|
| `pierceall` | Piercing Horn (Sừng xuyên) | C | pierce | enabler | BUILD | Mặt Horn có Pierce | - |
| `bloodmouth` | Bloodmouth (Miệng khát máu) | C | uni | enabler | BUILD | Mặt Mouth có Lifesteal, +2 HP. Sửa tag exec thành uni | - |
| `gorehook` | Gorehook (Móc xé) | C | exec | enabler | BUILD | Mặt dmg Horn/Tail có Execute | - |
| `broodpouch` | Brood Pouch (Túi trứng) | C | summon | enabler | AGG, T-START | Đầu trận 1 Egg. **Nhận luật swarmnest:** đầu lượt 3, nếu còn dưới 3 Egg thì thêm 1 Egg | - |
| `tidalbrand` | Tidalbrand (Dấu thủy triều) | C | mana | enabler | BUILD, T-START | Mặt Ears +1 Reroll; +1 Reroll đầu trận | - |
| `predatorpoise` | Predator's Poise (Thế thợ săn) | C | crit | enabler | AGG | Crit đang hiện sống qua reroll | - |
| `seedling` | Seedling Core (Lõi mầm) | C | growth | enabler | AGG | Mọi mặt +1 growth/lượt | - |
| `lastwall` | Last Wall (Bức tường cuối) | C | shield | enabler | T-START | Axie yếu nhất có Undying | - |
| `scentofblood` | Scent of Blood (Mùi máu) | R | exec | payoff | DMG | Địch dưới 50% HP nhận +4 mỗi đòn | - |
| `bloomscale` | Bloomscale (Vảy nở) | R | growth | enabler | BUILD, AGG | Mặt Back/Eyes có Growth, Growth +4 | - |
| `deathmark` | Death Mark (Dấu tử thần) | R | exec | scaling | KILL | Mỗi kill: mọi mặt dmg +1 hết trận, +2 HP | - |
| `bloodthorn` | Bloodthorn (Gai máu) | R | thorns | enabler | TAKEN | Bị đánh: hồi ⅓ Thorns; Shield +1 | - |
| `marrowdrill` | Marrow Drill (Khoan tủy) | R | pierce | enabler | BUILD | Mặt Pierce dmg gắn Weaken 2 | - |
| `wildfire` | Wildfire (Cháy rừng) | R | burn | enabler | BUILD, TICK | Burn giảm 1/lượt thay vì nửa; Horn gắn Burn 6 | - |
| `rotmouth` | Rotmouth (Miệng thối) | R | poison | enabler | BUILD | Mặt Mouth dmg gắn Poison 2 | - |
| `broodmother` | Broodmother (Mẹ đàn) | R | summon | enabler | KILL | Mỗi kill nở 1 Egg; Egg +1 dmg | - |
| `heartwood` | Heartwood (Lõi gỗ) | R | growth | scaling | AGG | Từ lượt 2 mọi mặt +2 growth/lượt | - |
| `bloodhymn` | Blood Hymn (Thánh ca máu) | R | crit | payoff | HIT | Crit +2 Mana | - |
| `squallmark` | Squallmark (Dấu bão) | R | aoe | enabler | BUILD | Mặt Eyes heal/debuff thành AoE | - |
| `holyfont` | Sacred Font (Suối thánh) | R | shield | enabler | AGG | Heal cũng cho Shield bằng số hồi | - |
| `ember` | Ember (Than hồng) | R | burn | enabler | HIT | Đòn ≥4 dmg gắn Burn 2 | - |
| `hivemind` | Hive Mind (Trí đàn) | R | summon | scaling | AGG | +1 dmg mọi mặt mỗi Egg đang sống | - |
| `growthcore` | Growth Core (Lõi tăng trưởng) | E | growth | enabler | BUILD | Mặt dmg có Growth, +1 dmg, +2 HP | - |
| `thousandcuts` | Thousand Cuts (Ngàn nhát) | E | pierce | payoff | BUILD | Pierce đánh 2 lần, mỗi lần nửa +2 | - |
| `pandemic` | Pandemic (Đại dịch) | E | poison | payoff | KILL | Địch chết lan nửa Poison sang địch khác | - |
| `shatterpoint` | Shatterpoint (Điểm vỡ) | E | crit | payoff | AGG | Crit xuyên Shield, +5 | - |
| `retributor` | Retributor (Kẻ báo ứng) | E | thorns | payoff | THORNS | Thorns của Axie có Shield lan ⅓ sang hàng xóm | - |
| `keeneye` | Keen Eye (Mắt tinh) | E | crit | payoff | ROLL-SETTLED (H1) | Chưa ai crit thì đòn đầu crit; crit +4. SỬA SAU REVIEW 11/10: chuyển từ ROLL-END sang `on_roll_settled` để tính lại sau mỗi reroll (§5 H1) | - |
| `pyroclasm` | Pyroclasm (Bùng cháy) | E | burn | payoff | TICK | Burn lan nửa sang hàng xóm; Horn +1 | - |
| `windlash` | Windlash (Roi gió) | E | aoe | enabler | BUILD | Mouth dmg có Cleave, +1 | - |
| `deathspiral` | Death Spiral (Xoáy tử) | E | exec | payoff | HIT | Lần đầu địch xuống dưới 50% HP: 7 dmg xuyên | - |
| `bastionplate` | Bastion Plate (Giáp pháo đài) | E | shield | payoff | SHIELD | Tạo Shield: 50% thành dmg lên 1 địch | - |
| `glassspine` | Glass Spine (Gai thủy tinh) | E | thorns, shield | payoff | SHIELD | Axie được Shield có Thorns ≥4 | - |
| `manaspring` | Mana Spring (Suối mana) | E | mana | enabler | T-START | +2 Mana/lượt | - |
| `chainreact` | Chain Reaction (Phản ứng dây chuyền) | E | aoe | payoff | KILL | Địch chết nổ 5 dmg lên địch còn lại (không kích chuỗi, §3.5) | - |
| `hearthcore` | Hearthcore (Lõi lò) | E | burn | payoff | TICK | Burn tick lần 2 bằng 70% (= +70% trên trục burn) | A |
| `quickenroot` | Quickenroot (Rễ nhanh) | E | growth | scaling | ROLL-END (chỉ roll đầu lượt) | Từ lượt 2 mặt đang roll +1 vĩnh viễn trong trận. SỬA SAU REVIEW 11/10: chỉ chạy một lần mỗi lượt sau roll đầu, KHÔNG chạy lại khi reroll (§5 H1) | - |
| `plaguelord` | Plague Lord (Chúa dịch) | L | poison | engine | TICK, BUILD | Poison không giảm; mặt Poison +1 | - |
| `echostone` | Echo Stone (Đá vọng) | L | uni | engine | AGG | Mặt đầu mỗi lượt kích 2 lần. Sửa tag crit thành uni | - |
| `venomengine` | Venom Engine (Động cơ độc) | L | poison | engine | TICK | Poison tick 2 lần/lượt (= +100% trên trục poison) | A |
| `worldpiercer` | World Piercer (Kẻ xuyên thế giới) | L | pierce | engine | BUILD, AGG | Mọi mặt dmg có Pierce; Pierce không dính Thorns | - |
| `hivequeen` | Hive Queen (Nữ hoàng đàn) | L | summon | engine | AGG | Egg thừa hưởng relic sửa die; giữ tối đa 6 Egg | - |
| `conduitcrown` | Conduit Crown (Vương miện dẫn) | L | mana | engine | AGG | Active dùng 2 lần/lượt (chỉ active rarity ≤ E); +2 Mana/lượt | - |
| `manaflood` | Mana Flood (Lũ mana) | L | mana | payoff | end turn | Mana dư cuối lượt nổ vào mọi địch; +3 Mana đầu trận | - |
| `worldtree` | World Tree (Cây thế giới) | L | growth | engine | combat end | Giữ nửa growth qua các trận, tối đa +3/mặt | - |
| `solarcore` | Solar Core (Lõi mặt trời) | L | burn | engine | TICK | Burn ×2 (= +100% trên trục burn) | A |
| `mirrorshell` | Mirror Shell (Vỏ gương) | L | thorns | payoff | THORNS | Thorns ×2 (= +100% trên trục thorns) | A |
| `stormcall` | Storm Call (Gọi bão) | L | aoe | engine | BUILD | Mặt dmg đơn mục tiêu có Cleave | - |
| `dawnlance` | Dawn Lance (Giáo bình minh) | L | uni | payoff | DMG | Đòn vào địch `not is_wounded(tgt)` ×1.9 (trục "opener"; §3.5, SỬA SAU REVIEW 11/10). Sửa tag pierce thành uni | A |
| `ironmaiden` | Iron Maiden (Thiếu nữ sắt) | L | thorns | payoff | T-START | Địch nhiều HP nhất nhận dmg = Thorns cao nhất (≤7) | - |
| `apexferal` | Apex Feral (Hoang thú tối thượng) | L | exec | engine | BUILD, HIT | Mọi mặt dmg có Execute; địch ≤15% HP chết ngay | - |
| `scalecrown` | Scale Crown (Vương miện vảy) | L | thorns | engine | T-START, THORNS | Cả đội nhận SCALES (Thorns 2 + Poison 1). **Nhận luật spines:** Thorns sàn 2 cho cả đội kể cả non-Reptile | - |

### 1.2 Rework (19): CŨ → MỚI

18 rework từ audit, cộng **Blood Pact** (bị buộc đổi vì quyết định 5: drawback không được đụng HP). Điểm chung: mỗi relic thêm một trigger hoặc một điều kiện để người chơi chơi khác đi, không còn là cộng số. Sáu relic Rare được hạ xuống Common (cột R là bậc MỚI) vì pool cũ chỉ có 16 Common mà offer trận thường lại lấy từ Common.

| id | Tên | R | Tag | Layer | Trigger | CŨ → MỚI | Slot |
|---|---|---|---|---|---|---|---|
| `claw` | Razor Claw (Vuốt dao cạo) | C | uni | enabler | ROLL-END + **NEW HOOK H1** | CŨ mọi mặt dmg +1 → MỚI mặt dmg có giá trị thấp nhất của đội mỗi lượt +4 (tính lại sau mỗi reroll; hòa thì Axie slot nhỏ hơn). Sửa tag exec thành uni | - |
| `carapace` | Stone Carapace (Mai đá) | C | shield | enabler | **NEW HOOK H2** | CŨ Shield/Heal +2 → MỚI mặt Shield đầu tiên mỗi lượt +5 Shield | - |
| `cleaveall` | Sweeping Tail (Đuôi quét) | C | aoe | enabler | BUILD | CŨ Cleave/AoE +2 → MỚI mặt Cleave/AoE +1 dmg cho mỗi địch còn sống (3 địch = +3) | - |
| `barbedhide` | Barbed Hide (Da gai) | C | thorns | enabler | **NEW HOOK H2** | CŨ Thorns +1, Shield +1 → MỚI mỗi mặt Shield dùng: Axie đó +1 Thorns đến hết lượt (cộng dồn tối đa +3) | - |
| `ear` | Keen Ears (Tai thính) | C | mana | enabler | BUILD + **NEW HOOK H4** | CŨ mặt Mana +1 → MỚI mặt Mana +1; lần đầu mỗi lượt dùng active, hoàn 1 Mana (hạ R→C) | - |
| `gustwing` | Gustwing (Cánh gió) | C | aoe | payoff | HIT | CŨ Cleave 75% → MỚI Cleave 75%; mục tiêu phụ cũng nhận status mặt chính gắn (Poison/Burn/Weaken). Hạ R→C | - |
| `heart` | Lunacia Heart (Tim Lunacia) | C | shield | enabler | T-START | CŨ +12 Max HP → MỚI +8 Max HP cả đội; đầu lượt Axie dưới 30% HP nhận 6 Shield. Hạ R→C | - |
| `talonedge` | Talon Edge (Lưỡi móng) | C | pierce | enabler | HIT | CŨ Pierce +2, Horn +1 → MỚI Pierce +2; Pierce trúng địch có Shield thì phá hết Shield còn lại của địch đó. Hạ R→C | - |
| `eggshell` | Eggshell Ward (Vỏ trứng hộ) | C | summon | enabler | **NEW HOOK H3** | CŨ Egg +2 Shield/lượt → MỚI cuối lượt, mỗi Egg còn sống cho Axie kề nó 3 Shield. Hạ R→C | - |
| `luckycharm` | Lucky Scale (Vảy may mắn) | C | crit | enabler | HIT | CŨ +35% crit → MỚI +20% crit; mỗi đòn dmg không crit của Axie đó +10% crit cho tới khi crit (reset khi crit/hết trận). Hạ R→C | - |
| `apexbrood` | Apex Brood (Đàn tối thượng) | E | summon | payoff | BUILD (Egg) | CŨ Egg +8 HP +2 dmg → MỚI Egg mới nở sao chép mặt dmg cao nhất của đội vào 1 slot; Egg +2 dmg | - |
| `regrow` | Regrowth Bud (Chồi tái sinh) | E | growth, shield | enabler | **NEW HOOK H2** | CŨ Regen 2 + 2 HP → MỚI mỗi mặt Shield/Heal dùng: Axie đó +1 growth trong trận (tối đa +4) | - |
| `fang` | Venom Fang (Nanh độc) | E | poison | enabler | HIT | CŨ mặt poison +1 stack → MỚI mặt Poison +1 stack; nếu mục tiêu đã có ≥5 Poison thì +2 nữa | - |
| `cullingorder` | Culling Order (Lệnh tàn sát) | E | exec | payoff | KILL | CŨ kill hồi 4 + 4 Shield → MỚI mỗi kill hoàn 1 Reroll (tối đa 2/lượt) và mặt dmg kế tiếp +3 | - |
| `hollowbone` | Hollow Bone (Xương rỗng) | E | pierce | payoff | **NEW HOOK H2** | CŨ Pierce +3, bỏ qua Thorns → MỚI Pierce bỏ qua Thorns; mặt Pierce đầu mỗi lượt gây thêm 1 đòn 50% lên địch HP thấp nhất (relic dmg, không kích relic) | - |
| `soulforge` | Soul Forge (Lò linh hồn) | L | shield | engine | AGG | CŨ Shield không trần, −30% dmg nhận, Shield +2 → MỚI Shield không trần; mỗi 10 Shield trên một Axie: mặt dmg của Axie đó +1 (tối đa +6). Bỏ `dr` | - |
| `apexpredator` | Apex Predator (Thợ săn tối thượng) | L | crit | engine | HIT | CŨ +35% crit và crit ×3 → MỚI crit ×3 (thay ×2), không cộng chance; mỗi crit hoàn 1 Reroll (tối đa 2/lượt) | A |
| `ancientgene` | Ancient Gene (Gene cổ đại) | L | uni, growth | engine | BUILD | CŨ mọi mặt ×1.3 (tag growth sai) → MỚI mọi mặt dmg +30% và chiếm ô G; mọi mặt đã có Growth +1 growth | G |
| `bloodpact` | Blood Pact (Khế ước máu) | L | uni | pact | BUILD, AGG | CŨ −15% Max HP, mọi dmg ×1.6 → MỚI mọi dmg +60% (ô G); Reroll max −2 (sàn 0). Chỉ ra ở boss. Sửa tag exec thành uni | G |

### 1.3 Merge: 7 relic cũ → 4 kết quả

| Relic cũ | → Kết quả | Ghi chú |
|---|---|---|
| `rotbite` (C) + `tinderbox` (C) + `openwound` (R) | `festermark` (bảng 1.4) | Ba relic cùng luật "địch có status nhận thêm". Mất phần ×1.3 của openwound (trục nhân), còn lại số phẳng |
| `voidgene` (R) + `infinitedie` (E) | `infinitedie` (bảng 1.4) | voidgene gần như là bản nhỏ của infinitedie |
| `spines` (R) | `scalecrown` (bảng 1.1) | scalecrown đã cho Thorns 2 cả đội, spines luôn chết khi có nó |
| `swarmnest` (E) | `broodpouch` (bảng 1.1) | Cùng luật khác số: gộp thành "1 Egg đầu trận + 1 Egg ở lượt 3" |

Id biến mất: `rotbite tinderbox openwound voidgene spines swarmnest` (6). 94 − 6 + `festermark` = 89 relic có gốc từ pool cũ.

### 1.4 Kết quả merge (2)

| id | Tên | R | Tag | Layer | Trigger | Effect | Slot |
|---|---|---|---|---|---|---|---|
| `festermark` | Festering Mark (Dấu mưng mủ) | R | poison, burn | payoff | DMG | Địch có Poison hoặc Burn nhận +2 mỗi đòn; có cả hai thì +4. Số phẳng, không nhân | - |
| `infinitedie` | Infinite Die (Xúc xắc vô hạn) | E | mana | enabler | BUILD, T-START | +2 Reroll max, +1 Mana lượt 1, undo sống qua reroll | - |

### 1.5 Relic MỚI (44) (SỬA SAU REVIEW 11/10: từ 45, bỏ `tithepurse`)

**Duo (12): cần có đủ 2 tag trong relic đang giữ (§4.3)**

| id | Tên | R | Tag | Layer | Trigger | Effect | Slot |
|---|---|---|---|---|---|---|---|
| `fumeblossom` | Fumeblossom (Hoa khói độc) | L | poison, burn | duo | TICK | Mỗi Burn tick lên một địch gắn thêm 1 Poison; mỗi Poison tick lên địch đang Burn cộng 1 Burn. Hai trục nuôi nhau. Giới hạn: mỗi chiều tối đa 1 lần/địch/lượt | - |
| `sporegale` | Spore Gale (Gió bào tử) | R | poison, aoe | duo | HIT, TICK | Mặt Cleave/AoE gắn 1 Poison lên mọi mục tiêu phụ; Poison lan 1 stack sang hàng xóm mỗi tick (bật `poisonSpread` có sẵn) | - |
| `firestormveil` | Firestorm Veil (Màn bão lửa) | E | burn, aoe | duo | HIT | Mặt AoE gắn Burn 2 lên mọi địch trúng; địch đang Burn nhận +1 mỗi đòn AoE | - |
| `spikedbulwark` | Spiked Bulwark (Thành gai) | R | shield, thorns | duo | SHIELD | Axie nhận Shield: Thorns của nó +1 cho mỗi 5 Shield đang có (tối đa +4) đến hết lượt | - |
| `aegiscapacitor` | Aegis Capacitor (Tụ khiên) | E | shield, mana | duo | **NEW HOOK H4** | Mỗi 2 Mana đã tiêu (đếm trong trận): Axie ít Shield nhất nhận 4 Shield | - |
| `breakersward` | Breaker's Ward (Khiên cướp) | R | shield, pierce | duo | HIT | Pierce phá Shield của địch: Axie ít Shield nhất nhận số Shield bị phá (tối đa 8/đòn). SỬA SAU REVIEW 11/10 (F-15): chỉ hưởng Shield **bị phá**, tự nó không phá; nguồn phá là `talonedge` / `a_pinning`. Gate offer: chỉ ra khi đang giữ `talonedge` hoặc `a_pinning` (§4.2 mục 4) | - |
| `assassinsneedle` | Assassin's Needle (Kim sát thủ) | L | crit, pierce | duo | BUILD, HIT | Mặt Pierce +25% crit chance; Pierce crit gắn Weaken 2 và hoàn 1 Mana | - |
| `coupmark` | Coup Mark (Dấu kết liễu) | E | crit, exec | duo | HIT | Crit lên địch dưới 50% HP: nếu địch còn ≤25% Max HP sau đòn thì chết ngay (Execute) | - |
| `broodbloom` | Brood Bloom (Nở đàn) | E | growth, summon | duo | **NEW HOOK H3** | Cuối lượt mỗi Egg +1 growth; Egg mới nở nhận growth bằng Egg có growth cao nhất | - |
| `wellspringroots` | Wellspring Roots (Rễ suối) | R | growth, mana | duo | **NEW HOOK H4** | Mỗi 2 Mana đã tiêu: mọi mặt của đội +1 growth trong trận (tối đa +4) | - |
| `thornling` | Thornling (Trứng gai) | E | summon, thorns | duo | THORNS | Egg có Thorns 3; mỗi lần Egg phản Thorns, Axie hàng xóm nhận 2 Shield | - |
| `carrioncall` | Carrion Call (Tiếng gọi xác) | E | exec, poison | duo | AGG | Địch có ≥5 Poison được tính là wounded trong `is_wounded()` (§3.5): FERAL, Scent of Blood, Death Spiral và mọi điều kiện "dưới 50% HP". Vì dùng đúng một hàm, địch đó cũng KHÔNG còn là "trên 50% HP" với `dawnlance` (SỬA SAU REVIEW 11/10) | - |

**Class upgrader (6): chỉ offer khi đội có ít nhất 1 Axie class đó (§4.3)**

| id | Tên | R | Tag | Layer | Trigger | Effect | Slot |
|---|---|---|---|---|---|---|---|
| `heartrootgrove` | Heartroot Grove (Lùm rễ tim) | E | plant, shield | class-up | **NEW FIELD** + **NEW HOOK H3** | BULWARK: Thorns 2 từ ≥6 Shield (thay 10), Thorns 3; cuối lượt Axie Plant có ≥10 Shield cho 3 Shield mỗi Axie kề | - |
| `alphafang` | Alpha's Fang (Nanh đầu đàn) | E | beast, exec | class-up | **NEW FIELD** + KILL | FERAL: ngưỡng dưới 65% HP (thay 50%, chỉ FERAL; `is_wounded` của relic khác vẫn 50%), hệ số vẫn ×1.6; Axie Beast kill hoàn 1 Reroll (1/lượt). SỬA SAU REVIEW 11/10 (F-20): chỉ tính kill do **mặt của Axie Beast** gây; kill do tick/thorns/relic không tính. `on_kill` ctx thêm `killer` (§5) | - |
| `tidecaller` | Tidecaller's Conch (Ốc gọi sóng) | E | aqua, mana | class-up | **NEW FIELD** | CONDUIT: mỗi 3 Mana tiêu cho 1 Reroll (thay 4), Reroll này được vượt max tới +2; mặt Mana của Axie Aqua +1 | - |
| `shedskin` | Shed Skin (Lớp da lột) | E | reptile, thorns | class-up | **NEW FIELD** + TAKEN | SCALES: Thorns 4 (thay 2), Thorns gắn Poison 2 (thay 1); Axie Reptile bị đánh khi không có Shield: +4 Shield (1 lần/lượt/Axie) | - |
| `venomlineage` | Venom Lineage (Dòng độc) | E | bug, poison | class-up | **NEW FIELD** | VIRULENT: Poison lên mục tiêu đã có Poison thêm 3 stack (thay 2); lần Poison đầu mỗi lượt của Axie Bug cũng lan 1 stack sang địch kề | - |
| `falconhood` | Falconer's Hood (Mũ chim ưng) | E | bird, pierce | class-up | **NEW FIELD** | TALON: Pierce +5 (thay +3); mặt Pierce của Axie Bird bỏ qua Thorns | - |

**Pact (8 mới + `bloodpact` ở 1.2 = 9). Chỉ ra ở boss, chọn 1/3 (§4.4)**

| id | Tên | R | Tag | Layer | Trigger | Effect (lợi) / drawback (dice, reroll, mana) | Slot |
|---|---|---|---|---|---|---|---|
| `brittledice` | Brittle Dice (Xúc xắc giòn) | E | uni | pact | BUILD | Lợi: mọi mặt dmg +4. Hại: mọi mặt Shield/Heal ×0.5 (làm tròn xuống) | - |
| `devilsreroll` | Devil's Reroll (Reroll của quỷ) | E | mana | pact | **NEW HOOK H1** | Lợi: Reroll max +3. Hại: mỗi lần reroll tốn 1 Mana, hết Mana là không reroll được | - |
| `hollowchalice` | Hollow Chalice (Chén rỗng) | E | mana | pact | AGG | Lợi: +1 ô active (4 ô), mọi active rẻ hơn 2 Mana (sàn 1). Hại: mặt Mana cho 0 Mana (Mana chỉ đến từ relic/class/lượt). SỬA SAU REVIEW 11/10 (F-17): "sau mọi mod, mặt Mana = 0" (`ear` +1, CONDUIT +1, `tidecaller` +1 đều không cứu); `ear`/`tidecaller` thành dead-draw `m=1` (§4.3) | - |
| `twinfates` | Twin Fates (Hai số phận) | L | uni | pact | **NEW HOOK H7** | Lợi: mỗi Axie roll 2 mặt, giữ mặt có giá trị chính cao hơn. Hại: Reroll max = 0, mọi nguồn Reroll vô hiệu | - |
| `lonewolf` | Lone Wolf Contract (Khế ước sói đơn) | E | uni | pact | BUILD | Lợi: Axie slot 1 mọi mặt +100%. Hại: 4 Axie còn lại không được reroll | G |
| `patientfang` | Patient Fang (Nanh kiên nhẫn) | L | uni | pact | AGG | Lợi: mỗi lượt đã qua, mọi mặt dmg +2 (lượt 2 = +2, lượt 3 = +4... tối đa +14). Hại: lượt 1 mọi mặt dmg ra 0 (Shield/Mana/utility vẫn chạy) | - |
| `tithepips` | Tithe of Pips (Thuế chấm) | E | mana | pact | T-START + **NEW HOOK H1 (ROLL-SETTLED), H7** | Lợi: +3 Mana mỗi lượt. Hại: mỗi lượt mặt có giá trị chính thấp nhất sau roll bị blank (không dùng được; reroll để thoát). Cờ blank được tính lại ở mỗi `on_roll_settled` (xoá cờ cũ rồi gắn lại) | - |
| `ironvow` | Iron Vow (Lời thề sắt) | E | shield, thorns | pact | AGG | Lợi: mọi Shield tạo ra ×1.5 (+50% trên trục shield), Thorns +2 cả đội. Hại: mọi mặt dmg −2 (sàn 1) | A |

**Dice-manipulation (6): hold, copy, nudge, swap, lock, flip**

Chung: các thao tác "Tweak" dùng click-click như hiện nay (bấm nút relic, rồi bấm die), miễn phí, **tổng 2 Tweak mỗi lượt cho cả đội relic** (§3.6).

| id | Tên | R | Tag | Layer | Trigger | Effect | Slot |
|---|---|---|---|---|---|---|---|
| `amberdie` | Amber Die (Xúc xắc hổ phách) | R | uni | dice | **NEW HOOK H3, H5, H7** | HOLD: cuối lượt chọn 1 die chưa dùng: lượt sau Axie đó giữ nguyên mặt này (không roll lại, vẫn reroll được). 1 lần/lượt, không tính vào ngân sách Tweak | - |
| `mirrorpip` | Mirror Pip (Chấm gương) | E | uni | dice | **NEW HOOK H7** | COPY: Tweak, chép mặt đã roll của Axie A sang Axie B (mặt cũ của B mất) | - |
| `pipfile` | Pip File (Giũa chấm) | C | uni | dice | **NEW HOOK H7** | NUDGE: Tweak, +1 hoặc −1 giá trị chính của 1 mặt đã roll. Tối đa 2 lần/lượt | - |
| `twinswap` | Twin Swap (Đổi đôi) | R | uni | dice | **NEW HOOK H7** | SWAP: Tweak, đổi chỗ mặt đã roll của 2 Axie chưa dùng mặt | - |
| `loadeddie` | Loaded Die (Xúc xắc gian) | R | uni | dice | **NEW HOOK H6, H7** | LOCK: lúc nhận, chọn 1 mặt của 1 Axie; mặt đó nặng ×3 (xuất hiện 37.5% thay vì 16.7%) cả run | - |
| `flipside` | Flipside Die (Mặt đối) | E | uni | dice | **NEW HOOK H7** | FLIP: Tweak, lật 1 mặt đã roll sang mặt đối (mặt i thành mặt i+3 mod 6, bảng cố định trong data) | - |

**Positional (5): dùng thứ tự đội 5 slot, trái là slot 1**

| id | Tên | R | Tag | Layer | Trigger | Effect | Slot |
|---|---|---|---|---|---|---|---|
| `linkstone` | Linkstone (Đá nối) | C | uni | positional | ROLL-SETTLED (H1) | SỬA SAU REVIEW 11/10 (F-11, Q4): điều kiện **tĩnh**. Mỗi Axie đang đứng kề một Axie còn sống khác mà mặt đang hiện cùng loại (dmg, shield, heal, poison, mana; Egg/token không tính) nhận +2 giá trị chính của mặt đó. **Khác LINK gốc** (LINK gốc kích lúc dùng mặt và ×1.15 cho người dùng sau): linkstone xét theo mặt đang hiện, tính lại sau roll và mỗi reroll, và không cần ai dùng trước. ×1.15 của LINK gốc vẫn chạy riêng. "Kề" dùng đúng hàm của LINK (`combat_engine.gd` ~751, kiểm lúc làm) | - |
| `bookend` | Bookend Pennants (Cờ hai đầu) | C | uni | positional | BUILD | Axie slot 1 và slot 5: mọi mặt dmg +3 | - |
| `keystone` | Keystone (Đá đỉnh vòm) | E | uni | positional | **NEW HOOK H2** | Mặt Shield/Heal/Mana của Axie slot 3 cũng áp 50% cho 2 Axie kề | - |
| `relaybaton` | Relay Baton (Gậy tiếp sức) | E | uni | positional | **NEW HOOK H2** | Axie dùng xong 1 mặt: Axie slot kế bên phải +2 dmg cho mặt kế tiếp lượt này (cộng dồn đi trái sang phải) | - |
| `symmetrycharm` | Symmetry Charm (Bùa đối xứng) | E | uni | positional | **NEW HOOK H1** | SỬA SAU REVIEW 11/10 (F-11): cặp đối xứng (slot 1-5, 2-4) "cùng loại" = cùng loại mặt theo định nghĩa của `linkstone` (dmg, shield, heal, poison, mana; token loại), xét trên mặt đang hiện của hai Axie còn sống. Cặp khớp: cả hai +3 giá trị chính; slot 3 +1 nếu cả hai cặp khớp. Một Axie chết hoặc đã dùng die thì cặp đó không khớp (không tính lại bonus đã trao). Trigger `on_roll_settled`: tính lại sau roll và mỗi reroll, không giữ state | - |

**Scaling có reset (3)**

| id | Tên | R | Tag | Layer | Trigger | Effect | Slot |
|---|---|---|---|---|---|---|---|
| `crescendofang` | Crescendo Fang (Nanh dồn nhịp) | C | exec | scaling | **NEW HOOK H2** | Mỗi mặt dmg dùng trong lượt: mặt dmg kế tiếp +1 (cộng dồn). Reset cuối lượt | - |
| `tideglass` | Tideglass (Kính thủy triều) | E | mana | scaling | **NEW HOOK H4, H5** | Mỗi 3 Mana tiêu: mọi mặt dmg +1 đến hết trận (tối đa +6). Reset mỗi trận | - |
| `heirloom` | Heirloom Seed (Hạt gia truyền) | R | uni | scaling | **NEW HOOK H5, H6** | Mỗi Elite/Boss thắng: mọi mặt dmg +1 vĩnh viễn trong run (tối đa +5). Mang qua trận, không mang qua run | - |

**Economy: chỉ đổi LỰA CHỌN, không đổi thu nhập, giá hay giá bán (3). SỬA SAU REVIEW 11/10 (F-01, Q1)**

Lý do: tiền in-run **là** Gene Shard (`shards_this_run`, được bank vào meta khi `end_run`). Nên mọi relic làm tiền vào nhiều hơn, hay làm chi phí rẻ đi (giữ lại nhiều Shard hơn cuối run), là faucet Gene Shard meta. Quy tắc cho nhóm economy: **không relic nào đổi lượng tiền nhận, giá mua, hay giá bán**. Relic chỉ mở thêm lựa chọn để *tiêu*. Tiêu chỉ làm lượng bank cuối run giảm, không bao giờ tăng, nên không thể là faucet. (`tithepurse` bỏ hẳn, không thay thế.)

| id | Tên | R | Tag | Layer | Trigger | Effect | Slot |
|---|---|---|---|---|---|---|---|
| `merchantscale` | Merchant's Scale (Cân thương nhân) | C | uni | economy | **NEW HOOK H8** | REDESIGN: Shop có **3 relic** thay vì 2, giá và giá bán giữ nguyên. Chỉ thêm lựa chọn để tiêu | - |
| `fortuneledger` | Fortune's Ledger (Sổ vận may) | R | uni | economy | **NEW HOOK H8** | +1 charge reroll phần thưởng mỗi màn reward (cộng vào `reward_reroll_max` từ meta, hiện = 1); charge cộng thêm này tốn 25 tiền in-run mỗi lần dùng. Reroll thẻ đã có sẵn trong code (`reroll_pending_rewards`), relic chỉ cộng charge; thẻ mới tất định theo số lần reroll. **A10: không offer** (A10 không còn reroll reward) | - |
| `scavengereye` | Scavenger's Eye (Mắt nhặt nhạnh) | R | uni | economy | **NEW HOOK H8** | Reward Battle/Elite hiện 4 thẻ thay vì 3; Treasure có thêm 1 thẻ relic (F-21: Treasure hiện là reward tier 1 nhiều loại thẻ, không có thẻ "chọn 1 trong 2 relic") | - |

**Payoff lẻ (1): lấp chỗ thiếu payoff của BULWARK**

| id | Tên | R | Tag | Layer | Trigger | Effect | Slot |
|---|---|---|---|---|---|---|---|
| `towershield` | Tower Shield (Khiên tháp) | C | shield | payoff | DMG | Mặt dmg của Axie đang có Shield: +1 dmg mỗi 4 Shield (tối đa +6). Shield thành sát thương | - |

### 1.6 Active (16, giữ). 3 ô active riêng

Active chiếm ô active (3 ô, +1 nếu có `hollowchalice`), không chiếm ô passive. Trigger luôn ACT. Layer luôn `active`.

| id | Tên | R | Tag | Layer | Trigger | Effect (MP = Mana) | Slot |
|---|---|---|---|---|---|---|---|
| `a_restore` | Anemone Restore (Hồi hải quỳ) | C | shield | active | ACT 2MP | Hồi 9 HP | - |
| `a_freeze` | Cryo Spore (Bào tử băng) | C | mana | active | ACT 4MP | Stun 1 địch | - |
| `a_wall` | Lunacia Wall (Tường Lunacia) | R | shield | active | ACT 6MP | 5 Shield cả đội | - |
| `a_chaos` | Chaos Gene (Gene hỗn loạn) | R | mana | active | ACT 1MP | +4 Reroll lượt này. **Thêm trần:** tổng Reroll nhận từ active ≤6/lượt (chặn 1MP = 8 reroll với Conduit Crown) | - |
| `a_pinning` | Pinning Lance (Giáo ghim) | R | pierce | active | ACT 3MP | Phá Shield, dmg = Shield (min 6) | - |
| `a_clutch` | Clutch Call (Tiếng gọi cứu) | R | summon | active | ACT 4MP | 1 Egg | - |
| `a_bramblewall` | Bramble Wall (Tường gai) | R | thorns | active | ACT 3MP | Thorns ≥5 cả đội | - |
| `a_perfectstrike` | Perfect Strike (Đòn hoàn hảo) | R | crit | active | ACT 4MP | **BUFF** 5MP → 4MP: 8 dmg luôn crit (≈4 dmg/MP, ngang Chomp) | - |
| `a_plague` | Spore Bloom (Bào tử nở) | E | poison | active | ACT 6MP | Poison 3 mọi địch | - |
| `a_chomp` | Chomp Strike (Cú cắn) | E | pierce | active | ACT 3MP | 12 dmg xuyên (chuẩn 4 dmg/MP) | - |
| `a_bloom` | Bloom Surge (Sóng nở) | E | growth | active | ACT 5MP | Mặt đang roll +3 growth | - |
| `a_coupdegrace` | Coup de Grâce (Nhát ân huệ) | E | exec | active | ACT 4MP | **BUFF** 5MP → 4MP, 14 → 15 dmg execute (3.75 dmg/MP) | - |
| `a_pyre` | Pyre Bloom (Hoa lửa) | E | burn | active | ACT 7MP | Burn 6 mọi địch | - |
| `a_aegisfont` | Aegis Font (Suối khiên) | E | shield | active | ACT 8MP | 8 Shield cả đội | - |
| `a_nova` | Gene Nova (Tân tinh gene) | L | aoe | active | ACT 7MP | **BUFF** 8MP → 7MP, 10 → 12 dmg mọi địch (≈1.7 dmg/MP/mục tiêu) | - |
| `a_ult` | LUNACIA ULTIMA | L | mana | active | ACT 18MP | 40 dmg xuyên + 10 Shield cả đội | - |

Id file hiện tại có tiền tố `r_`/`a_` (ví dụ `r_claw.tres`); cột id ở trên là id logic, active có `a_`, passive không ghi tiền tố cho gọn.

## 2. Relic mới: vì sao hay, combo, quyết định

Cơ sở: mỗi relic mới phải làm ít nhất một trong ba việc: **đổi luật** (hook mới), **tạo combo nhìn thấy được** (hai tag, hai class, hai slot), hoặc **buộc một quyết định giữa trận** (bỏ một die, trả Mana để reroll, xếp lại đội). Không relic nào chỉ cộng số (trừ vài cái Common cố ý đơn giản để làm bậc thang cho người mới).

### 2.1 Phủ archetype: mỗi kiểu chơi đủ 2 enabler, 2 payoff, 1 engine

Chữ nghiêng là relic mới hoặc relic được rework thành loại đó. `scaling` tính như payoff cho bảng phủ.

| Archetype | Enabler | Payoff | Engine |
|---|---|---|---|
| exec (FERAL) | `gorehook`, *`crescendofang`* | `scentofblood`, `deathspiral`, *`cullingorder`* (+`deathmark`) | `apexferal` |
| shield (BULWARK) | *`carapace`*, `lastwall`, *`heart`*, `holyfont` | `bastionplate`, *`towershield`* | *`soulforge`* |
| pierce (TALON) | `pierceall`, *`talonedge`*, `marrowdrill` | `thousandcuts`, *`hollowbone`* | `worldpiercer` |
| mana (CONDUIT) | `tidalbrand`, *`ear`*, `infinitedie`, `manaspring` | `manaflood`, *`tideglass`* | `conduitcrown` |
| thorns (AEGIS) | *`barbedhide`*, `bloodthorn` | `retributor`, `ironmaiden`, `mirrorshell`, `glassspine` | `scalecrown` |
| summon (SWARM) | `broodpouch`, *`eggshell`*, `broodmother` | *`apexbrood`*, `hivemind` | `hivequeen` |
| growth (EVOLVE) | `seedling`, `bloomscale`, `growthcore`, *`regrow`* | `heartwood`, `quickenroot` | `worldtree` (+*`ancientgene`* là ô G) |
| poison (PLAGUE) | `rotmouth`, *`fang`* | `pandemic`, *`festermark`* | `plaguelord`, `venomengine` |
| crit (APEX) | `predatorpoise`, *`luckycharm`* | `shatterpoint`, `keeneye`, `bloodhymn` | *`apexpredator`* |
| aoe (TEMPEST) | *`cleaveall`*, `squallmark`, `windlash` | `chainreact`, *`gustwing`* | `stormcall` |
| burn (INFERNO) | `wildfire`, `ember` | `pyroclasm`, `hearthcore`, *`festermark`* | `solarcore` |

Engine chung (không theo archetype): `echostone`, `ancientgene`, `dawnlance` (payoff opener). Bài học LoL trong audit §4: engine không được khoá vào một class, nên không relic engine nào có tag class.

### 2.2 Combo đáng nhớ (kiểm bằng sim ở §6)

| Combo | Cách chạy | Quyết định nó tạo ra |
|---|---|---|
| **Nhịp độc-lửa** `fumeblossom` + `wildfire` + `rotmouth` | Horn gắn Burn 6, Mouth gắn Poison 2; mỗi tick của một trục nuôi trục kia | Chọn mục tiêu để dồn hai status lên cùng một địch (tick chỉ nuôi nhau khi cả hai có mặt) |
| **Khiên thành giáo** `towershield` + `soulforge` + `breakersward` | Pierce phá Shield địch, lấy Shield về; Shield cao thì mặt dmg mạnh | Giữ Shield cao thay vì xả, đẩy dmg từ mặt Shield sang mặt dmg |
| **Con dao một nhát** `keeneye` + `coupmark` + `assassinsneedle` | Crit chance cao ở mặt Pierce, crit lên địch dưới 50% thì Execute ≤25% | Chọn Axie nào đánh trước để đúng thứ tự ngưỡng HP |
| **Mana đổi tăng trưởng** `wellspringroots` + `tideglass` + `tidecaller` | Mỗi lần tiêu Mana vừa +growth vừa +dmg vừa hoàn Reroll | Tiêu Mana sớm (growth cộng dồn lâu hơn) hay giữ cho active lớn |
| **Chuỗi tiếp sức** `relaybaton` + `bookend` + `linkstone` | Xếp đội theo thứ tự dmg tăng dần, hai đầu có +3, cặp LINK +2 | Cuộc xếp đội ở màn Map **là** quyết định build (quyết định 7) |
| **Hai thế giới** `amberdie` + `echostone` | Giữ mặt lớn nhất sang lượt sau, lượt sau Echo kích 2 lần | Hy sinh một mặt lượt này lấy một đòn gấp đôi lượt sau |
| **Đàn gai** `thornling` + `scalecrown` + `mirrorshell` | Egg có Thorns 3; Mirror Shell nhân trục thorns (một ô A) | Dồn vào Egg đứng hàng đầu thay vì Axie |
| **Lấy khiên đổi dice** `ironvow` + `soulforge` | Shield ×1.5 nhưng mọi mặt dmg −2 | Biến cả đội thành nguồn Shield, dmg đến từ Soul Forge/Tower Shield/Thorns |

### 2.3 12 relic Duo (cặp archetype chọn tay)

Mỗi archetype xuất hiện ở ít nhất 2 duo. Duo chỉ offer khi relic đang giữ có đủ cả hai tag (§4.3).

| # | Cặp | Relic | Combo nó mở ra |
|---|---|---|---|
| 1 | poison + burn (PLAGUE + INFERNO) | `fumeblossom` L | Hai status nuôi nhau |
| 2 | poison + aoe (PLAGUE + TEMPEST) | `sporegale` R | Cleave rải Poison lên cả bàn, lan sang hàng xóm |
| 3 | burn + aoe (INFERNO + TEMPEST) | `firestormveil` E | Mặt AoE gắn Burn lên mọi địch |
| 4 | shield + thorns (BULWARK + AEGIS) | `spikedbulwark` R | Shield cao thành Thorns cao |
| 5 | shield + mana (BULWARK + CONDUIT) | `aegiscapacitor` E | Tiêu Mana thành Shield cho Axie yếu |
| 6 | shield + pierce (BULWARK + TALON) | `breakersward` R | Phá Shield địch, ăn Shield đó |
| 7 | crit + pierce (APEX + TALON) | `assassinsneedle` L | Pierce thành đòn crit + Weaken + Mana |
| 8 | crit + exec (APEX + FERAL) | `coupmark` E | Crit lên địch yếu là Execute |
| 9 | growth + summon (EVOLVE + SWARM) | `broodbloom` E | Egg cũng lớn, Egg mới thừa hưởng growth |
| 10 | growth + mana (EVOLVE + CONDUIT) | `wellspringroots` R | Mana tiêu ra thành growth |
| 11 | summon + thorns (SWARM + AEGIS) | `thornling` E | Egg có Thorns, Egg bị đánh hộ Shield |
| 12 | exec + poison (FERAL + PLAGUE) | `carrioncall` E | Địch nhiễm độc cũng tính là "đã bị thương" cho mọi điều kiện dưới 50% HP |

Phủ: exec 2 (#8, #12), shield 3, pierce 2, mana 2, thorns 2, summon 2, growth 2, poison 3, crit 2, aoe 2, burn 2.

### 2.4 6 Class upgrader

Mỗi cái đổi **luật** của passive class, không chỉ số. Chỉ offer khi đội có Axie class đó (§4.3). Không cái nào được nâng hệ số nhân gốc của passive (FERAL vẫn ×1.6), nên không chiếm ô nhân.

| Class | Passive hôm nay | Relic | Thay đổi luật |
|---|---|---|---|
| Plant | BULWARK: +2 mọi Shield, ≥10 Shield thì Thorns 2 | `heartrootgrove` | Ngưỡng 10 → 6, và cuối lượt Axie Plant giàu Shield chia Shield cho hàng xóm (dùng vị trí) |
| Beast | FERAL: dưới 50% HP ×1.6 | `alphafang` | Ngưỡng 50% → 65% (nhiều đòn đủ điều kiện hơn), kill hoàn Reroll |
| Aqua | CONDUIT: +1 mọi Mana, 4 Mana tiêu = 1 Reroll | `tidecaller` | 3 Mana = 1 Reroll, được vượt trần Reroll |
| Reptile | SCALES: Thorns 2, Thorns gắn Poison 1 | `shedskin` | Thorns 4, Poison 2, bị đánh khi hết Shield thì nhận Shield |
| Bug | VIRULENT: Poison lên mục tiêu đã có Poison +2 | `venomlineage` | +3, và lan 1 stack sang hàng xóm lần đầu mỗi lượt |
| Bird | TALON: Pierce +3, AoE có Pierce | `falconhood` | Pierce +5, bỏ qua Thorns |

### 2.5 Pact (9). Chọn 1/3 ở boss, drawback chỉ ở xúc xắc, reroll, hoặc Mana

Không pact nào đụng HP. Pact chiếm 1 ô passive như relic thường.

| Pact | Lợi | Hại | Loại drawback | Hợp với | Tránh với |
|---|---|---|---|---|---|
| `bloodpact` L | Mọi dmg +60% (ô G) | Reroll max −2 | Reroll | Build đã chốt mặt tốt, ít cần reroll (TALON, FERAL) | `tidalbrand`, `infinitedie` (chết một nửa) |
| `twinfates` L | Mỗi die roll 2, giữ cao hơn | Không còn Reroll | Reroll | Build nhiều Axie, ít mặt phụ thuộc loại mặt | Mọi relic cộng Reroll |
| `lonewolf` E | Axie slot 1 mặt +100% (ô G) | 4 Axie còn lại không reroll được | Reroll | Một carry rõ ràng, đặt vào slot 1 | Đội cần reroll để tìm Pierce/Poison đều cho 5 Axie |
| `brittledice` E | Mọi mặt dmg +4 | Shield/Heal ×0.5 | Dice | Burst thuần (exec, crit, pierce) | BULWARK, AEGIS |
| `patientfang` L | +2 dmg mỗi lượt qua (tối đa +14) | Lượt 1 dmg = 0 | Dice | Build chậm (poison, thorns, growth) | Build cần giết nhanh |
| `tithepips` E | +3 Mana/lượt | Mặt thấp nhất mỗi lượt bị blank | Dice | CONDUIT | Đội có ít mặt giá trị cao |
| `ironvow` E | Shield ×1.5, Thorns +2 | Mặt dmg −2 | Dice | BULWARK, AEGIS | exec, crit |
| `hollowchalice` E | +1 ô active, active −2 Mana | Mặt Mana cho 0 | Mana | Build active thuần (`a_ult`, Pyre, Nova) | Build dựa vào mặt Mana |
| `devilsreroll` E | Reroll max +3 | Mỗi reroll tốn 1 Mana | Mana + Reroll | Build cần tìm mặt (pierce/crit combos) | Build ít Mana |

Drawback phải "đau thật và lâu dài trong run" (audit §5.2 luật 7): đều bật suốt run, không phải "mất lượt này". Nhóm drawback `Reroll / Dice / Mana` dùng để chia offer boss (§4.4): mỗi thẻ boss lấy mỗi nhóm một pact, nhưng **mỗi pact chỉ một lần/run**, không phải mỗi nhóm (SỬA SAU REVIEW 11/10, Q3). `twinfates` và `devilsreroll` loại nhau (§4.2 mục 6).

### 2.6 Positional, Dice, Scaling, Economy: quyết định mà chúng tạo ra

- **Positional** (`linkstone`, `bookend`, `keystone`, `relaybaton`, `symmetrycharm`): thứ tự đội thành một bài toán ghép. Ví dụ đội `[A B C D E]`: Bookend thưởng A và E, Keystone thưởng C, Symmetry thưởng khi A-E và B-D cùng loại mặt. Người chơi xếp lại ở màn Map giữa các trận (quyết định 7); trong trận thứ tự cố định.
- **Dice**: 6 relic, 6 động từ (hold, copy, nudge, swap, lock, flip). **Ngân sách Tweak toàn đội relic = 2/lượt** để không thành "chỉnh hết mọi die". Hold (`amberdie`) tách riêng vì nó mang qua lượt chứ không sửa lượt này. Mỗi thao tác ghi vào ActionLog (§5, H7) nên replay vẫn kiểm được.
- **Scaling có reset**: `crescendofang` reset mỗi lượt, `tideglass` reset mỗi trận, `heirloom` mang qua trận, reset mỗi run. Ba nhịp reset khác nhau để người chơi biết "gốc rễ" của số cộng.
- **Economy** (3, SỬA SAU REVIEW 11/10): chỉ thêm lựa chọn để tiêu: nhiều món trong shop (`merchantscale`), thêm charge reroll thẻ thưởng (`fortuneledger`), nhiều thẻ để xem (`scavengereye`). Không relic nào đổi tiền nhận/giá/giá bán, nên không phải faucet Gene Shard (quyết định 8, F-01).

### 2.7 Giữ lại cho người mới

Commons mới (`pipfile`, `linkstone`, `bookend`, `crescendofang`, `towershield`, `merchantscale`) cố ý đọc hiểu trong một câu: người chơi trận 1-3 vẫn có relic dễ hiểu để chọn (flow: scaffolded challenge).

## 3. Slot và luật nhân

### 3.1 Ô relic

- **8 ô passive, 3 ô active** (+1 ô active nếu có `hollowchalice`). Pact và relic khởi đầu từ meta `u_start` đều chiếm ô passive.
- Hết ô mà nhận relic mới: người chơi chọn **bán một relic đang có** (nhận 50% giá, §3.7) để đổi, hoặc bỏ relic mới. Áp dụng cho mọi nguồn (reward, shop, treasure, event, pact).
- Giá bán 50% tính theo giá mua của rarity: C 45, R 75, E 120, L 180, nên bán được 22 / 37 / 60 / 90 (làm tròn xuống). Relic nhận miễn phí vẫn bán theo bảng này. (SỬA SAU REVIEW 11/10: `merchantscale` không còn nâng giá bán, xem §1.5 economy.)

**Bảng luật ô đầy (SỬA SAU REVIEW 11/10, F-08).** Một bảng cho mọi nguồn:

| Tình huống | Luật |
|---|---|
| Nhận relic thường khi 8 ô passive đầy | Hộp "bán một relic để đổi" hoặc bỏ relic mới. Không bán được relic Eternal (A5) |
| Nhận relic **nhân** (G hoặc A) khi ô nhân của nó đã đầy (kể cả khi còn ô passive trống) | Vẫn được nhận, nhưng phải bán **một relic cùng loại ô nhân** (G bán relic G; A bán một trong hai relic A). Không bán relic khác để lách. Nếu relic duy nhất cùng ô là Eternal thì thẻ bị mờ, không nhận được. Offer có `m=1` (§4.3), không bị loại |
| Pact thường (A0–A5) khi đầy | Như relic thường; người chơi được **hủy** (không nhận pact) |
| Pact **ép** (A6 boss đầu, A10 mọi boss) khi 8/7 ô đầy | Hộp bán **bắt buộc, không có nút hủy**: phải bán một relic không-Eternal (nếu pact chiếm ô nhân thì áp luật dòng trên). Pact nào không thể đặt hợp lệ bị lọc khỏi thẻ ngay từ khâu offer, nên không có ngõ cụt |
| `ironvow` (A) và mọi pact có `mult_axis` | Cùng luật ô nhân như relic thường: `bloodpact`/`lonewolf` chiếm G, `ironvow` chiếm A. (Bản cũ chỉ nhắc ô G) |
| Bán một pact | Nhận 50% giá theo rarity như relic miễn phí khác. Drawback và lợi ích mất ngay. Pact đó **vẫn tính đã dùng**: không offer lại trong run (luật mỗi pact một lần, §4.4). Bán pact không "trả lại" gì |

### 3.2 Ba loại "nhân", và cái gì KHÔNG phải nhân

Mỗi relic có đúng một giá trị `mult_axis` trong data. Trục G là **theo từng Axie và chỉ cho mặt sát thương** (SỬA SAU REVIEW 11/10, Q2; xem §3.3). Sát thương cộng phẳng (+N) **không có trần mềm** (Q6); thay vào đó các relic cộng phẳng là ưu tiên sim số 1 (§6.5):

| `mult_axis` | Ý nghĩa | Ô chiếm | Relic hiện có |
|---|---|---|---|
| `G` | Nhân dmg của **mọi mặt dmg**, không điều kiện (đi qua `dmgMult` ở `damage_pipeline.gd`) | **1 ô G**, tối đa 1 relic | `ancientgene` +30%, `bloodpact` +60%, `lonewolf` +100% (chỉ Axie slot 1) |
| `A:<trục>` | Nhân một trục cụ thể: `poison` tick, `burn` tick, `thorns`, `crit` (hệ số crit), `opener` (đòn vào địch >50% HP), `shield` (Shield tạo ra) | **2 ô A**, tối đa 2 relic | `venomengine` (poison +100%), `hearthcore` (burn +70%), `solarcore` (burn +100%), `mirrorshell` (thorns +100%), `apexpredator` (crit ×2 → ×3 = +100%), `dawnlance` (opener +90%), `ironvow` (shield +50%) |
| `-` | Không nhân | không chiếm ô | Mọi relic còn lại |

Không phải nhân (không chiếm ô): số cộng phẳng (+N dmg), gắn keyword (Pierce, Execute, Cleave), điều kiện cộng phẳng (Scent of Blood +4), thêm lần đánh nhưng nửa dmg (Thousand Cuts), thêm mục tiêu, status mới. Hệ số nhân **gốc của luật** cũng không chiếm ô và không relic nào được nâng chúng: Execute ×1.6, FERAL ×1.6, LINK ×1.15, Vulnerable ×1.5. Đây là luật cho cả class upgrader.

### 3.3 Cộng trong trục, nhân giữa các trục

Mỗi trục: `total = 1 + Σ bonus` của mọi nguồn trong trục đó. Các trục khác nhau thì nhân với nhau.

- Hai relic burn: `hearthcore` +70% và `solarcore` +100% cho `1 + 0.7 + 1.0 = ×2.7` (cũ là ×2 × ×1.7 = ×3.4). Chiếm cả 2 ô A.
- **Trục G, theo từng Axie, chỉ mặt sát thương (SỬA SAU REVIEW 11/10, Q2 của Liam).** Trong code `ascend` (reward, người chơi chọn Axie) và `forge` (event, Axie ngẫu nhiên) là mutation `oc` trên **một Axie** (`RunState.gd` ~607–616, ~731–738), nhân `ceil(v × mult)` lúc dựng die. Luật mới:
  - `G_axie = min(2.5, 1 + Σ bonus relic G áp cho Axie đó + 0.25 × ascend_axie + 0.30 × forge_axie)`, với `ascend_axie`/`forge_axie` là số lần Axie **đó** nhận. `lonewolf` chỉ cộng cho Axie slot 1.
  - Chỉ áp cho mặt sát thương. Cách triển khai: trên mặt dmg, `oc` của ascend/forge **không nhân** lúc dựng die nữa mà đọc thành số hạng `axie_g_bonus` trong tổng G (đổi từ nhân dồn 1.25^n sang cộng 1 + 0.25n, và làm tròn một lần ở pipeline). +6 Max HP của `ascend` giữ nguyên.
  - Mặt Shield / Heal / Mana: giữ nhân `oc` dồn từ `ascend`/`forge` như hôm nay, nhưng **chặn tối đa ×2.0** (Liam 11/10, §7 câu 16). Ví dụ 4 lần ascend: 1.25⁴ = 2.44 → 2.0.
  - Vẫn tối đa 1 relic chiếm ô G (R1 không đổi).
- Crit chance: các nguồn gộp kiểu `1 − Π(1 − p_i)` (hyperbolic, kiểu Risk of Rain 2), chặn 75%. Hệ số crit ở trục `A:crit`.
- Dr (giảm dmg nhận) không còn relic nào dùng sau khi `soulforge` bỏ `dr`. Nếu sau này có, nó là trục G phòng thủ riêng, 1 ô.

### 3.4 Thứ tự tính (INV-5 giữ nguyên)

Keyword → cộng phẳng → nhân (data khi dựng die). Trong pipeline damage: Execute ×1.6 → Pierce → `G_axie` (của Axie đang đánh) → `mod_dmg` (relic điều kiện cộng phẳng và `opener`) → Crit (chance từ nguồn gộp, hệ số từ `A:crit`). Status tick đi đường riêng: `base × (1 + Σ bonus trục tương ứng)`.

### 3.5 Poison / Burn / Thorns tick và damage do relic gây ra

**Một hàm `is_wounded(tgt)` (SỬA SAU REVIEW 11/10, F-05).** Mọi điều kiện "dưới 50% HP" dùng đúng một hàm: `is_wounded(tgt) = tgt.hp < tgt.max_hp × 0.5  hoặc  (đang giữ carrioncall và tgt.poison ≥ 5)`. Người dùng: FERAL, `scentofblood`, `deathspiral`, `coupmark` (điều kiện "dưới 50%"), và `dawnlance` dùng `not is_wounded(tgt)`. Một địch không bao giờ vừa wounded vừa "trên 50%". Ngoại lệ duy nhất là `alphafang`: nâng ngưỡng 65% **chỉ trong FERAL** (tham số `threshold` của hàm, mặc định 0.5), relic khác vẫn gọi mặc định. `deathspiral` kích khi `is_wounded` chuyển false → true lần đầu trên địch đó (cờ theo địch, nằm trong `_state_dict`, §5).

| Nguồn damage | Dính G? | Dính trục A cùng loại? | Kích HIT/DMG? | Crit? | Tính vào "tổng dmg" (`stat`)? | Kích KILL khi giết? |
|---|---|---|---|---|---|---|
| Mặt dmg của Axie | Có | Opener/Crit | Có | Có | Có | Có |
| Poison / Burn tick | Không | Có (`A:poison`, `A:burn`) | Không | Không | Có | Có |
| Thorns phản | Không | Có (`A:thorns`) | Không | Không | Có | Có |
| **Damage do relic gây ra** (Bastion Plate, Death Spiral, Hollow Bone 50%, Chain Reaction, Iron Maiden, Mana Flood) | Không | Chỉ khi con số gốc là Poison/Burn/Thorns | **Không** | Không | Có | Có, độ sâu 1 |

**Kích KILL độ sâu 1:** kill do relic damage vẫn kích các relic KILL (ví dụ `broodmother` nở Egg), nhưng damage do **handler của KILL đó** gây ra (Chain Reaction nổ) có `depth = 1` và không kích KILL nữa. Chặn nổ dây chuyền vô hạn mà vẫn giữ được combo hợp lý. Dùng đường `attack:false, src:null` sẵn có ở pipeline, thêm một biến `depth`.

### 3.6 Ngân sách Tweak

Mọi thao tác Tweak của relic dice (`mirrorpip`, `pipfile`, `twinswap`, `flipside`) dùng chung **2 Tweak mỗi lượt**. Hold của `amberdie` không tính vào. `loadeddie` không dùng Tweak (nó chỉ đổi trọng số roll). Tweak không dùng được trên die đã dùng mặt. Ngân sách còn lại và mọi bộ đếm của §3.6 nằm trong `_state_dict` (§5, F-09): undo không được hoàn lại ngân sách.

**Trần Reroll nhận từ relic (SỬA SAU REVIEW 11/10, F-22).** Tổng Reroll nhận/hoàn từ relic trong một lượt (`cullingorder`, `apexpredator`, `alphafang`, `tidecaller`) ≤ **4/lượt** (núm `relic_reroll_cap`, mặc định 4, sim chỉnh). Không tính vào: `a_chaos` (có trần riêng 6/lượt từ active), chuyển Mana→Reroll của class CONDUIT gốc, và `infinitedie` (đó là max chứ không phải hoàn).

### 3.7 Đồng tiền

SỬA SAU REVIEW 11/10 (F-01): tiền in-run **là** Gene Shard: `shards_this_run` được `MetaState.add_shards()` bank khi `end_run` (`RunState.gd:35,386,447,783-787`). Vì thế luật là: không relic nào, kể cả economy, làm tăng tiền nhận, giảm giá mua, hay tăng giá bán. Bán relic (50% cố định) là faucet đã có sẵn, không đổi. `fortuneledger` là sink (25/lần dùng charge thêm). `merchantscale` và `scavengereye` không đổi dòng tiền. Test R6 so meta save trước/sau; thêm R14: lượng Shard bank cuối run với/không có 3 relic economy **không chênh** nếu người chơi chi tiêu giống nhau.

### 3.8 Ba build ví dụ, thấy trần làm việc

**Ví dụ 1: PLAGUE (đội Bug). Thấy 2 ô A đầy.**
Relic đang giữ: `rotmouth`, `fang`, `festermark`, `pandemic`, `plaguelord`, `carrioncall`, `venomlineage` (7 ô passive) + `venomengine` (A1, +100% poison) = 8/8. Mục tiêu có 8 Poison, tick gốc 8:
- Tick = 8 × (1 + 1.0) = 16/lượt, không giảm (plaguelord).
- `fumeblossom` chưa thể xuất hiện vì build chưa có relic tag burn (§4.3). Người chơi bán `fang` (nhận 60 tiền) để lấy `wildfire`; giờ đã có cả hai tag poison + burn nên các offer sau có thể ra `fumeblossom`. Họ nhặt `solarcore` (bán thêm `rotmouth` để có ô; A2, burn +100%): A = 2/2.
- Offer kế tiếp có `mirrorshell` (A thứ 3, ra với `m=1` nên hiếm). Nhận được nhưng phải đổi: UI ghi "Ô nhân archetype đã đầy, bán `venomengine` hoặc `solarcore` để đổi" (bảng luật ô đầy §3.1; không bán relic khác để lách). Cũ: không giới hạn, venomengine + plaguelord + solarcore + hearthcore chạy cùng nhau.

**Ví dụ 2: INFERNO. Cộng trong trục, không nhân dồn.**
Giữ `wildfire`, `ember`, `pyroclasm`, `hearthcore` (A1), `solarcore` (A2), `ancientgene` (G). Burn gốc 6 trên một mục tiêu:
- Cũ: 6 × 2 × 1.7 = **20.4** mỗi tick.
- Mới: 6 × (1 + 0.70 + 1.00) = **16.2** mỗi tick (−21%).
- Dice dmg: `ancientgene` +30% (G). Muốn thêm `bloodpact` (G): ra với `m=1` (ô G đầy), và nhận thì phải bán `ancientgene` đổi.

**Ví dụ 3 (VIẾT LẠI SAU REVIEW 11/10, F-02): TALON (đội Bird + Beast), có chọn pact ở boss. G tính theo từng Axie.**
Giữ `worldpiercer`, `thousandcuts`, `hollowbone`, `dawnlance` (A1, opener +90%), `apexpredator` (A2, crit +100%), `bloodpact` (G, +60%). Người chơi chọn `ascend` **2 lần, đều trên Axie X (carry)**; Axie Y không có ascend.
- Trục G của X: 1 + 0.60 + 0.25×2 = **2.10** (dưới trần 2.5). Của Y: 1 + 0.60 = **1.60**. `ancientgene` ra với `m=1` (ô G đầy).
- Đòn mở vào địch không-wounded: X = 2.10 × 1.9 (opener) = **×3.99**; Y = 1.60 × 1.9 = **×3.04**. Cũ (X): 1.6 × 1.3 × 1.9 × 1.25² = **×6.18**; cũ (Y): 1.6 × 1.3 × 1.9 = ×3.95.
- Địch wounded: X = 2.10 × 1.6 (FERAL, hệ số gốc) = **×3.36**; Y = 1.60 × 1.6 = **×2.56** (cũ X ×5.2). `dawnlance` không áp lên địch wounded (cùng một `is_wounded`).
- Ascend lần thứ 3 trên X: G_X = 1 + 0.60 + 0.75 = 2.35; lần thứ 4: 2.60, chặn ở **2.5**. Ascend trên Axie khác không làm X chạm trần nhanh hơn.
- Mặt Shield/Heal/Mana của X vẫn nhân `oc` như cũ (1.25²), không qua trục G.
- Reroll max −2 của bloodpact: đội cần tự kiếm reroll hoặc chấp nhận 0 reroll, nên build này rất phụ thuộc vào `tidalbrand`, `infinitedie`, `tidecaller`.

## 4. Hệ thống offer

### 4.1 Trọng số rarity theo nguồn (hai bước: chọn rarity, rồi chọn relic)

Hôm nay `pick_relic` chọn đều theo số relic nên boss ra Legendary 43%, elite 27%. Mới: **bước 1 chọn rarity theo trọng số của nguồn, bước 2 chọn relic trong rarity đó**. Rarity không có relic hợp lệ thì bỏ ra khỏi bảng và chuẩn hóa lại.

| Nguồn | Band hôm nay | Trọng số mới (%) | Ghi chú |
|---|---|---|---|
| Battle thường | C, R (sau pw>6: thêm E) | C 65 / R 35. Sau pw>6: C 50 / R 38 / E 12 | Trận đầu toàn thứ dễ hiểu |
| Mốc mỗi 3 step | R, E | R 70 / E 30 | |
| Elite | R, E, L | R 45 / E 40 / L 15 | Legendary từ ~27% còn 15% |
| Boss: thẻ relic thường | E, L | E 70 / L 30 | Legendary từ ~43% còn 30% (ví dụ của Liam) |
| Boss: thẻ Pact | E, L | Mỗi nhóm drawback một pact, trong nhóm đều theo pact (§4.4, SỬA SAU REVIEW 11/10) | Thay thẻ `chaos`/`curse` |
| Shop (2 relic/lần, 3 nếu có `merchantscale`) | giá 45/75/120/180 | C 35 / R 40 / E 22 / L 3 | Legendary hiếm ở shop (như Balatro) |
| Treasure | reward tier 1 | R 50 / E 40 / L 10 | |
| Event `chest` | R, E, **L** (code `pick_relic(1,3)` gồm cả Legendary) | R 55 / E 45 | Đổi hàm chọn và **bỏ Legendary khỏi chest** (đổi nhỏ so với code; F-19) |
| Event `bet_small` (tung đồng xu) | E, L | E 70 / L 30 | Thua −10% Max HP, **giữ như cũ** (Q5: là event, không phải relic) |
| Event `gamble_legend` | L | L 100 | Giữ như cũ, kèm −20% Max HP (Q5). R5 chỉ nói về relic/pact, không về event |

Không có pity timer cho Legendary ở bản này (xem câu hỏi mở).

### 4.2 Điều kiện loại cứng (không bao giờ offer)

1. Relic đã sở hữu (id) hoặc đã nằm trong offer đang hiện.
2. Relic **con** của relic đang sở hữu (`exSub` một chiều): `pierceall` ⊂ `worldpiercer`, `gorehook` ⊂ `apexferal`, `windlash` ⊂ `stormcall`. Có relic con rồi vẫn offer relic cha (nâng cấp). Hai cặp cũ `spines`/`scalecrown`, `swarmnest`/`broodpouch` đã biến mất nhờ merge.
3. Pact ngoài màn Pact của boss.
4. Duo khi chưa đủ 2 tag (§4.3). Class upgrader khi đội không có Axie class đó. `breakersward` khi chưa giữ `talonedge` hoặc `a_pinning` (F-15).
5. **Pact đã từng nhận trong run** (kể cả đã bán). SỬA SAU REVIEW 11/10 (Q3): luật là **mỗi PACT một lần/run**, không còn "mỗi nhóm drawback một lần". Pact không thể đặt hợp lệ (ô nhân đầy mà chỉ còn relic Eternal cùng ô; §3.1) cũng bị lọc.
6. **SỬA SAU REVIEW 11/10** (quyết định 13 của Liam + F-04). `twinfates` loại nhau hai chiều với mọi nguồn Reroll **là relic**: `tidalbrand`, `infinitedie`, `tidecaller`, `devilsreroll`, `cullingorder`, `apexpredator`, `alphafang`, `a_chaos`. Đang giữ `twinfates` thì không offer nhóm đó; đang giữ bất kỳ relic nào trong nhóm đó thì không offer `twinfates` (kể cả relic khởi đầu từ meta `u_start`). Áp cả trong màn Pact của boss (lọc khỏi thẻ trước khi chọn). `devilsreroll` và `twinfates` cũng loại nhau (cùng nhóm loại trừ ở trên; nay vì mỗi pact một lần/run nên cả hai cùng ra được nếu không lọc, và cặp đó là chết). Aqua CONDUIT (4 Mana = 1 Reroll) chỉ là cảnh báo UI trên thẻ `twinfates` khi đội có Axie Aqua, class không đổi được. **ĐÃ ÁP (Liam 11/10, câu 15):** khi đang giữ `twinfates`, thẻ reward `reroll`, shop item `reroll` và event option `bless_reroll` bị bỏ khỏi pool (không bao giờ hiện). `curse` (+1 reroll) cũng bị bỏ khỏi pool khi giữ `twinfates` (Liam 11/10).

### 4.3 Offer nghiêng theo build (1/3) và gating

**Điểm tag**: `score(t) = số relic đang giữ có tag t + số Axie trong đội có class gắn với archetype t` (dùng đúng ánh xạ `CLASS_PASSIVE.<class>.a` sẵn có trong `ContentDB.gd`: plant→shield, beast→exec, aqua→mana, reptile→thorns, bug→poison, bird→pierce). Tag `uni` không tính.
**Tag dẫn (lean tags)**: 2 tag có `score` cao nhất, `score ≥ 1`; hòa thì theo thứ tự cố định `exec shield pierce mana thorns summon growth poison crit aoe burn`. Chưa có tag nào thì chỉ dùng tag của class đội.

Khi một lần offer có nhiều thẻ relic (treasure, elite, boss, hoặc thẻ relic trong reward 3 thẻ): **chỉ thẻ relic đầu tiên là "thẻ dẫn"**. Hai thẻ còn lại chọn trung tính. Nghĩa là 1/3 nghiêng theo build, 2/3 để mở hướng mới.

Trọng số (số nguyên, để tất định) trong rarity đã chọn, mỗi relic hợp lệ `m`:
- `m = 4` (trung tính).
- Thẻ dẫn và relic chia ít nhất 1 lean tag: `m = 12`.
- Relic có layer payoff/engine/scaling, và đang có ≥2 enabler cùng tag: nhân thêm ×2 (nhấn mạnh "có enabler thì cần payoff").
- Relic payoff/engine mà `score` của mọi tag archetype của nó = 0 (không có nguồn): `m = 1` (hạ, không loại). Đây là "dead-draw mềm": `shatterpoint`, `keeneye` khi không có crit...
- Relic nhân mà ô tương ứng đã đầy (G hoặc A): `m = 1`. Nhận được nhưng phải bán một relic cùng ô nhân (§3.1).
- Khi đang giữ `hollowchalice`: `ear`, `tidecaller` `m = 1` (dead-draw, F-17).
- (SỬA SAU REVIEW 11/10) Dòng `m=1` cũ cho `twinfates` bỏ: đã thành loại cứng hai chiều ở §4.2 mục 6.

**Duo**: điều kiện đủ khi relic đang giữ (không tính chính nó) có ≥1 relic tag A **và** ≥1 relic tag B. Class của đội **không** tính cho duo (nếu tính thì duo xuất hiện từ đầu run). Duo vào offer với `m` như relic thường (trúng cả 2 lean tag thì nhận lean).
**Class upgrader**: đủ khi có ≥1 Axie class đó. Trúng lean tag của class thì nhận lean.

Ước lượng: giả sử 3 relic poison trong ~30 Epic hợp lệ, thẻ dẫn chọn poison với xác suất ≈ 3×12 / (3×12 + 27×4) = **25%**, so với 10% nếu chọn đều. Nghiêng nhẹ, không khoá.

### 4.4 Boss: màn Pact (chọn 1/3)

Màn reward boss giữ thẻ relic thường (E 70/L 30) và **thay thẻ `chaos`/`curse` bằng thẻ "Pact"**, mở màn chọn 1 trong 3. Luật mới (SỬA SAU REVIEW 11/10, Q3, F-07): **mỗi PACT chỉ nhận một lần/run** (không còn "mỗi nhóm một lần"), nên mọi boss đều hiện đủ 3 lựa chọn. Cách bốc ba pact (tất định, §4.5):

1. Lọc: bỏ pact đã nhận/đã bán trong run, pact loại cứng theo §4.2 mục 6, pact không đặt hợp lệ được (§3.1).
2. Còn ≥3 nhóm có pact: bốc **một pact từ mỗi nhóm**. Trong nhóm bốc đều theo pact (trọng số 4; pact nhân mà ô G/A đã đầy: trọng số 1). Không dùng E 70/L 30 nữa cho pact, vì nhóm đã quyết bậc.
3. Còn <3 nhóm: bốc theo thứ tự nhóm còn pact, rồi lấy thêm pact từ nhóm đã bốc cho đủ 3 (khác pact).
4. Còn <3 pact tổng: hiện số còn lại; còn 0 thì bỏ thẻ Pact (không treo).

Hệ quả: do mỗi thẻ đều có mỗi nhóm một pact, pact nhóm Mana (2 pact) hiện nhiều hơn pact nhóm Dice (4 pact) trên mỗi lần offer. Chấp nhận có chủ ý (giữ khác loại trên thẻ); khi đo pick rate (§6.2) so **theo lần được offer**, không so thô giữa nhóm.

Các nhóm:

| Nhóm | Pact |
|---|---|
| Reroll (hạn chế reroll) | `bloodpact` L, `twinfates` L, `lonewolf` E |
| Dice (làm xấu mặt) | `brittledice` E, `patientfang` L, `tithepips` E, `ironvow` E |
| Mana | `hollowchalice` E, `devilsreroll` E |

Người chơi có thể **bỏ cả 3** (không bắt buộc, trừ A6/A10), vì pact chiếm ô passive. Số pact tối đa một run bị giới hạn bởi số boss (run dài 4 boss = tối đa 4 pact), không còn bởi số nhóm. Khi ô đầy xem bảng luật §3.1 (kể cả pact ép ở A6/A10: hộp bán bắt buộc).
Giữ `curse` hiện tại cho tới khi code pact hoàn tất (quyết định 5); nó biến mất khi pact lên.

### 4.5 Tất định theo seed

`offer_seed = hash(run_seed, node_id, source_kind, offer_index, reroll_index)`. Danh sách ứng viên **sắp theo id tăng dần**, trọng số là số nguyên, chọn bằng tổng tích lũy và một `RandomNumberGenerator` seed bởi `offer_seed`; không dùng float, không phụ thuộc thứ tự UI hay thời gian. Đầu vào còn lại: id relic đang giữ (sắp theo id), class đội, số ô G/A đang dùng. Hàm thuần, nên đọc lại save hay chạy lại replay ra đúng offer cũ. `reroll_index` tăng mỗi lần reroll thẻ thưởng, nhờ đó ra thẻ mới nhưng vẫn kiểm lại được. SỬA SAU REVIEW 11/10 (§7 review): dùng đúng đường có sẵn `Rng.derive_combat_seed(run_seed, node_id, salt)` với salt tăng khi reroll (hiện `reroll_pending_rewards`), không thêm hàm hash mới.
Hàm này nằm trong `reward_generator.gd`, thuộc nhóm file bị fingerprint, nên đổi nó cũng nằm trong cùng một lần bump `RULES_VERSION` (§5).

## 5. Hook engine mới (8)

Tám hook, **gom làm một lần bump `RULES_VERSION`** sau khi Liam chốt bộ relic (quyết định 6). Chèn dự kiến theo audit §3.6 (số dòng là của audit, cần kiểm lại lúc làm). Quy ước chung: handler của hook mới gây damage thì damage đó có `attack:false, src:null, depth = depth gốc + 1` (§3.5), không kích HIT/DMG/crit.

| # | Hook | Chạy khi nào / ngữ nghĩa chính xác | Chèn ở | Relic cần |
|---|---|---|---|---|
| H1 | `before_reroll` / `on_roll_settled` | SỬA SAU REVIEW 11/10 (F-03). `before_reroll`: trước `reroll_dice` tiêu 1 charge, handler trả chi phí phụ (Mana) hoặc veto. `on_roll_settled`: chạy sau roll đầu lượt **và** sau mỗi reroll (sau cantrip, trước phase EXECUTE). **Hook ROLL-END hiện có (`on_roll_end`) giữ nguyên: chỉ chạy một lần mỗi lượt sau roll đầu, KHÔNG chạy lại khi reroll** (bản cũ của H1 nói "chạy lại mọi ROLL-END", làm `quickenroot` +1 growth mỗi reroll cho cả đội). `on_roll_settled` chỉ dành cho relic **không state**: handler phải là hàm thuần của các mặt đang hiện, ghi vào cờ/bonus theo-roll (xoá rồi gắn lại mỗi lần), không chạm bộ đếm hay giá trị vĩnh viễn. Dùng: `claw`, `symmetrycharm`, `linkstone`, `keeneye`, `tithepips` (cờ blank). Không dùng: `quickenroot` và mọi relic cộng dồn → ở `on_roll_end` | `combat_engine.gd` ~466/476 | `claw`, `devilsreroll`, `symmetrycharm`, `linkstone`, `keeneye`, `tithepips` |
| H2 | `on_face_used(unit, face, targets)` | Sau `_exec_face` xong, trước khi nhận input kế. Cho phép cộng buff cho die chưa dùng, thêm đòn phụ (depth+1) | `combat_engine.gd` ~739 | `carapace`, `barbedhide`, `regrow`, `hollowbone`, `keystone`, `relaybaton`, `crescendofang` |
| H3 | `on_turn_end` | Sau khi người chơi bấm End Turn, **trước** mana overflow nổ và trước pha địch. Thứ tự giữa relic: theo thứ tự nhận | `combat_engine.gd` ~1021 | `eggshell`, `broodbloom`, `heartrootgrove`, `amberdie` |
| H4 | `on_active_played(act_id, cost)` | Sau khi active xong, sau khi `mana_spent` đã cộng. Bộ đếm "mỗi N Mana tiêu" dùng `mana_spent // N` so với số lần đã thưởng | `combat_engine.gd` `play_active` ~501 | `ear`, `aegiscapacitor`, `wellspringroots`, `tideglass` |
| H5 | `on_combat_start` / `on_combat_end(result, node_kind)` | Start: sau `setup_new`, trước roll lượt 1 (khởi tạo bộ đếm theo trận). End: trong `get_result`, biết node là battle/elite/boss | `combat_engine.gd` | `heirloom`, `tideglass`, `amberdie`; tuỳ chọn chuyển `worldtree` sang hook này |
| H6 | `relic_state` (state theo run) | `RunState` giữ một dict JSON cho từng relic. Lưu qua `SaveStore`, khôi phục khi load. Tất định: chỉ do hành động trong run tạo ra nên replay dựng lại đúng, không cần ghi vào header replay | `RunState.gd`, `save_store.gd` | `heirloom`, `loadeddie`; tuỳ chọn `worldtree` |
| H7 | `roll_edit` | API sửa mặt sau roll: `tweak(kind, uid_a, uid_b)` với kind ∈ nudge/copy/swap/flip; hold qua `bank(uid)`; trọng số roll (`loadeddie`); roll 2 giữ cao hơn (`twinfates`); cờ `blank` (`tithepips`). Mỗi tweak là một action trong ActionLog để replay kiểm được (danh sách đầy đủ ở "Action mới" dưới) | `combat_engine.gd`, `unit.gd` (`set_roll` đã có), `action_log.gd` | `amberdie`, `mirrorpip`, `pipfile`, `twinswap`, `loadeddie`, `flipside`, `twinfates`, `tithepips` |
| H8 | `run_economy` | Ngoài combat. SỬA SAU REVIEW 11/10 (F-01): `shop_relic_count(base)`, `reward_card_count(kind)`, `reward_reroll_charges(base)` (+ chi phí 25 cho charge thêm), `on_relic_acquired`. **Bỏ `price_mod` và `income_mod`**: không relic nào được đổi giá hay thu nhập (§3.7). Không đi qua combat engine. Cờ A1 (giá ×1.15, bán 40%) làm thẳng trong `RunState`, không qua hook | `RunState.gd`, `reward_generator.gd` | `merchantscale`, `fortuneledger`, `scavengereye` |

**Ngân sách hook (SỬA SAU REVIEW 11/10):** vẫn đúng **8 hook (H1–H8)**, một lần bump. H1 trước đã là hai điểm vào (`before_reroll`/`after_reroll`); nay điểm thứ hai đổi tên `on_roll_settled` và hết chạy lại ROLL-END, nên không thêm hook mới nào. `on_roll_end` là hook sẵn có, không tính vào 8.

**Trạng thái và undo (F-09).** Mọi state mới của relic phải nằm trong `_state_dict` / `from_data` (`combat_engine.gd` ~189–232, ~689–703): ngân sách Tweak còn lại, bộ đếm `mana_spent` đã thưởng của `aegiscapacitor`/`wellspringroots`/`tideglass`, hoàn Reroll/lượt (kèm bộ đếm trần `relic_reroll_cap`), ramp `crescendofang`, bank `amberdie`, cờ `deathspiral` theo địch, `relic_state` theo trận, ngân sách Reroll nhận từ `a_chaos`. Nếu không: undo hoàn Mana mà không hoàn bộ đếm thì lặp "tiêu Mana, nhận Shield, undo" lấy thưởng vô hạn; save-resume giữa trận thì mất. Mỗi hook có test undo + save/resume (R13).

**Action mới trong ActionLog (F-10),** cùng một lần bump, mỗi cái có test `RunVerifier` và tamper: `reorder_party` (đổi thứ tự đội ở Map: ảnh hưởng LINK và 5 relic positional), `sell_relic`, `loaded_pick` (mặt khoá của `loadeddie`), `hold_pick` (die giữ của `amberdie`), `swap_on_full` (đổi khi ô đầy: relic bán + relic nhận, gồm hộp bán bắt buộc của pact ép), và các `tweak` (`nudge/copy/swap/flip`). `shop_buy`, `take_reward`, `reroll_rewards` đã có sẵn. `owned_relic_ids` giữ **thứ tự nhận** qua bán/đổi (H3 dùng thứ tự đó; bán rồi nhận lại thì ở cuối).

**Không phải hook nhưng cần code trong cùng lần bump** (liệt kê để không bị bỏ sót):
- Field `mult_axis` + bộ gộp trục G/A trong `relic_hooks.gd`, trần ×2.5 của G và 2 ô A (§3).
- Ô relic 8/3, bán 50%, chọn đổi khi đầy (`RunState.gd`), kèm bảng luật ô đầy §3.1 (ô nhân, pact ép, bán pact).
- `pick_relic` viết lại theo §4 (hai bước, điểm tag, `exSub`, duo/class gating, tách pact).
- `RelicDef`: `tags` (≤2) thay `archetype` đơn, `layer`, `mult_axis`, `pact_group`, `requires_class`. 44 file `.tres` mới, 19 + 2 sửa, 6 xóa (SỬA SAU REVIEW 11/10: 45 → 44).
- 6 NEW FIELD cho class upgrader (đọc trong `ContentDB.CLASS_PASSIVE` runtime, không đổi data gốc).
- Biến `depth` ở pipeline và quy tắc KILL độ sâu 1 (§3.5).
- Hàm `is_wounded(tgt, threshold=0.5)` duy nhất (§3.5), dùng cho FERAL, `scentofblood`, `deathspiral`, `coupmark`, `dawnlance`, và đọc `carrioncall`. Thay mọi chỗ viết thẳng `tgt.hp < max_hp*0.5` ở `damage_pipeline.gd` ~46–48.
- `on_kill` ctx thêm `killer` (cho `alphafang`; `damage_pipeline.gd` ~210–215). Kill do tick/thorns/relic có `killer = null`.
- Trục G theo từng Axie: `axie_g_bonus` thay nhân `oc` trên mặt dmg (§3.3), `RunState.gd` ~607–616, ~731–738.
- Trần Reroll nhận từ relic (`relic_reroll_cap`, §3.6).
- Trần Reroll nhận từ active ≤6/lượt (`a_chaos`).
- Đổi thứ tự đội ở màn Map (UI + `RunState`) và đọc `slot` của Unit cho 5 relic positional; dùng cùng định nghĩa "kề" với LINK (`combat_engine.gd` ~751, kiểm lại).
- Cập nhật `t_rules_version` (danh sách file fingerprint) và `RULES_VERSION` một lần.

## 6. Kế hoạch cân bằng

Hiện không có sim cân bằng relic trên Godot (audit §0; `godot/tools/run_bot.gd` chưa đọc). Mọi số trong file này là **số đoán đợt đầu**. Bước 6 là điều kiện để chốt số, không phải việc làm sau.

### 6.1 Cần sim gì

| Sim | Cách chạy | Đo gì |
|---|---|---|
| **A. Bot cam kết archetype** | 11 bot, mỗi bot ưu tiên relic theo một archetype (và đội class tương ứng), 300 seed/bot, cùng Ascension cố định (đề xuất mức Ascension 0 làm chuẩn; lặp lại ở một mức cao khi 3b xong) | Winrate mỗi archetype, độ dài run, số relic cuối run |
| **B. Bot tham lam** | Chọn relic có điểm cao nhất theo bảng đơn giản, không cam kết | Relic nào là pick bắt buộc (có trong >70% run thắng), relic nào hiếm khi được chọn |
| **C. Bot pact** | Bot A + chọn pact tốt nhất theo mô hình giá trị đơn giản, và biến thể không nhận pact | Pact nào quá mạnh/yếu, nhận pact có làm winrate tăng không |
| **D. Bot kinh tế** | Bot A với và không với 3 relic economy | Giá trị trung bình của economy relic so với relic thường; Shard bank cuối run không chênh (R14) |
| **A+. Cộng phẳng** (SỬA SAU REVIEW 11/10, F-12, Q6) | Bot A, ghi lại tổng "dmg cộng phẳng từ relic" trên mỗi mặt dmg theo lượt | Phân phối tổng cộng phẳng/mặt; tỉ lệ dmg run đến từ cộng phẳng so với từ G/A. **Không có trần** theo quyết định Q6; số này là cơ sở để Liam xét lại nếu lệch |
| **E. Soak phá vỡ** | 2000 run seed ngẫu nhiên, mọi pool, tìm: vòng lặp vô hạn, NaN/âm, trần bị vượt, replay verify fail | Lỗi hard |

### 6.2 Mục tiêu (cổng pass)

- **Winrate theo archetype ở Ascension cố định nằm trong 35–60%** (không archetype nào >60%, không archetype nào <35%). Chênh giữa archetype mạnh nhất và yếu nhất ≤ 25 điểm.
- **Reach** (tỉ lệ run bot A chạm được payoff + engine của archetype đó) ≥ 40%. Nếu thấp hơn là offer quá thưa, chỉnh lean/trọng số chứ không chỉnh số relic.
- **Không relic "bắt buộc"**: không relic `uni` nào (`echostone`, `ancientgene`, `dawnlance`, `claw`) có mặt trong >70% run thắng của mọi archetype.
- **Delta winrate theo relic** (có vs không có, trong cùng archetype): mọi relic trong [−8, +12] điểm. Ngoài khoảng: sửa số hoặc rarity.
- **Pick rate pact** trong 25–60% khi được offer (dưới 25% nghĩa là drawback quá đau, trên 60% nghĩa là quá lợi).
- **Thời gian giết** (TTK) mỗi archetype: không archetype nào có TTK trung bình ngắn hơn 60% hoặc dài hơn 140% trung bình các archetype khác.
- **Trần G chạm**: tỉ lệ run có **ít nhất một Axie** với `G_axie` bằng 2.5 ≤ 5% (nếu cao hơn, trần quá thấp hoặc `ascend` quá hào phóng).

### 6.3 Núm chỉnh (tất cả nằm trong data, không hardcode: `.tres` của relic và một `relic_tuning.tres` mới)

| Núm | Loại | Mặc định | Khoảng | Lý do |
|---|---|---|---|---|
| Ô passive / active | gate | 8 / 3 | 6–10 / 2–4 | Quyết định 1 |
| Tỉ lệ bán | curve | 50% | 25–60% | Sink in-run; không relic nào đổi (SỬA SAU REVIEW 11/10) |
| Trần G (theo từng Axie, chỉ mặt dmg) | curve | ×2.5 | ×2.0–3.0 | Thay mload; Q2 |
| `relic_reroll_cap` (Reroll nhận từ relic/lượt) | gate | 4 | 2–6 | F-22; `a_chaos` có trần riêng 6 |
| Số ô A | gate | 2 | 1–3 | Quyết định 2 |
| Trọng số rarity mỗi nguồn | gate | §4.1 | ±15 điểm | Tốc độ ra Legendary |
| `lean_m` (thẻ dẫn) | feel | 12 so với 4 (×3) | ×2–×5 | Mức nghiêng |
| `needs_source_m`, `slot_full_m` | feel | 1 so với 4 | 0–4 | Mức tránh dead-draw |
| Ngân sách Tweak | feel | 2/lượt | 1–3 | Quá cao thì thành "chỉnh hết" |
| Trần Reroll từ active | gate | 6/lượt | 4–8 | Chặn Chaos + Conduit Crown |
| Trần crit chance | curve | 75% | 60–85% | Hyperbolic |
| Số của từng relic (+N, %, mỗi N Mana) | curve | cột Effect §1 | ±30% | Chỉnh sau sim |
| Giá shop | gate | 45/75/120/180 | | Giữ như hiện tại |
| Cap `heirloom`, `tideglass`, `crescendofang` | curve | +5 / +6 / không | | Ba nhịp reset §2.6 |
| Bonus economy (shop 3 relic, 25 tiền cho charge thêm, 4 thẻ) | curve | §1.5 | | Không đổi dòng tiền; economy-designer xác nhận R14 |

### 6.4 Invariant (mỗi cái có test tự động)

| # | Invariant |
|---|---|
| R1 | `G_axie ≤ 2.5` mọi lúc cho từng Axie (chỉ mặt dmg); tối đa 1 relic `mult_axis = G`; `ascend`/`forge` trên Axie khác không đổi `G_axie` của Axie này |
| R2 | Tối đa 2 relic `mult_axis = A:*` |
| R3 | Passive ≤ 8, active ≤ 3 (4 nếu có `hollowchalice`) |
| R4 | Damage relic có `depth ≤ 1`, không bao giờ kích HIT/DMG/crit; không vòng nổ vô hạn |
| R5 | Drawback pact chỉ ở xúc xắc, reroll, Mana: không relic nào giảm Max HP của đội; HP vẫn hồi đầy mỗi trận |
| R6 | Không relic hay hook H8 ghi vào Gene Shard hoặc meta (so sánh meta save trước/sau mỗi run test) |
| R7 | Offer tất định: cùng (seed, state) cho cùng offer, 1000 lần; reroll_index đổi thì đổi offer |
| R8 | Mọi relic ≤2 tag, có layer, id duy nhất, không nhắc id quái hay roster Chimera (quét data) |
| R9 | Mỗi archetype ≥2 enabler, ≥2 payoff, ≥1 engine, đếm **theo layer**, trong đó `scaling` tính cho enabler **hoặc** payoff (F-14: `crescendofang` layer scaling nằm cột enabler của §2.1); mỗi archetype ≥2 duo |
| R10 | Tweak ≤ 2/lượt; mọi tweak có action trong ActionLog; replay full-run qua `RunVerifier` pass, và 3 tamper (tweak thứ 3, tweak lên die đã dùng, tweak bởi relic không sở hữu) bị bắt |
| R11 | Poison/Burn không vượt 30 stack/địch (chống vòng `fumeblossom` + `venomengine`); `fumeblossom` tối đa 1 lần/địch/lượt mỗi chiều |
| R12 | Số relic pool = **133**, **44** mới, đúng số theo rarity ở §0 (C 26 · R 31 · E 51 · L 25) và layer (economy 3) (test đếm). SỬA SAU REVIEW 11/10 |
| R13 | Undo không tăng ngân sách/bộ đếm của bất kỳ relic nào (Tweak, `mana_spent` thưởng, hoàn Reroll, ramp); save-resume giữa trận khôi phục đúng mọi state relic (F-09) |
| R14 | Shard bank cuối run bằng nhau giữa run có và không có 3 relic economy khi chi tiêu giống nhau; `tithepurse` không tồn tại trong data (F-01) |
| R15 | `on_roll_end` chạy đúng 1 lần/lượt dù có bao nhiêu reroll; `on_roll_settled` chạy 1 + số reroll lần; `quickenroot` +1 growth/lượt tối đa (F-03) |
| R16 | Mỗi pact tối đa một lần/run; thẻ boss luôn hiện 3 pact khi còn ≥3 hợp lệ; không bao giờ có hộp bán không lối thoát (F-07, F-08) |

### 6.5 Rủi ro cao cần sim đầu tiên

0. **Ưu tiên sim số 1 (F-12, Q6, SỬA SAU REVIEW 11/10): các relic cộng phẳng trên mặt dmg, không có trần.** `brittledice` +4, `patientfang` đến +14, `bookend` +3, `tideglass` +6, `heirloom` +5, `towershield` +6, `soulforge` +6, `deathmark` (không trần/trận), `claw` +4, `symmetrycharm` +3, `linkstone` +2, `relaybaton` cộng dồn, cộng `echostone` nhân đôi mặt đầu. Đo sim A+ (§6.1): tổng cộng phẳng/mặt khi build giữ 5–6 cái này. Liam đã quyết không thêm trần mềm; nếu sim cho thấy trần G thành trang trí thì báo lại để Liam xét.
1. `lonewolf` và `bloodpact` đều +60–100% ở ô G: nếu delta winrate >+12 thì giảm hệ số.
2. `patientfang` (+14 dmg ở lượt 8, lượt 1 = 0): build chậm có thể quá mạnh ở trận dài và quá yếu ở trận ngắn.
3. `twinfates`: cả 5 Axie roll 2 lần giữ mặt cao hơn, kỳ vọng mặt tốt hơn rõ; có thể mạnh hơn mọi pact còn lại dù mất reroll.
4. `fumeblossom` + `wildfire` + `rotmouth`: vòng khuếch đại hai chiều.
5. `aegiscapacitor`, `wellspringroots`, `tideglass`: ba relic cùng đếm `mana_spent`, cộng với `tidecaller`.
6. `relaybaton`: chuỗi cộng dồn trái sang phải có thể ra số lớn nếu có Echo Stone.
7. `scavengereye` (4 thẻ) cộng `fortuneledger` (reroll): số lần xem offer tăng mạnh, nhân hiệu quả của lean.
8. `a_chaos` đã cap; kiểm tra thêm `devilsreroll` (+3 reroll tốn Mana) với `a_chaos`.

### 6.6 Tiêu chí chấp nhận

**Chức năng (tự động):** R1–R12 xanh; mỗi hook H1–H8 có test riêng (hook chạy đúng thời điểm, đúng số lần, không tự gọi vòng); `t_rules_version` cập nhật và xanh; `t_replay` và `t_full_run_loop` xanh với bộ relic mới; Worker không đổi.
**Sim:** các cổng ở §6.2 đạt trên sim A, B, C, D với ≥300 seed mỗi bot.
**Trải nghiệm (playtest):** (1) người chơi mô tả được build mình đang đi bằng một câu sau 3 relic; (2) ít nhất một lần mỗi run người chơi dừng suy nghĩ ở một quyết định giữa trận mà không phải "bấm cái số to nhất" (ghi nhận bằng hỏi miệng); (3) người chơi mới trận 1–3 không thấy relic mà không hiểu; (4) thấy ô đầy và hiểu vì sao; (5) ở boss, pact tạo tranh luận "cái nào" chứ không phải luôn chọn một cái.

## 7. Câu hỏi mở cho Liam

Đề xuất của mình ghi ở cột phải. Liam quyết.

| # | Câu hỏi | Đề xuất |
|---|---|---|
| 1 | **Blood Pact thành rework thứ 19.** Quyết định 5 cấm drawback HP, mà bản cũ là −15% Max HP. Đổi sang "Reroll max −2". Chấp nhận con số 19 thay vì 18? | **Có.** Chạy ngược lại thì phải bỏ Blood Pact khỏi pool |
| 2 | Hạ 6 relic rework (Keen Ears, Gustwing, Lunacia Heart, Talon Edge, Eggshell Ward, Lucky Scale) từ Rare xuống Common để pool Common không chỉ có 20? | **Có.** Trận thường chỉ ra Common/Rare nên cần đủ Common. Nếu Liam không muốn đổi rarity thì phải thêm ~7 Common mới |
| 3 | `ascend` (reward) và `forge` (event) cộng vào trục G, chặn tổng ×2.5. Chấp nhận đổi hành vi "ascend không trần"? | **Có.** Nếu không, luật G chỉ chặn relic mà không chặn nguồn lớn nhất |
| 4 | Class passive có hệ số nhân gốc (FERAL ×1.6, LINK ×1.15) nằm ngoài ô nhân và class upgrader không được nâng hệ số. Chấp nhận? | **Có.** Giữ class như "luật nền", relic chỉ đổi ngưỡng/điều kiện |
| 5 | Tweak: chọn bằng click-click (bấm nút relic rồi bấm die), ngân sách 2/lượt. Chấp nhận UI này, hay bắt buộc auto để khỏi làm UI mới? | **Click-click.** Auto tước quyết định; `ui-programmer` ước lượng trước |
| 6 | Pact chiếm ô passive (như relic thường), mỗi nhóm drawback một lần/run (tối đa 3 pact)? Hay có ô pact riêng? | **Ô passive.** Pact phải đánh đổi với một relic khác, đó là cái giá thật. *(SỬA SAU REVIEW 11/10: "mỗi nhóm" bị thay bằng "mỗi pact một lần/run", Q3.)* |
| 7 | KILL độ sâu 1: kill do relic damage vẫn kích relic KILL nhưng handler đó không kích tiếp. Chấp nhận, hay cấm hẳn (relic damage không bao giờ kích gì)? | **Độ sâu 1.** Cấm hẳn làm Death Spiral + Broodmother hết cộng hưởng |
| 8 | Duo chỉ đếm tag của **relic đang giữ**, không đếm class của đội. Chấp nhận? | **Có.** Nếu đếm class thì duo xuất hiện ngay trận 1, mất cảm giác "đi hướng" |
| 9 | Có pity cho Legendary không (đảm bảo trong N lần offer)? Hôm nay không có và Legendary hiếm hơn trước (boss 30%, elite 15%) | **Chưa.** Chờ sim reach (§6.2) rồi quyết |
| 10 | Pool 134 relic, 45 mới: vượt mốc "~130" của yêu cầu. Chấp nhận? Cắt thì cắt nhóm nào? | **Giữ 134.** *(SỬA SAU REVIEW 11/10: đã thành 133 vì Liam bỏ `tithepurse`, Q1.)* |
| 11 | Tên tiền in-run: file này gọi "tiền in-run" vì chưa xác nhận tên hiện tại trong code. Ai kiểm? | *(SỬA SAU REVIEW 11/10: đã xác nhận, tiền in-run = Gene Shard, `shards_this_run`, §3.7.)* |
| 12 | `Fortune's Ledger` cần UI reroll reward (hiện chưa chắc có). Cắt relic này nếu UI quá tốn? | *(SỬA SAU REVIEW 11/10: reroll thẻ thưởng **đã có** (`reroll_pending_rewards`, `reward_reroll_max` = 1 từ meta). Relic chỉ cộng 1 charge, tốn 25; UI chỉ cần hiện thêm charge. A10 không offer.)* |
| 13 | `twinfates` làm chết các relic cộng Reroll. Chấp nhận như một drawback có chủ ý, hay loại hẳn `twinfates`? | **Chấp nhận**, và hạ `m` trong offer (§4.3) để người chơi không bị nhử |
| 14 | Một lần bump `RULES_VERSION` sau khi chốt: ai chốt "bộ relic đã khoá" để bắt đầu code hook? | Liam, sau khi review file này và có sim sơ bộ trên bản data (chưa cần hook) |
| 15 | **MỞ (SỬA SAU REVIEW 11/10, F-04).** Nguồn reroll **không phải relic** có vào loại trừ với `twinfates` không: thẻ reward `reroll`, shop item `reroll`, event `bless_reroll`, `curse` (+1 reroll)? Nếu không: đang giữ `twinfates` thì các thẻ đó là dead-draw lộ ra cho người chơi | **LIAM 11/10: CÓ** cho thẻ reward `reroll`, shop `reroll`, event `bless_reroll` — đã áp ở §4.2 mục 6. `curse` cũng loại (Liam 11/10) |
| 16 | **MỞ nhỏ (F-02).** Mặt Shield/Heal/Mana vẫn nhân `oc` dồn (1.25^n) và không có trần mới. Có chặn ×2.0 cho mặt phi sát thương không? | **LIAM 11/10: CÓ** — chặn ×2.0, đã áp ở §3 |

## 8. Relic chạm Ascension (chỉ ghi nhận, 3b làm sau)

Chỉ liệt kê điểm chạm; luật Ascension thiết kế ở 3b. Ràng buộc Liam đã chốt: luật cố định theo level, tất định, ranked kiểm replay được.

| Chỗ chạm | Điều 3b cần biết |
|---|---|
| Số ô passive (8) | Có thể giảm theo level (7, 6). Mọi relic đã tính theo 8, nên giảm ô là núm sạch |
| Tỉ lệ bán (50%) | Có thể giảm theo level (A1 = 40%). `merchantscale` không còn đụng tỉ lệ bán hay giá (SỬA SAU REVIEW 11/10) |
| Pact | Ascension có thể khoá pact đầu tiên hoặc đổi "bỏ cả 3 pact" thành không được bỏ. Luật chọn pact đang cho phép bỏ (§4.4). Sau Q3 (mỗi pact một lần) luôn có ≥3 pact hợp lệ ở boss thứ 3; pact ép khi ô đầy dùng hộp bán bắt buộc (§3.1) |
| Rarity weight | 3b có thể lệch trọng số theo level (ví dụ giảm Legendary), cùng bảng §4.1 |
| Sticker lên relic (bài học Balatro: Eternal/Perishable) | Cần thêm field `sticker` cho relic trong `RunState`; replay phải ghi được. Hook H6 là chỗ lưu tự nhiên |
| Ô G và trần ×2.5 | Có thể giảm trần theo level (×2.2) |
| Ngân sách Tweak | Có thể giảm 2 → 1 theo level |
| Economy relic | `merchantscale` giờ chỉ thêm 1 slot relic trong shop nên không tương tác với giá A1. `fortuneledger` không offer ở A10 (không còn reroll thẻ thưởng) |

Không thay đổi gì ở file này cho tới khi 3b được Liam duyệt.
