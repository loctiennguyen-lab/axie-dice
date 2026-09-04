#!/usr/bin/env node
/** verify.mjs — Axie Dice Tactics UI/UX conformance checker (from project doc) */
import { chromium } from 'playwright';
import { writeFileSync } from 'node:fs';

const argv = process.argv.slice(2);
const arg = (k, d) => { const i = argv.indexOf('--' + k); return i >= 0 ? argv[i + 1] : d; };
const URL       = arg('url', process.env.GAME_URL || 'http://localhost:5173');
const ONLY      = arg('only', null);
const JSON_OUT  = arg('json', null);
const HEADED    = argv.includes('--headed');

const DESKTOP = { width: 1440, height: 900 };
const PHONE   = { width: 393, height: 852 };
const TABLET  = { width: 744, height: 1133 };

const ALLOWED_FONT_SIZES = [11, 13, 15, 20, 28, 44, 34, 24];
const MIN_FONT_SIZE = 11;
const MIN_TAP = 44;
const AA_TEXT = 4.5;
const AA_LARGE = 3.0;
const AA_NONTEXT = 3.0;

const HELPERS = `
window.__V = (() => {
  const lin = c => { c/=255; return c <= 0.04045 ? c/12.92 : Math.pow((c+0.055)/1.055, 2.4); };
  const lum = ([r,g,b]) => 0.2126*lin(r) + 0.7152*lin(g) + 0.0722*lin(b);
  /* ---------- colour parsing ----------
     Chromium hands getComputedStyle() colours back in three different shapes and
     this function has to understand all of them, because anything it does NOT
     understand used to become pure white further down (see effFg) — an element
     then scored ~19:1 against a dark ground and PASSED having measured nothing.
     That is a false pass, the worst kind: the gate reports green while measuring
     nothing at all.

       legacy   "rgb(12, 34, 56)" / "rgba(12, 34, 56, 0.4)"
       modern   "rgb(12 34 56 / 40%)"   space-separated, slash alpha
       color()  "color(srgb 1 0.478431 0.478431 / 0.45)"  components are 0..1

     The color() form is what EVERY css color-mix() serialises to — verified in
     Chromium: color-mix(in srgb, #ff7a7a 45%, transparent) computes to
     "color(srgb 1 0.478431 0.478431 / 0.45)" in color, background-color AND
     border-color alike. src/style.css ships color-mix() today, so before this
     was fixed contrast scoring on those surfaces was vacuous.

     Anything still not understood (oklch/oklab/lab/lch/hwb, color() in a space
     other than srgb) is recorded in unparsed[] and reported by colorProblems()
     as a hard contrast FAILURE rather than being guessed at. Guessing is what
     put us in the hole; a loud failure forces whoever introduces such a colour
     to extend this function. */
  const unparsed = new Set();
  const clamp = (v, hi) => Math.max(0, Math.min(hi, v));
  const comp = (tok, scale) => {
    const t = String(tok == null ? '' : tok).trim();
    if (!t) return NaN;
    if (t === 'none') return 0;                       /* color(srgb none 0 0) */
    return t.endsWith('%') ? parseFloat(t) / 100 * scale : parseFloat(t);
  };
  const parse = s => {
    const str = String(s == null ? '' : s).trim();
    if (!str) return null;
    if (str === 'transparent') return { rgb: [0,0,0], a: 0 };
    let m = str.match(/^color\\(\\s*(srgb|srgb-linear)\\s+([^)]*)\\)$/i);
    if (m) {
      const [head, tail] = m[2].split('/');
      let rgb = head.trim().split(/\\s+/).filter(Boolean).slice(0,3).map(t => comp(t, 1));
      const a = tail == null ? 1 : comp(tail, 1);
      if (m[1].toLowerCase() === 'srgb-linear')
        rgb = rgb.map(v => v <= 0.0031308 ? v * 12.92 : 1.055 * Math.pow(v, 1/2.4) - 0.055);
      rgb = rgb.map(v => clamp(v * 255, 255));
      if (rgb.length < 3 || rgb.some(v => !Number.isFinite(v)) || !Number.isFinite(a)) { unparsed.add(str); return null; }
      return { rgb, a: clamp(a, 1) };
    }
    m = str.match(/^rgba?\\(([^)]*)\\)$/i);
    if (m) {
      const [head, tail] = m[1].split('/');
      const toks = head.trim().split(/[\\s,]+/).filter(Boolean);
      const rgb = toks.slice(0,3).map(t => clamp(comp(t, 255), 255));
      const a = tail != null ? comp(tail, 1) : (toks.length > 3 ? comp(toks[3], 1) : 1);
      if (rgb.length < 3 || rgb.some(v => !Number.isFinite(v)) || !Number.isFinite(a)) { unparsed.add(str); return null; }
      return { rgb, a: clamp(a, 1) };
    }
    unparsed.add(str);
    return null;
  };

  /* Every colour that actually decides an element's measured contrast, checked
     for parseability. A null here means the measurement below it is a guess, so
     the caller turns it into a failure instead of a 19:1 "pass". */
  function colorProblems(el) {
    const out = [];
    const own = getComputedStyle(el).color;
    if (own && !parse(own)) out.push('color: ' + own);
    let e = el;
    while (e && e !== document.documentElement) {
      const raw = getComputedStyle(e).backgroundColor;
      const c = parse(raw);
      if (!c) { out.push('background-color: ' + raw + ' on .' + (e.className || e.tagName)); }
      else if (c.a >= 1) break;
      e = e.parentElement;
    }
    return out;
  }
  const over = (fg, bg, a) => fg.map((v,i) => v*a + bg[i]*(1-a));
  const contrast = (a, b) => { const la = lum(a), lb = lum(b); const hi = Math.max(la,lb), lo = Math.min(la,lb); return (hi+0.05)/(lo+0.05); };

  function effBg(el) {
    const stack = [];
    let e = el;
    while (e && e !== document.documentElement) {
      const cs = getComputedStyle(e);
      const c = parse(cs.backgroundColor);
      if (c && c.a > 0) stack.push(c);
      if (c && c.a >= 1) break;
      e = e.parentElement;
    }
    let base = [11,13,16];
    const rootBg = parse(getComputedStyle(document.documentElement).backgroundColor);
    if (rootBg && rootBg.a >= 1) base = rootBg.rgb;
    let out = base;
    for (let i = stack.length - 1; i >= 0; i--) out = over(stack[i].rgb, out, stack[i].a);
    return out.map(Math.round);
  }

  function effFg(el) {
    const cs = getComputedStyle(el);
    const c = parse(cs.color) || { rgb:[255,255,255], a:1 };
    let a = c.a;
    let e = el;
    while (e && e !== document.documentElement) { a *= parseFloat(getComputedStyle(e).opacity); e = e.parentElement; }
    return over(c.rgb, effBg(el), Math.max(0, Math.min(1, a))).map(Math.round);
  }

  const visible = el => {
    const r = el.getBoundingClientRect();
    if (r.width < 1 || r.height < 1) return false;
    const cs = getComputedStyle(el);
    return cs.visibility !== 'hidden' && cs.display !== 'none' && parseFloat(cs.opacity) > 0.02;
  };

  const textLeaves = () => [...document.querySelectorAll('#app *, #app')]
    .filter(el => visible(el)
      && [...el.childNodes].some(n => n.nodeType === 3 && n.textContent.trim())
      && el.textContent.trim().length);

  const interactive = () => [...document.querySelectorAll(
      'button, a[href], input, select, textarea, [role=button], [role=option], [tabindex]:not([tabindex="-1"]), .btn, .die, .unit, .rsel, .pick, .nodecard, .cxtab, .tnode'
    )].filter(visible);

  function tapBox(el) {
    const r = el.getBoundingClientRect();
    let w = r.width, h = r.height;
    const own = getComputedStyle(el);
    if (own.position === 'static') return { w, h, expandedBy: null };
    for (const pseudo of ['::before','::after']) {
      const ps = getComputedStyle(el, pseudo);
      if (ps.content === 'none' || ps.position !== 'absolute') continue;
      const num = v => { const n = parseFloat(v); return Number.isFinite(n) ? n : 0; };
      const pw = num(ps.width), ph = num(ps.height);
      if (pw > w || ph > h) { w = Math.max(w, pw); h = Math.max(h, ph); return { w, h, expandedBy: pseudo }; }
      const dx = -(num(ps.left) + num(ps.right)), dy = -(num(ps.top) + num(ps.bottom));
      if (dx > 0 || dy > 0) { w += Math.max(0,dx); h += Math.max(0,dy); return { w, h, expandedBy: pseudo }; }
    }
    return { w, h, expandedBy: null };
  }

  const isDisabled = el => !!(el.closest('[disabled],.dis,[aria-disabled="true"]'));

  /* ---------- transient recorder ----------
     This file checks by SNAPSHOT, so any element that appears and vanishes
     between two snapshots is never inspected at all. The concrete case that
     exposed it: the relic activation badges in src/fx.js (relicBadge(), held
     RELIC_FX_HOLD = 600ms) passed no check because no check ever saw them —
     "the suite is green" and "the badge is compliant" were different claims and
     only a hand audit ever established the second.

     The observer below closes that for every transient element, present and
     future. From page load it records every element added under #app and, while
     that element lives, samples it every SAMPLE_MS. It keeps the sample from the
     moment the element is MOST legible (highest effective alpha), so an entry or
     exit fade is never mistaken for a contrast failure — the question asked is
     "at its best, was this readable?".

     An entry that outlives TRANSIENT_MS is dropped: it is ordinary UI and the
     snapshot checks already own it. An entry that dies inside that window is
     promoted to a finding and judged under exactly the same rules as static UI
     (type scale, contrast, overflow). An entry that lived long enough to be seen
     (ESCAPE_MS) but was never successfully sampled is recorded as an ESCAPE and
     fails the gate — that is the invariant that keeps this from rotting back
     into the hole it fixes: a transient element is either measured or it is a
     failure, never silently absent. */
  const TRANSIENT_MS = 1200, SAMPLE_MS = 40, ESCAPE_MS = 100, MAX_TRACK = 60, MAX_LEAVES = 12;
  const tPending = [];
  const tFindings = new Map();
  const tEscapes  = new Map();
  let   tSeen = 0;

  const effAlpha = el => {
    let a = 1, e = el;
    while (e && e !== document.documentElement) { const o = parseFloat(getComputedStyle(e).opacity); a *= Number.isFinite(o) ? o : 1; e = e.parentElement; }
    return Math.max(0, Math.min(1, a));
  };

  /* The opacity an element REACHES, not the one it happens to have when the
     sampler looks. A floating combat number spends its whole life inside a fade
     (0 -> 1 -> 0); polling it can only ever catch an arbitrary point on that
     curve, and judging contrast there measures the sampler's timing rather than
     the design. The peak is read from the animation's own keyframes, so it is
     exact and independent of when we look. Ancestor opacity is still multiplied
     in at its live value — a badge on an Axie Egg really is at .85, and that is
     the number the rule has to be applied to. */
  const peakOpacity = el => {
    let o = parseFloat(getComputedStyle(el).opacity);
    if (!Number.isFinite(o)) o = 1;
    try {
      for (const an of el.getAnimations()) {
        for (const kf of an.effect.getKeyframes()) {
          if (kf.opacity == null) continue;
          const v = parseFloat(kf.opacity);
          if (Number.isFinite(v)) o = Math.max(o, v);
        }
      }
    } catch (e) {}
    return Math.max(0, Math.min(1, o));
  };
  const peakAlpha = el => {
    let a = peakOpacity(el), e = el.parentElement;
    while (e && e !== document.documentElement) { const o = parseFloat(getComputedStyle(e).opacity); a *= Number.isFinite(o) ? o : 1; e = e.parentElement; }
    return Math.max(0, Math.min(1, a));
  };

  const tLeaves = root => {
    if (root.nodeType !== 1) return [];
    const all = [root, ...root.querySelectorAll('*')];
    const out = [];
    for (const el of all) {
      if ([...el.childNodes].some(n => n.nodeType === 3 && n.textContent.trim())) out.push(el);
      if (out.length >= MAX_LEAVES) break;
    }
    return out;
  };

  function tSample(entry) {
    entry.examined = true;          /* the recorder LOOKED at it — see tFinalise */
    for (const el of tLeaves(entry.node)) {
      if (!visible(el)) continue;
      const a = peakAlpha(el);
      const sig = (el.className || el.tagName) + ' | ' + el.textContent.trim().slice(0, 24);
      const prev = entry.best[sig];
      if (prev && prev.alpha >= a) continue;
      const cs = getComputedStyle(el);
      const r = el.getBoundingClientRect();
      entry.best[sig] = { sig, alpha: +a.toFixed(3), fs: parseFloat(cs.fontSize),
        bold: parseInt(cs.fontWeight, 10) >= 700,
        cls: el.className || el.tagName, txt: el.textContent.trim().slice(0, 24),
        fg: over(parse(getComputedStyle(el).color) ? parse(getComputedStyle(el).color).rgb : [255,255,255], effBg(el), a),
        bg: effBg(el), right: Math.round(r.right), disabled: isDisabled(el),
        problems: colorProblems(el), host: (entry.node.parentElement && entry.node.parentElement.className) || '' };
      entry.sampled = true;
    }
  }

  let tChurn = 0;
  function tFinalise(entry, now) {
    const life = now - entry.t0;
    if (life > TRANSIENT_MS) return;                 /* not transient — snapshot checks own it */
    if (!entry.examined) {
      /* Never even looked at while it was alive: that is the one outcome this
         recorder must not tolerate, because it is the original bug. Elements
         that WERE examined but carried no visible text are not escapes — there
         was simply nothing to audit. */
      if (life >= ESCAPE_MS) {
        const sig = (entry.node.className || entry.node.tagName || '?') + '';
        tEscapes.set(sig, { sig, life: Math.round(life) });
      }
      return;
    }
    /* src/ui.js re-renders a whole screen on every state change, so ordinary,
       persistent UI is destroyed and rebuilt constantly — a spent die's node
       lives 300ms even though a spent die is on screen for the rest of the
       turn. That is DOM churn, not transient UI. If an element with the same
       class is still on screen after this one died, it was replaced rather than
       dismissed, and the snapshot checks measure its settled state properly;
       judging the discarded node mid-transition would measure the re-render.
       Nothing is lost here, only attributed to the right check. */
    const stillOnScreen = b => {
      const first = String(b.cls || '').split(/\s+/).filter(Boolean)[0];
      if (!first) return false;
      try {
        for (const el of document.querySelectorAll('.' + CSS.escape(first)))
          if (el.textContent.trim().slice(0, 24) === b.txt && visible(el)) return true;
      } catch (e) {}
      return false;
    };
    for (const k of Object.keys(entry.best)) {
      const b = entry.best[k];
      /* identical element still on screen => it was re-rendered, not dismissed */
      if (stillOnScreen(b)) { tChurn++; continue; }
      b.life = Math.round(life);
      const old = tFindings.get(b.sig);
      /* keep the WORST-contrast sighting of each distinct element */
      if (!old || contrast(b.fg, b.bg) < contrast(old.fg, old.bg)) tFindings.set(b.sig, b);
      tSeen++;
    }
  }

  setInterval(() => {
    if (!tAttached) return;
    const now = performance.now();
    for (let i = tPending.length - 1; i >= 0; i--) {
      const e = tPending[i];
      if (!e.node.isConnected) { tFinalise(e, now); tPending.splice(i, 1); continue; }
      if (now - e.t0 > TRANSIENT_MS) { tPending.splice(i, 1); continue; }
      try { tSample(e); } catch (err) { /* an element can vanish mid-sample */ }
    }
  }, SAMPLE_MS);

  /* Attach lazily and defensively. This whole file is injected by
     addInitScript, which runs BEFORE the page's own scripts — at that moment
     document.documentElement can still be null, and an exception here would
     abort the IIFE, leave window.__V undefined and take the ENTIRE suite down
     with "Cannot read properties of undefined (reading 'textLeaves')" on the
     first check. The recorder is an addition to the gate; it must never be able
     to break the checks that were already there. If it cannot attach, the
     transient checks fail loudly on their own instead. */
  let tAttached = false;
  (function attach() {
    try {
      const root = document.documentElement || document.body;
      if (!root) { setTimeout(attach, 0); return; }
      new MutationObserver(muts => {
        const now = performance.now();
        for (const m of muts) for (const n of m.addedNodes) {
          if (n.nodeType !== 1 || tPending.length >= MAX_TRACK) continue;
          tPending.push({ node: n, t0: now, best: {}, sampled: false });
        }
      }).observe(root, { childList: true, subtree: true });
      tAttached = true;
    } catch (e) { setTimeout(attach, 50); }
  })();

  const transientReport = () => ({
    findings: [...tFindings.values()],
    escapes: [...tEscapes.values()],
    seen: tSeen, pending: tPending.length, attached: tAttached, churn: tChurn
  });

  return { contrast, effBg, effFg, over, visible, textLeaves, interactive, tapBox, isDisabled,
           parse, colorProblems, unparsedColors: () => [...unparsed],
           transientReport, effAlpha,
           rgbHex: c => '#' + c.map(v => Math.round(v).toString(16).padStart(2,'0')).join('') };
})();
`;

