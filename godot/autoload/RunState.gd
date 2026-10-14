extends Node
## In-run state (~= JS `S`). Lives for exactly one run: New Run → Result → back to
## MainMenu, at which point reset() re-instantiates every sub-object rather than
## clearing fields one by one (see architecture plan §4, §9 self-critique #2 — a
## field added later and never wired into reset() is how JS's own UID-desync class of
## bug happened; re-instantiating wholesale removes that failure mode by construction).

## PACT (appended last so saved phase numbers keep their meaning): after a non-final boss win, before the
## reward cards. relic-set-v2 §4.4, ascension-v2 A6/A10.
enum RunPhase { MENU, MAP, EVENT, SHOP, TREASURE, COMBAT, REWARD, WON, LOST, PACT }

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

## The whole run's combat totals, folded in from every fight as it ends — damage dealt and
## taken, turns played, kills, and the single biggest hit. `max_hit` is a MAXIMUM, not a sum;
## the rest add up.
##
## CombatEngine has counted all five since the beginning, and nothing outside that object ever
## read them, so the end-of-run screen documented them as "not tracked anywhere reachable" and
## showed nothing. They were tracked; they just never left the fight they happened in.
var run_stats: Dictionary = {"dmg": 0, "taken": 0, "turns": 0, "kills": 0, "max_hit": 0,
	"dmg_dealt_clamped": 0}
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

## Where every random draw of the rules gets its seed (L1 contract 1). Local for tests/dev/bots,
## Tape for the verifier/tutorial, Remote (lane S) for real runs. Set by the start_* functions.
var epoch: EpochSource = null
## True while an async request_* is waiting for a seed: every other action must be refused,
## because changing the log between request and reply would make the server's `h` disagree.
var epoch_busy: bool = false
## Relic run-level state (H6, contract 2.3): id -> plain-JSON Dictionary owned by that relic's handlers.
## Copied into pending_combat as `relic_state` and written back from get_result()["relic_state"].
var relic_state: Dictionary = {}
## id -> "eternal" (ascension sticker). Eternal relics cannot be sold.
var relic_stickers: Dictionary = {}
## Pact relic ids taken this run, kept after they are sold (drawbacks/offers care about history).
var pacts_taken: Array[String] = []
## Boss Pact screen (relic-set-v2 §4.4). Relic ids on offer (empty = no pact phase), whether skipping is
## refused (RelicSlots.pact_forced) and the boss' index (0 = first boss). Saved so a resume mid-phase works.
var pending_pact: Array[String] = []
var pending_pact_forced: bool = false
var pending_pact_boss_index: int = 0
## Swaps made on this Pact screen (R5). Display/cap only, the rules never branch on it.
var pending_pact_swaps: int = 0
## The pact offer's RNG is the boss reward epoch seed xor this salt: no new epoch kind (the Worker has none)
## and no way to fish, since the reward seed is already fixed by the server.
const PACT_SEED_SALT := 0x5AC7B055
## Aid R5 (swap one Pact card): the replacement is drawn from Rng(epoch seed of the `pact_reroll` request ^ this).
## The epoch seed already binds run + pact node + slot + request seq (= the swap index), so it is deterministic.
const PACT_REROLL_SALT := 0x70AC7E11
## Loadout Boon (design/l1-boons.md). Never read by combat rules: boon_numbers_for_fight() turns it into
## plain numbers on the combat setup (MON-13). "" when none, or when the run is a mission.
var boon_id: String = ""
## Account is in its first runs: attrition and the light clock are off. Fixed at run start (header).
var newcomer: bool = false
## Counters that scope a Boon to "your first 3 fights", "first Boss", "first Battle reward".
var _rewarding_kind: String = ""
## Aid uses this run [{aid, node_id}], ONLY written by record_aid_use() and read by aid_uses_view() / the
## UI's AidCatalog. No rule may read it (t_mon13). The Boon (R8/R9) is not counted here: boon_used says so.
var aid_uses: Array[Dictionary] = []
var boon_used: bool = false
var _shop_refreshes: int = 0
## Mission (risk-to-earn) header: {mission_id, tier, rules:[...], condition?, stake, m_base, m_scale, m_eff}.
var mission: Dictionary = {}
var fights_started: int = 0
var bosses_started: int = 0
## Ascension from which the map generator forces the extra elite row (RunMapGenerator: ascension >= 9).
const ELITE_FORCED_ASC := 9
var first_battle_rewarded: bool = false
## Number of relic items the shop offers, after the H8 `shop_relic_count` hook. Applied by the
## shop generator once lane B's generate_shop_items takes a relic_count.
var _shop_relic_count: int = 2
## Seed of the `node` epoch of the node being visited. Treasure rewards draw from it.
var _node_seed: int = 0
## Rows whose node types the server has revealed (extra.row_types / Scout). {row:int -> Array}.
var row_types_known: Dictionary = {}

## Every decision this run, in order, for the replay-verify gate the port still owes
## (`scripts/core/action_log.gd` explains why it is recorded here and not in the UI).
## Always present, never null: a run whose log is missing cannot be told apart from a run whose
## log is empty, and only one of those is honest.
var action_log: ActionLog = ActionLog.new()

# ---------------------------------------------------------------------------
# Shop / event offers — OWNED HERE, not by the map screen.
#
# They used to live in RunMapController, which created their Rng itself. Nothing about that
# was random-by-accident (the seed was always `derive_combat_seed(run_seed, node_id, salt)`),
# but a verifier replaying an action log cannot reach into a scene to rebuild a stream. Owning
# them here is what makes a RUN replayable rather than only a combat: the same seed and the
# same decisions now rebuild the same shop, the same event, and the same purchases.
#
# It also fixes what the log could honestly say. `try_buy_shop_item(item)` took the item
# itself, so the log had to record the client's description of what was on sale; it now takes
# an INDEX into an offer the verifier re-derives.
# ---------------------------------------------------------------------------

var shop_items: Array[Dictionary] = []
var event_key: String = ""
var _shop_rng: Rng = null
var _event_rng: Rng = null

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
	run_stats = {"dmg": 0, "taken": 0, "turns": 0, "kills": 0, "max_hit": 0, "dmg_dealt_clamped": 0}
	# RunStats accumulator (design-handoff-v2 §09): reset() is the one place both a fresh
	# start_new_run() (which calls reset() first) and a test/screen that just finished reading
	# a completed run funnel through, so resetting RunStatsAccumulator here keeps it in lock
	# step with run_stats without a second call site to remember.
	RunStatsAccumulator.reset()
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
	epoch = null
	epoch_busy = false
	boon_id = ""
	aid_uses = []
	boon_used = false
	_shop_refreshes = 0
	mission = {}
	newcomer = false
	fights_started = 0
	bosses_started = 0
	first_battle_rewarded = false
	relic_state = {}
	relic_stickers = {}
	pacts_taken = []
	pending_pact = []
	pending_pact_forced = false
	pending_pact_boss_index = 0
	pending_pact_swaps = 0
	_shop_relic_count = 2
	_node_seed = 0
	row_types_known = {}
	action_log = ActionLog.new()
	shop_items = []
	event_key = ""
	_shop_rng = null
	_event_rng = null

