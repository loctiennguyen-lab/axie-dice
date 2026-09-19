# Axie lookup proxy — for the WEB build only

## Do I need this?

| Build | Needs this proxy? | Why |
|---|---|---|
| **Desktop** (macOS / Windows / Linux) | **No** | Godot runs `curl` locally — nothing to deploy |
| **Web / browser** | **Yes** | A browser has no `OS.execute`, and calling the Axie gateway from page JavaScript is blocked by CORS |

There is no way around it inside a browser. The gateway sends no CORS headers, so the response is
unreadable from a web page; and a plain server-side `fetch()` is refused by Cloudflare's bot check,
which inspects the TLS fingerprint rather than the headers. `curl` on a server is the working path,
which is exactly what the JavaScript build already does.

## Why this is not `api/axie.js`

`api/axie.js` serves the **live JavaScript game** and real players. This file is separate on
purpose: the Godot port can change its shape or its limits without any of that reaching a player of
the other build. The one difference in output today is `genes` — the 512-bit `newGenes` the Godot
3D rig needs, which the JS build has never asked for because it shows a flat PNG instead.

## Deploy

### Vercel (what this repo already uses)

1. Copy `axie-proxy.js` into the `api/` directory of a Vercel project, named for the route you
   want — e.g. `api/axie-godot.js` serves `/api/axie-godot`.
2. Deploy.
3. Point the game at it:
   - **Project Settings**: add a string setting `axie/proxy_url` =
     `https://<your-app>.vercel.app/api/axie-godot`, or
   - **in code**: `AxieApi.set_proxy_url("https://…/api/axie-godot")`.

Deploying it into *this* repo's Vercel project would also work and would not change the JS game —
it is a new route, not an edit to an existing one. That is a deliberate choice to make, not a
default.

### Anywhere else

Any host that can run Node **and has `curl` on the box** will do (Netlify Functions, a small VPS,
Cloudflare Workers will NOT — no subprocesses). The handler is a plain
`(req, res)` function.

## Checking it works

```bash
curl -s "https://<your-app>/api/axie-godot?id=123" | python3 -m json.tool
```

Expect `genes` to be **130 characters** (`0x` + 128 hex digits). If it comes back 66 characters,
the query is reading `genes` instead of `newGenes` — Godot's decoder will not error on that, it
will build a wrong Axie in silence.

### A 502 usually means "no such Axie"

Measured 2026-09-19: an out-of-range id (`999999999`) does **not** come back as a null axie. The
gateway answers with `INTERNAL_SERVER_ERROR`, which this proxy reports as HTTP 502. So a 502 is
most often a wrong ID and occasionally a real outage, and nothing here can tell the two apart —
the game says both rather than guessing.

## What the game does when it is missing

`AxieApi.is_available()` returns false and the Vault screen disables the ID field **with the
reason printed on screen**, rather than offering a button that does nothing.
