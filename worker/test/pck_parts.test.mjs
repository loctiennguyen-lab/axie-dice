import test from 'node:test';
import assert from 'node:assert/strict';
import worker from '../src/index.js';

// Fake R2: Map of key -> Uint8Array. get() supports {range:{offset,length}}.
function fakeR2(objs, calls = []) {
  return {
    async get(key, opts) {
      calls.push({ key, range: opts?.range });
      const b = objs.get(key);
      if (!b) return null;
      let out = b;
      if (opts?.range && opts.range.offset !== undefined) out = b.slice(opts.range.offset, opts.range.offset + opts.range.length);
      return {
        body: new Blob([out]).stream(),
        size: b.length,
        httpEtag: '"old"',
        range: opts?.range,
        writeHttpMetadata() {},
        text: async () => new TextDecoder().decode(b),
      };
    },
    async head(key) { return objs.has(key) ? { httpEtag: '"old"' } : null; },
  };
}

const SIZES = [10, 7, 5, 3]; // total 25
const TOTAL = 25;
const full = new Uint8Array(TOTAL).map((_, i) => (i * 7 + 3) & 255);
function build({ manifest } = {}) {
  const objs = new Map();
  let off = 0;
  const parts = SIZES.map((n, i) => {
    const key = `pck/index.pck.00${i}`;
    objs.set(key, full.slice(off, off + n));
    off += n;
    return { key, size: n };
  });
  const m = manifest !== undefined ? manifest : JSON.stringify({ total: TOTAL, md5: 'abc', parts });
  if (m !== null) objs.set('index.pck.parts.json', new TextEncoder().encode(m));
  objs.set('index.pck', new Uint8Array([1, 2, 3]));
  return objs;
}
const req = (headers = {}, method = 'GET') => new Request('https://x.test/index.pck', { method, headers });
const bytes = async (res) => new Uint8Array(await res.arrayBuffer());

test('no range: whole file, content-length = total', async () => {
  const res = await worker.fetch(req(), { GAME: fakeR2(build()) });
  assert.equal(res.status, 200);
  assert.equal(res.headers.get('content-length'), String(TOTAL));
  assert.equal(res.headers.get('content-type'), 'application/octet-stream');
  assert.equal(res.headers.get('cache-control'), 'public, max-age=0, must-revalidate');
  assert.deepEqual(await bytes(res), full);
});

for (const [h, a, b] of [
  ['bytes=0-3', 0, 3],
  ['bytes=8-12', 8, 12],     // crosses part 0/1
  ['bytes=9-9', 9, 9],
  ['bytes=10-10', 10, 10],
  ['bytes=5-21', 5, 21],     // spans 3 parts
  ['bytes=17-', 17, 24],
  ['bytes=-6', 19, 24],
  ['bytes=20-999', 20, 24],  // clamped
  ['bytes=24-24', 24, 24],   // last byte
]) {
  test(`range ${h}`, async () => {
    const calls = [];
    const res = await worker.fetch(req({ range: h }), { GAME: fakeR2(build(), calls) });
    assert.equal(res.status, 206);
    assert.equal(res.headers.get('content-range'), `bytes ${a}-${b}/${TOTAL}`);
    assert.equal(res.headers.get('content-length'), String(b - a + 1));
    assert.deepEqual(await bytes(res), full.slice(a, b + 1));
    // only overlapping parts are read
    const partReads = calls.filter((c) => c.key.startsWith('pck/')).length;
    assert.ok(partReads <= SIZES.length);
  });
}

test('range inside one part reads only that part', async () => {
  const calls = [];
  const res = await worker.fetch(req({ range: 'bytes=11-13' }), { GAME: fakeR2(build(), calls) });
  await bytes(res);
  assert.deepEqual(calls.filter((c) => c.key.startsWith('pck/')).map((c) => c.key), ['pck/index.pck.001']);
});

test('range past end -> 416', async () => {
  const res = await worker.fetch(req({ range: 'bytes=25-30' }), { GAME: fakeR2(build()) });
  assert.equal(res.status, 416);
  assert.equal(res.headers.get('content-range'), `bytes */${TOTAL}`);
});

test('HEAD: headers, no body, no part reads', async () => {
  const calls = [];
  const res = await worker.fetch(req({}, 'HEAD'), { GAME: fakeR2(build(), calls) });
  assert.equal(res.status, 200);
  assert.equal(res.headers.get('content-length'), String(TOTAL));
  assert.equal((await bytes(res)).length, 0);
  assert.equal(calls.filter((c) => c.key.startsWith('pck/')).length, 0);
});

test('If-None-Match with manifest md5 -> 304', async () => {
  const res = await worker.fetch(req({ 'if-none-match': '"abc"' }), { GAME: fakeR2(build()) });
  assert.equal(res.status, 304);
});

test('no manifest -> old single-object path', async () => {
  const res = await worker.fetch(req(), { GAME: fakeR2(build({ manifest: null })) });
  assert.equal(res.status, 200);
  assert.deepEqual(await bytes(res), new Uint8Array([1, 2, 3]));
});

test('corrupt manifest -> 500 with reason', async () => {
  for (const m of ['not json', '{"total": 25, "parts": []}', JSON.stringify({ total: 99, parts: [{ key: 'a', size: 5 }] })]) {
    const res = await worker.fetch(req(), { GAME: fakeR2(build({ manifest: m })) });
    assert.equal(res.status, 500);
    assert.match(await res.text(), /index\.pck manifest invalid/);
  }
});

test('missing part object -> stream errors (no silent truncation)', async () => {
  const objs = build();
  objs.delete('pck/index.pck.002');
  const res = await worker.fetch(req(), { GAME: fakeR2(objs) });
  await assert.rejects(() => res.arrayBuffer());
});
