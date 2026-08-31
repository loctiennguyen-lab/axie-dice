#!/usr/bin/env node
/**
 * verify.mjs — Axie Dice Tactics UI/UX conformance checker
 * ---------------------------------------------------------
 * Chấm điểm bản build theo đúng spec trong IMPLEMENTATION_BRIEF.md.
 * Chạy được headless, không cần người ngồi xem.
 *
 *   npm i -D playwright && npx playwright install chromium
 *   node verify.mjs                                  # mặc định http://localhost:5173
 *   node verify.mjs --url https://axiedice.vercel.app
 *   node verify.mjs --only A            # chỉ chạy check của Phase A
 *   node verify.mjs --json report.json  # xuất báo cáo máy đọc được
 *
 * Exit code: 0 = mọi check bắt buộc PASS. 1 = còn check FAIL.
 */
import { chromium } from 'playwright';
import { writeFileSync } from 'node:fs';

/* ─────────────────────────── config ─────────────────────────── */
const argv = process.argv.slice(2);
const arg = (k, d) => { const i = argv.indexOf('--' + k); return i >= 0 ? argv[i + 1] : d; };
const URL       = arg('url', process.env.GAME_URL || 'http://localhost:5173');
const ONLY      = arg('only', null);
const JSON_OUT  = arg('json', null);
const HEADED    = argv.includes('--headed');

const DESKTOP = { width: 1440, height: 900 };
const PHONE   = { width: 393, height: 852 };   // iPhone 15 Pro CSS viewport
const TABLET  = { width: 744, height: 1133 };  // iPad mini portrait

/* Thang chữ hợp lệ sau refactor. Bất kỳ cỡ nào ngoài danh sách = FAIL. */
const ALLOWED_FONT_SIZES = [11, 13, 15, 20, 28, 44, 34, 24];  // t1..t6 + die-num + die icon
const MIN_FONT_SIZE = 11;
const MIN_TAP = 44;
const AA_TEXT = 4.5;
const AA_LARGE = 3.0;   // ≥ 24px, hoặc ≥ 18.66px bold
const AA_NONTEXT = 3.0;

/* ───────────────────── in-page helper bundle ─────────────────── */
/* Được inject vào mọi page. Tất cả phép đo chạy trong page context. */
const HELPERS = `
window.__V = (() => {
  const lin = c => { c/=255; return c <= 0.04045 ? c/12.92 : Math.pow((c+0.055)/1.055, 2.4); };
  const lum = ([r,g,b]) => 0.2126*lin(r) + 0.7152*lin(g) + 0.0722*lin(b);
  const parse = s => {
    const m = String(s).match(/rgba?\\(([^)]+)\\)/);
    if (!m) return null;
    const p = m[1].split(/[,\\s/]+/).filter(Boolean).map(Number);
    return { rgb: p.slice(0,3), a: p.length > 3 ? p[3] : 1 };
  };
  const over = (fg, bg, a) => fg.map((v,i) => v*a + bg[i]*(1-a));
  const contrast = (a, b) => { const la = lum(a), lb = lum(b); const hi = Math.max(la,lb), lo = Math.min(la,lb); return (hi+0.05)/(lo+0.05); };

  /* Nền hiệu dụng: đi lên cây, hợp nhất mọi lớp bán trong suốt. */
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

  /* Màu chữ hiệu dụng: gộp opacity thừa hưởng từ tổ tiên. */
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

  /* Vùng chạm thật = rect của element, mở rộng bởi ::before/::after nếu chúng
     absolute + inset âm + element có position khác static. */
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

  /* WCAG 1.4.3 / 1.4.11 miễn trừ "inactive user interface components".
     Ta vẫn bắt buộc ≥3:1 để người chơi nhận ra là nút bị tắt, chỉ không bắt 4.5:1. */
  const isDisabled = el => !!(el.closest('[disabled],.dis,[aria-disabled="true"],:disabled'));

  return { contrast, effBg, effFg, visible, textLeaves, interactive, tapBox, isDisabled,
           rgbHex: c => '#' + c.map(v => v.toString(16).padStart(2,'0')).join('') };
})();
`;

/* ──────────────────────── check registry ────────────────────── */
const results = [];
let consoleErrors = [];

function record(id, phase, title, pass, detail, required = true) {
  results.push({ id, phase, title, pass: !!pass, required, detail });
  const tag = pass ? '\x1b[32mPASS\x1b[0m' : (required ? '\x1b[31mFAIL\x1b[0m' : '\x1b[33mWARN\x1b[0m');
  console.log(`${tag}  ${id}  ${title}`);
  if (!pass && detail) String(detail).split('\n').slice(0, 12).forEach(l => console.log('        ' + l));
}

const want = phase => !ONLY || ONLY.toUpperCase().includes(phase);

/* ───────────────────────── navigation ──────────────────────── */
async function clickText(page, text, timeout = 4000) {
  const loc = page.locator(`text="${text}"`).first();
  try { await loc.waitFor({ state: 'visible', timeout }); await loc.click({ timeout }); return true; }
  catch { return false; }
}

