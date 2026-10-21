# Âm thanh các khoảnh khắc xúc xắc v4

Người viết: sound-designer. Duyệt: audio-director, rồi Liam. Nguồn luật: `design/gdd/dice-depth-v4.md` mục 3.0 (luật một câu) và 9 (giao diện). Đây là bản spec để duyệt, chưa có code, chưa có file âm thanh mới.

Mục tiêu của Liam: "gacha vui, phấn khích khi ra combo". Cách làm: mỗi lần tung có một nhịp nhỏ dễ chịu, BỘ là phần thưởng tăng dần rất rõ (ba, bốn, năm), còn rủi ro (Liều, Nứt) thì căng chứ không cay.

## 0. Hiện trạng (đã kiểm)

- `godot/assets/audio/` chỉ có `music/` (5 bài: home, pve_1..3, boss) và `sfx/class/` (13 âm x 7 class: attack, fly, hit của Axie) và `sfx/status/` (35 âm trạng thái: buff, heal, shield, power_gain, power_awaken, cleanse, stunned, secret, ...). Không có âm xúc xắc, UI, hay phần thưởng nào. `manifest.json` chỉ liệt kê class và status.
- Chỗ phát duy nhất: `godot/scenes/combat/CombatAudioDirector.gd`. Nó nghe `EventBus` (`face_used`, `hit_landed`, `unit_died`, `boss_phase_changed`, `status_tick`), dùng bus `Music` và `SFX`, 8 voice quay vòng (voice đầy thì cắt cái cũ nhất), không ducking, không random pitch. Map tên -> file nằm ở `godot/scripts/data_models/combat_audio.gd` (`status_sfx_path`: crit = `power_gain`, death = `death_mark`, undying = `power_awaken`).
- Cài đặt có sẵn trong `MetaState`: `audio_music_volume`, `audio_sfx_volume`, `audio_muted`, `reduce_flash`.
- Hệ quả: nhóm event dưới đây là phần MỚI, chưa có chỗ nào phát. Cần một người lập trình quyết định chỗ phát (mở rộng CombatAudioDirector hay một autoload riêng). Mình không viết code, chỉ nêu yêu cầu ở mục 5.

Quy ước độ to: tương đối so với một cú đánh dmg thường = 0 dB (mốc "tiếng đánh"). Số âm là nhỏ hơn.

## 1 và 2. Danh sách event

Ký hiệu asset: [CÓ] dùng được ngay không cần làm gì thêm, [TẠM] dùng file có sẵn làm placeholder để nghe thử, nhưng vẫn nên thay, [MỚI] phải tìm/tạo. Tất cả file mới đặt ở `godot/assets/audio/sfx/dice/` (đề xuất), ogg, mono, 44.1 kHz, thêm vào `manifest.json`.

Mình chưa nghe từng file có sẵn (không chạy được audio ở đây). Cột "dùng lại" dựa vào tên file và cách game đang dùng; audio-director cần nghe thử trước khi chốt [TẠM].

### 2.1 Tung thường và BỘ (tăng cấp)

