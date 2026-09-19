# Cổng Cutover — `godot-port` → `main`

> Chạy từ trên xuống trong một phiên. **Bất kỳ ô BẮT BUỘC nào chưa tick = KHÔNG ĐƯỢC CUTOVER.**
> Nguồn phạm vi có thẩm quyền: `docs/godot-port-gap-inventory.md`. Muốn hạ một tiêu chí thì
> **sửa chính file này trong cùng commit** — không hạ bằng lời.
>
> Vì sao file này tồn tại: "sẵn sàng thay bản live" trước đây chỉ là một câu định tính. Bản JS
> có `tools/ci.mjs` 12/12 để trả lời pass/fail; bản port thì không có gì tương đương.
> (Wayfinder ticket H. Bị chặn bởi ticket A cho tới 2026-09-19, nay đã mở khoá bởi
> `docs/architecture/adr-0004-headless-godot-is-the-referee.md`.)

Trạng thái lần cập nhật cuối: **2026-09-19**. Suite Godot **37/37**.

---

## 0. Tự động — BẮT BUỘC

- [ ] `godot/tools/run_tests.sh` xanh, và số gate **không thấp hơn** mức sàn ghi ở
      `.claude/docs/technical-preferences.md` (hôm nay **37**). Sửa suite thì sửa mức sàn
      trong cùng commit — mức sàn cũ không chỉ sai thông tin, nó **cho phép một regression
      đi qua review**.
- [ ] `node tools/ci.mjs` vẫn **12/12** cho bản JS. Cutover không được làm hỏng thứ đang sống.
- [x] `node tools/ci.mjs` — **đo 2026-09-20: 12/12 XANH**, bản JS đang live không bị ảnh hưởng.
- [ ] Web export build sạch **VÀ CHẠY ĐƯỢC**. ⚠️ Lỗi cú pháp GDScript làm Godot **treo im lặng**
      — "build không xong" và "build lỗi" trông giống hệt nhau. Chạy `--import` trước.

> ### 🚨 CHẶN PHÁT HÀNH — tìm ra 2026-09-20: **mọi bản export đều KHÔNG dựng được một con Axie nào**
>
> Dự án chưa từng có `export_presets.cfg`, nên chưa ai từng export lần nào. Lần đầu tiên làm:
> **build sạch ngay**, 41MB pck + 39MB wasm, **và bản web thật sự khởi động trong trình duyệt**
> (ảnh: màn tutorial hiện đúng). Nghe như tin tốt — cho đến khi đọc console:
>
> ```
> ERROR: AxieCatalog: catalog not found at res://addons/axie_mixer_3d_assets/catalog.json
> ```
>
> **Nguyên nhân**: `godot/addons/axie_mixer_3d_assets/.gdignore` — một file RỖNG khiến Godot coi
> như cả thư mục không tồn tại. Thư mục đó là **249MB, 2.211 file, 744 file GLB**: toàn bộ bộ
> phận cơ thể Axie. Trong EDITOR nó chạy vì `res://` trỏ vào đĩa thật. Trong bản EXPORT, `res://`
> chỉ có nội dung pck — mà thư mục này chưa bao giờ vào pck.
>
> **Hệ quả**: đội hình người chơi, quái dựng từ gene, preview Vault — không cái nào render được.
> Game vẫn boot (màn tutorial là chữ nên hiện bình thường), và đó chính là chỗ nguy hiểm:
> **"build thành công" là thật và hoàn toàn vô nghĩa.** Lỗi này áp cho **cả desktop lẫn web**,
> vì cùng một cơ chế pck. `include_filter` không cứu được — `.gdignore` ẩn thư mục khỏi hệ thống
> tài nguyên trước khi bộ lọc kịp nhìn thấy.
>
> Nhà cung cấp addon đặt `.gdignore` có lý do: bắt Godot import 744 file GLB là chậm và phình
> cache. Tức đây **không phải bug của họ, mà là một kiến trúc không tương thích với việc export**,
> và cần một quyết định — xem `production/wayfinder/tickets/J-axie-assets-are-not-exportable.md`.
>
> Chỉ một lần export thật + một lần mở thật trong trình duyệt mới lộ ra điều này. 41 gate xanh
> không hề đụng tới nó, vì gate nào cũng chạy trong editor, nơi đĩa thật luôn ở đó.
- [ ] `t_rules_version` xanh — tức `RULES_VERSION` đã được cân nhắc cho mọi thay đổi luật.

## 1. Ngang bằng tính năng — BẮT BUỘC

Godot đang phủ **13/22** màn của bản JS. Để cutover cần đủ những mục dưới đây:

> **Cập nhật 2026-09-20: mục §1 coi như ĐẠT, trừ hai điểm ghi rõ bên dưới.** Mỗi ô tick đều có
> gate tự động + ảnh chụp, không tick bằng cảm tính.

