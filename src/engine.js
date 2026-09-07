/* ============ AXIE DICE TACTICS v0.2 — ENGINE (pure, no DOM) ============ */
/* design/gdd/leaderboard-system.md Edge Cases + ADR-0001 Key Interfaces: replay
   must use the exact engine build active when a run's seed was issued, so a
   later balance patch (docs/balance-log.md) never retroactively rescoreS an
   old submission. Bump this string any time engine.js's gameplay math changes
   (new TUNE values, new mechanic, etc.) — NOT for pure refactors with no
   behavior change. Server stores this per-submission and only accepts a
   replay if it can run the matching engine version. */
const ENGINE_VERSION = '2026-09-04-relic94';

function mkRng(seed){ let a=seed>>>0; return function(){ a=(a+0x6D2B79F5)>>>0; let t=a; t=Math.imul(t^t>>>15,t|1); t^=t+Math.imul(t^t>>>7,t|61); return ((t^t>>>14)>>>0)/4294967296; }; }
let RNG=mkRng(12345);
const rnd=()=>RNG(), ri=n=>Math.floor(rnd()*n), pick=a=>a[ri(a.length)];
const clone=o=>JSON.parse(JSON.stringify(o));
function shuffle(a){ for(let i=a.length-1;i>0;i--){ const j=ri(i+1); [a[i],a[j]]=[a[j],a[i]]; } return a; }

const kwVal=(f,n)=>{ for(const k of f.k){ if(k===n) return true; if(k.startsWith(n+':')) return +k.split(':')[1]; } return 0; };
const hasKw=(f,n)=>f.k.some(k=>k===n||k.startsWith(n+':'));

/* ================= RELIC HOOKS ================= */
const rlist = s => (s.relics||[]).map(id=>RELIC_BY_ID[id]).filter(Boolean);
const rsum  = (s,k)=>{ let v=0; for(const r of rlist(s)) if(r[k]) v+=r[k]; return v; };
const rhas  = (s,k)=>rlist(s).some(r=>r[k]);
const rmax  = (s,k,d)=>{ let v=d; for(const r of rlist(s)) if(r[k]&&r[k]>v) v=r[k]; return v; };
const rcall = (s,k,ctx)=>{ for(const r of rlist(s)) if(r[k]) r[k](s,ctx); };
/* INV-5 (relic-system.md §3.12) — modFace KHÔNG được chạy theo thứ tự nhặt.
   `rlist` là thứ tự người chơi nhặt relic, nên r_claw(+1) + r_ancientgene(×1.3) cho
   (v+1)×1.3 hoặc v×1.3+1 tuỳ dãy nhặt: RP của một relic không còn là một SỐ mà là một
   KHOẢNG. Không phải lỗi replay (cùng dãy vẫn tất định) nhưng phá INV-1 trực tiếp.
   Khoá sắp xếp [PHASE_RANK, rar, RELIC_INDEX] đều là hằng của DỮ LIỆU ⇒ kết quả độc lập
   tuyệt đối với thứ tự nhặt, thứ tự shop và bet_big. Một relic có thể khai 2 entry ở 2 pha
   (modFace/mfPhase + modFace2/mfPhase2) — r_thousandcuts vừa thêm keyword vừa sửa f.v. */
function modFaceOrder(s){
  const out=[];
  for(const r of rlist(s)){
    if(r.modFace)  out.push({r, ph:MF_PHASE_RANK[r.mfPhase ||'add']||0, sub:0, fn:r.modFace});
    if(r.modFace2) out.push({r, ph:MF_PHASE_RANK[r.mfPhase2||'add']||0, sub:1, fn:r.modFace2});
  }
  return out.sort((a,b)=> a.ph-b.ph || a.r.rar-b.r.rar
    || (RELIC_INDEX[a.r.id]-RELIC_INDEX[b.r.id]) || a.sub-b.sub);
}

/* ================= ROSTER → UNIT ================= */
let UID=1;
function newRosterEntry(key,vr,nftBonusPct){ return {uid:UID++,key,vr:vr||0,muts:[],bonusHp:0,nftBonusPct:nftBonusPct||0}; }

/* NFT HP Bonus (design/gdd/economy-progression.md §10.2a — ngoại lệ có phạm vi của D12).
   Chỉ áp dụng cho Axie NFT được CHỌN TRƯỚC vào đội hình (không áp dụng Axie tuyển ngẫu nhiên).
   ownedCount = tổng số Axie NFT người chơi sở hữu · specialGenes = 0-3 (thuộc tính Axie thật). */
const NFT_BONUS_BASE=3, NFT_BONUS_CAP=20;
function nftOwnershipMult(ownedCount){ return ownedCount>=20?1.5 : ownedCount>=5?1.25 : 1.0; }
/* E16 — nhận SỐ PART có gene thật (specialGeneCount), không phải field thô. v1 coi field là số
   nguyên 0–3 trong khi API trả chuỗi ⇒ luôn ra 1.0. Một định nghĩa, hai chỗ dùng. */
function nftRarityMult(specialGeneCount){ return [1.0,1.15,1.3,1.5][Math.max(0,Math.min(3,specialGeneCount|0))]; }
function nftHpBonusPct(ownedCount,specialGenes){
  const pct=NFT_BONUS_BASE*nftOwnershipMult(ownedCount)*nftRarityMult(specialGenes);
  return Math.min(NFT_BONUS_CAP,pct);
}

function buildUnit(re,s){
  const h=HEROES[re.key];
  const baseHp=h.hp+re.bonusHp;
  const nftHp=re.nftBonusPct? Math.round(baseHp*re.nftBonusPct/100) : 0;
  const u={uid:re.uid,side:'p',key:re.key,n:h.n,cls:h.cls,tier:h.tier,pas:PASSIVE[h.cls],
    artIdx:h.art+((re.vr||0)%3), maxHp:baseHp+nftHp, hp:0, shield:0,
    die:clone(h.die), st:{}, rolled:-1, used:false, heavy:false, frozen:false, growth:{}, critNow:false};
  for(const m of re.muts){
    if(m.type==='part') u.die[m.idx]=clone(m.face);
    else if(m.type==='rune'){ if(!u.die[m.idx].k.includes(m.kw)) u.die[m.idx].k.push(m.kw); if(u.die[m.idx].r<1)u.die[m.idx].r=1; }
    else if(m.type==='oc') u.die.forEach(f=>{ if(f.v>0) f.v=Math.ceil(f.v*(m.mult||1.5)); });
  }
  /* ENG-3 — growth bền qua các trận (r_worldtree). Gieo TRƯỚC modFace: growth là số cộng
     vào faceValue, không phải vào f.v, nên thứ tự với modFace không đổi kết quả. */
  if(re.grown) for(const k in re.grown) u.growth[k]=(u.growth[k]||0)+re.grown[k];
  if(s) for(const e of modFaceOrder(s)) e.fn(u);   /* INV-5, không phải thứ tự nhặt */
  if(s&&s.metaHpBonus) u.maxHp+=s.metaHpBonus;
  u.hp=u.maxHp;
  return u;
}
/* ================= IMPORT AXIE → DIE (design/gdd/part-skill-identity.md §3.1–§3.6) =================
   axieData = {id, class, parts:[{id,name,class,type,specialGenes}, ...]} — shape thật từ api/axie.js proxy.

   v2 thay bảng SLOT_CLASS_TEMPLATE (36 ô, nhưng chỉ 19 mặt engine-distinct — cả 6 class dùng chung
   một mặt ears `mana 1 cantrip`) bằng bảng part-identity do tools/gen_faces.mjs sinh ra: 285 identity
   → 285 mặt distinct. Dữ liệu đi vào bundle qua src/part_faces.js (build.py %PARTFACES%), cùng byte
   với assets/data/part_faces.json — `node tools/gen_faces.mjs --check` so cả hai, nên bundle cũ
   không thể ship im lặng.

   BẤT BIẾN (AC-1, BLOCKING): mọi thứ dưới đây PURE — không Math.random, không Date, không I/O.
   api/submit-run.js chạy lại action log phía server để chấm điểm ranked, nên nó phải dựng lại ĐÚNG
   viên dice từ đúng part data. Một nguồn ngẫu nhiên ở đây làm sai điểm một cách ÂM THẦM, không throw. */
const PFACES = (typeof PART_FACES !== 'undefined') ? PART_FACES : null;
const PFK    = PFACES ? PFACES.constants : {};
/* E2/N3 — thứ tự mặt phải tất định. API trả part theo thứ tự nào là chuyện của API; nếu ta không
   sort thì cùng một Axie ra hai viên dice khác nhau ⇒ replay phía server fail. */
const SLOT_ORDER = ['mouth','horn','back','tail','eyes','ears'];

function mapAxieClass(axieClassName){
  const c=(axieClassName||'').toLowerCase();
  if(CLASSES.includes(c)) return c;
  if(c==='aquatic') return 'aqua';
  if(ORIGIN_CLASS_MAP[c]) return ORIGIN_CLASS_MAP[c];
  return 'beast'; /* class thật không nhận diện được — an toàn thay vì crash */
}
/* §3.1 — normClass GIỮ NGUYÊN dawn/dusk/mech (khác mapAxieClass, cái đó collapse chúng về
   beast/reptile/bug). Khoá tra bảng cần class thật vì 18 part secret-class có face riêng. */
function normPartClass(x){ const c=String(x==null?'':x).trim().toLowerCase(); return c==='aquatic'?'aqua':c; }
function normSlot(x){ return String(x==null?'':x).trim().toLowerCase(); }
/* §3.1 — bỏ hậu tố stage (` α` `α` ` +` `+`) ở cuối, trim, collapse khoảng trắng đôi.
   'Nut Cracker α' → 'Nut Cracker'. Phải khớp BYTE-BY-BYTE với baseName() của gen_faces.mjs,
   nếu không mọi tra bảng đều trượt về fallback. */
function baseName(x){
  let t=String(x==null?'':x);
  for(;;){ const u=t.replace(/[\s]*[α+]\s*$/,''); if(u===t) break; t=u; }
  return t.trim().replace(/\s{2,}/g,' ');
}
function partKey(part){ return normPartClass(part&&part.class)+'|'+normSlot(part&&part.type)+'|'+baseName(part&&part.name); }

/* §3.4a / E16-bis — thang specialGenes 8 bậc. Bảng alias nằm trong PART_FACES.constants.SG_TIER
   (dữ liệu, không hardcode). MỌI giá trị không nhận diện được → tier 0; đó là mặc định an toàn và
   nó xoá luôn bug lạm phát 30% của v1 (`if(part.specialGenes!=null)` đúng với gần như mọi part). */
function sgTier(part){
  const raw=part&&part.specialGenes; if(raw==null) return 0;
  const list=Array.isArray(raw)?raw:[raw]; const tbl=PFK.SG_TIER||{}; let best=0;
  for(const x of list){
    let k;
    if(typeof x==='number'){ if(!(x>0)) continue; k=String(x); }
    else k=String(x).trim().toLowerCase().replace(/[\s_-]+/g,'');
    if(k===''||k==='none'||k==='null'||k==='false') continue;
    if(/^0+$/.test(k)) continue;            /* '000000' và mọi bitmask toàn 0 = KHÔNG có gene */
    const t=tbl[k]; if(t===undefined) continue;   /* chưa biết → tier 0 */
    if(t>best) best=t;
  }
  return best;
}
/* §3.4a-3 — gene `origin` và bucket `O`/`P` đo CÙNG một sự thật ("part thuộc dòng Axie Origin").
   Cộng dồn là tính tiền hai lần, nên trục tất định (bucket, tra từ catalog) thắng và gene bị
   trung hoà. Trên part bucket C thì tier vẫn áp — nghĩa là catalog đã lạc hậu. */
function sgTierEff(part,bucket){
  const t=sgTier(part), org=(PFK.SG_TIER&&PFK.SG_TIER.origin);
  if(org!=null && t===org && (bucket==='O'||bucket==='P')) return 0;
  return t;
}
/* E16 — MỘT định nghĩa cho cả hai chỗ dùng: đây và nftRarityMult(). Số part có gene thật, kẹp 0–3. */
function specialGeneCount(axieData){
  const parts=(axieData&&axieData.parts)||[]; let n=0;
  for(const p of parts) if(sgTier(p)>0) n++;
  return Math.max(0,Math.min(3,n));
}
const geneMult=t=>1+(PFK.SG_STEP||0)*t;
const rBonus  =t=>((PFK.SG_RBONUS||[0])[t])||0;

