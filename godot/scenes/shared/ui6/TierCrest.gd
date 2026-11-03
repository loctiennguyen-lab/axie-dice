class_name TierCrest
extends TextureRect
## UI-06 carved crest (scroll wings + medallion with the 1/2/3 shards) centred on a card's top edge. A separate
## TextureRect so the nine-patch never stretches it. Height = token size.shards_h (64 at 1920); width keeps the
## 160x84 ratio. Call place_on(card_size) after the card is sized, or anchor it yourself.

var tier := 0


func setup(p_tier: int) -> TierCrest:
	tier = clampi(p_tier, 0, 2)
	name = "TierCrest"
	texture = UI6Assets.crest(tier)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var h := float(UI3Theme.size_of("shards_h"))
	custom_minimum_size = Vector2(h * 160.0 / 84.0, h)
	size = custom_minimum_size
	_add_gem(h)
	return self


## Library gem (Liam 2/11) over the medallion: a dark disc hides the leaf / drops / crystal baked into the crest PNG, the
## tier gem (green / orange / diamond) sits on it. One gem per tier; the 1/2/3 count is carried by the gem kind.
func _add_gem(h: float) -> void:
	var cx := h * 160.0 / 84.0 * 0.5
	var cy := h * 0.55
	var d := h * 0.5
	var disc := Panel.new()
	disc.name = "CrestDisc"
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("chip"), int(d), 0))
	disc.position = Vector2(cx - d * 0.5, cy - d * 0.5)
	disc.size = Vector2(d, d)
	add_child(disc)
	var gh := d * 0.84
	var gem := TextureRect.new()
	gem.name = "CrestGem"
	gem.texture = UI6Assets.shard(tier, gh)
	gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gem.position = Vector2(cx - gh * 0.5, cy - gh * 0.5)
	gem.size = Vector2(gh, gh)
	add_child(gem)


## Centre horizontally on a card of this width, half of the crest above the top edge.
func place_on(card_size: Vector2) -> void:
	position = Vector2((card_size.x - size.x) * 0.5, -size.y * 0.5)
