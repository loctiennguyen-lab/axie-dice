extends Node
## Headless balance sim: plays whole Short runs with scripted bots and prints win-rates.
## Policies: attack_spam (dmg first, rest after), attack_only (dmg only), greedy (1 step, heuristic values),
## expert (exact state eval via use_die + undo_last, free reroll, Hold on boss strike turn), random_legal.
## Cores: random | greedy_axis | combo (owned axis, then highest rarity); mix cycles the three.
## Args (after `--`): --runs=10 --seed=1000 --asc=0 --policies=attack_spam,greedy,random_legal
##   --teams=all|<name,name> --cores=random|greedy_axis|mix --out=<dir> --tag=<name>
## Mission mode (N-S, beta): --mission=N1..N6 (comma list ok) plays a Mission run: Ascension + Mission Rules M + the `standard`
##   block as RunState/ContentDB.mission_mods apply them. Ladder (LADDER below) is the brainstorm table, NOT read from
##   missions.json (N-C owns that file). Overrides: --asc=4 (list ok) --rules=M1,M5 (or --rules=none) --mode=short|full.
##   --rules=... without --mission = one "custom" config (per-rule d at A0/A3). --kind=mission (default, what the game does; since Liam 26/10
##   Mission runs carry an Anchor like a normal run, stage gate applies) | normal (header still carries the mission). --anchor defaults to auto in
##   mission mode. --force_run_rule=<id> makes the opening Run Rule offer hold only that rule (even a disabled one) and the bot takes it.
##   Same seed list for every config (seed+i, team/core policy by i) so configs pair by seed. CSV gets cfg,mode,rules columns;
##   the report adds win-rate, SE and Wilson 95% CI per config and paired differences.
## Deterministic by seed (the bot's own choices use a private Rng, never the game's).
## Never touches the network; the real save is guarded (SaveGuard) and the worktree has its own user dir.
## Engine gaps handled here (no engine edits): bot rng, preview via engine.preview_damage, private
## engine._face_value for non-dmg values.

const _Econ := preload("res://scripts/meta/economy_db.gd")
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
## Sensitive metrics per run (see SimReport.metric_section): player turns, damage dealt, V (sum of BO-type face values after the M bag
## over the ready dice) at turn start (v0) and after the bot's roll decisions (v1), sum of squared per-turn dmg, boss fight facts.
var _met := {}
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
var _corehold := true      # S2: expert Holds dice when it owns c_steady_hold / c_kindle / rule_tundra (--corehold=0 turns off)
const HOLD_CORES := ["c_steady_hold", "c_kindle", "rule_tundra", "c_key_strike"]
var _force: Array = []     # --force=id,id : grant these Cores at run start (diagnosis only)
var _anchor_mode := "none"   # none | auto | decline | a_volley | a_gambler | a_mana_mine | a_kin | a_embers | a_big_hand  (--anchor=)
var _stage := 3              # depth stage of every run (--stage=1|2|3)
var _anchor_aw_node := -1
var _anchor_aw_turn := -1
var _anchor_mut := {}
var _turns_total := 0
var _team_keys: Array = []
var _force_rule := ""      # --force_run_rule=<id>
var _arg_error := ""       # set by parse_mission_args
var _dump_fail := ""       # --dump_fail=<dir>: write the action log + tape of every run that fails verify (feed it to tools/verify_run.tscn)
var last_bundle: Dictionary = {}   # last verified run's {log fields..., tape}
var _verify := false       # --verify=1: after each run replay its action log through RunVerifier and compare (soak)
var _forced_mut := false   # this run had a forced Anchor / Run Rule that was NOT in the natural offer (replay cannot rebuild it)
## Fallback ladder (used only for a tier whose missions.json entry has no `rules` array) from design/proposals/nhiem-vu-beta-brainstorm.md section 2 (Huong B). Sim input, not game data.
const LADDER := {
	"N1": {"mode": "short", "asc": 0, "rules": []},
	"N2": {"mode": "short", "asc": 1, "rules": ["M6"]},
	"N3": {"mode": "short", "asc": 3, "rules": ["M5", "M6"]},
	"N4": {"mode": "short", "asc": 4, "rules": ["M1", "M7"]},
	"N5": {"mode": "short", "asc": 6, "rules": ["M2", "M4", "M5"]},
	"N6": {"mode": "full", "asc": 6, "rules": ["M1", "M5", "M6", "M7"]},
}
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


## Mana faces are Tai cantrips: they resolve inside roll_all / reroll (before the bot acts) and emit float_text "+N MP" (css "man").
## Count that exact amount so it is booked as in_face, not as turn-start / other.
var _mx_ft := 0.0
## OC2: false while the bot is only THINKING (_choose_move: trial use_die + undo_last, which emit the same float and are undone);
## true again inside real rerolls (_mx_reroll) and outside _choose_move (end_turn roll, setup roll).
var _mx_listen := true
func _on_float_text(_uid, text, css, _big) -> void:
	if _mx_listen and String(css) == "man" and String(text).begins_with("+") and String(text).ends_with(" MP"):
		_mx_ft += float(String(text).trim_prefix("+").trim_suffix(" MP").to_int())


func _mx_hook() -> void:
	if not EventBus.float_text.is_connected(_on_float_text):
		EventBus.float_text.connect(_on_float_text)


func _ready() -> void:
	if EventBus.has_signal("core_fired"):   # exact trigger counter (FX lane); else the heuristic in _note_triggers
		EventBus.connect("core_fired", _on_core_fired)
	var args := _parse_args()
	var guard := SaveGuard.new()
	guard.capture()
	_pact_mode = String(args.get("pact", "take"))
	_shop_mode = String(args.get("shop", "all"))
	_beam = int(args.get("beam", 3))
	_anchor_mode = String(args.get("anchor", "none"))
	_stage = clampi(int(args.get("stage", 3)), 1, 3)
	_nohold = int(args.get("hold", 0)) != 1   # Hold is OFF by default: ablation showed it costs ~4 points
	_noreroll = int(args.get("noreroll", 0)) == 1
	_corehold = int(args.get("corehold", 1)) == 1
	_force = Array(String(args.get("force", "")).split(",", false))
	var recs: Array
	if args.has("from"):   # --from=a.csv,b.csv : rebuild/merge a report from raw CSVs, no simulation
		recs = SimReport.read_csvs(String(args["from"]).split(","))
		args["policies"] = "merged"
		args["asc"] = "-"
		args["runs"] = recs.size()
	else:
		recs = run_batch(args)
		if _arg_error != "":
			guard.restore()
			get_tree().quit(2)
			return
	guard.restore()
	var out_dir := String(args.get("out", ProjectSettings.globalize_path("res://").path_join("../production/qa/sim")))
	var tag := String(args.get("tag", "%dx%s_A%s" % [int(args["runs"]), str(args["policies"]).replace(",", "+"), args["asc"]]))
	if args.has("mission") and not args.has("tag"):
		tag = "%dx%s_%s" % [int(args["runs"]), str(args["policies"]).replace(",", "+"), str(args["mission"]).replace(",", "+")]
	SimReport.write(recs, out_dir, tag, float(args.get("_secs", 0.0)), catalog())
	get_tree().quit(0)


