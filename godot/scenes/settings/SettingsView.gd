extends Control
## Settings. Four controls, every one of them connected to something real.
##
## The volume backend has existed since the audio pass (MetaState.audio_music_volume /
## audio_sfx_volume / audio_muted, already persisted and already read by CombatAudioDirector) —
## there was simply no screen to move them from. Reduce-flashing is new here, and is wired to
## the two effects that actually flash (CombatView.flashes_suppressed()).
##
## ABANDON RUN is the one destructive control in the game, so it asks twice and says exactly
## what it will destroy. It is also hidden — not greyed — when there is no saved run, because
## "abandon" with nothing to abandon is a question the player should never be asked.

const _ROW_SEP := 10

var _content: VBoxContainer
var _abandon_status: Label = null


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", _ROW_SEP)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content)

	_title("SETTINGS")
	_section("AUDIO")
	_slider("Music", MetaState.audio_music_volume, func(v: float) -> void:
		MetaState.audio_music_volume = v
		MetaState.save_to_disk()
		_apply_audio())
	_slider("Sound effects", MetaState.audio_sfx_volume, func(v: float) -> void:
		MetaState.audio_sfx_volume = v
		MetaState.save_to_disk()
		_apply_audio())
	_checkbox("Mute everything", MetaState.audio_muted, func(on: bool) -> void:
		MetaState.audio_muted = on
		MetaState.save_to_disk()
		_apply_audio())

	_section("ACCESSIBILITY")
	_checkbox("Reduce flashing and screen shake", MetaState.reduce_flash,
		func(on: bool) -> void:
			MetaState.reduce_flash = on
			MetaState.save_to_disk())
	_body("Turns off the screen shake on a hit and the colour flash on a resonant Axie. "
		+ "Dice, actions and damage numbers are untouched — those tell you what happened.")

	_section("RUN")
	_build_abandon_section()

	var back := Button.new()
	back.text = "BACK"
	back.custom_minimum_size = Vector2(0, 44)
	DangoTheme.style_button(back, false)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn"))
	_content.add_child(back)


## Pushes the stored levels at the running audio buses immediately, so a slider is audible
## while the player is still holding it rather than after the next scene change.
##
## `CombatAudioDirector.apply_settings()` is static precisely so a settings screen can drive
## the buses with no combat running — its own comment says so. Nothing new was added here.
func _apply_audio() -> void:
	CombatAudioDirector.apply_settings()


func _build_abandon_section() -> void:
	if not RunState.has_saved_run():
		_body("No run in progress.")
		return

	_body("A run is saved. Abandoning it deletes that save — the Axies, relics and Gene Shard "
		+ "in it are gone, and Gene Shard already banked from finished runs is not affected.")
	var confirm := CheckBox.new()
	confirm.name = "ConfirmAbandonCheck"
	confirm.text = "Yes, I want to abandon the saved run"
	_content.add_child(confirm)

	var btn := Button.new()
	btn.text = "ABANDON RUN"
	btn.custom_minimum_size = Vector2(0, 44)
	btn.disabled = true
	DangoTheme.style_button(btn, false)
	confirm.toggled.connect(func(on: bool) -> void:
		btn.disabled = not on)
	btn.pressed.connect(func() -> void:
		RunState.clear_saved_run()
		RunState.reset()
		btn.disabled = true
		confirm.disabled = true
		confirm.button_pressed = false
		if _abandon_status != null:
			_abandon_status.text = "The saved run has been deleted."
			_abandon_status.visible = true)
	_content.add_child(btn)

	_abandon_status = _body("")
	_abandon_status.visible = false


# --- small builders ---------------------------------------------------------

func _title(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", DangoTheme.PRIMARY)
	_content.add_child(lbl)


func _section(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", DangoTheme.PRIMARY)
	_content.add_child(lbl)


func _body(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
	_content.add_child(lbl)
	return lbl


## A slider with its value ON SCREEN. A bare slider tells the player where the handle is, not
## what it is set to, and "somewhere near the right" is not a volume anyone can come back to.
func _slider(label: String, value: float, on_change: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_content.add_child(row)

	var name_lbl := Label.new()
	name_lbl.text = label
	name_lbl.custom_minimum_size = Vector2(160, 0)
	row.add_child(name_lbl)

	var slider := HSlider.new()
	slider.name = "%sSlider" % label.replace(" ", "")
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(260, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)

	var value_lbl := Label.new()
	value_lbl.text = "%d%%" % roundi(value * 100.0)
	value_lbl.custom_minimum_size = Vector2(56, 0)
	row.add_child(value_lbl)

	slider.value_changed.connect(func(v: float) -> void:
		value_lbl.text = "%d%%" % roundi(v * 100.0)
		on_change.call(v))


func _checkbox(label: String, pressed: bool, on_toggle: Callable) -> void:
	var box := CheckBox.new()
	box.name = "%sCheck" % label.split(" ")[0]
	box.text = label
	box.button_pressed = pressed
	box.toggled.connect(func(on: bool) -> void: on_toggle.call(on))
	_content.add_child(box)
