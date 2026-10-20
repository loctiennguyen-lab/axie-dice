extends Node
## v4 UI item 2: Result shows Pacts as "Pact · passive" (never "never fired", never "Most impact"),
## and the "Best set" line shows/hides by whether the run stats carry `best_bo`.
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

func _texts(n: Node, out: Array) -> void:
	if n is Label:
		out.append((n as Label).text)
	for c in n.get_children():
		_texts(c, out)

func _ready() -> void:
	_guard.capture()
	var pact := "r_devilsreroll"
	var core := "a_aegisfont"
	_check(RelicSlots.is_pact(pact) and not RelicSlots.is_pact(core), "fixture: pact vs core")
	RunState.start_new_run(777002, ["plant1", "beast1", "aqua1", "reptile1", "bird1"] as Array[String], "short", 0, false)
	RunState.owned_relic_ids = [pact, core] as Array[String]
	RunState.core_impact = {pact: {"n": 9, "by": {"dmg": 999}}, core: {"n": 1, "by": {"dmg": 5}}}
	RunState.set_phase(RunState.RunPhase.WON)
	var view: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(view)
	await get_tree().process_frame
	await get_tree().process_frame
	var prow := view.find_child("CoreRow_%s" % pact, true, false)
	var crow := view.find_child("CoreRow_%s" % core, true, false)
	_check(prow != null and crow != null, "both core rows exist")
	if prow != null and crow != null:
		var pt: Array = []
		_texts(prow, pt)
		var ct: Array = []
		_texts(crow, ct)
		var ptxt := " ".join(pt)
		_check(ptxt.contains("Pact · passive"), "pact label: %s" % ptxt)
		_check(not ptxt.contains("never fired") and not ptxt.contains("Most impact"), "pact has no never-fired / Most impact")
		_check(" ".join(ct).contains("Most impact"), "the real core is the top: %s" % " ".join(ct))
	# Best set line
	_check(view.call("_best_set_line", {}) == null, "no best_bo field: line hidden")
	var l: Label = view.call("_best_set_line", {"best_bo": {"part": 1, "size": 5, "m100": 260}})
	_check(l != null and l.text.contains("HORN") and l.text.contains("×2.6") and l.text.contains("5"), "best set text: %s" % (l.text if l else "null"))
	var e: Label = view.call("_best_set_line", {"best_bo": {}})
	_check(e != null and e.text.begins_with("No Set"), "empty best_bo: encouragement")
	view.queue_free()
	print("=== t_v4ui_result: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	_guard.restore()
	if _fails.is_empty():
		print("t_v4ui_result: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_v4ui_result: FAIL - %s" % f)
	get_tree().quit(1)
