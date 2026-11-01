extends RefCounted
## UI-05 shared: Space keycap on a primary button (Land RunPlate/overlays, Shop Leave). Moved out of LandPlates so
## nothing outside the Land lane has to preload a Land file. Use: `const SpaceCap := preload("res://scenes/shared/ui5/SpaceCap.gd")`
## then `SpaceCap.attach(button, UI3Theme.space("32"))`.

## Space keycap on a primary button (primary variant), shown only while the button is enabled (a disabled primary has
## no keycap, Liam 30/10). Positioned after the centred label via Ui5HudStyle.place_trailing; re-synced on redraw/resize.
static func attach(b: Button, pad: int) -> PanelContainer:
	var cap := Ui5Keycap.make("Space", &"primary")
	b.add_child(cap)
	# Ui5HudStyle.place_trailing (shared, as RunPauseMenu): clones the styles, widens the right margin and centres the
	# [label + cap] group. It needs the button in the tree, so it runs deferred and again on resize / text / scale change.
	var sync := func() -> void:
		if not is_instance_valid(b) or not is_instance_valid(cap) or not b.is_inside_tree():
			return
		var sig := "%s|%s|%s|%d|%d|%s" % [b.text, b.disabled, b.size, UI3Theme.size_of("keycap_h"), b.get_theme_font_size("font_size"), cap.get_combined_minimum_size()]
		if String(b.get_meta("cap_sig", "")) == sig:
			return
		b.set_meta("cap_sig", sig)
		if not b.has_meta("styles_pinned"):
			# b.get_theme_stylebox() can still answer with the grey engine default here, and place_trailing clones
			# whatever it gets: pin the variation's real styles as overrides first so the clones keep fill and radius.
			b.set_meta("styles_pinned", true)
			for st in ["normal", "hover", "pressed", "disabled", "hover_pressed", "focus"]:
				var src: StyleBox = UI3Theme.get_theme().get_stylebox(st, b.theme_type_variation)
				if src != null:
					b.add_theme_stylebox_override(st, src.duplicate())
		cap.visible = not b.disabled
		Ui5HudStyle.place_trailing(b, cap, pad)
	b.resized.connect(sync)
	b.draw.connect(sync)
	sync.call_deferred()
	return cap
