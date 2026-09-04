/* t_relic.mjs — RELIC SYSTEM invariant gate
 *
 * Machine-verifies the two relic design documents against each other and against
 * the live engine:
 *   design/gdd/relic-system.md          — framework (§3.x rules, §4.x RP model, §6 retune, §12 AC)
 *   design/gdd/relic-roster-expansion.md — the 48 new relics (as authored)
 *   src/data.js + src/engine.js          — what the engine actually reads
 *
 * The headline invariant is INV-1 (§3.12): rarity bands are disjoint by construction and
 * every relic's RP sits inside its own band. That is the product owner's complaint
 * ("lower-rarity relics are stronger than higher-rarity ones") turned into arithmetic.
 *
 * Design rules, copied from tools/gen_faces.mjs because they are why that tool works:
 *   - parsing is STRICT. A table row that does not fit the documented shape is a hard
 *     failure with the row text, never a silently skipped row. A doc restructure must
 *     break this tool loudly rather than let it report GREEN on data it never read.
 *   - every invariant is a hard failure carrying { id, row, expected, actual }.
 *   - tools/known-failures.json is TWO-SIDED: a declared id that fires is KNOWN and does
 *     not break the build; a declared id that stops firing is STALE and DOES break it, so
 *     fixing a defect forces the allowlist entry to be deleted. --strict ignores the file.
 *
 * Run:  node tools/t_relic.mjs
 *       node tools/t_relic.mjs --strict      ignore known-failures.json
 *       node tools/t_relic.mjs --verbose     print every parsed relic and its RP
 *       node tools/t_relic.mjs --json        emit the report as JSON
 */
import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import vm from 'node:vm';

const ROOT = path.resolve(new URL('.', import.meta.url).pathname, '..');
const P = (...a) => path.join(ROOT, ...a);

const IN_FRAMEWORK = P('design/gdd/relic-system.md');
const IN_ROSTER = P('design/gdd/relic-roster-expansion.md');
const IN_DATA = P('src/data.js');
const IN_ENGINE = P('src/engine.js');
const KNOWN_FAILURES = P('tools/known-failures.json');

const RAR_NAME = ['COMMON', 'RARE', 'EPIC', 'LEGENDARY'];
const RAR_LETTER = { C: 0, R: 1, E: 2, L: 3 };
const EXPECT_TOTAL = 94;          /* §6.7.7: 44 + 48 + 2 */
const EXPECT_ORIGINALS = 44;
const EXPECT_EXPANSION = 48;
const EXPECT_NEW = 2;

/* ------------------------------------------------------------------ *
 * 0. Failure accumulator — every invariant is a HARD FAIL (exit != 0) *
 * ------------------------------------------------------------------ */
const failures = [];
const findings = [];
function hardFail(id, row, expected, actual, extra) {
  failures.push({ id, row, expected, actual: actual === undefined ? '(none)' : actual, extra });
}
function finding(kind, msg, data) { findings.push({ kind, msg, data }); }

/* A parse error is fatal, not a failure: a tool that half-read its input cannot
   report a trustworthy count. Everything below loadInputs() throws ParseError. */
class ParseError extends Error {}
function parseDie(where, msg) { throw new ParseError(`${where}: ${msg}`); }

/* ------------------------------- *
 * 1. CLI                          *
 * ------------------------------- */
function parseArgs(argv) {
  const o = { strict: false, verbose: false, json: false, help: false };
  for (const a of argv) {
    if (a === '--strict') o.strict = true;
    else if (a === '--verbose') o.verbose = true;
    else if (a === '--json') o.json = true;
    else if (a === '--help' || a === '-h') o.help = true;
    else { console.error(`t_relic: unknown flag ${a}`); process.exit(2); }
  }
  return o;
}
const HELP = `t_relic.mjs — relic system invariant gate (INV-1 / §3.12, §4.4, §12.1 AC-15..AC-21)

  --strict    ignore tools/known-failures.json; show the true invariant state
  --verbose   print every parsed relic with its rarity, RP and band verdict
  --json      emit the machine report instead of the human one
`;

/* ------------------------------- *
 * 2. Markdown helpers (strict)    *
 * ------------------------------- */
