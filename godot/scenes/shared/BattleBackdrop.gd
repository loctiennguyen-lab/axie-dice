class_name BattleBackdrop
extends Control
## The layered backdrop behind a fight.
##
## Replaces a single static `desert_battle_bg.png` that every combat in the game shared. An
## 18-row run that never changes its horizon reads as one very long fight rather than a
## journey, which is the thing this is actually for — the depth cue is a bonus.
##
## WHAT IT DRAWS
## -------------
## One pre-composited scene image per region, from `assets/backgrounds/origins/scene/`.
##
## A CORRECTION WORTH KEEPING: the first version of this stacked the kit's raw per-layer PNGs
## live and shifted each one against the camera, on the assumption that filename order encodes
## depth. It does not. Sorted alphabetically, `7-deep-forest` draws FRONT-BOT and FRONT-TOP
## *behind* Ground and MANY-TREES, and the result rendered as a flat green wash with no horizon
## — visibly worse than the single desert background it replaced. The kit records no depth data
## at all, so any ordering would have been a guess presented as fact.
##
## `tools/`-side compositing stacks each set the way the source intends and crops to 16:9, which
## produces the image the artist actually drew. Live parallax was a bonus; region variety was
## the goal, and it is not worth shipping the goal broken to keep the bonus.
##
## WHY THE SET IS CHOSEN BY ROW
## ----------------------------
## Keying off the enemy's class would be the obvious move and does not work: almost every
## monster in ContentDB has `cls == ""` (only heroes carry a class), so it would collapse to one
## backdrop again. Row number is the signal that actually varies across a run, and using it in
## order means the player walks from an entrance, through a forest, to a mountain — the run's
## shape becomes visible in the art.

const SCENE_DIR := "res://assets/backgrounds/origins/scene/"
const CLASS_BG_DIR := "res://assets/backgrounds/origins/class/"

## Parallax sets in the order a run travels through them. The kit's own numeric prefixes
## (4-entrance ... 10-rocky-mountain-2) already describe a journey, so the run follows it.
const JOURNEY: Array[String] = [
	"4-entrance",
	"5-crossroad",
	"6-river",
	"7-deep-forest",
	"8-temple",
	"9-rocky-mountain-1",
	"10-rocky-mountain-2",
]

## The scene is drawn slightly larger than the viewport and drifts a little with the stage
## camera, so the backdrop still has some life without needing real per-layer depth.
const MAX_PARALLAX_PX := 18.0
const OVERSCAN := 1.06

var _image: TextureRect = null
var _current_set := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## Picks and builds the backdrop for one combat.
##
## `row` is the RunMap row (1-based). `is_boss` gets the last, most dramatic scene regardless of
## row, so a boss fight never opens on a gentle forest clearing.
func show_for_node(row: int, is_boss: bool) -> void:
	var set_name := _set_for(row, is_boss)
	if set_name == _current_set:
		return
	_current_set = set_name
	_build(set_name)


func _set_for(row: int, is_boss: bool) -> String:
	if JOURNEY.is_empty():
		return ""
	if is_boss:
		return JOURNEY[JOURNEY.size() - 1]
	# Spread the run's rows evenly across the journey. Row is 1-based; an 18-row run over 7
	# scenes gives roughly 2-3 rows per scene.
	var idx: int = clampi(int(floor((maxi(row, 1) - 1) / 18.0 * JOURNEY.size())), 0, JOURNEY.size() - 1)
	return JOURNEY[idx]


func _build(set_name: String) -> void:
	if _image == null:
		_image = TextureRect.new()
		_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_image)
	var path := SCENE_DIR + set_name + ".jpg"
	if not ResourceLoader.exists(path):
		push_warning("BattleBackdrop: no scene image at %s" % path)
		return
	_image.texture = load(path) as Texture2D
	_resize_layers()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_resize_layers()


func _resize_layers() -> void:
	if _image != null:
		_image.size = Vector2(size.x * OVERSCAN, size.y * OVERSCAN)


## Called every frame by CombatView with the same stage offset the vignette already tracks.
func apply_parallax(stage_offset: Vector2) -> void:
	if _image == null:
		return
	var base := Vector2(-size.x * (OVERSCAN - 1.0) * 0.5, -size.y * (OVERSCAN - 1.0) * 0.5)
	_image.position = base + stage_offset * 0.01 * MAX_PARALLAX_PX


## Static, single-image fallback for screens that are not a fight (shop, event) — the kit ships
## one per Axie class plus a shop scene.
static func class_background(name: String) -> Texture2D:
	var path := CLASS_BG_DIR + name + ".jpg"
	return load(path) as Texture2D if ResourceLoader.exists(path) else null
