# Axie Dice — trạng thái hiện tại

Cập nhật: 2026-10-12. Nhánh `godot-port`, push lên `axiedice` (`git push axiedice godot-port:main`).

## ⇢ BẮT ĐẦU TỪ ĐÂY (cập nhật 18/10/2026)

**Đang làm: port UI-03 (Claude Design, A4 Blend trên Terrariums) vào game.** Kế hoạch làn: `production/ui3-port-plan.md`.
Bản giao round 1: `design/handoffs/ui-03-redesign/round-1/handoff/`. Màn chưa có mockup: `round-1/GAP-LIST.md`. Prompt round 2 đã
gửi Liam: `design/handoffs/ui-03-redesign/PROMPT-ROUND-2.md`. Quyết định Liam 18/10 ở cuối `pending-decisions.md`
(cả 25 màn, xúc xắc 3D vật lý làm luôn, giữ bắt đăng nhập, font Rowdies + Work Sans).

**Đã merge 18/10:** xúc xắc 3D (`DiceRoller3D.gd`, mô hình Blender `godot/assets/dice/axie_die.glb`, nguồn `tools/art/dice/axie_die.blend`)
và nền UI-03 (`godot/scenes/shared/ui3/UI3Theme.gd`, `UI3.gd`, `tokens_ui3.json`, font). Suite cây chính **104/104**.

**Đã merge lên axiedice/main (9263c52, suite 109/109 không SKIP):** nền UI3 + font, xúc xắc 3D Blender, 01 Land (r2), 03 run map,
06 run setup + 33/34/35 popup (đổi chỗ Axie), 07 reward (không Skip) + 31 reward types, 32 slots full, 08 shop, 09 event, 13 treasure,
12 pact (+ swap trả phí), 14 in-run menu (+ abandon_current_run dùng chung), 10 result, 02 combat (khay, nút, thẻ quái/boss + phase,
nhãn mục tiêu khớp engine), 30 defeat, 39 aid, 42 unit inspector, 16 boot r2 (bắt đăng nhập), 17/37/38 tutorial, 18 system, 36 toast theo mã,
26 settings (UI3Meta), UI3Meta + 27/44 presets, 28 land upgrade, 24 profile, 23 leaderboard, 40 missions, 41 daily, 20 echo box, 21 pass.
**Còn:** C = sửa bug save-quit trong trận (SettingsView.in_run kẹt), 4 điểm hình, 43 tooltips, 45 victory march; U = 25 vault (đã sửa preview),
nút chính Pass/Echo, 29 codex, AccountUI (welcome, chọn save). Sau đó: build + live smoke + viết lại `godot/CLAUDE.md` cho UI3 + bỏ Dango.
**Bẫy mới 18/10:** `t_rules_version` lấy dấu cả `autoload/` (làn chạy cờ skip nên không thấy); `git stash` dùng chung mọi worktree;
hai làn cùng thêm hàm vào UI3.gd = hàm trùng = treo; agent không được `pkill` theo tên chung.
Mỗi màn: review code + art-director xem ảnh 2 cỡ → merge đúng commit → --import → suite cây chính → push.

## (cũ 16/10) ⇢ BẮT ĐẦU TỪ ĐÂY (bàn giao 16/10/2026 03:10)

**Đọc `production/l1-plan-16-10.md`** (định nghĩa "xong", thứ tự việc, quy tắc chống treo + tiết kiệm token).
godot-port = axiedice/main. Suite cây chính **102/102**. Worker **184/184**, deploy **4055be9c** (16/10, migration 0007 đã áp),
RULES_VERSION `-n`. Live smoke PASS trên production với code mới nhất.
Bản Mac cho Liam test sáng 17/10 (L2): `build/AxieDice-0.1.0-L1-b615-bbfc8fb-macos.dmg` (ổ "Axie Dice L1" đang gắn).

**Xong sáng 16/10 (session sau bàn giao):**
1. Build Windows: `build/AxieDice-0.1.0-L1-b616-9574922-windows.zip` (9574922 chỉ thêm doc so với bbfc8fb). Bản Win cũ b556 đã ở `build/old/`.
2. Polish plan v2 (`production/polish/polish-plan-draft.md`, 4fe15e4): ux-designer review → art-director sửa (vạch freeze sau Batch 2,
   Reward/Shop/Event vào Batch 2, mỗi mục có cách kiểm, còn 3 câu hỏi). Chờ Liam duyệt.
