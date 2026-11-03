# Bảng tồn kho cuối: làm lại art AI (3/11)

Chỉ đọc kho, không sửa code, không commit. Người làm: technical-artist. Liam xem bảng này TRƯỚC khi gửi brief cho Claude Design.

Phạm vi lấy từ mục "Liam quyết (3/11)" trong `production/qa/art-provenance-0311.md`. Quy tắc: kho có thì dùng luôn; kho không có thì Claude Design vẽ lại bám kho (tô / ghép từ asset chính thức, đúng style đồ kho).

Viết tắt: `DL/` = `asset-library/design-library/`, `IT/` = `DL/art-2d/items/`, `IC/` = `DL/icons/`. Mã `a..`, `f..`, `s..`, `m..` là tên file trong `IT/` (ví dụ `s19a` = `IT/s19a.png`); xem `DL/_sheets/art_2d_items_1/2/3.jpg`.

Ảnh kèm (mỗi ảnh < 1 MB, bên trái là ảnh đang dùng trong game, sau vạch vàng là đồ kho để bám):
- `production/art-redo-0311-sheet-A.png`
- `production/art-redo-0311-sheet-B.png`
- `production/art-redo-0311-sheet-C.png`

Hai điều cần biết trước khi đọc:
1. Kho không có chút nào kiểu UI: không có khung thẻ, khung tròn, ổ cắm, glyph (khoá, menu, undo...), huy hiệu nhà. Chỉ có vật thể sơn kiểu Homeland (rương, đá, tinh thể, cờ, bình, nấm...). Nên "bám kho" nghĩa là: lấy HÌNH DÁNG, CHẤT LIỆU, BẢNG MÀU, NÉT SƠN (viền mảnh tối cùng tông, tô khối mềm, highlight trắng ấm) từ những vật này.
2. Kho CÓ vài sinh vật kiểu Axie / quái trong tranh: `IT/a14a` (khối băng có sinh vật), `IT/a16a/b/c` (quả cầu có sinh vật), `IT/a7a/c` (búp bê lồng nhau), `IT/a10a` (hộp hề), `IT/m13` (thú nhồi bông), `IT/s12a/b/c` (mặt nạ). Với các món này CHỈ bám khung / chất liệu / màu / dáng ngoài, KHÔNG vẽ lại sinh vật bên trong. Không món nào được vẽ Axie.

---

## Gói A. Thẻ Lõi (ui6 đang dùng + hướng mới)

Ảnh: `production/art-redo-0311-sheet-A.png`. File game nằm ở `godot/assets/ui6/`. 3 bậc = moss / amber / crystal. Tổng 71 file PNG, 26 món logic (không tính cỡ 32/64/128).

Nguyên tắc chung cho cả gói: 3 bậc phải đọc ra bằng CHẤT LIỆU + MÀU, không chỉ đổi màu. Bậc 1 moss = đá xám/gỗ + rêu xanh. Bậc 2 amber = gỗ nâu + viền vàng. Bậc 3 crystal = đá xanh lam + tinh thể. Bộ rương `s19a/b/c` (nâu / lục-vàng / tím-xanh) và bàn `a19a/b/c` (đá / gỗ / gỗ có sao) đã có sẵn đúng cách phân bậc đó.

### A1. Khung, crest, art window, mặt sau

