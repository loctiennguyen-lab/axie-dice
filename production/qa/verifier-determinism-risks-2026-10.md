# Rủi ro tất định chéo nền tảng của verifier (arm64 mac / x86_64 linux / wasm)

Quét bằng grep ở `autoload/`, `scripts/core/`, `scripts/meta/` (26/10/2026). Chưa chạy trên Linux/wasm, đây là danh sách cần kiểm.

| # | Chỗ | Vì sao có thể lệch | Mức |
|---|---|---|---|
| 1 | `rng.gd` mulberry32: số nguyên 64-bit GDScript, `& 0xFFFFFFFF`, rồi `float(x)/4294967296.0` | Số nguyên: giống hệt mọi nền tảng. Chia double IEEE-754: cũng giống (chia chính xác). Rủi ro thấp | Thấp |
| 2 | `next_int`: `int(floor(next_float() * n))` | Nhân double rồi floor, IEEE chuẩn, không FMA nếu GDScript không fuse. Godot tính từng phép trong interpreter nên không fuse. Thấp, nhưng wasm/x86 cần chứng minh bằng test | Thấp |
| 3 | `roundi`/`round`/`ceil`/`floor` trên `x * 100.0`, `v * 1.5`, `v * mult` (combat_engine ~25 chỗ, axie_to_die, core_offer) | Kết quả lệch nếu tích double rơi đúng nửa (x.5). Cùng IEEE nên giống nhau, nhưng đây là nơi lệch đầu tiên nếu một nền tảng dùng độ chính xác khác. Hiện giá trị đa phần là bội số của 0,05/0,25 (biểu diễn gần đúng, nhưng giống nhau mọi nơi) | Trung bình |
| 4 | `Array.hash()` trong `relic_hooks.gd:2176` (cache chữ ký) | Hash của Godot có thể khác giữa phiên bản/nền tảng; chỉ dùng làm khoá cache nên không đổi kết quả. Cần giữ vậy: KHÔNG dùng `hash()` cho thứ ảnh hưởng luật | Thấp (chỉ cache) |
| 5 | `String.hash()` ở `mission_board.gd:55` chọn nhánh A/B | Là meta/nhiệm vụ, không vào replay. Nhưng `hash()` không đảm bảo giống nhau giữa nền tảng: nếu server và client cùng dùng thì có thể thấy A/B khác nhau | Trung bình (ngoài verifier) |
| 6 | `RandomNumberGenerator`/`randf` trong `echo_box.gd` | Không vào replay (server tung). Nếu server tung bằng GDScript thì seed phải qua mulberry32 | Ngoài phạm vi |
| 7 | `randi()` ở RunState.gd:419 (seed offline) | Chỉ khi không có tape; verifier luôn dùng tape | Thấp |
| 8 | Thứ tự duyệt Dictionary / `keys()` | Godot giữ thứ tự chèn, giống nhau mọi nền tảng. Rủi ro nếu có `sort_custom` không ổn định (sort không stable của Godot với hoà) | Trung bình, cần grep `sort_custom` trong luật |
| 9 | `JSON.stringify` float (state digest) | Dạng in số float có thể khác; test dùng sha của chuỗi nên lệch ở đây là dương tính giả có thể xảy ra, nhưng nên biết | Thấp |
| 10 | Thư viện `ContentDB` nạp JSON: thứ tự file `DirAccess` | Thứ tự liệt kê file khác nhau theo hệ file; nếu có chỗ phụ thuộc thì lệch | Trung bình, cần kiểm |

## Test
- `godot/tests/t_verify_cross_platform.tscn`: chơi 5 run bot (Short + Full), replay, so (score, won, nodes, sha256 state) với `tests/fixtures/verify_golden.json` sinh trên arm64 macOS (đã commit). In `XPLAT_DIGEST <OS> <sha>` để so giữa máy.
- Chạy cùng test trên Linux x86_64 (trong image verifier, thêm `-- ` không cần) và trên bản web (wasm): digest phải trùng dòng macOS. Digest macOS hiện tại: `9c50817e...b55e4e` (rules `-t`). Đổi luật thì sinh lại golden bằng `-- --write-golden`.
- Phần chạy được local: mac vs chính nó (đã xanh). Phần 2 nền tảng còn lại cần Liam/lane I.
