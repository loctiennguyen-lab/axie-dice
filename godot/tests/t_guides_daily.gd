extends Node
## Gate for the two small systems ported together: the Daily Mission shard grant, and the
## SAMPLE TEAMS screen.
##
## WHAT IS ACTUALLY AT RISK
## ------------------------
##  1. **The daily granting more than once a day, or never.** It is called unconditionally at
##     every run end, so its whole correctness is the idempotence. Granting twice inflates the
##     economy quietly; granting never is a reward the player is told about and does not get.
##
##  2. **A sample team that cannot be used.** `GUIDES` is prose copied from the live build naming
##     real heroes. If a hero key in it does not exist in this port, the card renders — with
##     blank portraits and the raw key as a name — and "USE THIS TEAM" fills the roster with
##     unresolvable keys that build 0 HP units. Nothing throws at any point.
##
##  3. **A half-copied ARCH table.** Every guide points at an archetype for its name and colour.
##     A missing entry falls back to a default and reads as a styling choice rather than as
##     missing data.
##
## Run: godot --headless --path godot res://tests/t_guides_daily.tscn

## Every test in this file, by name. Listed rather than derived so that deleting a test is a
## visible edit here, not a silent drop in coverage.
const EXPECTED_TESTS: Array[String] = [
	"test_the_daily_grants_once_per_utc_day_and_not_again",
	"test_the_daily_is_granted_on_a_loss_as_well_as_a_win",
	"test_the_daily_survives_a_save_and_reload",
	"test_every_guide_names_heroes_and_an_archetype_that_exist",
	"test_the_arch_table_is_a_complete_copy",
	"test_the_guides_screen_renders_every_guide",
	"test_use_this_team_actually_reaches_the_menu",
]

var _failures: Array[String] = []
var _checks := 0
## Names of the test functions that ran to completion.
##
## WHY THIS EXISTS. A GDScript runtime error (a null node, a stale node path) ABORTS the running
## function and returns to the caller — the remaining assertions in it simply never run,
## `_failures` stays empty, and the file reports PASS. `t_vault` went green for a whole run that
## way, its biggest test having stopped at its second line; the only visible trace was the check
## count dropping, which nothing was watching. Every test records its own completion, and the
## verdict refuses to pass unless all of them did.
var _completed: Array[String] = []
## The RAW save file. This gate drives real `end_run()` calls, which bump `runs`, `xp` and
## `best` as well as the daily — restoring a hand-written list of fields leaves the rest
## inflated in the player's own save, and the list rots as end_run grows.
var _save_guard := SaveGuard.new()


func _ready() -> void:
	print("=== t_guides_daily: start ===")
	await get_tree().process_frame

	# MetaState is an autoload backed by the player's real save; borrow the whole file and put it
	# back byte for byte at the end.
	_save_guard.capture()

	test_the_daily_grants_once_per_utc_day_and_not_again()
	test_the_daily_is_granted_on_a_loss_as_well_as_a_win()
	test_the_daily_survives_a_save_and_reload()
	test_every_guide_names_heroes_and_an_archetype_that_exist()
	test_the_arch_table_is_a_complete_copy()
	await test_the_guides_screen_renders_every_guide()
	await test_use_this_team_actually_reaches_the_menu()

	_save_guard.restore()
	MainMenu.pending_team = []

	for name in EXPECTED_TESTS:
		if not _completed.has(name):
			_failures.append(("test '%s' did not run to completion — a runtime error aborted it "
				+ "part-way and every assertion after that point was skipped") % name)

	print("=== t_guides_daily: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_guides_daily: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_guides_daily: FAIL — %s" % f)
	get_tree().quit(1)


## Called as the LAST line of every test. Reaching it is the proof the test finished.
func _done(test_name: String) -> void:
	_completed.append(test_name)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


# ===========================================================================
# Daily Mission
# ===========================================================================

func test_the_daily_grants_once_per_utc_day_and_not_again() -> void:
	MetaState.daily_date = ""
	MetaState.shard_pool = 0

	_assert(MetaState.claim_daily_mission(),
		"the first claim of the day returned false — the player is told about a reward they "
		+ "never receive")
	_assert(MetaState.shard_pool == ContentDB.DAILY_MISSION_SHARD,
		"first claim granted %d shards, expected %d"
		% [MetaState.shard_pool, ContentDB.DAILY_MISSION_SHARD])
	_assert(MetaState.daily_date == MetaState.today_utc(),
		"the claim did not stamp today's date, so the next call will grant again")

	# The whole contract: called again, and again, it must do nothing. `end_run()` calls it on
	# every run end, so a player finishing four runs today reaches this path three times.
	for i in 3:
		_assert(not MetaState.claim_daily_mission(),
			"claim %d of the same day returned true — the daily is granting repeatedly" % (i + 2))
	_assert(MetaState.shard_pool == ContentDB.DAILY_MISSION_SHARD,
		"repeated claims inflated the pool to %d; it should still be %d"
		% [MetaState.shard_pool, ContentDB.DAILY_MISSION_SHARD])

	# A new day grants again.
	MetaState.daily_date = "1999-01-01"
	_assert(MetaState.claim_daily_mission(), "a claim on a new day was refused")
	_assert(MetaState.shard_pool == ContentDB.DAILY_MISSION_SHARD * 2,
		"the second day granted %d shards in total, expected %d"
		% [MetaState.shard_pool, ContentDB.DAILY_MISSION_SHARD * 2])

	# The date format has to be the one the DAILY SEED button uses, or the two features disagree
	# about when a day starts.
	var today := MetaState.today_utc()
	_assert(today.length() == 10 and today[4] == "-" and today[7] == "-",
		"today_utc() returned '%s', which is not 'YYYY-MM-DD'" % today)
	_done("test_the_daily_grants_once_per_utc_day_and_not_again")


