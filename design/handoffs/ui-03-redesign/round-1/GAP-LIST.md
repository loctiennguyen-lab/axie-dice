# UI-03 round 1: danh sách chỗ handoff chưa phủ

Audit 18/10/2026, chỉ đọc code + spec, chưa sửa gì. Bỏ qua dev_review và main_menu (đã xoá).
Priority: Must = người chơi gặp trong run đầu tiên, Should = meta / gặp sau, Could = hiếm.
"Một phần" = handoff có màn đó nhưng thiếu state ghi ở cột cuối.

## A. Thiếu hẳn hoặc chỉ phủ một phần

| # | Tên | Code | Khi nào người chơi thấy | Pri | Thiếu gì |
|---|---|---|---|---|---|
| 1 | Aid zone: nút Aid, offer card, Aid tray, modal xác nhận mua lần đầu | `combat/AidPanel.gd`, `combat/aid_purchase.gd` | Trong trận, bên trái dưới (phím A), ẩn 5 run đầu | Should | Một phần: 02-combat chỉ có "Aid tray (newcomer): free Aid only". Thiếu bản thật có giá Gem, offer, modal, dòng "fairness", row disabled vẫn hiện giá |
| 2 | Defeat panel (Continue có giá, recap 6 dòng, boss giữ HP/phase, heal %, End run) | `combat/DefeatPanel.gd` | Cả party chết | Must | Một phần: handoff chỉ có "Party down" + "See results". Thiếu Continue/hồi sinh, giá, recap, boss còn lại |
| 3 | Nút Undo (phím Z) trong combat | `combat/CombatView.gd` ~556 | Trong trận | Must | Handoff có icon ui_undo nhưng spec 02-combat không có nút, state disabled, chỗ đặt |
| 4 | Inspect đơn vị (bấm xem Axie/quái) | `combat/CombatView.gd` `_open_unit_inspect`, `combat/InfoPanelView.gd` | Trong trận | Should | Info panel chỉ phủ khi chọn xúc xắc, không phủ xem đơn vị |
| 5 | Intent badge, status chip trên đầu, float text (CRIT, LINK, +REROLL, SUMMON) | `shared/UnitHeadHUD.gd`, `shared/UnitPortrait.gd` | Trong trận | Must | Một phần: có status chip Shield/Poison, thiếu burn/weaken/... và float text |
| 6 | Victory march + skip | `combat/CombatView.gd` ~538 | Thắng trận | Could | Không có state |
| 7 | Reward loại khác relic: HP, +Reroll, Level, Ascend, Chaos, Curse | `core/reward_generator.gd`, `run_map/RunMapController.gd` `_show_reward_overlay` | Sau trận | Must | Handoff ghi "pick 1 of 3 relics". Cần layout cho các loại này |
| 8 | Slot relic / active đầy: đổi, bán | `run_map/RunMapController.gd` | Nhặt/mua khi đầy slot | Must | Không có state thay thế. Shop có sell plate, reward/treasure thì không |
| 9 | Pact swap có trả phí (Aid mua đổi thẻ) | `run_map/RunMapController.gd` 2170, `AidPurchase.buy_pact_swap` | Boss pact | Should | Handoff có "Swap a card · 1 left", chưa nói trả bằng gì, state đang mua / lỗi |
| 10 | Pact sell (bán pact) | `pact/PactView.gd` `_show_sell` | Boss pact | Should | Không có state |
| 11 | NetNotice cho lỗi epoch giữa run (RETRY / "session expired": SIGN IN + BACK TO MENU) | `shared/NetNotice.gd` | Combat, map, reward, shop (action cần server) | Must | 18-system có notice offline + Retry, thiếu bản fatal (hết phiên), không khoá input |
| 12 | Welcome sau đăng nhập, desktop sign-in flow (chờ trình duyệt), chip tài khoản, badge Sky Mavis | `shared/AccountUI.gd` (`show_welcome`, `show_desktop_flow`, `build_chip`, `sky_mavis_badge`) | Lần đầu, mỗi lần đăng nhập | Must | 16-boot có signing in, 26-settings có welcome nhưng không có state "đang chờ trình duyệt", chip, badge |
| 13 | Chọn save (cloud vs máy) | `shared/AccountUI.gd` `show_choice` | Đăng nhập khi 2 save lệch | Must | Có tên state ở 26-settings, nhưng phải kiểm: nó là overlay lúc boot, không chỉ trong Settings |
| 14 | Toast lỗi tài khoản theo code | `shared/AccountUI.gd` `show_toast` | Mọi lúc | Should | Có toast chung, chưa có bảng code |
| 15 | Thẻ "run chưa xong" trên Run setup (New run = mất cọc) | `run_setup/RunSetup.gd` ~1159, state `open_run` | Vào Run setup khi có run dở | Must | Handoff chỉ có dialog "Continue your run?" ở Land. Thiếu cảnh báo mất stake |
| 16 | Run setup: picker chọn Axie, mở leaderboard, load/save preset | `run_setup/RunSetup.gd` `open_picker`, `open_leaderboard`, `open_load_presets`, `open_save_preset` | Chọn đội | Must | Chỉ có Team presets (nút). Picker, 2 popup preset, leaderboard popup không có |
| 17 | Run setup: chọn Daily / Ranked + lý do khoá + lượt Daily | `run_setup/RunSetup.gd` `select_kind`, `kind_block_reason`, `daily_tries` | Run setup | Must | "4 mode rows" chưa khớp: game có kind (Normal/Daily/Ranked) + độ dài (Short/Full). Cần chốt |
| 18 | Missions = bảng cọc Shard (tier, Stake/Pay/Stone, confirm modal, escrow, khoá theo lý do, settle) | `missions/MissionsScreen.gd` (+ `MissionEscrowSync`) | Nhà Weaponsmith, phím 3 | Should | 22-missions viết như nhiệm vụ daily/weekly. Không có confirm modal M6c, thiếu Shard, "open run", kết quả thắng/thua cọc |
| 19 | Daily screen (Daily reward, Weekly bonus, Gem gift L1) | `daily/DailyScreen.gd` | Phím D (online-only) | Should | Handoff gộp Daily vào 22-missions nhưng nội dung là "Daily run tries". Thiếu 3 thẻ claim + guest/offline |
| 20 | Result: thẻ Shard, thẻ Pass XP, thẻ relics, quyết toán cọc mission | `result/ResultView.gd` | Hết run | Must | Một phần: 10-result có stats + earnings rows. Thiếu Pass card, relics card, thắng/thua stake |
| 21 | Titles (chọn title, mở title) | `profile/ProfileView.gd`, `result/ResultView.gd` | Profile, Result | Should | Result có title unlock, Profile spec chỉ nhắc "titles" trong Purpose, không có tab/state chọn |
| 22 | Season gift / quà mùa | `profile/ProfileView.gd`, `store/StoreScreen.gd`, `echobox/EchoBoxScreen.gd` (grep "season") | Đầu mùa / Store | Should | Chưa tìm thấy state. Cần hỏi design là ở đâu |
| 23 | Moon Card popup + nút ở Land | `land/Land.gd` `show_moon_card` | Land, Store | Should | Có popup "day n of 30 + Collect" ở Store. Thiếu chỗ gọi từ Land, state đã nhận hôm nay |
| 24 | Land: toast, confirm dialog, first_launch, building locked newcomer ("Opens after 5 runs"), gallery (từ Genesis), billboard Leaderboard | `land/Land.gd` | Land | Must | Có locked. Thiếu: toast, confirm dùng chung, nhà Gallery (tier 5), nút online-only khi guest |
| 25 | Profile: mở account từ Profile, avatar frame, ô cosmetic | `profile/ProfileView.gd`, `shared/AvatarFrame.gd`, `shared/CosmeticTile.gd` | Profile / Store | Should | Có tile Equipped/Owned/Locked. Thiếu frame avatar trên HUD Land, preview cosmetic trong trận |
| 26 | Echo Box: mở tại chỗ + mở 10 + rates; confirm mua | `echobox/EchoBoxScreen.gd` | Phím 4 | Should | Có đủ ở spec. Thiếu guest ("Sign in to use this", đọc rate được) và offline "nothing is spent" |
| 27 | Pass: chi tiết thưởng, level card | `pass/PassView.gd` `_show_detail`, `_build_level_card` | Phím 5 | Should | Thiếu state thưởng đã nhận, chưa mở, popup chi tiết |
| 28 | Vault: panel import (nhập Axie ID, Scan), panel record, đầy VAULT_MAX | `vault/VaultView.gd` | Phím 6 | Should | Có lookup/not found/error/empty/guest. Thiếu import panel, record, đầy kho, lưu máy-cục-bộ |
| 29 | Leaderboard: chi tiết 1 dòng (run replay) | `leaderboard/LeaderboardScreen.gd` `open_detail` | Billboard | Should | Spec có "View run" nhưng thiếu state chi tiết |
| 30 | Team presets: picker slot, editor | `team_presets/TeamPresetsScreen.gd` | Nhà House | Should | Có normal/empty/full/missing/delete. Thiếu editor + picker |
| 31 | Tutorial: curtain (màn che) + màn thưởng cuối | `tutorial/TutorialCoach.gd` `show_curtain`, `show_rewards`, `tutorial/TutorialView.gd` | Run đầu | Must | 17-tutorial chỉ có "step n of 5". Thiếu curtain mở đầu, rewards cuối |
| 32 | Guides tab (thẻ guide) + Unlocks tab (10 mục) | `guides/GuidesView.gd`, `unlocks/UnlocksView.gd` | Codex | Could | Chỉ 1 dòng state mỗi tab. Thiếu layout riêng |
| 33 | In-run menu: thẻ quit confirm, Abandon quyết toán cọc | `combat/CombatView.gd` `_build_quit_confirm`, `settings/SettingsView.gd` | Esc trong run | Must | Có dialog. Thiếu dòng mất stake khi abandon |
| 34 | Boss: "Phase 1 of 2" | `core/combat_engine.gd` (`phase_thresholds`) | Boss | Must | Game đọc ngưỡng từ data, kiểm số phase trước khi ghi cứng "of 2" |
| 35 | Battle backdrop theo node/boss | `shared/BattleBackdrop.gd` | Vào trận | Could | Không rõ handoff dùng 3D stage thay; cần xác nhận |
| 36 | Hover / tooltip relic, active, face xúc xắc | `run_map/RunMapController.gd` `_build_relic_row`, `shared/HPBar.gd` | Map, combat | Should | Không có spec tooltip (chỉ info panel khi chọn die) |

