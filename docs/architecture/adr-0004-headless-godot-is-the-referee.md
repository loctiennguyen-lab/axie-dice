# ADR-0004: Bản Godot headless chạy trên server LÀ trọng tài (replay-verify)

## Status
Accepted (2026-09-19). Chốt sau khi hỏi `technical-director` và `security-engineer`; chủ dự án
ra lệnh làm ngay trong phiên. Giải quyết wayfinder ticket **A**, mở khoá ticket **H**.

## Date
2026-09-19

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2, GDScript (nhánh `godot-port`) |
| **Domain** | Core / Networking — `action_log.gd`, `run_verifier.gd`, `tools/verify_run.gd`, `RunState`, `CombatEngine` |
| **Knowledge Risk** | LOW — không API nào mới sau 4.3; `HashingContext`, `OS.get_cmdline_user_args`, `FileAccess` đều có từ 4.0 |
| **References Consulted** | `api/submit-run.js`, `api/_engine.js`, ADR-0001, `docs/godot-port-gap-inventory.md` §3, ticket A |
| **Post-Cutoff APIs Used** | Không |
| **Verification Required** | Đã xong — xem Validation Criteria |

## ADR Dependencies

- **ADR-0001** (Leaderboard Backend) — định nghĩa "Ranked Run" và cơ chế replay hiện tại của bản
  JS. ADR này là bản tương đương cho Godot, giữ NGUYÊN ranh giới tin cậy đó.

## Context

Bản JS đang live chống gian lận được vì **client không bao giờ gửi điểm**. Nó gửi
`{seed, teamKeys, mode, ascension, actions}`; `api/submit-run.js` nạp `src/engine.js` vào một
Node VM, **chơi lại** đúng chuỗi hành động đó và tự tính điểm. Điểm giả không bị từ chối — nó
không tồn tại để mà giả.

Luật của bản port nằm trong ~3.000 dòng GDScript. Node VM không chạy được GDScript. Sáu hướng đã
được ghi ra (gap inventory §3): (A) Godot headless làm trọng tài · (B) biên dịch engine sang
WebAssembly chạy trong Node · (C) viết lại luật bằng TypeScript · (D) server ký seed, client báo
điểm · (E) hai bảng xếp hạng riêng · (F) bỏ hẳn bảng xếp hạng ở bản Godot.

## Decision

**Chọn (A): một bản Godot headless chạy trên server làm trọng tài.** Vercel vẫn là cửa trước —
nó giữ credential Upstash và quyền ghi bảng xếp hạng, gọi sang hộp verifier qua secret chung, và
**chỉ tin con điểm mà verifier trả về**. Hộp verifier không bao giờ cầm credential bảng xếp hạng.

Lý do quyết định, theo đúng thứ tự trọng lượng:

1. **Một bộ luật duy nhất, không thể trôi.** (C) đòi duy trì bản sao TypeScript của 3.000 dòng
   GDScript, bit-exact, mãi mãi — và ngày hai bên bất đồng thì **không ai biết bên nào đúng**.
   Trôi lệch giữa hai bản cài đặt của cùng một luật chính là lớp lỗi đã sinh ra phần lớn bug của
   bản port này (inventory §6). (A) không có bản sao nào để trôi.
2. **(B) mua đúng tính chất của (A) với giá đắt hơn nhiều** và không ai ở đây từng làm.
3. **(D) không phải chống gian lận** — nó là bước lùi so với thứ người chơi đang có.
4. **(F) xoá một tính năng đang sống.**

**Chi phí thật, nói thẳng vì chủ dự án là người trả**: một máy Linux nhỏ luôn bật, chạy Docker
image gồm Godot headless + bản export + script verify. Fly.io `shared-cpu-1x/512MB` hoặc Hetzner
CX22 — **khoảng 4–6 USD/tháng**, một hoá đơn.

### Các quyết định phụ, chốt luôn trong ADR này

- **Undo: GIỮ NGUYÊN hành vi của Godot, không sửa.** Undo của Godot là khôi phục ảnh chụp và
  **cuộn lại cả con trỏ RNG**; undo của JS thì không. Điều đó chỉ thành vấn đề nếu hai bộ luật
  phải khớp từng bit — tức là dưới phương án (C). Khi bản Godot tự làm trọng tài cho chính nó,
  cuộn-lại-RNG **chính là luật**, và nó là luật CHẶT hơn: undo của JS cho phép quay lại ăn may
  một kết quả roll khác, undo của Godot thì làm lại y hệt. Cái nó cho phép là *nhìn trước rồi
  đổi ý* (thử A, thấy kết quả, undo, làm B) — đó là câu hỏi cân bằng, không phải lỗ hổng bảo mật,
  và bị giới hạn bởi việc stack undo bị xoá mỗi khi reroll hoặc hết lượt.
