class_name RemoteLeaderboardSource
extends RefCounted
## Client side of the Worker leaderboard (L1 C2; worker/src/leaderboard.js). Pure transport, no UI.
## The Leaderboard screen (lane L) can wrap this behind its own LeaderboardSource interface.
##
## JSON contract (all callbacks get (ok: bool, data: Dictionary); on failure data = {code}):
##   fetch(board, mode, ascension, limit, done)
##     GET /api/leaderboard?board=season|daily&mode=short|full&asc=0..10&limit=1..100
##     -> {season, board, mode, ascension, day, entries:[{rank, name, score, won}], self:{rank, score}|null, total}
##   submit_run(run_id, done)
##     POST /api/leaderboard/submit {run_id} -> {ok, score, season, mode, ascension, rank}
##     errors: not_closed (409) | not_ranked (403) | bad_score / no_battles (422) | not_found (404) | unauthenticated (401)
## `self` is null for a guest or a player with no score on that board. Ranks are competition ranks (ties share).

## Tests: replaces AccountService.transport. Signature (method, path, body, cb(code, text)).
var http: Callable = Callable()


func _transport() -> Callable:
	return http if http.is_valid() else AccountService.transport


func fetch(board: String, mode: String, ascension: int, limit: int, done: Callable) -> void:
	var path := "/api/leaderboard?board=%s&mode=%s&asc=%d&limit=%d" % [
		"daily" if board == "daily" else "season", "full" if mode == "full" else "short",
		clampi(ascension, 0, 10), clampi(limit, 1, 100)]
	_transport().call("GET", path, "", func(code: int, text: String) -> void: _answer(code, text, done))


func submit_run(run_id: String, done: Callable) -> void:
	_transport().call("POST", "/api/leaderboard/submit", JSON.stringify({"run_id": run_id}),
		func(code: int, text: String) -> void: _answer(code, text, done))


static func _answer(code: int, text: String, done: Callable) -> void:
	var j: Variant = JSON.parse_string(text) if not text.is_empty() else null
	if code == 200 and typeof(j) == TYPE_DICTIONARY:
		done.call(true, j)
		return
	var err := "offline" if code == 0 else "server"
	if typeof(j) == TYPE_DICTIONARY and (j as Dictionary).has("error"):
		err = String((j as Dictionary)["error"])
	done.call(false, {"code": err})
