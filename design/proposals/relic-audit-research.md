Trạng thái: ĐỀ XUẤT — chờ Liam review

> **QUYẾT ĐỊNH LIAM (10/10, 12 câu §7) — ràng buộc cho bước 3:**
> 1 giới hạn 8 ô passive + 3 ô active riêng, bán lại 50% · 2 thay `mload` bằng 1 ô nhân toàn cục + tối đa 2 ô
> nhân theo archetype · 3 offer nghiêng nhẹ theo build (1/3 thẻ ưu tiên tag đang có), relic duo chỉ ra khi đủ
> 2 tag, vẫn deterministic theo seed · 4 trọng số trong từng bậc hiếm (vd boss 70% Epic / 30% Legendary) ·
> 5 relic pact chỉ ở boss, chọn 1/3, thay chaos/curse; drawback vào xúc xắc/reroll/mana, không đụng HP · 6 duyệt
> thêm 6–8 hook engine, bump `RULES_VERSION` một lần sau khi chốt bộ relic · 7 cho đổi thứ tự đội tự do ở màn
> map giữa các trận · 8 relic kinh tế chỉ chạm tiền trong run, không bao giờ cho Gene Shard · 9 duo = 12 cặp
> archetype chọn tay + 6 relic nâng passive class · 10 chưa làm keepsake · 11 sửa 6 tag sai, cho phép 2 tag/relic
> · 12 Ascension luật cố định từng level (ranked kiểm replay được).

# Relic: audit hiện trạng + nghiên cứu (bước 1–2 của relic redesign)

Tác giả: game-designer · 2026-10-10. Chưa có code, chưa sửa file nào khác. Bước 3 (bộ relic mới) chỉ làm sau khi Liam duyệt file này.
Ràng buộc đã chốt (Liam, `core-loop-v2.md` đầu file): giữ chiều sâu combat, chỉ thêm; không đổi archetype; không enemy counter-trait; giữ luật hồi đầy HP mỗi trận; quái sẽ thành Atia 3D nên relic không được dựa vào roster Chimera.
Chỗ nào chưa verify trên Godot thì ghi rõ. Số winrate/playrate cũ đều từ sim của bản JS (đã xoá ở commit `5e34a17`), trong `godot/tools/` chỉ thấy `run_bot.gd` (chưa đọc), không thấy sim cân bằng relic.

## 0. Đọc nhanh

1. **Pool 94 relic không "linh tinh", nó thiếu tầng.** 66 relic có luật hợp lý, nhưng 54% passive chỉ sửa sẵn cái die trước trận (cộng số hoặc gắn keyword), 0 relic economy, 0 relic chỉnh xúc xắc sau khi roll, 0 relic dùng vị trí đội hình, 1 relic pact, 1 relic mang trạng thái qua nhiều trận.
2. **Hai luật chống stack nằm trên giấy, không nằm trong code Godot.** `mload` chỉ là field, không ai đọc; `ex`/`exSub`/`RELIC_CAP` không tồn tại trong `RelicDef`. Offer là chọn đều ngẫu nhiên trong band rarity. Nghĩa là Blood Pact + Ancient Gene + Dawn Lance cùng một run hôm nay là hợp lệ.
3. **Engine có sẵn nhiều thứ chưa relic nào dùng** (Resonance LINK, `poisonSpread`, `last_big`, `mana_spent`, status `vulnerable`/`stun`, 9 keyword). Đây là đường rẻ nhất để làm relic mới mà chưa cần code.
4. **Thiếu hook** cho các relic hay nhất của game khác: on_reroll, on_face_used, on_turn_end, relic state theo run. Mỗi hook thêm vào `scripts/core` làm đổi fingerprint `RULES_VERSION` (`t_rules_version`), tức replay cũ hết hiệu lực.

## 1. Relic hôm nay hoạt động thế nào

### 1.1 Hook và trigger có trong engine

| Trigger | Gọi ở | Số relic dùng | Ghi chú |
|---|---|---|---|
| `mod_face` / `mod_face2` (sửa die lúc dựng unit) | `relic_hooks.gd:870` `apply_mod_faces`, gọi từ `combat_engine.gd:1265` | 31 | Thứ tự INV-5: keyword → cộng phẳng → nhân (`relic_hooks.gd:827,839`). Chạy cả trên Egg nếu có `eggInherit` (`:1290`) |
| `on_turn_start` | `combat_engine.gd:167` (lượt 1) và `:1093` | 14 | Trước roll. Muốn "đầu trận" phải tự check `turn == 1` |
| `on_roll_end` | `combat_engine.gd:379` | 2 | Sau roll + cantrip, còn reroll được |
| `mod_dmg` | `damage_pipeline.gd:54` | 5 | Chỉ khi nguồn là Axie phe mình, trước crit |
| `on_hit` | `damage_pipeline.gd:167` | 4 | Nguồn là Axie phe mình, `dealt > 0` |
| `on_kill` | `damage_pipeline.gd:215` | 5 | Chỉ địch chết |
| `on_shield` | `damage_pipeline.gd:207` | 2 | Chỉ shield lên phe mình |
| `on_thorns` / `on_dmg_taken` | `:165` / `:124` | 2 / 1 | Chỉ khi mục tiêu là phe mình |
| `growth_all_guard` | `combat_engine.gd:1118` | 1 | |
| Field aggregate (sum/has/max/mul) | `relic_hooks.gd:915-940` | 18 passive + phần lớn relic có hook | `dmgMult`, `dr`, `critBonus`, `critMult`, `thornsMult`, `burnMult`, `poisonTicks`, `plague`, `firstEcho`, `actReuse`, `tokenCap`... (khai báo `relic_def.gd:81-123`) |
| Active card (`act`) | `combat_engine.gd:501` `play_active` | 16 | Tốn Mana, 1 lần/lượt/thẻ, reset mỗi lượt (`:1088`). Không có hook "khi dùng active" |

60 passive có script trong `TABLE`, 18 passive thuần data, 16 active. (Comment đầu `relic_hooks.gd` nói "ships ZERO real relics", đã cũ.)

Luồng một lượt (`combat_engine.gd`): roll mỗi Axie 1 mặt (`:382`) → reroll tối đa `max_rerolls` (mặc định 2, `:140`) → dùng mặt/active → end turn (mana dư nổ nếu có `manaOverflow`, `:1031`) → địch đánh → tick status (`status_engine.gd:91`). Mana giữ nguyên cả trận; reroll hồi đầy mỗi lượt (`:1087`). Class passive nằm ở `ContentDB.gd:119-132`, 11 archetype ở `:802-829` (tracker UI, không đọc trong gameplay: `relic_def.gd:36`).