func _parse_args() -> Dictionary:
	var a := {"runs": 10, "seed": 1000, "asc": "0", "_asc_default": true, "policies": "attack_spam,greedy", "teams": "all", "cores": "mix", "tag": ""}
	for s in OS.get_cmdline_user_args():
		if s.begins_with("--") and s.contains("="):
			var kv := s.substr(2).split("=", true, 1)
			a[kv[0]] = kv[1]
			if kv[0] == "asc":
				a.erase("_asc_default")
	a["runs"] = int(a["runs"])
	a["seed"] = int(a["seed"])
	if a["tag"] == "":
		a.erase("tag")
	return a


## Returns an Array of run records (see _play_run). Public so the smoke test can call it.
func run_batch(args: Dictionary) -> Array:
	var recs: Array = []
	_mx_hook()
	var team_names: Array = TEAMS.keys() if String(args.get("teams", "all")) == "all" else String(args["teams"]).split(",")
	_e2_samples = int(args.get("e2_samples", 16))
	_e2_min_gain = float(args.get("e2_min_gain", 0.8))
	_e2_lam = [float(args.get("e2_lam_lo", 0.5)), float(args.get("e2_lam_mid", 0.35)), float(args.get("e2_lam_hi", 0.25))]
	_e1_min_ev = float(args.get("e1_min_ev", 1.0))
	_e1_mana_lam = float(args.get("e1_mana_lam", 0.35))
	_e1_p = float(args.get("e1_p", -1.0))
	var parsed := parse_mission_args(args)
	_arg_error = String(parsed["error"])
	if _arg_error != "":
		push_error("sim_balance: " + _arg_error)
		return recs
	var variants: Array = parsed["configs"]
	if variants.is_empty():
		for asc_s in String(args.get("asc", "0")).split(","):
			variants.append({"label": "", "tier": "", "mode": String(args.get("mode", "short")), "asc": int(asc_s), "rules": [], "kind": ""})
	else:
		_anchor_mode = String(args.get("anchor", "auto"))
		_stage = clampi(int(args.get("stage", 3)), 1, 3)
	_force_rule = String(args.get("force_run_rule", ""))
	_verify = int(args.get("verify", 0)) == 1
	_dump_fail = String(args.get("dump_fail", ""))
	if _force_rule != "":
		var fd = RelicRegistry.get_def(_force_rule)
		if fd == null or String(fd.core_axis) != "run_rule":
			_arg_error = "--force_run_rule=%s is not a Run Rule id" % _force_rule
			push_error("sim_balance: " + _arg_error)
			return recs
	var t0 := Time.get_ticks_msec()
	for cfg in variants:
		for pol in String(args.get("policies", "greedy")).split(","):
			for i in int(args["runs"]):
				var team_name: String = team_names[i % team_names.size()]
				var cp: String = String(args.get("cores", "mix"))
				if cp == "mix":
					cp = ["random", "greedy_axis", "combo"][(i / team_names.size()) % 3]
				recs.append(_play_run(int(args["seed"]) + i, team_name, int(cfg["asc"]), pol, cp, cfg))
	args["_secs"] = (Time.get_ticks_msec() - t0) / 1000.0
	return recs


const MX_KEYS := ['in_face', 'in_cantrip', 'in_use_other', 'in_turnstart', 'in_other', 'out_safe1', 'out_safe2', 'out_wild', 'out_oc', 'out_lieu', 'out_other', 'end_sum', 'end_n', 'buy_safe1', 'buy_safe2', 'buy_safe_free', 'buy_wild', 'buy_oc', 'buy_lieu', 'wild_n2', 'wild_n3', 'wild_n4', 'bo_turns', 'bo_m3_pre', 'bo_m3_post', 'face_rolled']
var _mx_prev_end := 0   # mana left at the end of the previous turn of this fight (0 at fight start)
var _mx_paid_k := 0     # paid Safe rerolls so far this turn


## Parses the mission-mode flags (see header). Returns {error, configs}; configs is [] when neither --mission nor --rules is given
## (then the sim behaves exactly as before). Pure: touches no state.
func parse_mission_args(args: Dictionary) -> Dictionary:
	var out := {"error": "", "configs": []}
	var has_mode := args.has("mode")
	var mode_o := String(args.get("mode", "short")).to_lower()
	if has_mode and not (mode_o == "short" or mode_o == "full"):
		out["error"] = "--mode must be short|full, got '%s'" % mode_o
		return out
	var kind := String(args.get("kind", "mission")).to_lower()
	if kind != "mission" and kind != "normal":
		out["error"] = "--kind must be mission|normal, got '%s'" % kind
		return out
	if not args.has("mission") and not args.has("rules"):
		return out
	var tiers: Array = ["custom"]
	if args.has("mission"):
		tiers = []
		for t in String(args["mission"]).split(",", false):
			var tid := t.strip_edges().to_upper()
			if not LADDER.has(tid):
				out["error"] = "--mission: unknown tier '%s' (N1..N6)" % t
				return out
			tiers.append(tid)
		if tiers.is_empty():
			out["error"] = "--mission is empty"
			return out
	var table_tiers: Dictionary = ((args["_table"] if args.has("_table") else _Econ.get_table("missions")) as Dictionary).get("tiers", {})
	var rules_o: Array = []
	var has_rules := args.has("rules")
	if has_rules:
		var table: Dictionary = ContentDB.mission_table.get("rules", {})
		for r in String(args["rules"]).split(",", false):
			var rid := r.strip_edges().to_upper()
			if rid == "NONE":
				continue
			if not table.has(rid):
				out["error"] = "--rules: unknown rule '%s'" % r
				return out
			if not rules_o.has(rid):
				rules_o.append(rid)
	var asc_o: Array = []
	if args.has("asc") and not bool(args.get("_asc_default", false)):
		for a in String(args["asc"]).split(",", false):
			asc_o.append(int(a))
	for tid in tiers:
		var base: Dictionary = LADDER.get(tid, {"mode": "short", "asc": 0, "rules": []})
		var src := "brainstorm(bs)" if tid != "custom" else "custom"
		var tt: Dictionary = (table_tiers.get(tid, {}) as Dictionary)
		if tid != "custom" and tt.get("rules", null) is Array:   # new form: the table the game reads
			base = {"mode": String(tt.get("mode", "short")), "asc": int(tt.get("ascension", 0)), "rules": (tt["rules"] as Array).map(func(x): return String(x))}
			src = "missions.json"
		var ascs: Array = asc_o if not asc_o.is_empty() else [int(base["asc"])]
		for asc in ascs:
			var rules: Array = rules_o.duplicate() if has_rules else (base["rules"] as Array).duplicate()
			var mode := mode_o if has_mode else String(base["mode"])
			var label := String(tid) + ("(bs)" if src.begins_with("brainstorm") else "")
			var mods: Array = []
			if asc != int(base["asc"]):
				mods.append("A%d" % asc)
			if has_rules and rules != (base["rules"] as Array):
				mods.append("rules=" + ("+".join(rules) if not rules.is_empty() else "none"))
			if mode != String(base["mode"]):
				mods.append(mode)
			if tid == "custom":
				label = "custom@A%d[%s]" % [asc, "+".join(rules) if not rules.is_empty() else "none"] + ("" if mode == "short" else "/" + mode)
			elif not mods.is_empty():
				label += "{" + ",".join(mods) + "}"
			(out["configs"] as Array).append({"label": label, "tier": tid, "mode": mode, "asc": int(asc), "rules": rules, "kind": kind, "src": src})
	return out


