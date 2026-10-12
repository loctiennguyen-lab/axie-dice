// RTT spike (ADR C1, "đo RTT từ VN"). Usage:
//   node measure_rtt.mjs https://HOST [N=50]
// With a deployed spike Worker (rtt-worker.js) it measures: HTTP GET /ping, WS /ws (Worker echo),
// WS /do (Durable Object echo) and /do?write=1 (DO echo + one SQLite write). Fresh HTTP connection
// vs reused connection is separated because the game keeps one WebSocket open per run.
// With any other host (e.g. https://axiedice.fun) only the read-only HTTP GET is measured, against
// PATH (env PATH_TO_GET, default /terms). Needs Node 22+ (global WebSocket, fetch).
// Decision rule to apply to the output: WS p95 under 150 ms means the epoch round trip fits the
// 150 ms budget; if the DO row is much slower than the Worker row, the DO location (not the Worker) is the cost.
const [, , host, nArg] = process.argv;
if (!host) { console.error('usage: node measure_rtt.mjs https://host [N]'); process.exit(1); }
const N = Number(nArg) || 50;
const base = host.replace(/\/$/, '');
const stats = (xs) => {
  const s = [...xs].sort((a, b) => a - b);
  const q = (p) => s[Math.min(s.length - 1, Math.floor(p * s.length))];
  return { n: s.length, min: s[0].toFixed(1), p50: q(0.5).toFixed(1), p95: q(0.95).toFixed(1), max: s[s.length - 1].toFixed(1) };
};
const row = (name, xs) => console.log(name.padEnd(28), JSON.stringify(stats(xs)));

async function http(path) {
  const xs = [];
  for (let i = 0; i < N; i++) {
    const t = performance.now();
    const r = await fetch(base + path, { headers: { 'cache-control': 'no-cache' } });
    await r.arrayBuffer();
    xs.push(performance.now() - t);
    await new Promise((r2) => setTimeout(r2, 100));
  }
  return xs;
}
function ws(path) {
  return new Promise((resolve, reject) => {
    const sock = new WebSocket(base.replace(/^http/, 'ws') + path);
    const xs = []; let sent = 0, openMs = 0; const t0 = performance.now();
    const next = () => { sent = performance.now(); sock.send('x'); };
    sock.onopen = () => { openMs = performance.now() - t0; next(); };
    sock.onmessage = () => {
      xs.push(performance.now() - sent);
      if (xs.length >= N) { sock.close(); resolve({ xs, openMs }); } else setTimeout(next, 100);
    };
    sock.onerror = (e) => reject(new Error('ws error ' + (e.message || '')));
  });
}

console.log(`target ${base}  N=${N}`);
const ping = process.env.PATH_TO_GET || '/ping';
const h = await http(ping);
row(`HTTP GET ${ping} (reused conn)`, h.slice(1));
console.log('first request (cold, TLS)'.padEnd(28), h[0].toFixed(1));
if (ping !== '/ping' && !process.env.SPIKE) { console.log('not a spike Worker: skipping WebSocket rows'); process.exit(0); }
for (const p of ['/ws', '/do', '/do?write=1']) {
  try {
    const { xs, openMs } = await ws(p);
    row(`WS ${p} (open ${openMs.toFixed(0)} ms)`, xs.slice(1));
  } catch (e) { console.log(`WS ${p} failed: ${e.message}`); }
}