Pipeline damage (`damage_pipeline.gd:44-65`): Execute ×1.6 → Pierce → `dmgMult` → `mod_dmg` → Crit. Poison/burn/thorns đi qua nguồn `null` hoặc đường riêng nên **không dính** `dmgMult`/`mod_dmg`/crit. Damage do relic gây ra (`attack:false`, `src:null`) không kích `on_hit`, tức đã có sẵn "proc coefficient = 0" cho chuỗi relic.

### 1.2 mload, trùng lặp, rarity, offer

| Mục | Hiện trạng | Nguồn |
|---|---|---|
| `mload` (trần nhân damage = 2) | Field có trong 94 .tres nhưng **không có chỗ nào đọc**. Doc `relic-system.md` §3.6 mô tả luật, code Godot chưa port | grep `mload` trong `godot/*.gd`: chỉ `relic_def.gd:39`, comment `reward_generator.gd:286`, comment `combat_engine.gd:1289` |
| Trùng lặp | Chỉ loại theo `id` đã sở hữu/đã được offer. Không có `ex`/`exSub`/`KW_EX`/`RELIC_CAP` | `reward_generator.gd:290-300`, `RunState.gd:619` |
| Rarity | 0 Common 16 · 1 Rare 29 · 2 Epic 28 · 3 Legendary 21 (gồm active). Không có Mythic | `relic_def.gd:32` |
| Chọn relic | `pick_relic` chọn **đều** trong band rarity, không trọng số rarity, không thiên về build đang có | `reward_generator.gd:290` |
| Band theo node | Battle thường [0,1] (sau pw>6: [0,2]); mỗi 3 step [1,2]; elite [1,3]; boss [2,3] | `:68-75` |
| Nguồn relic | Reward 3 thẻ (relic có 2–4 phiếu trên 6–11 phiếu trong pool, `:116-134`), shop 2 relic/lần giá 45/75/120/180 (`:59,307`), treasure (reward tier 1), event `chest`/`gamble_legend`/`bet_small`, reward `chaos` (relic Epic+ đổi −20% Max HP, `:247`), relic khởi đầu từ meta `u_start` (Common, không active) | `RunState.gd:244-254,698-756` |
| Số relic mỗi run | **Ước tính** 4–8 trong một run short thắng (≈13 trận có reward, mỗi lần ~1 thẻ relic trong 3 thẻ, thêm shop và treasure). Chưa đo; không có `RELIC_CAP` nên không có trần | tính từ pool, chưa verify bằng sim |

Hệ quả của "chọn đều": ở reward boss, Legendary chiếm 21/49 ≈ 43% số relic hợp lệ (Epic + Legendary), ở elite ≈ 27%. Không có cơ chế nào đảm bảo người chơi thấy payoff của archetype mình đang đi.

Hai nguồn nhân damage nằm **ngoài** mọi luật relic: reward `ascend` (+25% cả 6 mặt, "stacks without limit", `reward_generator.gd:240`) và event `forge` (×1.3, `RunState.gd:736`).

## 2. Bảng 94 relic

Rarity: C/R/E/L. Cat: **F** flat hoặc nhân trần (không điều kiện) · **C** conditional · **S** scaling · **R** rule-bending (thêm luật/trigger) · **A** active · economy: không có relic nào. Trigger: `build` = sửa die lúc dựng; `agg` = field đọc trực tiếp. Số liệu theo `.tres` và `relic_hooks.gd`.
Archetype là tag trong `.tres`; tag sai/lạ ghi trong cột lý do.