/** Đưa page tới màn combat. Trả về chuỗi các màn đã đi qua. */
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

/* ─────────────────────────── checks ────────────────────────── */

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
      const bold = parseInt(cs.fontWeight, 10) >= 700;
      const large = fs >= 24 || (bold && fs >= 18.66);
      const disabled = window.__V.isDisabled(el);
      const need = disabled ? aaLarge : (large ? aaLarge : aa);
      const fg = window.__V.effFg(el), bg = window.__V.effBg(el);
      const cr = window.__V.contrast(fg, bg);
      if (cr < need - 0.005) out.push({
        cr: +cr.toFixed(2), need, fs,
        fg: window.__V.rgbHex(fg), bg: window.__V.rgbHex(bg),
        cls: el.className || el.tagName, txt: el.textContent.trim().slice(0, 28),
        disabled
      });
    }
    return out.sort((a, b) => a.cr - b.cr);
  }, { aa: AA_TEXT, aaLarge: AA_LARGE });
  record(`A2.${label}`, phase, `[${label}] Mọi chữ đạt contrast AA`,
    bad.length === 0,
    bad.slice(0, 12).map(o => `${o.cr}:1 (cần ${o.need}${o.disabled ? ', disabled' : ''}) ${o.fs}px ${o.fg} trên ${o.bg} · .${o.cls} · "${o.txt}"`).join('\n')
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
    const banned = ['rgb(89, 97, 110)'];  // --faint #59616e
    return window.__V.textLeaves()
      .filter(el => banned.includes(getComputedStyle(el).color))
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
      if (window.__V.isDisabled(el)) continue;   // miễn trừ theo WCAG 1.4.11
      const bc = cs.borderTopColor.match(/[\d.]+/g).slice(0,3).map(Number);
      const outside = window.__V.effBg(el.parentElement || document.body);
      const cr = window.__V.contrast(bc, outside);
      if (cr < min - 0.005) out.push({ cr: +cr.toFixed(2), cls: el.className,
        bc: window.__V.rgbHex(bc), bg: window.__V.rgbHex(outside) });
    }
    const seen = new Set();
    return out.filter(o => { const k = o.cls + o.bc; if (seen.has(k)) return false; seen.add(k); return true; });
  }, AA_NONTEXT);
  record('A6', 'A', `Viền component đạt ≥ ${AA_NONTEXT}:1 (WCAG 1.4.11)`,
    bad.length === 0, bad.slice(0,10).map(o => `${o.cr}:1 · ${o.bc} trên ${o.bg} · .${o.cls}`).join('\n'));
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
    r.focusable === r.total, `focus được ${r.focusable}/${r.total} element — số còn lại là div/span thiếu tabindex hoặc chưa đổi sang <button>`);
  record('A8b', 'A', 'Focus ring nhìn thấy rõ (outline ≥ 2px, không dùng UA default)',
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
      sameAtFullHp === false ? `Ở >50% HP, fill của ta (${allyFull[0]}) khác fill của địch (${enemyFull[0]}) → vẫn mã hoá theo phe` : ''
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

/* ─────────────────────────── runner ────────────────────────── */
async function run() {
  const browser = await chromium.launch({ headless: !HEADED });
  const ctx = await browser.newContext({ viewport: DESKTOP, deviceScaleFactor: 1 });
  await ctx.addInitScript(HELPERS);
  const page = await ctx.newPage();
  page.on('console', m => { if (m.type() === 'error') consoleErrors.push(m.text()); });
  page.on('pageerror', e => consoleErrors.push('pageerror: ' + e.message));

  console.log(`\n▸ Kiểm tra ${URL}\n`);
  await page.goto(URL, { waitUntil: 'networkidle', timeout: 60000 });
  await page.waitForTimeout(800);

  /* ---- Phase A trên màn MENU ---- */
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

  /* ---- đi vào combat ---- */
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
  }

  /* ---- Phase B: tablet + phone ---- */
  if (want('B')) {
    for (const [label, vp] of [['tablet', TABLET], ['phone', PHONE]]) {
      const p2 = await ctx.newPage();
      await p2.setViewportSize(vp);
      await p2.goto(URL, { waitUntil: 'networkidle', timeout: 60000 });
      await p2.waitForTimeout(700);
      const n2 = await reachCombat(p2);
      const portraitGate = await p2.locator('.rotate-hint, [class*=rotate]').first().count();
      if (label === 'phone' && portraitGate) {
        record('B4', 'B', '[phone portrait] Có gợi ý xoay ngang thay vì nhồi 5 cột', true,
          'Tìm thấy .rotate-hint', false);
        await p2.setViewportSize({ width: PHONE.height, height: PHONE.width });  // landscape
        await p2.waitForTimeout(500);
      }
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

  /* ---- tổng kết ---- */
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