3. Làn U 3 việc (a95d2dc, 6a631e6, c8d8d18) → lead-programmer review MERGE → merge c88c997, suite cây chính 102/102 không SKIP,
   push. Live smoke `--full` PASS trên production (R ở c88c997). Còn nhỏ: test _atia_play chưa kiểm die/RESET/không connect 2 lần.
   b615 KHÔNG có 3 sửa này (build sau sẽ có).
4. Web gọn đã export: `web/index.pck` 205 MB (từ a100cf6 = code bbfc8fb). CHƯA deploy R2.

**Chờ Liam:** L2 test b615 (chơi run thường + Nhiệm vụ N1 + tắt wifi giữa trận + thoát rồi Continue); L3 đăng nhập trên Windows;
duyệt kế hoạch Polish. Quyết định Liam 16/10 ở cuối `pending-decisions.md` (L1 A đã làm, L4 bỏ, L5 vào Polish, L6 đã làm, L7 web-only đã làm).

## (cũ) ⇢ BẮT ĐẦU TỪ ĐÂY (cập nhật 14/10/2026)

**godot-port = axiedice/main (4ed21e7).** Suite cây chính **96/96 không SKIP**, Worker **163/163**. RULES_VERSION **`godot-2026-10-13-m`**.
Checklist: `production/l1-checklist.md`. Quyết định Liam 14/10: cuối `pending-decisions.md`.

**Xong 14/10 (đều review + suite cây chính):** C (bỏ FrontLine), C7 danh hiệu, C8 thưởng tuần Daily, C4 test, C5 polish Land v5,
C2 Daily + Ranked + leaderboard (Worker migration 0006), B11 R5 đổi thẻ pact (-m; R4 chờ ví chung LIAM-2), C6 Team presets + Leaderboard + Land upgrade (mở L1, giá gốc), C9 polish (cả 5 việc + MultiMesh lối đi).

**CHỜ LIAM DEPLOY Worker** (C2 + B11): `git pull axiedice main` → `cd worker && node --test test/*.test.mjs` →
`npx wrangler d1 migrations apply axie-dice-db --remote` (chỉ 0006) → `npx wrangler deploy`. Build game mới cũng cần (client gửi -m).

**Việc kế tiếp:** C6 còn Profile/Account, Cosmetics; đo FPS web (lối đi sân + Land) ở B8; B1 cuối + B3 (cần Liam), B7/B8 build.

**Bẫy hôm nay:** lỗi parse / thiếu `--import` sau rebase / dấu CONFLICT còn trong file → Godot TREO (luôn kill timer); test xanh ở
worktree nhưng đỏ ở cây chính vì save thật của Liam (không còn newcomer) → test phải tự đặt trạng thái; agent con hay chạm giới hạn
20 lượt → bảo commit từng bước nhỏ; vòng `until ! pgrep run_tests` không bao giờ thoát.

## (cũ) ⇢ BẮT ĐẦU TỪ ĐÂY (bàn giao chiều 13/10/2026 — session mới đọc mục này trước)

**Việc đầu tiên: mở `production/l1-checklist.md`** (checklist L1, ô `[ ]` = còn làm). Quyết định của Liam: `production/session-state/pending-decisions.md` mục F–K + các dòng cuối file (đã chốt, không hỏi lại).

**godot-port = axiedice/main.** Suite cây chính **92/92 không SKIP**, Worker **152/152**. RULES_VERSION **`godot-2026-10-13-l`**
(Worker `SUPPORTED_RULE_VERSIONS` có tới -l). **Worker đã deploy 13/10 16:13** (gồm -l, pact_pick, telemetry, Continue miễn phí).

