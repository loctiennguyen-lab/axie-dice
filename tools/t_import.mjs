/* Unit tests for the Import Axie mapping engine (axieToDie/mapAxieClass, engine.js).
   Pure logic — no browser needed, follows sim.js's require-via-vm pattern.
   Run: node tools/t_import.mjs */
import fs from 'node:fs';
import vm from 'node:vm';

const ctx = { console, Math, JSON };
vm.createContext(ctx);
const NAMES = ['HEROES', 'CLASSES', 'SLOT_CLASS_TEMPLATE', 'ORIGIN_CLASS_MAP', 'ORIGIN_TIER3_MULT',
  'mapAxieClass', 'axieToDie', 'partKey', 'sgTier', 'diePurity', 'coherenceMod', 'specialGeneCount', 'SLOT_ORDER', 'PART_FACES'];
const src = ['src/data.js', 'src/part_faces.js', 'src/engine.js'].map(f => fs.readFileSync(f, 'utf8')).join('\n')
  + '\n;globalThis.__X={' + NAMES.map(n => n + ':' + n).join(',') + '};';
vm.runInContext(src, ctx);
const G = ctx.__X;

let pass = 0, fail = 0;
function check(name, cond, detail) {
  if (cond) { pass++; console.log('PASS', name); }
  else { fail++; console.log('FAIL', name, detail !== undefined ? '-> ' + JSON.stringify(detail) : ''); }
}

/* ---- mapAxieClass ---- */
check('mapAxieClass: exact game class passes through', G.mapAxieClass('beast') === 'beast');
check('mapAxieClass: Axie API PascalCase normalizes', G.mapAxieClass('Beast') === 'beast');
check('mapAxieClass: Aquatic -> aqua', G.mapAxieClass('Aquatic') === 'aqua');
check('mapAxieClass: Dawn/Dusk/Mech map to a fixed real class, never crash',
  G.CLASSES.includes(G.mapAxieClass('Dawn')) && G.CLASSES.includes(G.mapAxieClass('Dusk')) && G.CLASSES.includes(G.mapAxieClass('Mech')));
check('mapAxieClass: unknown/garbage input falls back safely, never throws',
  (() => { try { return G.CLASSES.includes(G.mapAxieClass('nonsense')) && G.CLASSES.includes(G.mapAxieClass(undefined)); } catch (e) { return false; } })());

/* ---- axieToDie: basic shape ---- */
const sample = {
  id: '100000', class: 'Beast',
  parts: [
    { id: 'eyes-bookworm', name: 'Bookworm', class: 'Bug', type: 'Eyes', specialGenes: null },
    { id: 'ears-owl', name: 'Owl', class: 'Bird', type: 'Ears', specialGenes: null },
    { id: 'mouth-zigzag', name: 'Zigzag', class: 'Plant', type: 'Mouth', specialGenes: null },
    { id: 'horn-unko', name: 'Unko', class: 'Reptile', type: 'Horn', specialGenes: null },
    { id: 'back-anemone', name: 'Anemone', class: 'Aquatic', type: 'Back', specialGenes: null },
    { id: 'tail-twin-tail', name: 'Twin Tail', class: 'Bug', type: 'Tail', specialGenes: null },
  ],
};
const die1 = G.axieToDie(sample);
check('axieToDie: exactly 6 faces', die1.die.length === 6, die1.die.length);
check('axieToDie: body class mapped correctly', die1.cls === 'beast', die1.cls);
/* §3.4b — Max HP is no longer a straight copy of the tier-1 hero: coherence scales it, so a
   fully mixed Axie is slightly frailer. A mono-class Axie still lands exactly on the hero value. */
check('axieToDie: hp = round(HEROES[cls+"1"].hp x coherence)',
  die1.hp === Math.max(1, Math.round(G.HEROES.beast1.hp * die1.coh)), { hp: die1.hp, coh: die1.coh });
check('axieToDie: imported flag + axieId set', die1.imported === true && die1.axieId === '100000');
check('axieToDie: no NaN/undefined in any face value',
  die1.die.every(f => f && Number.isFinite(f.v) && f.t && Array.isArray(f.k) && Number.isFinite(f.r)),
  die1.die);
/* die[0] is NO LONGER the first part in API order: axieToDie sorts by SLOT_ORDER before
   slice(0,6) (N3/E2). That sort is load-bearing — api/submit-run.js replays the action log
   server-side, so a die that depends on API response order scores the wrong run. Assert the
   SET of faces, plus the sort itself. */
check('axieToDie: every part contributes a face carrying its own slot (not the body class)',
  new Set(die1.die.map(f => f.p)).size === 6 && die1.die.every(f => f.t !== 'blank'), die1.die.map(f => f.p));