## Run end, not run WIN. A daily tied to winning is a skill check, and the JS calls
## `claimDailyMission()` unconditionally from `onRunEnd()` (client.html:5447).
func test_the_daily_is_granted_on_a_loss_as_well_as_a_win() -> void:
	MetaState.daily_date = ""
	MetaState.shard_pool = 0
	RunState.start_new_run(31337, ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"short", 0, false)
	RunState.end_run(false)     # lost
	_assert(RunState.daily_mission_granted,
		"a lost run did not grant the daily — the reward is for showing up, not for winning")
	_assert(MetaState.shard_pool >= ContentDB.DAILY_MISSION_SHARD,
		"the shards did not reach the pool on a loss")

	# ...and the second run of the day must not report it again, or the result screen shows a
	# "+60" line for shards nobody received.
	RunState.start_new_run(31338, ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"short", 0, false)
	RunState.end_run(false)
	_assert(not RunState.daily_mission_granted,
		"the second run of the day reported the daily as granted — the result screen would show "
		+ "a +%d that did not happen" % ContentDB.DAILY_MISSION_SHARD)
	RunState.reset()
	_done("test_the_daily_is_granted_on_a_loss_as_well_as_a_win")


func test_the_daily_survives_a_save_and_reload() -> void:
	MetaState.daily_date = MetaState.today_utc()
	MetaState.save_to_disk()
	MetaState.daily_date = ""
	MetaState.load_from_disk()
	_assert(MetaState.daily_date == MetaState.today_utc(),
		"daily_date did not survive the save/load round trip — every restart would hand out "
		+ "another %d shards" % ContentDB.DAILY_MISSION_SHARD)
	_done("test_the_daily_survives_a_save_and_reload")


# ===========================================================================
# Sample teams
# ===========================================================================

func test_every_guide_names_heroes_and_an_archetype_that_exist() -> void:
	_assert(ContentDB.GUIDES.size() == 4,
		"%d guides, expected the 4 from src/data.js" % ContentDB.GUIDES.size())
	var ids := {}
	for g in ContentDB.GUIDES:
		var guide: Dictionary = g
		var id := str(guide.get("id", ""))
		_assert(not id.is_empty(), "a guide has no id")
		_assert(not ids.has(id), "two guides share the id '%s'" % id)
		ids[id] = true

		for field in ["n", "diff", "why", "arch"]:
			_assert(not str(guide.get(field, "")).is_empty(),
				"guide '%s' has an empty '%s'" % [id, field])
		_assert((guide.get("how", []) as Array).size() >= 3,
			"guide '%s' has only %d how-to lines" % [id, (guide.get("how", []) as Array).size()])

		_assert(ContentDB.ARCH.has(str(guide.get("arch", ""))),
			"guide '%s' points at archetype '%s', which is not in ARCH — the card would fall "
			% [id, guide.get("arch", "")] + "back to a default colour and read as a design choice")

		var team: Array = guide.get("team", [])
		_assert(team.size() == 5, "guide '%s' has %d heroes, expected 5" % [id, team.size()])
		for key in team:
			_assert(ContentDB.heroes.has(str(key)),
				"guide '%s' names hero '%s', which does not exist in this port. The card would "
				% [id, key] + "render with a blank portrait and the raw key as a name, and USE "
				+ "THIS TEAM would fill the roster with a 0 HP unit.")
	_done("test_every_guide_names_heroes_and_an_archetype_that_exist")


## The whole table, not only the four entries GUIDES happens to use. A lookup table copied
## halfway is one where the first caller to ask for a missing key gets a default instead of an
## error — and the missing keys are exactly the ones no test was looking at.
func test_the_arch_table_is_a_complete_copy() -> void:
	var expected := ["poison", "burn", "shield", "mana", "pierce", "crit", "growth", "summon",
		"aoe", "thorns"]
	_assert(ContentDB.ARCH.size() == expected.size(),
		"ARCH has %d entries, src/data.js has %d" % [ContentDB.ARCH.size(), expected.size()])
	for key in expected:
		_assert(ContentDB.ARCH.has(key), "ARCH is missing '%s'" % key)
		if not ContentDB.ARCH.has(key):
			continue
		var a: Dictionary = ContentDB.ARCH[key]
		for field in ["n", "ic", "c", "d"]:
			_assert(not str(a.get(field, "")).is_empty(),
				"ARCH['%s'] has an empty '%s'" % [key, field])
		_assert(str(a.get("c", "")).begins_with("#"),
			"ARCH['%s'].c is '%s', not a hex colour" % [key, a.get("c", "")])

	# The 2026-09-04 fix: aoe and thorns used to share ✷, which made two different archetypes
	# indistinguishable in the UI. Pinned so a re-copy from an older source cannot undo it.
	_assert(str((ContentDB.ARCH["aoe"] as Dictionary).get("ic", ""))
			!= str((ContentDB.ARCH["thorns"] as Dictionary).get("ic", "")),
		"aoe and thorns share an icon again — the UI cannot tell the two archetypes apart")
	_done("test_the_arch_table_is_a_complete_copy")


