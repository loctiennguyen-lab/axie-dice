extends Node
## Polish 3/11 #2b: a Core offer (build_offer, reroll_card) never contains an owned Core, a seen Core, or the
## same Core twice, for many seeds and tiers (guards the c_cascade "already_owned" report).

const OWNED := ["c_cascade", "c_bastion", "c_mana_pool", "c_tidecaller"]

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	RelicRegistry.legacy_unhide_for_tests()
	for mode in ["short", "full"]:
		for tier in 3:
			for sd in range(1, 80):
				var ctx := {"owned_ids": OWNED.duplicate(), "roster": [], "seen": ["c_loop"], "mode": mode,
					"first_run": false, "pick_index": 3, "front_size": 2, "ascension": 0, "tier_chain": [0, 1, 2],
					"depth_stage": 1, "anchor_id": "", "bonus": sd % 2 == 0, "anchor_house": []}
				var offer := CoreOffer.build_offer(Rng.new(sd * 7919 + tier), tier, ctx, 3)
				_check(offer, ctx, "%s t%d s%d" % [mode, tier, sd])
				if not offer.is_empty():
					var nc := CoreOffer.reroll_card(Rng.new(sd), offer, 0, ctx)
					if not nc.is_empty():
						var o2 := offer.duplicate()
						o2[0] = nc
						_check(o2, ctx, "reroll %s t%d s%d" % [mode, tier, sd])
	print("t_core_offer_no_owned: %d checks, %d failure(s)" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_core_offer_no_owned: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_core_offer_no_owned: FAIL — %s" % f)
	get_tree().quit(1)


func _check(offer: Array, ctx: Dictionary, tag: String) -> void:
	var seen_keys: Array = []
	for c in offer:
		var k := String((c as Dictionary)["key"])
		_checks += 1
		if (ctx["owned_ids"] as Array).has(k) or (ctx["seen"] as Array).has(k) or seen_keys.has(k):
			_failures.append("%s: owned/seen/duplicate card %s" % [tag, k])
		seen_keys.append(k)
