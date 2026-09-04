/* t_relic_behaviour.mjs — BEHAVIOUR proofs for the 94-relic system.
   Complements tools/t_relic.mjs: that one proves the DESIGN invariants (RP bands, tags,
   coverage, field liveness); this one proves the CODE actually does the thing, by running
   the engine. Every check here exists because asserting "implemented" is not evidence.
     P1  INV-5 / AC-18 — modFace independent of relic PICKUP ORDER (with a control that
         shows the old path really did differ, so the test is known to touch the right code)
     P2  QĐ-3 bug 1 — shop price monotonic, rar 4 no longer cheaper than RARE
     P3  QĐ-3 bug 2 — actives can crit (a_ult defect) + ENG-14 passthrough
     P4  §3.6/§3.7 — relicConflict: mload cap, RELIC_CAP, ex de-duplication
     P5  relics FIRE and EMIT (ENG-4/5/7/10/11/18/19, THORNS_CAP, IRONMAIDEN_CAP)
     P6  §3.4 — faceArch reaches thorns and exec
     P7  §7 E7 — collectionGrandfathered migration, including the exact 43/44 boundary
   Run from the repo root: node tools/t_relic_behaviour.mjs */
import fs from 'fs'; import vm from 'vm';
const ctx={console,Math,JSON,Date}; vm.createContext(ctx);
const NAMES=['RELICS','RELIC_BY_ID','RELIC_INDEX','RELIC_SHOP_COST','RELIC_MLOAD_CAP','RELIC_CAP','THORNS_CAP',
 'IRONMAIDEN_CAP','GROWTH_KEEP_CAP','RELIC_COUNT_PRE_EXPANSION','ARCH','HEROES','FACE_POOL','BOSSES',
 'newGame','startCombat','buildUnit','relicConflict','relicPool','playerUseRelic','dealDamage','endTurn',
 'aliveP','aliveE','addStatus','faceArch','mkRng','rollAll','genShop','partyKeywords'];
vm.runInContext(['src/data.js','src/part_faces.js','src/engine.js'].map(f=>fs.readFileSync(f,'utf8')).join('\n')
  +';globalThis.__X={'+NAMES.map(n=>`${n}:(typeof ${n}==='undefined'?undefined:${n})`).join(',')+'};',ctx);
const G=ctx.__X;
let pass=0,fail=0;
const ok=(c,m,d)=>{ if(c){pass++;console.log('  PASS  '+m+(d?'   '+d:''));} else {fail++;console.log('  FAIL  '+m+(d?'   '+d:''));} };

console.log('\n=== P1 · INV-5 / AC-18 — modFace independent of PICKUP ORDER ===');
{
  const rng=G.mkRng(4242);
  const withMF=G.RELICS.filter(r=>r.modFace||r.modFace2).map(r=>r.id);
  const re={key:'plant1',muts:[],lv:1};
  const dieFor=(ids,useSorted)=>{
    const s={relics:ids.slice(),roster:[re]};
    if(!useSorted){ /* mô phỏng CODE CŨ: chạy modFace theo đúng thứ tự nhặt */
      const u=G.buildUnit(re,null);
      for(const id of ids){ const r=G.RELIC_BY_ID[id];
        if(r.modFace) r.modFace(u); if(r.modFace2) r.modFace2(u); }
      return JSON.stringify(u.die)+'|'+u.maxHp;
    }
    const u=G.buildUnit(re,s); return JSON.stringify(u.die)+'|'+u.maxHp;
  };
  let newDiff=0, oldDiff=0;
  for(let t=0;t<200;t++){
    const n=1+Math.floor(rng()*4), set=[];
    while(set.length<n){ const id=withMF[Math.floor(rng()*withMF.length)]; if(!set.includes(id)) set.push(id); }
    const perms=[set, set.slice().reverse(),
      set.slice().sort(()=>rng()-0.5), set.slice().sort(()=>rng()-0.5), set.slice().sort(()=>rng()-0.5)];
    const nb=new Set(perms.map(p=>dieFor(p,true)));  if(nb.size>1) newDiff++;
    const ob=new Set(perms.map(p=>dieFor(p,false))); if(ob.size>1) oldDiff++;
  }
  ok(oldDiff>=1,'control: PICKUP-ORDER path differs on at least 1 of 200 sets','differs on '+oldDiff+'/200 (test touches the right code path)');
  ok(newDiff===0,'AC-18: sorted path identical across 5 permutations','differs on '+newDiff+'/200');
  const s={relics:['r_claw','r_ancientgene'],roster:[re]}, s2={relics:['r_ancientgene','r_claw'],roster:[re]};
  const d1=G.buildUnit(re,s).die.map(f=>f.v).join(','), d2=G.buildUnit(re,s2).die.map(f=>f.v).join(',');
  ok(d1===d2,'BUG-3 FIXED: r_claw + r_ancientgene same both pickup orders','['+d1+'] vs ['+d2+']');
}

