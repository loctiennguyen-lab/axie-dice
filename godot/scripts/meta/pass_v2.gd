class_name PassV2
extends RefCounted
## Battle Pass v2 (mùa 1): XP theo run, 30 level free, claim từng mốc, vòng lặp sau lv30.
## Design: echobox-pass-v2.md §3; dữ liệu assets/data/economy/pass_v2.json.
## Premium track: khoá tới mùa 2 (chỉ hiển thị nhãn "Season 2").
##
## Chạy trên `store` (MetaState hoặc stub test) có: pass_season:Dictionary, unlocks:Array,
## cosmetics_owned:Array, tickets, ledger_add(), add_shards(n, reason, save), add_stone(n, reason, save),
## unlock_price(id)->int, gem_wallet():GemWallet, save_to_disk().
## pass_season = {id, xp, level, claimed_free:Array[int], day, day_xp, post30_claimed}.
## Ngày luôn truyền vào ("YYYY-MM-DD" UTC) để test được.

const _Econ := preload("res://scripts/meta/economy_db.gd")


static func _cfg() -> Dictionary:
	return _Econ.get_table("pass_v2")


static func new_state(season_id: String) -> Dictionary:
	return {"id": season_id, "xp": 0, "level": 0, "claimed_free": [], "day": "", "day_xp": 0, "post30_claimed": 0}


## Mùa đang chạy tại ngày `day` (start_day <= day < end_day, so chuỗi ISO là đúng thứ tự thời gian).
static func season_active(day: String) -> bool:
	var c := _cfg()
	return day >= String(c.get("start_day", "9999")) and day < String(c.get("end_day", "0000"))


## Đảm bảo pass_season thuộc mùa hiện tại; mùa mới thì reset (XP lẻ không mang sang mùa sau).
static func ensure_season(store: Object) -> void:
	var sid := String(_cfg().get("season_id", ""))
	var ps: Dictionary = store.pass_season
	if String(ps.get("id", "")) != sid:
		store.pass_season = new_state(sid)


static func level_for_xp(xp: int) -> int:
	var lv := 0
	for l in _cfg().get("levels", []):
		if xp >= int((l as Dictionary).get("xp_total", 1 << 60)):
			lv = int((l as Dictionary).get("lv", 0))
	return lv


static func max_xp() -> int:
	var levels: Array = _cfg().get("levels", [])
	return int((levels[levels.size() - 1] as Dictionary).get("xp_total", 0))


## XP từ một run (thô, đã tính như công thức run XP hiện tại). Trần ngày UTC: 1.500 đầu 100%,
## phần sau 20%, tổng tối đa 2.000/ngày. Trả số XP thực nhận. Ngoài mùa: 0.
static func add_run_xp(store: Object, raw_xp: int, day: String) -> int:
	if raw_xp <= 0 or not season_active(day):
		return 0
	ensure_season(store)
	var x: Dictionary = _cfg().get("xp", {})
	var ps: Dictionary = store.pass_season
	var used := int(ps.get("day_xp", 0)) if String(ps.get("day", "")) == day else 0
	var full_cap := int(x.get("run_full_rate_until", 1500))
	var day_cap := int(x.get("run_cap_day", 2000))
	var full := maxi(0, mini(raw_xp, full_cap - used))
	var rest := raw_xp - full
	var granted := mini(full + int(floor(float(rest) * float(x.get("run_over_rate", 0.2)))), maxi(0, day_cap - used))
	ps["day"] = day
	ps["day_xp"] = used + granted
	_add_xp(store, granted)
	store.save_to_disk()
	return granted


## XP thưởng ngày (+100), không bị trần run. Ngoài mùa: 0.
static func add_daily_bonus_xp(store: Object, day: String) -> int:
	if not season_active(day):
		return 0
	ensure_season(store)
	var n := int((_cfg().get("xp", {}) as Dictionary).get("daily_bonus", 100))
	_add_xp(store, n)
	return n


static func _add_xp(store: Object, n: int) -> void:
	var ps: Dictionary = store.pass_season
	ps["xp"] = int(ps.get("xp", 0)) + n
	ps["level"] = level_for_xp(int(ps["xp"]))


## Các level đã đạt nhưng chưa nhận.
static func claimable_levels(store: Object) -> Array:
	var out: Array = []
	var ps: Dictionary = store.pass_season
	var lv := level_for_xp(int(ps.get("xp", 0)))
	var claimed: Array = ps.get("claimed_free", [])
	for i in range(1, lv + 1):
		if not claimed.has(i):
			out.append(i)
	return out


