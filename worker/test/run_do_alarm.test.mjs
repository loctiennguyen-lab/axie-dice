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
