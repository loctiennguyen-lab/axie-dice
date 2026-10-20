extends Node
## Depth v3 6.4 / 6.7b choose_affixes: groups A/B, forbidden pairs, no-break filter, first run, determinism.

var _guard := SaveGuard.new()
var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	var seen_a := {}
	var seen_b := {}
	for sd in 600:
		var r := CombatTraits.choose_affixes(sd, true, true)
		var a := String(r["affix"])
		var b := String(r["affix2"])
		seen_a[a] = true
		seen_b[b] = true
		_check(String(ContentDB.elite_affixes[a]["group"]) == "A", "seed %d: first is group A (%s)" % [sd, a])
		_check(b != "" and String(ContentDB.elite_affixes[b]["group"]) == "B", "seed %d: second is group B (%s)" % [sd, b])
		_check(not (a == "charge" and (b == "rush" or b == "frenzy")), "seed %d: forbidden pair %s+%s" % [sd, a, b])
		_check(not CombatTraits.affix_forbidden(a, b), "forbidden_pairs data respected")
		var before := CombatTraits.choose_affixes(sd, true, false)
		_check(String(before["affix2"]) == "" and String(before["affix"]) == a, "before boss 1: A only, same A")
		var nb := CombatTraits.choose_affixes(sd, false, true)
		var na := String(nb["affix"])
		_check(bool(ContentDB.elite_affixes[na].get("no_break_ok", false)), "seed %d: no-break team gets %s" % [sd, na])
		_check(na != "iron" and na != "mend" and na != "fang", "no-break never gets a poison/debuff-needing affix")
		_check(CombatTraits.choose_affixes(sd, true, true) == r, "deterministic")
	_check(seen_a.has("charge") and seen_b.has("rush") and seen_b.has("frenzy") and seen_b.has("swarm"), "all of charge / rush / frenzy / swarm do come up")
	_check(not seen_a.has("thorns") and not seen_a.has("echo") and not seen_a.has("chill"), "retired / ungrouped never drawn")
	var fr := CombatTraits.choose_affixes(5, true, true, true)
	_check(fr["affix"] == "iron" and fr["affix2"] == "", "first run: iron")
	_check(CombatTraits.choose_affixes(5, false, true, true)["affix"] == "ward", "first run, cannot break: ward")
	print("=== t_affix_pairs: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	for f in _failures.slice(0, 10):
		print("t_affix_pairs: FAIL - %s" % f)
	if _failures.is_empty():
		print("t_affix_pairs: PASS - %d checks OK" % _checks)
	_guard.restore()
	get_tree().quit(0 if _failures.is_empty() else 1)


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(msg)