## COMPATIBILITY ENTRY (L1 contract 1.4): the old synchronous start. `p_seed` becomes the secret of a
## LocalEpochSource, so the same seed still gives the same run (it is just a different run than before
## the epoch seam). New code uses begin_run() / start_run_with_epoch().
func start_new_run(p_seed: int, team_hero_keys: Array[String], p_mode: String,
		p_ascension: int, p_ranked: bool) -> void:
	start_run_with_epoch(LocalEpochSource.new(PackedByteArray(), p_seed), {
		"team_keys": team_hero_keys.duplicate(), "mode": p_mode, "ascension": p_ascension,
		"ranked": p_ranked}, p_seed)


## Synchronous start for sources that answer immediately (Local, Tape). Returns false (and starts
## nothing) when the source refuses or is remote. `display_seed` is only what the UI shows as "SEED".
func start_run_with_epoch(src: EpochSource, params: Dictionary, display_seed: int = -1) -> bool:
	reset()
	epoch = src
	var r := src.start_run(params)
	if not r.done:
		push_error("RunState.start_run_with_epoch: remote source, use begin_run()")
		epoch = null
		return false
	if not r.ok:
		push_error("RunState.start_run_with_epoch: epoch refused (%s)" % r.code)
		epoch = null
		return false
	_start_core(r, params, r.seed if display_seed < 0 else display_seed)
	return true


## Network session for RemoteEpochSource. A plain child node (not an autoload: an autoload named
## `RunSession` would collide with the class_name). Created on first use; tests may assign `session` first.
var session: RunSession = null


func run_session() -> RunSession:
	if session == null:
		session = RunSession.new()
		session.name = "RunSession"
		add_child(session)
	return session


## Async start used by the real menu flow (L/M wire it before the remote flag is switched on).
## Returns {ok, code}. Source = project setting `axie/epoch_source` ("local" by default).
func begin_run(params: Dictionary) -> Dictionary:
	if epoch_busy:
		return {"ok": false, "code": "busy"}
	# L1: chỉ N1-N3. Đường API trực tiếp cũng bị chặn, không chỉ nút trên MissionsScreen.
	var m_hdr: Dictionary = params.get("mission", {}) as Dictionary
	if String(params.get("kind", "")) == "mission" or not m_hdr.is_empty():
		if not MissionBoard.tier_enabled("N%d" % int(m_hdr.get("tier", 0))):
			return {"ok": false, "code": "tier_disabled"}
	var src: EpochSource = RemoteEpochSource.new(run_session()) if RemoteEpochSource.flag_on() \
			else LocalEpochSource.new(PackedByteArray(), randi())
	reset()
	epoch = src
	epoch_busy = true
	var r := src.start_run(params)
	if not r.done:
		await r.resolved
	epoch_busy = false
	if not r.ok:
		epoch = null
		return {"ok": false, "code": r.code}
	_start_core(r, params, r.seed)
	return {"ok": true, "code": ""}


## For a caller that already holds `epoch` and a run_start `seed` (tests, tools).
func start_new_run_seeded(seed: int, params: Dictionary) -> void:
	reset_keep_epoch()
	_start_core(EpochReply.ok_reply(seed, {}), params, seed)


func reset_keep_epoch() -> void:
	var keep := epoch
	reset()
	epoch = keep


func _start_core(start_reply: EpochReply, params: Dictionary, display_seed: int) -> void:
	var p_seed := start_reply.seed
	var team_hero_keys: Array[String] = []
	for k in (params.get("team_keys", []) as Array):
		team_hero_keys.append(String(k))
	var p_mode := String(params.get("mode", "short"))
	var p_ascension := int(params.get("ascension", 0))
	var p_ranked := bool(params.get("ranked", false))
	run_seed = display_seed
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
	# A verifier replays on a machine whose MetaState is not the player's, so bonuses may be handed in
	# through params (they travel in the signed header's loadout) instead of read from MetaState.
	var meta_bonus: Dictionary = (params["bonuses"] as Dictionary) if params.has("bonuses") \
		else MetaState.run_bonuses(ranked)
	bonus_reroll = int(meta_bonus.get("bonus_reroll", 0))
	var meta_hp := int(meta_bonus.get("hp_bonus", 0))
	reward_reroll_max = int(meta_bonus.get("reward_reroll_max", 1))
	# Ascension can cap the reward re-roll (A10 = none), whatever the meta granted.
	var asc_rr := int(ContentDB.ascension_mods(ascension).get("reward_reroll_max", -1))
	if asc_rr >= 0:
		reward_reroll_max = mini(reward_reroll_max, asc_rr)
	reward_reroll_charges = reward_reroll_max
	var hdr: Dictionary = start_reply.extra.get("header", {}) as Dictionary
	newcomer = bool(hdr.get("newcomer", params.get("newcomer", false)))
	mission = (hdr.get("mission", params.get("mission", {})) as Dictionary).duplicate(true)
	var is_mission := String(params.get("kind", "")) == "mission" or not mission.is_empty()
	var want_boon := String((params.get("loadout", {}) as Dictionary).get("boon_id", ""))
	boon_id = want_boon if (not is_mission and ContentDB.boons.has(want_boon)) else ""

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
	# M3 "Hunted" gives a mission run the two extra elites A9 already has; the generator keys them off
	# ascension >= 9, so a mission with M3 below A9 asks for the same map shape.
	# (mission_mods ignores min/max_ascension for the `standard` block; only listed rules are gated.)
	var map_asc := ascension
	if int(ContentDB.mission_mods(mission_rules(), ascension).get("extra_elite", 0)) > 0 and ascension < ELITE_FORCED_ASC:
		map_asc = ELITE_FORCED_ASC
	map_graph = RunMapGenerator.generate(_rng, mode, map_asc).to_data()
	# Opened AFTER the map exists, so a log never describes a run that failed to start. The
	# content version comes from part_faces.json's own stamp: the same actions against different
	# face values produce a different run, so a verifier has to refuse the mismatch rather than
	# replay it and disbelieve the score.
	# `ranked`, not `p_ranked` — the vault guard above may have downgraded the run, and a log
	# that claimed ranked while the run is not would be refused by the verifier for the wrong
	# reason (it would look like tampering rather than like an unranked run).
	action_log.begin(display_seed, team_hero_keys, mode, ascension,
		String(ContentDB.part_faces.get("engineVersion", "")), ranked)
	var loadout: Dictionary = (params.get("loadout", {}) as Dictionary).duplicate(true)
	loadout["bonuses"] = meta_bonus.duplicate(true)
	loadout["boon_id"] = boon_id
	var hdr_extra: Dictionary = start_reply.extra.get("header", {}) as Dictionary
	action_log.set_epoch_header(String(start_reply.extra.get("run_id", "")),
		String(start_reply.extra.get("client_nonce", "")), loadout,
		newcomer, mission)
	if epoch != null:
		epoch.bind_log(action_log)
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

