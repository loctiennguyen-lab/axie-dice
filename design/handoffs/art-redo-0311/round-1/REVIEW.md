# Art lượt 1 (thẻ Lõi, 23 món): kiểm bản giao Claude Design, 4/11

Bản giao: `_zip/art-batch1/v2/` (giải nén từ "UI mockups for Axie Combat HUD v2.zip", không `git add`).
Sheet của tôi: `review/review-1-cards.png`, `review-2-crest-back-window.png`, `review-3-slots-icons.png`.
Script đo và dựng sheet: `review/measure.py`, `review/sheet.py` (chạy bằng python có numpy + Pillow).

## Bản giao có gì
- Đủ 23/23 món, đúng tên, đúng cỡ canvas, RGBA, đủ bản 128/64/32. Không thiếu file.
- Không phải 3 món thử như handoff ghi. README của Claude Design nói Liam đã duyệt hàng thử v2 rồi 4 vòng sửa ngày 3/11
  (Crystal đổi thành platinum, vẽ lại crest_crystal, dựng lại card back và ô theo kiểu crest), và ghi trạng thái `style-pass`.
  **Cần Liam xác nhận** các vòng duyệt này, vì skill chỉ cho lên `style-pass` khi Liam nói.

## Luật cứng (tôi tự kiểm)
| Luật | Kết quả |
|---|---|
| Không Axie, sinh vật, mặt, mắt | đạt (xem từng món ở cỡ thật) |
| Không chữ, logo | đạt |
| Không viền đen | đạt: không món nào có điểm V < 0.2; V thấp nhất 0.208 (artwin_amber, slot_crystal) |
| Sao lấp lánh chỉ trên đá quý / kính / nhẫn | đạt: 3 sao, cả 3 trên tinh thể (crest_crystal, back_art_crystal, slot_crystal 128/64) |
| Crest để trống đĩa giữa Ø42 tại (80,46) | đạt: đĩa phẳng (độ lệch màu < 3.2/255), bán kính ~19–20 px, không biểu tượng |
| Nine-patch: margin đúng, tâm trong suốt | đạt: phần giữa 0 % pixel đặc ở cả 7 khung; góc nằm trong patch góc |

## Số đo (tôi đo lại)
Cách đo của tôi chạy trên 65 icon kho cho ra p5–p95: minV 0.205, cov 0.373–0.839, grain 0.78–2.94, màu 20–159. Khớp bảng
ngưỡng của skill, nên dùng làm thước được. Số của Claude Design thấp hơn số của tôi một cách đều đặn (grain thấp hơn ~25 %,
số màu thấp hơn ~40 %), nên họ đo khác cách. Trong ngoặc là số Claude Design tự báo.

| món | cov | gần đen % | minV | grain | số màu | trượt |
|---|---|---|---|---|---|---|
| family_stat | 0.741 | 0 | 0.443 | 2.22 (1.79) | 141 (62) | đạt |
| family_dice | 0.735 | 0 | 0.275 | 3.67 (2.79) | 131 (78) | grain |
| family_quest | 0.507 | 0 | 0.318 | 3.73 (2.68) | 103 (69) | grain |
| family_run_rule | 0.667 | 0 | 0.404 | 3.35 (2.43) | 205 (99) | grain, màu |
| badge_tradeoff | 0.41 | 0 | 0.4 | 2.82 (2.76) | 78 (49) | grain (sát ngưỡng) |
| badge_convert_to_dmg | 0.388 | 0 | 0.404 | 2.92 (2.26) | 62 (46) | grain (sát ngưỡng) |
| slot_moss | 0.546 | 0 | 0.212 | 3.26 (2.57) | 182 (103) | grain, màu |
| slot_amber | 0.599 | 0 | 0.212 | 3.72 (2.89) | 151 (80) | grain |
| slot_crystal | 0.589 | 0 | 0.208 | 5.49 (4.1) | 184 (117) | grain, màu |
| slot_empty | 0.765 | 0 | 0.216 | 2.47 (1.9) | 42 (33) | đạt |
| crest_moss | 0.514 | 0 | 0.278 | 2.38 (1.7) | 92 (67) | đạt |
| crest_amber | 0.512 | 0 | 0.4 | 3.07 (2.1) | 83 (46) | grain |
| crest_crystal | 0.548 | 0 | 0.306 | 6.74 (4.35) | 170 (128) | grain, màu |
| back_art_moss | 0.485 | 0 | 0.247 | 3.14 (2.31) | 178 (108) | grain, màu |
| back_art_amber | 0.523 | 0 | 0.235 | 3.68 (2.68) | 132 (83) | grain |
| back_art_crystal | 0.527 | 0 | 0.306 | 5.79 (4.07) | 174 (130) | grain, màu |

