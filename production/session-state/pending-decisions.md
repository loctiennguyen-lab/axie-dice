# Câu hỏi và việc chờ Liam — bản gom (cập nhật 12/10/2026, tối)

Liam trả lời theo số, ví dụ "đồng ý hết, trừ 4: …". Mỗi câu có khuyến nghị. Các câu cũ đã trả lời đều đã ghi vào file
nguồn, không nằm ở đây nữa.

## A–C. Đã trả lời 12/10 (tối)
1 có đăng nhập desktop · 2 Gem trên server · 3 cắt ngay #2 VIP thử, #3 hộp mùa, #4 Nhiệm vụ N1–N3 không nâng nhà, #10 boss → mascot; mục khác phải hỏi · 4–6 duyệt · 7 ~8 giờ/ngày · 8 "Axie Dice" ·
9 `fun.axiedice.game` · 10 0.1.0 · 11 Slack + form, người nhận Liam. Ghi ở đầu `production/l1-sprint-plan.md`.

## D. Việc anh cần tự làm (agent không làm được)

| Hạn | Việc |
|---|---|
| Ngay | Gửi Claude Design: **prompt menu/meta (Round 3)** — em đang viết, sẽ đưa link; và ghi chú cosmetics lượt 2 `design/handoffs/cosmetics-01/NOTE-TO-CLAUDE-DESIGN-02.md` nếu chưa gửi |
| Khi làn S sẵn sàng | Deploy Worker (gói Free) theo lệnh em đưa — em vẫn hỏi trước khi deploy |
| 20/10 | Hạn Claude Design giao Round 2 (run flow + Ascension) |
| 22/10 | **Asset boss Atia**: game có 6 boss; làn C đang kiểm 235 model Atia có đủ không, thiếu bao nhiêu sẽ báo |
| 24/10 | Hạn Claude Design giao Round 3 (menu/meta) |
| Khi rảnh | Chạy thử bản Windows trên một máy Windows (bản build đầu ở `~/my-game-wt/R/build/`) |

## E. Đã chốt hôm nay (để tham chiếu, không cần trả lời)
Kiến trúc server RNG · monetization (cách B, PA-1, quà 180 Gem) · Ascension răng cưa · Nhiệm vụ bản cực khó (Bayes, không giới
hạn/ngày, NFT dùng được) · UI request 02 + Round 1 · L1 = 3/11 nội bộ, phạm vi đầy đủ, Gem tặng 300/ngày · commit/push tự do, duyệt theo tuần.

## F. Liam trả lời đêm 12/10 (đã chốt, không hỏi lại)
- Việc thêm trong đêm (sau danh sách đã duyệt): Nhiệm vụ bản cực khó (doc + review), sim chốt số monetization + enrage Ascension, build thử Mac/Win (không deploy/upload), các màn meta R3 còn lại (Vault, Codex, Settings, Profile/Account, Leaderboard, Land upgrade).
- R3 Q1: Gem tặng (quà mùa, Pass) MUA ĐƯỢC hàng giá Gem ở L1, như khung M7e–M7h.
- R3 Q6/Q7: nhận cả hai — M1 party lên trên; header 64 trên panel meta rộng thành quy tắc style sheet.
- R3 Q3/Q4: giữ 3 việc tuần Pass (5 run, thắng 2, chạm boss 1; 500 XP/việc; tuần từ thứ Hai UTC). game-designer đề xuất tên A5/A10 + số Nhiệm vụ, ghi ở đây để Liam duyệt sáng; code dùng tạm.
- (Đã chốt trước: R3 Q2 [INF] nhận; Q8 gamepad bỏ.)

