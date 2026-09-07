/* ============ AXIE DICE TACTICS v0.2 — DATA ============
   Face: {p:part, t:type, v:value, k:[keywords], r:rarity 0..4}
   rarity: 0 Common · 1 Rare · 2 Epic · 3 Legendary · 4 Mythic
   types: dmg shield heal mana poison buff debuff blank summon
   kw: cleave pierce aoe cantrip heavy growth decay vital lifesteal exec
       multi:N chain:N selfharm:N rerollup mana:N
       burn:N crit:N freeze stun blind:N weaken:N vulnerable:N thorns:N regen:N poison:N  */

const B  = {p:'blank',t:'blank',v:0,k:[],r:0};
const F  = (p,t,v,...k)=>({p,t,v,k,r:0});
const FR = (r,p,t,v,...k)=>({p,t,v,k,r});   /* face có rarity */

const RARITY = ['COMMON','RARE','EPIC','LEGENDARY','MYTHIC'];
/* 2026-09-04: giá relic trong shop, một bảng cho MỌI rarity (relic-system.md §11 mục 19, AC-21).
   Trước đó engine.js hardcode `[45,75,120,180][r.rar]||60` — rar 4 (MYTHIC) rơi vào fallback 60,
   RẺ HƠN cả RARE (75), nên bậc Mythic không thể tồn tại trong shop. Phải đơn điệu tăng. */
const RELIC_SHOP_COST = [45,75,120,180,260];
/* §7 E7 — số relic TRƯỚC bản mở rộng 44->94. Phải là hằng viết cứng, KHÔNG được dùng
   RELICS.length: mốc grandfather là "người chơi đã hoàn thành bộ sưu tập CŨ", và
   RELICS.length vừa đổi nên nó không còn trả lời được câu hỏi đó. */
const RELIC_COUNT_PRE_EXPANSION = 44;

/* ---- Hằng của hệ relic (relic-system.md §3.6/§3.7/§9, part-skill-identity.md K24) ----
   Mọi giá trị dưới đây là KNOB: designer chỉnh ở đây, không ai hardcode lại trong engine. */
const RELIC_MLOAD_CAP = 2;   /* K5 · §3.6 — tổng `mload` của relic đang giữ không được vượt số này */
const RELIC_CAP       = 10;  /* K6 · §3.6 — trần số relic một run được giữ */
const THORNS_CAP      = 8;   /* K24 · part-skill-identity.md E10b R-B — thorns KHÔNG decay, không
                                trần thì nó vô hạn theo số lượt và không giá hữu hạn nào đúng.
                                8 là no-op với mọi dice hero hiện tại (reptile3 cao nhất thorns:4) */
const IRONMAIDEN_CAP  = 7;   /* §6.7.4 — trần damage mỗi lượt của r_ironmaiden */
const GROWTH_KEEP_CAP = 3;   /* §6.7.2 — trần growth r_worldtree giữ qua các trận */

/* INV-5 (§3.12): thứ tự chạy modFace = [PHASE_RANK, rar, RELIC_INDEX], KHÔNG phải thứ tự nhặt.
   Ba pha đúng thứ tự toán học: thêm keyword -> cộng phẳng -> nhân. */
const MF_PHASE_RANK = {kw:0, add:1, mul:2};

/* §3.7 — keyword nào trên mặt party đã cấp sẵn luật của relic nào (nguồn thứ 2 của `ex`).
   `bastion: null` là CÓ Ý THỨC: nó cộng dồn với r_bastionplate, không phải dead draw. */
const KW_EX = {overflow:'overflow', plague:'plague', echo:'echoRule', bastion:null};
/* 2026-09-01: hợp nhất với style.css --r0..--r4 (trước đó là 2 bảng màu khác nhau
   cho cùng khái niệm rarity — phát hiện ở docs/review-2026-08-31.md mục art).
   style.css là nguồn sự thật; giá trị dưới đây COPY nguyên từ đó. Nếu đổi rarity
   color, sửa style.css trước rồi đồng bộ lại đây — không sửa ngược. */
const RAR_COL = ['#9aa4b2','#63b3ff','#b388ff','#ffc857','#ff5f8f'];

const CLASSES = ['plant','beast','aqua','reptile','bug','bird'];
/* 2026-09-01: aqua/reptile/bug/bird dịch hue ra khỏi vùng màu semantic gameplay
   (--shd/--man/--dmg/--deb, --r1..r4) — trước đó trùng gần như nguyên hue, vi phạm
   nguyên tắc "mỗi màu nói một điều" của UI_DESIGN_SYSTEM_v0.8.md. plant/beast giữ
   nguyên (không trùng). Xem docs/review-2026-08-31.md mục art. */
const CLASS_COLOR = {plant:'#6fc04a',beast:'#e0913a',aqua:'#2ec4b6',reptile:'#8a9a3a',bug:'#c74fd8',bird:'#5c6bc0'};

/* ================= CLASS PASSIVE = ARCHETYPE ENGINE ================= */
const PASSIVE = {
  plant:  {n:'BULWARK',  a:'shield', d:'Every Shield you create is increased by 2. An Axie with 10 or more Shield gains Thorns 2.'},
  beast:  {n:'FERAL',    a:'exec',   d:'Attacks against a target below 50% HP deal 60% more damage.'},
  aqua:   {n:'CONDUIT',  a:'mana',   d:'All Mana you gain is increased by 1. Every 4 Mana you spend grants 1 Reroll.'},
  reptile:{n:'SCALES',   a:'thorns', d:'Always has Thorns 2. Your Thorns also apply Poison 1.'},
  bug:    {n:'VIRULENT', a:'poison', d:'Applying Poison to a target that already has Poison adds 2 stacks instead of 1.'},
  bird:   {n:'TALON',    a:'pierce', d:'Pierce attacks deal 3 extra damage. Your area faces also gain Pierce.'},
};

/* ================= ARCHETYPE (cho tracker UI) ================= */
const ARCH = {
  poison:{n:'PLAGUE',  ic:'☠', c:'#8fdc4a', d:'Stack Poison until it kills. Poison is the win condition.'},
  burn:  {n:'INFERNO', ic:'♨', c:'#ff9a4d', d:'Burn spreads, doubles, and crits.'},
  shield:{n:'BULWARK', ic:'⛨', c:'#5fb8ff', d:'Endless Shield, then turn that Shield into damage.'},
  mana:  {n:'CONDUIT', ic:'↯', c:'#c78cff', d:'Spam active cards. Never run out of Mana.'},
  pierce:{n:'TALON',   ic:'➤', c:'#e26fa8', d:'Ignore every Shield and finish off weakened targets.'},
  crit:  {n:'APEX',    ic:'✦', c:'#ffd76a', d:'High crit chance. Every hit is a big number.'},
  growth:{n:'EVOLVE',  ic:'⇗', c:'#66e08a', d:'Your die faces grow without limit during a fight.'},
  summon:{n:'SWARM',   ic:'✥', c:'#b0a8d0', d:'Summon Axie Eggs and win on numbers.'},
  aoe:   {n:'TEMPEST', ic:'✷', c:'#7ac8ff', d:'Every attack hits the whole board.'},
  /* 2026-09-04: thorns đổi icon ✷ -> ✜ (relic-system.md §11 mục 4). Trước đó aoe và thorns
     dùng CHUNG ✷ nên tracker UI không phân biệt được hai archetype khác nhau. */
  thorns:{n:'AEGIS',   ic:'✜', c:'#a86fd8', d:'Let the enemy kill itself on your armour.'},
  /* 2026-09-04: archetype thứ 11 (relic-system.md §3.3). PASSIVE.beast.a==='exec' đã trỏ tới
     key này từ trước nhưng ARCH không có entry ⇒ archScore() guard `if(sc[a]!=null)` bỏ qua
     im lặng ⇒ MỌI hero Beast góp 0 điểm cho mọi archetype, và relic tag 'exec' hiện em-dash. */
  exec:  {n:'FERAL',   ic:'✖', c:'#ff6b5f', d:'Wound them, then delete them. Every kill feeds the next.'},
};

/* ================= HEROES: 6 class × 3 tier ================= */
/* Hero display names (design/quick-specs/real-art-adoption-plan-2026-09-07.md
   §2, 2026-09-07 follow-up): renamed from generic gameplay names (Sprout/
   Cub/Fry/...) to the real Axie character each class's art actually shows —
   Olek/Buba/Puffy/Machito/Pomodoro/Momo. Matches the plan's own "one
   character carries all 3 tiers of its class" design: the UI already
   appends ' T'+tier separately (see client.html, grep "u.n+' T'+u.tier"), so
   e.g. plant1/2/3 render as "Olek T1"/"Olek T2"/"Olek T3" — the SAME
   character leveling up, not three unrelated names. */
const HEROES = {
  plant1:{n:'Olek',cls:'plant',tier:1,hp:17,art:0,art2:'olek_normal',die:[
    F('back','shield',4), F('back','shield',3), F('mouth','dmg',2), F('back','shield',2), F('horn','dmg',3), F('ears','mana',1,'cantrip')]},
  plant2:{n:'Olek',cls:'plant',tier:2,hp:25,art:3,art2:'olek_awaken',die:[
    F('back','shield',6), F('back','shield',5,'aoe'), F('mouth','dmg',4,'lifesteal'), F('eyes','heal',4),
    F('horn','dmg',5), F('ears','mana',1,'cantrip')]},
  plant3:{n:'Olek',cls:'plant',tier:3,hp:37,art:6,art2:'olek_awaken',die:[
    F('back','shield',9), F('back','shield',7,'aoe'), F('mouth','dmg',6,'lifesteal'), F('eyes','heal',6,'aoe'),
    F('horn','dmg',8,'cleave'), F('ears','mana',2,'cantrip')]},

  beast1:{n:'Buba',cls:'beast',tier:1,hp:12,art:0,art2:'buba_normal',die:[
    F('horn','dmg',5,'heavy'), F('horn','dmg',3), F('mouth','dmg',3), F('mouth','dmg',2,'growth'), F('back','shield',2), F('mouth','dmg',2)]},
  beast2:{n:'Buba',cls:'beast',tier:2,hp:18,art:3,art2:'buba_awaken',die:[
    F('horn','dmg',8,'heavy'), F('horn','dmg',5), F('mouth','dmg',4,'growth'), F('mouth','dmg',6,'selfharm:2'),
    F('tail','dmg',3,'cleave'), F('back','shield',3)]},
  beast3:{n:'Buba',cls:'beast',tier:3,hp:26,art:6,art2:'buba_awaken',die:[
    F('horn','dmg',13,'heavy'), F('horn','dmg',8,'vital'), F('mouth','dmg',6,'growth'), F('mouth','dmg',10,'selfharm:3'),
    F('tail','dmg',5,'cleave'), F('back','shield',5)]},

  aqua1:{n:'Puffy',cls:'aqua',tier:1,hp:13,art:0,art2:'puffy_normal',die:[
    F('ears','mana',1,'cantrip'), F('ears','mana',1,'cantrip'), F('eyes','heal',3), F('mouth','dmg',3),
    F('horn','dmg',4), F('mouth','dmg',2)]},
  aqua2:{n:'Puffy',cls:'aqua',tier:2,hp:19,art:3,art2:'puffy_awaken',die:[
    F('ears','mana',2,'cantrip'), F('ears','mana',1,'cantrip','rerollup'), F('eyes','heal',5), F('mouth','dmg',5),
    F('horn','dmg',6,'pierce'), F('tail','dmg',3,'aoe')]},
  aqua3:{n:'Puffy',cls:'aqua',tier:3,hp:27,art:6,art2:'puffy_awaken',die:[
    F('ears','mana',3,'cantrip'), F('ears','mana',2,'cantrip','rerollup'), F('eyes','heal',8,'aoe'), F('mouth','dmg',8),
    F('horn','dmg',9,'pierce'), F('tail','dmg',5,'aoe')]},

  reptile1:{n:'Machito',cls:'reptile',tier:1,hp:16,art:0,art2:'machito_normal',die:[
    F('back','shield',4), F('tail','poison',2), F('mouth','dmg',3), F('eyes','buff',0,'thorns:2'), F('back','shield',2), F('horn','dmg',3)]},
  reptile2:{n:'Machito',cls:'reptile',tier:2,hp:23,art:3,art2:'machito_awaken',die:[
    F('back','shield',6), F('tail','poison',3,'aoe'), F('mouth','dmg',4), F('eyes','buff',0,'thorns:3'),
    F('back','shield',4,'thorns:2'), F('horn','dmg',5,'pierce')]},
  reptile3:{n:'Machito',cls:'reptile',tier:3,hp:33,art:6,art2:'machito_awaken',die:[
    F('back','shield',9), F('tail','poison',5,'aoe'), F('mouth','dmg',7), F('eyes','debuff',0,'stun'),
    F('back','shield',6,'thorns:4'), F('horn','dmg',8,'pierce')]},

  bug1:{n:'Pomodoro',cls:'bug',tier:1,hp:14,art:0,art2:'pomodoro_normal',die:[
    F('eyes','debuff',0,'weaken:2'), F('tail','poison',2), F('mouth','dmg',3), F('back','shield',3), F('tail','poison',1), F('horn','dmg',3)]},
  bug2:{n:'Pomodoro',cls:'bug',tier:2,hp:20,art:3,art2:'pomodoro_normal',die:[
    F('eyes','debuff',0,'weaken:3'), F('eyes','debuff',0,'vulnerable:2'), F('tail','poison',3), F('mouth','dmg',4,'multi:2'),
    F('back','shield',4), F('horn','dmg',6)]},
  bug3:{n:'Pomodoro',cls:'bug',tier:3,hp:28,art:6,art2:'pomodoro_normal',die:[
    F('eyes','debuff',0,'weaken:4','aoe'), F('eyes','debuff',0,'vulnerable:3'), F('tail','poison',4,'aoe'),
    F('mouth','dmg',5,'multi:3'), F('eyes','debuff',0,'blind:2'), F('horn','dmg',9)]},

  bird1:{n:'Momo',cls:'bird',tier:1,hp:11,art:0,art2:'momo_normal',die:[
    F('horn','dmg',3,'pierce'), F('mouth','dmg',4), F('tail','dmg',2,'aoe'), F('ears','mana',1,'cantrip'), F('mouth','dmg',2), F('horn','dmg',2,'pierce')]},
  bird2:{n:'Momo',cls:'bird',tier:2,hp:16,art:3,art2:'momo_normal',die:[
    F('horn','dmg',5,'pierce'), F('mouth','dmg',6), F('tail','dmg',3,'aoe'), F('ears','mana',1,'cantrip'),
    F('mouth','dmg',3,'chain:3'), F('tail','dmg',2,'aoe')]},
  bird3:{n:'Momo',cls:'bird',tier:3,hp:23,art:6,art2:'momo_normal',die:[
    F('horn','dmg',8,'pierce'), F('mouth','dmg',9,'pierce'), F('tail','dmg',5,'aoe'), F('ears','mana',2,'cantrip'),
    F('mouth','dmg',4,'chain:4'), F('tail','dmg',4,'aoe','pierce')]},
};
const TIER_UP = {plant1:'plant2',plant2:'plant3',beast1:'beast2',beast2:'beast3',aqua1:'aqua2',aqua2:'aqua3',
  reptile1:'reptile2',reptile2:'reptile3',bug1:'bug2',bug2:'bug3',bird1:'bird2',bird2:'bird3'};
