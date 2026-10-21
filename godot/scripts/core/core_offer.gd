class_name CoreOffer
extends RefCounted
## Depth v3 Core (Loi) + Run Rule offer logic (design/proposals/depth-v3-design.md 2.1-2.3, 2b, lane B).
##
## Pure and static: it reads RelicDef data + a ctx Dictionary and draws from an Rng the caller owns.
## RunState keeps the run state (tier chain, core_seen, reroll counters) and calls these. Nothing here
## touches the shared map/boss `_rng`; every stream is `Rng.new(seed ^ SALT)`.
##
## ctx keys: owned_ids Array, roster Array, seen Array (ids already shown this run), mode "short"|"full",
##           first_run bool (the account's first run: no quest / bet Cores), pick_index int, front_size int.
## Requires/excludes TOKENS (RelicDef.requires / .excludes), see token_ok():
##   class_pair            2+ Axie of one class          face:<x>        some party face has type or keyword x
##   back_face:<x|y>       a back-row Axie has such a face   faces_distinct:<n>  >= n distinct face types/keywords
##   front_hero            the party has a front-row Axie    egg_source          party/owned can make Eggs
##   owned:<id>            id owned                      owned_axis:<axis>   a Core of that axis owned
##   owned_tag:<tag>       an owned def carries the tag      rule:<id>           that Run Rule is held
## An unknown token is FALSE (fail closed): a requires with a typo hides the Core, an excludes with a typo
## never excludes. t_core_catalog (lane C) must reject unknown tokens.

const TIER_SALT := 0x7C0DE711
const CORE_SALT := 0xC0DE0FFE
const ANCHOR_SALT := 0xA17C4012
const RULE_SALT := 0x2B1E5A17
const NO_RULE_ID := "rule_none"
const AXES := ["stat", "dice", "pos", "mana", "quest", "rule"]


static func tuning() -> RelicTuning:
	return RelicSlots.tuning()


# --------------------------------------------------------------------------------------------
# Tier chain (2.1)
# --------------------------------------------------------------------------------------------

## Tier of each Core pick, drawn ONCE at new_run from Rng(seed ^ TIER_SALT). Short = 4 entries; Full = those 4
## plus two drawn from tier_tail_full. Pick 1 is always moss and no chain has crystal before pick 3.
static func draw_tier_chain(seed: int, mode: String) -> Array[int]:
	var t := tuning()
	var rng := Rng.new(seed ^ TIER_SALT)
	var chain: Array[int] = []
	var pick = _weighted(rng, t.tier_chains_short)
	for v in (pick as Array):
		chain.append(int(v))
	if mode == "full":
		var tail = _weighted(rng, t.tier_tail_full)
		for v in (tail as Array):
			chain.append(int(v))
	return chain


## rows = [[value, weight], ...]; returns value.
static func _weighted(rng: Rng, rows: Array):
	var total := 0
	for r in rows:
		total += int((r as Array)[1])
	var roll := rng.next_int(maxi(total, 1))
	for r in rows:
		if roll < int((r as Array)[1]):
			return (r as Array)[0]
		roll -= int((r as Array)[1])
	return (rows[rows.size() - 1] as Array)[0]


static func picks_total(mode: String) -> int:
	var t := tuning()
	return t.core_picks_full if mode == "full" else t.core_picks_short


static func t_cap(mode: String) -> int:
	var t := tuning()
	return t.core_t_cap_full if mode == "full" else t.core_t_cap_short


## Number of owned Crystal (tier 2) Cores. Quest Cores count while owned.
static func owned_crystal_count(owned_ids: Array) -> int:
	var n := 0
	for id in RelicSlots.owned_cores(owned_ids):
		var d = RelicRegistry.get_def(id)
		if d != null and int(d.rarity) >= 2:
			n += 1
	return n


