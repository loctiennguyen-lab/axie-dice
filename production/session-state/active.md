# Axie Dice — trạng thái hiện tại

Cập nhật: 2026-10-10. Nhánh `godot-port`, push lên `axiedice` (`git push axiedice godot-port:main`).
Giữ file này dưới 100 dòng. Sửa khi xong một mốc, không ghi nhật ký vào đây.

## ⇢ BẮT ĐẦU TỪ ĐÂY

**Mốc reset 10/10/2026.** Từ ~21/9 tới 10/10 Liam làm bằng Cowork. Mọi thứ Cowork đã làm được
giữ. Backlog và câu hỏi treo của các phiên Claude Code trước 20/9 đã **bỏ hết** — nằm ở
`archive/2026-09-pre-cowork/`, chỉ đọc khi cần tra lịch sử, KHÔNG lấy việc từ đó.
Bỏ theo luôn: FIX-PASS-03 block 3–7, câu hỏi nameplate chạm nhau / màu `blind`·`undying`,
frontier A–I trong `production/wayfinder/map.md`, `docs/godot-port-gap-inventory.md`.

**Thứ tự việc Liam đã chốt (10/10):**
1. ~~Backlog account~~ — xong phần làm được trong repo (xem dưới).
2. **Gameplay + economy — để Axie Dice thành game trọn vẹn. Brainstorm xong 10/10, chờ duyệt
   thứ tự rồi sang bước PLAN.**

## Chốt từ brainstorm (Liam, 10/10)

Mục tiêu người chơi: cả bốn — leo Ascension, cạnh tranh trong công ty, sưu tầm, build đa dạng.
Làm cả 4 hệ:
- **Hợp đồng risk to earn** (ý Liam): bỏ shard nhận nhiệm vụ, xong nhận x1/x2/x3, thua mất cọc.
- **Battle Pass mới** (ý Liam): chơi → XP → mốc thưởng currency/relic/cosmetic độc quyền.
  Làm bản CỐ ĐỊNH trước, thiết kế để sau này reset thành mùa được.
- **Echo Box** (gacha cosmetic, giữ theo `design/gdd/economy-progression.md:380-402` +
  `design/ux/echo-box.md`). Bản Godot đang có 0 cosmetic → cần làm nội dung cosmetic trước.
- **Gene Mutation: PORT** (FACE_POOL 50 + 5 mặt BP = 55, 10 RUNES, từ `git show 5e34a17^:src/data.js`).
  Engine đã áp mut (`combat_engine.gd:1233-1252`); phải bump `RULES_VERSION`.
- **Bỏ Moon Dust và World Tour.** Chỉ một loại tiền: Gene Shard. Thêm **Mastery theo class**.
- Giữ cả hai độ dài run (short / full) như hiện tại.

### Tầm nhìn mới (Liam, 10/10) — Axie Dice thành game thật, không còn là prototype Vibeathon
- Không ép thời gian: ưu tiên làm tốt.
- **Màn chính là Land 3D**: Axie đi lại, chạy nhảy; các nhà là lối vào (nhà vào run, nhà gacha =
  Echo Box, nhà nhiệm vụ = hợp đồng risk to earn, ...). Asset: `asset-library/godot-ready/`.
- **Land là tài sản free của người chơi**, 6 tier theo độ hiếm:
  Savannah < Forest < Arctic < Mystic < Genesis < LunaLanding. Bắt đầu ở Savannah, dùng
  currency nâng cấp; land cao mới trang trí được vật phẩm hiếm.
- **Nền tảng: Windows + macOS trước** (Liam sửa 10/10); Android/iOS làm sau. Ghi chú cho lúc làm
  mobile: Google sign-in trên iOS kéo theo Sign in with Apple; renderer Mobile; nén ETC2/ASTC.
- Quyền dùng asset Sky Mavis: Liam đã xin, OK.
- **Vai trò**: agent `game-designer` thiết kế chính (rule, balance, relic, Battle Pass, Echo Box,
  hợp đồng); Liam review. Cosmetic art do Claude Design làm theo spec Claude viết.
- **Đề xuất core loop v2: Liam ĐÃ REVIEW 10/10** — quyết định ghi ở đầu file đề xuất, ưu tiên hơn nội
  dung bên dưới (giữ combat + HP cũ, không trait, relic là trọng tâm, quái Atia 3D, "Nhiệm vụ" 5/ngày
  không hoàn cược, 2 currency).
- Đề xuất gốc: `design/proposals/core-loop-v2.md` (game-designer;
  đầu file có ghi chú review của Claude: shard/run có thể gấp 3–4 lần số 150 dùng trong bảng, và
  phép tính Mastery sai ~2,5 lần). 9 câu hỏi mở ở §11.
- **Bản thử Land XONG** (`godot/prototypes/land_spike/`, README có số đo): khả thi, nhìn đạt.
  M3 Pro: 20 Axie ~200 FPS, 50 Axie ~76 FPS (renderer Mobile); ~0,22 ms/Axie, nút thắt chưa rõ
  (không phải animation/bóng/outline). Compatibility chậm ~10 lần → iOS phải dùng renderer Mobile.
  VRAM 480–700 MB; project chưa bật nén ETC2/ASTC.
