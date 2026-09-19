class_name CombatEngine
extends RefCounted
## Owns one combat encounter. NOT an autoload (architecture plan §4: "KHÔNG là autoload,
## để tránh lớp bug UID-desync mà JS gốc gặp phải bằng thiết kế") — `CombatView` creates a
## fresh instance per combat via `.new()` and either `setup_new()` (from RunState.pending_combat)
## or `from_data()` (restoring a save/undo/scene-reload snapshot).
##
## Ports engine.js's combat loop (startCombat/rollAll/resolveCantrips/doReroll/execFace/
## doFace/endTurn/tickStatus/checkEnd/finishCombat) onto an explicit 4-step turn FSM. See
## design/gdd/godot-port-rule-spec.md §2-§3 for the mechanics this must match exactly, and
## the architecture plan §4b/§5 for the undo/RNG decisions baked in here.
##
## DESIGN DECISION (not explicit in the rule spec or plan — flagged here): engine.js has NO
## real phase gate between "reroll" and "use a die" — both are freely interleavable any
## number of times during a turn; the rule spec's "4 bước" is a conceptual description, not
## an enforced state machine. To honor the architecture's explicit request for a
## ROLL/REROLL/EXECUTE/END_TURN enum while NOT changing that interleaving behavior (which
## would be an undocumented gameplay change), REROLL is treated as a transient marker:
## `reroll_dice()` flips phase to REROLL only for the duration of the reroll itself, then
## returns to EXECUTE, where `use_die()` remains legal the whole time. Reroll and die-use can
## still interleave freely, exactly like engine.js.

enum CombatPhase { ROLL, REROLL, EXECUTE, END_TURN }

## In-combat token ids (summoned allies, generated enemies) start far above any possible
## RunState persistent_id (which starts at 1 and grows by +1 per roster hero — see
## RunState._next_persistent_id) so the two id spaces can never collide by construction —
## this is the fix for the JS UID-desync bug class described in rule spec §4, not a patch.
const TOKEN_UID_BASE := 100000

## src/data.js GROWTH_KEEP_CAP — the per-face ceiling on growth carried between combats.
const GROWTH_KEEP_CAP := 3

const RESONANCE_MULT := 1.15
const RESONANCE_TYPES := ["dmg", "shield", "heal", "poison", "mana"]

const _EXCLUDE_EXACT_KW := ["aoe", "cantrip", "heavy", "echo", "selfkill", "plague", "bastion",
	"overflow", "cleave", "pierce", "lifesteal", "growth", "decay", "vital", "rerollup", "exec"]
const _EXCLUDE_PREFIX_KW := ["multi", "chain", "selfharm", "crit"]

var party: Array = []      # Array[Unit]
var enemies: Array = []    # Array[Unit]
var turn: int = 1
var phase: int = CombatPhase.EXECUTE

var mana: int = 0
var mana_spent: int = 0
var _cond_given: int = 0   ## AQUA CONDUIT payout watermark — see _grant_conduit_rerolls()
var rerolls: int = 0
var max_rerolls: int = 2
var used_actives: Array = []
var resonance_log: Array = []   # [{pos:int, t:String, used:bool}]
var last_big: Dictionary = {}   # {} or {v:int, f:Dictionary}
var first_used: bool = false
var stat: Dictionary = {"dmg": 0, "taken": 0, "turns": 0, "kills": 0, "max_hit": 0}

var relic_ids: Array = []
var node_id: String = ""
var kind: String = ""
var pw: int = 0
var ascension: int = 0
var combat_seed: int = 0

## Which boss this node fields, chosen once per run by RunState (never re-rolled in combat),
## and the run-wide CURSE PACT enemy modifiers. Both arrive through the combat setup so that
## a combat is still reconstructible from data alone (architecture plan §4).
var _boss_key: String = ""
var _run_mods: Dictionary = {"enemy_hp": 1.0, "enemy_dmg": 1.0}

var won: bool = false
var lost: bool = false
var result_shards_earned: int = 0

var undo_stack: Array = []

var _rng: Rng = null
var _next_token_uid: int = TOKEN_UID_BASE


# ===========================================================================
# Setup / snapshot round-trip
# ===========================================================================

## Builds a brand-new combat from RunState.pending_combat's CombatSetup shape:
## {node_id, kind, pw, ascension, roster_snapshot, relic_ids, combat_seed}. Never mutate
## `combat_setup` in place — RunState owns that Dictionary.
func setup_new(combat_setup: Dictionary) -> void:
	node_id = String(combat_setup.get("node_id", ""))
	kind = String(combat_setup.get("kind", "battle"))
	pw = int(combat_setup.get("pw", 0))
	ascension = int(combat_setup.get("ascension", 0))
	relic_ids = (combat_setup.get("relic_ids", []) as Array).duplicate()
	combat_seed = int(combat_setup.get("combat_seed", 0))
	_boss_key = String(combat_setup.get("boss_key", ""))
	_run_mods = (combat_setup.get("run_mods", {}) as Dictionary).duplicate()
	_rng = Rng.new(combat_seed)
	_next_token_uid = TOKEN_UID_BASE
	undo_stack = []
	won = false
	lost = false
	result_shards_earned = 0
	stat = {"dmg": 0, "taken": 0, "turns": 0, "kills": 0, "max_hit": 0}
	resonance_log = []
	last_big = {}
	first_used = false
	mana = 0
	mana_spent = 0
	_cond_given = 0
	used_actives = []

	var roster: Array = combat_setup.get("roster_snapshot", [])
	party = []
	for i in roster.size():
		party.append(_build_unit_from_roster(roster[i], i))

	# JS startCombat() spawns the `startSummon` relic's allies BEFORE generating the
	# encounter (engine.js:416-418), so they exist for anything that counts party size.
	var start_summons := int(RelicHooks.sum(self, "startSummon"))
	for i in start_summons:
		party.append(_mk_ally())
	if start_summons > 0:
		EventBus.relic_pulsed.emit("startSummon", 0)

	enemies = _generate_encounter(kind, pw)

	max_rerolls = 2 + int(combat_setup.get("bonus_reroll", 0)) + int(RelicHooks.sum(self, "rerollUp"))
	rerolls = max_rerolls

	for u in party:                                                    # SCALES passive
		if u.cls == "reptile":
			u.status["thorns"] = max(int(u.status.get("thorns", 0)), 2)

	# JS: `s.enemies.forEach(e => { if(e.permThorns) e.st.thorns = e.permThorns; })`
	# (engine.js:424). Without this the MECHA CHIMERA's RETALIATE trait — its entire
	# identity — is absent on turn 1 and only appears once bossTurnTraits() first runs.
	for e in enemies:
		var perm := int(e.custom_state.get("permanent_thorns", 0))
		if perm > 0:
			e.status["thorns"] = perm

	if bool(ContentDB.ascension_mods(ascension).get("weaken", false)):  # Ascension>=5
		var eligible: Array = []
		for u in party:
			if not u.is_token:
				eligible.append(u)
		if eligible.size() > 0:
			eligible[_rng.next_int(eligible.size())].status["weaken"] = 2

	turn = 1
	# JS startCombat() fires onTurnStart BEFORE the first rollAll (engine.js:426). Omitting it
	# made every on-turn-start relic silently skip turn 1 of every combat — the relic looked
	# implemented and was simply one turn late, forever.
	RelicHooks.fire(self, "on_turn_start", {"combat": self})
	_set_turn_phase(CombatPhase.ROLL)
	roll_all()
	_set_turn_phase(CombatPhase.EXECUTE)


