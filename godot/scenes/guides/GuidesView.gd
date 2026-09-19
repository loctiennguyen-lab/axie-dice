extends Control
## SAMPLE TEAMS — the four starter compositions, with why each one works and how to play it.
## Port of `scGuideBody()` (src/client.html:6858) over `ContentDB.GUIDES`.
##
## WHY THIS EXISTS AT ALL. Picking five Axies out of eighteen with no idea what any of them do
## together is the hardest moment in the game, and it happens before the player has learned
## anything. The JS build answers it with four worked examples and a one-click "use this team".
##
## WHY IT IS A SCREEN AND NOT A CODEX TAB. In JS these live behind `scCodex()`'s tab bar purely
## because they shared a header. The Codex (a ten-tab rules book) is unported and, per the
## handover, has to be re-audited sentence by sentence against the Godot rules before any of it
## can be copied — it currently says "12 waves" and describes a JS-shaped undo, both wrong here.
## Waiting for that would hold four self-contained cards hostage to a much bigger job.

const MAIN_MENU_SCENE := "res://scenes/main_menu/MainMenu.tscn"

## Same three-region split as the Vault screen, for the same reason: the BACK button is the only
## way off this screen and must not drift further away the longer the content gets.
@onready var _header: VBoxContainer = %HeaderRoot
@onready var _content: VBoxContainer = %ContentRoot
@onready var _footer: VBoxContainer = %FooterRoot


func _ready() -> void:
	var title := Label.new()
	title.text = "SAMPLE TEAMS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", DangoTheme.TEXT)
	_header.add_child(title)

	var sub := _body_label("Four teams that work, and why. Pick one to fill your roster — you can"
		+ " still change any slot afterwards.")
	sub.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
	_header.add_child(sub)

	for guide in ContentDB.GUIDES:
		_content.add_child(_build_card(guide))

	var back := Button.new()
	back.name = "BackButton"
	back.text = "BACK"
	back.custom_minimum_size = Vector2(0, 44)
	DangoTheme.style_button(back, false)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE))
	_footer.add_child(back)


