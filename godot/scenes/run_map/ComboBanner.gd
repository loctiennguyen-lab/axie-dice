class_name ComboBanner
extends RefCounted
## The set-formed banner (GachaFx) shown after a pick. Split out of RunMapController (UI-05 b23 lane 0b): code moved as-is, state stays on the controller (`c`).
## The controller keeps a same-name forwarder for every method here.


var c: RunMapController


func _init(ctrl: RunMapController) -> void:
	c = ctrl

## Shows the strongest newly formed combo (Full beats Pair) as a big centre panel above the overlay layer.
func _combo_banner(formed: Array) -> GachaFx:
	if formed.is_empty() or c._overlay_layer == null:
		return null
	var best: Dictionary = formed[0]
	for f in formed:
		if String(f["tier"]) == "full":
			best = f
			break
	c.gacha_log.append("banner:%s" % String(best["tier"]))
	var house := AnchorAdapter.house_of_combo(String(best["id"]))
	var mut := {"house": house} if house != "" and not AnchorAdapter.mutation_of(house)["name"].is_empty() else {}
	return GachaFx.banner(c._overlay_layer, String(best["tier"]), UI3Gacha.combo_name(String(best["id"])),
		UI3Gacha.combo_members(String(best["id"]), String(best["tier"])), mut) as GachaFx
