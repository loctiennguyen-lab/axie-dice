/* ============ DEV TOOLS — UI Inspector + Style Editor + Export ============
   Bấm F2 (hoặc nút ⚙ ở menu) để bật.
   1) INSPECT : rê chuột lên bất cứ thứ gì → click → gõ ghi chú. Tool tự ghi lại
                màn hình, đường dẫn element, vị trí, kích thước, style hiện tại.
   2) STYLE   : kéo slider chỉnh size/màu/khoảng cách, xem đổi NGAY.
   3) SCREENS : nhảy thẳng tới bất kỳ màn hình nào (không cần chơi lại từ đầu).
   4) EXPORT  : tải về 1 file UI_FEEDBACK.md — gửi lại file đó là đủ. */

const DEV={on:false,tab:'inspect',notes:[],hi:null,box:null,panel:null,sel:null};
const DEV_VER='v0.5';

/* ---------- các knob chỉnh được (map thẳng vào CSS variable) ---------- */
const KNOBS=[
  {v:'--ui-scale', n:'Global UI scale', t:'num', min:0.7, max:1.4, step:0.05, def:1, unit:''},
  {v:'--unit-w',   n:'Unit card width', t:'num', min:100, max:260, step:2, def:166, unit:'px'},
  {v:'--spr-w',    n:'Axie sprite size', t:'num', min:48, max:160, step:2, def:96, unit:'px'},
  {v:'--spr-big',  n:'Boss sprite size', t:'num', min:90, max:280, step:5, def:170, unit:'px'},
  {v:'--die-w',    n:'Die width', t:'num', min:100, max:260, step:2, def:166, unit:'px'},
  {v:'--die-h',    n:'Die height', t:'num', min:80, max:200, step:2, def:112, unit:'px'},
  {v:'--die-num',  n:'Die number size', t:'num', min:16, max:52, step:1, def:31, unit:'px'},
  {v:'--die-kw',   n:'Die keyword text size', t:'num', min:6, max:16, step:1, def:10, unit:'px'},
  {v:'--zone-gap', n:'Gap between cards', t:'num', min:2, max:30, step:1, def:10, unit:'px'},
  {v:'--bd',       n:'Border thickness', t:'num', min:1, max:6, step:1, def:3, unit:'px'},
  {v:'--radius',   n:'Corner radius', t:'num', min:0, max:14, step:1, def:14, unit:'px'},
  {v:'--intent-v', n:'Enemy intent number size', t:'num', min:10, max:34, step:1, def:16, unit:'px'},
  {v:'--hp-h',     n:'HP bar height', t:'num', min:10, max:30, step:1, def:15, unit:'px'},
  {v:'--float-sz', n:'Floating damage size', t:'num', min:12, max:44, step:1, def:26, unit:'px'},
  {v:'--acc',      n:'Accent colour', t:'col', def:'#ffd76a'},
  {v:'--bg',       n:'Background', t:'col', def:'#3c081b'},
  {v:'--bg-top',   n:'Background (gradient top)', t:'col', def:'#5e1433'},
  {v:'--pan',      n:'Panel', t:'col', def:'#232323'},
  {v:'--pan2',     n:'Panel (light 1)', t:'col', def:'#2e2e2e'},
  {v:'--pan3',     n:'Panel (light 2)', t:'col', def:'#3b3b3b'},
  {v:'--line',     n:'Border', t:'col', def:'#791a3e'},
  {v:'--txt',      n:'Text', t:'col', def:'#ffffff'},
  {v:'--dim',      n:'Muted text', t:'col', def:'#919191'},
];
const DEV_STYLE={};
function devSet(v,val){ DEV_STYLE[v]=val; document.documentElement.style.setProperty(v,val); }
function devResetStyle(){ KNOBS.forEach(k=>{ delete DEV_STYLE[k.v]; document.documentElement.style.removeProperty(k.v); }); devRender(); }