## Final tier of pick `pick_index`: chain value + bumps (Elite affix+, Crow, quest...), crystal cap, floor moss.
## `first_tier_override` = Run Rule "Mua Sao" (pick 1 crystal). Returns 0..2.
static func effective_tier(chain: Array, pick_index: int, bump: int, owned_ids: Array, mode: String,
		first_tier_override: int = -1) -> int:
	var base := 0
	if pick_index >= 0 and pick_index < chain.size():
		base = int(chain[pick_index])
	if pick_index == 0 and first_tier_override >= 0:
		base = first_tier_override
	var tier := clampi(base + bump, 0, 2)
	if tier >= 2 and owned_crystal_count(owned_ids) >= t_cap(mode):
		tier = 1
	return tier


# --------------------------------------------------------------------------------------------
# Filters (2.2)
# --------------------------------------------------------------------------------------------

static func _hero(entry) -> Dictionary:
	return ContentDB.heroes.get(String((entry as Dictionary).get("hero_key", "")), {})


static func _face_labels(hero: Dictionary) -> Array:
	var out: Array = []
	for f in (hero.get("die", []) as Array):
		var ft := String((f as Dictionary).get("type", ""))
		if ft != "" and ft != "blank":
			out.append(ft)
		for kw in ((f as Dictionary).get("keywords", []) as Array):
			out.append(String(kw).split(":")[0])
	return out


static func held_rule_id(owned_ids: Array) -> String:
	for id in owned_ids:
		var d = RelicRegistry.get_def(String(id))
		if d != null and String(d.core_axis) == "run_rule":
			return String(id)
	return ""


## One token against ctx. See the header for the grammar.
static func token_ok(token: String, ctx: Dictionary) -> bool:
	var owned: Array = ctx.get("owned_ids", [])
	var roster: Array = ctx.get("roster", [])
	var parts := token.split(":", true, 1)
	var head := parts[0]
	var arg := parts[1] if parts.size() > 1 else ""
	match head:
		"class_pair":
			var seen: Dictionary = {}
			for e in roster:
				var c := String(_hero(e).get("cls", ""))
				if c == "":
					continue
				if seen.has(c):
					return true
				seen[c] = true
			return false
		"face":
			var alts := arg.split("|")   # "shield|thorns" = any of these
			for e in roster:
				var labs := _face_labels(_hero(e))
				for a in alts:
					if labs.has(a):
						return true
			return false
		"back_face":
			var wanted := arg.split("|")
			var front := int(ctx.get("front_size", 2))
			for i in roster.size():
				if i < front:
					continue
				for lbl in _face_labels(_hero(roster[i])):
					if wanted.has(lbl):
						return true
			return false
		"faces_distinct":
			var all: Dictionary = {}
			for e in roster:
				for lbl in _face_labels(_hero(e)):
					all[lbl] = true
			return all.size() >= int(arg)
		"faces_nondmg":
			var nd := 0
			for e in roster:
				for f in (_hero(e).get("die", []) as Array):
					var ft := String((f as Dictionary).get("type", ""))
					if ft != "dmg" and ft != "blank" and ft != "":
						nd += 1
			return nd >= int(arg)
		"front_hero":
			return roster.size() > 0
		"team_can_break":
			return CombatTraits.team_can_break(roster)
		"egg_source":
			for e in roster:
				var labs := _face_labels(_hero(e))
				if labs.has("summon") or labs.has("egg"):
					return true
			return _owned_has_tag(owned, "egg")
		"owned":
			return owned.has(arg)
		"owned_axis":
			for id in owned:
				var d = RelicRegistry.get_def(String(id))
				if d != null and String(d.core_axis) == arg:
					return true
			return false
		"owned_tag":
			return _owned_has_tag(owned, arg)
		"rule":
			return held_rule_id(owned) == arg
	return false


static func _owned_has_tag(owned: Array, tag: String) -> bool:
	for id in owned:
		var d = RelicRegistry.get_def(String(id))
		if d != null and (d.tags as PackedStringArray).has(tag):
			return true
	return false