/* §3.4b — coherence/purity là thuộc tính của CẢ VIÊN DICE, không của từng part.
   Tính trên mapAxieClass() chứ không trên part.class thô: nhờ vậy part Dawn trên một Axie Dawn
   ĐẾM LÀ KHỚP mà không cần luật ngoại lệ nào. Die khuyết part giữ TỈ LỆ (không phạt hai lần:
   một lần vì có mặt BLANK vô dụng, một lần nữa vì coherence). */
function diePurity(parts,bodyCls){
  const n=parts.length; if(n===0) return 6;
  let match=0; for(const p of parts) if(mapAxieClass(p&&p.class)===bodyCls) match++;
  return n===6 ? match : Math.round(6*match/n);
}
function coherenceMod(parts,bodyCls){
  const COH=PFK.COH||{}; const pur=Math.max(0,Math.min(6,diePurity(parts,bodyCls)));
  let m=COH[pur]; if(m==null) m=1;
  const secret=parts.some(p=>(PFACES&&PFACES.scarcityBucket[partKey(p)])==='X');
  if(secret) m=Math.max(m,PFK.COH_FLOOR_SECRET||m);
  return m;
}
/* §3.4a-2 + §3.4c — ngân sách của MỘT part trên viên dice này.
   B_acq = trần của TIỀN (bucket × gene, kẹp B_CAP0) · B_run = trần của CHƠI (+ GENE_STEP mỗi bậc
   geneTier, kẹp B_CAP_RUN) · B_final = × coherence. */
function partBudget(bucket,part,geneTier,coh){
  const acq=Math.min(PFK.B_C*PFK.S[bucket]*geneMult(sgTierEff(part,bucket)), PFK.B_CAP0);
  const run=Math.min(acq+(PFK.GENE_STEP||0)*(geneTier||0), PFK.B_CAP_RUN);
  return run*coh;
}
/* F5b là AFFINE theo ngân sách ở cả hai nhánh, nên generator ship đúng hai hệ số (m, c) thay vì
   bắt engine.js chép lại toàn bộ bảng giá keyword — một bản sao thứ hai chắc chắn sẽ trôi.
   `lift` mang bump F6 (monotone) + REPAIR, là quyết định theo BUCKET mà mô hình affine không biết. */
function affValue(model,budget,lift){
  const x=model.m*budget-model.c;
  return Math.max(1, model.mode==='f'?Math.floor(x):Math.round(x))+(lift||0);
}
/* §5 E1 — part CÓ trong API thật nhưng KHÔNG có trong catalog. Đây là edge case xác suất cao
   nhất, không phải giả thuyết: catalog đã lớn 192 → 285 một lần rồi, và Sky Mavis phát hành part
   mới bất cứ lúc nào. Không có nhánh này thì người chơi import một Axie mang part mới ra một mặt
   CHẾT — đúng loại lỗi âm thầm mà cả hệ này tồn tại để chặn.

   Bốn quyết định, mỗi cái chịu lực:
   - variant 'A' (baseline của cả 36 family) chứ không random ⇒ axieToDie vẫn PURE ⇒ replay được.
   - bucket 'C' luôn ⇒ một part mới chưa cân bằng KHÔNG BAO GIỜ là thứ mạnh nhất game. Fail-safe
     đúng hướng.
   - vẫn hiện TÊN THẬT của part ⇒ giữ player fantasy, không phải "Unknown Part".
   - telemetry('part_unmapped') là tín hiệu vận hành DUY NHẤT báo catalog đã trôi. Gọi qua hook
     tuỳ chọn nên nó không đưa I/O vào đường suy diễn (giá trị mặt không phụ thuộc hook). */
function partTelemetry(evt,data){
  if(typeof telemetryHook==='function') try{ telemetryHook(evt,data); }catch(e){ /* never break a die */ }
}
function fallbackFace(part,coh,geneTier){
  const cls=normPartClass(part&&part.class), slot=normSlot(part&&part.type);
  const name=baseName(part&&part.name);
  partTelemetry('part_unmapped',{cls,slot,name});
  const fam=PFACES&&PFACES.familyVariant[cls];
  const tpl=fam&&fam[slot]&&fam[slot].A;
  if(!tpl){    /* E3 — slot hoặc class không nhận diện được. CHỈ ca này mới ra mặt blank. */
    const f=clone(B); f.src='fallback-blank'; f.name=name; return f;
  }
  const n=affValue(tpl,partBudget('C',part,geneTier,coh),tpl.lift&&tpl.lift.C);
  const isV0=tpl.t==='buff'||tpl.t==='debuff';
  return {p:slot,t:tpl.t,v:isV0?0:n,k:tpl.k.map(x=>/:N$/.test(x)?x.replace(/:N$/,':'+n):x),
    r:(PFK.SCARCITY_RFLOOR||{}).C||0,src:'fallback',name,variant:'A',bucket:'C'};
}
/* §3.6 bước 1–2. suppress = §3.4b (purity ≤ 2 → keyword sắc bị THAY bằng keyword thô, ngân sách
   chênh lệch hoàn vào v). Signature KHÔNG bị suppress và KHÔNG nhận bucket multiplier (§3.3). */
function resolveFace(part,coh,suppress,geneTier){
  const k=partKey(part);
  const sig=PFACES&&PFACES.signatureFace[k];
  const bucket=(PFACES&&PFACES.scarcityBucket[k])||'C';
  if(sig){
    const isV0=sig.t==='buff'||sig.t==='debuff';
    return {p:sig.p,t:sig.t,v:isV0?0:Math.max(1,Math.round(sig.v*coh)),k:sig.k.slice(),
      r:Math.min(4,sig.r+rBonus(sgTierEff(part,bucket))),src:'sig',name:baseName(part&&part.name)};
  }
  const letter=PFACES&&PFACES.partVariant[k];
  if(!letter) return fallbackFace(part,coh,geneTier);
  const fam=PFACES.familyVariant[normPartClass(part&&part.class)];
  const tpl=fam&&fam[normSlot(part&&part.type)]&&fam[normSlot(part&&part.type)][letter];
  if(!tpl) return fallbackFace(part,coh,geneTier);
  const model=(suppress&&tpl.sup)?tpl.sup:tpl;
  const n=affValue(model,partBudget(bucket,part,geneTier,coh),tpl.lift&&tpl.lift[bucket]);
  const isV0=tpl.t==='buff'||tpl.t==='debuff';
  /* trên mặt v=0 thì con số vừa tính là ĐỘ LỚN của keyword `:N`, không phải v */
  const keys=model.k.map(x=>/:N$/.test(x)?x.replace(/:N$/,':'+n):x);
  const rFloor=(PFK.SCARCITY_RFLOOR||{})[bucket]||0;
  return {p:normSlot(part&&part.type),t:tpl.t,v:isV0?0:n,k:keys,
    r:Math.min(3,rFloor+rBonus(sgTierEff(part,bucket))),  /* F8: variant kẹp r≤3 — chỉ signature mới lên COSMIC */
    src:'var',name:baseName(part&&part.name),variant:letter,bucket};
}
/* §3.9 — manifest scarcity đi kèm die để server verify lại được mà không cần fetch API. */
function scarcityManifest(parts){
  const out=[];
  for(const p of parts) out.push({k:partKey(p),b:(PFACES&&PFACES.scarcityBucket[partKey(p)])||'?',g:sgTier(p)});
  return out;
}
function axieToDie(axieData,geneTier){
  const raw=(axieData&&axieData.parts)||[];
  const bodyCls=mapAxieClass(axieData&&axieData.class);
  /* §3.10 — body class thật là dawn/dusk/mech (nếu có) trước khi bị ORIGIN_CLASS_MAP
     collapse về beast/reptile/bug. Giữ lại riêng để UI có thể hiện đúng danh tính
     ("real Dawn Axie") thay vì nói theo class đã map — mapping vẫn quyết định
     passive/màu/HP nền, chỉ display mới cần biết sự thật này. */
  const rawBodyCls=String((axieData&&axieData.class)||'').trim().toLowerCase();
  const secretCls=ORIGIN_CLASS_MAP[rawBodyCls]?rawBodyCls:null;
  /* N3/E2 — sort TRƯỚC khi cắt 6, nếu không viên dice phụ thuộc thứ tự API trả về. Sort ổn định
     theo (SLOT_ORDER, partKey) để hai part cùng slot cũng có thứ tự tất định (E5). */
  const parts=raw.slice().sort((a,b)=>{
    const d=SLOT_ORDER.indexOf(normSlot(a&&a.type))-SLOT_ORDER.indexOf(normSlot(b&&b.type));
    if(d!==0) return d;
    const ka=partKey(a),kb=partKey(b); return ka<kb?-1:ka>kb?1:0;
  }).slice(0,6);
  const coh=PFACES?coherenceMod(parts,bodyCls):1;
  const secret=PFACES&&parts.some(p=>PFACES.scarcityBucket[partKey(p)]==='X');
  const suppress=PFACES&&!secret&&diePurity(parts,bodyCls)<=2;
  const die=PFACES? parts.map(p=>resolveFace(p,coh,suppress,geneTier||0))
                  : parts.map(()=>clone(B));   /* bundle thiếu part_faces.js — die trống, không crash */
  while(die.length<6) die.push(clone(B));
  const baseHp=(HEROES[bodyCls+'1']&&HEROES[bodyCls+'1'].hp)||14;
  const hpStep=(PFK.HP_STEP||[0])[Math.max(0,Math.min(6,geneTier||0))]||0;
  const hp=Math.max(1,Math.round(baseHp*coh)+hpStep);
  return {n:'Axie #'+(axieData&&axieData.id), cls:bodyCls, secretCls, tier:1, hp, art:0, die, imported:true,
    axieId:axieData&&axieData.id, image:(axieData&&axieData.image)||null,
    purity:diePurity(parts,bodyCls), coh, geneTier:geneTier||0, scarcity:scarcityManifest(parts)};
}
/* độ hiếm của viên dice = tổng hợp các mặt (Option D) */
function dieRarity(u){
  const myth=u.die.filter(f=>f.r>=4).length, leg=u.die.filter(f=>f.r>=3).length;
  if(myth>=1) return 4;               /* COSMIC */
  if(leg>=2) return 3;                /* GOLDEN */
  if(leg>=1||u.die.filter(f=>f.r>=2).length>=2) return 2;
  if(u.die.some(f=>f.r>=1)) return 1;
  return 0;
}

/* ================= ENEMY GEN ================= */
function faceScale(t,s){ if(t==='poison')return Math.pow(s,0.50); if(t==='debuff'||t==='buff')return Math.pow(s,0.45); return s; }
function scaleDie(die,s){ return die.map(f=>({...f,k:f.k.slice(),v:f.v>0?Math.max(1,Math.round(f.v*faceScale(f.t,s))):0})); }
const avgFace=die=>{ const v=die.filter(f=>f.v>0).map(f=>f.v); return v.length? v.reduce((a,b)=>a+b,0)/v.length : 1; };

