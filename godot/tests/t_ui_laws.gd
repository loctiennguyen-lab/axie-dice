extends Node
## UI LAWS — the design rules, as a failing test.
##
## Run:  godot --headless --path godot res://tests/t_ui_laws.tscn
##       (picked up automatically by godot/tools/run_tests.sh)
##
## WHY THIS IS A SCENE TEST AND NOT `--script`. It shipped as `extends SceneTree`, run via
## `--script`. That form HANGS — not fails, hangs — and it took two processes stuck at 29 and 18
## minutes to notice, with the whole suite blocked behind it. The cause is not in this file's
## logic: `--script` starts Godot WITHOUT autoloads, and this test needs `SaveGuard`, which reads
## `MetaState.SAVE_PATH`. Resolving that unresolvable reference at script-load time never returns,
## so nothing this file does ever runs and it prints nothing at all. Every other test in this
## project that touches an autoload is a scene test for exactly this reason — see `t_vault.gd`.
## If you are tempted to move it back to `--script`, that is the trap.
##
## WHY THIS FILE EXISTS. Two rounds of written design corrections drifted back within one pass
## each. A rule nobody asserts is a suggestion. Every law below corresponds to a defect that
## actually shipped, so a regression fails the build instead of reaching a screenshot.
##
## Copy to: godot/tests/t_ui_laws.gd

const SCENES := [
	"res://scenes/main_menu/MainMenu.tscn",
	"res://scenes/main_menu/TeamSelect.tscn",
	"res://scenes/run_map/RunMap.tscn",
	"res://scenes/result/Result.tscn",
	"res://scenes/pass/Pass.tscn",
	"res://scenes/unlocks/Unlocks.tscn",
	"res://scenes/vault/Vault.tscn",
	"res://scenes/guides/Guides.tscn",
	"res://scenes/codex/Codex.tscn",
	"res://scenes/settings/Settings.tscn",
	"res://scenes/tutorial/Tutorial.tscn",
	"res://scenes/combat/Combat.tscn",
]


## 20 Sep 2026 — THE MOCKUPS OWN NUMBERS; THEY DO NOT OWN POSITIONS.
##
## This test arrived as part of the FIX-PASS-02 handoff ("new file, drop in as-is"). It
## encoded eight "screen laws" taken from the prose passes, NOT from the four v2 mockups in
## `docs/design-handoff-v2/mockups-v2/`. The owner ruled that morning that the mockups are the
## design authority, so four of those eight laws were enforcing the opposite of the design and
## have been removed or rewritten. Each removal is recorded at its old site rather than deleted
## silently, because the point of a law file is that you can see what it stopped enforcing.
##
## REVISED that evening, when the canvas went back to `window/stretch/aspect="expand"`: a
## mockup's WIDTH, padding, radius, border, gap, font size and colour are still the authority
## and still what these laws defend. A mockup's absolute Y is not — the logical viewport keeps
## its 1920 width and grows vertically, so 1080 is the MINIMUM canvas. That makes CANVAS below
## the tightest case for "nothing is clipped" rather than the only case, which is why the L1
## check still uses it.
##
## STILL MISSING, and the next thing to add here: the same walk at a TALLER canvas. Everything
## this file asserts is size-invariant except L1, and the defects `expand` actually produces —
## a band pinned to an absolute y while its neighbour floats, a graph leaving a void under
## itself — only appear above 1080. See FIX-PASS-03 §1.
const CANVAS := Vector2(1920, 1080)

## L8's old 12px/15px type floor is GONE. The mockups draw 9px (die-card face caption, combat
## node eyebrow), 10px (Team Select face caption, Codex tab tag) and 11px (mana hint, intent
## target line, boss ribbon eyebrow, relic description) as deliberate, repeated choices. A
## floor above those made the design illegal. What is left is a truncation guard: nothing in
## any mockup goes below 9, so a smaller number is a bug in our code, not a design intent.
const MIN_FONT := 9

var _fail: Array[String] = []
var _scene := ""

