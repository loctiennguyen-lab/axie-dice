# Dice depth v4 - brainstorm (20/10/2026)

Trạng thái: ĐỀ XUẤT, chưa chốt, chưa động code. Viết theo yêu cầu của lead, dựa trên mục "Liam trả lời" cuối
`turn-decisions-brainstorm.md`. Không có "3 Đòn + Tự Nạp" ở đây.

Nguồn tham khảo: Dicey Dungeons (ô có điều kiện lẻ/chẵn/khoảng số), Slice & Dice (mặt có keyword, đồ đổi mặt, cộng hưởng
giữa hero), Dice Throne (tung 3 lần, khoá/mở khoá viên, tổ hợp kiểu Yahtzee kích năng lực), King of Tokyo (reroll là
quyết định, giữ hay bỏ), Balatro (cộng trước, nhân sau, thứ tự quan trọng), Dice Forge (đổi mặt trong run), Luck be a
Landlord (ô cộng hưởng theo hàng xóm). Search web chỉ ra được chi tiết mức tổng quát cho Slice & Dice / Dice Throne, phần
chi tiết luật tôi dùng kiến thức sẵn có, chưa kiểm lại từng luật gốc.

## 0. Giả định cần lead xác nhận trước khi sim

- "Mặt" của một viên có hai trục: LOẠI hiệu ứng (dmg/shield/heal/poison/mana/buff/debuff/summon) và SỐ (giá trị hoặc
  tier). Combo "đôi/ba" tôi tính theo LOẠI (cùng là dmg). Combo "sảnh" cần một trục số 1-6 nằm trên mặt. Nếu mặt chỉ có
  loại + giá trị mà không có "số mặt" thì sảnh đổi thành "đủ k loại khác nhau" (xem M2). Ai đọc code xác nhận giúp.
- Xác suất bên dưới tính xấp xỉ bằng 5d6 thuần để lấy cảm giác (đôi trở lên ~91%, ba trở lên ~21%, tứ ~2%, ngũ ~0.1%).
  Thực tế loại dmg chiếm nhiều mặt hơn nên bộ dmg dễ ra hơn. Phải đo bằng sim, không tin con số này.
- Bài học từ bảng trên: ĐÔI quá dễ (9/10 lượt có), nên đôi chỉ nên là thưởng rất nhỏ. Mục tiêu chase là BA trở lên.

### 0b. Reviewer đã kiểm code (20/10) - hai giả định trên SAI một phần

- Mặt KHÔNG có số 1-6. Mặt là `{p: slot, t: loại, v: giá trị, k: keyword, r: độ hiếm}`
  (`axie_to_die.gd` `resolve_face`). Nhưng mỗi viên có đúng 6 mặt = 6 part, xếp theo `SLOT_ORDER`
  (mouth, horn, back, tail, eyes, ears), và engine đã có `roll_face_index()`. Tức "số mặt" có sẵn: slot 1-6.
- LOẠI gắn chặt vào SLOT (`part_faces.json` familyVariant): mouth và horn luôn là dmg ở cả 6 class; ears gần như luôn
  mana; back là shield (aqua/bug/plant/reptile) hoặc dmg (beast/bird); tail dmg (aqua/beast/bird), poison (bug/reptile),
  shield (plant); eyes heal (aqua/plant/reptile) hoặc debuff (beast/bird/bug).
- Nên số mặt dmg mỗi viên: beast/bird 4/6, aqua 3/6, bug/plant/reptile 2/6. Không viên nào dưới 2/6.
- Xác suất "Ba dmg trở lên" theo luật M1 (cùng LOẠI), tính bằng data chứ không bằng 5d6:
  - Đội trộn ví dụ ở mục 2 (beast, plant, aqua, bird, bug): lần tung đầu 50%, tứ+ 17%. Sau 1 lần reroll an toàn các
    viên không phải dmg: ba+ 89%, tứ+ 58%, ngũ 18%.
  - 5 beast/bird: lần tung đầu ba+ 79%, tứ+ 46%.
  - 5 plant: ba+ 21% (giống 5d6).
- Hệ quả: Bộ theo LOẠI gần như lượt nào cũng có, và gần như luôn là Bộ dmg. Nó thành buff dmg trung bình +60-80% cho viên
  dmg, cả bot Spam (không reroll) cũng ăn. Game sẽ DỄ hơn, ngược yêu cầu Liam. Đội beast/bird hưởng lợi, đội
  plant/bug/reptile bị thiệt có hệ thống. Quyết định cũng sụp về một lối: "reroll mọi viên không phải dmg".
