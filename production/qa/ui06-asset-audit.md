# Rà asset UI-06 / UI-07 so với kho có sẵn (bản sửa sau soát của art-director, 2/11)

Chỉ đọc, không sửa code game, không commit. Người làm: technical-artist.

## Cách đọc

Cột **Nguồn** và **Mức**:
- **Kho (đúng)** / **Kho (gần)**: có trong `asset-library/design-library/` (icons/, art-2d/items/). Gần = cùng ý nhưng khác hình / công dụng, có ghi khác gì.
- **Bản cũ của game**: ảnh có trong game trước UI-06 (git `587c749^`, hoặc `godot/assets/icons/web|hl`, `ui3/icons`). Ghi (đúng) hoặc (gần) cho biết khớp nghĩa tới đâu.
- **Không có**: không thấy trong kho lẫn bản cũ.

**Nguồn gốc của `icons/web/*`, `icons/hl/*` và `cards/*` cũ CHƯA kiểm.** Tôi không khẳng định chúng thuộc bộ icon / art Axie chính thức. Chỉ biết đó là ảnh game đã dùng trước UI-06.

**Cảnh báo phong cách:** `icons/web/*` và `icons/hl/*` viền đen dày kiểu sticker, lệch với phong cách sơn Homeland của bộ UI-06 mới và của `design-library`. Ghép lẫn trong cùng một thẻ sẽ chói. Muốn đồng bộ thì ưu tiên `design-library/art-2d/items` và `icons/`, hoặc thay cả cụm.

## Ảnh so sánh (đều dưới 1 MB, cạnh file này)
1. `ui06-audit-sheet1-map-nodes.png`: ô map cũ / mới / icons/web
2. `ui06-audit-sheet2-houses.png`: 6 house emblem, SVG cũ / mới
3. `ui06-audit-sheet3-family-badge-shard.png`: family, badge, shard và icon cũ gần nhất
4. `ui06-audit-sheet4-reward-illustrations.png`: minh hoạ + relic, cũ / mới
5. `ui06-audit-sheet5-frames-fx-ui7.png`: khung, crest, fx, UI-07 (không có bản thay)
6. `ui06-audit-sheet6-candidates.png`: hiện tại vs ứng viên kho mới tìm (cờ, bình, đá khắc, gem, rương, thuốc)

Bản cũ đã lưu ở `/private/tmp/claude-501/-Users-loc-tien-nguyen-my-game/618d3da5-1a0e-40e2-8929-42747913790c/scratchpad/audit/old/`. Lấy lại: `git show 587c749^:<đường dẫn> > file`. Ký hiệu "@cũ" dưới đây = `git show 587c749^:godot/assets/cards/<tên>.png`.

`bg_login` không tính vào phép đếm (nền đang dùng, chưa rà nguồn, xem mục 11).

## 1. Emblem họ Core (7)

| asset game đang dùng | dùng ở đâu | bản có sẵn tốt nhất | Nguồn | Mức | ghi chú |
|---|---|---|---|---|---|
| family_stat (tim) | CoreCard, CoreTooltip, CorePanel, CoreStrip | `godot/assets/icons/hl/aid.png` | game cũ (hl) | Bản cũ (gần) | Tim + dấu cộng kiểu "hồi máu", viền dày, tím. Kho không có tim. |
| family_dice (xúc xắc) | như trên | không có | không | Không có | `ui3 face_*` là mặt dice theo hiệu ứng, không phải khối xúc xắc. |
| family_pos (cờ) | như trên | `art-2d/items/s21a.png`, `s21b`, `s21c` (cờ nhỏ trên cột sừng) | kho | Kho (gần) | Phong cách sơn Homeland, có cột, hơi dài / mảnh; cắt vuông. Dự phòng: `renders/equipment/SM_Flag_Lvl1_Rig.png`. |
| family_mana (bình) | như trên | `art-2d/items/s16b.png` (bình lam) | kho | Kho (gần) | Bình thon có nút vải, màu lam (không phải ngọc lam tròn). Cũng có `s16c` (hồng), `icons/oil_bottle.png`. |
| family_quest (cuộn) | như trên | `godot/assets/icons/hl/pact.svg` | game cũ (hl) | Bản cũ (gần) | Cuộn / băng rôn tím có ruy băng, thật ra là icon "pact". Kho chưa thấy cuộn giấy (chưa quét hết `art-2d/items`). |
| family_rule (đá khắc) | như trên | `art-2d/items/f14c.png` (đá có rune xoắn) | kho | Kho (gần) | Rất sát: đá phủ rêu có khắc xoắn. Khác: đá dựng nghiêng, có rêu xanh. |
| family_run_rule (đồng hồ cát) | RunRuleSlot, RuleCard | `godot/assets/icons/hl/attrition.png` | game cũ (hl) | Bản cũ (gần) | Cùng hình, viền đen dày, không có khung gỗ. |

