/* ============ AXIE DICE TACTICS v0.2 — UI ============ */
const $=q=>document.querySelector(q), $$=q=>[...document.querySelectorAll(q)];
const el=(t,c,x)=>{ const e=document.createElement(t); if(c)e.className=c; if(x!=null)e.textContent=x; return e; };
const btn=(c,x,fn)=>{ const b=el('button','btn '+(c||''),x); b.onclick=e=>{ SFX.ui(); fn(e); }; b.onmouseenter=()=>SFX.hover(); return b; };
/* Accessibility: make a non-<button> interactive element (div with .onclick)
   reachable and operable by keyboard alone. Only call this once the element's
   .onclick has actually been assigned to a real handler — never on a
   disabled/"dis" card, so Tab order only ever lands on things that do something. */
const kbAct=e2=>{ e2.tabIndex=0;
  e2.addEventListener('keydown',ev=>{ if((ev.key==='Enter'||ev.key===' ')&&typeof e2.onclick==='function'){ ev.preventDefault(); e2.onclick(ev); } });
  return e2; };

let S=null, screen='menu', sel=null, selRelic=null, teamPick=[], msg='', SPD=1, tut=0;
let rollAnim=null, pendFloats=[], hoverT=null;

/* ---------- META (localStorage, degrade gracefully) ---------- */
const MK='axiedice_meta_v2', RK='axiedice_run_v2';
const DEF_META={vol:0.28,mute:false,spd:1,shards:0,unlocks:[],ascMax:0,best:0,runs:0,wins:0,faces:[],relics:[],bosses:[],tut:0,
  xp:0,bpClaimed:[],bpFaces:[],perks:{},title:'',reduceFlash:false,vault:[],echoPoints:0,displayName:'',
  /* Echo Box cosmetics (economy-progression.md §10.3 amendment, 2026-09-02):
     titles/avatars/decor/backgrounds are now an owned COLLECTION, separately
     equipped, not a single last-write-wins field. `title`/`echoPoints` above
     are kept (dead but harmless) for the one-time migration in loadMeta(). */
  ownedTitles:[], ownedAvatars:[], ownedDecor:[], ownedBackgrounds:[],
  equipped:{title:'',avatar:'',decor:'',background:''},
  echoBoxesOpened:0, echoMigrated:false,
  /* Custom profile identity (Profile screen "CHANGE NAME"/"UPLOAD AVATAR"):
     first use of each is free, every use after costs Gene Shard — see
     RENAME_COST/REAVATAR_COST below. customAvatar is a downscaled data URL,
     kept even after switching back to a gacha avatar (avatarSource flips
     which one is displayed, never destroys the upload) so re-equipping it
     later is free. */
  customAvatar:'', avatarSource:'gacha', freeNameUsed:false, freeAvatarUsed:false,
  dupeCounts:{0:0,1:0,2:0,3:0,4:0},
  /* owner: which logged-in account's data currently occupies local storage on
     THIS device (lowercased username, '' = not yet claimed by any account —
     a brand-new device, or a fresh install). Without this, local META was
     compared/offered by savedAt alone regardless of who it actually belonged
     to, so logging into account B on a device that last had account A's
     progress would present A's data as "this device's progress" and could
     leak it into B's cloud save. See pullSyncAfterLogin()/doAuth() below —
     any account other than `owner` must never see a merge/keep-device
     choice, only ever the truth from its own cloud save. */
  owner:''};
let META={...DEF_META};
function loadMeta(){
  try{ const j=localStorage.getItem(MK); if(j) META={...DEF_META,...JSON.parse(j)}; }catch(e){}
  /* One-time Echo Box migration (economy-progression.md §10.3 amendment):
     carry the old deterministic echoPoints meter forward as echoBoxesOpened
     (same tier/glow-border math, see echoTier()) and, if the player already
     had an Echo tier title in the old single-slot META.title, preserve it in
     the new ownedTitles collection instead of silently losing it. Guarded so
     a brand-new account (echoPoints undefined pre-DEF_META, or 0 post-) never
     crashes — `!=null` also treats 0 as "set", which is harmless: it just
     migrates to echoBoxesOpened=0, identical to the default. */
  if(!META.echoMigrated){
    if(META.echoPoints!=null) META.echoBoxesOpened=META.echoPoints;
    if(META.title && typeof ECHO_TITLES!=='undefined' && ECHO_TITLES.includes(META.title)){
      if(!META.ownedTitles.includes(META.title)) META.ownedTitles.push(META.title);
      META.equipped.title=META.title;
    }
    META.echoMigrated=true;
    saveMeta();
  }
}
function saveMeta(){ META.savedAt=Date.now(); try{ localStorage.setItem(MK,JSON.stringify(META)); }catch(e){} scheduleSyncPush(); }

/* ---------- MATCH HISTORY (localStorage, degrade gracefully — same pattern
   as META above). Deliberately LOCAL-ONLY: unlike META, this is never pushed
   through scheduleSyncPush()/api/sync-save.js. This is a scope decision, not
   an oversight — do not "fix" it by wiring in server sync without discussing
   scope first. Reasoning: history is purely a player-facing "what happened"
   record (including a full battle log per run), not progression state that
   needs cross-device continuity, and syncing it would meaningfully grow the
   sync payload for no gameplay benefit. Could be a fast-follow later. */
const HK='axiedice_history_v1';
/* Cap on NUMBER OF RUNS kept, oldest evicted first. Reasoning (same class as
   MAX_META_BYTES in api/auth.js, applied locally): each run's log is already
   capped at RUN_LOG_CAP (1500 entries, src/log.js) so per-run size is
   bounded; 20 runs of that bounded size is comfortably inside a typical
   5-10MB localStorage quota even before considering that most entries are
   short strings, not binary data. */
const HISTORY_MAX_RUNS=20;
function loadHistory(){ try{ const j=localStorage.getItem(HK); if(j) return JSON.parse(j); }catch(e){} return []; }
function saveHistory(list){ try{ localStorage.setItem(HK,JSON.stringify(list)); }catch(e){} }

/* ---------- ACCOUNT SYNC (design/gdd/player-accounts.md, ADR-0002) ----------
   Entirely additive to guest play: no token in localStorage = no server calls,
   META/localStorage path is unchanged. Session token cached separately from META
   so logging out never touches local progress (GDD §3 Logout). */
const TK='axiedice_token_v1';
function loadToken(){ try{ return localStorage.getItem(TK)||null; }catch(e){ return null; } }
function saveToken(t){ try{ localStorage.setItem(TK,t); }catch(e){} }
function clearToken(){ try{ localStorage.removeItem(TK); }catch(e){} }
/* Session token isn't JWT-spec — just base64url(payload)+'.'+base64url(hmac). Decoding
   the payload client-side is display-only (whose name to show); the server is the only
   party that verifies the signature, so a tampered token here just shows a wrong name
   until the next authenticated call 401s and clears it. */
function tokenUsername(t){
  try{
    const payloadB64=String(t).split('.')[0];
    let s=payloadB64.replace(/-/g,'+').replace(/_/g,'/'); while(s.length%4)s+='=';
    const u=JSON.parse(atob(s)).u;
    return typeof u==='string'?u:null;
  }catch(e){ return null; }
}
let authToken=loadToken(), authUsername=authToken?tokenUsername(authToken):null;
let acctMode='login', acctUsername='', acctPassword='', acctState='idle', acctMsg='', acctConflict=null;
/* Login is mandatory (ADR-0002 Amendment, design/gdd/player-accounts.md §3 "App
   gate"): gateMsg is the neutral banner shown on the gate screen when a cached
   token turns out to be stale (401 on first authenticated call) — never a
   silent drop, per GDD Edge Cases "Cached token present but expired/invalid". */
let gateMsg='';

let syncPushTimer=null;
/* Debounced push (~5s after the last saveMeta()) — never blocks or throws on
   failure, same graceful-degrade philosophy as the leaderboard's stored:false. */
function scheduleSyncPush(){
  if(!authToken) return;
  if(syncPushTimer) clearTimeout(syncPushTimer);
  syncPushTimer=setTimeout(pushSync,5000);
}
/* Coarse run start/end signal for the admin dashboard (docs/architecture/
   telemetry-dashboard-design.md) — NOT anti-cheat, NOT the leaderboard replay
   log (see api/submit-run.js for that). Fire-and-forget: must never throw,
   block, or slow down gameplay if the network/server is unavailable, same
   graceful-degrade philosophy as pushSync() above. No-ops entirely when
   logged out (shouldn't happen post-ADR-0002, but never assume). */
function sendTelemetry(type, extra){
  if(!authToken) return;
  try{
    fetch('/api/telemetry',{method:'POST',headers:{'Content-Type':'application/json','Authorization':'Bearer '+authToken},
      body:JSON.stringify({type,...extra})}).catch(()=>{});
  }catch(e){}
}
async function pushSync(){
  if(!authToken) return;
  try{
    const r=await fetch('/api/sync-save',{method:'POST',headers:{'Content-Type':'application/json','Authorization':'Bearer '+authToken},body:JSON.stringify({meta:META})});
    // Same "first authenticated call 401s -> drop to gate" rule as pullSyncAfterLogin
    // below — the debounced push can just as easily be the call that first
    // discovers a stale/rotated token, and the GDD's edge case doesn't care which
    // code path found it (design/gdd/player-accounts.md §5 Edge Cases).
    if(r.status===401){ clearToken(); authToken=null; authUsername=null; screen='gate'; gateMsg='Session expired — please log in again.'; render(); }
  }catch(e){ /* offline/server error — silently degrade, gameplay is never blocked */ }
}
/* Pulls the cloud save and reconciles with local META (GDD §3 Login).
   Reconciliation by savedAt ONLY applies when local data is already owned
   by THIS account (META.owner===authUsername) — i.e. "did I make progress
   on this device since my last sync". If local data belongs to a different
   account (or no account yet — a fresh device), it is never compared or
   offered as a choice: that would leak one player's progress into another
   account's cloud save. In that case we just adopt the cloud save outright
   (or start clean at DEF_META if this account has no cloud save yet), then
   stamp ownership so the NEXT login on this device reasons correctly.
   navigateOnDone controls whether we jump back to the menu when this resolves
   without a conflict (true from the login form; false from the boot-time pull,
   which should leave the player wherever they already are). */
