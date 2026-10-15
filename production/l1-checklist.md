# Checklist L1 — ra mắt playtest nội bộ 3/11/2026

Đánh dấu `[x]` khi xong (kèm ngày + commit nếu có). Làm theo thứ tự từng phần. Muốn biết "đã tới đâu" thì đếm ô trống.
Nguồn: `production/l1-sprint-plan.md` (lịch + danh sách cắt), quyết định Liam ở `production/session-state/pending-decisions.md`.

**Phạm vi L1 đã chốt (Liam 12–13/10):** bản tải về cho **Apple Silicon (macOS) + Windows**, **và cả bản web** · Nhiệm vụ chỉ
**N1–N3**, nhà Nhiệm vụ không nâng cấp · không VIP thử · không hộp mùa (chỉ hộp thường) · boss Atia thiếu asset → **mascot có
sẵn** · báo lỗi bằng **một Google Sheet** (Liam làm) · Cloudflare gói Free · không ký app (hướng dẫn mở thủ công).

---

## A. Việc của Liam

- [ ] A1. Tạo Google Sheet báo lỗi (cột gợi ý: ngày, người báo, máy Mac/Win/Web, bản build, mô tả, các bước, ảnh, mức độ) và gửi link cho lane I để gắn vào hướng dẫn cài + màn Settings.
- [x] A2. (13/10: Liam chọn v4 cho L1) Chốt hướng Land hub: bản Claude Design mới "Land hub v4 · town + dock" (`design/handoffs/ui-02-round4/_zip/Dice UI R1 - Land Hub v4.dc.html`, ảnh `screenshots/01-hub-v4.jpg`) có phải hướng sẽ làm cho L1 không.
- [ ] A3. Cosmetics lượt 2 (21 khung avatar còn thiếu + sửa plate xúc xắc) — chưa có trong bản zip 13/10. Gửi Claude Design hoặc chấp nhận dùng 20 plate + 5 khung hiện có cho L1. Hạn mềm 24/10.
- [ ] A4. Danh sách người mời (~50) + kênh gửi link tải. Hạn 24/10.
- [ ] A5. Nội dung thông báo phát hành: "Gem tặng sẽ reset ở L2", ngày Mùa 1 (3/11–29/12), link Google Sheet.
- [ ] A6. Dogfood RC2 (1–2/11) và chốt bản phát hành (2/11).

## B. Phải có (không được cắt)

- [ ] B1. **Bật chơi online thật** (xúc xắc server + ví Gem server):
  - [x] Worker nhận RULES_VERSION hiện tại — `SUPPORTED_RULE_VERSIONS` + test khoá theo action_log (13/10, merge B1). Cần Liam deploy Worker.
  - [x] Client gọi lại `/api/run/open` khi bị đóng 1008 auth, thử 1 lần (13/10).
  - [x] (15/10 merge 5e371dd; Liam: bắt đăng nhập mới chơi, tutorial không cần) Bật cờ `axie/epoch_source` + `axie/gem_wallet` = remote trong `godot/project.godot` mục [axie] (cách bật: l1-interfaces.md §6.5).
  - [x] (15/10, l1-interfaces.md §6.5) Ghi nhận rủi ro L1: server chưa kiểm kết quả run (chỉ kiểm hash chain) → thắng/thua, payout Nhiệm vụ, điều kiện quà mùa tin client; không mở thưởng Gem/tiền thật theo kết quả run trước khi có verifier (P3).
  - [ ] (15/10: lần thử đầu của Liam KHÔNG vào được run — UI gọi luật kiểu đồng bộ; đã sửa, merge 40e28ac, RULES_VERSION -n, cần deploy Worker + build lại để thử lại) Chạy trọn 1 run thật trên Worker: mất mạng giữa run, nối lại, hết hạn token, thoát app giữa trận.
  - [x] RunSession tắt `_process` khi không có run (13/10).