function mkMonster(key,sc,mods){
  const m=MON[key]; mods=mods||{hp:1,dmg:1};
  const hp=Math.max(1,Math.round(m.hp*sc*mods.hp));
  return {uid:UID++,side:'e',key,n:m.n,role:m.role,token:!!m.token,elite:!!m.elite,summons:m.summons,
    maxHp:hp,hp,shield:0,die:scaleDie(m.die,sc*mods.dmg),st:{},rolled:-1,intent:null,growth:{},critNow:false,sc};
}
function mkBoss(bk,pw,mods){
  const b=BOSS_BY_K[bk], B=CURVE.budget(pw);
  const hp=Math.round(b.hpk*B*mods.bossHp*mods.hp);
  const ds=(b.dmgk*B*mods.dmg)/avgFace(b.die);
  const u={uid:UID++,side:'e',key:b.k,n:b.n,role:'boss',big:1,boss:1,phase:1,trait:b.trait,desc:b.desc,
    maxHp:hp,hp,shield:0,die:scaleDie(b.die,ds),st:{},rolled:-1,intent:null,growth:{},critNow:false,
    permThorns:b.trait==='thorns'?Math.max(2,Math.round(0.09*B)):0,
    splitDone:0,adds:b.adds||[],addCap:b.addCap||0,turnCount:0,sc:Math.max(0.7,B/45)};
  if(b.die2){ u.hp2=Math.round((b.hpk2||b.hpk)*B*mods.bossHp*mods.hp); u.die2=scaleDie(b.die2,ds); }
  return u;
}
function genEncounter(s,kind){
  const mods=s.mods, pw=s.pw;
  if(kind==='boss'){ const bk=s.bossPlan[s.bossSteps.indexOf(s.step)]||'agony'; return [mkBoss(bk,pw,mods)]; }
  const isElite=kind==='elite';
  const budget=CURVE.budget(pw)*(isElite?CURVE.tune.eliteMult:1)*s.runMods.enemyHp;
  let n=CURVE.count(pw)+(isElite?mods.eliteExtra:0);
  const keys=[];
  if(isElite) keys.push(pick(ELITE_POOL));
  const avail=NORMAL_POOL.filter(p=>p.min<=pw+1).map(p=>p.k);
  const sorted=avail.slice().sort((a,b)=>MON[b].cost-MON[a].cost);
  while(keys.length<n) keys.push(sorted[ri(Math.max(1,Math.ceil(sorted.length*0.7)))]);
  const tot=keys.reduce((a,k)=>a+MON[k].cost,0);
  const sc=Math.max(0.55,Math.min(3.4,budget/tot));
  const em={hp:mods.hp,dmg:mods.dmg*s.runMods.enemyDmg};
  return keys.map(k=>mkMonster(k,sc,em));
}

/* ================= NEW GAME / MAP ================= */
function newGame(seed,teamKeys,opt){
  opt=opt||{};
  RNG=mkRng(seed>>>0); UID=1;
  const rl=RUN_LEN[opt.mode||'short'];
  const asc=opt.asc||0, mods=ascMods(asc);
  const order=(rl.len===12?BOSS_ORDER_12:BOSS_ORDER_20).slice();
  /* boss giữa có thể bị thay bằng boss alternate → mỗi run khác nhau */
  for(let i=1;i<order.length-1;i++) if(rnd()<0.5) order[i]=pick(BOSS_ALT);
  const elite=rl.elite.slice();
  if(mods.extraElite) for(let i=0;i<mods.extraElite;i++){ const c=1+ri(rl.len-1); if(!elite.includes(c)&&!rl.boss.includes(c)) elite.push(c); }
  const s={seed,mode:opt.mode||'short',asc,mods,len:rl.len,bossSteps:rl.boss,eliteSteps:elite,bossPlan:order,
    step:0,pw:0,phase:'map',nodes:null,node:null,
    roster:teamKeys.map((k,i)=>{
      const nft=opt.nftPreselect&&opt.nftPreselect[i];
      const pct=nft? nftHpBonusPct(nft.owned||0,nft.genes||0) : 0;
      return newRosterEntry(k,teamKeys.slice(0,i).filter(x=>x===k).length,pct);
    }),
    relics:(opt.startRelics||[]).slice(), party:[], enemies:[],
    mana:0,manaSpent:0,rerolls:2,maxRerolls:2+(opt.bonusReroll||0),bonusReroll:opt.bonusReroll||0,metaHpBonus:opt.metaHpBonus||0,
    shards:0,rerollReward:1,rrwMax:1,runMods:{enemyHp:1,enemyDmg:1},curses:[],
    undo:[],floatText:[],ev:[],log:[],rewards:null,rewardTier:0,event:null,shop:null,
    stat:{dmg:0,taken:0,turns:0,kills:0,maxHit:0},
    seen:{faces:[],relics:[]}};
  nextStep(s);
  return s;
}

function nextStep(s){
  s.step++;
  if(s.step>s.len){ s.phase='won'; return; }
  if(s.bossSteps.includes(s.step)){ s.nodes=[{type:'boss'}]; s.phase='map'; return; }
  if(s.step===1){ s.nodes=[{type:'battle'}]; s.phase='map'; return; }   /* wave 1: vào thẳng */
  const isElite=s.eliteSteps.includes(s.step);
  const a = isElite? {type:'elite'} : {type:'battle'};
  /* option B luôn KHÁC loại option A → luôn là một quyết định thật */
  const pool=[{type:'event'},{type:'event'},{type:'treasure'}];
  if(s.step>=3) pool.push({type:'shop'});
  if(!isElite&&s.step>=4) pool.push({type:'elite'});
  const b=pick(pool.filter(x=>x.type!==a.type))||{type:'event'};
  s.nodes = rnd()<0.5? [a,b] : [b,a];
  s.phase='map';
}
function chooseNode(s,i){
  const nd=s.nodes[i]; if(!nd) return false;
  s.node=nd; s.nodes=null;
  if(nd.type==='battle'||nd.type==='elite'||nd.type==='boss') startCombat(s,nd.type);
  else if(nd.type==='event'){ s.event={def:clone(pick(EVENTS.filter(e=>!e.shop))),res:null}; s.phase='event'; }
  else if(nd.type==='shop'){ genShop(s); s.phase='shop'; }
  else if(nd.type==='treasure'){ s.rewardTier=1; genRewards(s,'treasure'); s.phase='reward'; }
  return true;
}

/* ================= COMBAT START ================= */
const alive=a=>a.filter(u=>u.hp>0);
const aliveP=s=>alive(s.party);
const aliveE=s=>alive(s.enemies);
const realP=s=>s.party.filter(u=>!u.token);
const byUid=(s,uid)=>s.party.find(u=>u.uid===uid)||s.enemies.find(u=>u.uid===uid);

function startCombat(s,kind){
  s.kind=kind;
  s.party=s.roster.map(r=>buildUnit(r,s));
  const ss=rsum(s,'startSummon');
  for(let i=0;i<ss;i++) s.party.push(mkAlly(s));
  if(ss) EVrelic(s,'startSummon',null);
  s.enemies=genEncounter(s,kind);
  s.turn=1; s.mana=0; s.manaSpent=0; s.maxRerolls=2+(s.bonusReroll||0)+rsum(s,'rerollUp');
  s.rerolls=s.maxRerolls; s.phase='combat'; s.undo=[]; s.log=[]; s.usedActives=[]; s.floatText=[]; s.ev=[];
  s.lastBig=null; s._firstUsed=0; s._condGiven=0; s.resonanceLog=[];
  s.party.forEach(u=>{ if(u.cls==='reptile') u.st.thorns=Math.max(u.st.thorns||0,2); });
  s.enemies.forEach(e=>{ if(e.permThorns) e.st.thorns=e.permThorns; });
  if(s.mods.weaken){ const p=aliveP(s).filter(u=>!u.token); if(p.length) pick(p).st.weaken=2; }
  rcall(s,'onTurnStart',null);
  rollAll(s);
  return s;
}
function mkAlly(s){
  const m=MON.egg, sc=Math.max(1,CURVE.budget(s.pw)/14);
  const hp=Math.max(4,Math.round(m.hp*sc*0.55));
  const a={uid:UID++,side:'p',token:1,key:'egg',n:'Axie Egg',cls:'aqua',tier:1,artIdx:1,pas:null,
    maxHp:hp,hp,shield:0,die:scaleDie(m.die,sc*0.5),st:{},rolled:-1,used:false,heavy:false,frozen:false,growth:{},critNow:false};
  /* ENG-20 — token KHÔNG đi qua buildUnit nên chưa bao giờ nhận modFace. r_hivequeen mở cửa đó,
     và trả giá bằng mload 2 (§6.7.3). Vẫn chạy theo INV-5 nên độc lập thứ tự nhặt. */
  if(s&&rhas(s,'eggInherit')){ const before=a.maxHp;
    for(const e of modFaceOrder(s)) e.fn(a);
    if(a.maxHp!==before) a.hp=a.maxHp;
    EVrelic(s,'eggInherit',a.uid); }
  return a;
}

/* ================= ROLL ================= */
function critChance(s,u,f){ return (kwVal(f,'crit')||0) + rsum(s,'critBonus'); }
function rollUnit(s,u){
  u.rolled=ri(6); u.used=false;
  const f=u.die[u.rolled];
  u.heavy=hasKw(f,'heavy');
  /* CRIT quyết định NGAY LÚC ROLL và hiện lên mặt dice → giữ pillar Deterministic */
  const cc=critChance(s,u,f);
  u.critNow = u.side==='p' && f.t==='dmg' && cc>0 && rnd()*100<cc;
  u.rollFx=(f.r>=1?f.r:0);
}
function pickEnemyIntent(s,e){
  const f=e.die[e.rolled]; let tgt=null;
  const ps=aliveP(s);
  if(f.t==='dmg'||f.t==='poison'||f.t==='debuff'){
    if(ps.length){
      if(e.role==='assassin'){ tgt=ps.slice().sort((a,b)=>(a.hp+a.shield)-(b.hp+b.shield))[0].uid; }
      else if(e.role==='bruiser'&&rnd()<0.5){ tgt=ps.slice().sort((a,b)=>(b.hp+b.shield)-(a.hp+a.shield))[0].uid; }
      else tgt=pick(ps).uid;
    }
  } else if(f.t==='shield'||f.t==='heal'||f.t==='buff'){
    const es=aliveE(s);
    if(e.role==='healer'&&es.length) tgt=es.slice().sort((a,b)=>(a.hp/a.maxHp)-(b.hp/b.maxHp))[0].uid;
    else tgt=es.length?pick(es).uid:e.uid;
  }
  e.intent={face:f,tgt};
}
function rollAll(s){
  s.party.forEach(u=>{ if(u.hp>0){ if(u.frozenNext){ u.frozen=true; u.frozenNext=false; } rollUnit(s,u); } else { u.rolled=-1; u.used=true; } });
  s.enemies.forEach(e=>{ if(e.hp>0){ rollUnit(s,e); pickEnemyIntent(s,e); } else { e.rolled=-1; e.intent=null; } });
  resolveCantrips(s);
  rcall(s,'onRollEnd',null);
}
function resolveCantrips(s){
  for(const u of aliveP(s).slice()){
    let g=0;
    while(u.rolled>=0&&!u.used&&hasKw(u.die[u.rolled],'cantrip')&&g++<6){ execFace(s,u,u.uid); rollUnit(s,u); }
  }
}
function anyRerollable(s){ return s.party.some(u=>u.hp>0&&!u.used&&!u.heavy&&!u.frozen); }
function doReroll(s,uids){
  // Guards against a stale/queued UI action (e.g. a drag-and-drop gesture in
  // flight right as combat ends) landing after the phase has already moved on
  // to map/shop/event/reward — see api/submit-run.js replay-rejection
  // postmortem: without this, such an action could still succeed client-side
  // (nothing here checked phase) and get logged, then fail an honest server
  // replay because the two sides' `s.phase` no longer line up at that point.
  if(s.phase!=='combat') return false;
  if(s.rerolls<=0) return false;
  const list=uids.filter(id=>{ const u=byUid(s,id); return u&&u.side==='p'&&u.hp>0&&!u.used&&!u.heavy&&!u.frozen; });
  if(!list.length) return false;
  s.rerolls--;
  /* ENG-15 — reroll hôm nay huỷ luôn crit đã roll được, tức người chơi bị PHẠT vì dùng
     tài nguyên của chính mình. critKeep gỡ hình phạt đó (r_predatorpoise). */
  const keepCrit=rhas(s,'critKeep');
  list.forEach(id=>{ const u=byUid(s,id); const had=keepCrit&&u.critNow;
    rollUnit(s,u); if(had){ u.critNow=true; EVrelic(s,'critKeep',u.uid); } });
  resolveCantrips(s);
  if(!rhas(s,'safeReroll')) s.undo=[];
  return true;
}