## Restores a FULL CombatEngine snapshot in place (save/quit resume, undo, scene reload,
## DevReview jump). Snapshot-restore-in-place, not action-replay (architecture plan §4b) —
## `undo_last()` uses this same path.
func from_data(data: Dictionary) -> void:
	_apply_state_dict(data)
	undo_stack = (data.get("undo_stack", []) as Array).duplicate(true)


## Full, JSON-serializable snapshot: state + undo history. Used for scene-transition
## handoff, save/quit, and as the comparison object in tests/t_combat_roundtrip.gd.
func to_data() -> Dictionary:
	var d := _state_dict()
	d["undo_stack"] = undo_stack.duplicate(true)   # entries are already _state_dict()-shaped
	return d


func _state_dict() -> Dictionary:
	return {
		"party": _units_to_data(party),
		"enemies": _units_to_data(enemies),
		"turn": turn,
		"phase": phase,
		"mana": mana,
		"mana_spent": mana_spent,
		"rerolls": rerolls,
		"max_rerolls": max_rerolls,
		"used_actives": used_actives.duplicate(true),
		"resonance_log": _dup_dict_array(resonance_log),
		"last_big": last_big.duplicate(true),
		"first_used": first_used,
		"stat": stat.duplicate(true),
		"relic_ids": relic_ids.duplicate(),
		"node_id": node_id,
		"kind": kind,
		"pw": pw,
		"ascension": ascension,
		"combat_seed": combat_seed,
		"won": won,
		"lost": lost,
		"result_shards_earned": result_shards_earned,
		"rng_state": _rng.get_state() if _rng != null else 0,
		"next_token_uid": _next_token_uid,
	}


func _apply_state_dict(d: Dictionary) -> void:
	party = _units_from_data(d.get("party", []))
	enemies = _units_from_data(d.get("enemies", []))
	turn = int(d.get("turn", 1))
	phase = int(d.get("phase", CombatPhase.EXECUTE))
	mana = int(d.get("mana", 0))
	mana_spent = int(d.get("mana_spent", 0))
	rerolls = int(d.get("rerolls", 0))
	max_rerolls = int(d.get("max_rerolls", 2))
	used_actives = (d.get("used_actives", []) as Array).duplicate(true)
	resonance_log = _dup_dict_array(d.get("resonance_log", []))
	last_big = (d.get("last_big", {}) as Dictionary).duplicate(true)
	first_used = bool(d.get("first_used", false))
	stat = (d.get("stat", {}) as Dictionary).duplicate(true)
	relic_ids = (d.get("relic_ids", []) as Array).duplicate()
	node_id = String(d.get("node_id", ""))
	kind = String(d.get("kind", ""))
	pw = int(d.get("pw", 0))
	ascension = int(d.get("ascension", 0))
	combat_seed = int(d.get("combat_seed", 0))
	won = bool(d.get("won", false))
	lost = bool(d.get("lost", false))
	result_shards_earned = int(d.get("result_shards_earned", 0))
	_rng = Rng.new(int(d.get("rng_state", 0)))
	_next_token_uid = int(d.get("next_token_uid", TOKEN_UID_BASE))


func _units_to_data(arr: Array) -> Array:
	var out: Array = []
	for u in arr:
		out.append(u.to_data())
	return out

func _units_from_data(arr: Array) -> Array:
	var out: Array = []
	for d in arr:
		out.append(Unit.from_data(d))
	return out

static func _dup_dict_array(arr: Array) -> Array:
	var out: Array = []
	for e in arr:
		out.append((e as Dictionary).duplicate(true) if e is Dictionary else e)
	return out


## CombatResult half of the handoff back to RunState (architecture plan §4: "chỉ qua một
## hàm RunState.apply_combat_result(res)").
## `kind`/`pw` feed the reward-generation pass — src/engine.js finishCombat() needs exactly
## these two (plus s.step, which has no branching-RunMap equivalent, see rule spec §9 note)
## to pick a reward tier and rarity band.
func get_result() -> Dictionary:
	return {
		"won": won,
		"shards_earned": result_shards_earned if won else 0,
		"growth_keep": _compute_growth_keep(),
		"roster_updates": {},
		"kind": kind,
		"pw": pw,
	}


## src/engine.js finishCombat()'s ENG-3 block (engine.js:986-994) — the ONLY thing in the
## game that carries over between combats (HP, shield and status all reset; see rule spec §1).
##
## Keeps HALF the face growth earned this combat, per face, hard-capped at GROWTH_KEEP_CAP.
## The cap is load-bearing rather than decorative: this is the single cross-combat
## accumulator in the game, and uncapped it measures at ~1.6x the Legendary power ceiling.
##
## Returns {roster_index: {face_index: kept_growth}}, empty when no relic grants growthKeep.
## party[i] lines up with roster[i] because setup_new() builds the party by mapping the
## roster in order and pushes tokens only afterwards — the `is_token` guard makes that
## invariant explicit rather than relying on the ordering holding forever.
func _compute_growth_keep() -> Dictionary:
	if not won or not RelicHooks.has(self, "growthKeep"):
		return {}
	var out: Dictionary = {}
	for i in party.size():
		var u: Unit = party[i]
		if u.is_token or u.roster_index < 0:
			continue
		var per_face: Dictionary = {}
		for g in u.die.size():
			var earned := int(u.growth.get(g, 0))
			if earned > 0:
				per_face[g] = min(GROWTH_KEEP_CAP, int(floor(earned / 2.0)))
		if not per_face.is_empty():
			out[u.roster_index] = per_face
	return out


# ===========================================================================
# Query helpers
# ===========================================================================

func alive_party() -> Array:
	return party.filter(func(u): return u.hp > 0)

func alive_enemies() -> Array:
	return enemies.filter(func(u): return u.hp > 0)

## realP(s) — party members that are NOT tokens/allies. Only these count for the
## lose condition (rule spec §4/§8).
func real_party() -> Array:
	return party.filter(func(u): return not u.is_token)

func by_uid(uid: int) -> Unit:
	for u in party:
		if u.uid == uid:
			return u
	for u in enemies:
		if u.uid == uid:
			return u
	return null

func _any_real_party_alive() -> bool:
	for u in party:
		if not u.is_token and u.hp > 0:
			return true
	return false

func _count_alive_tokens(arr: Array) -> int:
	var n := 0
	for u in arr:
		if u.is_token and u.hp > 0:
			n += 1
	return n


# ===========================================================================
# Turn FSM
# ===========================================================================

func _set_turn_phase(new_phase: int) -> void:
	var old := phase
	phase = new_phase
	EventBus.turn_phase_changed.emit(old, new_phase)


## ROLL — both sides roll simultaneously, cantrips auto-resolve. engine.js rollAll(s).
func roll_all() -> void:
	for u in party:
		if u.hp > 0:
			if u.frozen_next:
				u.frozen = true
				u.frozen_next = false
			_roll_unit(u)
		else:
			u.clear_roll()
	for e in enemies:
		if e.hp > 0:
			_roll_unit(e)
			_pick_enemy_intent(e)
		else:
			e.clear_roll()
			e.intent = {}
	_resolve_cantrips()
	RelicHooks.fire(self, "on_roll_end", {"combat": self})


func _roll_unit(u: Unit) -> void:
	var fi := _rng.next_int(6)
	var f: Dictionary = u.die[fi]
	u.heavy = _has_kw(f, "heavy")
	var cc := _crit_chance(u, f)
	var crit_now: bool = u.side == "p" and String(f.get("type", "")) == "dmg" and cc > 0.0 \
		and (_rng.next_float() * 100.0) < cc
	u.set_roll(fi, crit_now)


