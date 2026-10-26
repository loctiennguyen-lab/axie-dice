// /download page, /download/<file> stream and the path guard, against a fake R2 (no network, no wrangler).
import test from 'node:test';
import assert from 'node:assert/strict';
import worker from '../src/index.js';
import { downloadKeyFor, isDownloadPath } from '../src/downloads.js';

// Fake R2 bucket: Map key -> Uint8Array. get/head mirror the parts of the R2 binding the route uses.
function fakeR2(objs, calls = []) {
  return {
    async get(key, opts) {
      calls.push({ op: 'get', key });
      const b = objs.get(key);
      if (!b) return null;
      return {
        body: new Blob([b]).stream(),
        size: b.length,
        httpEtag: '"etag-' + key + '"',
        writeHttpMetadata() {},
        text: async () => new TextDecoder().decode(b),
      };
    },
    async head(key) {
      calls.push({ op: 'head', key });
      const b = objs.get(key);
      return b ? { size: b.length, httpEtag: '"etag-' + key + '"' } : null;
    },
  };
}

const ZIP = new Uint8Array([80, 75, 3, 4, 9, 9, 9]);
const SHA_M = 'a'.repeat(64);
const SHA_W = 'b'.repeat(64);
const MAC = 'AxieDice-0.1.0-L1-b1639-5ecc08f-macos.zip';
const WIN = 'AxieDice-0.1.0-L1-b1639-5ecc08f-windows.zip';

function manifest(over = {}) {
  return {
    version: '0.1.0', build: 1639, commit: '5ecc08f', rules_version: 'godot-2026-10-26-t',
    published_at: '2026-10-26T10:00:00+07:00',
    platforms: {
      macos: { file: MAC, size: ZIP.length, sha256: SHA_M },
      windows: { file: WIN, size: ZIP.length, sha256: SHA_W },
    },
    ...over,
  };
}
function bucket(m = manifest(), extra = {}) {
  const objs = new Map();
  if (m !== null) objs.set('downloads/latest.json', new TextEncoder().encode(typeof m === 'string' ? m : JSON.stringify(m)));
  objs.set('downloads/' + MAC, ZIP);
  objs.set('downloads/' + WIN, ZIP);
  for (const [k, v] of Object.entries(extra)) objs.set(k, v);
  return objs;
}
const get = (path, env, method = 'GET') => worker.fetch(new Request('https://axiedice.fun' + path, { method }), env, { waitUntil() {} });
const text = (res) => res.text();

test('isDownloadPath matches only /download and /download/...', () => {
  assert.equal(isDownloadPath('/download'), true);
  assert.equal(isDownloadPath('/download/'), true);
  assert.equal(isDownloadPath('/download/x.zip'), true);
  assert.equal(isDownloadPath('/downloads'), false);
  assert.equal(isDownloadPath('/download.html'), false);
  assert.equal(isDownloadPath('/index.pck'), false);
});

test('downloadKeyFor maps names under downloads/ and refuses traversal', () => {
  assert.equal(downloadKeyFor('/download/' + MAC), 'downloads/' + MAC);
  assert.equal(downloadKeyFor('/download/old/' + MAC), 'downloads/old/' + MAC);
  for (const bad of [
    '/download/',
    '/download/..%2Findex.pck',          // decoded ../index.pck
    '/download/%2e%2e%2findex.pck',
    '/download/old/../../index.pck',
    '/download/./x.zip',
    '/download/a//b.zip',
    '/download/x.zip%5C..%5Cy.zip',      // backslash
    '/download/x.zip%00',                // NUL
    '/download/%2Fetc.zip',              // leading slash
    '/download/index.html',              // wrong extension for a download
    '/download/latest.txt.html',
    '/download/noext',
    '/download/%E0%A4%A',                // bad percent encoding
  ]) {
    assert.equal(downloadKeyFor(bad), null, bad);
  }
});

