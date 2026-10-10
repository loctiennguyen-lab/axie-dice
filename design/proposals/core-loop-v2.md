# Axie Dice — Core Loop v2 (Land, Contracts, Pass, Mastery, chiều sâu build)

**Trạng thái: ĐỀ XUẤT — chờ Liam review**
Tác giả: game-designer · 2026-10-10 · Chưa sửa file nào khác, chưa có code.
Mọi con số là first-pass để có cái mà bắn, chưa qua sim. Chỗ nào tôi chưa tự kiểm được trong code thì ghi rõ "chưa verify".

> **QUYẾT ĐỊNH CỦA LIAM SAU REVIEW (10/10) — ưu tiên hơn mọi đề xuất bên dưới:**
> - **Nền tảng: Windows + macOS trước.** Android/iOS làm sau.
> - **Land không cho sức mạnh combat.** Chỉ cho bề rộng: chỗ đặt cosmetic, slot đội hình, slot nhà
>   nhiệm vụ, gacha... Nâng Land tốn currency, và tốn NHIỀU.
> - **Đồng ý 2 currency.**
>   - **Gene Shard** — faucet: Battle Pass, chơi game, thưởng nhiệm vụ, daily quest...;
>     sink: Echo Box, cược nhiệm vụ.
>   - **Land Stone** — faucet: Echo Box, Battle Pass, daily quest; sink: nâng level Land (sau này
>     có thể thêm sink).
> - **Combat: GIỮ NGUYÊN chiều sâu hiện tại, chỉ bổ sung, không thay đổi.** Không đổi archetype.
>   KHÔNG thêm enemy trait khắc chế (§5.2 cột counter-trong-địch và §5.5 trait: bỏ). **Giữ luật HP
>   cũ** (hồi đầy mỗi trận — §5.6: chọn A). Ascension luật mới (§5.7): chưa duyệt.
> - **Relic là trọng tâm**: relic hiện tại cơ bản và linh tinh, chưa đủ hấp dẫn → cần thiết kế lại /
>   bổ sung kỹ.
> - **Quái: dùng hoàn toàn quái Atia 3D** (thay sprite Chimera). Boss thiếu asset thì Liam xin thêm.
> - **Gọi là "Nhiệm vụ", không gọi "hợp đồng".** Có mốc cược + phần thưởng tương ứng độ khó;
>   tối đa **5 nhiệm vụ/người/ngày**; không hoàn thành thì **mất tiền cược, không hoàn**. Thiết kế
>   cực kỳ cẩn thận, có nghiên cứu game khác.
> - Cần **economy-designer** cân bằng currency.
> - 55 món art mới (§9 cột N): Claude viết request cho Claude Design.

> **QUYẾT ĐỊNH LIAM (10/10, danh sách B):** B1 bản đầu không có store tiền thật, vé thiết kế sẵn để sau bán
> bundle · B2 **KHÔNG làm leaderboard công ty** — chỉ leaderboard cho người chơi ĐÃ ĐĂNG KÝ (đăng nhập) ·
> B3 Ascension luật mới: làm chung với relic · B4 Class Mastery §6.2: ĐỒNG Ý (đường cong phải sửa theo ghi
> chú review) · B5 Cạnh tranh §8: làm sau Nhiệm vụ · B6 tham quan Land người khác: làm trong phase này,
> để cuối (Claude đề xuất thời điểm) · B7 viết lại phasing §10 sau khi chốt relic.
> **Ghi chú review (Claude, 10/10) — hai số cần sửa trước khi tin bảng economy:**
> 1. **Shard/run có thể gấp 3–4 lần 150.** Ở Godot, shard của run = tổng thưởng từng trận
>    (25/45/90, `combat_engine.gd:1207`) + event − tiền tiêu shop, bank ở `RunState.end_run()`
>    (`RunState.gd:447`). Run short thắng (~8 battle, 2 elite, 3 boss) ≈ 560 trước khi tiêu. Con số
>    150 là của bản JS. Phải đo thật (sim nhiều seed) rồi co giãn lại §3.2–§3.3, §6.3, §7.3.
> 2. **Mastery §6.2:** XP class chia theo tỉ lệ class trong đội nên tổng mỗi run vẫn ~350. Max cả
>    6 class (6 × 9.200 = 55.200 XP) cần ~158 run (~65 giờ), không phải ~390 run / 160 giờ. Muốn
>    Mastery kéo dài ~160 giờ thì phải tăng đường cong khoảng 2,5 lần.

---

## 0. Đọc nhanh (nếu chỉ có 5 phút)

1. **Một câu**: Land là nơi ở, Run là nơi chơi. Land không cho sức mạnh trong combat, chỉ cho bề rộng (cosmetic, tiện lợi, lựa chọn trước run). Sức mạnh vẫn chỉ nằm ở tầng run. Đây chính là luật C6 + "hai tầng" trong `economy-progression.md` §3, tôi giữ nguyên.
2. **Hai currency, không hơn**: Gene Shard (chảy nhanh, đem đi cược/mua hộp) và Land Stone (chảy chậm, không cược được, không mua được bằng Shard, chỉ để lên tier Land).
3. **Chiều sâu build là phần tôi đầu tư nhiều nhất**: 4 trục (class passive × relic engine × Gene Mutation × enemy trait), mỗi archetype có một counter nằm trong *địch*, không chỉ trong build khác.
4. **Ranked/daily dùng "Ranked profile"**: bỏ hết perk/unlock cộng chỉ số. Không có nó thì mọi thứ về competition là P2W kiểu nạp thời gian.
5. **Cắt**: World Tour, Moon Dust (Liam đã chốt), unlock cộng HP/reroll vĩnh viễn, bán Echo Box theo giá lũy tiến, farming kiểu Homeland (không làm Mine/Smelter/Field...).

---

## 1. Hiện trạng — FACT (có file ref)