## The loadout Boon as plain numbers for THIS fight. `fight_index` counts every Battle/Elite/Boss from 1
## (a Continue stays in the same fight); `boss_index` is 1 for the first Boss, 0 when this is not a boss.
## Combat receives only the numbers, never the Boon (MON-13).
func boon_numbers_for_fight(fight_index: int, boss_index: int) -> Dictionary:
	var out := {}
	if boon_id == "":
		return out
	var fx: Dictionary = (ContentDB.boons[boon_id] as Dictionary).get("effect", {})
	var scope: Dictionary = fx.get("scope", {})
	var in_scope := false
	if scope.has("fights"):
		for fx_idx in (scope["fights"] as Array):   # JSON numbers are floats: compare as ints
			if int(fx_idx) == fight_index:
				in_scope = true
	elif scope.has("boss_index"):
		in_scope = boss_index > 0 and int(scope["boss_index"]) == boss_index
	if not in_scope:
		return out
	out["bonus_reroll"] = int(fx.get("max_reroll_bonus", 0))
	out["start_shield_all"] = int(fx.get("turn1_shield_all", 0))
	out["start_mana"] = int(fx.get("start_mana", 0))
	out["first_dmg_face_bonus"] = int(fx.get("first_dmg_face_bonus", 0))
	out["start_eggs"] = int(fx.get("start_eggs", 0))
	return out


func mission_rules() -> Array:
	return (mission.get("rules", []) as Array).duplicate()


## Mission win = the final boss fell AND the offer's side condition holds (checked on the team the run
## started with). A normal run: just `won`.
func mission_outcome(won: bool) -> Dictionary:
	var cond_ok := true
	if not mission.is_empty():
		cond_ok = ContentDB.mission_condition_met(String(mission.get("condition", "")),
			action_log.header.get("team_keys", []) as Array)
	return {"won": won and cond_ok, "condition_ok": cond_ok}


## Telemetry for the server's runs.summary_json (B4, production/l1-telemetry.md). Numbers only, no player data;
## the server caps the whole thing at 2048 bytes. Never read by any rule. `escrow` = MetaState.mission_escrow
## as it was just before settling (empty outside a mission).
func close_summary(won: bool, condition_ok: bool, escrow: Dictionary = {}) -> Dictionary:
	var aids: Array = []
	for u in aid_uses:
		aids.append(String((u as Dictionary).get("aid", "")))
	var s := {"v": 1, "condition_ok": condition_ok, "battles_done": fights_started, "bosses_started": bosses_started,
		"nodes_done": power_level, "pw": power_level, "len": mode, "newcomer": newcomer,
		"client": str(ProjectSettings.get_setting("application/config/version", "")),
		"aids": aids, "boon_used": boon_used, "pacts": pacts_taken.size(), "relics": owned_relic_ids.size(),
		"shards": shards_this_run}
	if not mission.is_empty():
		s["mission"] = {"tier": str(mission.get("tier", "")), "stake": int(escrow.get("stake", mission.get("stake", 0))),
			"payout": int(escrow.get("payout", 0)) if won else 0, "won": won}
	return s


## The one writer of the Aid ledger. R8/R9 (Boon, Kit) only flip boon_used; they never enter `uses`.
func record_aid_use(aid_id: String) -> void:
	if not mission.is_empty():
		return   # no Aid in a mission run; nothing to count
	if aid_id == "boon" or aid_id == "kit":
		boon_used = true
		return
	aid_uses.append({"aid": aid_id, "node_id": current_node_id})


func aid_uses_view() -> Array:
	return aid_uses.duplicate(true)


## Appends the line the server returned for an Aid use to OUR log, so the hash chain matches
## (contract 1.5), and counts it. `args` are the Aid's own positional parameters.
func apply_aid_use(aid_id: String, args: Array = []) -> void:
	var line: Array = [aid_id]
	line.append_array(args)
	action_log.record("aid_use", line)
	record_aid_use(aid_id)


## What the UI needs to decide which Aid to offer (AidCatalog, lane E). Pure read.
func aid_context(combat: CombatEngine = null) -> Dictionary:
	var hud: Dictionary = combat.hud_state() if combat != null else {}
	return {"mode": mode, "mission": not (action_log.header.get("mission", {}) as Dictionary).is_empty(),
		"newcomer": newcomer, "ascension": ascension,
		"node_kind": String(pending_combat.get("kind", "")) if phase == RunPhase.COMBAT else "",
		"in_shop": phase == RunPhase.SHOP, "at_pact": false,
		"party_wiped": combat != null and combat.can_continue(),
		"rerolls_left": int(hud.get("rerolls", 0)),
		"clock_turns_left": int((hud.get("clock", {}) as Dictionary).get("turns_left", 0)),
		"uses": aid_uses_view(), "boon_used": boon_used, "vip": false, "free_continue_left": MetaState.free_continue_left()}


## Aid R6: a new shop row from `seed` (the old items, bought or not, are replaced). Logged as
## `shop_refresh` [k]. Price and the cap live with the server / AidCatalog, not here.
func refresh_shop(seed: int = -1) -> bool:
	if phase != RunPhase.SHOP:
		return false
	var sd := _epoch_seed("shop_refresh", {"node_id": current_node_id, "k": _shop_refreshes + 1}, seed)
	if sd < 0:
		return false
	_shop_refreshes += 1
	action_log.record("shop_refresh", [_shop_refreshes])
	_open_shop(current_node_id, sd, true)
	return true


## Seed for one boundary: the caller's, or (compat) one asked from the epoch source right now.
## Returns -1 and logs an error when none can be had; callers then do nothing.
func _epoch_seed(kind: String, args: Dictionary, given: int) -> int:
	if given >= 0:
		return given
	_ensure_epoch()
	var r := epoch.request(kind, args)
	if not r.done:
		push_error("RunState: '%s' needs the async request_* wrapper with a remote epoch source" % kind)
		return -1
	if not r.ok:
		push_error("RunState: epoch '%s' refused (%s)" % [kind, r.code])
		return -1
	return r.seed


## Tests and tools that build a RunState by hand never opened an epoch. Give them a started Local one
## keyed by run_seed, so the old synchronous calls keep working.
func _ensure_epoch() -> void:
	if epoch != null:
		return
	epoch = LocalEpochSource.new(PackedByteArray(), run_seed)
	epoch.start_run({"mode": mode, "ascension": ascension})
	epoch.bind_log(action_log)


## Async twin of enter_node(): asks for the `node` seed (waiting if remote), then enters.
func request_enter_node(node_id: String, node_kind: String) -> Dictionary:
	if epoch_busy:
		return {"ok": false, "code": "busy"}
	_ensure_epoch()
	epoch_busy = true
	var r := epoch.request("node", {"node_id": node_id})
	if not r.done:
		await r.resolved
	epoch_busy = false
	if not r.ok:
		return {"ok": false, "code": r.code}
	if r.extra.has("row_types"):
		reveal_rows(r.extra["row_types"] as Dictionary)
	enter_node(node_id, node_kind, r.seed)
	return {"ok": true, "code": ""}


