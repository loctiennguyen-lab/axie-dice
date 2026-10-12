# Kế hoạch phase toàn dự án — Axie Dice v1

> **QUYẾT ĐỊNH LIAM (12/10) — ưu tiên hơn thân file:**
> **L1 = 3/11/2026** (Mùa 1 bắt đầu cùng ngày; game phải xong trước ngày đó) · L1 là bản **tải về (download)** cho người
> trong công ty test: nội bộ Sky Mavis + ~50 người mời — đây chính là mục tiêu playtest; **không phát hành Steam** ·
> Q3 được bump `RULES_VERSION` thêm trước L1, khoá từ L1 · Q4 web chỉ làm dự phòng (sẽ lag), khuyến khích tải bản desktop ·
> Q5 Mastery/tham quan Land sau L1, không port FACE_POOL · Q6 bao nhiêu làn cũng được nhưng phải hiệu quả và chính xác ·
> Q7 UI làm theo từng đợt Claude Design; chỗ chưa đúng phải có bản review rõ ràng để Claude Design sửa · Q9 Gem tặng
> 300/ngày, trần 900, reset ở L2, VIP thử 7 ngày · Q10 **UI vẫn làm đầy đủ**; tham quan Land để hẳn sau · Q11 chi phí cố
> định duyệt trước phần server, nhưng quy mô test nhỏ, không Steam nên gần như không có.
> ⚠ Kế hoạch thân file (30–38 tuần) KHÔNG khớp L1 3/11 (còn ~3 tuần). Phải viết lại phạm vi L1 — chờ Liam chọn cắt gì.

Trạng thái: ĐỀ XUẤT (12/10) — chờ Liam duyệt

Người viết: producer · 12/10/2026 · Chỉ viết file này, không code, không commit.
Thay phần phasing cũ ở `design/proposals/core-loop-v2.md` §10 (P1–P5 ở đó đã cũ). Để khỏi nhầm với P0–P5 của kiến trúc
server, phase trong file này gọi là **GĐ** (giai đoạn). P0–P5 luôn có nghĩa là lộ trình trong
`docs/architecture/server-authoritative-rng.md` §5.

**Mọi kích thước là ước tính** (S ≤ 1 tuần, M 2–4 tuần, L 5–9 tuần), tính theo nhịp làm việc hiện tại: Liam + agent,
mỗi việc xong phải qua một agent cao cấp khác review rồi Liam duyệt. Chưa có số velocity thật cho code mới kể từ khi
port xong, nên sai số lớn, có thể ±40%. Đo lại sau GĐ2 (combat batch là việc lớn đầu tiên).

---

## Tóm tắt một trang

**Ra mắt (theo Liam 12/10):** có hai mốc, cách nhau bằng một cổng riêng.
- **L1 — Playtest công khai.** Game mở cho mọi người, online-only, server tung xúc xắc, đủ Land, combat batch, economy
  meta, Nhiệm vụ. **Không có thanh toán tiền thật.** Liam chốt 12/10: **cấp Gem miễn phí**, Aid/Continue/VIP chạy như thật
  nhưng trả bằng Gem tặng. Lượng và cách cấp: đề xuất ở mục "Gem tặng ở L1" bên dưới, chờ Liam xác nhận con số.
- **L2 — Mở bán.** Kênh thanh toán + store tiền thật + Pass premium (mùa 2). Có cổng riêng (GĐ18).

| GĐ | Tên | Cỡ (ước tính) | Phụ thuộc chính | Song song được với | Chủ trì |
|---|---|---|---|---|---|
| 0 | Dọn đầu vào, tạo epic | S (~1 tuần) | — | GĐ1, GĐ7a | producer |
| 1 | Spike RTT server từ VN | S (1–2 ngày) | — | GĐ0 | technical-director |
| 2 | **Combat batch + engine theo epoch** (1 lần bump `RULES_VERSION`) | L (8–12 tuần; reviewer nới từ 6–8, xem ghi chú cuối file) | GĐ0 | GĐ4, GĐ7, GĐ8a | lead-programmer |
| 3 | Sim + chỉnh số (relic A–E, Ascension/monetization F/G) | M (2–3 tuần) | GĐ2 | GĐ5, GĐ9, GĐ10 | systems-designer |
| 4 | Server P0: danh tính desktop + ví D1 | M–L (3–5 tuần) | GĐ1 (một phần) | GĐ2, GĐ7, GĐ8 | technical-director |
| 5 | Server P2: RunDO + WebSocket | M (2–3 tuần) | GĐ1, bước 1 của GĐ2 | GĐ3, GĐ9, GĐ10 | network-programmer |
| 6 | Server P3: verifier + thưởng từ server + leaderboard | M (2–3 tuần) | GĐ5, GĐ2 xong | GĐ9, GĐ10, GĐ11 | technical-director |
| 7 | UI v3: Claude Design 3 vòng → sửa `godot/CLAUDE.md` → làm UI | L (lịch Claude Design 3–5 tuần + làm 7–9 tuần) | GĐ2 cho dữ liệu HUD, GĐ8a cho cảnh combat | GĐ2–GĐ6 | ux-designer / ui-programmer |
| 8 | Quái + boss Atia 3D, cảnh combat 3D | L (spike 1–2 tuần + 4–6 tuần) | — (spike), GĐ7 vòng 1 | GĐ2, GĐ4 | technical-artist |
| 9 | Land 3D hub (nhà là lối vào, 6 tier) | L (6–8 tuần) | GĐ7 vòng 1 | GĐ3, GĐ5, GĐ6 | gameplay-programmer + technical-artist |
| 10 | Economy meta: Echo Box 2 hộp, vé, Pass v2, Thưởng ngày, Land Stone, cosmetics | L (5–6 tuần) | GĐ4 | GĐ5, GĐ6, GĐ9 | economy-designer / gameplay-programmer |
| 11 | Aid / Continue / Gem / VIP trong game (không tiền thật) | M (2–3 tuần) | GĐ2, GĐ4, GĐ5 (test DO của Aid cần RunDO) | GĐ9, GĐ10 | gameplay-programmer |
| 12 | Nhiệm vụ (N1–N6, escrow, Bayes m_scale) | M (3–4 tuần) | GĐ2, GĐ3 (số d), GĐ5 (escrow lúc tạo run), GĐ6, GĐ10 | GĐ11, GĐ14 | gameplay-programmer + economy-designer |
| 13 | Server P4: online-only | M (~2 tuần) | GĐ6, GĐ11, GĐ12 | GĐ14, GĐ15 | technical-director |
| 14 | Telemetry + dashboard | S–M (1–2 tuần) | GĐ4 | GĐ11–GĐ13 | analytics-engineer |
| 15 | Bản desktop Windows/macOS (đóng gói, ký) + web | M (2–3 tuần làm, chứng chỉ có thời gian chờ) | GĐ4 (login desktop), Q1 | gần như mọi GĐ | devops-engineer / release-manager |
| 16 | Server P5 gia cố + QA/soak + beta kín | M (3–4 tuần) | GĐ13, GĐ15, và nội dung đã xong: GĐ7, GĐ8, GĐ9, GĐ10, GĐ14 (beta kín phải chơi đúng bản sẽ ra mắt) | — | qa-lead + security-engineer |
| 17 | Checklist ra mắt → **L1 playtest công khai** | S (~1 tuần) | GĐ16 | — | producer / release-manager |
| 18 | **Sau L1:** cổng thanh toán → **L2 mở bán**; Pass premium mùa 2; nội dung sau ra mắt | M+ (chưa ước tính kỹ) | L1 + dữ liệu telemetry | — | producer |

