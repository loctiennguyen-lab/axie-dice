/* headless balance simulator v0.2 */
const fs=require('fs'),vm=require('vm');
const ctx={console,Math,JSON};
vm.createContext(ctx);
const NAMES=['CURVE','HEROES','MON','BOSSES','RELICS','RELIC_BY_ID','TIER_UP','T1','CLASSES','FACE_POOL','ARCH','PASSIVE',
  'RUN_LEN','ASCENSION','ascMods','UNLOCKS','EVENTS',
  'newGame','nextStep','chooseNode','startCombat','rollAll','doReroll','anyRerollable','playerUseDie','playerUseRelic',
  'endTurn','undo','takeReward','buildUnit','dieRarity','aliveP','aliveE','realP','byUid','faceValue','hasKw','kwVal',
  'eventChoose','eventDone','shopBuy','shopDone','archScore','faceText','faceArch','nftHpBonusPct'];
const src=['src/data.js','src/engine.js'].map(f=>fs.readFileSync(f,'utf8')).join('\n')
  +'\n;globalThis.__X={'+NAMES.map(n=>n+':'+n).join(',')+'};';
vm.runInContext(src,ctx);
const G=ctx.__X;

const OV={}; process.argv.slice(3).forEach(a=>{const[k,v]=a.split('=');OV[k]=isNaN(+v)?v:+v;});
if(OV.base) G.CURVE.tune.base=OV.base;
if(OV.growth) G.CURVE.tune.growth=OV.growth;
if(OV.growth2) G.CURVE.tune.growth2=OV.growth2;
if(OV.elite) G.CURVE.tune.eliteMult=OV.elite;

const threat=(s,e)=>{ const f=e.intent&&e.intent.face; let t=e.hp*0.12;
  if(f){ if(f.t==='dmg')t+=f.v*(G.hasKw(f,'aoe')?2.2:1)*1.6; if(f.t==='poison')t+=f.v*1.6;
    if(f.t==='heal'||f.t==='shield')t+=f.v*1.0; if(f.t==='debuff')t+=6; if(f.t==='summon')t+=10; }
  if(e.role==='healer')t+=8; if(e.boss)t-=6; return t; };

function aiTurn(s){
  let g=0;
  while(s.rerolls>0&&g++<5){
    const bad=G.aliveP(s).filter(u=>!u.used&&!u.heavy&&!u.frozen&&u.rolled>=0&&(u.die[u.rolled].t==='blank'||G.faceValue(s,u,u.rolled)<=1));
    if(bad.length>=2) G.doReroll(s,bad.map(u=>u.uid)); else break;
  }
  const inc={};
  G.aliveE(s).forEach(e=>{ const f=e.intent&&e.intent.face; if(!f)return;
    if(f.t==='dmg'){ if(G.hasKw(f,'aoe')) G.aliveP(s).forEach(p=>inc[p.uid]=(inc[p.uid]||0)+f.v);
      else if(e.intent.tgt!=null) inc[e.intent.tgt]=(inc[e.intent.tgt]||0)+f.v*(G.kwVal(f,'multi')||1); } });
  let it=0;
  while(it++<40){
    const ready=G.aliveP(s).filter(u=>!u.used&&u.rolled>=0&&u.die[u.rolled].t!=='blank');
    if(!ready.length) break;
    let acted=false;
    for(const u of ready){ const f=u.die[u.rolled]; if(f.t!=='dmg'||G.hasKw(f,'aoe')||G.kwVal(f,'chain'))continue;
      const v=G.faceValue(s,u,u.rolled)*(G.kwVal(f,'multi')||1)*(u.critNow?2:1);
      const kills=G.aliveE(s).filter(e=>(G.hasKw(f,'pierce')?e.hp:e.hp+e.shield)<=v);
      if(kills.length){ kills.sort((a,b)=>threat(s,b)-threat(s,a)); G.playerUseDie(s,u.uid,kills[0].uid); acted=true; break; } }
    if(acted) continue;
    for(const u of ready){ const f=u.die[u.rolled];
      if(f.t!=='shield'&&f.t!=='heal') continue;
      const dg=G.aliveP(s).filter(p=>(inc[p.uid]||0)>=p.hp+p.shield);
      const tgt=dg.length? dg.sort((a,b)=>(inc[b.uid]||0)-(inc[a.uid]||0))[0]
        : G.aliveP(s).sort((a,b)=>((inc[b.uid]||0)-b.shield)-((inc[a.uid]||0)-a.shield))[0];
      if(!tgt) break;
      if(f.t==='heal'&&tgt.hp===tgt.maxHp&&!dg.length) continue;
      G.playerUseDie(s,u.uid,tgt.uid); acted=true; break; }
    if(acted) continue;
    for(const u of ready){ const f=u.die[u.rolled]; let tgt=null;
      if(['dmg','poison','debuff'].includes(f.t)){ const es=G.aliveE(s); if(!es.length)break;
        tgt=es.slice().sort((a,b)=>threat(s,b)-threat(s,a))[0]; }
      else { const ps=G.aliveP(s); tgt=ps.slice().sort((a,b)=>((inc[b.uid]||0)-b.shield)-((inc[a.uid]||0)-a.shield))[0]; }
      if(!tgt){ u.used=true; continue; }
      if(!G.playerUseDie(s,u.uid,tgt.uid)) u.used=true;
      acted=true; break; }
    if(!acted) break;
  }
  for(const id of s.relics.slice()){ const r=G.RELIC_BY_ID[id]; if(!r||!r.act)continue;
    if(s.mana<r.act.cost) continue; const a=r.act;
    if(a.kind==='dmg'||a.kind==='stun'||a.kind==='ult'){ const es=G.aliveE(s); if(es.length) G.playerUseRelic(s,id,es.slice().sort((x,y)=>threat(s,y)-threat(s,x))[0].uid); }
    else if(a.kind==='heal'){ const ps=G.aliveP(s).filter(p=>p.hp<p.maxHp*0.6); if(ps.length) G.playerUseRelic(s,id,ps[0].uid); }
    else G.playerUseRelic(s,id,null);
  }
  G.endTurn(s);
}
const PRI={level:6,ascend:6,relic:5,chaos:4,face:4,rune:3,reroll:3,hp:2,curse:2};
function aiReward(s){ let bi=0,bv=-1; s.rewards.forEach((r,i)=>{ const v=(PRI[r.t]||0)+(r.rar||0)*0.6; if(v>bv){bv=v;bi=i;} });
  return G.takeReward(s,bi); }
