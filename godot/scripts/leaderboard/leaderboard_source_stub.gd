class_name LeaderboardSourceStub
extends LeaderboardSource
## In-memory source for tests, QA captures and offline preview. `boards` maps
## LeaderboardSource.query_key(query) -> {"rows": [...], "me": {...}}; a missing key answers an
## empty board. `fail_reason` != "" answers a failure. `pending` = true keeps the callback until
## release() so tests can look at the loading state.

var boards: Dictionary = {}
var fail_reason := ""
var updated := "14:02"
var pending := false
var calls: Array[Dictionary] = []
var _held: Array = []


func fetch(query: Dictionary, cb: Callable) -> void:
	calls.append(query.duplicate())
	var res := _answer(query)
	if pending:
		_held.append([cb, res])
	else:
		cb.call(res)


func release() -> void:
	var h := _held
	_held = []
	for e in h:
		(e[0] as Callable).call(e[1])


func _answer(query: Dictionary) -> Dictionary:
	if fail_reason != "":
		return {"ok": false, "reason": fail_reason, "rows": [], "me": {}, "updated": updated}
	var b: Dictionary = boards.get(LeaderboardSource.query_key(query), {})
	return {"ok": true, "reason": "", "rows": b.get("rows", []), "me": b.get("me", {}), "updated": updated}
