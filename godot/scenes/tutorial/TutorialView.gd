extends Control
class_name TutorialView
## Mandatory onboarding tutorial (design/gdd/onboarding-tutorial.md), Godot port.
##
## SCOPE DEVIATION FROM THE DESIGN DOC (flagged per collaboration protocol — see task report
## for the full list; summarized here so the reason lives next to the code it explains):
## the JS tutorial reuses the production scCombat()/scReward() screens verbatim and overlays a
## step-lock on top of their real DOM. This port's equivalent production screens
## (scenes/combat/CombatView.gd, scenes/run_map/RunMapController.gd) are NOT owned by this
## task (see the task's file-ownership list) and retrofitting a step-lock/coach-overlay API
## into them is a real cross-screen architecture change, not something to do as a side effect
## of a tutorial. This scene is therefore a SELF-CONTAINED rehearsal: it drives a real
## `CombatEngine` instance (the same class and public API CombatView.gd uses — use_die/
## reroll_dice/end_turn) with a small hand-built board of its own, rather than instancing
## Combat.tscn. The RULES are real; the CHROME is a simplified stand-in for it.
##
## INPUT MODEL: click-click only. Unlike the JS build (which has a second drag-and-drop input
## path that also had to be locked — design doc §3.5), CombatView.gd's own header comment
## states drag-and-drop targeting is "NOT done this pass" for this port — there is currently
## only one input path in the whole game. Locking it is therefore sufficient; there is no
## second path to guard against yet, and none is added here.
##
## ISOLATION (mirrors design doc §3.1's "must not reach S.phase==='won'"/no leaderboard submit
## requirement): this fixture never touches `RunState` at all — no `enter_node()`, no action
## log assignment, no `RunState.shards_this_run` — so nothing here can be mistaken for a real
## run by the anti-cheat/replay-verify system, exactly the same isolation guarantee the JS
## fixture achieves by never incrementing `META.runs`.
##
## STEP MODEL: mirrors client.html's tutStep/tutPhase() split — most steps are DERIVED fresh
## from live combat state every render (so nothing can desync from the real board), and only
## the handful of steps with no combat-state signature of their own (WELCOME, ROLL->"GOT IT",
## INTENT->modal-closed, REWARD-taken->DONE) are tracked by the small `_manual_step` int below.

enum Step { WELCOME, ROLL, INTENT, REROLL, DIE, TARGET, ENDTURN, FREE, REWARD, DONE, LOST }

# --- Tutorial fixture tuning (coding-standards.md: gameplay values must be data-driven, not
# hardcoded inline at every call site — kept here as named consts, same pattern CombatView.gd
# already uses for its own tuning numbers, e.g. _ROLL_ANIM_SCALE). LOCKED once shipped, same
# as the JS TUT_SEED/TUT_TEAM/TUT_ENEMY_HP — changing the seed changes the first roll shown to
# every new player. Verified against THIS engine's own RNG (not assumed from the JS values) —
# see the task report for the probe that checked this seed produces >=1 usable "dmg" actor
# both before and after a reroll, and that the exact taught sequence (1 coached hit, then free
# play) wins within 2 real turns, on this build's CombatEngine.
const TUT_SEED := 3
const TUT_TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bird1"]
const TUT_ENEMY_HP := 6

const _REWARD_FLAVORS := [
	{"title": "+3 Max HP", "desc": "A sturdier Axie survives more turns."},
	{"title": "New Relic", "desc": "A passive effect that helps your whole team."},
	{"title": "Gene Shard x20", "desc": "Currency to unlock permanent upgrades between runs."},
]

var _combat: CombatEngine
var _max_rerolls: int = 0
var _manual_step: int = 0   # 0=welcome, 1=roll("GOT IT" gate), 2=intent(modal gate), 3=auto, 8=done
var _selected_uid: int = -1
var _intent_open: bool = false
var _intent_enemy_idx: int = -1
var _finished_reason: String = ""   # "" | "reward_taken" | "lost" — which big-overlay copy to show