function aiNode(s){
  /* AI: ưu tiên elite/battle để lấy power, 35% chọn non-combat */
  const i = s.nodes.length===1?0:(Math.floor(ctxRnd()*100)<35?1:0);
  const j = ['event','shop','treasure'].includes(s.nodes[i].type)? i : (s.nodes.findIndex(n=>['battle','elite','boss'].includes(n.type)));
  return G.chooseNode(s, j>=0? (Math.floor(ctxRnd()*100)<35? i : j) : 0);
}
let _seed=OV.seed0||1; function ctxRnd(){ _seed=(_seed*1103515245+12345)&0x7fffffff; return _seed/0x7fffffff; }

const N=+process.argv[2]||300;
const MODE=OV.mode||'short', ASC=OV.asc||0;
const L=G.RUN_LEN[MODE].len;
const win=Array(L+1).fill(0), tri=Array(L+1).fill(0), trn=Array(L+1).fill(0), die=Array(L+1).fill(0);
const pHp=Array(L+1).fill(0),pDps=Array(L+1).fill(0),eHp=Array(L+1).fill(0),eDps=Array(L+1).fill(0),cnt=Array(L+1).fill(0);
let wins=0, stuck=0; const archWin={}, archAll={};
const TEAMS=[['plant1','beast1','aqua1','reptile1','bug1'],['plant1','beast1','aqua1','bird1','bug1'],
  ['plant1','beast1','beast1','aqua1','reptile1'],['plant1','reptile1','aqua1','bug1','bird1'],
  ['bug1','bug1','reptile1','plant1','aqua1'],['bird1','bird1','beast1','aqua1','plant1']];