const results = [];
let consoleErrors = [];

function record(id, phase, title, pass, detail, required = true) {
  results.push({ id, phase, title, pass: !!pass, required, detail });
  const tag = pass ? '\x1b[32mPASS\x1b[0m' : (required ? '\x1b[31mFAIL\x1b[0m' : '\x1b[33mWARN\x1b[0m');
  console.log(`${tag}  ${id}  ${title}`);
  if (!pass && detail) String(detail).split('\n').slice(0, 12).forEach(l => console.log('        ' + l));
}

const want = phase => !ONLY || ONLY.toUpperCase().includes(phase);

async function clickText(page, text, timeout = 4000) {
  const loc = page.locator(`text="${text}"`).first();
  try { await loc.waitFor({ state: 'visible', timeout }); await loc.click({ timeout }); return true; }
  catch { return false; }
}

async function reachCombat(page) {
  const trail = [];
  await page.waitForTimeout(600);
  trail.push('menu');
  if (!(await clickText(page, 'NEW RUN'))) await clickText(page, 'PLAY');
  await page.waitForTimeout(500);
  trail.push('team-select');
  const go = page.locator('.go, button:has-text("START RUN")').first();
  if (await go.count()) { await go.click().catch(()=>{}); await page.waitForTimeout(600); trail.push('map'); }
  const node = page.locator('.nodecard, [class*=nodecard]').first();
  if (await node.count()) { await node.click().catch(()=>{}); await page.waitForTimeout(900); trail.push('combat'); }
  const inCombat = await page.locator('.die').count() > 0;
  return { trail, inCombat };
}