**Đã xong chiều 13/10 (đều qua review + suite):** B1 (điều kiện bật online), B2 (Aid/Continue trừ Gem), B3 code (màn đăng nhập),
B4 (số liệu + `worker/sql/l1_report.sql`), B5 (Nhiệm vụ N1–N3 + số bản cực khó -k), B6 (boss/elite đủ model), B9 (save cũ), B10
(Continue miễn phí người mới), B12 (cosmetics trong game), C1 (màn pact, -l), C3 (menu trong run), C5 (Land hub v5), C11 (cosmetics v8).

**Đang dở khi chuyển session (agent đã dừng cùng session cũ — kiểm tra rồi review + merge):**
- l1/L có commit chưa merge: cd2475b (Land v5: "5 runs" từ data, nút + Gem 44 px, chạm-để-xem, UI scale 0.85) — review FIX FIRST:
  `_is_touch()` chỉ dựa `is_touchscreen_available()` → laptop cảm ứng click chuột cũng 2 bước; cần chốt touch khi có
  InputEventScreenTouch thật + test HUD không đè dock ở scale 1.275. Đã có commit sửa 1cd678d (touch chỉ bật khi chạm thật + test HUD ở 1.275) — CHƯA review: cho agent khác review cd2475b..1cd678d rồi merge.
- l1/C: bỏ hẳn FrontLine (Liam chọn C) — đã có commit 20d73ee (xoá node + code, `_update_front_line` để no-op vì TutorialView còn đọc; suite worktree 91/91), CHƯA review: cho agent khác review rồi merge.
- Worktree R: file nháp `godot/tests/qa_b12_capture.*` untracked — xoá.

**Việc kế tiếp theo checklist:** B1 phần cuối (bật cờ remote trong `project.godot` [axie] + chạy trọn 1 run thật trên Worker),
B3 (Liam thử đăng nhập Google trên bản Mac/Win), B7 (build lại Mac Apple Silicon + Win), B8 (web), B11 (Aid R4/R5), C2 (Daily/Ranked),
C6 (màn R3 còn lại: Team presets, Leaderboard, Profile R3, Land upgrade), C7, C8, C9, rồi D1–D7 theo lịch.

**Bẫy quan trọng (đã cắn hôm nay):** merge commit đã review chứ không merge đầu nhánh; không `| tail -1` output merge (giấu CONFLICT);
test ở worktree xanh vẫn có thể đỏ ở cây chính vì save thật của Liam (có run_save + meta cũ) → test phải SaveGuard + tự đặt trạng thái
(newcomer, saved_run_probe); vòng chờ `until … pgrep run_tests` không bao giờ thoát nếu worktree khác đang chạy suite. Xem memory
`lane-merge-pitfalls`.

## (cũ) bàn giao sáng 13/10/2026 — sau đêm chạy liên tục)

**godot-port = axiedice/main** (đã push). Suite cây chính **85/85 không SKIP**, Worker **141/141**. RULES_VERSION
`godot-2026-10-13-i`. Mức sàn trong `.claude/docs/technical-preferences.md` đã cập nhật (file đó nằm trong .gitignore, chỉ trên máy).

**Đã merge trong đêm (mỗi lần merge đều có agent khác review + suite xanh ở cây chính):**
- A: luật Nhiệm vụ, end_run → record_run_outcome (+reached_boss), RemoteEpochSource sau cờ (mặc định local).
- B: offer v2, EN, boss miễn instant kill, 22 relic H1–H8 + 7 rework, pact live, trục G/A (trần G ×2,5), trần reroll,
  Eternal, pact_forced, **mở hết 14 relic ẩn** (không còn relic ẩn).
- C: Atia 3D, 6 sân biome (chọn theo hàng bản đồ, boss có biến thể), ánh sáng khớp Land, sửa khung/cổng.
- E: ví Gem remote, Pass v2 + việc tuần, ký quỹ cược Nhiệm vụ (nonce, an toàn khi tắt app), daily +500 Stone, hộp mùa (đang tắt).
- L: Land hub 6 tier, cổng xoay 90°, ánh sáng ấm, đất, decor dày, phím 1/3/4/daily mở màn R3, sửa lỗi khởi động.
- U: UI combat v3, AidPanel/DefeatPanel, "Elite row ahead" ở A9, số build 0.1.0-l1, chọn sân 3D.
- M (Round 3): Run Setup, Echo Box, Nhiệm vụ (cược thật qua ký quỹ), Store + Daily, Pass, Vault, Settings, Codex.
- S: RunSession, ví Gem khi đăng nhập (sau cờ), Continue boss 180, quà mùa 2×90 (bảng mùa server + điều kiện số run),
  token kid/jti + thu hồi, khoá trần quà nguyên tử, alarm hello.
