class_name RewardGenerator
extends RefCounted
## Post-combat / treasure reward generation — vertical-slice subset of src/engine.js
## genRewards()/mkReward() (design/gdd/godot-port-rule-spec.md §9). Pure static functions,
## no autoload registration, no instance state: deterministic given the Rng instance passed
## in, mirroring ContentDB.budget()/scale_die() being plain functions over data rather than
## stateful objects.
##
## IMPLEMENTED reward types (src/engine.js mkReward(), engine.js:1077-1121):
##   level  — src/engine.js :1080. Swaps one roster member's hero_key for its ContentDB.tier_up
##            entry (only offered for a member that HAS one). RunState.apply_chosen_reward()
##            does the actual swap + tier/max_hp refresh.
##   ascend — src/engine.js :1086. The "cannot tier up" fallback: +25% all six faces (a
##            muts:{type:"oc",mult:1.25} entry — CombatEngine._build_unit_from_roster() already
##            applies "oc" muts) + permanent +6 Max HP.
##   relic  — grants a RelicRegistry .tres relic not already owned / not already offered
##   hp     — +Max HP to one roster member (RunState roster[].bonus_hp — already read by
##            CombatEngine._build_unit_from_roster())
##   reroll — +1 permanent max reroll (RunState.bonus_reroll — already read by
##            CombatEngine.setup_new() via combat_setup["bonus_reroll"])
##   chaos  — src/engine.js :1115. A rarity>=2 relic, but the whole party loses 20% Max HP
##            for the rest of the run (RunState._reduce_party_max_hp_pct(), already shared
##            with the "gamble_legend" shrine event fx).
##   curse  — src/engine.js :1119. Enemies +18% HP / +12% damage for the rest of the run
##            (RunState.run_mods, read by CombatEngine via combat_setup["run_mods"]) + 1 extra
##            maximum Reroll. PARTIAL PORT — see RunState.apply_chosen_reward()'s "curse"
##            branch for the one JS sub-effect ("+4 damage on every one of your own damage
##            faces", the src/engine.js pseudo-relic `__curse_dmg`) that could NOT be ported
##            here: it needs a build-time face-mutation hook in relic_hooks.gd/
##            combat_engine.gd, both off-limits to this pass. Flagged for lead-programmer,
##            not shipped as a silently-broken promise — the reward's own "sub" text below
##            only advertises the effects that are actually real.
##
## REMOVED: a previous pass added an invented `shard` reward type with no src/engine.js
## counterpart (Gene Shard is a flat per-combat grant in JS, applied before genRewards() ever
## runs — see finishCombat(), engine.js ~995 — never one of the 3 reward cards). Removed
## rather than re-justified: this pass ports 4 real reward types (level/ascend/chaos/curse),
## which makes the invented filler type unnecessary for reward-screen variety.
##
## NOT YET PORTED (would need content this vertical slice doesn't ship):
##   face/rune — need src/data.js FACE_POOL + RUNES ported into ContentDB (Gene Mutation
##            pool). Real content, not yet in this vertical slice. Left out rather than
##            half-wired with a crash trap, per task instructions.

## The line the player reads on a relic card. It lives on the RelicDef itself
## (`relic_def.gd`'s `description`) — this used to be a hand-kept dictionary here, which meant
## a relic and its words were added in two different files and could disagree. The fallback
## stays for a relic whose text has genuinely not been written yet: an archetype line is a
## poor description, but a blank one reads as a relic that does nothing.
static func relic_desc(def: RelicDef) -> String:
	if def == null:
		return ""
	return def.description if def.description != "" else "Archetype: %s" % def.archetype


## src/data.js RELIC_SHOP_COST, verbatim — indexed by rarity 0..4 (Common..Mythic). This
## vertical slice's relics only reach rarity 3 (Legendary) (relic_def.gd's rarity comment),
## so index 4 is unreachable today but kept for parity with the source table.
const RELIC_SHOP_COST := [45, 75, 120, 180, 260]

const HEAL_ITEM_COST := 40
const HEAL_ITEM_V := 10
const REROLL_ITEM_COST := 110


