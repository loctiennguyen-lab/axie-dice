/* ============ AXIE DICE TACTICS v0.2 — UI ============ */
const $=q=>document.querySelector(q), $$=q=>[...document.querySelectorAll(q)];
const el=(t,c,x)=>{ const e=document.createElement(t); if(c)e.className=c; if(x!=null)e.textContent=x; return e; };
const btn=(c,x,fn)=>{ const b=el('button','btn '+(c||''),x); b.onclick=e=>{ SFX.ui(); fn(e); }; b.onmouseenter=()=>SFX.hover(); return b; };

let S=null, screen='menu', sel=null, selRelic=null, teamPick=[], msg='', SPD=1, tut=0;
let rollAnim=null, pendFloats=[], hoverT=null, logOpen=false;

/* ---------- META (localStorage, degrade gracefully) ---------- */
const MK='axiedice_meta_v2', RK='axiedice_run_v2';
const DEF_META={vol:0.28,mute:false,spd:1,shards:0,unlocks:[],ascMax:0,best:0,runs:0,wins:0,faces:[],relics:[],bosses:[],tut:0,
  xp:0,bpClaimed:[],bpFaces:[],perks:{},title:''};
let META={...DEF_META};
function loadMeta(){ try{ const j=localStorage.getItem(MK); if(j) META={...DEF_META,...JSON.parse(j)}; }catch(e){} }
function saveMeta(){ try{ localStorage.setItem(MK,JSON.stringify(META)); }catch(e){} }
function saveRun(){ try{ if(S&&S.phase!=='won'&&S.phase!=='lost') localStorage.setItem(RK,JSON.stringify({s:S,screen})); else localStorage.removeItem(RK); }catch(e){} }
function loadRun(){ try{ const j=localStorage.getItem(RK); if(!j) return null; return JSON.parse(j); }catch(e){ return null; } }
function clearRun(){ try{ localStorage.removeItem(RK); }catch(e){} }
const unlocked=id=>META.unlocks.includes(id);
function bpLevel(){ let lv=0,need=0; for(let i=1;i<=30;i++){ need+=BP_XP(i); if(META.xp>=need) lv=i; else break; } return lv; }
function bpProg(){ const lv=bpLevel(); let base=0; for(let i=1;i<=lv;i++) base+=BP_XP(i);
  const nxt=lv<30?BP_XP(lv+1):0; return {lv,cur:META.xp-base,need:nxt,pct:nxt?Math.min(100,100*(META.xp-base)/nxt):100}; }
function bpUnclaimed(){ const lv=bpLevel(); return BP.filter(b=>b.lv<=lv&&!META.bpClaimed.includes(b.lv)); }
function bpClaim(b){
  if(META.bpClaimed.includes(b.lv)) return;
  META.bpClaimed.push(b.lv); const r=b.r;
  if(r.t==='shard') META.shards+=r.v;
  else if(r.t==='unlock'){ if(!META.unlocks.includes(r.v)) META.unlocks.push(r.v); }
  else if(r.t==='face'){ if(!META.bpFaces.includes(r.v)) META.bpFaces.push(r.v);
    const f=BP_FACES[r.v]; if(f&&!META.faces.includes(faceText(f.face))) META.faces.push(faceText(f.face)); }
  else if(r.t==='perk') META.perks[r.v]=(META.perks[r.v]||0)+1;
  if(b.title) META.title=b.title;
  saveMeta();
}

/* ---------- sprites ---------- */
const MON_SPR={slime:['plant',2],chomper:['beast',1],spikelet:['reptile',2],bugling:['bug',0],jellyfin:['aqua',4],
  ravenling:['bird',5],thornback:['reptile',5],venomaw:['bug',4],bruiser:['beast',7],hexeye:['bug',7],
  cleaver:['beast',4],warden:['plant',7],stalker:['bird',3],pyrewing:['bird',7],broodmaw:['bug',5],
  bomblet:['aqua',7],totem:['plant',4],egg:['aqua',1],
  e_ravager:['beast',8],e_plague:['bug',8],e_bulwark:['plant',8],e_archon:['aqua',8],
  gooey_king:['plant',5],mecha:['reptile',8],frost_lord:['aqua',5],plague_mother:['bug',6],mirror:['reptile',4],agony:['bird',8]};
const sprOf=(cls,i)=>(AXIE_PIX[cls]&&AXIE_PIX[cls][((i%9)+9)%9])?AXIE_PIX[cls][((i%9)+9)%9].src:'';
const sprMon=k=>{ const m=MON_SPR[k]||['beast',0]; return sprOf(m[0],m[1]); };


const PARTN={mouth:'MOUTH',horn:'HORN',back:'BACK',tail:'TAIL',eyes:'EYES',ears:'EARS',blank:'',m:''};
const TYPEN={dmg:'Damage',shield:'Shield',heal:'Heal',mana:'Mana',poison:'Poison',
  buff:'Buff',debuff:'Debuff',summon:'Summon',blank:'Blank'};
const ST_NAME={poison:'Poison',burn:'Burn',regen:'Regen',thorns:'Thorns',blind:'Blind',
  weaken:'Weaken',vulnerable:'Vulnerable',stun:'Stun',undying:'Undying'};

/* ================= FX ================= */
function shake(n){ const a=$('#app'); if(!a) return; a.classList.remove('shk1','shk2','shk3');
  void a.offsetWidth; a.classList.add('shk'+Math.min(3,Math.max(1,n||1)));
  setTimeout(()=>a.classList.remove('shk1','shk2','shk3'),420/SPD); }
function flashScreen(cls){ const f=el('div','flashfx '+(cls||'')); document.body.appendChild(f); setTimeout(()=>f.remove(),300/SPD); }
function hitstop(ms){ const a=$('#app'); if(!a) return; a.classList.add('hstop'); setTimeout(()=>a.classList.remove('hstop'),(ms||90)/SPD); }
function bigText(t,cls){ const d=el('div','bigfx '+(cls||''),t); document.body.appendChild(d); setTimeout(()=>d.remove(),1100/SPD); }

function collectFloats(){ pendFloats=pendFloats.concat(S.floatText); S.floatText=[]; }
function paintFloats(){
  if(!pendFloats.length) return;
  const g={}; pendFloats.forEach(f=>{ (g[f.uid]=g[f.uid]||[]).push(f); });
  let maxHit=0, crit=false;
  for(const uid in g){
    const host=document.querySelector('.floats[data-uid="'+uid+'"]'); if(!host) continue;
    g[uid].forEach((f,i)=>{
      const n=el('div','ftx '+f.cls+(f.big?' b'+f.big:''),f.txt);
      n.style.animationDelay=(i*80/SPD)+'ms'; n.style.animationDuration=(1200/SPD)+'ms';
      n.style.left=(50+(i%3-1)*22)+'%'; host.appendChild(n);
      if(f.cls==='dmg'){ const v=Math.abs(parseInt(f.txt.replace(/[^0-9-]/g,''))||0); if(v>maxHit)maxHit=v; }
      if(f.big>=2) crit=true;
    });
  }
  if(maxHit>0){ SFX.hit(maxHit); if(maxHit>=20) shake(maxHit>=45?3:2); else shake(1); }
  if(crit){ SFX.crit(); hitstop(110); flashScreen('gold'); }
  pendFloats=[];
  setTimeout(()=>$$('.ftx').forEach(n=>n.remove()),1500/SPD);
}

/* ================= DICE ROLL ANIMATION ================= */
function triggerRollAnim(uids){
  rollAnim={uids:uids||S.party.filter(u=>u.hp>0&&u.rolled>=0).map(u=>u.uid),t0:performance.now()};
  SFX.tray();
}
function runRollAnim(){
  if(!rollAnim) return;
  const DUR=430/SPD, STAG=70/SPD;
  const boxes={}; $$('.diebox').forEach(b=>boxes[b.dataset.uid]=b);
  const order=rollAnim.uids.slice();
  const landed={};
  const step=()=>{
    if(!rollAnim) return;
    try{
    const now=performance.now(); let done=true;
    order.forEach((uid,i)=>{
      const b=boxes[uid]; if(!b) return;
      const u=byUid(S,uid); if(!u||u.rolled<0) return;
      const t=now-rollAnim.t0-i*STAG;
      const d=b.querySelector('.die'); if(!d) return;
      if(t<0){ d.classList.add('tumble'); b.classList.add('rolling'); done=false; return; }
      if(t<DUR){
        done=false; d.classList.add('tumble'); b.classList.add('rolling');
        const iv=Math.max(34,34+ (t/DUR)*90);
        const k=Math.floor(t/iv)%6;
        if(d.dataset.tf!=String(k)){ d.dataset.tf=String(k); paintDieFace(d,u,k,true); SFX.tumble(i); }
      } else if(!landed[uid]){
        landed[uid]=1; d.classList.remove('tumble'); b.classList.remove('rolling'); d.classList.add('landed');
        paintDieFace(d,u,u.rolled,false);
        const f=u.die[u.rolled]||u.die[0];
        if(hasKw(f,'heavy')) SFX.heavy(); else SFX.land(i,f.r);
        if(f.r>=4){ SFX.mythic(); hitstop(140); flashScreen('myth'); bigText('MYTHIC',''); }
        else if(f.r>=3){ SFX.legend(); flashScreen('gold'); }
        if(u.critNow){ d.classList.add('critready'); }
        setTimeout(()=>d.classList.remove('landed'),320/SPD);
      }
    });
    if(done){ rollAnim=null; render(); } else requestAnimationFrame(step);
    }catch(err){
      /* Never let a bad frame freeze the tray: without this the dice stay
         locked because clickDie() refuses input while rollAnim is set. */
      console.error('roll animation error',err);
      rollAnim=null; try{ render(); }catch(e){}
    }
  };
  requestAnimationFrame(step);
}
function paintDieFace(d,u,fi,temp){
  const f=u.die[fi]||u.die[0];
  d.className=d.className.replace(/t_\w+/g,'')+' t_'+f.t;
  d.dataset.r=f.r||0;
  d.innerHTML='';
  if(hasKw(f,'heavy')) d.appendChild(el('div','heavytag','HEAVY'));
  d.appendChild(el('div','dp',f.name||PARTN[f.p]||''));
  d.appendChild(ico(FT_IC[f.t],'di'));
  if(f.t==='blank') d.appendChild(el('div','dv blanktxt','BLANK'));
  else if(f.v>0||f.t==='dmg') d.appendChild(el('div','dv',String(temp?f.v:faceValue(S,u,fi))));
  const kws=f.k.filter(k=>k!=='cantrip'&&k!=='heavy');
  if(kws.length) d.appendChild(el('div','dk',kws.map(kwText).join(' · ')));
  if(!temp&&u.critNow) d.appendChild(el('div','critbadge','CRIT x'+rcritMult()));
  if(f.r>=1) d.appendChild(el('div','rartag','r'+f.r,''));
}
function rcritMult(){ let m=2; for(const id of S.relics){ const r=RELIC_BY_ID[id]; if(r&&r.critMult&&r.critMult>m)m=r.critMult; } return m; }

/* ================= RENDER ================= */
function render(){
  const root=$('#app'); if(!root) return;
  $$('.tutov').forEach(n=>n.remove());
  root.innerHTML=''; root.className='';
  if(screen==='menu') root.appendChild(scMenu());
  else if(screen==='team') root.appendChild(scTeam());
  else if(screen==='unlocks') root.appendChild(scUnlocks());
  else if(screen==='collection') root.appendChild(scCollection());
  else if(screen==='bp') root.appendChild(scBP());
  else if(screen==='codex') root.appendChild(scCodex());
  else if(screen==='guide') root.appendChild(scGuide());
  else if(S){
    if(S.phase==='map') root.appendChild(scMap());
    else if(S.phase==='event'){ root.appendChild(scCombatShell()); root.appendChild(scEvent()); }
    else if(S.phase==='shop'){ root.appendChild(scCombatShell()); root.appendChild(scShop()); }
    else if(S.phase==='reward'){ root.appendChild(scCombat(true)); root.appendChild(scReward()); }
    else if(S.phase==='won'||S.phase==='lost'){ root.appendChild(scCombat(true)); root.appendChild(scEnd()); }
    else root.appendChild(scCombat(false));
  }
  /* T11 · phone portrait gate — CSS decides when it shows */
  if(!$('.rotate-hint')){
    const rh=el('div','rotate-hint');
    rh.appendChild(el('div','rh-ic','[ ]'));
    rh.appendChild(el('div',null,'Rotate your device to landscape to play.'));
    rh.appendChild(el('div','sub','The board is five columns wide.'));
    document.body.appendChild(rh);
  }
  if(S&&modal==='info') root.appendChild(scInfo());
  if(S&&modal==='unit') root.appendChild(scUnitInfo());
  if(modal==='set')     root.appendChild(scSettings());
  postRender();
}
function postRender(){
  if(rollAnim) runRollAnim();
  if(typeof bindDrag==='function') bindDrag();
  if(tut&&screen!=='menu') document.body.appendChild(tutOverlay());
  autoFit();
}
/* Shrink the board just enough that the dice tray, REROLL and END TURN are
   always on screen. Laptops with short windows used to push them below the
   fold, which made the game look unresponsive. Never scales above the user's
   own UI scale setting. */
/* T09 · the old autoFit could only ever shrink, so on a tall screen the board
   used ~64% of the height while the dice numbers stayed at 30px. fitUI scales
   both ways. Below 1200px the breakpoints (T10) already handle sizing, so we
   lock to 1 there — otherwise the two mechanisms multiply. */