func _play_run(seed_value: int, team_name: String, asc: int, policy: String, core_policy: String, cfg: Dictionary = {}) -> Dictionary:
	_policy = policy
	_core_policy = core_policy
	_mx_ft = 0.0
	_abl = {}
	_met = {"turns": 0, "dmg": 0.0, "v0": 0.0, "v1": 0.0, "dsq": 0.0, "boss_n": 0, "boss_turns": 0, "boss_won": 0, "boss_hp": 0.0}
	for k in MX_KEYS:
		_met["mx_" + k] = 0.0
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
	_anchor_aw_node = -1
	_anchor_aw_turn = -1
	_anchor_mut = {}
	_turns_total = 0
	_forced_mut = false
	var team: Array[String] = []
	var keys: Array = TEAMS[team_name] if TEAMS.has(team_name) else Array(team_name.split("+"))   # "a+b+c+d+e" = explicit heroes
	for k in keys:
		team.append(String(k))
	_team_keys = team.duplicate()
	var run_params := {
		"team_keys": team, "mode": "short", "ascension": asc, "ranked": false, "rules_on": true,
		"newcomer": false, "bonuses": {}, "anchor": _anchor_mode != "none", "depth_stage": _stage}
	var cfg_label := String(cfg.get("label", ""))
	if cfg_label != "":
		# What MissionsScreen.mission_params builds (kind "mission" + header), minus stake/payout (the sim does not settle).
		run_params["mode"] = String(cfg["mode"])
		run_params["kind"] = String(cfg["kind"])
		run_params["mission"] = {"mission_id": "sim|%s" % cfg_label, "tier": int(String(cfg["tier"]).substr(1)) if String(cfg["tier"]).begins_with("N") else 0,
			"rules": (cfg["rules"] as Array).duplicate()}
	RunState.start_run_with_epoch(LocalEpochSource.new(PackedByteArray(), seed_value), run_params, seed_value)
	for fid in _force:
		RunState._grant_relic(String(fid), "sim_force")
	_drain_core_offers()
	_poll_anchor(0)
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
				eng.action_log = RunState.action_log if _verify else null   # trial moves go through _undo(), which drops the trial pair from the log; without --verify nothing is logged
				var aff := ""
				if node.node_type == "elite" and not eng.enemies.is_empty():
					aff = String((eng.enemies[0] as Unit).custom_state.get("affix", ""))
				var owned_snap: Array = RunState.owned_relic_ids.duplicate()
				_shield_used = 0
				var turns := _play_combat(eng)
				_turns_total += turns
				_note_triggers(eng, owned_snap)
				_fights.append({"kind": node.node_type, "turns": turns, "won": eng.won, "stuck": turns > STUCK_TURNS or not (eng.won or eng.lost), "affix": aff})
				RunState.apply_combat_result(eng.get_result())
				if node.node_type == "boss":
					var hp_now := 0.0
					var hp_max := 0.0
					for pu in eng.party:
						hp_now += float(maxi(0, (pu as Unit).hp))
						hp_max += float((pu as Unit).max_hp)
					_met["boss_n"] = int(_met["boss_n"]) + 1
					_met["boss_turns"] = int(_met["boss_turns"]) + turns
					_met["boss_won"] = 1 if eng.won else 0
					_met["boss_hp"] = hp_now / maxf(hp_max, 1.0)
				if not eng.won:
					death_kind = node.node_type
					death_row = node.row
				if RunState.phase == RunState.RunPhase.PACT:
					if _pact_mode == "skip" and RunState.pact_can_skip():
						RunState.skip_pact()
					else:
						_settle_pact()
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
		_poll_anchor(walked)
		if node.next_ids.is_empty():
			break
		node = graph.find_node(String(node.next_ids[_rng.next_int(node.next_ids.size())]))
	var won := RunState.phase == RunState.RunPhase.WON
	# S1: a Core counts as fired if it reported core_fired at ANY time of the run (also outside fights, also self-removing
	# Cores such as c_fossil, or c_dim_stone that is swapped for a Crystal Core on pick) as long as it was picked/owned.
	if EventBus.has_signal("core_fired"):
		for fid in _core_fired_seen:
			if _picked.has(fid) or RunState.owned_relic_ids.has(fid) or String(RunState.run_rule) == String(fid):
				_trig[fid] = true
	var cores: Array = []
	for id in RunState.owned_relic_ids:
		var d = RelicRegistry.get_def(String(id))
		if d != null and String(d.id).begins_with("c_"):
			cores.append(String(id) + "@" + String(d.core_axis))
	var end_state := "WON" if won else ("LOST" if RunState.phase == RunState.RunPhase.LOST else "STUCK")
	if end_state == "STUCK":
		end_state = "STUCK_NODES" if walked >= MAX_NODES else "STUCK_PHASE%d" % int(RunState.phase)
	for fgt in _fights:   # a fight the bot could not finish inside MAX_TURNS (hang candidate), whatever the run did afterwards
		if int((fgt as Dictionary)["turns"]) >= MAX_TURNS:
			end_state = "STUCK_TURNS"
	var vres := _verify_run(won, seed_value) if _verify else ["", ""]
	return {"seed": seed_value, "policy": policy, "core_policy": core_policy, "team": team_name, "asc": asc,
		"end": end_state, "verify": vres[0], "vdetail": vres[1],
		"won": won, "death_kind": death_kind, "death_row": death_row, "rule": RunState.run_rule,
		"cores": cores, "fights": _fights.duplicate(true), "offered": _offered.keys(), "picked": _picked.duplicate(),
		"trig": _trig.keys(), "m": _met.duplicate(),
		"anchor": RunState.anchor_id, "aw_node": _anchor_aw_node, "aw_turn": _anchor_aw_turn,
		"mut": _anchor_mut.duplicate(), "combos": RunState.combo_done.size(),
		"cfg": cfg_label, "src": String(cfg.get("src", "")), "kind": String(cfg.get("kind", "")), "mode": String(cfg.get("mode", "short")), "rules": "+".join(cfg.get("rules", []) as Array)}



