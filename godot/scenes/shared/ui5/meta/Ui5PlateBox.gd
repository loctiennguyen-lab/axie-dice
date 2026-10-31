class_name Ui5PlateBox
extends RefCounted
## UI-05 meta kit: the .plate box (walnut, 2 px rim, hard lip) with a uniform padding. Thin wrapper over PanelParts.plate_box.
const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")

static func plate(pad: int, rad := "l") -> StyleBoxFlat:
	return PanelParts.plate_box(rad, pad)
