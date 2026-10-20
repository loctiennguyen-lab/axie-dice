class_name RaidClient
extends RefCounted
## Client side of the Worker raid endpoints (lane RV; worker/src/raid.js). Pure transport, no UI.
## All callbacks get (ok: bool, data: Dictionary); on failure data = {code} (offline | server | the Worker's error).
##   save_defense(team, skin, power_hint, done)  POST /api/raid/defense  -> {ok, ghost_id}
##   opponents(done)                             GET  /api/raid/opponents -> {opponents:[{ghost_id,name,team,skin,power_hint}], points}
##   start(ghost_id, done)                       POST /api/raid/start     -> {challenge_id, seed, team, skin, name}
##   finish(challenge_id, won, turns, h, done)   POST /api/raid/finish    -> {ok, points, counted, reason?, total, badge?}
## Raid is online-only: with no session the Worker answers 401 -> code "unauthenticated".

## Tests: replaces AccountService.transport. Signature (method, path, body, cb(code, text)).
var http: Callable = Callable()


func _transport() -> Callable:
	return http if http.is_valid() else AccountService.transport


func save_defense(team: Array, skin: Dictionary, power_hint: int, done: Callable) -> void:
	_post("/api/raid/defense", {"team": team, "skin": skin, "power_hint": clampi(power_hint, 0, 9999)}, done)


func opponents(done: Callable) -> void:
	_call("GET", "/api/raid/opponents", "", done)


func start(ghost_id: String, done: Callable) -> void:
	_post("/api/raid/start", {"ghost_id": ghost_id}, done)


func finish(challenge_id: String, won: bool, turns: int, h: String, done: Callable) -> void:
	_post("/api/raid/finish", {"challenge_id": challenge_id, "won": won, "turns": clampi(turns, 1, 60), "h": h}, done)


## 64-hex digest the Worker stores with the result (it only checks the shape today: no replay yet).
static func result_hash(challenge_id: String, seed: int, won: bool, turns: int) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(("%s|%d|%d|%d" % [challenge_id, seed, 1 if won else 0, turns]).to_utf8_buffer())
	return ctx.finish().hex_encode()


func _post(path: String, body: Dictionary, done: Callable) -> void:
	_call("POST", path, JSON.stringify(body), done)


func _call(method: String, path: String, body: String, done: Callable) -> void:
	if NetGuard.blocked() and not http.is_valid():
		done.call(false, {"code": "offline"})
		return
	_transport().call(method, path, body, func(code: int, text: String) -> void: _answer(code, text, done))


static func _answer(code: int, text: String, done: Callable) -> void:
	var parser := JSON.new()   # not parse_string: garbage bodies (HTML error pages) must not log engine errors
	var j: Variant = parser.data if not text.is_empty() and parser.parse(text) == OK else null
	if code == 200 and typeof(j) == TYPE_DICTIONARY:
		done.call(true, j)
		return
	var err := "offline" if code == 0 else "server"
	if typeof(j) == TYPE_DICTIONARY and (j as Dictionary).has("error"):
		err = String((j as Dictionary)["error"])
	done.call(false, {"code": err})