## Generic request for the view (end_turn, reroll...). Caller checks `.done` / awaits `.resolved`.
func request_epoch(kind: String, args: Dictionary) -> EpochReply:
	_ensure_epoch()
	return epoch.request(kind, args)


## Rows whose node types were revealed to the player (Scout / node epoch). Recorded so a resumed
## run and the verifier know what the player has already seen.
func reveal_rows(row_types: Dictionary) -> void:
	for k in row_types.keys():
		row_types_known[int(k)] = (row_types[k] as Array).duplicate()


## Called by RunMapController when the player picks a valid node. Builds the CombatSetup
## data (not a live CombatEngine) and stores it in pending_combat for Combat.tscn to consume.
func enter_node(node_id: String, node_kind: String, seed: int = -1) -> void:
	# seed < 0 = compatibility path: ask the (Local/Tape) epoch for the `node` seed ourselves.
	var node_sd := _epoch_seed("node", {"node_id": node_id}, seed)
	if node_sd < 0:
		return
	_node_seed = node_sd
	action_log.record("enter_node", [node_id, node_kind])
	current_node_id = node_id
	match node_kind:
		"battle", "elite", "boss":
			set_phase(RunPhase.COMBAT)
			var combat_seed := node_sd
			fights_started += 1
			if node_kind == "boss":
				bosses_started += 1
			var boon_n := boon_numbers_for_fight(fights_started, bosses_started if node_kind == "boss" else 0)
			pending_combat = {
				"node_id": node_id,
				"kind": node_kind,
				"pw": power_level,
				"ascension": ascension,
				"roster_snapshot": roster.duplicate(true),
				"relic_ids": owned_relic_ids.duplicate(),
				"combat_seed": combat_seed,
				"bonus_reroll": bonus_reroll + int(boon_n.get("bonus_reroll", 0)),
				"newcomer": newcomer,
				"mission": not mission.is_empty(),
				"mission_rules": mission_rules(),
				"start_shield_all": int(boon_n.get("start_shield_all", 0)),
				"start_mana": int(boon_n.get("start_mana", 0)),
				"first_dmg_face_bonus": int(boon_n.get("first_dmg_face_bonus", 0)),
				"start_eggs": int(boon_n.get("start_eggs", 0)),
				"run_mods": run_mods.duplicate(),
				"relic_state": relic_state.duplicate(true),
				# Compatibility: lets CombatEngine ask for end_turn/reroll seeds itself until the UI
				# does it (contract 1.4). Not serialised: pending_combat is consumed, never saved.
				"epoch": epoch,
			}
			if node_kind == "boss":
				pending_combat["boss_key"] = _boss_key_for_node(node_id)
			EventBus.node_entered.emit(node_kind, node_id)
		"event":
			_open_event(node_id, node_sd)
			set_phase(RunPhase.EVENT)
			EventBus.node_entered.emit(node_kind, node_id)
		"shop":
			_open_shop(node_id, node_sd)
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
func apply_combat_result(res: Dictionary, reward_seed: int = -1) -> void:
	# Folded in BEFORE the won/lost branch: a run that ended in defeat still fought, and a
	# result screen that showed zeroes after a long losing run would be reporting the loss
	# twice.
	_fold_combat_stats(res.get("stat", {}))
	MetaState.note_run_battle(run_seed)   # H11 newcomer counter (lane E)
	if res.has("relic_state"):
		relic_state = (res["relic_state"] as Dictionary).duplicate(true)
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
			var reward_sd := _epoch_seed("reward", {"node_id": current_node_id}, reward_seed)
			if reward_sd < 0:
				return
			_generate_post_combat_rewards(res, reward_sd)
			if kind == "boss" and _open_pact_phase(reward_sd):
				set_phase(RunPhase.PACT)
			else:
				set_phase(RunPhase.REWARD)
	else:
		set_phase(RunPhase.LOST)
		EventBus.run_ended.emit(false)


## Adds one fight's counters onto the run's. `max_hit` takes the larger of the two — summing
## it would invent a hit nobody landed, which is exactly the kind of number a player would
## screenshot.
func _fold_combat_stats(raw) -> void:
	if not (raw is Dictionary):
		return
	var stat: Dictionary = raw
	for key in ["dmg", "taken", "turns", "kills", "dmg_dealt_clamped"]:
		run_stats[key] = int(run_stats.get(key, 0)) + int(stat.get(key, 0))
	run_stats["max_hit"] = maxi(int(run_stats.get("max_hit", 0)), int(stat.get("max_hit", 0)))


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
	# Lane E: settle the mission escrow (and save) BEFORE the saved run is cleared (kill-safe).
	var _esc: Dictionary = (MetaState.mission_escrow as Dictionary).duplicate()   # settle clears it; the summary needs the payout
	MetaState.settle_mission_for_run(String(mission.get("mission_id", "")), bool(mission_outcome(won)["won"]))
	clear_saved_run()
	if epoch != null:
		var mo := mission_outcome(won)
		epoch.close("won" if bool(mo["won"]) else "lost", close_summary(bool(mo["won"]), bool(mo["condition_ok"]), _esc))
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
	# Lane E hooks (present once l1/E is merged; has_method keeps this safe before that).
	if MetaState.has_method("record_run_outcome"):
		# Params are rebuilt from fields that already live in to_data() (a stored run_params would make
		# the RunVerifier replay digest differ). `won` here is the MISSION-aware win (final boss fell AND
		# the offer condition held); MetaState.wins/asc_max above use the raw `won` as the JS ladder does.
		MetaState.call("record_run_outcome", {"mode": mode, "ascension": ascension, "ranked": ranked,
			"reached_boss": bosses_started > 0, "mission_id": String(mission.get("mission_id", ""))},
			bool(mission_outcome(won)["won"]))
	if MetaState.has_method("pass_add_run_xp"):
		MetaState.call("pass_add_run_xp", last_run_xp)
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
	var base := int(ContentDB.ascension_mods(ascension).get("rewards", 3))
	if boon_id != "" and not first_battle_rewarded and _rewarding_kind == "battle":
		var fx: Dictionary = (ContentDB.boons[boon_id] as Dictionary).get("effect", {})
		if bool((fx.get("scope", {}) as Dictionary).get("first_battle_reward", false)):
			base += int(fx.get("reward_extra_cards", 0))
	return int(RelicHooks.run_value(owned_relic_ids, "reward_card_count",   # H8
		{"ascension": ascension, "kind": "reward"}, base))


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
func _generate_post_combat_rewards(res: Dictionary, reward_sd: int) -> void:
	var kind := String(res.get("kind", "battle"))
	_rewarding_kind = kind
	var pw := int(res.get("pw", power_level))
	# src/engine.js finishCombat(): s.rewardTier = boss?3 : elite?2 : (s.step%3===0?1:0). This
	# vertical slice's branching RunMap has no linear "step" counter (rule spec §9 note: "cần
	# verify lại khi số node/hàng thay đổi khi không còn 1 tuyến cố định") — approximated
	# with power_level (0-indexed, standing in for JS's 1-indexed step) below.
	var tier := 3 if kind == "boss" else (2 if kind == "elite" else (1 if (power_level + 1) % 3 == 0 else 0))
	_set_pending_rewards(tier, pw, reward_sd)
	if kind == "battle":
		first_battle_rewarded = true   # the Boon's extra card applies to the FIRST battle reward only
	_rewarding_kind = ""


