/* ============ AXIE DICE TACTICS v0.2 — DATA ============
   Face: {p:part, t:type, v:value, k:[keywords], r:rarity 0..4}
   rarity: 0 Common · 1 Rare · 2 Epic · 3 Legendary · 4 Mythic
   types: dmg shield heal mana poison buff debuff blank summon
   kw: cleave pierce aoe cantrip heavy growth decay vital lifesteal exec
       multi:N chain:N selfharm:N rerollup mana:N shieldself:N
       burn:N crit:N freeze stun blind:N weaken:N vulnerable:N thorns:N regen:N poison:N  */

const B  = {p:'blank',t:'blank',v:0,k:[],r:0};
const F  = (p,t,v,...k)=>({p,t,v,k,r:0});
const FR = (r,p,t,v,...k)=>({p,t,v,k,r});   /* face có rarity */

const RARITY = ['COMMON','RARE','EPIC','LEGENDARY','MYTHIC'];
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
  thorns:{n:'AEGIS',   ic:'✷', c:'#a86fd8', d:'Let the enemy kill itself on your armour.'},
};

/* ================= HEROES: 6 class × 3 tier ================= */
const HEROES = {
  plant1:{n:'Sprout',cls:'plant',tier:1,hp:17,art:0,die:[
    F('back','shield',4), F('back','shield',3), F('mouth','dmg',2), F('back','shield',2), F('horn','dmg',3), F('ears','mana',1,'cantrip')]},
  plant2:{n:'Bracken',cls:'plant',tier:2,hp:25,art:3,die:[
    F('back','shield',6), F('back','shield',5,'aoe'), F('mouth','dmg',4,'lifesteal'), F('eyes','heal',4),
    F('horn','dmg',5), F('ears','mana',1,'cantrip')]},
  plant3:{n:'Elder Bramble',cls:'plant',tier:3,hp:37,art:6,die:[
    F('back','shield',9), F('back','shield',7,'aoe'), F('mouth','dmg',6,'lifesteal'), F('eyes','heal',6,'aoe'),
    F('horn','dmg',8,'cleave'), F('ears','mana',2,'cantrip')]},

  beast1:{n:'Cub',cls:'beast',tier:1,hp:12,art:0,die:[
    F('horn','dmg',5,'heavy'), F('horn','dmg',3), F('mouth','dmg',3), F('mouth','dmg',2,'growth'), F('back','shield',2), F('mouth','dmg',2)]},
  beast2:{n:'Ravager',cls:'beast',tier:2,hp:18,art:3,die:[
    F('horn','dmg',8,'heavy'), F('horn','dmg',5), F('mouth','dmg',4,'growth'), F('mouth','dmg',6,'selfharm:2'),
    F('tail','dmg',3,'cleave'), F('back','shield',3)]},
  beast3:{n:'Alpha Fang',cls:'beast',tier:3,hp:26,art:6,die:[
    F('horn','dmg',13,'heavy'), F('horn','dmg',8,'vital'), F('mouth','dmg',6,'growth'), F('mouth','dmg',10,'selfharm:3'),
    F('tail','dmg',5,'cleave'), F('back','shield',5)]},

  aqua1:{n:'Fry',cls:'aqua',tier:1,hp:13,art:0,die:[
    F('ears','mana',1,'cantrip'), F('ears','mana',1,'cantrip'), F('eyes','heal',3), F('mouth','dmg',3),
    F('horn','dmg',4), F('mouth','dmg',2)]},
  aqua2:{n:'Tidecaller',cls:'aqua',tier:2,hp:19,art:3,die:[
    F('ears','mana',2,'cantrip'), F('ears','mana',1,'cantrip','rerollup'), F('eyes','heal',5), F('mouth','dmg',5),
    F('horn','dmg',6,'pierce'), F('tail','dmg',3,'aoe')]},
  aqua3:{n:'Abyss Herald',cls:'aqua',tier:3,hp:27,art:6,die:[
    F('ears','mana',3,'cantrip'), F('ears','mana',2,'cantrip','rerollup'), F('eyes','heal',8,'aoe'), F('mouth','dmg',8),
    F('horn','dmg',9,'pierce'), F('tail','dmg',5,'aoe')]},

  reptile1:{n:'Hatchling',cls:'reptile',tier:1,hp:16,art:0,die:[
    F('back','shield',4), F('tail','poison',2), F('mouth','dmg',3), F('eyes','buff',0,'thorns:2'), F('back','shield',2), F('horn','dmg',3)]},
  reptile2:{n:'Scaleguard',cls:'reptile',tier:2,hp:23,art:3,die:[
    F('back','shield',6), F('tail','poison',3,'aoe'), F('mouth','dmg',4), F('eyes','buff',0,'thorns:3'),
    F('back','shield',4,'thorns:2'), F('horn','dmg',5,'pierce')]},
  reptile3:{n:'Basilisk',cls:'reptile',tier:3,hp:33,art:6,die:[
    F('back','shield',9), F('tail','poison',5,'aoe'), F('mouth','dmg',7), F('eyes','debuff',0,'stun'),
    F('back','shield',6,'thorns:4'), F('horn','dmg',8,'pierce')]},

  bug1:{n:'Grub',cls:'bug',tier:1,hp:14,art:0,die:[
    F('eyes','debuff',0,'weaken:2'), F('tail','poison',2), F('mouth','dmg',3), F('back','shield',3), F('tail','poison',1), F('horn','dmg',3)]},
  bug2:{n:'Swarmling',cls:'bug',tier:2,hp:20,art:3,die:[
    F('eyes','debuff',0,'weaken:3'), F('eyes','debuff',0,'vulnerable:2'), F('tail','poison',3), F('mouth','dmg',4,'multi:2'),
    F('back','shield',4), F('horn','dmg',6)]},
  bug3:{n:'Hive Tyrant',cls:'bug',tier:3,hp:28,art:6,die:[
    F('eyes','debuff',0,'weaken:4','aoe'), F('eyes','debuff',0,'vulnerable:3'), F('tail','poison',4,'aoe'),
    F('mouth','dmg',5,'multi:3'), F('eyes','debuff',0,'blind:2'), F('horn','dmg',9)]},

  bird1:{n:'Chick',cls:'bird',tier:1,hp:11,art:0,die:[
    F('horn','dmg',3,'pierce'), F('mouth','dmg',4), F('tail','dmg',2,'aoe'), F('ears','mana',1,'cantrip'), F('mouth','dmg',2), F('horn','dmg',2,'pierce')]},
  bird2:{n:'Skirmisher',cls:'bird',tier:2,hp:16,art:3,die:[
    F('horn','dmg',5,'pierce'), F('mouth','dmg',6), F('tail','dmg',3,'aoe'), F('ears','mana',1,'cantrip'),
    F('mouth','dmg',3,'chain:3'), F('tail','dmg',2,'aoe')]},
  bird3:{n:'Storm Talon',cls:'bird',tier:3,hp:23,art:6,die:[
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
/* hooks: modFace(u) build-time · onRollEnd(s) · onTurnStart(s) · modDmg(ctx)->v
   onKill(s,ctx) · onShield(s,ctx) · onPoison(s,ctx) · onDmgTaken(s,ctx) · onTurnEnd(s)
   act:{cost,kind,...} = thẻ Lunacia active */
const RELICS = [
  /* ---- COMMON: mạnh nhưng thẳng ---- */
  {id:'r_claw', n:'Razor Claw', rar:0, a:'', d:'All damage faces deal 1 more.',
    modFace:u=>u.die.forEach(f=>{if(f.t==='dmg')f.v+=1;})},
  {id:'r_carapace', n:'Stone Carapace', rar:0, a:'shield', d:'All Shield faces grant 3 more.',
    modFace:u=>u.die.forEach(f=>{if(f.t==='shield')f.v+=3;})},
  {id:'r_heart', n:'Lunacia Heart', rar:0, a:'', d:'Gain 10 Max HP.',
    modFace:u=>{u.maxHp+=10;}},
  {id:'r_ear', n:'Keen Ears', rar:0, a:'mana', d:'All Mana faces give 1 more.',
    modFace:u=>u.die.forEach(f=>{if(f.t==='mana')f.v+=1;})},
  {id:'r_fang', n:'Venom Fang', rar:0, a:'poison', d:'All Poison faces apply 2 more stacks.',
    modFace:u=>u.die.forEach(f=>{if(f.t==='poison')f.v+=2;})},

  /* ---- RARE: đổi luật nhẹ ---- */
  {id:'r_voidgene', n:'Void Gene', rar:1, a:'mana', d:'RULE: blank faces are no longer dead. They grant 2 Mana and trigger on their own.',
    modFace:u=>u.die.forEach((f,i)=>{ if(f.t==='blank') u.die[i]={p:'ears',t:'mana',v:2,k:['cantrip'],r:1}; })},
  {id:'r_regrow', n:'Regrowth Bud', rar:1, a:'shield', d:'The whole party has Regen 2 every turn.',
    onTurnStart:s=>s.party.forEach(u=>{ if(u.hp>0) u.st.regen=Math.max(u.st.regen||0,2); })},
  {id:'r_spines', n:'Sharp Spines', rar:1, a:'thorns', d:'The whole party always has Thorns 3.',
    onTurnStart:s=>s.party.forEach(u=>{ if(u.hp>0) u.st.thorns=Math.max(u.st.thorns||0,3); })},
  {id:'r_pierceall',n:'Piercing Horn', rar:1, a:'pierce', d:'RULE: every Horn face gains Pierce.',
    modFace:u=>u.die.forEach(f=>{ if(f.p==='horn'&&!f.k.includes('pierce'))f.k.push('pierce'); })},
  {id:'r_cleaveall',n:'Sweeping Tail', rar:1, a:'aoe', d:'RULE: every Tail face gains Cleave.',
    modFace:u=>u.die.forEach(f=>{ if(f.p==='tail'&&!f.k.includes('cleave'))f.k.push('cleave'); })},
  {id:'r_bloodmouth',n:'Bloodmouth', rar:1, a:'', d:'RULE: every Mouth face gains Lifesteal.',
    modFace:u=>u.die.forEach(f=>{ if(f.p==='mouth'&&!f.k.includes('lifesteal'))f.k.push('lifesteal'); })},
  {id:'r_luckycharm',n:'Lucky Scale', rar:1, a:'crit', d:'RULE: every attack has a 20% chance to crit for double damage.',
    critBonus:20},
  {id:'r_ember', n:'Ember', rar:1, a:'burn', d:'RULE: every damaging attack also applies Burn 2.',
    onHit:(s,ctx)=>{ if(ctx.type==='dmg'&&ctx.dealt>0) ctx.addStatus('burn:2'); }},
  {id:'r_openwound',n:'Open Wound', rar:1, a:'poison', d:'RULE: targets with Poison take 30% more damage.',
    modDmg:ctx=> ctx.tgt.st.poison>0 ? Math.ceil(ctx.v*1.3) : ctx.v},
  {id:'r_wildfire',n:'Wildfire', rar:1, a:'burn', d:'RULE: Burn loses only 1 stack per turn instead of half.',
    burnSlow:1},

  /* ---- EPIC: đổi luật mạnh ---- */
  {id:'r_bastionplate',n:'Bastion Plate', rar:2, a:'shield', d:'RULE: whenever you create Shield, deal 60% of its value to a random enemy.',
    onShield:(s,ctx)=>ctx.splash(0.6)},
  {id:'r_venomengine',n:'Venom Engine', rar:2, a:'poison', d:'RULE: Poison deals its damage twice per turn.',
    poisonTicks:2},
  {id:'r_deathmark', n:'Death Mark', rar:2, a:'exec', d:'RULE: whenever an enemy dies, all damage faces gain 2 for the rest of the fight.',
    onKill:(s,ctx)=>s.party.forEach(u=>u.die.forEach(f=>{if(f.t==='dmg')f.v+=2;}))},
  {id:'r_chainreact',n:'Chain Reaction', rar:2, a:'aoe', d:'RULE: dying enemies explode for 8 damage to everything.',
    onKill:(s,ctx)=>ctx.explode(8)},
  {id:'r_echostone', n:'Echo Stone', rar:2, a:'crit', d:'RULE: the first face you use each turn triggers twice.',
    firstEcho:1},
  {id:'r_manaflood',n:'Mana Flood', rar:2, a:'mana', d:'RULE: unspent Mana at the end of your turn deals that much damage to every enemy.',
    manaOverflow:1},
  {id:'r_hollowbone',n:'Hollow Bone', rar:2, a:'pierce', d:'RULE: Pierce attacks ignore Thorns and deal 4 more damage.',
    piercePlus:4},
  {id:'r_swarmnest', n:'Swarm Nest', rar:2, a:'summon', d:'RULE: start every fight with 2 Axie Eggs on your side.',
    startSummon:2},
  {id:'r_growthcore',n:'Growth Core', rar:2, a:'growth', d:'RULE: every damage face gains Growth, permanently growing by 1 each use.',
    modFace:u=>u.die.forEach(f=>{ if(f.t==='dmg'&&!f.k.includes('growth'))f.k.push('growth'); })},
  {id:'r_mirrorshell',n:'Mirror Shell', rar:2, a:'thorns', d:'RULE: your Thorns deal triple damage.',
    thornsMult:3},
  {id:'r_holyfont', n:'Sacred Font', rar:2, a:'shield', d:'RULE: healing also grants Shield equal to the amount healed.',
    healShield:1},
  {id:'r_pyroclasm',n:'Pyroclasm', rar:2, a:'burn', d:'RULE: when Burn deals damage, it spreads half its stacks to adjacent targets.',
    burnSpread:1},

  /* ---- LEGENDARY: phá game ---- */
  {id:'r_infinitedie',n:'Infinite Die', rar:3, a:'', d:'RULE: gain 2 maximum Rerolls, and rerolling no longer clears your undo history.',
    rerollUp:2, safeReroll:1},
  {id:'r_bloodpact', n:'Blood Pact', rar:3, a:'exec', d:'RISK: the whole party loses 25% Max HP, but all your damage is multiplied by 1.6.',
    modFace:u=>{u.maxHp=Math.max(4,Math.round(u.maxHp*0.75));}, dmgMult:1.6},
  {id:'r_apexpredator',n:'Apex Predator', rar:3, a:'crit', d:'RULE: 35% more crit chance, and crits deal triple damage instead of double.',
    critBonus:35, critMult:3},
  {id:'r_plaguelord',n:'Plague Lord', rar:3, a:'poison', d:'RULE: Poison never loses stacks and spreads to adjacent targets.',
    plague:1, poisonSpread:1},
  {id:'r_soulforge', n:'Soul Forge', rar:3, a:'shield', d:'RULE: Shield has no cap, and you take 25% less damage.',
    noShieldCap:1, dr:0.25},
  {id:'r_stormcall', n:'Storm Call', rar:3, a:'aoe', d:'RULE: every single-target damage face gains Cleave.',
    modFace:u=>u.die.forEach(f=>{ if(f.t==='dmg'&&!f.k.includes('aoe')&&!f.k.includes('cleave'))f.k.push('cleave'); })},
  {id:'r_ancientgene',n:'Ancient Gene', rar:3, a:'growth', d:'RULE: all six faces on every Axie are 40% stronger.',
    modFace:u=>u.die.forEach(f=>{ if(f.v>0)f.v=Math.ceil(f.v*1.4); })},
  {id:'r_hivemind', n:'Hive Mind', rar:3, a:'summon', d:'RULE: each living Axie Egg gives the whole party 2 more damage.',
    hiveMind:2, startSummon:1},
  {id:'r_solarcore',n:'Solar Core', rar:3, a:'burn', d:'RULE: Burn deals double damage, and every attack applies Burn equal to 30% of the damage dealt.',
    burnMult:2, onHit:(s,ctx)=>{ if(ctx.type==='dmg'&&ctx.dealt>0) ctx.addStatus('burn:'+Math.max(1,Math.ceil(ctx.dealt*0.3))); }},

  /* ---- ACTIVE (thẻ Lunacia, tốn Mana) ---- */
  {id:'a_restore',n:'Anemone Restore',rar:0,a:'mana',d:'[MP 2] Heal one Axie for 10 HP.',act:{cost:2,kind:'heal',v:10,tgt:'ally'}},
  {id:'a_chomp',  n:'Chomp Strike',   rar:0,a:'mana',d:'[MP 3] Deal 12 piercing damage.',act:{cost:3,kind:'dmg',v:12,pierce:1,tgt:'enemy'}},
  {id:'a_wall',   n:'Lunacia Wall',   rar:1,a:'shield',d:'[MP 3] Grant 8 Shield to the whole party.',act:{cost:3,kind:'shieldall',v:8,tgt:'self'}},
  {id:'a_nova',   n:'Gene Nova',      rar:1,a:'aoe',d:'[MP 5] Deal 12 damage to every enemy.',act:{cost:5,kind:'dmgall',v:12,tgt:'self'}},
  {id:'a_freeze', n:'Cryo Spore',     rar:1,a:'mana',d:'[MP 4] Stun one enemy.',act:{cost:4,kind:'stun',tgt:'enemy'}},
  {id:'a_chaos',  n:'Chaos Gene',     rar:0,a:'mana',d:'[MP 2] Gain 2 Rerolls this turn.',act:{cost:2,kind:'reroll',v:2,tgt:'self'}},
  {id:'a_plague', n:'Spore Bloom',    rar:2,a:'poison',d:'[MP 4] Apply Poison 8 to every enemy.',act:{cost:4,kind:'poisonall',v:8,tgt:'self'}},
  {id:'a_ult',    n:'LUNACIA ULTIMA', rar:3,a:'crit',d:'[MP 10] Deal 40 piercing damage to one target and grant 10 Shield to the whole party.',
    act:{cost:10,kind:'ult',v:40,tgt:'enemy'}},
];
const RELIC_BY_ID = {}; RELICS.forEach(r=>RELIC_BY_ID[r.id]=r);

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
   Axie thực thi SAU nhận +25% giá trị mặt. Xem engine.js checkResonance/resonancePairs. */
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
];

/* ================= ECHO POINTS (design/gdd/economy-progression.md §10.3) =================
   Sink cuối game cho Shard dư sau khi Collection đầy đủ. Công thức giữ nguyên 100% theo
   doc gốc (base=500, growth=1.035); GATE đã đổi từ "111/111 part α" (chưa tồn tại trong
   code — catalog 396-part chỉ dùng cho Import Axie, không phải FACE_POOL 55-face thật
   đang chạy) sang "Collection Log đầy đủ cả 3 mục" (Faces/Relics/Bosses), vì đó là hoàn
   thành-qua-chơi thật duy nhất hiện có trong game. Xem economy-progression.md §10.3 ghi
   chú 2026-09-01 phần 9. */
const ECHO = { base: 500, growth: 1.035, tierSize: 25 };
const ECHO_TIER_NAMES = ['','Waning','Crescent','Gibbous','Full','Eclipse'];

if (typeof module!=='undefined') module.exports={B,F,FR,RARITY,RAR_COL,CLASSES,CLASS_COLOR,PASSIVE,ARCH,
  HEROES,TIER_UP,T1,FACE_POOL,MYTHIC_KW,RUNES,MON,NORMAL_POOL,ELITE_POOL,BOSSES,BOSS_BY_K,
  BOSS_ORDER_12,BOSS_ORDER_20,BOSS_ALT,RELICS,RELIC_BY_ID,EVENTS,CURVE,RUN_LEN,ASCENSION,ascMods,UNLOCKS,RESONANCE,
  SLOT_CLASS_TEMPLATE,ORIGIN_CLASS_MAP,ORIGIN_TIER3_MULT,ECHO,ECHO_TIER_NAMES};

/* ================= BATTLE PASS PARTS (4+1 mặt độc quyền, mỗi cái 1 lối chơi) ================= */
const BP_FACES = {
  bp_plague:{id:'bp_plague',n:'DOOMSDAY VENOM',arch:'poison',
    face:{p:'tail',t:'poison',v:10,k:['aoe','plague','pierce'],r:4,bp:'bp_plague'},
    d:'Apply Poison 10 to every enemy. It never loses stacks, and it also deals piercing damage equal to the stack count.'},
  bp_apex:{id:'bp_apex',n:'EXECUTIONER HORN',arch:'crit',
    face:{p:'horn',t:'dmg',v:24,k:['crit:100','cleave','exec'],r:4,bp:'bp_apex'},
    d:'Deal 24 damage. Always crits, cleaves, and executes (60% more damage below 50% HP).'},
  bp_bulwark:{id:'bp_bulwark',n:'CITADEL PLATE',arch:'shield',
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