| # | Fact | Nguồn |
|---|---|---|
| F1 | Run 18 hàng (short) / 30 hàng (full); node battle/elite/event/shop/treasure/boss. Boss cuối luôn là `agony`. | `run_map_generator.gd`, `godot-port-rule-spec.md` §9 |
| F2 | Party hồi đầy máu và Axie chết sống lại trước mỗi trận. Spec ghi rõ là quyết định có chủ đích "không camp". | `godot-port-rule-spec.md` ~dòng 64, 321 |
| F3 | Shard thưởng trong combat: 25 (battle) / 45 (elite) / 90 (boss). Daily mission +60. Tài liệu cũ nói thắng run +120, thua +40, baseline ~156 Shard/run (số này từ bản JS, **chưa đo lại trên Godot**). | `combat_engine.gd:1207`, `ContentDB.gd:789`, `economy-progression.md` §10 |
| F4 | 10 unlock Shard, tổng 3.450 Shard: 120 / 150 / 180 / 220 / 280 / 350 / 400 / 500 / 650 / 600. Bốn cái inert (`u_relic1/2`, `u_face1/2`). Sáu cái còn lại: một mở Full Run, `u_start` cho relic Common, bốn cái cộng reroll/HP phẳng. | `ContentDB.gd:769-786` |
| F5 | Pass 30 level, `XP_need(lv)=45+22(lv-1)` → tổng 10.920 XP tới lv30. Rewards: 13 mốc Shard (tổng 4.870), 5 unlock, 6 perk (reroll/relic/HP/rrw, lv 7/10/15/22/24/25/28), 5 mốc `face` (lv 5/12/19/26/30) **không claim được** vì chưa port FACE_POOL. | `ContentDB.gd:995-1042` |
| F6 | XP/run = 30 + 10×wave + 30×elite + 60×boss + 150×thắng + 25×Ascension + 40×Full. | `godot-port-rule-spec.md` §9 |
| F7 | Ascension 0–10 chỉ là nhân HP/dmg địch + thêm elite + weaken đầu trận + reward 2 lựa chọn ở A7. | rule-spec §9, `combat_engine.gd:155,1334-1348` |
| F8 | 94 relic (78 passive + 16 active), trần nhân damage `mload=2`, chống trùng `ex`, 11 archetype trong `ARCH` (PLAGUE, INFERNO, BULWARK, CONDUIT, TALON, APEX, EVOLVE, SWARM, TEMPEST, AEGIS, FERAL). | `relic-system.md` §0-1, `ContentDB.gd:802-822` |
| F9 | Class passive có sẵn cho cả 6 class: Plant shield+2/thorns, Beast exec +60% dưới 50% HP, Aqua mana+1 và 4 mana → 1 reroll, Reptile thorns+poison, Bug poison nhân đôi, Bird pierce+3. | `ContentDB.gd:119-132` |
| F10 | Reward: 3 lựa chọn, tối đa 2 cùng archetype (D16). | `economy-progression.md` §1.2 |
| F11 | `RunState.run_stats` có `dmg, taken, turns, kills, max_hit, dmg_dealt_clamped`; `max_hit` không tính poison/thorns. Action log có `seed, team_keys, mode, ascension, rules_version`, và có replay verifier. | `RunState.gd:44`, `action_log.gd:81-111`, `run_verifier.gd` (tôi chưa đọc nội dung, chỉ dựa vào brief + `t_replay` 47 check) |
| F12 | Echo Box (bản JS): 60 vật phẩm, 5 bậc [62, 27, 9, 1.7, 0.3]%, 3 trùng → ghép lên bậc cao, Mythic trùng hoàn 250 Shard, giá `500×1.035^(n-1)` (box đầu 50). **Chưa có trong Godot** (menu không có Echo Box, tôi chưa grep lại hết). | `economy-progression.md` §10 dòng 380-402 |
| F13 | Asset: các sheet biome (Savannah, Luna Landing) chủ yếu là **tile đất iso (Plot_Module 1x1/2x2/3x3), cây, đá, bụi** — không phải "đồ trang trí" theo nghĩa nội thất. Đồ nội thất nằm ở Atia (538). Building Homeland có sẵn `Portal`, `SpyQuarter`, `Alchemy`, `Armorsmith`, `Weaponsmith`, `EquipmentStall`, `GreenWarehouse`, `Jeweler`... Mỗi sheet building chỉ có 1 model + 2 variant `_F_01/_F_02`. | `asset-library/godot-ready/contact_sheets/` |
| F5b | Pass hiện tại **vi phạm C6**: perk HP/reroll/relic khởi đầu là sức mạnh vĩnh viễn nằm ở tầng sưu tầm. Unlock `u_hp`/`u_hp2`/`u_reroll`/`u_reroll2` cũng vậy. | so với `economy-progression.md` §3 |
| F14 | Gene Mutation cũ: FACE_POOL 50 mặt + 5 BP, 10 RUNES (`git show 5e34a17^:src/data.js` ~243-295). **Phiên này tôi không có shell nên chưa đọc lại được.** Phần §4.3 về Mutation dựa vào brief và vào D5 (mutate hạ mặt về Common), cần người port đọc nguồn rồi sửa. | brief; `economy-progression.md` D5 |

**Hai chỗ tôi muốn Liam nhìn kỹ vì chúng đẻ ra nhiều quyết định phía sau**: F2 (không carry HP, ngược hẳn với "map stakes") và F5b (cộng chỉ số vĩnh viễn, ngược với luật C6 mà chính Liam đã duyệt).

---

## 2. Core loop v2

### 2.1 Ba vòng lồng nhau

```
MICRO (30s)      chọn mặt xúc xắc -> chọn target -> số nhảy, địch phản ứng
MESO  (15-30p)   1 run: map -> combat -> chọn 1 trong 3 reward -> ... -> boss
SESSION (45-90p) Land -> chọn việc -> 1-3 run -> thưởng -> về Land mở/đặt đồ -> thoát
MID  (ngày/tuần) daily seed + daily mission, contract tuần, Pass XP, Mastery lớp
LONG (tháng)     lên tier Land, sưu tầm decor, Ascension 10, Mastery 6 class, bảng xếp hạng
```

### 2.2 Sơ đồ session

```
 Mở game
    |
    v
 [LAND]  Axie chạy lang thang, building hiện badge (!) khi có việc
    |
    +--> House (Team Select) ------------> RUN (short/full) --+
    +--> Portal (Daily seed / Ranked) ---> RUN (khoá luật) ---+
    +--> Mission house (Contract) -- trả stake --> RUN -------+
    |                                                          |
    |      <--- Shard, XP Pass, XP Mastery, Land Stone, ------+
    |           relic discovered, cosmetic drop
    +--> Echo Box house: mở hộp (Shard / vé)
    +--> Mastery hall: xem/nhận mốc class, chọn passive variant
    +--> Pass stall: nhận mốc Pass
    +--> Vault warehouse: import Axie thật
    +--> Decor mode: đặt đồ, nâng tier Land (Stone + Shard)
    |
    v
 Thoát (điểm dừng tự nhiên: sau khi nhận thưởng + 1 "mục tiêu kế" hiện ở HUD Land)
```

### 2.3 Nguyên tắc cho Land khi KHÔNG chạy run

Land phải trả lời đúng một câu hỏi: "vừa thắng/thua xong, tôi làm gì trong 2-5 phút trước khi bấm run tiếp?" Danh sách việc **được phép**:

| Việc | Thời lượng | Có thể grind không? |
|---|---|---|
| Mở thưởng, nhận mốc Pass/Mastery, mở Echo Box | 1-2 phút | Không, bị chặn bởi Shard |
| Đặt/sắp decor, đổi skin tòa nhà | 2-5 phút | Không cần, thuần sáng tạo |
| Xem Axie/mascot đi lại, chạm vào nghe/xem emote | 0-1 phút | Không có thưởng |
| Mua contract, chọn đội | 1-2 phút | Chặn bằng trần stake |
| Nâng tier Land | 1 lần mỗi vài tuần | Gate bằng Land Stone |

