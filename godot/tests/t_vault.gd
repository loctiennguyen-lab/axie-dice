extends Node
## Gate for the Vault store (Import Axie, step (c)) — `MetaState.vault_*` and the ranked block.
##
## WHAT IS ACTUALLY AT RISK HERE
## -----------------------------
##  1. **A ranked run played with a Vault Axie.** A vault die exists only in this player's local
##     save, so `api/submit-run.js` cannot rebuild it and cannot verify the score; the live server
##     refuses such a submission with HTTP 400 (:87). If the port lets one through, the failure is
##     not a crash — it is a leaderboard entry nobody can check. This is the single most important
##     assertion in the file.
##
##  2. **Numbers coming back from JSON as floats.** A vault record is a nested pile of numbers
##     that all mean something: a face value read back as `7.0` prints "7.0" on a die card, a tier
##     of `1.0` fails `== 1`, and an `axie_id` of `123.0` no longer matches the `vault_123` key it
##     was filed under. This project has already paid twice for exactly this (five growth sources
##     writing string keys nobody read; the part_faces coherence table). So the round trip is
##     tested through a real file, not through the in-memory array.
##
##  3. **A full vault losing an Axie quietly.** JS refuses the import and says so. A silent LRU
##     trim is a bug the player only discovers later, by an Axie being gone.
##
## Run: godot --headless --path godot res://tests/t_vault.tscn

const GOLDEN_REL := "../third_party/godot-axie-mixer-3d-main/tests/goldens/sample_axies.json"

## Every test in this file, by name. Listed rather than derived so that deleting a test is a
## visible edit here, not a silent drop in coverage.
const EXPECTED_TESTS: Array[String] = [
	"test_a_die_becomes_a_vault_entry_with_a_schema_and_a_stable_key",
	"test_reimporting_the_same_axie_updates_instead_of_duplicating",
	"test_a_full_vault_refuses_the_next_import_and_says_why",
	"test_removing_an_axie_also_unregisters_its_hero_key",
	"test_a_vault_axie_is_playable_as_a_tier_one_hero",
	"test_a_stale_record_is_flagged_and_never_becomes_playable",
	"test_a_ranked_run_cannot_be_started_with_a_vault_pick",
	"test_numbers_survive_the_json_round_trip",
	"test_a_payload_that_cannot_be_re_derived_is_refused",
	"test_the_vault_screen_shows_what_the_store_holds",
	"test_the_screen_marks_a_stale_record_instead_of_hiding_it",
	"test_no_row_leaks_a_null_or_nan_into_its_text",
	"test_no_test_writes_to_the_real_save_without_a_save_guard",
]

var _failures: Array[String] = []
var _checks := 0
## Names of the test functions that ran to completion.
##
## WHY THIS EXISTS. A GDScript runtime error (a null node, a bad path) ABORTS the running function
## and returns to the caller — the remaining assertions in it simply never run, `_failures` stays
## empty, and the file reports PASS. That is exactly how this gate went green while its biggest
## test had stopped at its second line: the only visible trace was the check count dropping from
## 262 to 249, which nothing was watching. Every test below records its own completion, and
## `_ready()` refuses to pass unless every one of them did.
var _completed: Array[String] = []
## The RAW save file, not just the in-memory vault.
##
## The first version restored `MetaState.vault` in memory and stopped there — but this gate calls
## `save_to_disk()` with twenty fixture Axies in it, so the FILE was left holding them. Nothing
## failed; the player simply found a stranger's vault the next time the game booted. Put the file
## back exactly as it was.
var _save_guard := SaveGuard.new()


