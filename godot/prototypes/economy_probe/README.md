# Economy probe — Gene Shard mỗi run (R)

**Trạng thái:** đã kết luận (10/10/2026). Code vứt đi.

## Giả thuyết
Bảng economy cũ dùng ~150 Shard/run (số của bản JS). Ở bản Godot, R thật là bao nhiêu?

## Chạy
Ghi vào save thật (qua `RunState.end_run()`): sao lưu
`~/Library/Application Support/Godot/app_userdata/Axie Dice (Godot port)/` trước, chép lại sau.

```bash
Godot --headless --path godot res://prototypes/economy_probe/probe_shards.tscn -- --mode=short --seeds=40 --shop=none
```
(zsh: nếu truyền tham số qua biến, dùng `${=cfg}`.)

## Kết quả (bot của `tools/run_bot.gd`: chơi dở, đi nhánh đầu, Ascension 0, đội plant1/beast1/aqua1/reptile1/bug1)

| Cấu hình | Run | Thắng | Shard trung bình (net) | Thắng / Thua | Full clear (theo đường đi) | XP thắng / thua |
|---|---|---|---|---|---|---|
| short, không mua shop | 40 | 10 | 336 | 569 / 258 | 568 | 506 / 190 |
| short, mua hết shop | 40 | 4 | 260 (tiêu 62) | 388 / 246 | 565 | 500 / 221 |
| full, không mua shop | 20 | 0 | 344 | — / 344 | 854 | — / 292 |

Đường đi nhánh đầu, short: ~9,4 battle, 1,4 elite, 3 boss, 2,2 event, 1,2 treasure, 0,8 shop.
Full: ~16 battle, 2 elite, 4 boss.

## Kết luận
- **R ≈ 350–570 Shard/run** cho short (thắng trọn ~568), full trọn ~854. Gấp 2,5–4 lần số 150 cũ.
- Gần như toàn bộ Shard đến từ combat (25/45/90); event lựa chọn đầu cho 0.
- Bot rất dở (25% thắng) → người thật sẽ gần mức trần hơn. Dùng R = 450 làm số giữa cho bảng
  economy cho tới khi có dữ liệu người chơi thật.
