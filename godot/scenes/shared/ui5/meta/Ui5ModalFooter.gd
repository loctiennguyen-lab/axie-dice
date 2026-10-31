class_name Ui5ModalFooter
extends RefCounted
## UI-05 ModalFooter. One row: [secondary] [primary] right-aligned, gap 12. Two rows (long labels: update, Move progress,
## Abandon): the primary full width on top, the secondary full width under it, same words. `secondary` may be null.

static func make(primary: Button, secondary: Button = null, two_rows := false) -> Control:
	var gap := UI3Theme.space("12")
	if two_rows:
		var v := VBoxContainer.new()
		v.name = "Footer"
		v.add_theme_constant_override("separation", gap)
		primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(primary)
		if secondary != null:
			secondary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.add_child(secondary)
		return v
	var h := HBoxContainer.new()
	h.name = "Footer"
	h.alignment = BoxContainer.ALIGNMENT_END
	h.add_theme_constant_override("separation", gap)
	if secondary != null:
		h.add_child(secondary)
	h.add_child(primary)
	return h


## True when the labels of a one-row footer would not fit `avail` px: the caller switches to two rows.
static func needs_two_rows(primary: Button, secondary: Button, avail: float) -> bool:
	var w := 0.0
	for b in [primary, secondary]:
		if b != null:
			w += b.get_minimum_size().x
	return w + UI3Theme.space("12") > avail
