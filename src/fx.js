/* ============ COMBAT ANIMATION ENGINE (S&D-style playback) ============
   Engine phát ra một stream sự kiện có thứ tự (s.ev). UI phát lại tuần tự:
   lunge → flash → knockback → số bay lên → HP bar tụt (chip bar) → chết.
   Trong lúc playback KHÔNG re-render (giữ DOM ổn định), chỉ mutate trực tiếp. */

let playing=false, skipHold=false, dragging=null, aimEl=null, lastDragEnd=0;

const unitEl=uid=>document.querySelector('.unit[data-uid="'+uid+'"]');
const dieBoxEl=uid=>document.querySelector('.diebox[data-uid="'+uid+'"]');
const wait=ms=>new Promise(r=>setTimeout(r, Math.max(8, ms/(SPD*(skipHold?4:1)))));

function centerOf(n){ const r=n.getBoundingClientRect(); return {x:r.left+r.width/2,y:r.top+r.height/2}; }

/* ---------- bar helpers ---------- */
function setBars(uid,hp,maxHp,shield){
  const n=unitEl(uid); if(!n) return;
  const pct=Math.max(0,100*hp/maxHp);
  const fill=n.querySelector('.hpfill'), txt=n.querySelector('.hpnum b');
  if(fill) fill.style.width=pct+'%';
  if(txt) txt.textContent=Math.max(0,hp)+'/'+maxHp;
  /* keep the danger class in sync during playback, not only on re-render */
  const bar=n.querySelector('.hpbar');
  if(bar){ const p=maxHp?hp/maxHp:0;
    bar.classList.toggle('low', p<=0.50 && p>0.25);
    bar.classList.toggle('crit', p<=0.25 && p>0);
    bar.setAttribute('aria-valuenow',String(Math.max(0,hp))); }
  let sb=n.querySelector('.shbar');
  if(shield>0){
    if(!sb){ sb=el('div','shbar'); const sl=el('span'); sl.appendChild(ico('shield','t'));
      sl.appendChild(el('span','stv','0')); sb.appendChild(sl); n.querySelector('.hpbar').after(sb); }
    sb.style.width=Math.min(100,100*shield/maxHp)+'%';
    const v=sb.querySelector('.stv'); if(v) v.textContent=String(shield);
    sb.classList.remove('brk');
  } else if(sb){ sb.classList.add('brk'); setTimeout(()=>sb.remove(),260/SPD); }
}
function floatOn(uid,txt,cls,big){
  const host=document.querySelector('.floats[data-uid="'+uid+'"]'); if(!host) return;
  const n=el('div','ftx '+cls+(big?' b'+big:''),txt);
  n.style.animationDuration=(1100/SPD)+'ms';
  n.style.left=(50+(Math.random()*30-15))+'%';
  host.appendChild(n);
  setTimeout(()=>n.remove(),1200/SPD);
}
/* ---------- relic badge (design/gdd/relic-system.md §3.9 + §10 E1) ----------
   engine.js EVrelic() phát {t:'relic',id,uid} với `id` là KEY LUẬT (rhas/rsum key),
   không phải relic id — nên phải tra ngược ra relic đang giữ để hiện đúng TÊN.
   Fallback label lo trường hợp luật đến từ nguồn khác relic (vd `plague` có thể
   do mặt Mythic `plague`, không do r_plaguelord) ⇒ không bao giờ hiện "undefined". */
const RELIC_FX_FIELD = {
  startSummon:['startSummon'], eggInherit:['eggInherit'], critKeep:['critKeep'],
  critFlat:['critFlat'], critPierce:['critPierce'], thorns:['thornsMult','thornsPlus'],
  noShieldCap:['noShieldCap'], growthAll:['growthAll'], plague:['plague'], burnTicks:['burnTicks']
};
const RELIC_FX_LABEL = {
  startSummon:'SUMMON', eggInherit:'INHERIT', critKeep:'CRIT KEPT', critFlat:'CRIT',
  critPierce:'PIERCE', thorns:'THORNS', noShieldCap:'NO CAP', growthAll:'GROWTH',
  plague:'PLAGUE', burnTicks:'BURN'
};
/* Pha màu archetype về phía trắng, trả HEX phẳng. Vì sao tính ở JS mà không dùng
   CSS color-mix(): computed style của color-mix serialise thành `color(srgb ...)`,
   và helper contrast của tools/verify.mjs chỉ parse `rgb()/rgba()` — màu sẽ bị đọc
   nhầm thành trắng, tức check contrast trên phần tử đó trở nên vô nghĩa (đo được,
   xem báo cáo). Hex phẳng giữ cho badge tự chứng minh được bằng chính công cụ gate. */
