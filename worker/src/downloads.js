// Desktop download page and file stream. Testers land on https://axiedice.fun/download (a fixed
// link that the game's "có bản mới" screen also points at), read the newest build from the manifest
// in R2, and download through the Worker so the bucket key never has to be public.
//
//   GET /download               HTML page built from downloads/latest.json
//   GET /download/<path>        streams R2 key downloads/<path> (attachment)
//
// Manifest (downloads/latest.json, written by tools/publish_desktop.sh):
//   {"version":"0.1.0","build":1639,"commit":"5ecc08f","rules_version":"godot-...",
//    "published_at":"2026-10-26T10:00:00+07:00",
//    "platforms":{"macos":{"file":"AxieDice-....-macos.zip","size":123,"sha256":"<64 hex>"},
//                 "windows":{...}}}
// `file` is a bare name inside downloads/; the Worker builds the URL, so the manifest cannot point
// anywhere else. Nothing outside the downloads/ prefix is reachable from here.

export const DOWNLOAD_MANIFEST_KEY = 'downloads/latest.json';
const PREFIX = 'downloads/';
const ALLOWED_EXT = new Set(['zip', 'dmg', 'exe', 'sha256', 'txt', 'json']);
const PLATFORMS = ['macos', 'windows'];

/** /download and /download/... only. /downloads and /download.html are not ours. */
export function isDownloadPath(pathname) {
  return pathname === '/download' || pathname === '/download/' || pathname.startsWith('/download/');
}

/**
 * Maps the URL's path after /download/ to an R2 key under downloads/. Returns null when the
 * request must be refused. Checks run on the DECODED name, so %2e%2e, %2F and %5C are caught too.
 */
export function downloadKeyFor(pathname) {
  const rest = pathname.slice('/download/'.length);
  let name;
  try { name = decodeURIComponent(rest); } catch { return null; }
  if (name === '' || name.endsWith('/')) return null;
  // ASCII printable only: a non-ASCII name would make `new Headers` throw (500) and R2 keys are not paths anyway.
  if (!/^[\x20-\x7e]+$/.test(name) || /[\\]/.test(name) || name.startsWith('/')) return null;
  const segs = name.split('/');
  if (segs.some((s) => s === '' || s === '.' || s === '..')) return null;
  const ext = segs[segs.length - 1].split('.').pop().toLowerCase();
  if (!ALLOWED_EXT.has(ext)) return null;
  return PREFIX + name;
}

/** Reads and checks the manifest. Returns {error: string} or {manifest}. */
export async function loadDownloadManifest(env) {
  const obj = await env.GAME.get(DOWNLOAD_MANIFEST_KEY);
  if (obj === null) return { missing: true };
  let m;
  try { m = JSON.parse(await obj.text()); } catch { return { error: 'manifest is not JSON' }; }
  if (!m || typeof m.version !== 'string' || typeof m.rules_version !== 'string') {
    return { error: 'manifest missing version or rules_version' };
  }
  if (!m.platforms || typeof m.platforms !== 'object') return { error: 'manifest missing platforms' };
  for (const p of PLATFORMS) {
    const e = m.platforms[p];
    if (!e || typeof e.file !== 'string' || downloadKeyFor(`/download/${e.file}`) === null) {
      return { error: `platform ${p}: bad file` };
    }
    if (!Number.isSafeInteger(e.size) || e.size <= 0) return { error: `platform ${p}: bad size` };
    if (typeof e.sha256 !== 'string' || !/^[0-9a-f]{64}$/.test(e.sha256)) {
      return { error: `platform ${p}: sha256 missing or not 64 lowercase hex` };
    }
  }
  return { manifest: m };
}

const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const mb = (n) => `${(n / 1048576).toFixed(1)} MB`;
const LABEL = { macos: 'macOS', windows: 'Windows' };

