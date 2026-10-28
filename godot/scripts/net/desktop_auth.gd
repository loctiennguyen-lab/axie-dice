class_name DesktopAuth
extends Node
## Browser sign-in for the desktop build (ADR-RNG 4.8). The Worker holds the Google secret; this
## node only does the loopback half:
##   1. listen on 127.0.0.1:<random port>, make a PKCE verifier + state
##   2. open the system browser at <server>/auth/login?desktop=1&challenge&port&state
##   3. keep accepting until a GET /cb with our `state` arrives (browsers preconnect and ask for
##      /favicon.ico), answer with a small page, then close the listener
##   4. POST {code, verifier} to /auth/desktop/token and hand back the tokens
## No custom URI scheme. Requests with a wrong `state` or another path never end the flow.
##
## Emits `finished(ok, tokens, error)`: tokens = {access, refresh, expires_in, device_id}.

signal finished(ok: bool, tokens: Dictionary, error: String)
## A valid /cb arrived (state matched, code present). The token exchange is now in flight.
signal callback_received

const LOGIN_TIMEOUT_S := 300.0
const PORT_MIN := 49152
const PORT_MAX := 65535
const MAX_PEERS := 8
const PEER_TIMEOUT_S := 20.0

var server_url := "https://axiedice.fun"
## Seam for tests: replaces OS.shell_open so a test can play the browser.
## Device name shown in /auth/devices; empty = OS name. Only live_smoke --login sets it ("Smoke").
static var label_override := ""
var open_url: Callable = func(u: String) -> void: OS.shell_open(u)
## Seam for the token request: exchange.call(url, json_body, done(code:int, text:String)).
var exchange: Callable

var _tcp: TCPServer
var _verifier := ""
var _state := ""
var _port := 0
var _peers: Array = []   # [{peer, buf, age}]
var _age := 0.0
var _done := false
var _url := ""
var _saved_low_cpu := false
var _power_held := false
var _cpu_held := false
## Seam for tests: brings the game window to the front once the browser has called back.
var raise_window: Callable = func() -> void: DesktopAuth.raise_game_window()


static func make_verifier() -> String:
	return _b64url(Crypto.new().generate_random_bytes(48))   # 64 chars, within PKCE's 43..128


static func challenge_for(verifier: String) -> String:
	return _b64url(verifier.sha256_buffer())


static func _b64url(b: PackedByteArray) -> String:
	return Marshalls.raw_to_base64(b).replace("+", "-").replace("/", "_").replace("=", "")


## {code, state, error} from the request line of the loopback hit, or {} if it is not GET /cb.
static func parse_callback(request_line: String) -> Dictionary:
	var parts := request_line.strip_edges().split(" ")
	if parts.size() < 2 or parts[0] != "GET":
		return {}
	var target := parts[1]
	var q := target.find("?")
	var path := target if q < 0 else target.substr(0, q)
	if path != "/cb":
		return {}
	var out := {"code": "", "state": "", "error": ""}
	if q >= 0:
		for pair in target.substr(q + 1).split("&"):
			var kv := pair.split("=", true, 1)
			if kv.size() == 2 and out.has(kv[0]):
				out[kv[0]] = String(kv[1]).uri_decode()
	return out


## Brings the game window in front of the browser and, if the OS refuses to hand over focus
## (macOS 14+ often does), bounces the dock icon / flashes the taskbar entry instead.
static func raise_game_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_move_to_foreground()
	DisplayServer.window_request_attention()


## The page the browser tab shows after /cb (and for errors). Static text, no external assets.
static func page_html(title: String, detail: String, ok: bool) -> String:
	var accent := "#2F8F4E" if ok else "#B2432B"
	var mark := "&#10003;" if ok else "!"
	return ("<!doctype html><html lang='en'><head><meta charset='utf-8'><title>Axie Dice</title>"
		+ "<meta name='viewport' content='width=device-width,initial-scale=1'>"
		+ "<style>body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;"
		+ "background:#F6E7C8;font-family:-apple-system,'Segoe UI',Roboto,sans-serif;color:#3A2214}"
		+ ".card{background:#FFF6E0;border:4px solid #8A3E22;border-radius:24px;padding:40px 48px;"
		+ "max-width:460px;text-align:center;box-shadow:4px 6px 0 rgba(74,34,14,.35)}"
		+ ".mark{width:72px;height:72px;line-height:72px;border-radius:50%%;margin:0 auto 18px;"
		+ "background:%s;color:#fff;font-size:40px;font-weight:800;border:3px solid #24140B}"
		+ "h1{font-size:26px;margin:0 0 10px}p{font-size:17px;margin:0;line-height:1.45}"
		+ "small{display:block;margin-top:18px;font-size:13px;opacity:.7}</style></head><body>"
		+ "<div class='card'><div class='mark'>%s</div><h1>%s</h1><p>%s</p>"
		+ "<small>Axie Dice</small></div></body></html>") % [accent, mark, title, detail]


## Starts the flow. Returns OK, or an Error if no loopback port could be opened.
func begin() -> int:
	_tcp = TCPServer.new()
	var err := ERR_CANT_CREATE
	for _i in 20:
		_port = randi_range(PORT_MIN, PORT_MAX)
		err = _tcp.listen(_port, "127.0.0.1")
		if err == OK:
			break
	if err != OK:
		return err
	_verifier = make_verifier()
	_state = _b64url(Crypto.new().generate_random_bytes(24))
	var url := "%s/auth/login?desktop=1&challenge=%s&port=%d&state=%s" \
		% [server_url, challenge_for(_verifier), _port, _state]
	_url = url
	# Keep the loop at full rate while the player is in the browser: the /cb accept loop is in _process.
	_saved_low_cpu = OS.low_processor_usage_mode
	_cpu_held = true
	OS.low_processor_usage_mode = false
	if DisplayServer.get_name() != "headless":
		DisplayServer.screen_set_keep_on(true)
		_power_held = true
	open_url.call(url)
	set_process(true)
	return OK