static func level_def(lv: int) -> Dictionary:
	for l in _cfg().get("levels", []):
		if int((l as Dictionary).get("lv", 0)) == lv:
			return l
	return {}


## Nhận phần thưởng free của một level. Trả {ok, reason, rewards:Array}.
## reason: not_reached | already_claimed | no_such_level | gem_needs_server.
## Atomic: mọi thứ áp trong bộ nhớ, đánh dấu đã nhận, rồi save một lần; Gem (ví) áp cuối cùng
## và ví local tự save nên save đó đã gồm cả dấu đã nhận. Ví không cấp local được (remote, chưa có
## endpoint quà mùa) thì từ chối cả mốc, KHÔNG đánh dấu đã nhận.
static func claim_free(store: Object, lv: int) -> Dictionary:
	var def := level_def(lv)
	if def.is_empty():
		return {"ok": false, "reason": "no_such_level", "rewards": []}
	var ps: Dictionary = store.pass_season
	if (ps.get("claimed_free", []) as Array).has(lv):
		return {"ok": false, "reason": "already_claimed", "rewards": []}
	if level_for_xp(int(ps.get("xp", 0))) < lv:
		return {"ok": false, "reason": "not_reached", "rewards": []}
	var gem := 0
	for r in def.get("free", []):
		if String((r as Dictionary).get("type", "")) == "gem":
			gem += int(r["value"])
	var wallet: GemWallet = store.gem_wallet() if gem > 0 else null
	if gem > 0 and not wallet.grants_locally():
		return {"ok": false, "reason": "gem_needs_server", "rewards": []}

	var given: Array = []
	for r in def.get("free", []):
		var rd: Dictionary = r
		var v = rd.get("value")
		match String(rd.get("type", "")):
			"shard": store.add_shards(int(v), "pass", false)
			"stone": store.add_stone(int(v), "pass", false)
			"ticket": EchoBox.grant_tickets(store, int(v), "pass")
			"cosmetic":
				if not store.cosmetics_owned.has(String(v)):
					store.cosmetics_owned.append(String(v))
			"title":
				var tid := "title:" + String(v)
				if not store.cosmetics_owned.has(tid):
					store.cosmetics_owned.append(tid)
			"unlock":
				if store.unlocks.has(String(v)):
					# ECO-13: đã có thì trả Shard bằng giá shop hiện hành, không cấp lại.
					var refund: int = store.unlock_price(String(v))
					store.add_shards(refund, "pass_unlock_refund", false)
					rd = {"type": "shard", "value": refund}
				else:
					store.unlocks.append(String(v))
		given.append(rd)
	(ps["claimed_free"] as Array).append(lv)
	ps["level"] = level_for_xp(int(ps.get("xp", 0)))
	if gem > 0:
		wallet.grant(gem, "season_gift")   # local: save luôn cả phần trên
		given.append({"type": "gem", "value": gem})
	else:
		store.save_to_disk()
	return {"ok": true, "reason": "", "rewards": given}


## Vòng lặp sau lv30: mỗi 2.000 XP dư = 50 Shard. Số vòng đã đạt nhưng chưa nhận.
static func post30_pending(store: Object) -> int:
	var loop: Dictionary = _cfg().get("post30_loop", {})
	var ps: Dictionary = store.pass_season
	var extra := int(ps.get("xp", 0)) - max_xp()
	if extra < 0:
		return 0
	return maxi(0, extra / int(loop.get("xp", 2000)) - int(ps.get("post30_claimed", 0)))


## Nhận hết các vòng đang chờ. Trả số Shard nhận được (0 nếu không có).
static func claim_post30(store: Object) -> int:
	var n := post30_pending(store)
	if n <= 0:
		return 0
	var shards := n * int((_cfg().get("post30_loop", {}) as Dictionary).get("shard", 50))
	store.add_shards(shards, "pass_loop", false)
	store.pass_season["post30_claimed"] = int(store.pass_season.get("post30_claimed", 0)) + n
	store.save_to_disk()
	return shards


## Premium: khoá ở L1 (mùa 2). Chỉ để UI hiện nhãn.
static func premium_state() -> Dictionary:
	var p: Dictionary = _cfg().get("premium", {})
	return {"locked": bool(p.get("locked_in_l1", true)), "label": String(p.get("label", "Season 2")),
		"unlock_season": int(p.get("unlock_season", 2))}
