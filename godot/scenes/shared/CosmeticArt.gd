class_name CosmeticArt
extends RefCounted
## Loader for cosmetic art (Cosmetics v7): dice skins and avatar frames.
## Source of truth is assets/cosmetics/cosmetics_manifest.json (one `dice` object, one `frames`
## object, ids kept from earlier versions).
##
## Dice layers: "plate" (Common/Uncommon/Rare) or "base" + "glow" (Epic+) + "max" (Mythic).
## `glow` is drawn with additive blend, `max` is drawn normally on top (Mythic max-level overlay).
## Frames: `base`, plus a static `_anim.png` overlay for Epic+ frames. Animated layers are
## PENDING (manifest `animated_layers.status`): the overlay is shown still, not animated.
## Ids that have no art (fx_*, std_* placeholder pool ids, titles) return empty results.

const ROOT := "res://assets/cosmetics/"
const MANIFEST := ROOT + "cosmetics_manifest.json"

static var _cache: Dictionary = {}


static func manifest() -> Dictionary:
	if _cache.is_empty():
		var f := FileAccess.open(MANIFEST, FileAccess.READ)
		if f != null:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_cache = d
	return _cache


## True while Epic+ frame overlays are static placeholders.
static func animation_pending() -> bool:
	return String((manifest().get("animated_layers", {}) as Dictionary).get("status", "")) == "pending"


static func has_art(id: String) -> bool:
	return (manifest().get("dice", {}) as Dictionary).has(id) or (manifest().get("frames", {}) as Dictionary).has(id)


## Layer list for a die skin or frame: [{"layer": "base", "path": "res://...", "add": false}, ...]
## in draw order. Empty when the id has no art.
static func layers(id: String) -> Array:
	var m := manifest()
	var entry: Variant = (m.get("dice", {}) as Dictionary).get(id, (m.get("frames", {}) as Dictionary).get(id, null))
	var out: Array = []
	if not (entry is Dictionary):
		return out
	for rel in (entry as Dictionary).get("files", []):
		var p := ROOT + String(rel)
		var stem := p.get_file().get_basename()
		var layer := stem.get_slice("_", stem.get_slice_count("_") - 1)
		out.append({"layer": layer, "path": p, "add": layer == "glow"})
	return out


## Control that stacks the layers of `id` at `px` x `px`. Returns null when there is no art.
static func make_node(id: String, px: float) -> Control:
	var ls := layers(id)
	if ls.is_empty():
		return null
	var root := Control.new()
	root.name = "Cosmetic_" + id
	root.custom_minimum_size = Vector2(px, px)
	root.size = Vector2(px, px)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for l in ls:
		var tex := load(String(l.path)) as Texture2D
		if tex == null:
			continue
		var tr := TextureRect.new()
		tr.name = String(l.layer)
		tr.texture = tex
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if l.add:
			var mat := CanvasItemMaterial.new()
			mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			tr.material = mat
		root.add_child(tr)
	return root