/* ================= DAMAGE PIPELINE ================= */
function EV(s,o){ if(!s.ev) s.ev=[]; if(s.ev.length>900) s.ev.length=0; s.ev.push(o); }
function EVhp(s,u){ EV(s,{t:'hp',uid:u.uid,hp:u.hp,maxHp:u.maxHp,shield:u.shield}); }
/* §3.9 — một relic không phát event là ĐÚNG SỐ nhưng VÔ HÌNH: fx.js replay s.ev để animate,
   nên plague/noShieldCap/firstEcho/growthAll... hôm nay không có cách nào hiện ra.
   Payload chỉ id + uid ⇒ tất định, không đụng math, KHÔNG cần bump ENGINE_VERSION vì
   server replay so sánh state chứ không so sánh s.ev.
   LƯU Ý CỐ Ý LỆCH SPEC: §10 E1 liệt kê cả buildUnit làm call site. Không làm ở đó — sau R1,
   relicPool() gọi buildUnit cho cả roster ở 6 call site để dò partyKeywords, nên emit trong
   buildUnit sẽ bơm rác vào s.ev mỗi lần sinh reward. Roster §5 tự nói relic modFace là
   "visible trên mặt die" nên không cần event. */
function EVrelic(s,id,uid){ if(s&&s.ev) EV(s,{t:'relic',id,uid:uid||null}); }
function ft(s,u,txt,cls,big){ s.floatText.push({uid:u.uid,txt,cls,big:big||0});
  EV(s,{t:'ft',uid:u.uid,txt,cls,big:big||0}); }

function dealDamage(s,src,tgt,v,o){
  o=o||{};
  if(tgt.hp<=0||v<=0) return 0;
  let pierce=!!o.pierce;
  /* ---- source side ---- */
  if(src&&src.side==='p'){
    const lowHp = tgt.hp < tgt.maxHp*0.5;
    if(lowHp && (src.cls==='beast'||o.exec)) v=Math.ceil(v*1.6);
    if(pierce){ v+= (src.cls==='bird'?3:0) + rsum(s,'piercePlus'); }
    const dm=rmul_(s,'dmgMult'); if(dm!==1) v=Math.ceil(v*dm);
    for(const r of rlist(s)) if(r.modDmg) v=r.modDmg({s,src,tgt,v});
    if(o.crit){
      v*=rmax(s,'critMult',2);
      /* ENG-21 — cộng SAU khi nhân, không trước. HAI phạm vi tách rời:
           critFlat     -> MỌI đòn crit            (r_shatterpoint)
           critFlatPity -> CHỈ đòn mang cờ pityCrit (r_keeneye, do onRollEnd của nó đặt)
         Giữ cả hai ⇒ +9 trên đòn pity, +5 trên các crit khác (roster §17.4). Gộp làm một field
         `critFlat` biến r_keeneye thành +9 trên MỌI crit ⇒ ≥35.60 RP, một EPIC đứng trong dải
         LEGENDARY. Event vẫn phát dưới id 'critFlat' vì đó là KEY LUẬT mà fx.js tra (nhãn 'CRIT'
         đúng cho cả hai; nếu chỉ giữ r_keeneye thì fallback label của fx.js lo phần tên). */
      let cf=rsum(s,'critFlat');
      if(src.pityCrit) cf+=rsum(s,'critFlatPity');
      if(cf){ v+=cf; EVrelic(s,'critFlat',tgt.uid); }
      if(rhas(s,'critPierce')){ pierce=true; EVrelic(s,'critPierce',tgt.uid); }  /* ENG-8 */
    }
  }
  /* ---- target side ---- */
  if(tgt.st.vulnerable>0) v=Math.ceil(v*1.5);
  if(tgt.side==='p'){ const dr=rsum(s,'dr'); if(dr>0) v=Math.max(1,Math.ceil(v*(1-dr))); }
  let dealt=0;
  EV(s,{t:'hit',src:src?src.uid:null,uid:tgt.uid,v:v,crit:!!o.crit});
  if(!pierce&&tgt.shield>0){ const ab=Math.min(tgt.shield,v); tgt.shield-=ab; v-=ab; if(ab>0) ft(s,tgt,'-'+ab,'shd'); }
  /* T22 (2026-09-03) · Formation Resonance's +25% was already baked into `v`
     by the time it reaches here (faceValue() applies RESONANCE.mult before
     dealDamage ever sees the number) — but the ONLY visible cue was a
     separate "LINK ×1.25" float on the ATTACKER, shown before the hit lands.
     The actual damage number on the TARGET carried zero indication it had
     been boosted, so a player watching numbers land had no way to connect
     "why did that one hit for more" back to their formation choice — see
     design/quick-specs/formation-resonance-2026-09-01.md Player Fantasy
     ("minh bạch triệt để"): a mechanic that changes a number must show up
     ON that number, not just as a separate pre-attack label. Tag the
     boosted hit's own float text so the two "LINK" cues read as one
     connected story instead of two disconnected floats. */
  if(v>0){ tgt.hp-=v; dealt=v; ft(s,tgt,(o.crit?'CRIT ':'')+(o.resonant?'LINK ':'')+'-'+v,'dmg',o.crit?2:(v>=25?1:0)); }
  if(tgt.hp<=0&&tgt.st.undying){ tgt.st.undying=0; tgt.hp=1; ft(s,tgt,'UNDYING','buf'); }
  if(tgt.hp<0) tgt.hp=0;
  EVhp(s,tgt);
  if(tgt.hp<=0) EV(s,{t:'death',uid:tgt.uid});
  /* stats */
  if(src&&src.side==='p'){ s.stat.dmg+=dealt; if(dealt>s.stat.maxHit) s.stat.maxHit=dealt; }
  if(tgt.side==='p') s.stat.taken+=dealt;
  /* ENG-19 / §10 G2(b) — QĐ-2 đã duyệt. Chạy SAU khi shield đã hấp thụ nên relic đọc được
     `dealt` thật, và mang `attack` vì hook nổ cho MỌI lần trừ HP kể cả tick poison/burn
     (src=null) trong khi thorns chỉ nổ khi o.attack — thiếu cờ này r_bloodthorn vượt dải. */
  if(tgt.side==='p') rcall(s,'onDmgTaken',{src,tgt,dealt,attack:!!o.attack});
  /* thorns (pierce+piercePlus relic bỏ qua thorns) */
  const skipThorns = pierce && rhas(s,'piercePlus');
  if(src&&o.attack&&!skipThorns&&tgt.st.thorns>0&&src.hp>0&&src!==tgt){
    let th=tgt.st.thorns;
    /* ENG-4 — thornsPlus cộng SAU khi nhân, nên nó không bị thornsMult khuếch đại. */
    if(tgt.side==='p'){ const tm=rmax(s,'thornsMult',1), tp=rsum(s,'thornsPlus');
      th=th*tm+tp; if(tm!==1||tp) EVrelic(s,'thorns',tgt.uid); }
    EV(s,{t:'hit',src:tgt.uid,uid:src.uid,v:th,crit:false});
    src.hp-=th; ft(s,src,'-'+th,'dmg');
    if(tgt.side==='p'&&tgt.cls==='reptile') addStatus(s,src,['poison:1']);
    if(src.hp<=0&&src.st.undying){src.st.undying=0;src.hp=1;}
    if(src.hp<0) src.hp=0;
    EVhp(s,src); if(src.hp<=0) EV(s,{t:'death',uid:src.uid});
    if(src.hp<=0&&src.side==='e') onEnemyDeath(s,src);
    if(tgt.side==='p') rcall(s,'onThorns',{src,tgt,th});   /* ENG-5 */
  }
  /* onHit relic hooks */
  if(src&&src.side==='p'&&dealt>0){
    for(const r of rlist(s)) if(r.onHit) r.onHit(s,{type:o.faceType||'dmg',dealt,tgt,crit:!!o.crit,src,addStatus:kw=>addStatus(s,tgt,[kw])});   /* ENG-1: ctx thêm crit + src */
  }
  if(tgt.side==='e'&&tgt.hp<=0) onEnemyDeath(s,tgt);
  if(tgt.boss) checkBossPhase(s,tgt);
  return dealt;
}
function rmul_(s,k){ let v=1; for(const r of rlist(s)) if(r[k]) v*=r[k]; return v; }

function onEnemyDeath(s,e){
  if(e._dead) return; e._dead=1;
  s.stat.kills++;
  rcall(s,'onKill',{tgt:e,
    explode:v=>aliveE(s).forEach(x=>{ if(x!==e) dealDamage(s,null,x,v,{}); }),
  });
}
function applyHeal(s,t,v){
  if(t.hp<=0||v<=0) return;
  const b=t.hp; t.hp=Math.min(t.maxHp,t.hp+v);
  if(t.hp>b) ft(s,t,'+'+(t.hp-b),'heal');
  EVhp(s,t);
  if(t.side==='p'&&rhas(s,'healShield')) applyShield(s,t,v);
}
function applyShield(s,t,v){
  if(t.hp<=0||v<=0) return;
  if(t.side==='p'&&t.cls==='plant') v+=2;
  const noCap = t.side==='p'&&rhas(s,'noShieldCap');
  if(noCap&&t.shield+v>t.maxHp*2) EVrelic(s,'noShieldCap',t.uid);
  const cap = noCap? 99999 : t.maxHp*2;
  t.shield=Math.min(cap,t.shield+v); ft(s,t,'+'+v,'shd'); EVhp(s,t);
  if(t.side==='p'&&t.cls==='plant'&&t.shield>=10) t.st.thorns=Math.max(t.st.thorns||0,2);
  if(t.side==='p') rcall(s,'onShield',{v,tgt:t,splash:m=>{ const es=aliveE(s); if(es.length) dealDamage(s,t,pick(es),Math.ceil(v*m),{attack:false}); }});
}
function addStatus(s,t,kws,src){
  for(const k of kws){
    const [n,val]=k.split(':'); let v=val?+val:1;
    if(n==='poison'){
      if(src&&src.side==='p'&&src.cls==='bug'&&t.st.poison>0) v+=2;
      t.st.poison=(t.st.poison||0)+v; ft(s,t,'PSN '+v,'poi');
      if(src&&src.side==='p'&&rhas(s,'poisonSpread')){
        const arr=t.side==='e'?aliveE(s):aliveP(s); const i=arr.indexOf(t);
        [arr[i-1],arr[i+1]].forEach(x=>{ if(x){ x.st.poison=(x.st.poison||0)+Math.ceil(v/2); ft(s,x,'PSN '+Math.ceil(v/2),'poi'); } });
      }
      continue;
    }
    if(['thorns','regen','burn','blind','weaken','vulnerable'].includes(n)){
      /* THORNS_CAP (K24) — thorns là đại lượng DUY NHẤT không bao giờ giảm: tickStatus không
         trừ nó. Không có trần thì nó vô hạn theo số lượt và KHÔNG giá hữu hạn nào đúng. */
      t.st[n] = (n==='thorns') ? Math.min(THORNS_CAP,(t.st[n]||0)+v) : (t.st[n]||0)+v;
      ft(s,t,n.slice(0,3).toUpperCase()+v,(n==='thorns'||n==='regen')?'buf':'deb');
    } else if(n==='stun'){ t.st.stun=1; ft(s,t,'STUN','deb'); }
    else if(n==='freeze'){ if(t.side==='p'){ t.frozenNext=true; ft(s,t,'FREEZE','deb'); } else { t.st.stun=1; ft(s,t,'STUN','deb'); } }
    else if(n==='enrage'){ t.die.forEach(f=>{ if(f.t==='dmg') f.v=Math.ceil(f.v*1.25); }); ft(s,t,'ENRAGE','buf'); }
    else if(n==='undying'){ t.st.undying=1; ft(s,t,'UNDYING','buf'); }
  }
}

