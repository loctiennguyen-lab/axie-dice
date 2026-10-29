class_name Ui5Keycap
extends RefCounted
## UI-05 b1 lane A: KeyCap (CSS .keycap). Liam 28/10: the combat HUD shows ONE key on screen, Space (End turn and
## "Click or Space to skip"). Every other shortcut still works and is named in its tooltip only.
## keycap_h high, min width keycap_h, 0 8 padding, radius s, Rowdies text_key.
## Variants: &"plain" (keycap_bg, cream, keycap shadow) · &"primary" (on the amber button: accent_text fill, accent
## text, no shadow) · &"disabled" (on a disabled button: intent_idle_bg fill, disabled_text).
## Every cap carries meta "ui5_keycap" so tests can find all of them.


static func make(text: String, variant := &"plain") -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "KeyCap"
	p.theme = UI3Theme.get_theme()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.set_meta("ui5_keycap", true)
	var l := UI3.label(text, "LabelDisplay")
	l.name = "Key"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	set_variant(p, variant)
	return p


static func set_variant(cap: PanelContainer, variant: StringName) -> void:
	var fill := "keycap_bg"
	var ink := "text"
	var shadow := Ui5HudStyle.shadow_of("keycap")
	match variant:
		&"primary":
			fill = "accent_text"
			ink = "accent"
			shadow = {}
		&"disabled":
			fill = "intent_idle_bg"
			ink = "disabled_text"
			shadow = {}
	cap.set_meta("variant", variant)
	cap.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color(fill), UI3Theme.radius("s"), 0,
		Color.TRANSPARENT, Vector4(UI3Theme.space("8"), 0, UI3Theme.space("8"), 0), shadow))
	var l := cap.get_node_or_null("Key") as Label
	if l != null:
		l.add_theme_color_override("font_color", UI3Theme.color(ink))
	refresh(cap)


## Re-reads the size tokens (the 1280 text floor makes text_key 21 logical px at scale 0.667).
static func refresh(cap: PanelContainer) -> void:
	var h := UI3Theme.size_of("keycap_h")
	cap.custom_minimum_size = Vector2(h, h)
	var l := cap.get_node_or_null("Key") as Label
	if l != null:
		l.add_theme_font_size_override("font_size", UI3Theme.size_of("text_key"))


static func text_of(cap: PanelContainer) -> String:
	var l := cap.get_node_or_null("Key") as Label
	return l.text if l != null else ""


## Every KeyCap under `root` (ui5 caps by meta, older UI3 caps by name / theme variation).
static func all_under(root: Node) -> Array[Control]:
	var out: Array[Control] = []
	for n in root.find_children("*", "Control", true, false):
		var c := n as Control
		if c.has_meta("ui5_keycap") or String(c.name).contains("KeyCap") \
				or (c is PanelContainer and String((c as PanelContainer).theme_type_variation).begins_with("PanelKeycap")):
			out.append(c)
	return out
