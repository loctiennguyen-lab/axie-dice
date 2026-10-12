# Kế hoạch sprint L1 — 13/10 → 3/11/2026

> **QUYẾT ĐỊNH LIAM (12/10, tối):** desktop **có đăng nhập Google qua Worker** (S + màn đăng nhập của U) · **Gem lưu trên
> server** · danh sách cắt §4: **chưa duyệt** (Liam hỏi "danh sách đâu", đang gửi lại) · cọc Nhiệm vụ do
> server giữ, Shard/Stone trong save · thưởng Nhiệm vụ client tự báo, đánh dấu chưa kiểm · bắt buộc online · Liam duyệt
> ~8 giờ/ngày (giữ đủ các làn) · app "Axie Dice", `fun.axiedice.game`, 0.1.0 · kênh báo lỗi: Slack riêng + form, người
> nhận Liam · **Cloudflare giữ gói Free** (playtest vài chục người; không nâng Paid, không bắt buộc staging) · không có
> danh sách máy người test — họ tự tải bản desktop.

Trạng thái: ĐỀ XUẤT (12/10) — chờ Liam duyệt

Người viết: producer · 12/10/2026 · Chỉ viết file này, không code, không commit.
Đầu vào: khối "QUYẾT ĐỊNH LIAM (12/10)" ở đầu `production/phase-plan-v1.md` và phạm vi L1 Liam chốt 12/10 (bên dưới).
File này thay phần lịch của `phase-plan-v1.md` cho tới L1. Sau L1, quay lại `phase-plan-v1.md` cho phần còn lại.

---

## 0. Nói thẳng một lần

Theo ước tính ở `phase-plan-v1.md` (đã qua lead-programmer review), phạm vi L1 dưới đây cỡ **nhiều tháng** công nếu làm
tuần tự. Còn 22 ngày. Chạy nhiều làn song song rút được lịch nhưng không rút được việc review (mỗi việc vẫn cần agent
cao cấp khác review và Liam duyệt). Đánh giá của producer: **đủ phạm vi trước 3/11 là không thực tế; ra đúng ngày được nếu
Liam duyệt trước danh sách cắt ở §4 và chấp nhận dùng tới khoảng mục 6–8 của danh sách đó.** Mốc 24/10 là lúc quyết.

**Phạm vi L1 Liam chốt:** đủ 133 relic · toàn bộ quái Atia 3D · server tung xúc xắc bản tối thiểu (RunDO cấp seed cho mọi
run, chưa có verifier container, chưa escrow đầy đủ) · Nhiệm vụ bản đơn giản (N1–N4, cọc Shard trừ lúc tạo run, luật thêm hiện
trước, m cố định, chưa bật Bayes nhưng ghi số liệu) · UI đầy đủ theo Claude Design (R1 đã có, R2/R3 chưa) · Land 3D hub
(tier đầu, không tham quan) · Echo Box (rương ở `godot/assets/echobox/chests/`) · Aid/Continue/VIP trả bằng Gem tặng
300/ngày (trần 900, VIP thử 7 ngày) · Ascension v2, boss clock, attrition.
**Phát hành:** bản tải về macOS + Windows, không ký, cho nội bộ Sky Mavis + ~50 người mời. Web chỉ dự phòng. Không Steam.
Mùa 1 bắt đầu 3/11.

**Không làm ở L1** (đã chốt hoặc theo phạm vi tối thiểu): verifier container, escrow đầy đủ, Bayes m_scale (chỉ ghi số),
N5/N6, điều kiện phụ Nhiệm vụ, tham quan Land, tier Land 2–6 (chỉ hiện giá, có thể chưa nâng — xem §4), Mastery, FACE_POOL,
sim F/G đầy đủ (chỉ sim kiểm tra nhanh bằng bot), ký code, store tiền thật.

---

## 1. Các làn (mỗi làn một git worktree)

Mỗi làn một worktree tách từ `godot-port`, một agent chính. Làn I (tích hợp) là người duy nhất merge vào `godot-port`.
"Sở hữu" = chỉ làn đó được sửa; làn khác cần đổi thì gửi yêu cầu cho làn sở hữu (hoặc làn I nếu là file chung).