| Event | Khi nào phát | Ưu tiên / ducking | Dài | To | Asset | Pitch |
|---|---|---|---|---|---|---|
| `dm_roll` | Bấm tung / tung lại, lúc xúc xắc bắt đầu lăn | Thấp. Không duck gì. Tối đa 1 cái, tung lại thì thay cái cũ | 0.5 s | -6 dB | [MỚI] tiếng 3-5 viên xúc xắc gỗ/gốm nhỏ lăn rồi lách cách trên khay. Tai nghe "ấm", không kim loại. Số viên ít thì lớp lách cách ít | 4 biến thể, ngẫu nhiên +-0.5 semitone, không lặp liền nhau |
| `dm_land` | Mỗi viên dừng hẳn (lúc số hiện ra). Lệch nhau 40 ms theo thứ tự viên | Thấp. Tối đa 6 cái trong 400 ms, quá thì bỏ cái thừa | 0.08 s | -12 dB | [MỚI] một tiếng "tok" gỗ khô rất ngắn | 3 biến thể, +-1 semitone, mỗi viên trong cùng lần tung hơi cao hơn viên trước 0.3 semitone (nghe như bậc thang nhỏ) |
| `dm_pair` | Lần đầu có ĐÔI (2 viên cùng part) trong một lần tung. Không phát cho đôi thứ hai | Thấp | 0.25 s | -9 dB | [MỚI] một nốt "pling" mềm (marimba hoặc kalimba, G5), một nốt, không gây hứng quá | +-0.3 semitone |
| `dm_set3` BỘ BA x1.4 | Banner "BA ... x1.4" hiện (nút khoá Bộ tính lại) | Cao. Tắt `dm_pair` và `dm_land` đang chạy. Duck Music -3 dB trong 0.6 s | 0.7 s | -2 dB | [TẠM] `sfx/status/power_gain.ogg` (cũng đang là tiếng crit, nên dễ bị lẫn, thay sớm) hoặc `buff.ogg`. [MỚI] đích: hai nốt đi lên C5-E5, kalimba + chuông nhỏ, đuôi ngắn sáng | +-0.2 semitone. Nếu 3 phần cùng part khác nhau thì không đổi nốt, tông giữ cố định để người chơi học "ba = hai nốt" |
| `dm_set4` BỘ BỐN x1.8 | Banner BỐN hiện | Cao hơn set3. Cắt set3 nếu đang chạy. Duck Music -4 dB 0.8 s | 1.0 s | -1 dB | [MỚI] ba nốt arpeggio C5-E5-G5 + một lớp lấp lánh (sparkle) ngắn. Thêm một nốt trầm ấm (G3) bên dưới cho "nặng" hơn | +-0.2 semitone |
| `dm_set5` BỘ NĂM x2.6 (jackpot) | Banner NĂM hiện | Cao nhất trong hệ thống. Cắt mọi `dm_*` khác. Duck Music -6 dB 1.5 s, SFX combat -3 dB 1.0 s | 2.0 s | 0 dB (to nhất, nhưng không vượt tiếng boss death) | [MỚI] arpeggio C5-E5-G5-C6, hợp âm chuông đầy (C-E-G-C), rồi mưa đồng xu/đá quý nhỏ 0.8 s (kiểu gacha), có một "whoosh" lên ở đầu. Phải khác hẳn set4 ngay từ 0.2 giây đầu | Không random pitch ở hợp âm (để giữ cảm giác "đúng"). Chỉ random lớp mưa đá quý +-1 semitone, 3 biến thể |
| `dm_set_up` (ba lên bốn, bốn lên năm khi đổi Mặt Tạm / Overcast...) | Banner mới của bậc cao hơn hiện trong cùng lượt | Không phải event riêng: chỉ phát `dm_setN` của bậc MỚI, cắt bậc cũ. Không phát chồng cả hai | - | - | Dùng chung `dm_set4/5`. Ghi chú: nếu bậc cũ đang phát chưa xong thì fade 80 ms rồi vào bậc mới | - |

Tăng cấp rõ rệt: số nốt 0 -> 2 -> 3 -> 4 + hợp âm + mưa; dài 0.5 -> 0.7 -> 1.0 -> 2.0 s; to -6 -> -2 -> -1 -> 0 dB; ducking 0 -> 3 -> 4 -> 6 dB. Đừng cho người chơi nghe set3 nhỏ hơn quá nhiều mà thành vô cảm: ba viên là mức hay gặp nhất nên phải vui, chỉ không "to".

### 2.2 Reroll, Liều, Nứt

| Event | Khi nào phát | Ưu tiên / ducking | Dài | To | Asset | Pitch |
|---|---|---|---|---|---|---|
| `dm_reroll_free` | Bấm "TUNG LẠI (miễn phí)" | Như `dm_roll` | 0.5 s | -6 dB | Dùng `dm_roll` luôn, không cần âm riêng | như `dm_roll` |
| `dm_reroll_safe` | Bấm "AN TOÀN: 2 mana" | Như `dm_roll` | 0.6 s | -6 dB | `dm_roll` + một tiếng "tinh" nhỏ của mana bị trừ (đồng xu rơi nhẹ). [MỚI] `dm_mana_spend` 0.15 s | +-0.5 semitone |
| `dm_gamble_arm` | Bấm "LIỀU" (viên bắt đầu lăn, người chơi chưa biết kết quả) | Trung bình. Duck Music -2 dB suốt thời gian tick | 0.9 s | -5 dB | [MỚI] `dm_roll` + lớp "căng": 5-6 tiếng tick đều như đồng hồ/ mõ gỗ, tốc độ nhanh dần, cao độ nhích lên mỗi tick (A4 -> D5), cuối cùng là một khoảng lặng 80 ms trước khi số hiện. Không có tiếng trầm nặng nề | Cao độ tick cố định (cho cảm giác thang), chỉ random vi mô +-0.1 semitone |
| `dm_crack` (có viên bị Nứt) | Lúc số hiện ra và viên đó hiện vết nứt | Trung bình. Một cái duy nhất mỗi lần tung, dù Nứt 1 hay 3 viên (viên thứ hai, ba thêm một lớp nhẹ lệch 60 ms, tối đa 3 lớp) | 0.3 s | -8 dB | [MỚI] "nứt" kiểu đáng yêu: một tiếng gốm/men nứt "tic-kít" nhỏ, giống vỏ trứng khẽ nứt, thêm một nốt "oop" ngắn đi xuống nhẹ (kiểu hoạt hình, không phải còi báo lỗi). KHÔNG dùng: buzzer, nốt trầm, thuỷ tinh vỡ chói, nhạc thua, giọng cười chê | +-1 semitone, 3 biến thể. Không đi xuống quá 3 semitone |
| `dm_gamble_clean` (thoát Nứt: Liều xong, không viên nào Nứt) | Số hiện ra, 0 viên Nứt | Trung bình, thấp hơn `dm_set3`. Nếu cùng lúc ra Bộ thì bỏ cái này, chỉ phát âm Bộ | 0.4 s | -5 dB | [TẠM] `sfx/status/cleanse.ogg` hoặc `cure.ogg` (nghe thử). [MỚI] đích: một tiếng thở phào sáng: hai nốt đi lên nhanh (E5-A5), marimba, kèm một chút "whoosh" nhẹ | +-0.3 semitone |
| `dm_crack_fade` (Nứt hết sau lượt) | Đầu lượt sau, viên Nứt trở lại bình thường | Thấp | 0.25 s | -10 dB | [MỚI] "tách" nhỏ + nốt lên ngắn, hơi giống `dm_gamble_clean` nhưng nhỏ hơn. Có thể gộp vào `cleanse.ogg` [TẠM] | +-0.5 semitone |

