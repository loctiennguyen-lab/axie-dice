# Nguồn gốc art 2D trong game (kiểm kê 3/11)

Chỉ đọc, không sửa code game, không commit. Người làm: technical-artist. Bảng UI-06 chi tiết (ứng viên kho, so sánh ảnh) nằm ở `production/qa/ui06-asset-audit.md`, ở đây chỉ trỏ lại.

Nguồn: **(a)** kho Sky Mavis / Axie chính thức, **(b)** Claude Design (AI), **(c)** AI khác / sinh bằng script / agent tự vẽ-render, **(d)** vẽ tay / nguồn ngoài có ghi, **(e)** chưa rõ.

Cách kiểm: commit thêm file (`git log --diff-filter=A`), message commit, README trong `design/handoffs/*`, md5 so với `asset-library/` và `design/handoffs/`. Lưu ý quan trọng: md5 trùng với handoff chỉ cho biết file có nằm trong gói đã gửi cho / nhận từ Claude Design, chưa đủ để nói ai vẽ. Chiều đó phải xem commit + README. Dòng nào dựa vào suy luận thì ghi "(suy luận)".

Quyết định mới của Liam (3/11): cái gì kho không có thì Claude Design vẽ lại nhưng phải **bám kho** (tô / ghép từ asset chính thức). Khung thẻ bậc, crest, socket, fx của UI-06 tính là AI và làm lại. Cột "món kho để bám" ghi ứng viên gần nhất. Đường dẫn kho viết tắt `DL/` = `asset-library/design-library/`.

## A. Nhóm AI / chưa chắc (cần làm lại hoặc xác nhận)