- Đề xuất của reviewer: Bộ tính theo SLOT (cùng số mặt), không theo loại. Khi đó xác suất đúng là 5d6 (ba+ ~21% lần
  đầu, tứ ~2%), "Ba Sừng" / "Ba Lưng" đọc được ngay bằng icon part, và Bộ có cả shield/heal/poison chứ không chỉ dmg.
  Sảnh (M2) cũng khả thi thật: slot liên tiếp. Cần Liam chọn (câu 1 mục 5).
- Reroll hiện tại đã có: 1 lần miễn phí mỗi lượt, sau đó 2 mana/lần, tối đa 4 (`combat_engine.gd` tune `reroll.*`).
  Đề xuất M5 "3 lần miễn phí, bỏ mana" là BUFF so với bây giờ và xoá một chỗ tiêu mana. Xem câu 2.
- Core "Concord" hiện có ép các Axie cùng class ra cùng face index. Với Bộ theo slot nó thành "Bộ chắc chắn". Phải xử lý
  trước khi sim (xem Ghi chú reviewer).

## 1. Mười hai cơ chế

Quy ước: Chi phí S/M/L = công code + test. "Replay" = có đụng ActionLog/RunVerifier/RULES_VERSION không. "Worker" = có
đụng server xúc xắc / kiểm run không (game online-only, xúc xắc do server tung).

### M1. Bộ cùng loại (đôi / ba / tứ / ngũ)
Sau mỗi lần tung, đếm số viên cùng LOẠI. Từ 3 viên cùng loại trở lên thành "Bộ", mỗi viên trong Bộ khi được dùng nhân
giá trị: ba x1.5, tứ x2.0, ngũ x3.0. Đôi chỉ x1.10.
- Ví dụ: tung ra dmg4, dmg3, dmg5, shield3, heal2. Ba dmg = (4+3+5) x 1.5 = 18 damage thay vì 12. Shield và heal giữ
  nguyên.
- Quyết định: đi theo Bộ dmg, hay cắt Bộ để giữ loại khác (cần khiên). Có Bộ rồi thì dùng viên nào trước (xem M11).
- Vì sao bừa thua: bừa thì không biết tung lại cái gì để tới ba/tứ, mất hệ số x1.5-x2 liên tục. Người giỏi ra tứ đều
  hơn nhiều so với tung may.
- Chi phí S. Replay: không (hàm thuần trên 5 mặt, RunVerifier replay ra cùng kết quả), nhưng đổi luật nên bump
  RULES_VERSION. Worker: chỉ nếu Worker chạy bản luật để verify run.

### M2. Sảnh / đa dạng (chuỗi mặt)
Nếu có 3-4-5 viên có số mặt liên tiếp (vd 2-3-4), thành "Sảnh": dùng các viên theo ĐÚNG thứ tự tăng dần thì mỗi viên sau
được +25% cộng dồn (viên 2 +25%, viên 3 +50%, viên 4 +75%). Dùng sai thứ tự thì chuỗi đứt từ chỗ sai. Nếu mặt không có
số, thay bằng "Đa dạng": đủ 4+ loại khác nhau thì mỗi viên +1 giá trị cố định.
- Ví dụ: sảnh 2-3-4 gồm shield2, dmg3, poison4. Nếu dùng shield, dmg, poison theo thứ tự: 2, 3x1.25, 4x1.5. Nhưng
  muốn dmg trước để mở giáp địch thì phải bỏ bonus.
- Quyết định: tuân thứ tự chuỗi hay phá chuỗi vì thứ tự chiến thuật khác.
- Chi phí M (thêm ràng buộc thứ tự dùng, UI phải hiện thứ tự). Replay: không đổi log (log đã ghi thứ tự dùng), bump
  RULES_VERSION. Worker: như M1.

### M3. Đồng tộc (cùng class)
3+ viên được dùng trong cùng lượt thuộc cùng class (Beast, Plant, ...) kích hoạt PASSIVE class mạnh gấp đôi lượt đó, cộng
thêm 10% cho cả đội. Class passive đã áp dụng cho mọi Axie (kể cả Vault/import) nên không cần data mới.
- Ví dụ: 3 Beast ở hàng trước đều dùng, passive Beast x2 trong lượt. Quyết định xếp đội hình đồng class hay đa dạng để
  lấy M1/M2.
- Vì sao bừa thua: bừa không xếp đội theo hướng này, mất 10%+passive x2 mỗi lượt. Người giỏi chọn Axie ngay từ party.
- Chi phí S-M. Replay: không. Worker: như M1.

