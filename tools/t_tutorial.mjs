/* Onboarding tutorial test suite (design/gdd/onboarding-tutorial.md).
   Covers the doc's §8 Acceptance Criteria that are actually automatable:
   determinism + content of the TUT_SEED/TUT_TEAM fixture, needsTutorial()'s
   truth table, migrateMeta()'s backfill for pre-existing saves, the gate
   deciding tutorial-vs-menu, the full coached click-path (with the
   pointer-events lock actually blocking a non-taught die), and the
   TUT_ENEMY_HP tuning knob's "wins within 3 turns" requirement. Not
   automated here (documented, not gated): the cross-device sync-fail edge
   case and dragged (as opposed to clicked) execution — see the GDD §5/§3.5.
   Run: python3 build.py && node tools/t_tutorial.mjs (no server — file://) */
import { chromium } from 'playwright';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const dir = dirname(fileURLToPath(import.meta.url));
const HTML_PATH = join(dir, '..', 'AxieDiceTactics.html');
const FILE = 'file:' + HTML_PATH;
let pass = 0, fail = 0;
const check = (n, c, d) => { if (c) { pass++; console.log('PASS', n); } else { fail++; console.log('FAIL', n, d !== undefined ? '-> ' + JSON.stringify(d) : ''); } };

/* ---------- grep-based: decision #1 (design doc) actually applied ---------- */
{
  const src = readFileSync(join(dir, '..', 'src', 'client.html'), 'utf8');
  check('dead TUT[] array is gone', !/const TUT\s*=/.test(src));
  check('dead tutOverlay() is gone', !/function tutOverlay\(/.test(src));
  // META.tut (the persistent flag), .tut-locking/.tut-allow (CSS), and
  // tutStep/tutPhase/etc. are all intentional — only the OLD bare counter
  // variable (`let ... tut=0`, `tut++`, `tut-1` array indexing) is dead.
  check('no stray bare `tut` counter variable (declaration/increment)', !/,\s*tut=0\b|\btut\+\+|\btut-1\b/.test(src));
}

const b = await chromium.launch({ args: ['--no-sandbox'] });

/* ---------- needsTutorial() truth table (§4 Formulas worked examples) ---------- */
{
  const pg = await b.newPage();
  await pg.goto(FILE, { waitUntil: 'networkidle' });
  const cases = await pg.evaluate(() => ([
    needsTutorial({ tut: 0, runs: 0 }),           // brand new account
    needsTutorial({ tut: 1, runs: 0 }),           // already completed, no runs yet
    needsTutorial({ tut: 0, runs: 5 }),           // pre-existing save, tut missing/stale
    needsTutorial({ tut: 1, runs: 12 }),          // ordinary returning player
  ]));
  check('needsTutorial: {tut:0,runs:0} -> true', cases[0] === true, cases[0]);
  check('needsTutorial: {tut:1,runs:0} -> false', cases[1] === false, cases[1]);
  check('needsTutorial: {tut:0,runs:5} -> false (runs>0 backstop)', cases[2] === false, cases[2]);
  check('needsTutorial: {tut:1,runs:12} -> false', cases[3] === false, cases[3]);
  await pg.close();
}

/* ---------- migrateMeta() backfill for a pre-existing save ---------- */
{
  const pg = await b.newPage();
  await pg.addInitScript(() => {
    localStorage.setItem('axiedice_meta_v2', JSON.stringify({ runs: 5 })); // no `tut` field at all
  });
  await pg.goto(FILE, { waitUntil: 'networkidle' });
  await pg.waitForTimeout(300);
  const tut = await pg.evaluate(() => META.tut);
  check('migrateMeta() backfills tut=1 for a save with runs>0', tut === 1, tut);
  await pg.close();
}

/* ---------- determinism + content of the TUT_SEED/TUT_TEAM fixture ---------- */
{
  const pg = await b.newPage();
  await pg.goto(FILE, { waitUntil: 'networkidle' });
  const snap = () => pg.evaluate(() => {
    startTutorial();
    return {
      faces: S.party.map(u => ({ p: u.die[u.rolled].p, t: u.die[u.rolled].t, v: u.die[u.rolled].v })),
      enemyHp: S.enemies.map(e => e.hp),
      phase: S.phase, turn: S.turn,
    };
  });
  const a = await snap(), c = await snap();
  check('TUT_SEED/TUT_TEAM roll is deterministic (2 calls, same result)', JSON.stringify(a) === JSON.stringify(c), { a, c });
  check('fixture starts in combat, turn 1', a.phase === 'combat' && a.turn === 1, a);
  check('fixture has >=1 dmg face for the party (step 4 needs one)', a.faces.some(f => f.t === 'dmg'), a.faces);
  check('fixture has >=1 utility face (heal/mana/shield) for the party', a.faces.some(f => ['heal', 'mana', 'shield'].includes(f.t)), a.faces);
  check('TUT_ENEMY_HP tuning applied to both enemies', a.enemyHp.every(hp => hp === a.enemyHp[0]) && a.enemyHp[0] > 0 && a.enemyHp[0] <= 10, a.enemyHp);
  await pg.close();
}

/* ---------- TUT_ENEMY_HP: the fight actually ends within <=3 turns ---------- */
{
  const pg = await b.newPage();
  await pg.goto(FILE, { waitUntil: 'networkidle' });
  const result = await pg.evaluate(() => {
    startTutorial();
    let guard = 0;
    while (S.phase === 'combat' && S.turn <= 3 && guard++ < 200) {
      const actor = S.party.find(u => u.hp > 0 && u.rolled >= 0 && !u.used && u.die[u.rolled].t !== 'blank');
      if (!actor) { endTurn(S); continue; }
      const targets = validTargets(actor);
      if (!targets.length) { actor.used = true; continue; }
      playerUseDie(S, actor.uid, targets[0]);
    }
    return { phase: S.phase, turn: S.turn };
  });
  check('mock battle reaches reward within <=3 turns using only rolled faces', result.phase === 'reward' && result.turn <= 3, result);
  await pg.close();
}

/* ---------- gate: enterMenu() picks tutorial vs menu correctly ---------- */
{
  const pg = await b.newPage();
  await pg.goto(FILE, { waitUntil: 'networkidle' });
  const fresh = await pg.evaluate(() => { META = { ...DEF_META, tut: 0, runs: 0 }; enterMenu(); return screen; });
  check('enterMenu(): brand-new account -> screen=tutorial', fresh === 'tutorial', fresh);
  const veteran = await pg.evaluate(() => { META = { ...DEF_META, tut: 0, runs: 5 }; enterMenu(); return screen; });
  check('enterMenu(): account with runs>0 -> screen=menu (no exception, even mid-migration)', veteran === 'menu', veteran);
  await pg.close();
}

/* ---------- full coached click-path, incl. the lock actually blocking a wrong die ---------- */
{
  const pg = await b.newPage();
  await pg.addInitScript(() => { localStorage.setItem('axiedice_meta_v2', JSON.stringify({ tut: 0, runs: 0 })); });
  await pg.goto(FILE, { waitUntil: 'networkidle' });
  await pg.evaluate(() => { META = { ...DEF_META, tut: 0, runs: 0 }; enterMenu(); render(); });
  await pg.waitForTimeout(200);
  check('gate lands a brand-new account on the tutorial screen', await pg.evaluate(() => screen) === 'tutorial');

  await pg.click('.tutcoach-big-bx .btn'); // WELCOME (0) -> step 1
  await pg.waitForTimeout(150);
  check('WELCOME "START" advances to step 1 (roll)', await pg.evaluate(() => tutStep) === 1);

  await pg.click('.tutcoach-bx .btn'); // step 1 -> 2
  await pg.waitForTimeout(150);
  check('step 1 "GOT IT" advances to step 2 (intent)', await pg.evaluate(() => tutStep) === 2);

  // Step 4a/4b lock: the NON-taught die must not react to a click while locked.
  // Uses Playwright's page.click() (a real, hit-tested mouse click) rather
  // than element.click() — the DOM method bypasses pointer-events entirely,
  // so it would prove nothing about the lock (same gotcha as the global
  // keyboard shortcuts, see client.html's keydown-handler comment).
  const wrongUid = await pg.evaluate(() => {
    tutStep = 3; S.rerolls = 0; render(); // jump straight past intent/reroll
    return S.party.find(u => u.uid !== tutActor().uid).uid;
  });
  await pg.click(`.diebox[data-uid="${wrongUid}"] .die`, { timeout: 1500 }).catch(() => {});
  const selAfterLockedClick = await pg.evaluate(() => sel);
  check('tut-locking actually blocks clicking a non-taught die', selAfterLockedClick !== wrongUid, selAfterLockedClick);

  await pg.evaluate(() => { tutStep = 2; tutIntentSeen = false; S.rerolls = S.maxRerolls; render(); });
  await pg.click('.unit.e'); // opens the intent modal
  await pg.waitForTimeout(150);
  check('clicking an enemy card opens the intent modal', await pg.evaluate(() => modal === 'unit'));
  await pg.keyboard.press('Escape');
  await pg.waitForTimeout(150);
  check('closing the intent modal advances past step 2', await pg.evaluate(() => tutStep) === 3);

  await pg.click('.btn.reroll');
  await pg.waitForTimeout(150);
  check('REROLL is clickable at step 3 and consumes a reroll', await pg.evaluate(() => S.rerolls < S.maxRerolls));

  // tutActor()/its target are recomputed AFTER the reroll (see client.html's
  // comment on tutActor() — this is exactly the bug that comment documents:
  // a die fixed BEFORE reroll can reroll onto a face that can't legally
  // target what was fixed as "the" target).
  const dieUid = await pg.evaluate(() => tutActor().uid);
  await pg.click(`.diebox[data-uid="${dieUid}"] .die`);
  await pg.waitForTimeout(150);
  check('clicking the taught die selects it', await pg.evaluate(() => sel) === dieUid);

  const tgtUid = await pg.evaluate(uid => validTargets(S.party.find(u => u.uid === uid))[0], dieUid);
  await pg.click(`.unit[data-uid="${tgtUid}"]`);
  // afterAct() is async (awaits playEvents()'s float/damage-number playback)
  // before it finishes; doEndTurn() itself no-ops while `playing` is still
  // true, so a fixed short wait here was flaky — poll instead.
  await pg.waitForFunction(() => !playing && !rollAnim, null, { timeout: 5000 });
  const taughtUsed = await pg.evaluate(uid => S.party.find(u => u.uid === uid).used, dieUid);
  check('clicking the taught target executes the die', taughtUsed === true);

  await pg.click('.btn.end');
  await pg.waitForFunction(() => !playing && !rollAnim, null, { timeout: 5000 });
  await pg.waitForTimeout(200);
  // Usually advances to turn 2, but if the taught die happened to reroll
  // onto an `aoe` face strong enough to wipe both TUT_ENEMY_HP=6 enemies at
  // once, the fight can legitimately end (S.phase='reward') on turn 1
  // itself — engine.js's endTurn() never increments `turn` in that case.
  // Both outcomes are a correct, "wins within <=3 turns" fixture; only a
  // stuck turn-1-combat would be a real bug.
  const post = await pg.evaluate(() => ({ turn: S.turn, phase: S.phase }));
  check('END TURN is reachable and the fight progresses', post.turn >= 2 || post.phase !== 'combat', post);

  // Free play (turns 2-3, no lock) — finish the fight with a small in-page bot,
  // same approach as the TUT_ENEMY_HP test above, then take a reward.
  await pg.evaluate(() => {
    let guard = 0;
    while (S.phase === 'combat' && guard++ < 200) {
      const actor = S.party.find(u => u.hp > 0 && u.rolled >= 0 && !u.used && u.die[u.rolled].t !== 'blank');
      if (!actor) { endTurn(S); continue; }
      const targets = validTargets(actor);
      if (!targets.length) { actor.used = true; continue; }
      playerUseDie(S, actor.uid, targets[0]);
    }
    render();
  });
  await pg.waitForTimeout(200);
  check('fight resolves to reward phase', await pg.evaluate(() => S.phase) === 'reward');
  await pg.click('.rcard');
  await pg.waitForTimeout(200);
  check('taking a reward reaches the DONE beat (not straight to menu)', await pg.evaluate(() => tutStep) === 8);
  check('taking a reward does NOT finish onboarding yet (screen still tutorial)', await pg.evaluate(() => screen) === 'tutorial');
  await pg.click('.tutcoach-big-bx .btn'); // DONE (8) -> "START PLAYING"
  await pg.waitForTimeout(150);
  check('DONE "START PLAYING" finishes onboarding: META.tut=1', await pg.evaluate(() => META.tut) === 1);
  check('DONE "START PLAYING" finishes onboarding: screen=menu', await pg.evaluate(() => screen) === 'menu');
  await pg.close();
}

await b.close();
console.log('---\n' + pass + ' passed, ' + fail + ' failed');
process.exit(fail ? 1 : 0);
