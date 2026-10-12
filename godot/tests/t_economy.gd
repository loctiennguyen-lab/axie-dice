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
	var unlocks: Array = []
	var pass_season := {}
	var _wallet: GemWallet = null
	func add_stone(n: int, _r: String, _save: bool = true) -> void:
		stone += n
	func add_shards(n: int, _r: String, _save: bool = true) -> void:
		shard_pool += n
	func unlock_price(_id: String) -> int:
		return 220
	func gem_wallet() -> GemWallet:
		if _wallet == null:
			_wallet = LocalGemWallet.new(self)
		return _wallet
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
	test_remote_wallet_wiring()
	test_pass_v2()
	test_pass_weekly_tasks()
	test_migration_resets_old_save()
	test_new_fields_survive_reload()
	test_record_run_outcome_and_badges()
	test_spend_and_ledger()
	test_mission_stake()
	test_daily_claim_stone()
	test_pass_wrappers()
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
	_assert(StoreCatalog.buy_cosmetic(s, "std_e_001", "epic") == "" and s.gems_cache == 700 and s.cosmetics_owned.has("std_e_001"), "mua cosmetic epic 180")
	_assert(StoreCatalog.buy_cosmetic(s, "std_e_001", "epic") == "owned" and s.gems_cache == 700, "đã có: không trừ")
	_assert(StoreCatalog.buy_cosmetic(s, "std_c_001", "common") == "not_for_sale", "common không bán trực tiếp")
	_assert(StoreCatalog.buy_cosmetic(s, "die_e_rune", "epic") == "not_in_normal_pool" and s.gems_cache == 700, "đồ mùa không bán trực tiếp")
	_assert(StoreCatalog.buy_cosmetic(s, "std_e_999", "epic") == "not_in_normal_pool", "id ngoài pool bị từ chối")
	var full := Stub.new()
	full.gems_cache = 5000
	full.tickets["normal"] = 990
	var saves0 := full.saves
	_assert(StoreCatalog.buy_ticket_bundle(full, 15) == "hold_cap" and full.gems_cache == 5000, "vượt trần 999 vé: từ chối, chưa trừ Gem")
	var one := Stub.new()
	one.gems_cache = 500
	_assert(StoreCatalog.buy_ticket_bundle(one, 6) == "" and one.saves == 1, "bundle = đúng một lần save")
	_assert(bool(_Econ.get_table("aid_prices")["ranked_allows_kit_boon"]), "ranked cho dùng Kit/Boon")
	var r := AidCatalog.offer("R8", _ctx({"node_kind": "setup", "mode": "ranked"}))
	_assert(r["show"] and r["enabled"], "Boon hiện ở ranked")
	var d: Dictionary = _Econ.get_table("daily")["daily_runs"]
	_assert(int(d["max_per_day"]) == 3 and bool(d["shared_seed"]), "Daily tối đa 3 lần/ngày UTC, chung seed")


class FakeNet extends RefCounted:
	var balance := 100
	func call_net(method: String, path: String, _body: String, done: Callable) -> void:
		if path == "/api/gem/claim":
			balance += 300
			done.call(200, JSON.stringify({"ok": true, "granted": 300, "reason": "", "next_utc": 1_900_000_000, "balance": balance}))
		else:
			done.call(200, JSON.stringify({"gem": balance}))


func test_remote_wallet_wiring() -> void:
	SaveStore.erase(MetaState.SAVE_PATH)
	MetaState.reload_from_store()
	var net := FakeNet.new()
	var w := RemoteGemWallet.new(net.call_net)
	MetaState.use_remote_gem_wallet(w)
	w.refresh()
	_assert(MetaState.gems_cache == 100, "balance_changed cập nhật gems_cache (100)")
	var got := {}
	MetaState.claim_gem_gift_async(func(r: Dictionary) -> void: got.merge(r))
	_assert(got.get("ok", false) and int(got.get("granted", 0)) == 300, "claim async remote trả kết quả server")
	_assert(MetaState.gems_cache == 400 and MetaState.gem_claim_next_utc == 1_900_000_000, "gems_cache + next_utc đồng bộ")
	_assert(MetaState.badge_count("store") == 0, "badge store tắt khi next_utc ở tương lai")
	# ví local vẫn chạy cùng API async
	MetaState.set_gem_wallet(LocalGemWallet.new(MetaState))
	MetaState.gems_cache = 0
	MetaState.gem_gift_day = ""
	MetaState.gem_claim_next_utc = 0
	var loc := {}
	MetaState.claim_gem_gift_async(func(r: Dictionary) -> void: loc.merge(r))
	_assert(loc.get("ok", false) and MetaState.gems_cache == 300, "claim async local")
	MetaState.set_gem_wallet(null)


