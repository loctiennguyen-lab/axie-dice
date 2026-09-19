# Godot Port — Session State (branch `godot-port`)

> Nguồn nền: `design/gdd/godot-port-rule-spec.md` (luật chơi) + kiến trúc
> `/Users/loc.tien.nguyen/.claude/plans/mellow-scribbling-mochi.md` + UX spec
> `design/ux/combat-screen-shroom-gloom-inspired.md`.

<!-- STATUS -->
Epic: Port Axie Dice Tactics sang Godot 4.7.2 (hướng phát triển CHÍNH; bản JS `main` vẫn live).
Feature: PHASE 2 (asset) — phần lớn đã xong. PHASE 1 (core loop) XONG. Số liệu đo được đầy đủ
  nhất nằm ở `docs/godot-port-inventory.md` (2026-09-18) — ưu tiên hơn số liệu cũ trong file
  này nếu 2 nguồn lệch nhau.
Task: **Vault/Import Axie: bước (a)(b)(c) XONG. Bước (d) lớp mạng BỊ CHẶN bởi một quyết định
  về `api/axie.js` — cần hỏi user. Xem mục A của "BẮT ĐẦU TỪ ĐÂY" ngay dưới.** Đã xong: âm thanh (A),
  94/94 relic (A2), bug quái sinh giữa trận (B2), chân dung thẻ die (C), nền node shop/event (D),
  save/CONTINUE RUN (E), battle pass + unlock ladder + `ascMax` (F), cân bằng lại độ khó
  (ticket B), xem die đối thủ (G), part_faces (H), `axie_to_die.gd` bit-exact (I bước a),
  **preview gene→3D (I bước b)**, **vault store + màn Vault + chốt chặn ranked (I bước c)**,
  **Daily Mission + SAMPLE TEAMS (hàng đợi C #1)**. Suite **30/30**. CHƯA COMMIT GÌ.
  ⚠️ **ĐỪNG đọc câu này thành "hết việc".** Cạn ở đây CHỈ có nghĩa là danh sách đánh số trong
  chính file này đã làm hết — nó chưa bao giờ là bản đồ của cả bản port. Việc còn lại nằm ở
  **`docs/godot-port-gap-inventory.md`** (đo 2026-09-19): Godot phủ 11/22 màn của bản JS, và
  các hệ Vault/tutorial/Codex/leaderboard đều ở 0%. Đọc file đó trước khi kết luận.
  Các QUYẾT ĐỊNH còn treo (khác với việc thi công) được theo dõi ở wayfinder map
  `production/wayfinder/map.md` — ĐỌC trước khi chọn việc kiến trúc/scope tiếp theo. Frontier
  hiện tại (open, chưa claim): A (chiến lược anti-cheat/replay-verify cho combat GDScript),
  B (chạy tools/sim.js lấy dữ liệu re-tune RunMap 18 hàng), C (kiến trúc Vault/Import Axie,
  đang 0%), D (lấy art thật Chimera/boss từ Drive — HITL), E (chọn test framework GUT/gdUnit4
  hay giữ run_tests.sh), I (có port FACE_POOL 55 mặt hay không). H (định nghĩa gate cutover
  vào `main`) đang BỊ CHẶN bởi A.
<!-- /STATUS -->

---

# ⇢ BẮT ĐẦU TỪ ĐÂY (phiên mới đọc mục này trước, phần dưới là lịch sử)

> **BÀN GIAO 2026-09-19.** User sẽ mở phiên mới và gõ *"tiếp tục làm Axie Dice trên Godot"*.
> Mục A dưới đây là thứ cần làm ngay; mục B là nợ; mục C là hàng đợi. Đọc hết 3 mục rồi
> **hỏi user trước khi ghi file đầu tiên** (giao thức bắt buộc, xem mục 3 "Luật bất biến").

## A. Vault/Import Axie — **XONG CẢ 4 BƯỚC 2026-09-19**. Việc tiếp theo: polish UI/UX.

> **CHỐT 2026-09-19 — ĐỪNG làm đường "dán gene code". Đã hỏi, đã đo, đã đóng:
> `docs/architecture/adr-0003-axie-import-stays-id-only.md`.**
> Game projectrogue.fun (cũng là Godot web export) có 2 đường nhập: ID **và** dán gene 512-bit.
> Đo thử xem mình có làm được không: `probe_part_map.gd` trên 16 Axie thật → 96 dòng, 66 khoá,
> **0 xung đột theo tên part** ⇒ *làm được về mặt kỹ thuật*. Vẫn KHÔNG làm, vì bảng ánh xạ phải phủ
> **285** mục mà chỉ harvest được dần: một bảng thiếu sẽ đẩy part chưa có vào `fallback_face()`, tức
> **cùng một con Axie nhập bằng ID và bằng gene ra hai bộ xúc xắc khác nhau, không lỗi gì cả** —
> đúng loại sai lệch tất định mà hệ replay-verify (điều kiện merge vào `main`) phải bác bỏ.
> `technical-director` / `producer` / `security-engineer` đều kết luận như nhau: dồn sức vào
> **anti-cheat (frontier A)** và các màn còn thiếu. Việc tiếp theo được cả ba xếp #1:
> **nhật ký action cho ranked + test tự-replay** (hàng đợi C #2) — nó cần cho CẢ 6 phương án
> anti-cheat nên làm trước là không thể phí.


Import Axie thật đã chạy đầu-cuối, **không đụng một dòng nào của bản JS**.

| Bước | Trạng thái |
|---|---|
| (a) `axie_to_die.gd` — thuật toán thuần + test bit-exact với JS | ✅ **XONG** (`t_axie_to_die`, 627 check) |
| (b) preview 3D từ GENE | ✅ **XONG 2026-09-19** (`t_axie_gene_preview`, 424 check) |
| (c) lưu vault trong `MetaState` + màn Vault | ✅ **XONG 2026-09-19** (`t_vault`, 262 check) |
| (d) lớp mạng | ✅ **XONG 2026-09-19** (`t_axie_api`, 67 check) |

### Bước (d) — `godot/scripts/net/axie_api.gd`

**Godot gọi `curl` của HỆ ĐIỀU HÀNH.** Nghe lạ, nhưng nó là client DUY NHẤT qua được — đo hết,
không đoán:

| Client | Kết quả (đo 2026-09-19) |
|---|---|
| Trình duyệt (bản JS) | CORS chặn — chính là lý do `api/axie.js` tồn tại |
| Node `fetch()` trong proxy | Cloudflare chặn — comment trong file ghi rõ |
| **Godot `HTTPRequest`** | **HTTP 403**, body là trang "Just a moment..." của Cloudflare |
| **`curl` gọi từ Godot** | ✅ **200, dữ liệu thật** |

Bản JS giải bài toán y hệt theo cách y hệt — hàm serverless của nó cũng shell ra `curl`, chỉ khác
là chạy trên server. Bản port làm tại máy, vì proxy live phục vụ người chơi thật và không phải thứ
của mình để sửa cho một tính năng chỉ build này cần.

> **`newGenes`, KHÔNG PHẢI `genes`.** Cả hai trường đều tồn tại, đều trả chuỗi hex — đó mới là chỗ
> nguy hiểm. `genes` là format **256-bit cũ** (66 ký tự); `newGenes` là **512-bit** (130).
> `AxieDescriptor.from_genes()` là decoder 512-bit: đưa chuỗi ngắn vào nó **KHÔNG báo lỗi** — nó
> giải ra rác và dựng một con Axie trông rất tự tin và rất sai. Đã ghim trong `t_axie_api` bằng
> chuỗi thật của Axie #123, đối chiếu với golden của addon.

### Web deploy — user hỏi đúng, và ĐÃ VÁ

User hỏi "deploy online thì Vault sẽ lỗi à?" — **đúng**, và vì HAI lý do độc lập: web export không
có `OS.execute` (không chạy được `curl`), VÀ trình duyệt gọi thẳng gateway thì **CORS chặn**. Trong
browser không có đường vòng nào: bắt buộc phải có server.

`AxieApi` giờ có **hai transport**, `active_transport()` chọn theo NĂNG LỰC THẬT của build:

| Build | Đường | Cần deploy |
|---|---|---|
| Desktop | `curl` cục bộ | không gì |
| Web | `HTTPRequest` → proxy | 1 file |

> Desktop có curl thì **vẫn ưu tiên curl** kể cả khi đã cấu hình proxy — đường đó không cần server
> nào phải sống, không tốn băng thông, không phụ thuộc deploy có mới hay không.

**`godot/server/axie-proxy.js` + `README.md`** — sẵn để deploy. **Cố ý đặt NGOÀI `api/`** để nó
không tự deploy kèm bản JS; user chủ động chọn bỏ vào đâu. Cấu hình bằng project setting
`axie/proxy_url` hoặc `AxieApi.set_proxy_url()`.

**Đã kiểm chứng proxy chạy thật** (gọi thẳng handler bằng Node, không chỉ đọc code): #123 và
#11778888 → HTTP 200, `genes` **130 ký tự**; `abc`/`0` → 400. (CORS: từ 2026-09-19 proxy
**không** gửi `*` nữa — mặc định không header, cross-origin thì khai báo qua biến môi trường
`AXIE_PROXY_ALLOWED_ORIGIN`. Xem `godot/server/README.md` mục CORS và ADR-0003.)

> **ĐÍNH CHÍNH 2026-09-19 (đo lại trên gateway thật) — đoạn cũ ở đây SAI, và cái sai đó đã sinh ra
> một lỗi thật.** Nó ghi: ID không tồn tại "KHÔNG trả axie null", nên 502 vừa nghĩa là sai ID vừa
> nghĩa là dịch vụ hỏng, "không có cách nào phân biệt từ phía client". Thân phản hồi thật:
>
> ```json
> {"data":{"axie":null},"errors":[{"message":"Internal Server Error","path":["axie"],
>  "extensions":{"type":"INTERNAL_SERVER_ERROR"}}]}
> ```
>
> `data.axie` **có mặt và bằng null** ngay trong cùng response — phân biệt được hoàn toàn. Cả hai
> lớp của mình chỉ đơn giản đọc phong bì sai thứ tự: `axie_api.gd` và `axie-proxy.js` đều thoát ở
> `errors` TRƯỚC khi nhìn `data`, nên gõ nhầm một chữ số thì người chơi nhận "The Axie service
> rejected the request" / 502 thay vì "No Axie with that ID". **Đã sửa cả hai**: `data` quyết định,
> `errors` chỉ lên tiếng khi `data` không mang trường `axie` nào. Đo lại sau khi sửa (gọi handler
> thật, không đọc code): `123` → 200 Plant · `11778888` → 200 Dusk · `999999999` → **404** ·
> `abc` → 400. Gate mới: `test_a_typo_is_named_a_typo_even_though_the_gateway_also_reports_an_error`
> — chạy trước khi sửa thì ĐỎ đúng 2 chỗ.
>
> Lỗi này lộ ra khi đối chiếu với projectrogue.fun (bản Godot web export của Jaastster): proxy của
> họ trả `{"data":{"axie":null}}` HTTP 200 cho ID không tồn tại, tức họ đọc `data` trước.

`AxieApi.is_available()` báo tình trạng và màn Vault ghi lý do **lên màn hình** thay vì im lặng
hỏng. `t_axie_api` **98 check**, phủ cả hai transport và ghim rằng chúng cho ra **bản ghi giống
hệt nhau** — để màn hình không bao giờ phải biết Axie đến từ đường nào.

> **BẪY: truyền payload qua argv làm `OS.execute` hỏng** (curl exit 2), lặp lại 100%, trong khi
> payload ngắn thì chạy. Ghi payload ra file rồi `-d @path` thì chạy ổn định — và tiện thể query
> không lộ ra process list.

> **BẪY: `--script` mode KHÔNG nạp autoload.** Probe live đầu tiên viết dạng `--script` nên
> `ContentDB` không tồn tại, `AxieToDie` không compile, và **nửa phần xúc xắc của probe im lặng
> không bao giờ chạy**. Đã chuyển thành scene (`tests/probe_axie_live.tscn`).

**Kiểm chứng đầu-cuối trên Axie THẬT** (`probe_axie_live.tscn`): #123 → Plant, gene 130 ký tự, rig
6/6 part, die HP 12 purity 3. #11778888 → **Dusk** → `cls=reptile secret=dusk` (map secret-class
đúng luật), rig 6/6, die HP 12 purity 5. Ảnh: `2026-09-19_vault-import-*.png`.

> `t_axie_api` **KHÔNG gọi mạng** — `test-standards.md` cấm test phụ thuộc trạng thái ngoài. Nó
> kiểm phần thuần (validate / dựng query / đọc phản hồi) bằng payload đóng hộp. Muốn kiểm endpoint
> thật thì chạy probe opt-in ở trên.

### Bước (c) đã làm gì (2026-09-19)

- `MetaState`: `VAULT_MAX=20`, `VAULT_SCHEMA=2`, `VAULT_KEY_PREFIX`, `vault_import()`,
  `vault_remove()`, `vault_stale()`, `vault_key()`, `vault_index_of()`, `vault_entry()`,
  `vault_is_full()`, `ensure_vault_heroes()`, `team_has_vault_pick()`, + bộ ép kiểu JSON riêng
  cho bản ghi vault.
- `RunState.start_new_run()`: **chốt chặn ranked** — đội có key `vault_*` thì hạ ranked xuống
  false (giống JS `if(hasVault) pickRanked=false;`).
- `godot/scenes/vault/VaultView.gd` + `Vault.tscn` — màn Vault: danh sách, preview 3D từ gene,
  dải 6 mặt, badge RE-SCAN, nút REMOVE, trạng thái đầy. Nút VAULT trên MainMenu.
- `godot/tests/t_vault.gd` + `.tscn` — **262 check**, suite 28→29.
- `godot/tests/qa_vault_screen_capture.gd` + `.tscn` — ảnh bằng chứng, **tự trả lại vault của
  người chơi** sau khi chụp (vault là file save thật, không phải test double).

> **Ô import CỐ Ý bị khoá, và LÝ DO ghi thẳng trên màn hình** — không phải tooltip, không phải
> ẩn đi. Nút bấm được mà không làm gì đúng là lỗi dự án này đã ship một lần rồi.

> **BẪY ĐÃ MẮC VÀ ĐÃ SỬA #1 — API đầu tiên của chính tôi có lỗ hổng, test bắt được.**
> `vault_add(die, parts = [])` nhận die và manifest part là HAI tham số: caller có thể ghép die
> của Axie A với part của Axie B, và caller quên tham số thứ hai thì ghi ra bản ghi **không thể
> re-derive ngay từ lúc sinh** — đúng trạng thái mà schema-1 bị kẹt — mà không lỗi gì. Đổi thành
> `vault_import(axie_data)`: một payload vào, một bản ghi ra, không có cách nào ghép sai hai nửa.

> **BẪY ĐÃ MẮC VÀ ĐÃ SỬA #2 — `set_genes()` gọi trước khi node vào cây thì preview im lặng
> không dựng gì.** Màn Vault dựng từng hàng thành cây rời rồi mới add — cách dựng list bình
> thường. `AxiePreview3D._ready()` chưa chạy ⇒ `_stage` null ⇒ 4 dòng
> `Cannot call method 'add_child' on a null value` mà test XANH lướt qua. Sửa ở component (hoãn
> lại tới `_ready()`), không ở chỗ gọi. `run_tests.sh` grep `SCRIPT ERROR` nên nó SẼ đánh trượt —
> nhưng chỉ khi chạy qua runner, không khi chạy lẻ.

