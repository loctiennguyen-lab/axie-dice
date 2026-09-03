/* E13 Vault schema-2 migration test (design/gdd/part-skill-identity.md §5 E13).
   A vault record is a die RESOLVED AT IMPORT TIME. When the part->face rules change, every
   record written under the old rules keeps its old faces — so without a migration the new
   system is INVISIBLE to everyone who already imported, and they have no way to find out.
   This test pins the three visible halves of the migration: the stale record is flagged,
   it is refused by team-select, and a freshly imported record is not flagged.
   Run: python3 build.py && node tools/t_vault.mjs  (no server needed — loads file://) */
import { chromium } from 'playwright';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const dir = dirname(fileURLToPath(import.meta.url));
const FILE = 'file:' + join(dir, '..', 'AxieDiceTactics.html');
let pass = 0, fail = 0;
const check = (n, c, d) => { if (c) { pass++; console.log('PASS', n); } else { fail++; console.log('FAIL', n, d !== undefined ? '-> ' + JSON.stringify(d) : ''); } };

const b = await chromium.launch({ args: ['--no-sandbox'] });
const pg = await b.newPage();
await pg.addInitScript(() => {
  /* one v1 record (no `schema` field — exactly what shipped before) and one v2 record */
  const stale = { n: 'Axie #stale', cls: 'beast', tier: 1, hp: 14, art: 0, imported: true, axieId: 'stale',
    die: [{ p: 'mouth', t: 'dmg', v: 3, k: [], r: 0 }, { p: 'horn', t: 'dmg', v: 3, k: [], r: 0 },
      { p: 'back', t: 'shield', v: 3, k: [], r: 0 }, { p: 'tail', t: 'dmg', v: 3, k: [], r: 0 },
      { p: 'eyes', t: 'heal', v: 3, k: [], r: 0 }, { p: 'ears', t: 'mana', v: 1, k: ['cantrip'], r: 0 }] };
  const fresh = JSON.parse(JSON.stringify(stale));
  fresh.n = 'Axie #fresh'; fresh.axieId = 'fresh'; fresh.schema = 2; fresh.parts = [];
  localStorage.setItem('axiedice_meta_v2', JSON.stringify({ vault: [stale, fresh] }));
});
await pg.goto(FILE, { waitUntil: 'networkidle' });
await pg.evaluate(() => { screen = 'team'; render(); });
await pg.waitForTimeout(300);

const chips = await pg.$$eval('.vchip', els => els.map(e => ({
  name: e.querySelector('.vchip-nm') ? e.querySelector('.vchip-nm').textContent : '',
  stale: e.classList.contains('stale'),
  badge: !!e.querySelector('.vchip-rescan'),
})));
check('both vault entries render', chips.length === 2, chips);
const st = chips.find(c => /stale/.test(c.name)), fr = chips.find(c => /fresh/.test(c.name));
check('E13: the pre-migration (schema-less) entry is flagged stale', !!st && st.stale, st);
check('E13: it shows a RE-SCAN badge so the player knows what to do', !!st && st.badge, st);
check('E13: a schema-2 entry is NOT flagged', !!fr && !fr.stale && !fr.badge, fr);

const idx = chips.findIndex(c => /stale/.test(c.name));
await pg.$$eval('.vchip', (els, i) => els[i].click(), idx);
await pg.waitForTimeout(200);
check('E13: clicking a stale entry does NOT add it to the team',
  await pg.evaluate(() => teamPick.filter(k => k === 'vault_stale').length) === 0);
check('E13: the refusal explains itself instead of failing silently',
  /re-import/i.test(await pg.evaluate(() => (document.body.innerText || ''))));

const fidx = chips.findIndex(c => /fresh/.test(c.name));
await pg.$$eval('.vchip', (els, i) => els[i].click(), fidx);
await pg.waitForTimeout(200);
check('E13: a schema-2 entry is still selectable (the gate is targeted, not a blanket block)',
  await pg.evaluate(() => teamPick.filter(k => k === 'vault_fresh').length) === 1);

const errs = [];
pg.on('pageerror', e => errs.push(String(e)));
check('no NaN/undefined leaked into the vault UI (UI rule 6)',
  !/\b(NaN|undefined|null)\b/.test(await pg.$eval('.vaultgrid', e => e.innerText)));
await b.close();
console.log('---\n' + pass + ' passed, ' + fail + ' failed');
process.exit(fail ? 1 : 0);
