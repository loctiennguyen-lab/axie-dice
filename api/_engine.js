/**
 * Shared helper: load src/data.js + src/engine.js into a fresh Node vm
 * context, exactly the way tools/sim.js already proves works headless.
 * Used by submit-run.js to replay a submitted action log server-side.
 * Not a route itself (no filename match for Vercel's /api convention).
 */
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const NAMES = [
  'newGame', 'chooseNode', 'playerUseDie', 'playerUseRelic', 'doReroll',
  'endTurn', 'undo', 'takeReward', 'eventChoose', 'eventDone', 'shopBuy', 'shopDone',
  'runXp', 'ENGINE_VERSION', 'RUN_LEN',
  // Read-only display helpers (docs/architecture/telemetry-dashboard-design.md's
  // sibling feature: leaderboard team/relic display) — pure functions, no DOM,
  // used by submit-run.js to turn its own trusted replay state into the same
  // {n,cls,tier,artIdx,die}/{n,rar,d} shape src/ui.js's saveRunHistory() already
  // produces client-side, so the Leaderboard can show it via the same renderer.
  'buildUnit', 'faceText', 'RELIC_BY_ID',
];

function loadEngine() {
  const ctx = { console, Math, JSON };
  vm.createContext(ctx);
  const src = ['src/data.js', 'src/engine.js']
    .map((f) => fs.readFileSync(path.join(process.cwd(), f), 'utf8'))
    .join('\n') + '\n;globalThis.__X={' + NAMES.map((n) => n + ':' + n).join(',') + '};';
  vm.runInContext(src, ctx);
  return ctx.__X;
}

module.exports = { loadEngine };
