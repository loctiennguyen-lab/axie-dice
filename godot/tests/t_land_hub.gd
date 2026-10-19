extends Node
## Gate for the Land hub scene: it builds, every house is a clickable box routed through LandNav
## (never a direct change_scene), locked plots never navigate, keys 1-9 map to the shortcut bar.
## Run: godot --headless --path godot res://tests/t_land_hub.tscn

var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)
		printerr("FAIL: ", msg)


var _save_guard := SaveGuard.new()


func _ready() -> void:
	print("=== t_land_hub: start ===")
	_save_guard.capture()   # Land discards unresumable run saves
	var seen_was := MetaState.tutorial_seen
	MetaState.tutorial_seen = true      # in memory only
	LandNav.dry_run = true
	LandHub.qa = {"guest": false}   # signed in: Start run goes to Run Setup (signed out = "Sign in to play")
	var hub := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate() as LandHub
	add_child(hub)
	await get_tree().process_frame
	await get_tree().process_frame

	for id in ["portal", "house", "missions", "echobox", "pass", "vault", "store", "board"]:
		_check(hub.find_child("Hit_" + id, true, false) != null, "thiếu hộp bấm cho " + id)
	_check(hub.find_child("Hit_mastery", true, false) == null, "Mastery Hall đã bỏ")
	_check(hub.find_child("Plot_gallery", true, false) != null, "thiếu ô đất Gallery")
	_check(hub.call("_block_reason", "gallery") == "Opens at Land tier 5", "Gallery khoá ghi Opens at Land tier 5")
	var moon_btn := hub.find_child("MoonCardButton", true, false) as Button
	_check(moon_btn != null and moon_btn.disabled and "Coming soon" in moon_btn.text, "Moon Card: nút tắt, Coming soon")
	# UI-03: the dock is gone; every place is reached by its world label (hit box + key), focusable.
	for id in ["house", "missions", "vault", "echobox", "pass", "store"]:
		_check((hub.find_child("Hit_" + id, true, false) as Control).focus_mode == Control.FOCUS_ALL, "hộp bấm %s phải focus được" % id)
	for n in ["ProfileChip", "Rail_Daily", "Codex", "Wallet", "Currencies", "HudBottomLeft", "HudBottomRight", "Settings"]:
		_check(hub.find_child(n, true, false) != null, "thiếu " + n)
	# No name plates, status pills or Names toggle: the name lives in a tooltip (hover / focus / first tap).
	for id in ["portal", "house", "missions", "echobox", "pass", "vault", "store", "board"]:
		_check(hub.find_child("Sign_" + id, true, false) == null, "không còn biển tên " + id)
		var hit := hub.find_child("Hit_" + id, true, false) as Control
		var tip := UI3Tooltip.text_of(hit)
		_check(tip.begins_with(String(LandHub.META[id]["name"])), "tooltip %s bắt đầu bằng tên: %s" % [id, tip])
		_check(String(LandHub.META[id]["key"]) in tip.split("\n")[0], "tooltip %s có phím" % id)
	_check(hub.find_child("NamesToggle", true, false) == null, "không còn nút Show names")
	_check(UI3Tooltip.text_of(hub.find_child("Plot_gallery", true, false) as Control).contains("Opens at Land tier 5"),
		"ô Gallery: tooltip ghi lý do khoá")
	_check(hub.get("_badges") == null, "không còn chip trạng thái")
	_check((hub.find_child("Settings", true, false) as Control).get_parent().get_parent() == hub.find_child("Wallet", true, false),
		"Settings nằm chung plate với tiền")

	# has_modal(): what holds back AccountService's rebuild. A touch sign preview must not.
	_check(not hub.has_modal(), "has_modal: false khi không có panel nào")
	var note := Node.new()
	note.name = NetNotice.NODE_NAME
	hub.add_child(note)
	_check(hub.has_modal(), "has_modal: NetNotice đang mở")
	hub.remove_child(note)
	note.free()
	_check(not hub.has_modal(), "has_modal: hết NetNotice thì false")
	var moon := Node.new()
	hub.add_child(moon)
	hub.set("_moon_card", moon)
	_check(hub.has_modal(), "has_modal: Moon Card popup đang mở")
	moon.queue_free()
	await get_tree().process_frame
	_check(not hub.has_modal(), "has_modal: Moon Card đóng thì false")
	hub.set("_touch_id", "pass")
	_check(not hub.has_modal(), "has_modal: biển xem trước trên touch không giữ rebuild")
	hub.set("_touch_id", "")

	# House -> screen through LandNav.
	LandNav.last_path = ""
	(hub.find_child("Hit_pass", true, false) as Button).emit_signal("pressed")
	_check(LandNav.last_path == "res://scenes/pass/Pass.tscn", "Pass path: " + LandNav.last_path)
	LandNav.last_path = ""
	(hub.find_child("Hit_vault", true, false) as Button).emit_signal("pressed")
	_check(LandNav.last_path == "res://scenes/vault/Vault.tscn", "Vault path: " + LandNav.last_path)
	LandNav.last_path = ""
	(hub.find_child("Hit_house", true, false) as Button).emit_signal("pressed")
	_check(LandNav.last_path == "res://scenes/team_presets/TeamPresets.tscn", "House path: " + LandNav.last_path)
	# Shortcut 6 = Vault.
	LandNav.last_path = ""
	hub.call("_handle_key", KEY_6)
	_check(LandNav.last_path == "res://scenes/vault/Vault.tscn", "phím 6 phải mở Vault")
	# Key 8 is unused. B opens the Leaderboard (C6), except for a newcomer (locked). The hub's newcomer
	# flag comes from the real save, so set it here instead of trusting the machine's save.
	LandNav.last_path = ""
	hub.call("_handle_key", KEY_8)
	_check(LandNav.last_path == "", "phím 8 không được điều hướng")
	var nc_was: bool = hub.get("_newcomer")
	hub.set("_newcomer", true)
	hub.call("_handle_key", KEY_B)
	_check(LandNav.last_path == "", "người mới: phím B không mở Leaderboard (khoá)")
	hub.set("_newcomer", false)
	hub.call("_handle_key", KEY_B)
	_check(LandNav.last_path == "res://scenes/leaderboard/Leaderboard.tscn", "phím B mở Leaderboard")
	LandNav.last_path = ""
	hub.set("_newcomer", nc_was)
	# Screens that do not exist yet are 'Coming soon', not a crash or a blank scene.
	LandNav.last_path = ""
	(hub.find_child("Hit_missions", true, false) as Button).emit_signal("pressed")
	_check(LandNav.last_path == "" or LandNav.is_available(&"missions"), "Missions chưa có màn thì không đổi scene")
	# Run plate -> run_setup when there is no open run.
	var plate := hub.find_child("RunPlate", true, false) as Button
	var newrun := hub.find_child("NewRunButton", true, false) as Control
	_check(plate != null and newrun != null, "thiếu RUN / New run")
	if plate != null and newrun != null:
		_check(not newrun.visible, "New run chỉ hiện khi có run dở")
		LandNav.last_path = ""
		plate.emit_signal("pressed")
		_check(LandNav.last_path == LandNav.resolve(&"run_setup"), "RUN phải mở run_setup")

	# Layout follows the window: plate centre x stays on the house centre at any height.
	var pass_plate := hub.find_child("Hit_pass", true, false) as Button
	_check(String((hub.META["pass"] as Dictionary)["sub"]).ends_with("29 Dec 2026"), "Pass sub-line phải ghi 29 Dec 2026")
	_check(absf(pass_plate.position.x + pass_plate.size.x * 0.5 - 1218.0) < 1.0, "hộp Pass lệch tâm x")

	hub.queue_free()
	await get_tree().process_frame

	# All six Lands build; Gallery is a plot until Genesis (5); newcomer locks Missions + Leaderboard.
	LandHub.qa = {"newcomer": true}
	for tier in range(1, 7):
		LandHub.tier_override = tier
		var h := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate() as LandHub
		add_child(h)
		await get_tree().process_frame
		_check((h.find_child("Hit_gallery", true, false) != null) == (tier >= 5), "tier %d: Gallery built" % tier)
		_check((h.find_child("Plot_gallery", true, false) != null) == (tier < 5), "tier %d: ô Gallery" % tier)
		_check((h.find_child("UpgradeLand", true, false) != null) == (tier < 6), "tier %d: nút Upgrade" % tier)
		_check((h.find_child("LandChip", true, false) != null) == (tier == 6), "tier %d: chip max tier" % tier)
		_check(h.find_child("Hit_portal", true, false) != null, "tier %d: thiếu Portal" % tier)
		LandNav.last_path = ""
		h.call("_handle_key", KEY_3)
		_check(LandNav.last_path == "", "tier %d: newcomer phải khoá Missions" % tier)
		h.queue_free()
		await get_tree().process_frame
	# States build: offline, guest, loading, first launch, mission run.
	for st in [{"offline": true, "guest": false}, {"guest": true, "first_launch": true}, {"loading": true}, {"newcomer": false, "run": true}]:
		LandHub.qa = st
		LandHub.tier_override = 2
		var h2 := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate() as LandHub
		add_child(h2)
		await get_tree().process_frame
		if st.has("offline"):
			_check((h2.find_child("OfflineBanner", true, false) as Control).visible, "banner offline")
			LandNav.last_path = ""
			h2.call("_handle_key", KEY_5)
			_check(LandNav.last_path == "", "offline: Pass không mở")
			var db := h2.find_child("Rail_Daily", true, false) as Button
			_check(db.disabled and "needs connection" in db.text, "offline: Daily tắt và ghi lý do")
			var rp := h2.find_child("RunPlate", true, false) as Button
			_check(rp.disabled and "needs connection" in rp.text, "offline: Start run tắt và ghi lý do (round 2)")
			_check("Needs a connection" in UI3Tooltip.text_of(h2.find_child("Hit_pass", true, false) as Control), "offline: tooltip Pass ghi lý do")
		if bool(st.get("guest", false)):
			_check((h2.find_child("RunPlate", true, false) as Button).text == "Sign in to play", "chưa đăng nhập: nút chính là Sign in to play")
			_check(not (h2.find_child("Currencies", true, false) as Control).visible, "chưa đăng nhập: ẩn tiền")
			_check(not (h2.find_child("Rail_Daily", true, false) as Control).visible, "lần đầu: ẩn Daily")
			_check(h2.call("_block_reason", "pass") == "Sign in to use" and h2.call("_block_reason", "store") == "Sign in to use", "chưa đăng nhập: ô online ghi Sign in to use")
			_check(h2.call("_block_reason", "board") != "Sign in to use", "chưa đăng nhập: Leaderboard vẫn đọc được")
			LandNav.last_path = ""
			(h2.find_child("RunPlate", true, false) as Button).emit_signal("pressed")
			_check(LandNav.last_path == "", "chưa đăng nhập: không vào Run Setup")
		if st.has("loading"):
			_check(String((h2.find_child("value_cur_shard", true, false) as Label).text) == "···", "loading: tiền hiện ···")
		h2.queue_free()
		await get_tree().process_frame
	# C4: "New run" on a Mission run settles the open stake as a loss (no refund, escrow cleared).
	var sp0 := MetaState.shard_pool
	var esc0 := MetaState.mission_escrow.duplicate(true)
	var led0 := MetaState.ledger.duplicate(true)
	MetaState.shard_pool = 4000
	MetaState.mission_escrow = {"tier": "N1", "mission_id": "ms_testc4", "stake": 300, "payout": 600, "stone": 0, "t": 1}
	LandHub.qa = {"newcomer": false}
	var h3 := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate() as LandHub
	h3.set("_force_run", true)
	add_child(h3)
	await get_tree().process_frame
	h3.call("_on_new_run_pressed")
	await get_tree().process_frame
	var okb := h3.find_child("ConfirmOk", true, false) as Button
	_check(okb != null, "C4: mission new-run opens the abandon confirm")
	_check(h3.find_child("Confirm", true, false) is UI3.ModalRoot, "UI3: the confirm is a UI3 modal (560 dialog, scrim)")
	_check(h3.find_child("Dialog", true, false).custom_minimum_size.x == 560.0, "UI3: confirm dialog 560 wide")
	if okb != null:
		_check(not MetaState.mission_escrow.is_empty(), "C4: escrow still open before confirming")
		okb.emit_signal("pressed")
		_check(MetaState.mission_escrow.is_empty(), "C4: escrow cleared after confirm")
		_check(MetaState.shard_pool == 4000, "C4: stake not refunded (pool unchanged)")
		var lost := false
		for l in MetaState.ledger:
			if String(l.get("r", "")) == "mission_loss_N1":
				lost = true
		_check(lost, "C4: mission counted as a loss in the ledger")
	h3.call("_show_toast", "one", 5.0)
	h3.call("_show_toast", "two", 5.0, &"error")
	await get_tree().process_frame
	var tl: Array = h3.get("_toasts")
	_check(tl.size() == 2 and is_equal_approx((tl[0] as Control).position.y, 24.0), "UI3: first toast 24 px from the top")
	_check(is_equal_approx((tl[1] as Control).position.y, 24.0 + (tl[0] as Control).size.y + 8.0), "UI3: toasts stack with an 8 px gap")
	_check(h3.find_child("LossRow", true, false) == null or (h3.find_child("LossRow", true, false) as Control).custom_minimum_size.y >= 48.0, "UI3: loss row at least 48 high")
	h3.queue_free()
	await get_tree().process_frame
	MetaState.shard_pool = sp0
	MetaState.mission_escrow = esc0
	MetaState.ledger = led0
	# Touch: first tap shows the sign (Open button), second tap opens.
	# Daily label carries the real tries left.
	LandHub.qa = {"guest": false, "newcomer": false, "first_launch": false, "daily_tries": {"used": 1, "max": 3}}
	var hd := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate() as LandHub
	add_child(hd)
	await get_tree().process_frame
	_check((hd.find_child("Rail_Daily", true, false) as Button).text == "Daily run · 2 of 3", "Daily ghi số lượt còn")
	hd.queue_free()
	await get_tree().process_frame
	LandHub.qa = {"touch": true, "newcomer": false, "guest": false}
	LandHub.tier_override = 1
	var ht := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate() as LandHub
	add_child(ht)
	await get_tree().process_frame
	LandNav.dry_run = true
	LandNav.last_path = ""
	(ht.find_child("Hit_vault", true, false) as Button).emit_signal("pressed")
	_check(LandNav.last_path == "" and ht.get("_touch_id") == "vault", "chạm 1 lần: chỉ hiện tooltip")
	(ht.find_child("Hit_vault", true, false) as Button).emit_signal("pressed")
	_check(LandNav.last_path == "res://scenes/vault/Vault.tscn", "chạm lần 2 mở Vault")
	_check((ht.find_child("Settings", true, false) as Control).custom_minimum_size.x >= 44.0, "Settings >= 44 px")
	# Mouse input switches touch mode off: click opens directly again.
	var mb := InputEventMouseButton.new()
	mb.pressed = true
	ht._input(mb)
	LandNav.last_path = ""
	(ht.find_child("Hit_pass", true, false) as Button).emit_signal("pressed")
	_check(LandNav.last_path == "res://scenes/pass/Pass.tscn", "chuột phải mở thẳng sau khi hết touch")
	# Touch latch: ScreenTouch -> on; emulated mouse keeps it; real mouse (device 0) clears it.
	var tt := InputEventScreenTouch.new()
	tt.pressed = true
	ht._input(tt)
	_check(ht.call("_is_touch"), "ScreenTouch bật touch")
	var em := InputEventMouseButton.new()
	em.pressed = true
	em.device = InputEvent.DEVICE_ID_EMULATION
	ht._input(em)
	_check(ht.call("_is_touch"), "chuột giả lập từ touch giữ touch")
	# Real input pipeline (viewport.push_input): tap on the sign button, then Open, then empty ground.
	LandNav.dry_run = true
	LandNav.last_path = ""
	ht.set("_touch_id", "")
	var vpt := ht.get_viewport()
	var hit := ht.find_child("Hit_vault", true, false) as Button
	var pt := hit.get_global_rect().get_center()
	await _tap(vpt, pt)
	_check(ht.get("_touch_id") == "vault" and LandNav.last_path == "", "pipeline: chạm 1 chỉ hiện biển")
	# A raw ScreenTouch reaching _unhandled_input must NOT close the sign (Controls never consume it).
	var raw := InputEventScreenTouch.new()
	raw.pressed = true
	ht._unhandled_input(raw)
	_check(ht.get("_touch_id") == "vault", "ScreenTouch thô không đóng biển")
	await _tap(vpt, pt)
	_check(ht.get("_touch_id") == "vault" and LandNav.last_path == "res://scenes/vault/Vault.tscn", "pipeline: chạm 2 mở Vault (không đóng biển)")
	LandNav.last_path = ""
	await _tap(vpt, Vector2(vpt.get_visible_rect().size.x * 0.5, 4.0))
	_check(ht.get("_touch_id") == "" and LandNav.last_path == "", "pipeline: chạm đất trống đóng biển")
	var rm := InputEventMouseButton.new()
	rm.pressed = true
	rm.device = 0
	ht._input(rm)
	_check(not ht.call("_is_touch"), "chuột thật tắt touch")
	ht.set("_touch_mode", true)
	# UI scale floor (~1.275 at 1280x720): HUD stays in the viewport and clear of the dock.
	ht.call("_place_hud", 1.275)
	var vp := Rect2(Vector2.ZERO, (ht.get("_ui") as Control).size)
	var groups := ["_hud_tl", "_hud_bl", "_hud_br", "_wallet"]
	var rects: Array[Rect2] = []
	for n in groups:
		var r := _srect(ht.get(n) as Control)
		_check(vp.encloses(r), "%s ra ngoài khung ở scale 1.275: %s" % [n, str(r)])
		for o in rects:
			_check(not r.intersects(o), "%s đè nhóm HUD khác ở scale 1.275" % n)
		rects.append(r)
	ht.queue_free()
	await get_tree().process_frame
	# Layout: every building, tree, rock, tuft and Axie lane stays inside the land square, canopy included.
	for tier in [1, 6]:
		LandHub.tier_override = tier
		LandHub.qa = {"guest": false}
		var hl := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate() as LandHub
		add_child(hl)
		await get_tree().process_frame
		var half := LandHub.PLOT_SIDE * 0.5
		var fp: Array = hl.get("_footprints")
		_check(fp.size() > 10, "tier %d: có footprint để kiểm" % tier)
		for f in fp:
			var fpos: Vector3 = f["p"]
			var fr: float = f["r"]
			_check(absf(fpos.x) + fr <= half and absf(fpos.z) + fr <= half, "tier %d: vật ra ngoài đất %s r=%.2f" % [tier, str(fpos), fr])
			# Projected top (and canopy) must be inside the land diamond on screen too.
			_check(hl.call("_screen_fits", fpos, float(f.get("rs", fr)), float(f.get("h", 0.0)), 0.0), "tier %d: đỉnh vật vượt mép đất trên màn hình %s r=%.2f h=%.2f" % [tier, str(fpos), fr, float(f.get("h", 0.0))])
		var n_props := 0
		for f in fp:
			if f.has("prop"):
				n_props += 1
				_check(not hl.call("_hits_building", f["p"], f.get("cover_r", f["r"]), f.get("cover_h", f["h"])), "tier %d: vật che nhà tại %s" % [tier, str(f["p"])])
		_check(n_props >= 4, "tier %d: còn đủ vật trang trí (%d)" % [tier, n_props])
		for lane in hl.get("_lanes"):
			for q in lane:
				_check(absf(q.x) + 0.7 <= half and absf(q.z) + 0.7 <= half, "tier %d: lane Axie ra ngoài đất %s" % [tier, str(q)])
		hl.queue_free()
		await get_tree().process_frame
	# Continue while a reconnect is in flight: a toast, never silence; the Run plate says "Reconnecting…".
	LandHub.qa = {"guest": false, "offline": false}
	LandHub.tier_override = 0
	var hub2 := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate() as LandHub
	hub2.set("_force_run", true)
	add_child(hub2)
	await get_tree().process_frame
	hub = hub2
	if is_instance_valid(hub):
		RunContinue.busy = true
		var n_before := (hub.get("_toasts") as Array).size()
		hub.call("_on_continue_pressed")
		_check((hub.get("_toasts") as Array).size() > n_before, "Continue busy: phải có toast")
		RunContinue.busy = false
		var rp := hub.find_child("RunPlate", true, false) as Button
		var old_txt := rp.text
		hub.call("_set_continue_busy", rp, true)
		_check(rp.disabled and rp.text == "Reconnecting…", "Run plate: Reconnecting… khi đang nối")
		hub.call("_set_continue_busy", rp, false)
		_check(not rp.disabled and rp.text == old_txt, "Run plate trả lại nhãn cũ")
		hub2.queue_free()
		await get_tree().process_frame
	LandHub.qa = {}
	LandHub.tier_override = 0
	LandNav.dry_run = false
	MetaState.tutorial_seen = seen_was
	_check_scene_deps("res://assets/land/homeland/scenes")
	_save_guard.restore()
	if _fails.is_empty():
		print("=== t_land_hub: PASS (%d checks) ===" % _checks)
		get_tree().quit(0)
	else:
		printerr("=== t_land_hub: FAIL (%d/%d) ===" % [_fails.size(), _checks])
		get_tree().quit(1)


