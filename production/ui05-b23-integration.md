# UI-05 đợt 2+3: sổ tích hợp (người giữ `int/ui5-b23`)

Nhánh tích hợp: `int/ui5-b23`, worktree `../my-game-wt/u5b-0`. Luật chạy làn: `production/ui05-b23-lane-run.md`.

## Đã gộp vào int
| Làn | Hash đã review | Ghi chú |
|---|---|---|
| 0a dời component | fbd2b00 | review OK; suite 295 + skip t_rules_version |
| 0a token B2/B3 + godot/CLAUDE.md | f8ef1f1 (merge 5b484b5) | review OK; +t_ui5_tokens_b23 |
| 0a tool names | c5e7f57 | review OK |
| (suite int @ c5e7f57) | | 296/296 + skip t_rules_version |
| 0d meta kit | 1600edc (merge 6087640) | re-review OK; +t_ui5_meta_kit |
| 0c tách Land/RunSetup/EchoBox | e76bf37 (merge 655e061) | review OK |
| R6 menu trong run | 2aa2e7a (merge 76f5385) | re-review OK; +t_ui5_run_menu; hiện Pact trong panel Cores |
| (suite int @ 76f5385) | | 298/298 + skip t_rules_version |
| 0b tách RunMapController | 7f01ce7 (merge 051575e) | review OK + guard await; +t_runmap_split_log_golden |
| S6 Result | b95762f (merge 656d273) | re-review OK; +t_ui5_result |
| S5 Missions | 6f11420 (merge 4aeb626) | re-review OK; +t_ui5_missions; RetryButton chỉ banner offline |
| S14 Settings | b223d2a (merge eddaa6a) | re-review OK; +t_ui5_settings; KeyBindings Num keys |
| title tiếng Anh | efc9e74 | Liam 31/10 chọn dịch: Seal Keeper / Last One Standing (`ascension_titles.json` en; id giữ theo vi); assert mới ở t_economy chưa chạy suite |
| tích hợp | 8cae680 | DetailPlate scrollbar trong kit; align_check nhận ToneDisc |
| (suite int @ 8cae680) | | 302/302 + skip t_rules_version |
| R3 Anchor pick | 51e52d2 (merge 6733686) | re-review OK; +t_ui5_anchor_pick; token `r3_fx_*` |
| S1a Land HUD | c13b2d2 (merge 23f3d86) | review OK + chặn Space khi RunPlate tắt + test cỡ chữ nút; +t_ui5_land_hud |
| (suite int @ 23f3d86) | | 304/304 + skip t_rules_version |
| R5a Shop | fc5df37 (merge 2483203) | re-review OK; +t_ui5_shop |
| R4 Make room + Combo | 3db6091 (merge dfb53c1) | re-review OK; +t_ui5_make_room; Sell bán luôn (frame); combo band không timer; chữ theo thân frame |
| (suite int @ dfb53c1) | | 306/306 + skip t_rules_version |
| S10 Season Pass | 78386a9 (merge abeeebf) | re-review OK; +t_ui5_pass; "ends 28 Dec 2026"; pass_summary "Shards"; claim sau mùa giữ hành vi (hỏi Liam) |
| S12 Profile | d1da132 (merge 8b11795) | re-review OK; +t_ui5_profile; Pure chỉ trận thắng (theo dữ liệu); giữ câu phụ Titles + đếm Default chờ Liam |
| (suite int @ 8b11795) | | 308/308 + skip t_rules_version |
| S11a Daily | 24f0c4b (merge 4445bbf) | re-review OK; +t_ui5_daily; GemClaim cụm icon+chữ |
| R2a Core offer + bỏ chọn sẵn | 030085d (merge ebb3455) | review (a) + re-review UI OK; +t_ui5_core_offer (205); TierLadder pip, CoreName trái, AwakenChip |
| .uid bù | 4d03e4f | commit .uid các làn bỏ sót |
| (suite int @ ebb3455) | | 308/310: đỏ t_anchor_flow_start (đếm RewardCard, R2a đổi tên CoreCard) + t_ui5_make_room (Take không chọn) → sửa test 4333f06 |
| S8b NetNotice + Update | 1139e9a (merge aa8215d) | review OK + sửa nhỏ; +t_ui5_system |
| (suite int @ aa8215d) | | 311/311 + skip t_rules_version |
| R5b Event + Treasure | ca735ab (merge c9e0075) | re-review OK; +t_ui5_event_treasure |
| R2b Rule card + reward/treasure text | 95f922d (merge 8deaa5d) | review OK + mục nhẹ; +t_ui5_rule_offer (440); RewardCard text_box; xung đột t_anchor_flow_start gộp tay (đếm Reward/Rule/CoreCard) |
| (suite int @ 8deaa5d) | | 313/313 + skip t_rules_version |
| S7b Raid | df7b58c (merge cf515fc) | re-review OK; +t_ui5_raid |
| S11b Store | 99a2203 (merge 990ecbe) | review OK; +t_ui5_store; USD buy tắt |
| S2 Edit Land + Upgrade | 794bea5 (merge e7eeca9) | re-review OK + nút Craft rộng theo cụm; +t_ui5_land_edit (1730) |
| S13 Codex + Guides/Unlocks header | 5ef1bc0 (merge cbb1fc5) | re-review OK; +t_ui5_codex (1044); search theo plain_lines; bảng padding; InfoPanel đã xem |
| (suite int @ cbb1fc5) | | 316/317: đỏ t_cosmetics_equip (tìm CosGrid/Cos_* — S11b đổi tên) → sửa test e10e6ad, xanh lẻ |
| S4a Team presets | 1524503 (merge 01e3c70) | review OK; +t_ui5_presets |
| S8a1 Account | 46dab89 (merge 7b3e2da) | re-review OK (lead-programmer); +t_ui5_account |
| S1b Land overlays | 41ca651 (merge 93d53b4) | re-review OK; +t_ui5_land_overlays; RunRow nâng lên trên LinksPlate khi hết chỗ ở 1280 (lệch frame, chấp nhận) |
| (suite int @ 93d53b4) | | 320/320 + skip t_rules_version |
| S8a2 Account gate | b489821 (merge c5c34c5) | review OK; +t_ui5_account_gate |
| S4b Tutorial | da416f5 (merge 221f47c) | re-review OK + người tích hợp sửa replay-end Skip (+test view, đã thử đỏ khi bỏ sửa); +t_ui5_tutorial |
| (suite int @ 221f47c) | | 322/322 + skip t_rules_version |
| S3a1 Run setup layout | 57d0b6b (merge 2cf768e) | re-review OK; focus NormalToggle; +t_ui5_run_setup |
| S3b Run setup picker | ad241bb (merge c02ef8c) | re-review OK; +t_ui5_run_picker |
| (suite int @ c02ef8c) | | 324/324 + skip t_rules_version |
| S9b Echo ceremony | 59a0923 (merge 3dd7f56) | re-review OK; +t_ui5_echo_ceremony; PROPOSAL_FX tắt |
| (suite int @ 3dd7f56) | | 325/325 + skip t_rules_version |
| S3a2 Run setup states | 0213e4a (merge f2f2cc2) | review OK; HudStyle `_real_style` dùng chung + test |
| (suite int @ f2f2cc2) | | 325/325 + skip t_rules_version |
| M2 run moments | 03b9a89 (merge 652bfcd) | re-review OK (lead-programmer); watchdog an toàn; reduce awaken/flash sửa; glyph đúng (ảnh đã xem); +t_ui5_moments_b2 |
| (suite int @ 652bfcd) | | 326/326 + skip t_rules_version |
| S9a Echo Box | 0a46e18 (merge 10c16ee) | re-review OK; chest không nhân scale 2 lần, `_fit_chest` chỉ khi Stage tràn, test canvas logical 1920; +t_ui5_echo |
| (suite int @ 10c16ee) | | 327/327 + skip t_rules_version |
| M3 meta moments | 41dbabe (merge 01645c2) | re-review OK; PROPOSAL tắt (`proposals_enabled` false); +t_ui5_moments_b3 |
| (suite int @ 01645c2) | | 327/328: đỏ t_vault (capture M3 không SaveGuard.restore) → sửa 5d2c003, t_vault xanh |
| Q1 test host 1920 logical | 6c8c0f9 (merge dedd7a6) | review OK |
| (suite int @ dedd7a6) | | 328/328 + skip t_rules_version |
| F2 combat QA | 7535222 (merge 60bb980) | review OK; GachaFx skip banner = click; End turn tắt không keycap. Khối cam = band Your turn trượt ra (không lỗi) |
| Q2 QA flow driver | d84d078 (merge 501f225) | driver đi hết run 1920/1280/reduce; RunVerifier ok; chờ band rồi chụp |
| F1 QA fixes | b38ee05 (merge 2173440) | re-review OK; Daily moment chờ layout, Echo reveal giữ thumb rồi drop (spec UI-03), TabBar focus, Missions N6, Series 1 dòng |
| (suite int @ 2173440) | | 326/328: đỏ t_combat_labels + t_combat_right_block — F2 ẩn keycap End turn tắt TRÁI frame round-1 (02-combat--enemy-turn vẽ keycap Space disabled: Space tua FX địch) → revert cd4e4b3, 4 test xanh |
| release_gate --suite @ cd4e4b3 | | 329/329 (AXIE_RELEASE=1, không skip, có t_rules_version) + Worker 395/395 |
| Q2 ảnh + QA report | b3d7483, 456eb0b (merge 3c6f90a, 50a03ce) | chỉ production/ (không đổi godot/) |
| Tutorial reward bấm thẻ là nhận | 02aaca5 | S4b đã thêm Take trái quyết định Liam (plan dòng 5, câu hỏi 2 = a) → sửa lại; review OK (cùng revert cd4e4b3); +test Space/Enter (3cf4d3e) |
| **release_gate --suite @ 3cf4d3e (bản sẽ deploy)** | | **329/329 (AXIE_RELEASE=1, không skip) + Worker 395/395** |

