# Brainstorm: làm game sâu hơn (20/10/2026)

Trạng thái: BRAINSTORM, chờ Liam chọn hướng. Chưa sửa code, chưa sửa GDD nào. Sau khi Liam chọn thì mới viết plan.

Cách đọc: mục 1 là chẩn đoán, mục 2 là chuyện BLANK, mục 3 là kho ý tưởng theo 5 trục, mục 4 là 3 gói, mục 5 là câu hỏi cho Liam. Nếu chỉ có 5 phút: đọc mục 4 và 5.

## 0. Những thứ đã chốt, đề xuất nào cũng phải đứng trong khung này

Lấy từ `production/session-state/active.md` (mục "Tầm nhìn") và `ascension-v2.md`:

- Intent địch luôn công khai (pillar minh bạch). Không ý nào dưới đây giấu thông tin.
- Hồi đầy HP mỗi trận, không camp, không mang HP sang trận sau. Vì vậy tôi không đề xuất HP carry, dù `core-loop-v2.md` mục 5.6 từng đề xuất.
- Không "trait khắc chế" gắn lên địch kiểu Cleanse/Drench/Plated (Liam đã bỏ ở `core-loop-v2.md` mục 5.5). Chiều sâu phải đến từ chỗ khác: cách xúc xắc tương tác với nhau, nhịp của boss, quyết định trên map.
- Ascension A1-A10 đã có bản v2 (`ascension-v2.md`), Nhiệm vụ đã có bản riêng. Tôi không đề xuất lại, chỉ coi chúng là một phần của lần bump chung.
- Một lần bump RULES_VERSION cho mọi thay đổi luật (backlog mục B). Có kèm Worker `SUPPORTED_RULE_VERSIONS` + deploy, phải hỏi Liam trước.

Một chỗ lệch tôi thấy cần Liam biết (không phải do đề xuất này gây ra): `build-spec.md` INV-6 vẫn ghi "không có đường nào từ tiền thật sang sức mạnh", trong khi hướng 11/10 là bán giải pháp dùng được cả ranked, và code đã có Aid (`combat_engine.gd` có tham số `from_aid` ở `reroll_dice`, `boss clock` có thể lùi bằng Aid). Mọi đề xuất dưới đây không đụng INV-6, nhưng chữ của INV-6 đang cũ so với hướng đã chốt. Nên sửa chữ khi tới lượt (câu hỏi 9).

## 1. Chẩn đoán: nông ở đâu

Tôi chưa có số win-rate (sim F chưa chạy, backlog mục 13), nên đây là chẩn đoán từ luật và code, không phải từ dữ liệu chơi. Chỗ nào chưa kiểm tôi ghi rõ.

**1.1 Một lượt gần như không có tương tác giữa các xúc xắc.**
Luật hiện tại: 5 Axie, mỗi con 1 viên, roll 1 mặt, reroll tối đa 2 charge chọn từng viên, rồi gán mỗi mặt vào một mục tiêu (`godot-port-rule-spec.md` §2). Liên kết duy nhất giữa hai viên là Formation Resonance: hai Axie liền kề cùng loại mặt thì viên sau ×1.15 (`combat_engine.gd:34-35`). Mức thưởng nhỏ và gần như luôn tự xảy ra nếu đội có nhiều mặt dmg. Kết quả: mỗi lượt là 5 bài toán nhỏ độc lập "mặt này đánh ai", không có bài toán lớn "tổ hợp 5 mặt này thế nào". Chính `bloodline-system.md` §4 cũng tự chẩn đoán đúng như vậy ("decision density thấp hơn tiềm năng"), và Chain/Combo mà nó thiết kế chưa hề vào code: grep `combat_engine.gd` chỉ thấy keyword `chain:N` (dòng 1163), không có luật Bloodchain.

**1.2 Reroll là công cụ sửa sai, không phải công cụ theo đuổi.**
Base 2 charge cố định (`combat_engine.gd:52, 207`), nạp lại đầu lượt (dòng 1426). Không có thứ gì đáng "săn" bằng reroll, vì không có tổ hợp mặt nào thưởng thêm. Người chơi reroll mặt xấu rồi thôi. Có hai nguồn reroll thêm: keyword `rerollup` (+1, `combat_engine.gd:1287`, có trên 35 mục trong `part_faces.json`, chủ yếu mặt ears) và passive Aqua 4 mana đổi 1 reroll (`_grant_conduit_rerolls`). Cả hai chỉ cho thêm lượt sửa sai, không tạo mục tiêu để săn.