test('GET /download renders the page with both links, size and sha256', async () => {
  const res = await get('/download', { GAME: fakeR2(bucket()) });
  assert.equal(res.status, 200);
  assert.match(res.headers.get('content-type'), /text\/html/);
  const html = await text(res);
  assert.match(html, new RegExp(`href="/download/${MAC}"`));
  assert.match(html, new RegExp(`href="/download/${WIN}"`));
  assert.ok(html.includes(SHA_M) && html.includes(SHA_W));
  assert.ok(html.includes('0.1.0') && html.includes('godot-2026-10-26-t'));
});

test('GET /download/ (trailing slash) serves the same page', async () => {
  const res = await get('/download/', { GAME: fakeR2(bucket()) });
  assert.equal(res.status, 200);
});

test('HEAD /download returns headers only', async () => {
  const res = await get('/download', { GAME: fakeR2(bucket()) }, 'HEAD');
  assert.equal(res.status, 200);
  assert.equal(await res.text(), '');
});

test('no manifest -> 503 with a plain message', async () => {
  const res = await get('/download', { GAME: fakeR2(bucket(null)) });
  assert.equal(res.status, 503);
});

for (const [label, bad] of [
  ['not JSON', 'nope{'],
  ['missing rules_version', manifest({ rules_version: undefined })],
  ['bad sha256', manifest({ platforms: { macos: { file: MAC, size: 7, sha256: 'xyz' }, windows: { file: WIN, size: 7, sha256: SHA_W } } })],
  ['file escapes downloads/', manifest({ platforms: { macos: { file: '../index.pck', size: 7, sha256: SHA_M }, windows: { file: WIN, size: 7, sha256: SHA_W } } })],
  ['missing windows', manifest({ platforms: { macos: { file: MAC, size: 7, sha256: SHA_M } } })],
]) {
  test(`invalid manifest (${label}) -> 500, no links rendered`, async () => {
    const body = typeof bad === 'string' ? bad : JSON.stringify(bad);
    const res = await get('/download', { GAME: fakeR2(bucket(body)) });
    assert.equal(res.status, 500);
    assert.doesNotMatch(await text(res), /href=/);
  });
}

test('GET /download/<file> streams the object as an attachment', async () => {
  const res = await get('/download/' + MAC, { GAME: fakeR2(bucket()) });
  assert.equal(res.status, 200);
  assert.equal(res.headers.get('content-type'), 'application/octet-stream');
  assert.equal(res.headers.get('content-length'), String(ZIP.length));
  assert.equal(res.headers.get('content-disposition'), `attachment; filename="${MAC}"`);
  assert.equal(res.headers.get('etag'), `"etag-downloads/${MAC}"`);
  assert.deepEqual(new Uint8Array(await res.arrayBuffer()), ZIP);
});

test('missing file -> 404', async () => {
  const res = await get('/download/AxieDice-nope.zip', { GAME: fakeR2(bucket()) });
  assert.equal(res.status, 404);
});

test('the manifest itself and refused names are not served', async () => {
  const res = await get('/download/latest.json', { GAME: fakeR2(bucket()) });
  assert.equal(res.status, 404);
});

test('a refused name never reads R2 and never falls through to the game', async () => {
  const calls = [];
  const env = { GAME: fakeR2(bucket(null, { 'index.pck': new Uint8Array([1]) }), calls) };
  const res = await get('/download/..%2Findex.pck', env);
  assert.equal(res.status, 404);
  assert.equal(calls.length, 0);
});

test('POST /download is refused', async () => {
  const res = await get('/download', { GAME: fakeR2(bucket()) }, 'POST');
  assert.equal(res.status, 405);
});

test('the game routes still answer (index.html fallback unchanged)', async () => {
  const objs = new Map([['index.html', new TextEncoder().encode('<html>')]]);
  const res = await get('/', { GAME: fakeR2(objs) });
  assert.equal(res.status, 200);
  assert.equal(await text(res), '<html>');
});
