extends RefCounted
## UI-05 b23 lane 0d: the meta kit laid out on one sheet (used by t_ui5_meta_kit and qa_ui5_meta_kit_capture).
## Every value below is a test fixture, not a game value. Returns the root Control (1920 x 1080 logical).

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
const Keycap := preload("res://scenes/shared/ui5/Keycap.gd")


static func _h(parent: Node, gap := 24) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", gap)
	parent.add_child(h)
	return h


static func _v(parent: Node, gap := 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", gap)
	parent.add_child(v)
	return v


static func build(host: Node) -> Control:
	var root := Control.new()
	root.name = "Sheet"
	root.theme = UI3Theme.get_theme()
	root.size = Vector2(1920, 1080)
	var bg := ColorRect.new()
	bg.color = UI3Theme.color("bg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	host.add_child(root)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 32)
	root.add_child(m)
	var col := _v(m, 20)
	col.name = "Rows"
	# row 1: currency + toasts
	var r1 := _h(col, 32)
	r1.name = "Row1"
	var gear := UI3.icon_button("ui_settings")
	r1.add_child(Ui5CurrencyPlate.make({"shard": 2450, "stone": 3200, "gem": 120}, gear))
	r1.add_child(Ui5CurrencyPlate.make({}, UI3.icon_button("ui_settings")))
	var toasts := _v(r1, 8)
	toasts.name = "Toasts"
	toasts.add_child(Ui5Toast.make("Your Land is now Forest", &"ok"))
	toasts.add_child(Ui5Toast.make("Could not upgrade", &"error"))
	toasts.add_child(Ui5Toast.make("Coming soon", &"info"))
	# row 2: tabs, rows, detail plates
	var r2 := _h(col, 24)
	r2.name = "Row2"
	var left := _v(r2, 12)
	left.name = "ListCol"
	var tabs := Ui5TabBar.new()
	tabs.setup(["Overview", "Runs", "Cosmetics"], 0)
	left.add_child(tabs)
	var rows: Array[Ui5ListRow] = []
	for i in 3:
		var lr := Ui5ListRow.new()
		lr.setup("Tier %d" % (i + 1), "Rule line %d" % (i + 1), "x%d" % (i + 1), "mission_row_h", 96)
		lr.custom_minimum_size.x = 520
		left.add_child(lr)
		rows.append(lr)
	rows[1].set_state(&"selected")
	rows[2].set_state(&"locked")
	var d0 := Ui5DetailPlate.new()
	d0.setup("mission_detail_w", "Pick a tier", 420, 340)
	r2.add_child(d0)
	var d1 := Ui5DetailPlate.new()
	d1.setup("mission_detail_w", "Pick a tier", 420, 340)
	r2.add_child(d1)
	d1.show_item("Tier 2")
	d1.add_line("Fixture rule line that is long enough to wrap onto a second line in the plate.")
	d1.footer.add_child(Ui5ClaimButton.make("Claim", &"M"))
	# row 3: save cards + footers
	var r3 := _h(col, 24)
	r3.name = "Row3"
	for i in 2:
		var sc := Ui5SaveCard.new()
		sc.setup("Save %d" % (i + 1), [["Gene Shards", "100"], ["Vault", "3"], ["Runs", "2 / 1"]], "Saved just now")
		sc.custom_minimum_size.x = 340
		sc.set_picked(i == 0)
		r3.add_child(sc)
	var f1 := Ui5ModalFooter.make(UI3.button("Move progress", &"primary", &"M"), UI3.button("Cancel", &"secondary", &"M"))
	f1.name = "Footer1Row"
	r3.add_child(f1)
	var f2 := Ui5ModalFooter.make(UI3.button("Update now", &"primary", &"M"), UI3.button("Close", &"secondary", &"M"), true)
	f2.name = "Footer2Rows"
	f2.custom_minimum_size.x = 320
	r3.add_child(f2)
	# row 4: gem cost, buy, claim, reason
	var r4 := _h(col, 16)
	r4.name = "Row4"
	r4.add_child(Ui5GemCost.make(90))
	r4.add_child(Ui5GemCost.buy_button(90, 400))
	r4.add_child(Ui5GemCost.buy_button(90, 10))
	r4.add_child(Ui5ClaimButton.make("Claim"))
	var cl := Ui5ClaimButton.make("Claim")
	Ui5ClaimButton.set_claimed(cl)
	r4.add_child(cl)
	var nd := Ui5ClaimButton.make("Claim")
	Ui5ClaimButton.set_need(nd, "Need 20")
	r4.add_child(nd)
	r4.add_child(Ui5ClaimButton.secondary_with_gem("Claim 300 Gem"))
	r4.add_child(Ui5DisabledReason.lock_line("Sign in to use"))
	# row 5: spinner, switch, slider
	var r5 := _h(col, 32)
	r5.name = "Row5"
	r5.add_child(Ui5Spinner.new())
	var s0 := Ui5Switch.new()
	s0.setup(false)
	r5.add_child(s0)
	var s1 := Ui5Switch.new()
	s1.setup(true)
	r5.add_child(s1)
	var sl := Ui5Slider.new()
	sl.setup(0.6)
	r5.add_child(sl)
	return root