## Đã review, chờ gộp
(trống)

## Đang làm / chờ review
- QA xong: REPORT + REVIEW-*.md ở `production/qa/ui05-b23/qa/`; soak 2856 run 0 xấu; flow UI 3 cấu hình RunVerifier ok
- Worktree u5b-s9a GIỮ LẠI (thư mục rác `godot/production/` — agent bị chặn rm, chờ Liam)
- S7a Leaderboard @ 84664ef: review yêu cầu sửa (tên PinnedRow sai nguồn, PinnedRow ở today/empty, cột lệch khi scroll); đang sửa
- S7a: c51f1f8 WIP chưa test; tiến trình t_ui5_lb treo (pid 97938/98445) giữ khoá — agent bị chặn kill, chờ Liam

## Việc chéo làn (giao khi tới làn đó)
- Backlog nhỏ sau deploy (từ REVIEW-*.md, không chặn): tên quái bị cắt ở 1280; tutorial coach che nút bước 7 + thẻ SET viền vàng bước 4; toast offline 1280 xuống 3 dòng đè đảo; chữ update bar/netnotice/raid nghi < 14 px (đo bằng test); capture `room` dựng sai state; 3 ảnh Result trống (chụp sớm). Đã xác nhận ĐÚNG frame: keycap Space trên End turn lúc lượt địch; Victory rays (đợt 1, không PROPOSAL).
- QA: 4 test dựng host `1920×1080*sc` (sai quy ước canvas logical 1920): `t_ui5_presets`, `t_ui5_missions`, `t_ui5_raid`, `t_ui5_run_picker`. Sửa về 1920×1080 và xem màn tương ứng có tự co/ẩn thứ gì cho vừa 1280×720 logical không (như S9a `_fit_chest`).
- QA luồng thật: Echo reveal Mythic có art xúc xắc (ảnh M3 chụp lúc art chưa nạp); banner Land tier-up 300 ms đầu có hở dải trên không (banner_rise dịch cả modal); kiểm skip core-reveal (moment dừng theo), xem treasure-open + level-up bằng mắt (M2 chưa có ảnh).
- Comment `RunSetup.gd:~568` "Try again becomes the primary" → giao S3a2 sửa.
- **S3a chia đôi (cùng RunSetup.gd, nối tiếp):** S3a1 = layout + kiểu run (stage1, stage3, a5, full-locked, newcomer, daily, ranked, components-land--setup); S3a2 = state (guest, offline-live/local, party-short, blocked, loading, open-run, start-error, starting, closing). Rồi S3b.
- **M2 (moment anchor-awaken, AnchorFx.gd):** AwakenStrip thành pill plate cao 48 + 2 chấm 16 px; hint "Click to continue" ở góc phải dưới (24/24); đĩa vàng 56 sau glyph awaken; màu tile #3b2416 + viền house; test kiểm AwakenGlyph/Strip/Hint; letter-spacing .cap-label (FontVariation).
- **S10 Pass:** `godot/scenes/pass/pass_summary.gd:43` "Lv 1 pays 300 Shard" → "Shards" (hiện trên thẻ Pass của Result); `PassView.gd:238` `"%d Shard"` + test ghim chữ cũ (`t_pass_remote_claims.gd:111` "+50 Shard"); thêm assert chuỗi này trong `t_ui5_result`; FIXES-30-10 mục 7: dòng Pass trên Result đúng data (Lv 5 "Leaf Tumble + 300 Shards").
- **S2 Land upgrade:** `Ui5DetailPlate.setup(..., gap := 12)` cho `.detail`.
- **Mọi làn S dùng kit:** SaveCard/ListRow mặc định không chọn; đừng bật sẵn.
- **Gộp 0b:** `t_boss_intro` đọc nguyên văn `RunMapController.gd` (khối match `"boss"` / `"battle", "elite"`): phải còn trong controller.
- **Màn cũ đổi màu theo token B2** (QA chụp lại): CorePanel, `UI3.tier_chip`, chữ rarity trên run map, `UI3.update_bar`, `UI3.run_rule_chip`, Result (thẻ Core/Run Rule).