function relicFxLighten(hex,amt){
  const m=/^#([0-9a-f]{6})$/i.exec(hex||''); if(!m) return hex;
  const v=parseInt(m[1],16), mix=c=>Math.round(c+(255-c)*amt);
  return '#'+[mix(v>>16&255),mix(v>>8&255),mix(v&255)]
    .map(c=>c.toString(16).padStart(2,'0')).join('');
}
/* Tra relic đang giữ có field tương ứng. rlist() lọc theo s.relics nên chỉ trả về
   relic người chơi THẬT SỰ cầm — nếu không có, luật đến từ face/class passive. */
function relicFxInfo(id){
  const fields=RELIC_FX_FIELD[id]||[id];
  let hit=null;
  try{ for(const r of rlist(S)){ if(fields.some(f=>r[f]!=null)){ hit=r; break; } } }catch(e){}
  const arch=ARCH[hit?hit.a:'']||null;
  const c=arch?arch.c:'#ffc857';   /* fallback = --acc, hex phẳng để đo được */
  return { n:(hit?hit.n:(RELIC_FX_LABEL[id]||id)).toUpperCase(),
           ic:arch?arch.ic:'◆', c, ctx:relicFxLighten(c,0.22) };
}
/* Throttle: CẢ HAI trục, vì hai kiểu spam khác nhau.
   1) Coalesce repeat cùng id — relic trên onHit/onDmgTaken/onThorns bắn nhiều lần
      trong MỘT lượt (thorns × 5 đòn AoE = 5 event giống hệt). Lần đầu hiện badge,
      các lần sau trong cửa sổ RELIC_FX_HOLD chỉ tăng bộ đếm "×N" trên badge đang
      sống → người chơi vẫn biết nó chạy 5 lần mà màn hình không nhấp nháy.
   2) Xếp hàng id KHÁC nhau theo bậc thang — 3 relic khác nhau cùng lượt là 3 thông
      tin khác nhau, không được nuốt. Bậc thang tính THEO TỪNG UNIT (đếm badge đang
      sống trong host đó), không phải một bộ đếm toàn cục: hai relic nổ trên hai
      Axie khác nhau không che nhau nên không có lý do gì phải đẩy cái thứ hai xuống.
   KHÔNG dùng await: badge sống bằng setTimeout riêng, playback không bị kéo dài,
   nên turn timing / replay không đổi. */