| id | Tên | R | Arch | Trigger | Effect | Cat | Verdict và lý do |
|---|---|---|---|---|---|---|---|
| claw | Razor Claw | C | exec | build | Mọi mặt dmg +1 | F | REWORK: thuần số; tag exec sai (dùng cho mọi build) |
| carapace | Stone Carapace | C | shield | build | Shield/Heal +2 | F | REWORK: thuần số |
| pierceall | Piercing Horn | C | pierce | build | Mặt Horn có Pierce | R | KEEP: on-ramp TALON (nhưng ⊂ worldpiercer) |
| cleaveall | Sweeping Tail | C | aoe | build | Mặt Cleave/AoE +2 | F | REWORK: số, ít mặt dính |
| bloodmouth | Bloodmouth | C | exec | build | Mặt Mouth có Lifesteal, +2 HP | R | KEEP: tag exec sai (Lifesteal không liên quan) |
| gorehook | Gorehook | C | exec | build | Mặt dmg Horn/Tail có Execute | R | KEEP: on-ramp FERAL (⊂ apexferal) |
| broodpouch | Brood Pouch | C | summon | agg | Đầu trận có 1 Egg | R | KEEP: enabler SWARM |
| barbedhide | Barbed Hide | C | thorns | build+agg | Thorns +1 dmg, Shield +1 | F | REWORK: thuần số |
| tidalbrand | Tidalbrand | C | mana | build+T-start | Mặt Ears +1 Reroll, +1 Reroll đầu trận | R | KEEP: Common hay nhất, chạm vào reroll |
| predatorpoise | Predator's Poise | C | crit | agg | Crit sống qua reroll | R | KEEP: chết nếu không có nguồn crit; cần enabler |
| seedling | Seedling Core | C | growth | agg | Mọi mặt +1 growth/lượt | S | KEEP |
| lastwall | Last Wall | C | shield | T-start | Axie yếu nhất có Undying | R | KEEP |
| rotbite | Rot Bite | C | poison | mod_dmg | Địch poison nhận +2/đòn | C | MERGE vào "status → thêm damage" |
| tinderbox | Tinderbox | C | burn | mod_dmg | Địch burn nhận +2/đòn | C | MERGE: cùng luật với rotbite |
| scentofblood | Scent of Blood | R | exec | mod_dmg | Địch <50% HP nhận +4 | C | KEEP: cặp tự nhiên với Dawn Lance |
| ear | Keen Ears | R | mana | build | Mặt Mana +1 | F | REWORK |
| bloomscale | Bloomscale | R | growth | build+agg | Back/Eyes có Growth, Growth +4 | R | KEEP |
| deathmark | Death Mark | R | exec | kill | Mỗi kill: mọi mặt dmg +1 hết trận, +2 HP | S | KEEP: snowball đúng nghĩa |
| gustwing | Gustwing | R | aoe | agg | Cleave 75% thay 50% | F | REWORK: mload 1 cho hiệu ứng nhỏ |
| heart | Lunacia Heart | R | shield | build | +12 Max HP | F | REWORK: không đổi quyết định nào |
| bloodthorn | Bloodthorn | R | thorns | taken | Bị đánh: hồi ⅓ Thorns; Shield +1 | C | KEEP |
| talonedge | Talon Edge | R | pierce | build | Mặt Pierce +2, Horn +1 | F | REWORK |
| voidgene | Void Gene | R | mana | build+T-start | +2 reroll max, +1 Mana lượt 1 | F | MERGE vào infinitedie (gần như bản nhỏ) |
| marrowdrill | Marrow Drill | R | pierce | build | Mặt Pierce dmg gắn Weaken 2 | R | KEEP |
| wildfire | Wildfire | R | burn | build+tick | Burn −1/lượt thay vì nửa; Horn gắn Burn 6 | R | KEEP |
| rotmouth | Rotmouth | R | poison | build | Mouth dmg gắn Poison 2 | R | KEEP |
| broodmother | Broodmother | R | summon | kill | Mỗi kill nở 1 Egg, Egg +1 dmg | R | KEEP: relic SWARM hay nhất |
| heartwood | Heartwood | R | growth | agg | Từ lượt 2 mọi mặt +2 growth/lượt | S | KEEP |
| luckycharm | Lucky Scale | R | crit | agg | +35% crit chance | F | REWORK: số; cộng dồn với apexpredator thành 70% |
| bloodhymn | Blood Hymn | R | crit | hit | Crit +2 Mana | R | KEEP: cầu nối crit→mana |
| squallmark | Squallmark | R | aoe | build | Eyes heal/debuff thành AoE | R | KEEP |
| holyfont | Sacred Font | R | shield | agg | Heal cũng cho Shield bằng số hồi | R | KEEP |
| spines | Sharp Spines | R | thorns | T-start | Cả đội Thorns ≥2 | R | MERGE: chết khi có scalecrown; Reptile đã có sẵn |
| ember | Ember | R | burn | hit | Đòn ≥4 dmg gắn Burn 2 | R | KEEP: mở burn cho mọi build |
| hivemind | Hive Mind | R | summon | agg | +1 dmg mọi mặt mỗi Egg sống | S | KEEP: scaling theo số đếm |
| eggshell | Eggshell Ward | R | summon | T-start | Egg +2 Shield/lượt | F | REWORK: số nhỏ trên token |
| openwound | Open Wound | R | poison | mod_dmg | Địch poison nhận +30% | C | MERGE (cùng họ rotbite) |
| growthcore | Growth Core | E | growth | build | Mặt dmg có Growth, +1 dmg, +2 HP | S | KEEP |
| apexbrood | Apex Brood | E | summon | T-start | Egg +8 HP, +2 dmg | F | REWORK: stat-stick trên token |
| thousandcuts | Thousand Cuts | E | pierce | build | Pierce đánh 2 lần, mỗi lần nửa +2 | R | KEEP |
| regrow | Regrowth Bud | E | shield | T-start | Cả đội Regen 2, +2 HP | F | REWORK: HP hồi đầy mỗi trận nên Regen ít giá trị |
| pandemic | Pandemic | E | poison | kill | Địch chết lan nửa poison | R | KEEP |
| shatterpoint | Shatterpoint | E | crit | agg | Crit xuyên Shield, +5 | R | KEEP |
| retributor | Retributor | E | thorns | thorns | Thorns của Axie có Shield lan ⅓ sang hàng xóm | R | KEEP |
| keeneye | Keen Eye | E | crit | roll-end | Nếu chưa ai crit thì đòn đầu crit; crit +4 | R | KEEP: relic crit tốt nhất |
| pyroclasm | Pyroclasm | E | burn | tick | Burn lan nửa sang hàng xóm; Horn +1 | R | KEEP |
| infinitedie | Infinite Die | E | mana | build+T-start | +2 reroll, +1 Mana, undo sống qua reroll | F | MERGE (nhận voidgene); reroll đo cũ ≈0 ảnh hưởng winrate |
| windlash | Windlash | E | aoe | build | Mouth dmg có Cleave, +1 | R | KEEP (⊂ stormcall) |
| deathspiral | Death Spiral | E | exec | hit | Lần đầu địch <50% HP: 7 dmg xuyên | R | KEEP |
| bastionplate | Bastion Plate | E | shield | shield | Tạo Shield: 50% thành dmg cho 1 địch | R | KEEP: payoff BULWARK |
| cullingorder | Culling Order | E | exec | kill | Kill: Axie thương nhất hồi 4 + 4 Shield | R | REWORK: phần hồi vô nghĩa khi HP hồi mỗi trận |
| glassspine | Glass Spine | E | thorns | shield | Axie được Shield có Thorns ≥4 | R | KEEP: cầu nối shield→thorns |
| manaspring | Mana Spring | E | mana | T-start | +2 Mana/lượt | F | KEEP: enabler mana duy nhất đều đặn |
| hollowbone | Hollow Bone | E | pierce | agg | Pierce +3 và bỏ qua Thorns | F | REWORK: số + kèm ngoại lệ |
| chainreact | Chain Reaction | E | aoe | kill | Địch chết nổ 5 dmg lên địch còn lại | R | KEEP |
| hearthcore | Hearthcore | E | burn | tick | Burn tick 2 lần (lần 2 = 70%) | R | KEEP (nhân trần burn) |
| quickenroot | Quickenroot | E | growth | roll-end | Từ lượt 2 mặt đang roll +1 vĩnh viễn trong trận | S | KEEP |
| swarmnest | Swarm Nest | E | summon | agg | Đầu trận 2 Egg | R | MERGE với broodpouch (cùng luật, khác số) |
| fang | Venom Fang | E | poison | build | Mặt poison +1 stack | F | REWORK: số; poison đã là phễu rộng nhất (doc cũ) |
| plaguelord | Plague Lord | L | poison | tick+build | Poison không giảm; mặt poison +1 | R | KEEP |
| soulforge | Soul Forge | L | shield | agg+build | Shield không trần, −30% dmg nhận, Shield +2 | F | REWORK: 3 số trong 1 relic, `dr` là nhân toàn cục |
| echostone | Echo Stone | L | crit | agg | Mặt đầu mỗi lượt kích 2 lần | R | KEEP: tag crit sai (build nào cũng dùng); ứng viên "pick bắt buộc" |
| venomengine | Venom Engine | L | poison | tick | Poison tick 2 lần/lượt | F | KEEP (nhân trần poison; đi cùng plaguelord là vô hạn) |
| apexpredator | Apex Predator | L | crit | agg | +35% crit, crit ×3 | F | REWORK: hai số trần |
| bloodpact | Blood Pact | L | exec | agg+build | −15% Max HP, mọi dmg ×1.6 | R | KEEP: pact duy nhất; tag exec sai; cần trần stack |
| worldpiercer | World Piercer | L | pierce | build+agg | Mọi mặt dmg có Pierce; Pierce không dính Thorns | R | KEEP |
| hivequeen | Hive Queen | L | summon | agg | Egg thừa hưởng relic sửa die; giữ tối đa 6 Egg | R | KEEP |
| conduitcrown | Conduit Crown | L | mana | T-start+agg | Active dùng 2 lần/lượt (rarity ≤2), +2 Mana/lượt | R | KEEP: payoff CONDUIT |
| manaflood | Mana Flood | L | mana | end turn | Mana dư cuối lượt nổ vào mọi địch; +3 Mana đầu trận | R | KEEP |
| ancientgene | Ancient Gene | L | growth | build | Mọi mặt ×1.3 | F | REWORK: nhân trần; tag growth sai |
| worldtree | World Tree | L | growth | combat end | Giữ nửa growth qua các trận, ≤+3/mặt | S | KEEP: relic duy nhất mang state qua trận |
| solarcore | Solar Core | L | burn | tick | Burn ×2 | F | KEEP (cộng hearthcore = ×3.4) |
| mirrorshell | Mirror Shell | L | thorns | thorns | Thorns ×2 | F | KEEP |
| stormcall | Storm Call | L | aoe | build | Mặt dmg đơn mục tiêu có Cleave | R | KEEP |
| dawnlance | Dawn Lance | L | pierce | mod_dmg | Đòn vào địch >50% HP ×1.9 | C | KEEP: tag pierce sai; mload 2 |
| ironmaiden | Iron Maiden | L | thorns | T-start | Địch nhiều HP nhất nhận dmg = Thorns cao nhất (≤7) | R | KEEP |
| apexferal | Apex Feral | L | exec | build+hit | Mọi mặt dmg có Execute; địch ≤15% HP chết ngay | R | KEEP |
| scalecrown | Scale Crown | L | thorns | T-start+thorns | Cả đội nhận SCALES: Thorns 2 + Poison 1 | R | KEEP: relic "mở đường" cho AEGIS |

