class_name RaidGhost
extends RefCounted
## Raid R1 ghost (lane RV, design/proposals/land-v1-spec.md section 6, option A).
## A defence team is stored as a small snapshot; an attacker fights it as ordinary AI enemies.
##   snapshot unit = {key, cls, hp, die:[6 x {type, value, kw:[..]}]}   (exactly what worker/src/raid.js validates)
## `make_enemies` maps each snapshot unit onto a CombatEngine enemy Unit: hp -> max_hp, every face is one
## enemy face (the engine's own _pick_enemy_intent chooses the action), class -> AI role. Class passives
## (e.g. Scales thorns) and relics of the defender are NOT carried: the ghost is a die + hp, nothing more.

const CLASSES: Array[String] = ["plant", "beast", "aqua", "reptile", "bug", "bird"]
const MAX_UNITS := 5
## Face types the engine knows (ContentDB) - the same list the Worker accepts.
const FACE_TYPES: Array[String] = ["dmg", "shield", "heal", "mana", "poison", "debuff", "buff", "summon", "blank"]
## Class -> enemy AI role (only changes who the unit targets / heals).
const ROLE_BY_CLASS := {"plant": "tank", "beast": "bruiser", "aqua": "healer", "reptile": "poisoner", "bug": "assassin", "bird": "assassin"}
## Class -> existing monster art key, so the ghost has a body on the field (display only).
const ART_BY_CLASS := {"plant": "thornback", "beast": "cleaver", "aqua": "jellyfin", "reptile": "venomaw", "bug": "bugling", "bird": "pyrewing"}

static var _kw_re: RegEx = null


static func _clean_kw(raw) -> Array:
	if _kw_re == null:
		_kw_re = RegEx.create_from_string("^[a-z_]{1,16}$")
	var out: Array = []
	if raw is Array:
		for k in raw:
			if out.size() < 4 and typeof(k) == TYPE_STRING and _kw_re.search(String(k)) != null:
				out.append(String(k))
	return out


## Snapshot of one hero key from ContentDB.heroes; {} when the key is unknown or has no 6-face die.
static func snapshot_unit(hero_key: String) -> Dictionary:
	var h: Dictionary = ContentDB.heroes.get(hero_key, {})
	var die: Array = h.get("die", [])
	if h.is_empty() or die.size() != 6 or not CLASSES.has(String(h.get("cls", ""))):
		return {}
	var faces: Array = []
	for f in die:
		var t := String((f as Dictionary).get("type", "blank"))
		faces.append({"type": t if t != "" else "blank", "value": clampi(int((f as Dictionary).get("value", 0)), 0, 99),
			"kw": _clean_kw((f as Dictionary).get("keywords", []))})
	var key := hero_key.to_lower().substr(0, 32)
	return {"key": key, "cls": String(h["cls"]), "hp": clampi(int(h.get("max_hp", 10)), 1, 999), "die": faces}


## Snapshot of a party (hero keys, "" = empty seat). Empty array when nothing usable.
static func snapshot_team(party: Array) -> Array:
	var out: Array = []
	for k in party:
		if String(k) == "" or out.size() >= MAX_UNITS:
			continue
		var u := snapshot_unit(String(k))
		if not u.is_empty():
			out.append(u)
	return out


## Rough strength number shown next to a ghost: hp + sum of face values / 6 style total. 0..9999.
static func power_hint(team: Array) -> int:
	var p := 0
	for u in team:
		p += int((u as Dictionary).get("hp", 0))
		for f in (u as Dictionary).get("die", []):
			p += int((f as Dictionary).get("value", 0))
	return clampi(p, 0, 9999)


## Server/untrusted snapshot -> true when every unit is usable (same rules as the Worker, so a bad row cannot crash a fight).
static func is_valid_team(team) -> bool:
	if not (team is Array) or (team as Array).is_empty() or (team as Array).size() > MAX_UNITS:
		return false
	for u in team:
		if not (u is Dictionary) or not CLASSES.has(String((u as Dictionary).get("cls", ""))):
			return false
		if typeof((u as Dictionary).get("hp")) not in [TYPE_INT, TYPE_FLOAT] or int((u as Dictionary)["hp"]) < 1:
			return false
		var die = (u as Dictionary).get("die")
		if not (die is Array) or (die as Array).size() != 6:
			return false
		for f in die:
			if not (f is Dictionary) or String((f as Dictionary).get("type", "")) == "":
				return false
			if not FACE_TYPES.has(String((f as Dictionary).get("type", ""))):
				return false
	return true


## One snapshot unit -> enemy Unit with the given uid. `fallback_name` is shown when the hero key is not in ContentDB.
static func make_enemy(snap: Dictionary, uid: int) -> Unit:
	var cls := String(snap.get("cls", "plant"))
	var u := Unit.new()
	u.uid = uid
	u.side = "e"
	u.key = String(ART_BY_CLASS.get(cls, "slime"))
	var key := String(snap.get("key", ""))
	u.n = String((ContentDB.heroes.get(key, {}) as Dictionary).get("n", key.capitalize()))
	u.cls = ""   # enemies carry no hero class (their passives are not ported)
	u.role = String(ROLE_BY_CLASS.get(cls, "bruiser"))
	var hp := clampi(int(snap.get("hp", 10)), 1, 999)
	u.max_hp = hp
	u.hp = hp
	var die: Array = []
	for f in snap.get("die", []):
		var d: Dictionary = f
		var t := String(d.get("type", "blank"))
		if not FACE_TYPES.has(t):
			t = "blank"
		var v := clampi(int(d.get("value", 0)), 0, 99)
		die.append({"part": "m", "type": t, "value": v, "keywords": _clean_kw(d.get("kw", [])), "rarity": 0})
	u.die = die
	u.custom_state["ghost_key"] = key
	return u


## All enemies of a ghost; `first_uid` is consecutive (CombatEngine passes its token-uid allocator through `alloc`).
static func make_enemies(team: Array, alloc: Callable) -> Array:
	var out: Array = []
	for s in team:
		out.append(make_enemy(s, int(alloc.call())))
	return out
