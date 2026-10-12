class_name DesktopTransport
extends Node
## HTTP for the desktop build: sends the access token as `Authorization: Bearer`, and on a 401
## refreshes once (POST /auth/refresh) and retries. Same call shape AccountService already uses:
##   request(method, path, body_text, done(code:int, text:String))
## code 0 = never reached the server. One refresh at a time: callers that hit a 401 meanwhile wait.
##
## Tokens are kept by DeviceTokens. A refresh the server refuses (revoked or reused) clears them and
## reports 401 upward, which AccountService shows as "session expired".

signal signed_out

var server_url := "https://axiedice.fun"
var tokens: Dictionary = {}
## Seam for tests: raw.call(method, url, headers:PackedStringArray, body, done(code, text)).
var raw: Callable = _http

var _refreshing := false
var _waiting: Array = []


func is_signed_in() -> bool:
	return String(tokens.get("refresh", "")) != ""


func request(method: String, path: String, body: String, done: Callable) -> void:
	if not is_signed_in():
		done.call(401, "")
		return
	_send(method, path, body, done, true)


func _send(method: String, path: String, body: String, done: Callable, may_refresh: bool) -> void:
	var headers := PackedStringArray(["Authorization: Bearer " + String(tokens.get("access", "")),
		"Content-Type: application/json"])
	raw.call(method, server_url + path, headers, body, func(code: int, text: String) -> void:
		if code == 401 and may_refresh:
			_refresh_then(func(ok: bool) -> void:
				if ok:
					_send(method, path, body, done, false)
				else:
					done.call(401, text))
		else:
			done.call(code, text))


func _refresh_then(next: Callable) -> void:
	_waiting.append(next)
	if _refreshing:
		return
	_refreshing = true
	raw.call("POST", server_url + "/auth/refresh", PackedStringArray(["Content-Type: application/json"]),
		JSON.stringify({"refresh": String(tokens.get("refresh", ""))}),
		func(code: int, text: String) -> void:
			var parsed: Variant = JSON.parse_string(text) if not text.is_empty() else null
			var ok := code == 200 and typeof(parsed) == TYPE_DICTIONARY and (parsed as Dictionary).has("refresh")
			if ok:
				tokens = parsed
				DeviceTokens.save(tokens)
			elif code == 401:
				tokens = {}
				DeviceTokens.clear()
				signed_out.emit()
			_refreshing = false
			var queue := _waiting
			_waiting = []
			for cb: Callable in queue:
				cb.call(ok))


func _http(method: String, url: String, headers: PackedStringArray, body: String, done: Callable) -> void:
	var req := HTTPRequest.new()
	req.timeout = 12.0
	add_child(req)
	req.request_completed.connect(func(result: int, code: int, _h: PackedStringArray, data: PackedByteArray) -> void:
		req.queue_free()
		done.call(code if result == HTTPRequest.RESULT_SUCCESS else 0, data.get_string_from_utf8()))
	var m := HTTPClient.METHOD_GET
	match method:
		"POST": m = HTTPClient.METHOD_POST
		"PUT": m = HTTPClient.METHOD_PUT
		"DELETE": m = HTTPClient.METHOD_DELETE
	if req.request(url, headers, m, body) != OK:
		req.queue_free()
		done.call(0, "")