# --- Built controls ---
var _board: Control
var _enemy_row: HBoxContainer
var _enemy_buttons: Array[Button] = []
var _die_row: HBoxContainer
var _die_buttons: Array[Button] = []
var _reroll_button: Button
var _end_turn_button: Button
var _coach_title: Label
var _coach_body: Label
var _coach_panel: PanelContainer
var _got_it_button: Button
var _intent_panel: PanelContainer
var _intent_label: Label
var _intent_close_button: Button
var _reward_row: HBoxContainer
var _reward_buttons: Array[Button] = []
var _big_overlay: Control
var _big_title: Label
var _big_body: Label
var _big_button: Button

var _content: Control

## FLAGGED (routing task): no background art was ever specified for this fixture screen (it
## painted flat DangoTheme.BG before this pass). Reusing MainMenu's plate — thematically
## "entering the game" fits an onboarding rehearsal — rather than leaving the shell's plate
## argument to a made-up asset with no design reference.
const BG_TEXTURE := "res://assets/backgrounds/origins/scene/4-entrance.jpg"


func _ready() -> void:
	custom_minimum_size = Vector2(0, 0)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_setup_combat()
	_render()


## Shell (godot/CLAUDE.md rule 2). NO footer — changed 2026-09-20.
##
## The routing task's scene list said "footer", and this screen duly built one and then added
## nothing to it: a 72px bar of chrome with no control in it, sitting across the bottom of every
## tutorial step. FIX-PASS-03 §1 is explicit that empty painted background is fine and an empty
## PANEL is not, and §8's footer rule exists to hold a BACK — which this mandatory fixture
## deliberately does not have (see the file header's ISOLATION note; the flow exits through its
## own DONE overlay). A bar with nothing in it satisfies neither rule, so it goes; the content
## column keeps the height back.
func _build_shell() -> Control:
	var built := DangoScreen.build(self, load(BG_TEXTURE), DangoTheme.Scrim.DEFAULT, false, false)
	return built["content"]


# ===========================================================================
# Fixture setup — real CombatEngine, no RunState involved (see file header "ISOLATION").
# ===========================================================================

func _setup_combat() -> void:
	_combat = CombatEngine.new()
	_combat.setup_new({
		"node_id": "tutorial", "kind": "battle", "pw": 0, "ascension": 0,
		"combat_seed": TUT_SEED, "roster_snapshot": _roster_snapshot(),
	})
	for e in _combat.enemies:
		e.hp = TUT_ENEMY_HP
		e.max_hp = TUT_ENEMY_HP
	_max_rerolls = _combat.max_rerolls


func _roster_snapshot() -> Array:
	var out: Array = []
	for i in TUT_TEAM.size():
		out.append({"persistent_id": i + 1, "hero_key": TUT_TEAM[i], "tier": 1, "max_hp": 0,
			"muts": [], "growth": {}, "bonus_hp": 0})
	return out


# ===========================================================================
# Step derivation — port of client.html's tutPhase()/tutActor() (see file header).
# ===========================================================================

func _phase() -> int:
	if _manual_step == 0:
		return Step.WELCOME
	if _manual_step >= 8:
		return Step.DONE
	if _manual_step == 1:
		return Step.ROLL
	if _manual_step == 2:
		return Step.INTENT
	if _combat.lost:
		return Step.LOST
	if _combat.won:
		return Step.REWARD
	if _combat.turn > 1:
		return Step.FREE
	if _combat.rerolls == _max_rerolls:
		return Step.REROLL
	for u in _combat.party:
		if u.hp > 0 and u.has_rolled() and u.roll_used():
			return Step.ENDTURN
	var actor := _teaching_actor()
	if actor == null:
		return Step.FREE
	return Step.TARGET if _selected_uid == actor.uid else Step.DIE


## Which party member step DIE/TARGET teaches — recomputed fresh every call (never cached),
## same rationale as client.html's tutActor(): REROLL can turn the taught unit's face into
## something else entirely, and re-deriving after the fact is what keeps the taught pair valid.
func _teaching_actor() -> Unit:
	for u in _combat.party:
		if u.hp > 0 and u.has_rolled() and not u.roll_used() \
				and String(u.current_face().get("type", "")) == "dmg":
			return u
	for u in _combat.party:
		if u.hp > 0 and u.has_rolled() and not u.roll_used() \
				and String(u.current_face().get("type", "blank")) != "blank":
			return u
	return null