Câu chuyện âm thanh của Liều: tick (hồi hộp) -> khoảng lặng -> (a) "tic-kít + oop" nhẹ nếu Nứt, hoặc (b) hai nốt sáng nếu sạch. Nứt phải nghe như "ối, hụt", không phải "bạn thua". Người chơi chọn Liều có ý thức, nên âm Nứt không được phạt thêm.

### 2.3 Mặt Tạm, Overcast, Lõi

| Event | Khi nào phát | Ưu tiên / ducking | Dài | To | Asset | Pitch |
|---|---|---|---|---|---|---|
| `dm_wild_pick` | Bấm viên rồi chip part để xác nhận Mặt Tạm | Trung bình | 0.35 s | -6 dB | [MỚI] "swap" ma thuật: một whoosh ngắn + chuông nhỏ lật (kiểu thẻ lật). 0.35 s | +-0.5 semitone |
| `dm_wild_match` (Mặt Tạm "khớp", hoàn thành BỘ) | Ngay sau `dm_wild_pick`, nếu kết quả tạo hoặc nâng Bộ | Thay `dm_wild_pick` (cắt nó). Rồi 120 ms sau phát `dm_setN` của bậc Bộ mới. Không phát cả "match" lẫn nốt đầu của setN trùng nhau: `dm_wild_match` ngắn và nằm ở tông thấp hơn để đi vào setN | 0.3 s | -4 dB | [MỚI] "click" khớp: hai mảnh ghép khớp nhau + một nốt G5 ngắn. Nếu Mặt Tạm không đổi Bộ ("không đổi") thì chỉ phát `dm_wild_pick`, không phát match | +-0.2 semitone |
| `dm_overcast_charge` | Bấm "OVERCAST 3" và xác nhận viên | Trung bình cao. Duck Music -3 dB 0.8 s | 0.8 s | -3 dB | [TẠM] `sfx/status/power_awaken.ogg` (đang là tiếng boss đổi pha, ý nghĩa khác, chỉ nghe thử). [MỚI] đích: một đợt dâng năng lượng 0.6 s (swell kiểu synth ấm/chuông tăng dần, tông lên một quãng 5) rồi một "pop" sáng. Số "+0.5" hiện đúng lúc pop. Cảm giác "nạp", khác hẳn jackpot ở chỗ chỉ có một nốt đỉnh, không có mưa đá quý | Cao độ cuối cố định, chỉ random lớp swell +-0.3 semitone |
| `dm_core_open` | Màn chọn Lõi mở (3 thẻ) | Trung bình. Duck Music -3 dB trong lúc chọn | 1.0 s | -4 dB | [MỚI] tiếng chuông thuỷ tinh/crystal bowl dài, bay lên | không random |
| `dm_core_hover` | Chuột/focus vào thẻ Lõi | Thấp, tối đa 4 lần mỗi giây | 0.1 s | -14 dB | [MỚI] tick thuỷ tinh rất nhỏ | +-1 semitone |
| `dm_core_pick` (chọn Lõi bậc Tinh Thể) | Xác nhận chọn một Lõi | Cao. Cắt `dm_core_open` | 1.4 s | -1 dB | [MỚI] "kết tinh": hợp âm chuông C-G-C (nhạc cụ: celesta + harp glissando đi lên 0.5 s), có một tiếng "cling" cuối. Ngắn hơn và đỡ hoành tráng hơn jackpot để jackpot vẫn là đỉnh | không random (đây là cú nhấn một lần mỗi run) |

