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
var chaos_reroll_given: int = 0   ## Reroll gained from active relics this turn (a_chaos cap, relic-set-v2 §3.6)
var relic_reroll_given: int = 0   ## Reroll gained from passive relic sources this turn (cap relic_reroll_cap)
var _cond_given: int = 0   ## AQUA CONDUIT payout watermark — see _grant_conduit_rerolls()
var rerolls: int = 0
var max_rerolls: int = 2
var used_actives: Array = []
var resonance_log: Array = []   # [{pos:int, t:String, used:bool}]
var last_big: Dictionary = {}   # {} or {v:int, f:Dictionary}
var first_used: bool = false
# "dmg_dealt_clamped" (RunStats accumulator, design-handoff-v2 §09): a SEPARATE, purely
# additive counter from "dmg" — see damage_pipeline.gd's write sites for why "dmg" itself
# could not be reused (it is unclamped and never counted poison/thorns). Nothing reads this
# key to make a decision; it exists only to be folded into RunState.run_stats and displayed.
var stat: Dictionary = {"dmg": 0, "taken": 0, "turns": 0, "kills": 0, "max_hit": 0,
	"dmg_dealt_clamped": 0}

var relic_ids: Array = []
var node_id: String = ""
var kind: String = ""
var pw: int = 0
var ascension: int = 0
var combat_seed: int = 0

## Which boss this node fields, chosen once per run by RunState (never re-rolled in combat),
## and the run-wide CURSE PACT enemy modifiers. Both arrive through the combat setup so that
## a combat is still reconstructible from data alone (architecture plan §4).
var _guarantee_tank: bool = false   ## setup flag `guarantee_tank` (A.13): the fight holds at least one plating tank
var _early_traits: bool = false   ## setup flag `before_first_elite`: normal fights carry at most traits.cap_early trait bearers
var run_rules: Array = []   ## Run rules active this fight ("R12" Plating everywhere + side bonus, "R13")
var affix2: String = ""   ## second Elite affix (group B, after boss 1)
var spite_hits: Dictionary = {}   ## enemy uid -> single-target dmg faces landed on it this player turn (M3)
var affix: String = ""   ## Elite affix id from combat_setup (depth v3 6.4), "" = none
var _boss_key: String = ""
var _run_mods: Dictionary = {"enemy_hp": 1.0, "enemy_dmg": 1.0}

var won: bool = false
var lost: bool = false
var result_shards_earned: int = 0

var undo_stack: Array = []

## Where player decisions are written down, or null when nobody is recording (every existing
## test, and any tool driving a combat for its own reasons). RunState hands the run's one log
## in when it builds the combat, so a combat never owns or creates one — a per-combat log
## could not express "this run", which is the unit the verifier cares about.
##
## Recorded HERE rather than in the UI on purpose: a new screen cannot forget to call it, and a
## headless bot produces exactly the log a player's hands would. See action_log.gd's header.
var action_log: ActionLog = null

var _rng: Rng = null
## Compatibility only (L1 contract 1.4): when a caller does not pass a seed (`seed < 0`) the engine
## asks this source for one. RunState hands it in through the combat setup. Null = legacy behaviour,
## the draw simply continues the current stream (raw-engine tests). Remove with the compat layer.
var _epoch: EpochSource = null
## k-th reroll request this turn (reroll epoch key, ADR-RNG §4.4). In the snapshot so undo rewinds it.
var reroll_k: int = 0
## Depth v4 BO (set): snapshot of the dice groups of >=3 sharing a part, [{part,size,uids,hi,m100}]. Rebuilt ONLY by _snap_bo()
## (end of roll_all/reroll_dice, after wild_face, after _roll_edit), saved in _state_dict, never rebuilt on load (design 3.3).
var bo: Array = []
## Depth v4 3.8: 1..3, default 3. Stage < 2 refuses Lieu / wild_face; stage < 3 refuses Overcast and switches off part_add.
var depth_stage: int = 3
## Depth v4 3.5 (N1): Lieu/An toan rerolls chosen this turn. ONLY these count against reroll.max_total; free, relic, Aid never do.
var reroll_paid_k: int = 0
## Depth v4 3.6 (MD 22/10): Mat Tam uses this FIGHT (cap wild.per_battle). In the undo snapshot and the save; reset in setup_new only.
var wild_used: int = 0
## Depth v4 3.7 (MD 22/10): Overcasts used this turn (cap overcast.per_turn). The Set it hit is stored as the `overcast` flag on every
## member die at the moment of use (locked: a later reroll / Mat Tam does not move it). In the undo snapshot and the save; reset in roll_all.
var overcast_used: int = 0
## Anchor (design: production/anchor-2b-brief.md). anchor_id "" = no Anchor: every hook below is skipped, no rng, replays unchanged.
var anchor_id: String = ""
var anchor_awakened: bool = false
## Per-turn Anchor tallies, reset in roll_all, in the undo snapshot AND the save. gb100 = Gambler clean-Gamble add (percent),
## mine = Mana Mine turn-one natural SET happened, sw_used = Second Wind used, vol_* = Volley blast state, oc2 = uids stacked by Double Beat.
var anchor_turn: Dictionary = {}
## House mutations (production/anchor-2b-brief.md): {house_id: tier 1|2}, empty without an Anchor. Fixed for the fight, in snapshot + save.
var house_tiers: Dictionary = {}
## Per-FIGHT mutation tally (not reset per turn): {"kin": bool Cover already fired, "fired": {house_id: total amount}}. Snapshot + save.
var anchor_fight: Dictionary = {}
## Every reroll this turn, any source: capped by reroll.hard_cap (3.10.3).
var reroll_total_turn: int = 0
## Depth v4 3.10.2: lock per (turn, k) = {rmode, rsrc, uids, list}; asking for the same k again must repeat it exactly. NOT cleared by undo. Reset in roll_all.
var reroll_lock: Dictionary = {}
## Relic scratch space for ONE combat (H6, contract 2.3): plain JSON, owned by lane B's handlers
## (tweak_left, mana_paid_<id>, chaos_rerolls...). In the snapshot, so undo and resume restore it
## together with Mana. `relic_run_in` is RunState.relic_state as the fight began; handlers write
## run-level results into `relic_run_out`, which get_result() hands back.
var relic_combat: Dictionary = {}
var relic_run_in: Dictionary = {}
var relic_run_out: Dictionary = {}
## Combat pressure (ascension-v2 §2.4, monetization-v1 §1.2). Pure functions of `turn` and
## `clock_turn_base`, so replay needs no extra input. Continue / the Aid "delay clock" move the base.
var clock_turn_base: int = 0
## How many times the party was revived in this fight (the `attempt` of the epoch protocol). Fight state,
## not a purchase flag: no rule reads it except to key the next epoch request (MON-13).
var attempt: int = 0
## Mission (risk-to-earn) run: standard + named extra rules, and no Continue / Aid. A fact about the
## RUN, fixed at setup (header), not about anything bought.
var mission: bool = false
var mission_rules: Array = []
## Newcomer account (first runs): attrition and the light A0-A3 clock are off. A fixed header fact.
var newcomer: bool = false
## Pure numbers handed in by RunState (a Boon, a mission rule, anything): the engine neither knows nor
## cares where they came from (MON-13). See setup_new().
var start_shield_all: int = 0
var start_mana: int = 0
var first_dmg_face_bonus: int = 0
var start_eggs: int = 0
var _first_dmg_used: bool = false
var _end_fired: bool = false     ## on_combat_end fires once, from the first get_result()


## Hands the engine the run's epoch source. setup_new() does it from the combat setup; a fight restored
## with from_data() (resume, scene reload) has no setup, so the caller (CombatView, lane U) calls
## `_combat.set_epoch(RunState.epoch)` right after from_data(). Without it the engine falls back to the
## legacy continuing stream and the draw is not on the tape.
func set_epoch(src: EpochSource) -> void:
	_epoch = src

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
	affix = String(combat_setup.get("affix", ""))
	affix2 = String(combat_setup.get("affix2", ""))
	run_rules = (combat_setup.get("run_rules", []) as Array).duplicate()
	if relic_ids.has("rule_hard_shell") and not run_rules.has("R12"):
		run_rules.append("R12")   # Vo Cung (rule_hard_shell) = depth v3 R12: Plating everywhere + side face bonus
	if kind == "elite" and bool(combat_setup.get("first_run_elite", false)):
		# 6.4: the account's first run keeps the anti-spam affix: Giap Sat, or Khien Hoi when the team cannot break Plating.
		var fr: Dictionary = ContentDB.elite_affix_meta.get("first_run", {})
		affix = String(fr.get("default", "iron")) if bool(combat_setup.get("team_can_break", true)) else String(fr.get("no_break", "ward"))
		affix2 = ""
	spite_hits = {}
	_run_mods = (combat_setup.get("run_mods", {}) as Dictionary).duplicate()
	_rng = Rng.new(combat_seed)
	_epoch = combat_setup.get("epoch", null) as EpochSource
	newcomer = bool(combat_setup.get("newcomer", false))
	depth_stage = clampi(int(combat_setup.get("depth_stage", 3)), 1, 3)
	bo = []
	clock_turn_base = 0
	attempt = 0
	mission = bool(combat_setup.get("mission", false))
	mission_rules = (combat_setup.get("mission_rules", []) as Array).duplicate()
	start_shield_all = int(combat_setup.get("start_shield_all", 0))
	start_mana = int(combat_setup.get("start_mana", 0))
	first_dmg_face_bonus = int(combat_setup.get("first_dmg_face_bonus", 0))
	start_eggs = int(combat_setup.get("start_eggs", 0))
	anchor_id = String(combat_setup.get("anchor_id", ""))
	anchor_awakened = anchor_id != "" and bool(combat_setup.get("anchor_awakened", false))
	anchor_turn = _anchor_turn_fresh()
	house_tiers = _house_tiers_from_data(combat_setup.get("house_tiers", {})) if anchor_id != "" else {}
	anchor_fight = _anchor_fight_fresh()
	_first_dmg_used = false
	relic_combat = {}
	relic_run_in = (combat_setup.get("relic_state", {}) as Dictionary).duplicate(true)
	relic_run_out = relic_run_in.duplicate(true)
	_end_fired = false
	reroll_k = 0
	reroll_paid_k = 0
	reroll_total_turn = 0
	reroll_lock = {}
	wild_used = 0
	_next_token_uid = TOKEN_UID_BASE
	undo_stack = []
	won = false
	lost = false
	result_shards_earned = 0
	stat = {"dmg": 0, "taken": 0, "turns": 0, "kills": 0, "max_hit": 0, "dmg_dealt_clamped": 0}
	resonance_log = []
	last_big = {}
	first_used = false
	mana = 0
	mana_spent = 0
	_cond_given = 0
	used_actives = []
	chaos_reroll_given = 0
	relic_reroll_given = 0

	var roster: Array = combat_setup.get("roster_snapshot", [])
	# Depth v3 Core Take The Field (c_descend): which back-row Axie walks to the front (-1 = none).
	var descend_idx := int(RelicHooks.run_value_hook(self, "descend_pick", {"combat": self, "roster": roster}, -1))
	if descend_idx >= 0:
		relic_combat["descend"] = {"idx": descend_idx}
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

	_early_traits = bool(combat_setup.get("before_first_elite", false))
	_guarantee_tank = bool(combat_setup.get("guarantee_tank", false))
	# Raid R1 (lane RV): a ghost team replaces the generated encounter; the engine's own enemy AI plays it.
	# Run-rule affixes (depth v3) only apply to generated encounters, never to a ghost team.
	var ghost_team: Array = combat_setup.get("ghost_team", [])
	if ghost_team.is_empty():
		enemies = _generate_encounter(kind, pw)
		_apply_affix_start()
	else:
		enemies = RaidGhost.make_enemies(ghost_team, _alloc_token_uid)

	# A3+ "Short Dice": the BASE loses its free reroll (floor 0 in ascension.json), so every reroll costs mana; bonuses still add on top.
	var amods_r := ContentDB.ascension_mods(ascension)
	# Depth v3 3.5: free rerolls per turn come from combat_tune.json reroll.free (was a literal 2).
	var base_rerolls := reroll_free_per_turn()
	if int(amods_r.get("reroll_base_delta", 0)) != 0:
		base_rerolls = maxi(int(amods_r.get("reroll_base_floor", 1)), base_rerolls + int(amods_r["reroll_base_delta"]))
	max_rerolls = maxi(0, base_rerolls + int(combat_setup.get("bonus_reroll", 0)) + int(RelicHooks.sum(self, "rerollUp")))
	rerolls = max_rerolls

	for u in party:                                                    # SCALES passive
		if u.cls == "reptile":
			u.status["thorns"] = max(int(u.status.get("thorns", 0)), int(RelicHooks.field(self, "scales_thorns", 2.0)))

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
	# Start-of-fight numbers (no source attached): eggs first so they also get the shield, then Mana.
	for i in start_eggs:
		if _count_alive_tokens(party) < int(RelicHooks.max_val(self, "tokenCap", 4.0)):
			party.append(_mk_ally())
	if start_shield_all > 0:
		for pu in party:
			if not pu.is_token:
				DamagePipeline.apply_shield(self, pu, start_shield_all)
	mana += start_mana
	RelicHooks.fire(self, "on_combat_start", {"combat": self, "node_kind": kind})   # H5a
	# JS startCombat() fires onTurnStart BEFORE the first rollAll (engine.js:426). Omitting it
	# made every on-turn-start relic silently skip turn 1 of every combat — the relic looked
	# implemented and was simply one turn late, forever.
	RelicHooks.fire(self, "on_turn_start", {"combat": self})
	_set_turn_phase(CombatPhase.ROLL)
	roll_all()
	_affix_chill()
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
		"chaos_reroll_given": chaos_reroll_given,
		"relic_reroll_given": relic_reroll_given,
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
		"affix": affix,
		"affix2": affix2,
		"run_rules": run_rules.duplicate(),
		"spite_hits": spite_hits.duplicate(),
		"won": won,
		"lost": lost,
		"result_shards_earned": result_shards_earned,
		"rng_state": _rng.get_state() if _rng != null else 0,
		"reroll_k": reroll_k,
		"reroll_paid_k": reroll_paid_k,
		"wild_used": wild_used,
		"overcast_used": overcast_used,
		"anchor_id": anchor_id,
		"anchor_awakened": anchor_awakened,
		"anchor_turn": anchor_turn.duplicate(true),
		"house_tiers": house_tiers.duplicate(),
		"anchor_fight": anchor_fight.duplicate(true),
		"reroll_total_turn": reroll_total_turn,
		"reroll_lock": _lock_to_data(),
		"relic_combat": relic_combat.duplicate(true),
		"relic_run_in": relic_run_in.duplicate(true),
		"relic_run_out": relic_run_out.duplicate(true),
		"end_fired": _end_fired,
		"clock_turn_base": clock_turn_base,
		"attempt": attempt,
		"mission": mission,
		"mission_rules": mission_rules.duplicate(),
		"newcomer": newcomer,
		"bo": _dup_dict_array(bo),
		"depth_stage": depth_stage,
		"start_shield_all": start_shield_all,
		"start_mana": start_mana,
		"first_dmg_face_bonus": first_dmg_face_bonus,
		"start_eggs": start_eggs,
		"first_dmg_used": _first_dmg_used,
		"next_token_uid": _next_token_uid,
	}