func _crit_chance(u: Unit, f: Dictionary) -> float:
	return float(_kw_val(f, "crit")) + RelicHooks.sum(self, "critBonus")


func _pick_enemy_intent(e: Unit) -> void:
	var fi := e.roll_face_index()
	var f: Dictionary = e.die[fi]
	var face_type := String(f.get("type", ""))
	var tgt_uid := -1
	if face_type in ["dmg", "poison", "debuff"]:
		var ps := alive_party()
		if ps.size() > 0:
			if e.role == "assassin":
				tgt_uid = _lowest_by(ps, func(u: Unit) -> float: return float(u.hp + u.shield)).uid
			elif e.role == "bruiser" and _rng.next_float() < 0.5:
				tgt_uid = _lowest_by(ps, func(u: Unit) -> float: return -float(u.hp + u.shield)).uid
			else:
				tgt_uid = ps[_rng.next_int(ps.size())].uid
	elif face_type in ["shield", "heal", "buff"]:
		var es := alive_enemies()
		if e.role == "healer" and es.size() > 0:
			tgt_uid = _lowest_by(es, func(u: Unit) -> float: return float(u.hp) / max(1.0, float(u.max_hp))).uid
		elif es.size() > 0:
			tgt_uid = es[_rng.next_int(es.size())].uid
		else:
			tgt_uid = e.uid
	e.intent = {"face_index": fi, "target_uid": tgt_uid}


## Returns the unit with the smallest `score`, breaking ties by ARRAY ORDER.
##
## This replaces three `sort_custom` calls. JS relies on Array.prototype.sort being stable
## (guaranteed since ES2019) so that equal-scoring targets resolve by array position and a
## replayed seed always attacks the same Axie. Godot's Array.sort_custom is an introsort and
## is NOT stable, so identical monsters in a fresh pack — the single most common case — could
## pick a different target than the JS original. That is a determinism break in a game whose
## entire RNG port exists to guarantee replayability, not a cosmetic difference.
func _lowest_by(units: Array, score: Callable) -> Unit:
	var best: Unit = units[0]
	var best_score: float = score.call(best)
	for i in range(1, units.size()):
		var u: Unit = units[i]
		var s_i: float = score.call(u)
		if s_i < best_score:          # strictly less — a tie keeps the earlier unit
			best = u
			best_score = s_i
	return best


func _resolve_cantrips() -> void:
	for u in alive_party().duplicate():
		var guard := 0
		while u.has_rolled() and not u.roll_used() and _has_kw(u.current_face(), "cantrip") and guard < 6:
			guard += 1
			_exec_face(u, u.uid)
			_roll_unit(u)


## REROLL — see the class-level DESIGN DECISION comment: this is a transient marker, not
## a blocking gate. engine.js doReroll(s, uids).
func reroll_dice(uids: Array) -> bool:
	if won or lost:
		return false
	if rerolls <= 0:
		return false
	var list: Array = []
	for raw_id in uids:
		var u := by_uid(int(raw_id))
		if u != null and u.side == "p" and u.hp > 0 and u.has_rolled() and not u.roll_used() \
				and not u.heavy and not u.frozen:
			list.append(u)
	if list.is_empty():
		return false
	_set_turn_phase(CombatPhase.REROLL)
	rerolls -= 1
	var keep_crit := RelicHooks.has(self, "critKeep")
	for raw_u in list:
		var u: Unit = raw_u
		var had_crit: bool = u.roll_crit_now()
		_roll_unit(u)
		# JS: `if(rhas(s,'critKeep')) u.critNow = u.critNow || had` (engine.js:496-500) — a
		# crit already showing on the die survives the reroll instead of being gambled away.
		if keep_crit and had_crit:
			u.set_crit_now(true)
	_resolve_cantrips()
	# JS clears the undo stack on reroll ONLY when the party lacks `safeReroll`
	# (engine.js:502). Clearing unconditionally quietly disabled that relic's whole point.
	if not RelicHooks.has(self, "safeReroll"):
		undo_stack = []
	_set_turn_phase(CombatPhase.EXECUTE)
	return true


## Plays a Lunacia active card for Mana. Port of src/engine.js playerUseRelic()
## (engine.js:810-874).
##
## Before this existed, Mana was a DEAD RESOURCE: mana faces generated it, `used_actives` was
## declared and reset every turn, and nothing could ever spend a point of it — which also
## meant the CONDUIT archetype (one of the game's four documented starter builds) had no win
## condition at all, and all 16 `a_*` relics were unportable.
##
## Returns false without spending anything if the card is unknown, unaffordable, already
## used up this turn, or given an illegal target. That last case matters: JS originally had
## no `else` on the kind dispatch, so an unrecognised kind still charged the mana and burned
## the turn's use while doing nothing.
func play_active(relic_id: String, target_uid: int = -1) -> bool:
	if won or lost:
		return false
	var def = RelicRegistry.get_def(relic_id)
	if def == null or int(def.act_cost) <= 0:
		return false
	var a: Dictionary = def.act if "act" in def else {}
	if a.is_empty():
		return false
	var cost := int(def.act_cost)
	if mana < cost:
		return false

	# ENG-16 — actReuse raises the PER-TURN use limit, and only for rarity <= 2 cards.
	# Actives reset every TURN (end_turn clears used_actives), not every combat, so mana is
	# the only real brake; every active card's costing assumes exactly that.
	var used_n := 0
	for x in used_actives:
		if String(x) == relic_id:
			used_n += 1
	var max_use: int = (max(1, int(RelicHooks.max_val(self, "actReuse", 1.0))) if int(def.rarity) <= 2 else 1)
	if used_n >= max_use:
		return false

	_push_undo()
	var tgt: Unit = (by_uid(target_uid) if target_uid >= 0 else null)
	var allies := alive_party()
	var src: Unit = (allies[0] if not allies.is_empty() else null)
	var v := int(a.get("v", 0))
	var ok := true

	match String(a.get("kind", "")):
		"heal":
			if tgt == null or tgt.side != "p" or tgt.hp <= 0:
				ok = false
			else:
				DamagePipeline.apply_heal(self, tgt, v)
		"dmg":
			if tgt == null or tgt.side != "e" or tgt.hp <= 0:
				ok = false
			else:
				# ENG-14: crit/exec come from the CARD's data. Hardcoding them false here is
				# the exact bug the JS original shipped — a card declaring crit never critted.
				DamagePipeline.resolve({"combat": self, "src": src, "tgt": tgt, "value": v,
					"pierce": bool(a.get("pierce", false)), "attack": true,
					"crit": bool(a.get("crit", false)), "exec": bool(a.get("exec", false)),
					"face_type": "dmg"})
		"ult":
			if tgt == null or tgt.side != "e" or tgt.hp <= 0:
				ok = false
			else:
				DamagePipeline.resolve({"combat": self, "src": src, "tgt": tgt, "value": v,
					"pierce": true, "attack": true, "crit": bool(a.get("crit", false)),
					"face_type": "dmg"})
				for t in alive_party():
					DamagePipeline.apply_shield(self, t, 10)
		"shieldall":
			for t in alive_party():
				DamagePipeline.apply_shield(self, t, v)
		"dmgall":
			for t in alive_enemies().duplicate():
				DamagePipeline.resolve({"combat": self, "src": src, "tgt": t, "value": v,
					"attack": true, "face_type": "dmg"})
		"poisonall":
			for t in alive_enemies().duplicate():
				StatusEngine.add_status(self, t, ["poison:%d" % v], src)
		"stun":
			if tgt == null or tgt.side != "e" or tgt.hp <= 0:
				ok = false
			else:
				StatusEngine.add_status(self, tgt, ["stun"], src)
		"reroll":
			rerolls += v
		"kw":
			# ENG-10 — mode 'min' raises a status to a floor and is idempotent; 'add' stacks.
			var parts := String(a.get("kw", "")).split(":")
			var kn := parts[0]
			var kv: int = (int(parts[1]) if parts.size() > 1 else 1)
			var scope_list: Array = (alive_enemies() if String(a.get("scope", "")) == "allEnemies"
				else alive_party())
			for t in scope_list.duplicate():
				if String(a.get("mode", "add")) == "min":
					var cur := int(t.status.get(kn, 0))
					if cur < kv:
						StatusEngine.add_status(self, t, ["%s:%d" % [kn, kv - cur]], src)
				else:
					StatusEngine.add_status(self, t, [String(a.get("kw", ""))], src)
		"grow":
			# ENG-11 — growth lands on the face each ally currently has ROLLED, and lasts the
			# whole combat.
			for raw_pu in alive_party():
				var pu: Unit = raw_pu
				var fi: int = pu.roll_face_index()
				if fi >= 0 and fi < pu.die.size() and int((pu.die[fi] as Dictionary).get("value", 0)) > 0:
					pu.growth[fi] = int(pu.growth.get(fi, 0)) + v
					EventBus.float_text.emit(pu.uid, "GROW +%d" % v, "buf", 0)
		"summon":
			# ENG-12 — same token cap and `used=true` as the summon face; a summoned egg does
			# not also get to act on the turn it arrives.
			var tcap := int(RelicHooks.max_val(self, "tokenCap", 4.0))
			for i in v:
				if _count_alive_tokens(party) < tcap:
					var al := _mk_ally()
					_roll_unit(al)
					al.mark_used()
					party.append(al)
					EventBus.unit_spawned.emit(al.uid)
			if src != null:
				EventBus.float_text.emit(src.uid, "SUMMON", "buf", 0)
		"shatter":
			# ENG-13 — strips shield and deals what it stripped, with a floor so the card is
			# not worth zero against an unshielded enemy.
			if tgt == null or tgt.side != "e" or tgt.hp <= 0:
				ok = false
			else:
				var sh := tgt.shield
				if sh > 0:
					tgt.shield = 0
					EventBus.float_text.emit(tgt.uid, "-%d" % sh, "shd", 0)
					EventBus.hp_changed.emit(tgt.uid, tgt.hp, tgt.max_hp, tgt.shield)
				DamagePipeline.resolve({"combat": self, "src": src, "tgt": tgt,
					"value": max(int(a.get("min", 0)), sh), "pierce": true, "attack": true,
					"face_type": "dmg"})
		_:
			ok = false

	if not ok:
		undo_stack.pop_back()
		return false

	mana -= cost
	mana_spent += cost
	used_actives.append(relic_id)
	_grant_conduit_rerolls()
	EventBus.relic_pulsed.emit(relic_id, (src.uid if src != null else 0))
	_check_end()
	return true