const RELIC_FX_HOLD=600;
let relicFxLive={};
function relicBadge(id,uid){
  const now=Date.now();
  /* Đã có badge cùng id còn sống → gộp, không tạo phần tử mới. */
  /* Điều kiện gộp = "badge đó CÒN trên màn hình", không phải một mốc thời gian
     song song: mọi thời lượng ở đây chia cho SPD, nên một hằng số 600ms cứng sẽ
     lệch khỏi tuổi thọ thật của badge ở speed khác 1 và sinh ra badge thứ hai
     cùng tên nằm cạnh badge thứ nhất. isConnected là nguồn sự thật duy nhất. */
  const live=relicFxLive[id];
  if(live&&live.node&&live.node.isConnected&&!live.node.classList.contains('rb-out')){
    live.n++; live.at=now;
    let c=live.node.querySelector('.rbx');
    if(!c){ c=el('span','rbx'); live.node.appendChild(c); }
    c.textContent='×'+live.n;
    live.node.classList.remove('rb-pop'); void live.node.offsetWidth; live.node.classList.add('rb-pop');
    clearTimeout(live.timer);
    live.timer=setTimeout(()=>relicBadgeEnd(id),RELIC_FX_HOLD/SPD);
    return;
  }
  /* Neo vào .sprwrap (khối tranh) chứ KHÔNG phải .floats. Lý do đo được, không
     phải thẩm mỹ: .floats nằm ở đỉnh card, mà đỉnh card của ĐỊCH chính là dòng
     intent ("☠3 → Cub") — thông tin quyết định lượt chơi. Badge phủ lên đó dù chỉ
     600ms vẫn là che mất dữ liệu người chơi cần. .sprwrap chỉ chứa tranh (không có
     số nào), position:relative sẵn, và co giãn theo card ở cả 4 breakpoint nên
     không cần magic number cho từng cỡ. Fallback .floats giữ cho badge luôn hiện
     được kể cả nếu cấu trúc card đổi.
     uid null (startSummon xảy ra trước khi có unit card) → neo vào Axie đầu đội. */
  const un=uid!=null?unitEl(uid):null;
  let host=un&&(un.querySelector('.sprwrap')||un.querySelector('.floats'));
  if(!host){ const f=document.querySelector('.zone.party .sprwrap')||document.querySelector('.sprwrap')
             ||document.querySelector('.floats'); host=f; }
  if(!host) return;
  const slot=host.querySelectorAll('.rbadge:not(.rb-out)').length;
  const info=relicFxInfo(id);
  const n=el('div','rbadge');
  n.style.setProperty('--rbc',info.c);
  n.style.setProperty('--rbc-tx',info.ctx);
  n.style.setProperty('--rbi',String(slot%3));
  n.appendChild(el('span','rbi',info.ic));
  n.appendChild(el('span','rbn',info.n));
  host.appendChild(n);
  /* Cue rất nhỏ (hover tick), CHỈ khi badge mới xuất hiện — lần gộp ×N im lặng,
     nếu không một relic thorns bắn 5 lần sẽ thành 5 tiếng bíp. Đi qua SFX chứ
     không tự tạo audio node, theo luật "UI sound qua audio event system". */
  try{ SFX.hover(); }catch(err){}
  relicFxLive[id]={node:n,n:1,at:now,timer:setTimeout(()=>relicBadgeEnd(id),RELIC_FX_HOLD/SPD)};
}
function relicBadgeEnd(id){
  const live=relicFxLive[id]; if(!live) return;
  delete relicFxLive[id];
  const n=live.node; if(!n||!n.isConnected) return;
  n.classList.add('rb-out');
  setTimeout(()=>n.remove(),220/SPD);
}

/* ---------- unit motion ---------- */
function lunge(srcUid,tgtUid){
  const a=unitEl(srcUid), b=tgtUid!=null?unitEl(tgtUid):null;
  if(!a) return;
  const dir = b ? Math.sign(centerOf(b).y-centerOf(a).y)||-1 : -1;
  const dx = b ? (centerOf(b).x-centerOf(a).x)*0.10 : 0;
  a.style.setProperty('--lx',Math.max(-40,Math.min(40,dx))+'px');
  a.style.setProperty('--ly',(dir*22)+'px');
  a.classList.remove('lunge'); void a.offsetWidth; a.classList.add('lunge');
  setTimeout(()=>a.classList.remove('lunge'),340/SPD);
}
function flashU(uid,cls){
  const n=unitEl(uid); if(!n) return;
  const s=n.querySelector('.spr'); if(!s) return;
  s.classList.remove('hitflash','healflash','shdflash'); void s.offsetWidth;
  s.classList.add(cls||'hitflash');
  setTimeout(()=>s.classList.remove('hitflash','healflash','shdflash'),260/SPD);
}
function knock(uid,mag){
  const n=unitEl(uid); if(!n) return;
  n.style.setProperty('--kx',(mag>=25?9:mag>=12?6:4)+'px');
  n.classList.remove('knock'); void n.offsetWidth; n.classList.add('knock');
  setTimeout(()=>n.classList.remove('knock'),320/SPD);
}
function deathA(uid){
  const n=unitEl(uid); if(!n) return;
  n.classList.add('dying');
  const p=el('div','puff'); n.appendChild(p);
  setTimeout(()=>{ n.classList.add('dead'); n.classList.remove('dying'); p.remove(); },420/SPD);
}
/* die bay tới mục tiêu */
function dieFly(uid,tgtUid){
  const box=dieBoxEl(uid); const d=box&&box.querySelector('.die'); if(!d) return;
  const tn = tgtUid!=null? unitEl(tgtUid) : null;
  const from=centerOf(d), to= tn? centerOf(tn) : {x:from.x,y:from.y-160};
  const g=d.cloneNode(true); g.classList.add('flyer');
  g.style.left=(from.x-d.offsetWidth/2)+'px'; g.style.top=(from.y-d.offsetHeight/2)+'px';
  g.style.width=d.offsetWidth+'px'; g.style.height=d.offsetHeight+'px';
  document.body.appendChild(g);
  requestAnimationFrame(()=>{ g.style.transitionDuration=(230/SPD)+'ms';
    g.style.transform='translate('+(to.x-from.x)+'px,'+(to.y-from.y)+'px) scale(.45) rotate(18deg)'; g.style.opacity='0'; });
  d.classList.add('spent');
  setTimeout(()=>g.remove(),300/SPD);
}

