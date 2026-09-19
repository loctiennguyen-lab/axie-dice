class_name AxieApi
extends Node
## Fetches one real Axie from the Axie Infinity GraphQL gateway, for Vault / Import Axie.
##
## WHY IT SHELLS OUT TO `curl` INSTEAD OF USING HTTPRequest
## --------------------------------------------------------
## The gateway sits behind Cloudflare bot management, and the check is on the TLS/HTTP2 client
## FINGERPRINT, not on headers — so no amount of User-Agent spoofing gets a normal HTTP client
## through. Measured, not assumed, on 2026-09-19:
##
##   * browser `fetch()`      → blocked by CORS (this is why the JS build has a server proxy)
##   * Node `fetch()`         → Cloudflare challenge (see the comment in `api/axie.js`)
##   * Godot `HTTPRequest`    → HTTP 403, body is Cloudflare's "Just a moment..." page
##   * `curl`                 → 200, real data
##
## `curl` is the only client that gets through, and Godot can run it. The JS build solves the
## same problem the same way — its serverless function also shells out to curl — it just does so
## on a server. This port does it locally instead, because the live proxy serves real players and
## is not ours to change for a feature only this build needs.
##
## TWO TRANSPORTS, BECAUSE A BROWSER CANNOT DO WHAT A DESKTOP CAN
## --------------------------------------------------------------
##   * DESKTOP → `curl` (above). No server needed, nothing to deploy, nothing to pay for.
##   * WEB      → an HTTP GET to a PROXY, via `HTTPRequest`.
##
## A web export has no `OS.execute` at all, and a browser calling the gateway directly is blocked
## by CORS — which is the very reason the JS build has a server proxy in the first place. Inside a
## browser there is no way around that: the fix is a server, and the only question is whose.
## `set_proxy_url()` / the `axie/proxy_url` project setting says which one; `godot/server/` holds
## a ready-to-deploy implementation and the instructions.
##
## The transport is chosen by capability, not by guesswork — see `active_transport()`. A desktop
## build with a proxy configured still prefers `curl`, because that path needs no server to be up.
##
## WHY `-d @file` AND NOT `-d <payload>`
## -------------------------------------
## Passing the payload as an argv string makes `OS.execute` fail with curl exit 2 — reproduced
## every time with this exact query, while a short payload works. Writing it to a file and
## passing `@path` works reliably, and has a second benefit: the query never appears in the
## machine's process list.
##
## SAFETY: arguments go to `OS.execute` as an ARRAY, never a shell string, so there is no shell
## to inject into; and `is_valid_axie_id()` rejects anything that is not digits before the value
## is used at all.

signal completed(result: Dictionary)

const ENDPOINT := "https://graphql-gateway.axieinfinity.com/graphql"
const TIMEOUT_SECONDS := 12

## `newGenes`, NOT `genes`.
##
## Both fields exist and both return a hex string, which is exactly what makes this dangerous:
## `genes` is the ORIGINAL 256-bit format (66 characters) and `newGenes` is the 512-bit Origin
## format (130). `AxieDescriptor.from_genes()` is a 512-bit decoder. Handed the short one it does
## not error — it decodes garbage and builds a confident, wrong-looking Axie. Verified on Axie
## #123: `newGenes` matches the vendor golden byte for byte; `genes` does not.
const QUERY := "query GetAxieDetail($axieId: ID!) {" \
	+ " axie(axieId: $axieId) { id class newGenes" \
	+ " parts { id name class type specialGenes } } }"

## Where curl might live. Checked in order; the first one that exists wins.
const CURL_PATHS: Array[String] = ["/usr/bin/curl", "/opt/homebrew/bin/curl", "/bin/curl"]

const _PAYLOAD_PATH := "user://axie_query.json"

## Project setting holding the proxy base URL, so a build can be pointed at a different server
## without a code change. Set it in Project Settings, or call `set_proxy_url()` at runtime.
const PROXY_SETTING := "axie/proxy_url"

enum Transport { NONE, CURL, PROXY }

static var _proxy_url_override := ""

var _thread: Thread = null
var _http: HTTPRequest = null


## The proxy base URL, or "" when none is configured. Expected to answer
## `GET <url>?id=<axieId>` with `{id, class, genes, parts}` — the shape `godot/server/axie-proxy.js`
## returns.
static func proxy_url() -> String:
	if not _proxy_url_override.is_empty():
		return _proxy_url_override
	if ProjectSettings.has_setting(PROXY_SETTING):
		return str(ProjectSettings.get_setting(PROXY_SETTING, "")).strip_edges()
	return ""


static func set_proxy_url(url: String) -> void:
	_proxy_url_override = url.strip_edges()


## Which path a fetch would actually take on THIS build.
##
## `curl` wins where it exists, even when a proxy is configured: it needs no server to be up, no
## deploy to be current and no bandwidth to be paid for. The proxy is what a browser has instead,
## not a better option that desktop should prefer.
static func active_transport() -> Transport:
	if OS.get_name() != "Web" and not curl_path().is_empty():
		return Transport.CURL
	if not proxy_url().is_empty():
		return Transport.PROXY
	return Transport.NONE