**1.3 Các viên xúc xắc giống nhau về khung.**
Slot cố định kiểu mặt (`rule-spec` §7): mouth dmg, horn dmg, back shield, tail dmg/poison, eyes heal/debuff, ears mana cantrip. Một viên bất kỳ hầu như luôn là ~2-3 dmg + 1 shield + 1 tiện ích + 1 mana. Đếm thô trong `part_faces.json` (grep trường `t`): dmg chiếm hơn một nửa số template, shield/mana mỗi loại khoảng 30-35, heal và debuff khoảng 20, poison khoảng 15, summon 3, buff đúng 1. Đội 5 Axie khác nhau vẫn cho ra 5 viên cùng một hình dạng, chỉ khác số và keyword. Đây là lý do "build trội hẳn" khó xuất hiện (khó có kiểu chơi khác nhau thật), nhưng cũng là lý do thiếu chiều sâu.

**1.4 Quái thường khác nhau ít. Boss có cơ chế nhưng đều là "chỉ số + một passive".**
Quái thường: 22 role trong `ContentDB.gd`, nhưng role chỉ ảnh hưởng chọn mục tiêu: assassin nhắm yếu nhất, bruiser 50% nhắm khoẻ nhất, mặc định random (`combat_engine.gd:518-528`). Người chơi không phải đổi cách đánh giữa các loại quái. Boss: cả 6 đã có trait chạy thật (`ContentDB.gd:485-491`, `t_boss_encounters`), có boss clock/attrition/spike (`combat_engine.gd:1601+`), tốt. Nhưng bộ xúc xắc boss lại cùng khung với xúc xắc phe mình (3-4 dmg, 1 shield, 1 heal/debuff), và trait chỉ là một lớp phủ: Mecha có Thorns + OVERDRIVE mỗi 3 lượt, Frost Lord đóng băng 1 viên. Chưa có boss nào buộc người chơi đổi kế hoạch trong trận (ví dụ chờ cửa sổ, giữ burst).

**1.4b Điểm sáng cần giữ.** Mecha OVERDRIVE mỗi 3 lượt là nhịp công khai; Agony hai pha; Mirror copy mặt mạnh nhất. Đây là hạt giống tốt: chỉ cần nhiều đòn kiểu "nhịp có thể đọc được" hơn.

**1.5 Map có hình dạng, nhưng quyết định chưa có giá.**
Graph rộng tối đa 3 cột (`run_map_generator.gd:60`), 18 hàng (Short) / 30 hàng (Full), hàng boss và elite cố định (`:49-54`), các hàng còn lại là battle hoặc pool event/event/treasure/shop. Vì full-heal trước mỗi trận (rule-spec §1), và `pw` tăng 1 sau MỌI node xong bất kể loại (`RunState.gd:48`), chọn battle hay event không đổi độ khó về sau. Khác biệt chỉ là có đánh hay không và nhận reward gì, mà node không cho biết sẽ nhận reward loại gì, nên đi đường nào chủ yếu là cảm tính. Hệ quả đáng ngờ: treasure cho reward không cần đánh và tăng `pw` y như battle, nên nhiều khả năng đang trội battle thường (pool hàng tự do là `event, event, treasure` + shop, `run_map_generator.gd:276`). Chưa có số, cần sim.

**1.6 Thua là mất cả run, không có áp lực nào ở giữa.**
Thua 1 trận = hết run (rule-spec §8), nhưng giữa các trận thì mọi thứ reset. Tức là run là chuỗi trận độc lập, độ căng chỉ nằm ở chính từng trận và ở lúc chọn reward. Reward là chỗ quyết định xây đội chính (3 lựa chọn, tối đa 2 cùng archetype), khá ổn, nhưng không có chỗ nào để sửa chính xúc xắc chủ động (ngoài ngẫu nhiên từ reward).

**1.7 Tóm lại**
Game không "dễ", game thiếu chỗ cho tay nghề. Ba chỗ rõ nhất: (a) xúc xắc không nói chuyện với nhau, (b) reroll không có mục tiêu, (c) quái và boss ít buộc đổi kế hoạch. Map và long-term là chuyện thứ hai.

## 2. Vấn đề mặt BLANK (backlog mục 9)

**Đã tìm ra (reviewer kiểm lại 20/10): đây là lỗi hiển thị ở màn Vault, không phải lỗi luật hay thiết kế part.**

