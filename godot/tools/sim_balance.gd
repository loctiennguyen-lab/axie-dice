extends Node
## Headless balance sim: plays whole Short runs with scripted bots and prints win-rates.
## Policies: attack_spam (dmg first, rest after), attack_only (dmg only), greedy (1 step, heuristic values),
## expert (exact state eval via use_die + undo_last, free reroll, Hold on boss strike turn), random_legal.
## Cores: random | greedy_axis | combo (owned axis, then highest rarity); mix cycles the three.
## Args (after `--`): --runs=10 --seed=1000 --asc=0 --policies=attack_spam,greedy,random_legal
##   --teams=all|<name,name> --cores=random|greedy_axis|mix --out=<dir> --tag=<name>
## Deterministic by seed (the bot's own choices use a private Rng, never the game's).
## Never touches the network; the real save is guarded (SaveGuard) and the worktree has its own user dir.
## Engine gaps handled here (no engine edits): bot rng, preview via engine.preview_damage, private
## engine._face_value for non-dmg values.

const MAX_TURNS := 60
const STUCK_TURNS := 20
const MAX_NODES := 60
const SALT := 0x5EED5

const TEAMS := {
	"beast_bird": ["beast1", "bird1", "beast1", "bird1", "beast1"],
	"aqua_plant": ["aqua1", "plant1", "aqua1", "plant1", "aqua1"],
	"reptile_bug": ["reptile1", "bug1", "reptile1", "bug1", "reptile1"],
	"mixed_std": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
	"mixed_dmg": ["beast1", "bird1", "aqua1", "bug1", "reptile1"],
	"tank_heavy": ["plant1", "plant1", "reptile1", "aqua1", "bird1"],
	"thorn_shield": ["reptile1", "plant1", "reptile1", "plant1", "reptile1"],
}

var _rng: Rng
var _policy := "greedy"
var _core_policy := "random"
var _fights: Array = []   # per run: {kind, turns, won, stuck}
var _offered := {}        # per run: Core/Rule ids that appeared in an offer
var _picked: Array = []   # per run: ids taken
var _trig := {}           # per run: ids that "fired" (see _note_triggers)
var _shield_used := 0
var _pact_mode := "take"   # take | skip   (--pact)
var _shop_mode := "all"    # all | none     (--shop)
var _nohold := false       # ablation (--hold=1)
var _noreroll := false     # ablation (--noreroll=1)
var _beam := 3             # expert in-turn beam width (--beam)
var _core_fired_seen := {} # ids reported by EventBus.core_fired, when the branch has that signal
## Real combos (design/proposals/core-pick-excitement-brainstorm.md 2.B1; members that exist as ids on this branch).
const COMBOS := [
	["c_cascade", "c_sixth_die", "c_mirror_face"], ["c_living_wall", "c_gatekeeper", "c_backline_glow"],
	["c_sonic_shield", "c_backline_glow", "c_blood_sign"], ["c_nest", "c_golden_egg", "c_spore_burst"],
	["c_overflow", "c_dewdrop", "c_backline_glow"], ["c_hollow_core", "c_kindle", "c_dewdrop"],
	["c_kindle", "c_prime_chain", "c_three_dice"], ["c_finisher", "c_chimera_hunt"],
	["c_living_wall", "c_growing_shell", "c_finisher"], ["c_descend", "c_thorn_pact", "c_bastion"],
	["c_thorn_pact", "c_elder_trunk", "c_backline_glow"], ["c_prism", "c_sixth_die", "c_collector"],
	["c_blood_sign", "c_plague_spread", "c_fissure"], ["c_loop", "c_mana_pool", "c_overflow"]]
const BAD_RULES := ["rule_none", "rule_crow", "rule_hard_shell"]   # measured: never fire / only hurt

## Events a handler can see in every fight where the Core is owned.
const ALWAYS_EVENTS := ["on_combat_start", "on_turn_start", "on_turn_end", "on_roll_settled", "on_roll_end",
	"on_combat_end", "mod_face", "face_final", "roll_face", "roll_edit", "extra_dice", "class_field", "face_crit",
	"incoming_dmg", "boss_period", "boss_strike_mult", "enemy_row_pref", "front_row_size", "stash_cap", "stash_repeat",
	"reroll_mana_cost", "reroll_allowed", "before_reroll", "cantrip_extra", "roll_share_class", "descend_pick", "active_cost"]


func _on_core_fired(a = null, b = null, c = null, d = null) -> void:
	for x in [a, b, c, d]:
		if x is String and (String(x).begins_with("c_") or String(x).begins_with("rule_")):
			_core_fired_seen[String(x)] = true
			return


func _ready() -> void:
	if EventBus.has_signal("core_fired"):   # exact trigger counter (FX lane); else the heuristic in _note_triggers
		EventBus.connect("core_fired", _on_core_fired)
	var args := _parse_args()
	var guard := SaveGuard.new()
	guard.capture()
	_pact_mode = String(args.get("pact", "take"))
	_shop_mode = String(args.get("shop", "all"))
	_beam = int(args.get("beam", 3))
	_nohold = int(args.get("hold", 0)) != 1   # Hold is OFF by default: ablation showed it costs ~4 points
	_noreroll = int(args.get("noreroll", 0)) == 1
	var recs: Array
	if args.has("from"):   # --from=a.csv,b.csv : rebuild/merge a report from raw CSVs, no simulation
		recs = SimReport.read_csvs(String(args["from"]).split(","))
		args["policies"] = "merged"
		args["asc"] = "-"
		args["runs"] = recs.size()
	else:
		recs = run_batch(args)
	guard.restore()
	var out_dir := String(args.get("out", ProjectSettings.globalize_path("res://").path_join("../production/qa/sim")))
	var tag := String(args.get("tag", "%dx%s_A%s" % [int(args["runs"]), str(args["policies"]).replace(",", "+"), args["asc"]]))
	SimReport.write(recs, out_dir, tag, float(args.get("_secs", 0.0)), catalog())
	get_tree().quit(0)


func _parse_args() -> Dictionary:
	var a := {"runs": 10, "seed": 1000, "asc": "0", "policies": "attack_spam,greedy", "teams": "all", "cores": "mix", "tag": ""}
	for s in OS.get_cmdline_user_args():
		if s.begins_with("--") and s.contains("="):
			var kv := s.substr(2).split("=", true, 1)
			a[kv[0]] = kv[1]
	a["runs"] = int(a["runs"])
	a["seed"] = int(a["seed"])
	if a["tag"] == "":
		a.erase("tag")
	return a