| Làn | Việc | Sở hữu (file / thư mục) | Agent chính · review | Skill |
|---|---|---|---|---|
| **I — Tích hợp** | Merge hằng ngày, chạy suite, giữ mức sàn test, cập nhật `FINGERPRINT`, bump `RULES_VERSION`, build RC | `godot/tests/t_rules_version.gd`, `godot/project.godot` (autoload, cài đặt), `godot/tools/run_tests.sh`, `.claude/docs/technical-preferences.md` (mức sàn), nhánh `godot-port` | lead-programmer · technical-director | `/code-review`, `/regression-suite` |
| **A — Luật combat** | Engine theo epoch (Local + Remote, giao diện chung), Ascension A1–A10, boss clock (nhẹ A0, đủ A4, nhanh A9), attrition, Continue kiểu B + hồi 25% từ A6, hook Aid (MON-13), tách map hình dạng/loại + Scout, luật thêm của Nhiệm vụ N1–N4, làm tròn ≥ .5 | `godot/scripts/core/` **trừ** `relic_hooks.gd`, `damage_pipeline.gd`, `save_store.gd` (`reward_generator.gd` của B, nhưng A sửa các điểm epoch seed trước 17/10); `godot/autoload/RunState.gd`; `godot/autoload/ContentDB.gd` (toàn bộ file), `scripts/data_models/run_map_*.gd`; A chèn điểm gọi hook rỗng + state relic trong `combat_engine.gd`/`RunState.gd` cho B | gameplay-programmer + godot-gdscript-specialist · lead-programmer; game-designer trả lời luật | `/dev-story`, `/code-review` |
| **B — Relic** | Ô 8/3, ô nhân G theo Axie (trần ×2,5) + ô A, trần ×2,0 mặt phi sát thương, 8 hook, action mới, pact ở boss, loại trừ `twinfates`, 133 relic, A7/A10 trên phần thưởng, cờ ẩn relic khỏi pool | `godot/scripts/core/relic_hooks.gd`, `damage_pipeline.gd`, `reward_generator.gd`, `godot/autoload/RelicRegistry.gd`, `godot/resources/relics/` | gameplay-programmer (agent thứ hai) · lead-programmer; game-designer kiểm đúng spec | `/dev-story`, `/code-review` |
| **S — Server tối thiểu** | Spike RTT (1 ngày), RunDO cấp seed mọi run, `RemoteEpochSource`/`RunSession` phía client, ghi kết quả run + dữ liệu Nhiệm vụ, sổ Gem tặng + nhận theo ngày (UTC server), ghi cọc Nhiệm vụ lúc tạo run, Workers Paid | `worker/` (src, test, wrangler), `godot/scripts/net/`, `godot/autoload/AccountService.gd` | network-programmer · technical-director, security-engineer | `/security-audit`, `/code-review` |
| **E — Economy + meta logic** | Dữ liệu economy (vé, hộp thường/mùa, pity, đổi trùng, Pass v2, Thưởng ngày, Gem tặng/VIP thử, nhà Nhiệm vụ, m cố định), logic Echo Box, ví client (Shard/Stone/Gem) **qua `SaveStore`** | `godot/autoload/MetaState.gd`, `godot/scripts/core/save_store.gd`, `godot/scripts/meta/` (mới), `godot/assets/data/economy/` (mới); **không** sửa `ContentDB.gd` (xem mục 4 bên dưới) | gameplay-programmer (agent thứ ba) + economy-designer · lead-programmer | `/balance-check`, `/dev-story` |
| **C — Combat 3D + Atia** | Kiểm kê Atia, bảng ánh xạ 27 enemy key (17 thường, 4 elite, 6 boss) → model 3D, cảnh combat 3D, anim theo event `s.ev` | `godot/scenes/shared/CombatStage3D.*`, `BattleBackdrop.gd`, `godot/scripts/data_models/monster_art.gd`, `monster_anim.gd`, `godot/assets/monsters/`, `godot/assets/bosses/`, `godot/assets/atia/` (mới) | technical-artist · art-director; performance-analyst đo | `/asset-spec`, `/asset-audit`, `/perf-profile` |
| **U — UI combat + run flow** | Theme mới từ style sheet R1, HUD combat (intent hợp nhất, clock, attrition, khay đội, Aid tray, Undo, bàn phím), màn thua + Continue, run flow + map 3D (R2), panel reward/shop/event/treasure, result | `godot/scenes/shared/DangoTheme.gd`, `godot/resources/theme/`, `godot/scenes/combat/` (`CombatView.gd`, `Combat.tscn`; `CombatStage3D` là của C), `scenes/shared/` còn lại (`DangoScreen`, `AccountUI`, `MockupAssets`, `UnitPortrait`, `AxiePreview3D`), `scripts/ui/`, `scenes/tutorial/`, `UnitHeadHUD.gd`, `HPBar.gd`, `godot/scenes/run_map/`, `godot/scenes/result/`, `godot/assets/icons/` | ui-programmer · ux-designer + art-director | `/team-ui`, `/ux-review` |
| **L — Land 3D hub** | Land Savannah từ spike (mặt đất mới, camera, Axie đi lại có ngân sách), nhà là lối vào, badge, thay MainMenu làm màn đầu, hiện giá nâng tier | `godot/scenes/land/` (mới), `godot/assets/land/` (mới), `godot/scenes/main_menu/` (`MainMenu.gd`, `TeamSelect.gd`) | gameplay-programmer (agent thứ tư) + technical-artist (chung với C, xếp lịch) · lead-programmer + art-director | `/dev-story`, `/perf-profile` |
| **M — Màn meta** | Run Setup (Portal: thường/Daily/Ranked, Ascension picker), Echo Box (2 tab, rương), Pass v2, nhà Nhiệm vụ, store Gem/VIP (không nút tiền thật), Vault/Codex/Settings/Guides restyle (R3) | `godot/scenes/pass/`, `vault/`, `codex/`, `settings/`, `guides/`, `unlocks/`, `godot/scenes/echobox/`, `missions/`, `store/`, `run_setup/` (mới) | ui-programmer (agent thứ hai) · ux-designer | `/team-ui`, `/ux-review` |
| **R — Build + QA** | Preset macOS + Windows (không ký), build thử từ 15/10, hướng dẫn mở cho người test, kế hoạch QA, soak, báo lỗi | `godot/export_presets.cfg`, script export, `production/qa/`, file hướng dẫn cài | devops-engineer + qa-lead · release-manager | `/release-checklist`, `/smoke-check`, `/bug-report` |
| **D — Thiết kế trực** | Trả lời câu hỏi luật trong ngày, spec gộp combat batch (ngày 13/10), review bản giao Claude Design, viết ghi chú sửa | `design/`, `design/handoffs/` | game-designer, economy-designer, art-director | `/design-review`, `/asset-audit` |

