extends Node
## Gate on the mockup → repo asset translation (`scenes/shared/MockupAssets.gd`).
##
## This test does NOT carry its own list of paths. It re-reads the four mockup HTML files and
## checks every asset reference they contain. That matters: a hard-coded list would pass
## forever while a mockup quietly grew a seventh node icon, which is the same class of drift
## that let a missing intent icon ship as an empty black box.
##
## Run: godot --headless --path godot res://tests/t_mockup_assets.tscn

const MOCKUP_DIR := "../docs/design-handoff-v2/mockups-v2"
const MOCKUPS := ["combat-v2.html", "run-flow-v2.html", "meta-screens-v2.html",
	"handoff-spec-v2.html"]

## The templated references, spelled out. `assets/fx/${k}.png` cannot be checked by reading the
## string; it has to be checked against the set of k the mockups actually pass.
const PART_SLOTS := ["mouth", "horn", "back", "tail", "eyes", "ears"]
const CLASSES := ["plant", "beast", "aqua", "reptile", "bug", "bird"]
const STATUS_KEYS := ["poison", "thorns", "burn", "weaken", "vuln", "regen", "stun", "freeze",
	"shield", "blind", "undying"]

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_mockup_assets: start ===")
	test_every_literal_path_in_every_mockup_resolves()
	test_every_part_icon_the_template_can_ask_for_exists()
	test_every_class_portrait_exists()
	test_every_status_icon_the_template_can_ask_for_exists()
	test_unmapped_paths_return_empty_rather_than_a_broken_guess()

	print("=== t_mockup_assets: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_mockup_assets: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_mockup_assets: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(msg)


func _mockup_text(file_name: String) -> String:
	var base := ProjectSettings.globalize_path("res://").path_join(MOCKUP_DIR)
	var f := FileAccess.open(base.path_join(file_name), FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text()


## Every `assets/…` string the mockups write literally must land on a file that exists.
func test_every_literal_path_in_every_mockup_resolves() -> void:
	var re := RegEx.create_from_string("assets/[A-Za-z0-9_\\-/]+?\\.(?:png|svg|jpg|jpeg)")
	var seen := {}
	for m in MOCKUPS:
		var text := _mockup_text(m)
		_assert(not text.is_empty(),
			"mockup '%s' could not be read — the design source of truth is missing from the " % m
				+ "repo, so nothing below actually proves anything")
		if text.is_empty():
			continue
		for hit in re.search_all(text):
			var raw := hit.get_string()
			if seen.has(raw):
				continue
			seen[raw] = m
			var p := MockupAssets.path(raw)
			_assert(not p.is_empty(),
				"'%s' (in %s) has no rule in MockupAssets — add one rather than inlining a "
					% [raw, m] + "res:// string at the call site")
			if p.is_empty():
				continue
			_assert(ResourceLoader.exists(p),
				"'%s' (in %s) maps to '%s', which is not in the project" % [raw, m, p])
	_assert(seen.size() >= 30,
		"only %d literal asset paths were found across four mockups — the regex is probably "
			% seen.size() + "not matching, which would make this whole test vacuous")


## `partIcon(part, cls)` can ask for any slot × class pair, including pairs no mockup happens
## to draw. Checking only the drawn ones is how a Bird team would find a hole at runtime.
func test_every_part_icon_the_template_can_ask_for_exists() -> void:
	for slot in PART_SLOTS:
		for cls in CLASSES:
			_assert(MockupAssets.part_icon(slot, cls) != null,
				"part icon %s/%s does not load — a die face would draw an empty tile" % [slot, cls])
	_assert(MockupAssets.part_icon("", "plant") != null,
		"the empty-slot case must fall back to blank.svg, not to null")


func test_every_class_portrait_exists() -> void:
	for cls in CLASSES:
		_assert(MockupAssets.tex("assets/portrait/%s.png" % cls) != null,
			"portrait for class '%s' does not load — it is used on the die card header, the "
				% cls + "run-map rail, the Result lineup and the inspector")


func test_every_status_icon_the_template_can_ask_for_exists() -> void:
	for k in STATUS_KEYS:
		_assert(MockupAssets.tex("assets/fx/%s.png" % k) != null,
			"status icon '%s' does not load — the chip would render as a bare colour block, "
				% k + "which is exactly what rule 6 forbids")


## A path with no rule must come back empty, never a plausible-looking res:// string that
## points at nothing. A wrong guess is worse than a refusal: it loads as null and draws a hole.
func test_unmapped_paths_return_empty_rather_than_a_broken_guess() -> void:
	for bad in ["assets/nope/thing.png", "assets/bg/not-a-place.jpg", "thing.png", ""]:
		_assert(MockupAssets.path(bad).is_empty(),
			"MockupAssets.path('%s') returned '%s' instead of refusing" % [bad, MockupAssets.path(bad)])
	_assert(MockupAssets.path("res://assets/icons/web/dmg.png") == "res://assets/icons/web/dmg.png",
		"a path that is already a res:// path must pass through untouched")