- **Cần ENGINE_VERSION tương đương: CÓ.** `ActionLog.RULES_VERSION` + `content_version` đóng dấu
  từ `part_faces.json`. Verifier từ chối log lệch phiên bản với thông điệp "chơi trên phiên bản
  khác", đúng tư thế 409 của bản JS — **không phải** buộc tội gian lận.
- **Bảng xếp hạng Godot PHẢI tách khỏi bảng JS.** Bản đồ 18 hàng so với 12 hàng nghĩa là điểm hai
  bản chưa bao giờ so sánh được với nhau. Khoá riêng, ví dụ `lb:godot:<mode>:<asc>`.
- **Chỉ verify được run RANKED.** Run thường bắt đầu bằng unlock nằm trong save của riêng người
  chơi (reroll thêm, HP thêm, relic khởi đầu); `MetaState.run_bonuses(true)` trả về toàn số 0 cho
  run ranked chính vì lý do đó. Verifier từ chối log không ranked thay vì đoán.

## Alternatives Considered

Xem bảng 6 phương án ở `docs/godot-port-gap-inventory.md` §3 — giữ nguyên ở đó, không chép lại.
Điểm khác biệt duy nhất so với lúc viết bảng đó: **rào cản "phải sửa lớn mới replay được cả ván"
hoá ra nhỏ hơn** — RNG của shop/event vốn đã là `Rng.derive_combat_seed(run_seed, node_id, salt)`,
tức hàm thuần của seed, chỉ **nằm sai chỗ** (màn hình bản đồ sở hữu nó). Chuyển quyền sở hữu về
`RunState` là refactor, không phải thiết kế lại — đã làm xong trong chính phiên này.

## Consequences

**Tích cực**
- Trọng tài và trò chơi là **cùng một mã nguồn**; không thể lệch.
- Ranh giới tin cậy giữ y hệt bản JS: client gửi quyết định, server tính điểm.
- Bộ máy này dùng lại được ngoài chống gian lận: phát lại một ván để gỡ lỗi, để quay video, để
  DevReview.

**Tiêu cực / nợ đã biết**
- **Phải nuôi một máy chủ.** Vercel một mình không đủ. Đây là thay đổi vận hành thật.
- **Những gì vẫn KHÔNG chặn được** (security-engineer xếp hạng, và bản JS live **cũng y hệt**):
  log do bot hoặc do người giải tối ưu rồi nộp nguội · chọn seed đẹp mới nộp · nộp lại log của
  người khác (chưa cơ chế nào buộc log vào danh tính) · lạm dụng tần suất. Đây là mức **ngang
  bằng** bản đang live, và ngang bằng mới là thước đo đúng cho lần cutover này — không phải
  hoàn hảo.
- Log chưa được ký và chưa buộc vào danh tính; việc đó đi cùng hệ Account, vẫn ở 0%.

## GDD Requirements Addressed

- `design/gdd/leaderboard-system.md` — tính toàn vẹn của bảng xếp hạng.
- `design/gdd/godot-port-rule-spec.md` §6 — Vault làm run mất tư cách ranked.

## Validation Criteria

Đã chạy thật, không phải dự định (2026-09-19):

1. **Chơi lại một TRẬN**: `t_replay` dựng lại trận từ seed + log, so sánh toàn bộ `to_data()` kể
   cả `rng_state` — trùng khít. **35 check.**
2. **Chơi lại CẢ VÁN**: seed 991237, **391 hành động**, `RunVerifier` tính ra **điểm 500, won**,
   khớp với ván đã chơi, và toàn bộ end state trùng khít.
3. **Qua ranh giới tiến trình** (đúng cách server sẽ làm): `record_sample_run` ghi log ra file
   13KB; một tiến trình Godot **khác** đọc file đó và trả
   `{"ok":true,"score":500,"won":true}`.
4. **Chống gian lận thật sự chặn**: sửa seed trong header → `action_rejected` ở nước đi 1 · chèn
   thêm một lần nhận thưởng → `"Reward 0 was taken from an offer of 0"` · sửa dấu phiên bản →
   `rules_version_mismatch`. Trong test còn 3 phép tiêm nữa ở mức trận (bỏ / đổi mục tiêu /
   hoán vị) và 1 ở mức ván (đổi phần thưởng đã lấy).
5. **Cổng biết trượt**: tiêm lệch seed mỗi trận vào `CombatEngine` ⇒ `t_replay` đỏ, chỉ đúng
   nước đi số 0.
6. **Undo có test riêng** (`test_an_undone_move_replays_like_it_never_happened`) — trước đó
   không cái gì chạm vào đường undo; security-engineer phát hiện, không phải test tự phát hiện.
7. Suite **37/37**.

## Related Decisions

- Wayfinder ticket **A** — đóng bởi ADR này.
- Wayfinder ticket **H** (cổng cutover) — hết bị chặn; xem `production/cutover-gate.md`.
- ADR-0003 — Import Axie chỉ nhập bằng ID; vault làm run mất tư cách ranked, nên không đụng
  đường verify này.
