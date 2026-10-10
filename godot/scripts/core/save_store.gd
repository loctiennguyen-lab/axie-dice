class_name SaveStore
extends Object
## Where a save actually lives. One place, because the answer differs per platform and getting
## it wrong is invisible until a player loses everything.
##
## WHY THIS EXISTS — MEASURED, NOT ASSUMED (2026-09-20)
## ----------------------------------------------------
## Godot's `user://` on a web export is an in-memory filesystem that the engine syncs to
## IndexedDB. In this project's own exported build, that sync does not happen reliably: after a
## clean start, three consecutive page loads each wrote the save successfully and each read
## back NOTHING. The file appeared in IndexedDB once and then stopped being updated while the
## game kept writing to it.
##
## That failure mode is worse than no saving at all. Every write succeeds, every read inside
## the same session returns what was written, and nothing anywhere reports an error — the
## player simply finds their progress gone the next day, and no log says why.
##
## Forcing Emscripten's own flush was tried first and is not reachable: `JavaScriptBridge.eval`
## runs in page scope, where `FS` is inside the module closure —
## `ReferenceError: FS is not defined`.
##
## So on the web the save goes to `localStorage`, which is synchronous, has no flush to miss,
## and is written through `JavaScriptBridge.get_interface()` rather than string-built JavaScript
## so a save containing a quote can never break the call. Measured on the same build: 1, 2, 3
## across three reloads.
##
## The FILE is still written on web as well. It costs nothing, and it means a future engine
## version that fixes its own syncing leaves a save this class can still read.

## `localStorage` is per-origin and shared with anything else on that origin, so the key says
## whose it is.
const _WEB_KEY_PREFIX := "axiedice:"


static func is_web() -> bool:
	return OS.has_feature("web")


## WHOSE SAVE IT IS (accounts, claude/ACCOUNT_SYSTEM_v1.md §5)
## ---------------------------------------------------------
## `profile` is "" for a guest and the signed-in player's id ("google:<sub>") otherwise. A
## guest keeps the exact keys and files every build before accounts used, so an existing player's
## progress is found where it always was. A signed-in player's saves live under their own key, so
## two people signing in on one browser can never load each other's progress.
##
## Set by AccountService before MetaState loads (it is listed earlier in the autoloads).
static var profile := ""

## Called after every write or erase made for the CURRENT profile while it is not the guest, so
## AccountService can schedule an upload. Writes AccountService makes itself (applying a cloud
## save, bookkeeping) go through the `_as` variants with `notify = false` and do not fire it.
static var on_changed: Callable = Callable()


## Writes `text` at `path`. Returns false only when nothing at all could be written — on web
## that means localStorage AND the file both failed, which is the case where a caller should
## tell the player rather than carry on.
static func write_text(path: String, text: String) -> bool:
	return write_text_as(profile, path, text, true)


## The stored text, or "" when there is none. On web localStorage wins over the file: it is the
## copy that survives, and a stale file left by an earlier engine sync would otherwise silently
## roll a player back.
static func read_text(path: String) -> String:
	return read_text_as(profile, path)


static func exists(path: String) -> bool:
	return exists_as(profile, path)


static func erase(path: String) -> void:
	erase_as(profile, path, true)


## Where `path` lives for `who`. The guest path is `path` itself.
static func path_for(who: String, path: String) -> String:
	if who.is_empty():
		return path
	return "user://acct/%s/%s" % [who.replace(":", "_").validate_filename(), path.get_file()]


static func write_text_as(who: String, path: String, text: String, notify: bool = false) -> bool:
	var real := path_for(who, path)
	if not who.is_empty():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(real.get_base_dir()))
	var wrote_file := _write_file(real, text)
	var ok := wrote_file
	if is_web():
		var store := _local_storage()
		if store == null:
			# Private-browsing modes can refuse localStorage entirely. The file write is then the
			# only copy, and it is the unreliable one — say so rather than returning success.
			push_warning("SaveStore: localStorage unavailable; the web save may not survive a reload")
		else:
			store.setItem(_WEB_KEY_PREFIX + real, text)
			ok = true
	if ok and notify:
		_notify(who)
	return ok


static func read_text_as(who: String, path: String) -> String:
	var real := path_for(who, path)
	if is_web():
		var store := _local_storage()
		if store != null:
			var raw: Variant = store.getItem(_WEB_KEY_PREFIX + real)
			if raw != null:
				var text := str(raw)
				if not text.is_empty():
					return text
	return _read_file(real)


static func exists_as(who: String, path: String) -> bool:
	var real := path_for(who, path)
	if is_web():
		var store := _local_storage()
		if store != null and store.getItem(_WEB_KEY_PREFIX + real) != null:
			return true
	return FileAccess.file_exists(real)


static func erase_as(who: String, path: String, notify: bool = false) -> void:
	var real := path_for(who, path)
	if is_web():
		var store := _local_storage()
		if store != null:
			store.removeItem(_WEB_KEY_PREFIX + real)
	if FileAccess.file_exists(real):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(real))
	if notify:
		_notify(who)


static func _notify(who: String) -> void:
	if not who.is_empty() and who == profile and on_changed.is_valid():
		on_changed.call()


# ---------------------------------------------------------------------------

## The browser's localStorage object, or null off the web / when the browser refuses it.
## Fetched through `get_interface` rather than `eval` so values travel as values: a save
## pasted into a JavaScript string would break on the first quote it contains.
static func _local_storage() -> JavaScriptObject:
	if not is_web():
		return null
	return JavaScriptBridge.get_interface("localStorage")


static func _write_file(path: String, text: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	f.close()
	return true


static func _read_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var text := f.get_as_text()
	f.close()
	return text
