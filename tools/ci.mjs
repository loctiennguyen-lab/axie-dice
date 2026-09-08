/* ci.mjs — the single test entry point for Axie Dice Tactics.
 *
 * Run:  node tools/ci.mjs            everything (needs playwright browsers + python3)
 *       node tools/ci.mjs --fast     logic suites only, no browser and no server
 *       node tools/ci.mjs --help
 *
 * PREREQUISITES — two of these are non-obvious and both have cost time before:
 *
 *   1. `npm install` MUST have been run. The repo has no committed node_modules, and without
 *      it `t_aoe`, `t_fit` and `verify` fail on `import { chromium } from 'playwright'`,
 *      which reads like three broken suites rather than one missing dependency.
 *      CI also needs `npx playwright install --with-deps chromium`.
 *
 *   2. `verify.mjs` needs a SERVED build, not a file:// URL. The sequence is
 *          python3 build.py
 *          python3 -m http.server 5173        (from the repo root)
 *          node tools/verify.mjs --url http://localhost:5173/AxieDiceTactics.html
 *      Run bare it dies with ERR_CONNECTION_REFUSED, which also reads like a code failure
 *      and is not. This script does the build and the serving for you.
 *
 * WHY THIS SCRIPT PARSES OUTPUT INSTEAD OF TRUSTING EXIT CODES:
 *   `t_aoe.mjs`, `t_fit.mjs`, `verify.mjs` and `sim.js` all exit 0 unconditionally today —
 *   they report to stdout and never signal failure. Trusting their exit status would give a
 *   permanently green build that tests nothing. Each step below therefore declares an
 *   `expect` predicate over captured stdout. Do not "simplify" this into bare spawns.
 *
 * KNOWN FAILURES: tools/known-failures.json. A declared failure is reported but does not break
 * the build; a declared failure that stops occurring breaks the build as STALE, so fixes force
 * the entry to be removed. Anything undeclared breaks the build.
 *
 * HISTORICAL NOTE: t_aoe.mjs and t_fit.mjs were dead until 2026-09-03 — they hardcoded
 * `/opt/pw-browsers/chromium` and `file:///home/claude/axie-dice/`, paths from a Linux sandbox
 * that no longer exists. They now resolve the browser from playwright and the page from
 * `process.cwd()`. Do not re-pin a machine-specific path.
 *
 *   t_vault.mjs was registered above the build until 2026-09-04. It needs a built
 *   AxieDiceTactics.html, so it failed on a clean checkout and — the real damage — passed
 *   against a stale build when one was present. Browser suites belong under the build.
 */