func _build_card(guide: Dictionary) -> PanelContainer:
	var arch_key := str(guide.get("arch", ""))
	var arch: Dictionary = ContentDB.ARCH.get(arch_key, {})
	# A missing archetype is a data error, not a styling choice — fall back to the neutral text
	# colour rather than to some other archetype's, so it does not masquerade as a real one.
	var accent := Color(str(arch.get("c", ""))) if arch.has("c") else DangoTheme.TEXT

	var card := PanelContainer.new()
	card.name = "Guide_" + str(guide.get("id", ""))
	card.add_theme_stylebox_override("panel", DangoTheme.panel_style(DangoTheme.BG_PANEL, 2, 8))

	# An archetype stripe down the left edge, inside the card's own black border.
	#
	# NOT a coloured border on the card, deliberately. `panel_style()`'s `border` argument now
	# means "this panel is in a STATE that needs attention" — the Vault screen uses it for a
	# record that must be re-scanned. Spending the same visual channel on a static category would
	# put two unrelated meanings in one signal, and the reader would have no way to tell which
	# one a coloured frame was saying. And not a tinted background either: the ground is very
	# dark, and pushing ten different hues behind the body text would take the text contrast out
	# of the range it was checked in, one archetype at a time.
	#
	# The stripe reads from peripheral vision while scrolling, which the archetype label cannot —
	# that label sits mid-card, after the guide's name, so there is no fixed edge for the eye to
	# track. (Decision by art-director, 2026-09-19.)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 0)
	card.add_child(body)

	if not arch.is_empty():
		var stripe := PanelContainer.new()
		stripe.name = "ArchStripe"
		stripe.custom_minimum_size = Vector2(5, 0)
		stripe.size_flags_vertical = Control.SIZE_FILL
		var sb := StyleBoxFlat.new()
		sb.bg_color = accent
		sb.set_border_width_all(0)
		sb.corner_radius_top_left = 8
		sb.corner_radius_bottom_left = 8
		stripe.add_theme_stylebox_override("panel", sb)
		body.add_child(stripe)
	# A guide with no archetype gets NO stripe rather than a grey one: absent data should look
	# absent, not like a category called "grey".

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	body.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	margin.add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	col.add_child(head)

	var name_lbl := Label.new()
	name_lbl.text = str(guide.get("n", ""))
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", accent)
	head.add_child(name_lbl)

	if not arch.is_empty():
		var arch_lbl := Label.new()
		arch_lbl.name = "ArchLabel"
		arch_lbl.text = "%s %s" % [str(arch.get("ic", "")), str(arch.get("n", ""))]
		arch_lbl.add_theme_font_size_override("font_size", 14)
		arch_lbl.add_theme_color_override("font_color", accent)
		head.add_child(arch_lbl)

	var diff := Label.new()
	diff.text = str(guide.get("diff", ""))
	diff.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diff.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	diff.add_theme_font_size_override("font_size", 14)
	diff.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
	head.add_child(diff)

	col.add_child(_build_team_strip(guide.get("team", [])))

	var why := _body_label(str(guide.get("why", "")))
	col.add_child(why)

	for line in guide.get("how", []):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var bullet := Label.new()
		bullet.text = "•"
		bullet.add_theme_color_override("font_color", accent)
		bullet.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(bullet)
		var text := _body_label(str(line))
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_font_size_override("font_size", 14)
		row.add_child(text)
		col.add_child(row)

	var use := Button.new()
	use.name = "UseButton"
	use.text = "USE THIS TEAM"
	use.custom_minimum_size = Vector2(0, 42)
	DangoTheme.style_button(use, true)
	use.pressed.connect(_on_use_pressed.bind(guide))
	col.add_child(use)
	return card


## Portrait + name per slot, in the order the guide lists them. Uses the same class portraits the
## die cards use, so a team here is recognisable as the team the menu will show.
func _build_team_strip(team: Array) -> HBoxContainer:
	var strip := HBoxContainer.new()
	strip.name = "TeamStrip"
	strip.add_theme_constant_override("separation", 8)
	for key in team:
		var hero: Dictionary = ContentDB.heroes.get(str(key), {})
		var slot := VBoxContainer.new()
		slot.add_theme_constant_override("separation", 2)

		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(56, 56)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var portrait_path := "res://assets/portraits/%s.png" % str(hero.get("cls", ""))
		if ResourceLoader.exists(portrait_path):
			portrait.texture = load(portrait_path)
		slot.add_child(portrait)

		var nm := Label.new()
		nm.text = str(hero.get("n", key))
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.add_theme_font_size_override("font_size", 12)
		nm.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
		slot.add_child(nm)
		strip.add_child(slot)
	return strip


## Puts the guide's team where the menu will pick it up, and returns it. SEPARATE from the
## navigation below on purpose: a test cannot exercise a method that changes the scene, because
## changing the scene frees the test's own tree and nothing is left to report a result. (Found
## the hard way — the first version did both, and the gate hung forever instead of failing.)
##
## The hand-off is a static var on `MainMenu` rather than a field on `RunState` or `MetaState`.
## A team the player is CONSIDERING is not run state — no run exists yet — and it is certainly
## not persistent state; putting it in either would mean a half-made choice surviving a crash, or
## a saved run's roster and a menu preselection living in the same place and eventually being
## confused for each other.
static func hand_team_to_menu(guide: Dictionary) -> Array[String]:
	var team: Array[String] = []
	for k in guide.get("team", []):
		team.append(str(k))
	MainMenu.pending_team = team
	return team


func _on_use_pressed(guide: Dictionary) -> void:
	hand_team_to_menu(guide)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _body_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", DangoTheme.TEXT)
	return lbl