## 2. Badge tag (6)

| asset game đang dùng | dùng ở đâu | bản có sẵn tốt nhất | Nguồn | Mức | ghi chú |
|---|---|---|---|---|---|
| badge_attack (kiếm) | CoreCard badge row | `design-library/icons/wooden_sword.png` (dự phòng cũ: `icons/web/dmg.png`) | kho | Kho (gần) | Kiếm gỗ sơn Homeland, đứng dọc. |
| badge_nonattack (khiên) | tooltip / frame cũ, README bảo ẩn | `icons/web/shield.png` | game cũ (web) | Bản cũ (gần) | Khiên xanh có mũi tên lên = "thêm khiên". Có thể bỏ vì badge này ẩn. |
| badge_tradeoff (cân) | CoreCard | `icons/hl/drawback.svg` | game cũ (hl) | Bản cũ (gần) | Mũi tên xuống hồng = "bất lợi". |
| badge_convert_to_dmg (tia chớp) | CoreCard | không có | không | Không có | |
| badge_front (chevron) | CoreCard | không có | không | Không có | Chevron cũng đã ở family_pos nên có thể bỏ badge này. |
| badge_egg (trứng) | CoreCard | `design-library/icons/egg.png` | kho | Kho (đúng) | |

## 3. House emblem (6)

| asset game đang dùng | dùng ở đâu | bản có sẵn tốt nhất | Nguồn | Mức | ghi chú |
|---|---|---|---|---|---|
| house_volley / gambler / mana_mine / kin / embers / big_hand | AnchorCard, AnchorTile/Chip, Codex, Result, CombatView, DiceDock, Land | `godot/assets/ui3/icons/house_*.svg` (còn trong repo, commit 10b7ae6) | game cũ (ui3) | Bản cũ (gần), cả 6 | Kho không có ký hiệu nhà. SVG cũ cùng nghĩa nhưng đen-trắng mảnh, không có khiên màu. Có thể dùng lại, hoặc nhờ Claude Design tô màu trên chính hình cũ. |

## 4. Shard / tier (3 bậc)

| asset game đang dùng | dùng ở đâu | bản có sẵn tốt nhất | Nguồn | Mức | ghi chú |
|---|---|---|---|---|---|
| shard_moss (lá) | TierShards, CoreSlot, shop Core card | `design-library/icons/gem_green.png` (hoặc `art-2d/items/s17a.png`, tinh thể lục lam) | kho | Kho (gần) | Đá quý lục thay cho lá; mất ý "rêu / sinh trưởng". |
| shard_amber (giọt) | như trên | `icons/gem_orange.png` (hoặc `art-2d/items/s17c.png`, tinh thể vàng) | kho | Kho (gần) | Đá quý cam thay cho giọt. |
| shard_crystal (tinh thể xanh) | như trên | `icons/diamond.png` | kho | Kho (gần) | Kim cương xanh, khác dáng lăng trụ. Đừng dùng `icons/web/shard.png` (Gene Shard, gây nhầm tiền tệ). |

Bộ gem_green / gem_orange / diamond cùng phong cách, cùng hình dáng (bát giác / kim cương), đọc được 3 bậc bằng màu. Xem sheet 6. `shards_*` (hàng 3 viên) ghép từ shard_*, cùng nhóm.

## 5. Slot / socket

| asset game đang dùng | dùng ở đâu | bản có sẵn tốt nhất | Nguồn | Mức | ghi chú |
|---|---|---|---|---|---|
| slot_moss / amber / crystal / empty | CoreSlot (Cores strip, DiceDock, EnemyColumn, Tutorial), ô bán shop | không có | không | Không có | Ổ cắm viền theo bậc. Đã quét 3 sheet art-2d/items: không có. |

## 6. Khung thẻ / crest / artwin / back_art / frame_run_rule