### M4. Trọn bộ (full house)
Có một Bộ ba và một Đôi khác loại trong cùng lần tung: nhận 1 mana và +1 viên "Hold miễn phí" (xem M6). Thưởng cho người
tung lại giữ đôi phụ thay vì phá nó.
- Ví dụ: dmg4 dmg3 dmg5 + shield3 shield2: Ba dmg + Đôi shield. Hai Bộ cùng nhân, và nhận 1 mana.
- Quyết định: khi nào giữ đôi phụ cho tới cuối thay vì reroll cả hai viên đó để tìm tứ.
- Chi phí S. Replay: không. Worker: như M1.

### M5. Liều (reroll chọn viên, có Nhiệt)
Mỗi lượt tung lại tối đa 3 lần, mỗi lần chọn một TẬP CON bất kỳ trong 5 viên (không tốn mana). Mỗi lần reroll +1 Nhiệt
(tối đa 3, reset đầu lượt). Mỗi Nhiệt cộng +15% vào hệ số mọi Bộ lượt đó. Nhưng khi Nhiệt đã là 2 trở lên, mỗi viên bị
reroll có 20% "Vỡ": mặt thành trống, viên đó không dùng được lượt này và phá Bộ nếu có.
- Ví dụ: sau lần tung đầu có Ba dmg (18). Reroll shield3 và heal2 (Nhiệt 1, an toàn): 58% ra thêm ít nhất 1 dmg (tứ).
  Reroll lần 2 chỉ viên còn thiếu (Nhiệt 2, bắt đầu 20% Vỡ mỗi viên). Đây là quyết định kiểu King of Tokyo.
- Quyết định: reroll mấy lần, tập con nào, dừng lúc nào. Có thể bỏ cả viên đang tốt để chase.
- Vì sao bừa thua: bừa reroll hết hoặc không reroll. Reroll hết thì Vỡ nhiều và phá Bộ, không reroll thì không ra Bộ lớn.
  Người giỏi tính xác suất, dừng đúng lúc.
- Chi phí M. Replay: CÓ. Mỗi lần reroll là action mới (tập con viên) vào ActionLog; RNG phải lấy từ luồng con xác định
  theo (run seed, lượt, lần reroll). Worker: CÓ, server tung từng lần reroll, và Vỡ cũng do server quyết (không để client
  tự roll).

### M6. Khoá-tích (Hold có giá trị tăng)
Hold sửa lại: giữ 1 viên (tối đa 1, Lõi có thể thêm) sang lượt sau, KHÔNG dùng viên đó lượt này. Lượt sau viên đó giữ
nguyên mặt, bonus Tích +1 mỗi lượt giữ (x1.25 mỗi Tích, tối đa 2 Tích = x1.5), và lượt đó chỉ tung 4 viên còn lại. Viên giữ
được tính vào Bộ như bình thường nên là "mỏ neo".
- Ví dụ: tung ra dmg6 (mặt rất tốt) nhưng cần dùng 4 viên còn lại để đỡ boss. Giữ dmg6, lượt sau dmg6 x1.25 = 7.5, làm
  mỏ neo cho Bộ dmg mới.
- Quyết định: hy sinh sức mạnh hiện tại lấy sức mạnh sau. Bây giờ Hold làm tệ đi vì không có thưởng, đây là sửa đúng chỗ.
- Chi phí M. Replay: có (action Hold đã có, thêm trạng thái Tích). Worker: Tích nằm trong run state; kiểm run bằng replay.

### M7. Đổi mặt (kiểu Dice Forge)
Sau mỗi trận thắng hoặc ở node Shop, người chơi được thay 1 mặt của 1 viên bằng một mặt khác (trong kho mặt của part hoặc
mặt đặc biệt). Mặt đặc biệt chính: "Mặt Hoà" đếm như BẤT KỲ loại nào cho Bộ, nhưng giá trị thấp. Đổi mặt là cách xây
đội cho Bộ (nhiều dmg thì dễ ba/tứ dmg).
- Quyết định: xây deck mặt đồng nhất (Bộ dễ, đơn điệu) hay đa dạng (linh hoạt, Bộ khó).
- Chi phí L. Mặt phải là dữ liệu của run (không sửa part gốc). Replay: CÓ (action đổi mặt, và run state chứa bản mặt).
  Worker: CÓ (state mặt cần lưu cùng run, qua SaveStore). Đụng part-tier-system. Để sau, không vào bản đầu.

