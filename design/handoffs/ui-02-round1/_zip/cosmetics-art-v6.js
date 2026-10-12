/* Axie Dice · Cosmetics 01 — v6 full collection (55). Earlier: v4 (Homeland frame style; FX re-skinned). Based on v3, Axie part-icon rendering language.
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

  // ---------- v4: Axie Homeland avatar-frame style ----------
  // OBSERVED (pixel-sampled) in the reference frames uploaded by the user (Homeland_Avatar frame_1/2/3, SS2/SS3 Fancy):
  // one warm maroon outline #682828–#703030 on every silhouette; airbrushed gradient fills; inner detail lines in a darker tone of the fill;
  // 2–3 large decoration clusters per frame placed asymmetrically; a cute critter or creature motif; 4-point sparkles with a coloured rim.
  const OL = '#6B2B2B';
  let DEFS = [], CU = 0, WK = 1;
  const grad = (c1, c2, x1 = 0, y1 = 0, x2 = 1, y2 = 1) => { const id = 'gr' + ++uid; DEFS.push(`<linearGradient id="${id}" x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}"><stop offset="0" stop-color="${c1}"/><stop offset="1" stop-color="${c2}"/></linearGradient>`); return `url(#${id})`; };
  const softDefs = (u, sc) => `<filter id="sf${u}" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="${2.2 * sc}"/></filter><filter id="cr${u}" x="-5%" y="-5%" width="110%" height="110%"><feTurbulence type="fractalNoise" baseFrequency="${0.9 / sc}" numOctaves="1" seed="${u % 40}"/><feDisplacementMap in="SourceGraphic" scale="${1.2 * sc}" xChannelSelector="R" yChannelSelector="G"/></filter>`;
  // paint: maroon-outlined shape; `soft` = airbrushed shade/glow blobs (blurred, clipped); `lines` = crisp inner detail (clipped)
  function paint(d, fill, o = {}) {
    const id = 'q' + ++uid, w = (o.w ?? 3.2) * WK, rule = o.rule ? ` fill-rule="${o.rule}" clip-rule="${o.rule}"` : '', ol = o.ol || OL;
    let s = `<path d="${d}"${rule} fill="${fill}" stroke="${ol}" stroke-width="${f(w * 2)}" stroke-linejoin="round" paint-order="stroke"/>`;
    if (o.soft || o.lines) s += `<clipPath id="${id}"><path d="${d}"${rule}/></clipPath><g clip-path="url(#${id})">${o.soft ? `<g filter="url(#sf${CU})">${o.soft}</g>` : ''}${o.lines || ''}</g>`;
    return s + (o.hl || '');
  }
  const line = (d, col, w, op) => `<path d="${d}" stroke="${col}" stroke-width="${w}" fill="none" stroke-linecap="round" stroke-linejoin="round"${op ? ` opacity="${op}"` : ''}/>`;
  const star4 = (x, y, r, fill, rim, style, k = 0.18) => `<path d="M${f(x)} ${f(y - r)}Q${f(x + r * k)} ${f(y - r * k)} ${f(x + r * 0.82)} ${f(y)}Q${f(x + r * k)} ${f(y + r * k)} ${f(x)} ${f(y + r)}Q${f(x - r * k)} ${f(y + r * k)} ${f(x - r * 0.82)} ${f(y)}Q${f(x - r * k)} ${f(y - r * k)} ${f(x)} ${f(y - r)}Z" fill="${fill}" stroke="${rim}" stroke-width="${f(Math.max(r * 0.2, 0.8))}" stroke-linejoin="round" paint-order="stroke" style="transform-origin:${f(x)}px ${f(y)}px;${style || ''}"/>`;
  const SPK = { teal: ['#D8FFF6', '#5AB0B0'], blue: ['#F2F6FF', '#7088C8'], orange: ['#FFD890', '#F07828'], cream: ['#FFF8E8', '#E0A058'] };
  const sparkle = (x, y, r, kind = 'teal', style) => star4(x, y, r, SPK[kind][0], SPK[kind][1], style);
  // broad leaf along +x
  function leafA(L, W, c1, c2, vein, r, w = 3.2) {
    const a = W * (1 + J(r, 0.1)), b = W * (0.9 + J(r, 0.1)), c = J(r, W * 0.1);
    const d = `M0 0C${f(L * 0.2)} ${f(-a)} ${f(L * 0.66)} ${f(-a * 0.96)} ${f(L)} ${f(c)}C${f(L * 0.7)} ${f(b * 0.92)} ${f(L * 0.24)} ${f(b)} 0 0Z`;
    let v = `M${f(L * 0.06)} 0Q${f(L * 0.5)} ${f(-W * 0.1)} ${f(L * 0.88)} ${f(c * 0.9)}`;
    for (let k = 1; k < 4; k++) { const t = k / 4.2; v += `M${f(L * t)} ${f(-W * 0.07)}l${f(L * 0.12)} ${f(-W * 0.45)}M${f(L * t)} ${f(-W * 0.02)}l${f(L * 0.12)} ${f(W * 0.45)}`; }
    return paint(d, grad(c1, c2, 0, 0, 1, 1), { w, soft: `<path d="M${f(L * 0.1)} ${f(W * 0.5)}Q${f(L * 0.5)} ${f(W * 0.9)} ${f(L)} ${f(W * 0.2)}V${f(W * 1.5)}H0Z" fill="${c2}" opacity=".7"/>`, lines: line(v, vein, f(w * 0.45)) });
  }
  function crystalA(x, by, h, w, lean, sw) {
    const bl = [x - w / 2, by], br = [x + w / 2, by], sl = [x - w / 2 - lean * 0.15, by - h * 0.66], sr = [x + w / 2 - lean * 0.05, by - h * 0.6], tp = [x + lean, by - h], mid = [x + lean * 0.45 + w * 0.06, by - h * 0.58], mb = [x + w * 0.08, by];
    return paint(`M${pp(bl)}L${pp(sl)}L${pp(tp)}L${pp(sr)}L${pp(br)}Z`, grad('#FF8A98', '#C02848', 0, 0, 1, 1), { w: sw, lines: `<path d="M${pp(sl)}L${pp(tp)}L${pp(mid)}L${pp(mb)}L${pp(bl)}Z" fill="#FF9AA8" opacity=".75"/>` + line(`M${pp(tp)}L${pp(mid)}L${pp(mb)}`, '#A01838', f(sw * 0.45)) + line(`M${f(sl[0] + w * 0.22)} ${f(sl[1])}L${f(tp[0] - w * 0.06)} ${f(tp[1] + h * 0.18)}`, '#FFE4EA', f(sw * 0.55)) });
  }
  function moonA(cx, cy, r, sw, gem) {
    return paint(crescent(cx, cy, r, 0.58), grad('#FFF8EC', '#F0D4B8', 0, 0, 1, 1), { w: sw, ol: '#E8A060', soft: `<path d="${circ(cx + r * 0.6, cy + r * 0.5, r * 0.6)}" fill="#F2C8A8" opacity=".8"/>`, lines: line(`M${pp(P(r * 0.78, -55, cx, cy))}A${f(r * 0.78)} ${f(r * 0.78)} 0 0 1 ${pp(P(r * 0.78, 10, cx, cy))}`, '#E8B080', f(sw * 0.35)) + (gem ? `<ellipse cx="${f(cx + r * 0.7)}" cy="${f(cy - r * 0.15)}" rx="${f(r * 0.07)}" ry="${f(r * 0.13)}" fill="#60D8D0"/>` : '') });
  }
  // the band: base fill, optional pattern (clipped), airbrush shade on the lower-right, maroon outline
  function bandA(r1, r2, fill, pattern, shade, r) {
    return paint(ringBlob(r1, r2, r, 0.012, 0.004), fill, { w: 3.2, rule: 'evenodd', soft: shade ? `<path d="${circ(170, 175, 95)}" fill="${shade}" opacity=".55"/><path d="${circ(80, 72, 70)}" fill="#FFFFFF" opacity=".28"/>` : '', lines: pattern || '' });
  }

  // ---------- DIE PLATES (104 face space; band hides y < 24.96; calm zone below) ----------
  const CZ = { x: 10.4, y: 45.8, w: 83.2, h: 37.4 };
  const DIE = {
    die_c_reed: {
      tier: 0, name: 'Sunbaked Weave', border: '#000', calm: ['#F8E4C0', '#F8C880', '#E09050'],
      spec: ['Border #000, 4 px at s=104 (3 px on the 36 px egg token).', 'Same language as the Homeland frames: straw strands with an airbrushed gold gradient (#FFF0D0 → #F8C880), inner lines #E09050 (6.1:1 to the value ink, so the calm zone stays readable).', 'A braided rim along the bottom 15 px in orange #F8A858 / brown #A85038, with the maroon #6B2B2B outline. Static.'],
      plate() {
        const r = rng(5); let s = `<rect width="104" height="104" fill="#F8E4C0"/>`;
        for (let i = 0; i < 4; i++) for (let j = 0; j < 4; j++) {
          const x = j * 26, y = i * 26, h = (i + j) % 2 === 0;
          for (let k = 0; k < 2; k++) {
            const d = h ? `M${x + 1.2} ${y + 1.6 + k * 12.4}h23.6a5.4 5.4 0 0 1 0 10.8h-23.6a5.4 5.4 0 0 1 0 -10.8Z` : `M${x + 1.6 + k * 12.4} ${y + 1.2}h10.8v23.6a5.4 5.4 0 0 1 -10.8 0Z`;
            s += paint(d, grad('#FFF0D0', '#F8C880', 0, 0, h ? 0 : 1, h ? 1 : 0), { w: 0.6, ol: '#E09050', lines: h ? line(`M${f(x + 4 + r() * 3)} ${f(y + 4.3 + k * 12.4)}h${f(6 + r() * 6)}`, '#FFFFFF', 1.2, 0.9) : line(`M${f(x + 4.3 + k * 12.4)} ${f(y + 4 + r() * 3)}v${f(6 + r() * 6)}`, '#FFFFFF', 1.2, 0.9) });
          }
        }
        s += `<path d="M-2 88.5C24 87 50 89.4 76 87.8S100 87.4 106 88V106H-2Z" fill="${OL}"/>`;
        for (let x = -3, k = 0; x < 108; x += 7.4, k++) s += paint(`M${f(x - 5.4)} 99.5C${f(x - 4.8)} 92.4 ${f(x + 3)} 90 ${f(x + 5.4)} 92.4C${f(x + 4.8)} 99 ${f(x - 2)} 102.4 ${f(x - 5.4)} 99.5Z`, k % 2 ? grad('#F8C070', '#F89858') : grad('#C86038', '#A85038'), { w: 0.7 });
        return s;
      },
    },
    die_u_moss: {
      tier: 1, name: 'Mossy Pebble', border: '#000', calm: ['#F4EEE2', '#E8DCC8', '#C8A888'],
      spec: ['Border #000, 4 px.', 'Cream river stones with an airbrushed top-left light (#FFFFFF → #E8DCC8) and soft brown inner line #C8A888 (6.6:1 to ink).', 'Frog-green moss along the bottom and sides (#60C878 → #40A888, vein #186048) with two broad leaves and a cream water-lily bud, borrowed from the lily-pad frame. Maroon outline. Static.'],
      plate() {
        const r = rng(9); let s = `<rect width="104" height="104" fill="#DCCDB4"/>`;
        [[16, 36, 22, 14], [56, 34, 21, 13], [95, 40, 16, 15], [24, 64, 22, 14], [70, 64, 26, 14], [8, 92, 18, 12], [50, 92, 22, 12], [96, 88, 14, 12]].forEach(([x, y, rx, ry]) => (s += paint(blob(x, y, rx, ry, 9, 0.08, r), grad('#FFFFFF', '#E8DCC8', 0, 0, 0.6, 1), { w: 0.7, ol: '#C8A888' })));
        const pts = []; for (let x = -6; x <= 110; x += 9) pts.push([x, 88 + J(r, 3)]);
        s += paint('M-6 110' + smooth(pts, false).replace('M', 'L') + 'L110 110Z', grad('#60C878', '#40A888', 0, 0, 0, 1), { w: 1, lines: line('M4 96l6 -3M22 97l7 -2M44 96l6 -3M70 97l7 -2M90 96l6 -2', '#186048', 0.9) });
        s += paint(blob(2, 62, 8, 15, 8, 0.15, r), grad('#60C878', '#40A888'), { w: 1 }) + paint(blob(103, 44, 7, 12, 8, 0.15, r), grad('#60C878', '#40A888'), { w: 1 });
        s += `<g transform="translate(80 88) rotate(-128)">${leafA(15, 5.2, '#7AD88A', '#40A888', '#186048', r, 0.9)}</g><g transform="translate(80 88) rotate(-58)">${leafA(12, 4.4, '#7AD88A', '#40A888', '#186048', r, 0.9)}</g>`;
        let lily = ''; [[-4.5, 0], [0, -6], [4.5, 0], [-2.5, -3.5], [2.5, -3.5]].forEach(([dx, dy]) => (lily += `M${f(20 + dx)} 92L${f(20 + dx * 0.6 - 1.4)} ${f(86 + dy)}L${f(20 + dx * 0.6)} ${f(84 + dy)}L${f(20 + dx * 0.6 + 1.4)} ${f(86 + dy)}Z`));
        return s + paint(lily, grad('#FFF8C8', '#F0D090', 0, 0, 0, 1), { w: 0.7 });
      },
    },
    die_r_aqua: {
      tier: 2, name: 'Tidepool', tag: 'Mastery · Aquatic', border: '#000', calm: ['#C8F0EA', '#90D8D0', '#58C0B0'],
      spec: ['Border #000, 4 px.', 'Two materials: scale field with an airbrushed aqua gradient (#E0FAF4 → #90D8D0) and scallop line #58C0B0 (7.2:1 to ink), plus a curling wave (#58C0B0 → #2E8C90) with cream foam and a maroon outline.', 'Bubbles are rimmed Homeland sparkles (#D8FFF6 with a teal rim #5AB0B0). Static.'],
      plate() {
        let s = `<rect width="104" height="104" fill="${grad('#E0FAF4', '#90D8D0', 0, 0, 0, 1)}"/>`, d = '';
        for (let row = 0; row < 15; row++) { const y = row * 7.2, off = (row % 2) * 6.5; for (let x = -13 + off; x < 110; x += 13) d += `M${f(x)} ${f(y)}a6.5 6.2 0 0 0 13 0`; }
        s += line(d, '#58C0B0', 1.3, 0.9);
        const wp = [[-4, 92], [9, 85.5], [21, 90], [34, 84], [48, 90.5], [61, 85], [74, 89.5], [88, 83.5], [100, 89], [110, 86]];
        s += paint('M-4 110' + smooth(wp, false).replace('M', 'L') + 'L110 110Z', grad('#58C0B0', '#2E8C90', 0, 0, 0, 1), { w: 1.1 });
        [[9, 85.5], [34, 84], [61, 85], [88, 83.5]].forEach(([x, y]) => (s += paint(`M${f(x - 6)} ${f(y + 3)}C${f(x - 4)} ${f(y - 3)} ${f(x + 4)} ${f(y - 3.5)} ${f(x + 6)} ${f(y + 0.5)}C${f(x + 3)} ${f(y - 1)} ${f(x - 1)} ${f(y)} ${f(x - 6)} ${f(y + 3)}Z`, '#F8F0D8', { w: 0.6 })));
        const bub = (x, y, rr) => `<circle cx="${x}" cy="${y}" r="${rr}" fill="#D8FFF6" stroke="#5AB0B0" stroke-width="${f(rr * 0.3)}" paint-order="stroke"/><circle cx="${f(x - rr * 0.35)}" cy="${f(y - rr * 0.35)}" r="${f(rr * 0.25)}" fill="#FFFFFF"/>`;
        return s + bub(6, 64, 3.6) + bub(8.6, 72.5, 2.1) + bub(5, 78, 1.4) + bub(97, 36, 4.2) + bub(99.5, 46, 2.3) + bub(93, 29, 1.6) + sparkle(14, 94, 3.4, 'teal');
      },
    },
    die_e_rune: {
      tier: 3, name: 'Moonrune Tablet', border: '#4A1E8A', calm: ['#EDE2FA', '#D8C4F4'],
      spec: ['Border #4A1E8A (Mystic violet), 4 px. Reads as black at 36 px.', 'Lavender tablet (#F4ECFF → #D8C4F4) with diagonal lilac stripes, as on the SS2 Fancy frame. Runes are carved in #8050C8 with a white lip.', 'Gold scroll curls (#F8C880 → #F0A050, line #E07828) in both lower corners, and a teal gem (#78E0B0) at each side.', 'glow.png: rune underlay #C898F0 5 px, blend Add. Idle: pulse 0.35→0.9, 2.0 s. Reduce flashing: 0.55→0.7.'],
      plate(o) {
        const r = rng(17); let s = `<rect width="104" height="104" fill="${grad('#F4ECFF', '#D8C4F4', 0, 0, 1, 1)}"/>`;
        for (let k = -2; k < 8; k++) s += `<path d="M${k * 22} 104L${k * 22 + 40} 0H${k * 22 + 51}L${k * 22 + 11} 104Z" fill="#E4D4F8" opacity=".7"/>`;
        let glyph = '';
        [[19.5, 0], [33.5, 1], [48.5, 2], [62.5, 3], [77, 4]].forEach(([x, i]) => { glyph += `<path transform="translate(${f(x - 4.5)} ${f(85.5 + J(r, 0.5))}) rotate(${f(J(r, 5))} 5 6) scale(.9)" d="${RUNES[i]}"/>`; });
        s += `<g stroke="#C898F0" stroke-width="5" stroke-linecap="round" fill="none" opacity="${o.static ? 0.55 : 0.35}" style="${A(o, 'cosPulse', 2)}">${glyph}</g>`;
        s += `<g stroke="#FFFFFF" stroke-width="1.2" stroke-linecap="round" fill="none" transform="translate(.6 .9)">${glyph}</g><g stroke="#8050C8" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" fill="none">${glyph}</g>`;
        const scroll = (x, y, m) => `<g transform="translate(${x} ${y}) scale(${m} 1)">${paint('M0 0C0 -8 10 -10 13 -4C16 2 9 6 6 2C4 -1 7 -3 9 -2', 'none', { w: 2.4 })}<path d="M0 0C0 -8 10 -10 13 -4C16 2 9 6 6 2C4 -1 7 -3 9 -2" stroke="${grad('#F8C880', '#F0A050')}" stroke-width="3.2" fill="none" stroke-linecap="round"/><path d="M1.5 -2C2 -6 8 -8 11 -4.5" stroke="#E07828" stroke-width=".8" fill="none" stroke-linecap="round"/></g>`;
        s += scroll(4, 100, 1) + scroll(100, 100, -1);
        const gem = (x, y, rr) => paint(`M${x} ${f(y - rr * 1.2)}L${f(x + rr)} ${f(y - rr * 0.2)}L${f(x + rr * 0.6)} ${f(y + rr)}L${f(x - rr * 0.6)} ${f(y + rr)}L${f(x - rr)} ${f(y - rr * 0.2)}Z`, grad('#B8F8D8', '#48D8A8', 0, 0, 1, 1), { w: 0.9, lines: line(`M${f(x - rr)} ${f(y - rr * 0.2)}H${f(x + rr)}M${x} ${f(y - rr * 1.2)}L${f(x - rr * 0.3)} ${f(y - rr * 0.2)}L${x} ${f(y + rr)}`, '#F0FFF8', 0.6) });
        return s + gem(5, 40, 4.2) + gem(99, 40, 4.2);
      },
    },
    die_l_gold: {
      tier: 4, name: 'Genesis Sunplate', border: '#7A3410', calm: ['#FFF0CC', '#FFE0A0', '#F0B868'],
      spec: ['Border #7A3410 (burnt orange), 4 px.', 'Warm gold field (#FFF6DC → #FFE0A0) with engraved orange swirls #F0B868 (5.4:1 to ink), as on the gold cuffs of frame_2. A sun rises from the bottom edge (#FFE090 → #F8A048), with orange blade rays (#FFC870 → #F07828) and a maroon outline.', 'glow.png: diagonal sheen, white 50 %, blend Add. Idle: sweeps across in 1.1 s, then rests. 3.2 s loop. Reduce flashing: sheen at 20 %.'],
      plate(o) {
        let s = `<rect width="104" height="104" fill="${grad('#FFF6DC', '#FFE0A0', 0, 0, 0, 1)}"/>`;
        s += line('M14 40c4 -6 12 -4 11 2c-1 4 -6 3 -5 0M80 36c5 -5 12 -2 10 4c-2 3 -6 2 -5 -1M36 34q10 -4 20 0', '#F0B868', 1.4);
        for (let k = 0; k < 9; k++) { const a = 200 + k * 17.5, b1 = P(17, a - 6, 52, 108), b2 = P(17, a + 6, 52, 108), tp = P(k % 2 ? 30 : 36, a, 52, 108); s += paint(`M${pp(b1)}L${pp(tp)}L${pp(b2)}Z`, grad('#FFC870', '#F07828', 0, 0, 1, 1), { w: 0.9 }); }
        s += paint(circ(52, 108, 19), grad('#FFE090', '#F8A048', 0, 0, 1, 1), { w: 1.2, lines: line('M40 102c3 -7 10 -10 17 -9', '#FFF4D0', 2) + line('M46 104c2 -4 8 -5 10 -2c1 3 -3 4 -4 2', '#E07828', 1) });
        s += sparkle(14, 88, 4, 'orange') + sparkle(90, 88, 4, 'orange');
        s += `<g style="${A(o, 'cosSheen', 3.2)}"><path d="M-40 0H-24L-54 104H-70Z" fill="#FFFFFF" opacity=".5"/><path d="M-19 0H-15L-45 104H-49Z" fill="#FFFFFF" opacity=".45"/></g>`;
        return s;
      },
    },
    die_m_redcrystal: {
      tier: 5, name: 'Luna Heartcrystal', border: OL, calm: ['#FFF4E4', '#F4DCC4'], dark: true,
      spec: ['Dark skin, so it gets a LIGHT VALUE PLATE: cream gradient #FFF4E4 → #F4DCC4 with a 1.4 px maroon #6B2B2B outline, sized to the calm zone. Ink stays #1A1206.', 'Border #6B2B2B (Homeland maroon), 4 px. Field: night navy (#2A3A6A → #14204A) with cream star dust.', 'Signature: a cream crescent moon with a teal gem (the SS3 crescent) and red crystals (#FF8A98 → #C02848, facet #FF9AA8).', 'Idle: 3 teal-rimmed sparkles twinkle 1.6 s, staggered. Reduce flashing: opacity only.', 'MAX settle: the crescent fills to a full moon for 0.6 s while the crystals grow 1→1.15 (ease-out-back). Reduced: crystals only.'],
      plate(o) {
        const r = rng(25); let s = `<rect width="104" height="104" fill="${grad('#2A3A6A', '#14204A', 0, 0, 0, 1)}"/>`;
        [[18, 32], [44, 30], [70, 40], [97, 70], [30, 41], [53, 38], [4, 52], [62, 44]].forEach(([x, y]) => (s += `<circle cx="${x}" cy="${y}" r="${f(0.6 + r() * 0.7)}" fill="#FFF4E4"/>`));
        s += moonA(87, 35.5, 9.5, 0.8, true);
        [[8, 35.5, 4.4, 0], [62, 31, 3.2, 0.5], [6, 86, 3, 1.1]].forEach(([x, y, rr, dl]) => (s += sparkle(x, y, rr, 'teal', A(o, 'cosTwinkle', 1.6, `ease-in-out ${dl}s infinite`))));
        s += crystalA(4, 106, 17, 8, -1.5, 0.9) + crystalA(15.5, 106, 24, 10, 2, 1) + crystalA(26, 106, 12, 6.5, 2.5, 0.9) + crystalA(100, 106, 15, 8, 1.5, 0.9) + crystalA(88.5, 106, 22, 9.5, -2.5, 1) + crystalA(78, 106, 10, 6, -1, 0.8) + crystalA(52, 106, 10, 6.5, 1, 0.8);
        s += paint(`M${CZ.x + 9} ${CZ.y}H${CZ.x + CZ.w - 9}Q${CZ.x + CZ.w} ${CZ.y} ${CZ.x + CZ.w} ${CZ.y + 9}V${CZ.y + CZ.h - 9}Q${CZ.x + CZ.w} ${CZ.y + CZ.h} ${CZ.x + CZ.w - 9} ${CZ.y + CZ.h}H${CZ.x + 9}Q${CZ.x} ${CZ.y + CZ.h} ${CZ.x} ${CZ.y + CZ.h - 9}V${CZ.y + 9}Q${CZ.x} ${CZ.y} ${CZ.x + 9} ${CZ.y}Z`, grad('#FFF4E4', '#F4DCC4', 0, 0, 0, 1), { w: 1.4 });
        return s;
      },
    },
  };

  const rgDef = (col, op) => { const id = 'rg' + ++uid; DEFS.push(`<radialGradient id="${id}"><stop offset="0" stop-color="${col}" stop-opacity="${op}"/><stop offset="1" stop-color="${col}" stop-opacity="0"/></radialGradient>`); return `url(#${id})`; };
  const band = (pts, fill, o) => paint('M-6 112' + smooth(pts, false).replace('M', 'L') + 'L110 112Z', fill, o);
  Object.assign(DIE, {
    die_c_sunwood: {
      tier: 0, name: 'Driftwood Deck', border: '#000', calm: ['#FAEEDC', '#EED6B0', '#DDB98C', '#C89868'],
      spec: ['Border #000, 4 px.', 'Six sun-bleached planks (#FAEEDC → #EED6B0), seam #C89868 (7.0:1 to ink), wavy grain #DDB98C. Iron nails #8A6040 sit at x 5 and 99, outside the calm zone.', 'One cream sparkle top-right. Static.'],
      plate() {
        const r = rng(41); let s = `<rect width="104" height="104" fill="#EED6B0"/>`;
        for (let i = 0; i < 6; i++) {
          const y = 20 + i * 15.6; let g = '';
          for (let k = 0; k < 2; k++) { const yy = y + 4.5 + k * 6 + J(r, 1); g += `M${f(-10 + r() * 20)} ${f(yy)}q12 ${f(J(r, 2.2))} 24 0t24 0t24 0t24 0t24 0`; }
          if (i === 1 || i === 5) { const kx = i === 1 ? 84 : 22; g += `M${kx - 5} ${f(y + 8)}a5 3 0 1 0 10 0a5 3 0 1 0 -10 0Z`; }
          s += paint(`M-2 ${f(y)}H106V${f(y + 15.6)}H-2Z`, grad('#FAEEDC', '#EED6B0', 0, 0, 0, 1), { w: 0.6, ol: '#C89868', lines: line(g, '#DDB98C', 1) });
          s += `<circle cx="5" cy="${f(y + 7.8)}" r="1.7" fill="#8A6040"/><circle cx="99" cy="${f(y + 7.8)}" r="1.7" fill="#8A6040"/>`;
        }
        return s + sparkle(92, 34, 3.4, 'cream');
      },
    },
    die_c_clay: {
      tier: 0, name: 'Kiln Clay', border: '#000', calm: ['#F9E0C6', '#EDB892', '#E2A47E'],
      spec: ['Border #000, 4 px.', 'Baked clay (#F9E0C6 → #EDB892) pressed with five thumbprints, ridges #E2A47E (6.9:1 to ink).', 'Terracotta glaze rim along the bottom (#DE7A50 → #B04A2E, highlight #F4A07C), maroon outline. Static.'],
      plate() {
        let s = `<rect width="104" height="104" fill="${grad('#F9E0C6', '#EDB892', 0, 0, 0, 1)}"/>`;
        const tp = (x, y, rot) => { let g = ''; for (let k = 1; k <= 4; k++) g += `M${f(x - k * 2.6)} ${y}a${f(k * 2.6)} ${f(k * 3.4)} 0 1 1 ${f(k * 5.2)} 0`; return `<g transform="rotate(${rot} ${x} ${y})">${line(g, '#E2A47E', 1)}</g>`; };
        s += tp(22, 40, -20) + tp(78, 58, 25) + tp(40, 76, 10) + tp(92, 34, -5) + tp(8, 64, 15);
        const pts = []; for (let x = -6, k = 0; x <= 112; x += 13, k++) pts.push([x, 88 + (k % 2 ? 2.6 : -1.6)]);
        return s + band(pts, grad('#DE7A50', '#B04A2E', 0, 0, 0, 1), { w: 1, lines: line('M6 94q8 -3 16 0M40 93q8 -3 16 0M74 94q8 -3 16 0', '#F4A07C', 1.4) }) + sparkle(94, 97, 3.2, 'orange');
      },
    },
    die_u_bark: {
      tier: 1, name: 'Heartwood Rings', border: '#000', calm: ['#F6E4C6', '#ECD2A8', '#DDB888'],
      spec: ['Border #000, 4 px.', 'A cut log face (#F6E4C6 → #ECD2A8): growth rings #DDB888 radiate from the lower-left corner (6.0:1 to ink).', 'Bark rim along the bottom (#B8743E → #8A4A26, grooves #6A3418) with a two-leaf sprout. Static.'],
      plate() {
        const r = rng(47); let s = `<rect width="104" height="104" fill="${grad('#F6E4C6', '#ECD2A8', 0, 0, 1, 1)}"/>`, g = '';
        for (let k = 1; k < 13; k++) g += blob(-8, 118, k * 11.5, k * 11, 16, 0.025, r);
        s += line(g, '#DDB888', 1.3);
        const pts = []; for (let x = -6; x <= 112; x += 8) pts.push([x, 89 + J(r, 1.8)]);
        let gr = ''; for (let x = 4; x < 104; x += 9) gr += `M${x} ${f(93 + r() * 2)}l${f(J(r, 1.5))} ${f(6 + r() * 4)}`;
        s += band(pts, grad('#B8743E', '#8A4A26', 0, 0, 0, 1), { w: 1, lines: line(gr, '#6A3418', 1.1) });
        s += line('M86 90q-1 -6 2 -9', OL, 2.2) + line('M86 90q-1 -6 2 -9', '#58B040', 1.1);
        return s + `<g transform="translate(88 82) rotate(-130)">${leafA(12, 4.4, '#9AE070', '#58B040', '#286018', r, 0.8)}</g><g transform="translate(88 82) rotate(-50)">${leafA(10, 3.8, '#9AE070', '#58B040', '#286018', r, 0.8)}</g>`;
      },
    },
    die_u_berry: {
      tier: 1, name: 'Berry Jam', border: '#000', calm: ['#FFF3F5', '#F8DCE4', '#F2C6D4'],
      spec: ['Border #000, 4 px.', 'Cream icing (#FFF3F5 → #F8DCE4) with sugar dots #F2C6D4. Jam (#F0507A → #B8204E, shine #FFC0D0) pools along the bottom and drips down both side edges, outside the calm zone.', 'Two blueberries bottom-left, a raspberry with a mint leaf bottom-right. Static.'],
      plate() {
        const r = rng(53); let s = `<rect width="104" height="104" fill="${grad('#FFF3F5', '#F8DCE4', 0, 0, 0, 1)}"/>`;
        for (let i = 0; i < 18; i++) s += `<circle cx="${f(r() * 104)}" cy="${f(28 + r() * 58)}" r="1" fill="#F2C6D4"/>`;
        const jam = grad('#F0507A', '#B8204E', 0, 0, 1, 1);
        s += paint('M-4 24H8V46a5 5 0 0 1 -10 0Z', jam, { w: 0.9, lines: line('M3 28V42', '#FFC0D0', 1.4) }) + paint('M96 24H108V58a5.5 5.5 0 0 1 -11 0Z', jam, { w: 0.9, lines: line('M100 28V54', '#FFC0D0', 1.4) });
        const pts = []; for (let x = -6, k = 0; x <= 112; x += 10, k++) pts.push([x, 87 + (k % 2 ? 2.4 : -1.2)]);
        s += band(pts, jam, { w: 1, lines: line('M30 93q10 -3 20 0M60 94q8 -2 14 0', '#FFC0D0', 1.4) });
        const bb = (x, y, rr) => paint(circ(x, y, rr), grad('#8A78F0', '#4A38A8', 0, 0, 1, 1), { w: 0.8, lines: line(`M${f(x - 1.6)} ${f(y - rr * 0.45)}l1.6 1.4l1.6 -1.4`, '#2A1A70', 0.8) + `<circle cx="${f(x - rr * 0.4)}" cy="${f(y - rr * 0.4)}" r="${f(rr * 0.25)}" fill="#E8E4FF"/>` });
        s += bb(10, 96, 5) + bb(20.5, 99.5, 4);
        [[86, 96], [90.5, 94], [95, 96], [88, 100], [93, 100], [90.5, 98], [84, 100.5], [97, 100.5]].forEach(([x, y]) => (s += paint(circ(x, y, 2.5), grad('#FF6A88', '#D02850', 0, 0, 1, 1), { w: 0.6 })));
        return s + `<g transform="translate(90 92) rotate(-150)">${leafA(10, 3.6, '#9AF0B0', '#40B878', '#186048', r, 0.7)}</g>`;
      },
    },
    die_r_plant: {
      tier: 2, name: 'Sprout Vine', tag: 'Mastery · Plant', border: '#000', calm: ['#F2FBDC', '#D8F0B4', '#BCE290'],
      spec: ['Border #000, 4 px.', 'Two materials: a spring-green field (#F2FBDC → #D8F0B4) printed with leaf silhouettes #BCE290 (12:1 to ink), plus a vine along the bottom (#5FA82A on maroon) carrying five chunky leaves.', 'A curled tendril top-right. Static.'],
      plate() {
        const r = rng(59); let s = `<rect width="104" height="104" fill="${grad('#F2FBDC', '#D8F0B4', 0, 0, 0, 1)}"/>`;
        [[20, 40, 30], [70, 36, -20], [30, 70, 60], [80, 70, 10], [52, 56, -60], [8, 84, 20]].forEach(([x, y, a]) => (s += `<g transform="translate(${x} ${y}) rotate(${a})">${line('M-11 0Q0 -8 11 0Q0 8 -11 0ZM-8 0H8', '#BCE290', 1.2)}</g>`));
        const vp = [[-4, 96], [14, 90], [30, 95], [48, 89], [66, 94], [84, 88], [108, 93]], vd = smooth(vp, false);
        s += line(vd, OL, 4.4) + line(vd, '#5FA82A', 2.4);
        [[14, 90, -110], [30, 95, -60], [48, 89, -118], [66, 94, -55], [84, 88, -112]].forEach(([x, y, a]) => (s += `<g transform="translate(${x} ${y}) rotate(${a})">${leafA(13, 4.8, '#A8E060', '#5FA82A', '#2E6010', r, 0.85)}</g>`));
        return s + line('M104 27c-8 2 -9 10 -3 12c3 1 4 -3 1 -4', OL, 2.6) + line('M104 27c-8 2 -9 10 -3 12c3 1 4 -3 1 -4', '#5FA82A', 1.2);
      },
    },
    die_r_beast: {
      tier: 2, name: 'Wildfur', tag: 'Mastery · Beast', border: '#000', calm: ['#FFF3DE', '#FFDEAE', '#F2C07C'],
      spec: ['Border #000, 4 px.', 'Two materials: warm fur (#FFF3DE → #FFDEAE) with tuft strokes #F2C07C (9.7:1 to ink), plus a fluffy orange ruff along the bottom (#FFC35A → #E0861E, strands #B85A10).', 'Three claw slashes (#C8682A) top-right and a paw print top-left, both above the calm zone. Static.'],
      plate() {
        const r = rng(61); let s = `<rect width="104" height="104" fill="${grad('#FFF3DE', '#FFDEAE', 0, 0, 0, 1)}"/>`, fur = '';
        for (let i = 0; i < 40; i++) { const x = r() * 104, y = 26 + r() * 62; fur += `M${f(x)} ${f(y)}q2 3 ${f(1 + r() * 2)} 6`; }
        s += line(fur, '#F2C07C', 1.1);
        [70, 79, 88].forEach((x) => (s += paint(`M${x} 27Q${x - 2} 35 ${x - 8} 44Q${x - 1} 36 ${x + 3} 28Z`, '#C8682A', { w: 0.7 })));
        s += [[12, 39, 3.8], [7.5, 32.5, 1.7], [12, 30.5, 1.7], [16.5, 32.5, 1.7]].map(([x, y, rr]) => `<circle cx="${x}" cy="${y}" r="${rr}" fill="#E8A050"/>`).join('');
        let d = 'M-4 112V90'; for (let x = -4; x < 108; x += 8) d += `Q${x + 4} ${f(82.5 + r() * 3)} ${x + 8} 90`; d += 'V112Z';
        let st = ''; for (let x = 0; x < 104; x += 8) st += `M${x} 93l-1 6`;
        return s + paint(d, grad('#FFC35A', '#E0861E', 0, 0, 0, 1), { w: 1, lines: line(st, '#B85A10', 1) });
      },
    },
    die_r_reptile: {
      tier: 2, name: 'Scute Mosaic', tag: 'Mastery · Reptile', border: '#000', calm: ['#F3EAFF', '#DFCEF8', '#C6ACEE'],
      spec: ['Border #000, 4 px.', 'Two materials: a pale lilac hex-scale field (#F3EAFF → #DFCEF8), hex lines #C6ACEE (9.1:1 to ink), plus a row of big glossy scutes along the bottom (#B694FF → #7D4CE7, shine #E2C8FF) with maroon outline. Static.'],
      plate() {
        let s = `<rect width="104" height="104" fill="${grad('#F3EAFF', '#DFCEF8', 0, 0, 0, 1)}"/>`, g = ''; const R = 8;
        for (let row = 0; row < 10; row++) for (let col = -1; col < 9; col++) { const cx = col * R * 1.732 + (row % 2) * R * 0.866, cy = 20 + row * R * 1.5; for (let k = 0; k < 6; k++) { const a = Math.PI / 6 + (k * Math.PI) / 3; g += (k ? 'L' : 'M') + f(cx + Math.cos(a) * R) + ' ' + f(cy + Math.sin(a) * R); } g += 'Z'; }
        s += line(g, '#C6ACEE', 1.1);
        for (let x = -4; x < 108; x += 16) s += paint(`M${x} 112V94Q${x} 88 ${x + 8} 87Q${x + 16} 88 ${x + 16} 94V112Z`, grad('#B694FF', '#7D4CE7', 0, 0, 0, 1), { w: 0.9, lines: line(`M${x + 4} 93Q${x + 8} 90.5 ${x + 12} 93`, '#E2C8FF', 1.3) });
        return s;
      },
    },
    die_r_bug: {
      tier: 2, name: 'Ladyshell', tag: 'Mastery · Bug', border: '#000', calm: ['#FFEEEA', '#FCD6CE', '#F2AC9C'],
      spec: ['Border #000, 4 px.', 'Two materials: a blush carapace (#FFEEEA → #FCD6CE) with segment arcs and a centre seam in #F2AC9C (9.0:1 to ink), plus a ladybird shell along the bottom (#FF6E5E → #D83A30, maroon spots and split).', 'Two curled antennae with red tips in the top corners. Static.'],
      plate() {
        let s = `<rect width="104" height="104" fill="${grad('#FFEEEA', '#FCD6CE', 0, 0, 0, 1)}"/>`, g = '';
        for (let y = 30; y < 88; y += 9) g += `M-2 ${y}Q52 ${y + 6} 106 ${y}`;
        s += line(g + 'M52 26V88', '#F2AC9C', 1.2);
        s += paint('M-4 112V93Q52 80 108 93V112Z', grad('#FF6E5E', '#D83A30', 0, 0, 0, 1), { w: 1, lines: line('M52 86V112', OL, 1.4) + [[20, 98, 4], [36, 94, 3], [68, 94, 3], [84, 98, 4], [10, 104, 2.6], [94, 104, 2.6]].map(([x, y, rr]) => `<circle cx="${x}" cy="${y}" r="${rr}" fill="${OL}"/>`).join('') + line('M8 94Q30 86 46 87', '#FFB0A0', 1.6) });
        const ant = (d, x, y) => line(d, OL, 1.6) + `<circle cx="${x}" cy="${y}" r="2.4" fill="#FF6E5E" stroke="${OL}" stroke-width="1"/>`;
        return s + ant('M4 26Q14 29 16 39', 16, 40) + ant('M100 26Q90 29 88 39', 88, 40);
      },
    },
    die_r_bird: {
      tier: 2, name: 'Plume Fan', tag: 'Mastery · Bird', border: '#000', calm: ['#EFF9FF', '#CFEEFF', '#A2D6F2'],
      spec: ['Border #000, 4 px.', 'Two materials: sky down (#EFF9FF → #CFEEFF) with feather scallops #A2D6F2 (11:1 to ink), plus seven tail feathers fanned up from the bottom edge, alternating pink (#FFB0D4 → #E85A9A) and blue (#A8E6FF → #3AA8E8) with quills. Static.'],
      plate() {
        let s = `<rect width="104" height="104" fill="${grad('#EFF9FF', '#CFEEFF', 0, 0, 0, 1)}"/>`, d = '';
        for (let row = 0; row < 8; row++) { const y = 24 + row * 9, off = (row % 2) * 9; for (let x = -18 + off; x < 110; x += 18) d += `M${x} ${y}q9 12 18 0`; }
        s += line(d, '#A2D6F2', 1.2);
        const PK = ['#FFB0D4', '#E85A9A', '#A02860'], BL = ['#A8E6FF', '#3AA8E8', '#1A5A9A'];
        const fea = (ang, len, C) => `<g transform="translate(52 118) rotate(${ang})">${paint(`M0 0C-6 ${-len * 0.4} -5.5 ${-len * 0.85} 0 ${-len}C5.5 ${-len * 0.85} 6 ${-len * 0.4} 0 0Z`, grad(C[0], C[1], 0, 0, 0, 1), { w: 0.9, lines: line(`M0 -2V${-len + 3}M0 ${f(-len * 0.5)}l-4 -3M0 ${f(-len * 0.66)}l4 -3`, C[2], 0.9) })}</g>`;
        return s + fea(-70, 60, PK) + fea(70, 60, PK) + fea(-48, 45, BL) + fea(48, 45, BL) + fea(-24, 35, PK) + fea(24, 35, PK) + fea(0, 32, BL);
      },
    },
    die_e_spore: {
      tier: 3, name: 'Glowshroom Grove', border: '#3B1A5C', calm: ['#F3EFFF', '#DDE6F6'],
      spec: ['Border #3B1A5C (deep Mystic), 4 px. Reads as black at 36 px.', 'Moonlit mist field (#F3EFFF → #DDE6F6). Ornament: violet toadstool clusters in both lower corners (caps #D49CFF → #9A5AE6, spots #F4E8FF, cream stems) on a plum moss rim (#7A60C8 → #4A3090).', 'glow.png: mint halos #9AF0D8 behind each cluster + 7 floating spores (core #E8FFF8, rim #3AB89A), blend Add. All spores sit above the calm zone or at the side edges.', 'Idle: halos pulse 0.25→0.9 over 2.0 s; spores twinkle 2.0 s, staggered 0.3 s. Reduce flashing: halos 0.5→0.65, spores opacity only.'],
      plate(o) {
        const r = rng(67); let s = `<rect width="104" height="104" fill="${grad('#F3EFFF', '#DDE6F6', 0, 0, 0, 1)}"/>`; const halo = rgDef('#9AF0D8', 0.9);
        s += `<g style="${A(o, 'cosPulse', 2)}" opacity="${o.static ? 0.6 : 1}"><circle cx="16" cy="88" r="20" fill="${halo}"/><circle cx="88" cy="86" r="22" fill="${halo}"/></g>`;
        const pts = []; for (let x = -6; x <= 112; x += 9) pts.push([x, 94 + J(r, 1.6)]);
        s += band(pts, grad('#7A60C8', '#4A3090', 0, 0, 0, 1), { w: 1 });
        const shroom = (x, y, h, w, c1, c2) => paint(`M${f(x - w * 0.18)} ${y}Q${f(x - w * 0.24)} ${f(y - h * 0.5)} ${f(x - w * 0.14)} ${f(y - h)}H${f(x + w * 0.14)}Q${f(x + w * 0.24)} ${f(y - h * 0.5)} ${f(x + w * 0.18)} ${y}Z`, grad('#FFF8EC', '#E2D2C4', 0, 0, 1, 0), { w: 0.9 }) + paint(`M${f(x - w / 2)} ${f(y - h + 2)}Q${f(x - w / 2)} ${f(y - h - w * 0.55)} ${x} ${f(y - h - w * 0.55)}Q${f(x + w / 2)} ${f(y - h - w * 0.55)} ${f(x + w / 2)} ${f(y - h + 2)}Q${x} ${f(y - h - 1.5)} ${f(x - w / 2)} ${f(y - h + 2)}Z`, grad(c1, c2, 0, 0, 0, 1), { w: 1, lines: [[-0.22, -0.3, 0.09], [0.18, -0.38, 0.07], [0.3, -0.12, 0.05]].map(([dx, dy, rr]) => `<circle cx="${f(x + dx * w)}" cy="${f(y - h + dy * w)}" r="${f(rr * w)}" fill="#F4E8FF"/>`).join('') });
        s += shroom(24, 99, 9, 12, '#9AF0D8', '#3AB89A') + shroom(12, 98, 16, 20, '#D49CFF', '#9A5AE6') + shroom(78, 99, 8, 11, '#9AF0D8', '#3AB89A') + shroom(91, 98, 19, 22, '#D49CFF', '#9A5AE6');
        [[30, 33, 0], [60, 30, 0.3], [86, 40, 0.6], [6, 54, 0.9], [98, 62, 1.2], [44, 39, 1.5], [72, 35, 1.8]].forEach(([x, y, dl]) => (s += `<g style="transform-origin:${x}px ${y}px;${A(o, 'cosTwinkle', 2, `ease-in-out ${dl}s infinite`)}"><circle cx="${x}" cy="${y}" r="4.5" fill="${halo}"/><circle cx="${x}" cy="${y}" r="1.5" fill="#E8FFF8" stroke="#3AB89A" stroke-width=".6"/></g>`));
        return s;
      },
    },
    die_e_s1_founder: {
      tier: 3, name: 'Founder’s Laurel', tag: 'Pass S1 · founding season', border: '#5A2A0A', calm: ['#FFF8E8', '#F4E2C0', '#EBD5A8'],
      spec: ['Border #5A2A0A (dark bronze), 4 px. Reads as black at 36 px.', 'Parchment (#FFF8E8 → #F4E2C0) with a faint star print #EBD5A8. Ornament: two laurel branches climb the side edges (leaves #B4E070 → #6AA02A, kept at x ≤ 9 and x ≥ 95), an orange Season-1 shield sits above the value row, and a gold ribbon (#FFD36A → #F0A030) reading “SEASON 1” in Baloo 2 800 #6B2B2B runs below it.', 'Idle: the two gold stars in the top corners twinkle, 2.0 s, offset 1.0 s. Reduce flashing: opacity only.'],
      plate(o) {
        const r = rng(71); let s = `<rect width="104" height="104" fill="${grad('#FFF8E8', '#F4E2C0', 0, 0, 0, 1)}"/>`;
        for (let i = 0; i < 4; i++) for (let j = 0; j < 4; j++) s += star4(16 + j * 24 + (i % 2) * 12, 32 + i * 16, 2.2, '#EBD5A8', '#EBD5A8');
        const br = (m) => { const Q = (t) => [(1 - t) * (1 - t) * 8 + 2 * t * (1 - t) * -1 + t * t * 4, (1 - t) * (1 - t) * 100 + 2 * t * (1 - t) * 68 + t * t * 30]; let g = line('M8 100Q-1 68 4 30', OL, 2.6) + line('M8 100Q-1 68 4 30', '#6AA02A', 1.3); for (let k = 0; k < 7; k++) { const [x, y] = Q(0.08 + k * 0.13); g += `<g transform="translate(${f(x)} ${f(y)}) rotate(${k % 2 ? -62 : -112})">${leafA(7, 2.8, '#B4E070', '#6AA02A', '#2E5A10', r, 0.55)}</g>`; } return m ? `<g transform="translate(104 0) scale(-1 1)">${g}</g>` : g; };
        s += br(0) + br(1);
        s += paint('M45 27H59V35Q59 41 52 44Q45 41 45 35Z', grad('#FFB060', '#D9601A', 0, 0, 0, 1), { w: 0.9 }) + star4(52, 34.5, 4, '#FFF4E0', '#B04A10');
        s += paint('M10 88H94L90 95L94 102H10L14 95Z', grad('#FFD36A', '#F0A030', 0, 0, 0, 1), { w: 1 }) + `<text x="52" y="97.6" text-anchor="middle" font-family="'Baloo 2',cursive" font-weight="800" font-size="8" letter-spacing=".8" fill="${OL}">SEASON 1</text>`;
        return s + star4(18, 33, 4.2, '#FFE48A', '#E08A12', A(o, 'cosTwinkle', 2)) + star4(86, 33, 4.2, '#FFE48A', '#E08A12', A(o, 'cosTwinkle', 2, 'ease-in-out 1s infinite'));
      },
    },
    die_l_relic_stone: {
      tier: 4, name: 'Relic Seam', border: '#3A3020', calm: ['#F3EFE6', '#DDD6C6', '#B4AA96'],
      spec: ['Border #3A3020 (old stone), 4 px.', 'Running-bond stone blocks (#F3EFE6 → #DDD6C6, mortar #B4AA96 at 8.4:1 to ink) with chip marks. Ornament: a carved keystone at the bottom centre with a glowing sun glyph.', 'Light layer (glow.png): golden seams crack down both side edges and along the bottom: halo #FFC870 6 px at 55 %, edge #C8701A 2.6 px, core #FFF4C8 1.2 px. Seams never enter the calm zone.', 'Idle: halo pulses 0.25→0.9, 2.4 s. Reduce flashing: 0.5→0.65.'],
      plate(o) {
        const r = rng(73); let s = `<rect width="104" height="104" fill="#B4AA96"/>`;
        for (let row = 0; row < 7; row++) { const y = 22 + row * 13.5, off = (row % 2) * 13; for (let x = -26 + off; x < 110; x += 26) s += paint(`M${x + 2.5} ${y + 1}h21a2 2 0 0 1 2 2v9.5a2 2 0 0 1 -2 2h-21a2 2 0 0 1 -2 -2v-9.5a2 2 0 0 1 2 -2Z`, grad('#F3EFE6', '#DDD6C6', 0, 0, 0, 1), { w: 0.4, ol: '#B4AA96', lines: line(`M${f(x + 5 + r() * 14)} ${f(y + 4 + r() * 6)}l2 1`, '#C8BEAA', 0.8) }); }
        const seam = 'M5 24L8 36L3 47L7 60L2 72L6 86L4 104M99 24L96 38L101 50L97 64L102 76L98 90L100 104M4 92L16 95L28 91L40 96L52 92L64 96L76 91L88 95L100 92';
        s += `<g style="${A(o, 'cosPulse', 2.4)}" opacity="${o.static ? 0.7 : 1}">${line(seam, '#FFC870', 6, 0.55)}</g>` + line(seam, '#C8701A', 2.6) + line(seam, '#FFF4C8', 1.2);
        s += paint('M42 86H62L60 104H44Z', grad('#F3EFE6', '#CFC6B2', 0, 0, 0, 1), { w: 0.9, ol: '#8A7E68' });
        let ray = ''; for (let k = 0; k < 8; k++) { const [x1, y1] = P(4.6, k * 45, 52, 95), [x2, y2] = P(6.8, k * 45, 52, 95); ray += `M${x1} ${y1}L${x2} ${y2}`; }
        return s + line(ray, '#C8701A', 1.1) + `<circle cx="52" cy="95" r="3.4" fill="#FFE08A" stroke="#C8701A" stroke-width="1"/>`;
      },
    },
    die_l_kingdom: {
      tier: 4, name: 'Lunacia Sovereign', tag: 'Echo Box · pairs with Pass lv30 “LUNACIA SOVEREIGN”', border: '#24388A', calm: ['#FFFAF0', '#F6E8D0', '#EAD4AC'],
      spec: ['Border #24388A (royal navy), 4 px. Reads as black at 36 px.', 'Ivory damask (#FFFAF0 → #F6E8D0, diamond motif #EAD4AC at 12:1 to ink). Ornament: a royal-blue velvet hem (#4A68D8 → #24388A) under a gold trim line (#FFC93C on maroon), a gold crown (#FFE48A → #E8A020, ruby #E8304A, sapphires #3AC8F0) and four gold stars on the hem, gold filigree in the top corners.', 'Light layer: diagonal white sheen, 50 %, blend Add. Idle: sweeps across in 1.2 s, then rests. 3.6 s loop. Reduce flashing: sheen at 20 %.'],
      plate(o) {
        let s = `<rect width="104" height="104" fill="${grad('#FFFAF0', '#F6E8D0', 0, 0, 0, 1)}"/>`, dm = '';
        for (let row = 0; row < 5; row++) for (let col = 0; col < 5; col++) { const x = col * 26 + (row % 2) * 13, y = 28 + row * 15; dm += `M${x} ${y - 5}L${x + 4} ${y}L${x} ${y + 5}L${x - 4} ${y}ZM${x} ${y - 2}v4`; }
        s += line(dm, '#EAD4AC', 1);
        s += paint('M-4 112V88H108V112Z', grad('#4A68D8', '#24388A', 0, 0, 0, 1), { w: 1 }) + line('M-4 87.5H108', OL, 4.6) + line('M-4 87.5H108', '#FFC93C', 2.6);
        [14, 28, 76, 90].forEach((x) => (s += star4(x, 97, 2.8, '#FFE48A', '#B87810')));
        s += paint('M40 103V92L45 96L52 89L59 96L64 92V103Z', grad('#FFE48A', '#E8A020', 0, 0, 0, 1), { w: 0.9, lines: '<circle cx="52" cy="98.5" r="1.9" fill="#E8304A"/><circle cx="45.5" cy="99.5" r="1.3" fill="#3AC8F0"/><circle cx="58.5" cy="99.5" r="1.3" fill="#3AC8F0"/>' });
        s += line('M4 28c8 0 10 8 4 10c-3 1 -4 -3 -1 -3M100 28c-8 0 -10 8 -4 10c3 1 4 -3 1 -3', '#E0A030', 1.4);
        return s + `<g style="${A(o, 'cosSheen', 3.6)}"><path d="M-40 0H-24L-54 104H-70Z" fill="#FFFFFF" opacity=".5"/><path d="M-19 0H-15L-45 104H-49Z" fill="#FFFFFF" opacity=".45"/></g>`;
      },
    },
    die_m_moon: {
      tier: 5, name: 'Moonface Dreamer', tag: 'Echo Box · the moon disc is the value plate', border: '#2E2266', calm: ['#FFF9EC', '#F0DCC0', '#EBD6B6', '#F8C8C0'],
      spec: ['Border #2E2266 (night violet), 4 px. Reads as black at 36 px.', 'Dark skin handled without a separate plate: a full moon (r 52, centre 52/68; #FFF9EC → #F0DCC0, rim #E8A060) covers the whole calm zone, so the number sits on the moon. Night field outside it (#30246A → #120C34) with star dust.', 'Signature: the moon has a sleeping face. Closed eyes sit above the value row (y 39), blush #F8C8C0 at the sides, a small smile below it (y 92). Faint craters #EBD6B6.', 'Idle: a warm halo (#FFE8B0 radial) breathes 0.25→0.9 over 3.0 s; four blue-rimmed sparkles twinkle 1.6 s, staggered. Reduce flashing: halo 0.5→0.65, sparkles opacity only.', 'MAX settle: the eyes open for 0.8 s (two #6B2B2B pupils with cream catch-lights) and the halo flares to r 70. Reduced: eyes only.'],
      plate(o) {
        const r = rng(79); let s = `<rect width="104" height="104" fill="${grad('#30246A', '#120C34', 0, 0, 0, 1)}"/>`;
        s += `<circle cx="52" cy="68" r="64" fill="${rgDef('#FFE8B0', 0.85)}" style="${A(o, 'cosPulse', 3)}" opacity="${o.static ? 0.6 : 1}"/>`;
        let n = 0; for (let i = 0; i < 60 && n < 12; i++) { const x = r() * 104, y = 26 + r() * 78; if (Math.hypot(x - 52, y - 68) > 58) { n++; s += `<circle cx="${f(x)}" cy="${f(y)}" r="${f(0.6 + r() * 0.6)}" fill="#FFF4E4"/>`; } }
        const cr = [[20, 76, 5], [86, 74, 6], [30, 99, 4], [76, 97, 3.5], [62, 30, 3], [40, 30, 2.4]].map(([x, y, rr]) => `<circle cx="${x}" cy="${y}" r="${rr}" fill="#EBD6B6"/>`).join('');
        s += paint(circ(52, 68, 52), grad('#FFF9EC', '#F0DCC0', 0, 0, 1, 1), { w: 1.2, ol: '#E8A060', lines: cr + '<ellipse cx="18" cy="58" rx="6" ry="3.6" fill="#F8C8C0"/><ellipse cx="86" cy="58" rx="6" ry="3.6" fill="#F8C8C0"/>' + line('M30 38q6 5 12 0M62 38q6 5 12 0M30 38l-2 -2M74 38l2 -2', OL, 2.2) + line('M46 91q6 5 12 0', OL, 1.8) });
        [[8, 30, 4, 0], [96, 30, 3.6, 0.6], [6, 92, 3, 1.1], [98, 92, 3.2, 0.3]].forEach(([x, y, rr, dl]) => (s += sparkle(x, y, rr, 'blue', A(o, 'cosTwinkle', 1.6, `ease-in-out ${dl}s infinite`))));
        return s;
      },
    },
  });
  { const ORD = ['die_c_reed', 'die_c_sunwood', 'die_c_clay', 'die_u_moss', 'die_u_bark', 'die_u_berry', 'die_r_plant', 'die_r_beast', 'die_r_aqua', 'die_r_reptile', 'die_r_bug', 'die_r_bird', 'die_e_rune', 'die_e_spore', 'die_e_s1_founder', 'die_l_gold', 'die_l_relic_stone', 'die_l_kingdom', 'die_m_redcrystal', 'die_m_moon']; const tmp = Object.assign({}, DIE); ORD.forEach((k) => { delete DIE[k]; DIE[k] = tmp[k]; }); }
  Object.values(DIE).forEach((d) => { d.contrast = Math.min(...d.calm.map((c) => contrast(c, INK))); });
  const wrapDefs = (u, sc, body) => { const b = body(); const defs = DEFS.join(''); DEFS = []; return [softDefs(u, sc) + defs, b]; };

  function plateSVG(id, o = {}) {
    const u = ++uid; CU = u; DEFS = [];
    const [defs, body] = wrapDefs(u, 0.4, () => DIE[id].plate(o));
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 104 104" width="${o.size || 512}" height="${o.size || 512}"><defs>${defs}<clipPath id="cp${u}"><rect width="104" height="104"/></clipPath></defs><g clip-path="url(#cp${u})">${body}</g></svg>`;
  }
  const CLASS = { plant: '#7DC943', aqua: '#39C5F3', beast: '#FFB23F', reptile: '#B679F7', bug: '#F2624F', bird: '#8BDCFF' };
  function dieSVG(id, s, o = {}) {
    const d = DIE[id], k = 104 / s, bw = (s <= 40 ? 3 : 4) * k, u = ++uid; CU = u; DEFS = [];
    const cls = CLASS[o.cls || 'plant'], val = String(o.value ?? 6), type = o.type || 'dmg';
    const fs = 41.6, iw = 31.2, gap = 6.24, tw = 0.56 * fs * val.length, x0 = -(tw + gap + iw) / 2 + 52, cy = 52 + 12.48, R = 18.72, h = bw / 2;
    const [defs, body] = wrapDefs(u, 0.4, () => d.plate(o));
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 104 104" width="${s}" height="${s}" style="display:block;overflow:visible"><defs>${defs}<clipPath id="cd${u}"><rect width="104" height="104" rx="${R}"/></clipPath></defs>
<g clip-path="url(#cd${u})">${body}</g>
<path d="M${h} 24.96V${R}A${R - h} ${R - h} 0 0 1 ${R} ${h}H${104 - R}A${R - h} ${R - h} 0 0 1 ${104 - h} ${R}V24.96Z" fill="${cls}" stroke="#000" stroke-width="${bw}"/>
<text x="${x0}" y="${cy}" dominant-baseline="central" font-family="'Baloo 2',cursive" font-weight="800" font-size="${fs}" fill="${INK}" dy="2">${val}</text>
<rect x="${x0 + tw + gap}" y="${cy - iw / 2}" width="${iw}" height="${iw}" rx="7" fill="${TYPE[type]}" stroke="#000" stroke-width="${(bw / k - 1) * k}"/>
<image href="assets/icons/${type}.png" x="${x0 + tw + gap + iw * 0.18}" y="${cy - iw / 2 + iw * 0.18}" width="${iw * 0.64}" height="${iw * 0.64}"/>
<rect x="${h}" y="${h}" width="${104 - bw}" height="${104 - bw}" rx="${R - h}" fill="none" stroke="${d.border}" stroke-width="${bw}"/></svg>`;
  }

  // ---------- AVATAR FRAMES (256 canvas, window circle Ø168, band r 84–102) ----------
  const tri = (r1, r2, n, a0, col, lineCol) => { let s = '', ln = ''; for (let i = 0; i < n; i++) { const a = a0 + (i * 360) / n, st = 360 / n, p1 = P(r1 - 2, a), p2 = P(r2 + 2, a + st * 0.5), p3 = P(r1 - 2, a + st); s += `M${pp(p1)}L${pp(p2)}L${pp(p3)}Z`; ln += `M${pp(p1)}L${pp(p2)}L${pp(p3)}`; } return `<path d="${s}" fill="${col}"/>` + line(ln, lineCol, 1.6); };
  const FRAME = {
    frame_c_plant: {
      tier: 0, name: 'Sprout Wreath', tag: 'Mastery · Plant', seed: 101,
      spec: ['Static. Built like Homeland_Avatar frame_3: a zig-zag band, one big cluster at the top, a leaf spray on the right and a sleeping critter at the bottom.', 'Band r 84–102: leaf green #9AD46A with darker triangles #6CB04E and line #4E8A3C. Maroon outline #6B2B2B, 3.2 px.', 'Top cluster: three broad leaves (#C2EC8E → #6CB04E, veins #4E8A3C) holding a pink flower (#FFB0C0 → #E68AD0). This is the 40 px silhouette cue.', 'A sleeping sprout-bud critter (closed eyes, blush, leaf on its head) at 7 o’clock, a leaf spray at 4 o’clock and two teal-rimmed sparkles.'],
      base() {
        const r = rng(this.seed); let s = '';
        s += bandA(84, 102, '#9AD46A', tri(84, 102, 14, -90, '#6CB04E', '#4E8A3C'), '#4E8A3C', r);
        [[60, 34, -10], [40, 30, 30], [24, 26, 64]].forEach(([a, L, rot]) => { const [x, y] = P(100, a); s += `<g transform="translate(${x} ${y}) rotate(${a + rot - 90})">${leafA(L, L * 0.34, '#C2EC8E', '#6CB04E', '#4E8A3C', r)}</g>`; });
        [[-100, 46, -150], [-100, 44, -40], [-100, 34, -95]].forEach(([a, L, rot]) => { const [x, y] = P(98, a); s += `<g transform="translate(${x} ${y}) rotate(${rot})">${leafA(L, L * 0.36, '#C2EC8E', '#6CB04E', '#4E8A3C', r, 3.4)}</g>`; });
        const [fx, fy] = P(98, -100); let pet = '';
        for (let i = 0; i < 5; i++) { const a = i * 72 - 90; pet += `M${fx} ${fy}C${pp(P(14, a - 30, fx, fy))} ${pp(P(20, a - 12, fx, fy))} ${pp(P(19, a, fx, fy))}C${pp(P(20, a + 12, fx, fy))} ${pp(P(14, a + 30, fx, fy))} ${fx} ${fy}Z`; }
        s += paint(pet, grad('#FFB0C0', '#E68AD0', 0, 0, 1, 1), { w: 3, lines: line(pet, '#E070B0', 0.8, 0.6) }) + paint(circ(fx, fy, 5.5), grad('#FFE890', '#F8B048'), { w: 2.4 });
        const [cx, cy] = P(100, 118);
        s += paint(blob(cx, cy, 19, 16, 10, 0.03, r), grad('#B8E890', '#6CB04E', 0, 0, 0.4, 1), { w: 3.2, soft: `<path d="${circ(cx + 6, cy + 10, 14)}" fill="#4E8A3C" opacity=".5"/>`, lines: line(`M${f(cx - 9)} ${f(cy - 1)}q3 3 6 0M${f(cx + 3)} ${f(cy - 1)}q3 3 6 0`, OL, 1.8) + `<ellipse cx="${f(cx - 10)}" cy="${f(cy + 5)}" rx="3.4" ry="2" fill="#F8A0B0" opacity=".85"/><ellipse cx="${f(cx + 10)}" cy="${f(cy + 5)}" rx="3.4" ry="2" fill="#F8A0B0" opacity=".85"/>` });
        s += `<g transform="translate(${f(cx + 2)} ${f(cy - 15)}) rotate(-70)">${leafA(16, 6, '#C2EC8E', '#6CB04E', '#4E8A3C', r, 2.6)}</g>`;
        return s + sparkle(...P(116, 172), 10) + sparkle(...P(118, 150), 6.5);
      },
    },
    frame_u_mushroom: {
      tier: 1, name: 'Toadstool Log', seed: 202,
      spec: ['Static. Band r 84–102: a bark log (#D07848 → #A85038) with grain lines #7A3424 and a soft light on the upper left. Maroon outline.', 'A big toadstool cluster at 2 o’clock (caps #FF9C9C → #E0505A, cream spots, gills #F0C8A0; stems cream) and a small pair at 8 o’clock.', 'A clover sprig on top (#7AD88A → #40A888) and two orange-rimmed sparkles. The asymmetric clusters carry the 40 px read.'],
      base() {
        const r = rng(this.seed); let s = '', gr = '';
        for (let k = 0; k < 14; k++) { const a = k * 25.7 + J(r, 6), rr = 88 + r() * 9; gr += `M${pp(P(rr, a))}Q${pp(P(rr + J(r, 1.5), a + 6))} ${pp(P(rr, a + 12 + r() * 4))}`; }
        s += bandA(84, 102, grad('#D07848', '#A85038', 0, 0, 1, 1), line(gr, '#7A3424', 1.8), '#7A3424', r);
        const mush = (a, sc, lean, squat, c1, c2) => {
          const [x, y] = P(101, a), hh = squat ? 13 : 21;
          const stem = `M-7.5 2C-8.5 -6 -6.5 -${hh - 4} -5.5 -${hh}L6 -${hh}C6.5 -${hh - 6} 9.5 -6 8.5 2Z`;
          const cap = `M-26 ${-hh + 3}C-28 ${-hh - 20} -8 ${-hh - 29} 3 ${-hh - 28}C19 ${-hh - 26} 28 ${-hh - 12} 26 ${-hh + 3}C12 ${-hh + 7} -12 ${-hh + 7} -26 ${-hh + 3}Z`;
          let spots = ''; [[-12, -hh - 12, 5], [6, -hh - 20, 3.6], [16, -hh - 8, 3], [-2, -hh - 4, 2.2]].forEach(([sx, sy, sr]) => (spots += `<path d="${blob(sx, sy, sr, sr * 0.85, 7, 0.12, r)}" fill="#FFF4E4"/>`));
          return `<g transform="translate(${x} ${y}) rotate(${a + 90 + lean}) scale(${sc})">${paint(stem, grad('#FFF8EC', '#F0D8C0', 0, 0, 1, 0), { w: 3 })}${paint(`M-22 ${-hh + 2}Q0 ${-hh + 10} 22 ${-hh + 2}Z`, '#F0C8A0', { w: 2.4, lines: line(`M-12 ${-hh + 3}l2 3M-4 ${-hh + 4}l.5 3M4 ${-hh + 4}l-.5 3M12 ${-hh + 3}l-2 3`, '#C86038', 1.3) })}${paint(cap, grad(c1, c2, 0, 0, 0.8, 1), { w: 3.2, lines: spots, hl: line(`M-18 ${-hh - 9}Q-14 ${-hh - 20} -2 ${-hh - 23}`, '#FFFFFF', 2.4, 0.75) })}</g>`;
        };
        s += mush(-30, 0.62, -12, true, '#FFB890', '#F07848') + mush(-62, 1.12, 8, false, '#FF9C9C', '#E0505A') + mush(-8, 0.7, 14, false, '#FF9C9C', '#E0505A') + mush(146, 0.58, 10, false, '#FF9C9C', '#E0505A') + mush(166, 0.5, -8, true, '#FFB890', '#F07848');
        const [kx, ky] = P(102, -120);
        [[-170, 22], [-120, 24], [-70, 20]].forEach(([rot, L]) => (s += `<g transform="translate(${kx} ${ky}) rotate(${rot})">${paint(`M0 0C${L * 0.2} ${-L * 0.55} ${L} ${-L * 0.6} ${L} 0C${L} ${L * 0.6} ${L * 0.2} ${L * 0.55} 0 0Z`, grad('#7AD88A', '#40A888', 0, 0, 1, 1), { w: 2.6, lines: line(`M2 0H${L * 0.8}`, '#186048', 1.4) })}</g>`));
        return s + sparkle(...P(118, 205), 9, 'orange') + sparkle(...P(120, 100), 7, 'orange');
      },
    },
    frame_r_frost: {
      tier: 2, name: 'Frost Crown', seed: 303,
      spec: ['Static. Two materials, after the steel tube of frame_2: a glossy periwinkle band (#F0F4FF → #B8C4EC) whose lower right turns to deep ice #8898D0, with blue lines #7088C8 and white gloss strokes; and ice crystals.', 'An ice crown of five faceted spikes on top (#F6FBFF → #9FD8F0, facets #60A8D0). This is the 40 px silhouette cue.', 'A round snowflake medallion at 6 o’clock (#C8F0FF → #70C0E8, white flake) and three blue-rimmed sparkles.'],
      base() {
        const r = rng(this.seed); let s = '';
        const deep = `<path d="M${pp(P(120, -20))}L${pp(P(120, 150))}L${pp(P(60, 150))}L${pp(P(60, -20))}Z" fill="#8898D0" opacity="0"/>`;
        let lw = ''; for (const [a0, a1] of [[-170, -120], [190, 230], [-60, -30]]) lw += `M${pp(P(97, a0))}A97 97 0 0 1 ${pp(P(97, a1))}`;
        s += bandA(84, 102, grad('#F0F4FF', '#B8C4EC', 0, 0, 1, 1), deep + `<path d="M${pp(P(110, -15))}A110 110 0 0 1 ${pp(P(110, 140))}L${pp(P(78, 140))}A78 78 0 0 0 ${pp(P(78, -15))}Z" fill="${grad('#9AA8DC', '#7C8CCC', 0, 0, 1, 1)}"/>` + line(`M${pp(P(94, -10))}A94 94 0 0 1 ${pp(P(94, 130))}`, '#A8D8E8', 1.6) + line(lw, '#7088C8', 1.6) + line(`M${pp(P(98, 196))}A98 98 0 0 1 ${pp(P(98, 236))}`, '#FFFFFF', 3, 0.9), null, r);
        [[-118, 30, 9, 2], [-95, 50, 11, 3], [-72, 30, 9, 2], [-138, 18, 7, 1], [-52, 18, 7, 1]].forEach(([a, L, hw, lean]) => { const b1 = P(98, a - hw), b2 = P(98, a + hw), tp = P(98 + L, a + lean), m = P(98, a + lean * 0.3); s += paint(`M${pp(b1)}L${pp(tp)}L${pp(b2)}Z`, grad('#F6FBFF', '#9FD8F0', 0, 0, 1, 1), { w: 3, lines: `<path d="M${pp(m)}L${pp(tp)}L${pp(b2)}Z" fill="#9FD0EE" opacity=".8"/>` + line(`M${pp(m)}L${pp(tp)}`, '#60A8D0', 1.4) + line(`M${pp(P(100, a - hw * 0.5))}L${pp(P(98 + L * 0.65, a - 1))}`, '#FFFFFF', 2) }); });
        const [mx, my] = P(100, 90); let fl = '';
        for (let q = 0; q < 6; q++) { const t = q * 60 - 90, e = P(10, t, mx, my), m = P(6, t, mx, my), b1 = P(3, t + 55, m[0], m[1]), b2 = P(3, t - 55, m[0], m[1]); fl += `M${mx} ${my}L${pp(e)}M${pp(m)}L${pp(b1)}M${pp(m)}L${pp(b2)}`; }
        s += paint(circ(mx, my, 15), grad('#C8F0FF', '#70C0E8', 0, 0, 1, 1), { w: 3, lines: line(fl, '#FFFFFF', 2.2) + line(`M${f(mx - 10)} ${f(my - 5)}a11 11 0 0 1 8 -7`, '#FFFFFF', 1.8, 0.8) });
        return s + sparkle(...P(118, 200), 10, 'blue') + sparkle(...P(118, 20), 8, 'blue') + sparkle(...P(116, 160), 6, 'blue');
      },
    },
    frame_e_runering: {
      tier: 3, name: 'Runewheel', seed: 404,
      spec: ['Base (static), after the SS2 Fancy frame: a lilac band (#C898F0 → #A870D0) with diagonal stripes #B888E8, sky-blue inlays #B0E0F8 (line #4870C8) and a large faceted gem at the top (#B8F8D8 → #48D8A8, facets #F0FFF8) flanked by gold scroll curls (#F8C880 → #F0A050, line #E07828).', 'Pink-orange leaf sprays (#F8B060 → #E068C0) at 4 and 8 o’clock; orange-rimmed sparkles.', 'anim/rune_orbit.png: 6 cream runes with a violet outline orbit at r 112, 360° in 16 s, linear. anim/gem_glow.png: gem glow opacity 0.2→0.9, 2.0 s ease-in-out.', 'Reduce flashing: orbit unchanged; glow 0.5→0.65.'],
      base() {
        const r = rng(this.seed); let s = '', st = '';
        for (let k = 0; k < 16; k++) { const a = k * 22.5; st += `<path d="M${pp(P(80, a))}L${pp(P(106, a + 8))}L${pp(P(106, a + 16))}L${pp(P(80, a + 8))}Z" fill="#B888E8" opacity=".7"/>`; }
        const inlay = (a) => paint(blob(...P(93, a), 6, 9, 8, 0.15, r, ((a + 90) * Math.PI) / 180), grad('#D0F0FF', '#90C8F0'), { w: 1.4, ol: '#4870C8' });
        s += bandA(84, 102, grad('#D8A8F8', '#A870D0', 0, 0, 1, 1), st, '#8050C8', r) + inlay(180) + inlay(0) + inlay(-160) + inlay(-20);
        [[1, -116], [-1, -64]].forEach(([m, a]) => { const [x, y] = P(100, a); s += `<g transform="translate(${x} ${y}) scale(${m} 1)">${paint('M-10 6C-14 -6 -2 -14 6 -8C12 -3 6 5 1 1C-2 -2 2 -5 4 -3', 'none', { w: 3.2 })}<path d="M-10 6C-14 -6 -2 -14 6 -8C12 -3 6 5 1 1C-2 -2 2 -5 4 -3" stroke="${grad('#F8C880', '#F0A050')}" stroke-width="6" fill="none" stroke-linecap="round"/><path d="M-9 2C-10 -6 -1 -11 5 -7" stroke="#E07828" stroke-width="1.2" fill="none" stroke-linecap="round"/></g>`; });
        const [gx, gy] = P(104, -90);
        s += paint(`M${gx - 22} ${gy}L${gx - 12} ${gy - 12}H${gx + 12}L${gx + 22} ${gy}L${gx} ${gy + 16}Z`, grad('#B8F8D8', '#48D8A8', 0, 0, 1, 1), { w: 3.2, lines: line(`M${gx - 22} ${gy}H${gx + 22}M${gx - 12} ${gy - 12}L${gx - 6} ${gy}L${gx} ${gy + 16}L${gx + 6} ${gy}L${gx + 12} ${gy - 12}M${gx - 6} ${gy}L${gx} ${gy - 12}L${gx + 6} ${gy}`, '#F0FFF8', 1.3) });
        s += paint(circ(gx, gy - 16, 4.5), grad('#B8F8D8', '#48D8A8'), { w: 2.4 });
        const spray = (a, sc, rot) => { const [x, y] = P(100, a); let lv = ''; for (let i = 0; i < 5; i++) { const t = -60 + i * 30, L = i === 2 ? 22 : 15; lv += `M0 0Q${pp(P(L * 0.6, t - 14, 0, 0))} ${pp(P(L, t, 0, 0))}Q${pp(P(L * 0.6, t + 14, 0, 0))} 0 0Z`; } return `<g transform="translate(${x} ${y}) rotate(${rot}) scale(${sc})">${paint(lv, grad('#F8B060', '#E068C0', 0, 0, 0, 1), { w: 2.6, lines: line('M0 0L0 -20M0 0L-12 -12M0 0L12 -12', '#C850A8', 0.9) })}</g>`; };
        s += spray(30, 1.1, -30) + spray(150, 0.85, 40);
        return s + sparkle(...P(116, -150), 11, 'orange') + sparkle(...P(116, -30), 8, 'orange') + sparkle(...P(118, 175), 7, 'orange');
      },
      anim(o) {
        const [gx, gy] = P(104, -90); let g = '';
        for (let i = 0; i < 6; i++) { const a = i * 60 + 30, [x, y] = P(114, a); g += `<path transform="translate(${x} ${y}) rotate(${a + 90}) translate(-6 -7.2) scale(1.2)" d="${RUNES[i]}"/>`; }
        return `<ellipse cx="${gx}" cy="${gy + 2}" rx="30" ry="22" fill="#B8F8D8" opacity="${o.static ? 0 : 0.2}" filter="url(#sf${CU})" style="${A(o, 'cosPulse', 2)}"/><g style="transform-origin:128px 128px;${A(o, 'cosSpin', 16, 'linear infinite')}"><g stroke="${OL}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round" fill="none">${g}</g><g stroke="#FFF4E4" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" fill="none">${g}</g></g>`;
      },
    },
    frame_l_sunburst: {
      tier: 4, name: 'Genesis Sunburst', seed: 505, ref: { src: 'assets/ref_f2.png', w: 800, h: 877, cx: 338.8, cy: 446, r: 207.1, label: 'Homeland_Avatar frame_2' },
      spec: ['Rebuilt after frame_2 and SS3 Fancy: a slim tube band, one big crest on top, one ornament cluster low on the side. No ring of rays.', 'Band r 88–101: gold tube (#FFE6A8 → #F0B860) with an orange inner line #E08838 and two white gloss strokes. Maroon outline #6B2B2B.', 'Crest: a sun disc (#FFE8A0 → #F8A048, orange swirl #E07828) between two pairs of blade wings (#FFC870 → #F07828, light line #FFE0A0), as on the SS3 top ornament.', 'A gold scroll cuff at 8 o’clock (swirls #E07828) and a hanging orange star at 3 o’clock; teal-rimmed sparkles.', 'anim/glow.png: sun-disc glow #FFF0C0, opacity 0.2→0.85, 2.4 s ease-in-out. anim/sparkles.png: 3 sparkles twinkle 1.6 s. Reduce flashing: glow 0.35→0.5, twinkle by opacity only.'],
      base() {
        const r = rng(this.seed); let s = '';
        s += bandA(88, 101, grad('#FFE6A8', '#F0B860', 0, 0, 1, 1), line(`M${pp(P(94.5, 150))}A94.5 94.5 0 0 1 ${pp(P(94.5, 300))}`, '#E08838', 1.6) + line(`M${pp(P(96, 196))}A96 96 0 0 1 ${pp(P(96, 232))}M${pp(P(96, 300))}A96 96 0 0 1 ${pp(P(96, 318))}`, '#FFFFFF', 3, 0.9), '#D88838', r);
        const [sx, sy] = P(103, -90);
        const blade = (ang, len, w0) => { const t = (ang * Math.PI) / 180, ux = Math.sin(t), uy = -Math.cos(t), px = -uy, py = ux, bx = sx + ux * 8, by = sy + uy * 8, tx = bx + ux * len, ty = by + uy * len; const d = `M${f(bx + px * w0)} ${f(by + py * w0)}Q${f(bx + ux * len * 0.55 + px * w0 * 1.1)} ${f(by + uy * len * 0.55 + py * w0 * 1.1)} ${f(tx)} ${f(ty)}Q${f(bx + ux * len * 0.5 - px * w0 * 0.5)} ${f(by + uy * len * 0.5 - py * w0 * 0.5)} ${f(bx - px * w0 * 0.6)} ${f(by - py * w0 * 0.6)}Z`; return paint(d, grad('#FFC870', '#F07828', 0, 1, 1, 0), { w: 3, lines: line(`M${f(bx + px * w0 * 0.3 + ux * 6)} ${f(by + py * w0 * 0.3 + uy * 6)}L${f(bx + ux * len * 0.8 + px * w0 * 0.2)} ${f(by + uy * len * 0.8 + py * w0 * 0.2)}`, '#FFE0A0', 1.8) }); };
        s += blade(-66, 44, 9) + blade(66, 44, 9) + blade(-38, 52, 10) + blade(38, 52, 10);
        s += paint(circ(sx, sy, 21), grad('#FFE8A0', '#F8A048', 0, 0, 1, 1), { w: 3.2, soft: `<path d="${circ(sx + 9, sy + 10, 14)}" fill="#F07828" opacity=".5"/>`, lines: line(`M${sx - 9} ${sy + 3}c0 -9 13 -11 15 -2c1 6 -6 8 -9 4c-2 -3 1 -5 3 -4`, '#E07828', 1.8) + line(`M${sx - 14} ${sy - 6}q4 -9 12 -11`, '#FFF8E0', 2.6) });
        const [cx, cy] = P(95, 142), ca = 142 + 90;
        const cuff = `M-16 -11L14 -14Q19 0 14 14L-16 11Q-20 0 -16 -11Z`;
        s += `<g transform="translate(${cx} ${cy}) rotate(${ca})">${paint(cuff, grad('#FFE6A8', '#F0B860', 0, 0, 1, 1), { w: 3, lines: line('M-10 -4c0 -5 7 -6 8 -1c1 3 -3 4 -4 2M2 5c0 -4 6 -5 7 -1', '#E07828', 1.5) + line('M-14 -7L12 -10', '#FFFFFF', 2, 0.8) })}${paint('M14 -14Q22 -15 23 -8Q24 0 23 8Q22 15 14 14Q19 0 14 -14Z', grad('#FFF0C8', '#F8C878'), { w: 3 })}</g>`;
        const [hx, hy] = P(101, 8);
        s += line(`M${hx} ${hy}V${f(hy + 9)}`, OL, 4.2) + star4(hx, hy + 20, 14, grad('#FFC870', '#F07828', 0, 0, 1, 1), OL, '', 0.14) + line(`M${hx} ${f(hy + 10)}V${f(hy + 28)}`, '#FFE0A0', 1.2, 0.8);
        return s;
      },
      anim(o) { const [sx, sy] = P(103, -90); return `<circle cx="${sx}" cy="${sy}" r="30" fill="#FFF0C0" opacity="${o.static ? 0 : 0.2}" filter="url(#sf${CU})" style="${A(o, 'cosPulse', 2.4)}"/>` + sparkle(...P(118, -150), 9, 'teal', A(o, 'cosTwinkle', 1.6, 'ease-in-out 0s infinite')) + sparkle(...P(118, -30), 7, 'teal', A(o, 'cosTwinkle', 1.6, 'ease-in-out .5s infinite')) + sparkle(...P(116, 60), 7, 'teal', A(o, 'cosTwinkle', 1.6, 'ease-in-out 1s infinite')); },
    },
    frame_m_eclipse: {
      tier: 5, name: 'Luna Eclipse', seed: 606, ref: { src: 'assets/ref_ss3.png', w: 800, h: 885, cx: 399.3, cy: 436.6, r: 247.8, label: 'Frame_SS3_Fancy' },
      spec: ['Rebuilt on the SS3 Fancy structure: a night band, a moon crest on top, a cream crescent sash over the lower half, and a crystal knot at 6 o’clock. No corona spikes.', 'Band r 88–101: night navy (#3A4A80 → #1E2A5A) with cream star dust and a #5A6AA8 gloss stroke. Maroon outline #6B2B2B.', 'Crest: a cream crescent moon (#FFF8EC → #F0D4B8, orange rim line #E8A060, teal gem #60D8D0) between two pairs of red-crystal wings (#FF8A98 → #C02848).', 'Sash: a cream crescent (#FFF6EA → #F0D8C0) from 4 to 8 o’clock, thickest at the bottom (r 84–114), with orange grain lines #E8A060 and teal glints.', 'Signature: a three-crystal knot at 6 o’clock. anim/moon_glow.png: glow #FFF4E4, opacity 0.2→0.85, 3 s. Special moment (Result screen, on victory): the moon turns crimson for 0.8 s. Reduced: no colour change, glow 0.35→0.5.'],
      base() {
        const r = rng(this.seed); let s = '', dots = '';
        for (let k = 0; k < 16; k++) { const q = P(90 + r() * 9, -170 + r() * 160); dots += `<circle cx="${q[0]}" cy="${q[1]}" r="${f(0.8 + r() * 0.9)}" fill="#FFF4E4"/>`; }
        s += bandA(88, 101, grad('#3A4A80', '#1E2A5A', 0, 0, 1, 1), dots + line(`M${pp(P(95, 200))}A95 95 0 0 1 ${pp(P(95, 240))}`, '#5A6AA8', 2.6), null, r);
        const o2 = [], i2 = [];
        for (let a = 18; a <= 162; a += 6) { const t = (a - 18) / 144, rr = 100 + 14 * Math.sin(Math.PI * t); o2.push(P(rr, a)); i2.push(P(84 + (a < 30 || a > 150 ? 6 : 0), a)); }
        const sash = smooth(o2.concat(i2.reverse()));
        let grain = ''; for (const [a0, a1, rr] of [[40, 80, 104], [95, 135, 106], [60, 120, 95]]) grain += `M${pp(P(rr, a0))}A${rr} ${rr} 0 0 1 ${pp(P(rr, a1))}`;
        s += paint(sash, grad('#FFF6EA', '#F0D8C0', 0, 0, 0, 1), { w: 3, lines: line(grain, '#E8A060', 1.3, 0.9) + [[48, 106], [124, 108], [150, 98]].map(([a, rr]) => { const [x, y] = P(rr, a); return `<ellipse cx="${x}" cy="${y}" rx="2" ry="3.4" transform="rotate(${a} ${x} ${y})" fill="#60D8D0"/>`; }).join('') });
        const [mx, my] = P(104, -90);
        const wing = (side, ang, h, w) => { const t = (ang * Math.PI) / 180; return `<g transform="translate(${f(mx + side * 12)} ${f(my + 10)}) rotate(${side * ang})">${crystalA(0, 0, h, w, side * 3, 2.8)}</g>`; };
        s += wing(-1, 66, 46, 15) + wing(1, 66, 46, 15) + wing(-1, 36, 58, 17) + wing(1, 36, 58, 17);
        s += `<g transform="rotate(-90 ${mx} ${my})">${moonA(mx, my, 33, 3.2, false)}</g><ellipse cx="${mx}" cy="${f(my - 24)}" rx="3" ry="5" fill="#60D8D0" stroke="#307070" stroke-width="1.2"/>`;
        const [kx, ky] = P(108, 90);
        s += `<g transform="translate(${kx} ${ky + 14})">${crystalA(-11, 0, 22, 12, -5, 3)}${crystalA(11, 0, 22, 12, 5, 3)}${crystalA(0, 4, 30, 14, 0, 3.2)}</g>`;
        return s;
      },
      anim(o) {
        const [mx, my] = P(104, -90); let s = `<circle cx="${mx}" cy="${my}" r="34" fill="#FFF4E4" opacity="${o.static ? 0 : 0.2}" filter="url(#sf${CU})" style="${A(o, 'cosPulse', 3)}"/>`;
        [[-150, 0, 9], [-30, 0.5, 8], [178, 1, 7], [2, 1.3, 7]].forEach(([a, d, rr]) => (s += sparkle(...P(117, a), rr, 'teal', A(o, 'cosTwinkle', 1.6, `ease-in-out ${d}s infinite`))));
        return s;
      },
    },
  };
  function frameSVG(id, o = {}) {
    const d = FRAME[id], size = o.size || 256, u = ++uid; CU = u; DEFS = []; WK = 1.3;
    const R = d.ref, rs = R ? 86 / R.r : 1;
    const [defs, body] = o.ref && R ? [softDefs(u, 1), '@@AV@@' + `<image href="${R.src}" x="${f(128 - R.cx * rs)}" y="${f(128 - R.cy * rs)}" width="${f(R.w * rs)}" height="${f(R.h * rs)}"/>`] : wrapDefs(u, 1, () => (d.behind ? d.behind(o) : '') + '@@AV@@' + d.base(o) + (d.anim ? d.anim(o) : ''));
    const av = o.avatar ? `<circle cx="128" cy="128" r="84" fill="#00B8FF"/><text x="128" y="132" text-anchor="middle" dominant-baseline="central" font-family="'Baloo 2',cursive" font-weight="800" font-size="84" fill="${INK}">L</text>` : '';
    const win = o.window ? '<circle cx="128" cy="128" r="84" fill="none" stroke="#FF3D6E" stroke-width="1.5" stroke-dasharray="4 4"/>' : '';
    WK = 1;
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="${size}" height="${size}" style="display:block;overflow:visible"><defs>${defs}</defs>${body.replace('@@AV@@', av)}${win}</svg>`;
  }


  PAL.IC = { b: '#F0F4FF', m: '#9AA8DC', d: '#6B2B2B', c: '#FFFFFF', p: '#E0E8F8' };
  PAL.LU = { b: '#FF8A98', m: '#C02848', d: '#6B2B2B', c: '#FFE4EA', p: '#FFC0C8' };
  // ---------- FX ----------
  const FX = {
    fx_c_dust: { tier: 0, name: 'Dust Devil', die: 'die_c_reed', spec: ['Trail: cartoon dust clouds (3-lobe puffs, sand #F7DE9A, shade #D99A2B, 2.5 px black ring) pop in behind the die every 60 ms (scale 0→1→0.7, 0.35 s), plus 2 speed streaks per bounce arc.', 'Impact: a cloud pair bursts left and right along the felt and a sand ring spreads flat on the felt (ground ellipse r 30→90, 0.4 s).', 'Settle (signature): a flat sand shockwave ring rolls out on the felt and two big clouds pop at the die’s feet. 8 bits [face type, sand].', 'Peak ≈ 22 / die. No luminance pulses, so the reduced variant is identical.'] },
    fx_u_ember: { tier: 1, name: 'Campfire Crown', die: 'die_u_moss', spec: ['Trail: a ribbon of flame tongues (teardrops, #FF6A2B outer / #FFD23F core, black ring) shed every 35 ms that shrink and lift, plus embers.', 'Impact: a flame flower (5 tongues fanned up from the felt) and 6 embers on gravity.', 'Settle (signature): a crown of 7 flame tongues flickers around the die’s base for 0.35 s (12 fps flicker, 3 shapes), then pops into embers. 8 bits [face type, #FFB23F]. Tongues sit at x ≥ ±62, so the face stays clear.', 'Peak ≈ 30 / die. Reduced: identical (flicker is shape-only, no brightness change).'] },
    fx_r_frost: { tier: 2, name: 'Glacier Bloom', die: 'die_r_aqua', spec: ['Trail: snowflakes and ice glints drift off the die.', 'Impact: 3 ice spikes erupt from the felt (Ice ramp, two-face toon), hold 0.3 s, then shatter into shards. A small snow cloud puffs.', 'Settle (signature): a ring of 6 ice spikes bursts out of the felt around the die (ground ellipse r 95), holds 0.35 s, then shatters outward. A frost ring spreads flat on the felt.', 'Spikes stay at |x| ≥ 70 from the die centre, so the face is never covered.', 'Peak ≈ 34 / die. Reduced: identical.'] },
    fx_e_rune: { tier: 3, name: 'Summoning Circle', die: 'die_e_rune', spec: ['Trail: spore wisps #BF6BFF (35 % halo) and floating rune glyphs.', 'Impact: a small rune ring flashes flat on the felt (ellipse r 40, 0.3 s).', 'Settle (signature): a magic circle draws itself on the felt under the die (outer ring sweeps 0→360° in 0.25 s, 6 runes pop in sequence, rotates 30°). A violet light pillar rises behind the die (35 %) and runes float up its edges. 0.9 s total.', 'Reduced: pillar 15 %, halos 50 %, the circle does not pulse.'] },
    fx_l_sunfire: { tier: 4, name: 'Genesis Crest', die: 'die_l_gold', spec: ['Trail: comet ribbon from the last 14 die positions (maroon 22 px, #F8A048 16 px, #FFC870 8 px core, tapered) plus gold sparkles.','Impact: a flat gold ring spreads on the felt (r 30→90) and two small orange-rimmed stars hop out.','Settle (signature, matches frame_l_sunburst): the frame crest rises behind the die. A sun disc (#FFE8A0 → #F8A048, swirl #E07828) with two pairs of blade wings (#F07828 → #FFC870) that flex 6 %. Four big orange-rimmed stars blink around it. 0.9 s. 10 bits [face type, #FFC870]; gold tint 0.25 for 0.2 s.','Reduce flashing: no tint, stars blink by scale only.','Peak ≈ 30 / die.'] },
    fx_m_lunar: { tier: 5, name: 'Luna Crest', die: 'die_m_redcrystal', spec: ['Rebuilt as the Mythic signature. No ice spikes, no shatter, nothing shared with Glacier Bloom. All Mythic layers run at full 60 fps; every lower tier animates on twos (12 fps), so the motion itself reads as premium.', 'Trail: a 4-layer crimson-gold ribbon (maroon 26 px, #7A1030 20, #FF3D6E 13, #FFD76A 5 core) + two afterimages of the die (32 % / 18 %) + tumbling gold crescents and crimson-rimmed star dust.', 'Impact: a flat crimson/gold double ring on the felt and 3 gold stars hop out.', 'Settle (every roll): a celestial dial opens behind the die (crimson ring r 96, gold ring r 84, 12 ticks, 3 gems, 4 crescents, rotating), a gold constellation draws itself on both sides (6 stars, |x| ≥ 96 from centre), and a light sheen crosses the die face once (0.32 s).', 'MAX (blood-moon eclipse, 1.9 s): the tray falls to night (60 % dim + 26 twinkling stars), a crimson moon rises behind the die with slow god rays, a plum shadow slides across it until only a gold corona is left, a diamond-ring sparkle pops on the rim, 6 gold crescents orbit the die and a shooting star crosses the tray.', 'Reduce flashing: 30 % dim, rays and corona glow at half, sheen at 50 %, no diamond-ring blink.', 'Peak ≈ 36 / die on MAX (each big layer is one particle).'] },
  };

  Object.assign(FX, {
    fx_c_leaf: { tier: 0, name: 'Leaf Tumble', die: 'die_c_sunwood', spec: ['Trail: one leaf every 70 ms (sizes 8–11, #9AD860 / #F0C040 / #E88A30, maroon ring) drifts down and flips (scale-Y flutter).', 'Impact: 4 leaves pop up and flutter down on light gravity; a flat green ring spreads on the felt.', 'Settle (signature): 8 leaves burst from an arc 80 px above the die and drift outward; a wide green felt ring (r 50→170). 8 bits [face type, leaf green], spawned first.', 'Peak ≤ 40 / die (hard cap). The face-type bits spawn first in the settle, so a full budget never drops them. No luminance change, so the reduced variant is identical.'] },
    fx_c_pebble: { tier: 0, name: 'Skipping Stones', die: 'die_c_clay', spec: ['Trail: a pebble (#C8BCA8 / #A89880 / #D8CCB4, maroon ring, cream glint) drops off the die every 90 ms.', 'Impact: 3 pebbles skip along the felt (each bounces at 50 % energy) and a small sand cloud puffs.', 'Settle (signature): 6 pebbles skip outward from |x| 60–80 and 2 sand clouds pop at the die’s feet; flat sand ring on the felt. 8 bits [face type, stone], spawned first.', 'Peak ≈ 24 / die. Reduced: identical.'] },
    fx_u_petal: { tier: 1, name: 'Petal Waltz', die: 'die_u_berry', spec: ['Trail: pink petals (#FFB0CC / #FF8AB0 / #FFE0EA) shed every 40 ms on a sine sway, flipping as they fall.', 'Impact: a fan of 6 petals opens upward from the felt.', 'Settle (signature): 12 petals appear on a ring (r 85 × 70) around the die and spin away tangentially like a waltz; a flat pink felt ring. 8 bits [face type, petal], spawned first.', 'Peak ≤ 40 / die (hard cap). The face-type bits spawn first in the settle, so a full budget never drops them. Reduced: identical.'] },
    fx_u_splash: { tier: 1, name: 'Puddle Jump', die: 'die_u_bark', spec: ['Trail: water drops (#7ADCFF / #3AB4F0 / #D8F6FF, teardrop pointing back along the motion) flick off every 50 ms and fall.', 'Impact: a 6-drop crown splash and a flat blue ring.', 'Settle (signature): two crown splashes rise at x ±64–96 (10 drops, up to 380 px/s) and two ripple rings spread on the felt (blue r 60→190, white r 40→130). 8 bits [face type, water], spawned first.', 'Peak ≤ 40 / die (hard cap). The face-type bits spawn first in the settle, so a full budget never drops them. Reduced: identical.'] },
    fx_r_bubble: { tier: 2, name: 'Bubble Stream', die: 'die_r_aqua', spec: ['Trail: bubbles rise and wobble off the die every 40 ms (grow 5→12, rim #7ADCFF on maroon, fill 28 %, white catch-light).', 'Impact: 5 bubbles float up from the felt.', 'Settle (signature): one big bubble swells behind the die (r 40→80) and pops into 6 droplet lines; 10 bubbles rise in two columns at |x| 66–110. 8 bits [face type, bubble], spawned first.', 'Peak ≤ 40 / die (hard cap). The face-type bits spawn first in the settle, so a full budget never drops them. Reduced: identical (no brightness change).'] },
    fx_r_spark: { tier: 2, name: 'Static Snap', die: 'die_r_beast', spec: ['Trail: short zig-zag bolts (maroon 7 px, #FFE84A 3.6 px, white 1.2 px core) crackle behind the die every 60 ms + yellow sparks.', 'Impact: 3 bolts run flat along the felt; yellow ring.', 'Settle (signature): 6 bolts snap outward from r 72 to r 120–150 around the die, re-jagged at 24 fps for 0.35 s, plus 6 sparks. 6 bits [face type, #FFE84A], spawned first.', 'Reduced: bolts keep one fixed shape (no re-jag), so nothing flickers.', 'Peak ≈ 28 / die.'] },
    fx_e_spore: { tier: 3, name: 'Glowshroom Bloom', die: 'die_e_spore', spec: ['Trail: mint (#5AE0C0) and violet (#BF6BFF) spore wisps with 35 % halos.', 'Impact: two small toadstools pop up on the felt at x ±36 and sink.', 'Settle (signature): 5 glowing toadstools sprout around the die (|x| 86–152, ease-out-back 0.16 s, 0.05 s stagger), mint halos behind each; 10 spores rise from them. 0.9 s. 8 bits [face type, mint], spawned first.', 'Reduced: halos at 50 %.', 'Peak ≈ 30 / die.'] },
    fx_l_starfall: { tier: 4, name: 'Royal Starfall', die: 'die_l_kingdom', spec: ['Trail: a 3-layer navy-gold comet ribbon (maroon 22 px, #3A58C8 15 px, #FFE48A 7 px) + gold stars with navy rims + white streaks.', 'Impact: a gold felt ring and two hopping stars.', 'Settle (signature): 5 shooting stars dive in from the upper right (0.3 s each, 0.07 s stagger), land around the die (never within 52 px of the face) and stay as twinkling gold stars; gold felt ring; gold tint 0.15 for 0.2 s. 10 bits [face type, gold], spawned first.', 'Reduce flashing: no tint, landed stars do not blink.', 'Peak ≈ 30 / die.'] },
  });
  { const ORD = ['fx_c_dust', 'fx_c_leaf', 'fx_c_pebble', 'fx_u_petal', 'fx_u_splash', 'fx_u_ember', 'fx_r_frost', 'fx_r_bubble', 'fx_r_spark', 'fx_e_rune', 'fx_e_spore', 'fx_l_sunfire', 'fx_l_starfall', 'fx_m_lunar']; const tmp = Object.assign({}, FX); ORD.forEach((k) => { delete FX[k]; FX[k] = tmp[k]; }); }

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
    const SAND = ['#FFF0D0', '#F8C070'], FIRE = ['#F07828', '#F8A048', '#FFC870'];
    const groundSpikes = (cx, n, rad, T, h0, h1, ang0) => { for (let i = 0; i < n; i++) { const a = ang0 + (i / n) * Math.PI * 2 + rnd(-0.15, 0.15), gx = cx + Math.cos(a) * rad, gy = FLOOR + Math.sin(a) * rad * 0.26; if (Math.abs(gx - cx) < 70) continue; add({ shape: 'spike', x: gx, y: gy, h: rnd(h0, h1), w: rnd(14, 20), lean: rnd(-6, 6) + (gx - cx) * 0.08, life: 0.55, pal: T, front: gy > FLOOR ? 1 : 0, shatter: 1 }); } };
    const FXDEF = {
      fx_c_dust: {
        trail(d, every) { if (every(0.06)) add({ shape: 'cloud', x: d.x - 40 + rnd(-6, 6), y: d.y + 30 + rnd(-6, 6), vx: -30, vy: -10, life: 0.38, s0: 0, s1: 14, col: SAND[0], sh: SAND[1] }); if (Math.random() < 0.08) add({ shape: 'streak', x: d.x - 60, y: d.y + rnd(-40, 40), vx: -60, life: 0.22, len: rnd(30, 50), col: '#FFF4E4' }); },
        impact(x, y, k) { [-1, 1].forEach((s) => add({ shape: 'cloud', x: x + s * 34, y: y - 10, vx: s * 140 * k, vy: -30 * k, drag: 3, life: 0.5, s0: 6, s1: 18 * (0.6 + k * 0.5), col: SAND[0], sh: SAND[1] })); add({ shape: 'gring', x, y, r0: 30, r1: 90 * (0.5 + k * 0.5), life: 0.4, col: '#FFE8B8' }); for (let i = 0; i < 3; i++) add({ shape: 'dia', x, y: y - 4, vx: rnd(-120, 120), vy: -rnd(120, 220) * k, g: 800, life: 0.45, s0: 6, s1: 4, col: '#E09050' }); },
        settle(d, fc) { add({ shape: 'gring', x: d.x, y: FLOOR, r0: 60, r1: 200, life: 0.6, col: '#FFE8B8', w: 7 }); [-1, 1].forEach((s) => add({ shape: 'cloud', x: d.x + s * 74, y: FLOOR - 14, vx: s * 70, vy: -16, drag: 2, life: 0.55, s0: 8, s1: 24, col: SAND[0], sh: SAND[1], front: 1 })); tw(d.x, d.y, 'dia', [fc, '#FFE8B8'], 8, 110, 150, 0.4, 13); },
      },
      fx_u_ember: {
        trail(d, every) { if (every(0.035)) add({ shape: 'flame', x: d.x - 26 + rnd(-6, 6), y: d.y + rnd(-14, 24), vx: -rnd(40, 80), vy: -rnd(30, 70), life: 0.36, s0: rnd(14, 20), s1: 4, col: '#F07828', core: '#FFD890' }); if (Math.random() < 0.3) add({ shape: 'dia', x: d.x - 30, y: d.y + rnd(-20, 20), vx: -rnd(20, 60), vy: -rnd(60, 120), life: 0.5, s0: 6, s1: 2, col: pick(FIRE) }); },
        impact(x, y, k) { for (let i = 0; i < 5; i++) { const a = -Math.PI / 2 + (i - 2) * 0.42; add({ shape: 'flame', x: x + Math.cos(a) * 14, y: y - 4, vx: Math.cos(a) * 90 * k, vy: Math.sin(a) * 150 * k, drag: 4, life: 0.34, s0: 22 * (0.6 + k * 0.4), s1: 4, col: '#F07828', core: '#FFD890', rotFix: a + Math.PI / 2 }); } for (let i = 0; i < 6; i++) add({ shape: 'dia', x, y: y - 6, vx: rnd(-110, 110), vy: -rnd(200, 320) * k, g: 650, life: 0.55, s0: 7, s1: 3, col: pick(FIRE) }); },
        settle(d, fc) { for (let i = 0; i < 7; i++) { const a = Math.PI + (i / 6) * Math.PI, side = Math.cos(a), gx = d.x + side * rnd(62, 84); add({ shape: 'flame', x: gx, y: FLOOR - 4 - Math.abs(Math.sin(a)) * 4, life: 0.42, s0: 30 + Math.abs(side) * 10, s1: 26, col: '#F07828', core: '#FFD890', flick: 1, front: 1, rotFix: side * 0.25, popTo: 1 }); } tw(d.x, d.y, 'dia', [fc, '#F8A048'], 8, 110, 150, 0.4, 13); },
      },
      fx_r_frost: {
        trail(d, every) { if (every(0.05)) add({ shape: 'flake', x: d.x - 34 + rnd(-8, 8), y: d.y + rnd(-24, 30), vx: -rnd(10, 40), vy: rnd(-10, 25), life: 0.6, s0: 8, s1: 5, col: '#FFFFFF', vr: rnd(-2, 2) }); if (Math.random() < 0.25) add({ shape: 'star', x: d.x - 20 + rnd(-20, 20), y: d.y + rnd(-40, 40), vx: -20, life: 0.35, s0: 7, s1: 2, col: '#E0E8F8' }); },
        impact(x, y, k) { if (k > 0.5) groundSpikes(x, 3, 34, PAL.IC, 26 * k, 40 * k, -Math.PI / 2); add({ shape: 'cloud', x: x, y: y - 8, vx: 0, vy: -20, life: 0.4, s0: 6, s1: 16, col: '#FFFFFF', sh: '#C8D4F0' }); },
        settle(d, fc) { groundSpikes(d.x, 6, 95, PAL.IC, 34, 54, 0.3); add({ shape: 'gring', x: d.x, y: FLOOR, r0: 50, r1: 150, life: 0.5, col: '#E0E8F8', w: 6 }); tw(d.x, d.y, 'shard', ['#C8D8F8', fc], 8, 115, 150, 0.4, 16); },
      },
      fx_e_rune: {
        trail(d, every) { if (every(0.04)) add({ shape: 'wisp', x: d.x - 30 + rnd(-10, 10), y: d.y + rnd(-25, 25), vx: -rnd(20, 50), vy: -rnd(5, 30), life: 0.5, s0: 5, s1: 2, col: '#B080E0' }); if (Math.random() < 0.12) add({ shape: 'glyph', x: d.x - 40, y: d.y + rnd(-30, 30), vx: -30, vy: -30, life: 0.5, s0: 12, s1: 12, k: (Math.random() * 6) | 0 }); },
        impact(x, y, k) { add({ shape: 'circle', x, y: FLOOR, R: 40 * (0.6 + k * 0.5), life: 0.3, mini: 1 }); },
        settle(d, fc) { add({ shape: 'circle', x: d.x, y: FLOOR, R: 130, life: 0.95 }); add({ shape: 'pillar', x: d.x, y: FLOOR, life: 0.9 }); for (let i = 0; i < 6; i++) add({ shape: 'glyph', x: d.x + (i % 2 ? 1 : -1) * rnd(72, 110), y: FLOOR - rnd(0, 20), vx: 0, vy: -rnd(70, 120), life: rnd(0.7, 0.9), s0: 14, s1: 10, k: i, delay: i * 0.05, front: 1 }); tw(d.x, d.y, 'dia', [fc, '#FFF4E4'], 8, 110, 150, 0.4, 13); },
      },
      fx_l_sunfire: {
        comet: true,
        trail(d, every) { if (every(0.03)) add({ shape: 'star', x: d.x - 20 + rnd(-14, 14), y: d.y + rnd(-20, 20), vx: -rnd(30, 70), vy: rnd(-30, 30), life: 0.45, s0: 8, s1: 2, col: '#FFD890' }); if (Math.random() < 0.18) add({ shape: 'streak', x: d.x - 70, y: d.y + rnd(-44, 44), vx: -80, life: 0.2, len: rnd(40, 70), col: '#FFE8B8' }); },
        impact(x, y, k) { add({ shape: 'gring', x, y: FLOOR, r0: 30, r1: 90 * (0.5 + k * 0.5), life: 0.4, col: '#FFC870', w: 6 }); for (let i = 0; i < 2; i++) add({ shape: 'star', x: x + (i ? 40 : -40), y: y - 20, vx: (i ? 1 : -1) * 60, vy: -120 * k, g: 300, life: 0.4, s0: 10, s1: 4, col: '#FFD890', rim: '#F07828' }); },
        settle(d, fc) { add({ shape: 'sun', x: d.x, y: d.y - 4, life: 0.9 }); [[-118, -40], [118, -40], [-96, 46], [96, 46]].forEach(([dx, dy], i) => add({ shape: 'star', x: d.x + dx, y: d.y + dy, life: 0.8, s0: 16 - (i > 1 ? 4 : 0), s1: 16 - (i > 1 ? 4 : 0), col: '#FFC870', rim: '#F07828', blink: 1, front: 1 })); tw(d.x, d.y, 'dia', [fc, '#FFC870'], 10, 115, 150, 0.4, 13); if (!flags.rf) tint = 0.25; },
      },
      fx_m_lunar: {
        comet: [['#000', 26], ['#7A1030', 20], ['#FF3D6E', 13], ['#FFD76A', 5]], ghost: true,
        trail(d, every) { if (every(0.05)) add({ shape: 'cres', x: d.x - 34 + rnd(-10, 10), y: d.y + rnd(-26, 26), vx: -rnd(30, 70), vy: rnd(-30, 10), life: 0.6, s0: rnd(9, 13), s1: 4, col: '#FFD76A' }); if (Math.random() < 0.4) add({ shape: 'star', x: d.x - 46 + rnd(-12, 12), y: d.y + rnd(-34, 34), vx: -20, life: 0.5, s0: 7, s1: 2, col: '#FFF4E4', rim: '#FF3D6E' }); },
        impact(x, y, k) { add({ shape: 'gcres', x, y: FLOOR, r0: 24, r1: 100 * (0.5 + k * 0.5), life: 0.45 }); for (let i = 0; i < 3; i++) add({ shape: 'star', x: x + rnd(-30, 30), y: y - 10, vx: rnd(-120, 120), vy: -rnd(140, 240) * k, g: 600, life: 0.5, s0: 10, s1: 5, col: '#FFD76A', rim: '#C02848' }); },
        settle(d, fc, max) {
          const L = max ? 1.9 : 1.05;
          if (max) { dim = flags.rf ? 0.3 : 0.6; add({ shape: 'night', x: 0, y: 0, life: L, sf: Array.from({ length: 26 }, () => [rnd(40, 820), rnd(36, 236), rnd(2.5, 5.5), rnd(0, 6)]) }); add({ shape: 'bloodmoon', x: d.x, y: d.y - 20, life: L }); }
          add({ shape: 'dial', x: d.x, y: d.y, life: L });
          add({ shape: 'constel', x: d.x, y: d.y, life: L, front: 1, pts: [[-104, 44], [-150, -26], [-112, -80], [100, -84], [150, -20], [110, 46]] });
          add({ shape: 'sheen', x: d.x, y: d.y, life: 0.4, delay: 0.08, front: 1 });
          tw(d.x, d.y, 'cres', ['#FFD76A', '#FF8A98'], 6, 120, 160, 0.45, 15);
          if (max) { for (let i = 0; i < 6; i++) add({ shape: 'orbitc', x: d.x, y: d.y, ang: (i / 6) * Math.PI * 2, life: L, s0: 14, s1: 14, front: 1 }); add({ shape: 'shoot', x: 0, y: 0, life: 1.4, delay: 0.75, front: 1 }); }
        },
      },
    };

    const LEAF = ['#9AD860', '#F0C040', '#E88A30'], PEB = ['#C8BCA8', '#A89880', '#D8CCB4'], PET = ['#FFB0CC', '#FF8AB0', '#FFE0EA'], WAT = ['#7ADCFF', '#3AB4F0', '#D8F6FF'];
    Object.assign(FXDEF, {
      fx_c_leaf: {
        trail(d, every) { if (every(0.07)) add({ shape: 'leaf', x: d.x - 30 + rnd(-8, 8), y: d.y + rnd(-20, 20), vx: -rnd(30, 60), vy: rnd(10, 40), life: 0.5, s0: rnd(8, 11), s1: 6, col: pick(LEAF), vr: rnd(-5, 5) }); },
        impact(x, y, k) { for (let i = 0; i < 4; i++) add({ shape: 'leaf', x: x + rnd(-20, 20), y: y - 8, vx: rnd(-110, 110), vy: -rnd(140, 220) * k, g: 380, drag: 1.8, life: 0.7, s0: 10, s1: 7, col: pick(LEAF), vr: rnd(-8, 8) }); add({ shape: 'gring', x, y: FLOOR, r0: 24, r1: 70 * (0.5 + k * 0.5), life: 0.35, col: '#D8F0A8' }); },
        settle(d, fc) { tw(d.x, d.y, 'leaf', [fc, '#9AD860'], 8, 110, 150, 0.4, 13); add({ shape: 'gring', x: d.x, y: FLOOR, r0: 50, r1: 170, life: 0.55, col: '#C8E890', w: 6 }); for (let i = 0; i < 8; i++) { const a = Math.PI + (i / 7) * Math.PI; add({ shape: 'leaf', x: d.x + Math.cos(a) * 84, y: d.y + Math.sin(a) * 80, vx: Math.cos(a) * 160, vy: Math.sin(a) * 120 - 40, g: 200, drag: 2, life: 0.75, s0: 12, s1: 8, col: LEAF[i % 3], vr: rnd(-9, 9), front: 1 }); } },
      },
      fx_c_pebble: {
        trail(d, every) { if (every(0.09)) add({ shape: 'pebble', x: d.x - 30, y: d.y + 20, vx: -40, vy: -60, g: 700, life: 0.5, s0: 5, s1: 5, col: pick(PEB), bounce: 1 }); },
        impact(x, y, k) { for (let i = 0; i < 3; i++) add({ shape: 'pebble', x, y: FLOOR - 6, vx: (i - 1) * 170 + rnd(-20, 20), vy: -rnd(120, 180) * k, g: 900, life: 0.55, s0: 6, s1: 6, col: pick(PEB), bounce: 1 }); add({ shape: 'cloud', x, y: y - 8, vx: 0, vy: -16, life: 0.35, s0: 4, s1: 12, col: SAND[0], sh: SAND[1] }); },
        settle(d, fc) { tw(d.x, d.y, 'dia', [fc, '#D8CCB4'], 8, 110, 150, 0.4, 13); add({ shape: 'gring', x: d.x, y: FLOOR, r0: 50, r1: 170, life: 0.55, col: '#E0D4C0', w: 6 }); for (let i = 0; i < 6; i++) { const sd = i % 2 ? 1 : -1; add({ shape: 'pebble', x: d.x + sd * rnd(60, 80), y: FLOOR - 6, vx: sd * rnd(120, 220), vy: -rnd(160, 260), g: 900, life: 0.65, s0: 8, s1: 8, col: PEB[i % 3], bounce: 1, front: 1 }); } [-1, 1].forEach((sd) => add({ shape: 'cloud', x: d.x + sd * 70, y: FLOOR - 12, vx: sd * 50, vy: -14, drag: 2, life: 0.5, s0: 6, s1: 18, col: SAND[0], sh: SAND[1], front: 1 })); },
      },
      fx_u_petal: {
        trail(d, every) { if (every(0.04)) add({ shape: 'petal', x: d.x - 28 + rnd(-8, 8), y: d.y + rnd(-24, 24), vx: -rnd(40, 80), vy: Math.sin(T * 8) * 40, life: 0.45, s0: 9, s1: 5, col: pick(PET), vr: rnd(-6, 6) }); },
        impact(x, y, k) { for (let i = 0; i < 6; i++) { const a = -Math.PI / 2 + (i - 2.5) * 0.35; add({ shape: 'petal', x, y: y - 6, vx: Math.cos(a) * 150 * k, vy: Math.sin(a) * 200 * k, g: 300, drag: 2, life: 0.6, s0: 9, s1: 6, col: PET[i % 3], vr: rnd(-6, 6) }); } },
        settle(d, fc) { tw(d.x, d.y, 'dia', [fc, '#FFB0CC'], 8, 110, 150, 0.4, 13); add({ shape: 'gring', x: d.x, y: FLOOR, r0: 50, r1: 160, life: 0.55, col: '#FFD0E0', w: 6 }); for (let i = 0; i < 12; i++) { const a = (i / 12) * Math.PI * 2; add({ shape: 'petal', x: d.x + Math.cos(a) * 85, y: d.y + Math.sin(a) * 70, vx: -Math.sin(a) * 180 + Math.cos(a) * 60, vy: Math.cos(a) * 140 + Math.sin(a) * 50, drag: 1.5, life: 0.7, s0: 12, s1: 8, col: PET[i % 3], vr: rnd(-8, 8), front: 1 }); } },
      },
      fx_u_splash: {
        trail(d, every) { if (every(0.05)) add({ shape: 'drop', x: d.x - 26, y: d.y + rnd(-10, 30), vx: -rnd(40, 90), vy: -rnd(20, 80), g: 600, life: 0.35, s0: 7, s1: 4, col: pick(WAT) }); },
        impact(x, y, k) { add({ shape: 'gring', x, y: FLOOR, r0: 24, r1: 80 * (0.5 + k * 0.5), life: 0.4, col: '#A8E8FF' }); for (let i = 0; i < 6; i++) { const a = -Math.PI / 2 + (i - 2.5) * 0.3; add({ shape: 'drop', x: x + Math.cos(a) * 30, y: FLOOR - 4, vx: Math.cos(a) * 180 * k, vy: Math.sin(a) * 260 * k, g: 900, life: 0.5, s0: 8, s1: 5, col: WAT[i % 3] }); } },
        settle(d, fc) { tw(d.x, d.y, 'dia', [fc, '#7ADCFF'], 8, 110, 150, 0.4, 13); add({ shape: 'gring', x: d.x, y: FLOOR, r0: 60, r1: 190, life: 0.6, col: '#A8E8FF', w: 7 }); add({ shape: 'gring', x: d.x, y: FLOOR, r0: 40, r1: 130, life: 0.5, col: '#FFFFFF', w: 4 }); for (let i = 0; i < 10; i++) { const sd = i < 5 ? -1 : 1, j = i % 5; add({ shape: 'drop', x: d.x + sd * (64 + j * 8), y: FLOOR - 6, vx: sd * rnd(40, 140), vy: -rnd(260, 380), g: 900, life: 0.6, s0: 10, s1: 6, col: WAT[i % 3], front: 1 }); } },
      },
      fx_r_bubble: {
        trail(d, every) { if (every(0.04)) add({ shape: 'bubble', x: d.x - 30 + rnd(-10, 10), y: d.y + rnd(-20, 30), vx: -rnd(20, 50), vy: -rnd(40, 90), life: 0.5, s0: 5, s1: rnd(8, 12), col: '#7ADCFF' }); },
        impact(x, y, k) { for (let i = 0; i < 5; i++) add({ shape: 'bubble', x: x + rnd(-30, 30), y: FLOOR - 10, vx: rnd(-40, 40), vy: -rnd(80, 160) * k, drag: 1, life: 0.6, s0: 4, s1: rnd(8, 14), col: '#7ADCFF' }); },
        settle(d, fc) { tw(d.x, d.y, 'dia', [fc, '#B8F0FF'], 8, 110, 150, 0.4, 13); add({ shape: 'bubble', x: d.x, y: d.y, life: 0.45, s0: 40, s1: 82, col: '#7ADCFF', vx: 0, vy: 0, still: 1 }); add({ shape: 'gring', x: d.x, y: FLOOR, r0: 50, r1: 150, life: 0.5, col: '#B8F0FF', w: 6 }); for (let i = 0; i < 10; i++) { const sd = i % 2 ? 1 : -1; add({ shape: 'bubble', x: d.x + sd * rnd(66, 110), y: FLOOR - rnd(0, 30), vx: sd * rnd(0, 30), vy: -rnd(90, 180), life: rnd(0.6, 0.85), s0: 6, s1: rnd(12, 20), col: '#7ADCFF', front: 1 }); } },
      },
      fx_r_spark: {
        trail(d, every) { if (every(0.06)) add({ shape: 'bolt', x: d.x - 30, y: d.y + rnd(-20, 20), ang: Math.PI + rnd(-0.6, 0.6), r0: 0, r1: rnd(30, 50), life: 0.18, segs: 4 }); if (Math.random() < 0.25) add({ shape: 'dia', x: d.x - 30, y: d.y + rnd(-20, 20), vx: -rnd(40, 90), vy: rnd(-60, 60), life: 0.3, s0: 6, s1: 2, col: '#FFE84A' }); },
        impact(x, y, k) { add({ shape: 'gring', x, y: FLOOR, r0: 24, r1: 80 * (0.5 + k * 0.5), life: 0.35, col: '#FFF2A0' }); [0, Math.PI, Math.PI * (Math.random() < 0.5 ? 0.06 : 0.94)].forEach((a) => add({ shape: 'bolt', x, y: FLOOR - 2, ang: a, r0: 8, r1: 20 + 60 * k, life: 0.22, segs: 4, sy: 0.3 })); },
        settle(d, fc) { tw(d.x, d.y, 'dia', [fc, '#FFE84A'], 6, 110, 150, 0.4, 13); for (let i = 0; i < 6; i++) { const a = (i / 6) * Math.PI * 2 + 0.3; add({ shape: 'bolt', x: d.x, y: d.y, ang: a, r0: 72, r1: rnd(120, 150), life: 0.35, segs: 5, front: 1 }); add({ shape: 'dia', x: d.x + Math.cos(a) * 76, y: d.y + Math.sin(a) * 76, vx: Math.cos(a) * 220, vy: Math.sin(a) * 220, drag: 3, life: 0.4, s0: 9, s1: 3, col: '#FFE84A', front: 1 }); } add({ shape: 'gring', x: d.x, y: FLOOR, r0: 50, r1: 160, life: 0.45, col: '#FFF2A0', w: 6 }); },
      },
      fx_e_spore: {
        trail(d, every) { if (every(0.04)) add({ shape: 'wisp', x: d.x - 30 + rnd(-10, 10), y: d.y + rnd(-25, 25), vx: -rnd(20, 50), vy: -rnd(5, 30), life: 0.5, s0: 5, s1: 2, col: Math.random() < 0.65 ? '#5AE0C0' : '#BF6BFF' }); },
        impact(x, y, k) { if (k > 0.5) [-1, 1].forEach((sd) => add({ shape: 'shroom', x: x + sd * 36, y: FLOOR, life: 0.4, s0: 14 * k, s1: 14 * k, col: sd > 0 ? '#5AE0C0' : '#C890FF' })); add({ shape: 'gring', x, y: FLOOR, r0: 24, r1: 70, life: 0.35, col: '#C8F8E8' }); },
        settle(d, fc) { tw(d.x, d.y, 'dia', [fc, '#7AF0D0'], 8, 110, 150, 0.4, 13); [[-120, -6, 26, 0], [-88, 8, 20, 1], [86, 8, 22, 1], [120, -6, 28, 0], [-152, 2, 16, 1]].forEach(([dx, dy, sz, fr], i) => add({ shape: 'shroom', x: d.x + dx, y: FLOOR + dy, life: 0.9, s0: sz, s1: sz, col: i % 2 ? '#5AE0C0' : '#C890FF', delay: i * 0.05, front: fr })); for (let i = 0; i < 10; i++) { const sd = i % 2 ? 1 : -1; add({ shape: 'wisp', x: d.x + sd * rnd(80, 140), y: FLOOR - rnd(20, 50), vx: sd * rnd(0, 20), vy: -rnd(50, 100), life: rnd(0.7, 0.9), s0: 5, s1: 2, col: i % 3 ? '#7AF0D0' : '#D8A8FF', front: 1 }); } },
      },
      fx_l_starfall: {
        comet: [['#000', 22], ['#3A58C8', 15], ['#FFE48A', 7]],
        trail(d, every) { if (every(0.03)) add({ shape: 'star', x: d.x - 20 + rnd(-14, 14), y: d.y + rnd(-20, 20), vx: -rnd(30, 70), vy: rnd(-30, 30), life: 0.45, s0: 8, s1: 2, col: '#FFE48A', rim: '#3A58C8' }); if (Math.random() < 0.18) add({ shape: 'streak', x: d.x - 70, y: d.y + rnd(-44, 44), vx: -80, life: 0.2, len: rnd(40, 70), col: '#E8EEFF' }); },
        impact(x, y, k) { add({ shape: 'gring', x, y: FLOOR, r0: 30, r1: 90 * (0.5 + k * 0.5), life: 0.4, col: '#FFE48A', w: 6 }); for (let i = 0; i < 2; i++) add({ shape: 'star', x: x + (i ? 40 : -40), y: y - 20, vx: (i ? 1 : -1) * 60, vy: -120 * k, g: 300, life: 0.4, s0: 10, s1: 4, col: '#FFE48A', rim: '#3A58C8' }); },
        settle(d, fc) { tw(d.x, d.y, 'dia', [fc, '#FFE48A'], 10, 115, 150, 0.4, 13); [[-130, -30], [-92, 42], [104, -64], [142, 18], [-20, -118]].forEach(([dx, dy], i) => add({ shape: 'fall', x: d.x + dx, y: d.y + dy, sx: 160 + rnd(-30, 30), sy: -220, life: 0.95, delay: i * 0.07, s0: 16 - (i % 2) * 3, s1: 16, front: 1 })); add({ shape: 'gring', x: d.x, y: FLOOR, r0: 60, r1: 190, life: 0.6, col: '#FFE48A', w: 6 }); if (!flags.rf) tint = 0.15; },
      },
    });
    // ---- drawing ----
    const P2 = (pts) => { ctx.beginPath(); pts.forEach((q, i) => ctx[i ? 'lineTo' : 'moveTo'](q[0], q[1])); ctx.closePath(); };
    function toonFill(path, base, shade, deep, lw, hl) { path(); ctx.lineWidth = lw; ctx.strokeStyle = deep; ctx.fillStyle = base; ctx.stroke(); ctx.fill(); if (shade) { ctx.save(); path(); ctx.clip(); ctx.translate(lw * 0.8, lw * 1.1); ctx.globalCompositeOperation = 'source-atop'; ctx.restore(); } if (hl) { ctx.fillStyle = hl.c; hl.path(); ctx.fill(); } }
    function cloud(s, col, sh, jj) { const lobes = [[-s * 0.55, s * 0.1, s * 0.5 * jj[0]], [0, -s * 0.2, s * 0.62 * jj[1]], [s * 0.55, s * 0.12, s * 0.48 * jj[2]]]; ctx.beginPath(); lobes.forEach(([x, y, r]) => { ctx.moveTo(x + r, y); ctx.arc(x, y, Math.max(r, 0.1), 0, 7); }); ctx.lineWidth = 5; ctx.strokeStyle = OL; ctx.stroke(); ctx.fillStyle = sh; ctx.fill(); ctx.beginPath(); lobes.forEach(([x, y, r]) => { ctx.moveTo(x - r * 0.12 + r * 0.82, y - r * 0.16); ctx.arc(x - r * 0.12, y - r * 0.16, Math.max(r * 0.82, 0.1), 0, 7); }); ctx.fillStyle = col; ctx.fill(); ctx.beginPath(); ctx.arc(-s * 0.12, -s * 0.42, s * 0.14, 0, 7); ctx.fillStyle = '#FFFFFF'; ctx.fill(); }
    function flameShape(s, wob) { ctx.beginPath(); ctx.moveTo(0, -s); ctx.bezierCurveTo(s * 0.18 + wob, -s * 0.5, s * 0.5, -s * 0.1, s * 0.42, s * 0.18); ctx.bezierCurveTo(s * 0.36, s * 0.5, -s * 0.36, s * 0.5, -s * 0.42, s * 0.18); ctx.bezierCurveTo(-s * 0.5, -s * 0.15, -s * 0.12 + wob, -s * 0.5, 0, -s); ctx.closePath(); }
    function crys(s, T, j) { const pts = [[s * 0.06 * j[4], -s * j[0]], [s * 0.36 * j[1], -s * 0.12], [s * 0.04, s * 0.62 * j[2]], [-s * 0.32 * j[3], s * 0.04]]; P2(pts); ctx.lineWidth = 2.6; ctx.strokeStyle = OL; ctx.stroke(); ctx.fillStyle = T.m; ctx.fill(); P2([pts[0], pts[3], pts[2], [pts[0][0] * 0.3, 0]]); ctx.fillStyle = T.b; ctx.fill(); ctx.beginPath(); ctx.moveTo(-s * 0.12, -s * 0.05); ctx.lineTo(pts[0][0] - s * 0.05, -s * 0.72); ctx.strokeStyle = T.c; ctx.lineWidth = 1.6; ctx.stroke(); }
    function cresPath(R, dx, R2) { const ix = (R * R - R2 * R2 + dx * dx) / (2 * dx), iy = Math.sqrt(Math.max(R * R - ix * ix, 0)), t1 = Math.atan2(iy, ix), t2 = Math.atan2(iy, ix - dx); ctx.beginPath(); ctx.arc(0, 0, R, t1, Math.PI * 2 - t1, false); ctx.arc(dx, 0, R2, -t2, t2, true); ctx.closePath(); }
    function cres(s, col, lw) { cresPath(s, s * 0.5, s * 0.84); ctx.lineWidth = lw || 2.6; ctx.strokeStyle = OL; ctx.stroke(); ctx.fillStyle = col; ctx.fill(); ctx.beginPath(); ctx.arc(0, 0, s * 0.72, Math.PI * 0.72, Math.PI * 1.1); ctx.strokeStyle = '#FFF8E0'; ctx.lineWidth = Math.max(1.2, s * 0.12); ctx.stroke(); }
    function star4(r, col, rim) { ctx.beginPath(); ctx.moveTo(0, -r); ctx.quadraticCurveTo(r * 0.12, -r * 0.12, r * 0.8, 0); ctx.quadraticCurveTo(r * 0.12, r * 0.12, 0, r * 0.85); ctx.quadraticCurveTo(-r * 0.12, r * 0.12, -r * 0.75, 0); ctx.quadraticCurveTo(-r * 0.12, -r * 0.12, 0, -r); ctx.lineWidth = Math.max(1.6, r * 0.32); ctx.strokeStyle = rim; ctx.fillStyle = col; ctx.stroke(); ctx.fill(); }
    function drawShape(p, a) {
      const u = Math.min(p.age / p.life, 1), s = p.s0 + (p.s1 - p.s0) * u, rf = flags.rf ? 0.5 : 1, eo = 1 - Math.pow(1 - u, 2);
      if (a <= 0) return;
      ctx.save(); ctx.globalAlpha = a; ctx.translate(p.x, p.y); ctx.lineJoin = 'round'; ctx.lineCap = 'round';
      const fs = (path, col) => { ctx.fillStyle = col || p.col; ctx.strokeStyle = OL; ctx.lineWidth = p.lw; path(); ctx.fill(); ctx.stroke(); };
      switch (p.shape) {
        case 'dia': { ctx.rotate(p.rot); const j = p.jj, h = s * 0.62; fs(() => P2([[0, -h * j[0]], [h * j[1], 0], [0, h * j[2]], [-h * j[3], 0]])); if (s > 6) { ctx.beginPath(); ctx.moveTo(-s * 0.2, -s * 0.06); ctx.lineTo(0, -s * 0.34); ctx.strokeStyle = 'rgba(255,255,255,.8)'; ctx.lineWidth = 1.5; ctx.stroke(); } break; }
        case 'shard': ctx.rotate(p.rot); crys(s, { b: p.col, m: p.col === '#C8D8F8' ? '#8898D0' : 'rgba(0,0,0,.25)', c: '#FFFFFF' }, p.jj); break;
        case 'crys': ctx.rotate(p.rot); crys(s, p.pal, p.jj); break;
        case 'cloud': { const k = u < 0.35 ? 1 - Math.pow(1 - u / 0.35, 3) : 1 - (u - 0.35) * 0.4; const sz = p.s1 * k; if (sz > 0.5) cloud(sz, p.col, p.sh, p.jj); break; }
        case 'streak': ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(p.len * (1 - u * 0.5), 0); ctx.strokeStyle = p.col; ctx.globalAlpha = a * 0.7; ctx.lineWidth = 3; ctx.stroke(); break;
        case 'star': { const sc = p.blink ? Math.abs(Math.sin(p.age * 9 + p.seed * 6)) : 1; const r = s * (0.4 + 0.6 * sc); ctx.rotate(0.1); ctx.lineWidth = Math.max(1.6, r * 0.32); ctx.strokeStyle = p.rim || '#5AB0B0'; ctx.fillStyle = p.col; (() => { ctx.beginPath(); ctx.moveTo(0, -r); ctx.quadraticCurveTo(r * 0.12, -r * 0.12, r * 0.8, 0); ctx.quadraticCurveTo(r * 0.12, r * 0.12, 0, r * 0.85); ctx.quadraticCurveTo(-r * 0.12, r * 0.12, -r * 0.75, 0); ctx.quadraticCurveTo(-r * 0.12, -r * 0.12, 0, -r); })(); ctx.stroke(); ctx.fill(); break; }
        case 'flake': ctx.rotate(p.rot); ctx.beginPath(); for (let k = 0; k < 3; k++) { const g = (k * Math.PI) / 3; ctx.moveTo(Math.cos(g) * s, Math.sin(g) * s); ctx.lineTo(-Math.cos(g) * s, -Math.sin(g) * s); } ctx.strokeStyle = OL; ctx.lineWidth = 5; ctx.stroke(); ctx.strokeStyle = p.col; ctx.lineWidth = 2; ctx.stroke(); break;
        case 'wisp': ctx.globalAlpha = a * 0.35 * rf; ctx.fillStyle = p.col; ctx.beginPath(); ctx.arc(0, 0, s * 2, 0, 7); ctx.fill(); ctx.globalAlpha = a; fs(() => { ctx.beginPath(); ctx.arc(0, 0, s, 0, 7); }); break;
        case 'glyph': { if (p.age < (p.delay || 0)) break; ctx.scale(s / 12, s / 12); ctx.translate(-5, -6); ctx.globalAlpha = a * rf * 0.6; ctx.strokeStyle = '#B080E0'; ctx.lineWidth = 5; ctx.stroke(new Path2D(RUNES[p.k % 6])); ctx.globalAlpha = a; ctx.strokeStyle = OL; ctx.lineWidth = 3.6; ctx.stroke(new Path2D(RUNES[p.k % 6])); ctx.strokeStyle = '#FFF4E4'; ctx.lineWidth = 1.6; ctx.stroke(new Path2D(RUNES[p.k % 6])); break; }
        case 'flame': { const fl = p.flick ? [1, 0.82, 1.1][Math.floor(p.age * 12 + p.seed * 3) % 3] : 1, sz = (p.popTo && u > 0.8 ? s * (1 - (u - 0.8) * 5) : s) * fl; if (sz <= 0.5) break; ctx.rotate(p.rotFix != null ? p.rotFix : Math.atan2(p.vy, p.vx) + Math.PI / 2 + Math.PI); const wob = p.flick ? (Math.floor(p.age * 12) % 2 ? 2 : -2) : 0; flameShape(sz, wob); ctx.lineWidth = 3; ctx.strokeStyle = OL; ctx.stroke(); ctx.fillStyle = p.col; ctx.fill(); ctx.save(); ctx.translate(0, sz * 0.16); flameShape(sz * 0.55, -wob); ctx.fillStyle = p.core; ctx.fill(); ctx.restore(); ctx.beginPath(); ctx.ellipse(-sz * 0.14, -sz * 0.05, sz * 0.06, sz * 0.14, 0.3, 0, 7); ctx.fillStyle = '#FFF6D0'; ctx.fill(); break; }
        case 'spike': {
          const grow = Math.min(p.age / 0.1, 1), e = 1 - Math.pow(1 - grow, 3), hh = p.h * e * (1 + 0.15 * Math.sin(Math.min(p.age / 0.18, 1) * Math.PI)), w = p.w, T = p.pal;
          if (u > 0.85) { ctx.globalAlpha = a * (1 - (u - 0.85) / 0.15); }
          const bl = [-w / 2, 0], br = [w / 2, 0], tp = [p.lean, -hh], md = [p.lean * 0.4 + w * 0.05, -hh * 0.4];
          P2([bl, tp, br]); ctx.lineWidth = 3.4; ctx.strokeStyle = OL; ctx.stroke(); ctx.fillStyle = T.m; ctx.fill();
          P2([bl, tp, md, [w * 0.05, 0]]); ctx.fillStyle = T.b; ctx.fill();
          ctx.beginPath(); ctx.moveTo(-w * 0.22, -hh * 0.12); ctx.lineTo(p.lean - w * 0.05, -hh * 0.8); ctx.strokeStyle = T.c; ctx.lineWidth = 2; ctx.stroke();
          ctx.beginPath(); ctx.ellipse(0, 1, w * 0.75, 3.5, 0, 0, 7); ctx.fillStyle = 'rgba(0,0,0,.25)'; ctx.fill();
          break; }
        case 'gring': { const r = p.r0 + (p.r1 - p.r0) * eo; ctx.scale(1, 0.26); ctx.globalAlpha = a * (1 - eo); ctx.beginPath(); ctx.arc(0, 0, r, 0, 7); ctx.strokeStyle = OL; ctx.lineWidth = (p.w || 5) + 6; ctx.stroke(); ctx.strokeStyle = p.col; ctx.lineWidth = p.w || 5; ctx.stroke(); break; }
        case 'ring': { const r = p.r0 + (p.r1 - p.r0) * eo; ctx.globalAlpha = a * (1 - eo); ctx.beginPath(); ctx.ellipse(0, 0, r, r * 0.85, 0, 0, 7); ctx.strokeStyle = OL; ctx.lineWidth = 9; ctx.stroke(); ctx.strokeStyle = p.col; ctx.lineWidth = 5; ctx.stroke(); break; }
        case 'ray': { if (p.age < (p.delay || 0)) break; const v = Math.min((p.age - (p.delay || 0)) / Math.max(p.life - (p.delay || 0), 0.01), 1), ev = 1 - Math.pow(1 - v, 2), r1 = p.r0 + (p.r1 - p.r0) * ev, r0 = p.r0 + (p.r1 - p.r0) * Math.max(ev - 0.35, 0); ctx.globalAlpha = (p.glow ? rf : 1) * (1 - v * v); ctx.beginPath(); ctx.moveTo(Math.cos(p.ang) * r0, Math.sin(p.ang) * r0 * 0.85); ctx.lineTo(Math.cos(p.ang) * r1, Math.sin(p.ang) * r1 * 0.85); ctx.strokeStyle = OL; ctx.lineWidth = 10; ctx.stroke(); ctx.strokeStyle = p.col; ctx.lineWidth = 5; ctx.stroke(); break; }
        case 'burst': { const k = 1 - Math.pow(1 - Math.min(u / 0.4, 1), 3); ctx.scale(1, 0.38); ctx.globalAlpha = 1 - Math.max(0, (u - 0.5) / 0.5); const R = p.R * k, pts = []; for (let i = 0; i < 20; i++) { const g = (i / 20) * Math.PI * 2, rr = i % 2 ? R * 0.55 : R * p.jj[i % 7]; pts.push([Math.cos(g) * rr, Math.sin(g) * rr]); } P2(pts); ctx.lineWidth = 8; ctx.strokeStyle = OL; ctx.stroke(); ctx.fillStyle = '#FFC93C'; ctx.fill(); P2(pts.map((q) => [q[0] * 0.55, q[1] * 0.55])); ctx.fillStyle = '#FFFCEB'; ctx.fill(); break; }
        case 'circle': {
          const R = p.R, sweep = Math.min(p.age / (p.mini ? 0.12 : 0.25), 1), fade = u > 0.7 ? 1 - (u - 0.7) / 0.3 : 1; ctx.scale(1, 0.28); ctx.rotate(p.age * 0.6); ctx.globalAlpha = fade;
          const arc = (r, w, c) => { ctx.beginPath(); ctx.arc(0, 0, r, -Math.PI / 2, -Math.PI / 2 + sweep * Math.PI * 2); ctx.strokeStyle = OL; ctx.lineWidth = w + 6; ctx.stroke(); ctx.strokeStyle = c; ctx.lineWidth = w; ctx.stroke(); };
          ctx.globalAlpha = fade * 0.3 * rf; ctx.beginPath(); ctx.arc(0, 0, R, 0, 7); ctx.fillStyle = '#B080E0'; ctx.fill(); ctx.globalAlpha = fade;
          arc(R, 6, '#B080E0'); arc(R * 0.78, 3.5, '#D8C4F4');
          if (!p.mini) { for (let i = 0; i < 6; i++) { if (p.age < 0.08 + i * 0.04) continue; const g = (i / 6) * Math.PI * 2; ctx.save(); ctx.translate(Math.cos(g) * R * 0.89, Math.sin(g) * R * 0.89); ctx.rotate(g + Math.PI / 2); ctx.scale(1.8, 1.8); ctx.translate(-5, -6); ctx.strokeStyle = OL; ctx.lineWidth = 3.6; ctx.stroke(new Path2D(RUNES[i])); ctx.strokeStyle = '#FFF4E4'; ctx.lineWidth = 1.6; ctx.stroke(new Path2D(RUNES[i])); ctx.restore(); } }
          break; }
        case 'pillar': { const up = Math.min(p.age / 0.2, 1), fade = u > 0.6 ? 1 - (u - 0.6) / 0.4 : 1, h = 300 * (1 - Math.pow(1 - up, 3)); const g = ctx.createLinearGradient(0, 0, 0, -h); g.addColorStop(0, `rgba(191,107,255,${0.38 * fade * rf})`); g.addColorStop(1, 'rgba(191,107,255,0)'); ctx.fillStyle = g; ctx.fillRect(-70, -h, 140, h); ctx.fillStyle = `rgba(241,226,255,${0.35 * fade * rf})`; ctx.fillRect(-26, -h, 52, h); break; }
        case 'sun': {
          const rise = Math.min(p.age / 0.22, 1), k = 1 + 2.4 * Math.pow(rise - 1, 3) + 1.4 * Math.pow(rise - 1, 2), fade = u > 0.6 ? 1 - (u - 0.6) / 0.4 : 1; ctx.globalAlpha = fade; ctx.scale(k, k);
          const blade = (ang, len, w0) => { const ux = Math.sin(ang), uy = -Math.cos(ang), px = -uy, py = ux, bx = ux * 40, by = uy * 40 - 10, tx = bx + ux * len, ty = by + uy * len; ctx.beginPath(); ctx.moveTo(bx + px * w0, by + py * w0); ctx.quadraticCurveTo(bx + ux * len * 0.55 + px * w0 * 1.1, by + uy * len * 0.55 + py * w0 * 1.1, tx, ty); ctx.quadraticCurveTo(bx + ux * len * 0.5 - px * w0 * 0.5, by + uy * len * 0.5 - py * w0 * 0.5, bx - px * w0 * 0.6, by - py * w0 * 0.6); ctx.closePath(); const g = ctx.createLinearGradient(bx, by, tx, ty); g.addColorStop(0, '#F07828'); g.addColorStop(1, '#FFC870'); ctx.fillStyle = g; ctx.lineWidth = 5; ctx.strokeStyle = OL; ctx.stroke(); ctx.fill(); ctx.beginPath(); ctx.moveTo(bx + ux * 8, by + uy * 8); ctx.lineTo(bx + ux * len * 0.8 + px * w0 * 0.2, by + uy * len * 0.8 + py * w0 * 0.2); ctx.strokeStyle = '#FFE0A0'; ctx.lineWidth = 3; ctx.stroke(); };
          const sp = 1 + 0.06 * Math.sin(p.age * 10);
          [[-1.15, 70], [1.15, 70], [-0.66, 86], [0.66, 86]].forEach(([a, L]) => blade(a, L * sp, 15));
          ctx.beginPath(); ctx.arc(0, -10, 62, 0, 7); ctx.lineWidth = 6; ctx.strokeStyle = OL; ctx.stroke(); const g = ctx.createLinearGradient(-50, -70, 50, 50); g.addColorStop(0, '#FFE8A0'); g.addColorStop(1, '#F8A048'); ctx.fillStyle = g; ctx.fill();
          ctx.beginPath(); ctx.arc(-22, -28, 4, Math.PI, 0); ctx.bezierCurveTo(-18, -34, 10, -38, 12, -16); ctx.bezierCurveTo(14, 0, -6, 4, -10, -6); ctx.strokeStyle = '#E07828'; ctx.lineWidth = 4; ctx.stroke();
          ctx.beginPath(); ctx.arc(0, -10, 50, Math.PI * 1.08, Math.PI * 1.42); ctx.strokeStyle = '#FFF8E0'; ctx.lineWidth = 7; ctx.stroke(); break; }
        case 'eclipse': {
          const rise = Math.min(p.age / 0.3, 1), k = 1 - Math.pow(1 - rise, 3), out = u > 0.8 ? (u - 0.8) / 0.2 : 0; ctx.globalAlpha = (1 - out) * (flags.rf ? 0.6 : 1); ctx.scale(k, k);
          [[-1, 1.0, 46], [1, 1.0, 46], [-1, 0.55, 56], [1, 0.55, 56]].forEach(([side, a, h]) => { ctx.save(); ctx.translate(side * 30, -18); ctx.rotate(side * a); ctx.translate(0, -62); crys(h, PAL.LU, [1, 1, 1, 1, 1]); ctx.restore(); });
          const R = 82, dx = 40, R2 = 70, ix = (R * R - R2 * R2 + dx * dx) / (2 * dx), iy = Math.sqrt(Math.max(R * R - ix * ix, 0)), t1 = Math.atan2(iy, ix), t2 = Math.atan2(iy, ix - dx);
          ctx.save(); ctx.rotate(-Math.PI / 2 - 0.5); ctx.beginPath(); ctx.arc(0, 0, R, t1, Math.PI * 2 - t1, false); ctx.arc(dx, 0, R2, -t2, t2, true); ctx.closePath(); ctx.lineWidth = 6; ctx.strokeStyle = OL; ctx.stroke(); const g = ctx.createLinearGradient(-R, -R, R, R); g.addColorStop(0, '#FFF8EC'); g.addColorStop(1, '#F0D4B8'); ctx.fillStyle = g; ctx.fill();
          ctx.beginPath(); ctx.arc(0, 0, R - 14, Math.PI * 0.75, Math.PI * 1.15); ctx.strokeStyle = '#E8A060'; ctx.lineWidth = 3; ctx.stroke(); ctx.beginPath(); ctx.ellipse(-R + 24, 0, 6, 10, 0, 0, 7); ctx.fillStyle = '#60D8D0'; ctx.fill(); ctx.lineWidth = 2.5; ctx.strokeStyle = '#307070'; ctx.stroke(); ctx.restore(); break; }

        case 'leaf': ctx.rotate(p.rot); ctx.scale(1, 0.6 + 0.4 * Math.abs(Math.cos(p.age * 6 + p.seed * 6))); fs(() => { ctx.beginPath(); ctx.moveTo(-s, 0); ctx.quadraticCurveTo(0, -s * 0.75, s, 0); ctx.quadraticCurveTo(0, s * 0.75, -s, 0); ctx.closePath(); }); ctx.beginPath(); ctx.moveTo(-s * 0.8, 0); ctx.lineTo(s * 0.75, 0); ctx.strokeStyle = 'rgba(60,40,0,.35)'; ctx.lineWidth = 1.4; ctx.stroke(); break;
        case 'petal': ctx.rotate(p.rot); ctx.scale(1, 0.55 + 0.45 * Math.abs(Math.sin(p.age * 7 + p.seed * 6))); fs(() => { ctx.beginPath(); ctx.moveTo(0, -s); ctx.bezierCurveTo(s * 0.8, -s * 0.5, s * 0.5, s * 0.7, 0, s * 0.6); ctx.bezierCurveTo(-s * 0.5, s * 0.7, -s * 0.8, -s * 0.5, 0, -s); ctx.closePath(); }); ctx.beginPath(); ctx.ellipse(-s * 0.15, -s * 0.3, s * 0.15, s * 0.3, 0.3, 0, 7); ctx.fillStyle = 'rgba(255,255,255,.7)'; ctx.fill(); break;
        case 'pebble': ctx.rotate(p.rot * 0.3); fs(() => { ctx.beginPath(); ctx.ellipse(0, 0, s, s * 0.72, 0, 0, 7); }); ctx.beginPath(); ctx.ellipse(-s * 0.3, -s * 0.25, s * 0.32, s * 0.18, -0.3, 0, 7); ctx.fillStyle = 'rgba(255,255,255,.6)'; ctx.fill(); break;
        case 'drop': ctx.rotate(Math.atan2(p.vy || 1, p.vx || 0) - Math.PI / 2); fs(() => { ctx.beginPath(); ctx.moveTo(0, -s * 1.4); ctx.quadraticCurveTo(s * 0.9, -s * 0.1, s * 0.7, s * 0.4); ctx.arc(0, s * 0.4, s * 0.7, 0, Math.PI); ctx.quadraticCurveTo(-s * 0.9, -s * 0.1, 0, -s * 1.4); ctx.closePath(); }); ctx.beginPath(); ctx.arc(-s * 0.25, s * 0.25, s * 0.18, 0, 7); ctx.fillStyle = '#FFFFFF'; ctx.fill(); break;
        case 'bubble': { const R = s; if (!p.still) ctx.translate(Math.sin(p.age * 10 + p.seed * 6) * 2, 0); if (u > 0.86) { const k = (u - 0.86) / 0.14; ctx.globalAlpha = a * (1 - k); ctx.beginPath(); for (let i = 0; i < 6; i++) { const g = (i / 6) * Math.PI * 2; ctx.moveTo(Math.cos(g) * R * (0.9 + k * 0.4), Math.sin(g) * R * (0.9 + k * 0.4)); ctx.lineTo(Math.cos(g) * R * (1.15 + k * 0.6), Math.sin(g) * R * (1.15 + k * 0.6)); } ctx.lineCap = 'round'; ctx.strokeStyle = OL; ctx.lineWidth = 5; ctx.stroke(); ctx.strokeStyle = p.col; ctx.lineWidth = 2.6; ctx.stroke(); break; } ctx.beginPath(); ctx.arc(0, 0, R, 0, 7); ctx.fillStyle = 'rgba(200,244,255,.28)'; ctx.fill(); ctx.lineWidth = Math.max(2.4, R * 0.12); ctx.strokeStyle = OL; ctx.stroke(); ctx.lineWidth = Math.max(1.2, R * 0.06); ctx.strokeStyle = p.col; ctx.stroke(); ctx.beginPath(); ctx.arc(0, 0, R * 0.68, Math.PI * 1.1, Math.PI * 1.45); ctx.strokeStyle = '#FFFFFF'; ctx.lineWidth = Math.max(1.4, R * 0.1); ctx.lineCap = 'round'; ctx.stroke(); break; }
        case 'bolt': { const n = p.segs || 4, sd = flags.rf ? Math.floor(p.seed * 1000) : Math.floor(p.age * 24) + Math.floor(p.seed * 1000), R2 = (k) => { const x = Math.sin(sd * 12.9898 + k * 78.233) * 43758.5453; return x - Math.floor(x); }; const ca = Math.cos(p.ang), sa = Math.sin(p.ang), sy = p.sy || 1; ctx.globalAlpha = a * (u > 0.6 ? (1 - u) / 0.4 : 1); ctx.beginPath(); for (let k = 0; k <= n; k++) { const t = k / n, rad = p.r0 + (p.r1 - p.r0) * Math.min(p.age / 0.06, 1) * t, off = k === 0 || k === n ? 0 : (R2(k) - 0.5) * 18; ctx[k ? 'lineTo' : 'moveTo'](ca * rad - sa * off, (sa * rad + ca * off) * sy); } ctx.lineJoin = 'round'; ctx.lineCap = 'round'; ctx.strokeStyle = OL; ctx.lineWidth = 7; ctx.stroke(); ctx.strokeStyle = '#FFE84A'; ctx.lineWidth = 3.6; ctx.stroke(); ctx.strokeStyle = '#FFFFFF'; ctx.lineWidth = 1.2; ctx.stroke(); break; }
        case 'shroom': { if (p.age < (p.delay || 0)) break; const v = Math.min((p.age - (p.delay || 0)) / 0.16, 1), k = (1 + 2.2 * Math.pow(v - 1, 3) + 1.2 * Math.pow(v - 1, 2)) * (u > 0.8 ? 1 - (u - 0.8) / 0.2 : 1); if (k <= 0.02) break; ctx.scale(k, k); const g = ctx.createRadialGradient(0, -s * 0.9, 0, 0, -s * 0.9, s * 1.6); g.addColorStop(0, 'rgba(154,240,216,' + 0.45 * rf + ')'); g.addColorStop(1, 'rgba(154,240,216,0)'); ctx.fillStyle = g; ctx.beginPath(); ctx.arc(0, -s * 0.9, s * 1.6, 0, 7); ctx.fill(); ctx.lineWidth = 3; ctx.strokeStyle = OL; ctx.lineJoin = 'round'; ctx.beginPath(); ctx.moveTo(-s * 0.2, 0); ctx.quadraticCurveTo(-s * 0.28, -s * 0.5, -s * 0.16, -s * 0.9); ctx.lineTo(s * 0.16, -s * 0.9); ctx.quadraticCurveTo(s * 0.28, -s * 0.5, s * 0.2, 0); ctx.closePath(); ctx.fillStyle = '#FFF4E4'; ctx.stroke(); ctx.fill(); ctx.beginPath(); ctx.moveTo(-s * 0.62, -s * 0.82); ctx.quadraticCurveTo(-s * 0.6, -s * 1.5, 0, -s * 1.52); ctx.quadraticCurveTo(s * 0.6, -s * 1.5, s * 0.62, -s * 0.82); ctx.quadraticCurveTo(0, -s * 0.98, -s * 0.62, -s * 0.82); ctx.closePath(); ctx.fillStyle = p.col; ctx.stroke(); ctx.fill(); [[-0.28, -1.2, 0.1], [0.2, -1.3, 0.08], [0.35, -1.02, 0.06]].forEach(([x, y, r]) => { ctx.beginPath(); ctx.arc(x * s, y * s, r * s, 0, 7); ctx.fillStyle = '#FFF4FF'; ctx.fill(); }); break; }
        case 'fall': { const t0 = p.delay || 0; if (p.age < t0) break; const v = Math.min((p.age - t0) / 0.3, 1), ev = 1 - (1 - v) * (1 - v), fade = u > 0.85 ? 1 - (u - 0.85) / 0.15 : 1; ctx.globalAlpha = fade; if (v < 1) { const hx = p.sx * (1 - ev), hy = p.sy * (1 - ev), tx = hx + p.sx * 0.35 * (1 - v * 0.6), ty = hy + p.sy * 0.35 * (1 - v * 0.6), g = ctx.createLinearGradient(hx, hy, tx, ty); g.addColorStop(0, '#FFE48A'); g.addColorStop(0.45, '#3A58C8'); g.addColorStop(1, 'rgba(58,88,200,0)'); const L = Math.hypot(tx - hx, ty - hy) || 1, nx = -(ty - hy) / L * 4, ny = (tx - hx) / L * 4; ctx.beginPath(); ctx.moveTo(hx + nx, hy + ny); ctx.lineTo(tx, ty); ctx.lineTo(hx - nx, hy - ny); ctx.closePath(); ctx.fillStyle = g; ctx.fill(); ctx.translate(hx, hy); star4(10, '#FFF8E0', '#3A58C8'); break; } const w = Math.min((p.age - t0 - 0.3) / 0.15, 1), pop = 1 + 0.5 * Math.sin(w * Math.PI), bl = flags.rf ? 1 : 0.75 + 0.25 * Math.sin(p.age * 10 + p.seed * 6); ctx.rotate(0.1); star4(s * pop * bl, '#FFE48A', '#3A58C8'); break; }
        case 'cres': ctx.rotate(p.rot); cres(s, p.col); break;
        case 'gcres': { const r = p.r0 + (p.r1 - p.r0) * eo; ctx.scale(1, 0.26); ctx.globalAlpha = a * (1 - eo); ctx.beginPath(); ctx.arc(0, 0, r, 0, 7); ctx.strokeStyle = OL; ctx.lineWidth = 13; ctx.stroke(); ctx.strokeStyle = '#FF3D6E'; ctx.lineWidth = 7; ctx.stroke(); ctx.beginPath(); ctx.arc(0, 0, r * 0.84, 0, 7); ctx.strokeStyle = OL; ctx.lineWidth = 7; ctx.stroke(); ctx.strokeStyle = '#FFD76A'; ctx.lineWidth = 3; ctx.stroke(); break; }
        case 'dial': {
          const v = Math.min(p.age / 0.28, 1), k = 1 + 2.2 * Math.pow(v - 1, 3) + 1.2 * Math.pow(v - 1, 2), fade = u > 0.78 ? 1 - (u - 0.78) / 0.22 : 1; ctx.globalAlpha = fade; ctx.scale(k, k); ctx.rotate(p.age * 0.7);
          const ring = (r, w, c) => { ctx.beginPath(); ctx.arc(0, 0, r, 0, 7); ctx.strokeStyle = OL; ctx.lineWidth = w + 5; ctx.stroke(); ctx.strokeStyle = c; ctx.lineWidth = w; ctx.stroke(); };
          ctx.globalAlpha = fade * 0.35 * rf; ctx.beginPath(); ctx.arc(0, 0, 96, 0, 7); ctx.fillStyle = '#2A0F2E'; ctx.fill(); ctx.globalAlpha = fade;
          ring(96, 6, '#FF3D6E'); ring(84, 3, '#FFD76A');
          for (let i = 0; i < 12; i++) { const g = (i / 12) * Math.PI * 2; ctx.save(); ctx.rotate(g); if (i % 4 === 0) { ctx.translate(0, -90); ctx.beginPath(); ctx.moveTo(0, -9); ctx.lineTo(7, 0); ctx.lineTo(0, 9); ctx.lineTo(-7, 0); ctx.closePath(); ctx.lineWidth = 4; ctx.strokeStyle = OL; ctx.stroke(); ctx.fillStyle = '#FF8A98'; ctx.fill(); ctx.beginPath(); ctx.moveTo(-2, -2); ctx.lineTo(0, -6); ctx.strokeStyle = '#FFF4E4'; ctx.lineWidth = 1.6; ctx.stroke(); } else { ctx.beginPath(); ctx.moveTo(0, -86); ctx.lineTo(0, -94); ctx.strokeStyle = '#FFD76A'; ctx.lineWidth = 2.4; ctx.stroke(); } ctx.restore(); }
          for (let i = 0; i < 4; i++) { const g = (i / 4) * Math.PI * 2 + Math.PI / 4; ctx.save(); ctx.translate(Math.cos(g) * 114, Math.sin(g) * 114); ctx.rotate(g + Math.PI); cres(11, '#FFD76A', 2.4); ctx.restore(); }
          break; }
        case 'constel': {
          const fade = u > 0.8 ? 1 - (u - 0.8) / 0.2 : 1, pr = Math.min(p.age / 0.42, 1), P = p.pts; ctx.globalAlpha = fade;
          [[0, 1, 2], [3, 4, 5]].forEach((g) => { for (let j = 0; j < 2; j++) { const t = Math.min(Math.max(pr * 2 - j, 0), 1); if (t <= 0) continue; const A = P[g[j]], B = P[g[j + 1]], ex = A[0] + (B[0] - A[0]) * t, ey = A[1] + (B[1] - A[1]) * t; ctx.beginPath(); ctx.moveTo(A[0], A[1]); ctx.lineTo(ex, ey); ctx.strokeStyle = OL; ctx.lineWidth = 6; ctx.stroke(); ctx.strokeStyle = '#FFD76A'; ctx.lineWidth = 2.6; ctx.stroke(); } });
          P.forEach((q, i) => { const t0 = (i % 3) * 0.12 + (i > 2 ? 0.04 : 0); if (p.age < t0) return; const w = Math.min((p.age - t0) / 0.14, 1), pop = 1 + 0.5 * Math.sin(w * Math.PI) * (1 - w) + (w < 1 ? -0.4 * (1 - w) : 0), tw2 = 0.8 + 0.2 * Math.sin(p.age * 8 + i * 1.7); ctx.save(); ctx.translate(q[0], q[1]); star4((i % 3 === 1 ? 15 : 11) * pop * tw2, '#FFF4E4', '#FF3D6E'); ctx.restore(); });
          break; }
        case 'sheen': { const t0 = p.delay || 0; if (p.age < t0) break; const v = Math.min((p.age - t0) / 0.32, 1); ctx.rotate(0.04); rr(-50, -50, 100, 100, 17); ctx.clip(); ctx.globalAlpha = 0.6 * rf * Math.sin(v * Math.PI); const x = -120 + 240 * v; ctx.beginPath(); ctx.moveTo(x - 14, -60); ctx.lineTo(x + 10, -60); ctx.lineTo(x - 30, 60); ctx.lineTo(x - 54, 60); ctx.closePath(); ctx.fillStyle = '#FFF8E0'; ctx.fill(); ctx.beginPath(); ctx.moveTo(x + 18, -60); ctx.lineTo(x + 26, -60); ctx.lineTo(x - 14, 60); ctx.lineTo(x - 22, 60); ctx.closePath(); ctx.fillStyle = '#FFD76A'; ctx.fill(); break; }
        case 'night': { const fade = Math.min(p.age / 0.3, 1) * (u > 0.8 ? 1 - (u - 0.8) / 0.2 : 1); p.sf.forEach(([x, y, r, ph]) => { ctx.save(); ctx.translate(x, y); ctx.globalAlpha = fade * (0.45 + 0.55 * Math.abs(Math.sin(p.age * 3 + ph))); ctx.beginPath(); ctx.arc(0, 0, r * 0.45, 0, 7); ctx.fillStyle = '#FFF4E4'; ctx.fill(); if (r > 4.5) { ctx.beginPath(); ctx.moveTo(-r, 0); ctx.lineTo(r, 0); ctx.moveTo(0, -r); ctx.lineTo(0, r); ctx.strokeStyle = '#FFD9E2'; ctx.lineWidth = 1.2; ctx.stroke(); } ctx.restore(); }); break; }
        case 'bloodmoon': {
          const v = Math.min(p.age / 0.38, 1), e = 1 + 2.0 * Math.pow(v - 1, 3) + 1.0 * Math.pow(v - 1, 2), out = u > 0.85 ? (u - 0.85) / 0.15 : 0, MR = 112; ctx.globalAlpha = 1 - out; ctx.translate(0, (1 - Math.min(e, 1)) * 90); ctx.scale(0.6 + 0.4 * e, 0.6 + 0.4 * e);
          ctx.save(); ctx.rotate(p.age * 0.25); for (let i = 0; i < 10; i++) { const g = (i / 10) * Math.PI * 2; ctx.beginPath(); ctx.moveTo(Math.cos(g - 0.09) * 120, Math.sin(g - 0.09) * 120); ctx.lineTo(Math.cos(g - 0.16) * 330, Math.sin(g - 0.16) * 330); ctx.lineTo(Math.cos(g + 0.16) * 330, Math.sin(g + 0.16) * 330); ctx.lineTo(Math.cos(g + 0.09) * 120, Math.sin(g + 0.09) * 120); ctx.closePath(); ctx.fillStyle = i % 2 ? 'rgba(255,215,106,1)' : 'rgba(255,61,110,1)'; ctx.globalAlpha = (1 - out) * v * 0.2 * rf; ctx.fill(); } ctx.restore(); ctx.globalAlpha = 1 - out;
          const ec = Math.min(Math.max((p.age - 0.45) / 0.5, 0), 1), ee = ec * ec * (3 - 2 * ec);
          if (ee > 0.6) { const cg = (ee - 0.6) / 0.4; ctx.beginPath(); ctx.arc(0, 0, MR + 10, 0, 7); ctx.strokeStyle = 'rgba(255,215,106,' + (0.35 * cg * rf) + ')'; ctx.lineWidth = 26; ctx.stroke(); }
          ctx.beginPath(); ctx.arc(0, 0, MR, 0, 7); ctx.lineWidth = 7; ctx.strokeStyle = OL; ctx.stroke(); const g = ctx.createRadialGradient(-30, -36, 10, 0, 0, MR); g.addColorStop(0, '#FF8A98'); g.addColorStop(0.55, '#E0305A'); g.addColorStop(1, '#8A1434'); ctx.fillStyle = g; ctx.fill();
          ctx.save(); ctx.beginPath(); ctx.arc(0, 0, MR - 3, 0, 7); ctx.clip();
          [[-78, -30, 16, 11], [72, -52, 12, 9], [62, 50, 18, 12], [-58, 64, 10, 7]].forEach(([x, y, rx, ry]) => { ctx.beginPath(); ctx.ellipse(x, y, rx, ry, 0.3, 0, 7); ctx.fillStyle = 'rgba(122,16,48,.55)'; ctx.fill(); ctx.beginPath(); ctx.ellipse(x - 2, y - 2, rx * 0.6, ry * 0.5, 0.3, Math.PI, Math.PI * 1.8); ctx.strokeStyle = 'rgba(255,192,200,.5)'; ctx.lineWidth = 2; ctx.stroke(); });
          ctx.beginPath(); ctx.arc(0, 0, MR - 12, Math.PI * 1.05, Math.PI * 1.42); ctx.strokeStyle = '#FFC0C8'; ctx.lineWidth = 6; ctx.stroke();
          if (ee > 0) { ctx.beginPath(); ctx.arc(-2.4 * MR * (1 - ee), 0, MR + 2, 0, 7); ctx.fillStyle = '#2A0F2E'; ctx.fill(); ctx.strokeStyle = '#4A1E50'; ctx.lineWidth = 4; ctx.stroke(); }
          ctx.restore();
          if (ee > 0.6) { const cg = (ee - 0.6) / 0.4; ctx.beginPath(); ctx.arc(0, 0, MR + 1, 0, 7); ctx.strokeStyle = '#FFD76A'; ctx.globalAlpha = (1 - out) * cg; ctx.lineWidth = 6; ctx.stroke(); ctx.globalAlpha = 1 - out; }
          if (!flags.rf && p.age > 0.92 && p.age < 1.3) { const w = (p.age - 0.92) / 0.38, sc = Math.sin(w * Math.PI); ctx.save(); ctx.translate(Math.cos(-0.7) * MR, Math.sin(-0.7) * MR); ctx.rotate(0.1); star4(34 * sc + 2, '#FFF8E0', '#FFB23F'); ctx.restore(); }
          break; }
        case 'orbitc': { const v = Math.min(p.age / 0.3, 1), burst = u > 0.82 ? (u - 0.82) / 0.18 : 0, g = p.ang + p.age * (flags.rf ? 1.2 : 2.1), rx = (150 + burst * 160) * v, ry = (70 + burst * 80) * v, back = Math.sin(g) < 0; ctx.globalAlpha = (1 - burst) * (back ? 0.7 : 1); ctx.translate(Math.cos(g) * rx, Math.sin(g) * ry); ctx.rotate(g + Math.PI); cres(s * (back ? 0.8 : 1), '#FFD76A'); break; }
        case 'shoot': { const t0 = p.delay || 0; if (p.age < t0) break; const v = Math.min((p.age - t0) / 0.55, 1); if (v >= 1) break; const hx = 820 - 600 * v, hy = 46 + 70 * v, tx = hx + 170, ty = hy - 20; const g = ctx.createLinearGradient(hx, hy, tx, ty); g.addColorStop(0, '#FFD76A'); g.addColorStop(0.4, '#FF3D6E'); g.addColorStop(1, 'rgba(255,61,110,0)'); ctx.beginPath(); ctx.moveTo(hx, hy - 4); ctx.lineTo(tx, ty); ctx.lineTo(hx, hy + 4); ctx.closePath(); ctx.fillStyle = g; ctx.globalAlpha = 1 - v * 0.3; ctx.fill(); ctx.translate(hx, hy); star4(11, '#FFF8E0', '#FF3D6E'); break; }
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
    const STATIC = { shroom: 1, fall: 1, bolt: 1, gcres: 1, dial: 1, constel: 1, sheen: 1, night: 1, bloodmoon: 1, orbitc: 1, shoot: 1, gring: 1, ring: 1, ray: 1, burst: 1, circle: 1, pillar: 1, sun: 1, eclipse: 1, orbit: 1, spike: 1 };
    function frame(now) {
      const o = getOpts(); flags = o;
      const dtReal = Math.min((now - last) / 1000, 0.05); last = now;
      const dt = dtReal / (o.slow ? 2.5 : 1);
      prevT = T; T += dt; if (T >= PERIOD) { T = 0; prevT = 0; parts = []; hist = []; settleAt = -1; stats = { peak: 0 }; dim = 0; }
      const def = FXDEF[o.fx], id = FX[o.fx].die, d = dieAt(T);
      const cross = (t) => prevT < t && T >= t;
      const every = (iv) => { spawnAcc += dt; if (spawnAcc >= iv) { spawnAcc = 0; return true; } return false; };
      if (d.moving) { def.trail(d, every); hist.unshift({ x: d.x, y: d.y, rot: d.rot, sx: d.sx, pop: d.pop }); hist.length = Math.min(hist.length, 14); } else if (hist.length) hist.pop();
      [[0.36, 1], [0.6, 0.6], [0.76, 0.35]].forEach(([t, k]) => { if (cross(t)) def.impact(dieAt(t).x, FLOOR, k); });
      if (cross(0.9)) { def.settle(d, TYPE.dmg, !!o.max); settleAt = T; clearT = 0; }
      for (const p of parts) { p.age += dt; if (!p.tw && !STATIC[p.shape]) { p.vy += p.g * dt; p.vx *= 1 - p.drag * dt; p.vy *= 1 - p.drag * dt; p.x += p.vx * dt; p.y += p.vy * dt; p.rot += p.vr * dt; if (p.bounce && p.y > FLOOR - 4 && p.vy > 0) { p.y = FLOOR - 4; p.vy *= -0.5; p.vx *= 0.8; } } }
      const dead = parts.filter((p) => p.age >= p.life); parts = parts.filter((p) => p.age < p.life);
      dead.forEach((p) => { if (p.shatter) for (let i = 0; i < 3; i++) add(p.pal === PAL.LU ? { shape: 'crys', pal: PAL.LU, x: p.x + p.lean * 0.5, y: p.y - p.h * 0.5, vx: rnd(-160, 160), vy: -rnd(100, 220), g: 700, life: 0.45, s0: 10, s1: 5, front: p.front } : { shape: 'shard', col: '#C8D8F8', x: p.x + p.lean * 0.5, y: p.y - p.h * 0.5, vx: rnd(-160, 160), vy: -rnd(100, 220), g: 700, life: 0.45, s0: 11, s1: 5, front: p.front }); if (p.popTo) for (let i = 0; i < 2; i++) add({ shape: 'dia', x: p.x, y: p.y - 20, vx: rnd(-60, 60), vy: -rnd(120, 200), g: 500, life: 0.4, s0: 6, s1: 2, col: pick(FIRE) }); });
      stats.peak = Math.max(stats.peak, parts.length);
      tint = Math.max(0, tint - dt * 1.25); if (T > 2.5) dim = Math.max(0, dim - dt * 2);
      ctx.clearRect(0, 0, W, H);
      rr(4, 4, W - 8, H - 8, 40); ctx.fillStyle = '#7A4A22'; ctx.fill(); ctx.lineWidth = 5; ctx.strokeStyle = '#000'; ctx.stroke();
      rr(22, 22, W - 44, H - 44, 26); const gr = ctx.createLinearGradient(0, 22, 0, H - 22); gr.addColorStop(0, '#27555D'); gr.addColorStop(1, '#1B3E45'); ctx.fillStyle = gr; ctx.fill(); ctx.lineWidth = 4; ctx.strokeStyle = '#A56B35'; ctx.stroke();
      ctx.save(); rr(22, 22, W - 44, H - 44, 26); ctx.clip();
      if (dim > 0) { ctx.fillStyle = `rgba(8,9,13,${dim})`; ctx.fillRect(0, 0, W, H); }
      const step = Math.floor(T * 12) !== lastStep; if (step) lastStep = Math.floor(T * 12);
      const life = (p) => (p.tw ? 1 - Math.pow(p.age / p.life, 2) : STATIC[p.shape] || p.shape === 'cloud' || p.shape === 'flame' || p.blink ? 1 : 1 - p.age / p.life);
      const SMOOTH = { dial: 1, constel: 1, sheen: 1, night: 1, bloodmoon: 1, orbitc: 1, shoot: 1 };
      const snap = (p) => { if (step || !p.sn || SMOOTH[p.shape]) { if (p.tw) { const e = 1 - Math.pow(1 - p.age / p.life, 3); p.x = p.x0 + (p.x1 - p.x0) * e; p.y = p.y0 + (p.y1 - p.y0) * e; } p.sn = { x: p.x, y: p.y, rot: p.rot, age: p.age }; } };
      const drawSn = (p) => { const k = { x: p.x, y: p.y, rot: p.rot, age: p.age }; Object.assign(p, p.sn); drawShape(p, life(p)); Object.assign(p, k); };
      const BIG = { gcres: 1, dial: 1, night: 1, bloodmoon: 1, pillar: 1, sun: 1, eclipse: 1, circle: 1, gring: 1 };
      for (const p of parts) if (BIG[p.shape] && !p.front) { snap(p); drawSn(p); }
      const ph = FLOOR - d.y - 52; ctx.fillStyle = `rgba(0,0,0,${Math.max(0.15, 0.4 - ph / 600)})`; ctx.beginPath(); ctx.ellipse(d.x, FLOOR + 6, 58 * Math.max(0.5, 1 - ph / 400), 12, 0, 0, 7); ctx.fill();
      if (def.comet && hist.length > 2) { (Array.isArray(def.comet) ? def.comet : [['#000', 24], [o.rf ? '#F8A048' : '#FF9445', 16], [o.rf ? '#FFC93C' : '#FFC870', 8]]).forEach(([c, w]) => { for (let i = 1; i < hist.length; i++) { ctx.beginPath(); ctx.moveTo(hist[i - 1].x, hist[i - 1].y); ctx.lineTo(hist[i].x, hist[i].y); ctx.strokeStyle = c; ctx.lineCap = 'round'; ctx.lineWidth = w * (1 - i / hist.length); ctx.stroke(); } }); }
      for (const p of parts) if (!p.front && !BIG[p.shape]) { snap(p); drawSn(p); }
      if (def.ghost && d.moving) [[7, 0.18], [3, 0.32]].forEach(([k, al]) => { const h = hist[k]; if (h) { ctx.save(); ctx.globalAlpha = al; drawDie(h, id, !!o.max); ctx.restore(); } });
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
    window.CosArt = { TIERS, DIE, FRAME, FX, INK, TYPE, PAL, OL, contrast, hue, lum, plateSVG, dieSVG, frameSVG, mountFX, exportPNG };
  });
})();
