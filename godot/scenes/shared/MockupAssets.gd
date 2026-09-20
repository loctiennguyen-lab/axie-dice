extends RefCounted
class_name MockupAssets
## Translates an asset path as written in the v2 mockups into the path it has in this repo.
##
## The four mockups under `docs/design-handoff-v2/mockups-v2/` name 34 distinct assets, and
## every single one of them already exists here — under a different folder name. `assets/fx/`
## is this repo's `assets/icons/web/`, the part icons use `_` where the mockup uses `-`, and
## the backdrops are numbered by their position in the run rather than named.
##
## That gap is small enough to paper over by hand, which is the danger. A hand-ghosted path
## fails silently: `load()` on a missing texture returns null, a null texture draws nothing,
## and nothing looks like a design choice rather than a defect. That is precisely how this
## build shipped four monsters wearing the same grey silhouette, and how the intent badge
## shipped as an empty black box. So the translation lives here once, and
## `tests/t_mockup_assets.gd` proves the whole mockup-side vocabulary resolves.
##
## Usage — pass the path exactly as the mockup writes it:
##     var tex := MockupAssets.tex("assets/fx/dmg.png")
##     var p   := MockupAssets.path("assets/part/back-plant.svg")

## Backdrop names, mockup → this repo's run-ordered scene files.
## `rocky` is a JUDGEMENT CALL: the kit ships `9-rocky-mountain-1` and `10-rocky-mountain-2`
## and the mockup says only "rocky". 9 is the lighter of the two and the mockup's Combat and
## Reward plates read bright, so 9 it is. One line to change if that reads wrong on screen.
const _SCENE_BG := {
	"entrance": "4-entrance",
	"crossroad": "5-crossroad",
	"river": "6-river",
	"deep-forest": "7-deep-forest",
	"temple": "8-temple",
	"rocky": "9-rocky-mountain-1",
	"rocky-2": "10-rocky-mountain-2",
}

## Backdrops that live in the class set rather than the scene set.
const _CLASS_BG := ["shop", "plant", "beast", "aqua", "reptile", "bug", "bird"]


## The repo path for a mockup path. Returns "" when nothing maps, so a caller can tell the
## difference between "no art here" and "art that failed to load" — `tex()` relies on that.
static func path(mockup_path: String) -> String:
	var p := mockup_path.strip_edges()
	if p.begins_with("res://"):
		return p
	if p.begins_with("./"):
		p = p.substr(2)
	if not p.begins_with("assets/"):
		return ""
	var rest := p.substr("assets/".length())
	var slash := rest.find("/")
	if slash < 0:
		return ""
	var bucket := rest.substr(0, slash)
	var name := rest.substr(slash + 1)

	match bucket:
		"fx":
			# The whole web icon set — face types, statuses, resources, node kinds.
			return "res://assets/icons/web/%s" % name
		"part":
			# `blank.svg` is the one file in the mockup's part/ folder that is not a part.
			if name == "blank.svg":
				return "res://assets/icons/web/blank.svg"
			return "res://assets/icons/web/part/%s" % name.replace("-", "_")
		"node":
			return "res://assets/icons/node/%s" % name
		"portrait":
			return "res://assets/portraits/%s" % name
		"mon":
			return "res://assets/monsters/%s" % name
		"axie":
			return "res://assets/axie/%s" % name
		"bg":
			var stem := name.get_basename()
			if _SCENE_BG.has(stem):
				return "res://assets/backgrounds/origins/scene/%s.jpg" % _SCENE_BG[stem]
			if stem in _CLASS_BG:
				return "res://assets/backgrounds/origins/class/%s.jpg" % stem
			return ""
		_:
			return ""


## Loads the texture behind a mockup path. Returns null when the path does not map or the file
## is absent — callers that need art to be there should say so out loud rather than drawing a
## hole, and `t_mockup_assets` is what keeps that from being anyone's runtime problem.
static func tex(mockup_path: String) -> Texture2D:
	var p := path(mockup_path)
	if p.is_empty() or not ResourceLoader.exists(p):
		return null
	return load(p) as Texture2D


## The part icon for one die face, by the mockup's own naming (`back`, `mouth`, `horn`, `tail`,
## `eyes`, `ears` × the six classes). An empty slot is the mockup's `blank.svg`, not a null.
static func part_icon(slot: String, cls: String) -> Texture2D:
	if slot.is_empty():
		return tex("assets/part/blank.svg")
	return tex("assets/part/%s-%s.svg" % [slot, cls])
