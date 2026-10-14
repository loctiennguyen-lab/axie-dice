class_name LeaderboardSource
extends RefCounted
## Client interface for the Leaderboard screen (R3 M9, L1 boards decided by Liam: Season and Today,
## one board per Ascension A0-A10, no Week, no Pure/All/Mission filters). The screen never talks to
## the network; it asks a LeaderboardSource. This base class is the "no endpoint" source (answers
## {ok: false, reason: "no_endpoint"}); make_default() picks RemoteLeaderboardAdapter when the
## account transport is up. Tests and QA use LeaderboardSourceStub.
##
## query  = {"asc": int 0..10, "period": "season" | "today", "mode": "short" | "full" (optional, default "short")}
## result = {
##   "ok": bool,
##   "reason": String,            # when not ok: "no_endpoint" | "offline" | "error"
##   "rows": Array[Dictionary],   # ROW
##   "me": Dictionary,            # ROW-shaped ({rank, score, name?}), {} when the player has no entry
##   "updated": String,           # "14:02", shown as "Last updated 14:02"
## }
## ROW = {"rank": int, "name": String, "score": int} plus OPTIONAL "won": bool, "land": String,
##   "aid": String, "mode": String, "date": String, "detail": {"summary", "party": [hero keys], "aid_note"}.
## The screen draws a column only when some row carries that field, so a server that sends just
## rank/name/score/won gets a four-column table with no blanks.
## cb is called exactly once, now or later; the screen ignores answers to superseded queries.

const PERIODS := ["season", "today"]


## Base implementation: nothing to ask.
func fetch(_query: Dictionary, cb: Callable) -> void:
	cb.call({"ok": false, "reason": "no_endpoint", "rows": [], "me": {}, "updated": ""})


static func query_key(q: Dictionary) -> String:
	return "%d|%s" % [int(q.get("asc", 0)), String(q.get("period", "season"))]


## The Worker-backed source when the account transport exists, else the no-endpoint base.
static func make_default() -> LeaderboardSource:
	var loop := Engine.get_main_loop()
	var a: Node = (loop as SceneTree).root.get_node_or_null("AccountService") if loop is SceneTree else null
	if a != null and (a.get("transport") as Callable).is_valid():
		return RemoteLeaderboardAdapter.new()
	return LeaderboardSource.new()
