extends Node
## In-run state (~= JS `S`). Lives for exactly one run: New Run → Result → back to
## MainMenu, at which point reset() re-instantiates every sub-object rather than
## clearing fields one by one (see architecture plan §4, §9 self-critique #2 — a
## field added later and never wired into reset() is how JS's own UID-desync class of
## bug happened; re-instantiating wholesale removes that failure mode by construction).

enum RunPhase { MENU, MAP, EVENT, SHOP, TREASURE, COMBAT, REWARD, WON, LOST }

var phase: int = RunPhase.MENU

# --- Run identity ---
var run_seed: int = 0
var ranked: bool = false          # submit-run.js zeroes meta bonuses for ranked runs —
                                   # this must be known from start_new_run(), never bolted on.
var mode: String = "short"        # "short" | "full"
var ascension: int = 0

# --- Roster (~= JS S.roster) ---
# Each entry: {persistent_id: int, hero_key: String, tier: int, max_hp: int, muts: Array,
# growth: Dictionary, bonus_hp: int}. persistent_id is assigned once here at roster
# creation and never changes for the run — this is the "stable id" half of the UID fix
# (architecture plan §4b/§3.2 in the reviewed draft): combat-local token/ally ids live
# in a separate, per-CombatEngine-instance space and can never collide with these.
var roster: Array[Dictionary] = []
var _next_persistent_id: int = 1

# --- RunMap (stub — full path-walking generator is checklist step 5, architecture plan §7;
# this holds the shape callers can already depend on) ---
var map_graph: Dictionary = {}     # RunMapGraph.to_data() shape once run_map_generator.gd exists
var current_node_id: String = ""
var visited_node_ids: Array[String] = []

# --- Progression (in-run, ~= JS S.shards/pw/owned relics) ---
var shards_this_run: int = 0
var power_level: int = 0           # "pw" — increments on every node completed regardless of
                                    # type (verified against engine.js takeReward/eventDone/shopDone)
var owned_relic_ids: Array[String] = []
var bonus_reroll: int = 0          # ~= JS s.bonusReroll — permanent +max-reroll from reward/
                                    # event/shop pickups. Already read by CombatEngine.setup_new()
                                    # via pending_combat["bonus_reroll"] (see enter_node() below).

# --- Boss plan (src/engine.js newGame(), engine.js:359-363) ---
# boss_plan[i] is the boss key for map_graph's boss_rows[i] (same index, both row-ordered).
# Picked ONCE at start_new_run() time, not when the player reaches that row — see
# _build_boss_plan(). The FINAL entry is always ContentDB.boss_order_12/20's own last entry
# ('agony'); only the middle entries can be swapped for a ContentDB.boss_alt pick.
var boss_plan: Array[String] = []

# --- Run-wide combat modifiers (~= JS s.runMods, engine.js:340,349) ---
# Read by CombatEngine via pending_combat["run_mods"] (see enter_node() below). Only the
# CURSE PACT reward (apply_chosen_reward()'s "curse" branch) mutates this today.
var run_mods: Dictionary = {"enemy_hp": 1.0, "enemy_dmg": 1.0}

# --- Reward-set reroll (~= JS s.rerollReward/s.rrwMax, engine.js:1163-1166,1170) ---
# src/client.html:4681 — `S.rerollReward = 1 + (P.rrw||0); S.rrwMax = S.rerollReward`. The
# battle-pass 'rrw' perk (level 28) is what raises it; this comment used to say that perk was
# unported and the value was always 1, which stayed in place after the perk became claimable
# and left level 28 granting nothing at all.
var reward_reroll_charges: int = 1
var reward_reroll_max: int = 1
var _reward_reroll_salt: int = 0    # bumped on every reroll so a re-rolled offer never
                                     # draws the same Rng stream as the offer it replaced.
var _reward_reroll_tier: int = 0
var _reward_reroll_pw: int = 0
var _reward_reroll_count: int = 0

# --- end_run() idempotency guard ---
# Both apply_combat_result()'s final-boss WON branch and Result.tscn's ResultView._ready()
# call end_run() for the very same run — this makes "bank shards into MetaState" a true
# single-fire event regardless of which call site gets there first, instead of double-
# crediting shards_this_run into MetaState.
var _run_end_processed: bool = false

## XP this run earned, set by end_run() so the Result screen can show it (JS keeps the same
## value on S.xpGain for exactly that reason).
var last_run_xp: int = 0
## True only when THIS run end was the one that granted the day's Daily Mission shards. Read by
## the result screen, which must show the line on the day it happened and not on every run.
var daily_mission_granted: bool = false

# --- Reward/event/shop/treasure loop (checklist step 4, reward-system pass) ---
# Reward-choice cards offered after a won combat (RewardGenerator.generate() output),
# consumed by RunMapController's post-combat reward overlay via apply_chosen_reward().
# Populated by apply_combat_result() (won branch) or RunMapController for a treasure node
# (tier-1, single reward, no choice — see that file's _on_treasure_node()).
var pending_rewards: Array[Dictionary] = []

# --- Combat handoff (architecture plan §4 fix A: DATA, never a live CombatEngine instance) ---
var pending_combat: Dictionary = {}   # CombatSetup shape: node_id, kind, pw, ascension mods,
                                       # roster snapshot, relics, combat_seed. Set by
                                       # RunMapController immediately before changing scene;
                                       # consumed and cleared by Combat.tscn._ready() in the
                                       # same call, never held across a frame boundary.