- `.gitignore`: `src/` neo về gốc (trước đó giấu mesh sân và Land).

**Còn lại theo làn:**
- A: (xong, -i) header.newcomer lấy từ params. Nối màn pact gọi `RelicSlots.pact_forced`. Client gọi lại `/api/run/open` sau 1008 auth.
- B: xong bộ relic L1. Còn: sim cân bằng thật (sim F), sporegale có thể dùng `poisonSpread`.
- C: mystic/genesis chưa ai xem ảnh; chân trời boss vẫn phẳng (camera thấy ít trời).
- E: thưởng tuần Daily (4 ngày → 150 Shard + 2000 Stone) có data chưa có logic; ghép số vào bảng Aid catalog (giá Aid đang viết cứng trong CombatView).
- L: mảnh địa hình biome thật (mới có đất texture), tier 6 trời tím/đất hồng chưa chỉnh.
- M: M2 Team presets, M9 Leaderboard, M12–M14 Profile/Account/Cosmetics, M15 Land upgrade chưa làm; Vault giữ thẻ cũ (chưa lưới 5×4); hộp mùa UI (bật `enabled`).
- R: bản build Mac/Win ở `build/l1-2026-10-13/` (từ b2bd505, TRƯỚC Pass/ký quỹ/màn M sau) — build lại sau khi anh duyệt.
- S: ràng token với session (chờ anh quyết); M7 nhảy hàng chưa có spec server.

**Câu cần Liam quyết:** `production/session-state/pending-decisions.md` mục F (đã trả lời) + **G** (agent chọn tạm). Quan trọng:
G1–G6 Nhiệm vụ cực khó (doc `design/proposals/nhiem-vu-risk-to-earn.md` + review), Eternal (2 relic đầu, có tính relic khởi đầu?),
breakersward, A9 "Elite row ahead", việc tuần (XP ngoài trần ngày, mất nếu qua tuần), quà mùa 3/8 run, token không ràng session,
thu nhỏ 72 MB texture nguồn, hộp mùa (dup trả vé).
Review UI R3 để gửi Claude Design: `design/handoffs/ui-02-round3/REVIEW-art-director.md`. Sim nhanh: `production/qa/sim-quick-2026-10-12.md`.
Smoke: `production/qa/smoke-2026-10-13.md`.

**Deploy Worker: XONG (Liam, sáng 13/10)** — đã kiểm: D1 không còn migration chờ (0001–0005 đã áp), secret RUN_TOKEN_KEY có (RUN_TOKEN_KID không đặt → mặc định "k1", đúng code), `/api/gem/season_gift` trả 401 khi chưa đăng nhập (code mới đang chạy). Web R2 + build desktop: chưa làm lại.

**Các bước deploy (để tham chiếu lần sau):**
1. `cd worker && node --test test/*.test.mjs` (141/141).
2. `npx wrangler d1 migrations apply axie-dice-db --remote` — áp 0002, 0003, 0004, **0005_token_revocation** (0005 phải trước code).
3. `npx wrangler secret put RUN_TOKEN_KEY` (và `RUN_TOKEN_KID`; khi xoay khoá thêm `RUN_TOKEN_KEY_PREV`/`RUN_TOKEN_KID_PREV`).
4. Google OAuth: thêm redirect URI desktop (loopback) nếu dùng login desktop.
5. `npx wrangler deploy`. Cờ client `axie/epoch_source`, `axie/gem_wallet` vẫn "local" → người chơi chưa thấy thay đổi.
6. Web: `bash export-web.sh` (tắt editor) → `bash deploy-r2.sh`. Desktop: build lại từ godot-port mới nhất.

## (cũ, tối 12/10) bàn giao trước đêm

