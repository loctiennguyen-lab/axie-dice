class_name Chipify
extends RefCounted
## UI-06 detail-text chips. Numbers (with an optional unit word: Mana, Shield, Thorns, poison, damage, Max HP, HP, M)
## become number chips; glossary keywords (SET, Cracked, Held, Hold, Overcast, Temp Face, Wild Face, Gamble, Focus)
## become keyword chips. Same regex as design build/gen-ui06a.js `chipify`. Two views of the same split:
## segments() for tests and custom builders, bbcode() for a RichTextLabel (bgcolor + colour from tokens).

const KEYWORDS := ["Temp Face", "Wild Face", "SET", "Cracked", "Held", "Hold", "Overcast", "Gamble", "Focus"]
const UNITS := ["Mana", "Shield", "Thorns", "poison", "damage", "Max HP", "HP", "M"]
const KIND_TEXT := "text"
const KIND_NUM := "num"
const KIND_KW := "kw"

static var _re: RegEx = null


static func _regex() -> RegEx:
	if _re == null:
		_re = RegEx.create_from_string("\\b(%s)\\b|([+\\-−]?\\d+(?:\\.\\d+)?%%?(?![\\w.])(?:\\s(?:%s)\\b)?)" % ["|".join(KEYWORDS), "|".join(UNITS)])
	return _re


## Splits `text` into [{text, kind}] where kind is KIND_TEXT / KIND_NUM / KIND_KW. Joining the texts gives `text` back.
static func segments(text: String) -> Array:
	var out: Array = []
	var pos := 0
	for m in _regex().search_all(text):
		var s := m.get_start()
		if s > pos:
			out.append({"text": text.substr(pos, s - pos), "kind": KIND_TEXT})
		var kw := m.get_string(1)
		out.append({"text": m.get_string(), "kind": KIND_KW if kw != "" else KIND_NUM})
		pos = m.get_end()
	if pos < text.length():
		out.append({"text": text.substr(pos), "kind": KIND_TEXT})
	return out


## BBCode for a RichTextLabel (bbcode_enabled = true). Plain text is escaped (a "[" in data never opens a tag).
static func bbcode(text: String) -> String:
	var nb := UI3Theme.color("num_chip_bg").to_html(false)
	var nt := UI3Theme.color("num_chip_text").to_html(false)
	var kb := UI3Theme.color("kw_chip_bg").to_html(false)
	var kt := UI3Theme.color("text").to_html(false)
	var out := ""
	for s in segments(text):
		var t := String(s["text"]).replace("[", "[lb]")
		match s["kind"]:
			KIND_NUM:
				out += "[bgcolor=#%s][color=#%s] %s [/color][/bgcolor]" % [nb, nt, t]
			KIND_KW:
				out += "[bgcolor=#%s][color=#%s] %s [/color][/bgcolor]" % [kb, kt, t]
			_:
				out += t
	return out