## AQUA CONDUIT class passive — every 4 Mana spent this combat grants +1 reroll charge, while
## at least one Aqua Axie lives. `_cond_given` tracks what has already been paid out so the
## grant is monotonic rather than re-awarded on every spend (JS `s._condGiven`).
func _grant_conduit_rerolls() -> void:
	var has_aqua := false
	for u in party:
		if u.cls == "aqua" and u.hp > 0:
			has_aqua = true
			break
	if not has_aqua:
		return
	var gained: int = int(floor(mana_spent / 4.0)) - _cond_given
	if gained > 0:
		rerolls += gained
		_cond_given += gained
		var allies := alive_party()
		if not allies.is_empty():
			EventBus.float_text.emit((allies[0] as Unit).uid, "+%d REROLL" % gained, "buf", 0)


## EXECUTE — click-click / drag-drop both call this single entry point (architecture
## plan §3: "Input click-click và drag-drop cùng gọi API execute() duy nhất").
## engine.js playerUseDie(s,uid,tgtUid).
func use_die(unit_uid: int, target_uid: int) -> bool:
	if won or lost:
		return false
	if phase != CombatPhase.EXECUTE:
		return false
	var u := by_uid(unit_uid)
	if u == null or u.side != "p" or u.hp <= 0 or not u.has_rolled() or u.roll_used():
		return false
	_push_undo()
	if not _exec_face(u, target_uid):
		undo_stack.pop_back()
		return false
	_check_end()
	return true


func _push_undo() -> void:
	undo_stack.append(_state_dict())
	if undo_stack.size() > 90:
		undo_stack.pop_front()


## Free undo within a turn, until reroll or a new turn clears the stack (rule spec §2).
## Snapshot-restore-in-place (architecture plan §4b) — NOT action-replay.
func undo_last() -> bool:
	if undo_stack.is_empty():
		return false
	var snap: Dictionary = undo_stack.pop_back()
	_apply_state_dict(snap)
	return true


func _exec_face(u: Unit, target_uid: int) -> bool:
	var fi := u.roll_face_index()
	if fi < 0 or u.roll_used():
		return false
	var f: Dictionary = u.die[fi]
	if String(f.get("type", "")) == "blank":
		return false

	var res_idx := _find_resonance_idx(u, f)
	var is_resonant := res_idx >= 0
	u.resonant_now = is_resonant
	if is_resonant:
		EventBus.float_text.emit(u.uid, "LINK x%.2f" % RESONANCE_MULT, "buf", 0)

	var reps := 2 if _has_kw(f, "echo") else 1
	# JS: `if(u.side==='p' && rhas(s,'firstEcho') && !s._firstUsed) reps = max(reps, 2)`
	# (engine.js:716). `first_used` was already being tracked here but never consulted, so
	# the firstEcho relic had no effect at all.
	if u.side == "p" and not first_used and RelicHooks.has(self, "firstEcho"):
		reps = max(reps, 2)
	EventBus.face_used.emit(u.uid, u.side, target_uid,
		_has_kw(f, "aoe") or f.get("type", "") == "mana" or f.get("type", "") == "summon",
		String(f.get("part", "")), String(f.get("name", "")), String(f.get("type", "")))

	var ok := _do_face(u, target_uid, f, fi, false)
	if not ok:
		u.resonant_now = false
		return false
	if u.side == "p":
		first_used = true
	for i in range(1, reps):
		_do_face(u, target_uid, f, fi, true)

	u.mark_used()
	if is_resonant:
		resonance_log[res_idx]["used"] = true
	_log_resonance_attempt(u, f, is_resonant)
	if is_resonant:
		EventBus.resonance_triggered.emit(u.uid)
	if u.side == "p" and u.roll_crit_now():
		u.set_crit_now(false)
	u.resonant_now = false
	return true


func _find_resonance_idx(u: Unit, f: Dictionary) -> int:
	if u.side != "p" or u.is_token:
		return -1
	if not RESONANCE_TYPES.has(String(f.get("type", ""))):
		return -1
	var pos := u.roster_index
	if pos < 0:
		return -1
	for i in resonance_log.size():
		var e: Dictionary = resonance_log[i]
		if not bool(e.get("used", false)) and String(e.get("t", "")) == String(f.get("type", "")) \
				and abs(int(e.get("pos", -999)) - pos) == 1:
			return i
	return -1