- `axie_to_die.gd` đúng là chỉ đẻ blank ở 3 đường hiếm: không nạp được `part_faces.json` (dòng 351/367), Axie thiếu part (dòng 368-369), slot/class lạ không có template "A" (dòng 232-237). Part ngoài catalog đi `fallback_face`, vẫn ra mặt thật bậc C.
- Chỗ gây lỗi là `VaultView._build_die_strip()` (`godot/scenes/vault/VaultView.gd:442-445`). Hàm này đưa thẳng trường `t` của mặt vào `UI3.die_tile`, nhưng `UI3.FACE_TYPES` (`UI3.gd:43`) dùng tên UI `attack`/`weaken`, không có `dmg`/`debuff`. Không khớp thì hàm ép về `blank`, và ô blank in "–" (`UI3.gd:914`). Hàm đổi tên đúng `UI3.face_key()` (`UI3.gd:390`) đã có sẵn, Vault chỉ không gọi.
- Một Axie thường có mouth/horn/tail là `dmg`, nên ra đúng 3/6 ô "–" (4/6 nếu mắt là debuff). Khớp với mô tả trong backlog mục 9.
- Trong trận không bị: `MetaState._hero_def_from_vault()` đổi sang tên dài trước khi vào engine, và combat có đường hiển thị riêng.

Hệ quả: sửa 1 dòng ở `scenes/` (gọi `UI3.face_key`), không nằm trong fingerprint, **không cần bump RULES_VERSION**, nên làm ngay như bug fix, không chờ phase thiết kế. Các hướng "không bao giờ blank" hay "biến blank thành mặt Focus" không còn cần cho vấn đề này. Ý "Focus" chỉ đáng giữ như một ý riêng nếu Liam duyệt Hold (2a).

## 3. Các trục chiều sâu

Quy ước: **Chi phí** S (dưới 1 tuần công), M (1-3 tuần), L (hơn 3 tuần, cần sim lại). Đây là ước lượng thô để producer kiểm, không phải cam kết. **Luật** = có đụng file nằm trong fingerprint `t_rules_version` (`scripts/core/`, `autoload/`, `assets/data/rules/`, `part_faces.json`, relics) nên phải bump RULES_VERSION. **INV** = có chạm bất biến INV-1..7 nào của `build-spec.md`.

### Trục 1. Xây đội (part / bloodline / synergy)