check('N3: faces come out in SLOT_ORDER regardless of API order',
  JSON.stringify(die1.die.map(f => f.p)) === JSON.stringify(G.SLOT_ORDER), die1.die.map(f => f.p));
check('N3: shuffling the input parts yields a byte-identical die',
  JSON.stringify(G.axieToDie({ ...sample, parts: sample.parts.slice().reverse() }).die) === JSON.stringify(die1.die));

/* ---- §3.1 partKey + §3.4 scarcity bucket ---- */
check('partKey: stage suffixes are stripped and class normalised (Aquatic -> aqua)',
  G.partKey({ class: 'Aquatic', type: 'Ears', name: 'Gill α' }) === 'aqua|ears|Gill',
  G.partKey({ class: 'Aquatic', type: 'Ears', name: 'Gill α' }));
check('partKey: the slot is part of the identity, so Nut Cracker mouth != Nut Cracker tail',
  G.partKey({ class: 'Beast', type: 'Mouth', name: 'Nut Cracker' })
  !== G.partKey({ class: 'Beast', type: 'Tail', name: 'Nut Cracker' }));
const BUCK = G.PART_FACES.scarcityBucket;
check('§3.4: bucket is read from the catalog, C/O/P split as designed',
  BUCK['beast|tail|Shiba'] === 'P' && BUCK['aqua|ears|Gill'] === 'P',
  [BUCK['beast|tail|Shiba'], BUCK['aqua|ears|Gill']]);

/* ---- §5 E1: a real part that is NOT in the catalog (the highest-probability edge case;
        the catalog already grew 192 -> 285 once and Sky Mavis ships parts whenever it likes) ---- */
const unmapped = [];
ctx.telemetryHook = (evt, data) => { if (evt === 'part_unmapped') unmapped.push(data); };
const e1 = G.axieToDie({ id: 'e1', class: 'Bird', parts: [{ id: 'x', name: 'Owl', class: 'Bird', type: 'Ears', specialGenes: null }] });
const e1f = e1.die[0], famA = G.PART_FACES.familyVariant.bird.ears.A;
check('E1: an uncatalogued part resolves to its family variant A, never blank',
  e1f.src === 'fallback' && e1f.t === famA.t && e1f.variant === 'A', e1f);
check('E1: the fallback is pinned to bucket C, so a new part can never be the strongest thing in the game',
  e1f.bucket === 'C' && e1f.v === famA.v.C, [e1f.bucket, e1f.v, famA.v.C]);
check('E1: the fallback still shows the part\'s real name (player fantasy, not "Unknown Part")',
  e1f.name === 'Owl', e1f.name);
check('E1: part_unmapped telemetry fires — the only operational signal that the catalog drifted',
  unmapped.length === 1 && unmapped[0].slot === 'ears' && unmapped[0].name === 'Owl', unmapped);
ctx.telemetryHook = undefined;

/* ---- §5 E3: genuinely unrecognisable slot/class stays blank, so the two paths remain distinct ---- */
const e3 = G.axieToDie({ id: 'e3', class: 'Beast', parts: [{ id: 'z', name: 'Q', class: 'Beast', type: 'Antenna', specialGenes: null }] });
check('E3: an unrecognisable SLOT yields blank, not a family face',
  e3.die.every(f => f.t === 'blank'), e3.die[0]);
const e3c = G.axieToDie({ id: 'e3c', class: 'Beast', parts: [{ id: 'z', name: 'Q', class: 'Nonsense', type: 'Mouth', specialGenes: null }] });
check('E3: an unrecognisable CLASS yields blank too', e3c.die[0].t === 'blank', e3c.die[0]);

/* ---- AC-1: purity. api/submit-run.js re-runs the action log server-side to score ranked runs,
        so an impurity corrupts SCORES rather than throwing. ---- */
let drift = 0;
const pin = JSON.stringify(G.axieToDie(sample));
for (let i = 0; i < 200; i++) if (JSON.stringify(G.axieToDie(sample)) !== pin) drift++;
check('AC-1: 200 re-derivations of the same Axie are byte-identical', drift === 0, drift);

/* ---- §3.4a: the 8-tier gene ladder ---- */
const geneAxie = g => ({ id: 'g', class: 'Beast', parts: [{ id: 'm', name: 'Nut Cracker', class: 'Beast', type: 'Tail', specialGenes: g }] });
check('§3.4a: an unrecognised gene string resolves to tier 0, it does NOT grant power',
  G.sgTier({ specialGenes: 'brand-new-2027-gene' }) === 0 && G.sgTier({ specialGenes: 'mystic' }) === 6,
  [G.sgTier({ specialGenes: 'brand-new-2027-gene' }), G.sgTier({ specialGenes: 'mystic' })]);