console.log('\n=== P2 · BUG-1 shop pricing: rar 4 no longer cheaper than RARE ===');
{
  const c=G.RELIC_SHOP_COST, mono=c.every((v,i)=>i===0||c[i-1]<v);
  ok(mono&&c.length===5,'RELIC_SHOP_COST strictly increasing over all 5 rarities','['+c.join(', ')+']');
  const oldCost=r=>[45,75,120,180][r]||60;
  ok(oldCost(4)<oldCost(1)&&c[4]>c[1],'observable: MYTHIC was '+oldCost(4)+' (< RARE '+oldCost(1)+'), now '+c[4]+' (> RARE '+c[1]+')');
}

console.log('\n=== P3 · BUG-2 a_ult / actives could never crit ===');
{
  const s=G.newGame(99,['beast1','plant1','aqua1'],{}); s.relics=[];
  G.startCombat(s,'normal');
  const e=G.aliveE(s)[0], u=G.aliveP(s)[0];
  /* đo qua event `hit` (giá trị TRƯỚC khi bị chặn bởi HP còn lại), không đo bằng hp delta */
  const dmgOf=(crit)=>{ e.hp=9999; e.maxHp=9999; e.shield=0; s.ev=[];
    G.dealDamage(s,u,e,20,{attack:true,crit}); const h=s.ev.filter(x=>x.t==='hit'&&x.uid===e.uid); return h.length?h[0].v:0; };
  const plain=dmgOf(false), crit=dmgOf(true);
  ok(crit>plain,'engine honours opts.crit on a non-face damage call (the a_ult defect)','plain '+plain+' vs crit '+crit);
  const src=fs.readFileSync('src/engine.js','utf8');
  ok(/kind==='ult'[\s\S]{0,220}crit:!!a\.crit/.test(src),"kind:'ult' now forwards a.crit (was hardcoded opts without crit)");
  ok(/kind==='dmg'[\s\S]{0,220}crit:!!a\.crit[\s\S]{0,40}exec:!!a\.exec/.test(src),"kind:'dmg' forwards a.crit and a.exec (ENG-14)");
  ok(G.RELIC_BY_ID['a_perfectstrike'].act.crit===1,'a_perfectstrike ships crit:1 and can now actually crit');
  ok(G.RELIC_BY_ID['a_ult'].a==='mana','a_ult retagged crit -> mana (§6.5) so tag and behaviour agree');
}

console.log('\n=== P4 · relicConflict — mload cap and ex de-duplication ===');
{
  const re={key:'plant1',muts:[],lv:1};
  const s={relics:['r_bloodpact'],roster:[re]};                 /* mload 2 = trần đã dùng hết */
  ok(G.relicConflict(s,G.RELIC_BY_ID['r_ancientgene'])===true,'mload 2 + mload 2 refused (cap '+G.RELIC_MLOAD_CAP+')');
  ok(G.relicConflict(s,G.RELIC_BY_ID['r_luckycharm'])===true,'mload 2 + mload 1 refused');
  ok(G.relicConflict(s,G.RELIC_BY_ID['r_claw'])===false,'mload 2 + mload 0 allowed');
  const s2={relics:['r_luckycharm'],roster:[re]};               /* ex ['critChance'] */
  ok(G.relicConflict(s2,G.RELIC_BY_ID['r_apexpredator'])===true,'duplicate ex token critChance refused (r_luckycharm -> r_apexpredator)');
  const s3={relics:['r_spines'],roster:[re]};
  ok(G.relicConflict(s3,G.RELIC_BY_ID['r_glassspine'])===false,'thornsFloorFlat vs thornsFloorShield are different rules, both allowed');
  const s4={relics:[],roster:[re]};
  ok(G.relicPool(s4,3).length>0 && G.relicPool(s4,3).every(r=>!G.relicConflict(s4,r)),'relicPool only offers non-conflicting relics','pool '+G.relicPool(s4,3).length);
  const full={relics:G.RELICS.filter(r=>!r.mload).slice(0,G.RELIC_CAP).map(r=>r.id),roster:[re]};
  ok(G.relicPool(full,3).length===0,'RELIC_CAP '+G.RELIC_CAP+' reached -> pool empty (mkReward falls back)');
}