func _ready() -> void:
	print("=== t_vault: start ===")
	await get_tree().process_frame

	# This test writes to the real MetaState (it is an autoload; there is no second instance to
	# borrow). Take the whole save file, and put it back byte for byte at the end.
	_save_guard.capture()
	MetaState.vault.clear()

	test_a_die_becomes_a_vault_entry_with_a_schema_and_a_stable_key()
	test_reimporting_the_same_axie_updates_instead_of_duplicating()
	test_a_full_vault_refuses_the_next_import_and_says_why()
	test_removing_an_axie_also_unregisters_its_hero_key()
	test_a_vault_axie_is_playable_as_a_tier_one_hero()
	test_a_stale_record_is_flagged_and_never_becomes_playable()
	test_a_ranked_run_cannot_be_started_with_a_vault_pick()
	test_numbers_survive_the_json_round_trip()
	test_a_payload_that_cannot_be_re_derived_is_refused()
	await test_the_vault_screen_shows_what_the_store_holds()
	await test_the_screen_marks_a_stale_record_instead_of_hiding_it()
	await test_no_row_leaks_a_null_or_nan_into_its_text()
	test_no_test_writes_to_the_real_save_without_a_save_guard()

	_save_guard.restore()
	for k in ContentDB.heroes.keys():
		if MetaState.is_vault_key(String(k)):
			ContentDB.heroes.erase(k)
	MetaState.ensure_vault_heroes()

	for name in EXPECTED_TESTS:
		if not _completed.has(name):
			_failures.append(("test '%s' did not run to completion — a runtime error aborted it "
				+ "part-way and every assertion after that point was skipped") % name)

	print("=== t_vault: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_vault: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_vault: FAIL — %s" % f)
	get_tree().quit(1)


## Called as the LAST line of every test. Reaching it is the proof the test finished.
func _done(test_name: String) -> void:
	_completed.append(test_name)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


## A raw API payload, the shape `vault_import()` and `AxieToDie.build()` both read. Built from
## real part keys rather than a hand-written die: synthesising a finished die would test the store
## against my idea of a die instead of the one `AxieToDie` actually produces.
func _payload(id: String, part_class: String = "plant") -> Dictionary:
	var parts: Array = []
	for slot in ["mouth", "horn", "back", "tail", "eyes", "ears"]:
		parts.append({"id": "%s-%s" % [part_class, slot], "name": "Test %s" % slot,
			"class": part_class, "type": slot, "specialGenes": null})
	return {"id": id, "class": part_class, "parts": parts, "genes": "0x1234"}


func test_a_die_becomes_a_vault_entry_with_a_schema_and_a_stable_key() -> void:
	MetaState.vault.clear()
	var res := MetaState.vault_import(_payload("123"))
	_assert(bool(res["ok"]), "a valid payload was refused: %s" % res.get("err", ""))
	_assert(not bool(res["updated"]), "a first import reported itself as an update")
	_assert(MetaState.vault.size() == 1, "vault holds %d entries after one import"
		% MetaState.vault.size())

	var entry: Dictionary = MetaState.vault[0]
	_assert(int(entry.get("schema", 0)) == MetaState.VAULT_SCHEMA,
		"the entry was stored with schema %s, expected %d — an unstamped record reads as stale "
		% [str(entry.get("schema", "-")), MetaState.VAULT_SCHEMA]
		+ "forever and can never be played")
	_assert(MetaState.vault_key(entry) == "vault_123",
		"key is '%s', expected 'vault_123'" % MetaState.vault_key(entry))
	_assert(typeof(entry.get("axie_id")) == TYPE_STRING,
		"axie_id was stored as %s, not a String — it will not survive a JSON round trip as the "
		% type_string(typeof(entry.get("axie_id"))) + "same value it was filed under")
	_assert(not MetaState.vault_stale(entry), "a freshly imported record reports as stale")
	_assert(MetaState.vault_index_of("123") == 0, "vault_index_of() cannot find what it stored")
	_assert(MetaState.vault_index_of(123) == 0,
		"vault_index_of() fails on a numeric id — the API returns ids as numbers, so a lookup "
		+ "with the value the API gave would miss the record it created")

	# The part manifest has to ride along: without it a re-derive is impossible, which is the
	# whole reason a schema-1 record cannot be migrated in place.
	var parts: Array = entry.get("parts", [])
	_assert(parts.size() == 6, "%d parts stored beside the die, expected 6" % parts.size())
	_assert(str((parts[0] as Dictionary).get("name", "")) != "",
		"the stored part manifest lost its names")
	_done("test_a_die_becomes_a_vault_entry_with_a_schema_and_a_stable_key")