function sliceSection(md, startRe, endRe, label) {
  const lines = md.split('\n');
  let s = -1, e = lines.length;
  for (let i = 0; i < lines.length; i++) if (startRe.test(lines[i])) { s = i; break; }
  if (s < 0) {
    parseDie('t_relic', `cannot locate section ${label} (${startRe}). The design doc was `
      + 'restructured; update the corresponding parser in t_relic.mjs rather than relaxing it.');
  }
  for (let i = s + 1; i < lines.length; i++) if (endRe.test(lines[i])) { e = i; break; }
  return { lines: lines.slice(s, e), offset: s, label };
}
const isSep = (l) => /^\s*\|[\s:|-]+\|\s*$/.test(l);
const isTableRow = (l) => /^\s*\|/.test(l) && !isSep(l);
const cells = (line) => line.trim().replace(/^\|/, '').replace(/\|$/, '').split('|').map((c) => c.trim());
const stripFmt = (s) => String(s).replace(/`/g, '').replace(/\*\*/g, '').replace(/\*/g, '')
  .replace(/[✓✗⚠️⚠]/g, '').trim();

/* Pull the first backtick-quoted token out of a cell: `r_claw` -> r_claw */
function tick(cell, where) {
  const m = /`([^`]+)`/.exec(String(cell));
  if (!m) parseDie(where, `expected a \`backticked\` token, cell reads "${String(cell).trim()}"`);
  return m[1].trim();
}
/* Strict number: accepts 13.20, **13.20**, ≈70, −0.5. Refuses to guess. */
function num(cell, where) {
  const s = stripFmt(cell).replace(/≈/g, '').replace(/−/g, '-').replace(/,/g, '');
  const m = /^-?\d+(?:\.\d+)?/.exec(s);
  if (!m) parseDie(where, `expected a number, cell reads "${String(cell).trim()}"`);
  return Number(m[0]);
}
/* Rarity from "0 C" / "**2 E**" / "COMMON" / "**1 R**" / "2 E" */
function rarity(cell, where) {
  const s = stripFmt(cell).toUpperCase();
  const byName = RAR_NAME.indexOf(s.replace(/[^A-Z]/g, ''));
  if (byName >= 0) return byName;
  const m = /^(\d)\s*([CREL])$/.exec(s.replace(/\s+/g, ' ').trim());
  if (m) {
    const n = Number(m[1]);
    if (RAR_LETTER[m[2]] !== n) {
      parseDie(where, `rarity cell "${String(cell).trim()}" is self-inconsistent: `
        + `digit ${n} is ${RAR_NAME[n]} but letter ${m[2]} is ${RAR_NAME[RAR_LETTER[m[2]]]}`);
    }
    return n;
  }
  const d = /^(\d)$/.exec(s.trim());
  if (d && Number(d[1]) <= 3) return Number(d[1]);
  parseDie(where, `expected a rarity (0..3, "1 R", or COMMON..LEGENDARY), cell reads "${String(cell).trim()}"`);
  return -1;
}
/* Every table in a section slice, as arrays of cell-arrays, with 1-based doc line numbers. */
function tablesIn(sec) {
  const out = [];
  let cur = null;
  for (let i = 0; i < sec.lines.length; i++) {
    const l = sec.lines[i];
    if (isTableRow(l)) {
      if (!cur) cur = { header: cells(l), rows: [], line: sec.offset + i + 1 };
      else if (!cur.sepSeen) { /* second line before separator: malformed, keep as row */ cur.rows.push({ c: cells(l), line: sec.offset + i + 1 }); }
      else cur.rows.push({ c: cells(l), line: sec.offset + i + 1 });
    } else if (isSep(l)) {
      if (cur) cur.sepSeen = true;
    } else if (cur) { out.push(cur); cur = null; }
  }
  if (cur) out.push(cur);
  return out;
}
/* The one table in a section whose header contains all of `must`. Fails loudly on 0 or >1. */
function theTable(sec, must) {
  const all = tablesIn(sec);
  const hit = all.filter((t) => must.every((m) => t.header.some((h) => stripFmt(h).toLowerCase().includes(m.toLowerCase()))));
  if (hit.length !== 1) {
    parseDie(sec.label, `expected exactly 1 table whose header contains [${must.join(', ')}], found ${hit.length} `
      + `(section has ${all.length} table(s): ${all.map((t) => '[' + t.header.map(stripFmt).join(' | ') + ']').join(' ; ')})`);
  }
  return hit[0];
}
const round2 = (x) => Math.round(x * 100) / 100;
const round4 = (x) => Math.round(x * 10000) / 10000;

/* ================================================================= *
 * STAGE A — the band model (§3.12 INV-2 + §4.6.1)                    *
 *                                                                    *
 * Nothing here is hardcoded from the brief. ANCHOR, SIG and τ are    *
 * READ FROM THE DOC and the bands are DERIVED, so that a future tune *
 * of τ or SIG cannot silently reintroduce cross-tier overlap: the    *
 * sufficient condition (1+τ)/(1−τ) < min(C_{r+1}/C_r) is asserted    *
 * in code, and the doc's own printed band tables are then checked    *
 * against the derivation.                                            *
 * ================================================================= */
function parseBandModel(md) {
  const inv2 = sliceSection(md, /^#### INV-2/, /^#### INV-3/, '§3.12 INV-2');
  const s461 = sliceSection(md, /^#### 4\.6\.1/, /^#### 4\.6\.2/, '§4.6.1');
  const grab = (sec, re, what) => {
    const m = re.exec(sec.lines.join('\n'));
    if (!m) parseDie(sec.label, `cannot find ${what} (${re})`);
    return m;
  };
  const readConsts = (sec) => {
    const anchor = Number(grab(sec, /ANCHOR\s*=\s*([0-9.]+)/, 'ANCHOR')[1]);
    const sig = grab(sec, /SIG\s*=\s*\[([^\]]*)\]/, 'SIG')[1]
      .split(',').map((x) => Number(x.trim()));
    const tau = Number(grab(sec, /τ\s*=\s*([0-9.]+)/, 'τ')[1]);
    if (sig.length !== 4 || sig.some((x) => !Number.isFinite(x))) {
      parseDie(sec.label, `SIG must be 4 finite numbers, got [${sig.join(', ')}]`);
    }
    if (!Number.isFinite(anchor) || !Number.isFinite(tau)) parseDie(sec.label, 'ANCHOR/τ not finite');
    return { anchor, sig, tau };
  };
  const a = readConsts(inv2), b = readConsts(s461);
  /* the two sections must state the same constants — a doc that disagrees with itself
     is the exact failure mode that produced the ±20% band bug */
  if (a.anchor !== b.anchor || a.tau !== b.tau || a.sig.join(',') !== b.sig.join(',')) {
    hardFail('DOC-CONST', '§3.12 INV-2 vs §4.6.1', JSON.stringify(a), JSON.stringify(b),
      'the two sections state different band constants; the band model is ambiguous');
  }
  /* the doc also states the derived bound and the ratio — recompute both */
  const boundM = /min_r\s*\(\s*C_\{r\+1\}\s*\/\s*C_r\s*\)\s*=\s*([0-9.]+)/.exec(inv2.lines.join('\n'));
  const tauMaxM = /⇔\s*τ\s*<[^=\n]*=\s*([0-9.]+)/.exec(inv2.lines.join('\n'));
  const statedRatio = boundM ? Number(boundM[1]) : null;
  const statedTauMax = tauMaxM ? Number(tauMaxM[1]) : null;

  /* printed band tables, from BOTH sections */
  const printed = {};
  for (const sec of [inv2, s461]) {
    printed[sec.label] = {};
    let seen = 0;
    for (const l of sec.lines) {
      if (!isTableRow(l)) continue;
      const c = cells(l);
      const m = /^(\d)\s+(COMMON|RARE|EPIC|LEGENDARY)$/.exec(stripFmt(c[0]));
      if (!m) continue;
      const r = Number(m[1]);
      if (RAR_NAME[r] !== m[2]) parseDie(sec.label, `band row "${l.trim()}" mismatches index and name`);
      const bandCell = c.find((x) => /\[\s*[0-9.]+\s*,\s*[0-9.]+\s*\]/.test(x));
      if (!bandCell) parseDie(sec.label, `band row for ${m[2]} has no [L, U] cell: "${l.trim()}"`);
      const bm = /\[\s*([0-9.]+)\s*,\s*([0-9.]+)\s*\]/.exec(bandCell);
      printed[sec.label][r] = { C: num(c[1], sec.label), L: Number(bm[1]), U: Number(bm[2]) };
      seen++;
    }
    if (seen !== 4) parseDie(sec.label, `expected 4 band rows (COMMON..LEGENDARY), parsed ${seen}`);
  }
  return { anchor: b.anchor, sig: b.sig, tau: b.tau, statedRatio, statedTauMax, printed };
}

/* INV-2b (§3.12) — the raw edges C_r(1∓τ) are not 2dp numbers, so the doc rounds them
   INWARD and declares the rounded values NORMATIVE:

       L_r = ceil( C_r × 0.85 × 100 ) / 100        U_r = floor( C_r × 1.15 × 100 ) / 100

   Rounding inward can only NARROW a band and WIDEN a forbidden zone, so INV-1 holds a
   fortiori; rounding to nearest would admit relics the model rejects (15.88 < 15.880788)
   and is exactly the spec-vs-machine disagreement INV-2b was written to close. Everything
   downstream — INV-1, the forbidden zones, the §6 headings, AC-15 — reads `band`, so the
   gate and the prose quote one set of numbers. `raw` is kept only to PROVE the direction
   of the rounding (checkBandDerivation step 4).

   The ±1e-9 is load-bearing, not defensive noise: 13.2 × 1.15 is 15.179999999999998 in
   IEEE-754, so a bare Math.floor gives 15.17 and a bare Math.ceil on 26.4 × 1.15 gives
   30.35 — both OUTSIDE the doc's table and both wrong by one ulp in the unsafe direction. */
const inwardLo = (x) => Math.ceil(x * 100 - 1e-9) / 100;
const inwardHi = (x) => Math.floor(x * 100 + 1e-9) / 100;
function deriveBands(model) {
  const C = model.sig.map((s) => model.anchor * s);
  const raw = C.map((c) => [c * (1 - model.tau), c * (1 + model.tau)]);
  const band = raw.map(([lo, hi]) => [inwardLo(lo), inwardHi(hi)]);
  return { C, raw, band };
}

/* INV-2: prove the derivation, do not trust the printed table. */
function checkBandDerivation(model, derived) {
  const { C, band } = derived;
  const ratios = [];
  for (let r = 0; r < 3; r++) ratios.push(C[r + 1] / C[r]);
  const minRatio = Math.min(...ratios);
  const spread = (1 + model.tau) / (1 - model.tau);

  /* (1) the sufficient condition itself */
  if (!(spread < minRatio)) {
    hardFail('INV-2', `τ = ${model.tau}, SIG = [${model.sig.join(', ')}]`,
      `(1+τ)/(1−τ) < min(C_{r+1}/C_r) = ${round4(minRatio)}`,
      `(1+τ)/(1−τ) = ${round4(spread)}`,
      'bands overlap BY CONSTRUCTION — a top-of-band relic outranks a bottom-of-band relic '
      + 'one tier up. This is the original defect; τ = 0.20 gives 1.5000 and reproduces it.');
  }
  /* (2) the doc's stated ratio and τ ceiling must be the real ones */
  if (model.statedRatio != null && Math.abs(model.statedRatio - minRatio) > 5e-4) {
    hardFail('INV-2', '§3.12 stated min(C_{r+1}/C_r)', String(model.statedRatio), String(round4(minRatio)));
  }
  const tauMax = (minRatio - 1) / (minRatio + 1);
  if (model.statedTauMax != null && Math.abs(model.statedTauMax - tauMax) > 5e-4) {
    hardFail('INV-2', '§3.12 stated τ ceiling', String(model.statedTauMax), String(round4(tauMax)));
  }
  if (!(model.tau < tauMax)) {
    hardFail('INV-2', 'τ', `< ${round4(tauMax)}`, String(model.tau), 'τ is at or above its own ceiling');
  }
  /* (3) bands really are disjoint, checked numerically and not by argument */
  for (let r = 0; r < 3; r++) {
    if (!(band[r][1] < band[r + 1][0])) {
      hardFail('INV-2', `Band[${RAR_NAME[r]}] vs Band[${RAR_NAME[r + 1]}]`,
        `U_${r} < L_${r + 1}`, `${round2(band[r][1])} >= ${round2(band[r + 1][0])}`);
    }
  }
  /* (4) INV-2b — prove the rounding is really INWARD. This is the property that lets
         INV-1 stay true without re-checking it: a subset band cannot admit anything the
         raw band rejected, and the forbidden zones (U_r, L_{r+1}) can only grow. An edge
         rounded OUTWARD would break that silently, so it is a hard failure. */
  const ULP = 0.01;
  for (let r = 0; r < 4; r++) {
    const [rl, ru] = derived.raw[r], nl = band[r][0], nu = band[r][1];
    if (nl < rl - 1e-9 || nu > ru + 1e-9) {
      hardFail('INV-2b', `Band[${RAR_NAME[r]}]`,
        `normative ⊆ raw — [${nl}, ${nu}] inside [${round4(rl)}, ${round4(ru)}]`,
        `normative [${nl}, ${nu}] escapes the raw ±τ band`,
        'the edge was rounded OUTWARD, which WIDENS the band and NARROWS the forbidden zone — '
        + 'INV-1 stops holding a fortiori and this gate would accept a relic the model rejects');
    }
    if (nl - rl >= ULP - 1e-9 || ru - nu >= ULP - 1e-9) {
      hardFail('INV-2b', `Band[${RAR_NAME[r]}]`,
        `every normative edge within one printed ulp (${ULP}) of its raw edge`,
        `L moved +${round4(nl - rl)}, U moved −${round4(ru - nu)}`,
        'INV-2b is a 2dp rounding rule, not a licence to hand-narrow a band');
    }
  }
  /* (4b) the printed tables ARE the normative bands, so they must equal the inward-rounded
          derivation EXACTLY. No tolerance: §6 and §12.1 AC-15 quote these edges verbatim as
          acceptance numbers, so a 0.01 typo in a table is a real defect — it would accept a
          relic the model rejects, which is the whole failure mode INV-2b closes. */
  for (const [label, rows] of Object.entries(model.printed)) {
    for (let r = 0; r < 4; r++) {
      const p = rows[r];
      const gaps = [['C', p.C, C[r]], ['L', p.L, band[r][0]], ['U', p.U, band[r][1]]];
      const bad = gaps.filter((g) => Math.abs(g[1] - g[2]) > 1e-9);
      if (bad.length) {
        hardFail('INV-2-TABLE', `${label} ${RAR_NAME[r]}`,
          `C ${C[r]}, band [${band[r][0]}, ${band[r][1]}] (ANCHOR/SIG/τ, edges rounded inward per INV-2b)`,
          `C ${p.C}, band [${p.L}, ${p.U}] (printed) — ${bad.map((g) => `${g[0]} is ${g[1]}, should be ${g[2]}`).join('; ')}`,
          'the doc prints a band it did not derive — §3.12 INV-2 says bands are never set by hand, '
          + 'and INV-2b fixes the rounding rule exactly so this comparison can be exact');
      }
    }
  }
  /* (5) REGRESSION GUARD: the old ±20% tolerance must still be provably broken, so that
         nobody can "fix" this tool by widening τ and having it stay green. */
  const oldSpread = 1.20 / 0.80;
  if (oldSpread < minRatio) {
    hardFail('INV-2-GUARD', 'τ = 0.20 (the superseded tolerance)',
      `(1.20/0.80) = 1.5000 >= ${round4(minRatio)} — overlap must remain arithmetically certain`,
      `1.5000 < ${round4(minRatio)}`,
      'SIG has been widened enough that ±20% no longer overlaps; §3.12\'s justification is stale');
  }
  return { minRatio, spread, tauMax };
}

/* ================================================================= *
 * STAGE B — the 44 retuned originals (§6.1 COMMON .. §6.5 ACTIVE)    *
 * ================================================================= */
/* "0 / `pierceInject` / `kw`" -> {mload:0, ex:['pierceInject'], mfPhase:'kw'}
   "**1+1=2** / `critChance`,`critMult`" -> {mload:2, ex:[...]}  (the doc writes the sum) */
function parseMloadCell(cell, where) {
  const raw = String(cell);
  const parts = raw.split('/').map((x) => x.trim());
  if (!parts.length) parseDie(where, `empty mload/ex/mfPhase cell`);
  const mtxt = stripFmt(parts[0]);
  let mload;
  const sum = /=\s*(\d)\s*$/.exec(mtxt);            /* "1+1=2" -> 2 */
  if (sum) mload = Number(sum[1]);
  else {
    const m = /^(\d)/.exec(mtxt);
    if (!m) parseDie(where, `mload is not an integer, cell reads "${raw.trim()}"`);
    mload = Number(m[1]);
  }
  const exTxt = parts[1] === undefined ? '' : parts[1];
  const ex = /^[\s—–-]*$/.test(stripFmt(exTxt)) ? []
    : (exTxt.match(/`([^`]+)`/g) || []).map((x) => x.replace(/`/g, '').trim()).filter(Boolean);
  if (exTxt.trim() && !/^[\s—–-]*$/.test(stripFmt(exTxt)) && !ex.length) {
    parseDie(where, `ex token list is neither "—" nor a list of \`tokens\`: "${exTxt.trim()}"`);
  }
  const mfTxt = parts[2] === undefined ? '' : stripFmt(parts[2]);
  const mfPhase = /^[\s—–-]*$/.test(mfTxt) ? null : mfTxt.replace(/[^a-z+]/g, '') || null;
  return { mload, ex, mfPhase };
}

const PASSIVE_SECTIONS = [
  { re: /^### 6\.1 COMMON/, end: /^### 6\.2 /, rar: 0, label: '§6.1' },
  { re: /^### 6\.2 RARE/, end: /^### 6\.3 /, rar: 1, label: '§6.2' },
  { re: /^### 6\.3 EPIC/, end: /^### 6\.4 /, rar: 2, label: '§6.3' },
  { re: /^### 6\.4 LEGENDARY/, end: /^### 6\.5 /, rar: 3, label: '§6.4' },
];

function parseOriginals(md, derived) {
  const out = [];
  for (const spec of PASSIVE_SECTIONS) {
    const sec = sliceSection(md, spec.re, spec.end, spec.label);
    /* the section header states its own band — check it against the derivation */
    const hm = /\[\s*([0-9.]+)\s*,\s*([0-9.]+)\s*\]/.exec(sec.lines[0]);
    if (!hm) parseDie(spec.label, `header "${sec.lines[0].trim()}" does not state its band`);
    const [L, U] = [Number(hm[1]), Number(hm[2])];
    /* the heading must quote the NORMATIVE band exactly (INV-2b). No tolerance: this is the
       number a designer reads while retuning a relic, so an 0.01 drift here silently retunes
       relics to a band the gate does not enforce. */
    const dL = derived.band[spec.rar][0], dU = derived.band[spec.rar][1];
    if (Math.abs(L - dL) > 1e-9 || Math.abs(U - dU) > 1e-9) {
      hardFail('INV-2-TABLE', `${spec.label} section header`,
        `[${dL}, ${dU}] (ANCHOR/SIG/τ, edges rounded inward per INV-2b)`,
        `[${L}, ${U}] (written in the heading)`,
        'a §6 heading quotes a band the model does not produce — the retune targets are off-model');
    }
    const t = theTable(sec, ['id', 'RP', 'mload']);
    const N = t.header.length;
    if (N !== 10) parseDie(spec.label, `expected a 10-column retune table, header has ${N}: [${t.header.join(' | ')}]`);
    const ix = {
      id: 0, name: 1, arch: 2, cat: 3, eff: 4, field: 5,
      rp: t.header.findIndex((h) => stripFmt(h) === 'RP'),
      aim: t.header.findIndex((h) => stripFmt(h).startsWith('Δaim')),
      ml: t.header.findIndex((h) => stripFmt(h).includes('mload')),
    };
    for (const k of ['rp', 'aim', 'ml']) {
      if (ix[k] < 0) parseDie(spec.label, `no "${k}" column in header [${t.header.join(' | ')}]`);
    }
    for (const row of t.rows) {
      const where = `${spec.label} line ${row.line}`;
      if (row.c.length !== N) {
        parseDie(where, `row has ${row.c.length} cells, header has ${N}. Row: ${row.c.join(' | ')}`);
      }
      const id = tick(row.c[ix.id], where);
      const ml = parseMloadCell(row.c[ix.ml], where);
      out.push({
        id, name: stripFmt(row.c[ix.name]), a: stripFmt(row.c[ix.arch]), cat: stripFmt(row.c[ix.cat]),
        rar: spec.rar, rp: num(row.c[ix.rp], where), aim: num(row.c[ix.aim], where),
        effect: stripFmt(row.c[ix.eff]), field: stripFmt(row.c[ix.field]),
        fieldRaw: row.c[ix.field], mload: ml.mload, ex: ml.ex, mfPhase: ml.mfPhase,
        kind: null, act: false, src: spec.label, line: row.line, origin: 'original',
      });
    }
  }
  /* §6.5 ACTIVE — a different shape: rar lives in a cell, RP is RP_act, and V_out/N* are given */
  const sec = sliceSection(md, /^### 6\.5 ACTIVE/, /^### 6\.6 /, '§6.5');
  const t = theTable(sec, ['id', 'kind', 'RP_act']);
  const N = t.header.length;
  if (N !== 11) parseDie('§6.5', `expected an 11-column active table, header has ${N}: [${t.header.join(' | ')}]`);
  const ix = {
    id: 0, name: 1, arch: 2, rar: 3, eff: 4, kind: 5,
    vout: t.header.findIndex((h) => stripFmt(h).startsWith('V_out')),
    nstar: t.header.findIndex((h) => stripFmt(h).startsWith('N')),
    rp: t.header.findIndex((h) => stripFmt(h) === 'RP_act'),
    aim: t.header.findIndex((h) => stripFmt(h).startsWith('Δaim')),
  };
  for (const k of ['vout', 'nstar', 'rp', 'aim']) {
    if (ix[k] < 0) parseDie('§6.5', `no "${k}" column in header [${t.header.join(' | ')}]`);
  }
  for (const row of t.rows) {
    const where = `§6.5 line ${row.line}`;
    if (row.c.length !== N) parseDie(where, `row has ${row.c.length} cells, header has ${N}. Row: ${row.c.join(' | ')}`);
    const eff = row.c[ix.eff];
    const mp = /\[\s*MP\s*(\d+)\s*\]/.exec(stripFmt(eff));
    if (!mp) parseDie(where, `active effect cell has no "[MP n]" cost: "${stripFmt(eff)}"`);
    out.push({
      id: tick(row.c[ix.id], where), name: stripFmt(row.c[ix.name]), a: stripFmt(row.c[ix.arch]),
      cat: 'active', rar: rarity(row.c[ix.rar], where), rp: num(row.c[ix.rp], where),
      aim: num(row.c[ix.aim], where), effect: stripFmt(eff), field: 'act',
      kind: stripFmt(row.c[ix.kind]), cost: Number(mp[1]),
      voutRaw: row.c[ix.vout], nstar: num(row.c[ix.nstar], where),
      mload: 0, ex: [], mfPhase: null, act: true, src: '§6.5', line: row.line, origin: 'original',
    });
  }
  return out;
}

/* ================================================================= *
 * STAGE C — the 48 audited expansion relics (§6.7.1..§6.7.6)         *
 *           + the 2 mandated new PLAGUE entries (§6.7.7)             *
 * ================================================================= */
const AUDIT_SECTIONS = [
  { re: /^#### 6\.7\.1 /, end: /^#### 6\.7\.2 /, label: '§6.7.1', arch: 'pierce' },
  { re: /^#### 6\.7\.2 /, end: /^#### 6\.7\.3 /, label: '§6.7.2', arch: 'growth' },
  { re: /^#### 6\.7\.3 /, end: /^#### 6\.7\.4 /, label: '§6.7.3', arch: 'summon' },
  { re: /^#### 6\.7\.4 /, end: /^#### 6\.7\.5 /, label: '§6.7.4', arch: 'thorns' },
  { re: /^#### 6\.7\.5 /, end: /^#### 6\.7\.6 /, label: '§6.7.5', arch: 'exec' },
  { re: /^#### 6\.7\.6 /, end: /^#### 6\.7\.7 /, label: '§6.7.6', arch: null },
];

function parseAudit(md) {
  const out = [];
  for (const spec of AUDIT_SECTIONS) {
    const sec = sliceSection(md, spec.re, spec.end, spec.label);
    const t = theTable(sec, ['id', 'rar sau', 'RP sau']);
    const H = t.header.map(stripFmt);
    const ix = {
      id: 0,
      arch: H.findIndex((h) => h === 'arch'),
      rarBefore: H.findIndex((h) => h.startsWith('rar trước')),
      rpBefore: H.findIndex((h) => h.startsWith('RP trước')),
      diag: H.findIndex((h) => h.startsWith('Chẩn đoán')),
      change: H.findIndex((h) => h.includes('THAY ĐỔI')),
      rarAfter: H.findIndex((h) => h.startsWith('rar sau')),
      rpAfter: H.findIndex((h) => h.startsWith('RP sau')),
      aim: H.findIndex((h) => h.startsWith('Δaim')),
    };
    for (const k of ['rarBefore', 'rpBefore', 'change', 'rarAfter', 'rpAfter', 'aim']) {
      if (ix[k] < 0) parseDie(spec.label, `no "${k}" column in header [${H.join(' | ')}]`);
    }
    if (spec.arch === null && ix.arch < 0) parseDie(spec.label, 'mixed-archetype table must carry an "arch" column');
    for (const row of t.rows) {
      const where = `${spec.label} line ${row.line}`;
      if (row.c.length !== t.header.length) {
        parseDie(where, `row has ${row.c.length} cells, header has ${t.header.length}. Row: ${row.c.join(' | ')}`);
      }
      const id = tick(row.c[ix.id], where);
      const change = row.c[ix.change];
      const nm = /N\*\s*=\s*(\d)/.exec(stripFmt(change));
      const mp = /\[\s*MP\s*(\d+)\s*\]/.exec(stripFmt(change));
      out.push({
        id, name: id, a: spec.arch || stripFmt(row.c[ix.arch]),
        cat: id.startsWith('a_') ? 'active' : 'audited',
        rar: rarity(row.c[ix.rarAfter], where), rp: num(row.c[ix.rpAfter], where),
        aim: num(row.c[ix.aim], where),
        rarBefore: rarity(row.c[ix.rarBefore], where), rpBefore: num(row.c[ix.rpBefore], where),
        rpBeforeRaw: stripFmt(row.c[ix.rpBefore]),
        diagnosis: ix.diag >= 0 ? stripFmt(row.c[ix.diag]) : '',
        change: stripFmt(change), effect: stripFmt(change), field: null,
        cost: mp ? Number(mp[1]) : null, nstar: nm ? Number(nm[1]) : null,
        mload: null, ex: null, mfPhase: null,
        act: id.startsWith('a_'), src: spec.label, line: row.line, origin: 'expansion',
      });
    }
  }
  /* §6.7.7 — two brand-new PLAGUE entries, in the §6-style shape */
  const sec = sliceSection(md, /^#### 6\.7\.7 /, /^#### 6\.7\.8 /, '§6.7.7');
  const t = theTable(sec, ['id mới', 'RP']);
  const H = t.header.map(stripFmt);
  const ix = {
    id: 0, name: 1, arch: H.indexOf('arch'), rar: H.indexOf('rar'),
    eff: H.findIndex((h) => h.startsWith('Hiệu ứng')), field: H.indexOf('Field'),
    rp: H.indexOf('RP'), aim: H.findIndex((h) => h.startsWith('Δaim')),
    ml: H.findIndex((h) => h.includes('mload')),
  };
  for (const k of ['arch', 'rar', 'rp', 'aim', 'ml']) {
    if (ix[k] < 0) parseDie('§6.7.7', `no "${k}" column in header [${H.join(' | ')}]`);
  }
  for (const row of t.rows) {
    const where = `§6.7.7 line ${row.line}`;
    if (row.c.length !== t.header.length) {
      parseDie(where, `row has ${row.c.length} cells, header has ${t.header.length}. Row: ${row.c.join(' | ')}`);
    }
    const ml = parseMloadCell(row.c[ix.ml], where);
    out.push({
      id: tick(row.c[ix.id], where), name: stripFmt(row.c[ix.name]), a: stripFmt(row.c[ix.arch]),
      cat: 'rule', rar: rarity(row.c[ix.rar], where), rp: num(row.c[ix.rp], where),
      aim: num(row.c[ix.aim], where), effect: stripFmt(row.c[ix.eff]),
      field: ix.field >= 0 ? stripFmt(row.c[ix.field]) : null,
      fieldRaw: ix.field >= 0 ? row.c[ix.field] : '',
      mload: ml.mload, ex: ml.ex, mfPhase: ml.mfPhase,
      act: false, src: '§6.7.7', line: row.line, origin: 'mandated-new',
    });
  }
  return out;
}

/* ================================================================= *
 * STAGE D — the roster doc AS AUTHORED                               *
 *                                                                    *
 * relic-roster-expansion.md is edited independently of the framework. *
 * We parse what it actually says today and diff it against §6.7's    *
 * "rar trước" column, so a mid-edit roster is REPORTED, not assumed. *
 * ================================================================= */
function parseRoster(md) {
  const byId = new Map();
  const lines = md.split('\n');
  const HEAD = /^###\s+`([a-z_0-9]+)`\s*—\s*([^·]+)·\s*\**(COMMON|RARE|EPIC|LEGENDARY)\**\s*·\s*`a:'([a-z]+)'`(.*)$/;
  for (let i = 0; i < lines.length; i++) {
    const l = lines[i];
    if (!/^###\s+`/.test(l)) continue;
    const m = HEAD.exec(l);
    if (!m) {
      parseDie(`roster line ${i + 1}`, `relic heading does not match `
        + '"### `id` — Name · RARITY · `a:\'arch\'`": ' + l.trim());
    }
    const id = m[1];
    if (byId.has(id)) parseDie(`roster line ${i + 1}`, `duplicate relic heading for \`${id}\``);
    const tail = m[5] || '';
    const mlm = /`mload\s*(\d)`/.exec(tail);
    const exm = /`ex:\s*(\[[^\]]*\])`/.exec(tail);
    const eng = [...tail.matchAll(/ENG-(\d+)/g)].map((x) => 'ENG-' + x[1]);
    /* the body: keep the act: line and the exact-effect line for later checks */
    let body = [];
    for (let j = i + 1; j < lines.length && !/^#{2,3}\s/.test(lines[j]); j++) body.push(lines[j]);
    body = body.join('\n');
    const actm = /\*\*act:\*\*\s*`\{([^}]*)\}`/.exec(body);
    let act = null;
    if (actm) {
      act = {};
      for (const kv of actm[1].split(',')) {
        const p = kv.split(':');
        if (p.length < 2) continue;
        act[p[0].trim()] = p.slice(1).join(':').trim().replace(/^'|'$/g, '');
      }
    }
    const mpm = /\[MP\s*(\d+)\]/.exec(body);
    byId.set(id, {
      id, name: m[2].trim(), rar: RAR_NAME.indexOf(m[3]), a: m[4],
      mload: mlm ? Number(mlm[1]) : null,
      ex: exm ? (exm[1].match(/'([^']+)'/g) || []).map((x) => x.replace(/'/g, '')) : null,
      eng, act, cost: act && act.cost ? Number(act.cost) : (mpm ? Number(mpm[1]) : null),
      kind: act ? act.kind : null, body, line: i + 1,
    });
  }
  /* §16 "Tóm tắt" — which relics are gated on engine work that does not exist yet */
  const gated = new Map();
  const sec = sliceSection(md, /^### Tóm tắt/, /^### ENG-0/, 'roster §16 Tóm tắt');
  const t = theTable(sec, ['Mục', 'Relic bị gate']);
  const gi = t.header.map(stripFmt).findIndex((h) => h.startsWith('Relic bị gate'));
  const ei = 0;
  for (const row of t.rows) {
    const eng = stripFmt(row.c[ei]);
    for (const g of (row.c[gi].match(/`([a-z_0-9]+)`/g) || [])) {
      const rid = g.replace(/`/g, '');
      if (!gated.has(rid)) gated.set(rid, []);
      gated.get(rid).push(eng);
    }
  }
  /* §17.2 mload/ex for the 48 */
  const s172 = sliceSection(md, /^### 17\.2 /, /^### 17\.3 /, 'roster §17.2');
  const mtab = theTable(s172, ['mload', 'Relic']);
  const rosterMload = new Map();
  for (const row of mtab.rows) {
    const lvl = num(row.c[0], 'roster §17.2');
    for (const g of (row.c[2].match(/`([a-z_0-9]+)`/g) || [])) {
      rosterMload.set(g.replace(/`/g, ''), lvl);
    }
  }
  return { byId, gated, rosterMload };
}

/* ================================================================= *
 * STAGE E — src/data.js + src/engine.js, evaluated in one scope      *
 *           (same vm pattern as tools/t_import.mjs and tools/sim.js) *
 * ================================================================= */
function loadSrc() {
  const dataSrc = fs.readFileSync(IN_DATA, 'utf8');
  const engineSrc = fs.readFileSync(IN_ENGINE, 'utf8');
  const ctx = { console: { log() {}, warn() {}, error() {} }, Math, JSON, Date };
  vm.createContext(ctx);
  const NAMES = ['ARCH', 'RELICS', 'RELIC_BY_ID', 'PASSIVE', 'FACE_POOL', 'HEROES', 'faceArch', 'archScore',
    'RARITY', 'RELIC_SHOP_COST'];
  const src = [dataSrc, engineSrc].join('\n')
    + '\n;globalThis.__X={' + NAMES.map((n) => `${n}: (typeof ${n} === 'undefined' ? undefined : ${n})`).join(',') + '};';
  try { vm.runInContext(src, ctx); } catch (e) {
    parseDie('src', `could not evaluate src/data.js + src/engine.js in a vm: ${e.message}`);
  }
  const G = ctx.__X;
  if (!G || !G.ARCH || !Array.isArray(G.RELICS)) {
    parseDie('src', 'src/data.js evaluated but ARCH / RELICS are not exported into scope');
  }
  return { G, dataSrc, engineSrc };
}

/* ================================================================= *
 * CHECK 1 — INV-1 / AC-15 / AC-16 / AC-17   (the headline)           *
 * ================================================================= */
function checkINV1(roster, derived, tag) {
  const { band } = derived;
  let inBand = 0;
  const outOfBand = [], inForbidden = [];
  for (const r of roster) {
    const b = band[r.rar];
    if (!b) { hardFail('INV-1', r.id, 'a rarity in 0..3', String(r.rar)); continue; }
    /* compare at the doc's own printed precision (0.01 RP) so that 15.18 counts as inside */
    const lo = round2(b[0]), hi = round2(b[1]), rp = round2(r.rp);
    if (rp >= lo && rp <= hi) inBand++;
    else outOfBand.push({ ...r, band: [lo, hi], miss: rp < lo ? 'below floor' : 'above ceiling' });
    for (let k = 0; k < 3; k++) {
      if (rp > round2(band[k][1]) && rp < round2(band[k + 1][0])) {
        inForbidden.push({ ...r, zone: [round2(band[k][1]), round2(band[k + 1][0])] });
      }
    }
  }
  /* AC-16 — every relic inside its own band */
  for (const v of outOfBand) {
    hardFail(`INV-1${tag}`, `${v.id} (${RAR_NAME[v.rar]}, ${v.src})`,
      `RP ∈ Band[${RAR_NAME[v.rar]}] = [${v.band[0]}, ${v.band[1]}]`,
      `RP = ${round2(v.rp)} — ${v.miss} by ${round2(v.miss === 'below floor' ? v.band[0] - v.rp : v.rp - v.band[1])} RP`,
      v.effect ? v.effect.slice(0, 120) : null);
  }
  /* AC-17 — forbidden zones empty */
  for (const v of inForbidden) {
    hardFail(`INV-3${tag}`, `${v.id} (${RAR_NAME[v.rar]})`,
      `RP outside the forbidden zone (${v.zone[0]}, ${v.zone[1]})`,
      `RP = ${round2(v.rp)} sits between two tiers`);
  }
  /* AC-15 — measured non-overlap across tiers */
  const byRar = [0, 1, 2, 3].map((r) => roster.filter((x) => x.rar === r));
  const extremes = byRar.map((g, r) => {
    if (!g.length) return null;
    const mn = g.reduce((a, b) => (b.rp < a.rp ? b : a));
    const mx = g.reduce((a, b) => (b.rp > a.rp ? b : a));
    return { r, n: g.length, min: mn, max: mx };
  });
  for (let r = 0; r < 3; r++) {
    const a = extremes[r], b = extremes[r + 1];
    if (!a || !b) continue;
    if (!(a.max.rp < b.min.rp)) {
      hardFail(`INV-1${tag}-OVERLAP`, `${RAR_NAME[r]} vs ${RAR_NAME[r + 1]}`,
        `max(${RAR_NAME[r]}) < min(${RAR_NAME[r + 1]})`,
        `max(${RAR_NAME[r]}) = ${round2(a.max.rp)} (${a.max.id}) >= min(${RAR_NAME[r + 1]}) = ${round2(b.min.rp)} (${b.min.id})`,
        'a lower-rarity relic is at least as strong as a higher-rarity one — the reported defect');
    }
  }
  return { inBand, outOfBand, inForbidden, extremes, total: roster.length };
}

/* ================================================================= *
 * MAIN                                                               *
 * ================================================================= */
function main() {
  const opts = parseArgs(process.argv.slice(2));
  if (opts.help) { console.log(HELP); return 0; }

  const fw = fs.readFileSync(IN_FRAMEWORK, 'utf8');
  const rosterMd = fs.readFileSync(IN_ROSTER, 'utf8');
  const model = parseBandModel(fw);
  const derived = deriveBands(model);
  const geom = checkBandDerivation(model, derived);

  const originals = parseOriginals(fw, derived);
  const audited = parseAudit(fw);
  const roster = parseRoster(rosterMd);
  const src = loadSrc();

  const all = [...originals, ...audited];

  /* --- structural counts: the doc states these in three independent places --- */
  const nOrig = originals.length;
  const nExp = audited.filter((r) => r.origin === 'expansion').length;
  const nNew = audited.filter((r) => r.origin === 'mandated-new').length;
  if (nOrig !== EXPECT_ORIGINALS) {
    hardFail('PARSE-6', '§6.1..§6.5', `${EXPECT_ORIGINALS} retuned originals`, String(nOrig));
  }
  if (nExp !== EXPECT_EXPANSION) {
    hardFail('PARSE-6.7', '§6.7.1..§6.7.6', `${EXPECT_EXPANSION} audited expansion relics`, String(nExp));
  }
  if (nNew !== EXPECT_NEW) {
    hardFail('PARSE-6.7.7', '§6.7.7', `${EXPECT_NEW} mandated new PLAGUE entries`, String(nNew));
  }
  if (all.length !== EXPECT_TOTAL) {
    hardFail('PARSE-TOTAL', 'combined roster', `${EXPECT_TOTAL} relics (44 + 48 + 2, §6.7.7)`,
      `${all.length} parsed (${nOrig} + ${nExp} + ${nNew})`);
  }
  const dupes = [];
  const seen = new Set();
  for (const r of all) { if (seen.has(r.id)) dupes.push(r.id); seen.add(r.id); }
  for (const d of dupes) hardFail('ID-UNIQUE', d, 'each relic id appears exactly once in the combined roster', 'duplicated');

  /* --- CHECK 1: INV-1 on the mandated 94 --- */
  const inv1 = checkINV1(all, derived, '');

  /* INV-2b is in force above, so the gate and the doc quote one band. The only relics the
     rounding can move are those in the SLIVER between a raw ±τ edge and its normative edge:
     they pass the raw model and fail the doc. They already hard-fail INV-1, so do not fail
     them twice — name them, so the failure reads as "0.01 outside the printed edge" rather
     than as a mis-costed relic. Empty today; measured, not assumed. */
  const sliver = all.filter((r) => {
    const nb = derived.band[r.rar], rb = derived.raw[r.rar];
    const inN = r.rp >= nb[0] - 1e-9 && r.rp <= nb[1] + 1e-9;
    const inR = r.rp >= rb[0] - 1e-9 && r.rp <= rb[1] + 1e-9;
    return inR && !inN;
  });
  if (sliver.length) {
    finding('INV-2b', `${sliver.length} relic(s) fall in the sliver cut off by INV-2b inward rounding — `
      + 'they satisfy the raw ±τ band and fail the normative one, so their INV-1 failure above is a '
      + 'rounding-edge case: nudge the RP, do not touch the band',
      sliver.map((r) => `${r.id} (${RAR_NAME[r.rar]}, RP ${round2(r.rp)}, normative `
        + `[${derived.band[r.rar][0]}, ${derived.band[r.rar][1]}])`).join(' · '));
  }

  /* --- the "before" control (AC-16): the expansion AS AUTHORED, pre-audit ---
     Run with the SAME band arithmetic. If this does not reproduce the doc's own
     "37/48 violate" figure, the RP model in this tool has drifted from §4.4 and the
     tool is wrong, not the data. That is why the control exists. */
  const before = audited.filter((r) => r.origin === 'expansion')
    .map((r) => ({ ...r, rar: r.rarBefore, rp: r.rpBefore, src: r.src + ' (pre-audit)' }));
  const beforeViolations = before.filter((r) => {
    const b = derived.band[r.rar];
    const rp = round2(r.rp);
    return !(rp >= round2(b[0]) && rp <= round2(b[1]));
  });
  const EXPECT_BEFORE = 37;
  if (beforeViolations.length !== EXPECT_BEFORE) {
    hardFail('AC-16-CONTROL', '§6.7 pre-audit control',
      `${EXPECT_BEFORE} of ${before.length} expansion relics violate INV-1 before the audit (stated in §6.7)`,
      `${beforeViolations.length} of ${before.length} measured`,
      'the doc\'s own "RP trước" column disagrees with the doc\'s own violation count — one of them is wrong');
  }

  runRemainingChecks({ all, originals, audited, roster, src, derived, model, fw, rosterMd });

  const rep = { model, derived, geom, inv1, all, originals, audited, roster, src, before, beforeViolations,
    rosterLines: rosterMd.split('\n').length,
    rosterMtime: fs.statSync(IN_ROSTER).mtime.toISOString().replace('T', ' ').slice(0, 19) };
  if (opts.json) console.log(JSON.stringify(toJson(rep), null, 2));
  else report(rep, opts);
  return adjudicate(opts);
}

function toJson(rep) {
  return {
    constants: { ANCHOR: rep.model.anchor, SIG: rep.model.sig, tau: rep.model.tau },
    bands: rep.derived.band.map((b, i) => ({ rarity: RAR_NAME[i], C: round2(rep.derived.C[i]), L: round2(b[0]), U: round2(b[1]) })),
    geometry: { minCentreRatio: round4(rep.geom.minRatio), bandSpread: round4(rep.geom.spread), tauCeiling: round4(rep.geom.tauMax) },
    counts: { total: rep.all.length, inBand: rep.inv1.inBand, outOfBand: rep.inv1.outOfBand.length },
    violations: rep.inv1.outOfBand.map((v) => ({ id: v.id, rarity: RAR_NAME[v.rar], rp: round2(v.rp), band: v.band, miss: v.miss, src: v.src })),
    failures, findings,
  };
}

function report(rep, opts) {
  const L = (s) => console.log(s === undefined ? '' : s);
  const { derived: d, model: m, inv1 } = rep;
  L();
  L('t_relic — RELIC SYSTEM INVARIANT GATE');
  L('='.repeat(78));
  L(`  framework : ${path.relative(ROOT, IN_FRAMEWORK)}`);
  L(`  roster    : ${path.relative(ROOT, IN_ROSTER)}  (${rep.roster.byId.size} relic headings, `
    + `${rep.rosterLines} lines, mtime ${rep.rosterMtime})`);
  L(`  engine    : ${path.relative(ROOT, IN_DATA)} + ${path.relative(ROOT, IN_ENGINE)} `
    + `(${rep.src.G.RELICS.length} relics live, ARCH has ${Object.keys(rep.src.G.ARCH).length} archetypes)`);
  L('='.repeat(78));
  L('MEASUREMENT PROVENANCE — every count below is for exactly this input state');
  L(`  RP source of truth : relic-system.md §6.1-§6.5 (44 retuned) + §6.7.1-§6.7.6 (48 audited)`);
  L(`                       + §6.7.7 (2 mandated new) = ${rep.all.length} relics`);
  L(`  roster doc role    : cross-check only. relic-roster-expansion.md is edited independently;`);
  L(`                       INV-1 is measured against the §6.7 audit END STATE, which does not move.`);
  const ids = EXTRA.ids || { retuned: [], pending: [] };
  const state = (ids.retuned.length && ids.pending.length) ? 'MID-EDIT'
    : (ids.pending.length ? 'PRE-AUDIT (retunes not yet applied)' : 'FULLY RETUNED');
  L(`  roster doc state   : ${state} — ${ids.retuned.length} relic(s) at their post-audit rarity, `
    + `${ids.pending.length} still pre-audit`);
  L('='.repeat(78));
  L();
  L('BAND MODEL — derived from the doc, never hardcoded');
  L(`  ANCHOR = ${m.anchor}   SIG = [${m.sig.join(', ')}]   τ = ${m.tau}`);
  L(`  (1+τ)/(1−τ) = ${round4(rep.geom.spread)}   <   min(C_r+1/C_r) = ${round4(rep.geom.minRatio)}   `
    + `⇒ bands disjoint (τ ceiling ${round4(rep.geom.tauMax)}, headroom ${round2((rep.geom.tauMax / m.tau - 1) * 100)}%)`);
  L(`  superseded ±20% would give 1.5000 > ${round4(rep.geom.minRatio)} ⇒ overlap certain`);
  L('  INV-2b: edges rounded INWARD to 2dp and NORMATIVE — narrowing only, so INV-1 holds a fortiori');
  L('    ' + d.band.map((b, r) => `${RAR_NAME[r][0]} [${round4(d.raw[r][0])}, ${round4(d.raw[r][1])}] -> `
    + `[${b[0].toFixed(2)}, ${b[1].toFixed(2)}]`).join('  '));
  L();
  L('  tier         centre        band              relics   min RP                 max RP');
  for (let r = 0; r < 4; r++) {
    const e = inv1.extremes[r];
    L(`  ${RAR_NAME[r].padEnd(11)} ${round2(d.C[r]).toFixed(2).padStart(6)}   `
      + `[${round2(d.band[r][0]).toFixed(2)}, ${round2(d.band[r][1]).toFixed(2)}]`.padEnd(18)
      + `${String(e ? e.n : 0).padStart(4)}   `
      + (e ? `${round2(e.min.rp).toFixed(2)} ${('(' + e.min.id + ')').padEnd(18)} ${round2(e.max.rp).toFixed(2)} (${e.max.id})` : '—'));
  }
  L();
  L('INV-1 — every relic inside its own band, bands disjoint');
  L(`  ${inv1.inBand} / ${inv1.total} satisfy INV-1   ·   ${inv1.outOfBand.length} violate   ·   `
    + `${inv1.inForbidden.length} in a forbidden zone`);
  if (inv1.outOfBand.length) {
    L();
    L('  VIOLATIONS (id · rarity · computed RP · band it missed):');
    for (const v of inv1.outOfBand) {
      L(`    ${v.id.padEnd(18)} ${RAR_NAME[v.rar].padEnd(10)} RP ${round2(v.rp).toFixed(2).padStart(6)}   `
        + `band [${v.band[0].toFixed(2)}, ${v.band[1].toFixed(2)}]   ${v.miss}   ${v.src}`);
    }
  }
  L();
  L(`  pre-audit control (§6.7 "RP trước", expansion as authored): `
    + `${rep.beforeViolations.length} / ${rep.before.length} violate INV-1  (doc states 37/48)`);
  if (opts.verbose) {
    L();
    L('ALL RELICS');
    for (const r of rep.all.slice().sort((a, b) => a.rar - b.rar || a.rp - b.rp)) {
      const b = d.band[r.rar];
      const ok = round2(r.rp) >= round2(b[0]) && round2(r.rp) <= round2(b[1]);
      L(`  ${ok ? ' ' : '!'} ${r.id.padEnd(18)} ${RAR_NAME[r.rar].padEnd(10)} ${r.a.padEnd(8)} `
        + `RP ${round2(r.rp).toFixed(2).padStart(6)}  ${r.src}`);
    }
  }
  reportExtra(rep, L);
  const seenNote = new Set();
  if (findings.length) {
    L();
    L('NOTES');
    for (const f of findings) {
      if (seenNote.has(f.msg)) continue;
      seenNote.add(f.msg);
      L(`  [${f.kind}] ${f.msg}`);
      if (f.data) L(`        ${typeof f.data === 'string' ? f.data : JSON.stringify(f.data)}`);
    }
  }
}

/* Two-sided allowlist, identical semantics to gen_faces.mjs. */
function adjudicate(opts) {
  let allow = [];
  if (!opts.strict && fs.existsSync(KNOWN_FAILURES)) {
    try { allow = (JSON.parse(fs.readFileSync(KNOWN_FAILURES, 'utf8')).t_relic || []); }
    catch (e) { console.log(`t_relic: cannot read ${path.relative(ROOT, KNOWN_FAILURES)}: ${e.message}`); return 2; }
  }
  const allowById = new Map(allow.map((a) => [a.id, a]));
  const known = failures.filter((f) => allowById.has(f.id));
  const fresh = failures.filter((f) => !allowById.has(f.id));
  const firedIds = new Set(failures.map((f) => f.id));
  const stale = allow.filter((a) => !firedIds.has(a.id));
  const show = (list) => {
    for (const f of list) {
      console.log(`  [${f.id}] ${f.row}`);
      console.log(`        expected: ${f.expected}`);
      console.log(`        actual:   ${f.actual}`);
      if (f.extra) console.log(`        note:     ${f.extra}`);
    }
  };
  if (known.length) {
    console.log(`\n${known.length} KNOWN failure(s) — declared in ${path.relative(ROOT, KNOWN_FAILURES)}, not a build break:`);
    for (const a of allowById.values()) {
      const n = known.filter((f) => f.id === a.id).length;
      if (n) console.log(`  [${a.id}] x${n} — owner ${a.owner} — ${a.reason || a.ref || ''}`);
    }
  }
  if (stale.length) {
    console.log(`\n${stale.length} STALE allowlist entr(y/ies) — these invariants now PASS, remove them:`);
    for (const a of stale) console.log(`  [${a.id}] declared ${a.since} by ${a.owner} — delete it from ${path.relative(ROOT, KNOWN_FAILURES)}`);
  }
  if (fresh.length) {
    console.log(`\n${fresh.length} HARD FAILURE(S) — build gate is RED\n`);
    show(fresh);
  }
  if (opts.strict && known.length) { console.log(`\n--strict: ${known.length} known failure(s) shown in full\n`); show(known); }
  if (!fresh.length && !stale.length) {
    console.log(`\ngate: GREEN${known.length ? ` (${known.length} known failure(s) allowed)` : ''}`);
  }
  return (fresh.length || stale.length) ? 1 : 0;
}

/* ---- wiring: every check above, plus its slice of the human report ---- */
const EXTRA = {};
function runRemainingChecks(ctx) {
  const { all, roster, src, fw, rosterMd } = ctx;
  /* engine-work text, so a field that is "pending" is not reported as "dead" */
  roster.fwText = fw;
  roster.engText = sliceSection(rosterMd, /^## 16\. /, /^## 17\. /, 'roster §16').lines.join('\n');
  roster.fwEngText = sliceSection(fw, /^## 10\. /, /^## 11\. /, '§10').lines.join('\n');

  const K = parseModelConstants(fw);
  EXTRA.K = K;
  EXTRA.act = checkActives(all, K, src.engineSrc, roster);
  EXTRA.field = checkFieldLiveness(all, src, roster, fw);
  EXTRA.tags = checkTags(all, src, fw);
  EXTRA.dir = checkDirectionLaw(src);
  EXTRA.dedup = checkDedupAndMload(all, src, fw, roster, EXTRA.field.mloadFields);
  EXTRA.cov = checkCoverage(all, src, fw);
  EXTRA.ids = checkIdStability(all, src, roster);
  EXTRA.shop = checkShop(src);
}

function reportExtra(rep, L) {
  const { act, field, tags, dir, dedup, cov, ids, K } = EXTRA;
  if (!act) return;
  L();
  L('ACTIVES — priced on per-turn repeatability (§4.3c / §4.4a)');
  L(`  engine premise (actives reset EVERY turn): ${act.perTurnProven ? 'PROVEN — ' + act.perTurnWhere : 'NOT PROVEN'}`);
  L(`  Ω = ${K['Ω']} turns · M_com = ${K.M_com} mana/fight · VPM_0 = R_mana = ${K.R_mana} · Sat = ${K.D} (∞ for ${K.SAT_INF.join('/')})`);
  L(`  ${act.actives.length} actives · engine implements kinds: ${act.implementedKinds.join(' ')}`);
  L('  id                MP   Θ(c)  N*   RP_act stated   re-derived');
  for (const r of act.rederived) {
    L(`    ${r.id.padEnd(16)} ${String(r.cost).padStart(3)}  ${String(r.theta).padStart(4)}  `
      + `${String(r.statedN == null ? '—' : r.statedN).padStart(2)}   ${round2(r.statedRP).toFixed(2).padStart(8)}        `
      + (r.computed == null ? '(no V_out in the doc)' : round2(r.computed).toFixed(2)));
  }
  L();
  L('FIELD LIVENESS — every relic field must be read by src/engine.js');
  const dOnly = [...field.declared.keys()].filter((f) => !field.liveFields.has(f)).sort();
  const lOnly = [...field.liveFields.keys()].filter((f) => !field.declared.has(f)).sort();
  L(`  ${field.declared.size} field(s) named in the design tables · ${field.liveFields.size} on the shipped relics`);
  L(`  named in the docs but not on any shipped relic yet: ${dOnly.join(' ') || 'none'}`);
  L(`  shipped but never named in the §6 tables:           ${lOnly.join(' ') || 'none'}`);
  L(`  dead (nothing reads them, no engine work declared): ${field.dead.length ? field.dead.map((d) => d.f).join(' ') : 'none'}`);
  L(`  pending engine work (declared, not yet read):       ${field.gatedFields.length ? field.gatedFields.map((g) => g.f).join(' ') : 'none'}`);
  L(`  addStatus() final else branch: ${field.hasFinalElse ? 'present' : 'ABSENT — unknown keywords are dropped silently'}`);
  if (field.dropped.length) L(`  keywords documented but handled nowhere: ${field.dropped.join(' ')}`);
  L();
  L('TAG INTEGRITY — checked against the runtime ARCH, not the doc');
  L(`  ARCH has ${tags.keys.length} archetype(s) (doc requires ${tags.want}): ${tags.keys.join(' ')}`);
  L(`  doc relics with an unresolvable tag: ${tags.missing.length ? tags.missing.join(' ') : 'none'}`);
  L(`  shipped relics untagged: ${tags.liveUntagged.length ? tags.liveUntagged.join(' ') : 'none'}`
    + ` · shipped with an unresolvable tag: ${tags.liveUnknown.length ? tags.liveUnknown.join(' ') : 'none'}`);
  L();
  L('kwPure DIRECTION LAW — by executing every shipped modFace over a synthetic die carrying all 8 face types');
  const inj = dir.filter((d) => KWPURE.includes(d.kw));
  L(`  ${dir.length} keyword injection(s) observed across ${new Set(dir.map((d) => d.id)).size} relic(s); `
    + `${inj.length} of them are kwPure (direction-sensitive)`);
  for (const d of dir) L(`    ${d.id.padEnd(16)} ${String(d.kw).padEnd(10)} -> ${d.type} face`);
  L();
  L('DE-DUPLICATION / ANTI-STACKING');
  L(`  RELIC_MLOAD_CAP = ${dedup.CAP} · rmax-merged fields: ${dedup.rmaxFields.join(' ')}`);
  L(`  ||-merged fields: ${dedup.orFields.join(' ')} · KW_EX: ${JSON.stringify(dedup.KW_EX)}`);
  L(`  mload/ex declared for ${dedup.covered} of ${dedup.covered + dedup.uncovered} relics`);
  L();
  L('ARCHETYPE COVERAGE (§5.1 targets: ' + cov.MIN.map((n, i) => `>=${n} ${RAR_NAME[i][0]}`).join(' ')
    + `, >=1 active, <=${cov.MAXPER} each, max/min <= ${cov.RATIO})`);
  L('  archetype    C   R   E   L  passive  active  total');
  for (const a of cov.universe) {
    const t = cov.table[a];
    L(`  ${a.padEnd(11)}${t.passive.map((n) => String(n).padStart(3) + ' ').join('')}`
      + `${String(t.passive.reduce((x, y) => x + y, 0)).padStart(7)}${String(t.active).padStart(8)}${String(t.total).padStart(7)}`);
  }
  L(`  max/min = ${round2(cov.ratio)}`);
  if (EXTRA.shop) {
    const sh = EXTRA.shop;
    L();
    L('SHOP PRICING — AC-21, strictly increasing over every declared rarity');
    L(`  RELIC_SHOP_COST = [${sh.tiers.join(', ')}] · ${sh.tiers.length} price(s) for `
      + `${Array.isArray(sh.rarNames) ? sh.rarNames.length : '?'} declared rarity(ies) `
      + `(${Array.isArray(sh.rarNames) ? sh.rarNames.join(' ') : '—'}) · max shipped rar = ${sh.maxRar}`);
    L(`  genShop() price line(s) reading the table: ${sh.priceLines ? sh.priceLines.length : 0} · `
      + `with a \`||\` fallback: ${sh.priceLines ? sh.priceLines.filter((l) => /\|\|/.test(l)).length : '?'}`);
  }
  L();
  L('ID STABILITY / DOC SYNC');
  L(`  ${ids.liveIds.length} shipped ids · ${ids.lost.length} would be lost by the retune`);
  L(`  roster file state: ${ids.retuned.length} relic(s) already carry their post-audit rarity, `
    + `${ids.pending.length} still at their pre-audit rarity`);
  if (ids.retuned.length && ids.pending.length) {
    L('  -> the roster doc is MID-EDIT. Numbers above are measured against the §6.7 audit (the mandated');
    L('     end state), which does not move; the roster file only affects the DOC-SYNC lines.');
  }
}


/* ================================================================= *
 * CHECK 2 — ACTIVES: per-turn repeatability is the whole story       *
 *                                                                    *
 * `s.usedActives = []` runs immediately after `s.turn++`, so an       *
 * active is usable ONCE PER TURN, every turn, gated only by mana.     *
 * Anything priced "once per fight" is wrong by a factor of Θ(c).      *
 * We (a) verify that premise against src/engine.js rather than        *
 * trusting the doc, (b) re-derive RP_act from §4.4a and compare it    *
 * to every stated value, and (c) check monotonicity among actives     *
 * alone, since an underpriced RARE active is the reported defect.     *
 * ================================================================= */
const SAFE_EXPR = /^[0-9+\-*/(). ]+$/;
function safeEval(expr, where) {
  const e = String(expr).replace(/×/g, '*').replace(/−/g, '-').replace(/–/g, '-').replace(/,/g, '');
  if (!SAFE_EXPR.test(e)) parseDie(where, `V_out expression is not plain arithmetic: "${expr}"`);
  let v;
  try { v = Function(`"use strict";return (${e});`)(); } catch (err) { parseDie(where, `cannot evaluate "${expr}": ${err.message}`); }
  if (!Number.isFinite(v)) parseDie(where, `V_out expression "${expr}" did not evaluate to a finite number`);
  return v;
}
/* split on '+' at paren depth 0 — "40 + 36.55" is two components, "4×(3+2+1)" is one */
function splitTopLevel(expr) {
  const out = []; let depth = 0, cur = '';
  for (const ch of expr) {
    if (ch === '(') depth++;
    else if (ch === ')') depth--;
    if (ch === '+' && depth === 0) { out.push(cur); cur = ''; continue; }
    cur += ch;
  }
  out.push(cur);
  return out.map((x) => x.trim()).filter(Boolean);
}

function parseModelConstants(fw) {
  const sec = sliceSection(fw, /^### 4\.0 /, /^### 4\.1 /, '§4.0');
  const t = theTable(sec, ['Ký hiệu', 'Giá trị']);
  const K = {};
  for (const row of t.rows) {
    const names = (row.c[0].match(/`([^`]+)`/g) || []).map((x) => x.replace(/`/g, ''));
    const vals = (row.c[2].match(/-?\d+(?:\.\d+)?/g) || []).map(Number);
    if (!names.length) continue;
    if (names.length === vals.length) names.forEach((n, i) => { K[n] = vals[i]; });
    else if (vals.length) names.forEach((n) => { K[n] = vals[vals.length - 1]; });
  }
  const rm = /R\s*=\s*\{[^}]*\bmana\s+([0-9.]+)/.exec(sec.lines.join('\n'));
  if (!rm) parseDie('§4.0', 'cannot find R_mana inside the R = { ... } role-rate line');
  K.R_mana = Number(rm[1]);
  for (const need of ['Ω', 'M_com', 'D', 'Act', 'T_in']) {
    if (!Number.isFinite(K[need])) parseDie('§4.0', `constant \`${need}\` not parsed from the §4.0 table (got ${K[need]})`);
  }
  /* §4.4a: which output components are unsaturable */
  const s44a = sliceSection(fw, /^### 4\.4a /, /^### 4\.4b /, '§4.4a');
  const satM = /tiện ích\s*\(([^)]*)\)\s*→\s*`?Sat\s*=\s*∞/.exec(s44a.lines.join('\n'));
  if (!satM) parseDie('§4.4a', 'cannot find the "Sat = ∞" utility-component list');
  K.SAT_INF = satM[1].split(',').map((x) => x.replace(/`/g, '').trim()).filter(Boolean);
  return K;
}

function checkActives(all, K, engineSrc, rosterDoc) {
  const actives = all.filter((r) => r.act);
  const res = { actives, perTurnProven: false, rederived: [], mismatches: [] };

  /* (a) the premise, verified against src/engine.js and not against the doc */
  /* Locate the function that advances the turn, then assert the reset happens inside it and
     AFTER the increment. A proximity regex would false-negative on any statement inserted
     between the two lines, and a false negative here is worse than a failure: it would leave
     the premise of the entire active model silently unproven while the gate still passed. */
  const compact = engineSrc.replace(/[ \t]+/g, ' ');
  const lines = engineSrc.split('\n');
  const incLine = lines.findIndex((l) => /\bs\.turn\+\+/.test(l));
  let fnStart = -1;
  for (let i = incLine; i >= 0; i--) if (/^(function|const|let|var)\s/.test(lines[i])) { fnStart = i; break; }
  let fnEnd = lines.length;
  for (let i = incLine + 1; i < lines.length; i++) if (/^(function|const|let|var)\s/.test(lines[i])) { fnEnd = i; break; }
  const resetLine = lines.findIndex((l, i) => i > incLine && i < fnEnd && /s\.usedActives\s*=\s*\[\s*\]/.test(l));
  res.perTurnProven = incLine >= 0 && resetLine > incLine;
  res.perTurnWhere = res.perTurnProven
    ? `src/engine.js:${incLine + 1} s.turn++  ->  :${resetLine + 1} s.usedActives=[]`
    + `${fnStart >= 0 ? '  (both inside ' + lines[fnStart].trim().slice(0, 40) + ')' : ''}`
    : null;
  if (!res.perTurnProven) {
    hardFail('ACT-PERTURN', 'src/engine.js',
      '`s.usedActives = []` executes after `s.turn++` inside the same turn-advance function — '
      + 'the §4.3c premise that EVERY active is reusable EVERY turn, gated only by mana',
      incLine < 0 ? 'no `s.turn++` found at all'
        : `\`s.turn++\` is at line ${incLine + 1} but no \`s.usedActives = []\` follows it in that function`,
      'RP_act (§4.4a) prices all 16 actives on Θ(c) = min(Ω, ⌊M_com/c⌋) casts PER FIGHT because they '
      + 'repeat every turn. If that premise is false, every RP_act in §6.5 and §6.7 is wrong and the '
      + 'INV-1 result above is meaningless for actives.');
  }
  const gate = /usedActives\.includes\([^)]*\)\s*\|\|\s*s\.mana\s*<\s*[a-zA-Z.]*cost/.test(compact);
  if (!gate) {
    finding('ACT-GATE', 'could not confirm the reuse gate `s.usedActives.includes(id) || s.mana < cost` in src/engine.js',
      'the pricing model assumes mana is the ONLY limiter; verify by hand if this note appears');
  }

  const theta = (c) => Math.min(K['Ω'], Math.floor(K.M_com / c));

  /* (b) re-derive RP_act for every active the doc gives a V_out for (the 8 in §6.5) */
  for (const a of actives) {
    if (!a.voutRaw) continue;
    const where = `${a.src} line ${a.line} (${a.id})`;
    const raw = stripFmt(a.voutRaw);
    const eq = raw.lastIndexOf('=');
    if (eq < 0) parseDie(where, `V_out cell has no "= total": "${raw}"`);
    const stated = Number(raw.slice(eq + 1).trim());
    const expr = raw.slice(0, eq).trim();
    if (!Number.isFinite(stated)) parseDie(where, `V_out total is not a number: "${raw}"`);
    const comps = splitTopLevel(expr).map((x) => safeEval(x, where));
    const sum = comps.reduce((x, y) => x + y, 0);
    if (Math.abs(sum - stated) > 0.02) {
      hardFail('RP-ACT-ARITH', `${a.id} (${a.src})`, `V_out = ${stated} (as written)`,
        `the expression "${expr}" evaluates to ${round2(sum)}`,
        "the doc's own V_out arithmetic does not add up");
      continue;
    }
    /* saturation: utility kinds are unbounded, everything else caps at the fight's demand */
    const inf = K.SAT_INF.some((k) => a.kind === k);
    const sat = inf ? Infinity : K.D;
    const c = a.cost;
    const TH = theta(c);
    let best = -Infinity, bestN = 0;
    for (let N = 1; N <= TH; N++) {
      const value = comps.reduce((acc, v) => acc + Math.min(N * v, sat), 0);
      const net = value - N * K.R_mana * c;
      if (net > best) { best = net; bestN = N; }
    }
    res.rederived.push({ id: a.id, cost: c, theta: TH, comps, sat, computed: best, statedRP: a.rp, statedN: a.nstar, bestN });
    if (Math.abs(best - a.rp) > 0.02) {
      hardFail('RP-ACT', `${a.id} (${RAR_NAME[a.rar]}, MP ${c}, ${a.src})`,
        `RP_act = ${round2(a.rp)} (stated in the doc)`,
        `RP_act = ${round2(best)} re-derived from §4.4a `
        + `[V_out components ${comps.map(round2).join(' + ')}, Sat ${inf ? '∞' : sat}, Θ(${c}) = ${TH}, N* = ${bestN}]`);
    }
    if (a.nstar != null && a.nstar !== bestN) {
      hardFail('RP-ACT-N', `${a.id} (${a.src})`, `N* = ${a.nstar} (stated)`, `N* = ${bestN} (argmax of the §4.4a objective)`);
    }
    if (a.nstar != null && a.nstar > TH) {
      hardFail('RP-ACT-THETA', `${a.id} (${a.src})`, `N* <= Θ(${c}) = min(Ω ${K['Ω']}, ⌊M_com ${K.M_com}/${c}⌋) = ${TH}`,
        `N* = ${a.nstar} casts assumed, which the fight's mana income cannot pay for`);
    }
  }
  /* (c) actives the audit only gives a cost + N* for: Θ consistency is still checkable */
  for (const a of actives) {
    if (a.voutRaw || a.cost == null || a.nstar == null) continue;
    const TH = theta(a.cost);
    if (a.nstar > TH) {
      hardFail('RP-ACT-THETA', `${a.id} (${a.src})`, `N* <= Θ(${a.cost}) = ${TH}`,
        `N* = ${a.nstar}`, 'the audit assumes more casts per fight than M_com can fund');
    }
    res.rederived.push({ id: a.id, cost: a.cost, theta: TH, comps: null, computed: null, statedRP: a.rp, statedN: a.nstar, bestN: null });
  }
  const noVout = actives.filter((a) => !a.voutRaw && a.cost != null && a.nstar == null);
  if (noVout.length) {
    finding('UNDERSPECIFIED', `${noVout.length} active(s) give no V_out and no N*, so RP_act cannot be re-derived — `
      + 'only the band check applies to them', noVout.map((a) => a.id).join(' '));
  }
  for (const a of actives) {
    if (a.cost != null) continue;
    const auth = rosterDoc.byId.get(a.id);
    if (auth && auth.cost != null) {
      a.cost = auth.cost;
      if (!a.kind && auth.kind) a.kind = auth.kind;
      finding('ACT-COST', `${a.id}: the §6.7 audit leaves it unchanged and states no cost, so the mana cost `
        + `was taken from relic-roster-expansion.md (MP ${auth.cost})`);
      const TH2 = theta(a.cost);
      if (a.nstar != null && a.nstar > TH2) {
        hardFail('RP-ACT-THETA', `${a.id} (${a.src})`, `N* <= Θ(${a.cost}) = ${TH2}`, `N* = ${a.nstar}`);
      }
    }
  }
  const noCost = actives.filter((a) => a.cost == null);
  if (noCost.length) {
    hardFail('ACT-COST', noCost.map((a) => a.id).join(' '), 'every active states its mana cost as "[MP n]"',
      'no cost found in the effect/change text', 'RP_act is a function of cost; without it the relic is unpriceable');
  }

  /* (d) monotonicity WITHIN actives, on the same RP scale as passives (INV-4) */
  const byRar = [0, 1, 2, 3].map((r) => actives.filter((x) => x.rar === r));
  for (let r = 0; r < 3; r++) {
    const lo = byRar[r], hi = byRar[r + 1];
    if (!lo.length || !hi.length) continue;
    const mx = lo.reduce((a, b) => (b.rp > a.rp ? b : a));
    const mn = hi.reduce((a, b) => (b.rp < a.rp ? b : a));
    if (!(mx.rp < mn.rp)) {
      hardFail('INV-4', `actives: ${RAR_NAME[r]} vs ${RAR_NAME[r + 1]}`,
        `max RP_act(${RAR_NAME[r]}) < min RP_act(${RAR_NAME[r + 1]})`,
        `${mx.id} = ${round2(mx.rp)} >= ${mn.id} = ${round2(mn.rp)}`,
        'a lower-rarity active out-values a higher-rarity one, and actives repeat EVERY turn');
    }
  }
  for (let r = 0; r < 4; r++) {
    if (!byRar[r].length) {
      finding('INV-4', `no active at rarity ${RAR_NAME[r]} in the combined roster — `
        + 'monotonicity across that step is vacuous, not proven');
    }
  }
  /* (e) AC-11: act.kind must be one of the 8 implemented branches, or explicitly gated */
  const kindsM = /`kind`.{0,80}?∈\s*\*\*8 giá trị đã implement\*\*[\s\S]{0,200}?`([^`]+)`/.exec(rosterDoc.fwText)
    || /act\.kind` phải ∈ \*\*8 giá trị đã implement\*\*[\s\S]{0,200}?`([^`]+)`/.exec(rosterDoc.fwText);
  let implemented = null;
  if (kindsM) implemented = kindsM[1].split(/[·,]/).map((x) => x.trim()).filter(Boolean);
  if (!implemented || implemented.length !== 8) {
    /* fall back to reading the engine itself — more authoritative anyway */
    const body = /playerUseRelic[\s\S]*?\n}/.exec(engineSrc);
    implemented = body ? [...new Set([...body[0].matchAll(/kind===?'([a-z]+)'/g)].map((x) => x[1]))] : [];
  }
  res.implementedKinds = implemented;
  for (const a of actives) {
    if (!a.kind) continue;
    if (!implemented.includes(a.kind)) {
      const gated = rosterDoc.gated.has(a.id);
      if (gated) {
        finding('ACT-KIND-GATED', `${a.id} uses act.kind:'${a.kind}', which src/engine.js does not implement `
          + `(gated on ${rosterDoc.gated.get(a.id).join(', ')})`,
          'playerUseRelic has no else branch: an unknown kind still spends mana, still burns the turn slot, and does nothing');
      } else {
        hardFail('AC-11', `${a.id} (${a.src})`,
          `act.kind ∈ {${implemented.join(', ')}} (the branches src/engine.js implements)`,
          `act.kind:'${a.kind}' with no declared engine work`,
          'playerUseRelic has no final else — an unknown kind silently charges mana and does nothing');
      }
    }
  }
  return res;
}


/* ================================================================= *
 * CHECK 3 — FIELD LIVENESS                                           *
 *                                                                    *
 * A relic field that nothing in src/engine.js reads makes the relic   *
 * silently do nothing: correct tooltip, zero effect, no error. The    *
 * canonical trap was `shieldself:N`: documented in the src/data.js    *
 * header comment, absent from KWT, and dropped by addStatus() because *
 * its if/else-if chain has no final else. The comment no longer names *
 * it and it appears nowhere in src/, so AC-6 now guards its ABSENCE.  *
 * ================================================================= */
const NOT_A_FIELD = new Set(['f.v', 'f.k', 'f.t', 'f.p', 'u.maxHp', 'u.die', 's.mana', 'turn 1',
  'add', 'kw', 'mul', 'mfPhase', 'mload', 'ex', 'rar', 'cat']);
function fieldsFromCell(cell) {
  const out = [];
  for (const g of (String(cell).match(/`([^`]+)`/g) || [])) {
    const t = g.replace(/`/g, '').trim();
    if (NOT_A_FIELD.has(t)) continue;
    const name = t.split(':')[0].split('(')[0].trim();
    if (/^[a-z][A-Za-z]*$/.test(name)) out.push(name);
  }
  return out;
}
function engineReads(engineSrc, f) {
  if (new RegExp(`'${f}'`).test(engineSrc)) return true;          /* rhas/rsum/rmax/rcall key */
  if (new RegExp(`\\br\\.${f}\\b`).test(engineSrc)) return true;   /* direct r.modFace style */
  if (new RegExp(`\\.${f}\\b`).test(engineSrc)) return true;
  return false;
}
function checkFieldLiveness(all, src, rosterDoc, fw) {
  const engineSrc = src.engineSrc;
  const declared = new Map();     /* field -> [relic ids] */
  const note = (f, id) => { if (!declared.has(f)) declared.set(f, []); declared.get(f).push(id); };
  for (const r of all) {
    if (r.fieldRaw) for (const f of fieldsFromCell(r.fieldRaw)) note(f, r.id);
    if (r.act) note('act', r.id);
  }
  /* the §3.6 mload classification enumerates real engine fields — they must all be live too */
  const s36 = sliceSection(fw, /^### 3\.6 /, /^### 3\.7 /, '§3.6');
  const mloadFields = { 2: [], 1: [] };
  const blockM = /```\n([\s\S]*?)```/.exec(s36.lines.join('\n'));
  if (!blockM) parseDie('§3.6', 'cannot find the mload classification code block');
  let cur = null;
  for (const line of blockM[1].split('\n')) {
    const lv = /^\s*([012])\s+multiplier|^\s*([012])\s+mọi trường hợp/.exec(line);
    if (lv) { cur = Number(lv[1] !== undefined ? lv[1] : lv[2]); continue; }
    if (cur === 2 || cur === 1) {
      for (const g of (line.match(/`?\b([a-z][A-Za-z]+)\b`?/g) || [])) {
        const t = g.replace(/`/g, '');
        if (/^(dmgMult|dr|critMult|critBonus|thornsMult|burnMult|burnSlow|burnSpread|poisonTicks|plague|poisonSpread|piercePlus|hiveMind|modFace)$/.test(t)) {
          mloadFields[cur].push(t);
        }
      }
    }
  }
  mloadFields[2] = [...new Set(mloadFields[2])];
  mloadFields[1] = [...new Set(mloadFields[1])];
  if (!mloadFields[2].length || mloadFields[1].length < 8) {
    parseDie('§3.6', `mload classification parsed only ${mloadFields[2].length} global and `
      + `${mloadFields[1].length} archetype-scoped fields; §3.6 lists 3 and 11`);
  }
  for (const f of [...mloadFields[2], ...mloadFields[1]]) note(f, '§3.6');

  /* the fields the LIVE relics actually carry — this is the ground truth today */
  const liveFields = new Map();
  for (const r of src.G.RELICS) {
    for (const k of Object.keys(r)) {
      if (['id', 'n', 'rar', 'a', 'd'].includes(k)) continue;
      if (!liveFields.has(k)) liveFields.set(k, []);
      liveFields.get(k).push(r.id);
    }
  }
  const dead = [], gatedFields = [];
  for (const [f, ids] of [...declared, ...liveFields]) {
    if (engineReads(engineSrc, f)) continue;
    /* is it declared as engine work? then it is GATED, not dead */
    const owners = ids.filter((x) => x !== '§3.6');
    const anyGated = owners.some((id) => rosterDoc.gated.has(id));
    const named = new RegExp(`\\b${f}\\b`).test(rosterDoc.engText) || new RegExp(`\\b${f}\\b`).test(rosterDoc.fwEngText);
    if (anyGated || named) { gatedFields.push({ f, ids: owners }); continue; }
    dead.push({ f, ids: owners });
  }
  for (const d of dead) {
    hardFail('FIELD-DEAD', `\`${d.f}\` (declared by ${d.ids.join(', ') || 'the design docs'})`,
      'the field is read somewhere in src/engine.js',
      'no read anywhere in src/engine.js, and no engine-work item declares it',
      'the relic will ship with a correct tooltip and zero effect — no crash, no warning');
  }
  if (gatedFields.length) {
    finding('FIELD-GATED', `${gatedFields.length} field(s) are not read by src/engine.js yet but ARE declared as `
      + 'engine work, so they are pending rather than dead',
      gatedFields.map((g) => `${g.f}<-${g.ids.join('/') || 'doc'}`).join(' · '));
  }

  /* --- the shieldself trap, checked exactly as described --- */
  const kwComment = /kw:\s*([\s\S]*?)\*\//.exec(src.dataSrc.slice(0, 1200));
  if (!kwComment) parseDie('src/data.js', 'cannot find the "kw:" keyword list in the header comment');
  const kwNames = [...new Set((kwComment[1].match(/[a-z]+(?=:N)?/g) || []))]
    .filter((x) => x.length > 2 && !['kw'].includes(x));
  const addBody = /function addStatus\(([\s\S]*?)\n\}/.exec(engineSrc);
  if (!addBody) parseDie('src/engine.js', 'cannot locate function addStatus()');
  const handled = new Set([
    ...[...addBody[1].matchAll(/n===?'([a-z]+)'/g)].map((x) => x[1]),
    ...[...addBody[1].matchAll(/'([a-z]+)'/g)].map((x) => x[1]),
  ]);
  const hasFinalElse = /\}\s*else\s*\{/.test(addBody[1]);
  const dropped = kwNames.filter((k) => !handled.has(k) && !new RegExp(`hasKw\\([^,]+,\\s*'${k}'`).test(engineSrc)
    && !new RegExp(`KWT[\\s\\S]{0,900}\\b${k}\\s*:`).test(engineSrc));
  if (!hasFinalElse) {
    finding('ADDSTATUS', 'addStatus() has no final `else` branch, so any keyword outside its if/else-if chain is '
      + 'accepted and silently discarded', `chain handles: ${[...handled].filter((h) => kwNames.includes(h)).sort().join(' ')}`);
  }
  if (dropped.length) {
    finding('KW-DROPPED', `${dropped.length} keyword(s) named in the src/data.js:6 header comment are handled `
      + 'nowhere — addStatus drops them silently and KWT has no label for them', dropped.join(' '));
  }
  /* AC-6: no relic anywhere may use shieldself */
  for (const r of all) {
    const txt = `${r.effect || ''} ${r.field || ''} ${r.change || ''}`;
    if (/shieldself/.test(txt)) {
      hardFail('AC-6', r.id, 'shieldself appears in zero relics (it was never implemented)',
        'the relic references shieldself', 'addStatus has no branch for it — it is dropped silently');
    }
  }
  /* Scan BOTH sources, not just the engine: the trap used to live in the src/data.js header
     comment, and a keyword that is documented but unhandled is how it got there. */
  const ssIn = [['src/data.js', src.dataSrc], ['src/engine.js', engineSrc]]
    .filter(([, txt]) => /shieldself/.test(txt)).map(([f]) => f);
  if (ssIn.length) {
    finding('AC-6', `shieldself is mentioned in ${ssIn.join(' and ')} — verify it is not an addStatus `
      + 'branch, a KWT label or a live relic field; AC-6 requires it to stay unimplemented');
  } else {
    finding('AC-6', 'shieldself confirmed unimplemented: zero occurrences in src/data.js or src/engine.js '
      + '(the src/data.js header comment no longer lists it), absent from KWT and from addStatus, and '
      + `used by 0 of the ${all.length} relics`);
  }
  return { declared, liveFields, dead, gatedFields, dropped, hasFinalElse, mloadFields };
}

/* ================================================================= *
 * CHECK 4 — TAG INTEGRITY, against the runtime ARCH and not the doc  *
 * ================================================================= */
function checkTags(all, src, fw) {
  const ARCH = src.G.ARCH, PASSIVE = src.G.PASSIVE;
  const keys = Object.keys(ARCH);
  const res = { keys, missing: [], untagged: [] };

  /* AC-1 */
  const wantM = /`Object\.keys\(ARCH\)\.length === (\d+)`/.exec(fw) || /ARCH` lên (\d+)/.exec(fw);
  const want = wantM ? Number(wantM[1]) : 11;
  res.want = want;
  if (keys.length !== want) {
    hardFail('AC-1', 'Object.keys(ARCH).length', String(want), String(keys.length),
      `missing: ${['poison', 'burn', 'shield', 'mana', 'pierce', 'crit', 'growth', 'summon', 'aoe', 'thorns', 'exec']
        .filter((k) => !keys.includes(k)).join(', ') || '(none)'}`);
  }
  const ic = {};
  for (const [k, v] of Object.entries(ARCH)) { (ic[v.ic] = ic[v.ic] || []).push(k); }
  for (const [glyph, owners] of Object.entries(ic)) {
    if (owners.length > 1) {
      hardFail('AC-1', `ARCH icon "${glyph}"`, 'every ARCH icon is unique',
        `shared by ${owners.join(' and ')}`, 'the tracker UI cannot tell these archetypes apart');
    }
  }
  if (PASSIVE) {
    for (const [cls, pv] of Object.entries(PASSIVE)) {
      if (!pv || !pv.a) continue;
      if (ARCH[pv.a] === undefined) {
        hardFail('AC-1', `PASSIVE.${cls}.a = '${pv.a}'`, `'${pv.a}' is a key of ARCH`,
          'no such ARCH entry',
          `archScore() guards with if(sc[a]!=null), so ${cls} contributes 0 to every archetype and the `
          + 'tracker shows an em-dash for relics tagged this way');
      }
    }
  }
  /* AC-2 on the DOC roster — every one of the 94 must resolve against the runtime ARCH */
  for (const r of all) {
    if (/^__/.test(r.id)) continue;
    if (!r.a) {
      res.untagged.push(r.id);
      hardFail('AC-2', `${r.id} (${r.src})`, 'a non-empty archetype tag', 'untagged');
      continue;
    }
    if (ARCH[r.a] === undefined) {
      res.missing.push(r.id);
      hardFail('AC-2', `${r.id} tagged a:'${r.a}' (${r.src})`,
        `'${r.a}' is a key of the runtime ARCH (src/data.js)`,
        `ARCH has ${keys.length} keys and '${r.a}' is not one of them: ${keys.join(', ')}`,
        'archScore() skips it silently, so this relic feeds no archetype and the UI renders an em-dash');
    }
  }
  /* AC-2 on the LIVE roster */
  const liveUntagged = src.G.RELICS.filter((r) => !/^__/.test(r.id) && !r.a);
  const liveUnknown = src.G.RELICS.filter((r) => !/^__/.test(r.id) && r.a && ARCH[r.a] === undefined);
  if (liveUntagged.length) {
    hardFail('AC-2-LIVE', liveUntagged.map((r) => r.id).join(' '),
      '0 untagged relics in the shipped RELICS array', `${liveUntagged.length} untagged`);
  }
  if (liveUnknown.length) {
    hardFail('AC-2-LIVE', liveUnknown.map((r) => `${r.id}:'${r.a}'`).join(' '),
      'every shipped relic tag resolves against ARCH', `${liveUnknown.length} unresolved`);
  }
  res.liveUntagged = liveUntagged.map((r) => r.id);
  res.liveUnknown = liveUnknown.map((r) => `${r.id}:'${r.a}'`);
  return res;
}


/* ================================================================= *
 * CHECK 5 — kwPure Direction Law (§3.5 / AC-5)                       *
 *                                                                    *
 * doFace() sends every non-excluded keyword through addStatus() to    *
 * the FACE'S OWN TARGET. So thorns/regen/undying pushed onto a `dmg`  *
 * face buff the ENEMY, and burn/poison/weaken/vulnerable/blind pushed *
 * onto a `shield`/`heal` face debuff YOUR OWN unit. The `poison`      *
 * branch never passes kwPure at all, so injections there are inert.   *
 * The live relics are checked by EXECUTION: run every modFace over a  *
 * synthetic unit carrying one face of each type and diff the keywords.*
 * ================================================================= */
const KWPURE_ALLY = ['thorns', 'regen', 'undying', 'enrage'];
const KWPURE_FOE = ['burn', 'poison', 'weaken', 'vulnerable', 'blind', 'stun', 'freeze'];
const KWPURE = [...KWPURE_ALLY, ...KWPURE_FOE];
const INERT_TYPES = ['poison', 'mana', 'summon'];

function checkDirectionLaw(src) {
  const SLOTS = ['mouth', 'horn', 'back', 'tail', 'eyes', 'ears', 'mouth', 'horn'];
  const TYPES = ['dmg', 'shield', 'heal', 'poison', 'mana', 'buff', 'debuff', 'summon'];
  const mkUnit = () => ({
    maxHp: 20, hp: 20, cls: 'beast', side: 'p',
    die: TYPES.map((t, i) => ({ p: SLOTS[i], t, v: 5, k: [], r: 0 })),
  });
  const results = [];
  for (const r of src.G.RELICS) {
    if (typeof r.modFace !== 'function') continue;
    const before = mkUnit();
    const after = mkUnit();
    try { r.modFace(after); } catch (e) {
      hardFail('AC-5', r.id, 'modFace runs over a unit carrying one face of each type',
        `it threw: ${e.message}`, 'a relic that throws on an unusual die shape is a crash in buildUnit');
      continue;
    }
    if (!after.die || after.die.length !== before.die.length) {
      finding('AC-5', `${r.id} modFace changed the die length — skipped from the direction check`);
      continue;
    }
    for (let i = 0; i < before.die.length; i++) {
      const t = before.die[i].t;
      const added = after.die[i].k.filter((k) => !before.die[i].k.includes(k));
      for (const kw of added) {
        const n = String(kw).split(':')[0];
        results.push({ id: r.id, type: t, kw: n });
        if (!KWPURE.includes(n)) continue;                    /* outside kwPure — direction is moot */
        if (INERT_TYPES.includes(t)) {
          hardFail('AC-5', `${r.id}: injects \`${kw}\` into a \`${t}\` face`,
            `no kwPure keyword on a ${t} face`, `\`${n}\` is kwPure`,
            t === 'poison'
              ? "doFace()'s poison branch never passes kwPure — the tooltip promises it, the engine never applies it"
              : `doFace() never calls addStatus for ${t} faces — silently inert`);
          continue;
        }
        const ally = ['shield', 'heal', 'buff'].includes(t);
        if (ally && KWPURE_FOE.includes(n)) {
          hardFail('AC-5', `${r.id}: injects \`${kw}\` into a \`${t}\` face`,
            `no debuff keyword on an ally-targeted face`, `\`${n}\` lands on YOUR OWN unit`,
            'Direction Law §3.5: shield/heal/buff faces send kwPure to the ally');
        }
        if (!ally && KWPURE_ALLY.includes(n)) {
          hardFail('AC-5', `${r.id}: injects \`${kw}\` into a \`${t}\` face`,
            `no buff keyword on an enemy-targeted face`, `\`${n}\` lands on the ENEMY`,
            'Direction Law §3.5: dmg/debuff faces send kwPure to the foe — dmg+thorns damages you every swing');
        }
      }
    }
  }
  return results;
}