| file / bộ | số file | dùng ở đâu | nguồn | bằng chứng | kho có bản thay? | món kho để bám | ghi chú |
|---|---|---|---|---|---|---|---|
| `ui6/family_stat, family_dice, family_quest, family_run_rule` (x3 cỡ 32/64/128) | 12 | CoreCard, Tooltip, CorePanel, CoreStrip, RunRuleSlot | (b) | commit 71cc401 "copy ui6 PNG kit"; md5 trùng `ui-06-run-cards/round-1` | Một phần, không có đúng hình | stat (tim): `DL/icons/strawberry.png`, `peach.png`; dice: `DL/icons/spiky_ball_*`/`egg.png` không sát, nên tô khối xúc xắc theo phong cách `art-2d/items/s16*`; quest (cuộn): chưa thấy, thử `art-2d/rewards`; run_rule (đồng hồ cát): chưa thấy | Audit UI-06 ghi dice/stat/quest/run_rule kho không có đúng |
| `ui6/badge_attack, nonattack, tradeoff, convert_to_dmg, front, egg` (x3) | 18 | CoreCard badge row | (b) | như trên | attack, egg có | attack: `DL/icons/wooden_sword.png`; egg: `DL/icons/egg.png`; tradeoff/nonattack/convert/front: bám `DL/icons/spiky_ball_red.png`, `stone_block.png` làm nền tô | front có thể bỏ (trùng family_pos) |
| `ui6/ui_awaken` (x3) | 3 | AnchorTile/Chip/Fx | (b) | như trên | không | `DL/icons/gem_orange.png` / `art-2d/items/s17c.png` (tinh thể vàng) | Sao vàng, đang là stand-in |
| `ui6/slot_moss/amber/crystal/empty` (x3) | 12 | CoreSlot, DiceDock, EnemyColumn, shop | (b) | như trên | không | khung ổ: `art-2d/items/f14c.png` (đá khắc), `DL/icons/stone_block.png`; màu bậc theo `gem_green / gem_orange / diamond` | Liam: làm lại |
| `ui6/frame_core_*` (3), `frame_run_rule` | 4 | CoreCard (NinePatch), RuleCard | (b) | như trên | không | `art-2d/rewards/*` (khung phần thưởng Giáng sinh, duy nhất có dạng khung); `DL/icons/ingot_bronze/silver/gold.png` cho màu bậc | Liam: làm lại |
| `ui6/crest_*`, `artwin_*`, `back_art_*` | 9 | TierCrest, ArtWindow, CoreCardBack | (b) | như trên | không | `art-2d/rewards/*`, `art-2d/items/s17a/c`, `gem_*` | Liam: làm lại |
| `ui6/fx_rays_crystal, fx_sparkle, fx_bubble, fx_leaf, fx_pulse` | 13 | CoreFireFX, reveal | (b) | như trên | không | hạt: cắt từ `DL/icons/gem_*`, `feather.png`, lá từ `art-2d/environment` | Texture hạt nhỏ, dễ vẽ lại |
| `ui6/house_*` (x6 x3) | 18 | **không còn dùng** (code trả `ui3/icons/house_*.svg`) | (b) | UI6Assets.house() | xem dưới | | Có thể xoá |
| `ui6/node_*` (x6 x3), `ill_*` (x11 x2), `relic_r0-4` (x2), `shard*/shards*` không-lib (x3), family pos/mana/rule không-lib | 18+22+10+18+9 = 77 | **không còn dùng** (commit 8768454 trả về bản cũ / lib) | (b) | UI6Assets.gd | | | Chết, nên xoá khỏi repo để khỏi nhầm |
| `ui3/icons/house_*.svg` | 6 | AnchorCard/Tile/Chip, Codex, Result, CombatView, DiceDock, Land | (c) | commit 10b7ae6 "neutral house sigils", agent Claude Opus viết SVG tay (suy luận: không có handoff kèm) | không (kho không có ký hiệu nhà) | huy hiệu: bám `art-2d/items/s21a-c` (cờ), `art-2d/rewards/*` | Liam đã chốt giữ bản này cho UI-06; giờ đợt polish tính lại, cần Liam xác nhận |
| `icons/hl/*` (10 png + 14 svg) | 24 | aid, attrition, drawback, gift, lethal, mooncard, reroll, skip, spike, undo, lock, pact, eternal, boss-clock, gem… (Land, Run, Combat) | (b) (suy luận) | commit 71d3fea (10/10 theme v3); md5 toàn bộ 24 nằm trong `ui-02-round5/_zip/hl/icons` (Claude Design giao) | có phần | gem: `DL/icons/gem_*`; spike: `spiky_ball_*`; gift: `DL/icons/*` hộp quà chưa thấy; lock/undo/skip: không có | Viền đen dày kiểu sticker |
| `ui3/icons/cur_*` (stone, ticket, fragment, gem, shard + cỡ 16-64) | ~16 | header tiền tệ, Echo Box | (b) (suy luận) | commit 7594a4a (UI-03); file nằm trong `ui-03-redesign/round-1/.../assets` | có | stone: `DL/icons/stone_block.png`; gem: `gem_pink/red.png`; shard: `diamond.png`; ticket: không có | cur_shard trùng md5 `icons/web/shard.png` |
| `ui3/icons/ui_check, ui_lock, ui_menu, ui_reroll, ui_settings, ui_undo, face_blank, face_buff, face_debuff, face_mana` (svg) | 10 | HUD, die face | (b)/(c) (suy luận) | commit 7594a4a; không có README nguồn | không | `DL/icons/` không có UI glyph | Glyph đơn giản, hand-authored |
| `ui3/icons/ui_mooncard.png` | 1 | UI | (e) | 7594a4a | | | |
| `icons/web/{blank,buff,debuff,mana,reroll,settings}.svg` | 6 | die face, HUD | (c) | commit 0eed4b6: "no source asset existed, hand-authored" bởi agent | không | | Chính commit nói tự vẽ |
| `icons/web/shard.png`, `armor.png`, `enrage.png` | 3 | Gene Shard, Armor, Enrage | (e)/(a) | enrage: commit b0a6f93 "from Atia icons" (a); shard + armor chưa truy được | | | Cần Liam xác nhận |
| `ui7/logo_axiedice.png` | 1 | LoginScreen | (b) | `ui-07-login/round-1/_zip/ui07/README`: logo bake bằng `bake-ui07.js` font Baloo 2 | không (logo game mình) | | Chữ bake, không phải tranh; Liam quyết có tính AI không |
| `ui7/bg_login_1280/1920.png` | 2 | LoginScreen nền | (a) đã bị Claude Design chỉnh | README: lấy từ Homeland `axie-reference/environment/field_garden_land_tree_garden.jpg`, xoá Axie + chữ, làm mờ, hạ sáng | có | `DL/art-2d/environment/` (ảnh gốc, tìm `field_garden...`) | Nền gốc là chính thức, nhưng bản đang dùng là đã qua xử lý; nên bake lại từ ảnh gốc |
| `cosmetics/dice/*` (26 skin: albedo, normal, emission, plate, trim, sparkle) | 222 | mặt xúc xắc 3D, tile, Echo Box | (b) | `design/handoffs/cosmetics-3d/round-1..5` (md5 trùng toàn bộ); commit d605fc3, 2b8e117 | không | chất liệu thật: texture vật liệu từ `asset-library/godot-ready/src/**/materials` (gỗ, đá, kim loại), `DL/icons/ingot_*`, `gem_*` | R5 README ghi "Claude Design review sheet"; phần lớn là texture sinh |
| `cosmetics/frames/*` (49 base + layer) | 49 | khung avatar | (b) | cosmetics-3d round 2-5 | không | `art-2d/rewards/*`, `art-2d/items/*` | |
| `portraits/{aqua,beast,bird,bug,plant,reptile}.png` | 6 | hồ sơ / chọn class | (e) | từ commit 042bfaf (vendor từ bản JS); md5 nằm trong ui-05-figma/round-3 (chỉ gửi đi) | có thể | Axie là 3D thật; kho không có ảnh Axie (INDEX: "No Axie images") | Cần Liam xem |

