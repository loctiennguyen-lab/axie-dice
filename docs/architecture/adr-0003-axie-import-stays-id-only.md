# ADR-0003: Import Axie giữ nguyên đường "nhập ID" — KHÔNG làm đường "dán gene"

## Status
Accepted (2026-09-19). Quyết định sau khi nghiên cứu projectrogue.fun và hỏi ý kiến
`technical-director`, `producer`, `security-engineer` — cả ba đều kết luận giống nhau.

## Date
2026-09-19

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2, GDScript (nhánh `godot-port`) |
| **Domain** | Vault / Import Axie — `godot/scripts/net/axie_api.gd`, `godot/scripts/core/axie_to_die.gd`, `godot/server/axie-proxy.js` |
| **Knowledge Risk** | LOW — không dùng API mới nào của 4.4→4.7; xem `docs/engine-reference/godot/VERSION.md` |
| **References Consulted** | projectrogue.fun (bản Godot web export của Jaastster, khảo sát 2026-09-19), `godot/tests/probe_part_map.gd` (số đo thật), `production/session-state/godot-port-active.md`, `docs/godot-port-gap-inventory.md` |
| **Post-Cutoff APIs Used** | Không |
| **Verification Required** | Đã xong — xem mục Validation Criteria |

## ADR Dependencies

- **ADR-0001** (Leaderboard Backend) — định nghĩa "Ranked Run": bật ranked thì Vault bị chặn khỏi
  team, và server replay lại toàn bộ run qua chính engine để chấm điểm. Quyết định này nằm trong
  ràng buộc đó.

## Context

Bản port Godot đã có Import Axie chạy đầu-cuối: người chơi gõ **ID Axie**, game lấy dữ liệu NFT
thật rồi dựng xúc xắc 6 mặt bằng `axie_to_die.gd` (bản port bit-exact của `axieToDie()` bên JS).

Khảo sát projectrogue.fun cho thấy game đó có **hai** đường nhập: ID **và** "dán gene code" (chuỗi
hex 512-bit) — đường thứ hai chạy được cả khi không có server nào. Câu hỏi: mình có nên làm theo?

Đo thật trước khi bàn (`probe_part_map.gd`, 16 Axie thật, 96 dòng part):

- `axie_to_die.gd` tra theo **TÊN part** ("Nut Cracker"); bộ giải gene chỉ cho
  `(slot, class, variant, skin)`.
- Ghép hai bên lại thì **0 xung đột khi khoá theo tên** ⇒ phép ánh xạ là một hàm thật sự, làm được.
- Nhưng bảng đầy đủ cần phủ **285** mục `class|slot|tên part` mà `part_faces.json` biết; 16 Axie
  mới phủ 66. Muốn đủ phải harvest hàng trăm đến hàng nghìn Axie.

## Decision

**Import Axie chỉ có một đường: nhập ID. Không làm đường dán gene, kể cả bản rút gọn.**

Lý do quyết định — không phải "khó quá", mà là **một bảng thiếu sẽ làm hỏng thứ đang chặn cutover**:

`axie_to_die.gd` đã có nhánh `fallback_face()` (dòng ~222) cho part có thật ngoài API nhưng chưa có
trong catalogue: nó trả mặt variant `A`, bucket `C`, giữ tên thật, và gom vào `unmapped_parts`. Với
một bảng harvest **chắc chắn thiếu**, cùng một con Axie nhập bằng ID sẽ ra mặt A, nhập bằng gene sẽ
rơi vào fallback — **hai bộ xúc xắc khác nhau cho cùng một con vật, không có lỗi nào bật lên**. Đó
đúng là kiểu sai lệch tất định mà hệ replay-verify (điều kiện để merge port vào `main`) phải chứng
minh là không tồn tại. Tức là: thêm bề mặt rủi ro cho đúng chỗ đang bế tắc, để nhân bản một tính
năng đã có.

Thêm hai lý do độc lập:

- **Bảng đó hỏng theo thời gian.** Catalogue part đã từng tăng 192 → 285; Sky Mavis thêm part lúc
  nào tuỳ họ. Bảng harvest là ảnh chụp, phải harvest lại mãi mãi.
