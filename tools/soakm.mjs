/* Soak test driven by REAL mouse events (pointerdown/move/up), the exact path a player uses. */
import { chromium } from 'playwright';
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';

const FILE = process.argv[2] || 'AxieDiceTactics.html';
const RUNS = +(process.argv[3] || 6);

/* NOTE: this used to hardcode 'file:'+join(__dir,'..','build','index.html')
   for any non-http FILE arg, silently ignoring whatever path was actually
   passed in (e.g. 'AxieDiceTactics.html') and testing a stale, unrelated
   build/index.html artifact instead. Resolve FILE against cwd like t_fit.mjs
   does, so the file you name on the command line is the file that runs. */
const buildFile = FILE.startsWith('http') ? FILE : pathToFileURL(resolve(process.cwd(), FILE)).href;

const b = await chromium.launch({args:['--no-sandbox']});
const p = await b.newPage({ viewport:{width:1700,height:1050} });
const errs = [];
p.on('pageerror', e => errs.push('PAGEERROR: ' + (e.stack||e.message)));
p.on('console', m => { if(m.type()==='error') errs.push('CONSOLE: ' + m.text()); });
await p.goto(buildFile);
await p.waitForTimeout(400);

const st = () => p.evaluate(() => ({
  phase: S ? S.phase : null, step: S?S.step:0, turn: S?S.turn:0,
  playing, rollAnim: !!rollAnim, sel, selRelic,
  dice: [...document.querySelectorAll('.diebox .die:not(.used):not(.out)')].map(d=>{
    const r=d.getBoundingClientRect();
    return {x:r.x+r.width/2, y:r.y+r.height/2, blank:d.classList.contains('blank')};
  }),
  tgts: [...document.querySelectorAll('.unit.tgt')].map(n=>{ const r=n.getBoundingClientRect();
    return {x:r.x+r.width/2, y:r.y+r.height/2}; }),
  btn: (s=>{ const n=document.querySelector(s); if(!n) return null;
    const r=n.getBoundingClientRect(); return {x:r.x+r.width/2,y:r.y+r.height/2}; }),
  end:  (()=>{ const n=document.querySelector('.btn.end'); if(!n) return null; const r=n.getBoundingClientRect(); return {x:r.x+r.width/2,y:r.y+r.height/2}; })(),
  cards:(()=>[...document.querySelectorAll('.rcard:not(.dis):not(.sold)')].map(n=>{ const r=n.getBoundingClientRect(); return {x:r.x+r.width/2,y:r.y+r.height/2}; }))(),
  nodes:(()=>[...document.querySelectorAll('.nodecard')].map(n=>{ const r=n.getBoundingClientRect(); return {x:r.x+r.width/2,y:r.y+r.height/2}; }))(),
  go:   (()=>{ const n=document.querySelector('.btn.go'); if(!n) return null; const r=n.getBoundingClientRect(); return {x:r.x+r.width/2,y:r.y+r.height/2}; })(),
  selFace: (()=>{ if(sel==null||!S) return null; const u=byUid(S,sel); return u?u.die[u.rolled]:null; })(),
}));

const rnd = n => Math.floor(Math.random()*n);
const problems = [];

async function settle(){
  for(let i=0;i<120;i++){
    const s = await p.evaluate(()=>({playing, roll:!!rollAnim}));
    if(!s.playing && !s.roll) return true;
    await p.waitForTimeout(25);
  }
  return false;
}
async function tap(pt){ await p.mouse.move(pt.x,pt.y); await p.mouse.down(); await p.waitForTimeout(25); await p.mouse.up(); await p.waitForTimeout(40); }
async function drag(a,c){ await p.mouse.move(a.x,a.y); await p.mouse.down(); await p.mouse.move(c.x,c.y,{steps:6}); await p.waitForTimeout(20); await p.mouse.up(); await p.waitForTimeout(40); }

