extends Node
## Season Echo Box (lane E, 19/10): pool separation from the normal box, Seasonal tab on the real
## EchoBox.open_season, per-tier progress, milestones + title grant, daily cap, pity, MetaState save.
## Own state via SaveGuard; no network.

const _Econ := preload("res://scripts/meta/economy_db.gd")
var _fail := 0
var _n := 0
var _guard := SaveGuard.new()


func _ok(c: bool, msg: String) -> void:
	_n += 1
	if not c:
		_fail += 1
		print("FAIL: ", msg)


func _ready() -> void:
	_guard.capture()
	await _run()
	_guard.restore()
	print("t_season_box: %d checks, %d failed" % [_n, _fail])
	print("PASS" if _fail == 0 else "FAIL")
	get_tree().quit(1 if _fail > 0 else 0)


func _run() -> void:
	var cfg := EchoBox.season_cfg()
	_ok(EchoBox.season_enabled(), "season box enabled")
	# pool separation
	var season_ids: Array = []
	for t in cfg.items:
		season_ids.append_array(cfg.items[t])
	season_ids.append("die_m_moon")   # 40-pull exclusive
	_ok((cfg.items.epic as Array).size() == 6 and (cfg.items.legendary as Array).size() == 3 and (cfg.items.mythic as Array).size() == 2, "11 season items 6/3/2")
	var normal: Dictionary = (_Econ.get_table("echobox").boxes.normal)
	var counts := {}
	for r in normal.art_map:
		var arts: Array = normal.art_map[r]
		counts[r] = arts.size()
		_ok(arts.size() >= 1, "normal tier %s has art" % r)
		for a in arts:
			_ok(not season_ids.has(a), "normal pool %s has no season item %s" % [r, a])
	print("distinct art per tier: ", counts)
	# season items live in art_map only: none may be in a normal tier, and every tier keeps >= 2 art ids
	for r in normal.art_map:
		_ok((normal.art_map[r] as Array).size() >= 2, "normal tier %s keeps >= 2 art ids" % r)
	# titles
	for k in ["title_s1_echo", "title_s1_lunar40", "title_s1_complete"]:
		_ok(String(cfg.titles.get(k, "")) != "" and EchoBox.season_owned_id(k).begins_with("title:"), "title defined: " + k)
	# real MetaState: open, cap, milestones, titles equip, save
	MetaState.tickets = {"normal": 2000, "season": 0}
	MetaState.season_box = {}
	MetaState.cosmetics_owned = []
	MetaState.echobox_pity = {}
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var opened := 0
	var d := 0
	var granted: Array = []   # every milestone reward id reported by open_season, across all pulls
	var complete_n := 0
	var complete_at := 0
	# open until the set is complete AND 40 pulls are in (precondition for the 40-pull milestone), bounded
	while opened < 200 and (opened < 40 or not (EchoBox.season_state(MetaState)["milestones"] as Array).has("complete")):
		var r := EchoBox.open_season(MetaState, rng, "2026-11-%02d" % (3 + d))
		if not r.ok:
			if r.reason == "daily_cap":
				d += 1
				continue
			_ok(false, "unexpected reason " + String(r.reason))
			break
		opened += 1
		granted.append_array(r.milestones)
		if r.complete:
			complete_n += 1
			if complete_at == 0:
				complete_at = opened
	var ms: Array = EchoBox.season_state(MetaState)["milestones"]
	_ok(ms.has("complete") and opened >= 40 and opened < 200, "full set and >= 40 pulls reached (%d, complete at %d)" % [opened, complete_at])
	var inv: Array = MetaState.cosmetics_owned
	_ok(inv.has("title:ECHO WALKER") and inv.has("title:LUNAR ECHO MASTER") and inv.has("die_m_moon") and inv.has("title:MOONBOUND"), "milestone rewards granted (titles as title:<NAME>)")
	_ok(complete_n == 1 and _unique(granted) and granted.has("title_s1_echo") and granted.has("die_m_moon"), "each milestone reported once (complete %d, %s)" % [complete_n, granted])
	_ok(_unique(ms) and ms.size() == 3, "milestones list has no duplicates: %s" % [ms])
	_ok(_unique(inv), "cosmetics_owned has no duplicates (titles included)")
	# re-open after the set is complete and every milestone claimed: nothing granted twice
	var before_inv: Array = inv.duplicate()
	for i in 6:
		var r2 := EchoBox.open_season(MetaState, rng, "2026-12-%02d" % (1 + i / 8))
		_ok(r2.ok and (r2.milestones as Array).is_empty() and not r2.complete, "re-open after claim grants no milestone")
	_ok(_unique(MetaState.cosmetics_owned) and MetaState.cosmetics_owned.size() == before_inv.size(), "re-open after complete adds no cosmetics / duplicates")
	_ok(_unique(EchoBox.season_state(MetaState)["milestones"]), "milestones still unique after re-open")
	_ok(TitleNames.owned(MetaState.cosmetics_owned).has("title:ECHO WALKER") and MetaState.equip_title("title:ECHO WALKER") == "", "TitleNames sees and equips the season title")
	_ok(TitleNames.display("title:LUNAR ECHO MASTER") == "Lunar Echo Master", "title display name")
	# round trip through the save: counters, day, day_pulls, owned, opens, milestones
	var snap := EchoBox.season_state(MetaState)
	var inv_snap: Array = MetaState.cosmetics_owned.duplicate()
	MetaState.reload_from_store()
	var back := EchoBox.season_state(MetaState)
	for k in ["c_epic", "c_legendary", "c_mythic", "day", "day_pulls", "opens"]:
		_ok(back[k] == snap[k], "%s survives reload (%s)" % [k, snap[k]])
	_ok(int(snap["opens"]) == opened + 6 and String(snap["day"]) != "" and int(snap["day_pulls"]) > 0, "snapshot is not empty")
	_ok((back["owned"] as Array).size() == 11 and _same_set(back["owned"], snap["owned"]), "owned survives reload")
	_ok(_same_set(back["milestones"], snap["milestones"]), "milestones survive reload")
	_ok(_same_set(MetaState.cosmetics_owned, inv_snap) and _unique(MetaState.cosmetics_owned), "cosmetics_owned survives reload without duplicates")
	# pity: at the cap the hit is guaranteed whatever the rng says, and the counter resets
	_ok(EchoBox.season_hit_prob(40, 40, 2.0) == 1.0 and absf(EchoBox.season_hit_prob(31, 40, 2.0) - 61.0 / (1600.0 - 900.0)) < 1e-9, "p(31/40)=8.7%, certain at 40")
	for t in ["mythic", "legendary", "epic"]:
		var cap := EchoBox.season_cap(t, false)
		var st := {"opens": 0, "c_epic": 0, "c_legendary": 0, "c_mythic": 0, "owned": [], "milestones": [], "day": "", "day_pulls": 0}
		st["c_" + t] = cap - 1
		# the other tiers sit at 0 so only `t` is due
		MetaState.tickets = {"normal": 100, "season": 0}
		MetaState.cosmetics_owned = []
		MetaState.season_box = {"s1": st}
		var pr := RandomNumberGenerator.new()
		pr.seed = 77
		var hit := EchoBox.open_season(MetaState, pr, "2026-11-03")
		_ok(hit.ok and hit.kind == "cosmetic" and hit.tier == t and not hit.duplicate, "pity: %s guaranteed at cap %d (got %s/%s)" % [t, cap, hit.get("kind"), hit.get("tier")])
		_ok(int(EchoBox.season_state(MetaState)["c_" + t]) == 0, "pity: c_%s resets after the hit" % t)
	# UI
	MetaState.tickets = {"normal": 60, "season": 0}
	MetaState.season_box = {}
	MetaState.cosmetics_owned = []
	var s: EchoBoxScreen = load("res://scenes/echobox/EchoBoxScreen.tscn").instantiate()
	s.use_account = false
	s.remote_on = false
	s.no_scene_change = true
	s.instant = true
	s.season_confirmed = false
	add_child(s)
	await get_tree().process_frame
	s.select_tab("seasonal")
	await get_tree().process_frame
	_ok(s.find_child("SeasonOpen", true, false) != null and s.find_child("SeasonOpen", true, false).find_child("CostChip", true, false) != null, "Open button with ticket cost chip")
	_ok(s.find_child("Open1", true, false) == null and s.find_child("PullsLeft", true, false) != null, "no normal Open on season tab, pulls left shown")
	_ok((s.find_child("PullsLeft", true, false) as Label).text.contains("8 / 8"), "pulls left 8 / 8")
	_ok(s.find_child("SeasonGrid", true, false).get_child_count() == 11, "11-item pool grid")
	for t in ["mythic", "legendary", "epic"]:
		_ok(s.find_child("Season_" + t, true, false) != null, "progress bar " + t)
	_ok(s.find_child("Milestone_12", true, false) != null and s.find_child("Milestone_40", true, false) != null and s.find_child("Milestone_complete", true, false) != null, "milestone list")
	# first pull confirms, nothing spent until Open
	s._on_season_open(1)
	await get_tree().process_frame
	_ok(s.find_child("ConfirmSeason", true, false) != null and s.tickets() == 60, "first season pull confirms; nothing spent yet")
	s.close_modal()
	# confirming once covers the rest of the play session, also on a fresh visit to the screen
	s.season_confirmed = true
	var s2: EchoBoxScreen = load("res://scenes/echobox/EchoBoxScreen.tscn").instantiate()
	_ok(s2.season_confirmed, "confirm is per play session: a new screen visit does not ask again")
	s2.free()
	s.rng.seed = 3
	var out: Array = await s.pull(1)
	_ok(out.size() == 1 and s.tickets() >= 55 and s.tickets() <= 55 + 8, "one pull costs 5 tickets (dup refund aside)")
	_ok(int(EchoBox.season_state(MetaState)["opens"]) == 1, "season state counts the open")
	s.close_modal()
	var out10: Array = await s.pull(7)
	_ok(out10.size() == 7 and s.season_pulls_left() == 0, "8 pulls reach the daily cap")
	s.close_modal()
	await get_tree().process_frame
	_ok((s.find_child("SeasonOpen", true, false) as Button).text.begins_with("8 of 8"), "cap reason inside the disabled button")
	_ok((await s.pull(1)).is_empty(), "no pull past the daily cap")
	s.queue_free()
	# Store text still true: season items are not in the normal pool
	_ok(not (_Econ.get_table("echobox").boxes.normal.art_map as Dictionary).values().any(func(a): return (a as Array).has("fx_m_lunar")), "fx_m_lunar not in normal pool")


func _unique(a: Array) -> bool:
	var seen := {}
	for x in a:
		if seen.has(x):
			return false
		seen[x] = true
	return true


func _same_set(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for x in a:
		if not b.has(x):
			return false
	return true
