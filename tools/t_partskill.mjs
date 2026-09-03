/* Regression pins for the PART SKILL IDENTITY face data (design/gdd/part-skill-identity.md).
   Reads the committed generator output; does NOT re-derive. Pair it with
   `node tools/gen_faces.mjs --check`, which proves the snapshot still matches the design tables.
   Run: node tools/t_partskill.mjs */
import fs from 'node:fs';

const MAIN = 'assets/data/part_faces.json';
const REF = 'assets/data/part_faces.ref.json';

let pass = 0, fail = 0;
function check(name, cond, detail) {
  if (cond) { pass++; console.log('PASS', name); }
  else { fail++; console.log('FAIL', name, detail !== undefined ? '-> ' + JSON.stringify(detail) : ''); }
}
const load = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
if (!fs.existsSync(MAIN) || !fs.existsSync(REF)) {
  console.log('FAIL missing generator output -> run: node tools/gen_faces.mjs && node tools/gen_faces.mjs --profile=reference');
  process.exit(1);
}
const P = load(MAIN), R = load(REF);
/* the 31 AUTHORED signatures (13 Addendum §3.3b + 18 Secret §3.10); everything else in
   SIGNATURE_FACE is one of the 50 legacy FACE_NAMES faces that AC-7c freezes. */
const AUTHORED = new Set([
  'beast|mouth|Cub', 'bug|mouth|Pincer', 'plant|ears|Clover', 'beast|back|Ronin',
  'beast|eyes|Zeal', 'plant|horn|Cactus', 'plant|tail|Hot Butt', 'aqua|horn|Anemone',
  'aqua|eyes|Sleepless', 'bug|horn|Parasite', 'bird|mouth|Little Owl', 'bird|back|Balloon',
  'bird|ears|Risky Bird',
  'dawn|mouth|Buddy Chorus', 'dawn|back|Magic Sack', 'dawn|back|Nutdha Statue',
  'dawn|back|White Gourd', 'dawn|tail|Aegis Talisman', 'dawn|eyes|Radiant Darkness',
  'dawn|ears|Harmonious Silence', 'dusk|horn|Dream Eater', 'dusk|back|Greedy Urn',
  'dusk|tail|Black Gourd', 'dusk|tail|Maraca', 'dusk|eyes|Fulu', 'dusk|eyes|Grand Finale',
  'mech|horn|Lost Dream', 'mech|horn|Rusty Helm', 'mech|horn|Shocker',
  'mech|back|Village Hero', 'mech|tail|Mainspring',
]);
const LEGACY = new Set(Object.keys(P.signatureFace).filter((k) => !AUTHORED.has(k)));
const T = P.manifest.totals, TR = R.manifest.totals;
const SLOTS = ['mouth', 'horn', 'back', 'tail', 'eyes', 'ears'];

/* ---- structural counts the doc states in three independent places ---- */
check('§3.13d: the signature roster splits 50 legacy + 31 authored',
  LEGACY.size === 50 && AUTHORED.size === 31, [LEGACY.size, AUTHORED.size]);
check('81 signature faces (§3.13d: 50 legacy + 13 addendum + 18 secret)',
  Object.keys(P.signatureFace).length === 81, Object.keys(P.signatureFace).length);
check('204 part->variant assignments (§3.12 checksum)',
  Object.keys(P.partVariant).length === 204, Object.keys(P.partVariant).length);
check('285 scarcity buckets = every catalog identity (§3.1)',
  Object.keys(P.scarcityBucket).length === 285, Object.keys(P.scarcityBucket).length);
check('signature and variant key sets are disjoint (AC-3)',
  Object.keys(P.signatureFace).every((k) => !(k in P.partVariant)));
check('signature + variant = 285 (AC-3)',
  new Set([...Object.keys(P.signatureFace), ...Object.keys(P.partVariant)]).size === 285);
check('I1: nC + nO + nP === 204', T.nC + T.nO + T.nP === 204, [T.nC, T.nO, T.nP]);
check('I1: bucket split is 115 / 74 / 15 (§3.5b TOTAL row)',
  T.nC === 115 && T.nO === 74 && T.nP === 15, [T.nC, T.nO, T.nP]);