- [x] `scMenu` — CONTINUE RUN · GUIDES · VAULT · CODEX · SETTINGS · HOW TO PLAY. Không còn hệ
      nào đã ship mà thiếu lối vào. (Collection chưa có lối vào vì **chưa tồn tại** — đã hoãn
      sang polish, xem dưới.)
- [x] `scTeam` — class passive hiện ở cả 5 ô, đọc từ `ContentDB.CLASS_PASSIVE`
      (`t_mainmenu_ui`). **"Xoá ô đã chọn" KHÔNG port, và đây là lý do chứ không phải bỏ quên**:
      bản JS là lưới bấm-để-thêm nên có ô trống để xoá; bản này là 5 ô chọn sẵn, không có ô
      trống nào tồn tại. Yêu cầu này mất nghĩa cùng với mô hình cũ.
- [x] `scEnd` — 5 thống kê cả ván + ô RANKED ba trạng thái (`t_result_screen`, 23 check)
- [x] `scInfo` — bảng 6 tab thật trong trận (`t_codex`)
- [x] `scCodex` — 10 tab, **audit lại theo luật Godot**: 8 chỗ sai của bản JS đã sửa, trong đó
      có đúng hai chỗ file này dự đoán. Tab CLASSES/RELIC/BOSSES đọc dữ liệu lúc chạy.
- [x] Tutorial/onboarding — chạy ở lần mở đầu trên máy (`t_tutorial_flow`, 43 check).
      ⚠️ **NHƯNG nó là sân tập riêng, không phải màn combat thật bị khoá từng bước.** Luật thật,
      bàn chơi rút gọn. Người chơi mới học trên một bố cục họ sẽ không gặp lại. Chủ dự án đã
      **chủ động hoãn** phần step-lock trên `CombatView` sang polish (2026-09-20). Tick ở đây là
      "có tutorial chạy được", **không phải** "tutorial đạt chất lượng bản JS".
- [x] `scSettings` — thanh trượt có %, tắt tiếng, giảm chớp (nối thật), ABANDON RUN
      (`t_settings`, 19 check)

**Đã xong, không cần làm lại**: Vault/Import Axie · part_faces · Daily Mission · GUIDES ·
`scUnitInfo` · save/CONTINUE RUN · battle pass + unlock ladder.

**HOÃN sang phase polish — KHÔNG chặn cutover**: `scCollection`, lịch sử run.

**ĐÃ BỎ — không mở lại nếu không có ADR mới**: Cosmetics/Echo Box · World Tour · màn đăng nhập
`scGate` · NFT HP bonus (code chết trong bản live) · hiển thị ví Ronin · đồng bộ lịch sử run
lên server.

## 2. Ngang bằng chống gian lận — BẮT BUỘC nếu bản Godot có bảng xếp hạng

Kiến trúc đã chốt: ADR-0004 (Godot headless làm trọng tài).

- [x] Client gửi seed + team + nhật ký hành động, **không bao giờ gửi điểm** — `ActionLog` ghi
      quyết định, không ghi kết quả
- [x] Chơi lại được ở mức **CẢ VÁN**: `RunState` sở hữu RNG của shop/event; `RunVerifier` dựng
      lại toàn bộ `to_data()` kể cả `rng_state` (đo: seed 991237, 391 hành động, điểm 500)
- [x] Trọng tài tự tính điểm bằng **đúng hàm** game dùng (`compute_run_xp`, ngang
      `api/submit-run.js:158`)
- [x] Chạy được qua ranh giới tiến trình: `tools/record_sample_run.tscn` →
      `tools/verify_run.tscn` (tiến trình khác, chỉ đọc file JSON)
- [x] Các phép tiêm hỏng log đều bị bắt, và **ở lại làm gate vĩnh viễn**: bỏ 1 hành động / đổi
      mục tiêu / hoán vị 2 hành động / đổi phần thưởng đã lấy / sửa seed / chèn thêm lượt nhận
      thưởng / sửa dấu phiên bản
- [x] Danh sách hành động của log **và** của verifier khớp nhau, có test giữ (bản JS để hai
      danh sách "đồng bộ thủ công" và đã lệch một mục — `eventDone` — nghĩa là mọi lần nộp của
      người dính lỗi đó đều hỏng)
- [x] Từ chối log `is_complete() == false` ở **phía server**, không tin client tự khai
- [x] Lệch `rules_version`/`content_version` → từ chối với thông điệp "chơi trên phiên bản
      khác", KHÔNG phải cáo buộc gian lận