Chín làn code + một làn thiết kế. Liam cho bao nhiêu làn cũng được miễn hiệu quả; nếu thấy khó duyệt kịp, gộp M vào U và L
vào C trước (hai cặp này dùng chung người review).

### Chỗ phải tuần tự (file chung, không cho hai làn sửa cùng lúc)

1. **`FINGERPRINT` của `t_rules_version`** bao cả `scripts/core/` lẫn toàn bộ `autoload/`. Làn A, B, E, S đều đụng tới.
   Luật: **không làn nào tự sửa `FINGERPRINT`**. Làn I tính lại sau mỗi lần merge, và ghi "có đổi kết quả run không".
   Đổi kết quả run (A, B) → bump `RULES_VERSION` (Liam cho bump thêm trước L1); chỉ ví/UI (E, S) → không bump.
   Bump chính: một lần khi gộp combat batch A + B (27/10). Sau đó chỉ bump khi chỉnh số, chậm nhất 29/10. Khoá từ L1.
2. **`MetaState.gd` + `save_store.gd`** chỉ làn E sửa. Mọi ghi save qua `SaveStore`; field meta mới phải sửa
   `MetaState.reload_from_store()`. Làn khác cần field mới thì gửi yêu cầu cho E. Không phá account/cloud save hiện có.
3. **`MainMenu.gd`** chỉ làn L sửa (nó thành Land). Làn M mở màn của mình qua một hàm điều hướng do L cung cấp.
4. **`ContentDB.gd`** (1.042 dòng, một file, một hàm nạp dữ liệu chung): **chỉ làn A sửa** (reviewer sửa: bản cũ chia A/E
   trong cùng file sẽ conflict ở mọi lần merge). Làn E không sửa file này: dữ liệu economy/Pass/unlock mới ra JSON ở
   `assets/data/economy/` và đọc qua `scripts/meta/`; nếu cần một dòng đăng ký trong ContentDB thì gửi A hoặc I.