## Returns an Array of run records (see _play_run). Public so the smoke test can call it.
func run_batch(args: Dictionary) -> Array:
	var recs: Array = []
	var team_names: Array = TEAMS.keys() if String(args.get("teams", "all")) == "all" else String(args["teams"]).split(",")
	var t0 := Time.get_ticks_msec()
	for asc_s in String(args.get("asc", "0")).split(","):
		for pol in String(args.get("policies", "greedy")).split(","):
			for i in int(args["runs"]):
				var team_name: String = team_names[i % team_names.size()]
				var cp: String = String(args.get("cores", "mix"))
				if cp == "mix":
					cp = ["random", "greedy_axis", "combo"][(i / team_names.size()) % 3]
				recs.append(_play_run(int(args["seed"]) + i, team_name, int(asc_s), pol, cp))
	args["_secs"] = (Time.get_ticks_msec() - t0) / 1000.0
	return recs


func _play_run(seed_value: int, team_name: String, asc: int, policy: String, core_policy: String) -> Dictionary:
	_policy = policy
	_core_policy = core_policy
	_abl = {}
	if policy.begins_with("expert_"):
		for k in policy.trim_prefix("expert_").split("+"):
			_abl[k] = true
		if _abl.has("legacy"):   # v3 expert: none of the four v4 mechanisms
			for k in ["no_bo_hunt", "no_lieu", "no_wild", "no_overcast"]:
				_abl[k] = true
	_rng = Rng.new(seed_value ^ SALT)
	_brng.seed = seed_value * 7919 + 13
	_fights = []
	_offered = {}
	_core_fired_seen = {}
	_picked = []
	_trig = {}
	var team: Array[String] = []
	var keys: Array = TEAMS[team_name] if TEAMS.has(team_name) else Array(team_name.split("+"))   # "a+b+c+d+e" = explicit heroes
	for k in keys:
		team.append(String(k))
	RunState.start_run_with_epoch(LocalEpochSource.new(PackedByteArray(), seed_value), {
		"team_keys": team, "mode": "short", "ascension": asc, "ranked": false, "rules_on": true,
		"newcomer": false, "bonuses": {}}, seed_value)
	_drain_core_offers()
	var graph := RunMapGraph.from_data(RunState.map_graph)
	var node := graph.find_node(graph.start_node_id)
	var walked := 0
	var death_kind := ""
	var death_row := 0
	while node != null and walked < MAX_NODES:
		walked += 1
		RunState.enter_node(node.id, node.node_type)
		match node.node_type:
			"battle", "elite", "boss":
				var eng := CombatEngine.new()
				eng.setup_new(RunState.pending_combat)
				eng.action_log = null   # trial moves use undo_last(), which would spam the shared log; sim never verifies
				var aff := ""
				if node.node_type == "elite" and not eng.enemies.is_empty():
					aff = String((eng.enemies[0] as Unit).custom_state.get("affix", ""))
				var owned_snap: Array = RunState.owned_relic_ids.duplicate()
				_shield_used = 0
				var turns := _play_combat(eng)
				_note_triggers(eng, owned_snap)
				_fights.append({"kind": node.node_type, "turns": turns, "won": eng.won, "stuck": turns > STUCK_TURNS or not (eng.won or eng.lost), "affix": aff})
				RunState.apply_combat_result(eng.get_result())
				if not eng.won:
					death_kind = node.node_type
					death_row = node.row
				if RunState.phase == RunState.RunPhase.PACT:
					if _pact_mode == "skip" and RunState.pact_can_skip():
						RunState.skip_pact()
					elif not RunState.take_pact(0):
						RunState.skip_pact()
				if not RunState.pending_rewards.is_empty():
					RunState.apply_chosen_reward(_pick_plain_reward())
			"event":
				var n_opt := RunState.event_options().size()
				if n_opt > 0:
					RunState.choose_event_option(_rng.next_int(n_opt))
			"shop":
				if _shop_mode != "none":
					for j in RunState.shop_items.size():
						RunState.try_buy_shop_item(j)
			"treasure":
				RunState.generate_treasure_rewards(node.id)
				if not RunState.pending_rewards.is_empty():
					RunState.apply_chosen_reward(_pick_plain_reward())
		if RunState.phase == RunState.RunPhase.WON or RunState.phase == RunState.RunPhase.LOST:
			break
		RunState.after_node()
		_drain_core_offers()
		if node.next_ids.is_empty():
			break
		node = graph.find_node(String(node.next_ids[_rng.next_int(node.next_ids.size())]))
	var won := RunState.phase == RunState.RunPhase.WON
	var cores: Array = []
	for id in RunState.owned_relic_ids:
		var d = RelicRegistry.get_def(String(id))
		if d != null and String(d.id).begins_with("c_"):
			cores.append(String(id) + "@" + String(d.core_axis))
	return {"seed": seed_value, "policy": policy, "core_policy": core_policy, "team": team_name, "asc": asc,
		"won": won, "death_kind": death_kind, "death_row": death_row, "rule": RunState.run_rule,
		"cores": cores, "fights": _fights.duplicate(true), "offered": _offered.keys(), "picked": _picked.duplicate(),
		"trig": _trig.keys()}


# ---------------------------------------------------------------- rewards / cores

func _drain_core_offers() -> void:
	var guard := 0
	while (RunState._core_offer_active or RunState._rule_offer_active) and not RunState.pending_rewards.is_empty() and guard < 16:
		guard += 1
		var cards: Array = RunState.pending_rewards
		for c in cards:
			_offered[String((c as Dictionary).get("key", ""))] = true
		var card: Dictionary = cards[0]
		if bool(card.get("rule", false)):
			card = cards[_rng.next_int(cards.size())]
			if _core_policy == "combo":
				for c in cards:
					if not BAD_RULES.has(String((c as Dictionary).get("key", ""))):
						card = c
						break
		elif _core_policy == "combo":
			var best_sc := -1.0
			for c in cards:
				var sc := _combo_score(String((c as Dictionary).get("key", "")))
				if sc > best_sc:
					best_sc = sc
					card = c
		elif _core_policy == "greedy_axis":
			var owned := _owned_axes()
			for c in cards:
				if owned.get(String((c as Dictionary).get("axis", "")), 0) > 0 and String((c as Dictionary).get("axis", "")) in ["dice", "mana", "pos", "rule"]:
					card = c
					break
		else:
			card = cards[_rng.next_int(cards.size())]
		var sell := ""
		if not bool(card.get("rule", false)):
			var chk := RelicSlots.check_add(RunState.owned_relic_ids, RunState.relic_stickers, String(card["key"]), RunState.ascension, false)
			if bool(chk["ok"]) and bool(chk["needs_sell"]):
				sell = String((chk["sell_from"] as Array)[0])
		if not RunState.apply_chosen_reward(card, sell):
			break
		_picked.append(String(card.get("key", "")))
		RunState.after_node()