# --- CONTINUE RUN (save/resume, ~= JS saveRun()/loadRun()) ---
# The in-flight CombatEngine._state_dict() when a run was saved mid-fight, or {} when it was
# saved on the map. CombatView consumes and clears it in _ready(), exactly as pending_combat
# is consumed — the difference is that pending_combat says "start this fight" while this says
# "this fight was already in progress, restore it".
var resume_combat: Dictionary = {}

# --- Gameplay RNG (architecture plan §5: owned here, never an autoload, never used for VFX) ---
var _rng: Rng = null

func _ready() -> void:
	reset()

## Wholesale reset — re-instantiates every mutable container instead of clearing fields,
## so a field added later that's forgotten here fails loudly (empty/default) rather than
## silently carrying over from the previous run.
func reset() -> void:
	phase = RunPhase.MENU
	run_seed = 0
	ranked = false
	mode = "short"
	ascension = 0
	roster = []
	_next_persistent_id = 1
	map_graph = {}
	current_node_id = ""
	visited_node_ids = []
	shards_this_run = 0
	power_level = 0
	owned_relic_ids = []
	bonus_reroll = 0
	boss_plan = []
	run_mods = {"enemy_hp": 1.0, "enemy_dmg": 1.0}
	reward_reroll_charges = 1
	reward_reroll_max = 1
	_reward_reroll_salt = 0
	_reward_reroll_tier = 0
	_reward_reroll_pw = 0
	_reward_reroll_count = 0
	_run_end_processed = false
	last_run_xp = 0
	daily_mission_granted = false
	pending_rewards = []
	pending_combat = {}
	resume_combat = {}
	_rng = null

func start_new_run(p_seed: int, team_hero_keys: Array[String], p_mode: String,
		p_ascension: int, p_ranked: bool) -> void:
	reset()
	run_seed = p_seed
	mode = p_mode
	ascension = p_ascension
	ranked = p_ranked
	# Rule spec §6: a Vault (Import Axie) pick makes a run ineligible for Ranked, and the live
	# server refuses such a submission outright (api/submit-run.js:87, HTTP 400). The reason is
	# mechanical, not a fairness preference — a vault die exists only in this player's local save,
	# so a server replay cannot rebuild it and the score cannot be verified at all.
	#
	# Enforced HERE and not only in the menu, because the menu is not the authority: a saved run,
	# a dev tool or a future daily-mission entry point all reach this function directly. JS makes
	# the same correction (`if(hasVault) pickRanked=false;`, client.html:4593) — the run is still
	# played, it simply is not ranked.
	if ranked and MetaState.team_has_vault_pick(team_hero_keys):
		ranked = false
		push_warning("RunState: ranked was requested with a Vault Axie in the team; running "
			+ "unranked instead — a vault die only exists in this save and cannot be replayed "
			+ "server-side.")
	_rng = Rng.new(p_seed)

	# Meta bonuses (src/client.html newRun(), :4669-4673). run_bonuses() returns all zeroes for
	# a ranked run — see its own comment for why that is not optional.
	# `ranked`, not `p_ranked`: the guard above may have downgraded the run, and a run that is not
	# ranked must get its meta bonuses. Reading the argument here instead would produce a run that
	# is unranked AND stripped of everything the player unlocked — the worst of both.
	var meta_bonus: Dictionary = MetaState.run_bonuses(ranked)
	bonus_reroll = int(meta_bonus.get("bonus_reroll", 0))
	var meta_hp := int(meta_bonus.get("hp_bonus", 0))
	reward_reroll_max = int(meta_bonus.get("reward_reroll_max", 1))
	reward_reroll_charges = reward_reroll_max

	for hero_key in team_hero_keys:
		var hero_def: Dictionary = ContentDB.heroes.get(hero_key, {})
		roster.append({
			"persistent_id": _next_persistent_id,
			"hero_key": hero_key,
			"tier": int(hero_def.get("tier", 1)),
			"max_hp": int(hero_def.get("max_hp", 0)),   # 0 if hero_key not in ContentDB yet
			"muts": [],
			"growth": {},
			# JS applies metaHpBonus inside buildUnit (engine.js:106); this port has a per-entry
			# bonus_hp that every other Max-HP source already goes through, so it rides that
			# rather than adding a second, parallel path to the same number.
			"bonus_hp": meta_hp,
		})
		_next_persistent_id += 1

	# Starting relic, if the meta grants one. Drawn from THIS run's own `_rng` before the boss
	# plan, so the pick is part of the seed like everything else — JS uses an unseeded pick0()
	# here, which is one of the few places the live game is not reproducible from its seed.
	var relic_cap := int(meta_bonus.get("start_relic_max_rarity", -1))
	if relic_cap >= 0:
		var pool: Array = []
		for def in RelicRegistry.offerable_defs_sorted():
			if int(def.rarity) <= relic_cap and int(def.act_cost) == 0:
				pool.append(String(def.id))
		if not pool.is_empty():
			owned_relic_ids.append(pool[_rng.next_int(pool.size())])
	# src/engine.js newGame() picks the boss plan BEFORE building the map (engine.js:359-363)
	# — mirrored here: boss_plan draws from the same _rng stream ahead of the map generator,
	# so the whole run (boss plan + map shape) is one deterministic function of p_seed.
	boss_plan = _build_boss_plan(p_mode)
	# RunMapGenerator.generate() is fail-hard on total retry exhaustion (returns null +
	# push_error, architecture plan §7 "fail cứng, không âm thầm nhả map xấu") — calling
	# .to_data() on that null is a deliberate crash, not a bug, if it ever happens.
	map_graph = RunMapGenerator.generate(_rng, mode, ascension).to_data()
	set_phase(RunPhase.MAP)