func test_reimporting_the_same_axie_updates_instead_of_duplicating() -> void:
	MetaState.vault.clear()
	MetaState.vault_import(_payload("777", "plant"))
	# The same Axie after its owner changed parts in the real world: same id, different class.
	var res := MetaState.vault_import(_payload("777", "aqua"))
	_assert(bool(res["ok"]) and bool(res["updated"]),
		"re-importing an owned id did not report as an update")
	_assert(MetaState.vault.size() == 1,
		"re-importing id 777 produced %d records — two records would both claim the key "
		% MetaState.vault.size() + "'vault_777' and one of them would silently win")
	_assert(String((MetaState.vault[0] as Dictionary).get("cls", "")) == "aqua",
		"the update kept the OLD record — a re-scan that changes nothing is worse than no "
		+ "re-scan, because the player believes it worked")
	_done("test_reimporting_the_same_axie_updates_instead_of_duplicating")


func test_a_full_vault_refuses_the_next_import_and_says_why() -> void:
	MetaState.vault.clear()
	for i in MetaState.VAULT_MAX:
		MetaState.vault_import(_payload(str(9000 + i)))
	_assert(MetaState.vault.size() == MetaState.VAULT_MAX,
		"filling to VAULT_MAX produced %d records" % MetaState.vault.size())
	_assert(MetaState.vault_is_full(), "a vault at VAULT_MAX does not report itself full")

	var res := MetaState.vault_import(_payload("8888"))
	_assert(not bool(res["ok"]), "a full vault accepted a 21st Axie")
	_assert(str(res["err"]) == "vault_full",
		"a full vault refused with err '%s', expected 'vault_full' — the screen branches on this "
		% str(res["err"]) + "exact string to choose its message")
	_assert(MetaState.vault.size() == MetaState.VAULT_MAX,
		"the refused import still changed the vault (%d records) — something was trimmed to make "
		% MetaState.vault.size() + "room, which is the silent data loss JS explicitly avoids")
	_assert(MetaState.vault_index_of("9000") >= 0,
		"the oldest entry is gone — a full vault dropped an Axie the player chose to keep")

	# An id already stored must still be updatable when the vault is full: it takes no new slot.
	var upd := MetaState.vault_import(_payload("9005", "bird"))
	_assert(bool(upd["ok"]) and bool(upd["updated"]),
		"a full vault refused to UPDATE a record it already holds, which needs no free slot")
	_done("test_a_full_vault_refuses_the_next_import_and_says_why")


func test_removing_an_axie_also_unregisters_its_hero_key() -> void:
	MetaState.vault.clear()
	MetaState.vault_import(_payload("4154"))
	_assert(ContentDB.heroes.has("vault_4154"),
		"importing did not register the hero key — a run started with this Axie would resolve "
		+ "an empty hero def and build a 0 HP unit")
	_assert(MetaState.vault_remove("4154"), "vault_remove() reported failure on a stored id")
	_assert(MetaState.vault.is_empty(), "the record survived removal")
	_assert(not ContentDB.heroes.has("vault_4154"),
		"the hero key outlived the record — the Axie is gone from the vault but still pickable")
	_assert(not MetaState.vault_remove("4154"), "removing a missing id reported success")
	_done("test_removing_an_axie_also_unregisters_its_hero_key")