for(let n=0;n<N;n++){
  const team=TEAMS[n%TEAMS.length];
  let nftPreselect;
  if(OV.nftCount){ // ví dụ: node tools/sim.js 500 mode=full nftCount=5 nftOwned=8 nftGenes=2
    const owned=OV.nftOwned||1, genes=OV.nftGenes||0;
    nftPreselect=team.map((_,i)=> i<OV.nftCount? {owned,genes} : null);
  }
  const s=G.newGame(9000+n,team,{mode:MODE,asc:ASC,nftPreselect});
  if(OV.bp) s.bpFaces=['bp_plague','bp_apex','bp_bulwark','bp_conduit','bp_swarm'];
  let g=0, seen={};
  while(s.phase!=='won'&&s.phase!=='lost'){
    if(g++>6000){ stuck++; break; }
    if(s.phase==='map'){ aiNode(s); continue; }
    if(s.phase==='event'){ if(!s.event.res) G.eventChoose(s,Math.floor(ctxRnd()*s.event.def.opts.length)); G.eventDone(s); continue; }
    if(s.phase==='shop'){ for(let i=0;i<s.shop.items.length;i++) G.shopBuy(s,i); G.shopDone(s); continue; }
    if(s.phase==='reward'){ if(seen[s.step]){ win[s.step]++; trn[s.step]+=s.turn||1; } if(!aiReward(s)) break; continue; }
    if(s.phase==='combat'){
      if(s.turn===1&&!seen[s.step]){ seen[s.step]=1; tri[s.step]++; cnt[s.step]++;
        let hp=0,dps=0; s.party.forEach(u=>{ hp+=u.maxHp; u.die.forEach((f,i)=>{ const v=f.v+(u.growth[i]||0);
          if(f.t==='dmg')dps+=v*(G.hasKw(f,'aoe')?2.5:1)*(G.kwVal(f,'multi')||G.kwVal(f,'chain')||1)/6;
          else if(f.t==='poison')dps+=v*1.6*(G.hasKw(f,'aoe')?2.5:1)/6; }); });
        let eh=0,ed=0; s.enemies.forEach(e=>{ eh+=e.maxHp; e.die.forEach(f=>{ if(f.t==='dmg')ed+=f.v*(G.hasKw(f,'aoe')?2.5:1)/6;
          else if(f.t==='poison')ed+=f.v*1.6*(G.hasKw(f,'aoe')?2.5:1)/6; }); });
        pHp[s.step]+=hp; pDps[s.step]+=dps; eHp[s.step]+=eh; eDps[s.step]+=ed; }
      if(s.turn>45){ s.phase='lost'; break; }
      aiTurn(s); continue;
    }
    break;
  }
  const a=G.archScore(s); const top=Object.keys(a).sort((x,y)=>a[y]-a[x])[0];
  archAll[top]=(archAll[top]||0)+1;
  if(s.phase==='won'){ wins++; win[L]++; archWin[top]=(archWin[top]||0)+1; }
  if(s.phase==='lost') die[s.step]++;
}
if(OV.q){ const p=[]; for(let w=1;w<=L;w++){const t=tri[w]||0;p.push(t?Math.round(win[w]/t*100):'-');}
  console.log(`mode=${MODE} asc=${ASC} run%=${(wins/N*100).toFixed(1)} | ${p.join(' ')}`); process.exit(0); }
console.log(`=== ${MODE.toUpperCase()} (${L} wave) · Ascension ${ASC} · ${N} run · stuck ${stuck}`);
console.log('full-run winrate:', (wins/N*100).toFixed(1)+'%');
console.log('step  win%  turns |  pHP  pDPS |  eHP  eDPS | ttk  deaths');
for(let w=1;w<=L;w++){
  const t=tri[w]||0,wn=win[w]||0,c=cnt[w]||1;
  const PH=pHp[w]/c,PD=pDps[w]/c,EH=eHp[w]/c,ED=eDps[w]/c;
  const isB=G.RUN_LEN[MODE].boss.includes(w);
  console.log(String(w).padStart(4),(t?(wn/t*100).toFixed(0):'-').padStart(5),(wn?(trn[w]/wn).toFixed(1):'-').padStart(6),'|',
    PH.toFixed(0).padStart(4),PD.toFixed(1).padStart(5),'|',EH.toFixed(0).padStart(4),ED.toFixed(1).padStart(5),'|',
    (EH/Math.max(1,PD)).toFixed(1).padStart(4),String(die[w]).padStart(6), isB?' << BOSS':(G.RUN_LEN[MODE].elite.includes(w)?' < elite':''));
}
console.log('\narchetype (build chủ đạo → winrate):');
Object.keys(archAll).sort((a,b)=>archAll[b]-archAll[a]).forEach(k=>{
  const t=archAll[k],w=archWin[k]||0;
  console.log('  '+(G.ARCH[k]?G.ARCH[k].n:k).padEnd(9), String(t).padStart(4)+' run', (t?(w/t*100).toFixed(0):'0')+'% win');
});