check('I2: nP === 18 - |Prime ∩ Signature| === 15', T.nP === 15, T.nP);
check('158 variants authored, 147 reachable (§3.12)',
  T.variants === 158 && T.variants - T.spares === 147, [T.variants, T.spares]);

/* ---- I13: the spare COUNT and the spare SET, because a right number with a wrong set
        is the exact error revision 1 made ---- */
const SPARES = ['aqua.mouth.A', 'bird.eyes.D', 'bird.tail.A', 'bird.tail.D', 'bug.eyes.D',
  'bug.mouth.D', 'plant.eyes.A', 'reptile.back.D', 'reptile.horn.A', 'reptile.tail.A', 'reptile.tail.D'];
check('I13: exactly 11 spare variants', T.spares === 11, T.spares);
check('I13: the spare SET matches §3.12 exactly',
  JSON.stringify(T.spareList.slice().sort()) === JSON.stringify(SPARES.slice().sort()), T.spareList);

/* ---- the headline count, pinned per slot ---- */
const EXPECT_DISTINCT = 285;
const EXPECT_SLOT = { mouth: 41, horn: 54, back: 52, tail: 52, eyes: 40, ears: 46 };
check(`engine-distinct (p,t,v,k) === ${EXPECT_DISTINCT}`,
  T.distinctEngineFaces === EXPECT_DISTINCT, T.distinctEngineFaces);
for (const s of SLOTS) {
  check(`engine-distinct[${s}] === ${EXPECT_SLOT[s]}`,
    T.perSlot[s].distinct === EXPECT_SLOT[s], T.perSlot[s]);
}
const counted = SLOTS.reduce((a, s) => a + T.perSlot[s].parts, 0);
check(`every slot part count sums to 285 (currently ${counted}: ${285 - counted} part(s) excluded because their `
  + `§3.11 row is unparseable — see gen_faces PARSE-3.11)`, counted === 285, { counted, perSlot: T.perSlot });

/* ---- §3.13c's structural claim: distinctness must NOT depend on B[C] ---- */
check('distinctEngineFaces identical at B[C]=2.80 and B[C]=6.00 (§3.13c)',
  T.distinctEngineFaces === TR.distinctEngineFaces, [T.distinctEngineFaces, TR.distinctEngineFaces]);
for (const s of SLOTS) {
  check(`slot ${s} distinct identical across both profiles`,
    T.perSlot[s].distinct === TR.perSlot[s].distinct, [T.perSlot[s].distinct, TR.perSlot[s].distinct]);
}

/* ---- F6: monotone v(C) < v(O) < v(P) on every authored variant ---- */
let mono = 0, monoBad = [];
for (const [cls, slots] of Object.entries(P.familyVariant)) {
  for (const [slot, vars] of Object.entries(slots)) {
    for (const [letter, tpl] of Object.entries(vars)) {
      mono++;
      if (!(tpl.v.C < tpl.v.O && tpl.v.O < tpl.v.P)) monoBad.push(`${cls}.${slot}.${letter}`);
    }
  }
}
check('I7: monotone C < O < P on every variant', monoBad.length === 0, monoBad);
check(`every non-spare variant emitted a value block (expect ${158 - T.spares} reachable; `
  + `a shortfall means that many §3.11 rows failed to parse)`, mono === 158 - T.spares,
  { emitted: mono, expected: 158 - T.spares });

/* ---- I25: SIG_LIFT stays inside its budget, and never merges a group ---- */
const SIG_LIFT_MAX = 3;
const lifts = P.manifest.sigLifts || [];
check(`I25: no SIG_LIFT exceeds SIG_LIFT_MAX (${SIG_LIFT_MAX})`,
  lifts.every((l) => l.to - l.from <= SIG_LIFT_MAX), lifts.filter((l) => l.to - l.from > SIG_LIFT_MAX));