**Đường găng (critical path):**
GĐ0 → GĐ2 (combat batch) → GĐ3 (sim, chốt số) → GĐ12 (Nhiệm vụ cần số d sau sim) + GĐ13 (online-only) → GĐ16 (gia cố + beta kín) → GĐ17 (L1).
(Reviewer: GĐ6 không nằm sau GĐ3. Verifier chỉ cần `RunVerifier` mới của bước 1 GĐ2; `SUPPORTED_RULES` chỉ phải khớp bản luật
cuối trước L1, nên GĐ6 chạy song song GĐ3.)
**Làn trình bày (GĐ7c + GĐ8b + GĐ9 + GĐ10 client) là một agent, làm tuần tự, cộng lại ~22–29 tuần + Claude Design chờ + GĐ16–17.**
Đó mới là đường găng thật nếu làn C chỉ có một agent. Ước tính của producer 22–28 tuần chỉ đúng khi làn C có 2 agent
hoặc cắt phạm vi (Q10). **Reviewer ước: ~30–38 tuần với 3 làn, ~40–50 tuần với 2 làn.** Đo lại sau bước 1 của GĐ2.

**Ba làn đề xuất** (Liam cho chạy song song; mặc định giữ 3 agent làm cùng lúc, không hơn):
- **Làn A — luật và combat:** GĐ0 → GĐ2 → GĐ3 → GĐ11 → GĐ12.
- **Làn B — server:** GĐ1 → GĐ4 → GĐ5 → GĐ6 → GĐ13 → GĐ14, chen GĐ15 khi có chỗ.
- **Làn C — trình bày:** GĐ7 (Claude Design, Liam gửi) + GĐ8 spike → GĐ7 làm UI → GĐ8 → GĐ9 → GĐ10 (phần client).

**Việc bắt buộc tuần tự (không được xé lẻ):**
1. Mọi đổi luật combat gom vào một lần bump `RULES_VERSION` ở cuối GĐ2 (Liam C, quyết định 6 của Ascension).
2. Sim chỉ chạy được khi GĐ2 xong. Chốt số (enrage, relic, pity...) chỉ sau sim.
3. `godot/CLAUDE.md` chỉ viết lại sau khi Liam nhận UI (hết vòng 3), và **trước** khi ai làm màn mới theo style mới.
4. P2 cần spike (GĐ1) + engine theo epoch (bước 1 của GĐ2). P3 cần P2. P4 cần P3 + ví + escrow.
5. Beta kín (GĐ16) chỉ sau online-only (GĐ13) **và sau khi UI v3, Atia, Land, economy meta đã xong**; L1 chỉ sau beta kín.
6. (Reviewer) **Chạy test không song song trên một máy.** `run_tests.sh` chụp và chép lại save thật trong `user://`; hai làn
   chạy suite cùng lúc sẽ giẫm lên nhau. Mỗi làn một worktree git riêng, hoặc xếp lịch chạy suite lần lượt.
7. (Reviewer) **`t_rules_version` fingerprint cả `scripts/core` lẫn toàn bộ `autoload/`** (kể cả `MetaState`, `AccountService`).
   Nên GĐ4, GĐ10, GĐ11 sửa autoload cũng làm hỏng gate: mỗi lần phải cập nhật `FINGERPRINT`, và trả lời "có đổi kết quả
   run không" (ví/ticket/UI-only thường là không, không bump). Hai làn cùng sửa một hằng `FINGERPRINT` sẽ xung đột merge;
   ai merge sau thì tính lại.
8. (Reviewer) **Schema save/`MetaState` chỉ sửa theo một thứ tự:** GĐ4 trước (đưa ví ra server, reset unlock, thêm số phiên bản
   schema + di cư, sửa `reload_from_store()`), sau đó GĐ9/GĐ10/GĐ11 mới thêm field (layout Land, vé, Pass...). Mọi field
   mới vẫn đi qua `SaveStore`. Không để ba GĐ cùng tự thêm field rồi ghép sau.
9. (Reviewer) `MainMenu.gd` và các màn meta là điểm va chạm của GĐ7c, GĐ9, GĐ10: GĐ9 đổi lối vào thành nhà trong Land,
   GĐ10 thêm màn Echo Box/Pass. Làm meta screens (GĐ7c) **sau** khi hợp đồng dữ liệu của GĐ10 chốt, không làm hai lần.

---

## Chi tiết từng giai đoạn

Mỗi GĐ ghi: mục tiêu, phạm vi, phụ thuộc, tiêu chí xong (kiểm được), rủi ro chính, ai làm. "Review" = agent cao cấp
khác người làm, theo luật của Liam. Sửa suite test thì sửa mức sàn ở `.claude/docs/technical-preferences.md` trong
cùng commit (hiện 56/56 Godot, 27/27 Worker).

### GĐ0 — Dọn đầu vào, tạo epic (S, ~1 tuần)

**Mục tiêu:** để người code không phải đọc câu đã bị ghi đè.

**Phạm vi:**
- Đồng bộ các dòng cũ còn sót: `echobox-pass-v2.md` INV-V10 và các dòng "Không áp dụng ở Ranked" (B3), `core-loop-v2.md`
  mục Ranked profile, `nhiem-vu-risk-to-earn.md` §6 và `monetization-v1.md` §2.3 (seed/resume cũ, kiến trúc §10).
- Review nhanh còn treo: Nhiệm vụ bản cực khó (economy-designer), monetization review cuối.
- Hai câu nhỏ ở `relic-set-v2-review.md` (F-04 nguồn reroll ngoài relic, F-02 trần ×2,0): đầu file `relic-set-v2.md`
  đã ghi Liam trả lời "CÓ" (câu 15, 16) nhưng đầu file review vẫn ghi OPEN. Chỉ cần sửa trạng thái.
- Viết lại `docs/architecture/telemetry-dashboard-design.md` (bản cũ dựa trên Vercel + Upstash, giờ là Cloudflare).
  Có thể dời sang GĐ14.
- Một "spec gộp" cho combat batch: danh sách hook, action mới, field state, file luật bị chạm, test cần thêm. Đây là
  đầu vào duy nhất của GĐ2.
- Tạo epic + story (`/create-epics`, `/create-stories`) theo file này.
- `SaveGuard` cho `record_sample_run.tscn` và `verify_run.tscn` (hai tool này còn ghi đè save thật).
- (Reviewer) Bắt đầu thủ tục có thời gian chờ ngay: Apple Developer (Developer ID + notarization), chứng chỉ ký code Windows,
  Steamworks (phí app + xác minh thuế/ngân hàng + chờ duyệt) nếu Q1 chọn Steam. Giao release-manager, Liam chỉ duyệt chi phí.
