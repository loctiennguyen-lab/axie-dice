class_name MissionBoard
extends RefCounted
## Bảng Nhiệm vụ beta: 6 bậc (N1-N6), mỗi bậc MỘT bộ luật cố định (không xoay A/B), mở bậc bằng chuỗi thắng.
## Design: nhiem-vu-beta-brainstorm.md §2 (hướng B), nhiem-vu-risk-to-earn.md 3.2-3.6.
## Dữ liệu: assets/data/economy/missions.json (field `rules` = mảng luật cố định của bậc, đúng tên Worker kiểm;
## `unlock_wins` = số lần thắng bậc trước để mở, mặc định 1). Định nghĩa luật M1-M7 (con số đổi trận) nằm ở
## rules/mission_rules.json; ở đây chỉ tham chiếu mã.
## Mở bậc: nguồn thật là server (GET /api/missions/unlocks -> apply_unlocks -> MetaState.mission_unlock_cache).
## Offline/test dùng cache. N1 luôn mở. Escrow (trừ cược lúc tạo run) và trả thưởng là việc server.
##
## `store` cần: runs:int, mission_unlock_cache:Array, mission_house_level:int, is_newcomer(),
## spend(currency, n, reason)->bool, save_to_disk().

const _Econ := preload("res://scripts/meta/economy_db.gd")

## Số lần thắng mỗi bậc theo lần hỏi server gần nhất: {"N1": {"unlocked": bool, "wins": int, "needs": int}}.
## Chỉ để viết lý do khoá ("1/2"); quyết định mở bậc đọc từ store.mission_unlock_cache.
static var server_tiers: Dictionary = {}


static func _cfg() -> Dictionary:
	return _Econ.get_table("missions")


static func tiers() -> Dictionary:
	return _cfg().get("tiers", {})


static func config() -> Dictionary:
	return _cfg()


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
	if lv < 1 and not store.is_newcomer():
		lv = 1
	if not bool(_cfg().get("house_upgrade_enabled", false)):
		lv = mini(lv, 1)   # beta: nhà luôn lv1, kể cả save/test lỡ ghi cấp cao hơn
	return lv


## Bậc có bật trong bản này không (data `enabled`, thiếu = bật). Bậc lạ = false.
static func tier_enabled(tier_id: String) -> bool:
	var t: Dictionary = (_cfg().get("tiers", {}) as Dictionary).get(tier_id, {})
	return not t.is_empty() and bool(t.get("enabled", true))


## Luật M cố định của bậc (mảng mã, copy).
static func tier_rules(tier_id: String) -> Array:
	var t: Dictionary = (_cfg().get("tiers", {}) as Dictionary).get(tier_id, {})
	return (t.get("rules", []) as Array).duplicate()


## Số lần thắng bậc trước cần để mở bậc này (N1 = 0).
static func wins_needed(tier_id: String) -> int:
	if tier_id == "N1":
		return 0
	var t: Dictionary = (_cfg().get("tiers", {}) as Dictionary).get(tier_id, {})
	return maxi(1, int(t.get("unlock_wins", 1)))


## Bậc trước ("N2" -> "N1"); "" cho N1 / bậc lạ.
static func prev_tier(tier_id: String) -> String:
	var i := tier_ids().find(tier_id)
	return String(tier_ids()[i - 1]) if i > 0 else ""


## Bậc mở theo cache server. N1 luôn mở.
static func tier_unlocked(tier_id: String, store: Object) -> bool:
	if tier_id == "N1":
		return true
	var cache: Variant = store.get("mission_unlock_cache")
	return typeof(cache) == TYPE_ARRAY and (cache as Array).has(tier_id)


