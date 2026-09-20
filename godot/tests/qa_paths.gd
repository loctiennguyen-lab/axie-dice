class_name QaPaths
extends RefCounted
## Where QA captures are written.
##
## This used to be a hardcoded `/Users/loc.tien.nguyen/my-game/production/qa/evidence` in every
## qa_*.gd. That path does not exist on a CI box, in a container, or on anybody else's machine,
## so the captures silently went nowhere and the "sửa → chạy → nhìn" loop had no `nhìn`.
## Resolved from the project folder instead, with an env override for a sandbox that mounts the
## repo somewhere else.


static func evidence_dir() -> String:
	var env := OS.get_environment("ADT_EVIDENCE_DIR")
	if env != "":
		return env
	# res:// is <repo>/godot, so the evidence folder is one level up.
	return ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence") \
		.simplify_path()