## The bridge that makes the whole feature cheap: a vault entry is shaped like a hero record, so
## the combat engine needs no change at all. If that shape ever drifts, it drifts silently — a
## missing key reads as a default, not as an error.
func test_a_vault_axie_is_playable_as_a_tier_one_hero() -> void:
	MetaState.vault.clear()
	MetaState.vault_import(_payload("555"))
	var def: Dictionary = ContentDB.heroes.get("vault_555", {})
	_assert(not def.is_empty(), "no hero def registered for vault_555")
	for field in ["n", "cls", "tier", "max_hp", "die"]:
		_assert(def.has(field),
			"the registered hero def has no '%s' — RunState.start_new_run() reads it and would "
			% field + "fall back to a default without saying anything")
	_assert(int(def.get("tier", 0)) == 1,
		"a vault Axie registered at tier %d; rule spec §6 says imports stay at form tier 1"
		% int(def.get("tier", 0)))
	_assert(int(def.get("max_hp", 0)) > 0, "the registered hero has no HP")
	_assert((def.get("die", []) as Array).size() == 6,
		"the registered hero's die has %d faces" % (def.get("die", []) as Array).size())

	RunState.start_new_run(4242, ["vault_555", "plant1", "beast1", "aqua1", "bird1"],
		"short", 0, false)
	var member: Dictionary = RunState.roster[0]
	_assert(String(member.get("hero_key", "")) == "vault_555", "the roster lost the vault key")
	_assert(int(member.get("max_hp", 0)) == int(def.get("max_hp", 0)),
		"the roster built the vault Axie with %d HP, the record says %d — 0 here is what an "
		% [int(member.get("max_hp", 0)), int(def.get("max_hp", 0))]
		+ "unresolved hero key looks like")
	RunState.reset()
	_done("test_a_vault_axie_is_playable_as_a_tier_one_hero")


func test_a_stale_record_is_flagged_and_never_becomes_playable() -> void:
	MetaState.vault.clear()
	var old := AxieToDie.build(_payload("321"))
	old["axie_id"] = "321"
	old["schema"] = 1                      # written under the v1 face rules
	old.erase("parts")                     # ...which is why it cannot be migrated in place
	MetaState.vault.append(old)
	MetaState.ensure_vault_heroes()

	_assert(MetaState.vault_stale(old), "a schema-1 record does not report as stale")
	_assert(not ContentDB.heroes.has("vault_321"),
		"a stale record was registered as playable — its die was built under last version's "
		+ "rules, and nothing downstream would ever notice")
	_assert(MetaState.vault_stale({}), "an empty record does not report as stale")

	# Re-importing it is the migration, and it must clear the flag.
	MetaState.vault_import(_payload("321"))
	_assert(not MetaState.vault_stale(MetaState.vault_entry("321")),
		"re-importing a stale record left it stale — the RE-SCAN button would do nothing")
	_assert(ContentDB.heroes.has("vault_321"), "the re-scanned Axie is still not playable")
	_done("test_a_stale_record_is_flagged_and_never_becomes_playable")


## The one that matters most — see the file header.
func test_a_ranked_run_cannot_be_started_with_a_vault_pick() -> void:
	MetaState.vault.clear()
	MetaState.vault_import(_payload("999"))

	_assert(MetaState.team_has_vault_pick(["plant1", "vault_999", "beast1"]),
		"team_has_vault_pick() missed a vault key")
	_assert(not MetaState.team_has_vault_pick(["plant1", "beast1", "aqua1"]),
		"team_has_vault_pick() flagged an all-starter team")

	RunState.start_new_run(1, ["vault_999", "plant1", "beast1", "aqua1", "bird1"], "short", 0, true)
	_assert(not RunState.ranked,
		"A RANKED RUN WAS STARTED WITH A VAULT AXIE. The server cannot rebuild a vault die from "
		+ "a replay, so this produces a leaderboard score that cannot be verified "
		+ "(api/submit-run.js:87 refuses it with HTTP 400).")
	RunState.reset()

	# ...and the downgrade must not also strip the player's meta bonuses: the run is unranked, so
	# it is entitled to them. Granting neither would be the worst of both outcomes.
	MetaState.unlocks.append("u_reroll")
	RunState.start_new_run(1, ["vault_999", "plant1", "beast1", "aqua1", "bird1"], "short", 0, true)
	_assert(RunState.bonus_reroll > 0,
		"the downgraded run got no meta bonuses either — it is not ranked, so there is no reason "
		+ "to withhold them")
	MetaState.unlocks.erase("u_reroll")
	RunState.reset()

	# An all-starter team is still allowed to be ranked; the guard must not block everything.
	RunState.start_new_run(1, ["plant1", "beast1", "aqua1", "bird1", "bug1"], "short", 0, true)
	_assert(RunState.ranked, "an all-starter team was refused a ranked run")
	RunState.reset()
	_done("test_a_ranked_run_cannot_be_started_with_a_vault_pick")