## Soak (--verify=1): the run just played is replayed through RunVerifier from its own action log + epoch tape. "ok" = the replay accepted
## every action AND reached the same end state (won, score, phase, power, relics, nodes, shards); "skip_forced" = a forced Anchor / Run Rule the
## verifier cannot rebuild; "diff:<field>" / "rejected:<error>@<index>" = a real mismatch (bug candidate). Runs AFTER the record is read from RunState,
## because the verifier takes RunState over.
func _verify_run(won: bool, seed_value: int) -> Array:
	if _forced_mut:
		return ["skip_forced", ""]
	var log: ActionLog = RunState.action_log
	if log == null:
		return ["no_log", ""]
	var live := {"phase": int(RunState.phase), "power_level": RunState.power_level, "relics": RunState.owned_relic_ids.duplicate(),
		"visited": RunState.visited_node_ids.duplicate(), "shards": RunState.shards_this_run, "score": RunState.compute_run_xp(won)}
	var tape: Array = RunState.epoch.tape() if RunState.epoch != null else []
	var bundle := log.to_data()
	bundle["tape"] = tape
	last_bundle = bundle.duplicate(true)   # for tests (t_soak_verify): the log + tape that was just verified
	var copy := ActionLog.from_data(bundle)
	var v := RunVerifier.verify(copy, tape, {}, true)
	if _dump_fail != "" and (not bool(v.get("ok", false)) or _verify_diff(v, live, won) != ""):
		DirAccess.make_dir_recursive_absolute(_dump_fail)
		var f := FileAccess.open(_dump_fail.path_join("log_%d_%s_%s.json" % [seed_value, _policy, _team_keys[0] if not _team_keys.is_empty() else "x"]), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(bundle))
			f.close()
	if not bool(v.get("ok", false)):
		return ["rejected:%s@%d" % [String(v.get("error", "?")), int(v.get("action_index", -1))], String(v.get("message", "")).replace(",", ";").replace("\n", " ")]
	var dd := _verify_diff(v, live, won)
	if dd != "":
		return [dd.get_slice("|", 0), dd.get_slice("|", 1)]
	return ["ok", ""]


## "" when the replay verdict `v` matches the live end state, else "diff:<field>|<detail>".
func _verify_diff(v: Dictionary, live: Dictionary, won: bool) -> String:
	var st: Dictionary = v.get("state", {}) as Dictionary
	if bool(v.get("won", false)) != won:
		return "diff:won|live=%s replay=%s" % [str(won), str(v.get("won"))]
	if int(v.get("score", -1)) != int(live["score"]):
		return "diff:score|live=%d replay=%d" % [int(live["score"]), int(v.get("score", -1))]
	for k in [["phase", "phase"], ["power_level", "power_level"], ["relics", "owned_relic_ids"], ["visited", "visited_node_ids"], ["shards", "shards_this_run"]]:
		if JSON.stringify(live[k[0]]) != JSON.stringify(st.get(k[1])):
			return ("diff:%s|live=%s replay=%s" % [String(k[0]), JSON.stringify(live[k[0]]), JSON.stringify(st.get(k[1]))]).replace(",", ";")
	return ""


## Settles the open boss Pact like a player would: first card that fits (selling a relic when the slots are full), else skip, and if the offer is
## forced and nothing fits, any card with a sale. (Before 26/10 the bot tried card 0 only and then walked on with the Pact still open: the live run
## accepted a reward in PACT phase, the verifier rightly refused it = 14 false "mismatches" in the soak.)
func _settle_pact() -> void:
	var cards := RunState.pact_cards()
	for i in cards.size():
		var c: Dictionary = cards[i]
		if bool(c["ok"]):
			if RunState.take_pact(i):
				return
		elif bool(c["needs_sell"]) and not (c["sell_from"] as Array).is_empty():
			if RunState.take_pact(i, String((c["sell_from"] as Array)[0])):
				return
	if RunState.phase == RunState.RunPhase.PACT:
		RunState.skip_pact()
	if RunState.phase == RunState.RunPhase.PACT:
		push_warning("sim_balance: Pact could not be settled")


const _UNDOABLE := ["use_die", "overcast", "wild_face", "play_active", "stash"]


## eng.undo_last() for the bot's THINKING (trial move + undo). With --verify the trial pair is cut out of the action log again, so the log holds only
## real decisions (a trial search would otherwise blow the 3000-action cap) and the replay does not play trials.
func _undo(eng: CombatEngine) -> bool:
	var ok := eng.undo_last()
	if _verify and ok and eng.action_log != null and OS.get_environment("AXIE_SOAK_KEEP_TRIALS") != "1":
		var en: Array = eng.action_log.entries
		var n := en.size()
		if n >= 2 and String((en[n - 1] as Dictionary).get("fn", "")) == "undo_last" and _UNDOABLE.has(String((en[n - 2] as Dictionary).get("fn", ""))):
			en.pop_back()
			en.pop_back()
	return ok


# ---------------------------------------------------------------- rewards / cores

## Anchor pick (opt-in with --anchor). random policies pick at random, expert by a team heuristic, --anchor=<id> forces one.
func _anchor_step() -> void:
	if _anchor_mode == "none" or not RunState._anchor_waiting or not RunState.anchor_offer_open():
		return
	if _anchor_mode == "decline":   # Anchor screen shown, the player passes (--anchor=decline)
		RunState.decline_anchor()
		return
	var offer: Array = RunState.anchor_offer
	var pick := String(offer[0])
	if _anchor_mode != "auto":
		if not offer.has(_anchor_mode):   # 6 Anchors, 3 offered: a forced run must really hold the forced Anchor
			_forced_mut = true
			offer[0] = _anchor_mode
			RunState.anchor_offer = offer
		pick = _anchor_mode
	elif _policy.begins_with("expert") or _policy == "free_hold":
		pick = _anchor_heuristic(offer)
	else:
		pick = String(offer[_rng.next_int(offer.size())])
	if not RunState.pick_anchor(pick):
		RunState.decline_anchor()