## src/engine.js chooseNode() 'treasure' branch (engine.js:402): `s.rewardTier=1;
## genRewards(s,'treasure')` — a real N-card offer at tier 1, same mechanism as a combat
## reward, NOT an instant single-card grant (that was this port's own earlier simplification
## — see RunMapController._on_treasure_node()'s history). `node_id` seeds a salt distinct
## from every other overlay flow (RunMapController._node_rng()'s convention).
func generate_treasure_rewards(_node_id: String) -> void:
	_set_pending_rewards(1, power_level, _node_seed)


func _set_pending_rewards(tier: int, pw: int, seed: int) -> void:
	_reward_reroll_tier = tier
	_reward_reroll_pw = pw
	_reward_reroll_count = _reward_count()
	_reward_reroll_salt = 0   # now: how many rerolls this offer has had (the `k` of the epoch)
	reward_reroll_charges = int(RelicHooks.run_value(owned_relic_ids, "reward_reroll_charges",   # H8
		{"ascension": ascension, "kind": "reward"}, reward_reroll_max))
	var reward_rng := Rng.new(seed)
	pending_rewards = RewardGenerator.generate(pw, tier, reward_rng, owned_relic_ids, roster,
		effective_max_rerolls(), _reward_reroll_count)


## src/engine.js rerollRewards() (engine.js:1163-1166): spends 1 s.rerollReward charge and
## redraws the SAME tier/pw offer. Uses a bumped salt (never the original 601/503 draw) so a
## reroll can never reproduce the exact offer it just replaced.
func reroll_pending_rewards(seed: int = -1) -> bool:
	if reward_reroll_charges <= 0 or pending_rewards.is_empty():
		return false
	var sd := _epoch_seed("reward_reroll", {"k": _reward_reroll_salt + 1}, seed)
	if sd < 0:
		return false
	action_log.record("reroll_rewards", [])
	reward_reroll_charges -= 1
	_reward_reroll_salt += 1
	var reward_rng := Rng.new(sd)
	pending_rewards = RewardGenerator.generate(_reward_reroll_pw, _reward_reroll_tier, reward_rng,
		owned_relic_ids, roster, effective_max_rerolls(), _reward_reroll_count)
	return true


## Applies ONE reward card's effect (RewardGenerator.generate() output) and clears
## pending_rewards. Deliberately never calls after_node() itself (see the ordering-fix note
## above) — every caller (RunMapController._on_reward_chosen(), shared by the post-combat
## and treasure flows) calls after_node() itself right after this, exactly like it already
## does for event/shop nodes.
func apply_chosen_reward(reward: Dictionary) -> void:
	# The INDEX into the offer, not the reward itself. A log carrying the reward would be the
	# client telling the verifier what it was given; the verifier re-derives the offer from the
	# seed and only needs to know which one was taken. A reward that is not in `pending_rewards`
	# has no index, so it is recorded as a hole in the log rather than silently omitted —
	# `action_log.is_complete()` is what any caller must check before trusting the record.
	var offer_index := pending_rewards.find(reward)
	if offer_index >= 0:
		action_log.record("take_reward", [offer_index])
	else:
		action_log.rejected.append("take_reward: chosen reward was not in pending_rewards")
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
				_grant_relic(rid, "reward")
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
				_grant_relic(rid2, "reward")
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


# ---------------------------------------------------------------------------------------
# BOSS PACT (relic-set-v2 §4.4; ascension-v2 A6 first boss / A10 every boss forced)
# ---------------------------------------------------------------------------------------

func _pact_ctx() -> Dictionary:
	return {"owned_ids": owned_relic_ids, "roster": roster, "ascension": ascension,
		"pacts_taken": pacts_taken, "stickers": relic_stickers}


## Draws the Pact offer after a non-final boss win. False (no phase) when no valid pact is left.
func _open_pact_phase(reward_sd: int) -> bool:
	pending_pact = []
	pending_pact_swaps = 0
	var idx := maxi(bosses_started - 1, 0)
	var offer := RewardGenerator.pick_pact_offer(Rng.new(reward_sd ^ PACT_SEED_SALT), _pact_ctx())
	for d in offer:
		pending_pact.append(String(d.id))
	if pending_pact.is_empty():
		return false
	pending_pact_boss_index = idx
	pending_pact_forced = RelicSlots.pact_forced(ascension, idx)
	return true


## What the Pact screen draws: [{id, name, description, group, rarity, ok, needs_sell, sell_from}].
func pact_cards() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in pending_pact:
		var d = RelicRegistry.get_def(id)
		var chk := RelicSlots.check_add(owned_relic_ids, relic_stickers, id, ascension, pending_pact_forced)
		out.append({"id": id, "name": String(d.name), "description": String(d.description),
			"group": String(d.pact_group), "rarity": int(d.rarity), "ok": bool(chk["ok"]),
			"swap_ok": pact_swap_possible(out.size()),
			"needs_sell": bool(chk["needs_sell"]), "sell_from": (chk["sell_from"] as Array).duplicate()})
	return out


func pact_can_skip() -> bool:
	return phase == RunPhase.PACT and not pending_pact_forced


## Takes pact `index` of the offer. When the slot is full the caller names `sell_id` (one of
## pact_cards()[index].sell_from); the sale is part of this one `pact_pick` log line, not a swap_on_full.
func take_pact(index: int, sell_id: String = "") -> bool:
	if phase != RunPhase.PACT or index < 0 or index >= pending_pact.size():
		return false
	var id := pending_pact[index]
	var chk := RelicSlots.check_add(owned_relic_ids, relic_stickers, id, ascension, pending_pact_forced)
	if not bool(chk["ok"]):
		return false
	if bool(chk["needs_sell"]):
		if sell_id == "" or not (chk["sell_from"] as Array).has(sell_id):
			return false
		shards_this_run += RelicSlots.sell_price(sell_id, ascension)
		owned_relic_ids.erase(sell_id)
		relic_state.erase(sell_id)
		relic_stickers.erase(sell_id)
		action_log.record("pact_pick", [index, sell_id])
	elif sell_id != "":
		return false
	else:
		action_log.record("pact_pick", [index])
	_grant_relic(id, "pact")
	_close_pact_phase()
	return true