/* ---------- nhảy màn hình ---------- */
const DEV_SCREENS=[
  ['menu','MAIN MENU'],['team','TEAM SELECT'],['codex','CODEX'],['guide','SAMPLE TEAMS'],
  ['bp','LUNACIA PASS'],['unlocks','UNLOCK'],['collection','COLLECTION'],
  ['map','MAP'],['combat','NORMAL FIGHT'],['boss','BOSS FIGHT'],
  ['reward','REWARD'],['event','EVENT'],['shop','MERCHANT'],
  ['win','VICTORY'],['lose','DEFEAT'],
];
function devDemoRun(rich){
  teamPick=['plant1','beast1','aqua1','reptile1','bird1'];
  pickSeed='DEV'; pickMode='short'; pickAsc=2;
  META.tut=1; startRun(); tut=0;
  if(rich){
    S.roster[0].key='plant3'; S.roster[1].key='beast3'; S.roster[2].key='aqua3';
    S.roster[3].key='reptile2'; S.roster[4].key='bird2';
    const L=FACE_POOL.filter(f=>f.r===3), M=FACE_POOL.filter(f=>f.r===4&&!f.bp);
    S.roster[0].muts.push({type:'part',idx:0,face:JSON.parse(JSON.stringify(L[3]))});
    S.roster[0].muts.push({type:'part',idx:1,face:JSON.parse(JSON.stringify(L[0]))});
    S.roster[1].muts.push({type:'part',idx:1,face:JSON.parse(JSON.stringify(M[1]))});
    S.relics=['r_apexpredator','r_venomengine','a_ult','a_nova','r_claw','r_solarcore'];
    S.pw=9; S.shards=340;
  }
}
function devGo(k){
  DEV.sel=null; sel=null; selRelic=null; rollAnim=null;
  if(['menu','team','codex','guide','bp','unlocks','collection'].includes(k)){
    if(!META.runs){ META.runs=18; META.wins=3; META.best=12; META.ascMax=4; META.shards=900; META.xp=5200; }
    screen=k; render(); return;
  }
  devDemoRun(true);
  screen='combat';
  if(k==='map'){ S.phase='map'; S.step=6; nextStep(S); S.step=6; }
  else if(k==='combat'){ S.step=6; startCombat(S,'battle'); S.mana=7; }
  else if(k==='boss'){ S.step=12; S.pw=11; startCombat(S,'boss'); S.mana=11; }
  else if(k==='reward'){ S.step=8; startCombat(S,'elite'); S.kind='elite'; S.rewardTier=2; genRewards(S,'elite'); S.phase='reward'; }
  else if(k==='event'){ S.step=5; S.event={def:JSON.parse(JSON.stringify(EVENTS[4])),res:null}; S.phase='event'; }
  else if(k==='shop'){ S.step=5; genShop(S); S.phase='shop'; }
  else if(k==='win'){ S.step=12; startCombat(S,'boss'); S.enemies.forEach(e=>e.hp=0); S.phase='won'; S.stat={dmg:1840,taken:920,turns:41,kills:37,maxHit:126}; S.xpGain=540; }
  else if(k==='lose'){ S.step=8; startCombat(S,'elite'); S.party.forEach(u=>u.hp=0); S.phase='lost'; S.stat={dmg:640,taken:410,turns:22,kills:14,maxHit:48}; S.xpGain=180; }
  S.ev=[]; S.floatText=[];
  render();
}

/* ---------- inspector ---------- */
const DEV_SKIP=['on','sel','dis','tgt','threat','lunge','knock','landed','tumble','acting','hovtgt',
  'dying','low','used','ready','got','lock','rolling','critready','spent','hasnew','brk','frozen'];