## "Fired" is a heuristic (the engine has no per-relic trace; relic_pulsed is not emitted by Core hooks):
## an owned Core/Rule counts as fired in a fight when (a) its state left a bucket (relic_combat / relic_run_out /
## relic_state / quest progress key naming the id or slug) or (b) one of its declared events certainly occurred:
## ALWAYS_EVENTS, or on_face_used/on_face_hit/on_hit/mod_dmg with dmg dealt, on_kill with kills, on_dmg_taken with
## damage taken, on_shield with a shield face used. Other events (thorns, status tick, stash, active...) count only via (a).
func _note_triggers(eng: CombatEngine, owned: Array) -> void:
	var st: Dictionary = eng.stat
	var seen := {}
	if int(st.get("dmg", 0)) > 0:
		for e in ["on_face_used", "on_face_hit", "on_hit", "mod_dmg"]:
			seen[e] = true
	if int(st.get("kills", 0)) > 0:
		seen["on_kill"] = true
	if int(st.get("taken", 0)) > 0:
		seen["on_dmg_taken"] = true
	if _shield_used > 0:
		seen["on_shield"] = true
		seen["on_face_used"] = true
	var keys: Array = []
	for bucket in [eng.relic_combat, eng.relic_run_out, RunState.relic_state]:
		keys.append_array((bucket as Dictionary).keys())
	for id in owned:
		var sid := String(id)
		if not (sid.begins_with("c_") or sid.begins_with("rule_")):
			continue
		var slug := sid.substr(sid.find("_") + 1)
		var hit := false
		for k in keys:
			if String(k) == sid or String(k).contains(slug):
				hit = true
				break
		if not hit:
			var d = RelicRegistry.get_def(sid)
			var hk: String = String(d.hook_key) if d != null and "hook_key" in d else sid
			var tbl: Dictionary = RelicHooks.TABLE.get(hk, {})
			for ev in tbl.keys():
				if ALWAYS_EVENTS.has(ev) or seen.has(ev):
					hit = true
					break
		if EventBus.has_signal("core_fired"):
			hit = _core_fired_seen.has(sid)
		if hit:
			_trig[sid] = true


func catalog() -> Array:
	var out: Array = []
	for d in RelicRegistry.all_defs_sorted():
		var id := String(d.id)
		if (id.begins_with("c_") or id.begins_with("rule_")) and not d.disabled and not d.hidden_from_pool \
				and not id.begins_with("c_test_") and not id.begins_with("rule_test_"):
			out.append({"id": id, "axis": String(d.core_axis), "rarity": int(d.rarity)})
	return out


func _combo_score(id: String) -> float:
	var d = RelicRegistry.get_def(id)
	var sc := float(d.rarity) * 0.5 if d != null else 0.0
	var best := 0.0
	for combo in COMBOS:
		if not (combo as Array).has(id):
			continue
		var have := 0
		for m in combo:
			if RunState.owned_relic_ids.has(m):
				have += 1
		best = maxf(best, 2.0 + (12.0 + 10.0 * have if have > 0 else 0.0))
	return sc + best


func _owned_axes() -> Dictionary:
	var out := {}
	for id in RunState.owned_relic_ids:
		var d = RelicRegistry.get_def(String(id))
		if d != null and String(d.id).begins_with("c_"):
			out[String(d.core_axis)] = int(out.get(String(d.core_axis), 0)) + 1
	return out


func _pick_plain_reward() -> Dictionary:
	var order := ["level", "ascend", "hp"]
	for t in order:
		for c in RunState.pending_rewards:
			if String((c as Dictionary).get("t", "")) == t:
				return c
	return RunState.pending_rewards[0]


# ---------------------------------------------------------------- combat bots

func _play_combat(eng: CombatEngine) -> int:
	var turns := 0
	_turn_seen = -1
	_plan = []
	while not (eng.won or eng.lost) and turns < MAX_TURNS:
		_play_turn(eng)
		turns += 1
	return turns


func _play_turn(eng: CombatEngine) -> void:
	var guard := 0
	if _policy == "random_legal":
		_random_extras(eng)
	while guard < 24 and not (eng.won or eng.lost):
		guard += 1
		var mv := _choose_move(eng)
		if mv.is_empty():
			break
		var mu: Unit = eng.by_uid(int(mv[0]))
		var mt := String(mu.current_face().get("type", "")) if mu != null else ""
		if not eng.use_die(int(mv[0]), int(mv[1])):
			break
		if mt == "shield":
			_shield_used += 1
	if not (eng.won or eng.lost):
		eng.end_turn()


func _ready_units(eng: CombatEngine) -> Array:
	var out: Array = []
	for u in eng.party:
		if u.hp > 0 and u.has_rolled() and not u.roll_used() and not u.held and u.roll_face_index() >= 0:
			if String(u.current_face().get("type", "")) != "blank":
				out.append(u)
	return out


func _choose_move(eng: CombatEngine) -> Array:
	var ready := _ready_units(eng)
	if ready.is_empty():
		return []
	var foes: Array = eng.alive_enemies()
	if foes.is_empty():
		return []
	if _policy.begins_with("expert"):   # expert, expert_no_bo_hunt, expert_no_lieu, expert_no_wild, expert_no_overcast, expert_legacy
		return _move_expert(eng, ready, foes)
	match _policy:
		"attack_spam":
			return _move_attack_spam(eng, ready, foes)
		"attack_only":   # pure spam: never spends a non-dmg face (stricter reading of attack_spam)
			for u in ready:
				if String(u.current_face().get("type", "")) == "dmg":
					return [u.uid, _lowest_hp(foes).uid]
			return []
		"random_legal":
			return _move_random(eng, ready, foes)
		_:
			return _move_greedy(eng, ready, foes)


func _lowest_hp(foes: Array) -> Unit:
	var best: Unit = foes[0]
	for e in foes:
		if (e as Unit).hp + (e as Unit).shield < best.hp + best.shield:
			best = e
	return best


func _move_attack_spam(eng: CombatEngine, ready: Array, foes: Array) -> Array:
	for u in ready:
		if String(u.current_face().get("type", "")) == "dmg":
			return [u.uid, _lowest_hp(foes).uid]
	return _move_random(eng, ready, foes)   # no dmg face left: anything legal (first ready), per spec "unless none left"


func _target_for(eng: CombatEngine, u: Unit, foes: Array, rnd: bool) -> int:
	var t := String(u.current_face().get("type", ""))
	if t in ["dmg", "poison", "debuff"]:
		return (foes[_rng.next_int(foes.size())] as Unit).uid if rnd else _lowest_hp(foes).uid
	if t in ["shield", "heal", "buff"]:
		var fr: Array = eng.alive_party()
		return (fr[_rng.next_int(fr.size())] as Unit).uid if rnd else u.uid
	return u.uid


