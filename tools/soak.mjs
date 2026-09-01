/* Soak test: plays full runs by clicking real DOM elements, captures every error. */
import { chromium } from 'playwright';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const FILE = process.argv[2] || 'AxieDiceTactics.html';
const RUNS = +(process.argv[3] || 40);
const MAXMETA = process.argv[4]==='max';

const __dir = dirname(fileURLToPath(import.meta.url));
const buildFile = FILE.startsWith('http') ? FILE : 'file:' + join(__dir, '..', 'build', 'index.html');

const b = await chromium.launch({args:['--no-sandbox']});
const p = await b.newPage({ viewport:{width:1600,height:1000} });
const errs = [];
p.on('pageerror', e => errs.push('PAGEERROR: ' + (e.stack||e.message)));
p.on('console', m => { if(m.type()==='error') errs.push('CONSOLE: '+m.text()); });
await p.goto(buildFile);
await p.waitForTimeout(500);

const report = await p.evaluate(async ({RUNS,MAXMETA}) => {
  const log = [];
  const sleep = ms => new Promise(r=>setTimeout(r,ms));
  const rnd = n => Math.floor(Math.random()*n);
  const errors = [];
  window.addEventListener('unhandledrejection', ev =>
    errors.push('UNHANDLED: ' + (ev.reason && (ev.reason.stack||ev.reason.message) || ev.reason)));
  const oldErr = window.onerror;
  window.onerror = (m,s,l,c,e)=>{ errors.push('ONERROR: '+(e&&e.stack||m)); if(oldErr) oldErr(m,s,l,c,e); };

  SPD = 8;                       /* fast-forward animations */
  const T1KEYS = ['plant1','beast1','aqua1','reptile1','bug1','bird1'];
  const stats = {runs:0, wins:0, losses:0, stalls:0, waves:[], maxWave:0};

  async function settle(){
    for(let i=0;i<400;i++){ if(!playing && !rollAnim) return true; await sleep(10); }
    return false;              /* stuck: playing/rollAnim never cleared */
  }

  for(let r=0;r<RUNS;r++){
    try{ localStorage.clear(); }catch(e){}
    loadMeta();
    if(MAXMETA){
      META.unlocks = UNLOCKS.map(u=>u.id);
      META.bpFaces = Object.keys(BP_FACES);
      META.perks = {reroll:2,hp4:2,relic0:1,relic1:1,rrw:2};
      META.shards = 9999; META.ascMax = 10;
      saveMeta();
    }
    teamPick = Array.from({length:5},()=>T1KEYS[rnd(6)]);
    pickMode = MAXMETA ? (r%2?'full':'short') : (r%4===3 ? 'full' : 'short');
    pickAsc  = MAXMETA ? (r%11) : (r%5); pickSeed = 'soak'+r;
    modal=null; sel=null; selRelic=null;
    startRun(); tut=0; render();
    stats.runs++;

    let guard = 0, lastSig = '', sameCount = 0;
    while(guard++ < 4000){
      if(!await settle()){ errors.push('STALL: playing stuck, run '+r+' wave '+S.step); stats.stalls++; break; }
      if(S.phase==='won'){ stats.wins++; break; }
      if(S.phase==='lost'){ stats.losses++; break; }
      stats.maxWave = Math.max(stats.maxWave, S.step);

      /* progress watchdog: detect a screen that accepts no input */
      const sig = S.phase+'|'+S.step+'|'+S.turn+'|'+S.party.filter(u=>u.used).length+'|'+S.enemies.length;
      if(sig===lastSig){ if(++sameCount>25){ errors.push('NOPROGRESS: '+sig+' run '+r); stats.stalls++; break; } }
      else { sameCount=0; lastSig=sig; }

      const click = selq => { const n=document.querySelector(selq); if(!n) return false; n.click(); return true; };

      if(S.phase==='map'){
        const nodes=[...document.querySelectorAll('.nodecard')];
        if(!nodes.length){ errors.push('MAP: no node cards, run '+r); break; }
        nodes[rnd(nodes.length)].click(); await sleep(20); continue;
      }
      if(S.phase==='reward'){
        const cards=[...document.querySelectorAll('.rcard')].filter(c=>!c.classList.contains('dis'));
        if(!cards.length){ errors.push('REWARD: no cards, run '+r); break; }
        cards[rnd(cards.length)].click(); await sleep(20); continue;
      }
      if(S.phase==='event'){
        if(!click('.evopt') && !click('.btn.go')){ errors.push('EVENT: no option, run '+r); break; }
        await sleep(20); continue;
      }
      if(S.phase==='shop'){
        const buys=[...document.querySelectorAll('.shopitem')].filter(c=>!c.classList.contains('dis')&&!c.classList.contains('sold'));
        if(buys.length && Math.random()<0.5){ buys[rnd(buys.length)].click(); await sleep(20); continue; }
        if(!click('.btn.go')){ errors.push('SHOP: no leave button, run '+r); break; }
        await sleep(20); continue;
      }
      if(S.phase!=='combat'){ errors.push('PHASE: unknown "'+S.phase+'" run '+r); break; }

      /* combat: use one die, or end turn */
      const dice=[...document.querySelectorAll('.diebox .die:not(.used):not(.out):not(.blank)')];
      if(!dice.length){
        const eb=document.querySelector('.btn.end');
        if(!eb){ errors.push('COMBAT: no END TURN button, run '+r); break; }
        eb.click(); await sleep(20); continue;
      }
      const d = dice[rnd(dice.length)];
      d.click(); await sleep(15);
      /* if it needed a target, one must now be highlighted */
      if(sel!=null){
        const tg=[...document.querySelectorAll('.unit.tgt')];
        if(!tg.length){
          const u=byUid(S,sel);
          errors.push('NOTARGET: face '+JSON.stringify(u&&u.die[u.rolled])+' run '+r+' wave '+S.step);
          sel=null; render(); continue;
        }
        tg[rnd(tg.length)].click(); await sleep(15);
      }
      /* occasionally reroll */
      if(Math.random()<0.15){ const rb=document.querySelector('.btn.reroll'); if(rb&&!rb.classList.contains('dis')) rb.click(); await sleep(15); }
    }
    if(guard>=4000) errors.push('GUARD: run '+r+' exceeded step budget');
    stats.waves.push(S.step);
  }
  return {errors, stats, log};
}, {RUNS,MAXMETA});

console.log('runs=%d wins=%d losses=%d stalls=%d maxWave=%d',
  report.stats.runs, report.stats.wins, report.stats.losses, report.stats.stalls, report.stats.maxWave);
const all = [...report.errors, ...errs];
const uniq = new Map();
for(const e of all){ const k=e.split('\n').slice(0,3).join('\n'); uniq.set(k,(uniq.get(k)||0)+1); }
console.log('--- distinct problems:', uniq.size, '---');
for(const [k,n] of [...uniq.entries()].sort((a,b)=>b[1]-a[1])) console.log('['+n+'x] '+k+'\n');
await b.close();
process.exit(uniq.size?1:0);