## src/engine.js genRewards()'s rarity band per tier — verbatim thresholds (rule spec §9):
## tier>=3 -> [2,4], tier==2 -> [1,3], tier==1 -> [1,2], tier==0 -> [0, 1 or 2 past pw>6].
static func rarity_band(tier: int, pw: int) -> Array:
	if tier >= 3:
		return [2, 4]
	if tier == 2:
		return [1, 3]
	if tier == 1:
		return [1, 2]
	return [0, 1 + (1 if pw > 6 else 0)]


## Main entry point. `owned_relic_ids`/`roster` are read-only inputs (RunState's own copies —
## generation never mutates them; RunState.apply_chosen_reward() does the actual mutation).
## `max_rerolls_now` gates the "reroll" type out of the pool once it would be pointless,
## mirroring src/engine.js's `if(s.maxRerolls<4) pool.push('reroll')`. `count` is the number
## of cards offered — src/data.js ascMods(a).rewards: 3 normally, 2 at Ascension>=7 (callers
## thread that through, RewardGenerator itself has no ascension input).
## `offer_ctx` (optional, default {} = legacy behaviour): {ascension, pacts_taken, stickers[, source]}.
## When non-empty the relic cards use the v2 offer system (rarity by source, lean tags on the first
## relic card, gating, hard exclusions) and `twinfates` drops the `reroll`/`curse` cards.
static func generate(pw: int, tier: int, rng: Rng, owned_relic_ids: Array = [],
		roster: Array = [], max_rerolls_now: int = 2, count: int = 3,
		offer_ctx: Dictionary = {}) -> Array[Dictionary]:
	var band := rarity_band(tier, pw)
	var pool := _type_pool(tier, max_rerolls_now, roster)
	var v2: Dictionary = {}
	if not offer_ctx.is_empty():
		v2 = offer_ctx.duplicate()
		v2["owned_ids"] = owned_relic_ids
		v2["roster"] = roster
		if not v2.has("source"):
			v2["source"] = offer_source_for_tier(tier, pw)
		if twinfates_blocks_reroll(owned_relic_ids):
			pool = pool.filter(func(x): return x != "reroll" and x != "curse")
	var out: Array[Dictionary] = []
	var guard := 0
	while out.size() < count and guard < 80:
		guard += 1
		var t: String = pool[rng.next_int(pool.size())]
		var r := _make_reward(t, band, pw, rng, owned_relic_ids, roster, out, v2)
		if not r.is_empty():
			out.append(r)
	# Fallback fill mirrors engine.js's `while(out.length<n){ const r=mkReward(s,'hp',...); ...
	# else break; }` — guarantees a full offer even if every other type ran dry, but never
	# spins forever if even "hp" can't produce one (empty roster).
	while out.size() < count:
		var r := _make_reward("hp", band, pw, rng, owned_relic_ids, roster, out, v2)
		if r.is_empty():
			break
		out.append(r)
	return out


## src/engine.js genRewards()'s pool construction (engine.js:1054-1068), minus the
## unported face/rune tokens and minus the `importedStuck` branch (no imported/vault Axies
## exist in this vertical slice's roster shape — `entry.get("imported")` is never set).
##   canLevel -> pool 'level','level'   (else -> 'ascend','ascend')
##   always   -> 'relic','relic'        (JS also pushes 'face','face','rune' here — unported)
##   maxRerolls<4 -> 'reroll'
##   always   -> 'hp'
##   tier>=2  -> 'relic','chaos'        (JS also pushes 'face' here — unported)
##   tier>=3  -> 'relic','chaos','curse' (JS also pushes 'face' here — unported)
static func _type_pool(tier: int, max_rerolls_now: int, roster: Array) -> Array:
	var can_level := false
	for e in roster:
		if ContentDB.tier_up.has(String((e as Dictionary).get("hero_key", ""))):
			can_level = true
			break
	var pool := ["relic", "relic"]
	if can_level:
		pool.append_array(["level", "level"])
	else:
		pool.append_array(["ascend", "ascend"])
	if max_rerolls_now < 4:
		pool.append("reroll")
	pool.append("hp")
	if tier >= 2:
		pool.append_array(["relic", "chaos"])
	if tier >= 3:
		pool.append_array(["relic", "chaos", "curse"])
	return pool