- (Reviewer) Định nghĩa "máy chuẩn" (CPU/GPU Windows + Mac tối thiểu) và ngân sách FPS/dung lượng. GĐ8 và GĐ9 đã dùng
  mốc này từ trước GĐ15. Spike Land mới đo trên M3 Pro (20 Axie ~200 FPS, 50 Axie ~76 FPS, Compatibility chậm ~10×),
  chưa có số cho GPU tích hợp Windows.

**Xong khi:** grep "Ranked profile tắt", "tối đa 5/ngày", "resume{seed}" trong `design/proposals/` không còn câu nào
chưa gạch; spec gộp combat batch được lead-programmer + game-designer review; epic có trong `production/`; hai tool có
`SaveGuard` và suite vẫn 56/56.

**Rủi ro:** sót một câu cũ, người code làm theo câu cũ (đã từng xảy ra với VIP 2 Continue, R10). Cách chặn: spec gộp là
nguồn duy nhất cho GĐ2.

**Ai:** producer (điều phối), game-designer, economy-designer, lead-programmer (spec gộp), tools-programmer (SaveGuard).
Skill: `/create-epics`, `/create-stories`, `/design-review`.

### GĐ1 — Spike RTT server từ VN (S, 1–2 ngày)

**Mục tiêu:** chốt WebSocket hay HTTP vào RunDO trước khi làm P2 (kiến trúc C1).

**Phạm vi:** DO tối thiểu + `WebSocketPeer` từ Mac, Windows, web. Đo RTT p50/p95 từ VN theo colo, số dòng ghi mỗi
message, input gate khi `await` D1, `Crypto.hmac_digest` trên web. Code spike vứt đi.

**Xong khi:** có bảng số đo (RTT p50/p95 cho 3 nền tảng), có kết luận WS/HTTP ghi vào đầu file kiến trúc, Liam đọc.

**Rủi ro:** RTT xấu → chuyển HTTP, phần còn lại của kiến trúc giữ nguyên (đã tính sẵn). Cần máy Windows thật.

**Ai:** technical-director, network-programmer. Skill: `/prototype` (nếu dùng).

### GĐ2 — Combat batch + engine theo epoch (L, 6–8 tuần) — ĐƯỜNG GĂNG

**Mục tiêu:** mọi thay đổi luật combat của v1 vào một đợt, **một lần bump `RULES_VERSION`**.

**Phạm vi (theo thứ tự làm bên trong):**
1. **Engine theo epoch (kiến trúc P1):** `EpochSource` (Local/Tape), chữ ký mới ở ranh giới, bỏ `derive_combat_seed`,
   `can_reroll` và hàm kiểm thuần, hash chain + canon + vector vàng chéo ngôn ngữ, `RunVerifier` nhận băng + loadout,
   header ActionLog mới + `AID_USE`/`CONTINUE`. **Gồm cả "epoch seed cho mọi random" (cũ là bước 6: reroll, thưởng,
   `shop_roll`, event)**: phải xong trước khi viết relic/pact/loaded_pick mới, nếu không mỗi thứ random mới phải sửa lại.
   Suite xanh với `LocalEpochSource`. (Xong bước này thì GĐ5 và GĐ6 bắt đầu được.) Đây là bước bắt buộc đi đầu: Aid/Continue/Scout
   ở bước 4–5 chỉ là hook + luật chạy trên `Local/TapeEpochSource`, chưa cần server; giá và ví là việc của GĐ11.
   (Reviewer) Trong lúc làm bước 2–8, `t_rules_version` sẽ đỏ ở mỗi commit chạm `scripts/core`/`autoload`: cập nhật
   `FINGERPRINT` mà **chưa bump** `RULES_VERSION`, chỉ bump ở commit cuối (bước 9).
2. **Khung relic:** 8 ô passive + 3 ô active, ô nhân G theo từng Axie (trần ×2,5, chỉ mặt sát thương), ô A, trần ×2,0
   cho mặt Shield/Heal/Mana, 8 hook mới (H1 tách `on_roll_end`/`on_roll_settled`), state relic vào `_state_dict`/`from_data`,
   action mới (`reorder_party`, `sell_relic`, `loaded_pick`, `hold_pick`, `swap_on_full`, `tweak`), `ascend`/`forge` vào ô G.
3. **Nội dung relic:** 133 relic (44 mới, 19 rework, 7 merge), pact ở boss (mỗi PACT một lần/run), loại trừ `twinfates`.
4. **Ascension A1–A10** (luật cố định, răng cưa cổng A3/A6/A9), **Boss Clock nhẹ ở A0**, đầy đủ ở A4, attrition.
   **Continue kiểu B** + luật "Continue hồi 25% từ A6" là luật Ascension.
5. **Hook Aid** (không luật nào đọc trạng thái Aid/Continue — MON-13, có test tĩnh), trần 6/4, 1 Boon/run trong trần,
   R2 1/trận từ A3.
6. (Đã chuyển lên bước 1: epoch seed cho mọi random.)
7. **Tách map:** hình dạng ở `run_start`, loại node từng hàng là bí mật server (HMAC riêng), lộ khi tới hàng hoặc qua Scout
   (lộ 3 hàng). Elite cũng bị che, boss cuối act luôn hiện.
8. Luật làm tròn sát thương: ≥ .5 lên, < .5 xuống (Liam 12/10). Sửa comment "Mythic" cũ ở `reward_generator.gd:56`,
   `relic_def.gd:32`, `unit.gd:40`.
9. **Bump `RULES_VERSION` một lần**, cập nhật `t_rules_version`, mức sàn test.

**Xong khi:**
- `godot/tools/run_tests.sh` xanh với mức sàn mới (cao hơn 56, ghi số thật), có test cho: mỗi hook, mỗi luật A1–A10,
  Continue, trần Aid, MON-13 tĩnh, vector vàng, tamper (N1, N2, N9, H1, H2, M4–M6 ở mức engine).
- `t_replay`: cùng (log, băng) → `to_data()` trùng khít; đổi một seed trong băng → trước ranh giới không đổi.
- `t_full_run_loop` chạy đủ seed-walk với bộ relic mới, không crash, không `NaN`.
- `git log` cho thấy đúng một commit đổi `RULES_VERSION` trong đợt.
- Review: lead-programmer (code), game-designer (đúng spec), security-engineer (phần epoch).

**Rủi ro:**
- (Reviewer) Cỡ thật: `combat_engine.gd` 1.516 dòng, `RunState.gd` 1.032, `relic_hooks.gd` 940 (hiện phục vụ 94 relic, sẽ
  thành 133 với 8 hook mới), `run_map_generator.gd` 537, cộng 10 luật Ascension, tách map, và viết lại test hiện có
  (`t_full_run_loop` 197 check, `t_replay` 47, `t_vault` 400 đều đọc bộ relic/luật cũ; 7 relic merge, `tithepurse` bỏ). Nên coi
  8–12 tuần và tách thành 2a (bước 1, có mốc đo velocity thật) rồi 2b (bước 2–9).
- Lớn nhất dự án về code: chạm cả 19 file luật cùng lúc. Chặn bằng thứ tự trên và test từng bước, nhưng chỉ bump một lần ở cuối.
- Có thể phát hiện chỗ spec chưa kiểm trên code (boss miễn stun, định nghĩa "kề", kill do tick có kích `on_kill` không).
  Mỗi chỗ là câu hỏi cho game-designer, không tự quyết.
