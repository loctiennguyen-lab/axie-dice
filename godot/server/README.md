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

### A wrong ID answers 404, not 502

Re-measured 2026-09-19 against the live gateway, correcting what this file said earlier. An
out-of-range id (`999999999`) comes back like this:

```json
{"data":{"axie":null},"errors":[{"message":"Internal Server Error","path":["axie"], …}]}
```

`data.axie` is present and null **in the same body** as the error, so the two cases ARE
distinguishable — this proxy used to bail on `errors` before looking at `data` and answered a
typo with 502, which reads as "the service is down". Now: `123` → 200, `999999999` → **404
"Axie #999999999 not found"**, `abc`/`0` → 400, and 502 means what it says.

## CORS — set this only for a cross-origin deploy

By default the proxy sends **no CORS header at all**. That is correct and sufficient when the game
and the proxy sit on the same domain (`https://yourgame.example` serving both the export and
`/api/axie-godot`) — a browser never asks permission to read its own origin. Deploy it that way if
you can; it is the simplest and the tightest.

Serving the web export from a *different* origin than the proxy? Name the allowed origins:

```bash
AXIE_PROXY_ALLOWED_ORIGIN="https://yourgame.example,https://staging.yourgame.example"
```

(On Vercel: Project Settings → Environment Variables.) Only those origins are echoed back, with
`Vary: Origin`. Anything else gets no header and the browser refuses the read.

It deliberately does **not** send `Access-Control-Allow-Origin: *`. Axie data is public, so `*`
leaks nothing — but it turns this into an open relay: any website could embed a `fetch()` to it and
use your box's Cloudflare-passing `curl` on your rate limit and your invocation bill.

**Symptom of a missing setting**: the game reports a network error on a proxy that answers 200 to
`curl`. That is the browser blocking the read, not the proxy failing — check `AXIE_PROXY_ALLOWED_ORIGIN`.

## What the game does when it is missing

`AxieApi.is_available()` returns false and the Vault screen disables the ID field **with the
reason printed on screen**, rather than offering a button that does nothing.
