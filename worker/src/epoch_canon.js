// Canon, hash chain and seed formula for server-rolled dice (ADR server-authoritative-rng §4.1).
// Byte-exact against godot/tests/data/epoch_golden.json (lane A); test/epoch_golden.test.mjs runs
// that file. The Godot side (EpochCanon) must produce the same bytes, so change nothing here
// without changing the golden file in lane A first.
//
// "|" in the ADR means plain byte concatenation, with no separator, except inside log lines and the
// rowtype message where it is a literal 0x7C. All functions are pure and async only because
// crypto.subtle is.

const enc = new TextEncoder();

export const DOMAIN_COMMIT = 'axiedice/commit/v1';
export const DOMAIN_LOG = 'axiedice/log/v1';
export const DOMAIN_ROWTYPE = 'axiedice/rowtype/v1';

const IDENT = /^[a-z0-9_]+$/;
const FN = /^[a-z_]+$/;
const VALUE_STR = /^[a-z0-9_-]+$/; // '-' because rules_version contains it; '.' is not allowed
export const MAX_PARAMS = 10;

/** True if v is a legal canon scalar: safe integer or non-empty [a-z0-9_-] string. */
export const isCanonScalar = (v) =>
  (typeof v === 'number' && Number.isSafeInteger(v)) || (typeof v === 'string' && VALUE_STR.test(v));

/** One canon value: integer, string, or flat array of those (order kept, empty array = empty). */
export function canonValue(v) {
  if (Array.isArray(v)) {
    if (!v.every(isCanonScalar)) throw new Error('canon: bad array element');
    return v.map(String).join(',');
  }
  if (!isCanonScalar(v)) throw new Error('canon: unsupported value');
  return String(v);
}

// Keys sort as bytes: JS default sort on ASCII strings is by UTF-16 code unit, identical for ASCII.
const byKey = (a, b) => (a < b ? -1 : a > b ? 1 : 0);

/** `key=value\n` lines sorted by full key; nested objects flatten to `parent.child`. */
export function canonKV(obj, prefix = '') {
  const lines = [];
  const walk = (o, pre) => {
    for (const k of Object.keys(o)) {
      if (!IDENT.test(k)) throw new Error('canon: key outside [a-z0-9_]');
      const v = o[k];
      if (v && typeof v === 'object' && !Array.isArray(v)) walk(v, `${pre}${k}.`);
      else lines.push([`${pre}${k}`, canonValue(v)]);
    }
  };
  walk(obj, prefix);
  return lines.sort((a, b) => byKey(a[0], b[0])).map(([k, v]) => `${k}=${v}\n`).join('');
}

/** `fn|p0=v0|p1=v1\n` per action (args are positional, max 10), in the order they happened. */
export function canonDelta(actions) {
  let out = '';
  for (const a of actions) {
    if (!a || typeof a.fn !== 'string' || !FN.test(a.fn)) throw new Error('canon: bad action fn');
    const args = a.args ?? [];
    if (!Array.isArray(args) || args.length > MAX_PARAMS) throw new Error('canon: bad action args');
    out += a.fn + args.map((v, i) => `|p${i}=${canonValue(v)}`).join('') + '\n';
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

/** h_0 = SHA256("axiedice/log/v1" || run_id), lowercase hex. */
export async function chainStart(runId) {
  return hex(await sha256(concat(DOMAIN_LOG, runId)));
}

/** h_n = SHA256("axiedice/log/v1" || h_{n-1} (32 raw bytes) || canon_delta). h travels as hex. */
export async function chainNext(prevHex, actions) {
  return hex(await sha256(concat(DOMAIN_LOG, fromHex(prevHex), canonDelta(actions))));
}

/** commit = SHA256("axiedice/commit/v1" || run_id || S_run), hex. S_run is 32 raw bytes. */
export async function commitOf(runId, sRun) {
  return hex(await sha256(concat(DOMAIN_COMMIT, runId, sRun)));
}

async function hmac(keyBytes, msgBytes) {
  const key = await crypto.subtle.importKey('raw', keyBytes, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  return new Uint8Array(await crypto.subtle.sign('HMAC', key, msgBytes));
}
const u32 = (mac) => ((mac[0] << 24) | (mac[1] << 16) | (mac[2] << 8) | mac[3]) >>> 0;

/**
 * seed = first 4 bytes (big-endian, unsigned) of HMAC-SHA256(S_run, canon_request).
 * `args.uids` is dropped from the canon (ADR 4.4): it is a ledger commitment, not seed input.
 * fields: {run_id, seq, kind, args, h, log_len, rules_version, attempt, client_nonce}
 */
export async function epochSeed(sRun, f) {
  const args = { ...(f.args || {}) };
  delete args.uids;
  const msg = canonKV({
    run_id: f.run_id, seq: f.seq, kind: f.kind, args, h: f.h, log_len: f.log_len,
    rules_version: f.rules_version, attempt: f.attempt ?? 0, client_nonce: f.client_nonce,
  });
  return u32(await hmac(sRun, enc.encode(msg)));
}

/** Full 32-byte digest for a map row: HMAC(S_run, domain 0x7C run_id 0x7C row as 4-byte BE). */
export async function rowTypeDigest(sRun, runId, row) {
  const r = new Uint8Array(4);
  new DataView(r.buffer).setUint32(0, row, false);
  return hex(await hmac(sRun, concat(DOMAIN_ROWTYPE, '|', runId, '|', r)));
}
/** 32-bit view of the digest, for callers that only need a number. */
export async function rowTypeSeed(sRun, runId, row) {
  return parseInt((await rowTypeDigest(sRun, runId, row)).slice(0, 8), 16) >>> 0;
}

/** Row of a node id "r<row>_c<col>" (row >= 1, col >= 0, no leading zeros), or -1. */
export function nodeRow(id) {
  const m = /^r([1-9][0-9]*)_c(0|[1-9][0-9]*)$/.exec(typeof id === 'string' ? id : '');
  return m ? Number(m[1]) : -1;
}

export const _bytes = { hex, fromHex, concat };
