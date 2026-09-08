# Onboarding Tutorial (Mandatory)

> **Status**: Draft — chờ implement
> **Ngày**: 2026-09-08
> **QA pre-implementation review**: 2026-09-08, verdict READY WITH FIXES (đã áp dụng vào bản này) — xem `.claude/agent-memory/qa-lead/project_onboarding-tutorial-qa-review.md`. Đã xác nhận bằng code thật (không chỉ tin theo lời draft): `newGame()` deterministic qua `mkRng`, click-click và kéo-thả cùng gọi `doTarget()`/`clickDie()`, code tutorial cũ (`TUT[]`/`tutOverlay()`/`tut`) chưa từng có entrypoint kích hoạt (comment tại `client.html`~3958 xác nhận đây là quyết định sản phẩm trước đó: tutorial cũ từng bị tắt hẳn và chuyển vào CODEX dạng tự nguyện — việc bật lại tutorial bắt buộc ở tài liệu này là đảo ngược quyết định đó, không phải khôi phục một tính năng đang chạy).

## 1. Overview

Tutorial bắt buộc, 6 bước, thời lượng mục tiêu ≤120 giây, chạy ngay sau lần đăng ký/đăng nhập ĐẦU TIÊN của một tài khoản — trước khi vào `screen==='menu'`. Mục tiêu là dạy đủ để chơi trận thật đầu tiên có chủ đích: đọc intent địch, REROLL, EXECUTE (chọn die → chọn target), END TURN, và chọn thưởng. Tutorial KHÔNG dạy các hệ nâng cao (relic, gene mutation, archetype tracker, ascension, class passive) — các hệ đó để lại cho contextual tooltip lần đầu người chơi gặp thật, ngoài scope tài liệu này.

Ba quyết định đã chốt cho lần triển khai này (ghi đè lên mọi phương án khác từng được cân nhắc ở bản draft trước):

1. Xóa hoàn toàn code tutorial cũ đã chết (`TUT[]`, `tutOverlay()`, biến module-level `tut`) khi implement — không giữ song song 2 hệ.
2. Account có `META.runs===0` nhưng đã Vault-import Axie (chưa từng đánh trận thật) vẫn bị bắt học tutorial — không có ngoại lệ.
3. Mock battle dùng đủ 5 Axie (party strip đầy đủ), không phải 1 Axie đơn.

## 2. Player Fantasy

Học bằng thao tác thật (learn-by-doing), không phải đọc slide. Cảm giác mục tiêu: "tôi vừa tự tay thắng 1 trận nhờ hiểu đúng luật" ngay từ phút chơi đầu tiên — nhất quán với player fantasy cốt lõi ở `game-concept.md`: "minh bạch triệt để" (thắng vì tính đúng, không phải may mắn). Về MDA, tutorial phục vụ chủ yếu aesthetic **Competence** (Self-Determination Theory) qua feedback tức thời và rõ ràng, và **Discovery** ở mức thấp (khám phá luật chơi qua thao tác, không qua văn bản).

## 3. Detailed Rules

### 3.1 Cơ chế nền

Dùng `newGame(TUT_SEED, TUT_TEAM, opt)` (đã có sẵn trong `engine.js`, hiện dùng để dựng seed chống gian lận leaderboard qua replay) để tạo ra một `S` (game state) hợp lệ, deterministic. Fixture này KHÔNG được ghi vào `META.runs`, không gửi leaderboard, không phát telemetry thật.