5b. **Chồng chéo còn lại đã xử (reviewer):**
   - **`combat_engine.gd` ↔ `relic_hooks.gd`:** 8 hook mới của B cần chỗ gọi nằm trong `combat_engine.gd`/`RunState.gd` (của A).
     Ngày 14–16 **A chèn sẵn các điểm gọi hook rỗng** (và state relic trong `_state_dict`/`from_data`), B chỉ viết thân hook.
     B không sửa `combat_engine.gd`.
   - **`reward_generator.gd` (của B) ↔ epoch seed (của A):** epoch seed phải đi qua thưởng/shop/event. A sửa đúng các điểm
     rút ngẫu nhiên đó trong `reward_generator.gd` ngày 14–16 và merge trước 17/10; từ đó mới trả file cho B. **Mọi random mới của
     B (pact, loaded_pick, relic ngẫu nhiên) chỉ viết sau khi `EpochSource` của A đã merge (17/10).** Lịch đã khớp (B làm khung
     14–16, nội dung từ 18/10), nhưng đây là điều kiện cứng, không phải may mắn.
   - **`scripts/data_models/` (`unit.gd`, `relic_def.gd`, `run_map_*.gd`)** không ai ghi tên: `run_map_*` thuộc A, `unit.gd` và
     `relic_def.gd` thuộc B (A gửi yêu cầu cho B). `monster_art.gd`/`monster_anim.gd` vẫn là của C.
   - **`RULES_VERSION` nằm trong `action_log.gd` (của A).** Ngoại lệ có chủ ý: làn I được sửa đúng hằng đó (và `FINGERPRINT`), không sửa gì khác.
   - **`CombatView.gd` + `Combat.tscn` (U) ↔ `CombatStage3D` (C):** U sở hữu `CombatView.gd` và `Combat.tscn`; C sở hữu `CombatStage3D.*`,
     `BattleBackdrop.gd`. Nối hai bên qua **một giao diện viết ngày 13/10**: `CombatStage3D` có hàm/tín hiệu kiểu `play_event(ev)`,
     `get_unit_anchor(uid)` (toạ độ màn hình cho intent/HUD); U chỉ gọi hàm đó. C cần đổi `CombatView.gd` thì gửi U. Không ai
     sửa `Combat.tscn` ngoài U. Cặp này đụng nhau nhiều nhất ở ngày 17–23, nên U + C chốt giao diện trước 14/10.
   - **Chưa ai nhận (reviewer gán):** `scenes/shared/DangoScreen.gd`, `AccountUI.gd`, `MockupAssets.gd`, `scripts/ui/` → làn U
     (M gửi yêu cầu cho U); `scenes/tutorial/` → U; `AxiePreview3D`, `UnitPortrait` → U.
5. **`project.godot`** (autoload mới, cài đặt render) chỉ làn I sửa.
6. **Chạy suite test:** `run_tests.sh` chụp và chép lại save thật trong `user://`, mà mọi worktree trên cùng máy dùng chung
   thư mục `user://` (tên theo `config/name` trong `project.godot`). Chạy hai suite cùng lúc sẽ giẫm nhau.
   Reviewer bổ sung: **khoá phải bọc MỌI lần chạy Godot trong repo, không chỉ cả suite**: một `t_*.tscn` lẻ, `--import`, mở
   editor, tool `record_sample_run`/`verify_run` đều chạm `user://`. Cách làm: khoá bằng `mkdir` nguyên tử (macOS không có `flock`)
   trong `run_tests.sh` + một script bọc `godot/tools/with_lock.sh` cho các lần chạy lẻ, có hạn chờ và dọn khoá chết (kiểm pid).
   Phải có thật trước khi làn nào chạy test (13/10, làn I), không phải "hoặc". Tính trước chi phí: nếu suite chạy N phút
   thì 9 làn xếp hàng thành nút thắt; mỗi làn chỉ chạy test lẻ của file mình trong ngày, suite đầy đủ do làn I chạy sau merge.
   Container Godot Linux (`tools/bin/`) chỉ là phương án nếu khoá không đủ, vì nó cô lập `user://` hoàn toàn. Worker test
   (`node --test`) không chạm `user://`, không cần khoá. Nhớ: lỗi parse làm Godot treo, Mac không có `timeout`.