## "Bua" bot, v4 actions: random reroll (random subset, random Lieu/An toan), sometimes Mat Tam / Overcast, only when the
## engine says it is legal (can_reroll / wild_block_reason / can_overcast).
func _random_extras(eng: CombatEngine) -> void:
	for _i in 2:
		if _rng.next_int(100) >= 45:
			break
		var ready := _ready_units(eng)
		if ready.is_empty():
			break
		var uids: Array = []
		for u in ready:
			if _rng.next_int(2) == 0:
				uids.append(u.uid)
		if uids.is_empty():
			uids.append((ready[_rng.next_int(ready.size())] as Unit).uid)
		var rm := _rng.next_int(2)
		if not eng.can_reroll(uids, false, rm):
			rm = 1 - rm
		if eng.can_reroll(uids, false, rm):
			eng.reroll_dice(uids, -1, false, rm)
	if _rng.next_int(100) < 30:
		var opts: Array = []
		for u in _ready_units(eng):
			for sl in 6:
				if eng.wild_block_reason(u.uid, sl) == "":
					opts.append([u.uid, sl])
		if not opts.is_empty():
			var o: Array = opts[_rng.next_int(opts.size())]
			eng.wild_face(int(o[0]), int(o[1]))
	if _rng.next_int(100) < 30:
		var oc: Array = []
		for u in _ready_units(eng):
			if eng.can_overcast(u.uid):
				oc.append(u.uid)
		if not oc.is_empty():
			eng.overcast(int(oc[_rng.next_int(oc.size())]))


func _move_random(eng: CombatEngine, ready: Array, foes: Array) -> Array:
	var u: Unit = ready[_rng.next_int(ready.size())]
	return [u.uid, _target_for(eng, u, foes, true)]


## Expected damage the enemies' public intents will put on friend `f` (shield not counted).
func _incoming(eng: CombatEngine, f: Unit) -> float:
	var s := 0.0
	var st := eng.affix_state()
	for e in eng.alive_enemies():
		var it: Dictionary = (e as Unit).intent
		if it.is_empty():
			continue
		var fi := int(it.get("face_index", -1))
		if fi < 0 or fi >= (e as Unit).die.size():
			continue
		var face: Dictionary = (e as Unit).die[fi]
		if String(face.get("type", "")) != "dmg":
			continue
		var v := float(eng._face_value(e, fi))
		var kws: String = str(face.get("keywords", []))
		if int(it.get("target_uid", -1)) == f.uid or kws.contains("aoe") or kws.contains("pierce"):
			s += v
	if bool(st.get("charge_next", false)) and int(st.get("charge_target", -1)) == f.uid:
		s += 2.5 * _avg_enemy_hit(eng)
	return s


func _avg_enemy_hit(eng: CombatEngine) -> float:
	var best := 0.0
	for e in eng.alive_enemies():
		for fi in (e as Unit).die.size():
			if String(((e as Unit).die[fi] as Dictionary).get("type", "")) == "dmg":
				best = maxf(best, float(eng._face_value(e, fi)))
	return best


func _move_greedy(eng: CombatEngine, ready: Array, foes: Array) -> Array:
	var best_s := -1.0
	var best: Array = []
	for u in ready:
		var fi: int = u.roll_face_index()
		var f: Dictionary = u.die[fi]
		var t := String(f.get("type", ""))
		var kws: String = str(f.get("keywords", []))
		var v := float(eng._face_value(u, fi))
		if t == "dmg":
			var aoe := kws.contains("aoe")
			var tg: Array = foes if aoe else foes   # aoe: any target works, score is the sum
			for e in tg:
				var s := 0.0
				var pool: Array = foes if aoe else [e]
				for p in pool:
					var after := float(eng.preview_damage(u, p, fi)["after"]) if not aoe else v
					var eff := minf(after, float(p.hp + p.shield))
					s += eff
					if after >= p.hp + p.shield:
						s += 4.0   # a kill removes its future attacks
				if int((e as Unit).plating if "plating" in e else 0) > 0 and not aoe:
					s *= 0.9
				if s > best_s:
					best_s = s
					best = [u.uid, (e as Unit).uid]
		elif t == "shield" or t == "heal":
			var targets: Array = [u] if kws.contains("aoe") else eng.alive_party()
			for fr in targets:
				var s2 := 0.0
				if t == "shield":
					var inc := _incoming(eng, fr)
					s2 = minf(v, maxf(0.0, inc - fr.shield)) * 1.1
				else:
					s2 = minf(v, float(fr.max_hp - fr.hp)) * 0.9
				if kws.contains("aoe"):
					s2 *= eng.alive_party().size() * 0.6
				if s2 > best_s:
					best_s = s2
					best = [u.uid, (fr as Unit).uid if not kws.contains("aoe") else u.uid]
		elif t == "poison" or t == "debuff":
			for e in foes:
				var s3 := 0.0
				if t == "poison":
					s3 = minf(v * 2.0, float((e as Unit).hp)) * 0.8
				else:
					s3 = 1.0
					if (e as Unit).plating > 0 or String((e as Unit).custom_state.get("m_trait", "")) in ["plating", "mend"] or str((e as Unit).intent.get("charge", "")) != "":
						s3 = 4.0
				if s3 > best_s:
					best_s = s3
					best = [u.uid, (e as Unit).uid]
		else:
			var s4 := 1.5 if t == "mana" else 0.8
			if s4 > best_s:
				best_s = s4
				best = [u.uid, u.uid]
	return best


# ---------------------------------------------------------------- expert

var _turn_seen := -1
var _brng := RandomNumberGenerator.new()   # the bot's OWN stream for look-ahead samples (never the game rng)

## Whole-state value (higher = better for the party): foe HP/shield/threat left, expected unblocked damage from the
## public intents on each Axie, party HP, mana, poison on foes.
func _eval(eng: CombatEngine) -> float:
	var v := 0.0
	var foes: Array = eng.alive_enemies()
	for e in foes:
		var eu: Unit = e
		var thr := 0.0
		if int(eu.status.get("stun", 0)) == 0 and not eu.intent.is_empty():
			var fi := int(eu.intent.get("face_index", -1))
			if fi >= 0 and fi < eu.die.size() and String((eu.die[fi] as Dictionary).get("type", "")) == "dmg":
				thr = float(eng._face_value(eu, fi))
		v -= float(eu.hp) + 0.8 * float(eu.shield) + 4.0 + thr * 0.8
		v -= 0.7 * minf(float(eu.status.get("poison", 0)) * -1.0, 0.0)   # (poison counted below as bonus)
		v += 0.9 * minf(float(eu.status.get("poison", 0)), float(eu.hp))
	v += 0.5 * float(eng.mana)
	for f in eng.alive_party():
		var fu: Unit = f
		var inc := _incoming(eng, fu)
		var loss := maxf(0.0, inc - float(fu.shield))
		if loss >= float(fu.hp):
			v -= 12.0 + float(fu.hp)
		else:
			v -= 1.6 * loss
		v += 0.8 * float(fu.hp)
	return v