## Câu hỏi gom cho Liam
- QA Unlocks: mục "NO EFFECT YET" (Relic Pool II/III, Gene Pool II/III) vẫn bấm mua được bằng Shards — khoá nút hay ẩn mục?
- QA Gate "Choose a save": nút "Keep this device" tô cam (primary theo XP như code cũ) cho quyết định không đảo ngược — giữ hay để cả hai nút ngang nhau?
- QA Raid guest/offline: không có nút Sign in trên màn Raid (chỉ nút xám "Sign in to raid") — thêm SignInButton như Daily/Store?
- QA: Land upgrade — khung preview tier bên phải là khối màu phẳng (TierArt chưa có art, README ghi placeholder). Giữ?
- QA: Run setup — thẻ party 5 class đều nền xanh lá (art portrait mặc định?) — đúng frame?
- M3: Land tier up — Reduce flashing tắt luôn hit-stop/rung/flash dù bảng spec ghi "—" (chọn an toàn). Giữ?
- M3: Pass level-up chỉ phát khi màn Pass vẽ lại thấy level tăng trong cùng phiên (mở Pass lần đầu của phiên không phát).
- S8a2: màn Choose save (a15) không đặt focus ban đầu (đúng frame và code cũ — nút Keep ghi đè save kia nên không để Enter tự chọn). Tab/d-pad vẫn vào được. Muốn focus sẵn vào thẻ đầu (thẻ chỉ chuyển focus, không chọn) không?
- S8a2: nút "Play as guest" kiểu quiet (gạch chân) ở 1280 trông như dòng chữ thường — đúng HTML `btn-quiet`; giữ?
- S1b: ở 1280 offline, nhãn "Daily run · needs connection" + "Start run · needs connection" quá dài nên RunRow được nâng lên trên hàng Codex/Edit/Raid/Moon Card (frame để cùng một hàng). Giữ, hay rút ngắn nhãn offline để về một hàng?
- S7b Raid: khi chờ server (lưu defence, Fight) nút không tắt (để giữ focus) và chưa có dấu hiệu "đang chờ"; thêm InfoLine "Working…" không?
- S13: bảng Controls trong Codex liệt kê đủ phím (vd "Enter, Num Enter") vì là bảng tham khảo; muốn chỉ phím chính không?
- S8b: NetNotice làm mờ màn bên dưới nhưng không chặn chuột (giữ hành vi cũ "không khoá input"). Muốn khoá input khi notice hiện không?
- S8b: frame NetNotice dùng ToneDisc căn trên (`flex-start`), code căn giữa theo luật chữ cạnh icon (29/10) — báo design sửa HTML.
- S12: câu phụ tab Titles "Titles from Ascension goals. One title at a time." — giờ có cả title Land; đổi thành "Titles from Ascension goals and Land milestones. One title at a time."?
- S12: số đếm tab cosmetic có tính ô Default không (code "2 of 27", HTML "2 of 26")?
- S12: HTML vẽ chip Pure cho dòng Mission Won, nhưng stat Pure wins loại mission — đang theo dữ liệu (không Pure cho mission).
- S7a: Today — guest/newcomer vẫn thấy PinnedRow ("Sign in to appear here") dù frame Today không vẽ; giữ?
- S10: ở 1280 tile Pass hẹp nên "Reach Level N" bị cắt "Reach Lev…" (mất số; tooltip có đủ). Đổi chữ ngắn hơn (vd "Lv N") không?
- S10: frame `21-pass--over`/`offline` vẽ Claim all tắt, nhưng game vẫn cho nhận level đã đạt sau mùa/offline (giữ hành vi, không đổi luật ở làn UI). Anh muốn khoá claim sau mùa không?
- R3: ở 1280 khoảng cách trong card Anchor 12 → 8 (logical) để Big Hand không vượt `anchor_card_h` khi chữ bị nâng lên sàn 14 px; HTML 1280 giữ 12.
- S1a: tooltip toà nhà trên Land vẫn ghi phím trong Title ("Echo Box · 4") theo luật "phím khác chỉ ghi trong tooltip"; frame chỉ có tên.
- R6: frame HTML không vẽ Pact trong panel "Cores owned". Đang hiện Pact theo kiểu hàng OwnedRule (tên trái, "Pact" phải, điều khoản phạt dưới) để không mất thông tin. Anh muốn hình khác thì báo.
- Slider Settings: theo HTML không có núm (đang làm vậy, vùng bấm vô hình ≥ hit_min). Có muốn núm không?

