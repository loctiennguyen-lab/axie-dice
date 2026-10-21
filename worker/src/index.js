import { handleLegal } from './legal.js';
import { handleAccounts, isAccountsPath } from './accounts.js';
import { handleWallet, isWalletPath } from './wallet.js';
import { handleRuns, isRunsPath, sweepPending } from './runs.js';
import { handleMissions, isMissionsPath } from './missions.js';
import { handleLeaderboard, isLeaderboardPath } from './leaderboard.js';
import { handleRaid, isRaidPath } from './raid.js';
/**
 * Axie Dice, served entirely from Cloudflare.
 *
 *   /api/axie?id=<axieId>   the Axie lookup proxy, ported from the Vercel function it replaces
 *   /auth/*, /api/me, /api/save   Google sign-in and cloud saves (accounts.js)
 *   /terms, /privacy        legal pages (legal.js)
 *   everything else         the Godot web build, streamed out of the R2 bucket
 *
 * Serving both from one Worker means the game and its API share an origin. The browser never
 * makes a cross-origin request, so the CORS headers below are belt and braces rather than the
 * thing the feature depends on.
 */

const GRAPHQL_ENDPOINT = 'https://graphql-gateway.axieinfinity.com/graphql';

const QUERY = `
  query GetAxieDetail($axieId: ID!) {
    axie(axieId: $axieId) {
      id
      class
      newGenes
      parts { id name class type specialGenes }
    }
  }
`;

/**
 * The gateway's own `axie.image` field returns an assets.axieinfinity.com URL that 403s even
 * from a real browser; that bucket rejects public reads regardless of headers or referrer. The
 * public, hotlink-safe CDN for the same rendered PNG is a different host with the same path
 * shape. Build the URL rather than trusting the field.
 */
const axieImageUrl = (id) =>
  `https://axiecdn.axieinfinity.com/axies/${id}/axie/axie-full-transparent.png`;

const isValidAxieId = (id) => typeof id === 'string' && /^\d+$/.test(id);

/** The gateway answers an unminted or non-existent id with `class: null` and empty parts. */
const isValidAxieData = (a) => !!a && a.class !== null && Array.isArray(a.parts) && a.parts.length > 0;

/**
 * Per-IP rate limit. Module scope lives as long as the isolate, so this resets whenever
 * Cloudflare recycles it and is per-colo rather than global. It is not meant to stop a
 * determined attacker, who can rotate IPs; it keeps a casual spam script from hammering the
 * gateway on our behalf. Same bargain the Vercel version made.
 */
const RATE_LIMIT_WINDOW_MS = 60_000;
const RATE_LIMIT_MAX = 20;
const hits = new Map();
function isRateLimited(ip) {
  const now = Date.now();
  const arr = (hits.get(ip) || []).filter((t) => now - t < RATE_LIMIT_WINDOW_MS);
  arr.push(now);
  hits.set(ip, arr);
  return arr.length > RATE_LIMIT_MAX;
}

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

const json = (body, status = 200, extra = {}) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS, ...extra },
  });