function uiPath(n){
  const parts=[]; let cur=n, g=0;
  while(cur&&cur!==document.body&&g++<5){
    let sel2=cur.tagName.toLowerCase();
    const cls=[...cur.classList].filter(c=>!DEV_SKIP.includes(c));
    if(cls.length) sel2='.'+cls.slice(0,3).join('.');
    const par=cur.parentElement;
    if(par){ const sib=[...par.children].filter(x=>x.className===cur.className);
      if(sib.length>1) sel2+='['+(sib.indexOf(cur)+1)+'/'+sib.length+']'; }
    parts.unshift(sel2);
    if(cur.classList&&cur.classList.contains('screen')) break;
    cur=par;
  }
  return parts.join(' > ');
}
function curScreen(){
  if(!S) return screen;
  if(screen!=='combat') return screen;
  return S.phase;
}
function devHighlight(n){
  if(!DEV.box) return;
  if(!n){ DEV.box.style.display='none'; return; }
  const r=n.getBoundingClientRect();
  DEV.box.style.display='block';
  DEV.box.style.left=r.left+'px'; DEV.box.style.top=r.top+'px';
  DEV.box.style.width=r.width+'px'; DEV.box.style.height=r.height+'px';
  const lbl=DEV.box.querySelector('.dvlbl');
  lbl.textContent=uiPath(n)+'   '+Math.round(r.width)+'×'+Math.round(r.height);
  lbl.style.top = r.top<30? (r.height+2)+'px' : '-19px';
}
function devSnapshot(n){
  const c=getComputedStyle(n), r=n.getBoundingClientRect();
  return {screen:curScreen(), path:uiPath(n),
    rect:Math.round(r.width)+'×'+Math.round(r.height)+' @ '+Math.round(r.left)+','+Math.round(r.top),
    text:(n.textContent||'').trim().slice(0,60),
    style:['font-size:'+c.fontSize,'color:'+c.color,'background:'+c.backgroundColor,
      'border:'+c.borderTopWidth+' '+c.borderTopColor,'padding:'+c.padding,'gap:'+c.gap].join(' · ')};
}