## src/engine.js newGame() (engine.js:359-363). `order` starts as ContentDB.boss_order_12
## (short) or boss_order_20 (full), verbatim. Every MIDDLE boss (index 1..size-2 — never the
## first, never the last) has a 50% chance to be replaced by a random ContentDB.boss_alt
## pick. The final entry of boss_order_12/20 is always 'agony' and this loop never reaches
## it — that IS the guarantee "the final boss is always agony", not a special case here.
func _build_boss_plan(p_mode: String) -> Array[String]:
	var source: Array = ContentDB.boss_order_12 if p_mode == "short" else ContentDB.boss_order_20
	var plan: Array[String] = []
	for k in source:
		plan.append(String(k))
	var alt: Array = ContentDB.boss_alt
	for i in range(1, plan.size() - 1):
		if _rng.next_float() < 0.5 and not alt.is_empty():
			plan[i] = String(alt[_rng.next_int(alt.size())])
	return plan


## Maps a boss-node id to the boss key chosen for it at run start. boss_plan[i] lines up
## with map_graph's boss_rows[i] (both row-ordered, same size by construction — see
## RunMapGenerator.MODE_CONFIG's boss_rows vs. ContentDB.boss_order_12/20 lengths).
func _boss_key_for_node(node_id: String) -> String:
	var graph := RunMapGraph.from_data(map_graph)
	var node := graph.find_node(node_id)
	if node == null:
		return ""
	var idx := graph.boss_rows.find(node.row)
	if idx < 0 or idx >= boss_plan.size():
		return ""
	return boss_plan[idx]


## True when `node_id` sits on map_graph's own LAST boss_rows entry — i.e. it is the final
## boss of the run. Never a hardcoded row number, so this keeps working if
## RunMapGenerator's row scale changes again (see that file's header note).
func _is_final_boss_row(node_id: String) -> bool:
	var graph := RunMapGraph.from_data(map_graph)
	if graph.boss_rows.is_empty():
		return false
	var final_row: int = graph.boss_rows[graph.boss_rows.size() - 1]
	var node := graph.find_node(node_id)
	return node != null and node.row == final_row

## Every phase transition goes through here — validated + signalled, never set directly
## elsewhere (architecture plan §4/§5 "no silent state change" discipline).
func set_phase(new_phase: int) -> void:
	var old_phase := phase
	phase = new_phase
	EventBus.phase_changed.emit(old_phase, new_phase)

## Called by RunMapController when the player picks a valid node. Builds the CombatSetup
## data (not a live CombatEngine) and stores it in pending_combat for Combat.tscn to consume.
func enter_node(node_id: String, node_kind: String) -> void:
	current_node_id = node_id
	match node_kind:
		"battle", "elite", "boss":
			set_phase(RunPhase.COMBAT)
			var combat_seed := Rng.derive_combat_seed(run_seed, node_id, 0)
			pending_combat = {
				"node_id": node_id,
				"kind": node_kind,
				"pw": power_level,
				"ascension": ascension,
				"roster_snapshot": roster.duplicate(true),
				"relic_ids": owned_relic_ids.duplicate(),
				"combat_seed": combat_seed,
				"bonus_reroll": bonus_reroll,
				"run_mods": run_mods.duplicate(),
			}
			if node_kind == "boss":
				pending_combat["boss_key"] = _boss_key_for_node(node_id)
			EventBus.node_entered.emit(node_kind, node_id)
		"event":
			set_phase(RunPhase.EVENT)
			EventBus.node_entered.emit(node_kind, node_id)
		"shop":
			set_phase(RunPhase.SHOP)
			EventBus.node_entered.emit(node_kind, node_id)
		"treasure":
			set_phase(RunPhase.TREASURE)
			EventBus.node_entered.emit(node_kind, node_id)
		_:
			push_error("RunState.enter_node: unknown node_kind '%s'" % node_kind)

## Called once by RunMap/Combat flow after a node resolves (combat won/lost, event choice
## applied, shop closed, treasure claimed). Advances power_level and returns to MAP unless
## the run just ended. Guarded against WON/LOST: apply_combat_result()'s final-boss branch
## sets WON directly (src/engine.js finishCombat() never calls afterNode() on that path
## either — it returns before genRewards()), so a caller that unconditionally calls
## after_node() once per resolved node (e.g. tests/t_full_run_loop.gd's walker) can never
## stomp a terminal phase back to MAP.
func after_node() -> void:
	if phase == RunPhase.WON or phase == RunPhase.LOST:
		return
	power_level += 1
	if not visited_node_ids.has(current_node_id):
		visited_node_ids.append(current_node_id)
	set_phase(RunPhase.MAP)