- [x] B2 (13/10, merge df8bb75; còn mở bên dưới). **Aid + Continue bằng Gem tặng**: bảng giá Aid ra data (đang viết cứng trong CombatView), nút mua trừ Gem thật qua server, giới hạn 6/run (4 từ A9, theo catalog + server), ẩn cho người mới. Còn mở: Continue miễn phí cho người mới (lần thua elite/boss đầu, A0–A2) — chưa làm.
- [~] B3 (13/10: màn đăng nhập xong, merge f6a5203; CÒN: Liam thử đăng nhập Google thật trên bản Mac + Win, thêm redirect URI desktop). **Đăng nhập desktop**: màn đăng nhập có trạng thái chờ/huỷ/lỗi; thử đăng nhập Google thật trên bản build Mac + Win; redirect URI desktop trên Google OAuth console.
- [x] B4 (13/10, merge 0e48e63; Liam chạy: `cd ~/my-game/worker && npx wrangler d1 execute axie-dice-db --remote --file=sql/l1_report.sql`, đọc `production/l1-telemetry.md`). **Ghi số liệu run + Nhiệm vụ**: kiểm tra server ghi đủ (run bắt đầu/kết thúc, Ascension, thắng/thua, Aid/Continue đã dùng, cược/payout Nhiệm vụ); có cách xuất ra bảng cho Liam xem.
- [x] B5 (13/10, merge f88192a + e9fcc76; số liệu N1–N6 theo bản cực khó, RULES_VERSION -k; còn: chạy N1 trên Worker khi bật online). **Nhiệm vụ chỉ N1–N3**: N4–N6 khoá "Not in this build" (kiểm lại sau khi đổi luật), nhà Nhiệm vụ không nâng cấp; chạy trọn N1 từ cược → run → payout trên Worker.
- [x] B6 (13/10, merge a1095a6: mọi boss/elite có model; mecha=xia, agony=paladill có animation). **Boss thiếu asset → mascot có sẵn** (`assets/bosses/`: kibo, kotaro, paladill, xia) cho từng boss còn thiếu.
- [ ] B7. **Bản tải Mac (Apple Silicon) + Windows**: build từ godot-port mới nhất, cài thử trên máy sạch, hướng dẫn mở (Gatekeeper / SmartScreen) được kiểm.
- [ ] B8. **Bản web**: `export-web.sh` → chạy được ≥ 30 FPS với Atia + Land → `deploy-r2.sh` (khi Liam cho deploy).
- [x] B9 (13/10, merge 462eefd: run lưu bằng luật cũ bị bỏ kèm thông báo + cược Nhiệm vụ tính thua; save cũ v1 reset tiền tệ theo thiết kế — Liam chọn A; test t_save_upgrade). Save không mất: chạy thử cập nhật bản cũ → bản mới trên save thật (bản sao), cloud save qua tài khoản.

- [x] B10 (13/10, merge 1cf344d; cần deploy Worker). Continue miễn phí cho người mới (lần thua elite/boss đầu, A0–A2, monetization-v1 §2.6/E13) — cần bộ đếm theo tài khoản (server). Đang: người mới không có Continue.
- [~] B11 (14/10 merge 9632915: R5 đổi 1 thẻ pact xong, RULES_VERSION -m, Worker deploy 15/10; R4 chờ ví chung LIAM-2). Aid R4 (dời đồng hồ) + R5 (đổi pact) đang hiện "Coming soon".

- [x] B12 (13/10 merge 951fc80; còn: chụp màn hình kiểm bằng mắt, màn Profile theo khung R3 M12/M14). **Dùng cosmetics trong game (Liam 13/10: BẮT BUỘC cho L1)**:
  - [x] Trang bị skin xúc xắc + khung avatar (Profile/Vault), lưu qua SaveStore.
  - [x] Xúc xắc mang skin trong trận; khung avatar ở Profile, chip trên Land, màn kết quả.
  - [x] Pool Echo Box + Store dùng 20 skin + 21 khung thật theo độ hiếm (thay ID giữ chỗ std_*).
  - [x] Thẻ phần thưởng Echo Box / Store / Pass hiện hình art.

## C. Nên có (cắt được nếu trễ — hỏi Liam trước)