async function checkFontSizes(page, label, phase = 'A') {
  const bad = await page.evaluate(({ min, allowed }) => {
    return window.__V.textLeaves().map(el => {
      const fs = parseFloat(getComputedStyle(el).fontSize);
      return { fs, cls: el.className || el.tagName, txt: el.textContent.trim().slice(0, 30) };
    }).filter(o => o.fs < min || !allowed.includes(Math.round(o.fs)));
  }, { min: MIN_FONT_SIZE, allowed: ALLOWED_FONT_SIZES });
  record(`A1.${label}`, phase, `[${label}] Không có chữ < ${MIN_FONT_SIZE}px và mọi cỡ đều thuộc thang`,
    bad.length === 0,
    bad.slice(0, 10).map(o => `${o.fs}px · .${o.cls} · "${o.txt}"`).join('\n') + (bad.length > 10 ? `\n… +${bad.length - 10} nữa` : ''));
}

async function checkContrast(page, label, phase = 'A') {
  const bad = await page.evaluate(({ aa, aaLarge }) => {
    const out = [];
    for (const el of window.__V.textLeaves()) {
      const cs = getComputedStyle(el);
      const fs = parseFloat(cs.fontSize);
      /* A colour the model cannot read is NOT a pass — it used to default to
         white and score ~19:1. Fail it loudly instead, naming the colour. */
      const probs = window.__V.colorProblems(el);
      if (probs.length) { out.push({ cr: null, need: aa, fs, fg: '?', bg: '?', unparsed: probs.join(' + '),
        cls: el.className || el.tagName, txt: el.textContent.trim().slice(0, 28), disabled: false }); continue; }
      const bold = parseInt(cs.fontWeight, 10) >= 700;
      const large = fs >= 24 || (bold && fs >= 18.66);
      const disabled = window.__V.isDisabled(el);
      const need = disabled ? aaLarge : (large ? aaLarge : aa);
      const fg = window.__V.effFg(el), bg = window.__V.effBg(el);
      const cr = window.__V.contrast(fg, bg);
      if (cr < need - 0.005) out.push({
        cr: +cr.toFixed(2), need, fs,
        fg: window.__V.rgbHex(fg), bg: window.__V.rgbHex(bg),
        cls: el.className || el.tagName, txt: el.textContent.trim().slice(0, 28), disabled
      });
    }
    return out.sort((a, b) => (a.cr == null ? -1 : b.cr == null ? 1 : a.cr - b.cr));
  }, { aa: AA_TEXT, aaLarge: AA_LARGE });
  record(`A2.${label}`, phase, `[${label}] Mọi chữ đạt contrast AA`,
    bad.length === 0,
    bad.slice(0, 12).map(o => o.unparsed
        ? `KHÔNG ĐO ĐƯỢC — màu ${o.unparsed} không parse được (xem parse() trong HELPERS) · .${o.cls} · "${o.txt}"`
        : `${o.cr}:1 (cần ${o.need}${o.disabled ? ', disabled' : ''}) ${o.fs}px ${o.fg} trên ${o.bg} · .${o.cls} · "${o.txt}"`).join('\n')
      + (bad.length > 12 ? `\n… +${bad.length - 12} nữa` : ''));
}

async function checkTapTargets(page, label, vp, phase = 'B') {
  const bad = await page.evaluate(min => window.__V.interactive().filter(el => !window.__V.isDisabled(el)).map(el => {
    const t = window.__V.tapBox(el);
    return { w: Math.round(t.w), h: Math.round(t.h), by: t.expandedBy,
             cls: el.className || el.tagName, txt: (el.textContent || '').trim().slice(0, 22) };
  }).filter(o => o.w < min || o.h < min), MIN_TAP);
  record(`B1.${label}`, phase, `[${label} ${vp.width}px] Mọi vùng chạm ≥ ${MIN_TAP}×${MIN_TAP}`,
    bad.length === 0,
    bad.slice(0, 12).map(o => `${o.w}×${o.h}${o.by ? ' (pseudo ' + o.by + ')' : ''} · .${o.cls} · "${o.txt}"`).join('\n')
      + (bad.length > 12 ? `\n… +${bad.length - 12} nữa` : ''));
}

async function checkNoFaint(page, label) {
  const hits = await page.evaluate(() => {
    /* Compare PARSED rgb, not the serialised string: colour(srgb …) — what any
       color-mix() computes to — never equals the literal 'rgb(89, 97, 110)', so
       a string match here silently stops matching the moment someone writes
       color-mix(in srgb, #59616e 100%, transparent). Same class of hole as the
       contrast parser had. */
    const banned = [[89, 97, 110]];
    const near = (a, b) => a.every((v, i) => Math.abs(v - b[i]) < 0.5);
    return window.__V.textLeaves()
      .filter(el => { const c = window.__V.parse(getComputedStyle(el).color);
                      return !!c && c.a >= 1 && banned.some(b => near(c.rgb, b)); })
      .map(el => (el.className || el.tagName) + ' · "' + el.textContent.trim().slice(0, 24) + '"');
  });
  record(`A3.${label}`, 'A', `[${label}] Không còn #59616e (--faint) dùng cho chữ`,
    hits.length === 0, hits.slice(0, 10).join('\n'));
}