## True when `def` can be shown now (not tier-checked). Used for Cores and Run Rules alike.
static func is_valid(def, ctx: Dictionary) -> bool:
	if def == null or bool(def.disabled) or bool(def.hidden_from_pool):
		return false
	var id := String(def.id)
	var owned: Array = ctx.get("owned_ids", [])
	if owned.has(id) or (ctx.get("seen", []) as Array).has(id):
		return false
	for tk in def.requires:
		if not token_ok(String(tk), ctx):
			return false
	for tk in def.excludes:
		if token_ok(String(tk), ctx):
			return false
	var asc_lt = (def.rule_knobs as Dictionary).get("asc_lt", null)   # Cheap Mana: only below this ascension
	if asc_lt != null and int(ctx.get("ascension", 0)) >= int(asc_lt):
		return false
	if not _bet_ok(def, ctx):
		return false
	var first_run := bool(ctx.get("first_run", false))
	if first_run and (bool(def.first_run_hidden) or String(def.core_axis) == "quest"):
		return false
	if String(def.core_axis) == "quest":
		if int(ctx.get("pick_index", 0)) == 0:
			return false
		for oid in owned:   # one unfinished quest Core at a time
			var od = RelicRegistry.get_def(String(oid))
			if od != null and String(od.core_axis) == "quest":
				return false
	return true


## Bet Cores (Fossil, Dim Stone; design 2.7 N10/N11) only show in the milestone picks they are defined for, never in
## quest / event / shop bonus offers (ctx.bonus). Knobs (RelicDef.rule_knobs): pick_max (0-based pick < pick_max),
## not_pick (1-based numbers, "last" = last pick of the mode), max_chain_t (hidden when the tier chain already has that many Crystals).
static func _bet_ok(def, ctx: Dictionary) -> bool:
	var kn: Dictionary = def.rule_knobs
	if not bool(kn.get("bet", false)):
		return true
	if bool(ctx.get("bonus", false)):
		return false
	var pick := int(ctx.get("pick_index", 0))
	var pmax := int(kn.get("pick_max", 0))
	if pmax > 0 and pick >= pmax:
		return false
	var total := picks_total(String(ctx.get("mode", "short")))
	for np in (kn.get("not_pick", []) as Array):
		if (str(np) == "last" and pick == total - 1) or (not str(np) == "last" and pick == int(np) - 1):
			return false
	if kn.has("max_chain_t"):
		var tn := 0
		for v in (ctx.get("tier_chain", []) as Array):
			if int(v) >= 2:
				tn += 1
		if tn >= int(kn["max_chain_t"]):
			return false
	if bool(kn.get("grant_crystal_other_axis", false)) and owned_crystal_count(ctx.get("owned_ids", [])) >= t_cap(String(ctx.get("mode", "short"))):
		return false
	return true


## Dim Stone payout: a random Crystal Core whose axis differs from the other cards of the offer (valid pool + core_seen
## still apply). Falls back to any Crystal axis, then to the nearest tier, so a pick never pays nothing while the pool has a Core.
## rng is the caller's own stream. Returns null when the pool is empty.
static func dim_stone_grant(rng: Rng, other_axes: Array, ctx: Dictionary):
	var pool := valid_pool(ctx)
	var cands: Array = []
	for d in pool:
		if int(d.rarity) == 2 and not other_axes.has(String(d.core_axis)):
			cands.append(d)
	if cands.is_empty():
		for d in pool:
			if int(d.rarity) == 2:
				cands.append(d)
	if cands.is_empty():
		for d in pool:
			if int(d.rarity) == 1:
				cands.append(d)
	if cands.is_empty():
		return null
	return cands[rng.next_int(cands.size())]


## All Cores (not Run Rules) that pass the filters, sorted by id (stable order for the draws).
static func valid_pool(ctx: Dictionary) -> Array:
	var out: Array = []
	for def in RelicRegistry.all_defs_sorted():
		var ax := String(def.core_axis)
		if ax == "" or ax == "run_rule":
			continue
		if is_valid(def, ctx):
			out.append(def)
	out.sort_custom(func(a, b): return String(a.id) < String(b.id))
	return out