| asset game đang dùng | dùng ở đâu | bản có sẵn tốt nhất | Nguồn | Mức | ghi chú |
|---|---|---|---|---|---|
| frame_core_moss / amber / crystal (NinePatch) | CoreCard | không có | không | Không có | Kho chỉ có khung phần thưởng Giáng sinh (`art-2d/rewards`), không phải thẻ. |
| crest_moss / amber / crystal | TierCrest | không có | không | Không có | |
| artwin_moss / amber / crystal | ArtWindow | không có | không | Không có | |
| back_art_moss / amber / crystal | CoreCardBack | không có | không | Không có | |
| frame_run_rule | RuleCard | không có | không | Không có | |

13 file. Giữ bản Claude Design (đúng như Liam nói).

## 7. Icon ô map (6)

Cảnh báo: bản cũ viền đen dày (xem sheet 1), lệch hẳn phong cách sơn Homeland của UI-06. Kho design-library không có icon ô map. Dùng lại bản cũ thì giữ 100% nhưng nhìn "khác bộ" với thẻ mới.

| asset game đang dùng | dùng ở đâu | bản có sẵn tốt nhất | Nguồn | Mức | ghi chú |
|---|---|---|---|---|---|
| node_battle | RunMap, Land, Settings, Tutorial, LandEditParts | `godot/assets/icons/web/battle.png` (= `ui3/icons/node_battle.png` cũ, md5 trùng) | game cũ (web) | Bản cũ (đúng) | Thú xám mắt đỏ. |
| node_elite | như trên | `icons/web/elite.png` | game cũ (web) | Bản cũ (đúng) | Vầng trăng đỏ. |
| node_boss | như trên | `icons/web/boss.png` | game cũ (web) | Bản cũ (đúng) | Mặt nạ đỏ. |
| node_shop | như trên | `icons/web/shop.png` | game cũ (web) | Bản cũ (đúng) | Bao gốm chấm xanh. |
| node_event | như trên | `icons/web/event.png` | game cũ (web) | Bản cũ (đúng) | Thẻ vàng + dấu hỏi. |
| node_treasure | như trên | `icons/web/chest.png` | game cũ (web) | Bản cũ (đúng) | Lục giác gỗ mặt cười. (Muốn cùng style Homeland: `art-2d/items/s19a` rương, xem mục 8.) |

## 8. Minh hoạ thưởng / shop / event / treasure (11)

| asset game đang dùng | dùng ở đâu | bản có sẵn tốt nhất | Nguồn | Mức | ghi chú |
|---|---|---|---|---|---|
| ill_card_level | reward level | `art-2d/items/s21a/b/c` (cờ) hoặc @cũ `card_level.png` | kho / game cũ | Kho (gần) | Cờ trên cột, thay cho "người giương cờ". Bản cũ là tranh sinh vật xanh, xem mục 12. |
| ill_card_ascend | reward ascend (chưa có data, chỉ bảng mẫu) | @cũ `card_ascend.png` | game cũ (cards) | Bản cũ (đúng) | Cầu vồng + ốc. |
| ill_card_hp | reward hp | @cũ `card_hp.png` | game cũ (cards) | Bản cũ (đúng) | Dâu + bánh quy. Kho có `icons/strawberry`, `peach` nếu cần icon. |
| ill_card_reroll | reward reroll | @cũ `card_reroll.png` | game cũ (cards) | Bản cũ (đúng) | Hộp "?" xanh. |
| ill_card_chaos | reward chaos | @cũ `card_chaos.png` | game cũ (cards) | Bản cũ (đúng) | Hộp "?" tím. |
| ill_card_curse | reward curse | @cũ `card_curse.png` | game cũ (cards) | Bản cũ (đúng) | Xem mục 12. |
| ill_card_relic | reward relic | @cũ `card_relic.png` | game cũ (cards) | Bản cũ (đúng) | Khiên gỗ. Byte-giống relic_r0 cũ. |
| ill_shop_heal | shop Serum | `art-2d/items/s16c.png` (bình thuốc hồng) hoặc `s16b` | kho | Kho (gần) | Bình thuốc sơn Homeland. Bản cũ (ốc xanh) `shop_heal.png` là lựa chọn thứ hai. |
| ill_shop_relic | shop Core Pick | @cũ `shop_relic.png` | game cũ (cards) | Bản cũ (đúng) | Đồng xu vàng; lệch nghĩa nhẹ vì nay là Core. Byte-giống relic_r2 cũ. |
| ill_node_event | overlay event (720) | @cũ `node_event.png` | game cũ (cards) | Bản cũ (đúng) | Xem mục 12. Kho: `art-2d/items/f14c` (đá khắc) nếu muốn bỏ sinh vật. |
| ill_node_treasure | overlay treasure (384) | `art-2d/items/s19a.png`, `s19b`, `s19c` (rương 3 bậc: nâu / lục-vàng / tím) | kho | Kho (gần) | Rương sơn Homeland; 3 bậc dùng được cho 3 tier. Bản cũ @cũ `node_treasure.png` có sinh vật, xem mục 12. |

