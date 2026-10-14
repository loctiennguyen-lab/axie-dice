class_name LeaderboardSource
extends RefCounted
## Client interface for the Leaderboard screen (R3 M9). The screen never talks to the network; it
## asks a LeaderboardSource. This base class is the "no endpoint yet" source: every fetch answers
## {ok: false, reason: "no_endpoint"}. Lane M's Worker endpoints will come as a subclass that
## overrides fetch(); tests and offline use LeaderboardSourceStub.
##
## query  = {"asc": int 0..10, "filter": "pure" | "all" | "mission", "period": "today" | "week" | "season"}
## result = {
##   "ok": bool,
##   "reason": String,            # when not ok: "no_endpoint" | "offline" | "error"
##   "rows": Array[Dictionary],   # see ROW
##   "me": Dictionary,            # same shape as a row, {} when the player has no entry
##   "updated": String,           # "14:02", shown as "Last updated 14:02"
## }
## ROW = {"rank": int, "name": String, "land": String (tier name), "aid": String ("" = Pure,
##   "Aid" = used Aid, "N2" = mission tier), "score": int, "mode": String, "date": String,
##   "detail": {"summary": String, "party": Array[String] hero keys, "aid_note": String}}
## cb is called exactly once, now or later; the screen ignores answers to superseded queries.

const FILTERS := ["pure", "all", "mission"]
const PERIODS := ["today", "week", "season"]


## Base implementation: nothing to ask yet.
func fetch(_query: Dictionary, cb: Callable) -> void:
	cb.call({"ok": false, "reason": "no_endpoint", "rows": [], "me": {}, "updated": ""})


static func query_key(q: Dictionary) -> String:
	return "%d|%s|%s" % [int(q.get("asc", 0)), String(q.get("filter", "pure")), String(q.get("period", "week"))]
