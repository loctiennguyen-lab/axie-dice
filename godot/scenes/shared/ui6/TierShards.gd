class_name TierShards
extends TextureRect
## UI-06 tier shard strip (1 / 2 / 3 shards for Moss / Amber / Crystal) as a plain icon, for places without a crest
## (make-room rows, tooltips, ladder). `px` is the height; width follows the picture.

var tier := 0


func setup(p_tier: int, px: float = 28) -> TierShards:
	tier = clampi(p_tier, 0, 2)
	name = "TierShards"
	texture = UI6Assets.shards(tier, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var ts := texture.get_size() if texture != null else Vector2.ONE
	custom_minimum_size = Vector2(px * ts.x / maxf(1.0, ts.y), px)
	return self