/* ================= FACE VALUE / EXEC ================= */
function faceValue(s,u,fi){
  const f=u.die[fi]; let v=f.v+(u.growth[fi]||0);
  if(hasKw(f,'vital')&&u.hp===u.maxHp) v*=2;
  if(f.t==='dmg'){
    if(u.st.blind>0) return 0;
    if(u.st.weaken>0) v=Math.max(0,v-u.st.weaken);
    if(u.overdrive) v=Math.ceil(v*1.5);
    if(u.side==='p'&&rhas(s,'hiveMind')) v+=rsum(s,'hiveMind')*s.party.filter(x=>x.token&&x.hp>0).length;
  }
  if(f.t==='mana'&&u.side==='p'&&u.cls==='aqua') v+=1;
  if(u.side==='p'&&u.resonantNow) v=Math.ceil(v*RESONANCE.mult);
  return v;
}
const neighborsOf=(arr,t)=>{ const i=arr.indexOf(t),o=[]; if(i>0)o.push(arr[i-1]); if(i>=0&&i<arr.length-1)o.push(arr[i+1]); return o; };

/* ================= FORMATION RESONANCE ================= */
/* design/quick-specs/formation-resonance-2026-09-01.md §Formulas 2-4 */
function formationPos(s,u){
  if(u.token) return -1;
  const i=s.roster.findIndex(r=>r.uid===u.uid);
  return i;
}
function findResonanceIdx(s,u,f){
  if(u.side!=='p'||u.token) return -1;
  if(!RESONANCE.types.includes(f.t)) return -1;
  const pos=formationPos(s,u);
  if(pos<0) return -1;
  return (s.resonanceLog||[]).findIndex(e=>!e.used&&e.t===f.t&&Math.abs(e.pos-pos)===1);
}
function logResonanceAttempt(s,u,f,wasConsumer){
  if(u.side!=='p'||u.token) return;
  if(!RESONANCE.types.includes(f.t)) return;
  if(wasConsumer) return;
  const pos=formationPos(s,u);
  if(pos<0) return;
  s.resonanceLog.push({pos,t:f.t,used:false});
}
function resonancePairs(s){
  const out=[];
  const real=[];
  s.roster.forEach((r,i)=>{
    const u=s.party.find(p=>p.uid===r.uid);
    if(u&&u.hp>0&&u.rolled>=0&&!u.used) real.push({pos:i,u});
  });
  for(let i=0;i<real.length;i++){
    for(let j=i+1;j<real.length;j++){
      const a=real[i], b=real[j];
      if(Math.abs(a.pos-b.pos)!==1) continue;
      const fa=a.u.die[a.u.rolled], fb=b.u.die[b.u.rolled];
      if(RESONANCE.types.includes(fa.t)&&fa.t===fb.t) out.push({posA:a.pos,posB:b.pos,type:fa.t});
    }
  }
  return out;
}

function execFace(s,u,tgtUid){
  const fi=u.rolled; if(fi<0||u.used) return false;
  const f=u.die[fi];
  if(f.t==='blank') return false;
  const resIdx=findResonanceIdx(s,u,f);
  const isResonant=resIdx>=0;
  u.resonantNow=isResonant;
  if(isResonant) ft(s,u,'LINK ×'+RESONANCE.mult,'buf');
  let reps = hasKw(f,'echo')?2:1;
  if(u.side==='p'&&rhas(s,'firstEcho')&&!s._firstUsed) reps=Math.max(reps,2);
  EV(s,{t:'use',uid:u.uid,side:u.side,tgt:tgtUid,aoe:hasKw(f,'aoe')||f.t==='mana'||f.t==='summon'});
  const ok=doFace(s,u,tgtUid,f,fi);
  if(!ok){ u.resonantNow=false; return false; }
  if(u.side==='p') s._firstUsed=1;
  for(let i=1;i<reps;i++) doFace(s,u,tgtUid,f,fi,true);
  u.used=true;
  if(isResonant) s.resonanceLog[resIdx].used=true;
  logResonanceAttempt(s,u,f,isResonant);
  if(isResonant) EV(s,{t:'resonance',uid:u.uid});
  if(u.side==='p'&&u.critNow) u.critNow=false;
  u.resonantNow=false;
  return true;
}
function doFace(s,u,tgtUid,f,fi,isEcho){
  const foes=u.side==='p'?aliveE(s):aliveP(s), friends=u.side==='p'?aliveP(s):aliveE(s);
  const v=faceValue(s,u,fi);
  let tgt=tgtUid!=null?byUid(s,tgtUid):null;
  const crit=!!u.critNow;
  const kwPure=f.k.filter(k=>!['aoe','cantrip','heavy','echo','selfkill','plague','bastion','overflow'].includes(k)
    && !k.startsWith('multi')&&!k.startsWith('chain')&&!k.startsWith('selfharm')&&!k.startsWith('crit')
    && k!=='cleave'&&k!=='pierce'&&k!=='lifesteal'&&k!=='growth'&&k!=='decay'&&k!=='vital'&&k!=='rerollup'&&k!=='exec');
  const hit=(t,amount,extra)=>{
    const d=dealDamage(s,u,t,amount,{pierce:hasKw(f,'pierce')||(u.side==='p'&&u.cls==='bird'&&hasKw(f,'aoe')),
      attack:true,crit,exec:hasKw(f,'exec'),faceType:'dmg',resonant:u.resonantNow});
    if(hasKw(f,'lifesteal')&&d>0) applyHeal(s,u,d);
    if(kwPure.length&&d>=0) addStatus(s,t,kwPure,u);
    return d;
  };
  if(f.t==='dmg'){
    if(hasKw(f,'aoe')) foes.slice().forEach(t=>hit(t,v));
    else {
      const chain=kwVal(f,'chain');
      if(chain){ for(let i=0;i<chain;i++){ const l=u.side==='p'?aliveE(s):aliveP(s); if(!l.length)break; hit(pick(l),v); } }
      else {
        if(!tgt||tgt.hp<=0||tgt.side===u.side) return false;
        const mult=kwVal(f,'multi')||1;
        for(let i=0;i<mult;i++) if(tgt.hp>0||i===0) hit(tgt,v);
        if(hasKw(f,'cleave')) neighborsOf(foes,tgt).forEach(t=>hit(t,Math.ceil(v*rmax(s,'cleaveRatio',0.5))));   /* ENG-9 */
      }
    }
    if(hasKw(f,'selfkill')){ u.hp=0; ft(s,u,'BOOM','dmg',1); }
  } else if(f.t==='poison'){
    const p=[]; for(let i=0;i<(kwVal(f,'multi')||1);i++) p.push('poison:'+v);
    if(hasKw(f,'aoe')) foes.slice().forEach(t=>addStatus(s,t,p,u));
    else { if(!tgt||tgt.hp<=0||tgt.side===u.side) return false; addStatus(s,tgt,p,u); }
    if(hasKw(f,'pierce')) (hasKw(f,'aoe')?foes:[tgt]).forEach(t=>{ if(t) dealDamage(s,u,t,v,{pierce:1,attack:false}); });
  } else if(f.t==='debuff'){
    if(hasKw(f,'aoe')) foes.slice().forEach(t=>addStatus(s,t,kwPure,u));
    else { if(!tgt||tgt.hp<=0||tgt.side===u.side) return false; addStatus(s,tgt,kwPure,u); }
  } else if(f.t==='shield'){
    const doSh=t=>{ applyShield(s,t,v); if(kwPure.length) addStatus(s,t,kwPure,u);
      if(hasKw(f,'bastion')){ const es=u.side==='p'?aliveE(s):aliveP(s); if(es.length) dealDamage(s,u,pick(es),v,{attack:false}); } };
    if(hasKw(f,'aoe')) friends.slice().forEach(doSh);
    else { if(!tgt||tgt.hp<=0||tgt.side!==u.side) return false; doSh(tgt); }
  } else if(f.t==='heal'){
    if(hasKw(f,'aoe')) friends.slice().forEach(t=>{applyHeal(s,t,v); if(kwPure.length)addStatus(s,t,kwPure,u);});
    else { if(!tgt||tgt.hp<=0||tgt.side!==u.side) return false; applyHeal(s,tgt,v); if(kwPure.length)addStatus(s,tgt,kwPure,u); }
  } else if(f.t==='buff'){
    if(hasKw(f,'aoe')) friends.slice().forEach(t=>addStatus(s,t,kwPure,u));
    else { if(!tgt||tgt.hp<=0||tgt.side!==u.side) return false; addStatus(s,tgt,kwPure,u); }
  } else if(f.t==='mana'){
    if(u.side==='p'){ s.mana+=v; ft(s,u,'+'+v+' MP','man'); }
  } else if(f.t==='summon'){
    if(u.side==='p'){ const tcap=rmax(s,'tokenCap',4);   /* ENG-20 — 4 không còn là số trần */
      for(let i=0;i<v;i++) if(s.party.filter(x=>x.token&&x.hp>0).length<tcap){ const a=mkAlly(s); rollUnit(s,a); a.used=true; s.party.push(a); } ft(s,u,'SUMMON','buf'); }
    else { const k=u.summons||'egg'; for(let i=0;i<v;i++) if(s.enemies.length<7){ const m=mkMonster(k,u.sc*0.7,{hp:1,dmg:1}); rollUnit(s,m); pickEnemyIntent(s,m); s.enemies.push(m); } }
  }
  if(!isEcho){
    const sh=kwVal(f,'selfharm'); if(sh) dealDamage(s,null,u,sh,{pierce:1});
    const mn=kwVal(f,'mana'); if(mn&&u.side==='p') s.mana+=mn;
    if(hasKw(f,'rerollup')&&u.side==='p') s.rerolls++;
    if(hasKw(f,'growth')) u.growth[fi]=(u.growth[fi]||0)+1+rsum(s,'growthPlus');   /* ENG-2 */
    if(hasKw(f,'decay')) u.growth[fi]=(u.growth[fi]||0)-1;
    if(u.side==='p'&&f.t==='dmg'&&v>0) s.lastBig=(!s.lastBig||v>s.lastBig.v)?{v,f:clone(f)}:s.lastBig;
  }
  return true;
}

/* ================= UNDO ================= */
const SNAP=['party','enemies','mana','manaSpent','rerolls','usedActives','turn','stat','_firstUsed','lastBig','resonanceLog'];
function snap(s){ const o={}; SNAP.forEach(k=>o[k]=(s[k]===undefined?null:clone(s[k]))); return o; }
function pushUndo(s){ s.undo.push(snap(s)); if(s.undo.length>90) s.undo.shift(); }
function undo(s){ if(!s.undo.length) return false; const o=s.undo.pop(); SNAP.forEach(k=>s[k]=o[k]); s.ev=[]; s.floatText=[]; return true; }

