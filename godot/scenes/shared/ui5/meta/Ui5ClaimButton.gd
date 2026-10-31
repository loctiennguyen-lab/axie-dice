class_name Ui5ClaimButton
extends RefCounted
## UI-05 free Claim (amber, never violet). make() = amber primary (S by default, M for a lone Claim). Other states:
## claimed (disabled, tick icon, "Claimed"), need (disabled, says why, e.g. "Need 20" / "Reach Level 11"), and the secondary
## "Claim 300 Gem" with the Gem icon used while another primary is live on the screen.

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")


static func make(text: String, size := &"S") -> Button:
	var b := UI3.button(text, &"primary", size)
	b.name = "ClaimButton"
	b.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body" if size == &"S" else "text_title"))
	return b


## Secondary variant with the Gem icon (the free gift while a Buy / Daily Claim is the screen's primary).
static func secondary_with_gem(text: String) -> Button:
	var b := PanelParts.button(text, &"secondary", &"S")
	b.name = "GiftButton"
	b.icon = UI3.currency_icon("cur_gem", UI3Theme.size_of("icon_s"))
	b.add_theme_constant_override("icon_max_width", UI3Theme.size_of("icon_s"))
	return b


static func set_claimed(b: Button, text := "Claimed") -> void:
	b.theme_type_variation = "ButtonSecondary"
	b.name = "ClaimedButton"
	b.text = TranslationServer.translate(text)
	b.icon = UI3.icon("ui_check")
	b.add_theme_constant_override("icon_max_width", UI3Theme.size_of("icon_s"))
	b.disabled = true


static func set_need(b: Button, why: String) -> void:
	Ui5DisabledReason.apply(b, why)
