extends Node
var _failures: Array[String] = []
var _checks := 0
func _assert(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_failures.append(m)
func _done(n: String) -> void:
	if _failures.is_empty():
		print("%s: PASS — %d checks OK" % [n, _checks])
		get_tree().quit(0)
		return
	for f in _failures:
		print("%s: FAIL — %s" % [n, f])
	get_tree().quit(1)
func _start(seed: int, extra: Dictionary = {}) -> void:
	RunState.reset()
	var p := {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "mode": "short", "ascension": 0, "ranked": false,
		"bonuses": {}, "loadout": {"rules_on": false}}
	for k in extra:
		p[k] = extra[k]
	RunState.start_new_run_seeded(seed, p)
func _axes(offer: Array) -> Array:
	var a: Array = []
	for c in offer:
		a.append(String(c["axis"]))
	return a

func _keys(pool: Array) -> Array:
	var k: Array = []
	for d in pool:
		k.append(String(d.id))
	return k

func _ready() -> void:
	CoreTestUtil.enable()
	# requires: class_pair needs 2 Axie of one class
	var diff := CoreTestUtil.ctx([], [], ["plant1", "beast1", "aqua1"])
	var pair := CoreTestUtil.ctx([], [], ["plant1", "plant2", "aqua1"])
	_assert(not _keys(CoreOffer.valid_pool(diff)).has("c_test_req_pair"), "no class pair -> filtered")
	_assert(_keys(CoreOffer.valid_pool(pair)).has("c_test_req_pair"), "class pair -> offered")
	# requires: face:poison
	_assert(_keys(CoreOffer.valid_pool(CoreTestUtil.ctx([], [], ["plant1", "beast1"]))).has("c_test_req_poison") == false, "no poison face -> filtered")
	_assert(_keys(CoreOffer.valid_pool(CoreTestUtil.ctx([], [], ["plant1", "reptile1"]))).has("c_test_req_poison"), "poison face -> offered")
	# excludes: rule:<id>
	_assert(_keys(CoreOffer.valid_pool(CoreTestUtil.ctx(["rule_test_a"]))).has("c_test_excl_rule"), "other rule: offered")
	_assert(not _keys(CoreOffer.valid_pool(CoreTestUtil.ctx(["rule_test_b"]))).has("c_test_excl_rule"), "excluded by the held rule")
	# unknown token fails closed on requires
	_assert(not CoreOffer.token_ok("nonsense:1", CoreTestUtil.ctx()), "unknown token is false")
	_assert(CoreOffer.token_ok("faces_distinct:3", CoreTestUtil.ctx()) and not CoreOffer.token_ok("faces_distinct:99", CoreTestUtil.ctx()), "faces_distinct")
	_assert(CoreOffer.token_ok("owned:c_test_dice_moss_a", CoreTestUtil.ctx(["c_test_dice_moss_a"])), "owned token")
	_assert(CoreOffer.token_ok("owned_axis:dice", CoreTestUtil.ctx(["c_test_dice_moss_a"])), "owned_axis token")
	# quest: not at pick 1, not in the first run, one at a time
	_assert(not _keys(CoreOffer.valid_pool(CoreTestUtil.ctx([], [], ["plant1"], 0))).has("c_test_quest_amber"), "no quest on pick 1")
	_assert(_keys(CoreOffer.valid_pool(CoreTestUtil.ctx([], [], ["plant1"], 1))).has("c_test_quest_amber"), "quest from pick 2")
	_assert(not _keys(CoreOffer.valid_pool(CoreTestUtil.ctx([], [], ["plant1"], 1, true))).has("c_test_quest_amber"), "no quest in the first run")
	_assert(not _keys(CoreOffer.valid_pool(CoreTestUtil.ctx(["c_test_quest_amber"]))).has("c_test_quest_amber"), "owned never again")
	# disabled / hidden / owned / seen
	_assert(not _keys(CoreOffer.valid_pool(CoreTestUtil.ctx([], ["c_test_dice_moss_a"]))).has("c_test_dice_moss_a"), "seen filtered")
	var d = RelicRegistry.get_def("c_test_dice_moss_b")
	d.disabled = true
	_assert(not _keys(CoreOffer.valid_pool(CoreTestUtil.ctx())).has("c_test_dice_moss_b"), "disabled flag hides a Core")
	d.disabled = false
	# old relics and Run Rules are never in the Core pool
	for k in _keys(CoreOffer.valid_pool(CoreTestUtil.ctx())):
		_assert(k.begins_with("c_test_"), "only Cores in the pool (%s)" % k)
	# a filtered Core never reaches an offer
	for sd in 40:
		for c in CoreOffer.build_offer(Rng.new(sd), 1, diff, 3):
			_assert(String(c["key"]) != "c_test_req_pair", "offer respects requires")
	# shortage: nearest tier on the same axis, then another axis
	var only_mana := CoreTestUtil.ctx([], ["c_test_dice_amber_a", "c_test_dice_amber_b", "c_test_pos_amber_a", "c_test_pos_amber_b", "c_test_req_pair", "c_test_req_poison", "c_test_excl_rule", "c_test_rule_amber_a", "c_test_quest_amber", "c_test_mana_amber_a"])
	var o := CoreOffer.build_offer(Rng.new(1), 1, only_mana, 3)
	_assert(o.size() >= 2, "shortage still gives cards (%d)" % o.size())
	var seen_ids: Array = only_mana["seen"]
	for c in o:
		_assert(not seen_ids.has(String(c["key"])), "shortage fill respects seen")
	_done("t_core_filter")
