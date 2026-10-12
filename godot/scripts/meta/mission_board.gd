class_name MissionBoard
extends RefCounted
## Bảng Nhiệm vụ ngày (L1: N1-N4 bật, N5/N6 tắt). Design: nhiem-vu-risk-to-earn.md 3.2-3.6.
## Dữ liệu: assets/data/economy/missions.json. Định nghĩa luật M1-M5 (con số đổi trận) nằm ở
## rules/mission_rules.json của làn A; ở đây chỉ tham chiếu mã.
## Chỉ là dữ liệu bảng + điều kiện mở. Escrow (trừ cược lúc tạo run) và trả thưởng là việc server.
##
## `store` cần: runs:int, asc_wins:Dictionary, full_a9_won:bool, mission_house_level:int,
## spend(currency, n, reason)->bool, save_to_disk().

const _Econ := preload("res://scripts/meta/economy_db.gd")


static func _cfg() -> Dictionary:
	return _Econ.get_table("missions")


static func tier_ids() -> Array:
	return ["N1", "N2", "N3", "N4", "N5", "N6"]


## Trả khi thắng, đã gồm cược: round5(stake x m_base x m_scale).
static func payout(tier_id: String) -> int:
	var t: Dictionary = (_cfg().get("tiers", {}) as Dictionary).get(tier_id, {})
	var raw := float(t.get("stake", 0)) * float(t.get("m_base", 0)) * float(t.get("m_scale", 1.0))
	return int(roundf(raw / 5.0) * 5.0)


## Cấp nhà hiệu lực: cấp 1 mở miễn phí sau giai đoạn làm quen (newcomer_runs run).
static func house_level(store: Object) -> int:
	var lv := int(store.mission_house_level)
	if lv < 1 and int(store.runs) >= int(_cfg().get("newcomer_runs", 5)):
		lv = 1
	return lv


## Bộ luật A hay B hôm nay cho bậc này (cố định theo ngày UTC, mọi người như nhau).
static func rule_set_key(day: String, tier_id: String) -> String:
	return "A" if ("%s|nv|%s" % [day, tier_id]).hash() % 2 == 0 else "B"


## Danh sách offer hôm nay: một dòng mỗi bậc (kể cả bậc tắt/khoá, kèm lý do để UI hiện xám).
static func offers(day: String, store: Object) -> Array:
	var cfg := _cfg()
	var out: Array = []
	for id in tier_ids():
		var t: Dictionary = (cfg.get("tiers", {}) as Dictionary).get(id, {})
		var key := rule_set_key(day, id)
		var lock := lock_reason(id, store)
		out.append({
			"tier": id, "mode": t.get("mode", "short"), "ascension": int(t.get("ascension", 0)),
			"stake": int(t.get("stake", 0)), "m": float(t.get("m_base", 0)) * float(t.get("m_scale", 1.0)),
			"payout": payout(id), "stone": int(t.get("stone", 0)),
			"rule_set": key, "rules": ((cfg.get("rule_sets", {}) as Dictionary).get(id, {}) as Dictionary).get(key, []),
			"enabled": bool(t.get("enabled", false)), "unlocked": lock == "", "lock_reason": lock,
		})
	return out


## "" nếu mua được; ngược lại "disabled" | "newcomer" | "house" | "asc_win" | "full_a9".
static func lock_reason(tier_id: String, store: Object) -> String:
	var t: Dictionary = (_cfg().get("tiers", {}) as Dictionary).get(tier_id, {})
	if not bool(t.get("enabled", false)):
		return "disabled"
	if int(store.runs) < int(_cfg().get("newcomer_runs", 5)):
		return "newcomer"
	if house_level(store) < int(t.get("house_level", 1)):
		return "house"
	if bool(t.get("unlock_full_a9", false)):
		if not bool(store.full_a9_won):
			return "full_a9"
	elif int((store.asc_wins as Dictionary).get(str(int(t.get("unlock_win_asc", 0))), 0)) < 1:
		return "asc_win"
	return ""


## Giá nâng lên cấp kế; {} nếu đã tối đa.
static func next_house_cost(store: Object) -> Dictionary:
	var cur := house_level(store)
	for h in _cfg().get("house", []):
		if int((h as Dictionary).get("level", 0)) == cur + 1:
			return h
	return {}


## Nâng nhà: trừ Shard và Stone (đủ cả hai mới trừ). Trả "" khi xong hoặc lý do từ chối.
static func upgrade_house(store: Object) -> String:
	var cost := next_house_cost(store)
	if cost.is_empty():
		return "max_level"
	if int(store.shard_pool) < int(cost.get("cost_shards", 0)):
		return "no_shards"
	if int(store.stone) < int(cost.get("cost_stone", 0)):
		return "no_stone"
	store.spend("shard", int(cost.get("cost_shards", 0)), "mission_house")
	store.spend("stone", int(cost.get("cost_stone", 0)), "mission_house")
	store.mission_house_level = int(cost["level"])
	store.save_to_disk()
	return ""
