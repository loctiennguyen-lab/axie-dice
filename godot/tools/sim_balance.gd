extends Node
## Headless balance sim: plays whole Short runs with scripted bots and prints win-rates.
## Policies: attack_spam (dmg first, rest after), attack_only (dmg only), greedy, random_legal.
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
## Events a handler can see in every fight where the Core is owned.
const ALWAYS_EVENTS := ["on_combat_start", "on_turn_start", "on_turn_end", "on_roll_settled", "on_roll_end",
	"on_combat_end", "mod_face", "face_final", "roll_face", "roll_edit", "extra_dice", "class_field", "face_crit",
	"incoming_dmg", "boss_period", "boss_strike_mult", "enemy_row_pref", "front_row_size", "stash_cap", "stash_repeat",
	"reroll_mana_cost", "reroll_allowed", "before_reroll", "cantrip_extra", "roll_share_class", "descend_pick", "active_cost"]


func _ready() -> void:
	var args := _parse_args()
	var guard := SaveGuard.new()
	guard.capture()
	var recs := run_batch(args)
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
					cp = "greedy_axis" if (i / team_names.size()) % 2 == 1 else "random"
				recs.append(_play_run(int(args["seed"]) + i, team_name, int(asc_s), pol, cp))
	args["_secs"] = (Time.get_ticks_msec() - t0) / 1000.0
	return recs


func _play_run(seed_value: int, team_name: String, asc: int, policy: String, core_policy: String) -> Dictionary:
	_policy = policy
	_core_policy = core_policy
	_rng = Rng.new(seed_value ^ SALT)
	_fights = []
	_offered = {}
	_picked = []
	_trig = {}
	var team: Array[String] = []
	for k in (TEAMS[team_name] as Array):
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
				eng.action_log = RunState.action_log
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
				if RunState.phase == RunState.RunPhase.PACT and not RunState.take_pact(0):
					RunState.skip_pact()
				if not RunState.pending_rewards.is_empty():
					RunState.apply_chosen_reward(_pick_plain_reward())
			"event":
				var n_opt := RunState.event_options().size()
				if n_opt > 0:
					RunState.choose_event_option(_rng.next_int(n_opt))
			"shop":
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
	while not (eng.won or eng.lost) and turns < MAX_TURNS:
		_play_turn(eng)
		turns += 1
	return turns


func _play_turn(eng: CombatEngine) -> void:
	var guard := 0
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
