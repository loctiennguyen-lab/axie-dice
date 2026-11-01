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
	return self


## Centre horizontally on a card of this width, half of the crest above the top edge.
func place_on(card_size: Vector2) -> void:
	position = Vector2((card_size.x - size.x) * 0.5, -size.y * 0.5)
