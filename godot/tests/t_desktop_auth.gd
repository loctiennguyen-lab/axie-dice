extends Node
## Desktop sign-in pieces that can run headless: PKCE, callback parsing, token store, the Bearer
## transport's refresh-once-and-retry, and a full loopback round trip with a fake browser.

var _fails := 0


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_fails += 1
		print("FAIL ", what)


func _ready() -> void:
	# PKCE: RFC 7636 appendix B vector
	_check(DesktopAuth.challenge_for("dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk") == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM", "PKCE S256 matches RFC 7636 vector")
	var v := DesktopAuth.make_verifier()
	_check(v.length() >= 43 and v.length() <= 128 and v.find("=") < 0 and v.find("+") < 0, "verifier length/charset")
	_check(DesktopAuth.make_verifier() != v, "verifier is random")

	var cb := DesktopAuth.parse_callback("GET /cb?code=abc_DEF-1&state=xyz HTTP/1.1")
	_check(cb.get("code") == "abc_DEF-1" and cb.get("state") == "xyz", "parse code+state")
	_check(DesktopAuth.parse_callback("GET /other?code=a&state=b HTTP/1.1").is_empty(), "other path ignored")
	_check(DesktopAuth.parse_callback("POST /cb?code=a HTTP/1.1").is_empty(), "non-GET ignored")
	_check(DesktopAuth.parse_callback("GET /cb?error=access_denied&state=s HTTP/1.1").get("error") == "access_denied", "parse error")

	var tmp := "user://t_device_tokens.dat"
	DeviceTokens.clear(tmp)
	_check(DeviceTokens.load_tokens(tmp).is_empty(), "no file -> empty")
	_check(DeviceTokens.save({"access": "a", "refresh": "r"}, tmp), "save")
	_check(DeviceTokens.load_tokens(tmp).get("refresh") == "r", "round trip")
	var raw := FileAccess.get_file_as_bytes(tmp)
	_check(raw.size() > 0 and raw.get_string_from_ascii().find("refresh") < 0, "file is not plain text")
	DeviceTokens.clear(tmp)
	_check(DeviceTokens.load_tokens(tmp).is_empty(), "clear")

	await _transport_tests()
	await _loopback_test()
	print("t_desktop_auth: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)


func _transport_tests() -> void:
	var t := DesktopTransport.new()
	add_child(t)
	t.server_url = "https://x"
	var calls: Array = []
	t.tokens = {"access": "A0", "refresh": "R0"}
	# server: A0 expired -> 401; refresh gives A1/R1; A1 works
	t.raw = func(method: String, url: String, headers: PackedStringArray, _body: String, done: Callable) -> void:
		calls.append("%s %s %s" % [method, url, headers[0] if headers.size() > 0 else ""])
		if url.ends_with("/auth/refresh"):
			done.call(200, JSON.stringify({"access": "A1", "refresh": "R1", "device_id": "d"}))
		elif headers[0] == "Authorization: Bearer A1":
			done.call(200, "{}")
		else:
			done.call(401, "")
	var got := []
	t.request("GET", "/api/me", "", func(c: int, _x: String) -> void: got.append(c))
	t.request("GET", "/api/wallet", "", func(c: int, _x: String) -> void: got.append(c))
	_check(got == [200, 200], "401 -> refresh -> retry, both callers succeed")
	var refreshes := calls.filter(func(c: String) -> bool: return c.contains("/auth/refresh")).size()
	_check(refreshes == 1, "one refresh for two concurrent 401s (got %d)" % refreshes)
	_check(t.tokens.get("refresh") == "R1", "rotated refresh kept")
	# refusal clears tokens and reports 401
	var out := []
	t.tokens = {"access": "bad", "refresh": "revoked"}
	t.raw = func(_m: String, _u: String, _h: PackedStringArray, _b: String, done: Callable) -> void: done.call(401, "")
	var flagged := [false]
	t.signed_out.connect(func() -> void: flagged[0] = true)
	t.request("GET", "/api/me", "", func(c: int, _x: String) -> void: out.append(c))
	_check(out == [401] and flagged[0] and not t.is_signed_in(), "refused refresh -> signed_out, tokens cleared")
	DeviceTokens.clear()
	t.free()


func _loopback_test() -> void:
	var a := DesktopAuth.new()
	add_child(a)
	var opened := [""]
	a.open_url = func(u: String) -> void: opened[0] = u
	var exchanged := [""]
	a.exchange = func(_url: String, body: String, done: Callable) -> void:
		exchanged[0] = body
		done.call(200, JSON.stringify({"access": "A", "refresh": "R", "expires_in": 1200, "device_id": "d1"}))
	var result := []
	a.finished.connect(func(ok: bool, tokens: Dictionary, err: String) -> void: result.append([ok, tokens, err]))
	_check(a.begin() == OK, "listener opens")
	var url := String(opened[0])
	_check(url.contains("desktop=1") and url.contains("port=%d" % a.listen_port()) and url.contains("challenge="), "login URL carries challenge and port")
	var state := url.split("state=")[1]
	# play the browser: hit /cb with a wrong state first? the listener takes ONE connection, so use the right one
	var c := StreamPeerTCP.new()
	c.connect_to_host("127.0.0.1", a.listen_port())
	for _i in 200:
		c.poll()
		if c.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			break
		await get_tree().process_frame
	c.put_data(("GET /cb?code=ONETIME&state=%s HTTP/1.1\r\nHost: 127.0.0.1\r\n\r\n" % state).to_utf8_buffer())
	for _i in 300:
		if not result.is_empty():
			break
		await get_tree().process_frame
	_check(result.size() == 1 and result[0][0] == true, "callback -> tokens")
	_check(String(exchanged[0]).contains("ONETIME") and String(exchanged[0]).contains("verifier"), "code + verifier sent to token endpoint")
	_check(result.size() == 1 and result[0][1].get("refresh") == "R", "tokens handed back")
	c.disconnect_from_host()
	a.queue_free()

	# wrong state is refused and no exchange happens
	var b := DesktopAuth.new()
	add_child(b)
	b.open_url = func(_u: String) -> void: pass
	var called := [false]
	b.exchange = func(_u: String, _bd: String, _d: Callable) -> void: called[0] = true
	var res2 := []
	b.finished.connect(func(ok: bool, _t: Dictionary, err: String) -> void: res2.append([ok, err]))
	b.begin()
	var c2 := StreamPeerTCP.new()
	c2.connect_to_host("127.0.0.1", b.listen_port())
	for _i in 200:
		c2.poll()
		if c2.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			break
		await get_tree().process_frame
	c2.put_data("GET /cb?code=X&state=WRONG HTTP/1.1\r\n\r\n".to_utf8_buffer())
	for _i in 300:
		if not res2.is_empty():
			break
		await get_tree().process_frame
	_check(res2.size() == 1 and res2[0] == [false, "state"] and not called[0], "wrong state refused, no token request")
	c2.disconnect_from_host()
	b.queue_free()