## Through a real file, because the failure is in the serialisation, not in the code above it.
func test_numbers_survive_the_json_round_trip() -> void:
	MetaState.vault.clear()
	MetaState.vault_import(_payload("123"))
	var before: Dictionary = MetaState.vault[0].duplicate(true)
	MetaState.save_to_disk()

	MetaState.vault.clear()
	MetaState.load_from_disk()
	_assert(MetaState.vault.size() == 1, "the vault did not come back from disk")
	if MetaState.vault.is_empty():
		return
	var after: Dictionary = MetaState.vault[0]

	_assert(typeof(after.get("axie_id")) == TYPE_STRING,
		"axie_id came back as %s" % type_string(typeof(after.get("axie_id"))))
	_assert(MetaState.vault_index_of("123") == 0,
		"the reloaded record can no longer be found by its own id — it is in the save and "
		+ "invisible to every lookup")
	_assert(MetaState.vault_key(after) == MetaState.vault_key(before),
		"the hero key changed across a save/load: '%s' -> '%s'" % [
			MetaState.vault_key(before), MetaState.vault_key(after)])
	for field in ["schema", "tier", "max_hp", "gene_tier", "purity"]:
		_assert(typeof(after.get(field)) == TYPE_INT,
			"'%s' came back as %s, not an int — it prints with a '.0' and fails every "
			% [field, type_string(typeof(after.get(field)))] + "equality test against a literal")
		_assert(int(after.get(field, -1)) == int(before.get(field, -2)),
			"'%s' changed value across the round trip: %s -> %s" % [
				field, str(before.get(field)), str(after.get(field))])

	var faces_before: Array = before.get("die", [])
	var faces_after: Array = after.get("die", [])
	_assert(faces_after.size() == faces_before.size(),
		"the die lost faces on reload: %d -> %d" % [faces_before.size(), faces_after.size()])
	for i in mini(faces_before.size(), faces_after.size()):
		var fb: Dictionary = faces_before[i]
		var fa: Dictionary = faces_after[i]
		_assert(typeof(fa.get("v")) == TYPE_INT,
			"face %d value came back as %s — it renders as '7.0' on the die card"
			% [i, type_string(typeof(fa.get("v")))])
		_assert(int(fa.get("v", -1)) == int(fb.get("v", -2)),
			"face %d value changed: %s -> %s" % [i, str(fb.get("v")), str(fa.get("v"))])
		_assert(str(fa.get("t", "")) == str(fb.get("t", "")),
			"face %d type changed: '%s' -> '%s'" % [i, str(fb.get("t")), str(fa.get("t"))])
		_assert(str(fa.get("p", "")) == str(fb.get("p", "")),
			"face %d part changed: '%s' -> '%s'" % [i, str(fb.get("p")), str(fa.get("p"))])

	# And the reloaded record has to be playable without anyone visiting a menu first — the JS
	# bug this port deliberately does not reproduce (client.html:3256).
	MetaState.ensure_vault_heroes()
	_assert(ContentDB.heroes.has("vault_123"),
		"a vault Axie loaded from disk is not registered until some screen renders it — CONTINUE "
		+ "RUN goes straight into combat and would resume with an unresolvable hero key")
	_done("test_numbers_survive_the_json_round_trip")