**Đang làm: sprint L1 — playtest nội bộ tải về, ra mắt 3/11/2026.** Kế hoạch: `production/l1-sprint-plan.md` (khối quyết định
đầu file), giao diện giữa các làn: `production/l1-interfaces.md`, bảng làn/worktree/quy tắc merge: `production/l1-lanes.md`,
nợ của làn I: `production/l1-tasks-I.md`, làn S: `production/l1-tasks-S.md`.

**Quy tắc làm việc đêm nay / sprint (Liam):** commit + push tự do (`git push axiedice godot-port:main`), duyệt theo tuần,
chạy liên tục; KHÔNG deploy (Worker/R2) khi chưa hỏi; mọi việc xong phải có agent khác review rồi mới merge.
**Dùng token cẩn thận:** đọc `production/agent-token-rules.md`, tối đa 4 agent cùng lúc, prompt gọn, agent mới cho việc mới.

**Worktree** `/Users/loc.tien.nguyen/my-game-wt/<A|B|C|E|L|M|R|S|U>` (nhánh `l1/<làn>`), mỗi cái có `godot/override.cfg`
(user dir riêng, khoá Godot riêng). Mọi lần chạy Godot qua `godot/tools/with_lock.sh`; worktree làn dùng
`AXIE_SKIP_RULES_FINGERPRINT=1`; cây chính thì không (phải xanh không SKIP). Sau rebase cần `--import` (class_name mới).
Nếu rebase bị chặn bởi `.import` untracked của echobox: xoá chúng (godot-port đã track).

**godot-port (= axiedice/main) hiện có:** ngày 0 (khoá, worktree), S (RunDO, canon, ví Gem server, login desktop),
R (build mac/win), A PR1 epoch + PR2 (hook H1–H8, Ascension v2, đồng hồ, attrition, spike, Continue, Aid R4/R6, Boon),
B relic v2 (133 relic, slots), C sổ Atia, E kinh tế + Store fixes. RULES_VERSION `godot-2026-10-12-c`. Suite 68/68 trước merge S.
**Cây chính còn sửa chưa commit:** `godot/tests/t_rules_version.gd` (FINGERPRINT sau merge S d9fbe77, không bump) +
`production/l1-tasks-I.md` — chạy suite ở cây chính, xanh thì commit + push.

**Lưu ý worktree bẩn lúc bàn giao** (agent bị ngắt do hết hạn mức): C 3 file, E 4, L 3, S 7 chưa commit — session mới
xem `git status` từng worktree, giữ/commit nếu xanh, không xoá bừa. Agent cũ của session trước có thể vẫn đang chạy nền một lúc.

**Chưa merge (theo làn, việc kế tiếp):**
| Làn | Commit chưa merge | Trạng thái / việc tiếp |
|---|---|---|
| A | 24b8d76 luật Nhiệm vụ, b7f270d end_run gọi record_run_outcome/pass_add_run_xp | 24b8d76 đang chờ review (lead-programmer). Tiếp: nối offer_ctx của B vào RunState (reward/shop/event/treasure/pact boss, shop_relic_count), R5 pact_reroll/pact_pick + ALLOWED_FNS + replay |
| B | 7ffcbb7 mô tả EN+boss immune (đã duyệt), ee2b582 offer v2 (đã duyệt), 83aefe9 thân 22 relic H1–H8 + 7 rework, 24dd998 pact live | 2 commit đầu đã duyệt MERGE (bump `-d`). 2 commit sau cần review. Còn: trục G/A, trần reroll a_chaos 6/4, relaybaton, Eternal sticker, pact bắt buộc A6/A10, mở nốt relic ẩn |
| C | 3f389e4, 8353d24, 011971f (Atia 3D + sửa review), 2935916 sân 6 biome, ef4bf9f ảnh lineup/arena | Review lần 2 báo commit cũ thiếu file arena — nay đã commit arena; cần review lại cả chuỗi + kiểm checkout sạch. Ảnh ở production/qa/evidence/ |
| E | 7f68d62 ví Gem remote (đã duyệt MERGE), 7ce7560 Pass v2 | 7ce7560 cần review. Tiếp: Việc tuần (3/tuần, 500 XP), MissionBoard theo `params.mission`/`mission_outcome` khi A merge |
| L | 50b016b LandNav, 888ec56 hub Savannah, a6ebd95 đủ 6 tier + nâng Land | Review xong: FIX FIRST, danh sách ở `production/l1-review-L.md`. Tiếp: **xoay cổng Portal 90° (Liam)**, **làm đẹp hub (Liam duyệt ưu tiên)**: ánh sáng ấm + bóng mềm, nền đất/mảnh địa hình biome thật, decor dày hơn, Pass ghi 29 Dec 2026 |
| U | 3 commit WIP (theme v3, khay 5 cột, AidPanel, DefeatPanel, banner) | CHƯA xanh. Tiếp: cho xanh, gọi `_combat.set_epoch(RunState.epoch)` sau `from_data`, màn đăng nhập desktop (AccountService.begin_desktop_sign_in), newcomer ẩn nút Aid, dòng "2 elite ẩn" ở A9, số build |
| S | e0fc845 (h_0 run_start) | Tiếp: nối RemoteGemWallet khi đăng nhập / set_gem_wallet(null) khi đăng xuất, RunSession + RemoteEpochSource (seq từ 0), giá Continue boss 180, kiểm nhảy hàng M7, endpoint quà mùa 2×90 Gem, tài khoản khách tối thiểu |
| M | chưa mở | Mở làn M: các màn meta theo Round 3 (`design/handoffs/ui-02-round3/_zip/`, README normative, 135 khung): ưu tiên Run Setup, Echo Box, Nhiệm vụ, Store+Daily, Pass |