func _candidates(eng: CombatEngine, u: Unit, foes: Array) -> Array:
	var t := String(u.current_face().get("type", ""))
	var out: Array = []
	if t in ["dmg", "poison", "debuff"]:
		for e in foes:
			out.append((e as Unit).uid)
	elif t in ["shield", "heal", "buff"]:
		for f in eng.alive_party():
			out.append((f as Unit).uid)
	else:
		out.append(u.uid)
	return out


var _plan: Array = []
var _abl := {}          # expert ablations: no_bo_hunt, no_lieu, no_wild, no_overcast (policy name expert_<k>)
var _last_score := 0.0  # score of the best sequence returned by the last _plan_turn

func _move_expert(eng: CombatEngine, ready: Array, foes: Array) -> Array:
	if int(eng.turn) != _turn_seen:
		_turn_seen = int(eng.turn)
		_expert_turn_start(eng, ready, foes)
		ready = _ready_units(eng)
		foes = eng.alive_enemies()
		_plan = _plan_turn(eng, ready, foes) if not (ready.is_empty() or foes.is_empty()) else []
	if _plan.is_empty():
		return []
	return _plan.pop_front()


## Beam search over ordered (die, target) sequences inside the turn, scored by _eval after each step (exact state, via
## use_die + undo_last). A prefix may stop at any depth (a die can stay unused). Returns the best sequence found.
func _plan_turn(eng: CombatEngine, ready: Array, foes: Array) -> Array:
	var base := _eval(eng)
	var beam: Array = [{"seq": [], "score": base}]
	var best: Dictionary = beam[0]
	for depth in ready.size():
		var nxt: Array = []
		var seen := {}
		for b in beam:
			var seq: Array = b["seq"]
			var applied := 0
			for m in seq:
				if eng.use_die(int(m[0]), int(m[1])):
					applied += 1
			if applied == seq.size():
				var used := {}
				for m in seq:
					used[int(m[0])] = true
				for u in _ready_units(eng):
					if used.has(u.uid):
						continue
					for tid in _candidates(eng, u, eng.alive_enemies()):
						if eng.use_die(u.uid, tid):
							var sc := _eval(eng)
							eng.undo_last()
							var ns: Array = seq.duplicate()
							ns.append([u.uid, tid])
							var keys: Array = []
							for m2 in ns:
								keys.append("%d:%d" % [m2[0], m2[1]])
							keys.sort()
							var key := ",".join(keys)
							if not seen.has(key):
								seen[key] = true
								nxt.append({"seq": ns, "score": sc})
			for k in applied:
				eng.undo_last()
		if nxt.is_empty():
			break
		nxt.sort_custom(func(x, y): return x["score"] > y["score"])
		beam = nxt.slice(0, _beam)
		if float(beam[0]["score"]) > float(best["score"]):
			best = beam[0]
	_last_score = float(best["score"])
	return best["seq"]


## Turn start: Hold the strongest dmg die on a boss STRIKE turn (it hits the next, hollow, turn for +30%);
## then spend the free reroll on dice whose best move is worth little.
func _expert_turn_start(eng: CombatEngine, ready: Array, foes: Array) -> void:
	for e in foes:
		var b: Unit = e
		if _nohold:
			break
		if b.is_boss and eng.boss_rhythm_phase(b, 0) == "strike":
			var pick: Unit = null
			var pv := 0
			for u in ready:
				if eng.can_stash(u.uid) and String(u.current_face().get("type", "")) == "dmg":
					var fv: int = eng._face_value(u, u.roll_face_index())
					if fv > pv:
						pv = fv
						pick = u
			if pick != null and pv >= 4:
				eng.stash(pick.uid)
			break
	if _abl.has("old"):   # first v4 heuristic (kept for before/after comparison)
		if not _noreroll:
			_expert_rerolls(eng)
		_expert_wild(eng)
		_expert_overcast(eng)
	else:
		_expert2_actions(eng)


## Best-of-plan value of the turn as it stands (beam 1 for speed): lets the bot price Mat Tam / Overcast with the engine's own numbers.
func _turn_value(eng: CombatEngine) -> float:
	var ready := _ready_units(eng)
	var foes: Array = eng.alive_enemies()
	if ready.is_empty() or foes.is_empty():
		return _eval(eng)
	var ob := _beam
	_beam = 1
	_plan_turn(eng, ready, foes)
	_beam = ob
	return _last_score


func _m100_of_size(eng: CombatEngine, n: int) -> float:
	if n < 3:
		return 1.0
	return float(clampi(100 + eng.bo_add100(n), 100, eng.bo_cap100())) / 100.0


## Expected value gain of growing a BỘ of `n` dice (avg face value `a`) with `k` rerolled outside dice, each landing on the part with prob `p`.
func _hunt_ev(eng: CombatEngine, n: int, a: float, k: int, p: float) -> float:
	var ev := 0.0
	var v0 := float(n) * a * _m100_of_size(eng, n)
	for h in range(1, k + 1):
		var c := 1.0
		for j in h:
			c = c * float(k - j) / float(j + 1)
		var ph: float = c * pow(p, h) * pow(1.0 - p, k - h)
		if n + h > 5:
			continue
		ev += ph * (float(n + h) * a * _m100_of_size(eng, n + h) - v0)
	return ev



# ---- diagnostics (AXIE_SIM_TRACE=<file>): one line per Lieu / Safe / Mat Tam / Overcast decision of the expert
var _trace_path := OS.get_environment("AXIE_SIM_TRACE")
var _trace_n := 0

func _hand(eng: CombatEngine) -> String:
	var parts: Array = []
	for u in _ready_units(eng):
		var f: Dictionary = u.current_face()
		parts.append("%s%d%s%s" % [String(f.get("type", "?")).substr(0, 2), int(eng._face_value(u, u.roll_face_index())),
			"p" + str(u.roll_face_index()), "X" if u.cracked else ""])
	var bo: Array = []
	for g in eng.bo:
		bo.append("%dx%d" % [int(g["part"]), int(g["size"])])
	return "[" + " ".join(parts) + "] bo=" + ",".join(bo) + " mana=" + str(eng.mana)


