class_name TeamPresets
extends RefCounted
## Saved named teams (R3 M2). Pure data helpers over MetaState.team_presets: an Array of
## {"name": String, "party": Array[String]} where party holds exactly PARTY_SIZE hero keys
## ("" = empty seat). Slots open by Land tier (R3 M2: 3 at Savannah, 4-6 Forest, 7-9 Arctic).

const PARTY_SIZE := 5
const NAME_MAX := 16
const MAX_SLOTS := 9
## Land tier -> number of preset slots. Tier 1 Savannah, 2 Forest, 3+ Arctic and above.
const SLOTS_BY_TIER := {1: 3, 2: 6, 3: 9}
const TIER_NAME := {2: "Forest", 3: "Arctic"}


static func slots_for_tier(tier: int) -> int:
	return int(SLOTS_BY_TIER.get(clampi(tier, 1, 3)))


## Land tier that opens slot n (1-based).
static func tier_for_slot(n: int) -> int:
	return 1 if n <= 3 else (2 if n <= 6 else 3)


static func clean_name(raw: String) -> String:
	return raw.strip_edges().substr(0, NAME_MAX)


## Normalises one entry from JSON; returns {} when it is unusable.
static func sanitize_entry(raw) -> Dictionary:
	if not (raw is Dictionary):
		return {}
	var n := clean_name(String((raw as Dictionary).get("name", "")))
	var p = (raw as Dictionary).get("party", [])
	if n == "" or not (p is Array):
		return {}
	var party: Array = []
	for i in PARTY_SIZE:
		party.append(String((p as Array)[i]) if i < (p as Array).size() else "")
	return {"name": n, "party": party}


static func sanitize_list(raw) -> Array:
	var out: Array = []
	if raw is Array:
		for e in raw:
			var s := sanitize_entry(e)
			if not s.is_empty() and out.size() < MAX_SLOTS:
				out.append(s)
	return out


## THE party-duplicate rule, shared by Run Setup, the Team Presets editor and saved presets:
## free starter Axies may sit in any number of seats; a Vault Axie fits one seat only.
static func may_repeat(key: String) -> bool:
	return key != "" and not MetaState.is_vault_key(key)


## True when `key` cannot go into `slot` of `party` because it is a Vault Axie already seated elsewhere.
static func seat_taken(party: Array, slot: int, key: String) -> bool:
	if key == "" or may_repeat(key):
		return false
	for j in party.size():
		if j != slot and String(party[j]) == key:
			return true
	return false


## True when `party` holds the same Vault Axie in two seats.
static func has_vault_duplicate(party: Array) -> bool:
	var seen := {}
	for k in party:
		var s := String(k)
		if s == "" or may_repeat(s):
			continue
		if seen.has(s):
			return true
		seen[s] = true
	return false


## True when this seat key still resolves to a playable hero (starter or Vault Axie still held).
static func seat_ok(key: String) -> bool:
	if key == "" or not ContentDB.heroes.has(key):
		return false
	if MetaState.is_vault_key(key):
		var e := MetaState.vault_entry(key.substr(MetaState.VAULT_KEY_PREFIX.length()))
		if MetaState.vault_stale(e):
			return false
	return true


static func missing_count(entry: Dictionary) -> int:
	var n := 0
	for k in (entry.get("party", []) as Array):
		if not seat_ok(String(k)):
			n += 1
	return n


## Party with unusable seats blanked, ready to load into Run Setup.
static func usable_party(entry: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var seen := {}
	for k in (entry.get("party", []) as Array):
		var s := String(k)
		if seat_ok(s) and (may_repeat(s) or not seen.has(s)):
			out.append(s)
			seen[s] = true
		else:
			out.append("")
	return out


static func has_nft(entry: Dictionary) -> bool:
	for k in (entry.get("party", []) as Array):
		if MetaState.is_vault_key(String(k)):
			return true
	return false


## Why a party cannot be saved ("" = fine): needs 5 filled seats, no Vault Axie twice.
static func save_block_reason(party: Array) -> String:
	var filled := 0
	for k in party:
		if String(k) != "":
			filled += 1
	if filled < PARTY_SIZE:
		return "Fill slot %d first" % (party.find("") + 1) if party.has("") else "Fill every slot first"
	if has_vault_duplicate(party):
		return "Each Vault Axie only once"
	return ""


# ---------------------------------------------------------------- mutations (persist via MetaState / SaveStore)

## Tests: force a Land tier (0 = use the real one).
static var tier_override := 0


## Land tier the player is on. Same source as Land.gd (_current_tier): MetaState.land_tier once
## lane E adds it, else tier 1 (Savannah).
static func current_tier() -> int:
	if tier_override > 0:
		return tier_override
	var v: Variant = MetaState.get("land_tier")
	return maxi(int(v), 1) if v != null else 1


static func tier_name(tier: int = -1) -> String:
	var t := clampi(current_tier() if tier < 0 else tier, 1, 3)
	return "Savannah" if t == 1 else String(TIER_NAME[t])


static func slot_count() -> int:
	return slots_for_tier(current_tier())


static func count() -> int:
	return MetaState.team_presets.size()


static func has_room() -> bool:
	return count() < slot_count()


## Adds a preset in the first free slot. Returns "" on success, else the reason.
static func add(name: String, party: Array) -> String:
	var n := clean_name(name)
	if n == "":
		return "Give the team a name"
	var why := save_block_reason(party)
	if why != "":
		return why
	if not has_room():
		return "All preset slots are used"
	MetaState.team_presets.append({"name": n, "party": party.duplicate()})
	MetaState.save_to_disk()
	return ""


static func update(i: int, name: String, party: Array) -> String:
	if i < 0 or i >= count():
		return "No such preset"
	var n := clean_name(name)
	if n == "":
		return "Give the team a name"
	var why := save_block_reason(party)
	if why != "":
		return why
	MetaState.team_presets[i] = {"name": n, "party": party.duplicate()}
	MetaState.save_to_disk()
	return ""


static func remove(i: int) -> void:
	if i >= 0 and i < count():
		MetaState.team_presets.remove_at(i)
		MetaState.save_to_disk()


## Copy goes to the next free slot as "<name> 2" (trimmed to NAME_MAX). Returns "" on success.
static func copy(i: int) -> String:
	if i < 0 or i >= count():
		return "No such preset"
	if not has_room():
		return "All preset slots are used"
	var e: Dictionary = MetaState.team_presets[i]
	var n := String(e["name"])
	n = (n.substr(0, NAME_MAX - 2) + " 2")
	MetaState.team_presets.append({"name": n, "party": (e["party"] as Array).duplicate()})
	MetaState.save_to_disk()
	return ""


## Reorder: moves preset i by dir (-1 / +1). Returns the new index (or i when it cannot move).
static func move(i: int, dir: int) -> int:
	var j := i + dir
	if i < 0 or i >= count() or j < 0 or j >= count():
		return i
	var t: Variant = MetaState.team_presets[i]
	MetaState.team_presets[i] = MetaState.team_presets[j]
	MetaState.team_presets[j] = t
	MetaState.save_to_disk()
	return j