const T1 = ['plant1','beast1','aqua1','reptile1','bug1','bird1'];

/* ================= IMPORT AXIE — SLOT × CLASS TEMPLATE (design/AUDIT_AND_SPEC_v1.md §G3① / §G5) =================
   Insight: KHÔNG hand-author theo 500+ part thật. Đây là bảng TEMPLATE tất định 6 slot × 6 class (36 entry) +
   1 fallback Origin (Dawn/Dusk/Mech). Mọi part thật có cùng (slot, class) → LUÔN ra CÙNG 1 face — đây là điểm
   mấu chốt giữ balance surface nhỏ. KHÔNG cá nhân hoá theo part.name/part.id.
   Số liệu copy tinh thần/dải giá trị từ face tier1 của đúng class đó trong HEROES ở trên (dmg/shield 2-4,
   ears luôn mana 1 cantrip). Đọc-chỉ-để-tham-khảo HEROES — bảng này không sửa HEROES/TUNE.
   eyes: type chọn theo PASSIVE[cls].a (archetype code) để nhất quán identity —
     plant/aqua (đã có heal ở tier1/2) → heal · reptile (SCALES/thorns) → buff thorns:2 (=reptile1) ·
     bug (VIRULENT/poison, debuff vốn có) → debuff weaken:2 (=bug1) ·
     beast (FERAL/exec — nhắm target yếu) → debuff vulnerable:2 (setup cho execute, không có face gốc tier1 để copy) ·
     bird (TALON/pierce — hit-and-run) → debuff blind:1 (utility nhẹ, giữ bird là class dmg thuần, không lấn buff/heal). */
const SLOT_CLASS_TEMPLATE = {
  eyes: {
    plant:   F('eyes','heal',3),
    beast:   F('eyes','debuff',0,'vulnerable:2'),
    aqua:    F('eyes','heal',3),
    reptile: F('eyes','buff',0,'thorns:2'),
    bug:     F('eyes','debuff',0,'weaken:2'),
    bird:    F('eyes','debuff',0,'blind:1'),
  },
  ears: {
    plant:   F('ears','mana',1,'cantrip'),
    beast:   F('ears','mana',1,'cantrip'),
    aqua:    F('ears','mana',1,'cantrip'),
    reptile: F('ears','mana',1,'cantrip'),
    bug:     F('ears','mana',1,'cantrip'),
    bird:    F('ears','mana',1,'cantrip'),
  },
  mouth: {
    plant:   F('mouth','dmg',2),
    beast:   F('mouth','dmg',3),
    aqua:    F('mouth','dmg',3),
    reptile: F('mouth','dmg',3),
    bug:     F('mouth','dmg',3),
    bird:    F('mouth','dmg',4),
  },
  horn: {
    plant:   F('horn','dmg',3),
    beast:   F('horn','dmg',4,'heavy'),
    aqua:    F('horn','dmg',3,'pierce'),
    reptile: F('horn','dmg',3,'pierce'),
    bug:     F('horn','dmg',3),
    bird:    F('horn','dmg',3,'pierce'),
  },
  back: {
    plant:   F('back','shield',4),
    beast:   F('back','shield',2),
    aqua:    F('back','shield',3),
    reptile: F('back','shield',4),
    bug:     F('back','shield',3),
    bird:    F('back','shield',2),
  },
  tail: {
    plant:   F('tail','dmg',2),
    beast:   F('tail','dmg',3,'cleave'),
    aqua:    F('tail','dmg',2,'aoe'),
    reptile: F('tail','dmg',2),
    bug:     F('tail','dmg',2,'multi:2'),
    bird:    F('tail','dmg',2,'aoe'),
  },
};
/* Biến thể theo TÊN PART THẬT (2026-09-03, game-designer đề xuất — xem
   design/quick-specs/import-axie-variants-2026-09-03.md) — giải quyết vấn đề
   "nhiều Axie khác ID nhưng ra thẻ gần như y hệt" (SLOT_CLASS_TEMPLATE trên
   chỉ phân biệt theo (slot,class), bỏ qua danh tính riêng của từng part thật).
   Mỗi TYPE mặt có sẵn vài biến thể — cùng dải sức mạnh (giữ balance, chỉ khác
   1 keyword nhỏ hoặc value ±1), CHỌN TẤT ĐỊNH theo part.name/part.id qua
   partVariantIndex() (engine.js) — không random, không hash-làm-RNG-ẩn: cùng
   tên part luôn ra đúng 1 biến thể, có thể tra bảng này để biết trước (đúng
   pillar "minh bạch triệt để"). KHÔNG đổi type/part-slot, chỉ tinh chỉnh nhỏ
   trên value/keyword của face gốc — vẫn đúng 6 mặt = 6 part thật của Axie đó. */
const PART_VARIANT_MODS = {
  dmg:    [ {}, {addKw:'crit:15'}, {dv:1} ],
  shield: [ {}, {addKw:'thorns:1'}, {dv:1} ],
  heal:   [ {}, {addKw:'regen:1'}, {dv:1} ],
  poison: [ {}, {addKw:'aoe'}, {dv:1} ],
  mana:   [ {}, {addKw:'rerollup'}, {dv:1} ],
  debuff: [ {}, {dv:1} ],
  buff:   [ {}, {dv:1} ],
  summon: [ {}, {dv:1} ],
};
/* Fallback cho 3 class Origin thật (Dawn/Dusk/Mech) — không có trong 6 class game hỗ trợ.
   Quyết định: mỗi Origin class map TẤT ĐỊNH sang 1 class game đại diện (đơn giản hoá — không hash part.id),
   để 3 Origin class ít nhất khác nhau (Dawn≠Dusk≠Mech), dù 2 part Dawn khác nhau cùng slot vẫn ra cùng face
   (đúng nguyên tắc template). axieToDie() nhân giá trị mặt lên ORIGIN_TIER3_MULT và ép rarity>=3 (Legendary)
   để phản ánh "part Origin là hiếm nhất trong game thật" như yêu cầu. */
const ORIGIN_CLASS_MAP = {dawn:'beast', dusk:'reptile', mech:'bug'};
const ORIGIN_TIER3_MULT = 2.2; /* xấp xỉ tỉ lệ value tier1→tier3 quan sát được trong HEROES ở trên */

/* ================= MUTATION FACE POOL (rarity-tiered) =================
   Đây là "Rare Dice" theo Option D: rarity nằm trên MẶT, người chơi tự slot vào. */
const FACE_POOL = [
  /* --- COMMON (r0): 1 action, 0 keyword --- */
  FR(0,'mouth','dmg',6), FR(0,'horn','dmg',7), FR(0,'back','shield',7), FR(0,'eyes','heal',6),
  FR(0,'ears','mana',2,'cantrip'), FR(0,'tail','poison',4), FR(0,'mouth','dmg',5), FR(0,'back','shield',6),
  /* --- RARE (r1): +1 keyword --- */
  FR(1,'horn','dmg',7,'pierce'), FR(1,'mouth','dmg',7,'lifesteal'), FR(1,'tail','dmg',5,'cleave'),
  FR(1,'back','shield',6,'aoe'), FR(1,'horn','dmg',9,'heavy'), FR(1,'tail','poison',5,'aoe'),
  FR(1,'eyes','heal',7,'aoe'), FR(1,'mouth','dmg',6,'growth'), FR(1,'ears','mana',3,'cantrip'),
  FR(1,'eyes','debuff',0,'weaken:3','aoe'), FR(1,'horn','dmg',8,'crit:30'), FR(1,'tail','dmg',6,'burn:3'),
  /* --- EPIC (r2): 2 keyword --- */
  FR(2,'horn','dmg',10,'pierce','crit:25'), FR(2,'mouth','dmg',8,'lifesteal','growth'),
  FR(2,'tail','dmg',7,'cleave','burn:4'), FR(2,'back','shield',9,'aoe','thorns:3'),
  FR(2,'tail','poison',6,'aoe','multi:2'), FR(2,'mouth','dmg',6,'multi:3'),
  FR(2,'horn','dmg',12,'heavy','vital'), FR(2,'ears','mana',3,'cantrip','rerollup'),
  FR(2,'eyes','debuff',0,'vulnerable:3','freeze'), FR(2,'tail','dmg',6,'aoe','pierce'),
  FR(2,'eyes','summon',1,'cantrip'), FR(2,'mouth','dmg',9,'exec'),
  /* --- LEGENDARY (r3): 2 keyword + value lớn --- */
  FR(3,'horn','dmg',18,'heavy','pierce'), FR(3,'tail','dmg',11,'aoe','burn:5'),
  FR(3,'mouth','dmg',13,'lifesteal','crit:40'), FR(3,'back','shield',15,'aoe','thorns:5'),
  FR(3,'tail','poison',9,'aoe','pierce'), FR(3,'horn','dmg',14,'cleave','exec'),
  FR(3,'ears','mana',5,'cantrip','rerollup'), FR(3,'eyes','heal',14,'aoe','regen:3'),
  FR(3,'mouth','dmg',8,'chain:5','crit:30'), FR(3,'eyes','summon',2,'cantrip'),
  /* --- MYTHIC (r4): phá luật --- */
  FR(4,'tail','poison',7,'aoe','plague'),        /* plague: Poison không giảm tầng */
  FR(4,'horn','dmg',20,'pierce','echo'),         /* echo: kích hoạt 2 lần */
  FR(4,'back','shield',18,'aoe','bastion'),      /* bastion: Shield cũng gây dmg = 100% */
  FR(4,'mouth','dmg',16,'lifesteal','crit:100'), /* crit luôn luôn */
  FR(4,'ears','mana',8,'cantrip','overflow'),    /* overflow: mana thừa cuối lượt → dmg AoE */
  FR(4,'tail','dmg',13,'aoe','cleave','burn:8'),
  FR(4,'eyes','summon',3,'cantrip'),
  FR(4,'horn','dmg',26,'heavy','vital','exec'),
];
/* 2026-09-01: tên part Axie thật (đã có quyền dùng tên — art dùng placeholder tạm,
   xem docs/axiedice-source/economy/PART_REVIEW_SHEET.md). Chỉ gắn NHÃN hiển thị,
   không đổi số/keyword nào — zero rủi ro balance. Khớp 1:1 theo thứ tự FACE_POOL. */
const FACE_NAMES=[
  // COMMON
  'Zigzag','Incisor','Snail Shell','Blossom','Gill','Grass Snake','Razor Bite','Pumpkin',
  // RARE
  'Cerastes','Toothless Bite','Cloud','Hermit','Imp','Tiny Dino','Cucumber Slice','Confident',
  'Bubblemaker','Little Peas','Dual Blade','The Last One',
  // EPIC
  'Eggshell','Axie Kiss','Swallow','Indian Star','Gila','Nut Cracker','Little Branch','Nyan',
  'Scar','Post Fight','Mavis','Lam',
  // LEGENDARY
  'Scaly Spear','Twin Tail','Piranha','Tri Spikes','Wall Gecko','Kestrel','Friezard','Gecko',
  'Goda','Robin',
  // MYTHIC
  'Thorny Caterpillar','Wing Horn','Green Thorns','Mosquito','Sidebarb',"Granma's Fan",'Neo','Pocky',
];
FACE_POOL.forEach((f,i)=>{ if(FACE_NAMES[i]) f.name=FACE_NAMES[i]; });
const MYTHIC_KW = {plague:'Poison never decays',echo:'Triggers twice',bastion:'Shield also deals damage',overflow:'Unspent Mana becomes area damage'};
const RUNES = ['cleave','pierce','growth','vital','lifesteal','aoe','crit:30','burn:4','exec','echo'];