## G. Ghi chú đêm 12/10 (agent chọn tạm, Liam xem)
- Việc tuần Pass (lane E): doc echobox-pass-v2 không nói XP việc tuần có tính vào trần XP run/ngày không. Chọn tạm: 500 XP/việc KHÔNG bị trần ngày (như thưởng ngày +100), nhưng hết mùa thì không nhận.
- Việc tuần chưa nhận khi qua tuần: chọn tạm là MẤT (chỉ nhận được việc của tuần hiện tại, tới hết Chủ nhật UTC; hết mùa cũng không nhận). An toàn về XP; nếu muốn nhận bù tuần cũ tới hết mùa thì bỏ check `week_over` trong PassV2.claim_weekly.
- (Lane I, đêm 12/10) R3 Q5 "Fog vs A9": luật A9 là một hàng elite bắt buộc, không phải elite ẩn. Tạm cho bản đồ ghi "Elite row ahead" (không đếm số, không lộ vị trí). Anh chọn: giữ dòng này / hiện hàng đó không sương mù / bỏ hẳn.
- (Lane I) Giá Aid trong CombatView (15/60/90/180, trần A9 = 4) đang viết cứng, nút mua chưa trừ Gem — chờ catalog Aid của làn E/S. Không chặn playtest nội bộ.