## Ghi câu trả lời của GET /api/missions/unlocks ({tiers:{N1:{unlocked,wins,needs}}}) vào cache của store.
## Trả true nếu câu trả lời hợp lệ. Câu trả lời lạ -> không đổi gì (không khoá nhầm người chơi).
static func apply_unlocks(store: Object, resp: Variant) -> bool:
	if typeof(resp) != TYPE_DICTIONARY or typeof((resp as Dictionary).get("tiers", null)) != TYPE_DICTIONARY:
		return false
	var info: Dictionary = (resp as Dictionary)["tiers"]
	var ids: Array = []
	server_tiers = {}
	for id in tier_ids():
		var e: Variant = info.get(id, null)
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = e
		server_tiers[id] = {"unlocked": bool(d.get("unlocked", false)), "wins": int(d.get("wins", 0)), "needs": int(d.get("needs", 0)),
			"locked_reason": String(d.get("locked_reason", ""))}
		if bool(d.get("unlocked", false)):
			ids.append(id)
	store.set_mission_unlocks(ids)
	return true


## Cảnh báo cố định theo bậc (§5): "" | "most_lose" (N3+) | "challenge" (N5+) | "title" (N6).
static func warning_kind(tier_id: String) -> String:
	var n := int(tier_id.substr(1)) if tier_id.length() > 1 else 0
	if n >= 6:
		return "title"
	if n >= 5:
		return "challenge"
	if n >= 3:
		return "most_lose"
	return ""


## Danh sách offer: một dòng mỗi bậc (kể cả bậc khoá, kèm lý do để UI hiện xám). `day` giữ cho chữ ký cũ.
static func offers(_day: String, store: Object) -> Array:
	var cfg := _cfg()
	var out: Array = []
	for id in tier_ids():
		var t: Dictionary = (cfg.get("tiers", {}) as Dictionary).get(id, {})
		var lock := lock_reason(id, store)
		var stake := int(t.get("stake", 0))
		var pay := payout(id)
		var est := float(t.get("est_win_pct", 0.0))
		var sv: Dictionary = server_tiers.get(id, {})
		var prev := prev_tier(id)
		out.append({
			"tier": id, "mode": t.get("mode", "short"), "ascension": int(t.get("ascension", 0)),
			"stake": stake, "m": float(t.get("m_base", 0)) * float(t.get("m_scale", 1.0)),
			"payout": pay, "net": pay - stake, "stone": int(t.get("stone", 0)),
			"rules": tier_rules(id),
			# ước tính từ bot (hiện nhãn "ước tính"): xác suất thắng và % cược nhận về trung bình
			"est_win_pct": est, "est_return_pct": (est / 100.0) * float(pay) / maxf(float(stake), 1.0) * 100.0,
			"warning": warning_kind(id),
			"unlock_prev": prev, "unlock_need": wins_needed(id), "unlock_wins": int(sv.get("wins", 0)),
			"enabled": tier_enabled(id), "unlocked": lock == "", "lock_reason": lock,
		})
	return out


## "" nếu mua được; ngược lại "disabled" | "newcomer" | "chain" (chưa thắng bậc trước đủ số lần).
static func lock_reason(tier_id: String, store: Object) -> String:
	if not tier_enabled(tier_id) or String((server_tiers.get(tier_id, {}) as Dictionary).get("locked_reason", "")) == "tier_locked":
		return "disabled"   # data off, or the server's kill switch ("Closed for now"), not a win-chain lock
	if store.is_newcomer():
		return "newcomer"
	if not tier_unlocked(tier_id, store):
		return "chain"
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
	if not bool(_cfg().get("house_upgrade_enabled", false)):
		return "disabled"   # L1: nhà không nâng cấp
	var cost := next_house_cost(store)
	if cost.is_empty():
		return "max_level"
	if int(store.shard_pool) < int(cost.get("cost_shards", 0)):
		return "no_shards"
	if int(store.stone) < int(cost.get("cost_stone", 0)):
		return "no_stone"
	# Hai khoản trừ + đổi cấp rồi save một lần.
	store.spend("shard", int(cost.get("cost_shards", 0)), "mission_house", false)
	store.spend("stone", int(cost.get("cost_stone", 0)), "mission_house", false)
	store.mission_house_level = int(cost["level"])
	store.save_to_disk()
	return ""