## Aid R5: replaces card `slot` of the open Pact offer with a fresh one (see RewardGenerator.pick_pact_replacement).
## Logs `pact_reroll` [slot, swap index]. Price and caps (1 per pact, 4 per run, total Aid cap) live with the
## server / AidCatalog, not here. `seed` < 0 asks the epoch (local); a remote caller passes the seed it got.
func reroll_pact_slot(slot: int, seed: int = -1) -> bool:
	if phase != RunPhase.PACT or slot < 0 or slot >= pending_pact.size():
		return false
	var sd := _epoch_seed("pact_reroll", {"node_id": current_node_id, "slot": slot}, seed)
	if sd < 0:
		return false
	var keep: Array = []
	for i in pending_pact.size():
		if i != slot:
			keep.append(pending_pact[i])
	var pick = RewardGenerator.pick_pact_replacement(Rng.new(sd ^ PACT_REROLL_SALT), _pact_ctx(), keep, pending_pact[slot])
	if pick == null:
		return false
	pending_pact_swaps += 1
	action_log.record("pact_reroll", [slot, pending_pact_swaps])
	pending_pact[slot] = String(pick.id)
	return true


## True when card `slot` can be swapped right now: PACT phase, slot in range, and at least one eligible
## replacement exists. `pick_pact_replacement` returns null only when its candidate list is empty, whatever the
## seed, so this answer cannot change between the check and the draw (a paid request that then fails is impossible).
func pact_swap_possible(slot: int) -> bool:
	if phase != RunPhase.PACT or slot < 0 or slot >= pending_pact.size():
		return false
	var keep: Array = []
	for i in pending_pact.size():
		if i != slot:
			keep.append(pending_pact[i])
	return RewardGenerator.pick_pact_replacement(Rng.new(0), _pact_ctx(), keep, pending_pact[slot]) != null


## Async twin for the Pact screen: asks the epoch (waiting if remote), then swaps. Validates BEFORE the request,
## because a remote request charges the Gem.
func request_pact_reroll(slot: int) -> Dictionary:
	if epoch_busy or not pact_swap_possible(slot):
		return {"ok": false, "code": "busy" if epoch_busy else "illegal"}
	_ensure_epoch()
	epoch_busy = true
	var r := epoch.request("pact_reroll", {"node_id": current_node_id, "slot": slot})
	if not r.done:
		await r.resolved
	epoch_busy = false
	if not r.ok:
		return {"ok": false, "code": r.code}
	if not reroll_pact_slot(slot, r.seed):
		return {"ok": false, "code": "illegal"}
	return {"ok": true, "code": ""}


## Leaves the Pact screen with nothing. Refused when the pact is forced. Logged as pact_pick -1.
func skip_pact() -> bool:
	if not pact_can_skip():
		return false
	action_log.record("pact_pick", [-1])
	_close_pact_phase()
	return true


func _close_pact_phase() -> void:
	pending_pact = []
	pending_pact_forced = false
	pending_pact_swaps = 0
	set_phase(RunPhase.REWARD)


## Builds this node's shop offer. Called from enter_node(), so a replay that applies the same
## `enter_node` action gets the same three items in the same order without being told them.
func _open_shop(_node_id: String, seed: int, is_refresh: bool = false) -> void:
	if not is_refresh:
		_shop_refreshes = 0
	_shop_relic_count = int(RelicHooks.run_value(owned_relic_ids, "shop_relic_count",   # H8
		{"ascension": ascension, "kind": "shop"}, 2))
	_shop_rng = Rng.new(seed)
	shop_items = []
	var price_mult := float(ContentDB.ascension_mods(ascension).get("shop_price_mult", 1.0))
	for raw in RewardGenerator.generate_shop_items(_shop_rng, owned_relic_ids):
		var it: Dictionary = (raw as Dictionary).duplicate(true)
		if price_mult != 1.0:
			it["cost"] = RulesMath.round_half_up(float(it.get("cost", 0)) * price_mult)   # A1: x1.15
		shop_items.append(it)


## Picks which event this node runs. Only events whose options actually DO something are
## eligible (ContentDB.playable_event_keys) — offering an unported option means the player
## chooses and nothing happens, which is indistinguishable from a bug.
func _open_event(_node_id: String, seed: int) -> void:
	_event_rng = Rng.new(seed)
	var keys := ContentDB.playable_event_keys()
	event_key = "" if keys.is_empty() else String(keys[_event_rng.next_int(keys.size())])


## The options on offer at this event node, in the order the player sees them — which is the
## order `choose_event_option()` indexes into.
func event_options() -> Array:
	return [] if event_key.is_empty() else ContentDB.playable_event_options(event_key)


## The replayable way to resolve an event: an INDEX into the offer this run generated. Nothing
## about the option travels in the log, so a verifier re-derives the offer and checks the index
## against it.
func choose_event_option(index: int, seed: int = -1) -> String:
	var opts := event_options()
	if index < 0 or index >= opts.size():
		push_error("RunState.choose_event_option: index %d outside an offer of %d"
			% [index, opts.size()])
		return ""
	var sd := _epoch_seed("event_choice", {"index": index}, seed)
	if sd < 0:
		return ""
	action_log.record("event_choose", [index])
	var fx := String((opts[index] as Dictionary).get("fx", ""))
	_event_rng = Rng.new(sd)
	return apply_event_fx(fx, _event_rng)


## Ported subset of src/engine.js applyEventFx() (rule spec §9/§10) — only the fx values
## reachable from ContentDB.events' two implemented event defs (shrine/campfire). Returns
## the same kind of human-readable result message the JS version shows before eventDone().
##
## PURE APPLICATION, AND DELIBERATELY UNLOGGED. `choose_event_option()` is the entry point a
## player's click goes through and the one that writes to the action log; this is the half that
## t_event_effects walks exhaustively to prove every `fx` in ContentDB has a handler, which it
## cannot do through an index into an offer it would first have to conjure.
func apply_event_fx(fx: String, rng: Rng) -> String:
	match fx:
		"bless_reroll":
			bonus_reroll += 1
			return "You permanently gain 1 maximum Reroll."
		"gamble_legend":
			var def := RewardGenerator.pick_relic(rng, owned_relic_ids, 3, 3)
			if def == null:
				def = RewardGenerator.pick_relic(rng, owned_relic_ids, 0, 2)
			if def != null:
				_grant_relic(def.id, "event")
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
				_grant_relic(def2.id, "event")
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
					_grant_relic(won_relic.id, "event")
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
	push_error("RunState.apply_event_fx: no handler for fx '%s' — the option should not "
		% fx + "have been offered (see ContentDB.playable_event_options)")
	return ""