async function checkTokens(page) {
  const t = await page.evaluate(() => {
    const s = getComputedStyle(document.documentElement); const o = {};
    for (const n of s) if (n.startsWith('--')) o[n] = s.getPropertyValue(n).trim();
    return o;
  });
  const expect = { '--t1':'11px','--t2':'13px','--t3':'15px','--t4':'20px','--t5':'28px','--t6':'44px',
                   '--die-num':'34px','--die-kw':'13px','--intent-v':'20px' };
  const wrong = Object.entries(expect).filter(([k,v]) => (t[k]||'—') !== v).map(([k,v]) => `${k}: có "${t[k]||'thiếu'}", cần "${v}"`);
  record('A4', 'A', 'Bảng token type đã cập nhật', wrong.length === 0, wrong.join('\n'));
  record('A5', 'A', 'Token --faint đã bị xoá khỏi :root', !('--faint' in t),
    '--faint vẫn tồn tại = ' + t['--faint']);
  return t;
}

async function checkBorderContrast(page) {
  const bad = await page.evaluate(min => {
    const out = [];
    for (const el of document.querySelectorAll('.unit, .die, .pick, .nodecard, .bottombar, .track, .btn')) {
      if (!window.__V.visible(el)) continue;
      const cs = getComputedStyle(el);
      if (parseFloat(cs.borderTopWidth) < 1) continue;
      if (cs.borderTopStyle === 'none' || cs.borderTopColor === 'rgba(0, 0, 0, 0)') continue;
      if (window.__V.isDisabled(el)) continue;
      /* parse(), not a bare /[\d.]+/ scrape: on a color-mix() border that scrape
         reads "color(srgb 0.5 0.2 0.1)" as rgb(0.5, 0.2, 0.1) — near-black — and
         invents a contrast number out of nothing. */
      const outside = window.__V.effBg(el.parentElement || document.body);
      const parsed = window.__V.parse(cs.borderTopColor);
      if (!parsed) { out.push({ cr: null, cls: el.className, bc: cs.borderTopColor,
        bg: window.__V.rgbHex(outside), unparsed: true }); continue; }
      const bc = window.__V.over(parsed.rgb, outside, parsed.a);
      const cr = window.__V.contrast(bc, outside);
      if (cr < min - 0.005) out.push({ cr: +cr.toFixed(2), cls: el.className,
        bc: window.__V.rgbHex(bc), bg: window.__V.rgbHex(outside) });
    }
    const seen = new Set();
    return out.filter(o => { const k = o.cls + o.bc; if (seen.has(k)) return false; seen.add(k); return true; });
  }, AA_NONTEXT);
  record('A6', 'A', `Viền component đạt ≥ ${AA_NONTEXT}:1 (WCAG 1.4.11)`,
    bad.length === 0, bad.slice(0,10).map(o => o.unparsed
      ? `KHÔNG ĐO ĐƯỢC — màu viền ${o.bc} không parse được · .${o.cls}`
      : `${o.cr}:1 · ${o.bc} trên ${o.bg} · .${o.cls}`).join('\n'));
}

async function checkNoBrokenStrings(page, label) {
  const hits = await page.evaluate(() => {
    const bad = /\b(undefined|NaN|null|\[object Object\])\b/;
    return window.__V.textLeaves()
      .filter(el => bad.test(el.textContent))
      .map(el => (el.className || el.tagName) + ' → "' + el.textContent.trim().slice(0, 60) + '"');
  });
  record(`A7.${label}`, 'A', `[${label}] Không có undefined / NaN / null lộ ra UI`,
    hits.length === 0, hits.slice(0, 8).join('\n'));
}

async function checkMediaQueries(page) {
  const info = await page.evaluate(() => {
    const conds = [];
    for (const s of document.styleSheets) {
      try { for (const r of s.cssRules) if (r.type === 4) conds.push(r.conditionText); } catch {}
    }
    return { conds, widthQueries: conds.filter(c => /width/.test(c)).length };
  });
  record('B0', 'B', 'Có ≥ 3 media query theo chiều rộng', info.widthQueries >= 3,
    `Tìm thấy ${info.widthQueries} width query. Toàn bộ: ${info.conds.join(' | ') || '(không có)'}`);
}

async function checkNoHorizontalOverflow(page, label) {
  const o = await page.evaluate(() => {
    const de = document.documentElement;
    const wide = [...document.querySelectorAll('#app *')]
      .filter(el => window.__V.visible(el) && el.getBoundingClientRect().right > innerWidth + 1)
      .slice(0, 8)
      .map(el => (el.className || el.tagName) + ' → right=' + Math.round(el.getBoundingClientRect().right));
    return { scrollW: de.scrollWidth, innerW: innerWidth, wide };
  });
  record(`B2.${label}`, 'B', `[${label}] Không tràn ngang (scrollWidth ≤ viewport)`,
    o.scrollW <= o.innerW + 1,
    `scrollWidth=${o.scrollW} > viewport=${o.innerW}\n` + o.wide.join('\n'));
}

async function checkUiScale(page, label, expectOne) {
  const s = await page.evaluate(() => ({
    scale: getComputedStyle(document.documentElement).getPropertyValue('--ui-scale').trim(),
    zoom: getComputedStyle(document.getElementById('app') || document.body).zoom
  }));
  const v = parseFloat(s.scale || '1');
  const ok = expectOne ? Math.abs(v - 1) < 0.001 : (v >= 0.85 && v <= 1.20);
  record(`B3.${label}`, 'B', `[${label}] --ui-scale ${expectOne ? '= 1' : 'trong [0.85, 1.20]'}`,
    ok, `--ui-scale = "${s.scale}" (zoom=${s.zoom})`);
}

async function checkFocusRing(page) {
  const r = await page.evaluate(() => {
    const els = window.__V.interactive().filter(e => !window.__V.isDisabled(e)).slice(0, 25);
    const bad = [];
    for (const el of els) {
      el.focus?.();
      const cs = getComputedStyle(el);
      const ow = parseFloat(cs.outlineWidth) || 0;
      const ring = ow >= 2 && cs.outlineStyle !== 'none';
      const shadow = cs.boxShadow && cs.boxShadow !== 'none';
      if (document.activeElement === el && !ring && !shadow)
        bad.push((el.className || el.tagName) + ' → outline:' + cs.outline);
    }
    return { total: els.length, focusable: els.filter(e => { e.focus?.(); return document.activeElement === e; }).length, bad };
  });
  record('A8a', 'A', 'Mọi element tương tác nhận được focus bằng bàn phím',
    r.focusable === r.total, `focus được ${r.focusable}/${r.total} element`);
  record('A8b', 'A', 'Focus ring nhìn thấy rõ (outline ≥ 2px)',
    r.bad.length === 0, r.bad.slice(0, 8).join('\n'));
}

async function checkDieUniform(page) {
  const r = await page.evaluate(() => {
    const dice = [...document.querySelectorAll('.die')].filter(window.__V.visible);
    const h = dice.map(d => Math.round(d.getBoundingClientRect().height));
    const w = dice.map(d => Math.round(d.getBoundingClientRect().width));
    const boxSizing = dice.map(d => getComputedStyle(d).boxSizing);
    return { n: dice.length, h, w, uniform: new Set(h).size <= 1 && new Set(w).size <= 1, boxSizing: [...new Set(boxSizing)] };
  });
  record('C1', 'C', 'Cả 5 ô xúc xắc cùng kích thước (mọi loại mặt)',
    r.n >= 5 && r.uniform, `n=${r.n} heights=${r.h} widths=${r.w} box-sizing=${r.boxSizing}`);
}

