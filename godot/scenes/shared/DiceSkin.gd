class_name DiceSkin
extends RefCounted
## Cosmetics round 2: 3D dice skins. Data = assets/cosmetics/dice_skins.json (generated from Claude
## Design's dice/<id>/spec.md, one entry per skin), art = assets/cosmetics/dice/<id>/*.png.
## Textures are loaded on demand with ResourceLoader and never preloaded: only the equipped skin (and
## whatever the Profile / Echo Box is showing) is ever in memory. Display names live only in the JSON
## ("name"), so a rename is a one-line data change.

const ROOT := "res://assets/cosmetics/dice/"
const DATA := "res://assets/cosmetics/dice_skins.json"
const TIER_NAMES := {"c": "Common", "u": "Uncommon", "r": "Rare", "e": "Epic", "l": "Legendary", "m": "Mythic"}

static var _data: Dictionary = {}
static var _tex: Dictionary = {}   # path -> Texture2D


static func _skins() -> Dictionary:
	if _data.is_empty():
		var f := FileAccess.open(DATA, FileAccess.READ)
		if f != null:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_data = (d as Dictionary).get("skins", {})
	return _data


static func ids() -> Array:
	return _skins().keys()


static func has(id: String) -> bool:
	return _skins().has(id)


static func info(id: String) -> Dictionary:
	return _skins().get(id, {})


static func display_name(id: String) -> String:
	return String(info(id).get("name", ""))


## "c" | "u" | "r" | "e" | "l" | "m" ("" for an unknown id).
static func tier(id: String) -> String:
	return String(info(id).get("tier", ""))


static func tier_name(id: String) -> String:
	return String(TIER_NAMES.get(tier(id), ""))


static func has_file(id: String, file: String) -> bool:
	return (info(id).get("files", []) as Array).has(file)


## Texture `file` of skin `id` (e.g. "albedo.png"), loaded on first use. null when the skin has no such file.
static func texture(id: String, file: String) -> Texture2D:
	if not has_file(id, file):
		return null
	var p := ROOT + id + "/" + file
	if not _tex.has(p):
		_tex[p] = ResourceLoader.load(p) as Texture2D
	return _tex[p]


## Drop every cached texture except the ones of `keep` (skin ids). Call when the equipped skin changes.
static func release_except(keep: Array) -> void:
	for p in _tex.keys():
		var id := String(p).trim_prefix(ROOT).get_slice("/", 0)
		if not keep.has(id):
			_tex.erase(p)


# --- materials ------------------------------------------------------------------------------------

static var _body_mats: Dictionary = {}   # id -> StandardMaterial3D (one per skin, so equal skins pulse in phase)


static func _apply_common(m: StandardMaterial3D, p: Dictionary, id: String, normal_scale: float, skin_scale_key := "") -> void:
	m.roughness = float(p.get("roughness", 0.5))
	m.metallic = float(p.get("metallic", 0.0))
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if bool(p.get("normal_enabled", false)):
		var nt := texture(id, String(p.get("normal_texture", "")))
		if nt != null:
			m.normal_enabled = true
			m.normal_texture = nt
			m.normal_scale = normal_scale
	if bool(p.get("clearcoat_enabled", false)):
		m.clearcoat_enabled = true
		m.clearcoat = float(p.get("clearcoat", 0.5))
		m.clearcoat_roughness = float(p.get("clearcoat_roughness", 0.08))
	if bool(p.get("emission_enabled", false)):
		m.emission_enabled = true
		m.emission = Color.WHITE
		m.emission_energy_multiplier = float(p.get("emission_energy_multiplier", 1.0))
		var et := texture(id, String(p.get("emission_texture", "")))
		if et != null:
			m.emission_texture = et


## Die_Body material of a skin (shared: one instance per skin). Triplanar UVs, 0.5 m face = 1 / uv1_scale tiles.
static func body_material(id: String) -> StandardMaterial3D:
	if _body_mats.has(id):
		return _body_mats[id]
	var p: Dictionary = (info(id).get("body", {}) as Dictionary)
	var m := StandardMaterial3D.new()
	m.resource_name = "Skin_" + id
	m.albedo_texture = texture(id, String(p.get("albedo_texture", "albedo.png")))
	_apply_common(m, p, id, 1.0)
	m.uv1_triplanar = bool(p.get("uv1_triplanar", true))
	var s := float(p.get("uv1_scale", 2.0))
	m.uv1_scale = Vector3(s, s, s)
	if p.has("metallic_texture"):
		var mt := texture(id, String(p["metallic_texture"]))
		if mt != null:
			m.metallic_texture = mt
			m.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	if bool(p.get("rim_enabled", false)):
		m.rim_enabled = true
		m.rim = float(p.get("rim", 0.5))
		m.rim_tint = float(p.get("rim_tint", 0.0))
	if bool(p.get("anisotropy_enabled", false)):
		m.anisotropy_enabled = true
		m.anisotropy = float(p.get("anisotropy", 0.5))
	_body_mats[id] = m
	return m


## One Face_* material: the runtime face texture over the skin's plate normal / emission. Faces keep the
## mesh UVs and are never metallic.
static func face_material(id: String, face_tex: Texture2D) -> StandardMaterial3D:
	var p: Dictionary = (info(id).get("face", {}) as Dictionary)
	var m := StandardMaterial3D.new()
	m.resource_name = "SkinFace_" + id
	m.albedo_texture = face_tex
	_apply_common(m, p, id, 1.6)
	return m


## Forget the shared body materials of every skin but `keep` (with release_except, frees the textures).
static func release_materials_except(keep: Array) -> void:
	for k in _body_mats.keys():
		if not keep.has(k):
			_body_mats.erase(k)


## next_pass material of the sheen skins (gold, kingdom): unshaded additive overlay, triplanar, scrolled by DiceSkinFx.
static var _sheen_mats: Dictionary = {}


static func sheen_material(id: String) -> StandardMaterial3D:
	var tx := texture(id, "sheen.png")
	if tx == null:
		return null
	if not _sheen_mats.has(id):
		var m := StandardMaterial3D.new()
		m.resource_name = "Sheen_" + id
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_texture = tx
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(2, 2, 2)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_sheen_mats[id] = m
	return _sheen_mats[id]
