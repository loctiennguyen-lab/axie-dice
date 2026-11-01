class_name CoreHeadline
extends RefCounted
## One-line headline of a Core or Run Rule, from assets/data/ui/core_headlines.json ({id: text}). UI data, not rules
## data. An id with no entry (or an empty string) has no headline: apply() hides the label. MAX_LEN is checked by
## t_ui6_kit (Unicode characters), nothing is clipped at run time.

const PATH := "res://assets/data/ui/core_headlines.json"
const MAX_LEN := 24

static var _data: Dictionary = {}
static var _loaded := false


static func all() -> Dictionary:
	if not _loaded:
		_loaded = true
		var f := FileAccess.open(PATH, FileAccess.READ)
		var v: Variant = JSON.parse_string(f.get_as_text()) if f != null else null
		_data = v if typeof(v) == TYPE_DICTIONARY else {}
		if _data.is_empty():
			push_error("CoreHeadline: %s missing or invalid" % PATH)
	return _data


## Localized headline for `id`, "" when none.
static func of(id: String) -> String:
	var h := String(all().get(id, ""))
	return TranslationServer.translate(h) if h != "" else ""


static func has(id: String) -> bool:
	return String(all().get(id, "")) != ""


## Sets `label.text` and visibility from the headline. Returns whether it shows.
static func apply(label: Label, id: String) -> bool:
	var h := of(id)
	label.text = h
	label.visible = h != ""
	return h != ""
