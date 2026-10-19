class_name EchoBox
extends RefCounted
## Logic hộp thường (Echo Box) + vé. Design: echobox-pass-v2.md 2.3-2.7, economy-v2.md 3-5.
## Dữ liệu: assets/data/economy/echobox.json. Hộp mùa: dữ liệu có (enabled=false), logic chưa viết.
##
## Chạy trên một `store` (MetaState hoặc stub test) có: tickets:Dictionary{normal,season},
## echobox_pity:Dictionary, cosmetics_owned:Array, và các hàm add_stone(n, reason),
## spend(currency, n, reason)->bool, ledger_add(cur, delta, reason), save_to_disk().
## RNG truyền vào (RandomNumberGenerator) để test xác định; sau này server tung thay client.
##
## Mỗi lượt ra ĐÚNG MỘT phần thưởng: Stone XOR cosmetic. Mở hộp/đổi trùng không bao giờ cộng Shard
## (INV-V1). Một loại vé (lưu ở tickets.normal; tickets.season dự trữ, luôn 0).

const _Econ := preload("res://scripts/meta/economy_db.gd")
const RARITIES := ["common", "uncommon", "rare", "epic", "legendary", "mythic"]


static func _cfg() -> Dictionary:
	return _Econ.get_table("echobox")


## Giá vé thứ k (k tính từ 1) mua bằng Shard trong ngày UTC: round5(200 x 1,05^(k-1)).
static func ticket_price(k: int) -> int:
	var t: Dictionary = _cfg().get("tickets", {})
	var raw := float(t.get("base_price", 200)) * pow(float(t.get("growth", 1.05)), k - 1)
	var step := float(t.get("round_to", 5))
	return int(roundf(raw / step) * step)


## Số vé đã mua bằng Shard trong ngày `day` ("YYYY-MM-DD").
static func bought_today(store: Object, day: String) -> int:
	var p: Dictionary = store.echobox_pity
	return int(p.get("buy_count", 0)) if String(p.get("buy_day", "")) == day else 0


## Tổng Shard để mua thêm n vé nữa hôm nay; -1 nếu vượt trần ngày (30).
static func cost_for(store: Object, day: String, n: int) -> int:
	var cap := int((_cfg().get("tickets", {}) as Dictionary).get("buy_cap_day", 30))
	var have := bought_today(store, day)
	if n <= 0 or have + n > cap:
		return -1
	var total := 0
	for k in range(have + 1, have + n + 1):
		total += ticket_price(k)
	return total


## Mua n vé bằng Shard. Trả {ok, cost, reason}. Vé giữ tối đa 999.
static func buy_tickets(store: Object, day: String, n: int) -> Dictionary:
	var hold_cap := int((_cfg().get("tickets", {}) as Dictionary).get("hold_cap", 999))
	var cost := cost_for(store, day, n)
	if cost < 0:
		return {"ok": false, "cost": 0, "reason": "daily_cap"}
	if int(store.tickets.get("normal", 0)) + n > hold_cap:
		return {"ok": false, "cost": 0, "reason": "hold_cap"}
	# Trừ Shard + cộng vé trong bộ nhớ rồi save MỘT lần: ngắt giữa chừng không mất Shard không vé.
	if not store.spend("shard", cost, "ticket_buy", false):
		return {"ok": false, "cost": cost, "reason": "no_shards"}
	var p: Dictionary = store.echobox_pity
	var count := bought_today(store, day) + n
	p["buy_day"] = day
	p["buy_count"] = count
	store.tickets["normal"] = int(store.tickets.get("normal", 0)) + n
	store.ledger_add("ticket", n, "buy")
	store.save_to_disk()
	return {"ok": true, "cost": cost, "reason": ""}


## Cấp vé không qua giá bậc thang (Pass, starter, bundle, recycle). origin vào sổ cái.
static func grant_tickets(store: Object, n: int, origin: String) -> void:
	var hold_cap := int((_cfg().get("tickets", {}) as Dictionary).get("hold_cap", 999))
	store.tickets["normal"] = mini(int(store.tickets.get("normal", 0)) + n, hold_cap)
	store.ledger_add("ticket", n, "grant:" + origin)