Khung và khung ảnh (chỉ tham khảo, tâm trong suốt nên cov thấp là đúng): grain 5.7–12.3, màu 43–154.

Đọc số:
- Gần đen và minV đạt hết. Đây là hai chỉ số phải sửa nếu trượt.
- Tôi đếm **3/16 đạt cả 5** (Claude Design báo 12/16). Theo ngưỡng 2.94 đo trên kho thì thêm 2 badge, thành 5/16.
  Kho chỉ đạt ~70 %, chính 43 ảnh kho dùng làm mẫu lượt này đạt 18/43 với cách đo của tôi.
- Trượt chủ yếu là grain cao: nét run tay + vệt cọ dày hơn kho. Khớp hướng "run tay 9/10" Liam đã chọn, nhưng 3 món platinum
  (grain 5.5–6.7) bằng mức các món kho nhiều chi tiết nhất (s3b/s3c 6.1, s18c 5.7). Grain và màu là cảnh báo, không bắt vẽ lại.

## Lắp vào game: 3 chỗ phải sửa code (hoặc xin vẽ lại)
1. **Nền thân thẻ.** Khung thẻ đang chạy có tâm vẽ sẵn (nền nâu tối) và code không vẽ nền riêng (`CoreCardShell` chỉ có
   `TierFrame` + nội dung). Khung mới tâm trong suốt (đúng brief) nên thân thẻ sẽ trong suốt, chữ nằm thẳng lên nền màn.
   Cách sửa: thêm một panel token màu phẳng sau khung (inset ~30 px). Áp cho cả `frame_run_rule`.
2. **Nền khung ảnh.** `artwin_*` đang chạy có cảnh vẽ bên trong (đồi xanh, quầng cam, tinh thể xanh). Bản mới chỉ còn khung
   rỗng, emblem sẽ nằm trên nền tối trống. Cần chọn: nền màu phẳng theo tier bằng code, để tối, hay xin Claude Design vẽ nền.
3. **Emblem trong ô.** Ô mới có cánh + chóp nên lõi tối chỉ còn ~48 % bề rộng, tâm (64,66) trên bản 128 (README cũng báo).
   Code đặt emblem 0.6 × ô ở chính giữa (`CorePanel.gd:318`, `RunMapHud.gd:146`, `RunPauseMenu`, `ComboBand`, `AnchorFx`),
   nên emblem đè lên vành (sheet 3). Hạ emblem xuống ~0.42 và dịch xuống ~1.5 %. Ở ô 44 px emblem còn ~18 px.

## Art-director soát độc lập
Xem qua sheet, README và code; chưa mở từng PNG 64/32 riêng.
- Giữ 15 món. Sửa nhỏ 7: `frame_core_crystal` (xem dưới), 3 `artwin` (cần nền), 3 slot tier (emblem trong ô 44 px).
- **Vẽ lại `family_stat`**: trái tim trông như quả dâu hoặc miếng thịt (hạt trắng lấm tấm, matte). Nên bóng gọn như peach / gem trong kho.
- **Khung moss và platinum gần nhau** (xám be và trắng xám), chỉ khác nhờ rêu và pha lê ở góc; ở cỡ nhỏ dễ lẫn. Crest và
  card back thì 3 tier đọc rõ.
- 4 emblem mới ngồi chung bộ được với pos / mana / rule, trừ trái tim. Nhìn chung emblem mới mềm và matte hơn bộ kho.
- Luật cứng: không thấy vi phạm. Đồng ý số grain trong README không khớp đo lại.
- Thêm khi lắp: gem tier (`TierShards`) cũng đặt trên ô, sẽ đè vương miện của ô mới; crest có cánh rộng hơn nên đĩa giữa
  ở 76 % cần chụp kiểm ở 1920 và 1280 (TierCrest vẽ đĩa + gem lên đó).
- Kết luận: hướng đúng, nhưng chưa lắp ngay; xử lý trái tim, ô, nền khung ảnh trước.