> **BẪY ĐÃ MẮC VÀ ĐÃ SỬA #3 — `<NULL>` in ra màn hình.** `secret_cls` là `null` (khớp JS
> `secretCls: null`, `t_axie_to_die` đang ghim, KHÔNG được đổi). `str(null)` trong GDScript ra
> chuỗi `"<NULL>"` — **không rỗng** — nên hàng in "<NULL>" chỗ tên class và bật badge ◈ SECRET
> cho MỌI Axie. `t_vault` xanh suốt: nó kiểm hàng có tồn tại, chưa bao giờ kiểm hàng NÓI GÌ.
> Chỉ ảnh chụp mới thấy. Đã thêm `_optional_string()` + gate quét MỌI Label tìm
> `<NULL>`/`NaN`/`undefined` (luật UI của bản JS, `tools/verify.mjs`).

**Xác minh**: 4 injection vào store (bỏ chốt ranked / bỏ ép kiểu JSON / cho vault đầy tự cắt bớt
/ cho bản ghi stale thành playable) ⇒ 2, 11, 3, 1 lỗi đỏ; injection khôi phục bug `<NULL>` ⇒ 4 lỗi.
Ảnh: `production/qa/evidence/2026-09-19_vault-screen-{01_empty,02_populated}.png`.

### Bước (b) đã làm gì (2026-09-19)

3 file mới, không đụng file cũ nào:

- `godot/scripts/core/axie_gene_preview.gd` — `AxieGenePreview.inspect(genes)`: giải mã gene,
  hỏi catalog từng part resolve được không, trả report đầy đủ + `warning_text()` cho badge.
  Không render, không cần màn hình ⇒ **gate headless ghim được con số**.
- `godot/scenes/shared/AxiePreview3D.gd` + `.tscn` — `Control` hiện Axie sống, chạy Idle.
- `godot/tests/t_axie_gene_preview.gd` + `.tscn` — **420 check**, suite 27→28.
- `godot/tests/qa_vault_preview_capture.gd` + `.tscn` — ảnh bằng chứng (chạy KHÔNG `--headless`).

> **DÙNG `AxieAvatarRenderer` CỦA ADDON, ĐỪNG TỰ DỰNG SUBVIEWPORT.** Kế hoạch đầu của tôi là
> chép `tools/render_portraits.gd`. Sai. Addon đã ship sẵn `AxieAvatarRenderer` +
> `AxieAvatarRenderParams` (port từ Unity), và `third_party/…/examples/avatars_demo.gd` chính là
> đúng ca này — Axie từ gene vào `TextureRect`, cả tĩnh lẫn realtime. Tự dựng là nhân đôi addon
> và lệch khỏi quy ước khung hình mà mọi công cụ Axie khác render theo.
> (`render_portraits.gd` giữ đường riêng vì lý do khác: nó **bake PNG offline** cho 6 rig class
> cố định, không phải xem trực tiếp một Axie bất kỳ.)

> **ĐÍNH CHÍNH con số của bàn giao trước: KHÔNG phải "54/60 part, 90%". Đo thật: 9/10 Axie dựng
> trọn vẹn, và 54/54 part giải mã được đều resolve — kit phủ 100% part của gene thật.** Sáu part
> "thiếu" kia là part ảo của sample #1, mà gene của nó đúng nghĩa là `0x0` và vendor đánh dấu
> `skip` / `skip_reason: "short_genes"`. Không có lỗ hổng coverage nào; có một sample không có
> gene. Câu chuyện "variant 00 kit không ship" là *hệ quả* của việc giải mã gene rỗng, không phải
> nguyên nhân độc lập.

> **BẪY ĐÃ MẮC VÀ ĐÃ SỬA #1 — quy tắc độ dài gene là SAI.** Tôi viết "gene thật luôn 128 chữ số
> hex, ngắn hơn là bị cắt cụt". Probe đo trên golden: 3 Axie THẬT (#1000, #42, #777) có `len: 117`
> mà giải mã hoàn hảo — body, màu, cả 6 part khớp golden. Gene là một **số lớn** viết dạng hex nên
> số 0 ở đầu đơn giản là không có (`_parse_genes` đọc ngược từ chữ số cuối đúng vì lý do đó).
> Tức code của tôi đang dán nhãn "gene hỏng" lên Axie hoàn toàn bình thường. Gene bị cắt cụt là
> **không thể phân biệt** với gene nhỏ hợp lệ — bỏ hẳn heuristic đó; giá trị duy nhất thật sự
> rỗng là số 0, và nó được bắt trước khi giải mã.

> **BẪY ĐÃ MẮC VÀ ĐÃ SỬA #2 — hai preview đứng cùng chỗ thì trộn hình vào nhau.**
> `AxieAvatarRenderer` cô lập bằng **render layer**, và mọi preview dùng CHUNG một layer trong
> CHUNG một World3D. Bốn preview đặt cùng toạ độ ⇒ camera của mỗi cái nhìn thấy cả bốn con và vẽ
> chồng lên nhau. Report vẫn nói "Fuzzy, colour 4, 6/6 part" trong khi ảnh là 4 Axie trộn làm một
> — **số đúng, con vật sai, không lỗi ở đâu cả**. Chỉ nhìn ảnh mới thấy. Đã sửa bằng free-list
> cấp ô (`STAGE_SPACING`), và gate `test_two_previews_never_share_a_stage()` khoá đúng cơ chế đó
> (khôi phục bug ⇒ 4 lỗi đỏ).

> Preview đứng ở `STAGE_ORIGIN` (y = -1000) và đèn key bị giới hạn `light_cull_mask` về avatar
> layer. Cả hai đều cần: viewport của renderer dùng chung World3D gốc (bắt buộc, đó là cách nó
> thấy nhân vật), mà layer 20 nằm TRONG cull mask mặc định của Camera3D — nên preview mở trong
> cảnh có camera 3D sẽ đẻ ra một con Axie đứng cạnh quái. Đèn directional thì không có vị trí,
> nên lùi xa không cứu được nó; phải cắt bằng cull mask.

**Xác minh**: 3 injection vào logic (chấp nhận gene rỗng / mọi part tự nhận resolve / lệch 1 ở
variant) ⇒ 5, 4, 54 lỗi đỏ; injection khôi phục bug chồng hình ⇒ 4 lỗi đỏ. Ảnh:
`production/qa/evidence/2026-09-19_vault-preview-from-genes.png` — 4 Axie khác hẳn nhau + ô gene
rỗng hiện badge "No gene data for this Axie."

Gene test có sẵn, không cần mạng:
`third_party/godot-axie-mixer-3d-main/tests/goldens/sample_axies.json` — 10 Axie thật kèm
gene, kèm cả body/color/parts kỳ vọng để đối chiếu.
(Bản zip user gửi lại 2026-09-19 đã `diff -rq` với `third_party/` và cả 3 addon trong
`godot/addons/`: **0 khác biệt** — đang dùng đúng version.)

## A2. Daily Mission + SAMPLE TEAMS — XONG 2026-09-19 (hàng đợi mục C #1)

Hai hệ nhỏ, độc lập với mọi quyết định đang treo. Suite 29→**30/30**, `t_guides_daily` **444 check**.

- **Daily Mission**: `ContentDB.DAILY_MISSION_SHARD = 60`, `MetaState.daily_date` +
  `today_utc()` + `claim_daily_mission()`, gọi từ `RunState.end_run()` trên MỌI kết thúc run
  (thắng, thua, bỏ) đúng như JS — buộc phải thắng mới nhận thì nó thành bài kiểm tra kỹ năng,
  không còn là daily. `RunState.daily_mission_granted` cho màn Result hiện dòng đó **chỉ đúng
  ngày nhận**. UTC chứ không phải giờ máy: nút DAILY SEED bên JS dùng cùng chuỗi
  `YYYY-MM-DD`, hai tính năng phải đổi ngày cùng một khoảnh khắc.
- **SAMPLE TEAMS**: `ContentDB.ARCH` (10 mục, chép ĐỦ) + `ContentDB.GUIDES` (4 đội, text chép
  nguyên văn — mỗi dòng `how` nêu tên relic và passive thật, viết lại từ trí nhớ là cách để
  guide giới thiệu một relic không tồn tại trong bản port). Màn
  `godot/scenes/guides/Guides.tscn`, nút trên MainMenu.
- Bàn giao đội dùng `static var MainMenu.pending_team`, **tiêu thụ xong là xoá** — không xoá
  thì lần sau vào menu nó đè lên đội người chơi đã tự sửa.

> **Làm màn SAMPLE TEAMS riêng, KHÔNG chờ Codex.** Bên JS chúng nằm chung `scCodex()` chỉ vì
> dùng chung cái header. Codex (sách luật 10 tab) chưa port và **phải audit lại từng câu** theo
> luật Godot — nó đang nói "12 waves" và mô tả undo kiểu JS, cả hai đều sai ở đây. Bắt 4 thẻ
> độc lập chờ việc đó là vô lý.

> **BẪY ĐÃ MẮC: test gọi hàm có `change_scene_to_file()` thì TREO VĨNH VIỄN, không phải fail.**
> Đổi scene giải phóng chính cây của test ⇒ không còn ai gọi `quit()`. Comment đầu tiên của tôi
> còn ghi "gọi thẳng handler để tránh đổi scene" — sai, handler ĐÓ mới là chỗ đổi scene. Đã tách
> `GuidesView.hand_team_to_menu()` (thuần) khỏi `_on_use_pressed()` (điều hướng).

> **BẪY ĐÃ MẮC: test và công cụ QA làm BẨN file save thật của người chơi.** `MetaState` là
> autoload trên `user://meta_save.json`; gate gọi `end_run()` thật, mà `end_run` đụng
> `runs`/`wins`/`xp`/`best` chứ không chỉ cái đang test. Khôi phục theo danh sách trường viết
> tay là danh sách sẽ lạc hậu. Cả 3 file (`t_vault`, `t_guides_daily`, `qa_guides_capture`) giờ
> **chụp nguyên file save và ghi lại nguyên xi**; đã xác minh bằng `shasum` trước/sau: KHÔNG ĐỔI.
> (2 Axie giả `#123`/`#456` do lần chạy trước khi vá để lại trong save đã được gỡ; backup ở
> scratchpad. `runs`/`xp` bị cộng thêm thì không tách được khỏi số thật nên để nguyên.)

**Xác minh**: 3 injection (daily bỏ chốt ngày / guide trỏ hero không tồn tại / menu không xoá
bàn giao) ⇒ 6, 1, 1 lỗi đỏ. Ảnh: `production/qa/evidence/2026-09-19_{guides,result-daily}.png`.

## A3. Review bằng AGENT — 2026-09-19, và những gì nó bắt được

Đã giao `godot-gdscript-specialist` (review code) + `ux-designer` (review 2 màn) + `art-director`
(quyết màu). **Chúng bắt được thứ tôi không bắt được** — ghi lại để phiên sau đừng bỏ qua bước này.

### BLOCKING #1 (gdscript-specialist) — 20 SubViewport render mỗi frame
`ScrollContainer` của Godot **KHÔNG cull** con nằm ngoài vùng nhìn; `is_visible_in_tree()` vẫn
`true` cho mọi dòng đã cuộn khuất. Vault 20 dòng = 20 lượt render 512×512 **mỗi frame**, cộng 20
lần `AxieAvatarRenderer._tag_visuals()` duyệt lại TOÀN BỘ cây mesh mỗi frame chỉ để ghi lại đúng
bitmask đã ghi frame trước. Sửa: `REFRESH_HZ = 12` + `_is_on_screen()` so global_rect với
`ScrollContainer` tổ tiên (tìm MỘT LẦN trong `_ready()`). Gate mới
`test_an_offscreen_preview_stops_rendering`.

### BLOCKING #2 (gdscript-specialist) — `AxiePreview3D` thiếu `class_name`
`VaultView` giữ preview dưới kiểu `Control` rồi gọi `.set_genes()` — **gõ sai tên method sẽ
compile sạch, `check_syntax.sh` không bắt, chỉ vỡ khi người chơi mở màn Vault**. Đã thêm
`class_name AxiePreview3D` + ép kiểu ở nơi gọi. Gate `test_the_preview_exposes_a_typed_public_api`.
> Lưu ý khi tự kiểm chứng: gỡ `class_name` ra để thử thì test **TREO** (parse error), không đỏ —
> đúng bẫy số 1 của dự án. Đừng nhầm "treo" với "gate không bắt được".

### P0 (ux-designer) — "RE-SCAN NEEDED" ra lệnh làm việc không thể làm
Dòng đỏ đó đọc như hành động cần làm ngay, nhưng SCAN đang khoá vì thiếu lớp mạng, và lời giải
thích nằm tít đầu trang — người chơi cuộn tới dòng 18 chỉ thấy một lệnh đỏ khẩn cấp không làm
được. Đã nối lý do + nêu REMOVE ngay trong chính dòng đó.

### P1 đã sửa
- Ô import khoá giờ mờ cả khối (`modulate` 0.45) — trước đó khung giống hệt card đang sống.
- Card RE-SCAN có **viền DANGER**, không chỉ chữ đỏ.
- Bộ đếm đầy kho thêm chữ **"FULL"**, không chỉ đổi màu (tín hiệu chỉ-bằng-màu).
- Header + nút BACK **tách khỏi vùng cuộn** ở cả 2 màn (`Frame/HeaderRoot` · `Frame/Scroll/
  ContentRoot` · `Frame/FooterRoot`) — trước đó càng nhiều Axie, lối thoát càng xa.