## ADDED when this file landed. `Result.tscn`'s `_ready()` writes the save, which reaches
## `MetaState.save_to_disk()` — so walking these scenes edits the PLAYER'S REAL SAVE and leaves
## it edited. This project already has a test whose whole job is to catch that (`t_vault`), and
## it caught this file on its first run. Every capture/QA scene in `tests/` wraps itself the same
## way; see `tests/save_guard.gd`.
var _guard := SaveGuard.new()


func _ready() -> void:
	var root := get_tree().root
	# `content_scale_size` alone is not the canvas a Control measures itself against — that is
	# the VIEWPORT's size, which headless leaves at whatever the window happens to be. Every
	# full-rect Control then reported a 1920x1920 rect and L1 flagged all twelve scenes as
	# "clipped by the canvas edge", 375 violations of a law none of them was breaking. The
	# window has to actually be the canvas for the measurement to mean anything.
	root.content_scale_size = CANVAS
	root.size = Vector2i(CANVAS)
	DisplayServer.window_set_size(Vector2i(CANVAS))
	for _w in 4:
		await get_tree().process_frame
	_guard.capture()
	_seed_state_the_scenes_need()
	for path in SCENES:
		await _check_scene(path)
	_guard.restore()
	if _fail.is_empty():
		print("t_ui_laws: PASS (%d scenes)" % SCENES.size())
		get_tree().quit(0)
	else:
		print("t_ui_laws: %d VIOLATION(S)\n" % _fail.size())
		for line in _fail:
			print("  " + line)
		get_tree().quit(1)


## Two of the twelve scenes below refuse to build out of nowhere, and both refusals are correct:
## `MainMenu._ready()` routes to the tutorial while the save has never seen it, and `CombatView`
## asserts that `RunState.pending_combat` was set by whoever sent the player into a fight. On a
## machine with a played save the first is invisible and on the author's the second was never
## hit, so this gate went red on a fresh checkout for reasons that had nothing to do with UI
## laws. Both are seeded here, in memory; `_guard` puts the save file back byte for byte.
func _seed_state_the_scenes_need() -> void:
	MetaState.tutorial_seen = true
	CombatView.disable_juice_for_tests = true
	var roster: Array = []
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	for i in keys.size():
		roster.append({
			"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"],
			"muts": [], "growth": {}, "bonus_hp": 0,
		})
	RunState.pending_combat = {
		"node_id": "ui_laws_node", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": roster, "relic_ids": [], "combat_seed": 13371337,
	}


## Frees the scene under test. Called on EVERY exit path from `_check_scene()`.
func _teardown(inst: Node) -> void:
	get_tree().root.remove_child(inst)
	inst.free()


func _bad(node: Node, law: String, detail: String) -> void:
	_fail.append("%s  [%s]  %s — %s" % [_scene, law, node.get_path(), detail])


func _check_scene(path: String) -> void:
	_scene = path.get_file()
	if not ResourceLoader.exists(path):
		_fail.append("%s  [L0] scene missing" % _scene)
		return
	var inst: Node = (load(path) as PackedScene).instantiate()
	get_tree().root.add_child(inst)
	# Six frames, not two. A screen that caps a region with `fit_or_scroll()` reports the
	# UNCAPPED height until its container has resorted, and two frames is not always enough —
	# the Codex read 431px taller than the canvas here while its own QA capture shows it
	# sitting inside the footer line.
	for _f in 6:
		await get_tree().process_frame
	# EVERY scene checked here is freed at the end of this function. It was not, and that is why
	# this test HUNG rather than failed: twelve live scenes accumulate in the tree, and Combat in
	# particular starts a combat loop, timers and audio that keep the tree busy so `quit()` never
	# arrives. Two of these were found stuck at 29 and 18 minutes. A test that hangs is worse than
	# a test that fails — it stops the suite instead of reporting, and `run_tests.sh` picks this
	# file up, so one hang here takes every other gate with it.

	# L0 · every screen paints on a plate; none renders on engine grey.
	#
	# RECURSIVE on purpose. This used `has_node("PlateHost")`, which only looks at DIRECT
	# children — and Combat and RunMap have `Node2D` scene roots whose real UI lives under
	# `CanvasLayer/Root`, so their genuine plate could never satisfy it. The first response to
	# that was to add an EMPTY `PlateHost` Control at each of those two scene roots purely to
	# make this line pass. That is a test being made to lie: the assertion went green while the
	# thing it asserts about was not there. Those decoys have been deleted and the check now
	# looks where a plate actually lives.
	if inst.find_child("PlateHost", true, false) == null:
		_fail.append("%s  [L0] no PlateHost — screen renders on engine grey" % _scene)

	# L4 · REMOVED — see the note at the per-Control L4 site. Whether a screen has a footer is
	# the mockup's call, not this file's.

	_walk(inst, inst)
	# `queue_free()` is DEFERRED, and one frame is not enough to collect a scene that is still
	# running timers — which is half of why this file hung. Free it synchronously instead.
	_teardown(inst)


