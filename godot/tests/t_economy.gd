extends Node
## Lane E (L1): dữ liệu economy, GemWallet local, AidCatalog, Echo Box hộp thường, bảng Nhiệm vụ,
## save schema + migration. Logic chạy trên Stub (không chạm save thật); phần MetaState dùng SaveGuard.
## Design: echobox-pass-v2.md, economy-v2.md, monetization-v1.md, nhiem-vu-risk-to-earn.md.

const _Econ := preload("res://scripts/meta/economy_db.gd")

var _failures: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()


## Thay MetaState: đủ field/hàm mà LocalGemWallet, EchoBox, MissionBoard cần.
class Stub extends RefCounted:
	var shard_pool := 0
	var stone := 0
	var gems_cache := 0
	var gem_claim_next_utc := 0
	var gem_gift_day := ""
	var vip_until_utc := 0
	var vip_trial_used := false
	var tickets := {"normal": 0, "season": 0}
	var echobox_pity := {}
	var cosmetics_owned: Array = []
	var runs := 0
	var asc_wins := {}
	var full_a9_won := false
	var mission_house_level := 0
	var saves := 0
	var ledger: Array = []
	func add_stone(n: int, _r: String) -> void:
		stone += n
	func spend(cur: String, n: int, _r: String, _save: bool = true) -> bool:
		if cur == "shard":
			if shard_pool < n: return false
			shard_pool -= n
		elif cur == "gem":
			if gems_cache < n: return false
			gems_cache -= n
		elif cur == "stone":
			if stone < n: return false
			stone -= n
		return true
	func ledger_add(c: String, d: int, r: String) -> void:
		ledger.append([c, d, r])
	func save_to_disk() -> void:
		saves += 1