| món (file game) | dùng ở đâu | kho có dùng luôn? | nếu vẽ: món kho để bám | kích thước cần | ghi chú |
|---|---|---|---|---|---|
| `frame_core_moss.png` | CoreCard (NinePatch) | không | `IT/a19a.png` (bàn đá xám: chất liệu đá khắc vân, góc bo), `IT/s19a.png` (rương nâu, nẹp xám: cách làm nẹp góc) | 400x600, nine-patch [100,64,100,60] | Giữ lỗ giữa trống để đặt art window. Rêu phủ góc (xem `IT/f14c.png`) |
| `frame_core_amber.png` | CoreCard | không | `IT/a19b.png` + `IT/a19c.png` (gỗ cam, nẹp), `IT/s19b.png` (viền vàng dày) | 400x600, nine-patch [56,56,56,60] | Bậc amber có viền vàng mảnh hơn, nên margin nhỏ hơn 2 bậc kia. Giữ đúng 56 |
| `frame_core_crystal.png` | CoreCard | không | `IT/s19c.png` (rương lam-tím, nẹp xanh nhạt), `IT/s17a.png` (tinh thể xanh mọc ở góc) | 400x600, nine-patch [100,64,100,64] | Tinh thể ở góc nằm trong vùng patch 100x64, đừng tràn ra giữa |
| `frame_run_rule.png` | RuleCard (Luật run) | không | `IT/f14c.png` (đá rune xoắn), `IT/f9a.png` (cột đá có hoa văn), `IT/a19a.png` (đá khắc) | 520x600, nine-patch [48,48,48,52] | Phải khác khung Lõi: đá khắc thuần, không rêu, không bậc |
| `crest_moss.png` | TierCrest (đặt giữa mép trên thẻ) | không | `IT/a20a.png` (hoa tinh thể xanh lam: dáng cánh toả), `IT/makerdao1.png` (đế xoắn vàng) | 160x84, trong suốt | Dạng huy hiệu có 2 cánh rộng. Ô giữa chứa biểu tượng bậc (lá) |
| `crest_amber.png` | TierCrest | không | `IT/makerdao3.png` (chỉ cái này) | 160x84 | Biểu tượng bậc: giọt vàng |
| `crest_crystal.png` | TierCrest | không | `IT/makerdao2.png` (sừng xanh), `IT/a20b.png`, `IT/a20c.png` (hoa tinh thể lam) | 160x84 | Biểu tượng bậc: tinh thể |
| `artwin_moss.png` | ArtWindow (cửa sổ tranh giữa thẻ) | không | `IT/a14a.png` (khối băng: chỉ bám khung băng bo tròn, KHÔNG vẽ sinh vật bên trong), `IT/a16a.png` (chỉ bám vành kính + đế) | 352x160, nine-patch [28,28,28,44] | Phải là khung trống, tranh Lõi nằm trong |
| `artwin_amber.png` | ArtWindow | không | `IT/a16b.png`, `IT/a16c.png` (chỉ bám đế vàng cam, bỏ sinh vật trong cầu) | 352x160, nine-patch [28,28,28,28] | |
| `artwin_crystal.png` | ArtWindow | không | `IT/a14c.png` (băng, bỏ cây bên trong), `IT/s17a.png` | 352x160, nine-patch [28,28,28,40] | |
| `back_art_moss/amber/crystal.png` | CoreCardBack (mặt sau thẻ) | không | `IT/s18a/b/c.png` (chậu / bát có chân, 3 bậc: nâu mộc / cam / lam có hoa văn: bám miệng bát và hoa văn), `IT/s3b.png`, `IT/s3c.png` (cột totem) | 200x200 mỗi cái, tròn trên nền trong suốt | Medallion tròn, biểu tượng bậc ở giữa. s18a→c cho cách tăng độ cầu kỳ theo bậc |

### A2. Ổ cắm (socket / slot)

| món | dùng ở đâu | kho có dùng luôn? | nếu vẽ: món kho để bám | kích thước cần | ghi chú |
|---|---|---|---|---|---|
| `slot_moss_{32,64,128}.png` | CoreSlot (Cores strip, DiceDock, EnemyColumn, Tutorial, ô bán shop) | không | `IC/gem_ring.png` (vòng) + `IT/f14c.png`, `IT/s5a.png` (chất liệu đá) | 128 (xuất thêm 64, 32), tròn, giữa trong suốt | Vòng ổ, giữa rỗng để thả shard/Lõi vào |
| `slot_amber_*` | như trên | không | `IC/gem_ring.png` (vòng vàng) + `IT/s5b.png`, `IT/s19b.png` | như trên | |
| `slot_crystal_*` | như trên | không | `IC/gem_ring.png` + `IT/s5c.png` (đá lam), `IT/s17a.png` | như trên | |
| `slot_empty_*` | như trên | không | `IC/gem_ring.png` + `IT/s5a.png` (đá, không màu bậc) | như trên | Ổ chưa có gì: tối, viền đứt hoặc trơn |

### A3. Family, badge, shard-awaken