### M8. Nóng / Lạnh (trạng thái viên)
Viên dùng cùng LOẠI hai lượt liền thành "Nóng": +25%/lượt liên tiếp (tối đa +75%). Đổi loại thì Nguội. Viên bị Vỡ (M5) thì
"Lạnh": lượt sau mặt của viên đó bị ép lấy thấp hơn trong hai lần tung.
- Quyết định: lập kế hoạch qua nhiều lượt (giữ một viên là dmg liên tục) so với linh hoạt theo từng lượt.
- Vì sao bừa thua: bừa đổi loại mỗi lượt, không bao giờ Nóng; Vỡ liên tục thì Lạnh liên tục.
- Chi phí M. Replay: không (trạng thái suy ra từ log). Worker: như M1. Rủi ro: thêm một thứ để nhớ. Nên để sau M1/M5.

### M9. Mặt Tạm (mana mua Bộ)
Trả 2 mana: biến 1 viên bất kỳ thành "Mặt Hoà" trong lượt (đếm là loại cần cho Bộ). Mana có giá trị: mua độ chắc chắn.
Overcast (làm riêng) cũng gắn vào Bộ: Overcast một viên đang ở trong Bộ thì phần thưởng Bộ của viên đó tính gấp đôi.
- Ví dụ: Tung ra dmg4 dmg3 shield3 shield2 heal2 (chỉ có đôi). Trả 2 mana đổi heal2 thành Mặt Hoà làm dmg: thành Ba
  dmg. Trả thêm mana thì ngũ.
- Quyết định: dành mana cho Mặt Tạm, Overcast, hay Nạp khác. Hết nghĩa "mana vô nghĩa".
- Chi phí S-M (phụ thuộc bản Overcast). Replay: CÓ (action dùng mana đổi mặt). Worker: server xác nhận đủ mana.

### M10. Cược (khai báo Bộ trước lần reroll cuối)
Trước lần reroll cuối cùng, người chơi có thể khai báo "Bộ mục tiêu" (vd Ba dmg). Nếu đạt thì Bộ nhân thêm x1.5. Nếu
không đạt thì Bộ nhân bị trừ (x0.75 cho mọi viên). Thưởng cho người đọc xác suất, phạt người cược bừa.
- Ví dụ: đang có Ba dmg, cược Tứ dmg trước lần reroll cuối. 58% đạt (Tứ x2.0 x1.5 = x3.0), 42% mất (x1.5 x0.75 =
  x1.1).
- Quyết định: biết mình có đang ở vị trí tốt không, cược hay ăn chắc.
- Chi phí M. Replay: CÓ (action cược). Worker: CÓ, server so Bộ khai báo với kết quả (client không tự tính).

### M11. Cộng trước, nhân sau (thứ tự dùng)
Mỗi viên có hai nhóm hiệu ứng: CỘNG (buff +dmg, +khiên cho viên khác) và NHÂN (Bộ). Viên buff dùng TRƯỚC thì cộng vào giá
trị gốc rồi mới nhân Bộ; dùng sau thì không được nhân. Kiểu Balatro.
- Ví dụ: Ba dmg x1.5, và có buff +2 dmg. Dùng buff trước: (4+3+5+2x3 viên) x 1.5; dùng buff sau: chỉ cộng thô.
- Quyết định: thứ tự dùng 5 viên có ý nghĩa tính toán thật (hiện gần như không).
- Chi phí S-M. Replay: không đổi log. Worker: như M1. Lưu ý: thứ tự có thể xung đột với sảnh (M2), cần luật ưu tiên.

### M12. Phối hợp hàng (trước/sau)
Bộ có đủ viên ở CẢ hàng trước và hàng sau thì +20% hệ số Bộ, vì hai hàng "phối hợp". Bộ toàn một hàng không có.
- Quyết định: đội hình cho Bộ, không chỉ cho phòng thủ.
- Chi phí S. Replay: không. Worker: như M1.

## 2. Đề xuất "hệ lõi": BỘ + LIỀU + MẶT TẠM (M1 + M5 + M9, kèm M6)

Ba cơ chế này không phải danh sách rời, mỗi cái khoá cái kia vào quyết định thật:

- BỘ (M1) cho mục tiêu: sau lần tung đầu, người chơi có thứ để đuổi (ba/tứ x1.5-x2.0). Không có Bộ thì reroll chẳng có
  lý do tồn tại, đó chính là lý do "reroll vô ích" bây giờ.
- LIỀU (M5) cho cách đuổi, và cho RỦI RO: Nhiệt tăng nhân nhưng bắt đầu Vỡ. Không có rủi ro thì reroll hết là tối ưu
  (đã nhàm). Có Vỡ thì người chơi phải dừng.
