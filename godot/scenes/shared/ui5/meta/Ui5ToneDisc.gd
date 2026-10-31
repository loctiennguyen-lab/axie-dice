class_name Ui5ToneDisc
extends RefCounted
## UI-05 ToneDisc: round glyph disc (toast_dot px) before a toast, warning or notice. Never colour alone: ok = tick icon,
## error = "!", warn = "!", info = "i". Tones: &"ok" (toast_ok), &"error" (toast_error), &"warn" (accent), &"info" (text).

const TONES := {&"ok": ["toast_ok", ""], &"error": ["toast_error", "!"], &"warn": ["accent", "!"], &"info": ["text", "i"]}


static func diameter() -> int:
	return UI3Theme.size_of("toast_dot")


static func make(tone := &"error", node_name := "ToneDisc") -> PanelContainer:
	var t: Array = TONES.get(tone, TONES[&"error"])
	var d := diameter()
	var p := PanelContainer.new()
	p.name = node_name
	p.theme = UI3Theme.get_theme()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.custom_minimum_size = Vector2(d, d)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.set_meta("tone", tone)
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color(t[0]), UI3Theme.radius("pill")))
	if String(t[1]) == "":
		var ic := TextureRect.new()
		ic.name = "Glyph"
		ic.texture = UI3.icon("ui_check")
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2.ONE * int(d * 0.6)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ic.modulate = UI3Theme.color("text_ink")
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(ic)
	else:
		var l := Ui5Text.label(String(t[1]), "text_body", "text_ink", true)
		l.name = "Glyph"
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.clip_text = false
		p.add_child(l)
	return p
