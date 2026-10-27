# Verifier: đo thời gian replay (26/10/2026)

Máy: Apple M3 Pro, macOS 27.0.1, Godot 4.7.2 editor binary (headless, không phải export template). Lệnh:
`Godot --headless --path godot res://tools/verify_run.tscn -- --in=<log> --out=<kq>`; log từ `record_sample_run` (RunBot, ranked).

| Log | Mode | Action | Node | Replay (ms, trường `ms`) | Wall cả tiến trình |
|---|---|---|---|---|---|
| seed 5 | short | 118 | 5 | 30 | ~1,3 s |
| seed 991237 | short | 328 | 18 | 93-108 | ~1,3-1,4 s |
| seed 42 | full | 294 | 15 | 84 | ~1,3 s |
| seed 991237 | full | 59 | 5 | 17-20 | ~1,3 s |

- Cold start Godot (nạp autoload, ContentDB) ~1,2 s; replay chỉ ~0,3 ms/action (~0,1 s cho 328 action). Ba lần mỗi dòng, ổn định.
- Qua `with_lock.sh` wall ~5,2 s: phần thêm là chụp/trả save của khoá, không phải của verifier. Container thật không có bước đó.
- Giới hạn của số liệu: bot chết sớm (Short <= 18 node, Full <= 15 node, chưa có run thắng), nên chưa có log "Full thắng đủ 40+ node". Ngoại suy tuyến tính: run thắng Full ~1000-1500 action = ~0,5 s replay. Cần đo lại bằng run thật khi có.
- Linux x86_64 / Container cold start: CHƯA đo (cần Container hoặc máy V2). Kỳ vọng cùng bậc 1-3 s, bộ nhớ chưa đo.