const BOARD_W = 880;   /* 846px content + 34px headroom */
const BOARD_H = 720;   /* header + enemies + party + tray + bar + gaps */
function fitUI(){
  const raw = Math.min(innerWidth / BOARD_W, innerHeight / BOARD_H);
  const s = innerWidth >= 1200 ? Math.min(raw, 1.20) : 1;
  document.documentElement.style.setProperty('--ui-scale', Math.max(0.85, s).toFixed(3));
}
function autoFit(){ fitUI(); }
let fitT=null;
addEventListener('resize', fitUI, { passive:true });
fitUI();

/* ================= MENU ================= */
/* T18 · One decision in the middle, four secondary destinations under it.
   The old vertical rails are gone: rotated edge text reads ~2x slower, the
   screen edge is browser-chrome territory, and :hover never fires on touch. */
function menuTile(label, sub, fn, flag){
  const b=btn('menu-tile'+(flag?' hasnew':''),'',fn);
  b.appendChild(el('span','mt-n',label));
  b.appendChild(el('small','mt-s',sub||''));
  return b;
}
function scMenu(){
  const w=el('div','screen menu title');
  const nb=bpUnclaimed().length, pr=bpProg(), saved=loadRun();
  const inner=el('div','menu-inner');
  inner.appendChild(el('h1','logo','AXIE DICE TACTICS'));
  inner.appendChild(el('div','sub','LUNACIA MUTANTS · v1.0'));
  if(saved){
    inner.appendChild(btn('go cta btn--lg','CONTINUE RUN',()=>{ S=saved.s; screen='combat'; render(); }));
    inner.appendChild(btn('ghost cta2 btn--lg','NEW RUN',()=>{ teamPick=['plant1','beast1','aqua1','reptile1','bug1']; screen='team'; render(); }));
  } else {
    inner.appendChild(btn('go cta btn--lg','PLAY',()=>{ teamPick=['plant1','beast1','aqua1','reptile1','bug1']; screen='team'; render(); }));
  }
  const grid=el('div','menu-grid');
  const faces=(META.faces||[]).length, relics=(META.relics||[]).length;
  grid.appendChild(menuTile('PASS','Lv '+pr.lv,()=>{ screen='bp'; render(); }, nb>0));
  grid.appendChild(menuTile('COLLECTION',faces+' faces · '+relics+' relics',()=>{ screen='collection'; render(); }));
  grid.appendChild(menuTile('UNLOCKS',(META.unlocks||[]).length+'/'+UNLOCKS.length,()=>{ screen='unlocks'; render(); }));
  grid.appendChild(menuTile('CODEX','how to play',()=>{ screen='codex'; render(); }));
  inner.appendChild(grid);
  const line=[];
  if(META.runs) line.push(META.runs+(META.runs===1?' run':' runs'));
  if(META.wins) line.push(META.wins+(META.wins===1?' win':' wins'));
  if(META.best) line.push('best wave '+META.best);
  if(META.shards) line.push(META.shards+' Shard');
  if(line.length) inner.appendChild(el('div','stats',line.join('  ·  ')));
  const row=el('div','menu-mini');
  row.appendChild(btn('ghost btn--sm','SAMPLE TEAMS',()=>{ screen='guide'; render(); }));
  row.appendChild(btn('ghost btn--sm','SETTINGS',()=>{ modal='set'; render(); }));
  if(typeof devToggle==='function') row.appendChild(btn('ghost btn--sm','DEV TOOLS',()=>devToggle(true)));
  inner.appendChild(row);
  w.appendChild(inner);
  return w;
}
function scUnlocks(){
  const w=el('div','screen menu unlocks');
  w.appendChild(el('h1','logo sm','UNLOCKS'));
  w.appendChild(el('div','sub',META.shards+' GENE SHARD'));
  const g=el('div','unlockgrid');
  UNLOCKS.forEach(u=>{
    const has=unlocked(u.id), can=!has&&META.shards>=u.cost;
    const c=el('div','ucard'+(has?' has':can?'':' dis'));
    c.appendChild(el('div','un',u.n));
    c.appendChild(el('div','ud',u.d));
    c.appendChild(el('div','uc',has?'UNLOCKED':u.cost+' SHARD'));
    if(can) c.onclick=()=>{ SFX.coin(); META.shards-=u.cost; META.unlocks.push(u.id); saveMeta(); render(); };
    g.appendChild(c);
  });
  w.appendChild(g);
  w.appendChild(btn('','BACK',()=>{ screen='menu'; render(); }));
  return w;
}
function scCollection(){
  const w=el('div','screen menu collection');
  w.appendChild(el('h1','logo sm','COLLECTION'));
  w.appendChild(el('div','sub',`Faces ${META.faces.length}/${FACE_POOL.length} · Relics ${META.relics.length}/${RELICS.length} · Bosses ${META.bosses.length}/${BOSSES.length}`));
  const mk=(title,items,total,emptyMsg)=>{
    const s=el('div','colsec'); s.appendChild(el('h3',null,title+'  ('+items.length+'/'+total+')'));
    const g=el('div','colgrid');
    if(!items.length) g.appendChild(el('div','iempty',emptyMsg));
    items.forEach(x=>{ const c=el('div','citem'+(x.r!=null?' r'+x.r:'')); c.textContent=x.n; g.appendChild(c); });
    s.appendChild(g); return s;
  };
  w.appendChild(mk('RELIC', RELICS.filter(r=>META.relics.includes(r.id)).map(r=>({n:r.n,r:r.rar})), RELICS.length,
    'No relics yet — you get them from rewards, the Merchant and Treasure nodes.'));
  w.appendChild(mk('DIE FACES', FACE_POOL.filter(f=>META.faces.includes(faceText(f))).map(f=>({n:faceText(f),r:f.r})), FACE_POOL.length,
    'No die faces collected yet — every Gene Mutation reward unlocks a new one.'));
  w.appendChild(mk('BOSSES DEFEATED', BOSSES.filter(b=>META.bosses.includes(b.k)).map(b=>({n:b.n,r:4})), BOSSES.length,
    'No bosses defeated yet — bosses appear on waves marked BOSS on the map.'));
  w.appendChild(btn('','BACK',()=>{ screen='menu'; render(); }));
  return w;
}

/* ================= TEAM SELECT ================= */
let pickMode='short', pickAsc=0, pickSeed='';
function scTeam(){
  const w=el('div','screen title');
  w.appendChild(el('h1','logo sm','CHOOSE YOUR TEAM'));
  w.appendChild(el('div','sub','Pick 5 Axies · left click to add · right click to remove'));
  const grid=el('div','pickgrid');
  T1.forEach(k=>{
    const h=HEROES[k], n=teamPick.filter(x=>x===k).length, pa=PASSIVE[h.cls];
    const c=el('div','pick'+(n?' on':'')); c.style.setProperty('--cc',CLASS_COLOR[h.cls]);
    const im=el('img','spr'); im.src=sprOf(h.cls,h.art+(n%3)); c.appendChild(im);
    c.appendChild(el('div','nm',h.n));
    c.appendChild(el('div','cls',h.cls.toUpperCase()+' · HP '+h.hp));
    const p=el('div','pasbox'); p.appendChild(el('span','pn',pa.n)); p.appendChild(el('span','pd',pa.d)); c.appendChild(p);
    const dv=el('div','minidie'); h.die.forEach(f=>{ const c=el('span','mf t_'+f.t); c.appendChild(ico(FT_IC[f.t],'t')); if(f.v)c.appendChild(el('span','mfv',String(f.v))); dv.appendChild(c); });
    c.appendChild(dv);
    if(n) c.appendChild(el('div','cnt','×'+n));
    c.onclick=()=>{ if(teamPick.length<5){ SFX.ui(); teamPick.push(k); render(); } };
    c.oncontextmenu=e=>{ e.preventDefault(); const i=teamPick.lastIndexOf(k); if(i>=0){SFX.ui();teamPick.splice(i,1);render();} };
    grid.appendChild(c);
  });
  w.appendChild(grid);

  const cfg=el('div','cfg');
  const modeBox=el('div','cfgrow'); modeBox.appendChild(el('span','cl','MODE'));
  ['short','full'].forEach(m=>{
    const rl=RUN_LEN[m], lock=(m==='full'&&!unlocked('u_full'));
    const b=el('button','btn sm'+(pickMode===m?' on':'')+(lock?' dis':''),rl.n+' · '+rl.d+(lock?'  [LOCKED]':''));
    b.onclick=()=>{ if(lock)return; SFX.ui(); pickMode=m; render(); }; modeBox.appendChild(b);
  });
  cfg.appendChild(modeBox);
  const ascBox=el('div','cfgrow'); ascBox.appendChild(el('span','cl','ASCENSION'));
  for(let a=0;a<=Math.min(10,META.ascMax);a++){
    const b=el('button','btn sm'+(pickAsc===a?' on':''),'A'+a);
    b.title=a===0?'No modifiers':ASCENSION.slice(0,a).map(x=>'A'+x.a+': '+x.d).join('\n');
    b.onclick=()=>{ SFX.ui(); pickAsc=a; render(); }; ascBox.appendChild(b);
  }
  if(META.ascMax===0) ascBox.appendChild(el('span','hintxt','Win a run to unlock Ascension 1'));
  cfg.appendChild(ascBox);
  if(pickAsc>0){ const d=el('div','ascdesc'); ASCENSION.slice(0,pickAsc).forEach(x=>d.appendChild(el('div',null,'A'+x.a+' · '+x.d))); cfg.appendChild(d); }
  const seedBox=el('div','cfgrow'); seedBox.appendChild(el('span','cl','SEED'));
  const inp=el('input','seedinp'); inp.placeholder='leave blank for random'; inp.value=pickSeed;
  inp.oninput=e=>pickSeed=e.target.value; seedBox.appendChild(inp);
  const dseed='DAILY-'+new Date().toISOString().slice(0,10);
  seedBox.appendChild(btn('sm','DAILY SEED',()=>{ pickSeed=dseed; render(); }));
  cfg.appendChild(seedBox);
  w.appendChild(cfg);

  const bar=el('div','trow');
  bar.appendChild(el('div','tcount',`${teamPick.length}/5`));
  bar.appendChild(btn('','RANDOM',()=>{ teamPick=[]; while(teamPick.length<5) teamPick.push(T1[Math.floor(Math.random()*6)]); render(); }));
  bar.appendChild(btn('sm','CODEX',()=>{ screen='codex'; render(); }));
  bar.appendChild(btn('sm','SAMPLE TEAMS',()=>{ screen='guide'; render(); }));
  bar.appendChild(btn('','MENU',()=>{ screen='menu'; render(); }));
  const go=btn('big go','START RUN',()=>{ if(teamPick.length===5) startRun(); });
  if(teamPick.length!==5) go.classList.add('dis');
  bar.appendChild(go);
  w.appendChild(bar);
  return w;
}
function hashSeed(str){ let h=2166136261; for(let i=0;i<str.length;i++){ h^=str.charCodeAt(i); h=Math.imul(h,16777619); } return h>>>0; }
function startRun(){
  const seed = pickSeed? hashSeed(pickSeed) : (Math.random()*1e9)|0;
  const P=META.perks||{};
  const sr=(unlocked('u_start')?1:0)+(P.relic0||0)+(P.relic1||0);
  const srRar=(P.relic1?1:0);
  S=newGame(seed,teamPick.slice(),{mode:pickMode,asc:pickAsc,
    bonusReroll:(unlocked('u_reroll')?1:0)+(P.reroll||0),
    metaHpBonus:(unlocked('u_hp')?3:0)+4*(P.hp4||0),
    startRelics: sr? [pick0(RELICS.filter(r=>r.rar<=srRar&&!r.act)).id] : []});
  S.bpFaces=(META.bpFaces||[]).slice();
  S.rerollReward=1+(P.rrw||0); S.rrwMax=S.rerollReward;
  S.unlockRelicMax = unlocked('u_relic2')?3:unlocked('u_relic1')?2:1;
  S.unlockFaceMax  = unlocked('u_face2')?4:unlocked('u_face1')?3:2;
  S.seedStr=pickSeed||('#'+seed);
  META.runs++; saveMeta();
  screen='combat'; sel=null; selRelic=null; msg='';
  /* T-preflight · the tutorial used to auto-open over the map and blocked the
     very first click of a new run. It now lives in CODEX, reachable from the menu. */
  render(); saveRun();
}
const pick0=a=>a[Math.floor(Math.random()*a.length)];

/* ================= MAP ================= */
const NODE_INFO={battle:{n:'BATTLE',ic:'dmg',d:'Regular Chimeras. Standard reward.',c:'#ff7a7a'},
  elite:{n:'ELITE',ic:'elite',d:'Much more dangerous. Bigger reward and more Shard.',c:'#ffa94d'},
  boss:{n:'BOSS',ic:'boss',d:'A boss with its own mechanic. Huge reward.',c:'#ff5f5f'},
  event:{n:'EVENT',ic:'event',d:'A risk-and-reward choice. No combat.',c:'#c78cff'},
  shop:{n:'MERCHANT',ic:'shop',d:'Buy relics and genes with Gene Shard.',c:'#ffd76a'},
  treasure:{n:'TREASURE',ic:'chest',d:'A free reward with no risk.',c:'#5fb8ff'}};
