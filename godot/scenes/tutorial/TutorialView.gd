extends Control
class_name TutorialView
## Mandatory onboarding tutorial (design/gdd/onboarding-tutorial.md), Godot port.
##
## WHAT CHANGED, 21 Sep 2026. This screen used to be a self-contained rehearsal: a real
## CombatEngine driven through a small hand-built board of its own, because retrofitting a
## step-lock into the production combat screen was out of that task's scope. The result taught
## the rules on a screen the player never sees again, and looked nothing like the game.
##
## It now does what the web build always did: it teaches ON the real screen. Combat.tscn is
## instanced as-is — the same dice tray, the same 3D stage, the same intent badges — and
## everything the tutorial adds sits ABOVE it in TutorialCoach.gd (the dim, the spotlight, the
## card). The two hooks this needs from CombatView.gd are documented there next to `_tutorial`:
## a flag that stops the screen writing a result anywhere, and a per-step gate on its input
## handlers.
##
## ISOLATION (design doc §3.1's "must not reach S.phase==='won'" / no leaderboard submit) is
## unchanged and is now enforced on CombatView's side: in tutorial mode it never calls
## RunState.apply_combat_result(), never writes the CONTINUE RUN slot, never changes scene, and
## logs into an ActionLog of its own rather than the run's. This file's only write to global
## state is RunState.pending_combat, which Combat.tscn consumes and clears in its own _ready().
##
## STEP MODEL: unchanged in shape from the previous pass and from client.html's tutStep/
## tutPhase() split — most steps are DERIVED fresh from live combat state every tick (so
## nothing can desync from the real board), and only the handful with no combat-state signature
## of their own (WELCOME, PARTY, INTENT, reward-taken) are tracked by `_manual_step`.
##
## THE LOCK IS IN TWO PLACES ON PURPOSE. The coach's dim is four click-blocking bands around
## the lit rectangle, so what the player can see is exactly what they can press. That is the
## visible lock. The one that has to hold is CombatView._gated(), because Space, Escape and
## CombatStage3D's own unit_clicked path never travel through the overlay at all.
## t_tutorial_flow.gd presses the handlers directly, bypassing the overlay, to prove it.

enum Step { WELCOME, PARTY, INTENT, REROLL, DIE, TARGET, ENDTURN, FREE, REWARD, DONE, LOST }

# --- Fixture tuning. LOCKED once shipped, same as the JS TUT_SEED/TUT_TEAM/TUT_ENEMY_HP —
# changing the seed changes the first roll shown to every new player.
const TUT_SEED := 3
const TUT_TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bird1"]
const TUT_ENEMY_HP := 6

const _REWARD_FLAVORS := [
	{"title": "+3 Max HP", "desc": "A sturdier Axie survives more turns."},
	{"title": "New Relic", "desc": "A passive effect that helps your whole team."},
	{"title": "Gene Shard x20", "desc": "Currency to unlock permanent upgrades between runs."},
]

## Total coached steps, for the "STEP n OF N" line on the card. FREE and the end screens are
## not counted: by then the tutorial has stopped telling the player what to do.
const _COACHED_STEPS := 6

var _view: Node2D = null            # the real Combat.tscn
var _combat: CombatEngine = null    # its engine, read-only from here
var _coach: TutorialCoach = null

var _manual_step: int = 0   # 0=welcome, 1=party, 2=intent, 3=auto, 8=reward taken
var _outcome: int = -1      # -1 still fighting, 0 lost, 1 won
var _max_rerolls: int = 0
var _last_phase: int = -1
var _ready_done: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_coach = TutorialCoach.new()
	_coach.cta_pressed.connect(_on_cta_pressed)
	_coach.reward_chosen.connect(_on_reward_pressed)
	_coach.skip_pressed.connect(_on_skip_pressed)
	add_child(_coach)
	await _build_combat()
	_ready_done = true
	_render(true)


## Boots the production combat screen inside this one. `tutorial: true` is the whole contract —
## see CombatView's `_tutorial` comment for the three things it turns off.
func _build_combat() -> void:
	RunState.pending_combat = {
		"node_id": "tutorial", "kind": "battle", "pw": 0, "ascension": 0,
		"combat_seed": TUT_SEED, "roster_snapshot": _roster_snapshot(),
		"relic_ids": [], "tutorial": true,
	}
	_view = load("res://scenes/combat/Combat.tscn").instantiate() as Node2D
	add_child(_view)
	move_child(_coach, get_child_count() - 1)   # the coach stays on top of the board
	# Two frames: one for Combat's own _ready(), one for the deck bar to have a real size (the
	# coach's first spotlight measures a Control, and an unlaid-out one measures zero).
	await get_tree().process_frame
	await get_tree().process_frame
	_combat = _view.get("_combat") as CombatEngine
	_max_rerolls = int(_view.get("_max_rerolls"))
	if _combat != null:
		# A short fight: the taught hit lands, the enemy answers once, and free play finishes
		# it within a turn or two instead of making a first-time player grind a full wave.
		for e in _combat.enemies:
			e.hp = TUT_ENEMY_HP
			e.max_hp = TUT_ENEMY_HP
		_view.call("_rebuild_all")
	_view.connect("tutorial_combat_finished", _on_combat_finished)
	_view.call("set_tutorial_gate", Callable(self, "_allows"))


