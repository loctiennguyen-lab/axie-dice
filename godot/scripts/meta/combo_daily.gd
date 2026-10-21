class_name ComboDaily
extends RefCounted
## Lane GM (D2): the daily challenge "Form combo X". Pure: the combo of a UTC day is picked from the Pair-tier combos
## (ids sorted) by a stable hash of the date, so every device agrees. Reward is cosmetic only (titles), never Shards.

const TITLE_FIRST := "title:Combo Maker"
const TITLE_SEVENTH := "title:Combo Master"
const MILESTONES := {1: TITLE_FIRST, 7: TITLE_SEVENTH}


static func _hash(s: String) -> int:
	var h := 5381
	for b in s.to_utf8_buffer():
		h = (h * 33 + int(b)) & 0x7fffffff
	return h


## Combo id for `day` ("YYYY-MM-DD"), "" when no combo has a Pair tier to form.
static func pick(day: String, combos: Array) -> String:
	var ids: Array[String] = []
	for c in combos:
		if (c as Dictionary).get("pair", null) is Array:
			ids.append(String((c as Dictionary).get("id", "")))
	ids.sort()
	return "" if ids.is_empty() else ids[_hash(day) % ids.size()]