Tổng: 18 event (dm_roll, dm_land, dm_pair, dm_set3, dm_set4, dm_set5, dm_reroll_free [= dm_roll], dm_reroll_safe, dm_gamble_arm, dm_crack, dm_gamble_clean, dm_crack_fade, dm_wild_pick, dm_wild_match, dm_overcast_charge, dm_core_open, dm_core_hover, dm_core_pick). `dm_set_up` không đếm vì dùng lại set4/5, `dm_reroll_free` dùng lại `dm_roll`, nên cần làm 16 âm riêng.

Dùng lại được ngay (placeholder, cần nghe thử): `dm_set3` (power_gain / buff), `dm_gamble_clean` (cleanse / cure), `dm_crack_fade` (cleanse), `dm_overcast_charge` (power_awaken). Các âm còn lại không có gì tương đương, phải làm mới. Không có âm nào ở nhóm này "dùng ngay không cần thay" ở mức chất lượng cuối, vì asset hiện có là âm trạng thái combat, không phải âm thưởng cho khoảnh khắc gacha.

## 3. VFX đi kèm (ghi chú cho technical-artist)

Nguyên tắc: nhẹ, phẳng (UI3 không blur, không shader trên UI), không che số, mọi hiệu ứng phải đi qua cờ `MetaState.reduce_flash` và có phiên bản "ít chuyển động".

| Event | VFX | Reduce flashing bật |
|---|---|---|
| `dm_roll` / `dm_land` | Viên nảy nhẹ 4-6 px khi dừng. Không particle | Giữ nguyên (nảy nhẹ không phải nháy) |
| `dm_pair` | Thanh nối nét đứt giữa hai viên sáng lên mờ rồi xuống, 0.2 s | Bỏ phần sáng, giữ nét đứt hiện |
| `dm_set3` | Viên trong Bộ nhảy lên 8 px, viền nhóm đậm hơn một nhịp. Banner 36 px hiện 0.6 s | Bỏ nháy viền, chỉ banner và nhảy |
| `dm_set4` | Như set3 + 6-8 hạt lấp lánh nhỏ bay lên từ mỗi viên trong Bộ, tối đa 0.5 s. Số nhân "5 -> 8" phóng to 110% rồi về | Bỏ hạt, giữ phóng to số |
| `dm_set5` | Như set4 + rung khay xúc xắc 3 px, 2 nhịp, + mưa hạt đá quý/đồng xu 0.8 s từ trên xuống, bay ở nền sau số, không che số (số luôn nằm lớp trên, hạt giảm alpha khi đi ngang vùng số). Banner thêm viền vàng | Bỏ rung và mưa hạt, thay bằng banner đứng yên + một vòng sáng cố định 0.6 s (không nhấp nháy). Không có nháy toàn màn hình ở bất cứ trường hợp nào |
| `dm_gamble_arm` | Nút Liều rung 2 px theo nhịp tick. Viền khay hơi ám (amber, không đỏ) | Bỏ rung, giữ viền cố định |
| `dm_crack` | Vết nứt hiện trên viên (hình, vẽ nhanh 0.15 s), viên lắc 2 lần nhẹ, chip "1/2" hiện. KHÔNG flash đỏ, không rung khay | Bỏ lắc, chỉ vết nứt tĩnh |
| `dm_gamble_clean` | Một tia sáng nhỏ quét qua khay 0.3 s, cream, không đỏ | Bỏ tia quét, hiện chữ "Sạch" nhỏ 0.6 s |
| `dm_crack_fade` | Vết nứt mờ dần 0.3 s | Giữ (đã là mờ dần, không nháy) |
| `dm_wild_pick` / `dm_wild_match` | Huy hiệu "?" lật thành glyph part (xoay 0.25 s), sau đó viền nhóm nối viên này vào Bộ | Bỏ xoay, đổi tức thì |
| `dm_overcast_charge` | Vòng sáng lan từ viên ra ngoài 0.5 s, số "+0.5" nổi lên | Bỏ vòng lan, chỉ số nổi |
| `dm_core_open` / `dm_core_pick` | Thẻ Lõi bậc Tinh Thể có viền tinh thể lung linh chậm (loop 3 s, alpha dao động nhẹ). Chọn: thẻ phóng 105%, hạt tinh thể 8 mảnh rơi quanh | Bỏ lung linh và hạt, viền tĩnh |

Luật chung cho VFX: không nháy quá 3 lần/giây, không nháy toàn màn hình, không dùng đỏ cho thứ không phải nguy hiểm (UI3). Màu nào mã hoá cơ chế thì kèm glyph.

## 4. Tránh mệt tai khi lặp nhiều lượt