## B. Kho / chính thức (không cần làm lại)

| file / bộ | số file | dùng ở đâu | nguồn | bằng chứng | ghi chú |
|---|---|---|---|---|---|
| `icons/web/part/*.svg` | 36 | icon bộ phận (Mouth, Horn…) | (a) | `icon-set-2026-09-08/README`: `@axieinfinity/dango-icons` | |
| `icons/web/*.png` (battle, boss, elite, event, shop, chest, dmg, heal, poison, shield, summon, burn, freeze…) + `icons/node/*` (6) + `ui3/icons/{face_*,node_*,status_*}.png` (trùng md5 với web) | ~23 + 6 + 14 | ô map, status, die face | (a) | README: Origins Asset Kit `Textures/StatusIcons`, `wolf_pack`, `bloodmoon`...; commit 386dad0, 0eed4b6 | `blind` và `freeze` là placeholder (kit không có đúng hình); viền đen dày, lệch style Homeland |
| `cards/*` (card_*, node_*, relic_r0-4, shop_*) | 16 | thẻ thưởng/shop/event/relic (đang dùng lại bản cũ) | (a) | commit 530abab: "Origins Kit ships 91 painted 320x320 card illustrations", ghép bằng mắt | Chưa so md5 (kit Origins không có trong `asset-library`). Audit UI-06 nêu 4 tranh có sinh vật giống Axie |
| `ui6/lib/*` (family pos/mana/rule, shard/shards x3) | 27 | CoreCard, shard | (a) (dẫn xuất) | commit 8768454; theo audit lấy từ `DL/art-2d/items` (s21, s16b, f14c) và `icons/gem_*`, `diamond` | Resize từ kho |
| `echobox/chests/*` | 16 | Echo Box (mới 2 file được tham chiếu) | (a)/(d) | `chests/README.md`: Liam gửi 12/10 từ Google Drive, "art Axie Infinity 2D" | |
| `backgrounds/origins/*` | 53 | nền màn (14 file được tham chiếu) | (a) | commit 042bfaf "painted backdrops" Origins | |
| `monsters/*.png` + `monsters/anim/*` | 21 + 55 | quái 2D | (a) | `chimera-monster-art-mapping`: 75 PNG Chimeras của Origins; commit e3cc563 render từ Spine chính thức | |
| `vfx/*` | 42 | VFX kỹ năng | (a) | commit 9c2077e "real Origins skill VFX" | |
| `bosses/*` | 21 | texture boss 3D | (a) | 4 file trùng md5 `godot-ready/src`; commit 16c4a9b "official art-team FBX" | 3D, không phải UI |
| `atia/*` (44 arena + 28 quái) | 72 | texture 3D | (a) | 40 file trùng md5 `godot-ready/src` | 3D |
| `atia/arena_v2/*` | 42 | không thấy tham chiếu theo tên | (c) | commit 2601b04, 25ba8b3: Blender GLB dựng từ kit, texture sinh trong Blender | 3D, bỏ qua |
| `land/homeland/*` | 108 | Land 3D | (a) | 88 file trùng md5 `godot-ready/src` | texture 3D |
| `axie/back-*.png` | 5 | thân Axie 3D | (a) (suy luận) | commit 042bfaf | |
| `land/tier_previews/*` (6), `ui3/result_bg/*.jpg` (6) | 12 | preview tier Land, nền Result | (c) | commit 812bd35, dca163f: render nội bộ từ scene 3D kho | Ảnh chụp scene kho, không vẽ |
| `ui7/google_g.svg` | 1 | nút Google | (d) | logo Google chính thức | giữ |

## C. Tổng kết

Đếm theo file (không tính `.import`), phạm vi 2D người chơi thấy:

| nguồn | số file (xấp xỉ) | ghi chú |
|---|---|---|
| (a) kho / chính thức (gồm texture 3D) | ~530 | 2D thuần (icon, thẻ, nền, quái, vfx, rương): ~290 |
| (b) Claude Design | ~490 | ui6 166 (live 71, chết 95) + cosmetics 271 + hl 24 + ui3 cur/ui ~26 + ui7 logo |
| (c) AI khác / script / agent tự vẽ | ~75 | 12 svg tự vẽ (house 6, web 6) + render nội bộ 12 + arena_v2 42 (3D) |
| (d) nguồn ngoài có ghi | 1 | google_g |
| (e) chưa rõ | ~11 | portraits 6, web shard/armor, ui_mooncard, v.v. |