func test_the_guides_screen_renders_every_guide() -> void:
	var packed := load("res://scenes/guides/Guides.tscn") as PackedScene
	_assert(packed != null, "could not load Guides.tscn")
	if packed == null:
		return
	var screen := packed.instantiate()
	add_child(screen)
	await get_tree().process_frame

	for g in ContentDB.GUIDES:
		var guide: Dictionary = g
		var id := str(guide.get("id", ""))
		var card: Node = screen.find_child("Guide_" + id, true, false)
		_assert(card != null, "guide '%s' has no card on screen" % id)
		if card == null:
			continue
		var strip: Node = card.find_child("TeamStrip", true, false)
		_assert(strip != null and strip.get_child_count() == 5,
			"guide '%s' shows %d team slots, expected 5"
			% [id, (strip.get_child_count() if strip != null else -1)])
		_assert(card.find_child("UseButton", true, false) != null,
			"guide '%s' has no USE THIS TEAM button" % id)
		_assert(card.find_child("ArchLabel", true, false) != null,
			"guide '%s' shows no archetype label" % id)

	# UI rule, same sweep the Vault screen carries: nothing may print a raw null or NaN. Here the
	# realistic leak is a hero key rendering as its own key because the lookup missed.
	for node in screen.find_children("*", "Label", true, false):
		var text := (node as Label).text
		for leak in ["<NULL>", "NaN", "undefined"]:
			_assert(not text.contains(leak),
				"a Label on the Sample Teams screen reads '%s'" % text)
		_assert(not (text.length() > 4 and text.ends_with("1") and text == text.to_lower()
				and ContentDB.heroes.has(text)),
			"a Label shows the raw hero key '%s' instead of the hero's name" % text)

	screen.queue_free()
	_done("test_the_guides_screen_renders_every_guide")


## The hand-off. The button is on one scene and the team lands on another, so "it set a variable"
## is not enough — the menu has to actually come up holding that team.
func test_use_this_team_actually_reaches_the_menu() -> void:
	MainMenu.pending_team = []
	var screen := (load("res://scenes/guides/Guides.tscn") as PackedScene).instantiate()
	add_child(screen)
	await get_tree().process_frame

	var first: Dictionary = ContentDB.GUIDES[0]
	var card: Node = screen.find_child("Guide_" + str(first.get("id", "")), true, false)
	var use := card.find_child("UseButton", true, false) as Button
	_assert(use != null, "the first guide has no USE THIS TEAM button")
	if use == null:
		return

	# `hand_team_to_menu()`, not `_on_use_pressed()`. The button handler also changes the scene,
	# and changing the scene frees this test's own tree — the first version of this line called
	# the handler and the gate HUNG rather than failing, which is this project's worst failure
	# shape. The two were split for exactly this reason; see GuidesView.
	var want: Array = first.get("team", [])
	screen.hand_team_to_menu(first)
	_assert(MainMenu.pending_team.size() == want.size(),
		"the button handed over %d heroes, the guide lists %d"
		% [MainMenu.pending_team.size(), want.size()])
	for i in mini(MainMenu.pending_team.size(), want.size()):
		_assert(MainMenu.pending_team[i] == str(want[i]),
			"slot %d handed over '%s', the guide says '%s'"
			% [i, MainMenu.pending_team[i], str(want[i])])
	screen.queue_free()

	# The menu must pick it up, and must CLEAR it — otherwise a player who returns to the menu
	# later has their own edited team silently replaced by a guide they clicked once.
	var menu := (load("res://scenes/main_menu/MainMenu.tscn") as PackedScene).instantiate()
	add_child(menu)
	await get_tree().process_frame
	_assert(menu._team_selection.size() == want.size(),
		"the menu built a team of %d from a hand-off of %d"
		% [menu._team_selection.size(), want.size()])
	for i in mini(menu._team_selection.size(), want.size()):
		_assert(menu._team_selection[i] == str(want[i]),
			"the menu slot %d is '%s', the guide says '%s'"
			% [i, menu._team_selection[i], str(want[i])])
	_assert(MainMenu.pending_team.is_empty(),
		"the hand-off was not cleared after being consumed — the next visit to the menu would "
		+ "overwrite whatever the player had changed since")
	menu.queue_free()
	_done("test_use_this_team_actually_reaches_the_menu")