## Single point of truth for writing combat results back into run state (architecture
## plan §4: "chỉ qua một hàm" — never let Combat.tscn or Result.tscn mutate roster/shards
## directly). res is a CombatResult-shaped Dictionary from CombatEngine.get_result():
## {won, shards_earned, growth_keep, roster_updates, kind, pw}.
func apply_combat_result(res: Dictionary) -> void:
	if res.get("won", false):
		shards_this_run += int(res.get("shards_earned", 0))
		_apply_growth_keep(res.get("growth_keep", {}))
		var kind := String(res.get("kind", "battle"))
		if kind == "boss" and _is_final_boss_row(current_node_id):
			# src/engine.js finishCombat() (engine.js:997): `if(k==='boss'&&s.step>=s.len){
			# s.phase='won'; return; }` — defeating the FINAL boss ends the run immediately,
			# with NO reward offer (genRewards() is never reached on this path in the source
			# either). pending_rewards is force-cleared so a stale offer can never linger
			# under the WON overlay. end_run() is guarded against double-firing (see
			# _run_end_processed) since Result.tscn's ResultView._ready() also calls it.
			pending_rewards = []
			set_phase(RunPhase.WON)
			end_run(true)
		else:
			_generate_post_combat_rewards(res)
			set_phase(RunPhase.REWARD)
	else:
		set_phase(RunPhase.LOST)
		EventBus.run_ended.emit(false)


## src/engine.js finishCombat()'s ENG-3 block (engine.js:986-994) write-back half. The
## halving/capping itself already happened in CombatEngine._compute_growth_keep() — this
## just ADDS each already-halved, already-capped-per-combat delta onto the roster's
## persistent ledger (roster[i].growth), keyed by the same {roster_index: {face_index: v}}
## shape get_result() returns. Never halves or caps again here (combat-engine workstream's
## contract — see task coordination note).
func _apply_growth_keep(growth_keep: Dictionary) -> void:
	for roster_index_key in growth_keep.keys():
		var idx := int(roster_index_key)
		if idx < 0 or idx >= roster.size():
			continue
		var entry: Dictionary = roster[idx]
		var growth: Dictionary = (entry.get("growth", {}) as Dictionary).duplicate()
		var per_face: Dictionary = growth_keep[roster_index_key]
		for face_index_key in per_face.keys():
			var fi := int(face_index_key)
			growth[fi] = int(growth.get(fi, 0)) + int(per_face[face_index_key])
		entry["growth"] = growth


func end_run(won: bool) -> void:
	if _run_end_processed:
		return
	_run_end_processed = true
	# JS: saveRun() writes the slot only while phase is neither 'won' nor 'lost', and removes it
	# otherwise (client.html:3420). Doing it here rather than in a save guard means a finished
	# run cannot leave a resumable save behind even if some later call site forgets.
	clear_saved_run()
	MetaState.add_shards(shards_this_run)

	# Lifetime stats and the Ascension ladder (src/client.html onRunEnd(), :5436-5446).
	MetaState.runs += 1
	if power_level > MetaState.best:
		MetaState.best = power_level
	if won:
		MetaState.wins += 1
		# JS: a win at or above your current ceiling raises it by one, capped at 10. So the
		# ladder is climbed by winning AT the top, not by winning anywhere.
		if ascension >= MetaState.asc_max and MetaState.asc_max < 10:
			MetaState.asc_max = mini(10, ascension + 1)
	last_run_xp = compute_run_xp(won)
	MetaState.xp += last_run_xp
	# Daily Mission. Granted on ANY run end — win, loss or quit — exactly as JS does it
	# (client.html:5447 calls it unconditionally from onRunEnd()). Tying it to a win would make
	# the day's reward a skill check, which is not what a daily is for.
	daily_mission_granted = MetaState.claim_daily_mission()
	MetaState.save_to_disk()

	EventBus.run_ended.emit(won)


## src/data.js runXp() (:1034), verbatim:
##   round(30 + 10*(step - (won?0:1)) + 30*elitesPassed + 60*bossesPassed
##         + (won?150:0) + asc*25 + (mode=='full'?40:0))
##
## `s.step` is JS's linear wave counter; `power_level` is this port's equivalent — it advances
## once per completed node of any type, which is what `step` did.
##
## NOTE, not a bug: this port's map is 18 rows where JS's is 12, so a full run passes through
## roughly half again as many nodes and earns roughly half again as much XP. The formula is
## ported unchanged on purpose; the divergence belongs to the 18-row decision (still an open
## balance question, wayfinder ticket B), not to this function, and burying a compensating
## fudge factor here would hide it.
func compute_run_xp(won: bool) -> int:
	var elites := 0
	var bosses := 0
	if not map_graph.is_empty():
		var graph := RunMapGraph.from_data(map_graph)
		for node_id in visited_node_ids:
			var node := graph.find_node(String(node_id))
			if node == null:
				continue
			match node.node_type:
				"elite":
					elites += 1
				"boss":
					bosses += 1
	var step := power_level
	var total := 30.0 + 10.0 * float(step - (0 if won else 1)) \
		+ 30.0 * float(elites) + 60.0 * float(bosses) \
		+ (150.0 if won else 0.0) + float(ascension) * 25.0 \
		+ (40.0 if mode == "full" else 0.0)
	return int(round(maxf(total, 0.0)))


# ===========================================================================
# Reward / event / shop loop (checklist step 4, reward-system pass —
# design/gdd/godot-port-rule-spec.md §9). Single point of truth for mutating
# roster/relics/shards/reroll from a reward pick, event choice, or shop purchase — never
# let RunMapController (or any UI) touch those fields directly.
# ===========================================================================