function playerUseDie(s,uid,tgtUid){
  // See doReroll's comment above — same stale-action-after-phase-change guard.
  if(s.phase!=='combat') return false;
  const u=byUid(s,uid); if(!u||u.side!=='p'||u.hp<=0||u.used) return false;
  pushUndo(s);
  if(!execFace(s,u,tgtUid)){ s.undo.pop(); return false; }
  checkEnd(s); return true;
}
function playerUseRelic(s,id,tgtUid){
  // See doReroll's comment above — same stale-action-after-phase-change guard.
  if(s.phase!=='combat') return false;
  const it=RELIC_BY_ID[id]; if(!it||!it.act) return false;
  if(s.mana<it.act.cost) return false;
  /* ENG-16 — actReuse nới TRẦN LƯỢT (số lần dùng/lượt), chỉ cho thẻ rarity <= 2.
     LƯU Ý: actives reset MỖI LƯỢT (endTurn xoá usedActives ngay sau khi tăng số lượt), không
     phải mỗi trận — mana là chốt chặn duy nhất. Mọi định giá active dựa trên sự thật đó. */
  const usedN = s.usedActives.filter(x=>x===id).length;
  const maxUse = it.rar<=2 ? Math.max(1,rmax(s,'actReuse',1)) : 1;
  if(usedN>=maxUse) return false;
  pushUndo(s);
  const a=it.act, tgt=tgtUid!=null?byUid(s,tgtUid):null, u=aliveP(s)[0]; let ok=true;
  if(a.kind==='heal'){ if(!tgt||tgt.side!=='p'||tgt.hp<=0) ok=false; else applyHeal(s,tgt,a.v); }
  /* ENG-14 — nhánh dmg trước đây BỎ QUA crit/exec trong opts, nên một active tự khai crit
     không bao giờ crit được. a.crit/a.exec đọc từ data ⇒ không lặp lại lỗi hardcode. */
  else if(a.kind==='dmg'){ if(!tgt||tgt.side!=='e'||tgt.hp<=0) ok=false; else dealDamage(s,u,tgt,a.v,{pierce:a.pierce,attack:true,crit:!!a.crit,exec:!!a.exec}); }
  /* QĐ-3 bug 2: opts thiếu `crit` nên nhánh này KHÔNG BAO GIỜ crit được dù thẻ tự khai crit.
     Sửa bằng cách truyền a.crit (giống hit() trong doFace). a_ult đồng thời được retag
     crit -> mana ở §6.5 vì RP 36.05 của nó định giá trên 40 damage KHÔNG crit. */
  else if(a.kind==='ult'){ if(!tgt||tgt.side!=='e'||tgt.hp<=0) ok=false; else { dealDamage(s,u,tgt,a.v,{pierce:1,attack:true,crit:!!a.crit}); aliveP(s).forEach(t=>applyShield(s,t,10)); } }
  else if(a.kind==='shieldall') aliveP(s).forEach(t=>applyShield(s,t,a.v));
  else if(a.kind==='dmgall') aliveE(s).slice().forEach(t=>dealDamage(s,u,t,a.v,{attack:true}));
  else if(a.kind==='poisonall') aliveE(s).slice().forEach(t=>addStatus(s,t,['poison:'+a.v],u));
  else if(a.kind==='stun'){ if(!tgt||tgt.side!=='e'||tgt.hp<=0) ok=false; else addStatus(s,tgt,['stun'],u); }   /* §11 mục 8: truyền source cho nhất quán */
  else if(a.kind==='reroll') s.rerolls+=a.v;
  /* ENG-10 — kind:'kw' (mode × scope). mode 'min' idempotent (nâng lên sàn), 'add' cộng dồn. */
  else if(a.kind==='kw'){
    const [kn,kvRaw]=String(a.kw).split(':'); const kv=kvRaw?+kvRaw:1;
    const list=(a.scope==='allEnemies'? aliveE(s): aliveP(s)).slice();
    for(const t of list){
      if(a.mode==='min'){ const cur=t.st[kn]||0; if(cur<kv) addStatus(s,t,[kn+':'+(kv-cur)],u); }
      else addStatus(s,t,[a.kw],u);
    }
  }
  /* ENG-11 — kind:'grow'. Growth theo MẶT ĐANG ROLL, vĩnh viễn trong trận. */
  else if(a.kind==='grow'){
    aliveP(s).forEach(p=>{ if(p.rolled>=0&&p.die[p.rolled]&&p.die[p.rolled].v>0){
      p.growth[p.rolled]=(p.growth[p.rolled]||0)+a.v; ft(s,p,'GROW +'+a.v,'buf'); } });
  }
  /* ENG-12 — kind:'summon'. Copy nguyên nhánh summon của doFace: GIỮ cap token và used=true. */
  else if(a.kind==='summon'){
    const tcap=rmax(s,'tokenCap',4);
    for(let i=0;i<a.v;i++) if(s.party.filter(x=>x.token&&x.hp>0).length<tcap){
      const al=mkAlly(s); rollUnit(s,al); al.used=true; s.party.push(al); }
    ft(s,u,'SUMMON','buf');
  }
  /* ENG-13 — kind:'shatter'. Phá sạch shield và gây damage bằng lượng đã phá, tối thiểu a.min:
     sàn này là lý do thẻ không bằng 0 trước địch không giáp. */
  else if(a.kind==='shatter'){
    if(!tgt||tgt.side!=='e'||tgt.hp<=0) ok=false;
    else { const sh=tgt.shield||0; if(sh>0){ tgt.shield=0; ft(s,tgt,'-'+sh,'shd'); EVhp(s,tgt); }
      dealDamage(s,u,tgt,Math.max(a.min||0,sh),{pierce:1,attack:true}); }
  }
  /* Trước đây KHÔNG có else: một `kind` lạ vẫn TRỪ MANA + tiêu slot của lượt + không làm gì. */
  else ok=false;
  if(!ok){ s.undo.pop(); return false; }
  s.mana-=a.cost; s.manaSpent+=a.cost; s.usedActives.push(id);
  /* AQUA CONDUIT: mỗi 4 mana tiêu → +1 reroll */
  if(s.party.some(u2=>u2.cls==='aqua'&&u2.hp>0)){
    const gained=Math.floor(s.manaSpent/4)-(s._condGiven||0);
    if(gained>0){ s.rerolls+=gained; s._condGiven=(s._condGiven||0)+gained; ft(s,aliveP(s)[0],'+'+gained+' REROLL','buf'); }
  }
  checkEnd(s); return true;
}

/* ================= BOSS TRAITS ================= */
function checkBossPhase(s,b){
  if(b.trait==='phase'&&b.phase===1&&b.hp<=0&&b.hp2){
    b.phase=2; b.maxHp=b.hp2; b.hp=b.hp2; b.die=b.die2; b.shield=0; b.st={}; b._dead=0;
    ft(s,b,'PHASE 2','deb',2); EV(s,{t:'phase',uid:b.uid}); EVhp(s,b); s.bossPhaseFx=1;
  }
  if(b.trait==='split'){
    const fr=b.hp/b.maxHp, want=fr<=0.34?2:fr<=0.67?1:0;
    while(b.splitDone<want&&b.splitDone<b.addCap){
      b.splitDone++; const m=mkMonster(pick(b.adds),b.sc*1.6,{hp:1,dmg:1}); rollUnit(s,m); pickEnemyIntent(s,m); s.enemies.push(m);
    }
  }
}
function bossTurnTraits(s){
  for(const b of aliveE(s)){
    if(!b.boss) continue;
    b.turnCount=(b.turnCount||0)+1; b.overdrive=0;
    if(b.trait==='thorns'){ b.st.thorns=Math.max(b.st.thorns||0,b.permThorns); if(b.turnCount%3===0){ b.overdrive=1; ft(s,b,'OVERDRIVE','deb',1); } }
    if(b.trait==='summon'&&b.turnCount%3===0&&b.adds.length&&b.splitDone<b.addCap){
      b.splitDone++; const m=mkMonster(pick(b.adds),b.sc,{hp:1,dmg:1}); rollUnit(s,m); pickEnemyIntent(s,m); s.enemies.push(m);
    }
    /* FREEZE: constrain (không reroll được) — KHÔNG destroy */
    if(b.trait==='freeze'){ const c=aliveP(s).filter(u=>!u.frozen&&!u.token); if(c.length){ const t=pick(c); t.frozen=true; ft(s,t,'FROZEN','deb'); } }
    /* MIRROR: copy mặt mạnh nhất người chơi vừa dùng */
    if(b.trait==='mirror'&&s.lastBig){ b.die[0]={...clone(s.lastBig.f),v:Math.max(b.die[0].v,Math.ceil(s.lastBig.v*1.1))}; }
  }
}

/* ================= END TURN ================= */
function endTurn(s){
  if(s.phase!=='combat') return;
  s.undo=[]; s._firstUsed=0;
  /* mana overflow relic / mythic face */
  if(s.mana>0&&(rhas(s,'manaOverflow')||s.party.some(u=>u.die.some(f=>hasKw(f,'overflow'))))){
    const v=s.mana; aliveE(s).slice().forEach(t=>dealDamage(s,aliveP(s)[0],t,v,{attack:false}));
    ft(s,aliveP(s)[0]||s.party[0],'OVERFLOW '+v,'man',1); s.mana=0;
  }
  for(const e of s.enemies){
    if(e.hp<=0||!e.intent) continue;
    EV(s,{t:'eact',uid:e.uid});
    if(e.st.stun){ e.st.stun=0; ft(s,e,'STUNNED','deb'); continue; }
    execFace(s,e,e.intent.tgt);
    if(!realP(s).some(u=>u.hp>0)) break;
  }
  EV(s,{t:'tick'});
  tickStatus(s);
  if(checkEnd(s)) return;
  s.turn++; s.stat.turns++;
  s.rerolls=s.maxRerolls; s.usedActives=[]; s.resonanceLog=[];
  s.party.forEach(u=>{ if(u.frozen) u.frozen=false; });
  rcall(s,'onTurnStart',null);
  bossTurnTraits(s);
  rollAll(s);
  /* G1 / ENG-18 — growthAll. `growth` hôm nay chỉ cộng cho ĐÚNG MẶT vừa dùng, nên ở Ω=5 lượt
     giá trị ≈ 0 và EVOLVE không có relic hợp bậc nào. growthAll cộng cho MỌI mặt của die.
     Guard !p.token bắt buộc: token không đi qua buildUnit, u.growth của chúng không bền.
     Guard theo lượt nằm trong THÂN relic (growthAllGuard), không nằm trong spec G1. */
  let ga=0;
  for(const r of rlist(s)){ if(!r.growthAll) continue;
    if(r.growthAllGuard&&!r.growthAllGuard(s)) continue; ga+=r.growthAll; }
  if(ga) s.party.forEach(p=>{ if(p.hp>0&&!p.token){
    p.die.forEach((f,i)=>{ if(f.v>0) p.growth[i]=(p.growth[i]||0)+ga; });
    ft(s,p,'GROW +'+ga,'buf'); EVrelic(s,'growthAll',p.uid); } });
  checkEnd(s);
}
function tickStatus(s){
  const ticks=Math.max(1,rmax(s,'poisonTicks',1));
  const plague=rhas(s,'plague');
  for(const u of s.party.concat(s.enemies)){
    if(u.hp<=0) continue;
    if(u.st.poison>0){
      const t=(u.side==='e')?ticks:1;
      for(let i=0;i<t;i++) if(u.hp>0) dealDamage(s,null,u,u.st.poison,{pierce:1});
      const keepFull = u.side==='e' && (plague || u.die.some(f=>hasKw(f,'plague')) || s.party.some(p=>p.die.some(f=>hasKw(f,'plague'))));
      if(!keepFull) u.st.poison--; else EVrelic(s,'plague',u.uid);   /* §3.9: plague 100% vô hình trước đây */
    }
    if(u.st.burn>0){
      const bm=rmax(s,'burnMult',1);
      const base=u.st.burn*(u.side==='e'?bm:1);
      dealDamage(s,null,u,base,{pierce:1});
      /* ENG-7 — đối xứng chính xác với poisonTicks (cũng rmax) thay vì phát minh khái niệm mới.
         Tick 2+ chỉ gây burnTickRatio phần: nếu không, r_hearthcore × r_solarcore = ×4 output. */
      const bt=Math.max(1,rmax(s,'burnTicks',1));
      if(u.side==='e'&&bt>1){
        const ratio=rmax(s,'burnTickRatio',0.7);
        for(let i=1;i<bt;i++) if(u.hp>0) dealDamage(s,null,u,Math.max(1,Math.ceil(base*ratio)),{pierce:1});
        EVrelic(s,'burnTicks',u.uid);
      }
      if(u.side==='e'&&rhas(s,'burnSpread')){
        const arr=aliveE(s), i=arr.indexOf(u), sp=Math.ceil(u.st.burn*0.5);
        [arr[i-1],arr[i+1]].forEach(x=>{ if(x&&x!==u){ x.st.burn=(x.st.burn||0)+sp; ft(s,x,'BUR'+sp,'deb'); } });
      }
      u.st.burn = rhas(s,'burnSlow')? u.st.burn-1 : Math.floor(u.st.burn/2);
    }
    if(u.st.regen>0){ applyHeal(s,u,u.st.regen); u.st.regen--; }
    ['blind','weaken','vulnerable'].forEach(k=>{ if(u.st[k]>0) u.st[k]--; });
  }
}
function checkEnd(s){
  if(!aliveE(s).length){ finishCombat(s); return true; }
  if(!realP(s).some(u=>u.hp>0)){ s.phase='lost'; return true; }
  return false;
}
function finishCombat(s){
  const k=s.kind;
  /* ENG-3 — giữ MỘT NỬA growth kiếm được trong trận, trần GROWTH_KEEP_CAP mỗi mặt.
     Trần này là bắt buộc, không phải tuỳ chọn: đây là relic DUY NHẤT tích luỹ qua các trận,
     và không trần thì nó đo được ≈70 RP = 1.6× trần LEGENDARY (§6.7.2).
     s.party[i] khớp s.roster[i] vì startCombat dựng party bằng s.roster.map(); token được
     push SAU nên không bao giờ lọt vào vòng này. */
  if(rhas(s,'growthKeep')) for(let i=0;i<s.roster.length;i++){
    const re=s.roster[i], u=s.party[i];
    if(!re||!u||u.token) continue;
    if(!re.grown) re.grown={};
    for(let g=0;g<u.die.length;g++){
      const seeded=re.grown[g]||0, earned=(u.growth[g]||0)-seeded;
      if(earned>0) re.grown[g]=Math.min(GROWTH_KEEP_CAP, seeded+Math.floor(earned/2));
    }
  }
  s.shards += k==='boss'?90:k==='elite'?45:25;
  s.rewardTier = k==='boss'?3:k==='elite'?2:(s.step%3===0?1:0);
  if(k==='boss'&&s.step>=s.len){ s.phase='won'; return; }
  genRewards(s,k); s.phase='reward';
}