func _trace(kind: String, eng: CombatEngine, before: String, tv0: float, extra: String) -> void:
	if _trace_path == "":
		return
	var f := FileAccess.open(_trace_path, FileAccess.READ_WRITE if FileAccess.file_exists(_trace_path) else FileAccess.WRITE)
	f.seek_end()
	f.store_line("%s\tT%d\t%s\t-> %s\tdTV=%.1f\t%s" % [kind, int(eng.turn), before, _hand(eng), _turn_value(eng) - tv0, extra])
	f.close()

## Up to 3 reroll rounds. v4: (a) hunt a bigger BỘ by rerolling the dice OUTSIDE the best part group, choosing Lieu vs An toan by
## expected value (Nứt % and mana); (b) otherwise reroll "weak" dice (never BỘ members), cheaply with Lieu.
func _expert_rerolls(eng: CombatEngine) -> void:
	var crack_p := float(CombatEngine.tune_knob("crack", "pct", 30.0)) / 100.0
	for round in 3:
		var did := false
		if not _abl.has("no_bo_hunt"):
			did = _try_hunt(eng, crack_p)
		if not did:
			did = _try_weak_reroll(eng)
		if not did:
			break


func _try_hunt(eng: CombatEngine, crack_p: float) -> bool:
	var groups := {}   # part -> Array[Unit]
	for d in eng._bo_dice():
		var u: Unit = d
		if u.wild_slot >= 0 or u.cracked:
			continue
		var pt: int = u.roll_face_index()
		if not groups.has(pt):
			groups[pt] = []
		(groups[pt] as Array).append(u)
	var best_pt := -1
	var best_n := 0
	var best_sum := 0.0
	for pt in groups:
		var g: Array = groups[pt]
		var sm := 0.0
		for u in g:
			sm += maxf(0.0, eng._face_base(u, pt))
		if g.size() > best_n or (g.size() == best_n and sm > best_sum):
			best_pt = pt
			best_n = g.size()
			best_sum = sm
	if best_n < 2 or best_n >= 5:
		return false
	var in_group := {}
	for u in groups[best_pt]:
		in_group[(u as Unit).uid] = true
	var cands: Array = []
	for u in eng.alive_party():
		var uu: Unit = u
		if uu.has_rolled() and not uu.roll_used() and not uu.held and not in_group.has(uu.uid):
			cands.append(uu.uid)
	var ok_units: Array = eng._rerollable(cands)   # Units, not uids
	cands = []
	for u in ok_units:
		cands.append((u as Unit).uid)
	if cands.is_empty():
		return false
	var a := best_sum / float(best_n)
	var k := cands.size()
	var free := eng.rerolls > 0
	var ev_safe := _hunt_ev(eng, best_n, a, k, 1.0 / 6.0) - (0.0 if free else float(eng.reroll_mana_cost(false, 1)) * 1.0)
	var ev_lieu := _hunt_ev(eng, best_n, a, k, (1.0 / 6.0) * (1.0 - crack_p)) - crack_p * float(k) * a * 0.5
	var rm := 1
	var ev := ev_safe
	if not free and not _abl.has("no_lieu") and eng.depth_stage >= 2 and ev_lieu > ev_safe:
		rm = 0
		ev = ev_lieu
	if ev < 1.0 or not eng.can_reroll(cands, false, rm):
		return false
	if _trace_path != "":
		var h0 := _hand(eng)
		var t0 := _turn_value(eng)
		var okr := eng.reroll_dice(cands, -1, false, rm)
		_trace("HUNT_" + ("LIEU" if rm == 0 else "SAFE"), eng, h0, t0, "free=%s k=%d n=%d evL=%.1f evS=%.1f" % [str(free), k, best_n, ev_lieu, ev_safe])
		return okr
	return eng.reroll_dice(cands, -1, false, rm)


func _try_weak_reroll(eng: CombatEngine) -> bool:
	var protect := {}
	if not _abl.has("no_bo_hunt"):
		for g in eng.bo:
			for id in g["uids"]:
				protect[int(id)] = true
	var base := _eval(eng)
	var weak: Array = []
	for u in _ready_units(eng):
		if protect.has(u.uid):
			continue
		var bd := 0.0
		for tid in _candidates(eng, u, eng.alive_enemies()):
			if eng.use_die(u.uid, tid):
				bd = maxf(bd, _eval(eng) - base)
				eng.undo_last()
		if bd < 2.5 and not u.frozen and not u.held:
			weak.append(u.uid)
	if weak.is_empty():
		return false
	# a weak die is cheap to crack: pay with Lieu (0 mana) when a chosen reroll is needed, otherwise An toan
	var rm := 1
	if eng.rerolls <= 0 and not _abl.has("no_lieu") and eng.depth_stage >= 2:
		rm = 0
	if not eng.can_reroll(weak, false, rm):
		if rm == 0 and eng.can_reroll(weak, false, 1):
			rm = 1
		else:
			return false
	if _trace_path != "":
		var h1 := _hand(eng)
		var t1 := _turn_value(eng)
		var okw := eng.reroll_dice(weak, -1, false, rm)
		_trace("WEAK_" + ("LIEU" if rm == 0 else "SAFE"), eng, h1, t1, "free=%s n=%d" % [str(eng.rerolls > 0), weak.size()])
		return okw
	return eng.reroll_dice(weak, -1, false, rm)


## Mat Tam: attach when it completes a BỘ (ba+) and the turn value rises by more than the mana it costs.
func _expert_wild(eng: CombatEngine) -> void:
	if _abl.has("no_wild"):
		return
	var base := _turn_value(eng)
	var best_g := 1.0
	var best: Array = []
	for u in _ready_units(eng):
		for sl in 6:
			if eng.wild_block_reason(u.uid, sl) != "":
				continue
			var pv: Dictionary = eng.preview_wild(u.uid, sl)
			if not bool(pv["ok"]) or float(pv["mult"]) <= 1.0:
				continue
			if eng.wild_face(u.uid, sl):
				var g := _turn_value(eng) - base
				eng.undo_last()
				if g > best_g:
					best_g = g
					best = [u.uid, sl]
	if not best.is_empty():
		var h2 := _hand(eng)
		eng.wild_face(int(best[0]), int(best[1]))
		_trace("WILD", eng, h2, base, "gainSeen=%.1f" % best_g)