- Run local đang dở lúc bump bị bỏ (đã chốt, có thông báo).

**Ai:** lead-programmer (chủ trì, review), gameplay-programmer + godot-gdscript-specialist (code), game-designer
(câu hỏi luật), qa-tester (test). Skill: `/dev-story`, `/code-review`, `/regression-suite`.

### GĐ3 — Sim và chỉnh số (M, 2–3 tuần) — ĐƯỜNG GĂNG

**Mục tiêu:** đổi "số đoán đầu" thành số đã sim, đủ tin để mở playtest.

**Phạm vi:** bot A–E cho bộ relic (ưu tiên số 1: sát thương cộng thẳng không trần, F-12), sim F/G cho Ascension +
monetization (bảng răng cưa `ascension-v2.md` §5.1, casual A0 = 40, sàn 35, cờ đỏ 36; khoảng cách heavy − regular 22;
sàn Continue thắng ≥ 50% A0–A5, ≥ 35% A6–A10), mốc enrage, `relic_reroll_cap`, pity Legendary (câu 9), số Nhiệm vụ
(d theo logit) dùng số mới. Đo lại R (Shard/run, đang 450) trên luật mới.

**Xong khi:** mỗi ô mục tiêu ở §5.1 có số sim nằm trong dải hoặc có ghi chú vì sao lệch; số mới ghi vào doc nguồn có
nhãn "sau sim"; economy-designer + systems-designer ký; Liam duyệt bảng.

**Rủi ro:** sim cho thấy cần đổi luật (không chỉ số) → phải mở lại GĐ2. Chỉnh số trong file luật cũng làm đổi
fingerprint → có cần bump lần 2 không là câu Q3.

**Ai:** systems-designer, economy-designer, game-designer; ai-programmer cho bot. Skill: `/balance-check`.

### GĐ4 — Server P0: danh tính desktop + ví (M–L, 3–5 tuần)

**Mục tiêu:** tiền tệ và tài khoản sống ở server, desktop đăng nhập được.

**Phạm vi:** login desktop qua Worker (loopback + PKCE), access/refresh token xoay vòng, bearer tách cookie, lưu token
(godot-gdextension-specialist đánh giá Keychain/Credential Manager; đường lùi: file mã hoá), tài khoản khách server cấp,
bảng `wallets`/`wallet_ledger`/`entitlements`/`runs`, endpoint chi tiêu + Echo Box, PUT/GET save tách trường server
(PUT `shards=999999` không đổi số dư), di cư C6 (khoản khởi đầu cố định gộp tutorial, unlock cũ reset), cổng 18+ là cờ
server, endpoint xuất/xoá dữ liệu, Workers Paid. Nếu chọn Steam (Q1): danh tính SteamID qua ticket buộc nonce.

**Thêm (reviewer):** môi trường **staging** (Worker + D1 + R2 + DO riêng, hiện `wrangler.toml` chỉ có production), vì GĐ16 pentest
"trên staging" và GĐ5/GĐ6 cần chỗ thử không đụng ví thật; số phiên bản schema cho save + hàm di cư một lần; mức sàn Worker
ghi vào `technical-preferences.md` cùng commit (hiện 27/27, chỉ có `accounts.test.mjs`; thêm khung `vitest-pool-workers`
cho DO). Cỡ thật khả năng 5–7 tuần (login desktop Windows + GDExtension keychain + ví + di cư + staging).

**Không phá:** mọi ghi save vẫn qua `SaveStore`; field meta mới phải sửa `MetaState.reload_from_store()`; account +
cloud save hiện có (10/2026) giữ chạy.

**Xong khi:** Worker test xanh (mức sàn mới) gồm các ca ở kiến trúc §7 mục Worker (chi tiêu song song trừ một lần, refresh
dùng lại...); đăng nhập được từ build Mac và Windows thật; save cũ di cư đúng trên một bản sao save thật; security-engineer
review (`/security-audit`).

**Rủi ro:** loopback login trên Windows (firewall, cổng bị chiếm); GDExtension cho keychain là việc mới với dự án;
`@cloudflare/vitest-pool-workers` thêm khung test thứ hai.

**Ai:** technical-director (chủ trì), devops-engineer, security-engineer, godot-gdextension-specialist, network-programmer.
Skill: `/security-audit`, `/code-review`.

### GĐ5 — Server P2: RunDO + WebSocket (M, 2–3 tuần)

**Mục tiêu:** run chạy qua Durable Object, server tung xúc xắc, sau cờ, web trước.

**Phạm vi:** `POST /api/run`, `GET /api/run/:id/ws`, `RunSession` (hàng đợi `seq`, nối lại có backoff, overlay kết nối lại),
alarm thử lại ghi R2, limiter hai lớp, `run_json` ngừng đồng bộ, resume không reseed, không huỷ run vì để không.

**Xong khi:** test transport giả (rớt, trễ 2 s, trùng, đảo thứ tự, đứt giữa reroll) cho cùng state như ca không lỗi;
kill client giữa lượt → resume ra cùng kết quả; evict DO giữa run → sổ còn nguyên; chơi trọn một run trên web qua DO.

**Rủi ro:** hibernation sai → chi phí DO tăng (đo số DO mở, duration). Web chạy trước desktop vì desktop chưa login xong.

**Ai:** network-programmer, technical-director (review), devops-engineer.

### GĐ6 — Server P3: verifier + thưởng từ server + leaderboard (M, 2–3 tuần) — ĐƯỜNG GĂNG

**Mục tiêu:** từ đây mới có bảo vệ thật: thưởng chỉ trả sau khi verifier chạy lại run.

**Phạm vi:** container verifier (1 job/tiến trình, không mạng ra, timeout cứng, kiểm JSON trước Godot), job canary, kênh
ký, hàng đợi, `SUPPORTED_RULES` allowlist, payout idempotent, leaderboard (chỉ người đã đăng ký, tên tự đặt, bảng Pure
không Aid, bỏ = thua). Sửa ADR-0004 (cửa trước là Worker) và ADR-0003 (lưu định nghĩa die Vault).

**Xong khi:** log treo Godot + canary qua → run thường `verify_failed`, run có cọc huỷ + hoàn cọc + gắn cờ; canary hỏng →
`infra_error`; thưởng tạm tính lệch thưởng đã verify = 0 trên 100 run mẫu; `SUPPORTED_RULES` chỉ có bản luật sau GĐ3.

**Rủi ro:** chi phí/hạ tầng container (Cloudflare Containers hay chỗ khác — technical-director chốt trong GĐ này, không cần Liam
trừ khi có chi phí cố định đáng kể).

**Ai:** technical-director, devops-engineer, security-engineer. Skill: `/security-audit`.

### GĐ7 — UI v3 (L: lịch Claude Design 3–5 tuần + làm 7–9 tuần)

**Mục tiêu:** toàn bộ màn theo style Homeland mới, đúng luật "không giấu thông tin".