/* ================= MONSTERS (role-based) ================= */
const MON = {
  /* ROLE: bruiser — damage thuần */
  slime:{n:'Gooey Slime',role:'bruiser',cost:3,hp:9,die:[
    F('m','dmg',3),F('m','dmg',3),F('m','dmg',2),F('m','shield',3),B,F('m','dmg',4)]},
  chomper:{n:'Chomper',role:'bruiser',cost:4,hp:11,die:[
    F('m','dmg',4),F('m','dmg',4),F('m','dmg',5),B,F('m','dmg',3),F('m','shield',2)]},
  bruiser:{n:'Bruiser',role:'bruiser',cost:7,hp:20,die:[
    F('m','dmg',8,'heavy'),F('m','dmg',6),F('m','dmg',5),F('m','shield',5),F('m','dmg',7),B]},
  /* ROLE: assassin — nhắm Axie yếu nhất, pierce */
  ravenling:{n:'Ravenling',role:'assassin',cost:5,hp:10,die:[
    F('m','dmg',5,'pierce'),F('m','dmg',4),F('m','dmg',3,'aoe'),F('m','dmg',6),B,F('m','dmg',4,'pierce')]},
  stalker:{n:'Stalker',role:'assassin',cost:8,hp:14,die:[
    F('m','dmg',9,'pierce'),F('m','dmg',7,'exec'),F('m','dmg',6),F('m','dmg',11,'pierce'),F('m','shield',4),B]},
  /* ROLE: tank — HP/shield cao, dmg thấp, taunt */
  spikelet:{n:'Spikelet',role:'tank',cost:4,hp:12,die:[
    F('m','dmg',3),F('m','buff',0,'thorns:3'),F('m','dmg',4),F('m','shield',4),F('m','dmg',2),B]},
  thornback:{n:'Thornback',role:'tank',cost:6,hp:19,die:[
    F('m','shield',6),F('m','dmg',5),F('m','buff',0,'thorns:4'),F('m','dmg',6,'cleave'),F('m','dmg',4),B]},
  /* ROLE: healer — hồi máu đồng minh */
  jellyfin:{n:'Jellyfin',role:'healer',cost:5,hp:13,die:[
    F('m','dmg',4,'cleave'),F('m','heal',5),F('m','shield',5),F('m','heal',4,'aoe'),F('m','dmg',5),B]},
  warden:{n:'Warden',role:'healer',cost:9,hp:26,die:[
    F('m','shield',9,'aoe'),F('m','dmg',8),F('m','heal',8,'aoe'),F('m','dmg',10),F('m','buff',0,'thorns:5'),B]},
  /* ROLE: poisoner */
  bugling:{n:'Bugling',role:'poisoner',cost:3,hp:8,die:[
    F('m','poison',2),F('m','dmg',3),F('m','dmg',2),F('m','poison',3),B,F('m','dmg',4)]},
  venomaw:{n:'Venomaw',role:'poisoner',cost:6,hp:14,die:[
    F('m','poison',3,'aoe'),F('m','dmg',6),F('m','poison',4),F('m','dmg',5),F('m','debuff',0,'weaken:2'),B]},
  /* ROLE: mage — debuff/AoE */
  hexeye:{n:'Hexeye',role:'mage',cost:7,hp:15,die:[
    F('m','debuff',0,'blind:2'),F('m','dmg',6),F('m','debuff',0,'vulnerable:3'),F('m','dmg',5,'aoe'),F('m','debuff',0,'freeze'),B]},
  pyrewing:{n:'Pyrewing',role:'mage',cost:8,hp:16,die:[
    F('m','dmg',6,'aoe','burn:3'),F('m','dmg',8),F('m','dmg',5,'burn:5'),F('m','dmg',7,'aoe'),F('m','shield',6),B]},
  /* ROLE: summoner */
  broodmaw:{n:'Broodmaw',role:'summoner',cost:8,hp:18,summons:'bugling',die:[
    F('m','dmg',6),F('m','summon',1),F('m','dmg',7),F('m','shield',6),F('m','summon',1),F('m','dmg',5,'aoe')]},
  /* ROLE: kamikaze — HP thấp, đòn cực mạnh rồi tự chết */
  bomblet:{n:'Bomblet',role:'kamikaze',cost:5,hp:7,die:[
    F('m','dmg',12,'aoe','selfkill'),F('m','dmg',3),F('m','dmg',4),F('m','dmg',12,'aoe','selfkill'),F('m','shield',3),B]},
  /* ROLE: buffer */
  totem:{n:'Chimera Totem',role:'buffer',cost:6,hp:16,die:[
    F('m','buff',0,'enrage'),F('m','shield',7,'aoe'),F('m','dmg',5),F('m','buff',0,'enrage'),F('m','heal',6,'aoe'),B]},
  cleaver:{n:'Cleaver',role:'bruiser',cost:8,hp:19,die:[
    F('m','dmg',7,'cleave'),F('m','dmg',9),F('m','dmg',6,'cleave'),F('m','dmg',5),F('m','shield',6),B]},
  /* elite */
  e_ravager:{n:'Elite Ravager',role:'bruiser',cost:11,elite:1,hp:30,die:[
    F('m','dmg',11,'heavy'),F('m','dmg',8,'cleave'),F('m','dmg',7),F('m','dmg',9),F('m','shield',8),F('m','dmg',6,'aoe')]},
  e_plague:{n:'Elite Plaguebearer',role:'poisoner',cost:11,elite:1,hp:28,die:[
    F('m','poison',5,'aoe'),F('m','dmg',9),F('m','poison',6),F('m','debuff',0,'weaken:3'),F('m','dmg',8,'aoe'),F('m','heal',8)]},
  e_bulwark:{n:'Elite Bulwark',role:'tank',cost:11,elite:1,hp:38,die:[
    F('m','shield',12,'aoe'),F('m','dmg',10),F('m','buff',0,'thorns:6'),F('m','dmg',12),F('m','heal',10,'aoe'),F('m','dmg',7,'cleave')]},
  e_archon:{n:'Elite Archon',role:'mage',cost:11,elite:1,hp:26,die:[
    F('m','dmg',9,'aoe','burn:4'),F('m','debuff',0,'blind:2','aoe'),F('m','dmg',13),F('m','debuff',0,'vulnerable:4'),
    F('m','dmg',8,'aoe'),F('m','shield',10)]},
  /* summoned token */
  egg:{n:'Axie Egg',role:'token',cost:2,hp:6,token:1,die:[
    F('m','dmg',4),F('m','dmg',3),F('m','shield',3),F('m','dmg',5),F('m','dmg',3),B]},
};
const NORMAL_POOL = [
  {k:'slime',min:1},{k:'chomper',min:1},{k:'bugling',min:1},{k:'spikelet',min:2},
  {k:'jellyfin',min:3},{k:'ravenling',min:3},{k:'bomblet',min:4},{k:'thornback',min:5},
  {k:'venomaw',min:5},{k:'totem',min:6},{k:'bruiser',min:7},{k:'hexeye',min:7},
  {k:'pyrewing',min:8},{k:'stalker',min:9},{k:'broodmaw',min:9},{k:'cleaver',min:10},{k:'warden',min:11},
];
const ELITE_POOL = ['e_ravager','e_plague','e_bulwark','e_archon'];

/* ================= BOSSES — constrain, không destroy ================= */
const BOSSES = [
  {k:'gooey_king',n:'GOOEY KING',hpk:3.7,dmgk:0.62,trait:'split',addCap:2,adds:['slime'],
   desc:'SPLIT — spawns a Gooey Slime at 2/3 and 1/3 HP.',
   die:[F('m','dmg',9),F('m','dmg',7,'cleave'),F('m','shield',9),F('m','dmg',6,'aoe'),F('m','dmg',11),F('m','heal',8)]},
  {k:'mecha',n:'MECHA CHIMERA',hpk:3.3,dmgk:0.57,trait:'thorns',addCap:0,adds:[],
   desc:'RETALIATE — always has Thorns. Every 3rd turn it enters OVERDRIVE and deals 50% more damage.',
   die:[F('m','dmg',13),F('m','dmg',9,'aoe'),F('m','shield',14),F('m','dmg',11,'cleave'),F('m','dmg',16,'pierce'),F('m','buff',0,'thorns:6')]},
  {k:'frost_lord',n:'FROST LORD',hpk:3.2,dmgk:0.55,trait:'freeze',addCap:0,adds:[],
   desc:'DEEP FREEZE — freezes one of your dice each turn. Frozen dice cannot be rerolled, but can still be used.',
   die:[F('m','dmg',12,'aoe'),F('m','dmg',15),F('m','shield',13,'aoe'),F('m','debuff',0,'freeze','aoe'),F('m','dmg',18,'pierce'),F('m','heal',12)]},
  {k:'plague_mother',n:'PLAGUE MOTHER',hpk:3.0,dmgk:0.54,trait:'summon',addCap:3,adds:['bugling','venomaw'],
   desc:'BROOD — summons a minion every 3 turns and stacks Poison relentlessly.',
   die:[F('m','poison',7,'aoe'),F('m','dmg',14),F('m','poison',9),F('m','dmg',12,'aoe'),F('m','debuff',0,'weaken:4'),F('m','heal',14)]},
  {k:'mirror',n:'MIRROR CHIMERA',hpk:2.9,dmgk:0.52,trait:'mirror',addCap:0,adds:[],
   desc:'MIRROR — copies the strongest die face you used last turn and plays it back at you.',
   die:[F('m','dmg',14),F('m','dmg',10,'aoe'),F('m','shield',15),F('m','dmg',12,'cleave'),F('m','dmg',17,'pierce'),F('m','heal',13)]},
  {k:'agony',n:'NIGHTMARE AGONY',hpk:2.0,hpk2:2.5,dmgk:0.50,trait:'phase',addCap:0,adds:[],
   desc:'TWO PHASES — on defeat it heals to full and switches to a far deadlier die.',
   die:[F('m','dmg',16),F('m','dmg',12,'aoe'),F('m','shield',16),F('m','dmg',14,'cleave'),F('m','debuff',0,'blind:3'),F('m','dmg',20,'pierce')],
   die2:[F('m','dmg',22,'pierce'),F('m','dmg',16,'aoe'),F('m','dmg',18,'cleave'),F('m','dmg',14,'aoe','pierce'),
         F('m','debuff',0,'vulnerable:4'),F('m','dmg',26)]},
];
const BOSS_BY_K = {}; BOSSES.forEach(b=>BOSS_BY_K[b.k]=b);
/* thứ tự boss: 2 boss đầu dễ hơn, final luôn là agony */
const BOSS_ORDER_12 = ['gooey_king','frost_lord','agony'];
const BOSS_ORDER_20 = ['gooey_king','mecha','plague_mother','agony'];
const BOSS_ALT      = ['frost_lord','mirror'];   /* thay thế ngẫu nhiên cho boss giữa */

/* ================= RELIC — hook system, đổi LUẬT ================= */
/* HOOK API — danh sách này phải khớp `rcall`/`rlist` thật trong src/engine.js (ENG-17).
   Bản trước liệt kê onPoison/onTurnEnd (KHÔNG có rcall nào) và bỏ sót onHit (CÓ được gọi) —
   một comment nói dối về API là cách project này đã bị cắn 3 lần (xem §6.2a r_voidgene).
     modFace(u)            build-time, chạy theo thứ tự INV-5 (mfPhase/rar/RELIC_INDEX)
     modFace2(u)           entry modFace thứ 2 ở pha khác (mfPhase2)
     onRollEnd(s)          sau khi roll xong mỗi lượt
     onTurnStart(s)        đầu mỗi lượt + đầu trận
     modDmg({s,src,tgt,v}) -> v
     onHit(s,{type,dealt,tgt,crit,src,addStatus})
     onKill(s,{tgt,explode})
     onShield(s,{v,tgt,splash})
     onThorns(s,{src,tgt,th})              ENG-5
     onDmgTaken(s,{src,tgt,dealt,attack})  ENG-19 / QĐ-2
     growthAllGuard(s) -> bool             guard theo lượt cho growthAll (ENG-18)
   act:{cost,kind,...} = thẻ Lunacia active */