| món | dùng ở đâu | kho có dùng luôn? | nếu vẽ: món kho để bám | kích thước cần | ghi chú |
|---|---|---|---|---|---|
| `family_stat_*` (tim) | CoreCard, Tooltip, CorePanel, CoreStrip | không dùng luôn được (kho không có tim) | `IC/strawberry.png`, `IC/peach.png` (độ bóng, tô khối, highlight) | 128/64/32 | Vẽ trái tim theo cách tô của dâu/đào |
| `family_dice_*` (xúc xắc) | như trên | không | mặt xúc xắc 3D của game (chấm kem): `godot/assets/dice/axie_die.glb` + `cosmetics/dice/die_c_*/albedo.png` (chưa có PNG 2D, cần chụp), `IC/wood_plank.png` (chất liệu gỗ). Bỏ `a10a`/`m13` (có hề / thú nhồi bông) | 128/64/32 | Khối lập phương, chấm kem như xúc xắc trong game
| `family_quest_*` (cuộn) | như trên | không | `IT/s21a/b/c.png` (băng cờ vải treo cột sừng: chất liệu vải, nếp, hoa văn) | 128/64/32 | Vẽ cuộn giấy/băng rôn bằng chất vải của cờ |
| `family_run_rule_*` (đồng hồ cát) | RunRuleSlot, RuleCard | không | `IT/f4b.png` (cột đá gãy: chất liệu thân), `IC/gem_orange.png` (cát màu hổ phách) | 128/64/32 | Khung đá/gỗ, cát vàng. Kho không có đồng hồ cát |
| `family_pos_*` (cờ) | như trên | **ĐÃ là bản kho** (`ui6/lib`, từ `IT/s21`) | chỉ nhắc để khỏi nhầm | | Không thuộc phạm vi làm lại |
| `family_mana_*` (bình), `family_rule_*` (đá khắc) | như trên | **ĐÃ là bản kho** (`IT/s16b`, `IT/f14c`) | | | Không làm lại. Gói A cần giữ cho 4 emblem mới cùng bộ với 3 emblem này |
| `badge_attack_*` (kiếm) | CoreCard badge row | **dùng luôn**: `IC/wooden_sword.png` | | 128/64/32, cắt vuông, đứng chéo nếu cần | Đơn giản nhất |
| `badge_egg_*` (trứng) | như trên | **dùng luôn**: `IC/egg.png` | | 128/64/32 | |
| `badge_tradeoff_*` (cân) | như trên | không | chỉ bám màu và độ bóng: `IC/gem_red.png` | 128/64/32 | Biểu tượng "được cái này mất cái kia", ví dụ cái cân. Không bám sinh vật `spiky_ball`
| `badge_convert_to_dmg_*` (tia chớp) | như trên | không | chỉ bám màu và độ bóng: `IC/gem_orange.png` | 128/64/32 | Kho không có tia chớp |
| `badge_nonattack_*` (khiên) | tooltip/frame cũ, README bảo ẩn | không | `IC/stone_block.png` (khối đá), `IT/s15a.png` (mặt gỗ) | 128/64/32 | Nên bỏ nếu badge này luôn ẩn. Hỏi Liam |
| `badge_front_*` (chevron) | CoreCard | không | | | Nên bỏ (trùng family_pos). Hỏi Liam |
| `ui_awaken_*` (sao vàng) | AnchorTile/Chip/Fx | **dùng luôn (phương án vật thật)**: `IC/gem_orange.png` hoặc `IT/s17c.png` | (nếu Liam muốn vẽ: `IC/gem_orange.png` + `IT/makerdao1.png`) | 128/64/32 | Tinh thể vàng nhỏ phát sáng thay cho sao phẳng |
| `shard_*` / `shards_*` (3 bậc) | TierShards, CoreSlot, shop | **ĐÃ là bản kho** (`ui6/lib`: gem_green / gem_orange / diamond) | | | Không thuộc phạm vi |

### A4. Hiệu ứng hạt (fx)

| món | dùng ở đâu | kho có dùng luôn? | nếu vẽ: món kho để bám | kích thước cần | ghi chú |
|---|---|---|---|---|---|
| `fx_sparkle_*` | CoreFireFX, reveal | **KHÔNG gửi Claude Design**: làm bằng code (gradient / shader hạt) | (không cần) | 128/64/32, trắng ấm trên trong suốt | Texture hạt, dễ làm |
| `fx_bubble_*` | như trên | **KHÔNG gửi Claude Design**: làm bằng code (gradient / shader hạt) | (không cần) | 128/64/32 | |
| `fx_leaf_*` | như trên | **dùng luôn**: cắt từ `IT/f13a.png` | (không cần) | 128/64/32 | Lá có gân, tô khối |
| `fx_pulse_*` | như trên | **KHÔNG gửi Claude Design**: làm bằng code (gradient / shader hạt) | (không cần) | 128/64/32 | Vòng/quầng mềm |
| `fx_rays_crystal.png` | như trên, bậc crystal | **KHÔNG gửi Claude Design**: làm bằng code (gradient / shader hạt) | (không cần) | 1024x1024 | Tia sáng toả, tinh thể |

### A5. Mới thêm

| món | dùng ở đâu | kho có dùng luôn? | nếu vẽ: món kho để bám | kích thước cần | ghi chú |
|---|---|---|---|---|---|
| **Hiệu ứng Lõi kích hoạt (hướng mới)**: thay đường chấm / mũi tên xuống Axie | CoreFireFX khi một Lõi nổ | một phần: `godot/assets/vfx/*.png` là VFX kỹ năng chính thức Origins (42 file: `*_cast`, `*_projectile`...) có thể đặt lên Axie đích | `IC/gem_*`, `IT/s17a-c.png` (hạt tinh thể bay), `fx_sparkle` (A4) | cần quyết hướng trước, chưa ra kích thước | CÂU HỎI cho Liam: bỏ hẳn đường nối, hay giữ nhưng đổi thành "thẻ Lõi sáng lên + hạt bay tới Axie"? Ra hướng rồi mới đặt brief. Gợi ý: thẻ phát sáng ở chỗ, hạt bay theo cung, rơi lên Axie đích bằng 1 vspark. Phần lớn là code + vài sprite A4, ít cần vẽ mới |
| **Icon riêng từng Boss Pact (9)** | màn Pact sau boss, thẻ pact trong shop/run | không | dùng cùng thế giới vật phẩm kho: xem bảng dưới | 128/64/32, mỗi cái 1 file | 9 pact lấy từ `godot/resources/relics/*.tres` (`pact_group` khác rỗng) |
| **Minh hoạ Luật run (nếu cần)** | RuleCard | không | `IT/f14c.png`, `IT/f9a.png` | tuỳ | Liam quyết có cần không. Có `frame_run_rule` + `family_run_rule` rồi, có thể đủ |

