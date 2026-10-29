extends Node
## QA-only (UI-05 b1 QA): where U5Moments.head() puts the hit tag / number for each unit of a real fight, and a shot
## right after a hit on an enemy. Prints QA_HEAD uid side name head=(x,y) height=h raw=(x,y).
##   QA_KIND=battle|boss godot/tools/shot.sh res://tests/qa_ui5_head_probe.tscn 1920x1080

const U := preload("res://tests/qa_ui5_util.gd")
var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	UI3Theme.set_scale_override(1.0)
	var kind := OS.get_environment("QA_KIND") if OS.get_environment("QA_KIND") != "" else "battle"
	MetaState.runs = 10
	MetaState.runs_with_battle = 99
	MetaState.runs_completed = 10
	RunState.start_new_run(424242, RunBot.DEFAULT_TEAM, "short", 0, false)
	await get_tree().process_frame
	RunState.power_level = 9 if kind == "boss" else 4
	RunState.enter_node("r12_c0" if kind == "boss" else "r5_c0", kind)
	var v: CombatView = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(v)
	for _i in 400:
		await get_tree().process_frame
		if v._combat != null and not v._is_animating and not v._dice_in_air() and v._combat.phase == CombatEngine.CombatPhase.EXECUTE:
			break
	await get_tree().create_timer(4.0).timeout   # bands gone
	var c: CombatEngine = v._combat
	var st: CombatStage3D = v._stage3d
	for u in c.party + c.enemies:
		var h: float = CombatStage3D.AXIE_HEAD_HEIGHT if u.side == "p" else st.head_height_of(u.uid, CombatStage3D.HEAD_HEIGHT)
		print("QA_HEAD uid=%d side=%s name=%s head=%s height=%.2f raw=%s" % [u.uid, u.side, u.n,
			str(U5Moments.head(v, u.uid)), h, str(st.get_unit_screen_pos(u.uid, h))])
	# One attack on the first enemy, shot just after the impact.
	var units: Array = v._party_dice_units()
	var tgt: Unit = c.alive_enemies()[0]
	for i in units.size():
		var u: Unit = units[i]
		if u.hp > 0 and u.has_rolled() and not u.roll_used() and String(u.die[u.roll_face_index()].get("type", "")) == "dmg":
			v._on_die_slot_pressed(i)
			v._on_target_clicked(tgt.uid)
			break
	for k in 40:
		await get_tree().process_frame
		if k == 14 or k == 28:
			U.save(get_viewport(), "head-%s-hit-f%d" % [kind, k])
			for line in U.clip_audit(v.get_node("Ui5Moments"), get_viewport().get_visible_rect()):
				print("QA_CLIP f%d | %s" % [k, line])
			var r := v.get_node_or_null("Ui5Moments/Root")
			if r != null:
				for ch in r.get_children():
					if ch is Control:
						print("QA_MOMENT f%d %s pos=%s" % [k, ch.name, str((ch as Control).global_position)])
	UI3Theme.set_scale_override(-1.0)
	_guard.restore()
	get_tree().quit(0)