/* ================= RELICS — 94 (78 passive + 16 active) =================
   Nguồn định giá: design/gdd/relic-system.md §6.1-§6.5 (44 retune) + §6.7 (48 audit) +
   §6.7.7 (2 entry PLAGUE mới). MỌI id cũ được giữ nguyên: META.relics lưu tiến độ
   Collection xuyên save và ui.js gate phần thưởng ở META.relics.length >= RELICS.length,
   nên một id biến mất là một entry mồ côi không bao giờ đếm được (migration: §7 E7).

   Trường bắt buộc trên mỗi entry:
     mload  0|1|2  §3.6 — 2 = multiplier TOÀN CỤC · 1 = multiplier PHẠM VI ARCHETYPE
                   (bằng 0 nếu build không có trục đó) · 0 = còn lại. Tổng <= RELIC_MLOAD_CAP.
     ex     []     §3.7 — token de-dup. Một token cho mỗi LUẬT, không cho mỗi field.
     mfPhase       INV-5 — 'kw' | 'add' | 'mul'. CHỈ trên relic có modFace. Không suy từ thân hàm.
     eng           §11 mục 17b / INV-9 — trỏ tới mục engine work mà relic phụ thuộc.
   `cat` (taxonomy §3.1) KHÔNG được ship: không có điểm đọc nào trong engine, và INV-9 cấm
   ship field không ai đọc. Nó sống trong doc, nơi nó là nhãn phân loại chứ không phải cơ chế. */
