/* ============ COMBAT LOG (T15) ============
   design/ux/combat-log.md — second, display-only consumer of the same
   engine event stream fx.js plays back (S.ev / EV()). This module never
   mutates S and never touches engine.js; it only compiles already-emitted
   events into short, human-readable lines and renders them into a panel
   that lives outside the #app tree (so ui.js's full-teardown render()
   never unmounts it — see clogInit()).

   Compiled-line mapping: design/ux/combat-log.md §Detailed Rules —
   Information Architecture. Any deviation from that table is called out
   in a comment at the point of the deviation. */

const CLOG_KEY='axiedice_logopen_v1';
let clogOpen=false;
let clogEntries=[];          /* newest-first compiled entries */
/* Run-scoped accumulator (Match History — design/gdd unwritten as of this
   change, see ui.js saveRunHistory()). Unlike clogEntries (wiped every
   clogReset(), i.e. every new wave — T15 "current combat only"), this holds
   the FULL run's compiled log across every wave.
   Entries pushed here are the SAME object references pushed into
   clogEntries, not snapshots: clogRefreshDom()/clogHandleFt()/clogHandle()
   keep mutating an entry's `.segs`/`.actor`/`.part`/`.tgt` in place as a
   `use` -> `hit`/`ft` -> ... sequence resolves. A snapshot taken at
   push-time (clogCreateEntry) would freeze mid-action — e.g. missing the
   part name on a still-provisional `eact` entry, or a later "(N blocked by
   Shield)" suffix appended after the fact. Sharing the reference means this
   accumulator always reflects each entry's FINAL state by the time a run
   ends and ui.js's onRunEnd() reads it — which is the only point that
   matters, since runLogEntries is never rendered live itself.
   The `.node` DOM reference these entries pick up (assigned in
   clogCreateEntry/clogRefreshDom) is stripped EXPLICITLY by ui.js's
   saveRunHistory() right before JSON.stringify — never rely on
   JSON.stringify to drop it implicitly (a DOM node's ancestor chain isn't
   even guaranteed to throw a clean circular-reference error). */
let runLogEntries=[];
/* Cap: a full 20-wave run generates comfortably under a thousand compiled
   lines in practice; 1500 mirrors the "generous vs. realistic, blocks
   unbounded growth" reasoning already used for MAX_ACTIONS in
   api/submit-run.js and the clogEntries.length>400 cap just below. Oldest
   entries are dropped first (FIFO, via shift()) so the TAIL of the run —
   what a player actually wants to relive, especially the final blow — is
   never the part that gets truncated. */
const RUN_LOG_CAP=1500;
/* Called from ui.js's startRun() — a NEW RUN boundary, not a new wave.
   Deliberately separate from clogReset() (which runs every wave and must
   keep leaving this accumulator untouched). */
function clogRunReset(){ runLogEntries=[]; }
let clogSeq=1;
let clogTurnNo=1;
let clogOpenEntry=null;      /* entry currently accumulating hit/ft segments */
let clogPendingShield=null;  /* {uid,seg} — last hit segment eligible for a "(N blocked by Shield)" suffix */
let clogFrozen=false;
let clogAtTop=true;
let clogUnseen=0;
let clogSRQueue=[];
let clogSRTimer=null;
let clogPanel=null, clogBody=null, clogSR=null, clogScrim=null, clogUnreadEl=null;

function clogLoadPref(){ try{ clogOpen=localStorage.getItem(CLOG_KEY)==='1'; }catch(e){} }
function clogSavePref(){ try{ localStorage.setItem(CLOG_KEY,clogOpen?'1':'0'); }catch(e){} }

