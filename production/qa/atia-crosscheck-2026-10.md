# AT bước 1: đối chiếu model Atia (26/10/2026)

Chỉ đối chiếu, chưa import, chưa sửa data/code. Worktree `beta/at`, từ godot-port 6cdc3a5.

## Cách làm

- Kho: `asset-library/godot-ready/src/Atia_Asset/DeliveryAssets/` (Character/Monster, VillageAnimal, Mascot).
- Mỗi `godot/assets/atia/<key>/tex.png` (đã thu về 512) so với mọi texture trong kho (thu về 128x128, sai số pixel trung bình).
  Khớp thật cho ra sai số 0.0-1.0; không khớp thì >= 30. Hai con RGBA (pyrewing, stalker) so riêng trên vùng alpha, ra 0.5 và 1.0.
  Mở ảnh xem bằng mắt cho stalker/Oranda, pyrewing/Cloud, Owl/BigOwl: đúng.
- Không dùng md5 được vì tex.png đã bị resize.
- Cảnh báo: tên clip KHÔNG phải dấu vân tay chắc chắn như brainstorm viết. Wrapper đổi tên clip: `hexeye` là Snail (nguồn chỉ có Skill1) nhưng có `Attack.res`;
  `bruiser` là Tanuki (nguồn Skill1) cũng có `Attack`. Chỉ tin texture.

## 1. 21 model hiện có -> họ nguồn

| Key | Họ nguồn (thư mục kho) | Sai số | Chắc? |
|---|---|---|---|
| slime | Slimes_01 | 0.0 | chắc |
| warden | Slimes_02 | 0.0 | chắc |
| bugling | Slimes_03 | 0.0 | chắc |
| chomper | 110001_Slime | 0.2 | chắc |
| bruiser | 110004_Tanuki | 0.4 | chắc |
| hexeye | 110005_Snail | 0.2 | chắc |
| venomaw | 110006_Elephant | 0.2 | chắc |
| ravenling | 110007_Phoenix | 0.2 | chắc |
| jellyfin | 110008_Jellyfish | 0.4 | chắc |
| e_plague | 110009_Giant Mushroom | 0.3 | chắc |
| e_ravager | 110010_BigOwl (Elite) | 0.5 | chắc |
| pyrewing | 500340001_Cloud | 0.5 (alpha) | chắc |
| e_bulwark | 500340009_Pangocub | 0.3 | chắc |
| e_archon | 500340007_SeaHorseMinion4 (Nightmare) | 0.2 | chắc |
| spikelet | Strawberry | 0.2 | chắc |
| broodmaw | Onion | 0.2 | chắc |
| totem | Shitake | 0.3 | chắc |
| stalker | Oranda | 1.0 (alpha) | chắc |
| bomblet | VillageAnimal/Mouse | 0.6 | chắc |
| cleaver | VillageAnimal/Boar | 0.0 | chắc |
| thornback | VillageAnimal/Dryad (Fighter) | 0.7 | chắc |

Họ đã dùng: Slimes(01-03), 110001 Slime, Tanuki, Snail, Elephant, Phoenix, Jellyfish, Giant Mushroom, BigOwl, Cloud, Pangocub, SeaHorseMinion, Strawberry, Onion, Shitake, Oranda, Mouse, Boar, Dryad.
Brainstorm đoán sai nhiều con: venomaw (Elephant, không phải "hoa"), hexeye (Snail), totem (Shitake), pyrewing (Cloud), stalker (Oranda), jellyfin (Jellyfish), e_archon (SeaHorseMinion4, đúng hướng).

## 2. 12 ứng viên

Clip lấy từ tên file FBX trong kho (chưa mở nhị phân). Kích thước = ước: rig FBX trong kho + 3-4 file anim .res (20-70 KB/file theo các model hiện có) + tex 512 (~0.2-0.3 MB).

