extends Control
## The real in-combat information panel (godot-port-gap-inventory.md §2.1 "scInfo" row) —
## six tabs: YOUR TEAM, YOUR RELICS, ENEMIES (all live, built here from the running
## CombatEngine) plus STATUS EFFECTS / KEYWORDS / MANA, shared verbatim with the Codex via
## CodexContent.gd so the two screens can never disagree on a rule.
##
## Instantiated by CombatView.gd (see the one-line hook noted in the ui-programmer report),
## NOT part of Combat.tscn's static node tree — this file/scene is new and CombatView.gd is
## not restructured to own it.

signal closed

@onready var _tab_row: HBoxContainer = %TabRow
@onready var _scroll: ScrollContainer = %Scroll
@onready var _body: RichTextLabel = %Body
@onready var _close: Button = %CloseButton
@onready var _dim: ColorRect = %Dim

var _combat: CombatEngine = null
var _owned_relic_ids: Array = []
var _current_tab: String = "party"
var _tab_buttons: Dictionary = {}


func _ready() -> void:
	for pair in CodexContent.INFO_TABS:
		var key: String = pair[0]
		var label: String = pair[1]
		var b := Button.new()
		b.text = label
		b.toggle_mode = true
		b.pressed.connect(func(): _select_tab(key))
		_tab_row.add_child(b)
		_tab_buttons[key] = b
	_close.pressed.connect(_on_close)
	_dim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			_on_close())
	_select_tab(_current_tab)


## Called by CombatView.gd right after instancing this scene.
func setup(combat: CombatEngine, owned_relic_ids: Array) -> void:
	_combat = combat
	_owned_relic_ids = owned_relic_ids
	if is_inside_tree():
		_select_tab(_current_tab)


func _on_close() -> void:
	closed.emit()


func _select_tab(key: String) -> void:
	_current_tab = key
	for k in _tab_buttons.keys():
		(_tab_buttons[k] as Button).button_pressed = (k == key)
	match key:
		"party": _body.text = _party_text()
		"relic": _body.text = _relic_text()
		"enemy": _body.text = _enemy_text()
		_: _body.text = CodexContent.tab_text(key)
	_scroll.scroll_vertical = 0


func _party_text() -> String:
	if _combat == null:
		return "(no active combat)"
	var s := "[b][color=#ffd76a]YOUR TEAM[/color][/b]\nEvery face on every Axie, at its live value.\n\n"
	for u in _combat.party:
		if bool(u.is_token):
			continue
		s += "[b]%s[/b] - T%d - HP %d/%d" % [String(u.n), int(u.tier), int(u.hp), int(u.max_hp)]
		if int(u.shield) > 0:
			s += "  -  Shield %d" % int(u.shield)
		s += "\n"
		var passive: Dictionary = ContentDB.CLASS_PASSIVE.get(String(u.cls), {})
		if not passive.is_empty():
			s += "[i]%s: %s[/i]\n" % [String(passive.get("n", "")), String(passive.get("d", ""))]
		s += _die_rows(u)
		s += "\n"
	return s


func _enemy_text() -> String:
	if _combat == null:
		return "(no active combat)"
	var s := "[b][color=#ffd76a]ENEMIES[/color][/b]\nEvery face on every enemy, so you know what it can roll.\n\n"
	for u in _combat.enemies:
		var tag := ""
		if bool(u.is_boss):
			tag = "  [BOSS]"
		elif String(u.role) != "" and String(u.role) != "boss":
			tag = "  (%s)" % String(u.role)
		var dead := "  [DEAD]" if int(u.hp) <= 0 else ""
		s += "[b]%s[/b]%s%s - HP %d/%d" % [String(u.n), tag, dead, max(0, int(u.hp)), int(u.max_hp)]
		if int(u.shield) > 0:
			s += "  -  Shield %d" % int(u.shield)
		s += "\n"
		s += _die_rows(u)
		s += "\n"
	return s


func _die_rows(u: Unit) -> String:
	var s := ""
	var cur := u.roll_face_index() if u.has_rolled() else -1
	for i in u.die.size():
		var f: Dictionary = u.die[i]
		var mark := " <-- rolled" if i == cur else ""
		var kws: Array = f.get("keywords", [])
		var kw_text := (" [" + ", ".join(kws) + "]") if not kws.is_empty() else ""
		# LIVE value, not the printed one. Same fix as the die card and the intent badge
		# (CombatView._live_face_value()): growth/vital/blind/weaken/overdrive all land on
		# top of `value`, and a reference panel that disagrees with the card next to it is
		# worse than no panel.
		var live := _combat._face_value(u, i) if _combat != null else int(f.get("value", 0))
		s += "  %d. %s %s %d%s%s\n" % [i + 1, String(f.get("part", "")).to_upper(),
			String(f.get("type", "")), live, kw_text, mark]
	return s


func _relic_text() -> String:
	var list: Array = []
	for id in _owned_relic_ids:
		var def = RelicRegistry.get_def(id)
		if def != null:
			list.append(def)
	var s := "[b][color=#ffd76a]YOUR RELICS[/color][/b]\nYou are carrying %d relic(s). Relics apply to your whole party.\n\n" % list.size()
	if list.is_empty():
		s += "No relics yet. You get them from rewards, the Merchant and Treasure nodes.\n"
		return s
	var act: Array = []
	var pas: Array = []
	for d in list:
		if int(d.act_cost) > 0:
			act.append(d)
		else:
			pas.append(d)
	if not act.is_empty():
		s += "[b]LUNACIA CARDS (cost Mana)[/b]\n"
		for d in act:
			var used := _combat != null and _combat.used_actives.has(String(d.id))
			var can_afford := _combat != null and int(_combat.mana) >= int(d.act_cost)
			var note := "  (already used this turn)" if used else ("" if can_afford else "  (not enough Mana)")
			s += "- %s [%d MP]: %s%s\n" % [String(d.name), int(d.act_cost), String(d.description), note]
		s += "\n"
	if not pas.is_empty():
		s += "[b]PASSIVE[/b]\n"
		for d in pas:
			s += "- %s: %s\n" % [String(d.name), String(d.description)]
	return s
