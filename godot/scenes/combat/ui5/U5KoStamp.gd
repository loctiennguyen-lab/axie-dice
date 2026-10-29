class_name U5KoStamp
extends PanelContainer
## UI-05 b1 lane E: the "OUT" stamp a knocked-out Axie's DieCard gets (moment-axie-ko.html, motion row axie_ko,
## layer "stamp": scale 1.8 -> 1, rot -12 -> -8, 260 ms BACK OUT at +280). It sits on the Ui5Moments layer and
## follows the card every frame (the card itself belongs to the dice lane), and goes away when the Axie is
## back up (Continue revive) or the card is gone.

var _v: CombatView
var _uid := -1
var _card: Control


static func make(v: CombatView, uid: int, card: Control, text: String, color_token: String) -> U5KoStamp:
	var s := U5KoStamp.new()
	s.name = "KoStamp"
	s._v = v
	s._uid = uid
	s._card = card
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := UI3Theme.size_of("btn_s")   # 44, as in the moment
	s.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("plate_ink"), int(h * 0.5), UI3Theme.stroke("btn"),
		UI3Theme.color(color_token), Vector4(14, 0, 14, 0)))
	s.custom_minimum_size = Vector2(0, h)
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UI3Theme.font_display())
	l.add_theme_font_size_override("font_size", UI3Theme.size_of("text_title"))   # 24
	l.add_theme_color_override("font_color", UI3Theme.color(color_token))
	s.add_child(l)
	s.modulate.a = 0.0
	return s


## Snap onto the card (over its die face: the upper part of the card), keeping the timeline's offsets.
func follow() -> void:
	if _card == null or not is_instance_valid(_card):
		return
	size = get_combined_minimum_size()
	pivot_offset = size * 0.5
	var r := _card.get_global_rect()
	position = Vector2(r.get_center().x, r.position.y + r.size.y * 0.3) - size * 0.5


func _process(_dt: float) -> void:
	var alive := false
	if is_instance_valid(_v) and _v._combat != null:
		var u: Unit = _v._combat.by_uid(_uid)
		alive = u != null and u.hp > 0
	if alive or _card == null or not is_instance_valid(_card) or not _card.is_visible_in_tree():
		queue_free()
		return
	follow()