const RELICS = [
  /* ---------------- COMMON — Band [11.22, 15.18] (§6.1) ---------------- */
  {id:'r_claw', n:'Razor Claw', rar:0, a:'exec', d:'All damage faces deal 1 more.',
    mload:0, ex:[], mfPhase:'add',
    modFace:u=>u.die.forEach(f=>{if(f.t==='dmg')f.v+=1;})},
  {id:'r_carapace', n:'Stone Carapace', rar:0, a:'shield', d:'All Shield and Heal faces give 2 more.',
    mload:0, ex:[], mfPhase:'add',
    modFace:u=>u.die.forEach(f=>{if(f.t==='shield'||f.t==='heal')f.v+=2;})},
  /* §3.7a cặp 2 — 9 mặt ⊂ 29 mặt của r_worldpiercer, ĐO TRÊN MẶT THẬT. Theo hệ type hai relic
     này "độc lập" (horn∧shield thuộc cái đầu) — nhưng horn∧shield KHÔNG TỒN TẠI: horn chỉ mang
     dmg (§4.4b), nên "mọi mặt horn" nằm trọn trong "mọi mặt dmg". `exSub` MỘT CHIỀU: r_worldpiercer
     vẫn được đề nghị khi đang giữ relic này (nó là nâng cấp thật). */
  {id:'r_pierceall',n:'Piercing Horn', rar:0, a:'pierce', d:'RULE: every Horn face gains Pierce.',
    mload:0, ex:['pierceInject'], exSub:['pierceInjectAll'], mfPhase:'kw',
    modFace:u=>u.die.forEach(f=>{ if(f.p==='horn'&&!f.k.includes('pierce'))f.k.push('pierce'); })},
  /* INV-7: bản cũ tiêm `cleave` vào slot `tail`, định giá ở p_slot 0.111 — nhưng 3/4 mặt tail
     tier-1 là `poison`, và nhánh poison của doFace KHÔNG BAO GIỜ đi qua hit() ⇒ cleave ở đó là
     no-op im lặng. Giá thật 3.57 RP = 27% một COMMON. Hiệu ứng mới định giá ở p_eff(aoe). */
  {id:'r_cleaveall',n:'Sweeping Tail', rar:0, a:'aoe', d:'Damage faces that already Cleave or hit All deal 2 more.',
    mload:0, ex:[], mfPhase:'add',
    modFace:u=>u.die.forEach(f=>{ if(f.t==='dmg'&&(f.k.includes('cleave')||f.k.includes('aoe')))f.v+=2; })},
  {id:'r_bloodmouth',n:'Bloodmouth', rar:0, a:'exec', d:'RULE: every Mouth face gains Lifesteal. Each Axie gains 2 Max HP.',
    mload:0, ex:[], mfPhase:'kw',
    modFace:u=>{ u.die.forEach(f=>{ if(f.p==='mouth'&&!f.k.includes('lifesteal'))f.k.push('lifesteal'); }); u.maxHp+=2; }},
  /* §3.7a cặp 3 — 17 mặt ⊂ 31 mặt của r_apexferal. `exSub` chứ KHÔNG PHẢI `ex`: token chung sẽ
     khiến COMMON 11.88 RP này cấm LEGENDARY r_apexferal xuất hiện. */
  {id:'r_gorehook', n:'Gorehook', rar:0, a:'exec', d:'RULE: every Horn and Tail damage face gains Execute.',
    mload:0, ex:[], exSub:['execInjectAll'], mfPhase:'kw',
    modFace:u=>u.die.forEach(f=>{ if(f.t==='dmg'&&(f.p==='horn'||f.p==='tail')&&!f.k.includes('exec'))f.k.push('exec'); })},
  {id:'r_broodpouch',n:'Brood Pouch', rar:0, a:'summon', d:'Start every fight with an Axie Egg.',
    mload:0, ex:[], startSummon:1},
  {id:'r_barbedhide',n:'Barbed Hide', rar:0, a:'thorns', d:'Your Thorns deal 1 more damage. Shield faces give 1 more.',
    mload:0, ex:[], mfPhase:'add', eng:'ENG-4', thornsPlus:1,
    modFace:u=>u.die.forEach(f=>{ if(f.t==='shield')f.v+=1; })},
  {id:'r_rotbite', n:'Rot Bite', rar:0, a:'poison', d:'RULE: poisoned enemies take 2 more damage from every attack.',
    mload:0, ex:['poisonAmpFlat'],
    modDmg:ctx=> (ctx.tgt.st.poison>0? ctx.v+2 : ctx.v)},
  {id:'r_tinderbox',n:'Tinderbox', rar:0, a:'burn', d:'RULE: burning enemies take 2 more damage from every attack.',
    mload:0, ex:['burnAmpFlat'],
    modDmg:ctx=> (ctx.tgt.st.burn>0? ctx.v+2 : ctx.v)},
  {id:'r_lastwall',n:'Last Wall', rar:0, a:'shield', d:'RULE: at the start of every turn, your most endangered Axie survives its next killing blow with 1 HP.',
    mload:0, ex:['undyingGrant'],
    onTurnStart:s=>{ const p=aliveP(s).filter(u=>!u.token);
      if(!p.length) return;
      let w=p[0]; for(const u of p) if(u.hp+u.shield < w.hp+w.shield) w=u;
      if(!w.st.undying){ w.st.undying=1; ft(s,w,'UNDYING','buf'); } }},
  {id:'r_tidalbrand',n:'Tidalbrand', rar:0, a:'mana', d:'RULE: every Ears face also grants 1 Reroll. Start each fight with 1 extra Reroll.',
    mload:0, ex:[], mfPhase:'kw',
    modFace:u=>u.die.forEach(f=>{ if(f.p==='ears'&&!f.k.includes('rerollup'))f.k.push('rerollup'); }),
    onTurnStart:s=>{ if(s.turn===1){ s.rerolls++; s.maxRerolls++; } }},
  {id:'r_predatorpoise',n:"Predator's Poise", rar:0, a:'crit', d:'RULE: rerolling an Axie no longer cancels a critical hit it had already rolled.',
    mload:0, ex:[], eng:'ENG-15', critKeep:1},
  {id:'r_seedling',n:'Seedling Core', rar:0, a:'growth', d:'Every face grows by 1 each turn. Growth faces grow by 2 instead of 1.',
    mload:0, ex:[], eng:'ENG-18', growthAll:1, growthPlus:1},

  /* ---------------- RARE — Band [15.89, 21.48] (§6.2) ---------------- */
  {id:'r_heart', n:'Lunacia Heart', rar:1, a:'shield', d:'Each Axie gains 12 Max HP.',
    mload:0, ex:[], mfPhase:'add', modFace:u=>{u.maxHp+=12;}},
  {id:'r_ear', n:'Keen Ears', rar:1, a:'mana', d:'All Mana faces give 1 more.',
    mload:0, ex:['manaFaceBoost'], mfPhase:'add',
    modFace:u=>u.die.forEach(f=>{if(f.t==='mana')f.v+=1;})},
  {id:'r_spines', n:'Sharp Spines', rar:1, a:'thorns', d:'The whole party always has Thorns 2.',
    mload:0, ex:['thornsFloorFlat'],
    onTurnStart:s=>s.party.forEach(u=>{ if(u.hp>0) u.st.thorns=Math.max(u.st.thorns||0,2); })},
  {id:'r_luckycharm',n:'Lucky Scale', rar:1, a:'crit', d:'RULE: every attack has a 35% higher chance to crit.',
    mload:1, ex:['critChance'], critBonus:35},
  {id:'r_ember', n:'Ember', rar:1, a:'burn', d:'RULE: any hit dealing 4 or more damage also applies Burn 2.',
    mload:0, ex:[],
    onHit:(s,ctx)=>{ if(ctx.type==='dmg'&&ctx.dealt>=4) ctx.addStatus('burn:2'); }},
  {id:'r_openwound',n:'Open Wound', rar:1, a:'poison', d:'RULE: targets with Poison take 30% more damage.',
    mload:0, ex:['poisonAmpPct'],
    modDmg:ctx=> ctx.tgt.st.poison>0 ? Math.ceil(ctx.v*1.3) : ctx.v},
  {id:'r_deathmark', n:'Death Mark', rar:1, a:'exec', d:'RULE: whenever an enemy dies, all damage faces gain 1 for the rest of the fight. Each Axie gains 2 Max HP.',
    mload:0, ex:[], mfPhase:'add',
    modFace:u=>{u.maxHp+=2;},
    onKill:(s,ctx)=>s.party.forEach(u=>u.die.forEach(f=>{if(f.t==='dmg')f.v+=1;}))},
  {id:'r_holyfont', n:'Sacred Font', rar:1, a:'shield', d:'RULE: healing also grants Shield equal to the amount healed.',
    mload:0, ex:['healShield'], healShield:1},
  {id:'r_hivemind', n:'Hive Mind', rar:1, a:'summon', d:'RULE: each living Axie Egg gives the whole party 1 more damage.',
    mload:1, ex:['hiveMind'], hiveMind:1},
  {id:'r_wildfire',n:'Wildfire', rar:1, a:'burn', d:'RULE: Burn loses only 1 stack per turn instead of half. Every Horn damage face also applies Burn 6.',
    mload:1, ex:['burnDecay'], mfPhase:'kw', burnSlow:1,
    modFace:u=>u.die.forEach(f=>{ if(f.p==='horn'&&f.t==='dmg'&&!f.k.some(k=>k.startsWith('burn')))f.k.push('burn:6'); })},
  /* §6.2a — id này hỏng BA LẦN theo cùng một cách: định giá một cơ chế không tồn tại
     (mặt `blank` không có trên hero nào · rerollup trùng r_tidalbrand · rerollRefund không
     tồn tại trong src). INV-9 buộc định giá theo cơ chế THẬT SỰ chạy được. */
  {id:'r_voidgene', n:'Void Gene', rar:1, a:'mana', d:'Gain 2 maximum Rerolls, and 1 Mana at the start of every fight.',
    mload:0, ex:[], rerollUp:2,
    onTurnStart:s=>{ if(s.turn===1){ s.mana+=1; } }},
  {id:'r_talonedge',n:'Talon Edge', rar:1, a:'pierce', d:'Faces that already Pierce deal 2 more. Horn attacks deal 1 more.',
    mload:0, ex:[], mfPhase:'add',
    modFace:u=>u.die.forEach(f=>{ if(f.t!=='dmg') return; if(f.k.includes('pierce')) f.v+=2; if(f.p==='horn') f.v+=1; })},
  {id:'r_marrowdrill',n:'Marrow Drill', rar:1, a:'pierce', d:'RULE: every Pierce damage face also applies Weaken 2.',
    mload:0, ex:[], mfPhase:'kw',
    modFace:u=>u.die.forEach(f=>{ if(f.t==='dmg'&&f.k.includes('pierce')&&!f.k.some(k=>k.startsWith('weaken')))f.k.push('weaken:2'); })},
  {id:'r_heartwood',n:'Heartwood', rar:1, a:'growth', d:'RULE: from the second turn on, every face on each Axie grows by 2 for the rest of the fight.',
    mload:0, ex:[], eng:'ENG-18', growthAll:2, growthAllGuard:s=>s.turn>1},
  {id:'r_bloomscale',n:'Bloomscale', rar:1, a:'growth', d:'RULE: every Back and Eyes face gains Growth, and Growth faces grow by 4 instead of 1.',
    mload:0, ex:[], mfPhase:'kw', eng:'ENG-2', growthPlus:3,
    modFace:u=>u.die.forEach(f=>{ if((f.p==='back'||f.p==='eyes')&&!f.k.includes('growth'))f.k.push('growth'); })},
  {id:'r_eggshell',n:'Eggshell Ward', rar:1, a:'summon', d:'RULE: every Axie Egg gains 2 Shield at the start of each turn.',
    mload:0, ex:[],
    onTurnStart:s=>s.party.forEach(u=>{ if(u.token&&u.hp>0) applyShield(s,u,2); })},
  {id:'r_broodmother',n:'Broodmother', rar:1, a:'summon', d:'RULE: whenever an enemy dies, hatch an Axie Egg. Your Eggs deal 1 more damage.',
    mload:0, ex:[],
    onKill:(s,ctx)=>{ const cap=rmax(s,'tokenCap',4);
      if(s.party.filter(x=>x.token&&x.hp>0).length<cap){ const al=mkAlly(s); rollUnit(s,al); al.used=true; s.party.push(al); } },
    onTurnStart:s=>s.party.forEach(u=>{ if(u.token&&u.hp>0&&!u.eggDmg){ u.eggDmg=1; u.die.forEach(f=>{ if(f.t==='dmg')f.v+=1; }); } })},
  {id:'r_bloodthorn',n:'Bloodthorn', rar:1, a:'thorns', d:'RULE: when an Axie is struck, it heals a third of its own Thorns. Shield faces give 1 more.',
    mload:0, ex:[], mfPhase:'add', eng:'ENG-19',
    modFace:u=>u.die.forEach(f=>{ if(f.t==='shield')f.v+=1; }),
    onDmgTaken:(s,ctx)=>{ if(!ctx.attack) return; const th=ctx.tgt.st.thorns||0;
      if(th>0&&ctx.tgt.hp>0) applyHeal(s,ctx.tgt,Math.ceil(th/3)); }},
  {id:'r_scentofblood',n:'Scent of Blood', rar:1, a:'exec', d:'RULE: enemies below half HP take 4 more damage from every attack.',
    mload:0, ex:[],
    modDmg:ctx=> (ctx.tgt.side==='e'&&ctx.tgt.hp<ctx.tgt.maxHp*0.5? ctx.v+4 : ctx.v)},
  {id:'r_rotmouth',n:'Rotmouth', rar:1, a:'poison', d:'RULE: every Mouth damage face also applies Poison 2.',
    mload:0, ex:[], mfPhase:'kw',
    modFace:u=>u.die.forEach(f=>{ if(f.p==='mouth'&&f.t==='dmg'&&!f.k.some(k=>k.startsWith('poison')))f.k.push('poison:2'); })},
  {id:'r_bloodhymn',n:'Blood Hymn', rar:1, a:'crit', d:'RULE: critical hits grant 2 Mana.',
    mload:0, ex:[], eng:'ENG-1',
    onHit:(s,ctx)=>{ if(ctx.crit&&ctx.dealt>0){ s.mana+=2; } }},
  {id:'r_gustwing',n:'Gustwing', rar:1, a:'aoe', d:'RULE: Cleave attacks deal 75% damage to neighbours instead of 50%.',
    mload:1, ex:['cleaveRatio'], eng:'ENG-9', cleaveRatio:0.75},
  {id:'r_squallmark',n:'Squallmark', rar:1, a:'aoe', d:'RULE: every Eyes face that heals or weakens gains Area.',
    mload:0, ex:[], mfPhase:'kw',
    modFace:u=>u.die.forEach(f=>{ if(f.p==='eyes'&&(f.t==='heal'||f.t==='debuff')&&!f.k.includes('aoe'))f.k.push('aoe'); })},

  /* ---------------- EPIC — Band [22.44, 30.36] (§6.3) ---------------- */
  {id:'r_fang', n:'Venom Fang', rar:2, a:'poison', d:'All Poison faces apply 1 more stack.',
    mload:0, ex:[], mfPhase:'add',
    modFace:u=>u.die.forEach(f=>{if(f.t==='poison')f.v+=1;})},
  {id:'r_regrow', n:'Regrowth Bud', rar:2, a:'shield', d:'The whole party has Regen 2 every turn. Each Axie gains 2 Max HP.',
    mload:0, ex:['regenFloor'], mfPhase:'add',
    modFace:u=>{u.maxHp+=2;},
    onTurnStart:s=>s.party.forEach(u=>{ if(u.hp>0) u.st.regen=Math.max(u.st.regen||0,2); })},
  {id:'r_bastionplate',n:'Bastion Plate', rar:2, a:'shield', d:'RULE: whenever you create Shield, deal 50% of its value to a random enemy.',
    mload:0, ex:['shieldSplash'], onShield:(s,ctx)=>ctx.splash(0.5)},
  {id:'r_hollowbone',n:'Hollow Bone', rar:2, a:'pierce', d:'RULE: Pierce attacks ignore Thorns and deal 3 more damage.',
    mload:1, ex:['piercePlus'], piercePlus:3},
  {id:'r_pyroclasm',n:'Pyroclasm', rar:2, a:'burn', d:'RULE: when Burn deals damage, it spreads half its stacks to adjacent targets. Every Horn damage face deals 1 more.',
    mload:1, ex:['burnSpread'], mfPhase:'add', burnSpread:1,
    modFace:u=>u.die.forEach(f=>{ if(f.p==='horn'&&f.t==='dmg')f.v+=1; })},
  {id:'r_chainreact',n:'Chain Reaction', rar:2, a:'aoe', d:'RULE: dying enemies explode for 5 damage to everything.',
    mload:0, ex:[], onKill:(s,ctx)=>ctx.explode(5)},
  {id:'r_growthcore',n:'Growth Core', rar:2, a:'growth', d:'RULE: every damage face gains Growth and 1 damage. Each Axie gains 2 Max HP.',
    mload:0, ex:['growthInject'], mfPhase:'kw', mfPhase2:'add',
    modFace:u=>u.die.forEach(f=>{ if(f.t==='dmg'&&!f.k.includes('growth'))f.k.push('growth'); }),
    modFace2:u=>{ u.die.forEach(f=>{ if(f.t==='dmg')f.v+=1; }); u.maxHp+=2; }},
  {id:'r_swarmnest', n:'Swarm Nest', rar:2, a:'summon', d:'RULE: start every fight with 2 Axie Eggs on your side.',
    mload:0, ex:[], startSummon:2},
  {id:'r_infinitedie',n:'Infinite Die', rar:2, a:'mana', d:'Gain 2 maximum Rerolls, 1 Mana at the start of every fight, and rerolling no longer clears your undo history.',
    mload:0, ex:['safeReroll'], rerollUp:2, safeReroll:1,
    onTurnStart:s=>{ if(s.turn===1){ s.mana+=1; } }},
  {id:'r_thousandcuts',n:'Thousand Cuts', rar:2, a:'pierce', d:'RULE: every Pierce face strikes twice, each strike for half damage plus 2.',
    mload:1, ex:[], mfPhase:'kw', mfPhase2:'add',
    modFace:u=>u.die.forEach(f=>{ if(f.t==='dmg'&&f.k.includes('pierce')&&!f.k.some(k=>k.startsWith('multi')))f.k.push('multi:2'); }),
    modFace2:u=>u.die.forEach(f=>{ if(f.t==='dmg'&&f.k.includes('pierce'))f.v=Math.ceil(f.v/2)+2; })},
  {id:'r_quickenroot',n:'Quickenroot', rar:2, a:'growth', d:'RULE: from the second turn on, the face each Axie has rolled grows by 1 permanently.',
    mload:0, ex:[],
    onRollEnd:s=>{ if(s.turn<=1) return;
      aliveP(s).forEach(u=>{ if(u.rolled>=0&&!u.used&&u.die[u.rolled].v>0){ u.growth[u.rolled]=(u.growth[u.rolled]||0)+1; ft(s,u,'GROW','buf'); } }); }},
  {id:'r_apexbrood',n:'Apex Brood', rar:2, a:'summon', d:'RULE: Axie Eggs have 8 more Max HP and their attacks deal 2 more.',
    mload:0, ex:[],
    onTurnStart:s=>s.party.forEach(u=>{ if(u.token&&u.hp>0&&!u.eggBuff){ u.eggBuff=1; u.maxHp+=8; u.hp+=8; u.die.forEach(f=>{ if(f.t==='dmg')f.v+=2; }); EVhp(s,u); } })},
  {id:'r_glassspine',n:'Glass Spine', rar:2, a:'thorns', d:'RULE: any Axie you give Shield to has at least Thorns 4.',
    mload:0, ex:['thornsFloorShield'], eng:'ENG-6',
    onShield:(s,ctx)=>{ if(ctx.tgt&&ctx.tgt.hp>0) ctx.tgt.st.thorns=Math.max(ctx.tgt.st.thorns||0,4); }},
  {id:'r_retributor',n:'Retributor', rar:2, a:'thorns', d:'RULE: when a shielded Axie Thorns an attacker, the two enemies beside it take a third as much.',
    mload:0, ex:[], eng:'ENG-5',
    onThorns:(s,ctx)=>{ if(!(ctx.tgt.shield>0)) return; const d=Math.ceil(ctx.th/3); if(d<=0) return;
      neighborsOf(aliveE(s),ctx.src).forEach(x=>dealDamage(s,null,x,d,{pierce:1,attack:false})); }},
  {id:'r_cullingorder',n:'Culling Order', rar:2, a:'exec', d:'RULE: whenever an enemy dies, your most wounded Axie heals 4 and gains 4 Shield.',
    mload:0, ex:[],
    onKill:(s,ctx)=>{ const p=aliveP(s).filter(u=>!u.token); if(!p.length) return;
      let w=p[0]; for(const u of p) if(u.hp/u.maxHp < w.hp/w.maxHp) w=u;
      applyHeal(s,w,4); applyShield(s,w,4); }},
  {id:'r_deathspiral',n:'Death Spiral', rar:2, a:'exec', d:'RULE: the first time each enemy drops below half HP, it takes 7 damage immediately.',
    mload:0, ex:[],
    onHit:(s,ctx)=>{ const t=ctx.tgt;
      if(t&&t.side==='e'&&t.hp>0&&t.hp<t.maxHp*0.5&&!t.spiraled){ t.spiraled=1; dealDamage(s,null,t,7,{pierce:1,attack:false}); } }},
  {id:'r_pandemic',n:'Pandemic', rar:2, a:'poison', d:'RULE: when a poisoned enemy dies, every other enemy gains half its Poison.',
    mload:0, ex:[],
    onKill:(s,ctx)=>{ const p=ctx.tgt.st.poison||0; if(p<=0) return; const half=Math.ceil(p/2);
      aliveE(s).forEach(x=>{ if(x!==ctx.tgt) addStatus(s,x,['poison:'+half]); }); }},
  {id:'r_hearthcore',n:'Hearthcore', rar:2, a:'burn', d:'RULE: Burn deals its damage twice per turn; the second tick deals 70%.',
    mload:1, ex:['burnTicks'], eng:'ENG-7', burnTicks:2, burnTickRatio:0.7},
  {id:'r_manaspring',n:'Mana Spring', rar:2, a:'mana', d:'RULE: at the start of every turn, gain 2 Mana.',
    mload:0, ex:[],
    onTurnStart:s=>{ const p=aliveP(s).filter(u=>!u.token); if(!p.length) return; s.mana+=2; ft(s,p[0],'+2 MP','man'); }},
  {id:'r_keeneye',n:'Keen Eye', rar:2, a:'crit', d:'RULE: if no Axie rolled a critical hit this turn, your first attack this turn crits. Critical hits deal 4 more damage.',
    mload:0, ex:['critPity'], eng:'ENG-21', critFlatPity:4,
    onRollEnd:s=>{ const p=aliveP(s); p.forEach(u=>{ u.pityCrit=0; });
      if(p.some(u=>u.critNow)) return;
      const c=p.find(u=>u.rolled>=0&&!u.used&&u.die[u.rolled].t==='dmg');
      if(c){ c.critNow=true; c.pityCrit=1; ft(s,c,'CRIT','buf'); } }},
  {id:'r_shatterpoint',n:'Shatterpoint', rar:2, a:'crit', d:'RULE: critical hits ignore Shield and deal 5 more damage.',
    mload:0, ex:[], eng:'ENG-8', critPierce:1, critFlat:5},
  /* §3.7a cặp 4 — 15 mặt ⊂ 26 mặt của r_stormcall. Mệnh đề +1 damage là của riêng relic này và
     KHÔNG bị trùng, nhưng mệnh đề tiêm `cleave` thì có ⇒ một chiều là đủ và đúng. */
  {id:'r_windlash',n:'Windlash', rar:2, a:'aoe', d:'RULE: every Mouth damage face gains Cleave and deals 1 more.',
    mload:0, ex:[], exSub:['cleaveInject'], mfPhase:'kw', mfPhase2:'add',
    modFace:u=>u.die.forEach(f=>{ if(f.p==='mouth'&&f.t==='dmg'&&!f.k.includes('cleave')&&!f.k.includes('aoe'))f.k.push('cleave'); }),
    modFace2:u=>u.die.forEach(f=>{ if(f.p==='mouth'&&f.t==='dmg')f.v+=1; })},

  /* ---------------- LEGENDARY — Band [31.77, 42.97] (§6.4) ---------------- */
  {id:'r_echostone', n:'Echo Stone', rar:3, a:'crit', d:'RULE: the first face you use each turn triggers twice.',
    mload:0, ex:['echoRule'], firstEcho:1},
  {id:'r_apexpredator',n:'Apex Predator', rar:3, a:'crit', d:'RULE: 35% more crit chance, and crits deal triple damage instead of double.',
    mload:2, ex:['critChance','critMult'], critBonus:35, critMult:3},
  {id:'r_bloodpact', n:'Blood Pact', rar:3, a:'exec', d:'RISK: the whole party loses 15% Max HP, but all your damage is multiplied by 1.6.',
    mload:2, ex:['dmgMult'], mfPhase:'add', dmgMult:1.6,
    modFace:u=>{u.maxHp=Math.max(4,Math.round(u.maxHp*0.85));}},
  {id:'r_venomengine',n:'Venom Engine', rar:3, a:'poison', d:'RULE: Poison deals its damage twice per turn.',
    mload:1, ex:['poisonTicks'], poisonTicks:2},
  {id:'r_plaguelord',n:'Plague Lord', rar:3, a:'poison', d:'RULE: Poison never loses stacks. All Poison faces apply 1 more stack.',
    mload:1, ex:['plague'], mfPhase:'add', plague:1,
    modFace:u=>u.die.forEach(f=>{if(f.t==='poison')f.v+=1;})},
  {id:'r_mirrorshell',n:'Mirror Shell', rar:3, a:'thorns', d:'RULE: your Thorns deal double damage.',
    mload:1, ex:['thornsMult'], thornsMult:2},
  {id:'r_solarcore',n:'Solar Core', rar:3, a:'burn', d:'RULE: Burn deals double damage.',
    mload:1, ex:['burnMult'], burnMult:2},
  {id:'r_soulforge', n:'Soul Forge', rar:3, a:'shield', d:'RULE: Shield has no cap, you take 30% less damage, and all Shield faces give 2 more.',
    mload:2, ex:['dr'], mfPhase:'add', noShieldCap:1, dr:0.30,
    modFace:u=>u.die.forEach(f=>{ if(f.t==='shield')f.v+=2; })},
  {id:'r_stormcall', n:'Storm Call', rar:3, a:'aoe', d:'RULE: every single-target damage face gains Cleave.',
    mload:0, ex:['cleaveInject'], mfPhase:'kw',
    modFace:u=>u.die.forEach(f=>{ if(f.t==='dmg'&&!f.k.includes('aoe')&&!f.k.includes('cleave'))f.k.push('cleave'); })},
  {id:'r_manaflood',n:'Mana Flood', rar:3, a:'mana', d:'RULE: unspent Mana at the end of your turn deals that much damage to every enemy. Gain 3 Mana at the start of every fight.',
    mload:0, ex:['overflow'], manaOverflow:1,
    onTurnStart:s=>{ if(s.turn===1){ s.mana+=3; } }},
  {id:'r_ancientgene',n:'Ancient Gene', rar:3, a:'growth', d:'RULE: all six faces on every Axie are 30% stronger.',
    mload:2, ex:['globalFaceMult'], mfPhase:'mul',
    modFace:u=>u.die.forEach(f=>{ if(f.v>0)f.v=Math.ceil(f.v*1.3); })},
  {id:'r_worldpiercer',n:'World Piercer', rar:3, a:'pierce', d:'RULE: every damage face gains Pierce, and your Pierce no longer triggers Thorns.',
    mload:1, ex:['pierceInjectAll'], mfPhase:'kw', piercePlus:1,
    modFace:u=>u.die.forEach(f=>{ if(f.t==='dmg'&&!f.k.includes('pierce'))f.k.push('pierce'); })},
  {id:'r_dawnlance',n:'Dawn Lance', rar:3, a:'pierce', d:'RULE: your attacks against an enemy above half HP deal 90% more damage.',
    mload:2, ex:['dmgMultCond'],
    modDmg:ctx=> (ctx.tgt.side==='e'&&ctx.tgt.hp>ctx.tgt.maxHp*0.5? Math.ceil(ctx.v*1.9) : ctx.v)},
  {id:'r_worldtree',n:'World Tree', rar:3, a:'growth', d:'RULE: your Axie keep half of everything they grew, up to +3 per face, for the rest of the run.',
    mload:1, ex:[], eng:'ENG-3', growthKeep:1},
  {id:'r_hivequeen',n:'Hive Queen', rar:3, a:'summon', d:'RULE: your Axie Eggs inherit every relic that reshapes your dice, and you may keep 6 Eggs.',
    mload:2, ex:['eggInherit'], eng:'ENG-20', eggInherit:1, tokenCap:6},
  {id:'r_ironmaiden',n:'Iron Maiden', rar:3, a:'thorns', d:'RULE: at the start of every turn, the enemy with the most HP takes damage equal to your highest Thorns, up to 7.',
    mload:0, ex:[],
    onTurnStart:s=>{ const es=aliveE(s); if(!es.length) return;
      let th=0; for(const u of aliveP(s)) th=Math.max(th,u.st.thorns||0);
      th=Math.min(IRONMAIDEN_CAP,th); if(th<=0) return;
      let big=es[0]; for(const e of es) if(e.hp>big.hp) big=e;
      dealDamage(s,null,big,th,{pierce:1,attack:false}); }},
  /* §3.7a cặp 1 — TRÙNG KHÍT với r_spines: cả hai viết st.thorns=Math.max(...,2), cùng luật cùng N.
     Không có chiều nâng cấp ⇒ `ex` ĐỐI XỨNG (thornsFloorFlat), không phải `exSub`. (D1 đã duyệt ở
     roster §17.5; §17.2 đã gán token, bản ship bỏ sót.) Mệnh đề Poison-on-Thorns vẫn là của riêng
     relic này nên nó KHÔNG thành dead draw theo chiều ngược lại — nhưng mệnh đề sàn Thorns thì có,
     và §3.7 chặn ở điểm phát nên chỉ cần một trong hai được đề nghị. */
  {id:'r_scalecrown',n:'Scale Crown', rar:3, a:'thorns', d:'RULE: every Axie gains the Reptile SCALES passive — always Thorns 2, and your Thorns also apply Poison 1.',
    mload:0, ex:['thornsFloorFlat'], eng:'ENG-5',
    onTurnStart:s=>s.party.forEach(u=>{ if(u.hp>0) u.st.thorns=Math.max(u.st.thorns||0,2); }),
    onThorns:(s,ctx)=>{ if(ctx.tgt.cls!=='reptile'&&ctx.src&&ctx.src.hp>0) addStatus(s,ctx.src,['poison:1']); }},
  /* §11 mục 25 — superset của r_gorehook PHẢI mang token, nếu không `exSub:['execInjectAll']`
     của r_gorehook không có gì để trỏ tới và im lặng thành no-op. §17.2 đã gán, bản ship bỏ sót.
     Token một chủ sở hữu là HỢP LỆ ở đây (§3.7a): nó là ĐÍCH của một exSub, không phải rác. */
  {id:'r_apexferal',n:'Apex Feral', rar:3, a:'exec', d:'RULE: every damage face gains Execute, and any enemy left at 15% HP or less dies immediately.',
    mload:0, ex:['execInjectAll'], mfPhase:'kw',
    modFace:u=>u.die.forEach(f=>{ if(f.t==='dmg'&&!f.k.includes('exec'))f.k.push('exec'); }),
    onHit:(s,ctx)=>{ const t=ctx.tgt;
      if(t&&t.side==='e'&&t.hp>0&&t.hp<=t.maxHp*0.15) dealDamage(s,null,t,t.hp,{pierce:1,attack:false}); }},
  {id:'r_conduitcrown',n:'Conduit Crown', rar:3, a:'mana', d:'RULE: each of your Lunacia cards may be used twice per turn, and you gain 2 Mana at the start of every turn.',
    mload:1, ex:['actReuse'], eng:'ENG-16', actReuse:2,
    onTurnStart:s=>{ const p=aliveP(s).filter(u=>!u.token); if(!p.length) return; s.mana+=2; ft(s,p[0],'+2 MP','man'); }},

  /* ---------------- ACTIVE (thẻ Lunacia) — §6.5 / §6.7 ----------------
     ĐỊNH GIÁ TRÊN SỰ THẬT ENGINE: usedActives reset MỖI LƯỢT, nên một active là
     "1 lần mỗi lượt, mọi lượt", chặn duy nhất bởi mana — không phải "1 lần mỗi trận". */
  {id:'a_restore',n:'Anemone Restore',rar:0,a:'shield',d:'[MP 2] Heal one Axie for 9 HP.',
    mload:0, ex:[], act:{cost:2,kind:'heal',v:9,tgt:'ally'}},
  {id:'a_freeze', n:'Cryo Spore',     rar:0,a:'mana',  d:'[MP 4] Stun one enemy.',
    mload:0, ex:[], act:{cost:4,kind:'stun',tgt:'enemy'}},
  {id:'a_chaos',  n:'Chaos Gene',     rar:1,a:'mana',  d:'[MP 1] Gain 4 Rerolls this turn.',
    mload:0, ex:[], act:{cost:1,kind:'reroll',v:4,tgt:'self'}},
  {id:'a_wall',   n:'Lunacia Wall',   rar:1,a:'shield',d:'[MP 6] Grant 5 Shield to the whole party.',
    mload:0, ex:[], act:{cost:6,kind:'shieldall',v:5,tgt:'self'}},
  {id:'a_pinning',n:'Pinning Lance',  rar:1,a:'pierce',d:'[MP 3] Destroy one enemy Shield and deal damage equal to the Shield destroyed, minimum 6.',
    mload:0, ex:[], eng:'ENG-13', act:{cost:3,kind:'shatter',min:6,tgt:'enemy'}},
  {id:'a_clutch', n:'Clutch Call',    rar:1,a:'summon',d:'[MP 4] Summon 1 Axie Egg.',
    mload:0, ex:[], eng:'ENG-12', act:{cost:4,kind:'summon',v:1,tgt:'self'}},
  {id:'a_bramblewall',n:'Bramble Wall',rar:1,a:'thorns',d:'[MP 3] Every Axie Thorns become at least 5.',
    mload:0, ex:[], eng:'ENG-10', act:{cost:3,kind:'kw',mode:'min',kw:'thorns:5',scope:'party',tgt:'self'}},
  {id:'a_perfectstrike',n:'Perfect Strike',rar:1,a:'crit',d:'[MP 5] Deal 8 damage to one enemy. This attack always crits.',
    mload:0, ex:[], eng:'ENG-14', act:{cost:5,kind:'dmg',v:8,crit:1,tgt:'enemy'}},
  {id:'a_plague', n:'Spore Bloom',    rar:2,a:'poison',d:'[MP 6] Apply Poison 3 to every enemy.',
    mload:0, ex:[], act:{cost:6,kind:'poisonall',v:3,tgt:'self'}},
  {id:'a_chomp',  n:'Chomp Strike',   rar:2,a:'pierce',d:'[MP 3] Deal 12 piercing damage.',
    mload:0, ex:[], act:{cost:3,kind:'dmg',v:12,pierce:1,tgt:'enemy'}},
  {id:'a_bloom',  n:'Bloom Surge',    rar:2,a:'growth',d:'[MP 5] The face each Axie has rolled grows by 3 permanently.',
    mload:0, ex:[], eng:'ENG-11', act:{cost:5,kind:'grow',v:3,tgt:'self'}},
  {id:'a_coupdegrace',n:'Coup de Grâce',rar:2,a:'exec',d:'[MP 5] Deal 14 damage to one enemy, executing.',
    mload:0, ex:[], eng:'ENG-14', act:{cost:5,kind:'dmg',v:14,exec:1,tgt:'enemy'}},
  {id:'a_pyre',   n:'Pyre Bloom',     rar:2,a:'burn',  d:'[MP 7] Apply Burn 6 to every enemy.',
    mload:0, ex:[], eng:'ENG-10', act:{cost:7,kind:'kw',mode:'add',kw:'burn:6',scope:'allEnemies',tgt:'self'}},
  {id:'a_aegisfont',n:'Aegis Font',   rar:2,a:'shield',d:'[MP 8] Grant 8 Shield to the whole party.',
    mload:0, ex:[], act:{cost:8,kind:'shieldall',v:8,tgt:'self'}},
  {id:'a_nova',   n:'Gene Nova',      rar:3,a:'aoe',   d:'[MP 8] Deal 10 damage to every enemy.',
    mload:0, ex:[], act:{cost:8,kind:'dmgall',v:10,tgt:'self'}},
  {id:'a_ult',    n:'LUNACIA ULTIMA', rar:3,a:'mana',  d:'[MP 18] Deal 40 piercing damage to one target and grant 10 Shield to the whole party.',
    mload:0, ex:[], act:{cost:18,kind:'ult',v:40,tgt:'enemy'}},
];
const RELIC_BY_ID = {}; RELICS.forEach(r=>RELIC_BY_ID[r.id]=r);
/* INV-5: khoá sắp xếp thứ ba. Hằng của DỮ LIỆU (chỉ số trong RELICS), không phụ thuộc save. */
const RELIC_INDEX = {}; RELICS.forEach((r,i)=>RELIC_INDEX[r.id]=i);