/* ---------- panel ---------- */
function devRender(){
  if(!DEV.panel) return;
  const p=DEV.panel; p.innerHTML='';
  const head=el('div','dvhead');
  head.appendChild(el('div','dvtitle','DEV TOOLS  '+DEV_VER));
  const x=el('button','dvx','X'); x.onclick=()=>devToggle(false); head.appendChild(x);
  p.appendChild(head);
  const tabs=el('div','dvtabs');
  [['inspect','NOTES ('+DEV.notes.length+')'],['style','STYLE'],['screens','SCREENS'],['export','EXPORT']]
    .forEach(([k,n])=>{ const b=el('button','dvtab'+(DEV.tab===k?' on':''),n);
      b.onclick=()=>{ DEV.tab=k; devRender(); }; tabs.appendChild(b); });
  p.appendChild(tabs);
  const body=el('div','dvbody');

  if(DEV.tab==='inspect'){
    body.appendChild(el('div','dvhint','Hover anything in the game, click it, then type what you want changed. The tool records the screen, the element, its size and its current style for you.'));
    if(DEV.sel){
      const s2=DEV.sel;
      const bx=el('div','dvsel');
      bx.appendChild(el('div','dvk',s2.screen+'  ·  '+s2.path));
      bx.appendChild(el('div','dvm',s2.rect+(s2.text?'  ·  "'+s2.text+'"':'')));
      bx.appendChild(el('div','dvm',s2.style));
      const ta=el('textarea','dvta'); ta.placeholder='What should change here?\ne.g. "the number is too small, make it 34px and bolder"\ne.g. "move this button to the right, in line with END TURN"';
      bx.appendChild(ta);
      const row=el('div','dvrow');
      const add=el('button','dvbtn go','+ SAVE NOTE');
      add.onclick=()=>{ const t=ta.value.trim(); if(!t) return;
        DEV.notes.push({...s2,note:t}); DEV.sel=null; devSave(); devRender(); };
      const cancel=el('button','dvbtn','Cancel'); cancel.onclick=()=>{ DEV.sel=null; devRender(); };
      row.appendChild(add); row.appendChild(cancel); bx.appendChild(row);
      body.appendChild(bx);
      setTimeout(()=>ta.focus(),30);
    }
    DEV.notes.forEach((n,i)=>{
      const c=el('div','dvnote');
      c.appendChild(el('div','dvk','#'+(i+1)+'  '+n.screen+'  ·  '+n.path));
      c.appendChild(el('div','dvn',n.note));
      const del=el('button','dvdel','X'); del.onclick=()=>{ DEV.notes.splice(i,1); devSave(); devRender(); };
      c.appendChild(del); body.appendChild(c);
    });
    if(!DEV.notes.length&&!DEV.sel) body.appendChild(el('div','dvempty','No notes yet.'));
  }

  if(DEV.tab==='style'){
    body.appendChild(el('div','dvhint','Drag a slider and the game updates instantly. Whatever you change ends up in the exported file.'));
    KNOBS.forEach(k=>{
      const row=el('div','dvknob');
      row.appendChild(el('div','dvkn',k.n));
      if(k.t==='num'){
        const cur=DEV_STYLE[k.v]!=null? parseFloat(DEV_STYLE[k.v]) : k.def;
        const wrap=el('div','dvsl');
        const inp=document.createElement('input'); inp.type='range'; inp.min=k.min; inp.max=k.max; inp.step=k.step; inp.value=cur;
        const val=el('span','dvval',cur+k.unit);
        inp.oninput=()=>{ val.textContent=inp.value+k.unit; devSet(k.v,inp.value+k.unit); };
        wrap.appendChild(inp); wrap.appendChild(val); row.appendChild(wrap);
      } else {
        const cur=DEV_STYLE[k.v]||k.def;
        const inp=document.createElement('input'); inp.type='color'; inp.value=cur; inp.className='dvcol';
        const val=el('span','dvval',cur);
        inp.oninput=()=>{ val.textContent=inp.value; devSet(k.v,inp.value); };
        const wrap=el('div','dvsl'); wrap.appendChild(inp); wrap.appendChild(val); row.appendChild(wrap);
      }
      body.appendChild(row);
    });
    const r=el('div','dvrow'); const rb=el('button','dvbtn','RESET TO DEFAULTS'); rb.onclick=devResetStyle;
    r.appendChild(rb); body.appendChild(r);
  }

  if(DEV.tab==='screens'){
    body.appendChild(el('div','dvhint','Jump straight to any screen without replaying the game. The demo state already has relics, Legendary and Mythic faces, and a boss.'));
    const g=el('div','dvscreens');
    DEV_SCREENS.forEach(([k,n])=>{ const b=el('button','dvbtn scr',n); b.onclick=()=>devGo(k); g.appendChild(b); });
    body.appendChild(g);
  }

  if(DEV.tab==='export'){
    const st=Object.keys(DEV_STYLE).length;
    body.appendChild(el('div','dvhint','Press the button below to download UI_FEEDBACK.md. Send that file back as it is, no explanation needed.'));
    body.appendChild(el('div','dvsum','Notes: '+DEV.notes.length+'\nStyle overrides: '+st));
    const r=el('div','dvrow');
    const d=el('button','dvbtn go','DOWNLOAD UI_FEEDBACK.md'); d.onclick=devExport;
    const c=el('button','dvbtn','COPY TO CLIPBOARD'); c.onclick=()=>{ try{navigator.clipboard.writeText(devText());
      c.textContent='COPIED'; setTimeout(()=>c.textContent='COPY TO CLIPBOARD',1400);}catch(e){} };
    r.appendChild(d); r.appendChild(c); body.appendChild(r);
    const pre=el('pre','dvpre',devText()); body.appendChild(pre);
    const r2=el('div','dvrow');
    const w=el('button','dvbtn','CLEAR ALL NOTES'); w.onclick=()=>{ if(confirm('Delete every note?')){ DEV.notes=[]; devSave(); devRender(); } };
    r2.appendChild(w); body.appendChild(r2);
  }
  p.appendChild(body);
}