function scMap(){
  const w=el('div','screen map');
  w.appendChild(track(true));
  const bs=S.bossSteps.includes(S.step);
  w.appendChild(el('h2','maph',bs?'BOSS AHEAD':'CHOOSE YOUR PATH'));
  const row=el('div','noderow');
  S.nodes.forEach((nd,i)=>{
    const inf=NODE_INFO[nd.type];
    const c=el('div','nodecard n_'+nd.type); c.style.setProperty('--nc',inf.c);
    c.appendChild(ico(inf.ic,'nic',inf.c));
    c.appendChild(el('div','nn',inf.n));
    if(nd.type==='boss'){ const bk=S.bossPlan[S.bossSteps.indexOf(S.step)]||'agony'; const b=BOSS_BY_K[bk];
      const im=el('img','spr mut'); im.src=sprMon(bk); c.appendChild(im);
      c.appendChild(el('div','nbn',b.n)); c.appendChild(el('div','nd',b.desc)); }
    else {
      c.appendChild(el('div','nd',inf.d));
      if(nd.type==='battle'||nd.type==='elite'){
        const n=CURVE.count(S.pw)+(nd.type==='elite'?S.mods.eliteExtra:0);
        c.appendChild(el('div','nmeta',n+(n>1?' CHIMERAS':' CHIMERA')+(nd.type==='elite'?' · +45 SHARD':' · +25 SHARD')));
      }
    }
    c.onclick=()=>{ SFX.ui(); if(nd.type==='boss') SFX.boss();
      chooseNode(S,i);
      if(['battle','elite','boss'].includes(nd.type)) triggerRollAnim();
      S.ev=[]; S.floatText=[]; render(); saveRun(); };
    row.appendChild(c);
  });
  w.appendChild(row);
  const mrow=el('div','trow');
  mrow.appendChild(btn('sm info','TEAM & RELIC INFO',()=>{ modal='info'; render(); }));
  w.appendChild(mrow);
  w.appendChild(partyStrip());
  w.appendChild(archStrip());
  return w;
}
/* One bar carries everything the player must always see: where they are, whose
   turn it is, what they can spend. Every other read-out lives behind INFO. */
function track(withCtl){
  const t=el('div','track');
  const isB=S.bossSteps.includes(S.step), isE=S.eliteSteps.includes(S.step);
  t.appendChild(el('div','tlabel','WAVE'));
  const st=el('div','tstep'+(isB?' boss':isE?' elite':''));
  st.appendChild(el('span','en',String(S.step)));
  st.appendChild(el('span',null,'/'+S.len));
  if(isB||isE) st.appendChild(el('span','en',' '+(isB?'BOSS':'ELITE')));
  t.appendChild(st);
  for(let i=1;i<=S.len;i++){
    const cl=S.bossSteps.includes(i)?'boss':S.eliteSteps.includes(i)?'elite':'norm';
    const n=el('div','tnode '+cl+(i<S.step?' done':i===S.step?' cur':''));
    n.title='Wave '+i+(cl==='boss'?' · Boss':cl==='elite'?' · Elite':''); t.appendChild(n);
  }
  const r=el('div','trk-right');
  // S.turn only exists once startCombat() has run; on the map screen (e.g. the
  // forced wave-1 battle node) combat has not started yet, so fall back to 1
  // rather than ever rendering the literal string "undefined".
  if(withCtl) r.appendChild(el('div','turn','TURN '+(S.turn||1)));
  if(withCtl){ const rr=el('div','rr'); rr.appendChild(ico('reroll','t'));
    rr.appendChild(el('span','rrn',S.rerolls+'/'+S.maxRerolls)); rr.title='Rerolls left this turn'; r.appendChild(rr); }
  const shw=el('span','shards'); shw.appendChild(ico('shard','t')); shw.appendChild(el('span',null,' '+S.shards)); r.appendChild(shw);
  if(S.asc) r.appendChild(el('span','ascbadge','A'+S.asc));
  if(withCtl){
    const ub=btn('xs ghost','UNDO',()=>{ if(undo(S)){ sel=null;selRelic=null;flash('Undone.'); render(); } });
    if(!S.undo.length) ub.classList.add('dis'); r.appendChild(ub);
    const sp=el('div','spd');
    [1,2,3].forEach(v=>{ const b=el('button','btn xs'+(SPD===v?' on':''),v+'x'); b.onclick=()=>{SPD=v;render();}; sp.appendChild(b); });
    r.appendChild(sp);
    const ib=btn('xs ghost','INFO',()=>{ modal='info'; render(); });
    ib.title='Every relic, stat and die face — yours and the enemy’s  (press I)';
    r.appendChild(ib);
    r.appendChild(btn('xs ghost','SET',()=>{ modal='set'; render(); }));
  }
  t.appendChild(r);
  return t;
}
function partyStrip(){
  const p=el('div','pstrip');
  S.roster.forEach(e=>{
    const u=buildUnit(e,S), dr=dieRarity(u);
    const c=el('div','psc dr'+dr); c.style.setProperty('--cc',CLASS_COLOR[u.cls]);
    const im=el('img','spr'); im.src=sprOf(u.cls,u.artIdx); c.appendChild(im);
    c.appendChild(el('div','nm',u.n+' T'+u.tier));
    c.appendChild(el('div','hp','HP '+u.maxHp));
    const dv=el('div','minidie');
    u.die.forEach((f,i)=>{ const s2=el('span','mf t_'+f.t+' r'+f.r); s2.appendChild(ico(FT_IC[f.t],'t'));
    if(f.v) s2.appendChild(el('span','mfv',String(f.v))); s2.title='Face '+(i+1)+': '+faceText(f); dv.appendChild(s2); });
    c.appendChild(dv);
    if(dr>=3) c.appendChild(el('div','drtag',dr>=4?'COSMIC DIE':'GOLDEN DIE'));
    p.appendChild(c);
  });
  const rl=el('div','relicstrip');
  if(!S.relics.length) rl.appendChild(el('div','nothing','no relics yet'));
  S.relics.forEach(id=>{ const r=RELIC_BY_ID[id]; if(!r)return;
    const c=el('div','rchip r'+r.rar,r.n); c.title=r.d; rl.appendChild(c); });
  const wrap=el('div','pstripwrap'); wrap.appendChild(p); wrap.appendChild(rl);
  return wrap;
}
function archStrip(){
  const sc=archScore(S), keys=Object.keys(sc).filter(k=>sc[k]>0).sort((a,b)=>sc[b]-sc[a]).slice(0,4);
  const w=el('div','archstrip');
  if(!keys.length) return w;
  w.appendChild(el('span','al','BUILD'));
  keys.forEach((k,i)=>{ const a=ARCH[k]; const c=el('div','achip'+(i===0?' lead':''));
    c.style.setProperty('--ac',a.c); c.appendChild(ico(ARCH_IC[k]||'buff','ai',a.c));
    c.appendChild(el('span','an',a.n)); c.appendChild(el('span','av',String(sc[k])));
    c.title=a.d; w.appendChild(c); });
  return w;
}

const ARCH_IC={poison:'poison',burn:'burn',shield:'shield',mana:'mana',pierce:'dmg',crit:'buff',growth:'regen',summon:'summon',aoe:'debuff',thorns:'thorns'};
/* ================= COMBAT ================= */
function focusState(){
  if(sel!=null||selRelic) return 'target';
  if(S.party.some(u=>u.hp>0&&!u.used&&u.rolled>=0&&u.die[u.rolled].t!=='blank')) return 'dice';
  return 'end';
}
function scCombatShell(){ const w=el('div','screen combat frozen'); w.appendChild(track()); w.appendChild(partyStrip()); return w; }

function scCombat(frozen){
  const fs=focusState();
  const w=el('div','screen combat f_'+fs+(frozen?' frozen':''));
  w.appendChild(track(true));
  if(msg) w.appendChild(el('div','msg',msg));

  /* enemies */
  const ez=el('div','zone enemies');
  S.enemies.forEach(e=>ez.appendChild(unitCard(e)));
  w.appendChild(ez);
  /* party — mỗi Axie ghép chung 1 cột với đúng die của nó (2026-09-01: trước đây
     là 2 hàng riêng, chỉ thẳng cột nhờ trùng width tình cờ; giờ ghép rõ ràng bằng cấu trúc) */
  const pz=el('div','zone party');
  /* Formation Resonance (design/quick-specs/formation-resonance-2026-09-01.md):
     hiển thị cặp "đang mở" TRƯỚC khi người chơi click — bắt buộc theo pillar
     minh bạch triệt để. cols[i] tương ứng roster/pos i cho các Axie thật vì
     s.party = roster.map(buildUnit) rồi mới push token ở cuối. */
  const resPairs=resonancePairs(S);
  S.party.forEach((u,i)=>{
    const col=el('div','pcol'); col.appendChild(unitCard(u)); col.appendChild(dieBox(u)); pz.appendChild(col);
    const pair=resPairs.find(p=>p.posA===i);
    if(pair){
      const link=el('div','reslink');
      link.appendChild(ico(FT_IC[pair.type],'ii'));
      link.title='Formation Resonance: cặp Axie liền kề cùng roll mặt '+pair.type+' — Axie thực thi SAU nhận +'+Math.round((RESONANCE.mult-1)*100)+'%.';
      pz.appendChild(link);
    }
  });
  w.appendChild(pz);
  /* bottom */
  const bb=el('div','bottombar');
  const mo=el('div','manaorb'+(S.mana>=10?' full':''));
  mo.appendChild(el('div','mv',String(S.mana))); mo.appendChild(el('div','ml','MANA'));
  const fill=el('div','mfill'); fill.style.height=Math.min(100,S.mana*10)+'%'; mo.appendChild(fill);
  bb.appendChild(mo);
  const items=el('div','items');
  S.relics.forEach(id=>{ const r=RELIC_BY_ID[id]; if(!r||!r.act) return;
    const used=S.usedActives.includes(id), can=S.mana>=r.act.cost&&!used;
    const c=el('div','icard r'+r.rar+(can?'':' dis')+(selRelic===id?' sel':''));
    c.appendChild(el('div','ic-n',r.n)); c.appendChild(el('div','ic-c','MP '+r.act.cost));
    c.title=r.d;
    c.onclick=()=>{ if(!can)return; SFX.ui(); sel=null;
      if(r.act.tgt==='self'){ if(playerUseRelic(S,id,null)) afterAct(); }
      else { selRelic=id; render(); } };
    items.appendChild(c);
  });
  if(!items.children.length) items.appendChild(el('div','nothing','no active cards yet'));
  bb.appendChild(items);
  const rb=btn('reroll','REROLL '+S.rerolls,()=>{
    const pickd=S.party.filter(u=>u.rsel&&u.hp>0&&!u.used&&!u.heavy&&!u.frozen).map(u=>u.uid);
    const use=pickd.length?pickd:S.party.filter(u=>u.hp>0&&!u.used&&!u.heavy&&!u.frozen).map(u=>u.uid);
    if(doReroll(S,use)){ SFX.reroll(); S.party.forEach(u=>u.rsel=false); sel=null;
      flash('Rerolled. Undo history cleared.'); triggerRollAnim(use); collectFloats(); render(); } });
  if(!(S.rerolls>0&&anyRerollable(S))) rb.classList.add('dis');
  bb.appendChild(rb);
  bb.appendChild(btn('end','END TURN',()=>doEndTurn()));
  w.appendChild(bb);
  /* One line, and only when it earns its place. The generic controls hint
     retires after the first wave so the board stays quiet. */
  const hint = sel!=null ? 'Pick a target — gold outline means legal. Esc to cancel.'
    : selRelic ? 'Pick a target for the card.'
    : fs==='end' ? 'No dice left — press END TURN or Space.'
    : S.step<=1 ? 'Click or drag a die to use it · corner button marks it for reroll · Ctrl+Z undoes'
    : '';
  if(hint) w.appendChild(el('div','hintbar',hint));
  else w.appendChild(el('div','hintbar',''));
  return w;
}

function needsTarget(u){
  const f=u.die[u.rolled];
  if(f.t==='blank'||f.t==='mana'||f.t==='summon') return false;
  if(hasKw(f,'aoe')) return false;
  if(f.t==='dmg'&&kwVal(f,'chain')) return false;
  return true;
}
function validTargets(u){
  if(!needsTarget(u)) return [];
  const f=u.die[u.rolled];
  const foe=['dmg','poison','debuff'].includes(f.t);
  return (foe?aliveE(S):aliveP(S)).map(x=>x.uid);
}

