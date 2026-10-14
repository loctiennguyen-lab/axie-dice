class_name TitleNames
extends RefCounted
## Display side of player titles (C7). A title is owned as "title:<NAME>" in `cosmetics_owned`.
## Ascension titles (A5 / A10) come from assets/data/economy/ascension_titles.json: the owned id is
## built from the `vi` name (stable key), the shown text is `en` (falls back to `vi`). Other titles
## (Pass, Echo Box series) show their id without the prefix, capitalised like PassView does.

const PREFIX := "title:"
const _DB := preload("res://scripts/meta/economy_db.gd")


## [{asc:int, id:String, name:String}] ascending by Ascension.
static func ascension_titles() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var t: Dictionary = _DB.get_table("ascension_titles").get("titles", {})
	for k in t:
		var d: Dictionary = t[k]
		var vi := String(d.get("vi", ""))
		if vi == "":
			continue
		out.append({"asc": int(k), "id": PREFIX + vi, "name": String(d.get("en", vi)) if String(d.get("en", "")) != "" else vi})
	out.sort_custom(func(a, b) -> bool: return int(a["asc"]) < int(b["asc"]))
	return out


## Owned title ids ("title:..."), no duplicates, in the order they were gained.
static func owned(owned_ids: Array) -> Array[String]:
	var out: Array[String] = []
	for o in owned_ids:
		var s := String(o)
		if s.begins_with(PREFIX) and not out.has(s):
			out.append(s)
	return out


static func display(id: String) -> String:
	for t in ascension_titles():
		if String(t["id"]) == id:
			return String(t["name"])
	return id.trim_prefix(PREFIX).capitalize()
