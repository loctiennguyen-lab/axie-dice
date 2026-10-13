// Socket-without-hello alarm (l1-tasks-S item 10). RunDO against a fake DurableObjectState.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { RunDO, HELLO_DEADLINE_MS } from '../src/run_do.js';

function sqlStub() {
  const db = new DatabaseSync(':memory:');
  return { exec(q, ...b) { const st = db.prepare(q); if (/^\s*select/i.test(q)) { const r = st.all(...b); return { toArray: () => r }; } if (/^\s*(insert|update|delete)/i.test(q)) { st.run(...b); return { toArray: () => [] }; } db.exec(q); return { toArray: () => [] }; } };
}
const fakeWs = (att) => ({ att, closed: null, serializeAttachment(a) { this.att = a; }, deserializeAttachment() { return this.att; }, close(c, r) { this.closed = [c, r]; } });

function mk() {
  const sockets = [];
  let alarm = null;
  const ctx = { storage: { sql: sqlStub(), getAlarm: async () => alarm, setAlarm: async (t) => { alarm = t; } }, getWebSockets: () => sockets, acceptWebSocket: (w) => sockets.push(w) };
  return { sockets, getAlarm: () => alarm, do: new RunDO(ctx, {}) };
}

test('alarm closes sockets that never said hello, keeps authed ones, re-arms for young ones', async () => {
  const m = mk();
  const now = Date.now();
  const old = fakeWs({ authed: false, epoch: 0, at: now - HELLO_DEADLINE_MS - 1 });
  const ok = fakeWs({ authed: true, epoch: 1 });
  const young = fakeWs({ authed: false, epoch: 0, at: now - 1000 });
  m.sockets.push(old, ok, young);
  await m.do.alarm();
  assert.deepEqual(old.closed, [1008, 'no_hello']);
  assert.equal(ok.closed, null);
  assert.equal(young.closed, null);
  assert.ok(m.getAlarm() > now && m.getAlarm() <= now + HELLO_DEADLINE_MS);
});

test('alarm with nothing waiting does not re-arm', async () => {
  const m = mk();
  m.sockets.push(fakeWs({ authed: true, epoch: 1 }));
  await m.do.alarm();
  assert.equal(m.getAlarm(), null);
});

test('hello alarm leaves an open run alone in D1; a closed run is synced', async () => {
  const m = mk();
  const calls = [];
  m.do.env.DB = { prepare: (q) => ({ bind: (...a) => ({ run: async () => { calls.push([q, a]); } }) }) };
  await m.do.core.init({ run_id: 'a'.repeat(32), player_id: 'p', rules_version: 'godot-2026-09-21-a' });
  await m.do.alarm();
  assert.equal(calls.length, 0);
  m.do.core.sql.exec(`UPDATE meta SET state = 'closed', outcome = 'won', summary = '{"battles_done":4,"newcomer":true}' WHERE id = 1`);
  m.do.core.sql.exec(`INSERT INTO epochs (seq, kind, args, h, log_len, seed, log_delta, attempt, req_digest, aid, at) VALUES (9, 'continue', '{}', 'h', 1, 1, '[]', 0, 'd', 'R1', 1)`);
  await m.do.alarm();
  assert.equal(calls.length, 1);
  const stored = JSON.parse(calls[0][1][3]);
  assert.equal(calls[0][1][2], 4);                       // battles_done column now filled from the summary
  assert.deepEqual(stored.srv.aids, ['R1']);             // server-seen Aid kept next to the client claim
  assert.equal(stored.newcomer, true);
});

test('unparseable summary and absurd battles_done still sync (no endless alarm)', async () => {
  const m = mk();
  const calls = [];
  m.do.env.DB = { prepare: (q) => ({ bind: (...a) => ({ run: async () => { calls.push([q, a]); } }) }) };
  await m.do.core.init({ run_id: 'b'.repeat(32), player_id: 'p', rules_version: 'godot-2026-09-21-a' });
  m.do.core.sql.exec(`UPDATE meta SET state = 'closed', outcome = 'lost', summary = '{"battles_d' WHERE id = 1`);
  await m.do.alarm();
  assert.equal(calls.length, 1);
  assert.equal(calls[0][1][2], 0);
  m.do.core.sql.exec(`UPDATE meta SET summary = '{"battles_done":99999}' WHERE id = 1`);
  await m.do.alarm();
  assert.equal(calls[1][1][2], 0);
});