console.log('\n=== P5 · relics actually FIRE, and emit events ===');
{
  const mk=(relics,hero)=>{ const s=G.newGame(7,[hero||'plant1','plant1','aqua1'],{});
    s.relics=relics.slice(); G.startCombat(s,'normal'); return s; };
  const s1=mk(['r_ironmaiden']); const e=G.aliveE(s1)[0];
  G.aliveP(s1).forEach(u=>{u.st.thorns=9;});
  const before=G.aliveE(s1).reduce((a,x)=>a+x.hp,0);
  G.RELIC_BY_ID['r_ironmaiden'].onTurnStart(s1);
  const after=G.aliveE(s1).reduce((a,x)=>a+x.hp,0);
  ok(before-after===G.IRONMAIDEN_CAP,'r_ironmaiden fires, capped at IRONMAIDEN_CAP','dealt '+(before-after));
  const u=G.aliveP(s1)[0]; const thBefore=u.st.thorns; G.addStatus(s1,u,['thorns:99']);
  ok(u.st.thorns===G.THORNS_CAP,'THORNS_CAP holds: thorns never decays, so without a cap it is unbounded',
     thBefore+' + 99 -> '+u.st.thorns+' (cap '+G.THORNS_CAP+')');
  const s2=mk(['r_bloodthorn']); const p=G.aliveP(s2)[0];
  p.st.thorns=6; p.hp=Math.max(2,p.maxHp-30); p.shield=0; const h0=p.hp;
  G.dealDamage(s2,G.aliveE(s2)[0],p,5,{attack:true});
  ok(p.hp>h0-5,'r_bloodthorn onDmgTaken (ENG-19) heals a third of own Thorns','hp '+h0+' -> '+p.hp+' after a 5 hit');
  const s3=mk(['r_seedling']); const p3=G.aliveP(s3)[0]; const g0=JSON.stringify(p3.growth);
  G.endTurn(s3);
  ok(JSON.stringify(G.aliveP(s3)[0]?G.aliveP(s3)[0].growth:{})!==g0,'r_seedling growthAll (ENG-18/G1) grows the whole die each turn',
     'growth '+g0+' -> '+JSON.stringify(G.aliveP(s3)[0]?G.aliveP(s3)[0].growth:{}));
  ok(s3.ev.some(x=>x.t==='relic'),"event stream carries the new t:'relic' event so fx.js can animate it",
     'relic events: '+s3.ev.filter(x=>x.t==='relic').length);
  const s4=mk(['a_bramblewall']); s4.mana=10;
  const before4=G.aliveP(s4).map(x=>x.st.thorns||0);
  const used=G.playerUseRelic(s4,'a_bramblewall',null);
  ok(used&&G.aliveP(s4).every(x=>(x.st.thorns||0)>=5),"a_bramblewall kind:'kw' (ENG-10) raises every Axie to Thorns 5",
     JSON.stringify(before4)+' -> '+JSON.stringify(G.aliveP(s4).map(x=>x.st.thorns||0)));
  const s5=mk(['a_bloom']); s5.mana=10;
  const rolledIdx=G.aliveP(s5)[0].rolled, gb=(G.aliveP(s5)[0].growth[rolledIdx]||0);
  const used5=G.playerUseRelic(s5,'a_bloom',null);
  ok(used5&&(G.aliveP(s5)[0].growth[rolledIdx]||0)===gb+3,"a_bloom kind:'grow' (ENG-11) implemented — no longer eats mana and does nothing",
     'growth '+gb+' -> '+(G.aliveP(s5)[0].growth[rolledIdx]||0));
  const s6=mk(['r_claw']); s6.mana=10;
  ok(G.playerUseRelic(s6,'r_claw',null)===false,'unknown/absent act rejected before mana is spent (else-branch added)');
}

