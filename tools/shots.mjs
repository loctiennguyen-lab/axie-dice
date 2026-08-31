import { chromium } from 'playwright';
const b = await chromium.launch({executablePath:'/opt/pw-browsers/chromium',args:['--no-sandbox']});
const p = await b.newPage({viewport:{width:1440,height:900},deviceScaleFactor:1.5});
p.on('pageerror',e=>console.log('PAGEERROR',e.message));
p.on('console',m=>{if(m.type()==='error')console.log('CONSOLE',m.text())});
await p.goto('file:///home/claude/axie-dice/AxieDiceTactics.html');
await p.waitForTimeout(400);
const shot = async (n)=>{ await p.waitForTimeout(500); await p.screenshot({path:'ui_'+n+'.png'}); console.log('shot',n); };

await p.evaluate(()=>{ try{localStorage.clear()}catch(e){}
  loadMeta(); META.unlocks=UNLOCKS.map(u=>u.id); META.shards=999; META.runs=12; META.wins=1; META.best=15; META.ascMax=3; META.xp=900; META.tut=1;
  saveMeta(); screen='menu'; render(); });
await shot('menu');

await p.evaluate(()=>{ screen='team'; teamPick=['plant1','beast1','aqua1']; render(); });
await shot('team');

await p.evaluate(()=>{ teamPick=['plant1','beast1','aqua1','reptile1','bug1']; pickMode='short'; pickAsc=2; pickSeed='ui';
  startRun(); tut=0; render(); });
await shot('map');

await p.evaluate(()=>{ const i=S.nodes.findIndex(n=>['battle','elite','boss'].includes(n.type)); chooseNode(S,i<0?0:i);
  S.relics=['r_venomfang','r_ironshell','a_bolt']; S.mana=6; render(); });
await shot('combat');

await p.evaluate(()=>{ const u=S.party.find(x=>!x.used&&x.rolled>=0); if(u){ sel=u.uid; } render(); });
await shot('combat_target');

await p.evaluate(()=>{ sel=null; modal='info'; infoTab='party'; render(); });
await shot('info');
await p.evaluate(()=>{ modal='unit'; modalUid=S.enemies[0].uid; render(); });
await shot('unitinfo');
await p.evaluate(()=>{ modal=null; render(); });

await p.evaluate(()=>{ modal=null; S.enemies.forEach(e=>e.hp=0); checkEnd(S); render(); });
await shot('reward');

await p.evaluate(()=>{ screen='codex'; modal=null; render(); });
await shot('codex');
await p.evaluate(()=>{ screen='bp'; render(); });
await shot('bp');
await p.evaluate(()=>{ screen='guide'; render(); });
await shot('guide');
await p.evaluate(()=>{ screen='unlocks'; render(); });
await shot('unlocks');
await p.evaluate(()=>{ screen='menu'; modal=null; railOpen='left'; render(); });
await shot('menu_rail');
await b.close();
