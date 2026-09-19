#!/usr/bin/env node
// Builds production/leaderboard/LEADERBOARD.md from the verdicts the referee produced.
//
// It reads ONLY verdict files — never a submitted record — so a board row can never carry a
// number the client supplied. That is the same boundary api/submit-run.js draws for the live
// JS build: the score on the board is the score the replay computed, or it is not on the board.

import { readdirSync, readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const VERDICT_DIR = join(ROOT, 'production/leaderboard/verdicts');
const OUT = join(ROOT, 'production/leaderboard/LEADERBOARD.md');

function verdicts() {
  if (!existsSync(VERDICT_DIR)) return [];
  return readdirSync(VERDICT_DIR)
    .filter((f) => f.endsWith('.verdict.json'))
    .map((f) => {
      try {
        return { name: f.replace('.verdict.json', ''), ...JSON.parse(readFileSync(join(VERDICT_DIR, f), 'utf-8')) };
      } catch {
        return { name: f, ok: false, error: 'unreadable_verdict', message: 'not valid JSON' };
      }
    });
}

const all = verdicts();
// Golden records are the determinism check, not entries: they are a bot's run, kept so CI can
// prove the referee scores the same on every machine. Ranking them would put the test fixture
// on the board next to the players.
const players = all.filter((v) => !v.name.startsWith('golden__'));
const goldenOk = all.length - players.length;
const accepted = players.filter((v) => v.ok).sort((a, b) => b.score - a.score);
const refused = players.filter((v) => !v.ok);

const lines = [];
lines.push('# Leaderboard');
lines.push('');
lines.push('Every score here was computed by replaying the run, never submitted by a client.');
lines.push('Rebuilt by `.github/workflows/verify-runs.yml`; edit the records, not this file.');
lines.push('');
// UTC, and labelled as such: this is generated on a runner in one timezone and read by people
// in another, and an unlabelled date that disagrees with the reader's calendar reads as stale.
lines.push(`_${accepted.length} verified · ${refused.length} refused · ${goldenOk} golden determinism check${goldenOk === 1 ? '' : 's'} · generated ${new Date().toISOString().slice(0, 10)} UTC_`);
lines.push('');

if (accepted.length === 0) {
  lines.push('No verified runs yet.');
} else {
  lines.push('| # | Run | Score | Won | Rules |');
  lines.push('|---|-----|-------|-----|-------|');
  accepted.forEach((v, i) => {
    lines.push(`| ${i + 1} | ${v.name} | ${v.score} | ${v.won ? 'yes' : 'no'} | ${v.rules_version ?? '?'} |`);
  });
}

if (refused.length > 0) {
  lines.push('');
  lines.push('## Refused');
  lines.push('');
  // Refusals are listed WITH their reason on purpose. A board that silently drops a record
  // teaches an honest player whose run hit a version mismatch that submitting does nothing.
  lines.push('| Run | Reason | Detail |');
  lines.push('|-----|--------|--------|');
  for (const v of refused) {
    lines.push(`| ${v.name} | \`${v.error}\` | ${String(v.message ?? '').replace(/\|/g, '\\|')} |`);
  }
}

mkdirSync(dirname(OUT), { recursive: true });
writeFileSync(OUT, lines.join('\n') + '\n');
console.log(`build_leaderboard: ${accepted.length} verified, ${refused.length} refused -> ${OUT}`);