1. Âm xuất hiện mỗi lượt (`dm_roll`, `dm_land`) ngắn (<= 0.5 s), tần số thấp-vừa, nhỏ (-6 đến -12 dB), có biến thể và pitch random.
2. Âm thưởng (`dm_set3`) giảm dần nếu lặp: sau lần thứ 4 trong cùng một trận thì phát ở -3 dB (bỏ lớp lấp lánh, giữ 2 nốt); sang trận sau thì reset. `dm_set4`, `dm_set5` hiếm nên không giảm.
3. Không loop dài. Lớp tick `dm_gamble_arm` chạy tối đa 1 s, không lặp.
4. Mỗi lượt chỉ có một "âm đỉnh": `dm_set5` > `dm_set4` > `dm_set3` > `dm_overcast_charge` > `dm_wild_match` > `dm_gamble_clean`. Âm đỉnh cắt hoặc hạ âm khác ở cùng thời điểm, không chồng.
5. Tần số: âm xúc xắc ở 800 Hz - 5 kHz, âm thưởng ở 1 - 8 kHz, tránh dải 200-500 Hz nơi tiếng đánh combat đang nằm. Không dùng sóng răng cưa chói hay dải > 8 kHz kéo dài.
6. Khoảng lặng 80 ms trước khi số hiện ở Liều là một phần của thiết kế, đừng lấp bằng âm.
7. Âm Nứt luôn nhỏ hơn âm Bộ ít nhất 6 dB và không đi kèm tiếng trầm. Tránh để lượt xấu nghe như bị trừng phạt, vì người chơi sẽ tắt âm.
8. Ducking Music chỉ tạm thời (đi về trong 0.3-0.6 s), không để nhạc nền "thở" liên tục khi tung nhanh.
9. Nếu người chơi bấm tung liên tục (< 0.5 s giữa hai lần), cắt âm lần trước ngay, không để âm đuôi chồng thành "cháo".

Chế độ tắt:
- Nghe theo `audio_muted` và `audio_sfx_volume` hiện có. Tất cả `dm_*` đi qua bus `SFX`.
- Đề xuất thêm một công tắc "Âm khoảnh khắc xúc xắc" (mặc định BẬT) trong Cài đặt, riêng với SFX combat, để người chơi tắt âm thưởng nhưng vẫn nghe đánh nhau. Đây là việc cần Liam duyệt (câu hỏi 2 bên dưới) vì đụng MetaState (mục "Thêm field mới vào meta save thì phải sửa cả `MetaState.reload_from_store()`" trong CLAUDE.md).
- Âm chỉ là lớp thêm: mọi thông tin vẫn có trên màn (banner, chip, số). Không có thông tin nào chỉ nằm trong âm thanh.
- `reduce_flash` không tắt âm, chỉ tắt VFX nháy (mục 3).

## 5. Yêu cầu cho người triển khai (không viết code)

- Cần ít nhất 2 voice riêng cho `dm_*` (ngoài 8 voice combat hiện có), vì voice pool quay vòng sẽ cắt tiếng Bộ khi có một AoE nổ cùng lúc.
- Cần ducking Music (tween volume Music bus theo bảng) và ducking SFX combat nhẹ cho `dm_set5`. Hiện chưa có.
- Cần bộ chọn biến thể (không lặp liền nhau) và pitch random +-semitone. Hiện `_play()` chưa có.
- Tên event nên gắn với tín hiệu logic của luật (set_formed, set_upgraded, crack_applied, gamble_started, wild_applied, overcast_applied, core_picked). Hiện `EventBus` chưa có các tín hiệu này, nên cần lane code thêm chúng cùng lúc với GDD v4. Test headless: `disable_juice_for_tests` phải tắt hết âm `dm_*` như CombatAudioDirector đã làm.
- Các tên event, tên file `.ogg`, bus: mình đề xuất, chưa chốt. Audio-director chốt.

## 6. Câu hỏi cần Liam / audio-director quyết
1. "Thoát Nứt" nghĩa là gì? Mình hiểu hai nghĩa: (a) Liều xong mà không viên nào Nứt (`dm_gamble_clean`), (b) viên Nứt hết ở lượt sau (`dm_crack_fade`). Đã làm cả hai, hỏi để xem có bỏ cái nào không.
2. Có thêm công tắc riêng "âm khoảnh khắc xúc xắc" trong Cài đặt không (cần sửa MetaState + save)?
3. Chất âm: mình đề xuất marimba/kalimba/celesta/chuông, ấm và cute, hợp Lunacia. Nếu audio-director muốn nghiêng về arcade/synth hơn thì mình đổi lại danh sách nhạc cụ.
4. Jackpot BỘ NĂM có cần có "stinger" nhạc (nhạc nền nhường chỗ 2 giây) không, hay chỉ ducking như trên là đủ?
5. Tìm asset hay thuê làm? Mình chưa tìm thư viện nào ngoài; nếu dùng pack có sẵn thì cần Liam duyệt giấy phép.

## 7. Bảng chọn âm từ kho hiện có