/* ---------- lifecycle ---------- */
function clogReset(){
  clogEntries=[]; clogOpenEntry=null; clogPendingShield=null; clogFrozen=false;
  clogTurnNo=1; clogAtTop=true; clogUnseen=0; clogSRQueue=[];
  if(clogSRTimer){ clearTimeout(clogSRTimer); clogSRTimer=null; }
  if(clogSR) clogSR.textContent='';
  if(clogBody){ clogBody.innerHTML=''; clogBody.scrollTop=0; }
  clogRenderUnread();
}
/* Defeat is the one case the log must survive into (design/ux/combat-log.md
   §Interaction: "Battle Report"). Freezing just means we stop compiling —
   nothing more will arrive from a combat that has already ended — and we
   force the panel open without touching the player's remembered preference
   (so their next combat still opens/closes the way they set it). */
function clogFreeze(){
  if(clogFrozen) return;
  clogCloseOpen();
  clogFrozen=true;
  clogSetOpen(true,false);
}

/* ---------- open/close panel ---------- */
function clogSetOpen(v,persist){
  clogOpen=!!v;
  if(persist!==false) clogSavePref();
  clogApplyOpenClass();
  if(clogOpen){ clogUnseen=0; clogRenderUnread(); }
}
function clogApplyOpenClass(){
  document.body.classList.toggle('clog-open',clogOpen);
}
function clogToggleBtn(){
  const b=btn('xs ghost'+(clogOpen?' on':''),'LOG',()=>{ SFX.ui(); clogSetOpen(!clogOpen); render(); });
  b.setAttribute('aria-pressed',clogOpen?'true':'false');
  b.title='Battle log — every action this combat, compiled (press L)';
  return b;
}

/* ---------- persistent DOM (created once; never unmounted by render()) ---------- */
function clogInit(){
  if(clogPanel) return;
  clogLoadPref();
  clogScrim=el('div','clog-scrim');
  clogScrim.onclick=()=>{ clogSetOpen(false); render(); };
  document.body.appendChild(clogScrim);

  /* .clog-panel is a fixed, viewport-bounded, overflow:hidden clipper — it
     never itself extends past the viewport edge. .clog-inner is what
     actually slides via transform. Sliding .clog-panel itself off-screen
     (translateX(100%) on a right:0;width:280px box) put its border box
     past the viewport edge, which some engines still count toward
     document.scrollWidth even though nothing is visible there — that
     regressed tools/verify.mjs's B2 (no-horizontal-overflow) check.
     Clipping at the outer, viewport-bounded box fixes it without changing
     the visual toggle mechanism (still opacity/transform, never unmounted). */
  clogPanel=el('div','clog-panel');
  const inner=el('div','clog-inner');
  const head=el('div','clog-head');
  head.appendChild(el('div','clog-title','BATTLE LOG'));
  head.appendChild(btn('xs ghost clog-close','CLOSE',()=>{ clogSetOpen(false); render(); }));
  inner.appendChild(head);

  const wrap=el('div','clog-bodywrap');
  clogUnreadEl=el('div','clog-unread');
  clogUnreadEl.onclick=()=>{ if(clogBody) clogBody.scrollTop=0; clogUnseen=0; clogAtTop=true; clogRenderUnread(); };
  wrap.appendChild(clogUnreadEl);

  clogBody=el('div','clog-body');
  /* role=log gives assistive tech a navigable landmark; aria-live is
     deliberately "off" here — the throttled announcer below (clogSR) is the
     ONLY live-region channel, per the spec's explicit anti-flood rule. See
     the ambiguity note in the implementation report: the spec text also
     says the visible container itself should be aria-live="polite", which
     would reintroduce the exact per-event flood the spec spends a whole
     section warning against. Resolved in favour of the anti-flood rule. */
  clogBody.setAttribute('role','log');
  clogBody.setAttribute('aria-live','off');
  clogBody.setAttribute('aria-label','Combat log');
  clogBody.addEventListener('scroll',()=>{
    const wasTop=clogAtTop; clogAtTop=clogBody.scrollTop<=2;
    if(clogAtTop&&!wasTop){ clogUnseen=0; clogRenderUnread(); }
  },{passive:true});
  wrap.appendChild(clogBody);
  inner.appendChild(wrap);
  clogPanel.appendChild(inner);
  document.body.appendChild(clogPanel);

  clogSR=el('div','sr-only clog-sr');
  clogSR.setAttribute('aria-live','polite');
  clogSR.setAttribute('aria-atomic','true');
  document.body.appendChild(clogSR);

  clogApplyOpenClass();
}
function clogRenderUnread(){
  if(!clogUnreadEl) return;
  clogUnreadEl.classList.toggle('on',clogUnseen>0&&!clogAtTop);
  clogUnreadEl.textContent='• '+clogUnseen+' new ▲';
}