- (Lane B, 12/10) Eternal sticker: docs do not say which relics get it. Chose the first `eternal_max` (2 from A5) non-pact relics granted in the run, deterministic by grant order (no RNG, replay-safe). Sticker cleared when sold via swap. Liam to confirm vs random pick.
- (Lane B, 12/10) G axis: ascend/forge no longer bake into damage faces; they add 0.25/0.30 to G_axie (cap 2.5, tuning g_cap). Non-damage faces: compounding oc capped x2.0. ancientgene no longer multiplies at build time (pipeline G). A:poison/burn apply to enemy ticks only (as the old poisonTicks/burnMult did); hearthcore/solarcore/venomengine/mirrorshell/apexpredator old legacy fields removed from .tres.
- (Lane B, 12/10) Reroll caps: a_chaos 6/turn via chaos_reroll_given; relic sources go through CombatEngine.grant_relic_reroll (cap 4) but cullingorder/apexpredator/alphafang/tidecaller bodies do not grant Reroll yet (hidden, need FIELD hook).
- (Lane B, 12/10) Forced pact: only RelicSlots.pact_forced(asc, boss_index) exists. The pact screen / pact_pick flow is not in RunState yet (lane A/U) and must call it for "no skip".
- (game-designer, 12/10 đêm) Nhiệm vụ bản cực khó, `design/proposals/nhiem-vu-risk-to-earn.md`, chờ anh duyệt. Anh trả lời: **G1** RTP toàn dân ~0,70–0,75 (dưới đích 0,75): chấp nhận, hay hạ độ khó N1–N2? **G2** Trần payout 20.000 kẹp N6 ở m = 8 (heavy nhận lại 0,41): giữ N6 là bậc danh hiệu, hay nâng trần lên ~42.000? **G3** Bỏ giới hạn "tối đa 2 luật thêm", N6 có 5 luật: duyệt? **G4** Duyệt 2 luật mới M6 Quân dày / M7 Elite hung (sửa `mission_mods` + engine + bump RULES_VERSION). **G5** Ngưỡng telemetry nới (WAU 12%, bỏ sau 1 lần 60%, RTP đáy 0,70) và chọn tên danh hiệu A5 (Người Giữ Ấn / Kẻ Mang Của Vĩnh Cửu / Bàn Tay Không Buông) và A10 (Người Đứng Cuối / Kẻ Gánh Mọi Giao Kèo / Chủ Của Ván Cuối). **G6** Giữ hay bỏ điều kiện phụ (Một nhà, Đa sắc) ở bản cực khó. Chưa có gì chạy sim: mọi tỉ lệ thắng là tính tay.
- (Lane I) Eternal: relic khởi đầu (u_start) cũng chiếm ô Eternal (2 relic đầu từ A5, theo thứ tự nhận). Anh xác nhận có tính relic khởi đầu không; muốn loại thì đổi một dòng ở RunState.gd (~1184).
- (Lane I) Land hub: ~72 MB texture nguồn HomeLand (homeland/src, gồm atlas đất 4096/5000 px) đã commit nguyên bản; bản build giới hạn kích thước khi import (size_limit 2048/1024). Anh có muốn thu nhỏ hẳn file nguồn (giảm ~50 MB repo) không? Agent bị chặn khi định ghi đè file PNG, nên không tự làm.
- (Lane S, 12/10, agent chọn, anh xác nhận) Season gift gate server: mốc 1 cần 3 run đã đóng trong cửa sổ mùa, mốc 2 cần 8 (và phải có mốc 1); "run đã đóng" = runs.state=closed + battles_done>=1 (chưa có verifier, nên là lời khai client có qua chain); ân hạn 7 ngày sau end; quà mùa chia chung trần số dư 900 với quà ngày (cắt theo chỗ còn trống); mùa S1 = 2026-11-03..2026-12-29 UTC. Giá trị ở worker/src/aid_prices.js (SEASONS, SEASON_GATES).
- [M/I, 12/10] Guest/offline never block play while local: Echo Box (flag axie/gem_wallet=="remote", no helper exists yet) and Run Setup (axie/epoch_source=="remote", stands in for RemoteEpochSource.flag_on(), class not in tree yet) only show an info banner; block pulls/Begin only when the flag is on. State comes from AccountService.status (OFFLINE, GUEST/EXPIRED); lane S should point both `remote_on` vars at the real flag helpers.
- Lane B (12/10): tidecaller "Reroll vượt max tới +2": CONDUIT rerolls hiện không bị chặn bởi max nên không thêm code. alphafang kill hoàn Reroll dùng grant_relic_reroll (1/lượt). shedskin "không có Shield" = không có Shield trước đòn (had_shield). venomlineage "lần Poison đầu mỗi lượt" tính theo từng Axie Bug. Dự kiến (stash, chưa commit): breakersward kích cả khi đòn thường phá Shield + shatter (pierce không chạm Shield); sporegale tính mọi mục tiêu AoE là phụ và lan Poison mỗi tick (không dùng field poisonSpread); firestormveil +1 thêm nếu đã Burn.
- [B, 12/10] breakersward: spec says 'Pierce phá Shield' but a Pierce hit never touches Shield in the engine (breakers are talonedge / a_pinning). Implemented as 'any party attack that removes enemy Shield pays out' (fires from DamagePipeline step 8 and the a_pinning active), not only shatter. Confirm or narrow.
- [S, 12/10] Run token revocation: only the newest jti (minted at create and every /api/run/open) passes hello; legacy tokens without jti are refused; hello fails closed if D1 errors. "Session alive" is NOT checked against sessions (token not bound to a session); logout does not revoke the run token. Lock = players.locked_at (migration 0005). shop_roll also consumed by shop_done, event_choice by event_done, reward_reroll by take_reward. Confirm or ask for session binding.
- [E, 12/10] Hộp mùa: open_season làm theo §2.8 (5 vé/lượt, 8 lượt/ngày, N 10/20/40, Vault x2). Giữ enabled=false (UI lane M bật). Dup hộp mùa trả vé thẳng (2/4/8), không qua mảnh. 'Xác nhận lượt đầu' là việc UI. Danh hiệu/mốc cấp vào cosmetics_owned. Chờ Liam duyệt.
- (Lane I, 13/10) Newcomer: client tính "người mới" = MetaState.runs < 5 (run đã kết thúc); Worker tính runs có battles_done ≥ 1; monetization-v1 §1.6 nói "run đã tạo" (kể cả bỏ dở). Anh chốt một định nghĩa. Từ -i, run người mới local được giảm độ khó đúng thiết kế (không attrition, không đồng hồ nhẹ, ẩn Aid) — trước đó vô tình không bao giờ bật.