func _exit_tree() -> void:
	# A Thread that is still running when its owner leaves the tree prints an error and leaks.
	if _thread != null and _thread.is_started():
		_thread.wait_to_finish()
	_thread = null


# ===========================================================================
# Pure helpers — no I/O, no network. Everything below the next section header
# needs a machine and a working internet connection; everything here does not,
# which is what lets the gate cover the parsing without ever making a request.
# ===========================================================================

## The API takes an ID; anything else is a mistake worth catching before a request is made.
## Leading zeros are rejected too: "007" and "7" would be the same Axie to the API but two
## different keys in the vault.
static func is_valid_axie_id(id: String) -> bool:
	var s := id.strip_edges()
	if s.is_empty() or s.length() > 12:
		return false
	if s.length() > 1 and s.begins_with("0"):
		return false
	for i in s.length():
		if s[i] < "0" or s[i] > "9":
			return false
	return true


static func build_payload(id: String) -> String:
	return JSON.stringify({"query": QUERY, "variables": {"axieId": id.strip_edges()}})


## Turns whatever curl produced into the one shape the rest of the game reads:
##   {ok: bool, err: String, axie: {id, class, genes, parts}}
##
## `err` is a short machine key AND `message` is the sentence a player reads — kept separate so
## the screen never has to pattern-match on prose, and so a new failure mode cannot quietly
## inherit another one's wording.
static func parse_response(exit_code: int, body: String) -> Dictionary:
	if exit_code != 0:
		return _fail("network", "Could not reach the Axie service. Check your connection.")
	if body.strip_edges().is_empty():
		return _fail("empty", "The Axie service returned nothing.")

	# Cloudflare answers a blocked client with an HTML challenge page, not JSON. Naming that case
	# matters: "invalid response" would send the next person debugging their JSON parser.
	var head := body.strip_edges().substr(0, 40).to_lower()
	if head.begins_with("<!doctype") or head.begins_with("<html"):
		return _fail("blocked",
			"The Axie service blocked this request (bot protection). Try again in a minute.")

	var parsed = JSON.parse_string(body)
	if not (parsed is Dictionary):
		return _fail("bad_json", "The Axie service sent something unreadable.")
	var doc: Dictionary = parsed

	if doc.has("errors"):
		return _fail("graphql", "The Axie service rejected the request.")
	var data = doc.get("data")
	if not (data is Dictionary):
		return _fail("bad_json", "The Axie service sent something unreadable.")
	var axie = (data as Dictionary).get("axie")
	# A non-existent or unminted id comes back as a NULL axie, or as one with a null class and no
	# parts — the JS proxy checks the same two shapes (`isValidAxieData`, api/axie.js:50).
	if not (axie is Dictionary):
		return _fail("not_found", "No Axie with that ID.")
	var a: Dictionary = axie
	var parts: Array = a.get("parts", []) if a.get("parts") is Array else []
	if a.get("class") == null or parts.is_empty():
		return _fail("not_found", "No Axie with that ID.")

	var genes := str(a.get("newGenes", "")) if a.get("newGenes") != null else ""
	return {
		"ok": true, "err": "", "message": "",
		"axie": {
			# `id` as a STRING: it is a name, not a quantity, and MetaState files vault records
			# under `vault_<id>`. See MetaState.vault_import().
			"id": str(a.get("id", "")),
			"class": str(a.get("class", "")),
			# May legitimately be "" — an Axie predating the Origin gene format. The die still
			# builds from `parts`; only the 3D preview needs this, and AxieGenePreview already
			# reports an empty gene as absence rather than drawing a bare body.
			"genes": genes,
			"parts": parts,
		},
	}


static func _fail(err: String, message: String) -> Dictionary:
	return {"ok": false, "err": err, "message": message, "axie": {}}


## The curl binary, or "" when there is none. Public because the Vault screen has to tell the
## player why the field is disabled instead of just disabling it.
static func curl_path() -> String:
	for p in CURL_PATHS:
		if FileAccess.file_exists(p):
			return p
	return ""


static func is_available() -> bool:
	return active_transport() != Transport.NONE


## Why importing cannot work here, in words a player can act on. Empty when it can.
static func unavailable_reason() -> String:
	if active_transport() != Transport.NONE:
		return ""
	if OS.get_name() == "Web":
		# A browser cannot reach the gateway itself — CORS — so this build needs a proxy and was
		# shipped without one. That is a deploy-time omission, and saying so is more useful than
		# "unavailable".
		return ("This web build has no Axie proxy configured, and a browser cannot reach the "
			+ "Axie service directly. See godot/server/README.md.")
	return "Importing an Axie needs `curl`, which was not found on this machine."


# ===========================================================================
# The request itself
# ===========================================================================

