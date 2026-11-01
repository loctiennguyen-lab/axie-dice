class_name UI6Assets
extends RefCounted
## UI-06 art lookup. The ONLY place that builds paths into res://assets/ui6/. Lanes ask for a texture by meaning
## (family, tag, tier, house ...) and never concatenate file names. Every getter returns a Texture2D, or null
## (plus push_error) for an unknown key, so a typo is loud. Icons come as _32/_64/_128 PNGs: `px` picks the
## smallest variant that is at least `px` big (never upscales a 32). Frames, art windows and back art are
## nine-patch PNGs at the 1920 size; their margins live in tokens.ninepatch (see ninepatch_margins()).

const DIR := "res://assets/ui6/"
const TIER_KEYS := ["moss", "amber", "crystal"]
const FAMILIES := ["stat", "dice", "pos", "mana", "quest", "rule", "run_rule"]
## Tags that get a badge (Liam 1/11). Order here is NOT display order, see TagBadges.
const BADGE_TAGS := ["attack", "nonattack", "tradeoff", "convert_to_dmg", "front", "egg"]
const HOUSES := ["volley", "gambler", "mana_mine", "kin", "embers", "big_hand"]
const NODE_KINDS := ["battle", "elite", "boss", "shop", "event", "treasure"]
const FX := ["bubble", "leaf", "pulse", "sparkle"]
const ILLUSTRATIONS := ["card_level", "card_ascend", "card_hp", "card_reroll", "card_chaos", "card_curse", "card_relic",
	"shop_heal", "shop_relic", "node_event", "node_treasure"]

static var _cache: Dictionary = {}


## "moss" / "amber" / "crystal" for tier 0/1/2 (clamped).
static func tier_key(tier: int) -> String:
	return TIER_KEYS[clampi(tier, 0, 2)]


static func _load(file: String) -> Texture2D:
	if _cache.has(file):
		return _cache[file]
	var p := DIR + file
	var t: Texture2D = load(p) as Texture2D if ResourceLoader.exists(p) else null
	if t == null:
		push_error("UI6Assets: missing %s" % p)
	_cache[file] = t
	return t


static func _sized(base: String, px: float) -> Texture2D:
	var s := 128
	if px <= 32.5:
		s = 32
	elif px <= 64.5:
		s = 64
	return _load("%s_%d.png" % [base, s])


## Family emblem: axis in FAMILIES (core_axis value, or "run_rule" for the Run Rule card type).
static func family(axis: String, px: float = 64) -> Texture2D:
	if not FAMILIES.has(axis):
		push_error("UI6Assets.family: unknown axis '%s'" % axis)
		return null
	return _sized("family_" + axis, px)


## Tag badge icon for a tag in BADGE_TAGS (meme and anything else: null, no error, they have no badge).
static func badge(tag: String, px: float = 32) -> Texture2D:
	return _sized("badge_" + tag, px) if BADGE_TAGS.has(tag) else null


## House emblem. `house` is "h_volley" or "volley".
static func house(house_id: String, px: float = 64) -> Texture2D:
	var k := house_id.trim_prefix("h_")
	if not HOUSES.has(k):
		push_error("UI6Assets.house: unknown house '%s'" % house_id)
		return null
	return _sized("house_" + k, px)


## Awakened mark (AnchorTile / AnchorChip / awaken banner).
static func awaken(px: float = 64) -> Texture2D:
	return _sized("ui_awaken", px)


## Single tier shard (tier 0..2) and the 1/2/3 shard strip for the tier.
static func shard(tier: int, px: float = 32) -> Texture2D:
	return _sized("shard_" + tier_key(tier), px)


static func shards(tier: int, px: float = 64) -> Texture2D:
	return _sized("shards_" + tier_key(tier), px)


## Cores-strip socket by tier; tier < 0 = the empty socket.
static func slot(tier: int, px: float = 64) -> Texture2D:
	return _sized("slot_empty" if tier < 0 else "slot_" + tier_key(tier), px)


## Nine-patch card frame for a tier, 400x600 at 1920. Margins: ninepatch_margins("frame_core_" + tier_key).
static func frame(tier: int) -> Texture2D:
	return _load("frame_core_%s.png" % tier_key(tier))


static func frame_run_rule() -> Texture2D:
	return _load("frame_run_rule.png")


## Nine-patch art window by tier.
static func artwin(tier: int) -> Texture2D:
	return _load("artwin_%s.png" % tier_key(tier))


## Carved crest (160x84) that sits centred on the card's top edge and holds the shards.
static func crest(tier: int) -> Texture2D:
	return _load("crest_%s.png" % tier_key(tier))


## Centre picture of a face-down card (200x200).
static func back_art(tier: int) -> Texture2D:
	return _load("back_art_%s.png" % tier_key(tier))


## Run-map node icon, kind in NODE_KINDS.
static func node(kind: String, px: float = 64) -> Texture2D:
	if not NODE_KINDS.has(kind):
		push_error("UI6Assets.node: unknown kind '%s'" % kind)
		return null
	return _sized("node_" + kind, px)


## Reward / shop / overlay illustration in ILLUSTRATIONS; `big` = the 640 master, else 320.
static func illustration(name: String, big := false) -> Texture2D:
	if not ILLUSTRATIONS.has(name):
		push_error("UI6Assets.illustration: unknown '%s'" % name)
		return null
	return _load("ill_%s_%d.png" % [name, 640 if big else 320])


## Shop rarity picture 0 (Common) .. 4 (Legendary).
static func relic_rarity(r: int, big := false) -> Texture2D:
	return _load("relic_r%d_%d.png" % [clampi(r, 0, 4), 640 if big else 320])


## Particle / reveal texture in FX, or "rays_crystal" (the reveal rays).
static func fx(name: String, px: float = 64) -> Texture2D:
	if name == "rays_crystal":
		return _load("fx_rays_crystal.png")
	if not FX.has(name):
		push_error("UI6Assets.fx: unknown '%s'" % name)
		return null
	return _sized("fx_" + name, px)


## [L, T, R, B] at the 1920 PNG for key like "frame_core_moss", "artwin_amber", "frame_run_rule".
static func ninepatch_margins(key: String) -> Vector4i:
	var np: Dictionary = UI3Theme.tokens().get("ninepatch", {})
	var m: Array = np.get(key, [])
	if m.size() != 4:
		push_error("UI6Assets: no ninepatch margins for '%s'" % key)
		return Vector4i.ZERO
	return Vector4i(int(m[0]), int(m[1]), int(m[2]), int(m[3]))