## Cheap team-based guess: Volley wants shield faces (plant/reptile), Mana Mine wants aqua/mana income, Gambler wants a
## roster that profits from Lieu (beast/bird/bug). Kin wants 3+ Axies of one class, Embers wants a Hold Core (it also Holds big dice
## itself, see _core_hold), Big Hand wants a team with many repeated faces (approximated by class stacking + its own house Cores).
## Ties go to the first in offer order.
func _anchor_heuristic(offer: Array) -> String:
	var n := {"shield": 0, "mana": 0, "gamble": 0}
	var by_cls := {}
	for u in _team_keys:
		var k := String(u)
		var cls := k.rstrip("0123456789")
		by_cls[cls] = int(by_cls.get(cls, 0)) + 1
		if k.begins_with("plant") or k.begins_with("reptile"):
			n["shield"] += 1
		elif k.begins_with("aqua"):
			n["mana"] += 1
		else:
			n["gamble"] += 1
	var top := 0
	for c in by_cls:
		top = maxi(top, int(by_cls[c]))
	var hold_core := 0
	for id in HOLD_CORES:
		if RunState.owned_relic_ids.has(id) or String(RunState.run_rule) == id:
			hold_core += 1
	var big_core := 0
	for id in (Anchors.get_def("a_big_hand").get("house_cores", []) as Array):
		if RunState.owned_relic_ids.has(id):
			big_core += 1
	var sc := {"a_volley": n["shield"] + 0.5, "a_mana_mine": n["mana"] * 1.5 + 0.7, "a_gambler": n["gamble"] + 0.6,
		"a_kin": (3.5 + top if top >= 3 else 0.3), "a_embers": 1.6 + 2.0 * hold_core, "a_big_hand": 1.0 + 0.6 * top + 1.0 * big_core}
	var best := String(offer[0])
	for id in offer:
		if float(sc.get(String(id), 0.0)) > float(sc.get(best, 0.0)):
			best = String(id)
	return best


func _poll_anchor(node_no: int) -> void:
	if RunState.anchor_id == "":
		return
	if RunState.anchor_awakened and _anchor_aw_node < 0:
		_anchor_aw_node = node_no
		_anchor_aw_turn = _turns_total
	var t: Dictionary = RunState.house_tiers_now()
	for hid in t.keys():
		_anchor_mut[hid] = maxi(int(_anchor_mut.get(hid, 0)), int(t[hid]))


func _drain_core_offers() -> void:
	var guard := 0
	while guard < 16:
		_anchor_step()
		if not ((RunState._core_offer_active or RunState._rule_offer_active) and not RunState.pending_rewards.is_empty()):
			break
		guard += 1
		var cards: Array = RunState.pending_rewards
		for c in cards:
			_offered[String((c as Dictionary).get("key", ""))] = true
		var card: Dictionary = cards[0]
		if bool(card.get("rule", false)) and _force_rule != "":
			# --force_run_rule: the offer becomes just this rule (valid or not, even `disabled`); no bot rng is drawn.
			var natural_hit := false
			for c0 in cards:
				if String((c0 as Dictionary).get("key", "")) == _force_rule:
					natural_hit = true
			if not (cards.size() == 1 and natural_hit):
				_forced_mut = true
			card = CoreOffer.rule_card_of(RelicRegistry.get_def(_force_rule), 0)
			RunState.pending_rewards = [card]
		elif bool(card.get("rule", false)):
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
	if RunState.anchor_id != "" and (_policy.begins_with("expert") or _policy == "free_hold") \
			and (Anchors.get_def(RunState.anchor_id).get("house_cores", []) as Array).has(id):
		sc += 3.0   # expert leans a little toward the Anchor's own-house Cores
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
	_mx_prev_end = 0
	while not (eng.won or eng.lost) and turns < MAX_TURNS:
		_play_turn(eng)
		turns += 1
	return turns


func _play_turn(eng: CombatEngine) -> void:
	var guard := 0
	if _policy == "random_legal":
		_random_extras(eng)
	var dmg0 := float(eng.stat.get("dmg_dealt_clamped", 0))
	var v0 := _v_sum(eng)
	var v1 := -1.0
	var mx_start := eng.mana
	_mx_paid_k = 0
	_mx_acc_before = _mx_tracked_net()
	var ft0 := _mx_ft   # mana-face cantrips resolved by the roll that started this turn
	_mx_ft = 0.0
	if mx_start >= _mx_prev_end:
		var fr := minf(ft0, float(mx_start - _mx_prev_end))
		_ma("in_face", fr)
		_ma("in_turnstart", float(mx_start - _mx_prev_end) - fr)
	else:
		_ma("out_other", _mx_prev_end - mx_start)
	while guard < 24 and not (eng.won or eng.lost):
		guard += 1
		_mx_listen = false
		var mv := _choose_move(eng)
		_mx_listen = true
		if v1 < 0.0:
			_mx_decision_point(eng, mx_start)
			v1 = _v_sum(eng)   # after the bot's roll decisions (rerolls / Mat Tam / Overcast happen inside the first _choose_move)
		if mv.is_empty():
			break
		var mu: Unit = eng.by_uid(int(mv[0]))
		var mt := String(mu.current_face().get("type", "")) if mu != null else ""
		var mx_m0 := eng.mana
		var mx_cant := int(eng._kw_val(mu.current_face(), "mana")) if mu != null and mu.side == "p" else 0
		var ft_keep := _mx_ft
		var used_ok := eng.use_die(int(mv[0]), int(mv[1]))
		_mx_ft = ft_keep   # a mana face used by hand is booked by _mx_use_gain, not by the listener
		if not used_ok:
			break
		_mx_use_gain(eng.mana - mx_m0, mt, mx_cant)
		if mt == "shield":
			_shield_used += 1
	if not (eng.won or eng.lost):
		_mx_close_turn(eng, mx_start)
		eng.end_turn()
		_mx_prev_end = eng.mana
	else:
		_mx_prev_end = 0
		_mx_ft = 0.0
	var dd := float(eng.stat.get("dmg_dealt_clamped", 0)) - dmg0
	_met["turns"] = int(_met["turns"]) + 1
	_met["dmg"] = float(_met["dmg"]) + dd
	_met["dsq"] = float(_met["dsq"]) + dd * dd
	_met["v0"] = float(_met["v0"]) + v0
	_met["v1"] = float(_met["v1"]) + (v1 if v1 >= 0.0 else v0)


# ---------------------------------------------------------------- mana accounting (step 0, v4 mana decisions)
# All real (non-trial) mana-moving calls of the bots go through these wrappers; trial moves (use_die + undo_last) are not counted.
var _mx_acc_before := 0.0

func _ma(key: String, v: float) -> void:
	_met["mx_" + key] = float(_met["mx_" + key]) + v