func effective_max_rerolls() -> int:
	return 2 + bonus_reroll


## src/data.js ascMods(a).rewards: 3 normally, 2 at Ascension>=7 — thread through
## ContentDB.ascension_mods() rather than re-deriving the threshold here.
func _reward_count() -> int:
	return int(ContentDB.ascension_mods(ascension).get("rewards", 3))


## Builds the reward-choice cards for a won combat (src/engine.js finishCombat() ->
## genRewards()).
##
## ORDERING FIX: previously, CombatView._finish() called RunState.after_node() (advancing
## power_level/phase to MAP) immediately on a win, BEFORE the player had actually picked a
## reward — src/engine.js's takeReward() advances s.pw/s.phase strictly AFTER the pick. That
## call was removed from CombatView._finish() (this pass, run-completion path only); now
## after_node() is called from RunMapController._on_reward_chosen() once a card is actually
## picked, matching takeReward()'s ordering exactly, with generate_treasure_rewards() /
## _on_reward_chosen() sharing the exact same path for the treasure node's own offer.
func _generate_post_combat_rewards(res: Dictionary) -> void:
	var kind := String(res.get("kind", "battle"))
	var pw := int(res.get("pw", power_level))
	# src/engine.js finishCombat(): s.rewardTier = boss?3 : elite?2 : (s.step%3===0?1:0). This
	# vertical slice's branching RunMap has no linear "step" counter (rule spec §9 note: "cần
	# verify lại khi số node/hàng thay đổi khi không còn 1 tuyến cố định") — approximated
	# with power_level (0-indexed, standing in for JS's 1-indexed step) below.
	var tier := 3 if kind == "boss" else (2 if kind == "elite" else (1 if (power_level + 1) % 3 == 0 else 0))
	_set_pending_rewards(tier, pw, 601)


## src/engine.js chooseNode() 'treasure' branch (engine.js:402): `s.rewardTier=1;
## genRewards(s,'treasure')` — a real N-card offer at tier 1, same mechanism as a combat
## reward, NOT an instant single-card grant (that was this port's own earlier simplification
## — see RunMapController._on_treasure_node()'s history). `node_id` seeds a salt distinct
## from every other overlay flow (RunMapController._node_rng()'s convention).
func generate_treasure_rewards(_node_id: String) -> void:
	_set_pending_rewards(1, power_level, 503)


func _set_pending_rewards(tier: int, pw: int, salt: int) -> void:
	_reward_reroll_tier = tier
	_reward_reroll_pw = pw
	_reward_reroll_count = _reward_count()
	_reward_reroll_salt = salt
	reward_reroll_charges = reward_reroll_max
	var reward_rng := Rng.new(Rng.derive_combat_seed(run_seed, current_node_id, salt))
	pending_rewards = RewardGenerator.generate(pw, tier, reward_rng, owned_relic_ids, roster,
		effective_max_rerolls(), _reward_reroll_count)


## src/engine.js rerollRewards() (engine.js:1163-1166): spends 1 s.rerollReward charge and
## redraws the SAME tier/pw offer. Uses a bumped salt (never the original 601/503 draw) so a
## reroll can never reproduce the exact offer it just replaced.
func reroll_pending_rewards() -> bool:
	if reward_reroll_charges <= 0 or pending_rewards.is_empty():
		return false
	reward_reroll_charges -= 1
	_reward_reroll_salt += 1
	var reward_rng := Rng.new(Rng.derive_combat_seed(run_seed, current_node_id, _reward_reroll_salt))
	pending_rewards = RewardGenerator.generate(_reward_reroll_pw, _reward_reroll_tier, reward_rng,
		owned_relic_ids, roster, effective_max_rerolls(), _reward_reroll_count)
	return true