/* ================= REWARDS ================= */
function facePool(s,minR,maxR){
  const cap = s.unlockFaceMax!=null? s.unlockFaceMax : 4;
  const bp = s.bpFaces||[];
  return FACE_POOL.filter(f=>f.r>=minR&&f.r<=Math.min(maxR,cap)&&(!f.bp||bp.includes(f.bp)));
}
/* §3.7 nguồn 2 — một keyword đang có trên mặt party đã cấp sẵn luật của relic, nên relic đó
   là dead draw. Phải đọc mặt SAU mutation (buildUnit), không phải HEROES[key].die, vì mặt
   Mythic đến từ `muts`. buildUnit không dùng RNG ⇒ tất định. */
function partyKeywords(s){
  const out=new Set();
  for(const re of (s.roster||[])){
    let die; try{ die=buildUnit(re,s).die; }catch(e){ continue; }
    for(const f of die) for(const k of f.k){ const t=KW_EX[k.split(':')[0]]; if(t) out.add(t); }
  }
  return out;
}
const mloadHeld = s => rlist(s).reduce((a,r)=>a+(r.mload||0),0);
/* §3.6 + §3.7 — thi hành ở ĐIỂM PHÁT, không ở điểm tính: người chơi không bao giờ được đề nghị
   một relic họ không dùng an toàn được. Không UI mới, không màn "chọn bỏ relic nào", và pool
   vẫn là hàm thuần của s.relics ⇒ không phá determinism. */
function relicConflict(s,r){
  if((s.relics||[]).length>=RELIC_CAP) return true;                  /* trần thứ hai */
  if(mloadHeld(s)+(r.mload||0)>RELIC_MLOAD_CAP) return true;         /* anti-stacking */
  /* Hai tập KHÁC NHAU, và sự khác nhau đó chính là tính bất đối xứng của §3.7a:
       heldEx = token `ex` của relic ĐANG GIỮ       -> nguồn duy nhất cho `exSub`
       owned  = heldEx + token suy ra từ KW_EX của mặt party -> nguồn cho `ex` (§3.7) */
  const heldEx=new Set();
  for(const h of rlist(s)) for(const t of (h.ex||[])) heldEx.add(t);
  const owned=new Set(heldEx);
  for(const t of partyKeywords(s)) owned.add(t);
  if((r.ex||[]).some(t=>owned.has(t))) return true;                  /* §3.7  — ĐỐI XỨNG */
  /* §3.7a — MỘT CHIỀU: "đừng đề nghị TÔI nếu một superset đã được giữ".
     `exSub` chỉ đọc, KHÔNG BAO GIỜ đổ vào heldEx/owned ⇒ subset đang giữ không thể chặn
     superset. Đây là toàn bộ lý do mục này tồn tại: `ex` đối xứng sẽ khiến r_gorehook
     (COMMON, 11.88 RP) CẤM r_apexferal (LEGENDARY) xuất hiện — một món nhặt sớm rẻ tiền xoá
     mất phần thưởng cuối build, đảo ngược đúng đường tiến bộ §3.12 sinh ra để bảo vệ.
     ⚠ GIỚI HẠN ĐÃ BIẾT, không sửa ở đây: lấy subset TRƯỚC rồi superset sau thì subset vẫn
     thành 0 HỒI TỐ. Chặn điều đó cần cơ chế hoàn trả (refund/xoá relic) — là content thật,
     không phải một luật pool. `exSub` mua đúng nửa có giá trị hơn: game KHÔNG BAO GIỜ đề nghị
     một relic đã chết sẵn. Hàm vẫn thuần theo (s.relics, roster) ⇒ không phá determinism. */
  return (r.exSub||[]).some(t=>heldEx.has(t));
}
function relicPool(s,maxR){
  const cap = s.unlockRelicMax!=null? s.unlockRelicMax : 3;
  return RELICS.filter(r=>r.rar<=Math.min(maxR,cap)&&!s.relics.includes(r.id)&&!relicConflict(s,r));
}
function genRewards(s,kind){
  const tier=s.rewardTier, n=s.mods.rewards;
  const pwr=s.pw;
  /* rarity band theo tier + tiến độ */
  const band = tier>=3? [2,4] : tier===2? [1,3] : tier===1? [1,2] : [0,1+(pwr>6?1:0)];
  const out=[]; const pool=[];
  const canLevel=s.roster.filter(r=>TIER_UP[r.key]);
  if(canLevel.length) pool.push('level','level'); else pool.push('ascend','ascend');
  /* design/gdd/part-skill-identity.md §3.4c — Axie import KHÔNG BAO GIỜ level được (chúng không có
     entry trong TIER_UP), nên với nhánh else ở trên, một đội trộn hero + vault chỉ thấy 'ascend'
     khi KHÔNG hero nào còn level được — tức gần như không bao giờ trong phần lớn một run. Kết quả:
     con Axie import bị bỏ đói đúng đường tăng trưởng duy nhất của nó.
     Sửa bằng cách THÊM vào pool, không thay nhánh else: đội TOÀN HERO có phân phối pool y hệt
     trước (AC-31), vì điều kiện đòi có ít nhất một thành viên `imported` không level được. */
  const importedStuck=s.roster.filter(r=>{ const h=HEROES[r.key]; return h&&h.imported&&!TIER_UP[r.key]; });
  if(canLevel.length&&importedStuck.length) pool.push('ascend','ascend');
  pool.push('relic','relic','face','face','rune');
  if(s.maxRerolls<4) pool.push('reroll');
  pool.push('hp');
  if(tier>=2) pool.push('relic','face','chaos');
  if(tier>=3) pool.push('relic','face','chaos','curse');
  let g=0;
  while(out.length<n&&g++<80){
    const t=pick(pool);
    const r=mkReward(s,t,band,out);
    if(r) out.push(r);
  }
  while(out.length<n){ const r=mkReward(s,'hp',band,out); if(r) out.push(r); else break; }
  s.rewards=out;
}
function mkReward(s,t,band,out){
  const dup=(k,v)=>out.some(o=>o.t===k&&o.key===v);
  if(t==='level'){
    const c=s.roster.filter(x=>TIER_UP[x.key]&&!out.some(o=>o.t==='level'&&o.uid===x.uid));
    if(!c.length) return null; const e=pick(c), nk=TIER_UP[e.key];
    return {t:'level',uid:e.uid,key:nk,rar:2,title:'LEVEL UP',
      desc:`${HEROES[e.key].n} -> ${HEROES[nk].n}`,sub:'Rewrites all six faces and Max HP',cls:HEROES[nk].cls,tier:HEROES[nk].tier};
  }
  if(t==='ascend'){
    const c=s.roster.filter(x=>!TIER_UP[x.key]&&!out.some(o=>o.t==='ascend'&&o.uid===x.uid));
    if(!c.length) return null; const e=pick(c);
    return {t:'ascend',uid:e.uid,rar:2,title:'ASCENSION',desc:`${HEROES[e.key].n}: all six faces +25%`,sub:'+6 Max HP · stacks without limit',cls:HEROES[e.key].cls,tier:4};
  }
  if(t==='relic'){
    const p=relicPool(s,band[1]).filter(r=>!dup('relic',r.id));
    if(!p.length) return null;
    const w=p.filter(r=>r.rar>=band[0]); const it=pick(w.length?w:p);
    return {t:'relic',key:it.id,rar:it.rar,title:'RELIC',desc:it.n,sub:it.d,arch:it.a};
  }
  if(t==='face'){
    const p=facePool(s,band[0],band[1]); if(!p.length) return null;
    const f=pick(p); const e=pick(s.roster); const idx=ri(6);
    return {t:'face',uid:e.uid,idx,face:clone(f),rar:f.r,title:'GENE MUTATION',
      desc:`${HEROES[e.key].n} · face ${idx+1}`,sub:faceText(f),cls:HEROES[e.key].cls,tier:HEROES[e.key].tier,arch:faceArch(f)};
  }
  if(t==='rune'){
    const e=pick(s.roster); const u=buildUnit(e,s);
    const valid=u.die.map((f,i)=>i).filter(i=>u.die[i].t!=='blank');
    if(!valid.length) return null; const idx=pick(valid); const kw=pick(RUNES);
    if(u.die[idx].k.includes(kw)) return null;
    return {t:'rune',uid:e.uid,idx,kw,rar:1,title:'RUNE IMBUE',
      desc:`${HEROES[e.key].n} · face ${idx+1} (${u.die[idx].p})`,sub:'Adds the keyword ['+kwText(kw)+']',cls:HEROES[e.key].cls,tier:HEROES[e.key].tier};
  }
  if(t==='reroll'){ if(out.some(o=>o.t==='reroll')) return null;
    return {t:'reroll',rar:1,title:'REROLL +1',desc:`Maximum ${s.maxRerolls} -> ${s.maxRerolls+1}`,sub:'Lasts the whole run'}; }
  if(t==='hp'){ const e=pick(s.roster); const v=6+Math.floor(s.pw*0.9);
    return {t:'hp',uid:e.uid,v,rar:0,title:'GENE VITALITY',desc:`${HEROES[e.key].n}: +${v} Max HP`,sub:'',cls:HEROES[e.key].cls,tier:HEROES[e.key].tier}; }
  if(t==='chaos'){ if(out.some(o=>o.t==='chaos')) return null;
    const p=relicPool(s,3).filter(r=>r.rar>=2); if(!p.length) return null; const it=pick(p);
    return {t:'chaos',key:it.id,rar:4,title:'CHAOS DEAL',desc:it.n,
      sub:'GAMBLE: the whole party loses 20% Max HP for the rest of the run\n'+it.d,arch:it.a}; }
  if(t==='curse'){ if(out.some(o=>o.t==='curse')) return null;
    return {t:'curse',rar:4,title:'CURSE PACT',desc:'Enemies gain 18% HP and 12% damage for the rest of the run',
      sub:'IN EXCHANGE: all damage faces deal 4 more, and 1 extra maximum Reroll'}; }
  return null;
}
/* Archetype của một MẶT — bảng ưu tiên tường minh, khớp đầu tiên thắng.
   Nguồn: design/gdd/relic-system.md §3.4 (12 dòng, thứ tự dưới đây LÀ luật, không phải
   thứ tự tình cờ của một if-chain). Luật phát biểu bằng lời: "archetype của một mặt là
   archetype hiếm nhất và khó thay thế nhất mà nó thuộc về — keyword trước type;
   accumulator (poison/thorns) trước burst; điều kiện (exec) trước xác suất (crit);
   phạm vi (aoe) cuối cùng."
   Bản cũ KHÔNG BAO GIỜ trả 'thorns' hay 'exec' ⇒ AEGIS là archetype không mặt nào nuôi
   được (Reptile không nuôi nổi chính SCALES của mình) và mọi mặt `exec` nuôi 0 archetype. */