### art-director — dải màu archetype 5px mép trái
Chọn dải trái, **KHÔNG** dùng tham số `border` mới của `panel_style()`: kênh "viền đổi màu" hôm
nay vừa mang nghĩa *trạng thái cần chú ý* (bản ghi RE-SCAN), gán thêm nghĩa *thể loại tĩnh* vào
cùng kênh là trộn hai tín hiệu khác nhau. Cũng không tô nền vì nền `#13161B` rất tối, đổi hue sau
lưng chữ sẽ kéo contrast ra khỏi vùng đã kiểm. Guide thiếu archetype ⇒ **không có dải**, không
phải dải xám.
> Rủi ro còn lại: `ARCH.burn` (#ff9a4d) gần trùng `PRIMARY` (#FF9345, cam CTA). 4 guide hiện tại
> không dùng burn; nếu sau này có, phải soát lại bằng mắt.

### ⚠️ BUG HARNESS tìm được khi sửa: **test bị abort giữa chừng vẫn báo PASS**
Tôi đổi cấu trúc scene, test còn hardcode đường cũ `Scroll/ContentRoot` ⇒ `get_node()` trả null ⇒
SCRIPT ERROR **abort hàm test**, mọi assertion sau đó không chạy, `_failures` rỗng, file báo
**PASS**. Dấu vết duy nhất: số check tụt 262→249, không ai canh.
Đã vá ở cấp harness cho **cả 3 gate mới**: mỗi test gọi `_done("<tên>")` ở dòng cuối, `_ready()`
đối chiếu với hằng `EXPECTED_TESTS` và BÁO ĐỎ nếu thiếu. Xác minh: nhét lại đúng bug đường-dẫn ⇒
`FAIL — test '...' did not run to completion`. **Nên nhân rộng sang các gate cũ.**

## A4. Không gate nào còn đụng file save của người chơi — 2026-09-19

**Đo được trước khi sửa** (chạy từng gate một, `shasum` file save trước/sau): `t_full_run_loop`,
`t_meta_progression`, `t_run_save` đều làm bẩn. Chạy suite = cộng thêm `runs`/`xp`/`best` vào save
thật. `t_meta_progression` còn đáng chú ý: nó ĐÃ có `_restore_meta()` khôi phục 9 trường — nhưng
khôi phục **trong bộ nhớ**, trong khi test đã gọi `save_to_disk()` từ trước đó (qua
`claim_bp_reward()`/`buy_unlock()`), nên FILE vẫn giữ giá trị của test.

**`godot/tests/save_guard.gd` (MỚI)** — `SaveGuard.capture()` / `.restore()`: chụp nguyên văn file
save rồi ghi lại nguyên xi, và `load_from_disk()` lại để phần sau của tiến trình thấy giá trị thật.
Cả **6** gate động tới `MetaState` giờ dùng chung nó (3 cũ + `t_vault`, `t_guides_daily`,
`qa_guides_capture` — 3 cái sau trước đó mỗi cái tự chép một bản `_restore_save()`).

> **Danh sách trường khôi phục bằng tay là danh sách sẽ lạc hậu.** `end_run()` chạm
> `runs`/`wins`/`best`/`daily_date` chứ không chỉ cái đang test, và nó sẽ còn chạm thêm. Chép bytes
> thì không lạc hậu được. Đó là lý do chọn chụp file thay vì liệt kê trường.

**Xác minh**: chạy **từng gate một trong 30 gate**, so `shasum` trước/sau ⇒ **0/30 làm bẩn**; rồi
cả suite ⇒ file save **không đổi một byte**. Suite vẫn 30/30.

> ⚠️ **Save của user đã bị churn trong lúc làm việc này** (trước khi có SaveGuard). Đã dọn 3 Axie
> fixture `#123/#4154/#1000` do `qa_vault_screen_capture` để lại — game KHÔNG thể tự tạo chúng vì
> ô import đang khoá. `runs`/`xp` bị cộng lên rồi lại bị một lần khôi phục snapshot cũ kéo xuống;
> đã đặt về mức CAO NHẤT từng quan sát (runs 6, xp 1095) để user không mất tiến độ, nhưng **một
> phần trong đó là do test của tôi và không tách ra được**. Backup:
> `scratchpad/meta_save.{pre-cleanup,before-final-cleanup}.json`.

## A5. Nút có phản hồi hover/pressed — 2026-09-19 (art-director spec + ui-programmer impl)

Trước đó `DangoTheme` KHÔNG có biến thể hover/pressed nào, và nhiều màn còn ép cả 3-4 state dùng
CHUNG một stylebox. Bấm nút không có tín hiệu thị giác nào.

- `DangoTheme`: enum `ButtonState` + `primary_button_style(warning, state)` /
  `secondary_button_style(state)` + helper **`style_button(btn, primary, warning, font_color)`** áp
  đủ 4 stylebox và 4 khoá font color trong một lời gọi.
- **26 call site** chuyển sang helper: MainMenu 9 · CombatView 9 · VaultView 3 · GuidesView 2 ·
  RunMapController 2 · ResultView 1.
- Gate mới `t_button_states` — **65 check**, suite 30→**31/31**.

> **Quy tắc art-director, không phải "làm sáng lên cho có":** hover chỉ đổi MÀU (sáng lên), không
> đụng hình học. Pressed đổi màu theo hướng NGƯỢC LẠI (tối đi) VÀ đổi hình học (border +1,
> content_margin trên +1 / dưới −1 — tổng bằng 0 nên rect ngoài không đổi). Bất đối xứng này là
> thứ làm hover và pressed phân biệt được **với nhau**, không chỉ mỗi cái khác normal. Disabled
> không bao giờ kế thừa `warning` và không dùng hướng màu của hover/pressed.

> **Nút SCAN của màn Vault trước đó KHÔNG có style nào cả** — xám mặc định Godot. `grep` 6 file
> tôi đưa cho agent không thấy nó (vì nó chưa từng gọi `add_theme_stylebox_override`); chỉ quét
> `Button.new()` rộng hơn mới ra. Bài học: liệt kê call site theo "chỗ đã gọi API" bỏ sót đúng
> những chỗ chưa bao giờ gọi.

**Xác minh**: ép hover trở lại giống normal ⇒ 3 lỗi đỏ, trong đó có
`'normal' and 'hover' states render identically`.

**Lệch khỏi spec, đã ghi rõ** (cần art-director duyệt nếu muốn số chính xác): màu viền disabled
của họ primary và toàn bộ công thức disabled của họ secondary — spec chỉ cho số cho primary.

## A6. Đợt polish UI/UX — 2026-09-19 (user chơi thử: "cực kì xấu và mất thẩm mĩ")

Hai bản audit trước (`production/qa/2026-09-19_visual-polish-backlog.md`,
`..._runloop-ux-backlog.md`), rồi 3 agent sửa song song, mỗi agent **sở hữu file rời nhau**; phần
dùng chung (`DangoTheme`) tôi làm trước bằng tay để chúng không giẫm chân. Suite 32→**35/35**.

**Đã sửa**: camera RunMap · nhãn node lộ ID · shop BOUGHT vs không-đủ-tiền · chip rarity cho cả 4
màn reward/shop/event/treasure · mô tả level-up · ghi chú dev lộ ra menu · 6 section menu có khung ·
max-content-width · scrollbar theo theme · nút FULL khoá có tín hiệu · bóng đổ chân unit · thứ tự
màn Result. Gate mới: `t_runloop_ui` (29) · `t_mainmenu_ui` (12) · `t_result_and_stage` (84).

> **BẢN SỬA CỦA AGENT LÀM HỎNG THÊM, VÀ KHUYẾN NGHỊ CỦA AUDIT CŨNG SAI.** Agent báo "xong" mục
> camera RunMap; chụp lại thì màn hình chỉ còn **5 thẻ "?" khổng lồ, không icon, không nhãn**.
> Công thức là `zoom = box_size / viewport`, mà **Godot 4 `zoom` là HỆ SỐ NHÂN — lớn là phóng TO**;
> nó làm ngược đúng chiều. Agent còn nới trần zoom 1.9→6.5 nên phóng mạnh hơn. Comment nó để lại
> ghi rõ mô hình sai: *"6260 world units … needs zoom~5.8"* — thật ra cần ≈0.17.
> Và audit đề xuất "đưa MỌI node vào khung" — làm thế thì map 18 hàng khiến mỗi node còn ~30px,
> nhìn hết map mà không bấm nổi; đó chính là lý do bản gốc chỉ khung vài node. Lời giải đúng là
> **cửa sổ** (1 hàng sau, 3 hàng trước): không cắt cụt, vẫn đọc được. Cả hai lời giải sai đã ghi
> vào comment để đừng ai thử lại.

> **Agent bác lại audit một cách ĐÚNG, 2 lần.** (a) Đường nối RunMap: bezier-wobble **đã implement
> sẵn** đúng spec, audit dựa trên ảnh cũ — không sửa gì. (b) "Power level 7 / Nodes visited 0" đọc
> mâu thuẫn: hai số này trong gameplay thật **luôn đổi cùng nhau** (`RunState.after_node()`); con
> số 7/0 là do `qa_guides_capture.gd:39` tự set `power_level` để dàn cảnh chụp — artefact của
> script QA, không phải lỗi. Đây là kiểu phản hồi cần có: kiểm rồi nói thẳng, thay vì sửa bừa cho
> khớp backlog.

> **LỖ HỔNG TRONG CHÍNH GATE TĨNH CỦA TÔI — ghi GIÁN TIẾP không bị bắt.**
> `test_no_test_writes_to_the_real_save_without_a_save_guard` tìm lời gọi trực tiếp
> (`RunState.end_run(`…). Nhưng 4 công cụ QA chỉ *nạp `Result.tscn`* — `ResultView._ready()` mới là
> chỗ gọi `end_run()`. Chúng âm thầm cộng shard/XP vào save thật ở mỗi lần chụp. Đã thêm danh sách
> **scene ghi gián tiếp** vào gate và gắn `SaveGuard` cho cả 4. Xác minh: chạy lại từng cái, so
> `shasum` — **0/4 làm bẩn**.
> (Lần trước gate này cũng từng xanh giả vì chỉ tìm chữ "SaveGuard" mà chữ đó nằm trong comment.
> Hai lần liên tiếp cùng một gate lọt vì kiểm quá hời hợt — nếu siết lần ba, siết theo *hành vi*.)

> Chốt chặn abort bắt lỗi của CHÍNH TÔI khi viết `t_result_and_stage`: sai thứ tự tham số
> `spawn_unit()`. Không có nó thì 2 test đã âm thầm bỏ qua nửa số assertion mà vẫn báo PASS.

**Còn lại, cố ý chưa làm**: quái không map Chimera vẫn hiện **capsule trơn** (P0-4 — là gap NỘI
DUNG, cần chốt `docs/art/chimera-monster-art-mapping-2026-09-08.md`, không phải bug hiển thị);
chữ nhãn phụ nhỏ/tương phản thấp (P1-2); ảnh nền thật cho menu (L).

## B. NỢ — chưa làm, đã biết, đừng để trôi

1. **CHƯA COMMIT GÌ CẢ.** Toàn bộ `godot/` vẫn untracked; `git status` ~15 mục. User chưa
   bao giờ yêu cầu commit — **đừng tự commit** (luật bất biến).
2. **`api/axie.js` chưa truy vấn `genes`** — mới có `class` + `parts`. File đó phục vụ bản JS
   ĐANG LIVE, thêm trường là thay đổi production ⇒ phải hỏi user. Hoặc Godot gọi thẳng
   GraphQL Axie và bỏ qua proxy. **Chỉ cần quyết ở bước (d)**, không phải bây giờ.
3. **Chưa có đường rời combat về menu** ngoài nút "Quit" (có xác nhận). Bản JS có
   "SAVE & QUIT TO MENU" trong modal — user đã chọn không làm lúc đó.
4. **4 unlock bán được nhưng chưa có tác dụng**: `u_relic1`/`u_relic2`/`u_face1`/`u_face2`
   (khai trong `ContentDB.UNLOCKS_WITHOUT_EFFECT`, `t_meta_progression` ghim đúng danh sách).
5. **5 mốc Lunacia Pass loại `face` không nhận được** — `FACE_POOL` chưa port (user hoãn tới
   "big update"). Đã cố ý TỪ CHỐI claim thay vì đốt mốc; hiện trên menu kèm lý do.
6. **Chỉ số run-level chưa đếm**: damage/turns/kills/max-hit — màn Result thiếu chúng,
   và `run history` sẽ cần chúng trước.
7. ~~**3 gate CŨ làm bẩn file save thật của người chơi**~~ ✅ **ĐÃ SỬA 2026-09-19** — xem mục A4.
8. **Ô XÚC XẮC và NODE BẢN ĐỒ vẫn không có phản hồi hover/pressed** — `CombatView` (die slot,
   `:450`/`:1849`) và `RunMapController` (`:313`) ép cả 4 state dùng chung một stylebox. CỐ Ý
   để ngoài đợt sửa nút 2026-09-19: art-director chỉ spec 2 họ primary/secondary, còn đây là
   **họ thứ ba** — style của chúng đã mang TRẠNG THÁI GAME (loại mặt xúc xắc, đã dùng/chưa,
   loại node), nên thêm hover phải quyết trước là hover chồng lên tín hiệu trạng thái thế nào.
   Đáng làm: ô xúc xắc là thứ được click nhiều nhất trong game.
9. ~~**Không nút nào trong game có phản hồi hover/pressed**~~ ✅ **ĐÃ SỬA 2026-09-19** — xem A5.
10. **XP cao hơn bản JS ~50%** vì map 18 hàng: công thức port nguyên văn, lệch thuộc về
   quyết định 18 hàng (ticket B đã resolved), không nhét hệ số bù vào hàm tính XP.

## C. HÀNG ĐỢI sau khi xong Vault — thứ tự đã đề xuất, user chưa chốt

Nguồn đầy đủ, đo thật: **`docs/godot-port-gap-inventory.md`** §5. Tóm tắt:
1. ~~**Daily mission** + **GUIDES** (4 đội hình mẫu)~~ ✅ **XONG 2026-09-19** — xem mục A2.
2. **Action log ranked** + test tự-replay — độc lập với MỌI quyết định leaderboard, và nó
   tạo ra bằng chứng thực nghiệm cho cuộc thảo luận đó.
3. **scCodex** (sách luật 10 tab) rồi 3 tab luật của **scInfo** — LỚN, và **phải audit lại
   từng câu theo luật Godot**, đừng chép: codex JS nói "12 waves" và mô tả undo kiểu JS,
   **cả hai đều sai với bản Godot**.
4. **Tutorial** — cuối cụm dạy người chơi, vì nó tiêu thụ scUnitInfo + màn thưởng + step-lock.
   Trigger phải đổi từ "sau đăng nhập đầu" sang "lần chạy đầu trên máy này" (Godot không có
   màn login) — **đây là quyết định thiết kế, chốt với user trước khi viết dòng đầu tiên**.
5. Quyết định wayfinder còn treo: **A** (anti-cheat/replay-verify — cổng chặn merge vào
   `main`; Node VM không chạy được GDScript, 6 phương án đã liệt ở gap-inventory §3),
   **E** (test framework), **D** (art thật từ Drive — cần user), **I** (FACE_POOL — user hoãn).
   **B đã RESOLVED** 2026-09-19.

**KHÔNG làm** (đã quyết, có lý do đo được, ghi ở gap-inventory §2.5): Cosmetics + Echo Box,
World Tour, scGate/login, NFT HP bonus (là code chết trong bản JS), đồng bộ run history.


## 0. Chạy 3 lệnh này trước khi sửa bất cứ gì

```bash
./godot/tools/check_syntax.sh     # preflight cú pháp, vài giây — CHẠY SAU MỖI LẦN SỬA .gd
./godot/tools/run_tests.sh        # toàn bộ suite, phải 27/27
```
Ảnh chụp thật (chạy KHÔNG có `--headless`, nếu không `get_tree().root.get_texture()` trả null):
```bash
/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot --path godot res://tests/qa_real_flow_capture.tscn
/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot --path godot res://tests/qa_boss_check.tscn
```
Ảnh ra ở `production/qa/evidence/`. **Luôn Read lại ảnh và tự đánh giá** — nhiều lỗi UI chỉ
nhìn mới thấy, test không bắt được.

> ⚠️ **Bẫy tốn nhiều giờ nhất của dự án này**: lỗi parse GDScript **KHÔNG** làm Godot báo lỗi.
> Script không load → `_ready()` không chạy → không ai gọi `quit()` → process chạy vô hạn.
> Nó **trông y hệt test bị treo**. Luôn ghi output ra file rồi đọc, đừng pipe qua `head`.
> `check_syntax.sh` bắt được trong vài giây — đó là lý do nó tồn tại.

## 1. Việc tiếp theo, theo thứ tự ưu tiên

### (A) Nối âm thanh vào combat — ĐÃ XONG (2026-09-18)
`godot/scenes/combat/CombatAudioDirector.gd` (MỚI) là node con của CombatView, tự nghe
EventBus. Không đọc state game, không tiêu RNG, không quyết định kết quả nào.

- Ánh xạ: `face_used`→đòn đánh (giọng × bộ phận) + cue theo type · `hit_landed`→pha `hit`
  (chỉ khi kit có ghi thật) + `power_gain` khi crit · `unit_died`→`death_mark` ·
  `boss_phase_changed`→`power_awaken` · `status_tick`→cue theo từng status đã resolve.
- Bus `Music`/`SFX` tạo lúc chạy (project không có `default_bus_layout.tres`); mute + 2 mức
  âm lượng lưu trong `MetaState` (`audio_music_volume`/`audio_sfx_volume`/`audio_muted`).
  Nút "Sound: on/off" dựng BẰNG CODE vào ButtonsRow — `Combat.tscn` KHÔNG bị sửa.
- `disable_juice_for_tests` được đọc MỘT LẦN trong `_ready()`: không dựng player nào, không
  connect signal nào. Cố ý — cờ kiểm ở từng chỗ phát có thể bị lật giữa test và bắt đầu kêu,
  còn máy CI không có thiết bị âm thanh thì ngay từ đầu đừng đưa stream cho nó.

> **LỖI THẬT tìm được khi nối, đừng để tái diễn**: nối "đúng brief" thì MỌI QUÁI SẼ CÂM.
> `ContentDB._load_enemies()` không set `cls` cho quái nào (`Unit.cls` mặc định `""`), mà
> `face_sfx_path()` trả `""` ngay dòng đầu khi class rỗng → 27/27 quái+boss im lặng, tức một
> nửa số đòn trong trận. `t_assets` KHÔNG bắt được vì nó chỉ lặp qua 6 class hero có thật —
> nó chứng minh "fallback theo type chạy được", chưa bao giờ hỏi "quái lấy class ở đâu".
> Sửa: `CombatAudio.monster_voice_class()` suy giọng từ **sprite Chimera con quái đang mặc**
> (`MonsterArt.sprite_name_for()`), theo tiền tố tên kit — `aqua-*`→aqua,
> `dryad-/treant/forest-/flowering-*`→plant, `*wolf/*bear`→beast. Chọn cách này thay vì bảng
> tay vì nó tự đồng bộ với art: đổi sprite là đổi tiếng theo, người chơi nghe đúng thứ đang
> nhìn. Phân bố thực tế đo được: plant 12 / aqua 6 / beast 9.

> **Bẫy đã mắc trong chính phiên này**: chèn hàm mới vào GIỮA `_connect_ui_buttons()` làm
> phần đuôi của nó (nối 6 nút die + dựng style thẻ die) rơi vào hàm kế tiếp. `check_syntax.sh`
> KHÔNG bắt được — cú pháp vẫn hợp lệ, chỉ là sai hàm. Sau khi chèn code vào giữa file, phải
> đọc lại BIÊN của hàm bị chèn, đừng tin mỗi syntax check.

**Kiểm chứng** (chạy có renderer, không phải tự đánh giá): 9 player dựng ra, nhạc
`pve_2.wav` đang phát, 9 giọng đăng ký (5 hero + 4 quái), bus Music/SFX ở idx 1/2 @
-8.0/-2.0 dB, một `face_used` ra `plant_bite_attack.wav`.

**Test mới `t_combat_audio_wiring` (296 check)** — khoá bất biến trên NỘI DUNG chứ không
trên file: mọi quái + mọi boss `ContentDB` sinh ra được đều phải ra file âm thanh có thật;
pha `hit` không rơi ngược về `attack` (nếu không mỗi đòn cận chiến kêu 2 lần); mute có thật
tới bus chứ không chỉ ghi vào save; director im tuyệt đối ở test mode.

> **LỖ HỔNG CÓ SẴN phát hiện dọc đường, CHƯA sửa (ngoài phạm vi)**: quái sinh GIỮA trận
> (`combat_engine.gd:914` và `:1390` — SPLIT của gooey_king, `startSummon`) không có
> nameplate, thanh máu, status pill, và cũng không có giọng — vì `CombatView` chỉ dựng chân
> dung một lần trong `_ready()`. Chỗ sửa đúng là nơi dựng chân dung, gọi luôn
> `_audio.register_unit()`. Đã ghi chú trong `CombatAudioDirector.gd`.

### (A2) Author 94/94 relic — ĐÃ XONG (2026-09-18)
Từ 20/94 lên **94/94**. `godot/resources/relics/` giờ có 95 file (94 relic + pseudo-relic
`__curse_dmg`). Sinh bằng script đọc thẳng `src/data.js`, không gõ tay, không đoán số.

- **Trường `description` MỚI trên `RelicDef`.** Text mô tả trước đây nằm trong dict viết tay
  `RELIC_DESC` bên trong `reward_generator.gd` — tức relic và lời của nó ở 2 file khác nhau và
  có thể lệch nhau. Giờ text nằm ngay trong `.tres` của chính relic đó; không thể thêm relic
  mà quên text. `reward_generator.relic_desc(def)` là chỗ đọc duy nhất.
- **48/74 relic cần HÀM GDScript, không phải chỉ điền dữ liệu.** Tài liệu cũ nói phần còn lại
  "chỉ là AUTHOR dữ liệu" — đúng với 26 (16 active card + 10 passive thuần), **sai với 48**
  (23 `modFace` + 25 hook `onTurnStart`/`onKill`/`onHit`/`onShield`/`onThorns`/`onRollEnd`/
  `modDmg`/`onDmgTaken`/`growthAllGuard`). Rào KIẾN TRÚC đúng là đã gỡ; thân hàm thì chưa.
  Tất cả 48 hàm giờ đã có trong `RelicHooks.TABLE`, chép từ thân JS chứ không từ mô tả.

> **BUG CÓ SẴN đã sửa nhân tiện — `sort_index` sai ở 17/20 relic cũ.** Công thức là
> `phase*100000 + rarity*1000 + vị trí trong RELICS[]`, nhưng 17 file lệch đúng 1 đơn vị.
> Kiểm chứng: `src/data.js` chưa từng đổi (giống hệt `main`, không sửa từ commit `6c2e4dc`)
> → chúng bị viết sai ngay từ đầu, không phải do dữ liệu trôi. Nó VÔ HẠI cho tới hôm nay vì
> không relic nào trong 20 cái đó dùng `modFace`; nhưng `sort_index` chính là khoá phá hoà của
> INV-5, và vừa thêm 23 relic `modFace` là nó có hiệu lực ngay. Đã sinh lại cả 94.

> **BẪY: test wiring KHÔNG thay được test hành vi.** Sau khi thêm 74 `.tres` với `hook_key`
> trỏ tới entry CHƯA TỒN TẠI, cả suite 19/19 vẫn xanh — 48 relic hoàn toàn trơ mà không lỗi,
> không cảnh báo. Và ngược lại: `t_relic_completeness` xanh trong khi `r_broodmother` đang gọi
> `Unit.set_used()` — một hàm KHÔNG tồn tại (tên thật `mark_used()`). GDScript chỉ phát hiện
> lúc gọi, trên biến không khai kiểu, nên cả `check_syntax.sh` lẫn test wiring đều mù. Phải có
> cả hai loại test.

**2 test MỚI:**
- `t_relic_completeness` (533 check) — mọi `hook_key` phải có entry thật trong TABLE, và entry
  phải khai đúng bộ event mà `src/data.js` khai; không entry nào mồ côi; mọi relic phải có mô
  tả; `sort_index` phải phân tách được; cả 16 active card phải có `kind` mà `play_active()`
  thật sự dispatch.
- `t_relic_behaviour` (169 check) — SỞ HỮU relic rồi chạy `CombatEngine` thật, đòi hỏi có KHÁC
  BIỆT quan sát được. Bắt được `set_used` không tồn tại. Kiểm số cụ thể cho `r_claw`,
  `r_ancientgene` (ceil, blank vẫn là blank), `r_heart`, `r_bloodpact` (sàn 4),
  `r_thousandcuts`, 3 relic mana (chỉ lượt 1), `r_regrow`/`r_scalecrown` (sàn chứ không cộng
  dồn), và INV-1: `r_claw`+`r_ancientgene` ra kết quả GIỐNG NHAU bất kể thứ tự nhặt.
  > Roster của test dùng `bird1` thay `bug1` **có chủ đích**: `r_cleaveall`/`r_marrowdrill`/
  > `r_thousandcuts` chỉ tác động lên mặt ĐÃ có sẵn pierce hoặc cleave, mà không die T1 nào
  > ngoài Bird có. Với roster hiển nhiên thì 3 relic này ra "không đổi gì" — trông như hỏng.

### (B) `.gitignore` cho `assets/_incoming/` (120MB) — ĐÃ XONG (2026-09-19)
Đã thêm `assets/_incoming/` vào `.gitignore` gốc. Đây là khu vực giải nén tạm; phần hữu ích
đã chuyển hết vào `godot/assets/` (52MB), phần thô tái tạo được từ nguồn gốc (zip Origins Kit,
Drive) nên an toàn khi không commit. Không có lệnh commit nào chạy kèm việc này.

### (B2) Quái sinh giữa trận không có nameplate/HP bar/tiếng — ĐÃ SỬA (2026-09-18)
Phát hiện 2026-09-18 trong lúc nối âm thanh. **Chưa sửa**, user đã yêu cầu ghi lại để làm sau.

`CombatView.gd` chỉ gọi `_spawn_portrait()` trong `_ready()`, lặp qua `_combat.party` và
`_combat.enemies` đúng MỘT lần. Nhưng `combat_engine.gd` có `enemies.append(m)` ở dòng ~914
và ~1390 — quái được SINH THÊM giữa trận (trait SPLIT của boss `gooey_king` ở 2/3 và 1/3 máu,
và `startSummon`).

Hậu quả: unit sinh thêm KHÔNG có `UnitPortrait` (tên + HP + thanh máu) và KHÔNG có
`UnitHeadHUD` (status pill + intent badge). `_rebuild_all()` vẫn gọi `_update_portrait(u)` cho
chúng nhưng `_portraits.get(uid)` trả null. Chúng cũng không được đăng ký giọng với
`CombatAudioDirector` nên hoàn toàn câm tiếng.

Không crash — chỉ là một con quái không tên, không thanh máu, không tiếng, **trông như lựa
chọn thẩm mỹ chứ không như lỗi**. Đúng loại lỗi `docs/godot-port-inventory.md` §6 liệt kê.

**Thực tế rộng hơn ghi chú ban đầu: có 5 chỗ sinh unit giữa trận, không phải 2** —
`combat_engine.gd:584` (active card summon), `:905` (mặt summon), `:917` (quái role summoner),
`:1394` (`spawn_boss_add`, SPLIT của gooey_king), và **`relic_hooks.gd:520`** (`r_broodmother`,
file hoàn toàn khác).

Đã làm CẢ HAI phương án (user chọn):
1. **Signal `EventBus.unit_spawned(uid)`** — 5 chỗ append đều emit. Cho unit hiện ra ngay
   trong khung hình đó thay vì đợi rebuild sau.
2. **`CombatView._sync_unit_visuals()`** — đối chiếu toàn bộ roster của engine với `_portraits`
   và dựng bù cái nào thiếu. Chạy từ `_ready()`, từ signal, VÀ từ mọi `_rebuild_all()`.
   **Đây mới là nguồn chân lý, không phải signal.** Lý do: bản thân bug này LÀ "có chỗ sinh
   unit mà không ai báo cho view" — cách sửa đòi phải nhớ báo sẽ tái tạo đúng lỗi đó ngay khi
   ai đó thêm chỗ sinh thứ 6. `_ready()` giờ cũng gọi chính hàm này thay vì vòng lặp riêng,
   nên chỉ còn MỘT đường dựng bàn cờ.

Thêm `CombatStage3D.reseat_side(uids, is_enemy)`: `spawn_unit()` đặt vị trí MỘT LẦN theo
`slot_count` lúc đó, nên mỗi lần có thêm unit là cả hàng phải giãn lại — không có nó thì con
mới đứng đè lên con cũ.

> **BẪY: test "có portrait chưa" không đủ.** Bản sửa đầu của tôi xanh 47 check, nhưng ảnh chụp
> thật cho thấy 2 con Gooey Slime mới hiện **`0/0` máu, thanh máu xám** — trông như quái sinh
> ra đã chết. Engine vẫn để chúng ở 9/9 suốt; chỉ là `_on_unit_spawned` mới dựng nameplate mà
> chưa sơn số lên nó. Test không bắt được vì nó hỏi "có nameplate không", chưa bao giờ hỏi
> "nameplate ghi đúng số không". Đã sửa handler gọi `_rebuild_all()`, và test giờ đọc thẳng
> `_hp_label.text` — thứ người chơi thật sự nhìn. **Nếu không chụp ảnh nhìn bằng mắt thì lọt.**

**Test mới `t_midcombat_spawn_visuals` (56 check)** — mở trận thật, gọi `spawn_boss_add()`
thật, đòi hỏi mọi unit sống đều có portrait + head HUD + slot 3D + giọng âm thanh + nameplate
ghi ĐÚNG số, và không hai unit nào đứng trùng chỗ. **Đã chứng minh nó đỏ khi gỡ bản sửa**
(8 lỗi), chứ không chỉ xanh khi có.
Kiểm chứng bằng mắt: `production/qa/evidence/2026-09-18_midcombat-spawn.png`.

### (B3) Boss dùng art nhìn NGHIÊNG, không nhìn vào đội — ĐÃ KHẢO SÁT, CỐ Ý CHƯA ĐỔI
User hỏi "boss có bị ngược không" (2026-09-18). **Không bị lật** — ảnh dựng ra giống hệt file
gốc; `_make_enemy_sprite()` không set `flip_h`, và `billboard = BILLBOARD_ENABLED` khiến sprite
luôn quay về camera nên phép xoay 180° của hàng party không đụng tới nó.

Vấn đề THẬT: **11/20 sprite vẽ chính diện, 9/20 vẽ nghiêng và mọi con nghiêng đều hướng sang
TRÁI.** 4/6 boss đang dùng sprite nghiêng (`agony`→werewolf, `mecha`→alpha-wolf,
`frost_lord`→gray-wolf, `gooey_king`→aqua-slime-boss). Đội người chơi ở giữa phía dưới, boss ở
giữa phía trên — **không có quan hệ trái/phải**, nên lật ngang KHÔNG giải quyết gì, chỉ đổi
thành "nhìn ra phải".

Đã dựng thử bảng đổi sang sprite chính diện và **nhìn thì rõ là tệ hơn**: `agony` (boss cuối)
thành daddy-bear — một con gấu mặc yếm xách túi đi chợ; `frost_lord` (DEEP FREEZE) thành
aqua-slime-def — slime xanh lá dễ thương, không hề lạnh. Nguyên nhân gốc: **kit không có sprite
chính diện nào đạt chuẩn boss** — 11 con chính diện đều là sinh vật dễ thương/trung tính, 9 con
dữ tướng đều vẽ nghiêng. Đó là giới hạn của bộ art, không phải gán sai.

→ **Quyết định của user: giữ art nghiêng, chờ art Chimera thật từ Drive** (ticket D trong
wayfinder). Đừng đổi sprite boss chỉ để lấy hướng nhìn.

### (E) Save / CONTINUE RUN — ĐÃ XONG (2026-09-18)
Port đúng hành vi JS: lưu **cả trạng thái giữa trận**, CONTINUE RUN nhảy thẳng vào trận đang dở
(`client.html:3996` cũng làm y vậy).

- `RunState.to_data()/from_data()` + `save_run()/load_run()/has_saved_run()/clear_saved_run()`
  → `user://run_save.json`, có `SAVE_VERSION`. File sai version hoặc không phải JSON bị **từ
  chối hẳn**, không nạp một nửa — run khôi phục vào schema không khớp còn tệ hơn không có save,
  vì nó trông như đã chạy được.
- Lưu sau mỗi hành động thật sự đổi state: dùng die / reroll / end turn / undo, và một lần khi
  vừa vào trận. Phía bản đồ: xong node (SAU `after_node()`), mua đồ shop, màn RESULT của event.
- `end_run()` xoá file — giống JS xoá slot khi phase là `won`/`lost`.
- Nút **CONTINUE RUN** trên MainMenu, chỉ dựng khi có file lưu, đặt TRÊN BEGIN RUN (BEGIN RUN
  ghi đè save ngay khi bấm).
- `CombatView._ready()` dựng lại `_setup` từ chính snapshot khi `pending_combat` rỗng — vào
  thẳng từ menu thì không ai gọi `enter_node()`, mà `assert` cũ sẽ nổ.

> **LỖI THẬT suýt lọt: growth mất sạch khi lưu.** `Unit.growth` và `roster[i].growth` dùng khoá
> **int** (`pu.growth[fi]`). JSON không có khoá số — mọi khoá quay về dạng chuỗi, nên
> `growth.get(3)` trượt giá trị nằm ở `"3"` và trả 0. Không lỗi, không cảnh báo: người chơi
> mất toàn bộ growth tích luỹ khi CONTINUE, trông như growth vốn dĩ yếu.
> `t_combat_roundtrip` xanh 200/200 và **không thể** bắt được — nó round-trip trong BỘ NHỚ,
> nơi kiểu dữ liệu còn nguyên. Đã ép lại khoá ở `Unit.from_data()` và `RunState._int_keyed()`.
> Đây là dictionary khoá-int DUY NHẤT trong state (`status`/`custom_state`/`stat`/`run_mods`/
> map graph đều dùng khoá chuỗi) nên ép có chọn lọc, không ép mù mọi khoá trông giống số.

**Test mới `t_run_save` (150 check)** — mọi assert đều đi qua `JSON.stringify` →
`JSON.parse_string` thật. Bỏ bước đó ra thì test vẫn xanh trong khi tính năng đã hỏng.
Gồm: round-trip toàn bộ RunState trên 5 seed, khoá growth sống sót (cả roster lẫn Unit),
`run_mods` giữ được phần thập phân (ép int sẽ biến curse 1.45× thành 1×), lưu-nạp khôi phục
đúng lượt và đúng máu địch giữa trận, run kết thúc không để lại save, và file sai version bị
từ chối mà **không** ghi đè run đang chạy.

> Bẫy tôi mắc khi viết test: so sánh bằng `str()` báo `roster`/`map_graph` "đổi" ở cả 5 seed —
> thực ra JSON chỉ sắp lại thứ tự khoá, dữ liệu y hệt. 10 lỗi đó là lỗi của test. Đã thay bằng
> hàm chuẩn hoá sắp khoá; nó cũng xử luôn việc JSON trả mọi số về float (`6` vs `6.0`).

Kiểm chứng ngoài test: không có save → menu không có nút; có save giữa trận → nút hiện, dẫn
sang Combat, khôi phục đúng `turn = 2`.

**Nút Quit giữa trận (bổ sung 2026-09-18)** — dựng bằng code vào `ButtonsRow` cạnh Sound, mở
overlay xác nhận rồi mới lưu và về MainMenu. Có xác nhận vì bấm nhầm giữa trận boss là mất cả
run; bản JS cũng để nó trong modal (`client.html:7135`) đúng vì lý do đó.
> Lỗi bắt được bằng ảnh chụp: hộp thoại dùng `DangoTheme.BG_PANEL` (alpha 0.82) nên **chữ phía
> sau xuyên qua** — nameplate địch và "28/28" đọc được xuyên thân hộp. Đổi sang `DangoTheme.BG`
> đục hoàn toàn. Một câu hỏi bắt người chơi đọc thì phải có nền đục.

## Hai comment SAI đã sửa (2026-09-18)

Không phải dọn hình thức — dự án này đã có tiền lệ comment mô tả cái sai như thể là đặc tả
(`r_chainreact`), sống sót qua nhiều phiên.

- `ContentDB.gd` có TODO nói 5 boss trait `split/thorns/freeze/summon/mirror` "còn thiếu".
  **Sai**: cả 5 đã chạy từ Phase 1 — `_boss_turn_traits()` lo thorns/summon/freeze/mirror,
  `DamagePipeline.check_boss_phase()` lo split — và `t_boss_encounters` phủ 62 check.
- `DevReviewController.gd` ghi 2 stub "NOT implemented yet (needs CombatEngine)". CombatEngine
  đã tồn tại từ Phase 1; giữ stub giờ là LỰA CHỌN không làm dev tool, không phải bị chặn.

### (F) Battle Pass XP + unlock ladder + ascMax — ĐÃ XONG (2026-09-18)
Port nguyên văn bảng và công thức từ `src/data.js`.

- `ContentDB`: `UNLOCKS` (10 mục, 120→650 shard), `BP_TRACK` (30 mốc), `BP_XP(n)=45+22*(n-1)`.
- `MetaState`: `xp`/`bp_claimed`/`perks`/`asc_max`/`runs`/`wins`/`best` (lưu đĩa) +
  `bp_level()`/`bp_progress()`/`claim_bp_reward()`/`buy_unlock()`/`run_bonuses()`.
- `RunState.end_run()`: `compute_run_xp()` port đúng `runXp()` (`data.js:1034`), cộng
  `wins`/`runs`/`best`, và nâng `asc_max` khi THẮNG Ở ĐÚNG trần hiện tại (thắng dưới trần
  không nâng — đúng JS).
- `RunState.start_new_run()`: áp dụng `bonus_reroll` / HP meta / relic khởi đầu từ unlock+perk.
- `MainMenu`: khoá FULL mode sau `u_full`, giới hạn ascension theo `asc_max`, mục LUNACIA PASS
  (claim) và UNLOCKS (mua bằng shard). `ResultView` hiện XP kiếm được.

> **LUẬT QUAN TRỌNG NHẤT: ranked run KHÔNG được nhận bất kỳ bonus meta nào**
> (`client.html:4669-4673`). Meta là dữ liệu cục bộ, không bao giờ đồng bộ lên server, nên
> replay phía server không tái tạo được nó — chỉ cần rò một bonus là mọi điểm ranked trở thành
> hàm của trạng thái riêng tư trên máy người chơi, và **nhìn từ bên trong không thấy gì sai
> cả**. `t_meta_progression` khoá điều này ở cả `run_bonuses(true)` lẫn `start_new_run(ranked)`,
> kèm một phép kiểm ngược (chạy UNRANKED phải THẤY bonus) để assertion kia không xanh vì
> `run_bonuses()` đơn giản là không bao giờ được gọi.

> **5 mốc thưởng loại `face` bị TỪ CHỐI, không phải cấp âm thầm.** `FACE_POOL` chưa port nên
> không có mặt xúc xắc nào để cấp. `claim_bp_reward()` trả về lý do và **không** đánh dấu đã
> nhận — nếu đánh dấu, mốc đó mất vĩnh viễn khi mutation pool về sau có thật. Chúng hiện trên
> menu kèm lý do thay vì bị giấu: một track có lỗ đọc như lỗi, còn "cần hệ thống bản này chưa
> có" đọc đúng như nó là. Đúng bài học `apply_event_effect`.

> **XP sẽ cao hơn bản JS ~50%** vì map Godot 18 hàng thay vì 12 và công thức tính theo số node
> đã qua. Công thức port NGUYÊN VĂN, không nhét hệ số bù — lệch này thuộc về quyết định 18
> hàng (ticket B), giấu nó trong hàm tính XP chỉ làm mất dấu.

> 4 unlock (`u_relic1`/`u_relic2`/`u_face1`/`u_face2`) mở rộng pool phần thưởng mà bản port
> chưa dựng, nên **bán được nhưng chưa có tác dụng**. Đã khai báo tường minh trong
> `ContentDB.UNLOCKS_WITHOUT_EFFECT` và `t_meta_progression` ghim đúng danh sách đó — thêm
> vào đấy phải là hành động có chủ đích, không phải trôi dần thành cửa hàng bán đồ chết.

**Test mới `t_meta_progression` (106 check)** — đường cong XP, tính cộng dồn theo cấp, claim
đúng một lần, `face` bị từ chối mà không bị đốt mốc, mua unlock tiêu đúng shard và từ chối khi
thiếu, cộng dồn bonus theo từng số hạng của JS, **ranked = 0 tuyệt đối**, công thức XP theo
từng số hạng, và luật nâng `asc_max`.

### (I) Vault/Import Axie — hướng dựng hình ĐÃ CHỐT (2026-09-19)
**Dựng Axie bằng chính rig 3D trong game, từ GENE — không tải ảnh PNG từ CDN.**
Hướng do user chỉ ra; tôi đã xác minh bằng cách giải mã 4 NFT thật trong golden của addon
(#123, #922, #4154, #1000) rồi render: body type và màu **khớp chính xác** golden, kể cả thân
`Fuzzy`, và 4 con ra 4 hình khác hẳn nhau.
Ảnh: `production/qa/evidence/2026-09-19_vault-from-genes.png`.

> **TÔI ĐÃ BÁO CÁO SAI trước đó và user bắt được.** Có lúc tài liệu ghi "bộ 3D không dựng được
> một Axie NFT cụ thể, phải tải PNG từ CDN". Lý lẽ khi đó (không có bảng ánh xạ tên part
> "Anemone" → id kit `S00_Aquatic02_L1_Back`) **đúng nhưng không liên quan**: đường đi không
> qua tên part mà qua **gene**. `AxieDescriptor.from_genes()` là bộ giải mã 512-bit đầy đủ,
> nạp thẳng vào `AxieCharacter3D`. Đã sửa ở `docs/godot-port-gap-inventory.md` §4 #12.

> ~~**Độ trung thực đã ĐO: 54/60 part dựng đúng (90%), 9/10 Axie trọn vẹn.**~~ **SỐ NÀY SAI, đã
> đo lại 2026-09-19 ở mục A: 9/10 Axie trọn vẹn và 54/54 part giải mã được đều resolve (100%).**
> Sáu part "thiếu" là part ảo của sample #1, gene của nó là `0x0`. Giữ dòng gạch ở đây vì con số
> cũ đã được chép đi nhiều chỗ.
> `AxiePartResolver` chỉ fallback theo skin/level, **không bao giờ theo variant**, nên chỗ nào
> thật sự thiếu thì lỗi là *thiếu part* chứ không phải *sai part*. Thân trần vẫn phải **phát
> hiện được**, đừng để nó trông như "một con Axie kỳ lạ" — giờ do `AxieGenePreview` lo.

> `api/axie.js` hiện truy vấn `class` + `parts`, **chưa có `genes`**. File đó phục vụ bản JS
> ĐANG LIVE — thêm trường là thay đổi production, phải quyết có ý thức; hoặc Godot gọi thẳng
> GraphQL và bỏ qua proxy. Để tới bước cuối mới quyết.

**Thứ tự xây (mỗi lớp chứng minh được trước khi lớp sau phụ thuộc vào nó):**
(a) ~~`axie_to_die.gd` thuật toán thuần + test bit-exact với JS~~ **XONG 2026-09-19** →
(b) preview 3D từ gene → (c) lưu vault trong `MetaState` → (d) lớp mạng CUỐI CÙNG.

**(a) đã xong**: `godot/scripts/core/axie_to_die.gd` port nguyên `axieToDie()` + chuỗi hàm phụ
(partKey, sgTier/sgTierEff, diePurity, coherenceMod, partBudget, affValue, resolveFace,
fallbackFace, scarcityManifest). **THUẦN** — không RNG, không Time, không I/O, đúng bất biến
AC-1 của `engine.js:118`: `api/submit-run.js` chạy lại run ranked phía server và phải dựng lại
ĐÚNG viên dice; một nguồn ngẫu nhiên ở đây làm sai điểm **âm thầm, không throw**.

**Test mới `t_axie_to_die` (627 check)** so **từng mặt, từng trường** với output thật của
`src/engine.js`. File tham chiếu `godot/tests/axie_to_die_reference.json` được **SINH RA** bằng
cách chạy engine JS thật trên 10 fixture — **đừng sửa tay**, kỳ vọng chép tay chỉ là test tự
đồng ý với chính nó. 10 fixture dựng từ khoá catalog thật nên phủ đủ nhánh: signature, variant,
fallback part lạ, fallback-blank, die thiếu part, hậu tố `α`, class Origin (Dawn), gene tier
0/2/6, class không nhận diện được, và không có part nào.
Đã xác minh gate bắt được sai lệch: nhét +1 vào `aff_value` → **42 lỗi**.

> Tên trường KHÁC Ở CHỦ ĐÍCH: JS trả `hp`/`axieId`/`secretCls`/`geneTier`, bản port trả
> `max_hp`/`axie_id`/`secret_cls`/`gene_tier` cho khớp shape roster Godot. Bảng ánh xạ khai báo
> ngay trong test (`RENAMED`), nên đổi tên là một sửa đổi **thấy được** chứ không lệch âm thầm.

> Bẫy mới: **GDScript 4.7 không có `String(bool)`**. Với tham số Variant nó KHÔNG lỗi lúc biên
> dịch — nó hỏng lúc chạy và so sánh ra "khác nhau", khiến 10 trường đang đúng tự báo là
> `true != true`. Dùng `str()`, đừng dùng `String()`, cho giá trị kiểu chưa biết.

### (H) part_faces — ĐÃ XONG (2026-09-19), bước 1 của Vault/Import Axie
`godot/assets/data/part_faces.json` là **bản CHÉP** từ `assets/data/part_faces.json` ở gốc repo,
file do `tools/gen_faces.mjs` SINH RA. Generator vẫn chạy bên JS và vẫn là nguồn duy nhất được
phép ghi; Godot chỉ đọc output. **Đừng sửa tay bản chép** — sửa là tạo ra một bảng không khớp
với ai cả.

- `ContentDB.part_faces` + `_load_part_faces()`. Chọn JSON chứ không phải `.tres`: 285 mục
  scarcity + 81 signature + 204 variant sẽ thành hàng trăm file resource, và mất luôn sợi dây
  nối về generator — thứ khiến chúng đáng tin.
- Cấu trúc đã xác minh: 22 hằng số · 6 class familyVariant · **81 signature · 204 variant ·
  285 scarcity** (= 81 + 204) · phân bố bucket C 174 / O 75 / P 18 / X 18. **Con số trong tài
  liệu dự án ĐÚNG ở chỗ này** — hiếm khi, nên đáng ghi.
- `constants.COH` dùng khoá `"0"`–`"6"`; đã ép về **int** ngay lúc nạp, một lần, tại chỗ duy
  nhất dữ liệu đi vào chương trình. Mọi khoá khác là chuỗi thật (`"aqua|back|Hermit"`) nên
  KHÔNG ép mù. Đây đúng bài học `Unit.growth` vừa rồi.

**Test mới `t_part_faces` (49 check)** — bài quan trọng nhất là so **bản chép với file gốc**
theo từng mục. Một bản chép không có gate là bản chép sẽ âm thầm cũ đi: generator chạy lại cho
đợt cân bằng, bản live đổi, còn Godot vẫn phát cho người chơi die dựng theo luật tháng trước —
không lỗi, vì một bảng cũ vẫn là một bảng hợp lệ. Đã xác minh gate đỏ khi cố tình làm lệch 1 mục.

### (G) Xem die của unit bất kỳ (scUnitInfo) — ĐÃ XONG (2026-09-19)
Trước đó người chơi đọc được die của mình trên thẻ, nhưng **không có cách nào xem die địch** —
21 quái + 6 boss, mỗi con 6 mặt, chỉ học được bằng cách bị đánh. Rule spec đòi "minh bạch triệt
để"; đây là lỗ lớn nhất trong đó.

- Panel dựng **bằng code** (không đụng `Combat.tscn`): tên + pill BOSS/class, HP/shield/tier,
  passive (phe ta) hoặc role (địch), status đang có, **cả 6 mặt** với giá trị THẬT qua
  `_face_value()` (đã tính growth/weaken/blind/vital/overdrive), keyword, đánh dấu mặt đang roll.
- `ContentDB.CLASS_PASSIVE` MỚI — 6 mục nguyên văn `data.js:54`. Engine đã áp dụng cả 6 passive
  từ Phase 1 nhưng **chưa bao giờ nói cho người chơi biết chúng tồn tại**.
- Quy tắc mở: port đúng `client.html:5273` — click unit **không phải mục tiêu hợp lệ** thì mở
  panel; hợp lệ thì vẫn chọn mục tiêu. Đường đánh nhau **không đổi một chút nào**.

> **BUG LỚN tìm được nhờ việc này: `Unit.growth` có HAI quy ước khoá không gặp nhau.**
> `get_growth()`/`add_growth()` dùng khoá CHUỖI `str(i)`, còn `grow` card (`combat_engine:573`),
> `growthAll` (`:1030`), `r_quickenroot` và `_apply_growth_keep` (r_worldtree) đều ghi khoá INT.
> `_face_value()` đọc qua `get_growth()`, nên **5 nguồn growth trong game ghi ra số mà không ai
> đọc** — card `a_bloom`, relic `r_seedling`, `r_heartwood`, `r_quickenroot`, `r_worldtree` đều
> trơ hoàn toàn. Không lỗi, không cảnh báo.
> Tệ hơn: bản sửa JSON ngày 2026-09-18 của tôi ép khoá về int, nên **một run được lưu còn mất
> luôn phần growth vốn đang chạy**. Đã thống nhất về INT ở cả hai đầu.
> Test chặn: `t_relic_behaviour` kiểm theo KẾT QUẢ (ghi growth theo từng kiểu rồi hỏi engine mặt
> đó đáng bao nhiêu) — xác minh đỏ 3 lỗi khi khôi phục bug, gồm dòng "r_seedling hoàn toàn trơ".

> **Bug nhỏ cùng họ**: `_PART_LABEL` khai khoá `"ear"`/`"eye"` trong khi dữ liệu dùng
> `"ears"`/`"eyes"` — 2 mục đó **chưa bao giờ khớp**. Thẻ die đọc đúng chỉ nhờ fallback
> `part.to_upper()`; panel mới dùng fallback rỗng nên rơi mất nhãn và làm lộ chuyện này.
> `_PART_ICON_SLOT` cũng vì thế mà là bảng chết. Đã sửa khoá + thêm test kiểm theo DỮ LIỆU.

**Test mới `t_unit_inspect` (39 check)** — trong đó bài quan trọng nhất là
`test_selecting_a_die_then_clicking_an_enemy_still_attacks()`: panel đi chung handler với việc
chọn mục tiêu, qua 2 đường (model 3D và nameplate), nên rủi ro thật không phải thiếu panel mà là
**panel nuốt mất cú click định ra đòn**.

Kiểm chứng bằng mắt: `production/qa/evidence/2026-09-19_unit-inspect-{enemy,party}.png`.

### (C) Chân dung Axie cho thẻ die — ĐÃ XONG (2026-09-18)
Công cụ MỚI `godot/tools/render_portraits.tscn` dựng rig thật của từng class vào `SubViewport`
nền trong suốt rồi xuất `assets/portraits/<class>.png`. Thẻ die dùng ảnh đó thay icon mắt cũ
(badge 18→22px; 18px biến mọi class thành cùng một vệt màu).

> **Rig chỉ sinh ra 6 hình, KHÔNG phải 18.** Ghi chú cũ nói "6 class × 3 tier" — sai:
> `CombatStage3D._build_parts()` dùng `_PART_VARIANT = 2` cố định và `_CLASS_COLOR_VARIANT`
> chỉ có theo class, nên **tier không hề tồn tại trong rig**. Xuất 18 file thì 12 file là bản
> sao giả vờ khác nhau. Giải pháp đã chốt với user: 6 ảnh + **tier hiển thị bằng số La Mã**
> sau tên trên thẻ (`II`/`III`; T1 để trống vì mọi Axie đều bắt đầu ở đó).

> **Chân dung NHÌN THẲNG camera**, khác với luật "Axie quay lưng về camera" — luật đó là quy
> định cho SÂN ĐẤU. Đã hỏi và user xác nhận: ảnh thẻ phải thấy mặt, chụp sau gáy thì mọi class
> trông giống hệt nhau. **Sprite trên sân KHÔNG đổi gì.**

> **Bẫy**: công cụ **phải chạy KHÔNG có `--headless`** — dưới dummy renderer
> `SubViewport.get_texture().get_image()` trả ảnh rỗng, file vẫn được ghi và vẫn trắng trơn.
> Công cụ tự kiểm `DisplayServer.get_name() == "headless"` và tự kiểm ảnh có pixel đục trước
> khi ghi, vì "PNG tồn tại, load được, và trong suốt hoàn toàn" là lỗi không có triệu chứng nào khác.

> **Bẫy thứ hai**: PNG mới ghi ra đĩa thì `ResourceLoader.exists()` vẫn trả false cho tới khi
> chạy `godot --headless --path godot --import`. `t_assets` đỏ 6 lỗi đúng vì lý do đó.

### (D) Nền cho node shop/event — ĐÃ XONG (2026-09-18)
`RunMapController._open_overlay(backdrop)` thêm `TextureRect` phủ toàn màn **sau lớp dim** (dim
là thứ giữ chữ đọc được; đặt tranh trực tiếp dưới body text thì độ tương phản phụ thuộc vào
bức tranh nào tình cờ được chọn).

- Shop → `shop.jpg`
- Event → chọn **tất định theo `node_id.hash()`** trong 6 nền class, cùng kỷ luật với nhạc trận.
  Màn RESULT sau khi chọn dùng LẠI đúng nền đó — đổi cảnh giữa lúc chọn và lúc thấy kết quả sẽ
  đọc như một node thứ hai không liên quan.
- Treasure "ANCIENT CRYPT" → `reptile.jpg`, bức duy nhất trong bộ đọc ra "bên trong một thứ gì
  đó" (hầm xương); 6 bức còn lại đều là cảnh ngoài trời.
- Overlay phần thưởng sau trận **giữ nguyên nền trơn** — nó giải quyết trận đánh người chơi vẫn
  đang nhìn, đổi cảnh sẽ phá mạch.

Kiểm chứng bằng mắt: `production/qa/evidence/2026-09-18_node-bg-{shop,event,treasure}.png`,
`2026-09-18_die-portraits-crop.png`.

## 2. PHASE 3 (polish/cân bằng/xuất bản) — chưa bắt đầu

- ~~Độ khó chưa re-tune~~ — **ĐÃ CÂN BẰNG LẠI 2026-09-19** (wayfinder ticket B).
  `TUNE.growth` 1.150 → **1.125**. Con số "+34%" ghi ở đây trước kia **SAI**: nó đọc `pw` ở boss
  cuối là 18 (số hàng), trong khi `power_level` đếm node ĐÃ HOÀN THÀNH nên ở đó là 17. Đo thật
  là **+47%** — và boss cuối chưa phải chỗ tệ nhất, **boss giữa +75%**. Auto-player (chơi ngu)
  từ 0 thắng / 4 thua giờ là 2 thắng / 2 thua. Chi tiết đầy đủ ở ticket B.
- **Chưa port có chủ đích** (không phải quên): `FACE_POOL` 55 mặt = 0 → thiếu reward `face`
  (Gene Mutation), 2 event `casino`/`mutant`, 2 ô shop Gene Mutation.
  > ⚠️ **ĐÍNH CHÍNH (2026-09-18)**: file này (và inventory §5.2) từng ghi FACE_POOL thiếu làm
  > mất cả reward `rune`. **Sai.** Reward `rune` đọc mảng `RUNES` RIÊNG (`src/data.js:295` —
  > cleave/pierce/growth/vital/lifesteal/aoe/crit:30/burn:4/exec/echo), qua `pick(RUNES)` ở
  > `engine.js:1103-1109`, **không đụng `FACE_POOL`**. Đó là 2 khoảng trống khác nhau và
  > `RUNES` nhỏ hơn hẳn. Comment trong `reward_generator.gd:41` vốn đã ghi đúng.
- Relic: **ĐÃ XONG 94/94** (2026-09-18) — xem §1(A2).
- (Save run, battle pass XP, unlock ladder, `ascMax`: ĐÃ XONG — xem §1(E) và §1(F).)
- Vault/import Axie NFT — yêu cầu Phase 2 của user, hiện **0%**.
- ADR anti-cheat/replay-verify trước khi cân nhắc merge `godot-port` vào `main`.

## 3. Luật bất biến — đừng hỏi lại, đừng làm ngược

1. **Quái và boss CHỈ lấy art từ kho Chimera.** Không dùng mascot Axie. Đã khoá bằng test
   `t_assets.test_no_monster_or_boss_wears_a_hero_identity()` — nó so sánh DANH TÍNH, không
   phải khoá, vì lỗi cũ lọt đúng ở chỗ đó (boss `gooey_king` từng dùng model `Pomodoro` =
   hero class Bug trong đội người chơi).
2. **Icon phải giống hệt bản web** — nguồn là `src/art7.js`, đã trích vào
   `godot/assets/icons/web/`. KHÔNG dùng icon Origins Kit cho status/node/resource/mặt xúc xắc.
3. **Axie quay lưng về camera** — user đã bác đề xuất xoay 3/4.
4. HP bar 1 thanh liền mạch + số, không chia đốt. Eye-glow dùng `OmniLight3D` riêng.
5. RunMap: node ≥2 hàng xa bị mờ "?" (ưu tiên bí ẩn) — chỉ áp dụng RunMap.
6. Không commit khi user chưa bảo.

## 4. Chưa commit gì

Toàn bộ `godot/` vẫn là untracked. `git status` sẽ thấy `?? godot/`. Đó là bình thường —
chưa có lệnh commit từ user.

---


## ⚠️ ĐÍNH CHÍNH một kết luận SAI của phiên trước (2026-09-18)

Phiên trước ghi: *"review `review-uiux-godot-vs-web.md` dựa trên 1 cửa sổ CŨ, game hiện tại
KHÔNG bị các vấn đề đó"*. **Sai.** Ảnh chụp lại qua đúng luồng thật
(`production/qa/evidence/2026-09-18_real-flow-check.png`, chụp bằng `qa_real_flow_capture.tscn`)
cho thấy review **đúng gần như toàn bộ**: quái là 2 bóng đen xám, intent hiện `?`/`-> ?`,
KHÔNG có thanh tài nguyên trên cùng (chỉ "Lượt 1" + nút Log), số "5" trôi nổi không nhãn ở góc
trái dưới, status `☠2` lơ lửng không gắn chủ, thẻ die thiếu chân dung/HP/mặt xúc xắc/READY-SPENT.
→ Các mục P0/P1 của review đó là việc THẬT của Phase 2, đừng bỏ qua vì ghi chú cũ.
(Ngoại lệ vẫn giữ: **Axie quay lưng về camera** là quyết định có chủ đích của user, KHÔNG đổi.)

## Baseline đo được (2026-09-18)

- `godot/tools/run_tests.sh` — runner MỚI, 1 entry point cho cả 2 loại test (scene `t_*.tscn`
  và SceneTree `t_*.gd` chạy qua `--script`). **13/13 GREEN** trước khi bắt đầu Phase 1.
  (Lưu ý bẫy: đừng dò fail bằng `grep -i fail` — "0 failure(s)" của bài PASS sẽ dính.)
- `godot/tests/t_full_run_loop.gd/.tscn` — **GATE MỚI của Phase 1**, vá đúng "lỗ hổng test
  nghiêm trọng" đã ghi nhận: đi trọn đường thật `start_new_run()` → map → `enter_node()` →
  `CombatEngine` → reward → `after_node()` → … → boss cuối. Khi vừa viết ra nó FAIL 5/12 —
  đúng như thiết kế, vì đó là thước đo tiến độ Phase 1. Nay đã XANH (xem mục kết quả bên dưới).
  > Bẫy đã tốn thời gian: script GDScript lỗi parse thì `_ready()` không chạy, `quit()` không
  > ai gọi → Godot chạy vô hạn, **trông như test treo chứ không phải lỗi biên dịch**. Luôn
  > ghi output ra file rồi đọc, đừng pipe qua `head`.
  > `Unit.rolled` là **Array** (0 hoặc 1 entry), KHÔNG phải int như JS `u.rolled=-1`. Dùng
  > `has_rolled()/roll_face_index()/roll_used()/current_face()`, đừng so sánh số trực tiếp.

## Kết quả 3 audit đối chiếu src/engine.js + src/data.js (2026-09-18)

### Đã port ĐÚNG — không cần đụng lại
- 18/18 hero × 6 mặt × 3 tier: diff bằng máy = **0 sai lệch** (part/type/value/keyword/HP).
- 11/11 status effect, 32/32 keyword, 6/6 class passive.
- Damage pipeline 13 bước: đúng thứ tự, đúng số học.
- Formation Resonance ×1.15, face-value chain, shield/heal rule, enemy AI intent, CURVE/budget.
- RNG mulberry32 bit-exact với JS.

### Gap PHASE 1 — theo thứ tự nghiêm trọng
1. **Run KHÔNG THỂ THẮNG.** `RunPhase.WON` không được gán ở đâu cả; `after_node()` luôn về
   MAP; boss cuối không có `next_ids` → map khoá cứng, không lối ra. *(JS: engine.js:383,997)*
2. **Boss không bao giờ xuất hiện.** `_generate_encounter()` nhánh boss trả về 3 slime.
   Không có `boss_plan`/`BOSS_ORDER_12`/`BOSS_ALT`; `ContentDB.boss_stats()` viết đúng nhưng
   chưa từng được gọi từ combat.
3. **Mọi quái đều là slime.** `NORMAL_POOL` (17 key, gate theo `pw`)/`ELITE_POOL` (4) chưa
   port; 6 quái đã có trong ContentDB là **dữ liệu chết**. Elite chỉ khác battle ở hệ số budget.
4. **Tier-up hero không tồn tại** → đội kẹt T1 trong khi `budget(pw)` leo 10.5→75. Run bất
   khả thắng về toán học. Gate mới chết ở row 11. Trong JS đây là reward **trọng số cao nhất**.
5. **Reward 3/9 loại** (thiếu `level/ascend/face/rune/chaos/curse`, có thêm `shard` tự chế).
   Thiếu reward-set reroll (`rrwMax`); treasure phát thẳng 1 thay vì cho chọn 3.
6. **Boss trait 5/6 là stub rỗng** (`split/thorns+OVERDRIVE/freeze/summon/mirror`). Chỉ
   `agony` 2-phase chạy thật. `Unit.overdrive` được đọc nhưng không ai set.
7. **Relic 20/94.** `modFace` **không có call site nào** → 31 relic (42% phần thiếu) bị chặn
   kiến trúc. 16 active card (`a_*`) chưa có đường thực thi → mana là tài nguyên chết.
8. **Ascension `hp` bị nhân 2 lần** vào budget (`combat_engine.gd:883` + `:893`) → A10 ra
   ≈2.11× thay vì 1.452×. A7 (`rewards=2`) chưa có. Không có chọn mode/ascension/team.
9. **Không có save run đang chơi** (CONTINUE RUN); shard của run THẮNG không bao giờ được
   bank vì đường WON không tới Result.
10. `FACE_POOL` 55 mặt = 0 port → mất cả trục reward Gene Mutation + 2 event `casino`/`mutant`.

## KẾT QUẢ PHASE 1 (2026-09-18) — đo được, không phải tự đánh giá

`./godot/tools/run_tests.sh` → **17/17 PASS** (trước khi bắt đầu: 13/13 nhưng bộ test cũ
KHÔNG hề đi qua đường thật, nên xanh mà vẫn sai).

| Chỉ số | Trước | Sau |
|---|---|---|
| Gate `t_full_run_loop` | 5 fail / 12 check | **0 fail / 157 check, 8 seed-walk** |
| Số loại quái thật sự xuất hiện trong 1 run | **1** (chỉ slime) | **24** |
| Boss xuất hiện trong trận | **0** | **3** (gooey_king → frost_lord → agony, đúng BOSS_ORDER_12) |
| Run có thể THẮNG | **không bao giờ** (soft-lock) | có, verify qua `RunPhase.WON` |
| Auto-player (ngu, không reroll/relic) đi được | row 6/4/14/6 của 18 | **row 15/6/12/15** sau khi có tier-up |

3 test MỚI, mỗi cái vá đúng một lỗ hổng đã cho phép bug sống sót:
- `t_full_run_loop` — đi TRỌN đường thật `start_new_run → map → enter_node → CombatEngine →
  reward → after_node → … → boss cuối`. Tách 2 chế độ: `PLAYED_SEEDS` (mô phỏng thật, dùng để
  ĐO tiến độ, không assert — đó là câu hỏi cân bằng) và `FORCED_SEEDS` (ép thắng, dùng để
  ASSERT vòng lặp có đóng lại không — nếu không tách, mọi run chết ở row 9 sẽ che mất việc
  nhánh THẮNG chưa từng chạy).
- `t_boss_encounters` (62 check) — 6 boss sinh đúng stat, mecha permThorns+OVERDRIVE mỗi 3 lượt,
  agony đổi phase 2, gooey_king SPLIT ở 2/3 và 1/3 + tôn trọng add_cap, frost_lord đóng băng,
  mirror copy mặt mạnh nhất, pool gate theo pw, elite có elite thật, ascension KHÔNG nhân đôi.
- `t_mod_face` (280 check) — `modFace` chạy thật, INV-5 độc lập thứ tự nhặt relic, pseudo-relic
  không bao giờ bị phát như loot.
- `t_event_effects` (114 check) — khoá bất biến **"mọi lựa chọn được ĐỀ NGHỊ đều phải CÓ TÁC
  DỤNG"**. Fail ngay khi ai đó thêm dữ liệu event mà quên nhánh `fx` tương ứng.

2 công cụ MỚI, dùng trước khi làm bất cứ gì:
- `godot/tools/check_syntax.sh` — preflight cú pháp toàn project, vài giây. **Bắt buộc chạy sau
  mỗi lần sửa .gd.** Lý do: lỗi parse GDScript KHÔNG làm Godot báo lỗi — script không load,
  `_ready()` không chạy, không ai gọi `quit()`, process chạy vô hạn. Nó giống hệt "test treo".
  Đã lọc sẵn 2 loại dương tính giả (autoload không tồn tại ở chế độ `--script`, và lỗi lan truyền
  "Failed to compile depended scripts").
- `godot/tools/run_tests.sh` — 1 entry point, chạy cả `t_*.tscn` lẫn `t_*.gd`.

### Bug THẬT tìm được trong lúc port (không nằm trong gap list ban đầu)

1. `ContentDB.boss_stats()` ghi khóa `max_hp2` nhưng `DamagePipeline.check_boss_phase()` đọc
   `hp2` → phase 2 của Agony **không bao giờ kích hoạt được**, kể cả sau khi boss biết spawn.
2. `r_chainreact` nổ trúng **cả phe mình** và có pierce. JS chỉ nổ vào địch còn sống, trừ con
   vừa chết, không pierce. Comment trong code lại mô tả cái sai đó như thể là đặc tả.
3. Ascension `hp` bị nhân 2 lần vào budget → A10 ra ≈2.11× thay vì 1.452×.
4. `_pick_enemy_intent` dùng `sort_custom` (introsort, KHÔNG ổn định) trong khi JS dựa vào
   `Array.prototype.sort` ổn định → hoà điểm `hp+shield` (rất hay gặp ở đàn quái giống nhau)
   chọn mục tiêu khác JS ⇒ phá tính tất định/replay. Thay bằng `_lowest_by()` tie-break theo
   thứ tự mảng.
5. `onTurnStart` không chạy ở lượt 1 → mọi relic loại đó trễ đúng 1 lượt, mãi mãi.
6. **Hồi quy suýt lọt lưới**: thêm event `casino`/`mutant` vào ContentDB khiến map bốc trúng
   được chúng, nhưng 6/14 `fx` không có nhánh xử lý trong `apply_event_effect()` → người chơi
   chọn xong **không có gì xảy ra**, không lỗi, không log. Đã port đủ `bet_small`/`shards30`/
   `leave`; 3 cái còn lại (`bet_big`/`dip`/`drink`) cần FACE_POOL nên bị **lọc khỏi lựa chọn**
   qua `ContentDB.playable_event_options()` thay vì đề nghị rồi im lặng. Event còn <2 lựa chọn
   thì bị loại hẳn (1 nút bấm không phải một quyết định). `apply_event_effect()` giờ
   `push_error` nếu gặp fx lạ. Khi FACE_POOL có, XOÁ bộ lọc chứ đừng lách qua nó.

## Chưa port (có chủ đích, KHÔNG phải quên) — ưu tiên cho sau

- `FACE_POOL` 55 mặt = 0 → thiếu reward `face`/`rune`, 2 event `casino`/`mutant`, 2 ô shop
  Gene Mutation, 5 mặt Battle Pass. Đây là 1 trong 2 trục reward của bản JS.
- 74/94 relic chưa có `.tres` — nhưng **rào kiến trúc đã gỡ**: `modFace`/`modFace2` (chặn 31
  relic) và đường chạy active card (chặn 16 relic `a_*`) giờ đều đã có và có test. Việc còn lại
  là AUTHOR dữ liệu, không còn là sửa engine.
- (Save run, battle pass XP, unlock ladder, `ascMax`: ĐÃ XONG — xem §1(E) và §1(F).)
- Vault/import Axie (Phase 2 theo yêu cầu user).

## Kế hoạch Phase 1 — 4 workstream

- **W1 ContentDB** (`ContentDB.gd`): 14 quái thiếu (gồm 4 elite), 4 boss thiếu, bảng
  `NORMAL_POOL`/`ELITE_POOL`/`BOSS_ORDER_12`/`BOSS_ORDER_20`/`BOSS_ALT`, `TIER_UP`, 4 event thiếu.
- **W2 CombatEngine** (`combat_engine.gd`, tự làm — file lõi, không giao agent): port thật
  `genEncounter`, sinh boss, 5 boss trait, `permThorns`, `startSummon`, `onTurnStart` lượt 1,
  `growthAll`, sort ổn định, `safeReroll`/`critKeep`, `growthKeep`, pass `modFace` (INV-5),
  active relic + tiêu mana, sửa nhân đôi ascension hp.
- **W3 RunState/Reward** (`RunState.gd`, `reward_generator.gd`, `RunMapController.gd`):
  `boss_plan`, phase WON, tier-up/ascend/chaos/curse, reward reroll, treasure chọn-3, A7,
  `runMods` curse, save/load run.
- **W4 Menu/Result** (`MainMenu.*`, `Result*`): chọn team/mode/ascension, màn Result đầy đủ.

Tiêu chí hoàn thành Phase 1: `t_full_run_loop` xanh + `run_tests.sh` xanh toàn bộ. → ĐẠT.

## PHASE 2 — ĐANG CHẠY (2026-09-18)

User đã cấp **toàn bộ** Axie Origins Asset Kit (zip 1.1GB, 15.726 file, Unity project) và yêu cầu
tôi **tự chuyển đổi sang Godot**.

### Đã chuyển đổi xong (tự làm, có kiểm chứng bằng mắt)

**1. Icon — 62 file, lấy ĐÚNG từ bản web** (`godot/assets/icons/web/`)
Nguồn là `src/art7.js` của chính game, KHÔNG phải Origins Kit — vì user yêu cầu "dùng lại
toàn bộ icon đã dùng trong bản web để cho khớp". Gồm 21 PNG (status/node/resource/die-face),
5 SVG (`mana/blank/buff/debuff/reroll`), 36 icon bộ phận cơ thể (6 slot × 6 class).
> Bẫy khi trích xuất: giá trị trong `ICON_SVG_RAW` là chuỗi JS có dấu nháy ESCAPE bên trong
> (`blank` bắt đầu bằng `<g stroke=\'`). Regex non-greedy cắt sai giữa chuỗi rồi
> `unicode_escape` chết vì dấu `\` thừa ở cuối. Phải quét chuỗi thủ công, có xử lý escape.

**2. Quái — 20 Chimera toàn thân** (`godot/assets/monsters/`, 3.8MB)
Công cụ MỚI, dùng lại được: **`tools/spine_to_sprites.py`**. Origins Kit ship Chimera dưới
dạng **Spine 3.8** (`.skel` nhị phân + `.atlas` + atlas `.png`). Godot không đọc được nếu
không có plugin `spine-godot` (license riêng của Esoteric) — dự án đã quyết KHÔNG lấy phụ
thuộc đó. Giải pháp: tự đọc `.skel`, tính world transform của setup pose, ghép từng mảnh từ
atlas thành 1 PNG phẳng. **Không cần runtime, không cần license.**
> 4 bẫy đã tốn thời gian, ghi lại để không lặp:
> 1. Spine 3.8 **CÓ bảng chuỗi** ngay sau header; nhiều trường là chỉ số vào bảng đó
>    (`readStringRef`), không phải chuỗi inline. Đọc sai → lệch stream ngay từ slot đầu.
> 2. Số bone ảnh hưởng mỗi đỉnh (weighted vertex) là **varint**, không phải float (3.6/3.7
>    dùng float). Sai chỗ này → ăn hết phần còn lại của file, báo lỗi ở EOF chứ không báo
>    tại chỗ, nên trông như file hỏng.
> 3. Trong atlas, `size` là kích thước **LOGIC đã bỏ xoay**. `rotate: true` chỉ nói cách
>    packer xếp vào page. Hoán đổi w/h ở đây làm mọi mảnh xoay bị kéo méo (mắt slime dài
>    406px thay vì 46px) — trông như art xấu chứ không như bug transform.
> 4. Slot tên `fx*` là hiệu ứng đòn đánh, vẫn gắn trong setup pose → ghép thẳng sẽ ra con
>    quái đang "mặc" hiệu ứng trúng đòn của chính nó. Phải lọc.
>
> **Bài học chung đã ghi vào docstring công cụ**: bản đầu tôi khẳng định "mọi attachment đều
> là region", "kiểm chứng" bằng 2 file JSON có sẵn (machito, shilin). Hai file đó tình cờ là
> 2 con ĐƠN GIẢN NHẤT. 16/20 binary có mesh, nhiều con có weighted vertex. **Hai mẫu tiện tay
> không phải một cuộc khảo sát.**
>
> Còn lại: `machito`/`shilin` ship dạng `.json` (không có `.skel`) nên công cụ bỏ qua — 2 con
> này là nhân vật Axie, không phải quái, nên không cần.
>
> **HẠN CHẾ THẬT, đừng báo cáo là hoàn hảo**: công cụ lấy **setup pose** (tư thế gốc của
> rigger), không phải khung hình idle. Với 17/20 con thì setup pose chính là tư thế đứng bình
> thường nên không vấn đề gì. Nhưng **3 con đọc hơi lạ**: `dryad-mage` (dang tay kiểu T-pose),
> `dryad-ranger` (đang giữa bước chạy), `aqua-alpha-wolf` (tư thế tách rời). Kiểm chứng bằng
> `production/qa/evidence/2026-09-18_monsters-at-game-scale.png` — dựng ở đúng 140px, kích
> thước thật trên sân.
> Cách sửa nếu sau này thấy đáng: đọc thêm phần ANIMATION trong `.skel` (nằm sau phần skin)
> và lấy keyframe đầu của clip idle thay cho setup pose. Đó là việc đáng kể về format, chỉ để
> sửa 3 sprite — nên đã cân nhắc và hoãn, không phải bỏ quên.

**3. Bảng gán quái ↔ sprite**: `godot/scripts/data_models/monster_art.gd`.
Gán theo **hình dáng nhìn thấy + vai trò AI**, KHÔNG theo tên (không có Chimera nào tên
"Ravenling"). 21 quái + 6 boss đều có sprite, dùng hết cả 20 file, không thừa không thiếu.

**4. Âm thanh** (`godot/assets/audio/`, 32MB sau xử lý)
78 SFX combat (6 class × 13 kiểu đòn/pha — khớp đúng hệ class của game), 38 SFX status,
5 nhạc nền (`pve_1/2/3`, `boss`, `home`). Bỏ `mech/dawn/dusk` vì game không có class tương ứng.
Máy không có ffmpeg → tự hạ mẫu 48kHz→24kHz mono bằng Python (`wave`+`array`, lọc box trước
khi decimate để không bị alias), 53MB→33.7MB. Godot tự nén QOA khi import.
> Đã sửa: importer mặc định `edit/loop_mode=0` → nhạc phát 1 lần rồi im, rất dễ tưởng là
> "chưa nối audio". Đã bật Forward cho cả 5 track.
> Bảng ánh xạ đã có: `godot/scripts/data_models/combat_audio.gd`.
> Vấn đề nó giải: kit đặt tên sound theo **ANIMATION** (bite/slash/smash/gore/cast/projectile/
> throw) vì đó là thứ điều khiển chúng trong game gốc; còn game này đặt tên mặt xúc xắc theo
> **HIỆU ỨNG** (dmg/shield/heal/…) và **BỘ PHẬN** (mouth/horn/back/tail/eyes/ears). Không có
> gì nối 2 hệ đó tự động. Chọn bộ phận làm tín hiệu chính (mouth→bite, horn→gore, tail→slash,
> back→smash, eyes/ears→cast) vì đó cũng chính là thứ người chơi đang nhìn; chỉ khi bộ phận
> không cho thông tin (mặt của quái đều là part "m") mới rơi xuống ánh xạ theo loại.
> Nhạc trận chọn tất định theo `node_id.hash()` — KHÔNG dùng `randi()`, vì cả bản port RNG
> tồn tại để run replay được giống hệt.
> **CHƯA nối vào EventBus/combat** — mới chỉ có file, import và bảng ánh xạ.

**5. Test mới `t_assets` (285 check)** — khoá bất biến 2 chiều: mọi quái/boss phải có sprite
tải được, VÀ mọi sprite phải có người dùng. Lý do: thiếu art KHÔNG crash — nó hiện ra như một
lựa chọn thẩm mỹ chứ không như lỗi, đúng kiểu đã cho phép "4 con quái cùng một bóng xám" sống
sót qua nhiều phiên. Đã mở rộng: nền theo class, đủ lớp parallax, mọi mặt xúc xắc (class ×
bộ phận × loại) đều ra file âm thanh có thật, mọi status có tiếng, nhạc boss không bao giờ
lẫn với nhạc trận thường, và lựa chọn nhạc là tất định.

### Đã nối vào game (verify bằng ảnh chụp thật qua đúng luồng chơi)
- Sprite Chimera thay bóng xám; boss to rõ ra dáng boss (`_BOSS_SCALE` 1.5→2.15 — 1.5 KHÔNG
  đủ vì hàng địch ở xa, phối cảnh đã thu nhỏ sẵn; phải đo bằng ảnh, không tính bằng công thức).
- Hàng địch lùi sâu hơn (`_POS_Z_ENEMY` -2.8→-4.1) để nameplate không đè lên đầu Axie.
- Thanh tài nguyên trên cùng: WAVE + thanh tiến độ, TURN, REROLL, SHARD, MANA, Undo/Info/Log.
- Nameplate: tên + HP + thanh máu; status pill dính vào chủ.
- Thẻ die có icon loại mặt + bộ phận.

### 3 bug tự tìm & sửa trong lúc verify (đều KHÔNG crash, chỉ nhìn mới thấy)

1. **Tên bị cắt giữa chữ** — "Venomaw"→"Venon", "FROST LORD"→"FRC". Chẩn đoán đầu của tôi
   SAI (tưởng cắt chuỗi); thực ra là clip khi vẽ. Gốc: `_resync_size()` lấy
   `get_combined_minimum_size()` của card, mà `NameLabel` là EXPAND_FILL nên minimum của nó
   ≈ 0 → card co lại tới mức cắt chữ. Sửa: cho label tự khai bề rộng text thật
   (`font.get_string_size`). Nới `WIDTH` thành sàn cứng thì hết cắt nhưng **nameplate chạm
   nhau** (đúng lỗi #6 review) — nên cách đúng là đo theo nội dung, không phải nới sàn.
2. **Badge intent rỗng hoàn toàn** (ô đen, không icon không số). Đây là **bug trong phần trích
   xuất icon của TÔI**: 5 icon `ICON_SVG_RAW` là FRAGMENT vẽ trong hộp 128 đơn vị
   (`cx=64 cy=64`), `client.html:2354` bọc chúng bằng `viewBox="0 0 128 128"`. Tôi bọc bằng
   `0 0 48 48` → mọi hình nằm ngoài khung → render ra **không gì cả**. File tồn tại, tên đúng,
   load thành công — không có kiểm tra "file có tồn tại" nào bắt được. Đã thêm test
   `test_raw_svg_icons_use_the_web_builds_viewbox()`.
3. Boss `frost_lord` đang dùng `aqua-alpha-wolf` — 1 trong 3 sprite có setup pose kiểu T-pose.
   Chấp nhận được với quái thường, KHÔNG chấp nhận được với boss cả trận xoay quanh nó.
   Đổi: `frost_lord`→gray-wolf, `mecha`→alpha-wolf, `mirror`→dryad-fighter.

- [x] **Thẻ die đầy đủ**: badge class + tên + READY/SPENT/DEAD, thanh HP + số, dãy 6 mặt của
      die (mặt đang roll viền cam), mặt lớn + icon bộ phận. Thẻ đã dùng/chết bị dim toàn thân.
      > Cỡ chữ: agent để state 10px / HP 11px / caption 10px — dưới sàn 14px của dự án và
      > **tự khai ra**, không giấu. Đã nâng lên 12/14/12 và kiểm lại bằng ảnh crop phóng to
      > (`2026-09-18_dice-cards-crop.png`) chứ không tin vào con số.
      > **Chưa có chân dung Axie thật** — badge hiện là icon mắt theo class. Party là rig 3D,
      > không có asset chân dung 2D nào tồn tại. Bịa một cái ra còn tệ hơn là không có.
- [x] **Khung log rỗng**: ẩn hẳn cho tới khi có dòng đầu tiên, thay vì để ô viền trống.

### Còn lại của Phase 2 (chưa làm — không phải quên)
- Âm thanh: có file + import + bảng ánh xạ, CHƯA nối vào EventBus/combat. (User chọn để sau.)
- Nền theo class (`origins/class/*.jpg`) mới dùng cho combat; shop/event node chưa dùng.
- [x] **Nền trận đã nối** (`godot/scenes/shared/BattleBackdrop.gd`): 7 cảnh, chọn theo HÀNG
      trên RunMap nên một run 18 hàng đọc ra như một hành trình (cổng rừng → ngã ba → sông →
      rừng sâu → đền → núi đá → núi băng), boss luôn lấy cảnh cuối tối nhất.
      > **Sai lầm đã mắc & sửa, giữ lại để không lặp**: bản đầu tôi stack từng lớp PNG rời và
      > dịch chuyển theo camera, GIẢ ĐỊNH thứ tự tên file mã hoá độ sâu. KHÔNG đúng — sắp
      > alphabet thì `7-deep-forest` vẽ `FRONT-BOT`/`FRONT-TOP` RA SAU `Ground`/`MANY-TREES`,
      > kết quả là một mảng xanh phẳng không có đường chân trời, **xấu hơn cả nền sa mạc cũ**.
      > Kit KHÔNG ghi thông tin độ sâu ở đâu cả, nên mọi thứ tự đều là phỏng đoán đội lốt dữ
      > liệu. Cách đúng: ghép sẵn mỗi bộ thành 1 ảnh (đúng ý người vẽ) rồi crop 16:9.
      > Parallax là phần thưởng thêm; biến thể theo vùng mới là mục tiêu, không đánh đổi.
      > Chọn theo hàng, KHÔNG theo class quái — vì gần như mọi quái có `cls == ""`.

- `PvE/Cards/Chimeras` (75 ảnh minh hoạ có nền vẽ sẵn) — hợp làm art thẻ/màn thưởng, KHÔNG
  dùng làm sprite trên sân được.

## Ghi chú Phase 2 từ user

- Icon: **dùng lại đúng icon bản web** (`src/client.html`). Audit đã lập bảng đối chiếu:
  Godot thiếu HẾT 9 icon loại mặt xúc xắc (`FT_IC` — icon tần suất cao nhất game), thiếu icon
  shard/reroll/mana/chest, `frozen.png`+`shield.png` có trên đĩa nhưng không ai preload,
  `ContentDB` copy nhầm field `ic` chết của data.js (`⛩`/`✚`) thay vì `EV_IC` thật của client.
  Node icon là mục DUY NHẤT đã khớp đủ.
- Boss art: user nói ảnh boss bản JS là **tạm bợ** → xử lý quái thường trước; user sẽ cấp ảnh
  Chimera thật sau. Drive user cấp: `1RjgfuL5t0yuGNbyYtitVQtw63bew1eGr` (có `1. Character`,
  `2. Equipment`, `3. Environment/Props`, `Nightmare Realm Map`, `NPC Playtest 2`).
- Vault (nhập Axie ID → gene → die) là yêu cầu Phase 2 của user. Hiện Godot có **0%**:
  `MetaState.vault` là mảng rỗng không ai đọc; thiếu `axieToDie`, `part_faces` (81 signature +
  204 variant + 285 scarcity), coherence/purity, NFT HP bonus, UI import.

## ⚠️ LỖI THẬT phiên trước đã mắc — user phát hiện (2026-09-18)

Boss đang dùng model GLB từ `third_party/axie-3d-assets`: `agony`→**Paladill**,
`gooey_king`→**Pomodoro**. Nhưng **"Pomodoro" chính là tên hiển thị của hero class Bug trong
đội người chơi** (`ContentDB._hero("Pomodoro", "bug", ...)`). Tức là game đang cho người chơi
đánh nhau với chính nhân vật của mình. Paladill cũng là mascot Axie, không phải Chimera.

Không có gì bắt được lỗi này vì code chỉ so sánh **KHOÁ** (`gooey_king` vs `bug1`), chưa bao
giờ so sánh **DANH TÍNH** đằng sau khoá.

→ **Quy tắc user (bất biến)**: quái và boss CHỈ lấy art từ kho Chimera. Không dùng mascot Axie.
→ Đã khoá bằng test `t_assets.test_no_monster_or_boss_wears_a_hero_identity()`: không sprite
  quái/boss nào được trùng tên với bất kỳ hero nào, và file tên-hero không được phép nằm trong
  thư mục sprite quái.
→ Nhánh `_BOSS_MODEL_SCENE` trong `CombatStage3D.gd` **đã gỡ hẳn** (~6.700 ký tự code +
  30 dòng tài liệu mô tả nó). Mọi boss đi chung đường sprite Chimera với quái thường.

### Dọn dẹp đã làm (user duyệt 2026-09-18) — giải phóng ~550MB

**Đã xoá** (verify từng nhóm: không `load`/`preload`, không scene tham chiếu; sau mỗi nhóm
chạy lại `check_syntax` + `run_tests` + chụp ảnh thật):
- `assets/_incoming/origins-kit-full` + `axie-origins-audio` — **540MB**. Tái tạo được 100%
  từ zip gốc `~/Downloads/axie-origins-asset-kit-main (2).zip` (1.12GB) + `tools/spine_to_sprites.py`.
- `godot/assets/models/` — 6.1MB, paladill/pomodoro .glb + texture (boss hero, đã cấm).
- `godot/tests/qa_boss_capture.gd/.tscn` — QA cho nhánh GLB đã xoá; header còn khẳng định
  "`_generate_encounter()` chưa roll ra boss", sai từ khi Phase 1 xong. Thay bằng `qa_boss_check.gd`.
- `godot/assets/icons/{intent,status,status_origins}` + `portraits/` + `desert_battle_bg.png`
  — đều bị bộ icon web / BattleBackdrop thay thế. Chỉ còn được nhắc trong 1 comment.

**CỐ TÌNH GIỮ — đừng xoá vì thấy "không được tham chiếu"**:
> Máy quét tên-file báo 23.2MB "không dùng". Phần lớn là **dương tính giả**: đường dẫn được
> GHÉP LÚC CHẠY nên tên không bao giờ xuất hiện trong code.
- `godot/assets/audio/sfx/class/*.wav` (78) — `CombatAudio.face_sfx_path()` ghép
  `<class>_<action>_<phase>`. `t_assets` đang chứng minh cả 78 file đều dùng được.
- `godot/assets/icons/web/part/*.svg` (36) — ghép `<slot>_<class>.svg`, cũng có test.
- `godot/assets/backgrounds/origins/parallax/**` (39 layer) — nguồn DUY NHẤT trong repo để
  tái tạo ảnh cảnh nếu đổi cách ghép.
- 17 SFX status chưa map — mới 2.3MB, và vòng nối âm thanh có thể cần (`cleanse`, `summon_off`…).
- `third_party/` (391MB) — CLAUDE.md quy định đây là nơi vendor gói upstream "kept as
  delivered"; nó là hồ sơ nguồn gốc/license. Xoá là quyết định CHÍNH SÁCH, không phải dọn rác.
- `assets/_incoming/lunacia-terrain-art-2026-09-17` (119MB) — nguồn của `plant_landscape.png`
  ĐANG DÙNG; không rõ tải về từ đâu nên không chắc lấy lại được.

## Quyết định đã chốt (đừng hỏi lại / đừng làm ngược lại)

- **FACE_POOL / thiết kế relic để dành cho một bản BIG UPDATE sau** (user, 2026-09-18). Hiện
  tại ưu tiên là game chơi được, không phải bù đủ trục reward. Cụ thể: đội toàn Beast/Reptile/
  Bug có **0 mặt mana ở cả 3 tier** (chỉ Plant 1, Aqua 2, Bird 1 là có), và với FACE_POOL=0 thì
  đường mana thứ hai (reward `face` Gene Mutation) biến mất — nên đội đó không rút được relic
  sinh mana sẽ không dùng được active card nào cả run. **Đã biết, đã chấp nhận tạm thời.**
  Số Mana cost của 16 active card đã port NGUYÊN VĂN, không đổi.

- RunMap: graph phân nhánh thật, node ≥2 hàng xa bị mờ "?" (ưu tiên bí ẩn) — chỉ RunMap.
- **Axie quay lưng về camera** — giữ nguyên, user đã bác đề xuất xoay 3/4.
- Boss/quái: KHÔNG tích hợp Spine2D runtime.
- Eye-glow dùng `OmniLight3D` riêng, không tái dùng `AxieMysticGlow` (giữ tín hiệu Mythic).
- HP bar: 1 thanh liền mạch + số HP, KHÔNG chia đốt.
- Animation/layout: lấy CẢM HỨNG Shroom and Gloom, giữ bản sắc Axie.
- RunMap 18 hàng (×1.5 so với JS 12) là quyết định cũ — nhưng nó đẩy `budget` cuối run từ
  56.2 lên 75.5 (**+34% độ khó**). — ⚠️ CON SỐ NÀY SAI, và đã được ĐO LẠI + SỬA ngày
  2026-09-19: thực tế +47% ở boss cuối và +75% ở boss giữa; `TUNE.growth` đã hạ 1.150 → 1.125.
  Xem `production/wayfinder/tickets/B-runmap-retune-sim-data.md`. Giữ dòng gốc ở đây để thấy
  con số sai đã tồn tại bao lâu, không phải để dùng lại.
- **Undo có tua lại RNG, JS thì KHÔNG** (`_state_dict()` lưu `rng_state`). Bản Godot dễ hiểu
  hơn cho người chơi, nhưng lệch JS: một hành động tiêu RNG (`chain`, AoE random) undo rồi làm
  lại sẽ ra kết quả KHÁC ở JS, GIỐNG ở Godot. Giữ nguyên hành vi Godot; đây là việc phải giải
  quyết trong ADR anti-cheat/replay-verify trước khi merge `godot-port` vào `main`, không phải
  bug cần sửa vội.


---

# KHOẢNG CÁCH SO VỚI BẢN JS

**Toàn bộ nội dung này đã chuyển sang `docs/godot-port-gap-inventory.md`** — một tài liệu riêng,
đo lại toàn bộ ngày 2026-09-19 bằng 4 lượt khảo sát song song trên `src/`.

Bản kê đầu tiên tôi viết ở đây **có 3 chỗ sai**, đã sửa trong tài liệu mới:

1. **"JS ~30 màn, Godot 5"** — sai. JS có **22 màn thật** (34 hàm `sc*`, nhưng 11 cái không phải
   màn: 8 mảnh tab, 1 widget, 1 router, 1 lớp nền). Godot phủ **5 đủ + 6 một phần = 11/22**,
   tức khoảng **một nửa**, không phải ~17%. Đếm file `.tscn` không bằng đếm màn: `RunMap.tscn`
   một mình gánh 5 màn JS, `MainMenu.tscn` gánh 4.
2. **Cột "JS" trong bảng là SỐ LẦN GREP**, không phải số lượng nội dung. Ai ước lượng khối lượng
   việc từ nó sẽ ước thiếu nghiêm trọng: "Cosmetics 28" thực ra là **97 món**.
3. **"Thiếu hẳn: Battle Pass riêng, Unlocks riêng"** — sai, cả hai **đã có**, dựng inline trong
   `MainMenu.gd`.

Đọc `docs/godot-port-gap-inventory.md` trước khi kết luận còn gì phải làm.