## dmg/poison/debuff faces teach "click the enemy"; anything else (heal/shield/buff/mana) falls
## back to self-target — a safe default this fixture's fixed seed does not actually exercise
## (the taught actor is a "dmg" face on TUT_SEED, verified by the probe in the task report) but
## kept so a future reseed cannot silently point the coaching arrow at an illegal target.
func _teaching_target(actor: Unit) -> Unit:
	if actor == null:
		return null
	var t := String(actor.current_face().get("type", ""))
	if t == "dmg" or t == "poison" or t == "debuff":
		for e in _combat.enemies:
			if e.hp > 0:
				return e
		return null
	return actor


func _all_rollable_uids() -> Array:
	var out: Array = []
	for u in _combat.party:
		if u.hp > 0 and u.has_rolled() and not u.roll_used() and not u.heavy and not u.frozen:
			out.append(u.uid)
	return out


# ===========================================================================
# UI construction — everything built in code (same convention as MainMenu.gd/
# RunMapController.gd's own runtime-built content).
# ===========================================================================

func _build_ui() -> void:
	_content = _build_shell()   # first statement in effect — see _build_shell()'s own doc comment

	_board = VBoxContainer.new()
	_board.set_anchors_preset(Control.PRESET_FULL_RECT)
	_board.add_theme_constant_override("separation", 16)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(_board)
	_content.add_child(margin)

	var header := Label.new()
	header.text = "TUTORIAL"
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", DangoTheme.PRIMARY)
	_board.add_child(header)

	_enemy_row = HBoxContainer.new()
	_enemy_row.add_theme_constant_override("separation", 12)
	_board.add_child(_enemy_row)
	for i in 8:   # sized generously; hidden buttons beyond the real enemy count
		var b := Button.new()
		b.visible = false
		b.pressed.connect(func(): _on_enemy_pressed(i))
		DangoTheme.style_button(b, false)
		_enemy_row.add_child(b)
		_enemy_buttons.append(b)

	_intent_panel = PanelContainer.new()
	_intent_panel.visible = false
	_intent_panel.add_theme_stylebox_override("panel", DangoTheme.surface_style(DangoTheme.Surface.PANEL, 10, 3, 4.0, Vector2(12, 8)))
	_board.add_child(_intent_panel)
	var intent_col := VBoxContainer.new()
	intent_col.add_theme_constant_override("separation", 8)
	_intent_panel.add_child(intent_col)
	_intent_label = Label.new()
	_intent_label.add_theme_color_override("font_color", DangoTheme.TEXT)
	_intent_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intent_col.add_child(_intent_label)
	_intent_close_button = Button.new()
	_intent_close_button.text = "Close"
	DangoTheme.style_button(_intent_close_button, true)
	_intent_close_button.pressed.connect(_on_intent_close_pressed)
	intent_col.add_child(_intent_close_button)

	_die_row = HBoxContainer.new()
	_die_row.add_theme_constant_override("separation", 10)
	_board.add_child(_die_row)
	for i in TUT_TEAM.size():
		var b2 := Button.new()
		b2.custom_minimum_size = Vector2(150, 90)
		b2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b2.pressed.connect(func(): _on_die_pressed(i))
		DangoTheme.style_button(b2, false)
		_die_row.add_child(b2)
		_die_buttons.append(b2)

	var controls_row := HBoxContainer.new()
	controls_row.add_theme_constant_override("separation", 12)
	_board.add_child(controls_row)
	_reroll_button = Button.new()
	_reroll_button.text = "REROLL"
	DangoTheme.style_button(_reroll_button, false)
	_reroll_button.pressed.connect(_on_reroll_pressed)
	controls_row.add_child(_reroll_button)
	_end_turn_button = Button.new()
	_end_turn_button.text = "END TURN"
	DangoTheme.style_button(_end_turn_button, true)
	_end_turn_button.pressed.connect(_on_end_turn_pressed)
	controls_row.add_child(_end_turn_button)

	_reward_row = HBoxContainer.new()
	_reward_row.add_theme_constant_override("separation", 12)
	_reward_row.visible = false
	_board.add_child(_reward_row)
	for i in _REWARD_FLAVORS.size():
		var rb := Button.new()
		rb.custom_minimum_size = Vector2(180, 100)
		rb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var flavor: Dictionary = _REWARD_FLAVORS[i]
		rb.text = "%s\n\n%s" % [String(flavor.get("title", "")), String(flavor.get("desc", ""))]
		DangoTheme.style_button(rb, true)
		rb.pressed.connect(func(): _on_reward_pressed(i))
		_reward_row.add_child(rb)
		_reward_buttons.append(rb)

	_coach_panel = PanelContainer.new()
	_coach_panel.add_theme_stylebox_override("panel", DangoTheme.surface_style(DangoTheme.Surface.PANEL, 10, 3, 4.0, Vector2(14, 9)))
	_board.add_child(_coach_panel)
	var coach_col := VBoxContainer.new()
	coach_col.add_theme_constant_override("separation", 6)
	_coach_panel.add_child(coach_col)
	_coach_title = Label.new()
	_coach_title.add_theme_font_size_override("font_size", 20)
	_coach_title.add_theme_color_override("font_color", DangoTheme.PRIMARY)
	coach_col.add_child(_coach_title)
	_coach_body = Label.new()
	_coach_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_coach_body.add_theme_color_override("font_color", DangoTheme.TEXT)
	coach_col.add_child(_coach_body)
	_got_it_button = Button.new()
	_got_it_button.text = "GOT IT →"
	_got_it_button.visible = false
	DangoTheme.style_button(_got_it_button, true)
	_got_it_button.pressed.connect(_on_got_it_pressed)
	coach_col.add_child(_got_it_button)

	_big_overlay = ColorRect.new()
	(_big_overlay as ColorRect).color = DangoTheme.BG
	_big_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.add_child(_big_overlay)
	var big_center := CenterContainer.new()
	big_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_big_overlay.add_child(big_center)
	var big_col := VBoxContainer.new()
	big_col.add_theme_constant_override("separation", 14)
	big_center.add_child(big_col)
	_big_title = Label.new()
	_big_title.add_theme_font_size_override("font_size", 28)
	_big_title.add_theme_color_override("font_color", DangoTheme.TEXT)
	big_col.add_child(_big_title)
	_big_body = Label.new()
	_big_body.custom_minimum_size = Vector2(480, 0)
	_big_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_big_body.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
	big_col.add_child(_big_body)
	_big_button = Button.new()
	_big_button.custom_minimum_size = Vector2(220, 52)
	DangoTheme.style_button(_big_button, true)
	big_col.add_child(_big_button)