- **R (Gene Shard/run) đã đo** (`godot/prototypes/economy_probe/README.md`): short thắng trọn ~568,
  full trọn ~854, bot dở trung bình ~336. Dùng R ≈ 450 cho bảng economy tới khi có dữ liệu thật.
- **Request art 55 món cho Claude Design**: `design/requests/cosmetics-art-request-01.md`
  (20 die skin, 21 khung avatar, 14 dice FX, 6 bậc theo biome, cần Claude Design đề xuất màu Mythic).
- **Thiết kế Nhiệm vụ XONG, chờ Liam review**: `design/proposals/nhiem-vu-risk-to-earn.md` (4 bậc
  stake 0.2R–1.0R, 15 loại, 11 câu hỏi mở). Ràng buộc đã kiểm trong code: RunVerifier chỉ xác minh
  run ranked → Nhiệm vụ phải chạy ranked profile; resume chỉ nạp 6 key run_stats (`RunState.gd:930`).
- **Economy v2 XONG, chờ Liam review**: `design/proposals/economy-v2.md` (Echo Box giá bậc thang
  reset tuần 600×1,06^(k−1), Stone chỉ từ 12 hộp đầu tuần, Land chỉ trả Stone 40/100/180/280/360,
  LunaLanding ~6 tháng với người chơi thường, Pass 27.810 XP / season 8 tuần, m Nhiệm vụ hạ còn
  1,4/2,0/3,0/3,8 để RTP ~95%, 12 câu hỏi mở). R trong probe KHÔNG gồm daily +60.
- **Thứ tự Liam chốt (10/10): Economy → Relic → Nhiệm vụ.** Quyết định review economy + Nhiệm vụ ghi ở
  đầu `economy-v2.md` và `nhiem-vu-risk-to-earn.md` (Echo Box reset ngày, quay bằng vé, phân tách đồ
  trùng ra vé, học gacha Dota 2; Land giá to 40k/100k/180k/500k?/1M Stone, ~1 năm; Pass kiểu LoL ≥2
  tuần, chứa 5 unlock chỉ số; UTC; Nhiệm vụ trả ít Stone, được lỗ cả 5).
- **Echo Box v2 + Pass v2 (cơ chế) XONG**: `design/proposals/echobox-pass-v2.md` (vé + mảnh, giá vé ngày
  100×1,05^(k−1), Stone/lượt TB ~180 trong 20 lượt đầu ngày, Pass 32.400 XP ≥14 ngày, 5 unlock ở lv
  4/8/12/16/20). Tier 4 Land = 500.000 (Liam xác nhận). Agent KHÔNG xác minh được "gacha mới của Dota 2"
  Liam nói → hỏi Liam hệ nào.
- **Economy v2 bản hợp nhất XONG** (`economy-v2.md`, R=450): tới LunaLanding heavy 51,6 tuần (~1 năm),
  regular 77,9, casual 98,3 (Liam CHẤP NHẬN 10/10, không catch-up); Pass heavy 14,7 ngày; ngân sách Nhiệm vụ ≤150 Stone/ngày. Bất biến ECO-1..13.
- **Liam gửi dữ kiện gacha Dota 2 (ảnh Slack 10/2026, Tidehunter "Arcana Progress"):** tỉ lệ tăng dần,
  đồ độc quyền sau 40 lần mở, 6 đồ trùng → 1 rương, ~50 rương là đủ đồ cực hiếm (~$250).
  **XONG**: §2 Echo Box sửa theo Dota "Trove of Terror" (10/2026): series 25 món, tỉ lệ tăng dần F(c)=(c/N)^2,
  đủ bộ chắc chắn ≤100 lượt, Mythic đầu ≤50, quà mốc 40 lượt, 6 trùng → 1 vé, series 8 tuần, series cũ vào Vault.
  **Liam 10/10: Echo Box TÁCH 2 PHẦN** — hộp thường (công thức cũ + asset sẵn có) và hộp mùa (Dota, đồ cực
  hiếm theo mùa; GIÁ HỘP MÙA CAO HƠN NHIỀU hộp thường). **XONG 10/10** (`echobox-pass-v2.md` §2): 2 loại vé không đổi chéo,
  hộp mùa 3× giá (300 vs 100 Shard, chờ Liam OQ-27), hộp mùa 0 Stone/lượt (chỉ Stone một lần/món mới),
  pool thường 223 món, Series 1 hộp mùa 11+1 món, đủ bộ ≤80 lượt, nhịp 12 tuần, 1 nhà 2 tab. OQ-20..27.
  Chờ Liam trả lời danh sách A–D + OQ-20..27 → economy-designer cân lại số.
- Asset: `asset-library/godot-ready/` + `asset-library/design-library/` giờ là BẢN CHÉP THẬT (10/10).
  **Không mở/sửa `~/Downloads/MyGame` và `~/Downloads/axie-asset-sources/`** (Liam cấm).