- MẶT TẠM (M9) cho cách ăn chắc bằng mana: mana mua lại độ chắc chắn khi sắp Vỡ. Mana từ vô nghĩa thành tài nguyên
  cạnh tranh với Overcast.
- Khoá-tích (M6) làm Hold có giá thật, nối nhiều lượt: giữ mặt tốt làm mỏ neo cho Bộ lượt sau.

Nhân chiều sâu cho các thứ đã có:
- Vị trí: đội hình quyết định loại và class có sẵn trong đội, tức xác suất Bộ nào dễ ra (và M12 nếu chọn).
- Lõi: Lõi hiện có (49) thành "ngọc phụ" đổi một biến của Bộ/Nhiệt/Mana (mục 3).
- Giáp/Khiên/Hồi: giữ lại đúng 1 shield để sống cũng là chi phí cơ hội khi đuổi Bộ dmg.
- Nhịp boss: boss có lượt phá giáp, lượt burst cần Bộ lớn, người tính trước thì giữ Hold-tích cho đúng lượt.

Một lượt ví dụ đủ 5 viên: Beast(trước) dmg4, Plant(trước) dmg3, Aquatic(sau) shield3, Bird(sau) dmg5, Bug(sau) heal2.
Mana 3. Địch boss sắp đánh nặng.
1. Có Ba dmg (4,3,5) = 18 thay vì 12. Chưa cần gì cũng khá.
2. Boss sắp đánh 14: cần khiên. Giữ shield3, reroll chỉ heal2 (Nhiệt 1, không Vỡ): 35% ra dmg thành Tứ (x2.0).
3. Hoặc liều: reroll cả shield3 + heal2 (Nhiệt 2, mỗi viên 20% Vỡ): xác suất ra ít nhất 1 dmg 58%, nhưng 36% có ít nhất
   1 viên Vỡ và mất khiên.
4. Hoặc trả 2 mana Mặt Tạm biến heal2 thành dmg: chắc chắn Tứ dmg, giữ shield3, nhưng còn 1 mana, không đủ Overcast.
Bốn nhánh, mỗi nhánh có lý. Bừa "dùng hết" chỉ ra nhánh 1 với kết quả thấp nhất.

Vì sao không phạt bằng quái: không có quái nào đổi hành vi theo người chơi. Khó hơn đến từ (a) HP/dmg quái nền cao hơn,
(b) đáy sức mạnh của người chơi bừa thấp hơn bản cũ vì hết "dùng hết = tối ưu", (c) trần của người chơi giỏi cao hơn
bản cũ vì Bộ. Tức thưởng người giỏi và hạ người bừa.

[Reviewer sửa] Liam muốn CẢ BA bot đều thua nhiều hơn, kể cả Expert. Bộ nâng trần nên quái nền phải bù nhiều hơn phần Bộ
cho thêm, không phải +15% cố định. Cách chỉnh: chốt hệ số Bộ trước, đo Expert, rồi tăng HP/dmg quái nền tới khi Expert
về 18-23%. Điểm bắt đầu +25%, quét 15-35%. Nếu giữ Bộ theo LOẠI (mục 0b) thì hệ số Bộ phải hạ mạnh (ba x1.2, tứ x1.4,
ngũ x1.8) và có thể phải hạ giá trị mặt nền, nếu không thì quái +35% vẫn không đủ.

## 3. Lõi chủ (chọn 1 trong 3 lúc bắt đầu run)

Mỗi Lõi chủ sửa một "luật chính" của hệ lõi. Số là điểm khởi đầu để sim chỉnh. Cột "ngọc phụ hợp" là NHÓM Lõi hiện có
(tôi chưa đối chiếu tên 49 Lõi cụ thể, việc đó làm khi sim đã chạy):