function unitCard(u){
  const isE=u.side==='e';
  const c=el('div','unit'+(isE?' e':' p')+(u.hp<=0?' dead':'')+(u.big?' big':'')+(u.elite?' elite':'')+(u.token?' token':''));
  c.dataset.uid=u.uid;
  if(!isE) c.style.setProperty('--cc',CLASS_COLOR[u.cls]||'#888');
  let tgtable=false;
  if(sel!=null){ const su=byUid(S,sel); if(su) tgtable=validTargets(su).includes(u.uid); }
  if(selRelic){ const a=RELIC_BY_ID[selRelic].act; tgtable=((a.tgt==='enemy')===isE)&&u.hp>0; }
  if(tgtable) c.classList.add('tgt');
  const incoming = !isE && S.enemies.some(e=>e.hp>0&&e.intent&&e.intent.tgt===u.uid&&['dmg','poison','debuff'].includes(e.intent.face.t));
  if(incoming) c.classList.add('threat');

  const spw=el('div','sprwrap');
  const im=el('img','spr'+(isE?' mut':'')); im.src=isE?sprMon(u.key):sprOf(u.cls,u.artIdx); spw.appendChild(im);
  if(!isE&&u.pas) { const p=el('div','pasdot',u.pas.n[0]); p.title=u.pas.n+': '+u.pas.d; spw.appendChild(p); }
  c.appendChild(spw);
  c.appendChild(el('div','nm',(isE?u.n:u.n+' T'+u.tier)+(u.token?' *':'')));
  /* hp bar + ghost preview */
  /* T05 · the number sits above the bar, so no fill colour can ever make it
     unreadable.  T06 · the class encodes how close to death the unit is —
     identical for both sides, because position already says which side. */
  const pct = u.maxHp ? u.hp/u.maxHp : 0;
  const hpState = pct<=0.25 ? ' crit' : pct<=0.50 ? ' low' : '';
  const bar=el('div','hpbar'+hpState);
  const num=el('div','hpnum'); num.appendChild(el('span',null,'HP'));
  num.appendChild(el('b',null,u.hp+'/'+u.maxHp)); bar.appendChild(num);
  const track=el('div','hptrack');
  bar.setAttribute('role','progressbar');
  bar.setAttribute('aria-valuenow',String(Math.max(0,u.hp)));
  bar.setAttribute('aria-valuemin','0'); bar.setAttribute('aria-valuemax',String(u.maxHp));
  bar.setAttribute('aria-label','Health');
  const f1=el('div','hpfill'); f1.style.width=Math.max(0,100*pct)+'%'; track.appendChild(f1);
  const pv=previewOn(u);
  if(pv&&pv.hpAfter!=null){ const gh=el('div','hpghost');
    gh.style.left=(100*pv.hpAfter/u.maxHp)+'%'; gh.style.width=(100*(u.hp-pv.hpAfter)/u.maxHp)+'%'; track.appendChild(gh); }
  bar.appendChild(track);
  c.appendChild(bar);
  if(u.shield>0){ const sb=el('div','shbar'); sb.style.width=Math.min(100,100*u.shield/u.maxHp)+'%';
    const sl=el('span'); sl.appendChild(ico('shield','t')); sl.appendChild(el('span','stv',String(u.shield)));
    sb.appendChild(sl); c.appendChild(sb); }
  const row=el('div','stats');
  for(const k in ST_IC){ const v=u.st[k];
    if(v>0){ const sp=el('span','st '+k); sp.appendChild(ico(ST_IC[k],'t'));
      if(k!=='stun'&&k!=='undying') sp.appendChild(el('span','stv',String(v)));
      sp.title=ST_NAME[k]+' '+v; row.appendChild(sp); } }
  if(u.frozen){ const sp=el('span','st frz'); sp.appendChild(ico('freeze','t')); sp.title='Frozen: cannot be rerolled'; row.appendChild(sp); }
  c.appendChild(row);
  if(isE&&u.hp>0&&u.intent){
    const f=u.intent.face, v=faceValue(S,u,u.rolled);
    const danger = f.t==='dmg' && v>=(u.big?14:10);
    const it=el('div','intent t_'+f.t+(danger?' danger':''));
    it.appendChild(ico(FT_IC[f.t],'ii'));
    it.appendChild(el('span','iv', (f.t==='debuff'||f.t==='buff')? f.k.filter(x=>x!=='aoe').map(kwText).join(' ') : String(v)));
    const tg=u.intent.tgt!=null?byUid(S,u.intent.tgt):null;
    const tl=hasKw(f,'aoe')?'ALL':(tg?(tg.side==='p'?tg.n:(tg.uid===u.uid?'itself':tg.n)):'');
    if(tl) it.appendChild(el('span','itg','→ '+tl));
    ['cleave','pierce','exec'].forEach(k=>{ if(hasKw(f,k)) it.appendChild(el('span','ik',kwText(k).toUpperCase())); });
    c.appendChild(it);
  }
  if(u.boss){ c.appendChild(el('div','bossdesc',u.desc+(u.phase===2?' · PHASE 2':''))); }
  if(pv) c.appendChild(el('div','preview '+pv.cls,pv.txt));
  if(tgtable) c.onclick=()=>doTarget(u.uid);
  else if(u.hp>0){
    /* Not a legal target right now, so a click is a question rather than an
       action: show every face on that Axie's die, ally or enemy. */
    c.classList.add('inspect');
    c.onclick=()=>{ if(Date.now()-lastDragEnd<200) return; SFX.ui(); modal='unit'; modalUid=u.uid; render(); };
  }
  const fl=el('div','floats'); fl.dataset.uid=u.uid; c.appendChild(fl);
  return c;
}
function previewOn(t){
  if(selRelic){ const a=RELIC_BY_ID[selRelic].act;
    if((a.tgt==='enemy')!==(t.side==='e')||t.hp<=0) return null;
    if(a.kind==='heal') return {txt:'+'+a.v,cls:'heal'};
    if(a.kind==='dmg'||a.kind==='ult') return {txt:'-'+a.v,cls:'dmg',hpAfter:Math.max(0,t.hp-a.v)};
    if(a.kind==='stun') return {txt:'STUN',cls:'deb'}; return null; }
  if(sel==null) return null;
  const u=byUid(S,sel); if(!u||!validTargets(u).includes(t.uid)) return null;
  const f=u.die[u.rolled]; let v=faceValue(S,u,u.rolled);
  if(f.t==='dmg'){
    if(u.critNow) v*=rcritMult();
    const low=t.hp<t.maxHp*0.5; if(low&&(u.cls==='beast'||hasKw(f,'exec'))) v=Math.ceil(v*1.6);
    const pierce=hasKw(f,'pierce'); if(pierce&&u.cls==='bird') v+=3;
    if(t.st.vulnerable>0) v=Math.ceil(v*1.5);
    const m=kwVal(f,'multi')||1, tot=v*m;
    const eff=pierce?tot:Math.max(0,tot-t.shield);
    return {txt:(u.critNow?'CRIT ':'')+'-'+tot+(t.hp<=eff?' KILL':''),cls:'dmg',hpAfter:Math.max(0,t.hp-eff)};
  }
  if(f.t==='shield') return {txt:'SH +'+(v+(t.cls==='plant'?2:0)),cls:'shd'};
  if(f.t==='heal') return {txt:'+'+Math.min(v,t.maxHp-t.hp),cls:'heal',hpAfter:null};
  if(f.t==='poison'){ let n=v; if(u.cls==='bug'&&t.st.poison>0) n+=2; return {txt:'PSN +'+n,cls:'poi'}; }
  if(f.t==='debuff'||f.t==='buff') return {txt:f.k.filter(x=>x!=='aoe'&&x!=='cantrip').map(kwText).join(' '),cls:'deb'};
  return null;
}

function dieBox(u){
  const b=el('div','diebox'); b.dataset.uid=u.uid;
  if(u.hp<=0||u.rolled<0){ b.appendChild(el('div','die out','X')); b.appendChild(el('div','dlbl','')); return b; }
  const f=u.die[u.rolled];
  const dr=dieRarity(u);
  const d=el('div','die dr'+dr+(u.used?' used':'')+(sel===u.uid?' sel':'')+(f.t==='blank'?' blank':'')+(u.critNow?' critready':''));
  d.style.setProperty('--cc',CLASS_COLOR[u.cls]||'#888');
  paintDieFace(d,u,u.rolled,false);
  if(hasKw(f,'heavy')) d.classList.add('heavy');
  d.onclick=()=>clickDie(u);
  d.onmouseenter=()=>SFX.hover();
  b.appendChild(d);
  const pips=el('div','pips');
  for(let i=0;i<6;i++){ const p=el('span','pip r'+(u.die[i].r||0)+(i===u.rolled?' on':''));
    p.title='Face '+(i+1)+': '+faceText(u.die[i]); pips.appendChild(p); }
  b.appendChild(pips);
  if(!u.used&&!u.heavy&&!u.frozen){
    const rs=el('div','rsel'+(u.rsel?' on':'')); rs.appendChild(ico('reroll','t'));
    rs.title='Mark this die for reroll';
    rs.onclick=e=>{ e.stopPropagation(); SFX.ui(); u.rsel=!u.rsel; render(); }; b.appendChild(rs);
  } else if(u.frozen){ const fz=el('div','rsel frz'); fz.appendChild(ico('freeze','t')); b.appendChild(fz); }
  b.appendChild(el('div','dlbl',u.n));
  return b;
}

/* ---------- actions ---------- */
function clickDie(u){
  if(rollAnim||playing||u.used||u.hp<=0) return;
  const f=u.die[u.rolled];
  if(f.t==='blank'){ flash('This face is blank. Try rerolling it.'); render(); return; }
  selRelic=null; SFX.ui();
  if(!needsTarget(u)){ if(playerUseDie(S,u.uid,null)) afterAct(); return; }
  sel = sel===u.uid? null : u.uid; render();
}
function doTarget(uid){
  if(playing) return;
  if(selRelic){ const r=selRelic; selRelic=null; if(playerUseRelic(S,r,uid)) afterAct(); else render(); return; }
  if(sel==null) return;
  const su=sel; sel=null;
  if(playerUseDie(S,su,uid)) afterAct(); else render();
}
async function afterAct(){
  flash(''); sel=null; selRelic=null;
  render();                         /* vẽ lại tray (die đã dùng) trước khi phát */
  await playEvents();
  S.floatText=[];
  if(S.phase==='won'||S.phase==='reward'){ SFX.win(); onCombatEnd(); }
  render(); saveRun();
}
async function doEndTurn(){
  if(rollAnim||playing) return;
  sel=null; selRelic=null;
  const before=S.turn;
  endTurn(S); flash('');
  await playEvents();
  S.floatText=[];
  if(S.phase==='reward'||S.phase==='won'){ SFX.win(); onCombatEnd(); render(); saveRun(); return; }
  if(S.phase==='lost'){ SFX.lose(); onRunEnd(); render(); return; }
  if(S.turn>before) triggerRollAnim();
  if(S.enemies.some(e=>e.hp>0&&e.intent&&e.intent.face.t==='dmg'&&faceValue(S,e,e.rolled)>=(e.big?14:12))) SFX.warn();
  render(); saveRun();
}
function onCombatEnd(){
  if(S.bossSteps.includes(S.step)){ const bk=S.bossPlan[S.bossSteps.indexOf(S.step)]; if(bk&&!META.bosses.includes(bk)){ META.bosses.push(bk); saveMeta(); } }
  if(S.phase==='won') onRunEnd();
}
function onRunEnd(){
  META.shards+=S.shards;
  if(S.step>META.best) META.best=S.step;
  S.seen.faces.forEach(f=>{ if(!META.faces.includes(f)) META.faces.push(f); });
  S.seen.relics.forEach(r=>{ if(!META.relics.includes(r)) META.relics.push(r); });
  if(S.phase==='won'){ META.wins++; if(S.asc>=META.ascMax&&META.ascMax<10) META.ascMax=Math.min(10,S.asc+1); }
  S.xpGain=runXp(S,S.phase==='won'); META.xp+=S.xpGain;
  saveMeta(); clearRun();
}
function flash(t){ msg=t; }

/* ================= REWARD ================= */
const TIERN=['REWARD','BIG REWARD','ELITE REWARD','BOSS REWARD'];
function scReward(){
  const ov=el('div','overlay');
  const bx=el('div','rewardbox tier'+S.rewardTier);
  bx.appendChild(el('h2',null,TIERN[S.rewardTier]||TIERN[0]));
  bx.appendChild(el('div','sub','Your party heals to full and any fallen Axie is revived · +'+(S.kind==='boss'?90:S.kind==='elite'?45:25)+' Shard'));
  const row=el('div','rrow');
  S.rewards.forEach((r,i)=>{
    const c=el('div','rcard r'+(r.rar||0)+' t_'+r.t);
    c.style.animationDelay=(i*140/SPD)+'ms';
    c.appendChild(el('div','rbadge',RARITY[r.rar||0]));
    c.appendChild(el('div','rt',r.title));
    if(r.cls){ const im=el('img','spr'); const ent=r.uid!=null?S.roster.find(x=>x.uid===r.uid):null;
      im.src=sprOf(r.cls,(r.tier===4?6:(r.tier-1)*3)+((ent&&ent.vr||0)%3)); c.appendChild(im); }
    else c.appendChild(ico(r.t==='relic'||r.t==='chaos'?'chest':r.t==='curse'?'poison':r.t==='reroll'?'reroll':'shard','ricon'));
    c.appendChild(el('div','rd',r.desc));
    if(r.sub) c.appendChild(el('div','rsub',r.sub));
    if(r.arch&&ARCH[r.arch]){ const a=el('div','rarch',ARCH[r.arch].n); a.style.color=ARCH[r.arch].c; c.appendChild(a); }
    if(r.t==='face'){ const ent=S.roster.find(x=>x.uid===r.uid);
      if(ent){ const u=buildUnit(ent,S); const old=u.die[r.idx];
        c.appendChild(el('div','rrepl','Overwrites: '+faceText(old))); } }
    c.appendChild(el('div','rcta','TAKE'));
    c.onclick=()=>{ SFX.legend(); if(r.rar>=4) flashScreen('myth'); takeReward(S,i); sel=null;
      S.ev=[]; S.floatText=[];
      if(S.phase==='combat') triggerRollAnim(); render(); saveRun(); };
    c.onmouseenter=()=>SFX.hover();
    row.appendChild(c);
  });
  bx.appendChild(row);
  if(S.rerollReward>0){
    const rr=btn('sm','REROLL REWARDS ('+S.rerollReward+')',()=>{ if(rerollRewards(S)){ SFX.reroll(); render(); } });
    const wrap=el('div','trow'); wrap.appendChild(rr);
    wrap.appendChild(el('span','hintxt','Once per wave. Draws three new options.'));
    bx.appendChild(wrap);
  }
  bx.appendChild(partyStrip());
  bx.appendChild(archStrip());
  ov.appendChild(bx);
  setTimeout(()=>SFX.open(),80);
  return ov;
}