static func _make_reward(t: String, band: Array, pw: int, rng: Rng, owned_relic_ids: Array,
		roster: Array, out: Array[Dictionary], v2: Dictionary = {}) -> Dictionary:
	match t:
		"level":
			return _make_level_reward(rng, roster, out)
		"ascend":
			return _make_ascend_reward(rng, roster, out)
		"relic":
			var already_offered: Array = []
			for o in out:
				if String(o.get("t", "")) == "relic":
					already_offered.append(o.get("key"))
			var def: RelicDef
			if v2.is_empty():
				def = pick_relic(rng, owned_relic_ids + already_offered, band[0], band[1])
			else:
				var c := v2.duplicate()
				c["offered_ids"] = already_offered
				def = pick_offer_relic(rng, String(c["source"]), c, already_offered.is_empty())
			if def == null:
				return {}
			return {
				"t": "relic", "key": def.id, "rar": def.rarity, "title": "RELIC",
				"desc": def.name, "sub": relic_desc(def),
			}
		"hp":
			if roster.is_empty():
				return {}
			var e: Dictionary = roster[rng.next_int(roster.size())]
			var v: int = 6 + int(floor(pw * 0.9))
			return {
				"t": "hp", "persistent_id": int(e.get("persistent_id", 0)), "v": v, "rar": 0,
				"title": "GENE VITALITY", "desc": "%s: +%d Max HP" % [_hero_name(e), v], "sub": "",
			}
		"reroll":
			for o in out:
				if String(o.get("t", "")) == "reroll":
					return {}
			return {
				"t": "reroll", "rar": 1, "title": "REROLL +1",
				"desc": "+1 maximum Reroll", "sub": "Lasts the whole run",
			}
		"chaos":
			return _make_chaos_reward(rng, owned_relic_ids, out)
		"curse":
			return _make_curse_reward(out)
	return {}


## src/engine.js mkReward() 'level' branch (engine.js:1080-1085). Only offers a roster member
## that HAS a ContentDB.tier_up entry, and never the same member twice within one offer (the
## `out` de-dup check mirrors JS's `!out.some(o=>o.t==='level'&&o.uid===x.uid)`).
static func _make_level_reward(rng: Rng, roster: Array, out: Array[Dictionary]) -> Dictionary:
	var already: Array = []
	for o in out:
		if String(o.get("t", "")) == "level":
			already.append(int(o.get("persistent_id", -1)))
	var candidates: Array = []
	for e in roster:
		var entry: Dictionary = e
		if not ContentDB.tier_up.has(String(entry.get("hero_key", ""))):
			continue
		if already.has(int(entry.get("persistent_id", -1))):
			continue
		candidates.append(entry)
	if candidates.is_empty():
		return {}
	var picked: Dictionary = candidates[rng.next_int(candidates.size())]
	var next_key := String(ContentDB.tier_up.get(String(picked.get("hero_key", "")), ""))
	if next_key == "":
		return {}
	var next_def: Dictionary = ContentDB.heroes.get(next_key, {})
	# runloop-ux-backlog P0-3: hero names do NOT change on tier-up by design (e.g. "Pomodoro"
	# stays "Pomodoro" tier 1->2->3) — a previous "%s -> %s" phrasing put the arrow between two
	# IDENTICAL strings whenever that happened, which reads as a rendering bug rather than a
	# reward. The arrow now points at the thing that actually changes: tier.
	var cur_def: Dictionary = ContentDB.heroes.get(String(picked.get("hero_key", "")), {})
	var cur_tier: int = int(cur_def.get("tier", int(picked.get("tier", 0))))
	var next_tier: int = int(next_def.get("tier", cur_tier + 1))
	return {
		"t": "level", "persistent_id": int(picked.get("persistent_id", 0)), "key": next_key, "rar": 2,
		"title": "LEVEL UP",
		"desc": "%s: Tier %d to Tier %d" % [_hero_name(picked), cur_tier, next_tier],
		"sub": "Rewrites all six faces and Max HP",
	}