**Phạm vi:**
- **7a (Claude Design, Liam gửi):** R1 sửa (`NOTE-TO-CLAUDE-DESIGN-R1.md`) → R2 (run flow, map 3D, khung panel chung,
  Aid còn lại, Ascension) → R3 (meta screens, Run Setup). Mỗi vòng: art-director review + ux-designer audit → Liam nhận.
  Song song: Cosmetics 01 lượt 2 (21 khung vẽ lại, sửa plate, FX spec).
- **7b:** viết lại `godot/CLAUDE.md` theo style sheet mới (thay luật UI cũ). Làm ngay sau khi Liam nhận R3, hoặc nhận
  từng phần sau R1 nếu Liam cho (xem Q7).
- **7c:** làm UI trong Godot: theme + plate nine-slice → HUD combat (intent hợp nhất, clock, attrition, khay đội, Aid tray,
  Undo, bàn phím) → màn thua + Continue → run flow + map 3D → meta screens → tutorial chạy băng dựng sẵn với UI mới.

**Phụ thuộc:** HUD combat cần dữ liệu GĐ2 (clock, attrition, Aid, Scout) và cảnh combat 3D của GĐ8; meta screens cần
GĐ10/GĐ11 về dữ liệu.

**Xong khi:** mỗi màn có ảnh chụp 1920×1080 + 1920×1240 so với mockup (`production/qa/evidence/`), không clip; chơi
hết một run chỉ bằng bàn phím; Aid tray không bấm nhầm END TURN; mọi offer hiện giá + trần; biến thể reduce-flashing;
`t_mainmenu_ui`, `t_button_states`, `t_runloop_ui`... được viết lại theo màn mới, suite xanh. Review: art-director + ux-designer.

**Rủi ro:** Claude Design giao lệch số (R1 đã lệch công thức intent, attrition, giá) → mỗi vòng phải kiểm số với doc.
Chữ 11–12 px trên laptop. Lịch phụ thuộc người ngoài.

**Ai:** ux-designer + art-director (spec, review), ui-programmer (làm), accessibility-specialist (bàn phím, tương phản).
Skill: `/ux-review`, `/team-ui`, `/asset-audit`.

### GĐ8 — Quái và boss Atia 3D, cảnh combat 3D (L: spike 1–2 tuần + 4–6 tuần)

**Mục tiêu:** thay sprite Chimera 2D bằng quái Atia 3D trong toàn bộ roster.

**Phạm vi:**
- **8a spike (làm sớm, song song GĐ2):** kiểm kê `asset-library/godot-ready/` (235 monster, 85 nhân vật đã có
  AnimationPlayer với 454 clip; 77 clip không gắn được) → quái nào có rig + đủ clip (idle/attack/hit/die). Dựng một trận
  với 3 quái + 1 boss, đo FPS Forward+/Mobile/Compatibility và dung lượng. Ra danh sách boss thiếu asset để Liam xin thêm.
- **8b:** map roster hiện tại → Atia (bảng ánh xạ do game-designer + art-director duyệt), cảnh combat 3D (camera, sân,
  ánh sáng một hướng trên-trái), anim theo event `s.ev`, chỗ đặt intent/clock theo UI v3. Chép đúng món cần vào
  `godot/assets/`, không trỏ vào asset-library.

**Xong khi:** mọi enemy id trong `ContentDB` có model 3D + anim tối thiểu (kiểm tự động như `t_assets`); boss có đủ
asset hoặc có placeholder được Liam chấp nhận; FPS combat ≥ 60 trên máy chuẩn desktop (định nghĩa ở GĐ15) và có số đo web.

**Rủi ro:** boss thiếu asset (Liam phải xin — ngoài tầm kiểm soát), clip anim thiếu, dung lượng web tăng mạnh.

**Ai:** technical-artist (chủ trì), art-director, gameplay-programmer, performance-analyst. Skill: `/asset-spec`, `/asset-audit`, `/perf-profile`.

### GĐ9 — Land 3D hub (L, 6–8 tuần)

**Mục tiêu:** mở game vào Land sống; nhà là lối vào mọi tính năng meta.

**Phạm vi:** mặt đất Land riêng (plot module có texture lưới, thang 300 — phải làm mới), camera pan/zoom, Axie đi lại có
ngân sách (desktop đo; web giảm), nhà: Portal (Run Setup: thường/Daily/Ranked), House (đội lưu sẵn), Echo Box (2 tab),
Pass, Vault, Nhiệm vụ, Store (đề xuất từ render), Mastery nếu vào L1, 5 nhà Liam nhận (Weaponsmith, Alchemy, GemStorage,
Jeweler, Armorsmith); badge (!), 6 tier đổi mặt đất, nâng tier bằng Land Stone (40k/100k/180k/500k/1M), chỗ đặt
decor/thú từ Echo Box. Lưu layout qua `SaveStore` (+ `MetaState.reload_from_store()`). Tham quan Land người khác (B6):
cuối GĐ này hoặc sau L1 (Q5).

**Xong khi:** mọi nhà mở đúng màn; nâng tier trừ Stone ở server và đổi biome; layout decor còn sau khi đăng nhập máy
khác; ngân sách Axie đo được và ghi lại; FPS ≥ 60 desktop chuẩn; web có chế độ giảm chạy ≥ 30 FPS (hoặc phương án Q4).

**Rủi ro:** phần tốn nhất về nội dung (core-loop §12 đã cảnh báo). Compatibility renderer chậm ~10× → web khó. VRAM cao.

**Ai:** gameplay-programmer, technical-artist, world-builder/level-designer (bố cục), ux-designer, performance-analyst.

### GĐ10 — Economy meta: Echo Box, vé, Pass, Thưởng ngày, Land Stone, cosmetics (L, 5–6 tuần)

**Mục tiêu:** vòng sưu tầm chạy thật, do server giữ.

**Phạm vi:** vé (200 Shard ×1,05/vé trong ngày UTC, trần 30), hộp thường (1 vé, 60% Stone, pity 15/60/200/1.000, jackpot
0,02%), hộp mùa (5 vé, leo dần N=10/20/40, đủ bộ ≤ 80 lượt, quà mốc 40, nhịp 12 tuần), đồ trùng → mảnh → vé, công bố odds
+ pity trong game; Pass v2 30 level (≥ 14 ngày, vòng 2.000 XP = 50 Shard sau lv30, 12 vé, 5 unlock lv 4/8/12/16/20, hoàn Shard
người đã mua, 2 mốc × 90 Gem ở lv10/lv20); Thưởng ngày (UTC, server xác nhận, khách chờ 7 ngày); trang bị cosmetic (die
plate, khung, FX theo manifest); 3 vé tài khoản mới. Class Mastery: theo Q5.

**Xong khi:** test tự động kiểm: pity không bao giờ vượt; đủ bộ mùa ≤ 80 lượt trên 10.000 lần mô phỏng; EV hộp thường
242,5 Stone/lượt ± sai số; giá vé đúng công thức; không vòng vé vô hạn; mọi chi tiêu đi qua ví server (PUT save không đổi
được). economy-designer ký.

**Rủi ro:** gacha có tiền thật về sau → bảng odds phải công khai từ L1 cho quen. Mùa 1 phải gắn ngày L1 (Q2).

**Ai:** economy-designer (số), gameplay-programmer (client), network-programmer/devops (endpoint), ui-programmer.
Skill: `/balance-check`, `/dev-story`.

