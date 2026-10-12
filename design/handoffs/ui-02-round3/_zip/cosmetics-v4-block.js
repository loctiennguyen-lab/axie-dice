  // ---------- v4: Axie Homeland avatar-frame style ----------
  // OBSERVED (pixel-sampled) in the reference frames uploaded by the user (Homeland_Avatar frame_1/2/3, SS2/SS3 Fancy):
  // one warm maroon outline #682828–#703030 on every silhouette; airbrushed gradient fills; inner detail lines in a darker tone of the fill;
  // 2–3 large decoration clusters per frame placed asymmetrically; a cute critter or creature motif; 4-point sparkles with a coloured rim.
  const OL = '#6B2B2B';
  let DEFS = [], CU = 0;
  const grad = (c1, c2, x1 = 0, y1 = 0, x2 = 1, y2 = 1) => { const id = 'gr' + ++uid; DEFS.push(`<linearGradient id="${id}" x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}"><stop offset="0" stop-color="${c1}"/><stop offset="1" stop-color="${c2}"/></linearGradient>`); return `url(#${id})`; };
  const softDefs = (u, sc) => `<filter id="sf${u}" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="${2.2 * sc}"/></filter><filter id="cr${u}" x="-5%" y="-5%" width="110%" height="110%"><feTurbulence type="fractalNoise" baseFrequency="${0.9 / sc}" numOctaves="1" seed="${u % 40}"/><feDisplacementMap in="SourceGraphic" scale="${1.2 * sc}" xChannelSelector="R" yChannelSelector="G"/></filter>`;
  // paint: maroon-outlined shape; `soft` = airbrushed shade/glow blobs (blurred, clipped); `lines` = crisp inner detail (clipped)
  function paint(d, fill, o = {}) {
    const id = 'q' + ++uid, w = o.w ?? 3.2, rule = o.rule ? ` fill-rule="${o.rule}" clip-rule="${o.rule}"` : '', ol = o.ol || OL;
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
      tier: 4, name: 'Genesis Sunburst', seed: 505,
      spec: ['Base (static), after the gold cuffs of frame_2 and the SS3 hanging stars: a gold band (#FFD890 → #E0A058) with engraved swirls #E07828 and teal gem studs (#90E0D0, rim #307070).', 'A big sun at the top (#FFE8A0 → #F8A048, swirl #E07828) and orange 4-point stars (#FFC870 → #F07828) hanging at 3 and 9 o’clock.', 'anim/rays.png (behind the base): 12 blade rays (#FFC870 → #F07828), long r 126 / short r 114, rotate 360° in 30 s, linear. anim/glow.png: ring r 93, #FFF0C0, opacity 0→0.8→0, 2.4 s.', 'Reduce flashing: glow 0.3→0.45; rays keep rotating.'],
      behind(o) {
        let s = '';
        for (let i = 0; i < 12; i++) { const a = i * 30 + 15, L = i % 2 ? 114 : 126, b1 = P(96, a - 7), b2 = P(96, a + 7), tp = P(L, a); s += paint(`M${pp(b1)}L${pp(tp)}L${pp(b2)}Z`, grad('#FFC870', '#F07828', 0, 0, 1, 1), { w: 3, lines: line(`M${pp(P(98, a - 2))}L${pp(P(L - 8, a - 1))}`, '#FFE8B0', 1.8) }); }
        return `<g style="transform-origin:128px 128px;${A(o, 'cosSpin', 30, 'linear infinite')}">${s}</g>`;
      },
      base() {
        const r = rng(this.seed); let s = '', sw = '';
        [200, 250, 330, 20, 140].forEach((a) => { const [x, y] = P(93, a); sw += `M${f(x - 5)} ${f(y)}c0 -5 8 -6 9 -1c1 3 -3 5 -5 3c-1 -1 0 -3 1 -2`; });
        s += bandA(84, 102, grad('#FFD890', '#E0A058', 0, 0, 1, 1), line(sw, '#E07828', 1.6), '#C86038', r);
        [60, 120, 180, 0].forEach((a) => { const [x, y] = P(93, a); s += `<circle cx="${x}" cy="${y}" r="4.6" fill="#90E0D0" stroke="#307070" stroke-width="1.6"/><circle cx="${f(x - 1.4)}" cy="${f(y - 1.4)}" r="1.3" fill="#FFFFFF"/>`; });
        const [sx, sy] = P(106, -90);
        s += paint(circ(sx, sy, 22), grad('#FFE8A0', '#F8A048', 0, 0, 1, 1), { w: 3.4, soft: `<path d="${circ(sx + 9, sy + 10, 15)}" fill="#F07828" opacity=".55"/>`, lines: line(`M${sx - 10} ${sy + 2}c0 -9 14 -11 16 -2c1 6 -6 8 -9 4c-2 -3 1 -5 3 -4`, '#E07828', 1.8) + line(`M${sx - 15} ${sy - 6}q4 -9 13 -11`, '#FFF8E0', 2.6) });
        const hang = (a) => { const [x, y] = P(101, a); return line(`M${x} ${y}V${f(y + 10)}`, OL, 4) + star4(x, y + 18, 14, grad('#FFC870', '#F07828', 0, 0, 1, 1), OL, '', 0.14) + line(`M${x} ${f(y + 8)}V${f(y + 26)}M${f(x - 9)} ${f(y + 18)}H${f(x + 9)}`, '#FFE0A0', 1.2, 0.8); };
        return s + hang(0) + hang(180) + sparkle(...P(118, 125), 8, 'teal') + sparkle(...P(120, 55), 6, 'teal');
      },
      anim(o) { return `<circle cx="128" cy="128" r="93" fill="none" stroke="#FFF0C0" stroke-width="10" opacity="0" style="${A(o, 'cosPulse', 2.4)}"/>`; },
    },
    frame_m_eclipse: {
      tier: 5, name: 'Luna Eclipse', seed: 606,
      spec: ['Base (static): a night band (#3A4A80 → #14204A) with cream star dust and lines #5A6AA8; a big cream crescent moon at the top (#FFF8EC → #F0D4B8, rim #E8A060, teal gem), after the SS3 Fancy crescent; a red-crystal cluster at 6 o’clock (#FF8A98 → #C02848). Maroon outline.', 'anim/corona.png (behind the base): 18 coral flame tongues (#FF8A98 → #C83050) with pink inner tongues #FFC0C8. Breathes 0.97→1.03, 3 s ease-in-out.', 'anim/stars.png: 5 teal-rimmed sparkles twinkle 1.6 s, staggered.', 'Special moment (Result screen, on victory): the moon slides 40° over the top of the corona for a full eclipse of 0.8 s, then returns. Reduced: slide only.', 'Reduce flashing: breathe 0.99→1.01; twinkle by opacity only.'],
      behind(o) {
        const r = rng(607); let a = 0, out = '', inn = '';
        for (let i = 0; i < 18; i++) { const L = 114 + r() * 12, hw = 8 + r() * 2, sw = 10 + r() * 5, b1 = P(97, a - hw), b2 = P(97, a + hw), tp = P(L, a + sw), c1 = P((97 + L) / 2 + 2, a - 1), c2 = P((97 + L) / 2 - 3, a + hw + sw * 0.35);
          out += paint(`M${pp(b1)}Q${pp(c1)} ${pp(tp)}Q${pp(c2)} ${pp(b2)}Z`, grad('#FF8A98', '#C83050', 0, 0, 1, 1), { w: 3 });
          if (i % 2 === 0) { const L2 = 100 + (L - 100) * 0.5, ip = P(L2, a + sw * 0.6), j1 = P(99, a - hw * 0.35), j2 = P(99, a + hw * 0.45); inn += `<path d="M${pp(j1)}Q${pp(P((99 + L2) / 2, a + 1))} ${pp(ip)}Q${pp(P((99 + L2) / 2 - 1, a + hw * 0.6))} ${pp(j2)}Z" fill="#FFC0C8"/>`; }
          a += 20 + J(r, 2.5); }
        return `<g style="transform-origin:128px 128px;${A(o, 'cosBreathe', 3)}">${out}${inn}</g>`;
      },
      base() {
        const r = rng(this.seed); let s = '', dots = '';
        for (let k = 0; k < 18; k++) { const q = P(87 + r() * 12, r() * 360); dots += `<circle cx="${q[0]}" cy="${q[1]}" r="${f(0.8 + r() * 1)}" fill="#FFF4E4"/>`; }
        s += bandA(84, 102, grad('#3A4A80', '#14204A', 0, 0, 1, 1), dots + line(`M${pp(P(97, 196))}A97 97 0 0 1 ${pp(P(97, 240))}`, '#5A6AA8', 2.4), null, r);
        const [mx, my] = P(104, -90);
        s += `<g transform="rotate(-90 ${mx} ${my})">${moonA(mx, my, 30, 3.4, false)}</g><ellipse cx="${mx}" cy="${f(my - 22)}" rx="3" ry="5" fill="#60D8D0" stroke="#307070" stroke-width="1.2"/>`;
        const [cx0, cy0] = P(99, 90);
        s += `<g transform="translate(${cx0} ${cy0 + 8})">${crystalA(-17, 4, 22, 12, -6, 3)}${crystalA(18, 4, 26, 13, 7, 3)}${crystalA(-1, 6, 42, 16, 2, 3.2)}${crystalA(9, 8, 16, 9, 4, 2.6)}</g>`;
        return s;
      },
      anim(o) {
        const r = rng(608); let s = '';
        [[158, 0], [204, 0.4], [-30, 0.8], [17, 1.2], [132, 1]].forEach(([a, d]) => { const [x, y] = P(93 + J(r, 4), a); s += sparkle(x, y, 6 + r() * 3, 'teal', A(o, 'cosTwinkle', 1.6, `ease-in-out ${d}s infinite`)); });
        return s;
      },
    },
  };
  function frameSVG(id, o = {}) {
    const d = FRAME[id], size = o.size || 256, u = ++uid; CU = u; DEFS = [];
    const [defs, body] = wrapDefs(u, 1, () => (d.behind ? d.behind(o) : '') + '@@AV@@' + d.base(o) + (d.anim ? d.anim(o) : ''));
    const av = o.avatar ? `<circle cx="128" cy="128" r="84" fill="#00B8FF"/><text x="128" y="132" text-anchor="middle" dominant-baseline="central" font-family="'Baloo 2',cursive" font-weight="800" font-size="84" fill="${INK}">L</text>` : '';
    const win = o.window ? '<circle cx="128" cy="128" r="84" fill="none" stroke="#FF3D6E" stroke-width="1.5" stroke-dasharray="4 4"/>' : '';
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="${size}" height="${size}" style="display:block;overflow:visible"><defs>${defs}</defs>${body.replace('@@AV@@', av)}${win}</svg>`;
  }