/* ================= PLAYBACK ================= */
async function playEvents(){
  if(!S||!S.ev||!S.ev.length){ S.ev=[]; return; }
  const evs=S.ev.slice(); S.ev=[];
  /* Combat log (T15): compile the same batch fx.js is about to animate,
     synchronously and before any wait() — the log must be complete at any
     speed, decoupled from animation pacing (design/ux/combat-log.md §Speed-
     Slider Interaction). */
  if(typeof clogIngest==='function') clogIngest(evs);
  playing=true; document.body.classList.add('playing');
  try{ await runEvents(evs); }
  catch(err){ console.error('playback error',err); }
  finally{
    /* Never leave the board locked: if playback throws, the player would be
       unable to click any die or target for the rest of the run. */
    playing=false; document.body.classList.remove('playing'); skipHold=false;
    document.body.classList.remove('dragging'); dragging=null;
  }
}
async function runEvents(evs){
  for(const e of evs){
    if(e.t==='use'){
      if(e.side==='p'){ dieFly(e.uid,e.aoe?null:e.tgt); lunge(e.uid,e.aoe?null:e.tgt); await wait(150); }
      else { lunge(e.uid,e.aoe?null:e.tgt); await wait(110); }
    }
    else if(e.t==='eact'){
      const n=unitEl(e.uid); if(n){ n.classList.add('acting'); setTimeout(()=>n.classList.remove('acting'),520/SPD); }
      await wait(230);
    }
    else if(e.t==='hit'){
      flashU(e.uid,'hitflash'); knock(e.uid,e.v);
      if(e.v>0){ SFX.hit(e.v); shake(e.v>=45?3:e.v>=20?2:1); }
      if(e.crit){ SFX.crit(); hitstop(110); flashScreen('gold'); }
      await wait(e.crit?150:70);
    }
    else if(e.t==='ft'){
      floatOn(e.uid,e.txt,e.cls,e.big);
      if(e.cls==='heal'){ SFX.heal(); flashU(e.uid,'healflash'); }
      else if(e.cls==='shd'&&e.txt[0]==='+'){ SFX.shield(); flashU(e.uid,'shdflash'); }
      else if(e.cls==='poi') SFX.poison();
      else if(e.cls==='man') SFX.mana();
      await wait(40);
    }
    else if(e.t==='hp'){ setBars(e.uid,e.hp,e.maxHp,e.shield); await wait(30); }
    else if(e.t==='death'){ SFX.kill(); deathA(e.uid); await wait(300); }
    else if(e.t==='resonance'){
      /* Formation Resonance (design/quick-specs/formation-resonance-2026-09-01.md):
         glow pulse nhỏ tái dùng style shield/buff đã có, không thêm sprite/màu mới. */
      flashU(e.uid,'shdflash'); SFX.shield();
      await wait(40);
    }
    else if(e.t==='relic'){
      /* §3.9 — relic bắn trên onHit/onKill/onShield/onTurnStart/onDmgTaken nên có thể
         dày đặc; relicBadge() tự throttle. Không await lâu: badge tự hết hạn bằng
         setTimeout, playback không bị kéo dài ⇒ không đụng timing replay dựa vào. */
      relicBadge(e.id,e.uid);
      await wait(30);
    }
    else if(e.t==='tick'){ await wait(160); }
    else if(e.t==='phase'){ SFX.boss(); bigText('PHASE 2','ph'); flashScreen('myth'); shake(3); await wait(700); }
  }
}