func _walk(node: Node, scene_root: Node) -> void:
	if node is Control:
		_check_control(node as Control, scene_root)
	for child in node.get_children():
		_walk(child, scene_root)


func _check_control(c: Control, scene_root: Node) -> void:
	# ── L7 · shadows are hard shelves, and borders are pure black ────────────────────────────
	# `get_theme_stylebox_list()` does not exist on Control in Godot 4 — it was a Godot 3 API.
	# As shipped, this line threw on EVERY Control the walk visited, so laws L7-shadow and
	# L7-border never actually ran: the test printed a violation count that excluded the two
	# rules it exists to enforce, while the errors scrolled past as engine noise. A test that
	# errors per node and still reports a tidy total is worse than one that fails outright.
	# Godot 4 has no way to enumerate a Control's overrides, so the names are listed explicitly;
	# these are every stylebox key this project actually sets.
	for key in ["panel", "normal", "hover", "pressed", "disabled", "focus",
			"tab_selected", "tab_unselected", "tab_hovered", "read_only"]:
		if not c.has_theme_stylebox_override(key):
			continue
		var sb := c.get_theme_stylebox(key)
		if sb is StyleBoxFlat:
			var f := sb as StyleBoxFlat
			if f.shadow_size != 0:
				_bad(c, "L7", "shadow_size=%d — a shelf is shadow_size 0 + shadow_offset"
					% f.shadow_size)
			var b := f.border_color
			var is_black := b.r < 0.02 and b.g < 0.02 and b.b < 0.02 and b.a > 0.98
			# The mockups draw exactly five non-black borders, and no others:
			#   · the selection ring on a die card and a targetable enemy   → PRIMARY
			#   · the targetable ring on a party member                     → SUCCESS
			#   · the party nameplate's 6px top edge                        → the class colour
			#   · shield/info accents                                       → INFO
			#   · a WARNING BUTTON's outline                                → DANGER
			# The last one was missing here and it is not drift: FIX-PASS-03 L1 names it as one
			# of its two explicit exceptions ("a warning button's DANGER outline"), and
			# `DangoTheme.primary_button_style(warning = true)` is the only thing that draws it —
			# END TURN, while the player still has an unspent die. Flagging it made the gate
			# demand that a sanctioned state be removed.
			var is_state := b.is_equal_approx(DangoTheme.PRIMARY) \
				or b.is_equal_approx(DangoTheme.INFO) \
				or b.is_equal_approx(DangoTheme.SUCCESS) \
				or (c is Button and b.is_equal_approx(DangoTheme.DANGER)) \
				or _is_class_color(b) or b.a == 0.0
			if f.get_border_width_min() > 0 and not is_black and not is_state:
				_bad(c, "L7", "border_color %s — the mockups use pure black everywhere except "
					% b.to_html(false) + "PRIMARY/SUCCESS selection rings and the party "
					+ "nameplate's class-coloured top edge")

	# ── L8 · type floor ──────────────────────────────────────────────────────────────────────
	var floor_px := MIN_FONT
	if c is Label or c is Button or c is RichTextLabel:
		var size_px := c.get_theme_font_size("font_size", c.get_class())
		if c.has_theme_font_size_override("font_size"):
			size_px = c.get_theme_font_size("font_size")
		if size_px > 0 and size_px < floor_px:
			_bad(c, "L8", "font_size %d is below %d — no mockup goes under 9px, so this is "
				% [size_px, floor_px] + "ours, not the design's")

	# ── L6 · no white ink on a saturated fill ────────────────────────────────────────────────
	if (c is Label or c is Button) and c.has_theme_color_override("font_color"):
		var ink: Color = c.get_theme_color("font_color")
		if ink.r > 0.92 and ink.g > 0.92 and ink.b > 0.92:
			var parent_fill: Variant = _nearest_fill(c)
			# The mockups deliberately put CREAM_RAISED on DANGER — the incoming-damage chip
			# and the ENEMY TURN banner both read `#FFF8EA` on `#F54540`, and `ink_on()` would
			# darken them, which is not the design. Reds are therefore exempt. On PRIMARY, on
			# a class colour and on a rarity colour the mockups are unanimous the other way:
			# always dark ink, never white. That is what this law now guards.
			if parent_fill != null and _is_saturated(parent_fill) \
					and not _is_red(parent_fill as Color):
				_bad(c, "L6", "near-white ink on fill %s — every mockup inks this dark; "
					% (parent_fill as Color).to_html(false) + "use DangoTheme.ink_on()")

	# ── L1 · nothing is clipped by the canvas edge ───────────────────────────────────────────
	# The old L1 demanded a uniform 48px safe area on every side of every screen. The mockups
	# have no such thing: the run-map rail insets 28, its header 30, the combat deck 24/16, the
	# combat top bar 0, and the meta screens variously 42, 44, 56 and 64. Enforcing 48 made
	# agents push mockup numbers outward to satisfy a rule the design never agreed to, which is
	# how Team Select, Guides and Codex drifted off their redlines. What the mockups DO share
	# is that nothing is ever cut off by the edge of the canvas — so that is the law. CANVAS is
	# 1920x1080, the MINIMUM under `aspect="expand"`: a layout that fits the minimum fits every
	# larger one, so this is the tightest form of the check, not an assumption about the window.
	# Inside a scrolling region this law does not apply and cannot: a scroll viewport clips its
	# content on purpose and hands the player a bar to reach the rest — which is L2's job, not
	# this one. Measuring a scrolled card against the canvas reported the Codex's eleven status
	# cards as eleven clipping bugs on a screen whose own capture shows every one of them inside
	# the panel.
	if c.visible and c.size.x > 1.0 and c.size.y > 1.0 \
			and not _is_full_bleed(c) and not _inside_scroll(c):
		var r := Rect2(c.global_position, c.size)
		if r.position.x < -0.5 or r.position.y < -0.5 \
				or r.end.x > CANVAS.x + 0.5 or r.end.y > CANVAS.y + 0.5:
			_bad(c, "L1", "rect %s is clipped by the canvas edge" % r)

	# ── L4 · REMOVED ─────────────────────────────────────────────────────────────────────────
	# "BACK always lives in a footer bar" came from the prose passes. The mockups decide per
	# screen — their Codex has no footer at all — so this law was forcing a footer onto screens
	# the design draws without one, and costing the Codex panel 72px of height to do it.

	# ── L2 · a scrollable region shows a scrollbar ───────────────────────────────────────────
	if c is ScrollContainer:
		var sc := c as ScrollContainer
		if sc.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			if sc.get_v_scroll_bar().custom_minimum_size.x < 8.0:
				_bad(c, "L2", "scrollable but the scrollbar has no width — invisible overflow")

	# ── L3 · a panel does not leave a void under its last child ──────────────────────────────
	# Two things are NOT this defect and were being reported as it:
	#   · a HIDDEN panel (the debug log, a die card's reroll overlay) — nobody sees its slack;
	#   · a panel STRETCHED BY ITS ROW to match a taller sibling, which is RES-04's "all three
	#     are the same height, the row stretches" said out loud. Slack there is the law working.
	var stretched_by_row: bool = c.get_parent() is BoxContainer \
		and (c.size_flags_vertical & Control.SIZE_FILL) != 0
	# A panel whose body SCROLLS has no void under its last child — it has a viewport, and what
	# is under the fold is reachable. CDX-02's reading panel fills the column by design.
	if c is PanelContainer and c.visible and not stretched_by_row \
			and not _inside_scroll(c) and not _wraps_a_scroll(c) and c.get_child_count() > 0:
		var child := c.get_child(0)
		if child is Control:
			var slack: float = c.size.y - (child as Control).get_combined_minimum_size().y
			if slack > 80.0:
				_bad(c, "L3", "%dpx of empty panel below its content — hug it or fit_or_scroll()"
					% int(slack))