async function pullSyncAfterLogin(navigateOnDone){
  try{
    const r=await fetch('/api/sync-save',{headers:{'Authorization':'Bearer '+authToken}});
    if(r.status===401){ clearToken(); authToken=null; authUsername=null; screen='gate'; gateMsg='Session expired — please log in again.'; render(); return; }
    const data=await r.json();
    if(!data||typeof data!=='object'){ if(navigateOnDone) screen='menu'; render(); return; }
    const serverMeta=data.meta;
    const sameOwner=META.owner&&META.owner===authUsername;
    if(!serverMeta){
      // This account has never synced from any device yet.
      if(!sameOwner){ META={...DEF_META,owner:authUsername}; } else { META.owner=authUsername; }
      saveMeta();
      if(navigateOnDone) screen='menu'; render(); return;
    }
    if(!sameOwner){
      // Local data (if any) isn't this account's — never prompt, just adopt the cloud truth.
      META={...DEF_META,...serverMeta,owner:authUsername}; saveMeta();
      if(navigateOnDone) screen='menu'; render(); return;
    }
    const localSavedAt=META.savedAt||0, serverSavedAt=serverMeta.savedAt||0;
    if(localSavedAt>serverSavedAt){
      acctConflict={server:serverMeta}; screen='account'; render(); return;
    }
    META={...DEF_META,...serverMeta,owner:authUsername}; saveMeta();
    if(navigateOnDone) screen='menu'; render();
  }catch(e){ if(navigateOnDone) screen='menu'; render(); }
}
async function doAuth(action){
  if(acctState==='busy') return;
  const u=(acctUsername||'').trim().toLowerCase();
  if(!/^[a-z0-9_]{3,20}$/.test(u)){ acctState='error'; acctMsg='Username must be 3-20 characters: a-z, 0-9, _ only.'; render(); return; }
  if((acctPassword||'').length<8){ acctState='error'; acctMsg='Password must be at least 8 characters.'; render(); return; }
  acctState='busy'; acctMsg=''; render();
  try{
    // Only offer local META as the new account's starting cloud save when this
    // device's local data is actually unclaimed (fresh device) or already this
    // same username's — never hand a brand-new account someone else's leftover
    // local progress just because they happen to share a device (see the
    // ownership comment on DEF_META/pullSyncAfterLogin above).
    const localIsForeign=action==='register'&&META.owner&&META.owner!==u;
    const body={action, username:u, password:acctPassword};
    if(action==='register') body.meta=localIsForeign?DEF_META:META;
    const r=await fetch('/api/auth',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
    const data=await r.json();
    if(!data.ok){ acctState='error'; acctMsg=data.error||'Something went wrong.'; render(); return; }
    authToken=data.token; saveToken(authToken); authUsername=data.username||u;
    acctPassword=''; acctState='idle';
    if(action==='register'){
      // Registration already uploaded the right starting META server-side
      // (see localIsForeign above) — mirror that choice locally, stamp
      // ownership, then let debounced sync take over from here.
      if(localIsForeign) META={...DEF_META};
      META.owner=authUsername; saveMeta(); screen='menu'; render(); return;
    }
    await pullSyncAfterLogin(true);
  }catch(e){ acctState='error'; acctMsg='Network error — could not reach the server. Try again.'; render(); }
}
function doLogout(){
  clearToken(); authToken=null; authUsername=null;
  if(syncPushTimer){ clearTimeout(syncPushTimer); syncPushTimer=null; }
  // Login is mandatory (GDD §3 Logout) — there's nowhere else for a logged-out
  // session to land but the gate. Local META is left untouched (not wiped).
  gateMsg=''; screen='gate'; render();
}
function resolveConflictKeepLocal(){ acctConflict=null; saveMeta(); screen='menu'; render(); }
function resolveConflictUseCloud(){ if(acctConflict) META={...DEF_META,...acctConflict.server}; acctConflict=null; saveMeta(); screen='menu'; render(); }
/* ---------- ECHO BOX (design/gdd/economy-progression.md §10.3, amended
   2026-09-02: Echo Forge -> Echo Box, deterministic point-buy -> gacha) ----------
   End-game Gene Shard sink, unlocked once the Collection Log (Faces + Relics +
   Bosses) is 100% complete. The tier meter/glow-border math (ECHO/echoTier/
   echoCost) is UNCHANGED from the original Echo Forge — only what a purchase
   GRANTS changed, from a deterministic point to a cosmetic gacha pull. See
   COSMETIC_POOLS/ECHO_BOX_* in cosmetics.js and scEchoBox()/scProfile() below. */
function collectionComplete(){
  return META.faces.length>=FACE_POOL.length && META.relics.length>=RELICS.length && META.bosses.length>=BOSSES.length;
}
function echoCost(n){ return Math.round(ECHO.base*Math.pow(ECHO.growth,n-1)); }
function echoTier(){ return Math.min(Math.floor((META.echoBoxesOpened||0)/ECHO.tierSize), ECHO_TIER_NAMES.length-1); }
/* Deterministic tier-title grant (NO randomness — same mechanic as before,
   just routed through the new ownership model): push into ownedTitles so it's
   never silently lost, and auto-equip it (matches the old "always show your
   newest unlock" behaviour). Also used by bpClaim() below for Battle Pass
   titles. */
function grantTitle(t){
  if(!t) return;
  if(!META.ownedTitles.includes(t)) META.ownedTitles.push(t);
  META.equipped.title=t;
}
function ownedArrFor(cat){
  return cat==='avatar'?META.ownedAvatars:cat==='decor'?META.ownedDecor:cat==='background'?META.ownedBackgrounds:META.ownedTitles;
}
/* Cumulative-weight rarity roll over ECHO_BOX_RARITY_ODDS (r0..r4). */
function rollEchoRarity(){
  let roll=Math.random(), acc=0;
  for(let r=0;r<ECHO_BOX_RARITY_ODDS.length;r++){ acc+=ECHO_BOX_RARITY_ODDS[r]; if(roll<acc) return r; }
  return ECHO_BOX_RARITY_ODDS.length-1;
}
/* Opens one Echo Box: (1) unchanged gate/cost/tier-title mechanic, (2) rolls
   a cosmetic reward by rarity then category, granting an unowned item in that
   exact rarity+category cell, or recording a duplicate toward fusion if the
   whole cell is already owned. Returns a result object for the caller to
   render (scEchoBox()), or null if the purchase itself couldn't happen. */
function echoBoxOpen(){
  if(!collectionComplete()) return null;
  const cost=echoCost((META.echoBoxesOpened||0)+1);
  if(META.shards<cost) return null;
  const beforeTier=echoTier();
  META.shards-=cost; META.echoBoxesOpened=(META.echoBoxesOpened||0)+1;
  let tierTitle=null;
  if(echoTier()>beforeTier){ tierTitle=ECHO_TITLES[echoTier()]; grantTitle(tierTitle); }
  const rar=rollEchoRarity();
  const cat=ECHO_BOX_CATEGORIES[Math.floor(Math.random()*ECHO_BOX_CATEGORIES.length)];
  const pool=COSMETIC_POOLS[cat], owned=ownedArrFor(cat);
  const candidates=Object.keys(pool).filter(k=>pool[k].rar===rar && !owned.includes(k));
  let result;
  if(candidates.length){
    const key=candidates[Math.floor(Math.random()*candidates.length)];
    owned.push(key);
    result={dup:false,cat,rar,key,n:pool[key].n,tierTitle};
  } else {
    META.dupeCounts[rar]=(META.dupeCounts[rar]||0)+1;
    result={dup:true,cat,rar,dupeCount:META.dupeCounts[rar],tierTitle};
  }
  saveMeta();
  return result;
}
/* Fusion (economy-progression.md §10.3 amendment): ECHO_FUSE_COST duplicate
   rolls of the same rarity (any category) fuse into 1 guaranteed-new item one
   rarity tier up. Mythic (r4) duplicates have nowhere higher to go and refund
   Shard instead; if the entire next tier (and every tier above it, up to
   mythic) is already 100% owned, cascade upward and fall back to the same
   refund rather than getting stuck with an unspendable fusion. */
function fuseCosmetics(rarity){
  if(((META.dupeCounts&&META.dupeCounts[rarity])||0)<ECHO_FUSE_COST) return null;
  META.dupeCounts[rarity]-=ECHO_FUSE_COST;
  if(rarity>=4){ META.shards+=ECHO_FUSE_MYTHIC_REFUND; saveMeta(); return {refund:true,shards:ECHO_FUSE_MYTHIC_REFUND}; }
  let targetRar=rarity+1, granted=null;
  while(targetRar<=4 && !granted){
    for(const cat of ECHO_BOX_CATEGORIES){
      const pool=COSMETIC_POOLS[cat], owned=ownedArrFor(cat);
      const candidates=Object.keys(pool).filter(k=>pool[k].rar===targetRar && !owned.includes(k));
      if(candidates.length){
        const key=candidates[Math.floor(Math.random()*candidates.length)];
        owned.push(key);
        granted={cat,rar:targetRar,key,n:pool[key].n};
        break;
      }
    }
    if(!granted) targetRar++;
  }
  if(!granted){ META.shards+=ECHO_FUSE_MYTHIC_REFUND; saveMeta(); return {refund:true,shards:ECHO_FUSE_MYTHIC_REFUND}; }
  saveMeta();
  return granted;
}
/* ---------- IMPORT AXIE VAULT (design/AUDIT_AND_SPEC_v1.md §G3① / §G5) ----------
   Vault lưu die suy ra từ Axie NFT thật (axieToDie, engine.js). Giới hạn 20 slot (localStorage) —
   nếu đầy, TỪ CHỐI import mới kèm thông báo rõ ràng thay vì âm thầm cắt bớt (LRU/silent-trim).
   Import lại cùng axieId (VD: đã đổi part ngoài đời rồi quét lại) → CẬP NHẬT bản ghi cũ, không tạo bản sao. */
const VAULT_MAX=20;
function importAxieToVault(axieData){
  if(!axieData||axieData.id==null) return {ok:false,err:'invalid_axie_data'};
  const die=axieToDie(axieData);
  const idx=META.vault.findIndex(v=>v.axieId===die.axieId);
  if(idx>=0){ META.vault[idx]=die; saveMeta(); return {ok:true,updated:true,die}; }
  if(META.vault.length>=VAULT_MAX) return {ok:false,err:'vault_full',max:VAULT_MAX};
  META.vault.push(die); saveMeta();
  return {ok:true,updated:false,die};
}
function removeFromVault(axieId){
  if(!META.vault) return;
  META.vault=META.vault.filter(v=>v.axieId!==axieId);
  delete HEROES['vault_'+axieId];
  saveMeta();
}
/* Bridge: engine.js resolves roster members via HEROES[re.key] everywhere
   (buildUnit, ascend/gene rewards, passives). Vault entries are already
   shaped like a HEROES record (n/cls/tier/hp/art/die — see axieToDie), so
   registering them under a stable synthetic key lets a vault Axie be picked
   into teamPick and played exactly like a T1 hero, with zero engine changes.
   Idempotent — safe to call on every render. */
function vaultKey(v){ return 'vault_'+v.axieId; }
function ensureVaultHero(v){
  const key=vaultKey(v);
  if(!HEROES[key]) HEROES[key]=v;
  return key;
}
/* ---------- IMPORT AXIE screen state ---------- */
let importIdInput='', importState='idle', importMsg='', importPreview=null, roninAddr=null;
async function connectRonin(){
  if(typeof window.ronin==='undefined') return null;
  try{ const accounts=await window.ronin.provider.request({method:'eth_requestAccounts'}); return accounts&&accounts[0]; }
  catch(e){ return null; }
}
const shortAddr=a=>a?(a.slice(0,9)+'…'+a.slice(-4)):'';
async function doAxieLookup(){
  const id=(importIdInput||'').trim();
  if(!id||isNaN(Number(id))||Number(id)<=0){ importState='error'; importMsg='Nhập Axie ID hợp lệ'; render(); return; }
  importState='loading'; importMsg=''; importPreview=null; render();
  let res;
  try{ res=await fetch('/api/axie?id='+encodeURIComponent(id)); }
  catch(e){ importState='error'; importMsg='Không kết nối được, thử lại sau'; render(); return; }
  if(res.status===404){ importState='error'; importMsg='Không tìm thấy Axie #'+id; render(); return; }
  if(!res.ok){ importState='error'; importMsg='Không kết nối được, thử lại sau'; render(); return; }
  let data;
  try{ data=await res.json(); }
  catch(e){ importState='error'; importMsg='Không kết nối được, thử lại sau'; render(); return; }
  importPreview=data; importState='preview'; render();
}
function scImportAxie(){
  const w=el('div','screen menu vaultscreen');
  w.appendChild(el('h1','logo sm','IMPORT AXIE'));
  w.appendChild(el('div','sub','Manual Axie ID lookup · optional wallet connect for trust signal'));

  if(typeof window!=='undefined'&&typeof window.ronin!=='undefined'){
    const wrow=el('div','vwrow');
    if(roninAddr) wrow.appendChild(el('div','vwaddr','WALLET · '+shortAddr(roninAddr)));
    else wrow.appendChild(btn('ghost sm','CONNECT RONIN WALLET',async()=>{ const a=await connectRonin(); if(a){ roninAddr=a; render(); } }));
    w.appendChild(wrow);
  }

  const form=el('div','cfgrow vform');
  form.appendChild(el('span','cl','AXIE ID'));
  const inp=el('input','seedinp'); inp.type='number'; inp.min='1'; inp.placeholder='e.g. 1234567'; inp.value=importIdInput;
  inp.oninput=e=>importIdInput=e.target.value;
  inp.onkeydown=e=>{ if(e.key==='Enter') doAxieLookup(); };
  form.appendChild(inp);
  const goB=btn('sm','IMPORT',()=>doAxieLookup());
  if(importState==='loading') goB.classList.add('dis');
  form.appendChild(goB);
  w.appendChild(form);

  if(importState==='loading') w.appendChild(el('div','vmsg vmsg-info','Đang tra cứu…'));
  if(importState==='error') w.appendChild(el('div','vmsg vmsg-bad',importMsg));

  if(importState==='preview'&&importPreview){
    const die=axieToDie(importPreview);
    const pv=el('div','vpreview');
    if(die.image){ const pim=el('img','vpreview-art'); pim.src=die.image; pv.appendChild(pim); }
    pv.appendChild(el('div','vpn',die.n+'  ·  '+die.cls.toUpperCase()));
    const parts=el('div','vparts');
    (importPreview.parts||[]).forEach(p=>parts.appendChild(el('span','vpart',(p.type||'?').toUpperCase()+': '+(p.name||'?'))));
    pv.appendChild(parts);
    const dv=el('div','minidie'); die.die.forEach(f=>{ const c=el('span','mf r'+(f.r||0)+' t_'+f.t); c.appendChild(ico(FT_IC[f.t],'t')); if(f.v)c.appendChild(el('span','mfv',String(f.v))); dv.appendChild(c); });
    pv.appendChild(dv);
    const full=(META.vault||[]).length>=VAULT_MAX;
    const already=(META.vault||[]).some(v=>v.axieId===die.axieId);
    const addB=btn('sm go',full&&!already?'VAULT FULL':already?'UPDATE VAULT ENTRY':'ADD TO VAULT',()=>{
      const r=importAxieToVault(importPreview);
      if(r.ok){ importState='idle'; importPreview=null; importIdInput=''; render(); }
      else { importState='error'; importMsg=(r.err==='vault_full')?('Vault đã đầy ('+r.max+'/'+r.max+')'):'Không thể thêm Axie này'; render(); }
    });
    if(full&&!already) addB.classList.add('dis');
    pv.appendChild(addB);
    w.appendChild(pv);
  }

  const vlist=META.vault||[];
  if(vlist.length){
    const sec=el('div','colsec'); sec.appendChild(el('h3',null,'YOUR VAULT  ('+vlist.length+'/'+VAULT_MAX+')'));
    const g=el('div','vaultgrid');
    vlist.forEach(v=>{
      ensureVaultArt(v);
      const c=el('div','vchip'); c.style.setProperty('--cc',CLASS_COLOR[v.cls]);
      const im=el('img','vchip-thumb'); im.src=axieArtSrc(v); im.onerror=()=>{ im.onerror=null; im.src=sprOf(v.cls,v.art||0); }; c.appendChild(im);
      const info=el('div','vchip-info');
      info.appendChild(el('div','vchip-nm',v.n));
      info.appendChild(el('div','vchip-cls',v.cls.toUpperCase()+' · HP '+v.hp));
      c.appendChild(info);
      c.appendChild(btn('ghost xs','REMOVE',()=>{ removeFromVault(v.axieId); render(); }));
      g.appendChild(c);
    });
    sec.appendChild(g);
    w.appendChild(sec);
  }

  w.appendChild(btn('','BACK',()=>{ importState='idle'; importMsg=''; importPreview=null; screen='menu'; render(); }));
  return w;
}
function saveRun(){ try{ if(S&&S.phase!=='won'&&S.phase!=='lost') localStorage.setItem(RK,JSON.stringify({s:S,screen})); else localStorage.removeItem(RK); }catch(e){} }
function loadRun(){ try{ const j=localStorage.getItem(RK); if(!j) return null; return JSON.parse(j); }catch(e){ return null; } }
function clearRun(){ try{ localStorage.removeItem(RK); }catch(e){} }
const unlocked=id=>META.unlocks.includes(id);
function bpLevel(){ let lv=0,need=0; for(let i=1;i<=30;i++){ need+=BP_XP(i); if(META.xp>=need) lv=i; else break; } return lv; }
function bpProg(){ const lv=bpLevel(); let base=0; for(let i=1;i<=lv;i++) base+=BP_XP(i);
  const nxt=lv<30?BP_XP(lv+1):0; return {lv,cur:META.xp-base,need:nxt,pct:nxt?Math.min(100,100*(META.xp-base)/nxt):100}; }
function bpUnclaimed(){ const lv=bpLevel(); return BP.filter(b=>b.lv<=lv&&!META.bpClaimed.includes(b.lv)); }
function bpClaim(b){
  if(META.bpClaimed.includes(b.lv)) return;
  META.bpClaimed.push(b.lv); const r=b.r;
  if(r.t==='shard') META.shards+=r.v;
  else if(r.t==='unlock'){ if(!META.unlocks.includes(r.v)) META.unlocks.push(r.v); }
  else if(r.t==='face'){ if(!META.bpFaces.includes(r.v)) META.bpFaces.push(r.v);
    const f=BP_FACES[r.v]; if(f&&!META.faces.includes(faceText(f.face))) META.faces.push(faceText(f.face)); }
  else if(r.t==='perk') META.perks[r.v]=(META.perks[r.v]||0)+1;
  if(b.title) grantTitle(b.title);
  saveMeta();
}

/* ---------- sprites ---------- */
const MON_SPR={slime:['plant',2],chomper:['beast',1],spikelet:['reptile',2],bugling:['bug',0],jellyfin:['aqua',4],
  ravenling:['bird',5],thornback:['reptile',5],venomaw:['bug',4],bruiser:['beast',7],hexeye:['bug',7],
  cleaver:['beast',4],warden:['plant',7],stalker:['bird',3],pyrewing:['bird',7],broodmaw:['bug',5],
  bomblet:['aqua',7],totem:['plant',4],egg:['aqua',1],
  e_ravager:['beast',8],e_plague:['bug',8],e_bulwark:['plant',8],e_archon:['aqua',8],
  gooey_king:['plant',5],mecha:['reptile',8],frost_lord:['aqua',5],plague_mother:['bug',6],mirror:['reptile',4],agony:['bird',8]};
const sprOf=(cls,i)=>(AXIE_PIX[cls]&&AXIE_PIX[cls][((i%9)+9)%9])?AXIE_PIX[cls][((i%9)+9)%9].src:'';
const sprMon=k=>{ const m=MON_SPR[k]||['beast',0]; return sprOf(m[0],m[1]); };


const PARTN={mouth:'MOUTH',horn:'HORN',back:'BACK',tail:'TAIL',eyes:'EYES',ears:'EARS',blank:'',m:''};
const TYPEN={dmg:'Damage',shield:'Shield',heal:'Heal',mana:'Mana',poison:'Poison',
  buff:'Buff',debuff:'Debuff',summon:'Summon',blank:'Blank'};
const ST_NAME={poison:'Poison',burn:'Burn',regen:'Regen',thorns:'Thorns',blind:'Blind',
  weaken:'Weaken',vulnerable:'Vulnerable',stun:'Stun',undying:'Undying'};

/* ================= FX ================= */
function shake(n){ const a=$('#app'); if(!a) return; a.classList.remove('shk1','shk2','shk3');
  void a.offsetWidth; a.classList.add('shk'+Math.min(3,Math.max(1,n||1)));
  setTimeout(()=>a.classList.remove('shk1','shk2','shk3'),420/SPD); }
/* Photosensitivity: honour both the in-game "REDUCE FLASH EFFECTS" setting and
   the OS-level prefers-reduced-motion query. Neither removes the feedback
   entirely (crit/Mythic still needs *some* signal) — instead flashScreen loses
   its full-viewport radial burst and becomes a thin top-edge accent bar at a
   quarter of the opacity, and hitstop's brightness/contrast punch is cut down
   to a barely-there version instead of being skipped outright. */
const prefersReducedMotion=()=>{ try{ return matchMedia('(prefers-reduced-motion: reduce)').matches; }catch(e){ return false; } };
const wantsLessFlash=()=>META.reduceFlash||prefersReducedMotion();
function flashScreen(cls){ const f=el('div','flashfx '+(cls||'')+(wantsLessFlash()?' low':'')); document.body.appendChild(f); setTimeout(()=>f.remove(),300/SPD); }
function hitstop(ms){ const a=$('#app'); if(!a) return; a.classList.add(wantsLessFlash()?'hstop-lite':'hstop'); setTimeout(()=>a.classList.remove('hstop','hstop-lite'),(ms||90)/SPD); }
function bigText(t,cls){ const d=el('div','bigfx '+(cls||''),t); document.body.appendChild(d); setTimeout(()=>d.remove(),1100/SPD); }

function collectFloats(){ pendFloats=pendFloats.concat(S.floatText); S.floatText=[]; }
function paintFloats(){
  if(!pendFloats.length) return;
  const g={}; pendFloats.forEach(f=>{ (g[f.uid]=g[f.uid]||[]).push(f); });
  let maxHit=0, crit=false;
  for(const uid in g){
    const host=document.querySelector('.floats[data-uid="'+uid+'"]'); if(!host) continue;
    g[uid].forEach((f,i)=>{
      const n=el('div','ftx '+f.cls+(f.big?' b'+f.big:''),f.txt);
      n.style.animationDelay=(i*80/SPD)+'ms'; n.style.animationDuration=(1200/SPD)+'ms';
      n.style.left=(50+(i%3-1)*22)+'%'; host.appendChild(n);
      if(f.cls==='dmg'){ const v=Math.abs(parseInt(f.txt.replace(/[^0-9-]/g,''))||0); if(v>maxHit)maxHit=v; }
      if(f.big>=2) crit=true;
    });
  }
  if(maxHit>0){ SFX.hit(maxHit); if(maxHit>=20) shake(maxHit>=45?3:2); else shake(1); }
  if(crit){ SFX.crit(); hitstop(110); flashScreen('gold'); }
  pendFloats=[];
  setTimeout(()=>$$('.ftx').forEach(n=>n.remove()),1500/SPD);
}

/* ================= DICE ROLL ANIMATION ================= */
function triggerRollAnim(uids){
  rollAnim={uids:uids||S.party.filter(u=>u.hp>0&&u.rolled>=0).map(u=>u.uid),t0:performance.now()};
  SFX.tray();
}
function runRollAnim(){
  if(!rollAnim) return;
  const DUR=430/SPD, STAG=70/SPD;
  const boxes={}; $$('.diebox').forEach(b=>boxes[b.dataset.uid]=b);
  const order=rollAnim.uids.slice();
  const landed={};
  const step=()=>{
    if(!rollAnim) return;
    try{
    const now=performance.now(); let done=true;
    order.forEach((uid,i)=>{
      const b=boxes[uid]; if(!b) return;
      const u=byUid(S,uid); if(!u||u.rolled<0) return;
      const t=now-rollAnim.t0-i*STAG;
      const d=b.querySelector('.die'); if(!d) return;
      if(t<0){ d.classList.add('tumble'); b.classList.add('rolling'); done=false; return; }
      if(t<DUR){
        done=false; d.classList.add('tumble'); b.classList.add('rolling');
        const iv=Math.max(34,34+ (t/DUR)*90);
        const k=Math.floor(t/iv)%6;
        if(d.dataset.tf!=String(k)){ d.dataset.tf=String(k); paintDieFace(d,u,k,true); SFX.tumble(i); }
      } else if(!landed[uid]){
        landed[uid]=1; d.classList.remove('tumble'); b.classList.remove('rolling'); d.classList.add('landed');
        paintDieFace(d,u,u.rolled,false);
        const f=u.die[u.rolled]||u.die[0];
        if(hasKw(f,'heavy')) SFX.heavy(); else SFX.land(i,f.r);
        if(f.r>=4){ SFX.mythic(); hitstop(140); flashScreen('myth'); bigText('MYTHIC',''); }
        else if(f.r>=3){ SFX.legend(); flashScreen('gold'); }
        if(u.critNow){ d.classList.add('critready'); }
        setTimeout(()=>d.classList.remove('landed'),320/SPD);
      }
    });
    if(done){ rollAnim=null; render(); } else requestAnimationFrame(step);
    }catch(err){
      /* Never let a bad frame freeze the tray: without this the dice stay
         locked because clickDie() refuses input while rollAnim is set. */
      console.error('roll animation error',err);
      rollAnim=null; try{ render(); }catch(e){}
    }
  };
  requestAnimationFrame(step);
}
function paintDieFace(d,u,fi,temp){
  const f=u.die[fi]||u.die[0];
  d.className=d.className.replace(/t_\w+/g,'')+' t_'+f.t;
  d.dataset.r=f.r||0;
  d.innerHTML='';
  /* §3.4 — merge the heavy banner + rarity dot into one top accent strip:
     3px-tall, full-width, coloured by rarity (data-r drives the CSS colour,
     same --r1..r4 mapping as before); a small weight glyph insets at the
     left edge only when the face has the `heavy` keyword. */
  const strip=el('div','ractag'); if(hasKw(f,'heavy')) strip.appendChild(el('span','ractag-hv','⚖'));
  d.appendChild(strip);
  d.appendChild(el('div','dp',f.name||PARTN[f.p]||''));
  d.appendChild(ico(FT_IC[f.t],'di'));
  if(f.t==='blank') d.appendChild(el('div','dv blanktxt','BLANK'));
  else if(f.v>0||f.t==='dmg') d.appendChild(el('div','dv',String(temp?f.v:faceValue(S,u,fi))));
  /* §3.3 interim fix — compact die face only shows combat-decision-critical
     keywords (aoe/heavy/exec); the rest (multi/chain/pierce/cleave/cantrip)
     remain visible via the existing unit-inspect modal (modal='unit'). */
  const kws=f.k.filter(k=>k==='aoe'||k==='exec');
  if(kws.length) d.appendChild(el('div','dk',kws.map(kwText).join(' · ')));
  if(!temp&&u.critNow) d.appendChild(el('div','critbadge','CRIT x'+rcritMult()));
}
function rcritMult(){ let m=2; for(const id of S.relics){ const r=RELIC_BY_ID[id]; if(r&&r.critMult&&r.critMult>m)m=r.critMult; } return m; }

/* ================= RENDER ================= */
function render(){
  const root=$('#app'); if(!root) return;
  if(typeof clogInit==='function'&&!clogPanel) clogInit();
  if(typeof clogFreeze==='function'&&S&&S.phase==='lost') clogFreeze();
  if(typeof clogSetOpen==='function'&&screen!=='combat'&&clogOpen) clogSetOpen(false,false);
  $$('.tutov').forEach(n=>n.remove());
  // screen==='combat' covers the entire active run (map/event/shop/reward/
  // combat/win-lose all render under this value via the `else if(S){...}`
  // branch below) — the board is a fixed single-viewport during a run, so
  // the page itself must not scroll or rubber-band drag. Menu/list screens
  // (menu/unlocks/collection/vault/leaderboard/bp/codex/guide/team) never
  // get this class and keep scrolling normally.
  document.body.classList.toggle('locked-scroll', screen==='combat');
  root.innerHTML=''; root.className='';
  // Mandatory login gate (design/gdd/player-accounts.md §3 "App gate") — checked
  // first, before any other screen dispatch, so there is no ordering accident
  // that could let a later branch render while screen==='gate'.
  if(screen==='gate') root.appendChild(scGate());
  else if(screen==='menu') root.appendChild(scMenu());
  else if(screen==='team') root.appendChild(scTeam());
  else if(screen==='unlocks') root.appendChild(scUnlocks());
  else if(screen==='collection') root.appendChild(scCollection());
  else if(screen==='profile') root.appendChild(scProfile());
  else if(screen==='vault') root.appendChild(scImportAxie());
  else if(screen==='leaderboard') root.appendChild(scLeaderboard());
  else if(screen==='history') root.appendChild(scHistory());
  else if(screen==='account') root.appendChild(scAccount());
  else if(screen==='bp') root.appendChild(scBP());
  else if(screen==='codex') root.appendChild(scCodex());
  else if(screen==='guide') root.appendChild(scGuide());
  else if(S){
    if(S.phase==='map') root.appendChild(scMap());
    else if(S.phase==='event'){ root.appendChild(scCombatShell()); root.appendChild(scEvent()); }
    else if(S.phase==='shop'){ root.appendChild(scCombatShell()); root.appendChild(scShop()); }
    else if(S.phase==='reward'){ root.appendChild(scCombat(true)); root.appendChild(scReward()); }
    else if(S.phase==='won'||S.phase==='lost'){ root.appendChild(scCombat(true)); root.appendChild(scEnd()); }
    else root.appendChild(scCombat(false));
  }
  /* T11 · phone portrait gate — CSS decides when it shows */
  if(!$('.rotate-hint')){
    const rh=el('div','rotate-hint');
    rh.appendChild(el('div','rh-ic','[ ]'));
    rh.appendChild(el('div',null,'Rotate your device to landscape to play.'));
    rh.appendChild(el('div','sub','The board is five columns wide.'));
    document.body.appendChild(rh);
  }
  if(S&&modal==='info') root.appendChild(scInfo());
  if(S&&modal==='unit') root.appendChild(scUnitInfo());
  if(modal==='set')     root.appendChild(scSettings());
  if(modal==='name')    root.appendChild(scNameModal());
  if(modal==='avatar')  root.appendChild(scAvatarModal());
  postRender();
}
function postRender(){
  if(rollAnim) runRollAnim();
  if(typeof bindDrag==='function') bindDrag();
  if(tut&&screen!=='menu') document.body.appendChild(tutOverlay());
  autoFit();
}
/* Shrink the board just enough that the dice tray, REROLL and END TURN are
   always on screen. Laptops with short windows used to push them below the
   fold, which made the game look unresponsive. Never scales above the user's
   own UI scale setting. */
/* T09 · the old autoFit could only ever shrink, so on a tall screen the board
   used ~64% of the height while the dice numbers stayed at 30px. fitUI scales
   both ways. Below 1200px the breakpoints (T10) already handle sizing, so we
   lock to 1 there — otherwise the two mechanisms multiply. */
const BOARD_W = 880;   /* 846px content + 34px headroom */
const BOARD_H = 985;   /* header + enemies + party + tray + bar + gaps —
  measured live (972px at --ui-scale:1, 5-unit party + msg banner), not a
  guess: the old value of 720 predated later additions (Formation Resonance
  links, the 5th party column) and silently let the board grow taller than
  fitUI's shrink math accounted for, pushing the dice tray/END TURN off the
  bottom on shorter windows. Re-measure with document.querySelector('.screen
  .combat').scrollHeight at --ui-scale:1 if combat's vertical content changes
  again — don't just bump this number blind. */
function fitUI(){
  const raw = Math.min(innerWidth / BOARD_W, innerHeight / BOARD_H);
  const s = innerWidth >= 1200 ? Math.min(raw, 1.20) : 1;
  // Floor raised 0.85 -> 1.0: text must never be shrunk below its authored
  // size (--t1 is 11px, already the accessibility minimum — tools/verify.mjs
  // A4 also hardcodes 11px, so bumping the token itself isn't an option
  // either). The real, measured combat height (BOARD_H above) is taller than
  // a standard 900px-tall desktop viewport, so something has to give: below
  // this floor, the board scrolls (body is no longer overflow:hidden — see
  // the scroll-lock fix) instead of shrinking text past legibility. Only
  // scales UP (still capped at 1.20) on genuinely tall windows.
  document.documentElement.style.setProperty('--ui-scale', Math.max(1.0, s).toFixed(3));
}
function autoFit(){ fitUI(); }
let fitT=null;
addEventListener('resize', fitUI, { passive:true });
fitUI();

/* Profile identity costs (design/gdd/economy-progression.md tier calibration:
   150 matches the cheapest existing UNLOCKS shard cost, 200 sits one tier up
   to reflect image storage/sync weight — both stay well under the 400+ range
   reserved for power-adjacent unlocks, keeping this clearly cosmetic-tier).
   First use of each is free (META.freeNameUsed/freeAvatarUsed), tracked
   independently so using one doesn't silently spend the other's free use. */
const RENAME_COST=150, REAVATAR_COST=200;
const AVATAR_MAX_DIM=128, AVATAR_JPEG_Q=0.7, AVATAR_MAX_BYTES=40*1024;
function nameChangeCost(){ return META.freeNameUsed?RENAME_COST:0; }
function avatarChangeCost(){ return META.freeAvatarUsed?REAVATAR_COST:0; }
function applyDisplayName(name){
  const n=(name||'').trim().slice(0,24);
  if(!n) return false;
  const cost=nameChangeCost();
  if(cost>0){ if(META.shards<cost) return false; META.shards-=cost; }
  META.displayName=n; META.freeNameUsed=true; saveMeta(); return true;
}
function applyCustomAvatar(dataUrl){
  const cost=avatarChangeCost();
  if(cost>0){ if(META.shards<cost) return false; META.shards-=cost; }
  META.customAvatar=dataUrl; META.avatarSource='custom'; META.freeAvatarUsed=true; saveMeta(); return true;
}
/* Downscales/re-encodes an uploaded image client-side (center-cropped to a
   square) so a custom avatar can never meaningfully threaten the 512KB
   api/sync-save.js META budget — see AVATAR_MAX_DIM/AVATAR_JPEG_Q/
   AVATAR_MAX_BYTES above. Rejects non-images and anything that's still too
   big after compression rather than silently truncating it. */
function readAvatarFile(file, cb){
  if(!file||!/^image\//.test(file.type)){ cb(null,'Please choose an image file.'); return; }
  const img=new Image();
  const url=URL.createObjectURL(file);
  img.onload=()=>{
    URL.revokeObjectURL(url);
    const side=Math.min(img.width,img.height);
    const sx=(img.width-side)/2, sy=(img.height-side)/2;
    const cv=document.createElement('canvas'); cv.width=AVATAR_MAX_DIM; cv.height=AVATAR_MAX_DIM;
    cv.getContext('2d').drawImage(img,sx,sy,side,side,0,0,AVATAR_MAX_DIM,AVATAR_MAX_DIM);
    const dataUrl=cv.toDataURL('image/jpeg',AVATAR_JPEG_Q);
    if(dataUrl.length>AVATAR_MAX_BYTES*1.4){ cb(null,'Image too complex to compress small enough — try a simpler picture.'); return; }
    cb(dataUrl,null);
  };
  img.onerror=()=>{ URL.revokeObjectURL(url); cb(null,'Could not read that image.'); };
  img.src=url;
}
/* ================= MENU ================= */
/* Shared avatar+decor composition — used by the menu's top-left corner
   (48px) and the full Profile screen preview (96px, sized via CSS on
   .profile-avatar-wrap/.profile-avatar). Decor pack 1 (CSS ring/frame) sets
   a `decor-<style>` class on the wrap; decor pack 2 (real land-item art)
   badges a small `<img>` in the corner instead — the two kinds coexist in
   the same pool, this renders whichever the equipped item has. */
function buildAvatarWrap(eq){
  const eqDecor=eq.decor&&COSMETIC_DECOR[eq.decor];
  const avWrap=el('div','profile-avatar-wrap'+(eqDecor&&eqDecor.style?(' decor-'+eqDecor.style):''));
  const av=el('div','profile-avatar');
  if(META.avatarSource==='custom'&&META.customAvatar){
    const im=el('img','profile-avatar-img'); im.src=META.customAvatar; av.appendChild(im);
  } else if(eq.avatar&&COSMETIC_AVATARS[eq.avatar]){
    const im=el('img','profile-avatar-img'); im.src=COSMETIC_AVATARS[eq.avatar].src; av.appendChild(im);
  } else {
    av.appendChild(el('div','profile-avatar-empty','—'));
  }
  avWrap.appendChild(av);
  if(eqDecor&&eqDecor.img){
    const badge=el('div','decor-badge'); const bim=el('img','decor-badge-img'); bim.src=eqDecor.img; badge.appendChild(bim);
    avWrap.appendChild(badge);
  }
  return avWrap;
}
/* T18 · One decision in the middle, four secondary destinations under it.
   The old vertical rails are gone: rotated edge text reads ~2x slower, the
   screen edge is browser-chrome territory, and :hover never fires on touch. */
function menuTile(label, sub, fn, flag){
  const b=btn('menu-tile'+(flag?' hasnew':''),'',fn);
  b.appendChild(el('span','mt-n',label));
  b.appendChild(el('small','mt-s',sub||''));
  return b;
}
function scMenu(){
  const w=el('div','screen menu title');
  const nb=bpUnclaimed().length, pr=bpProg(), saved=loadRun();
  const inner=el('div','menu-inner');
  // T19 · login is mandatory now, so every menu view has a signed-in user —
  // surface identity as a persistent top-left corner (avatar + name + title),
  // not a full-weight tile: there's no "sync progress" call-to-action
  // anymore, sync is automatic and invisible. Absolutely positioned against
  // .screen.menu.title (position:relative, see style.css) so it sits in the
  // corner regardless of .menu-inner's centered flow.
  if(authToken){
    const eqCorner=META.equipped||{title:'',avatar:'',decor:'',background:''};
    const corner=el('div','menu-corner');
    corner.appendChild(buildAvatarWrap(eqCorner));
    const txt=el('div','menu-corner-txt');
    txt.appendChild(el('div','menu-corner-name',META.displayName||authUsername||'?'));
    const hasTitle=!!eqCorner.title;
    const titleTxt=hasTitle?(COSMETIC_TITLES[eqCorner.title]?COSMETIC_TITLES[eqCorner.title].n:eqCorner.title):'No title';
    txt.appendChild(el('div','menu-corner-title'+(hasTitle?' has':''),titleTxt));
    corner.appendChild(txt);
    corner.onclick=()=>{ screen='profile'; render(); };
    kbAct(corner);
    w.appendChild(corner);
  }
  inner.appendChild(el('h1','logo','AXIE DICE TACTICS'));
  inner.appendChild(el('div','sub','LUNACIA MUTANTS · v1.0'));
  if(echoTier()>0) inner.appendChild(el('div','sub echotier','Echo Tier: '+ECHO_TIER_NAMES[echoTier()]));
  if(saved){
    inner.appendChild(btn('go cta btn--lg','CONTINUE RUN',()=>{ S=saved.s; screen='combat'; render(); }));
    inner.appendChild(btn('ghost cta2 btn--lg','NEW RUN',()=>{ teamPick=['plant1','beast1','aqua1','reptile1','bug1']; screen='team'; render(); }));
  } else {
    inner.appendChild(btn('go cta btn--lg','PLAY',()=>{ teamPick=['plant1','beast1','aqua1','reptile1','bug1']; screen='team'; render(); }));
  }
  // T19 · grouped by function instead of one flat 4-per-row grid: progression-
  // tracking screens ("what have I earned / what's left") vs. reference/utility
  // screens. Grouping communicates relationship; a uniform grid didn't.
  const faces=(META.faces||[]).length, relics=(META.relics||[]).length;
  const groups=el('div','menu-groups');

  const progGroup=el('div','menu-group');
  progGroup.appendChild(el('div','menu-group-label','PROGRESS'));
  const progGrid=el('div','menu-grid menu-grid--3');
  progGrid.appendChild(menuTile('PASS','Lv '+pr.lv,()=>{ screen='bp'; render(); }, nb>0));
  progGrid.appendChild(menuTile('COLLECTION',faces+' faces · '+relics+' relics',()=>{ screen='collection'; render(); }));
  progGrid.appendChild(menuTile('UNLOCKS',(META.unlocks||[]).length+'/'+UNLOCKS.length,()=>{ screen='unlocks'; render(); }));
  progGroup.appendChild(progGrid);
  groups.appendChild(progGroup);

  const refGroup=el('div','menu-group');
  refGroup.appendChild(el('div','menu-group-label','REFERENCE'));
  const refGrid=el('div','menu-grid menu-grid--4');
  refGrid.appendChild(menuTile('CODEX','how to play',()=>{ screen='codex'; render(); }));
  refGrid.appendChild(menuTile('VAULT',(META.vault||[]).length+'/'+VAULT_MAX+' imported',()=>{ screen='vault'; render(); }));
  refGrid.appendChild(menuTile('LEADERBOARD','Ranked Run scores',()=>{ screen='leaderboard'; render(); loadLeaderboard(); }));
  refGrid.appendChild(menuTile('HISTORY',loadHistory().length+' runs',()=>{ screen='history'; render(); }));
  refGroup.appendChild(refGrid);
  groups.appendChild(refGroup);

  inner.appendChild(groups);
  const line=[];
  if(META.runs) line.push(META.runs+(META.runs===1?' run':' runs'));
  if(META.wins) line.push(META.wins+(META.wins===1?' win':' wins'));
  if(META.best) line.push('best wave '+META.best);
  if(META.shards) line.push(META.shards+' Shard');
  if(line.length) inner.appendChild(el('div','stats',line.join('  ·  ')));
  const row=el('div','menu-mini');
  row.appendChild(btn('ghost btn--sm','SAMPLE TEAMS',()=>{ screen='guide'; render(); }));
  row.appendChild(btn('ghost btn--sm','SETTINGS',()=>{ modal='set'; render(); }));
  row.appendChild(btn('ghost btn--sm','LOGOUT',()=>doLogout()));
  if(typeof devToggle==='function') row.appendChild(btn('ghost btn--sm','DEV TOOLS',()=>devToggle(true)));
  inner.appendChild(row);
  w.appendChild(inner);
  return w;
}
function scUnlocks(){
  const w=el('div','screen menu unlocks');
  w.appendChild(el('h1','logo sm','UNLOCKS'));
  w.appendChild(el('div','sub',META.shards+' GENE SHARD'));
  const g=el('div','unlockgrid');
  UNLOCKS.forEach(u=>{
    const has=unlocked(u.id), can=!has&&META.shards>=u.cost;
    // Reuse the Lunacia Pass card language: icon zone up top, body in the
    // middle, cost/state pinned to the bottom via margin-top:auto — so
    // has/can/dis states read from icon + border color, not just opacity.
    const c=el('div','ucard'+(has?' has':can?' can':' dis'));
    c.appendChild(ico(has?'chest':can?'shard':'blank','ucicow',has?'#5fd68a':undefined));
    const body=el('div','ubody');
    body.appendChild(el('div','un',u.n));
    body.appendChild(el('div','ud',u.d));
    c.appendChild(body);
    c.appendChild(el('div','uc',has?'UNLOCKED':u.cost+' SHARD'));
    if(can){ c.onclick=()=>{ SFX.coin(); META.shards-=u.cost; META.unlocks.push(u.id); saveMeta(); render(); }; kbAct(c); }
    g.appendChild(c);
  });
  w.appendChild(g);
  w.appendChild(btn('','BACK',()=>{ screen='menu'; render(); }));
  return w;
}
function scCollection(){
  const w=el('div','screen menu collection');
  w.appendChild(el('h1','logo sm','COLLECTION'));
  w.appendChild(el('div','sub',`Faces ${META.faces.length}/${FACE_POOL.length} · Relics ${META.relics.length}/${RELICS.length} · Bosses ${META.bosses.length}/${BOSSES.length}`));
  // Render the FULL pool per section (not just owned items) so players can see
  // what's still missing. Unowned entries render as a rarity-tinted "???"
  // placeholder instead of being omitted, keeping progress-by-rarity visible.
  const mk=(title,all)=>{
    const ownedCount=all.filter(x=>x.owned).length;
    const s=el('div','colsec'); s.appendChild(el('h3',null,title+'  ('+ownedCount+'/'+all.length+')'));
    const g=el('div','colgrid');
    all.forEach(x=>{
      const cls='citem'+(x.r!=null?' r'+x.r:'')+(x.owned?'':' locked');
      const c=el('div',cls); c.textContent=x.owned?x.n:'???'; g.appendChild(c);
    });
    s.appendChild(g); return s;
  };
  w.appendChild(mk('RELIC', RELICS.map(r=>({n:r.n,r:r.rar,owned:META.relics.includes(r.id)}))));
  w.appendChild(mk('DIE FACES', FACE_POOL.map(f=>{ const n=faceText(f); return {n,r:f.r,owned:META.faces.includes(n)}; })));
  w.appendChild(mk('BOSSES DEFEATED', BOSSES.map(b=>({n:b.n,r:4,owned:META.bosses.includes(b.k)}))));
  w.appendChild(scEchoBox());
  w.appendChild(btn('','BACK',()=>{ screen='menu'; render(); }));
  return w;
}
/* ---------- ECHO BOX panel (part of Collection screen) ----------
   design/gdd/economy-progression.md §10.3 amendment: was "Echo Forge", a
   deterministic point-buy. Now a cosmetic gacha (avatars/decor/backgrounds/
   titles from cosmetics.js) with the same underlying Shard-cost/tier-meter
   curve. Reveal cards reuse .rcard/rbadge (scReward()'s visual language). */
let echoBoxResult=null, echoFuseResult=null;
function scEchoBox(){
  const s=el('div','colsec echosec');
  s.appendChild(el('h3',null,'ECHO BOX'));
  if(!collectionComplete()){
    s.appendChild(el('div','iempty','Complete every Relic, Die Face and Boss above to unlock the Echo Box.'));
    return s;
  }
  s.appendChild(el('div','ud','Spend leftover Gene Shard on Echo Boxes — gacha pulls for avatars, decor, backgrounds and titles.'));
  const opened=META.echoBoxesOpened||0;
  const tier=echoTier();
  const tierName=tier>0?ECHO_TIER_NAMES[tier]:'—';
  const inTier=opened%ECHO.tierSize;
  const cost=echoCost(opened+1);
  s.appendChild(el('div','ud',`Echo Boxes Opened: ${opened}  ·  Tier: ${tierName}  ·  ${inTier}/${ECHO.tierSize} to next tier`));
  s.appendChild(el('div','ud',`Next Echo Box costs ${cost} Shard.`));
  const can=META.shards>=cost;
  const ob=el('button','btn cta'+(can?'':' dis'),'OPEN BOX');
  if(can){
    ob.onclick=()=>{
      const beforeTier=echoTier();
      const r=echoBoxOpen();
      if(r){
        echoBoxResult=r;
        SFX[(r.rar>=3||r.tierTitle)?'legend':'coin']();
        render();
      }
    };
    ob.onmouseenter=()=>SFX.hover();
  } else {
    ob.disabled=true;
  }
  s.appendChild(ob);

  if(echoBoxResult){
    const r=echoBoxResult;
    const card=el('div','rcard r'+r.rar+' echoresult');
    card.appendChild(el('div','rbadge',RARITY[r.rar]));
    card.appendChild(el('div','rt',r.dup?'DUPLICATE':(r.n||'')));
    card.appendChild(el('div','rd',r.dup?('Fusion progress: '+r.dupeCount+'/'+ECHO_FUSE_COST+' at '+RARITY[r.rar]):(r.cat||'').toUpperCase()));
    if(r.tierTitle) card.appendChild(el('div','rsub','Tier title unlocked: '+r.tierTitle));
    s.appendChild(card);
  }

  const fs=el('div','fusewrap');
  for(let r=0;r<5;r++){
    const dc=(META.dupeCounts&&META.dupeCounts[r])||0;
    const row=el('div','fuserow');
    row.appendChild(el('span','rchip r'+r,RARITY[r]));
    row.appendChild(el('span','ud',dc+'/'+ECHO_FUSE_COST));
    const fb=el('button','btn sm'+(dc>=ECHO_FUSE_COST?'':' dis'),r>=4?'FUSE (SHARD REFUND)':'FUSE');
    if(dc>=ECHO_FUSE_COST){
      fb.onclick=()=>{ const res=fuseCosmetics(r); if(res){ echoFuseResult=res; SFX.legend(); render(); } };
      fb.onmouseenter=()=>SFX.hover();
    } else {
      fb.disabled=true;
    }
    row.appendChild(fb);
    fs.appendChild(row);
  }
  s.appendChild(fs);
  if(echoFuseResult){
    const r=echoFuseResult;
    const card=el('div','rcard'+(r.refund?'':(' r'+r.rar))+' echoresult');
    if(r.refund) card.appendChild(el('div','rt','+'+r.shards+' Gene Shard'));
    else {
      card.appendChild(el('div','rbadge',RARITY[r.rar]));
      card.appendChild(el('div','rt',r.n));
      card.appendChild(el('div','rd',(r.cat||'').toUpperCase()));
    }
    s.appendChild(card);
  }
  return s;
}

/* ================= PROFILE ================= */
/* Equipped-cosmetics preview + the 4 owned-collection sections (Titles/
   Avatars/Decor/Backgrounds). Reuses scCollection()'s mk()-style "owned item
   vs rarity-tinted ??? placeholder" pattern (.colsec/.citem — see scCollection
   above). Scope note: equipped avatar/decor/background render ONLY here (and
   the small menu acctbar entry point) — in-combat unit card sprites are a
   separate, already-correct system (Axie class art) and out of scope. */
function scProfile(){
  const w=el('div','screen menu profile');
  w.appendChild(el('h1','logo sm','PROFILE'));
  w.appendChild(el('div','sub','Signed in as '+(authUsername||'?')));

  const eq=META.equipped||{title:'',avatar:'',decor:'',background:''};
  const prevCls='profile-preview'+(eq.background&&COSMETIC_BACKGROUNDS[eq.background]?(' '+COSMETIC_BACKGROUNDS[eq.background].style):'');
  const prev=el('div',prevCls);
  // Avatar+decor composition shared with the menu corner — see
  // buildAvatarWrap() above scMenu().
  prev.appendChild(buildAvatarWrap(eq));
  prev.appendChild(el('div','profile-title',eq.title?(COSMETIC_TITLES[eq.title]?COSMETIC_TITLES[eq.title].n:eq.title):'No title equipped'));
  const idRow=el('div','profile-idrow');
  idRow.appendChild(el('div','profile-dispname',META.displayName||authUsername||'?'));
  const nameCost=nameChangeCost();
  idRow.appendChild(btn('xs ghost',nameCost?'CHANGE NAME · '+nameCost+' SHARD':'CHANGE NAME · FREE',()=>{ modal='name'; render(); }));
  const avCost=avatarChangeCost();
  idRow.appendChild(btn('xs ghost',avCost?'UPLOAD AVATAR · '+avCost+' SHARD':'UPLOAD AVATAR · FREE',()=>{ modal='avatar'; render(); }));
  prev.appendChild(idRow);
  w.appendChild(prev);

  const mkSec=(title,cat,pool)=>{
    const owned=ownedArrFor(cat)||[];
    const keys=Object.keys(pool);
    const s=el('div','colsec'); s.appendChild(el('h3',null,title+'  ('+owned.length+'/'+keys.length+')'));
    const g=el('div','colgrid');
    keys.forEach(k=>{
      const item=pool[k], has=owned.includes(k), isEq=eq[cat]===k;
      const thumbSrc=item.src||item.img; // real art (avatar portraits/cards, land-item decor) vs. CSS-only entries
      const c=el('div','citem r'+item.rar+(has?'':' locked')+(isEq?' on':'')+(thumbSrc?' has-thumb':''));
      if(has&&thumbSrc){ const t=el('img','citem-thumb'); t.src=thumbSrc; c.appendChild(t); c.appendChild(el('span',null,item.n)); }
      else c.textContent=has?item.n:'???';
      if(has){
        c.onclick=()=>{ META.equipped[cat]=k; if(cat==='avatar') META.avatarSource='gacha'; saveMeta(); render(); };
        kbAct(c);
      }
      g.appendChild(c);
    });
    // A previously-uploaded custom avatar is never deleted by switching to a
    // gacha one (see applyCustomAvatar()) — surface it as its own always-
    // owned tile so switching back is free, not a re-purchase.
    if(cat==='avatar'&&META.customAvatar){
      const isEq=META.avatarSource==='custom';
      const c=el('div','citem custom has-thumb'+(isEq?' on':''));
      const t=el('img','citem-thumb'); t.src=META.customAvatar; c.appendChild(t); c.appendChild(el('span',null,'My Upload'));
      c.onclick=()=>{ META.avatarSource='custom'; saveMeta(); render(); };
      kbAct(c);
      g.insertBefore(c,g.firstChild);
    }
    s.appendChild(g); return s;
  };
  // ownedTitles also holds deterministic titles that AREN'T in the gacha
  // pool (Echo Tier's ECHO_TITLES, Battle Pass's b.title rewards — both
  // granted via grantTitle(), see echoBoxOpen()/bpClaim()). Without this,
  // they'd count toward the "(N/18)" total but never actually appear as a
  // selectable chip, and the count would look broken (more owned than the
  // pool size). Show them as their own always-owned, max-rarity entries,
  // keyed by the title text itself (how ownedTitles stores them).
  const titlePool={...COSMETIC_TITLES};
  (META.ownedTitles||[]).forEach(t=>{ if(!titlePool[t]) titlePool[t]={n:t,rar:4}; });
  w.appendChild(mkSec('TITLES','title',titlePool));
  w.appendChild(mkSec('AVATARS','avatar',COSMETIC_AVATARS));
  w.appendChild(mkSec('DECOR','decor',COSMETIC_DECOR));
  w.appendChild(mkSec('BACKGROUNDS','background',COSMETIC_BACKGROUNDS));
  w.appendChild(btn('','BACK',()=>{ screen='menu'; render(); }));
  return w;
}

/* ================= TEAM SELECT ================= */
let pickMode='short', pickAsc=0, pickSeed='', pickRanked=false;
/* Compact Vault chip accordion (ux-designer spec, 2026-09-03) — Set of
   expanded vault hero keys, same inline-expand pattern as historyExpanded/
   lbExpanded elsewhere in this file. Real art (v.image, from the Axie
   Infinity API via api/axie.js) falls back to the generated pixel sprite if
   missing/broken — vault entries imported before this field existed have
   image:null|undefined and just show the sprite, no re-import required. */
let vaultExpanded=new Set();
const axieArtSrc=v=>v.image||sprOf(v.cls,v.art||0);
/* Vault entries imported before the `image` field existed (2026-09-03) have
   no v.image at all — rather than force a manual re-import for every old
   entry, lazily backfill it once per render pass: refetch just the id from
   the same api/axie proxy Import Axie already uses, cache the real art URL
   into the vault record, and re-render. Silent no-op on any failure (offline,
   API down, Axie no longer resolvable) — the sprite fallback already covers
   that, this is purely a nice-to-have upgrade, never blocking. */
let vaultArtFetching=new Set();
function ensureVaultArt(v){
  if(v.image||!v.axieId||vaultArtFetching.has(v.axieId)) return;
  vaultArtFetching.add(v.axieId);
  fetch('/api/axie?id='+encodeURIComponent(v.axieId)).then(r=>r.ok?r.json():null).then(data=>{
    if(data&&data.image){
      v.image=data.image;
      const idx=(META.vault||[]).findIndex(x=>x.axieId===v.axieId);
      if(idx>=0) META.vault[idx].image=data.image;
      saveMeta(); render();
    }
  }).catch(()=>{}).finally(()=>vaultArtFetching.delete(v.axieId));
}
function scTeam(){
  const w=el('div','screen title');
  w.appendChild(el('h1','logo sm','CHOOSE YOUR TEAM'));
  w.appendChild(el('div','sub','Pick 5 Axies · left click to add · right click to remove'));
  if(msg) w.appendChild(el('div','msg',msg));
  const full=teamPick.length>=5;
  const grid=el('div','pickgrid');
  T1.forEach(k=>{
    const h=HEROES[k], n=teamPick.filter(x=>x===k).length, pa=PASSIVE[h.cls];
    const c=el('div','pick'+(n?' on':'')+(full&&!n?' full':'')); c.style.setProperty('--cc',CLASS_COLOR[h.cls]);
    const im=el('img','spr'); im.src=sprOf(h.cls,h.art+(n%3)); c.appendChild(im);
    c.appendChild(el('div','nm',h.n));
    c.appendChild(el('div','cls',h.cls.toUpperCase()+' · HP '+h.hp));
    const p=el('div','pasbox'); p.appendChild(el('span','pn',pa.n)); p.appendChild(el('span','pd',pa.d)); c.appendChild(p);
    const dv=el('div','minidie'); h.die.forEach(f=>{ const c=el('span','mf t_'+f.t); c.appendChild(ico(FT_IC[f.t],'t')); if(f.v)c.appendChild(el('span','mfv',String(f.v))); dv.appendChild(c); });
    c.appendChild(dv);
    if(n) c.appendChild(el('div','cnt','×'+n));
    c.onclick=()=>{ if(teamPick.length<5){ SFX.ui(); msg=''; teamPick.push(k); render(); } else { SFX.warn(); flash('Team full (5/5) — right-click a card to swap it out'); render(); } };
    c.oncontextmenu=e=>{ e.preventDefault(); const i=teamPick.lastIndexOf(k); if(i>=0){SFX.ui();msg='';teamPick.splice(i,1);render();} };
    kbAct(c);
    grid.appendChild(c);
  });
  w.appendChild(grid);

  if((META.vault||[]).length){
    w.appendChild(el('h3','vaulthdr','YOUR VAULT'));
    const vgrid=el('div','vaultgrid');
    META.vault.forEach(v=>{
      ensureVaultArt(v);
      const key=ensureVaultHero(v), h=HEROES[key];
      const n=teamPick.filter(x=>x===key).length, pa=PASSIVE[h.cls];
      const open=vaultExpanded.has(key);
      const c=el('div','vchip'+(n?' on':'')+(full&&!n?' full':'')); c.style.setProperty('--cc',CLASS_COLOR[h.cls]);
      const im=el('img','vchip-thumb'); im.src=axieArtSrc(v); im.onerror=()=>{ im.onerror=null; im.src=sprOf(h.cls,h.art); }; c.appendChild(im);
      const info=el('div','vchip-info');
      info.appendChild(el('div','vchip-nm',h.n));
      info.appendChild(el('div','vchip-cls',h.cls.toUpperCase()+' · HP '+h.hp));
      c.appendChild(info);
      if(n) c.appendChild(el('div','cnt','×'+n));
      const ib=el('button','vchip-i',open?'×':'i'); ib.title='Ability & dice faces';
      ib.onclick=e=>{ e.stopPropagation(); if(open) vaultExpanded.delete(key); else vaultExpanded.add(key); render(); };
      c.appendChild(ib);
      c.onclick=()=>{ if(teamPick.length<5){ SFX.ui(); msg=''; teamPick.push(key); render(); } else { SFX.warn(); flash('Team full (5/5) — right-click a card to swap it out'); render(); } };
      c.oncontextmenu=e=>{ e.preventDefault(); const i=teamPick.lastIndexOf(key); if(i>=0){SFX.ui();msg='';teamPick.splice(i,1);render();} };
      kbAct(c);
      vgrid.appendChild(c);
      if(open){
        const d=el('div','vdetail');
        const p=el('div','pasbox'); p.appendChild(el('span','pn',pa.n)); p.appendChild(el('span','pd',pa.d)); d.appendChild(p);
        const dv=el('div','minidie'); h.die.forEach(f=>{ const cc=el('span','mf t_'+f.t); cc.appendChild(ico(FT_IC[f.t],'t')); if(f.v)cc.appendChild(el('span','mfv',String(f.v))); dv.appendChild(cc); });
        d.appendChild(dv);
        vgrid.appendChild(d);
      }
    });
    w.appendChild(vgrid);
  }

  const cfg=el('div','cfg');
  const modeBox=el('div','cfgrow'); modeBox.appendChild(el('span','cl','MODE'));
  ['short','full'].forEach(m=>{
    const rl=RUN_LEN[m], lock=(m==='full'&&!unlocked('u_full'));
    const b=el('button','btn sm'+(pickMode===m?' on':'')+(lock?' dis':''),rl.n+' · '+rl.d+(lock?'  [LOCKED]':''));
    b.onclick=()=>{ if(lock)return; SFX.ui(); pickMode=m; render(); }; modeBox.appendChild(b);
  });
  cfg.appendChild(modeBox);
  const ascBox=el('div','cfgrow'); ascBox.appendChild(el('span','cl','ASCENSION'));
  for(let a=0;a<=Math.min(10,META.ascMax);a++){
    const b=el('button','btn sm'+(pickAsc===a?' on':''),'A'+a);
    b.title=a===0?'No modifiers':ASCENSION.slice(0,a).map(x=>'A'+x.a+': '+x.d).join('\n');
    b.onclick=()=>{ SFX.ui(); pickAsc=a; render(); }; ascBox.appendChild(b);
  }
  if(META.ascMax===0) ascBox.appendChild(el('span','hintxt','Win a run to unlock Ascension 1'));
  cfg.appendChild(ascBox);
  const rkBox=el('div','cfgrow'); rkBox.appendChild(el('span','cl','RANKED'));
  const hasVault=teamPick.some(k=>k.startsWith('vault_'));
  if(hasVault) pickRanked=false;
  const rb=el('button','btn sm'+(pickRanked?' on':'')+(hasVault?' dis':''),'RANKED RUN'+(pickRanked?' ✓':''));
  rb.title=hasVault?'Remove your Vault (Import Axie) picks to enable Ranked Run.'
    :'Ranked Run ignores all Unlock/Pass bonuses (everyone plays the exact same numbers) and can be submitted to the Leaderboard.';
  rb.onclick=()=>{ if(hasVault)return; SFX.ui(); pickRanked=!pickRanked; render(); };
  rkBox.appendChild(rb);
  if(pickRanked) rkBox.appendChild(el('span','hintxt','No Unlock/Pass bonuses this run · eligible for the Leaderboard'));
  cfg.appendChild(rkBox);
  if(pickAsc>0){ const d=el('div','ascdesc'); ASCENSION.slice(0,pickAsc).forEach(x=>d.appendChild(el('div',null,'A'+x.a+' · '+x.d))); cfg.appendChild(d); }
  const seedBox=el('div','cfgrow'); seedBox.appendChild(el('span','cl','SEED'));
  const inp=el('input','seedinp'); inp.placeholder='leave blank for random'; inp.value=pickSeed;
  inp.oninput=e=>pickSeed=e.target.value; seedBox.appendChild(inp);
  const dseed='DAILY-'+new Date().toISOString().slice(0,10);
  seedBox.appendChild(btn('sm','DAILY SEED',()=>{ pickSeed=dseed; render(); }));
  cfg.appendChild(seedBox);
  w.appendChild(cfg);

  const bar=el('div','trow');
  bar.appendChild(el('div','tcount',`${teamPick.length}/5`));
  bar.appendChild(btn('','RANDOM',()=>{ teamPick=[]; while(teamPick.length<5) teamPick.push(T1[Math.floor(Math.random()*6)]); render(); }));
  bar.appendChild(btn('sm','CODEX',()=>{ screen='codex'; render(); }));
  bar.appendChild(btn('sm','SAMPLE TEAMS',()=>{ screen='guide'; render(); }));
  bar.appendChild(btn('','MENU',()=>{ msg=''; screen='menu'; render(); }));
  const go=btn('big go','START RUN',()=>{ if(teamPick.length===5) startRun(); });
  if(teamPick.length!==5) go.classList.add('dis');
  bar.appendChild(go);
  w.appendChild(bar);
  return w;
}
function hashSeed(str){ let h=2166136261; for(let i=0;i<str.length;i++){ h^=str.charCodeAt(i); h=Math.imul(h,16777619); } return h>>>0; }
/* Leaderboard anti-cheat (design/gdd/leaderboard-system.md "Nộp điểm & xác thực"):
   the server replays actionLog through the exact same engine.js call sequence
   and only trusts the score IT computes. logAction() must be called at every
   site that mutates S via an engine.js function — see the matching list this
   comment enumerates, kept in sync manually since there's no framework to
   enforce it: chooseNode, playerUseDie, playerUseRelic, doReroll, endTurn,
   undo, takeReward, eventChoose, shopBuy, shopDone. */
function logAction(fn,args){ if(S&&S.actionLog) S.actionLog.push({fn,args}); }

function startRun(){
  // Match History (src/log.js runLogEntries): reset at the NEW RUN boundary,
  // not per-wave (clogReset() below/in scMap stays wave-scoped) — see
  // log.js's runLogEntries comment for why this is a separate accumulator.
  if(typeof clogRunReset==='function') clogRunReset();
  const seed = pickSeed? hashSeed(pickSeed) : (Math.random()*1e9)|0;
  const P=META.perks||{};
  /* Ranked Run (leaderboard-eligible): zero every META-derived bonus so a
     submission replays identically for every player regardless of how many
     Unlocks they've bought locally — meta-progression is never synced to the
     server, so it can't be trusted/verified there. This is the MVP's
     "Standard board, ai cũng như nhau" guarantee (leaderboard-system.md) —
     see docs/architecture/adr-0001 follow-up note on why a full Standard/
     Collector split needing server-side progression sync is out of scope
     for this beta. Vault (Import Axie) picks are blocked in Ranked Run for
     the same reason: replay would need the server to re-fetch NFT part data
     over the network mid-replay, which the design's deterministic-replay
     model forbids (network calls aren't deterministic). */
  const ranked=!!pickRanked;
  const sr=ranked?0:(unlocked('u_start')?1:0)+(P.relic0||0)+(P.relic1||0);
  const srRar=(P.relic1?1:0);
  S=newGame(seed,teamPick.slice(),{mode:pickMode,asc:pickAsc,
    bonusReroll: ranked?0:(unlocked('u_reroll')?1:0)+(unlocked('u_reroll2')?1:0)+(P.reroll||0),
    metaHpBonus: ranked?0:(unlocked('u_hp')?3:0)+(unlocked('u_hp2')?2:0)+4*(P.hp4||0),
    startRelics: sr? [pick0(RELICS.filter(r=>r.rar<=srRar&&!r.act)).id] : []});
  S.ranked=ranked;
  S.startedAt=Date.now();
  S.actionLog = ranked? [] : null;
  S.runSeed = seed;
  S.runTeamKeys = teamPick.slice();
  S.bpFaces=(META.bpFaces||[]).slice();
  S.rerollReward=1+(P.rrw||0); S.rrwMax=S.rerollReward;
  S.unlockRelicMax = unlocked('u_relic2')?3:unlocked('u_relic1')?2:1;
  S.unlockFaceMax  = unlocked('u_face2')?4:unlocked('u_face1')?3:2;
  S.seedStr=pickSeed||('#'+seed);
  META.runs++; saveMeta();
  sendTelemetry('run.started',{mode:pickMode,ascension:pickAsc,ranked});
  screen='combat'; sel=null; selRelic=null; msg='';
  /* T-preflight · the tutorial used to auto-open over the map and blocked the
     very first click of a new run. It now lives in CODEX, reachable from the menu. */
  render(); saveRun();
}
const pick0=a=>a[Math.floor(Math.random()*a.length)];

/* ================= MAP ================= */
const NODE_INFO={battle:{n:'BATTLE',ic:'dmg',d:'Regular Chimeras. Standard reward.',c:'#ff7a7a'},
  elite:{n:'ELITE',ic:'elite',d:'Much more dangerous. Bigger reward and more Shard.',c:'#ffa94d'},
  boss:{n:'BOSS',ic:'boss',d:'A boss with its own mechanic. Huge reward.',c:'#ff5f5f'},
  event:{n:'EVENT',ic:'event',d:'A risk-and-reward choice. No combat.',c:'#c78cff'},
  shop:{n:'MERCHANT',ic:'shop',d:'Buy relics and genes with Gene Shard.',c:'#ffd76a'},
  treasure:{n:'TREASURE',ic:'chest',d:'A free reward with no risk.',c:'#5fb8ff'}};
function scMap(){
  const w=el('div','screen map');
  w.appendChild(track(true));
  const bs=S.bossSteps.includes(S.step);
  w.appendChild(el('h2','maph',bs?'BOSS AHEAD':'CHOOSE YOUR PATH'));
  const row=el('div','noderow');
  S.nodes.forEach((nd,i)=>{
    const inf=NODE_INFO[nd.type];
    const c=el('div','nodecard n_'+nd.type); c.style.setProperty('--nc',inf.c);
    c.appendChild(ico(inf.ic,'nic',inf.c));
    c.appendChild(el('div','nn',inf.n));
    if(nd.type==='boss'){ const bk=S.bossPlan[S.bossSteps.indexOf(S.step)]||'agony'; const b=BOSS_BY_K[bk];
      const im=el('img','spr mut'); im.src=sprMon(bk); c.appendChild(im);
      c.appendChild(el('div','nbn',b.n)); c.appendChild(el('div','nd',b.desc)); }
    else {
      c.appendChild(el('div','nd',inf.d));
      if(nd.type==='battle'||nd.type==='elite'){
        const n=CURVE.count(S.pw)+(nd.type==='elite'?S.mods.eliteExtra:0);
        c.appendChild(el('div','nmeta',n+(n>1?' CHIMERAS':' CHIMERA')+(nd.type==='elite'?' · +45 SHARD':' · +25 SHARD')));
      }
    }
    c.onclick=()=>{ SFX.ui(); if(nd.type==='boss') SFX.boss();
      logAction('chooseNode',[i]);
      chooseNode(S,i);
      if(['battle','elite','boss'].includes(nd.type)){
        /* New combat: the log is scoped to "current combat only" (T15) —
           reset before ingesting this combat's own startup batch (e.g. a
           turn-1 cantrip resolving before the player can act). */
        if(typeof clogReset==='function') clogReset();
        if(typeof clogIngest==='function') clogIngest(S.ev);
        triggerRollAnim();
      }
      S.ev=[]; S.floatText=[]; render(); saveRun(); };
    kbAct(c);
    row.appendChild(c);
  });
  w.appendChild(row);
  const mrow=el('div','trow');
  mrow.appendChild(btn('sm info','TEAM & RELIC INFO',()=>{ modal='info'; render(); }));
  w.appendChild(mrow);
  w.appendChild(partyStrip());
  w.appendChild(archStrip());
  return w;
}
/* One bar carries everything the player must always see: where they are, whose
   turn it is, what they can spend. Every other read-out lives behind INFO. */
function track(withCtl){
  const t=el('div','track');
  const isB=S.bossSteps.includes(S.step), isE=S.eliteSteps.includes(S.step);
  t.appendChild(el('div','tlabel','WAVE'));
  const st=el('div','tstep'+(isB?' boss':isE?' elite':''));
  st.appendChild(el('span','en',String(S.step)));
  st.appendChild(el('span',null,'/'+S.len));
  if(isB||isE) st.appendChild(el('span','en',' '+(isB?'BOSS':'ELITE')));
  t.appendChild(st);
  for(let i=1;i<=S.len;i++){
    const cl=S.bossSteps.includes(i)?'boss':S.eliteSteps.includes(i)?'elite':'norm';
    const n=el('div','tnode '+cl+(i<S.step?' done':i===S.step?' cur':''));
    n.title='Wave '+i+(cl==='boss'?' · Boss':cl==='elite'?' · Elite':''); t.appendChild(n);
  }
  const r=el('div','trk-right');
  // S.turn only exists once startCombat() has run; on the map screen (e.g. the
  // forced wave-1 battle node) combat has not started yet, so fall back to 1
  // rather than ever rendering the literal string "undefined".
  if(withCtl) r.appendChild(el('div','turn','TURN '+(S.turn||1)));
  if(withCtl){ const rr=el('div','rr'); rr.appendChild(ico('reroll','t'));
    rr.appendChild(el('span','rrn',S.rerolls+'/'+S.maxRerolls)); rr.title='Rerolls left this turn'; r.appendChild(rr); }
  const shw=el('span','shards'); shw.appendChild(ico('shard','t')); shw.appendChild(el('span',null,' '+S.shards)); r.appendChild(shw);
  if(S.asc) r.appendChild(el('span','ascbadge','A'+S.asc));
  if(withCtl){
    const ub=btn('xs ghost','UNDO',()=>{ if(undo(S)){ logAction('undo',[]); sel=null;selRelic=null;flash('Undone.'); render(); } });
    if(!S.undo.length) ub.classList.add('dis'); r.appendChild(ub);
    const sp=el('div','spd');
    [1,2,3].forEach(v=>{ const b=el('button','btn xs'+(SPD===v?' on':''),v+'x'); b.onclick=()=>{SPD=v;render();}; sp.appendChild(b); });
    r.appendChild(sp);
    const ib=btn('xs ghost','INFO',()=>{ modal='info'; render(); });
    ib.title='Every relic, stat and die face — yours and the enemy’s  (press I)';
    r.appendChild(ib);
    if(typeof clogToggleBtn==='function') r.appendChild(clogToggleBtn());
    r.appendChild(btn('xs ghost','SET',()=>{ modal='set'; render(); }));
  }
  t.appendChild(r);
  return t;
}
function partyStrip(){
  const p=el('div','pstrip');
  S.roster.forEach(e=>{
    const u=buildUnit(e,S), dr=dieRarity(u);
    const c=el('div','psc dr'+dr); c.style.setProperty('--cc',CLASS_COLOR[u.cls]);
    const im=el('img','spr'); im.src=sprOf(u.cls,u.artIdx); c.appendChild(im);
    c.appendChild(el('div','nm',u.n+' T'+u.tier));
    c.appendChild(el('div','hp','HP '+u.maxHp));
    const dv=el('div','minidie');
    u.die.forEach((f,i)=>{ const s2=el('span','mf t_'+f.t+' r'+f.r); s2.appendChild(ico(FT_IC[f.t],'t'));
    if(f.v) s2.appendChild(el('span','mfv',String(f.v))); s2.title='Face '+(i+1)+': '+faceText(f); dv.appendChild(s2); });
    c.appendChild(dv);
    if(dr>=3) c.appendChild(el('div','drtag',dr>=4?'COSMIC DIE':'GOLDEN DIE'));
    p.appendChild(c);
  });
  const rl=el('div','relicstrip');
  if(!S.relics.length) rl.appendChild(el('div','nothing','no relics yet'));
  S.relics.forEach(id=>{ const r=RELIC_BY_ID[id]; if(!r)return;
    const c=el('div','rchip r'+r.rar,r.n); c.title=r.d; rl.appendChild(c); });
  const wrap=el('div','pstripwrap'); wrap.appendChild(p); wrap.appendChild(rl);
  return wrap;
}
function archStrip(){
  const sc=archScore(S), keys=Object.keys(sc).filter(k=>sc[k]>0).sort((a,b)=>sc[b]-sc[a]).slice(0,4);
  const w=el('div','archstrip');
  if(!keys.length) return w;
  w.appendChild(el('span','al','BUILD'));
  keys.forEach((k,i)=>{ const a=ARCH[k]; const c=el('div','achip'+(i===0?' lead':''));
    c.style.setProperty('--ac',a.c); c.appendChild(ico(ARCH_IC[k]||'buff','ai',a.c));
    c.appendChild(el('span','an',a.n)); c.appendChild(el('span','av',String(sc[k])));
    c.title=a.d; w.appendChild(c); });
  return w;
}

const ARCH_IC={poison:'poison',burn:'burn',shield:'shield',mana:'mana',pierce:'dmg',crit:'buff',growth:'regen',summon:'summon',aoe:'debuff',thorns:'thorns'};
/* ================= COMBAT ================= */
function focusState(){
  if(sel!=null||selRelic) return 'target';
  if(S.party.some(u=>u.hp>0&&!u.used&&u.rolled>=0&&u.die[u.rolled].t!=='blank')) return 'dice';
  return 'end';
}
function scCombatShell(){ const w=el('div','screen combat frozen'); w.appendChild(track()); w.appendChild(partyStrip()); return w; }

function scCombat(frozen){
  const fs=focusState();
  const w=el('div','screen combat f_'+fs+(frozen?' frozen':''));
  w.appendChild(track(true));
  if(msg) w.appendChild(el('div','msg',msg));

  /* enemies */
  const ez=el('div','zone enemies');
  S.enemies.forEach(e=>ez.appendChild(unitCard(e)));
  w.appendChild(ez);
  /* party — mỗi Axie ghép chung 1 cột với đúng die của nó (2026-09-01: trước đây
     là 2 hàng riêng, chỉ thẳng cột nhờ trùng width tình cờ; giờ ghép rõ ràng bằng cấu trúc) */
  /* Swarm builds (Primal Nest cantrip, Swarm Nest/Hive Mind relics) can push
     the party past 5 with living Axie Eggs (engine.js applyFace 'summon',
     capped at 4 tokens => up to 9 total). .pcol's default --unit-w never
     shrank for this, so a 7-9-unit party wrapped to a 2nd row that landed
     far below the fold — technically reachable by scrolling (nothing was
     actually broken), but easy to mistake for "abilities stopped working"
     mid-combat. Shrink the whole zone at >6 so it fits without hunting. */
  const pz=el('div','zone party'+(S.party.length>6?' compact':''));
  /* Formation Resonance (design/quick-specs/formation-resonance-2026-09-01.md):
     hiển thị cặp "đang mở" TRƯỚC khi người chơi click — bắt buộc theo pillar
     minh bạch triệt để. cols[i] tương ứng roster/pos i cho các Axie thật vì
     s.party = roster.map(buildUnit) rồi mới push token ở cuối. */
  const resPairs=resonancePairs(S);
  S.party.forEach((u,i)=>{
    const col=el('div','pcol'); col.appendChild(unitCard(u)); col.appendChild(dieBox(u)); pz.appendChild(col);
    const pair=resPairs.find(p=>p.posA===i);
    if(pair){
      const link=el('div','reslink');
      link.appendChild(ico(FT_IC[pair.type],'ii'));
      const tip='Formation Resonance: cặp Axie liền kề cùng roll mặt '+pair.type+' — Axie thực thi SAU nhận +'+Math.round((RESONANCE.mult-1)*100)+'%.';
      link.title=tip; link.dataset.tip=tip; kbAct(link);
      pz.appendChild(link);
    }
  });
  w.appendChild(pz);
  /* bottom */
  const bb=el('div','bottombar');
  const mo=el('div','manaorb'+(S.mana>=10?' full':''));
  mo.appendChild(el('div','mv',String(S.mana))); mo.appendChild(el('div','ml','MANA'));
  const fill=el('div','mfill'); fill.style.height=Math.min(100,S.mana*10)+'%'; mo.appendChild(fill);
  bb.appendChild(mo);
  const items=el('div','items');
  S.relics.forEach(id=>{ const r=RELIC_BY_ID[id]; if(!r||!r.act) return;
    const used=S.usedActives.includes(id), can=S.mana>=r.act.cost&&!used;
    const c=el('div','icard r'+r.rar+(can?'':' dis')+(selRelic===id?' sel':''));
    c.appendChild(el('div','ic-n',r.n)); c.appendChild(el('div','ic-c','MP '+r.act.cost));
    c.title=r.d;
    c.onclick=()=>{ if(!can)return; SFX.ui(); sel=null;
      if(r.act.tgt==='self'){ if(playerUseRelic(S,id,null)){ logAction('playerUseRelic',[id,null]); afterAct(); } }
      else { selRelic=id; render(); } };
    if(can) kbAct(c);
    items.appendChild(c);
  });
  if(!items.children.length) items.appendChild(el('div','nothing','no active cards yet'));
  bb.appendChild(items);
  const rb=btn('reroll','REROLL '+S.rerolls,()=>{
    const pickd=S.party.filter(u=>u.rsel&&u.hp>0&&!u.used&&!u.heavy&&!u.frozen).map(u=>u.uid);
    const use=pickd.length?pickd:S.party.filter(u=>u.hp>0&&!u.used&&!u.heavy&&!u.frozen).map(u=>u.uid);
    if(doReroll(S,use)){ logAction('doReroll',[use]); SFX.reroll(); S.party.forEach(u=>u.rsel=false); sel=null;
      flash('Rerolled. Undo history cleared.'); triggerRollAnim(use); collectFloats(); render(); } });
  if(!(S.rerolls>0&&anyRerollable(S))) rb.classList.add('dis');
  bb.appendChild(rb);
  bb.appendChild(btn('end','END TURN',()=>doEndTurn()));
  w.appendChild(bb);
  /* One line, and only when it earns its place. The generic controls hint
     retires after the first wave so the board stays quiet. */
  const hint = sel!=null ? 'Pick a target — gold outline means legal. Esc to cancel.'
    : selRelic ? 'Pick a target for the card.'
    : fs==='end' ? 'No dice left — press END TURN or Space.'
    : S.step<=1 ? 'Click or drag a die to use it · corner button marks it for reroll · Ctrl+Z undoes'
    : '';
  if(hint) w.appendChild(el('div','hintbar',hint));
  else w.appendChild(el('div','hintbar',''));
  return w;
}

function needsTarget(u){
  const f=u.die[u.rolled];
  if(f.t==='blank'||f.t==='mana'||f.t==='summon') return false;
  if(hasKw(f,'aoe')) return false;
  if(f.t==='dmg'&&kwVal(f,'chain')) return false;
  return true;
}
function validTargets(u){
  if(!needsTarget(u)) return [];
  const f=u.die[u.rolled];
  const foe=['dmg','poison','debuff'].includes(f.t);
  return (foe?aliveE(S):aliveP(S)).map(x=>x.uid);
}

/* Disambiguate same-name units (dup Axie picks, dup enemy mobs). Returns the
   unit's 1-based position — stable-sorted by uid, not board order — among
   currently-ALIVE same-named units on its side, or null when there's no
   collision (the common case, which must render with zero extra markup). */
function dupeIndex(u){
  const pool=(u.side==='e'?S.enemies:S.party).filter(x=>x.hp>0&&x.n===u.n);
  if(pool.length<2) return null;
  pool.sort((a,b)=>a.uid-b.uid);
  return pool.findIndex(x=>x.uid===u.uid)+1;
}
function unitCard(u){
  const isE=u.side==='e';
  const c=el('div','unit'+(isE?' e':' p')+(u.hp<=0?' dead':'')+(u.big?' big':'')+(u.elite?' elite':'')+(u.token?' token':'')+(!isE&&echoTier()>0?' echo'+echoTier():''));
  c.dataset.uid=u.uid;
  if(!isE) c.style.setProperty('--cc',CLASS_COLOR[u.cls]||'#888');
  let tgtable=false;
  if(sel!=null){ const su=byUid(S,sel); if(su) tgtable=validTargets(su).includes(u.uid); }
  if(selRelic){ const a=RELIC_BY_ID[selRelic].act; tgtable=((a.tgt==='enemy')===isE)&&u.hp>0; }
  if(tgtable) c.classList.add('tgt');
  const incoming = !isE && S.enemies.some(e=>e.hp>0&&e.intent&&e.intent.tgt===u.uid&&['dmg','poison','debuff'].includes(e.intent.face.t));
  if(incoming) c.classList.add('threat');

  const spw=el('div','sprwrap');
  const im=el('img','spr'+(isE?' mut':'')); im.src=isE?sprMon(u.key):sprOf(u.cls,u.artIdx); spw.appendChild(im);
  if(!isE&&u.pas) { const p=el('div','pasdot',u.pas.n[0]); p.title=u.pas.n+': '+u.pas.d; spw.appendChild(p); }
  c.appendChild(spw);
  const dupeI=dupeIndex(u);
  const nm=el('div','nm',(isE?u.n:u.n+' T'+u.tier)+(u.token?' *':''));
  if(dupeI) nm.appendChild(el('span','dupe-tag',' ('+dupeI+')'));
  c.appendChild(nm);
  /* hp bar + ghost preview */
  /* T05 · the number sits above the bar, so no fill colour can ever make it
     unreadable.  T06 · the class encodes how close to death the unit is —
     identical for both sides, because position already says which side. */
  const pct = u.maxHp ? u.hp/u.maxHp : 0;
  const hpState = pct<=0.25 ? ' crit' : pct<=0.50 ? ' low' : '';
  const bar=el('div','hpbar'+hpState);
  const num=el('div','hpnum');
  num.appendChild(el('b',null,u.hp+'/'+u.maxHp)); bar.appendChild(num);
  const track=el('div','hptrack');
  bar.setAttribute('role','progressbar');
  bar.setAttribute('aria-valuenow',String(Math.max(0,u.hp)));
  bar.setAttribute('aria-valuemin','0'); bar.setAttribute('aria-valuemax',String(u.maxHp));
  bar.setAttribute('aria-label','Health');
  const f1=el('div','hpfill'); f1.style.width=Math.max(0,100*pct)+'%'; track.appendChild(f1);
  const pv=previewOn(u);
  if(pv&&pv.hpAfter!=null){ const gh=el('div','hpghost');
    gh.style.left=(100*pv.hpAfter/u.maxHp)+'%'; gh.style.width=(100*(u.hp-pv.hpAfter)/u.maxHp)+'%'; track.appendChild(gh); }
  bar.appendChild(track);
  c.appendChild(bar);
  if(u.shield>0){ const sb=el('div','shbar'); sb.style.width=Math.min(100,100*u.shield/u.maxHp)+'%';
    const sl=el('span'); sl.appendChild(ico('shield','t')); sl.appendChild(el('span','stv',String(u.shield)));
    sb.appendChild(sl); c.appendChild(sb); }
  const row=el('div','stats');
  /* §3.2 — cap visible status chips: priority-sort (stun/undying > poison/burn >
     everything else), render top 3 + a "+N" overflow chip whose title= lists
     the rest (reuses the existing per-chip title= tooltip pattern). */
  const stChips=[];
  for(const k in ST_IC){ const v=u.st[k]; if(v>0) stChips.push({k,v}); }
  if(u.frozen) stChips.push({k:'frz',v:0,frozen:true});
  const stPriority=k=>(k==='stun'||k==='undying')?0:(k==='poison'||k==='burn')?1:2;
  stChips.sort((a,b)=>stPriority(a.k)-stPriority(b.k));
  const shown=stChips.slice(0,3), overflow=stChips.slice(3);
  shown.forEach(({k,v,frozen})=>{
    if(frozen){ const sp=el('span','st frz'); sp.appendChild(ico('freeze','ii')); sp.title='Frozen: cannot be rerolled'; row.appendChild(sp); return; }
    const sp=el('span','st '+k); sp.appendChild(ico(ST_IC[k],'ii'));
    if(k!=='stun'&&k!=='undying') sp.appendChild(el('span','stv',String(v)));
    sp.title=ST_NAME[k]+' '+v; row.appendChild(sp);
  });
  if(overflow.length){
    const more=el('span','st more','+'+overflow.length);
    more.title=overflow.map(({k,v,frozen})=>frozen?'Frozen: cannot be rerolled':(ST_NAME[k]+' '+v)).join(', ');
    row.appendChild(more);
  }
  c.appendChild(row);
  if(isE&&u.hp>0&&u.intent){
    const f=u.intent.face, v=faceValue(S,u,u.rolled);
    const danger = f.t==='dmg' && v>=(u.big?14:10);
    const it=el('div','intent t_'+f.t+(danger?' danger':''));
    it.appendChild(ico(FT_IC[f.t],'ii'));
    it.appendChild(el('span','iv', (f.t==='debuff'||f.t==='buff')? f.k.filter(x=>x!=='aoe').map(kwText).join(' ') : String(v)));
    const tg=u.intent.tgt!=null?byUid(S,u.intent.tgt):null;
    const tgDupe=tg?dupeIndex(tg):null;
    let tl=hasKw(f,'aoe')?'ALL':(tg?(tg.side==='p'?tg.n:(tg.uid===u.uid?'itself':tg.n)):'');
    if(tl&&tgDupe&&tl!=='ALL'&&tl!=='itself') tl+=' ('+tgDupe+')';
    if(tl) it.appendChild(el('span','itg','→ '+tl));
    ['cleave','pierce','exec'].forEach(k=>{ if(hasKw(f,k)) it.appendChild(el('span','ik',kwText(k).toUpperCase())); });
    c.appendChild(it);
  }
  if(u.boss){ c.appendChild(el('div','bossdesc',u.desc+(u.phase===2?' · PHASE 2':''))); }
  if(pv) c.appendChild(el('div','preview '+pv.cls,pv.txt));
  if(tgtable){ c.onclick=()=>doTarget(u.uid); kbAct(c); }
  else if(u.hp>0){
    /* Not a legal target right now, so a click is a question rather than an
       action: show every face on that Axie's die, ally or enemy. */
    c.classList.add('inspect');
    c.onclick=()=>{ if(Date.now()-lastDragEnd<200) return; SFX.ui(); modal='unit'; modalUid=u.uid; render(); };
    kbAct(c);
  }
  const fl=el('div','floats'); fl.dataset.uid=u.uid; c.appendChild(fl);
  return c;
}
function previewOn(t){
  if(selRelic){ const a=RELIC_BY_ID[selRelic].act;
    if((a.tgt==='enemy')!==(t.side==='e')||t.hp<=0) return null;
    if(a.kind==='heal') return {txt:'+'+a.v,cls:'heal'};
    if(a.kind==='dmg'||a.kind==='ult') return {txt:'-'+a.v,cls:'dmg',hpAfter:Math.max(0,t.hp-a.v)};
    if(a.kind==='stun') return {txt:'STUN',cls:'deb'}; return null; }
  if(sel==null) return null;
  const u=byUid(S,sel); if(!u||!validTargets(u).includes(t.uid)) return null;
  const f=u.die[u.rolled]; let v=faceValue(S,u,u.rolled);
  if(f.t==='dmg'){
    if(u.critNow) v*=rcritMult();
    const low=t.hp<t.maxHp*0.5; if(low&&(u.cls==='beast'||hasKw(f,'exec'))) v=Math.ceil(v*1.6);
    const pierce=hasKw(f,'pierce'); if(pierce&&u.cls==='bird') v+=3;
    if(t.st.vulnerable>0) v=Math.ceil(v*1.5);
    const m=kwVal(f,'multi')||1, tot=v*m;
    const eff=pierce?tot:Math.max(0,tot-t.shield);
    return {txt:(u.critNow?'CRIT ':'')+'-'+tot+(t.hp<=eff?' KILL':''),cls:'dmg',hpAfter:Math.max(0,t.hp-eff)};
  }
  if(f.t==='shield') return {txt:'SH +'+(v+(t.cls==='plant'?2:0)),cls:'shd'};
  if(f.t==='heal') return {txt:'+'+Math.min(v,t.maxHp-t.hp),cls:'heal',hpAfter:null};
  if(f.t==='poison'){ let n=v; if(u.cls==='bug'&&t.st.poison>0) n+=2; return {txt:'PSN +'+n,cls:'poi'}; }
  if(f.t==='debuff'||f.t==='buff') return {txt:f.k.filter(x=>x!=='aoe'&&x!=='cantrip').map(kwText).join(' '),cls:'deb'};
  return null;
}

function dieBox(u){
  const b=el('div','diebox'); b.dataset.uid=u.uid;
  if(u.hp<=0||u.rolled<0){ b.appendChild(el('div','die out','X')); b.appendChild(el('div','dlbl','')); return b; }
  const f=u.die[u.rolled];
  const dr=dieRarity(u);
  const d=el('div','die dr'+dr+(u.used?' used':'')+(sel===u.uid?' sel':'')+(f.t==='blank'?' blank':'')+(u.critNow?' critready':''));
  d.style.setProperty('--cc',CLASS_COLOR[u.cls]||'#888');
  paintDieFace(d,u,u.rolled,false);
  if(hasKw(f,'heavy')) d.classList.add('heavy');
  d.onclick=()=>clickDie(u);
  d.onmouseenter=()=>SFX.hover();
  kbAct(d);
  b.appendChild(d);
  const pips=el('div','pips');
  for(let i=0;i<6;i++){ const p=el('span','pip r'+(u.die[i].r||0)+(i===u.rolled?' on':''));
    p.title='Face '+(i+1)+': '+faceText(u.die[i]); pips.appendChild(p); }
  b.appendChild(pips);
  if(!u.used&&!u.heavy&&!u.frozen){
    const rs=el('div','rsel'+(u.rsel?' on':'')); rs.appendChild(ico('reroll','t'));
    rs.title='Mark this die for reroll';
    rs.onclick=e=>{ e.stopPropagation(); SFX.ui(); u.rsel=!u.rsel; render(); }; kbAct(rs); b.appendChild(rs);
  } else if(u.frozen){ const fz=el('div','rsel frz'); fz.appendChild(ico('freeze','t')); b.appendChild(fz); }
  b.appendChild(el('div','dlbl',u.n));
  return b;
}

/* ---------- actions ---------- */
function clickDie(u){
  if(rollAnim||playing||u.used||u.hp<=0) return;
  const f=u.die[u.rolled];
  if(f.t==='blank'){ flash('This face is blank. Try rerolling it.'); render(); return; }
  selRelic=null; SFX.ui();
  if(!needsTarget(u)){ if(playerUseDie(S,u.uid,null)){ logAction('playerUseDie',[u.uid,null]); afterAct(); } return; }
  sel = sel===u.uid? null : u.uid; render();
}
function doTarget(uid){
  if(playing) return;
  if(selRelic){ const r=selRelic; selRelic=null; if(playerUseRelic(S,r,uid)){ logAction('playerUseRelic',[r,uid]); afterAct(); } else render(); return; }
  if(sel==null) return;
  const su=sel; sel=null;
  if(playerUseDie(S,su,uid)){ logAction('playerUseDie',[su,uid]); afterAct(); } else render();
}
async function afterAct(){
  flash(''); sel=null; selRelic=null;
  render();                         /* vẽ lại tray (die đã dùng) trước khi phát */
  await playEvents();
  S.floatText=[];
  if(S.phase==='won'||S.phase==='reward'){ SFX.win(); onCombatEnd(); }
  render(); saveRun();
}
async function doEndTurn(){
  if(rollAnim||playing) return;
  sel=null; selRelic=null;
  const before=S.turn;
  logAction('endTurn',[]);
  endTurn(S); flash('');
  await playEvents();
  S.floatText=[];
  if(S.phase==='reward'||S.phase==='won'){ SFX.win(); onCombatEnd(); render(); saveRun(); return; }
  if(S.phase==='lost'){ SFX.lose(); onRunEnd(); render(); return; }
  if(S.turn>before) triggerRollAnim();
  if(S.enemies.some(e=>e.hp>0&&e.intent&&e.intent.face.t==='dmg'&&faceValue(S,e,e.rolled)>=(e.big?14:12))) SFX.warn();
  render(); saveRun();
}
function onCombatEnd(){
  if(S.bossSteps.includes(S.step)){ const bk=S.bossPlan[S.bossSteps.indexOf(S.step)]; if(bk&&!META.bosses.includes(bk)){ META.bosses.push(bk); saveMeta(); } }
  if(S.phase==='won') onRunEnd();
}
function onRunEnd(){
  META.shards+=S.shards;
  if(S.step>META.best) META.best=S.step;
  S.seen.faces.forEach(f=>{ if(!META.faces.includes(f)) META.faces.push(f); });
  S.seen.relics.forEach(r=>{ if(!META.relics.includes(r)) META.relics.push(r); });
  if(S.phase==='won'){ META.wins++; if(S.asc>=META.ascMax&&META.ascMax<10) META.ascMax=Math.min(10,S.asc+1); }
  S.xpGain=runXp(S,S.phase==='won'); META.xp+=S.xpGain;
  saveMeta();
  const outcome=S.phase==='won'?'win':(S.abandoned?'quit':'loss');
  sendTelemetry('run.ended',{mode:S.mode,ascension:S.asc,ranked:!!S.ranked,outcome,wave:S.step,
    durationMs:S.startedAt?(Date.now()-S.startedAt):0});
  saveRunHistory(); // reads S — must run before clearRun() discards it
  clearRun();
}
/* ---------- MATCH HISTORY entry (see HK comment above for local-only scope
   decision). Runs once per finished (won OR lost, including an ABANDON RUN
   — see scSettings' ABANDON RUN button, which just sets S.phase='lost' and
   calls onRunEnd()) run, before S is discarded. */
function saveRunHistory(){
  // Same selection logic as archStrip() (top archScore(S) entries by score,
  // ties broken by score order) — do not recompute this differently.
  const sc=archScore(S);
  const archetypes=Object.keys(sc).filter(k=>sc[k]>0).sort((a,b)=>sc[b]-sc[a]).slice(0,4).map(k=>({key:k,score:sc[k]}));
  const entry={
    ts:Date.now(), won:S.phase==='won', mode:S.mode, asc:S.asc, ranked:!!S.ranked,
    wave:S.step, len:S.len,
    stats:{dmg:S.stat.dmg,taken:S.stat.taken,maxHit:S.stat.maxHit,kills:S.stat.kills,turns:S.stat.turns},
    shards:S.shards, xp:S.xpGain,
    team:S.roster.map(e=>{ const u=buildUnit(e,S); return {n:u.n,cls:u.cls,tier:u.tier,artIdx:u.artIdx,die:u.die.map(faceText)}; }),
    relics:S.relics.map(id=>RELIC_BY_ID[id]).filter(Boolean).map(r=>({n:r.n,rar:r.rar,d:r.d})),
    archetypes,
    // Explicit strip of DOM/bookkeeping fields (`node`,`id`,`uid`,`provisional`,
    // `orphan`) before persisting — see src/log.js runLogEntries comment:
    // entries share object references with the live clogEntries panel while
    // a run is in progress, so this mapping is the actual "plain-data copy"
    // boundary, done once here rather than trusted to JSON.stringify.
    log:(typeof runLogEntries!=='undefined'?runLogEntries:[]).map(e=>({
      kind:e.kind, text:e.text, fallback:e.fallback, actor:e.actor, part:e.part, tgt:e.tgt,
      segs:e.segs?e.segs.map(g=>({txt:g.txt,cls:g.cls,ic:g.ic})):e.segs,
      deathTag:e.deathTag}))
  };
  const list=loadHistory();
  list.unshift(entry);
  if(list.length>HISTORY_MAX_RUNS) list.length=HISTORY_MAX_RUNS;
  saveHistory(list);
}
function flash(t){ msg=t; }

/* ================= REWARD ================= */
const TIERN=['REWARD','BIG REWARD','ELITE REWARD','BOSS REWARD'];
function scReward(){
  const ov=el('div','overlay');
  const bx=el('div','rewardbox tier'+S.rewardTier);
  bx.appendChild(el('h2',null,TIERN[S.rewardTier]||TIERN[0]));
  bx.appendChild(el('div','sub','Your party heals to full and any fallen Axie is revived · +'+(S.kind==='boss'?90:S.kind==='elite'?45:25)+' Shard'));
  const row=el('div','rrow');
  S.rewards.forEach((r,i)=>{
    const c=el('div','rcard r'+(r.rar||0)+' t_'+r.t);
    c.style.animationDelay=(i*140/SPD)+'ms';
    c.appendChild(el('div','rbadge',RARITY[r.rar||0]));
    c.appendChild(el('div','rt',r.title));
    if(r.cls){ const im=el('img','spr'); const ent=r.uid!=null?S.roster.find(x=>x.uid===r.uid):null;
      im.src=sprOf(r.cls,(r.tier===4?6:(r.tier-1)*3)+((ent&&ent.vr||0)%3)); c.appendChild(im); }
    else c.appendChild(ico(r.t==='relic'||r.t==='chaos'?'chest':r.t==='curse'?'poison':r.t==='reroll'?'reroll':'shard','ricon'));
    c.appendChild(el('div','rd',r.desc));
    if(r.sub) c.appendChild(el('div','rsub',r.sub));
    if(r.arch&&ARCH[r.arch]){ const a=el('div','rarch',ARCH[r.arch].n); a.style.color=ARCH[r.arch].c; c.appendChild(a); }
    if(r.t==='face'){ const ent=S.roster.find(x=>x.uid===r.uid);
      if(ent){ const u=buildUnit(ent,S); const old=u.die[r.idx];
        c.appendChild(el('div','rrepl','Overwrites: '+faceText(old))); } }
    c.appendChild(el('div','rcta','TAKE'));
    c.onclick=()=>{ if(r.t==='level') SFX.levelup(); else SFX.legend(); if(r.rar>=4) flashScreen('myth'); logAction('takeReward',[i]); takeReward(S,i); sel=null;
      if(typeof clogIngest==='function') clogIngest(S.ev);
      S.ev=[]; S.floatText=[];
      if(S.phase==='combat') triggerRollAnim(); render(); saveRun(); };
    c.onmouseenter=()=>SFX.hover();
    kbAct(c);
    row.appendChild(c);
  });
  bx.appendChild(row);
  if(S.rerollReward>0){
    const rr=btn('sm','REROLL REWARDS ('+S.rerollReward+')',()=>{ if(rerollRewards(S)){ SFX.reroll(); render(); } });
    const wrap=el('div','trow'); wrap.appendChild(rr);
    wrap.appendChild(el('span','hintxt','Once per wave. Draws three new options.'));
    bx.appendChild(wrap);
  }
  bx.appendChild(partyStrip());
  bx.appendChild(archStrip());
  ov.appendChild(bx);
  setTimeout(()=>SFX.open(),80);
  return ov;
}

const EV_IC={shrine:'buff',merchant:'shop',treasure:'chest',campfire:'burn',casino:'shard',mutant:'summon'};
/* ================= EVENT ================= */
function scEvent(){
  const ev=S.event, d=ev.def;
  const ov=el('div','overlay');
  const bx=el('div','rewardbox event');
  bx.appendChild(ico(EV_IC[d.k]||'event','evic'));
  bx.appendChild(el('h2',null,d.n));
  bx.appendChild(el('div','sub',d.d));
  if(!ev.res){
    const row=el('div','rrow');
    d.opts.forEach((o,i)=>{ const c=el('div','rcard evopt');
      c.appendChild(el('div','rt',o.t)); c.appendChild(el('div','rd',o.d));
      c.appendChild(el('div','rcta','TAKE'));
      c.onclick=()=>{ SFX.open(); logAction('eventChoose',[i]); eventChoose(S,i); render(); saveRun(); };
      c.onmouseenter=()=>SFX.hover(); kbAct(c); row.appendChild(c); });
    bx.appendChild(row);
  } else {
    bx.appendChild(el('div','evres',ev.res.msg));
    bx.appendChild(btn('big go','CONTINUE',()=>{ logAction('eventDone',[]); eventDone(S); render(); saveRun(); }));
  }
  bx.appendChild(partyStrip());
  ov.appendChild(bx);
  return ov;
}

/* ================= SHOP ================= */
function scShop(){
  const ov=el('div','overlay');
  const bx=el('div','rewardbox shop');
  bx.appendChild(ico('shop','evic'));
  bx.appendChild(el('h2',null,'CHIMERA MERCHANT'));
  bx.appendChild(el('div','sub',S.shards+' GENE SHARD'));
  const row=el('div','rrow wrap');
  S.shop.items.forEach((it,i)=>{
    const sold=S.shop.bought.includes(i), can=!sold&&S.shards>=it.cost;
    const c=el('div','rcard shopitem r'+it.rar+(sold?' sold':can?'':' dis'));
    c.appendChild(el('div','rbadge',RARITY[it.rar]));
    c.appendChild(ico(it.kind==='relic'?'chest':it.kind==='face'?'summon':it.kind==='heal'?'heal':'reroll','ricon'));
    c.appendChild(el('div','rt',it.n));
    c.appendChild(el('div','rd',it.d));
    if(it.arch&&ARCH[it.arch]){ const a=el('div','rarch',ARCH[it.arch].n); a.style.color=ARCH[it.arch].c; c.appendChild(a); }
    c.appendChild(el('div','rcost',sold?'SOLD'  :it.cost+' SHARD'));
    if(can){ c.onclick=()=>{ SFX.coin(); logAction('shopBuy',[i]); shopBuy(S,i); render(); saveRun(); }; kbAct(c); }
    row.appendChild(c);
  });
  bx.appendChild(row);
  bx.appendChild(btn('big go','LEAVE',()=>{ logAction('shopDone',[]); shopDone(S); render(); saveRun(); }));
  bx.appendChild(partyStrip());
  ov.appendChild(bx);
  return ov;
}

/* ================= END / RECAP ================= */
/* ================= LEADERBOARD (view) ================= */
let lbMode='short', lbAsc=0, lbState='idle', lbRows=[], lbConfigured=true;
/* Set of expanded row `rank`s (see scLeaderboard's build-reference accordion,
   same inline-expand pattern as historyExpanded above) — reset on every
   reload since `rank` is only unique within the CURRENT mode/ascension view. */
let lbExpanded=new Set();
async function loadLeaderboard(){
  lbState='busy'; lbExpanded.clear(); render();
  try{
    const r=await fetch('/api/leaderboard?mode='+lbMode+'&ascension='+lbAsc);
    const data=await r.json();
    lbRows=data.rows||[]; lbConfigured=data.configured!==false; lbState='done';
  }catch(e){ lbState='error'; lbRows=[]; }
  render();
}
function scLeaderboard(){
  const w=el('div','screen menu leaderboard');
  w.appendChild(el('h1','logo sm','LEADERBOARD'));
  w.appendChild(el('div','sub','Ranked Run scores · replayed and verified server-side, never trusted from the client'));
  const cfg=el('div','cfg');
  const modeBox=el('div','cfgrow'); modeBox.appendChild(el('span','cl','MODE'));
  ['short','full'].forEach(m=>{ const b=el('button','btn sm'+(lbMode===m?' on':''),m==='short'?'SHORT RUN':'FULL RUN');
    b.onclick=()=>{ SFX.ui(); lbMode=m; loadLeaderboard(); }; modeBox.appendChild(b); });
  cfg.appendChild(modeBox);
  const ascBox=el('div','cfgrow'); ascBox.appendChild(el('span','cl','ASCENSION'));
  for(let a=0;a<=10;a++){ const b=el('button','btn sm'+(lbAsc===a?' on':''),'A'+a);
    b.onclick=()=>{ SFX.ui(); lbAsc=a; loadLeaderboard(); }; ascBox.appendChild(b); }
  cfg.appendChild(ascBox);
  w.appendChild(cfg);
  if(lbState==='busy') w.appendChild(el('div','iempty','Loading…'));
  else if(lbState==='error') w.appendChild(el('div','iempty','Could not reach the server. Try again later.'));
  else if(!lbConfigured) w.appendChild(el('div','iempty','Leaderboard storage is not set up on this server yet — scores are computed but not saved. See README for setup.'));
  else if(!lbRows.length) w.appendChild(el('div','iempty','No Ranked Run scores yet for this Mode/Ascension — be the first.'));
  else{
    const tbl=el('div','lbtable');
    lbRows.forEach(row=>{
      const hasBuild=!!(row.team&&row.team.length);
      const open=lbExpanded.has(row.rank);
      const r=el('div','lbrow'+(row.won?' won':'')+(hasBuild?' expandable':'')+(open?' open':''));
      r.appendChild(el('div','lbrank','#'+row.rank));
      r.appendChild(el('div','lbname',row.name+(row.wallet?' 🔗':'')));
      r.appendChild(el('div','lbscore',String(row.score)));
      r.appendChild(el('div','lbstep',(row.won?'WON':'wave '+row.step)));
      if(hasBuild){
        r.onclick=()=>{ SFX.ui(); if(open) lbExpanded.delete(row.rank); else lbExpanded.add(row.rank); render(); };
        kbAct(r);
      }
      tbl.appendChild(r);
      if(open&&hasBuild){
        const d=el('div','lbdetail');
        teamRelicsSec(row).forEach(sec=>d.appendChild(sec));
        tbl.appendChild(d);
      }
    });
    w.appendChild(tbl);
  }
  w.appendChild(btn('','BACK',()=>{ screen='menu'; render(); }));
  return w;
}

/* ================= MATCH HISTORY (view) =================
   Local-only (see HK/saveRunHistory() comments in the META/onRunEnd section
   above). Rows are inline-expand (accordion), not a separate screen state —
   keeps Esc/ESC_TO_MENU_SCREENS simple (a second `screen` value for the
   detail view would need its own back-target and Esc handling; an expand
   toggle needs neither). */
let historyExpanded=new Set(); /* Set of entry.ts (unique per run) currently expanded */
function scHistory(){
  const w=el('div','screen menu history');
  w.appendChild(el('h1','logo sm','HISTORY'));
  const list=loadHistory();
  w.appendChild(el('div','sub',list.length+' run'+(list.length===1?'':'s')+' recorded on this device'));
  if(!list.length){
    w.appendChild(el('div','iempty','No runs yet — finish a run to see it here.'));
  } else {
    const toolrow=el('div','trow');
    toolrow.appendChild(btn('sm danger','CLEAR HISTORY',()=>{
      if(confirm('Clear all match history? This cannot be undone.')){ saveHistory([]); historyExpanded.clear(); render(); }
    }));
    w.appendChild(toolrow);
    const tbl=el('div','histlist');
    list.forEach(r=>{
      const open=historyExpanded.has(r.ts);
      const row=el('div','histrow'+(r.won?' won':'')+(open?' open':''));
      row.appendChild(el('div','histres',r.won?'WIN':'LOSS'));
      row.appendChild(el('div','histwave','Wave '+r.wave+'/'+r.len));
      row.appendChild(el('div','histdate',new Date(r.ts).toLocaleString()));
      const portraits=el('div','histteam');
      (r.team||[]).forEach(u=>{ const im=el('img','spr histspr'); im.src=sprOf(u.cls,u.artIdx); im.title=u.n+' T'+u.tier; portraits.appendChild(im); });
      row.appendChild(portraits);
      const chips=el('div','histarch');
      (r.archetypes||[]).slice(0,2).forEach(a=>{ const def=ARCH[a.key]; if(!def) return;
        const c=el('span','achip'); c.style.setProperty('--ac',def.c);
        c.appendChild(ico(ARCH_IC[a.key]||'buff','ai',def.c)); c.appendChild(el('span','an',def.n));
        chips.appendChild(c); });
      row.appendChild(chips);
      row.onclick=()=>{ SFX.ui(); if(open) historyExpanded.delete(r.ts); else historyExpanded.add(r.ts); render(); };
      kbAct(row);
      tbl.appendChild(row);
      if(open) tbl.appendChild(histDetail(r));
    });
    w.appendChild(tbl);
  }
  w.appendChild(btn('','BACK',()=>{ screen='menu'; render(); }));
  return w;
}
/* Dedicated small renderers from the saved plain data, rather than forcing
   partyStrip()/archStrip() (which read the live `S`/`buildUnit()` engine
   state) onto a lightweight fake context — the saved shape (already
   display-ready: `u.n/u.cls/u.tier/u.artIdx/u.die` as strings, `r.n/r.rar/r.d`)
   doesn't line up with what those functions expect closely enough to reuse
   cleanly. archScore() IS reused (in saveRunHistory()) for the archetype
   *selection*; only the presentational chip here is a small local copy of
   archStrip()'s chip markup. */
/* Shared by HISTORY's detail accordion and the Leaderboard's (see scLeaderboard
   below) — both work from the same plain, display-ready shape ({n,cls,tier,
   artIdx,die}[] / {n,rar,d}[]), just from different sources: HISTORY reads the
   client's own saveRunHistory() snapshot, Leaderboard reads api/submit-run.js's
   server-side replay output (see that file's team/relics comment) — the shape
   matching is what lets this one renderer serve both. */
function teamRelicsSec(r){
  const tsec=el('div','colsec'); tsec.appendChild(el('h3',null,'TEAM'));
  const tgrid=el('div','pstrip');
  (r.team||[]).forEach(u=>{
    const c=el('div','psc'); c.style.setProperty('--cc',CLASS_COLOR[u.cls]||'#888');
    const im=el('img','spr'); im.src=sprOf(u.cls,u.artIdx); c.appendChild(im);
    c.appendChild(el('div','nm',u.n+' T'+u.tier));
    const dv=el('div','minidie');
    (u.die||[]).forEach(fx=>dv.appendChild(el('span','mf',fx)));
    c.appendChild(dv);
    tgrid.appendChild(c);
  });
  tsec.appendChild(tgrid);

  const rsec=el('div','colsec'); rsec.appendChild(el('h3',null,'RELICS'));
  const rl=el('div','relicstrip');
  if(!r.relics||!r.relics.length) rl.appendChild(el('div','nothing','no relics'));
  (r.relics||[]).forEach(rr=>{ const c=el('div','rchip r'+rr.rar,rr.n); c.title=rr.d; rl.appendChild(c); });
  rsec.appendChild(rl);

  return [tsec,rsec];
}
function histDetail(r){
  const d=el('div','histdetail');
  teamRelicsSec(r).forEach(sec=>d.appendChild(sec));

  const ssec=el('div','colsec'); ssec.appendChild(el('h3',null,'STATS'));
  const rc=el('div','recap');
  const mk=(k,v)=>{ const c=el('div','rcstat'); c.appendChild(el('div','rv',String(v))); c.appendChild(el('div','rk',k)); return c; };
  const st=r.stats||{};
  rc.appendChild(mk('Damage dealt',st.dmg||0));
  rc.appendChild(mk('Damage taken',st.taken||0));
  rc.appendChild(mk('Biggest hit',st.maxHit||0));
  rc.appendChild(mk('Enemies killed',st.kills||0));
  rc.appendChild(mk('Turns played',st.turns||0));
  rc.appendChild(mk('Shard earned',r.shards||0));
  ssec.appendChild(rc);
  d.appendChild(ssec);

  const lsec=el('div','colsec'); lsec.appendChild(el('h3',null,'BATTLE LOG'));
  const log=r.log||[];
  if(!log.length){ lsec.appendChild(el('div','iempty','No log recorded for this run.')); }
  else {
    // Oldest-first, top-to-bottom — runLogEntries (src/log.js) accumulates in
    // that chronological order (push, not unshift), the opposite of the live
    // panel's newest-first convention, because a finished run's log reads
    // like a story here, not like an in-progress feed. clogBuildNode() is the
    // exact same renderer the live panel uses, reused verbatim.
    const body=el('div','histlogbody');
    log.forEach(e=>body.appendChild(clogBuildNode(e)));
    lsec.appendChild(body);
  }
  d.appendChild(lsec);
  return d;
}

/* ================= ACCOUNT (register/login/sync) ================= */
/* design/gdd/player-accounts.md, docs/architecture/adr-0002-player-accounts.md.
   Entirely additive — guests never see server calls from this screen unless
   they submit the form. Follows scImportAxie()'s form pattern (cfgrow+vform
   input row, vmsg status line). */
/* Shared login/register form body — used by both the mandatory gate (scGate,
   reached pre-auth) and the post-auth conflict/account screen (scAccount).
   opts.showBack controls whether a BACK-to-menu button is appended: the gate
   has no menu to go back to (there is no screen before it), scAccount's
   pre-auth branch does. */
function buildAuthForm(w, opts){
  opts=opts||{};
  const tabRow=el('div','cfgrow');
  [['login','LOG IN'],['register','REGISTER']].forEach(([m,label])=>{
    const b=el('button','btn sm'+(acctMode===m?' on':''),label);
    b.onclick=()=>{ SFX.ui(); acctMode=m; acctState='idle'; acctMsg=''; render(); };
    tabRow.appendChild(b);
  });
  w.appendChild(tabRow);

  const form=el('div','cfgrow vform');
  const uIn=el('input','seedinp'); uIn.placeholder='Username (3-20, a-z0-9_)'; uIn.value=acctUsername;
  uIn.oninput=e=>acctUsername=e.target.value;
  uIn.onkeydown=e=>{ if(e.key==='Enter') doAuth(acctMode); };
  form.appendChild(uIn);
  const pIn=el('input','seedinp'); pIn.type='password'; pIn.placeholder='Password (min 8 chars)'; pIn.value=acctPassword;
  pIn.oninput=e=>acctPassword=e.target.value;
  pIn.onkeydown=e=>{ if(e.key==='Enter') doAuth(acctMode); };
  form.appendChild(pIn);
  const goB=btn('sm go', acctMode==='login'?'LOG IN':'CREATE ACCOUNT', ()=>doAuth(acctMode));
  if(acctState==='busy') goB.classList.add('dis');
  form.appendChild(goB);
  w.appendChild(form);

  if(acctState==='busy') w.appendChild(el('div','vmsg vmsg-info','Working…'));
  if(acctState==='error') w.appendChild(el('div','vmsg vmsg-bad',acctMsg));
  if(acctMode==='register') w.appendChild(el('div','vmsg vmsg-info','Registering uploads this device\'s current progress as your first cloud save.'));

  if(opts.showBack) w.appendChild(btn('','BACK',()=>{ screen='menu'; render(); }));
}
/* Mandatory login gate (design/gdd/player-accounts.md §3 "App gate"). Reached
   only from boot with no cached token, or a 401 on the first authenticated
   call after boot (stale/expired token). No BACK button — deliberately: there
   is no prior screen to return to, PLAY and every other screen are unreachable
   until doAuth()/pullSyncAfterLogin() succeed and set screen='menu' themselves. */
function scGate(){
  const w=el('div','screen menu title gate');
  const inner=el('div','menu-inner');
  inner.appendChild(el('h1','logo','AXIE DICE TACTICS'));
  inner.appendChild(el('div','sub','Log in or create an account to play.'));
  if(gateMsg) inner.appendChild(el('div','vmsg vmsg-bad',gateMsg));
  buildAuthForm(inner,{showBack:false});
  w.appendChild(inner);
  return w;
}
/* Reachable only post-auth: the sync-conflict prompt (GDD §3 Login) after a
   pullSyncAfterLogin() finds divergent progress, or (pre-auth branch below,
   currently unreachable via any in-app navigation since the ACCOUNT menu tile
   was removed — kept for a possible future "switch account" entry point). */
function scAccount(){
  const w=el('div','screen menu vaultscreen');
  w.appendChild(el('h1','logo sm','ACCOUNT'));

  if(acctConflict){
    w.appendChild(el('div','sub','This device has progress newer than your cloud save. Choose which to keep — nothing is discarded silently.'));
    const row=el('div','cfgrow vform');
    row.appendChild(btn('cta','KEEP THIS DEVICE',()=>resolveConflictKeepLocal()));
    row.appendChild(btn('ghost','USE CLOUD SAVE',()=>resolveConflictUseCloud()));
    w.appendChild(row);
    return w;
  }

  if(authToken){
    w.appendChild(el('div','sub','Signed in as '+(authUsername||'?')+' · progress syncs automatically across devices'));
    w.appendChild(btn('ghost sm','LOG OUT',()=>doLogout()));
    w.appendChild(btn('','BACK',()=>{ screen='menu'; render(); }));
    return w;
  }

  w.appendChild(el('div','sub','Sync your Vault, Unlocks, Collection and Battle Pass across devices.'));
  buildAuthForm(w,{showBack:true});
  return w;
}

/* ================= LEADERBOARD SUBMISSION (Ranked Run only) ================= */
let submitState='idle', submitMsg='';
async function submitRun(){
  submitState='busy'; submitMsg=''; render();
  try{
    // Logged-in players submit under their account username automatically — closes
    // the free-text name-spoofing gap (ADR-0002 GDD Requirements Addressed).
    const nameToUse=(authToken&&authUsername)?authUsername:META.displayName;
    const body={ seed:S.runSeed, teamKeys:S.runTeamKeys, mode:S.mode, ascension:S.asc,
      actions:S.actionLog, displayName:nameToUse, walletAddr:roninAddr, engineVersion:ENGINE_VERSION };
    const r=await fetch('/api/submit-run',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
    const data=await r.json();
    if(!r.ok||!data.accepted){ submitState='error'; submitMsg=data.reason||'Submission rejected.'; render(); return; }
    submitState='done';
    submitMsg = data.stored? ('Submitted — Score '+data.score+'.') : ('Score computed ('+data.score+') but the leaderboard isn\'t configured on this server yet.');
    render();
  }catch(e){ submitState='error'; submitMsg='Network error — could not reach the server. Try again.'; render(); }
}
function scSubmitBox(){
  const b=el('div','submitbox');
  b.appendChild(el('div','ud','RANKED RUN — this score is eligible for the Leaderboard.'));
  if(authToken&&authUsername){
    b.appendChild(el('div','vwaddr','SIGNED IN AS '+authUsername.toUpperCase()));
  } else {
    const nameRow=el('div','vform');
    const inp=el('input','seedinp'); inp.placeholder='Display name'; inp.value=META.displayName||'';
    inp.oninput=e=>{ META.displayName=e.target.value.slice(0,24); saveMeta(); };
    nameRow.appendChild(inp);
    b.appendChild(nameRow);
  }
  if(roninAddr) b.appendChild(el('div','vwaddr','WALLET · '+shortAddr(roninAddr)));
  else if(typeof window.ronin!=='undefined') b.appendChild(btn('ghost sm','CONNECT RONIN WALLET (optional)',async()=>{ const a=await connectRonin(); if(a){ roninAddr=a; render(); } }));
  if(submitState==='idle'||submitState==='error'){
    b.appendChild(btn('cta','SUBMIT TO LEADERBOARD',()=>{
      if(!(authToken&&authUsername)&&!(META.displayName||'').trim()){ submitState='error'; submitMsg='Enter a display name first.'; render(); return; }
      submitRun();
    }));
  } else if(submitState==='busy'){ b.appendChild(el('div','vmsg vmsg-info','Submitting…')); }
  if(submitMsg) b.appendChild(el('div','vmsg '+(submitState==='error'?'vmsg-bad':'vmsg-info'),submitMsg));
  return b;
}

function scEnd(){
  const won=S.phase==='won';
  const ov=el('div','overlay');
  const bx=el('div','rewardbox end '+(won?'win':'lose'));
  bx.appendChild(el('h2',null,won?'LUNACIA CONQUERED':'YOUR TEAM HAS FALLEN'));
  bx.appendChild(el('div','sub',won?`Cleared all ${S.len} waves · Ascension ${S.asc}`
    :`Defeated on wave ${S.step} of ${S.len}`));
  /* death recap */
  const rc=el('div','recap');
  const mk=(k,v)=>{ const c=el('div','rcstat'); c.appendChild(el('div','rv',String(v))); c.appendChild(el('div','rk',k)); return c; };
  rc.appendChild(mk('Wave reached',S.step)); rc.appendChild(mk('Damage dealt',S.stat.dmg));
  rc.appendChild(mk('Damage taken',S.stat.taken)); rc.appendChild(mk('Biggest hit',S.stat.maxHit));
  rc.appendChild(mk('Enemies killed',S.stat.kills)); rc.appendChild(mk('Turns played',S.stat.turns));
  rc.appendChild(mk('Shard earned',S.shards));
  if(S.xpGain!=null) rc.appendChild(mk('Lunacia XP',+S.xpGain));
  bx.appendChild(rc);
  if(!won&&S.enemies.length){
    const killer=S.enemies.filter(e=>e.hp>0).sort((a,b)=>b.maxHp-a.maxHp)[0];
    if(killer){ const k=el('div','killer'); const im=el('img','spr mut'); im.src=sprMon(killer.key);
      k.appendChild(im); k.appendChild(el('div',null,'Killed by '+killer.n+(killer.boss?' (BOSS)':'')));
      bx.appendChild(k); }
  }
  bx.appendChild(el('div','buildsum','FINAL BUILD'));
  bx.appendChild(partyStrip());
  bx.appendChild(archStrip());
  if(S.ranked) bx.appendChild(scSubmitBox());
  const row=el('div','trow');
  row.appendChild(btn('big go','RETRY (same team)',()=>{ startRun(); }));
  row.appendChild(btn('','MENU',()=>{ screen='menu'; render(); }));
  if(S.seedStr) row.appendChild(btn('sm ghost','COPY SEED',()=>{ try{navigator.clipboard.writeText(S.seedStr);}catch(e){} flash('Seed copied: '+S.seedStr); render(); }));
  bx.appendChild(row);
  ov.appendChild(bx);
  if(won){ flashScreen('gold'); bigText('VICTORY','win'); }
  else { shake(3); flashScreen('dmg'); bigText('DEFEATED','lose'); }
  setTimeout(()=>won?SFX.win():SFX.lose(),100);
  return ov;
}

/* ================= TUTORIAL ================= */
const TUT=[
  {t:'A DIE IS AN AXIE',d:'Each Axie carries one six-sided die, and those six faces are its six body parts: Mouth, Horn, Back, Tail, Eyes and Ears. All five dice roll at the start of every turn.'},
  {t:'THE ENEMY SHOWS ITS HAND',d:'Enemies roll dice too, and whatever they roll is printed on their card: the number is the damage, the arrow is the target. You always see everything before you decide.'},
  {t:'USING A DIE',d:'Click a die, then click a target with a gold outline. You can also drag it straight onto the target. The preview shows exactly how much HP will be left. Made a mistake? Ctrl+Z undoes it.'},
  {t:'REROLLING',d:'Use the small button on a die to mark it, then press REROLL. Mark nothing and all of them are rerolled. Rerolling clears your undo history, so use it before you commit.'},
  {t:'RARITY LIVES ON THE FACE',d:'Rewards give you a new FACE, from Common all the way up to Mythic, and you choose which of the six faces it replaces. Collect Legendary faces and the die turns GOLDEN; a single Mythic face makes it COSMIC.'},
];
function tutOverlay(){
  const i=tut-1, t=TUT[i];
  const ov=el('div','overlay tutov');
  const bx=el('div','tutbox');
  bx.appendChild(el('div','tstep',(tut)+'/'+TUT.length));
  bx.appendChild(el('h2',null,t.t));
  bx.appendChild(el('div','td',t.d));
  const r=el('div','trow');
  r.appendChild(btn('sm ghost','SKIP',()=>{ tut=0; META.tut=1; saveMeta(); render(); }));
  r.appendChild(btn('big go',tut<TUT.length?'NEXT':'PLAY',()=>{ tut++; if(tut>TUT.length){ tut=0; META.tut=1; saveMeta(); } render(); }));
  bx.appendChild(r); ov.appendChild(bx);
  return ov;
}

/* ================= KEYS / BOOT ================= */
/* Leaf/single-purpose screens (each already has its own BACK/MENU button) —
   Esc backs out to the main menu from these, same as clicking that button.
   Deliberately excludes 'combat' (Esc there only deselects, never leaves a
   run) and 'menu'/'team' (no single obvious "back" destination). */
const ESC_TO_MENU_SCREENS=['codex','collection','unlocks','vault','guide','bp','leaderboard','account','history','profile'];
document.addEventListener('keydown',e=>{
  if(e.key==='Escape'){
    if(modal){ modal=null; render(); return; }
    sel=null; selRelic=null;
    if(ESC_TO_MENU_SCREENS.includes(screen)){ msg=''; screen='menu'; }
    render(); return;
  }
  if((e.key==='i'||e.key==='I')&&S&&screen==='combat'){ modal=(modal==='info'?null:'info'); render(); return; }
  if((e.key==='l'||e.key==='L')&&S&&screen==='combat'&&typeof clogSetOpen==='function'){ clogSetOpen(!clogOpen); render(); return; }
  if(modal) return;
  if(!S||S.phase!=='combat'||playing) return;
  if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==='z'){ e.preventDefault(); if(undo(S)){ logAction('undo',[]); sel=null; render(); } }
  else if(e.key==='r'||e.key==='R'){ const b=$('.btn.reroll'); if(b&&!b.classList.contains('dis')) b.click(); }
  else if(e.key===' '||e.key==='Enter'){ e.preventDefault(); const b=$('.btn.end'); if(b) b.click(); }
  else if(e.key>='1'&&e.key<='5'){ const u=S.party.filter(x=>x.side==='p')[+e.key-1]; if(u) clickDie(u); }
});
document.addEventListener('mousedown',e=>{ if(e.button===0&&rollAnim){ rollAnim.t0-=400; } });
window.addEventListener('load',()=>{ loadMeta();
  if(META.vol!=null) AU.vol=META.vol;
  if(META.mute) AU.on=false;
  if(META.spd) SPD=META.spd;
  if(META.tut)tut=0;
  // Mandatory login gate: no cached token -> show ONLY the gate, never the menu
  // (design/gdd/player-accounts.md §3). A cached token renders normally,
  // optimistically, while pullSyncAfterLogin verifies it server-side below.
  if(!authToken) screen='gate';
  render();
  if(authToken) pullSyncAfterLogin(false); });

/* ================= LUNACIA PASS ================= */
function scBP(){
  const w=el('div','screen menu bpscreen');
  w.appendChild(el('h1','logo sm','LUNACIA PASS'));
  const pr=bpProg();
  w.appendChild(el('div','sub','Level '+pr.lv+' of 30  ·  '+META.xp+' XP earned'+(META.equipped.title?'  ·  '+META.equipped.title:'')));
  const bar=el('div','bpbar big'); const f=el('div','bpfill'); f.style.width=pr.pct+'%'; bar.appendChild(f);
  bar.appendChild(el('div','bptxt',pr.lv<30?(pr.cur+' / '+pr.need+' XP to Level '+(pr.lv+1)):'MAX LEVEL'));
  w.appendChild(bar);
  const un=bpUnclaimed();
  if(un.length){ const cw=el('div','trow');
    cw.appendChild(btn('big go','CLAIM ALL ('+un.length+')',()=>{ un.forEach(bpClaim); SFX.passClaim(); flashScreen('gold'); render(); }));
    w.appendChild(cw); }
  const tr=el('div','bptrack');
  BP.forEach(b=>{
    const lv=pr.lv, got=META.bpClaimed.includes(b.lv), ready=b.lv<=lv&&!got;
    const c=el('div','bpnode'+(b.big?' big':'')+(got?' got':ready?' ready':' lock'));
    c.appendChild(el('div','bplv','Lv '+b.lv));
    const r=b.r;
    let icn='shard', txt='', sub='';
    if(r.t==='shard'){ icn='shard'; txt='+'+r.v; sub='GENE SHARD'; }
    else if(r.t==='unlock'){ const u=UNLOCKS.find(x=>x.id===r.v); icn='chest'; txt=u?u.n:'UNLOCK'; sub=u?u.d:''; }
    else if(r.t==='perk'){ icn='buff'; txt=r.n; sub='PERMANENT'; }
    else if(r.t==='face'){ const bf=BP_FACES[r.v]; icn='summon'; txt=bf.n; sub=bf.d; c.classList.add('mythic'); }
    // everything but the level header and the claim state sits in a fixed
    // icon/name/desc "body" zone so the icon lands at the same offset on
    // every card, whatever reward type it holds.
    const body=el('div','bpbody');
    const icow=el('div','bpicow'); icow.appendChild(ico(icn,'bpic')); body.appendChild(icow);
    body.appendChild(el('div','bpn',txt));
    if(sub) body.appendChild(el('div','bpd',sub));
    if(r.t==='face'){ const bf=BP_FACES[r.v];
      body.appendChild(el('div','bpface',faceText(bf.face)));
      const ar=ARCH[bf.arch]; if(ar){ const tg=el('div','rarch',ar.n); tg.style.color=ar.c; body.appendChild(tg); } }
    if(b.title) body.appendChild(el('div','bpttl','TITLE: '+b.title));
    c.appendChild(body);
    c.appendChild(el('div','bpstate',got?'CLAIMED':ready?'CLAIM':'LOCKED'));
    if(ready){ c.onclick=()=>{ bpClaim(b); if(r.t==='face'){ flashScreen('myth'); bigText('MYTHIC',''); SFX.mythic(); } else { SFX.passClaim(); flashScreen('gold'); } render(); }; kbAct(c); }
    tr.appendChild(c);
  });
  w.appendChild(tr);
  const info=el('div','tips');
  info.innerHTML=`<b>XP per run:</b> 30 to start &nbsp;·&nbsp; 10 per wave cleared &nbsp;·&nbsp; 30 per Elite &nbsp;·&nbsp; 60 per Boss &nbsp;·&nbsp; 150 for winning &nbsp;·&nbsp; 25 per Ascension level &nbsp;·&nbsp; 40 for a Full Run.
  <br><b>You earn XP even when you lose.</b> There is no season timer and no progress ever expires.
  <br><b>Five exclusive die faces</b> at levels 5, 12, 19, 26 and 30, each one built around a different playstyle.`;
  w.appendChild(info);
  w.appendChild(btn('','BACK',()=>{ screen='menu'; render(); }));
  return w;
}

/* ================= CODEX (tab layout) ================= */
let cxTab='basic', cxFilter='';
function cxH(t){ return el('h4','cxh',t); }
function cxP(html){ const d=el('div','cxp'); d.innerHTML=html; return d; }
function cxTable(head,rows,cls){
  // Column count must always match head.length: the grid template is derived
  // from the real number of columns instead of a hand-matched CSS class, so a
  // 3- or 4-column row can never overflow into the next row's first column
  // (that mismatch used to make a row's last cell visually collide with the
  // following row, e.g. the CLASS/PASSIVE/EFFECT table).
  const n=head.length;
  const gtc = n<=2 ? '150px 1fr' : '130px repeat('+(n-1)+',1fr)';
  const t=el('div','cxtable '+(cls||''));
  const mkRow=(cells,isHead)=>{
    const tr=el('div','cxtr'+(isHead?' cxhead':''));
    tr.style.gridTemplateColumns=gtc;
    cells.forEach(c=>{ const d=el('div','cxtd'); if(typeof c==='string') d.textContent=c; else if(c) d.appendChild(c); tr.appendChild(d); });
    return tr;
  };
  t.appendChild(mkRow(head,true));
  rows.forEach(r=>t.appendChild(mkRow(r,false)));
  return t;
}
const chip=(txt,col)=>{ const s2=el('span','cchip',txt); if(col){ s2.style.borderColor=col; s2.style.color=col; } return s2; };
const iconChip=(ic,txt,col)=>{ const s2=el('span','cchip ic'); s2.appendChild(ico(ic,'t',col)); s2.appendChild(el('span',null,txt));
  if(col){ s2.style.borderColor=col; s2.style.color=col; } return s2; };

const CX_TABS=[
  ['basic','THE BASICS'],['dice','DICE & BODY PARTS'],['mana','MANA & CARDS'],
  ['kw','KEYWORDS'],['st','STATUS EFFECTS'],['cls','CLASSES & PLAYSTYLES'],
  ['relic','RELIC TABLE'],['reward','MAP & REWARDS'],['boss','BOSSES'],['diff','DIFFICULTY & KEYS'],
];

function scCodex(){
  const w=el('div','screen menu codex');
  const top=el('div','cxtop');
  top.appendChild(el('h1','logo sm','CODEX'));
  top.appendChild(el('div','sub','Every rule in the game. Nothing is hidden.'));
  w.appendChild(top);
  const shell=el('div','cxshell');
  const nav=el('div','cxnav');
  CX_TABS.forEach(([k,n])=>{ const b=el('button','cxtab'+(cxTab===k?' on':''),n);
    b.onclick=()=>{ SFX.ui(); cxTab=k; render(); }; nav.appendChild(b); });
  nav.appendChild(btn('sm ghost','BACK',()=>{ screen='menu'; render(); }));
  shell.appendChild(nav);
  const pane=el('div','cxpane');
  pane.appendChild(CX_BODY[cxTab]());
  shell.appendChild(pane);
  w.appendChild(shell);
  return w;
}

const CX_BODY={
 basic:()=>{ const d=el('div');
  d.appendChild(cxH('A RUN'));
  d.appendChild(cxP(`A <b>run</b> is 12 waves (Short) or 20 waves (Full). Each wave you choose <b>one of two nodes</b> on the map,
   and after clearing it you pick <b>one of three rewards</b>. After every fight your party <b>heals to full and any fallen Axie is revived</b>,
   so the difficulty sits inside each individual fight rather than in slow attrition.<br>
   Losing ends the run, but you keep every Gene Shard and every point of Lunacia XP you earned.`));
  d.appendChild(cxH('A TURN IN COMBAT'));
  d.appendChild(cxTable(['STEP','WHAT HAPPENS'],[
    [chip('1 · ROLL','#ffd76a'),'All five of your dice and every enemy die roll at once. Whatever an enemy rolls is printed on its card, so its intent is public.'],
    [chip('2 · REROLL','#5fb8ff'),'Mark the dice you want to reroll using the small button on each one, then press REROLL. Mark nothing and every die is rerolled. You get two rerolls per turn by default.'],
    [chip('3 · ACT','#66e08a'),'Click a die then click a target, or drag it straight onto the target. Order is up to you. Ctrl+Z undoes anything.'],
    [chip('4 · END TURN','#ff5f5f'),'Enemies act out exactly the intent they showed, one at a time. Then status effects such as Poison, Burn and Regen tick.'],
  ]));
  d.appendChild(cxH('WHEN DOES UNDO STOP WORKING?'));
  d.appendChild(cxP(`You can undo as much as you like during your turn. The history is cleared at exactly two moments: when you press
   <b>REROLL</b> and when you press <b>END TURN</b>. Both create new randomness. If undo reached back past a reroll you could simply
   rewind until the dice came up perfect, and the game would stop meaning anything.<br>
   <span class="cnote">The relic <b>Infinite Die</b> breaks this rule: rerolling no longer clears your undo history.</span>`));
  d.appendChild(cxH('WINNING AND LOSING'));
  d.appendChild(cxTable(['','CONDITION'],[
    [chip('WIN A FIGHT','#66e08a'),'Every enemy is reduced to 0 HP.'],
    [chip('LOSE','#ff5f5f'),'All five of your main Axies are down. Summoned Axie Eggs do not count, so losing every Egg does not end the run.'],
    [chip('WIN THE RUN','#ffd76a'),'Defeat the final boss on wave 12 (Short) or wave 20 (Full).'],
  ]));
  return d; },

 dice:()=>{ const d=el('div');
  d.appendChild(cxH('A DIE IS AN AXIE'));
  d.appendChild(cxP(`Every Axie carries <b>one six-sided die</b>, and those six faces are its <b>six body parts</b>.
   Class does not decide which part sits on which face. Class decides the <b>distribution</b> of parts.
   Plant has several Back faces, Beast leans on Horn, Aqua on Ears. That is why two Axies of different classes play nothing alike.<br>
   The row of <b>six small squares</b> under each die shows all six faces, with the current one lit. Hover any square to read that face.
   The border colour tells you its rarity.`));
  d.appendChild(cxH('THE SIX PARTS'));
  d.appendChild(cxTable(['PART','ROLE'],[
    [iconChip('dmg','MOUTH'),'Single-target damage. Often carries Lifesteal.'],
    [iconChip('dmg','HORN'),'Your heaviest hits. Often carries Pierce or Heavy.'],
    [iconChip('shield','BACK'),'Shield for itself or an ally.'],
    [iconChip('poison','TAIL'),'Multi-target work: Cleave, area damage and Poison.'],
    [iconChip('heal','EYES'),'Utility: healing, debuffs and summoning.'],
    [iconChip('mana','EARS'),'Mana. Always triggers on its own without using your action.'],
    [iconChip('blank','BLANK'),'A dead face. Reroll it, or overwrite it with a Gene Mutation.'],
  ]));
  d.appendChild(cxH('RARITY LIVES ON THE FACE'));
  d.appendChild(cxP(`This is the biggest difference between this game and others like it: rarity is <b>not</b> a property of the die,
   it is a property of <b>each individual face</b>. A Gene Mutation reward hands you a new face and <b>you decide which of the six it replaces</b>.
   That is a real decision, and sometimes a painful one. Do you overwrite the blank, or the Shield face that has been carrying you?`));
  d.appendChild(cxTable(['TIER','DEFINITION','EXAMPLE'],
    RARITY.map((r,i)=>[chip(r,RAR_COL[i]),
      ['One action, no keywords','One keyword','Two keywords','Two keywords and a big number','Breaks a rule of the game'][i],
      ['MOUTH · Damage 6','HORN · Damage 7 · [Pierce]','HORN · Damage 10 · [Pierce + Crit 25%]','HORN · Damage 18 · [Heavy + Pierce]','TAIL · Poison 7 · [All + Plague]'][i]])));
  d.appendChild(cxH('GOLDEN AND COSMIC DICE'));
  d.appendChild(cxP(`The rarity of the <b>whole die</b> is simply the sum of its faces:<br>
   · <b>two or more Legendary faces</b> makes it a <span class="gold">GOLDEN DIE</span>, with a gold glowing border<br>
   · <b>a single Mythic face</b> makes it a <span class="cos">COSMIC DIE</span>, pulsing pink<br><br>
   In other words, <b>a beautiful die is something you build, not something you find.</b> Rarity here is an output of your decisions, not an input.`));
  d.appendChild(cxH('WHY CRIT IS SHOWN BEFORE YOU ATTACK'));
  d.appendChild(cxP(`Crit is decided the moment the die lands, and a <b>CRIT x2</b> badge appears on that face straight away.
   The reason is simple: the whole game rests on you seeing every piece of information before you commit. If crit were rolled
   when you pressed attack, you could no longer plan a turn.`));
  return d; },

 mana:()=>{ const d=el('div');
  d.appendChild(cxH('WHAT MANA IS FOR'));
  d.appendChild(cxP(`<b>Mana is a shared party resource</b>, not something an individual Axie owns. You spend it on
   <b>Lunacia Cards</b>, which are the relics with a button along the bottom bar. Put simply: your dice are what you do
   <i>every</i> turn, and Mana is the extra move you choose <i>when</i> to make.`));
  d.appendChild(cxH('EARNING MANA'));
  d.appendChild(cxTable(['SOURCE','DETAIL'],[
    [iconChip('mana','EARS faces'),'Your main source. Ears faces always trigger on their own the moment they land, and the die then rerolls itself for free. An Ears face never costs you an action.'],
    [chip('AQUA class','#4aa8d8'),'The CONDUIT passive adds 1 to every Mana gain. A team without Aqua cannot really run a Mana build.'],
    [chip('Mana keyword','#c78cff'),'Some faces grant Mana alongside their main effect.'],
    [chip('Keen Ears relic','#b8b2cc'),'All Mana faces give 1 more.'],
  ]));
  d.appendChild(cxH('THE RULES'));
  d.appendChild(cxTable(['RULE','WHAT IT MEANS'],[
    ['Carries over','Mana is not lost at the end of a turn. You can bank it for one big play.'],
    ['Resets each fight','Every new fight starts at 0 Mana. Saving Mana between fights does nothing.'],
    ['No cap','There is no maximum. The Mana orb glows and pulses once you reach 10.'],
    ['One use per card','Each Lunacia Card can be used once per turn, even if you could afford it twice.'],
  ]));
  d.appendChild(cxH('TWO WAYS TO CONVERT SPARE MANA'));
  d.appendChild(cxTable(['SOURCE','EFFECT'],[
    [chip('AQUA passive','#4aa8d8'),'Every 4 Mana you have SPENT this fight grants 1 Reroll. The more you spend, the more control you have over your dice.'],
    [chip('Overflow','#c78cff'),'The Mana Flood relic and the Mythic face ENDLESS EARS turn unspent Mana at the end of your turn into area damage equal to that amount.'],
  ]));
  d.appendChild(cxP(`<span class="cnote"><b>The common mistake</b> is hoarding Mana and never spending it. Without Overflow, idle Mana is
   wasted Mana, and with Aqua it also chokes off your reroll supply. The rule of thumb: <b>spend steadily, do not hoard.</b></span>`));
  d.appendChild(cxH('LUNACIA CARDS'));
  d.appendChild(cxTable(['CARD','COST','EFFECT'],
    RELICS.filter(r=>r.act).map(r=>[chip(r.n,RAR_COL[r.rar]),iconChip('mana',String(r.act.cost)),
      r.d.replace(/^\[MP \d+\]\s*/,'')])));
  return d; },

 kw:()=>{ const d=el('div');
  d.appendChild(cxH('KEYWORDS ON A FACE'));
  d.appendChild(cxP('Keywords are what turn an ordinary face into one you remember. They appear in gold text just below the number on the die.'));
  d.appendChild(cxH('TARGETING'));
  d.appendChild(cxTable(['KEYWORD','EFFECT'],[
    [chip('Cleave','#ffd76a'),'Full damage to the target and half to the two units next to it. Position matters here.'],
    [chip('All','#ffd76a'),'Hits every unit on that side. No target selection needed.'],
    [chip('Chain N','#ffd76a'),'N separate hits on random targets. High total damage, no control.'],
    [chip('Multi N','#ffd76a'),'Performs the action N times against the same target.'],
  ]));
  d.appendChild(cxH('DAMAGE'));
  d.appendChild(cxTable(['KEYWORD','EFFECT'],[
    [chip('Pierce','#e26fa8'),'Ignores Shield completely and hits HP directly.'],
    [chip('Execute','#e26fa8'),'60% more damage against a target below 50% HP.'],
    [chip('Vital','#e26fa8'),'Double value while the attacking Axie is at full HP.'],
    [chip('Crit N%','#ffd76a'),'An N% chance to deal double damage, rolled when the die lands and shown on the face.'],
    [chip('Lifesteal','#66e08a'),'Heals the attacker for the damage dealt.'],
  ]));
  d.appendChild(cxH('CHANGES OVER TIME'));
  d.appendChild(cxTable(['KEYWORD','EFFECT'],[
    [chip('Growth','#66e08a'),'Permanently gains 1 for the rest of the fight each time you use it. The longer the fight, the scarier the face.'],
    [chip('Decay','#ff5f5f'),'Loses 1 each time you use it. Strong early, weak later.'],
  ]));
  d.appendChild(cxH('SPECIAL RULES'));
  d.appendChild(cxTable(['KEYWORD','EFFECT'],[
    [chip('Cantrip','#5fb8ff'),'Triggers on its own the moment it lands, then the die rerolls itself for free. It never costs you an action.'],
    [chip('Heavy','#ffd76a'),'This die cannot be rerolled. In exchange the number is much higher.'],
    [chip('+Reroll','#5fb8ff'),'Using this face immediately gives you another Reroll.'],
    [chip('Self-damage N','#ff5f5f'),'The attacking Axie takes N piercing damage.'],
  ]));
  d.appendChild(cxH('MYTHIC — RULE BREAKERS'));
  d.appendChild(cxTable(['KEYWORD','WHAT IT BREAKS'],[
    [chip('Echo x2',RAR_COL[4]),'The face triggers twice from a single roll.'],
    [chip('Plague',RAR_COL[4]),'Poison from this face never loses stacks. It stays forever.'],
    [chip('Bastion',RAR_COL[4]),'Creating Shield also deals damage equal to the Shield value.'],
    [chip('Overflow',RAR_COL[4]),'Unspent Mana explodes into area damage at the end of your turn.'],
  ]));
  return d; },

 st:()=>{ const d=el('div');
  d.appendChild(cxH('HELPFUL EFFECTS'));
  d.appendChild(cxTable(['','EFFECT','RULE'],[
    [ico('shield','t'),'Shield','Absorbs damage before HP. It does NOT expire at the end of a turn, it stays until it is broken. Pierce ignores it entirely.'],
    [ico('regen','t'),'Regen N','Heals N at the end of the turn, then N drops by 1.'],
    [ico('thorns','t'),'Thorns N','Anything that attacks this unit takes N damage back. Reptile always has Thorns 2.'],
    [ico('undying','t'),'Undying','Survives one lethal hit at 1 HP.'],
  ]));
  d.appendChild(cxH('HARMFUL EFFECTS'));
  d.appendChild(cxTable(['','EFFECT','RULE'],[
    [ico('poison','t'),'Poison N','Deals N piercing damage at the end of the turn, then N drops by 1. This is cumulative damage, so the more stacks the deadlier it gets.'],
    [ico('burn','t'),'Burn N','Deals N damage at the end of the turn, then N is halved. Faster than Poison up front, but it burns out quickly.'],
    [ico('weaken','t'),'Weaken N','That unit deals N less damage per hit.'],
    [ico('vuln','t'),'Vulnerable N','That unit takes 50% more damage.'],
    [ico('blind','t'),'Blind N','All of that unit\\u2019s damage faces deal 0 for N turns. Devastating against a single-target boss.'],
    [ico('stun','t'),'Stun','The unit skips its turn entirely.'],
    [ico('freeze','t'),'Frozen','The die cannot be rerolled, but it can still be used. This constrains you rather than taking something away.'],
  ]));
  d.appendChild(cxP(`<span class="cnote">Poison and Burn both <b>pierce</b>, so Shield does not stop them. That is why even a Shield build
   has to deal with Poisoners quickly.</span>`));
  return d; },

 cls:()=>{ const d=el('div');
  d.appendChild(cxH('THE SIX CLASSES'));
  d.appendChild(cxP('A passive is what defines a playstyle. It is always on, needs no activation, and acts as the <b>engine</b> of its matching archetype.'));
  d.appendChild(cxTable(['CLASS','PASSIVE','EFFECT'],
    CLASSES.map(c=>[chip(c.toUpperCase(),CLASS_COLOR[c]),chip(PASSIVE[c].n,CLASS_COLOR[c]),PASSIVE[c].d])));
  d.appendChild(cxH('THREE TIERS PER CLASS'));
  d.appendChild(cxTable(['CLASS','T1','T2','T3'],
    CLASSES.map(c=>{ const k1=c+'1',k2=c+'2',k3=c+'3';
      return [chip(c.toUpperCase(),CLASS_COLOR[c]),
        HEROES[k1].n+' · HP '+HEROES[k1].hp, HEROES[k2].n+' · HP '+HEROES[k2].hp, HEROES[k3].n+' · HP '+HEROES[k3].hp]; }),
    'tiertable'));
  d.appendChild(cxP(`The <b>LEVEL UP</b> reward promotes one Axie to the next tier and <b>rewrites all six faces and its Max HP</b>.
   It is the single largest source of power in a run. Once an Axie is at T3 the reward becomes <b>ASCENSION</b> instead, which makes
   all six faces 25% stronger and stacks without limit.<br>
   <span class="cnote">Careful: Level Up overwrites faces you gained from Gene Mutation too. Think twice before mutating an Axie that is about to be promoted.</span>`));
  d.appendChild(cxH('THE TEN PLAYSTYLES'));
  d.appendChild(cxP('The <b>BUILD</b> bar at the top of the combat screen scores your playstyles live, based on your classes, relics and die faces.'));
  d.appendChild(cxTable(['PLAYSTYLE','DIRECTION'],
    Object.keys(ARCH).map(k=>[chip(ARCH[k].n,ARCH[k].c),ARCH[k].d])));
  return d; },

 relic:()=>{ const d=el('div');
  const tot=RELICS.length, act=RELICS.filter(r=>r.act).length;
  d.appendChild(cxH('THE FULL RELIC TABLE'));
  d.appendChild(cxP(`There are <b>${tot} relics</b> in total: <b>${tot-act} passives</b> that are always on and change a rule of the game,
   and <b>${act} active cards</b> that cost Mana. Relics apply to your <b>whole party</b>, never to a single Axie.
   You find them in rewards, at the Merchant, in Treasure nodes and through events.`));
  const cnt=[0,1,2,3].map(r=>RELICS.filter(x=>x.rar===r).length);
  const sum=el('div','cxsum');
  [0,1,2,3].forEach(r=>{ const b=el('div','cxsumbox'); b.style.borderColor=RAR_COL[r];
    b.appendChild(el('div','csv',String(cnt[r]))); b.appendChild(el('div','csk',RARITY[r])); sum.appendChild(b); });
  d.appendChild(sum);
  const fbar=el('div','cxfilter');
  fbar.appendChild(el('span','cl','FILTER BY PLAYSTYLE'));
  const mk=(k,n,c)=>{ const b=el('button','cxfb'+(cxFilter===k?' on':''),n);
    if(c){b.style.borderColor=c;b.style.color=c;} b.onclick=()=>{ SFX.ui(); cxFilter=(cxFilter===k?'':k); render(); }; return b; };
  fbar.appendChild(mk('','ALL'));
  Object.keys(ARCH).forEach(k=>fbar.appendChild(mk(k,ARCH[k].n,ARCH[k].c)));
  d.appendChild(fbar);
  [3,2,1,0].forEach(rar=>{
    let list=RELICS.filter(r=>r.rar===rar);
    if(cxFilter) list=list.filter(r=>r.a===cxFilter);
    if(!list.length) return;
    d.appendChild(cxH(RARITY[rar]+'  ·  '+list.length+' relics'));
    d.appendChild(cxTable(['NAME','PLAYSTYLE','EFFECT'],
      list.map(r=>[chip(r.n,RAR_COL[rar]),
        r.a&&ARCH[r.a]?chip(ARCH[r.a].n,ARCH[r.a].c):chip('-','#5a5378'),
        (r.act?'[CARD · '+r.act.cost+' MANA] ':'')+r.d.replace(/^\[MP \d+\]\s*/,'')]),'relictable'));
  });
  return d; },

 reward:()=>{ const d=el('div');
  d.appendChild(cxH('MAP NODES'));
  d.appendChild(cxP('Each wave offers two nodes. The two options are <b>always of different types</b>, so it is always a real decision and never two identical choices.'));
  d.appendChild(cxTable(['NODE','DESCRIPTION'],
    Object.keys(NODE_INFO).map(k=>[iconChip(NODE_INFO[k].ic,NODE_INFO[k].n,NODE_INFO[k].c),NODE_INFO[k].d])));
  d.appendChild(cxH('THE EIGHT REWARD TYPES'));
  d.appendChild(cxTable(['TYPE','EFFECT'],[
    [chip('LEVEL UP','#66e08a'),'Promotes an Axie to the next tier and rewrites all six faces and Max HP. The biggest power spike available.'],
    [chip('ASCENSION','#ffd76a'),'For an Axie already at T3: all six faces get 25% stronger, and it stacks without limit.'],
    [chip('GENE MUTATION','#c78cff'),'Replaces one face with a new one of a given rarity. You choose which face it overwrites.'],
    [chip('RUNE IMBUE','#5fb8ff'),'Adds one keyword to a face you already have.'],
    [chip('RELIC','#5fb8ff'),'An item that changes a rule of the game for your whole party.'],
    [chip('REROLL +1','#5fb8ff'),'Raises your maximum Rerolls per turn, up to 4.'],
    [chip('CHAOS DEAL',RAR_COL[4]),'A gamble: the party loses 20% Max HP for the rest of the run in exchange for an Epic or better relic.'],
    [chip('CURSE PACT',RAR_COL[4]),'A gamble: enemies gain 18% HP and 12% damage for the rest of the run, and every damage face deals 4 more plus 1 extra maximum Reroll.'],
  ]));
  d.appendChild(cxH('REROLLING REWARDS'));
  d.appendChild(cxP(`Once per wave you can <b>redraw all three options</b> if none of them fit your build.
   Without that safety valve a run would fail because of the draw rather than because of your decisions.`));
  d.appendChild(cxH('GENE SHARD'));
  d.appendChild(cxP(`The only currency in the game. You earn it during a run (25 from a normal fight, 45 from an Elite, 90 from a Boss, plus
   whatever events give you) and spend it at the <b>Merchant</b> mid-run. Whatever is left when the run ends is
   <b>added to your permanent wallet</b> and buys Unlocks from the main menu.`));
  return d; },

 boss:()=>{ const d=el('div');
  d.appendChild(cxH('SIX BOSSES, SIX MECHANICS'));
  d.appendChild(cxP(`A single run only meets 3 bosses (Short) or 4 (Full), and <b>the order is randomised every run</b>, so no two runs feel the same.
   The final boss is always NIGHTMARE AGONY.<br>
   <span class="cnote">Design principle: a boss should <b>constrain</b> you, never <b>destroy</b> what you built. Frost Lord freezes a die,
   so you can still use it but cannot reroll it. It never deletes a face. Losing a build you spent 30 minutes assembling is bad design.</span>`));
  d.appendChild(cxTable(['BOSS','MECHANIC'],BOSSES.map(b=>[chip(b.n,'#ff5f5f'),b.desc])));
  d.appendChild(cxH('THE CHIMERA ROSTER — NINE ROLES'));
  d.appendChild(cxTable(['ROLE','BEHAVIOUR'],[
    [chip('Bruiser','#ff8f8f'),'Straight damage. Half the time it goes for your healthiest Axie.'],
    [chip('Assassin','#ff8f8f'),'Always attacks your weakest Axie, and usually has Pierce or Execute. Kill it first.'],
    [chip('Tank','#5fb8ff'),'High HP and Shield, low damage, often with Thorns.'],
    [chip('Healer','#66e08a'),'Heals its most wounded ally. Kill it early or the fight drags forever.'],
    [chip('Poisoner','#8fdc4a'),'Applies Poison, which pierces Shield.'],
    [chip('Mage','#c78cff'),'Area damage and debuffs. Blind and Vulnerable are especially painful.'],
    [chip('Summoner','#b0a8d0'),'Calls in more enemies. Leave it alone and you get buried.'],
    [chip('Kamikaze','#ff9a4d'),'Low HP, one enormous area attack, then it dies. Kill it before it detonates.'],
    [chip('Buffer','#ffd76a'),'Enrages its allies for 25% more damage. Dangerous indirectly.'],
  ]));
  return d; },

 diff:()=>{ const d=el('div');
  d.appendChild(cxH('ASCENSION — THE DIFFICULTY CEILING'));
  d.appendChild(cxP(`Every run you win unlocks the next Ascension level. This is what lets broken builds exist without making the game boring:
   as your power grows, the ceiling grows with it.`));
  d.appendChild(cxTable(['LEVEL','MODIFIER (STACKING)'],ASCENSION.map(a=>[chip('A'+a.a,'#ff9ad1'),a.d])));
  d.appendChild(cxH('TWO RUN LENGTHS'));
  d.appendChild(cxTable(['MODE','LENGTH','BOSSES','ELITES'],[
    [chip('SHORT RUN','#66e08a'),'12 waves · about 15 min','Waves 4, 8, 12','Waves 3, 6, 10'],
    [chip('FULL RUN','#ffd76a'),'20 waves · about 35 min','Waves 5, 10, 15, 20','Waves 3, 7, 12, 17'],
  ]));
  d.appendChild(cxH('SHORTCUTS'));
  d.appendChild(cxTable(['KEY','ACTION'],[
    [chip('1 - 5','#ffd76a'),'Select the die of Axie 1 to 5'],
    [chip('R','#ffd76a'),'Reroll'],
    [chip('Space / Enter','#ffd76a'),'End turn'],
    [chip('Ctrl + Z','#ffd76a'),'Undo'],
    [chip('I','#ffd76a'),'Open the information panel'],
    [chip('Esc','#ffd76a'),'Close or deselect'],
    [chip('Hold mouse','#ffd76a'),'Fast-forward animations (4x)'],
    [chip('1x / 2x / 3x','#ffd76a'),'Buttons on the wave bar set the global animation speed'],
  ]));
  return d; },
};

/* ================= GUIDE — đội hình mẫu ================= */
function scGuide(){
  const w=el('div','screen menu guide');
  w.appendChild(el('h1','logo sm','SAMPLE TEAMS'));
  w.appendChild(el('div','sub','Four proven playstyles. Pick one to load it straight into team select.'));
  const g=el('div','guidegrid');
  GUIDES.forEach(G=>{
    const a=ARCH[G.arch];
    const c=el('div','gcard'); c.style.setProperty('--gc',a?a.c:'#ffd76a');
    c.appendChild(el('div','gname',G.n));
    c.appendChild(el('div','gdiff',G.diff));
    const tm=el('div','gteam');
    G.team.forEach((k,i)=>{ const h=HEROES[k];
      const u=el('div','gu'); u.style.setProperty('--cc',CLASS_COLOR[h.cls]);
      const im=el('img','spr'); im.src=sprOf(h.cls,h.art+(G.team.slice(0,i).filter(x=>x===k).length%3));
      u.appendChild(im); u.appendChild(el('div','gn',h.n)); tm.appendChild(u); });
    c.appendChild(tm);
    c.appendChild(el('div','gwhy',G.why));
    const ul=el('div','ghow');
    G.how.forEach(h=>{ const r=el('div','gh'); r.appendChild(el('span','gb','')); r.appendChild(el('span',null,h)); ul.appendChild(r); });
    c.appendChild(ul);
    c.appendChild(btn('sm go gbtn','USE THIS TEAM',()=>{ teamPick=G.team.slice(); screen='team'; render(); }));
    g.appendChild(c);
  });
  w.appendChild(g);
  w.appendChild(btn('','BACK',()=>{ screen='menu'; render(); }));
  return w;
}

/* ================= [4] SETTINGS + [MỚI] BẢNG THÔNG TIN TRONG TRẬN ================= */
let modal=null, infoTab='party', modalUid=null, railOpen=null;
let pendAvatarData=null, pendAvatarErr=null;

function closeModal(){ modal=null; pendAvatarData=null; pendAvatarErr=null; render(); }
function modalShell(title,sub,tabs,bodyFn){
  const ov=el('div','overlay modalov');
  ov.onclick=e=>{ if(e.target===ov) closeModal(); };
  const bx=el('div','modalbox');
  const hd=el('div','mdhead');
  const ti=el('div','mdtitle'); ti.appendChild(el('span',null,title));
  if(sub) ti.appendChild(el('span','mdsub',sub));
  hd.appendChild(ti);
  const x=el("button","btn xs ghost mdx","CLOSE"); x.onclick=closeModal; hd.appendChild(x);
  bx.appendChild(hd);
  if(tabs){ const tb=el('div','mdtabs');
    tabs.forEach(([k,n])=>{ const b=el('button','mdtab'+(infoTab===k?' on':''),n);
      b.onclick=()=>{ SFX.ui(); infoTab=k; render(); }; tb.appendChild(b); });
    bx.appendChild(tb); }
  const bd=el('div','mdbody'); bd.appendChild(bodyFn()); bx.appendChild(bd);
  ov.appendChild(bx);
  return ov;
}

/* ---------- BẢNG THÔNG TIN ---------- */
const INFO_TABS=[['party','YOUR TEAM'],['relic','YOUR RELICS'],['enemy','ENEMIES'],
  ['st','STATUS EFFECTS'],['kw','KEYWORDS'],['mana','MANA']];
function faceRow(u,f,i){
  const r=el('div','ifrow'+(u&&u.rolled===i?' cur':'')+' r'+(f.r||0));
  r.appendChild(el('div','ifn',String(i+1)));
  const ic=el('div','ific'); ic.appendChild(ico(FT_IC[f.t],'t')); r.appendChild(ic);
  r.appendChild(el('div','ifp',f.name||PARTN[f.p]||TYPEN[f.t]||'—'));
  r.appendChild(el('div','ifv', f.t==='blank'?'—':String(u?faceValue(S,u,i):f.v)));
  const kws=f.k.filter(k=>k!=='heavy');
  r.appendChild(el('div','ifk',kws.length?kws.map(kwText).join(' · '):''));
  if(f.r>=1) r.appendChild(el('div','ifr',RARITY[f.r]));
  return r;
}
/* Click any Axie on the board — yours or the enemy's — to read its whole die.
   The face it is showing right now is marked, so you can judge what it might
   roll next instead of memorising twenty monsters. */
function scUnitInfo(){
  const u = S && byUid(S,modalUid);
  if(!u) return el('div');
  const isE = u.side==='e';
  const sub = 'HP '+u.hp+'/'+u.maxHp + (u.shield?'  ·  Shield '+u.shield:'') + (isE?'':'  ·  Tier '+u.tier);
  return modalShell(u.n.toUpperCase(), sub, null, ()=>{
    const d=el('div','uinsp');
    const h=el('div','ic2h');
    const im=el('img','spr'+(isE?' mut':'')); im.src=isE?sprMon(u.key):sprOf(u.cls,u.artIdx); h.appendChild(im);
    const t=el('div','ic2t');
    if(!isE&&u.pas){ const p=el('div','ic2p'); p.appendChild(el('b',null,u.pas.n+': ')); p.appendChild(el('span',null,u.pas.d)); t.appendChild(p); }
    if(isE&&u.desc) t.appendChild(el('div','ic2s',u.desc));
    if(isE&&u.role) t.appendChild(el('div','ic2t','ROLE: '+u.role.toUpperCase()));
    const stx=Object.keys(ST_IC).filter(k=>u.st[k]>0);
    if(stx.length){ const sr=el('div','ic2st');
      stx.forEach(k=>{ const sp=el('span','st '+k); sp.appendChild(ico(ST_IC[k],'t'));
        sp.appendChild(el('span','stv',String(u.st[k]))); sp.title=ST_NAME[k]; sr.appendChild(sp); });
      t.appendChild(sr); }
    const dr=dieRarity(u);
    if(!isE&&dr>=3) t.appendChild(el('div','ic2dr'+dr,dr>=4?'COSMIC DIE':'GOLDEN DIE'));
    h.appendChild(t); d.appendChild(h);
    d.appendChild(cxP(isE
      ? 'Each face is one in six. Values are already scaled to this wave.'
      : 'Each face is one in six. Values already include buffs, relics and Growth.'));
    const fl=el('div','iflist');
    u.die.forEach((f,i)=>fl.appendChild(faceRow(u,f,i)));
    d.appendChild(fl);
    return d;
  });
}
function scInfo(){
  return modalShell('INFORMATION','Wave '+S.step+' of '+S.len+' · turn '+S.turn, INFO_TABS, ()=>{
    const d=el('div');
    if(infoTab==='party'){
      /* The build read-out lives here rather than on the board — it is worth
         checking between decisions, not on every single frame. */
      d.appendChild(archStrip());
      d.appendChild(cxP('Every face on every Axie. The face currently showing is <b>highlighted in gold</b>. Values already include buffs, relics and Growth.'));
      S.party.filter(u=>!u.token).forEach(u=>{
        const c=el('div','icard2'); c.style.setProperty('--cc',CLASS_COLOR[u.cls]||'#888');
        const h=el('div','ic2h');
        const im=el('img','spr'); im.src=sprOf(u.cls,u.artIdx); h.appendChild(im);
        const t=el('div','ic2t');
        t.appendChild(el('div','ic2n',u.n+' · T'+u.tier+(u.hp<=0?'  [DOWN]':'')));
        t.appendChild(el('div','ic2s','HP '+u.hp+'/'+u.maxHp+(u.shield?'  ·  Shield '+u.shield:'')));
        if(u.pas){ const p=el('div','ic2p'); p.appendChild(el('b',null,u.pas.n+': ')); p.appendChild(el('span',null,u.pas.d)); t.appendChild(p); }
        const stx=Object.keys(ST_IC).filter(k=>u.st[k]>0);
        if(stx.length){ const sr=el('div','ic2st');
          stx.forEach(k=>{ const sp=el('span','st '+k); sp.appendChild(ico(ST_IC[k],'t'));
            sp.appendChild(el('span','stv',String(u.st[k]))); sp.title=ST_NAME[k]; sr.appendChild(sp); });
          t.appendChild(sr); }
        h.appendChild(t);
        const dr=dieRarity(u);
        if(dr>=3) h.appendChild(el('div','ic2dr'+dr,dr>=4?'COSMIC DIE':'GOLDEN DIE'));
        c.appendChild(h);
        const fl=el('div','iflist'); u.die.forEach((f,i)=>fl.appendChild(faceRow(u,f,i))); c.appendChild(fl);
        d.appendChild(c);
      });
    }
    if(infoTab==='relic'){
      const list=S.relics.map(id=>RELIC_BY_ID[id]).filter(Boolean);
      d.appendChild(cxP('You are carrying <b>'+list.length+' relics</b>. Relics apply to your whole party.'));
      if(!list.length) d.appendChild(el('div','iempty','No relics yet. You get them from rewards, the Merchant and Treasure nodes.'));
      const act=list.filter(r=>r.act), pas=list.filter(r=>!r.act);
      if(act.length){ d.appendChild(cxH('LUNACIA CARDS — cost Mana ('+act.length+')'));
        d.appendChild(cxTable(['CARD','COST','EFFECT'],act.map(r=>{
          const used=S.usedActives.includes(r.id), can=S.mana>=r.act.cost&&!used;
          return [chip(r.n,RAR_COL[r.rar]), iconChip('mana',String(r.act.cost),can?'#66e08a':'#ff8f8f'),
            r.d.replace(/^\[MP \d+\]\s*/,'')+(used?'   (already used this turn)':can?'':'   (not enough Mana)')]; }))); }
      if(pas.length){ d.appendChild(cxH('PASSIVE — always on ('+pas.length+')'));
        d.appendChild(cxTable(['RELIC','PLAYSTYLE','EFFECT'],pas.map(r=>[
          chip(r.n,RAR_COL[r.rar]), r.a&&ARCH[r.a]?chip(ARCH[r.a].n,ARCH[r.a].c):chip('—','#5a5378'), r.d]),'relictable')); }
      const sc=archScore(S), keys=Object.keys(sc).filter(k=>sc[k]>0).sort((a,b)=>sc[b]-sc[a]);
      if(keys.length){ d.appendChild(cxH('CURRENT BUILD'));
        d.appendChild(cxTable(['PLAYSTYLE','SCORE','DIRECTION'],
          keys.map(k=>[chip(ARCH[k].n,ARCH[k].c),String(sc[k]),ARCH[k].d]))); }
    }
    if(infoTab==='enemy'){
      d.appendChild(cxP('Every face on every enemy, so you know in advance what it can roll. The face it is showing right now is highlighted in gold.'));
      S.enemies.forEach(e=>{
        const c=el('div','icard2 en'+(e.hp<=0?' dead':''));
        const h=el('div','ic2h');
        const im=el('img','spr mut'); im.src=sprMon(e.key); h.appendChild(im);
        const t=el('div','ic2t');
        t.appendChild(el('div','ic2n',e.n+(e.boss?'  [BOSS]':e.elite?'  [ELITE]':'')+(e.hp<=0?'  [DEAD]':'')));
        t.appendChild(el('div','ic2s','HP '+e.hp+'/'+e.maxHp+(e.shield?'  ·  Shield '+e.shield:'')+'  ·  role: '+(e.role||'-')));
        if(e.desc) t.appendChild(el('div','ic2p',e.desc));
        const stx=Object.keys(ST_IC).filter(k=>e.st[k]>0);
        if(stx.length){ const sr=el('div','ic2st');
          stx.forEach(k=>{ const sp=el('span','st '+k); sp.appendChild(ico(ST_IC[k],'t'));
            sp.appendChild(el('span','stv',String(e.st[k]))); sr.appendChild(sp); }); t.appendChild(sr); }
        h.appendChild(t); c.appendChild(h);
        const fl=el('div','iflist'); e.die.forEach((f,i)=>fl.appendChild(faceRow(e,f,i))); c.appendChild(fl);
        d.appendChild(c);
      });
    }
    if(infoTab==='st') d.appendChild(CX_BODY.st());
    if(infoTab==='kw') d.appendChild(CX_BODY.kw());
    if(infoTab==='mana') d.appendChild(CX_BODY.mana());
    return d;
  });
}

/* ---------- SETTINGS ---------- */
function scSettings(){
  return modalShell('SETTINGS',null,null,()=>{
    const d=el('div','setwrap');
    const row=(lbl,node)=>{ const r=el('div','setrow'); r.appendChild(el('div','setl',lbl)); r.appendChild(node); d.appendChild(r); };
    /* âm lượng */
    const vw=el('div','setctl');
    const vi=document.createElement('input'); vi.type='range'; vi.min=0; vi.max=100; vi.step=5;
    vi.value=Math.round((META.vol!=null?META.vol:0.28)*100/0.6*0.6*100/100*100)/100*1;
    vi.value=Math.round((META.vol!=null?META.vol:0.28)*167);
    const vv=el('span','setv',vi.value+'%');
    vi.oninput=()=>{ vv.textContent=vi.value+'%'; META.vol=(+vi.value)/167; AU.vol=META.vol; AU.on=+vi.value>0; saveMeta(); };
    vw.appendChild(vi); vw.appendChild(vv);
    const mb=el('button','btn sm'+(AU.on?'':' on'),AU.on?'SOUND ON':'SOUND OFF');
    mb.onclick=()=>{ AU.on=!AU.on; META.mute=!AU.on; saveMeta(); render(); };
    vw.appendChild(mb);
    row('VOLUME',vw);
    /* tốc độ */
    const sw=el('div','setctl');
    [1,2,3].forEach(v=>{ const b=el('button','btn sm'+(SPD===v?' on':''),v+'x');
      b.onclick=()=>{ SPD=v; META.spd=v; saveMeta(); render(); }; sw.appendChild(b); });
    row('ANIMATION SPEED',sw);
    /* photosensitivity: crit/Mythic flashScreen() + hitstop() screen punch */
    const flw=el('div','setctl');
    const fb=el('button','btn sm'+(META.reduceFlash?' on':''),META.reduceFlash?'FLASH: REDUCED':'FLASH: NORMAL');
    fb.title='Softens the full-screen flash on crits/Mythic pickups and the hit-stop punch. Also respects your OS "reduce motion" setting automatically.';
    fb.onclick=()=>{ META.reduceFlash=!META.reduceFlash; saveMeta(); render(); };
    flw.appendChild(fb);
    row('REDUCE FLASH EFFECTS',flw);
    /* tra cứu */
    const iw=el('div','setctl');
    iw.appendChild(btn('sm','INFORMATION',()=>{ modal='info'; render(); }));
    iw.appendChild(btn('sm','CODEX',()=>{ modal=null; screen='codex'; render(); }));
    row('REFERENCE',iw);
    /* run */
    const rw=el('div','setctl');
    rw.appendChild(btn('sm','SAVE & QUIT TO MENU',()=>{ saveRun(); modal=null; screen='menu'; render(); }));
    const ab=btn('sm danger','ABANDON RUN',()=>{
      if(confirm('Abandon this run? You keep the Gene Shard and XP you have already earned.')){
        S.phase='lost'; S.abandoned=true; onRunEnd(); modal=null; render(); } });
    rw.appendChild(ab);
    row('RUN',rw);
    d.appendChild(el('div','sethint','Shortcuts: I opens information · Esc closes · Space ends the turn · Ctrl+Z undoes'));
    return d;
  });
}
/* First use free, then RENAME_COST Gene Shard every time after — see the
   cost helpers above buildAvatarWrap(). Purely the display name shown on
   the menu corner/Profile; never touches the login username (an auth-system
   identifier — see api/auth.js, out of scope here). */
function scNameModal(){
  return modalShell('CHANGE NAME',null,null,()=>{
    const d=el('div','setwrap');
    const cost=nameChangeCost();
    d.appendChild(el('div','sethint',cost?('Costs '+cost+' Gene Shard — you have '+META.shards+'.'):'Free — your first name change.'));
    const inp=el('input','seedinp'); inp.maxLength=24; inp.placeholder='Display name';
    inp.value=META.displayName||authUsername||'';
    d.appendChild(inp);
    const err=el('div','sethint danger','');
    d.appendChild(err);
    const row=el('div','setctl');
    const canAfford=cost===0||META.shards>=cost;
    const ok=btn('sm'+(canAfford?'':' dis'),canAfford?'CONFIRM':('NEEDS '+cost+' SHARD'),()=>{
      if(!canAfford) return;
      if(!(inp.value||'').trim()){ err.textContent='Enter a name.'; return; }
      applyDisplayName(inp.value); closeModal();
    });
    if(!canAfford) ok.disabled=true;
    row.appendChild(ok);
    row.appendChild(btn('sm ghost','CANCEL',closeModal));
    d.appendChild(row);
    return d;
  });
}
/* First use free, then REAVATAR_COST every time after. Client-side downscale
   (readAvatarFile()) happens before the cost is even shown so the preview
   the player is paying for is the actual stored image. Never destroys a
   previous upload (see applyCustomAvatar()) — switching away and back is
   free via the "My Upload" tile in the Profile AVATARS grid. */
function scAvatarModal(){
  return modalShell('UPLOAD AVATAR',null,null,()=>{
    const d=el('div','setwrap');
    const cost=avatarChangeCost();
    if(!pendAvatarData){
      d.appendChild(el('div','sethint',cost?('Costs '+cost+' Gene Shard — you have '+META.shards+'.'):'Free — your first avatar upload.'));
      const inp=document.createElement('input'); inp.type='file'; inp.accept='image/*'; inp.style.display='none';
      inp.onchange=()=>{
        const f=inp.files&&inp.files[0]; if(!f) return;
        readAvatarFile(f,(dataUrl,e)=>{ pendAvatarData=dataUrl; pendAvatarErr=e; render(); });
      };
      d.appendChild(inp);
      d.appendChild(btn('sm','CHOOSE IMAGE',()=>inp.click()));
      if(pendAvatarErr) d.appendChild(el('div','sethint danger',pendAvatarErr));
      d.appendChild(btn('sm ghost','CANCEL',closeModal));
    } else {
      const prevW=el('div','profile-avatar-wrap'); const av=el('div','profile-avatar');
      const im=el('img','profile-avatar-img'); im.src=pendAvatarData; av.appendChild(im); prevW.appendChild(av);
      d.appendChild(prevW);
      d.appendChild(el('div','sethint',cost?('Costs '+cost+' Gene Shard — you have '+META.shards+'.'):'Free — your first avatar upload.'));
      const canAfford=cost===0||META.shards>=cost;
      const row=el('div','setctl');
      const ok=btn('sm'+(canAfford?'':' dis'),canAfford?'CONFIRM':('NEEDS '+cost+' SHARD'),()=>{
        if(!canAfford) return;
        applyCustomAvatar(pendAvatarData); pendAvatarData=null; pendAvatarErr=null; closeModal();
      });
      if(!canAfford) ok.disabled=true;
      row.appendChild(ok);
      row.appendChild(btn('sm ghost','RETAKE',()=>{ pendAvatarData=null; render(); }));
      row.appendChild(btn('sm ghost','CANCEL',closeModal));
      d.appendChild(row);
    }
    return d;
  });
}
