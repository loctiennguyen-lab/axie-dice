class_name LandDecor
extends RefCounted
## Land v1 decor rules (design/proposals/land-v1-spec.md §2-4). Pure functions over plain data so tests
## can drive them without a scene; the few helpers that touch MetaState (craft, claim) say so.
## Data: assets/data/land/decor.json. Positions are world units on the ground (x, z); `pos` is a Vector3
## whose y is ignored.

const DATA := "res://assets/data/land/decor.json"
const LIB := "res://assets/land/homeland/scenes/HomeLand_Asset/"

static var _cache: Dictionary = {}


static func data() -> Dictionary:
	if _cache.is_empty():
		var f := FileAccess.open(DATA, FileAccess.READ)
		if f != null:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_cache = d
	return _cache


static func all_defs() -> Array:
	return data().get("decor", [])


## Definition of one decor id, {} when unknown.
static func def(id: String) -> Dictionary:
	for d in all_defs():
		if String((d as Dictionary)["id"]) == id:
			return d
	return {}


static func scene_path(id: String) -> String:
	return LIB + String(def(id).get("scene", "")) + ".tscn"


static func tier_cap(tier: int) -> int:
	var caps: Array = data().get("tier_caps", [10])
	return int(caps[clampi(tier, 1, caps.size()) - 1])


static func snap(v: float, step: float = -1.0) -> float:
	var s := step if step > 0.0 else float(data().get("grid", 0.5))
	return snappedf(v, s)


static func rot_step(rot: int, dir: int = 1) -> int:
	return posmod(rot + dir, 8)


static func count_placed(placed: Array, id: String = "") -> int:
	if id == "":
		return placed.size()
	var n := 0
	for e in placed:
		if String((e as Dictionary)["id"]) == id:
			n += 1
	return n


# ------------------------------------------------------------------ craft

## "" when `id` can be crafted now, else the reason (shown in the disabled button).
static func craft_block(id: String, tier: int, owned: Dictionary, shards: int) -> String:
	var d := def(id)
	if d.is_empty() or not bool(d.get("craftable", true)):
		return "Not craftable."
	if tier < int(d["min_tier"]):
		return "Needs Land tier %d." % int(d["min_tier"])
	if int(owned.get(id, 0)) >= int(d["max_own"]):
		return "You own the maximum (%d)." % int(d["max_own"])
	if shards < int(d["shard_cost"]):
		return "Needs %d Shard." % int(d["shard_cost"])
	return ""


## Pays Shard through MetaState.spend (ledgered) and adds one copy. Returns the block reason or "".
static func craft(id: String) -> String:
	var why := craft_block(id, MetaState.land_tier, MetaState.land_decor_owned, MetaState.shard_pool)
	if why != "":
		return why
	if not MetaState.spend("shard", int(def(id)["shard_cost"]), "decor_" + id, false):
		return "Needs %d Shard." % int(def(id)["shard_cost"])
	MetaState.land_decor_owned[id] = int(MetaState.land_decor_owned.get(id, 0)) + 1
	MetaState.save_to_disk()
	return ""


# ------------------------------------------------------------------ placement

