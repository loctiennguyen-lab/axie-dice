extends Node
## BUG-0005: no combat HUD tooltip may show while the tutorial welcome curtain (or the skip confirm) is up.
## Before the fix the enemy intent plate used a NATIVE tooltip, an OS-level popup no overlay can cover.

var _fails := 0
var _checks := 0


func _ok(c: bool, what: String) -> void:
	_checks += 1
	if not c:
		_fails += 1
		print("  FAIL: ", what)


func _ready() -> void:
	await get_tree().process_frame
	var pp: UnitPortrait = load("res://scenes/shared/UnitPortrait.tscn").instantiate()
	pp.setup(9001, "BLANKY", "reptile", true, false)
	add_child(pp)
	await get_tree().process_frame
	pp.set_intent({"show": true, "type": "blank", "num": 0, "label": "BLANK", "target": ""})
	var ip: Control = pp._intent_panel
	_ok(ip.tooltip_text == "", "intent plate has no native tooltip (it would draw over any overlay)")
	_ok(UI3Tooltip.text_of(ip).begins_with("Next: BLANK 0"), "intent text lives in the UI3 tooltip")

	var coach := TutorialCoach.new()
	add_child(coach)
	await get_tree().process_frame
	# Tooltip already up when the welcome curtain opens: it must go away.
	UI3Tooltip.show_now(ip)
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(UI3Tooltip.shown_plate(get_tree()) != null, "setup: intent tooltip shows with no modal")
	coach.show_curtain("Welcome to Axie Dice!", "Body.", "Start")
	await get_tree().process_frame
	_ok(UI3Tooltip.shown_plate(get_tree()) == null, "opening the welcome curtain hides a tooltip that was up")
	# And the HUD cannot raise a new one underneath it (hover or focus).
	UI3Tooltip.show_now(ip)
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(UI3Tooltip.shown_plate(get_tree()) == null, "no HUD tooltip while the curtain is up")
	# Skip confirm counts too.
	coach.clear()
	coach.call("_ask_skip")
	await get_tree().process_frame
	UI3Tooltip.show_now(ip)
	await get_tree().process_frame
	_ok(UI3Tooltip.shown_plate(get_tree()) == null, "no HUD tooltip while the skip confirm is up")
	coach.find_child("SkipConfirm", true, false).queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	# Modal gone: tooltips work again.
	UI3Tooltip.show_now(ip)
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(UI3Tooltip.shown_plate(get_tree()) != null, "tooltip works again once the modal is gone")
	print("t_tooltip_modal: %s - %d checks" % ["PASS" if _fails == 0 else "FAIL", _checks])
	get_tree().quit(0 if _fails == 0 else 1)