## src/engine.js mkReward() 'ascend' branch (engine.js:1086-1090) — the tier-up fallback for
## a roster member with no ContentDB.tier_up entry (already at max tier, or an import-style
## Axie in a future vertical slice). Never the same member twice within one offer.
static func _make_ascend_reward(rng: Rng, roster: Array, out: Array[Dictionary]) -> Dictionary:
	var already: Array = []
	for o in out:
		if String(o.get("t", "")) == "ascend":
			already.append(int(o.get("persistent_id", -1)))
	var candidates: Array = []
	for e in roster:
		var entry: Dictionary = e
		if ContentDB.tier_up.has(String(entry.get("hero_key", ""))):
			continue
		if already.has(int(entry.get("persistent_id", -1))):
			continue
		candidates.append(entry)
	if candidates.is_empty():
		return {}
	var picked: Dictionary = candidates[rng.next_int(candidates.size())]
	return {
		"t": "ascend", "persistent_id": int(picked.get("persistent_id", 0)), "rar": 2,
		"title": "ASCENSION", "desc": "%s: all six faces +25%%" % _hero_name(picked),
		"sub": "+6 Max HP · stacks without limit",
	}


## src/engine.js mkReward() 'chaos' branch (engine.js:1115-1118) — a rarity>=2 relic (NOT
## band-gated like the plain "relic" type — JS calls `relicPool(s,3)` unconditionally, then
## filters `r.rar>=2`), in exchange for -20% party Max HP for the rest of the run.
static func _make_chaos_reward(rng: Rng, owned_relic_ids: Array, out: Array[Dictionary]) -> Dictionary:
	for o in out:
		if String(o.get("t", "")) == "chaos":
			return {}
	var already_offered: Array = []
	for o in out:
		if String(o.get("t", "")) == "relic":
			already_offered.append(o.get("key"))
	var def := pick_relic(rng, owned_relic_ids + already_offered, 2, 3)
	if def == null:
		return {}
	return {
		"t": "chaos", "key": def.id, "rar": 4, "title": "CHAOS DEAL", "desc": def.name,
		"sub": "GAMBLE: the whole party loses 20%% Max HP for the rest of the run\n%s" % (
			relic_desc(def)),
	}


## src/engine.js mkReward() 'curse' branch (engine.js:1119-1121). Sub text intentionally
## only advertises the run_mods + reroll effects that are actually wired end-to-end — see
## this file's header note on the "+4 dmg per face" half that could not be ported here.
static func _make_curse_reward(out: Array[Dictionary]) -> Dictionary:
	for o in out:
		if String(o.get("t", "")) == "curse":
			return {}
	return {
		"t": "curse", "rar": 4, "title": "CURSE PACT",
		"desc": "Enemies gain 18% HP and 12% damage for the rest of the run",
		"sub": "IN EXCHANGE: you gain 1 extra maximum Reroll.",
	}


static func _hero_name(entry: Dictionary) -> String:
	var hero_def: Dictionary = ContentDB.heroes.get(String(entry.get("hero_key", "")), {})
	return String(hero_def.get("n", entry.get("hero_key", "?")))


# ===========================================================================
# RELIC OFFER v2 (relic-set-v2 §4, design/l1-relic-answers.md §8).
#
# Pure functions of (rng, ctx). Two steps: (1) pick a rarity by the source's weights, (2) pick a
# relic inside that rarity by integer weights `m`. Candidates are sorted by id, weights are ints,
# so the result depends only on the rng stream, never on UI order or float rounding. The rng is
# ALWAYS the caller's (epoch stream); nothing here makes a Rng.
#
# ctx (all optional): {owned_ids: Array, roster: Array[{hero_key}], ascension: int,
#   pacts_taken: Array, stickers: Dictionary, offered_ids: Array}
# ===========================================================================

## reward tier (RunState) -> offer source name. Tier 1 is "milestone"; Treasure/chest/event callers
## pass their own source name instead.
static func offer_source_for_tier(tier: int, pw: int) -> String:
	if tier >= 3:
		return "boss"
	if tier == 2:
		return "elite"
	if tier == 1:
		return "milestone"
	return "battle_late" if pw > 6 else "battle"


## Twinfates mutual exclusion also removes the reward `reroll`/`curse` cards, the shop `reroll` item
## and the event `bless_reroll` option (Liam 11/10). Callers outside this file use this test.
static func twinfates_blocks_reroll(owned_ids: Array) -> bool:
	return owned_ids.has(RelicSlots.tuning().twinfates_id)