Active (16): tất cả cat **A**, trigger `act` (tốn Mana).

| id | Tên | R | Arch | MP | Effect | Verdict và lý do |
|---|---|---|---|---|---|---|
| restore | Anemone Restore | C | shield | 2 | Hồi 9 HP | KEEP |
| freeze | Cryo Spore | C | mana | 4 | Stun 1 địch | KEEP: status ít dùng nhất |
| wall | Lunacia Wall | R | shield | 6 | 5 Shield cả đội | KEEP |
| chaos | Chaos Gene | R | mana | 1 | +4 reroll lượt này | KEEP: nghi ngờ suy biến cùng Conduit Crown (2 MP → 8 reroll) |
| pinning | Pinning Lance | R | pierce | 3 | Phá Shield, dmg = Shield (min 6) | KEEP |
| clutch | Clutch Call | R | summon | 4 | 1 Egg | KEEP |
| bramblewall | Bramble Wall | R | thorns | 3 | Thorns ≥5 cả đội | KEEP |
| perfectstrike | Perfect Strike | R | crit | 5 | 8 dmg, luôn crit | BUFF: ≈3.2 dmg/MP, yếu hơn Chomp |
| plague | Spore Bloom | E | poison | 6 | Poison 3 mọi địch | KEEP |
| chomp | Chomp Strike | E | pierce | 3 | 12 dmg xuyên | KEEP: 4 dmg/MP, tốt nhất mọi active; các thẻ khác cần BUFF |
| bloom | Bloom Surge | E | growth | 5 | Mặt đang roll +3 growth | KEEP |
| coupdegrace | Coup de Grâce | E | exec | 5 | 14 dmg execute | BUFF: 2.8 dmg/MP |
| pyre | Pyre Bloom | E | burn | 7 | Burn 6 mọi địch | KEEP |
| aegisfont | Aegis Font | E | shield | 8 | 8 Shield cả đội | KEEP |
| nova | Gene Nova | L | aoe | 8 | 10 dmg mọi địch | BUFF: Legendary mà ≈1.25 dmg/MP/mục tiêu |
| ult | LUNACIA ULTIMA | L | mana | 18 | 40 dmg xuyên + 10 Shield cả đội | KEEP: đích đến của build mana |

Tổng verdict: KEEP 66 · BUFF 3 · REWORK 18 · MERGE 7 · CUT 0.
Tôi không đề nghị CUT relic nào: vấn đề là thiếu tầng, không phải thừa relic xấu. 18 REWORK là các stat-stick; ở bước 3 mỗi cái hoặc thêm một trigger, hoặc gộp thành một họ.

## 3. Phát hiện

### 3.1 Cơ cấu

| Cat | Số | Tỉ lệ |
|---|---|---|
| Flat / nhân trần | 27 | 29% |
| Conditional | 5 | 5% |
| Scaling | 8 | 9% |
| Rule-bending | 38 | 40% |
| Active | 16 | 17% |
| Economy | 0 | 0% |

Trong 38 rule-bending có 15 relic chỉ gắn keyword lên một slot lúc dựng die (pierceall, gorehook, bloodmouth, rotmouth, marrowdrill, wildfire, stormcall, windlash, squallmark, worldpiercer, thousandcuts, tidalbrand, bloomscale, growthcore, apexferal). Cộng với 27 stat → **42/78 passive (54%) sửa die trước trận rồi không bao giờ hỏi người chơi gì nữa.** Chỉ 23 passive có trigger giữa trận. Đó là cảm giác "cơ bản" của Liam.

### 3.2 Archetype

| Arch | Tổng | C/R/E/L | Nhận xét |
|---|---|---|---|
| exec | 10 | 3/2/3/2 | Đủ. 3 relic mis-tag (claw, bloodmouth, bloodpact) |
| shield | 10 | 3/3/3/1 | Payoff chỉ có bastionplate; còn lại là số |
| pierce | 9 | 1/3/3/2 | Mạnh nhất về số (xem 3.3); dawnlance mis-tag |
| mana | 10 | 2/3/2/3 | Nhiều enabler, sink duy nhất là 16 active; ear/voidgene/infinitedie đều cùng việc |
| thorns | 9 | 1/3/2/3 | Payoff có (ironmaiden, retributor) nhưng Thorns không scale (cap 8, `status_engine.gd:21`) và không nhận `dmgMult` |
| summon | 8 | 1/4/2/1 | Enabler tốt, payoff nằm ở token stat-stick |
| growth | 8 | 1/2/3/2 | Đủ; ancientgene mis-tag (là nhân toàn cục) |
| poison | 8 | 1/2/3/2 | Payoff là nhân tick, không có "lý do chọn mục tiêu" |
| crit | 8 | 1/3/2/2 | Crit chỉ có trên mặt dmg và chance mặc định 0, nên 3 relic crit chết nếu thiếu nguồn |
| aoe | 7 | 1/2/2/2 | Nhiều relic "thêm keyword" |
| burn | 7 | 1/2/3/1 | Ít, nhưng hearthcore+solarcore+wildfire+pyroclasm cộng dồn mạnh |