## H. Liam trả lời sáng 13/10 (đã chốt, không hỏi lại)
1. RTP Nhiệm vụ ~0,70–0,75: CHẤP NHẬN (A) — game phải khó, người chơi phải khó chịu. Không hạ N1–N2.
2. Trần payout 20.000 giữ; N6 là bậc danh hiệu (A).
3. Bỏ giới hạn "tối đa 2 luật thêm" (N6 có 5 luật): ĐỒNG Ý.
4. Luật mới M6 (quái thường HP ×1,20) + M7 (elite dmg ×1,25): ĐỒNG Ý → sửa mission_mods + engine + bump RULES_VERSION.
5. Giữ điều kiện phụ (Một nhà, Đa sắc).
6. Bỏ cuộc thì KHÔNG nhận R (Shard của run).
7. Danh hiệu A5 = "Người Giữ Ấn", A10 = "Người Đứng Cuối".
8. Eternal KHÔNG tính relic khởi đầu.
9. breakersward giữ như đã làm (mọi đòn phá Shield + shatter).
10. A9 giữ dòng "Elite row ahead".
11. Người mới = dưới 5 run đã có ít nhất 1 trận (giống Worker).
12. Việc tuần: 500 XP ngoài trần ngày; việc chưa nhận mất khi qua tuần. Đồng ý cả hai.
13. Quà mùa: mốc 1 = 3 run, mốc 2 = 8 run, ân hạn 7 ngày: đồng ý.
14. Ràng token với session: để sau L1 (không ảnh hưởng L1 vì cờ remote đang local).
15. Hộp mùa: món trùng trả vé 2/4/8: đồng ý.
16. KHÔNG thu nhỏ texture nguồn Land (Liam chưa xem Land thế nào; giữ nguyên chất lượng).
- (Lane I, 13/10) M7 "elite dmg ×1,25" đang nhân MỌI mặt xúc xắc elite (cả Shield/hồi máu/buff), giống luật enemy_dmg sẵn có. Nếu anh muốn chỉ mặt sát thương thì báo, sửa nhỏ.
- (Lane I, 13/10) TRƯỚC khi bật online: Worker chỉ nhận RULES_VERSION `godot-2026-09-21-a` (run_do.js SUPPORTED_RULES). Phải thêm bản hiện tại (hoặc đặt biến môi trường SUPPORTED_RULES) khi bật cờ remote, nếu không mọi run bị từ chối.

## I. Liam trả lời trưa 13/10 (đã chốt)
- Boss Atia thiếu asset → dùng mascot có sẵn.
- Người test dùng Apple Silicon + Windows: làm 2 bản tải (mac arm64/universal + win).
- Báo lỗi: một Google Sheet (Liam làm).
- Nhiệm vụ L1: VẪN CẮT, chỉ N1–N3 (bản cực khó N1–N6 là thiết kế đầy đủ, mở dần sau L1).
- L1 làm cả web và desktop.
- Checklist L1: `production/l1-checklist.md`.

## J. Liam trả lời chiều 13/10 (Land hub v4)
- Leaderboard = một công trình trên Land kiểu bảng thông báo. Lane I chọn asset HomeLand `SM_Billboard_Big` (tấm biển gỗ chim kéo), đặt ở ô Mastery Hall cũ, phím B. Dự phòng: cột cờ ConsumableStall.
- Unlocks nằm trong Profile.
- Mastery Hall: chưa làm ở bản này (bỏ khỏi Land, dock, phím).
- (Liam 13/10) Save cũ v1 (trước kinh tế v2): GIỮ THIẾT KẾ — reset toàn bộ Shard, unlock, perk, XP, Pass khi chuyển; giữ runs/wins/best/asc_max/settings; có bản .bak.

