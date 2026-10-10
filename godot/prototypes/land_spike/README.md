# Land spike — Land 3D sống (Savannah)

**Trạng thái:** đã kết luận (10/10/2026). Code vứt đi, không được game tham chiếu.

## Giả thuyết

Dùng asset Homeland đã chuyển sang Godot (`asset-library/godot-ready/`) dựng được một Land 3D trông
đúng chất Homeland, có Axie (rig 3D của game) đi lại bằng Walk/Run/Idle, và chạy đủ nhanh trên
Windows + iOS.

## Chạy

```bash
# xem (chuột phải/giữa kéo để pan, lăn để zoom, +/- thêm bớt 5 Axie, bấm vào nhà)
Godot --path godot res://prototypes/land_spike/LandSpike.tscn
# đo: --axies=N --bench=giây --shot=ảnh.png, thêm --rendering-method mobile|forward_plus|gl_compatibility
Godot --path godot --rendering-method mobile res://prototypes/land_spike/LandSpike.tscn -- --axies=20 --bench=6
```

Asset nằm ở `homeland/`, chép bằng
`python3 godot/tools/import_homeland.py --dest prototypes/land_spike/homeland --list prototypes/land_spike/spike_assets.txt`
(24 scene → 142 file, 20,8 MB). `measure.gd` in kích thước thật từng asset.

## Kết quả

**Nhìn:** ổn. Plot Savannah, 4 công trình (Portal = vào run, Alchemy = Echo Box, SpyQuarter = hợp
đồng, House = nhà), cây/bụi/đá, Axie đủ class/dáng/màu đi lại có bóng. Ảnh: xem báo cáo trong phiên.

**Hiệu năng** — Apple M3 Pro, 1600×900, vsync tắt, trung bình 6 giây:

| Axie | Forward+ | Mobile (Metal) | Compatibility (GL) |
|---|---|---|---|
| 0 | — | 552 FPS (1,8 ms) | — |
| 8 | 334 | 403 | 34 |
| 20 | 180 | 201 | 15 |
| 50 | 73 | 76 | 7,5 |
| 100 | 38 | 39 | 7,5 |

- Chi phí gần như tuyến tính theo số Axie: ~0,22 ms và ~20k tam giác mỗi con.
- Tắt animation, bóng đổ hay outline của Axie đều KHÔNG đổi con số (50 Axie: 12,9–13,2 ms) → chưa
  rõ nút thắt; cần profiler thật (Godot profiler / Xcode Instruments trên máy).
- **Compatibility chậm gấp ~10 lần** — mà project đang đặt `rendering_method.mobile="gl_compatibility"`.
  Lên iOS phải dùng renderer Mobile (Metal).
- VRAM 480–700 MB: cao cho iOS. Project chưa bật `textures/vram_compression/import_etc2_astc`
  (godot-ready có bật).

## Kết luận cho bản thật

1. Hướng Land 3D với asset có sẵn: **khả thi**, nhìn đạt.
2. Số Axie trên Land phải có ngân sách. Gợi ý ban đầu: ≤ 10–15 Axie hiển thị trên iOS cho tới khi đo
   trên máy thật.
3. iOS: renderer Mobile, bật nén ETC2/ASTC, đo trên iPhone thật trước khi chốt ngân sách.
4. Mặt đất plot module mang texture ô lưới mẫu và được import ở thang 300 đơn vị (props ~1) — cần
   làm ground riêng cho Land thật.
5. Material Unity → Godot: đúng màu với mọi thứ đã dùng; warning "FBX image couldn't be loaded" là
   đường dẫn texture nhúng trên máy họa sĩ, bỏ qua được (có sẵn trong log gốc của godot-ready).
