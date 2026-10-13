class_name Cosmetics
extends RefCounted
## B12: cosmetic ownership -> art mapping and equip rules. COSMETIC ONLY: no combat rule reads any of
## this (see tests/t_cosmetics_equip.gd, a t_mon13-style scan of scripts/core).
## Owned ids can be real art ids (die_*, frame_*) or Echo Box placeholder pool ids (std_c_001...).
## Placeholders map to art through `boxes.normal.art_map` in echobox.json (reuse across duplicates).

const _Econ := preload("res://scripts/meta/economy_db.gd")
const SLOT_DIE := "die"
const SLOT_FRAME := "frame"


## Art id for any owned/pool id, "" when it has none (fx_*, titles).
static func art_id(id: String) -> String:
	if CosmeticArt.has_art(id):
		return id
	if not id.begins_with("std_"):
		return ""
	var parts := id.split("_")
	if parts.size() != 3 or not parts[2].is_valid_int():
		return ""
	var box: Dictionary = ((_Econ.get_table("echobox").get("boxes", {}) as Dictionary).get("normal", {}) as Dictionary)
	var pool: Dictionary = box.get("pool", {})
	var amap: Dictionary = box.get("art_map", {})
	for r in pool:
		if String((pool[r] as Dictionary).get("id_prefix", "")) == "%s_%s" % [parts[0], parts[1]]:
			var lst: Array = amap.get(r, [])
			if lst.is_empty():
				return ""
			return String(lst[(int(parts[2]) - 1) % lst.size()])
	return ""


## "die", "frame" or "" for any id.
static func slot_of(id: String) -> String:
	var a := art_id(id)
	if a.begins_with("die_"):
		return SLOT_DIE
	if a.begins_with("frame_"):
		return SLOT_FRAME
	return ""


## Distinct art ids the player owns, of one slot, in manifest order.
static func owned_art(owned: Array, slot: String) -> Array[String]:
	var have := {}
	for o in owned:
		var a := art_id(String(o))
		if a != "" and slot_of(a) == slot:
			have[a] = true
	var out: Array[String] = []
	var m: Dictionary = CosmeticArt.manifest().get("dice" if slot == SLOT_DIE else "frames", {})
	for k in m:
		if have.has(k):
			out.append(String(k))
	return out


## Equip rule: id must resolve to art and be owned. "" = ok, else the reason.
static func can_equip(owned: Array, art: String) -> String:
	var slot := slot_of(art)
	if slot == "" or art_id(art) != art:
		return "Not equippable."
	if not owned_art(owned, slot).has(art):
		return "You don't own this."
	return ""