## K. Liam trả lời chiều 13/10
- C1 màn pact sau boss: LÀM CHO L1 (A).
- Land v5: đồng ý khoá Nhiệm vụ + Leaderboard cho người mới (5 run đầu); phím xem tên nhà dùng N thay Alt.
- Cosmetics v7: nhập 20 plate + 21 khung tĩnh vào game; còn thiếu (lane I đã kiểm): 13 file lớp animation `anim/*.png` không có trong zip (chỉ 7 `_anim.png` gộp, ảnh tĩnh), khung Common ở 40 px gần như giống nhau → danh sách sửa ở REVIEW-cosmetics-v7.md.
- (Liam 13/10) Cosmetics phải dùng được trong game ở L1 (trang bị + hiện trong trận/Profile + pool Echo Box/Store thật) — checklist B12.

## B12 cosmetics pool (13/10, lane M)
- Echo Box normal pool keeps 223 placeholder ids (61/55/47/28/20/12) so odds, no-repeat and dup-fragment economy are unchanged. `boxes.normal.art_map` in echobox.json maps std_<r>_NNN -> real art ((NNN-1) mod list length), so one skin/frame shows under many ids (Common 9 art, Uncommon 5, Rare 10, Epic 4, Legendary 4, Mythic 4). Shrinking the pool to real art would push dup rate up and break the ticket-return cap (INV-V3), so I did not. Liam: ok, or want a real 223-item pool later?
- Pass-exclusive art (Moss die, Vine frame, S1 Founder die/frame, Sovereign frame) is left out of the normal pool; Season-box items (rune, spore, runering, firefly, relic_stone, sunburst, eclipse, moon) ARE in it, since Epic would otherwise have no art. Season exclusivity is not kept while the season box is disabled.
- (Liam 13/10) Vạch tiền tuyến (FrontLine, spec CB-06 cũ) trong combat: BỎ HẲN.
- (Liam 14/10, đã chốt) Danh hiệu: thắng ở A≥5 nhận danh hiệu A5, thắng ở A10 nhận cả hai (C7 làm đúng vậy). Tên tiếng Anh: giữ tiếng Việt tới khi làm xong hết, Liam sẽ tự đổi sang tiếng Anh sau (`ascension_titles.json` → `en`).
- (Liam 14/10, đã chốt) Run Nhiệm vụ thắng ở A≥5 nhưng trượt điều kiện phụ → tính thua → KHÔNG nhận danh hiệu. Đúng.
- (Liam 14/10, đã chốt) Thẻ Weekly: giữ "(n/4)", "Paid this week" và toast (phần thêm ngoài mockup R3).
- (Liam 14/10, đã chốt) C2 Daily/Ranked cho L1: Daily = seed riêng mỗi người (server tung như run thường, chỉ khác thưởng);
  3 lượt/ngày UTC, run bỏ dở vẫn tính 1 lượt; thưởng Daily (60 Shard + 500 Stone + 100 Pass XP sau 1 run xong) là QUÀ RIÊNG,
  cộng thêm ngoài quà daily cũ. Ranked: MỞ ĐỦ + leaderboard trong L1 (Worker: bảng điểm + nộp/đọc điểm, bỏ chặn ALLOW_GATED_MODES
  cho ranked, khoá newcomer, cấm Axie import).
- (Liam 14/10, đã chốt) B11: R4 (dời đồng hồ) giữ "Coming soon" tới khi chốt ví chung (LIAM-2). R5 (đổi pact): đổi 1 thẻ,
  nút Swap dưới mỗi thẻ, thẻ mới cùng pool, khác 2 thẻ còn lại và thẻ bị thay, cùng nhóm drawback nếu pool đủ, seed tất định.
