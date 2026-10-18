# UI-03 round 1: danh sách chỗ handoff chưa phủ

Đã review: art-director 18/10. Sửa: A4 (inspect là có thật, chuột phải), A22 gộp vào A27 (quà mùa = hàng thưởng Gem trong Pass), A34 (3 phase, không phải 2), gộp A9+A10 và A14 vào A12, bỏ B10 (code đã khớp: E và Space đều End turn), B2 và B1 đã chốt (xem cuối bảng). Số mục trong bảng giữ nguyên để khỏi lệch tham chiếu.

Audit 18/10/2026, chỉ đọc code + spec, chưa sửa gì. Bỏ qua dev_review và main_menu (đã xoá).
Priority: Must = người chơi gặp trong run đầu tiên, Should = meta / gặp sau, Could = hiếm.
"Một phần" = handoff có màn đó nhưng thiếu state ghi ở cột cuối.

## A. Thiếu hẳn hoặc chỉ phủ một phần

| # | Tên | Code | Khi nào người chơi thấy | Pri | Thiếu gì |
|---|---|---|---|---|---|
| 1 | Aid zone: nút Aid, offer card, Aid tray, modal xác nhận mua lần đầu | `combat/AidPanel.gd`, `combat/aid_purchase.gd` | Trong trận, bên trái dưới (phím A), ẩn 5 run đầu | Should | Một phần: 02-combat chỉ có "Aid tray (newcomer): free Aid only". Thiếu bản thật có giá Gem, offer, modal, dòng "fairness", row disabled vẫn hiện giá |
| 2 | Defeat panel (Continue có giá, recap 6 dòng, boss giữ HP/phase, heal %, End run) | `combat/DefeatPanel.gd` | Cả party chết | Must | Một phần: handoff chỉ có "Party down" + "See results". Thiếu Continue/hồi sinh, giá, recap, boss còn lại |
| 3 | Nút Undo (phím Z) trong combat | `combat/CombatView.gd` ~556 | Trong trận | Must | Handoff có icon ui_undo nhưng spec 02-combat không có nút, state disabled, chỗ đặt |
| 4 | Inspect đơn vị: chuột phải lên model 3D, luôn mở inspector kể cả khi đang chọn die; không đổi state game | `shared/CombatStage3D.gd` 33-39 (`unit_inspect_requested`), `combat/CombatView.gd` `_open_unit_inspect`, `_inspect_panel` | Trong trận | Should | Info panel chỉ phủ khi chọn xúc xắc, không phủ inspector. Cần chỗ cho cách mở không chuột phải (touch/phím) nếu có |
| 5 | Intent badge, status chip trên đầu, float text (CRIT, LINK, +REROLL, SUMMON) | `shared/UnitHeadHUD.gd`, `shared/UnitPortrait.gd` | Trong trận | Must | Một phần: có status chip Shield/Poison, thiếu burn/weaken/... và float text |
| 6 | Victory march + skip | `combat/CombatView.gd` ~538 | Thắng trận | Could | Không có state |
| 7 | Reward loại khác relic: HP, +Reroll, Level, Ascend, Chaos, Curse | `core/reward_generator.gd`, `run_map/RunMapController.gd` `_show_reward_overlay` | Sau trận | Must | Handoff ghi "pick 1 of 3 relics". Cần layout cho các loại này |
| 8 | Slot relic / active đầy: đổi, bán | `run_map/RunMapController.gd` | Nhặt/mua khi đầy slot | Must | Không có state thay thế. Shop có sell plate, reward/treasure thì không |
| 9 | Pact: swap có trả phí (Aid mua đổi thẻ) + bán pact (gộp cũ #9 và #10) | `run_map/RunMapController.gd` 2170, `AidPurchase.buy_pact_swap`, `pact/PactView.gd` `_show_sell` | Boss pact | Should | Handoff có "Swap a card · 1 left", chưa nói trả bằng gì, state đang mua / lỗi. Không có state bán pact |
| 10 | (gộp vào #9) | | | | |
| 11 | NetNotice cho lỗi epoch giữa run (RETRY / "session expired": SIGN IN + BACK TO MENU) | `shared/NetNotice.gd` | Combat, map, reward, shop (action cần server) | Must | 18-system có notice offline + Retry, thiếu bản fatal (hết phiên), không khoá input |
| 12 | Welcome sau đăng nhập, desktop sign-in flow (chờ trình duyệt), chip tài khoản, badge Sky Mavis, toast lỗi tài khoản theo code (gộp cũ #14) | `shared/AccountUI.gd` (`show_welcome`, `show_desktop_flow`, `build_chip`, `sky_mavis_badge`, `show_toast`) | Lần đầu, mỗi lần đăng nhập | Must | 16-boot có signing in, 26-settings có welcome nhưng không có state "đang chờ trình duyệt", chip, badge, bảng toast theo code lỗi |
| 13 | Chọn save (cloud vs máy) | `shared/AccountUI.gd` `show_choice` | Đăng nhập khi 2 save lệch | Must | Có tên state ở 26-settings, nhưng phải kiểm: nó là overlay lúc boot, không chỉ trong Settings |
| 14 | (gộp vào #12) | | | | |
| 15 | Thẻ "run chưa xong" trên Run setup (New run = mất cọc) | `run_setup/RunSetup.gd` ~1159, state `open_run` | Vào Run setup khi có run dở | Must | Handoff chỉ có dialog "Continue your run?" ở Land. Thiếu cảnh báo mất stake |
| 16 | Run setup: picker chọn Axie, mở leaderboard, load/save preset | `run_setup/RunSetup.gd` `open_picker`, `open_leaderboard`, `open_load_presets`, `open_save_preset` | Chọn đội | Must | Chỉ có Team presets (nút). Picker, 2 popup preset, leaderboard popup không có |
| 17 | Run setup: chọn Daily / Ranked + lý do khoá + lượt Daily | `run_setup/RunSetup.gd` `select_kind`, `kind_block_reason`, `daily_tries` | Run setup | Must | "4 mode rows" chưa khớp: game có kind (Normal/Daily/Ranked) + độ dài (Short/Full). Cần chốt |
| 18 | Missions = bảng cọc Shard (tier, Stake/Pay/Stone, confirm modal, escrow, khoá theo lý do, settle) | `missions/MissionsScreen.gd` (+ `MissionEscrowSync`) | Nhà Weaponsmith, phím 3 | Should | 22-missions viết như nhiệm vụ daily/weekly. Không có confirm modal M6c, thiếu Shard, "open run", kết quả thắng/thua cọc |
| 19 | Daily screen (Daily reward, Weekly bonus, Gem gift L1) | `daily/DailyScreen.gd` | Phím D (online-only) | Should | Handoff gộp Daily vào 22-missions nhưng nội dung là "Daily run tries". Thiếu 3 thẻ claim + guest/offline |
| 20 | Result: thẻ Shard, thẻ Pass XP, thẻ relics, quyết toán cọc mission | `result/ResultView.gd` | Hết run | Must | Một phần: 10-result có stats + earnings rows. Thiếu Pass card, relics card, thắng/thua stake |
| 21 | Titles (chọn title, mở title) | `profile/ProfileView.gd`, `result/ResultView.gd` | Profile, Result | Should | Result có title unlock, Profile spec chỉ nhắc "titles" trong Purpose, không có tab/state chọn |
| 22 | (gộp vào #27) Quà mùa = hàng thưởng Gem "Season gift" trong Pass (`pass/PassView.gd` 390, tổng 180 Gem theo `t_economy`). Tab Seasonal của Echo Box là "coming later", không có nút Open ở L1 | | | | |
| 23 | Moon Card popup + nút ở Land | `land/Land.gd` `show_moon_card` | Land, Store | Should | Có popup "day n of 30 + Collect" ở Store. Thiếu chỗ gọi từ Land, state đã nhận hôm nay |
| 24 | Land: toast, confirm dialog, first_launch, building locked newcomer ("Opens after 5 runs"), gallery (từ Genesis), billboard Leaderboard | `land/Land.gd` | Land | Must | Có locked. Thiếu: toast, confirm dùng chung, nhà Gallery (tier 5), nút online-only khi guest |
| 25 | Profile: mở account từ Profile, avatar frame, ô cosmetic | `profile/ProfileView.gd`, `shared/AvatarFrame.gd`, `shared/CosmeticTile.gd` | Profile / Store | Should | Có tile Equipped/Owned/Locked. Thiếu frame avatar trên HUD Land, preview cosmetic trong trận |
| 26 | Echo Box: mở tại chỗ + mở 10 + rates; confirm mua | `echobox/EchoBoxScreen.gd` | Phím 4 | Should | Có đủ ở spec. Thiếu guest ("Sign in to use this", đọc rate được) và offline "nothing is spent" |
| 27 | Pass: chi tiết thưởng, level card | `pass/PassView.gd` `_show_detail`, `_build_level_card` | Phím 5 | Should | Thiếu state thưởng đã nhận, chưa mở, popup chi tiết, hàng "Season gift" (Gem, đi đường grant) |
| 28 | Vault: panel import (nhập Axie ID, Scan), panel record, đầy VAULT_MAX | `vault/VaultView.gd` | Phím 6 | Should | Có lookup/not found/error/empty/guest. Thiếu import panel, record, đầy kho, lưu máy-cục-bộ |
| 29 | Leaderboard: chi tiết 1 dòng (run replay) | `leaderboard/LeaderboardScreen.gd` `open_detail` | Billboard | Should | Spec có "View run" nhưng thiếu state chi tiết |
| 30 | Team presets: picker slot, editor | `team_presets/TeamPresetsScreen.gd` | Nhà House | Should | Có normal/empty/full/missing/delete. Thiếu editor + picker |
| 31 | Tutorial: curtain (màn che) + màn thưởng cuối | `tutorial/TutorialCoach.gd` `show_curtain`, `show_rewards`, `tutorial/TutorialView.gd` | Run đầu | Must | 17-tutorial chỉ có "step n of 5". Thiếu curtain mở đầu, rewards cuối |
| 32 | Guides tab (thẻ guide) + Unlocks tab (10 mục) | `guides/GuidesView.gd`, `unlocks/UnlocksView.gd` | Codex | Could | Chỉ 1 dòng state mỗi tab. Thiếu layout riêng |
| 33 | In-run menu: thẻ quit confirm, Abandon quyết toán cọc | `combat/CombatView.gd` `_build_quit_confirm`, `settings/SettingsView.gd` | Esc trong run | Must | Có dialog. Thiếu dòng mất stake khi abandon |
| 34 | Boss: "Phase 1 of 3" | `assets/data/rules/combat_tune.json` `phase_thresholds` [66, 33] (HP%), `combat/DefeatPanel.gd` 118 mặc định 3 | Boss | Must | Handoff ghi "of 2". Game có 3 phase, đổi ở 66% và 33% HP. Cần chỗ hiện đổi phase, không ghi cứng số |
| 35 | Battle backdrop theo node/boss | `shared/BattleBackdrop.gd` | Vào trận | Could | Không rõ handoff dùng 3D stage thay; cần xác nhận |
| 36 | Hover / tooltip relic, active, face xúc xắc | `run_map/RunMapController.gd` `_build_relic_row`, `shared/HPBar.gd` | Map, combat | Should | Không có spec tooltip (chỉ info panel khi chọn die) |

## B. Handoff giả định khác game

| # | Handoff nói | Game thật | Mức |
|---|---|---|---|
| 1 | "Offline never blocks Normal runs", "Play as guest", "Play offline" (README, 01, 16) | L1: xúc xắc roll trên server. Guest / hết phiên không bắt đầu được kind nào: "Sign in to play" (`RunSetup.gd` 268, 354, test `t_run_setup`) | Cao, Must |
| 2 | Xúc xắc ném vật lý `RigidBody3D` bay vào tray | Code hiện chưa có (stage slot cố định, reroll toss 2D). Liam đã duyệt: dựng đúng như spec, kết quả vẫn do RNG engine quyết, vật lý chỉ để trình diễn. Không còn là lệch | Đã chốt |
| 3 | Crit = 20%, x2, camera shake 6 px | Không có 20% cố định. Chỉ mặt `dmg` bên party, % lấy từ keyword `crit` của mặt + relic `critBonus` (`combat_engine.gd` 507-515) | Cao |
| 4 | Reroll 2 mỗi lượt | 2 là mức gốc. Ascension, `bonus_reroll`, relic `rerollUp` đổi `max_rerolls` (`combat_engine.gd` 204-207). Handoff phải hiện số động | Trung bình |
| 5 | Egg tối đa 6, phím 6-9 và 0 | Mặc định 4 token còn sống (`tokenCap` mặc định 4), relic nâng. Phím chọn chỉ có 1-5 (+R, E/Space, Z, A) | Cao |
| 6 | Reward = chọn 1 trong 3 relic | Có thêm HP, Reroll, Level, Ascend, Chaos, Curse | Cao |
| 7 | Defeat = "Party down" + "See results" | Defeat có Continue (có giá, 1 lần, hồi % máu) và End run | Cao |
| 8 | Missions = nhiệm vụ daily/weekly; Daily run "2 of 3" nằm ở Land | Missions = bảng cọc Shard. Daily claim ở màn Daily riêng. Lượt Daily (max 3) có thật ở Run setup | Trung bình |
| 9 | "Aid tray (newcomer): free Aid only" | Newcomer (5 run đầu) không thấy Aid nào: ẩn hoàn toàn (`AidPanel.gd` dòng 10-11) | Trung bình |
| 10 | (bỏ) Space = End turn | Code khớp: E và Space đều End turn, Space/Enter/Esc còn skip animation (`CombatView.gd` 541-553) | Không lệch |
| 11 | Tiền: Gem, Shard, Stone luôn trên header | Shard là tiền trong run và cũng là tiền cọc (starter Shard không cọc được). Stone chưa có art. Gem violet chỉ cho bề mặt trả phí (CLAUDE.md godot) | Thấp |

## C. Nên hỏi Liam
- Đã chốt, không cần hỏi nữa: B1 (bắt buộc đăng nhập để chơi ở L1, Liam 15/10), B2 (ném xúc xắc vật lý sẽ dựng).
- Còn hỏi: A4 inspect hiện chỉ mở bằng chuột phải, có cần đường mở khác không (touch)?