## Applies ONE reward card's effect (RewardGenerator.generate() output) and clears
## pending_rewards. Deliberately never calls after_node() itself (see the ordering-fix note
## above) — every caller (RunMapController._on_reward_chosen(), shared by the post-combat
## and treasure flows) calls after_node() itself right after this, exactly like it already
## does for event/shop nodes.
func apply_chosen_reward(reward: Dictionary) -> void:
	match String(reward.get("t", "")):
		"level":
			# src/engine.js applyReward() 'level' (engine.js:1176): `ent(r.uid).key=r.key`.
			# tier/max_hp are cached fields on the Godot roster entry (JS's roster entries
			# don't carry them — HEROES[key] is read live) — refresh both from the new
			# hero def so CombatEngine._build_unit_from_roster() picks up the tier-up
			# without needing a live ContentDB.heroes lookup itself.
			var entry := _roster_entry_by_pid(int(reward.get("persistent_id", -1)))
			if not entry.is_empty():
				var new_key := String(reward.get("key", ""))
				entry["hero_key"] = new_key
				var hero_def: Dictionary = ContentDB.heroes.get(new_key, {})
				entry["tier"] = int(hero_def.get("tier", entry.get("tier", 1)))
				entry["max_hp"] = int(hero_def.get("max_hp", entry.get("max_hp", 0)))
		"ascend":
			# src/engine.js applyReward() 'ascend' (engine.js:1177): `e.muts.push({type:'oc',
			# mult:1.25}); e.bonusHp+=6;` — CombatEngine._build_unit_from_roster() already
			# applies "oc" muts (ceil(value*mult) on every value-bearing face).
			var entry2 := _roster_entry_by_pid(int(reward.get("persistent_id", -1)))
			if not entry2.is_empty():
				var muts: Array = (entry2.get("muts", []) as Array).duplicate()
				muts.append({"type": "oc", "mult": 1.25})
				entry2["muts"] = muts
				entry2["bonus_hp"] = int(entry2.get("bonus_hp", 0)) + 6
		"relic":
			var rid := String(reward.get("key", ""))
			if rid != "" and not owned_relic_ids.has(rid):
				owned_relic_ids.append(rid)
		"hp":
			var entry3 := _roster_entry_by_pid(int(reward.get("persistent_id", -1)))
			if not entry3.is_empty():
				entry3["bonus_hp"] = int(entry3.get("bonus_hp", 0)) + int(reward.get("v", 0))
		"reroll":
			bonus_reroll += 1
		"chaos":
			# src/engine.js applyReward() 'chaos' (engine.js:1179-1180): grants the relic,
			# THEN the whole party loses 20% Max HP — same helper the "gamble_legend" shrine
			# event fx already uses.
			var rid2 := String(reward.get("key", ""))
			if rid2 != "" and not owned_relic_ids.has(rid2):
				owned_relic_ids.append(rid2)
			_reduce_party_max_hp_pct(0.2)
		"curse":
			# src/engine.js applyReward() 'curse' (engine.js:1184-1185):
			#   s.runMods.enemyHp *= 1.18; s.runMods.enemyDmg *= 1.12;
			#   s.relics.push('__curse_dmg'); s.bonusReroll += 1
			# '__curse_dmg' is a PSEUDO-RELIC, not something the player can be offered: its
			# entire body is a modFace that adds +4 to each of your own damage faces
			# (engine.js:1188-1189). Carrying it as a real relic id — rather than as a
			# special case in the reward code — is what makes the bonus obey the same INV-5
			# ordering as every other die mutation.
			run_mods["enemy_hp"] = float(run_mods.get("enemy_hp", 1.0)) * 1.18
			run_mods["enemy_dmg"] = float(run_mods.get("enemy_dmg", 1.0)) * 1.12
			if not owned_relic_ids.has("__curse_dmg"):
				owned_relic_ids.append("__curse_dmg")
			bonus_reroll += 1
	pending_rewards = []


## Ported subset of src/engine.js applyEventFx() (rule spec §9/§10) — only the fx values
## reachable from ContentDB.events' two implemented event defs (shrine/campfire). Returns
## the same kind of human-readable result message the JS version shows before eventDone().
func apply_event_effect(fx: String, rng: Rng) -> String:
	match fx:
		"bless_reroll":
			bonus_reroll += 1
			return "You permanently gain 1 maximum Reroll."
		"gamble_legend":
			var def := RewardGenerator.pick_relic(rng, owned_relic_ids, 3, 3)
			if def == null:
				def = RewardGenerator.pick_relic(rng, owned_relic_ids, 0, 2)
			if def != null:
				owned_relic_ids.append(def.id)
			_reduce_party_max_hp_pct(0.2)
			return "Received %s. The whole party loses 20%% Max HP." % (def.name if def != null else "nothing")
		"pray":
			if roster.is_empty():
				return "Nothing happened."
			var e: Dictionary = roster[rng.next_int(roster.size())]
			e["bonus_hp"] = int(e.get("bonus_hp", 0)) + 8
			return "%s gains 8 Max HP." % _hero_display_name(e)
		"chest":
			var def2 := RewardGenerator.pick_relic(rng, owned_relic_ids, 1, 3)
			if def2 != null:
				owned_relic_ids.append(def2.id)
			return "You found a relic: %s" % (def2.name if def2 != null else "nothing")
		"shards60":
			shards_this_run += 60
			return "You gained 60 Gene Shard."
		"rest":
			if roster.is_empty():
				return "Nothing happened."
			var e2: Dictionary = roster[rng.next_int(roster.size())]
			e2["bonus_hp"] = int(e2.get("bonus_hp", 0)) + 12
			return "%s gains 12 Max HP." % _hero_display_name(e2)
		"forge":
			if roster.is_empty():
				return "Nothing happened."
			var e3: Dictionary = roster[rng.next_int(roster.size())]
			var muts: Array = e3.get("muts", [])
			muts.append({"type": "oc", "mult": 1.3})
			e3["muts"] = muts
			return "%s is 30%% stronger on all six faces." % _hero_display_name(e3)
		"meditate":
			for e4 in roster:
				e4["bonus_hp"] = int(e4.get("bonus_hp", 0)) + 4
			return "The whole party gains 4 Max HP."
		"bet_small":
			# src/engine.js:1217-1218 — a true coin flip: an Epic-or-better relic, or the
			# whole party pays 10% Max HP. The RNG draw happens FIRST and unconditionally,
			# so the stream advances identically on both outcomes.
			if rng.next_float() < 0.5:
				var won_relic := RewardGenerator.pick_relic(rng, owned_relic_ids, 2, 3)
				if won_relic != null:
					owned_relic_ids.append(won_relic.id)
				return "YOU WIN! Received %s" % (won_relic.name if won_relic != null else "nothing")
			_reduce_party_max_hp_pct(0.1)
			return "YOU LOSE. The whole party loses 10% Max HP."
		"shards30":
			shards_this_run += 30
			return "You gained 30 Gene Shard."
		"leave":
			# src/engine.js:1228 returns this text and nothing else. The heal is real but
			# already guaranteed: every combat rebuilds the party at full HP (rule spec §1),
			# so there is no HP state between nodes for this to restore. Kept as flavour,
			# matching JS exactly — do not "fix" it into a mechanical effect.
			return "The whole party heals to full."
	# An fx with no branch here would silently do nothing, which reads as a bug to the
	# player. ContentDB.playable_event_keys() filters unported options out of the offer,
	# so reaching this line means an option was offered that should not have been.
	push_error("RunState.apply_event_effect: no handler for fx '%s' — the option should not "
		% fx + "have been offered (see ContentDB.playable_event_options)")
	return ""


