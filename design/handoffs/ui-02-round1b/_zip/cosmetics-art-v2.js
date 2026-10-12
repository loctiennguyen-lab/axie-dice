/* Axie Dice · Cosmetics 01 pilot — vector art + FX engine. Plain script, sets window.CosArt. */
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
  // ---------- colour maths ----------
  const lin = (c) => { c /= 255; return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); };
  const hex = (h) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16));
  const lum = (h) => { const [r, g, b] = hex(h).map(lin); return 0.2126 * r + 0.7152 * g + 0.0722 * b; };
  const contrast = (a, b) => { const x = lum(a), y = lum(b); return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05); };
  const hue = (h) => { const [r, g, b] = hex(h).map((v) => v / 255); const M = Math.max(r, g, b), m = Math.min(r, g, b), d = M - m; if (!d) return null; let H = M === r ? ((g - b) / d) % 6 : M === g ? (b - r) / d + 2 : (r - g) / d + 4; H *= 60; return H < 0 ? H + 360 : H; };

  // ---------- anim helper ----------
  // reduced-flashing variants use the *Soft keyframes; static drops animation entirely.
  function A(o, name, dur, extra) {
    if (o.static) return '';
    const soft = o.rf && /Pulse|Twinkle|Breathe|Sheen/.test(name) ? name + 'Soft' : name;
    return `animation:${soft} ${dur}s ${extra || 'ease-in-out infinite'};`;
  }
  let uid = 0;
  const f = (n) => +n.toFixed(2);
  const P = (r, a, cx = 128, cy = 128) => { const t = (a * Math.PI) / 180; return [f(cx + r * Math.cos(t)), f(cy + r * Math.sin(t))]; };
  const ring = (r1, r2, cx = 128, cy = 128) => `M${cx - r2} ${cy}a${r2} ${r2} 0 1 0 ${2 * r2} 0a${r2} ${r2} 0 1 0 ${-2 * r2} 0ZM${cx - r1} ${cy}a${r1} ${r1} 0 1 1 ${2 * r1} 0a${r1} ${r1} 0 1 1 ${-2 * r1} 0Z`;
  const RUNES = ['M2 1V11M2 4L8 1M2 7L8 4', 'M5 1V11M1 4L5 7L9 4', 'M1 1L9 11M9 1L1 11', 'M2 11V1L8 5L2 8', 'M1 6H9M5 1V11M2 2L8 10', 'M2 1H8L2 11H8'];
  const star4 = (x, y, r, fill, style = '') => `<path d="M${x} ${y - r}Q${x} ${y} ${x + r} ${y}Q${x} ${y} ${x} ${y + r}Q${x} ${y} ${x - r} ${y}Q${x} ${y} ${x} ${y - r}Z" fill="${fill}" style="transform-origin:${x}px ${y}px;${style}"/>`;
  const crescent = (cx, cy, r, k = 0.62) => `M${cx} ${cy - r}A${r} ${r} 0 1 1 ${cx} ${cy + r}A${f(r * k)} ${r} 0 1 0 ${cx} ${cy - r}Z`;

  // ---------- HAND-DRAWN HELPERS ----------
  function rng(seed) { let a = seed >>> 0; return function () { a = (a + 0x6D2B79F5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
  const J = (r, amt) => (r() * 2 - 1) * amt;
  function smooth(pts, closed = true) {
    const n = pts.length, g = (i) => pts[closed ? (i + n) % n : Math.max(0, Math.min(n - 1, i))];
    let d = 'M' + f(pts[0][0]) + ' ' + f(pts[0][1]);
    for (let i = 0; i < (closed ? n : n - 1); i++) { const p0 = g(i - 1), p1 = g(i), p2 = g(i + 1), p3 = g(i + 2); d += 'C' + f(p1[0] + (p2[0] - p0[0]) / 6) + ' ' + f(p1[1] + (p2[1] - p0[1]) / 6) + ' ' + f(p2[0] - (p3[0] - p1[0]) / 6) + ' ' + f(p2[1] - (p3[1] - p1[1]) / 6) + ' ' + f(p2[0]) + ' ' + f(p2[1]); }
    return d + (closed ? 'Z' : '');
  }
  const blob = (cx, cy, rx, ry, n, j, r, rot = 0) => { const pts = []; for (let i = 0; i < n; i++) { const t = rot + (i / n) * Math.PI * 2, k = 1 + J(r, j); pts.push([cx + Math.cos(t) * rx * k, cy + Math.sin(t) * ry * k]); } return smooth(pts); };
  const ringPts = (rad, n, j, r) => { const pts = []; for (let i = 0; i < n; i++) { const t = (i / n) * Math.PI * 2, k = rad * (1 + J(r, j)); pts.push([128 + Math.cos(t) * k, 128 + Math.sin(t) * k]); } return pts; };
  const ringBlob = (r1, r2, r, jo = 0.035, ji = 0.008) => smooth(ringPts(r2, 22, jo, r)) + smooth(ringPts(r1, 22, ji, r).reverse());
  const wobRect = (x, y, w, h, rad, r, j) => { const pts = []; const c = [[x + rad, y], [x + w - rad, y], [x + w, y + rad], [x + w, y + h - rad], [x + w - rad, y + h], [x + rad, y + h], [x, y + h - rad], [x, y + rad]]; c.forEach(([px, py]) => pts.push([px + J(r, j), py + J(r, j)])); return smooth(pts); };
  // wobble (line boil) + grain filters, per svg instance
  const defsFor = (u, disp, freq, seed, gf) => '<filter id="w' + u + '" x="-8%" y="-8%" width="116%" height="116%"><feTurbulence type="fractalNoise" baseFrequency="' + freq + '" numOctaves="2" seed="' + seed + '"/><feDisplacementMap in="SourceGraphic" scale="' + disp + '" xChannelSelector="R" yChannelSelector="G"/></filter>' +
    '<filter id="g' + u + '" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="' + gf + '" numOctaves="2" seed="' + (seed + 9) + '"/><feColorMatrix type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  2.4 0 0 0 -1.3"/></filter>';
  const grain = (u, w, h, op) => '<rect width="' + w + '" height="' + h + '" filter="url(#g' + u + ')" opacity="' + op + '"/>';
  // faceted crystal: x, baseY, height, width, lean (tip offset), colours
  function crystal(x, by, h, w, lean, c, sw) {
    const bl = [x - w / 2, by + 2], br = [x + w / 2, by + 2], sl = [x - w / 2 - lean * 0.2, by - h * 0.68], sr = [x + w / 2 - lean * 0.1, by - h * 0.62], tp = [x + lean, by - h], mb = [x + w * 0.08, by + 2], mr = [x + lean * 0.5 + w * 0.06, by - h * 0.6];
    const P2 = (p) => f(p[0]) + ' ' + f(p[1]);
    return '<path d="M' + P2(bl) + 'L' + P2(sl) + 'L' + P2(tp) + 'L' + P2(sr) + 'L' + P2(br) + 'Z" fill="' + c[1] + '"/>' +
      '<path d="M' + P2(bl) + 'L' + P2(sl) + 'L' + P2(tp) + 'L' + P2(mr) + 'L' + P2(mb) + 'Z" fill="' + c[0] + '"/>' +
      '<path d="M' + P2(tp) + 'L' + P2(mr) + 'L' + P2(mb) + '" stroke="' + c[2] + '" stroke-width="' + sw * 0.5 + '" fill="none" stroke-linejoin="round"/>' +
      '<path d="M' + P2([sl[0] + w * 0.18, sl[1] + 2]) + 'L' + P2([tp[0] - w * 0.08, tp[1] + h * 0.22]) + '" stroke="#FFE8EE" stroke-width="' + sw * 0.55 + '" stroke-linecap="round"/>' +
      '<path d="M' + P2(bl) + 'L' + P2(sl) + 'L' + P2(tp) + 'L' + P2(sr) + 'L' + P2(br) + '" fill="none" stroke="#1E0410" stroke-width="' + sw + '" stroke-linejoin="round"/>';
  }
  const crescentHD = (cx, cy, rr, shade, sw) => '<path d="' + crescent(cx, cy, rr) + '" fill="#FFE8EE" stroke="#000" stroke-width="' + sw + '" stroke-linejoin="round"/>' +
    '<path d="M' + f(cx + rr * 0.95) + ' ' + f(cy + rr * 0.25) + 'A' + rr + ' ' + rr + ' 0 0 1 ' + f(cx) + ' ' + f(cy + rr) + 'A' + f(rr * 0.62) + ' ' + rr + ' 0 0 0 ' + f(cx + rr * 0.6) + ' ' + f(cy + rr * 0.3) + 'Z" fill="' + shade + '"/>' +
    '<ellipse cx="' + f(cx + rr * 0.55) + '" cy="' + f(cy - rr * 0.35) + '" rx="' + f(rr * 0.13) + '" ry="' + f(rr * 0.1) + '" fill="' + shade + '"/><ellipse cx="' + f(cx + rr * 0.72) + '" cy="' + f(cy + rr * 0.05) + '" rx="' + f(rr * 0.08) + '" ry="' + f(rr * 0.07) + '" fill="' + shade + '"/>';
  const twinkle = (x, y, rv, rh, fill, style) => '<path d="M' + f(x) + ' ' + f(y - rv) + 'Q' + f(x + rh * 0.12) + ' ' + f(y - rh * 0.12) + ' ' + f(x + rh) + ' ' + f(y) + 'Q' + f(x + rh * 0.12) + ' ' + f(y + rh * 0.12) + ' ' + f(x) + ' ' + f(y + rv * 0.8) + 'Q' + f(x - rh * 0.12) + ' ' + f(y + rh * 0.12) + ' ' + f(x - rh * 0.85) + ' ' + f(y) + 'Q' + f(x - rh * 0.12) + ' ' + f(y - rh * 0.12) + ' ' + f(x) + ' ' + f(y - rv) + 'Z" fill="' + fill + '" style="transform-origin:' + f(x) + 'px ' + f(y) + 'px;' + (style || '') + '"/>';

  // ---------- DIE PLATES (104 × 104 face space; band hides y < 24.96) ----------
  const CZ = { x: 10.4, y: 45.8, w: 83.2, h: 37.4 };
  const DIE = {
    die_c_reed: {
      tier: 0, name: 'Woven Reed', border: '#000', calm: ['#EBD49A', '#E3C887', '#B88F48'], wob: [1.4, 0.06, 4], gr: 0.16,
      spec: ['Border #000, 4 px at s=104 (3 px on the 36 px egg token).', 'Hand-woven straw: every strand is its own shape, with a little drift in width and tone. Over-strands cast a 1 px shadow on the strand underneath.', 'One frayed strand at the lower left and a rope-braid rim along the bottom 13 px.', 'Grain overlay 16 %, line boil 1.4 px.'],
      plate(o) {
        const r = rng(11), tones = ['#EBD49A', '#E7CD8F', '#F0DCA8', '#E3C887'];
        let s = '<rect width="104" height="104" fill="#B88F48"/>';
        for (let i = 0; i < 8; i++) for (let j = 0; j < 8; j++) {
          const x = j * 13 + J(r, 0.5), y = i * 13 + J(r, 0.5), h = (i + j) % 2 === 0, t = tones[(r() * 4) | 0], wv = J(r, 0.6);
          if (h) {
            s += '<rect x="' + f(x + 0.3) + '" y="' + f(y + 2.4) + '" width="12.6" height="' + f(9.6 + wv) + '" rx="4.4" fill="#C9A660"/><rect x="' + f(x + 0.3) + '" y="' + f(y + 1.5) + '" width="12.6" height="' + f(8.8 + wv) + '" rx="4.4" fill="' + t + '"/>';
            s += '<path d="M' + f(x + 2 + r() * 2) + ' ' + f(y + 3.6) + 'h' + f(4 + r() * 5) + '" stroke="#FFF3CF" stroke-width=".9" stroke-linecap="round"/>';
            if (r() < 0.6) s += '<path d="M' + f(x + 1 + r() * 3) + ' ' + f(y + 7.5 + J(r, 1)) + 'h' + f(3 + r() * 6) + '" stroke="#C9A660" stroke-width=".6" stroke-linecap="round"/>';
          } else {
            s += '<rect x="' + f(x + 2.4) + '" y="' + f(y + 0.3) + '" width="' + f(9.6 + wv) + '" height="12.6" rx="4.4" fill="#C9A660"/><rect x="' + f(x + 1.5) + '" y="' + f(y + 0.3) + '" width="' + f(8.8 + wv) + '" height="12.6" rx="4.4" fill="' + t + '"/>';
            s += '<path d="M' + f(x + 3.4) + ' ' + f(y + 2 + r() * 2) + 'v' + f(4 + r() * 5) + '" stroke="#FFF3CF" stroke-width=".9" stroke-linecap="round"/>';
          }
        }
        s += '<path d="M3 84c3 -2 5 -1 6 -4M5 86c2 1 4 0 6 2" stroke="#8E6630" stroke-width=".9" fill="none" stroke-linecap="round"/>';
        s += '<path d="M-2 90.5C20 89.6 40 91.4 60 90.4S90 89.8 106 90.8V106H-2Z" fill="#8E6630"/>';
        for (let x = -4, k = 0; x < 108; x += 6.6 + J(r, 0.5), k++) s += '<ellipse cx="' + f(x) + '" cy="' + f(97.3 + J(r, 0.4)) + '" rx="5" ry="3.3" transform="rotate(' + f(34 + J(r, 5)) + ' ' + f(x) + ' 97.3)" fill="' + (k % 2 ? '#D8B46A' : '#CFA95E') + '" stroke="#5A3A12" stroke-width=".9"/><path d="M' + f(x - 2.6) + ' ' + f(95.6) + 'q1.6 -1.6 3.6 -.6" stroke="#F3DDA4" stroke-width=".8" fill="none" stroke-linecap="round"/>';
        s += '<path d="M-2 90.5C20 89.6 40 91.4 60 90.4S90 89.8 106 90.8" stroke="#5A3A12" stroke-width="1.6" fill="none"/>';
        return s;
      },
    },
    die_u_moss: {
      tier: 1, name: 'Mossback Stone', border: '#000', calm: ['#C5C8B8', '#BEC2B1', '#8F9486', '#9DA192'], wob: [1.6, 0.05, 7], gr: 0.2,
      spec: ['Border #000, 4 px.', 'Irregular field-stones in grey mortar. Each stone carries its own lower-right shadow #9DA192 and an upper-left highlight, so the light always comes from the top left.', 'Lumpy moss clumps creep in from the bottom and both sides, with one small sprout. Inner moss line #1E2A0E, not black.', 'Grain 20 %, line boil 1.6 px.'],
      plate(o) {
        const r = rng(23), tones = ['#C9CCBD', '#C3C6B6', '#CDD0C2', '#BEC2B1'];
        let s = '<rect width="104" height="104" fill="#8F9486"/>';
        [[-4, -4, 40, 30], [38, -4, 36, 26], [76, -4, 32, 34], [-4, 28, 30, 30], [28, 24, 45, 29], [75, 32, 33, 26], [-4, 60, 38, 30], [36, 55, 37, 28], [75, 60, 33, 30], [-4, 92, 50, 16], [48, 85, 60, 23]].forEach(([x, y, w, h]) => {
          const p = wobRect(x + 1.2, y + 1.2, w - 2.4, h - 2.4, 6, r, 1.6);
          s += '<path d="' + p + '" fill="#9DA192" transform="translate(1.3 1.7)"/><path d="' + p + '" fill="' + tones[(r() * 4) | 0] + '"/>';
          s += '<path d="M' + f(x + 5 + r() * 3) + ' ' + f(y + 4.5) + 'q' + f(w * 0.25) + ' ' + f(-1 + J(r, 0.6)) + ' ' + f(w * 0.45) + ' 0" stroke="#E4E6DA" stroke-width="1.2" fill="none" stroke-linecap="round"/>';
        });
        s += '<path d="M82 66l3 4l-1 4l3 3" stroke="#7F8476" stroke-width=".9" fill="none" stroke-linecap="round"/>';
        const pts = []; for (let x = -4; x <= 108; x += 5.6) pts.push([x, 87 + J(r, 3.2) - (x > 40 && x < 62 ? 1.5 : 0)]);
        const clump = 'M-4 108' + smooth(pts, false).replace('M', 'L') + 'L108 108Z';
        s += '<path d="' + clump + '" fill="#5E9A35"/><path d="' + clump + '" fill="#79B443" transform="translate(0 -2.5)" stroke="#1E2A0E" stroke-width="1.8"/>';
        s += '<path d="' + clump + '" fill="#5E9A35" transform="translate(0 6)"/>';
        for (let k = 0; k < 9; k++) s += '<circle cx="' + f(4 + r() * 96) + '" cy="' + f(89 + r() * 4) + '" r="' + f(0.8 + r() * 1.1) + '" fill="#A9D86A"/>';
        const side = (cx, cy, rx, ry) => { const p = blob(cx, cy, rx, ry, 9, 0.22, r); return '<path d="' + p + '" fill="#5E9A35" transform="translate(1.2 1.6)"/><path d="' + p + '" fill="#79B443" stroke="#1E2A0E" stroke-width="1.6"/><circle cx="' + f(cx + rx * 0.2) + '" cy="' + f(cy - ry * 0.3) + '" r="1.2" fill="#A9D86A"/>'; };
        s += side(1, 63, 8.5, 15) + side(103, 41, 8, 12);
        s += '<path d="M79 86c0 -3 -1 -5 -3 -7" stroke="#1E2A0E" stroke-width="1.3" fill="none" stroke-linecap="round"/><path d="M76 79c-4 -1 -7 1 -7 3c3 1 6 0 7 -3Z" fill="#9BCB5C" stroke="#1E2A0E" stroke-width="1.1"/><path d="M78 81c2 -4 6 -5 8 -3c-2 3 -5 4 -8 3Z" fill="#79B443" stroke="#1E2A0E" stroke-width="1.1"/>';
        return s;
      },
    },
    die_r_aqua: {
      tier: 2, name: 'Tidescale', tag: 'Mastery · Aquatic', border: '#000', calm: ['#A3E2F4', '#74C6E0'], wob: [1.3, 0.06, 15], gr: 0.12,
      spec: ['Border #000, 4 px.', 'Two materials: hand-placed scales (each one a slightly different size, some with a highlight tick) and a curling wave with foam hooks along the bottom.', 'Bubbles come in uneven clusters on the left and right edges, each with a highlight dot at the upper left.', 'Inner lines #0B3E57 (deep sea blue) instead of black. Grain 12 %.'],
      plate(o) {
        const r = rng(37);
        let s = '<rect width="104" height="104" fill="#A3E2F4"/>', d = '', hi = '';
        for (let row = 0; row < 17; row++) { const y = row * 6.4 - 2 + J(r, 0.4), off = (row % 2) * 5.6; for (let x = -11 + off; x < 110; x += 11.2) { const sz = 5.3 + J(r, 0.6), xx = x + J(r, 0.5); d += 'M' + f(xx) + ' ' + f(y) + 'a' + f(sz) + ' ' + f(sz * 0.95) + ' 0 0 0 ' + f(sz * 2) + ' 0'; if (r() < 0.3) hi += 'M' + f(xx + sz * 0.5) + ' ' + f(y + sz * 0.45) + 'q' + f(sz * 0.3) + ' ' + f(sz * 0.3) + ' ' + f(sz * 0.8) + ' ' + f(sz * 0.25); } }
        s += '<path d="' + d + '" stroke="#74C6E0" stroke-width="1.2" fill="none"/><path d="' + hi + '" stroke="#D6F5FD" stroke-width="1" fill="none" stroke-linecap="round"/>';
        const wp = [[-3, 94], [8, 88.5], [17, 93], [30, 86], [41, 92.5], [55, 87.5], [66, 92], [79, 85.5], [90, 93], [99, 88], [107, 92]];
        const wave = 'M-3 108' + smooth(wp, false).replace('M', 'L') + 'L107 108Z';
        s += '<path d="' + wave + '" fill="#39C5F3" stroke="#0B3E57" stroke-width="1.8" stroke-linejoin="round"/><path d="' + wave + '" fill="#1FA6D9" transform="translate(0 7)"/>';
        [[8, 88.5], [30, 86], [55, 87.5], [79, 85.5], [99, 88]].forEach(([x, y], k) => (s += '<path d="M' + f(x - 5) + ' ' + f(y + 2.2) + 'q' + f(2.6) + ' ' + f(-4.6 - (k % 2)) + ' ' + f(6.8) + ' -1.4q-1.2 .4 -1.6 1.8" stroke="#F2FCFF" stroke-width="1.9" fill="none" stroke-linecap="round"/>'));
        const bub = (x, y, rr) => '<circle cx="' + x + '" cy="' + y + '" r="' + rr + '" fill="#E9FAFF" stroke="#0B3E57" stroke-width="1.3"/><path d="M' + f(x + rr * 0.1) + ' ' + f(y + rr * 0.85) + 'a' + rr * 0.9 + ' ' + rr * 0.9 + ' 0 0 0 ' + f(rr * 0.75) + ' ' + f(-rr * 0.9) + '" stroke="#9EDCF0" stroke-width="1" fill="none"/><circle cx="' + f(x - rr * 0.38) + '" cy="' + f(y - rr * 0.38) + '" r="' + f(rr * 0.24) + '" fill="#FFFFFF"/>';
        return s + bub(6, 66, 3.7) + bub(8.4, 73.6, 2.1) + bub(4.6, 78.6, 1.4) + bub(96.5, 38, 4.4) + bub(99, 47.5, 2.3) + bub(92.6, 31, 1.6);
      },
    },
    die_e_rune: {
      tier: 3, name: 'Mystic Runestone', border: '#2A0F45', calm: ['#D6C4F2', '#CDB8EE', '#DED0F6'], wob: [1.4, 0.05, 21], gr: 0.18,
      spec: ['Border #2A0F45 (deep violet), 4 px. Reads as black at 36 px.', 'Ornament: a chiselled groove frame and four amethysts in the corners, each cut differently. The runes are carved (dark groove plus light lower lip), placed by hand, a few slightly tilted.', 'glow.png: rune underlay #BF6BFF, 5 px, blend Add. Idle: pulse 0.35→0.9, 2.0 s ease-in-out. Reduce flashing: 0.55→0.7.', 'Grain 18 % for the stone tooth.'],
      plate(o) {
        const r = rng(41);
        let s = '<rect width="104" height="104" fill="#D6C4F2"/>';
        [[22, 40, 14, 8, '#CDB8EE'], [76, 70, 16, 9, '#CDB8EE'], [50, 56, 18, 7, '#DED0F6'], [16, 74, 9, 6, '#DED0F6']].forEach(([x, y, rx, ry, c]) => (s += '<path d="' + blob(x, y, rx, ry, 8, 0.25, r) + '" fill="' + c + '"/>'));
        const fr = wobRect(7, 7, 90, 90, 12, r, 0.7);
        s += '<path d="' + fr + '" fill="none" stroke="#EFE6FC" stroke-width="1" transform="translate(.9 .9)"/><path d="' + fr + '" fill="none" stroke="#9C78D8" stroke-width="2.3"/>';
        s += '<path d="M0 70l4 1.5l-1 3.5l-3 .8Z" fill="#A688D6"/><path d="M104 54l-3.4 1l.6 3.4l2.8 1Z" fill="#A688D6"/>';
        let glyph = '';
        [[19.5, 0], [33.5, 1], [48.5, 2], [62.5, 3], [77, 4]].forEach(([x, i]) => { glyph += '<path transform="translate(' + f(x - 4.5 + J(r, 0.6)) + ' ' + f(85.5 + J(r, 0.8)) + ') rotate(' + f(J(r, 7)) + ' 5 6) scale(' + f(0.86 + r() * 0.1) + ')" d="' + RUNES[i] + '"/>'; });
        glyph += '<path transform="translate(1.8 57) rotate(-4 5 6) scale(.74)" d="' + RUNES[1] + '"/><path transform="translate(94.6 59) rotate(5 5 6) scale(.74)" d="' + RUNES[4] + '"/>';
        s += '<g stroke="#BF6BFF" stroke-width="5" stroke-linecap="round" fill="none" opacity="' + (o.static ? 0.55 : 0.35) + '" style="' + A(o, 'cosPulse', 2) + '">' + glyph + '</g>';
        s += '<g stroke="#F3ECFD" stroke-width="1" stroke-linecap="round" fill="none" transform="translate(.7 .8)">' + glyph + '</g>';
        s += '<g stroke="#4A1F86" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round" fill="none">' + glyph + '</g>';
        const gem = (cx, cy, rr, rot) => { const pts = []; for (let i = 0; i < 6; i++) { const t = rot + (i / 6) * Math.PI * 2; pts.push([cx + Math.cos(t) * rr * (1 + J(r, 0.18)), cy + Math.sin(t) * rr * (1 + J(r, 0.18))]); } const P2 = (p) => f(p[0]) + ' ' + f(p[1]); return '<path d="M' + pts.map(P2).join('L') + 'Z" fill="#BF6BFF"/><path d="M' + P2(pts[3]) + 'L' + P2(pts[4]) + 'L' + P2(pts[5]) + 'L' + cx + ' ' + cy + 'Z" fill="#E6C8FF"/><path d="M' + P2(pts[0]) + 'L' + P2(pts[1]) + 'L' + P2(pts[2]) + 'L' + cx + ' ' + cy + 'Z" fill="#7A3BC7"/><path d="M' + pts.map(P2).join('L') + 'Z" fill="none" stroke="#2A0F45" stroke-width="1.6" stroke-linejoin="round"/>'; };
        return s + gem(7.5, 96.5, 6, 0.3) + gem(96.5, 97, 5.4, 0.9) + gem(7, 39, 4.2, 0.1) + gem(97, 40.5, 4.6, 0.6);
      },
    },
    die_l_gold: {
      tier: 4, name: 'Genesis Sunplate', border: '#3A2205', calm: ['#FFD46A', '#FFE59A', '#F2BE4E'], wob: [1.3, 0.05, 29], gr: 0.12,
      spec: ['Border #3A2205 (dark bronze), 4 px.', 'Ornament: hand-hammered gold (scattered dents, each with a lit and a shaded edge), a carved half-sun with uneven flame tongues, filigree scrolls in both bottom corners and two rivets.', 'glow.png: diagonal sheen band, white 50 %, blend Add. Idle: the sheen sweeps across in 1.1 s, then rests. 3.2 s loop. Reduce flashing: sheen at 20 %.'],
      plate(o) {
        const r = rng(53);
        let s = '<rect width="104" height="104" fill="#FFD46A"/>';
        for (let a = 196; a < 344;) { const w = 4.4 + J(r, 1), L = 80 + r() * 40, [x1, y1] = P(L, a, 52, 108), [x2, y2] = P(L, a + w, 52, 108); s += '<path d="M52 108L' + x1 + ' ' + y1 + 'L' + x2 + ' ' + y2 + 'Z" fill="#FFE59A"/><path d="M52 108L' + x2 + ' ' + y2 + '" stroke="#EDB548" stroke-width=".8"/>'; a += w + 6 + J(r, 1.5); }
        for (let k = 0; k < 22; k++) { const x = r() * 104, y = 26 + r() * 74, rx = 2.2 + r() * 2.4; s += '<ellipse cx="' + f(x) + '" cy="' + f(y) + '" rx="' + f(rx) + '" ry="' + f(rx * 0.7) + '" fill="#F2BE4E" opacity=".55"/><path d="M' + f(x - rx * 0.7) + ' ' + f(y + rx * 0.2) + 'q' + f(rx * 0.4) + ' ' + f(-rx * 0.8) + ' ' + f(rx * 1.2) + ' ' + f(-rx * 0.5) + '" stroke="#FFF0B8" stroke-width=".8" fill="none" stroke-linecap="round"/>'; }
        const fr = wobRect(6, 6, 92, 92, 12, r, 0.6);
        s += '<path d="' + fr + '" fill="none" stroke="#FFF0B8" stroke-width=".9" transform="translate(.8 .8)"/><path d="' + fr + '" fill="none" stroke="#D99A22" stroke-width="1.8"/>';
        [202, 216, 231, 244, 296, 309, 323, 337].forEach((a) => { const L = 26 + r() * 4, [x1, y1] = P(20, a - 3, 52, 108), [tx, ty] = P(L, a + 2, 52, 108), [x2, y2] = P(20, a + 4, 52, 108); s += '<path d="M' + x1 + ' ' + y1 + 'Q' + f((x1 + tx) / 2 - 1.5) + ' ' + f((y1 + ty) / 2) + ' ' + tx + ' ' + ty + 'Q' + f((x2 + tx) / 2 + 1) + ' ' + f((y2 + ty) / 2) + ' ' + x2 + ' ' + y2 + 'Z" fill="#F4AE33" stroke="#3A2205" stroke-width="1.4" stroke-linejoin="round"/>'; });
        s += '<path d="' + blob(52, 108, 19, 19, 12, 0.03, r) + '" fill="#F4AE33" stroke="#3A2205" stroke-width="2.2"/><path d="' + blob(52, 108, 12, 12, 10, 0.05, r) + '" fill="#FFC94A" stroke="#B9781A" stroke-width="1.2"/><path d="M38 100q5 -7 13 -8" stroke="#FFE08A" stroke-width="2" fill="none" stroke-linecap="round"/>';
        s += '<path d="M9 97c-1 -5 4 -8 7 -5c2 2 0 5 -2 4M95 97c1 -5 -4 -8 -7 -5c-2 2 0 5 2 4" stroke="#8A5A12" stroke-width="1.3" fill="none" stroke-linecap="round"/>';
        s += '<circle cx="12.5" cy="86" r="3.2" fill="#F4AE33" stroke="#3A2205" stroke-width="1.6"/><circle cx="11.6" cy="85" r="1" fill="#FFF0B8"/><circle cx="91.5" cy="86.5" r="3.2" fill="#F4AE33" stroke="#3A2205" stroke-width="1.6"/><circle cx="90.6" cy="85.5" r="1" fill="#FFF0B8"/>';
        s += '<g style="' + A(o, 'cosSheen', 3.2) + '"><path d="M-40 0H-24L-54 104H-70Z" fill="#FFFFFF" opacity=".5"/><path d="M-20 0H-16L-46 104H-50Z" fill="#FFFFFF" opacity=".4"/></g>';
        return s;
      },
    },
    die_m_redcrystal: {
      tier: 5, name: 'Luna Redcrystal', border: '#1E0410', calm: ['#FFE8EE'], dark: true, wob: [1.3, 0.05, 33], gr: 0.08,
      spec: ['Dark skin, so it gets a LIGHT VALUE PLATE: #FFE8EE, hand-cut edge, 3 px #1E0410 outline, sized to the calm zone (x −0.40…+0.40 s, y −0.06…+0.30 s). Ink stays #1A1206.', 'Border #1E0410, 4 px. Field: starlit plum #2A0F2E with nebula patches #3A1640.', 'Signature: a cratered crescent moon and faceted red crystals (light face #FF6F93, dark face #B0173F, highlight #FFE8EE). Clusters lean at different angles.', 'Idle: 3 uneven sparkles twinkle 1.6 s, staggered; crystal glint 2.8 s. Reduce flashing: opacity only, no scale.', 'MAX settle: the crescent fills to a full moon for 0.6 s while the crystals grow 1→1.15 (ease-out-back). Reduced: crystals only.'],
      plate(o) {
        const r = rng(61);
        let s = '<rect width="104" height="104" fill="#2A0F2E"/>';
        s += '<path d="' + blob(20, 38, 22, 9, 9, 0.3, r) + '" fill="#3A1640"/><path d="' + blob(86, 92, 20, 10, 9, 0.3, r) + '" fill="#331338"/>';
        [[18, 33], [44, 29], [71, 41], [8, 94], [97, 71], [30, 41], [53, 38], [98, 54], [4, 52]].forEach(([x, y]) => (s += '<circle cx="' + x + '" cy="' + y + '" r="' + f(0.5 + r() * 0.8) + '" fill="#C9A3CF"/>'));
        s += crescentHD(87, 35.5, 8.8, '#E9C7D2', 1.5);
        [[7, 35.5, 4.2, 3, 0], [61, 32, 3, 2.2, 0.5], [5.5, 86, 2.8, 2, 1.1]].forEach(([x, y, rv, rh, d]) => (s += twinkle(x, y, rv, rh, '#FFE8EE', A(o, 'cosTwinkle', 1.6, 'ease-in-out ' + d + 's infinite'))));
        const C1 = ['#FF6F93', '#B0173F', '#7A0E2C'], C2 = ['#FF3D6E', '#8E1234', '#5A0A20'];
        s += crystal(4, 104, 15, 7, -1.5, C2, 1.6) + crystal(15, 104, 21, 9, 2, C1, 1.8) + crystal(25, 104, 11, 6, 2.5, C2, 1.5);
        s += crystal(100, 104, 13, 7, 1.5, C2, 1.6) + crystal(89, 104, 19, 8.5, -2.5, C1, 1.8) + crystal(79, 104, 9, 5.5, -1, C2, 1.4) + crystal(52, 104, 9, 6, 1, C1, 1.4);
        s += '<path d="' + wobRect(CZ.x, CZ.y, CZ.w, CZ.h, 10, r, 0.5) + '" fill="#FFE8EE" stroke="#1E0410" stroke-width="3"/><path d="M' + f(CZ.x + 8) + ' ' + f(CZ.y + CZ.h - 4) + 'Q52 ' + f(CZ.y + CZ.h - 2.6) + ' ' + f(CZ.x + CZ.w - 8) + ' ' + f(CZ.y + CZ.h - 4.4) + '" stroke="#F2C9D5" stroke-width="2" fill="none" stroke-linecap="round"/>';
        s += twinkle(14, 87, 3.4, 2.2, '#FFFFFF', A(o, 'cosTwinkle', 2.8, 'ease-in-out 0.6s infinite'));
        return s;
      },
    },
  };
  Object.values(DIE).forEach((d) => { d.contrast = Math.min(...d.calm.map((c) => contrast(c, INK))); });
  const platePack = (id, o, u) => { const d = DIE[id]; return '<g filter="url(#w' + u + ')">' + d.plate(o) + '</g>' + grain(u, 104, 104, d.gr); };
  const plateDefs = (id, u) => { const w = DIE[id].wob; return defsFor(u, w[0], w[1], w[2], 0.55); };

  function plateSVG(id, o = {}) {
    const u = ++uid;
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 104 104" width="' + (o.size || 512) + '" height="' + (o.size || 512) + '"><defs>' + plateDefs(id, u) + '<clipPath id="cp' + u + '"><rect width="104" height="104"/></clipPath></defs><g clip-path="url(#cp' + u + ')">' + platePack(id, o, u) + '</g></svg>';
  }
  const CLASS = { plant: '#7DC943', aqua: '#39C5F3', beast: '#FFB23F', reptile: '#B679F7', bug: '#F2624F', bird: '#8BDCFF' };
  // Full die; code-drawn layers (band, value, chip) stay crisp exactly as reroll_die.gd draws them.
  function dieSVG(id, s, o = {}) {
    const d = DIE[id], k = 104 / s, bw = (s <= 40 ? 3 : 4) * k, u = ++uid;
    const cls = CLASS[o.cls || 'plant'], val = String(o.value ?? 6), type = o.type || 'dmg';
    const fs = 41.6, iw = 31.2, gap = 6.24, tw = 0.56 * fs * val.length, x0 = -(tw + gap + iw) / 2 + 52, cy = 52 + 12.48;
    const R = 18.72, h = bw / 2;
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 104 104" width="' + s + '" height="' + s + '" style="display:block;overflow:visible"><defs>' + plateDefs(id, u) + '<clipPath id="cd' + u + '"><rect width="104" height="104" rx="' + R + '"/></clipPath></defs>' +
      '<g clip-path="url(#cd' + u + ')">' + platePack(id, o, u) + '</g>' +
      '<path d="M' + h + ' 24.96V' + R + 'A' + (R - h) + ' ' + (R - h) + ' 0 0 1 ' + R + ' ' + h + 'H' + (104 - R) + 'A' + (R - h) + ' ' + (R - h) + ' 0 0 1 ' + (104 - h) + ' ' + R + 'V24.96Z" fill="' + cls + '" stroke="#000" stroke-width="' + bw + '"/>' +
      '<text x="' + x0 + '" y="' + cy + '" dominant-baseline="central" font-family="\'Baloo 2\',cursive" font-weight="800" font-size="' + fs + '" fill="' + INK + '" dy="2">' + val + '</text>' +
      '<rect x="' + (x0 + tw + gap) + '" y="' + (cy - iw / 2) + '" width="' + iw + '" height="' + iw + '" rx="7" fill="' + TYPE[type] + '" stroke="#000" stroke-width="' + (bw / k - 1) * k + '"/>' +
      '<image href="assets/icons/' + type + '.png" x="' + (x0 + tw + gap + iw * 0.18) + '" y="' + (cy - iw / 2 + iw * 0.18) + '" width="' + iw * 0.64 + '" height="' + iw * 0.64 + '"/>' +
      '<rect x="' + h + '" y="' + h + '" width="' + (104 - bw) + '" height="' + (104 - bw) + '" rx="' + (R - h) + '" fill="none" stroke="' + d.border + '" stroke-width="' + bw + '"/></svg>';
  }

  // ---------- AVATAR FRAMES (256 canvas, window = circle Ø168 at centre) ----------
  // leaf along +x, length L, half-width W, tip curl c; shadow on the lower half (light from top-left)
  function leafHD(L, W, c, r, col, shade, rib, sw) {
    const a1 = W * (1 + J(r, 0.15)), a2 = W * (0.85 + J(r, 0.15)), b1 = W * (0.75 + J(r, 0.15)), b2 = W * (0.65 + J(r, 0.1));
    const out = 'M0 0C' + f(L * 0.28) + ' ' + f(-a1) + ' ' + f(L * 0.72) + ' ' + f(-a2) + ' ' + f(L) + ' ' + f(c) + 'C' + f(L * 0.7) + ' ' + f(b2) + ' ' + f(L * 0.3) + ' ' + f(b1) + ' 0 0Z';
    const low = 'M0 0Q' + f(L * 0.5) + ' ' + f(c * 0.4 + W * 0.08) + ' ' + f(L) + ' ' + f(c) + 'C' + f(L * 0.7) + ' ' + f(b2) + ' ' + f(L * 0.3) + ' ' + f(b1) + ' 0 0Z';
    return '<path d="' + out + '" fill="' + col + '"/><path d="' + low + '" fill="' + shade + '"/><path d="M' + f(L * 0.06) + ' 0Q' + f(L * 0.5) + ' ' + f(c * 0.4 + W * 0.08) + ' ' + f(L * 0.88) + ' ' + f(c * 0.9) + '" stroke="' + rib + '" stroke-width="' + f(sw * 0.5) + '" fill="none" stroke-linecap="round"/><path d="M' + f(L * 0.2) + ' ' + f(-W * 0.5) + 'q' + f(L * 0.15) + ' ' + f(-W * 0.25) + ' ' + f(L * 0.32) + ' ' + f(-W * 0.2) + '" stroke="#D8F5A8" stroke-width="' + f(sw * 0.45) + '" fill="none" stroke-linecap="round" opacity=".8"/><path d="' + out + '" fill="none" stroke="#000" stroke-width="' + sw + '" stroke-linejoin="round"/>';
  }
  // band = shadow colour underneath, light colour on top nudged up-left and clipped to the band
  const shadedBand = (u, path, dark, light, extra) => '<path d="' + path + '" fill="' + dark + '" fill-rule="evenodd"/><g clip-path="url(#cb' + u + ')"><path d="' + path + '" fill="' + light + '" fill-rule="evenodd" transform="translate(-2.4 -3.2)"/></g>' + (extra || '') + '<path d="' + path + '" fill="none" stroke="#000" stroke-width="4" stroke-linejoin="round"/>';
  const FRAME = {
    frame_c_plant: {
      tier: 0, name: 'Sprout Ring', tag: 'Mastery · Plant', seed: 101,
      spec: ['Static. A vine band (r 82–97, lumpy outer edge), lit #6DB33B over shade #4E8F2A, with bark ticks #2F5E14.', '11 leaves in uneven sizes (24–36 px), denser at the upper left and sparser at the lower right. Each leaf has a shaded lower half and a rib.', 'A sprout leaning 8° off the 12 o’clock, two unequal leaves and a curling tendril. This is the 40 px silhouette cue. One cream bud at 4 o’clock.', 'Shelf shadow: black 50 %, offset (0, 6), no blur. Line boil 3 px.'],
      base(o, u) {
        const r = rng(this.seed); let s = '';
        const band = ringBlob(82, 97, r, 0.03);
        const angs = [-152, -131, -112, -58, -36, -12, 22, 58, 101, 147, 171, 204];
        angs.forEach((a, i) => { const [x, y] = P(94 + r() * 5, a); const L = 24 + r() * 12; s += '<g transform="translate(' + x + ' ' + y + ') rotate(' + f(a + (i % 2 ? 1 : -1) * (28 + r() * 22)) + ')">' + leafHD(L, L * 0.34, J(r, 3), r, i % 3 ? '#8ED158' : '#6DB33B', '#4E8F2A', '#2F5E14', 3) + '</g>'; });
        let ticks = ''; for (let k = 0; k < 12; k++) { const a = k * 30 + J(r, 9), rr = 86 + r() * 8; const [x1, y1] = P(rr, a), [x2, y2] = P(rr + J(r, 1.5), a + 5 + r() * 6); ticks += 'M' + x1 + ' ' + y1 + 'Q' + f((x1 + x2) / 2 + J(r, 2)) + ' ' + f((y1 + y2) / 2 + J(r, 2)) + ' ' + x2 + ' ' + y2; }
        s += shadedBand(u, band, '#4E8F2A', '#6DB33B', '<path d="' + ticks + '" stroke="#2F5E14" stroke-width="1.6" fill="none" stroke-linecap="round"/>');
        s += '<path d="M126 33C124 26 127 20 133 16" stroke="#000" stroke-width="8" fill="none" stroke-linecap="round"/><path d="M126 33C124 26 127 20 133 16" stroke="#4E8F2A" stroke-width="3.5" fill="none" stroke-linecap="round"/>';
        s += '<path d="M131 22c8 -2 12 4 9 8c-2 3 -6 2 -6 -1" stroke="#000" stroke-width="6" fill="none" stroke-linecap="round"/><path d="M131 22c8 -2 12 4 9 8c-2 3 -6 2 -6 -1" stroke="#6DB33B" stroke-width="2.4" fill="none" stroke-linecap="round"/>';
        s += '<g transform="translate(133 17) rotate(-140)">' + leafHD(46, 16, -3, r, '#8ED158', '#4E8F2A', '#2F5E14', 3.5) + '</g><g transform="translate(133 17) rotate(-48)">' + leafHD(35, 12, 2, r, '#6DB33B', '#4E8F2A', '#2F5E14', 3.5) + '</g>';
        const [bx, by] = P(99, 32);
        s += '<path d="' + blob(bx, by, 7, 6, 7, 0.15, r) + '" fill="#FFF1A8" stroke="#000" stroke-width="3"/><path d="M' + f(bx - 3) + ' ' + f(by - 1) + 'q2 -3 5 -2" stroke="#FFFFFF" stroke-width="1.6" fill="none" stroke-linecap="round"/><path d="M' + f(bx + 1) + ' ' + f(by + 2) + 'q3 1 4 -2" stroke="#D9C26A" stroke-width="1.4" fill="none" stroke-linecap="round"/>';
        return s;
      },
      band: (r) => ringBlob(82, 97, r, 0.03),
    },
    frame_u_mushroom: {
      tier: 1, name: 'Toadstool Log', seed: 202,
      spec: ['Static. A log ring (r 82–97) with bark #A8693A over shade #7E4A24, about 30 hand-placed bark strokes #6E3F1C, a knot at 2 o’clock and a small moss patch.', 'Five mushrooms, all different: a big leaning toadstool at 8 o’clock, a squat one beside it, two babies, and a tan pair at 1 o’clock. Caps carry a shaded underside, gills and uneven spots.', 'The asymmetric clusters are what read at 40 px.'],
      base(o, u) {
        const r = rng(this.seed); let s = '';
        const band = ringBlob(82, 97, r, 0.025);
        let bark = ''; for (let k = 0; k < 30; k++) { const a = r() * 360, rr = 85 + r() * 10; const [x1, y1] = P(rr, a), [x2, y2] = P(rr + J(r, 1), a + 3 + r() * 5); bark += 'M' + x1 + ' ' + y1 + 'L' + x2 + ' ' + y2; }
        const [kx, ky] = P(90, 22);
        s += shadedBand(u, band, '#7E4A24', '#A8693A', '<path d="' + bark + '" stroke="#6E3F1C" stroke-width="1.5" stroke-linecap="round"/><path d="' + blob(kx, ky, 5.5, 4, 8, 0.15, r) + '" fill="#6E3F1C" stroke="#3E2010" stroke-width="1.4"/><path d="' + blob(kx, ky, 2.4, 1.8, 6, 0.2, r) + '" fill="#3E2010"/>');
        const [mx, my] = P(97, -128);
        s += '<path d="' + blob(mx, my, 13, 6, 9, 0.3, r, -0.6) + '" fill="#5E9A35" stroke="#000" stroke-width="3"/><circle cx="' + f(mx - 3) + '" cy="' + f(my - 2) + '" r="1.5" fill="#A9D86A"/><circle cx="' + f(mx + 4) + '" cy="' + f(my) + '" r="1.1" fill="#A9D86A"/>';
        const grass = (a, h) => { const [x, y] = P(96, a); return '<g transform="translate(' + x + ' ' + y + ') rotate(' + (a + 90) + ')"><path d="M-8 2Q-8 -6 -10 -' + f(h * 0.7) + 'Q-5 -4 -3 1Q-1 -8 1 -' + f(h) + 'Q2 -6 4 0Q6 -6 9 -' + f(h * 0.6) + 'Q8 -2 8 2Z" fill="#79B443" stroke="#000" stroke-width="2.4" stroke-linejoin="round"/></g>'; };
        s += grass(100, 13) + grass(80, 9) + grass(166, 11) + grass(-18, 8);
        const mush = (a, sc, cap, shade, lean, squat) => {
          const [x, y] = P(93, a), hh = squat ? 14 : 22;
          const capP = 'M-25 ' + (-hh + 2) + 'C-27 ' + (-hh - 18) + ' -8 ' + (-hh - 27) + ' 3 ' + (-hh - 26) + 'C18 ' + (-hh - 24) + ' 27 ' + (-hh - 12) + ' 25 ' + (-hh + 2) + 'C11 ' + (-hh + 6) + ' -11 ' + (-hh + 6) + ' -25 ' + (-hh + 2) + 'Z';
          const capS = 'M-12 ' + (-hh + 4) + 'C6 ' + (-hh + 5) + ' 18 ' + (-hh + 3) + ' 25 ' + (-hh + 2) + 'C26 ' + (-hh - 6) + ' 23 ' + (-hh - 13) + ' 19 ' + (-hh - 17) + 'C19 ' + (-hh - 8) + ' 8 ' + (-hh + 1) + ' -12 ' + (-hh + 4) + 'Z';
          let sp = ''; [[-12, -hh - 10, 4.4], [6, -hh - 17, 3], [15, -hh - 7, 2.6], [-3, -hh - 4, 1.8]].forEach(([sx, sy, sr]) => (sp += '<path d="' + blob(sx, sy, sr, sr * 0.85, 6, 0.2, r) + '" fill="#FFF1D6"/>'));
          return '<g transform="translate(' + x + ' ' + y + ') rotate(' + (a + 90 + lean) + ') scale(' + sc + ')"><path d="M-7 1C-8 -6 -6 -' + (hh - 6) + ' -5 -' + hh + 'L6 -' + hh + 'C6 -' + (hh - 7) + ' 9 -6 8 1Z" fill="#FFF1D6" stroke="#000" stroke-width="3" stroke-linejoin="round"/><path d="M3 -' + (hh - 1) + 'C4 -' + (hh - 8) + ' 6 -6 6 0" stroke="#E2CDA6" stroke-width="2.5" fill="none"/>' +
            '<path d="M-21 ' + (-hh + 1) + 'Q0 ' + (-hh + 8) + ' 21 ' + (-hh + 1) + 'Z" fill="#E8D2AE"/><path d="M-12 ' + (-hh + 2.5) + 'l2 3M-4 ' + (-hh + 3.5) + 'l0.5 3.2M4 ' + (-hh + 3.5) + 'l-.5 3.2M12 ' + (-hh + 2.5) + 'l-2 3" stroke="#B89870" stroke-width="1.3" stroke-linecap="round"/>' +
            '<path d="' + capP + '" fill="' + cap + '"/><path d="' + capS + '" fill="' + shade + '"/>' + sp + '<path d="M-18 ' + (-hh - 10) + 'q4 -9 13 -11" stroke="#FFFFFF" stroke-width="2.2" fill="none" stroke-linecap="round" opacity=".85"/><path d="' + capP + '" fill="none" stroke="#000" stroke-width="3" stroke-linejoin="round"/></g>';
        };
        s += mush(152, 0.62, '#E8A45A', '#C07A34', 8, true) + mush(112, 0.55, '#F2624F', '#C43E30', -10, false) + mush(131, 1.08, '#F2624F', '#C43E30', 14, false) + mush(-64, 0.6, '#E8A45A', '#C07A34', -6, false) + mush(-42, 0.8, '#E8A45A', '#C07A34', 10, true);
        return s;
      },
      band: (r) => ringBlob(82, 97, r, 0.025),
    },
    frame_r_frost: {
      tier: 2, name: 'Frost Crown', seed: 303,
      spec: ['Static. Two materials: chunky ice (r 82–99, faceted in three tints #CFF1FF / #A8DEF7 / #E3F8FF) and soft snow.', 'An uneven six-spike crown that leans slightly right, with a lit left face and a shaded right face #9ED8F2. This is the 40 px silhouette.', 'Four icicles of different lengths at the bottom, a lumpy snow clump on the left and one hand-drawn snowflake at 2 o’clock.'],
      base(o, u) {
        const r = rng(this.seed); let s = '';
        [[-118, 34, 8.5, 2], [-95, 50, 10, 4], [-73, 31, 8, 3], [-140, 21, 7, 1], [-52, 19, 6.5, 2], [-84, 15, 4.5, 1]].forEach(([a, L, hw, lean]) => { const [b1x, b1y] = P(96, a - hw), [b2x, b2y] = P(96, a + hw), [tx, ty] = P(96 + L, a + lean), [mx, my] = P(96, a + lean * 0.3); s += '<path d="M' + b1x + ' ' + b1y + 'L' + tx + ' ' + ty + 'L' + b2x + ' ' + b2y + 'Z" fill="#E9FAFF"/><path d="M' + mx + ' ' + my + 'L' + tx + ' ' + ty + 'L' + b2x + ' ' + b2y + 'Z" fill="#9ED8F2"/><path d="M' + f((b1x + mx) / 2) + ' ' + f((b1y + my) / 2) + 'L' + f(tx * 0.7 + b1x * 0.3) + ' ' + f(ty * 0.7 + b1y * 0.3) + '" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/><path d="M' + b1x + ' ' + b1y + 'L' + tx + ' ' + ty + 'L' + b2x + ' ' + b2y + '" fill="none" stroke="#000" stroke-width="3" stroke-linejoin="round"/>'; });
        const band = ringBlob(82, 99, r, 0.045, 0.01);
        let facets = '', a0 = 0; const tints = ['#CFF1FF', '#A8DEF7', '#E3F8FF', '#BFE8FB'];
        let k = 0; while (a0 < 360) { const w = 12 + r() * 12, [i1x, i1y] = P(80, a0), [o1x, o1y] = P(104, a0 + J(r, 3)), [o2x, o2y] = P(104, a0 + w + J(r, 3)), [i2x, i2y] = P(80, a0 + w); facets += '<path d="M' + i1x + ' ' + i1y + 'L' + o1x + ' ' + o1y + 'L' + o2x + ' ' + o2y + 'L' + i2x + ' ' + i2y + 'Z" fill="' + tints[k++ % 4] + '"/>'; a0 += w; }
        s += '<path d="' + band + '" fill="#A8DEF7" fill-rule="evenodd"/><g clip-path="url(#cb' + u + ')">' + facets + '</g><path d="' + band + '" fill="none" stroke="#000" stroke-width="4" stroke-linejoin="round"/>';
        [[71, 11], [84, 19], [99, 13], [112, 7]].forEach(([a, L]) => { const [b1x, b1y] = P(97, a - 3), [b2x, b2y] = P(97, a + 3), [tx, ty] = P(97 + L, a + 1); s += '<path d="M' + b1x + ' ' + b1y + 'Q' + f(tx - 1) + ' ' + f(ty - 2) + ' ' + tx + ' ' + ty + 'Q' + f(tx + 2) + ' ' + f(ty - 3) + ' ' + b2x + ' ' + b2y + 'Z" fill="#DDF5FF" stroke="#000" stroke-width="2.6" stroke-linejoin="round"/>'; });
        const pts = []; for (let a = 140; a <= 206; a += 8) pts.push(P(102 + J(r, 4) + (a > 160 && a < 190 ? 4 : 0), a));
        const back = []; for (let a = 206; a >= 140; a -= 13) back.push(P(88, a));
        const snow = smooth(pts.concat(back));
        s += '<path d="' + snow + '" fill="#CFE3EE" transform="translate(1 3)"/><path d="' + snow + '" fill="#FFFFFF" stroke="#000" stroke-width="3" stroke-linejoin="round"/>';
        const [fx0, fy0] = P(104, 28); let fl = '';
        for (let q = 0; q < 6; q++) { const t = q * 60 + 8 + J(r, 4), L = 9 + J(r, 1.5), [ex, ey] = P(L, t, fx0, fy0), [mx, my] = P(L * 0.55, t, fx0, fy0), [b1x, b1y] = P(3.4, t + 50, mx, my), [b2x, b2y] = P(3.4, t - 50, mx, my); fl += 'M' + fx0 + ' ' + fy0 + 'L' + ex + ' ' + ey + 'M' + mx + ' ' + my + 'L' + b1x + ' ' + b1y + 'M' + mx + ' ' + my + 'L' + b2x + ' ' + b2y; }
        s += '<path d="' + fl + '" stroke="#000" stroke-width="5.5" stroke-linecap="round"/><path d="' + fl + '" stroke="#FFFFFF" stroke-width="2.2" stroke-linecap="round"/>';
        return s;
      },
      band: (r) => ringBlob(82, 99, r, 0.045, 0.01),
    },
    frame_e_runering: {
      tier: 3, name: 'Runewheel', seed: 404,
      spec: ['Base (static): carved stone band r 82–97, lit #9255D8 over #7A3BC7, two hairline cracks #4A1F86 and four amethysts in different cuts, placed off-axis on purpose.', 'anim/rune_ring.png: outer band r 102–120 #BF6BFF with 11 carved runes, unevenly spaced. Rotates 360° in 16 s, linear. Its shelf shadow is a plain ring, so it stays static.', 'anim/rune_glow.png: rune underlay #F1E2FF 6 px, opacity 0.2→0.9, 2.0 s ease-in-out.', 'Reduce flashing: rotation unchanged (no change in brightness); glow 0.5→0.65.'],
      shadowExtra: '<path d="' + ring(102, 120) + '" fill-rule="evenodd"/>',
      base(o, u) {
        const r = rng(this.seed); let s = '';
        const band = ringBlob(82, 97, r, 0.02);
        const [c1x, c1y] = P(84, 150), [c2x, c2y] = P(84, -20);
        s += shadedBand(u, band, '#6A2FB4', '#9255D8', '<path d="M' + c1x + ' ' + c1y + 'l-4 5l2 4l-3 4M' + c2x + ' ' + c2y + 'l5 -2l2 3" stroke="#4A1F86" stroke-width="1.5" fill="none" stroke-linecap="round"/>');
        const gem = (a, rr, rot) => { const [cx, cy] = P(89.5, a), pts = []; for (let i = 0; i < 6; i++) { const t = rot + (i / 6) * Math.PI * 2; pts.push([cx + Math.cos(t) * rr * (1 + J(r, 0.2)), cy + Math.sin(t) * rr * 1.25 * (1 + J(r, 0.2))]); } const P2 = (p) => f(p[0]) + ' ' + f(p[1]); return '<path d="M' + pts.map(P2).join('L') + 'Z" fill="#F1E2FF"/><path d="M' + P2(pts[0]) + 'L' + P2(pts[1]) + 'L' + P2(pts[2]) + 'L' + f(cx) + ' ' + f(cy) + 'Z" fill="#C9A6F2"/><path d="M' + P2(pts[4]) + 'L' + P2(pts[5]) + 'L' + f(cx) + ' ' + f(cy) + 'Z" fill="#FFFFFF"/><path d="M' + pts.map(P2).join('L') + 'Z" fill="none" stroke="#000" stroke-width="3" stroke-linejoin="round"/>'; };
        return s + gem(-88, 9, 0.2) + gem(4, 8, 0.8) + gem(93, 9.5, 0.4) + gem(177, 8.4, 1.1);
      },
      anim(o) {
        const r = rng(405); let g = '', a = 4;
        for (let i = 0; i < 11; i++) { const [x, y] = P(111, a); g += '<path transform="translate(' + x + ' ' + y + ') rotate(' + f(a + 90 + J(r, 8)) + ') translate(-6 -7.2) scale(' + f(1.1 + r() * 0.2) + ')" d="' + RUNES[i % 6] + '"/>'; a += 27 + J(r, 6); }
        return '<g style="transform-origin:128px 128px;' + A(o, 'cosSpin', 16, 'linear infinite') + '"><path d="' + ring(102, 120) + '" fill="#A55BE6" fill-rule="evenodd"/><path d="' + ring(105, 120) + '" fill="#BF6BFF" fill-rule="evenodd"/><path d="' + ring(102, 120) + '" fill="none" stroke="#000" stroke-width="4"/>' +
          '<g stroke="#F1E2FF" stroke-width="6" stroke-linecap="round" fill="none" opacity="' + (o.static ? 0 : 0.2) + '" style="' + A(o, 'cosPulse', 2) + '">' + g + '</g><g stroke="#E6C8FF" stroke-width="1.1" stroke-linecap="round" fill="none" transform="translate(.8 .9)">' + g + '</g><g stroke="#2A0F45" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" fill="none">' + g + '</g></g>';
      },
      band: (r) => ringBlob(82, 97, r, 0.02),
    },
    frame_l_sunburst: {
      tier: 4, name: 'Genesis Sunburst', seed: 505,
      spec: ['Base (static): hammered gold band r 82–101, lit #FFD46A over #E9A93A, with an engraved wave scroll #B9781A, six oval Kam gems at uneven angles and a sun emblem set slightly off-centre at the top.', 'anim/rays.png (behind the base): 15 flame-shaped rays that bend and vary in length (long r 118–128, short r 106–114), #FFC94A / #FFB23F with a #FFE08A core line. Rotates 360° in 30 s, linear.', 'anim/glow.png: ring r 92, #FFF6D0 10 px, opacity 0→0.8→0, 2.4 s ease-in-out.', 'Reduce flashing: glow 0.3→0.45; the rays keep rotating.'],
      behind(o) {
        const r = rng(506); let s = '', a = 0;
        for (let i = 0; i < 15; i++) { const L = i % 2 ? 106 + r() * 8 : 118 + r() * 10, hw = 6 + r() * 2, bend = 4 + r() * 4, [x1, y1] = P(93, a - hw), [x2, y2] = P(93, a + hw), [tx, ty] = P(L, a + bend), [c1x, c1y] = P((93 + L) / 2, a - hw * 0.4 + bend * 0.2), [c2x, c2y] = P((93 + L) / 2, a + hw * 0.7 + bend * 0.6), [k1x, k1y] = P(97, a + bend * 0.1), [k2x, k2y] = P(L - 6, a + bend * 0.85);
          s += '<path d="M' + x1 + ' ' + y1 + 'Q' + c1x + ' ' + c1y + ' ' + tx + ' ' + ty + 'Q' + c2x + ' ' + c2y + ' ' + x2 + ' ' + y2 + 'Z" fill="' + (i % 2 ? '#FFB23F' : '#FFC94A') + '" stroke="#000" stroke-width="3" stroke-linejoin="round"/><path d="M' + k1x + ' ' + k1y + 'L' + k2x + ' ' + k2y + '" stroke="#FFE08A" stroke-width="2" stroke-linecap="round"/>'; a += 24 + J(r, 3); }
        return '<g style="transform-origin:128px 128px;' + A(o, 'cosSpin', 30, 'linear infinite') + '">' + s + '</g>';
      },
      base(o, u) {
        const r = rng(this.seed); let s = '';
        const band = ringBlob(82, 101, r, 0.02);
        let dents = ''; for (let k = 0; k < 26; k++) { const [x, y] = P(85 + r() * 13, r() * 360), rx = 2 + r() * 2; dents += '<ellipse cx="' + x + '" cy="' + y + '" rx="' + f(rx) + '" ry="' + f(rx * 0.7) + '" fill="#E9A93A" opacity=".6"/><path d="M' + f(x - rx * 0.7) + ' ' + f(y + rx * 0.1) + 'q' + f(rx * 0.4) + ' ' + f(-rx * 0.8) + ' ' + f(rx * 1.2) + ' ' + f(-rx * 0.5) + '" stroke="#FFF0B8" stroke-width="1" fill="none" stroke-linecap="round"/>'; }
        const wv = []; for (let a = 0; a < 360; a += 7) wv.push(P(91.5 + Math.sin((a * Math.PI) / 18) * 2.6 + J(r, 0.5), a));
        s += shadedBand(u, band, '#D08E26', '#FFD46A', dents + '<path d="' + smooth(wv) + '" stroke="#B9781A" stroke-width="1.6" fill="none"/>');
        [14, 70, 128, 165, 220, 318].forEach((a) => { const [x, y] = P(91.5, a + J(r, 4)), rx = 4.4 + r() * 1.2; s += '<ellipse cx="' + x + '" cy="' + y + '" rx="' + f(rx) + '" ry="' + f(rx * 0.75) + '" transform="rotate(' + (a + 90) + ' ' + x + ' ' + y + ')" fill="#FF9445" stroke="#000" stroke-width="2.2"/><circle cx="' + f(x - 1.4) + '" cy="' + f(y - 1.4) + '" r="1.3" fill="#FFE0C2"/>'; });
        const [ex, ey] = P(103, -84);
        let fl = ''; for (let k = 0; k < 9; k++) { const t = k * 40 + J(r, 6), L = 22 + r() * 6, [x1, y1] = P(16, t - 9, ex, ey), [tx, ty] = P(L, t + 4, ex, ey), [x2, y2] = P(16, t + 9, ex, ey); fl += '<path d="M' + x1 + ' ' + y1 + 'Q' + f((x1 + tx) / 2) + ' ' + f((y1 + ty) / 2 - 2) + ' ' + tx + ' ' + ty + 'Q' + f((x2 + tx) / 2 + 2) + ' ' + f((y2 + ty) / 2) + ' ' + x2 + ' ' + y2 + 'Z" fill="#FF9445" stroke="#000" stroke-width="2.6" stroke-linejoin="round"/>'; }
        s += fl + '<path d="' + blob(ex, ey, 17, 17, 12, 0.03, r) + '" fill="#FF9445" stroke="#000" stroke-width="3.5"/><path d="' + blob(ex, ey, 10, 10, 10, 0.05, r) + '" fill="#FFC94A" stroke="#B9781A" stroke-width="2"/><path d="M' + f(ex - 11) + ' ' + f(ey - 4) + 'q4 -8 11 -8" stroke="#FFE0C2" stroke-width="2.4" fill="none" stroke-linecap="round"/>';
        return s;
      },
      anim(o) { return '<circle cx="128" cy="128" r="92" fill="none" stroke="#FFF6D0" stroke-width="10" opacity="0" style="' + A(o, 'cosPulse', 2.4) + '"/>'; },
      band: (r) => ringBlob(82, 101, r, 0.02),
    },
    frame_m_eclipse: {
      tier: 5, name: 'Luna Eclipse', seed: 606,
      spec: ['Base (static): starlit band r 82–100, plum #2A0F2E lit to #3A1640, a cratered crescent moon #FFE8EE at 1:30 and a faceted red-crystal cluster at 6 o’clock (four crystals leaning different ways).', 'anim/corona.png (behind the base): 19 brushy flame tongues #FF3D6E sweeping clockwise, with inner tongues #FF9DB4. Breathes 0.97→1.03, 3 s ease-in-out.', 'anim/stars.png: 5 uneven sparkles twinkle 1.6 s, staggered.', 'Signature: the only frame with a corona and a moon. Special moment (Result screen, on victory): the moon slides 40° over the corona top for a full eclipse of 0.8 s, then returns. Reduced: slide only, the corona does not brighten.', 'Reduce flashing: breathe 0.99→1.01, twinkle opacity 0.6→1, no scale.'],
      behind(o) {
        const r = rng(607); let a = 0, outer = '', inner = '';
        for (let i = 0; i < 19; i++) { const L = 110 + r() * 18, hw = 7 + r() * 3, sw = 9 + r() * 6, [x1, y1] = P(96, a - hw), [x2, y2] = P(96, a + hw), [tx, ty] = P(L, a + sw), [c1x, c1y] = P((96 + L) / 2, a), [c2x, c2y] = P((96 + L) / 2 - 2, a + hw + sw * 0.4);
          outer += '<path d="M' + x1 + ' ' + y1 + 'Q' + c1x + ' ' + c1y + ' ' + tx + ' ' + ty + 'Q' + c2x + ' ' + c2y + ' ' + x2 + ' ' + y2 + 'Z" fill="#FF3D6E" stroke="#000" stroke-width="3" stroke-linejoin="round"/>';
          if (i % 2 === 0) { const L2 = 100 + (L - 100) * 0.55, [ix, iy] = P(L2, a + sw * 0.6), [j1x, j1y] = P(97, a - hw * 0.4), [j2x, j2y] = P(97, a + hw * 0.5); inner += '<path d="M' + j1x + ' ' + j1y + 'Q' + f((j1x + ix) / 2) + ' ' + f((j1y + iy) / 2) + ' ' + ix + ' ' + iy + 'Q' + f((j2x + ix) / 2) + ' ' + f((j2y + iy) / 2) + ' ' + j2x + ' ' + j2y + 'Z" fill="#FF9DB4"/>'; }
          a += 19 + J(r, 3); }
        return '<g style="transform-origin:128px 128px;' + A(o, 'cosBreathe', 3) + '">' + outer + inner + '</g>';
      },
      base(o, u) {
        const r = rng(this.seed); let s = '';
        const band = ringBlob(82, 100, r, 0.02);
        let dots = ''; for (let k = 0; k < 16; k++) { const [x, y] = P(84 + r() * 14, r() * 360); dots += '<circle cx="' + x + '" cy="' + y + '" r="' + f(0.6 + r() * 1) + '" fill="#C9A3CF"/>'; }
        s += shadedBand(u, band, '#22091F', '#3A1640', dots);
        const [mx, my] = P(106, -46);
        s += '<g transform="rotate(-22 ' + mx + ' ' + my + ')">' + crescentHD(mx, my, 25, '#E9C7D2', 3.5) + '</g>';
        const [c0x, c0y] = P(98, 90);
        const C1 = ['#FF6F93', '#B0173F', '#7A0E2C'], C2 = ['#FF3D6E', '#8E1234', '#5A0A20'];
        s += '<g transform="translate(' + c0x + ' ' + (c0y - 6) + ')">' + crystal(-17, 10, 22, 11, -6, C2, 3) + crystal(17, 10, 26, 12, 7, C2, 3) + crystal(-2, 12, 40, 15, 2, C1, 3.2) + crystal(8, 14, 15, 8, 4, C1, 2.6) + '</g>';
        return s;
      },
      anim(o) {
        const r = rng(608); let s = '';
        [[158, 0], [204, 0.4], [248, 0.8], [17, 1.2], [132, 1]].forEach(([a, d]) => { const [x, y] = P(90 + J(r, 4), a), rv = 4 + r() * 2.5; s += twinkle(x, y, rv, rv * 0.7, '#FFE8EE', A(o, 'cosTwinkle', 1.6, 'ease-in-out ' + d + 's infinite')); });
        return s;
      },
      band: (r) => ringBlob(82, 100, r, 0.02),
    },
  };
  function frameSVG(id, o = {}) {
    const d = FRAME[id], u = ++uid, size = o.size || 256, base = d.base(o, u);
    const clipBand = d.band(rng(d.seed));
    const av = o.avatar ? '<circle cx="128" cy="128" r="84" fill="#00B8FF"/><text x="128" y="132" text-anchor="middle" dominant-baseline="central" font-family="\'Baloo 2\',cursive" font-weight="800" font-size="84" fill="' + INK + '">L</text>' : '';
    const win = o.window ? '<circle cx="128" cy="128" r="84" fill="none" stroke="#FF3D6E" stroke-width="1.5" stroke-dasharray="4 4"/>' : '';
    const shadow = (d.shadowExtra || '') + base.replace(/fill="(?!none)[^"]*"/g, 'fill="#000"').replace(/stroke="(?!none)[^"]*"/g, 'stroke="#000"');
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="' + size + '" height="' + size + '" style="display:block;overflow:visible"><defs>' + defsFor(u, 3, 0.022, d.seed % 97, 0.5) + '<clipPath id="cb' + u + '"><path d="' + clipBand + '" clip-rule="evenodd"/></clipPath></defs>' +
      '<g filter="url(#w' + u + ')">' + (d.behind ? d.behind(o) : '') + '</g>' + av +
      '<g filter="url(#w' + u + ')"><g transform="translate(0 6)" opacity=".5">' + shadow + '</g>' + base + (d.anim ? d.anim(o) : '') + '</g>' + win + '</svg>';
  }

  // ---------- FX ----------
  const FX = {
    fx_c_dust: { tier: 0, name: 'Sand Puff', die: 'die_c_reed', spec: ['Trail: sand puffs #E8D3A0 (black 2.5 px ring), 1 per 45 ms behind the die, grow 7→13 px, life 0.35 s.', 'Impact: 7 puffs along the felt, ±60–160 px/s sideways, life 0.45 s (replaces the #F3E7D3/#BFD3CC dust).', 'Settle: 8 diamonds [face type, #E8D3A0], 110–150 px travel, ease-out-cubic, life 0.4 s.', 'Peak live particles ≈ 18 / die. No glow, so the reduced variant is identical.'] },
    fx_u_ember: { tier: 1, name: 'Campfire Embers', die: 'die_u_moss', spec: ['Trail: ember diamonds #FFB23F / #FF6A2B / #FFE08A, 6 px, rise 40–90 px/s, 1 per 35 ms, life 0.5 s.', 'Impact: 9 embers in an upward cone (200–320 px/s, gravity 600) + 3 smoke puffs #5A4A44.', 'Settle: 10 diamonds [face type, #FFB23F] + #FFF8EA lock ring (existing).', 'Peak ≈ 28 / die. Reduced: identical (no flash).'] },
    fx_r_frost: { tier: 2, name: 'Frost Trail', die: 'die_r_aqua', spec: ['Trail: snowflakes (white, 6-arm, black under-stroke) 7 px, slow drift, 1 per 50 ms, life 0.6 s.', 'Impact: 6 snow puffs #FFFFFF + 4 ice chips #8BDCFF.', 'Settle: 8 ice shards [#8BDCFF, face type] (long triangles) + hex lock ring #8BDCFF.', 'Peak ≈ 26 / die. Reduced: identical.'] },
    fx_e_rune: { tier: 3, name: 'Rune Circle', die: 'die_e_rune', spec: ['Trail: spore wisps #BF6BFF 4 px with a 10 px 35 % halo, 1 per 40 ms, life 0.5 s.', 'Impact: 6-dot ring #BF6BFF expanding 30→70 px, 0.3 s.', 'Settle: rune circle (r 56→130, 0.4 s, rotates 40°, 6 rune ticks) + 8 diamonds [face type, #F1E2FF].', 'Reduced: halos 50 %, rune circle stroke 50 % alpha.'] },
    fx_l_sunfire: { tier: 4, name: 'Sunfire Comet', die: 'die_l_gold', spec: ['Trail: comet ribbon from the last 14 die positions — black 22 px, #FF9445 16 px, #FFD872 8 px core, tapered; plus sparks #FFE08A 1 per 30 ms.', 'Impact: 8 short gold rays (r 40→80) 0.25 s + 4 sparks.', 'Settle: 12 sunburst rays (r 64→130) 0.3 s + 10 diamonds [face type, #FFD872] + gold screen tint 0.25 alpha, 0.2 s.', 'Reduced: no screen tint, rays 50 % alpha, comet core #FFC94A.', 'Peak ≈ 34 / die (ribbon counts as 1).'] },
    fx_m_lunar: { tier: 5, name: 'Lunar Shatter', die: 'die_m_redcrystal', spec: ['Trail: red-crystal shards #FF3D6E / #B0173F tumbling, 8 px, 1 per 40 ms + star dust #FFE8EE (4-point), life 0.55 s.', 'Impact: 8 shards burst + 1 star.', 'Settle: 10 shards [face type, #FF3D6E, #FFE8EE] + crimson lock ring.', 'MAX moment (signature): screen dims to 40 % (no flash), a crimson moon halo (r 96, 6 px) with a crescent above the die holds 1.2 s while 8 shards orbit at r 96, then everything bursts outward. Face stays clear: the halo is outside the face rect.', 'Reduced: dim to 25 %, halo 50 % alpha, no orbit speed-up.', 'Peak ≈ 38 / die on MAX.'] },
  };

  function mountFX(canvas, getOpts) {
    const W = 860, H = 340, FLOOR = 262, CAP = 40, PERIOD = 3.0;
    const ctx = canvas.getContext('2d'), dpr = window.devicePixelRatio || 1;
    canvas.width = W * dpr; canvas.height = H * dpr; ctx.scale(dpr, dpr);
    const imgs = {}, icon = new Image(); icon.src = 'assets/icons/dmg.png';
    const plateImg = (id) => { if (!imgs[id]) { const im = new Image(); im.src = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(plateSVG(id, { static: true, size: 208 })); imgs[id] = im; } return imgs[id]; };
    let lastStep = -1, parts = [], hist = [], last = performance.now(), T = 0, prevT = 0, flags = {}, spawnAcc = 0, settleAt = -1, clearT = 0, peak = 0, tint = 0, dim = 0, raf, stats = { peak: 0, clear: 0 };
    const rnd = (a, b) => a + Math.random() * (b - a);
    const add = (p) => { if (parts.length >= CAP) return; parts.push(Object.assign({ age: 0, s0: 8, s1: 8, rot: rnd(0, 6.28), vr: rnd(-6, 6), g: 0, drag: 0, vx: 0, vy: 0, a: 1, jj: [rnd(0.72, 1.18), rnd(0.72, 1.18), rnd(0.72, 1.18), rnd(0.72, 1.18), rnd(0.72, 1.18), rnd(0.72, 1.18), rnd(0.72, 1.18)], lw: rnd(2, 3.4) }, p)); };
    const tw = (x, y, shape, cols, n, d0, d1, life, size, extra) => { for (let i = 0; i < n; i++) { const g = Math.random() * Math.PI * 2, d = rnd(d0, d1); add(Object.assign({ tw: 1, x0: x, y0: y, x1: x + Math.cos(g) * d, y1: y + Math.sin(g) * d * 0.72, shape, col: cols[i % cols.length], life: life * rnd(0.85, 1.1), s0: size, s1: size * 0.3, front: 1, rot: g }, extra)); } };
    const dieAt = (t) => {
      const u = Math.min(t / 0.78, 1), e = 1 - Math.pow(1 - u, 2), x = 110 + e * 320;
      let h = 0;
      if (t < 0.36) h = 150 * (1 - Math.pow(t / 0.36, 2)); else if (t < 0.6) { const v = (t - 0.36) / 0.24; h = 62 * 4 * v * (1 - v); } else if (t < 0.76) { const v = (t - 0.6) / 0.16; h = 22 * 4 * v * (1 - v); }
      const spin = (1 - e) * 11, settle = Math.min(Math.max((t - 0.76) / 0.3, 0), 1);
      const sx = t < 0.76 ? 0.35 + 0.65 * Math.abs(Math.cos(spin * 1.6)) : 0.35 + 0.65 * Math.abs(Math.cos(0)) ;
      const pop = t > 0.9 && t < 1.1 ? 1 + 0.12 * Math.sin(((t - 0.9) / 0.2) * Math.PI) : 1;
      return { x, y: FLOOR - h - 52, rot: t < 0.76 ? spin : 0.06 * (1 - settle) + 0.04, sx: t < 0.76 ? sx : 1, pop, moving: t < 0.76 };
    };
    const FXDEF = {
      fx_c_dust: {
        trail(d, every) { if (every(0.045)) add({ shape: 'puff', x: d.x - 34, y: d.y + 34, vx: -40, vy: -12, life: 0.35, s0: 7, s1: 13, col: '#E8D3A0' }); },
        impact(x, y, k) { for (let i = 0; i < 7; i++) add({ shape: 'puff', x: x + rnd(-30, 30), y, vx: (i % 2 ? 1 : -1) * rnd(60, 160) * k, vy: -rnd(20, 60) * k, drag: 2.5, life: 0.45, s0: 8, s1: 16, col: '#E8D3A0' }); },
        settle(d, fc) { tw(d.x, d.y, 'dia', [fc, '#E8D3A0'], 8, 110, 150, 0.4, 13); },
      },
      fx_u_ember: {
        trail(d, every) { if (every(0.035)) add({ shape: 'dia', x: d.x - 30 + rnd(-10, 10), y: d.y + rnd(-10, 30), vx: -rnd(20, 50), vy: -rnd(40, 90), life: 0.5, s0: 7, s1: 3, col: ['#FFB23F', '#FF6A2B', '#FFE08A'][Math.random() * 3 | 0] }); },
        impact(x, y, k) { for (let i = 0; i < 9; i++) add({ shape: 'dia', x: x + rnd(-24, 24), y, vx: rnd(-90, 90), vy: -rnd(200, 320) * k, g: 600, life: 0.55, s0: 8, s1: 3, col: ['#FFB23F', '#FF6A2B', '#FFE08A'][i % 3] }); for (let i = 0; i < 3; i++) add({ shape: 'puff', x: x + rnd(-30, 30), y: y - 6, vx: rnd(-40, 40), vy: -rnd(20, 40), life: 0.5, s0: 8, s1: 15, col: '#5A4A44' }); },
        settle(d, fc) { tw(d.x, d.y, 'dia', [fc, '#FFB23F'], 10, 110, 150, 0.4, 13); add({ shape: 'ring', x: d.x, y: d.y, r0: 56, r1: 100, life: 0.42, col: '#FFF8EA', front: 1 }); },
      },
      fx_r_frost: {
        trail(d, every) { if (every(0.05)) add({ shape: 'flake', x: d.x - 34 + rnd(-8, 8), y: d.y + rnd(-20, 30), vx: -rnd(10, 40), vy: rnd(-10, 25), life: 0.6, s0: 8, s1: 5, col: '#FFFFFF', vr: rnd(-2, 2) }); },
        impact(x, y, k) { for (let i = 0; i < 6; i++) add({ shape: 'puff', x: x + rnd(-30, 30), y, vx: (i % 2 ? 1 : -1) * rnd(40, 130) * k, vy: -rnd(20, 70) * k, drag: 2.5, life: 0.45, s0: 7, s1: 14, col: '#FFFFFF' }); for (let i = 0; i < 4; i++) add({ shape: 'dia', x, y: y - 4, vx: rnd(-160, 160), vy: -rnd(120, 220) * k, g: 700, life: 0.5, s0: 8, s1: 4, col: '#8BDCFF' }); },
        settle(d, fc) { tw(d.x, d.y, 'shard', ['#8BDCFF', fc], 8, 115, 150, 0.4, 16); add({ shape: 'hex', x: d.x, y: d.y, r0: 58, r1: 110, life: 0.42, col: '#8BDCFF', front: 1 }); },
      },
      fx_e_rune: {
        trail(d, every) { if (every(0.04)) add({ shape: 'wisp', x: d.x - 30 + rnd(-10, 10), y: d.y + rnd(-25, 25), vx: -rnd(20, 50), vy: -rnd(5, 30), life: 0.5, s0: 5, s1: 2, col: '#BF6BFF' }); },
        impact(x, y) { for (let i = 0; i < 6; i++) { const g = (i / 6) * Math.PI * 2; add({ tw: 1, shape: 'wisp', x0: x, y0: y - 4, x1: x + Math.cos(g) * 70, y1: y - 4 + Math.sin(g) * 22, life: 0.3, s0: 5, s1: 3, col: '#BF6BFF' }); } },
        settle(d, fc) { add({ shape: 'rune', x: d.x, y: d.y, r0: 56, r1: 130, life: 0.4, col: '#BF6BFF', front: 1 }); tw(d.x, d.y, 'dia', [fc, '#F1E2FF'], 8, 110, 150, 0.4, 13); },
      },
      fx_l_sunfire: {
        comet: true,
        trail(d, every) { if (every(0.03)) add({ shape: 'star', x: d.x - 20 + rnd(-14, 14), y: d.y + rnd(-20, 20), vx: -rnd(30, 70), vy: rnd(-30, 30), life: 0.45, s0: 7, s1: 2, col: '#FFE08A' }); },
        impact(x, y) { for (let i = 0; i < 8; i++) add({ shape: 'ray', x, y: y - 6, ang: Math.PI + (i / 7) * Math.PI, r0: 40, r1: 80, life: 0.25, col: '#FFD872', glow: 1 }); for (let i = 0; i < 4; i++) add({ shape: 'star', x, y: y - 8, vx: rnd(-140, 140), vy: -rnd(100, 200), g: 500, life: 0.4, s0: 7, s1: 3, col: '#FFE08A' }); },
        settle(d, fc) { for (let i = 0; i < 12; i++) add({ shape: 'ray', x: d.x, y: d.y, ang: (i / 12) * Math.PI * 2, r0: 64, r1: 130, life: 0.3, col: '#FFD872', glow: 1, front: 1 }); tw(d.x, d.y, 'dia', [fc, '#FFD872'], 10, 115, 150, 0.4, 13); if (!flags.rf) tint = 0.25; },
      },
      fx_m_lunar: {
        trail(d, every) { if (every(0.04)) { add({ shape: 'shard', x: d.x - 30 + rnd(-10, 10), y: d.y + rnd(-25, 25), vx: -rnd(30, 70), vy: rnd(-20, 30), life: 0.55, s0: 10, s1: 5, col: Math.random() < 0.5 ? '#FF3D6E' : '#B0173F' }); if (Math.random() < 0.5) add({ shape: 'star', x: d.x - 40 + rnd(-10, 10), y: d.y + rnd(-30, 30), vx: -20, vy: 0, life: 0.5, s0: 6, s1: 2, col: '#FFE8EE' }); } },
        impact(x, y, k) { for (let i = 0; i < 8; i++) add({ shape: 'shard', x, y: y - 4, vx: rnd(-180, 180), vy: -rnd(120, 260) * k, g: 700, life: 0.5, s0: 10, s1: 4, col: i % 2 ? '#FF3D6E' : '#B0173F' }); add({ shape: 'star', x, y: y - 20, vx: 0, vy: -40, life: 0.4, s0: 9, s1: 3, col: '#FFE8EE' }); },
        settle(d, fc, max) {
          tw(d.x, d.y, 'shard', [fc, '#FF3D6E', '#FFE8EE'], 10, 115, 150, 0.4, 15);
          add({ shape: 'ring', x: d.x, y: d.y, r0: 56, r1: 110, life: 0.42, col: '#FF3D6E', front: 1 });
          if (max) { dim = flags.rf ? 0.25 : 0.4; add({ shape: 'halo', x: d.x, y: d.y, life: 1.4, col: '#FF3D6E', front: 1 }); for (let i = 0; i < 8; i++) add({ shape: 'orbit', x: d.x, y: d.y, ang: (i / 8) * Math.PI * 2, life: 1.4, s0: 12, s1: 12, col: i % 2 ? '#FF3D6E' : '#B0173F', front: 1 }); }
        },
      },
    };
    function drawShape(p, a) {
      const s = p.s0 + (p.s1 - p.s0) * Math.min(p.age / p.life, 1), rf = flags.rf ? 0.5 : 1;
      ctx.save(); ctx.globalAlpha = a; ctx.translate(p.x, p.y); ctx.lineJoin = 'round'; ctx.lineCap = 'round';
      const fillStroke = (path) => { ctx.fillStyle = p.col; ctx.strokeStyle = '#000'; ctx.lineWidth = p.lw; path(); ctx.fill(); ctx.stroke(); };
      const jb = (rad) => { const n = p.jj.length; ctx.beginPath(); const pts = p.jj.map((k, i) => [Math.cos((i / n) * 6.283) * rad * k, Math.sin((i / n) * 6.283) * rad * k]); ctx.moveTo((pts[0][0] + pts[n - 1][0]) / 2, (pts[0][1] + pts[n - 1][1]) / 2); for (let i = 0; i < n; i++) { const q = pts[i], nx = pts[(i + 1) % n]; ctx.quadraticCurveTo(q[0], q[1], (q[0] + nx[0]) / 2, (q[1] + nx[1]) / 2); } ctx.closePath(); };
      const u = p.age / p.life, eo = 1 - Math.pow(1 - u, 2);
      switch (p.shape) {
        case 'dia': ctx.rotate(p.rot); fillStroke(() => { const j = p.jj, h = s * 0.62; ctx.beginPath(); ctx.moveTo(0, -h * j[0]); ctx.lineTo(h * j[1], 0); ctx.lineTo(0, h * j[2]); ctx.lineTo(-h * j[3], 0); ctx.closePath(); }); if (s > 6) { ctx.beginPath(); ctx.moveTo(-s * 0.22, -s * 0.08); ctx.lineTo(0, -s * 0.36); ctx.strokeStyle = 'rgba(255,255,255,.75)'; ctx.lineWidth = 1.4; ctx.stroke(); } break;
        case 'puff': fillStroke(() => jb(s / 2)); break;
        case 'shard': ctx.rotate(p.rot); fillStroke(() => { const j = p.jj; ctx.beginPath(); ctx.moveTo(s * 0.08 * j[4], -s * j[0]); ctx.lineTo(s * 0.34 * j[1], -s * 0.1); ctx.lineTo(0, s * 0.6 * j[2]); ctx.lineTo(-s * 0.3 * j[3], s * 0.05); ctx.closePath(); }); ctx.beginPath(); ctx.moveTo(-s * 0.1, -s * 0.1); ctx.lineTo(s * 0.04, -s * 0.7); ctx.strokeStyle = 'rgba(255,255,255,.7)'; ctx.lineWidth = 1.3; ctx.stroke(); break;
        case 'star': ctx.rotate(p.rot * 0.2); fillStroke(() => { ctx.beginPath(); ctx.moveTo(0, -s); ctx.quadraticCurveTo(0, 0, s, 0); ctx.quadraticCurveTo(0, 0, 0, s); ctx.quadraticCurveTo(0, 0, -s, 0); ctx.quadraticCurveTo(0, 0, 0, -s); }); break;
        case 'flake': ctx.rotate(p.rot); ctx.beginPath(); for (let k = 0; k < 3; k++) { const g = (k * Math.PI) / 3; ctx.moveTo(Math.cos(g) * s, Math.sin(g) * s); ctx.lineTo(-Math.cos(g) * s, -Math.sin(g) * s); } ctx.strokeStyle = '#000'; ctx.lineWidth = 5; ctx.stroke(); ctx.strokeStyle = p.col; ctx.lineWidth = 2; ctx.stroke(); break;
        case 'wisp': ctx.globalAlpha = a * 0.35 * rf; ctx.fillStyle = p.col; ctx.beginPath(); ctx.arc(0, 0, s * 2, 0, 7); ctx.fill(); ctx.globalAlpha = a; fillStroke(() => { ctx.beginPath(); ctx.arc(0, 0, s, 0, 7); }); break;
        case 'ring': case 'hex': case 'rune': {
          const r = p.r0 + (p.r1 - p.r0) * eo; ctx.globalAlpha = a * (1 - eo) * (p.shape === 'rune' ? rf : 1);
          ctx.beginPath(); if (p.shape === 'hex') { for (let k = 0; k <= 6; k++) { const g = (k / 6) * Math.PI * 2 + Math.PI / 6, jk = 0.94 + 0.06 * p.jj[k % 7]; ctx[k ? 'lineTo' : 'moveTo'](Math.cos(g) * r * jk, Math.sin(g) * r * 0.85 * jk); } } else { ctx.save(); ctx.scale(1, 0.85); const n = 7, pts = p.jj.map((k, i) => [Math.cos((i / n) * 6.283) * r * (0.95 + 0.05 * k), Math.sin((i / n) * 6.283) * r * (0.95 + 0.05 * k)]); ctx.moveTo((pts[0][0] + pts[6][0]) / 2, (pts[0][1] + pts[6][1]) / 2); for (let i = 0; i < n; i++) { const q = pts[i], nx = pts[(i + 1) % n]; ctx.quadraticCurveTo(q[0], q[1], (q[0] + nx[0]) / 2, (q[1] + nx[1]) / 2); } ctx.closePath(); ctx.restore(); }
          ctx.strokeStyle = '#000'; ctx.lineWidth = 9; ctx.stroke(); ctx.strokeStyle = p.col; ctx.lineWidth = 5; ctx.stroke();
          if (p.shape === 'rune') { ctx.rotate(eo * 0.7); for (let k = 0; k < 6; k++) { const g = (k / 6) * Math.PI * 2; ctx.save(); ctx.translate(Math.cos(g) * r, Math.sin(g) * r * 0.85); ctx.rotate(g + Math.PI / 2); ctx.fillStyle = '#F1E2FF'; ctx.strokeStyle = '#000'; ctx.lineWidth = 2.5; ctx.beginPath(); ctx.rect(-5, -7, 10, 14); ctx.fill(); ctx.stroke(); ctx.translate(-4, -5); ctx.scale(0.8, 0.8); ctx.strokeStyle = '#5B23A8'; ctx.lineWidth = 2.4; ctx.stroke(new Path2D(RUNES[k])); ctx.restore(); } }
          break; }
        case 'ray': {
          const r1 = p.r0 + (p.r1 - p.r0) * eo, r0 = p.r0 + (p.r1 - p.r0) * Math.max(eo - 0.35, 0); ctx.globalAlpha = a * (p.glow ? rf : 1);
          ctx.beginPath(); ctx.moveTo(Math.cos(p.ang) * r0, Math.sin(p.ang) * r0 * 0.85); ctx.lineTo(Math.cos(p.ang) * r1, Math.sin(p.ang) * r1 * 0.85);
          ctx.strokeStyle = '#000'; ctx.lineWidth = 10; ctx.stroke(); ctx.strokeStyle = p.col; ctx.lineWidth = 5; ctx.stroke(); break; }
        case 'halo': {
          const ein = Math.min(u / 0.2, 1), out = u > 0.8 ? 1 - (u - 0.8) / 0.2 : 1; ctx.globalAlpha = out * (flags.rf ? 0.5 : 1);
          const r = 96 * (0.8 + 0.2 * (1 - Math.pow(1 - ein, 3)));
          ctx.beginPath(); ctx.arc(0, 0, r, 0, 7); ctx.strokeStyle = '#000'; ctx.lineWidth = 11; ctx.stroke(); ctx.strokeStyle = p.col; ctx.lineWidth = 6; ctx.stroke();
          ctx.translate(0, -r - 4); ctx.beginPath(); ctx.arc(0, 0, 20, Math.PI * 0.15, Math.PI * 1.85, false); ctx.arc(-9, 0, 15, Math.PI * 1.75, Math.PI * 0.25, true); ctx.closePath(); ctx.fillStyle = '#FFE8EE'; ctx.strokeStyle = '#000'; ctx.lineWidth = 3; ctx.fill(); ctx.stroke(); break; }
        case 'orbit': {
          const burst = u > 0.8 ? (u - 0.8) / 0.2 : 0, r = 96 + burst * 120, g = p.ang + p.age * (flags.rf ? 1.5 : 2.5);
          ctx.globalAlpha = 1 - burst; ctx.translate(Math.cos(g) * r, Math.sin(g) * r); ctx.rotate(g + Math.PI / 2);
          fillStroke(() => { ctx.beginPath(); ctx.moveTo(0, -s); ctx.lineTo(s * 0.32, 0); ctx.lineTo(0, s * 0.6); ctx.lineTo(-s * 0.32, 0); ctx.closePath(); }); break; }
      }
      ctx.restore();
    }
    function rr(x, y, w, h, r) { ctx.beginPath(); ctx.roundRect(x, y, w, h, r); }
    function drawDie(d, id, max) {
      const s = 104, im = plateImg(id), D = DIE[id], cls = CLASS.plant;
      ctx.save(); ctx.translate(d.x, d.y); ctx.rotate(d.rot); ctx.scale(d.sx * d.pop, d.pop); ctx.translate(-s / 2, -s / 2);
      ctx.save(); rr(0, 0, s, s, 18.72); ctx.clip(); if (im.complete) ctx.drawImage(im, 0, 0, s, s); ctx.restore();
      ctx.beginPath(); ctx.moveTo(2, 24.96); ctx.lineTo(2, 18.72); ctx.arcTo(2, 2, 18.72, 2, 16.7); ctx.lineTo(85.28, 2); ctx.arcTo(102, 2, 102, 18.72, 16.7); ctx.lineTo(102, 24.96); ctx.closePath(); ctx.fillStyle = cls; ctx.fill(); ctx.lineWidth = 4; ctx.strokeStyle = '#000'; ctx.stroke();
      ctx.font = "800 41.6px 'Baloo 2'"; ctx.fillStyle = INK; ctx.textBaseline = 'middle';
      const val = max ? '8' : '6', tw = ctx.measureText(val).width, x0 = 52 - (tw + 6.24 + 31.2) / 2, cy = 64.48;
      ctx.fillText(val, x0, cy + 3);
      rr(x0 + tw + 6.24, cy - 15.6, 31.2, 31.2, 7); ctx.fillStyle = TYPE.dmg; ctx.fill(); ctx.lineWidth = 3; ctx.stroke();
      if (icon.complete) ctx.drawImage(icon, x0 + tw + 6.24 + 5.6, cy - 10, 20, 20);
      rr(2, 2, 100, 100, 16.7); ctx.lineWidth = 4; ctx.strokeStyle = D.border; ctx.stroke();
      ctx.restore();
    }
    function frame(now) {
      const o = getOpts(); flags = o;
      const dtReal = Math.min((now - last) / 1000, 0.05); last = now;
      const dt = dtReal / (o.slow ? 2.5 : 1);
      prevT = T; T += dt; if (T >= PERIOD) { T = 0; prevT = 0; parts = []; hist = []; settleAt = -1; stats = { peak: 0, clear: clearT }; }
      const def = FXDEF[o.fx], id = FX[o.fx].die, d = dieAt(T);
      const cross = (t) => prevT < t && T >= t;
      const every = (iv) => { spawnAcc += dt; if (spawnAcc >= iv) { spawnAcc = 0; return true; } return false; };
      if (d.moving) { def.trail(d, every); hist.unshift({ x: d.x, y: d.y }); hist.length = Math.min(hist.length, 14); } else if (hist.length) hist.pop();
      [[0.36, 1], [0.6, 0.6], [0.76, 0.35]].forEach(([t, k]) => { if (cross(t)) def.impact(dieAt(t).x, FLOOR, k); });
      if (cross(0.9)) { def.settle(d, TYPE.dmg, !!o.max); settleAt = T; clearT = 0; }
      for (const p of parts) { p.age += dt; if (!p.tw && p.shape !== 'halo' && p.shape !== 'orbit' && p.shape !== 'ring' && p.shape !== 'hex' && p.shape !== 'rune' && p.shape !== 'ray') { p.vy += p.g * dt; p.vx *= 1 - p.drag * dt; p.vy *= 1 - p.drag * dt; p.x += p.vx * dt; p.y += p.vy * dt; p.rot += p.vr * dt; } }
      parts = parts.filter((p) => p.age < p.life);
      stats.peak = Math.max(stats.peak, parts.length);
      tint = Math.max(0, tint - dt * 1.25); if (T > 2.2) dim = Math.max(0, dim - dt * 2);
      // draw
      ctx.clearRect(0, 0, W, H);
      rr(4, 4, W - 8, H - 8, 40); ctx.fillStyle = '#7A4A22'; ctx.fill(); ctx.lineWidth = 5; ctx.strokeStyle = '#000'; ctx.stroke();
      rr(22, 22, W - 44, H - 44, 26); const gr = ctx.createLinearGradient(0, 22, 0, H - 22); gr.addColorStop(0, '#27555D'); gr.addColorStop(1, '#1B3E45'); ctx.fillStyle = gr; ctx.fill(); ctx.lineWidth = 4; ctx.strokeStyle = '#A56B35'; ctx.stroke();
      ctx.save(); rr(22, 22, W - 44, H - 44, 26); ctx.clip();
      if (dim > 0) { ctx.fillStyle = `rgba(8,9,13,${dim})`; ctx.fillRect(0, 0, W, H); }
      const ph = FLOOR - d.y - 52; ctx.fillStyle = `rgba(0,0,0,${Math.max(0.15, 0.4 - ph / 600)})`; ctx.beginPath(); ctx.ellipse(d.x, FLOOR + 6, 58 * Math.max(0.5, 1 - ph / 400), 12, 0, 0, 7); ctx.fill();
      if (def.comet && hist.length > 2) { [['#000', 22], [o.rf ? '#FFB23F' : '#FF9445', 15], [o.rf ? '#FFC94A' : '#FFD872', 7]].forEach(([c, w]) => { for (let i = 1; i < hist.length; i++) { ctx.beginPath(); ctx.moveTo(hist[i - 1].x, hist[i - 1].y); ctx.lineTo(hist[i].x, hist[i].y); ctx.strokeStyle = c; ctx.lineCap = 'round'; ctx.lineWidth = w * (1 - i / hist.length); ctx.stroke(); } }); }
      const step = Math.floor(T * 12) !== lastStep; if (step) lastStep = Math.floor(T * 12);
      const life = (p) => p.tw ? 1 - Math.pow(p.age / p.life, 2) : 1 - p.age / p.life;
      const snap = (p) => { if (step || !p.sn) { if (p.tw) { const e = 1 - Math.pow(1 - p.age / p.life, 3); p.x = p.x0 + (p.x1 - p.x0) * e; p.y = p.y0 + (p.y1 - p.y0) * e; } p.sn = { x: p.x, y: p.y, rot: p.rot, age: p.age }; } };
      const drawSn = (p) => { const k = { x: p.x, y: p.y, rot: p.rot, age: p.age }; Object.assign(p, p.sn); const a = life(p); drawShape(p, a); Object.assign(p, k); return a; };
      for (const p of parts) if (!p.front) { snap(p); drawSn(p); }
      drawDie(d, id, !!o.max);
      let over = false;
      for (const p of parts) if (p.front) {
        snap(p);
        if (p.tw) { if (Math.abs(p.sn.x - d.x) < 52 + p.s0 / 2 && Math.abs(p.sn.y - d.y) < 52 + p.s0 / 2 && life(p) > 0.15) over = true; }
        else if (p.r0 != null) { const r = p.r0 + (p.r1 - p.r0) * (1 - Math.pow(1 - p.sn.age / p.life, 2)); if (r < 66) over = true; }
        drawSn(p);
      }
      if (settleAt >= 0 && over) clearT = T - settleAt;
      if (o.max && T > 0.9 && T < 2.2) { ctx.save(); ctx.translate(d.x + 52, d.y - 58); ctx.rotate(-0.14); ctx.font = "800 24px 'Baloo 2'"; const w = ctx.measureText('MAX!').width + 22; rr(-w / 2, -18, w, 36, 10); ctx.fillStyle = '#FFD76A'; ctx.fill(); ctx.lineWidth = 4; ctx.strokeStyle = '#000'; ctx.stroke(); ctx.fillStyle = INK; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText('MAX!', 0, 2); ctx.restore(); }
      if (tint > 0) { ctx.fillStyle = `rgba(255,215,106,${tint})`; ctx.fillRect(0, 0, W, H); }
      ctx.restore();
      o.onStats && o.onStats({ live: parts.length, peak: stats.peak, clear: clearT });
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

  window.CosArt = { TIERS, DIE, FRAME, FX, INK, TYPE, contrast, hue, lum, plateSVG, dieSVG, frameSVG, mountFX, exportPNG };
})();
