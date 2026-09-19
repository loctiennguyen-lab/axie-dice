extends Node
## Gate for the gene -> 3D preview path (Vault/Import Axie, step (b)).
##
## WHAT IT IS ACTUALLY PROTECTING
## -----------------------------
## Two different failures, and only one of them looks like a failure:
##
##  1. The decoder drifting. `AxieDescriptor.from_genes()` is vendored addon code that this
##     project does not own; a re-vendor could change how a gene becomes a body, a colour and six
##     parts. The vendor ships its own goldens for exactly that, and this test reads THEM — not a
##     hand-written expectation, which would only be the port agreeing with itself.
##
##  2. An Axie rendering as a bare body with nobody noticing. `AxiePartResolver` falls back by skin
##     and by level but NEVER by variant, so a part the kit does not ship resolves to nothing
##     rather than to something wrong. The picture that comes out is not an error — it is a
##     plausible-looking Axie missing its horns, and this project's most expensive bugs have all
##     been of that shape (five growth sources writing keys nobody read; every monster mute).
##     So the counts below are PINNED, and the empty-gene sample must come back explicitly flagged.
##
## The measured numbers, taken on 2026-09-19 from the vendor's ten pinned samples:
##   9 of 10 build whole · 54 of 54 decodable parts resolve to a real catalogue asset.
## Note this CORRECTS the figure carried in the handover ("54/60, 90% coverage"): the missing six
## were the phantom parts of sample #1, whose gene is literally `0x0` and which the vendor marks
## `skip`. There is no kit coverage gap on real genes — there is one sample with no gene at all.
##
## Run: godot --headless --path godot res://tests/t_axie_gene_preview.tscn

const GOLDEN_REL := "../third_party/godot-axie-mixer-3d-main/tests/goldens/sample_axies.json"
const PREVIEW_SCENE := "res://scenes/shared/AxiePreview3D.tscn"

## Measured, not assumed — see the header. A change here must be a change somebody looked at.
const EXPECTED_COMPLETE_AXIES := 9
const EXPECTED_SAMPLE_COUNT := 10
const EXPECTED_RESOLVED_PARTS := 54
const EXPECTED_DECODED_PARTS := 54

## Every spelling of "this is not an Axie". The last one matters most: a gene of all zeroes decodes
## to a perfectly plausible Beast with variant-00 parts, so it has to be caught as absence rather
## than rendered as a strange Axie.
const JUNK_GENES: Array[String] = ["", "   ", "0x", "zzz", "0xZZ", "0x0", "0x00000000"]