async function checkNoLayoutShift(page) {
  const r = await page.evaluate(async () => {
    const snap = () => [...document.querySelectorAll('.unit, .die, .zone')]
      .map(e => { const b = e.getBoundingClientRect(); return Math.round(b.x) + ',' + Math.round(b.y); }).join('|');
    const before = snap();
    const die = [...document.querySelectorAll('.die')].find(d => getComputedStyle(d).opacity > 0.5);
    if (!die) return { skipped: true };
    die.click();
    await new Promise(r => setTimeout(r, 350));
    const during = snap();
    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    await new Promise(r => setTimeout(r, 350));
    const after = snap();
    const diff = (a, b) => a.split('|').filter((v, i) => v !== b.split('|')[i]).length;
    return { movedOnSelect: diff(before, during), movedOnCancel: diff(during, after) };
  });
  if (r.skipped) return record('C2', 'C', 'Chọn xúc xắc không gây layout shift', false, 'Không tìm thấy .die khả dụng');
  record('C2', 'C', 'Chọn / bỏ chọn xúc xắc không làm element nào dịch chuyển',
    r.movedOnSelect === 0 && r.movedOnCancel === 0,
    `${r.movedOnSelect} element dịch khi chọn, ${r.movedOnCancel} khi hủy`);
}

async function checkHpState(page) {
  const r = await page.evaluate(() => {
    const bars = [...document.querySelectorAll('.hpbar')].filter(window.__V.visible);
    return bars.map(b => {
      const fill = b.querySelector('.hpfill');
      const txt = (b.textContent || '').trim();
      const m = txt.match(/(\d+)\s*\/\s*(\d+)/);
      const pct = m ? +m[1] / +m[2] : null;
      const enemy = !!b.closest('.unit.e, .unit.enemy');
      return { pct, enemy, fill: fill ? getComputedStyle(fill).backgroundColor : null,
               cls: b.className, chipShown: !!b.querySelector('.hpchip') &&
                 getComputedStyle(b.querySelector('.hpchip')).display !== 'none' };
    });
  });
  const withPct = r.filter(b => b.pct != null);
  const problems = [];
  for (const b of withPct) {
    const expectLow = b.pct <= 0.50 && b.pct > 0.25;
    const expectCrit = b.pct <= 0.25 && b.pct > 0;
    const hasLow = /\blow\b/.test(b.cls), hasCrit = /\bcrit\b/.test(b.cls);
    if (expectLow && !(hasLow || hasCrit)) problems.push(`${Math.round(b.pct*100)}% (${b.enemy?'địch':'ta'}) thiếu class .low → fill ${b.fill}`);
    if (expectCrit && !hasCrit) problems.push(`${Math.round(b.pct*100)}% (${b.enemy?'địch':'ta'}) thiếu class .crit → fill ${b.fill}`);
  }
  const allyFull = withPct.filter(b => !b.enemy && b.pct > 0.5).map(b => b.fill);
  const enemyFull = withPct.filter(b => b.enemy && b.pct > 0.5).map(b => b.fill);
  const sameAtFullHp = allyFull.length && enemyFull.length
    ? new Set([...allyFull, ...enemyFull]).size === 1 : null;
  record('A9', 'A', 'Thanh máu mã hoá % HP, không mã hoá phe',
    problems.length === 0 && sameAtFullHp !== false,
    [ ...problems,
      sameAtFullHp === false ? `Ở >50% HP, fill của ta (${allyFull[0]}) khác fill của địch (${enemyFull[0]})` : ''
    ].filter(Boolean).join('\n') || `Đã kiểm ${withPct.length} thanh máu`);
}

async function checkReducedMotion(page) {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.waitForTimeout(300);
  const bad = await page.evaluate(() => [...document.querySelectorAll('#app *')]
    .filter(window.__V.visible)
    .map(el => ({ cls: el.className || el.tagName,
                  an: getComputedStyle(el).animationName,
                  dur: getComputedStyle(el).animationDuration }))
    .filter(o => o.an && o.an !== 'none' && parseFloat(o.dur) > 0)
    .slice(0, 10));
  await page.emulateMedia({ reducedMotion: 'no-preference' });
  record('A10', 'A', 'prefers-reduced-motion: reduce tắt hết animation',
    bad.length === 0, bad.map(o => `.${o.cls} → ${o.an} ${o.dur}`).join('\n'));
}

async function checkCharsPerLine(page) {
  const r = await page.evaluate(() => {
    const c = document.createElement('canvas').getContext('2d');
    const out = [];
    for (const el of document.querySelectorAll('.cxp, .pd, .nd, p')) {
      if (!window.__V.visible(el)) continue;
      const cs = getComputedStyle(el);
      c.font = `${cs.fontStyle} ${cs.fontWeight} ${cs.fontSize} ${cs.fontFamily}`;
      const adv = c.measureText('M'.repeat(50)).width / 50;
      const w = el.getBoundingClientRect().width;
      out.push({ cls: el.className || el.tagName, chars: Math.round(w / adv), w: Math.round(w), fs: cs.fontSize });
    }
    const seen = new Set();
    return out.filter(o => { if (seen.has(o.cls)) return false; seen.add(o.cls); return true; });
  });
  const bad = r.filter(o => o.chars > 78);
  record('D1', 'D', 'Đoạn văn dài ≤ 78 ký tự/dòng', bad.length === 0,
    bad.map(o => `.${o.cls} → ${o.chars} ký tự (${o.w}px @ ${o.fs})`).join('\n'), false);
}

/* ---------------------------------------------------------------------------
   TRANSIENT UI
   Three parts, because no single one of them is enough:
     driveTransients()  puts the game in a fixed state and plays a REAL turn, so
                        transient UI actually happens (a check that never has
                        anything to look at is not a check).
     checkTransients()  reads what the recorder in HELPERS captured and judges it
                        under the ordinary rules.
     checkPixelTruth()  re-measures the elements whose backdrop the DOM model
                        cannot see, against the real framebuffer.
   --------------------------------------------------------------------------- */

/* Fixed seed, fixed relics, real player input. The relic set is chosen so the
   events come through four different engine hooks — startCombat (startSummon /
   eggInherit, src/engine.js:382,404), tickStatus (plague, :901), startTurn
   (growthAll, :889) and dealDamage (thorns, :535) — rather than one. */
async function driveTransients(page) {
  const setup = await page.evaluate(() => {
    try {
      loadMeta(); META.unlocks = UNLOCKS.map(u => u.id); META.tut = 1; saveMeta();
      teamPick = ['plant1','beast1','aqua1','reptile1','bug1'];
      pickMode = 'short'; pickAsc = 0; pickSeed = 'verify-transient';
      startRun(); tut = 0;
      /* before chooseNode(), because startCombat() reads startSummon to decide
         whether an Axie Egg joins the party — the Egg is the worst-case badge
         backdrop (.unit.p.token{opacity:.85} over artwork). */
      S.relics = ['r_broodpouch','r_hivequeen','r_plaguelord','r_seedling','r_mirrorshell'];
      const i = S.nodes.findIndex(n => ['battle','elite','boss'].includes(n.type));
      chooseNode(S, i < 0 ? 0 : i);
      S.enemies.forEach(e => { if (e.hp > 0) e.st.poison = 4; });   /* give plague something to hold */
      render();
      return { ok: true, party: S.party.length, eggs: S.party.filter(u => u.token).length };
    } catch (e) { return { ok: false, err: String(e && e.message || e) }; }
  });
  if (!setup.ok) return { ...setup, badges: 0 };

  await page.waitForTimeout(300);
  const end = page.locator('.btn.end').first();
  if (await end.count()) await end.click().catch(() => {});
  /* The relic events sit after the enemy action chain in the stream, so wait for
     the badge itself rather than guessing at a delay. */
  let sawBadge = false;
  try { await page.waitForSelector('.rbadge', { timeout: 15000 }); sawBadge = true; } catch {}
  await page.waitForTimeout(1800);   /* let the badges live and die under the recorder */
  return { ...setup, sawBadge };
}