**Claude Design Round 3 + phụ lục Round 2 đã về** (`design/handoffs/ui-02-round3/`), chưa review. Việc: art-director review
→ ghi chú sửa cho Liam gửi; làn M + U làm theo.

**Liam trả lời tối 12/10:** Pass: hết mùa vẫn nhận được thưởng đã đạt, chỉ dừng cộng XP · ưu tiên làm đẹp Land hub: CÓ.
**Liam trả lời thêm tối 12/10 (đã chốt, không hỏi lại):** (3) chấp nhận các chỗ [INF] của Round 3, code theo, gom danh sách
sửa cho Liam gửi Claude Design · (4) bỏ phần gamepad trong R3 · (5) KHÔNG deploy Worker trong đêm — sáng 13/10 Liam làm cùng ·
(6) thứ tự ưu tiên trong đêm: merge các commit đang chờ → U xanh → màn meta R3 (Run Setup, Echo Box, Nhiệm vụ, Store, Pass
trước) → đẹp Land hub → relic ẩn → sân biome → RunSession. Tối đa 4 agent cùng lúc. Chạy liên tục, không chờ Liam duyệt.

**Trước deploy Worker (hỏi Liam):** áp migration 0002–0004 lên D1 `axie-dice-db`, `wrangler secret put RUN_TOKEN_KEY`, có
thể thêm redirect URI desktop cho Google OAuth; Cloudflare gói Free.

Bản đầy đủ trước khi rút gọn: `archive/active-2026-10-12-before-rewrite.md`. Backlog trước 20/9: `archive/2026-09-pre-cowork/` (đã bỏ).

## (cũ, sáng 12/10) BẮT ĐẦU TỪ ĐÂY

**Cập nhật cuối 12/10:** đã chốt + review xong: kiến trúc server RNG (local `docs/architecture/`), monetization-v1
(cách B, PA-1, quà 180 Gem, status CHỐT — chờ sim), ascension-v2 bảng răng cưa, prompt UI
`design/requests/ui-redesign-request-02.md` (Liam gửi Claude Design). Tiếp theo: (1) Liam gửi prompt UI + ghi chú cosmetics
02 cho Claude Design; (2) technical-director thêm kind epoch cho R5 đổi pact; (3) sim F/G cho monetization + Ascension;
(4) viết lại Nhiệm vụ bản cực khó; (5) kế hoạch phase toàn dự án. Mục 1–3 bên dưới là bản sáng 12/10, đã xong.

1. **Mở `production/session-state/pending-decisions.md`** — 23 câu (A art, B monetization, C kiến trúc) + câu commit (D),
   mỗi câu có đề xuất. Liam nói sẽ trả lời ở session này. Đưa danh sách cho Liam, ghi quyết định vào đầu file nguồn,
   rồi làm "Việc sau khi Liam trả lời" ở cuối file đó.