Kho: `sfx/class/` (78 file, 6 class x 13 loại: bite/cast/gore/projectile/slash/smash/throw attack, fly, hit), `sfx/status/` (35 file), `music/` (5 bài, không dùng cho SFX).

Lưu ý quan trọng: lượt này mình không có công cụ chạy `afinfo` hay nghe file, nên KHÔNG đo độ dài và KHÔNG nghe. Mọi lựa chọn dưới đây dựa vào tên file và cách game đang dùng chúng. Cột "độ tin" là mức mình tin vào tên: Cao / Vừa / Yếu. Cần audio-director nghe thử, chạy `afinfo <file> | grep duration` cho file được chọn, rồi chỉnh. Nếu file nào dài quá độ dài đích ở mục 2 thì cắt đuôi bằng fade khi import, không đổi bố trí.

Loại bỏ cả nhóm `sfx/class/`: toàn tiếng đánh, bay, trúng đòn của Axie. Không có tiếng nào nghe như xúc xắc, chuông hay phần thưởng, và dùng chúng sẽ lẫn với combat (dải 200-500 Hz mà mục 4.5 muốn tránh). Chỉ lấy `status/`.

Cách đọc cột pitch: số nhân `pitch_scale` (1.0 = gốc, 1.059 = +1 semitone, 1.122 = +2, 1.189 = +3, 1.26 = +4, 1.335 = +5, 1.5 = +7). Chồng lớp: các layer phát cùng lúc, hoặc lệch nhau `+N ms` khi ghi vậy. Pitch lên thì file ngắn lại theo, nên bậc cao nghe nhanh và sáng hơn (hợp ý tăng cấp).

### 7.1 Tăng cấp BỘ (phần quan trọng nhất)

Ý tưởng: dùng cùng một họ âm (`buff`, `power_gain`, `power_awaken`, `morph_aura_burst`), tăng cấp bằng số lớp chồng và độ cao, không bằng một file khác. Người chơi nghe ba = một lớp, bốn = hai lớp lên cao, năm = nhiều lớp + một cú nổ.