async function handleAxie(request, url) {
  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS });
  if (request.method !== 'GET') return json({ error: 'Method not allowed' }, 405);

  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  if (isRateLimited(ip)) return json({ error: 'Too many requests, try again in a minute.' }, 429);

  const id = url.searchParams.get('id');
  if (!isValidAxieId(id)) {
    return json({ error: 'Invalid axieId. Must be a positive integer.', received: id }, 400);
  }

  let upstream;
  try {
    upstream = await fetch(GRAPHQL_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        // The gateway sits behind Cloudflare bot management. The Vercel version had to shell
        // out to curl because Node's fetch was challenged on TLS fingerprint, not on headers.
        // A Worker cannot shell out, so if this ever starts coming back as an HTML challenge
        // page rather than JSON, the fix is a Sky Mavis Developer API key (docs.skymavis.com),
        // not another header.
        'User-Agent': 'axie-dice/1.0 (+https://github.com/loctiennguyen-lab/axie-dice)',
        Accept: 'application/json',
      },
      body: JSON.stringify({ query: QUERY, variables: { axieId: id } }),
    });
  } catch (err) {
    return json({ error: 'Failed to reach the Axie service', detail: String(err) }, 502);
  }

  const text = await upstream.text();
  let data;
  try {
    data = JSON.parse(text);
  } catch {
    // Almost always the bot-management challenge page. Say so, because "invalid response"
    // sends the next reader looking for a parsing bug that is not there.
    return json(
      {
        error: 'The Axie service did not answer with JSON.',
        upstream_status: upstream.status,
        first_bytes: text.slice(0, 200),
      },
      502,
    );
  }

  if (data.errors) return json({ error: 'Axie API returned an error', detail: data.errors }, 502);

  const axie = data?.data?.axie;
  if (!isValidAxieData(axie)) return json({ error: `Axie #${id} not found or has no data` }, 404);

  return json(
    {
      id: axie.id,
      class: axie.class,
      image: axieImageUrl(axie.id),
      // `genes` carries the value of the gateway's `newGenes` field and the name mismatch is
      // deliberate. The gateway exposes both; `genes` is the original 256-bit format (66 chars)
      // and `newGenes` is the 512-bit Origin format (130). AxieDescriptor.from_genes() is a
      // 512-bit decoder, and handed the short one it does not error, it decodes garbage and
      // builds a confident, wrong-looking Axie. `genes` is the key because that is the contract
      // AxieApi.parse_proxy_response reads first.
      genes: axie.newGenes || '',
      parts: axie.parts,
    },
    200,
    { 'Cache-Control': 'public, max-age=300' },
  );
}

/**
 * Content type is decided by the key's extension, not by what the uploader stored.
 *
 * A file dragged into the R2 dashboard carries whatever MIME the browser guessed from the OS,
 * and macOS has no guess for .wasm or .pck. A .wasm served as application/octet-stream makes
 * WebAssembly.instantiateStreaming refuse the module and the game dies on a black screen with
 * a console error that reads like a corrupt build. The extension is the authoritative answer
 * here, so it wins over the stored metadata.
 */
const CONTENT_TYPES = {
  html: 'text/html; charset=utf-8',
  js: 'text/javascript; charset=utf-8',
  wasm: 'application/wasm',
  json: 'application/json',
  png: 'image/png',
  jpg: 'image/jpeg',
  jpeg: 'image/jpeg',
  webp: 'image/webp',
  svg: 'image/svg+xml',
  pck: 'application/octet-stream',
};
const typeFor = (key) => CONTENT_TYPES[key.split('.').pop().toLowerCase()] || 'application/octet-stream';

/**
 * The engine files change on every export and must revalidate, or the browser keeps
 * running an old index.js/index.wasm against a fresh index.html. Everything else
 * (loading-screen art, fonts, icons) is content-stable and gets a year.
 */
const REVALIDATE = new Set([
  'index.html',
  'index.js',
  'index.wasm',
  'index.pck',
  'index.audio.worklet.js',
  'index.audio.position.worklet.js',
]);
function cacheFor(key) {
  if (REVALIDATE.has(key)) return 'public, max-age=0, must-revalidate';
  return 'public, max-age=31536000, immutable';
}


/**
 * index.pck is stored in R2 as several parts plus a manifest, because `wrangler r2 object put`
 * refuses files over 300 MiB. Manifest: {"total": N, "md5": "...", "parts": [{"key", "size"}]}.
 * No manifest object -> the caller falls back to the single `index.pck` object.
 * Returns null (no manifest), a Response (error), or the parsed manifest.
 */