Chi tiết 9 Boss Pact (nhóm theo `pact_group`):

| pact | nhóm | gợi ý hình (Liam / art-director quyết) | món kho để bám |
|---|---|---|---|
| Blood Pact | reroll | giọt máu / khế ước | `IC/gem_red.png` (đỏ), `IT/s16c.png` (chỉ bám bình hồng, bỏ sinh vật) |
| Lone Wolf Contract | reroll | cuộn hợp đồng + vết cào | `IT/s21a.png` (vải rách), `IC/feather.png` |
| Twin Fates | reroll | hai viên đối xứng | **dùng luôn (vật thật)**: `IC/gem_pink.png` + `IC/gem_red.png` ghép đôi |
| Brittle Dice | dice | xúc xắc nứt | bám chất liệu `IT/f4b.png` (đá gãy); vẽ xúc xắc như family_dice |
| Iron Vow | dice | thỏi sắt | **dùng luôn (vật thật)**: `IC/ingot_iron.png` |
| Patient Fang | dice | răng nanh | `IC/ingot_silver.png` + dáng sừng `IT/makerdao2.png` |
| Tithe of Pips | dice | thỏi / đồng vàng | **dùng luôn (vật thật)**: `IC/ingot_gold.png` |
| Devil's Reroll | mana | xúc xắc đỏ lửa | bám màu `IC/gem_red.png`, `IC/ore_red_raw.png`; không bám `spiky_ball` / `m14` (sinh vật) |
| Hollow Chalice | mana | chén rỗng | `IT/s16a.png` (bình), `IT/s11c.png` (bình ngọc) |

(Lưu ý: tên hình là gợi ý của tôi, không phải quyết định. Art-director chốt.)

### Tổng gói A

