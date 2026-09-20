extends Node
## Gate on the enemy intent badge's three states — Empty States Spec §1 / FIX-PASS-03 CB-14b.
##
## WHY THIS FILE EXISTS. The rule the spec spends most of its words on is a negative one: the
## empty badge must never be readable as "0 damage". That is not enforceable by looking at a
## screenshot six months from now — somebody re-adds a dash, or reuses the value Label to hold
## a placeholder, or "tidies" the two branches back into one, and the badge quietly starts
## lying about the enemy's next turn. Each of the spec's six layers is one assertion here.
##
## Run: godot --headless --path godot res://tests/t_intent_badge.tscn

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_intent_badge: start ===")
	test_a_live_intent_shows_tile_value_divider_and_target()
	test_a_blank_face_shows_no_move_and_no_digit_anywhere()
	test_an_unmapped_face_type_is_hidden_not_no_move()
	test_no_intent_rolled_is_hidden_and_the_badge_stays_on_screen()
	test_the_question_mark_appears_in_exactly_one_state()
	test_a_party_unit_is_the_only_thing_that_hides()

	print("=== t_intent_badge: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_intent_badge: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_intent_badge: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(msg)


func _make() -> UnitHeadHUD:
	# Built the same way CombatView builds it (line ~2094): the class constructs its own tree
	# in _ready(), there is no .tscn.
	var hud := UnitHeadHUD.new()
	hud.uid = 1
	add_child(hud)
	return hud


## Every Label under the badge, with its text — the only honest way to ask "is there a digit
## anywhere in this thing", which is the spec's first and strongest layer.
func _visible_texts(hud: UnitHeadHUD) -> Array[String]:
	var out: Array[String] = []
	var stack: Array = [hud]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Control and not (n as Control).visible:
			continue
		if n is Label:
			out.append((n as Label).text)
		for c in n.get_children():
			stack.append(c)
	return out


func _node_visible(hud: UnitHeadHUD, node_name: String) -> bool:
	var n := hud.find_child(node_name, true, false)
	return n != null and (n as Control).visible


func test_a_live_intent_shows_tile_value_divider_and_target() -> void:
	var hud := _make()
	hud.set_intent(true, "dmg", 7, "Buba")
	var texts := _visible_texts(hud)
	_assert(texts.has("7"), "a live dmg intent does not show its value: %s" % str(texts))
	_assert(texts.has("→ BUBA"),
		"a live intent does not show '→ BUBA' (CB-14: real arrow, name uppercased): %s"
		% str(texts))
	_assert(hud.visible, "a live intent hid the whole badge")
	hud.queue_free()


## THE SIX LAYERS. A blank face is the game's real "this enemy does nothing" — not a hidden
## one — so it must read as NO MOVE and carry no digit, no tile, no divider and no target.
func test_a_blank_face_shows_no_move_and_no_digit_anywhere() -> void:
	var hud := _make()
	hud.set_intent(true, "blank", 0, "Buba")
	var texts := _visible_texts(hud)
	_assert(texts.has("NO MOVE"), "a blank face does not render NO MOVE: %s" % str(texts))
	for t in texts:
		_assert(not _has_digit(t),
			"layer 1 broken — the NO MOVE badge shows the text '%s', which contains a digit. " % t
			+ "The whole point of this state is that there is no number to misread as 0 damage.")
		_assert(t != "?",
			"layer broken — '?' is reserved for the HIDDEN state; a blank face is a KNOWN "
			+ "'does nothing' and must never render as unknown")
	_assert(_node_visible(hud, "IntentWord"), "the word label is not visible")
	_assert(texts.size() == 1,
		"layer 2/3 broken — the NO MOVE badge should be ONE element; it renders %d: %s"
		% [texts.size(), str(texts)])
	_assert(hud.visible, "a blank face hid the badge — the spec says the enemy badge never hides")
	hud.queue_free()


func test_an_unmapped_face_type_is_hidden_not_no_move() -> void:
	var hud := _make()
	hud.set_intent(true, "not_a_real_face_type", 4, "Buba")
	var texts := _visible_texts(hud)
	_assert(texts.has("HIDDEN"),
		"an unmapped face type should read HIDDEN (the build genuinely does not know what is "
		+ "coming), not NO MOVE: %s" % str(texts))
	_assert(texts.has("?"), "the HIDDEN state keeps the tile and its '?': %s" % str(texts))
	_assert(not texts.has("4"),
		"the HIDDEN state leaked the value it is supposed to be withholding: %s" % str(texts))
	hud.queue_free()


func test_no_intent_rolled_is_hidden_and_the_badge_stays_on_screen() -> void:
	var hud := _make()
	hud.set_intent(false, "", 0, "")
	_assert(hud.visible,
		"an enemy with no rolled intent hid its badge. That is the exact regression Empty "
		+ "States Spec §1 exists to stop: the column is a 186x370 stack with gap 8, so the "
		+ "status chips and HP bar jump 44px mid-turn when a 42px badge disappears.")
	_assert(_visible_texts(hud).has("HIDDEN"),
		"an unrolled intent should read HIDDEN, not NO MOVE — 'not decided yet' and 'does "
		+ "nothing' are two different facts and the spec gives them two different shapes")
	hud.queue_free()


func test_the_question_mark_appears_in_exactly_one_state() -> void:
	var live := _make()
	live.set_intent(true, "dmg", 7, "Buba")
	_assert(not _visible_texts(live).has("?"), "a live intent drew a '?'")
	live.queue_free()
	var inert := _make()
	inert.set_intent(true, "blank", 0, "Buba")
	_assert(not _visible_texts(inert).has("?"), "the NO MOVE badge drew a '?'")
	inert.queue_free()


func test_a_party_unit_is_the_only_thing_that_hides() -> void:
	var hud := _make()
	hud.set_intent(true, "dmg", 7, "Buba")
	hud.hide_intent()
	_assert(not hud.visible, "hide_intent() left the badge on screen for a party unit")
	hud.queue_free()


func _has_digit(t: String) -> bool:
	for c in t:
		if c >= "0" and c <= "9":
			return true
	return false
