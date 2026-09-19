class_name CardArt
extends RefCounted
## The illustration on a reward, shop or node card.
##
## WHERE THE ART COMES FROM
## ------------------------
## `godot/assets/cards/*.png` are Axie Origins Kit card illustrations
## (`PvE/Cards/Tools/*.png`, 320x320, painted with their own backgrounds). They are exactly what
## a card wants and exactly what a battlefield sprite does not — which is why the Chimera
## CARD art was ruled out for monsters (godot-port-gap-inventory.md) and is right here.
##
## PAIRED BY LOOKING, NOT BY NAME
## ------------------------------
## The kit's names describe the ability they illustrated in a different game, so matching on
## them produces nonsense. Each pairing below was chosen from a contact sheet of the candidates:
## strawberries on a plate for MAX HP because food reads as health instantly; a mystery box for
## CHAOS DEAL because that is what a chaos deal is; a tarot-ish card burning in red for CURSE
## PACT. `MonsterArt` was authored the same way and for the same reason.
##
## Missing art is not an error — `texture_for_*` returns null and the card renders as it always
## did, text only. A reward the player can take must never depend on an image existing.

const DIR := "res://assets/cards/"

## RunState reward `t` value -> illustration. Mirrors the 7 reward types the port actually
## offers (reward_generator.gd); `face`/`rune` are deliberately absent because this build does
## not offer them, and an image for a reward nobody can receive would be dead weight.
const REWARD_ART := {
	"level": "card_level",      # a plant creature sprouting up a rock — growing stronger
	"ascend": "card_ascend",    # a rainbow over a beach — a permanent blessing
	"relic": "card_relic",      # unused for relics — see texture_for_reward()'s rarity branch
	"hp": "card_hp",            # strawberries on a plate
	"reroll": "card_reroll",    # a mystery box struck by lightning — drawn again
	"chaos": "card_chaos",      # a pink "?" box — an unknown bargain
	"curse": "card_curse",      # a dark card burning in red — a pact with a price
}

## Shop item `kind` -> illustration. The shop sells three things (reward_generator.gd
## generate_shop_items): a relic, a Serum, and an Instinct.
const SHOP_ART := {
	"relic": "shop_relic",      # unused for relics — see texture_for_shop()'s rarity branch
	"heal": "shop_heal",        # a shell pouring clear water — a potion
	"reroll": "card_reroll",    # deliberately the same image as the reward: it is the same gain
}

## Map node kind -> the illustration its overlay leads with.
const NODE_ART := {
	"treasure": "node_treasure",  # a rock crowned with clover, floating — a lucky find
	"event": "node_event",        # a creature under a question mark — a choice
}


## Relics get art BY RARITY, not one image for all of them. Two relics sit side by side in
## every shop and in most reward offers; one shared picture made the pair read as the same item
## twice. Rarity is the one thing about a relic that a single illustration can honestly carry —
## the other 94 differences need 94 pictures, which is a separate job.
const RELIC_ART_BY_RARITY: Array[String] = [
	"relic_r0",   # Common — a plain wooden shield
	"relic_r1",   # Uncommon — a great leaf sheltering smaller creatures
	"relic_r2",   # Rare — a gold coin
	"relic_r3",   # Epic — a staff wreathed in light
	"relic_r4",   # Legendary — something burning
]


## `rarity` is DangoTheme.RARITY_NAMES' index (0 Common .. 4 Legendary), or -1 when the caller
## has none. Out-of-range falls back to Common rather than to nothing: a relic with a strange
## rarity is still a relic, and a blank card would be the more confusing failure.
static func texture_for_reward(reward_type: String, rarity: int = -1) -> Texture2D:
	if reward_type == "relic":
		return _relic_art(rarity)
	return _load(String(REWARD_ART.get(reward_type, "")))


static func texture_for_shop(kind: String, rarity: int = -1) -> Texture2D:
	if kind == "relic":
		return _relic_art(rarity)
	return _load(String(SHOP_ART.get(kind, "")))


static func _relic_art(rarity: int) -> Texture2D:
	var index: int = clampi(rarity, 0, RELIC_ART_BY_RARITY.size() - 1)
	return _load(RELIC_ART_BY_RARITY[index])


static func texture_for_node(node_kind: String) -> Texture2D:
	return _load(String(NODE_ART.get(node_kind, "")))


static func _load(basename: String) -> Texture2D:
	if basename.is_empty():
		return null
	var path := DIR + basename + ".png"
	if not ResourceLoader.exists(path):
		push_warning("CardArt: %s is mapped but missing" % path)
		return null
	return load(path) as Texture2D