const EV_IC={shrine:'buff',merchant:'shop',treasure:'chest',campfire:'burn',casino:'shard',mutant:'summon'};
/* ================= EVENT ================= */
function scEvent(){
  const ev=S.event, d=ev.def;
  const ov=el('div','overlay');
  const bx=el('div','rewardbox event');
  bx.appendChild(ico(EV_IC[d.k]||'event','evic'));
  bx.appendChild(el('h2',null,d.n));
  bx.appendChild(el('div','sub',d.d));
  if(!ev.res){
    const row=el('div','rrow');
    d.opts.forEach((o,i)=>{ const c=el('div','rcard evopt');
      c.appendChild(el('div','rt',o.t)); c.appendChild(el('div','rd',o.d));
      c.appendChild(el('div','rcta','TAKE'));
      c.onclick=()=>{ SFX.open(); eventChoose(S,i); render(); saveRun(); };
      c.onmouseenter=()=>SFX.hover(); row.appendChild(c); });
    bx.appendChild(row);
  } else {
    bx.appendChild(el('div','evres',ev.res.msg));
    bx.appendChild(btn('big go','CONTINUE',()=>{ eventDone(S); render(); saveRun(); }));
  }
  bx.appendChild(partyStrip());
  ov.appendChild(bx);
  return ov;
}

/* ================= SHOP ================= */
function scShop(){
  const ov=el('div','overlay');
  const bx=el('div','rewardbox shop');
  bx.appendChild(ico('shop','evic'));
  bx.appendChild(el('h2',null,'CHIMERA MERCHANT'));
  bx.appendChild(el('div','sub',S.shards+' GENE SHARD'));
  const row=el('div','rrow wrap');
  S.shop.items.forEach((it,i)=>{
    const sold=S.shop.bought.includes(i), can=!sold&&S.shards>=it.cost;
    const c=el('div','rcard shopitem r'+it.rar+(sold?' sold':can?'':' dis'));
    c.appendChild(el('div','rbadge',RARITY[it.rar]));
    c.appendChild(ico(it.kind==='relic'?'chest':it.kind==='face'?'summon':it.kind==='heal'?'heal':'reroll','ricon'));
    c.appendChild(el('div','rt',it.n));
    c.appendChild(el('div','rd',it.d));
    if(it.arch&&ARCH[it.arch]){ const a=el('div','rarch',ARCH[it.arch].n); a.style.color=ARCH[it.arch].c; c.appendChild(a); }
    c.appendChild(el('div','rcost',sold?'SOLD'  :it.cost+' SHARD'));
    if(can) c.onclick=()=>{ SFX.coin(); shopBuy(S,i); render(); saveRun(); };
    row.appendChild(c);
  });
  bx.appendChild(row);
  bx.appendChild(btn('big go','LEAVE',()=>{ shopDone(S); render(); saveRun(); }));
  bx.appendChild(partyStrip());
  ov.appendChild(bx);
  return ov;
}

/* ================= END / RECAP ================= */
function scEnd(){
  const won=S.phase==='won';
  const ov=el('div','overlay');
  const bx=el('div','rewardbox end '+(won?'win':'lose'));
  bx.appendChild(el('h2',null,won?'LUNACIA CONQUERED':'YOUR TEAM HAS FALLEN'));
  bx.appendChild(el('div','sub',won?`Cleared all ${S.len} waves · Ascension ${S.asc}`
    :`Defeated on wave ${S.step} of ${S.len}`));
  /* death recap */
  const rc=el('div','recap');
  const mk=(k,v)=>{ const c=el('div','rcstat'); c.appendChild(el('div','rv',String(v))); c.appendChild(el('div','rk',k)); return c; };
  rc.appendChild(mk('Wave reached',S.step)); rc.appendChild(mk('Damage dealt',S.stat.dmg));
  rc.appendChild(mk('Damage taken',S.stat.taken)); rc.appendChild(mk('Biggest hit',S.stat.maxHit));
  rc.appendChild(mk('Enemies killed',S.stat.kills)); rc.appendChild(mk('Turns played',S.stat.turns));
  rc.appendChild(mk('Shard earned',S.shards));
  if(S.xpGain!=null) rc.appendChild(mk('Lunacia XP',+S.xpGain));
  bx.appendChild(rc);
  if(!won&&S.enemies.length){
    const killer=S.enemies.filter(e=>e.hp>0).sort((a,b)=>b.maxHp-a.maxHp)[0];
    if(killer){ const k=el('div','killer'); const im=el('img','spr mut'); im.src=sprMon(killer.key);
      k.appendChild(im); k.appendChild(el('div',null,'Killed by '+killer.n+(killer.boss?' (BOSS)':'')));
      bx.appendChild(k); }
  }
  bx.appendChild(el('div','buildsum','FINAL BUILD'));
  bx.appendChild(partyStrip());
  bx.appendChild(archStrip());
  const row=el('div','trow');
  row.appendChild(btn('big go','RETRY (same team)',()=>{ startRun(); }));
  row.appendChild(btn('','MENU',()=>{ screen='menu'; render(); }));
  if(S.seedStr) row.appendChild(btn('sm ghost','COPY SEED',()=>{ try{navigator.clipboard.writeText(S.seedStr);}catch(e){} flash('Seed copied: '+S.seedStr); render(); }));
  bx.appendChild(row);
  ov.appendChild(bx);
  setTimeout(()=>won?SFX.win():SFX.lose(),100);
  return ov;
}

/* ================= TUTORIAL ================= */
const TUT=[
  {t:'A DIE IS AN AXIE',d:'Each Axie carries one six-sided die, and those six faces are its six body parts: Mouth, Horn, Back, Tail, Eyes and Ears. All five dice roll at the start of every turn.'},
  {t:'THE ENEMY SHOWS ITS HAND',d:'Enemies roll dice too, and whatever they roll is printed on their card: the number is the damage, the arrow is the target. You always see everything before you decide.'},
  {t:'USING A DIE',d:'Click a die, then click a target with a gold outline. You can also drag it straight onto the target. The preview shows exactly how much HP will be left. Made a mistake? Ctrl+Z undoes it.'},
  {t:'REROLLING',d:'Use the small button on a die to mark it, then press REROLL. Mark nothing and all of them are rerolled. Rerolling clears your undo history, so use it before you commit.'},
  {t:'RARITY LIVES ON THE FACE',d:'Rewards give you a new FACE, from Common all the way up to Mythic, and you choose which of the six faces it replaces. Collect Legendary faces and the die turns GOLDEN; a single Mythic face makes it COSMIC.'},
];
function tutOverlay(){
  const i=tut-1, t=TUT[i];
  const ov=el('div','overlay tutov');
  const bx=el('div','tutbox');
  bx.appendChild(el('div','tstep',(tut)+'/'+TUT.length));
  bx.appendChild(el('h2',null,t.t));
  bx.appendChild(el('div','td',t.d));
  const r=el('div','trow');
  r.appendChild(btn('sm ghost','SKIP',()=>{ tut=0; META.tut=1; saveMeta(); render(); }));
  r.appendChild(btn('big go',tut<TUT.length?'NEXT':'PLAY',()=>{ tut++; if(tut>TUT.length){ tut=0; META.tut=1; saveMeta(); } render(); }));
  bx.appendChild(r); ov.appendChild(bx);
  return ov;
}

/* ================= KEYS / BOOT ================= */
document.addEventListener('keydown',e=>{
  if(!S||screen!=='combat'&&screen!=='menu') { }
  if(e.key==='Escape'){ if(modal){ modal=null; render(); return; } sel=null; selRelic=null; render(); return; }
  if((e.key==='i'||e.key==='I')&&S&&screen==='combat'){ modal=(modal==='info'?null:'info'); render(); return; }
  if(modal) return;
  if(!S||S.phase!=='combat'||playing) return;
  if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==='z'){ e.preventDefault(); if(undo(S)){ sel=null; render(); } }
  else if(e.key==='r'||e.key==='R'){ const b=$('.btn.reroll'); if(b&&!b.classList.contains('dis')) b.click(); }
  else if(e.key===' '||e.key==='Enter'){ e.preventDefault(); const b=$('.btn.end'); if(b) b.click(); }
  else if(e.key>='1'&&e.key<='5'){ const u=S.party.filter(x=>x.side==='p')[+e.key-1]; if(u) clickDie(u); }
});
document.addEventListener('mousedown',e=>{ if(e.button===0&&rollAnim){ rollAnim.t0-=400; } });
window.addEventListener('load',()=>{ loadMeta();
  if(META.vol!=null) AU.vol=META.vol;
  if(META.mute) AU.on=false;
  if(META.spd) SPD=META.spd;
  if(META.tut)tut=0; render(); });

/* ================= LUNACIA PASS ================= */
function scBP(){
  const w=el('div','screen menu bpscreen');
  w.appendChild(el('h1','logo sm','LUNACIA PASS'));
  const pr=bpProg();
  w.appendChild(el('div','sub','Level '+pr.lv+' of 30  ·  '+META.xp+' XP earned'+(META.title?'  ·  '+META.title:'')));
  const bar=el('div','bpbar big'); const f=el('div','bpfill'); f.style.width=pr.pct+'%'; bar.appendChild(f);
  bar.appendChild(el('div','bptxt',pr.lv<30?(pr.cur+' / '+pr.need+' XP to Level '+(pr.lv+1)):'MAX LEVEL'));
  w.appendChild(bar);
  const un=bpUnclaimed();
  if(un.length){ const cw=el('div','trow');
    cw.appendChild(btn('big go','CLAIM ALL ('+un.length+')',()=>{ un.forEach(bpClaim); SFX.legend(); flashScreen('gold'); render(); }));
    w.appendChild(cw); }
  const tr=el('div','bptrack');
  BP.forEach(b=>{
    const lv=pr.lv, got=META.bpClaimed.includes(b.lv), ready=b.lv<=lv&&!got;
    const c=el('div','bpnode'+(b.big?' big':'')+(got?' got':ready?' ready':' lock'));
    c.appendChild(el('div','bplv','Lv '+b.lv));
    const r=b.r;
    let icn='shard', txt='', sub='';
    if(r.t==='shard'){ icn='shard'; txt='+'+r.v; sub='GENE SHARD'; }
    else if(r.t==='unlock'){ const u=UNLOCKS.find(x=>x.id===r.v); icn='chest'; txt=u?u.n:'UNLOCK'; sub=u?u.d:''; }
    else if(r.t==='perk'){ icn='buff'; txt=r.n; sub='PERMANENT'; }
    else if(r.t==='face'){ const bf=BP_FACES[r.v]; icn='summon'; txt=bf.n; sub=bf.d; c.classList.add('mythic'); }
    c.appendChild(ico(icn,'bpic'));
    c.appendChild(el('div','bpn',txt));
    if(sub) c.appendChild(el('div','bpd',sub));
    if(r.t==='face'){ const bf=BP_FACES[r.v];
      c.appendChild(el('div','bpface',faceText(bf.face)));
      const ar=ARCH[bf.arch]; if(ar){ const tg=el('div','rarch',ar.n); tg.style.color=ar.c; c.appendChild(tg); } }
    if(b.title) c.appendChild(el('div','bpttl','TITLE: '+b.title));
    c.appendChild(el('div','bpstate',got?'CLAIMED':ready?'CLAIM':'LOCKED'));
    if(ready) c.onclick=()=>{ bpClaim(b); SFX.legend(); if(r.t==='face'){ flashScreen('myth'); bigText('MYTHIC',''); SFX.mythic(); } render(); };
    tr.appendChild(c);
  });
  w.appendChild(tr);
  const info=el('div','tips');
  info.innerHTML=`<b>XP per run:</b> 30 to start &nbsp;·&nbsp; 10 per wave cleared &nbsp;·&nbsp; 30 per Elite &nbsp;·&nbsp; 60 per Boss &nbsp;·&nbsp; 150 for winning &nbsp;·&nbsp; 25 per Ascension level &nbsp;·&nbsp; 40 for a Full Run.
  <br><b>You earn XP even when you lose.</b> There is no season timer and no progress ever expires.
  <br><b>Five exclusive die faces</b> at levels 5, 12, 19, 26 and 30, each one built around a different playstyle.`;
  w.appendChild(info);
  w.appendChild(btn('','BACK',()=>{ screen='menu'; render(); }));
  return w;
}

/* ================= CODEX (tab layout) ================= */
let cxTab='basic', cxFilter='';
function cxH(t){ return el('h4','cxh',t); }
function cxP(html){ const d=el('div','cxp'); d.innerHTML=html; return d; }
function cxTable(head,rows,cls){
  // Column count must always match head.length: the grid template is derived
  // from the real number of columns instead of a hand-matched CSS class, so a
  // 3- or 4-column row can never overflow into the next row's first column
  // (that mismatch used to make a row's last cell visually collide with the
  // following row, e.g. the CLASS/PASSIVE/EFFECT table).
  const n=head.length;
  const gtc = n<=2 ? '150px 1fr' : '130px repeat('+(n-1)+',1fr)';
  const t=el('div','cxtable '+(cls||''));
  const mkRow=(cells,isHead)=>{
    const tr=el('div','cxtr'+(isHead?' cxhead':''));
    tr.style.gridTemplateColumns=gtc;
    cells.forEach(c=>{ const d=el('div','cxtd'); if(typeof c==='string') d.textContent=c; else if(c) d.appendChild(c); tr.appendChild(d); });
    return tr;
  };
  t.appendChild(mkRow(head,true));
  rows.forEach(r=>t.appendChild(mkRow(r,false)));
  return t;
}
const chip=(txt,col)=>{ const s2=el('span','cchip',txt); if(col){ s2.style.borderColor=col; s2.style.color=col; } return s2; };
const iconChip=(ic,txt,col)=>{ const s2=el('span','cchip ic'); s2.appendChild(ico(ic,'t',col)); s2.appendChild(el('span',null,txt));
  if(col){ s2.style.borderColor=col; s2.style.color=col; } return s2; };

