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
	if not store.spend("shard", cost, "ticket_buy"):
		return {"ok": false, "cost": cost, "reason": "no_shards"}
	var p: Dictionary = store.echobox_pity
	var count := bought_today(store, day) + n
	p["buy_day"] = day
	p["buy_count"] = count
	store.tickets["normal"] = int(store.tickets.get("normal", 0)) + n
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