check("E16-bis: '000000' is an all-zero bitmask = NO gene (v1 used it as the HAS-gene fixture)",
  G.sgTier({ specialGenes: '000000' }) === 0 && G.sgTier({ specialGenes: null }) === 0);
check('§3.4a: the ladder is ordered — agamogenesis > mystic > summer > normal',
  G.sgTier({ specialGenes: 'agamogenesis' }) > G.sgTier({ specialGenes: 'mystic' })
  && G.sgTier({ specialGenes: 'mystic' }) > G.sgTier({ specialGenes: 'summer' })
  && G.sgTier({ specialGenes: 'summer' }) > 0);
check('§3.4a: a higher gene tier never lowers the face rarity, and raises it by tier 5+',
  G.axieToDie(geneAxie('mystic')).die[0].r > G.axieToDie(geneAxie(null)).die[0].r,
  [G.axieToDie(geneAxie('mystic')).die[0].r, G.axieToDie(geneAxie(null)).die[0].r]);
check('§3.4a-3: gene `origin` is neutralised on an O/P bucket part (bucket already prices it)',
  JSON.stringify(G.axieToDie(geneAxie('origin')).die[0]) === JSON.stringify(G.axieToDie(geneAxie(null)).die[0]));
check('F8: a variant face is capped at r<=3 — only a signature may push a die to COSMIC',
  G.axieToDie(geneAxie('agamogenesis')).die[0].r <= 3);
check('E16: specialGeneCount counts PARTS with a real gene, clamped 0-3',
  G.specialGeneCount({ parts: [{ specialGenes: 'mystic' }, { specialGenes: '000000' }, { specialGenes: 'summer' }] }) === 2);

/* ---- §3.4b: coherence hits BOTH face value and Max HP ---- */
const mono = { id: 'pure', class: 'Beast', parts: sample.parts.map(p => ({ ...p, class: 'Beast' })) };
const purd = G.axieToDie(mono), mixd = G.axieToDie(sample);
/* Read the ladder from the generated data, not from a literal: K25 is a live balance knob
   (it was retuned 2026-09-03 to land the imported-team sim gate) and a hardcoded 1.00/0.82
   turns every future tune into a false test failure. The PROPERTY is what matters: purity 6
   gets the ladder's top value, and a fully mixed die sits on the bottom rung, never below it. */
const COH = G.PART_FACES.constants.COH;
check('§3.4b: a mono-class Axie has purity 6 and the ladder\'s top coherence',
  purd.purity === 6 && purd.coh === COH['6'], [purd.purity, purd.coh, COH['6']]);
check('§3.4b: a fully mixed Axie is penalised but never gated (lands on the ladder floor)',
  mixd.coh < COH['6'] && mixd.coh >= COH['0'], [mixd.coh, COH['0']]);
check('§3.4b: the ladder is monotone — more purity is never worth less',
  [0,1,2,3,4,5].every(i => COH[String(i)] < COH[String(i+1)]), COH);
check('§3.4b: coherence lowers Max HP as well as face value',
  mixd.hp < purd.hp && mixd.hp === Math.max(1, Math.round(G.HEROES.beast1.hp * mixd.coh)), [mixd.hp, purd.hp]);
check('§3.4b: a die missing parts keeps the RATIO, so it is not punished twice for blanks',
  G.axieToDie({ id: 'p3', class: 'Beast', parts: mono.parts.slice(0, 3) }).coh === COH['6']);

/* ---- the headline promise: same class, different parts => different dice ---- */
const twinA = { id: 'A', class: 'Beast', parts: [
  { id: '1', name: 'Cub', class: 'Beast', type: 'Mouth', specialGenes: null },
  { id: '2', name: 'Imp', class: 'Beast', type: 'Horn', specialGenes: null },
  { id: '3', name: 'Ronin', class: 'Beast', type: 'Back', specialGenes: null },
  { id: '4', name: 'Shiba', class: 'Beast', type: 'Tail', specialGenes: null },
  { id: '5', name: 'Zeal', class: 'Beast', type: 'Eyes', specialGenes: null },
  { id: '6', name: 'Nyan', class: 'Beast', type: 'Ears', specialGenes: null }] };
const twinB = { id: 'B', class: 'Beast', parts: [
  { id: '1', name: 'Axie Kiss', class: 'Beast', type: 'Mouth', specialGenes: null },
  { id: '2', name: 'Pocky', class: 'Beast', type: 'Horn', specialGenes: null },
  { id: '3', name: 'Hero', class: 'Beast', type: 'Back', specialGenes: null },
  { id: '4', name: 'Puppy', class: 'Beast', type: 'Tail', specialGenes: null },
  { id: '5', name: 'Little Peas', class: 'Beast', type: 'Eyes', specialGenes: null },
  { id: '6', name: 'Puppy', class: 'Beast', type: 'Ears', specialGenes: null }] };