const CX_TABS=[
  ['basic','THE BASICS'],['dice','DICE & BODY PARTS'],['mana','MANA & CARDS'],
  ['kw','KEYWORDS'],['st','STATUS EFFECTS'],['cls','CLASSES & PLAYSTYLES'],
  ['relic','RELIC TABLE'],['reward','MAP & REWARDS'],['boss','BOSSES'],['diff','DIFFICULTY & KEYS'],
];

function scCodex(){
  const w=el('div','screen menu codex');
  const top=el('div','cxtop');
  top.appendChild(el('h1','logo sm','CODEX'));
  top.appendChild(el('div','sub','Every rule in the game. Nothing is hidden.'));
  w.appendChild(top);
  const shell=el('div','cxshell');
  const nav=el('div','cxnav');
  CX_TABS.forEach(([k,n])=>{ const b=el('button','cxtab'+(cxTab===k?' on':''),n);
    b.onclick=()=>{ SFX.ui(); cxTab=k; render(); }; nav.appendChild(b); });
  nav.appendChild(btn('sm ghost','BACK',()=>{ screen='menu'; render(); }));
  shell.appendChild(nav);
  const pane=el('div','cxpane');
  pane.appendChild(CX_BODY[cxTab]());
  shell.appendChild(pane);
  w.appendChild(shell);
  return w;
}