## Every HomeLand scene Land can place: all dependencies exist on disk (a clean checkout must not
## have broken refs, e.g. files swallowed by .gitignore) and the scene instantiates.
func _check_scene_deps(dir_path: String) -> void:
	var scenes: Array[String] = []
	_collect_scenes(dir_path, scenes)
	_check(scenes.size() > 0, "no Land scenes found under " + dir_path)
	for sp in scenes:
		for d in ResourceLoader.get_dependencies(sp):
			var parts := String(d).split("::")
			var dp := parts[parts.size() - 1]
			if dp == "":
				dp = parts[0]
			_check(ResourceLoader.exists(dp) or FileAccess.file_exists(dp), "%s depends on missing %s" % [sp, dp])
		var ps := load(sp) as PackedScene
		_check(ps != null, sp + " does not load")
		if ps != null:
			var inst := ps.instantiate()
			_check(inst != null, sp + " does not instantiate")
			if inst != null:
				inst.free()


func _collect_scenes(dir_path: String, out: Array[String]) -> void:
	for f in DirAccess.get_files_at(dir_path):
		if f.ends_with(".tscn"):
			out.append(dir_path.path_join(f))
	for d in DirAccess.get_directories_at(dir_path):
		_collect_scenes(dir_path.path_join(d), out)


## One touch tap as the engine delivers it: ScreenTouch + emulated mouse press/release.
func _tap(vp: Viewport, ui_pos: Vector2) -> void:
	# Window pixels: the headless window is tiny and the stretch transform maps it onto the UI canvas.
	var pos := vp.get_final_transform() * ui_pos
	var mm := InputEventMouseMotion.new()
	mm.position = pos
	mm.global_position = pos
	Input.parse_input_event(mm)
	for down in [true, false]:
		var st := InputEventScreenTouch.new()
		st.position = pos
		st.pressed = down
		Input.parse_input_event(st)
		var mb := InputEventMouseButton.new()
		mb.position = pos
		mb.global_position = pos
		mb.button_index = MOUSE_BUTTON_LEFT
		mb.pressed = down
		mb.device = InputEvent.DEVICE_ID_EMULATION
		Input.parse_input_event(mb)
		await get_tree().process_frame
	await get_tree().process_frame


## Real on-screen rect: transforms the control's own rect through its global transform (scale + pivot).
func _srect(c: Control) -> Rect2:
	var xf := c.get_global_transform()
	var sz := c.get_combined_minimum_size()
	return xf * Rect2(Vector2.ZERO, sz)
