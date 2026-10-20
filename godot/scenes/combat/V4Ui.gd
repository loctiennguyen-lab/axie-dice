class_name V4Ui
extends RefCounted
## Depth v4 combat UI helpers (spec design/ux/depth-v4/combat-v4.md). Pure strings and numbers: the engine
## owns every value, this file only words them. All text goes through tr() (TranslationServer).

## Engine SLOT_ORDER: the index of a die face is also the index of its part.
const SLOT_ORDER := ["mouth", "horn", "back", "tail", "eyes", "ears"]
const PART_WORD := {"mouth": "MOUTH", "horn": "HORN", "back": "BACK", "tail": "TAIL", "eyes": "EYES", "ears": "EARS"}
const PART_PLURAL := {"mouth": "MOUTHS", "horn": "HORNS", "back": "BACKS", "tail": "TAILS", "eyes": "EYES", "ears": "EARS"}
const SIZE_WORD := {3: "THREE", 4: "FOUR", 5: "FIVE"}


static func _T(k: String) -> String:
	return TranslationServer.translate(k)


static func part_name(part_index: int) -> String:
	if part_index < 0 or part_index >= SLOT_ORDER.size():
		return ""
	return _T(String(PART_WORD[SLOT_ORDER[part_index]]))


## "x1.4" from an m100 (140 -> "x1.4"); never hard-coded, follows the bo.scale knob.
static func mult_text(m100: int) -> String:
	var v := float(m100) / 100.0
	var s := "%.2f" % v
	if s.ends_with("0"):
		s = "%.1f" % v
	return "×" + s


## Group label on the tray: "SET OF 3 ×1.4".
static func set_label(size: int, m100: int) -> String:
	return "%s %d %s" % [_T("SET OF"), size, mult_text(m100)]


## Banner for four / five: "FOUR HORNS ×1.8!" (3 has no banner).
static func banner_text(part_index: int, size: int, m100: int) -> String:
	var part := String(SLOT_ORDER[clampi(part_index, 0, 5)])
	var ex := "!!" if size >= 5 else "!"
	return "%s %s %s%s" % [_T(String(SIZE_WORD.get(size, ""))), _T(String(PART_PLURAL[part])), mult_text(m100), ex]


static func has_banner(size: int) -> bool:
	return size >= 4


## Group of `uid` in a bo snapshot, or {}.
static func group_of(bo: Array, uid: int) -> Dictionary:
	for g in bo:
		if (g["uids"] as Array).has(uid):
			return g
	return {}


## Banner seconds by tier (spec 1.4): four 0.8, five 1.2.
static func banner_secs(size: int) -> float:
	return 1.2 if size >= 5 else 0.8