## Backlog nhỏ phát hiện trong đợt
- `t_ui5_anchor_pick.gd:47-48,65,98` và `t_ui5_core_offer.gd:246`: kiểm đáy với khung `*sc` lẫn đơn vị logical/real (hơi chặt hơn ở 1280, không sai).
- UI3Theme chỉ định nghĩa normal/hover/pressed/disabled/focus cho variation nút → `hover_pressed` của nút chưa vào cây có thể ra style xám (từ trước).
- Combat: dưới curtain/coach tutorial (Welcome) nút End turn vẫn hiện keycap Space; README round-3 nói keycap mất khi curtain giữ focus. Sửa ở HUD combat (keycap ẩn khi có `ui3_modal`).
- Codex: bảng BBCode chưa kéo full bề ngang reading plate (`.tbl` full).
- `t_runloop_ui` có 6 dòng "Lambda capture ... freed" + 1 `grab_focus !is_inside_tree` ở đầu test, có từ trước R5b (đo trên ebb3455). Tìm nguồn khi dọn.
- Daily: claim Daily đường remote không có cờ pending (bấm đúp có thể gửi 2 request) — có từ trước UI-05.
- `GachaFx.banner()` không còn dùng ở production sau R4 (chỉ `t_anchor_mutation`); `_input` rẽ theo `name == "ComboBanner"`. Dọn khi tiện.
- Keycap Space trên nút (Leave shop, RunPlate…) chỉ đúng khi focus ở nút đó; focus ở nút khác thì Space bấm nút kia. Cân nhắc phím tắt toàn cục cho nút có cap (sau khi R2 xong RunMapController).
- Người tích hợp (sau khi gộp S1b): chuyển `LandPlates.attach_space_cap` (land/ui5) lên `shared/ui5` (HudStyle/Keycap) và cho Land, Shop (R5a) gọi bản shared. KHÔNG để file trên đường autoload (AccountUI) preload file của làn Land.
- `HudStyle._set_side_margins`/`reserve_trailing` nhân bản `b.get_theme_stylebox(st)` — nếu nút chưa nhận theme thì lấy nhầm style mặc định (nút mất nền). Sửa gốc: đọc từ `UI3Theme.get_theme().get_stylebox(st, b.theme_type_variation)` khi chưa có override. S1a đang workaround bằng pin style trong LandPlates.
- Land: chuỗi focus (`Land.gd:~1076`) chưa gồm ProfileButton, LandPlate, Codex/Edit/Raid; frame nói RunPlate luôn có focus — QA kiểm điều hướng bàn phím trên Land.
- QA Settings: khi cuộn bằng bánh xe tới mục khác, IndexRow "Audio" vẫn giữ viền focus cạnh viền mục đang chọn (ảnh chụp cuộn bằng code). Kiểm bằng tay.
- QA resize 1920→1280 khi đang mở Result và menu trong run: stylebox override ghi số theo scale lúc dựng (ResultView plate/keycap, RunPauseMenu Resume) có thể giữ scale cũ.
- `CombatView.gd:919`: menu trong combat ghi "Fight 1 of 18" ở header nhưng panel ghi "Floor 2 of 18" (`node.row + 1`), có từ trước.

