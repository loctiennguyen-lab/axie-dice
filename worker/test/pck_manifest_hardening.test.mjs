// Security debt from the 23/10 deploy review (production/release/deploy-2026-10-23.md): manifest keys stay under
// pck/, md5 is mandatory, a>b ranges are ignored (RFC 7233: 200, not 416), If-Range must equal our strong ETag.
import test from 'node:test';
import assert from 'node:assert/strict';
import worker from '../src/index.js';

const MD5 = 'fedcba9876543210fedcba9876543210';
const SIZES = [10, 7, 8];
const TOTAL = 25;
const full = new Uint8Array(TOTAL).map((_, i) => (i * 11 + 5) & 255);
function r2(manifest, calls = []) {
  const objs = new Map();
  let off = 0;
  SIZES.forEach((n, i) => { objs.set(`pck/index.pck.00${i}`, full.slice(off, off + n)); off += n; });
  objs.set('secret.txt', new TextEncoder().encode('nope'));
  objs.set('index.pck.parts.json', new TextEncoder().encode(JSON.stringify(manifest)));
  return {
    async get(key, opts) {
      calls.push(key);
      const b = objs.get(key);
      if (!b) return null;
      const out = opts?.range ? b.slice(opts.range.offset, opts.range.offset + opts.range.length) : b;
      return { body: new Blob([out]).stream(), size: b.length, httpEtag: '"x"', writeHttpMetadata() {}, text: async () => new TextDecoder().decode(b) };
    },
    async head() { return null; },
  };
}
const good = () => ({ total: TOTAL, md5: MD5, parts: SIZES.map((n, i) => ({ key: `pck/index.pck.00${i}`, size: n })) });
const get = (manifest, headers = {}, calls) => worker.fetch(new Request('https://x.test/index.pck', { headers }), { GAME: r2(manifest, calls) });

test('part keys that escape pck/ are refused and nothing is read', async () => {
  for (const key of ['secret.txt', 'pck2/x', '/pck/x', 'pck/../secret.txt', 'pck/./x', 'pck//x', 'pck/', 'PCK/x', 'pck\\x']) {
    const m = good(); m.parts[1].key = key;
    const calls = [];
    const res = await get(m, {}, calls);
    assert.equal(res.status, 500, key);
    assert.equal(calls.filter((k) => k !== 'index.pck.parts.json').length, 0, key);
  }
});

test('md5 must be 32 lowercase hex; every other shape is a 500', async () => {
  for (const md5 of [undefined, null, '', 'A'.repeat(32), 'g'.repeat(32), MD5 + '0', MD5.slice(1), 5, [MD5]]) {
    const m = good(); if (md5 === undefined) delete m.md5; else m.md5 = md5;
    const res = await get(m);
    assert.equal(res.status, 500, String(md5));
    assert.match(await res.text(), /md5/);
  }
});

test('Range with first > last is ignored: 200 whole file, never 416 (also when past the end)', async () => {
  for (const h of ['bytes=9-3', 'bytes=24-0', 'bytes=40-30']) {
    const res = await get(good(), { range: h });
    assert.equal(res.status, 200, h);
    assert.equal(res.headers.get('content-range'), null);
    assert.deepEqual(new Uint8Array(await res.arrayBuffer()), full);
  }
  assert.equal((await get(good(), { range: 'bytes=25-' })).status, 416);   // a>b is not the same as past the end
});

test('If-Range equal to the ETag keeps the range (206)', async () => {
  const res = await get(good(), { range: 'bytes=8-12', 'if-range': `"${MD5}"` });
  assert.equal(res.status, 206);
  assert.equal(res.headers.get('content-range'), `bytes 8-12/${TOTAL}`);
  assert.deepEqual(new Uint8Array(await res.arrayBuffer()), full.slice(8, 13));
});

test('If-Range with a stale etag, a weak etag or a date drops the range: 200 whole file', async () => {
  for (const v of ['"old"', `W/"${MD5}"`, 'Wed, 21 Oct 2026 07:28:00 GMT', '', MD5]) {
    const res = await get(good(), { range: 'bytes=8-12', 'if-range': v });
    assert.equal(res.status, 200, v);
    assert.equal(res.headers.get('content-length'), String(TOTAL));
    assert.deepEqual(new Uint8Array(await res.arrayBuffer()), full, v);
  }
  // stale If-Range also beats an unsatisfiable range: the client gets the file, not a 416
  assert.equal((await get(good(), { range: 'bytes=99-', 'if-range': '"old"' })).status, 200);
});

test('If-Range without a Range header changes nothing', async () => {
  assert.equal((await get(good(), { 'if-range': '"old"' })).status, 200);
});
