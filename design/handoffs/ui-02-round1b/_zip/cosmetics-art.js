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

  // ---------- DIE PLATES (104 × 104 face space; band hides y < 24.96) ----------
  const CZ = { x: 10.4, y: 45.8, w: 83.2, h: 37.4 };
  const DIE = {
    die_c_reed: {
      tier: 0, name: 'Woven Reed', border: '#000', calm: ['#E6CC8E', '#EFDAA6', '#CDAE68'],
      spec: ['Border #000, 4 px at s=104 (3 px on the 36 px egg token).', 'One material: straw weave on 13 px cells, tonal only (ΔL small) so the weave never competes with the value.', 'Braided rim along the bottom 13 px.'],
      plate() {
        let s = '<rect width="104" height="104" fill="#EBD49A"/>';
        for (let i = 0; i < 8; i++) for (let j = 0; j < 8; j++) {
          const x = j * 13, y = i * 13, h = (i + j) % 2 === 0;
          s += `<rect x="${x}" y="${y}" width="13" height="13" fill="${h ? '#E6CC8E' : '#EFDAA6'}"/>`;
          s += h ? `<path d="M${x} ${y + 4.3}h13M${x} ${y + 8.7}h13" stroke="#CDAE68" stroke-width="1.2"/>` : `<path d="M${x + 4.3} ${y}v13M${x + 8.7} ${y}v13" stroke="#CDAE68" stroke-width="1.2"/>`;
        }
        s += '<rect y="91" width="104" height="13" fill="#D2B06A"/>';
        let t = ''; for (let x = -6; x < 110; x += 6) t += `M${x} 104L${x + 6} 92`;
        s += `<path d="${t}" stroke="#A9873F" stroke-width="2"/><path d="M0 91H104" stroke="#8C6A2A" stroke-width="2"/>`;
        return s;
      },
    },
    die_u_moss: {
      tier: 1, name: 'Mossback Stone', border: '#000', calm: ['#C5C8BA', '#ADB1A2'],
      spec: ['Border #000, 4 px.', 'One material: grey field-stone with moss creeping in from the bottom edge and both sides.', 'Moss stays outside the calm zone (x < 10.4 or > 93.6, y > 83.2).'],
      plate() {
        return '<rect width="104" height="104" fill="#C5C8BA"/>' +
          '<path d="M0 42H38V58H70V40H104M24 58V76H60M70 58H104M40 76V92" stroke="#ADB1A2" stroke-width="1.5" fill="none"/>' +
          '<path d="M0 86C14 80 22 92 36 87S60 80 72 88S94 82 104 86V104H0Z" fill="#6FA83E" stroke="#000" stroke-width="2"/>' +
          '<ellipse cx="18" cy="95" rx="7" ry="3" fill="#9BCB5C"/><ellipse cx="60" cy="96" rx="8" ry="3" fill="#9BCB5C"/><ellipse cx="90" cy="94" rx="6" ry="2.5" fill="#9BCB5C"/>' +
          '<path d="M0 50C6 52 9 60 6 66C9 72 7 80 0 82Z" fill="#6FA83E" stroke="#000" stroke-width="2"/>' +
          '<path d="M104 30C97 33 95 40 98 46C95 51 97 56 104 58Z" fill="#6FA83E" stroke="#000" stroke-width="2"/>' +
          '<path d="M80 86C78 80 74 78 70 79C72 83 76 85 80 86ZM80 86C82 80 86 79 90 80C88 84 84 86 80 86Z" fill="#9BCB5C" stroke="#000" stroke-width="1.5"/>';
      },
    },
    die_r_aqua: {
      tier: 2, name: 'Tidescale', tag: 'Mastery · Aquatic', border: '#000', calm: ['#AEE8F8', '#86D4EC'],
      spec: ['Border #000, 4 px.', 'Two materials: tonal scallop scales over the whole face + a hard-outlined wave crest and bubbles at the edges.', 'Scale strokes are #86D4EC on #AEE8F8, so they read as texture, not pattern, behind the value.'],
      plate() {
        let s = '<rect width="104" height="104" fill="#AEE8F8"/>', d = '';
        for (let r = 0; r < 16; r++) { const y = r * 7, o = (r % 2) * 6; for (let x = -12 + o; x < 110; x += 12) d += `M${x} ${y}a6 6 0 0 0 12 0`; }
        s += `<path d="${d}" stroke="#86D4EC" stroke-width="1.4" fill="none"/>`;
        let w = 'M0 92'; for (let x = 0; x < 104; x += 13) w += `q6.5 -8 13 0`;
        s += `<path d="${w}V104H0Z" fill="#39C5F3" stroke="#000" stroke-width="2"/>`;
        for (let x = 6.5; x < 104; x += 13) s += `<circle cx="${x}" cy="88.6" r="1.6" fill="#F2FCFF"/>`;
        const bub = (x, y, r) => `<circle cx="${x}" cy="${y}" r="${r}" fill="#F2FCFF" stroke="#000" stroke-width="1.8"/><path d="M${x - r * 0.5} ${y - r * 0.1}a${r * 0.5} ${r * 0.5} 0 0 1 ${r * 0.5} ${-r * 0.45}" stroke="#86D4EC" stroke-width="1.2" fill="none"/>`;
        return s + bub(6.5, 70, 3.6) + bub(6, 80, 2.2) + bub(97, 40, 4) + bub(92, 31, 2.4);
      },
    },
    die_e_rune: {
      tier: 3, name: 'Mystic Runestone', border: '#2A0F45', calm: ['#DDCDF6'],
      spec: ['Border #2A0F45 (deep violet), 4 px — reads as black at 36 px.', 'Ornament: inset rim #A27BE0 2 px, diamond studs on the rim corners and mid-sides.', 'glow.png: rune underlay #BF6BFF, 5 px stroke, blend Add, opacity 0.35→0.9.', 'Idle: glow pulse 2.0 s ease-in-out loop. Reduce flashing: 0.55→0.7.'],
      plate(o) {
        let s = '<rect width="104" height="104" fill="#DDCDF6"/><rect x="7" y="7" width="90" height="90" rx="13" fill="none" stroke="#A27BE0" stroke-width="2"/>';
        let g = '', glyph = '';
        [22, 36, 50, 64, 78].forEach((x, i) => { glyph += `<path transform="translate(${x - 4.5} 86) scale(.9)" d="${RUNES[i]}"/>`; });
        glyph += `<path transform="translate(1.6 58) scale(.75)" d="${RUNES[1]}"/><path transform="translate(94.9 58) scale(.75)" d="${RUNES[4]}"/>`;
        g += `<g stroke="#BF6BFF" stroke-width="5" stroke-linecap="round" fill="none" opacity="${o.static ? 0.6 : 0.35}" style="${A(o, 'cosPulse', 2)}">${glyph}</g>`;
        g += `<g stroke="#5B23A8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none">${glyph}</g>`;
        const dia = (x, y, r) => `<path d="M${x} ${y - r}L${x + r} ${y}L${x} ${y + r}L${x - r} ${y}Z" fill="#BF6BFF" stroke="#2A0F45" stroke-width="2"/>`;
        return s + g + dia(7, 97, 6) + dia(97, 97, 6) + dia(7, 40, 4.5) + dia(97, 40, 4.5);
      },
    },
    die_l_gold: {
      tier: 4, name: 'Genesis Sunplate', border: '#3A2205', calm: ['#FFD872', '#FFE69E'],
      spec: ['Border #3A2205 (dark bronze), 4 px.', 'Ornament: carved sunburst fan from a half-sun at the bottom edge, engraved rim #E0A532, bronze studs.', 'glow.png: diagonal sheen band, white 50 %, blend Add.', 'Idle: sheen sweeps left→right in 1.1 s, then rests — 3.2 s loop, ease-in-out. Reduce flashing: sheen 20 % opacity.'],
      plate(o) {
        let s = '<rect width="104" height="104" fill="#FFD872"/>';
        for (let a = 180; a < 360; a += 13) { const [x1, y1] = P(170, a, 52, 108), [x2, y2] = P(170, a + 6.5, 52, 108); s += `<path d="M52 108L${x1} ${y1}L${x2} ${y2}Z" fill="#FFE69E"/>`; }
        s += '<rect x="6" y="6" width="92" height="92" rx="13" fill="none" stroke="#E0A532" stroke-width="2"/>';
        let t = ''; [200, 215, 230, 245, 295, 310, 325, 340].forEach((a) => { const [x1, y1] = P(23, a, 52, 108), [x2, y2] = P(28, a, 52, 108); t += `M${x1} ${y1}L${x2} ${y2}`; });
        s += `<path d="${t}" stroke="#3A2205" stroke-width="2.5" stroke-linecap="round"/>`;
        s += '<circle cx="52" cy="108" r="19" fill="#F7B538" stroke="#3A2205" stroke-width="2.5"/><circle cx="52" cy="108" r="12" fill="#FFC94A" stroke="#B9781A" stroke-width="1.5"/>';
        s += '<circle cx="12" cy="92" r="3.5" fill="#F7B538" stroke="#3A2205" stroke-width="2"/><circle cx="92" cy="92" r="3.5" fill="#F7B538" stroke="#3A2205" stroke-width="2"/>';
        s += `<g style="${A(o, 'cosSheen', 3.2)}"><path d="M-40 0H-24L-54 104H-70Z" fill="#FFFFFF" opacity=".5"/></g>`;
        return s;
      },
    },
    die_m_redcrystal: {
      tier: 5, name: 'Luna Redcrystal', border: '#1E0410', calm: ['#FFE8EE'], dark: true,
      spec: ['Dark skin → LIGHT VALUE PLATE: #FFE8EE, rx 10, 3 px #1E0410 outline, exactly the calm zone (x −0.40…+0.40 s, y −0.06…+0.30 s). Ink stays #1A1206.', 'Border #1E0410, 4 px. Field: starlit plum #2A0F2E.', 'Signature: crescent moon + red-crystal clusters (no lower tier has both a light value plate and a moon).', 'Idle: 4 stars twinkle, 1.6 s, staggered 0.4 s; crystal glint 2.8 s. Reduce flashing: twinkle 0.6→1 opacity, no scale.', 'MAX settle moment: crescent fills to a full moon for 0.6 s while the crystals grow 1→1.15 (ease-out-back), then return. Reduced: no fill, crystals only.'],
      plate(o) {
        let s = '<rect width="104" height="104" fill="#2A0F2E"/>';
        [[20, 36], [44, 30], [70, 40], [8, 94], [96, 72]].forEach(([x, y]) => (s += `<circle cx="${x}" cy="${y}" r="1" fill="#6B3A70"/>`));
        s += `<path d="${crescent(88, 36, 8.5)}" fill="#FFE8EE" stroke="#000" stroke-width="1.6"/>`;
        [[7, 36, 3.6, 0], [60, 33, 2.6, 0.4], [97, 86, 3, 0.8], [5, 88, 2.6, 1.2]].forEach(([x, y, r, d]) => (s += star4(x, y, r, '#FFE8EE', A(o, 'cosTwinkle', 1.6, `ease-in-out ${d}s infinite`))));
        const sh = (pts, fill, hi) => `<path d="M${pts}Z" fill="${fill}" stroke="#1E0410" stroke-width="2" stroke-linejoin="round"/>` + (hi ? `<path d="M${hi}Z" fill="#FF9DB4"/>` : '');
        s += sh('0 104L5 86L12 104', '#B0173F') + sh('8 104L17 84L25 104', '#FF3D6E', '17 86L13 104L17 104') + sh('22 104L28 92L33 104', '#B0173F');
        s += sh('104 104L99 86L92 104', '#B0173F') + sh('96 104L87 84L79 104', '#FF3D6E', '87 86L83 104L87 104') + sh('82 104L76 92L71 104', '#B0173F');
        s += sh('46 104L52 92L58 104', '#FF3D6E');
        s += `<rect x="${CZ.x}" y="${CZ.y}" width="${CZ.w}" height="${CZ.h}" rx="10" fill="#FFE8EE" stroke="#1E0410" stroke-width="3"/>`;
        s += star4(17, 88, 3, '#FFFFFF', A(o, 'cosTwinkle', 2.8, 'ease-in-out 0.6s infinite'));
        return s;
      },
    },
  };
  // calm-zone contrast check (min over every colour that touches the zone)
  Object.values(DIE).forEach((d) => { d.contrast = Math.min(...d.calm.map((c) => contrast(c, INK))); });

  function plateSVG(id, o = {}) {
    const d = DIE[id], c = 'cp' + ++uid;
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 104 104" width="${o.size || 512}" height="${o.size || 512}"><defs><clipPath id="${c}"><rect width="104" height="104"/></clipPath></defs><g clip-path="url(#${c})">${d.plate(o)}</g></svg>`;
  }
  const CLASS = { plant: '#7DC943', aqua: '#39C5F3', beast: '#FFB23F', reptile: '#B679F7', bug: '#F2624F', bird: '#8BDCFF' };
  // Full die, code-drawn layers on top (reroll_die.gd geometry). s = rendered px; border px stays constant.
  function dieSVG(id, s, o = {}) {
    const d = DIE[id], k = 104 / s, bw = (s <= 40 ? 3 : 4) * k, c = 'cd' + ++uid;
    const cls = CLASS[o.cls || 'plant'], val = String(o.value ?? 6), type = o.type || 'dmg';
    const fs = 41.6, iw = 31.2, gap = 6.24, tw = 0.56 * fs * val.length, x0 = -(tw + gap + iw) / 2 + 52, cy = 52 + 12.48;
    const R = 18.72, h = bw / 2;
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 104 104" width="${s}" height="${s}" style="display:block;overflow:visible">
<defs><clipPath id="${c}"><rect width="104" height="104" rx="${R}"/></clipPath></defs>
<g clip-path="url(#${c})">${d.plate(o)}</g>
<path d="M${h} 24.96V${R}A${R - h} ${R - h} 0 0 1 ${R} ${h}H${104 - R}A${R - h} ${R - h} 0 0 1 ${104 - h} ${R}V24.96Z" fill="${cls}" stroke="#000" stroke-width="${bw}"/>
<text x="${x0}" y="${cy}" dominant-baseline="central" font-family="'Baloo 2',cursive" font-weight="800" font-size="${fs}" fill="${INK}" dy="2">${val}</text>
<rect x="${x0 + tw + gap}" y="${cy - iw / 2}" width="${iw}" height="${iw}" rx="7" fill="${TYPE[type]}" stroke="#000" stroke-width="${(bw / k - 1) * k}"/>
<image href="assets/icons/${type}.png" x="${x0 + tw + gap + iw * 0.18}" y="${cy - iw / 2 + iw * 0.18}" width="${iw * 0.64}" height="${iw * 0.64}"/>
<rect x="${h}" y="${h}" width="${104 - bw}" height="${104 - bw}" rx="${R - h}" fill="none" stroke="${d.border}" stroke-width="${bw}"/></svg>`;
  }

  // ---------- AVATAR FRAMES (256 canvas, window = circle Ø168 at centre) ----------
  const leaf = (L) => `M0 0C${L * 0.25} ${-L * 0.34} ${L * 0.75} ${-L * 0.34} ${L} 0C${L * 0.75} ${L * 0.34} ${L * 0.25} ${L * 0.34} 0 0Z`;
  const FRAME = {
    frame_c_plant: {
      tier: 0, name: 'Sprout Ring', tag: 'Mastery · Plant',
      spec: ['Static. Ring r 82–100 #7DC943, 4 px black.', '12 leaves alternating #9BDB5E / #5FA830 + a two-leaf sprout at 12 o’clock — the sprout is the 40 px silhouette cue.', 'Shelf shadow: silhouette, black 50 %, offset (0, 6), no blur.'],
      base() {
        let s = '';
        for (let i = 0; i < 12; i++) { const a = i * 30 + 15; if (a > 240 && a < 300) continue; const [x, y] = P(96, a); s += `<g transform="translate(${x} ${y}) rotate(${a + (i % 2 ? 38 : -38)})"><path d="${leaf(30)}" fill="${i % 2 ? '#5FA830' : '#9BDB5E'}" stroke="#000" stroke-width="3" stroke-linejoin="round"/><path d="M4 0H25" stroke="#3F7F1E" stroke-width="2" stroke-linecap="round"/></g>`; }
        s += `<path d="${ring(82, 100)}" fill="#7DC943" fill-rule="evenodd" stroke="#000" stroke-width="4"/><circle cx="128" cy="128" r="91" fill="none" stroke="#5FA830" stroke-width="2" stroke-dasharray="6 7"/>`;
        s += '<path d="M128 30V18" stroke="#000" stroke-width="8" stroke-linecap="round"/><path d="M128 30V18" stroke="#5FA830" stroke-width="3" stroke-linecap="round"/>';
        [[-128, '#9BDB5E'], [-52, '#7DC943']].forEach(([r, c]) => (s += `<g transform="translate(128 22) rotate(${r})"><path d="${leaf(44)}" fill="${c}" stroke="#000" stroke-width="3.5" stroke-linejoin="round"/><path d="M6 0H36" stroke="#3F7F1E" stroke-width="2.5" stroke-linecap="round"/></g>`));
        return s;
      },
    },
    frame_u_mushroom: {
      tier: 1, name: 'Toadstool Ring', spec: ['Static. Wood ring r 82–98 #B5773F with grain #8E5A2B.', 'Mushroom clusters at 8 and 2 o’clock break the circle — asymmetric silhouette reads at 40 px.', 'Caps #F2624F / #E8A45A with cream spots, stems #FFF1D6.'],
      base() {
        let s = `<path d="${ring(82, 98)}" fill="#B5773F" fill-rule="evenodd" stroke="#000" stroke-width="4"/>`;
        s += '<circle cx="128" cy="128" r="87" fill="none" stroke="#8E5A2B" stroke-width="2" stroke-dasharray="40 14 18 22"/><circle cx="128" cy="128" r="93" fill="none" stroke="#8E5A2B" stroke-width="2" stroke-dasharray="22 30 50 12"/>';
        const grass = (a) => { const [x, y] = P(98, a); return `<g transform="translate(${x} ${y}) rotate(${a + 90})"><path d="M-8 2L-6 -10L-3 1L0 -14L3 1L7 -9L8 2Z" fill="#7DC943" stroke="#000" stroke-width="2.5" stroke-linejoin="round"/></g>`; };
        s += grass(100) + grass(78) + grass(160) + grass(-20);
        const mush = (a, sc, cap) => { const [x, y] = P(94, a); return `<g transform="translate(${x} ${y}) rotate(${a + 90}) scale(${sc})"><path d="M-7 0V-22H7V0Z" fill="#FFF1D6" stroke="#000" stroke-width="3" stroke-linejoin="round"/><path d="M-24 -20C-24 -44 24 -44 24 -20Z" fill="${cap}" stroke="#000" stroke-width="3" stroke-linejoin="round"/><circle cx="-10" cy="-29" r="4" fill="#FFF1D6"/><circle cx="7" cy="-34" r="3" fill="#FFF1D6"/><circle cx="14" cy="-24" r="2.5" fill="#FFF1D6"/></g>`; };
        s += mush(150, 0.8, '#E8A45A') + mush(115, 0.7, '#F2624F') + mush(133, 1.1, '#F2624F') + mush(-62, 0.65, '#E8A45A') + mush(-40, 0.85, '#F2624F');
        return s;
      },
    },
    frame_r_frost: {
      tier: 2, name: 'Frost Crown', spec: ['Static. Two materials: ice ring r 82–100 #CFF1FF with radial facets #8BDCFF, and a snow drift #FFFFFF at 6 o’clock.', 'Five-spike ice crown (44 / 32 / 22 px) on top — the crown is the 40 px silhouette.', 'Two small snowflakes at 3 and 9 o’clock.'],
      base() {
        let s = '', t = '';
        [[-90, 46], [-66, 32], [-114, 32], [-42, 22], [-138, 22]].forEach(([a, L]) => { const [bx1, by1] = P(97, a - 9), [bx2, by2] = P(97, a + 9), [tx, ty] = P(97 + L, a), [mx, my] = P(97, a); s += `<path d="M${bx1} ${by1}L${tx} ${ty}L${bx2} ${by2}Z" fill="#E9FAFF" stroke="#000" stroke-width="3" stroke-linejoin="round"/><path d="M${mx} ${my}L${tx} ${ty}L${bx2} ${by2}Z" fill="#A9E4FB"/>`; });
        s += `<path d="${ring(82, 100)}" fill="#CFF1FF" fill-rule="evenodd" stroke="#000" stroke-width="4"/>`;
        for (let a = 0; a < 360; a += 15) { const [x1, y1] = P(85, a), [x2, y2] = P(97, a); t += `M${x1} ${y1}L${x2} ${y2}`; }
        s += `<path d="${t}" stroke="#8BDCFF" stroke-width="2"/>`;
        let d = `M${P(100, 52).join(' ')}`; for (let a = 52; a < 128; a += 12) { const [x, y] = P(108, a + 6), [x2, y2] = P(101, a + 12); d += `Q${x} ${y} ${x2} ${y2}`; }
        d += `L${P(90, 128).join(' ')}A90 90 0 0 0 ${P(90, 52).join(' ')}Z`;
        s += `<path d="${d}" fill="#FFFFFF" stroke="#000" stroke-width="3" stroke-linejoin="round"/>`;
        const flake = (a) => { const [x, y] = P(91, a); let l = ''; for (let k = 0; k < 3; k++) { const [a1, b1] = P(9, k * 60, x, y), [a2, b2] = P(9, k * 60 + 180, x, y); l += `M${a1} ${b1}L${a2} ${b2}`; } return `<path d="${l}" stroke="#000" stroke-width="6" stroke-linecap="round"/><path d="${l}" stroke="#FFFFFF" stroke-width="2.5" stroke-linecap="round"/>`; };
        return s + flake(0) + flake(180);
      },
    },
    frame_e_runering: {
      tier: 3, name: 'Runewheel', spec: ['Base (static): ring r 82–98 #7A3BC7, four #F1E2FF diamond studs at N/E/S/W.', 'anim/rune_ring.png: outer ring r 102–120 #BF6BFF with 12 runes #2A0F45 — rotates 360° in 16 s, linear. Its shelf shadow is a plain ring, so it is static.', 'anim/rune_glow.png: rune underlay #F1E2FF 5 px, opacity pulse 0.2→0.9, 2.0 s ease-in-out.', 'Reduce flashing: rotation unchanged (no luminance change); glow 0.5→0.65.'],
      shadowExtra: `<path d="${ring(102, 120)}" fill-rule="evenodd"/>`,
      base() {
        let s = `<path d="${ring(82, 98)}" fill="#7A3BC7" fill-rule="evenodd" stroke="#000" stroke-width="4"/><circle cx="128" cy="128" r="93" fill="none" stroke="#A36BE8" stroke-width="2"/>`;
        [0, 90, 180, 270].forEach((a) => { const [x, y] = P(90, a); s += `<path d="M${x} ${y - 12}L${x + 9} ${y}L${x} ${y + 12}L${x - 9} ${y}Z" fill="#F1E2FF" stroke="#000" stroke-width="3" stroke-linejoin="round" transform="rotate(${a} ${x} ${y})"/>`; });
        return s;
      },
      anim(o) {
        let g = '';
        for (let i = 0; i < 12; i++) { const a = i * 30, [x, y] = P(111, a); g += `<path transform="translate(${x} ${y}) rotate(${a + 90}) translate(-6 -7.2) scale(1.2)" d="${RUNES[i % 6]}"/>`; }
        return `<g style="transform-origin:128px 128px;${A(o, 'cosSpin', 16, 'linear infinite')}"><path d="${ring(102, 120)}" fill="#BF6BFF" fill-rule="evenodd" stroke="#000" stroke-width="4"/>
<g stroke="#F1E2FF" stroke-width="6" stroke-linecap="round" fill="none" opacity="${o.static ? 0 : 0.2}" style="${A(o, 'cosPulse', 2)}">${g}</g><g stroke="#2A0F45" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" fill="none">${g}</g></g>`;
      },
    },
    frame_l_sunburst: {
      tier: 4, name: 'Genesis Sunburst', spec: ['Base (static): gold ring r 82–102 #FFD872, carved rings #D99A22, 8 Kam gems #FF9445, sun emblem at 12 o’clock.', 'anim/rays.png (behind base): 16 rays #FFC94A, long r 126 / short r 114, rotate 360° in 30 s linear.', 'anim/glow.png: ring r 92, #FFF6D0 10 px, opacity 0→0.8→0, 2.4 s ease-in-out.', 'Reduce flashing: glow 0.3→0.45; rays keep rotating.'],
      behind(o) {
        let s = '';
        for (let i = 0; i < 16; i++) { const a = i * 22.5, L = i % 2 ? 114 : 126, [x1, y1] = P(94, a - 7), [x2, y2] = P(94, a + 7), [tx, ty] = P(L, a); s += `<path d="M${x1} ${y1}L${tx} ${ty}L${x2} ${y2}Z" fill="${i % 2 ? '#FFB23F' : '#FFC94A'}" stroke="#000" stroke-width="3" stroke-linejoin="round"/>`; }
        return `<g style="transform-origin:128px 128px;${A(o, 'cosSpin', 30, 'linear infinite')}">${s}</g>`;
      },
      base() {
        let s = `<path d="${ring(82, 102)}" fill="#FFD872" fill-rule="evenodd" stroke="#000" stroke-width="4"/><circle cx="128" cy="128" r="88" fill="none" stroke="#D99A22" stroke-width="2.5"/><circle cx="128" cy="128" r="97" fill="none" stroke="#D99A22" stroke-width="2"/>`;
        for (let a = 22.5; a < 360; a += 45) { const [x, y] = P(92.5, a); s += `<circle cx="${x}" cy="${y}" r="4.5" fill="#FF9445" stroke="#000" stroke-width="2"/>`; }
        s += '<circle cx="128" cy="25" r="17" fill="#FF9445" stroke="#000" stroke-width="3.5"/><circle cx="128" cy="25" r="9" fill="#FFC94A" stroke="#B9781A" stroke-width="2"/>';
        return s;
      },
      anim(o) { return `<circle cx="128" cy="128" r="92" fill="none" stroke="#FFF6D0" stroke-width="10" opacity="0" style="${A(o, 'cosPulse', 2.4)}"/>`; },
    },
    frame_m_eclipse: {
      tier: 5, name: 'Luna Eclipse', spec: ['Base (static): starlit ring r 82–100 #2A0F2E, crescent moon #FFE8EE at 1:30, red-crystal cluster at 6 o’clock (#FF3D6E / #B0173F, facet #FF9DB4).', 'anim/corona.png (behind base): crimson flame corona r 104–122 #FF3D6E + inner #FF9DB4, breathe scale 0.97→1.03, 3 s ease-in-out.', 'anim/stars.png: 6 four-point stars twinkle 1.6 s, staggered.', 'Signature: the only frame with a corona + moon. Special moment (Result screen, on victory): moon slides 40° to cover the corona top — full eclipse 0.8 s — then returns. Reduced: slide only, corona does not brighten.', 'Reduce flashing: breathe 0.99→1.01, twinkle opacity 0.6→1, no scale.'],
      behind(o) {
        let a = '', b = '';
        for (let i = 0; i <= 32; i++) { const r = i % 2 ? 106 : 122 - ((i * 7) % 5) * 2, [x, y] = P(r, i * 11.25 - 90); a += (i ? 'L' : 'M') + x + ' ' + y; const r2 = i % 2 ? 102 : 112, [x2, y2] = P(r2, i * 11.25 - 84); b += (i ? 'L' : 'M') + x2 + ' ' + y2; }
        const hole = 'M32 128a96 96 0 1 0 192 0a96 96 0 1 0 -192 0Z';
        return `<g style="transform-origin:128px 128px;${A(o, 'cosBreathe', 3)}"><path d="${a}Z${hole}" fill-rule="evenodd" fill="#FF3D6E" stroke="#000" stroke-width="3" stroke-linejoin="round"/><path d="${b}Z${hole}" fill-rule="evenodd" fill="#FF9DB4"/></g>`;
      },
      base() {
        let s = `<path d="${ring(82, 100)}" fill="#2A0F2E" fill-rule="evenodd" stroke="#000" stroke-width="4"/>`;
        const [mx, my] = P(106, -45);
        s += `<g transform="rotate(-20 ${mx} ${my})"><path d="${crescent(mx, my, 25)}" fill="#FFE8EE" stroke="#000" stroke-width="3.5" stroke-linejoin="round"/></g>`;
        const shard = (a, L, w, fill) => { const [b1x, b1y] = P(98, a - w), [b2x, b2y] = P(98, a + w), [tx, ty] = P(98 + L, a), [mx2, my2] = P(98, a); return `<path d="M${b1x} ${b1y}L${tx} ${ty}L${b2x} ${b2y}Z" fill="${fill}" stroke="#000" stroke-width="3" stroke-linejoin="round"/><path d="M${mx2} ${my2}L${tx} ${ty}L${b1x} ${b1y}Z" fill="#FF9DB4" opacity=".85"/>`; };
        s += shard(68, 22, 7, '#B0173F') + shard(112, 22, 7, '#B0173F') + shard(90, 34, 9, '#FF3D6E');
        return s;
      },
      anim(o) {
        let s = '';
        [[160, 2.6, 0], [200, 3.2, 0.4], [250, 2.6, 0.8], [20, 3, 1.2], [-10, 2.4, 0.2], [140, 2.2, 1]].forEach(([a, r, d]) => { const [x, y] = P(91, a); s += star4(x, y, r * 1.6, '#FFE8EE', A(o, 'cosTwinkle', 1.6, `ease-in-out ${d}s infinite`)); });
        return s;
      },
    },
  };
  function frameSVG(id, o = {}) {
    const d = FRAME[id], base = d.base(o), size = o.size || 256;
    const av = o.avatar ? `<circle cx="128" cy="128" r="84" fill="#00B8FF"/><text x="128" y="132" text-anchor="middle" dominant-baseline="central" font-family="'Baloo 2',cursive" font-weight="800" font-size="84" fill="${INK}">L</text>` : '';
    const win = o.window ? '<circle cx="128" cy="128" r="84" fill="none" stroke="#FF3D6E" stroke-width="1.5" stroke-dasharray="4 4"/>' : '';
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="${size}" height="${size}" style="display:block;overflow:visible">${d.behind ? d.behind(o) : ''}${av}<g transform="translate(0 6)" opacity=".5" class="cos-sh">${(d.shadowExtra || '') + base.replace(/fill="(?!none)[^"]*"/g, 'fill="#000"').replace(/stroke="(?!none)[^"]*"/g, 'stroke="#000"')}</g>${base}${d.anim ? d.anim(o) : ''}${win}</svg>`;
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
    let parts = [], hist = [], last = performance.now(), T = 0, prevT = 0, flags = {}, spawnAcc = 0, settleAt = -1, clearT = 0, peak = 0, tint = 0, dim = 0, raf, stats = { peak: 0, clear: 0 };
    const rnd = (a, b) => a + Math.random() * (b - a);
    const add = (p) => { if (parts.length >= CAP) return; parts.push(Object.assign({ age: 0, s0: 8, s1: 8, rot: rnd(0, 6.28), vr: rnd(-6, 6), g: 0, drag: 0, vx: 0, vy: 0, a: 1 }, p)); };
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
      const fillStroke = (path) => { ctx.fillStyle = p.col; ctx.strokeStyle = '#000'; ctx.lineWidth = 2.5; path(); ctx.fill(); ctx.stroke(); };
      const u = p.age / p.life, eo = 1 - Math.pow(1 - u, 2);
      switch (p.shape) {
        case 'dia': ctx.rotate(p.rot); fillStroke(() => { ctx.beginPath(); ctx.rect(-s / 2, -s / 2, s, s); }); break;
        case 'puff': fillStroke(() => { ctx.beginPath(); ctx.arc(0, 0, s / 2, 0, 7); }); break;
        case 'shard': ctx.rotate(p.rot); fillStroke(() => { ctx.beginPath(); ctx.moveTo(0, -s); ctx.lineTo(s * 0.32, 0); ctx.lineTo(0, s * 0.6); ctx.lineTo(-s * 0.32, 0); ctx.closePath(); }); break;
        case 'star': ctx.rotate(p.rot * 0.2); fillStroke(() => { ctx.beginPath(); ctx.moveTo(0, -s); ctx.quadraticCurveTo(0, 0, s, 0); ctx.quadraticCurveTo(0, 0, 0, s); ctx.quadraticCurveTo(0, 0, -s, 0); ctx.quadraticCurveTo(0, 0, 0, -s); }); break;
        case 'flake': ctx.rotate(p.rot); ctx.beginPath(); for (let k = 0; k < 3; k++) { const g = (k * Math.PI) / 3; ctx.moveTo(Math.cos(g) * s, Math.sin(g) * s); ctx.lineTo(-Math.cos(g) * s, -Math.sin(g) * s); } ctx.strokeStyle = '#000'; ctx.lineWidth = 5; ctx.stroke(); ctx.strokeStyle = p.col; ctx.lineWidth = 2; ctx.stroke(); break;
        case 'wisp': ctx.globalAlpha = a * 0.35 * rf; ctx.fillStyle = p.col; ctx.beginPath(); ctx.arc(0, 0, s * 2, 0, 7); ctx.fill(); ctx.globalAlpha = a; fillStroke(() => { ctx.beginPath(); ctx.arc(0, 0, s, 0, 7); }); break;
        case 'ring': case 'hex': case 'rune': {
          const r = p.r0 + (p.r1 - p.r0) * eo; ctx.globalAlpha = a * (1 - eo) * (p.shape === 'rune' ? rf : 1);
          ctx.beginPath(); if (p.shape === 'hex') { for (let k = 0; k <= 6; k++) { const g = (k / 6) * Math.PI * 2 + Math.PI / 6; ctx[k ? 'lineTo' : 'moveTo'](Math.cos(g) * r, Math.sin(g) * r * 0.85); } } else ctx.ellipse(0, 0, r, r * 0.85, 0, 0, 7);
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
      const life = (p) => p.tw ? 1 - Math.pow(p.age / p.life, 2) : 1 - p.age / p.life;
      for (const p of parts) if (!p.front) { if (p.tw) { const e = 1 - Math.pow(1 - p.age / p.life, 3); p.x = p.x0 + (p.x1 - p.x0) * e; p.y = p.y0 + (p.y1 - p.y0) * e; } drawShape(p, life(p)); }
      drawDie(d, id, !!o.max);
      let over = false;
      for (const p of parts) if (p.front) {
        if (p.tw) { const e = 1 - Math.pow(1 - p.age / p.life, 3); p.x = p.x0 + (p.x1 - p.x0) * e; p.y = p.y0 + (p.y1 - p.y0) * e; if (Math.abs(p.x - d.x) < 52 + p.s0 / 2 && Math.abs(p.y - d.y) < 52 + p.s0 / 2 && life(p) > 0.15) over = true; }
        else if (p.r0 != null) { const r = p.r0 + (p.r1 - p.r0) * (1 - Math.pow(1 - p.age / p.life, 2)); if (r < 66) over = true; }
        drawShape(p, life(p));
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