| | số món |
|---|---|
| Dùng kho luôn | **4** món ui6: badge_attack, badge_egg, ui_awaken (gem_orange / s17c), fx_leaf (cắt từ `IT/f13a`). Thêm 3 pact (Twin Fates, Iron Vow, Tithe of Pips). Thêm 5 món đã là bản kho từ trước (family pos/mana/rule, shard, shards), ngoài phạm vi |
| Làm bằng code, KHÔNG gửi Claude Design | **4** fx: rays, pulse, sparkle, bubble (gradient) |
| Vẽ bám kho (Claude Design) | **23** món ui6: frame_core x3, frame_run_rule, crest x3, artwin x3, back_art x3, slot x4, family stat/dice/quest/run_rule (4), badge tradeoff/convert (2). Cộng **6 pact** (Blood Pact, Lone Wolf, Brittle Dice, Patient Fang, Devil's Reroll, Hollow Chalice) |
| Bỏ (khuyến nghị) | badge_nonattack, badge_front, minh hoạ Luật run |
| Hướng mới | hiệu ứng Lõi kích hoạt: làm bằng code + `godot/assets/vfx`, không vẽ mới |

---

## Gói B. Icon SVG do agent tự vẽ

Ảnh: `production/art-redo-0311-sheet-B.png` (SVG render qua qlmanage, nền trắng của SVG bị làm xám trong sheet).

Phạm vi theo Liam: 6 house + ~16 SVG khác. Đếm lại thực tế:
- 6 `house_*.svg` trong `godot/assets/ui3/icons/` (commit 10b7ae6, agent tự vẽ).
- 6 SVG trong `godot/assets/icons/web/` (blank, buff, debuff, mana, reroll, settings; commit 0eed4b6 ghi rõ "hand-authored").
- 10 SVG trong `godot/assets/ui3/icons/` (ui_check, ui_lock, ui_menu, ui_reroll, ui_settings, ui_undo, face_blank, face_buff, face_debuff, face_mana).
- 6 + 10 = **16**, đúng như Liam nói. Nhưng 6 cái web TRÙNG nghĩa 6 cái ui3 (blank = face_blank, buff = face_buff, debuff = face_debuff, mana = face_mana, reroll = ui_reroll, settings = ui_settings). Vẽ lại **10 hình duy nhất**, xuất ra 16 chỗ. Cần Liam xác nhận (câu hỏi 3).
- Phát hiện mới: 8 trong 16 file này (face_blank/buff/debuff/mana, ui_lock/reroll/settings/undo) có manifest c2pa nhúng trong SVG. Nghĩa là chúng được tạo qua một công cụ AI có gắn dấu nguồn, không phải agent gõ tay. Càng nên làm lại. `ui_check`, `ui_menu` không có dấu. Không ảnh hưởng quyết định, ghi để Liam biết.

### B1. 6 house emblem

Huy hiệu nhà Anchor, dùng ở AnchorCard/Tile/Chip, Codex, Result, CombatView, DiceDock, Land. File game `godot/assets/ui3/icons/house_*.svg`, hiện 128x128, SVG. Kho không có ký hiệu nhà nên cả 6 đều là "vẽ bám kho".

Bám chung: dáng huy hiệu-cờ từ `IT/s21a/b/c.png` (vải, viền mảnh tối, hoa văn tròn / hoa tuyết), và chất liệu khiên-vàng từ `IT/makerdao1/3.png`. Ý Liam trước đó: có khiên màu thay cho đen-trắng mảnh (audit UI-06).

| món (file game) | dùng ở đâu | kho có dùng luôn? | nếu vẽ: món kho để bám | kích thước cần | ghi chú |
|---|---|---|---|---|---|
| `house_volley.svg` | Anchor Volley | **phương án vật thật, chờ Liam chọn**: `IT/s2a.png` (gốc cây có bia + mũi tên) | nếu Liam muốn cách điệu: `IT/s21c.png` (dáng huy hiệu cờ) | SVG 128x128 (xuất PNG 256 để test) | Hình: mũi tên / bia. Nghĩa nhà: bắn liên tục |
| `house_gambler.svg` | Anchor Gambler | không (cần vẽ trong cả hai phương án) | chỉ bám màu / chất liệu hộp: `IT/a10a.png` (KHÔNG vẽ lại chú hề), chấm kem như xúc xắc game | như trên | Xúc xắc / hộp bất ngờ |
| `house_mana_mine.svg` | Anchor Mana Mine | **phương án vật thật, chờ Liam chọn**: `IC/ore_blue_raw.png` | nếu cách điệu: `IT/s17a.png` (tinh thể xanh) | như trên | Quặng xanh lam |
| `house_kin.svg` | Anchor Kin | **phương án vật thật, chờ Liam chọn**: `IT/a7a.png` (chỉ dáng tròn lồng nhau, không mặt) | nếu cách điệu: dáng khối tròn của `IT/a7a/c.png`, không vẽ mặt | như trên | Nhóm / họ hàng. Chỉ bám dáng khối tròn, không vẽ mặt Axie |
| `house_embers.svg` | Anchor Embers | **phương án vật thật, chờ Liam chọn**: `IC/coal_pile.png` (hoặc `IT/s17c.png`) | nếu cách điệu: `IC/charcoal_log.png`, `IT/s17c.png` | như trên | Than hồng / lửa |
| `house_big_hand.svg` | Anchor Big Hand | **phương án vật thật, chờ Liam chọn**: `IT/s2c.png` (rìu cắm gốc) | nếu cách điệu: `IT/s2c.png` (dáng rìu); kho không có bàn tay | như trên | Cú đánh to. Hình bàn tay cần vẽ bám dáng khối, kho không có tay |

### B2. 10 icon SVG khác (hình duy nhất)

Kho không có glyph UI, nên cột bám chỉ cho CHẤT LIỆU / BẢNG MÀU / ĐỘ DÀY NÉT, không cho hình. Gợi ý: nét viền tối mảnh cùng tông (đừng viền đen dày kiểu sticker như `icons/hl`), tô khối nhẹ.

| món (file game) | dùng ở đâu | kho có dùng luôn? | nếu vẽ: món kho để bám | kích thước cần | ghi chú |
|---|---|---|---|---|---|
| `ui3/ui_check.svg` | HUD, xác nhận | không | `IC/gem_green.png` (màu xanh lục) | SVG 128 (hiện 128, dùng ~24-48 trên màn) | Dấu tick |
| `ui3/ui_lock.svg` | khoá Lõi / ô | không | `IC/stone_block.png`, `IT/s19a.png` (ổ khoá rương: hình ổ khoá thật có sẵn trên rương) | SVG 128 | Bám ổ khoá của rương `s19a/b/c` |
| `ui3/ui_menu.svg` | nút menu | không | `IT/a18a.png` (khúc gỗ, 3 thanh) | SVG 128 | 3 gạch / 3 khúc |
| `ui3/ui_reroll.svg` + `icons/web/reroll.svg` | nút Reroll | không | `IT/s4a/b/c.png` (chong chóng quay, đúng ý "xoay") | SVG 128 | Mũi tên vòng hoặc chong chóng |
| `ui3/ui_settings.svg` + `icons/web/settings.svg` | nút Settings | không | `IT/s16a.png` / `IT/a1b.png` (rìu: dụng cụ) | SVG 128 | Bánh răng |
| `ui3/ui_undo.svg` | nút Undo | không | chỉ lấy nét viền / bảng màu của bộ glyph (kho không có mũi tên quay lại) | SVG 128 | Mũi tên quay lại |
| `ui3/face_blank.svg` + `icons/web/blank.svg` | mặt xúc xắc trống | **dùng luôn**: `IC/stone_block.png` | (không cần) | SVG 128 | Mặt không hiệu ứng |
| `ui3/face_buff.svg` + `icons/web/buff.svg` | mặt buff | **dùng luôn**: `IC/gem_green.png` (trùng shard Moss, Liam quyết có chấp nhận không) | nếu không chấp nhận trùng: vẽ bám `IC/gem_green.png` | SVG 128 | Mặt tăng. **Cũng là stand-in tạm cho ui_awaken cũ**, đã tách ra ở gói A |
| `ui3/face_debuff.svg` + `icons/web/debuff.svg` | mặt debuff | **dùng luôn**: `IC/gem_red.png` | (không cần) | SVG 128 | Mặt giảm |
| `ui3/face_mana.svg` + `icons/web/mana.svg` | mặt mana | **dùng luôn**: `IT/s16b.png` (bình lam; trùng family_mana, vẫn cùng nghĩa) | (không cần) | SVG 128 | Ghi chú: gói A có `family_mana` là bình lam, nên hai cái này cùng tông |

Không thuộc phạm vi B nhưng cùng loại (Liam cần quyết, câu hỏi 4): `icons/hl/*` (24 file, Claude Design, viền đen dày, commit 71d3fea) và `ui3/icons/cur_*` (16 file, UI-03). Bảng nguồn gốc xếp chúng vào "AI" nhưng quyết định 3/11 không nhắc tên.

### Tổng gói B

| | số món |
|---|---|
| Dùng kho luôn | **4 glyph** (face_blank, face_buff, face_debuff, face_mana) + **5 house nếu Liam chọn "vật thật"** (Volley, Mana Mine, Kin, Embers, Big Hand) |
| Vẽ bám kho | **6 glyph** (ui_check, ui_lock, ui_menu, ui_reroll, ui_settings, ui_undo) + **1 house** (Gambler). Nếu Liam chọn cách điệu: 6 house đều vẽ |

---

## Gói C---

## Gói C. Cosmetics 3D

Ảnh: `production/art-redo-0311-sheet-C.png` (chỉ 10 hàng mẫu: mỗi hàng 1 nhóm bậc, trái = ảnh đang dùng, phải = vật kho để bám).

Tất cả nằm dưới `godot/assets/cosmetics/`. Đây là mảng lớn nhất; kho không có bản thay trực tiếp, chỉ có VẬT LIỆU / MÀU / HOA VĂN để tham khảo. Quy tắc bám: ảnh tham chiếu là vật thật sơn kiểu Homeland, texture phải trông như "bề mặt của vật đó" (gỗ ra gỗ, vàng ra vàng).

### C1. 26 skin xúc xắc (`cosmetics/dice/<id>/`)

Mỗi skin là 1 thư mục. File thường có: `albedo.png` 512x512 (tileable), `normal.png` 512x512, `plate.png` + `plate_normal.png` 256x256 (tấm mặt), `tile_trim_56.png`, `tile_trim_88.png`, `egg_trim_36.png`; một số skin có thêm emission + sparkle. 222 file / 26 skin ≈ 8-9 file mỗi skin. Dùng ở mặt xúc xắc 3D, tile, Echo Box. Không nine-patch. Không skin nào dùng kho luôn được.

| bộ (độ hiếm) | skin | số | món kho để bám | cách bám | ghi chú |
|---|---|---|---|---|---|
| c (common) | `die_c_clay`, `die_c_reed`, `die_c_sunwood` | 3 | `IT/a18a/b.png` (gỗ khúc), `IT/s15a/b.png` (gỗ, dây thừng), `IC/wood_plank.png`, `IC/wool_bundle.png` (sợi: reed) | chất liệu gỗ / đất sét, vân gỗ thật | Hiện là texture phẳng nâu cam / đan sậy / gỗ nhạt |
| u (uncommon) | `die_u_bark`, `die_u_berry`, `die_u_moss` | 3 | `IT/f11a.png` (gốc cây vân tròn), `IT/f12a.png` (thảm rêu xanh), `IT/f5a.png` (dây leo nho), `IC/strawberry.png` | màu + vân tự nhiên | |
| r (rare, 6 class) | `die_r_aqua`, `_beast`, `_bird`, `_bug`, `_plant`, `_reptile` | 6 | aqua: `IT/a14a.png` / `IT/a16a.png` (xanh biển); beast: `IT/s12a.png` (mặt nạ cam); bird: `IC/gem_pink.png`; bug: `IT/f17a.png`; plant: `IT/f13a.png`; reptile: `IT/s12c.png` (mặt nạ lục) | bảng màu class + vân đại diện (vảy, lông, gạch) | Bám 6 màu class của game; kho không có vảy / lông, chỉ cho màu |
| e (epic) | `die_e_reef_01`..`06` (6), `die_e_rune`, `die_e_s1_founder`, `die_e_spore` | 9 | reef: `IT/a14a.png`, `IT/a15a/b/c.png` (tinh thể băng xanh), `IT/s17a.png`; rune: `IT/f14c.png`, `IT/f9a.png`; spore: `IT/f17a/b/c.png` (nấm); s1_founder: `IT/makerdao3.png` | tinh thể sáng, rune khắc | 6 reef cần 6 biến thể: dùng cả bộ `a14` / `a15` / `a16` |
| m (mythic) | `die_m_moon`, `die_m_redcrystal` | 2 | moon: `IT/a20a.png`, `IT/makerdao2.png` (xanh đêm); redcrystal: `IC/gem_red.png`, `IC/ore_red_raw.png`, `IT/s17b.png` | màu đỏ ruby, mặt cắt tinh thể | |
| l (legendary) | `die_l_gold`, `die_l_kingdom`, `die_l_relic_stone` | 3 | gold: `IC/ingot_gold.png`, `IC/ore_gold.png`; kingdom: `IT/s19b.png` (lục-vàng) + `IT/a20c.png`; relic_stone: `IT/f14c.png`, `IC/stone_block.png` | kim loại vàng thật, đá khắc | |

### C2. 49 file khung avatar = 27 khung (`cosmetics/frames/`)

Mỗi khung là 1 `frame_<id>_base.png` 256x256 (vòng tròn, giữa trong suốt) + 0 đến 2 layer hiệu ứng (`glow`, `drift`, `runes`, `embers`, `stars`, `glints`, `fireflies`, `flicker`, `corona`, `shadow`, `core`, `glint`, `rays`) cùng 256x256, chồng lên trong game. 27 base + 22 layer = 49 file. Không nine-patch.

Bám chung: kho chỉ có DUY NHẤT 1 loại vòng tròn: `DL/art-2d/rewards/christmas_2024_homeland_avatar_*.png` (viền tối mảnh, vòng tròn, hoa văn trang trí). Dùng nó làm mẫu NÉT VIỀN và độ dày. Các chất liệu khác lấy từ vật thật dưới đây. Hiện tại khung đang viền đen dày kiểu sticker, lệch kho.

| bộ | khung (base) | số base / số layer | món kho để bám | ghi chú |
|---|---|---|---|---|
| c (6 class) | `c_aqua`, `c_beast`, `c_bird`, `c_bug`, `c_plant`, `c_reptile` | 6 / 0 | `art-2d/rewards/christmas_2024_homeland_avatar_1..4_10.png` (vòng tròn + màu nền), `IT/a14a/s12a/f17a/f13a/s12c` cho màu từng class | 6 vòng cùng khuôn, khác màu + chi tiết đặc trưng class |
| u (4) | `u_campfire`, `u_mushroom`, `u_pond`, `u_vine` | 4 / 0 | `IC/coal_pile.png` + `IC/charcoal_log.png`; `IT/f17a.png`; `IT/s9a.png` (hồ đá); `IT/f15a.png`, `IT/f5a.png` (dây leo) | |
| r (4) | `r_aurora`, `r_frost`, `r_icicle`, `r_snowglobe` | 4 / 0 | `IT/a14a/b/c.png` (khối băng), `IT/a16a.png` (quả cầu), `IT/a4c.png` (cây tuyết) | |
| e (9) | `e_firefly`, `e_reef_01..06`, `e_runering`, `e_s1_founder` | 9 / 15 (firefly 2, reef 10, runering 2, s1_founder 1) | `IT/a15a/b/c.png`, `IT/s17a.png` (reef); `IT/f14c.png`, `IT/f9a.png` (rune); `IT/makerdao3.png` | Có nhiều layer động nhất |
| m (2) | `m_crystal`, `m_eclipse` | 2 / 4 | `IT/s17b.png`, `IC/gem_red.png`; `IT/a20a.png` | |
| l (2) | `l_sovereign`, `l_sunburst` | 2 / 3 | `IC/ingot_gold.png`, `IT/makerdao3.png`, `IT/a20c.png`, `IT/s19b.png` | |

(Số layer đếm theo ls: e = 24 file tổng gồm 9 base, 15 layer; m = 6 gồm 2 base, 4 layer; l = 5 gồm 2 base, 3 layer. Cộng 22 layer, khớp.)

### Tổng gói C

| | số món |
|---|---|
| Dùng kho luôn | **0** |
| Vẽ bám kho | **26 skin xúc xắc** (khoảng 222 file) + **27 khung avatar** (49 file, trong đó 22 là layer hiệu ứng) |

---

## Tổng cộng

| gói | dùng kho luôn | code | vẽ bám kho (Claude Design) |
|---|---|---|---|
| A. Thẻ Lõi (gồm 9 pact) | 7 (4 ui6 + 3 pact) | 4 fx | 29 (23 ui6 + 6 pact) |
| B. Icon SVG | 4 glyph (+5 house nếu "vật thật") | 0 | 7 (6 glyph + Gambler); 12 nếu house cách điệu |
| C. Cosmetics | 0 | 0 | 53 (26 skin + 27 khung; 271 file) |
| **Cộng** | **11 (16 nếu house vật thật)** | **4** | **89 (nếu house vật thật) hoặc 94 (house cách điệu)** |

(Gói B cách điệu: 6 glyph + 6 house = 12, trong đó Gambler vẽ trong cả hai phương án. Cộng 29 + 12 + 53 = 94.)
Nếu Liam không chấp nhận face_buff trùng shard Moss thì thêm 1 món vẽ.
Ngoài phạm vi nhưng liên quan: xoá 95 file ui6 chết (đã chốt).

## Chia lượt gửi Claude Design (art-director)

- **Lượt 1 (23 món)**: frame_core x3, frame_run_rule, crest x3, artwin x3, back_art x3, slot x4, family stat/dice/quest/run_rule, badge tradeoff/convert.
- **Lượt 2 (~19-20 món)**: 6 pact còn lại + house (1 Gambler, hoặc 6 nếu cách điệu) + 6 glyph UI (+ face_buff nếu không dùng gem_green).
- **Lượt 3-4**: cosmetics (skin xúc xắc, rồi khung).

## Câu hỏi còn mở cho Liam (kèm khuyến nghị của art-director)

0. **Huy hiệu nhà (MỚI)**: vật thật từ kho (5/6 dùng luôn, chỉ Gambler vẽ) hay vẽ cách điệu cả 6?
1. Hiệu ứng Lõi kích hoạt. Khuyến nghị: bỏ đường nối, thẻ sáng lên + hạt bay tới Axie, dùng `godot/assets/vfx/*`, làm bằng code.
2. Icon 9 Boss Pact: chỉ 128. Hình từng cái do art-director chốt (gợi ý trong bảng chỉ là đoán).
3. 6 SVG `icons/web` trùng 6 SVG `ui3`. Khuyến nghị: gộp thành 10 hình, làm lại 6 SVG web.
4. `icons/hl/*` (24) + `ui3/icons/cur_*` (16). Khuyến nghị: vào gói D, làm sau.
5. badge_nonattack, badge_front. Khuyến nghị: bỏ.
6. Minh hoạ Luật run. Khuyến nghị: không làm.
7. Kích thước cosmetics. Khuyến nghị: vẽ 1024 tileable rồi hạ cỡ.
8. Layer động của khung. Khuyến nghị: chỉ vẽ base, giữ layer cũ.
9. face_buff = `IC/gem_green` trùng shard Moss: chấp nhận không?
10. Đã chốt GIỮ, không đụng: chân dung, `icons/web` png, logo, bg_login, cards.

## Hạn chế

- Gợi ý hình của pact, house, glyph là của tôi, chưa qua art-director.
- Số layer frame đếm bằng `ls`, chưa kiểm game có dùng hết không.
- SVG trong sheet B render bằng qlmanage nên nền hơi khác trong game.
- "Bám" chưa thử trong game. Sheet A/B còn một số ô cũ (ví dụ a10a, m13, spiky_ball, a20 coi như tượng): theo bảng chữ trong file này, không theo sheet.
- Chưa có PNG 2D của mặt xúc xắc (chỉ có `dice/axie_die.glb`), phải chụp từ game.

## Liam quyết (3/11, sau khi xem bảng)
- Huy hiệu nhà: **vật thật từ kho**. Volley gốc cây có bia, Mana Mine quặng xanh, Embers đống than, Big Hand rìu cắm gốc, Kin dáng tròn. Chỉ Gambler phải vẽ.
- Hiệu ứng Lõi kích hoạt: **bỏ đường nối**. Ô Lõi sáng lên, vài hạt bay cong tới Axie, nổ bằng VFX kỹ năng chính thức trong `godot/assets/vfx`. Làm bằng code (làn P1), không qua Claude Design.
- `icons/hl` + `cur_*`: **gói D, làm sau gói A–C**.
- Duyệt hết phần còn lại theo khuyến nghị:
  - pact chỉ vẽ cỡ 128;
  - gộp SVG thành 10 hình;
  - bỏ badge nonattack và front;
  - không vẽ minh hoạ Luật run;
  - cosmetics vẽ 1024 tileable rồi hạ cỡ, chỉ vẽ base, giữ layer cũ;
  - face_buff dùng ngọc xanh, chấp nhận trùng với shard Moss.