/* ================= EVENT ROOM ================= */
const EVENTS = [
  {k:'shrine',n:'LUNACIA SHRINE',ic:'⛩',d:'An ancient altar. Power always has a price.',
   opts:[
     {t:'Accept the blessing',d:'Permanently gain 1 maximum Reroll',fx:'bless_reroll'},
     {t:'Make the wager',d:'The whole party loses 20% Max HP. Receive a Legendary relic.',fx:'gamble_legend'},
     {t:'Pray',d:'Heal to full and give one Axie 8 Max HP',fx:'pray'},
   ]},
  {k:'merchant',n:'CHIMERA MERCHANT',ic:'⚖',d:'He deals in genes. Prices are in Gene Shard.',opts:null,shop:1},
  {k:'treasure',n:'ANCIENT CRYPT',ic:'❖',d:'A sealed gene vault.',
   opts:[
     {t:'Open the vault',d:'Receive a random relic at a better than usual rarity',fx:'chest'},
     {t:'Smash it open',d:'Receive 60 Gene Shard',fx:'shards60'},
   ]},
  {k:'campfire',n:'CAMPFIRE',ic:'✚',d:'Rest, or forge your genes.',
   opts:[
     {t:'Rest',d:'One Axie gains 12 Max HP',fx:'rest'},
     {t:'Forge',d:'One Axie gets 30% stronger on all six faces',fx:'forge'},
     {t:'Meditate',d:'The whole party gains 4 Max HP',fx:'meditate'},
   ]},
  {k:'casino',n:'MUTANT CASINO',ic:'☘',d:'The dice decide. Even odds.',
   opts:[
     {t:'Small bet',d:'50%: an Epic relic. 50%: the party loses 10% Max HP.',fx:'bet_small'},
     {t:'Big bet',d:'40%: a Mythic face. 60%: lose a random relic.',fx:'bet_big'},
     {t:'Walk away',d:'Receive 30 Gene Shard',fx:'shards30'},
   ]},
  {k:'mutant',n:'MUTAGEN POOL',ic:'❂',d:'Glowing liquid. Dip an Axie in?',
   opts:[
     {t:'Dip one Axie',d:'Overwrite 2 random faces with random Epic faces',fx:'dip'},
     {t:'Drink it',d:'RISK: one Axie loses 8 Max HP and gains a Legendary face',fx:'drink'},
     {t:'Leave',d:'The whole party heals to full',fx:'leave'},
   ]},
];