const dA = G.axieToDie(twinA).die, dB = G.axieToDie(twinB).die;
const tup = f => `${f.p}|${f.t}|${f.v}|${f.k.slice().sort().join(',')}`;
check('two same-class Axies with different parts produce six pairwise-different faces',
  dA.every((f, i) => tup(f) !== tup(dB[i])), dA.map((f, i) => [tup(f), tup(dB[i])]).filter(x => x[0] === x[1]));
check('every face inside one die is itself distinct (no 19-face collapse like SLOT_CLASS_TEMPLATE)',
  new Set(dA.map(tup)).size === 6 && new Set(dB.map(tup)).size === 6,
  [new Set(dA.map(tup)).size, new Set(dB.map(tup)).size]);

/* ---- edge cases: too few / too many parts ---- */
const shortDie = G.axieToDie({ id: '4', class: 'Beast', parts: sample.parts.slice(0, 3) });
check('axieToDie: fewer than 6 parts still yields exactly 6 faces (blank-padded)',
  shortDie.die.length === 6, shortDie.die.length);
check('axieToDie: padded faces are blank, not crashed/undefined',
  shortDie.die.slice(3).every(f => f.t === 'blank'), shortDie.die.slice(3));

const longParts = sample.parts.concat([{ id: 'extra', name: 'Extra', class: 'Bug', type: 'Tail', specialGenes: null }]);
const longDie = G.axieToDie({ id: '5', class: 'Beast', parts: longParts });
check('axieToDie: more than 6 parts is truncated to 6, not overflowed', longDie.die.length === 6, longDie.die.length);

const emptyDie = G.axieToDie({ id: '6', class: 'Beast', parts: [] });
check('axieToDie: zero parts never throws, yields 6 blank faces',
  emptyDie.die.length === 6 && emptyDie.die.every(f => f.t === 'blank'));

const nullDie = G.axieToDie({ id: '7', class: null, parts: null });
check('axieToDie: null class/parts never throws', G.CLASSES.includes(nullDie.cls) && nullDie.die.length === 6);

/* ---- unknown slot name never crashes (defensive against future API field changes) ---- */
const weirdSlot = G.axieToDie({ id: '8', class: 'Beast', parts: [{ id: 'x', name: 'X', class: 'Beast', type: 'Wing', specialGenes: null }] });
check('axieToDie: unrecognized slot name falls back safely instead of crashing',
  weirdSlot.die.length === 6 && Number.isFinite(weirdSlot.die[0].v));

console.log('---');
console.log(pass + ' passed, ' + fail + ' failed');
process.exit(fail ? 1 : 0);

/* ---- §3.4c / N15 — reward starvation. An imported Axie has no TIER_UP entry, so it can never
       take 'level'. Before the fix, 'ascend' only entered the pool when NO roster member could
       level, which for a mixed hero+vault team is almost never — the imported Axie was starved
       of its only growth path for most of a run. The fix ADDS to the pool rather than replacing
       the else-branch, so an all-hero roster keeps its exact previous distribution (AC-31). ---- */
const G2 = ctx.__X2 || (() => {
  vm.runInContext('\n;globalThis.__X2={genRewards,HEROES,TIER_UP,newRosterEntry};', ctx);
  return ctx.__X2;
})();
function pooledRewards(roster) {
  const s = { rewardTier: 0, mods: { rewards: 3 }, pw: 4, roster, maxRerolls: 4, relics: [], seen: {} };
  const kinds = new Set();
  for (let i = 0; i < 400; i++) { G2.RNG_SEED = i; try { G2.genRewards(s, 'node').forEach(r => kinds.add(r.t)); } catch (e) { /* reward gen needs no RNG seed reset here */ } }
  return kinds;
}
const heroKey = Object.keys(G2.TIER_UP)[0];
const vaultHero = { n: 'V', cls: 'beast', tier: 1, hp: 14, art: 0, imported: true,
  die: G.axieToDie(twinA).die };
G2.HEROES.vault_test = vaultHero;
const mixed = [G2.newRosterEntry(heroKey), G2.newRosterEntry('vault_test')];
const allHero = [G2.newRosterEntry(heroKey), G2.newRosterEntry(heroKey)];
const mixedKinds = pooledRewards(mixed), heroKinds = pooledRewards(allHero);
check('§3.4c: a mixed hero+vault roster CAN roll ASCENSION (the imported Axie\'s only growth path)',
  mixedKinds.has('ascend'), [...mixedKinds]);
check('AC-31: an all-hero roster still cannot roll ASCENSION while a hero can level (unchanged)',
  !heroKinds.has('ascend'), [...heroKinds]);