## src/data.js shopBuy() ported subset. `rng` is the same Rng the shop overlay generated its
## items with (RunMapController owns it) — reused here only for the "heal" item's random
## target pick, matching src/engine.js's `pick(s.roster)`.
func try_buy_shop_item(item: Dictionary, rng: Rng) -> bool:
	var cost := int(item.get("cost", 0))
	if shards_this_run < cost:
		return false
	shards_this_run -= cost
	match String(item.get("kind", "")):
		"relic":
			var rid := String(item.get("key", ""))
			if rid != "" and not owned_relic_ids.has(rid):
				owned_relic_ids.append(rid)
		"heal":
			if not roster.is_empty():
				var e: Dictionary = roster[rng.next_int(roster.size())]
				e["bonus_hp"] = int(e.get("bonus_hp", 0)) + int(item.get("v", 10))
		"reroll":
			bonus_reroll += 1
	return true


func _roster_entry_by_pid(pid: int) -> Dictionary:
	for e in roster:
		if int(e.get("persistent_id", -1)) == pid:
			return e
	return {}

func _hero_base_max_hp(entry: Dictionary) -> int:
	var hero_def: Dictionary = ContentDB.heroes.get(String(entry.get("hero_key", "")), {})
	var base := int(entry.get("max_hp", 0))
	if base <= 0:
		base = int(hero_def.get("max_hp", 10))
	return base

func _hero_display_name(entry: Dictionary) -> String:
	var hero_def: Dictionary = ContentDB.heroes.get(String(entry.get("hero_key", "")), {})
	return String(hero_def.get("n", entry.get("hero_key", "?")))

## src/engine.js's gamble_legend fx: `e.bonusHp-=Math.round((h.hp+e.bonusHp)*0.2)` per roster
## entry — reduces every Axie's effective Max HP by 20%, applied as a bonus_hp adjustment so
## it stacks correctly with any HP already granted this run.
func _reduce_party_max_hp_pct(pct: float) -> void:
	for e in roster:
		var base := _hero_base_max_hp(e)
		var cur_bonus := int(e.get("bonus_hp", 0))
		e["bonus_hp"] = cur_bonus - int(round((base + cur_bonus) * pct))


# ===========================================================================
# CONTINUE RUN — save / restore (~= JS saveRun()/loadRun()/clearRun(),
# client.html:3412-3422)
# ===========================================================================

const SAVE_PATH := "user://run_save.json"

## Bumped whenever the shape below changes incompatibly. A save from a different version is
## ignored rather than half-loaded: a run restored into a schema it does not match is worse
## than no save at all, because it looks like it worked.
const SAVE_VERSION := 1