func _mx_tracked_net() -> float:
	var t := 0.0
	for k in MX_KEYS:
		if k.begins_with("in_") and k != "in_turnstart":
			t += float(_met["mx_" + k])
		elif k.begins_with("out_") and k != "out_other":
			t -= float(_met["mx_" + k])
	return t


## Mana change caused by a die being used: mana face, cantrip keyword, anything else (Cores / relics) is "use_other".
func _mx_use_gain(d: int, face_type: String, cantrip: int) -> void:
	if d == 0:
		return
	if d < 0:
		return   # counted by the end-of-turn residual
	var rest := d
	var c := mini(cantrip, rest)
	_ma("in_cantrip", c)
	rest -= c
	if face_type == "mana":
		_ma("in_face", rest)
		rest = 0
	_ma("in_use_other", rest)


## Called once per turn after the bot's roll decisions: is there a BỘ, how much mana is there to Overcast it with.
func _mx_decision_point(eng: CombatEngine, mana_start: int) -> void:
	for u in _ready_units(eng):
		if String((u as Unit).current_face().get("type", "")) == "mana":
			_ma("face_rolled", 1)
	if eng.bo.is_empty():
		return
	_ma("bo_turns", 1)
	if mana_start >= eng.overcast_cost():
		_ma("bo_m3_pre", 1)
	if eng.mana >= eng.overcast_cost():
		_ma("bo_m3_post", 1)


## Before end_turn: unspent mana, plus whatever changed this turn that no wrapper saw (Core hooks on reroll / turn start...).
func _mx_close_turn(eng: CombatEngine, mana_start: int) -> void:
	_ma("end_sum", eng.mana)
	_ma("end_n", 1)
	# Mana faces that came in with rerolls this turn. The expert also rolls in TRIALS (undone), which emit the same float, so the
	# listener total is only an upper bound: cap it by the real unexplained mana gain of the turn.
	var expect0 := float(mana_start) + (_mx_tracked_net() - _mx_acc_before)
	_ma("in_face", clampf(_mx_ft, 0.0, maxf(0.0, float(eng.mana) - expect0)))
	_mx_ft = 0.0
	var expect := float(mana_start) + (_mx_tracked_net() - _mx_acc_before)
	var resid := float(eng.mana) - expect
	if resid > 0.0:
		_ma("in_other", resid)
	elif resid < 0.0:
		_ma("out_other", -resid)


## S3: a REAL action must not run muted: the callers (_expert2_actions, _free_hold_rerolls) mute CoreHooks for their look-ahead, which silenced
## every core_fired raised by a paid reroll / Mat Tam / Overcast (c_tidecaller read 0% fired for that reason).
func _mx_reroll(eng: CombatEngine, uids: Array, rm: int) -> bool:
	var saved_mute := CoreHooks.mute
	CoreHooks.mute = 0
	var r := _mx_reroll_real(eng, uids, rm)
	CoreHooks.mute = saved_mute
	return r


func _mx_reroll_real(eng: CombatEngine, uids: Array, rm: int) -> bool:
	var m0 := eng.mana
	var free := eng.rerolls > 0
	var was := _mx_listen
	_mx_listen = true   # real reroll: its mana-face cantrips are real income
	var ok := eng.reroll_dice(uids, -1, false, rm)
	_mx_listen = was
	if not ok:
		return false
	var d := m0 - eng.mana
	if rm == 0:
		_ma("buy_lieu", 1)
		if d > 0:
			_ma("out_lieu", d)
	elif d > 0:
		_mx_paid_k += 1
		_ma("buy_safe1" if _mx_paid_k == 1 else "buy_safe2", 1)
		_ma("out_safe1" if _mx_paid_k == 1 else "out_safe2", d)
	else:
		_ma("buy_safe_free", 1)
	if d < 0:
		_ma("in_other", -d)
	return ok


## S3: a REAL action must not run muted: the callers (_expert2_actions, _free_hold_rerolls) mute CoreHooks for their look-ahead, which silenced
## every core_fired raised by a paid reroll / Mat Tam / Overcast (c_tidecaller read 0% fired for that reason).
func _mx_wild(eng: CombatEngine, uid: int, slot: int) -> bool:
	var saved_mute := CoreHooks.mute
	CoreHooks.mute = 0
	var r := _mx_wild_real(eng, uid, slot)
	CoreHooks.mute = saved_mute
	return r


func _mx_wild_real(eng: CombatEngine, uid: int, slot: int) -> bool:
	var m0 := eng.mana
	var u := eng.by_uid(uid)
	var after := 0
	if u != null:
		var save := u.wild_slot
		u.wild_slot = slot
		for dd in eng._bo_dice():
			if (dd.wild_slot if dd.wild_slot >= 0 else dd.roll_face_index()) == slot:
				after += 1
		u.wild_slot = save
	if not eng.wild_face(uid, slot):
		return false
	_ma("buy_wild", 1)
	_ma("out_wild", m0 - eng.mana)
	var before := after - 1   # group size before the click (n=2 -> a Set of 3; n=3 -> a Set of 4)
	_ma("wild_n%d" % clampi(before, 2, 4), 1)
	return true


## S3: a REAL action must not run muted: the callers (_expert2_actions, _free_hold_rerolls) mute CoreHooks for their look-ahead, which silenced
## every core_fired raised by a paid reroll / Mat Tam / Overcast (c_tidecaller read 0% fired for that reason).
func _mx_overcast(eng: CombatEngine, uid: int) -> bool:
	var saved_mute := CoreHooks.mute
	CoreHooks.mute = 0
	var r := _mx_overcast_real(eng, uid)
	CoreHooks.mute = saved_mute
	return r


func _mx_overcast_real(eng: CombatEngine, uid: int) -> bool:
	var m0 := eng.mana
	if not eng.overcast(uid):
		return false
	_ma("buy_oc", 1)
	_ma("out_oc", m0 - eng.mana)
	return true