## ctx: {zones: [{p: Vector3, r: float}] hard keep-outs (buildings, plots, Portal), lanes: [[Vector3, Vector3]],
## props: [{p, r}] random scenery already standing (optional)}.
static func _lane_dist(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	var q := a + ab * t
	return Vector2(p.x - q.x, p.z - q.z).length()


static func _d2(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## "" when decor `id` may stand at `pos`, else the reason. `ignore` = index in `placed` being moved (-1 = new).
static func placement_block(id: String, pos: Vector3, placed: Array, ctx: Dictionary, tier: int,
		owned: Dictionary, ignore: int = -1) -> String:
	var d := def(id)
	if d.is_empty():
		return "Unknown decor."
	if tier < int(d.get("min_tier", 1)):
		return "Needs Land tier %d." % int(d["min_tier"])
	var r := float(d["footprint_r"])
	var D := data()
	var lim := float(D["land_half"]) - float(D["edge_margin"]) - r
	if absf(pos.x) > lim or absf(pos.z) > lim:
		return "Too close to the edge of the Land."
	for z in ctx.get("zones", []):
		if _d2(pos, z["p"]) < float(z["r"]) + r * 0.5:
			return "Blocked by a building, plot or the Portal."
	for l in ctx.get("lanes", []):
		if _lane_dist(pos, l[0], l[1]) < float(D["lane_clear"]):
			return "On an Axie path."
	for pr in ctx.get("props", []):
		if _d2(pos, pr["p"]) < (float(pr["r"]) + r) * 0.45:
			return "Overlaps scenery."
	var n_id := 0
	for i in placed.size():
		var e: Dictionary = placed[i]
		if i == ignore:
			continue
		if String(e["id"]) == id:
			n_id += 1
		var er := float(def(String(e["id"])).get("footprint_r", 0.5))
		if _d2(pos, Vector3(float(e["x"]), 0.0, float(e["z"]))) < (er + r) * float(D["overlap"]):
			return "Overlaps another decor."
	if ignore < 0:
		if placed.size() >= tier_cap(tier):
			return "Land tier %d holds %d decor." % [tier, tier_cap(tier)]
		if n_id >= int(owned.get(id, 0)):
			return "None left in storage."
	return ""


## Drops what a save cannot honour, never deletes a copy: unknown ids go, copies beyond what is owned, beyond the
## tier cap or off the Land go back to storage (simply not in `placed`). Returns the cleaned array.
static func sanitize(placed: Array, owned: Dictionary, tier: int) -> Array:
	var out: Array = []
	var per := {}
	var D := data()
	for e in placed:
		if not (e is Dictionary):
			continue
		var id := String(e.get("id", ""))
		var d := def(id)
		if d.is_empty() or out.size() >= tier_cap(tier) or tier < int(d.get("min_tier", 1)):
			continue
		if int(per.get(id, 0)) >= int(owned.get(id, 0)):
			continue
		var lim := float(D["land_half"]) - float(D["edge_margin"]) - float(d["footprint_r"])
		var x := float(e.get("x", 0.0))
		var z := float(e.get("z", 0.0))
		if absf(x) > lim or absf(z) > lim:
			continue
		per[id] = int(per.get(id, 0)) + 1
		out.append({"id": id, "x": snappedf(x, 0.01), "z": snappedf(z, 0.01), "rot": posmod(int(e.get("rot", 0)), 8)})
	return out


## Stored copies (owned minus placed) of one id.
static func in_storage(id: String, placed: Array, owned: Dictionary) -> int:
	return maxi(0, int(owned.get(id, 0)) - count_placed(placed, id))


# ------------------------------------------------------------------ aesthetic score + milestones

## sum(rarity points * min(count, 3)) + 2 per distinct biome (spec §4). Recomputed from `placed`, never saved.
static func aesthetic(placed: Array) -> int:
	var D := data()
	var counts := {}
	for e in placed:
		var id := String((e as Dictionary)["id"])
		counts[id] = int(counts.get(id, 0)) + 1
	var score := 0
	var biomes := {}
	for id in counts:
		var d := def(String(id))
		if d.is_empty():
			continue
		score += int((D["rarity_points"] as Dictionary).get(String(d["rarity"]), 0)) * mini(int(counts[id]), int(D["per_id_scored"]))
		if String(d.get("biome", "")) != "":
			biomes[String(d["biome"])] = true
	return score + int(D["biome_bonus"]) * biomes.size()


static func milestones() -> Array:
	return data().get("milestones", [])


## Milestones reached by `score` and not claimed yet.
static func claimable(score: int, claimed: Array) -> Array:
	var out: Array = []
	for m in milestones():
		if score >= int(m["points"]) and not claimed.has(String(m["id"])):
			out.append(m)
	return out


## Next unclaimed-and-unreached milestone, {} when all reached.
static func next_milestone(score: int) -> Dictionary:
	for m in milestones():
		if score < int(m["points"]):
			return m
	return {}


## Grants one milestone through cosmetics_owned (no Stone, no power). "" ok, else reason. Saves via SaveStore.
static func claim(id: String) -> String:
	var m: Dictionary = {}
	for x in milestones():
		if String(x["id"]) == id:
			m = x
	if m.is_empty():
		return "Unknown milestone."
	if MetaState.land_milestones_claimed.has(id):
		return "Already claimed."
	if aesthetic(MetaState.land_decor_placed) < int(m["points"]):
		return "Needs %d aesthetic points." % int(m["points"])
	var items: Array = []
	if m.has("item"):
		items.append(String(m["item"]))
	for it in m.get("items", []):
		items.append(String(it))
	for it in items:
		if not MetaState.cosmetics_owned.has(it):
			MetaState.cosmetics_owned.append(it)
	if m.has("decor"):
		var did := String(m["decor"])
		MetaState.land_decor_owned[did] = maxi(int(MetaState.land_decor_owned.get(did, 0)), 1)
	MetaState.land_milestones_claimed.append(id)
	MetaState.save_to_disk()
	return ""
