# SR-V job and result schema (Worker <-> runner), shadow mode

Worker side: `worker/src/verify_job.js` (builds the job), `worker/src/verify_queue.js` (endpoints).

## What reaches the server today
- The full action log DOES reach the server: every epoch request and `run_close` carry a hash-chained `log_delta`; the
  Durable Object keeps them all (`epochs.log_delta`), so `entries` = all deltas in seq order, closing delta included.
- The log HEADER does NOT reach the server. Missing: `team_keys`, `content_version`, `local_secret`, and the loadout flags
  `anchor`, `rules_on`, `core_off`, `boon_id`.
- NEW (client lane): `run_close` may carry an optional `log_header` object. Whitelisted and size-capped by the Worker; an
  invalid one is dropped and the close still succeeds:
  `{"team_keys":[str<=80 x<=5], "content_version":str<=40, "local_secret":int, "loadout":{"anchor":bool,"rules_on":bool,"core_off":bool,"boon_id":str<=40}}`
  Send what `ActionLog.header` holds for those keys. It is a client claim and is only used for what the server cannot know.

## Job (response of POST /api/verify/next -> `{"job": {...}}`)
```json
{
  "run_id": "<32 hex>",
  "rules_version": "godot-2026-10-26-v",
  "payload": {
    "schema": 1,
    "server_header": {
      "rules_version": "godot-2026-10-26-v",
      "kind": "mission",
      "mode": "short",
      "ascension": 3,
      "ranked": false,
      "depth_stage": 3,
      "newcomer": false,
      "mission": {"tier": "N2", "rules": ["M1", "M3"]},
      "header_mismatch": false
    },
    "server_loadout": {
      "bonuses": {"bonus_reroll": 1, "hp_bonus": 3, "start_relic_max_rarity": -1, "reward_reroll_max": 1},
      "forced": {},
      "server_unknown": ["anchor", "rules_on", "core_off", "boon_id"]
    },
    "client_header": {"team_keys": ["..."], "content_version": "...", "local_secret": 0,
                      "loadout": {"anchor": false, "rules_on": true, "core_off": false, "boon_id": ""}},
    "client_claim": {"outcome": "won", "score": 1234},
    "entries": [{"fn": "enter_node", "args": ["r1_c0", "battle"]}],
    "tape": [{"seq": 0, "kind": "run_start", "args": {"mode": "short", "ascension": 3}, "seed": 123,
              "extra": {"run_id": "<32 hex>", "client_nonce": "<32 hex>",
                        "header": {"newcomer": false, "depth_stage": 3, "mission": {"tier": "N2", "rules": ["M1", "M3"]}},
                        "h": "<hex>", "log_len": 0}},
             {"seq": 1, "kind": "node", "args": {"node_id": "r1_c0"}, "seed": 456, "extra": {"h": "<hex>", "log_len": 4}}]
  }
}
```
Rules for the runner when it builds the verifier input:
1. `server_header` wins over anything in the log header: `rules_version`, `mode`, `ascension`, `ranked`, `depth_stage`, `mission`.
   `kind=='mission'` <=> `mission` present. If `server_header.header_mismatch` is true, answer `ok:false, reason:"header_mismatch"` without replaying.
2. Log header = `{team_keys, content_version, local_secret}` from `client_header` + the server fields above.
   `team_keys`/`content_version` missing -> `bad_header` (job still queued; shows up as `error`, not a verdict).
3. Loadout passed to `RunVerifier.verify(log, tape, loadout)` = `{bonuses: server_loadout.bonuses}` + `client_header.loadout`
   (anchor, rules_on, core_off, boon_id) with `server_loadout.forced` applied on top. For ranked, `forced` =
   `{rules_on:true, core_off:false, anchor:false}`. Never take `bonuses` from the client.
4. `tape` is built by the server (seeds, args, chain h/log_len); `extra.header` of tape[0] is server-written (newcomer, depth_stage, mission).
   `mission.mission_id` is NOT known to the server (it is not stored), so compare tier + rules only.
5. Bonuses are right only when the economy is server-owned (unlocks in D1). Before R3 the D1 `unlocks` table is empty.
6. `client_claim.score` is `summary.score` from the client (may be absent -> score not compared).

## Result (POST /api/verify/result)
Body `{"run_id": "<32 hex>", "result": {8 keys}}` exactly the CLI output: `ok, reason, rules_version, outcome(won|lost|rejected|invalid), score, nodes, log_len, ms`.
Ceilings: score <= 1,000,000, nodes <= 1000, log_len <= 20,000, ms <= 600,000, reason `[a-z_]{0,64}`. `ok:true` needs `reason==""` and outcome won/lost.
Reply `{"ok":true,"state":"ok|mismatch|error","verdict":"match|outcome_mismatch|score_mismatch|rejected|error"}`.
`rules_version_mismatch`, `content_version_mismatch`, `bad_header`, `log_incomplete`, `bad_json`, `bad_tape`, `input_too_large`, `log_too_long`, `no_input`, `unreadable_input` count as `error` (could not judge), everything else rejected = `rejected`.

## Auth
Headers `X-Verify-Ts` (unix s, +-120 s) and `X-Verify-Sig` = hex HMAC-SHA256(`VERIFY_HMAC_KEY`, `${ts}\n${METHOD}\n${path}\n${body}`).
POST /api/verify/next, POST /api/verify/result, GET /api/verify/stats (body empty, query not signed). No key configured = 404.

## Queue housekeeping (b5cedf6)
- `/next` dọn trước khi nhận job (tối đa 50 dòng mỗi lệnh): job đã thử ≥ 3 lần và hết lease → `error/attempts_exhausted`; job chờ quá 14 ngày → `error/expired`; payload của job đã xong được xoá sau 7 ngày (kết quả vẫn nằm trong `verify_results`).
- Payload tối đa 900 000 byte (đếm byte, không đếm ký tự); lớn hơn thì job được lưu là `error/payload_too_large`.
- `/result` chỉ nhận khi lease còn hạn (`claimed_at >= now - 300`), không thì 409. Body > 4096 byte → 413.