func _roster_snapshot() -> Array:
	var out: Array = []
	for i in TUT_TEAM.size():
		out.append({"persistent_id": i + 1, "hero_key": TUT_TEAM[i], "tier": 1, "max_hp": 0,
			"muts": [], "growth": {}, "bonus_hp": 0})
	return out


# ===========================================================================
# Step derivation — port of client.html's tutPhase()/tutActor()
# ===========================================================================

func _phase() -> int:
	if _manual_step == 0:
		return Step.WELCOME
	if _manual_step == 1:
		return Step.PARTY
	if _manual_step == 2:
		return Step.INTENT
	if _manual_step >= 8:
		return Step.DONE
	if _combat == null:
		return Step.FREE
	if _outcome == 0 or _combat.lost:
		return Step.LOST
	if _outcome == 1 or _combat.won:
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
	return Step.TARGET if int(_view.get("_selected_die_uid")) == actor.uid else Step.DIE


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
## back to self-target — a safe default this fixture's fixed seed does not exercise, kept so a
## future reseed cannot silently point the coaching arrow at an illegal target.
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


## Which die slot the taught actor occupies — the slots are CombatView's own ordering
## (`_party_dice_units()`), not `_combat.party`'s, and the gate key is the SLOT index.
func _slot_of(u: Unit) -> int:
	if u == null or _view == null:
		return -1
	var units: Array = _view.call("_party_dice_units")
	for i in units.size():
		if (units[i] as Unit).uid == u.uid:
			return i
	return -1


# ===========================================================================
# Tick — the derived step is re-read every frame, and the screen is only redrawn when it moves
# ===========================================================================

func _process(_delta: float) -> void:
	if not _ready_done:
		return
	var ph := _phase()
	if ph != _last_phase:
		_render(false)


func _on_combat_finished(won: bool) -> void:
	_outcome = 1 if won else 0
	_render(false)


# ===========================================================================
# Input — the coach only ever sends these three, and each re-checks the step itself
# ===========================================================================

## The card's single button. Which step it belongs to decides what it does, and each branch
## re-checks the step rather than trusting the caller (same defense-in-depth as every handler
## in the previous pass — t_tutorial_flow.gd calls these directly to prove it).
func _on_cta_pressed() -> void:
	match _phase():
		Step.WELCOME:
			_manual_step = 1
		Step.PARTY:
			_manual_step = 2
		Step.INTENT:
			_manual_step = 3
		Step.DONE, Step.LOST:
			_on_finish_pressed()
			return
		_:
			return
	_render(false)


func _on_reward_pressed(idx: int) -> void:
	if _phase() != Step.REWARD:
		return
	if idx < 0 or idx >= _REWARD_FLAVORS.size():
		return
	_manual_step = 8
	_render(false)


func _on_skip_pressed() -> void:
	_on_finish_pressed()


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
# Render — one "read model, redraw" entry point. Sets the coach's card AND the combat screen's
# input gate from the same step value, so what is lit and what is pressable cannot disagree.
# ===========================================================================

func _render(_first: bool) -> void:
	var ph := _phase()
	_last_phase = ph
	match ph:
		Step.WELCOME:
			_coach.show_curtain("Welcome to Axie Dice!",
				"Every Axie is a die, and every face is a real body part. "
				+ "Let's play one battle together before you're on your own.",
				"START")
		Step.PARTY:
			_coach.show_step(_label(1), "These five are your team",
				"Each card is one Axie's die, showing the face it just rolled: the body part, "
				+ "what it does, and for how much.",
				"GOT IT →", _dice_tray())
		Step.INTENT:
			_coach.show_step(_label(2), "The enemy shows its hand",
				"That badge above its head is exactly what it will do on its turn. You always "
				+ "get to see it coming.",
				"GOT IT →", null, _enemy_rect())
		Step.REROLL:
			_coach.show_step(_label(3), "Not happy with that roll?",
				"Press REROLL. It re-rolls every die you haven't used yet, and you get a few "
				+ "of these each turn.",
				"", _node("_reroll_button"))
		Step.DIE:
			_coach.show_step(_label(4), "Pick this die",
				"It rolled an attack face. Click it to pick it up. The highlighted one is the "
				+ "only card you can press right now.",
				"", _die_slot(_slot_of(_teaching_actor())))
		Step.TARGET:
			_coach.show_step(_label(5), "Now click the enemy",
				"That spends the die and lands the hit. Every attack works this way: pick a "
				+ "die, then pick who it goes to.",
				"", null, _enemy_rect())
		Step.ENDTURN:
			_coach.show_step(_label(6), "Your move is done",
				"Press END TURN and the enemy acts out exactly what its badge showed.",
				"", _node("_end_turn_button"))
		Step.FREE:
			_coach.show_step("", "Over to you",
				"That's the whole loop. Finish the fight. Everything on this screen is "
				+ "yours now.", "", null, _free_hint_rect(), false)
		Step.REWARD:
			_coach.show_rewards("You won. Pick one.",
				"All three are good picks. This is where you start shaping your build.",
				_REWARD_FLAVORS)
		Step.DONE:
			_coach.show_curtain("Nice work. You're ready.",
				"Roll, read the enemy, reroll if you need to, act, then pick a reward. "
				+ "Everything else you'll pick up as you play.",
				"START PLAYING")
		Step.LOST:
			_coach.show_curtain("That fight didn't go your way.",
				"That shouldn't happen in the tutorial, so let's just get you into the real game.",
				"CONTINUE")