func _log_resonance_attempt(u: Unit, f: Dictionary, was_consumer: bool) -> void:
	if u.side != "p" or u.is_token or was_consumer:
		return
	if not RESONANCE_TYPES.has(String(f.get("type", ""))):
		return
	var pos := u.roster_index
	if pos < 0:
		return
	resonance_log.append({"pos": pos, "t": String(f.get("type", "")), "used": false})


func _face_value(u: Unit, fi: int) -> int:
	var f: Dictionary = u.die[fi]
	var v: float = float(f.get("value", 0)) + float(u.get_growth(fi))
	if _has_kw(f, "vital") and u.hp == u.max_hp:
		v *= 2.0
	var face_type := String(f.get("type", ""))
	if face_type == "dmg":
		if int(u.status.get("blind", 0)) > 0:
			return 0
		if int(u.status.get("weaken", 0)) > 0:
			v = max(0.0, v - int(u.status["weaken"]))
		if u.overdrive:
			v = ceil(v * 1.5)
		if u.side == "p" and RelicHooks.has(self, "hiveMind"):
			v += RelicHooks.sum(self, "hiveMind") * _count_alive_tokens(party)
	if face_type == "mana" and u.side == "p" and u.cls == "aqua":
		v += 1.0                                                        # CONDUIT passive
	if u.side == "p" and u.resonant_now:
		v = ceil(v * RESONANCE_MULT)
	return int(v)


func _pure_keywords(f: Dictionary) -> Array:
	var out: Array = []
	for k in (f.get("keywords", []) as Array):
		var ks := String(k)
		var base := ks.split(":")[0]
		if _EXCLUDE_EXACT_KW.has(base) or _EXCLUDE_PREFIX_KW.has(base):
			continue
		out.append(ks)
	return out


func _do_face(u: Unit, target_uid: int, f: Dictionary, fi: int, is_echo: bool) -> bool:
	var foes := (alive_enemies() if u.side == "p" else alive_party())
	var friends := (alive_party() if u.side == "p" else alive_enemies())
	var v := _face_value(u, fi)
	var tgt: Unit = (by_uid(target_uid) if target_uid >= 0 else null)
	var crit := u.roll_crit_now()
	var kw_pure := _pure_keywords(f)
	var face_type := String(f.get("type", ""))

	var hit := func(t: Unit, amount: int) -> int:
		var pierce: bool = _has_kw(f, "pierce") or (u.side == "p" and u.cls == "bird" and _has_kw(f, "aoe"))
		var d: int = DamagePipeline.resolve({
			"combat": self, "src": u, "tgt": t, "value": amount, "pierce": pierce, "attack": true,
			"crit": crit, "exec": _has_kw(f, "exec"), "face_type": "dmg", "resonant": u.resonant_now,
		})
		if _has_kw(f, "lifesteal") and d > 0:
			DamagePipeline.apply_heal(self, u, d)
		if kw_pure.size() > 0 and d >= 0:
			StatusEngine.add_status(self, t, kw_pure, u)
		return d

	if face_type == "dmg":
		if _has_kw(f, "aoe"):
			for t in foes.duplicate():
				hit.call(t, v)
		else:
			var chain := int(_kw_val(f, "chain"))
			if chain > 0:
				for i in chain:
					var l := (alive_enemies() if u.side == "p" else alive_party())
					if l.is_empty():
						break
					hit.call(l[_rng.next_int(l.size())], v)
			else:
				if tgt == null or tgt.hp <= 0 or tgt.side == u.side:
					return false
				var mult: int = int(_kw_val(f, "multi"))
				if mult <= 0:
					mult = 1
				for i in mult:
					if tgt.hp > 0 or i == 0:
						hit.call(tgt, v)
				if _has_kw(f, "cleave"):
					for t in _neighbors_of(foes, tgt):
						hit.call(t, int(ceil(v * RelicHooks.max_val(self, "cleaveRatio", 0.5))))
		if _has_kw(f, "selfkill"):
			u.hp = 0
			EventBus.float_text.emit(u.uid, "BOOM", "dmg", 1)

	elif face_type == "poison":
		var mult2: int = int(_kw_val(f, "multi"))
		if mult2 <= 0:
			mult2 = 1
		var p: Array = []
		for i in mult2:
			p.append("poison:%d" % v)
		if _has_kw(f, "aoe"):
			for t in foes.duplicate():
				StatusEngine.add_status(self, t, p, u)
		else:
			if tgt == null or tgt.hp <= 0 or tgt.side == u.side:
				return false
			StatusEngine.add_status(self, tgt, p, u)
		if _has_kw(f, "pierce"):
			var targets: Array = (foes if _has_kw(f, "aoe") else ([tgt] if tgt != null else []))
			for t in targets:
				DamagePipeline.resolve({"combat": self, "src": u, "tgt": t, "value": v, "pierce": true, "attack": false})

	elif face_type == "debuff":
		if _has_kw(f, "aoe"):
			for t in foes.duplicate():
				StatusEngine.add_status(self, t, kw_pure, u)
		else:
			if tgt == null or tgt.hp <= 0 or tgt.side == u.side:
				return false
			StatusEngine.add_status(self, tgt, kw_pure, u)

	elif face_type == "shield":
		var do_sh := func(t: Unit) -> void:
			DamagePipeline.apply_shield(self, t, v)
			if kw_pure.size() > 0:
				StatusEngine.add_status(self, t, kw_pure, u)
			if _has_kw(f, "bastion"):
				var es := (alive_enemies() if u.side == "p" else alive_party())
				if es.size() > 0:
					DamagePipeline.resolve({"combat": self, "src": u, "tgt": es[_rng.next_int(es.size())], "value": v, "attack": false})
		if _has_kw(f, "aoe"):
			for t in friends.duplicate():
				do_sh.call(t)
		else:
			if tgt == null or tgt.hp <= 0 or tgt.side != u.side:
				return false
			do_sh.call(tgt)

	elif face_type == "heal":
		if _has_kw(f, "aoe"):
			for t in friends.duplicate():
				DamagePipeline.apply_heal(self, t, v)
				if kw_pure.size() > 0:
					StatusEngine.add_status(self, t, kw_pure, u)
		else:
			if tgt == null or tgt.hp <= 0 or tgt.side != u.side:
				return false
			DamagePipeline.apply_heal(self, tgt, v)
			if kw_pure.size() > 0:
				StatusEngine.add_status(self, tgt, kw_pure, u)

	elif face_type == "buff":
		if _has_kw(f, "aoe"):
			for t in friends.duplicate():
				StatusEngine.add_status(self, t, kw_pure, u)
		else:
			if tgt == null or tgt.hp <= 0 or tgt.side != u.side:
				return false
			StatusEngine.add_status(self, tgt, kw_pure, u)

	elif face_type == "mana":
		if u.side == "p":
			mana += v
			EventBus.float_text.emit(u.uid, "+%d MP" % v, "man", 0)

	elif face_type == "summon":
		if u.side == "p":
			var tcap: int = int(RelicHooks.max_val(self, "tokenCap", 4.0))
			for i in v:
				if _count_alive_tokens(party) < tcap:
					var a := _mk_ally()
					_roll_unit(a)
					a.mark_used()
					party.append(a)
					EventBus.unit_spawned.emit(a.uid)
			EventBus.float_text.emit(u.uid, "SUMMON", "buf", 0)
		else:
			for i in v:
				if enemies.size() < 7:
					var m := _mk_monster(String(u.custom_state.get("summons", "slime")),
						float(u.custom_state.get("sc", 1.0)) * 0.7, {"hp": 1.0, "dmg": 1.0})
					_roll_unit(m)
					_pick_enemy_intent(m)
					enemies.append(m)
					EventBus.unit_spawned.emit(m.uid)

	if not is_echo:
		var sh: int = int(_kw_val(f, "selfharm"))
		if sh > 0:
			DamagePipeline.resolve({"combat": self, "src": null, "tgt": u, "value": sh, "pierce": true})
		var mn: int = int(_kw_val(f, "mana"))
		if mn > 0 and u.side == "p":
			mana += mn
		if _has_kw(f, "rerollup") and u.side == "p":
			rerolls += 1
		if _has_kw(f, "growth"):
			u.add_growth(fi, 1 + int(RelicHooks.sum(self, "growthPlus")))
		if _has_kw(f, "decay"):
			u.add_growth(fi, -1)
		if u.side == "p" and face_type == "dmg" and v > 0:
			if last_big.is_empty() or v > int(last_big.get("v", 0)):
				last_big = {"v": v, "f": (f as Dictionary).duplicate(true)}
	return true


