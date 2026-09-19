class_name SaveGuard
extends RefCounted
## Borrows the player's real save file for the duration of a test, and puts it back byte for byte.
##
## WHY THIS EXISTS
## ---------------
## `MetaState` is an autoload over `user://meta_save.json` — there is no second instance a test
## can borrow, so every gate that exercises progression writes to the file a real player's run
## history lives in. Measured on 2026-09-19 with `shasum` before and after each gate:
## `t_full_run_loop`, `t_meta_progression` and `t_run_save` all left it changed. Running the suite
## was quietly adding runs and XP to the player's own save.
##
## WHY NOT RESTORE THE FIELDS BY HAND
## ----------------------------------
## `t_meta_progression` already did that — it snapshots nine fields and puts them back. It still
## left the file dirty, for two reasons that are both permanent: the restore happens in memory
## while the test has already called `save_to_disk()`, and `end_run()` touches fields
## (`runs`/`wins`/`best`/`daily_date`) that a hand-written list has to be kept in step with
## forever. A list of fields to restore is a list that falls behind the thing it restores.
## Copying the bytes cannot fall behind.
##
## USE:
##     var _guard := SaveGuard.new()
##     func _ready() -> void:
##         _guard.capture()
##         ... tests ...
##         _guard.restore()
##
## `restore()` also reloads MetaState from the restored file, so anything later in the same
## process sees the player's real values rather than the test's leftovers.

var _backup := ""
var _had_save := false
var _captured := false


func capture() -> void:
	_captured = true
	_had_save = FileAccess.file_exists(MetaState.SAVE_PATH)
	_backup = FileAccess.get_file_as_string(MetaState.SAVE_PATH) if _had_save else ""


func restore() -> void:
	if not _captured:
		push_warning("SaveGuard.restore() called without capture() — nothing to put back, and "
			+ "the test has been writing to the player's real save file the whole time.")
		return
	if _had_save:
		var f := FileAccess.open(MetaState.SAVE_PATH, FileAccess.WRITE)
		if f == null:
			push_error("SaveGuard: could not reopen %s to restore it" % MetaState.SAVE_PATH)
			return
		f.store_string(_backup)
		f.close()
	elif FileAccess.file_exists(MetaState.SAVE_PATH):
		# There was no save before the test ran. Leaving one behind would hand a fresh install a
		# progression history it never played.
		DirAccess.remove_absolute(ProjectSettings.globalize_path(MetaState.SAVE_PATH))
	MetaState.load_from_disk()