| Event | File (res://assets/audio/sfx/status/...) | Pitch, vol, chồng lớp | Lý do | Độ tin |
|---|---|---|---|---|
| `dm_set3` | `buff.ogg` | Một lớp, pitch 1.0, -2 dB | "buff" là tiếng được cộng sức mạnh, đúng nghĩa "Bộ ba x1.4". Không dùng `power_gain` vì nó đang là tiếng crit, dễ lẫn (bản code tạm đang dùng power_gain, nên đổi) | Vừa |
| `dm_set4` | `buff.ogg` + `power_gain.ogg` | Lớp A: buff pitch 1.12, -1 dB. Lớp B: power_gain pitch 1.26, -3 dB, lệch +90 ms | Hai lớp, cao hơn bậc ba 2 đến 4 semitone, lớp thứ hai vào sau tạo cảm giác "lên thêm một bậc" như arpeggio. Dài hơn set3 nhờ lớp B | Vừa |
| `dm_set5` | `buff.ogg` + `power_gain.ogg` + `power_awaken.ogg` + `morph_aura_burst.ogg` | Lớp A: buff 1.26, 0 dB. Lớp B: power_gain 1.5, -2 dB, +90 ms. Lớp C: power_awaken 1.19, -2 dB, +200 ms (thân hợp âm). Lớp D: morph_aura_burst 1.0, -3 dB, +200 ms (cú nổ jackpot). Cắt mọi `dm_*` khác như mục 2.1 | Bốn lớp, đủ khác set4 từ 0.2 s đầu vì có lớp D. Thân + cú nổ lấy tên "awaken" và "aura burst" (thức tỉnh, bùng nổ). Mưa đá quý / đồng xu 0.8 s KHÔNG có trong kho, xem 7.4 | Yếu đến Vừa. Cần nghe: bốn lớp chồng dễ thành tiếng ồn, nếu vậy bỏ lớp C |
| `dm_set_up` | (dùng set4 / set5) | Không thêm gì | Như mục 2.1 | - |

Nếu muốn tăng cấp rõ hơn nữa mà không thêm file: set3 pitch 1.0, set4 pitch 1.12, set5 pitch 1.26 (cách nhau đều 2 đến 4 semitone), và bỏ random pitch ở set3 thấp quá (cho khỏi nhập nhằng thang này).

### 7.2 Rủi ro và thoát Nứt

| Event | File | Pitch, vol | Lý do | Độ tin |
|---|---|---|---|---|
| `dm_gamble_clean` | `cleanse.ogg` | 1.12, -5 dB. Thay thế được bằng `cure.ogg` | "Cleanse" = sạch, đúng nghĩa thở phào "không Nứt". Pitch lên một chút cho sáng. Mục 1 spec đã chọn sẵn | Vừa |
| `dm_crack_fade` | `cleanse.ogg` | 1.3, -10 dB (bản nhỏ và cao hơn gamble_clean) | Cùng họ nhưng khác pitch và nhỏ hơn 5 dB, người chơi nghe ra "cùng ý nghĩa, nhỏ hơn" | Vừa |
| `dm_crack` | KHÔNG CÓ | - | Xem 7.4. Các file `bleed`, `debuff`, `weak`, `vunerable`, `disarm` nghe như trừng phạt, đúng loại spec cấm ở mục 2.2 (Nứt phải "ối, hụt", không phải "thua") | - |

### 7.3 Mặt Tạm, Overcast, Lõi

| Event | File | Pitch, vol, chồng lớp | Lý do | Độ tin |
|---|---|---|---|---|
| `dm_wild_pick` | `feather.ogg` | pitch 1.2, -6 dB | Lông vũ = nhẹ, "swap/lật", gần với whoosh ngắn mà spec cần. Chỉ là placeholder, thiếu "chuông lật" | Yếu |
| `dm_wild_match` | `shield.ogg` | pitch 1.5, -4 dB | Tiếng khoá / khớp vào (shield bật lên) ngắn, pitch cao gần "click" ghép mảnh. Không phải chọn mạnh, nghe thử so với `secret.ogg` | Yếu |
| `dm_overcast_charge` | `power_awaken.ogg` + `power_gain.ogg` | Lớp A: power_awaken 1.0, -3 dB (giữ như code). Lớp B: power_gain pitch 1.5, -3 dB, lệch +600 ms làm "pop" cuối khi "+0.5" hiện (căn giờ theo độ dài file thật sau khi đo) | Swell + một nốt đỉnh duy nhất đúng ý "nạp" (mục 2.3). Chỉ một nốt đỉnh nên khác jackpot. Nếu awaken ngắn hơn 600 ms thì dời lớp B cho khớp | Vừa |
| `dm_core_open` | `secret.ogg` | pitch 1.0, -4 dB | "Secret" = tiết lộ, huyền bí. Chỉ placeholder, thiếu chuông thuỷ tinh | Yếu |
| `dm_core_pick` | `morph_aura_burst.ogg` + `buff.ogg` | Lớp A: morph_aura_burst 1.12, -3 dB. Lớp B: buff 1.5, -2 dB, +120 ms. Phải nhỏ hơn set5 (A của set5 là 0 dB, lớp D cùng file -3 dB nhưng pitch 1.0): dùng ít lớp hơn là đủ | "Kết tinh" gần với "aura burst" + một nốt sáng. Đỡ hoành tráng hơn jackpot vì 2 lớp so với 4 | Yếu |
| `dm_core_hover` | KHÔNG CÓ | - | Xem 7.4 | - |

### 7.4 Event kho hiện có KHÔNG có âm phù hợp (cần nguồn mới)

| Event | Âm cần tìm | Ghi chú |
|---|---|---|
| `dm_roll` (và `dm_reroll_free`) | 3-5 viên xúc xắc gỗ/gốm nhỏ lăn rồi lách cách trên khay, 0.5 s, ấm, không kim loại. 4 biến thể | Kho không có tiếng va chạm vật cứng nào. Nhóm `fly` / `throw_fly` là whoosh, không phải lăn |
| `dm_land` | Một "tok" gỗ khô cực ngắn 0.08 s, 3 biến thể | Cần tần số 800 Hz - 5 kHz. Không file nào ngắn và khô cỡ đó theo tên |
| `dm_pair` | Một nốt marimba / kalimba G5, 0.25 s | Kho không có âm có cao độ rõ (kiểu nhạc cụ) |
| `dm_reroll_safe` | `dm_roll` + `dm_mana_spend`: đồng xu rơi nhẹ 0.15 s | Phần roll thiếu (xem trên), phần "tinh" cũng thiếu |
| `dm_gamble_arm` | 5-6 tiếng tick như mõ gỗ, nhanh dần, cao độ A4 -> D5, rồi 80 ms im | Nên làm từ một tick đơn lặp bằng code (một file tick, pitch tăng dần mỗi lần), chỉ cần 1 file mới |
| `dm_crack` | Gốm/men nứt "tic-kít" nhỏ như vỏ trứng + một nốt "oop" xuống nhẹ (kiểu hoạt hình), 0.3 s, 3 biến thể | KHÔNG dùng buzzer, nốt trầm, thuỷ tinh vỡ chói |
| `dm_core_hover` | Tick thuỷ tinh rất nhỏ 0.1 s | Có thể dùng chung một tick với gamble_arm nếu pitch cao |
| Lớp "mưa đá quý/đồng xu" của `dm_set5` | Mưa đồng xu / đá quý nhỏ 0.8 s, 3 biến thể | Thiếu lớp này jackpot vẫn chạy bằng 4 lớp ở 7.1 nhưng sẽ kém hơn "kiểu gacha" |
| `dm_wild_pick`, `dm_wild_match`, `dm_core_open`, `dm_core_pick` | Bản đích như mục 2.3 (chuông lật, click khớp, crystal bowl, celesta + harp) | Đã có placeholder Yếu ở 7.3, nhưng chất âm đúng vẫn phải làm mới |

### 7.5 Tổng kết

- 18 event: 6 event có âm dùng được (Vừa): `dm_set3`, `dm_set4`, `dm_set5`, `dm_gamble_clean`, `dm_crack_fade`, `dm_overcast_charge`.
- 4 event có placeholder Yếu (nghe thử, nên thay): `dm_wild_pick`, `dm_wild_match`, `dm_core_open`, `dm_core_pick`.
- 8 event thiếu hẳn, cần nguồn mới: `dm_roll`, `dm_reroll_free` (= roll), `dm_reroll_safe`, `dm_land`, `dm_pair`, `dm_gamble_arm`, `dm_crack`, `dm_core_hover`.
- Việc cho người lập trình, nếu Liam duyệt: `EVENTS` trong `DiceMomentAudio.gd` hiện chỉ có 1 path và 1 db mỗi event. Chồng lớp và pitch nhân (bảng trên) cần đổi sang danh sách layer `{path, db, pitch, delay_ms}`. Chưa sửa gì.
- Việc cần người nghe trước: đo độ dài từng file được chọn bằng `afinfo`, nghe thử 4 lớp của set5 xem có bị cháo không.


## 8. Âm từ MyGame SFX

Nguồn: MyGame SFX (Sky Mavis IP, Liam cho phép 23/10). File chép vào `godot/assets/audio/sfx/ui/`, giữ tên gốc. Code: `DiceMomentAudio.EVENTS` có thêm `layers` ({path | paths, db, pitch, pj, delay_ms}); biến thể và pitch ngẫu nhiên dùng rng UI riêng, không đụng rng engine. Gacha dùng chung qua `gacha_timing.json` (`layers`). Độ dài đo bằng `afinfo`. Không file nào quá 1.5 s nên không cần cắt.

| Event | File (độ dài) | dB | Pitch | Ghi chú |
|---|---|---|---|---|
| dm_roll, dm_reroll_free | ui_tap_01/02/03 (0.09 s) | -6 | 1.0 +-0.05 | chọn ngẫu nhiên 1 trong 3 |
| dm_land | ui_tap_02 (0.09 s) | -15 | 1.2 +-0.06 | phát mỗi viên (5/lượt); giảm 3 dB + jitter pitch sau review audio-director |
| dm_set4 | power_gain (status) + star_activate | -2 / -6 | 1.0 / 1.1 | lớp 2 là phần "lên thêm một bậc" so với set3 |
| dm_pair | ui_toast (0.40 s) | -9 | 1.0 | |
| dm_reroll_safe | resource_collect_01 (0.40 s) | -6 | 1.0 | |
| dm_gamble_arm | ui_tap_03 x5 (0.09 s) | -5 | 1.0, 1.07, 1.14, 1.22, 1.33 | delay 0/170/320/440/540 ms, nhanh dần |
| dm_crack | overflow_death_crack (0.40 s) | -8 | 1.3 | đuôi 0.4 s, không cần stop |
| dm_core_hover | ui_tap_01 (0.09 s) | -14 | 1.5 | |
| dm_wild_pick | ui_confirm_01 (0.30 s) | -6 | 1.0 | |
| dm_wild_match | ui_confirm_02 (0.30 s) | -4 | 1.2 | |
| dm_core_open | ui_modal_open (0.30 s) | -4 | 1.0 | |
| dm_core_pick | star_activate (1.30 s) | -1 | 1.0 | |
| dm_set5 | talent_capstone_unlock (1.14 s) + axie_level_up (1.20 s) | 0 / -4 | 1.0 | lớp 2 trễ 120 ms |
| dm_combo PAIR | star_activate | -3 | 1.0 | |
| dm_combo_full (mới) | axie_level_up + talent_capstone_unlock | -3 / -4 | 1.0 | lớp 2 trễ 100 ms |
| gacha pair | star_activate | -3 | 1.0 | |
| gacha full | axie_level_up + talent_capstone_unlock | -3 / -4 | 1.0 | lớp 2 trễ 100 ms |
| gacha jackpot | talent_capstone_unlock | -2 | 1.0 | |
| gacha near_miss | overflow_death_crack | -12 | 1.0 | |

Giữ nguyên (chưa đổi): dm_set3 (power_gain), dm_overcast_charge, dm_gamble_clean, dm_crack_fade (placeholder status/).
