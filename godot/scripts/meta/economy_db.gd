extends Node
## Loader + kiểm tra dữ liệu economy (L1 lane E). Contract: production/l1-interfaces.md 5.1.
## Autoload `EconomyDB` do làn I đăng ký; code trong scripts/meta/ gọi qua
## preload("res://scripts/meta/economy_db.gd") (hàm static) nên không phụ thuộc đăng ký autoload.
## Không ai khác đọc JSON trực tiếp. Số liệu: design/proposals/{economy-v2,echobox-pass-v2,
## monetization-v1,nhiem-vu-risk-to-earn}.md.

const DATA_DIR := "res://assets/data/economy/"
const TABLES := ["gem", "aid_prices", "echobox", "pass_v2", "daily", "missions", "land_tiers", "ascension_titles"]

static var _cache: Dictionary = {}


## Đọc bảng `name` (tên file không đuôi, vd "gem"). {} nếu thiếu hoặc hỏng.
static func get_table(name: String) -> Dictionary:
	if _cache.has(name):
		return _cache[name]
	var path := DATA_DIR + name + ".json"
	if not FileAccess.file_exists(path):
		push_error("EconomyDB: thiếu %s" % path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("EconomyDB: %s không phải JSON object" % path)
		return {}
	_cache[name] = parsed
	return parsed


## Số "version" ở đầu file; 0 nếu thiếu.
static func version(name: String) -> int:
	return int(get_table(name).get("version", 0))


## Chỉ cho test: bỏ cache để đọc lại file.
static func clear_cache() -> void:
	_cache.clear()


## Kiểm toàn bộ bất biến số liệu. Trả danh sách lỗi (rỗng = sạch).
static func validate() -> Array[String]:
	var errs: Array[String] = []
	for t in TABLES:
		if version(t) < 1:
			errs.append("%s: thiếu hoặc sai \"version\"" % t)
	if not errs.is_empty():
		return errs
	_validate_gem(errs)
	_validate_aids(errs)
	_validate_echobox(errs)
	_validate_pass(errs)
	_validate_missions(errs)
	_validate_land(errs)
	return errs


static func _validate_gem(errs: Array[String]) -> void:
	var g := get_table("gem")
	var gift: Dictionary = g.get("gift", {})
	if int(gift.get("per_day", 0)) <= 0 or int(gift.get("balance_cap", 0)) < int(gift.get("per_day", 0)):
		errs.append("gem: gift.per_day/balance_cap vô lý")
	var sg: Dictionary = g.get("season_gift", {})
	var sum := 0
	for m in sg.get("milestones", []):
		sum += int((m as Dictionary).get("gems", 0))
	if sum != int(sg.get("total", -1)):
		errs.append("gem: season_gift milestones cộng %d != total %s" % [sum, sg.get("total")])


static func _validate_aids(errs: Array[String]) -> void:
	var a := get_table("aid_prices")
	for id in ["R1", "R2", "R4", "R5", "R6", "R7", "R8", "R9"]:
		if not (a.get("aids", {}) as Dictionary).has(id):
			errs.append("aid_prices: thiếu %s" % id)
		elif int(a["aids"][id].get("price", 0)) <= 0:
			errs.append("aid_prices: %s giá <= 0" % id)
	var tc: Dictionary = a.get("total_cap", {})
	if int(tc.get("a0_a8", 0)) != 6 or int(tc.get("a9_a10", 0)) != 4:
		errs.append("aid_prices: total_cap phải 6/4")


static func _validate_echobox(errs: Array[String]) -> void:
	var e := get_table("echobox")
	var normal: Dictionary = (e.get("boxes", {}) as Dictionary).get("normal", {})
	var total := 0.0
	var stone_share := 0.0
	var ev := 0.0
	for row in normal.get("table", []):
		var r: Dictionary = row
		var w := float(r.get("weight", 0.0))
		total += w
		if String(r.get("kind", "")) == "stone":
			stone_share += w
			ev += w / 100.0 * float(r.get("amount", 0))
	if absf(total - 100.0) > 0.01:
		errs.append("echobox normal: tổng weight %.4f != 100 (±0.01)" % total)
	if absf(stone_share - 60.0) > 0.01:
		errs.append("echobox normal: Stone share %.4f != 60" % stone_share)
	if absf(ev - 242.5) > 242.5 * 0.03:
		errs.append("echobox normal: EV Stone %.2f lệch 242,5 quá 3%%" % ev)
	var season: Dictionary = (e.get("boxes", {}) as Dictionary).get("season", {})
	var st := 0.0
	var sev := 0.0
	for row in season.get("stone_table", []):
		st += float((row as Dictionary).get("weight", 0))
		sev += float((row as Dictionary).get("weight", 0)) / 100.0 * float((row as Dictionary).get("amount", 0))
	if absf(st - 100.0) > 0.01:
		errs.append("echobox season: stone_table tổng %.4f != 100" % st)
	if absf(sev - 1290.0) > 1290.0 * 0.03:
		errs.append("echobox season: EV %.1f lệch 1.290 quá 3%%" % sev)
	# Bound đủ bộ: max_t n_t * (N_t + h_t) <= full_set_pity
	var tiers: Dictionary = season.get("tiers", {})
	var order := ["mythic", "legendary", "epic"]
	var bound := 0
	for i in order.size():
		var t: Dictionary = tiers.get(order[i], {})
		if int(t.get("N", 0)) <= i:
			errs.append("echobox season: N_%s phải > số tầng cao hơn" % order[i])
		bound = maxi(bound, int(t.get("n", 0)) * (int(t.get("N", 0)) + i))
	if bound > int(season.get("full_set_pity", 80)):
		errs.append("echobox season: bound %d vượt full_set_pity" % bound)
	var tk: Dictionary = e.get("tickets", {})
	if int(tk.get("base_price", 0)) != 200:
		errs.append("echobox: base_price vé phải 200")
	var fr: Dictionary = e.get("dup_fragments", {})
	var prev := 0
	for r in ["common", "uncommon", "rare", "epic", "legendary", "mythic"]:
		if int(fr.get(r, 0)) <= prev:
			errs.append("echobox: dup_fragments phải tăng dần theo độ hiếm (%s)" % r)
		prev = int(fr.get(r, 0))


static func _validate_pass(errs: Array[String]) -> void:
	var p := get_table("pass_v2")
	var levels: Array = p.get("levels", [])
	if levels.size() != 30:
		errs.append("pass_v2: cần 30 level, có %d" % levels.size())
		return
	var shard := 0
	var stone := 0
	var tickets := 0
	var unlocks := 0
	var cum := 0
	for l in levels:
		cum += int(l.get("xp", 0))
		if cum != int(l.get("xp_total", -1)):
			errs.append("pass_v2: xp_total sai ở lv %d" % int(l.get("lv", 0)))
		for r in l.get("free", []):
			var v := int(r.get("value", 0)) if typeof(r.get("value")) != TYPE_STRING else 0
			match String(r.get("type", "")):
				"shard": shard += v
				"stone": stone += v
				"ticket": tickets += v
				"unlock": unlocks += 1
	if cum != 32400:
		errs.append("pass_v2: tổng XP %d != 32.400" % cum)
	if shard != 4800: errs.append("pass_v2: Shard %d != 4.800" % shard)
	if stone != 16500: errs.append("pass_v2: Stone %d != 16.500" % stone)
	if tickets != 12: errs.append("pass_v2: vé %d != 12" % tickets)
	if unlocks != 5: errs.append("pass_v2: unlock %d != 5" % unlocks)


static func _validate_missions(errs: Array[String]) -> void:
	var m := get_table("missions")
	var tiers: Dictionary = m.get("tiers", {})
	# Beta: 6 bậc. Cược cố định theo thiết kế; m/ascension/luật là số của sim (N-S) nên chỉ kiểm hình dạng.
	var stakes := [300, 500, 800, 1200, 1800, 2500]
	var rule_ids: Array = ["M1", "M2", "M3", "M4", "M5", "M6", "M7"]
	var last_pay := 0
	for i in 6:
		var id := "N%d" % (i + 1)
		var t: Dictionary = tiers.get(id, {})
		if int(t.get("stake", 0)) != stakes[i] or float(t.get("m_base", 0)) <= 0.0:
			errs.append("missions: %s sai stake/m" % id)
		if int(t.get("unlock_wins", 1)) < 1:
			errs.append("missions: %s unlock_wins phải >= 1" % id)
		if not bool(t.get("enabled", false)):
			errs.append("missions: %s phải bật (beta, Liam 26/10)" % id)
		if typeof(t.get("rules", null)) != TYPE_ARRAY:
			errs.append("missions: %s thiếu mảng rules (Worker kiểm chặt)" % id)
		else:
			var seen := {}
			for r in (t["rules"] as Array):
				if seen.has(String(r)):
					errs.append("missions: %s luật trùng %s (Worker từ chối)" % [id, str(r)])
				seen[String(r)] = true
				if not rule_ids.has(String(r)):
					errs.append("missions: %s luật lạ %s" % [id, str(r)])
		var pay := int(roundf(float(t.get("stake", 0)) * float(t.get("m_base", 0)) * float(t.get("m_scale", 1.0)) / 5.0) * 5.0)
		if pay < last_pay:
			errs.append("missions: payout %s thấp hơn bậc trước" % id)
		last_pay = pay
	if bool(m.get("house_upgrade_enabled", true)):
		errs.append("missions: nâng nhà phải tắt ở L1")
	if bool((get_table("gem").get("vip_trial", {}) as Dictionary).get("enabled", true)):
		errs.append("gem: vip_trial phải tắt ở L1")


## Tier cap = highest tier row in land_tiers.json (6).
static func land_max_tier() -> int:
	var m := 1
	for t in get_table("land_tiers").get("tiers", []):
		m = maxi(m, int((t as Dictionary).get("tier", 1)))
	return m


## Land Stone to go from `tier` to tier+1; -1 when there is no next tier.
static func land_tier_cost(tier: int) -> int:
	for t in get_table("land_tiers").get("tiers", []):
		if int((t as Dictionary).get("tier", 0)) == tier + 1:
			return int((t as Dictionary).get("cost_stone", 0))
	return -1


## Switch in land_tiers.json (live at L1 since 14/10; false would draw "Not in this build", M15a).
static func land_upgrade_enabled() -> bool:
	return bool(get_table("land_tiers").get("upgrade_enabled", false))


static func _validate_land(errs: Array[String]) -> void:
	var total := 0
	for t in get_table("land_tiers").get("tiers", []):
		total += int((t as Dictionary).get("cost_stone", 0))
	if total != 1820000:
		errs.append("land_tiers: tổng Stone %d != 1.820.000" % total)