## Every test in this file, by name. Listed rather than derived so that deleting a test is a
## visible edit here, not a silent drop in coverage.
const EXPECTED_TESTS: Array[String] = [
	"test_the_catalogue_is_actually_loaded",
	"test_every_golden_decodes_to_the_vendors_own_expectations",
	"test_part_resolution_matches_the_measured_coverage",
	"test_an_axie_with_no_gene_is_reported_as_absent_not_rendered_bare",
	"test_unshipped_parts_are_named_so_the_badge_has_something_to_say",
	"test_junk_genes_never_crash_and_never_claim_to_be_an_axie",
	"test_the_preview_scene_reports_what_the_inspector_reports",
	"test_two_previews_never_share_a_stage",
	"test_a_preview_configured_before_it_enters_the_tree_still_builds",
	"test_an_offscreen_preview_stops_rendering",
	"test_the_preview_exposes_a_typed_public_api",
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
var _golden: Dictionary = {}


func _ready() -> void:
	print("=== t_axie_gene_preview: start ===")
	await get_tree().process_frame   # let AxieMixerBoot assign AxieFactory.default_factory

	_golden = _load_golden()
	if _golden.is_empty():
		print("t_axie_gene_preview: FAIL — could not read the vendor golden at %s" % GOLDEN_REL)
		get_tree().quit(1)
		return

	test_the_catalogue_is_actually_loaded()
	test_every_golden_decodes_to_the_vendors_own_expectations()
	test_part_resolution_matches_the_measured_coverage()
	test_an_axie_with_no_gene_is_reported_as_absent_not_rendered_bare()
	test_unshipped_parts_are_named_so_the_badge_has_something_to_say()
	test_junk_genes_never_crash_and_never_claim_to_be_an_axie()
	await test_the_preview_scene_reports_what_the_inspector_reports()
	await test_two_previews_never_share_a_stage()
	await test_a_preview_configured_before_it_enters_the_tree_still_builds()
	await test_an_offscreen_preview_stops_rendering()
	test_the_preview_exposes_a_typed_public_api()

	for name in EXPECTED_TESTS:
		if not _completed.has(name):
			_failures.append(("test '%s' did not run to completion — a runtime error aborted it "
				+ "part-way and every assertion after that point was skipped") % name)

	print("=== t_axie_gene_preview: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_axie_gene_preview: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_axie_gene_preview: FAIL — %s" % f)
	get_tree().quit(1)


## Called as the LAST line of every test. Reaching it is the proof the test finished.
func _done(test_name: String) -> void:
	_completed.append(test_name)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _load_golden() -> Dictionary:
	var path := ProjectSettings.globalize_path("res://").path_join(GOLDEN_REL)
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Without a catalogue every report would come back `no_catalog` and every count would be zero —
## which would make the coverage tests below pass vacuously if they only checked "nothing broke".
func test_the_catalogue_is_actually_loaded() -> void:
	_assert(AxieFactory.default_factory != null,
		"AxieFactory.default_factory is null — AxieMixerBoot did not boot, every check below "
		+ "would be measuring an empty catalogue rather than the kit")
	_done("test_the_catalogue_is_actually_loaded")


## The vendor's golden carries the body type, the colour variant and all six parts it expects for
## each pinned Axie. Comparing against that, rather than against numbers typed into this file, is
## what makes this a check on the decoder instead of a check on my transcription.
func test_every_golden_decodes_to_the_vendors_own_expectations() -> void:
	for entry in _golden.get("ids", []):
		var id := str(entry.get("id", "?"))
		if bool(entry.get("skip", false)):
			continue   # covered by its own test below
		var report := AxieGenePreview.inspect(str(entry.get("genes", "")))
		_assert(bool(report["ok"]),
			"#%s: a pinned sample came back not-ok (reason '%s')" % [id, report["reason"]])
		_assert(str(report["body_name"]) == str(entry.get("body", "")),
			"#%s: body decoded as '%s', golden says '%s'" % [
				id, report["body_name"], entry.get("body", "")])
		_assert(int(report["color_variant"]) == int(entry.get("color", -1)),
			"#%s: colour variant decoded as %d, golden says %s" % [
				id, int(report["color_variant"]), str(entry.get("color", "-"))])

		# Parts are compared by SLOT, not by array position: the gene layout order
		# (Eye/Mouth/Ear/Horn/Back/Tail) is not the enum order, and a reordering that still
		# produced the right set would otherwise read as six failures or as none.
		var got_by_slot := {}
		for p in report["parts"]:
			got_by_slot[str(p["slot"])] = p
		for want in entry.get("parts", []):
			var slot := str(want.get("type", ""))
			_assert(got_by_slot.has(slot), "#%s: decoded no %s part at all" % [id, slot])
			if not got_by_slot.has(slot):
				continue
			var got: Dictionary = got_by_slot[slot]
			_assert(str(got["part_class"]) == str(want.get("class", "")),
				"#%s %s: class '%s', golden '%s'" % [
					id, slot, got["part_class"], want.get("class", "")])
			_assert(int(got["variant"]) == int(want.get("variant", -1)),
				"#%s %s: variant %d, golden %s" % [
					id, slot, int(got["variant"]), str(want.get("variant", "-"))])
			_assert(int(got["skin"]) == int(want.get("skin", -1)),
				"#%s %s: skin %d, golden %s" % [
					id, slot, int(got["skin"]), str(want.get("skin", "-"))])
			_assert(int(got["level"]) == int(want.get("level", -1)),
				"#%s %s: level %d, golden %s" % [
					id, slot, int(got["level"]), str(want.get("level", "-"))])
			# The vendor also names the asset it expects the resolver to land on. Checking it
			# turns "a part resolved" into "the RIGHT part resolved" — the resolver's skin/level
			# fallback can succeed on a different asset than the one asked for.
			if want.has("resolved"):
				_assert(str(got["asset"]) == str(want.get("resolved", "")),
					"#%s %s: resolved to '%s', golden expects '%s'" % [
						id, slot, got["asset"], want.get("resolved", "")])
	_done("test_every_golden_decodes_to_the_vendors_own_expectations")


## The coverage figure itself. Pinned rather than derived, because the number going DOWN is the
## regression this whole file exists to catch, and a derived number can never go down.
func test_part_resolution_matches_the_measured_coverage() -> void:
	var samples: Array = _golden.get("ids", [])
	_assert(samples.size() == EXPECTED_SAMPLE_COUNT,
		"the vendor golden now has %d samples, not %d — the pinned coverage numbers below were "
		% [samples.size(), EXPECTED_SAMPLE_COUNT]
		+ "measured against the old set and no longer mean what they say")

	var complete := 0
	var decoded := 0
	var resolved := 0
	for entry in samples:
		var report := AxieGenePreview.inspect(str(entry.get("genes", "")))
		decoded += int(report["part_count"])
		resolved += int(report["resolved_count"])
		if bool(report["complete"]):
			complete += 1
	_assert(complete == EXPECTED_COMPLETE_AXIES,
		"%d of %d samples build whole, expected %d" % [
			complete, samples.size(), EXPECTED_COMPLETE_AXIES])
	_assert(decoded == EXPECTED_DECODED_PARTS,
		"%d parts decoded across the samples, expected %d" % [decoded, EXPECTED_DECODED_PARTS])
	_assert(resolved == EXPECTED_RESOLVED_PARTS,
		"%d of %d decoded parts resolved to a catalogue asset, expected %d — the kit's coverage "
		% [resolved, decoded, EXPECTED_RESOLVED_PARTS]
		+ "of real Axie parts has changed")

	# The vendor states its own floor; if ours ever drops below it we are worse than upstream
	# accepts, which is a different and louder problem than "the number moved".
	_assert(complete >= int(_golden.get("spawn_min", 0)),
		"only %d samples build whole, below the vendor's own spawn_min of %s" % [
			complete, str(_golden.get("spawn_min", 0))])
	_done("test_part_resolution_matches_the_measured_coverage")


## Sample #1's gene is `0x0`. It must come back as "there is no Axie here", not as a Beast-coloured
## body with no parts — the second is indistinguishable from a real Axie whose art failed to load.
func test_an_axie_with_no_gene_is_reported_as_absent_not_rendered_bare() -> void:
	var zero_sample := {}
	for entry in _golden.get("ids", []):
		if bool(entry.get("skip", false)):
			zero_sample = entry
			break
	_assert(not zero_sample.is_empty(),
		"the vendor golden no longer carries a skipped sample — the empty-gene case now has no "
		+ "fixture, and this test is checking nothing")
	if zero_sample.is_empty():
		return

	var report := AxieGenePreview.inspect(str(zero_sample.get("genes", "")))
	_assert(not bool(report["ok"]), "the empty gene `%s` was accepted as a real Axie"
		% str(zero_sample.get("genes", "")))
	_assert(str(report["reason"]) == AxieGenePreview.REASON_EMPTY,
		"the empty gene reported reason '%s', expected '%s'" % [
			report["reason"], AxieGenePreview.REASON_EMPTY])
	_assert(not bool(report["complete"]), "the empty gene was reported as a complete Axie")
	_assert(not AxieGenePreview.warning_text(report).is_empty(),
		"the empty gene produced no warning text — the preview would show a bare body with "
		+ "nothing on screen to say why")
	_done("test_an_axie_with_no_gene_is_reported_as_absent_not_rendered_bare")


## The badge has to NAME what is missing. "Some parts are missing" sends a player looking for a
## problem in their own Axie; "the kit has no art for Horn Plant-07" says where the fault is.
func test_unshipped_parts_are_named_so_the_badge_has_something_to_say() -> void:
	# A gene the kit cannot possibly satisfy: every part decodes to variant 255, and the kit ships
	# 02-12. Synthetic on purpose — no real Axie reaches this state, and waiting for one to appear
	# in the golden would mean never testing the path.
	var report := AxieGenePreview.inspect("0xffffffff")
	_assert(bool(report["ok"]), "a well-formed non-zero gene was rejected before decoding")
	_assert(int(report["resolved_count"]) == 0,
		"variant-255 parts resolved to %d catalogue assets — the resolver is falling back by "
		% int(report["resolved_count"])
		+ "VARIANT, which would silently show the wrong body part rather than none")
	_assert(not bool(report["complete"]), "an Axie with no resolvable part was reported complete")
	var missing: Array = report["missing"]
	_assert(missing.size() == AxieGenePreview.PART_COUNT,
		"%d missing parts named, expected %d" % [missing.size(), AxieGenePreview.PART_COUNT])
	var warning := AxieGenePreview.warning_text(report)
	_assert(warning.contains("0/6"), "the warning does not say how many parts are shown: '%s'"
		% warning)
	for label in missing:
		_assert(warning.contains(str(label)),
			"the warning leaves out the missing part '%s': '%s'" % [label, warning])
	_done("test_unshipped_parts_are_named_so_the_badge_has_something_to_say")


func test_junk_genes_never_crash_and_never_claim_to_be_an_axie() -> void:
	for genes in JUNK_GENES:
		var report := AxieGenePreview.inspect(genes)
		_assert(not bool(report["ok"]), "junk gene '%s' was accepted as a real Axie" % genes)
		_assert(not bool(report["complete"]), "junk gene '%s' was reported complete" % genes)
		_assert(int(report["resolved_count"]) == 0,
			"junk gene '%s' resolved %d parts" % [genes, int(report["resolved_count"])])
		_assert(not AxieGenePreview.warning_text(report).is_empty(),
			"junk gene '%s' produced no warning text" % genes)
	_done("test_junk_genes_never_crash_and_never_claim_to_be_an_axie")


## Wiring, deliberately kept separate from everything above. The tests so far prove the numbers are
## right; this one proves the scene that shows them to a player is actually asking for them. Both
## are needed — 74 relics once sat wired to hooks that did not exist while the suite stayed green.
func test_the_preview_scene_reports_what_the_inspector_reports() -> void:
	var packed := load(PREVIEW_SCENE) as PackedScene
	_assert(packed != null, "could not load %s" % PREVIEW_SCENE)
	if packed == null:
		return
	var preview := packed.instantiate()
	add_child(preview)
	await get_tree().process_frame

	var signalled: Array[Dictionary] = []
	preview.preview_updated.connect(func(r: Dictionary) -> void: signalled.append(r))

	# A real, whole Axie: no badge.
	var good := _first_unskipped_genes()
	var direct := AxieGenePreview.inspect(good)
	var from_scene: Dictionary = preview.set_genes(good)
	_assert(int(from_scene["resolved_count"]) == int(direct["resolved_count"]),
		"the scene reported %d resolved parts, the inspector %d" % [
			int(from_scene["resolved_count"]), int(direct["resolved_count"])])
	_assert(bool(from_scene["complete"]), "a whole Axie came back incomplete through the scene")
	_assert(not preview.get_node("Warning").visible,
		"the warning badge is showing on an Axie that built whole")
	_assert(signalled.size() == 1, "preview_updated fired %d times, expected 1" % signalled.size())

	# Now an Axie that cannot build: the badge must appear.
	preview.set_genes("0x0")
	_assert(preview.get_node("Warning").visible,
		"the warning badge stayed hidden for a gene that builds nothing — this is the exact "
		+ "silent-bare-body case the whole file is here to prevent")
	_assert(not preview.get_node("Warning/Margin/WarningLabel").text.is_empty(),
		"the badge is visible but carries no text")
	_assert(preview.get_node("Frame").texture == null,
		"the previous Axie's picture is still on screen under the new ID")

	# And clearing puts it back to empty rather than leaving the last Axie up.
	preview.clear_preview()
	_assert(not preview.get_node("Warning").visible, "clear_preview() left the badge showing")
	_assert(preview.report().is_empty(), "clear_preview() left the old report in place")

	preview.queue_free()
	_done("test_the_preview_scene_reports_what_the_inspector_reports")


## Regression guard for a bug that only a screenshot revealed, written as an assertion about the
## MECHANISM so it can live in a headless suite.
##
## `AxieAvatarRenderer` isolates a character with a render layer, and every preview uses the same
## layer in the same world. When the first version put every preview's stage at the same
## coordinates, each preview's camera saw all of them and drew them composited — four Axies on top
## of one another. Every number in every report above stayed correct while the picture was of no
## real Axie at all. Nothing here can see a picture, but "two live previews stand in different
## places" is the property that was violated, and it is checkable.
func test_two_previews_never_share_a_stage() -> void:
	var packed := load(PREVIEW_SCENE) as PackedScene
	if packed == null:
		return
	var made: Array[Node] = []
	var places := {}
	for i in 3:
		var p := packed.instantiate()
		add_child(p)
		made.append(p)
	await get_tree().process_frame
	for p in made:
		var stage := p.get_node_or_null("PreviewStage") as Node3D
		_assert(stage != null, "a preview built no 3D stage")
		if stage == null:
			continue
		var key := str(stage.position)
		_assert(not places.has(key),
			"two live previews are standing at %s — their avatar cameras will each render both "
			% key + "characters on top of each other, and the report will not say so")
		places[key] = true

	# A slot has to come back when a preview is freed, or a Vault screen opened and closed all
	# session walks the stages out to coordinates where float precision starts to matter. The
	# check is "did not move further out", not "took back that exact slot": any slot freed earlier
	# in the session is equally good, and demanding the specific one would be asserting the
	# allocator's bookkeeping order rather than the property that matters.
	var freed: Node = made.pop_back()
	var released := (freed.get_node("PreviewStage") as Node3D).position
	freed.free()
	var reused := packed.instantiate()
	add_child(reused)
	await get_tree().process_frame
	var retaken := (reused.get_node("PreviewStage") as Node3D).position
	_assert(retaken.x <= released.x,
		"a preview freed its stage at %s and the next one opened at %s — slots are not being "
		% [released, retaken] + "released, so stages drift outward for as long as the session runs")
	made.append(reused)
	for p in made:
		var stage2 := p.get_node_or_null("PreviewStage") as Node3D
		if stage2 != null and p != reused:
			_assert(stage2.position != retaken,
				"the reopened preview landed on top of a preview that is still alive, at %s"
				% retaken)
		p.queue_free()
	_done("test_two_previews_never_share_a_stage")


func _first_unskipped_genes() -> String:
	for entry in _golden.get("ids", []):
		if not bool(entry.get("skip", false)):
			return str(entry.get("genes", ""))
	return ""


## Regression test. The Vault screen builds each row as a detached subtree and configures the
## preview inside it BEFORE adding the row to anything — the ordinary way to build a list. The
## first version of `set_genes()` assumed `_ready()` had already run, so `_stage` was null, the rig
## was never built, and the panel came up empty. The only trace was four
## `Cannot call method 'add_child' on a null value` lines that a green test run scrolled past.
func test_a_preview_configured_before_it_enters_the_tree_still_builds() -> void:
	var packed := load(PREVIEW_SCENE) as PackedScene
	if packed == null:
		return
	var genes := _first_unskipped_genes()

	var preview := packed.instantiate()          # NOT in the tree yet
	var report: Dictionary = preview.set_genes(genes)
	_assert(bool(report["complete"]),
		"set_genes() on a detached preview returned a broken report — the inspection is pure and "
		+ "must not depend on being in the tree")

	add_child(preview)
	await get_tree().process_frame
	_assert(preview.get_node("PreviewStage").get_child_count() > 1,
		"a preview configured before entering the tree built no character — the stage holds only "
		+ "its light, so the panel would come up empty with no error")
	_assert(not preview.get_node("Warning").visible,
		"the deferred build left a warning badge on a whole Axie")

	# ...and a preview cleared while still detached must not spring back to life on entry.
	var cleared := packed.instantiate()
	cleared.set_genes(genes)
	cleared.clear_preview()
	add_child(cleared)
	await get_tree().process_frame
	_assert(cleared.get_node("PreviewStage").get_child_count() == 1,
		"a preview cleared before entering the tree built its Axie anyway once added")

	preview.queue_free()
	cleared.queue_free()
	_done("test_a_preview_configured_before_it_enters_the_tree_still_builds")


## Regression guard for the performance finding: a preview scrolled out of sight must stop
## rendering, and one on screen must not render at the display's rate.
##
## `ScrollContainer` CLIPS its children rather than hiding them, so `is_visible_in_tree()` stays
## true for every row a player has scrolled past. The first version rendered on that alone: a
## twenty-record vault meant twenty 512x512 viewport passes AND twenty whole-mesh-tree walks
## (`AxieAvatarRenderer._tag_visuals`) every single frame, nearly all of them for Axies nobody
## could see. Nothing errors; the screen just becomes heavy in proportion to how much the player
## has collected.
func test_an_offscreen_preview_stops_rendering() -> void:
	var packed := load(PREVIEW_SCENE) as PackedScene
	if packed == null:
		return
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, 200)
	scroll.size = Vector2(300, 200)
	scroll.position = Vector2(0, 0)
	add_child(scroll)
	var column := VBoxContainer.new()
	scroll.add_child(column)

	var preview := packed.instantiate() as AxiePreview3D
	preview.custom_minimum_size = Vector2(150, 150)
	column.add_child(preview)
	await get_tree().process_frame
	preview.set_genes(_first_unskipped_genes())
	await get_tree().process_frame

	_assert(preview._clip_rect_source == scroll,
		"the preview did not find the ScrollContainer it lives in, so it cannot tell whether it "
		+ "has been scrolled out of view and will render forever")
	_assert(preview._is_on_screen(),
		"a preview sitting inside the visible part of its scroll region reported itself offscreen")

	# Push it far below the scroll region — what scrolling to row twenty does.
	preview.position = Vector2(0, 5000)
	await get_tree().process_frame
	_assert(not preview._is_on_screen(),
		"a preview moved well outside its ScrollContainer still reports itself on screen; every "
		+ "row of a full vault would keep rendering at full rate")

	# And the rate itself must be capped, not "whatever the display does".
	_assert(AxiePreview3D.REFRESH_HZ <= 20.0,
		"REFRESH_HZ is %s — twenty previews at that rate is twenty full viewport passes and "
		% str(AxiePreview3D.REFRESH_HZ) + "twenty whole-tree walks per frame")

	preview.queue_free()
	scroll.queue_free()
	_done("test_an_offscreen_preview_stops_rendering")


## The API this screen depends on has to be reachable through a TYPED reference. Without
## `class_name` the Vault screen held its preview as a bare `Control` and called `set_genes()` on
## it — a call nothing checks until it runs. A typo in the method name would have compiled clean,
## passed `check_syntax.sh`, and failed only when a player opened the Vault.
func test_the_preview_exposes_a_typed_public_api() -> void:
	var packed := load(PREVIEW_SCENE) as PackedScene
	if packed == null:
		return
	var typed := packed.instantiate() as AxiePreview3D
	_assert(typed != null,
		"AxiePreview3D.tscn does not instantiate as AxiePreview3D — the script has lost its "
		+ "class_name, and every caller is back to untyped method calls on Control")
	if typed == null:
		return
	for method in ["set_genes", "report", "clear_preview"]:
		_assert(typed.has_method(method),
			"AxiePreview3D no longer has '%s'; a caller naming it compiles clean and fails only "
			% method + "when the screen is actually opened")
	_assert(typed.has_signal("preview_updated"), "the preview_updated signal is gone")
	typed.free()
	_done("test_the_preview_exposes_a_typed_public_api")