const CX_BODY={
 basic:()=>{ const d=el('div');
  d.appendChild(cxH('A RUN'));
  d.appendChild(cxP(`A <b>run</b> is 12 waves (Short) or 20 waves (Full). Each wave you choose <b>one of two nodes</b> on the map,
   and after clearing it you pick <b>one of three rewards</b>. After every fight your party <b>heals to full and any fallen Axie is revived</b>,
   so the difficulty sits inside each individual fight rather than in slow attrition.<br>
   Losing ends the run, but you keep every Gene Shard and every point of Lunacia XP you earned.`));
  d.appendChild(cxH('A TURN IN COMBAT'));
  d.appendChild(cxTable(['STEP','WHAT HAPPENS'],[
    [chip('1 · ROLL','#ffd76a'),'All five of your dice and every enemy die roll at once. Whatever an enemy rolls is printed on its card, so its intent is public.'],
    [chip('2 · REROLL','#5fb8ff'),'Mark the dice you want to reroll using the small button on each one, then press REROLL. Mark nothing and every die is rerolled. You get two rerolls per turn by default.'],
    [chip('3 · ACT','#66e08a'),'Click a die then click a target, or drag it straight onto the target. Order is up to you. Ctrl+Z undoes anything.'],
    [chip('4 · END TURN','#ff5f5f'),'Enemies act out exactly the intent they showed, one at a time. Then status effects such as Poison, Burn and Regen tick.'],
  ]));
  d.appendChild(cxH('WHEN DOES UNDO STOP WORKING?'));
  d.appendChild(cxP(`You can undo as much as you like during your turn. The history is cleared at exactly two moments: when you press
   <b>REROLL</b> and when you press <b>END TURN</b>. Both create new randomness. If undo reached back past a reroll you could simply
   rewind until the dice came up perfect, and the game would stop meaning anything.<br>
   <span class="cnote">The relic <b>Infinite Die</b> breaks this rule: rerolling no longer clears your undo history.</span>`));
  d.appendChild(cxH('WINNING AND LOSING'));
  d.appendChild(cxTable(['','CONDITION'],[
    [chip('WIN A FIGHT','#66e08a'),'Every enemy is reduced to 0 HP.'],
    [chip('LOSE','#ff5f5f'),'All five of your main Axies are down. Summoned Axie Eggs do not count, so losing every Egg does not end the run.'],
    [chip('WIN THE RUN','#ffd76a'),'Defeat the final boss on wave 12 (Short) or wave 20 (Full).'],
  ]));
  return d; },

 dice:()=>{ const d=el('div');
  d.appendChild(cxH('A DIE IS AN AXIE'));
  d.appendChild(cxP(`Every Axie carries <b>one six-sided die</b>, and those six faces are its <b>six body parts</b>.
   Class does not decide which part sits on which face. Class decides the <b>distribution</b> of parts.
   Plant has several Back faces, Beast leans on Horn, Aqua on Ears. That is why two Axies of different classes play nothing alike.<br>
   The row of <b>six small squares</b> under each die shows all six faces, with the current one lit. Hover any square to read that face.
   The border colour tells you its rarity.`));
  d.appendChild(cxH('THE SIX PARTS'));
  d.appendChild(cxTable(['PART','ROLE'],[
    [iconChip('dmg','MOUTH'),'Single-target damage. Often carries Lifesteal.'],
    [iconChip('dmg','HORN'),'Your heaviest hits. Often carries Pierce or Heavy.'],
    [iconChip('shield','BACK'),'Shield for itself or an ally.'],
    [iconChip('poison','TAIL'),'Multi-target work: Cleave, area damage and Poison.'],
    [iconChip('heal','EYES'),'Utility: healing, debuffs and summoning.'],
    [iconChip('mana','EARS'),'Mana. Always triggers on its own without using your action.'],
    [iconChip('blank','BLANK'),'A dead face. Reroll it, or overwrite it with a Gene Mutation.'],
  ]));
  d.appendChild(cxH('RARITY LIVES ON THE FACE'));
  d.appendChild(cxP(`This is the biggest difference between this game and others like it: rarity is <b>not</b> a property of the die,
   it is a property of <b>each individual face</b>. A Gene Mutation reward hands you a new face and <b>you decide which of the six it replaces</b>.
   That is a real decision, and sometimes a painful one. Do you overwrite the blank, or the Shield face that has been carrying you?`));
  d.appendChild(cxTable(['TIER','DEFINITION','EXAMPLE'],
    RARITY.map((r,i)=>[chip(r,RAR_COL[i]),
      ['One action, no keywords','One keyword','Two keywords','Two keywords and a big number','Breaks a rule of the game'][i],
      ['MOUTH · Damage 6','HORN · Damage 7 · [Pierce]','HORN · Damage 10 · [Pierce + Crit 25%]','HORN · Damage 18 · [Heavy + Pierce]','TAIL · Poison 7 · [All + Plague]'][i]])));
  d.appendChild(cxH('GOLDEN AND COSMIC DICE'));
  d.appendChild(cxP(`The rarity of the <b>whole die</b> is simply the sum of its faces:<br>
   · <b>two or more Legendary faces</b> makes it a <span class="gold">GOLDEN DIE</span>, with a gold glowing border<br>
   · <b>a single Mythic face</b> makes it a <span class="cos">COSMIC DIE</span>, pulsing pink<br><br>
   In other words, <b>a beautiful die is something you build, not something you find.</b> Rarity here is an output of your decisions, not an input.`));
  d.appendChild(cxH('WHY CRIT IS SHOWN BEFORE YOU ATTACK'));
  d.appendChild(cxP(`Crit is decided the moment the die lands, and a <b>CRIT x2</b> badge appears on that face straight away.
   The reason is simple: the whole game rests on you seeing every piece of information before you commit. If crit were rolled
   when you pressed attack, you could no longer plan a turn.`));
  return d; },

 mana:()=>{ const d=el('div');
  d.appendChild(cxH('WHAT MANA IS FOR'));
  d.appendChild(cxP(`<b>Mana is a shared party resource</b>, not something an individual Axie owns. You spend it on
   <b>Lunacia Cards</b>, which are the relics with a button along the bottom bar. Put simply: your dice are what you do
   <i>every</i> turn, and Mana is the extra move you choose <i>when</i> to make.`));
  d.appendChild(cxH('EARNING MANA'));
  d.appendChild(cxTable(['SOURCE','DETAIL'],[
    [iconChip('mana','EARS faces'),'Your main source. Ears faces always trigger on their own the moment they land, and the die then rerolls itself for free. An Ears face never costs you an action.'],
    [chip('AQUA class','#4aa8d8'),'The CONDUIT passive adds 1 to every Mana gain. A team without Aqua cannot really run a Mana build.'],
    [chip('Mana keyword','#c78cff'),'Some faces grant Mana alongside their main effect.'],
    [chip('Keen Ears relic','#b8b2cc'),'All Mana faces give 1 more.'],
  ]));
  d.appendChild(cxH('THE RULES'));
  d.appendChild(cxTable(['RULE','WHAT IT MEANS'],[
    ['Carries over','Mana is not lost at the end of a turn. You can bank it for one big play.'],
    ['Resets each fight','Every new fight starts at 0 Mana. Saving Mana between fights does nothing.'],
    ['No cap','There is no maximum. The Mana orb glows and pulses once you reach 10.'],
    ['One use per card','Each Lunacia Card can be used once per turn, even if you could afford it twice.'],
  ]));
  d.appendChild(cxH('TWO WAYS TO CONVERT SPARE MANA'));
  d.appendChild(cxTable(['SOURCE','EFFECT'],[
    [chip('AQUA passive','#4aa8d8'),'Every 4 Mana you have SPENT this fight grants 1 Reroll. The more you spend, the more control you have over your dice.'],
    [chip('Overflow','#c78cff'),'The Mana Flood relic and the Mythic face ENDLESS EARS turn unspent Mana at the end of your turn into area damage equal to that amount.'],
  ]));
  d.appendChild(cxP(`<span class="cnote"><b>The common mistake</b> is hoarding Mana and never spending it. Without Overflow, idle Mana is
   wasted Mana, and with Aqua it also chokes off your reroll supply. The rule of thumb: <b>spend steadily, do not hoard.</b></span>`));
  d.appendChild(cxH('LUNACIA CARDS'));
  d.appendChild(cxTable(['CARD','COST','EFFECT'],
    RELICS.filter(r=>r.act).map(r=>[chip(r.n,RAR_COL[r.rar]),iconChip('mana',String(r.act.cost)),
      r.d.replace(/^\[MP \d+\]\s*/,'')])));
  return d; },

 kw:()=>{ const d=el('div');
  d.appendChild(cxH('KEYWORDS ON A FACE'));
  d.appendChild(cxP('Keywords are what turn an ordinary face into one you remember. They appear in gold text just below the number on the die.'));
  d.appendChild(cxH('TARGETING'));
  d.appendChild(cxTable(['KEYWORD','EFFECT'],[
    [chip('Cleave','#ffd76a'),'Full damage to the target and half to the two units next to it. Position matters here.'],
    [chip('All','#ffd76a'),'Hits every unit on that side. No target selection needed.'],
    [chip('Chain N','#ffd76a'),'N separate hits on random targets. High total damage, no control.'],
    [chip('Multi N','#ffd76a'),'Performs the action N times against the same target.'],
  ]));
  d.appendChild(cxH('DAMAGE'));
  d.appendChild(cxTable(['KEYWORD','EFFECT'],[
    [chip('Pierce','#e26fa8'),'Ignores Shield completely and hits HP directly.'],
    [chip('Execute','#e26fa8'),'60% more damage against a target below 50% HP.'],
    [chip('Vital','#e26fa8'),'Double value while the attacking Axie is at full HP.'],
    [chip('Crit N%','#ffd76a'),'An N% chance to deal double damage, rolled when the die lands and shown on the face.'],
    [chip('Lifesteal','#66e08a'),'Heals the attacker for the damage dealt.'],
  ]));
  d.appendChild(cxH('CHANGES OVER TIME'));
  d.appendChild(cxTable(['KEYWORD','EFFECT'],[
    [chip('Growth','#66e08a'),'Permanently gains 1 for the rest of the fight each time you use it. The longer the fight, the scarier the face.'],
    [chip('Decay','#ff5f5f'),'Loses 1 each time you use it. Strong early, weak later.'],
  ]));
  d.appendChild(cxH('SPECIAL RULES'));
  d.appendChild(cxTable(['KEYWORD','EFFECT'],[
    [chip('Cantrip','#5fb8ff'),'Triggers on its own the moment it lands, then the die rerolls itself for free. It never costs you an action.'],
    [chip('Heavy','#ffd76a'),'This die cannot be rerolled. In exchange the number is much higher.'],
    [chip('+Reroll','#5fb8ff'),'Using this face immediately gives you another Reroll.'],
    [chip('Self-damage N','#ff5f5f'),'The attacking Axie takes N piercing damage.'],
  ]));
  d.appendChild(cxH('MYTHIC — RULE BREAKERS'));
  d.appendChild(cxTable(['KEYWORD','WHAT IT BREAKS'],[
    [chip('Echo x2',RAR_COL[4]),'The face triggers twice from a single roll.'],
    [chip('Plague',RAR_COL[4]),'Poison from this face never loses stacks. It stays forever.'],
    [chip('Bastion',RAR_COL[4]),'Creating Shield also deals damage equal to the Shield value.'],
    [chip('Overflow',RAR_COL[4]),'Unspent Mana explodes into area damage at the end of your turn.'],
  ]));
  return d; },

 st:()=>{ const d=el('div');
  d.appendChild(cxH('HELPFUL EFFECTS'));
  d.appendChild(cxTable(['','EFFECT','RULE'],[
    [ico('shield','t'),'Shield','Absorbs damage before HP. It does NOT expire at the end of a turn, it stays until it is broken. Pierce ignores it entirely.'],
    [ico('regen','t'),'Regen N','Heals N at the end of the turn, then N drops by 1.'],
    [ico('thorns','t'),'Thorns N','Anything that attacks this unit takes N damage back. Reptile always has Thorns 2.'],
    [ico('undying','t'),'Undying','Survives one lethal hit at 1 HP.'],
  ]));
  d.appendChild(cxH('HARMFUL EFFECTS'));
  d.appendChild(cxTable(['','EFFECT','RULE'],[
    [ico('poison','t'),'Poison N','Deals N piercing damage at the end of the turn, then N drops by 1. This is cumulative damage, so the more stacks the deadlier it gets.'],
    [ico('burn','t'),'Burn N','Deals N damage at the end of the turn, then N is halved. Faster than Poison up front, but it burns out quickly.'],
    [ico('weaken','t'),'Weaken N','That unit deals N less damage per hit.'],
    [ico('vuln','t'),'Vulnerable N','That unit takes 50% more damage.'],
    [ico('blind','t'),'Blind N','All of that unit\\u2019s damage faces deal 0 for N turns. Devastating against a single-target boss.'],
    [ico('stun','t'),'Stun','The unit skips its turn entirely.'],
    [ico('freeze','t'),'Frozen','The die cannot be rerolled, but it can still be used. This constrains you rather than taking something away.'],
  ]));
  d.appendChild(cxP(`<span class="cnote">Poison and Burn both <b>pierce</b>, so Shield does not stop them. That is why even a Shield build
   has to deal with Poisoners quickly.</span>`));
  return d; },

 cls:()=>{ const d=el('div');
  d.appendChild(cxH('THE SIX CLASSES'));
  d.appendChild(cxP('A passive is what defines a playstyle. It is always on, needs no activation, and acts as the <b>engine</b> of its matching archetype.'));
  d.appendChild(cxTable(['CLASS','PASSIVE','EFFECT'],
    CLASSES.map(c=>[chip(c.toUpperCase(),CLASS_COLOR[c]),chip(PASSIVE[c].n,CLASS_COLOR[c]),PASSIVE[c].d])));
  d.appendChild(cxH('THREE TIERS PER CLASS'));
  d.appendChild(cxTable(['CLASS','T1','T2','T3'],
    CLASSES.map(c=>{ const k1=c+'1',k2=c+'2',k3=c+'3';
      return [chip(c.toUpperCase(),CLASS_COLOR[c]),
        HEROES[k1].n+' · HP '+HEROES[k1].hp, HEROES[k2].n+' · HP '+HEROES[k2].hp, HEROES[k3].n+' · HP '+HEROES[k3].hp]; }),
    'tiertable'));
  d.appendChild(cxP(`The <b>LEVEL UP</b> reward promotes one Axie to the next tier and <b>rewrites all six faces and its Max HP</b>.
   It is the single largest source of power in a run. Once an Axie is at T3 the reward becomes <b>ASCENSION</b> instead, which makes
   all six faces 25% stronger and stacks without limit.<br>
   <span class="cnote">Careful: Level Up overwrites faces you gained from Gene Mutation too. Think twice before mutating an Axie that is about to be promoted.</span>`));
  d.appendChild(cxH('THE TEN PLAYSTYLES'));
  d.appendChild(cxP('The <b>BUILD</b> bar at the top of the combat screen scores your playstyles live, based on your classes, relics and die faces.'));
  d.appendChild(cxTable(['PLAYSTYLE','DIRECTION'],
    Object.keys(ARCH).map(k=>[chip(ARCH[k].n,ARCH[k].c),ARCH[k].d])));
  return d; },

 relic:()=>{ const d=el('div');
  const tot=RELICS.length, act=RELICS.filter(r=>r.act).length;
  d.appendChild(cxH('THE FULL RELIC TABLE'));
  d.appendChild(cxP(`There are <b>${tot} relics</b> in total: <b>${tot-act} passives</b> that are always on and change a rule of the game,
   and <b>${act} active cards</b> that cost Mana. Relics apply to your <b>whole party</b>, never to a single Axie.
   You find them in rewards, at the Merchant, in Treasure nodes and through events.`));
  const cnt=[0,1,2,3].map(r=>RELICS.filter(x=>x.rar===r).length);
  const sum=el('div','cxsum');
  [0,1,2,3].forEach(r=>{ const b=el('div','cxsumbox'); b.style.borderColor=RAR_COL[r];
    b.appendChild(el('div','csv',String(cnt[r]))); b.appendChild(el('div','csk',RARITY[r])); sum.appendChild(b); });
  d.appendChild(sum);
  const fbar=el('div','cxfilter');
  fbar.appendChild(el('span','cl','FILTER BY PLAYSTYLE'));
  const mk=(k,n,c)=>{ const b=el('button','cxfb'+(cxFilter===k?' on':''),n);
    if(c){b.style.borderColor=c;b.style.color=c;} b.onclick=()=>{ SFX.ui(); cxFilter=(cxFilter===k?'':k); render(); }; return b; };
  fbar.appendChild(mk('','ALL'));
  Object.keys(ARCH).forEach(k=>fbar.appendChild(mk(k,ARCH[k].n,ARCH[k].c)));
  d.appendChild(fbar);
  [3,2,1,0].forEach(rar=>{
    let list=RELICS.filter(r=>r.rar===rar);
    if(cxFilter) list=list.filter(r=>r.a===cxFilter);
    if(!list.length) return;
    d.appendChild(cxH(RARITY[rar]+'  ·  '+list.length+' relics'));
    d.appendChild(cxTable(['NAME','PLAYSTYLE','EFFECT'],
      list.map(r=>[chip(r.n,RAR_COL[rar]),
        r.a&&ARCH[r.a]?chip(ARCH[r.a].n,ARCH[r.a].c):chip('-','#5a5378'),
        (r.act?'[CARD · '+r.act.cost+' MANA] ':'')+r.d.replace(/^\[MP \d+\]\s*/,'')]),'relictable'));
  });
  return d; },

 reward:()=>{ const d=el('div');
  d.appendChild(cxH('MAP NODES'));
  d.appendChild(cxP('Each wave offers two nodes. The two options are <b>always of different types</b>, so it is always a real decision and never two identical choices.'));
  d.appendChild(cxTable(['NODE','DESCRIPTION'],
    Object.keys(NODE_INFO).map(k=>[iconChip(NODE_INFO[k].ic,NODE_INFO[k].n,NODE_INFO[k].c),NODE_INFO[k].d])));
  d.appendChild(cxH('THE EIGHT REWARD TYPES'));
  d.appendChild(cxTable(['TYPE','EFFECT'],[
    [chip('LEVEL UP','#66e08a'),'Promotes an Axie to the next tier and rewrites all six faces and Max HP. The biggest power spike available.'],
    [chip('ASCENSION','#ffd76a'),'For an Axie already at T3: all six faces get 25% stronger, and it stacks without limit.'],
    [chip('GENE MUTATION','#c78cff'),'Replaces one face with a new one of a given rarity. You choose which face it overwrites.'],
    [chip('RUNE IMBUE','#5fb8ff'),'Adds one keyword to a face you already have.'],
    [chip('RELIC','#5fb8ff'),'An item that changes a rule of the game for your whole party.'],
    [chip('REROLL +1','#5fb8ff'),'Raises your maximum Rerolls per turn, up to 4.'],
    [chip('CHAOS DEAL',RAR_COL[4]),'A gamble: the party loses 20% Max HP for the rest of the run in exchange for an Epic or better relic.'],
    [chip('CURSE PACT',RAR_COL[4]),'A gamble: enemies gain 18% HP and 12% damage for the rest of the run, and every damage face deals 4 more plus 1 extra maximum Reroll.'],
  ]));
  d.appendChild(cxH('REROLLING REWARDS'));
  d.appendChild(cxP(`Once per wave you can <b>redraw all three options</b> if none of them fit your build.
   Without that safety valve a run would fail because of the draw rather than because of your decisions.`));
  d.appendChild(cxH('GENE SHARD'));
  d.appendChild(cxP(`The only currency in the game. You earn it during a run (25 from a normal fight, 45 from an Elite, 90 from a Boss, plus
   whatever events give you) and spend it at the <b>Merchant</b> mid-run. Whatever is left when the run ends is
   <b>added to your permanent wallet</b> and buys Unlocks from the main menu.`));
  return d; },

 boss:()=>{ const d=el('div');
  d.appendChild(cxH('SIX BOSSES, SIX MECHANICS'));
  d.appendChild(cxP(`A single run only meets 3 bosses (Short) or 4 (Full), and <b>the order is randomised every run</b>, so no two runs feel the same.
   The final boss is always NIGHTMARE AGONY.<br>
   <span class="cnote">Design principle: a boss should <b>constrain</b> you, never <b>destroy</b> what you built. Frost Lord freezes a die,
   so you can still use it but cannot reroll it. It never deletes a face. Losing a build you spent 30 minutes assembling is bad design.</span>`));
  d.appendChild(cxTable(['BOSS','MECHANIC'],BOSSES.map(b=>[chip(b.n,'#ff5f5f'),b.desc])));
  d.appendChild(cxH('THE CHIMERA ROSTER — NINE ROLES'));
  d.appendChild(cxTable(['ROLE','BEHAVIOUR'],[
    [chip('Bruiser','#ff8f8f'),'Straight damage. Half the time it goes for your healthiest Axie.'],
    [chip('Assassin','#ff8f8f'),'Always attacks your weakest Axie, and usually has Pierce or Execute. Kill it first.'],
    [chip('Tank','#5fb8ff'),'High HP and Shield, low damage, often with Thorns.'],
    [chip('Healer','#66e08a'),'Heals its most wounded ally. Kill it early or the fight drags forever.'],
    [chip('Poisoner','#8fdc4a'),'Applies Poison, which pierces Shield.'],
    [chip('Mage','#c78cff'),'Area damage and debuffs. Blind and Vulnerable are especially painful.'],
    [chip('Summoner','#b0a8d0'),'Calls in more enemies. Leave it alone and you get buried.'],
    [chip('Kamikaze','#ff9a4d'),'Low HP, one enormous area attack, then it dies. Kill it before it detonates.'],
    [chip('Buffer','#ffd76a'),'Enrages its allies for 25% more damage. Dangerous indirectly.'],
  ]));
  return d; },

 diff:()=>{ const d=el('div');
  d.appendChild(cxH('ASCENSION — THE DIFFICULTY CEILING'));
  d.appendChild(cxP(`Every run you win unlocks the next Ascension level. This is what lets broken builds exist without making the game boring:
   as your power grows, the ceiling grows with it.`));
  d.appendChild(cxTable(['LEVEL','MODIFIER (STACKING)'],ASCENSION.map(a=>[chip('A'+a.a,'#ff9ad1'),a.d])));
  d.appendChild(cxH('TWO RUN LENGTHS'));
  d.appendChild(cxTable(['MODE','LENGTH','BOSSES','ELITES'],[
    [chip('SHORT RUN','#66e08a'),'12 waves · about 15 min','Waves 4, 8, 12','Waves 3, 6, 10'],
    [chip('FULL RUN','#ffd76a'),'20 waves · about 35 min','Waves 5, 10, 15, 20','Waves 3, 7, 12, 17'],
  ]));
  d.appendChild(cxH('SHORTCUTS'));
  d.appendChild(cxTable(['KEY','ACTION'],[
    [chip('1 - 5','#ffd76a'),'Select the die of Axie 1 to 5'],
    [chip('R','#ffd76a'),'Reroll'],
    [chip('Space / Enter','#ffd76a'),'End turn'],
    [chip('Ctrl + Z','#ffd76a'),'Undo'],
    [chip('I','#ffd76a'),'Open the information panel'],
    [chip('Esc','#ffd76a'),'Close or deselect'],
    [chip('Hold mouse','#ffd76a'),'Fast-forward animations (4x)'],
    [chip('1x / 2x / 3x','#ffd76a'),'Buttons on the wave bar set the global animation speed'],
  ]));
  return d; },
};

/* ================= GUIDE — đội hình mẫu ================= */
function scGuide(){
  const w=el('div','screen menu guide');
  w.appendChild(el('h1','logo sm','SAMPLE TEAMS'));
  w.appendChild(el('div','sub','Four proven playstyles. Pick one to load it straight into team select.'));
  const g=el('div','guidegrid');
  GUIDES.forEach(G=>{
    const a=ARCH[G.arch];
    const c=el('div','gcard'); c.style.setProperty('--gc',a?a.c:'#ffd76a');
    c.appendChild(el('div','gname',G.n));
    c.appendChild(el('div','gdiff',G.diff));
    const tm=el('div','gteam');
    G.team.forEach((k,i)=>{ const h=HEROES[k];
      const u=el('div','gu'); u.style.setProperty('--cc',CLASS_COLOR[h.cls]);
      const im=el('img','spr'); im.src=sprOf(h.cls,h.art+(G.team.slice(0,i).filter(x=>x===k).length%3));
      u.appendChild(im); u.appendChild(el('div','gn',h.n)); tm.appendChild(u); });
    c.appendChild(tm);
    c.appendChild(el('div','gwhy',G.why));
    const ul=el('div','ghow');
    G.how.forEach(h=>{ const r=el('div','gh'); r.appendChild(el('span','gb','')); r.appendChild(el('span',null,h)); ul.appendChild(r); });
    c.appendChild(ul);
    c.appendChild(btn('sm go gbtn','USE THIS TEAM',()=>{ teamPick=G.team.slice(); screen='team'; render(); }));
    g.appendChild(c);
  });
  w.appendChild(g);
  w.appendChild(btn('','BACK',()=>{ screen='menu'; render(); }));
  return w;
}