/* ================================================================= *
 * CHECK 6 — de-duplication (§3.7 / AC-10, AC-19) and mload (§3.6)    *
 * ================================================================= */
function checkDedupAndMload(all, src, fw, rosterDoc, mloadFields) {
  const engineSrc = src.engineSrc;
  /* which fields does the engine merge with rmax? read it from the engine, not the doc */
  const rmaxFields = [...new Set([...engineSrc.matchAll(/rmax\(\s*s\s*,\s*'([a-zA-Z]+)'/g)].map((m) => m[1]))];
  const orFields = [...new Set([...engineSrc.matchAll(/rhas\(\s*s\s*,\s*'([a-zA-Z]+)'\s*\)\s*\|\|/g)].map((m) => m[1]))];
  /* KW_EX from §3.7 */
  const s37 = sliceSection(fw, /^### 3\.7 /, /^### 3\.8 /, '§3.7');
  const kwexM = /KW_EX\s*=\s*\{([^}]*)\}/.exec(s37.lines.join('\n'));
  if (!kwexM) parseDie('§3.7', 'cannot find the KW_EX mapping');
  const KW_EX = {};
  for (const pair of kwexM[1].split(',')) {
    const m = /([a-zA-Z]+)\s*:\s*'?([a-zA-Z]+)'?/.exec(pair);
    if (m) KW_EX[m[1].trim()] = m[2] === 'null' ? null : m[2];
  }
  const capM = /RELIC_MLOAD_CAP\s*=\s*(\d)/.exec(fw);
  const CAP = capM ? Number(capM[1]) : 2;

  const withEx = all.filter((r) => Array.isArray(r.ex));
  const noEx = all.filter((r) => r.ex === null);
  if (noEx.length) {
    finding('UNDERSPECIFIED', `${noEx.length} of ${all.length} relics carry no \`mload\`/\`ex\` declaration in the `
      + '§6.7 audit tables (those columns exist only in §6.1-§6.4 and §6.7.7), so the de-duplication and '
      + 'anti-stacking checks below cover the other ' + withEx.length + ' only',
      noEx.slice(0, 8).map((r) => r.id).join(' ') + (noEx.length > 8 ? ' …' : ''));
  }
  /* AC-9: mload domain, classification, and the rar floor */
  for (const r of withEx) {
    if (![0, 1, 2].includes(r.mload)) {
      hardFail('AC-9', r.id, 'mload ∈ {0, 1, 2}', String(r.mload));
    }
    if (r.mload > CAP) {
      hardFail('AC-9', r.id, `mload <= RELIC_MLOAD_CAP (${CAP})`, String(r.mload),
        'a single relic that exceeds the cap can never be offered — it is unreachable content');
    }
    if (r.mload > 0 && r.rar < 1) {
      hardFail('AC-9', `${r.id} (${RAR_NAME[r.rar]})`, 'mload > 0 ⇒ rar >= 1', `mload ${r.mload} at COMMON`);
    }
    const fields = r.fieldRaw ? fieldsFromCell(r.fieldRaw) : [];
    const wantsTwo = fields.some((f) => mloadFields[2].includes(f) && f !== 'modFace');
    const wantsOne = fields.some((f) => mloadFields[1].includes(f));
    if (wantsTwo && r.mload !== 2) {
      hardFail('AC-9', r.id, 'mload = 2 (it carries a global multiplier: ' + fields.filter((f) => mloadFields[2].includes(f) && f !== 'modFace').join(', ') + ')', `mload ${r.mload}`);
    } else if (!wantsTwo && wantsOne && r.mload < 1) {
      hardFail('AC-9', r.id, 'mload >= 1 (it carries an archetype-scoped multiplier: ' + fields.filter((f) => mloadFields[1].includes(f)).join(', ') + ')', `mload ${r.mload}`);
    }
    /* AC-9 tail: anything merged by rmax must carry an ex token */
    const rmaxUsed = fields.filter((f) => rmaxFields.includes(f));
    if (rmaxUsed.length && !r.ex.length) {
      hardFail('AC-9', r.id, `an \`ex\` token, because it writes ${rmaxUsed.join('/')} which the engine merges with rmax()`,
        'ex: []', 'without a token a second relic on the same field is a 100% dead draw');
    }
  }
  /* AC-19(a): two relics on the same rmax field must share a token */
  const byField = new Map();
  for (const r of withEx) {
    for (const f of (r.fieldRaw ? fieldsFromCell(r.fieldRaw) : [])) {
      if (!rmaxFields.includes(f) && !orFields.includes(f)) continue;
      if (!byField.has(f)) byField.set(f, []);
      byField.get(f).push(r);
    }
  }
  for (const [f, rs] of byField) {
    for (let i = 0; i < rs.length; i++) {
      for (let j = i + 1; j < rs.length; j++) {
        const shared = rs[i].ex.filter((t) => rs[j].ex.includes(t));
        if (!shared.length) {
          hardFail('AC-19', `${rs[i].id} + ${rs[j].id} both write \`${f}\``,
            'they share at least one `ex` token so the pool never offers both',
            `ex ${JSON.stringify(rs[i].ex)} vs ${JSON.stringify(rs[j].ex)} — disjoint`,
            `the engine merges \`${f}\` with ${rmaxFields.includes(f) ? 'rmax()' : '||'}, so the second one contributes exactly 0`);
        }
      }
    }
  }
  /* AC-19(c): a relic granting a rule that a face KEYWORD also grants must carry the mapped token */
  for (const [kw, token] of Object.entries(KW_EX)) {
    if (!token) {
      finding('AC-19', `KW_EX maps keyword \`${kw}\` to null on purpose — it stacks rather than duplicating, `
        + 'so no `ex` token is required');
      continue;
    }
    const owners = withEx.filter((r) => (r.fieldRaw ? fieldsFromCell(r.fieldRaw) : []).some((f) => f.toLowerCase().includes(kw.toLowerCase()))
      || (r.effect || '').toLowerCase().includes(kw.toLowerCase()));
    for (const o of owners) {
      if (!o.ex.includes(token)) {
        hardFail('AC-19', `${o.id} grants the \`${kw}\` rule`,
          `ex includes '${token}' (KW_EX maps the \`${kw}\` face keyword to it)`,
          `ex: ${JSON.stringify(o.ex)}`,
          `a party face carrying \`${kw}\` already grants this rule; the engine merges them, so the relic is a dead draw`);
      }
    }
  }
  return { rmaxFields, orFields, KW_EX, CAP, covered: withEx.length, uncovered: noEx.length };
}

/* ================================================================= *
 * CHECK 7 — archetype coverage (§5.1 target, §6.7.8 claim / AC-4)     *
 * ================================================================= */
function checkCoverage(all, src, fw) {
  const s51 = sliceSection(fw, /^### 5\.1 /, /^### 5\.2 /, '§5.1');
  const txt = s51.lines.join('\n');
  const tm = /≥(\d)\s*COMMON\s*·\s*≥(\d)\s*RARE\s*·\s*≥(\d)\s*EPIC\s*·\s*≥(\d)\s*LEGENDARY/.exec(txt);
  if (!tm) parseDie('§5.1', 'cannot find the "≥1 COMMON · ≥2 RARE · ≥2 EPIC · ≥1 LEGENDARY" passive target');
  const MIN = [Number(tm[1]), Number(tm[2]), Number(tm[3]), Number(tm[4])];
  const rm = /max\(count\w*\)\s*\/\s*min\(count\w*\)\s*≤\s*([0-9.]+)/.exec(txt);
  const cm = /không được vượt\s*\*\*(\d+) relic\*\*/.exec(txt);
  const RATIO = rm ? Number(rm[1]) : 1.6;
  const MAXPER = cm ? Number(cm[1]) : 10;

  const archs = Object.keys(src.G.ARCH);
  const docArchs = [...new Set(all.map((r) => r.a).filter(Boolean))];
  const universe = [...new Set([...archs, ...docArchs])];
  const table = {};
  for (const a of universe) {
    const mine = all.filter((r) => r.a === a);
    table[a] = {
      passive: [0, 1, 2, 3].map((r) => mine.filter((x) => !x.act && x.rar === r).length),
      active: mine.filter((x) => x.act).length,
      total: mine.length,
    };
  }
  for (const a of universe) {
    const t = table[a];
    for (let r = 0; r < 4; r++) {
      if (t.passive[r] < MIN[r]) {
        hardFail('AC-4', `archetype ${a}`, `>= ${MIN[r]} ${RAR_NAME[r]} passive`, `${t.passive[r]}`,
          '§5.1: below this an archetype cannot be started, chosen between, or completed');
      }
    }
    if (t.active < 1) {
      hardFail('AC-4', `archetype ${a}`, '>= 1 active (Nourishment Contract clause (d))', '0 actives',
        'that archetype has no surface on which to spend Mana');
    }
    if (t.total > MAXPER) {
      hardFail('AC-4', `archetype ${a}`, `<= ${MAXPER} relics`, String(t.total));
    }
  }
  const counts = universe.map((a) => table[a].total).filter((n) => n > 0);
  const ratio = Math.max(...counts) / Math.min(...counts);
  if (ratio > RATIO + 1e-9) {
    const mx = universe.reduce((a, b) => (table[b].total > table[a].total ? b : a));
    const mn = universe.filter((a) => table[a].total > 0).reduce((a, b) => (table[b].total < table[a].total ? b : a));
    hardFail('AC-4', 'archetype count spread', `max/min <= ${RATIO}`,
      `${Math.max(...counts)} (${mx}) / ${Math.min(...counts)} (${mn}) = ${round2(ratio)}`);
  }
  /* §6.7.8 states the post-audit coverage explicitly — compare it with what we counted */
  const sec = sliceSection(fw, /^#### 6\.7\.8 /, /^## 7\./, '§6.7.8');
  const t = theTable(sec, ['archetype', 'passive', 'active']);
  let rows = 0;
  for (const row of t.rows) {
    const key = stripFmt(row.c[0]).split(/\s+/)[0].toLowerCase();
    if (key.startsWith('tổng')) continue;
    if (!table[key]) {
      hardFail('PARSE-6.7.8', `§6.7.8 row "${stripFmt(row.c[0])}"`, 'an archetype present in the roster', `no relic carries a:'${key}'`);
      continue;
    }
    rows++;
    const stated = [1, 2, 3, 4].map((i) => num(row.c[i], '§6.7.8'));
    const statedAct = num(row.c[6], '§6.7.8');
    const statedTot = num(row.c[7], '§6.7.8');
    const mineP = table[key].passive;
    if (stated.join(',') !== mineP.join(',') || statedAct !== table[key].active || statedTot !== table[key].total) {
      hardFail('COVERAGE-CLAIM', `§6.7.8 row ${key}`,
        `C/R/E/L ${stated.join('/')}, ${statedAct} active, ${statedTot} total (stated)`,
        `C/R/E/L ${mineP.join('/')}, ${table[key].active} active, ${table[key].total} total (counted from §6.1-§6.7.7)`,
        'the coverage table and the relic tables disagree; one of them is stale');
    }
  }
  if (rows !== universe.length) {
    finding('COVERAGE', `§6.7.8 tabulates ${rows} archetypes, the roster uses ${universe.length}`,
      universe.filter((a) => !t.rows.some((r) => stripFmt(r.c[0]).toLowerCase().startsWith(a))).join(' '));
  }
  return { table, MIN, RATIO, MAXPER, ratio, universe };
}

/* ================================================================= *
 * CHECK 8 — id stability + migration (§6, ui.js META.relics)         *
 * ================================================================= */
function checkIdStability(all, src, rosterDoc) {
  const docIds = new Set(all.map((r) => r.id));
  const liveIds = src.G.RELICS.map((r) => r.id).filter((id) => !/^__/.test(id));
  const lost = liveIds.filter((id) => !docIds.has(id));
  for (const id of lost) {
    hardFail('ID-STABLE', id, 'every shipped relic id survives the retune (§6: "ID GIỮ NGUYÊN")',
      'absent from the combined 94-relic roster',
      'META.relics persists Collection progress across saves, and src/client.html gates a meta reward on '
      + 'META.relics.length >= RELICS.length — a vanished id becomes an orphan that can never be counted');
  }
  /* every id the roster doc authors must appear in the framework audit, and vice versa */
  const auditIds = new Set(all.filter((r) => r.origin === 'expansion').map((r) => r.id));
  const rosterIds = [...rosterDoc.byId.keys()];
  const notAudited = rosterIds.filter((id) => !auditIds.has(id) && !docIds.has(id));
  const notAuthored = [...auditIds].filter((id) => !rosterDoc.byId.has(id));
  for (const id of notAudited) {
    hardFail('DOC-SYNC', id, 'every relic authored in relic-roster-expansion.md is audited in §6.7',
      'present in the roster doc, absent from §6.7',
      'this relic has no RP verdict, so INV-1 says nothing about it');
  }
  for (const id of notAuthored) {
    hardFail('DOC-SYNC', id, 'every relic audited in §6.7 is authored in relic-roster-expansion.md',
      'audited in §6.7, absent from the roster doc',
      'the audit prices a relic the roster no longer defines');
  }
  /* roster-declared rarity vs the audit "rar trước" — this is how a mid-edit roster shows up */
  const drift = [];
  for (const r of all) {
    if (r.origin !== 'expansion') continue;
    const auth = rosterDoc.byId.get(r.id);
    if (!auth) continue;
    if (auth.rar === r.rar && r.rar !== r.rarBefore) drift.push({ id: r.id, state: 'retuned', rar: auth.rar });
    else if (auth.rar === r.rarBefore && r.rar !== r.rarBefore) drift.push({ id: r.id, state: 'pre-retune', rar: auth.rar });
    else if (auth.rar !== r.rar && auth.rar !== r.rarBefore) {
      hardFail('DOC-SYNC', r.id, `rarity ${RAR_NAME[r.rarBefore]} (pre-audit) or ${RAR_NAME[r.rar]} (post-audit)`,
        `the roster doc says ${RAR_NAME[auth.rar]}, which is neither`,
        'the roster has drifted away from both sides of the §6.7 audit');
    }
  }
  const retuned = drift.filter((d) => d.state === 'retuned');
  const pending = drift.filter((d) => d.state === 'pre-retune');
  return { lost, notAudited, notAuthored, retuned, pending, liveIds };
}

/* ================================================================= *
 * CHECK 9 — AC-21, shop price monotonicity                           *
 * ================================================================= */
/* The defect AC-21 was written against was `cost:[45,75,120,180][r.rar]||60`: a rar-4 relic
   missed the array and fell back to 60, CHEAPER than a RARE at 75, so the Mythic tier could
   not exist in the shop. That is fixed — src/engine.js now reads `RELIC_SHOP_COST[r.rar]` from
   a named table in src/data.js — so matching on the old expression only proves the old text is
   gone. Check the PROPERTY instead, which survives the next refactor:

     1. the price table exists and every entry is a positive finite number;
     2. it is STRICTLY INCREASING over its FULL length, not just over the shipped rarities —
        a Mythic price cheaper than a Legendary one is the same defect one tier up;
     3. it covers every declared rarity, so no rarity can miss the table;
     4. the engine actually prices relics from it;
     5. the relic price carries NO fallback default — a fallback is what let (2) be violated
        without anyone noticing.

   (3)+(5) together are strictly stronger than the old fallback check: the old one only fired
   when a `||` literal was present, this one fires whenever a rarity has no explicit price. */
function checkShop(src) {
  const tiers = src.G.RELIC_SHOP_COST;
  const rarNames = src.G.RARITY;
  if (!Array.isArray(tiers) || !tiers.length) {
    hardFail('AC-21', 'RELIC_SHOP_COST in src/data.js',
      'a named array of relic shop prices, one per rarity',
      tiers === undefined ? 'not declared' : JSON.stringify(tiers),
      'without a named table the price is an inline literal again, which is how the '
      + '`[45,75,120,180][r.rar]||60` Mythic bug shipped');
    return null;
  }
  const maxRar = Math.max(...src.G.RELICS.map((r) => r.rar));
  /* (1) every entry is a real price */
  for (let i = 0; i < tiers.length; i++) {
    if (!Number.isFinite(tiers[i]) || tiers[i] <= 0) {
      hardFail('AC-21', `RELIC_SHOP_COST[${i}]`, 'a positive finite price', String(tiers[i]));
    }
  }
  /* (2) strictly increasing over the WHOLE table, including rarities nothing ships yet */
  for (let i = 1; i < tiers.length; i++) {
    if (!(tiers[i - 1] < tiers[i])) {
      hardFail('AC-21', `RELIC_SHOP_COST[${i - 1}] -> [${i}]`
        + ` (${rarNames && rarNames[i - 1] ? rarNames[i - 1] : 'rar ' + (i - 1)} -> `
        + `${rarNames && rarNames[i] ? rarNames[i] : 'rar ' + i})`,
        'strictly increasing with rarity',
        `${tiers[i - 1]} -> ${tiers[i]}`,
        'a higher rarity that is not more expensive makes the rarity colour a lie at the till — '
        + 'the same defect class as INV-1, priced in shards instead of RP');
    }
  }
  /* (3) every declared rarity is priced — this is the fallback bug stated positively */
  if (Array.isArray(rarNames) && tiers.length !== rarNames.length) {
    hardFail('AC-21', 'RELIC_SHOP_COST vs RARITY',
      `one price per declared rarity (${rarNames.length}: ${rarNames.join(', ')})`,
      `${tiers.length} price(s) [${tiers.join(', ')}]`,
      tiers.length < rarNames.length
        ? `${rarNames.slice(tiers.length).join(', ')} would index past the table (today max shipped `
          + `rar = ${maxRar}, so it need not fire yet — that is exactly how the Mythic bug hid)`
        : 'there are more prices than rarities — one of the two lists was edited alone');
  }
  /* (4)+(5) the engine prices relics from the table, with no fallback default */
  const gm = /function genShop\s*\([^)]*\)\s*\{([\s\S]*?)\n\}/.exec(src.engineSrc);
  let priceLines = null;
  if (!gm) {
    hardFail('AC-21', 'genShop() in src/engine.js', 'a locatable genShop function body',
      'not found', 'the shop was restructured — re-point this check at the new relic pricing site '
      + 'rather than deleting it');
  } else {
    priceLines = gm[1].split('\n').filter((l) => /RELIC_SHOP_COST/.test(l));
    if (!priceLines.length) {
      hardFail('AC-21', 'genShop() relic price', 'priced from RELIC_SHOP_COST',
        'genShop never reads RELIC_SHOP_COST',
        'the named table is dead and the shop prices relics some other way — an inline literal '
        + 'is unreviewable and is the original defect');
    }
    for (const l of priceLines) {
      if (/\|\|/.test(l)) {
        hardFail('AC-21', `genShop() relic price line \`${l.trim()}\``,
          'no fallback branch — every rarity has an explicit price in RELIC_SHOP_COST',
          'the price expression carries a `||` default',
          'a default silently re-prices any rarity missing from the table, which is how a rar-4 '
          + 'relic came out cheaper than a RARE');
      }
    }
  }
  return { tiers, rarNames, maxRar, priceLines };
}

/* ================================================================= *
 * ENTRY POINT                                                        *
 * A parse failure is exit 2 and says so loudly: this tool refuses to *
 * report a count over data it could not fully read.                  *
 * ================================================================= */
let __code;
try { __code = main(); } catch (e) {
  if (e instanceof ParseError) {
    console.error('\nt_relic: FATAL — could not read a design input.\n');
    console.error('  ' + e.message);
    console.error('\n  A design doc was restructured and a parser in tools/t_relic.mjs needs updating.');
    console.error('  That is intentional: the gate refuses to report an invariant count over data it');
    console.error('  only partially parsed, because a silently skipped row reads as a PASS.\n');
  } else {
    console.error('\nt_relic: FATAL — unexpected error\n');
    console.error(e && e.stack ? e.stack : String(e));
  }
  __code = 2;
}
process.exit(__code);