const ARCH_PRIORITY = [
  ['summon', f => f.t === 'summon'],                       /* 1  type độc quyền */
  ['poison', f => f.t === 'poison' || hasKw(f, 'poison')], /* 2  accumulator bậc hai */
  ['thorns', f => hasKw(f, 'thorns')],                     /* 3  thorns không bao giờ giảm */
  ['burn',   f => hasKw(f, 'burn')],                       /* 4  cần mật độ mới hoạt động */
  ['exec',   f => hasKw(f, 'exec')],                       /* 5  điều kiện, ×1.6 với FERAL */
  ['crit',   f => hasKw(f, 'crit')],                       /* 6  xác suất, sau điều kiện */
  ['growth', f => hasKw(f, 'growth')],                     /* 7 */
  ['pierce', f => hasKw(f, 'pierce')],                     /* 8 */
  ['mana',   f => f.t === 'mana' || hasKw(f, 'mana')],     /* 9  type xuống dưới keyword */
  ['shield', f => f.t === 'shield'],                       /* 10 sau thorns — có chủ ý */
  ['aoe',    f => hasKw(f, 'aoe') || hasKw(f, 'cleave')],  /* 11 phạm vi, không phải bản sắc */
];
function faceArch(f){
  for(const [a, test] of ARCH_PRIORITY) if(test(f)) return a;
  return '';   /* 12  dmg/heal/debuff/buff trơn là mặt trung tính — đúng, không phải thiếu sót */
}
const KWT={cleave:'Cleave',pierce:'Pierce',aoe:'All',cantrip:'Cantrip',heavy:'Heavy',growth:'Growth',
  decay:'Decay',vital:'Vital',lifesteal:'Lifesteal',rerollup:'+Reroll',exec:'Execute',echo:'Echo x2',
  plague:'Plague',bastion:'Bastion',overflow:'Overflow',selfkill:'Self-destruct',enrage:'Enrage',freeze:'Freeze',stun:'Stun',
  multi:'Multi',chain:'Chain',selfharm:'Self-damage',crit:'Crit',burn:'Burn',poison:'Poison',thorns:'Thorns',
  regen:'Regen',blind:'Blind',weaken:'Weaken',vulnerable:'Vulnerable',mana:'Mana',undying:'Undying'};
function kwText(k){ const [n,v]=k.split(':'); return (KWT[n]||n)+(v?' '+v:''); }
const TT={dmg:'Damage',shield:'Shield',heal:'Heal',mana:'Mana',poison:'Poison',buff:'Buff',debuff:'Debuff',summon:'Summon',blank:'Blank'};
function faceText(f){
  const parts=[]; parts.push((f.p||'').toUpperCase());
  parts.push(TT[f.t]+(f.v>0?' '+f.v:''));
  if(f.k.length) parts.push('['+f.k.map(kwText).join(' · ')+']');
  return parts.join(' · ');
}

function rerollRewards(s){
  if(s.rerollReward<=0||!s.rewards) return false;
  s.rerollReward--; genRewards(s,s.kind||'battle'); return true;
}
function takeReward(s,i){
  const r=s.rewards&&s.rewards[i]; if(!r) return false;
  applyReward(s,r);
  s.rewards=null; s.pw++; s.rerollReward=s.rrwMax||1;
  afterNode(s); return true;
}
function applyReward(s,r){
  const ent=u=>s.roster.find(x=>x.uid===u);
  if(r.t==='level') ent(r.uid).key=r.key;
  else if(r.t==='ascend'){ const e=ent(r.uid); e.muts.push({type:'oc',mult:1.25}); e.bonusHp+=6; }
  else if(r.t==='relic'){ s.relics.push(r.key); s.seen.relics.push(r.key); }
  else if(r.t==='face'){ ent(r.uid).muts.push({type:'part',idx:r.idx,face:r.face}); s.seen.faces.push(faceText(r.face)); }
  else if(r.t==='rune') ent(r.uid).muts.push({type:'rune',idx:r.idx,kw:r.kw});
  else if(r.t==='reroll') s.bonusReroll=(s.bonusReroll||0)+1;
  else if(r.t==='hp') ent(r.uid).bonusHp+=r.v;
  else if(r.t==='chaos'){ s.relics.push(r.key); s.seen.relics.push(r.key);
    s.roster.forEach(e=>{ const h=HEROES[e.key]; e.bonusHp-=Math.round((h.hp+e.bonusHp)*0.2); }); }
  else if(r.t==='curse'){ s.runMods.enemyHp*=1.18; s.runMods.enemyDmg*=1.12; s.curses.push('CURSE PACT');
    s.relics.push('__curse_dmg'); s.bonusReroll=(s.bonusReroll||0)+1; }
}
/* pseudo-relic cho curse */
RELIC_BY_ID['__curse_dmg']={id:'__curse_dmg',n:'Curse Pact',rar:4,a:'',d:'Every damage face deals +4.',
  modFace:u=>u.die.forEach(f=>{ if(f.t==='dmg')f.v+=4; })};

function afterNode(s){ if(s.step>=s.len&&s.bossSteps.includes(s.step)) s.phase='won'; else nextStep(s); }

/* ================= EVENT ================= */
function eventChoose(s,i){
  const ev=s.event; if(!ev||ev.res!=null) return false;
  const o=ev.def.opts[i]; if(!o) return false;
  const msg=applyEventFx(s,o.fx);
  ev.res={opt:o,msg};
  return true;
}
function applyEventFx(s,fx){
  const R=e=>s.roster[ri(s.roster.length)];
  if(fx==='bless_reroll'){ s.bonusReroll=(s.bonusReroll||0)+1; return 'You permanently gain 1 maximum Reroll.'; }
  if(fx==='gamble_legend'){ const p=relicPool(s,3).filter(r=>r.rar>=3); const it=p.length?pick(p):pick(relicPool(s,2));
    if(it){s.relics.push(it.id); s.seen.relics.push(it.id);}
    s.roster.forEach(e=>{ const h=HEROES[e.key]; e.bonusHp-=Math.round((h.hp+e.bonusHp)*0.2); });
    return 'Received '+(it?it.n:'nothing')+'. The whole party loses 20% Max HP.'; }
  if(fx==='pray'){ const e=R(); e.bonusHp+=8; return HEROES[e.key].n+' gains 8 Max HP.'; }
  if(fx==='chest'){ const p=relicPool(s,3).filter(r=>r.rar>=1); const it=p.length?pick(p):null;
    if(it){s.relics.push(it.id);s.seen.relics.push(it.id);} return 'You found a relic: '+(it?it.n:'nothing'); }
  if(fx==='shards60'){ s.shards+=60; return 'You gained 60 Gene Shard.'; }
  if(fx==='shards30'){ s.shards+=30; return 'You gained 30 Gene Shard.'; }
  if(fx==='rest'){ const e=R(); e.bonusHp+=12; return HEROES[e.key].n+' gains 12 Max HP.'; }
  if(fx==='forge'){ const e=R(); e.muts.push({type:'oc',mult:1.3}); return HEROES[e.key].n+' is 30% stronger on all six faces.'; }
  if(fx==='meditate'){ s.roster.forEach(e=>e.bonusHp+=4); return 'The whole party gains 4 Max HP.'; }
  if(fx==='bet_small'){ if(rnd()<0.5){ const p=relicPool(s,2).filter(r=>r.rar>=2); const it=p.length?pick(p):null;
      if(it){s.relics.push(it.id);s.seen.relics.push(it.id);} return 'YOU WIN! Received '+(it?it.n:'nothing'); }
    s.roster.forEach(e=>{const h=HEROES[e.key]; e.bonusHp-=Math.round((h.hp+e.bonusHp)*0.1);}); return 'YOU LOSE. The whole party loses 10% Max HP.'; }
  if(fx==='bet_big'){ if(rnd()<0.4){ const p=facePool(s,4,4); const f=p.length?pick(p):pick(facePool(s,3,3));
      const e=R(); if(f){e.muts.push({type:'part',idx:ri(6),face:clone(f)}); s.seen.faces.push(faceText(f));}
      return 'YOU WIN! '+HEROES[e.key].n+' gains the face '+(f?faceText(f):'nothing'); }
    if(s.relics.length){ const id=s.relics.splice(ri(s.relics.length),1)[0]; return 'YOU LOSE. Relic destroyed: '+(RELIC_BY_ID[id]?RELIC_BY_ID[id].n:id); }
    return 'YOU LOSE. Luckily you had no relic to lose.'; }
  if(fx==='dip'){ const e=R(); const p=facePool(s,2,2);
    for(let i=0;i<2;i++){ const f=p.length?pick(p):null; if(f) e.muts.push({type:'part',idx:ri(6),face:clone(f)}); }
    return HEROES[e.key].n+' gains 2 random Epic faces.'; }
  if(fx==='drink'){ const e=R(); e.bonusHp-=8; const p=facePool(s,3,3); const f=p.length?pick(p):null;
    if(f){e.muts.push({type:'part',idx:ri(6),face:clone(f)}); s.seen.faces.push(faceText(f));}
    return HEROES[e.key].n+' loses 8 Max HP and gains '+(f?faceText(f):'nothing'); }
  if(fx==='leave') return 'The whole party heals to full.';
  return '';
}
function eventDone(s){ s.event=null; s.pw++; afterNode(s); }

/* ================= SHOP ================= */
function genShop(s){
  const items=[];
  const rp=relicPool(s,3);
  shuffle(rp).slice(0,3).forEach(r=>items.push({kind:'relic',key:r.id,n:r.n,d:r.d,rar:r.rar,
    cost:RELIC_SHOP_COST[r.rar],arch:r.a}));
  const fp=facePool(s,1,3);
  shuffle(fp).slice(0,2).forEach(f=>{ const e=pick(s.roster);
    items.push({kind:'face',face:clone(f),uid:e.uid,idx:ri(6),n:'GENE · '+HEROES[e.key].n,
      d:faceText(f),rar:f.r,cost:[40,60,100,150,240][f.r]||60,arch:faceArch(f)}); });
  items.push({kind:'heal',n:'Serum',d:'One Axie gains 10 Max HP',rar:0,cost:40});
  items.push({kind:'reroll',n:'Instinct',d:'1 extra maximum Reroll',rar:2,cost:110});
  s.shop={items,bought:[]};
}
function shopBuy(s,i){
  const it=s.shop.items[i];
  if(!it||s.shop.bought.includes(i)||s.shards<it.cost) return false;
  s.shards-=it.cost; s.shop.bought.push(i);
  if(it.kind==='relic'){ s.relics.push(it.key); s.seen.relics.push(it.key); }
  else if(it.kind==='face'){ const e=s.roster.find(x=>x.uid===it.uid); e.muts.push({type:'part',idx:it.idx,face:it.face}); s.seen.faces.push(faceText(it.face)); }
  else if(it.kind==='heal'){ pick(s.roster).bonusHp+=10; }
  else if(it.kind==='reroll'){ s.bonusReroll=(s.bonusReroll||0)+1; }
  return true;
}
function shopDone(s){ s.shop=null; s.pw++; afterNode(s); }

/* ================= ARCHETYPE SCORE ================= */
function archScore(s){
  const sc={};
  for(const k in ARCH) sc[k]=0;
  for(const id of s.relics){ const r=RELIC_BY_ID[id]; if(r&&r.a&&sc[r.a]!=null) sc[r.a]+=(r.rar>=3?3:r.rar>=2?2:1); }
  for(const e of s.roster){
    const a=PASSIVE[HEROES[e.key].cls].a; if(sc[a]!=null) sc[a]+=1;
    for(const m of e.muts) if(m.type==='part'){ const a2=faceArch(m.face); if(a2&&sc[a2]!=null) sc[a2]+=(m.face.r>=3?3:m.face.r>=2?2:1); }
  }
  return sc;
}

if(typeof module!=='undefined') module.exports={facePool,rerollRewards,mkRng,newGame,nextStep,chooseNode,startCombat,rollAll,doReroll,
  anyRerollable,playerUseDie,playerUseRelic,endTurn,undo,takeReward,genRewards,buildUnit,dieRarity,aliveP,aliveE,realP,
  byUid,faceValue,hasKw,kwVal,genEncounter,eventChoose,eventDone,genShop,shopBuy,shopDone,archScore,
  faceText,kwText,faceArch,RELIC_BY_ID,rlist,critChance,nftHpBonusPct,resonancePairs,axieToDie,mapAxieClass,
  ENGINE_VERSION};