Archetype còn thiếu loại relic: **không archetype nào có relic dùng vị trí đội hình, chỉnh xúc xắc, hoặc cần hai archetype/hai class**. Tag chỉ để tracker nên lệch tag không gây bug nhưng làm tracker nói sai.

### 3.3 Combo chết và pick áp đảo (phân tích code, chưa đo)

| Vấn đề | Chi tiết |
|---|---|
| Dead-draw | spines ⊂ scalecrown (Reptile có sẵn Thorns 2, `ContentDB.gd:127`); pierceall ⊂ worldpiercer; gorehook ⊂ apexferal; windlash ⊂ stormcall. Ba cặp sau do `relic-system.md` §3.7a đo trên data JS, tôi chưa đo lại trên Godot nhưng body hook là bản phiên âm nên khả năng cao vẫn đúng |
| Chồng sàn Thorns | spines (2), glassspine (4), bramblewall (5) dùng `max`, cái nhỏ hơn thành 0 |
| Nhân không trần | bloodpact ×1.6 + ancientgene ×1.3 + dawnlance ×1.9 (nửa đầu HP địch) ≈ ×3.9, cộng `ascend` (+25% mỗi lần, không trần) và `forge`. mload bằng 2+2+2 mà không bị chặn |
| Nhóm TALON | worldpiercer + hollowbone + thousandcuts + dawnlance = mload 5. Mọi mặt xuyên Shield, +4 mỗi đòn, đánh 2 lần |
| Nhân status | solarcore ×2 + hearthcore ×1.7 = ×3.4 burn; plaguelord (không giảm) + venomengine (tick 2 lần) = poison tự nhân vô hạn. Status không dính `dmgMult`, nên **không bị `mload` đo** |
| Mana | chaos (1 MP → 4 reroll) + conduitcrown (dùng 2 lần): 8 reroll/lượt cho 2 MP. Chomp 4 dmg/MP vượt mọi active khác |
| Universal pick | echostone (mload 0, Legendary, chạy cho mọi build) nhiều khả năng là pick bắt buộc. Chưa đo |

### 3.4 Relic không đổi quyết định nào

claw, carapace, cleaveall, barbedhide, heart, ear, gustwing, talonedge, eggshell, apexbrood, regrow, fang: 12 relic. Người chơi nhặt rồi không chơi khác đi. (HP hồi đầy mỗi trận nên Max HP và Regen có giá trị thấp hơn vẻ ngoài.)

### 3.5 Engine đã hỗ trợ nhưng chưa relic nào dùng (đường rẻ, chưa cần code)

| Thứ có sẵn | Vị trí | Gợi ý loại relic |
|---|---|---|
| **Resonance LINK** (hai Axie liền kề cùng loại mặt → ×1.15) | `combat_engine.gd:34-35,751` | Relic vị trí: không relic nào nhắc đến LINK |
| `poisonSpread` (poison lan hàng xóm) | `status_engine.gd:50` | Có code, 0 relic gán. (Doc cũ chủ ý chưa thêm vì poison đã phễu rộng; vẫn nên cân nhắc cho lateral) |
| `last_big` (mặt dmg lớn nhất đã dùng) | `combat_engine.gd:966` | Chỉ boss Mirror đọc; relic "lặp lại mặt lớn nhất" |
| `mana_spent`, `used_actives`, `stat.kills/max_hit` | `combat_engine.gd` | Relic scaling theo đếm |
| Status `vulnerable` (×1.5), `stun`, `blind`, `enrage`, `undying` | `damage_pipeline.gd:68`, `status_engine.gd:60-84` | Chỉ a_freeze dùng stun, chỉ lastwall dùng undying; vulnerable không có nguồn từ relic |
| 9 keyword chưa relic nào gắn: `chain`, `vital`, `echo`, `cantrip`, `heavy`, `bastion`, `decay`, `selfharm`, `overflow` | `combat_engine.gd:37-39` | Relic `mod_face` thuần data như rotmouth |
| Hook ít dùng: `on_dmg_taken` (1), `on_shield` (2), `on_thorns` (2), `on_roll_end` (2) | `relic_hooks.gd` | Relic "bị đánh thì…", "sau khi roll thì…" |
| Field đơn lẻ: `critFlat`, `cleaveRatio`, `tokenCap`, `burnTicks`, `actReuse` (chỉ rarity ≤2) | `relic_def.gd:81-123` | Mở rộng sang relic thứ hai |
| `rerolls` hồi đầy mỗi lượt | `combat_engine.gd:1087` | "Reroll chưa dùng được giữ lại" (kiểu Ice Cream), ~1 dòng |

### 3.6 Hook CHƯA có (cần code, đổi `RULES_VERSION`)

| Hook / hạ tầng | Lý do cần | Chỗ chèn dự kiến |
|---|---|---|
| `on_reroll` | Relic reroll (hiện chỉ có field) | `combat_engine.gd:466` |
| `on_face_used` (sau `_exec_face`) | Relic combo theo chuỗi mặt, đếm số mặt dùng | `:739` |
| `on_turn_end` (trước địch hành động) | Relic cuối lượt, "chưa dùng thì…" | `:1021` |
| `on_heal`, `on_mana_gain/spend`, `on_crit`, `on_active_played`, `on_status_applied`, `on_ally_died`, `on_summon` | Phản ứng với sự kiện đang chỉ phát qua EventBus | nhiều chỗ |
| `on_combat_start` / `on_combat_end` | Hiện phải giả bằng `turn == 1` | `setup_new`, `get_result` |
| **State relic theo run** | `RelicDef` read-only theo kế hoạch kiến trúc §6; chỉ `growthKeep` mang state qua trận. Mọi relic "đếm" cần chỗ lưu trong `RunState` + save + replay | `RunState.gd` |
| Hook ngoài combat: nhận relic, mua shop, chọn reward | Relic economy, relic nhân đôi reward | `RunState.gd`, `reward_generator.gd` |
| Chỉnh mặt sau khi roll (`Unit.set_roll` đã có, `unit.gd`) | Relic dice-manipulation | gọi từ `on_roll_end` |
| Pool lọc theo build (tag đang sở hữu) | Duo relic, mload, ex | `pick_relic` |
| Đổi thứ tự đội hình trong run | Relic vị trí có agency | UI + `RunState` |

## 4. Nghiên cứu

