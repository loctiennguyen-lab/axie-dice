// RTT spike Worker. NOT part of the game Worker; deploy only under its own name (wrangler.spike.toml).
// Routes: GET /ping (plain HTTP), GET /ws (plain Worker WebSocket echo), GET /do (WebSocket echo via a
// Durable Object, the real RunDO path incl. SQLite write per message when ?write=1).
export class SpikeDO {
  constructor(ctx) { this.ctx = ctx; ctx.storage.sql.exec('CREATE TABLE IF NOT EXISTS t (n INTEGER)'); }
  async fetch(request) {
    const pair = new WebSocketPair();
    this.ctx.acceptWebSocket(pair[1]);
    this.write = new URL(request.url).searchParams.get('write') === '1';
    return new Response(null, { status: 101, webSocket: pair[0] });
  }
  webSocketMessage(ws, msg) {
    if (this.write) this.ctx.storage.sql.exec('INSERT INTO t VALUES (1)');
    ws.send(msg);
  }
}
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === '/ping') return new Response(JSON.stringify({ colo: request.cf && request.cf.colo, t: Date.now() }), { headers: { 'content-type': 'application/json' } });
    if (request.headers.get('Upgrade') !== 'websocket') return new Response('expected websocket', { status: 426 });
    if (url.pathname === '/ws') {
      const [a, b] = Object.values(new WebSocketPair());
      b.accept();
      b.addEventListener('message', (e) => b.send(e.data));
      return new Response(null, { status: 101, webSocket: a });
    }
    if (url.pathname === '/do') {
      const id = env.SPIKE.idFromName(url.searchParams.get('name') || 'spike');
      return env.SPIKE.get(id).fetch(request);
    }
    return new Response('not found', { status: 404 });
  },
};