# --------------------------------------------------------------------------------------------
# Core offer (2.1, 2.2)
# --------------------------------------------------------------------------------------------

static func card_of(def, slot: int) -> Dictionary:
	return {"t": "relic", "key": String(def.id), "rar": int(def.rarity), "title": "CORE", "desc": String(def.name),
		"sub": RewardGenerator.relic_desc(def), "core": true, "axis": String(def.core_axis),
		"tier": int(def.rarity), "slot": slot, "meme": is_meme(def)}


static func _owned_axes(owned: Array) -> Array:
	var out: Array = []
	for id in RelicSlots.owned_cores(owned):
		var d = RelicRegistry.get_def(id)
		var ax := String(d.core_axis)
		if not out.has(ax):
			out.append(ax)
	return out


## Defs of `pool` on `axis` with tier `tier`, else nearest tier (ties: the lower one). [] when the axis has none.
static func _axis_candidates(pool: Array, axis: String, tier: int, used_ids: Array) -> Array:
	for dist in 3:
		for sign in ([0] if dist == 0 else [-1, 1]):
			var tt: int = tier + sign * dist
			if tt < 0 or tt > 2:
				continue
			var c: Array = []
			for d in pool:
				if String(d.core_axis) == axis and int(d.rarity) == tt and not used_ids.has(String(d.id)):
					c.append(d)
			if not c.is_empty():
				return c
	return []


## Offer of `n` cards at `tier`. Distinct axes while the pool allows (card 1 follows an owned axis, card 2 an unowned
## one, the rest random), at most one stat and one quest card, missing axis -> nearest tier -> other axis, and under
## 2 valid cards the rest is filled with moss stat Cores. Every returned id must then be added to core_seen by the caller.
static func build_offer(rng: Rng, tier: int, ctx: Dictionary, n: int) -> Array[Dictionary]:
	var pool := valid_pool(ctx)
	var owned: Array = ctx.get("owned_ids", [])
	var owned_axes := _owned_axes(owned)
	var out: Array[Dictionary] = []
	var used_axes: Array = []
	var used_ids: Array = []
	var t := tuning()
	for i in n:
		var order := _axis_order(rng, i, owned_axes, used_axes, out, pool, tier, used_ids)
		var picked = null
		for ax in order:
			var cands := _axis_candidates(pool, String(ax), tier, used_ids)
			if _count_memes(out) >= 1:
				cands = cands.filter(func(d): return not is_meme(d))   # gacha C5: at most one meme Core per offer
			if cands.is_empty():
				continue
			if String(ax) == "stat" and _count_axis(out, "stat") >= t.core_stat_max_per_offer:
				continue
			if String(ax) == "quest" and _count_axis(out, "quest") >= t.core_quest_max_per_offer:
				continue
			picked = _pick_biased(rng, cands, ctx)
			break
		if picked == null:
			continue
		used_axes.append(String(picked.core_axis))
		used_ids.append(String(picked.id))
		out.append(card_of(picked, out.size()))
	# Fill: under 2 valid cards -> moss stat Cores (still no repeats of seen/owned).
	if out.size() < mini(2, n):
		for d in pool:
			if out.size() >= mini(2, n):
				break
			if String(d.core_axis) == "stat" and int(d.rarity) == 0 and not used_ids.has(String(d.id)):
				used_ids.append(String(d.id))
				out.append(card_of(d, out.size()))
	return out


