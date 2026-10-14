class_name RemoteLeaderboardAdapter
extends LeaderboardSource
## Thin adapter: LeaderboardSource over RemoteLeaderboardSource (scripts/net, GET /api/leaderboard).
## period season -> board=season, today -> board=daily; asc passes through; mode defaults to short.
## Entries map {rank, name, score, won} 1:1; `self` becomes `me` (no name: the screen fills it in).

const LIMIT := 100

var remote := RemoteLeaderboardSource.new()


func fetch(query: Dictionary, cb: Callable) -> void:
	var board := "daily" if String(query.get("period", "season")) == "today" else "season"
	remote.fetch(board, String(query.get("mode", "short")), int(query.get("asc", 0)), LIMIT,
		func(ok: bool, data: Dictionary) -> void: cb.call(map_result(ok, data)))


static func map_result(ok: bool, data: Dictionary) -> Dictionary:
	if not ok:
		var code := String(data.get("code", "server"))
		return {"ok": false, "reason": "offline" if code == "offline" else "error", "rows": [], "me": {}, "updated": ""}
	var rows: Array = []
	for e in (data.get("entries", []) as Array):
		var d := e as Dictionary
		var r := {"rank": int(d.get("rank", 0)), "name": String(d.get("name", "")), "score": int(d.get("score", 0))}
		if d.has("won"):
			r["won"] = bool(d["won"])
		rows.append(r)
	var me := {}
	var s = data.get("self", null)
	if s is Dictionary:
		me = {"rank": int((s as Dictionary).get("rank", 0)), "score": int((s as Dictionary).get("score", 0))}
	var t := Time.get_time_dict_from_system()
	return {"ok": true, "reason": "", "rows": rows, "me": me, "updated": "%02d:%02d" % [t["hour"], t["minute"]]}