### GĐ11 — Aid, Continue, Gem, VIP trong game, chưa có tiền thật (M, 2–3 tuần)

**Mục tiêu:** toàn bộ đường Aid chạy được, server cấp và ghi log; chỉ thiếu cổng thanh toán.

**Phạm vi:** Gem trong ví server (`entitlements`), danh mục Aid với giá PA-1 (Continue 90/180, R2 15, R4 60, R5 15, R6 18,
R7 Scout 12, Boon 38, Kit 60), trần 6/4, Continue trả trong `epoch_req(continue)`, Aid random qua `epoch_req` kind `reroll`
`source=aid`, VIP (1 Continue/run −25%, 1 Boon/ngày, popup ngày 2), giai đoạn làm quen 5 run (đếm run có ≥ 1 trận xong),
câu công khai cạnh bảng giá, bảng Pure, store trong game **không có nút mua bằng tiền thật**. Nguồn Gem ở L1: Gem tặng (mục "Gem tặng ở L1"), ghi ledger với thẻ
nguồn `playtest_grant` tách khỏi quà mùa để reset được ở L2.
(Reviewer, thiếu trong phạm vi) endpoint **nhận Gem tặng theo ngày** (UTC, khoá idempotency `grant:{account}:{ngày}`, trần số dư
900), chỉ tài khoản đã đăng ký (khách không có ví, C3). Chống lạm dụng tối thiểu: Gem tặng chỉ tiêu trong game, không rút,
không vào bảng Pure; đếm tài khoản mới theo IP/ASN hash (đã có cho khách) và cờ ở dashboard GĐ14; nhiều tài khoản chỉ làm
lệch số đo, nên chấp nhận ở L1 và gắn thẻ `playtest_grant` để lọc.

**Xong khi:** test DO: Aid thứ 7 ở A0 / thứ 5 ở A9 bị từ chối; hai `aid_req` cùng `seq` trừ một lần; Aid/Continue/Boon trong
Nhiệm vụ bị từ chối; ranked/Nhiệm vụ khi còn newcomer bị từ chối; không có endpoint nào nhận tiền thật.

**Ai:** gameplay-programmer, network-programmer, economy-designer, ux-designer. Skill: `/dev-story`, `/security-audit`.

### GĐ12 — Nhiệm vụ (M, 3–4 tuần) — ĐƯỜNG GĂNG

**Mục tiêu:** bài test risk-to-earn của Liam chạy thật.

**Phạm vi:** nhà Nhiệm vụ 4 cấp (Shard + Stone), N1–N6 (N6 Full mode, cần đã thắng Full ở A9), cược trừ lúc tạo run (một batch
D1), escrow, payout `cược × m` + ít Stone, trần payout 20.000/run, không giới hạn số lần/ngày nhưng một run mở, Bayes m_scale
(cron, chỉ hạ, ≤ 0,02/ngày, công khai trên thẻ), "kỳ vọng nhận lại" trên thẻ, leaderboard theo từng Ascension, 2 điều kiện phụ
(Một nhà, Đa sắc) nếu kịp, verifier lỗi = huỷ + hoàn cọc. NFT dùng được. Không Aid/Continue/Boon.

**Xong khi:** test: cược trừ đúng một lần kể cả khi tạo run song song; thua/bỏ = mất cược; verifier timeout → hoàn cọc;
m_scale không bao giờ vượt bảng gốc; RTP mô phỏng trên ba hồ sơ nằm trong 0,75–0,95; dashboard hiện RTP theo bậc (GĐ14).

**Rủi ro:** bật khi chưa sim (Liam cho phép) → chỉnh live bằng Bayes; RTP sát đáy 0,77. Cược Shard đã được pháp lý duyệt.

**Ai:** gameplay-programmer, economy-designer, network-programmer, security-engineer. Skill: `/balance-check`, `/security-audit`.

### GĐ13 — Server P4: online-only (M, ~2 tuần)

**Mục tiêu:** bản release chỉ dùng `RemoteEpochSource` (Tape cho tutorial).

**Phạm vi:** bỏ đường chơi offline khỏi build release, Aid/Continue trừ ví server, escrow Nhiệm vụ, ~20 run mới/ngày (không
áp cho Nhiệm vụ), test tĩnh: tutorial không gọi `RunSession`/`AccountService`.

**Xong khi:** build release không có `LocalEpochSource` (kiểm bằng test); rút mạng giữa run → overlay nối lại, không mất
run; mọi tamper test của kiến trúc §7 xanh.

**Ai:** technical-director, network-programmer, devops-engineer.

### GĐ14 — Telemetry + dashboard (S–M, 1–2 tuần)

**Mục tiêu:** có số để chỉnh game sau L1; bắt buộc trước beta kín.

**Phạm vi:** viết lại design cho Cloudflare (Analytics Engine + D1), không vendor mới. Sự kiện: funnel (cài → tutorial → run 1
→ 5 run → đăng ký), retention D1/D7/D30, win rate theo Ascension và nhóm người chơi, dùng Aid/Continue theo loại (cảnh báo
khi Continue thắng > 80% A0–A5 / > 60% A6–A10), RTP Nhiệm vụ theo bậc + đầu vào Bayes, tiêu Shard/vé/Stone, thời gian tới
tier Land, RTT xin seed, tỉ lệ `verify_failed`. Không log bí mật, IP chỉ đếm dạng hash. Cập nhật privacy/terms.

**Xong khi:** dashboard hiện đủ các số trên từ dữ liệu beta giả lập; analytics-engineer + security-engineer review.

**Ai:** analytics-engineer, devops-engineer, security-engineer. Skill: `/security-audit`.

### GĐ15 — Bản desktop Windows/macOS + web (M, 2–3 tuần làm; chứng chỉ có thời gian chờ)

**Mục tiêu:** người ngoài tải và chạy được, không bị cảnh báo hệ điều hành.

**Phạm vi:** export preset Windows + macOS (hiện chỉ có preset Web), renderer Forward+/Mobile cho desktop; macOS: Developer ID,
hardened runtime, notarization, kiểm loopback login; Windows: ký code, installer, kiểm SmartScreen; kiểm phiên bản client với
`SUPPORTED_RULES` (báo cập nhật khi luật bị rút); crash report; định nghĩa "máy chuẩn" desktop. Kênh phát hành theo Q1
(Steam: Steamworks, ticket, trang store). **Web:** giữ song song, COOP/COEP, ngân sách dung lượng (đang ~190 MB trước khi
có Atia + Land), chế độ Land giảm.

**Xong khi:** cài sạch trên một máy Windows và một máy Mac không có công cụ dev: mở không cảnh báo, đăng nhập, chơi hết run;
web chạy trên Chrome/Safari/Firefox desktop; dung lượng tải ghi lại cho cả 3.

**Rủi ro:** tài khoản Apple Developer, chứng chỉ ký Windows, tài khoản Steam cần **thời gian xác minh và tiền** → bắt đầu thủ
tục ngay ở GĐ0, không đợi. Đây là việc tiền/pháp lý: chuẩn bị phương án ở Q1, Liam quyết.

**Ai:** devops-engineer, release-manager, godot-specialist, performance-analyst. Skill: `/release-checklist`, `/perf-profile`.