function pageHtml(m) {
  const cards = PLATFORMS.map((p) => {
    const e = m.platforms[p];
    return `<section class="card">
  <h2>${LABEL[p]}</h2>
  <p><a class="btn" href="/download/${encodeURIComponent(e.file)}" download>Tải ${LABEL[p]} (${mb(e.size)})</a></p>
  <p class="small">File: <code>${esc(e.file)}</code><br>SHA-256: <code>${esc(e.sha256)}</code></p>
</section>`;
  }).join('\n');
  return `<!doctype html>
<html lang="vi">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Tải Axie Dice (desktop)</title>
<style>
:root { color-scheme: dark; }
body { margin: 0; background: #16220f; color: #FFEBD2; font: 16px/1.6 system-ui, -apple-system, 'Segoe UI', sans-serif; }
main { max-width: 680px; margin: 0 auto; padding: 40px 16px 64px; }
h1 { font-size: 32px; color: #FFF6E6; margin: 0 0 8px; }
h2 { font-size: 24px; color: #FFD9B0; margin: 0 0 12px; }
.meta { color: rgba(255,232,206,.7); margin: 0 0 28px; }
.card { background: rgba(0,0,0,.25); border: 1px solid rgba(255,217,176,.2); border-radius: 12px; padding: 18px 20px; margin: 0 0 16px; }
.btn { display: inline-block; background: #FFC078; color: #2a1a05; font-weight: 700; text-decoration: none; padding: 12px 20px; border-radius: 10px; }
.small { font-size: 16px; color: rgba(255,232,206,.75); word-break: break-all; }
code { font-size: 16px; }
ul { padding-left: 20px; }
</style>
</head>
<body>
<main>
<h1>Axie Dice, bản desktop</h1>
<p class="meta">Phiên bản ${esc(m.version)} · build ${esc(m.build ?? '?')} · luật ${esc(m.rules_version)}${m.published_at ? ` · ${esc(m.published_at)}` : ''}</p>
${cards}
<h2>Trước khi mở</h2>
<ul>
  <li>Bản này chưa ký số. macOS 15 trở lên: chuột phải chọn Mở không còn đủ. Vào Cài đặt hệ thống > Quyền riêng tư và bảo mật, kéo xuống mục về AxieDice và bấm "Vẫn mở" (Open Anyway), nhập mật khẩu máy.</li>
  <li>macOS máy cũ (14 trở xuống): chuột phải vào app, chọn Mở. Nếu app báo "bị hỏng" thì chạy trong Terminal: <code>xattr -dr com.apple.quarantine /Applications/AxieDice.app</code></li>
  <li>Windows: SmartScreen hiện "Windows đã bảo vệ máy tính PC", bấm "Thêm thông tin" (More info), rồi "Vẫn chạy" (Run anyway).</li>
  <li>Nên so sha256 của file vừa tải với dòng SHA-256 trên trang này.</li>
  <li>Bản cũ sẽ báo "có bản mới" khi vào trận. Tải lại từ trang này là đủ.</li>
</ul>
</main>
</body>
</html>`;
}

const SEC = { 'X-Content-Type-Options': 'nosniff' };
const HTML_HEADERS = { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'public, max-age=60', ...SEC };
const TEXT = (status, msg) => new Response(msg, { status, headers: { 'Content-Type': 'text/plain; charset=utf-8', ...SEC } });

/** Entry point, called from index.js before the game fallback. */
export async function handleDownload(request, env, url) {
  if (request.method !== 'GET' && request.method !== 'HEAD') {
    return new Response('Method not allowed', { status: 405 });
  }
  const isPage = url.pathname === '/download' || url.pathname === '/download/';
  if (isPage) {
    const r = await loadDownloadManifest(env);
    if (r.missing) return TEXT(503, 'Chưa có bản desktop nào được đăng.');
    // The reason stays in the log; the public answer is the same for any manifest fault.
    if (r.error) { console.error('downloads manifest invalid:', r.error); return TEXT(503, 'Trang tải tạm thời chưa sẵn sàng. Thử lại sau.'); }
    return new Response(request.method === 'HEAD' ? null : pageHtml(r.manifest), { status: 200, headers: HTML_HEADERS });
  }

  const key = downloadKeyFor(url.pathname);
  if (key === null || key === DOWNLOAD_MANIFEST_KEY) return TEXT(404, 'Not found');
  const obj = request.method === 'HEAD' ? await env.GAME.head(key) : await env.GAME.get(key);
  if (obj === null) return TEXT(404, 'Not found');
  const name = key.slice(PREFIX.length).split('/').pop();
  const headers = new Headers({
    'Content-Type': 'application/octet-stream',
    'Content-Length': String(obj.size),
    'Content-Disposition': `attachment; filename="${name.replace(/["\\]/g, '_')}"`,
    'Cache-Control': 'public, max-age=3600',
    ETag: obj.httpEtag,
    ...SEC,
  });
  return new Response(request.method === 'HEAD' ? null : obj.body, { status: 200, headers });
}
