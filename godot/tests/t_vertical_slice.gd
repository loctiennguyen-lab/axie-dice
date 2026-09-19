extends Node
## Headless "play one full combat start-to-finish" gate (architecture plan §3/§8:
## "headless log mode" for DevReview, built as a test first). Drives CombatEngine with a
## simple always-legal-action bot, connects every EventBus gameplay signal and prints them,
## and asserts the encounter reaches combat_finished with sane numbers (no NaN, no negative
## HP, no runaway turn count).
##
## Implemented as a scene (t_vertical_slice.tscn) run via `godot --headless --path godot
## tests/t_vertical_slice.tscn`, NOT a raw `--script` SceneTree override — see the comment
## at the top of t_combat_roundtrip.gd for why (autoload singletons aren't resolvable as
## bare compile-time identifiers in `--script` mode; a normal scene's `_ready()` doesn't
## have that problem).

const MAX_TURNS := 200

var _combat: CombatEngine
var _finished := false
var _final_won := false
var _event_count := 0
var _anomaly := ""


func _ready() -> void:
	EventBus.hp_changed.connect(_on_hp_changed)
	EventBus.hit_landed.connect(_on_hit_landed)
	EventBus.unit_died.connect(_on_unit_died)
	EventBus.face_used.connect(_on_face_used)
	EventBus.resonance_triggered.connect(_on_resonance)
	EventBus.float_text.connect(_on_float_text)
	EventBus.enemy_intent_executed.connect(_on_enemy_intent)
	EventBus.status_tick.connect(_on_status_tick)
	EventBus.turn_phase_changed.connect(_on_turn_phase_changed)
	EventBus.combat_finished.connect(_on_combat_finished)

	_combat = CombatEngine.new()
	_combat.setup_new({
		"node_id": "vslice_node",
		"kind": "battle",
		"pw": 2,
		"ascension": 0,
		"roster_snapshot": _synthetic_roster(),
		"relic_ids": [],
		"combat_seed": 424242,
	})
	print("=== t_vertical_slice: combat start ===")
	print("party: %s" % _describe_units(_combat.party))
	print("enemies: %s" % _describe_units(_combat.enemies))

	var turns := 0
	while not _finished and turns < MAX_TURNS:
		_play_one_turn()
		turns += 1

	print("=== t_vertical_slice: combat end after %d turn(s) ===" % turns)
	print("final party: %s" % _describe_units(_combat.party))
	print("final enemies: %s" % _describe_units(_combat.enemies))
	print("stat: %s" % JSON.stringify(_combat.stat))

	var ok := _finished and _anomaly == "" and turns < MAX_TURNS
	if not _finished:
		_anomaly = "combat never reached combat_finished within %d turns" % MAX_TURNS
	if ok:
		print("t_vertical_slice: PASS — combat_finished(won=%s) after %d turn(s), %d event(s) observed, no anomalies" % [_final_won, turns, _event_count])
		get_tree().quit(0)
	else:
		print("t_vertical_slice: FAIL — %s" % _anomaly)
		get_tree().quit(1)


func _play_one_turn() -> void:
	# Bot: keep using any legal die on any legal target until nothing more can be used,
	# preferring damage faces against the first alive enemy and support faces on self.
	var guard := 0
	while guard < 64:
		guard += 1
		var acted := false
		for u in _combat.party.duplicate():
			if u.hp <= 0 or not u.has_rolled() or u.roll_used():
				continue
			var fi: int = u.roll_face_index()
			var f: Dictionary = u.die[fi]
			var face_type := String(f.get("type", ""))
			var tgt_uid := -1
			if face_type in ["dmg", "poison", "debuff"]:
				var es: Array = _combat.alive_enemies()
				if es.size() > 0:
					tgt_uid = es[0].uid
			elif face_type in ["shield", "heal", "buff"]:
				tgt_uid = u.uid
			else:
				tgt_uid = u.uid
			if _combat.use_die(u.uid, tgt_uid):
				acted = true
		if not acted:
			break
	_combat.end_turn()


func _synthetic_roster() -> Array:
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var out: Array = []
	for i in keys.size():
		out.append({
			"persistent_id": i + 1,
			"hero_key": keys[i],
			"tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"],
			"muts": [],
			"growth": {},
			"bonus_hp": 0,
		})
	return out


func _describe_units(units: Array) -> String:
	var parts: Array = []
	for u in units:
		parts.append("%s#%d[hp=%d/%d,sh=%d]" % [u.key, u.uid, u.hp, u.max_hp, u.shield])
	return ", ".join(parts)


func _check_numeric_sanity(uid: int, hp: int, max_hp: int, shield: int) -> void:
	if hp < 0 or shield < 0 or max_hp <= 0 or is_nan(hp) or is_nan(shield):
		_anomaly = "unit %d has invalid numbers hp=%s max_hp=%s shield=%s" % [uid, hp, max_hp, shield]


func _on_hp_changed(uid: int, hp: int, max_hp: int, shield: int) -> void:
	_event_count += 1
	_check_numeric_sanity(uid, hp, max_hp, shield)
	print("[hp] uid=%d hp=%d/%d shield=%d" % [uid, hp, max_hp, shield])

func _on_hit_landed(src_uid: int, uid: int, value: int, crit: bool) -> void:
	_event_count += 1
	if value < 0:
		_anomaly = "negative hit value %d on uid=%d" % [value, uid]
	print("[hit] src=%d -> uid=%d value=%d crit=%s" % [src_uid, uid, value, crit])

func _on_unit_died(uid: int) -> void:
	_event_count += 1
	print("[death] uid=%d" % uid)

func _on_face_used(uid: int, side: String, target_uid: int, aoe: bool, face_part: String, face_name: String, face_type: String) -> void:
	_event_count += 1
	print("[use] uid=%d side=%s tgt=%d aoe=%s part=%s type=%s" % [uid, side, target_uid, aoe, face_part, face_type])

func _on_resonance(uid: int) -> void:
	_event_count += 1
	print("[resonance] uid=%d" % uid)

func _on_float_text(uid: int, text: String, css_class: String, big: int) -> void:
	_event_count += 1
	print("[ft] uid=%d text=%s class=%s" % [uid, text, css_class])

func _on_enemy_intent(uid: int) -> void:
	_event_count += 1
	print("[eact] uid=%d" % uid)

func _on_status_tick(statuses: PackedStringArray) -> void:
	_event_count += 1
	print("[tick] %s" % ", ".join(statuses))

func _on_turn_phase_changed(old_phase: int, new_phase: int) -> void:
	print("[phase] %d -> %d" % [old_phase, new_phase])

func _on_combat_finished(won: bool) -> void:
	_finished = true
	_final_won = won
	print("[combat_finished] won=%s" % won)
