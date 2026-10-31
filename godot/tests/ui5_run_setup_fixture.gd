extends RefCounted
## UI-05 b23 lane S3a1: in-memory MetaState + RunSetup for the 7 main frames of round-3 "06-run-setup" (no disk writes:
## callers wrap with SaveGuard). Ids are the frame ids without the "06-run-setup--" prefix.
const IDS := ["stage1", "stage3", "a5", "full-locked", "newcomer", "daily", "ranked"]


## Sets MetaState for `id`, builds the screen (not yet in the tree) and returns it.
static func make(id: String, stub: Callable = Callable()) -> RunSetup:
	MetaState.unlocks.erase("u_full")
	MetaState.runs_with_battle = 9
	MetaState.runs_completed = 9
	MetaState.runs = 9
	MetaState.asc_max = 6
	var used := 1
	var asc := 0
	var kind := "normal"
	match id:
		"stage1":
			MetaState.runs_with_battle = 0
			MetaState.runs_completed = 0
			MetaState.runs = 0
			used = 0
		"stage3":
			MetaState.unlocks.append("u_full")
		"a5":
			asc = 5
		"full-locked":
			MetaState.asc_max = 3
			asc = 2
		"newcomer":
			MetaState.runs_with_battle = 2
			MetaState.runs_completed = 2
			MetaState.runs = 2
		"daily":
			MetaState.unlocks.append("u_full")
			kind = "daily"
		"ranked":
			MetaState.unlocks.append("u_full")
			kind = "ranked"
	var s: RunSetup = load("res://scenes/run_setup/RunSetup.tscn").instantiate()
	s.use_account = false
	s.remote_on = true
	s.no_scene_change = true
	s.daily_info_hook = func(cb: Callable) -> void: cb.call(true, {"used": used, "max": 3})
	s.account_status_hook = func() -> int: return AccountService.Status.SAVED
	if stub.is_valid():
		s.start_hook = stub
	s.ascension = asc
	s.set_meta("fx_kind", kind)
	return s


## After the screen is in the tree and the Daily tries arrived: applies the kind the frame shows.
static func apply_kind(s: RunSetup) -> void:
	s.select_kind(String(s.get_meta("fx_kind", "normal")))