## src/data.js shopBuy() ported subset. Takes an INDEX into `shop_items` — the offer this run
## generated — so the action log records a choice rather than a description of the goods.
## `_shop_rng` is the same stream the offer was generated from, continued here for the "heal"
## item's random target pick (src/engine.js's `pick(s.roster)`); continuing it rather than
## starting a fresh one is what makes the purchase order part of the replay.
func try_buy_shop_item(index: int, seed: int = -1) -> bool:
	if index < 0 or index >= shop_items.size():
		return false
	var item: Dictionary = shop_items[index]
	if bool(item.get("bought", false)):
		return false
	var cost := int(item.get("cost", 0))
	if shards_this_run < cost:
		return false
	var rng: Rng = null
	if shop_item_needs_epoch(index):
		var sd := _epoch_seed("shop_roll", {"node_id": current_node_id, "item": index}, seed)
		if sd < 0:
			return false
		rng = Rng.new(sd)
	action_log.record("shop_buy", [index])
	shards_this_run -= cost
	match String(item.get("kind", "")):
		"relic":
			var rid := String(item.get("key", ""))
			if rid != "" and not owned_relic_ids.has(rid):
				_grant_relic(rid, "reward")
		"heal":
			if not roster.is_empty():
				var e: Dictionary = roster[rng.next_int(roster.size())]
				e["bonus_hp"] = int(e.get("bonus_hp", 0)) + int(item.get("v", 10))
		"reroll":
			bonus_reroll += 1
	# Marked here, not by the caller. The screen used to set it after the fact, which meant a
	# replay — which has no screen — left every item buyable forever.
	item["bought"] = true
	return true


## True when buying this item draws randomness (today only "heal": it picks the Axie), so the UI
## must ask for a `shop_roll` epoch first. Other items are bought without one.
func shop_item_needs_epoch(index: int) -> bool:
	if index < 0 or index >= shop_items.size():
		return false
	return String((shop_items[index] as Dictionary).get("kind", "")) == "heal"


## Puts a relic in the owned list (order of pickup is the order hooks fire in) and tells the relics
## that care. Slot capacity is NOT checked here: the UI asks acquire_relic() first when a slot may be
## full; the plain reward/shop/event paths grant directly, as before the slot model existed.
func _grant_relic(relic_id: String, source: String) -> void:
	if relic_id == "" or owned_relic_ids.has(relic_id):
		return
	owned_relic_ids.append(relic_id)
	if RelicSlots.is_pact(relic_id) and not pacts_taken.has(relic_id):
		pacts_taken.append(relic_id)
	# Eternal sticker (ascension.json `eternal_max`, relic-set-v2 A5): the first N non-pact relics the run
	# acquires are stuck (cannot be sold). Deterministic from the grant order, so replay needs no extra log.
	# H8: the starting relic (u_start) is appended directly in start_new_run_seeded, never through here, so it never counts.
	var eternal_max := int(ContentDB.ascension_mods(ascension).get("eternal_max", 0))
	if eternal_max > 0 and not RelicSlots.is_pact(relic_id) and not relic_id.begins_with("__") \
			and relic_stickers.size() < eternal_max:
		relic_stickers[relic_id] = RelicSlots.STICKER_ETERNAL
	RelicHooks.run_fire(owned_relic_ids, "on_relic_acquired", {"relic_id": relic_id, "source": source})   # H8


## Takes a relic respecting the slot rules (RelicSlots.check_add). When every slot of its kind is
## full the caller must name `sell_id` from check.sell_from; that is logged as `swap_on_full`.
func acquire_relic(relic_id: String, source: String, sell_id: String = "") -> bool:
	var chk := RelicSlots.check_add(owned_relic_ids, relic_stickers, relic_id, ascension, false)
	if not bool(chk["ok"]):
		return false
	if bool(chk["needs_sell"]):
		if sell_id == "" or not (chk["sell_from"] as Array).has(sell_id):
			return false
		shards_this_run += RelicSlots.sell_price(sell_id, ascension)
		owned_relic_ids.erase(sell_id)
		relic_state.erase(sell_id)
		relic_stickers.erase(sell_id)
		action_log.record("swap_on_full", [sell_id, relic_id])
	elif sell_id != "":
		return false
	_grant_relic(relic_id, source)
	return true


## Sells an owned, non-Eternal relic for Gene Shards. Not while a fight is open.
func sell_relic(relic_id: String) -> bool:
	if not owned_relic_ids.has(relic_id) or relic_stickers.get(relic_id, "") == RelicSlots.STICKER_ETERNAL:
		return false
	if phase == RunPhase.COMBAT:
		return false
	shards_this_run += RelicSlots.sell_price(relic_id, ascension)
	owned_relic_ids.erase(relic_id)
	relic_state.erase(relic_id)
	action_log.record("sell_relic", [relic_id])
	return true


## Re-orders the party (positional relics read the slot). `order` = persistent_ids, a permutation.
## Only on the map: slot changes mid-fight would move "next to" under the player's feet.
func reorder_party(order: Array) -> bool:
	if phase != RunPhase.MAP or order.size() != roster.size():
		return false
	var by_pid: Dictionary = {}
	for e in roster:
		by_pid[int(e.get("persistent_id", -1))] = e
	var out: Array[Dictionary] = []
	for pid in order:
		if not by_pid.has(int(pid)):
			return false
		out.append(by_pid[int(pid)])
		by_pid.erase(int(pid))
	roster = out
	action_log.record("reorder_party", [_int_array(order)])
	return true