func _neighbors_of(arr: Array, t: Unit) -> Array:
	var i := arr.find(t)
	var out: Array = []
	if i > 0:
		out.append(arr[i - 1])
	if i >= 0 and i < arr.size() - 1:
		out.append(arr[i + 1])
	return out


# ===========================================================================
# END_TURN
# ===========================================================================

func end_turn() -> void:
	if won or lost:
		return
	if phase == CombatPhase.END_TURN:
		return
	_set_turn_phase(CombatPhase.END_TURN)
	undo_stack = []
	first_used = false

	# mana overflow (relic OR mythic `overflow` face) — no-op today: no relic and no
	# ported tier-1 face carries `overflow`. Kept so wiring either in later is content-only.
	if mana > 0 and (RelicHooks.has(self, "manaOverflow") or _any_die_has_keyword(party, "overflow")):
		var v := mana
		var src: Unit = (alive_party()[0] if alive_party().size() > 0 else null)
		for t in alive_enemies().duplicate():
			DamagePipeline.resolve({"combat": self, "src": src, "tgt": t, "value": v, "attack": false})
		EventBus.float_text.emit((src.uid if src != null else 0), "OVERFLOW %d" % v, "man", 1)
		mana = 0

	for e in enemies:
		if e.hp <= 0 or e.intent.is_empty():
			continue
		EventBus.enemy_intent_executed.emit(e.uid)
		if int(e.status.get("stun", 0)) > 0:
			e.status["stun"] = 0
			EventBus.float_text.emit(e.uid, "STUNNED", "deb", 0)
			continue
		_exec_face(e, int(e.intent.get("target_uid", -1)))
		if not _any_real_party_alive():
			break

	StatusEngine.tick_status(self)   # emits EventBus.status_tick once, at the end (see status_engine.gd)
	if _check_end():
		return

	turn += 1
	stat["turns"] = int(stat.get("turns", 0)) + 1
	rerolls = max_rerolls
	used_actives = []
	resonance_log = []
	for u in party:
		if u.frozen:
			u.frozen = false
	RelicHooks.fire(self, "on_turn_start", {"combat": self})
	_boss_turn_traits()
	_set_turn_phase(CombatPhase.ROLL)
	roll_all()
	_apply_growth_all()
	_check_end()
	_set_turn_phase(CombatPhase.EXECUTE)


## src/engine.js endTurn()'s growthAll pass (engine.js:929-938, spec G1/ENG-18).
##
## Plain `growth` only ever grows the ONE face just used, so over a ~5-turn combat it is worth
## almost nothing and the EVOLVE archetype had no payoff. growthAll grows EVERY value-bearing
## face of every living non-token party member each turn. The `!token` guard is load-bearing,
## not tidiness: tokens never pass through _build_unit_from_roster, so their `growth` is not
## persisted and growing it would be a silent no-op that looks like it worked.
func _apply_growth_all() -> void:
	var ga := 0
	for def in RelicHooks.owned_defs(self):
		var amount := int(def.growthAll) if "growthAll" in def else 0
		if amount == 0:
			continue
		# JS keeps the per-turn guard inside the relic body (growthAllGuard), not in the
		# spec — a relic with no guard always fires, which is what call_hook's default returns.
		var hk: String = def.hook_key if "hook_key" in def else ""
		if not bool(RelicHooks.call_hook(hk, "growth_all_guard", {"combat": self})):
			continue
		ga += amount
	if ga == 0:
		return
	for p in party:
		if p.hp <= 0 or p.is_token:
			continue
		for i in p.die.size():
			if int((p.die[i] as Dictionary).get("value", 0)) > 0:
				p.growth[i] = int(p.growth.get(i, 0)) + ga
		EventBus.float_text.emit(p.uid, "GROW +%d" % ga, "buf", 0)
		EventBus.relic_pulsed.emit("growthAll", p.uid)


func _any_die_has_keyword(units: Array, kw: String) -> bool:
	for u in units:
		for f in u.die:
			if (f.get("keywords", []) as Array).has(kw):
				return true
	return false


## Port of src/engine.js bossTurnTraits() (engine.js:889-902), run once at the start of every
## turn after the first. Previously this incremented a counter and cleared `overdrive` and did
## nothing else, which meant five of the six bosses were stat-sticks with a description that
## advertised a mechanic they did not have.
func _boss_turn_traits() -> void:
	for b in alive_enemies():
		if not b.is_boss:
			continue
		b.custom_state["turn_count"] = int(b.custom_state.get("turn_count", 0)) + 1
		b.overdrive = false
		var turn_count := int(b.custom_state["turn_count"])
		var add_cap := int(b.custom_state.get("add_cap", 0))

		match String(b.custom_state.get("trait", "")):
			# MECHA CHIMERA — RETALIATE: thorns never wear off, and every 3rd turn it enters
			# OVERDRIVE (+50% damage, read by _face_value()).
			"thorns":
				var perm := int(b.custom_state.get("permanent_thorns", 0))
				b.status["thorns"] = max(int(b.status.get("thorns", 0)), perm)
				if turn_count % 3 == 0:
					b.overdrive = true
					EventBus.float_text.emit(b.uid, "OVERDRIVE", "deb", 1)

			# PLAGUE MOTHER — BROOD: one add every 3 turns, up to addCap.
			"summon":
				if turn_count % 3 == 0 and int(b.custom_state.get("split_done", 0)) < add_cap:
					b.custom_state["split_done"] = int(b.custom_state.get("split_done", 0)) + 1
					spawn_boss_add(b, float(b.custom_state.get("sc", 1.0)))

			# FROST LORD — DEEP FREEZE: locks one un-frozen, non-token Axie's die out of the
			# reroll pool. Note it sets `frozen` directly, NOT `frozen_next`: the constraint
			# applies to the turn that is starting right now.
			"freeze":
				var candidates: Array = []
				for u in alive_party():
					if not u.frozen and not u.is_token:
						candidates.append(u)
				if not candidates.is_empty():
					var t: Unit = candidates[_rng.next_int(candidates.size())]
					t.frozen = true
					EventBus.float_text.emit(t.uid, "FROZEN", "deb", 0)

			# MIRROR CHIMERA — copies the strongest face the player used last turn into its
			# own slot 0 at x1.1, never weakening what was already there.
			"mirror":
				if not last_big.is_empty() and not b.die.is_empty():
					var mirrored: Dictionary = (last_big.get("f", {}) as Dictionary).duplicate(true)
					if not mirrored.is_empty():
						mirrored["value"] = max(int(b.die[0].get("value", 0)),
							int(ceil(float(last_big.get("v", 0)) * 1.1)))
						b.die[0] = mirrored