Quay lại bản cũ: tranh cũ nền đầy, bản mới tranh tròn nền trong, phần mask / khung của UI-06 có thể phải chỉnh.

## 9. relic_r0–r4 (5)

| asset game đang dùng | dùng ở đâu | bản có sẵn tốt nhất | Nguồn | Mức | ghi chú |
|---|---|---|---|---|---|
| relic_r0 … relic_r4 | shop item theo độ hiếm (RunMapController, RunMapHud, RunMapOffers, ShopCoreCard) | @cũ `relic_r0..r4.png` | game cũ (cards) | Bản cũ (đúng) | Thuộc hệ rarity relic cũ (Common..Legendary), chưa chắc khớp với bậc Core mới (Moss / Amber / Crystal). |

Phương án từ kho nếu muốn bậc theo vật liệu: `stone_block`, `ingot_bronze`, `ingot_silver`, `ingot_gold`, `diamond`, hoặc bộ 3 bình `art-2d/items/s16a/b/c`. Chưa chọn, để Liam quyết.

## 10. fx (5) và ui_awaken

| asset game đang dùng | dùng ở đâu | bản có sẵn tốt nhất | Nguồn | Mức | ghi chú |
|---|---|---|---|---|---|
| fx_rays_crystal, fx_sparkle, fx_bubble, fx_leaf, fx_pulse | CoreFireFX, reveal | không có | không | Không có | Texture hạt chung. `godot/assets/vfx/` chỉ có VFX kỹ năng. |
| ui_awaken (sao vàng) | AnchorTile / AnchorChip, AnchorFx | `godot/assets/ui3/icons/face_buff.svg` | game cũ (ui3) | Bản cũ (gần) | Là stand-in cũ (mặt buff), không phải dấu thức tỉnh. |

## 11. UI-07 (Login)

| asset game đang dùng | dùng ở đâu | bản có sẵn tốt nhất | Nguồn | Mức | ghi chú |
|---|---|---|---|---|---|
| bg_login_1280 / 1920 | LoginScreen nền | chưa rà | chưa rõ | (không đếm) | Nền đồng cỏ Homeland. Chưa truy được nguồn, không tính vào thống kê. |
| logo_axiedice | LoginScreen | không có | không | Không có | Logo của game mình. |
| google_g (SVG) | nút Google | không có | không | Không có | Logo Google chính thức, giữ. |

## 12. Tranh có sinh vật kiểu Axie vs quy tắc "không dùng ảnh Axie"

`design-library/INDEX.md` ghi: "No Axie images. In the game an Axie is always a live 3D model." Các tranh cũ sau có sinh vật trông giống Axie / quái:
- `card_level.png` (@cũ): sinh vật xanh dạng bò sát trên đá.
- `node_event.png` (@cũ): sinh vật tím có sừng trên bãi biển.
- `node_treasure.png` (@cũ): tượng đá có mặt phủ cây.
- `card_curse.png` (@cũ): thẻ đỏ có hình khắc có vẻ nhân vật.

Tôi chưa xác minh chúng có phải Axie hay không, và nguồn gốc của `cards/*` cũ chưa kiểm. Liam quyết có tính vào quy tắc không. Nếu tính, 4 tranh này không dùng lại; thay bằng: level → `s21a/b/c` (cờ), treasure → `s19a/b/c` (rương), event → `f14c` (đá khắc), curse → chưa có thay trong kho (cần Claude Design hoặc dùng icon `hl/lethal` / `drawback`).

## Tóm tắt số lượng (69 asset, không tính bg_login)

Đếm theo asset logic, không tính bản 32/64/128 hay 320/640.