/* ---------- screen-reader channel: batched, throttled ~400ms, always polite ---------- */
function clogQueueSR(sentence){
  if(!sentence) return;
  clogSRQueue.push(sentence);
  clogPumpSR();
}
function clogPumpSR(){
  if(clogSRTimer) return;
  if(!clogSRQueue.length) return;
  const batch=clogSRQueue.splice(0,clogSRQueue.length);
  if(clogSR) clogSR.textContent=batch.join('. ')+'.';
  clogSRTimer=setTimeout(()=>{ clogSRTimer=null; clogPumpSR(); },400);
}

/* ---------- raw-text -> plain language (buf/deb float text) ---------- */
const CLOG_STATUS_WORD={THO:'Thorns',REG:'Regen',BUR:'Burn',BLI:'Blind',WEA:'Weaken',VUL:'Vulnerable'};
const CLOG_STATUS_EXACT={STUN:'Stunned',STUNNED:'Stunned — turn wasted',FREEZE:'Frozen next turn',
  FROZEN:'Frozen this turn',ENRAGE:'Enraged (+25% damage)',UNDYING:'Undying',OVERDRIVE:'Overdrive',
  SUMMON:'Summoned an ally'};
function clogStatusPhrase(txt){
  if(CLOG_STATUS_EXACT[txt]) return CLOG_STATUS_EXACT[txt];
  const m=/^([A-Z]{3})(\d+)$/.exec(txt);
  if(m&&CLOG_STATUS_WORD[m[1]]) return CLOG_STATUS_WORD[m[1]]+' +'+m[2];
  if(txt.indexOf('LINK')===0) return 'Formation Resonance '+txt.slice(4).trim();
  if(/^\+\d+ REROLL$/.test(txt)) return txt.charAt(0)+txt.slice(1).toLowerCase().replace('reroll','Reroll');
  return txt; /* unmapped status text: show it verbatim rather than drop it */
}