| # | Lõi chủ | Luật chính (số) | Ngọc phụ hợp |
|---|---|---|---|
| 1 | Tam Tấu | Mỗi Bộ ba+ nổ AoE bằng 50% tổng giá trị các viên trong Bộ (tứ 100%). Đôi không nhân. | Lõi AoE, thorn, poison (nổ rồi lan) |
| 2 | Con Bạc | Nhiệt tối đa 5 (thay vì 3), mỗi Nhiệt +20% hệ số Bộ, nhưng Vỡ 25% từ Nhiệt 3. | Lõi reroll, giáp/khiên (đỡ khi Vỡ), heal |
| 3 | Cầu Thang | Sảnh 3+ dùng đúng thứ tự thì +35%/bước thay vì +25% và các viên sảnh miễn Plating địch. | Lõi buff/debuff (viên số liền kề), Charge |
| 4 | Mỏ Mana | Mỗi Bộ ba+ +1 mana, Mặt Tạm chỉ tốn 1 mana (thay vì 2); Overcast trong Bộ nhân x2.5 thay vì x2. Hồi mana nền -1. | Lõi mana, Overcast, summon |
| 5 | Đồng Tộc | Đồng tộc (M3) cần 2 viên (thay vì 3), passive class x2.5; Bộ ba+ khác class không nhân. | Lõi class/Huyết Thống (đồng class) |
| 6 | Giữ Lửa | Giữ 2 viên (thay vì 1), Tích tối đa 3 (x1.75). Viên giữ nổ khi dùng: +50% thêm. | Lõi Hold, Đòn Nạp, Hồi Ngắt (đúng lượt boss) |
| 7 | Thợ Rèn Mặt | Mỗi trận thắng được thay 1 mặt (M7), Mặt Hoà xuất hiện sẵn 1 viên. Bộ ba+ có Mặt Hoà thêm +0.25. | Lõi đổi mặt, class (xây loại duy nhất) |

Ghi chú:
- #7 Thợ Rèn Mặt cần M7 (cỡ L). Bản đầu có thể chỉ gồm #1-#6 (6 Lõi) và thêm #7 khi M7 xong.
- 3 cái tôi cho là hay nhất: #2 Con Bạc (khoảnh khắc kịch tính nhất, hợp kiểu gacha/vui), #1 Tam Tấu (đọc dễ, hợp "vui khi
  ra combo", AoE kéo 49 Lõi hiện có), #6 Giữ Lửa (kế hoạch nhiều lượt, đúng nhịp boss).
- Lõi chủ không cho thêm sức mạnh trần, chỉ ĐỔI luật. Tránh biến thành "+X% dmg" mà Liam chê.
- Cần tránh: Lõi chủ nào mà người giỏi chọn, bot cũng chọn một Lõi tốt nhất (dominant). Chỉ tiêu ở mục 4.

## 4. Đo bằng sim

Bot cần học:
- Random: dùng bừa, reroll bừa.
- Spam (hiện có): dùng hết mọi viên, không reroll.
- Greedy-Bộ: sau tung tính Bộ lớn nhất hiện có, giữ lại, reroll phần còn lại một lần.
- Expert: expectimax 1 bước trên 2^5 tập con để reroll (chọn tập con tối đa hoá giá trị kỳ vọng sau khi trừ rủi ro Vỡ), biết
  dừng ở Nhiệt hợp lý, biết dùng Mặt Tạm và Overcast, chọn thứ tự dùng (M11), chọn Hold, chọn Lõi chủ trong 3.
  Không cần Expert là hoàn hảo, chỉ cần "người chơi giỏi thật" tới đâu thì đo được.
- Mỗi Lõi chủ chạy cả 4 bot, 2000 run mỗi bot, cùng seed.

Chỉ tiêu (so với bản cũ: random 20.6, spam 22.8, expert 28.6):
- Random thắng <= 10% (giảm hơn 10 điểm so với 20.6).
- Spam thắng <= 12% (giảm hơn 10 điểm so với 22.8).
- Expert thắng 18-23% (thấp hơn 28.6 từ 5-10 điểm, đúng yêu cầu Liam 22/10). [Reviewer sửa: bản trước ghi 25-30%,
  tức giữ ngang bản cũ, trái yêu cầu.]
- Expert - Random >= 12 điểm, nhắm 15 (bản cũ chỉ 8). Nếu Expert 18% thì Random phải <= 6%.
- Thứ tự chỉnh: (1) hệ số Bộ + luật Liều, (2) quái nền tới khi Expert vào 18-23, (3) nếu Random/Spam vẫn cao thì hạ
  đáy (bớt hồi/khiên nền), KHÔNG hạ Expert thêm.
- Tỷ lệ lượt Expert chọn khác Greedy/Spam >= 60% (đo "lượt có quyết định thật").
- Ít nhất 40% run Random chết ở act 1-2 (bừa thua rõ).
- Tỷ lệ boss cuối r18: Expert thấy rõ hơn Random (bản cũ boss cuối lấy nửa số run mọi bot).
- Mỗi Lõi chủ có tỉ lệ chọn 10-25% (không dominant) và chênh winrate giữa các Lõi chủ <= 5 điểm.
- Số lựa chọn "hợp lý" mỗi lượt (không bị trội hoàn toàn) từ 3-8. Nếu >8 thì rối, nếu <3 thì nhàm.
- Lõi combo hiện có: đo lại bằng Expert (câu hỏi 4 của reviewer chưa có lời đáp).

