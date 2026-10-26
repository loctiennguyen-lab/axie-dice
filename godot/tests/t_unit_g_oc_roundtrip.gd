extends Node
## Regression (soak seed 5004): Unit.to_data/from_data must keep g_oc_bonus (ascend/forge G bonus). CombatEngine.undo_last and
## save/load rebuild units from this dict; losing it made live damage lower than the replay of the same action log.

func _ready() -> void:
	var u := Unit.new()
	u.uid = 3
	u.g_oc_bonus = 0.3
	var back := Unit.from_data(JSON.parse_string(JSON.stringify(u.to_data())) as Dictionary)
	var ok := is_equal_approx(back.g_oc_bonus, 0.3)
	# an old save without the key still loads as 0
	var d := u.to_data()
	d.erase("g_oc_bonus")
	ok = ok and Unit.from_data(d).g_oc_bonus == 0.0
	print("PASS t_unit_g_oc_roundtrip" if ok else "FAIL t_unit_g_oc_roundtrip: g_oc_bonus=%s" % str(back.g_oc_bonus))
	get_tree().quit(0 if ok else 1)