## Mở một lượt hộp thường (1 vé). Trả:
## {ok, reason, kind:"stone"|"cosmetic", amount, rarity, item, duplicate, fragments, tickets_back}
static func open_normal(store: Object, rng: RandomNumberGenerator) -> Dictionary:
	var box: Dictionary = (_cfg().get("boxes", {}) as Dictionary).get("normal", {})
	var cost := int(box.get("ticket_cost", 1))
	if int(store.tickets.get("normal", 0)) < cost:
		return {"ok": false, "reason": "no_tickets"}
	store.tickets["normal"] = int(store.tickets["normal"]) - cost
	store.ledger_add("ticket", -cost, "open:normal")

	var pity: Dictionary = store.echobox_pity
	pity["opens"] = int(pity.get("opens", 0)) + 1
	var rows: Array = box.get("table", [])
	var res := {"ok": true, "reason": "", "kind": "", "amount": 0, "rarity": "", "item": "",
		"duplicate": false, "fragments": 0, "tickets_back": 0}

	var row := _pick(rows, rng, "")
	if String(row.get("kind", "")) == "stone":
		res["kind"] = "stone"
		res["amount"] = int(row.get("amount", 0))
		store.add_stone(int(row["amount"]), "echobox")
	else:
		res["kind"] = "cosmetic"
		var forced := _forced_min_rarity(pity, box)
		var rarity := String(row.get("rarity", "common"))
		if forced != "" and RARITIES.find(rarity) < RARITIES.find(forced):
			rarity = String(_pick(rows, rng, forced).get("rarity", forced))
		res["rarity"] = rarity
		_advance_pity(pity, box, rarity)
		_give_cosmetic(store, box, rarity, rng, res)
	store.save_to_disk()
	return res


# --- Hộp mùa (echobox-pass-v2 §2.8-2.10) ---------------------------------------------------

const _TIERS := ["mythic", "legendary", "epic"]   # thứ tự thử ở bước 3


static func season_cfg() -> Dictionary:
	return (_cfg().get("boxes", {}) as Dictionary).get("season", {})


## Id stored in cosmetics_owned for a season reward. Titles map to "title:<NAME>" (what TitleNames reads);
## anything else (die_m_moon...) is stored as is.
static func season_owned_id(reward_id: String) -> String:
	var t: Dictionary = season_cfg().get("titles", {})
	return TitleNames.PREFIX + String(t[reward_id]) if t.has(reward_id) else reward_id


static func season_enabled() -> bool:
	return bool(season_cfg().get("enabled", false))


## Trạng thái (bản sao) của một series; mặc định series hiện hành trong data.
static func season_state(store: Object, series_id: String = "") -> Dictionary:
	var sid := series_id if series_id != "" else String(season_cfg().get("series_id", "s1"))
	var e: Dictionary = (store.season_box as Dictionary).get(sid, {})
	var out := {"opens": 0, "c_epic": 0, "c_legendary": 0, "c_mythic": 0, "owned": [], "milestones": [], "day": "", "day_pulls": 0}
	for k in e:
		out[k] = e[k].duplicate() if e[k] is Array else e[k]
	return out


## Trần N_t hiện dùng (Vault nhân vault_cap_scale).
static func season_cap(tier: String, vault: bool) -> int:
	var cfg := season_cfg()
	var n := int(((cfg.get("tiers", {}) as Dictionary).get(tier, {}) as Dictionary).get("N", 1))
	return n * (int(cfg.get("vault_cap_scale", 2)) if vault else 1)


## p_t(c) = (c^k - (c-1)^k) / (N^k - (c-1)^k); c >= N -> 1.
static func season_hit_prob(c: int, n: int, k: float) -> float:
	if c >= n:
		return 1.0
	var lo := pow(float(c - 1), k)
	return (pow(float(c), k) - lo) / (pow(float(n), k) - lo)