## Regression test for a hole in this store's FIRST API, found by this file before any screen
## used it. `vault_add(die, parts = [])` took the resolved die and its manifest as two separate
## arguments: a caller could pair Axie A's die with Axie B's parts, and a caller who simply left
## the second argument off wrote a record with no manifest at all — born in the un-re-derivable
## state that forces a re-scan, silently, at import time. The signature is now one payload in.
func test_a_payload_that_cannot_be_re_derived_is_refused() -> void:
	MetaState.vault.clear()

	var no_parts := _payload("4321")
	no_parts["parts"] = []
	var res := MetaState.vault_import(no_parts)
	_assert(not bool(res["ok"]),
		"an Axie with no part manifest was stored — its die can never be rebuilt, so it is a "
		+ "schema-1 record wearing a schema-2 stamp")
	_assert(str(res["err"]) == "invalid_axie_data",
		"refused with err '%s', expected 'invalid_axie_data'" % str(res["err"]))
	_assert(MetaState.vault.is_empty(), "the refused import still left a record behind")

	_assert(not bool(MetaState.vault_import({})["ok"]), "an empty payload was accepted")
	var no_id := _payload("")
	_assert(not bool(MetaState.vault_import(no_id)["ok"]),
		"a payload with no id was accepted — its key would be the bare prefix 'vault_', which "
		+ "every other id-less record would also claim")
	_assert(MetaState.vault.is_empty(), "a junk payload left a record behind")
	_done("test_a_payload_that_cannot_be_re_derived_is_refused")


## The screen. Kept separate from the store tests above on purpose: those prove the numbers are
## right, this proves the screen is asking for them. Both are needed — 74 relics once sat wired to
## hooks that did not exist while the whole suite stayed green.
func test_the_vault_screen_shows_what_the_store_holds() -> void:
	MetaState.vault.clear()
	MetaState.vault_import(_payload("123", "plant"))
	MetaState.vault_import(_payload("456", "aqua"))

	var packed := load("res://scenes/vault/Vault.tscn") as PackedScene
	_assert(packed != null, "could not load Vault.tscn")
	if packed == null:
		return
	var screen := packed.instantiate()
	add_child(screen)
	await get_tree().process_frame

	# `find_child`, not a hardcoded node path. The first version wrote "Scroll/ContentRoot"; the
	# screen later grew a sticky header/footer and the path became "Frame/Scroll/ContentRoot", so
	# `get_node()` returned null and this whole test ABORTED — silently, still reporting PASS.
	# See the completion guard in `_ready()`.
	_assert(screen.find_child("Row_123", true, false) != null,
		"the screen has no row for Axie 123 — it is in the store and invisible on screen")
	_assert(screen.find_child("Row_456", true, false) != null, "no row for Axie 456")

	# Every row must carry a preview fed from the record's own genes, a die readout, and a way
	# to remove it. A row missing any of those is a row that looks fine and does nothing.
	var row: Node = screen.find_child("Row_123", true, false)
	_assert(row.find_child("Preview", true, false) != null, "the row has no 3D preview")
	var strip: Node = row.find_child("DieStrip", true, false)
	_assert(strip != null, "the row shows no die")
	_assert(strip != null and strip.get_child_count() == 6,
		"the die strip shows %d faces, expected 6"
		% (strip.get_child_count() if strip != null else -1))

	# The import control follows what the build can ACTUALLY do, and says so either way. This
	# used to assert the field was permanently disabled; that stopped being true when the network
	# layer landed, so the check now mirrors `AxieApi.is_available()` instead of a constant.
	var field := screen.find_child("AxieIdField", true, false) as LineEdit
	var scan := screen.find_child("ScanButton", true, false) as Button
	var status := screen.find_child("ImportStatus", true, false) as Label
	_assert(field != null and scan != null and status != null,
		"the import row is missing one of its three parts (field / SCAN / status line)")
	if field != null and scan != null and status != null:
		if AxieApi.is_available():
			_assert(field.editable,
				"import works on this build but the Axie ID field is not editable")
			_assert(scan.disabled,
				"SCAN is enabled with an EMPTY field — pressing it costs a round trip to learn "
				+ "what the field could have said immediately")
			field.text = "123"
			screen._refresh_scan_enabled()
			_assert(not scan.disabled, "SCAN stayed disabled for a valid Axie ID")
			field.text = "abc"
			screen._refresh_scan_enabled()
			_assert(scan.disabled, "SCAN is enabled for an ID that is not a number")
			field.text = ""
			screen._refresh_scan_enabled()
		else:
			_assert(not field.editable,
				"import cannot work on this build but the field invites the player to try")
			_assert(scan.disabled, "the SCAN button is enabled and would do nothing")
			_assert(status.text.contains(AxieApi.unavailable_reason()),
				"import is unavailable and the screen does not say why: '%s'" % status.text)

	# Removing through the button must go through the store, not just hide a row.
	var remove := row.find_child("RemoveButton", true, false) as Button
	_assert(remove != null, "the row has no REMOVE button")
	if remove != null:
		remove.pressed.emit()
		await get_tree().process_frame
		_assert(MetaState.vault_index_of("123") < 0,
			"REMOVE did not reach the store — the row is gone from the screen and the Axie is "
			+ "still in the save, so it comes back on the next visit")
		_assert(screen.find_child("Row_123", true, false) == null,
			"the removed row is still on screen")
		_assert(screen.find_child("Row_456", true, false) != null,
			"removing one Axie took the other one with it")

	screen.queue_free()
	_done("test_the_vault_screen_shows_what_the_store_holds")


