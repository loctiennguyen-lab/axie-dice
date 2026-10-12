class_name RemoteGemWallet
extends GemWallet
## GemWallet backed by the Worker (D1 ledger is the only truth; this object is a display cache).
## Same signatures as LocalGemWallet so nobody else changes; the network is async, so:
##   * balance()   returns the cache. Call refresh() (or listen to `balance_changed`) to update it.
##   * spend()     optimistic: checks the cache, lowers it, sends POST /api/wallet/spend in the
##                 background with an idempotency key; if the server says no, the cache is
##                 corrected and `spend_failed` is emitted. Aid/Continue inside a run are NOT spent
##                 here: the RunDO charges them inside epoch_req, so the client never pays twice.
##   * grant()     does nothing and warns: Gem only comes from the server (claim, season gift).
##   * claim_daily_gift()  cannot return the answer synchronously. It starts the claim and returns
##                 reason "pending"; use claim_daily_gift_async(done) for the real result.
## DEVIATION from the sync GemWallet contract (lane E): the claim result and spend confirmation are
## asynchronous. UI that shows "claimed +300" should use the async call or `balance_changed`.

signal balance_changed(balance: int)
signal spend_failed(reason: String, balance: int)

## transport.call(method, path, body_text, done(code:int, text:String)): the same callable
## AccountService uses (Bearer on desktop, cookie on web).
var transport: Callable
var _balance := 0
var _next_claim_utc := 0
var _spend_seq := 0


func _init(p_transport: Callable = Callable()) -> void:
	transport = p_transport


func balance() -> int:
	return _balance


func next_claim_utc() -> int:
	return _next_claim_utc


func refresh(done: Callable = Callable()) -> void:
	transport.call("GET", "/api/wallet", "", func(code: int, text: String) -> void:
		var ok := false
		if code == 200:
			var j: Variant = JSON.parse_string(text)
			if typeof(j) == TYPE_DICTIONARY and (j as Dictionary).has("gem"):
				_set_balance(int(j["gem"]))
				ok = true
		if done.is_valid():
			done.call(ok))


func spend(n: int, reason: String) -> bool:
	if n < 0 or _balance < n:
		return false
	if n == 0:
		return true
	_set_balance(_balance - n)
	var body := JSON.stringify({"amount": n, "reason": _clean_reason(reason), "idem": _new_idem()})
	transport.call("POST", "/api/wallet/spend", body, func(code: int, text: String) -> void:
		var j: Variant = JSON.parse_string(text) if not text.is_empty() else null
		var bal: Variant = (j as Dictionary).get("balance") if typeof(j) == TYPE_DICTIONARY else null
		if code == 200:
			if bal != null:
				_set_balance(int(bal))
		else:
			# Refused (402) or never arrived: the optimistic drop was wrong, take the server's number.
			if bal != null:
				_set_balance(int(bal))
			else:
				refresh()
			spend_failed.emit(reason, _balance))
	return true


func grant(_n: int, tag: String) -> void:
	push_warning("RemoteGemWallet.grant(%s): Gem is granted by the server only; ignored" % tag)


func claim_daily_gift(now_unix: int) -> Dictionary:
	claim_daily_gift_async(Callable())
	return {"ok": false, "granted": 0, "reason": "pending", "next_utc": GemWallet.next_utc_midnight(now_unix)}


## done(result:Dictionary) with {ok, granted, reason, next_utc}; reason "" | "already_claimed" | "at_cap" | "offline".
func claim_daily_gift_async(done: Callable) -> void:
	transport.call("POST", "/api/gem/claim", "", func(code: int, text: String) -> void:
		var out := {"ok": false, "granted": 0, "reason": "offline", "next_utc": 0}
		var j: Variant = JSON.parse_string(text) if not text.is_empty() else null
		if code == 200 and typeof(j) == TYPE_DICTIONARY:
			var d: Dictionary = j
			out = {"ok": bool(d.get("ok", false)), "granted": int(d.get("granted", 0)),
				"reason": String(d.get("reason", "")), "next_utc": int(d.get("next_utc", 0))}
			_next_claim_utc = int(out["next_utc"])
			if d.has("balance"):
				_set_balance(int(d["balance"]))
		if done.is_valid():
			done.call(out))


func _set_balance(v: int) -> void:
	if v == _balance:
		return
	_balance = v
	balance_changed.emit(v)


## Server pattern: [a-z0-9_:.-]{1,48}.
static func _clean_reason(r: String) -> String:
	var out := ""
	for ch in r.to_lower():
		out += ch if "abcdefghijklmnopqrstuvwxyz0123456789_:.-".contains(ch) else "_"
	return out.substr(0, 48) if not out.is_empty() else "spend"


## Idempotency key: server pattern [A-Za-z0-9_-]{8,64}. Random, so each purchase is its own operation.
func _new_idem() -> String:
	_spend_seq += 1
	return "%s_%d" % [Marshalls.raw_to_base64(Crypto.new().generate_random_bytes(12)).replace("+", "-").replace("/", "_").replace("=", ""), _spend_seq]