2. Không có agent nào đang chạy. Không có server preview nào đang mở.
3. Có việc CHƯA COMMIT (xem `pending-decisions.md` mục D) — chỉ commit/push khi Liam cho phép.

## Quy tắc làm việc (Liam)
- Brainstorm → plan → làm → polish, đợi Liam duyệt giữa các bước. Có chỗ chưa rõ → hỏi.
- **Mọi việc xong phải cho một agent cao cấp KHÁC người làm audit/review** trước khi báo Liam.
- Thiết kế do agent làm chính (`game-designer`, `economy-designer`, `systems-designer`), Liam review.
- Không chạy nhiều agent song song nếu Liam chưa cho; thực tế đang giữ tối đa 2 cùng lúc.
- **Không mở/sửa `~/Downloads/MyGame` (Axie Infinity: A New Empire) và `~/Downloads/axie-asset-sources/`.**
- Gọi là "Nhiệm vụ", không gọi "hợp đồng".

## Tầm nhìn & hướng sản phẩm (đã chốt)
- Axie Dice thành game thật (không còn prototype Vibeathon). Nền tảng **Windows + macOS trước**, web giữ song song, mobile sau.
- Màn chính là **Land 3D** sống (Axie đi lại), các nhà là lối vào. Land là tài sản free, 6 tier Savannah < Forest <
  Arctic < Mystic < Genesis < LunaLanding, nâng bằng **Land Stone** (40k/100k/180k/500k/1M). Land KHÔNG cho sức mạnh combat.
- Combat giữ nguyên chiều sâu, chỉ bổ sung; không trait khắc chế; hồi đầy HP mỗi trận. Quái chuyển sang **Atia 3D**.
- **Hướng mới 11/10:** tạo ức chế TRONG RUN (quái/boss thật khó) rồi bán giải pháp (tiện lợi + sức mạnh trong run)
  bằng **tiền thật**, dùng được cả ranked. **Server tung xúc xắc ở mọi chế độ** (online-only). Nhiệm vụ KHÔNG gắn
  monetization — chỉ khó, là bài test risk-to-earn của Liam. Đã nêu rủi ro pháp lý (cược tiền có giá trị) → hỏi pháp lý Sky Mavis.

## Thiết kế — trạng thái từng file (`design/proposals/`, mỗi file mở đầu bằng khối quyết định của Liam)
| File | Trạng thái |
|---|---|
| `core-loop-v2.md` | Đã review; quyết định ở đầu file ghi đè thân file |
| `economy-v2.md` | **Chốt**: 2 tiền (Gene Shard, Land Stone), vé 200 Shard ×1,05/ngày cap 30, mỗi lượt Echo Box 1 phần thưởng, jackpot 0,02%/0,03%, heavy ~1 năm tới Luna (regular/casual chậm hơn — Liam chấp nhận). R ≈ 450 Shard/run (đo: `godot/prototypes/economy_probe/`) |
| `echobox-pass-v2.md` | **Chốt**, đồng bộ với economy: hộp thường (pool lớn, pity) + hộp mùa (kiểu Dota "Trove of Terror", 5 vé/lượt, đủ bộ ≤80 lượt, 12 tuần); Pass kiểu LoL ≥14 ngày, có 5 unlock chỉ số |
| `relic-audit-research.md`, `relic-set-v2.md`, `relic-set-v2-review.md` | **Bộ relic KHOÁ về thiết kế** (133 relic, 8+3 ô, trần nhân G ×2,5/Axie mặt dmg, 9 pact, 8 hook mới); số chốt sau sim |
| `ascension-v2.md` | Liam trả lời đủ; A1–A10 luật cố định; mốc enrage chốt sau sim |
| `nhiem-vu-risk-to-earn.md` | Bản 7 bậc đã viết; Liam yêu cầu **viết lại CỰC KHÓ** (chưa làm), nhà Nhiệm vụ nâng bằng Shard + Stone, bậc khó nhất dùng Full mode, server tung xúc xắc |
| `monetization-v1.md` (+ `-review.md`) | Đã định giá (Lunar Gem, 10 Aid, trần 8/run); creative-director: APPROVE WITH CHANGES, 3 BLOCKER → chờ Liam (pending B) |
| `design/registry/entities.yaml` | Đã đăng ký 18 mục economy |