## Opens the same login URL again (same port/state/verifier) while still waiting.
func reopen() -> void:
	if not _done and _url != "":
		open_url.call(_url)


func cancel() -> void:
	if not _done:
		_emit(false, {}, "cancelled")


func listen_port() -> int:
	return _port


func _process(delta: float) -> void:
	if _done:
		return
	_age += delta
	if _age > LOGIN_TIMEOUT_S:
		_finish(false, {}, "timeout")
		return
	# Browsers open speculative connections (Chrome preconnect) and fetch /favicon.ico, so the listener
	# keeps accepting until a valid GET /cb with our `state` arrives. Everything else gets a 404.
	while _tcp != null and _tcp.is_connection_available() and _peers.size() < MAX_PEERS:
		_peers.append({"peer": _tcp.take_connection(), "buf": "", "age": 0.0})
	for entry in _peers.duplicate():
		if _done:
			return
		_service_peer(entry, delta)


func _service_peer(entry: Dictionary, delta: float) -> void:
	var peer: StreamPeerTCP = entry["peer"]
	peer.poll()
	entry["age"] = float(entry["age"]) + delta
	var st := peer.get_status()
	if st == StreamPeerTCP.STATUS_ERROR or st == StreamPeerTCP.STATUS_NONE or float(entry["age"]) > PEER_TIMEOUT_S:
		_drop(entry)
		return
	if st != StreamPeerTCP.STATUS_CONNECTED:
		return
	var n := peer.get_available_bytes()
	if n > 0:
		entry["buf"] = String(entry["buf"]) + peer.get_utf8_string(n)
	var buf := String(entry["buf"])
	if buf.length() > 8192:
		_drop(entry)
	elif buf.find("\r\n") >= 0:
		_handle_request(entry, buf.substr(0, buf.find("\r\n")))


func _handle_request(entry: Dictionary, line: String) -> void:
	var peer: StreamPeerTCP = entry["peer"]
	var cb := parse_callback(line)
	if cb.is_empty() or String(cb["state"]) != _state:
		_reply(peer, 404 if cb.is_empty() else 400, "Not the sign-in page", "This address only works for the Axie Dice sign-in.", false)
		_drop(entry)
		return
	if not String(cb["error"]).is_empty():
		_reply(peer, 200, "Sign-in did not finish", "Go back to Axie Dice and try again.", false)
		_drop(entry)
		raise_window.call()
		_finish(false, {}, String(cb["error"]))
		return
	var code := String(cb["code"])
	if code.is_empty():
		_reply(peer, 400, "Sign-in did not finish", "The sign-in answer was empty. Go back to Axie Dice and try again.", false)
		_drop(entry)
		return
	_reply(peer, 200, "Signed in \u2014 you can return to Axie Dice", "You can close this tab. The game is already waiting for you.", true)
	_drop(entry)
	_done = true   # stop polling; the exchange below is async
	_stop_listening()
	raise_window.call()
	callback_received.emit()
	exchange.call(server_url + "/auth/desktop/token",
		JSON.stringify({"code": code, "verifier": _verifier, "label": label_override if label_override != "" else OS.get_name()}),
		func(http: int, text: String) -> void:
			var parsed: Variant = JSON.parse_string(text)
			if http == 200 and typeof(parsed) == TYPE_DICTIONARY and (parsed as Dictionary).has("refresh"):
				_emit(true, parsed, "")
			else:
				_emit(false, {}, "token"))


func _reply(peer: StreamPeerTCP, status: int, title: String, detail: String, ok: bool) -> void:
	var body := page_html(title, detail, ok)
	var resp := "HTTP/1.1 %d %s\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: %d\r\nConnection: close\r\nCache-Control: no-store\r\n\r\n%s" \
		% [status, "OK" if status == 200 else "Error", body.to_utf8_buffer().size(), body]
	peer.put_data(resp.to_utf8_buffer())


func _drop(entry: Dictionary) -> void:
	var peer: StreamPeerTCP = entry["peer"]
	# Read what the browser still has in flight: closing a socket with unread bytes makes the OS send a
	# reset, and the browser may then throw the page away instead of showing it.
	peer.poll()
	if peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		var left := peer.get_available_bytes()
		if left > 0:
			peer.get_data(left)
	peer.disconnect_from_host()
	_peers.erase(entry)


func _stop_listening() -> void:
	for entry in _peers.duplicate():
		_drop(entry)
	if _tcp != null:
		_tcp.stop()


func _finish(ok: bool, tokens: Dictionary, error: String) -> void:
	_done = true
	_emit(ok, tokens, error)


func _emit(ok: bool, tokens: Dictionary, error: String) -> void:
	_done = true
	set_process(false)
	_release()
	finished.emit(ok, tokens, error)


## Closes the listener and gives back the power settings taken in begin(). Safe to call twice.
func _release() -> void:
	_stop_listening()
	if _cpu_held:
		OS.low_processor_usage_mode = _saved_low_cpu
		_cpu_held = false
	if _power_held:
		DisplayServer.screen_set_keep_on(false)
		_power_held = false


## The node can be freed mid-flow (scene change, quit): never leave the port open or the screen forced on.
func _exit_tree() -> void:
	_done = true
	_release()
