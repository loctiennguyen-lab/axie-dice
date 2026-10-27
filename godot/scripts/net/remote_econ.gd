class_name RemoteEcon
extends RefCounted
## Server economy client (SR1). D1 is the only truth for Shard / Stone / ticket / unlock / Echo Box pity;
## MetaState keeps a DISPLAY CACHE that this class overwrites from every server answer
## (MetaState.apply_server_econ -> SaveStore). Nothing here changes a balance on its own: the client sends
## the request, waits, and shows what the server says (Echo Box results included).
##   GET  /api/econ                    -> snapshot
##   POST /api/econ/spend  {sku, req_id}   sku "unlock:<id>" | "ticket:<n>"
##   POST /api/econ/claim  {kind, run_id?, amount?}   kind daily|daily_run|weekly|run
##   POST /api/echobox/open {req_id}
## Every done(r) gets {ok:bool, code:String, dup:bool, result:Dictionary, net:bool}. `net` is false only when
## the request never got an answer (offline): nothing was spent, nothing is shown as spent.

## transport.call(method, path, body_text, done(code:int, text:String)): same callable AccountService uses.
var transport: Callable
var _seq := 0
var busy := 0


func _init(p_transport: Callable = Callable()) -> void:
	transport = p_transport


func refresh(done: Callable = Callable()) -> void:
	_call("GET", "/api/econ", "", done)


func buy_unlock(id: String, done: Callable = Callable()) -> void:
	_call("POST", "/api/econ/spend", JSON.stringify({"sku": "unlock:" + id, "req_id": new_req_id()}), done)


func buy_tickets(n: int, done: Callable = Callable()) -> void:
	_call("POST", "/api/econ/spend", JSON.stringify({"sku": "ticket:%d" % n, "req_id": new_req_id()}), done)


## kind: "daily" | "daily_run" | "weekly" | "run" (run needs run_id + amount).
func claim(kind: String, extra: Dictionary = {}, done: Callable = Callable()) -> void:
	var b := extra.duplicate()
	b["kind"] = kind
	_call("POST", "/api/econ/claim", JSON.stringify(b), done)


func open_box(done: Callable = Callable()) -> void:
	_call("POST", "/api/echobox/open", JSON.stringify({"req_id": new_req_id()}), done)


func _call(method: String, path: String, body: String, done: Callable) -> void:
	busy += 1
	transport.call(method, path, body, func(code: int, text: String) -> void:
		busy -= 1
		var r := {"ok": false, "code": "offline", "dup": false, "result": {}, "net": false}
		var j: Variant = JSON.parse_string(text) if not text.is_empty() else null
		if code > 0 and typeof(j) == TYPE_DICTIONARY:
			var d: Dictionary = j
			r["net"] = true
			if d.has("shard"):
				MetaState.apply_server_econ(d)   # wins over the cache even on a refusal: it is the truth
			if code == 200 and (d.get("ok", true) != false):
				r["ok"] = true
				r["code"] = ""
				r["dup"] = bool(d.get("dup", false))
				r["result"] = d.get("result", {})
			else:
				r["code"] = String(d.get("code", d.get("error", "server")))
		elif code == 401:
			r["code"] = "unauthenticated"
		if done.is_valid():
			done.call(r))


## Idempotency key, server pattern [A-Za-z0-9_-]{8,64}. Random: each purchase is its own operation.
func new_req_id() -> String:
	_seq += 1
	return "%s_%d" % [Marshalls.raw_to_base64(Crypto.new().generate_random_bytes(12)).replace("+", "-").replace("/", "_").replace("=", ""), _seq]


static func message_for(code: String) -> String:
	match code:
		"insufficient": return "Not enough Shards."
		"no_tickets": return "No tickets left."
		"owned": return "Already owned."
		"day_cap": return "Daily ticket limit reached."
		"hold_cap": return "You can hold at most 999 tickets."
		"conflict": return "Something else changed your balance. Try again."
		"offline": return "Can't reach the server. Nothing was spent."
		"unauthenticated": return "Sign in to use your wallet."
		"no_run_today": return "Finish a run first."
		"not_enough_days": return "Not enough daily claims this week."
		"not_reached": return "Not reached yet."
		"out_of_season": return "The Pass season is not running."
		"not_done": return "That task is not finished yet."
		"nothing_to_claim": return "Nothing to claim."
		"run_not_closed": return "The run is not closed on the server yet."
		_: return "The server refused this (%s). Nothing was spent." % code