static func _party_classes(roster: Array) -> Array:
	var out: Array = []
	for e in roster:
		var hero: Dictionary = ContentDB.heroes.get(String((e as Dictionary).get("hero_key", "")), {})
		var cls := String(hero.get("cls", ""))
		if cls != "" and not out.has(cls):
			out.append(cls)
	return out


static func _arch_tags(def) -> Array:
	var order := RelicSlots.tuning().tag_order
	var out: Array = []
	for t in def.tags:
		if order.has(t):
			out.append(String(t))
	return out


## score(t) = owned relics carrying t + party Axies whose class maps to t (§4.3).
static func tag_scores(owned_ids: Array, roster: Array) -> Dictionary:
	var sc: Dictionary = {}
	for id in owned_ids:
		var d = RelicRegistry.get_def(String(id))
		if d == null:
			continue
		for t in _arch_tags(d):
			sc[t] = int(sc.get(t, 0)) + 1
	for e in roster:
		var hero: Dictionary = ContentDB.heroes.get(String((e as Dictionary).get("hero_key", "")), {})
		var t2 := String((ContentDB.CLASS_PASSIVE.get(String(hero.get("cls", "")), {}) as Dictionary).get("a", ""))
		if t2 != "":
			sc[t2] = int(sc.get(t2, 0)) + 1
	return sc


## The 2 highest-score tags (score >= 1); ties by the fixed tag order.
static func lean_tags(owned_ids: Array, roster: Array) -> Array:
	var sc := tag_scores(owned_ids, roster)
	var order := RelicSlots.tuning().tag_order
	var tags: Array = []
	for t in order:
		if int(sc.get(t, 0)) >= 1:
			tags.append(String(t))
	tags.sort_custom(func(a, b):
		var sa := int(sc[a])
		var sb := int(sc[b])
		if sa != sb:
			return sa > sb
		return order.find(a) < order.find(b))
	return tags.slice(0, 2)


static func _owned_has_tag(owned_ids: Array, tag: String) -> bool:
	for id in owned_ids:
		var d = RelicRegistry.get_def(String(id))
		if d != null and d.tags.has(tag):
			return true
	return false


## Hard exclusions (§4.2). `pact_mode` is true only for the boss Pact screen.
static func is_offerable(def, ctx: Dictionary, pact_mode: bool = false) -> bool:
	var t := RelicSlots.tuning()
	var owned: Array = ctx.get("owned_ids", [])
	var id := String(def.id)
	if def.hidden_from_pool or id.begins_with("__") or owned.has(id) or (ctx.get("offered_ids", []) as Array).has(id):
		return false
	var is_pact := String(def.pact_group) != ""
	if is_pact != pact_mode:
		return false
	if is_pact and (ctx.get("pacts_taken", []) as Array).has(id):
		return false
	if String(def.exsub_of) != "" and owned.has(String(def.exsub_of)):
		return false
	if def.requires_any.size() > 0:
		var any := false
		for r in def.requires_any:
			if owned.has(String(r)):
				any = true
		if not any:
			return false
	if String(def.layer) == "duo":
		for tg in def.tags:
			if not _owned_has_tag(owned, String(tg)):
				return false
	if String(def.requires_class) != "" and not _party_classes(ctx.get("roster", [])).has(String(def.requires_class)):
		return false
	# twinfates <-> every relic Reroll source, both ways
	if id == t.twinfates_id:
		for x in t.twinfates_exclusive:
			if owned.has(String(x)):
				return false
	elif owned.has(t.twinfates_id) and t.twinfates_exclusive.has(id):
		return false
	if id == t.fortune_id and int(ctx.get("ascension", 0)) >= t.fortune_blocked_from_ascension:
		return false
	if is_pact:   # a pact that can never be placed (multiplier slot held only by Eternal relics) is filtered
		var chk := RelicSlots.check_add(owned, ctx.get("stickers", {}), id, int(ctx.get("ascension", 0)), false)
		if not bool(chk["ok"]):
			return false
	return true