Nguồn: hầu hết là wiki cộng đồng, forum, báo/guide, không có tài liệu chính thức của nhà làm game. Tôi đánh dấu **[cộng đồng]** hoặc **[kiến thức riêng, chưa kiểm]**. Không có số liệu nào bên dưới nên coi là cứng.

| Game | Pattern | Vì sao tạo quyết định/combo | Áp vào Axie Dice |
|---|---|---|---|
| **Slay the Spire** [cộng đồng: [wiki Busted Crown](https://slay-the-spire.fandom.com/wiki/Busted_Crown), [thảo luận boss relic](https://steamcommunity.com/app/646570/discussions/0/594015574338624970)] | Boss relic: sức mạnh lớn kèm drawback thật (Busted Crown +1 Energy nhưng 2 thẻ reward ít hơn). Chọn 1 trong 3, chỉ ở boss | Người chơi chọn cái drawback mình giảm được. Cùng relic, giá trị đổi theo deck | Relic **pact** khi thắng boss: chọn 1 trong 3. Drawback đánh vào xúc xắc/tài nguyên (face yếu đi, reroll bị giới hạn, mana tax), **không** đánh HP carry (giữ luật HP) |
| **StS** [cộng đồng: [Snecko Eye](https://slay-the-spire.fandom.com/wiki/Snecko_Eye), [Ice Cream/Dead Branch thảo luận](https://steamcommunity.com/app/646570/discussions/0/1728701877482379002)] | Relic đổi **luật tài nguyên**: Ice Cream (Energy giữ lại), Snecko (rút nhiều nhưng cost ngẫu nhiên), Dead Branch (exhaust sinh thẻ) | Không cộng số mà đổi cách lập kế hoạch lượt; Snecko là rủi ro-có-điều-kiện | Reroll giữ lại; mặt blank thành 1 reroll; "mặt thấp nhất bị roll lại tự động nhưng cao hơn" (volatility relic). Mana đã giữ cả trận nên Ice Cream của mana không có nghĩa |
| **Balatro** [cộng đồng: [Inverse](https://www.inverse.com/gaming/balatro-tips-for-scoring-big), [bài toán retrigger](https://benstokman.me/blog/using-geometry-and-quadratic-functions-to-prove-balance-scoring-retrigger-effects-balatro)] | Joker xử lý trái→phải: +Mult trước ×Mult mới tốt. Scaling joker (Supernova, Green Joker) nên lấy sớm. Retrigger | Thứ tự là quyết định; scaling cho lý do lấy sớm; retrigger nhân giá trị mà không nhân số thẻ | Thứ tự INV-5 của mình cố tình **không** để người chơi quyết (add trước mul theo data). Phần "thứ tự" nên dời sang **vị trí đội hình** (5 slot). Retrigger: Echo Stone là mới 1 cái, mở rộng theo slot/theo loại mặt |
| **Balatro** [cộng đồng: [tier list](https://www.pocketgamer.com/balatro/joker-tier-list/), [giga.de](https://www.giga.de/games/balatro-alle-joker-freischalten--01JYP8RPYMGMY8WQJHTKKGXH3E)] | 4 rarity (~61/64/20/5 trên 150, số khác nhau giữa nguồn), shop ~70/25/5, Legendary không có trong shop. Blueprint/Brainstorm copy joker khác | Rarity là **trọng số**, không phải chỉ nhãn; Legendary là mục tiêu đặc biệt | Trọng số rarity trong `pick_relic` (hiện đều). Relic "copy" dùng được vì `relic_ids` có thứ tự nhận |
| **Balatro stakes** [cộng đồng: [wiki Stickers](https://balatrogame.fandom.com/wiki/Stickers), [stake list](https://dotesports.com/indies/news/all-balatro-stakes-in-unlock-order)] | Mỗi stake thêm luật: Eternal (không bán được), Perishable (hết hiệu lực sau 5 vòng), Rental (trả tiền mỗi vòng) lên chính joker | Độ khó đánh vào **tập relic**, không phải số của địch | Gợi ý cho Ascension (mục 6) |
| **Monster Train** [cộng đồng mỏng: [Destructoid MT2](https://www.destructoid.com/best-artifacts-in-monster-train-2/)] | Artifact vừa theo clan vừa không theo clan | Artifact theo clan khoá lựa chọn có ý nghĩa; artifact chung là "đường lui" | Relic gắn **class** (6 class) bên cạnh archetype; vài relic chung không điều kiện |
| **Hades** [cộng đồng: [Prima: Duo/Legendary](https://primagames.com/gaming/hades-guide-legendary-heroic-duo-boons), [Hades II rarity/Pom](https://hades2.wiki.fextralife.com/Boon)] | Legendary cần 1 boon tier thấp + 1 tier cao của một vị thần; **Duo** cần boon từ hai vị thần. Có điều kiện mà vẫn không chắc xuất hiện. Pom of Power nâng level một boon. Keepsake là món mang vào trước run | Combo là phần thưởng của việc **đi theo hướng**; offer biết người chơi đang có gì | Duo relic cần hai tag; offer lọc theo tag đang sở hữu. Keepsake: xem câu hỏi mở (Land không cho sức mạnh combat) |
| **Dicey Dungeons** [cộng đồng: [Wikipedia](https://en.wikipedia.org/wiki/Dicey_Dungeons), [Game Developer](https://www.gamedeveloper.com/disciplines/road-to-the-igf-cavanagh-houston-dobbe-s-i-dicey-dungeons-i-)] | Trang bị có slot nhận xúc xắc với điều kiện (lẻ/chẵn, ≥/≤); item biến đổi die sau khi roll (reroll 1 die, tách, nhân đôi). Dev thấy trộn thẻ ngẫu nhiên với dice ngẫu nhiên thì quá hỗn loạn | Giá trị của die là thứ người chơi **chế biến**, không chỉ đọc | Relic **dice-manipulation**: +1/−1 cho một mặt, lật mặt, nhân đôi mặt dùng lượt này, chuyển type. Giữ có trần (một ngẫu nhiên là đủ, vì Axie đã có roll + reroll) |
| **Risk of Rain 2** [cộng đồng: [Steam thảo luận](https://steamcommunity.com/app/632360/discussions/0/3189116298881963378/?ctp=2), [Ukulele](https://rogueranker.com/risk-of-rain-2-ukulele/); một số nguồn kém tin] | Stack tuyến tính, **hyperbolic** (tiến tới nhưng không chạm 100%), **proc coefficient** (chuỗi proc có hệ số <1 nên tự dừng). Lunar item: trade-off nặng (Purity) | Chuỗi proc là chỗ sinh ra "build vỡ", nên phải có luật dừng | Mình đã có proc 0 (damage relic gây không kích `on_hit`). Dùng dạng hyperbolic cho các % cộng dồn (crit chance, dr) |
| **Vampire Survivors** [cộng đồng: [wiki Evolution](https://vampire-survivors.fandom.com/wiki/Evolution)] | Evolution = vũ khí max + đúng passive item đang giữ; Union ghép hai vũ khí | Công thức **nhìn thấy được**, tạo mục tiêu săn | Recipe relic: hai relic cụ thể đang giữ thì nâng thành bản mới (Codex ghi sẵn) |
| **LoL** [cộng đồng/báo: [Sportskeeda](https://www.sportskeeda.com/esports/news-league-legends-season-14-set-completely-remove-mythic-items), [RiftFeed](https://riftfeed.gg/more/league-of-legends-dev-reveals-why-gargoyles-stoneplate-was-removed-in-season-14)] | Mythic (build-defining) bị bỏ ở mùa 14: chỉ phục vụ tốt khoảng nửa roster, quá ít món cho quá nhiều champion, assassin lợi, tank/juggernaut thiệt | Bài học ngược: **build-defining item phải đủ cho mọi kiểu chơi** | 11 archetype + 6 class thì không được có "1 mythic/archetype" kiểu cứng. Làm vài relic engine **chung** + engine theo archetype, và không khoá một món vào một class |
| **Dota 2** [cộng đồng: [esports.gg](https://esports.gg/guides/dota-2/neutral-items-in-dota-2-all-tiers-and-inactive-neutrals/), [Liquipedia](https://liquipedia.net/dota2/Neutral_Item)] | Neutral item: 5 tier mở theo thời gian, mỗi tier chọn từ một offer (~12-13 món), mỗi người chọn một. Craggy Coat: drawback chỉ nằm ở active (opt-in) | Chọn từ offer có giới hạn tạo quyết định; drawback gắn vào kích hoạt thì người chơi tự chịu | Pact relic có thể có drawback **chỉ khi kích hoạt** (active) thay vì luôn bật. Aghanim's Scepter nâng skill của hero và Black King Bar là active định hình giao tranh **[kiến thức riêng, chưa kiểm]** → relic nâng cấp **class passive** (6 class) và 1–2 active "định hình" |
| **Backpack Hero / Luck be a Landlord** [cộng đồng: [Destructoid](https://www.destructoid.com/review-backpack-hero/), [LBAL guide](https://gamepretty.com/luck-be-a-landlord-symbol-item-guide/)] | Adjacency: Backpack Hero là câu đố tự xếp; LBAL tự đánh giá mỗi lượt (ăn, nhân, sinh ra symbol kề bên). Không có tài liệu thiết kế của dev | Vị trí cho thêm trục chọn thứ hai | Hàng xóm đã có thật: cleave, Retributor, burn/poison lan, LINK. Relic vị trí cần player đổi được thứ tự đội |
| **Peglin / Inscryption** [cộng đồng: [Indietail](https://indiecator.org/2022/05/18/indietail-peglin/), [Prima](https://primagames.com/gaming/inscryption-best-cards-deathcards-sigils)] | Khối hiệu ứng nhỏ, ghép được; Inscryption hiển thị sigil ngay trên thẻ nên tổ hợp nhìn thấy trước | Tổ hợp phải **đọc được** trước khi chọn | Relic gắn vào keyword/type (đã có trong data) để tự ghép; mô tả relic nêu rõ "tag" |

**Điều rút ra chung:** (1) game giữ chân người chơi bằng 3 trục: enabler → payoff → engine rời; (2) combo đáng nhớ có điều kiện nhìn thấy (Hades, Vampire Survivors); (3) drawback thật tạo build chứ không phải số to hơn (StS, RoR2, Balatro stakes); (4) chuỗi nhân phải có điểm dừng định sẵn; (5) item "định hình" không được khoá theo một kiểu chơi (LoL).

## 5. Framework relic cho Axie Dice

### 5.1 Các tầng

| Tầng | Vai trò | Rarity chính | Ví dụ hướng (không phải danh sách bước 3) |
|---|---|---|---|
| **Enabler** | Tạo ra thứ để đi theo: tag keyword, trạng thái, mana, Egg, growth | C–R | gắn `echo`/`vital` lên slot; `poisonSpread` |
| **Payoff** | Đổi trục thành damage/phòng thủ có điều kiện | R–E | địch vulnerable nhận thêm; shield→dmg |
| **Engine ("mythic")** | Viết lại một luật; build quay quanh nó | L | Echo Stone là mẫu hiện có. Cần ≥1 engine mỗi archetype **và** vài engine chung |
| **Pact** | Sức mạnh lớn + drawback thật, chỉ ở boss (hoặc chaos) | E–L | Drawback đánh xúc xắc/reroll/mana, không đánh HP |
| **Duo / combo** | Cần hai tag (hai archetype hoặc hai class) mới xuất hiện | R–L | Offer chỉ hiện khi đang có đủ tag |
| **Dice-manipulation** | Chế biến mặt đã roll | R–E | set/nudge/duplicate/chuyển type, có trần mỗi lượt |
| **Scaling** | Đếm và nhân: reset theo trận hoặc giữ theo run | R–L | World Tree là mẫu run-persistent; còn lại reset |
| **Vị trí (5 slot)** | Dùng thứ tự đội và LINK | R–E | slot 1/5, hàng xóm, đối xứng |
| **Class upgrader** | Nâng class passive (Plant/Beast/Aqua/Reptile/Bug/Bird) | E | 6 relic, mỗi class một |
| **Economy / meta-run** | Giá shop, số thẻ reward, reroll reward | C–R | chỉ đụng tiền **trong run**, xem câu hỏi mở |

### 5.2 Luật chống suy biến

1. **Một slot "nhân toàn cục"**: tối đa 1 relic mang `dmgMult`/`dr`/nhân mặt trong cả run. Đơn giản hơn tổng `mload` 0/1/2 mà code chưa hề có. Relic nhân theo archetype (burn, poison, crit, thorns) cho tối đa 2.
2. **Đếm status vào trần**: relic nhân status tick (poison/burn) cũng mang nhãn nhân, vì chúng đi ngoài `dmgMult`.
3. **Gộp % kiểu cộng, nhân một lần** (bài học Balatro/RoR2): các % cùng trục (crit chance, dr) cộng rồi qua một hàm hyperbolic, không nhân dồn.
4. **Proc**: damage do relic gây ra **không kích relic** (giữ sẵn `attack:false`/`src:null`). Mọi hook mới ghi rõ điều này.
5. **Offer biết build**: `exSub` một chiều (không offer subset khi đã có superset) + sửa 4 cặp chết ở 3.3; duo/payoff chỉ offer khi có enabler tương ứng.
6. **Slot cho passive** (xem câu hỏi 1): có trần thì mới có quyết định "bỏ cái nào".
7. **Drawback phải thật và lâu dài trong run**, không "mất lượt này" (như `relic-system.md` §3.1 đã nói cho pact).
8. **Mọi điều kiện enemy-agnostic**: chỉ dùng HP%, status, Shield, số địch, `is_boss`/elite. Không tên quái, không roster Chimera (quái sẽ thành Atia).
9. **Sim trước khi chốt số**: dùng winrate theo archetype ±8 điểm quanh trung bình và playrate ≥5% làm mục tiêu (doc cũ có nhiều archetype dưới 5% playrate). Cần một bot Godot (hiện chưa thấy sim relic trên Godot).

### 5.3 Cỡ pool khoẻ (đề xuất, chưa tinh)

Giữ 87 relic sau 7 MERGE, thêm ~45 mới ≈ **130 tổng (114 passive + 16 active)**.

| Rarity | Số | Cat (passive) | Số |
|---|---|---|---|
| Common | 28 | Enabler | 26 |
| Rare | 42 | Payoff | 24 |
| Epic | 38 | Engine | 14 |
| Legendary | 22 | Pact | 8 |
| | | Duo | 12 |
| | | Dice-manipulation | 8 |
| | | Scaling | 6 |
| | | Vị trí | 5 |
| | | Class upgrader | 6 |
| | | Economy | 5 |

Mỗi archetype tối thiểu: 2 enabler C/R, 2 payoff R/E, 1 engine L; mỗi cặp archetype "bắc cầu" ≥1 duo. Tối thiểu 12 duo chọn tay phủ đủ 11 archetype ít nhất 2 lần, không làm hết 55 cặp.

## 6. Bài học cho Ascension luật mới (chỉ ghi nhận, thiết kế ở bước 3)

- Balatro stake đánh vào **chính relic** (Eternal/Perishable/Rental). Ascension kiểu này hợp với "luật mới thay vì số to hơn".
- Hades Pact có nhiều điều kiện, trong đó có cái bắt người chơi bỏ boon ([nguồn](https://www.trueachievements.com/game/Hades/walkthrough/7), cộng đồng): hợp ý "buộc đổi build", nhưng phần lớn điều kiện vẫn là tăng số địch, nên phải chọn lọc.
- Ý tưởng sơ bộ: reward relic đầu tiên bị khoá là pact; shop bán relic có sticker xấu rẻ hơn; slot passive giảm; một relic bị "Perishable" sau N trận. Ascension này phải **tất định** (ranked có replay-verify), nên chọn luật cố định theo level thay vì tự chọn Heat.

## 7. Câu hỏi mở cho Liam (mỗi câu có đề xuất)

| # | Câu hỏi | Đề xuất của tôi |
|---|---|---|
| 1 | Có giới hạn số relic passive không (kiểu slot Joker)? Hiện không trần, 4–8 relic/run (ước tính) | **Có: 8 slot passive**, active tách riêng 3 slot. Bán lại relic lấy 50% giá (sink in-run). Đây là thứ thêm, không đụng combat |
| 2 | Thay `mload` bằng "1 slot nhân toàn cục" + "tối đa 2 nhân archetype"? | **Có.** Dễ hiểu hơn, dễ hiển thị trên UI, code đơn giản |
| 3 | Offer có nghiêng theo build đang giữ (kiểu Hades) hay giữ chọn đều? | **Nghiêng nhẹ:** trong 3 thẻ, 1 thẻ relic ưu tiên tag đang có; duo chỉ hiện khi đủ tag. Vẫn tất định theo seed |
| 4 | Trọng số rarity trong band (hiện chọn đều theo số relic: boss ra Legendary 43%)? | **Có trọng số** (ví dụ boss E 70/L 30, elite R 50/E 35/L 15) |
| 5 | Pact relic: chỉ ở boss (chọn 1 trong 3) và thay luôn reward `chaos`/`curse`? | **Có.** Drawback chỉ đánh dice/reroll/mana, không HP carry. Giữ `curse` hiện tại cho đến khi pact thay thế |
| 6 | Duyệt thêm khoảng 6–8 hook mới (`on_reroll`, `on_face_used`, `on_turn_end`, `on_combat_end`, relic state theo run, hook ngoài combat) dù replay cũ mất hiệu lực? | **Duyệt**, gom làm một lần đổi `RULES_VERSION`; làm sau khi chốt bộ relic để không đổi hai lần |
| 7 | Cho đổi thứ tự đội hình giữa các trận (để relic vị trí có agency)? | **Có**, miễn phí ở màn Map; nếu không thì bỏ tầng vị trí khỏi bước 3 |
| 8 | Relic economy chỉ đụng tiền **trong run** (giá shop, số reward, reroll reward), không cộng Gene Shard? | **Đúng.** Shard bank về meta nên cộng Shard là chạm economy toàn game, cần economy-designer duyệt riêng |
| 9 | Duo relic theo cặp archetype hay cặp class? | **Cặp archetype** (12 cặp chọn tay), cộng 6 relic nâng class passive |
| 10 | Keepsake kiểu Hades (một món mang vào run) có chấp nhận không, khi Land không cho sức mạnh combat? | **Chưa.** Làm sau; nếu làm thì là "chọn 1 trong 3 relic Common đã thấy ở run trước", không phải relic mua |
| 11 | Sửa 6 tag archetype sai (claw, bloodmouth, bloodpact, dawnlance, ancientgene, echostone) và cho phép relic có 2 tag? | **Có**, nếu không thì tracker UI nói sai. Relic chung (claw, ancientgene, echostone) đánh dấu "universal" |
| 12 | Ascension: luật cố định theo level (tất định, ranked được) hay tự chọn kiểu Heat? | **Cố định theo level**; thiết kế chi tiết ở bước 3 cùng relic |

## 8. Nguồn code đã đọc

`godot/scripts/core/relic_hooks.gd`, `combat_engine.gd` (100–1140), `damage_pipeline.gd`, `status_engine.gd`, `reward_generator.gd`, `godot/autoload/RunState.gd` (225–285, 600–765), `ContentDB.gd` (110–140, 795–830), `godot/scripts/data_models/relic_def.gd`, toàn bộ 94 file `godot/resources/relics/*.tres` (chỉ trường `id/name/description/rarity/archetype/mload/hook_key/act_cost` và field aggregate), `design/gdd/relic-system.md` (1–462: §3.1–3.9), `godot-port-rule-spec.md` §1–3, 7–9, `relic-roster-expansion.md` (chỉ các dòng sim, 165–198, 886–1074). Chưa đọc: UI hiển thị relic, `unit.gd`, test `t_mod_face`, `relic-rebalance-2026-09-07.md` ngoài dòng grep.
