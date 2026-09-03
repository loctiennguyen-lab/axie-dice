import { chromium } from 'playwright';
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';
const b = await chromium.launch({args:['--no-sandbox']});
for(const vp of [{width:1440,height:900},{width:1280,height:720},{width:1920,height:1080},{width:1366,height:768}]){
  const p = await b.newPage({viewport:vp});
  p.on('pageerror',e=>console.log('  PAGEERROR',e.message));
  await p.goto(pathToFileURL(resolve(process.cwd(), 'AxieDiceTactics.html')).href);
  await p.waitForTimeout(300);
  await p.evaluate(()=>{
    try{localStorage.clear()}catch(e){}
    loadMeta(); META.unlocks=UNLOCKS.map(u=>u.id); saveMeta();
    teamPick=['plant1','beast1','aqua1','reptile1','bug1']; pickMode='short'; pickAsc=0; pickSeed='fit';
    startRun(); tut=0;
    if(S.phase==='map'&&S.nodes){ const i=S.nodes.findIndex(n=>['battle','elite','boss'].includes(n.type)); chooseNode(S, i<0?0:i); }
    render();
  });
  await p.waitForTimeout(600);
  const r = await p.evaluate(()=>{
    const bb=document.querySelector('.bottombar'), tr=document.querySelector('.tray');
    const rb=bb&&bb.getBoundingClientRect(), rt=tr&&tr.getBoundingClientRect();
    return {zoom:document.querySelector('#app').style.zoom||'1',
      docH:document.documentElement.scrollHeight, winH:window.innerHeight,
      bottombarBottom: rb?Math.round(rb.bottom):null, trayBottom: rt?Math.round(rt.bottom):null,
      enemies:S.enemies.length};
  });
  const ok = r.bottombarBottom!=null && r.bottombarBottom <= r.winH+1;
  console.log(`${vp.width}x${vp.height}  zoom=${r.zoom}  doc=${r.docH} win=${r.winH}  END TURN bottom=${r.bottombarBottom}  ${ok?'VISIBLE ok':'OFF SCREEN <-- BUG'}`);
  await p.close();
}
await b.close();