static func _int_array(a: Array) -> Array:
	var out: Array = []
	for x in a:
		out.append(int(x))
	return out


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
const SAVE_VERSION := 2

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
		"run_stats": run_stats.duplicate(true),
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
		# The shop/event offer, and the shop stream's POSITION. The offer itself is re-derivable
		# from (run_seed, node_id, salt), but `bought` flags and how far the stream has been
		# drawn are not: resuming a half-shopped node without them hands the player the same
		# three items to buy a second time, and moves the "heal" pick onto a different Axie
		# than the unsaved run would have.
		"shop_items": shop_items.duplicate(true),
		"event_key": event_key,
		"shop_rng_state": _shop_rng.get_state() if _shop_rng != null else 0,
		"event_rng_state": _event_rng.get_state() if _event_rng != null else 0,
		# Epoch seam (contract 1.5). The tape lets a resumed run keep its sequence and hash chain;
		# the log is saved with it because the chain is computed over it.
		"epoch_tape": epoch.tape() if epoch != null else [],
		"epoch_seq": (epoch.tape().size() if epoch != null else 0),
		"run_id": String(action_log.header.get("run_id", "")),
		"node_seed": _node_seed,
		"mission": mission.duplicate(true),
		"aid_uses": aid_uses.duplicate(true), "boon_used": boon_used, "shop_refreshes": _shop_refreshes,
		"boon_id": boon_id, "newcomer": newcomer, "fights_started": fights_started,
		"bosses_started": bosses_started, "first_battle_rewarded": first_battle_rewarded,
		"relic_state": relic_state.duplicate(true),
		"relic_stickers": relic_stickers.duplicate(true),
		"pacts_taken": pacts_taken.duplicate(),
		"pending_pact": pending_pact.duplicate(), "pending_pact_forced": pending_pact_forced,
		"pending_pact_boss_index": pending_pact_boss_index, "pending_pact_swaps": pending_pact_swaps,
		"row_types_known": row_types_known.duplicate(true),
		"action_log": action_log.to_data(),
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

	var saved_shop: Array = d.get("shop_items", []) as Array
	shop_items = []
	for raw in saved_shop:
		if raw is Dictionary:
			shop_items.append((raw as Dictionary).duplicate(true))
	event_key = String(d.get("event_key", ""))
	# `Rng.new(get_state())` is an exact position-in-stream restore, not a reseed — rng.gd's
	# own header says so, because _init() assigns the state with no extra math.
	_shop_rng = Rng.new(int(d.get("shop_rng_state", 0)))
	_event_rng = Rng.new(int(d.get("event_rng_state", 0)))

	shards_this_run = int(d.get("shards_this_run", 0))
	var saved_stats: Dictionary = (d.get("run_stats", {}) as Dictionary)
	run_stats = {}
	for key in ["dmg", "taken", "turns", "kills", "max_hit", "dmg_dealt_clamped"]:
		run_stats[key] = int(saved_stats.get(key, 0))
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
	_node_seed = int(d.get("node_seed", 0))
	mission = (d.get("mission", {}) as Dictionary).duplicate(true)
	aid_uses.assign(d.get("aid_uses", []))
	boon_used = bool(d.get("boon_used", false))
	_shop_refreshes = int(d.get("shop_refreshes", 0))
	boon_id = String(d.get("boon_id", ""))
	newcomer = bool(d.get("newcomer", false))
	fights_started = int(d.get("fights_started", 0))
	bosses_started = int(d.get("bosses_started", 0))
	first_battle_rewarded = bool(d.get("first_battle_rewarded", false))
	relic_state = (d.get("relic_state", {}) as Dictionary).duplicate(true)
	relic_stickers = (d.get("relic_stickers", {}) as Dictionary).duplicate(true)
	pacts_taken.assign(d.get("pacts_taken", []))
	pending_pact.assign(d.get("pending_pact", []))
	pending_pact_forced = bool(d.get("pending_pact_forced", false))
	pending_pact_boss_index = int(d.get("pending_pact_boss_index", 0))
	pending_pact_swaps = int(d.get("pending_pact_swaps", 0))
	row_types_known = {}
	for rk in (d.get("row_types_known", {}) as Dictionary).keys():
		row_types_known[int(rk)] = ((d["row_types_known"] as Dictionary)[rk] as Array).duplicate()
	if d.has("action_log"):
		action_log = ActionLog.from_data(d["action_log"] as Dictionary)
		var tape_in := ActionLog._restore_ints(d.get("epoch_tape", [])) as Array
		if RemoteEpochSource.flag_on():
			var remote := RemoteEpochSource.new(run_session())
			remote.resume(tape_in, run_session())
			remote.bind_log(action_log)
			epoch = remote
		else:
			var local := LocalEpochSource.new(PackedByteArray(), int(action_log.header.get("local_secret", 0)))
			local.resume(tape_in)
			local.bind_log(action_log)
			epoch = local


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
		"rules_version": ActionLog.RULES_VERSION,   # a run must never continue under different rules
		"run": to_data(),
		"combat": combat_state.duplicate(true),
	}
	# Through SaveStore: on a web build `user://` does not reliably survive a page reload, and
	# a half-finished run is exactly what a player expects to still be there tomorrow. See
	# save_store.gd's header for the measurement.
	if not SaveStore.write_text(SAVE_PATH, JSON.stringify(payload)):
		push_error("RunState: could not write %s — this run is not being saved" % SAVE_PATH)


## True only when a save exists AND this build can resume it (see saved_run_status()).
func has_saved_run() -> bool:
	return bool(saved_run_status()["resumable"])


## Raw file check, no judgement on whether the save is usable.
func saved_run_file_exists() -> bool:
	return SaveStore.exists(SAVE_PATH)


const DISCARD_MESSAGE := "Your unfinished run was from an older version and can't be continued."

## Set by discard_unresumable_run(); the first screen that shows it calls take_discard_notice().
var discard_notice := ""


## {"exists": bool, "resumable": bool, "reason": ""|"version"|"rules"|"corrupt"}. Pure: touches nothing.
## "version" = file schema differs; "rules" = saved under another ActionLog.RULES_VERSION (or none recorded).
func saved_run_status() -> Dictionary:
	if not SaveStore.exists(SAVE_PATH):
		return {"exists": false, "resumable": false, "reason": ""}
	var parsed = JSON.parse_string(SaveStore.read_text(SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY or typeof((parsed as Dictionary).get("run", null)) != TYPE_DICTIONARY:
		return {"exists": true, "resumable": false, "reason": "corrupt"}
	var payload: Dictionary = parsed
	if int(payload.get("version", -1)) != SAVE_VERSION:
		return {"exists": true, "resumable": false, "reason": "version"}
	if str(payload.get("rules_version", "")) != ActionLog.RULES_VERSION:
		return {"exists": true, "resumable": false, "reason": "rules"}
	return {"exists": true, "resumable": true, "reason": ""}


## If a save file exists that cannot be resumed: settle any open mission escrow as a loss (so the
## stake is not stuck), erase the file and set discard_notice. Returns true when something was discarded.
## Screens call this before they decide whether to offer CONTINUE.
func discard_unresumable_run() -> bool:
	var st := saved_run_status()
	if not bool(st["exists"]) or bool(st["resumable"]):
		return false
	MetaState.settle_mission_stake(false, true)
	SaveStore.erase(SAVE_PATH)
	discard_notice = DISCARD_MESSAGE
	return true


## Returns the pending "run discarded" line once, then clears it.
func take_discard_notice() -> String:
	var m := discard_notice
	discard_notice = ""
	return m


## Restores a saved run into this autoload and returns true on success. Returns false — having
## changed nothing — for a missing, unreadable, malformed or wrong-version file, so a caller
## can fall back to the main menu instead of dropping the player into a half-built run.
func load_run() -> bool:
	var text := SaveStore.read_text(SAVE_PATH)
	if text.is_empty():
		return false
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("RunState: save file is not a JSON object — ignoring it")
		return false
	var payload: Dictionary = parsed
	if int(payload.get("version", -1)) != SAVE_VERSION:
		push_warning("RunState: save file is version %s, this build reads %d — ignoring it"
			% [payload.get("version", "?"), SAVE_VERSION])
		return false
	if str(payload.get("rules_version", "")) != ActionLog.RULES_VERSION:
		push_warning("RunState: save was made under rules '%s', this build is '%s' — ignoring it"
			% [payload.get("rules_version", "none"), ActionLog.RULES_VERSION])
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
	if not saved_run_file_exists():
		return
	# SaveStore, so ABANDON RUN deletes BOTH copies on a web build. Deleting only the file
	# there would leave the localStorage copy behind, and the next launch would offer to
	# continue a run the player had just abandoned.
	SaveStore.erase(SAVE_PATH)