`TUT_TEAM` = đủ 5 Axie cố định (party strip đầy đủ, theo quyết định #3 ở trên).

Render bằng đúng các hàm production hiện có — `scCombat()`, `track()`, `partyStrip()` — không dựng UI riêng cho tutorial. Lý do: luôn khớp UI mới nhất, không phải maintain 2 bộ UI song song khi combat UI thay đổi sau này.

**Ràng buộc bắt buộc trên `opt`** (QA fix — xác nhận bằng code: `META.runs++` chạy ngay lúc bắt đầu run thật, `submitRun()` chỉ chạy khi `S.phase==='won'`): `opt` truyền vào `newGame()` cho fixture tutorial **không được** khiến `S.phase` chạm `'won'` trong phạm vi 6 bước (ví dụ không đặt `len` sao cho enemy chết ở bước 5 đồng thời kết thúc luôn cả run) — mục tiêu là dừng ở `S.phase==='reward'` sau khi thắng 1 encounter, không bao giờ đi xa tới điểm submit leaderboard thật. Đây là điều kiện ẩn phải giữ đúng khi chọn `opt`, không phải điều tự nhiên xảy ra.

### 3.2 Trigger và Gate

```
needsTutorial = !META.tut && META.runs === 0
```

`META.runs===0` là lớp phòng hờ thứ hai (belt-and-suspenders): nếu trong tương lai `META.tut` bị thiếu hoặc sai do bug/migration trên save cũ, `runs>0` vẫn đảm bảo không bao giờ ép người chơi đã từng chơi thật quay lại tutorial.

Theo quyết định #2: KHÔNG có ngoại lệ cho account chỉ Vault-import Axie — `runs===0` vẫn bắt học dù tài khoản đó đã import Axie nhưng chưa từng đánh trận thật.

Gate check phải chạy ở **2 điểm code khác nhau**, cả hai đều bắt buộc (thiếu một điểm là có lỗ hổng để né tutorial):

1. **Sau xác thực thành công.** Hiện tại `screen='menu'` bị gán rải rác ở ≥6 nơi khác nhau trong `doAuth()` (nhánh register/login), 4 nhánh của `pullSyncAfterLogin`, `resolveConflictKeepLocal()`, `resolveConflictUseCloud()`. Cần gom tất cả về **một hàm chốt duy nhất**, `enterMenu()`, mà mỗi nơi ở trên gọi thay vì gán `screen='menu'` trực tiếp. `enterMenu()` chạy gate check rồi tự quyết định `screen='tutorial'` hay `screen='menu'`.

   Điều kiện bắt buộc: `enterMenu()` phải chạy SAU KHI `META` đã được gán từ `serverMeta` (dòng dạng `META={...DEF_META,...serverMeta,owner:authUsername}`), không phải trước — nếu chạy trước, gate sẽ đọc nhầm `META.tut` cũ trên máy hiện tại thay vì giá trị thật đã đồng bộ từ cloud.

2. **Lúc boot lại trang khi đã có token sẵn** (`window.addEventListener('load', ...)`). Hiện tại đoạn này set thẳng `screen` mặc định là `'menu'`, không đi qua `enterMenu()`. Phải sửa để gọi cùng gate check — nếu không, người chơi refresh trang ngay sau khi đăng ký/đăng nhập sẽ né được tutorial hoàn toàn.

### 3.3 Hard block

- `screen==='tutorial'` KHÔNG được thêm vào `ESC_TO_MENU_SCREENS` — giống cách `scGate()` (màn hình đăng nhập bắt buộc) đã tự loại mình ra khỏi danh sách đó. Nhấn Esc trong tutorial không được thoát ra menu.
- KHÔNG có nút Skip lộ ra cho người chơi thật — đúng yêu cầu "bắt buộc". (So sánh: code cũ đã xóa từng có nút SKIP trong `tutOverlay()` — hệ mới không có tương đương.)
- QA/dev test dùng `devtools.js` (`devGo()` — bị `build.py public` strip khỏi bản public) để nhảy thẳng qua màn hình bất kỳ, bao gồm bỏ qua tutorial khi test. Không cần xây riêng cơ chế skip cho mục đích QA.

### 3.4 6 bước

| # | Khái niệm | Khóa UI | Copy (1 câu) | Điều kiện hoàn thành |
|---|---|---|---|---|
| 1 | ROLL (tự động) | mọi thứ trừ vùng đọc | "5 Axie của bạn vừa roll — mỗi mặt là một bộ phận thật." | 1 tap bất kỳ trong vùng cho phép |
| 2 | Đọc intent địch | chỉ click thẻ địch | "Địch sẽ đánh ai, bao nhiêu — bạn biết trước 100%." | click thẻ địch mở `scUnitInfo()` (tái dùng modal có sẵn) |
| 3 | REROLL | chỉ nút REROLL + toggle mark | "Đánh dấu die muốn đổi, hoặc bấm REROLL không đánh dấu gì để đổi cả 5." | 1 lần bấm REROLL |
| 4a | EXECUTE — chọn die | chỉ 1 die được dạy (glow border, tái dùng CSS class hiệu ứng pulse có sẵn) | "Click die này." | `sel===uid` đúng die được chỉ định |
| 4b | EXECUTE — chọn mục tiêu | chỉ 1 target hợp lệ | "Giờ click (hoặc kéo-thả) vào địch này." | `doTarget()` bắn trúng đúng target — chấp nhận cả click và drag |
| 4c | (không khóa) gợi ý Undo, tự tắt ~4s | — | "Lỡ tay? Ctrl+Z hoàn tác — miễn phí tới khi bạn Reroll hoặc End Turn." | không có điều kiện hoàn thành, chỉ là toast thoáng qua |
| 5 | END TURN | chỉ nút END TURN | "Địch giờ thực hiện đúng điều đã báo trước. Bấm END TURN." | bấm nút (Enter/Space vốn đã trỏ vào `.btn.end` khi nó có focus, dùng được ngay) |
| 6 | Chọn thưởng 1/3 | 3 thẻ thưởng thật (`scReward()`) | "Chọn 1. Cả 3 đều tốt — đây là lúc bạn định hình lối chơi." | click 1 trong 3 thẻ |

Sau bước 6: `META.tut=1; saveMeta();` rồi `screen='menu'`.

`TUT_ENEMY_HP` phải được tune để người chơi LUÔN thắng trong ≤2-3 lượt bằng đúng thao tác được dạy ở bảng trên — không cần build skill, không có nhánh thua trong toàn bộ tutorial.

### 3.5 Tích hợp UI

- 1 screen mới, `screen==='tutorial'`, xử lý bởi hàm mới `scTutorial()`, thêm 1 nhánh vào chuỗi if/else của `render()`.
- **`scTutorial()` phải tự dispatch theo `S.phase`** (QA fix — gap thật, không phải diễn giải quá mức): khi enemy chết ở bước 5, `S.phase` chuyển từ `'combat'` sang `'reward'` — `scTutorial()` không được luôn gọi cứng `scCombat(false)`, mà phải kiểm `S.phase` và gọi `scCombat(false)` khi `'combat'` hoặc `scReward()` khi `'reward'`, giống cách `render()` chính đang dispatch cho luồng game thật. Thiếu bước này, bước 6 (chọn thưởng) sẽ không bao giờ hiện ra.
- Overlay hướng dẫn (hint/lock) đặt tên `tutCoachOverlay()` (khác tên với `tutOverlay()` cũ — đã bị xóa theo quyết định #1, không tái dùng tên để tránh nhầm lẫn khi tìm code cũ trong lịch sử git). Overlay này append lên trên bất kỳ hàm render nào đang active (`scCombat()` hoặc `scReward()`) theo dispatch ở trên.
- Bàn phím: element được phép ở mỗi bước dùng lại `kbAct()` sẵn có (đã tự gọi `ev.stopPropagation()` sau khi xử lý phím). Thêm một guard tường minh ở đầu handler `keydown` toàn cục: nếu `screen==='tutorial' && tutStep!==STEP_ENDTURN` thì bỏ qua Enter/Space cho `.btn.end`, không chỉ dựa vào việc phần tử đó có đang được focus hay không — vì shortcut Enter/Space-kết-thúc-lượt toàn cục vốn hoạt động độc lập với focus.
- Tái dùng thật (không viết UI riêng): bước 2 dùng `scUnitInfo()`; bước 6 dùng `scReward()`.
- Khóa-bước (step-lock) phải chấp nhận CẢ HAI input path đồng thời: click-click và pointer-event drag-and-drop tự viết (`bindDrag()`, state `dragging`, `pointermove`/`pointerup` gọi thẳng `doTarget()` — cùng hàm click-click dùng). Cách triển khai: đặt class `body.tut-locking` với CSS `pointer-events:none`, rồi `pointer-events:auto!important` trên đúng (các) phần tử được phép ở bước hiện tại. Cách này chặn được cả click và drag bằng một cơ chế duy nhất, thay vì viết guard riêng cho từng loại input.
- **UI-rule coverage bắt buộc (QA fix)**: `tools/verify.mjs` không tự khám phá screen mới — nó lái qua `devGo(k)` theo một danh sách cố định. Phải thêm case `devGo('tutorial')` trong `src/devtools.js` VÀ thêm `'tutorial'` vào danh sách screen mà `tools/verify.mjs` duyệt qua, nếu không 8 UI rule (contrast/tap-target/layout-shift/NaN-leak) sẽ không bao giờ chạy trên tutorial dù `node tools/ci.mjs` vẫn báo xanh 11/11.

### 3.6 Không dạy trong tutorial này

Relic, gene mutation, archetype tracker, ascension, class passive. Các hệ này dùng contextual tooltip lần đầu người chơi gặp thật trong game — nằm ngoài scope tài liệu này, không thiết kế ở đây.

## 4. Formulas

| Biến / Knob | Định nghĩa | Giá trị đề xuất | Ví dụ / Ghi chú |
|---|---|---|---|
| `needsTutorial` | boolean, điều kiện kích hoạt tutorial | `!META.tut && META.runs === 0` | `META.tut=0, META.runs=0` → `true`. `META.tut=1, META.runs=0` → `false`. `META.tut=0, META.runs=5` (save cũ, migration chưa chạy) → `false` nhờ vế thứ 2 — đây chính là "lớp phòng hờ" mô tả ở §3.2 |
| `TUT_SEED` | hằng số seed truyền vào `newGame(seed, team, opt)` để tạo fixture deterministic | hằng số cố định, ví dụ `1` | KHÔNG được đổi sau khi ship — đổi giá trị này đổi luôn chuỗi roll đầu tiên hiển thị cho mọi người chơi mới, phá vỡ kịch bản bước 1-4 đã được viết copy khớp với 1 chuỗi mặt cụ thể |
| `TUT_TEAM` | mảng 5 Axie cố định dùng làm party fixture | 5 Axie cụ thể, cố định | Phải đảm bảo roll đầu tiên tại `TUT_SEED` cho ra ≥1 mặt damage và ≥1 mặt utility, để bước 4a/4b luôn có ít nhất một lựa chọn hợp lệ đúng kịch bản |
| `TUT_ENEMY_HP` | HP của địch trong mock battle | tune để thắng chắc trong ≤3 lượt bằng đúng thao tác được dạy | Không có công thức tổng quát — xác minh bằng 1 lần playthrough cố định với `TUT_SEED`/`TUT_TEAM` đã chốt, rồi khóa giá trị |
| Thời lượng mục tiêu | tổng thời gian ước tính từ bước 1 đến bước 6 | ≤120 giây | Playtest-validate độ dài copy và số bước; không phải công thức tính được, chỉ là ngưỡng chấp nhận |
| Số bước | số bước cố định trong luồng tutorial | 6 | Không mở rộng nếu chưa revisit scope tài liệu này |

**Ví dụ tính `needsTutorial` cụ thể:**
- Account mới toanh, chưa từng đăng nhập: `META={...DEF_META}` → `tut=0, runs=0` → `needsTutorial=true`.
- Account cũ, đăng nhập máy mới, `pullSyncAfterLogin` đã kéo `serverMeta` có `runs=12, tut=1`: `needsTutorial=false`.
- Account cũ, `tut` bị mất do lỗi migration nhưng `runs=8` (đã chơi thật): `needsTutorial=false` nhờ vế `runs===0` — đây là lý do vế thứ 2 tồn tại, không phải phòng hờ thừa.

## 5. Edge Cases

- **Thoát giữa chừng / mất mạng khi đang ở `screen==='tutorial'`.** Vì state dùng là fixture (`newGame(TUT_SEED,...)`), không phải save thật, không cần checkpoint từng bước. Vào lại app sẽ chạy lại gate check, thấy `needsTutorial` vẫn `true`, quay lại `screen==='tutorial'` và chạy lại từ bước 1. Chấp nhận được vì tổng thời lượng tutorial ≤120 giây.
- **Refresh trang (F5) để cố né tutorial.** Gate check chạy ở CẢ HAI code path (post-auth qua `enterMenu()`, và boot-với-token-sẵn trong `window.addEventListener('load', ...)`) → F5 ở bất kỳ bước nào chỉ đưa người chơi về lại `screen==='tutorial'` từ bước 1, không rơi vào `'menu'`.
- **Refresh xảy ra trước khi debounce sync (~5 giây) kịp đẩy `tut=1` lên server sau khi hoàn thành bước 6.** Không gây lỗi nghiêm trọng: local `META.tut` vẫn là `0` cho tới khi debounce chạy xong, nên refresh trong khoảng đó sẽ cho hiện lại tutorial một lần nữa. Hệ quả nghiêng về phía an toàn hơn ("vẫn bắt học thêm 1 lần" thay vì "né được tutorial") — chấp nhận được, không cần fix thêm.
- **Account cũ đăng nhập trên máy mới.** `pullSyncAfterLogin` kéo `META` thật từ server (gồm `tut`/`runs`) về TRƯỚC KHI `enterMenu()` chạy gate check (đúng thứ tự bắt buộc ở §3.2) → tự động không bị ép học lại, miễn là gán `META={...DEF_META,...serverMeta,...}` luôn xảy ra trước lời gọi `enterMenu()`.
- **Account chỉ Vault-import Axie, `META.runs===0`.** Theo quyết định #2: VẪN bị bắt học tutorial, không có ngoại lệ, dù tài khoản đó đã có Axie import từ Vault.
- **Push sync lên server thất bại vĩnh viễn ở thiết bị A sau khi hoàn thành tutorial, người chơi sau đó đăng nhập ở thiết bị B (QA fix — khác với case refresh-cùng-máy ở trên).** Nếu thiết bị A không bao giờ đẩy `tut=1` lên server thành công (offline vĩnh viễn, hoặc gỡ app trước khi debounce chạy), thiết bị B khi `pullSyncAfterLogin` sẽ kéo về `serverMeta.tut` vẫn là giá trị cũ → bị bắt học lại tutorial dù đã hoàn thành ở A. Severity thấp (học lại tối đa 1 lần, ≤120 giây), chấp nhận được — không cần cơ chế bù trừ thêm, nhưng phải ghi nhận đây là hành vi đã biết, không phải bug bỏ sót.
- **Migration save cũ (đã tồn tại trước khi tính năng này ship).** `migrateMeta()` phải backfill `tut=1` cho mọi save có `runs>0` tại thời điểm ship, để không ép người chơi cũ (đã từng chơi thật nhiều trận) phải học lại tutorial lần đầu tiên họ mở game sau bản cập nhật.
- **Bước 4c (gợi ý Undo) hết 4 giây mà người chơi chưa thao tác gì ở bước 4b.** Toast tự tắt, không khóa tiến trình — bước 4b vẫn đang chờ input hợp lệ, không có time-out nào áp lên bước 4b tự nó.
- **Người chơi bấm REROLL nhiều lần liên tiếp ở bước 3.** Điều kiện hoàn thành bước 3 chỉ cần "1 lần bấm REROLL" — bấm thêm lần nữa (nếu game cho phép) không phá điều kiện, chỉ đơn giản là bước 3 đã coi là hoàn thành từ lần bấm đầu tiên và chuyển sang bước 4a.

## 6. Dependencies

- `design/gdd/player-accounts.md` — cung cấp: app gate mandatory-login, `pullSyncAfterLogin`, cấu trúc field `META`. Tutorial phụ thuộc vào việc `META` đã được gán đúng thứ tự (server trước, gate check sau) như mô tả ở §3.2.
  - **Lưu ý ngược (chưa thực hiện trong lượt này):** `player-accounts.md` cần được cập nhật thêm một câu tham chiếu tới hệ thống tutorial mới ở mục Dependencies của chính nó, vì luồng đăng nhập mà nó mô tả giờ rẽ vào `screen==='tutorial'` thay vì đi thẳng `'menu'` — đây là một thay đổi hành vi thực sự đối với `player-accounts.md`, không chỉ là một tham chiếu mới một chiều. Việc sửa `player-accounts.md` nằm ngoài scope của tài liệu này và KHÔNG được thực hiện ở đây.
- `design/gdd/game-concept.md` — cung cấp: core loop 4 bước (roll → đọc intent → reroll/execute → end turn), pillar "minh bạch triệt để", cơ chế `newGame(seed,...)` dùng làm nền cho fixture deterministic.
- `src/engine.js` (`newGame()`) — cung cấp cơ chế seed để tạo state deterministic; tutorial là một use case thứ hai của cơ chế này (use case đầu là chống gian lận leaderboard qua replay).
- `src/client.html` — toàn bộ điểm neo kỹ thuật: `scCombat()`, `scUnitInfo()`, `scReward()`, `bindDrag()`, `kbAct()`, `render()`, `ESC_TO_MENU_SCREENS`, `DEF_META`, `doAuth()`, `pullSyncAfterLogin()`, `window.addEventListener('load',...)`.

## 7. Tuning Knobs

| Knob | Category | Range đề xuất | Lý do |
|---|---|---|---|
| `TUT_SEED` | Curve (nhưng khóa cứng sau ship) | 1 hằng số, không đổi sau khi ship | Đổi seed đổi luôn roll đầu tiên hiển thị — phá kịch bản copy đã viết khớp với 1 chuỗi mặt cụ thể |
| `TUT_TEAM` | Curve | 5 Axie cố định | Cần roll đầu tại `TUT_SEED` cho ra ≥1 mặt dmg + ≥1 mặt utility; mọi thay đổi `data.js` (rebalance part/face) sau này phải được test lại để không âm thầm phá kịch bản này (xem test ở §8) |
| `TUT_ENEMY_HP` | Gate | tune để thắng chắc ≤3 lượt | Xác minh bằng playthrough cố định 1 lần khi khóa `TUT_SEED`/`TUT_TEAM` |
| Thời lượng mục tiêu | Feel | ≤120 giây | Playtest-validate độ dài copy và nhịp độ 6 bước |
| Thời gian hiển thị gợi ý Undo (bước 4c) | Feel | ~4 giây | Đủ để đọc 1 câu ngắn, không chặn tiến trình bước 4b |
| Số bước | Gate | 6, cố định | Không mở rộng nếu chưa revisit scope tài liệu này |

Tất cả knob trên phải sống trong data file (theo `coding-standards.md`: "Gameplay values must be data-driven"), không hardcode rải rác trong `client.html`.

## 8. Acceptance Criteria

- GIVEN tài khoản mới đăng ký lần đầu, WHEN đăng ký thành công, THEN `screen` chuyển sang `'tutorial'`, không phải `'menu'`.
- GIVEN `screen==='tutorial'`, WHEN người chơi click vào phần tử ngoài phần tử được phép ở bước hiện tại (kể cả thao tác kéo-thả), THEN không có hành động game nào được thực thi.
- GIVEN đang ở bước 3 (REROLL), WHEN nhấn Enter/Space mà không có phần tử nào đang focus, THEN nút END TURN không bị kích hoạt sớm.
- GIVEN tutorial đang mở ở bất kỳ bước nào, WHEN reload trang (F5), THEN quay lại `screen==='tutorial'` từ bước 1, không rơi vào `'menu'`.
- GIVEN account cũ có `META.runs>0` (hoặc `META.tut===1` sau khi cloud sync xong) đăng nhập trên máy mới, WHEN `pullSyncAfterLogin` hoàn tất, THEN vào thẳng `'menu'`, không bị ép vào tutorial.
- GIVEN account chỉ Vault-import Axie và `META.runs===0`, WHEN đăng nhập, THEN vẫn bị đưa vào `screen==='tutorial'` (không có ngoại lệ, theo quyết định #2).
- GIVEN hoàn thành bước 6 (chọn 1 trong 3 thẻ thưởng), WHEN lựa chọn được xác nhận, THEN `META.tut` được set thành `1`, `saveMeta()` được gọi, và `screen` chuyển thành `'menu'`.
- GIVEN đang ở bước 4b, WHEN người chơi hoàn thành bằng click-click HOẶC bằng kéo-thả, THEN cả hai input path đều được chấp nhận là hợp lệ.
- GIVEN `TUT_SEED`/`TUT_TEAM` đã khóa cố định, WHEN chạy fixture nhiều lần trên bất kỳ máy nào, THEN chuỗi roll đầu tiên luôn giống hệt nhau — kiểm chứng bằng `tools/t_tutorial.mjs` assert đúng chuỗi mặt kỳ vọng, để một lần rebalance `data.js` trong tương lai không âm thầm phá kịch bản tutorial mà không bị CI bắt.
- GIVEN roll đầu tiên tại `TUT_SEED`/`TUT_TEAM` (QA fix — tách riêng khỏi AC determinism ở trên, vì 2 lần chạy khớp nhau không tự chứng minh nội dung đúng), WHEN kiểm tra các mặt đã roll của phe người chơi, THEN có ≥1 mặt `type==='dmg'` và ≥1 mặt utility (heal/mana/shield) — đúng yêu cầu ở §4 để bước 4a/4b luôn có lựa chọn hợp lệ.
- GIVEN `TUT_ENEMY_HP` đã khóa (QA fix — trước đây thiếu AC cho giá trị Config/Data này), WHEN chơi hết mock battle bằng đúng thao tác được dạy ở bảng §3.4, THEN trận luôn thắng trong ≤3 lượt — xác minh bằng 1 lần smoke-check playthrough cố định, ghi vào `production/qa/smoke-[date].md` theo bảng Test Evidence của `coding-standards.md`.
- GIVEN hàm `needsTutorial(meta)` (QA fix — đề xuất tách thành hàm thuần, export được, thay vì để inline trong `enterMenu()`), WHEN gọi với 4 case: `{tut:0,runs:0}`, `{tut:1,runs:0}`, `{tut:0,runs:5}` (save cũ trước migration), `{tut:0,runs:0}` sau khi Vault-import (không có field runs riêng cho import), THEN kết quả khớp đúng bảng ví dụ ở §4 — kiểm chứng bằng unit test thuần Node trong `tools/t_tutorial.mjs`, không cần Playwright, theo mẫu `t_relic.mjs`.
- GIVEN `migrateMeta()` chạy trên một save cũ dạng `{runs:5, tut:undefined}` (QA fix), WHEN migration hoàn tất, THEN `tut===1` (backfill đúng theo Edge Case "Migration save cũ" ở §5) — kiểm chứng bằng 1 test riêng trong `tools/t_tutorial.mjs`.
- GIVEN code cũ `TUT[]`, `tutOverlay()`, biến module-level `tut`, WHEN việc implement tính năng này hoàn tất, THEN các định danh này không còn tồn tại trong `client.html` (đã xóa hoàn toàn theo quyết định #1) và mọi tham chiếu tới `META.tut` dùng biến đếm bước mới `tutStep` để tránh nhập nhằng tên — kiểm chứng bằng 1 check grep-based trong `tools/t_tutorial.mjs`, theo đúng kiểu check drag-and-drop hiện có trong `.claude/docs/technical-preferences.md`.
- GIVEN `'tutorial'` được thêm vào danh sách screen của `devGo()`/`tools/verify.mjs` (QA fix, xem §3.5), WHEN `node tools/ci.mjs` chạy, THEN 8 UI rule (contrast/tap-target/layout-shift/NaN-leak) thực sự thực thi trên `screen==='tutorial'`, không chỉ trên các screen đã có từ trước.