### GĐ16 — Server P5 gia cố + QA/soak + beta kín (M, 3–4 tuần) — ĐƯỜNG GĂNG

**Phạm vi:** công bố `S_run` + công cụ kiểm cộng đồng, retention tự động (90 ngày, run gắn cờ 6 tháng), chaos test (DO evict,
verifier chết giữa job), load test ~1.000 run đồng thời, xoay khoá thật một lần, pentest nội bộ bằng client sửa đổi trên
staging. QA: soak nhiều giờ trên 3 nền tảng, ma trận nền tảng × chế độ, regression suite. **Beta kín** (người mời, cỡ theo
Q8) với telemetry bật, ít nhất 2 tuần.

**Xong khi:** không còn bug S1/S2 mở; load test đạt mục tiêu; pentest không tìm được cách đổi kết quả dice/thưởng; số beta
so với mục tiêu sim (win rate A0 casual, Continue, RTP Nhiệm vụ) có báo cáo, lệch thì có quyết định chỉnh.

**Ai:** qa-lead (chủ trì), qa-tester, security-engineer, performance-analyst, technical-director.
Skill: `/smoke-check`, `/regression-suite`, `/security-audit`, `/perf-profile`.

### GĐ17 — Checklist ra mắt → L1 playtest công khai (S, ~1 tuần)

**Phạm vi:** viết `production/launch-checklist-l1.md` (thay `web-launch-checklist.md` và `cutover-gate.md`, hai file này là
bản 9/2026 cho port JS → Godot). Gồm: terms/privacy mới (ví, gacha, cược Shard, dữ liệu), bảng odds + pity công khai, giấy
phép asset (Homeland/Atia — mục A3 cũ), cờ 18+ ở server, khoá `RULES_VERSION` + `SUPPORTED_RULES`, monitoring + cầu dao khách,
kế hoạch rollback, kênh hỗ trợ/báo lỗi, thông báo "đây là playtest, tiến trình có giữ/không giữ khi L2" (Gem tặng
reset ở L2, quà mùa giữ), ngày bắt đầu Mùa 1.

**Xong khi:** mọi ô bắt buộc tick, có người ký từng ô; Liam bấm.

**Ai:** producer, release-manager, community-manager, security-engineer. Skill: `/release-checklist`, `/gate-check`.

### GĐ18 — Sau L1: cổng mở bán (L2) và nội dung sau ra mắt (chưa ước tính kỹ)

**L2 có cổng riêng**, chỉ mở khi đủ:
- Liam chọn kênh thanh toán (B8). Nếu bán trên Steam thì phải dùng Steam MicroTxn; Mac App Store bắt IAP; web cần nhà
  cung cấp riêng. ADR thanh toán riêng (technical-director).
- Telemetry L1 đủ để xác nhận độ khó (casual A0 ~40%, sàn Continue, cảnh báo Continue) trước khi thu tiền.
- Pháp lý cho mua tiền thật (cổng 18+ theo vùng, BE/NL cho vé), hoàn tiền/chargeback, reset Gem tặng `playtest_grant` (quà mùa 180 giữ nguyên).
- Pass premium bắt đầu từ mùa 2 (B7).

Nội dung sau L1 (thứ tự đề xuất): Cạnh tranh §8 (B5: sau Nhiệm vụ), tham quan Land (B6, nếu chưa làm), Series 2 hộp mùa,
thêm vùng địch Atia, Echo Market (A10 hoãn), R3 (v1.1).

---

## Ghi chú reviewer (12/10)

Đã sửa trực tiếp trong file: phụ thuộc sai/thiếu của GĐ11, GĐ12, GĐ16; câu "GĐ3 → GĐ6" trên đường găng; epoch seed chuyển lên
bước 1 của GĐ2; hướng xử lý `t_rules_version` trong lúc làm GĐ2; mục tuần tự 6–9; thêm thủ tục chứng chỉ/máy chuẩn vào GĐ0;
staging + schema save vào GĐ4; endpoint Gem tặng vào GĐ11; số liệu web; Q6 và Q9–Q11. Kích thước GĐ2 nới lên 8–12 tuần, GĐ4 nên 5–7,
GĐ6 nên 4–6 (container chạy Godot headless, canary, kênh ký là việc mới hoàn toàn), tổng 30–38 tuần với 3 làn. Những cỡ này là
ước tính của reviewer, producer đo lại sau bước 1 của GĐ2.

## Rủi ro chung (register mức dự án)

| Rủi ro | Khả năng | Ảnh hưởng | Cách giảm | Chủ |
|---|---|---|---|---|
| Băng thông review của Liam là nút thắt (mọi việc chờ Liam duyệt) | Cao | Cao | Gom duyệt theo tuần, mỗi lần một danh sách quyết định có đề xuất | producer |
| Combat batch lớn hơn ước tính | Trung bình | Cao (đường găng) | Thứ tự trong GĐ2, đo velocity sau bước 1 rồi ước lại | lead-programmer |
| Sim bắt đổi luật, không chỉ số | Trung bình | Cao | Sim sớm từng phần bằng bot khi bước 2–4 của GĐ2 xong | systems-designer |
| Thiếu asset boss Atia / anim | Trung bình | Trung bình | Spike 8a sớm, Liam xin asset sớm | technical-artist |
| Web chậm (Compatibility ~10×) và nặng (>190 MB) | Cao | Trung bình | Web không chặn L1 desktop (Q4), chế độ giảm | performance-analyst |
| Thủ tục ký/Steam mất thời gian | Trung bình | Trung bình | Bắt đầu ở GĐ0 | release-manager |
| Playtest không có tiền thật → số Aid/Continue không phản ánh hành vi trả tiền | Cao | Trung bình | Đọc số L1 là cận trên của nhu cầu; chỉnh lại ở L2 | economy-designer |
| Chi phí Cloudflare (DO, verifier container) khi mở công khai | Trung bình | Trung bình | Cầu dao khách, đo số DO mở, load test GĐ16 | devops-engineer |
| Phá account/cloud save hiện có | Thấp | Cao | Mọi ghi qua `SaveStore`; test di cư trên bản sao save thật | technical-director |

---

## Gem tặng ở L1 (Liam chốt cấp Gem miễn phí; con số dưới đây là đề xuất, chờ Liam xác nhận)

- **Cách cấp: theo ngày, bấm nhận, 300 Gem/ngày, số dư Gem tặng tối đa 900.** Cộng thêm quà 180 Gem/mùa trên Pass free
  như thiết kế (2 mốc × 90).
- **Lý do chọn 300/ngày:** đủ cho một Continue boss (180) + vài Aid nhỏ (R2 15, Scout 12, Boon 38) mỗi ngày, tức người chơi
  được thấy đủ các tình huống Aid quan trọng nhất. Nhưng không đủ để mua Continue ở mọi lần thua trong cùng ngày (trần
  6 Aid/run × giá thật vượt xa 300), nên vẫn phải **chọn** lúc nào dùng — đó là hành vi cần đo. Trần số dư 900 (3 ngày)
  để người nghỉ vài ngày không quay lại với kho Gem lớn làm lệch số.