- **Seed/resume — CHỐT (Liam 10/10), làm cùng ĐỢT COMBAT:** vào lại thì về đúng trận/lượt/HP/mặt đang
  hiện, nhưng RNG **xúc xắc** được reseed ngẫu nhiên lúc nạp (ghi vào action log; server cấp seed cho
  ranked/Nhiệm vụ); phần thưởng/shop/event GIỮ theo seed như cũ. Bump RULES_VERSION, dạy RunVerifier
  hiểu thao tác reseed, test: vào lại → tương lai khác, verifier vẫn chấp nhận.
- Công cụ `godot/tools/import_homeland.py`: chép scene từ godot-ready + mọi phụ thuộc, sửa đường dẫn.
  `prototypes/*` đã thêm vào `exclude_filter` của export Web.

Audit nền (agent game-designer, 10/10), các lỗ còn phải tính trong plan: unlock chỉ cộng chỉ số
(game dễ dần), shard hết chỗ tiêu sau vài run, Ascension chỉ nhân số, không có đường vào run
ranked / leaderboard / daily seed, party full HP mỗi trận, nội dung boss/event ít.
Nghi lỗi hiển thị chưa kiểm: `ResultView.gd:548-551` trừ 60 daily khỏi `shards_this_run`.

Mỗi bước: brainstorm → plan → làm → polish, đợi Liam duyệt giữa các bước.

## Việc đang treo

- Commit `088bf0f` và mọi thay đổi 10/10 (dưới) chưa commit/push. Worker chưa deploy
  (rate limit + sửa typo "Axie Dice Dice" trên /terms, /privacy chỉ có hiệu lực sau
  `cd worker && npx wrangler deploy`).
- Xoá Worker cũ `axie-dice-fun` (dashboard) · test Chrome incognito + Safari — Liam làm.
- Login riêng + chip tài khoản góc phải: để tới đợt polish UI cuối (Liam, 10/10).

## Xong 10/10 (Claude Code)

- `t_rules_version`: chỉ cập nhật FINGERPRINT, không bump `RULES_VERSION` (Liam duyệt).
- Save thật không còn bị test làm bẩn: `SaveGuard` giữ cả `run_save.json`; thêm guard vào 8 test;
  `run_tests.sh` so hash save quanh MỖI test, test nào để lại thay đổi → FAIL + tự chép lại.
- Worker rate limit: `/auth/*` 30/phút/IP, `/api/save` 60/phút/session (binding `[[ratelimits]]`).
  `/api/me` không giới hạn. Game có câu báo riêng cho `rate_limited`.
- Xoá `production/privacy-preview.html`.

## Số đo (10/10/2026, sau các sửa trên)

- Godot: `godot/tools/run_tests.sh` → **56/56**, save máy không đổi (md5 khớp trước/sau).
- Worker: `cd worker && node --test test/*.test.mjs` → **27/27**.

## Cowork đã làm (21/9 → 10/10)

- Repo gọn thành repo Axie Dice (`5e34a17`), đổi tên game, English pass.
- Combat: quái đánh lần lượt có animation, reroll tray FX (Claude Design v2), sửa tray chặn click.
- Monster sprite từ Spine 3.8, skill VFX Origins, Axie import đánh như chính nó.
- Deploy: Cloudflare Worker `axie-dice` + R2 + D1, domain axiedice.fun, web shell cache `index.pck`.
- Texture Axie sang WebP lossless; audio qua AudioServer; proxy Axie cùng origin.
- Account + cloud save (Google sign-in, guest mode, conflict dialog, backup). Xem
  `design/gdd/player-accounts.md`. File chính: `AccountService.gd`, `save_store.gd`,
  `AccountUI.gd`, `worker/src/accounts.js`.

## Hệ thống đã có trong game (tổng quát)

Core loop đầy đủ (combat, run map, reward/shop/event, boss), 94 relic, Vault/Import Axie,
battle pass + unlock, daily mission, tutorial, Codex, replay-verify chống gian lận
(`RunVerifier`, `ActionLog.RULES_VERSION`), UI v2 (DangoTheme, font Baloo 2 / Work Sans).

## Tài liệu nên đọc

- Luật chơi: `design/gdd/godot-port-rule-spec.md`. Economy: `design/gdd/build-spec.md`
  (INV-1..7) + `economy-progression.md`. Mục lục: `design/gdd/systems-index.md`.
- UI: `godot/CLAUDE.md` trước khi sửa `godot/scenes/`.

## Bẫy

- Lỗi parse GDScript làm Godot treo, không thoát. Ghi output ra file, đừng pipe qua `head`.
- Mac này không có lệnh `timeout`; dùng background process + `( sleep N; kill $p )`.
- Chụp màn hình phải chạy KHÔNG `--headless` (headless trả ảnh trống).
- Mọi chỗ ghi save đi qua `SaveStore`. Thêm field meta → sửa `MetaState.reload_from_store()`.