## Kết luận và việc chờ Liam
Hướng vẽ đạt: đúng luật cứng, bám kho, card back và crest đẹp hơn rõ so với bản UI-06. Chưa lắp vào game. Cần Liam:
1. Xác nhận 4 vòng duyệt ngày 3/11 trong Claude Design (để ghi `style-pass`), và chấp nhận grain cao hơn kho như bảng trên.
2. `family_stat`: xin Claude Design vẽ lại trái tim (đề xuất), hay giữ.
3. Khung moss / platinum gần nhau: xin Claude Design kéo xa ra (vd moss ấm hơn + rêu dày hơn dọc cạnh), hay giữ.
4. Nền thân thẻ: tôi đề xuất code thêm panel màu token phía sau khung (không cần vẽ lại).
5. Nền khung ảnh: (a) màu phẳng theo tier bằng code, (b) để tối, (c) xin Claude Design vẽ nền. Đề xuất (a).
6. Ô 44 / 38 px: sửa code cỡ emblem (~0.42) và gem tier khi lắp, chụp kiểm. Không cần quyết.

Liam chốt xong thì: gửi Claude Design phần sửa (mục 2, 3 nếu có), rồi lắp vào game theo bước 6 của handoff
(`UI6Assets.gd`, thay file `godot/assets/ui6/`, `--import`, test, chụp 1920 + 1280, review, QA, hỏi deploy).

## Liam chốt (4/11) và lắp vào game
Liam đồng ý mục 1, 3–6 theo đề xuất; **giữ trái tim `family_stat`** như bản giao. Mục 3 (moss / platinum gần nhau) chưa
gửi Claude Design, chờ Liam xác nhận có gửi không.

Đã lắp (chưa commit, chưa deploy):
- 43 PNG chép đè `godot/assets/ui6/` cùng tên, `--import`.
- `TierFrame`: panel `plate` phẳng sau khung ("BodyFill"), lùi 14 px vào dưới viền, co theo margin.
- `ArtWindow`: panel `tier_<tier>_bg` phẳng trong khung ảnh ("WindowFill"); emblem căn giữa ô mở và chặn chiều cao theo ô mở
  (trước là 1.5 × core_emblem tràn qua viền khung ảnh mới).
- `CoreCardShell.content_pad()` = core_pad + 12 cho trái / phải / dưới (viền khung dày ~35 px, chữ từng chạm viền);
  `CoreCard`, `RuleCard` tính bề rộng chữ theo đó.
- Ô socket: `UI6Assets.SLOT_EMBLEM` 0.56 + `place_in_slot()` (tâm lõi y 0.516), dùng ở `RunMapHud`, `RunPauseMenu`,
  `AnchorFx`, `ComboBand`; `CorePanel` dùng 0.56 cho Core (Run Rule không có socket, giữ 0.6). Gem ở `ComboBand` lớn
  dời xuống góc dưới phải, 0.3 × ô.
- 2 file chụp QA nhận `UI6_SHOT_DIR` để không ghi đè ảnh cũ trong `production/qa/ui06/`.

Ảnh: `production/qa/art-batch1/{l1,l2,l3}` (1920 + 1280).
Review độc lập: lead-programmer (code, không lỗi chặn; đã sửa content_pad trả int, bỏ dòng thừa) và art-director (hình:
emblem ô quá nhỏ ở 0.42, emblem tràn khung ảnh, Reroll thẻ chữ dài chạm viền dưới: cả 3 đã sửa, chụp lại).
Còn để ý: viền chọn cyan bị cánh crest platinum vượt ra ở 1280 (nhỏ); gem tier ở dải Lõi vẫn đè góc emblem như trước.
- Liam 4/11: ô socket ở dải Lõi bị kéo thành bầu dục (ô cao hơn rộng, art vẽ STRETCH_SCALE). Đã giữ ô vuông
  (`SIZE_SHRINK_CENTER`) và art giữ tỉ lệ (`STRETCH_KEEP_ASPECT_CENTERED`) ở CorePanel, RunPauseMenu, RunMapHud, ComboBand.
- Suite đủ: **344/344** (4/11, sau mọi sửa). 18 test liên quan chạy lẻ cũng xanh.
- Art-director xem lại: 3 lỗi cũ đã hết, đưa Liam được. Còn: ở 1280 combat ô ~28 px chỉ đọc được tier (tên Lõi ở tooltip);
  emblem trong khung ảnh hơi nhỏ so với ô mở.
