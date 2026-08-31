import { chromium } from 'playwright';
const file = process.argv[2] || 'AxieDiceTactics.html';
const b = await chromium.launch({executablePath:'/opt/pw-browsers/chromium',args:['--no-sandbox']});
const p = await b.newPage({ viewport:{width:1600,height:1000} });
p.on('pageerror', e=>console.log('PAGEERROR', e.message));
await p.goto('file:///home/claude/axie-dice/'+file);
await p.waitForTimeout(400);

// start a run through the API the menu uses
await p.evaluate(()=>{
  localStorage.clear();
  teamPick=['plant1','plant1','beast1','bug1','aqua1'];
  pickMode='short'; pickAsc=0; pickSeed='';
  startRun(); tut=0;
  if(S.phase==='map'&&S.nodes) chooseNode(S,0);
  render();
});
await p.waitForTimeout(200);
console.log('phase=',await p.evaluate(()=>S.phase+' party='+S.party.length));
await p.waitForTimeout(300);

async function trial(kind){
  // force unit 0's rolled face to a non-targeting face
  const info = await p.evaluate((kind)=>{
    const u=S.party[0];
    u.used=false; u.rolled=0;
    u.die[0] = kind==='aoe' ? F('tail','poison',4,'aoe')
             : kind==='mana' ? F('ears','mana',3,'cantrip')
             : F('mouth','dmg',5);
    sel=null; render();
    const d=document.querySelector('.diebox[data-uid="'+u.uid+'"] .die');
    const r=d.getBoundingClientRect();
    return {uid:u.uid, x:r.x+r.width/2, y:r.y+r.height/2, poisonBefore:S.enemies.map(e=>e.st.poison)};
  }, kind);
  // simulate a real mouse click (pointerdown -> pointerup, no movement)
  await p.mouse.move(info.x, info.y);
  await p.mouse.down();
  await p.waitForTimeout(60);
  await p.mouse.up();
  await p.waitForTimeout(600);
  const after = await p.evaluate(()=>({
    used:S.party[0].used,
    sel:typeof sel!=='undefined'?sel:null,
    poison:S.enemies.map(e=>e.st.poison),
    mana:S.mana
  }));
  console.log(kind.toUpperCase().padEnd(6), 'used='+after.used, 'sel='+after.sel,
              'poison='+JSON.stringify(after.poison), 'mana='+after.mana);
  return after.used;
}

const rAoe  = await trial('aoe');
const rMana = await trial('mana');
const rSng  = await trial('single');
console.log('---');
console.log('AoE face usable by mouse :', rAoe  ? 'YES' : 'NO  <-- BUG');
console.log('Mana face usable by mouse:', rMana ? 'YES' : 'NO  <-- BUG');
console.log('Single-target selects    :', rSng===false ? 'ok (waits for target)' : 'unexpected');

/* regression: single-target face must still work by DRAG onto an enemy */
const drag = await (async()=>{
  const info = await p.evaluate(()=>{
    const u=S.party[1]; u.used=false; u.rolled=0; u.die[0]=F('mouth','dmg',5);
    sel=null; render();
    const d=document.querySelector('.diebox[data-uid="'+u.uid+'"] .die').getBoundingClientRect();
    return {uid:u.uid, x:d.x+d.width/2, y:d.y+d.height/2, hp:S.enemies[0].hp};
  });
  await p.mouse.move(info.x,info.y); await p.mouse.down();
  const e = await p.evaluate(()=>{ const n=document.querySelector('.unit.e.tgt')||document.querySelector('.unit.e');
    const r=n.getBoundingClientRect(); return {x:r.x+r.width/2,y:r.y+r.height/2}; });
  await p.mouse.move(e.x,e.y,{steps:8}); await p.mouse.up(); await p.waitForTimeout(700);
  const after = await p.evaluate(()=>({used:S.party[1].used, hp:S.enemies[0]?S.enemies[0].hp:0}));
  console.log('DRAG   single-target used='+after.used+' enemyHp '+info.hp+' -> '+after.hp);
  return after.used;
})();

/* regression: single-target face must still work by CLICK then CLICK target */
const clk = await (async()=>{
  const info = await p.evaluate(()=>{
    const u=S.party[2]; u.used=false; u.rolled=0; u.die[0]=F('mouth','dmg',5);
    sel=null; render();
    const d=document.querySelector('.diebox[data-uid="'+u.uid+'"] .die').getBoundingClientRect();
    return {x:d.x+d.width/2, y:d.y+d.height/2};
  });
  await p.mouse.click(info.x,info.y); await p.waitForTimeout(150);
  const e = await p.evaluate(()=>{ const n=document.querySelector('.unit.e.tgt');
    if(!n) return null; const r=n.getBoundingClientRect(); return {x:r.x+r.width/2,y:r.y+r.height/2}; });
  if(!e){ console.log('CLICK  no target highlighted <-- BUG'); return false; }
  await p.mouse.click(e.x,e.y); await p.waitForTimeout(700);
  const after = await p.evaluate(()=>S.party[2].used);
  console.log('CLICK  single-target used='+after);
  return after;
})();

/* summon face */
const sm = await (async()=>{
  const info = await p.evaluate(()=>{
    const u=S.party[3]; u.used=false; u.rolled=0; u.die[0]=F('back','summon',1);
    sel=null; render();
    const d=document.querySelector('.diebox[data-uid="'+u.uid+'"] .die').getBoundingClientRect();
    return {x:d.x+d.width/2,y:d.y+d.height/2, n:S.party.length};
  });
  await p.mouse.click(info.x,info.y); await p.waitForTimeout(700);
  const after=await p.evaluate(()=>({used:S.party[3].used,n:S.party.length}));
  console.log('SUMMON used='+after.used+' party '+info.n+' -> '+after.n);
  return after.used;
})();

console.log('---');
console.log(drag&&clk&&sm ? 'ALL REGRESSION CHECKS PASS' : 'REGRESSION FAILURE');
await b.close();
