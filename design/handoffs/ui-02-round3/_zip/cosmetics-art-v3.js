/* Axie Dice · Cosmetics 01 pilot — v3, Axie part-icon rendering language.
   OBSERVED in godot/assets/icons/web/part/*.svg: every shape is drawn with a 5-tone ramp per hue —
   base, deep (hue-tinted outline, never pure black), mid (shade), pale, cream (highlight). Outlines are
   heavier on the lower-right, highlights are cream swooshes on the upper-left. This file reproduces that. */
(function () {
  const INK = '#1A1206';
  const TYPE = { dmg: '#F54540', shield: '#31C6FF', heal: '#3FCD3C', mana: '#BF6BFF', poison: '#A8D84A', buff: '#FF9345' };
  const TIERS = [
    { k: 'c', name: 'Common', biome: 'Savannah', color: '#C6CEDA' },
    { k: 'u', name: 'Uncommon', biome: 'Forest', color: '#40CC3D' },
    { k: 'r', name: 'Rare', biome: 'Arctic', color: '#33B8FF' },
    { k: 'e', name: 'Epic', biome: 'Mystic', color: '#BF6BFF' },
    { k: 'l', name: 'Legendary', biome: 'Genesis', color: '#FF9445' },
    { k: 'm', name: 'Mythic', biome: 'LunaLanding', color: '#FF3D6E', proposed: true },
  ];
  // 5-tone ramps. PL/AQ/BG/RP are lifted verbatim from the shipped part icons; the rest follow the same structure.
  const PAL = {
    PL: { b: '#AFDB1B', d: '#1F3A00', m: '#6F9E09', p: '#D2D9B3', c: '#FEFDF1' },
    AQ: { b: '#00F5F8', d: '#003E5C', m: '#009DAA', p: '#B7E2CD', c: '#F4FFF4' },
    BG: { b: '#FF433E', d: '#3B0000', m: '#DC1244', p: '#EFCCBB', c: '#FFFAF5' },
    RP: { b: '#9967FB', d: '#3B0948', m: '#7D4CE7', p: '#E2C8EF', c: '#FFF7FF' },
    ST: { b: '#F5C24A', d: '#4A2A00', m: '#D99A2B', p: '#F7DE9A', c: '#FFFBEF' },
    SN: { b: '#D9D6C6', d: '#2E2A1E', m: '#ADA993', p: '#ECEADF', c: '#FFFFFA' },
    WD: { b: '#D08A45', d: '#3A1A04', m: '#9A5A22', p: '#EFD2AE', c: '#FFF6E8' },
    IC: { b: '#8FE8FF', d: '#06395A', m: '#3FB8E6', p: '#D2F2FB', c: '#F7FEFF' },
    SW: { b: '#FFFFFF', d: '#06395A', m: '#CDE9F5', p: '#EEF8FC', c: '#FFFFFF' },
    MY: { b: '#B98AFF', d: '#2E0A52', m: '#8A55E6', p: '#E3D0FF', c: '#FFF8FF' },
    GD: { b: '#FFC93C', d: '#4A2500', m: '#E08A12', p: '#FFE7A3', c: '#FFFCEB' },
    KM: { b: '#FF9445', d: '#4A1A00', m: '#D9601A', p: '#FFD2AE', c: '#FFF1E4' },
    LU: { b: '#FF3D6E', d: '#3D0418', m: '#C3134A', p: '#F2C4D0', c: '#FFF4F7' },
    MN: { b: '#FFEFD9', d: '#3D0418', m: '#EBC7B4', p: '#FFF7EC', c: '#FFFFFF' },
    NT: { b: '#3A1640', d: '#12030F', m: '#24091F', p: '#5A2A62', c: '#C9A3CF' },
  };
  // ---------- maths ----------
  const lin = (c) => { c /= 255; return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); };
  const hex = (h) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16));
  const lum = (h) => { const [r, g, b] = hex(h).map(lin); return 0.2126 * r + 0.7152 * g + 0.0722 * b; };
  const contrast = (a, b) => { const x = lum(a), y = lum(b); return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05); };
  const hue = (h) => { const [r, g, b] = hex(h).map((v) => v / 255); const M = Math.max(r, g, b), m = Math.min(r, g, b), d = M - m; if (!d) return null; let H = M === r ? ((g - b) / d) % 6 : M === g ? (b - r) / d + 2 : (r - g) / d + 4; H *= 60; return H < 0 ? H + 360 : H; };
  function rng(seed) { let a = seed >>> 0; return function () { a = (a + 0x6D2B79F5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
  const J = (r, amt) => (r() * 2 - 1) * amt;
  const f = (n) => +(+n).toFixed(2);
  const P = (r, a, cx = 128, cy = 128) => { const t = (a * Math.PI) / 180; return [f(cx + r * Math.cos(t)), f(cy + r * Math.sin(t))]; };
  const pp = (p) => p[0] + ' ' + p[1];
  function smooth(pts, closed = true) {
    const n = pts.length, g = (i) => pts[closed ? (i + n) % n : Math.max(0, Math.min(n - 1, i))];
    let d = 'M' + f(pts[0][0]) + ' ' + f(pts[0][1]);
    for (let i = 0; i < (closed ? n : n - 1); i++) { const p0 = g(i - 1), p1 = g(i), p2 = g(i + 1), p3 = g(i + 2); d += 'C' + f(p1[0] + (p2[0] - p0[0]) / 6) + ' ' + f(p1[1] + (p2[1] - p0[1]) / 6) + ' ' + f(p2[0] - (p3[0] - p1[0]) / 6) + ' ' + f(p2[1] - (p3[1] - p1[1]) / 6) + ' ' + f(p2[0]) + ' ' + f(p2[1]); }
    return d + (closed ? 'Z' : '');
  }
  const blob = (cx, cy, rx, ry, n, j, r, rot = 0) => { const pts = []; for (let i = 0; i < n; i++) { const t = rot + (i / n) * Math.PI * 2, k = 1 + J(r, j); pts.push([cx + Math.cos(t) * rx * k, cy + Math.sin(t) * ry * k]); } return smooth(pts); };
  const circ = (cx, cy, r) => `M${f(cx - r)} ${f(cy)}a${f(r)} ${f(r)} 0 1 0 ${f(2 * r)} 0a${f(r)} ${f(r)} 0 1 0 ${f(-2 * r)} 0Z`;
  const ring = (r1, r2, cx = 128, cy = 128) => circ(cx, cy, r2) + `M${cx - r1} ${cy}a${r1} ${r1} 0 1 1 ${2 * r1} 0a${r1} ${r1} 0 1 1 ${-2 * r1} 0Z`;
  const ringBlob = (r1, r2, r, jo = 0.03, ji = 0.006, n = 20) => { const o = [], i = []; for (let k = 0; k < n; k++) { const t = (k / n) * Math.PI * 2; o.push([128 + Math.cos(t) * r2 * (1 + J(r, jo)), 128 + Math.sin(t) * r2 * (1 + J(r, jo))]); i.push([128 + Math.cos(t) * r1 * (1 + J(r, ji)), 128 + Math.sin(t) * r1 * (1 + J(r, ji))]); } return smooth(o) + smooth(i.reverse()); };
  const crescent = (cx, cy, r, k = 0.62) => `M${f(cx)} ${f(cy - r)}A${f(r)} ${f(r)} 0 1 1 ${f(cx)} ${f(cy + r)}A${f(r * k)} ${f(r)} 0 1 0 ${f(cx)} ${f(cy - r)}Z`;
  // tapered highlight swoosh along an arc (cream, upper-left)
  function swoosh(cx, cy, r, a0, a1, w) { const n = 10, o = [], i = []; for (let k = 0; k <= n; k++) { const t = k / n, a = a0 + (a1 - a0) * t, tw = w * Math.pow(Math.sin(Math.PI * t), 0.8); o.push(P(r + tw / 2, a, cx, cy)); i.push(P(r - tw / 2, a, cx, cy)); } return 'M' + o.map(pp).join('L') + 'L' + i.reverse().map(pp).join('L') + 'Z'; }
  const RUNES = ['M2 1V11M2 4L8 1M2 7L8 4', 'M5 1V11M1 4L5 7L9 4', 'M1 1L9 11M9 1L1 11', 'M2 11V1L8 5L2 8', 'M1 6H9M5 1V11M2 2L8 10', 'M2 1H8L2 11H8'];
  let uid = 0;
  function A(o, name, dur, extra) {
    if (o.static) return '';
    const soft = o.rf && /Pulse|Twinkle|Breathe|Sheen/.test(name) ? name + 'Soft' : name;
    return `animation:${soft} ${dur}s ${extra || 'ease-in-out infinite'};`;
  }
  /* toon(): one Axie-style shape. Deep outline (heavier lower-right), mid shade with the lit base shifted
     toward the light, optional inner detail clipped to the shape, cream highlight on top. */
  function toon(d, T, o = {}) {
    const id = 'k' + ++uid, ow = o.ow ?? 3, sx = o.sh ? o.sh[0] : -ow * 0.9, sy = o.sh ? o.sh[1] : -ow * 1.2, rule = o.rule ? ` fill-rule="${o.rule}" clip-rule="${o.rule}"` : '';
    return `<clipPath id="${id}"><path d="${d}"${rule}/></clipPath>` +
      `<path d="${d}"${rule} fill="${T.d}" stroke="${T.d}" stroke-width="${f(ow * 1.9)}" stroke-linejoin="round" transform="translate(${f(ow * 0.28)} ${f(ow * 0.38)})"/>` +
      `<path d="${d}"${rule} fill="${T.d}" stroke="${T.d}" stroke-width="${f(ow * 1.15)}" stroke-linejoin="round"/>` +
      `<g clip-path="url(#${id})"><path d="${d}"${rule} fill="${o.shade || T.m}"/><path d="${d}"${rule} fill="${o.fill || T.b}" transform="translate(${f(sx)} ${f(sy)})"/>${o.inner || ''}</g>` +
      (o.hl ? `<path d="${o.hl}" fill="${o.hlc || T.c}"/>` : '');
  }
  const twinkle = (x, y, r, fill, style) => `<path d="M${f(x)} ${f(y - r)}Q${f(x + r * 0.14)} ${f(y - r * 0.14)} ${f(x + r * 0.78)} ${f(y)}Q${f(x + r * 0.14)} ${f(y + r * 0.14)} ${f(x)} ${f(y + r * 0.82)}Q${f(x - r * 0.14)} ${f(y + r * 0.14)} ${f(x - r * 0.72)} ${f(y)}Q${f(x - r * 0.14)} ${f(y - r * 0.14)} ${f(x)} ${f(y - r)}Z" fill="${fill}" style="transform-origin:${f(x)}px ${f(y)}px;${style || ''}"/>`;
  // Axie part icons, inlined so exported PNGs keep them
  const PARTS = {};
  const PART = (name, x, y, size, rot = 0) => PARTS[name] ? `<g transform="translate(${x} ${y}) rotate(${rot}) scale(${f(size / 48)}) translate(-24 -24)">${PARTS[name]}</g>` : '';
  // chunky Axie leaf along +x
  function leaf(L, W, T, r, ow = 2.6) {
    const a1 = W * (1 + J(r, 0.12)), b1 = W * (0.82 + J(r, 0.1)), c = J(r, W * 0.15);
    const d = `M0 0C${f(L * 0.2)} ${f(-a1 * 1.15)} ${f(L * 0.78)} ${f(-a1)} ${f(L)} ${f(c)}C${f(L * 0.72)} ${f(b1)} ${f(L * 0.22)} ${f(b1 * 1.05)} 0 0Z`;
    const vein = `M${f(L * 0.1)} ${f(-W * 0.06)}Q${f(L * 0.5)} ${f(-W * 0.28)} ${f(L * 0.86)} ${f(c * 0.8 - W * 0.04)}L${f(L * 0.84)} ${f(c * 0.8 + W * 0.1)}Q${f(L * 0.5)} ${f(-W * 0.06)} ${f(L * 0.12)} ${f(W * 0.08)}Z`;
    return toon(d, T, { ow, sh: [-ow * 0.5, -ow * 1.3], hl: vein });
  }
  // faceted crystal (two faces, cream edge highlight)
  function crystal(x, by, h, w, lean, T, ow) {
    const bl = [x - w / 2, by], br = [x + w / 2, by], sl = [x - w / 2 - lean * 0.15, by - h * 0.66], sr = [x + w / 2 - lean * 0.05, by - h * 0.6], tp = [x + lean, by - h], mid = [x + lean * 0.45 + w * 0.06, by - h * 0.58], mb = [x + w * 0.08, by];
    const d = `M${pp(bl)}L${pp(sl)}L${pp(tp)}L${pp(sr)}L${pp(br)}Z`;
    const lit = `<path d="M${pp(bl)}L${pp(sl)}L${pp(tp)}L${pp(mid)}L${pp(mb)}Z" fill="${T.b}"/>`;
    const hl = `M${f(sl[0] + w * 0.16)} ${f(sl[1] + 1)}L${f(tp[0] - w * 0.05)} ${f(tp[1] + h * 0.16)}L${f(tp[0] - w * 0.12)} ${f(tp[1] + h * 0.3)}L${f(sl[0] + w * 0.22)} ${f(sl[1] + h * 0.2)}Z`;
    return toon(d, T, { ow, fill: T.m, shade: T.m, sh: [0, 0], inner: lit + `<path d="M${pp(tp)}L${pp(mid)}L${pp(mb)}" stroke="${T.d}" stroke-width="${f(ow * 0.45)}" fill="none" stroke-linejoin="round" opacity=".55"/>`, hl });
  }
  function moon(cx, cy, r, ow) {
    const T = PAL.MN, cr = (x, y, rr) => `<path d="${circ(x, y, rr)}" fill="${T.m}"/><path d="M${f(x - rr * 0.7)} ${f(y + rr * 0.3)}A${rr} ${rr} 0 0 0 ${f(x + rr * 0.7)} ${f(y + rr * 0.3)}" stroke="${T.c}" stroke-width="${f(rr * 0.35)}" fill="none" stroke-linecap="round"/>`;
    return toon(crescent(cx, cy, r), T, { ow, sh: [-ow * 0.4, -ow * 0.9], inner: cr(cx + r * 0.62, cy - r * 0.32, r * 0.14) + cr(cx + r * 0.78, cy + r * 0.12, r * 0.09) + cr(cx + r * 0.5, cy + r * 0.55, r * 0.1), hl: swoosh(cx, cy, r * 0.82, -70, 10, r * 0.13) });
  }
  const studs = (pts, T, rr, ow) => pts.map(([x, y]) => toon(circ(x, y, rr), T, { ow, hl: circ(x - rr * 0.32, y - rr * 0.34, rr * 0.3) })).join('');

  // ---------- DIE PLATES (104 face space; band hides y < 24.96; calm zone below) ----------
  const CZ = { x: 10.4, y: 45.8, w: 83.2, h: 37.4 };
  const DIE = {
    die_c_reed: {
      tier: 0, name: 'Sunbaked Weave', border: '#000', calm: ['#F7DE9A', '#F5C24A', '#D99A2B'],
      spec: ['Border #000, 4 px at s=104 (3 px on the 36 px egg token).', 'Straw ramp (Axie 5-tone): base #F5C24A, shade #D99A2B, pale #F7DE9A, cream #FFFBEF, deep #4A2A00.', 'Chunky two-strand weave on 26 px cells. Inside the calm zone the strands separate with the shade tone only (6.4:1 to ink). The deep outline is kept for the braided rim along the bottom 15 px.', 'Static.'],
      plate() {
        const T = PAL.ST, r = rng(5); let s = `<rect width="104" height="104" fill="${T.p}"/>`;
        for (let i = 0; i < 4; i++) for (let j = 0; j < 4; j++) {
          const x = j * 26, y = i * 26, h = (i + j) % 2 === 0;
          for (let k = 0; k < 2; k++) {
            const d = h ? `M${x + 1} ${y + 1.5 + k * 12.5}h24a5.5 5.5 0 0 1 0 11h-24a5.5 5.5 0 0 1 0 -11Z` : `M${x + 1.5 + k * 12.5} ${y + 1}h11v24a5.5 5.5 0 0 1 -11 0Z`;
            const hl = h ? `M${x + 4 + r() * 2} ${y + 4 + k * 12.5}h${f(9 + r() * 6)}a1.3 1.3 0 0 1 0 2.6h-${f(9)}a1.3 1.3 0 0 1 0 -2.6Z` : `M${x + 4 + k * 12.5} ${y + 4 + r() * 2}h2.6v${f(8 + r() * 6)}a1.3 1.3 0 0 1 -2.6 0Z`;
            s += toon(d, { b: T.b, d: T.m, m: '#E6AE3E', c: '#FCE7A6' }, { ow: 1, sh: [-1, -1.4], hl });
          }
        }
        s += `<path d="M-2 88C24 86.6 50 88.8 76 87.4S100 87 106 87.6V106H-2Z" fill="${T.d}"/>`;
        for (let x = -3, k = 0; x < 108; x += 7.4, k++) { const d = `M${f(x - 5.6)} 99.5C${f(x - 5)} 92 ${f(x + 3)} 89.5 ${f(x + 5.6)} 92C${f(x + 5)} 99 ${f(x - 2)} 102.5 ${f(x - 5.6)} 99.5Z`; s += toon(d, T, { ow: 1.1, hl: `M${f(x - 2.6)} 95C${f(x - 1.6)} 92.6 ${f(x + 1)} 91.6 ${f(x + 2.6)} 92.4C${f(x + 0.6)} 93 ${f(x - 1)} 94.4 ${f(x - 2.6)} 95Z` }); }
        return s;
      },
    },
    die_u_moss: {
      tier: 1, name: 'Mossy Pebble', border: '#000', calm: ['#ECEADF', '#D9D6C6', '#ADA993'],
      spec: ['Border #000, 4 px.', 'Stone ramp: base #D9D6C6, shade #ADA993, pale #ECEADF, cream #FFFFFA. Moss uses the shipped Plant ramp (#AFDB1B / #6F9E09 / deep #1F3A00 / cream #FEFDF1).', 'Six chubby river stones, each lit from the upper left with a cream swoosh. Inside the calm zone they outline in shade #ADA993 only.', 'Moss pillows creep in from the bottom and both sides, with two Axie-style leaves at the lower right. Static.'],
      plate() {
        const S = PAL.SN, L = PAL.PL, r = rng(9); let s = `<rect width="104" height="104" fill="${S.m}"/>`;
        [[16, 36, 22, 15], [56, 34, 22, 13], [94, 40, 16, 16], [24, 64, 22, 15], [70, 64, 26, 15], [8, 92, 18, 12], [50, 92, 22, 12], [96, 88, 14, 12]].forEach(([x, y, rx, ry]) => {
          s += toon(blob(x, y, rx, ry, 9, 0.08, r), { b: S.b, d: S.m, m: '#C4C0AC', c: S.c }, { ow: 1.4, sh: [-2, -2.8], hl: swoosh(x, y, Math.min(rx, ry) * 0.72, 196, 250, 2.8) });
        });
        const pts = []; for (let x = -6; x <= 110; x += 9) pts.push([x, 88 + J(r, 3) + (x > 36 && x < 64 ? 2 : 0)]);
        const moss = 'M-6 110' + smooth(pts, false).replace('M', 'L') + 'L110 110Z';
        s += toon(moss, L, { ow: 2, sh: [0, -3], inner: [12, 30, 48, 66, 84, 100].map((x) => `<path d="${circ(x + J(r, 2), 93 + J(r, 1.5), 1.4 + r())}" fill="${L.c}" opacity=".9"/>`).join('') });
        s += toon(blob(2, 62, 8, 15, 8, 0.15, r), L, { ow: 2, hl: swoosh(2, 62, 6, 200, 260, 2) }) + toon(blob(103, 44, 7, 12, 8, 0.15, r), L, { ow: 2 });
        s += `<g transform="translate(80 88) rotate(-128)">${leaf(14, 5.5, L, r, 1.6)}</g><g transform="translate(80 88) rotate(-62)">${leaf(11, 4.5, L, r, 1.6)}</g>`;
        return s;
      },
    },
    die_r_aqua: {
      tier: 2, name: 'Tidepool', tag: 'Mastery · Aquatic', border: '#000', calm: ['#A9F1EC', '#7FE0DD'],
      spec: ['Border #000, 4 px.', 'Aquatic ramp, verbatim from the shipped part icons: #00F5F8 / shade #009DAA / deep #003E5C / pale #B7E2CD / cream #F4FFF4.', 'Two materials: soft scale field (#A9F1EC with #7FE0DD scallops) and a curling wave with cream foam. Bubbles drift up both edges.', 'Mastery emblem: the Aquatic tail part icon (tail_aqua.svg, used as-is) sits in the lower-left corner. Static.'],
      plate() {
        const T = PAL.AQ, r = rng(13); let s = `<rect width="104" height="104" fill="#A9F1EC"/>`, d = '';
        for (let row = 0; row < 15; row++) { const y = row * 7.2, off = (row % 2) * 6.5; for (let x = -13 + off; x < 110; x += 13) d += `M${f(x)} ${f(y)}a6.5 6.2 0 0 0 13 0`; }
        s += `<path d="${d}" stroke="#7FE0DD" stroke-width="1.5" fill="none"/>`;
        const wp = [[-4, 92], [9, 85.5], [21, 90], [34, 84], [48, 90.5], [61, 85], [74, 89.5], [88, 83.5], [100, 89], [110, 86]];
        s += toon('M-4 110' + smooth(wp, false).replace('M', 'L') + 'L110 110Z', T, { ow: 2, sh: [0, -3.4] });
        [[9, 85.5], [34, 84], [61, 85], [88, 83.5]].forEach(([x, y]) => (s += `<path d="M${f(x - 6)} ${f(y + 3)}C${f(x - 4)} ${f(y - 3)} ${f(x + 4)} ${f(y - 3.5)} ${f(x + 6)} ${f(y + 0.5)}C${f(x + 3)} ${f(y - 1)} ${f(x - 1)} ${f(y)} ${f(x - 6)} ${f(y + 3)}Z" fill="${T.c}"/>`));
        const bub = (x, y, rr) => toon(circ(x, y, rr), { b: '#E4FFFD', d: T.d, m: '#B7E2CD', c: '#FFFFFF' }, { ow: 1.2, sh: [-rr * 0.25, -rr * 0.3], hl: circ(x - rr * 0.36, y - rr * 0.38, rr * 0.26) });
        s += bub(6, 64, 3.8) + bub(8.6, 72.5, 2.2) + bub(5, 78, 1.5) + bub(97, 36, 4.4) + bub(99.5, 46, 2.4) + bub(93, 29, 1.7);
        return s + PART('tail_aqua', 13, 92, 24, -8);
      },
    },
    die_e_rune: {
      tier: 3, name: 'Moonrune Tablet', border: '#2E0A52', calm: ['#DCC8FF', '#C9AEFA'],
      spec: ['Border #2E0A52 (Mystic deep), 4 px. Reads as black at 36 px.', 'Mystic ramp: base #B98AFF, shade #8A55E6, deep #2E0A52, pale #E3D0FF, cream #FFF8FF.', 'Ornament: a carved inset frame and four faceted amethysts at the corners, toon-shaded like part icons. Runes are carved, with a shade groove and a cream lower lip.', 'glow.png: rune underlay #BF6BFF 5 px, blend Add. Idle: pulse 0.35→0.9, 2.0 s ease-in-out. Reduce flashing: 0.55→0.7.'],
      plate(o) {
        const T = PAL.MY, r = rng(17); let s = `<rect width="104" height="104" fill="#DCC8FF"/>`;
        s += `<path d="M6 30Q6 6 30 6H74Q98 6 98 30V74Q98 98 74 98H30Q6 98 6 74Z" fill="none" stroke="#C9AEFA" stroke-width="5"/><path d="M8 30Q8 8 30 8H74Q96 8 96 30V74Q96 96 74 96H30Q8 96 8 74Z" fill="none" stroke="${T.m}" stroke-width="1.6"/>`;
        let glyph = '';
        [[19.5, 0], [33.5, 1], [48.5, 2], [62.5, 3], [77, 4]].forEach(([x, i]) => { glyph += `<path transform="translate(${f(x - 4.5)} ${f(85.5 + J(r, 0.5))}) rotate(${f(J(r, 5))} 5 6) scale(.9)" d="${RUNES[i]}"/>`; });
        glyph += `<path transform="translate(1.8 57) scale(.74)" d="${RUNES[1]}"/><path transform="translate(94.6 59) scale(.74)" d="${RUNES[4]}"/>`;
        s += `<g stroke="#BF6BFF" stroke-width="5" stroke-linecap="round" fill="none" opacity="${o.static ? 0.55 : 0.35}" style="${A(o, 'cosPulse', 2)}">${glyph}</g>`;
        s += `<g stroke="${T.c}" stroke-width="1.2" stroke-linecap="round" fill="none" transform="translate(.6 .9)">${glyph}</g><g stroke="${T.d}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" fill="none">${glyph}</g>`;
        const gem = (x, y, rr, rot) => { const pts = []; for (let i = 0; i < 5; i++) { const t = rot + (i / 5) * Math.PI * 2; pts.push([x + Math.cos(t) * rr, y + Math.sin(t) * rr * 1.12]); } const d = 'M' + pts.map((q) => f(q[0]) + ' ' + f(q[1])).join('L') + 'Z'; return toon(d, T, { ow: 1.5, sh: [-rr * 0.3, -rr * 0.4], inner: `<path d="M${f(pts[2][0])} ${f(pts[2][1])}L${x} ${y}L${f(pts[3][0])} ${f(pts[3][1])}" stroke="${T.d}" stroke-width=".8" fill="none" opacity=".5"/>`, hl: `M${f(x - rr * 0.55)} ${f(y - rr * 0.1)}L${f(x - rr * 0.1)} ${f(y - rr * 0.75)}L${f(x + rr * 0.05)} ${f(y - rr * 0.45)}L${f(x - rr * 0.35)} ${f(y + rr * 0.1)}Z` }); };
        return s + gem(8, 96, 6.2, -1.57) + gem(96, 96, 6.2, -1.57) + gem(7, 38, 4.4, -1.57) + gem(97, 38, 4.4, -1.57);
      },
    },
    die_l_gold: {
      tier: 4, name: 'Genesis Sunplate', border: '#4A2500', calm: ['#FFE7A3', '#FFF1C4'],
      spec: ['Border #4A2500 (Genesis deep), 4 px.', 'Gold ramp: base #FFC93C, shade #E08A12, deep #4A2500, pale #FFE7A3, cream #FFFCEB.', 'Ornament: a soft fan of cream rays from a chubby half-sun on the bottom edge (11 rounded rays, toon-shaded), gold rivets and a carved inset frame.', 'glow.png: diagonal sheen, white 50 %, blend Add. Idle: sweeps across in 1.1 s, then rests. 3.2 s loop. Reduce flashing: sheen at 20 %.'],
      plate(o) {
        const T = PAL.GD, r = rng(21); let s = `<rect width="104" height="104" fill="${T.p}"/>`;
        for (let a = 196; a < 344; a += 13.4) { const [x1, y1] = P(170, a, 52, 112), [x2, y2] = P(170, a + 6.2, 52, 112); s += `<path d="M52 112L${x1} ${y1}L${x2} ${y2}Z" fill="#FFF1C4"/>`; }
        s += `<path d="M6 30Q6 6 30 6H74Q98 6 98 30V74Q98 98 74 98H30Q6 98 6 74Z" fill="none" stroke="#FFD978" stroke-width="4"/><path d="M8 30Q8 8 30 8H74Q96 8 96 30V74Q96 96 74 96H30Q8 96 8 74Z" fill="none" stroke="${T.m}" stroke-width="1.4"/>`;
        for (let k = 0; k < 11; k++) { const a = 196 + k * 14.8, [b1x, b1y] = P(20, a - 5, 52, 108), [b2x, b2y] = P(20, a + 5, 52, 108), L = k % 2 ? 27 : 31, [tx, ty] = P(L, a, 52, 108), [c1x, c1y] = P(L + 2, a - 3, 52, 108), [c2x, c2y] = P(L + 2, a + 3, 52, 108); s += toon(`M${b1x} ${b1y}L${c1x} ${c1y}Q${tx} ${ty} ${c2x} ${c2y}L${b2x} ${b2y}Z`, T, { ow: 1.4 }); }
        s += toon(circ(52, 108, 20), T, { ow: 2.2, sh: [-3, -4], inner: `<path d="${circ(52, 108, 12)}" fill="#FFE07A"/>`, hl: swoosh(52, 108, 15, 200, 250, 4) });
        s += studs([[13, 86], [91, 86]], T, 3.4, 1.3);
        s += `<g style="${A(o, 'cosSheen', 3.2)}"><path d="M-40 0H-24L-54 104H-70Z" fill="#FFFFFF" opacity=".5"/><path d="M-19 0H-15L-45 104H-49Z" fill="#FFFFFF" opacity=".45"/></g>`;
        return s;
      },
    },
    die_m_redcrystal: {
      tier: 5, name: 'Luna Heartcrystal', border: '#3D0418', calm: ['#FFF4F7', '#F2C4D0'], dark: true,
      spec: ['Dark skin, so it gets a LIGHT VALUE PLATE: cream #FFF4F7 with a pale #F2C4D0 lower lip, 3 px deep #3D0418 outline, sized to the calm zone. Ink stays #1A1206.', 'Border #3D0418 (Luna deep), 4 px. Field: starlit plum #2A0F2E with nebula patches #3A1640.', 'Luna ramp: base #FF3D6E, shade #C3134A, deep #3D0418, pale #F2C4D0, cream #FFF4F7. Crystals have two faces and a cream edge glint; the moon is cream with craters.', 'Idle: 3 sparkles twinkle 1.6 s, staggered; crystal glint 2.8 s. Reduce flashing: opacity only.', 'MAX settle: the crescent fills to a full moon for 0.6 s while the crystals grow 1→1.15 (ease-out-back). Reduced: crystals only.'],
      plate(o) {
        const T = PAL.LU, r = rng(25); let s = `<rect width="104" height="104" fill="#2A0F2E"/>`;
        s += `<path d="${blob(22, 36, 24, 10, 9, 0.25, r)}" fill="#3A1640"/><path d="${blob(84, 94, 22, 10, 9, 0.25, r)}" fill="#331338"/>`;
        [[18, 32], [44, 30], [70, 40], [97, 70], [30, 41], [53, 38], [4, 52]].forEach(([x, y]) => (s += `<circle cx="${x}" cy="${y}" r="${f(0.6 + r() * 0.7)}" fill="#C9A3CF"/>`));
        s += moon(87, 35.5, 9, 1.4);
        [[8, 35.5, 4.4, 0], [62, 32, 3.2, 0.5], [6, 86, 3, 1.1]].forEach(([x, y, rr, dl]) => (s += twinkle(x, y, rr, T.c, A(o, 'cosTwinkle', 1.6, `ease-in-out ${dl}s infinite`))));
        const D = { b: '#FF6F93', d: T.d, m: T.m, c: T.c };
        s += crystal(4, 106, 17, 8, -1.5, T, 1.5) + crystal(15.5, 106, 24, 10, 2, D, 1.7) + crystal(26, 106, 12, 6.5, 2.5, T, 1.4);
        s += crystal(100, 106, 15, 8, 1.5, T, 1.5) + crystal(88.5, 106, 22, 9.5, -2.5, D, 1.7) + crystal(78, 106, 10, 6, -1, T, 1.3) + crystal(52, 106, 10, 6.5, 1, D, 1.3);
        s += toon(`M${CZ.x + 9} ${CZ.y}H${CZ.x + CZ.w - 9}Q${CZ.x + CZ.w} ${CZ.y} ${CZ.x + CZ.w} ${CZ.y + 9}V${CZ.y + CZ.h - 9}Q${CZ.x + CZ.w} ${CZ.y + CZ.h} ${CZ.x + CZ.w - 9} ${CZ.y + CZ.h}H${CZ.x + 9}Q${CZ.x} ${CZ.y + CZ.h} ${CZ.x} ${CZ.y + CZ.h - 9}V${CZ.y + 9}Q${CZ.x} ${CZ.y} ${CZ.x + 9} ${CZ.y}Z`, { b: T.c, d: T.d, m: T.p, c: '#FFFFFF' }, { ow: 1.6, sh: [0, -3] });
        s += twinkle(15, 86, 3.6, '#FFFFFF', A(o, 'cosTwinkle', 2.8, 'ease-in-out 0.6s infinite'));
        return s;
      },
    },
  };
  Object.values(DIE).forEach((d) => { d.contrast = Math.min(...d.calm.map((c) => contrast(c, INK))); });

  function plateSVG(id, o = {}) {
    const u = ++uid;
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 104 104" width="${o.size || 512}" height="${o.size || 512}"><defs><clipPath id="cp${u}"><rect width="104" height="104"/></clipPath></defs><g clip-path="url(#cp${u})">${DIE[id].plate(o)}</g></svg>`;
  }
  const CLASS = { plant: '#7DC943', aqua: '#39C5F3', beast: '#FFB23F', reptile: '#B679F7', bug: '#F2624F', bird: '#8BDCFF' };
  function dieSVG(id, s, o = {}) {
    const d = DIE[id], k = 104 / s, bw = (s <= 40 ? 3 : 4) * k, u = ++uid;
    const cls = CLASS[o.cls || 'plant'], val = String(o.value ?? 6), type = o.type || 'dmg';
    const fs = 41.6, iw = 31.2, gap = 6.24, tw = 0.56 * fs * val.length, x0 = -(tw + gap + iw) / 2 + 52, cy = 52 + 12.48, R = 18.72, h = bw / 2;
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 104 104" width="${s}" height="${s}" style="display:block;overflow:visible"><defs><clipPath id="cd${u}"><rect width="104" height="104" rx="${R}"/></clipPath></defs>
<g clip-path="url(#cd${u})">${d.plate(o)}</g>
<path d="M${h} 24.96V${R}A${R - h} ${R - h} 0 0 1 ${R} ${h}H${104 - R}A${R - h} ${R - h} 0 0 1 ${104 - h} ${R}V24.96Z" fill="${cls}" stroke="#000" stroke-width="${bw}"/>
<text x="${x0}" y="${cy}" dominant-baseline="central" font-family="'Baloo 2',cursive" font-weight="800" font-size="${fs}" fill="${INK}" dy="2">${val}</text>
<rect x="${x0 + tw + gap}" y="${cy - iw / 2}" width="${iw}" height="${iw}" rx="7" fill="${TYPE[type]}" stroke="#000" stroke-width="${(bw / k - 1) * k}"/>
<image href="assets/icons/${type}.png" x="${x0 + tw + gap + iw * 0.18}" y="${cy - iw / 2 + iw * 0.18}" width="${iw * 0.64}" height="${iw * 0.64}"/>
<rect x="${h}" y="${h}" width="${104 - bw}" height="${104 - bw}" rx="${R - h}" fill="none" stroke="${d.border}" stroke-width="${bw}"/></svg>`;
  }

  // ---------- AVATAR FRAMES (256 canvas, window circle Ø168) ----------
  const bandToon = (d, T, extra, hlR) => toon(d, T, { ow: 3.6, rule: 'evenodd', sh: [-3, -4.2], inner: extra || '', hl: swoosh(128, 128, hlR || 91, 196, 252, 6.5) });
  const FRAME = {
    frame_c_plant: {
      tier: 0, name: 'Sprout Wreath', tag: 'Mastery · Plant', seed: 101,
      spec: ['Static. Plant ramp, verbatim from the shipped part icons: #AFDB1B / shade #6F9E09 / deep #1F3A00 / cream #FEFDF1. The outer outline is the deep #1F3A00, which reads as black at 40 px.', 'A chubby vine band (r 82–98) with a cream gloss swoosh at 10 o’clock and shade-tone bark nicks.', '10 Axie-style leaves (fat, with a cream vein), grouped in threes and denser at the top. The sprout at 12 o’clock is the 40 px silhouette cue.', 'Mastery emblem: the Plant horn part icon (horn_plant.svg, used as-is) as a badge at 6 o’clock.', 'Shelf shadow: black 50 %, offset (0, 6), no blur.'],
      base() {
        const T = PAL.PL, r = rng(this.seed); let s = '';
        [[-160, 30], [-140, 26], [-118, 22], [-62, 22], [-40, 26], [-20, 30], [22, 22], [158, 22], [40, 18], [140, 18]].forEach(([a, L], i) => { const [x, y] = P(95, a); s += `<g transform="translate(${x} ${y}) rotate(${f(a + (i % 2 ? 34 : -34))})">${leaf(L + r() * 6, (L + 4) * 0.34, T, r, 2.8)}</g>`; });
        let nicks = ''; for (let k = 0; k < 14; k++) { const a = k * 25.7 + J(r, 6), [x1, y1] = P(86 + r() * 6, a), [x2, y2] = P(88 + r() * 6, a + 6); nicks += `<path d="M${x1} ${y1}L${x2} ${y2}" stroke="${T.m}" stroke-width="2.2" stroke-linecap="round"/>`; }
        s += bandToon(ringBlob(82, 98, r, 0.028), T, nicks);
        s += `<path d="M127 36C125 28 127 22 132 17" stroke="${T.d}" stroke-width="9" fill="none" stroke-linecap="round"/><path d="M127 36C125 28 127 22 132 17" stroke="${T.m}" stroke-width="4" fill="none" stroke-linecap="round"/>`;
        s += `<g transform="translate(132 18) rotate(-146)">${leaf(44, 17, T, r, 3)}</g><g transform="translate(132 18) rotate(-40)">${leaf(36, 14, T, r, 3)}</g>`;
        s += PART('horn_plant', 128, 226, 50, 0);
        return s;
      },
    },
    frame_u_mushroom: {
      tier: 1, name: 'Toadstool Log', seed: 202,
      spec: ['Static. Wood ramp: base #D08A45, shade #9A5A22, deep #3A1A04, pale #EFD2AE, cream #FFF6E8.', 'A chubby log ring with long bark grooves and a cut knot at 2 o’clock. Moss pillows use the Plant ramp.', 'Mushroom caps use the shipped Bug ramp (#FF433E / #DC1244 / deep #3B0000 / cream #FFFAF5): one big leaning toadstool, a squat one and two babies at 8 o’clock, plus a pair at 1 o’clock. Cream spots, pale gills.', 'The two asymmetric clusters carry the 40 px read.'],
      base() {
        const W = PAL.WD, B = PAL.BG, L = PAL.PL, r = rng(this.seed); let s = '';
        let grooves = ''; for (let k = 0; k < 16; k++) { const a = k * 22.5 + J(r, 6), rr = 86 + r() * 8; grooves += `<path d="M${pp(P(rr, a))}Q${pp(P(rr + J(r, 1.5), a + 6))} ${pp(P(rr, a + 10 + r() * 4))}" stroke="${W.m}" stroke-width="2.2" fill="none" stroke-linecap="round"/>`; }
        s += bandToon(ringBlob(82, 98, r, 0.022), W, grooves);
        const [kx, ky] = P(90, -36);
        s += toon(blob(kx, ky, 7, 5.5, 8, 0.1, r), W, { ow: 1.8, fill: W.p, inner: `<path d="${blob(kx, ky, 3.6, 2.8, 7, 0.1, r)}" fill="${W.m}"/><path d="${blob(kx, ky, 1.5, 1.2, 6, 0.1, r)}" fill="${W.d}"/>` });
        const [mx, my] = P(97, -132), [m2x, m2y] = P(97, 64);
        s += toon(blob(mx, my, 15, 7, 9, 0.22, r, -0.65), L, { ow: 2.6, hl: swoosh(mx, my, 5, 200, 260, 2.4) }) + toon(blob(m2x, m2y, 12, 6, 9, 0.2, r, 1.1), L, { ow: 2.6 });
        const mush = (a, sc, lean, squat) => {
          const [x, y] = P(99, a), hh = squat ? 13 : 21;
          const stem = `M-7.5 2C-8.5 -6 -6.5 -${hh - 4} -5.5 -${hh}L6 -${hh}C6.5 -${hh - 6} 9.5 -6 8.5 2Z`;
          const cap = `M-26 ${-hh + 3}C-28 ${-hh - 20} -8 ${-hh - 29} 3 ${-hh - 28}C19 ${-hh - 26} 28 ${-hh - 12} 26 ${-hh + 3}C12 ${-hh + 7} -12 ${-hh + 7} -26 ${-hh + 3}Z`;
          let spots = ''; [[-12, -hh - 12, 5], [6, -hh - 20, 3.6], [16, -hh - 8, 3], [-2, -hh - 4, 2.2]].forEach(([sx, sy, sr]) => (spots += `<path d="${blob(sx, sy, sr, sr * 0.85, 7, 0.12, r)}" fill="${B.c}"/>`));
          return `<g transform="translate(${x} ${y}) rotate(${a + 90 + lean}) scale(${sc})">${toon(stem, { b: '#FFF4E2', d: B.d, m: B.p, c: '#FFFFFF' }, { ow: 2.6, sh: [-3, 0] })}<path d="M-22 ${-hh + 2}Q0 ${-hh + 9} 22 ${-hh + 2}Z" fill="${B.p}"/>${toon(cap, B, { ow: 3, sh: [-3, -3.6], inner: spots, hl: `M-20 ${-hh - 8}C-18 ${-hh - 17} -10 ${-hh - 22} -2 ${-hh - 23}C-9 ${-hh - 19} -15 ${-hh - 14} -17 ${-hh - 6}Z` })}</g>`;
        };
        s += mush(154, 0.6, 8, true) + mush(113, 0.52, -10, false) + mush(132, 1.06, 14, false) + mush(-62, 0.58, -6, false) + mush(-40, 0.8, 10, true);
        return s;
      },
    },
    frame_r_frost: {
      tier: 2, name: 'Frost Crown', seed: 303,
      spec: ['Static. Two materials. Ice ramp: base #8FE8FF, shade #3FB8E6, deep #06395A, pale #D2F2FB, cream #F7FEFF. Snow: white, shade #CDE9F5, the same deep outline.', 'A chubby ice band with cream facet glints, and a six-spike crown that leans slightly right. Every spike has a lit left face and a shaded right face. The crown is the 40 px silhouette.', 'A snow pillow on the left, three icicles of different lengths at the bottom, and one cream snowflake at 2 o’clock.'],
      base() {
        const T = PAL.IC, S = PAL.SW, r = rng(this.seed); let s = '';
        [[-118, 34, 9, 2], [-95, 52, 11, 4], [-72, 32, 9, 3], [-141, 21, 7, 1], [-50, 20, 7, 2], [-84, 16, 5, 1]].forEach(([a, L, hw, lean]) => { const b1 = P(95, a - hw), b2 = P(95, a + hw), tp = P(95 + L, a + lean), m = P(95, a + lean * 0.3); s += toon(`M${pp(b1)}L${pp(tp)}L${pp(b2)}Z`, T, { ow: 3, fill: T.m, shade: T.m, sh: [0, 0], inner: `<path d="M${pp(b1)}L${pp(tp)}L${pp(m)}Z" fill="${T.b}"/>`, hl: `M${pp(P(97, a - hw * 0.55))}L${pp(P(95 + L * 0.72, a + lean * 0.5 - 1))}L${pp(P(97, a - hw * 0.15))}Z`, hlc: T.c }); });
        let glints = ''; for (let k = 0; k < 10; k++) { const a = k * 36 + J(r, 8); glints += `<path d="M${pp(P(86, a))}L${pp(P(95, a + 4))}" stroke="${T.p}" stroke-width="2.4" stroke-linecap="round"/>`; }
        s += bandToon(ringBlob(82, 99, r, 0.04, 0.008), T, glints);
        [[72, 13], [86, 21], [101, 14]].forEach(([a, L]) => { const b1 = P(97, a - 3.5), b2 = P(97, a + 3.5), tp = P(97 + L, a + 1); s += toon(`M${pp(b1)}Q${pp(P(97 + L * 0.6, a - 2))} ${pp(tp)}Q${pp(P(97 + L * 0.6, a + 3))} ${pp(b2)}Z`, T, { ow: 2.2 }); });
        const pts = []; for (let a = 138; a <= 210; a += 9) pts.push(P(103 + J(r, 3) + (a > 160 && a < 190 ? 5 : 0), a));
        const back = []; for (let a = 210; a >= 138; a -= 14) back.push(P(87, a));
        s += toon(smooth(pts.concat(back)), S, { ow: 3, sh: [-2, -3.5], hl: swoosh(128, 128, 101, 168, 196, 4) });
        const [fx0, fy0] = P(105, 28); let fl = '';
        for (let q = 0; q < 6; q++) { const t = q * 60 + 8, L = 9.5, e = P(L, t, fx0, fy0), m = P(L * 0.55, t, fx0, fy0), b1 = P(3.6, t + 50, m[0], m[1]), b2 = P(3.6, t - 50, m[0], m[1]); fl += `M${fx0} ${fy0}L${pp(e)}M${pp(m)}L${pp(b1)}M${pp(m)}L${pp(b2)}`; }
        s += `<path d="${fl}" stroke="${T.d}" stroke-width="6" stroke-linecap="round"/><path d="${fl}" stroke="${T.c}" stroke-width="2.4" stroke-linecap="round"/>`;
        return s;
      },
    },
    frame_e_runering: {
      tier: 3, name: 'Runewheel', seed: 404,
      spec: ['Base (static): Mystic ramp (base #B98AFF, shade #8A55E6, deep #2E0A52, cream #FFF8FF). A carved stone band with a cream gloss swoosh and four faceted amethysts placed off-axis.', 'anim/rune_ring.png: outer band r 102–120, toon-shaded #9967FB (Reptile ramp, verbatim), with 11 carved runes, unevenly spaced. Rotates 360° in 16 s, linear. Its shelf shadow is a plain ring, so it stays static.', 'anim/rune_glow.png: rune underlay #F1E2FF 6 px, opacity 0.2→0.9, 2.0 s ease-in-out.', 'Reduce flashing: rotation unchanged; glow 0.5→0.65.'],
      shadowExtra: `<path d="${ring(102, 120)}" fill-rule="evenodd"/>`,
      base() {
        const T = PAL.MY, r = rng(this.seed); let s = '';
        s += bandToon(ringBlob(82, 97, r, 0.018), T, `<path d="M${pp(P(85, 150))}l-4 5l2 4M${pp(P(85, -20))}l5 -2l2 3" stroke="${T.d}" stroke-width="1.6" fill="none" stroke-linecap="round" opacity=".6"/>`);
        const gem = (a, rr) => { const [cx, cy] = P(89.5, a), pts = []; for (let i = 0; i < 6; i++) { const t = (a * Math.PI) / 180 + (i / 6) * Math.PI * 2; pts.push([cx + Math.cos(t) * rr * (i % 3 === 0 ? 1.3 : 0.9), cy + Math.sin(t) * rr * (i % 3 === 0 ? 1.3 : 0.9)]); } return toon('M' + pts.map((q) => f(q[0]) + ' ' + f(q[1])).join('L') + 'Z', { b: '#F1E2FF', d: T.d, m: '#C9A6F2', c: '#FFFFFF' }, { ow: 2.6, sh: [-rr * 0.3, -rr * 0.4], hl: `M${f(cx - rr * 0.6)} ${f(cy - rr * 0.1)}L${f(cx - rr * 0.1)} ${f(cy - rr * 0.7)}L${f(cx)} ${f(cy - rr * 0.35)}Z` }); };
        return s + gem(-86, 9) + gem(6, 8) + gem(94, 9.5) + gem(176, 8.4);
      },
      anim(o) {
        const T = PAL.RP, r = rng(405); let g = '', a = 4;
        for (let i = 0; i < 11; i++) { const [x, y] = P(111, a); g += `<path transform="translate(${x} ${y}) rotate(${f(a + 90 + J(r, 8))}) translate(-6 -7.2) scale(${f(1.1 + r() * 0.2)})" d="${RUNES[i % 6]}"/>`; a += 27 + J(r, 6); }
        return `<g style="transform-origin:128px 128px;${A(o, 'cosSpin', 16, 'linear infinite')}">${toon(ring(102, 120), T, { ow: 3.6, rule: 'evenodd', sh: [0, -3] })}
<g stroke="#F1E2FF" stroke-width="6" stroke-linecap="round" fill="none" opacity="${o.static ? 0 : 0.2}" style="${A(o, 'cosPulse', 2)}">${g}</g><g stroke="${T.c}" stroke-width="1.2" stroke-linecap="round" fill="none" transform="translate(.8 .9)">${g}</g><g stroke="${T.d}" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" fill="none">${g}</g></g>`;
      },
    },
    frame_l_sunburst: {
      tier: 4, name: 'Genesis Sunburst', seed: 505,
      spec: ['Base (static): Gold ramp band (base #FFC93C, shade #E08A12, deep #4A2500, cream gloss) with a wave scroll, six Kam gems (#FF9445 ramp) and a chubby sun emblem set slightly off-centre at the top.', 'anim/rays.png (behind the base): 14 rounded, toon-shaded rays that alternate long and short (r 118–128 / 106–114). Rotates 360° in 30 s, linear.', 'anim/glow.png: ring r 92, #FFF6D0 10 px, opacity 0→0.8→0, 2.4 s ease-in-out.', 'Reduce flashing: glow 0.3→0.45; the rays keep rotating.'],
      behind(o) {
        const T = PAL.GD, r = rng(506); let s = '', a = 0;
        for (let i = 0; i < 14; i++) { const L = i % 2 ? 108 + r() * 6 : 120 + r() * 8, hw = i % 2 ? 7 : 9, b1 = P(92, a - hw), b2 = P(92, a + hw), c1 = P(L - 3, a - hw * 0.45), c2 = P(L - 3, a + hw * 0.45), tp = P(L + 3, a); s += toon(`M${pp(b1)}L${pp(c1)}Q${pp(tp)} ${pp(c2)}L${pp(b2)}Z`, i % 2 ? { b: '#FFB23F', d: T.d, m: '#E08A12', c: T.c } : T, { ow: 3, hl: `M${pp(P(97, a - hw * 0.5))}L${pp(P(L - 8, a - hw * 0.3))}L${pp(P(L - 9, a - hw * 0.05))}L${pp(P(97, a - hw * 0.2))}Z` }); a += 25.7 + J(r, 2); }
        return `<g style="transform-origin:128px 128px;${A(o, 'cosSpin', 30, 'linear infinite')}">${s}</g>`;
      },
      base() {
        const T = PAL.GD, K = PAL.KM, r = rng(this.seed); let s = '';
        const wv = []; for (let a = 0; a < 360; a += 7) wv.push(P(91.5 + Math.sin((a * Math.PI) / 18) * 2.6, a));
        s += bandToon(ringBlob(82, 101, r, 0.018), T, `<path d="${smooth(wv)}" stroke="${T.m}" stroke-width="1.8" fill="none"/>`, 92);
        [14, 70, 128, 165, 220, 318].forEach((a) => { const [x, y] = P(91.5, a + J(r, 4)); s += toon(`M${f(x - 5.5)} ${y}a5.5 4.4 0 1 0 11 0a5.5 4.4 0 1 0 -11 0Z`, K, { ow: 1.8, hl: circ(x - 2, y - 1.6, 1.5) }); });
        const [ex, ey] = P(103, -84);
        for (let k = 0; k < 9; k++) { const t = k * 40, b1 = P(15, t - 10, ex, ey), b2 = P(15, t + 10, ex, ey), tp = P(26, t, ex, ey); s += toon(`M${pp(b1)}Q${pp(P(25, t - 4, ex, ey))} ${pp(tp)}Q${pp(P(25, t + 4, ex, ey))} ${pp(b2)}Z`, K, { ow: 2.2 }); }
        s += toon(circ(ex, ey, 17), K, { ow: 3, sh: [-3, -3.6], inner: `<path d="${circ(ex, ey, 9.5)}" fill="#FFC27A"/>`, hl: swoosh(ex, ey, 12.5, 200, 255, 4) });
        return s;
      },
      anim(o) { return `<circle cx="128" cy="128" r="92" fill="none" stroke="#FFF6D0" stroke-width="10" opacity="0" style="${A(o, 'cosPulse', 2.4)}"/>`; },
    },
    frame_m_eclipse: {
      tier: 5, name: 'Luna Eclipse', seed: 606,
      spec: ['Base (static): Night band (#3A1640, deep #12030F, mauve gloss swoosh) with star dust, a cream moon with craters at 1:30, and a toon-shaded red-crystal cluster at 6 o’clock (Luna ramp #FF3D6E / #C3134A / deep #3D0418 / cream glint).', 'anim/corona.png (behind the base): 18 chubby flame tongues sweeping clockwise, Luna ramp with pale #F2C4D0 inner tongues. Breathes 0.97→1.03, 3 s ease-in-out.', 'anim/stars.png: 5 cream sparkles twinkle 1.6 s, staggered.', 'Signature: the only frame with a corona and a moon. Special moment (Result screen, on victory): the moon slides 40° over the top of the corona for a full eclipse of 0.8 s, then returns. Reduced: slide only, the corona does not brighten.', 'Reduce flashing: breathe 0.99→1.01; twinkle by opacity only.'],
      behind(o) {
        const T = PAL.LU, r = rng(607); let a = 0, out = '', inn = '';
        for (let i = 0; i < 18; i++) { const L = 112 + r() * 14, hw = 8 + r() * 2, sw = 10 + r() * 5, b1 = P(95, a - hw), b2 = P(95, a + hw), tp = P(L, a + sw), c1 = P((95 + L) / 2 + 2, a - 1), c2 = P((95 + L) / 2 - 3, a + hw + sw * 0.35);
          out += toon(`M${pp(b1)}Q${pp(c1)} ${pp(tp)}Q${pp(c2)} ${pp(b2)}Z`, T, { ow: 3, sh: [-2, -2.6] });
          if (i % 2 === 0) { const L2 = 100 + (L - 100) * 0.5, ip = P(L2, a + sw * 0.6), j1 = P(97, a - hw * 0.35), j2 = P(97, a + hw * 0.45); inn += `<path d="M${pp(j1)}Q${pp(P((97 + L2) / 2, a + 1))} ${pp(ip)}Q${pp(P((97 + L2) / 2 - 1, a + hw * 0.6))} ${pp(j2)}Z" fill="${T.p}"/>`; }
          a += 20 + J(r, 2.5); }
        return `<g style="transform-origin:128px 128px;${A(o, 'cosBreathe', 3)}">${out}${inn}</g>`;
      },
      base() {
        const N = PAL.NT, T = PAL.LU, r = rng(this.seed); let s = '';
        let dots = ''; for (let k = 0; k < 16; k++) dots += `<circle cx="${P(84 + r() * 14, r() * 360)[0]}" cy="${P(84 + r() * 14, r() * 360)[1]}" r="${f(0.7 + r() * 0.9)}" fill="${N.c}"/>`;
        s += toon(ringBlob(82, 100, r, 0.018), N, { ow: 3.6, rule: 'evenodd', sh: [-3, -4.2], inner: dots, hl: swoosh(128, 128, 92, 196, 252, 5), hlc: '#7A4A84' });
        const [mx, my] = P(106, -46);
        s += `<g transform="rotate(-24 ${mx} ${my})">${moon(mx, my, 26, 3.4)}</g>`;
        const [cx0, cy0] = P(97, 90), D = { b: '#FF6F93', d: T.d, m: T.m, c: T.c };
        s += `<g transform="translate(${cx0} ${cy0 + 8})">${crystal(-17, 4, 22, 12, -6, T, 3)}${crystal(18, 4, 26, 13, 7, T, 3)}${crystal(-1, 6, 42, 16, 2, D, 3.2)}${crystal(9, 8, 16, 9, 4, D, 2.6)}</g>`;
        return s;
      },
      anim(o) {
        const r = rng(608); let s = '';
        [[158, 0], [204, 0.4], [248, 0.8], [17, 1.2], [132, 1]].forEach(([a, d]) => { const [x, y] = P(90 + J(r, 4), a); s += twinkle(x, y, 5 + r() * 2.5, PAL.LU.c, A(o, 'cosTwinkle', 1.6, `ease-in-out ${d}s infinite`)); });
        return s;
      },
    },
  };
  function frameSVG(id, o = {}) {
    const d = FRAME[id], size = o.size || 256, base = d.base(o);
    const av = o.avatar ? `<circle cx="128" cy="128" r="84" fill="#00B8FF"/><text x="128" y="132" text-anchor="middle" dominant-baseline="central" font-family="'Baloo 2',cursive" font-weight="800" font-size="84" fill="${INK}">L</text>` : '';
    const win = o.window ? '<circle cx="128" cy="128" r="84" fill="none" stroke="#FF3D6E" stroke-width="1.5" stroke-dasharray="4 4"/>' : '';
    const shadow = (d.shadowExtra || '') + base.replace(/<clipPath[\s\S]*?<\/clipPath>/g, '').replace(/clip-path="[^"]*"/g, '').replace(/fill="(?!none)[^"]*"/g, 'fill="#000"').replace(/stroke="(?!none)[^"]*"/g, 'stroke="#000"');
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="${size}" height="${size}" style="display:block;overflow:visible">${d.behind ? d.behind(o) : ''}${av}<g transform="translate(0 6)" opacity=".5">${shadow}</g>${base}${d.anim ? d.anim(o) : ''}${win}</svg>`;
  }

  // ---------- FX ----------
  const FX = {
    fx_c_dust: { tier: 0, name: 'Dust Devil', die: 'die_c_reed', spec: ['Trail: cartoon dust clouds (3-lobe puffs, sand #F7DE9A, shade #D99A2B, 2.5 px black ring) pop in behind the die every 60 ms (scale 0→1→0.7, 0.35 s), plus 2 speed streaks per bounce arc.', 'Impact: a cloud pair bursts left and right along the felt and a sand ring spreads flat on the felt (ground ellipse r 30→90, 0.4 s).', 'Settle (signature): a flat sand shockwave ring rolls out on the felt and two big clouds pop at the die’s feet. 8 bits [face type, sand].', 'Peak ≈ 22 / die. No luminance pulses, so the reduced variant is identical.'] },
    fx_u_ember: { tier: 1, name: 'Campfire Crown', die: 'die_u_moss', spec: ['Trail: a ribbon of flame tongues (teardrops, #FF6A2B outer / #FFD23F core, black ring) shed every 35 ms that shrink and lift, plus embers.', 'Impact: a flame flower (5 tongues fanned up from the felt) and 6 embers on gravity.', 'Settle (signature): a crown of 7 flame tongues flickers around the die’s base for 0.35 s (12 fps flicker, 3 shapes), then pops into embers. 8 bits [face type, #FFB23F]. Tongues sit at x ≥ ±62, so the face stays clear.', 'Peak ≈ 30 / die. Reduced: identical (flicker is shape-only, no brightness change).'] },
    fx_r_frost: { tier: 2, name: 'Glacier Bloom', die: 'die_r_aqua', spec: ['Trail: snowflakes and ice glints drift off the die.', 'Impact: 3 ice spikes erupt from the felt (Ice ramp, two-face toon), hold 0.3 s, then shatter into shards. A small snow cloud puffs.', 'Settle (signature): a ring of 6 ice spikes bursts out of the felt around the die (ground ellipse r 95), holds 0.35 s, then shatters outward. A frost ring spreads flat on the felt.', 'Spikes stay at |x| ≥ 70 from the die centre, so the face is never covered.', 'Peak ≈ 34 / die. Reduced: identical.'] },
    fx_e_rune: { tier: 3, name: 'Summoning Circle', die: 'die_e_rune', spec: ['Trail: spore wisps #BF6BFF (35 % halo) and floating rune glyphs.', 'Impact: a small rune ring flashes flat on the felt (ellipse r 40, 0.3 s).', 'Settle (signature): a magic circle draws itself on the felt under the die (outer ring sweeps 0→360° in 0.25 s, 6 runes pop in sequence, rotates 30°). A violet light pillar rises behind the die (35 %) and runes float up its edges. 0.9 s total.', 'Reduced: pillar 15 %, halos 50 %, the circle does not pulse.'] },
    fx_l_sunfire: { tier: 4, name: 'Solar Flare', die: 'die_l_gold', spec: ['Trail: a comet ribbon from the last 14 die positions (black 22 px, #FF9445 16 px, #FFD872 8 px core, tapered), a flaming head, sparks and speed streaks.', 'Impact: a comic starburst (10 points, gold, black outline) slams flat on the felt with 6 short rays.', 'Settle (signature): a chubby toon sun rises behind the die (r 74, 12 rounded rays turning 20°), holds 0.4 s, then its rays fire outward. 10 bits [face type, #FFD872]. Gold screen tint 0.25 for 0.2 s.', 'Reduced: no screen tint, rays at 50 % alpha.', 'Peak ≈ 34 / die (the ribbon counts as 1).'] },
    fx_m_lunar: { tier: 5, name: 'Blood Moon', die: 'die_m_redcrystal', spec: ['Trail: red-crystal shards (Luna ramp, two-face) tumbling, with cream star dust.', 'Impact: two crystal spikes erupt from the felt and shatter.', 'Settle: a ring of 6 crystals bursts out of the felt and shatters. Crimson ring.', 'MAX (signature): night falls (40 % dim, no flash). A cream moon rises behind the die, ringed by 16 crimson corona tongues, while 8 crystals orbit at r 112 (outside the face). After 1.2 s the corona bursts into shards and 4 stars twinkle across the tray.', 'Reduced: 25 % dim, corona 50 % alpha, orbit at 60 % speed.', 'Peak ≈ 39 / die on MAX.'] },
  };

  function mountFX(canvas, getOpts) {
    const W = 860, H = 340, FLOOR = 262, CAP = 40, PERIOD = 3.2;
    const ctx = canvas.getContext('2d'), dpr = window.devicePixelRatio || 1;
    canvas.width = W * dpr; canvas.height = H * dpr; ctx.scale(dpr, dpr);
    const imgs = {}, icon = new Image(); icon.src = 'assets/icons/dmg.png';
    const plateImg = (id) => { if (!imgs[id]) { const im = new Image(); im.src = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(plateSVG(id, { static: true, size: 208 })); imgs[id] = im; } return imgs[id]; };
    let lastStep = -1, parts = [], hist = [], last = performance.now(), T = 0, prevT = 0, flags = {}, spawnAcc = 0, settleAt = -1, clearT = 0, tint = 0, dim = 0, raf, stats = { peak: 0 };
    const rnd = (a, b) => a + Math.random() * (b - a), pick = (a) => a[(Math.random() * a.length) | 0];
    const add = (p) => { if (parts.length >= CAP) return null; const q = Object.assign({ age: 0, s0: 8, s1: 8, rot: rnd(0, 6.28), vr: rnd(-6, 6), g: 0, drag: 0, vx: 0, vy: 0, jj: Array.from({ length: 7 }, () => rnd(0.75, 1.15)), lw: rnd(2.2, 3.2), seed: Math.random() }, p); parts.push(q); return q; };
    const tw = (x, y, shape, cols, n, d0, d1, life, size, extra) => { for (let i = 0; i < n; i++) { const g = Math.random() * Math.PI * 2, d = rnd(d0, d1); add(Object.assign({ tw: 1, x0: x, y0: y, x1: x + Math.cos(g) * d, y1: y + Math.sin(g) * d * 0.72, shape, col: cols[i % cols.length], life: life * rnd(0.85, 1.1), s0: size, s1: size * 0.3, front: 1, rot: g }, extra)); } };
    const dieAt = (t) => {
      const u = Math.min(t / 0.78, 1), e = 1 - Math.pow(1 - u, 2), x = 110 + e * 320;
      let h = 0;
      if (t < 0.36) h = 150 * (1 - Math.pow(t / 0.36, 2)); else if (t < 0.6) { const v = (t - 0.36) / 0.24; h = 62 * 4 * v * (1 - v); } else if (t < 0.76) { const v = (t - 0.6) / 0.16; h = 22 * 4 * v * (1 - v); }
      const spin = (1 - e) * 11, settle = Math.min(Math.max((t - 0.76) / 0.3, 0), 1);
      const pop = t > 0.9 && t < 1.1 ? 1 + 0.12 * Math.sin(((t - 0.9) / 0.2) * Math.PI) : 1;
      return { x, y: FLOOR - h - 52, rot: t < 0.76 ? spin : 0.06 * (1 - settle) + 0.04, sx: t < 0.76 ? 0.35 + 0.65 * Math.abs(Math.cos(spin * 1.6)) : 1, pop, moving: t < 0.76, vx: 320 * (1 - u) };
    };
    const SAND = ['#F7DE9A', '#F5C24A'], FIRE = ['#FF6A2B', '#FF9445', '#FFD23F'];
    const groundSpikes = (cx, n, rad, T, h0, h1, ang0) => { for (let i = 0; i < n; i++) { const a = ang0 + (i / n) * Math.PI * 2 + rnd(-0.15, 0.15), gx = cx + Math.cos(a) * rad, gy = FLOOR + Math.sin(a) * rad * 0.26; if (Math.abs(gx - cx) < 70) continue; add({ shape: 'spike', x: gx, y: gy, h: rnd(h0, h1), w: rnd(14, 20), lean: rnd(-6, 6) + (gx - cx) * 0.08, life: 0.55, pal: T, front: gy > FLOOR ? 1 : 0, shatter: 1 }); } };
    const FXDEF = {
      fx_c_dust: {
        trail(d, every) { if (every(0.06)) add({ shape: 'cloud', x: d.x - 40 + rnd(-6, 6), y: d.y + 30 + rnd(-6, 6), vx: -30, vy: -10, life: 0.38, s0: 0, s1: 14, col: SAND[0], sh: SAND[1] }); if (Math.random() < 0.08) add({ shape: 'streak', x: d.x - 60, y: d.y + rnd(-40, 40), vx: -60, life: 0.22, len: rnd(30, 50), col: '#FFFBEF' }); },
        impact(x, y, k) { [-1, 1].forEach((s) => add({ shape: 'cloud', x: x + s * 34, y: y - 10, vx: s * 140 * k, vy: -30 * k, drag: 3, life: 0.5, s0: 6, s1: 18 * (0.6 + k * 0.5), col: SAND[0], sh: SAND[1] })); add({ shape: 'gring', x, y, r0: 30, r1: 90 * (0.5 + k * 0.5), life: 0.4, col: '#F7DE9A' }); for (let i = 0; i < 3; i++) add({ shape: 'dia', x, y: y - 4, vx: rnd(-120, 120), vy: -rnd(120, 220) * k, g: 800, life: 0.45, s0: 6, s1: 4, col: '#D99A2B' }); },
        settle(d, fc) { add({ shape: 'gring', x: d.x, y: FLOOR, r0: 60, r1: 200, life: 0.6, col: '#F7DE9A', w: 7 }); [-1, 1].forEach((s) => add({ shape: 'cloud', x: d.x + s * 74, y: FLOOR - 14, vx: s * 70, vy: -16, drag: 2, life: 0.55, s0: 8, s1: 24, col: SAND[0], sh: SAND[1], front: 1 })); tw(d.x, d.y, 'dia', [fc, '#F7DE9A'], 8, 110, 150, 0.4, 13); },
      },
      fx_u_ember: {
        trail(d, every) { if (every(0.035)) add({ shape: 'flame', x: d.x - 26 + rnd(-6, 6), y: d.y + rnd(-14, 24), vx: -rnd(40, 80), vy: -rnd(30, 70), life: 0.36, s0: rnd(14, 20), s1: 4, col: '#FF6A2B', core: '#FFD23F' }); if (Math.random() < 0.3) add({ shape: 'dia', x: d.x - 30, y: d.y + rnd(-20, 20), vx: -rnd(20, 60), vy: -rnd(60, 120), life: 0.5, s0: 6, s1: 2, col: pick(FIRE) }); },
        impact(x, y, k) { for (let i = 0; i < 5; i++) { const a = -Math.PI / 2 + (i - 2) * 0.42; add({ shape: 'flame', x: x + Math.cos(a) * 14, y: y - 4, vx: Math.cos(a) * 90 * k, vy: Math.sin(a) * 150 * k, drag: 4, life: 0.34, s0: 22 * (0.6 + k * 0.4), s1: 4, col: '#FF6A2B', core: '#FFD23F', rotFix: a + Math.PI / 2 }); } for (let i = 0; i < 6; i++) add({ shape: 'dia', x, y: y - 6, vx: rnd(-110, 110), vy: -rnd(200, 320) * k, g: 650, life: 0.55, s0: 7, s1: 3, col: pick(FIRE) }); },
        settle(d, fc) { for (let i = 0; i < 7; i++) { const a = Math.PI + (i / 6) * Math.PI, side = Math.cos(a), gx = d.x + side * rnd(62, 84); add({ shape: 'flame', x: gx, y: FLOOR - 4 - Math.abs(Math.sin(a)) * 4, life: 0.42, s0: 30 + Math.abs(side) * 10, s1: 26, col: '#FF6A2B', core: '#FFD23F', flick: 1, front: 1, rotFix: side * 0.25, popTo: 1 }); } tw(d.x, d.y, 'dia', [fc, '#FFB23F'], 8, 110, 150, 0.4, 13); },
      },
      fx_r_frost: {
        trail(d, every) { if (every(0.05)) add({ shape: 'flake', x: d.x - 34 + rnd(-8, 8), y: d.y + rnd(-24, 30), vx: -rnd(10, 40), vy: rnd(-10, 25), life: 0.6, s0: 8, s1: 5, col: '#FFFFFF', vr: rnd(-2, 2) }); if (Math.random() < 0.25) add({ shape: 'star', x: d.x - 20 + rnd(-20, 20), y: d.y + rnd(-40, 40), vx: -20, life: 0.35, s0: 7, s1: 2, col: '#D2F2FB' }); },
        impact(x, y, k) { if (k > 0.5) groundSpikes(x, 3, 34, PAL.IC, 26 * k, 40 * k, -Math.PI / 2); add({ shape: 'cloud', x: x, y: y - 8, vx: 0, vy: -20, life: 0.4, s0: 6, s1: 16, col: '#FFFFFF', sh: '#CDE9F5' }); },
        settle(d, fc) { groundSpikes(d.x, 6, 95, PAL.IC, 34, 54, 0.3); add({ shape: 'gring', x: d.x, y: FLOOR, r0: 50, r1: 150, life: 0.5, col: '#D2F2FB', w: 6 }); tw(d.x, d.y, 'shard', ['#8FE8FF', fc], 8, 115, 150, 0.4, 16); },
      },
      fx_e_rune: {
        trail(d, every) { if (every(0.04)) add({ shape: 'wisp', x: d.x - 30 + rnd(-10, 10), y: d.y + rnd(-25, 25), vx: -rnd(20, 50), vy: -rnd(5, 30), life: 0.5, s0: 5, s1: 2, col: '#BF6BFF' }); if (Math.random() < 0.12) add({ shape: 'glyph', x: d.x - 40, y: d.y + rnd(-30, 30), vx: -30, vy: -30, life: 0.5, s0: 12, s1: 12, k: (Math.random() * 6) | 0 }); },
        impact(x, y, k) { add({ shape: 'circle', x, y: FLOOR, R: 40 * (0.6 + k * 0.5), life: 0.3, mini: 1 }); },
        settle(d, fc) { add({ shape: 'circle', x: d.x, y: FLOOR, R: 130, life: 0.95 }); add({ shape: 'pillar', x: d.x, y: FLOOR, life: 0.9 }); for (let i = 0; i < 6; i++) add({ shape: 'glyph', x: d.x + (i % 2 ? 1 : -1) * rnd(72, 110), y: FLOOR - rnd(0, 20), vx: 0, vy: -rnd(70, 120), life: rnd(0.7, 0.9), s0: 14, s1: 10, k: i, delay: i * 0.05, front: 1 }); tw(d.x, d.y, 'dia', [fc, '#F1E2FF'], 8, 110, 150, 0.4, 13); },
      },
      fx_l_sunfire: {
        comet: true,
        trail(d, every) { if (every(0.03)) add({ shape: 'star', x: d.x - 20 + rnd(-14, 14), y: d.y + rnd(-20, 20), vx: -rnd(30, 70), vy: rnd(-30, 30), life: 0.45, s0: 8, s1: 2, col: '#FFE08A' }); if (Math.random() < 0.18) add({ shape: 'streak', x: d.x - 70, y: d.y + rnd(-44, 44), vx: -80, life: 0.2, len: rnd(40, 70), col: '#FFE7A3' }); },
        impact(x, y, k) { add({ shape: 'burst', x, y: FLOOR, R: 50 * (0.5 + k * 0.6), life: 0.28 }); for (let i = 0; i < 6; i++) add({ shape: 'ray', x, y: y - 6, ang: Math.PI + (i / 5) * Math.PI, r0: 30, r1: 70 * (0.6 + k * 0.4), life: 0.25, col: '#FFD872', glow: 1 }); },
        settle(d, fc) { add({ shape: 'sun', x: d.x, y: d.y - 4, life: 0.8 }); for (let i = 0; i < 12; i++) add({ shape: 'ray', x: d.x, y: d.y, ang: (i / 12) * Math.PI * 2, r0: 90, r1: 170, life: 0.3, col: '#FFD872', glow: 1, front: 1, delay: 0.42 }); tw(d.x, d.y, 'dia', [fc, '#FFD872'], 10, 115, 150, 0.4, 13); if (!flags.rf) tint = 0.25; },
      },
      fx_m_lunar: {
        trail(d, every) { if (every(0.045)) add({ shape: 'crys', x: d.x - 30 + rnd(-10, 10), y: d.y + rnd(-25, 25), vx: -rnd(30, 70), vy: rnd(-20, 30), life: 0.55, s0: 12, s1: 6, pal: PAL.LU }); if (Math.random() < 0.35) add({ shape: 'star', x: d.x - 40 + rnd(-10, 10), y: d.y + rnd(-30, 30), vx: -20, life: 0.5, s0: 7, s1: 2, col: '#FFF4F7' }); },
        impact(x, y, k) { if (k > 0.5) groundSpikes(x, 2, 40, PAL.LU, 26, 36, -Math.PI / 2 + 0.6); for (let i = 0; i < 4; i++) add({ shape: 'crys', x, y: y - 4, vx: rnd(-180, 180), vy: -rnd(120, 240) * k, g: 700, life: 0.5, s0: 10, s1: 5, pal: PAL.LU }); },
        settle(d, fc, max) {
          if (!max) groundSpikes(d.x, 6, 95, PAL.LU, 34, 52, 0.3);
          tw(d.x, d.y, 'crys', [fc], 8, 115, 150, 0.4, 15, { pal: PAL.LU });
          add({ shape: 'ring', x: d.x, y: d.y, r0: 56, r1: 110, life: 0.42, col: '#FF3D6E', front: 1 });
          if (max) { dim = flags.rf ? 0.25 : 0.42; add({ shape: 'eclipse', x: d.x, y: d.y - 6, life: 1.5 }); for (let i = 0; i < 8; i++) add({ shape: 'orbit', x: d.x, y: d.y, ang: (i / 8) * Math.PI * 2, life: 1.5, s0: 14, s1: 14, pal: PAL.LU, front: 1 }); for (let i = 0; i < 4; i++) add({ shape: 'star', x: rnd(80, 780), y: rnd(50, 150), life: 1.4, s0: 10, s1: 10, col: '#FFF4F7', blink: 1, front: 1 }); }
        },
      },
    };
    // ---- drawing ----
    const P2 = (pts) => { ctx.beginPath(); pts.forEach((q, i) => ctx[i ? 'lineTo' : 'moveTo'](q[0], q[1])); ctx.closePath(); };
    function toonFill(path, base, shade, deep, lw, hl) { path(); ctx.lineWidth = lw; ctx.strokeStyle = deep; ctx.fillStyle = base; ctx.stroke(); ctx.fill(); if (shade) { ctx.save(); path(); ctx.clip(); ctx.translate(lw * 0.8, lw * 1.1); ctx.globalCompositeOperation = 'source-atop'; ctx.restore(); } if (hl) { ctx.fillStyle = hl.c; hl.path(); ctx.fill(); } }
    function cloud(s, col, sh, jj) { const lobes = [[-s * 0.55, s * 0.1, s * 0.5 * jj[0]], [0, -s * 0.2, s * 0.62 * jj[1]], [s * 0.55, s * 0.12, s * 0.48 * jj[2]]]; ctx.beginPath(); lobes.forEach(([x, y, r]) => { ctx.moveTo(x + r, y); ctx.arc(x, y, Math.max(r, 0.1), 0, 7); }); ctx.lineWidth = 5; ctx.strokeStyle = '#000'; ctx.stroke(); ctx.fillStyle = sh; ctx.fill(); ctx.beginPath(); lobes.forEach(([x, y, r]) => { ctx.moveTo(x - r * 0.12 + r * 0.82, y - r * 0.16); ctx.arc(x - r * 0.12, y - r * 0.16, Math.max(r * 0.82, 0.1), 0, 7); }); ctx.fillStyle = col; ctx.fill(); ctx.beginPath(); ctx.arc(-s * 0.12, -s * 0.42, s * 0.14, 0, 7); ctx.fillStyle = '#FFFFFF'; ctx.fill(); }
    function flameShape(s, wob) { ctx.beginPath(); ctx.moveTo(0, -s); ctx.bezierCurveTo(s * 0.18 + wob, -s * 0.5, s * 0.5, -s * 0.1, s * 0.42, s * 0.18); ctx.bezierCurveTo(s * 0.36, s * 0.5, -s * 0.36, s * 0.5, -s * 0.42, s * 0.18); ctx.bezierCurveTo(-s * 0.5, -s * 0.15, -s * 0.12 + wob, -s * 0.5, 0, -s); ctx.closePath(); }
    function crys(s, T, j) { const pts = [[s * 0.06 * j[4], -s * j[0]], [s * 0.36 * j[1], -s * 0.12], [s * 0.04, s * 0.62 * j[2]], [-s * 0.32 * j[3], s * 0.04]]; P2(pts); ctx.lineWidth = 2.6; ctx.strokeStyle = '#000'; ctx.stroke(); ctx.fillStyle = T.m; ctx.fill(); P2([pts[0], pts[3], pts[2], [pts[0][0] * 0.3, 0]]); ctx.fillStyle = T.b; ctx.fill(); ctx.beginPath(); ctx.moveTo(-s * 0.12, -s * 0.05); ctx.lineTo(pts[0][0] - s * 0.05, -s * 0.72); ctx.strokeStyle = T.c; ctx.lineWidth = 1.6; ctx.stroke(); }
    function drawShape(p, a) {
      const u = Math.min(p.age / p.life, 1), s = p.s0 + (p.s1 - p.s0) * u, rf = flags.rf ? 0.5 : 1, eo = 1 - Math.pow(1 - u, 2);
      if (a <= 0) return;
      ctx.save(); ctx.globalAlpha = a; ctx.translate(p.x, p.y); ctx.lineJoin = 'round'; ctx.lineCap = 'round';
      const fs = (path, col) => { ctx.fillStyle = col || p.col; ctx.strokeStyle = '#000'; ctx.lineWidth = p.lw; path(); ctx.fill(); ctx.stroke(); };
      switch (p.shape) {
        case 'dia': { ctx.rotate(p.rot); const j = p.jj, h = s * 0.62; fs(() => P2([[0, -h * j[0]], [h * j[1], 0], [0, h * j[2]], [-h * j[3], 0]])); if (s > 6) { ctx.beginPath(); ctx.moveTo(-s * 0.2, -s * 0.06); ctx.lineTo(0, -s * 0.34); ctx.strokeStyle = 'rgba(255,255,255,.8)'; ctx.lineWidth = 1.5; ctx.stroke(); } break; }
        case 'shard': ctx.rotate(p.rot); crys(s, { b: p.col, m: p.col === '#8FE8FF' ? '#3FB8E6' : 'rgba(0,0,0,.25)', c: '#FFFFFF' }, p.jj); break;
        case 'crys': ctx.rotate(p.rot); crys(s, p.pal, p.jj); break;
        case 'cloud': { const k = u < 0.35 ? 1 - Math.pow(1 - u / 0.35, 3) : 1 - (u - 0.35) * 0.4; const sz = p.s1 * k; if (sz > 0.5) cloud(sz, p.col, p.sh, p.jj); break; }
        case 'streak': ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(p.len * (1 - u * 0.5), 0); ctx.strokeStyle = p.col; ctx.globalAlpha = a * 0.7; ctx.lineWidth = 3; ctx.stroke(); break;
        case 'star': { const sc = p.blink ? Math.abs(Math.sin(p.age * 9 + p.seed * 6)) : 1; const r = s * (0.4 + 0.6 * sc); ctx.rotate(0.1); fs(() => { ctx.beginPath(); ctx.moveTo(0, -r); ctx.quadraticCurveTo(r * 0.12, -r * 0.12, r * 0.8, 0); ctx.quadraticCurveTo(r * 0.12, r * 0.12, 0, r * 0.85); ctx.quadraticCurveTo(-r * 0.12, r * 0.12, -r * 0.75, 0); ctx.quadraticCurveTo(-r * 0.12, -r * 0.12, 0, -r); }); break; }
        case 'flake': ctx.rotate(p.rot); ctx.beginPath(); for (let k = 0; k < 3; k++) { const g = (k * Math.PI) / 3; ctx.moveTo(Math.cos(g) * s, Math.sin(g) * s); ctx.lineTo(-Math.cos(g) * s, -Math.sin(g) * s); } ctx.strokeStyle = '#000'; ctx.lineWidth = 5; ctx.stroke(); ctx.strokeStyle = p.col; ctx.lineWidth = 2; ctx.stroke(); break;
        case 'wisp': ctx.globalAlpha = a * 0.35 * rf; ctx.fillStyle = p.col; ctx.beginPath(); ctx.arc(0, 0, s * 2, 0, 7); ctx.fill(); ctx.globalAlpha = a; fs(() => { ctx.beginPath(); ctx.arc(0, 0, s, 0, 7); }); break;
        case 'glyph': { if (p.age < (p.delay || 0)) break; ctx.scale(s / 12, s / 12); ctx.translate(-5, -6); ctx.globalAlpha = a * rf * 0.6; ctx.strokeStyle = '#BF6BFF'; ctx.lineWidth = 5; ctx.stroke(new Path2D(RUNES[p.k % 6])); ctx.globalAlpha = a; ctx.strokeStyle = '#2E0A52'; ctx.lineWidth = 3.6; ctx.stroke(new Path2D(RUNES[p.k % 6])); ctx.strokeStyle = '#F1E2FF'; ctx.lineWidth = 1.6; ctx.stroke(new Path2D(RUNES[p.k % 6])); break; }
        case 'flame': { const fl = p.flick ? [1, 0.82, 1.1][Math.floor(p.age * 12 + p.seed * 3) % 3] : 1, sz = (p.popTo && u > 0.8 ? s * (1 - (u - 0.8) * 5) : s) * fl; if (sz <= 0.5) break; ctx.rotate(p.rotFix != null ? p.rotFix : Math.atan2(p.vy, p.vx) + Math.PI / 2 + Math.PI); const wob = p.flick ? (Math.floor(p.age * 12) % 2 ? 2 : -2) : 0; flameShape(sz, wob); ctx.lineWidth = 3; ctx.strokeStyle = '#000'; ctx.stroke(); ctx.fillStyle = p.col; ctx.fill(); ctx.save(); ctx.translate(0, sz * 0.16); flameShape(sz * 0.55, -wob); ctx.fillStyle = p.core; ctx.fill(); ctx.restore(); ctx.beginPath(); ctx.ellipse(-sz * 0.14, -sz * 0.05, sz * 0.06, sz * 0.14, 0.3, 0, 7); ctx.fillStyle = '#FFF6D0'; ctx.fill(); break; }
        case 'spike': {
          const grow = Math.min(p.age / 0.1, 1), e = 1 - Math.pow(1 - grow, 3), hh = p.h * e * (1 + 0.15 * Math.sin(Math.min(p.age / 0.18, 1) * Math.PI)), w = p.w, T = p.pal;
          if (u > 0.85) { ctx.globalAlpha = a * (1 - (u - 0.85) / 0.15); }
          const bl = [-w / 2, 0], br = [w / 2, 0], tp = [p.lean, -hh], md = [p.lean * 0.4 + w * 0.05, -hh * 0.4];
          P2([bl, tp, br]); ctx.lineWidth = 3.4; ctx.strokeStyle = '#000'; ctx.stroke(); ctx.fillStyle = T.m; ctx.fill();
          P2([bl, tp, md, [w * 0.05, 0]]); ctx.fillStyle = T.b; ctx.fill();
          ctx.beginPath(); ctx.moveTo(-w * 0.22, -hh * 0.12); ctx.lineTo(p.lean - w * 0.05, -hh * 0.8); ctx.strokeStyle = T.c; ctx.lineWidth = 2; ctx.stroke();
          ctx.beginPath(); ctx.ellipse(0, 1, w * 0.75, 3.5, 0, 0, 7); ctx.fillStyle = 'rgba(0,0,0,.25)'; ctx.fill();
          break; }
        case 'gring': { const r = p.r0 + (p.r1 - p.r0) * eo; ctx.scale(1, 0.26); ctx.globalAlpha = a * (1 - eo); ctx.beginPath(); ctx.arc(0, 0, r, 0, 7); ctx.strokeStyle = '#000'; ctx.lineWidth = (p.w || 5) + 6; ctx.stroke(); ctx.strokeStyle = p.col; ctx.lineWidth = p.w || 5; ctx.stroke(); break; }
        case 'ring': { const r = p.r0 + (p.r1 - p.r0) * eo; ctx.globalAlpha = a * (1 - eo); ctx.beginPath(); ctx.ellipse(0, 0, r, r * 0.85, 0, 0, 7); ctx.strokeStyle = '#000'; ctx.lineWidth = 9; ctx.stroke(); ctx.strokeStyle = p.col; ctx.lineWidth = 5; ctx.stroke(); break; }
        case 'ray': { if (p.age < (p.delay || 0)) break; const v = Math.min((p.age - (p.delay || 0)) / Math.max(p.life - (p.delay || 0), 0.01), 1), ev = 1 - Math.pow(1 - v, 2), r1 = p.r0 + (p.r1 - p.r0) * ev, r0 = p.r0 + (p.r1 - p.r0) * Math.max(ev - 0.35, 0); ctx.globalAlpha = (p.glow ? rf : 1) * (1 - v * v); ctx.beginPath(); ctx.moveTo(Math.cos(p.ang) * r0, Math.sin(p.ang) * r0 * 0.85); ctx.lineTo(Math.cos(p.ang) * r1, Math.sin(p.ang) * r1 * 0.85); ctx.strokeStyle = '#000'; ctx.lineWidth = 10; ctx.stroke(); ctx.strokeStyle = p.col; ctx.lineWidth = 5; ctx.stroke(); break; }
        case 'burst': { const k = 1 - Math.pow(1 - Math.min(u / 0.4, 1), 3); ctx.scale(1, 0.38); ctx.globalAlpha = 1 - Math.max(0, (u - 0.5) / 0.5); const R = p.R * k, pts = []; for (let i = 0; i < 20; i++) { const g = (i / 20) * Math.PI * 2, rr = i % 2 ? R * 0.55 : R * p.jj[i % 7]; pts.push([Math.cos(g) * rr, Math.sin(g) * rr]); } P2(pts); ctx.lineWidth = 8; ctx.strokeStyle = '#000'; ctx.stroke(); ctx.fillStyle = '#FFC93C'; ctx.fill(); P2(pts.map((q) => [q[0] * 0.55, q[1] * 0.55])); ctx.fillStyle = '#FFFCEB'; ctx.fill(); break; }
        case 'circle': {
          const R = p.R, sweep = Math.min(p.age / (p.mini ? 0.12 : 0.25), 1), fade = u > 0.7 ? 1 - (u - 0.7) / 0.3 : 1; ctx.scale(1, 0.28); ctx.rotate(p.age * 0.6); ctx.globalAlpha = fade;
          const arc = (r, w, c) => { ctx.beginPath(); ctx.arc(0, 0, r, -Math.PI / 2, -Math.PI / 2 + sweep * Math.PI * 2); ctx.strokeStyle = '#000'; ctx.lineWidth = w + 6; ctx.stroke(); ctx.strokeStyle = c; ctx.lineWidth = w; ctx.stroke(); };
          ctx.globalAlpha = fade * 0.3 * rf; ctx.beginPath(); ctx.arc(0, 0, R, 0, 7); ctx.fillStyle = '#BF6BFF'; ctx.fill(); ctx.globalAlpha = fade;
          arc(R, 6, '#BF6BFF'); arc(R * 0.78, 3.5, '#E3D0FF');
          if (!p.mini) { for (let i = 0; i < 6; i++) { if (p.age < 0.08 + i * 0.04) continue; const g = (i / 6) * Math.PI * 2; ctx.save(); ctx.translate(Math.cos(g) * R * 0.89, Math.sin(g) * R * 0.89); ctx.rotate(g + Math.PI / 2); ctx.scale(1.8, 1.8); ctx.translate(-5, -6); ctx.strokeStyle = '#2E0A52'; ctx.lineWidth = 3.6; ctx.stroke(new Path2D(RUNES[i])); ctx.strokeStyle = '#F1E2FF'; ctx.lineWidth = 1.6; ctx.stroke(new Path2D(RUNES[i])); ctx.restore(); } }
          break; }
        case 'pillar': { const up = Math.min(p.age / 0.2, 1), fade = u > 0.6 ? 1 - (u - 0.6) / 0.4 : 1, h = 300 * (1 - Math.pow(1 - up, 3)); const g = ctx.createLinearGradient(0, 0, 0, -h); g.addColorStop(0, `rgba(191,107,255,${0.38 * fade * rf})`); g.addColorStop(1, 'rgba(191,107,255,0)'); ctx.fillStyle = g; ctx.fillRect(-70, -h, 140, h); ctx.fillStyle = `rgba(241,226,255,${0.35 * fade * rf})`; ctx.fillRect(-26, -h, 52, h); break; }
        case 'sun': {
          const rise = Math.min(p.age / 0.22, 1), k = 1 + 2.4 * Math.pow(rise - 1, 3) + 1.4 * Math.pow(rise - 1, 2), fade = u > 0.55 ? 1 - (u - 0.55) / 0.45 : 1; ctx.globalAlpha = fade; ctx.scale(k, k); ctx.rotate(p.age * 0.45);
          for (let i = 0; i < 12; i++) { const g = (i / 12) * Math.PI * 2, L = i % 2 ? 104 : 120, hw = 0.13; ctx.beginPath(); ctx.moveTo(Math.cos(g - hw) * 70, Math.sin(g - hw) * 70); ctx.lineTo(Math.cos(g - hw * 0.4) * (L - 6), Math.sin(g - hw * 0.4) * (L - 6)); ctx.quadraticCurveTo(Math.cos(g) * (L + 6), Math.sin(g) * (L + 6), Math.cos(g + hw * 0.4) * (L - 6), Math.sin(g + hw * 0.4) * (L - 6)); ctx.lineTo(Math.cos(g + hw) * 70, Math.sin(g + hw) * 70); ctx.closePath(); ctx.lineWidth = 4; ctx.strokeStyle = '#4A2500'; ctx.stroke(); ctx.fillStyle = i % 2 ? '#FFB23F' : '#FFC93C'; ctx.fill(); }
          ctx.beginPath(); ctx.arc(0, 0, 76, 0, 7); ctx.lineWidth = 5; ctx.strokeStyle = '#4A2500'; ctx.stroke(); ctx.fillStyle = '#E08A12'; ctx.fill(); ctx.beginPath(); ctx.arc(-4, -5, 72, 0, 7); ctx.fillStyle = '#FFC93C'; ctx.fill(); ctx.beginPath(); ctx.arc(0, 0, 58, Math.PI * 1.05, Math.PI * 1.45); ctx.strokeStyle = '#FFFCEB'; ctx.lineWidth = 8; ctx.stroke(); break; }
        case 'eclipse': {
          const rise = Math.min(p.age / 0.3, 1), k = 1 - Math.pow(1 - rise, 3), out = u > 0.8 ? (u - 0.8) / 0.2 : 0; ctx.globalAlpha = (1 - out) * (flags.rf ? 0.5 : 1);
          ctx.save(); ctx.rotate(p.age * 0.5); for (let i = 0; i < 16; i++) { const g = (i / 16) * Math.PI * 2, L = (112 + (i % 3) * 8) * k * (1 + out * 0.6); ctx.beginPath(); ctx.moveTo(Math.cos(g - 0.17) * 84, Math.sin(g - 0.17) * 84); ctx.quadraticCurveTo(Math.cos(g) * L * 0.9, Math.sin(g) * L * 0.9, Math.cos(g + 0.28) * L, Math.sin(g + 0.28) * L); ctx.quadraticCurveTo(Math.cos(g + 0.2) * 92, Math.sin(g + 0.2) * 92, Math.cos(g + 0.17) * 84, Math.sin(g + 0.17) * 84); ctx.closePath(); ctx.lineWidth = 4; ctx.strokeStyle = '#000'; ctx.stroke(); ctx.fillStyle = i % 2 ? '#FF3D6E' : '#C3134A'; ctx.fill(); } ctx.restore();
          ctx.globalAlpha = 1 - out; ctx.beginPath(); ctx.arc(0, 0, 86 * k, 0, 7); ctx.lineWidth = 5; ctx.strokeStyle = '#3D0418'; ctx.stroke(); ctx.fillStyle = '#EBC7B4'; ctx.fill(); ctx.beginPath(); ctx.arc(-5, -6, 81 * k, 0, 7); ctx.fillStyle = '#FFEFD9'; ctx.fill();
          [[30, -40, 12], [48, 18, 8], [-36, 44, 10]].forEach(([x, y, r]) => { ctx.beginPath(); ctx.arc(x * k, y * k, r * k, 0, 7); ctx.fillStyle = '#EBC7B4'; ctx.fill(); });
          ctx.beginPath(); ctx.arc(0, 0, 66 * k, Math.PI * 1.05, Math.PI * 1.45); ctx.strokeStyle = '#FFFFFF'; ctx.lineWidth = 8; ctx.stroke(); break; }
        case 'orbit': { const burst = u > 0.8 ? (u - 0.8) / 0.2 : 0, r = 112 + burst * 140, g = p.ang + p.age * (flags.rf ? 1.5 : 2.5); ctx.globalAlpha = 1 - burst; ctx.translate(Math.cos(g) * r, Math.sin(g) * r * 0.85); ctx.rotate(g + Math.PI / 2); crys(s, p.pal, p.jj); break; }
      }
      ctx.restore();
    }
    function rr(x, y, w, h, r) { ctx.beginPath(); ctx.roundRect(x, y, w, h, r); }
    function drawDie(d, id, max) {
      const s = 104, im = plateImg(id), D = DIE[id];
      ctx.save(); ctx.translate(d.x, d.y); ctx.rotate(d.rot); ctx.scale(d.sx * d.pop, d.pop); ctx.translate(-s / 2, -s / 2);
      ctx.save(); rr(0, 0, s, s, 18.72); ctx.clip(); if (im.complete) ctx.drawImage(im, 0, 0, s, s); ctx.restore();
      ctx.beginPath(); ctx.moveTo(2, 24.96); ctx.lineTo(2, 18.72); ctx.arcTo(2, 2, 18.72, 2, 16.7); ctx.lineTo(85.28, 2); ctx.arcTo(102, 2, 102, 18.72, 16.7); ctx.lineTo(102, 24.96); ctx.closePath(); ctx.fillStyle = CLASS.plant; ctx.fill(); ctx.lineWidth = 4; ctx.strokeStyle = '#000'; ctx.stroke();
      ctx.font = "800 41.6px 'Baloo 2'"; ctx.fillStyle = INK; ctx.textBaseline = 'middle';
      const val = max ? '8' : '6', tw2 = ctx.measureText(val).width, x0 = 52 - (tw2 + 6.24 + 31.2) / 2, cy = 64.48;
      ctx.fillText(val, x0, cy + 3);
      rr(x0 + tw2 + 6.24, cy - 15.6, 31.2, 31.2, 7); ctx.fillStyle = TYPE.dmg; ctx.fill(); ctx.lineWidth = 3; ctx.stroke();
      if (icon.complete) ctx.drawImage(icon, x0 + tw2 + 6.24 + 5.6, cy - 10, 20, 20);
      rr(2, 2, 100, 100, 16.7); ctx.lineWidth = 4; ctx.strokeStyle = D.border; ctx.stroke();
      ctx.restore();
    }
    const STATIC = { gring: 1, ring: 1, ray: 1, burst: 1, circle: 1, pillar: 1, sun: 1, eclipse: 1, orbit: 1, spike: 1 };
    function frame(now) {
      const o = getOpts(); flags = o;
      const dtReal = Math.min((now - last) / 1000, 0.05); last = now;
      const dt = dtReal / (o.slow ? 2.5 : 1);
      prevT = T; T += dt; if (T >= PERIOD) { T = 0; prevT = 0; parts = []; hist = []; settleAt = -1; stats = { peak: 0 }; dim = 0; }
      const def = FXDEF[o.fx], id = FX[o.fx].die, d = dieAt(T);
      const cross = (t) => prevT < t && T >= t;
      const every = (iv) => { spawnAcc += dt; if (spawnAcc >= iv) { spawnAcc = 0; return true; } return false; };
      if (d.moving) { def.trail(d, every); hist.unshift({ x: d.x, y: d.y }); hist.length = Math.min(hist.length, 14); } else if (hist.length) hist.pop();
      [[0.36, 1], [0.6, 0.6], [0.76, 0.35]].forEach(([t, k]) => { if (cross(t)) def.impact(dieAt(t).x, FLOOR, k); });
      if (cross(0.9)) { def.settle(d, TYPE.dmg, !!o.max); settleAt = T; clearT = 0; }
      for (const p of parts) { p.age += dt; if (!p.tw && !STATIC[p.shape]) { p.vy += p.g * dt; p.vx *= 1 - p.drag * dt; p.vy *= 1 - p.drag * dt; p.x += p.vx * dt; p.y += p.vy * dt; p.rot += p.vr * dt; } }
      const dead = parts.filter((p) => p.age >= p.life); parts = parts.filter((p) => p.age < p.life);
      dead.forEach((p) => { if (p.shatter) for (let i = 0; i < 3; i++) add(p.pal === PAL.LU ? { shape: 'crys', pal: PAL.LU, x: p.x + p.lean * 0.5, y: p.y - p.h * 0.5, vx: rnd(-160, 160), vy: -rnd(100, 220), g: 700, life: 0.45, s0: 10, s1: 5, front: p.front } : { shape: 'shard', col: '#8FE8FF', x: p.x + p.lean * 0.5, y: p.y - p.h * 0.5, vx: rnd(-160, 160), vy: -rnd(100, 220), g: 700, life: 0.45, s0: 11, s1: 5, front: p.front }); if (p.popTo) for (let i = 0; i < 2; i++) add({ shape: 'dia', x: p.x, y: p.y - 20, vx: rnd(-60, 60), vy: -rnd(120, 200), g: 500, life: 0.4, s0: 6, s1: 2, col: pick(FIRE) }); });
      stats.peak = Math.max(stats.peak, parts.length);
      tint = Math.max(0, tint - dt * 1.25); if (T > 2.5) dim = Math.max(0, dim - dt * 2);
      ctx.clearRect(0, 0, W, H);
      rr(4, 4, W - 8, H - 8, 40); ctx.fillStyle = '#7A4A22'; ctx.fill(); ctx.lineWidth = 5; ctx.strokeStyle = '#000'; ctx.stroke();
      rr(22, 22, W - 44, H - 44, 26); const gr = ctx.createLinearGradient(0, 22, 0, H - 22); gr.addColorStop(0, '#27555D'); gr.addColorStop(1, '#1B3E45'); ctx.fillStyle = gr; ctx.fill(); ctx.lineWidth = 4; ctx.strokeStyle = '#A56B35'; ctx.stroke();
      ctx.save(); rr(22, 22, W - 44, H - 44, 26); ctx.clip();
      if (dim > 0) { ctx.fillStyle = `rgba(8,9,13,${dim})`; ctx.fillRect(0, 0, W, H); }
      const step = Math.floor(T * 12) !== lastStep; if (step) lastStep = Math.floor(T * 12);
      const life = (p) => (p.tw ? 1 - Math.pow(p.age / p.life, 2) : STATIC[p.shape] || p.shape === 'cloud' || p.shape === 'flame' || p.blink ? 1 : 1 - p.age / p.life);
      const snap = (p) => { if (step || !p.sn) { if (p.tw) { const e = 1 - Math.pow(1 - p.age / p.life, 3); p.x = p.x0 + (p.x1 - p.x0) * e; p.y = p.y0 + (p.y1 - p.y0) * e; } p.sn = { x: p.x, y: p.y, rot: p.rot, age: p.age }; } };
      const drawSn = (p) => { const k = { x: p.x, y: p.y, rot: p.rot, age: p.age }; Object.assign(p, p.sn); drawShape(p, life(p)); Object.assign(p, k); };
      const BIG = { pillar: 1, sun: 1, eclipse: 1, circle: 1, gring: 1 };
      for (const p of parts) if (BIG[p.shape] && !p.front) { snap(p); drawSn(p); }
      const ph = FLOOR - d.y - 52; ctx.fillStyle = `rgba(0,0,0,${Math.max(0.15, 0.4 - ph / 600)})`; ctx.beginPath(); ctx.ellipse(d.x, FLOOR + 6, 58 * Math.max(0.5, 1 - ph / 400), 12, 0, 0, 7); ctx.fill();
      if (def.comet && hist.length > 2) { [['#000', 24], [o.rf ? '#FFB23F' : '#FF9445', 16], [o.rf ? '#FFC93C' : '#FFD872', 8]].forEach(([c, w]) => { for (let i = 1; i < hist.length; i++) { ctx.beginPath(); ctx.moveTo(hist[i - 1].x, hist[i - 1].y); ctx.lineTo(hist[i].x, hist[i].y); ctx.strokeStyle = c; ctx.lineCap = 'round'; ctx.lineWidth = w * (1 - i / hist.length); ctx.stroke(); } }); }
      for (const p of parts) if (!p.front && !BIG[p.shape]) { snap(p); drawSn(p); }
      drawDie(d, id, !!o.max);
      let over = false;
      for (const p of parts) if (p.front) {
        snap(p);
        if (p.tw) { if (Math.abs(p.sn.x - d.x) < 52 + p.s0 / 2 && Math.abs(p.sn.y - d.y) < 52 + p.s0 / 2 && life(p) > 0.15) over = true; }
        else if (p.r0 != null && p.shape === 'ring') { const r = p.r0 + (p.r1 - p.r0) * (1 - Math.pow(1 - p.sn.age / p.life, 2)); if (r < 66) over = true; }
        drawSn(p);
      }
      if (settleAt >= 0 && over) clearT = T - settleAt;
      if (o.max && T > 0.9 && T < 2.4) { ctx.save(); ctx.translate(d.x + 52, d.y - 58); ctx.rotate(-0.14); ctx.font = "800 24px 'Baloo 2'"; const w = ctx.measureText('MAX!').width + 22; rr(-w / 2, -18, w, 36, 10); ctx.fillStyle = '#FFD76A'; ctx.fill(); ctx.lineWidth = 4; ctx.strokeStyle = '#000'; ctx.stroke(); ctx.fillStyle = INK; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText('MAX!', 0, 2); ctx.restore(); }
      if (tint > 0) { ctx.fillStyle = `rgba(255,215,106,${tint})`; ctx.fillRect(0, 0, W, H); }
      ctx.restore();
      o.onStats && o.onStats({ live: parts.length, peak: stats.peak, clear: clearT }); window.__fxT = T;
      raf = requestAnimationFrame(frame);
    }
    raf = requestAnimationFrame(frame);
    return { destroy() { cancelAnimationFrame(raf); } };
  }

  async function exportPNG(svg, size, name) {
    const img = new Image(); img.src = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg);
    await img.decode(); const c = document.createElement('canvas'); c.width = c.height = size;
    c.getContext('2d').drawImage(img, 0, 0, size, size);
    const a = document.createElement('a'); a.download = name; a.href = c.toDataURL('image/png'); a.click();
  }

  const partNames = ['horn_plant', 'tail_aqua'];
  Promise.all(partNames.map((n) => fetch('assets/part/' + n + '.svg').then((r) => r.text()).then((t) => { PARTS[n] = t.replace(/<metadata>[\s\S]*?<\/metadata>/, '').replace(/^[\s\S]*?<svg[^>]*>/, '').replace(/<\/svg>\s*$/, ''); }).catch(() => {}))).then(() => {
    window.CosArt = { TIERS, DIE, FRAME, FX, INK, TYPE, PAL, contrast, hue, lum, plateSVG, dieSVG, frameSVG, mountFX, exportPNG };
  });
})();