/* ================= [4] SETTINGS + [MỚI] BẢNG THÔNG TIN TRONG TRẬN ================= */
let modal=null, infoTab='party', modalUid=null, railOpen=null;

function closeModal(){ modal=null; render(); }
function modalShell(title,sub,tabs,bodyFn){
  const ov=el('div','overlay modalov');
  ov.onclick=e=>{ if(e.target===ov) closeModal(); };
  const bx=el('div','modalbox');
  const hd=el('div','mdhead');
  const ti=el('div','mdtitle'); ti.appendChild(el('span',null,title));
  if(sub) ti.appendChild(el('span','mdsub',sub));
  hd.appendChild(ti);
  const x=el("button","btn xs ghost mdx","CLOSE"); x.onclick=closeModal; hd.appendChild(x);
  bx.appendChild(hd);
  if(tabs){ const tb=el('div','mdtabs');
    tabs.forEach(([k,n])=>{ const b=el('button','mdtab'+(infoTab===k?' on':''),n);
      b.onclick=()=>{ SFX.ui(); infoTab=k; render(); }; tb.appendChild(b); });
    bx.appendChild(tb); }
  const bd=el('div','mdbody'); bd.appendChild(bodyFn()); bx.appendChild(bd);
  ov.appendChild(bx);
  return ov;
}

/* ---------- BẢNG THÔNG TIN ---------- */
const INFO_TABS=[['party','YOUR TEAM'],['relic','YOUR RELICS'],['enemy','ENEMIES'],
  ['st','STATUS EFFECTS'],['kw','KEYWORDS'],['mana','MANA']];
function faceRow(u,f,i){
  const r=el('div','ifrow'+(u&&u.rolled===i?' cur':'')+' r'+(f.r||0));
  r.appendChild(el('div','ifn',String(i+1)));
  const ic=el('div','ific'); ic.appendChild(ico(FT_IC[f.t],'t')); r.appendChild(ic);
  r.appendChild(el('div','ifp',f.name||PARTN[f.p]||TYPEN[f.t]||'—'));
  r.appendChild(el('div','ifv', f.t==='blank'?'—':String(u?faceValue(S,u,i):f.v)));
  const kws=f.k.filter(k=>k!=='heavy');
  r.appendChild(el('div','ifk',kws.length?kws.map(kwText).join(' · '):''));
  if(f.r>=1) r.appendChild(el('div','ifr',RARITY[f.r]));
  return r;
}
/* Click any Axie on the board — yours or the enemy's — to read its whole die.
   The face it is showing right now is marked, so you can judge what it might
   roll next instead of memorising twenty monsters. */
function scUnitInfo(){
  const u = S && byUid(S,modalUid);
  if(!u) return el('div');
  const isE = u.side==='e';
  const sub = 'HP '+u.hp+'/'+u.maxHp + (u.shield?'  ·  Shield '+u.shield:'') + (isE?'':'  ·  Tier '+u.tier);
  return modalShell(u.n.toUpperCase(), sub, null, ()=>{
    const d=el('div','uinsp');
    const h=el('div','ic2h');
    const im=el('img','spr'+(isE?' mut':'')); im.src=isE?sprMon(u.key):sprOf(u.cls,u.artIdx); h.appendChild(im);
    const t=el('div','ic2t');
    if(!isE&&u.pas){ const p=el('div','ic2p'); p.appendChild(el('b',null,u.pas.n+': ')); p.appendChild(el('span',null,u.pas.d)); t.appendChild(p); }
    if(isE&&u.desc) t.appendChild(el('div','ic2s',u.desc));
    if(isE&&u.role) t.appendChild(el('div','ic2t','ROLE: '+u.role.toUpperCase()));
    const stx=Object.keys(ST_IC).filter(k=>u.st[k]>0);
    if(stx.length){ const sr=el('div','ic2st');
      stx.forEach(k=>{ const sp=el('span','st '+k); sp.appendChild(ico(ST_IC[k],'t'));
        sp.appendChild(el('span','stv',String(u.st[k]))); sp.title=ST_NAME[k]; sr.appendChild(sp); });
      t.appendChild(sr); }
    const dr=dieRarity(u);
    if(!isE&&dr>=3) t.appendChild(el('div','ic2dr'+dr,dr>=4?'COSMIC DIE':'GOLDEN DIE'));
    h.appendChild(t); d.appendChild(h);
    d.appendChild(cxP(isE
      ? 'Each face is one in six. Values are already scaled to this wave.'
      : 'Each face is one in six. Values already include buffs, relics and Growth.'));
    const fl=el('div','iflist');
    u.die.forEach((f,i)=>fl.appendChild(faceRow(u,f,i)));
    d.appendChild(fl);
    return d;
  });
}
function scInfo(){
  return modalShell('INFORMATION','Wave '+S.step+' of '+S.len+' · turn '+S.turn, INFO_TABS, ()=>{
    const d=el('div');
    if(infoTab==='party'){
      /* The build read-out lives here rather than on the board — it is worth
         checking between decisions, not on every single frame. */
      d.appendChild(archStrip());
      d.appendChild(cxP('Every face on every Axie. The face currently showing is <b>highlighted in gold</b>. Values already include buffs, relics and Growth.'));
      S.party.filter(u=>!u.token).forEach(u=>{
        const c=el('div','icard2'); c.style.setProperty('--cc',CLASS_COLOR[u.cls]||'#888');
        const h=el('div','ic2h');
        const im=el('img','spr'); im.src=sprOf(u.cls,u.artIdx); h.appendChild(im);
        const t=el('div','ic2t');
        t.appendChild(el('div','ic2n',u.n+' · T'+u.tier+(u.hp<=0?'  [DOWN]':'')));
        t.appendChild(el('div','ic2s','HP '+u.hp+'/'+u.maxHp+(u.shield?'  ·  Shield '+u.shield:'')));
        if(u.pas){ const p=el('div','ic2p'); p.appendChild(el('b',null,u.pas.n+': ')); p.appendChild(el('span',null,u.pas.d)); t.appendChild(p); }
        const stx=Object.keys(ST_IC).filter(k=>u.st[k]>0);
        if(stx.length){ const sr=el('div','ic2st');
          stx.forEach(k=>{ const sp=el('span','st '+k); sp.appendChild(ico(ST_IC[k],'t'));
            sp.appendChild(el('span','stv',String(u.st[k]))); sp.title=ST_NAME[k]; sr.appendChild(sp); });
          t.appendChild(sr); }
        h.appendChild(t);
        const dr=dieRarity(u);
        if(dr>=3) h.appendChild(el('div','ic2dr'+dr,dr>=4?'COSMIC DIE':'GOLDEN DIE'));
        c.appendChild(h);
        const fl=el('div','iflist'); u.die.forEach((f,i)=>fl.appendChild(faceRow(u,f,i))); c.appendChild(fl);
        d.appendChild(c);
      });
    }
    if(infoTab==='relic'){
      const list=S.relics.map(id=>RELIC_BY_ID[id]).filter(Boolean);
      d.appendChild(cxP('You are carrying <b>'+list.length+' relics</b>. Relics apply to your whole party.'));
      if(!list.length) d.appendChild(el('div','iempty','No relics yet. You get them from rewards, the Merchant and Treasure nodes.'));
      const act=list.filter(r=>r.act), pas=list.filter(r=>!r.act);
      if(act.length){ d.appendChild(cxH('LUNACIA CARDS — cost Mana ('+act.length+')'));
        d.appendChild(cxTable(['CARD','COST','EFFECT'],act.map(r=>{
          const used=S.usedActives.includes(r.id), can=S.mana>=r.act.cost&&!used;
          return [chip(r.n,RAR_COL[r.rar]), iconChip('mana',String(r.act.cost),can?'#66e08a':'#ff8f8f'),
            r.d.replace(/^\[MP \d+\]\s*/,'')+(used?'   (already used this turn)':can?'':'   (not enough Mana)')]; }))); }
      if(pas.length){ d.appendChild(cxH('PASSIVE — always on ('+pas.length+')'));
        d.appendChild(cxTable(['RELIC','PLAYSTYLE','EFFECT'],pas.map(r=>[
          chip(r.n,RAR_COL[r.rar]), r.a&&ARCH[r.a]?chip(ARCH[r.a].n,ARCH[r.a].c):chip('—','#5a5378'), r.d]),'relictable')); }
      const sc=archScore(S), keys=Object.keys(sc).filter(k=>sc[k]>0).sort((a,b)=>sc[b]-sc[a]);
      if(keys.length){ d.appendChild(cxH('CURRENT BUILD'));
        d.appendChild(cxTable(['PLAYSTYLE','SCORE','DIRECTION'],
          keys.map(k=>[chip(ARCH[k].n,ARCH[k].c),String(sc[k]),ARCH[k].d]))); }
    }
    if(infoTab==='enemy'){
      d.appendChild(cxP('Every face on every enemy, so you know in advance what it can roll. The face it is showing right now is highlighted in gold.'));
      S.enemies.forEach(e=>{
        const c=el('div','icard2 en'+(e.hp<=0?' dead':''));
        const h=el('div','ic2h');
        const im=el('img','spr mut'); im.src=sprMon(e.key); h.appendChild(im);
        const t=el('div','ic2t');
        t.appendChild(el('div','ic2n',e.n+(e.boss?'  [BOSS]':e.elite?'  [ELITE]':'')+(e.hp<=0?'  [DEAD]':'')));
        t.appendChild(el('div','ic2s','HP '+e.hp+'/'+e.maxHp+(e.shield?'  ·  Shield '+e.shield:'')+'  ·  role: '+(e.role||'-')));
        if(e.desc) t.appendChild(el('div','ic2p',e.desc));
        const stx=Object.keys(ST_IC).filter(k=>e.st[k]>0);
        if(stx.length){ const sr=el('div','ic2st');
          stx.forEach(k=>{ const sp=el('span','st '+k); sp.appendChild(ico(ST_IC[k],'t'));
            sp.appendChild(el('span','stv',String(e.st[k]))); sr.appendChild(sp); }); t.appendChild(sr); }
        h.appendChild(t); c.appendChild(h);
        const fl=el('div','iflist'); e.die.forEach((f,i)=>fl.appendChild(faceRow(e,f,i))); c.appendChild(fl);
        d.appendChild(c);
      });
    }
    if(infoTab==='st') d.appendChild(CX_BODY.st());
    if(infoTab==='kw') d.appendChild(CX_BODY.kw());
    if(infoTab==='mana') d.appendChild(CX_BODY.mana());
    return d;
  });
}

/* ---------- SETTINGS ---------- */
function scSettings(){
  return modalShell('SETTINGS',null,null,()=>{
    const d=el('div','setwrap');
    const row=(lbl,node)=>{ const r=el('div','setrow'); r.appendChild(el('div','setl',lbl)); r.appendChild(node); d.appendChild(r); };
    /* âm lượng */
    const vw=el('div','setctl');
    const vi=document.createElement('input'); vi.type='range'; vi.min=0; vi.max=100; vi.step=5;
    vi.value=Math.round((META.vol!=null?META.vol:0.28)*100/0.6*0.6*100/100*100)/100*1;
    vi.value=Math.round((META.vol!=null?META.vol:0.28)*167);
    const vv=el('span','setv',vi.value+'%');
    vi.oninput=()=>{ vv.textContent=vi.value+'%'; META.vol=(+vi.value)/167; AU.vol=META.vol; AU.on=+vi.value>0; saveMeta(); };
    vw.appendChild(vi); vw.appendChild(vv);
    const mb=el('button','btn sm'+(AU.on?'':' on'),AU.on?'SOUND ON':'SOUND OFF');
    mb.onclick=()=>{ AU.on=!AU.on; META.mute=!AU.on; saveMeta(); render(); };
    vw.appendChild(mb);
    row('VOLUME',vw);
    /* tốc độ */
    const sw=el('div','setctl');
    [1,2,3].forEach(v=>{ const b=el('button','btn sm'+(SPD===v?' on':''),v+'x');
      b.onclick=()=>{ SPD=v; META.spd=v; saveMeta(); render(); }; sw.appendChild(b); });
    row('ANIMATION SPEED',sw);
    /* tra cứu */
    const iw=el('div','setctl');
    iw.appendChild(btn('sm','INFORMATION',()=>{ modal='info'; render(); }));
    iw.appendChild(btn('sm','CODEX',()=>{ modal=null; screen='codex'; render(); }));
    row('REFERENCE',iw);
    /* run */
    const rw=el('div','setctl');
    rw.appendChild(btn('sm','SAVE & QUIT TO MENU',()=>{ saveRun(); modal=null; screen='menu'; render(); }));
    const ab=btn('sm danger','ABANDON RUN',()=>{
      if(confirm('Abandon this run? You keep the Gene Shard and XP you have already earned.')){
        S.phase='lost'; onRunEnd(); modal=null; render(); } });
    rw.appendChild(ab);
    row('RUN',rw);
    d.appendChild(el('div','sethint','Shortcuts: I opens information · Esc closes · Space ends the turn · Ctrl+Z undoes'));
    return d;
  });
}