**1a. Bond: ngưỡng đồng class kiểu TFT (nhẹ hơn Bloodchain đầy đủ).**
Mô tả: đội có 2/3/4 Axie cùng class thì mở bậc thưởng đội, cộng phẳng và có trần (vd. 2 Plant: shield đầu lượt +2 cho Axie đứng cuối; 4 Plant: thêm thorns đội). Không nhân, theo luật "cộng không nhân" đã rút ra từ bug poison wave 15 (`bloodline-system.md` §4.3 ràng buộc 1). Secret class (Dawn/Dusk/Mech) tính 0.5 cho cả hai class gốc theo ràng buộc 3 ở cùng mục.
Ví dụ một lượt: đội 3 Bird + 1 Bug + 1 Plant. Bird có 3, bật bậc 3: mặt pierce đầu tiên mỗi lượt +2. Người chơi cân nhắc nhặt Axie Bird thứ 4 hay giữ Plant để chống. Không còn là chọn "Axie mạnh nhất".
Độ sâu thêm: quyết định đa dạng-hay-chuyên-sâu ngay lúc chọn đội và lúc reward tier-up. Đây là loại "lý do từ chối một hero mạnh hơn" mà bloodline mục 4.2 muốn.
Chi phí: M. Rủi ro: hội tụ về mono-class (bloodline mục 9 #2 ghi đỏ), nên bậc cao phải đủ nhỏ và có đối trọng (hero khác class vẫn có Resonance). Luật: có (combat_engine, ContentDB, data/rules). INV: không chạm; không đổi ngân sách part nên INV-5 nguyên, nhưng phải kiểm lại cân bằng bằng sim.

**1b. Vị trí đội hình có tác dụng thật (trước/sau).**
Mô tả: 5 slot trong `roster` chia 2 hàng (trước 2, sau 3). Quái đánh đơn mục tiêu ưu tiên hàng trước; AoE/pierce/cleave bỏ qua hàng. Intent vẫn hiện đúng mục tiêu như bây giờ, nên pillar minh bạch không đổi. Hiện tại thứ tự `roster` chỉ quyết định Resonance (liền kề) và thứ tự ưu tiên của vài relic (rule-spec §4).
Ví dụ: đặt Plant (shield+2) ở trước, Aqua/Bird mỏng ở sau. Boss AoE của Plague Mother (poison aoe) bỏ qua hàng nên Plant không che được, buộc có Bug/Plant nghĩ lại.
Độ sâu: biến việc xếp đội (đang là ẩn số rẻ) thành quyết định chiến thuật, tăng giá trị mặt AoE/pierce một cách tự nhiên mà không cần trait khắc chế.
Chi phí: M (logic mục tiêu địch + UI vị trí ở màn combat đã vẽ xong theo UI-03, có thể phải sửa spec UI). Rủi ro: người chơi mới thấy rối; cần giải thích trong tutorial. Thay đổi dạng "hàng trước chắc chắn trúng" có thể làm AI assassin mất vai (nhắm yếu nhất). Luật: có (`_pick_enemy_intent`). INV: không.

**1c. Slot "Rune" cho mặt, chủ động gắn.**
Mô tả: mỗi hero có tối đa 1 slot rune; rune là keyword gắn thêm lên một mặt chọn trước run (vd. +pierce lên mặt shield). Hiện reward `rune` đã có nhưng gắn ngẫu nhiên vào mặt có sẵn theo reward. Ý này là cho người chơi chọn mặt nào, và cho phép đổi ở một node Forge (ý 4c).
Độ sâu: biểu đạt (SDT autonomy), tạo build "sửa chính xúc xắc" thay vì chỉ nhặt relic. Chi phí: M. Rủi ro: cần chặn tổ hợp keyword hỏng (trần nhân `mload`, `relicConflict`). Luật: có. INV: rune không đổi `partId` nên không chạm INV-3/4; không có gì đi vào bộ sưu tầm nên không chạm INV-1. Hạng mục này chỉ nên làm cùng 4c.

### Trục 2. Lựa chọn trong trận (reroll, giữ xúc xắc, combo mặt)

**2a. Giữ xúc xắc sang lượt sau ("Hold").**
Mô tả: mỗi lượt được giữ tối đa 1 viên chưa dùng; viên đó không dùng được lượt này, nhưng sang lượt sau nó giữ nguyên mặt (không roll lại). Không tính là hành động undo. Cần thêm một loại action trong action log.
Ví dụ: Mecha OVERDRIVE ở lượt 3. Lượt 2 người chơi thấy mặt shield 14 và giữ lại, lượt 3 mở bằng shield lớn thay vì đánh. Hoặc giữ mặt dmg 20 pierce chờ lúc Phase 2 của Agony.
Độ sâu: biến nhịp boss công khai thành bài toán lập kế hoạch, reroll cũng có chỗ để "tích". Đây là cách rẻ nhất tôi thấy để cho người chơi quyết định theo thời gian chứ không chỉ theo mặt hiện tại.
Chi phí: M. Rủi ro: xoắn với Cantrip, Frozen, replay (cần thêm action `hold` vào log và `RunVerifier`), có thể tạo chiến lược chỉ giữ-dồn mọi lượt nếu không có trần: giữ 1, và viên giữ không được giữ tiếp lượt thứ hai. Luật: có (combat_engine, action_log). INV: không.

**2b. Mana thành tiền tệ reroll chung.**
Mô tả: reroll gốc giảm còn 1 charge miễn phí; reroll thêm tốn Mana (mặt ears cho Mana). Giữ passive Aqua nhưng đổi thành giảm giá. Hiện mặt mana (~30 template) chủ yếu nuôi active relic, nhiều đội bỏ qua.
Ví dụ: người chơi có 4 Mana, chọn dùng 2 Mana reroll viên dmg yếu, hay để dành cho active relic. Mặt ears từ "mặt phụ" thành lựa chọn có giá.
Độ sâu: một tài nguyên chia sẻ giữa reroll và relic active, buộc cân nhắc. Chi phí: S-M. Rủi ro: đội ít mana bị bóp nghẹt, cần tuning kỹ (knob: giá reroll, số charge gốc). Cần sim vì đổi trực tiếp độ khó mọi trận. Luật: có. INV: không.

**2c. Gán mặt chồng lên một Axie (combo thật, mô hình (a) trong bloodline §4.1).**
Mô tả: cho phép dồn một mặt của Axie A vào Axie B để nhập thành combo trên B (B có thể nhận 2+ mặt cùng loại part). Đây là thay đổi mô hình, không phải hàm kiểm tra (bloodline §4.1 đã cảnh báo), và là cách duy nhất tôi thấy cho decision density tăng thật.
Ví dụ: 3 mặt Horn trong lượt, dồn cả vào Beast có exec để thành đòn kết liễu thay vì 3 đòn rời.
Độ sâu: cao nhất trong danh sách này. Chi phí: L (bloodline §4.4 ước 4-6 tuần, gồm UI và sim). Rủi ro cao: UI kéo-thả đang có cho click-click và drag; thêm "dồn" là bài toán UI mới; hội tụ mono-class; replay. Luật: có, nặng. INV: không chạm trực tiếp.

### Trục 3. Quái và boss có cơ chế riêng

**3a. Cửa sổ nhịp của boss (boss rhythm).**
Mô tả: mỗi boss có chu kỳ 3 lượt công khai hiện sẵn trên UI (đã có boss clock làm nền tảng): lượt 1 chuẩn bị, lượt 2 tấn công, lượt 3 hở. Chu kỳ khác nhau từng boss, không thiên về archetype nào. Mecha: sau OVERDRIVE là 1 lượt mất Thorns. Frost Lord: lượt đóng băng 2 viên thay vì 1 rồi 1 lượt nghỉ. Gooey King: sau mỗi lần split, boss gốc được +shield chờ phá. Phần việc chủ yếu là dữ liệu + mở rộng `_boss_turn_traits()`.
Ví dụ: Frost Lord báo "lượt sau đóng băng 2 viên". Người chơi chủ động dùng viên sắp bị đóng băng trước, và không reroll viên đó. Cùng ý 2a hay nhất khi có Hold.
Độ sâu: cho mỗi boss một cách đánh riêng, không cần trait khắc chế. Cũng là "ức chế" đúng hướng monetization 11/10: boss khó, người ta mua giải pháp (Aid lùi clock đã có, thêm Aid loại "xem trước nhịp" thì lệch pillar vì đã công khai, nên không cần).
Chi phí: M cho 6 boss (khung chung + 6 bộ dữ liệu, `t_boss_encounters` mở rộng). Rủi ro: tuning độ khó boss, sim. Luật: có. INV: không.

**3b. Affix công khai cho Elite (hiện trên node trước khi bước vào).**
Mô tả: mỗi Elite khi sinh map nhận 1 affix hiện sẵn trên node (vd. "Echo: lặp intent lượt sau", "Thief: lấy 1 Mana mỗi lượt", "Berserk: dmg +25% khi dưới 50% HP"). Affix đổi nhịp trận, không phải counter archetype. Phần thưởng tăng theo affix khó.
Ví dụ: trên map có 2 Elite ở hàng 9: một "Thief", một "Berserk". Đội mana-heavy né Thief, đội burst chọn Berserk để ăn thưởng lớn. Quyết định map có giá thật mà không cần HP carry.
Độ sâu: nối trục quái với trục map. Chi phí: M. Rủi ro: danh sách affix mà vô tình là counter (vd. Thief khắc CONDUIT) trái với quyết định "không trait khắc chế", nên Liam cần duyệt từng affix. Luật: có (map generator trong `scripts/core`, combat). INV: không.

**3c. Quái thường có hành vi theo role thật.**
Mô tả: nâng 22 role từ "chọn mục tiêu" thành một hành vi nhỏ mỗi role, hiện trên intent: healer che quái yếu, summoner sinh egg mỗi 2 lượt, buffer buff đồng đội. Một phần đã có trong rule-spec (healer, summoner), nên cần kiểm lại phần nào code thật sự đã làm trước khi ước lượng. Chưa kiểm.
Độ sâu: vừa phải. Chi phí: S-M tuỳ phần có sẵn. Luật: có. INV: không. Rủi ro thấp.

### Trục 4. Quyết định trên map run

**4a. Hiện loại reward trên node.**
Mô tả: lúc sinh map (có seed), mỗi node battle/elite gắn trước loại reward (relic / tier-up / mặt mới / shard lớn). Reward cụ thể vẫn roll sau trận. Ý này giữ nguyên full-heal và minh bạch.
Ví dụ: đội cần tier-up cho Plant đã thấy node ở hàng 7 có biểu tượng tier-up, đi đường đó dù phải qua Elite. Đường đi trở thành kế hoạch.
Độ sâu: nhanh, rẻ, tác động lớn vì cho quyết định map có thông tin. Chi phí: M (generator + UI node; UI-03 đã xong nên cần sửa spec map). Rủi ro: seed + replay (map gen nằm trong `scripts/core`, đã vào fingerprint); phải đảm bảo reward roll không đổi so với bản đã công bố. Luật: có. INV: INV-7 không đụng (không gate).

**4b. Node "Thử thách" tự chọn (opt-in).**
Mô tả: một số node battle có nút bật "Thử thách": +25% budget địch, đổi lại +1 bậc reward. Người chơi kiểm soát độ khó và rủi ro của chính mình, trong khi `pw` vẫn tăng như cũ.
Độ sâu: rủi ro tự chọn (không HP carry nhưng vẫn có stake). Chi phí: S-M. Rủi ro: cân bằng phần thưởng; người chơi giỏi luôn bật hết nên cần trần số lần. Luật: có (encounter budget, reward). INV: không.

**4c. Node "Phòng gene" (Forge) thay một số node treasure.**
Mô tả: trả 1 reward hoặc shard để chọn một mặt và: gắn rune (ý 1c), nâng bậc mặt, hoặc đổi mặt bằng Gene Mutation (luật hiện có, luôn hạ về Common theo INV-4). Là chỗ duy nhất người chơi trực tiếp sửa xúc xắc.
Chi phí: M. Rủi ro: INV-3/INV-4 phải giữ: Forge không được đổi `partId` ngoài đường Gene Mutation. Shard sink phải cân với faucet (economy-v2). Luật: có. INV: chạm INV-3, INV-4 (giữ nguyên, thêm test).

### Trục 5. Tiến triển dài hạn (Land / Ascension / Nhiệm vụ)

Ascension v2 và Nhiệm vụ đã có đề xuất riêng; ở đây chỉ nói thêm hai ý chưa có.

**5a. Mutator tuỳ chọn lúc tạo run.**
Mô tả: trước run chọn 0-2 mutator (vd. "Mono-class", "Không Shield", "Một viên reroll duy nhất", "Glass: HP -30%, dmg +20%"). Cộng XP/Shard theo độ khó, không cộng sức mạnh. Thay thế một phần vai trò Ascension cho người đã chơi nhiều.
Độ sâu: thay đổi cách chơi chứ không chỉ tăng số. Chi phí: M. Rủi ro: mỗi mutator là một luật mới cần test, và cần thêm trường vào header action log để server replay-verify. Luật: có. INV: INV-6 giữ (không cộng sức mạnh), INV-7 giữ (opt-in, không gate).

**5b. Mastery theo Axie (chỉ cosmetic/danh hiệu).**
Mô tả: mỗi Axie (hero hoặc Vault) tích điểm thông thạo qua các run, mở khung/danh hiệu, không mở sức mạnh. Hợp INV-6 và Land C6 (Land không cho sức mạnh combat).
Chi phí: M. Rủi ro: ít chiều sâu chiến đấu, chỉ giữ chân. Luật: không (ngoài run). INV: không. Làm sau.

## 4. Ba gói đề xuất

Mọi gói đều gom vào **một lần bump RULES_VERSION**, cùng với backlog mục B (comment "Mythic", trạng thái Ranked + câu "mất cọc"), Ascension v2 đã duyệt, và Worker `SUPPORTED_RULE_VERSIONS`. Sim F (backlog 13) phải chạy sau khi luật chốt, và với Gói Vừa/Lớn thì cần chạy trước khi bump, vì độ khó mọi trận đổi.

### Gói 1. Nhỏ, an toàn (~2-3 tuần)

Gồm: 2b mana-reroll · 3a cửa sổ nhịp boss · 4a hiện loại reward trên node.
- Giải quyết: chẩn đoán 1.2 (reroll có lý do), 1.4 (boss buộc đổi kế hoạch), 1.5 (map có thông tin).
- Không giải quyết: 1.1 và 1.3, xúc xắc vẫn không nói chuyện với nhau.
- Rủi ro: thấp, vì phần lớn là dữ liệu và UI. Sim cần chạy một vòng.
- Hợp monetization: boss khó hơn, Aid (đã có) bán được nhiều giá trị hơn.

### Gói 2. Vừa (~5-8 tuần), khuyến nghị

Gồm tất cả Gói 1, thêm: 2a Hold · 1a Bond · 1b hàng trước/sau · 3b affix Elite (và mặt "Focus" nếu Hold được duyệt).
- Giải quyết: cả bốn điểm của chẩn đoán 1.1-1.5. Hold + nhịp boss cho quyết định theo thời gian; Bond + hàng đội hình cho quyết định lúc xếp đội; affix Elite nối quái với map.
- Chưa có: combo thật trên một Axie (2c), Forge.
- Rủi ro: vừa. Bond và hàng trước/sau cùng đẩy về chuyên hoá, có thể làm một vài build trội, nên sim cần chạy theo archetype (mục tiêu `core-loop-v2` 5.2: không archetype nào thắng quá 60% hay dưới 35% ở A5). UI cần sửa ở combat (hiện hàng, hiện Hold, hiện Bond) và map (loại reward, affix), mà UI-03 đã coi như xong, nên phải xin Liam mở lại phạm vi UI.
- Lý do khuyến nghị: gói này chạm đủ ba nguyên nhân gốc mà không cần làm lại mô hình xúc xắc (2c). Mỗi ý chồng lên ý khác (Hold + nhịp boss; Bond + hàng trước/sau; affix + reward trên map), không có ý nào đứng một mình vô nghĩa. Phần nào quá nặng thì cắt được từng mảnh mà không phá cả gói.

### Gói 3. Lớn (~10-14 tuần)

Gồm tất cả Gói 2, thêm: 2c gán mặt chồng lên Axie (combo thật) + 1c rune chọn chủ động + 4c Forge + 4b Thử thách + 5a Mutator.
- Giải quyết: tất cả, kể cả decision density thật sự (1.1).
- Rủi ro: cao. 2c là đổi mô hình, `bloodline-system.md` §4.4 ước 4-6 tuần riêng nó. Sim và UI chiếm nhiều nhất. Có nguy cơ làm game phức tạp quá mức cho người chơi mới, đúng thứ tutorial hiện có phải chịu thêm. Ngoài ra Gói 3 chạm INV-3/INV-4 qua Forge.
- Khi nào chọn: nếu Liam muốn game khác hẳn về chiều sâu và chấp nhận phase này kéo dài, hoặc muốn làm 2c như một "mùa" riêng sau bản đầu.

Khuyến nghị của tôi: **Gói 2**, bắt đầu bằng việc chạy baseline sim (câu hỏi 2). 2c, Forge, Mutator để đợt sau. Nếu làm đợt sau thì sẽ phải bump RULES_VERSION lần thứ hai, trái với quyết định "một lần bump" hiện tại, nên đó là câu hỏi cho Liam (câu 7), không phải mặc định.

## 5. Câu hỏi cho Liam

1. **BLANK:** đã ra nguyên nhân (mục 2: Vault hiển thị sai tên loại mặt). Cho sửa ngay như bug fix riêng, không bump, không chờ phase này được không? Khuyến nghị: được.
2. **Sim baseline:** có chạy một đợt sim đo win-rate hiện tại (theo archetype và Ascension) trước khi lên plan không? Chẩn đoán trên chưa có số, và các mục tiêu "không archetype nào thắng trên 60%" cần mốc để so. Khuyến nghị: có, một lần, rồi mới chốt gói.
3. **Gói nào:** 1, 2, hay 3? Khuyến nghị: Gói 2.
4. **HP carry:** `core-loop-v2` từng đề xuất, Liam đã giữ full-heal. Xác nhận vẫn giữ, và nếu sau này đổi thì đổi luôn trong lần bump này hay không bao giờ? Khuyến nghị: giữ full-heal; chiều sâu map lấy từ 4a/3b.
5. **Trait khắc chế:** Liam đã bỏ trait địch khắc archetype. Affix Elite (3b) và nhịp boss (3a) không khắc archetype nhưng gần ranh giới. Liam có chấp nhận ranh giới đó, và sẽ duyệt từng affix một chứ? Khuyến nghị: chấp nhận, duyệt từng affix bằng một bảng ngắn.
6. **Phạm vi UI:** Gói 1 và 2 cần sửa UI combat và map đã duyệt ở UI-03 (hiện hàng, Hold, Bond, loại reward, affix). Mở lại UI-03 chỉ cho các thay đổi này được không? Khuyến nghị: được, mỗi thay đổi một spec nhỏ, không làm lại cả bộ.
7. **Một hay hai lần bump:** quyết định hiện tại là gom MỘT lần. Nếu chọn Gói 2 mà vẫn muốn 2c/Forge/Mutator về sau thì có hai cách: (a) giữ một bump, phần hoãn chờ tới khi có bump khác vì lý do khác; (b) chấp nhận bump thứ hai có kế hoạch, kèm deploy Worker lần nữa. Khuyến nghị: (b), vì chờ gom tới phase 10-14 tuần thì rủi ro hơn. Nhưng đây là đổi quyết định đã chốt, Liam chọn.
8. **Mặt "Focus":** chỉ còn là ý phụ của Hold (2a), không liên quan BLANK nữa. Khuyến nghị: quyết cùng 2a.
9. **INV-6:** `build-spec.md` INV-6 còn ghi "không có đường nào từ tiền thật sang sức mạnh" trong khi hướng 11/10 và code (Aid) đã khác. Cập nhật chữ của INV-6 (và `t_economy`/test CI nếu có kiểm nó) trong phase này hay để lại? Khuyến nghị: cập nhật chữ trong plan, vì mọi người đọc INV để biết cái gì cấm.
10. **Ưu tiên cảm giác:** Liam muốn sâu theo hướng nào nhất? (a) lập kế hoạch dài hơi (Hold, boss rhythm, map), (b) tổ hợp trong lượt (Bond, combo), (c) kiểm soát rủi ro tự chọn (Thử thách, Mutator). Khuyến nghị: (a) trước, vì rẻ nhất và hợp pillar minh bạch nhất.

## Ghi chú nguồn

Đã đọc: `production/backlog-after-b931.md`, `design/gdd/godot-port-rule-spec.md` §1-§11, `design/gdd/bloodline-system.md` §4, `build-spec.md` (INV-1..7), tiêu đề + kết luận `core-loop-v2.md` (§0, §1, §5), `ascension-v2.md` §0, `nhiem-vu-risk-to-earn.md` §0. Code đã grep: `axie_to_die.gd`, `combat_engine.gd` (reroll, resonance, boss traits, enemy intent), `ContentDB.gd` (boss), `run_map_generator.gd`, `part_faces.json` (đếm thô theo trường `t`), `MetaState.gd` (bug schema Vault). Tác giả chưa đọc `part-skill-identity.md` và `part-tier-system.md` ngoài tiêu đề; reviewer đã đọc phần Overview/Player Fantasy và bảng gán keyword §8, kết quả ở ghi chú 3-4 bên dưới.

## Ghi chú reviewer (creative-director, 20/10)

1. **Hold (2a) và mana-reroll (2b) đụng giao thức server tung xúc xắc, không chỉ RULES_VERSION.** Worker có danh sách action (`worker/src/run_core.js:22`), schema epoch reroll `(turn, k, source)` (`epoch_args.json:21`) và kiểm số reroll mỗi lượt (`run_core.js:82`). Hold cần action mới và đổi luật roll đầu lượt; 2b đổi cách đếm và nguồn reroll. Ước lượng M cho hai ý này nên cộng phần Worker + `RunVerifier`.
2. **2b là cần gạt monetization, không chỉ tuning.** Hạ reroll gốc xuống 1 thì Aid reroll trả tiền (`R2`, `aid_prices.js`) đáng giá hơn hẳn. Hợp hướng 11/10, nhưng nên để economy-designer định giá và Liam duyệt như một quyết định monetization, ghi rõ trong gói.
3. **Rune (1c) va với `part-skill-identity.md` §3.4b.** Die lai tạp (purity ≤2) bị thay keyword sắc bằng keyword thô, đó là "Breeding moment" của doc. Rune gắn `pierce` lên mặt bất kỳ sẽ xoá khác biệt này, và nằm ngoài bảng giá keyword F4. Nếu làm: rune phải trả giá theo F4 và không được trả lại keyword đã bị suppress.
4. **Bond (1a) chồng lên class passive và coherence.** Doc đã có F5 "class surcharge" để tính giá việc cộng dồn với passive, và §3.4b thưởng die thuần class. Bond thêm một lớp thưởng theo class mà không qua F5. Cần systems-designer kiểm trước khi đưa vào gói.
5. **Ý bị bỏ sót: mở rộng Resonance thành "keyword nối".** Resonance đã phụ thuộc thứ tự dùng và vị trí liền kề (`combat_engine.gd:1066-1089`), tức là đã có mầm tương tác giữa các viên. Thêm cặp khác loại (vd. dùng shield rồi dmg ở Axie kề bên thì dmg được cộng thêm) đánh thẳng vào 1.1 với chi phí M, không phải đổi mô hình như 2c. Đáng cân nhắc thay 1a trong Gói 2.
6. **Treasure:** xem 1.5. Nên thêm "treasure vs battle" vào mục tiêu đo của sim baseline (câu 2); nếu đúng là trội, 4a (reward trên node) sẽ càng làm rõ điều đó.
7. **Gói 2 có thể lạc quan.** 5 ý luật + Worker + mở lại UI combat/map trong 5-8 tuần là chặt. Nếu cần cắt, giữ trục lập kế hoạch (Hold + nhịp boss + reward trên node + affix Elite), để Bond/hàng trước-sau sau khi có sim.
