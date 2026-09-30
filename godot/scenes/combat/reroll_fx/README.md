# RerollFX — hiệu ứng reroll cho màn combat (Godot 4.4+)

Port từ bản thiết kế `Godot Combat Reroll FX v2.dc.html`. Chỉ lo phần trình diễn: kết quả roll
game logic đã chốt trước khi gọi `play()`, còn khay này chỉ diễn rồi dừng đúng vào mặt đó.

## Có gì

| Nhịp | Thời gian (1x) | Hiệu ứng |
|---|---|---|
| 1 Lấy đà | 0.26s | Card rung trái/phải, nhấc lên rồi nén xuống. Khay bật lên, nền trận tối lại |
| 2 Tung | ~0.8s | Khối 3D bay ra từ đúng card, mỗi viên cách nhau 35ms. Mỗi lần chạm felt thì tung bụi và kêu "thud", lần chạm đầu rung màn hình |
| 3 Tease | 0.55s | Mọi viên khác dừng hết, viên Axie cuối vẫn xoay. Spotlight bám theo nó, cả màn còn lại (kể cả các viên đã dừng) tối đi |
| 4 Chốt mặt | 0.3s/viên | Nảy mảnh theo màu loại mặt, vòng sáng, số trên bảng tally ở đầu khay chạy lên. Tiếng click cao dần theo từng viên. MAX: tag MAX! nghiêng, flash vàng, mảnh gấp đôi, arpeggio |
| 5 Đánh giá | 0.5–1.1s | Con dấu NICE / GREAT / PERFECT / JACKPOT đập xuống giữa khay, kèm "±n POWER VS LAST ROLL" |
| 6 Thu về | 0.52s | Khối bay cong về card. Card nảy, flash, hiện chip +2 / −1 / NEW / MAX |

Bấm vào khay (hoặc gọi `skip()`) để bỏ qua.

## File

```
reroll_fx/
  reroll_fx.gd         RerollFX (CanvasLayer): cả sequence, tray, tally, stamp, rung
  reroll_die.gd        RerollDie: khối lập phương thật (Quaternion), vẽ 2D chiếu trực giao
  fx_bits.gd           mảnh vỡ / bụi / vòng sáng (có viền đen, đúng art style)
  reroll_sfx.gd        âm thanh placeholder, tạo sẵn thành AudioStreamWAV lúc khởi động
  spotlight.gdshader   lớp tối có lỗ tròn cho nhịp tease
  demo/                scene test độc lập, bấm R để roll
```

Không cần SubViewport hay 3D node. Mặt die là một hình vuông được biến đổi affine, nên số và
icon vẫn đúng ở mọi góc xoay.

## Gắn vào combat

1. Copy cả thư mục vào `godot/scenes/combat/reroll_fx/`. Các path bên trong đều tương đối.
2. Trong combat scene:

```gdscript
var reroll_fx := RerollFX.new()

func _ready() -> void:
    reroll_fx.display_font = preload("res://assets/fonts/Baloo2-ExtraBold.ttf")   # font game đang dùng
    reroll_fx.type_icons = {
        "dmg": preload("res://assets/fx/dmg.png"), "shield": preload("res://assets/fx/shield.png"),
        "heal": preload("res://assets/fx/heal.png"), "mana": preload("res://assets/fx/mana.svg"),
        "poison": preload("res://assets/fx/poison.png"), "buff": preload("res://assets/fx/buff.svg"),
        "debuff": preload("res://assets/fx/debuff.svg"),
    }
    reroll_fx.reroll_icon = preload("res://assets/fx/reroll.svg")
    add_child(reroll_fx)
    reroll_fx.die_returned.connect(_on_die_returned)
    reroll_fx.finished.connect(_on_reroll_finished)
    reroll_fx.shake_requested.connect(_on_shake)   # nếu board có camera/rung riêng

func on_reroll_pressed() -> void:
    if reroll_fx.is_playing():
        reroll_fx.skip()
        return
    var prev := {}  # nhớ mặt cũ trước khi logic roll
    for u in party: prev[u.id] = u.rolled
    combat.reroll_all()                              # logic roll như hiện tại
    var entries := []
    for u in party_units_rolling():                  # bỏ qua die đã dùng / egg vừa nở
        entries.append({
            "id": u.id, "card": dice_cards[u.id],
            "faces": u.die.map(func(f): return {"type": f.type, "value": f.value}),
            "final": u.rolled, "prev": prev[u.id],
            "class_color": CLASS_COLORS[u.cls], "egg": u.is_egg,
        })
    reroll_fx.play(entries, {"rerolls_left": combat.rerolls})

func _on_die_returned(id, face_index, is_max) -> void:
    dice_cards[id].show_face(face_index)   # đổi mặt trên card ĐÚNG lúc khối về tới

func _on_reroll_finished(grade: Dictionary) -> void:
    pass  # mở lại input; grade.tier / grade.power_delta nếu muốn dùng thêm
```

Lưu ý:

- **Card đổi mặt ở `die_returned`**, không đổi ngay lúc logic roll. Nếu UI card đang bind thẳng
  vào `u.rolled` thì phải giữ mặt cũ cho tới signal này, không thì người chơi thấy kết quả trước.
- Hiệu ứng động vào `position.y / rotation / scale / modulate` của card rồi trả về giá trị gốc.
  Nếu card nằm trong `HBoxContainer` thì vẫn chạy, miễn là container không sort lại giữa chừng.
- Khóa input combat từ lúc `play()` tới `finished` (trừ nút REROLL / phím R, dùng để skip).
- Mặc định artboard 1920×1080, tự scale theo chiều cao viewport.

## Tùy chỉnh

| Thuộc tính | Mặc định | Ý nghĩa |
|---|---|---|
| `slowmo` | 1.0 | 2.5 = slow-mo như bản thiết kế, để review nhịp |
| `fast_mode` | false | Nối vào Settings → "Fast reroll": bỏ tease và con dấu |
| `screen_shake` | true | Tắt cho người chơi nhạy chuyển động |
| `sound` | true | |
| `shake_camera` | null | Camera2D sẽ rung cùng |

Bậc đánh giá tính giống bản thiết kế: trung bình của (giá trị / giá trị max của die) trên các die
Axie, mặt buff/debuff tính 0.6. Egg không tính. Tất cả đều MAX (≥3 die) → JACKPOT; ≥0.85 hoặc
≥3 MAX → PERFECT; ≥0.68 → GREAT; ≥0.52 → NICE; dưới đó không hiện dấu.

## Âm thanh

Toàn bộ là tiếng synth giữ chỗ. Thay bằng file thật:

```gdscript
reroll_fx._sfx.set_sample("toss", preload("res://audio/sfx/dice_rattle.wav"))
```

Tên: `open, toss, thud, lock_0..lock_12, max, spin, grade_0..grade_3, whoosh, pop_0..pop_10`.
Player tự đặt `playback_type = Stream`, khớp bản sửa trong AUDIO_SILENCE_INVESTIGATION.md, và
phát qua bus `SFX` nếu có (không thì `Master`).

## Đã kiểm tra

Chạy thật trên Godot 4.4.1 (headless và có render), với luck = random / lucky / jackpot:
cả 8 die (5 Axie + 3 egg) đều về đủ, `finished` phát đúng một lần, skip giữa lúc tung vẫn kết
thúc sạch trong khoảng 2s. Mặt dừng đúng với `final` và luôn đứng thẳng (lệch tối đa ±11°).
Chưa chạy trong project thật của game, nên phần gắn vào combat scene cần test lại trên máy.