## Bẫy đã gặp
- 1/11: S4b làm Take cho tutorial reward dù Liam đã chốt "bấm thẻ là nhận" (plan dòng 5). Brief làn S4b không nhắc quyết định này → review cũng không bắt. Khi viết brief, chép các quyết định của Liam liên quan vào brief.
- 31/10: luật b23 "không keycap trên nút tắt" KHÔNG áp cho End turn combat đợt 1 — frame round-1 vẽ keycap Space disabled lúc lượt địch (Space tua FX). Đối chiếu frame trước khi "sửa" theo luật chung.
- 31/10: `scratchpad/rt.sh` dùng chung bị M2 ghi đè (trỏ u5b-m2) → S9a chạy nhầm vài lượt (đã chạy lại bằng script riêng). Luật mới trong lane-run: script theo tên làn.
- 31/10: ổ đĩa đầy (còn 587 MB) lúc tạo worktree — mỗi worktree ~1,2 GB. Đã xoá 26 worktree làn đã gộp (nhánh còn). Sau mỗi lần gộp, xoá worktree của làn đó.
- Làn bỏ sót `.uid` của file mình (hiểu quá chặt lời dặn không add uid làn khác) → int 4d03e4f commit bù; lane-run.md đã ghi luật.
- Làn mới phải tách từ `int/ui5-b23` (R2, R3 tách từ 0b nên thiếu token B2/B3).
- Keycap trên nút: dùng `HudStyle.place_trailing` sau khi nút vào cây + nối `resized` (R6, S1a đều vấp khi tự đặt).
- Đừng bỏ focus ban đầu của màn vì frame không vẽ focus: mất đường vào cho bàn phím/gamepad (S14).
- Test lẻ phải có `AXIE_TEST_NO_NET=1` (run_tests.sh tự bật), thiếu thì `t_run_setup` đỏ giả.
- Agent con ~20 lượt: hay hết lượt trước khi commit. Brief phải dặn commit sau mỗi khối.
- `godot/tests/qa_ui5_stage_capture.gd.uid` untracked ở mọi worktree: không add.