Lưu ý đo: M5 reroll cần luồng RNG con, sim phải dùng cùng cách tách seed như engine để replay khớp.

## 5. Câu hỏi cho Liam (reviewer viết lại 20/10)

1. Bộ tính theo gì? (a) cùng SLOT, tức cùng số mặt 1-6: ba+ ~21% lần tung đầu, Bộ có cả khiên/hồi/độc, Sảnh làm được.
   (b) cùng LOẠI như bản đầu: ba dmg 50-79% ngay lần đầu, gần như lượt nào cũng có, game dễ đi.
   Khuyến nghị: (a).
2. Reroll: (a) giữ khung bây giờ: 1 lần miễn phí an toàn, lần 2-3 thì chọn: liều miễn phí (có Vỡ) hoặc trả 2 mana để an
   toàn. Mana mua độ chắc, Mặt Tạm gộp luôn vào đây. (b) 3 lần miễn phí, bỏ mana như bản đầu.
   Khuyến nghị: (a), vừa khó hơn vừa giữ mana có nghĩa.
3. Bump này chỉ gồm Bộ + Liều + Overcast + 5 Lõi chủ (Tam Tấu, Con Bạc, Mỏ Mana, Đồng Tộc, Giữ Lửa)? Khoá-tích chỉ có
   trong Lõi Giữ Lửa; Sảnh, Đổi mặt, Cược để bump sau. Người mới mở dần: run đầu chỉ có Bộ + reroll, Nhiệt/Vỡ mở sau
   boss act 1 đầu tiên, Lõi chủ mở từ run thứ 3. Khuyến nghị: đồng ý.
4. Độ khó: chỉ tiêu random <= 10%, spam <= 12%, expert 18-23%, gap >= 12. Quái nền bắt đầu +25%, quét 15-35% cho tới khi
   Expert vào khoảng đó. Chốt? Khuyến nghị: chốt.

## 6. Việc cần kiểm trong code trước khi sim (chưa làm)

- Mặt có "số" 1-6 hay chỉ loại + giá trị (quyết định M2).
- Chỗ sinh RNG của reroll hiện tại và cách ActionLog ghi (M5, M9, M10 cần action mới).
- Worker có chạy bản luật để verify run, hay chỉ server-roll xúc xắc (quyết định cột Worker ở trên).
- [Reviewer] Đã kiểm dòng 1 (xem 0b). Còn dòng 2-3.

## Ghi chú reviewer (creative-director, 20/10)

Verdict: CẦN SỬA trước khi sim. Hướng đúng (Bộ cho mục tiêu, Liều cho rủi ro, mana mua độ chắc), nhưng luật Bộ theo
loại làm game dễ đi, và chỉ tiêu Expert trái yêu cầu Liam. Hai chỗ đó đã sửa ở mục 0b, 2, 4, 5.

Bất đồng với bản đầu:

1. Bộ theo LOẠI. Không đồng ý, lý do ở 0b: data cho thấy dmg chiếm 2/6 tới 4/6 mặt của mọi viên, nên ba dmg không phải
   thứ để đuổi mà là mặc định. Bộ theo SLOT giữ được đúng cảm giác "chase" mà người viết muốn (xác suất 5d6 trong bản
   đầu hoá ra đúng cho slot).
2. Quá nhiều thứ cho một bump. Bản đầu cộng: Bộ, Nhiệt, Vỡ, Mặt Tạm, Overcast, Tích, Hold, hàng, Giáp, Lõi chủ, 49 Lõi
   phụ. Người mới phải nhớ ~6 luật mới trong một lượt. Gọt:
   - Bắt buộc bump này: Bộ (theo slot), Liều (Nhiệt + Vỡ, lần 1 an toàn), Overcast, Lõi chủ.
   - Gộp: Mặt Tạm vào "reroll an toàn trả mana". Một hành động mana thay vì hai, cùng ý nghĩa "mua độ chắc".
   - Chỉ nằm trong Lõi chủ: Khoá-tích (Giữ Lửa). Hold nền giữ như bây giờ.
   - Để sau: M2 Sảnh, M3/M12 thưởng đội hình, M4, M7, M8, M10, M11.
   - Mở dần: dùng cờ Newcomer đã có trong `combat_engine.gd`. Run 1-2: Bộ + reroll. Nhiệt/Vỡ mở sau boss act 1 đầu tiên.
     Lõi chủ mở từ run 3. Ascension sau thêm Sảnh hoặc Cược như luật mới, không như +HP.
