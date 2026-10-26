class_name LandAxies
extends RefCounted
## LD-A 2/3: the Axies on the Land are the player's own. Source order: raid defence team, then
## team preset 0, then random (the caller fills any gap with random bodies). Duplicates dropped.

## Starter gift (LD-A 3): ids from assets/data/land/decor.json.
const GIFT_DECOR: Array = ["decor_sav_tree2", "decor_sav_rock2", "decor_for_plant"]
const _CLASS_COLOR := {"plant": 8, "beast": 3, "aqua": 14, "reptile": 30, "bug": 20, "bird": 26}
const _CLASS_PART := {"plant": "Plant", "beast": "Beast", "aqua": "Aquatic", "reptile": "Reptile", "bug": "Bug", "bird": "Bird"}
const _PARTS: Array[int] = [AxieTypes.Part.MOUTH, AxieTypes.Part.HORN, AxieTypes.Part.BACK,
	AxieTypes.Part.TAIL, AxieTypes.Part.EAR, AxieTypes.Part.EYE]


## Raid defence party. The defence team lives on the server and nothing local stores it yet, so this
## reads an optional MetaState field and is empty until one exists.
static func defense_keys() -> Array:
	var v: Variant = MetaState.get("raid_defense_party")
	return (v as Array) if v is Array else []


static func preset0_keys() -> Array:
	var presets: Array = MetaState.team_presets
	if presets.is_empty():
		return []
	return (presets[0] as Dictionary).get("party", [])


## Up to `limit` distinct, known hero keys from the first source that has any.
static func pick_keys(limit: int) -> Array[String]:
	for src in [defense_keys(), preset0_keys()]:
		var out: Array[String] = []
		for k in src:
			var s := String(k)
			if s != "" and not out.has(s) and ContentDB.heroes.has(s) and out.size() < limit:
				out.append(s)
		if not out.is_empty():
			return out
	return []


## Body for a hero key: real genes (Vault Axie) when valid, else the class body combat uses.
static func descriptor_for(key: String) -> AxieDescriptor:
	var h: Dictionary = ContentDB.heroes.get(key, {})
	if h.is_empty():
		return null
	var genes := String(h.get("genes", "")).strip_edges()
	if genes != "":
		var d := AxieDescriptor.from_genes(genes)
		if d != null:
			return d
	var cls := String(h.get("cls", ""))
	if not _CLASS_PART.has(cls):
		return null
	var desc := AxieDescriptor.new()
	desc.body = AxieTypes.Body.NORMAL
	desc.color_variant = int(_CLASS_COLOR[cls])
	var parts: Array[AxiePartDescriptor] = []
	for pt in _PARTS:
		parts.append(AxiePartDescriptor.new(pt, 0, String(_CLASS_PART[cls]), 2, 1))
	desc.parts = parts
	return desc
