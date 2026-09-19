extends Node
## OPT-IN PROBE — not a gate, not run by `godot/tools/run_tests.sh` (name starts with `probe_`).
##
## Asks one question, with data instead of opinion: can the table the gene-code import would need —
## `(slot, class, variant)` -> the marketplace part name that `axie_to_die.gd` keys on — be BUILT
## from Axies we can already fetch? The gateway hands back `newGenes` AND `parts` in the same
## response, so every Axie fetched is six free rows of that table. This probe pairs them and
## reports whether the pairing is a function: one key, always one part.
##
## Usage: fetch a sample with curl into a JSON array of `{id, class, newGenes, parts[]}`, then
##   AXIE_SAMPLE=/abs/path/sample.json \
##   Godot --headless --path godot res://tests/probe_part_map.tscn

const DEFAULT_SAMPLE := "/private/tmp/claude-501/axie_sample.json"


func _ready() -> void:
	await get_tree().process_frame
	var path := OS.get_environment("AXIE_SAMPLE")
	if path.is_empty():
		path = DEFAULT_SAMPLE
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		print("PROBE: cannot read sample at %s" % path)
		get_tree().quit(1)
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Array):
		print("PROBE: sample is not a JSON array")
		get_tree().quit(1)
		return

	var table := {}          # "slot|class|variant|skin" -> {part_id: times_seen}
	var by_name := {}        # same key -> {base_name: times_seen}
	var rows := 0
	var skipped_axies := 0
	var slot_names := {}     # what the two sides call the six slots, to prove they line up

	for entry in (parsed as Array):
		var axie: Dictionary = entry
		var report := AxieGenePreview.inspect(str(axie.get("newGenes", "")))
		if not bool(report.get("ok", false)):
			skipped_axies += 1
			continue
		# API side, keyed by slot so the pairing never depends on array order.
		var api_by_slot := {}
		for p in (axie.get("parts", []) as Array):
			var pd: Dictionary = p
			api_by_slot[_norm_slot(str(pd.get("type", "")))] = pd
		for gp in (report.get("parts", []) as Array):
			var g: Dictionary = gp
			# The two sides name two of the six slots differently — the gene decoder says
			# "eye"/"ear", the marketplace says "eyes"/"ears". Unnormalised, those two slots
			# simply never matched and the probe reported 64 rows out of 96 as if that were the
			# whole picture, with nothing failing.
			var slot := _norm_slot(str(g.get("slot", "")))
			slot_names[slot] = true
			if not api_by_slot.has(slot):
				continue
			var api: Dictionary = api_by_slot[slot]
			# `skin` belongs in the key. Without it `tail|Aquatic|02` collides: tail-koi and
			# tail-kuro-koi are the same variant in two skins, and a table that dropped skin
			# would hand the die whichever of the two it happened to see last.
			var key := "%s|%s|%02d|%s" % [slot, str(g.get("part_class", "")),
				int(g.get("variant", -1)), str(g.get("skin", ""))]
			var seen: Dictionary = table.get(key, {})
			var pid := str(api.get("id", ""))
			seen[pid] = int(seen.get(pid, 0)) + 1
			table[key] = seen
			# `axie_to_die.gd` keys on the part NAME through base_name(), not on the marketplace
			# id — and the two disagree: the Origin re-issue of a part carries a `-2` id
			# (ears-small-frill-2) under the same name. Measuring both says which one the table
			# has to be built on.
			var nseen: Dictionary = by_name.get(key, {})
			var nm := AxieToDie.base_name(str(api.get("name", "")))
			nseen[nm] = int(nseen.get(nm, 0)) + 1
			by_name[key] = nseen
			rows += 1

	var name_conflicts := 0
	for k in by_name.keys():
		if (by_name[k] as Dictionary).size() > 1:
			name_conflicts += 1
			print("  NAME CONFLICT %s -> %s" % [k, str((by_name[k] as Dictionary).keys())])
	var conflicts := 0
	var keys := table.keys()
	keys.sort()
	for k in keys:
		var seen: Dictionary = table[k]
		if seen.size() > 1:
			conflicts += 1
			print("  CONFLICT %s -> %s" % [k, str(seen.keys())])

	print("--- sample: %d axies (%d unusable), %d part rows" % [
		(parsed as Array).size(), skipped_axies, rows])
	print("--- slots the gene decoder named: %s" % str(slot_names.keys()))
	print("--- distinct keys: %d · conflicting by marketplace id: %d · by part NAME: %d" % [
		keys.size(), conflicts, name_conflicts])
	for k in keys:
		print("    %s -> %s" % [k, str((by_name[k] as Dictionary).keys()[0])])
	print("PROBE DONE")
	get_tree().quit(0)


## "Eye"/"Eyes" and "Ear"/"Ears" are the same slot under two names.
static func _norm_slot(raw: String) -> String:
	var s := raw.strip_edges().to_lower()
	if s == "eye":
		return "eyes"
	if s == "ear":
		return "ears"
	return s