func _apply_state_dict(d: Dictionary) -> void:
	party = _units_from_data(d.get("party", []))
	enemies = _units_from_data(d.get("enemies", []))
	turn = int(d.get("turn", 1))
	phase = int(d.get("phase", CombatPhase.EXECUTE))
	mana = int(d.get("mana", 0))
	mana_spent = int(d.get("mana_spent", 0))
	chaos_reroll_given = int(d.get("chaos_reroll_given", 0))
	relic_reroll_given = int(d.get("relic_reroll_given", 0))
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
	affix = String(d.get("affix", ""))
	affix2 = String(d.get("affix2", ""))
	run_rules = (d.get("run_rules", []) as Array).duplicate()
	spite_hits = {}
	for k in (d.get("spite_hits", {}) as Dictionary):
		spite_hits[int(k)] = int((d["spite_hits"] as Dictionary)[k])
	won = bool(d.get("won", false))
	lost = bool(d.get("lost", false))
	result_shards_earned = int(d.get("result_shards_earned", 0))
	_rng = Rng.new(int(d.get("rng_state", 0)))
	reroll_k = int(d.get("reroll_k", 0))
	bo = _bo_from_data(d.get("bo", []))
	depth_stage = clampi(int(d.get("depth_stage", 3)), 1, 3)
	reroll_paid_k = int(d.get("reroll_paid_k", 0))
	wild_used = int(d.get("wild_used", 0))
	overcast_used = int(d.get("overcast_used", 0))
	anchor_id = String(d.get("anchor_id", ""))
	anchor_awakened = bool(d.get("anchor_awakened", false))
	anchor_turn = _anchor_turn_from_data(d.get("anchor_turn", {}))
	house_tiers = _house_tiers_from_data(d.get("house_tiers", {}))
	anchor_fight = _anchor_fight_from_data(d.get("anchor_fight", {}))
	reroll_total_turn = int(d.get("reroll_total_turn", 0))
	reroll_lock = _lock_from_data(d.get("reroll_lock", {}))
	relic_combat = (d.get("relic_combat", {}) as Dictionary).duplicate(true)
	relic_run_in = (d.get("relic_run_in", {}) as Dictionary).duplicate(true)
	relic_run_out = (d.get("relic_run_out", {}) as Dictionary).duplicate(true)
	_end_fired = bool(d.get("end_fired", false))
	clock_turn_base = int(d.get("clock_turn_base", 0))
	attempt = int(d.get("attempt", 0))
	mission = bool(d.get("mission", false))
	mission_rules = (d.get("mission_rules", []) as Array).duplicate()
	newcomer = bool(d.get("newcomer", false))
	start_shield_all = int(d.get("start_shield_all", 0))
	start_mana = int(d.get("start_mana", 0))
	first_dmg_face_bonus = int(d.get("first_dmg_face_bonus", 0))
	start_eggs = int(d.get("start_eggs", 0))
	_first_dmg_used = bool(d.get("first_dmg_used", false))
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
	if not _end_fired and (won or lost):
		# H5b: once per fight, only when the fight is truly over (a wiped party still on the Continue
		# screen has not asked for a result yet). Guarded by a flag in the snapshot, not by luck.
		_end_fired = true
		RelicHooks.fire(self, "on_combat_end", {"combat": self, "result": "won" if won else "lost",
			"node_kind": kind})
	return {
		"relic_state": relic_run_out.duplicate(true),
		"won": won,
		"shards_earned": result_shards_earned if won else 0,
		"growth_keep": _compute_growth_keep(),
		"roster_updates": {},
		"kind": kind,
		"pw": pw,
		# The fight's own counters, so the RUN can total them. They were tracked here from the
		# start and read by nothing outside this object, which is why the end-of-run screen had
		# to say "not tracked" about numbers the engine had been counting all along.
		"stat": stat.duplicate(true),
		# Real (non-token) Axie down at the end of the fight. Read by Run Rule Crow Herald (design 2b R11).
		"downed": real_party().filter(func(u): return u.hp <= 0).size(),
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
	return party.filter(func(u): return u.hp > 0 and not is_sidelined(u))


## Depth v3: a unit that is in `party` but out of play: asleep (Core Sacrifice) or a temporary extra die
## (Core Sixth Die, "phantom"). Never targeted, never counts for the lose check.
static func is_sidelined(u: Unit) -> bool:
	return u.custom_state.has("asleep") or u.custom_state.has("phantom")

func alive_enemies() -> Array:
	return enemies.filter(func(u): return u.hp > 0)

## realP(s) — party members that are NOT tokens/allies. Only these count for the
## lose condition (rule spec §4/§8).
func real_party() -> Array:
	return party.filter(func(u): return not u.is_token and not is_sidelined(u))

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
		if not u.is_token and u.hp > 0 and not is_sidelined(u):
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
	_drop_phantoms()
	bo = []   # cantrips resolved below read M = 1; the new snapshot is taken at the end
	reroll_paid_k = 0
	reroll_total_turn = 0
	reroll_lock = {}
	overcast_used = 0
	anchor_turn = _anchor_turn_fresh()
	for u in party:
		u.custom_state.erase("tmp_thorns")   # Spiked Shield: Thorns last until the end of the enemy turn only
		u.overcast = false
		u.wild_slot = -1   # Mat Tam lasts one turn, mana not refunded (3.6)
		u.cracked = false   # Lieu cracks last until the next roll (a parked die comes out clean too)
		if u.custom_state.has("asleep"):
			u.held = false
			u.clear_roll()
		elif u.hp > 0:
			if u.frozen_next:
				u.frozen = true
				u.frozen_next = false
			# Depth v3 Hold: a die parked with stash() keeps its face and its crit, does not draw from
			# the rng, and is usable at once. It cannot be parked again next turn (stash_carry).
			if u.held and u.has_rolled() and not u.roll_used():
				u.held = false
				u.stash_carry = true
			else:
				u.held = false
				u.stash_carry = false
				_roll_unit(u)
		else:
			u.held = false
			u.stash_carry = false
			u.clear_roll()
	_share_class_rolls()
	_spawn_phantom_dice()
	for e in enemies:
		if e.hp > 0:
			_roll_unit(e)
			_apply_strike_face(e)
			_affix_echo(e)
			_pick_enemy_intent(e)
			CombatTraits.charge_roll(self, e)
		else:
			e.clear_roll()
			e.intent = {}
	_resolve_cantrips()
	RelicHooks.fire(self, "on_roll_end", {"combat": self})
	RelicHooks.fire(self, "on_roll_settled", {"combat": self, "rerolled_uids": []})   # H1b
	_snap_bo()
	_anchor_mine_roll()


## Depth v3 Core Concord (hook `roll_share_class`): Axies of one class that rolled fresh this turn all show the face
## index of the first of them (their own crit roll stays). No extra rng draws.
func _share_class_rolls() -> void:
	if not bool(RelicHooks.run_value_hook(self, "roll_share_class", {"combat": self}, false)):
		return
	var first_of := {}
	for u in party:
		if u.hp <= 0 or is_sidelined(u) or u.is_token or u.held or u.stash_carry or not u.has_rolled() or u.cls == "":
			continue
		if not first_of.has(u.cls):
			first_of[u.cls] = u.roll_face_index()
		elif u.roll_face_index() != int(first_of[u.cls]):
			var crit: bool = u.roll_crit_now()
			var f: Dictionary = u.die[int(first_of[u.cls])]
			u.set_roll(int(first_of[u.cls]), crit and String(f.get("type", "")) == "dmg")
			u.heavy = _has_kw(f, "heavy")


## Depth v3 Core Sixth Die: hook `extra_dice` (value = how many). Each extra die is a copy of a random living
## Axie's die, rolled now, usable this turn, dropped at end of turn. Draws from the shared rng only when the Core is owned.
func _spawn_phantom_dice() -> void:
	var n := int(RelicHooks.run_value_hook(self, "extra_dice", {"combat": self}, 0))
	for i in n:
		var pool: Array = []
		for u in party:
			if u.hp > 0 and not is_sidelined(u) and not u.is_token:
				pool.append(u)
		if pool.is_empty():
			return
		var src: Unit = pool[_rng.next_int(pool.size())]
		var d := src.to_data()
		var ph := Unit.from_data(d)
		ph.uid = _alloc_token_uid()
		ph.hp = 1
		ph.max_hp = 1
		ph.shield = 0
		ph.status = {}
		ph.held = false
		ph.stash_carry = false
		ph.frozen = false
		ph.frozen_next = false
		ph.plating = 0
		ph.plating_off = 0
		ph.roster_index = -1
		ph.slot = -1
		ph.growth = {}
		ph.clear_roll()
		ph.custom_state = {"phantom": true, "src_uid": src.uid}
		party.append(ph)
		_roll_unit(ph)
		EventBus.unit_spawned.emit(ph.uid)
		EventBus.float_text.emit(ph.uid, "6TH DIE", "buf", 0)
		CoreHooks.fire("c_sixth_die", ph.uid, 1, "rule")


func _drop_phantoms() -> void:
	party = party.filter(func(u): return not u.custom_state.has("phantom"))


func _roll_unit(u: Unit) -> void:
	var fi := _rng.next_int(6)
	# H7: roll_face may redirect the face (loadeddie, twinfates draw more from the same stream).
	fi = int(RelicHooks.run_value_hook(self, "roll_face", {"combat": self, "unit": u}, fi))
	var f: Dictionary = u.die[fi]
	u.heavy = _has_kw(f, "heavy")
	var cc := _crit_chance(u, f)
	var crit_now: bool = u.side == "p" and String(f.get("type", "")) == "dmg" and cc > 0.0 \
		and (_rng.next_float() * 100.0) < cc
	u.set_roll(fi, crit_now)


func _crit_chance(u: Unit, f: Dictionary) -> float:
	return float(RelicHooks.run_value_hook(self, "face_crit", {"combat": self, "unit": u, "face": f},
		float(_kw_val(f, "crit")) + RelicHooks.sum(self, "critBonus")))


func _pick_enemy_intent(e: Unit) -> void:
	var fi := e.roll_face_index()
	var f: Dictionary = e.die[fi]
	var face_type := String(f.get("type", ""))
	var tgt_uid := -1
	if face_type in ["dmg", "poison", "debuff"]:
		var ps := alive_party()
		if ps.size() > 0:
			# Depth v3 rows: a single-target attack can only pick a front-row Axie while one lives. AoE / pierce
			# faces ignore rows; the Assassin keeps hunting the weakest of the WHOLE party (design 4 / 9c).
			var rp := ps
			if not _has_kw(f, "aoe") and not _has_kw(f, "pierce") and e.role != "assassin":
				rp = front_row_targets(ps)
				if String(RelicHooks.run_value_hook(self, "enemy_row_pref", {"combat": self}, "")) == "back":
					rp = back_row_targets(ps)   # Upside Down
					CoreHooks.fire("rule_upside_down", e.uid, 1, "rule")
			var ambush: bool = bool(_aff(e).get("target_back_weakest", false)) \
				and not _has_kw(f, "aoe") and not _has_kw(f, "pierce")
			if ambush:
				var back: Array = []
				for raw in ps:
					if row_of(raw as Unit) == 1:
						back.append(raw)
				var pool_a: Array = back if not back.is_empty() else ps
				tgt_uid = _lowest_by(pool_a, func(u: Unit) -> float: return float(u.hp + u.shield)).uid
			elif e.role == "assassin":
				tgt_uid = _lowest_by(ps, func(u: Unit) -> float: return float(u.hp + u.shield)).uid
			elif e.role == "bruiser" and _rng.next_float() < 0.5:
				tgt_uid = _lowest_by(rp, func(u: Unit) -> float: return -float(u.hp + u.shield)).uid
			else:
				tgt_uid = rp[_rng.next_int(rp.size())].uid
	elif face_type in ["shield", "heal", "buff"]:
		var es := alive_enemies()
		if e.role == "healer" and es.size() > 0:
			tgt_uid = _lowest_by(es, func(u: Unit) -> float: return float(u.hp) / max(1.0, float(u.max_hp))).uid
		elif es.size() > 0:
			tgt_uid = es[_rng.next_int(es.size())].uid
		else:
			tgt_uid = e.uid
	e.intent = {"face_index": fi, "target_uid": tgt_uid}


## ---- Depth v3 rows (design 4). Front row = roster 0..front_size-1, the rest are the back row. -------------
## Egg / token units (roster_index < 0) stand in the BACK row. Hook `front_row_size` lets a Core widen it.
func front_row_size() -> int:
	return int(RelicHooks.run_value_hook(self, "front_row_size", {"combat": self},
		int(tune_knob("rows", "front_size", 2.0))))


## 0 = front, 1 = back.
func row_of(u: Unit) -> int:
	if u.is_token and not relic_combat.is_empty() and bool(relic_combat.get("eggs_front", false)):
		return 0   # Nest
	if not relic_combat.is_empty() and relic_combat.has("descend") and u.roster_index == int((relic_combat["descend"] as Dictionary)["idx"]):
		return 0
	return 0 if (u.roster_index >= 0 and u.roster_index < front_row_size()) else 1


## The living back-row units of `ps`; when none is alive, `ps` itself.
func back_row_targets(ps: Array) -> Array:
	var out: Array = []
	for raw in ps:
		if row_of(raw as Unit) == 1:
			out.append(raw)
	return out if not out.is_empty() else ps


## The living front-row units of `ps`; when none is alive, `ps` itself (the back row becomes reachable).
func front_row_targets(ps: Array) -> Array:
	var out: Array = []
	for raw in ps:
		if row_of(raw as Unit) == 0:
			out.append(raw)
	return out if not out.is_empty() else ps


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
		# Depth v3 Core Loop (c_loop): the first cantrip an Axie resolves each roll is used one extra time.
		var extra := int(RelicHooks.run_value_hook(self, "cantrip_extra", {"combat": self, "unit": u}, 0))
		while u.has_rolled() and not u.roll_used() and _has_kw(u.current_face(), "cantrip") and guard < 6:
			guard += 1
			_exec_face(u, u.uid)
			if extra > 0:
				extra -= 1
				if u.has_rolled():
					u.rolled[0]["used"] = false
					EventBus.float_text.emit(u.uid, "LOOP", "buf", 0)
					CoreHooks.fire("c_loop", u.uid, 1, "reroll")
					_exec_face(u, u.uid)
			_roll_unit(u)


## ---- async twins (L1 B1): the view awaits the seed, then calls the sync rule with it -------------------
## True while one of the request_* below waits for its reply; the view disables input meanwhile.
var epoch_pending: bool = false


func _reroll_args(uids: Array, from_aid: bool, rmode: int = 1) -> Dictionary:
	# rmode (NOT `mode`, that key is run_start's short/full): 0 = Lieu, 1 = Safe. Free and Aid rerolls always send 1 (3.5).
	var rargs := {"turn": turn, "k": reroll_k + 1,
		"source": "aid" if from_aid else "base", "uids": _int_list(uids), "rmode": effective_rmode(from_aid, rmode)}
	if attempt > 0:
		rargs["attempt"] = attempt
	return rargs


func _end_turn_args() -> Dictionary:
	var eargs := {"turn": turn}
	if attempt > 0:
		eargs["attempt"] = attempt
	return eargs


func _continue_args() -> Dictionary:
	return {"node_id": node_id, "attempt": attempt + 1}


## Waits for one epoch reply. Returns {ok, seed, code}. No epoch source = seed -1 (the sync path rolls on
## the engine's own rng, as before).
func _await_seed(kind: String, args: Dictionary) -> Dictionary:
	if _epoch == null:
		return {"ok": true, "seed": -1, "code": ""}
	epoch_pending = true
	var r := _epoch.request(kind, args)
	if not r.done:
		await r.resolved
	epoch_pending = false
	return {"ok": r.ok, "seed": r.seed, "code": r.code}


## Async reroll_dice(). Returns {ok, code}; code "illegal" = rules refused, "busy" = a request is in flight.
func request_reroll_dice(uids: Array, from_aid: bool = false, rmode: int = 1) -> Dictionary:
	if epoch_pending:
		return {"ok": false, "code": "busy"}
	if not can_reroll(uids, from_aid, rmode):
		return {"ok": false, "code": "illegal"}
	var a := await _await_seed("reroll", _reroll_args(uids, from_aid, rmode))
	if not bool(a["ok"]):
		return {"ok": false, "code": String(a["code"])}
	var ok := reroll_dice(uids, int(a["seed"]), from_aid, rmode)
	return {"ok": ok, "code": "" if ok else "illegal"}


## Async begin_end_turn().
func request_begin_end_turn() -> Dictionary:
	if epoch_pending:
		return {"ok": false, "code": "busy"}
	if not can_end_turn():
		return {"ok": false, "code": "illegal"}
	var a := await _await_seed("end_turn", _end_turn_args())
	if not bool(a["ok"]):
		return {"ok": false, "code": String(a["code"])}
	var ok := begin_end_turn(int(a["seed"]))
	return {"ok": ok, "code": "" if ok else "illegal"}


## Async continue_after_wipe() (Aid R1).
func request_continue_after_wipe(heal_pct: int = -1) -> Dictionary:
	if epoch_pending:
		return {"ok": false, "code": "busy"}
	if not can_continue():
		return {"ok": false, "code": "illegal"}
	var a := await _await_seed("continue", _continue_args())
	if not bool(a["ok"]):
		return {"ok": false, "code": String(a["code"])}
	var ok := continue_after_wipe(int(a["seed"]), heal_pct)
	return {"ok": ok, "code": "" if ok else "illegal"}


## REROLL — see the class-level DESIGN DECISION comment: this is a transient marker, not
## a blocking gate. engine.js doReroll(s, uids).
func reroll_dice(uids: Array, seed: int = -1, from_aid: bool = false, rmode: int = 1) -> bool:
	if not can_reroll(uids, from_aid, rmode):
		return false
	var eff := effective_rmode(from_aid, rmode)
	# Epoch boundary: the seed for the new faces. Asked AFTER the legality check (ADR-RNG §4.3 rule 5:
	# never ask for a seed for an action the engine would refuse) and BEFORE the action is logged
	# (the server expects the consuming action at log_len).
	var use_seed := seed
	if use_seed < 0 and _epoch != null:
		var r := _epoch.request("reroll", _reroll_args(uids, from_aid, eff))
		if not r.ok:
			push_error("CombatEngine.reroll_dice: epoch refused (%s)" % r.code)
			return false
		use_seed = r.seed
	# can_reroll() already ran the veto / Mana check BEFORE the epoch was asked for. The live pass below
	# may still refuse; nothing (RNG, reroll_k, Mana) is touched until it has agreed.
	var list: Array = _rerollable(uids)
	var hook := _before_reroll(uids, from_aid, false)
	var paid_cost := reroll_mana_cost(from_aid, eff)   # 0 while a free charge is left, for Aid and for Lieu
	var mut_saved := reroll_mana_cost(from_aid, eff, false) - paid_cost   # Hunt Four discount, if any
	if bool(hook["veto"]) or mana < int(hook["mana_cost"]) + paid_cost:
		return false
	if use_seed >= 0:
		_rng = Rng.new(use_seed)
	var was_paid := paid_cost > 0 or (not from_aid and rerolls <= 0)
	var rsrc := 1 if from_aid else 0
	var chosen := not from_aid and rerolls <= 0   # Lieu / Safe pick: the only kind counted against max_total (N1)
	reroll_k += 1
	reroll_total_turn += 1
	if chosen:
		reroll_paid_k += 1
		if eff == 1:
			anchor_turn["safe_n"] = int(anchor_turn["safe_n"]) + 1
			if mut_saved > 0:
				_mut_emit("h_big_hand", 0, mut_saved)
	var uid_list: Array = []
	for lu in list:
		uid_list.append((lu as Unit).uid)
	reroll_lock[reroll_k] = {"rmode": eff, "rsrc": rsrc, "uids": _int_list(uids), "list": uid_list}
	mana -= int(hook["mana_cost"]) + paid_cost
	_set_turn_phase(CombatPhase.REROLL)
	if not from_aid and rerolls > 0:
		rerolls -= 1
	if was_paid:
		RelicHooks.fire(self, "on_reroll_paid", {"combat": self, "cost": paid_cost, "k": reroll_k, "rmode": eff})
	var keep_crit := RelicHooks.has(self, "critKeep")
	for raw_u in list:
		var u: Unit = raw_u
		var had_crit: bool = u.roll_crit_now()
		u.cracked = false   # a re-rolled die sheds an old crack; Lieu may crack it again below
		_roll_unit(u)
		# JS: `if(rhas(s,'critKeep')) u.critNow = u.critNow || had` (engine.js:496-500) — a
		# crit already showing on the die survives the reroll instead of being gambled away.
		if keep_crit and had_crit:
			u.set_crit_now(true)
	_resolve_cantrips()
	var settled: Array[int] = []
	for ru in list:
		settled.append((ru as Unit).uid)
	RelicHooks.fire(self, "on_roll_settled", {"combat": self, "rerolled_uids": settled})   # H1b
	if eff == 0:
		# Lieu (3.5): ONE draw per uid the caller named, in the caller's order, from this reroll's own seed stream,
		# even for a die that died or did not roll, so RNG use does not depend on state. Only a die rolled just now can crack.
		var crack_pct := int(tune_knob("anchor", "gambler_crack_pct", 40.0)) if anchor_id == "a_gambler" else int(tune_knob("crack", "pct", 30.0))
		if CoreHooks.RelicHooks_has(self, "rule_high_stakes"):
			var hs := roundi(float(CoreHooks.rule_knob("rule_high_stakes", "crack_chance", 0.2)) * 100.0)
			crack_pct = mini(hs, crack_pct) if anchor_id == "a_gambler" else hs   # Anchor Gambler: the lower of the two
		var cracked_now: Array = []
		for raw_c in uids:
			var hit := _rng.next_int(100) < crack_pct
			var cu := by_uid(int(raw_c))
			if hit and cu != null and settled.has(cu.uid):
				cu.cracked = true
				cracked_now.append(cu.uid)
		_mut_gamble(cracked_now)
		_anchor_after_gamble(settled.size(), cracked_now, use_seed)
		if CoreHooks.RelicHooks_has(self, "rule_high_stakes"):
			CoreHooks.stakes_clean(self, settled, cracked_now)
	_snap_bo()
	# JS clears the undo stack on reroll ONLY when the party lacks `safeReroll`
	# (engine.js:502). Clearing unconditionally quietly disabled that relic's whole point.
	if not RelicHooks.has(self, "safeReroll"):
		undo_stack = []
	_set_turn_phase(CombatPhase.EXECUTE)
	# The uids the CALLER asked for, not the filtered `list`: the filter is a rule, and a replay
	# re-applies it. Logging the filtered set would bake today's filter into the record and hide
	# a future change to it.
	# `from_aid` is logged (as 0/1, canon has no bool) so a replay can re-apply an Aid reroll made
	# with no rerolls left; the plain reroll_dice(uids) form still replays (missing arg = 0).
	# args[2] = rmode (0 Lieu / 1 Safe), already normalised: free and Aid log 1.
	_log("reroll_dice", [uids.duplicate(), 1 if from_aid else 0, eff])
	return true


## Pure legality check for reroll_dice(); the view calls it BEFORE asking for an epoch.
func can_reroll(uids: Array, from_aid: bool = false, rmode: int = 1) -> bool:
	return reroll_refusal(uids, from_aid, rmode) == ""


## "" when the reroll is legal, else why not (the UI greys the button with it). Codes: over, hard_cap, stage, mission, none, pin_mismatch,
## mana, veto, bad_rmode, max_total (chosen rerolls used up).
func reroll_refusal(uids: Array, from_aid: bool = false, rmode: int = 1) -> String:
	if won or lost:
		return "over"
	if rmode != 0 and rmode != 1:
		return "bad_rmode"
	if reroll_total_turn >= reroll_hard_cap():
		return "hard_cap"
	if rerolls <= 0 and not from_aid and not reroll_is_payable():
		return "max_total"   # chosen (paid) rerolls reached reroll.max_total, distinct from the all-sources hard_cap
	var eff := effective_rmode(from_aid, rmode)
	if eff == 0 and depth_stage < 2:
		return "stage"   # Lieu opens at stage 2
	if from_aid and mission:
		return "mission"   # no Aid in a mission run
	var list := _rerollable(uids)
	if list.is_empty():
		return "none"
	if not _lock_allows(uids, list, eff, from_aid):
		return "pin_mismatch"
	var h := _before_reroll(uids, from_aid, true)
	if bool(h["veto"]):
		return "veto"
	if mana < int(h["mana_cost"]) + reroll_mana_cost(from_aid, eff):
		return "mana"
	return ""


## 3.5: a free-charge reroll and an Aid reroll are always Safe (1); only the chosen reroll (no charge left) can be Lieu.
func effective_rmode(from_aid: bool, rmode: int) -> int:
	if from_aid or rerolls > 0:
		return 1
	if depth_stage >= 2 and CoreHooks.RelicHooks_has(self, "rule_high_stakes"):
		return 0   # High Stakes (R16): every paid reroll is a Gamble. Stage 1 has no Gamble (reroll_refusal), so it stays Safe;
		# at integration the rule gets requires stage_min:2 (token from lane NC).
	return 0 if rmode == 0 else 1


## Base knob raised by hook `reroll_hard_cap` (hollow_core / cheap_mana: +1 each, so their looser cap is not eaten by the cap of 4).
func reroll_hard_cap() -> int:
	return int(RelicHooks.run_value_hook(self, "reroll_hard_cap", {"combat": self}, int(tune_knob("reroll", "hard_cap", 4.0))))


## 3.10.2 (N2/N3): the next reroll is key reroll_k + 1. If that key was already thrown (an undo rewound reroll_k, or a load), only the exact
## same request may repeat it: same rmode, same source (rsrc), same uid list, and the same dice still rerollable. Otherwise false, no k jump.
func _lock_allows(uids: Array, list: Array, eff: int, from_aid: bool) -> bool:
	var k := reroll_k + 1
	if not reroll_lock.has(k):
		return true
	var lk: Dictionary = reroll_lock[k]
	if int(lk["rmode"]) != eff or int(lk["rsrc"]) != (1 if from_aid else 0):
		return false
	if _int_list(uids) != (lk["uids"] as Array):
		return false
	var now_list: Array = []
	for u in list:
		now_list.append((u as Unit).uid)
	return now_list == (lk["list"] as Array)


func _lock_to_data() -> Dictionary:
	var out := {}
	for k in reroll_lock:
		out[str(k)] = (reroll_lock[k] as Dictionary).duplicate(true)
	return out


static func _lock_from_data(d) -> Dictionary:
	var out := {}
	if d is Dictionary:
		for k in d:
			var e: Dictionary = d[k]
			out[int(k)] = {"rmode": int(e.get("rmode", 1)), "rsrc": int(e.get("rsrc", 0)),
				"uids": _int_list(e.get("uids", [])), "list": _int_list(e.get("list", []))}
	return out


## ---- Depth v3 3.5: reroll costs mana once the free charges are gone ----------------------------------
func reroll_free_per_turn() -> int:
	return int(tune_knob("reroll", "free", 1.0))


## True when no free charge is left but a Lieu/Safe pick is still allowed this turn: reroll_paid_k + reroll.free < reroll.max_total (N1).
func reroll_is_payable() -> bool:
	return rerolls <= 0 and reroll_paid_k + reroll_free_per_turn() < int(tune_knob("reroll", "max_total", 3.0))


## Mana the NEXT reroll costs on top of any relic surcharge: 0 while a free charge is left, and for an
## Aid reroll. Hook `reroll_mana_cost` (value = knob reroll.mana_cost) lets a Core discount it.
func reroll_mana_cost(from_aid: bool = false, rmode: int = 1, with_mutation: bool = true) -> int:
	if from_aid or rerolls > 0 or rmode == 0:
		return 0   # Lieu is free (its price is the crack)
	var base := int(tune_knob("reroll", "mana_cost_2", 1.0)) if reroll_paid_k <= 0 else int(tune_knob("reroll", "mana_cost_3", 3.0))
	var c := maxi(0, int(RelicHooks.run_value_hook(self, "reroll_mana_cost", {"combat": self}, base)))
	return _mut_safe_price(c) if with_mutation else c


## H1a. A handler may veto the reroll or charge Mana for it; dry_run tells it nothing may be spent.
func _before_reroll(uids: Array, from_aid: bool, dry_run: bool) -> Dictionary:
	var ctx := {"combat": self, "uids": _int_list(uids), "from_aid": from_aid, "veto": false,
		"mana_cost": 0, "dry_run": dry_run}
	RelicHooks.fire(self, "before_reroll", ctx)
	return ctx


func _rerollable(uids: Array) -> Array:
	var list: Array = []
	for raw_id in uids:
		var u := by_uid(int(raw_id))
		if u != null and u.side == "p" and u.hp > 0 and u.has_rolled() and not u.roll_used() \
				and not u.heavy and not u.frozen and not u.held and not u.overcast and u.wild_slot < 0 \
				and bool(RelicHooks.run_value_hook(self, "reroll_allowed", {"combat": self, "unit": u}, true)):
			list.append(u)
	return list


static func _int_list(a: Array) -> Array:
	var out: Array = []
	for x in a:
		out.append(int(x))
	return out


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
## Mana cost of an active after relic hooks (hollowchalice etc). Accepts a RelicDef or a relic id.
## The UI must use this, never the raw def.act_cost, for affordability.
func active_cost(def_or_id) -> int:
	var d = RelicRegistry.get_def(def_or_id) if def_or_id is String else def_or_id
	if d == null:
		return 0
	return int(RelicHooks.run_value_hook(self, "active_cost", {"combat": self, "def": d}, int(d.act_cost)))


func play_active(relic_id: String, target_uid: int = -1) -> bool:
	if won or lost:
		return false
	var def = RelicRegistry.get_def(relic_id)
	if def == null or int(def.act_cost) <= 0:
		return false
	var a: Dictionary = def.act if "act" in def else {}
	if a.is_empty():
		return false
	var cost := active_cost(def)
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
			# a_chaos: total Reroll from actives <= chaos_reroll_cap per turn (1 MP = 8 with Conduit Crown otherwise)
			var room: int = maxi(0, RelicSlots.tuning().chaos_reroll_cap - chaos_reroll_given)
			var got: int = mini(v, room)
			chaos_reroll_given += got
			rerolls += got
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
					RelicHooks.fire(self, "on_egg_hatched", {"combat": self, "egg": al})
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
					RelicHooks.fire(self, "on_shield_break", {"combat": self, "tgt": tgt, "broken": sh, "src": src})
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
	RelicHooks.fire(self, "on_active_played", {"combat": self, "act_id": relic_id, "cost": cost})   # H4
	EventBus.relic_pulsed.emit(relic_id, (src.uid if src != null else 0))
	_check_end()
	_log("play_active", [relic_id, target_uid])
	return true


## AQUA CONDUIT class passive — every 4 Mana spent this combat grants +1 reroll charge, while
## at least one Aqua Axie lives. `_cond_given` tracks what has already been paid out so the
## grant is monotonic rather than re-awarded on every spend (JS `s._condGiven`).
## Passive relic Reroll sources (cullingorder, apexpredator, alphafang, tidecaller) go through here:
## total <= relic_reroll_cap per turn. Returns how many were actually granted.
func grant_relic_reroll(n: int) -> int:
	var got: int = mini(n, maxi(0, RelicSlots.tuning().relic_reroll_cap - relic_reroll_given))
	relic_reroll_given += got
	rerolls += got
	return got


func _grant_conduit_rerolls() -> void:
	var has_aqua := false
	for u in party:
		if u.cls == "aqua" and u.hp > 0:
			has_aqua = true
			break
	if not has_aqua:
		return
	var gained: int = int(floor(mana_spent / RelicHooks.field(self, "conduit_step", tune_knob("reroll", "conduit_step", 3.0)))) - _cond_given
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
	if u.held:
		return false   # parked this turn (stash)
	_push_undo()
	if not _exec_face(u, target_uid):
		undo_stack.pop_back()
		return false
	_check_end()
	# Only the calls that CHANGED something are recorded — an illegal move is a misclick, not a
	# decision, and replaying one would be evaluated in a state where it might be legal.
	_log("use_die", [unit_uid, target_uid])
	return true


## No-op without a log, so nothing in combat has to know whether anyone is recording.
func _log(fn: String, args: Array = []) -> void:
	if action_log != null:
		action_log.record(fn, args)


## core_impact (the display tally of Core activations) as it was when undo entry `k` was pushed. Not part of the
## snapshot dict itself (that would change saves / digests); undo_last() puts the tally back so an undone move is
## not counted twice when the player redoes it. Lost across a save/load (undo then leaves the tally as it is).
var _impact_at: Dictionary = {}


func _push_undo() -> void:
	_impact_at[undo_stack.size()] = RunState.core_impact.duplicate(true)
	undo_stack.append(_state_dict())
	if undo_stack.size() > 90:
		undo_stack.pop_front()
		for i in 90:
			_impact_at[i] = _impact_at.get(i + 1, {})


## H7 — dice-editing relics (Tweak / Amber hold / Loaded die). Each call: legal only mid-EXECUTE, takes an
## undo snapshot, lets the owning relic decide through `roll_edit` (ctx.ok = true), and is logged so a
## replay re-applies it. Deterministic apart from draws the handler makes on the epoch's own stream.
func tweak(kind: String, uid_a: int, uid_b: int = -1) -> bool:
	return _roll_edit("tweak", kind, uid_a, uid_b, -1, [kind, uid_a, uid_b])


func hold_pick(uid: int) -> bool:
	return _roll_edit("hold_pick", "hold", uid, -1, -1, [uid])


func loaded_pick(uid: int, face_index: int) -> bool:
	return _roll_edit("loaded_pick", "loaded", uid, -1, face_index, [uid, face_index])


## Tweaks the party may still spend this turn (relic_combat["tweak_left"], set by the relic).
func tweak_budget_left() -> int:
	return int(relic_combat.get("tweak_left", 0))


func _roll_edit(fn: String, p_kind: String, uid_a: int, uid_b: int, face_index: int, log_args: Array) -> bool:
	if won or lost or phase != CombatPhase.EXECUTE:
		return false
	_push_undo()
	var ctx := {"combat": self, "kind": p_kind, "uid_a": uid_a, "uid_b": uid_b,
		"face_index": face_index, "ok": false}
	RelicHooks.fire(self, "roll_edit", ctx)
	if not bool(ctx["ok"]):
		undo_stack.pop_back()
		return false
	_snap_bo()
	_log(fn, log_args)
	return true


## ---- Depth v3 Hold (design/proposals/depth-v3-design.md 3.2/3.3) ----------------------------------------
## Knob lookup in combat_tune.json: section/key with a code default, so a missing key never breaks a fight.
static func tune_knob(section: String, key: String, default_value: float) -> float:
	var sec = ContentDB.combat_tune.get(section, {})
	if sec is Dictionary and (sec as Dictionary).has(key):
		return float((sec as Dictionary)[key])
	return default_value


## How many dice may be parked at once. Hook `stash_cap` (value = knob stash.cap) lets a Core raise it.
func stash_cap() -> int:
	return int(RelicHooks.run_value_hook(self, "stash_cap", {"combat": self},
		int(tune_knob("stash", "cap", 1.0))))


func stash_count() -> int:
	var n := 0
	for u in party:
		if u.held and u.hp > 0:
			n += 1
	return n


## Pure legality check (the view greys the button with it). A die can be parked when it is a live, rolled,
## unused, non-token, non-frozen die whose face is not a cantrip, it was not itself parked over the last turn
## change (unless hook `stash_repeat`), and the cap is not reached.
func can_stash(unit_uid: int) -> bool:
	if won or lost or phase != CombatPhase.EXECUTE:
		return false
	var u := by_uid(unit_uid)
	if u == null or u.side != "p" or u.is_token or u.hp <= 0 or not u.has_rolled() or u.roll_used():
		return false
	if u.held or u.frozen or u.overcast or u.wild_slot >= 0 or _has_kw(u.current_face(), "cantrip"):
		return false
	if u.stash_carry and not bool(RelicHooks.run_value_hook(self, "stash_repeat",
			{"combat": self, "unit": u}, false)):
		return false
	return stash_count() < stash_cap()


## Parks one unused die: it cannot be used or rerolled now, and keeps its face (and crit) to the next turn.
## No mana. Undoable like any action. Logged as `stash [uid]`. Not `hold_pick` (the Amber relic).
func stash(unit_uid: int) -> bool:
	if not can_stash(unit_uid):
		return false
	var u := by_uid(unit_uid)
	_push_undo()
	var base_cap := int(tune_knob("stash", "cap", 1.0))
	var was_carry: bool = u.stash_carry
	var was_n := stash_count()
	u.held = true
	EventBus.float_text.emit(u.uid, "HOLD", "buf", 0)
	EventBus.die_stashed.emit(u.uid)
	for sid in ["c_steady_hold", "rule_tundra"]:
		if CoreHooks.RelicHooks_has(self, sid) and (was_n >= base_cap or (was_carry and sid == "c_steady_hold")):
			CoreHooks.fire(sid, u.uid, 1, "rule")
			break
	RelicHooks.fire(self, "on_stash", {"combat": self, "unit": u, "face": u.current_face(),
		"fi": u.roll_face_index()})
	_log("stash", [unit_uid])
	return true


# ---- Depth v4 3.6 MAT TAM ----------------------------------------------------------------------------------
func wild_cost() -> int:
	if anchor_id == "a_mana_mine":
		return maxi(0, int(tune_knob("anchor", "mine_wild_cost", 3.0)))   # Mana Mine price
	return maxi(0, int(tune_knob("wild", "cost", 2.0)))


func wild_per_battle() -> int:
	return maxi(0, int(tune_knob("wild", "per_battle", 1.0)))


## "" when `uid` may take Mat Tam part `slot` now, else a short code: phase, slot, stage, no_die, limit, used, held, cracked, cantrip,
## wild, same, not_counted, need_set3 (result is not a group of exactly 4), set5, mana. Mat Tam only turns a Set of 3 into a Set of 4. Pure (the UI greys the picker with it).
func wild_block_reason(unit_uid: int, slot: int) -> String:
	if won or lost or phase != CombatPhase.EXECUTE:
		return "phase"
	if slot < 0 or slot >= 6:
		return "slot"
	if depth_stage < 2:
		return "stage"
	var u := by_uid(unit_uid)
	if u == null or u.side != "p" or u.is_token or u.custom_state.has("phantom") or u.hp <= 0 or not u.has_rolled():
		return "no_die"
	if wild_used >= wild_per_battle():
		return "limit"
	if u.roll_used():
		return "used"
	if u.held:
		return "held"
	if u.cracked:
		return "cracked"
	if _has_kw(u.current_face(), "cantrip"):
		return "cantrip"
	if u.wild_slot >= 0:
		return "wild"
	if u.overcast:
		return "overcast"  # MD review: an Overcast die keeps its face (the +add is locked on the Set)
	if slot == u.roll_face_index():
		return "same"
	if not _bo_dice().has(u):
		return "not_counted"
	if mana < wild_cost():
		return "mana"
	# n >= 3 after attaching (otherwise it is useless and refused, mana untouched)
	u.wild_slot = slot
	var n := 0
	for d in _bo_dice():
		if (d.wild_slot if d.wild_slot >= 0 else d.roll_face_index()) == slot:
			n += 1
	u.wild_slot = -1
	if n < 4:
		return "need_set3"  # MD 22/10: only 3 -> 4 (a pair would become a 3: refused)
	if n >= 5:
		return "set5"  # A+ (Liam 22/10): Wild Face can never make a Set of 5
	return ""


func can_wild_face(unit_uid: int, slot: int) -> bool:
	return wild_block_reason(unit_uid, slot) == ""


## Pays wild.cost mana; the die counts as part `slot` for Sets this turn (its real face is unchanged). Undoable, no rng.
## Logged as `wild_face [uid, slot]`. Retakes the Set snapshot.
func wild_face(unit_uid: int, slot: int) -> bool:
	if not can_wild_face(unit_uid, slot):
		return false
	var u := by_uid(unit_uid)
	_push_undo()
	mana -= wild_cost()
	wild_used += 1
	u.wild_slot = slot
	_snap_bo()
	EventBus.float_text.emit(u.uid, "WILD", "buf", 0)
	EventBus.die_wild.emit(u.uid, slot)
	_log("wild_face", [unit_uid, slot])
	return true


## UI preview of Mat Tam ("-> BO BA x1.4"): what the Set groups would be if `uid` took part `slot`. Pure: no state change, no event, no rng.
## Returns {ok, reason (wild_block_reason), bo_label ("" when no Set, else "BỘ BA/BỐN/NĂM"), mult (M of the die's group, 1.0 = none), groups (hypothetical bo)}.
func preview_wild(unit_uid: int, slot: int) -> Dictionary:
	var out := {"ok": false, "reason": wild_block_reason(unit_uid, slot), "bo_label": "", "mult": 1.0, "groups": []}
	out["ok"] = out["reason"] == ""
	var u := by_uid(unit_uid)
	if u == null or u.side != "p" or slot < 0 or slot >= 6:
		return out
	var was := u.wild_slot
	u.wild_slot = slot
	var groups := recompute_bo()
	u.wild_slot = was
	out["groups"] = groups
	for g in groups:
		if (g["uids"] as Array).has(unit_uid):
			out["mult"] = float(bo_group_m100(g)) / 100.0
			out["bo_label"] = {3: "BỘ BA", 4: "BỘ BỐN", 5: "BỘ NĂM"}[int(g["size"])]
			break
	return out


# ---- Overcast (lane OC): pay mana to power ONE die up this turn ---------------------------------------------
func overcast_cost() -> int:
	if anchor_awakened and anchor_id == "a_mana_mine" and overcast_used >= 1:
		return maxi(0, int(tune_knob("anchor", "beat_cost2", 2.0)))   # Double Beat: the second Overcast of the turn
	if anchor_id == "a_mana_mine" and bool(anchor_turn.get("mine", false)):
		return maxi(0, int(tune_knob("anchor", "mine_overcast_cost", 1.0)))
	return maxi(0, int(tune_knob("overcast", "mana_cost", 3.0)))


## Depth v4 3.7: Overcast adds this to the M bag (knob overcast.add, default 0.5). No own multiplier any more.
func overcast_add() -> float:
	return maxf(0.0, tune_knob("overcast", "add", 0.5))


## DEPRECATED shim for the old UI tooltip ("x1.5"): 1 + overcast_add(). The UI step should show the preview instead.
func overcast_mult() -> float:
	return 1.0 + overcast_add()


func overcast_per_turn() -> int:
	if anchor_awakened and anchor_id == "a_mana_mine":
		return maxi(0, int(tune_knob("anchor", "beat_per_turn", 2.0)))   # Double Beat
	return maxi(0, int(tune_knob("overcast", "per_turn", 1.0)))


func overcast_count() -> int:
	return overcast_used


## Pure: uids of the Set (snapshot `bo`, size >= 3) the die belongs to right now, else []. Overcast hits all of them (MD 22/10).
func overcast_set_uids(u: Unit) -> Array:
	for g in bo:
		if (g["uids"] as Array).has(u.uid):
			return (g["uids"] as Array).duplicate()
	return []


## "" when the die can be overcast now, else a short reason (the UI shows it on the disabled button).
func overcast_block_reason(unit_uid: int) -> String:
	if won or lost or phase != CombatPhase.EXECUTE:
		return "Not your turn"
	var u := by_uid(unit_uid)
	if u == null or u.side != "p" or u.is_token or u.custom_state.has("phantom") or u.hp <= 0 or not u.has_rolled():
		return "No die"
	if depth_stage < 3:
		return "Not unlocked yet"
	if u.roll_used():
		return "Die already used"
	if u.held:
		return "Die is held"
	if u.frozen:
		return "Die is frozen"
	if u.overcast and not _anchor_can_stack_oc(u):
		return "Already overcast"
	if overcast_used >= overcast_per_turn():
		return "1 Overcast per turn"
	if _has_kw(u.current_face(), "cantrip") or not BO_TYPES.has(String(u.current_face().get("type", ""))):
		return "Not on this face"
	if _face_base(u, u.roll_face_index()) < 1.0:
		return "Face has no value"
	if overcast_set_uids(u).is_empty():
		return "Needs a Set"
	if mana < overcast_cost():
		return "Needs %d mana" % overcast_cost()
	return ""


func can_overcast(unit_uid: int) -> bool:
	return overcast_block_reason(unit_uid) == ""


## Pays overcast_cost() mana and powers up the WHOLE Set the die is in (the Set at this moment) for this turn: every member gets the
## `overcast` flag (+overcast.add in its M bag). Undoable. Logged as `overcast [uid]`. No rng.
func overcast(unit_uid: int) -> bool:
	if not can_overcast(unit_uid):
		return false
	var u := by_uid(unit_uid)
	var members: Array = overcast_set_uids(u)
	_push_undo()
	var before := _face_value(u, u.roll_face_index())
	var stack := u.overcast   # only legal through Double Beat (overcast_block_reason)
	mana -= overcast_cost()
	overcast_used += 1
	for m in members:
		var d := by_uid(int(m))
		if d != null:
			if stack:
				(anchor_turn["oc2"] as Array).append(d.uid)
			d.overcast = true
	var after := _face_value(u, u.roll_face_index())
	for m in members:
		EventBus.float_text.emit(int(m), "OVERCAST", "buf", 0)
	EventBus.die_overcast.emit(u.uid, before, after)
	_log("overcast", [unit_uid])
	return true


## Group preview for the UI: one {uid, now, boosted} per die of the Set `u` is in (u first), values of each die's current face.
func overcast_group_preview(u: Unit) -> Array:
	var out: Array = []
	var uids: Array = overcast_set_uids(u)
	uids.sort_custom(func(a, b): return int(a) == u.uid and int(b) != u.uid)
	for m in uids:
		var d := by_uid(int(m))
		if d == null:
			continue
		var pv := overcast_preview(d)
		out.append({"uid": d.uid, "now": pv[0], "boosted": pv[1]})
	return out


## For the UI preview ("6 -> 9"): [value now, value if overcast] of the die's current face.
func overcast_preview(u: Unit) -> Array:
	var fi := u.roll_face_index()
	var was := u.overcast
	var now := _face_value(u, fi)
	u.overcast = true
	var boosted := _face_value(u, fi)
	u.overcast = was
	return [now, boosted]


## Free undo within a turn, until reroll or a new turn clears the stack (rule spec §2).
## Snapshot-restore-in-place (architecture plan §4b) — NOT action-replay.
func undo_last() -> bool:
	if undo_stack.is_empty():
		return false
	var snap: Dictionary = undo_stack.pop_back()
	var keep_lock := reroll_lock.duplicate(true)   # 3.10.2: undo rewinds reroll_k but never the lock
	if _impact_at.has(undo_stack.size()):
		RunState.core_impact = (_impact_at[undo_stack.size()] as Dictionary).duplicate(true)
	_apply_state_dict(snap)
	reroll_lock = keep_lock
	_log("undo_last", [])
	return true


func _exec_face(u: Unit, target_uid: int) -> bool:
	var fi := u.roll_face_index()
	if fi < 0 or u.roll_used():
		return false
	var f: Dictionary = u.die[fi]
	if String(f.get("type", "")) == "blank":
		return false
	if u.side == "p" and String(f.get("type", "")) == "dmg" and bool(RelicHooks.run_value_hook(self, "face_blocked", {"combat": self, "unit": u}, false)):
		return false   # Rebound Core: the top-Thorns Axie cannot use damage faces

	var embers_last := u.side == "p" and _mut_embers_add100(u) > 0
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
	RelicHooks.fire(self, "on_face_used", {"combat": self, "unit": u, "face": f, "fi": fi,
		"target_uid": target_uid, "side": u.side, "depth": 0})   # H2
	if u.side == "p":
		if embers_last:
			_mut_emit("h_embers", u.uid, roundi(float(_mut_knob("h_embers", "mult", 0.0)) * 100.0))
		_anchor_volley_use(u)
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


## depth v3 lane FX: true only while _do_face computes the value it applies, so Core face_final handlers fire
## EventBus.core_fired for real uses and stay silent for UI previews / forecasts.
var core_emit: bool = false


const BO_TYPES := ["dmg", "shield", "heal", "poison"]   # the face types the M bag multiplies (design 3.4)
const CRACK_TYPES := ["dmg", "shield", "heal", "poison", "mana"]   # faces that carry a number: Crack halves them (design 3.4 step 2)


## Steps 1-3 of design 3.4 (base value, Crack, R12 / CONDUIT flat adds). Returns -1.0 for a blinded attack (value 0, no hooks).
## This is `v0` for the Overcast check (v0 >= 1).
func _face_base(u: Unit, fi: int) -> float:
	var f: Dictionary = u.die[fi]
	var v: float = float(f.get("value", 0)) + float(u.get_growth(fi))
	if _has_kw(f, "vital") and u.hp == u.max_hp:
		v *= 2.0
	var face_type := String(f.get("type", ""))
	if face_type == "dmg":
		if int(u.status.get("blind", 0)) > 0:
			return -1.0
		if int(u.status.get("weaken", 0)) > 0:
			v = max(0.0, v - int(u.status["weaken"]))
		if u.overdrive:
			v = ceil(v * 1.5)
		if u.side == "p" and RelicHooks.has(self, "hiveMind"):
			v += RelicHooks.sum(self, "hiveMind") * _count_alive_tokens(party)
		if u.side == "e":
			# base x (1 + enrage% + attrition%) x spike, rounded half up (monetization-v1 §1.2).
			v = float(RulesMath.round_half_up(v * enemy_dmg_factor(u) * boss_hollow_dealt_mult(u) * affix_dealt_mult(u) * CombatTraits.charge_mult(u)))
	if u.cracked and u.side == "p" and v >= 1.0 and CRACK_TYPES.has(face_type):
		v = ceil(v / maxf(1.0, tune_knob("crack", "value_div", 2.0)))   # step 2: Crack (v >= 1 stays >= 1)
	var sfb := CombatTraits.side_face_bonus(self, u, face_type, v)
	if core_emit and sfb > 0 and CoreHooks.RelicHooks_has(self, "rule_hard_shell"):
		CoreHooks.fire("rule_hard_shell", u.uid, sfb, face_type)
	v += sfb                                                                # R12 Vo Cung: +2 on shield / poison faces of the Axie
	if face_type == "mana" and u.side == "p" and u.cls == "aqua":
		v += 1.0                                                        # CONDUIT passive
	return v


func _face_value(u: Unit, fi: int) -> int:
	var f: Dictionary = u.die[fi]
	var face_type := String(f.get("type", ""))
	var v: float = _face_base(u, fi)
	if v < 0.0:
		return 0
	# Step 4: the M bag, one integer multiply (design 3.4). Never on mana / debuff / summon / blank.
	if u.side == "p" and BO_TYPES.has(face_type):
		var m100 := m100_for(u)
		if m100 > 100:
			v = float(_mul_up(int(v), m100))
	if u.side == "p" and u.resonant_now:
		v = ceil(v * RESONANCE_MULT)
	var fv := int(RelicHooks.run_value_hook(self, "face_final", {"combat": self, "unit": u, "face_type": face_type, "part": String(f.get("part", "")), "fi": fi}, int(v)))
	if u.side == "p" and face_type == "poison":
		fv = mini(fv, int(tune_knob("poison", "face_cap", 8.0)))   # v4 3.10.7: a player poison face never exceeds poison.face_cap (after M and Cores, before the pipeline)
	return fv


@warning_ignore("integer_division")
static func _mul_up(v: int, m100: int) -> int:
	return (v * m100 + 99) / 100


## M bag of a die in percent (100 = x1.00): 100 + its Set add (from the snapshot) + Overcast add, clamped to [100, bo.m_cap].
## Core adds (design 10) are not done yet.
func m100_for(u: Unit) -> int:
	if u.side != "p":
		return 100
	var add := 0
	for g in bo:
		if (g["uids"] as Array).has(u.uid):
			add += int(g["m100"]) - 100 + _anchor_set_add100() + _mut_embers_add100(u)
			break
	if u.overcast:
		add += roundi(overcast_add() * 100.0)
		if (anchor_turn.get("oc2", []) as Array).has(u.uid):
			add += roundi(overcast_add() * 100.0)   # Double Beat: the second Overcast on the same Set stacks
	return clampi(100 + add, 100, bo_cap100())


## Group M x100 including the Anchor's Set add (Volley price / Gambler bonus), clamped like m100_for. For previews/UI; excludes the
## per-die parts (Overcast, Last Strike) that depend on which die is asked about.
func bo_group_m100(g: Dictionary) -> int:
	return clampi(int(g["m100"]) + _anchor_set_add100(), 100, bo_cap100())


## ---- Anchor base rules + awakenings (production/anchor-2b-brief.md) ---------------------------------------------
static func _anchor_turn_fresh() -> Dictionary:
	return {"gb100": 0, "mine": false, "sw_used": false, "vol_fired": false, "vol_uids": [], "vol_dmg": 0, "vol2": false, "oc2": [], "cr_n": 0, "safe_n": 0}


static func _anchor_turn_from_data(raw) -> Dictionary:
	var out := _anchor_turn_fresh()
	if not (raw is Dictionary):
		return out
	var d: Dictionary = raw
	out["gb100"] = int(d.get("gb100", 0))
	for k in ["mine", "sw_used", "vol_fired", "vol2"]:
		out[k] = bool(d.get(k, false))
	out["vol_dmg"] = int(d.get("vol_dmg", 0))
	out["cr_n"] = int(d.get("cr_n", 0))
	out["safe_n"] = int(d.get("safe_n", 0))
	for k in ["vol_uids", "oc2"]:
		var l: Array = []
		for x in (d.get(k, []) as Array):
			l.append(int(x))
		out[k] = l
	return out


## Percent added to a SET member's M by the Anchor right now (Volley price, Gambler clean-Gamble bonus). 0 without an Anchor.
func _anchor_set_add100() -> int:
	if anchor_id == "a_volley":
		return -roundi(tune_knob("anchor", "volley_set_add", 0.15) * 100.0)
	if anchor_id == "a_gambler":
		return int(anchor_turn.get("gb100", 0))
	return 0


## Double Beat: an already-overcast die may be overcast again once (a second stack on the same Set).
func _anchor_can_stack_oc(u: Unit) -> bool:
	return anchor_awakened and anchor_id == "a_mana_mine" and overcast_used == 1 and not (anchor_turn.get("oc2", []) as Array).has(u.uid)


## Mana Mine: a natural SET on the first roll of the turn gives +1 mana and cheap Overcast. Called at the end of roll_all (no wild yet).
func _anchor_mine_roll() -> void:
	if anchor_id != "a_mana_mine" or bo.is_empty():
		return
	anchor_turn["mine"] = true
	var gain := int(tune_knob("anchor", "mine_mana", 1.0))
	mana += gain
	var allies := alive_party()
	CoreHooks.fire(anchor_id, (allies[0] as Unit).uid if not allies.is_empty() else 0, gain, "mana")


## Gambler: called once per Gamble (Lieu) after the Crack draws. `n` = dice rerolled, `cracked` = uids that cracked.
## Clean Gamble (n >= 2, no Crack) raises every SET this turn (cap). Second Wind (awakened): rerolls the Cracked dice free, once a turn.
func _anchor_after_gamble(n: int, cracked: Array, use_seed: int) -> void:
	if anchor_id != "a_gambler":
		return
	if cracked.is_empty():
		if n >= 2:
			var cap := roundi(tune_knob("anchor", "gambler_turn_cap", 0.60) * 100.0)
			var step := roundi(tune_knob("anchor", "gambler_set_add", 0.30) * 100.0)
			var before := int(anchor_turn["gb100"])
			anchor_turn["gb100"] = mini(cap, before + step)
			if int(anchor_turn["gb100"]) > before:
				CoreHooks.fire(anchor_id, 0, int(anchor_turn["gb100"]) - before, "rule")
		return
	if not anchor_awakened or bool(anchor_turn["sw_used"]):
		return
	anchor_turn["sw_used"] = true
	# Second Wind: own seed derived from this Gamble's epoch seed (seed ^ (k+1)); no new epoch request, no crack draws.
	if use_seed >= 0:
		_rng = Rng.new(use_seed ^ (reroll_k + 1))
	reroll_k += 1
	reroll_lock[reroll_k] = {"rmode": 0, "rsrc": 2, "uids": _int_list(cracked), "list": _int_list(cracked)}
	var redone: Array[int] = []
	for cu_id in cracked:
		var cu := by_uid(int(cu_id))
		if cu == null:
			continue
		cu.cracked = false
		_roll_unit(cu)
		redone.append(cu.uid)
	_resolve_cantrips()
	RelicHooks.fire(self, "on_roll_settled", {"combat": self, "rerolled_uids": redone})
	CoreHooks.fire(anchor_id, int(cracked[0]), redone.size(), "reroll")


## Volley: first die used from a SET of 3+ each turn fires the SET: all enemies take pct of the SET's base total (dmg faces only), max cap each.
## Thorn Storm (awakened): when the last die of that SET is used, it fires a second time and pierces enemy Shield (Plating still cuts).
func _anchor_volley_use(u: Unit) -> void:
	if anchor_id != "a_volley":
		return
	if not bool(anchor_turn["vol_fired"]):
		var grp: Dictionary = {}
		for g in bo:
			if (g["uids"] as Array).has(u.uid):
				grp = g
				break
		if grp.is_empty():
			return
		var total := 0
		for m in (grp["uids"] as Array):
			var d := by_uid(int(m))
			if d == null or d.roll_face_index() < 0:
				continue
			if String(d.die[d.roll_face_index()].get("type", "")) == "dmg":
				total += maxi(0, int(_face_base(d, d.roll_face_index())))
		var pct := int(tune_knob("anchor", "volley_pct_%d" % clampi(int(grp["size"]), 3, 5), {3: 30.0, 4: 55.0, 5: 80.0}[clampi(int(grp["size"]), 3, 5)]))
		var per := mini(int(tune_knob("anchor", "volley_cap", 16.0)), total * pct / 100)
		anchor_turn["vol_fired"] = true
		anchor_turn["vol_uids"] = (grp["uids"] as Array).duplicate()
		anchor_turn["vol_dmg"] = per
		_anchor_blast(u, per, false)
		return
	if not anchor_awakened or bool(anchor_turn["vol2"]):
		return
	if not (anchor_turn["vol_uids"] as Array).has(u.uid):
		return
	for m in (anchor_turn["vol_uids"] as Array):
		var d2 := by_uid(int(m))
		if d2 != null and d2.hp > 0 and not d2.roll_used():
			return   # not every SET die used yet
	anchor_turn["vol2"] = true
	_anchor_blast(u, int(anchor_turn["vol_dmg"]), true)


func _anchor_blast(u: Unit, per: int, pierce_shield: bool) -> void:
	if per <= 0:
		return
	var sum := 0
	for t in alive_enemies().duplicate():
		var v := float(per)
		if pierce_shield:
			v = CombatTraits.reduce(self, t, v)   # Plating (boss too) still blocks the pierce blast
		# attack:false = no Thorns back, no single-target Plating; src null = no source-side bonuses (burst damage)
		sum += DamagePipeline.resolve({"combat": self, "src": null, "tgt": t, "value": int(v), "pierce": pierce_shield,
			"attack": false, "face_type": "dmg", "from_burst": true})
	CoreHooks.fire(anchor_id, u.uid, sum, "dmg")


## ---- House mutations (houses.json; production/anchor-2b-brief.md) -----------------------------------------------
static func _house_tiers_from_data(raw) -> Dictionary:
	var out := {}
	if raw is Dictionary:
		for k in (raw as Dictionary).keys():
			if int(raw[k]) > 0:
				out[String(k)] = int(raw[k])
	return out


static func _anchor_fight_fresh() -> Dictionary:
	return {"kin": false, "fired": {}}


static func _anchor_fight_from_data(raw) -> Dictionary:
	var out := _anchor_fight_fresh()
	if raw is Dictionary:
		out["kin"] = bool(raw.get("kin", false))
		var f := {}
		for k in (raw.get("fired", {}) as Dictionary).keys():
			f[String(k)] = int(raw["fired"][k])
		out["fired"] = f
	return out


func _mut_tier(house_id: String) -> int:
	return int(house_tiers.get(house_id, 0))


## Knob of the house's current tier from houses.json (0 when the house has no mutation on).
func _mut_knob(house_id: String, key: String, default = 0):
	var t := _mut_tier(house_id)
	if t <= 0:
		return default
	var m: Dictionary = Anchors.get_house(house_id).get("mutation", {})
	var tier_d: Dictionary = m.get("tier%d" % t, {})
	if tier_d.has(key):
		return tier_d[key]
	var t1: Dictionary = m.get("tier1", {})   # tier 2 only lists what it changes
	return t1.get(key, default)


## A mutation did something: per-fight tally + the UI/stat event.
func _mut_emit(house_id: String, uid: int, amount: int) -> void:
	if amount <= 0:
		return
	var f: Dictionary = anchor_fight["fired"]
	f[house_id] = int(f.get(house_id, 0)) + amount
	CoreHooks.fire(house_id, uid, amount, "mutation")


func _in_bo(u: Unit) -> bool:
	for g in bo:
		if (g["uids"] as Array).has(u.uid):
			return true
	return false


## h_volley Spiked Shield: a Shield face from a SET die gives its recipient Thorns (1/3 of the value, rounded down, max 4 per Axie) until the end of the
## enemy turn. Tier 1 takes them off the Shield, tier 2 keeps the Shield whole. Returns the Shield to apply.
func _mut_spiked(u: Unit, t: Unit, v: int) -> int:
	if _mut_tier("h_volley") <= 0 or not _in_bo(u):
		return v
	var cur := int(t.custom_state.get("tmp_thorns", 0))
	var th := mini(v / maxi(1, int(_mut_knob("h_volley", "shield_div", 3))), maxi(0, int(_mut_knob("h_volley", "max", 4)) - cur))   # integer division; cap is per Axie per turn
	if th <= 0:
		return v
	t.custom_state["tmp_thorns"] = cur + th
	_mut_emit("h_volley", t.uid, th)
	return v if not bool(_mut_knob("h_volley", "shield_cost", true)) else maxi(0, v - th)


## h_gambler Crack Mana: the first N Cracks of a turn (N = per_turn of the tier) give mana.
func _mut_gamble(cracked: Array) -> void:
	if _mut_tier("h_gambler") <= 0:
		return
	for cu in cracked:
		if int(anchor_turn["cr_n"]) >= int(_mut_knob("h_gambler", "per_turn", 1)):
			break
		anchor_turn["cr_n"] = int(anchor_turn["cr_n"]) + 1
		var g := int(_mut_knob("h_gambler", "mana", 1))
		mana += g
		_mut_emit("h_gambler", int(cu), g)


## h_mana_mine Mana Overflow: end of the player turn (after Mana Pool / Mana Ward in on_turn_end), mana >= min: pay 1, every enemy takes dmg.
## Never on the winning turn (no enemy left standing). Once per turn by construction (end_turn runs once).
func _mut_overflow() -> void:
	if _mut_tier("h_mana_mine") <= 0 or won or lost or alive_enemies().is_empty():
		return
	if mana < int(_mut_knob("h_mana_mine", "min_mana", 3)):
		return
	mana -= int(_mut_knob("h_mana_mine", "cost", 1))
	var dmg := int(_mut_knob("h_mana_mine", "dmg", 2))
	var sum := 0
	for t in alive_enemies().duplicate():
		sum += DamagePipeline.resolve({"combat": self, "src": null, "tgt": t, "value": dmg, "attack": false, "face_type": "dmg", "from_burst": true})
	var al := alive_party()
	_mut_emit("h_mana_mine", (al[0] as Unit).uid if not al.is_empty() else 0, maxi(sum, 1))


## h_kin Cover: the first turn of the fight that shows a SET, the front-row Axie with the least HP (Egg included) gets Shield per SET die.
func _mut_kin() -> void:
	if _mut_tier("h_kin") <= 0 or bool(anchor_fight["kin"]) or bo.is_empty():
		return
	var best: Unit = null
	for p in alive_party():
		var pu := p as Unit
		if row_of(pu) != 0:
			continue
		if best == null or pu.hp < best.hp or (pu.hp == best.hp and pu.uid < best.uid):
			best = pu
	if best == null:
		return
	anchor_fight["kin"] = true
	var amt := int(_mut_knob("h_kin", "shield_per_die", 2)) * int((bo[0] as Dictionary)["uids"].size())
	DamagePipeline.apply_shield(self, best, amt)
	_mut_emit("h_kin", best.uid, amt)


## h_embers Last Strike: percent added to the M of the SET die that is the last one used this turn (inside m100_for, so under m_cap).
func _mut_embers_add100(u: Unit) -> int:
	if _mut_tier("h_embers") <= 0 or u.side != "p" or not _in_bo(u):
		return 0
	if not CoreHooks.is_finisher(self, u):
		return 0
	return roundi(float(_mut_knob("h_embers", "mult", 0.0)) * 100.0)


## h_big_hand Hunt Four: on a turn whose only SET is exactly three dice, the first paid Safe reroll is free (tier 1) and the second costs
## at most 1 (tier 2). Counted by anchor_turn.safe_n (paid Safe rerolls this turn; still counts toward reroll.max_total).
func _mut_safe_price(c: int) -> int:
	if _mut_tier("h_big_hand") <= 0 or bo.size() != 1 or int((bo[0] as Dictionary)["size"]) != 3:
		return c
	var n := int(anchor_turn.get("safe_n", 0))
	if n == 0:
		return maxi(0, c - c * int(_mut_knob("h_big_hand", "free_safe", 1)))
	if n == 1 and _mut_tier("h_big_hand") >= 2:
		return mini(c, int(_mut_knob("h_big_hand", "second_safe_cost", 1)))
	return c


func bo_cap100() -> int:
	return maxi(100, roundi(tune_knob("bo", "m_cap", 3.0) * 100.0))


## Set add in percent for a group of `size` dice: round(add_N * scale * 100) (design 3.4, N11: each term rounded once).
func bo_add100(size: int) -> int:
	var n := clampi(size, 3, 5)
	var def := {3: 0.3, 4: 1.2, 5: 1.6}[n] as float
	return roundi(tune_knob("bo", "add_%d" % n, def) * tune_knob("bo", "scale", 1.0) * 100.0)


## Pure: the dice that count toward Sets right now (3.2 + Concord filter, before wild_slot is applied), in party order.
func _bo_dice() -> Array:
	var out: Array = []
	if int(tune_knob("bo", "enabled", 1.0)) == 0:
		return out
	var concord := bool(RelicHooks.run_value_hook(self, "roll_share_class", {"combat": self}, false))
	var phantom_ok := int(tune_knob("bo", "phantom_counts", 0.0)) != 0
	var seen_cls := {}
	for u in party:
		if u.side != "p" or u.is_token or u.hp <= 0 or not u.has_rolled() or u.custom_state.has("asleep"):
			continue
		if u.custom_state.has("phantom") and not phantom_ok:
			continue
		if u.custom_state.has("copycat_turn") and int(u.custom_state["copycat_turn"]) == turn:
			continue   # meme Core Copycat: the copied die does not count toward Sets
		if u.cracked or String((u.die[u.roll_face_index()] as Dictionary).get("type", "")) == "blank":
			continue
		if concord and u.cls != "":
			if seen_cls.has(u.cls):
				continue
			seen_cls[u.cls] = true
		out.append(u)
	return out


## Pure: the Set groups for the CURRENT faces (design 3.2). Does not touch state. Concord (hook roll_share_class): per class only the
## first eligible die of `party` counts, filtered BEFORE wild_slot is applied.
func recompute_bo() -> Array:
	var by_part := {}   # part index -> [Unit]
	for u in _bo_dice():
		var part: int = u.wild_slot if u.wild_slot >= 0 else u.roll_face_index()
		if not by_part.has(part):
			by_part[part] = []
		(by_part[part] as Array).append(u)
	var out: Array = []
	var hi_r := int(tune_knob("part", "hi_r", 2.0))
	var hi_add := roundi(tune_knob("part", "hi_add", 0.25) * 100.0)
	for part in by_part:
		var us: Array = by_part[part]
		if us.size() < 3:
			continue
		var hi := false
		if depth_stage >= 3 and hi_add > 0:
			for u in us:
				if int((u.die[u.roll_face_index()] as Dictionary).get("rarity", 0)) >= hi_r:
					hi = true
					break
		var uids: Array = []
		for u in us:
			uids.append(u.uid)
		var m := 100 + bo_add100(us.size()) + (hi_add if hi else 0)
		out.append({"part": int(part), "size": us.size(), "uids": uids, "hi": hi, "m100": clampi(m, 100, bo_cap100())})
	return out


## Keeps the fight's best Set ({part,size,m100}) in `stat["best_bo"]` (Result screen "Best set"; display only).
func _note_best_bo() -> void:
	for g in bo:
		stat["best_bo"] = RunStatsAccumulator.better_bo(stat.get("best_bo", {}) as Dictionary, g as Dictionary)


## Takes the snapshot (the only writer of `bo` besides roll_all's reset and load) and tells the UI when it changed.
func _snap_bo() -> void:
	var nb := recompute_bo()
	if JSON.stringify(nb) == JSON.stringify(bo):
		_mut_kin()
		return
	bo = nb
	_note_best_bo()
	EventBus.bo_changed.emit(_dup_dict_array(bo))
	_mut_kin()


static func _bo_from_data(raw: Array) -> Array:
	var out: Array = []
	for g in raw:
		var uids: Array = []
		for x in (g["uids"] as Array):
			uids.append(int(x))
		out.append({"part": int(g["part"]), "size": int(g["size"]), "uids": uids, "hi": bool(g["hi"]), "m100": int(g["m100"])})
	return out


## UI preview (design 8.6 item 7, "4 -> 1"): what die face `fi` of `src` would do to `target` as a single-target hit,
## WITHOUT touching state, events or rng. raw = face value (+ the once-per-turn first-dmg bonus), after = raw after
## vulnerable, the boss hollow turn and Plating (the same steps and order as DamagePipeline.resolve 6, 6b, 6c).
## Includes the pierce bonus (bird talon, piercePlus). Not covered: crit, exec/feral, Core mod_dmg hooks, shield absorb (shown by the UI from target.shield).
## Returns {raw, after, plating (P that counted, 0 = none), single (Plating applies at all), shield (target shield)}.
func preview_damage(src: Unit, target: Unit, fi: int) -> Dictionary:
	# Core hooks create their combat_state buckets lazily on first read; a UI preview must not leave them behind
	# (the replay never calls it, so a leftover empty bucket would make the digests differ).
	var rc_before := relic_combat.duplicate(true)
	CoreHooks.mute += 1   # a preview never counts as a Core firing
	var out := _preview_damage(src, target, fi)
	CoreHooks.mute -= 1
	relic_combat = rc_before
	return out


func _preview_damage(src: Unit, target: Unit, fi: int) -> Dictionary:
	if src == null or target == null or fi < 0 or fi >= src.die.size():
		return {"raw": 0, "after": 0, "plating": 0, "single": false, "shield": 0}
	var f: Dictionary = src.die[fi]
	var raw := _face_value(src, fi)
	if src.side == "p" and first_dmg_face_bonus > 0 and not _first_dmg_used \
			and String(f.get("type", "")) == "dmg" and raw > 0:
		raw += first_dmg_face_bonus
	var attack := String(f.get("type", "")) == "dmg"
	var pierce := _has_kw(f, "pierce") or (src.side == "p" and src.cls == "bird" and _has_kw(f, "aoe"))
	var single := attack and not pierce and not _has_kw(f, "aoe")
	var v := float(raw)
	if pierce and src.side == "p":
		v += (RelicHooks.field(self, "talon_pierce", 3.0) if src.cls == "bird" else 0.0) + RelicHooks.sum(self, "piercePlus")   # pipeline step 2
	if v <= 0.0:
		return {"raw": raw, "after": 0, "plating": 0, "single": single, "shield": target.shield}
	if int(target.status.get("vulnerable", 0)) > 0:
		v = ceil(v * 1.5)
	if target.is_boss and attack:
		v = ceil(v * boss_hollow_taken_mult(target))
	var p := 0
	if single and target.side == "e":
		var plated := CombatTraits.reduce(self, target, v)
		if plated < v:
			p = CombatTraits.plating_of(self, target)
		v = plated
	return {"raw": raw, "after": int(v), "plating": p, "single": single, "shield": target.shield}


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
	core_emit = true
	var v := _face_value(u, fi)
	core_emit = false
	if u.side == "p" and not is_echo and first_dmg_face_bonus > 0 and not _first_dmg_used \
			and String(f.get("type", "")) == "dmg" and v > 0:
		v += first_dmg_face_bonus   # flat, after everything else; once per turn
		_first_dmg_used = true
	var tgt: Unit = (by_uid(target_uid) if target_uid >= 0 else null)
	var crit: bool = u.roll_crit_now()
	var face_type := String(f.get("type", ""))
	var kw_pure := CombatTraits.side_bonus_keywords(self, u, face_type, _pure_keywords(f))   # R12: debuff magnitudes +2
	if face_type == "debuff" and CoreHooks.RelicHooks_has(self, "rule_hard_shell"):
		var raised := 0   # Hard Shell: the +2 on each numeric debuff keyword is a real effect, report it
		var base_kw := _pure_keywords(f)
		for ki in mini(base_kw.size(), kw_pure.size()):
			if str(base_kw[ki]) != str(kw_pure[ki]):
				raised += int(str(kw_pure[ki]).split(":")[1]) - int(str(base_kw[ki]).split(":")[1])
		CoreHooks.fire("rule_hard_shell", u.uid, raised, "debuff")

	var ctx_n := [0, false]   # [hits so far, secondary-target mode] for the on_face_hit hook (FACE_CTX)
	var hit := func(t: Unit, amount: int) -> int:
		var pierce: bool = _has_kw(f, "pierce") or (u.side == "p" and u.cls == "bird" and _has_kw(f, "aoe"))
		var single: bool = not pierce and not _has_kw(f, "aoe") and not bool(ctx_n[1])
		var d: int = DamagePipeline.resolve({
			"combat": self, "src": u, "tgt": t, "value": amount, "pierce": pierce, "attack": true,
			"crit": crit, "exec": _has_kw(f, "exec"), "face_type": "dmg", "resonant": u.resonant_now,
			"single": single,
		})
		if single and u.side == "p":
			CombatTraits.on_single_hit(self, u, t)
		if _has_kw(f, "lifesteal") and d > 0:
			DamagePipeline.apply_heal(self, u, d)
		if kw_pure.size() > 0 and d >= 0:
			StatusEngine.add_status(self, t, kw_pure, u)
		ctx_n[0] = int(ctx_n[0]) + 1
		RelicHooks.fire(self, "on_face_hit", {"combat": self, "unit": u, "face": f, "tgt": t, "crit": crit,
			"dealt": d, "aoe": _has_kw(f, "aoe"), "secondary": bool(ctx_n[1]), "pierce": pierce, "first": int(ctx_n[0]) == 1})
		return d

	if face_type == "dmg":
		if _has_kw(f, "aoe"):
			ctx_n[1] = true
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
					ctx_n[1] = true
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
			var sv := v
			if u.side == "p":
				sv = _mut_spiked(u, t, v)
			DamagePipeline.apply_shield(self, t, sv)
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
					RelicHooks.fire(self, "on_egg_hatched", {"combat": self, "egg": a})
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

## END TURN, in one call. Unchanged behaviour, and the ONLY entry point for anything that is
## not pacing the enemy phase on screen: the tutorial, the run verifier, the bot and every test
## call this and see exactly what they always saw.
##
## SPLIT 2026-09-21 into begin/step/finish (below) so CombatView can put a gap between enemies
## and let each one's attack animation play. The engine gained no timing and no `await`: it
## still resolves everything the instant it is asked to, and this wrapper still does the whole
## turn inside one call stack. What changed is that the CALLER may now drive the loop itself.
##
## Making `end_turn()` itself a coroutine was the obvious alternative and is the wrong one. It
## would turn nineteen synchronous call sites into nineteen places that must remember to
## `await`, and one of them is `run_verifier.gd` — a referee that replays a log frame-free and
## must not start depending on the scene tree's clock to reach a verdict.
func end_turn(seed: int = -1) -> void:
	if not begin_end_turn(seed):
		return
	# Index, not a snapshot of uids, and `enemies.size()` re-read every pass — see
	# step_end_turn_action()'s comment for the summon case that makes the difference.
	var i := 0
	while i < enemies.size():
		if not step_end_turn_action(i):
			break
		i += 1
	finish_end_turn()


## Whether end_turn() would do anything. Public because the view needs the same answer to
## decide whether to start pacing a phase at all, and a second copy of the condition there is
## how the two drift.
func can_end_turn() -> bool:
	return not won and not lost and phase != CombatPhase.END_TURN


## Phase 1 of 3 — everything that happens BEFORE the first enemy acts. Returns false when the
## call was rejected (already over, or already in END_TURN), in which case nothing moved and
## the caller must not go on to step or finish.
func begin_end_turn(seed: int = -1) -> bool:
	if not can_end_turn():
		return false
	# Epoch boundary (see reroll_dice): enemy phase + next turn's rolls + intents draw from `seed`.
	var use_seed := seed
	if use_seed < 0 and _epoch != null:
		var r := _epoch.request("end_turn", _end_turn_args())
		if not r.ok:
			push_error("CombatEngine.begin_end_turn: epoch refused (%s)" % r.code)
			return false
		use_seed = r.seed
	if use_seed >= 0:
		_rng = Rng.new(use_seed)
	_log("end_turn", [])
	_set_turn_phase(CombatPhase.END_TURN)
	undo_stack = []
	first_used = false
	RelicHooks.fire(self, "on_turn_end", {"combat": self})   # H3
	_drop_phantoms()   # Sixth Die vanishes at end of turn
	_mut_overflow()

	# mana overflow (relic OR mythic `overflow` face) — no-op today: no relic and no
	# ported tier-1 face carries `overflow`. Kept so wiring either in later is content-only.
	if mana > 0 and (RelicHooks.has(self, "manaOverflow") or _any_die_has_keyword(party, "overflow")):
		var v := mana
		var src: Unit = (alive_party()[0] if alive_party().size() > 0 else null)
		for t in alive_enemies().duplicate():
			DamagePipeline.resolve({"combat": self, "src": src, "tgt": t, "value": v, "attack": false})
		EventBus.float_text.emit((src.uid if src != null else 0), "OVERFLOW %d" % v, "man", 1)
		mana = 0
	CombatTraits.enemy_phase_start(self)
	return true


## Phase 2 of 3 — resolve the enemy sitting at `index` in `enemies`, and answer "keep going?".
## One call, one enemy, no timing of its own; the caller decides how long to wait before the
## next one.
##
## BY INDEX, NOT BY UID, AND THE CALLER RE-READS `enemies.size()` EVERY PASS. This is the whole
## fidelity question of the split. The loop it replaces was `for e in enemies`, and GDScript
## re-reads an Array's size on every iteration — so an enemy SUMMONED by an earlier enemy this
## same phase is reached and acts in the same turn. Handing the caller a list of uids taken
## before the first enemy moved would quietly drop that summon: same inputs, different run,
## which is exactly the kind of "refactor" this project's RULES_VERSION gate exists to catch.
## Indices survive an append; a snapshot does not.
##
## Every guard below is the original loop body's, in the original order, including WHERE the
## party-wipe check sits: only a real `_exec_face()` can end the phase early. A skipped enemy
## (dead, or with no intent) and a stunned one both return true exactly as the old `continue`
## did, so an enemy killed by an earlier enemy's thorns is passed over identically.
func step_end_turn_action(index: int) -> bool:
	if phase != CombatPhase.END_TURN or index < 0 or index >= enemies.size():
		return true
	var e: Unit = enemies[index]
	if e.hp <= 0 or e.intent.is_empty():
		return true
	EventBus.enemy_intent_executed.emit(e.uid)
	if int(e.status.get("stun", 0)) > 0:
		e.status["stun"] = 0
		EventBus.float_text.emit(e.uid, "STUNNED", "deb", 0)
		CombatTraits.charge_on_stun(self, e)
		return true
	if String(e.intent.get("charge", "")) == "start":
		return true                             # charge turn: the elite gathers power, no attack (M5)
	var charge_value := -1
	var charge_tgt := int(e.intent.get("target_uid", -1))
	if String(e.intent.get("charge", "")) == "hit":
		charge_value = _face_value(e, e.roll_face_index())
	var hp_before := {}
	if int(_aff(e).get("poison_on_pierce", 0)) > 0:
		for pu in party:
			hp_before[(pu as Unit).uid] = (pu as Unit).hp
	_exec_face(e, int(e.intent.get("target_uid", -1)))
	if charge_value >= 0:
		EventBus.charge_hit.emit(e.uid, charge_tgt, charge_value)
	_affix_fang(e, hp_before)
	# Rush: every Nth turn the elite acts twice (the same intent), announced a turn early via affix_state().
	if _affix_double_now(e) and e.hp > 0 and _any_real_party_alive():
		e.clear_used_for_second_action()
		_exec_face(e, int(e.intent.get("target_uid", -1)))
		_affix_fang(e, hp_before)
	return _any_real_party_alive()


## Phase 3 of 3 — the status tick, the end check, and the next turn's setup. Runs whether the
## phase ran to completion or broke early on a party wipe, which is what the original did too.
##
## The `phase` guard only catches a stray call: `_check_end()` never touches `phase`, so a win
## or a loss inside the enemy phase still arrives here with END_TURN set and still ticks status
## before returning — verified by reading _check_end(), not assumed.
func finish_end_turn() -> void:
	if phase != CombatPhase.END_TURN:
		return
	StatusEngine.tick_status(self)   # emits EventBus.status_tick once, at the end (see status_engine.gd)
	if _check_end():
		return

	turn += 1
	stat["turns"] = int(stat.get("turns", 0)) + 1
	rerolls = max_rerolls
	reroll_k = 0
	reroll_paid_k = 0
	reroll_total_turn = 0
	reroll_lock = {}
	_first_dmg_used = false
	used_actives = []
	chaos_reroll_given = 0
	relic_reroll_given = 0
	resonance_log = []
	for u in party:
		if u.frozen:
			u.frozen = false
	_affix_turn_start()
	spite_hits = {}
	CombatTraits.turn_start(self)
	EventBus.combat_clock_changed.emit(clock_state())
	EventBus.combat_attrition_changed.emit(attrition_state())
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


## ---- Depth v3 6.4 Elite affixes (data: assets/data/rules/elite_affixes.json) -----------------------------------
func _aff(e: Unit) -> Dictionary:
	if e == null or e.side != "e":
		return {}
	var out := {}
	for key in ["affix", "affix2"]:
		var id := String(e.custom_state.get(key, ""))
		if id != "" and ContentDB.elite_affixes.has(id):
			out.merge(ContentDB.elite_affixes[id] as Dictionary, true)
	return out


## The elite (enemy 0) of an elite fight carries the affix; shield / thorns are set before turn 1.
func _apply_affix_start() -> void:
	if kind != "elite" or affix == "" or not ContentDB.elite_affixes.has(affix) or enemies.is_empty():
		return
	var e: Unit = enemies[0]
	e.custom_state["affix"] = affix
	if affix2 != "" and ContentDB.elite_affixes.has(affix2):
		e.custom_state["affix2"] = affix2
	var a := _aff(e)
	if int(a.get("start_shield_pct", 0)) > 0:
		e.shield = int(round(float(e.max_hp) * float(a["start_shield_pct"]) / 100.0))
	if int(a.get("thorns", 0)) > 0:
		e.custom_state["permanent_thorns"] = int(a["thorns"])
	# 6.7b.6: an Elite with a group-A affix drops the trait of its own role (one anti-spam mechanic per fight).
	var in_a := false
	for id in [affix, affix2]:
		if String((ContentDB.elite_affixes.get(id, {}) as Dictionary).get("group", "")) == "A":
			in_a = true
	if in_a:
		e.custom_state.erase("m_trait")
		e.plating = 0
	if bool(a.get("iron", false)):
		e.plating = CombatTraits.plating_for_pw(pw) + int(tune_knob("plating", "iron_bonus", 1.0))   # Giap Sat = P+1, not R12+1
	if bool(a.get("spite", false)):
		e.custom_state["spite"] = true          # M3: replaces any old thorns of this unit (pipeline ignores its thorns)


func _affix_turn_start() -> void:
	for e in enemies:
		var perm := int((e as Unit).custom_state.get("permanent_thorns", 0))
		if perm > 0 and not (e as Unit).is_boss and (e as Unit).hp > 0 and String((e as Unit).custom_state.get("affix", "")) != "":
			(e as Unit).status["thorns"] = maxi(int((e as Unit).status.get("thorns", 0)), perm)


## Echo: the elite repeats last turn's face (rng draws unchanged; only the chosen face is replaced).
func _affix_echo(e: Unit) -> void:
	var a := _aff(e)
	if a.is_empty():
		return
	if bool(a.get("repeat_intent", false)) and e.custom_state.has("last_face"):
		e.set_roll(int(e.custom_state["last_face"]), false)
		e.heavy = _has_kw(e.die[e.roll_face_index()], "heavy")
	e.custom_state["last_face"] = e.roll_face_index()


## Damage multiplier an affix puts on an enemy's faces (echo -30%, frenzy +25% under the threshold).
func affix_dealt_mult(u: Unit) -> float:
	var a := _aff(u)
	if a.is_empty():
		return 1.0
	var m := 1.0 + float(a.get("dmg_pct", 0)) / 100.0
	var th := int(a.get("enrage_below_pct", 0))
	if th > 0 and u.hp * 100 < th * u.max_hp:
		m *= 1.0 + float(a.get("enrage_dmg_pct", 0)) / 100.0
	return m


func _affix_swarm() -> void:
	if kind != "elite" or won or lost or enemies.is_empty():
		return
	var e: Unit = enemies[0]
	var a := _aff(e)
	var th := int(a.get("summon_below_pct", 0))
	if th <= 0 or e.hp <= 0 or bool(e.custom_state.get("swarm_done", false)) or e.hp * 100 >= th * e.max_hp:
		return
	e.custom_state["swarm_done"] = true
	for _i in int(a.get("summon_count", 2)):
		var m := _mk_monster("slime", float(e.custom_state.get("sc", 1.0)) * float(a.get("summon_scale", 0.5)), {"hp": 1.0, "dmg": 1.0})
		_roll_unit(m)
		_pick_enemy_intent(m)
		enemies.append(m)
		EventBus.unit_spawned.emit(m.uid)
	EventBus.float_text.emit(e.uid, "SWARM", "deb", 1)


func _affix_chill() -> void:
	if enemies.is_empty():
		return
	var n := int(_aff(enemies[0]).get("freeze_first_turn", 0))
	for _i in n:
		var cands: Array = []
		for u in alive_party():
			if not u.frozen and not u.is_token:
				cands.append(u)
		if cands.is_empty():
			return
		var t: Unit = cands[_rng.next_int(cands.size())]
		t.frozen = true
		EventBus.float_text.emit(t.uid, "FROZEN", "deb", 0)


## Fang: poison only when the hit got through the shield (the target lost HP).
func _affix_fang(e: Unit, hp_before: Dictionary) -> void:
	var n := int(_aff(e).get("poison_on_pierce", 0))
	if n <= 0:
		return
	for pu in party:
		var u: Unit = pu
		if hp_before.has(u.uid) and u.hp > 0 and u.hp < int(hp_before[u.uid]):
			StatusEngine.add_status(self, u, ["poison:%d" % n], e)
			hp_before[u.uid] = u.hp


func _affix_double_now(e: Unit) -> bool:
	var p := int(_aff(e).get("double_turn_period", 0))
	return p > 0 and turn % p == 0


## For the UI: the affix of the elite and whether its special turn is now / next (announced one turn early).
func affix_state() -> Dictionary:
	if enemies.is_empty() or _aff(enemies[0]).is_empty():
		return {}
	var e: Unit = enemies[0]
	var p := int(_aff(e).get("double_turn_period", 0))
	var st := {"id": String(e.custom_state.get("affix", "")), "double_now": _affix_double_now(e),
		"double_next": p > 0 and (turn + 1) % p == 0}
	if String(e.custom_state.get("affix2", "")) != "":
		st["id2"] = String(e.custom_state.get("affix2", ""))
	if bool(_aff(e).get("charge", false)):
		# M5 tell for the UI: this turn is the charge / the strike, the next one is, and who is locked.
		st["charge_now"] = CombatTraits.is_charge_turn(turn)
		st["charge_next"] = CombatTraits.is_charge_turn(turn + 1)
		st["strike_now"] = String(e.intent.get("charge", "")) == "hit"
		st["charge_target"] = int(e.custom_state.get("charge_target", -1))
	return st


## ---- Depth v3 6.3 boss rhythm: a public 3-turn cycle, readable one turn ahead ---------------------------------
## Phase of boss `b` at `turn_count + ahead`. Turn 1 (count 0) is "prep". strike = count % period == 0 (this is
## where Mecha's OVERDRIVE and Plague Mother's brood already sat), hollow = the turn after, prep = the one before.
## "" for a non-boss, a boss with no rhythm (Agony runs its own two phases), or when combat_tune boss_rhythm.enabled = 0.
func boss_period() -> int:
	return maxi(2, int(RelicHooks.run_value_hook(self, "boss_period", {"combat": self}, maxi(3, int(tune_knob("boss_rhythm", "period", 3.0))))))


func boss_rhythm_phase(b: Unit, ahead: int = 0) -> String:
	if b == null or not b.is_boss or tune_knob("boss_rhythm", "enabled", 1.0) < 1.0:
		return ""
	if String(b.custom_state.get("trait", "")) == "phase":
		return ""
	var period := boss_period()
	var tc := int(b.custom_state.get("turn_count", 0)) + ahead
	if tc <= 0:
		return "prep"
	var m := tc % period
	return "strike" if m == 0 else ("hollow" if m == 1 else "prep")


## What the UI shows: this turn's phase, the NEXT one (the early tell), and turns until the strike.
func boss_rhythm_state(b: Unit) -> Dictionary:
	var ph := boss_rhythm_phase(b)
	if ph == "":
		return {}
	var to_strike := 0
	while to_strike < 12 and boss_rhythm_phase(b, to_strike) != "strike":
		to_strike += 1
	return {"phase": ph, "next": boss_rhythm_phase(b, 1), "turns_to_strike": to_strike,
		"trait": String(b.custom_state.get("trait", ""))}


func boss_is_hollow(b: Unit) -> bool:
	return b != null and boss_rhythm_phase(b) == "hollow"


## Damage the boss deals on a hollow turn (default x0.7).
func boss_hollow_dealt_mult(u: Unit) -> float:
	if u != null and u.is_boss and boss_rhythm_phase(u) == "strike":
		return float(RelicHooks.run_value_hook(self, "boss_strike_mult", {"combat": self}, 1.0))   # Quick Beat
	if not boss_is_hollow(u):
		return 1.0
	return 1.0 + tune_knob("boss_rhythm", "hollow_dealt_pct", -30.0) / 100.0


## Damage the boss takes from dmg faces on a hollow turn (default x1.3), read by DamagePipeline.
func boss_hollow_taken_mult(b: Unit) -> float:
	if not boss_is_hollow(b):
		return 1.0
	return 1.0 + tune_knob("boss_rhythm", "hollow_taken_pct", 30.0) / 100.0


## Strike turn: the boss rolls as usual (same rng draws) and then uses its strongest damage face.
func _apply_strike_face(e: Unit) -> void:
	if boss_rhythm_phase(e) != "strike" or bool(e.custom_state.get("charge_broken", false)):
		return                                  # a broken charge (stun on the prep turn) leaves a plain roll (M5)
	var best := -1
	var best_v := -1
	for i in e.die.size():
		var f: Dictionary = e.die[i]
		if String(f.get("type", "")) == "dmg" and int(f.get("value", 0)) > best_v:
			best_v = int(f.get("value", 0))
			best = i
	if best >= 0:
		e.set_roll(best, false)
		e.heavy = _has_kw(e.die[best], "heavy")


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
		var rphase := boss_rhythm_phase(b)       # depth v3 6.3: "prep" / "strike" / "hollow" / "" (no rhythm)
		if rphase != "":
			EventBus.float_text.emit(b.uid, rphase.to_upper(), "deb", 0)
			RelicHooks.fire(self, "on_boss_rhythm", {"combat": self, "boss": b, "phase": rphase,
				"next": boss_rhythm_phase(b, 1)})

		match String(b.custom_state.get("trait", "")):
			# MECHA CHIMERA — RETALIATE: thorns never wear off, and every 3rd turn it enters
			# OVERDRIVE (+50% damage, read by _face_value()).
			"thorns":
				var perm := int(b.custom_state.get("permanent_thorns", 0))
				# Hollow turn: the thorns shell is open (depth v3 6.3 tell).
				b.status["thorns"] = 0 if rphase == "hollow" else max(int(b.status.get("thorns", 0)), perm)
				if turn_count % boss_period() == 0:
					b.overdrive = true
					EventBus.float_text.emit(b.uid, "OVERDRIVE", "deb", 1)

			# PLAGUE MOTHER — BROOD: one add every 3 turns, up to addCap.
			"summon":
				if turn_count % boss_period() == 0 and int(b.custom_state.get("split_done", 0)) < add_cap:
					b.custom_state["split_done"] = int(b.custom_state.get("split_done", 0)) + 1
					spawn_boss_add(b, float(b.custom_state.get("sc", 1.0)))

			# FROST LORD — DEEP FREEZE: locks one un-frozen, non-token Axie's die out of the
			# reroll pool. Note it sets `frozen` directly, NOT `frozen_next`: the constraint
			# applies to the turn that is starting right now.
			"freeze":
				# Strike turn freezes 2 dice, hollow turn none, otherwise 1 (depth v3 6.3).
				var n_freeze := 2 if rphase == "strike" else (0 if rphase == "hollow" else 1)
				for _fz in n_freeze:
					var candidates: Array = []
					for u in alive_party():
						if not u.frozen and not u.is_token:
							candidates.append(u)
					if candidates.is_empty():
						break
					var t: Unit = candidates[_rng.next_int(candidates.size())]
					t.frozen = true
					EventBus.float_text.emit(t.uid, "FROZEN", "deb", 0)

			# MIRROR CHIMERA — copies the strongest face the player used last turn into its
			# own slot 0 at x1.1, never weakening what was already there.
			"mirror":
				if rphase != "hollow" and not last_big.is_empty() and not b.die.is_empty():
					var mirrored: Dictionary = (last_big.get("f", {}) as Dictionary).duplicate(true)
					if not mirrored.is_empty():
						mirrored["value"] = max(int(b.die[0].get("value", 0)),
							int(ceil(float(last_big.get("v", 0)) * 1.1)))
						b.die[0] = mirrored


# ===========================================================================
# Continue (monetization R1, dang B) and the Aid effects that touch a fight
# ===========================================================================

## Whole real party down and the fight is not won.
func can_continue() -> bool:
	return lost and not won and not mission


## Revives the real party at `heal_pct` of Max HP (ceil), keeps every enemy exactly as it was (HP, phase,
## spike schedule), sends clock and attrition back to 0 and rolls a fresh turn from `seed`. It is the
## same fight: `turn` is not touched. `heal_pct < 0` reads the ascension rule. The server charges for
## it inside the epoch request; here it is only a pure effect taking numbers (MON-13).
func continue_after_wipe(seed: int = -1, heal_pct: int = -1) -> bool:
	if not can_continue():
		return false
	var pct := heal_pct if heal_pct >= 0 else int(ContentDB.ascension_mods(ascension).get("continue_heal_pct", 40))
	var use_seed := seed
	if use_seed < 0 and _epoch != null:
		var r := _epoch.request("continue", _continue_args())
		if not r.ok:
			push_error("CombatEngine.continue_after_wipe: epoch refused (%s)" % r.code)
			return false
		use_seed = r.seed
	if use_seed >= 0:
		_rng = Rng.new(use_seed)
	attempt += 1
	lost = false
	var revived: Array = []
	for u in party:
		if u.is_token or u.custom_state.has("phantom"):
			continue
		u.hp = maxi(1, int(ceil(float(u.max_hp) * float(pct) / 100.0)))
		u.shield = 0
		u.status = {}
		u.frozen = false
		u.frozen_next = false
		u.clear_roll()
		revived.append(u.uid)
	clock_turn_base = turn
	undo_stack = []
	rerolls = max_rerolls
	reroll_k = 0
	reroll_paid_k = 0
	reroll_total_turn = 0
	reroll_lock = {}
	used_actives = []
	chaos_reroll_given = 0
	relic_reroll_given = 0
	resonance_log = []
	_first_dmg_used = false
	_set_turn_phase(CombatPhase.ROLL)
	roll_all()
	_set_turn_phase(CombatPhase.EXECUTE)
	EventBus.party_revived.emit(revived, pct)
	_log("continue", [attempt])
	return true


## Aid R4: pushes the boss clock (and attrition, they share the base) back `turns` turns.
func delay_clock(turns: int) -> void:
	clock_turn_base = mini(turn, clock_turn_base + maxi(0, turns))


# ===========================================================================
# Pressure: boss clock, attrition, spike (all pure in `turn`)
# ===========================================================================

func _eff_turn() -> int:
	return turn - clock_turn_base


## {} when this fight has no clock (not a boss, or the light clock for a newcomer).
func _clock_cfg() -> Dictionary:
	if kind != "boss":
		return {}
	var c: Dictionary = ContentDB.ascension_mods(ascension).get("clock", {})
	var ov: Dictionary = _mission_mods().get("clock_override", {})
	if not ov.is_empty():
		return {"start": int(ov["start"]), "step_pct": int(ov["step_pct"]),
			"max_stacks": int(ov["max_stacks"]), "light": false}   # replaces, never stacks
	if c.is_empty() or (bool(c.get("light", false)) and newcomer):
		return {}
	return c


func _mission_mods() -> Dictionary:
	return ContentDB.mission_mods(mission_rules, ascension) if mission else {}


func clock_state() -> Dictionary:
	var c := _clock_cfg()
	if c.is_empty():
		return {"active": false, "start_turn": 0, "turns_left": 0, "stacks": 0, "pct": 0}
	var start := int(c["start"])
	var stacks := clampi(_eff_turn() - start + 1, 0, int(c["max_stacks"]))
	return {"active": true, "start_turn": start, "turns_left": start - _eff_turn(),
		"stacks": stacks, "pct": stacks * int(c["step_pct"])}


func attrition_state() -> Dictionary:
	var a: Dictionary = ContentDB.combat_tune.get("attrition", {})
	if a.is_empty() or newcomer:
		return {"active": false, "start_turn": 0, "stacks": 0, "pct": 0}
	var step := maxi(1, int(a["step_pct"]))
	var stacks := clampi(_eff_turn() - int(a["start"]) + 1, 0, int(a["cap_pct"]) / step)
	return {"active": true, "start_turn": int(a["start"]), "stacks": stacks, "pct": stacks * step}


## Spike period for this enemy, 0 = never spikes (ascension < 3, normal battles, boss before phase 2).
func _spike_period(e: Unit) -> int:
	var sp: Dictionary = ContentDB.combat_tune.get("spike", {})
	if sp.is_empty() or ascension < int(sp.get("from_ascension", 3)):
		return 0
	var base := 0
	if e.is_boss:
		base = int(sp.get("boss_period", 0)) if int(e.custom_state.get("phase", 1)) >= int(sp.get("boss_from_phase", 2)) else 0
	elif kind == "elite":
		base = int(sp.get("elite_period", 0))
	if base > 0 and mission:
		base = maxi(1, base + int(_mission_mods().get("spike_period_delta", 0)))   # M2: a turn sooner
	return base


## Turns until this enemy's next spike, counting this turn as 0; -1 when it never spikes.
func turns_to_spike(e: Unit) -> int:
	var p := _spike_period(e)
	return -1 if p <= 0 else (p - turn % p) % p


func enemy_dmg_factor(e: Unit) -> float:
	var pct := int(attrition_state()["pct"])
	if e.is_boss:
		pct += int(clock_state()["pct"])
	var f := (100.0 + float(pct)) / 100.0
	if turns_to_spike(e) == 0:
		f *= float(ContentDB.combat_tune.get("spike", {}).get("mult", 1.0))
	return f


## Everything the HUD shows about pressure, in one pure call (contract 3.2).
func hud_state() -> Dictionary:
	var nxt: Dictionary = {}
	var phases: Dictionary = {}
	for e in alive_enemies():
		var fi: int = e.roll_face_index() if not e.intent.is_empty() else -1
		if fi >= 0 and fi < e.die.size():
			var is_dmg: bool = String((e.die[fi] as Dictionary).get("type", "")) == "dmg"
			var tts := turns_to_spike(e)
			nxt[e.uid] = {"dmg": _face_value(e, fi) if is_dmg else 0, "spike": tts == 0 and is_dmg,
				"turns_to_spike": tts}
		if e.is_boss:
			phases[e.uid] = {"phase": int(e.custom_state.get("phase", 1)),
				"thresholds": (ContentDB.combat_tune.get("phase_thresholds", []) as Array).duplicate()}
	return {"turn": turn, "rerolls": rerolls, "max_rerolls": max_rerolls, "mana": mana,
		"tweak_left": tweak_budget_left(), "clock": clock_state(), "attrition": attrition_state(),
		"enemy_next": nxt, "boss_phase": phases, "newcomer": newcomer}


func _check_end() -> bool:
	_affix_swarm()
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
	u.slot = index   # positional relics ("next to") read slot; reorder_party changes the roster order
	u.max_hp = base_hp + int(entry.get("bonus_hp", 0))
	u.die = (hero_def.get("die", []) as Array).duplicate(true)

	var oc_prod := 1.0
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
			# relic-set-v2 §3.3: on damage faces ascend/forge no longer multiply at build time; they feed
			# G_axie as an additive term (RelicHooks.g_axie). Shield/Heal/Mana keep the compounding
			# multiplier, capped at oc_nondmg_cap, rounded once from the base value (after the loop).
			var mult := float(m.get("mult", 1.5))
			u.g_oc_bonus += mult - 1.0
			oc_prod *= mult

	if oc_prod != 1.0:
		var oc_m := minf(oc_prod, RelicSlots.tuning().oc_nondmg_cap)
		for f in u.die:
			if int(f.get("value", 0)) > 0 and String(f.get("type", "")) != "dmg":
				f["value"] = int(ceil(int(f["value"]) * oc_m))

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
	var mm := _mission_mods()
	if mission:
		amods = amods.duplicate()
		amods["dmg"] = float(amods.get("dmg", 1.0)) * float(mm.get("enemy_dmg", 1.0))
		amods["boss_hp"] = float(amods.get("boss_hp", 1.0)) * float(mm.get("boss_hp", 1.0))

	# Depth v3 6.2 / 9c difficulty knobs (combat_tune.json difficulty.*): monster damage and boss HP, kept apart
	# from the budget knobs (TUNE.growth / elite_mult) so a tuning pass can move HP and damage separately.
	if p_kind == "boss":
		return [_mk_boss(_boss_key_for_this_node(), p_pw, amods)]   # boss knobs are applied in ContentDB.boss_stats()
	amods = amods.duplicate()
	amods["dmg"] = float(amods.get("dmg", 1.0)) * tune_knob("difficulty", "enemy_dmg_mult", 1.0)

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
	if _guarantee_tank and not is_elite:
		keys = CombatTraits.guarantee_tank(keys, avail)   # A.13: draws above are unchanged, only the last slot swaps

	var tot := 0.0
	for k in keys:
		tot += float((ContentDB.enemies.get(k, {}) as Dictionary).get("cost", 1))
	var sc: float = clamp(budget_v / max(tot, 1.0), 0.55, 3.4)
	# M6 (normal_hp) applies per monster to non-elite fights; M7 (elite_dmg) to elite fights.
	# Distinct from run_mods["enemy_hp"] (the encounter budget). Rounding is the existing
	# round-half-up on the final HP (_mk_monster) / die value (scale_die).
	var em := {"hp": float(amods.get("hp", 1.0)) * (float(mm.get("elite_hp", 1.0)) if is_elite else float(mm.get("normal_hp", 1.0))),
		"dmg": float(amods.get("dmg", 1.0)) * _run_mod("enemy_dmg") * (float(mm.get("elite_dmg", 1.0)) if is_elite else 1.0)}

	var out: Array = []
	for k in keys:
		out.append(_mk_monster(String(k), sc, em))
	CombatTraits.assign_traits(self, out, is_elite, bool(_early_traits))
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
	u.plating = CombatTraits.plating_for_pw(p_pw)   # M6: only counts on prep / strike turns (CombatTraits.plating_of)
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