6b. **`FINGERPRINT` trong worktree của làn:** vì không làn nào được sửa `FINGERPRINT`, `t_rules_version` sẽ **đỏ trong mọi worktree
   đã sửa `scripts/core/` hoặc `autoload/`**. Đây là lỗi dự kiến, không phải bug của làn. Làn I thêm cờ cho runner
   (ví dụ `SKIP=t_rules_version`) để làn chạy được "xanh trừ gate này", và làn I tính lại fingerprint **sau mỗi merge** trên
   `godot-port` (hằng này là dòng conflict chắc chắn, giải bằng cách tính lại, không bằng cách chọn bên nào). Mỗi lần merge ghi
   một dòng "đổi kết quả run: có/không" vào mô tả merge. Mốc 27/10 bump `RULES_VERSION` chỉ là lần bump **của gộp A+B**;
   các merge trước đó cập nhật fingerprint mà không bump (đúng như `phase-plan-v1.md` GĐ2).
7. **Giao diện giữa làn** viết ngày 13/10, trước khi ai code: `EpochSource` (A ↔ S), trạng thái Ascension/clock/attrition/Aid
   mà HUD đọc (A, B → U), API ví/Gem/cọc (E ↔ S ↔ M), enemy key → model (A → C), hàm điều hướng Land (L → M).

---

## 2. Lịch theo ngày

| Ngày | Mốc | Việc chính |
|---|---|---|
| **13/10 T3** | Ngày 0 | Tạo worktree; spec gộp combat batch (D + lead-programmer); viết giao diện giữa làn (§1 mục 7); khoá chạy suite; Liam gửi Claude Design ghi chú R1 + yêu cầu R2 và nhắc lịch R3; S chạy spike RTT; C bắt đầu kiểm kê Atia; Liam xin asset boss thiếu nếu C báo trong ngày |
| 14–16/10 | | A: `EpochSource` + Ascension + clock + attrition. B: khung ô/hook. S: RunDO tối thiểu trên staging. E: dữ liệu economy + Echo Box logic. C: ánh xạ 27 key, dựng 1 trận. U: theme. L: Land từ spike. R: preset mac/win |
| **15/10 T5** | **Build thử đầu tiên** | R: build mac + win (không ký) của bản hiện tại, cài thử trên máy sạch, viết bản nháp hướng dẫn mở. Hạn Claude Design gửi R1 bản sửa |
| **17/10 T7** | Giao diện chạy được | A + B: khung mới merge (sau cờ, luật cũ vẫn chạy); S: client nói chuyện với RunDO trên staging; U: HUD combat bản đầu trên theme mới |
| 18–23/10 | | B: nội dung relic theo lô (giữ nguyên → rework → merge → mới); A: Continue, hook Aid, tách map + Scout, luật Nhiệm vụ; S: sổ Gem tặng, ghi cọc, ghi kết quả; E: Pass v2, Thưởng ngày, Nhiệm vụ meta, VIP thử; C: toàn bộ roster; U: màn thua, Aid tray, run flow (R2); L: nhà nối màn; M: Run Setup, Echo Box, nhà Nhiệm vụ |
| **20/10 T2** | Hạn R2 | Claude Design gửi R2. D review trong 1 ngày, ghi chú sửa gửi ngay |
| **22/10 T5** | Hạn asset boss | Boss Atia thiếu asset phải có ở đây, nếu không thì dùng phương án ở §4 mục 10 |
| **24/10 T7** | **MỐC KIỂM TRA** + hạn R3 | Mỗi làn báo % xong theo danh sách việc. Producer đề xuất mục cắt theo §4, Liam duyệt trong ngày. R3 chưa về → áp §4 mục 6 |
| 25–27/10 | | Hoàn tất. **27/10 T3: gộp combat batch A + B, bump `RULES_VERSION`**, bot chạy kiểm tra nhanh (không crash, win rate A0 không lệch quá xa mục tiêu) |
| **28/10 T4** | **Đủ tính năng** | Mọi làn đã merge. Suite xanh với mức sàn mới. Chỉnh số lần cuối (bump nếu cần) |
| **29/10 T5** | **Code freeze** + RC1 | Từ đây chỉ sửa bug S1/S2, mỗi bản sửa qua làn I. R: build RC1 mac + win |
| 29–31/10 | QA + soak | Soak nhiều giờ trên mac + win, ma trận chế độ (thường, Daily, Ranked, Nhiệm vụ N1–N4, Ascension 0/3/6/9), mất mạng giữa run, cài trên máy sạch, web dự phòng nếu còn giữ |
| **31/10 T7** | RC2 | Build lại với bản sửa S1/S2 |
| 1–2/11 | Dogfood nhỏ | Liam + vài người chơi RC2 thật. Checklist phát hành (hướng dẫn cài, cách báo lỗi, thông báo "Gem tặng reset ở L2", ngày Mùa 1). **2/11 T2: chốt bản phát hành** |
| **3/11 T3** | **L1 + Mùa 1** | Gửi link tải cho nội bộ + ~50 người mời. Theo dõi RunDO, lỗi, số Nhiệm vụ |