## V = sum of face values (after the M bag, Cores muted) of the dmg/shield/heal/poison faces on the dice that can still be played.
func _v_sum(eng: CombatEngine) -> float:
	var t := 0.0
	CoreHooks.mute += 1
	for u in _ready_units(eng):
		var uu: Unit = u
		if String(uu.current_face().get("type", "")) in CombatEngine.BO_TYPES:
			t += float(eng._face_value(uu, uu.roll_face_index()))
	CoreHooks.mute -= 1
	return t


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
	if _policy.begins_with("expert") or _policy == "free_hold":   # expert, expert_no_bo_hunt, expert_no_lieu, expert_no_wild, expert_no_overcast, expert_legacy
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
			_mx_reroll(eng, uids, rm)
	if _rng.next_int(100) < 30:
		var opts: Array = []
		for u in _ready_units(eng):
			for sl in 6:
				if eng.wild_block_reason(u.uid, sl) == "":
					opts.append([u.uid, sl])
		if not opts.is_empty():
			var o: Array = opts[_rng.next_int(opts.size())]
			_mx_wild(eng, int(o[0]), int(o[1]))
	if _rng.next_int(100) < 30:
		var oc: Array = []
		for u in _ready_units(eng):
			if eng.can_overcast(u.uid):
				oc.append(u.uid)
		if not oc.is_empty():
			_mx_overcast(eng, int(oc[_rng.next_int(oc.size())]))


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
		v -= float(eu.hp) + 0.8 * float(eu.shield) + 4.0 + thr * 0.8 + 0.8 * float(eng.shell_of(eu))   # anti-spam B: Shell left is HP left
		v -= 0.7 * minf(float(eu.status.get("poison", 0)) * -1.0, 0.0)   # (poison counted below as bonus)
		v += 0.9 * minf(float(eu.status.get("poison", 0)), float(eu.hp))
	if CombatEngine.antispam_on("mana_heat"):   # anti-spam A: mana over keep is burned into HP at end of turn
		v += 0.5 * float(mini(eng.mana, eng.mana_heat_keep())) - 0.9 * float(eng.mana_heat_preview()["dmg"])
	else:
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
## Trial use_die + undo_last must not count as a Core firing: mute the whole search.
func _plan_turn(eng: CombatEngine, ready: Array, foes: Array) -> Array:
	CoreHooks.mute += 1
	var r := _plan_turn_inner(eng, ready, foes)
	CoreHooks.mute -= 1
	return r


func _plan_turn_inner(eng: CombatEngine, ready: Array, foes: Array) -> Array:
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
							_undo(eng)
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
				_undo(eng)
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
	elif _policy == "free_hold":
		_free_hold_rerolls(eng)
	else:
		_expert2_actions(eng)
	if _corehold and not _nohold_cores_off(eng):
		_core_hold(eng)


func _nohold_cores_off(eng: CombatEngine) -> bool:
	if RunState.anchor_id == "a_embers":
		return false   # Embers: a Held die comes back +0.50, so the bot parks dice every turn
	for id in HOLD_CORES:
		if RunState.owned_relic_ids.has(id) or String(RunState.run_rule) == id:
			return false
	return true


## S2: a Hold Core (c_steady_hold, c_kindle, rule_tundra) needs dice parked, and the plain expert never parks (Hold is only the
## boss-strike trick). With such a Core owned: after the rerolls, park the lowest-value non-cantrip dice up to stash_cap, but always
## keep 2 dice ready. A die carried from last turn (stash_carry) is used, not parked again, unless c_steady_hold allows repeat.
func _core_hold(eng: CombatEngine) -> void:
	var guard := 0
	while guard < 6:
		guard += 1
		var ready := _ready_units(eng)
		if ready.size() <= 2:
			return
		var pick: Unit = null
		var pv := 1000000
		# c_key_strike quest (Held die hits for 9+): park the BIGGEST die instead of the smallest.
		var big: bool = (RunState.owned_relic_ids.has("c_key_strike") and not CoreHooks.quest_done(eng, "c_key_strike")) or RunState.anchor_id == "a_embers"   # Embers also parks the biggest die (+0.50 next turn)
		for u in ready:
			if not eng.can_stash(u.uid):
				continue
			if RunState.anchor_id == "a_embers" and eng._in_bo(u):
				continue   # never break a SET to park (Shell and every SET bonus punish it); park the leftovers only
			var fv: int = eng._face_value(u, u.roll_face_index())
			if big:
				fv = -fv
			if fv < pv:
				pv = fv
				pick = u
		if pick == null or not eng.stash(pick.uid):
			return


## free_hold ("decent player, no thinking"): spend only FREE rerolls (never mana), keep the biggest part group, re-roll every other
## die; if nothing pairs, keep just the single best die. No Mat Tam, no Overcast, no Lieu. Dice moves then use the same beam plan as
## expert, so expert - free_hold isolates the PAID decisions (the v4 skill part) from the passive bag.
func _free_hold_rerolls(eng: CombatEngine) -> void:
	if _noreroll:
		return
	CoreHooks.mute += 1
	for round in 3:
		if eng.rerolls <= 0 or eng.reroll_total_turn >= eng.reroll_hard_cap():
			break
		var groups := {}
		for d in eng._bo_dice():
			var u: Unit = d
			if u.wild_slot >= 0 or u.cracked:
				continue
			var pt: int = u.roll_face_index()
			if not groups.has(pt):
				groups[pt] = []
			(groups[pt] as Array).append(u)
		var keep := {}
		var best_n := 0
		var best_sum := -1.0
		for pt in groups:
			var g: Array = groups[pt]
			var sm := 0.0
			for u in g:
				sm += maxf(0.0, eng._face_base(u, pt))
			if g.size() > best_n or (g.size() == best_n and sm > best_sum):
				best_n = g.size()
				best_sum = sm
				keep = {}
				if g.size() >= 2:
					for u in g:
						keep[(u as Unit).uid] = true
				else:
					var bu: Unit = g[0]
					for u in g:
						if eng._face_base(u, pt) > eng._face_base(bu, pt):
							bu = u
					keep[bu.uid] = true
		if best_n >= 5:
			break
		var cands: Array = []
		for u in eng.alive_party():
			var uu: Unit = u
			if uu.has_rolled() and not uu.roll_used() and not uu.held and not keep.has(uu.uid):
				cands.append(uu.uid)
		var ok_units: Array = eng._rerollable(cands)
		cands = []
		for u in ok_units:
			cands.append((u as Unit).uid)
		if cands.is_empty() or not eng.can_reroll(cands, false, 1) or eng.reroll_mana_cost(false, 1) > 0:
			break
		if not _mx_reroll(eng, cands, 1):
			break
	CoreHooks.mute -= 1


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


