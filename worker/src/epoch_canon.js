// Canon, hash chain and seed formula for server-rolled dice (ADR server-authoritative-rng §4.1).
//
// STATUS: provisional. Lane A owns the canonical byte format and will land
// godot/tests/data/epoch_golden.json; when it does, copy it to worker/test/epoch_golden.json and
// make test/epoch_golden.test.mjs pass against it. Every byte-level choice that the ADR leaves
// open is isolated in the functions marked [GOLDEN] below so that reconciling is a local edit.
//
// All functions are pure and async only because crypto.subtle is.

const enc = new TextEncoder();

export const DOMAIN_COMMIT = 'axiedice/commit/v1';
export const DOMAIN_LOG = 'axiedice/log/v1';
export const DOMAIN_ROWTYPE = 'axiedice/rowtype/v1';

const IDENT = /^[a-z0-9_]+$/;
// Values also allow '-' and '.' because rules_version is "godot-2026-09-21-a". [GOLDEN: ADR says
// [a-z0-9_] only; ask lane A whether rules_version is mapped or the charset widens.]
const VALUE_STR = /^[a-z0-9_.-]+$/;

/** One canon value: integer -> decimal, array -> "a,b,c" (order kept), string -> [a-z0-9_]+. */
export function canonValue(v) {
  if (Array.isArray(v)) return v.map(canonValue).join(',');
  if (typeof v === 'number') {
    if (!Number.isSafeInteger(v)) throw new Error('canon: non-integer number');
    return String(v); // String(-0) is "0"; no "+", no leading zeros
  }
  if (typeof v === 'string') {
    if (!VALUE_STR.test(v)) throw new Error('canon: string outside allowed charset');
    return v;
  }
  if (typeof v === 'boolean') return v ? '1' : '0';
  throw new Error('canon: unsupported value');
}

const byKey = (a, b) => (a < b ? -1 : a > b ? 1 : 0);

/** `k=v\n` lines sorted by key. Nested plain objects flatten to `outer.inner`. [GOLDEN] */
export function canonKV(obj, prefix = '') {
  const lines = [];
  for (const k of Object.keys(obj).sort(byKey)) {
    if (!IDENT.test(k)) throw new Error('canon: key outside [a-z0-9_]');
    const v = obj[k];
    if (v && typeof v === 'object' && !Array.isArray(v)) lines.push(canonKV(v, `${prefix}${k}.`));
    else lines.push(`${prefix}${k}=${canonValue(v)}\n`);
  }
  return lines.join('');
}

/** One action per line: `fn|k1=v1|k2=v2\n`, params sorted by key, actions in order. [GOLDEN] */
export function canonDelta(actions) {
  let out = '';
  for (const a of actions) {
    if (!a || typeof a.fn !== 'string' || !IDENT.test(a.fn)) throw new Error('canon: bad action fn');
    const args = a.args || {};
    let line = a.fn;
    for (const k of Object.keys(args).sort(byKey)) {
      if (!IDENT.test(k)) throw new Error('canon: key outside [a-z0-9_]');
      line += `|${k}=${canonValue(args[k])}`;
    }
    out += `${line}\n`;
  }
  return out;
}

const hex = (buf) => Array.from(new Uint8Array(buf), (b) => b.toString(16).padStart(2, '0')).join('');
const fromHex = (s) => Uint8Array.from(s.match(/../g) || [], (h) => parseInt(h, 16));
const concat = (...parts) => {
  const arrs = parts.map((p) => (typeof p === 'string' ? enc.encode(p) : p));
  const out = new Uint8Array(arrs.reduce((n, a) => n + a.length, 0));
  let o = 0;
  for (const a of arrs) { out.set(a, o); o += a.length; }
  return out;
};
const sha256 = async (bytes) => new Uint8Array(await crypto.subtle.digest('SHA-256', bytes));

/** h_0 = SHA256("axiedice/log/v1" | run_id), lowercase hex. [GOLDEN: "|" is a literal 0x7c byte] */
export async function chainStart(runId) {
  return hex(await sha256(concat(DOMAIN_LOG, '|', runId)));
}

/** h_n = SHA256("axiedice/log/v1" | h_{n-1} | canon(log_delta)). h is hex text, not raw bytes. [GOLDEN] */
export async function chainNext(prevHex, actions) {
  return hex(await sha256(concat(DOMAIN_LOG, '|', prevHex, '|', canonDelta(actions))));
}

/** commit = SHA256("axiedice/commit/v1" | run_id | S_run), hex. S_run is raw bytes. [GOLDEN] */
export async function commitOf(runId, sRun) {
  return hex(await sha256(concat(DOMAIN_COMMIT, '|', runId, '|', sRun)));
}

async function hmac(keyBytes, msgBytes) {
  const key = await crypto.subtle.importKey('raw', keyBytes, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  return new Uint8Array(await crypto.subtle.sign('HMAC', key, msgBytes));
}

/**
 * seed = first 4 bytes (big-endian, unsigned) of HMAC-SHA256(S_run, canon{...}).
 * `args.uids` is deliberately NOT part of the seed (ADR 4.4): it is committed in the ledger only.
 * fields: {run_id, seq, kind, args, h, log_len, rules_version, attempt, client_nonce}
 */
export async function epochSeed(sRun, f) {
  const args = { ...(f.args || {}) };
  delete args.uids;
  const msg = canonKV({
    run_id: f.run_id, seq: f.seq, kind: f.kind, args, h: f.h, log_len: f.log_len,
    rules_version: f.rules_version, attempt: f.attempt ?? 0, client_nonce: f.client_nonce,
  });
  const mac = await hmac(sRun, enc.encode(msg));
  return ((mac[0] << 24) | (mac[1] << 16) | (mac[2] << 8) | mac[3]) >>> 0;
}

/** Node type of one map row: HMAC with its own domain, so it never leaks through epoch seeds. */
export async function rowTypeSeed(sRun, runId, row) {
  const mac = await hmac(sRun, concat(DOMAIN_ROWTYPE, '|', runId, '|', String(row)));
  return ((mac[0] << 24) | (mac[1] << 16) | (mac[2] << 8) | mac[3]) >>> 0;
}

export const _bytes = { hex, fromHex, concat };