async function checkTransients(page, label = 'transient', drv = {}) {
  const r = await page.evaluate(() => window.__V.transientReport());
  const seen = r.findings.length;
  /* A canary, not decoration. "The suite is green" and "the badge is compliant"
     were different claims once already; this makes the second one an assertion.
     If src/fx.js renames these classes the check goes red and someone has to
     come back here — which is the correct failure mode. A check that quietly
     stops finding its subject is the bug this whole file is fixing. */
  const WITNESS = { '.rbi/.rbn (relic badge, fx.js relicBadge)': /^rb[inx]$/,
                    '.ftx (floating combat number, fx.js floatOn)': /^ftx$/ };
  const classes = new Set(r.findings.map(f => String(f.cls).split(' ')[0]));
  const missing = Object.entries(WITNESS).filter(([, re]) => ![...classes].some(c => re.test(c))).map(([k]) => k);

  record('T0', 'A', `[${label}] Bộ ghi bắt được UI thoáng qua và không bỏ sót cái nào`,
    seen > 0 && r.escapes.length === 0 && missing.length === 0,
    (seen === 0 ? 'Không bắt được element thoáng qua nào — check này đang không đo gì cả.\n' : '')
      + (missing.length ? 'KHÔNG THẤY chứng nhân bắt buộc: ' + missing.join(', ')
          + '\n(element thoáng qua đã đổi class, hoặc driver không còn sinh ra nó — check đang đo hụt)\n' : '')
      + (r.escapes.length ? 'Thoát khỏi phép đo (sống ≥100ms mà không lấy được mẫu):\n'
          + r.escapes.slice(0, 8).map(e => `.${e.sig} · ${e.life}ms`).join('\n') : '')
      + `\nĐã bắt: ${seen} element — ${[...new Set(r.findings.map(f => '.' + String(f.cls).split(' ')[0]))].join(' ')}`
      + `\nDriver: party=${drv.party} egg=${drv.eggs} badge=${drv.sawBadge ? 'có' : 'KHÔNG'} err=${drv.err || '—'}`
      + `\nBỏ qua ${r.churn} node do re-render (đã có element cùng class còn sống — snapshot check lo)`);

  const badFs = r.findings.filter(f => f.fs < MIN_FONT_SIZE || !ALLOWED_FONT_SIZES.includes(Math.round(f.fs)));
  record(`A1.${label}`, 'A', `[${label}] Không có chữ < ${MIN_FONT_SIZE}px và mọi cỡ đều thuộc thang`,
    badFs.length === 0,
    badFs.slice(0, 10).map(f => `${f.fs}px · .${f.cls} · "${f.txt}" (sống ${f.life}ms)`).join('\n'));

  const badCr = [];
  for (const f of r.findings) {
    if (f.problems && f.problems.length) { badCr.push({ ...f, unparsed: f.problems.join(' + ') }); continue; }
    const large = f.fs >= 24 || (f.bold && f.fs >= 18.66);
    const need = (f.disabled || large) ? AA_LARGE : AA_TEXT;   /* same rule as checkContrast */
    const cr = contrastOf(f.fg, f.bg);
    if (cr < need - 0.005) badCr.push({ ...f, cr: +cr.toFixed(2), need });
  }
  record(`A2.${label}`, 'A', `[${label}] Mọi chữ đạt contrast AA`,
    badCr.length === 0,
    badCr.slice(0, 10).map(f => f.unparsed
      ? `KHÔNG ĐO ĐƯỢC — màu ${f.unparsed} · .${f.cls} · "${f.txt}"`
      : `${f.cr}:1 (cần ${f.need}) ${f.fs}px alpha=${f.alpha} trên .${f.host} · .${f.cls} · "${f.txt}" (sống ${f.life}ms)`).join('\n'));

  const vw = page.viewportSize().width;
  const badOv = r.findings.filter(f => f.right > vw + 1);
  record(`B2.${label}`, 'B', `[${label}] Không tràn ngang`,
    badOv.length === 0,
    badOv.slice(0, 8).map(f => `.${f.cls} → right=${f.right} > viewport=${vw}`).join('\n'));
  return r;
}

const contrastOf = (a, b) => {
  const lin = c => { c /= 255; return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); };
  const lum = ([r, g, b]) => 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);
  const la = lum(a), lb = lum(b), hi = Math.max(la, lb), lo = Math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
};

/* Contrast read off the real framebuffer instead of modelled from the DOM.
   Needed because effBg() composites background-COLOR only: it cannot see a
   gradient, an <img> behind an absolutely-positioned overlay, or an ancestor
   opacity fading a whole card over artwork. A relic badge is all three at once —
   it floats over an Axie sprite, and on an Axie Egg the whole card is at
   opacity .85, which is exactly where an earlier hand audit found the AEGIS
   glyph at 4.29:1 against AA's 4.5.

   The backdrop is sampled (screenshot with the glyphs hidden); the glyph colour
   is then composited analytically over each sampled pixel at the element's real
   effective alpha. Sampling the glyph pixels themselves would measure font
   antialiasing rather than colour — at 11px almost no pixel is fully covered. */
async function pixelTruth(page, sel) {
  const meta = await page.evaluate(s => {
    const el = document.querySelector(s);
    if (!el || !window.__V.visible(el)) return null;
    const cs = getComputedStyle(el);
    /* The GLYPH RUN, not the element box. .pasdot is a 24px circle inside a
       square box: sampling the box reads the card behind it through the rounded
       corners and reports a contrast the text never had. Range client rects give
       the rectangle the text actually occupies. */
    let r = el.getBoundingClientRect();
    try {
      const rg = document.createRange();
      rg.selectNodeContents(el);
      const rects = [...rg.getClientRects()].filter(q => q.width > 1 && q.height > 1);
      if (rects.length) {
        const l = Math.max(...rects.map(q => q.left)), t = Math.max(...rects.map(q => q.top));
        r = { left: Math.min(...rects.map(q => q.left)), top: Math.min(...rects.map(q => q.top)),
              right: Math.max(...rects.map(q => q.right)), bottom: Math.max(...rects.map(q => q.bottom)) };
      }
    } catch (e) {}
    const x = Math.max(0, Math.floor(r.left)), y = Math.max(0, Math.floor(r.top));
    const w = Math.min(Math.ceil(r.right) - x, innerWidth - x), h = Math.min(Math.ceil(r.bottom) - y, innerHeight - y);
    if (w < 2 || h < 2) return null;
    const c = window.__V.parse(cs.color);
    window.__vHidden = { el, color: el.style.color, ts: el.style.textShadow };
    el.style.setProperty('color', 'transparent', 'important');
    el.style.setProperty('text-shadow', 'none', 'important');
    /* page.screenshot({clip}) is DOCUMENT-relative while getBoundingClientRect()
       is VIEWPORT-relative: without the scroll offset a scrolled page samples a
       completely different region and invents a number (measured: an icon
       "scored" 1:1 against a backdrop it was nowhere near). */
    return { x, y, w, h, sx: Math.round(scrollX), sy: Math.round(scrollY),
             rgb: c ? c.rgb : null, raw: cs.color, alpha: window.__V.effAlpha(el),
             fs: parseFloat(cs.fontSize), bold: parseInt(cs.fontWeight, 10) >= 700,
             cls: el.className || el.tagName, txt: el.textContent.trim().slice(0, 24) };
  }, sel);
  if (!meta) return null;
  let png = null, err = null;
  try { png = await page.screenshot({ clip: { x: meta.x + meta.sx, y: meta.y + meta.sy, width: meta.w, height: meta.h } }); }
  catch (e) { err = e.message; }
  await page.evaluate(() => { const h = window.__vHidden; if (h) { h.el.style.color = h.color; h.el.style.textShadow = h.ts; window.__vHidden = null; } });
  if (!png) return { ...meta, error: err };
  /* A second frame WITH the glyphs, so the backdrop can be sampled only where the
     ink actually falls. Without it we sample the whole text box and a glyph that
     merely OVERLAPS a coloured strip scores as if it sat on it. This also
     self-checks the hide step: no difference between the two frames means the
     glyphs were not hidden (text-fill-color, a pseudo-element, an <img>), and
     that is reported rather than turned into a number. */
  let inkPng = null;
  try { inkPng = await page.screenshot({ clip: { x: meta.x + meta.sx, y: meta.y + meta.sy, width: meta.w, height: meta.h } }); }
  catch (e) { return { ...meta, error: e.message }; }
  return await page.evaluate(async ({ bare, ink, meta }) => {
    const load = async b64 => {
      const img = new Image();
      await new Promise((ok, no) => { img.onload = ok; img.onerror = () => no(new Error('decode')); img.src = 'data:image/png;base64,' + b64; });
      const cv = document.createElement('canvas');
      cv.width = img.width; cv.height = img.height;
      const cx = cv.getContext('2d', { willReadFrequently: true });
      cx.drawImage(img, 0, 0);
      return { d: cx.getImageData(0, 0, cv.width, cv.height).data, w: cv.width, h: cv.height };
    };
    const B = await load(bare), I = await load(ink);
    if (!meta.rgb) return { ...meta, cr: null, unparsed: meta.raw };
    if (B.d.length !== I.d.length) return { ...meta, cr: null, note: 'khung hình lệch kích thước' };
    const crs = [];
    let worstPx = null, worst = Infinity, inkPx = 0;
    for (let i = 0; i < B.d.length; i += 4) {
      const diff = Math.max(Math.abs(B.d[i] - I.d[i]), Math.abs(B.d[i+1] - I.d[i+1]), Math.abs(B.d[i+2] - I.d[i+2]));
      if (diff < 24) continue;                       /* no ink here — not text */
      inkPx++;
      const bg = [B.d[i], B.d[i+1], B.d[i+2]];       /* the real surface behind the glyph */
      const fg = window.__V.over(meta.rgb, bg, meta.alpha);
      const cr = window.__V.contrast(fg, bg);
      crs.push(cr);
      if (cr < worst) { worst = cr; worstPx = { bg, fg: fg.map(Math.round) }; }
    }
    if (!inkPx) return { ...meta, cr: null, note: 'không tìm thấy ink — chữ không bị ẩn bởi color:transparent (text-fill-color? pseudo-element? ảnh?)' };
    crs.sort((a, b) => a - b);
    /* 5th percentile, not the single worst pixel: one stray antialiased edge
       pixel must not condemn a badge, but a bad REGION must. */
    const cr = crs[Math.floor(crs.length * 0.05)];
    return { ...meta, cr: +cr.toFixed(2), min: +worst.toFixed(2), px: inkPx,
             bg: window.__V.rgbHex(worstPx.bg), fg: window.__V.rgbHex(worstPx.fg) };
  }, { bare: png.toString('base64'), ink: inkPng.toString('base64'), meta });
}