Cuối tuần (18–19/10, 25–26/10, 1–2/11) agent vẫn làm; nếu Liam không duyệt được cuối tuần thì việc chờ duyệt dồn sang thứ Hai.

**Build không ký:** macOS — chuột phải → Open, hoặc System Settings → Privacy & Security → "Open Anyway" (hoặc
`xattr -dr com.apple.quarantine`, chỉ ghi cho người rành). Windows — SmartScreen: "More info" → "Run anyway". Làn R viết và
thử hướng dẫn trên máy sạch trước 29/10.

---

## 3. Phụ thuộc bên ngoài

| Thứ cần | Từ ai | Hạn chót | Trễ thì |
|---|---|---|---|
| R1 bản sửa (`NOTE-TO-CLAUDE-DESIGN-R1.md`) | Claude Design (Liam gửi 13/10) | 15/10 | U làm theo R1 cũ + bảng số đúng của review; sửa sau |
| R2 (run flow, map 3D, Aid còn lại, Ascension) | Claude Design | 20/10 | U làm run flow bằng theme mới trên bố cục `run-flow-v2` |
| R3 (meta screens, Run Setup) | Claude Design | 24/10 | §4 mục 6 |
| Cosmetics lượt 2 (21 khung, sửa plate) | Claude Design | 24/10 | L1 dùng 20 plate + 5 khung đã có |
| Asset boss Atia còn thiếu | Liam xin (bên asset) | xin 13–14/10, có trước 22/10 | §4 mục 10 |
| Workers Paid (Durable Object) | Liam bật | 14/10 | S không deploy được RunDO |
| Danh sách ~50 người mời + máy họ (mac Intel/Apple Silicon, bản Windows) | Liam | 24/10 | R không biết phải test trên máy nào |

Cần chốt ngày 13/10 (technical-director đề xuất, Liam xác nhận nếu muốn): ở L1, Shard/Stone/Gem vẫn nằm trong save qua
`SaveStore` (cloud save) như hiện tại, server chỉ ghi sổ nối thêm (Gem tặng, cọc Nhiệm vụ, kết quả run) để đối soát. Ví server
thật làm sau L1. Đây là cách nhanh nhất khớp với "chưa escrow đầy đủ"; đổi lại người test sửa được save — chấp nhận được
với nhóm nội bộ.

---

## 4. Danh sách cắt dự phòng (Liam duyệt trước, áp tại mốc 24/10)

Xếp theo **thứ tự cắt**: mục 1 cắt trước, ít hại nhất. Mỗi mục có điều kiện kích hoạt đo được ở 24/10. Cắt mục nào thì
mục đó vào backlog sau L1, không mất. Producer đoán sẽ cần tới khoảng mục 6–8.