/* ---------- compiling ---------- */
function clogUnitName(uid){ const u=S&&byUid(S,uid); return u?u.n:('#'+uid); }
function clogOpenFromUse(e){
  const u=S&&byUid(S,e.uid);
  const rolled = u&&u.rolled>=0? u.die[u.rolled] : null;
  const part = (u&&u.side==='p'&&rolled) ? (rolled.name||PARTN[rolled.p]||rolled.p||null) : null;
  const faceT = rolled? rolled.t : null;
  let tgt;
  if(faceT==='mana'||faceT==='summon') tgt='self';
  else if(e.tgt==null) tgt=e.aoe?'all':'self';
  else tgt=clogUnitName(e.tgt);
  return {id:clogSeq++,kind:'line',actor:u?u.n:('#'+e.uid),part,tgt,uid:e.uid,segs:[],provisional:false};
}
function clogCloseOpen(){
  if(!clogOpenEntry) return;
  const e=clogOpenEntry; clogOpenEntry=null; clogPendingShield=null;
  if(e.provisional&&!e.segs.length) e.fallback=e.actor+' acts (no effect)';
  clogRefreshDom(e);
  clogQueueSR(clogEntryText(e));
}
function clogEnsureOpen(e,actorSide){
  if(clogOpenEntry) return;
  /* Orphan hit/ft: engine emitted damage/status with no open use/eact entry
     (status-tick damage after a `tick` boundary, or passive regen). The raw
     stream doesn't say *which* status caused it (dealDamage doesn't tag its
     caller), so rather than guess and risk mislabeling Burn as Poison (or
     vice versa) we attribute the line to the affected unit generically —
     see report for this flagged decision. */
  const name=clogUnitName(e.uid);
  clogOpenEntry={id:clogSeq++,kind:'line',actor:name,part:null,tgt:null,uid:e.uid,segs:[],provisional:false,orphan:true};
  clogCreateEntry(clogOpenEntry);
}
function clogHandle(e){
  if(clogFrozen) return;
  if(e.t==='eact'){
    clogCloseOpen();
    clogOpenEntry={id:clogSeq++,kind:'line',actor:clogUnitName(e.uid),part:null,tgt:null,uid:e.uid,segs:[],provisional:true};
    clogCreateEntry(clogOpenEntry);
  } else if(e.t==='use'){
    if(clogOpenEntry&&clogOpenEntry.provisional&&clogOpenEntry.uid===e.uid){
      const up=clogOpenFromUse(e);
      clogOpenEntry.actor=up.actor; clogOpenEntry.part=up.part; clogOpenEntry.tgt=up.tgt; clogOpenEntry.provisional=false;
      clogRefreshDom(clogOpenEntry);
    } else { clogCloseOpen(); clogOpenEntry=clogOpenFromUse(e); clogCreateEntry(clogOpenEntry); }
  } else if(e.t==='hit'){
    clogEnsureOpen(e);
    const seg={ic:'dmg',cls:'dmg',txt:(e.crit?'CRIT ':'')+e.v+' dmg'};
    clogOpenEntry.segs.push(seg);
    clogPendingShield={uid:e.uid,seg};
    clogRefreshDom(clogOpenEntry);
  } else if(e.t==='ft'){
    clogHandleFt(e);
  } else if(e.t==='death'){
    clogEnsureOpen(e);
    clogOpenEntry.segs.push({ic:null,cls:'dead',txt:clogUnitName(e.uid)+' ☠ defeated'});
    clogOpenEntry.deathTag=true;
    clogRefreshDom(clogOpenEntry);
  } else if(e.t==='phase'){
    clogCloseOpen();
    const e2={id:clogSeq++,kind:'ban',text:'⚡ '+clogUnitName(e.uid)+' enters Phase 2'};
    clogCreateEntry(e2); clogQueueSR(e2.text);
  } else if(e.t==='tick'){
    clogCloseOpen();
    clogTurnNo++;
    const d={id:clogSeq++,kind:'div',text:'— Turn '+clogTurnNo+' —'};
    clogCreateEntry(d);
  }
  /* 'hp' and 'resonance' are intentionally not compiled into their own line:
     'hp' is a bar-sync signal with no info the accompanying `ft` doesn't
     already carry (see report); 'resonance' is always paired with the
     `ft` LINK ×N line that clogStatusPhrase already renders. */
}
function clogHandleFt(e){
  if(e.cls==='dmg') return; /* folded into the `hit` line — hit.v is the source of truth */
  clogEnsureOpen(e);
  if(e.cls==='shd'){
    if(e.txt.charAt(0)==='-'){
      const amt=e.txt.slice(1);
      if(clogPendingShield&&clogPendingShield.uid===e.uid){
        clogPendingShield.seg.txt+=' ('+amt+' blocked by Shield)';
        clogPendingShield=null;
      } else clogOpenEntry.segs.push({ic:'shield',cls:'shd',txt:amt+' blocked by Shield'});
    } else clogOpenEntry.segs.push({ic:'shield',cls:'shd',txt:e.txt+' Shield'});
  } else if(e.cls==='heal'){
    clogOpenEntry.segs.push({ic:'heal',cls:'heal',txt:e.txt+' HP'});
  } else if(e.cls==='poi'){
    const m=/PSN (\d+)/.exec(e.txt);
    clogOpenEntry.segs.push({ic:'poison',cls:'poi',txt:'Poison +'+(m?m[1]:e.txt)});
  } else if(e.cls==='man'){
    clogOpenEntry.segs.push({ic:'mana',cls:'man',txt:e.txt.replace('MP','Mana')});
  } else if(e.cls==='buf'||e.cls==='deb'){
    clogOpenEntry.segs.push({ic:e.cls==='buf'?'buff':'debuff',cls:e.cls,txt:clogStatusPhrase(e.txt)});
  } else {
    clogOpenEntry.segs.push({ic:null,cls:null,txt:e.txt});
  }
  clogRefreshDom(clogOpenEntry);
}
function clogIngest(evs){
  if(!evs||!evs.length||clogFrozen) return;
  for(const e of evs) clogHandle(e);
}

