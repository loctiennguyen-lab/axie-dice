class_name CoreVisuals
extends RefCounted
## Shared look-up for Cores: tier words and colours, family (core_axis) names and chips. Moved out of CorePanel in
## UI-06 L0 so RunMapOffers, AnchorCard and the other UI-06 lanes never depend on CorePanel. CorePanel keeps its old
## constant names as aliases of these. Pure functions; no node state.

const TIER_NAME := ["Moss", "Amber", "Crystal"]
const TIER_TOKEN := ["tier_moss", "tier_amber", "tier_crystal"]
const TIER_TEXT_TOKEN := ["tier_moss_text", "tier_amber_text", "tier_crystal_text"]
const FAMILY_TOKEN := {"stat": "fam_stat", "dice": "fam_dice", "pos": "fam_pos", "mana": "fam_mana", "quest": "fam_quest",
	"rule": "fam_rule", "run_rule": "fam_run_rule"}
## LEGACY UI-05 axis glyphs (assets/ui3/icons), still used by the old CorePanel / offer cards until L1-L2 move to
## UI6Assets.family(). New code uses family_texture().
const AXIS_ICON := {"stat": "face_buff", "dice": "face_dmg", "pos": "face_summon", "mana": "face_mana",
	"quest": "node_treasure", "rule": "face_debuff", "run_rule": "ui_settings"}
## Long axis names (tooltips, UI-05 text).
const AXIS_NAME := {"stat": "Stat", "dice": "Dice faces", "pos": "Position", "mana": "Mana",
	"quest": "Quest", "rule": "Rule change", "run_rule": "Run rule"}
## Short family chip names (UI-06 FamilyChip).
const FAMILY_NAME := {"stat": "Stat", "dice": "Dice", "pos": "Position", "mana": "Mana", "quest": "Quest",
	"rule": "Rule", "run_rule": "Run rule"}


static func tier_name(tier: int) -> String:
	return TIER_NAME[clampi(tier, 0, 2)]


## Tier colour (frame / chip edge).
static func tier_color(tier: int) -> Color:
	return UI3Theme.color(TIER_TOKEN[clampi(tier, 0, 2)])


## Tier colour for words on a plate (the lighter text-safe tint).
static func tier_text_color(tier: int) -> Color:
	return UI3Theme.color(TIER_TEXT_TOKEN[clampi(tier, 0, 2)])


static func family_color(axis: String) -> Color:
	return UI3Theme.color(String(FAMILY_TOKEN.get(axis, "text_muted")))


static func family_name(axis: String) -> String:
	return TranslationServer.translate(String(FAMILY_NAME.get(axis, "Core")))


static func axis_name(axis: String) -> String:
	return TranslationServer.translate(String(AXIS_NAME.get(axis, "Core")))


## UI-06 family emblem picture (see UI6Assets.family).
static func family_texture(axis: String, px: float = 64) -> Texture2D:
	return UI6Assets.family(axis if UI6Assets.FAMILIES.has(axis) else "stat", px)


## Chip with an icon + word; see UI3.icon_chip. icon_name "" = word only (legacy assets/ui3/icons name).
static func word_chip(text: String, icon_name: String, border: Color, chip_name := "") -> PanelContainer:
	return UI3.icon_chip(text, UI3.icon(icon_name) if icon_name != "" else null, border, chip_name)


## UI-06 FamilyChip: the family emblem + family name, edged in the family colour. Node name "FamilyChip".
static func family_chip(axis: String) -> PanelContainer:
	var px := float(UI3Theme.size_of("fam_chip_emblem"))
	var c := UI3.icon_chip(family_name(axis), family_texture(axis, px), family_color(axis), "FamilyChip")
	var ic := c.find_child("Icon", true, false) as TextureRect
	if ic != null:
		ic.custom_minimum_size = Vector2(px, px)
	return c