| nhóm | Kho (đúng) | Kho (gần) | Bản cũ của game | Không có | cộng |
|---|---|---|---|---|---|
| family 7 | 0 | 3 (pos, mana, rule) | 3 (stat, quest, run_rule) | 1 (dice) | 7 |
| badge 6 | 1 (egg) | 1 (attack) | 2 (nonattack, tradeoff) | 2 (convert, front) | 6 |
| house 6 | 0 | 0 | 6 | 0 | 6 |
| shard 3 | 0 | 3 | 0 | 0 | 3 |
| slot 4 | 0 | 0 | 0 | 4 | 4 |
| khung / crest / artwin / back_art / run_rule | 0 | 0 | 0 | 13 | 13 |
| ô map 6 | 0 | 0 | 6 | 0 | 6 |
| minh hoạ 11 | 0 | 3 (level, shop_heal, treasure) | 8 | 0 | 11 |
| relic_r0-4 | 0 | 0 | 5 | 0 | 5 |
| fx 5 | 0 | 0 | 0 | 5 | 5 |
| ui_awaken | 0 | 0 | 1 | 0 | 1 |
| UI-07 (logo, google_g) | 0 | 0 | 0 | 2 | 2 |
| **Tổng** | **1** | **10** | **31** | **27** | **69** |

Theo 3 mức Liam cần: **Kho có = 11** (1 đúng + 10 gần), **Bản cũ của game = 31**, **Không có = 27**.

## 5 thay thế đáng làm nhất

1. **Shard 3 bậc** → `gem_green` / `gem_orange` / `diamond` (cùng bộ sơn Homeland, đọc được bậc bằng màu).
2. **family_rule / family_mana / family_pos** → `f14c` (đá khắc), `s16b` (bình lam), `s21a/b/c` (cờ). Cùng bộ `art-2d/items`.
3. **ill_node_treasure** → `s19a/b/c` (rương 3 bậc); **ill_shop_heal** → `s16c` (bình thuốc); **ill_card_level** → `s21` (cờ). Cũng đỡ vướng quy tắc "không Axie".
4. **badge_egg** → `icons/egg.png` (đúng); **badge_attack** → `wooden_sword.png`.
5. **Icon ô map 6** và **house 6**: dùng lại bản cũ (`icons/web/*`, `ui3/icons/house_*.svg`) nhưng phải chấp nhận khác phong cách; nếu Liam muốn đồng bộ thì để Claude Design vẽ lại cho cùng bộ chứ đừng ghép lẫn.

## Cần Claude Design vẽ (27 file)

- Khung / crest / artwin / back_art / frame_run_rule (13): chất liệu thẻ theo bậc.
- slot_moss / amber / crystal / empty (4).
- fx particle (5): rays, sparkle, bubble, leaf, pulse.
- family_dice (1).
- badge_convert_to_dmg, badge_front (2) (front có thể bỏ).
- logo_axiedice, google_g (2).

Chưa tính: các mục Liam quyết có thay hay không (house 6, ô map 6, stat / quest / run_rule, relic_r0-4, ui_awaken, nonattack / tradeoff, 4 tranh có sinh vật). Nếu Liam muốn đồng bộ Homeland cho các mục này mà kho không đáp ứng thì cộng thêm vào danh sách vẽ.

## Chưa kiểm

- Nguồn gốc `icons/web/*`, `icons/hl/*`, `cards/*` cũ.
- Nguồn `bg_login`.
- Chỉ quét 3 sheet `art_2d_items_*` và `icons_*`; chưa quét `godot-ready/contact_sheets` (render 3D) và `renders/*`, `art-2d/environment|building-concepts`.
- Ứng viên Kho (gần) chưa thử trong game: khác kích cỡ / tỉ lệ / nền, cần cắt và test.

## Liam quyết (2/11)
- Emblem họ + shard bậc: **thay bằng đồ trong kho design-library** (sheet 6: cờ s21, bình s16b, đá khắc f14c, ngọc gem_green / gem_orange / diamond hoặc tinh thể s17, rương s19, bình s16c). Cái nào kho không có (family dice / stat / quest) thì giữ.
- Icon ô run map: **bộ cũ của game** (`godot/assets/icons/web/`).
- Tranh thẻ thưởng / shop / event / rương: **tranh cũ của game** (`git show 587c749^:godot/assets/cards/...`).
- House emblem 6 Anchor: **SVG cũ của game** (`godot/assets/ui3/icons/house_*.svg`).