## A record written under the old face rules must be visible AND visibly unusable. Hiding it reads
## as data loss; showing it unmarked hands the player a die built to last version's rules.
func test_the_screen_marks_a_stale_record_instead_of_hiding_it() -> void:
	MetaState.vault.clear()
	var old := AxieToDie.build(_payload("321"))
	old["axie_id"] = "321"
	old["schema"] = 1
	MetaState.vault.append(old)

	var screen := (load("res://scenes/vault/Vault.tscn") as PackedScene).instantiate()
	add_child(screen)
	await get_tree().process_frame

	var row: Node = screen.find_child("Row_321", true, false)
	_assert(row != null, "a stale record was hidden from the screen entirely — to the player "
		+ "that is an Axie that vanished")
	if row != null:
		_assert(row.find_child("StaleBadge", true, false) != null,
			"a stale record is shown with no RE-SCAN badge — it looks exactly like a playable one")
	screen.queue_free()
	_done("test_the_screen_marks_a_stale_record_instead_of_hiding_it")


## UI rule, ported from the JS build's own checklist (`tools/verify.mjs`: no `undefined`/`NaN`
## leaks). Written as a sweep over every Label rather than as a check on one field, because the
## bug that prompted it was not a missing value — it was a PRESENT one printed wrong.
##
## `AxieToDie` sets `secret_cls` to NULL on an ordinary Axie, mirroring the JS `secretCls: null`.
## `str(null)` in GDScript is the literal string "<NULL>", which is not empty — so the first
## version of the row printed "<NULL>" where the class goes and lit the ◈ SECRET badge on every
## Axie in the vault. `t_vault` was green throughout: it asserted rows existed, never what they
## said. Only the screenshot showed it.
func test_no_row_leaks_a_null_or_nan_into_its_text() -> void:
	MetaState.vault.clear()
	MetaState.vault_import(_payload("123", "plant"))
	MetaState.vault_import(_payload("456", "aqua"))

	var screen := (load("res://scenes/vault/Vault.tscn") as PackedScene).instantiate()
	add_child(screen)
	await get_tree().process_frame

	var seen := 0
	for node in screen.find_children("*", "Label", true, false):
		var text := (node as Label).text
		seen += 1
		for leak in ["<NULL>", "null", "nan", "NaN", "undefined", "inf"]:
			_assert(not text.contains(leak),
				"a Label on the Vault screen reads '%s' — it leaks '%s' to the player" % [
					text, leak])
	_assert(seen > 6, "only %d labels found; the sweep is not reaching the rows" % seen)

	# And the badge must be OFF for an ordinary Axie: a screen where every Axie is "secret" says
	# nothing at all.
	for id in ["123", "456"]:
		var row: Node = screen.find_child("Row_" + id, true, false)
		_assert(row != null and row.find_child("SecretBadge", true, false) == null,
			"Axie %s has no secret class but the row shows the ◈ SECRET badge" % id)

	screen.queue_free()
	_done("test_no_row_leaks_a_null_or_nan_into_its_text")