## Overcast: the die whose boost raises the turn value the most (BỘ dice come out on top because M multiplies), if it beats its mana.
func _expert_overcast(eng: CombatEngine) -> void:
	if _abl.has("no_overcast"):
		return
	var base := _turn_value(eng)
	var best_g := 1.0
	var best := -1
	for u in _ready_units(eng):
		if not eng.can_overcast(u.uid):
			continue
		var pr: Array = eng.overcast_preview(u)
		if float(pr[1]) <= float(pr[0]):
			continue
		if eng.overcast(u.uid):
			var g := _turn_value(eng) - base
			eng.undo_last()
			if g > best_g:
				best_g = g
				best = u.uid
	if best >= 0:
		var h3 := _hand(eng)
		eng.overcast(best)
		_trace("OVERCAST", eng, h3, base, "gainSeen=%.1f" % best_g)


# ================================================================ expert v2: decisions by sampled expected value
# One greedy loop per turn over {no action, reroll subset S in Safe / Lieu, Mat Tam (die, slot), Overcast die}. Each option is
# priced as  E[value after] - value now - mana spent * lambda(mana).  "value" is a cheap model of the turn (face values with the
# BO bag M, Nứt halving, per-type weights); rerolls are sampled (N draws from the bot's own rng, SAME draws for every option =
# common random numbers). The model uses the engine's own _face_base / bo_add100 / bo_cap100 / overcast_preview / preview_wild.

const E2_SAMPLES := 16
const E2_MIN_GAIN := 0.8
const E2_TYPES_M := ["dmg", "shield", "heal", "poison"]
var _e2_tv := {}   # per-decision cache: foe hp, incoming


func _e2_lambda(m: int) -> float:
	return 0.15 if m >= 10 else (0.35 if m >= 6 else 0.7)


func _e2_mana_cost_val(mana: int, c: int) -> float:
	var t := 0.0
	for j in c:
		t += _e2_lambda(mana - j)
	return t


## Entries for every die that matters this turn: ready ones (value now) and BO-eligible ones (group size).
func _e2_ctx(eng: CombatEngine) -> Dictionary:
	var elig := {}
	for d in eng._bo_dice():
		elig[(d as Unit).uid] = true
	var ready := {}
	for u in _ready_units(eng):
		ready[(u as Unit).uid] = true
	var ents: Array = []
	var seen := {}
	var order: Array = []
	for u in eng.party:
		if ready.has(u.uid) or elig.has(u.uid):
			order.append(u)
	for uu in order:
		var u: Unit = uu
		if seen.has(u.uid):
			continue
		seen[u.uid] = true
		var was := u.cracked
		u.cracked = false
		var vb: Array = []
		var ty: Array = []
		var rar: Array = []
		for fi in 6:
			var fd: Dictionary = u.die[fi]
			ty.append(String(fd.get("type", "")))
			rar.append(int(fd.get("rarity", 0)))
			vb.append(maxf(0.0, eng._face_base(u, fi)))
		u.cracked = was
		ents.append({"u": u, "uid": u.uid, "ready": ready.has(u.uid), "elig": elig.has(u.uid), "fi": u.roll_face_index(),
			"cr": was, "wild": u.wild_slot, "vb": vb, "ty": ty, "rar": rar,
			"rr": ready.has(u.uid) and u.wild_slot < 0 and not u.overcast and not u.frozen and not u.held})
	var foe_hp := 0.0
	for e in eng.alive_enemies():
		foe_hp += float((e as Unit).hp) + 0.8 * float((e as Unit).shield)
	var inc := 0.0
	var miss := 0.0
	for f in eng.alive_party():
		inc += _incoming(eng, f as Unit)
		miss += float((f as Unit).max_hp - (f as Unit).hp)
	var hi_r := int(CombatEngine.tune_knob("part", "hi_r", 2.0))
	var hi_add := roundi(CombatEngine.tune_knob("part", "hi_add", 0.25) * 100.0) if eng.depth_stage >= 3 else 0
	return {"e": ents, "foe_hp": maxf(foe_hp, 1.0), "inc": inc, "miss": miss, "hi_r": hi_r, "hi_add": hi_add,
		"cap": eng.bo_cap100(), "add3": eng.bo_add100(3), "add4": eng.bo_add100(4), "add5": eng.bo_add100(5),
		"mana": eng.mana}


## Model value of a hypothetical state: faces[i] (0..5), cracked[i], wild[i] (-1 none). bo_aware=false hides the sets (M = 1).
func _e2_value(ctx: Dictionary, faces: Array, cracked: Array, wild: Array, bo_aware: bool = true) -> float:
	var ents: Array = ctx["e"]
	var cnt := {}
	var hi := {}
	if bo_aware:
		for i in ents.size():
			var en: Dictionary = ents[i]
			if not en["elig"] or cracked[i]:
				continue
			var fi: int = faces[i]
			if String(en["ty"][fi]) == "blank":
				continue
			var part: int = wild[i] if wild[i] >= 0 else fi
			cnt[part] = int(cnt.get(part, 0)) + 1
			if int(en["rar"][fi]) >= int(ctx["hi_r"]):
				hi[part] = true
	var dmg := 0.0
	var sh := 0.0
	var he := 0.0
	var other := 0.0
	for i in ents.size():
		var en: Dictionary = ents[i]
		if not en["ready"]:
			continue
		var fi: int = faces[i]
		var t: String = en["ty"][fi]
		if t == "blank":
			continue
		var v: float = en["vb"][fi]
		if cracked[i] and v >= 1.0 and (t in E2_TYPES_M or t == "mana"):
			v = ceil(v / 2.0)
		if t in E2_TYPES_M:
			var part: int = wild[i] if wild[i] >= 0 else fi
			var n: int = int(cnt.get(part, 0))
			if n >= 3 and not cracked[i]:
				var m: int = 100 + (ctx["add3"] if n == 3 else (ctx["add4"] if n == 4 else ctx["add5"])) + (int(ctx["hi_add"]) if hi.has(part) else 0)
				v = float(int(v) * clampi(m, 100, int(ctx["cap"])) + 99) / 100.0
				v = floor(v)
		match t:
			"dmg":
				dmg += v
			"shield":
				sh += v
			"heal":
				he += v
			"poison":
				other += 1.3 * v
			"mana":
				other += _e2_lambda(int(ctx["mana"])) * v
			_:
				other += 2.0
	var fh: float = ctx["foe_hp"]
	var inc: float = ctx["inc"]
	return minf(dmg, fh) + 0.1 * maxf(0.0, dmg - fh) + 0.9 * minf(sh, inc) + 0.1 * maxf(0.0, sh - inc) \
		+ 0.8 * minf(he, float(ctx["miss"])) + other


func _e2_state(ctx: Dictionary) -> Array:
	var faces: Array = []
	var cr: Array = []
	var wl: Array = []
	for en in ctx["e"]:
		faces.append(int(en["fi"]))
		cr.append(bool(en["cr"]))
		wl.append(int(en["wild"]))
	return [faces, cr, wl]