class NoLocalGrantWallet extends GemWallet:
	func balance() -> int:
		return 0


func test_pass_v2() -> void:
	_assert(not PassV2.season_active("2026-11-02") and PassV2.season_active("2026-11-03"), "mùa 1 bắt đầu 3/11")
	_assert(PassV2.season_active("2026-12-28") and not PassV2.season_active("2026-12-29"), "mùa 1 hết 29/12 (loại trừ)")
	_assert(PassV2.level_for_xp(499) == 0 and PassV2.level_for_xp(500) == 1 and PassV2.level_for_xp(1040) == 2
		and PassV2.level_for_xp(32400) == 30 and PassV2.level_for_xp(99999) == 30, "level theo XP cộng dồn")
	var d1 := "2026-11-03"
	var s := Stub.new()
	_assert(PassV2.add_run_xp(s, 1000, "2026-11-02") == 0, "ngoài mùa không nhận XP")
	_assert(PassV2.add_run_xp(s, 1000, d1) == 1000, "1.000 XP đầu: 100%")
	_assert(PassV2.add_run_xp(s, 1000, d1) == 600, "500 còn lại 100% + 500 x 20% = 600")
	_assert(PassV2.add_run_xp(s, 5000, d1) == 400, "trần ngày 2.000: chỉ nhận 400")
	_assert(PassV2.add_run_xp(s, 100, d1) == 0 and int(s.pass_season["xp"]) == 2000, "đầy trần ngày")
	_assert(PassV2.add_run_xp(s, 300, "2026-11-04") == 300, "ngày UTC mới: trần reset")
	_assert(PassV2.add_daily_bonus_xp(s, "2026-11-04") == 100 and int(s.pass_season["xp"]) == 2400, "thưởng ngày +100 XP, không bị trần run")
	_assert(int(s.pass_season["level"]) == PassV2.level_for_xp(2400), "level cập nhật")
	_assert(s.pass_season["id"] == "s1", "pass_season thuộc mùa s1")
	# ensure_season: mùa khác thì reset
	s.pass_season = PassV2.new_state("s0")
	s.pass_season["xp"] = 777
	PassV2.add_run_xp(s, 10, d1)
	_assert(int(s.pass_season["xp"]) == 10 and s.pass_season["id"] == "s1", "mùa mới reset XP")

	# claim từng mốc
	var c := Stub.new()
	c.pass_season = PassV2.new_state("s1")
	_assert(PassV2.claim_free(c, 1)["reason"] == "not_reached", "chưa đạt level 1")
	c.pass_season["xp"] = 500
	var r := PassV2.claim_free(c, 1)
	_assert(r["ok"] and c.shard_pool == 300, "lv1 = 300 Shard")
	_assert(PassV2.claim_free(c, 1)["reason"] == "already_claimed" and c.shard_pool == 300, "không nhận trùng")
	_assert(PassV2.claimable_levels(c).is_empty(), "không còn mốc chờ")
	_assert(PassV2.claim_free(c, 99)["reason"] == "no_such_level", "level lạ")
	# unlock: cấp lần đầu, trùng thì hoàn Shard bằng giá shop
	c.pass_season["xp"] = 2240
	var shard0 := c.shard_pool
	PassV2.claim_free(c, 4)
	_assert(c.unlocks.has("u_reroll") and c.shard_pool == shard0, "lv4 cấp unlock u_reroll")
	var o := Stub.new()
	o.pass_season = PassV2.new_state("s1")
	o.pass_season["xp"] = 2240
	o.unlocks = ["u_reroll"]
	var ro := PassV2.claim_free(o, 4)
	_assert(ro["ok"] and o.shard_pool == 220 and o.unlocks.size() == 1, "đã có unlock: hoàn Shard giá shop, không cấp lại (ECO-13)")
	# mốc Gem
	var g := Stub.new()
	g.pass_season = PassV2.new_state("s1")
	g.pass_season["xp"] = 6800
	var rg := PassV2.claim_free(g, 10)
	_assert(rg["ok"] and g.gems_cache == 90 and g.shard_pool == 500 and int(g.tickets["normal"]) == 1, "lv10: 500 Shard + 1 vé + 90 Gem")
	# ví không cấp local được: từ chối cả mốc, không đánh dấu
	var rm := Stub.new()
	rm.pass_season = PassV2.new_state("s1")
	rm.pass_season["xp"] = 6800
	rm._wallet = NoLocalGrantWallet.new()
	var rr := PassV2.claim_free(rm, 10)
	_assert(not rr["ok"] and rr["reason"] == "gem_needs_server" and rm.shard_pool == 0
		and (rm.pass_season["claimed_free"] as Array).is_empty(), "ví remote chưa có endpoint: không nhận, không mất mốc")
	# nhận hết 30 level: đúng tổng đã chốt
	var all := Stub.new()
	all.pass_season = PassV2.new_state("s1")
	all.pass_season["xp"] = 32400
	for lv in PassV2.claimable_levels(all):
		_assert(PassV2.claim_free(all, lv)["ok"], "claim lv%d" % lv)
	_assert(all.shard_pool == 4800 and all.stone == 16500 and int(all.tickets["normal"]) == 12, "tổng Pass: 4.800 Shard, 16.500 Stone, 12 vé")
	_assert(all.gems_cache == 180 and all.unlocks.size() == 5, "180 Gem (2 x 90) và 5 unlock")
	_assert(all.cosmetics_owned.has("frame_l_sovereign") and all.cosmetics_owned.has("title:LUNACIA SOVEREIGN"), "cosmetic + danh hiệu lv30")
	_assert(PassV2.claimable_levels(all).is_empty(), "claim hết, không còn gì chờ")
	# vòng lặp sau lv30
	all.pass_season["xp"] = 32400 + 4500
	_assert(PassV2.post30_pending(all) == 2, "4.500 XP dư = 2 vòng")
	_assert(PassV2.claim_post30(all) == 100 and all.shard_pool == 4900, "2 vòng = 100 Shard")
	_assert(PassV2.claim_post30(all) == 0, "không nhận trùng vòng")
	all.pass_season["xp"] = 32400 + 6000
	_assert(PassV2.post30_pending(all) == 1, "thêm một vòng mới")
	var low := Stub.new()
	low.pass_season = PassV2.new_state("s1")
	low.pass_season["xp"] = 30000
	_assert(PassV2.post30_pending(low) == 0, "chưa tới lv30: không có vòng")
	var pr := PassV2.premium_state()
	_assert(pr["locked"] and pr["label"] == "Season 2", "premium khoá, nhãn Season 2")
	# MetaState: các key mới của pass_season qua reload
	SaveStore.erase(MetaState.SAVE_PATH)
	MetaState.reload_from_store()
	MetaState.pass_season = {"id": "s1", "xp": 1234, "level": 2, "claimed_free": [1], "day": "2026-11-03", "day_xp": 900, "post30_claimed": 2}
	MetaState.save_to_disk()
	MetaState.reload_from_store()
	_assert(int(MetaState.pass_season["day_xp"]) == 900 and String(MetaState.pass_season["day"]) == "2026-11-03"
		and int(MetaState.pass_season["post30_claimed"]) == 2, "pass_season giữ day/day_xp/post30_claimed qua reload")
	_assert(MetaState.unlock_price("u_reroll") > 0, "unlock_price đọc từ ContentDB")


