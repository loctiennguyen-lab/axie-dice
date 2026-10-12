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
