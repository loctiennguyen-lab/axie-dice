# Axie Dice — trạng thái hiện tại

Cập nhật: 2026-10-12. Nhánh `godot-port`, push lên `axiedice` (`git push axiedice godot-port:main`).

## ⇢ BẮT ĐẦU TỪ ĐÂY (bàn giao tối 12/10/2026 — session mới đọc mục này trước)

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

**Chưa merge (theo làn, việc kế tiếp):**
| Làn | Commit chưa merge | Trạng thái / việc tiếp |
|---|---|---|
| A | 24b8d76 luật Nhiệm vụ, b7f270d end_run gọi record_run_outcome/pass_add_run_xp | 24b8d76 đang chờ review (lead-programmer). Tiếp: nối offer_ctx của B vào RunState (reward/shop/event/treasure/pact boss, shop_relic_count), R5 pact_reroll/pact_pick + ALLOWED_FNS + replay |
| B | 7ffcbb7 mô tả EN+boss immune (đã duyệt), ee2b582 offer v2 (đã duyệt), 83aefe9 thân 22 relic H1–H8 + 7 rework, 24dd998 pact live | 2 commit đầu đã duyệt MERGE (bump `-d`). 2 commit sau cần review. Còn: trục G/A, trần reroll a_chaos 6/4, relaybaton, Eternal sticker, pact bắt buộc A6/A10, mở nốt relic ẩn |
| C | 3f389e4, 8353d24, 011971f (Atia 3D + sửa review), 2935916 sân 6 biome, ef4bf9f ảnh lineup/arena | Review lần 2 báo commit cũ thiếu file arena — nay đã commit arena; cần review lại cả chuỗi + kiểm checkout sạch. Ảnh ở production/qa/evidence/ |
| E | 7f68d62 ví Gem remote (đã duyệt MERGE), 7ce7560 Pass v2 | 7ce7560 cần review. Tiếp: Việc tuần (3/tuần, 500 XP), MissionBoard theo `params.mission`/`mission_outcome` khi A merge |
| L | 50b016b LandNav, 888ec56 hub Savannah, a6ebd95 đủ 6 tier + nâng Land | Review lần đầu dở (agent bị ngắt). Tiếp: **xoay cổng Portal 90° (Liam)**, **làm đẹp hub (Liam duyệt ưu tiên)**: ánh sáng ấm + bóng mềm, nền đất/mảnh địa hình biome thật, decor dày hơn, Pass ghi 29 Dec 2026 |
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
