/* ============ AXIE DICE TACTICS v0.2 — ENGINE (pure, no DOM) ============ */

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

/* ================= ROSTER → UNIT ================= */
let UID=1;
function newRosterEntry(key,vr,nftBonusPct){ return {uid:UID++,key,vr:vr||0,muts:[],bonusHp:0,nftBonusPct:nftBonusPct||0}; }

/* NFT HP Bonus (design/gdd/economy-progression.md §10.2a — ngoại lệ có phạm vi của D12).
   Chỉ áp dụng cho Axie NFT được CHỌN TRƯỚC vào đội hình (không áp dụng Axie tuyển ngẫu nhiên).
   ownedCount = tổng số Axie NFT người chơi sở hữu · specialGenes = 0-3 (thuộc tính Axie thật). */
const NFT_BONUS_BASE=3, NFT_BONUS_CAP=20;
function nftOwnershipMult(ownedCount){ return ownedCount>=20?1.5 : ownedCount>=5?1.25 : 1.0; }
function nftRarityMult(specialGenes){ return [1.0,1.15,1.3,1.5][Math.max(0,Math.min(3,specialGenes|0))]; }
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
  if(s) for(const r of rlist(s)) if(r.modFace) r.modFace(u);
  if(s&&s.metaHpBonus) u.maxHp+=s.metaHpBonus;
  u.hp=u.maxHp;
  return u;
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
    mana:0,manaSpent:0,rerolls:2,maxRerolls:2+(opt.bonusReroll||0),metaHpBonus:opt.metaHpBonus||0,
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
  s.enemies=genEncounter(s,kind);
  s.turn=1; s.mana=0; s.manaSpent=0; s.maxRerolls=2+(s.bonusReroll||0)+rsum(s,'rerollUp');
  s.rerolls=s.maxRerolls; s.phase='combat'; s.undo=[]; s.log=[]; s.usedActives=[]; s.floatText=[]; s.ev=[];
  s.lastBig=null; s._firstUsed=0; s._condGiven=0;
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
  return {uid:UID++,side:'p',token:1,key:'egg',n:'Axie Egg',cls:'aqua',tier:1,artIdx:1,pas:null,
    maxHp:hp,hp,shield:0,die:scaleDie(m.die,sc*0.5),st:{},rolled:-1,used:false,heavy:false,frozen:false,growth:{},critNow:false};
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
  if(s.rerolls<=0) return false;
  const list=uids.filter(id=>{ const u=byUid(s,id); return u&&u.side==='p'&&u.hp>0&&!u.used&&!u.heavy&&!u.frozen; });
  if(!list.length) return false;
  s.rerolls--;
  list.forEach(id=>rollUnit(s,byUid(s,id)));
  resolveCantrips(s);
  if(!rhas(s,'safeReroll')) s.undo=[];
  return true;
}