/* ================= DRAG & DROP ================= */
function aimInit(){
  if(aimEl) return;
  aimEl=document.createElementNS('http://www.w3.org/2000/svg','svg');
  aimEl.setAttribute('id','aim'); aimEl.innerHTML=
    '<defs><marker id="ah" markerWidth="6" markerHeight="6" refX="3" refY="3" orient="auto">'+
    '<path d="M0,0 L6,3 L0,6 z" fill="#ffd76a"/></marker></defs>'+
    '<line id="aimline" stroke="#ffd76a" stroke-width="4" stroke-dasharray="8 6" marker-end="url(#ah)"/>';
  document.body.appendChild(aimEl);
}
function aimShow(x1,y1,x2,y2){ aimInit(); aimEl.classList.add('on');
  const l=aimEl.querySelector('#aimline'); l.setAttribute('x1',x1); l.setAttribute('y1',y1);
  l.setAttribute('x2',x2); l.setAttribute('y2',y2); }
function aimHide(){ if(aimEl) aimEl.classList.remove('on'); }

function bindDrag(){
  $$('.diebox .die:not(.used):not(.out)').forEach(d=>{
    d.onpointerdown=ev=>{
      if(playing||rollAnim) return;
      const box=d.closest('.diebox'); const uid=+box.dataset.uid;
      const u=byUid(S,uid); if(!u||u.used||u.hp<=0) return;
      const f=u.die[u.rolled]; if(f.t==='blank') return;
      ev.preventDefault();
      const need=needsTarget(u);
      dragging={uid,x0:ev.clientX,y0:ev.clientY,moved:false,el:d,need};
      d.setPointerCapture&&d.setPointerCapture(ev.pointerId);
      /* Faces that hit everything (All), Mana, Summon and Chain need no target.
         Do not select-and-rerender here: that detaches the die element and the
         click never lands, leaving the die stuck highlighted. Fire on release. */
      if(!need) return;
      sel=uid; selRelic=null; render();
    };
  });
}
document.addEventListener('pointermove',ev=>{
  if(!dragging) return;
  const dx=ev.clientX-dragging.x0, dy=ev.clientY-dragging.y0;
  if(!dragging.moved&&Math.hypot(dx,dy)>7){ dragging.moved=true; document.body.classList.add('dragging'); }
  if(!dragging.moved) return;
  const d=dieBoxEl(dragging.uid); if(!d) return;
  const c=centerOf(d);
  aimShow(c.x,c.y,ev.clientX,ev.clientY);
  const over=document.elementFromPoint(ev.clientX,ev.clientY);
  const t=over&&over.closest('.unit.tgt');
  $$('.unit.tgt').forEach(n=>n.classList.toggle('hovtgt',n===t));
});
document.addEventListener('pointerup',ev=>{
  if(!dragging) return;
  const d=dragging; dragging=null;
  /* A finished drag must not also register as a click, or releasing short of a
     target would pop the Axie inspector open. */
  if(d.moved) lastDragEnd=Date.now();
  document.body.classList.remove('dragging'); aimHide();
  $$('.unit.hovtgt').forEach(n=>n.classList.remove('hovtgt'));
  if(!d.moved){
    /* A tap on a no-target face uses it right away. A tap on a targeting face
       keeps the selection so the player can then click a target. */
    if(!d.need){ const u=byUid(S,d.uid); if(u) clickDie(u); }
    return;
  }
  /* Dragging a no-target face anywhere on the board also uses it. */
  if(!d.need){ const u=byUid(S,d.uid); if(u) clickDie(u); return; }
  const over=document.elementFromPoint(ev.clientX,ev.clientY);
  const t=over&&over.closest('.unit.tgt');
  if(t){ doTarget(+t.dataset.uid); }
  else {
    /* Released short of a target. Keep the die selected so a near miss costs
       nothing — the player can just click the target instead of starting over. */
    render();
  }
});
/* Last-resort watchdog. If playback or the roll animation ever hangs, the whole
   board becomes unclickable (body.playing sets pointer-events:none). Rather than
   stranding the player mid-run, release the lock and redraw. */
let lockSince=0;
setInterval(()=>{
  const locked = playing || !!rollAnim;
  if(!locked){ lockSince=0; return; }
  if(!lockSince){ lockSince=Date.now(); return; }
  if(Date.now()-lockSince < 12000) return;
  console.warn('input lock released by watchdog');
  lockSince=0; playing=false; rollAnim=null; skipHold=false; dragging=null;
  document.body.classList.remove('playing','dragging');
  try{ if(S) render(); }catch(e){}
},2000);

/* giữ chuột / space để tua nhanh playback */
document.addEventListener('pointerdown',()=>{ if(playing) skipHold=true; });
document.addEventListener('keydown',e=>{ if(playing&&(e.key===' '||e.key==='Enter')) skipHold=true; });