const groups = {};
for (const [k, f] of Object.entries(P.signatureFace)) {
  if (f.t === 'buff' || f.t === 'debuff') continue;
  const g = `${f.p}|${f.t}|${f.k.slice().sort().join(',')}`;
  (groups[g] = groups[g] || []).push([k, f.v]);
}
const merged = Object.entries(groups)
  .filter(([, m]) => m.length > 1 && new Set(m.map((x) => x[1])).size !== m.length);
check('I25: no (p,t,sortedKeys) signature group has two faces at the same v', merged.length === 0, merged);
/* ---- R8 / SPREAD (§3.5d-bis) ---- */
const SPREAD_MAX_BUMP = 2;
const spread = P.manifest.spreadLog || [];
check('AC-9c: every one of the 285 parts has its own engine tuple (p,t,v,k)',
  T.distinctEngineFaces === 285, T.distinctEngineFaces);
check('AC-9b: every one of the 285 parts has its own (cls,p,t,v,k) tuple',
  T.distinctIdentityFaces === 285, T.distinctIdentityFaces);
check(`R8: no SPREAD bump exceeds SPREAD_MAX_BUMP (${SPREAD_MAX_BUMP})`,
  spread.every((l) => l.bumps <= SPREAD_MAX_BUMP), spread);
check('AC-7c: SPREAD never moved a legacy FACE_POOL face',
  spread.every((l) => !LEGACY.has(l.face)), spread.filter((l) => LEGACY.has(l.face)));
check('every slot reports zero lost faces', SLOTS.every((s) => T.perSlot[s].lost === 0),
  SLOTS.map((s) => [s, T.perSlot[s].lost]).filter((x) => x[1]));

check('§3.3c: the documented SIG_LIFT pairs are separated',
  P.signatureFace['aqua|ears|Gill'].v !== P.signatureFace['aqua|ears|Bubblemaker'].v
  && P.signatureFace['bird|eyes|Mavis'].v !== P.signatureFace['bird|eyes|Robin'].v,
  [P.signatureFace['aqua|ears|Gill'].v, P.signatureFace['aqua|ears|Bubblemaker'].v,
   P.signatureFace['bird|eyes|Mavis'].v, P.signatureFace['bird|eyes|Robin'].v]);

/* ---- I10 / I11: nothing dirty reaches runtime ---- */
const allFaces = [...Object.values(P.signatureFace)];
for (const slots of Object.values(P.familyVariant)) {
  for (const vars of Object.values(slots)) {
    for (const tpl of Object.values(vars)) {
      for (const b of ['C', 'O', 'P']) allFaces.push({ t: tpl.t, v: tpl.v[b], k: tpl.k });
    }
  }
}
check('I11: no NaN / undefined / Infinity in any emitted value',
  allFaces.every((f) => Number.isFinite(f.v) && typeof f.t === 'string' && Array.isArray(f.k)),
  allFaces.filter((f) => !Number.isFinite(f.v)).slice(0, 5));
check('I11: no keyword string carries NaN/undefined',
  allFaces.every((f) => f.k.every((k) => !/NaN|undefined|Infinity/.test(k))));
check('I10: shieldself appears zero times (never implemented — §3.7)',
  allFaces.every((f) => f.k.every((k) => !k.startsWith('shieldself'))));

/* ---- constants that are DERIVED, not free knobs (§7) ---- */
check('K27: SIG_IMPORT_SCALE === B[C] / B_REF',
  Math.abs(P.constants.SIG_IMPORT_SCALE - P.constants.B_C / P.constants.B_REF) < 1e-4,
  P.constants.SIG_IMPORT_SCALE);
check('I16: SPREAD_OWN === S_MAX × G_MAX and stays under 2.40',
  Math.abs(P.constants.SPREAD_OWN - P.constants.S_MAX * P.constants.G_MAX) < 1e-3
  && P.constants.SPREAD_OWN < 2.4, P.constants.SPREAD_OWN);
check('reference profile really is B[C] = 6.00', R.constants.B_C === 6, R.constants.B_C);
check('production profile really is B[C] = 2.80', P.constants.B_C === 2.8, P.constants.B_C);

console.log('---');
console.log(`${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