/* ================= CURVE + ASCENSION ================= */
const TUNE = { base:10.5, growth:1.150, growth2:1.05, knee:12, eliteMult:1.25 };
/* Formation Resonance (design/quick-specs/formation-resonance-2026-09-01.md):
   hai Axie liền kề trong s.roster cùng roll mặt cùng type trong cùng lượt →
   Axie thực thi SAU nhận +15% giá trị mặt. Xem engine.js checkResonance/resonancePairs.
   1.15 là ĐÚNG — đừng "sửa" thành 1.25. Spec §Tuning Knobs cho khoảng an toàn
   1.15-1.40 và chỉ định 1.15 cho trường hợp team dmg-stack quá mạnh; code ra đời
   đã là 1.15 (commit 5f54429), chưa bao giờ là 1.25. Chỗ THẬT SỰ lệch là spec
   §Formulas vẫn ghi "1.25 (mặc định)" và dùng 1.25 trong mọi ví dụ tính toán.
   Comment này từng ghi +25% và đã khiến một lượt review kết luận sai giá trị. */
const RESONANCE = { mult: 1.15, types: ['dmg','shield','heal','poison','mana'] };
/* 2026-09-01: growth2 1.065→1.05, eliteMult 1.40→1.25 — economy-designer diagnosis
   (docs/review-2026-08-31.md follow-up): Full Run winrate measured 3.6% via
   tools/sim.js vs 6% target, driven by 8 compounding hard gates over 20 waves +
   an over-strong first elite (wave 3 dip to 75%). Re-validate via
   `node tools/sim.js 500 mode=full asc=0` before further TUNE changes. */
const CURVE = {
  /* budget suy từ POWER LEVEL (số reward đã nhận), không từ step
     → tự thích ứng cả run 12 wave và 20 wave, và cả khi người chơi chọn event thay vì battle */
  budget: pw => TUNE.base * Math.pow(TUNE.growth, Math.min(pw,TUNE.knee)) * Math.pow(TUNE.growth2, Math.max(0,pw-TUNE.knee)),
  count:  pw => Math.max(2, Math.min(pw>=14?6:5, 2 + Math.floor(pw/4))),
  tune: TUNE,
};
const RUN_LEN = {
  short:{len:12,boss:[4,8,12],elite:[3,6,10],n:'SHORT RUN',d:'12 waves · about 15 minutes'},
  full: {len:20,boss:[5,10,15,20],elite:[3,7,12,17],n:'FULL RUN',d:'20 waves · about 35 minutes'},
};
const ASCENSION = [
  {a:1, d:'Enemies have 10% more HP'},
  {a:2, d:'Elite waves contain one extra enemy'},
  {a:3, d:'Enemies deal 10% more damage'},
  {a:4, d:'Bosses have 15% more HP'},
  {a:5, d:'Each fight, a random Axie starts with Weaken 2'},
  {a:6, d:'Enemies have 10% more HP (stacking)'},
  {a:7, d:'Rewards offer only 2 choices'},
  {a:8, d:'Enemies deal 15% more damage (stacking)'},
  {a:9, d:'Two extra waves become Elite waves'},
  {a:10,d:'Enemies have 20% more HP and deal 20% more damage (stacking)'},
];
function ascMods(a){
  const m={hp:1,dmg:1,eliteExtra:0,bossHp:1,weaken:0,rewards:3,extraElite:0};
  if(a>=1) m.hp*=1.10;
  if(a>=2) m.eliteExtra=1;
  if(a>=3) m.dmg*=1.10;
  if(a>=4) m.bossHp*=1.15;
  if(a>=5) m.weaken=1;
  if(a>=6) m.hp*=1.10;
  if(a>=7) m.rewards=2;
  if(a>=8) m.dmg*=1.15;
  if(a>=9) m.extraElite=2;
  if(a>=10){ m.hp*=1.20; m.dmg*=1.20; }
  return m;
}

/* ================= META UNLOCK ================= */
const UNLOCKS = [
  {id:'u_full',   n:'FULL RUN (20 waves)', cost:120, d:'Unlocks the 20-wave mode with 4 bosses.'},
  {id:'u_relic1', n:'Relic Pool II',      cost:150, d:'Adds Epic relics to the reward pool.'},
  {id:'u_face1',  n:'Gene Pool II',       cost:180, d:'Adds Legendary faces to the mutation pool.'},
  {id:'u_reroll', n:'Survival Instinct',  cost:220, d:'Start every run with 1 extra maximum Reroll.'},
  {id:'u_relic2', n:'Relic Pool III',     cost:280, d:'Adds Legendary relics to the reward pool.'},
  {id:'u_face2',  n:'Gene Pool III',      cost:350, d:'Adds Mythic faces to the mutation pool.'},
  {id:'u_start',  n:'Lunacia Legacy',     cost:400, d:'Start every run with a random Common relic.'},
  {id:'u_hp',     n:'Ancient Bloodline',  cost:500, d:'Your whole party permanently gains 3 Max HP.'},
  /* 2026-09-01: bảng cũ chỉ 8 mục, hết sạch sau ~15-20 run (theo audit progression) — thêm
     2 mục nối dài category số liệu đã có (reroll/HP), giữ nhịp dài hơn trước khi Echo
     Points (§10.3) trở thành sink duy nhất còn lại.
     ĐÃ TỰ KIỂM TRA QUA sim.js (3 seed, allUnlocks=1) trước khi chốt số — bản nháp đầu
     (thêm hẳn +7 maxHP và 1 relic khởi đầu thứ 2) làm winrate full-unlock nhảy 35%→62.8%
     (+79% relative chỉ từ 4 mục mới) — quá mạnh. Đã cắt "relic khởi đầu thứ 2" hoàn toàn
     (đo riêng: +1 relic = +9.4pp một mình, relic là cả 1 hiệu ứng build-wide, không phải
     số liệu đơn thuần, không an toàn để bán trực tiếp bằng Shard) và giảm HP xuống +2
     (không phải +7). Kết quả cuối: TB 3 seed 36.5%→42.4% (+16% relative) — hợp lý cho
     phần thưởng veteran dài hạn, không phá game. Reroll đo được ảnh hưởng gần như 0 qua
     nhiều seed, giữ nguyên +1. Xem docs/balance-log.md. */
  {id:'u_reroll2',n:'Overdrive Reflexes', cost:650, d:'Start every run with 1 more extra maximum Reroll (stacks with Survival Instinct).'},
  {id:'u_hp2',    n:'Titan Bloodline',    cost:600, d:'Your whole party permanently gains 2 more Max HP (stacks with Ancient Bloodline).'},
];

/* ================= ECHO POINTS (design/gdd/economy-progression.md §10.3) =================
   Sink cuối game cho Shard dư sau khi Collection đầy đủ. Công thức giữ nguyên 100% theo
   doc gốc (base=500, growth=1.035); GATE đã đổi từ "111/111 part α" (chưa tồn tại trong
   code — catalog 396-part chỉ dùng cho Import Axie, không phải FACE_POOL 55-face thật
   đang chạy) sang "Collection Log đầy đủ cả 3 mục" (Faces/Relics/Bosses), vì đó là hoàn
   thành-qua-chơi thật duy nhất hiện có trong game. Xem economy-progression.md §10.3 ghi
   chú 2026-09-01 phần 9. */
/* economy-progression.md §10.3 amendment (2026-09-07): Echo Box no longer
   gates on collectionComplete() — box #1 costs `introCost` (a deliberately
   tiny Shard price, reachable within the first run or two), every box after
   that reverts to the original `base`/`growth` curve unchanged. */
const ECHO = { base: 500, growth: 1.035, tierSize: 25, introCost: 50 };
/* Daily Mission (economy-progression.md §10.3, the "+60/ngày" faucet row —
   documented since the original economy pass but never implemented until
   now). One flat grant per UTC calendar day for completing any run (win or
   lose both count, matching this project's "losing still gets you closer"
   philosophy elsewhere) - no streak, no per-mission variety, by design: this
   is meant to be the smallest possible reason to open the game once a day,
   not a second progression system competing with World Tour/Battle Pass. */
const DAILY_MISSION_SHARD = 60;

/* Echo Box "double gacha" reveal (design/quick-specs/echo-box-double-gacha-
   ux.md) — a chest-grade reveal step shown BEFORE the existing cosmetic
   rarity card. Deliberately DETERMINISTIC from the rarity `rollEchoRarity()`
   already rolled (r0..r4), not an independent second RNG roll: the ux-
   designer's spec proposed an independent 6-way pre-roll with rarity floors
   on the top grades, which raises the system-wide Mythic rate ~4.5× — a real
   economy change that needs `economy-designer`/PM sign-off before it ships
   (see that doc's §6). This mapping ships the full visual "which chest did
   I get" beat now, at ZERO odds change, so the feature doesn't have to wait
   on that sign-off. Swapping to the independent-roll table later only means
   replacing chestGradeFor()'s body — nothing else in the reveal UI changes. */
const CHEST_GRADES=[
  {k:'bronze',n:'Bronze Chest',d:'A Bronze Chest. Steady odds inside.'},
  {k:'silver',n:'Silver Chest',d:'Silver Chest. Getting warmer.'},
  {k:'gold',n:'Gold Chest',d:'Gold Chest! A cut above.'},
  {k:'platinum',n:'Platinum Chest',d:'Platinum Chest — the good stuff.'},
  {k:'diamond',n:'Diamond Chest',d:'Diamond Chest! Rare air.'},
  {k:'lunacian',n:'Lunacian Chest',d:'LUNACIAN CHEST!! Rarest pull in the game.'},
];
/* r0..r4 (Common..Mythic) -> a CHEST_GRADES index. r2 (Epic) splits Gold/
   Platinum on a coin flip so all 6 chest arts see play, not just 5 of 6 —
   still zero odds impact, the coin flip only picks which PICTURE represents
   the same already-rolled Epic result. */
function chestGradeFor(rar){
  if(rar<=0) return CHEST_GRADES[0];
  if(rar===1) return CHEST_GRADES[1];
  if(rar===2) return CHEST_GRADES[Math.random()<0.5?2:3];
  if(rar===3) return CHEST_GRADES[4];
  return CHEST_GRADES[5];
}
const ECHO_TIER_NAMES = ['','Waning','Crescent','Gibbous','Full','Eclipse'];
/* Profile titles unlocked when echoTier() crosses each boundary (economy-progression.md
   §10.3). Index-matched to ECHO_TIER_NAMES; index 0 unused (tier 0 = no Echo title yet).
   ALL-CAPS to match the existing title voice (see BP max-level title 'LUNACIA SOVEREIGN'). */
const ECHO_TITLES = ['','WANING WANDERER','CRESCENT ADEPT','GIBBOUS HERALD','FULLMOON MUTANT','ECLIPSE SOVEREIGN'];

/* ================= WORLD TOUR ("Lunacia Atlas") — design/gdd/world-tour.md =================
   Two independent, linear 10-tile chapters. `TOUR_T[i-1]` is T(i)=i*(i+1)
   (§Formulas #1) — the map-RELATIVE run count (see tourProgress() in
   client.html, which subtracts each map's own baseline) needed to open tile
   `i`. Landmark tiles (§Detailed Rules "Ô mốc") gate on a field with no RNG
   branch, per that section's explicit rule — never frost_lord/mirror
   (BOSS_ALT). Regular-tile rewards implement the doc's own placeholder
   default ("toàn bộ ô thường tái dùng pool Echo Box" — explicitly left
   un-finalized, §Detailed Rules "Phần thưởng"): each reuses an existing,
   already-Echo-Box-reachable cosmetic key, so granting it here is a
   convenience unlock, not a new exclusive. Only the 3 landmark tiles grant
   the actual Tour-exclusive items (TOUR_EXCLUSIVE_DECOR/_BACKGROUNDS in
   cosmetics.js + the literal 'TOUR CHAMPION' title). */