- [x] **Trọng tài chạy được, miễn phí, không máy chủ** — `.github/workflows/verify-runs.yml`
      chấm theo lô. Đo tại máy: **0,6–0,85 giây/ván** (391 nước đi). Đủ cho **beta kín** nộp
      qua pull request. ⚠️ Chưa chạy lần nào trên CI thật (chỉ chạy sau lần push đầu).
- [ ] **Endpoint nộp điểm luôn bật** — chỉ cần khi mở bảng xếp hạng CÔNG KHAI. Client không tự
      đẩy lên repo được nếu không mang credential, mà credential nhét trong game là credential
      ai cũng có. Đây là thứ duy nhất trong §2 còn cần tiền/hạ tầng.
- [ ] `api/submit-run-godot.js` chuyển tiếp sang verifier bằng secret chung; Vercel giữ quyền
      ghi Upstash và **chỉ tin điểm verifier trả về**
- [ ] Bảng xếp hạng Godot dùng **khoá riêng** (`lb:godot:*`) — 18 hàng so với 12 hàng nghĩa là
      điểm hai bản chưa bao giờ so sánh được
- [ ] Ghi nhận thành văn bản: undo cuộn lại RNG (khác JS) và bản đồ 18 hàng — **đã ghi ở
      ADR-0004**, tick khi đã được đọc và chấp nhận

> **Rủi ro CÒN LẠI, chấp nhận có ý thức** (security-engineer xếp hạng; bản JS live cũng y hệt):
> log do bot/giải tối ưu nộp nguội · chọn seed đẹp · nộp lại log người khác · lạm dụng tần suất.
> Mức cần đạt của lần cutover này là **ngang bằng bản đang live**, không phải hoàn hảo.

## 3. QA ký duyệt — BẮT BUỘC

Bản port cần **biến thể riêng**, không dùng nguyên `/launch-checklist` (cửa hàng/marketing/pháp
lý — không liên quan) và không chỉ `/release-checklist`. Cụ thể:

- [ ] `/release-checklist pc` — chỉ phần sức khoẻ bản build
- [ ] `/regression-suite` — ánh xạ test với đường đi then chốt trong GDD
- [ ] `/soak-test` — một phiên chơi dài
- [ ] `/smoke-check` — cổng trước khi bàn giao QA
- [ ] `/team-qa` ra kết luận **APPROVED** hoặc **APPROVED WITH CONDITIONS**

Lý do cần biến thể riêng: **không skill nào có sẵn kiểm "ngang bằng với bản tiền nhiệm" và
"liên tục dữ liệu người chơi thật"** — hai thứ duy nhất thực sự nguy hiểm ở lần cutover này.
Chính file này là biến thể đó.

## 4. Kế hoạch lùi — BẮT BUỘC

- [ ] Gắn tag `pre-godot-cutover` trên `main`; bản deploy cũ giữ nguyên, khôi phục được bằng
      một cú bấm
- [ ] **Không xoá `src/` và `api/` khi cutover.** Xoá là một PR riêng, sau này
- [ ] **Merge ≠ deploy**: merge trước, deploy bản Godot là bước riêng
- [ ] Bảng xếp hạng: điểm Godot vào **mùa/bảng mới** khoá theo phiên bản; lịch sử JS đóng băng
      ở chế độ chỉ đọc. Lùi = deploy lại bản JS + ẩn mùa mới. **Không xoá, không ghi đè dòng
      nào** — đây là thứ duy nhất trong danh sách này không thể hoàn tác
- [ ] Ghi rõ **điều kiện kích hoạt lùi** và **ai được quyết**, trước khi merge

## 5. Ai ký

Theo `.claude/docs/coordination-rules.md`:

- [ ] `technical-director` — trọng tài + kiến trúc
- [ ] `qa-lead` — bằng chứng kiểm thử
- [ ] `creative-director` — ngang bằng trải nghiệm & phần dạy người chơi
- [ ] `producer` — tổng hợp
- [ ] **Chủ dự án ký — BẮT BUỘC.** Lần này không phải một bản phát hành thông thường: nó **cho
      nghỉ hưu một build đang phục vụ người chơi thật**. Không uỷ quyền nào bao được việc đó.

---

## Ba cái bẫy đã biết

1. **Bỏ màn đăng nhập = bỏ luôn danh tính** — mà bảng xếp hạng thì cần danh tính. Nếu bản Godot
   ship kèm ranked, hệ Account (đang 0%) quay lại thành BẮT BUỘC. Nếu không ship ranked, toàn
   bộ mục §2 được miễn — nhưng **đó là bỏ một tính năng người chơi đang có, và cần chủ dự án
   ký**.
2. **Không hẹn ngày cho §2** khi hộp verifier chưa dựng.
3. **Liên tục dữ liệu bảng xếp hạng là mục duy nhất không thể hoàn tác.** Mọi thứ khác lùi được.