**Danh sách việc KHÔNG làm** (để Land không thành farming sim): không có timer thu hoạch, không có nhà máy sản xuất, không có tài nguyên gỗ/đá/quặng, không có NPC cần chăm, không có "quay lại sau 8 tiếng". Các building Mine/Smelter/Field/Animal*/Coal*/*Storage trong thư viện asset **không dùng làm chức năng**, chỉ dùng làm decor (xem §4.3).

---

## 3. Currency và economy

### 3.1 Hai currency

| Currency | Vai trò | Faucet | Sink | Cược được? |
|---|---|---|---|---|
| **Gene Shard** (có sẵn) | Tiền "chảy": nhanh vào, nhanh ra | Combat (25/45/90), thắng run, daily mission, Pass, contract thắng | Echo Box, phí nâng Land, unlock mới, craft decor, **stake contract** | Có |
| **Land Stone** (mới) | Tiền "mốc": chậm, chỉ đo cam kết lâu dài | Ascension first-clear, Mastery level, Pass, contract tuần, daily streak, run thắng (thỉnh thoảng) | **Chỉ** nâng tier Land | Không |

**Vì sao không gộp thành một**: nếu nâng Land bằng Shard thì contract (cược Shard) thành đường tắt lên LunaLanding cho người giỏi, và Land — tài sản "của riêng mình" — thành thứ đo bằng độ may mắn khi cược. Tách ra thì cược chỉ làm giàu Shard, tức là chỉ nhiều hộp Echo hơn, còn mốc dài hạn vẫn đòi hỏi chơi nhiều kiểu (Ascension, Mastery, mission). Hai currency là mức tối thiểu để cô lập rủi ro đó. Tôi không đề xuất currency thứ ba: vé Echo là **item đếm**, không phải currency; XP là thanh tiến độ, không tiêu được.

**Land Stone không có gacha, không có đổi qua lại với Shard.** Đây là luật cứng (INV-Land-1), cùng tinh thần luật 3 của D12.

### 3.2 Pacing mục tiêu

Giả định "người chơi thường" = 1 giờ/ngày, 5 ngày/tuần ≈ 5-7 giờ/tuần ≈ 12-14 run/tuần (run trung bình 25 phút, trộn short/full).

| Mốc | Giờ chơi tích lũy | Tuần (thường) | Land Stone cần (cộng dồn) | Phí Shard |
|---|---|---|---|---|
| Savannah (khởi đầu) | 0 | 0 | 0 | 0 |
| → Forest | ~6h | tuần 1 | 30 | 300 |
| → Arctic | ~20h | tuần 3-4 | 110 | 1.000 |
| → Mystic | ~45h | tuần 7-8 | 270 | 2.500 |
| → Genesis | ~90h | tuần 14-16 | 570 | 5.000 |
| → LunaLanding | ~160h | tuần 24-28 | 1.020 | 10.000 |

Land Stone mỗi tier: 30 / 80 / 160 / 300 / 450. Nếu quá lệch khi sim thì chỉnh trên cột này, không đụng Shard.

**Faucet Land Stone tới LunaLanding (target ~1.020)** — ước tính thô, nửa đầu rất sát, nửa sau cần sim:

| Nguồn | Công thức | Tổng 160h |
|---|---|---|
| Daily mission | 1/ngày | ~160 |
| Contract tuần (hoàn thành) | 5/tuần | ~115 |
| Ascension first-clear A1..A10 | 5 + 2×A mỗi level, 1 lần | 160 |
| Class Mastery (6 class × 20 lv) | 2 Stone/level, 120 level | 240 |
| Pass 30 level | 36 | 36 |
| Run thắng | 1 Stone / thắng, ~35% win | ~110 |
| Codex/achievement mốc | ~15 mốc × 10 | 150 |
| **Cộng** | | **~970** |

Thiếu ~50 so với 1.020; tôi cố ý để thiếu một chút và để LunaLanding là tier gần như cần Ascension cao + Mastery nhiều class. Người đạt A10 và 3 class Mastery 20 vẫn nên tới được.

### 3.3 Faucet/sink Shard (tuần của người chơi thường, ~13 run)

Faucet: ~13 run × ~150 (baseline F3, chưa đo) ≈ 1.950 + daily 60×5 = 300 + contract net (trần, §7) ≈ 300 → **~2.500/tuần**.

| Sink | Chi/tuần | Ghi chú |
|---|---|---|
| Echo Box | 6 hộp × 250 = 1.500 | Giá phẳng 250 (xem §6.3) |
| Phí Land tier | amortized ~600 | 18.800 tổng chia ~30 tuần |
| Unlock hiện hữu + mới | ~100 | Hết sau ~35 tuần; xem §3.4 |
| Craft decor / Fuse | ~300 | Chọn món trên pool đã lọc |
| **Cộng** | ~2.500 | cân bằng ±10% |

**Chống tích Shard vô ích** (người giỏi giàu hơn): (1) Echo Box không có điểm dừng, pool 335 món + cosmetic Season mới; (2) Mythic trùng đổi **Land Stone nhỏ** thay vì hoàn Shard (xử lý được dòng "Mythic hoàn 250 Shard" của bản JS: ở bản này hoàn Shard sẽ thành vòng lặp quay vô hạn); (3) "Gallery" mốc sưu tầm tiêu Shard để lấy khung danh hiệu (Prestige tier, tương đương Echo Point cũ, **chỉ ở profile, không lên leaderboard**).
**Kiểm**: Shard dư ròng sau mỗi tuần của người giỏi nhất phải ≤ 1 tuần thu nhập (chạy sim `t_economy` mới; tôi chưa có tool này).

### 3.4 Cái gì xử lý với unlock hiện có

| Unlock | Đề xuất | Lý do |
|---|---|---|
| `u_full` (mở Full) | Giữ, bỏ Shard, mở bằng "hoàn 1 run short" | Là cửa chuyển chế độ, không nên bán |
| `u_relic1/2`, `u_face1/2` | Thay bằng **relic/face discovery**: relic Epic/Legendary vào pool khi **gặp lần đầu**, không bán | Hiện đang inert; mở pool làm tăng bề rộng, đúng C6 |
| `u_reroll`, `u_reroll2`, `u_hp`, `u_hp2`, `u_start` | **Đóng băng trong Ranked profile**; ở chế độ thường giữ nhưng mua Shard rẻ + đổi sang **sidegrade** về sau (xem OQ-3) | Là sức mạnh vĩnh viễn ở tầng sưu tầm, trái C6 |

---

## 4. Land

### 4.1 Tier

| Tier | Biome | Rarity decor tối đa đặt được | Slot decor (ô iso) | Building | Thay đổi nhìn thấy |
|---|---|---|---|---|---|
| 1 | Savannah | Common | 40 | House, Mission house, Echo Box | Đất vàng, cỏ, cây baobab, đá |
| 2 | Forest | Uncommon | 70 | + Pass stall, Vault warehouse | Cây xanh, thêm ao/suối |
| 3 | Arctic | Rare | 110 | + Mastery hall | Tuyết, băng; Axie mặc áo ấm (tint) |
| 4 | Mystic | Epic | 160 | + Portal (Daily/Ranked) | Phát sáng, đom đóm |
| 5 | Genesis | Legendary | 220 | + Gallery (khung vinh danh) | Thêm bậc thang, tượng, tòa nhà lv3-4 |
| 6 | LunaLanding | Mythic | 300 | Cho đặt NFT-decor | Đá/cây đỏ pha lê (đúng sheet LunaLanding), mặt trăng trên trời |

- **Ranh giới nằm ở "đặt", không ở "sở hữu"**: món rarity cao hơn tier hiện tại vẫn rơi từ hộp, nằm trong Storage, nhìn được nhưng chưa đặt được. Cho người chơi cái đích để hướng tới (Premack: mục tiêu nhìn thấy).
- Building không có tier riêng, mà **tự lên cấp hiển thị theo Land tier** (House lv1 ở Savannah → lv4 ở Genesis; Homeland có lv1-4). Không đòi nâng từng building riêng, tránh sinh thêm sink.
- **Nhà phải có cửa vào rõ**: bấm hoặc Axie chạy vào là mở màn tương ứng (màn Godot đã có: Team Select, Vault, Pass, Codex).

### 4.2 Building list

| Building (asset sẵn có) | Chức năng | Phase |
|---|---|---|
| **House** (Homeland House lv1-4) | Bắt đầu run: Team Select, short/full, Ascension | 1 |
| **Mission house** (`SpyQuarter`) | Mua contract (§7) | 2 |
| **Echo Box house** (`Alchemy` hoặc `PotionMaker`) | Mở hộp, xem Storage | 3 |
| **Pass stall** (`EquipmentStall`) | Nhận mốc Pass | 2 |
| **Vault warehouse** (`GreenWarehouse`) | Vault: import Axie thật (đã có màn) | 2 |
| **Mastery hall** (`Weaponsmith`) | Mốc 6 class, chọn passive variant | 4 |
| **Portal** (`Portal`) | Daily seed, bảng xếp hạng, Ranked | 4 |
| **Gallery** (tự dựng từ `NFT_Item`/Atia) | Khung vinh danh, xem Land người khác | 5 |

Tôi **chưa xem contact sheet của Alchemy/Weaponsmith/Portal** (chỉ xem SpyQuarter, Savannah, LunaLanding); nhóm art cần xác nhận building nào đọc được là gì ở zoom của Land. SpyQuarter thực ra là một hồ nhỏ dưới cây phong, hợp với "nhà gián điệp" kém hơn tôi nghĩ.

### 4.3 Decor lấy từ đâu

| Nguồn | Tỷ lệ mục tiêu | Ghi chú |
|---|---|---|
| Echo Box | ~75% | Nguồn chính, mọi rarity |
| Mastery milestone | ~15% | Decor theo chủ đề class, chỉ rarity thấp-trung |
| Battle Pass | ~4% | Mốc "big" độc quyền theo season |
| Contract tuần | ~6% | Contract khó (x3) cho decor "Nguy hiểm" (theo chủ đề) |
| **Craft** | **Không** | Tôi khuyên *không* làm craft vật liệu (gỗ+đá → bàn). Đó là farming sim. Cho "Fuse 3 trùng → 1 bậc cao hơn" (đã có, F12) là đủ. |

**Land có cho sức mạnh không?** Khuyến nghị: **không cho sức mạnh combat**, kể cả nhỏ. Land cho: (a) slot Team preset (3 → 6 → 9), (b) thêm contract slot song song (1 → 3), (c) hiển thị (khung, Axie đi theo). Trade-off tôi thấy rõ: cho một chút buff (ví dụ +1 reroll ở Mystic) sẽ làm Land có "ý nghĩa" cho người chơi coi trọng sức mạnh, nhưng nó phá **leaderboard nội bộ công ty**: người chơi sớm hơn thắng vì Land chứ không vì kỹ năng, và với một game chọn nhân dạng "kỹ năng", đó là loại P2W theo thời gian. Nếu Liam vẫn muốn một chút sức mạnh thì phải khóa nó ở Ranked profile (OQ-3).

---

## 5. Chiều sâu combat và build

### 5.1 Bài học và nó thành gì ở đây

| Game | Bài học | Thành gì trong Axie Dice |
|---|---|---|
| **LoL/Dota** — itemization | Món đồ đổi vai trò, có counter (anti-heal, armor pen); địch tạo áp lực buộc phải "mua" counter | **Enemy trait** (§5.5): địch có 8 trait; mỗi archetype có ít nhất một trait khắc nó. Build phải có kế hoạch phụ chứ không đi một đường tới hết. |
| **Slay the Spire** | Boss relic có giá phải trả; elite thưởng chọn lọc; relic bẻ luật | **Boss relic có drawback**, "cursed reward" ở Ascension cao (§5.4). |
| **Balatro** | Thứ tự áp dụng, scaling, retrigger, risk-vs-reward, interest | Relic scaling (§5.3), retrigger mặt xúc xắc, Shard-trong-run tích lãi (cap). Chỉ nhân theo `mload` hiện có (F8). |
| **Monster Train** | Hai clan, nâng cấp theo nhánh | **Cặp class**: relic cross-class chỉ bật khi đủ 2-3 class trên bàn. |
| **Dicey Dungeons** | Xúc xắc cắm vào ô có điều kiện, reroll là tài nguyên | Relic chơi với bản thân xúc xắc: giữ mặt, copy mặt, "đôi" mặt (Snake Eyes). |

### 5.2 Tám build archetype

Dựa vào `ARCH` hiện có (F8), chọn **8 trục chính** để cân bằng; 3 cái còn lại (EVOLVE, SWARM, TEMPEST) giữ làm "build đặc biệt" cần kiểm lại sức mạnh.

| Archetype | Cách thắng | Class tự nhiên | Counter (nằm trong *địch*) | Counter (nằm trong *build khác*) |
|---|---|---|---|---|
| PLAGUE | Poison chồng tới chết | Bug | Địch **Cleanse** (xóa poison mỗi 2 lượt); địch **Chitin** (poison −50%) | TALON xong sớm hơn chờ poison |
| INFERNO | Burn lan/nhân đôi | Beast/Bird | Địch **Drench** (burn không áp) | APEX burst nhanh hơn |
| BULWARK/AEGIS | Shield→damage; thorns | Plant/Reptile | Địch **Corrode** (shield bay hết đầu lượt), kiểu **Pierce** | TALON bỏ qua shield |
| CONDUIT | Mana → nhiều active | Aqua | Địch **Silence** (khóa active 1 lượt), **Drain** | APEX/FERAL không cần mana |
| TALON | Pierce, kết liễu | Bird | Nhiều địch nhỏ (**Swarm**), mục tiêu đơn kém | TEMPEST |
| APEX | Crit lớn | (đa class) | Địch **Plated** (trần damage mỗi đòn) | PLAGUE/AEGIS đi vòng qua |
| FERAL | Exec <50% HP | Beast | Boss **Phase shield** (không xuống <50% trong vài lượt) | BULWARK chịu được và đợi |
| EVOLVE | Mặt xúc xắc lớn dần | (đa class) | Boss **Early Burst** (đánh mạnh lượt 1-3) | BULWARK câu giờ |

Đây là một vòng chéo không hoàn hảo, không phải rock-paper-scissors thuần: mục tiêu **không archetype nào thắng >60% hay <35%** ở A5 (sim 10.000 run mỗi archetype, ép sẵn qua relic). Mỗi archetype có 1-2 counter *thật* trong thế giới địch nên không bao giờ "đi một đường tới hết trên mọi bản đồ".

### 5.3 Gene Mutation + relic + class tạo combo

Công thức tôi dùng để thiết kế: **Passive class (có sẵn) × Relic engine (mua/nhặt) × Mặt đã Mutate (sửa mặt)**. Gene Mutation là chỗ người chơi *sửa chính xúc xắc* (rune gắn vào mặt) nên là kênh biểu đạt mạnh nhất (SDT: autonomy).

| Combo ví dụ | Passive | Relic | Mutation/rune | Kết quả |
|---|---|---|---|---|
| Poison đôi | Bug: poison chồng +2 | "Wither Lens": poison tick nhân 1.5 | Rune gắn poison lên mặt Shield | Mặt phòng thủ cũng nhiễm poison |
| Gai độc | Reptile: thorns+poison | "Bastion Plate" | Rune thorns vào mọi mặt shield | Thành tường độc |
| Mana vòng | Aqua: 4 mana → reroll | "Reroll Engine" (§5.3a) | Rune "refund 1 mana" | Chuỗi reroll → burst |
| Cross-class | Bird pierce + Plant shield | "Crossover Banner" | Rune trùng class | Đòn pierce từ shield |
| Glass cannon | Beast exec | "Glass Cannon Sigil" | Rune crit | Kết liễu nhanh nhưng mỏng |
| Late bloom | Plant | "Hourglass of Late Bloomers" | Rune growth | Trụ lâu, đánh mạnh dần |

**Ràng buộc để tránh hỏng** (kế thừa luật đã có): `mload ≤ 2` áp cho *tích mọi multiplier*, kể cả từ rune (F8). Mutation hạ mặt về Common theo D5. Mỗi mặt tối đa 1 rune. (Chi tiết 10 rune phải lấy từ nguồn JS, xem F14.)

**Khung phân loại relic mới** — mỗi relic chỉ thuộc 1 lớp, mỗi lớp có luật riêng:

| Lớp | Đặc điểm | Ràng buộc |
|---|---|---|
| Rule-bender | Đổi một luật cứng | Tối đa 1 trên bàn; bậc Legendary |
| Scaling | Mạnh dần theo lượt/node | Phải có reset (đầu trận / đầu run) |
| Risk | Cộng sức mạnh, trừ thứ khác | Trừ phải *thấy rõ* trước khi nhận |
| Dice-manip | Chơi với bản thân xúc xắc | Không được tạo vòng lặp reroll vô hạn |
| Cross-class | Cần ≥2-3 class trên bàn | Yếu khi đơn class (cân bằng bằng đa dạng) |

**12 relic ý tưởng** (idea-level, chưa có số):

| # | Tên | Lớp | Ý |
|---|---|---|---|
| 1 | Loaded Die | Dice-manip | 1 lần/lượt, đóng băng 1 xúc xắc sang lượt sau, nhưng lượt này không dùng được nó. |
| 2 | Mirror Shard | Dice-manip | Xúc xắc reroll copy mặt của xúc xắc kế bên (hy sinh đa dạng). |
| 3 | Snake Eyes Charm | Dice-manip | Hai xúc xắc cùng loại mặt trong 1 lượt → mặt thứ hai +50%. |
| 4 | Hourglass of Late Bloomers | Scaling | +1 mọi giá trị mặt mỗi 3 lượt sống sót trong trận; reset mỗi trận. |
| 5 | Echo Tail | Scaling (retrigger) | Mặt đầu tiên mỗi lượt kích hoạt 2 lần nếu nó là mặt thấp nhất; khoảng nhân chịu `mload`. |
| 6 | No-Wall Pact | Rule-bender | Không tạo được Shield; mọi giá trị Shield thành damage. Chặn Plant/BULWARK, thưởng TALON/APEX. |
| 7 | Pact of Two Worlds | Rule-bender | Chọn 2 class: cả hai passive áp cho mọi Axie; passive 4 class còn lại tắt. |
| 8 | Glass Cannon Sigil | Risk | Damage x1.4 (trong `mload`), max HP −30%. |
| 9 | Debt Ledger | Risk | Nhận ngay một relic Rare, trả bằng HP toàn đội trận kế tiếp. |
| 10 | Crossover Banner | Cross-class | Có ≥3 class: mỗi Axie mượn 50% passive của Axie bên trái. |
| 11 | Shard Interest | Scaling (kinh tế) | Mỗi node, +5% Shard-trong-run đang giữ (cap +25). Thưởng không tiêu, phạt mua sắm. |
| 12 | Cursed Hourglass (boss relic) | Risk/Rule | +1 hành động xúc xắc/lượt nhưng địch có thêm 1 intent. |

### 5.4 Tránh chiến lược thống trị

1. **Mỗi archetype có ít nhất 1 trait địch khắc nó** (§5.5), không phụ thuộc người chơi nhặt gì.
2. Giữ các luật sẵn có: `mload=2`, `ex` (chống trùng), D16 (≤2 cùng archetype trong 3 offer) (F8, F10).
3. **Số slot relic**: nếu hiện chưa có trần, thêm trần 7-8 (kiểu Joker slot của Balatro) để chọn có cái giá. *(Chưa verify trần hiện tại trong code; cần kiểm.)*
4. **Cờ cân bằng tự động**: sim hàng đêm, archetype nào vượt 60% hoặc dưới 35% win-rate ở A5 thì báo; mọi chỉnh sửa ghi vào changelog balance.
5. Ranked/daily: **seed cố định ⇒ offer cố định**, nên "build tốt nhất" không có lợi thế về RNG, chỉ có quyết định hay hay dở.

### 5.5 Enemy trait và Atia monsters

Hiện địch dùng sprite Chimera 2D (đã cố tình giữ ở `godot/CLAUDE.md`); thư viện có 235 monster Atia (3D). Đề xuất:

| Thay đổi | Cách làm |
|---|---|
| 6 vùng địch theo 6 biome | Mỗi vùng 4 monster thường + 2 elite + 1 boss. 6 × 7 = 42 monster dùng, 193 để dành mùa sau. |
| Trait | 8 trait: Cleanse, Chitin, Drench, Corrode, Silence, Plated, Swarm, Phase-shield. Mỗi monster mang 0-2 trait, hiện bằng icon rõ trên intent (Pillar "minh bạch triệt để", F8 doc). |
| Boss | 2 boss/vùng, mỗi boss 1 cơ chế đổi luật (không chỉ HP): ví dụ boss "Tide Mother" dọn sạch debuff mỗi 3 lượt, boss "Rock Warden" chỉ nhận ≤20% max HP mỗi đòn. Giữ `agony` là boss kết ở A10. |
| Art cần | Hỏi art: 42 monster có rig/animation đủ chưa, hay phải dùng sprite tĩnh. Đây là quyết định kỹ thuật, tôi không chốt. |

### 5.6 Map stakes (HP carry-over)

Hiện tại hồi đầy mỗi trận (F2) nên map không tạo áp lực. Ba lựa chọn:

| Lựa chọn | Mô tả | Ưu | Nhược |
|---|---|---|---|
| A. Giữ nguyên | Không carry | Không đổi luật, replay cũ còn hợp lệ | Map nhàm, elite chỉ là "trận khó hơn" |
| **B. Carry một phần (khuyến nghị)** | Sau trận hồi 50% HP đã mất; Axie chết trở lại 25% HP; thêm lựa chọn "Nghỉ" ở Event (hồi 40% max) | Có áp lực chọn đường, event hồi máu có giá | Phải cân lại budget `pw`; đổi `RULES_VERSION` (replay cũ vô hiệu) |
| C. Carry hoàn toàn | Như Slay the Spire | Căng nhất | Đẩy người chơi về build phòng thủ, giết đa dạng |

Khuyến nghị B, **tỷ lệ hồi giảm theo Ascension** (A0 60% → A10 30%), nhưng cần sim 3 lần: win-rate trung bình A0 giữ trong 55-65% so với hiện tại. Vì đụng luật combat nên chạy đủ `t_rules_version`, `t_replay`, `t_full_run_loop`.

### 5.7 Ascension thành luật mới (không chỉ số lớn)

Bảng đề xuất; giữ cột "số phụ" nhỏ để không bỏ hoàn toàn đường cong hiện tại (F7).

| A | Luật mới | Số phụ giữ lại |
|---|---|---|
| 1 | Sương mù: node cách >2 hàng ẩn loại | HP địch +5% |
| 2 | Elite mang 1 trait ngẫu nhiên | +1 elite/wave (đã có) |
| 3 | Tỷ lệ hồi sau trận 60% → 50% | dmg địch +5% |
| 4 | Boss có cơ chế phase mới | HP boss +10% |
| 5 | Một xúc xắc ngẫu nhiên bị "Jam" lượt đầu mỗi trận | weaken (đã có) |
| 6 | Shop: ít hơn 1 món, giá +20%, không reroll miễn phí | |
| 7 | Reward 2 lựa chọn (đã có) + một "cursed" xuất hiện | |
| 8 | Hồi giảm còn 40%; heal từ relic −50% | dmg địch +10% |
| 9 | Elite thêm 2 (đã có) + elite có trait kép | |
| 10 | Boss cuối: hai pha, trait kép; tính điểm lên bảng Ascension | |

Các mốc này **cần sim**; tôi chưa có số win-rate hiện tại. Ghi chú: "ẩn intent" là ý tưởng phổ biến ở roguelike nhưng bị loại vì xung đột Pillar *Minh bạch triệt để* (`relic-system.md` header).

---

## 6. Battle Pass, Echo Box, Mastery

### 6.1 Battle Pass (cố định trước, sau thành mùa)

- **Một track miễn phí duy nhất** (không có store). Giữ 30 level, giữ công thức XP hiện có (F5, F6): tổng 10.920 XP. Với run trung bình ~350 XP, đủ ~31 run, khoảng 2-3 tuần chơi thường. Ngắn: đây là "Pass nhập môn", mùa kế tiếp có thể dài hơn.
- **Cắt khỏi Pass**: perk HP/reroll/relic khởi đầu (vi phạm C6, F5b). Mốc `face` thay bằng "relic discover" hoặc cosmetic.

| Level | Reward | Loại |
|---|---|---|
| 1, 4, 7, 10, 13, 16, 19, 22, 25, 28 | Shard (200→700 tăng dần, tổng ~3.000) | Currency |
| 3, 9, 14, 20, 26 | Vé Echo ×1 (tổng 5; lv30 thêm ×3) | Item |
| Mỗi 5 level | Land Stone ×6 (tổng 36) | Currency |
| 5, 12, 19 | Relic discover (Epic cố định) | Pool breadth |
| 8, 15, 23, 30 | **Cosmetic độc quyền Season 1** (decor Rare, khung, die skin Epic, danh hiệu "LUNACIA SOVEREIGN" ở lv30) | Cosmetic |
| 11, 17, 24 | Decor thường ×1 | Cosmetic |

**Thiết kế sẵn cho mùa**: toàn bộ track nằm trong `pass_season_<id>.json` (`id`, `start`, `xp_curve`, `rewards[]`); XP lưu theo `season_id`; Season hết thì XP reset, cosmetic Season tag "Season N" nhưng **về sau xuất hiện trong Echo Box** (không biến mất vĩnh viễn: tránh FOMO không cần thiết; mỗi mùa có 2 món "mới nhất" thể hiện bằng huy hiệu tag).

### 6.2 Class Mastery (thay World Tour/Moon Dust)

Một thanh theo class (6 class: plant/beast/aqua/reptile/bug/bird).

- **XP class** = XP run × (số Axie class đó / 5) cho mỗi class trong đội (đội 3 Plant + 2 Beast: 60% Plant, 40% Beast). Run đơn class nhận XP đầy đủ nhưng ép Axie đa dạng nên vẫn chọn.
- Đường cong: `need(L) = 80 + 40(L−1)`, L=1..20, tổng 9.200 XP/class. ~140 XP class/run ⇒ ~65 run/class ⇒ 6 class ~390 run (~160h).

| Level | Reward |
|---|---|
| 1 | Danh hiệu class |
| 3 | Khung avatar class (Common) |
| 5 | Decor chủ đề class ×1 + 2 Land Stone |
| 8 | Die skin class (Rare) |
| 10 | **Passive variant**: chọn phiên bản B của passive class (sidegrade, vd Plant "Bramble": shield +1 và thorns +3). Chọn trước run, đổi tự do |
| 12 | Relic mới của class vào pool (breadth) |
| 15 | Axie accessory chủ đề (Epic) |
| 20 | Hiệu ứng aura class (Legendary) + danh hiệu "Master of X" |

Mọi level cho 2 Land Stone (tổng 240, đã tính ở §3.2). **Hai luật**: Mastery chỉ cho bề rộng; passive variant phải **cân bằng sức mạnh ngang bản gốc** (sim), nếu không nó là perk trá hình.

### 6.3 Echo Box (thích nghi từ design cũ)

| Thay đổi so với bản JS (F12) | Lý do |
|---|---|
| Rarity 5 bậc → **6 bậc đúng thang Land** (Common→Mythic = Savannah→LunaLanding) | Rarity của vật phẩm trùng biome của nó: món Genesis đặt ở tier 5. Đọc được, chia sẻ ngôn ngữ. |
| Tỷ lệ: 55 / 27 / 11 / 5 / 1.7 / 0.3 (%) | Mở rộng [62, 27, 9, 1.7, 0.3] hiện có theo tinh thần "Mythic cố tình cực hiếm" |
| Giá **250 Shard phẳng** (bỏ `500×1.035^n`) | Ở thang 4-6 hộp/tuần, giá lũy tiến làm hộp thứ 100 thành sink đau mà vô nghĩa. Sink dài hạn đã chuyển sang Land. |
| **Pity**: 10 hộp bảo đảm ≥Rare; 50 hộp bảo đảm ≥Epic; công bố tỷ lệ trong UI | Ethical gacha (F12 chưa có pity) |
| Danh mục: decor 50%, thú cưng 12%, die skin 10%, tòa nhà skin 6%, accessory 8%, khung 6%, danh hiệu 5%, FX 3% | Khớp §8 |
| **Trùng**: 3 trùng cùng bậc → 1 món chưa có bậc trên (giữ); Mythic trùng → 3 Land Stone, không hoàn Shard | Tránh vòng lặp Shard |
| ×10: 2.250 Shard (giảm 10%) | |

**Echo Box có thể làm Shard "đổ về" tầng cosmetic, không chạm sức mạnh**. Điều này giữ luật 1 của rào chắn P2W (Echo Rank không hiện trên leaderboard).

---

## 7. Contract — Risk to earn (Mission house)

### 7.1 Luật

- Mua contract ở Mission house **trước khi vào run**, tối đa **1 contract/run**, 1 slot (Land cao mở thêm tới 3 slot nhưng vẫn 1 contract/run; slot thừa để chọn trước hôm sau).
- Trả `stake`. Hoàn thành: nhận `stake × m`. Thất bại (hoặc bỏ run): mất stake.
- `m` ∈ {1, 2, 3}. **×1 là "hoàn stake" (hòa vốn)**, giá trị nằm ở phần thưởng kèm (XP Mastery, Land Stone, decor), không phải lãi Shard. *(Tôi hiểu "×1" theo nghĩa này; OQ-5.)*
- Kiểm chứng bằng **replay verifier**: mọi điều kiện tính từ `run_stats` + `ActionLog` header, nên không thể khai gian.

### 7.2 Loại nhiệm vụ (đều dựa vào thứ game đã theo dõi, F11)

| Loại | Điều kiện | Dữ liệu |
|---|---|---|
| Glass | Thắng run, `taken` ≤ N | `taken` |
| Blitz | Thắng với `turns` ≤ N | `turns` |
| Heavy Hitter | Một đòn `max_hit` ≥ N | `max_hit` |
| Massacre | `kills` ≥ N trước boss | `kills` |
| Pure | Đội 1 class / 3+ class | team classes |
| Ascension | Thắng ở A≥k | `ascension` |
| Full Course | Thắng Full mode | `mode` |
| Detour | Không ghé shop / chỉ ghé elite | visited nodes |
| Minimalist | Thắng với ≤K relic | relics |

### 7.3 Stake và trần

| Tier | Stake | m | Ngưỡng gắn với "Rating" người chơi (tỷ lệ thắng gần đây) |
|---|---|---|---|
| Safe | 100 | ×1 | p ≈ 85% |
| Standard | 200 | ×2 | p ≈ 45% |
| Hard | 400 | ×3 | p ≈ 25% |

- **EV ròng** = stake × (p·m − 1). Standard p=45% ⇒ −10%; Hard p=25% ⇒ −25%; Safe luôn ≥ 0. Người chơi trung bình mất nhẹ, người giỏi chỉ hòa hoặc lãi nhỏ.
- **Ngưỡng tự co giãn theo người chơi** (Rating = win-rate 20 run gần nhất, ví dụ): người giỏi nhận ngưỡng khó hơn, giữ p·m ≈ 1 ở mọi trình độ.
- **Trần cứng** (nếu ngưỡng sai): tối đa **2 contract/ngày**, lãi Shard ròng tối đa **+120/ngày** (khoảng 840/tuần ≈ 1/3 thu nhập, sau đó vẫn nhận phần thưởng phi-Shard), 1 contract/run, stake ≤ 25% số Shard đang có.
- **Chống "farm contract"**: người giỏi không thể rút vô hạn vì (a) trần lãi/ngày, (b) mỗi lần thắng liên tiếp, ngưỡng cùng loại +1 bậc ("Heat"), (c) contract chỉ cho phép ở run thường, không cho ở Daily seed (seed cố định, tránh người chơi thử nhiều lần cho tới khi chắc thắng).
- **Cần sim**: p(skill) theo percentile để chốt ngưỡng; hiện chưa có dữ liệu thật.

### 7.4 Phần thưởng kèm

x1: +XP Pass; x2: + 1 Land Stone; x3: + decor "Nguy hiểm" (chủ đề) mỗi tuần 1 lần.

---

## 8. Competition

| Thành phần | Thiết kế |
|---|---|
| **Daily seed** | Mỗi ngày UTC một seed: map, reward offer, RNG combat giống nhau. Qua Portal. Mỗi ngày tối đa 3 lần thử. |
| **Ranked profile** | Bỏ hết perk/unlock cộng chỉ số, relic khởi đầu cố định. Chỉ còn Ascension + đội hình tự chọn. Giữ đúng luật "tầng sưu tầm = bề rộng" cho đo kỹ năng. |
| **Điểm** | `score = 1000×thắng + 40×node_cleared + max(0, 300−turns) + 2×HP_còn + 100×A`. Chỉ là first-pass; hòa → turns ít hơn. |
| **Xác minh** | Client gửi action log; server chạy `RunVerifier` (đã có, `t_replay` 47 check). Không verify được thì không lên bảng. |
| **Bảng** | Ngày, tuần, và Ascension 10 cả mùa. **Bảng công ty**: nhóm theo domain email đăng nhập Google (đã có tài khoản, F: `worker/src/accounts.js`). *Cần đồng ý quyền riêng tư + terms (OQ-6).* |
| **Land và contract vào bảng thế nào** | Không vào điểm. Hiện **khung, danh hiệu, Axie đi theo** cạnh tên (flex cosmetic); bấm tên để **tham quan Land** (snapshot chỉ-đọc). Contract tuần cho điểm "Season" riêng (đếm mission hoàn thành), không cộng điểm daily. |

---

## 9. Danh mục cosmetic cần có (spec cho art team, bản phát hành nội dung đầu tiên)

Số lượng/ bậc (Common→Mythic = Savannah→LunaLanding). **Cột "Nguồn"**: E = đã có asset 3D, cần chọn lọc; L = cần chỉnh nhẹ (material/tint/attach); N = art mới.

| Category | Nguồn | C | U | R | E | L | M | Tổng |
|---|---|---|---|---|---|---|---|---|
| Decor đất (cây, đá, tile, đường) | E (biome sheet) | 14 | 12 | 10 | 8 | 6 | 4 | 54 |
| Decor nội thất/vật phẩm | E (Atia furniture, NFT_Item) | 16 | 16 | 14 | 12 | 10 | 8 | 76 |
| Thú cưng đi theo/lang thang | E (149 mascot) | 12 | 10 | 8 | 6 | 4 | 3 | 43 |
| Skin tòa nhà (2 variant `_F_01/_02` đã có thể dùng cho tier thấp) | L | 0 | 2 | 2 | 3 | 3 | 4 | 14 |
| Phụ kiện Axie (vũ khí/đồ cầm tay, 164 weapon) | E+L (attach) | 10 | 8 | 6 | 6 | 4 | 2 | 36 |
| Tint/aura Axie | L (shader) | 4 | 3 | 3 | 2 | 2 | 1 | 15 |
| Die skin (chất liệu xúc xắc 3D) | N | 4 | 4 | 4 | 3 | 3 | 2 | 20 |
| Khung avatar | N (2D) | 5 | 4 | 4 | 3 | 3 | 2 | 21 |
| Danh hiệu | chữ (narrative) | 12 | 10 | 8 | 6 | 4 | 2 | 42 |
| FX roll/trail | N (VFX) | 3 | 3 | 3 | 2 | 2 | 1 | 14 |
| **Tổng** | | 80 | 72 | 62 | 51 | 41 | 29 | **335** |

**Phân bổ nguồn (335 món)**: Echo Box ~255 (76%), Mastery 48 (6 class × 8), Pass Season 1: 12, contract 20.
**Art mới thực sự (N)**: 20 die skin + 21 khung + 14 FX = 55 món; 15 tint + 36 accessory cần việc kỹ thuật; còn lại (~245) **không cần art mới**, chỉ cần curate prefab đã có.
**Tính hợp lý**: ở 6 hộp/tuần, ~40 tuần mới đủ 335 món nếu không trùng; trùng làm dài hơn, phù hợp mục tiêu 160-giờ.
Lưu ý (F13): biome sheet chủ yếu là terrain/cây/đá, nên "decor đất" Savannah/Forest dễ dồi dào, nhưng Mythic (LunaLanding) hiện chỉ thấy đá pha lê/cây đỏ — đủ cho 4 món nhưng cần xem thêm nếu muốn nhiều hơn.

---

## 10. Phasing

| Phase | Nội dung | Phụ thuộc | Ship được gì |
|---|---|---|---|
| **P1 — Nền combat** | Port Gene Mutation (FACE_POOL, runes), sửa 5 mốc Pass chết, 4 unlock inert, "Ranked profile" khung, HP carry-over B, enemy trait + 1 vùng địch Atia, Ascension luật mới | Đọc `git show 5e34a17^`; bump `RULES_VERSION`; sim | Game combat sâu hơn, chơi được hoàn toàn trong menu hiện tại. **Không cần Land.** |
| **P2 — Land v0** | Cảnh Land 3D (Savannah), Axie đi lại, House/Pass stall/Vault/Mission house làm cửa vào màn đã có; Land Stone; contract; Pass bản mới | P1 (cân bằng xong), asset prefab | Mở game vào Land, mua contract, chơi run, nhận thưởng |
| **P3 — Echo Box + decor** | Echo Box, Storage, chế độ đặt decor, 6 tier, ~150 món đầu (decor + thú) | P2, art curate | Vòng sưu tầm + sáng tạo |
| **P4 — Competition + Mastery** | Daily seed, Portal, leaderboard, Mastery hall, passive variants | P1 (Ranked profile), P3 để có flex | Vòng thi đấu hàng ngày |
| **P5 — Mở rộng** | Gallery, tham quan Land, Season 2, thêm 5 vùng địch, thêm relic lớp mới | P4 | Nội dung sống |

Mỗi phase ship độc lập, và P1 có giá trị ngay cả khi Land chưa xong.

**Cắt hoặc hoãn**: World Tour, Moon Dust (đã chốt); mọi building sản xuất (Mine/Smelter/Field...); craft vật liệu; Land buff; premium pass; **Echo Point/Prestige riêng** (gộp vào Gallery); thêm currency thứ ba.

---

## 11. Câu hỏi mở cho Liam (mỗi cái kèm đề xuất)

| # | Câu hỏi | Đề xuất của tôi |
|---|---|---|
| OQ-1 | Chấp nhận **2 currency** (Shard + Land Stone) thay vì 1? | Có. Một currency làm contract thành đường tắt lên Land. |
| OQ-2 | Echo Box giá phẳng 250 thay vì lũy tiến cũ (`economy-progression.md` §10)? | Phẳng; cần Liam xác nhận vì ngược với bản đã duyệt. |
| OQ-3 | Với unlock cộng chỉ số (`u_hp`, `u_reroll`...) và perk Pass: (a) xóa hẳn, (b) giữ ở chế độ thường nhưng khóa ở Ranked, (c) đổi sang sidegrade? | (b) ngắn hạn, (c) dài hạn. Xóa thì người đã mua mất thứ họ mua. |
| OQ-4 | HP carry-over: A, B hay C? Chấp nhận phá replay cũ (đổi `RULES_VERSION`)? | B, vì replay cũ hiện không có giá trị ngoài test. |
| OQ-5 | "×1" của contract = hoàn đúng stake (hòa vốn)? | Có, nhưng kèm thưởng phi-Shard. Nếu ý Liam là "thắng thêm 1×" thì kinh tế đổi (lãi gấp đôi) và phải hạ trần. |
| OQ-6 | Bảng công ty theo domain email Google: có đồng ý không, người chơi có thể ẩn không? | Có, opt-out mặc định bật hiển thị tên; cần xem terms/privacy hiện có (`worker/src/legal.js`). |
| OQ-7 | Dùng monster Atia 3D thay cho sprite Chimera 2D? | Làm thử 1 vùng ở P1 để đo chi phí rig/animation trước khi cam kết 6 vùng. |
| OQ-8 | **Không có real-money store**: có chấp nhận hẳn không, ngay cả cho season sau? | Có. Nếu sau này có, phải làm lại §3 và §6 (premium track, giá Echo Box, pity pháp lý). |
| OQ-9 | Land có tham quan được giữa người chơi (snapshot chỉ-đọc) không? | Có ở P5, không trước đó; cần server lưu snapshot (`SaveStore`). |

---

## 12. Rủi ro tôi thấy (không có trong 9 mục nhưng Liam nên biết)

1. **Land 3D sống động là phần tốn nhất.** Cảnh, camera, điều hướng Axie, chế độ đặt decor, lưu layout (qua `SaveStore`, CLAUDE.md) là nhiều tháng. P1 được thiết kế để không phụ thuộc nó.
2. **Contract, Echo Box, Pass cùng nhắm vào Shard**: nếu faucet ~150/run sai (chưa đo trên Godot, F3), mọi bảng trong §3 xô lệch. Việc đầu tiên của P1: đo thật.
3. **Đổi luật combat** (HP carry-over, trait) ảnh hưởng `RULES_VERSION`, 19 file fingerprint trong `t_rules_version`, và toàn bộ `t_full_run_loop` (197 check). Lên kế hoạch test floor cùng lúc.
4. **Số lượng nội dung trong §5 và §9 rất lớn** cho một team nhỏ; phần "chiều sâu" tôi khuyên làm *trước* cosmetic, vì nó quyết định người chơi quay lại hay không, còn cosmetic chỉ làm họ ở lại lâu hơn.

*Kiểm số*: 10.920 XP Pass = 30×45 + 22×(0+1+…+29)= 1.350 + 22×435 = 10.920. Tổng Shard Pass hiện tại = 4.870. Tổng unlock hiện tại = 3.450. Tổng Land Stone tier = 30+80+160+300+450 = 1.020. Tổng Shard phí Land = 300+1.000+2.500+5.000+10.000 = 18.800. Tổng cosmetic bảng §9 = 335 (cột: 80+72+62+51+41+29).