## One draw inside an axis cell. Without ctx.anchor_house it is the plain uniform `next_int(n)` (old runs stay identical);
## with it the Anchor's house Cores weigh `anchor_house_bias` (fixed point x100), still ONE rng call.
static func _pick_biased(rng: Rng, cands: Array, ctx: Dictionary):
	var house: Array = ctx.get("anchor_house", [])
	if house.is_empty():
		return cands[rng.next_int(cands.size())]
	var hw := maxi(1, roundi(tuning().anchor_house_bias * 100.0))
	var total := 0
	for d in cands:
		total += hw if house.has(String(d.id)) else 100
	var roll := rng.next_int(total)
	for d in cands:
		roll -= hw if house.has(String(d.id)) else 100
		if roll < 0:
			return d
	return cands[cands.size() - 1]


## R1: draw a list of axes without replacement, weight = min(valid Cores in the axis cell, axis_weight_cap). One rng call per axis.
static func _weighted_axes(rng: Rng, axes: Array, weights: Dictionary) -> Array:
	var left := axes.duplicate()
	var out: Array = []
	while not left.is_empty():
		var total := 0
		for a in left:
			total += maxi(1, int(weights.get(a, 1)))
		var roll := rng.next_int(total)
		var k := 0
		for i in left.size():
			roll -= maxi(1, int(weights.get(left[i], 1)))
			if roll < 0:
				k = i
				break
		out.append(left[k])
		left.remove_at(k)
	return out


## Gacha C5: meme Cores carry the tag "meme"; an offer shows at most one.
static func is_meme(def) -> bool:
	return def != null and (def.tags as PackedStringArray).has("meme")


static func _count_memes(cards: Array) -> int:
	var n := 0
	for c in cards:
		if bool((c as Dictionary).get("meme", false)):
			n += 1
	return n


static func _count_axis(out: Array, axis: String) -> int:
	var n := 0
	for c in out:
		if String((c as Dictionary).get("axis", "")) == axis:
			n += 1
	return n


## Axis preference order for card `i`. Deterministic given rng state.
static func _axis_order(rng: Rng, i: int, owned_axes: Array, used_axes: Array, out: Array, pool: Array,
		tier: int, used_ids: Array) -> Array:
	var present: Array = []   # axes with at least one candidate (any tier)
	var weights: Dictionary = {}   # R1: valid Cores left in each axis cell, capped
	var wcap := maxi(1, tuning().axis_weight_cap)
	for d in pool:
		var ax := String(d.core_axis)
		if used_ids.has(String(d.id)):
			continue
		weights[ax] = mini(int(weights.get(ax, 0)) + 1, wcap)
		if not present.has(ax):
			present.append(ax)
	present.sort()
	var fresh: Array = present.filter(func(a): return not used_axes.has(a))
	var first: Array = []
	if i == 0:
		first = fresh.filter(func(a): return owned_axes.has(a))
	elif i == 1:
		first = fresh.filter(func(a): return not owned_axes.has(a))
	if first.is_empty():
		first = fresh
	var order: Array = _weighted_axes(rng, first, weights)
	var rest := fresh.filter(func(a): return not order.has(a))
	order.append_array(_weighted_axes(rng, rest, weights))
	var dup := present.filter(func(a): return not order.has(a))   # axes already in the offer: last resort
	order.append_array(dup)
	return order