# ===========================================================================
# Input handlers — EVERY one starts with an explicit step-gate check (defense in depth: this
# is the logical guard, independent of whichever controls happen to be `.disabled` — mirrors
## client.html's own reasoning for guarding its global Enter/Space shortcut inside the handler
## rather than trusting the CSS pointer-events lock alone). t_tutorial_flow.gd calls these
## functions directly (bypassing the disabled UI) specifically to prove these guards, not just
## the visual lock, are what is doing the work.
# ===========================================================================

func _on_start_pressed() -> void:
	if _phase() != Step.WELCOME:
		return
	_manual_step = 1
	_render()


func _on_got_it_pressed() -> void:
	if _phase() != Step.ROLL:
		return
	_manual_step = 2
	_render()


## One button, two jobs depending on the step (see _build_ui()'s comment on the enemy row
## doubling as the target-click surface): at INTENT it opens the read-only intent popup; at
## TARGET/FREE it forwards to the same use_die() path _on_target_pressed() drives. Each branch
## keeps its own explicit step-gate check rather than relying on the caller to have picked the
## right moment — same defense-in-depth as every other handler in this file.
func _on_enemy_pressed(idx: int) -> void:
	if idx < 0 or idx >= _combat.enemies.size():
		return
	var ph := _phase()
	if ph == Step.INTENT:
		_intent_open = true
		_intent_enemy_idx = idx
		_render()
		return
	if ph == Step.TARGET or ph == Step.FREE:
		_on_target_pressed(_combat.enemies[idx].uid)
		return


func _on_intent_close_pressed() -> void:
	_intent_open = false
	if _manual_step == 2:
		_manual_step = 3
	_render()


func _on_reroll_pressed() -> void:
	var ph := _phase()
	if ph != Step.REROLL and ph != Step.FREE:
		return
	if _combat.rerolls <= 0:
		return
	_combat.reroll_dice(_all_rollable_uids())
	_selected_uid = -1
	_render()