/* ---------- rendering ---------- */
function clogEntryText(e){
  if(e.fallback) return e.fallback;
  let s=e.actor+(e.part?' ('+e.part+')':'')+(e.tgt&&e.tgt!=='self'?' to '+e.tgt:'');
  if(e.segs&&e.segs.length) s+=': '+e.segs.map(g=>g.txt).join(', ');
  return s;
}
function clogBuildNode(e){
  if(e.kind==='div') return el('div','clog-div',e.text);
  if(e.kind==='ban'){ const n=el('div','clog-ban'); n.textContent=e.text; return n; }
  const n=el('div','clog-entry'+(e.deathTag?' dead':''));
  const head=el('div','clog-line1');
  if(e.fallback) head.textContent=e.fallback;
  else {
    let t=e.actor+(e.part?' ('+e.part+')':'');
    if(e.tgt&&e.tgt!=='self') t+=' → '+e.tgt;
    head.textContent=t;
  }
  n.appendChild(head);
  if(!e.fallback&&e.segs&&e.segs.length){
    const body=el('div','clog-line2');
    e.segs.forEach((g,i)=>{
      if(i>0) body.appendChild(el('span','clog-dot','·'));
      const s=el('span','clog-seg'+(g.cls?' c-'+g.cls:''));
      if(g.ic) s.appendChild(ico(g.ic,'clog-ic'));
      s.appendChild(el('span',null,g.txt));
      body.appendChild(s);
    });
    n.appendChild(body);
  }
  return n;
}
/* Entries are pushed into clogEntries AND rendered the moment they're
   created (not deferred until closed) — the spec requires the log to
   "append synchronously and instantly", including the currently-in-progress
   action, not just fully-resolved ones. clogRefreshDom() then keeps that
   same DOM node in sync in place as more hit/ft/death segments arrive,
   without re-inserting or re-scrolling (it's already the newest/topmost). */
function clogCreateEntry(e){
  clogEntries.unshift(e);
  if(clogEntries.length>400){
    const dropped=clogEntries.splice(400);
    dropped.forEach(d=>{ if(d.node&&d.node.parentNode) d.node.parentNode.removeChild(d.node); });
  }
  /* Match History accumulator — see runLogEntries comment above. Pushed in
     chronological (oldest-first) order via push()/shift(), the opposite of
     clogEntries' newest-first unshift() above, because a saved run's log is
     read top-to-bottom like a story (see ui.js scHistory()), not like a
     live panel. */
  runLogEntries.push(e);
  if(runLogEntries.length>RUN_LOG_CAP) runLogEntries.shift();
  if(!clogBody) return;
  const atTop=clogBody.scrollTop<=2;
  e.node=clogBuildNode(e);
  clogBody.insertBefore(e.node,clogBody.firstChild);
  if(atTop){ clogBody.scrollTop=0; clogAtTop=true; }
  else { clogBody.scrollTop+=e.node.offsetHeight||0; clogUnseen++; clogAtTop=false; clogRenderUnread(); }
}
function clogRefreshDom(e){
  if(!e||!e.node||!e.node.parentNode) return;
  const fresh=clogBuildNode(e);
  e.node.parentNode.replaceChild(fresh,e.node);
  e.node=fresh;
}