- **Lý do tồn tại của đường gene bên họ là "không có backend".** Mình **có**: `curl` trên desktop,
  proxy trên web, cả hai đã kiểm chứng. Đường gene giải một bài toán mình đã giải rồi.

Kèm theo, **đã siết CORS của proxy** (`godot/server/axie-proxy.js`): bỏ
`Access-Control-Allow-Origin: *`, mặc định **không gửi header CORS nào** (đủ cho deploy same-origin
— cách projectrogue.fun làm), và chỉ echo lại origin nào có trong biến môi trường
`AXIE_PROXY_ALLOWED_ORIGIN` kèm `Vary: Origin`. Dữ liệu Axie là công khai nên `*` không làm lộ gì,
nhưng nó biến proxy thành **open relay**: site bất kỳ có thể nhúng `fetch()` để xài nhờ đường
vượt Cloudflare, ăn vào rate-limit và hoá đơn invocation của mình.

## Alternatives Considered

| Phương án | Vì sao không chọn |
|---|---|
| **Harvest bảng đầy đủ** (dán gene → xúc xắc chơi được) | Sai lệch tất định như trên; dữ liệu hỏng dần; chi phí lớn; và harvest hàng nghìn request tới gateway là vùng xám về rate-limit/ToS — `producer` đánh dấu đây là việc phải hỏi chủ dự án, không tự quyết. |
| **Dán gene → chỉ xem preview 3D, không tạo xúc xắc** | Gần như miễn phí (đã có `AxieGenePreview`), nhưng đặt cạnh ô nhập ID đang chạy đủ thì nó là một nút "làm được một nửa". Để lại sau cutover, chỉ làm nếu người chơi thật sự hỏi. |
| **Giữ CORS `*`** | Open relay, không có lợi ích bù lại. |

## Consequences

**Tích cực**
- Chỉ còn **một** đường sinh xúc xắc từ Axie ⇒ replay-verify sau này chỉ phải chứng minh một đường.
- Proxy an toàn hơn trước khi deploy lần đầu (chưa deploy ở đâu, nên đổi bây giờ không ảnh hưởng ai).
- Công sức dồn về đúng chỗ đang chặn: hệ anti-cheat + 11 màn còn thiếu.

**Tiêu cực / nợ đã biết**
- Không import được khi **hoàn toàn không có mạng** (bản web luôn cần proxy sống). Chấp nhận: bản
  desktop không cần server nào, và bản web vốn đã cần mạng để tải game.
- Nếu sau này thật sự làm đường gene: **bắt buộc** đi kèm gate chứng minh hai đường (ID và gene)
  cho ra **cùng một** xúc xắc, hoặc chặn hẳn khỏi ranked/leaderboard ở phía server —
  `security-engineer` nêu rõ chuỗi gene là input do người chơi tự chọn, không tương ứng NFT nào.

## GDD Requirements Addressed

- `design/gdd/godot-port-rule-spec.md` — luật Import Axie / Vault (giữ nguyên, không đổi luật chơi).

## Validation Criteria

Đã chạy, không phải dự định:

1. `godot/tools/run_tests.sh` → **35/35 pass** (trong đó `t_axie_api` **98 check**).
2. Gọi thật handler proxy qua mạng thật: `123` → 200 Plant · `11778888` → 200 Dusk ·
   `999999999` → **404** · `abc` → 400.
3. Kiểm CORS bằng cách gọi handler với nhiều `Origin`: không set biến môi trường thì **không**
   có header nào; set 2 origin thì đúng 2 origin đó được echo kèm `Vary: Origin`, origin lạ không.
4. `probe_part_map.gd` trên 16 Axie thật: 96 dòng, 66 khoá, **0 xung đột theo tên part** — số liệu
   làm nền cho quyết định này. Probe là công cụ opt-in, không nằm trong suite.

## Related Decisions

- Wayfinder frontier **C** ("kiến trúc Vault/Import Axie") — **đóng** bởi ADR này.
- Wayfinder frontier **A** (chiến lược anti-cheat/replay-verify cho GDScript) — vẫn mở, và là việc
  tiếp theo được cả ba chuyên gia xếp ưu tiên số 1.