func _label(n: int) -> String:
	return "STEP %d OF %d" % [n, _COACHED_STEPS]


## THE STEP-LOCK. CombatView calls this on every interaction, with a key naming what the
## player just pressed — "reroll", "end_turn", "die:<slot>", "target:<uid>", "undo", "active".
## The answer is derived from _phase() on the spot, never from what the coach last drew: the
## coach redraws a frame after the state that moved the step, and a lock made of that snapshot
## would spend one frame enforcing the previous step.
##
## Everything not named here is refused, which is the right default — a step that forgets to
## list an interaction locks it rather than leaking it.
func _allows(key: String) -> bool:
	match _phase():
		Step.REROLL:
			return key == "reroll"
		Step.DIE:
			var slot := _slot_of(_teaching_actor())
			return slot >= 0 and key == "die:%d" % slot
		Step.TARGET:
			# The taught die stays pressable so the player can put it back down; everything
			# else on the board is still locked to the one legal target.
			var tgt := _teaching_target(_teaching_actor())
			if tgt != null and key == "target:%d" % tgt.uid:
				return true
			var slot2 := _slot_of(_teaching_actor())
			return slot2 >= 0 and key == "die:%d" % slot2
		Step.ENDTURN:
			return key == "end_turn"
		Step.FREE:
			return true
	return false


## A private Control on the combat screen, by field name. Kept in one place so the coupling to
## CombatView's internals is a short, greppable list rather than scattered `.get()` calls.
func _node(field: String) -> Control:
	if _view == null:
		return null
	var c = _view.get(field)
	return c as Control if c is Control else null


## The five die cards as one block — the dice tray, not the whole deck bar. Lighting the bar
## would also light the mana well, the relic rack and the two action buttons, none of which
## this step is talking about. Reached through a slot's parent rather than by node path so it
## survives Combat.tscn being re-laid-out.
func _dice_tray() -> Control:
	var first := _die_slot(0)
	return first.get_parent() as Control if first != null else _node("_deck_bar_panel")


func _die_slot(index: int) -> Control:
	if _view == null or index < 0:
		return null
	var slots = _view.get("_die_slot_buttons")
	if slots is Array and index < (slots as Array).size():
		return (slots as Array)[index] as Control
	return null


## The enemy's own column, as a rectangle: its intent badge and nameplate sit at a fixed y near
## the top of the stage and the creature hangs below them, so the lit area has to run from the
## badge down to the front line — the plate alone would leave the body the player is being told
## to click sitting in the dark, outside the hole, unclickable.
func _enemy_rect() -> Rect2:
	if _combat == null or _view == null:
		return Rect2()
	var target := _teaching_target(_teaching_actor())
	if target == null:
		for e in _combat.enemies:
			if e.hp > 0:
				target = e
				break
	if target == null:
		return Rect2()
	var box := Rect2()
	for field in ["_head_huds", "_portraits"]:
		var d = _view.get(field)
		if not (d is Dictionary):
			continue
		var c = (d as Dictionary).get(target.uid)
		if c is Control and (c as Control).is_visible_in_tree():
			var r := (c as Control).get_global_rect()
			box = r if box.size == Vector2.ZERO else box.merge(r)
	if box.size == Vector2.ZERO:
		return Rect2()
	var line := _node("_front_line")
	var bottom: float = line.global_position.y if line != null else box.end.y
	box = box.grow_individual(46.0, 6.0, 46.0, maxf(bottom - box.end.y, 0.0))
	return box


## FREE play dims nothing — but the card still has to sit somewhere sensible, so it is placed
## against the top-left of the board rather than beside a spotlight.
func _free_hint_rect() -> Rect2:
	return Rect2(24.0, 70.0, 1.0, 1.0)