## Starts a fetch. Emits `completed(result)` on the main thread; `result` has the shape
## `parse_response()` documents. Returns false if a request is already in flight.
##
## THREADED because `OS.execute` BLOCKS. Run on the main thread it freezes the whole game —
## rendering, input, animation — for as long as the request takes, up to the 12-second timeout.
## A Vault screen that locks up for twelve seconds on a typo is worse than no import button.
func request_axie(id: String) -> bool:
	if _thread != null and _thread.is_started():
		return false
	if not is_valid_axie_id(id):
		completed.emit(_fail("bad_id", "An Axie ID is a number, like 123."))
		return true
	match active_transport():
		Transport.CURL:
			return _request_via_curl(id)
		Transport.PROXY:
			return _request_via_proxy(id)
		_:
			completed.emit(_fail("unavailable", unavailable_reason()))
			return true


func _request_via_curl(id: String) -> bool:
	var f := FileAccess.open(_PAYLOAD_PATH, FileAccess.WRITE)
	if f == null:
		completed.emit(_fail("io", "Could not prepare the request."))
		return true
	f.store_string(build_payload(id))
	f.close()

	_thread = Thread.new()
	_thread.start(_run.bind(ProjectSettings.globalize_path(_PAYLOAD_PATH), curl_path()))
	return true


func _run(payload_abs: String, curl: String) -> void:
	var out: Array = []
	var code := OS.execute(curl, [
		"-s", "-m", str(TIMEOUT_SECONDS), "-X", "POST", ENDPOINT,
		"-H", "Content-Type: application/json",
		"-d", "@" + payload_abs,
	], out, true)
	var body := str(out[0]) if out.size() > 0 else ""
	_finish.call_deferred(parse_response(code, body))


func _finish(result: Dictionary) -> void:
	if _thread != null and _thread.is_started():
		_thread.wait_to_finish()
	_thread = null
	completed.emit(result)


# ---------------------------------------------------------------------------
# Proxy transport (web, and any build with no curl)
# ---------------------------------------------------------------------------

## A plain GET. No thread: `HTTPRequest` is already asynchronous, and a web export has no threads
## to use anyway.
func _request_via_proxy(id: String) -> bool:
	if _http == null:
		_http = HTTPRequest.new()
		_http.timeout = float(TIMEOUT_SECONDS)
		add_child(_http)
		_http.request_completed.connect(_on_proxy_completed)
	var url := "%s?id=%s" % [proxy_url(), id.strip_edges().uri_encode()]
	var err := _http.request(url)
	if err != OK:
		completed.emit(_fail("network", "Could not reach the Axie service."))
	return true


func _on_proxy_completed(result: int, code: int, _headers: PackedStringArray,
		body: PackedByteArray) -> void:
	completed.emit(parse_proxy_response(result, code, body.get_string_from_utf8()))


## The proxy answers with the already-unwrapped Axie, not with a GraphQL envelope — so this is a
## separate parser from `parse_response()` rather than a branch inside it. Both produce the same
## result shape, and `t_axie_api` pins that they agree, so a screen never has to know which
## transport it got its Axie from.
static func parse_proxy_response(result: int, code: int, body: String) -> Dictionary:
	if result != HTTPRequest.RESULT_SUCCESS:
		return _fail("network", "Could not reach the Axie service. Check your connection.")
	if code == 404:
		return _fail("not_found", "No Axie with that ID.")
	if code == 429:
		return _fail("rate_limited", "Too many lookups. Wait a minute and try again.")
	if code != 200:
		# 502 deserves its own wording. MEASURED 2026-09-19: an out-of-range id such as 999999999
		# does not come back as a null axie — the gateway answers with an INTERNAL_SERVER_ERROR,
		# which the proxy correctly reports as 502. So a 502 usually means "no such Axie" and
		# occasionally means the service really is down, and there is no way to tell them apart
		# from here. Saying both is honest; picking one would be a guess presented as a fact.
		if code == 502:
			return _fail("upstream",
				"The Axie service could not look that ID up. Check the ID is right — if it is, "
				+ "the service may be having trouble.")
		return _fail("proxy", "The Axie service is not responding correctly (HTTP %d)." % code)

	var parsed = JSON.parse_string(body)
	if not (parsed is Dictionary):
		return _fail("bad_json", "The Axie service sent something unreadable.")
	var d: Dictionary = parsed
	var parts: Array = d.get("parts", []) if d.get("parts") is Array else []
	if d.get("class") == null or parts.is_empty():
		return _fail("not_found", "No Axie with that ID.")
	return {
		"ok": true, "err": "", "message": "",
		"axie": {
			"id": str(d.get("id", "")),
			"class": str(d.get("class", "")),
			# The proxy is expected to publish the 512-bit gene under `genes`. It accepts
			# `newGenes` too, because that is what the gateway itself calls the field and a
			# hand-written proxy is very likely to pass it straight through.
			"genes": str(d.get("genes", d.get("newGenes", ""))),
			"parts": parts,
		},
	}
