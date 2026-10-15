class_name RunContinue
extends RefCounted
## The online half of every CONTINUE button (Land, MainMenu, RunSetup). Call right after RunState.load_run()
## succeeded and before changing scene: with a remote epoch source the session has to find its run again.
##
##     match await RunContinue.reconnect(self, _on_continue_pressed):
##         "ok": change scene
##         "gone": the save was discarded (RunState.take_discard_notice() has the line): go to / stay on Land
##         "failed": NetNotice is up (RETRY calls `retry`, or SIGN IN); stay where you are


static func reconnect(host: Node, retry: Callable) -> String:
	var res: Dictionary = await RunState.resume_online()
	if bool(res["ok"]):
		return "ok"
	var code := String(res["code"])
	if code == "run_gone":
		return "gone"
	NetNotice.show(host, code, retry)
	return "failed"