## One-card reroll (2.1): replace offer[idx] with a same-tier card, same axis if the pool still has one, else an axis
## not yet in the offer. `ctx.seen` must already hold every card shown so far. Returns {} when no card exists.
static func reroll_card(rng: Rng, offer: Array, idx: int, ctx: Dictionary) -> Dictionary:
	if idx < 0 or idx >= offer.size():
		return {}
	var old: Dictionary = offer[idx]
	var tier := int(old.get("tier", 0))
	var pool := valid_pool(ctx)
	var used_ids: Array = []
	var others: Array = []   # the cards that stay: same per-offer caps as build_offer apply to the replacement
	for j in offer.size():
		used_ids.append(String((offer[j] as Dictionary).get("key", "")))
		if j != idx:
			others.append(offer[j])
	if _count_memes(others) >= 1:
		pool = pool.filter(func(d): return not is_meme(d))
	var old_axis := String(old.get("axis", ""))
	var same := _same_tier(pool, old_axis, tier, used_ids) if _axis_allowed(others, old_axis) else []
	if not same.is_empty():
		return card_of(same[rng.next_int(same.size())], idx)
	var other_axes: Array = []
	for d in pool:
		var ax := String(d.core_axis)
		if ax != old_axis and not other_axes.has(ax) and int(d.rarity) == tier \
				and not used_ids.has(String(d.id)) and _axis_allowed(others, ax):
			other_axes.append(ax)
	other_axes.sort()
	var in_offer: Array = []
	for c in others:
		in_offer.append(String((c as Dictionary).get("axis", "")))
	var fresh := other_axes.filter(func(a): return not in_offer.has(a))
	var use: Array = fresh if not fresh.is_empty() else other_axes
	if use.is_empty():
		return {}
	var ax2 := String(use[rng.next_int(use.size())])
	var c2 := _same_tier(pool, ax2, tier, used_ids)
	return card_of(c2[rng.next_int(c2.size())], idx)


## True when one more card of `axis` fits next to `others` (trần stat / quest mỗi bộ ba, same as build_offer).
static func _axis_allowed(others: Array, axis: String) -> bool:
	var t := tuning()
	if axis == "stat" and _count_axis(others, "stat") >= t.core_stat_max_per_offer:
		return false
	if axis == "quest" and _count_axis(others, "quest") >= t.core_quest_max_per_offer:
		return false
	return true


## True when reroll_card() would find a replacement (seed independent): lets the UI grey the button out.
static func can_reroll_card(offer: Array, idx: int, ctx: Dictionary) -> bool:
	return not reroll_card(Rng.new(0), offer, idx, ctx).is_empty()


static func _same_tier(pool: Array, axis: String, tier: int, used_ids: Array) -> Array:
	var c: Array = []
	for d in pool:
		if String(d.core_axis) == axis and int(d.rarity) == tier and not used_ids.has(String(d.id)):
			c.append(d)
	return c


# --------------------------------------------------------------------------------------------
# Run Rule offer (2b)
# --------------------------------------------------------------------------------------------

static func rule_card_of(def, slot: int) -> Dictionary:
	return {"t": "relic", "key": String(def.id), "rar": int(def.rarity), "title": "RUN RULE", "desc": String(def.name),
		"sub": RewardGenerator.relic_desc(def), "core": true, "rule": true, "axis": "run_rule", "tier": 0, "slot": slot}


## Two Run Rule cards from Rng(base_seed ^ RULE_SALT). `allow_none` (run 2+): 10% that card 2 is "no rule".
static func build_rule_offer(base_seed: int, ctx: Dictionary, allow_none: bool) -> Array[Dictionary]:
	var t := tuning()
	var rng := Rng.new(base_seed ^ RULE_SALT)
	var pool: Array = []
	for def in RelicRegistry.all_defs_sorted():
		if String(def.core_axis) == "run_rule" and String(def.id) != NO_RULE_ID and is_valid(def, ctx):
			pool.append(def)
	pool.sort_custom(func(a, b): return String(a.id) < String(b.id))
	var out: Array[Dictionary] = []
	var want_none := allow_none and rng.next_int(100) < t.rule_none_pct
	var none_def = RelicRegistry.get_def(NO_RULE_ID)
	var real := 2 - (1 if (want_none and none_def != null) else 0)
	while out.size() < real and not pool.is_empty():
		var total := 0
		for d in pool:
			total += maxi(1, int(d.weight))
		var roll := rng.next_int(total)   # 2b.2: weight 2 for R10 / R12 / R13, 1 for the rest
		var k := 0
		for i in pool.size():
			roll -= maxi(1, int(pool[i].weight))
			if roll < 0:
				k = i
				break
		out.append(rule_card_of(pool[k], out.size()))
		pool.remove_at(k)
	if want_none and none_def != null:
		out.append(rule_card_of(none_def, out.size()))
	return out