for(let r=0;r<RUNS;r++){
  await p.evaluate((r)=>{
    try{ localStorage.clear(); }catch(e){}
    loadMeta();
    META.unlocks = UNLOCKS.map(u=>u.id);
    META.bpFaces = Object.keys(BP_FACES);
    META.perks = {reroll:2,hp4:2,relic0:1,relic1:1,rrw:2};
    META.shards = 9999; META.ascMax = 10; saveMeta();
    teamPick = Array.from({length:5},()=>['plant1','beast1','aqua1','reptile1','bug1','bird1'][Math.floor(Math.random()*6)]);
    pickMode='short'; pickAsc = r%6; pickSeed='m'+r;
    modal=null; sel=null; selRelic=null;
    SPD=6; startRun(); tut=0; render();
  }, r);

  let guard=0, stuck=0, lastSig='';
  while(guard++ < 800){
    if(!await settle()){ problems.push('STALL run '+r+' (playing/rollAnim never cleared)'); break; }
    const s = await st();
    if(s.phase==='won'||s.phase==='lost') break;
    const sig = s.phase+'|'+s.step+'|'+s.turn+'|'+s.dice.length;
    if(sig===lastSig){ if(++stuck>18){ problems.push('NOPROGRESS run '+r+' at '+sig+' sel='+s.sel+' face='+JSON.stringify(s.selFace)); break; } }
    else { stuck=0; lastSig=sig; }

    if(s.phase==='map'){ if(!s.nodes.length){ problems.push('MAP no nodes run '+r); break; } await tap(s.nodes[rnd(s.nodes.length)]); continue; }
    if(s.phase==='reward'){ if(!s.cards.length){ problems.push('REWARD no cards run '+r); break; } await tap(s.cards[rnd(s.cards.length)]); continue; }
    if(s.phase==='event'){
      if(s.cards.length){ await tap(s.cards[rnd(s.cards.length)]); continue; }
      if(s.go){ await tap(s.go); continue; }
      const dump=await p.evaluate(()=>({html:document.querySelector('#app').innerHTML.slice(0,1500), ev:S.event&&{res:S.event.res,def:S.event.def&&S.event.def.n}}));
      problems.push(s.phase+' dead-end run '+r+' :: '+JSON.stringify(dump.ev)+' :: '+dump.html.replace(/\s+/g,' ').slice(0,900)); break;
    }
    if(s.phase==='shop'){
      if(s.cards.length && Math.random()<0.45){ await tap(s.cards[rnd(s.cards.length)]); continue; }
      if(s.go){ await tap(s.go); continue; }
      problems.push('shop dead-end run '+r); break;
    }
    if(s.phase!=='combat'){ problems.push('unknown phase '+s.phase+' run '+r); break; }

    const usable = s.dice.filter(d=>!d.blank);
    if(!usable.length){ if(!s.end){ problems.push('no END TURN run '+r); break; } await tap(s.end); continue; }
    const d = usable[rnd(usable.length)];

    if(Math.random()<0.5){
      /* tap the die, then tap a target if one is required */
      await tap(d);
      const s2 = await st();
      if(s2.sel!=null){
        if(!s2.tgts.length){ problems.push('SELECTED BUT NO TARGET run '+r+' face='+JSON.stringify(s2.selFace)); await p.keyboard.press('Escape'); continue; }
        await tap(s2.tgts[rnd(s2.tgts.length)]);
        const s3 = await st();
        if(s3.sel!=null && s3.dice.length===s.dice.length){
          problems.push('TARGET CLICK DID NOTHING run '+r+' face='+JSON.stringify(s2.selFace));
          await p.keyboard.press('Escape');
        }
      }
    } else {
      /* drag the die onto a target */
      await p.mouse.move(d.x,d.y); await p.mouse.down(); await p.mouse.move(d.x+14,d.y-14,{steps:3});
      const s2 = await st();
      const t = s2.tgts.length ? s2.tgts[rnd(s2.tgts.length)] : {x:d.x, y:d.y-160};
      await p.mouse.move(t.x,t.y,{steps:6}); await p.waitForTimeout(20); await p.mouse.up(); await p.waitForTimeout(60);
      const s3 = await st();
      if(s3.dice.length===s.dice.length && s3.sel!=null){
        problems.push('DRAG DID NOTHING run '+r+' face='+JSON.stringify(s2.selFace));
        await p.keyboard.press('Escape');
      }
    }
  }
}

console.log('--- mouse soak done, problems:', problems.length + errs.length);
const uniq=new Map();
for(const e of [...problems,...errs]){ const k=e.split('\n').slice(0,3).join('\n'); uniq.set(k,(uniq.get(k)||0)+1); }
for(const [k,n] of [...uniq.entries()].sort((a,b)=>b[1]-a[1])) console.log('['+n+'x] '+k+'\n');
await b.close();
