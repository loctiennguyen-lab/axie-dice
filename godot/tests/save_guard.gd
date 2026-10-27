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
##
## BOTH FILES, NOT JUST META (2026-10-10)
## --------------------------------------
## Until 10 Oct this guarded `meta_save.json` only. Measured that day, one test at a time with
## md5 before and after: 23 gates deleted `run_save.json` — the player's run in progress — because
## starting a run or a combat calls `RunState.clear_saved_run()`. Every gate that already used
## SaveGuard was among them. The run save is now captured and put back the same way.
## `run_tests.sh` also hashes both files around every test and fails the one that changed them,
## so a gate that forgets SaveGuard (or quits before `restore()`) is caught, not silent.

const _PATHS := [MetaState.SAVE_PATH, RunState.SAVE_PATH]
## SIGN-IN FILES (2026-10-15): since 12/10 the project's config/name is "Axie Dice", the same user:// as the
## shipped desktop app, so account tests were deleting Liam's real desktop session (account.json +
## device_tokens.dat). These are copied byte for byte at capture() and put back (or removed) at restore().
const _RAW_PATHS := ["user://account.json", "user://account_prefs.json", "user://account_sync.json",
	"user://device_tokens.dat"]

var _backup := {}       # path -> text, only for files that existed at capture()
var _raw := {}          # user:// path -> bytes, sign-in files that existed at capture()
## ACCOUNT SAVES (2026-10-26): SaveStore keeps each signed-in profile under user://acct/<id>/. A test that switches
## SaveStore.profile writes there, not to the guest files above, and run_tests.sh hashes acct/ too. The whole tree is
## copied at capture() and put back at restore(): files that are new get deleted, changed ones rewritten.
const _ACCT_ROOT := "user://acct"
var _acct := {}         # user://acct/... path -> bytes, every file that existed at capture()
var _captured := false


func capture() -> void:
	_captured = true
	_backup.clear()
	_raw.clear()
	_acct.clear()
	for ap in _acct_files(_ACCT_ROOT):
		_acct[ap] = FileAccess.get_file_as_bytes(ap)
	for rp in _RAW_PATHS:
		if FileAccess.file_exists(rp):
			_raw[rp] = FileAccess.get_file_as_bytes(rp)
	for p in _PATHS:
		var real := SaveStore.path_for(SaveStore.profile, p)
		if FileAccess.file_exists(real):
			_backup[p] = FileAccess.get_file_as_string(real)


func restore() -> void:
	if not _captured:
		push_warning("SaveGuard.restore() called without capture() — nothing to put back, and "
			+ "the test has been writing to the player's real save file the whole time.")
		return
	for p in _PATHS:
		var real := SaveStore.path_for(SaveStore.profile, p)
		if _backup.has(p):
			var f := FileAccess.open(real, FileAccess.WRITE)
			if f == null:
				push_error("SaveGuard: could not reopen %s to restore it" % real)
				continue
			f.store_string(_backup[p])
			f.close()
		elif FileAccess.file_exists(real):
			# There was no save before the test ran. Leaving one behind would hand a fresh install a
			# progression history (or a run) it never played.
			DirAccess.remove_absolute(ProjectSettings.globalize_path(real))
	for rp in _RAW_PATHS:
		if _raw.has(rp):
			var rf := FileAccess.open(rp, FileAccess.WRITE)
			if rf == null:
				push_error("SaveGuard: could not reopen %s to restore it" % rp)
				continue
			rf.store_buffer(_raw[rp])
			rf.close()
		elif FileAccess.file_exists(rp):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(rp))
	for ap in _acct_files(_ACCT_ROOT):
		if not _acct.has(ap):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ap))
	for ap in _acct:
		var af := FileAccess.open(ap, FileAccess.WRITE)
		if af == null:
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path((ap as String).get_base_dir()))
			af = FileAccess.open(ap, FileAccess.WRITE)
		if af == null:
			push_error("SaveGuard: could not reopen %s to restore it" % ap)
			continue
		af.store_buffer(_acct[ap])
		af.close()
	_prune_empty_dirs(_ACCT_ROOT, false)
	MetaState.load_from_disk()


func _acct_files(dir: String) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_acct_files(dir.path_join(d)))
	return out


## Removes directories left empty under `dir` (the root itself only if it is empty and `drop_self`).
func _prune_empty_dirs(dir: String, drop_self: bool) -> void:
	for d in DirAccess.get_directories_at(dir):
		_prune_empty_dirs(dir.path_join(d), true)
	if drop_self and DirAccess.get_files_at(dir).is_empty() and DirAccess.get_directories_at(dir).is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))