Kiến trúc: `docs/architecture/server-authoritative-rng.md` (B2) + `-review.md` (lead-programmer) + `-security-review.md`
— **3 file chỉ có trên máy (docs/ bị gitignore)**. Chờ Liam (pending C).

Request cho Claude Design: `design/requests/cosmetics-art-request-01.md` (55 món), `design/requests/ascension-ui-request-01.md`.

## Art Cosmetics 01 (Claude Design, nhận 11/10)
- Nguồn + REVIEW: `design/handoffs/cosmetics-01/`. Đã xuất 20 die plate PNG 512 (mipmap bật) → `godot/assets/cosmetics/dice/`,
  5/21 khung → `godot/assets/cosmetics/frames/`, manifest `godot/assets/cosmetics/cosmetics_manifest.json` (spec 14 FX).
- SVG plate dùng filter → phải rasterize bằng Chrome headless (cách làm trong README của handoff).
- art-director: skin ACCEPT WITH FIXES, khung REJECT (cần vẽ 19), FX ACCEPT WITH FIXES. Chờ Liam (pending A).

## Đã làm (code) — đều đã commit + push trừ khi ghi khác
- Test không còn làm bẩn save thật; `run_tests.sh` FAIL test nào đổi save. Suite **56/56**. Worker **27/27**.
- Worker: rate limit sign-in/save, sửa typo /terms /privacy — đã deploy (version b73672cd).
- Prototypes: `godot/prototypes/land_spike/` (Land 3D khả thi; M3 Pro: 20 Axie ~200 FPS, 50 ~76; Compatibility chậm ~10×),
  `godot/prototypes/economy_probe/`. Công cụ `godot/tools/import_homeland.py`.
- Asset 3D: `asset-library/godot-ready/` (bản chép Godot-ready, 951 scene) + `asset-library/design-library/` — local, gitignore.

## Việc lớn còn lại (thứ tự)
1. Liam trả lời `pending-decisions.md` → sửa kiến trúc + monetization theo review, gửi Claude Design sửa cosmetics.
2. Viết lại Nhiệm vụ bản cực khó (+ review).
3. Viết lại kế hoạch phase toàn dự án (Land, combat batch gom một lần bump `RULES_VERSION`: relic hooks + Ascension +
   Aid + epoch seed, quái Atia 3D, server RNG P0–P5, store).
4. Bắt đầu triển khai theo phase.

## Bẫy
- Comment cũ gọi bậc 4 là "Mythic" (`reward_generator.gd:56`, `relic_def.gd:32`, `unit.gd:40`) giờ sai vì Mythic = 5 (chỉ cosmetic).
  Đây là file luật: sửa comment cũng làm đỏ `t_rules_version`, nên để gom vào lần bump `RULES_VERSION` chung.
- Lỗi parse GDScript làm Godot treo; Mac không có `timeout` → background + `( sleep N; kill $p )`.
- `godot/tools/record_sample_run.tscn` và `verify_run.tscn` CHƯA có SaveGuard — ghi đè save thật. Sao lưu
  `~/Library/Application Support/Godot/app_userdata/Axie Dice (Godot port)/` trước khi chạy bất cứ thứ gì.
- Chụp màn hình phải chạy KHÔNG `--headless`. Mọi ghi save qua `SaveStore`; field meta mới → sửa `MetaState.reload_from_store()`.
- Worker test: `cd worker && node --test test/*.test.mjs` (Node 24 không nhận `test/`).
- zsh không tách biến chứa tham số: dùng `${=var}`.
- Server tĩnh xem bản giao Claude Design: cấu hình `cosmetics-01` trong `.claude/launch.json` (cổng 8766).

---
**Session mới: đọc mục "⇢ BẮT ĐẦU TỪ ĐÂY" ở đầu file này, rồi mở `production/session-state/pending-decisions.md` (23 câu chờ Liam).**
