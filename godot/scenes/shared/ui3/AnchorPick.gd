class_name AnchorPick
extends Control
## Anchor pick overlay (design/ux/anchor-mvp.md section 1): 3 face-up-after-flip cards, one primary "Take <Name>",
## no Skip, no Reroll. Reuses GachaReveal for the flip. UI only: the pick goes through AnchorAdapter.pick().
## Hosted inside RunMapController's overlay host (same one the Core pick uses).

signal picked(anchor_id: String)

## One plain line per Anchor, shown at the top of its card (UI-side wording; the exact rule stays below).
const SUMMARY := {
	"a_volley": "A matching group of 3+ dice also hits every enemy.",
	"a_gambler": "Safer rerolls (Gambles) that make your groups stronger.",
	"a_mana_mine": "Make a group on your first roll and get extra Mana.",
	"a_kin": "Groups of the same class hit harder, mixed groups hit weaker.",
	"a_embers": "Keep 2 dice for next turn and they hit much harder.",
	"a_big_hand": "Groups of 4 or 5 dice hit harder, groups of 3 get nothing."}
## Jargon explained once, on the screen (SET etc. are never defined elsewhere before the first pick).
const GLOSSARY := "SET = 3+ dice that match and fire together. M = a die's damage multiplier. Cracked = a die broken by a risky reroll (Gamble). Held = a die you keep for next turn. Temp Face = a die that joins any SET for one turn. House Cores = the 5 Cores tied to an Anchor."

const TEXT_W := 480.0   ## text width of the shared RULE/AWAKENS blocks (Codex detail)
const AnchorCardScript := preload("res://scenes/run_map/ui5/AnchorCard.gd")
const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")

var cards: Array[PanelContainer] = []
var take_button: Button
var reveal: GachaReveal
var selected := -1
var _ids: Array = []
var _row: HBoxContainer
var _cap: PanelContainer


## UI-05 48-anchor-pick: one column from offer_top, gap 32: Header (Title + ShardPill), SubLine, CardRow, Glossary, Footer
## (TakeButton). Nothing is chosen on open; TakeButton is disabled and says why until a card is picked.
func setup(ids: Array, first_time := true) -> void:
	_ids = ids
	UI3Theme.sync_scale()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := VBoxContainer.new()
	col.name = "AnchorColumn"
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_top = UI3Theme.size_of("offer_top")
	col.add_theme_constant_override("separation", UI3Theme.space("32"))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	# html .offer-sub has margin-top -24: Header and SubLine sit 8 apart inside one block, not 32.
	var top := VBoxContainer.new()
	top.name = "TopBlock"
	top.add_theme_constant_override("separation", UI3Theme.space("8"))
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)
	var head := HBoxContainer.new()
	head.name = "Header"
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", UI3Theme.space("20"))
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(head)
	var t := PanelParts.on_view(PanelParts.text(tr("Choose your Anchor"), "text_banner", "text", true))
	t.name = "Title"
	head.add_child(t)
	head.add_child(_shard_pill(int(RunState.shards_this_run)))
	var sub := PanelParts.on_view(PanelParts.text(tr("Anchor = a rule that stays all run. Hold 2 of its House Cores to awaken it. Click a card to choose.")))
	sub.name = "SubLine"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.mouse_filter = Control.MOUSE_FILTER_PASS
	UI3Tooltip.bind(sub, tr(GLOSSARY))   # polish 3/11 #9: the SET / M / Cracked footnote is a tooltip now
	top.add_child(sub)
	_row = HBoxContainer.new()
	_row.name = "CardRow"
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", UI3Theme.space("32"))
	_row.custom_minimum_size.y = UI3Theme.size_of("anchor_card_h")
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.sort_children.connect(_lift_selected)
	col.add_child(_row)
	for i in ids.size():
		var c := _build_card(String(ids[i]), i)
		_row.add_child(c)
		cards.append(c)
	var foot := HBoxContainer.new()
	foot.name = "Footer"
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(foot)
	take_button = UI3.button(tr("Take"), &"primary", &"L")
	take_button.name = "TakeButton"
	take_button.pressed.connect(_take)
	foot.add_child(take_button)
	_cap = Ui5Keycap.make("Space", &"primary")
	take_button.add_child(_cap)
	take_button.resized.connect(_place_cap)
	_refresh_take()
	# Flip like the Core pick (no random tier: neutral moss look, first time = longer aura).
	reveal = GachaReveal.new()
	reveal.name = "GachaReveal"
	add_child(reveal)
	for c in cards:
		c.set_meta("gacha_tier", 0)
	reveal.start(cards, 0, first_time, false, col)
	reveal.finished.connect(func() -> void: if not cards.is_empty(): cards[0].grab_focus())