- [x] C1 (13/10 merge 1410f4c; RULES_VERSION -l; cần deploy Worker để nhận pact_pick + -l; màn PactView là bản đầu, chưa có khung Claude Design). Màn pact boss bắt buộc ở A6/A10 gọi `RelicSlots.pact_forced` (luật đã có, màn chưa nối).
- [x] C2 (14/10 merge f05dd91; Worker deploy 15/10 0a2acf58). Chế độ **Daily** và **Ranked** trong Run Setup (đang vẽ nhưng khoá).
- [x] C3 (13/10, merge b21c841). Menu trong run → Settings ("Back to run", bỏ cuộc trừ cược đúng).
- [x] C4 (14/10: code có từ C5 87c5dcb, test thêm ở t_land_hub, merge C8). Land "New run" khi còn run Nhiệm vụ dang dở → settle cược (đường này đang bỏ sót).
- [~] C5 (13/10 merge 87c5dcb: lưới 3×3, dock, chip, phím, trạng thái; 14/10 merge 4816900: "5 runs" từ data, nút + Gem 44 px, chạm-để-xem trên cảm ứng (chỉ bật khi chạm thật), HUD scale tối thiểu 0.85; còn: màn Leaderboard → C6). Land hub **v5** (Liam duyệt 13/10, review `design/handoffs/ui-02-round5/REVIEW-land-hub-v5.md`; khoá Nhiệm vụ + Leaderboard cho người mới; phím N xem tên) — thay cho v4 (Liam chốt 13/10; review: `design/handoffs/ui-02-round4/REVIEW-land-hub-v4.md`): lưới 3×3 quanh Portal, dock dưới, nút RUN giữa).
- [~] C6 (14/10 merge a2ceadd: Team presets + Leaderboard xong; Land upgrade xong 664b1a0, mở cho L1, giá gốc; còn Profile/Account, Cosmetics). Các màn R3 còn lại: Team presets, Leaderboard, Profile/Account, Cosmetics, Land upgrade (Land Stone).
- [x] C7 (14/10 merge, a1720d8 + bd8a2bf; Liam: thắng A≥5 nhận A5, A10 nhận cả hai; tên EN Liam đổi sau). Danh hiệu A5/A10 hiện trong game (Profile / Result).
- [x] C8 (14/10 merge 67aa32d: tự cộng ở lần nhận daily thứ 4 trong tuần, ghi ledger, chấm ngày; "(n/4)", "Paid this week" và toast là phần thêm ngoài mockup R3 — Liam xem). Thưởng tuần Daily (4 ngày → 150 Shard + 2000 Stone) — có data, chưa có logic.
- [x] C9 (14/10 merge a048294 + 09e7aac: sân mystic/genesis, tier 6, vách tier 4–5; còn đo FPS web ở B8). Polish hình: xem sân mystic/genesis, Land tier 6 (trời tím/đất hồng), mảnh địa hình biome.
- [x] C11 (13/10 merge d6b8eaa + 0706365: cosmetics v8 — 20 plate, 21 khung, 14 lớp animation chạy thật, blend add, giảm nhấp nháy). Cosmetics v7: nhập 20 plate + 21 khung tĩnh; chờ Claude Design gửi 13 lớp anim + sửa khung Common/Rare ở 40 px.
- [ ] C10. Danh sách sửa Round 3 của art-director (Liam đã gửi Claude Design) — áp phần nhận về.

## D. Kiểm tra trước phát hành (theo lịch)

- [ ] D1. **27/10** — bot chạy kiểm tra nhanh: không crash, win rate A0 không lệch quá xa; chỉnh số lần cuối (bump RULES_VERSION nếu cần).
- [ ] D2. **28/10** — Đủ tính năng: mọi làn đã merge, suite xanh không SKIP, mức sàn test đúng.
- [ ] D3. **29/10** — Code freeze + RC1 (Mac + Win + Web).
- [ ] D4. **29–31/10** — QA + soak: ma trận chế độ (thường, Daily, Ranked, Nhiệm vụ N1–N3, Ascension 0/3/6/9), mất mạng giữa run, cài máy sạch.
- [ ] D5. **31/10** — RC2 với bản sửa lỗi S1/S2.
- [ ] D6. **2/11** — Chốt bản: link tải Mac + Win, web đã deploy, hướng dẫn cài, link Google Sheet, thông báo.
- [ ] D7. **3/11** — Gửi link + theo dõi RunDO, lỗi, số Nhiệm vụ.

---

## Đã xong (để tham chiếu)

- [x] Worker deploy 13/10 (migration 0001–0005, token kid/jti, quà mùa, Continue boss 180) — Liam.
- [x] Worker deploy lần 4, 15/10 (version d7b97e18): RULES_VERSION -n + epoch_args.json (sửa run online). Claude chạy theo lệnh Liam; /api/leaderboard 200.
- [x] Worker deploy lần 3, 15/10 (version 0a2acf58): migration 0006_leaderboard, Ranked + leaderboard + Daily 3 lượt (C2), RULES_VERSION -m + pact_reroll (B11). Đã gọi thử /api/leaderboard season + daily: 200 — Liam.
- [x] Worker deploy lần 2, 13/10 14:39 (version eb839d69): nhận RULES_VERSION -k, ghi số liệu run (B4), Continue miễn phí người mới (B10) — Liam.
- [x] Merge đêm 12→13/10: A, B (bộ relic đủ, không còn relic ẩn), C (Atia 3D + 6 sân), E, L (Land 6 tier), U (combat v3), M (Run Setup, Echo Box, Nhiệm vụ, Store + Daily, Pass, Vault, Settings, Codex), S.
- [x] Liam trả lời 16 câu (mục H) + luật Nhiệm vụ M6/M7, người mới = 5 run có trận, danh hiệu A5/A10 (merge 13/10, RULES_VERSION `-j`).