console.log('\n=== P6 · faceArch reaches thorns and exec (§3.4) ===');
{
  const seen={}; for(const f of G.FACE_POOL){ const a=G.faceArch(f); seen[a]=(seen[a]||0)+1; }
  ok((seen.thorns||0)>0,'faceArch returns thorns — AEGIS finally has faces that feed it','thorns faces: '+(seen.thorns||0));
  ok((seen.exec||0)>0,'faceArch returns exec — FERAL/Beast finally feeds an archetype','exec faces: '+(seen.exec||0));
  ok(G.ARCH.exec&&Object.keys(G.ARCH).length===11,'ARCH has 11 archetypes incl. exec');
  const ics=Object.values(G.ARCH).map(a=>a.ic);
  ok(new Set(ics).size===ics.length,'every ARCH icon unique','['+ics.join(' ')+']');
}

console.log('\n=== P7 · collectionGrandfathered migration (§7 E7) ===');
{
  /* ui.js was folded into src/client.html by main's a206b12 client refactor; the
     migrateMeta()/collectionComplete() source these proofs assert on moved verbatim. */
  const uiSrc=fs.readFileSync('src/client.html','utf8');
  const DEF={faces:[],relics:[],bosses:[],collectionGrandfathered:false};
  const mkMeta=o=>({...DEF,...o});
  let META;
  const migrateMeta=()=>{ if(!META.collectionGrandfathered&&(META.relics||[]).length>=G.RELIC_COUNT_PRE_EXPANSION) META.collectionGrandfathered=true; };
  const complete=()=>META.collectionGrandfathered
    ||(META.faces.length>=G.FACE_POOL.length&&META.relics.length>=G.RELICS.length&&META.bosses.length>=Object.keys(G.BOSSES).length);
  ok(/function migrateMeta\(\)/.test(uiSrc)&&/if\(META\.collectionGrandfathered\) return true;/.test(uiSrc),
     'src/client.html ships migrateMeta() and collectionComplete() honours the flag');
  ok(/loadMeta\(\)\{[\s\S]{0,200}migrateMeta\(\);/.test(uiSrc),'migrateMeta() runs on local save load');
  ok((uiSrc.match(/migrateMeta\(\); saveMeta\(\);/g)||[]).length===2,'migrateMeta() also runs on both server-meta load paths');
  /* người chơi CŨ đã 44/44 relic + full faces/bosses */
  META=mkMeta({relics:G.RELICS.slice(0,44).map(r=>r.id),
               faces:G.FACE_POOL.map((_,i)=>i), bosses:Object.keys(G.BOSSES)});
  const preMigrate=(META.relics.length>=G.RELICS.length);
  migrateMeta();
  ok(preMigrate===false,'without the flag a 44/44 veteran would read as INCOMPLETE at 94 relics (the reward being revoked)');
  ok(META.collectionGrandfathered===true&&complete()===true,'44/44 veteran is grandfathered — Echo Box NOT revoked',
     META.relics.length+'/'+G.RELICS.length+' relics, complete='+complete());
  /* người chơi MỚI không được tặng không */
  META=mkMeta({relics:G.RELICS.slice(0,10).map(r=>r.id)}); migrateMeta();
  ok(META.collectionGrandfathered===false&&complete()===false,'new player at 10/94 is NOT grandfathered');
  /* 43/44 — ngay dưới mốc */
  META=mkMeta({relics:G.RELICS.slice(0,43).map(r=>r.id)}); migrateMeta();
  ok(META.collectionGrandfathered===false,'43 relics (one short of the old roster) is NOT grandfathered — boundary is exact');
  /* cờ một chiều, bền qua load lại */
  META=mkMeta({relics:G.RELICS.slice(0,44).map(r=>r.id)}); migrateMeta();
  const saved=JSON.parse(JSON.stringify(META)); META=mkMeta(saved); migrateMeta();
  ok(META.collectionGrandfathered===true,'flag survives a save/load round-trip (one-way, never revoked)');
  ok(G.RELIC_COUNT_PRE_EXPANSION===44&&!/RELIC_COUNT_PRE_EXPANSION\s*=\s*RELICS\.length/.test(fs.readFileSync('src/data.js','utf8')),
     'RELIC_COUNT_PRE_EXPANSION is a hard 44, not RELICS.length (which already moved)');
}

console.log('\n'+(fail?`${fail} FAILED, ${pass} passed`:`ALL ${pass} PROOFS PASS`));
process.exit(fail?1:0);