func _on_die_pressed(idx: int) -> void:
	var ph := _phase()
	if ph != Step.DIE and ph != Step.FREE:
		return
	if idx < 0 or idx >= _combat.party.size():
		return
	var u: Unit = _combat.party[idx]
	if u.hp <= 0 or not u.has_rolled() or u.roll_used():
		return
	if ph == Step.DIE:
		var taught := _teaching_actor()
		if taught == null or u.uid != taught.uid:
			return   # <-- the guard t_tutorial_flow.gd's break-injection targets
	_selected_uid = u.uid
	_render()


func _on_target_pressed(uid: int) -> void:
	var ph := _phase()
	if ph != Step.TARGET and ph != Step.FREE:
		return
	if _selected_uid == -1:
		return
	var actor := _combat.by_uid(_selected_uid)
	if actor == null:
		return
	if ph == Step.TARGET:
		var expected := _teaching_target(_teaching_actor())
		if expected == null or uid != expected.uid:
			return
	_combat.use_die(_selected_uid, uid)
	_selected_uid = -1
	_render()


func _on_end_turn_pressed() -> void:
	var ph := _phase()
	if ph != Step.ENDTURN and ph != Step.FREE:
		return
	_combat.end_turn()
	_selected_uid = -1
	_render()


func _on_reward_pressed(idx: int) -> void:
	if _phase() != Step.REWARD:
		return
	if idx < 0 or idx >= _REWARD_FLAVORS.size():
		return
	_finished_reason = "reward_taken"
	_manual_step = 8
	_render()


## Split from _on_finish_pressed() so a test can exercise "the tutorial is now recorded as
## seen" without also triggering the real scene change (which would tear down the running test
## scene's own tree, since Tutorial.tscn's root is a child of whatever scene the test harness
## instantiated it under, not the SceneTree's actual current_scene when run this way).
func _finish_tutorial() -> void:
	MetaState.tutorial_seen = true
	MetaState.save_to_disk()


func _on_finish_pressed() -> void:
	_finish_tutorial()
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")


# ===========================================================================
# Render — single "read model, redraw" entry point (same discipline CombatView.gd's own
# _rebuild_all() comment describes), called after every handler above.
# ===========================================================================

func _render() -> void:
	var ph := _phase()

	_big_overlay.visible = ph in [Step.WELCOME, Step.DONE, Step.LOST]
	if ph == Step.WELCOME:
		_big_title.text = "Welcome to Axie Dice Tactics!"
		_big_body.text = "Every Axie is a die, and every face is a real body part. Let's play one battle together before you're on your own."
		_big_button.text = "START"
		_disconnect_big_button()
		_big_button.pressed.connect(_on_start_pressed)
	elif ph == Step.DONE:
		_big_title.text = "Nice work — you're ready."
		_big_body.text = "That's the whole loop: roll, read the enemy, reroll if you need to, act, then pick a reward. Everything else you'll pick up as you play."
		_big_button.text = "START PLAYING"
		_disconnect_big_button()
		_big_button.pressed.connect(_on_finish_pressed)
	elif ph == Step.LOST:
		_big_title.text = "That fight didn't go your way."
		_big_body.text = "That shouldn't happen in this tutorial — let's just get you into the real game."
		_big_button.text = "CONTINUE"
		_disconnect_big_button()
		_big_button.pressed.connect(_on_finish_pressed)

	_intent_panel.visible = _intent_open
	if _intent_open and _intent_enemy_idx >= 0 and _intent_enemy_idx < _combat.enemies.size():
		var e: Unit = _combat.enemies[_intent_enemy_idx]
		_intent_label.text = _intent_text(e)

	for i in _enemy_buttons.size():
		var b := _enemy_buttons[i]
		if i < _combat.enemies.size():
			var e2: Unit = _combat.enemies[i]
			b.visible = true
			b.text = "%s\nHP %d/%d" % [e2.n if e2.n != "" else e2.key, e2.hp, e2.max_hp]
			b.disabled = (ph != Step.INTENT) or e2.hp <= 0
		else:
			b.visible = false

	for i in _die_buttons.size():
		var b3 := _die_buttons[i]
		if i >= _combat.party.size():
			b3.visible = false
			continue
		var u: Unit = _combat.party[i]
		b3.visible = true
		b3.text = _die_label(u)
		var selectable := u.hp > 0 and u.has_rolled() and not u.roll_used()
		var enabled := false
		if ph == Step.DIE:
			var taught := _teaching_actor()
			enabled = selectable and taught != null and u.uid == taught.uid
		elif ph == Step.FREE:
			enabled = selectable
		b3.disabled = not enabled
		b3.button_pressed = (u.uid == _selected_uid)

	_reroll_button.disabled = not ((ph == Step.REROLL or ph == Step.FREE) and _combat.rerolls > 0)
	_end_turn_button.disabled = not (ph == Step.ENDTURN or ph == Step.FREE)
	_got_it_button.visible = (ph == Step.ROLL)

	_reward_row.visible = (ph == Step.REWARD)
	for rb in _reward_buttons:
		rb.disabled = (ph != Step.REWARD)

	# Target buttons (enemy row doubles as the target-click surface at TARGET/FREE too — a
	# second connection would stack handlers, so target clicks route through the SAME enemy
	# button objects via _enemy_or_target_pressed() rerouting below instead of a second row).
	for i in _enemy_buttons.size():
		if i >= _combat.enemies.size():
			continue
		var b4 := _enemy_buttons[i]
		var e3: Unit = _combat.enemies[i]
		if ph == Step.TARGET or ph == Step.FREE:
			var can_target := e3.hp > 0 and _selected_uid != -1
			if ph == Step.TARGET:
				var expected := _teaching_target(_teaching_actor())
				can_target = can_target and expected != null and expected.uid == e3.uid
			b4.disabled = not can_target

	if not (ph in [Step.ROLL, Step.INTENT, Step.REROLL, Step.DIE, Step.TARGET, Step.ENDTURN, Step.REWARD]):
		_coach_panel.visible = false
	else:
		_coach_panel.visible = true
		_set_coach_text(ph)


