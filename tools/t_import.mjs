/* Unit tests for the Import Axie mapping engine (axieToDie/mapAxieClass, engine.js).
   Pure logic — no browser needed, follows sim.js's require-via-vm pattern.
   Run: node tools/t_import.mjs */
import fs from 'node:fs';
import vm from 'node:vm';

const ctx = { console, Math, JSON };
vm.createContext(ctx);
const NAMES = ['HEROES', 'CLASSES', 'SLOT_CLASS_TEMPLATE', 'ORIGIN_CLASS_MAP', 'ORIGIN_TIER3_MULT',
  'mapAxieClass', 'axieToDie'];
const src = ['src/data.js', 'src/engine.js'].map(f => fs.readFileSync(f, 'utf8')).join('\n')
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
check('axieToDie: hp matches HEROES beast1 tier1', die1.hp === G.HEROES.beast1.hp, die1.hp);
check('axieToDie: imported flag + axieId set', die1.imported === true && die1.axieId === '100000');
check('axieToDie: no NaN/undefined in any face value',
  die1.die.every(f => f && Number.isFinite(f.v) && f.t && Array.isArray(f.k) && Number.isFinite(f.r)),
  die1.die);
check('axieToDie: each face mapped by the PART\'s own class, not the body class',
  die1.die[0].t === G.SLOT_CLASS_TEMPLATE.eyes.bug.t, die1.die[0]);

/* ---- Origin class fallback (Dawn/Dusk/Mech) ---- */
const originSample = {
  id: '1', class: 'Dawn',
  parts: [{ id: 'horn-x', name: 'X', class: 'Dawn', type: 'Horn', specialGenes: null }],
};
const dieOrigin = G.axieToDie(originSample);
const originCls = G.ORIGIN_CLASS_MAP['dawn'];
const baseFace = G.SLOT_CLASS_TEMPLATE.horn[originCls];
check('axieToDie: Origin part value scaled by ORIGIN_TIER3_MULT',
  dieOrigin.die[0].v === Math.round(baseFace.v * G.ORIGIN_TIER3_MULT),
  { got: dieOrigin.die[0].v, base: baseFace.v, mult: G.ORIGIN_TIER3_MULT });
check('axieToDie: Origin part rarity forced to >=3 (Legendary)', dieOrigin.die[0].r >= 3, dieOrigin.die[0].r);

/* ---- specialGenes bump ---- */
const sgSample = {
  id: '2', class: 'Beast',
  parts: [{ id: 'mouth-x', name: 'X', class: 'Plant', type: 'Mouth', specialGenes: '000000' }],
};
const dieSg = G.axieToDie(sgSample);
const baseMouthPlant = G.SLOT_CLASS_TEMPLATE.mouth.plant;
check('axieToDie: specialGenes part value scaled by 1.3',
  dieSg.die[0].v === Math.round(baseMouthPlant.v * 1.3),
  { got: dieSg.die[0].v, base: baseMouthPlant.v });
check('axieToDie: specialGenes part rarity forced to >=1 (Rare)', dieSg.die[0].r >= 1, dieSg.die[0].r);

/* ---- Origin + specialGenes compounding (both bumps apply, in that order) ---- */
const bothSample = {
  id: '3', class: 'Mech',
  parts: [{ id: 'horn-x', name: 'X', class: 'Mech', type: 'Horn', specialGenes: '000000' }],
};
const dieBoth = G.axieToDie(bothSample);
const bothOriginCls = G.ORIGIN_CLASS_MAP['mech'];
const bothBase = G.SLOT_CLASS_TEMPLATE.horn[bothOriginCls];
const expected = Math.round(Math.round(bothBase.v * G.ORIGIN_TIER3_MULT) * 1.3);
check('axieToDie: Origin+specialGenes compound in the documented order (origin mult, then x1.3)',
  dieBoth.die[0].v === expected, { got: dieBoth.die[0].v, expected });
check('axieToDie: compounded value has no overflow/NaN', Number.isFinite(dieBoth.die[0].v) && dieBoth.die[0].v > 0);

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