- **Theo ngày thay vì một lần:** một khoản lớn một lần thì tuần đầu tiêu thoải mái, sau đó hết, số đo bị lệch theo thời
  gian; theo ngày cho dữ liệu đều và thêm một lý do quay lại (giống VIP về sau).
- **Reset khi bật store thật (L2): có**, xoá phần Gem tặng (`playtest_grant`) và báo trước từ ngày đầu playtest. Quà mùa
  180 Gem giữ lại vì nó là quà thật của thiết kế. Không reset thì Gem miễn phí thành tiền thật, phá giá Gem lúc mở bán.
- **VIP ở L1:** cho mọi người dùng thử miễn phí 7 ngày một lần để đo lợi ích VIP; hoặc tắt nếu Liam muốn số Aid sạch hơn.
- **Lưu ý khi đọc số:** Gem miễn phí thì người chơi dùng dễ hơn tiền thật, nên tỉ lệ dùng Aid/Continue ở L1 là **cận trên**
  của nhu cầu khi bán thật. economy-designer chỉnh lại trước L2. Số 300/900 chưa sim; economy-designer kiểm lại ở GĐ3.

## Câu hỏi cho Liam (mỗi câu có đề xuất, chưa quyết)

**Q1. Kênh phát hành desktop cho L1: Steam, tự phát hành (tải từ axiedice.fun), hay itch.io?**
Việc này chạm tiền và pháp lý nên chỉ chuẩn bị, Liam quyết. Nó cũng gần như chọn luôn kênh thanh toán L2 cho bản desktop
(Steam bắt dùng MicroTxn), và quyết định có làm danh tính Steam trong GĐ4 không.
- Steam: có sẵn người chơi, cập nhật tự động, danh tính Steam; tốn phí đăng ký app và thời gian duyệt (số cụ thể chưa
  verify); có thể ra dạng Playtest/Early Access hợp với L1.
- Tự phát hành: nhanh, không phí nền tảng, nhưng phải tự lo cập nhật và ký Windows/macOS.
- **Đề xuất: Steam cho desktop (ra dạng Playtest/Early Access), web giữ ở axiedice.fun.** Cần quyết trước GĐ4 để biết có làm
  ticket Steam không; thủ tục bắt đầu ở GĐ0.

**Q2. Ngày Mùa 1.** Mockup đang ghi "kết thúc 30/11/2026" (Liam nhận là ngày tạm). Theo ước tính, L1 khó sớm hơn khoảng
tháng 3–4/2027 (22–28 tuần tính từ giữa 10/2026). **Đề xuất:** Mùa 1 bắt đầu đúng ngày L1, dài 8 tuần (Pass) / 12 tuần (hộp mùa) như thiết kế; ngày 30/11 chỉ
là chữ trên mockup.

**Q3. Chỉnh số sau sim (GĐ3) có tính là bump `RULES_VERSION` lần hai không?** Số nằm trong file luật bị fingerprint nên đổi
số là đổi phiên bản. **Đề xuất:** "một lần bump" áp cho thay đổi luật của combat batch; chỉnh số trước L1 được bump thêm
(chưa có người chơi thật, Liam đã nói reset không đáng lo). Từ L1 trở đi mới khoá chặt.

**Q4. Web ở L1:** Compatibility renderer chậm ~10× và gói web đã ~190 MB (`index.pck`, cộng ~39 MB wasm, đo 12/10) trước khi thêm Atia + Land. Spike Land: 50 Axie ~76 FPS trên M3 Pro
với Forward+; chậm ~10× ở Compatibility nghĩa là web gần như không chạy nổi Land có Axie đi lại.
- (a) Web có đủ, với Land chế độ giảm (ít Axie, không bóng).
- (b) Web ra sau desktop vài tuần.
- **Đề xuất: (a) nhưng không chặn L1** — nếu web chưa đạt ≥ 30 FPS hoặc tải quá lâu thì desktop ra trước, web theo sau.

**Q5. Class Mastery (B4 đã đồng ý), Gene Mutation/FACE_POOL (ticket I chưa ai quyết), tham quan Land (B6) có vào L1 không?**
**Đề xuất:** Mastery sau L1 (đường cong chưa sửa theo ghi chú review, chưa có spec số); FACE_POOL không port, đóng ticket I
(relic set mới đã là trục chiều sâu, Pass v2 không còn mốc `face`); tham quan Land sau L1 (cần snapshot server + kiểm duyệt).

**Q6. Mấy làn chạy song song?** Kế hoạch giả định 3 làn (combat, server, trình bày). Thực tế đang giữ tối đa 2 agent cùng lúc.
**Đề xuất:** 3 làn, mỗi làn một agent, Liam duyệt theo lô mỗi tuần. 2 làn thì L1 lùi thêm khoảng 8–10 tuần.
(Reviewer: điều kiện kèm theo là mỗi làn một worktree git riêng và không chạy test song song; mỗi tuần Liam dành bao nhiêu giờ duyệt
mới là giới hạn thật. Nên hỏi luôn con số đó.)

**Q7. Có làm UI dần theo từng vòng Claude Design không, hay chờ đủ 3 vòng?** Luật hiện tại: có mockup rồi mới sửa `godot/CLAUDE.md`.
**Đề xuất:** sau khi Liam nhận R1 bản sửa thì viết phần "style sheet + combat" của `godot/CLAUDE.md` và bắt đầu theme + HUD
combat; R2/R3 bổ sung sau. Tiết kiệm 3–4 tuần trên làn trình bày. Rủi ro: R2/R3 đổi style sheet → làm lại một ít.

**Q8. Beta kín trước L1: ai, bao nhiêu người, bao lâu?** **Đề xuất:** nội bộ Sky Mavis + ~50 người mời, 2 tuần, telemetry bật;
là cổng để xác nhận số sim trước khi mở công khai.

**Q9. (Reviewer thêm) Gem tặng ở L1:** 300 Gem/ngày, trần số dư 900, bấm nhận; VIP dùng thử 7 ngày một lần; reset phần `playtest_grant`
khi L2. Mục "Gem tặng ở L1" ghi "chờ Liam xác nhận" nhưng không nằm trong danh sách câu hỏi. **Đề xuất:** đồng ý 300/900 và reset ở L2;
VIP thử 7 ngày thì bật, vì cần số đo lợi ích VIP.

**Q10. (Reviewer thêm) Phạm vi L1 của làn trình bày.** Land 3D (GĐ9) + Atia (GĐ8b) + UI v3 (GĐ7c) là phần dài nhất, và web không chạy nổi
Land đầy đủ. Liam đã nói L1 "đủ Land". Có chấp nhận cắt L1 còn: Land nền (mặt đất + nhà là lối vào, tier 1–2, ít Axie đi lại),
còn 6 tier đầy đủ, decor/thú, tham quan sau L1 không? **Đề xuất:** cắt như vậy; đây là cần gạt lớn nhất để kéo L1 gần lại.

**Q11. (Reviewer thêm) Chi phí cố định cần duyệt trước GĐ4:** Workers Paid, môi trường staging (DO, D1, R2 riêng), container cho
verifier, chứng chỉ ký, phí Steam. **Đề xuất:** Liam duyệt một lần theo bảng technical-director + release-manager lập ở GĐ0.