func test_pass_weekly_tasks() -> void:
	# 3/11/2026 là thứ Ba -> thứ Hai của tuần đó là 2/11
	_assert(PassV2.week_key("2026-11-03") == "2026-11-02", "tuần bắt đầu thứ Hai (3/11 -> 2/11)")
	_assert(PassV2.week_key("2026-11-02") == "2026-11-02" and PassV2.week_key("2026-11-08") == "2026-11-02", "thứ Hai..Chủ nhật cùng tuần")
	_assert(PassV2.week_key("2026-11-09") == "2026-11-09", "thứ Hai kế = tuần mới")
	var s := Stub.new()
	s.pass_season = PassV2.new_state("s1")
	PassV2.record_run(s, "2026-10-30", true, true)
	_assert((s.pass_season["weekly"] as Dictionary).is_empty(), "ngoài mùa không đếm")
	var d := "2026-11-04"
	for i in 4:
		PassV2.record_run(s, d, false, false)
	var st := PassV2.weekly_status(s, d)
	_assert(st.size() == 3 and st[0]["id"] == "play_runs" and st[0]["progress"] == 4 and not st[0]["done"], "4/5 run: chưa xong")
	_assert(not PassV2.claim_weekly(s, d, "play_runs", d)["ok"] and PassV2.claim_weekly(s, d, "play_runs", d)["reason"] == "not_done", "chưa xong thì không nhận")
	PassV2.record_run(s, d, true, true)
	PassV2.record_run(s, d, true, false)
	st = PassV2.weekly_status(s, d)
	_assert(st[0]["done"] and st[0]["progress"] == 5 and st[1]["done"] and st[1]["progress"] == 2 and st[2]["done"], "6 run, 2 thắng, 1 chạm boss: cả 3 xong (tiến độ kẹp ở target)")
	_assert(PassV2.weekly_claimable(s, d).size() == 3, "3 việc chờ nhận")
	var xp0 := int(s.pass_season.get("xp", 0))
	var r := PassV2.claim_weekly(s, d, "win_runs", d)
	_assert(r["ok"] and r["xp"] == 500 and int(s.pass_season["xp"]) == xp0 + 500, "nhận 500 XP")
	_assert(PassV2.claim_weekly(s, d, "win_runs", d)["reason"] == "already_claimed", "không nhận trùng")
	_assert(PassV2.claim_weekly(s, d, "nope", d)["reason"] == "unknown_task", "việc lạ")
	PassV2.claim_weekly(s, d, "play_runs", d)
	PassV2.claim_weekly(s, d, "reach_boss", d)
	_assert(int(s.pass_season["xp"]) == xp0 + 1500, "tổng 1.500 XP/tuần")
	# tuần sau: tiến độ riêng; tuần trước vẫn xem được
	var nxt := "2026-11-10"
	PassV2.record_run(s, nxt, true, false)
	_assert(PassV2.weekly_status(s, nxt)[0]["progress"] == 1 and PassV2.weekly_status(s, d)[0]["progress"] == 5, "mỗi tuần một bộ đếm")
	var late := Stub.new()
	late.pass_season = PassV2.new_state("s1")
	for i in 5:
		PassV2.record_run(late, "2026-11-04", true, true)
	_assert(PassV2.claim_weekly(late, "2026-11-04", "play_runs", "2026-11-20")["reason"] == "week_over", "qua tuần: không nhận được nữa")
	_assert(PassV2.claim_weekly(late, "2026-11-04", "play_runs", "2026-11-08")["ok"], "Chủ nhật cuối tuần vẫn nhận được")
	_assert(PassV2.weekly_claimable(late, "2026-11-10").is_empty(), "tuần mới: không còn gì chờ nhận của tuần cũ")
	_assert(PassV2.claim_weekly(late, "2026-12-29", "win_runs", "2026-12-29")["reason"] == "season_over", "hết mùa: không nhận XP")
	# MetaState: record_run_outcome đếm run (trong mùa theo ngày thật nên chỉ kiểm không lỗi) + qua reload
	SaveStore.erase(MetaState.SAVE_PATH)
	MetaState.reload_from_store()
	MetaState.pass_season = PassV2.new_state("s1")
	PassV2.record_run(MetaState, "2026-11-04", true, true)
	MetaState.save_to_disk()
	MetaState.reload_from_store()
	var wk: Dictionary = MetaState.pass_season["weekly"]
	_assert(wk.has("2026-11-02") and int(wk["2026-11-02"]["runs"]) == 1 and int(wk["2026-11-02"]["boss"]) == 1
		and typeof(wk["2026-11-02"]["runs"]) == TYPE_INT, "weekly qua reload giữ kiểu int")
	MetaState.record_run_outcome({"mode": "short", "ascension": 0, "reached_boss": true}, false)
	# Save cũ không có "weekly": load được, đếm tiếp bình thường
	MetaState.pass_season = {"id": "s1", "xp": 300, "level": 0, "claimed_free": [], "day": "", "day_xp": 0, "post30_claimed": 0}
	MetaState.save_to_disk()
	MetaState.reload_from_store()
	_assert(int(MetaState.pass_season["xp"]) == 300 and (MetaState.pass_season.get("weekly", {}) as Dictionary).is_empty(), "save cũ không có weekly: load được, weekly rỗng")
	PassV2.record_run(MetaState, "2026-11-04", false, false)
	_assert(PassV2.weekly_status(MetaState, "2026-11-04")[0]["progress"] == 1, "save cũ: đếm run tiếp được")


