class_name RunContinue
extends RefCounted
## The online half of every CONTINUE button (Land, MainMenu, RunSetup). Call right after RunState.load_run()
## succeeded and before changing scene: with a remote epoch source the session has to find its run again.
##
##     match await RunContinue.reconnect(self, _on_continue_pressed):
##         "ok": change scene
##         "gone": the save was discarded (RunState.take_discard_notice() has the line): go to / stay on Land
##         "busy": another Continue is still in flight, do nothing
##         "failed": NetNotice is up (RETRY calls `retry`, or SIGN IN); stay where you are


## True while a Continue is reconnecting. Every handler checks it BEFORE load_run(): a second press would run
## load_run again and a second open_existing, which revokes the first run token.
static var busy: bool = false


## `button` (optional) is disabled while the reconnect is out and given back after.
static func reconnect(host: Node, retry: Callable, button: BaseButton = null) -> String:
	if busy:
		return "busy"
	busy = true
	if is_instance_valid(button):
		button.disabled = true
	var res: Dictionary = await RunState.resume_online()
	busy = false
	if is_instance_valid(button):
		button.disabled = false
	if bool(res["ok"]):
		return "ok"
	var code := String(res["code"])
	if code == "run_gone":
		return "gone"
	NetNotice.show(host, code, retry, "Could not load your run")
	return "failed"