| Ứng viên | Họ | Trùng với | Clip thật | Rig FBX | Ước/model | Kết luận |
|---|---|---|---|---|---|---|
| gmush | 110009 Giant Mushroom | **e_plague** | Idle, Skill1, Skill2, Dead, Stun | 1.66 MB | ~2 MB | TRÙNG, thay |
| shitake | Shitake | **totem** | Idle, Attack_1, GetHit, Dead | - | - | TRÙNG, thay |
| snail | 110005 Snail | **hexeye** | Idle, Skill1, Dead | 1.25 MB | - | TRÙNG, thay |
| tanuki | 110004 Tanuki | **bruiser** | Idle, Skill1, Dead | 0.50 MB | - | TRÙNG, thay |
| anemone | Anemone | không (không có model nào khớp) | **Idle, Attack, GetHit, Dead** (+Run) | 0.28 MB | ~0.7 MB | GIỮ, đủ 4 clip |
| cloud | Cloud | **pyrewing** | Idle, Skill1-4, GetHit, Dead, Stun | 0.39 MB | - | TRÙNG, thay |
| oranda | Oranda | **stalker** | Idle, Attack_1, GetHit, Dead | - | - | TRÙNG, thay |
| elephant | 110006 Elephant | **venomaw** | Idle, Skill1, Skill2, Dead, Stun | 0.93 MB | - | TRÙNG, thay |
| owl | 110003 Owl | **e_ravager** (cùng mesh/anim `A_Monster_5001006_*` với BigOwl, chỉ khác texture xanh) | Idle, Skill1, Dead, Stun | 0.71 MB | - | TRÙNG họ, thay |
| e_bigowl | 110010 BigOwl | **e_ravager** (chính nó) | Idle, Skill1, Dead, Stun | 0.77 MB | - | TRÙNG, thay |
| e_golem | 500340003 AncientGolem | không | Idle, Skill1/1b/2/3/4, Dead, Stun (không GetHit, không Attack) | 0.87 MB | ~1.3 MB | GIỮ (Elite chỉ cần idle; attack = Skill1) |
| e_phoenix | 110007 Phoenix | **ravenling** | Idle, Skill1, Skill2, Dead, Stun | 0.40 MB | - | TRÙNG, thay |

Kết quả: chỉ 2/12 sạch (anemone, e_golem). 10/12 trùng quái đã có. Cả 3 con min 1 (gmush, shitake, snail) đều trùng; nhóm 1100xx trùng hết (Tanuki, Snail, Elephant, Phoenix, Mushroom, BigOwl, và Owl cùng họ BigOwl).
Nghĩa là bảng pool trong brainstorm không đứng được như viết.

## 3. Kho còn gì sạch để thay

Chưa dùng, khác họ mọi model hiện có:

| Họ | Clip | Rig | Ước | Ghi chú |
|---|---|---|---|---|
| Anemone | Idle, Attack, GetHit, Dead | 0.28 MB | 0.7 MB | duy nhất đủ 4 clip |
| AncientGolem | Idle, Skill1-4, Dead, Stun | 0.87 MB | 1.3 MB | Elite |
| SeaHorse (01/Nightmare) | Idle, Skill1-5, Dead, Stun | 0.35 MB | 0.7 MB | Elite; không có boss nào dùng (boss là Chimera + Axie), nhưng brainstorm đã để dành cho boss 7 |
| 110002 Shiitake | Idle, Skill1, Dead, Stun | 0.42 MB | 0.8 MB | khác texture Shitake (be nâu vs cam), cùng loài nấm: cần Liam/art xem có quá giống totem không |
| Pangolord | Idle, GetHit, Dead, nhiều skill (không Attack thường) | 0.19 MB | 0.6 MB | gần họ e_bulwark (Pangocub là con của nó): rủi ro "trông cùng loài" |
| Slimes_04 | Attack, GetHit, Idle (không Dead) | 0.15 MB | 0.5 MB | cùng họ Slimes (đã dùng 01-03), mesh khác; thiếu Dead |
| VillageAnimal: Fox, Rabbit, Hedgehog, Horse, Bear, Owl(Village) | chỉ Idle/Run/Walk/Eat (không Attack/GetHit/Dead) | 0.11-0.25 MB | 0.4-0.6 MB | cùng kiểu bomblet/cleaver/thornback hiện có (Idle-only, đã có tiền lệ). Không phải "quái", cần art-director duyệt |

Loại: MiniBoss Ver1-3 (không có Dead, cùng họ e_archon), Cloud/Golem bản Nightmare (cùng họ), Mascot (nhân vật Axie, dùng cho boss/hub), Dryad_Elder và Mage (texture 10 MB, không có anim).

## 4. Đề xuất thay (giữ vai trò/cost/min của mẫu)