/* ================= DAMAGE PIPELINE ================= */
function EV(s,o){ if(!s.ev) s.ev=[]; if(s.ev.length>900) s.ev.length=0; s.ev.push(o); }
function EVhp(s,u){ EV(s,{t:'hp',uid:u.uid,hp:u.hp,maxHp:u.maxHp,shield:u.shield}); }
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
    if(o.crit) v*=rmax(s,'critMult',2);
  }
  /* ---- target side ---- */
  if(tgt.st.vulnerable>0) v=Math.ceil(v*1.5);
  if(tgt.side==='p'){ const dr=rsum(s,'dr'); if(dr>0) v=Math.max(1,Math.ceil(v*(1-dr))); }
  let dealt=0;
  EV(s,{t:'hit',src:src?src.uid:null,uid:tgt.uid,v:v,crit:!!o.crit});
  if(!pierce&&tgt.shield>0){ const ab=Math.min(tgt.shield,v); tgt.shield-=ab; v-=ab; if(ab>0) ft(s,tgt,'-'+ab,'shd'); }
  if(v>0){ tgt.hp-=v; dealt=v; ft(s,tgt,(o.crit?'CRIT ':'')+'-'+v,'dmg',o.crit?2:(v>=25?1:0)); }
  if(tgt.hp<=0&&tgt.st.undying){ tgt.st.undying=0; tgt.hp=1; ft(s,tgt,'UNDYING','buf'); }
  if(tgt.hp<0) tgt.hp=0;
  EVhp(s,tgt);
  if(tgt.hp<=0) EV(s,{t:'death',uid:tgt.uid});
  /* stats */
  if(src&&src.side==='p'){ s.stat.dmg+=dealt; if(dealt>s.stat.maxHit) s.stat.maxHit=dealt; }
  if(tgt.side==='p') s.stat.taken+=dealt;
  /* thorns (pierce+piercePlus relic bỏ qua thorns) */
  const skipThorns = pierce && rhas(s,'piercePlus');
  if(src&&o.attack&&!skipThorns&&tgt.st.thorns>0&&src.hp>0&&src!==tgt){
    let th=tgt.st.thorns;
    if(tgt.side==='p') th*=rmax(s,'thornsMult',1);
    EV(s,{t:'hit',src:tgt.uid,uid:src.uid,v:th,crit:false});
    src.hp-=th; ft(s,src,'-'+th,'dmg');
    if(tgt.side==='p'&&tgt.cls==='reptile') addStatus(s,src,['poison:1']);
    if(src.hp<=0&&src.st.undying){src.st.undying=0;src.hp=1;}
    if(src.hp<0) src.hp=0;
    EVhp(s,src); if(src.hp<=0) EV(s,{t:'death',uid:src.uid});
    if(src.hp<=0&&src.side==='e') onEnemyDeath(s,src);
  }
  /* onHit relic hooks */
  if(src&&src.side==='p'&&dealt>0){
    for(const r of rlist(s)) if(r.onHit) r.onHit(s,{type:o.faceType||'dmg',dealt,tgt,addStatus:kw=>addStatus(s,tgt,[kw])});
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
  const cap = (t.side==='p'&&rhas(s,'noShieldCap'))? 99999 : t.maxHp*2;
  t.shield=Math.min(cap,t.shield+v); ft(s,t,'+'+v,'shd'); EVhp(s,t);
  if(t.side==='p'&&t.cls==='plant'&&t.shield>=10) t.st.thorns=Math.max(t.st.thorns||0,2);
  if(t.side==='p') rcall(s,'onShield',{v,splash:m=>{ const es=aliveE(s); if(es.length) dealDamage(s,t,pick(es),Math.ceil(v*m),{attack:false}); }});
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
      t.st[n]=(t.st[n]||0)+v; ft(s,t,n.slice(0,3).toUpperCase()+v,(n==='thorns'||n==='regen')?'buf':'deb');
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
  return v;
}
const neighborsOf=(arr,t)=>{ const i=arr.indexOf(t),o=[]; if(i>0)o.push(arr[i-1]); if(i>=0&&i<arr.length-1)o.push(arr[i+1]); return o; };

function execFace(s,u,tgtUid){
  const fi=u.rolled; if(fi<0||u.used) return false;
  const f=u.die[fi];
  if(f.t==='blank') return false;
  let reps = hasKw(f,'echo')?2:1;
  if(u.side==='p'&&rhas(s,'firstEcho')&&!s._firstUsed) reps=Math.max(reps,2);
  EV(s,{t:'use',uid:u.uid,side:u.side,tgt:tgtUid,aoe:hasKw(f,'aoe')||f.t==='mana'||f.t==='summon'});
  const ok=doFace(s,u,tgtUid,f,fi);
  if(!ok) return false;
  if(u.side==='p') s._firstUsed=1;
  for(let i=1;i<reps;i++) doFace(s,u,tgtUid,f,fi,true);
  u.used=true;
  if(u.side==='p'&&u.critNow) u.critNow=false;
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
      attack:true,crit,exec:hasKw(f,'exec'),faceType:'dmg'});
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
        if(hasKw(f,'cleave')) neighborsOf(foes,tgt).forEach(t=>hit(t,Math.ceil(v*0.5)));
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
    if(u.side==='p'){ for(let i=0;i<v;i++) if(s.party.filter(x=>x.token&&x.hp>0).length<4){ const a=mkAlly(s); rollUnit(s,a); a.used=true; s.party.push(a); } ft(s,u,'SUMMON','buf'); }
    else { const k=u.summons||'egg'; for(let i=0;i<v;i++) if(s.enemies.length<7){ const m=mkMonster(k,u.sc*0.7,{hp:1,dmg:1}); rollUnit(s,m); pickEnemyIntent(s,m); s.enemies.push(m); } }
  }
  if(!isEcho){
    const sh=kwVal(f,'selfharm'); if(sh) dealDamage(s,null,u,sh,{pierce:1});
    const mn=kwVal(f,'mana'); if(mn&&u.side==='p') s.mana+=mn;
    if(hasKw(f,'rerollup')&&u.side==='p') s.rerolls++;
    if(hasKw(f,'growth')) u.growth[fi]=(u.growth[fi]||0)+1;
    if(hasKw(f,'decay')) u.growth[fi]=(u.growth[fi]||0)-1;
    if(u.side==='p'&&f.t==='dmg'&&v>0) s.lastBig=(!s.lastBig||v>s.lastBig.v)?{v,f:clone(f)}:s.lastBig;
  }
  return true;
}