## Mở một lượt hộp mùa (ticket_cost vé, trần pull_cap_day/ngày). `day` = "YYYY-MM-DD" UTC.
## vault=true: N nhân đôi (series cũ). Trả {ok, reason, kind:"stone"|"cosmetic", amount, tier, item,
## duplicate, tickets_back, milestones:[ids], complete}. reason: disabled | no_tickets | daily_cap.
static func open_season(store: Object, rng: RandomNumberGenerator, day: String, vault: bool = false,
		series_id: String = "", allow_disabled: bool = false) -> Dictionary:
	var cfg := season_cfg()
	if not bool(cfg.get("enabled", false)) and not allow_disabled:
		return {"ok": false, "reason": "disabled"}
	var sid := series_id if series_id != "" else String(cfg.get("series_id", "s1"))
	var cost := int(cfg.get("ticket_cost", 5))
	var st := season_state(store, sid)
	var day_pulls := int(st["day_pulls"]) if String(st["day"]) == day else 0
	if day_pulls >= int(cfg.get("pull_cap_day", 8)):
		return {"ok": false, "reason": "daily_cap"}
	if int(store.tickets.get("normal", 0)) < cost:
		return {"ok": false, "reason": "no_tickets"}
	store.tickets["normal"] = int(store.tickets["normal"]) - cost
	store.ledger_add("ticket", -cost, "open:season")

	var tiers: Dictionary = cfg.get("tiers", {})
	var items: Dictionary = cfg.get("items", {})
	var owned: Array = st["owned"]
	var k := float(cfg.get("escalation_k", 2))
	var res := {"ok": true, "reason": "", "kind": "", "amount": 0, "tier": "", "item": "",
		"duplicate": false, "tickets_back": 0, "milestones": [], "complete": false}
	# Bước 1: c_t += 1 cho tầng chưa đủ.
	var incomplete := {}
	for t in _TIERS:
		var have := 0
		for it in items.get(t, []):
			if owned.has(it):
				have += 1
		incomplete[t] = have < int(items.get(t, []).size())
		if incomplete[t]:
			st["c_" + t] = int(st["c_" + t]) + 1
	# Bước 2: tầng đến hạn (cao nhất thắng). Bước 3: Mythic -> Legendary -> Epic.
	var hit := ""
	for t in _TIERS:
		if incomplete[t] and int(st["c_" + t]) >= season_cap(t, vault):
			hit = t
			break
	if hit == "":
		for t in _TIERS:
			var p: float
			if incomplete[t]:
				p = season_hit_prob(int(st["c_" + t]), season_cap(t, vault), k)
			else:
				p = float((tiers[t] as Dictionary).get("dup_rate", 0))
			if rng.randf() < p:
				hit = t
				break
	if hit == "":
		# Bước 4: Stone.
		var row := _pick_amount(cfg.get("stone_table", []), rng)
		res["kind"] = "stone"
		res["amount"] = row
		store.add_stone(row, "echobox_season", false)
	else:
		res["kind"] = "cosmetic"
		res["tier"] = hit
		var list: Array = items.get(hit, [])
		if incomplete[hit]:
			var missing: Array = []
			for it in list:
				if not owned.has(it):
					missing.append(it)
			var pick: String = missing[rng.randi_range(0, missing.size() - 1)]
			owned.append(pick)
			if not store.cosmetics_owned.has(pick):
				store.cosmetics_owned.append(pick)
			res["item"] = pick
			st["c_" + hit] = 0   # bước 5
		else:
			res["duplicate"] = true
			res["item"] = list[rng.randi_range(0, list.size() - 1)]
			var back := int((tiers[hit] as Dictionary).get("dup_tickets", 0))
			res["tickets_back"] = back
			if back > 0:
				grant_tickets(store, back, "recycle_season")
	st["opens"] = int(st["opens"]) + 1
	st["owned"] = owned
	st["day"] = day
	st["day_pulls"] = day_pulls + 1
	# Mốc (ngoài lượt, không Stone/vé) + đủ bộ.
	for m in cfg.get("milestones", []):
		var md: Dictionary = m
		if int(st["opens"]) >= int(md.get("opens", 1 << 30)):
			var mid := "m%d" % int(md["opens"])
			if not (st["milestones"] as Array).has(mid):
				(st["milestones"] as Array).append(mid)
				for key in ["reward", "also"]:
					var rid := season_owned_id(String(md.get(key, "")))
					if rid != "" and not store.cosmetics_owned.has(rid):
						store.cosmetics_owned.append(rid)
				(res["milestones"] as Array).append(String(md.get("reward", "")))
	var total := 0
	var all_have := 0
	for t in _TIERS:
		total += (items.get(t, []) as Array).size()
	all_have = owned.size()
	if total > 0 and all_have >= total and not (st["milestones"] as Array).has("complete"):
		(st["milestones"] as Array).append("complete")
		var cr := season_owned_id(String(cfg.get("complete_reward", "")))
		if cr != "" and not store.cosmetics_owned.has(cr):
			store.cosmetics_owned.append(cr)
		res["complete"] = true
	store.season_box[sid] = st
	store.save_to_disk()
	return res