func _shard_pill(n: int) -> PanelContainer:
	var box := PanelParts.plate_box("pill")
	box.content_margin_left = UI3Theme.space("16")
	box.content_margin_right = UI3Theme.space("16")
	var chip := PanelParts.panel(box, "ShardPill")
	chip.custom_minimum_size = Vector2(0, UI3Theme.size_of("btn_m"))
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", UI3Theme.space("8"))
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(r)
	var px := UI3Theme.size_of("icon_m")
	r.add_child(PanelParts.icon_rect(UI3.currency_icon("cur_shard", px), px))
	var v := PanelParts.text(UI3.fmt(n), "text_title", "text", true)
	v.name = "Value"
	v.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	r.add_child(v)
	return chip


func _lift_selected() -> void:
	for c in cards:
		var ac := c as Control
		if ac.has_method("lift_px"):
			ac.position.y -= float(ac.call("lift_px"))


func _build_card(id: String, idx: int) -> PanelContainer:
	var card: PanelContainer = AnchorCardScript.new()
	card.setup(id)
	card.name = "AnchorCard%d" % idx   # the design name is AnchorCard; the index keeps siblings apart (data-name prefix)
	card.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			select(idx)
			card.grab_focus()
		elif ev.is_action_pressed("ui_accept") and not ev.is_echo():
			if selected == idx:
				_take()   # Space / Enter on the card that is already chosen takes it
			else:
				select(idx)
			card.accept_event())
	return card


## RULE / PRICE (amber, only when the Anchor has one) / AWAKENS blocks. Shared with the Codex detail so both read the same.
static func add_text_blocks(col: VBoxContainer, id: String) -> void:
	_section(col, "RULE", "Rule", AnchorAdapter.rule_text(id), 3)
	if AnchorAdapter.price_text(id) != "":   # an Anchor with no price shows no PRICE block (no fake cost line)
		var pr := _section(col, "PRICE", "Price", "− " + AnchorAdapter.price_text(id), 2)
		(pr.find_child("PriceText", true, false) as Label).add_theme_color_override("font_color", UI3Theme.color("anchor_price"))
	var aw := _section(col, "AWAKENS", "Awakens", "", 0)
	var an := UI3.label(AnchorAdapter.awaken_name(id), "LabelDisplay")
	an.name = "AwakenName"
	aw.add_child(an)
	var ar := UI3.label(AnchorAdapter.awaken_rule(id), "LabelMuted")
	ar.name = "AwakenRule"
	ar.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ar.custom_minimum_size.x = TEXT_W - 48.0
	aw.add_child(ar)
	var cond := UI3.label(TranslationServer.translate("Awakens when you hold 2 of these 5 Cores"), "LabelMuted")
	cond.name = "AwakenCondition"
	cond.add_theme_color_override("font_color", UI3Theme.color("anchor_awake"))
	cond.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cond.custom_minimum_size.x = TEXT_W - 48.0
	aw.add_child(cond)


## A small labelled block: muted caption, then the text. Returns the block (text label is "<cap>Text").
static func _section(col: VBoxContainer, cap: String, _key: String, text: String, _lines: int) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.name = "Section" + cap.capitalize()
	b.add_theme_constant_override("separation", 2)
	b.add_child(UI3.label(TranslationServer.translate(cap), "LabelMuted"))
	if text != "":
		var l := UI3.label(text, "LabelDisplay")
		l.name = cap.capitalize() + "Text"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = TEXT_W - 48.0
		b.add_child(l)
	col.add_child(b)
	return b


func select(i: int) -> void:
	if reveal != null and reveal.running:
		return   # the click that skips the flip is not also a pick
	if i < 0 or i >= cards.size() or AnchorAdapter.disabled_reason(String(_ids[i])) != "":
		return
	selected = i
	for k in cards.size():
		(cards[k] as Object).call("set_selected", k == i)
	_row.queue_sort()
	_refresh_take()


func _place_cap() -> void:
	if _cap != null and is_instance_valid(take_button):
		Ui5HudStyle.place_trailing(take_button, _cap, UI3Theme.space("32"))


func _refresh_take() -> void:
	if _cap != null:
		_cap.visible = selected >= 0   # no key cap on a disabled button
	if selected < 0:
		take_button.text = tr("Take")
		take_button.disabled = true
		UI3.set_disabled_reason(take_button, tr("Pick an Anchor"))
	else:
		UI3.clear_disabled_reason(take_button)
		take_button.disabled = false
		take_button.text = tr("Take %s") % AnchorAdapter.name_of(String(_ids[selected]))
	if _cap != null:
		_place_cap.call_deferred()


func _take() -> void:
	if selected < 0 or (reveal != null and reveal.running):
		return
	var id := String(_ids[selected])
	if AnchorAdapter.pick(id):
		picked.emit(id)


func _unhandled_key_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not ev.pressed or ev.echo:
		return
	var k := (ev as InputEventKey).keycode
	if k == KEY_SPACE and selected >= 0:
		_take()
		get_viewport().set_input_as_handled()
	elif k in [KEY_1, KEY_2, KEY_3]:
		select(int(k - KEY_1))
		get_viewport().set_input_as_handled()