/* ================= UNDO ================= */
const SNAP=['party','enemies','mana','manaSpent','rerolls','usedActives','turn','stat','_firstUsed','lastBig'];
function snap(s){ const o={}; SNAP.forEach(k=>o[k]=(s[k]===undefined?null:clone(s[k]))); return o; }
function pushUndo(s){ s.undo.push(snap(s)); if(s.undo.length>90) s.undo.shift(); }
function undo(s){ if(!s.undo.length) return false; const o=s.undo.pop(); SNAP.forEach(k=>s[k]=o[k]); s.ev=[]; s.floatText=[]; return true; }

function playerUseDie(s,uid,tgtUid){
  const u=byUid(s,uid); if(!u||u.side!=='p'||u.hp<=0||u.used) return false;
  pushUndo(s);
  if(!execFace(s,u,tgtUid)){ s.undo.pop(); return false; }
  checkEnd(s); return true;
}
function playerUseRelic(s,id,tgtUid){
  const it=RELIC_BY_ID[id]; if(!it||!it.act) return false;
  if(s.usedActives.includes(id)||s.mana<it.act.cost) return false;
  pushUndo(s);
  const a=it.act, tgt=tgtUid!=null?byUid(s,tgtUid):null, u=aliveP(s)[0]; let ok=true;
  if(a.kind==='heal'){ if(!tgt||tgt.side!=='p'||tgt.hp<=0) ok=false; else applyHeal(s,tgt,a.v); }
  else if(a.kind==='dmg'){ if(!tgt||tgt.side!=='e'||tgt.hp<=0) ok=false; else dealDamage(s,u,tgt,a.v,{pierce:a.pierce,attack:true}); }
  else if(a.kind==='ult'){ if(!tgt||tgt.side!=='e'||tgt.hp<=0) ok=false; else { dealDamage(s,u,tgt,a.v,{pierce:1,attack:true}); aliveP(s).forEach(t=>applyShield(s,t,10)); } }
  else if(a.kind==='shieldall') aliveP(s).forEach(t=>applyShield(s,t,a.v));
  else if(a.kind==='dmgall') aliveE(s).slice().forEach(t=>dealDamage(s,u,t,a.v,{attack:true}));
  else if(a.kind==='poisonall') aliveE(s).slice().forEach(t=>addStatus(s,t,['poison:'+a.v],u));
  else if(a.kind==='stun'){ if(!tgt||tgt.side!=='e'||tgt.hp<=0) ok=false; else addStatus(s,tgt,['stun']); }
  else if(a.kind==='reroll') s.rerolls+=a.v;
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
  s.rerolls=s.maxRerolls; s.usedActives=[];
  s.party.forEach(u=>{ if(u.frozen) u.frozen=false; });
  rcall(s,'onTurnStart',null);
  bossTurnTraits(s);
  rollAll(s);
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
      if(!keepFull) u.st.poison--;
    }
    if(u.st.burn>0){
      const bm=rmax(s,'burnMult',1);
      dealDamage(s,null,u,u.st.burn*(u.side==='e'?bm:1),{pierce:1});
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
function relicPool(s,maxR){
  const cap = s.unlockRelicMax!=null? s.unlockRelicMax : 3;
  return RELICS.filter(r=>r.rar<=Math.min(maxR,cap)&&!s.relics.includes(r.id));
}
function genRewards(s,kind){
  const tier=s.rewardTier, n=s.mods.rewards;
  const pwr=s.pw;
  /* rarity band theo tier + tiến độ */
  const band = tier>=3? [2,4] : tier===2? [1,3] : tier===1? [1,2] : [0,1+(pwr>6?1:0)];
  const out=[]; const pool=[];
  const canLevel=s.roster.filter(r=>TIER_UP[r.key]);
  if(canLevel.length) pool.push('level','level'); else pool.push('ascend','ascend');
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
function faceArch(f){
  if(f.t==='poison') return 'poison';
  if(hasKw(f,'burn')) return 'burn';
  if(f.t==='shield') return 'shield';
  if(f.t==='mana') return 'mana';
  if(f.t==='summon') return 'summon';
  if(hasKw(f,'crit')) return 'crit';
  if(hasKw(f,'pierce')) return 'pierce';
  if(hasKw(f,'growth')) return 'growth';
  if(hasKw(f,'aoe')||hasKw(f,'cleave')) return 'aoe';
  return '';
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
    cost:[45,75,120,180][r.rar]||60,arch:r.a}));
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
  faceText,kwText,faceArch,RELIC_BY_ID,rlist,critChance,nftHpBonusPct};
