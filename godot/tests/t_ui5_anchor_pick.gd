extends Node
## UI-05 b23 lane R3: the Anchor pick (48-anchor-pick). Data-names, nothing preselected, Take disabled with its reason,
## pick enables Take, the awaken moment keeps its content, 1920 + 1280, align check measured > 0 pairs, real text >= 14 px.
## Run: godot --headless --path godot res://tests/t_ui5_anchor_pick.tscn

const Align := preload("res://tests/ui5_align_check.gd")
const NAMES := ["AnchorPick", "Header", "Title", "ShardPill", "SubLine", "CardRow", "AnchorCard0", "HouseGlyph", "AnchorName",
	"HouseLine", "Summary", "RuleBox", "AwakensBox", "HouseCores", "HouseCoreChip", "Glossary", "Footer", "TakeButton"]
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _min_text(n: Node, sc: float, acc: Array) -> void:
	if n is Label and (n as Label).is_visible_in_tree() and (n as Label).text.strip_edges() != "":
		var l := n as Label
		acc.append([l.get_theme_font_size("font_size") * sc, l.text.left(20)])
	for c in n.get_children():
		_min_text(c, sc, acc)


func _case(ids: Array, reasons: Dictionary, sc: float, tag: String) -> void:
	UI3Theme.set_scale_override(sc)
	AnchorAdapter.test_state = {"open": true, "offer": ids, "reasons": reasons, "picked": []}
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.theme = UI3Theme.get_theme()
	add_child(host)
	var v := AnchorPick.new()
	v.name = "AnchorPick"
	host.add_child(v)
	v.setup(ids, true)
	await get_tree().process_frame
	await get_tree().process_frame
	for nm in NAMES:
		_check(v.find_child(nm, true, false) != null or nm == "AnchorPick", "%s: node %s" % [tag, nm])
	_check(v.selected == -1, "%s: nothing preselected" % tag)
	_check(v.take_button.disabled and v.take_button.text == "Pick an Anchor", "%s: Take disabled, says why" % tag)
	_check(v.find_child("Keycap", true, false) == null, "%s: no keycap on the disabled button" % tag)
	for c in v.cards:
		_check(absf(c.size.x - UI3Theme.size_of("anchor_card_w")) < 1.0, "%s: card width %f" % [tag, c.size.x])
		_check(c.size.y >= UI3Theme.size_of("anchor_card_h") - 1.0, "%s: card height %f" % [tag, c.size.y])
		var col := c.get_child(0) as Control
		_check(col.get_minimum_size().y <= c.size.y + 1.0, "%s: card content fits (%f > %f)" % [tag, col.get_minimum_size().y, c.size.y])
	var sel := 0
	while sel < ids.size() and AnchorAdapter.disabled_reason(String(ids[sel])) != "":
		sel += 1
	v.select(sel)
	await get_tree().process_frame
	_check(v.selected == sel and not v.take_button.disabled and v.take_button.text.begins_with("Take "), "%s: pick enables Take" % tag)
	_check((v.cards[sel] as Object).get("selected") == true, "%s: card marked selected" % tag)
	_check(Align.pairs(v) > 0, "%s: align check measured pairs" % tag)
	var probs := Align.check(v, 1.5, tag + " ")
	_check(probs.is_empty(), "%s: align %s" % [tag, str(probs)])
	var acc: Array = []
	_min_text(v, sc, acc)
	for t in acc:
		_check(float(t[0]) >= 13.9, "%s: text '%s' is %.1f px" % [tag, t[1], t[0]])
	_check(acc.size() > 10, "%s: texts measured" % tag)
	host.queue_free()
	await get_tree().process_frame


func _ready() -> void:
	print("=== t_ui5_anchor_pick: start ===")
	_guard.capture()
	UI3Gacha.instant_override = 1
	for sc in [1.0, 2.0 / 3.0]:
		var tg := "1920" if sc == 1.0 else "1280"
		await _case(["a_volley", "a_gambler", "a_mana_mine"], {"a_mana_mine": "stage_locked"}, sc, tg + " gambler")
		await _case(["a_kin", "a_embers", "a_big_hand"], {}, sc, tg + " kin")
	# awaken moment still carries its content
	var host := Control.new()
	add_child(host)
	var fx := AnchorFx.play(host, "a_gambler")
	_check(fx.find_child("AwakenName", true, false) != null, "awaken moment name")
	AnchorAdapter.test_state = null
	UI3Theme.set_scale_override(-1.0)
	UI3Gacha.instant_override = -1
	_guard.restore()
	_check(_checks > 100, "the cases really ran (%d checks)" % _checks)
	print("=== t_ui5_anchor_pick: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	for f in _fails:
		print("FAIL: ", f)
	if _fails.is_empty():
		print("t_ui5_anchor_pick: PASS")
	get_tree().quit(1 if not _fails.is_empty() else 0)