## Integer weight `m` of one candidate (§4.3, answers §8.3). `lead` = this is the offer's first relic card.
static func relic_weight(def, ctx: Dictionary, lean: Array, lead: bool) -> int:
	var t := RelicSlots.tuning()
	var owned: Array = ctx.get("owned_ids", [])
	var sc := tag_scores(owned, ctx.get("roster", []))
	var arch := _arch_tags(def)
	var m := t.m_neutral
	if lead:
		for tg in arch:
			if lean.has(tg):
				m = t.m_lean
				break
	var payoff := t.payoff_layers.has(String(def.layer))
	if payoff:
		for tg in arch:
			var enablers := 0
			for id in owned:
				var d = RelicRegistry.get_def(String(id))
				if d != null and String(d.layer) == "enabler" and d.tags.has(tg):
					enablers += 1
			if enablers >= 2:
				m *= t.m_payoff_mult
				break
	# overrides to the floor
	if payoff and not arch.is_empty():
		var any_src := false
		for tg in arch:
			if int(sc.get(tg, 0)) > 0:
				any_src = true
		if not any_src:
			m = t.m_floor
	if String(def.mult_axis) != "":
		var cap := RelicSlots.capacity(int(ctx.get("ascension", 0)), owned)
		var cls_g: bool = String(def.mult_axis) == "G"
		var held := 0
		for id in owned:
			var d2 = RelicRegistry.get_def(String(id))
			if d2 != null and (String(d2.mult_axis) == "G") == cls_g and String(d2.mult_axis) != "":
				held += 1
		if held >= int(cap["g"] if cls_g else cap["a"]):
			m = t.m_floor
	if owned.has(t.chalice_id) and t.chalice_dead_draws.has(String(def.id)):
		m = t.m_floor
	return m


## One relic for `source` ("battle", "elite", "shop", ...), or null when nothing is valid.
## Two draws from `rng` when there is a candidate: rarity, then relic.
static func pick_offer_relic(rng: Rng, source: String, ctx: Dictionary, lead: bool = false):
	var t := RelicSlots.tuning()
	var weights: Array = t.rarity_weights.get(source, [25, 25, 25, 25])
	var lean := lean_tags(ctx.get("owned_ids", []), ctx.get("roster", []))
	var by_rar: Array = [[], [], [], []]
	for def in RelicRegistry.offerable_defs_sorted():   # sorted by sort_index; re-sorted by id below
		if String(def.core_axis) == "" and is_offerable(def, ctx):
			(by_rar[clampi(int(def.rarity), 0, 3)] as Array).append(def)
	var total := 0
	for r in 4:
		if not (by_rar[r] as Array).is_empty():
			total += int(weights[r])
	if total <= 0:
		return null
	var roll := rng.next_int(total)
	var rarity := 0
	for r in 4:
		if (by_rar[r] as Array).is_empty():
			continue
		if roll < int(weights[r]):
			rarity = r
			break
		roll -= int(weights[r])
	var cands: Array = by_rar[rarity]
	cands.sort_custom(func(a, b): return String(a.id) < String(b.id))
	var ws: Array = []
	var wtotal := 0
	for d in cands:
		var w := relic_weight(d, ctx, lean, lead)
		ws.append(w)
		wtotal += w
	var pick := rng.next_int(wtotal)
	for i in cands.size():
		if pick < int(ws[i]):
			return cands[i]
		pick -= int(ws[i])
	return cands[cands.size() - 1]


## Boss Pact screen (§4.4): one pact from each drawback group that still has one (reroll, dice,
## mana), uniform inside the group (weight 4, or 1 when its multiplier slot is full), then topped
## up from the same groups to `pact_offer_size` distinct pacts. Fewer valid pacts -> fewer cards.
static func pick_pact_offer(rng: Rng, ctx: Dictionary) -> Array:
	var t := RelicSlots.tuning()
	var groups: Dictionary = {}
	for g in t.pact_groups:
		groups[String(g)] = []
	for def in RelicRegistry.all_defs_sorted():
		if is_offerable(def, ctx, true) and groups.has(String(def.pact_group)):
			(groups[String(def.pact_group)] as Array).append(def)
	for g in groups:
		(groups[g] as Array).sort_custom(func(a, b): return String(a.id) < String(b.id))
	var out: Array = []
	for g in t.pact_groups:
		if out.size() >= t.pact_offer_size:
			break
		var pick = _pick_pact_from(rng, groups[String(g)], ctx, out)
		if pick != null:
			out.append(pick)
	var guard := 0
	while out.size() < t.pact_offer_size and guard < 16:
		guard += 1
		var added := false
		for g in t.pact_groups:
			if out.size() >= t.pact_offer_size:
				break
			var pick2 = _pick_pact_from(rng, groups[String(g)], ctx, out)
			if pick2 != null:
				out.append(pick2)
				added = true
		if not added:
			break
	return out