## Walks up for the nearest ancestor StyleBoxFlat fill, so "white on orange" can be detected
## without every call site declaring its own background.
func _nearest_fill(c: Control) -> Variant:
	var n: Node = c
	while n != null:
		if n is Control and (n as Control).has_theme_stylebox_override("panel"):
			var sb := (n as Control).get_theme_stylebox("panel")
			if sb is StyleBoxFlat:
				return (sb as StyleBoxFlat).bg_color
		if n is Button and (n as Control).has_theme_stylebox_override("normal"):
			var nb := (n as Control).get_theme_stylebox("normal")
			if nb is StyleBoxFlat:
				return (nb as StyleBoxFlat).bg_color
		n = n.get_parent()
	return null


## The five class colours, as the mockups define them. A party nameplate's 6px top edge is
## drawn in its Axie's class colour — the one coloured border the design actually asks for.
func _is_class_color(b: Color) -> bool:
	for cls in ["plant", "beast", "aqua", "reptile", "bug", "bird"]:
		if b.is_equal_approx(DangoTheme.class_color(cls)):
			return true
	return false


## Reds — DANGER and the boss ribbon's `#C9302B`. The mockups ink these cream, not dark.
func _is_red(col: Color) -> bool:
	return col.r > 0.55 and col.g < 0.45 and col.b < 0.45


