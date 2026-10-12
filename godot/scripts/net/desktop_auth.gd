class_name DesktopAuth
extends Node
## Browser sign-in for the desktop build (ADR-RNG 4.8). The Worker holds the Google secret; this
## node only does the loopback half:
##   1. listen on 127.0.0.1:<random port>, make a PKCE verifier + state
##   2. open the system browser at <server>/auth/login?desktop=1&challenge&port&state
##   3. accept ONE request on /cb, check `state`, answer with a small page, close the listener
##   4. POST {code, verifier} to /auth/desktop/token and hand back the tokens
## No custom URI scheme. The listener never accepts a second connection.
##
## Emits `finished(ok, tokens, error)`: tokens = {access, refresh, expires_in, device_id}.

signal finished(ok: bool, tokens: Dictionary, error: String)

const LOGIN_TIMEOUT_S := 300.0
const PORT_MIN := 49152
const PORT_MAX := 65535

var server_url := "https://axiedice.fun"
## Seam for tests: replaces OS.shell_open so a test can play the browser.
var open_url: Callable = func(u: String) -> void: OS.shell_open(u)
## Seam for the token request: exchange.call(url, json_body, done(code:int, text:String)).
var exchange: Callable

var _tcp: TCPServer
var _verifier := ""
var _state := ""
var _port := 0
var _peer: StreamPeerTCP
var _buf := ""
var _age := 0.0
var _done := false


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
	open_url.call(url)
	set_process(true)
	return OK


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
	if _peer == null and _tcp != null and _tcp.is_connection_available():
		_peer = _tcp.take_connection()
		_tcp.stop()   # one connection only; nobody else can reach the port after this
	if _peer == null:
		return
	_peer.poll()
	if _peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		if _peer.get_status() == StreamPeerTCP.STATUS_ERROR:
			_finish(false, {}, "network")
		return
	var n := _peer.get_available_bytes()
	if n > 0:
		_buf += _peer.get_utf8_string(n)
	if _buf.length() > 8192:
		_finish(false, {}, "bad_request")
	elif _buf.find("\r\n") >= 0:
		_handle_request(_buf.substr(0, _buf.find("\r\n")))


func _handle_request(line: String) -> void:
	var cb := parse_callback(line)
	var ok := not cb.is_empty() and String(cb["state"]) == _state
	_reply_page(ok and String(cb["error"]).is_empty())
	if not ok:
		_finish(false, {}, "state")
		return
	if not String(cb["error"]).is_empty():
		_finish(false, {}, String(cb["error"]))
		return
	var code := String(cb["code"])
	if code.is_empty():
		_finish(false, {}, "bad_request")
		return
	_done = true   # stop polling; the exchange below is async
	_close_peer()
	exchange.call(server_url + "/auth/desktop/token",
		JSON.stringify({"code": code, "verifier": _verifier, "label": OS.get_name()}),
		func(http: int, text: String) -> void:
			var parsed: Variant = JSON.parse_string(text)
			if http == 200 and typeof(parsed) == TYPE_DICTIONARY and (parsed as Dictionary).has("refresh"):
				_emit(true, parsed, "")
			else:
				_emit(false, {}, "token"))


func _reply_page(ok: bool) -> void:
	var body := "<html><body style='font-family:sans-serif;text-align:center;margin-top:20vh'><h2>%s</h2></body></html>" \
		% ("Signed in. You can close this tab and go back to the game." if ok else "Sign-in did not work. Go back to the game and try again.")
	var resp := "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: %d\r\nConnection: close\r\nCache-Control: no-store\r\n\r\n%s" \
		% [body.to_utf8_buffer().size(), body]
	_peer.put_data(resp.to_utf8_buffer())


func _close_peer() -> void:
	if _peer != null:
		_peer.disconnect_from_host()
		_peer = null


func _finish(ok: bool, tokens: Dictionary, error: String) -> void:
	_done = true
	_close_peer()
	_emit(ok, tokens, error)


func _emit(ok: bool, tokens: Dictionary, error: String) -> void:
	_done = true
	if _tcp != null:
		_tcp.stop()
	set_process(false)
	finished.emit(ok, tokens, error)