/* Which elements need the framebuffer rather than the model: anything whose
   background chain crosses a gradient or an image, plus anything currently
   floating as an overlay (position:absolute/fixed) — that is where a sibling
   <img> can be the real backdrop without appearing anywhere in the chain. */
async function checkPixelTruth(page, label, frozen = {}) {
  const sels = await page.evaluate(() => {
    const out = [], seen = new Set();
    let i = 0;
    for (const el of window.__V.textLeaves()) {
      let need = null, e = el;
      while (e && e !== document.documentElement) {
        const cs = getComputedStyle(e);
        if (cs.backgroundImage && cs.backgroundImage !== 'none') { need = 'background-image trên .' + (e.className || e.tagName); break; }
        if (cs.position === 'absolute' || cs.position === 'fixed') { need = 'overlay .' + (e.className || e.tagName); break; }
        const c = window.__V.parse(cs.backgroundColor);
        if (c && c.a >= 1) break;
        e = e.parentElement;
      }
      if (!need) continue;
      const sig = (el.className || el.tagName) + '|' + Math.round(parseFloat(getComputedStyle(el).fontSize));
      if (seen.has(sig)) continue;
      seen.add(sig);
      out.push({ el, why: need, cls: el.className || el.tagName });
    }
    /* overlays first: a floating badge over artwork is the case the DOM model is
       most wrong about, so it must never be the one that misses the cap. */
    out.sort((a, b) => (a.why.startsWith('overlay') ? 0 : 1) - (b.why.startsWith('overlay') ? 0 : 1));
    return out.slice(0, 12).map(c => {
      c.el.setAttribute('data-vpx', String(i));
      return { sel: '[data-vpx="' + (i++) + '"]', why: c.why, cls: c.cls };
    });
  });
  const bad = [], done = [];
  for (const c of sels) {
    const m = await pixelTruth(page, c.sel);
    if (!m || m.error) continue;
    done.push(m);
    const large = m.fs >= 24 || (m.bold && m.fs >= 18.66);
    const need = large ? AA_LARGE : AA_TEXT;
    if (m.cr == null) bad.push(`KHÔNG ĐO ĐƯỢC — .${m.cls} "${m.txt}": ${m.unparsed ? 'màu ' + m.unparsed : m.note}`);
    else if (m.cr < need - 0.005)
      bad.push(`${m.cr}:1 (cần ${need}) ${m.fs}px alpha=${m.alpha} ${m.fg} trên pixel thật ${m.bg} · .${m.cls} · "${m.txt}" [${c.why}]`);
  }
  await page.evaluate(() => document.querySelectorAll('[data-vpx]').forEach(el => el.removeAttribute('data-vpx')));
  /* The badge is the reason this check exists — it must be one of the elements
     actually measured, not merely present on screen while something else was. */
  const badgeMeasured = done.some(m => /^rb[inx]\b/.test(String(m.cls)));
  if (frozen.ok && !badgeMeasured) bad.push('Badge đã đóng băng nhưng KHÔNG nằm trong số element được đo bằng pixel — check đang đo hụt đúng thứ nó sinh ra để đo.');
  record(`A2px.${label}`, 'A', `[${label}] Chữ trên nền mô hình DOM không thấy được (gradient/ảnh/overlay) đạt AA khi đo bằng pixel thật`,
    bad.length === 0 && done.length > 0,
    (done.length === 0 ? 'Không đo được element nào — check này đang không đo gì cả.' : bad.join('\n'))
      + `\nĐã đo ${done.length} element bằng pixel thật: `
      + done.map(m => `.${String(m.cls).split(' ')[0]} ${m.cr == null ? '—' : m.cr + ':1'}`).join(', ')
      + `\nBadge đóng băng: ${frozen.ok ? (frozen.onEgg ? 'trên Axie Egg (.unit.p.token, opacity .85)' : 'trên Axie thường') : 'KHÔNG (' + (frozen.err || 'n/a') + ')'}`);
  return done;
}

/* Fire one more badge and FREEZE it, so the pixel measurement is not racing a
   600ms lifetime. The freeze uses fx.js's own bookkeeping (relicFxLive[id].timer
   is the very timeout relicBadge() installed) rather than patching the runtime:
   nothing about how the badge is built or painted changes, it simply stops being
   torn down while the camera is open.

   relicBadge('eggInherit', uid) is the exact call fx.js's own event replay makes
   (src/fx.js:248, `relicBadge(e.id, e.uid)`) for the event engine.js:404 emits,
   `EVrelic(s,'eggInherit',a.uid)` where `a` is the Axie Egg. Aiming it at the Egg
   is deliberate: .unit.p.token{opacity:.85} over artwork is the worst backdrop
   the badge ever lands on, and the one an earlier hand audit measured at 4.29:1. */
async function freezeBadge(page) {
  const info = await page.evaluate(() => {
    try {
      const egg = S.party.find(u => u.token && u.hp > 0);
      const host = egg || S.party.find(u => u.hp > 0);
      if (!host) return { ok: false, err: 'không còn Axie sống để gắn badge' };
      relicBadge('eggInherit', host.uid);
      for (const k in relicFxLive) {
        const l = relicFxLive[k];
        if (l && l.timer) { clearTimeout(l.timer); l.timer = null; }
      }
      return { ok: true, onEgg: !!egg, uid: host.uid, n: document.querySelectorAll('.rbadge').length };
    } catch (e) { return { ok: false, err: String(e && e.message || e) }; }
  });
  await page.waitForTimeout(300);   /* rb-in is .18s — measure the settled state */
  return info;
}

async function releaseBadges(page) {
  await page.evaluate(() => { try { for (const k in relicFxLive) relicBadgeEnd(k); } catch (e) {} });
  await page.waitForTimeout(300);
}