| Slot | cost/min | Thay bằng | Clip | Mức tin |
|---|---|---|---|---|
| gmush | 4 / 1 | Bear (VillageAnimal) | Idle | yếu (Idle-only) |
| shitake | 3 / 1 | 110002 Shiitake | Idle, Skill1, Dead | vừa (thiếu hit, gần totem) |
| snail | 3 / 1 | Hedgehog | Idle | yếu (Idle-only) |
| tanuki | 5 / 3 | Fox | Idle | yếu (Idle-only) |
| anemone | 5 / 3 | giữ | đủ 4 | tốt |
| cloud | 6 / 6 | Slimes_04 | Attack, GetHit, Idle | vừa (họ Slimes, thiếu Dead) |
| oranda | 7 / 7 | Pangolord | Idle, GetHit, Dead | vừa (gần e_bulwark) |
| elephant | 7 / 7 | Horse | Idle | yếu |
| owl | 8 / 8 | Rabbit hoặc Owl(Village) | Idle | yếu |
| e_bigowl | Elite | SeaHorse | Idle, Skill1, Dead | tốt |
| e_golem | Elite | giữ | Idle, Skill1, Dead | tốt |
| e_phoenix | Elite | **bỏ** (không còn con sạch) | - | Elite pool 4+2 = 6, không phải 7 |

Chú ý: vai trò ghi theo mẫu (khối chỉ số), hình chỉ thế chỗ; vài cặp hình-vai trò lệch (Horse = bruiser nặng thì ổn, Rabbit = mage burn thì lạ). Art-director/Liam chọn lại tên-hình nếu cần.

## 5. Ngưỡng pool theo số con thật sự có

Công thức: số loại bốc = ceil(0.7 x n). a = số con mới min 1, b = số con mới min 3 (thêm vào), N = tổng quái thường mới. pw0: n=3+a; pw1: n=4+a; pw2: n=6+a+b; pw>=10: n=17+N.

| Phương án | a | a+b | N | pw0 | pw1 | pw2 | pw>=10 |
|---|---|---|---|---|---|---|---|
| Hiện tại | 0 | 0 | 0 | 3 | 3 | 5 | 12 |
| Brainstorm (9 thường) | 3 | 5 | 9 | 5 | 5 | 8 | 19 |
| P1: 9 thường như mục 4 (6 con Idle-only/yếu) | 3 | 5 | 9 | 5 | 5 | 8 | 19 |
| P2: 6 thường tốt/vừa (anemone, Shiitake, Slimes_04, Pangolord + Hedgehog + Fox) | 3 | 4-5 | 6 | 5 | 5 | 7-8 | 17 |
| P3: chỉ con có >= 3 clip (anemone, Shiitake, Slimes_04, Pangolord) | 1-2 | 2-3 | 4 | 4 | 4-5 | 6 | 15 |

Giữ 5/5/8/19 chỉ làm được với P1, tức là phải dùng 5-6 con VillageAnimal Idle-only (hiện chỉ có 3 con Idle-only ở normal). Hai tuỳ chọn khác: P2 (pw2 = 7-8, pw>=10 = 17) hoặc hạ ngưỡng `t_pool_diversity`. Con số pw0/pw1 = 5 cần 3 con min 1 (hoặc pw1 chỉ cần 2).

## 6. Rủi ro còn lại / cần Liam quyết

1. Dùng VillageAnimal (Fox, Rabbit, Hedgehog, Horse, Bear, Owl) làm quái: có thể không hợp "quái" về art, và không có Attack/GetHit/Dead (chết = biến mất?). Cần art-director xem + kiểm cách registry xử lý thiếu `die`. Tiền lệ: bomblet/cleaver/thornback.
2. Shiitake 110002 và Pangolord, Slimes_04: "khác họ" về texture/mesh nhưng cùng loài với con có sẵn; mắt người chơi có thể coi là trùng.
3. Chưa mở FBX nhị phân, chưa chụp render: kích thước và clip là theo tên file. `facing_deg`, `height_m` chưa kiểm.
4. Còn thể loại ngoài kho Atia (asset ngoài) thì không có trong phạm vi này. Nếu muốn đủ 12 con đủ 4 clip thì kho Atia không đủ.
5. Bảng pool, `t_pool_diversity` và số "26 key / 17-4-6" trong brainstorm phải viết lại theo phương án chọn trước khi bước 2.