func _is_saturated(fill: Variant) -> bool:
	var col: Color = fill
	if col.a < 0.5:
		return false
	# saturated == a real hue at meaningful chroma: the class colours, PRIMARY, the rarity set.
	return col.s > 0.35 and col.v > 0.55


## Full-bleed chrome is allowed outside the safe area: the Combat top bar, the deck bar, the
## footer, and the plate/scrim stack.
## True when `c` is inside a scroll viewport — its clipping is the feature, not the defect.
func _inside_scroll(c: Control) -> bool:
	var n: Node = c.get_parent()
	while n != null:
		if n is ScrollContainer:
			return true
		n = n.get_parent()
	return false


## True when `c` CONTAINS a vertically scrolling region, so its own height is a viewport.
func _wraps_a_scroll(c: Control) -> bool:
	for n in c.find_children("*", "ScrollContainer", true, false):
		if (n as ScrollContainer).vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			return true
	return false


func _is_full_bleed(c: Control) -> bool:
	if c.name in ["PlateHost", "Plate", "Scrim", "Background", "Footer", "TopBar", "DeckBar",
			"Content"] or c.get_parent() == null:
		return true
	# The plate itself is a cover-fit image: `build_plate()` scales it to fill the canvas on its
	# long axis, so it over-scans on the other one BY DESIGN. Its whole subtree is exempt, which
	# is not a loophole — nothing inside a plate host carries type or a control.
	var n: Node = c.get_parent()
	while n != null:
		if n.name in ["PlateHost", "Background", "Scrim"]:
			return true
		n = n.get_parent()
	return false