const PCK_MANIFEST_KEY = 'index.pck.parts.json';
async function loadPckManifest(env) {
  const obj = await env.GAME.get(PCK_MANIFEST_KEY);
  if (obj === null) return null;
  const bad = (why) => new Response(`index.pck manifest invalid: ${why}`, { status: 500 });
  let m;
  try { m = JSON.parse(await obj.text()); } catch { return bad('not JSON'); }
  if (!m || !Number.isSafeInteger(m.total) || m.total <= 0 || !Array.isArray(m.parts) || m.parts.length === 0) {
    return bad('missing total/parts');
  }
  let sum = 0;
  for (const p of m.parts) {
    if (!p || typeof p.key !== 'string' || !p.key || !Number.isSafeInteger(p.size) || p.size <= 0) return bad('bad part entry');
    sum += p.size;
  }
  if (sum !== m.total) return bad(`part sizes sum to ${sum}, total says ${m.total}`);
  return m;
}

/** One range: bytes=a-b | a- | -n. Returns {start,end} | 'unsatisfiable' | null (ignore header). */
function parseRange(header, total) {
  const m = /^bytes=(\d*)-(\d*)$/.exec((header || '').trim());
  if (!m || (m[1] === '' && m[2] === '')) return null;
  let start;
  let end;
  if (m[1] === '') {
    const n = Number(m[2]);
    if (n === 0) return 'unsatisfiable';
    start = Math.max(0, total - n);
    end = total - 1;
  } else {
    start = Number(m[1]);
    end = m[2] === '' ? total - 1 : Math.min(Number(m[2]), total - 1);
  }
  if (start >= total || end < start) return 'unsatisfiable';
  return { start, end };
}

/** Streams bytes [start,end] of the concatenated parts; only parts overlapping the range are read. */
function streamParts(env, manifest, start, end, ctx) {
  const segs = [];
  let base = 0;
  for (const p of manifest.parts) {
    const lo = Math.max(start, base);
    const hi = Math.min(end, base + p.size - 1);
    if (lo <= hi) segs.push({ key: p.key, offset: lo - base, length: hi - lo + 1 });
    base += p.size;
  }
  // Native pipeTo per part into one fixed-length stream: the runtime does the copying with
  // backpressure. (A hand-written pull() loop was cut off mid-body by the edge on a 360 MB file.)
  const length = end - start + 1;
  const { readable, writable } = typeof FixedLengthStream !== 'undefined'
    ? new FixedLengthStream(length)
    : new TransformStream();
  const pump = (async () => {
    try {
      for (const s of segs) {
        const o = await env.GAME.get(s.key, { range: { offset: s.offset, length: s.length } });
        if (o === null) throw new Error(`pck part missing: ${s.key}`);
        await o.body.pipeTo(writable, { preventClose: true });
      }
      await writable.close();
    } catch (e) {
      try { await writable.abort(e); } catch { /* already errored */ }
    }
  })();
  if (ctx && ctx.waitUntil) ctx.waitUntil(pump);
  return readable;
}