## A STATIC sweep over the test directory itself, not over behaviour.
##
## WHY. Six gates were converted to `SaveGuard` by looking for files that already had a local
## `_restore_save()` helper. That was the wrong set: it missed `qa_vault_screen_capture.gd`, which
## had never had one — it restored `MetaState.vault` in memory and stopped, while
## `vault_import()`'s own `save_to_disk()` left three fixture Axies in the player's real save. The
## player found a stranger's Axies in their vault. Nothing failed, and the per-gate `shasum` sweep
## that would have caught it is a thing a person has to remember to run.
##
## So the rule is enforced on the SOURCE: anything under `res://tests/` that can write to
## `MetaState` must also mention `SaveGuard`. It is a crude check on purpose — it cannot be
## fooled by a clever restore, and it costs one directory walk.
func test_no_test_writes_to_the_real_save_without_a_save_guard() -> void:
	# Calls that reach `MetaState.save_to_disk()`, directly or through the game's own code.
	var writers := ["vault_import(", "vault_remove(", "claim_daily_mission(", "buy_unlock(",
		"claim_bp_reward(", "add_shards(", "save_to_disk(", "end_run("]
	# INDIRECT writers: loading one of these scenes is enough, because the scene's own `_ready()`
	# reaches `MetaState.save_to_disk()`. Four QA captures slipped through the direct-call list
	# for exactly this reason — they only ever said `Result.tscn`, never `end_run(`, and they were
	# quietly banking shards and XP into the player's save on every run.
	var writer_scenes := ["Result.tscn"]
	var dir := DirAccess.open("res://tests")
	_assert(dir != null, "could not open res://tests to sweep it")
	if dir == null:
		return

	var scanned := 0
	for file_name in dir.get_files():
		if not file_name.ends_with(".gd"):
			continue
		# This file, and the guard itself, are allowed to name these without using one.
		if file_name in ["t_vault.gd", "save_guard.gd"]:
			continue
		var text := FileAccess.get_file_as_string("res://tests/" + file_name)
		if text.is_empty():
			continue
		scanned += 1
		var touched := ""
		for w in writers:
			if text.contains("MetaState." + w) or text.contains("RunState." + w):
				touched = w
				break
		if touched.is_empty():
			for sc in writer_scenes:
				if text.contains(sc):
					touched = sc + " (whose _ready() writes the save)"
					break
		if touched.is_empty():
			continue
		# USE, not mention. The first version of this check looked for the word "SaveGuard"
		# anywhere in the file — and passed happily on a file where the only occurrence was the
		# COMMENT explaining why a SaveGuard was needed. Verified by injection: removing the real
		# guard left the gate green. All three calls have to be present.
		var uses_guard := text.contains("SaveGuard.new()") \
			and text.contains(".capture()") and text.contains(".restore()")
		_assert(uses_guard,
			("%s calls %s — which reaches MetaState.save_to_disk() — without a working SaveGuard "
			+ "(needs SaveGuard.new() + .capture() + .restore()). Running it edits the player's "
			+ "real save file and leaves it edited.") % [file_name, touched])

	_assert(scanned > 20, "the sweep only saw %d test files; it is not reaching the directory"
		% scanned)
	_done("test_no_test_writes_to_the_real_save_without_a_save_guard")
