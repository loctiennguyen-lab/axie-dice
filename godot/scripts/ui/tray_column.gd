class_name TrayColumn
extends RefCounted
## One party card in the dice tray. UI-05 b1 lane B: the card itself is a DieCard (scenes/combat/ui5/DieCard.gd); this class
## keeps the old entry points (`build`, `update`, `ui3_face`, `dock_top`, the content dictionary keys) so DiceDock,
## EnemyColumn (HP preview on "hp"), the 3D dice throw (tray target = "die"), the cosmetics test and the tutorial keep working.
## The card is still the toggle Button DieSlotN: `%DieSlot0`, focus, keys and the tutorial step lock "die:<slot>" stay on it.
## Every size comes from UI3Theme tokens (die_card_w / die_card_h / dice_gap / dice_header_h / set_banner_h), so the 1280
## interpolation applies (no 848 / 153.6 constants any more).

## Game face type -> UI3 face name.
const _FACE := {"dmg": &"attack", "debuff": &"weaken"}
const _STATUS_ICON := {"poison": "status_poison", "vulnerable": "status_vuln"}


# ---------------------------------------------------------------- dock geometry (logical px, canvas 1920)

## DieCard width (152; 174 logical = 116 real px at 1280).
static func card_w() -> float:
	return float(UI3Theme.size_of("die_card_w"))


## DieCard height (228, or a few px more when the 1280 text floor makes the rows taller).
static func card_h() -> float:
	return DieCard.needed_height()


## Gap between two DieCards (12).
static func gap() -> float:
	return float(UI3Theme.size_of("dice_gap"))


## Gap between the dock's three rows (SetBanners, DiceHeader, DiceRow): 8.
static func row_gap() -> float:
	return float(UI3Theme.space("8"))


static func header_h() -> float:
	return float(UI3Theme.size_of("dice_header_h"))


static func banner_h() -> float:
	return float(UI3Theme.size_of("set_banner_h"))


## DiceDock = VBox(SetBanners 40, gap 8, DiceHeader 28, gap 8, DiceRow card_h): 312 at 1920.
static func dock_h() -> float:
	return banner_h() + row_gap() + header_h() + row_gap() + card_h()


## Top edge of the DiceDock on a screen `vs_y` high (bottom margin space.screen = 24).
static func dock_top(vs_y: float) -> float:
	return vs_y - float(UI3Theme.space("screen")) - dock_h()


## Top edge of the DiceHeader (FRONT / BACK) row.
static func header_top(vs_y: float) -> float:
	return dock_top(vs_y) + banner_h() + row_gap()


## Top edge of the DieCards.
static func card_top(vs_y: float) -> float:
	return header_top(vs_y) + header_h() + row_gap()


static func ui3_face(game_type: String) -> StringName:
	var f := StringName(_FACE.get(game_type, game_type))
	return f if f in UI3.FACE_TYPES else &"blank"


## Puts a DieCard inside the slot Button. Returns the dictionary `update()` repaints. Keys kept from UI-03/04:
## button, card, root/body (the DieCard: DiceDock hangs the Anchor chip on it), plate, die (the Die panel: 3D throw target,
## skin trim parent), die_num (FaceValue), hp (HPBar: EnemyColumn previews damage on it), name_label, hp_label, skin_*.
static func build(btn: Button) -> Dictionary:
	btn.custom_minimum_size = Vector2(card_w(), card_h())
	btn.clip_contents = false
	var card := DieCard.new()
	if String(btn.name).begins_with("DieSlot") and String(btn.name).trim_prefix("DieSlot").is_valid_int():
		card.name = "DieCard%d" % (int(String(btn.name).trim_prefix("DieSlot")) + 1)   # HTML data-name DieCard1..5
	btn.add_child(card)
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		btn.add_theme_stylebox_override(st, empty)
	btn.add_theme_stylebox_override("focus", UI3Theme.focus_style(UI3Theme.radius("xl")))
	return {"button": btn, "card": card, "root": card, "body": card, "plate": card.plate,
		"name_label": card.owner_name, "hp": card.hp_bar, "hp_label": card.owner_hp, "lifted": false,
		"skin_id": "", "skin_node": null, "die": card.die, "die_num": card.face_value, "holder": card.die_holder}


## Paints the card. `d`: see DieCard.apply (name, hp, max_hp, shield, incoming, faces, rolled, alive, spent, selected,
## legal_target, skin, held, overcast, cracked, rr_tick, wild_text, part_*, set_*) + tip (the card's tooltip).
static func update(content: Dictionary, d: Dictionary) -> void:
	var btn: Button = content["button"]
	var card: DieCard = content["card"]
	card.apply(d)
	content["lifted"] = card.lifted
	content["skin_id"] = card.skin_id
	content["skin_node"] = card.skin_node
	var tip := String(d.get("tip", ""))
	if card.delta_full != "":
		tip = "%s\n%s %s" % [tip, TranslationServer.translate("In the SET:"), card.delta_full]
	UI3Tooltip.bind(btn, tip)
	btn.set_meta("ui3_tip_side_of_row", true)


## The DieCard lifts its own die when selected (update); nothing to tween here.
static func set_lifted(_view: Node, content: Dictionary, lifted: bool, _instant: bool) -> void:
	content["lifted"] = lifted