func _set_coach_text(ph: int) -> void:
	match ph:
		Step.ROLL:
			_coach_title.text = "Your 5 Axies just rolled"
			_coach_body.text = "Every face is a real body part on that Axie."
		Step.INTENT:
			_coach_title.text = "The enemy shows its hand"
			_coach_body.text = "Click an enemy — you'll see exactly what it's about to do."
		Step.REROLL:
			_coach_title.text = "Not happy with that roll?"
			_coach_body.text = "Press REROLL — in this tutorial it re-rolls every die."
		Step.DIE:
			_coach_title.text = "Click this die"
			_coach_body.text = "The highlighted die is the only one you can click right now."
		Step.TARGET:
			_coach_title.text = "Now pick a target"
			_coach_body.text = "Click the highlighted enemy to use it."
		Step.ENDTURN:
			_coach_title.text = "The enemy acts out exactly what it showed"
			_coach_body.text = "Press END TURN."
		Step.REWARD:
			_coach_title.text = "Pick 1 of 3"
			_coach_body.text = "All three are good picks — this is where you start shaping your build."


func _die_label(u: Unit) -> String:
	if u.hp <= 0:
		return "%s\nDEAD" % u.n
	if not u.has_rolled():
		return "%s\n(not rolled)" % u.n
	if u.roll_used():
		return "%s\nSPENT" % u.n
	var f := u.current_face()
	# The LIVE value — see CombatView._live_face_value(). The tutorial runs a real
	# CombatEngine, so its party grows every turn like any other, and a lesson that shows one
	# number and deals another is teaching the wrong thing.
	var live := _combat._face_value(u, u.roll_face_index()) if _combat != null \
		else int(f.get("value", 0))
	return "%s\n%s · %d" % [u.n, String(f.get("type", "")).to_upper(), live]


func _intent_text(e: Unit) -> String:
	if e.intent.is_empty():
		return "%s has no move ready yet." % e.n
	var fi := int(e.intent.get("face_index", -1))
	if fi < 0 or fi >= e.die.size():
		return "%s's move is unclear." % e.n
	var f: Dictionary = e.die[fi]
	var target_uid := int(e.intent.get("target_uid", -1))
	var target_name := "no one"
	if target_uid >= 0:
		var t := _combat.by_uid(target_uid)
		if t != null:
			target_name = t.n
	return "%s will use %s (%d) on %s." % [
		e.n, String(f.get("type", "")).to_upper(),
		(_combat._face_value(e, fi) if _combat != null else int(f.get("value", 0))),
		target_name]


func _disconnect_big_button() -> void:
	for c in _big_button.pressed.get_connections():
		_big_button.pressed.disconnect(c["callable"])