## Aid R5 (swap one Pact card): one replacement for `replaced_id`. Never one of `keep_ids` (the other cards on
## screen) and never the replaced card. Same drawback group when it still has a candidate, else any group
## (groups in `pact_groups` order). null when nothing else is eligible. One draw from `rng` per attempt.
static func pick_pact_replacement(rng: Rng, ctx: Dictionary, keep_ids: Array, replaced_id: String):
	var t := RelicSlots.tuning()
	var groups: Dictionary = {}
	for g in t.pact_groups:
		groups[String(g)] = []
	var replaced_group := ""
	for def in RelicRegistry.all_defs_sorted():
		if String(def.id) == replaced_id:
			replaced_group = String(def.pact_group)
		if String(def.id) == replaced_id or keep_ids.has(String(def.id)):
			continue
		if is_offerable(def, ctx, true) and groups.has(String(def.pact_group)):
			(groups[String(def.pact_group)] as Array).append(def)
	for g in groups:
		(groups[g] as Array).sort_custom(func(a, b): return String(a.id) < String(b.id))
	if groups.has(replaced_group):
		var same = _pick_pact_from(rng, groups[replaced_group], ctx, [])
		if same != null:
			return same
	for g in t.pact_groups:
		if String(g) == replaced_group:
			continue
		var other = _pick_pact_from(rng, groups[String(g)], ctx, [])
		if other != null:
			return other
	return null


static func _pick_pact_from(rng: Rng, group: Array, ctx: Dictionary, already: Array):
	var cands: Array = []
	var ws: Array = []
	var total := 0
	var owned: Array = ctx.get("owned_ids", [])
	var cap := RelicSlots.capacity(int(ctx.get("ascension", 0)), owned)
	for d in group:
		if already.has(d):
			continue
		var w := RelicSlots.tuning().pact_weight
		if String(d.mult_axis) != "":
			var cls_g: bool = String(d.mult_axis) == "G"
			var held := 0
			for id in owned:
				var d2 = RelicRegistry.get_def(String(id))
				if d2 != null and String(d2.mult_axis) != "" and (String(d2.mult_axis) == "G") == cls_g:
					held += 1
			if held >= int(cap["g"] if cls_g else cap["a"]):
				w = RelicSlots.tuning().m_floor
		cands.append(d)
		ws.append(w)
		total += w
	if cands.is_empty():
		return null
	var pick := rng.next_int(total)
	for i in cands.size():
		if pick < int(ws[i]):
			return cands[i]
		pick -= int(ws[i])
	return cands[cands.size() - 1]


## Shared by reward generation, event effects (RunState.apply_event_fx), and the shop —
## every place src/engine.js's relicPool()/pick() picked a random not-yet-owned relic.
## Simplification vs. src/engine.js relicConflict(): does NOT enforce RELIC_MLOAD_CAP,
## RELIC_CAP, or the ex/exSub keyword-conflict exclusion (rule spec §5) — those need the
## full per-relic mload/ex/exSub fields and a live party-die read that this vertical slice's
## RelicDef does not carry yet. Flagged as a scope reduction, not an oversight.
##
## `offer_ctx` (optional): when non-empty AND it carries a "source", the v2 offer system runs instead
## (rarity weights by source, lean tags, gating; see pick_offer_relic). Empty keeps the legacy
## uniform pick inside [min_rar, max_rar], so callers can migrate one at a time.
static func pick_relic(rng: Rng, exclude_ids: Array, min_rar: int, max_rar: int,
		offer_ctx: Dictionary = {}) -> RelicDef:
	if offer_ctx.has("source"):
		var c := offer_ctx.duplicate()
		c["offered_ids"] = (c.get("offered_ids", []) as Array) + exclude_ids   # owned + already on the table
		return pick_offer_relic(rng, String(c["source"]), c, bool(c.get("lead", false)))
	var pool: Array = []
	for def in RelicRegistry.offerable_defs_sorted():
		if exclude_ids.has(def.id) or String(def.core_axis) != "":   # Cores come only through CoreOffer
			continue
		if def.rarity < min_rar or def.rarity > max_rar:
			continue
		pool.append(def)
	if pool.is_empty():
		return null
	return pool[rng.next_int(pool.size())]