func _check_end() -> bool:
	if alive_enemies().is_empty():
		won = true
		_finish_combat()
		return true
	if not _any_real_party_alive():
		lost = true
		EventBus.combat_finished.emit(false)
		return true
	return false


func _finish_combat() -> void:
	result_shards_earned = 90 if kind == "boss" else (45 if kind == "elite" else 25)
	EventBus.combat_finished.emit(true)


# ===========================================================================
# Unit construction
# ===========================================================================

func _build_unit_from_roster(entry: Dictionary, index: int) -> Unit:
	var hero_key := String(entry.get("hero_key", ""))
	var hero_def: Dictionary = ContentDB.heroes.get(hero_key, {})
	var base_hp := int(entry.get("max_hp", 0))
	if base_hp <= 0:
		base_hp = int(hero_def.get("max_hp", 10))

	var u := Unit.new()
	u.uid = int(entry.get("persistent_id", 0))
	u.side = "p"
	u.key = hero_key
	u.n = String(hero_def.get("n", hero_key))
	u.cls = String(hero_def.get("cls", ""))
	u.tier = int(entry.get("tier", hero_def.get("tier", 1)))
	u.roster_index = index
	u.max_hp = base_hp + int(entry.get("bonus_hp", 0))
	u.die = (hero_def.get("die", []) as Array).duplicate(true)

	for m in (entry.get("muts", []) as Array):
		var mt := String(m.get("type", ""))
		if mt == "part":
			var idx := int(m.get("idx", -1))
			if idx >= 0 and idx < u.die.size():
				u.die[idx] = (m.get("face", {}) as Dictionary).duplicate(true)
		elif mt == "rune":
			var idx2 := int(m.get("idx", -1))
			if idx2 >= 0 and idx2 < u.die.size():
				var kws: Array = u.die[idx2]["keywords"]
				var kw := String(m.get("kw", ""))
				if not kws.has(kw):
					kws.append(kw)
				if int(u.die[idx2].get("rarity", 0)) < 1:
					u.die[idx2]["rarity"] = 1
		elif mt == "oc":
			var mult := float(m.get("mult", 1.5))
			for f in u.die:
				if int(f.get("value", 0)) > 0:
					f["value"] = int(ceil(int(f["value"]) * mult))

	# ENG-3 — growth persisted between combats by the growthKeep relic. Seeded BEFORE the
	# modFace pass, matching JS (engine.js buildUnit): growth is added to faceValue at use
	# time, not baked into f.v, so the two are order-independent — but keeping the same
	# order removes the question entirely.
	u.growth = (entry.get("growth", {}) as Dictionary).duplicate(true)

	# INV-5 build-time die mutation. This call site did not exist before the Phase-1 parity
	# pass, which is why 31 of the 94 relics (every relic that permanently rewrites a die
	# face) could not be ported at all — no amount of relic authoring would have worked
	# without it. Ordering is by relic DATA, never by pickup order; see
	# RelicHooks.mod_face_order().
	RelicHooks.apply_mod_faces(self, u)

	u.hp = u.max_hp
	return u


func _mk_ally() -> Unit:
	var m: Dictionary = ContentDB.egg_token
	var sc: float = max(1.0, ContentDB.budget(pw) / 14.0)
	var hp: int = max(4, int(round(float(m.get("hp", 6)) * sc * 0.55)))
	var a := Unit.new()
	a.uid = _alloc_token_uid()
	a.side = "p"
	a.is_token = true
	a.key = "egg"
	a.n = "Axie Egg"
	a.cls = "aqua"
	a.tier = 1
	a.max_hp = hp
	a.hp = hp
	a.die = ContentDB.scale_die(m.get("die", []), sc * 0.5)
	a.roster_index = -1
	# ENG-20 — tokens do NOT go through _build_unit_from_roster, so they never saw the
	# modFace pass. The `eggInherit` relic is what opens that door, and it pays for it with
	# mload 2 (rule spec §6.7.3). JS re-syncs hp when a modFace changed max_hp.
	if RelicHooks.has(self, "eggInherit"):
		var before := a.max_hp
		RelicHooks.apply_mod_faces(self, a)
		if a.max_hp != before:
			a.hp = a.max_hp
		EventBus.relic_pulsed.emit("eggInherit", a.uid)
	return a


func _mk_monster(key: String, sc: float, mods: Dictionary) -> Unit:
	var m: Dictionary = ContentDB.enemies.get(key, ContentDB.enemies.get("slime", {}))
	var hp: int = max(1, int(round(float(m.get("hp", 1)) * sc * float(mods.get("hp", 1.0)))))
	var u := Unit.new()
	u.uid = _alloc_token_uid()
	u.side = "e"
	u.key = key
	u.n = String(m.get("n", key))
	u.role = String(m.get("role", ""))
	u.is_token = bool(m.get("token", false))
	u.max_hp = hp
	u.hp = hp
	u.die = ContentDB.scale_die(m.get("die", []), sc * float(mods.get("dmg", 1.0)))
	u.custom_state["sc"] = sc
	return u


func _alloc_token_uid() -> int:
	var id := _next_token_uid
	_next_token_uid += 1
	return id


## Faithful port of src/engine.js genEncounter() (engine.js:336-351).
##
## Three things this replaces, all of which were stubs that shipped as if they were features:
##  - boss nodes returned three scaled SLIMES, so no boss ever entered play and every
##    `is_boss` code path downstream (2-phase, SPLIT, OVERDRIVE, FREEZE, MIRROR) was dead;
##  - every battle/elite drew the literal key "slime", so the six other ported monsters were
##    unreachable data and an elite differed from a battle only by a budget multiplier;
##  - the ascension `hp` modifier was applied TWICE (once into the budget that drives `sc`,
##    which scales HP *and* the die, then again per-monster), so A10 enemies came out at
##    ~2.11x HP instead of the intended 1.452x. JS multiplies the budget by the CURSE
##    modifier (`s.runMods.enemyHp`) only; `mods.hp` belongs to mkMonster alone.
func _generate_encounter(p_kind: String, p_pw: int) -> Array:
	var amods := ContentDB.ascension_mods(ascension)

	if p_kind == "boss":
		return [_mk_boss(_boss_key_for_this_node(), p_pw, amods)]

	var is_elite := p_kind == "elite"
	# JS: budget = CURVE.budget(pw) * eliteMult * s.runMods.enemyHp — the CURSE modifier,
	# NOT the ascension one. See the double-count note above.
	var budget_v: float = ContentDB.budget(p_pw) \
		* (float(ContentDB.TUNE["elite_mult"]) if is_elite else 1.0) \
		* _run_mod("enemy_hp")
	# JS `mods.eliteExtra` is 1 from Ascension 2 up. ContentDB.ascension_mods() historically
	# omitted the field (it only ported the in-combat ones), so the JS rule is the fallback
	# here rather than a silent 0 — that omission is what made A2 a no-op before.
	var elite_extra: int = int(amods.get("elite_extra", 1 if ascension >= 2 else 0))
	var n: int = ContentDB.count(p_pw) + (elite_extra if is_elite else 0)

	var keys: Array = []
	if is_elite:
		var elite_pool: Array = _elite_pool()
		if not elite_pool.is_empty():
			keys.append(String(elite_pool[_rng.next_int(elite_pool.size())]))

	# JS: NORMAL_POOL filtered by `p.min <= pw+1`, sorted by cost DESC, then picked from the
	# strongest ~70% — so the roster of possible monsters shifts upward as the run progresses.
	var avail := _available_normal_keys(p_pw)
	if avail.is_empty():
		avail = ["slime"]
	var pick_range: int = max(1, int(ceil(avail.size() * 0.7)))
	while keys.size() < n:
		keys.append(String(avail[_rng.next_int(pick_range)]))

	var tot := 0.0
	for k in keys:
		tot += float((ContentDB.enemies.get(k, {}) as Dictionary).get("cost", 1))
	var sc: float = clamp(budget_v / max(tot, 1.0), 0.55, 3.4)
	var em := {"hp": amods.get("hp", 1.0), "dmg": float(amods.get("dmg", 1.0)) * _run_mod("enemy_dmg")}

	var out: Array = []
	for k in keys:
		out.append(_mk_monster(String(k), sc, em))
	return out