3. Liều 3 lần miễn phí. Với 3 lần miễn phí, lối "reroll tới khi ra Bộ" sẽ trội vì Vỡ chỉ chạm viên đang bị reroll (viên
   đó vốn không có giá trị với mình). Kỳ vọng vẫn dương ở lần 3. Nên giới hạn: lần 1 an toàn, lần 2-3 chọn liều hoặc trả
   mana. Bot Expert phải cho thấy có lượt dừng ở lần 1 (đo: >= 30% lượt Expert không dùng lần 2).
4. Vỡ = mặt trống. Mất hẳn một viên là chỗ người chơi thấy bị cướp nhất. Đổi thành "Nứt": viên giữ loại, giá trị còn một
   nửa, không vào Bộ. Vẫn đau, nhưng không về 0. Thêm: % Vỡ hiện trên nút trước khi bấm, Vỡ do server tung, và viên
   KHÔNG bị reroll thì không bao giờ Vỡ (ghi rõ trong luật, bản đầu chữ "phá Bộ nếu có" dễ hiểu nhầm). "Gacha vui" nên
   nằm ở khoảnh khắc ra Bộ (hiệu ứng, âm thanh, chữ "Ba Sừng!"), không nằm ở hình phạt.
5. 7 Lõi chủ:
   - #3 Cầu Thang chết ở bump này (Sảnh chưa có). Bỏ, quay lại khi làm Sảnh theo slot.
   - #7 Thợ Rèn Mặt cần M7 (cỡ L). Để sau.
   - #4 Mỏ Mana có vòng lặp: Mặt Tạm 1 mana tạo Bộ, Bộ trả lại 1 mana, tức Bộ miễn phí mỗi lượt. Nếu gộp Mặt Tạm vào
     reroll an toàn thì sửa thành: reroll an toàn 1 mana thay vì 2, Overcast trong Bộ x2.5, mana nền -1, và +1 mana khi
     ra Bộ chỉ 1 lần/lượt, không tính Bộ có viên vừa trả mana.
   - #1 Tam Tấu: theo luật loại thì gần như lượt nào cũng nổ AoE 50%, trội ở trận nhiều quái. Theo luật slot thì ổn.
     Vẫn nên bắt đầu 35% (tứ 70%) rồi sim.
   - #5 Đồng Tộc: với đội thuần class, 2 viên là gần như luôn đủ, passive x2.5 có thể trội. Bắt đầu x2. Và đụng Core
     Concord hiện có (cùng class ra cùng face index): theo luật slot thì Concord + đội thuần = Bộ chắc chắn mỗi lượt.
     Phải cấm Concord đi với Bộ, hoặc Concord không tính vào Bộ.
   - #2 Con Bạc là cái "gacha vui" nhất, giữ. Trần Nhiệt +100% có thể quá cao, sim xem chênh Expert-Random của riêng nó.
   - #6 Giữ Lửa có lẽ yếu ở act 1 (bỏ nhịp hiện tại) và mạnh ở boss. Chấp nhận được, miễn tỉ lệ chọn >= 10%.
   - Bump này còn 5 Lõi chủ, mỗi run cho chọn 1 trong 3.
6. Chỉ tiêu "3-8 lựa chọn hợp lý mỗi lượt" chưa đo được bằng bot hiện có (cần định nghĩa "trội hoàn toàn"). Bỏ ở vòng
   sim đầu, dựa vào chỉ tiêu "Expert chọn khác Greedy/Spam >= 60%" đã có.

## Liam trả lời (22/10), đã chốt
Duyệt hướng BỘ + LIỀU + MẶT TẠM. Yêu cầu: làm hiệu quả, DỄ HIỂU, thân thiện với người chơi, không phức tạp khiến người chơi bỏ cuộc; đặc biệt cẩn thận không gây bug / lỗ hổng luật — QA kỹ. 4 câu mục 5 theo khuyến nghị (BỘ theo part; reroll lần 1 an toàn, lần 2-3 liều hoặc trả mana; bump này BỘ + LIỀU + MẶT TẠM + Overcast + 5 Lõi chủ, mở dần cho người mới; quái nền +25% rồi chỉnh bằng sim) trừ khi Liam đổi.
Quy trình: GDD `design/gdd/dice-depth-v4.md` → QA lead soi lỗ hổng + ma trận test TRƯỚC khi code → làm → review độc lập + smoke luồng thật.