async function run() {
  const browser = await chromium.launch({ headless: !HEADED, args:['--no-sandbox'] });
  const ctx = await browser.newContext({ viewport: DESKTOP, deviceScaleFactor: 1 });
  await ctx.addInitScript(HELPERS);
  // Login is mandatory (design/gdd/player-accounts.md §3 "App gate") and this
  // test harness has no live Upstash/AUTH_JWT_SECRET to register/log in
  // against. Seed a cached token before the app's own boot script runs, the
  // same way a real returning player's browser would already have one — this
  // exercises the SAME "optimistic render, verify later" path the real app
  // uses (ui.js: `if(!authToken) screen='gate'` only checks presence, not
  // validity — that's a deliberate, documented tradeoff of the static-HTML
  // architecture, not a hole this script is opening). It does NOT test the
  // gate/auth-form UI itself — that needs its own check against a real
  // deployment with Upstash configured, not this offline suite.
  await ctx.addInitScript(() => { try { localStorage.setItem('axiedice_token_v1', 'verify-mjs-test-token'); } catch (e) {} });
  // This suite serves the build over a bare `python -m http.server` (see
  // .claude/launch.json) — there is no /api/* backend at all locally, so any
  // real fetch() to it 404s/501s and Chromium logs that resource failure as
  // a console error regardless of whether the app's own JS catches the
  // rejection (that log line comes from the browser's network stack, not
  // from app code — try/catch cannot suppress it). Now that login is
  // mandatory and a token is always present (see above), saveMeta()'s
  // debounced sync push actually fires during these checks for the first
  // time, so this was previously latent. Stub fetch for /api/* to return a
  // benign, shape-correct response instead — this tests the SAME app code
  // path (a resolved fetch handled normally) without a real backend, it does
  // not test the backend itself (that needs a real deployment).
  await ctx.addInitScript(() => {
    const real = window.fetch.bind(window);
    window.fetch = (input, init) => {
      const url = typeof input === 'string' ? input : (input && input.url) || '';
      if (url.indexOf('/api/') === -1) return real(input, init);
      const method = (init && init.method) || 'GET';
      let body = { ok: true };
      if (url.indexOf('/api/sync-save') !== -1) body = method === 'GET' ? { meta: null } : { ok: true, savedAt: Date.now() };
      else if (url.indexOf('/api/leaderboard') !== -1) body = { rows: [], configured: false };
      else if (url.indexOf('/api/submit-run') !== -1) body = { accepted: false, reason: 'verify.mjs stub' };
      else if (url.indexOf('/api/auth') !== -1) body = { ok: false, error: 'verify.mjs stub — auth flow not exercised by this offline suite' };
      return Promise.resolve(new Response(JSON.stringify(body), { status: 200, headers: { 'Content-Type': 'application/json' } }));
    };
  });
  const page = await ctx.newPage();
  page.on('console', m => { if (m.type() === 'error') consoleErrors.push(m.text()); });
  page.on('pageerror', e => consoleErrors.push('pageerror: ' + e.message));

  console.log(`\n▸ Kiểm tra ${URL}\n`);
  await page.goto(URL, { waitUntil: 'networkidle', timeout: 60000 });
  await page.waitForTimeout(800);

  if (want('A')) {
    await checkTokens(page);
    await checkFontSizes(page, 'menu');
    await checkContrast(page, 'menu');
    await checkNoFaint(page, 'menu');
    await checkNoBrokenStrings(page, 'menu');
    await checkBorderContrast(page);
    await checkFocusRing(page);
    await checkReducedMotion(page);
  }
  if (want('B')) await checkMediaQueries(page);

  const nav = await reachCombat(page);
  console.log(`\n  ↳ đường đi: ${nav.trail.join(' → ')}${nav.inCombat ? '' : '  ⚠ CHƯA vào được combat'}\n`);
  record('N0', 'A', 'Đi được từ Menu tới Combat bằng UI', nav.inCombat, `trail=${nav.trail.join(' → ')}`);

  if (nav.inCombat) {
    if (want('A')) {
      await checkFontSizes(page, 'combat');
      await checkContrast(page, 'combat');
      await checkNoFaint(page, 'combat');
      await checkNoBrokenStrings(page, 'combat');
      await checkHpState(page);
    }
    if (want('B')) { await checkTapTargets(page, 'combat', DESKTOP); await checkUiScale(page, 'desktop-1440', false); }
    if (want('C')) { await checkDieUniform(page); await checkNoLayoutShift(page); }
    if (want('D')) await checkCharsPerLine(page);
    if (want('A')) {
      /* Last on this page: driveTransients() restarts the run with a fixed seed,
         so it must not disturb anything above it. */
      const drv = await driveTransients(page);
      await checkTransients(page, 'transient', drv);
      const frozen = await freezeBadge(page);
      await checkPixelTruth(page, 'combat', frozen);
      await releaseBadges(page);
    }
  }

  if (want('B')) {
    for (const [label, vp] of [['tablet', TABLET], ['phone', PHONE]]) {
      const p2 = await ctx.newPage();
      await p2.setViewportSize(vp);
      await p2.goto(URL, { waitUntil: 'networkidle', timeout: 60000 });
      await p2.waitForTimeout(700);
      // Portrait gate (game is landscape-only, .rotate-hint covers PLAY and
      // intercepts clicks — see .claude/docs/technical-preferences.md) must be
      // cleared BEFORE attempting reachCombat, not after: a real phone player
      // rotates first, then plays. Checking/rotating after the fact meant
      // reachCombat's click was always silently swallowed by the overlay and
      // N1.phone could never pass regardless of the app actually working.
      const portraitGate = await p2.locator('.rotate-hint, [class*=rotate]').first().count();
      if (label === 'phone' && portraitGate) {
        record('B4', 'B', '[phone portrait] Có gợi ý xoay ngang', true, 'Tìm thấy .rotate-hint', false);
        await p2.setViewportSize({ width: PHONE.height, height: PHONE.width });
        await p2.waitForTimeout(500);
      }
      const n2 = await reachCombat(p2);
      await checkNoHorizontalOverflow(p2, label);
      await checkUiScale(p2, label, true);
      if (n2.inCombat || await p2.locator('.die').count()) {
        await checkTapTargets(p2, label, vp);
        await checkFontSizes(p2, label);
        await checkContrast(p2, label);
      } else {
        record(`N1.${label}`, 'B', `[${label}] Vào được combat`, false, `trail=${n2.trail.join(' → ')}`);
      }
      await p2.close();
    }
  }

  record('A11', 'A', 'Không có console error', consoleErrors.length === 0,
    [...new Set(consoleErrors)].slice(0, 8).join('\n'));

  await browser.close();

  const req = results.filter(r => r.required);
  const failed = req.filter(r => !r.pass);
  const warned = results.filter(r => !r.required && !r.pass);
  const byPhase = {};
  for (const r of results) {
    byPhase[r.phase] ??= { pass: 0, fail: 0 };
    r.pass ? byPhase[r.phase].pass++ : byPhase[r.phase].fail++;
  }
  console.log('\n' + '─'.repeat(64));
  console.log(`KẾT QUẢ: ${req.length - failed.length}/${req.length} check bắt buộc PASS` +
              (warned.length ? `, ${warned.length} cảnh báo` : ''));
  for (const [p, v] of Object.entries(byPhase).sort())
    console.log(`  Phase ${p}: ${v.pass} pass / ${v.fail} fail`);
  if (failed.length) {
    console.log('\nCòn phải sửa:');
    failed.forEach(f => console.log(`  ✗ ${f.id}  ${f.title}`));
  } else {
    console.log('\n✅ Toàn bộ check bắt buộc đã PASS.');
  }
  console.log('─'.repeat(64) + '\n');

  if (JSON_OUT) {
    writeFileSync(JSON_OUT, JSON.stringify({ url: URL, at: new Date().toISOString(),
      total: req.length, passed: req.length - failed.length, results, consoleErrors: [...new Set(consoleErrors)] }, null, 2));
    console.log('→ báo cáo JSON: ' + JSON_OUT);
  }
  process.exit(failed.length ? 1 : 0);
}

run().catch(e => { console.error('\n✗ verify.mjs lỗi:', e.message); process.exit(2); });