## Dictionaries whose keys are INTEGERS, per roster entry. JSON has no integer keys — every
## one comes back as a string — so `growth.get(3)` would miss a value stored under "3" and
## silently read 0. Nothing errors; the player simply loses every point of accumulated growth
## on resume. These are the only int-keyed dictionaries in the run state (`status`,
## `custom_state`, `stat`, `run_mods` and the map graph all use string keys), so the coercion
## below is targeted rather than a blanket "any digit-looking key becomes a number", which
## would corrupt a legitimate numeric-looking string key added later.
static func _int_keyed(d: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in d.keys():
		out[int(k)] = int(d[k])
	return out


func to_data() -> Dictionary:
	return {
		"phase": phase,
		"run_seed": run_seed,
		"ranked": ranked,
		"mode": mode,
		"ascension": ascension,
		"roster": roster.duplicate(true),
		"next_persistent_id": _next_persistent_id,
		"map_graph": map_graph.duplicate(true),
		"current_node_id": current_node_id,
		"visited_node_ids": visited_node_ids.duplicate(),
		"shards_this_run": shards_this_run,
		"power_level": power_level,
		"owned_relic_ids": owned_relic_ids.duplicate(),
		"bonus_reroll": bonus_reroll,
		"boss_plan": boss_plan.duplicate(),
		"run_mods": run_mods.duplicate(true),
		"reward_reroll_charges": reward_reroll_charges,
		"reward_reroll_max": reward_reroll_max,
		"reward_reroll_salt": _reward_reroll_salt,
		"reward_reroll_tier": _reward_reroll_tier,
		"reward_reroll_pw": _reward_reroll_pw,
		"reward_reroll_count": _reward_reroll_count,
		"run_end_processed": _run_end_processed,
		"pending_rewards": pending_rewards.duplicate(true),
		# `_rng` is only ever drawn from inside start_new_run() (boss plan, then map
		# generation); every later draw derives its own Rng from (run_seed, node_id, salt).
		# Its position is therefore dead state today — carried anyway so that a future caller
		# which does use it mid-run cannot make a resumed run diverge from an unsaved one
		# without anybody noticing.
		"rng_state": _rng.get_state() if _rng != null else 0,
	}


func from_data(d: Dictionary) -> void:
	phase = int(d.get("phase", RunPhase.MAP))
	run_seed = int(d.get("run_seed", 0))
	ranked = bool(d.get("ranked", false))
	mode = String(d.get("mode", "short"))
	ascension = int(d.get("ascension", 0))

	roster.assign(_roster_from_data(d.get("roster", [])))
	_next_persistent_id = int(d.get("next_persistent_id", roster.size() + 1))
	map_graph = (d.get("map_graph", {}) as Dictionary).duplicate(true)
	current_node_id = String(d.get("current_node_id", ""))
	visited_node_ids.assign(d.get("visited_node_ids", []))

	shards_this_run = int(d.get("shards_this_run", 0))
	power_level = int(d.get("power_level", 0))
	owned_relic_ids.assign(d.get("owned_relic_ids", []))
	bonus_reroll = int(d.get("bonus_reroll", 0))
	boss_plan.assign(d.get("boss_plan", []))
	run_mods = _run_mods_from_data(d.get("run_mods", {}))

	reward_reroll_charges = int(d.get("reward_reroll_charges", 1))
	reward_reroll_max = int(d.get("reward_reroll_max", 1))
	_reward_reroll_salt = int(d.get("reward_reroll_salt", 0))
	_reward_reroll_tier = int(d.get("reward_reroll_tier", 0))
	_reward_reroll_pw = int(d.get("reward_reroll_pw", 0))
	_reward_reroll_count = int(d.get("reward_reroll_count", 0))
	_run_end_processed = bool(d.get("run_end_processed", false))
	pending_rewards.assign(d.get("pending_rewards", []))
	_rng = Rng.new(int(d.get("rng_state", run_seed)))


## Roster entries survive JSON intact except for `growth`, whose keys are integers — see
## _int_keyed(). Every numeric field is re-cast because JSON.parse_string returns every number
## as a float: `tier` would come back as 1.0, and `"T%d" % tier` on a float is a different
## string than on an int.
func _roster_from_data(raw: Array) -> Array:
	var out: Array = []
	for e in raw:
		var entry: Dictionary = (e as Dictionary).duplicate(true)
		entry["persistent_id"] = int(entry.get("persistent_id", 0))
		entry["tier"] = int(entry.get("tier", 1))
		entry["max_hp"] = int(entry.get("max_hp", 0))
		entry["bonus_hp"] = int(entry.get("bonus_hp", 0))
		entry["growth"] = _int_keyed(entry.get("growth", {}))
		out.append(entry)
	return out


## Multipliers, so they must stay floats — but JSON gives back 1.0 for a value written as 1,
## and int()-ing them anywhere downstream would turn a 1.5x curse into 1x.
func _run_mods_from_data(raw: Dictionary) -> Dictionary:
	return {
		"enemy_hp": float(raw.get("enemy_hp", 1.0)),
		"enemy_dmg": float(raw.get("enemy_dmg", 1.0)),
	}


## Writes the resumable slot. `combat_state` is CombatEngine._state_dict() when a fight is in
## progress, or {} on the map. Mirrors JS saveRun(): a finished run is never written — the
## slot is removed instead, so "there is a save" and "the run is resumable" cannot disagree.
func save_run(combat_state: Dictionary = {}) -> void:
	if phase == RunPhase.WON or phase == RunPhase.LOST or phase == RunPhase.MENU:
		clear_saved_run()
		return
	var payload := {
		"version": SAVE_VERSION,
		"run": to_data(),
		"combat": combat_state.duplicate(true),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("RunState: could not open %s for writing" % SAVE_PATH)
		return
	f.store_string(JSON.stringify(payload))
	f.close()


func has_saved_run() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Restores a saved run into this autoload and returns true on success. Returns false — having
## changed nothing — for a missing, unreadable, malformed or wrong-version file, so a caller
## can fall back to the main menu instead of dropping the player into a half-built run.
func load_run() -> bool:
	if not has_saved_run():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		push_warning("RunState: could not open %s for reading" % SAVE_PATH)
		return false
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("RunState: save file is not a JSON object — ignoring it")
		return false
	var payload: Dictionary = parsed
	if int(payload.get("version", -1)) != SAVE_VERSION:
		push_warning("RunState: save file is version %s, this build reads %d — ignoring it"
			% [payload.get("version", "?"), SAVE_VERSION])
		return false
	var run_data = payload.get("run", null)
	if typeof(run_data) != TYPE_DICTIONARY:
		push_warning("RunState: save file has no run data — ignoring it")
		return false

	reset()
	from_data(run_data)
	var combat = payload.get("combat", {})
	resume_combat = (combat as Dictionary).duplicate(true) if typeof(combat) == TYPE_DICTIONARY else {}
	return true


func clear_saved_run() -> void:
	if not has_saved_run():
		return
	var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if err != OK:
		push_warning("RunState: could not delete %s (error %d)" % [SAVE_PATH, err])