| # | Cắt | Cắt khi (đo 24/10) | Mất gì | Tiết kiệm |
|---|---|---|---|---|
| 1 | **Bỏ bản web khỏi L1** (giữ bản web đang chạy hiện tại, không cập nhật) | R chưa có build web chạy ≥ 30 FPS với Atia + Land | Người không cài được thì không chơi bản mới | Toàn bộ việc tối ưu web |
| 2 | **Tắt VIP thử 7 ngày** (Gem tặng 300/ngày vẫn giữ) | E hoặc M chưa xong VIP | Không đo được lợi ích VIP | ~1–2 ngày E + M |
| 3 | **Hộp mùa sau L1**, chỉ hộp thường | Echo Box hộp thường chưa xong 100% | Mùa 1 không có đồ mùa hiếm ngày đầu (thêm giữa mùa) | ~2–3 ngày E + M |
| 3b | (Reviewer thêm) **Land chỉ tier 1, không có nâng tier/Land Stone sink**, chỉ hiện giá | L hoặc E chưa xong nâng tier | Nâng tier | ~2 ngày L + E |
| 4 | **Nhà Nhiệm vụ không nâng cấp**, chỉ N1–N3 (bỏ N4) | Nhiệm vụ chưa chạy trọn N1 từ đầu tới cuối | Bậc cao nhất | ~1–2 ngày |
| 5 | **Quái thường Atia → giữ sprite Chimera** (elite + boss vẫn 3D) | C chưa xong > 50% quái thường | Trận thường trộn 2D/3D | ~3–4 ngày C |
| 6 | **R3 chưa về / chưa làm kịp → theme mới trên màn meta cũ** (Vault, Codex, Settings, Guides, Pass dùng bố cục cũ, đổi màu/font/plate) | R3 chưa về 24/10 hoặc M chưa bắt đầu màn R3 | Màn meta chưa đúng mockup | ~4–5 ngày M |
| 7 | **Relic chưa xong → ẩn khỏi pool** (cờ trong `RelicRegistry`); tối thiểu: 68 relic giữ nguyên + mọi relic đã qua test | B chưa xong > 80% relic mới | Ít build hơn; pact/duo có thể thiếu | Phần relic còn lại |
| 8 | **Pass v2 → dùng Pass hiện tại**, chỉ đổi phần thưởng bằng dữ liệu (cosmetic, vé, 2 mốc 90 Gem) | E chưa xong đường cong + vòng lặp sau lv30 | Đường cong LoL, vòng sau lv30 | ~2 ngày E |
| 9 | **Land tĩnh**: Land 3D camera cố định, không Axie đi lại; tệ hơn nữa → ảnh render Land làm nền, nhà là nút | L chưa có Land chạy ≥ 60 FPS với nhà nối đủ màn | "Land sống" | ~3–5 ngày L |
| 10 | **Boss/elite thiếu asset → mascot GLB đã có** (`assets/bosses/`: kibo, kotaro, paladill, xia) hoặc sprite Chimera, từng con một | Asset boss chưa có 22/10 | Một số boss không đúng Atia | Theo từng boss |
| 11 | **Tắt Nhiệm vụ ở L1** | Nhiệm vụ còn bug mất cọc sai | Bài test risk-to-earn | ~3 ngày |
| 12 | **Lùi ngày L1** (Liam quyết), hoặc cuối cùng: xúc xắc local + server chỉ ghi log | RunDO không ổn định trên mạng thật | Một trong hai trụ của L1 | — |

**Không cắt** (bảo vệ): cài và chạy được trên mac + win; save không mất (qua `SaveStore`); Ascension + boss clock + attrition
(lõi "game khó"); Aid/Continue bằng Gem tặng (thứ L1 muốn đo); ghi số liệu run + Nhiệm vụ.

---

## 5. Rủi ro chính (nói một lần)

- **Phạm vi lớn hơn thời gian nhiều lần** → danh sách cắt §4 là kế hoạch thật, không phải dự phòng xa.
- **Duyệt là nút thắt:** 9 làn × review agent cao cấp × Liam duyệt. Đề xuất: Liam duyệt theo lô 2 lần/ngày, chỉ những thứ
  người chơi thấy; phần code chỉ cần review agent.
- **Merge chồng nhau** ở `scripts/core/`, `autoload/`, `FINGERPRINT` → luật sở hữu §1 + làn I merge mỗi ngày.
- **Không có sim đầy đủ** → số là số đoán đầu; L1 là chỗ đo. Ghi số liệu là bắt buộc.
- **Claude Design / asset boss trễ** → hạn chót §3, có phương án sẵn.
- **Build không ký** làm người test nản → hướng dẫn thử trên máy sạch trước 29/10.
- Bẫy cũ: lỗi parse làm Godot treo; hai tool replay còn ghi đè save thật (làn I thêm `SaveGuard` ngày 13/10).