### AI chắc chắn (làm lại, bám kho)
1. `ui6` đang dùng: family dice/stat/quest/run_rule, badge x6, ui_awaken, slot x4, frame_core x3 + frame_run_rule, crest/artwin/back_art x9, fx x5. Tổng 71 file = **~26 asset logic** (không tính cỡ).
2. `cosmetics/dice` (26 skin) + `cosmetics/frames` (49 file). Hầu hết texture sinh, mỗi skin là 1 asset logic.
3. `icons/hl/*` (24) và `ui3/icons/cur_*` (suy luận từ handoff, nhưng handoff do Claude Design giao).
4. `ui6` chết (95 file, 77+18): nên xoá, không cần làm lại.

### Chưa rõ, cần Liam xác nhận
- 6 `house_*.svg`: agent Claude tự viết SVG, không phải kho. Tính AI hay không?
- `icons/web/*.svg` 6 cái tự vẽ (blank, buff, debuff, mana, reroll, settings) và 10 svg `ui3` (ui_*, face_*): tính AI?
- `portraits/*` (6), `icons/web/shard.png`, `armor.png`, `ui_mooncard.png`.
- `logo_axiedice.png` (chữ bake) và `bg_login` (ảnh kho nhưng đã bị xử lý).
- `cards/*`: commit ghi từ Origins Kit nhưng không so được md5 (kit Origins không có trong `asset-library`). Cần Liam hoặc kit gốc để xác nhận.
- `icons/web` png là Origins Kit thật, nhưng viền đen dày lệch style Homeland; có thay không là chuyện style chứ không phải AI.

### Kho thay được vs phải vẽ mới (cho nhóm AI, ~26 asset ui6 live + hl + cur + svg)
- Kho thay trực tiếp / gần: badge_attack, badge_egg, shard 3 bậc (đã làm trong lib), family pos/mana/rule (đã có trong lib), gem/diamond cho cur_gem/cur_shard, cur_stone: **~10 asset**.
- Phải vẽ mới nhưng bám kho (Claude Design tô từ kho): family dice/stat/quest/run_rule, badge x4, awaken, slot x4, khung / crest / artwin / back_art (13), fx x5, house x6, hl icon ~20, ui glyph ~10: **~65 asset**.
- Cosmetics: 26 dice + 49 frame, đây là mảng lớn nhất; kho chỉ cho vật liệu / màu tham khảo, không có bản thay.

## Ảnh kèm (dưới 1 MB)
- `production/qa/art-provenance-sheet1-ui6-live.png`: ui6 đang dùng (nhóm AI chắc chắn)
- `production/qa/art-provenance-sheet2-hl-cur-login-cosmetics.png`: hl, cur_*, login, mẫu cosmetics
(SVG không có trong sheet vì máy chưa có bộ render SVG.)

## Hạn chế của lần kiểm kê này
- "Được dùng" kiểm bằng grep tên, nên asset load động (ui6, cosmetics) có thể bị sót; bảng trên dựa thêm vào `UI6Assets.gd`.
- Số liệu là xấp xỉ, chưa gộp lại bằng script cuối. `.import` không tính.
- Chưa so md5 `cards/*`, `backgrounds/origins`, `monsters`, `vfx` với kit Origins vì kit không nằm trong repo.

## Xác minh thêm (3/11, sau review art-director)
- `cards/*` (16 tranh thẻ thưởng/shop/event/rương): commit 530abab ghi rõ là tranh vẽ sẵn trong **Axie Origins Kit** (91 tranh 320x320). Đây là art CHÍNH THỨC, không phải AI.
- `icons/web/*.png` và `portraits/*` (6 chân dung class): đưa vào ở 042bfaf, cùng lúc với bộ art của bản game JS cũ.
- `house_*.svg`: 10b7ae6, do agent tự vẽ bằng code. `ui3/icons/cur_*`: 7594a4a (UI-03). `icons/hl/*`: 71d3fea (theme v3).

## Liam quyết (3/11)
- 6 house SVG + ~16 icon SVG khác do agent tự vẽ: **tính là AI, làm lại**.
- `icons/web` + 6 chân dung class: **chính thức, giữ**.
- Cosmetics (26 skin xúc xắc + 49 khung, Claude Design): **làm lại trong đợt này**.
- Logo chữ "AXIE DICE" và nền màn đăng nhập: **giữ như hiện tại**.
- Đã chốt trước đó: `cards/*` là Origins Kit nên giữ. ui6 Claude Design (family dice/stat/quest/run_rule, badge, awaken, slot, khung/crest/artwin/back_art, fx) làm lại. 95 file ui6 không còn ai dùng thì XOÁ, không làm lại.
- Phần kho không có: Claude Design vẽ lại BÁM KHO, Liam duyệt từng món.