func _ready() -> void:
	print("=== t_economy: start ===")
	_guard.capture()
	await get_tree().process_frame
	test_data_validates()
	test_ticket_price_curve()
	test_gem_gift()
	test_aid_catalog()
	test_echobox_distribution_and_pity()
	test_echobox_no_repeat_and_recycle()
	test_ticket_buy_cap_and_cost()
	test_mission_board()
	test_store_and_l1_flags()
	test_migration_resets_old_save()
	test_new_fields_survive_reload()
	test_record_run_outcome_and_badges()
	test_spend_and_ledger()
	_guard.restore()
	print("=== t_economy: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_economy: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_economy: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func test_data_validates() -> void:
	_Econ.clear_cache()
	var errs := _Econ.validate()
	_assert(errs.is_empty(), "EconomyDB.validate: %s" % str(errs))
	for t in _Econ.TABLES:
		_assert(_Econ.version(t) >= 1, "bảng %s thiếu version" % t)
	var g := _Econ.get_table("gem")
	_assert(int(g["gift"]["per_day"]) == 300 and int(g["gift"]["balance_cap"]) == 900, "Gem tặng 300/900")
	_assert(int(g["season_gift"]["total"]) == 180, "quà mùa 180")
	var a := _Econ.get_table("aid_prices")["aids"] as Dictionary
	_assert(int(a["R1"]["price"]) == 90 and int(a["R1"]["boss_price"]) == 180, "Continue 90/180")
	_assert(int(a["R1"]["vip_price"]) == 68 and int(a["R1"]["boss_vip_price"]) == 135, "Continue VIP 68/135")
	_assert(int(a["R2"]["price"]) == 15 and int(a["R2"]["pack3"]) == 38, "R2 15 / gói 38")
	_assert(int(a["R4"]["price"]) == 60 and int(a["R5"]["price"]) == 15 and int(a["R6"]["price"]) == 18
		and int(a["R7"]["price"]) == 12 and int(a["R8"]["price"]) == 38 and int(a["R9"]["price"]) == 60, "giá PA-1")
	_assert(not bool(_Econ.get_table("echobox")["boxes"]["season"]["enabled"]), "hộp mùa tắt ở L1")
	_assert(not bool(g["vip_trial"]["enabled"]), "VIP thử tắt ở L1")
	var tiers: Dictionary = _Econ.get_table("missions")["tiers"]
	_assert(tiers["N3"]["enabled"] and not tiers["N4"]["enabled"], "Nhiệm vụ chỉ N1-N3 ở L1")


func test_ticket_price_curve() -> void:
	var want := {1: 200, 5: 245, 10: 310, 15: 395, 20: 505, 30: 825}
	for k in want:
		_assert(EchoBox.ticket_price(k) == want[k], "giá vé thứ %d = %d, có %d" % [k, want[k], EchoBox.ticket_price(k)])


func test_gem_gift() -> void:
	var s := Stub.new()
	var w := LocalGemWallet.new(s)
	var day0 := 1_800_000_000 / 86400 * 86400   # 00:00 UTC của một ngày
	var r := w.claim_daily_gift(day0 + 3600)
	_assert(r["ok"] and r["granted"] == 300 and s.gems_cache == 300, "ngày 1 nhận 300")
	_assert(r["next_utc"] == day0 + 86400, "next_utc = 00:00 UTC kế")
	var again := w.claim_daily_gift(day0 + 80000)
	_assert(not again["ok"] and again["reason"] == "already_claimed" and s.gems_cache == 300, "cùng ngày UTC: không nhận lần hai")
	w.claim_daily_gift(day0 + 86400 + 5)
	w.claim_daily_gift(day0 + 2 * 86400 + 5)
	_assert(s.gems_cache == 900, "3 ngày = 900")
	var capped := w.claim_daily_gift(day0 + 3 * 86400)
	_assert(not capped["ok"] and capped["reason"] == "at_cap" and s.gems_cache == 900, "ở trần 900 không nhận")
	_assert(w.spend(100, "aid:R2") and s.gems_cache == 800, "spend 100")
	var part := w.claim_daily_gift(day0 + 3 * 86400)
	_assert(part["ok"] and part["granted"] == 100 and s.gems_cache == 900, "nhận phần còn trong trần (100)")
	_assert(not w.spend(901, "x") and s.gems_cache == 900, "không đủ Gem thì không trừ")
	w.grant(90, "season_gift")
	_assert(s.gems_cache == 990, "quà mùa không bị trần 900")
	# quay đồng hồ lùi về ngày đã nhận: không nhận lại
	var s3 := Stub.new()
	var w3 := LocalGemWallet.new(s3)
	w3.claim_daily_gift(day0 + 5 * 86400)
	s3.gems_cache = 0
	var back := w3.claim_daily_gift(day0 + 2 * 86400)
	_assert(not back["ok"] and back["reason"] == "already_claimed" and s3.gems_cache == 0, "đồng hồ lùi: already_claimed")
	# 00:00 UTC chính xác vẫn là ngày mới (biên)
	var s2 := Stub.new()
	var w2 := LocalGemWallet.new(s2)
	w2.claim_daily_gift(day0 + 86399)
	_assert(w2.claim_daily_gift(day0 + 86400)["ok"], "23:59:59 rồi 00:00:00 là hai ngày khác nhau")


func _ctx(over: Dictionary = {}) -> Dictionary:
	var c := {"mode": "short", "mission": false, "newcomer": false, "ascension": 0, "node_kind": "combat",
		"node_id": 1, "in_shop": false, "at_pact": false, "party_wiped": false, "rerolls_left": 1,
		"clock_turns_left": 99, "uses": [], "boon_used": false, "vip": false, "free_continue_left": false}
	c.merge(over, true)
	return c


func test_aid_catalog() -> void:
	var o := AidCatalog.offer("R1", _ctx({"party_wiped": true}))
	_assert(o["show"] and o["enabled"] and o["price"] == 90, "Continue thường 90")
	o = AidCatalog.offer("R1", _ctx({"party_wiped": true, "node_kind": "boss"}))
	_assert(o["price"] == 180, "Continue boss 180")
	o = AidCatalog.offer("R1", _ctx({"party_wiped": true, "node_kind": "boss", "vip": true}))
	_assert(o["price"] == 135, "VIP boss 135")
	o = AidCatalog.offer("R1", _ctx({"party_wiped": true, "vip": true}))
	_assert(o["price"] == 68, "VIP thường 68")
	o = AidCatalog.offer("R1", _ctx({"party_wiped": false}))
	_assert(not o["show"], "không chào Continue khi chưa thua")
	o = AidCatalog.offer("R1", _ctx({"party_wiped": true, "uses": [{"aid": "R1", "node_id": 1, "turn": 3}]}))
	_assert(o["show"] and not o["enabled"] and o["reason"] == "cap_type", "Continue 1/run")
	o = AidCatalog.offer("R1", _ctx({"party_wiped": true, "node_kind": "boss", "asc": 0, "free_continue_left": true}))
	_assert(o["price"] == 0 and o["enabled"], "Continue miễn phí mẫu ở boss A0")
	o = AidCatalog.offer("R1", _ctx({"party_wiped": true, "node_kind": "boss", "ascension": 3, "free_continue_left": true}))
	_assert(o["price"] == 180, "hết miễn phí từ A3")
	# newcomer: ẩn mọi Aid, chừa Continue miễn phí
	for id in AidCatalog.IDS:
		_assert(not AidCatalog.offer(id, _ctx({"newcomer": true, "party_wiped": true, "rerolls_left": 0, "in_shop": true, "node_kind": "boss"}))["show"] or id == "R1",
			"newcomer ẩn %s" % id)
	o = AidCatalog.offer("R1", _ctx({"newcomer": true, "party_wiped": true, "node_kind": "elite", "free_continue_left": true}))
	_assert(o["show"] and o["price"] == 0, "newcomer vẫn thấy Continue miễn phí")
	o = AidCatalog.offer("R1", _ctx({"newcomer": true, "party_wiped": true, "node_kind": "elite"}))
	_assert(not o["show"], "newcomer hết lượt miễn phí: ẩn")
	# run Nhiệm vụ: không Aid nào
	for id in AidCatalog.IDS:
		_assert(not AidCatalog.offer(id, _ctx({"mission": true, "party_wiped": true, "rerolls_left": 0, "in_shop": true, "node_kind": "boss"}))["show"], "mission ẩn %s" % id)
	# R2: chỉ khi hết reroll; 2/trận A0-A2, 1/trận từ A3, 4/run
	_assert(not AidCatalog.offer("R2", _ctx({"rerolls_left": 1}))["show"], "R2 ẩn khi còn reroll")
	var r2 := _ctx({"rerolls_left": 0})
	_assert(AidCatalog.offer("R2", r2)["price"] == 15, "R2 15")
	var one := [{"aid": "R2", "node_id": 1, "turn": 1}]
	_assert(AidCatalog.offer("R2", _ctx({"rerolls_left": 0, "uses": one}))["enabled"], "A0: lần 2 trong trận được")
	_assert(not AidCatalog.offer("R2", _ctx({"rerolls_left": 0, "uses": one, "ascension": 3}))["enabled"], "A3: 1/trận")
	_assert(AidCatalog.offer("R2", _ctx({"rerolls_left": 0, "ascension": 3, "node_id": 2, "uses": one}))["enabled"], "A3: trận khác dùng được")
	var four: Array = []
	for i in 4:
		four.append({"aid": "R2", "node_id": 10 + i, "turn": 1})
	_assert(AidCatalog.offer("R2", _ctx({"rerolls_left": 0, "node_id": 99, "uses": four}))["reason"] == "cap_type", "R2 tối đa 4/run")
	# R4 chỉ boss, enrage còn <= 2 lượt, 1/boss
	_assert(not AidCatalog.offer("R4", _ctx({"node_kind": "combat", "clock_turns_left": 1}))["show"], "R4 chỉ ở boss")
	_assert(not AidCatalog.offer("R4", _ctx({"node_kind": "boss", "clock_turns_left": 5}))["show"], "R4 chỉ khi còn <= 2 lượt")
	_assert(AidCatalog.offer("R4", _ctx({"node_kind": "boss", "clock_turns_left": 2}))["price"] == 60, "R4 60")
	_assert(not AidCatalog.offer("R4", _ctx({"node_kind": "boss", "clock_turns_left": 2, "uses": [{"aid": "R4", "node_id": 1, "turn": 1}]}))["enabled"], "R4 1/boss")
	# R5 chỉ A6+, R6 shop 2/run, R7 map 3/run, R8/R9 setup
	_assert(not AidCatalog.offer("R5", _ctx({"at_pact": true, "ascension": 5}))["show"], "R5 chỉ từ A6")
	_assert(AidCatalog.offer("R5", _ctx({"at_pact": true, "ascension": 6}))["price"] == 15, "R5 15")
	var six := [{"aid": "R6", "node_id": 5, "turn": 1}, {"aid": "R6", "node_id": 6, "turn": 1}]
	_assert(AidCatalog.offer("R6", _ctx({"in_shop": true}))["price"] == 18, "R6 18")
	_assert(not AidCatalog.offer("R6", _ctx({"in_shop": true, "node_id": 7, "uses": six}))["enabled"], "R6 2/run")
	var sc := []
	for i in 3:
		sc.append({"aid": "R7", "node_id": i, "turn": 0})
	_assert(AidCatalog.offer("R7", _ctx({"node_kind": "map"}))["price"] == 12, "R7 12")
	_assert(not AidCatalog.offer("R7", _ctx({"node_kind": "map", "uses": sc}))["enabled"], "R7 3/run")
	_assert(AidCatalog.offer("R8", _ctx({"node_kind": "setup"}))["price"] == 38, "Boon 38")
	_assert(not AidCatalog.offer("R8", _ctx({"node_kind": "setup", "boon_used": true}))["enabled"], "1 Boon/run")
	_assert(not AidCatalog.offer("R9", _ctx({"node_kind": "setup", "boon_used": true}))["enabled"], "Kit có Boon: không khi đã có Boon")
	# Quy ước đếm: R8/R9 không nằm trong uses; dòng lỡ có cũng KHÔNG tính vào trần tổng
	var junk := [{"aid": "R8", "node_id": 0, "turn": 0}, {"aid": "R9", "node_id": 0, "turn": 0}]
	var cj := _ctx({"rerolls_left": 0, "node_id": 99, "uses": junk})
	_assert(AidCatalog.offer("R2", cj)["enabled"], "R8/R9 trong uses không tính vào trần tổng")
	# Kit: Boon trong Kit = 1 ô (boon_used) + R2/R7 dùng thật là các dòng uses. Kit đủ dùng = 1 + 2 R2 + 1 R7 = 4 ô
	var kit_uses := [{"aid": "R2", "node_id": 1, "turn": 1}, {"aid": "R2", "node_id": 2, "turn": 1}, {"aid": "R7", "node_id": 3, "turn": 0}]
	var ck := _ctx({"rerolls_left": 0, "node_id": 99, "boon_used": true, "uses": kit_uses})
	_assert(AidCatalog.offer("R2", ck)["enabled"], "sau Kit đủ dùng vẫn còn ô (4/6)")
	ck["uses"] = kit_uses + [{"aid": "R1", "node_id": 4, "turn": 2}, {"aid": "R4", "node_id": 5, "turn": 2}]
	_assert(AidCatalog.offer("R2", ck)["reason"] == "cap_total", "Kit + Continue + R4 = 6 ô: đầy trần tổng")
	_assert(not AidCatalog.offer("R8", _ctx({"node_kind": "setup", "boon_used": true}))["enabled"], "Kit/Boon: 1 Boon/run")
	_assert(AidCatalog.offer("R9", _ctx({"node_kind": "setup"}))["price"] == 60, "Kit 60")
	# trần tổng 6 (A0-A8) / 4 (A9-A10); Boon chiếm 1 ô
	var mix: Array = []
	for i in 5:
		mix.append({"aid": "R7" if i < 3 else "R2", "node_id": 20 + i, "turn": 1})
	var c6 := _ctx({"rerolls_left": 0, "node_id": 99, "uses": mix})
	_assert(AidCatalog.offer("R2", c6)["enabled"], "5 lượt: còn ô thứ 6")
	c6["boon_used"] = true
	var res := AidCatalog.offer("R2", c6)
	_assert(not res["enabled"] and res["reason"] == "cap_total", "5 Aid + Boon = 6: đầy trần tổng")
	var c4 := _ctx({"rerolls_left": 0, "ascension": 9, "node_id": 99, "uses": mix.slice(0, 4)})
	_assert(AidCatalog.offer("R2", c4)["reason"] == "cap_total", "A9: trần tổng 4")
	_assert(AidCatalog.offer("R2", _ctx({"rerolls_left": 0, "gems": 10}))["reason"] == "no_gems", "không đủ Gem")
	_assert(AidCatalog.offer("R99", _ctx())["reason"] == "unknown_aid", "Aid lạ")


func _rng(seed_v: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	return r


func test_echobox_distribution_and_pity() -> void:
	var s := Stub.new()
	s.shard_pool = 777
	var rng := _rng(424242)
	var stones := 0
	var stone_sum := 0
	var cos := 0
	var max_since := {"since_rare": 0, "since_epic": 0, "since_legendary": 0, "since_mythic": 0}
	var by_rar := {}
	var n := 20000
	for i in n:
		s.tickets["normal"] = 5   # nạp vé mỗi lượt: vé giữ tối đa 999 nên không nạp một cục
		var r := EchoBox.open_normal(s, rng)
		if r["kind"] == "stone":
			stones += 1
			stone_sum += int(r["amount"])
		else:
			cos += 1
			by_rar[r["rarity"]] = int(by_rar.get(r["rarity"], 0)) + 1
		for k in max_since:
			max_since[k] = maxi(int(max_since[k]), int(s.echobox_pity.get(k, 0)))
	_assert(stones + cos == n, "mỗi lượt đúng một phần thưởng (Stone XOR cosmetic)")
	_assert(absf(float(stones) / n - 0.60) < 0.01, "Stone ~60%% (có %.3f)" % [float(stones) / n])
	_assert(absf(float(stone_sum) / n - 242.5) < 242.5 * 0.08, "EV Stone ~242,5 (có %.1f)" % [float(stone_sum) / n])
	_assert(s.stone == stone_sum, "Stone vào ví đúng tổng")
	_assert(s.shard_pool == 777, "mở hộp không đổi Shard (INV-V1)")
	_assert(s.tickets["normal"] >= 0, "vé không âm")
	_assert(int(s.echobox_pity.get("opens", 0)) == n, "đếm số lượt mở")
	_assert(int(max_since["since_rare"]) <= 15 and int(max_since["since_epic"]) <= 60 and int(max_since["since_legendary"]) <= 200,
		"pity không bao giờ vượt: %s" % str(max_since))
	_assert(int(by_rar.get("common", 0)) > int(by_rar.get("rare", 0)), "common nhiều hơn rare")
	# Pity cứng: ép bộ đếm tới ngưỡng thì lượt cosmetic kế chắc >= Rare
	var s2 := Stub.new()
	s2.echobox_pity = {"since_rare": 15, "since_epic": 0, "since_legendary": 0, "since_mythic": 0}
	var rng2 := _rng(7)
	var forced_ok := true
	var tested := 0
	for i in 400:
		s2.echobox_pity["since_rare"] = 15
		s2.tickets["normal"] = 1
		var r := EchoBox.open_normal(s2, rng2)
		if r["kind"] == "cosmetic":
			tested += 1
			if EchoBox.RARITIES.find(r["rarity"]) < 2:
				forced_ok = false
	_assert(tested > 50 and forced_ok, "pity 15: lượt cosmetic kế luôn >= Rare (%d mẫu)" % tested)
	var s3 := Stub.new()
	s3.tickets["normal"] = 100
	var r0 := EchoBox.open_normal(s3, _rng(1))
	_assert(r0["ok"], "mở có vé")
	var s4 := Stub.new()
	_assert(not EchoBox.open_normal(s4, _rng(1))["ok"], "không vé thì không mở")


func test_echobox_no_repeat_and_recycle() -> void:
	var s := Stub.new()
	var rng := _rng(99)
	var dup_before_complete := false
	var tickets_in := 0
	var tickets_back := 0
	var opened := 0
	for i in 900:
		s.tickets["normal"] = 1
		var before := (s.cosmetics_owned.size())
		var r := EchoBox.open_normal(s, rng)
		opened += 1
		if r["kind"] == "cosmetic" and r["duplicate"]:
			# trùng chỉ hợp lệ khi tầng đó đã đủ
			var have := 0
			for id in s.cosmetics_owned:
				if String(id).begins_with(String(_Econ.get_table("echobox")["boxes"]["normal"]["pool"][r["rarity"]]["id_prefix"])):
					have += 1
			if have < int(_Econ.get_table("echobox")["boxes"]["normal"]["pool"][r["rarity"]]["count"]):
				dup_before_complete = true
		tickets_back += int(r.get("tickets_back", 0))
		_assert(s.cosmetics_owned.size() >= before, "kho đồ không giảm")
	_assert(not dup_before_complete, "không ra đồ trùng khi tầng còn món chưa có")
	_assert(opened == 900, "đã mở 900 lượt")
	_assert(float(tickets_back) / opened < 0.25, "hồi vé < 0,25/lượt (INV-V3), có %.4f" % [float(tickets_back) / opened])
	# không trùng id trong kho
	var seen := {}
	var uniq := true
	for id in s.cosmetics_owned:
		if seen.has(id):
			uniq = false
		seen[id] = true
	_assert(uniq, "kho không có id lặp")
	# 10 mảnh = 1 vé: ép đủ tầng common rồi mở
	var s2 := Stub.new()
	var box: Dictionary = _Econ.get_table("echobox")["boxes"]["normal"]
	for id in EchoBox.pool_ids(box, "common"):
		s2.cosmetics_owned.append(id)
	var frag := 0
	var cfg := _Econ.get_table("echobox")
	_assert(int(cfg["dup_fragments"]["common"]) * 10 == 30 and int(cfg["fragments_per_ticket"]) == 10, "10 trùng common = 30 mảnh = 3 vé")
	s2.tickets["normal"] = 1
	s2.echobox_pity = {"fragments": 9}
	var rng2 := _rng(5)
	var got_back := false
	for i in 400:
		s2.tickets["normal"] = 1
		var r := EchoBox.open_normal(s2, rng2)
		if r["kind"] == "cosmetic" and r["duplicate"] and r["rarity"] == "common":
			got_back = int(r["tickets_back"]) >= 1
			break
	_assert(got_back, "mảnh 9 + 3 -> hoàn 1 vé, dư 2")
	_assert(int(s2.echobox_pity["fragments"]) < 10, "mảnh lẻ < 10")


func test_ticket_buy_cap_and_cost() -> void:
	var s := Stub.new()
	s.shard_pool = 100000
	var day := "2026-11-03"
	_assert(EchoBox.cost_for(s, day, 1) == 200, "vé đầu 200")
	_assert(EchoBox.cost_for(s, day, 2) == 200 + 210, "2 vé = 200 + 210")
	var r := EchoBox.buy_tickets(s, day, 10)
	_assert(r["ok"] and s.tickets["normal"] == 10 and EchoBox.bought_today(s, day) == 10, "mua 10 vé")
	var spent := 100000 - s.shard_pool
	var expect := 0
	for k in range(1, 11):
		expect += EchoBox.ticket_price(k)
	_assert(spent == expect, "chi %d == tổng giá bậc thang %d" % [spent, expect])
	_assert(EchoBox.cost_for(s, day, 1) == EchoBox.ticket_price(11), "vé thứ 11 tính tiếp bậc")
	_assert(EchoBox.cost_for(s, "2026-11-04", 1) == 200, "sang ngày UTC mới giá reset")
	_assert(EchoBox.cost_for(s, day, 21) == -1, "vượt trần 30 vé/ngày")
	var poor := Stub.new()
	poor.shard_pool = 100
	var rp := EchoBox.buy_tickets(poor, day, 1)
	_assert(not rp["ok"] and rp["reason"] == "no_shards" and poor.tickets["normal"] == 0, "thiếu Shard: không mua")
	EchoBox.grant_tickets(s, 5, "pass")
	_assert(EchoBox.bought_today(s, day) == 10, "vé Pass không tăng bậc giá")
	_assert(s.ledger.has(["ticket", 10, "buy"]), "mua vé có dòng sổ cái")
	var saves_before := s.saves
	EchoBox.buy_tickets(s, day, 1)
	_assert(s.saves == saves_before + 1, "mua vé = đúng MỘT lần save (Shard và vé cùng lúc)")
	var hold := Stub.new()
	hold.shard_pool = 100000
	hold.tickets["normal"] = 995
	_assert(EchoBox.buy_tickets(hold, day, 10)["reason"] == "hold_cap", "giữ tối đa 999 vé")


func test_mission_board() -> void:
	var want := {"N1": 480, "N2": 975, "N3": 1960, "N4": 3960, "N5": 6805, "N6": 16200}
	for k in want:
		_assert(MissionBoard.payout(k) == want[k], "payout %s = %d, có %d" % [k, want[k], MissionBoard.payout(k)])
	var s := Stub.new()
	s.runs = 2
	var offers := MissionBoard.offers("2026-11-03", s)
	_assert(offers.size() == 6, "6 dòng (N4-N6 tắt hiện xám)")
	_assert(offers[0]["lock_reason"] == "newcomer", "chưa qua 5 run: khoá newcomer")
	s.runs = 5
	_assert(MissionBoard.lock_reason("N1", s) == "asc_win", "N1 cần thắng A3")
	s.asc_wins["3"] = 1
	_assert(MissionBoard.lock_reason("N1", s) == "", "đã thắng A3: N1 mở")
	s.asc_wins["7"] = 1
	for k in ["N4", "N5", "N6"]:
		_assert(MissionBoard.lock_reason(k, s) == "disabled", "%s tắt ở L1 (chỉ N1-N3)" % k)
	var a := MissionBoard.offers("2026-11-03", s)
	var b := MissionBoard.offers("2026-11-03", s)
	_assert(a == b, "bảng cùng ngày giống nhau")
	var ruleset_days := {}
	for d in range(1, 29):
		ruleset_days[MissionBoard.rule_set_key("2026-11-%02d" % d, "N2")] = true
	_assert(ruleset_days.size() == 2, "bộ luật A/B đổi theo ngày")
	_assert((a[0]["rules"] as Array).is_empty() and a[0]["stone"] == 4, "N1 chỉ luật chuẩn, 4 Stone")
	# nâng nhà: tắt ở L1
	s.shard_pool = 99999
	s.stone = 99999
	_assert(MissionBoard.upgrade_house(s) == "disabled" and s.mission_house_level == 0 and s.shard_pool == 99999,
		"nâng nhà tắt ở L1, không trừ gì")


func test_migration_resets_old_save() -> void:
	var starter: Dictionary = _Econ.get_table("daily")["starter"]
	var old := {"shard_pool": 9999, "battle_pass_xp": 500, "battle_pass_level": 4, "vault": [],
		"unlocks": ["u_hp", "u_reroll"], "xp": 7000, "bp_claimed": [1, 2, 3], "perks": {"hp4": 2},
		"asc_max": 5, "runs": 12, "wins": 4, "best": 17, "audio_muted": true, "daily_date": "2026-09-01",
		"tutorial_seen": true}
	var old_text := JSON.stringify(old)
	var had_bak := SaveStore.exists(MetaState.V1_BACKUP_PATH)
	var prior_bak := SaveStore.read_text(MetaState.V1_BACKUP_PATH)
	SaveStore.erase(MetaState.V1_BACKUP_PATH)
	SaveStore.write_text(MetaState.SAVE_PATH, old_text)
	MetaState.reload_from_store()
	_assert(SaveStore.read_text(MetaState.V1_BACKUP_PATH) == old_text, "migrate v1 ghi meta_save.v1.bak nguyên bản")
	var bak_ledger := false
	for e in MetaState.ledger:
		if e["c"] == "ticket" and e["r"] == "starter":
			bak_ledger = true
	_assert(bak_ledger, "vé khởi đầu có dòng sổ cái")
	_assert(MetaState.unlocks.is_empty() and MetaState.perks.is_empty(), "unlock + perk cũ bị bỏ")
	_assert(MetaState.xp == 0 and MetaState.bp_claimed.is_empty() and MetaState.battle_pass_level == 1, "Pass cũ reset")
	_assert(MetaState.shard_pool == int(starter["shards"]), "số dư cũ thay bằng khoản khởi đầu (%d)" % MetaState.shard_pool)
	_assert(int(MetaState.tickets["normal"]) == int(starter["tickets"]), "khởi đầu có vé")
	_assert(MetaState.runs == 12 and MetaState.wins == 4 and MetaState.best == 17 and MetaState.asc_max == 5, "thống kê run giữ")
	_assert(MetaState.audio_muted and MetaState.tutorial_seen, "cài đặt + tutorial_seen giữ")
	_assert(MetaState.save_version == MetaState.SAVE_VERSION and MetaState.starter_granted, "đã lên schema mới")
	# Nạp không tự ghi: file vẫn là bản cũ cho tới lần save kế
	var raw = JSON.parse_string(SaveStore.read_text(MetaState.SAVE_PATH))
	_assert(not (raw as Dictionary).has("save_version"), "migrate chỉ trong bộ nhớ, file chưa bị ghi")
	MetaState.save_to_disk()
	var spent_once: int = MetaState.shard_pool - 100
	MetaState.shard_pool = spent_once
	MetaState.save_to_disk()
	MetaState.reload_from_store()
	_assert(MetaState.shard_pool == spent_once, "nạp lại save mới KHÔNG cấp khởi đầu lần hai")
	_assert(MetaState.has_unlock("u_hp") == false, "unlock cũ không quay lại")
	# Bản sao chỉ ghi một lần: save v1 khác đi không đè bản đầu
	SaveStore.write_text(MetaState.SAVE_PATH, JSON.stringify({"shard_pool": 1, "runs": 1}))
	MetaState.reload_from_store()
	_assert(SaveStore.read_text(MetaState.V1_BACKUP_PATH) == old_text, "bản sao v1 không bị ghi đè lần hai")
	# trả lại bản sao của người chơi thật (nếu có)
	SaveStore.erase(MetaState.V1_BACKUP_PATH)
	if had_bak:
		SaveStore.write_text_as(SaveStore.profile, MetaState.V1_BACKUP_PATH, prior_bak, false)
	# Tài khoản mới tinh (không có save): có khoản khởi đầu
	SaveStore.erase(MetaState.SAVE_PATH)
	MetaState.reload_from_store()
	_assert(MetaState.shard_pool == int(starter["shards"]) and MetaState.starter_granted, "tài khoản mới nhận khoản khởi đầu")


func test_new_fields_survive_reload() -> void:
	SaveStore.erase(MetaState.SAVE_PATH)
	MetaState.reload_from_store()
	MetaState.stone = 1234
	MetaState.gems_cache = 321
	MetaState.gem_claim_next_utc = 1_800_086_400
	MetaState.gem_gift_day = "2026-11-03"
	MetaState.tickets = {"normal": 7, "season": 0}
	MetaState.echobox_pity = {"since_rare": 4, "fragments": 6, "buy_day": "2026-11-03", "buy_count": 3}
	MetaState.cosmetics_owned = ["std_c_001", "std_u_002"] as Array[String]
	MetaState.pass_season = {"id": "s1", "xp": 900, "level": 1, "claimed_free": [1]}
	MetaState.vip_until_utc = 1_900_000_000
	MetaState.vip_trial_used = true
	MetaState.mission_house_level = 2
	MetaState.asc_wins = {"3": 2}
	MetaState.full_a9_won = true
	MetaState.aid_hints_off = true
	MetaState.last_daily_reward_utc = "2026-11-03"
	MetaState.save_to_disk()
	MetaState.reload_from_store()
	_assert(MetaState.stone == 1234 and MetaState.gems_cache == 321, "stone/gem qua reload")
	_assert(MetaState.gem_claim_next_utc == 1_800_086_400 and MetaState.gem_gift_day == "2026-11-03", "mốc nhận Gem qua reload")
	_assert(int(MetaState.tickets["normal"]) == 7 and typeof(MetaState.tickets["normal"]) == TYPE_INT, "vé là int sau JSON")
	_assert(int(MetaState.echobox_pity["since_rare"]) == 4 and typeof(MetaState.echobox_pity["since_rare"]) == TYPE_INT
		and String(MetaState.echobox_pity["buy_day"]) == "2026-11-03", "pity giữ kiểu")
	_assert(MetaState.cosmetics_owned.size() == 2 and MetaState.cosmetics_owned[1] == "std_u_002", "kho cosmetic")
	_assert(int(MetaState.pass_season["xp"]) == 900 and int(MetaState.pass_season["claimed_free"][0]) == 1, "pass_season")
	_assert(MetaState.vip_until_utc == 1_900_000_000 and MetaState.vip_trial_used, "VIP")
	_assert(MetaState.mission_house_level == 2 and int(MetaState.asc_wins["3"]) == 2 and MetaState.full_a9_won, "nhà + asc_wins")
	_assert(MetaState.aid_hints_off and MetaState.last_daily_reward_utc == "2026-11-03", "aid_hints_off + daily")


func test_record_run_outcome_and_badges() -> void:
	SaveStore.erase(MetaState.SAVE_PATH)
	MetaState.reload_from_store()
	MetaState.record_run_outcome({"mode": "short", "ascension": 3}, false)
	_assert(MetaState.asc_wins.is_empty(), "thua không ghi asc_wins")
	MetaState.record_run_outcome({"mode": "short", "ascension": 3}, true)
	MetaState.record_run_outcome({"mode": "short", "ascension": 3}, true)
	_assert(int(MetaState.asc_wins["3"]) == 2 and not MetaState.full_a9_won, "thắng A3 hai lần")
	MetaState.record_run_outcome({"mode": "full", "ascension": 8}, true)
	_assert(not MetaState.full_a9_won, "Full A8 chưa tính")
	MetaState.record_run_outcome({"mode": "full", "ascension": 9}, true)
	_assert(MetaState.full_a9_won, "thắng Full A9")
	MetaState.gem_gift_day = ""
	MetaState.gems_cache = 0
	_assert(MetaState.badge_count("store") == 1, "badge store khi có thể nhận Gem")
	MetaState.claim_gem_gift_now()
	_assert(MetaState.badge_count("store") == 0, "badge tắt sau khi nhận")
	MetaState.tickets["normal"] = 3
	_assert(MetaState.badge_count("echobox") == 1 and MetaState.badge_count("không_có") == 0, "badge echobox / màn lạ = 0")


func test_spend_and_ledger() -> void:
	SaveStore.erase(MetaState.SAVE_PATH)
	MetaState.reload_from_store()
	MetaState.shard_pool = 100
	MetaState.stone = 50
	MetaState.ledger = []
	_assert(not MetaState.spend("shard", 101, "x") and MetaState.shard_pool == 100, "thiếu Shard: không trừ")
	_assert(MetaState.spend("shard", 40, "ticket_buy") and MetaState.shard_pool == 60, "trừ Shard")
	_assert(MetaState.spend("stone", 50, "house") and MetaState.stone == 0, "trừ Stone")
	MetaState.add_stone(10, "echobox")
	_assert(MetaState.stone == 10, "add_stone")
	_assert(not MetaState.spend("gem", 1, "aid:R2"), "Gem = 0: không trừ")
	_assert(not MetaState.spend("vàng", 1, "x"), "tiền tệ lạ bị từ chối")
	_assert(MetaState.ledger.size() == 3 and MetaState.ledger[0]["c"] == "shard" and int(MetaState.ledger[0]["d"]) == -40
		and int(MetaState.ledger[0]["b"]) == 60, "sổ cái ghi đúng thay đổi + số dư sau")
	for i in 250:
		MetaState.add_stone(1, "bulk")
	_assert(MetaState.ledger.size() == MetaState.LEDGER_MAX, "sổ cái giữ tối đa %d dòng" % MetaState.LEDGER_MAX)


func test_store_and_l1_flags() -> void:
	_assert(not StoreCatalog.usd_enabled(), "nút USD tắt ở L1")
	var s := Stub.new()
	s.gems_cache = 1000
	_assert(StoreCatalog.buy_ticket_bundle(s, 6) == "" and s.gems_cache == 880 and s.tickets["normal"] == 6, "bundle 6 vé = 120 Gem")
	_assert(StoreCatalog.buy_ticket_bundle(s, 7) == "unknown_bundle", "gói lạ")
	_assert(StoreCatalog.buy_ticket_bundle(s, 100) == "no_gems" and s.tickets["normal"] == 6, "thiếu Gem: không nhận vé")
	_assert(EchoBox.bought_today(s, "2026-11-03") == 0, "vé bundle không tăng bậc giá Shard")
	_assert(StoreCatalog.cosmetic_price("rare") == 90 and StoreCatalog.cosmetic_price("mythic") == 720, "giá cosmetic tạm 90..720")
	_assert(StoreCatalog.buy_cosmetic(s, "frame_u_x", "epic") == "" and s.gems_cache == 700 and s.cosmetics_owned.has("frame_u_x"), "mua cosmetic epic 180")
	_assert(StoreCatalog.buy_cosmetic(s, "frame_u_x", "epic") == "owned" and s.gems_cache == 700, "đã có: không trừ")
	_assert(StoreCatalog.buy_cosmetic(s, "x", "common") == "not_for_sale", "common không bán trực tiếp")
	_assert(bool(_Econ.get_table("aid_prices")["ranked_allows_kit_boon"]), "ranked cho dùng Kit/Boon")
	var r := AidCatalog.offer("R8", _ctx({"node_kind": "setup", "mode": "ranked"}))
	_assert(r["show"] and r["enabled"], "Boon hiện ở ranked")
	var d: Dictionary = _Econ.get_table("daily")["daily_runs"]
	_assert(int(d["max_per_day"]) == 3 and bool(d["shared_seed"]), "Daily tối đa 3 lần/ngày UTC, chung seed")