const TOUR_T=[2,6,12,20,30,42,56,72,90,110]; // T(i), i=1..10, index i-1
/* `node:{x,y}` (percent 0-100, top-left origin, relative to the rendered map
   <img>'s own box) — design/ux/world-tour-map.md §4. Hand-traced against the
   actual path curvature in the map art; a STARTING placement, not pixel-
   locked truth (spec's own words — nudge once viewed against the real
   rendered <img> in a browser, the live DOM box wins over these guesses). */
const TOUR_MAPS=[
  { map:1, name:'Lovely Forest I', art:'1',
    tiles:[
      {i:1, reward:{cat:'avatar',key:'slime'}, node:{x:6,y:87}},
      {i:2, reward:{cat:'decor',key:'ring_plain'}, node:{x:13,y:58}},
      {i:3, reward:{cat:'background',key:'bg_plant'}, node:{x:19,y:26}},
      {i:4, landmark:{type:'boss',boss:'gooey_king'}, reward:{cat:'decor',key:'tour_gooeytrophy'}, node:{x:40,y:58}},
      {i:5, reward:{cat:'avatar',key:'gray_wolf'}, node:{x:50,y:76}},
      {i:6, reward:{cat:'decor',key:'ring_dashed'}, node:{x:60,y:64}},
      {i:7, reward:{cat:'background',key:'bg_beast'}, node:{x:69,y:45}},
      {i:8, reward:{cat:'avatar',key:'treant'}, node:{x:78,y:30}},
      {i:9, reward:{cat:'decor',key:'ring_twin'}, node:{x:87,y:18}},
      {i:10, landmark:{type:'ascMax',min:1}, reward:{cat:'background',key:'tour_ascthreshold'}, node:{x:95,y:9}},
    ] },
  { map:2, name:'Lovely Forest II', art:'2',
    tiles:[
      {i:1, reward:{cat:'avatar',key:'aqua_wolf'}, node:{x:5,y:62}},
      {i:2, reward:{cat:'decor',key:'halo_dotted'}, node:{x:13,y:38}},
      {i:3, reward:{cat:'background',key:'bg_aqua'}, node:{x:21,y:14}},
      {i:4, reward:{cat:'avatar',key:'dryad_fighter'}, node:{x:31,y:30}},
      {i:5, reward:{cat:'decor',key:'frame_vine'}, node:{x:41,y:50}},
      {i:6, reward:{cat:'background',key:'bg_reptile'}, node:{x:50,y:68}},
      {i:7, reward:{cat:'avatar',key:'dryad_mage'}, node:{x:59,y:80}},
      {i:8, reward:{cat:'decor',key:'frame_shard'}, node:{x:69,y:64}},
      {i:9, reward:{cat:'background',key:'bg_bug'}, node:{x:80,y:42}},
      {i:10, landmark:{type:'boss',boss:'agony'}, reward:{cat:'title',key:'TOUR CHAMPION'}, node:{x:93,y:16}},
    ] },
];
/* badgeTier() §Formulas #6 — product owner resolved world-tour.md's open
   Question #3 (2026-09-08): option (a), badge now reads fullAscMax so it
   always agrees with the Map2 gate (questStep(), which already reads
   fullAscMax) instead of the old ascMax-based check that let a Short-Run-only
   player see Gold on Map1 while Map2 stayed locked. Acceptance Criteria #8's
   test vectors (written against ascMax) need updating to match — see
   world-tour.md. */
const TOUR_GOLD_THRESHOLD={1:3,2:5};
/* questStep() §Formulas #3 (world-tour.md, v6) — W, the META.wins floor for
   step 2 of the Map1->Map2 quest chain. Replaces v4/v5's single-axis chain
   (3 thresholds stacked on META.fullAscMax alone, which let one high-Ascension
   win skip the whole chain) with 3 different axes: wins (volume) -> ascMax
   (skill ceiling, any mode) -> fullAscMax (skill + endurance in Full mode).
   Untuned constant (§Tuning Knobs: safe range 3-15) — no real playtest/sim
   data yet on wins-before-Map1-completion, revisit once available. */
const TOUR_QUEST_WINS=5;

if (typeof module!=='undefined') module.exports={B,F,FR,RARITY,RAR_COL,RELIC_SHOP_COST,RELIC_COUNT_PRE_EXPANSION,RELIC_MLOAD_CAP,RELIC_CAP,THORNS_CAP,IRONMAIDEN_CAP,GROWTH_KEEP_CAP,
  MF_PHASE_RANK,KW_EX,RELIC_INDEX,CLASSES,CLASS_COLOR,PASSIVE,ARCH,
  HEROES,TIER_UP,T1,FACE_POOL,MYTHIC_KW,RUNES,MON,NORMAL_POOL,ELITE_POOL,BOSSES,BOSS_BY_K,
  BOSS_ORDER_12,BOSS_ORDER_20,BOSS_ALT,RELICS,RELIC_BY_ID,EVENTS,CURVE,RUN_LEN,ASCENSION,ascMods,UNLOCKS,RESONANCE,
  SLOT_CLASS_TEMPLATE,ORIGIN_CLASS_MAP,ORIGIN_TIER3_MULT,ECHO,ECHO_TIER_NAMES,ECHO_TITLES};

/* ================= BATTLE PASS PARTS (4+1 mặt độc quyền, mỗi cái 1 lối chơi) ================= */
const BP_FACES = {
  bp_plague:{id:'bp_plague',n:'DOOMSDAY VENOM',arch:'poison',
    face:{p:'tail',t:'poison',v:10,k:['aoe','plague','pierce'],r:4,bp:'bp_plague'},
    d:'Apply Poison 10 to every enemy. It never loses stacks, and it also deals piercing damage equal to the stack count.'},
  bp_apex:{id:'bp_apex',n:'EXECUTIONER HORN',arch:'crit',
    face:{p:'horn',t:'dmg',v:24,k:['crit:100','cleave','exec'],r:4,bp:'bp_apex'},
    d:'Deal 24 damage. Always crits, cleaves, and executes (60% more damage below 50% HP).'},
  /* 2026-09-04: arch 'shield' -> 'thorns' (relic-system.md §11 mục 5). Sau bảng ưu tiên §3.4,
     faceArch(bp_bulwark.face) trả 'thorns' vì mặt mang thorns:6; nhãn tự khai phải nói cùng
     một điều với faceArch, nếu không hai nguồn mô tả cùng một mặt theo hai cách khác nhau. */
  bp_bulwark:{id:'bp_bulwark',n:'CITADEL PLATE',arch:'thorns',
    face:{p:'back',t:'shield',v:22,k:['aoe','bastion','thorns:6'],r:4,bp:'bp_bulwark'},
    d:'Grant 22 Shield to the whole party. Creating Shield also deals damage equal to its value. Thorns 6.'},
  bp_conduit:{id:'bp_conduit',n:'ENDLESS EARS',arch:'mana',
    face:{p:'ears',t:'mana',v:10,k:['cantrip','overflow','rerollup'],r:4,bp:'bp_conduit'},
    d:'Gain 10 Mana on landing, plus 1 Reroll. Unspent Mana explodes for area damage at the end of the turn.'},
  bp_swarm:{id:'bp_swarm',n:'PRIMAL NEST',arch:'summon',
    face:{p:'eyes',t:'summon',v:4,k:['cantrip'],r:4,bp:'bp_swarm'},
    d:'Summon 4 Axie Eggs the moment it lands, without using your action.'},
};
Object.values(BP_FACES).forEach(b=>FACE_POOL.push(b.face));

/* ================= BATTLE PASS TRACK (30 mốc) ================= */
const BP_XP = n => 45 + 22*(n-1);                    /* XP cần cho level n */
const BP_TOTAL = (()=>{ let t=0; for(let i=1;i<=30;i++) t+=BP_XP(i); return t; })();
const BP = [
  {lv:1, r:{t:'shard',v:120}},
  {lv:2, r:{t:'shard',v:200}},
  {lv:3, r:{t:'unlock',v:'u_relic1'}},
  {lv:4, r:{t:'shard',v:250}},
  {lv:5, r:{t:'face',v:'bp_plague'}, big:1},
  {lv:6, r:{t:'shard',v:250}},
  {lv:7, r:{t:'perk',v:'reroll',n:'Start with 1 extra Reroll'}},
  {lv:8, r:{t:'shard',v:300}},
  {lv:9, r:{t:'unlock',v:'u_face1'}},
  {lv:10,r:{t:'perk',v:'relic0',n:'Start every run with a Common relic'}, big:1},
  {lv:11,r:{t:'shard',v:350}},
  {lv:12,r:{t:'face',v:'bp_apex'}, big:1},
  {lv:13,r:{t:'shard',v:350}},
  {lv:14,r:{t:'unlock',v:'u_relic2'}},
  {lv:15,r:{t:'perk',v:'hp4',n:'Whole party gains 4 Max HP'}, big:1},
  {lv:16,r:{t:'shard',v:400}},
  {lv:17,r:{t:'unlock',v:'u_face2'}},
  {lv:18,r:{t:'shard',v:400}},
  {lv:19,r:{t:'face',v:'bp_bulwark'}, big:1},
  {lv:20,r:{t:'unlock',v:'u_full'}, big:1},
  {lv:21,r:{t:'shard',v:450}},
  {lv:22,r:{t:'perk',v:'reroll',n:'Start with 1 more Reroll (2 total)'}},
  {lv:23,r:{t:'shard',v:500}},
  {lv:24,r:{t:'perk',v:'hp4',n:'4 more Max HP (8 total)'}},
  {lv:25,r:{t:'perk',v:'relic1',n:'Starting relic upgraded to Rare'}, big:1},
  {lv:26,r:{t:'face',v:'bp_conduit'}, big:1},
  {lv:27,r:{t:'shard',v:600}},
  {lv:28,r:{t:'perk',v:'rrw',n:'Reroll rewards twice per wave'}},
  {lv:29,r:{t:'shard',v:700}},
  {lv:30,r:{t:'face',v:'bp_swarm'}, big:1, title:'LUNACIA SOVEREIGN'},
];
/* XP mỗi run */
function runXp(s,won){
  return Math.round(30 + 10*(s.step-(won?0:1)) + 30*s.eliteSteps.filter(x=>x<s.step).length
    + 60*s.bossSteps.filter(x=>x<s.step).length + (won?150:0) + s.asc*25 + (s.mode==='full'?40:0));
}

/* ================= GUIDE — đội hình mẫu cho người mới ================= */
const GUIDES = [
  {id:'wall',n:'LIVING WALL',arch:'shield',diff:'EASY · best starting team',
   team:['plant1','plant1','reptile1','bug1','aqua1'],
   why:'Two Plants stack Shield on top of each other (their BULWARK passive adds 2 to every Shield), Reptile punishes attackers with Thorns, and Bug weakens the enemy. You almost never die out of nowhere, so mistakes are forgiving.',
   how:['Take Back (Shield) faces over damage faces for the first four waves.',
        'Hunt for: Bastion Plate · Mirror Shell · Sharp Spines · Soul Forge.',
        'Win condition: Bastion Plate turns your Shield into damage, so you are both unkillable and dealing damage at once.',
        'Weakness: you kill slowly. Watch out for bosses that heal, like Warden and Plague Mother.']},
  {id:'plague',n:'PESTILENCE',arch:'poison',diff:'MEDIUM',
   team:['bug1','bug1','reptile1','plant1','aqua1'],
   why:'The Bug passive VIRULENT adds 2 Poison stacks instead of 1 when the target already has Poison, so your stacks grow exponentially. Reptile adds even more Poison through Thorns.',
   how:['Always put Poison on the SAME target so the passive keeps triggering.',
        'Hunt for: Venom Engine (Poison ticks twice) · Plague Lord (never decays, spreads) · Open Wound.',
        'Win condition: one target sitting on 40+ Poison stacks is dead, boss included.',
        'Weakness: weak in waves 1-3 before the stacks build. Take event nodes to get through the early game.']},
  {id:'apex',n:'APEX FANG',arch:'crit',diff:'MEDIUM · fastest kills',
   team:['beast1','beast1','bird1','plant1','aqua1'],
   why:'The Beast passive FERAL deals 60% more damage to targets below 50% HP, and Bird ignores Shield. You kill enemies before they get to act, which is the best defence in the game.',
   how:['Focus one enemy below 50% HP first, then finish it. Do not spread your damage around.',
        'Hunt for: Apex Predator (triple crits) · Lucky Scale · Death Mark · Blood Pact.',
        'Win condition: crit plus execute means a single die face can delete a boss.',
        'Weakness: low HP. One unlucky turn costs you an Axie.']},
  {id:'conduit',n:'THE CURRENT',arch:'mana',diff:'HARD · highest ceiling',
   team:['aqua1','aqua1','plant1','bird1','bug1'],
   why:'The Aqua passive CONDUIT adds 1 to every Mana gain and grants a Reroll for every 4 Mana you spend. More rerolls means you almost always find the face you need.',
   how:['Spend Mana constantly. Hoarded Mana is wasted Mana, unless you have Mana Flood.',
        'Hunt for active cards: Gene Nova · Lunacia Ultima · Spore Bloom, and Mana Flood.',
        'Win condition: two or three active cards per turn plus rerolls until you hit the perfect face.',
        'Weakness: needs time to set up, and depends on finding active cards.']},
];