## Run-wide enemy modifier from the CURSE PACT reward (JS `s.runMods.enemyHp/enemyDmg`,
## engine.js:340/349/1184). Supplied by RunState through the combat setup; defaults to 1.0 so
## a caller that doesn't know about curses still gets JS-identical numbers.
func _run_mod(key: String) -> float:
	return float(_run_mods.get(key, 1.0))


## NORMAL_POOL keys legal at this power level, sorted by monster cost DESCENDING.
##
## The sort MUST be stable: JS relies on Array.prototype.sort being stable (ES2019+) so that
## equal-cost monsters keep their NORMAL_POOL declaration order, and the index-based pick
## below then draws the same key JS would. Godot's Array.sort_custom is an introsort and is
## NOT stable, so ties are broken explicitly by pool index here instead.
func _available_normal_keys(p_pw: int) -> Array:
	var pool: Array = _normal_pool()
	var decorated: Array = []
	for i in pool.size():
		var entry: Dictionary = pool[i]
		if int(entry.get("min", 1)) <= p_pw + 1:
			var key := String(entry.get("k", ""))
			decorated.append({
				"k": key,
				"cost": int((ContentDB.enemies.get(key, {}) as Dictionary).get("cost", 0)),
				"i": i,
			})
	decorated.sort_custom(func(a, b):
		if int(a["cost"]) != int(b["cost"]):
			return int(a["cost"]) > int(b["cost"])
		return int(a["i"]) < int(b["i"]))
	var out: Array = []
	for d in decorated:
		out.append(String(d["k"]))
	return out


## NORMAL_POOL / ELITE_POOL live in ContentDB. Both are read through a guard rather than
## indexed directly: if the content pass that adds them has not landed, the encounter falls
## back to the old slime-only behaviour with a loud warning instead of crashing a live run.
func _normal_pool() -> Array:
	if "normal_pool" in ContentDB:
		var p: Array = ContentDB.get("normal_pool")
		if not p.is_empty():
			return p
	push_warning("CombatEngine: ContentDB.normal_pool missing — falling back to slime-only encounters")
	return [{"k": "slime", "min": 1}]


func _elite_pool() -> Array:
	if "elite_pool" in ContentDB:
		return ContentDB.get("elite_pool") as Array
	return []


## Which boss stands at this boss node. RunState picks the whole run's boss line-up once at
## start_new_run() (JS newGame(), engine.js:359-363: BOSS_ORDER_12/20, mid bosses 50% swapped
## for a BOSS_ALT pick, final boss always 'agony') and hands the chosen key down through the
## combat setup, so combat never re-rolls it and a replayed seed meets the same bosses.
func _boss_key_for_this_node() -> String:
	if _boss_key != "" and ContentDB.bosses.has(_boss_key):
		return _boss_key
	# JS's own fallback is the same: `s.bossPlan[...] || 'agony'` (engine.js:338).
	return "agony"


## Port of src/engine.js mkBoss() (engine.js:325-335). ContentDB.boss_stats() already does the
## hpk/dmgk-against-budget maths; the two fields it does not compute — `permThorns` and the
## `sc` used when the boss spawns adds — are derived here from the same budget.
func _mk_boss(boss_key: String, p_pw: int, amods: Dictionary) -> Unit:
	var stats := ContentDB.boss_stats(boss_key, p_pw, amods)
	if stats.is_empty():
		push_error("CombatEngine: no boss data for '%s' — falling back to a slime pack" % boss_key)
		return _mk_monster("slime", 1.0, {"hp": 1.0, "dmg": 1.0})

	var bud := ContentDB.budget(p_pw)
	var trait_name := String(stats.get("trait", ""))

	var u := Unit.new()
	u.uid = _alloc_token_uid()
	u.side = "e"
	u.key = boss_key
	u.n = String(stats.get("n", boss_key))
	u.role = "boss"
	u.is_boss = true
	u.max_hp = int(stats.get("max_hp", 1))
	u.hp = u.max_hp
	u.die = (stats.get("die", []) as Array).duplicate(true)

	u.custom_state["trait"] = trait_name
	u.custom_state["phase"] = 1
	u.custom_state["adds"] = (stats.get("adds", []) as Array).duplicate()
	u.custom_state["add_cap"] = int(stats.get("add_cap", 0))
	u.custom_state["split_done"] = 0
	u.custom_state["turn_count"] = 0
	# JS: permThorns = trait==='thorns' ? max(2, round(0.09*B)) : 0
	u.custom_state["permanent_thorns"] = (max(2, int(round(0.09 * bud))) if trait_name == "thorns" else 0)
	# JS: sc = max(0.7, B/45) — the scale a boss's summoned adds are built at.
	u.custom_state["sc"] = max(0.7, bud / 45.0)
	if (stats.get("die2", []) as Array).size() > 0:
		u.custom_state["max_hp2"] = int(stats.get("max_hp2", u.max_hp))
		u.custom_state["die2"] = (stats.get("die2", []) as Array).duplicate(true)
	return u


## Spawns one boss add mid-combat (SPLIT / BROOD), rolled and with its intent already picked
## so it acts on the turn it appears — exactly as JS does inline in checkBossPhase() and
## bossTurnTraits() (engine.js:884-886, 895-897).
func spawn_boss_add(b: Unit, scale: float) -> void:
	var adds: Array = b.custom_state.get("adds", [])
	if adds.is_empty():
		return
	var m := _mk_monster(String(adds[_rng.next_int(adds.size())]), scale, {"hp": 1.0, "dmg": 1.0})
	_roll_unit(m)
	_pick_enemy_intent(m)
	enemies.append(m)
	EventBus.unit_spawned.emit(m.uid)


# ===========================================================================
# Face keyword parsing (engine.js kwVal/hasKw)
# ===========================================================================

static func _has_kw(f: Dictionary, name: String) -> bool:
	for k in (f.get("keywords", []) as Array):
		var ks := String(k)
		if ks == name or ks.begins_with(name + ":"):
			return true
	return false

## Returns `true` for a bare keyword ("cantrip"), or the int after ":" for "name:N" —
## matches JS kwVal's mixed bool|number return. Callers that need a number use int(...)
## on the result, which coerces `true`/`false` to 1/0 same as JS's `+true`/`+false`.
static func _kw_val(f: Dictionary, name: String) -> Variant:
	for k in (f.get("keywords", []) as Array):
		var ks := String(k)
		if ks == name:
			return true
		if ks.begins_with(name + ":"):
			return int(ks.split(":")[1])
	return 0
