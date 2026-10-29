# Combat animation variety — evidence (UI-05 b1, nhánh ui5b1/anim)

Chụp bằng `godot/tools/shot.sh res://tests/qa_combat_anim_evidence.tscn 1920x1080` (không headless).
Mỗi cảnh có ảnh cả màn (`.jpg`) và ảnh cắt quanh con đang ra chiêu (`-crop.png`, phóng to).
Axie trong trận chỉ cao ~90 px trên khung 1080p nên ảnh cắt hơi mờ; dáng rõ hơn ở các contact sheet trong `sheets/`.

| # | Cảnh | Clip | Ghi chú |
|---|---|---|---|
| 01 | Damage, part Horn | AttackHead | húc đầu lao tới |
| 02 | Damage, part Back | AttackRange | xoay người, ném |
| 03 | Damage, part Tail | CutTree | vung ngang |
| 04 | Damage trong Set | AttackCombo | xoay + đấm liên tiếp |
| 05 | Damage của Set đã Overcast | HitTree | nhảy lên, đập xuống |
| 06 | Heal | LootItem | cúi xuống nhặt, đưa lên miệng |
| 07 | Buff | MalaSkill | giơ tay trước ngực, xoay |
| 08 | Mana | TalismanSkill | xoay + đẩy tay |
| 09 | Summon | Shoveling | đào đất |
| 10 | Quái thường (Chom) tấn công | Attack của model Atia | ảnh cắt bị lệch, xem ảnh cả màn |
| 11 | Axie trúng đòn nặng | IdleGetHit chậm (0.75x) | |
| 12 | Thắng trận | FlagAttack (cheer) rồi Run | |
| 13 | Boss Gooey King, face không phải damage | Cast | trước đây boss luôn dùng Attack |
| 14 | Boss tấn công | Attack | |
| 15 | Boss sang phase mới | Roar | ảnh gọi thẳng play_roar (tên cũ trong lần chụp: charge) |

`sheets/`:
- `candidates-Normal-raw-*.png`: contact sheet các clip ứng viên trên body Normal (mỗi hàng 1 clip, 5 khung từ đầu tới cuối clip). Thứ tự hàng: a = Stun, AttackHead, AttackRange, AttackCombo, CutTree; b = HitTree, LootItem, PourWater, Shoveling, StoneHarvest; c = MalaSkill, TomeSkill, TalismanSkill, FluteSkill, StaffSkill; d = LanternSkill, HammerSkill, FlagAttack, GauntletSkill, HammerRun.
- `baked-Sumo-retarget.png`, `baked-Bigyak-retarget.png`: AttackHead/AttackRange/AttackCombo/HitTree/LootItem đã bake cho Sumo/Bigyak (hai body này không có các clip đó, retarget từ Normal). Part vẫn bám đúng chỗ.
- `weapon-skills-Mala-Talisman-Tome-Lantern.png`, `rejected-FluteSkill-row3.png`: cận cảnh các clip vũ khí.

## Clip bị loại

| Clip | Lý do |
|---|---|
| PourWater | gần như đứng yên khi không có bình nước |
| FluteSkill, TomeSkill | tay giơ ngang giữ một món đồ vô hình |
| HammerSkill, GauntletSkill | nhảy/lộn ra khỏi khung hình, dễ đè lên HUD |
| LanternSkill | lăn tròn quay lưng về camera, khó đọc |
| Mọi `*Attack/*Idle/*Run/*Walk` của vũ khí còn lại (Axe, Bow, Brush, Cannon, Dagger, Spear, Sword, Whip, ...) | dáng cầm vũ khí; pack không có mesh vũ khí nên không gắn được |

## Test

- `tests/t_combat_anim_variety.tscn`: PASS (20149 check).
- Suite đầy đủ: 292/292 PASS (`suite.log`, chạy sau commit sửa review). Lần chạy trước đỏ `t_raid_screen` vì cheer lúc thắng làm cuộc chạy dài thêm 0.55 s; đã sửa cho cheer chạy trong nhịp ease-in đầu cuộc chạy, tổng thời gian giữ nguyên.
- Ảnh 12 (victory) chụp trước khi sửa: cheer lúc đó đứng yên rồi mới chạy, giờ vừa cheer vừa bắt đầu trượt chậm. Dáng FlagAttack giống nhau.
