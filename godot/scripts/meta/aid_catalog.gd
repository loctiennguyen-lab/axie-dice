class_name AidCatalog
extends RefCounted
## Có chào Aid hay không, giá bao nhiêu, trần nào còn lại. Contract l1-interfaces.md 3.4.
## Dữ liệu: assets/data/economy/aid_prices.json (monetization-v1 PA-1). Server kiểm lại mọi trần.
##
## MON-13: hàm này chỉ cho UI. Không luật chiến đấu nào được đọc `uses` hay kết quả của nó.
##
## ctx (UI dựng từ RunState.aid_context()):
##   mode, mission:bool, newcomer:bool, ascension:int, node_kind:String
##   ("setup"|"map"|"combat"|"elite"|"boss"|"shop"|"pact"), node_id (tuỳ chọn, để đếm trần theo
##   trận/boss/lần ghé), in_shop, at_pact, party_wiped, rerolls_left, clock_turns_left,
##   uses:Array[{aid,node_id,turn}], boon_used:bool, vip:bool, free_continue_left:bool,
##   gems:int (tuỳ chọn; có thì kiểm đủ Gem).
## Trả {show:bool, enabled:bool, price:int, reason:String}. reason "" khi enabled.

const _Econ := preload("res://scripts/meta/economy_db.gd")
const IDS := ["R1", "R2", "R4", "R5", "R6", "R7", "R8", "R9"]
const _COMBAT_KINDS := ["combat", "elite", "boss"]


static func offer(aid_id: String, ctx: Dictionary) -> Dictionary:
	var cfg: Dictionary = _Econ.get_table("aid_prices")
	var aids: Dictionary = cfg.get("aids", {})
	if not aids.has(aid_id):
		return _no("unknown_aid")
	var a: Dictionary = aids[aid_id]
	var asc := int(ctx.get("ascension", 0))
	var kind := String(ctx.get("node_kind", ""))
	var node_id = ctx.get("node_id", null)

	# Run Nhiệm vụ: không Aid nào. Newcomer: ẩn hết, chỉ chừa Continue miễn phí mẫu (A0-A2).
	if bool(ctx.get("mission", false)):
		return _no("mission_run")
	if bool(ctx.get("newcomer", false)):
		var fc: Dictionary = cfg.get("free_continue", {})
		if aid_id == "R1" and bool(ctx.get("party_wiped", false)) and asc <= int(fc.get("max_asc", 2)) \
				and bool(ctx.get("free_continue_left", false)) and kind in fc.get("node_kinds", []):
			return {"show": true, "enabled": true, "price": 0, "reason": ""}
		return _no("newcomer")

	var uses: Array = ctx.get("uses", [])
	var total_used := uses.size() + (1 if bool(ctx.get("boon_used", false)) else 0)
	var total_cap := _total_cap(cfg, asc)

	# "Khi nào chào" (monetization-v1 2.2) -> show.
	var show := false
	match aid_id:
		"R1": show = bool(ctx.get("party_wiped", false))
		"R2": show = kind in _COMBAT_KINDS and int(ctx.get("rerolls_left", 1)) <= 0
		"R4": show = kind == "boss" and int(ctx.get("clock_turns_left", 99)) <= int(a.get("offer_when_turns_left_max", 2))
		"R5": show = bool(ctx.get("at_pact", false)) and asc >= int(a.get("min_asc", 6))
		"R6": show = bool(ctx.get("in_shop", false))
		"R7": show = kind == "map"
		"R8", "R9": show = kind == "setup"
	if not show:
		return _no("not_now")

	var price := _price(aid_id, a, ctx, kind)
	# Continue miễn phí mẫu (1 lần/tài khoản, A0-A2, thua ở elite/boss): giá 0, không tính vào trần.
	if aid_id == "R1" and bool(ctx.get("free_continue_left", false)) and asc <= int((cfg.get("free_continue", {}) as Dictionary).get("max_asc", 2)) \
			and kind in (cfg.get("free_continue", {}) as Dictionary).get("node_kinds", []):
		price = 0
	var reason := ""
	if total_cap > 0 and total_used >= total_cap and price > 0:
		reason = "cap_total"
	elif aid_id == "R9" and (bool(ctx.get("boon_used", false)) or _count(uses, "R9", null, false) > 0):
		reason = "cap_type"
	elif _type_capped(aid_id, a, uses, node_id, asc, ctx):
		reason = "cap_type"
	elif aid_id == "R8" and bool(ctx.get("boon_used", false)):
		reason = "cap_boon"
	elif ctx.has("gems") and int(ctx["gems"]) < price:
		reason = "no_gems"
	return {"show": true, "enabled": reason == "", "price": price, "reason": reason}


## Trần tổng mỗi run: 6 cho A0-A8, 4 cho A9-A10.
static func _total_cap(cfg: Dictionary, asc: int) -> int:
	var tc: Dictionary = cfg.get("total_cap", {})
	if asc >= int(cfg.get("total_cap_split_asc", 9)):
		return int(tc.get("a9_a10", 4))
	return int(tc.get("a0_a8", 6))


static func _price(aid_id: String, a: Dictionary, ctx: Dictionary, kind: String) -> int:
	if aid_id == "R1":
		var boss := kind == "boss"
		if bool(ctx.get("vip", false)):
			return int(a.get("boss_vip_price" if boss else "vip_price", 0))
		return int(a.get("boss_price" if boss else "price", 0))
	return int(a.get("price", 0))


## Số lần aid đã dùng; node_id != null và by_node = true thì chỉ đếm cùng node.
static func _count(uses: Array, aid: String, node_id, by_node: bool) -> int:
	var n := 0
	for u in uses:
		if String((u as Dictionary).get("aid", "")) != aid:
			continue
		if by_node and (u as Dictionary).get("node_id", null) != node_id:
			continue
		n += 1
	return n


static func _type_capped(aid_id: String, a: Dictionary, uses: Array, node_id, asc: int, ctx: Dictionary) -> bool:
	if a.has("cap_run") and _count(uses, aid_id, null, false) >= int(a["cap_run"]):
		return true
	if a.has("cap_per_boss") and _count(uses, aid_id, node_id, true) >= int(a["cap_per_boss"]):
		return true
	if a.has("cap_per_pact") and _count(uses, aid_id, node_id, true) >= int(a["cap_per_pact"]):
		return true
	if a.has("cap_per_visit") and _count(uses, aid_id, node_id, true) >= int(a["cap_per_visit"]):
		return true
	if a.has("cap_battle_by_asc"):
		var per: int = int((a["cap_battle_by_asc"] as Dictionary).get(str(asc), 1))
		if _count(uses, aid_id, node_id, true) >= per:
			return true
	return false


static func _no(reason: String) -> Dictionary:
	return {"show": false, "enabled": false, "price": 0, "reason": reason}
