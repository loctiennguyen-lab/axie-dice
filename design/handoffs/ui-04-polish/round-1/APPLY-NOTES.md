# UI-04 round 1: ghi chú áp vào game (28/10)

Nhánh tích hợp: `int/ui4` (worktree `../my-game-wt/ui4`).

## Đã gộp
| Làn | Nhánh / commit | Màn |
|---|---|---|
| Nền | ui4/base 42c8a55 | Token UI-04, component chung (UI3), bảng chuyển động 41 id, `t_ui4_components` |
| Trận: plate + HUD | ui4/combat f83af92, 4373fca | Plate quái/boss, khung HUD, thẻ Attrition, khối hành động |
| Trận: khay xúc xắc + Aid | ui4/combat-dock e72657b | DiceDock 848, FRONT/BACK, nhãn chờ server, vùng Aid |
| Trận: màn thua + hiệu ứng | ui4/combat-fx b2eac31 | Màn thua C4, hiệu ứng đánh/crit/big hit/KO/giáp/phase/thắng/lộ ý định |
| Bản đồ run | ui4/run d5561d4 | Bảng Lõi, chip Anchor, chip luật run, chấm bậc |
| Land | ui4/land c6ffaab | Chip Land, chip tiền, toast, nút có phím, dải nâng tier |
| Run setup | ui4/run-setup 008c831 | Bảng trái 456, dòng chế độ có lý do khoá, A7+ khoá, thẻ đội hình |
| Nhiệm vụ | ui4/meta 92f4ffd | Thang rủi ro, bảng chi tiết, "How it works" |
| Result | ui4/result 12ca306 | Khung 880 không cuộn, Shard nổi bật, Pass gọn, Lõi một dòng |
| Pass + mạng + Update | ui4/pass-system fb60ba1 | Pass lật trang 8 cấp, NetNotice v4, thanh Update mép trên |
| Echo Box | ui4/echobox 8c8ca8a | Sân khấu rương, chip vé, đồng hồ Fragments, pity theo độ hiếm, hộp mở 720 |
| Sửa chung | 3d8846d, 8a08792 | Bóng thẻ LEADER theo token; `button_with_cost` hết nền xám |

## Còn chạy
- Chọn Core (47) + hiệu ứng run: ui4/core-offer.
- Chọn Anchor (48) + Anchor thức tỉnh (49): ui4/anchor.

## Việc gom một lượt cuối (sau khi gộp đủ)
- Đưa vào `UI3`:
  - Từ Land: chip tiền tệ, nút có phím, toast có glyph, chip Land.
  - Pill, meter.
  - Từ Echo Box: chip DUPLICATE.
- Echo Box: thay `_cost_in_button` / `_primary_cost` cục bộ bằng `UI3.button_with_cost` (đã sửa lỗi nền xám).
- `UI3.category_chip` thiếu lề hai bên.
- `UI3Motion._burst`: thêm cỡ hạt particle. Result đang tự thu hạt Shard 512 px xuống 32.
- Thanh Update phủ 56 px trên cùng nhưng chưa đẩy màn xuống: cần sửa ở khung chung.
- `UI3Meta` để trống ô banner vẫn tốn 24 px.
- Dòng Pass ở Result vẫn dùng `PassSummary.line()` cũ. Muốn dùng chữ gộp thì phải sửa cả `t_result_pass_agree`.
- Âm thanh: tên sfx trong `motion_ui3.json` chưa gắn file nào.

## Lệch so với thiết kế (biết rõ)
- **Trận:**
  - Ô xúc xắc vẫn 96, thiết kế là 88. Thẻ xúc xắc cao 184, thiết kế khoảng 194, giảm để không đè vùng 3D.
  - Chưa có dải chữ "Phase 2" của boss, dải chữ "Victory" + quay chậm, nét gạch tên Axie khi KO.
  - Nút Continue bấm được ngay, chưa có khoá 1 giây.
- **Bản đồ:** game có 6 ô Lõi, thiết kế vẽ 7. Ô Anchor trong dải Lõi vẫn kiểu cũ.
- **Land:**
  - Không giãn được khoảng cách chữ "LAND TIER UP".
  - Daily giữ chữ một dòng.
  - Chưa có hiệu ứng số tiền đếm lên và bay vào chip.
- **Run setup:**
  - Ô trống trong đội hình đang viền liền, thiết kế là nét đứt.
  - Biểu tượng khoá nhỏ, mờ.
  - Chưa giãn chữ các nhãn viết hoa.
- **Echo Box:**
  - Ảnh món mới có thể trống ở frame đầu.
  - Chưa có hạt Fragment bay vào đồng hồ, chưa có tia sáng cho món Rare+.
  - Sau khi mở 1 hộp vẫn hiện bản tóm tắt cũ (test cũ cần).
- **Pass:** chưa có phím ←/→ để lật trang. Đã hỏi Liam.
- **Nhiệm vụ:**
  - Ô báo thua chưa có viền đỏ.
  - Thanh số dư trên đầu màn vẫn hiện.
  - Khoảng cách giữa bảng và khung chi tiết là 24, thiết kế là 0.