static func _pick_amount(rows: Array, rng: RandomNumberGenerator) -> int:
	var total := 0.0
	for r in rows:
		total += float((r as Dictionary).get("weight", 0))
	var x := rng.randf() * total
	var acc := 0.0
	for r in rows:
		acc += float((r as Dictionary).get("weight", 0))
		if x < acc:
			return int((r as Dictionary).get("amount", 0))
	return int((rows[rows.size() - 1] as Dictionary).get("amount", 0))


# --- nội bộ -----------------------------------------------------------------

## Chọn một dòng theo weight (chuẩn hoá theo tổng). min_rarity "" = mọi dòng; tên độ hiếm =
## chỉ dòng cosmetic có độ hiếm >= đó.
static func _pick(rows: Array, rng: RandomNumberGenerator, min_rarity: String) -> Dictionary:
	var pool: Array = []
	var total := 0.0
	var min_i := RARITIES.find(min_rarity) if min_rarity != "" else -1
	for r in rows:
		var d: Dictionary = r
		if min_i >= 0:
			if String(d.get("kind", "")) != "cosmetic" or RARITIES.find(String(d.get("rarity", ""))) < min_i:
				continue
		pool.append(d)
		total += float(d.get("weight", 0))
	var x := rng.randf() * total
	var acc := 0.0
	for d in pool:
		acc += float((d as Dictionary).get("weight", 0))
		if x < acc:
			return d
	return pool[pool.size() - 1]


static func _step_key(min_rarity: String) -> String:
	return "since_" + min_rarity


## Ngưỡng cao nhất đã tới hạn (bộ đếm >= pulls) -> độ hiếm tối thiểu của lượt này; "" nếu không.
static func _forced_min_rarity(pity: Dictionary, box: Dictionary) -> String:
	var forced := ""
	var best := -1
	for s in (box.get("pity", {}) as Dictionary).get("steps", []):
		var step: Dictionary = s
		var key := _step_key(String(step.get("min_rarity", "")))
		if int(pity.get(key, 0)) >= int(step.get("pulls", 0)):
			var ri := RARITIES.find(String(step["min_rarity"]))
			if ri > best:
				best = ri
				forced = String(step["min_rarity"])
	return forced


## Lượt cosmetic ra độ hiếm r: mọi bộ đếm có min_rarity <= r về 0, còn lại +1.
static func _advance_pity(pity: Dictionary, box: Dictionary, rarity: String) -> void:
	var ri := RARITIES.find(rarity)
	for s in (box.get("pity", {}) as Dictionary).get("steps", []):
		var step: Dictionary = s
		var key := _step_key(String(step.get("min_rarity", "")))
		if RARITIES.find(String(step["min_rarity"])) <= ri:
			pity[key] = 0
		else:
			pity[key] = int(pity.get(key, 0)) + 1


static func pool_ids(box: Dictionary, rarity: String) -> Array:
	var spec: Dictionary = (box.get("pool", {}) as Dictionary).get(rarity, {})
	var out: Array = []
	for i in range(1, int(spec.get("count", 0)) + 1):
		out.append("%s_%03d" % [String(spec.get("id_prefix", "std")), i])
	return out


## Không-lặp theo tầng; hết món chưa có thì là đồ trùng -> mảnh -> vé (10 mảnh = 1 vé).
static func _give_cosmetic(store: Object, box: Dictionary, rarity: String, rng: RandomNumberGenerator, res: Dictionary) -> void:
	var ids := pool_ids(box, rarity)
	var missing: Array = []
	for id in ids:
		if not store.cosmetics_owned.has(id):
			missing.append(id)
	if not missing.is_empty() or ids.is_empty():
		if ids.is_empty():
			return
		var pick: String = missing[rng.randi_range(0, missing.size() - 1)]
		store.cosmetics_owned.append(pick)
		res["item"] = pick
		return
	res["duplicate"] = true
	res["item"] = ids[rng.randi_range(0, ids.size() - 1)]
	var cfg := _cfg()
	var gain := int((cfg.get("dup_fragments", {}) as Dictionary).get(rarity, 0))
	var per := int(cfg.get("fragments_per_ticket", 10))
	var pity: Dictionary = store.echobox_pity
	var frags := int(pity.get("fragments", 0)) + gain
	var back := frags / per
	pity["fragments"] = frags % per
	res["fragments"] = gain
	res["tickets_back"] = back
	if back > 0:
		grant_tickets(store, back, "recycle")