function devText(){
  let t='# UI FEEDBACK — Axie Dice Tactics '+DEV_VER+'\n';
  t+='> Generated by the in-game DEV TOOLS. Apply each item below exactly.\n\n';
  const st=Object.keys(DEV_STYLE);
  t+='## 1. STYLE OVERRIDES ('+st.length+')\n';
  if(!st.length) t+='_(none)_\n';
  else { t+='```css\n:root{\n';
    st.forEach(v=>{ const k=KNOBS.find(x=>x.v===v);
      t+='  '+v+': '+DEV_STYLE[v]+';'+(k?'   /* '+k.n+' — default '+k.def+(k.unit||'')+' */':'')+'\n'; });
    t+='}\n```\n'; }
  t+='\n## 2. PER-ELEMENT NOTES ('+DEV.notes.length+')\n';
  if(!DEV.notes.length) t+='_(none)_\n';
  const byScreen={};
  DEV.notes.forEach((n,i)=>{ (byScreen[n.screen]=byScreen[n.screen]||[]).push({...n,i:i+1}); });
  Object.keys(byScreen).forEach(sc=>{
    t+='\n### SCREEN: '+sc.toUpperCase()+'\n';
    byScreen[sc].forEach(n=>{
      t+='\n**['+n.i+'] `'+n.path+'`**\n';
      t+='- Current size: '+n.rect+'\n';
      if(n.text) t+='- Content: "'+n.text+'"\n';
      t+='- Current style: '+n.style+'\n';
      t+='- **REQUESTED CHANGE:** '+n.note+'\n';
    });
  });
  t+='\n---\n_Total: '+DEV.notes.length+' notes · '+st.length+' style overrides_\n';
  return t;
}
function devExport(){
  const blob=new Blob([devText()],{type:'text/markdown'});
  const a=document.createElement('a'); a.href=URL.createObjectURL(blob);
  a.download='UI_FEEDBACK.md'; a.click(); setTimeout(()=>URL.revokeObjectURL(a.href),2000);
}
function devSave(){ try{ localStorage.setItem('axiedice_devnotes',JSON.stringify(DEV.notes)); }catch(e){} }
function devLoad(){ try{ const j=localStorage.getItem('axiedice_devnotes'); if(j) DEV.notes=JSON.parse(j); }catch(e){} }

/* ---------- toggle ---------- */
function devToggle(on){
  DEV.on = on==null? !DEV.on : on;
  document.body.classList.toggle('devmode',DEV.on);
  if(DEV.on){
    devLoad();
    if(!DEV.box){
      DEV.box=el('div','dvbox'); DEV.box.appendChild(el('div','dvlbl','')); document.body.appendChild(DEV.box);
      DEV.panel=el('div','dvpanel'); document.body.appendChild(DEV.panel);
    }
    DEV.box.style.display='none';
    DEV.panel.style.display='flex';
    devRender();
  } else {
    if(DEV.box) DEV.box.style.display='none';
    if(DEV.panel) DEV.panel.style.display='none';
  }
}
document.addEventListener('keydown',e=>{ if(e.key==='F2'){ e.preventDefault(); devToggle(); } });
document.addEventListener('mousemove',e=>{
  if(!DEV.on||DEV.tab!=='inspect'||DEV.sel) return;
  const n=e.target;
  if(!n||n.closest('.dvpanel')||n.classList.contains('dvbox')||n.classList.contains('dvlbl')){ devHighlight(null); return; }
  DEV.hi=n; devHighlight(n);
},true);
/* chặn hoàn toàn input của game khi đang ở chế độ INSPECT
   (nếu không, click vào xí ngầu sẽ kích hoạt drag + re-render và mất element) */
['pointerdown','pointerup','mousedown','mouseup'].forEach(ev=>{
  document.addEventListener(ev,e=>{
    if(!DEV.on||DEV.tab!=='inspect') return;
    if(e.target&&e.target.closest&&e.target.closest('.dvpanel')) return;
    e.preventDefault(); e.stopPropagation();
  },true);
});
document.addEventListener('click',e=>{
  if(!DEV.on||DEV.tab!=='inspect') return;
  const n=e.target;
  if(!n||n.closest('.dvpanel')) return;
  e.preventDefault(); e.stopPropagation();
  DEV.sel=devSnapshot(n); devHighlight(null); devRender();
},true);