## Chance a rerolled die lands on one given part: cantrip faces resolve and re-roll, so a die only rests on its non-cantrip faces
## (1/5 with one Tai cantrip, 1/6 with none). Averaged over the dice in `uids`.
func _p_land(eng: CombatEngine, uids: Array) -> float:
	var tot := 0.0
	for uid in uids:
		var u: Unit = eng.by_uid(int(uid))
		var nc := 0
		for fi in 6:
			if not eng._has_kw(u.die[fi], "cantrip"):
				nc += 1
		tot += 1.0 / float(maxi(nc, 1))
	return tot / float(maxi(uids.size(), 1))


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
	var p_land := _e1_p if _e1_p > 0.0 else _p_land(eng, cands)
	var ev_safe := _hunt_ev(eng, best_n, a, k, p_land) - (0.0 if free else float(eng.reroll_mana_cost(false, 1)) * _e1_mana_lam)
	var ev_lieu := _hunt_ev(eng, best_n, a, k, p_land * (1.0 - crack_p)) - crack_p * float(k) * a * 0.5
	var rm := 1
	var ev := ev_safe
	if not free and not _abl.has("no_lieu") and eng.depth_stage >= 2 and ev_lieu > ev_safe:
		rm = 0
		ev = ev_lieu
	if ev < _e1_min_ev or not eng.can_reroll(cands, false, rm):
		return false
	if _trace_path != "":
		var h0 := _hand(eng)
		var t0 := _turn_value(eng)
		var okr := _mx_reroll(eng, cands, rm)
		_trace("HUNT_" + ("LIEU" if rm == 0 else "SAFE"), eng, h0, t0, "free=%s k=%d n=%d evL=%.1f evS=%.1f" % [str(free), k, best_n, ev_lieu, ev_safe])
		return okr
	return _mx_reroll(eng, cands, rm)


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
				_undo(eng)
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
		var okw := _mx_reroll(eng, weak, rm)
		_trace("WEAK_" + ("LIEU" if rm == 0 else "SAFE"), eng, h1, t1, "free=%s n=%d" % [str(eng.rerolls > 0), weak.size()])
		return okw
	return _mx_reroll(eng, weak, rm)


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
				_undo(eng)
				if g > best_g:
					best_g = g
					best = [u.uid, sl]
	if not best.is_empty():
		var h2 := _hand(eng)
		_mx_wild(eng, int(best[0]), int(best[1]))
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
		var gtot := 0.0
		for gp in eng.overcast_group_preview(u):
			gtot += float(gp["boosted"]) - float(gp["now"])
		if gtot <= 0.0:
			continue
		if eng.overcast(u.uid):
			var g := _turn_value(eng) - base
			_undo(eng)
			if g > best_g:
				best_g = g
				best = u.uid
	if best >= 0:
		var h3 := _hand(eng)
		_mx_overcast(eng, best)
		_trace("OVERCAST", eng, h3, base, "gainSeen=%.1f" % best_g)


# ================================================================ expert v2: decisions by sampled expected value
# One greedy loop per turn over {no action, reroll subset S in Safe / Lieu, Mat Tam (die, slot), Overcast die}. Each option is
# priced as  E[value after] - value now - mana spent * lambda(mana).  "value" is a cheap model of the turn (face values with the
# BO bag M, Nứt halving, per-type weights); rerolls are sampled (N draws from the bot's own rng, SAME draws for every option =
# common random numbers). The model uses the engine's own _face_base / bo_add100 / bo_cap100 / overcast_preview / preview_wild.

# Bot tuning params (override with --e2_*=..; set in run_batch). Reasons for the defaults:
#  e2_samples 16     : CRN draws per option; enough because every option reuses the same draws (the SE of a gain DIFFERENCE is small).
#  e2_min_gain 0.8   : an action must beat "do nothing" by ~1 value point (the model's noise floor); lower = twitchier bot.
#  e2_lam_lo/mid/hi  : value of one mana (in face-value points) when mana < 6 / < 10 / >= 10. GDD v4 and v4-decisions-pay say
#                      lambda 0.2-0.5; mana is only convertible to reroll/Overcast/active relics, so it is cheap when stocked.
#  e1_min_ev 1.0     : legacy ("expert_old") hunt threshold. e1_mana_lam 0.35: legacy mana price (was a hard 1.0).
#  e1_p              : legacy per-die chance to land on the wanted part; -1 = derive from the dice (1/(6 - cantrip faces)).
var _e2_samples := 16
var _e2_min_gain := 0.8
var _e2_lam := [0.5, 0.35, 0.25]
var _e1_min_ev := 1.0
var _e1_mana_lam := 0.35
var _e1_p := -1.0
const E2_TYPES_M := ["dmg", "shield", "heal", "poison"]
var _e2_tv := {}   # per-decision cache: foe hp, incoming


## Faces a die can come to rest on after a (re)roll: cantrip faces auto-use and re-roll (the draw must skip them).
func _non_cantrip_faces(eng: CombatEngine, u: Unit) -> Array:
	var r: Array = []
	for fi in 6:
		if not eng._has_kw(u.die[fi], "cantrip"):
			r.append(fi)
	if r.is_empty():
		r = [0, 1, 2, 3, 4, 5]
	return r


func _e2_lambda(m: int) -> float:
	return float(_e2_lam[2]) if m >= 10 else (float(_e2_lam[1]) if m >= 6 else float(_e2_lam[0]))


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
			"nc": _non_cantrip_faces(eng, u),
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
				for sidx in _e2_samples:
					var row: Array = []
					for i in ents.size():
						var ncf: Array = ents[i]["nc"]
						row.append([ncf[int(_brng.randf() * float(ncf.size())) % ncf.size()], _brng.randf()])
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
						opts.append({"gain": tot / float(_e2_samples) - base_roll - cost, "kind": "reroll", "a": sset, "b": rm})
		# ---- Mat Tam
		if not _abl.has("no_wild") and eng.depth_stage >= 2 and eng.wild_used < eng.wild_per_battle() and eng.mana >= eng.wild_cost():
			var wcost := _e2_mana_cost_val(eng.mana, eng.wild_cost())
			for i in ents.size():
				if not ents[i]["ready"] or int(ents[i]["wild"]) >= 0:
					continue
				for sl in 6:
					if sl == int(ents[i]["fi"]):
						continue
					if eng.wild_block_reason(int(ents[i]["uid"]), sl) != "":   # v4/MD: only a Set of 3 -> 4 is legal (need_set3 etc.)
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
				# v4/MD: Overcast powers the WHOLE Set -> value = sum over every member (type-weighted), engine says who is in it.
				var gsum := 0.0
				for gp in eng.overcast_group_preview(en["u"]):
					var gu := eng.by_uid(int(gp["uid"]))
					var gt := String(gu.current_face().get("type", "")) if gu != null else ""
					var w := 1.0 if gt == "dmg" else (0.7 if gt == "shield" else (0.6 if gt == "heal" else 1.3))
					gsum += w * (float(gp["boosted"]) - float(gp["now"]))
				opts.append({"gain": gsum - ocost, "kind": "oc", "a": i, "b": 0})
		opts.sort_custom(func(x, y): return float(x["gain"]) > float(y["gain"]))
		var done := false
		for o in opts:
			if float(o["gain"]) < _e2_min_gain:
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
					ok = _mx_reroll(eng, uids, int(o["b"]))
			elif kind == "wild":
				var uid := int(ents[int(o["a"])]["uid"])
				if eng.wild_block_reason(uid, int(o["b"])) == "":
					ok = _mx_wild(eng, uid, int(o["b"]))
			else:
				ok = _mx_overcast(eng, int(ents[int(o["a"])]["uid"]))
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