## src/data.js genShop() ported subset — 2 relics + Serum (heal) + Instinct (reroll), using
## the REAL src/data.js prices (RELIC_SHOP_COST / 40 / 110), not invented placeholder
## numbers. Simplified vs. the source (which also offers 2 Gene Mutation face items) since
## the face/mutation pool isn't ported yet (see file header).
static func generate_shop_items(rng: Rng, owned_relic_ids: Array, offer_ctx: Dictionary = {},
		relic_count: int = 2, core_item: bool = false) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	var offered: Array = []
	var shop_ctx: Dictionary = {}
	if not offer_ctx.is_empty():
		shop_ctx = offer_ctx.duplicate()
		shop_ctx["owned_ids"] = owned_relic_ids
		shop_ctx["source"] = "shop"
	for i in (0 if core_item else relic_count):   # Core flow: the shop no longer sells old relics (depth v3 2.8)
		var def: RelicDef
		if shop_ctx.is_empty():
			def = pick_relic(rng, owned_relic_ids + offered, 0, 3)
		else:
			shop_ctx["offered_ids"] = offered
			def = pick_offer_relic(rng, "shop", shop_ctx, false)
		if def == null:
			break
		offered.append(def.id)
		items.append({
			"kind": "relic", "key": def.id, "title": def.name,
			"desc": relic_desc(def),
			"rar": def.rarity, "cost": RELIC_SHOP_COST[mini(maxi(def.rarity, 0), 4)], "bought": false,
		})
	if core_item:   # depth v3 2.8: in-run shards buy one Moss Core pick (opens when the shop closes). No real money.
		items.append({
			"kind": "core", "tier": 0, "title": "Core Pick",
			"desc": "Choose 1 of 3 Moss Cores (after you leave the shop)",
			"cost": RelicSlots.tuning().core_shop_cost, "bought": false, "rar": 0,
		})
	items.append({
		"kind": "heal", "title": "Serum", "desc": "One Axie gains %d Max HP" % HEAL_ITEM_V,
		"cost": HEAL_ITEM_COST, "v": HEAL_ITEM_V, "bought": false, "rar": 0,
	})
	if shop_ctx.is_empty() or not twinfates_blocks_reroll(owned_relic_ids):   # twinfates: no Reroll sources
		items.append({
			"kind": "reroll", "title": "Instinct", "desc": "1 extra maximum Reroll",
			"cost": REROLL_ITEM_COST, "bought": false, "rar": 0,
		})
	return items


## runloop-ux-backlog P0-2: every choice card (reward/shop/treasure/event) should carry a
## rarity chip so a player scanning quickly can gauge a decision's "weight" without reading
## every line. Reward and shop-relic entries already carry a real `rar` (RelicDef.rarity /
## reward-type table above) — event options (`ContentDB.events[key].opts[i]`) do not, and
## ContentDB.gd is data owned by a different pass this task does not touch. This is a UI-only
## heuristic derived from each option's already-written fx risk/reward (no rule/balance
## change — a relabelled chip cannot alter what pressing the button does), so it lives here
## rather than pretending the data always had it. Unlisted fx -> 0 (Common), the safe default
## for anything added to ContentDB.gd later without updating this table.
const _EVENT_FX_RARITY := {
	# Lunacia Shrine
	"bless_reroll": 1, "gamble_legend": 4, "pray": 1,
	# Campfire
	"rest": 0, "forge": 2, "meditate": 0,
	# Ancient Crypt (event variant, distinct from the treasure-node reward flow)
	"chest": 3, "shards60": 1,
	# Mutant Casino
	"bet_small": 2, "bet_big": 4, "shards30": 0,
	# Mutagen Pool
	"dip": 2, "drink": 3, "leave": 0,
}


static func event_option_rarity(opt: Dictionary) -> int:
	return int(_EVENT_FX_RARITY.get(String(opt.get("fx", "")), 0))
