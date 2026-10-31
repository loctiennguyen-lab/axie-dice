class_name Ui5GemCost
extends RefCounted
## UI-05 Gem cost (paid surfaces only, violet): the chip, and the Store Buy button. The Buy button is amber primary and says
## "Buy for N Gem"; when the player is short it is disabled and says why ("Buy · need N more Gem"). Prices and balances come
## from the game; nothing here knows a price.

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")


## Violet chip: gem icon + amount (28 high, Rowdies 18), node name GemCost.
static func make(amount: int) -> PanelContainer:
	var c := PanelParts.cost_chip(&"gem", amount)
	c.name = "GemCost"
	return c


## Amber primary M "Buy for N Gem" (live) or the disabled reason button when have < price.
static func buy_button(price: int, have: int) -> Button:
	var b := PanelParts.button(TranslationServer.translate("Buy for %s Gem") % UI3.fmt(price), &"primary", &"M")
	b.name = "BuyFor%dGemButton" % price
	if have < price:
		b.name = "BuyNeed%dMoreGemButton" % (price - have)
		Ui5DisabledReason.apply(b, TranslationServer.translate("Buy · need %s more Gem") % UI3.fmt(price - have))
	return b