async function servePck(request, env, manifest, ctx) {
  const total = manifest.total;
  const etag = manifest.md5 ? `"${manifest.md5}"` : `"pck-${total}"`;
  const headers = new Headers({
    'Content-Type': 'application/octet-stream',
    ETag: etag,
    'Cache-Control': cacheFor('index.pck'),
    'Accept-Ranges': 'bytes',
    'Cross-Origin-Opener-Policy': 'same-origin',
    'Cross-Origin-Embedder-Policy': 'require-corp',
  });
  const rangeHeader = request.headers.get('range');
  const r = rangeHeader ? parseRange(rangeHeader, total) : null;
  if (r === 'unsatisfiable') {
    headers.set('Content-Range', `bytes */${total}`);
    return new Response(null, { status: 416, headers });
  }
  const inm = request.headers.get('if-none-match');
  if (inm && !r) {
    const wanted = inm.split(',').map((t) => t.trim().replace(/^W\//, ''));
    if (wanted.includes('*') || wanted.includes(etag)) return new Response(null, { status: 304, headers });
  }
  const start = r ? r.start : 0;
  const end = r ? r.end : total - 1;
  headers.set('Content-Length', String(end - start + 1));
  if (r) headers.set('Content-Range', `bytes ${start}-${end}/${total}`);
  const body = request.method === 'HEAD' ? null : streamParts(env, manifest, start, end, ctx);
  return new Response(body, { status: r ? 206 : 200, headers });
}

async function serveGame(request, env, url, ctx) {
  if (request.method !== 'GET' && request.method !== 'HEAD') {
    return new Response('Method not allowed', { status: 405 });
  }
  let key = decodeURIComponent(url.pathname.slice(1));
  if (key === '' || key.endsWith('/')) key += 'index.html';

  if (key === 'index.pck') {
    const manifest = await loadPckManifest(env);
    if (manifest instanceof Response) return manifest;
    if (manifest) return servePck(request, env, manifest, ctx);
  }

  // Range matters here: index.pck is 189 MB and a browser that reconnects asks for the rest
  // rather than the whole thing again.
  const range = request.headers.get('range');

  // Conditional requests. The engine files are served `max-age=0, must-revalidate`, which only
  // helps if the server can answer "unchanged". Without this a revalidation always came back as
  // a full 200, so index.wasm (9.5 MB on the wire) was downloaded again on every single visit.
  // A range request is left alone: a partial response is not what the validator describes.
  const ifNoneMatch = request.headers.get('if-none-match');
  if (ifNoneMatch && !range) {
    const meta = await env.GAME.head(key);
    if (meta) {
      const wanted = ifNoneMatch.split(',').map((t) => t.trim().replace(/^W\//, ''));
      if (wanted.includes('*') || wanted.includes(meta.httpEtag)) {
        return new Response(null, {
          status: 304,
          headers: {
            ETag: meta.httpEtag,
            'Cache-Control': cacheFor(key),
            'Cross-Origin-Opener-Policy': 'same-origin',
            'Cross-Origin-Embedder-Policy': 'require-corp',
          },
        });
      }
    }
  }
  const obj = await env.GAME.get(key, range ? { range: request.headers } : undefined);
  if (obj === null) return new Response(`Not found: ${key}`, { status: 404 });

  const headers = new Headers();
  obj.writeHttpMetadata(headers);
  headers.set('etag', obj.httpEtag);
  headers.set('Cache-Control', cacheFor(key));
  headers.set('Accept-Ranges', 'bytes');
  headers.set('Content-Type', typeFor(key));
  // Cross-origin isolation. The threaded web export needs SharedArrayBuffer, and the browser
  // only hands it over when the page is isolated. Every asset the page loads must therefore be
  // same-origin or CORS-enabled - which is why the loading-screen fonts are served from here
  // instead of Google Fonts.
  headers.set('Cross-Origin-Opener-Policy', 'same-origin');
  headers.set('Cross-Origin-Embedder-Policy', 'require-corp');

  // Only answer 206 when the client actually asked for a range. R2 reports obj.range on a
  // plain get too, and a 206 nobody asked for is not just untidy: Chrome refuses to load an
  // AudioWorklet module from one, which silently kills every sound in the game.
  if (range && obj.range && obj.size !== undefined) {
    const start = obj.range.offset ?? 0;
    const len = obj.range.length ?? obj.size - start;
    headers.set('Content-Range', `bytes ${start}-${start + len - 1}/${obj.size}`);
    return new Response(request.method === 'HEAD' ? null : obj.body, { status: 206, headers });
  }
  return new Response(request.method === 'HEAD' ? null : obj.body, { status: 200, headers });
}

export { RunDO } from './run_do.js';

export default {
  async scheduled(_event, env, ctx) { ctx.waitUntil(sweepPending(env)); },
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (url.pathname === '/api/axie') return handleAxie(request, url);
    if (url.pathname === '/terms' || url.pathname === '/privacy') return handleLegal(url);
    if (isAccountsPath(url.pathname)) return handleAccounts(request, env, url);
    if (isWalletPath(url.pathname)) return handleWallet(request, env, url);
    if (isRunsPath(url.pathname)) return handleRuns(request, env, url);
    if (isMissionsPath(url.pathname)) return handleMissions(request, env, url);
    if (isLeaderboardPath(url.pathname)) return handleLeaderboard(request, env, url);
    if (isRaidPath(url.pathname)) return handleRaid(request, env, url);
    return serveGame(request, env, url, ctx);
  },
};