func _fresh_meta(shards: int, locked: int) -> void:
	SaveStore.erase(MetaState.SAVE_PATH)
	MetaState.reload_from_store()
	MetaState.shard_pool = shards
	MetaState.starter_shard_locked = locked
	MetaState.stone = 0
	MetaState.mission_escrow = {}
	MetaState.mission_stone_day = {"day": "", "n": 0}
	MetaState.save_to_disk()


## Escrow cược Nhiệm vụ: take / thắng / thua / bỏ / idempotent / hoàn / khởi động lại / thiếu / starter.
func test_mission_stake() -> void:
	var has_run := [false]   # điều khiển tường minh "có save run không", không đọc user dir thật
	MetaState.saved_run_probe = func() -> bool: return has_run[0]
	_test_mission_stake_body(has_run)
	MetaState.saved_run_probe = Callable()


func _test_mission_stake_body(has_run: Array) -> void:
	var m1 := ""
	var new_id := ""
	var pay := MissionBoard.payout("N1")   # 300 x 1.6 = 480
	_fresh_meta(1000, 0)
	m1 = MetaState.take_mission_stake("N1", 300)
	_assert(m1 != "" and MetaState.shard_pool == 700 and int(MetaState.mission_escrow["stake"]) == 300, "take: trừ cược, ghi escrow")
	MetaState.record_run_outcome({"mode": "short", "ascension": 3, "mission_id": m1}, true)
	_assert(MetaState.shard_pool == 700 + pay and MetaState.stone == 4 and MetaState.mission_escrow.is_empty(), "thắng: trả payout + Stone, đóng escrow")
	_assert(not MetaState.settle_mission_stake(true) and MetaState.shard_pool == 700 + pay, "settle lần hai: không trả thêm")
	MetaState.record_run_outcome({"mode": "short", "ascension": 3, "mission_id": m1}, true)
	_assert(MetaState.shard_pool == 700 + pay, "record_run_outcome lặp: không trả thêm")
	# thua
	_fresh_meta(1000, 0)
	var m3 := MetaState.take_mission_stake("N2")
	MetaState.record_run_outcome({"mission_id": m3}, false)
	_assert(MetaState.shard_pool == 500 and MetaState.mission_escrow.is_empty() and MetaState.stone == 0, "thua: mất cược, không Stone")
	# bỏ run
	_fresh_meta(1000, 0)
	MetaState.take_mission_stake("N1")
	_assert(MetaState.settle_mission_stake(false) and MetaState.shard_pool == 700 and not MetaState.settle_mission_stake(false), "bỏ: mất cược, idempotent")
	# run thường kết thúc: không đụng escrow
	_fresh_meta(1000, 0)
	var m5 := MetaState.take_mission_stake("N1")
	MetaState.record_run_outcome({"mode": "short", "ascension": 0}, true)
	_assert(not MetaState.mission_escrow.is_empty(), "run thường (không mission_id): escrow nguyên")
	# khởi động lại giữa run
	MetaState.reload_from_store()
	_assert(int(MetaState.mission_escrow.get("stake", 0)) == 300 and MetaState.shard_pool == 700, "restart: escrow + số dư còn")
	MetaState.record_run_outcome({"mission_id": m5}, true)
	_assert(MetaState.shard_pool == 700 + pay, "restart rồi thắng: trả đúng một lần")
	# hoàn
	_fresh_meta(1000, 0)
	MetaState.take_mission_stake("N3")
	_assert(MetaState.refund_mission_stake() and MetaState.shard_pool == 1000 and not MetaState.refund_mission_stake(), "refund: trả đúng cược, một lần")
	# thiếu / starter / tier tắt / sai stake
	_fresh_meta(200, 0)
	_assert(MetaState.take_mission_stake("N1") == "" and MetaState.shard_pool == 200 and MetaState.mission_escrow.is_empty(), "thiếu Shard: false, không đổi")
	_fresh_meta(700, 500)
	_assert(MetaState.stake_usable_shards() == 200 and MetaState.take_mission_stake("N1") == "", "starter không tính làm cược")
	_fresh_meta(800, 500)
	_assert(MetaState.take_mission_stake("N1") != "" and MetaState.shard_pool == 500 and MetaState.starter_shard_locked == 500, "đủ phần dùng được: cược không đụng starter")
	_fresh_meta(5000, 0)
	_assert(MetaState.take_mission_stake("N4") == "" and MetaState.take_mission_stake("N1", 999) == "" and MetaState.take_mission_stake("ZZ") == "", "tier tắt/lạ, sai stake: từ chối")
	# spend thường tiêu starter trước
	_fresh_meta(800, 500)
	MetaState.spend("shard", 100, "t")
	_assert(MetaState.starter_shard_locked == 400 and MetaState.stake_usable_shards() == 300, "spend thường tiêu phần starter trước")
	# save cũ không có field mới
	var raw: Dictionary = JSON.parse_string(SaveStore.read_text(MetaState.SAVE_PATH))
	raw.erase("mission_escrow"); raw.erase("starter_shard_locked"); raw.erase("mission_stone_day")
	SaveStore.write_text(MetaState.SAVE_PATH, JSON.stringify(raw))
	MetaState.reload_from_store()
	_assert(MetaState.mission_escrow.is_empty() and MetaState.starter_shard_locked == 0, "save cũ: load được, mặc định rỗng")
	# R: bỏ ngay sau khi mua = chỉ mất cược (R tích theo tiến độ, 0 lúc đầu)
	_fresh_meta(1000, 0)
	MetaState.take_mission_stake("N1")
	MetaState.settle_mission_stake(false)
	_assert(MetaState.shard_pool == 700, "mua rồi bỏ ngay: -cược")
	# orphan: escrow mở nhưng không còn run lưu -> đóng thua rồi cho take mới
	_fresh_meta(1000, 0)
	var old := MetaState.take_mission_stake("N1")
	new_id = MetaState.take_mission_stake("N1")
	_assert(new_id != "" and new_id != old and MetaState.shard_pool == 400 and MetaState.mission_escrow["mission_id"] == new_id, "escrow mồ côi: đóng thua, nhận cược mới")
	# --- review fixes ---
	# nonce: mỗi lần nhận cược một id khác, không rỗng
	_fresh_meta(2000, 0)
	var n1 := MetaState.take_mission_stake("N1")
	MetaState.refund_mission_stake()
	var n2 := MetaState.take_mission_stake("N1")
	_assert(n1 != "" and n2 != "" and n1 != n2 and MetaState.current_mission_id() == n2, "nonce khác nhau mỗi lần nhận")
	# run không cược (id rỗng / id khác) không chốt được escrow
	_assert(not MetaState.settle_mission_for_run("", true) and not MetaState.settle_mission_for_run(n1, true) and not MetaState.mission_escrow.is_empty(), "id rỗng/cũ: không chốt escrow")
	MetaState.record_run_outcome({"mission_id": ""}, true)
	_assert(not MetaState.mission_escrow.is_empty(), "record_run_outcome id rỗng: escrow nguyên")
	# refund sau khi run bắt đầu: từ chối
	var saved_phase := RunState.phase
	RunState.phase = RunState.RunPhase.MAP
	_assert(not MetaState.refund_mission_stake() and not MetaState.mission_escrow.is_empty(), "refund khi RunState đang chạy: từ chối")
	RunState.phase = saved_phase
	has_run[0] = true
	_assert(not MetaState.refund_mission_stake() and not MetaState.mission_escrow.is_empty(), "refund khi có save run: từ chối")
	_assert(MetaState.take_mission_stake("N1") == "", "đang có run lưu + escrow mở: không nhận cược mới")
	has_run[0] = false
	# kill-gap: chốt trước khi xoá save run; reload vẫn thấy đã trả, không trả hai lần
	var before := MetaState.shard_pool
	_assert(MetaState.settle_mission_for_run(n2, true), "settle_mission_for_run khớp id")
	MetaState.reload_from_store()
	_assert(MetaState.mission_escrow.is_empty() and MetaState.shard_pool == before + pay, "kill sau settle: thắng còn nguyên sau reload")
	MetaState.record_run_outcome({"mission_id": n2}, true)
	_assert(MetaState.shard_pool == before + pay, "end_run chạy lại sau reload: không trả hai lần")
	# abandon = thua
	_fresh_meta(1000, 0)
	MetaState.take_mission_stake("N1")
	MetaState.settle_mission_stake(false)
	MetaState.reload_from_store()
	_assert(MetaState.mission_escrow.is_empty() and MetaState.shard_pool == 700, "abandon: đóng thua, bền qua reload")