- (Liam 14/10, đã chốt) C6: Team presets 3/6/9 ô theo tier Land như mockup. Leaderboard L1 chỉ hiện bảng Worker có: Season + Today, lọc A0–A10; ẩn Week và lọc Pure/All/Nhiệm vụ.
- (Liam 14/10, đã chốt) Land upgrade MỞ trong L1 (khác README R3 M15a "Not in this build"): `land_tiers.json` upgrade_enabled = true.
- (Liam 14/10, đã chốt) C9 polish: làm cả 5 việc trong L1 (màu đất/trời + sương + khung cây sân mystic/genesis, tier 6 màu + trăng, đá lối đi mystic, lối đi + cỏ bụi genesis, mảnh vách/địa hình Land tier 4–5).
- (Liam 14/10, đã chốt) Giá nâng Land L1: GIỮ GIÁ GỐC (tổng 1,82 triệu Stone). economy-designer ước: ít chơi tới tier 2 ~ngày 16, tier 3 cuối mùa; nhiều chơi tier 3 ~ngày 25; tier 4–6 gần như không ai tới trong 8 tuần.
- (Liam 15/10, đã chốt) Bật online (B1): L1 BẮT ĐĂNG NHẬP mới chơi (run thường, Daily, Ranked, Nhiệm vụ). Khách thấy 'Sign in to play' + nút đăng nhập. Tutorial vẫn chơi không cần đăng nhập. Không làm tài khoản khách trên Worker cho L1.
- (Liam 15/10) Sau khi chơi bản Mac online đầu tiên: UI còn RẤT xấu, phase Polish phải làm lại cực nhiều. Trước khi lên plan Polish: xin Liam danh sách màn xấu + art-director/ux-designer audit bản build thật.
- (Liam 16/10, đã chốt) L1 Nhiệm vụ online: làm phương án A (server giữ ký quỹ Shard + trả thưởng khi đóng run), đẩy nhanh, mục tiêu 1 buổi.
- (Liam 16/10) L2 test bản b595: sáng 17/10. L3 đăng nhập Windows: ok. L4 (Google Sheet / danh sách mời / thông báo): bỏ qua. L5 cosmetics lượt 2: làm cùng đợt Polish.
- (Liam 16/10) L6 hình: mọi màn đều xấu (Polish). Việc làm ngay: (1) bỏ thanh gạch ngang ở giữa màn trận (chưa bỏ); (2) xoay cổng (gate) trong màn chơi 90°; Axie chạy XUYÊN qua cổng khi qua màn, không chạy tới giữa rồi hiện popup; (3) quái/boss có animation nhưng đang đơ hoàn toàn → phải chuyển động; thiếu animation thì dùng Blender tự làm.
- (Liam 16/10) L7 cắt dung lượng: CHỈ bản web. Bản desktop giữ nguyên chất lượng hoàn toàn.
- (Liam 16/10, đã chốt) Polish: mọi màn đều xấu, UI thừa, trông như AI làm → LÀM LẠI TOÀN BỘ UI TỪ ĐẦU, không vá theo polish plan v2. Claude Design được vẽ lại và vẽ thêm. Main Menu bỏ hẳn, Land hub thay. Cỡ chữ / nền màn meta: chờ bản mockup mới. Việc trước mắt: viết prompt cho Claude Design (`design/handoffs/ui-03-redesign/PROMPT-CLAUDE-DESIGN.md`), mockup phải dễ code trên Godot.
- (Liam 16/10, đã chốt) UI-03 dùng **Terrariums design system** (Liam đang làm với Claude Design), thay Dango. Vòng A = 3 cách áp Terrariums (bố cục/mật độ/HUD), không phải 3 phong cách khác nhau. Khi triển khai: thay `DangoTheme.gd` bằng theme sinh từ tokens Terrariums.
- (Liam 18/10, đã chốt) UI-03 round 1 (A4 Blend): tải font Rowdies Bold + Work Sans Regular (OFL) từ Google Fonts; LÀM LUÔN xúc xắc 3D tung bằng vật lý (RigidBody3D) trong đợt port Combat; GIỮ bắt đăng nhập (bỏ ý 'offline vẫn chơi Normal' của mockup); port CẢ 25 màn, chạy song song nhiều làn.
- (Liam 18/10, đã chốt) Reward UI-03: GIỮ KHÔNG có Skip (luật 21/9), dù mockup có Skip. Cờ `_REWARD_ALLOW_SKIP := false` trong RunMapController.gd.