func _expert2_actions(eng: CombatEngine) -> void:
	var crack_p := float(CombatEngine.tune_knob("crack", "pct", 30.0)) / 100.0
	var bo_aware_roll := not _abl.has("no_bo_hunt")
	CoreHooks.mute += 1
	for step in 6:
		var ctx := _e2_ctx(eng)
		var st := _e2_state(ctx)
		var ents: Array = ctx["e"]
		var base := _e2_value(ctx, st[0], st[1], st[2])
		var base_roll := _e2_value(ctx, st[0], st[1], st[2], bo_aware_roll)
		var opts: Array = []   # {gain, kind, a, b}
		# ---- rerolls
		if not _noreroll and eng.reroll_total_turn < eng.reroll_hard_cap():
			var idx: Array = []
			for i in ents.size():
				if ents[i]["rr"]:
					idx.append(i)
			if not idx.is_empty():
				var free := eng.rerolls > 0
				var sets := _e2_sets(ctx, idx, st, bo_aware_roll)
				var draws: Array = []
				for sidx in E2_SAMPLES:
					var row: Array = []
					for i in ents.size():
						row.append([_brng.randi() % 6, _brng.randf()])
					draws.append(row)
				var modes: Array = [1]
				if not free and not _abl.has("no_lieu") and eng.depth_stage >= 2:
					modes.append(0)
				for sset in sets:
					for rm in modes:
						var tot := 0.0
						for row in draws:
							var f2: Array = (st[0] as Array).duplicate()
							var c2: Array = (st[1] as Array).duplicate()
							for i in sset:
								f2[i] = row[i][0]
								c2[i] = rm == 0 and float(row[i][1]) < crack_p
							tot += _e2_value(ctx, f2, c2, st[2], bo_aware_roll)
						var cost := 0.0 if rm == 0 else _e2_mana_cost_val(eng.mana, eng.reroll_mana_cost(false, 1))
						opts.append({"gain": tot / float(E2_SAMPLES) - base_roll - cost, "kind": "reroll", "a": sset, "b": rm})
		# ---- Mat Tam
		if not _abl.has("no_wild") and eng.depth_stage >= 2 and eng.wild_used < eng.wild_per_turn() and eng.mana >= eng.wild_cost():
			var wcost := _e2_mana_cost_val(eng.mana, eng.wild_cost())
			for i in ents.size():
				if not ents[i]["ready"] or int(ents[i]["wild"]) >= 0:
					continue
				for sl in 6:
					if sl == int(ents[i]["fi"]):
						continue
					var w2: Array = (st[2] as Array).duplicate()
					w2[i] = sl
					var g := _e2_value(ctx, st[0], st[1], w2) - base - wcost
					if g > 0.0:
						opts.append({"gain": g, "kind": "wild", "a": i, "b": sl})
		# ---- Overcast
		if not _abl.has("no_overcast"):
			var ocost := _e2_mana_cost_val(eng.mana, eng.overcast_cost())
			for i in ents.size():
				var en: Dictionary = ents[i]
				if not en["ready"] or not eng.can_overcast(int(en["uid"])):
					continue
				var pr: Array = eng.overcast_preview(en["u"])
				var t: String = en["ty"][int(en["fi"])]
				var w := 1.0 if t == "dmg" else (0.7 if t == "shield" else (0.6 if t == "heal" else 1.3))
				opts.append({"gain": w * (float(pr[1]) - float(pr[0])) - ocost, "kind": "oc", "a": i, "b": 0})
		opts.sort_custom(func(x, y): return float(x["gain"]) > float(y["gain"]))
		var done := false
		for o in opts:
			if float(o["gain"]) < E2_MIN_GAIN:
				break
			var ok := false
			var kind := String(o["kind"])
			var h0 := _hand(eng) if _trace_path != "" else ""
			var t0 := _turn_value(eng) if _trace_path != "" else 0.0
			if kind == "reroll":
				var uids: Array = []
				for i in (o["a"] as Array):
					uids.append(int(ents[i]["uid"]))
				if eng.can_reroll(uids, false, int(o["b"])):
					ok = eng.reroll_dice(uids, -1, false, int(o["b"]))
			elif kind == "wild":
				var uid := int(ents[int(o["a"])]["uid"])
				if eng.wild_block_reason(uid, int(o["b"])) == "":
					ok = eng.wild_face(uid, int(o["b"]))
			else:
				ok = eng.overcast(int(ents[int(o["a"])]["uid"]))
			if ok:
				if _trace_path != "":
					_trace("E2_" + kind + (("_" + ("LIEU" if int(o["b"]) == 0 else "SAFE")) if kind == "reroll" else ""), eng, h0, t0, "pred=%.1f" % float(o["gain"]))
				done = true
				break
		if not done:
			break
	CoreHooks.mute -= 1


## Candidate reroll subsets (indices into ctx["e"]): every single die, the lowest-value prefixes, everything outside the best part group.
func _e2_sets(ctx: Dictionary, idx: Array, st: Array, bo_aware: bool) -> Array:
	var ents: Array = ctx["e"]
	var keyv := {}
	var by_part := {}
	for i in idx:
		var en: Dictionary = ents[i]
		var fi: int = en["fi"]
		by_part[fi] = int(by_part.get(fi, 0)) + 1
	for i in idx:
		var fi2: int = ents[i]["fi"]
		var z: Array = (st[0] as Array).duplicate()
		var base1 := _e2_value(ctx, st[0], st[1], st[2], false)
		# value of the die by itself (no sets): replace it by a blank-ish removal via ready flag trick
		var en2: Dictionary = ents[i]
		en2["ready"] = false
		var v1 := _e2_value(ctx, st[0], st[1], st[2], false)
		en2["ready"] = true
		keyv[i] = base1 - v1 + (100.0 if (bo_aware and int(by_part.get(fi2, 0)) >= 3) else 0.0)
	var sorted := idx.duplicate()
	sorted.sort_custom(func(x, y): return float(keyv[x]) < float(keyv[y]))
	var out: Array = []
	var seen := {}
	var add := func(s: Array):
		if s.is_empty():
			return
		var k := s.duplicate()
		k.sort()
		var key := str(k)
		if not seen.has(key):
			seen[key] = true
			out.append(k)
	for i in idx:
		add.call([i])
	for n in range(2, mini(sorted.size(), 5) + 1):
		add.call(sorted.slice(0, n))
	if bo_aware:
		var best_pt := -1
		var best_n := 0
		for pt in by_part:
			if int(by_part[pt]) > best_n:
				best_n = int(by_part[pt])
				best_pt = pt
		if best_n >= 2:
			var outside: Array = []
			for i in idx:
				if int(ents[i]["fi"]) != best_pt:
					outside.append(i)
			add.call(outside)
	return out
