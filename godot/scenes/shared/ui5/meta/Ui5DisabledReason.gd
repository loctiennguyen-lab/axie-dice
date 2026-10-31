class_name Ui5DisabledReason
extends RefCounted
## UI-05 disabled-with-reason: a disabled primary says why in its own label and carries no keycap (Liam 30/10). apply()
## disables a Button through UI3.set_disabled_reason, drops any KeyCap child and mirrors the reason in the tooltip.
## lock_line() is the small "lock" row under a card / in a tooltip (LockReason): lock icon + muted text, centred on the icon.

static func apply(b: Button, reason: String) -> void:
	UI3.set_disabled_reason(b, reason)
	b.tooltip_text = reason
	for c in b.get_children():
		if c.has_meta("ui5_keycap"):
			b.remove_child(c)
			c.queue_free()


static func clear(b: Button) -> void:
	UI3.clear_disabled_reason(b)
	b.tooltip_text = ""


static func lock_line(text: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.name = "LockReason"
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", UI3Theme.space("8"))
	var ic := TextureRect.new()
	ic.name = "Icon"
	ic.texture = UI3.icon("ui_lock")
	ic.custom_minimum_size = Vector2.ONE * UI3Theme.size_of("text_body")
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(ic)
	h.add_child(Ui5Text.label(text, "text_body", "text_muted"))
	return h