## claim_daily_mission: +500 Stone (daily.json) vào sổ cái, một lần/ngày; cờ ngày + đếm ngày tuần bền qua reload.
func test_daily_claim_stone() -> void:
	_fresh_meta(0, 0)
	var want := int((_Econ.get_table("daily").get("daily_reward", {}) as Dictionary).get("stone", -1))
	_assert(want > 0 and not MetaState.daily_done_today() and MetaState.weekly_daily_days() == 0, "daily: trạng thái đầu sạch")
	_assert(MetaState.claim_daily_mission(), "daily: nhận lần đầu")
	_assert(MetaState.stone == want, "daily: Stone = daily.json (%d)" % want)
	var led := 0
	for l in MetaState.ledger:
		if String(l.get("c", "")) == "stone" and String(l.get("r", "")) == "daily":
			led += int(l.get("d", 0))
	_assert(led == want, "daily: Stone vào sổ cái")
	_assert(not MetaState.claim_daily_mission() and MetaState.stone == want, "daily: lần hai cùng ngày không cộng thêm")
	_assert(MetaState.daily_done_today() and MetaState.weekly_daily_days() == 1, "daily: cờ hôm nay + 1 ngày trong tuần")
	_assert(MetaState.weekly_daily_min_days() == 4, "daily: ngưỡng tuần từ data")
	MetaState.save_to_disk()
	MetaState.reload_from_store()
	_assert(MetaState.stone == want and MetaState.daily_done_today() and MetaState.weekly_daily_days() == 1, "daily: bền qua reload")
	MetaState.daily_date = "2000-01-01"
	MetaState.daily_week = {"week": "2000-01-03", "n": 3}
	_assert(not MetaState.daily_done_today() and MetaState.weekly_daily_days() == 0, "daily: tuần cũ không tính")
	MetaState.claim_daily_mission()
	_assert(MetaState.weekly_daily_days() == 1, "daily: sang tuần mới đếm lại từ 1")


## MetaState.pass_state() chỉ đọc + pass_claim_post30() đi qua PassV2.
func test_pass_wrappers() -> void:
	_fresh_meta(0, 0)
	var st := MetaState.pass_state()
	for k in ["season_id", "active", "xp", "level", "max_xp", "claimed_free", "claimable_levels", "post30_pending", "premium", "week_key", "weekly"]:
		_assert(st.has(k), "pass_state có key %s" % k)
	_assert(MetaState.pass_claim_post30() == 0, "post30: chưa có vòng thì 0")
	MetaState.pass_season["id"] = "x"
	MetaState.pass_season["xp"] = PassV2.max_xp() + 4000
	_assert(int(MetaState.pass_state()["post30_pending"]) == 2, "post30_pending = 2 vòng")
	var before := MetaState.shard_pool
	var got := MetaState.pass_claim_post30()
	_assert(got > 0 and MetaState.shard_pool == before + got and int(MetaState.pass_state()["post30_pending"]) == 0, "post30: nhận Shard, hết vòng chờ")
	st["claimed_free"].append(99)
	_assert(not (MetaState.pass_season["claimed_free"] as Array).has(99), "pass_state trả bản sao")