import { spawn, spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const ROOT = path.resolve(new URL('.', import.meta.url).pathname, '..');
const PORT = 5173;
const URL_ = `http://localhost:${PORT}/AxieDiceTactics.html`;
const KNOWN = path.join(ROOT, 'tools/known-failures.json');

const args = process.argv.slice(2);
if (args.includes('--help') || args.includes('-h')) {
  console.log(fs.readFileSync(new URL(import.meta.url), 'utf8').split('*/')[0].replace(/^\/\*\s?|^ \* ?/gm, ''));
  process.exit(0);
}
const FAST = args.includes('--fast');

const known = fs.existsSync(KNOWN) ? JSON.parse(fs.readFileSync(KNOWN, 'utf8')) : {};
const results = [];

function run(cmd, argv, opts = {}) {
  const r = spawnSync(cmd, argv, { cwd: ROOT, encoding: 'utf8', timeout: opts.timeout || 600000 });
  return { code: r.status, out: (r.stdout || '') + (r.stderr || '') };
}

function step(name, cmd, argv, expect, opts = {}) {
  process.stdout.write(`\n=== ${name} :: ${cmd} ${argv.join(' ')}\n`);
  const { code, out } = run(cmd, argv, opts);
  const verdict = expect({ code, out });
  const ok = verdict === true || (verdict && verdict.ok === true);
  const summary = (verdict && verdict.summary) || '';
  results.push({ name, ok, detail: ok ? summary : String(verdict), out });
  console.log(ok ? `    PASS  ${summary}` : `    FAIL  ${verdict}`);
  if (!ok) console.log(out.split('\n').slice(-25).map((l) => '      | ' + l).join('\n'));
  return ok;
}
const okWith = (summary) => ({ ok: true, summary: summary || '' });

/* ---------- preflight ---------- */
if (!fs.existsSync(path.join(ROOT, 'node_modules'))) {
  console.error('\nci: node_modules is missing. Run `npm install` first (and, for browser suites,');
  console.error('    `npx playwright install --with-deps chromium`). Without it t_aoe, t_fit and');
  console.error('    verify all fail on a missing `playwright` import and look like three broken suites.\n');
  process.exit(2);
}

/* ---------- logic suites (no browser, no server) ---------- */
step('generator snapshot, production', 'node', ['tools/gen_faces.mjs', '--check'],
  ({ code, out }) => code === 0 ? okWith((out.match(/gate: (\w+.*)/) || [, ''])[1]) : 'gen_faces --check exited ' + code);

step('generator snapshot, reference', 'node', ['tools/gen_faces.mjs', '--profile=reference', '--check'],
  ({ code }) => code === 0 ? okWith() : 'gen_faces --profile=reference --check exited ' + code);

step('part-skill face pins', 'node', ['tools/t_partskill.mjs'],
  ({ code, out }) => code === 0 ? okWith((out.match(/(\d+ passed, \d+ failed)/) || [, ''])[1])
    : (out.match(/(\d+ passed, \d+ failed)/) || [, 'failed'])[1]);

step('import mapping unit tests', 'node', ['tools/t_import.mjs'],
  ({ out }) => /(\d+) passed, 0 failed/.test(out) ? okWith((out.match(/(\d+ passed, \d+ failed)/) || [, ''])[1])
    : 'expected "N passed, 0 failed"');

step('relic invariant gate', 'node', ['tools/t_relic.mjs'],
  ({ code, out }) => code === 0 ? okWith((out.match(/(\d+ \/ \d+ satisfy INV-1)/) || [, 'gate: GREEN'])[1])
    : 't_relic exited ' + code + ' (gate RED)');

step('relic behaviour proofs', 'node', ['tools/t_relic_behaviour.mjs'],
  ({ code, out }) => code === 0 ? okWith((out.match(/(ALL \d+ PROOFS PASS)/) || [, ''])[1])
    : 'expected ALL N PROOFS PASS');

step('headless balance sim', 'node', ['tools/sim.js'],
  ({ out }) => {
    const m = out.match(/full-run winrate:\s*([\d.]+)%/);
    if (!m) return 'could not parse "full-run winrate: N%" from sim output';
    return okWith(`winrate ${m[1]}% (informational — sim is a balance probe, not a gate)`);
  });

/* ---------- browser suites ---------- */
let server = null;
if (!FAST) {
  const b = run('python3', ['build.py']);
  if (b.code !== 0) { console.error('ci: python3 build.py failed\n' + b.out); process.exit(2); }
  console.log('\n=== build :: python3 build.py -> AxieDiceTactics.html');

  step('AoE / summon regression', 'node', ['tools/t_aoe.mjs'],
    ({ out }) => /ALL REGRESSION CHECKS PASS/.test(out) ? okWith() : 'expected "ALL REGRESSION CHECKS PASS"');

  /* t_vault MUST stay BELOW the build. It is a playwright suite that loads
     AxieDiceTactics.html over file://, so while it sat up with the logic suites it failed
     with ERR_FILE_NOT_FOUND on a clean checkout — and, far worse, PASSED against whatever
     stale build happened to be lying around, verifying code that was no longer the code.
     Do not move it back up. Its own header says: python3 build.py && node tools/t_vault.mjs */
  step('vault migration', 'node', ['tools/t_vault.mjs'],
    ({ code, out }) => code === 0 ? okWith((out.match(/(\d+ passed, \d+ failed)/) || [, ''])[1])
      : 't_vault exited ' + code);

  /* Same file:// / build-freshness reasoning as t_vault above — must stay
     below the build step. design/gdd/onboarding-tutorial.md §8. */
  step('onboarding tutorial', 'node', ['tools/t_tutorial.mjs'],
    ({ code, out }) => code === 0 ? okWith((out.match(/(\d+ passed, \d+ failed)/) || [, ''])[1])
      : 't_tutorial exited ' + code);

  /* t_fit reads AxieDiceTactics.html over file://, so it needs no server. It exits 0 even when
     a viewport is broken, so count the "OFF SCREEN" markers and diff against the allowlist. */
  step('viewport fit', 'node', ['tools/t_fit.mjs'], ({ out }) => {
    const bad = out.split('\n').filter((l) => /OFF SCREEN/.test(l)).map((l) => l.trim().split(/\s+/)[0]);
    const allow = (known.t_fit || []).map((k) => k.viewport);
    const fresh = bad.filter((v) => !allow.includes(v));
    const stale = allow.filter((v) => !bad.includes(v));
    if (fresh.length) return `viewport(s) newly off-screen: ${fresh.join(', ')}`;
    if (stale.length) return `STALE allowlist: ${stale.join(', ')} now passes — remove it from tools/known-failures.json`;
    return okWith(bad.length ? `${bad.length} known failure(s): ${bad.join(', ')}` : 'all viewports fit');
  });

  server = spawn('python3', ['-m', 'http.server', String(PORT)], { cwd: ROOT, stdio: 'ignore', detached: true });
  await new Promise((r) => setTimeout(r, 2500));

  step('UI rules (served build)', 'node', ['tools/verify.mjs', '--url', URL_], ({ out }) => {
    if (/ERR_CONNECTION_REFUSED/.test(out)) return 'server not reachable on :' + PORT + ' — verify.mjs needs a SERVED build';
    const m = out.match(/KẾT QUẢ:\s*(\d+)\/(\d+)/);
    if (!m) return 'could not parse the "KẾT QUẢ: n/n" summary';
    return m[1] === m[2] ? okWith(`${m[1]}/${m[2]}`) : `${m[1]}/${m[2]} — a required check regressed`;
  });

  if (server && server.pid) { try { process.kill(-server.pid); } catch { try { server.kill(); } catch { /* */ } } }
}

/* ---------- summary ---------- */
const failed = results.filter((r) => !r.ok);
console.log('\n' + '='.repeat(72));
for (const r of results) console.log(`  ${r.ok ? 'PASS' : 'FAIL'}  ${r.name}${r.detail && r.ok ? ' — ' + r.detail : ''}`);
console.log('='.repeat(72));
console.log(failed.length ? `\n${failed.length} step(s) FAILED\n` : `\nall ${results.length} step(s) passed${FAST ? ' (--fast: browser suites skipped)' : ''}\n`);
process.exit(failed.length ? 1 : 0);