## B. Handoff giả định khác game

| # | Handoff nói | Game thật | Mức |
|---|---|---|---|
| 1 | "Offline never blocks Normal runs", "Play as guest", "Play offline" (README, 01, 16) | L1: xúc xắc roll trên server. Guest / hết phiên không bắt đầu được kind nào: "Sign in to play" (`RunSetup.gd` 268, 354, test `t_run_setup`) | Cao, Must |
| 2 | Xúc xắc ném vật lý `RigidBody3D` bay vào tray | Không có RigidBody3D. Stage là slot cố định (`CombatStage3D.gd` dòng 13). Reroll là toss 2D (`reroll_fx/`). Kết quả đến từ RNG engine | Cao, Must |
| 3 | Crit = 20%, x2, camera shake 6 px | Không có 20% cố định. Chỉ mặt `dmg` bên party, % lấy từ keyword `crit` của mặt + relic `critBonus` (`combat_engine.gd` 507-515) | Cao |
| 4 | Reroll 2 mỗi lượt | 2 là mức gốc. Ascension, `bonus_reroll`, relic `rerollUp` đổi `max_rerolls` (`combat_engine.gd` 204-207). Handoff phải hiện số động | Trung bình |
| 5 | Egg tối đa 6, phím 6-9 và 0 | Mặc định 4 token còn sống (`tokenCap` mặc định 4), relic nâng. Phím chọn chỉ có 1-5 (+R, E/Space, Z, A) | Cao |
| 6 | Reward = chọn 1 trong 3 relic | Có thêm HP, Reroll, Level, Ascend, Chaos, Curse | Cao |
| 7 | Defeat = "Party down" + "See results" | Defeat có Continue (có giá, 1 lần, hồi % máu) và End run | Cao |
| 8 | Missions = nhiệm vụ daily/weekly; Daily run "2 of 3" nằm ở Land | Missions = bảng cọc Shard. Daily claim ở màn Daily riêng. Lượt Daily (max 3) có thật ở Run setup | Trung bình |
| 9 | "Aid tray (newcomer): free Aid only" | Newcomer (5 run đầu) không thấy Aid nào: ẩn hoàn toàn (`AidPanel.gd` dòng 10-11) | Trung bình |
| 10 | Space = End turn (spec) | Game có E và Space, README game ghi Space nên chỉ là skip, chờ Liam quyết (`CombatView.gd` 550-553) | Thấp |
| 11 | Tiền: Gem, Shard, Stone luôn trên header | Shard là tiền trong run và cũng là tiền cọc (starter Shard không cọc được). Stone chưa có art. Gem violet chỉ cho bề mặt trả phí (CLAUDE.md godot) | Thấp |

## C. Nên hỏi Liam
- Mục A22 (season gift) và A4 (inspect): chưa tìm được chỗ trong code, cần biết có còn dùng không.
- B1 làm mất nhiều state ở boot, Land, Run setup, Result: cần quyết trước khi dựng.
