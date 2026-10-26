class_name UpdateRequired
extends RefCounted
## "Bản này cũ, tải bản mới" modal. Shown whenever the Worker refuses this build: POST /api/run answers
## 409 `version` (the client's rules version is no longer served) or 409 `mission_needs_update` (a Mission run
## only takes the newest rules while normal runs still accept the older one). Never shows a raw error code.
## One entry point for every place that calls a run: NetNotice (in-run and Continue), RunSetup (Begin),
## MissionsScreen (stake). `UpdateRequired.show(host)` builds a UI3 modal on its own CanvasLayer.

## Fixed download page for the desktop build. Change the address HERE only (production/beta-plan.md section 5:
## the link stays the same from build to build; the real place is decided with Liam).
const DOWNLOAD_URL := "https://axiedice.fun/download"
const NODE_NAME := "UpdateRequired"

## Tests: replaces OS.shell_open. Callable(url:String).
static var open_url_hook: Callable = Callable()


## True for the Worker/RemoteEpochSource codes that mean "this build is too old".
static func is_update_code(code: String) -> bool:
	return code == "version" or code == "mission_needs_update"


## [title, body] for `code`. Pure (a test can check both). Says that nothing was lost.
static func texts_for(code: String) -> Array:
	if code == "mission_needs_update":
		return ["This version is out of date", "Missions need the newest version of the game. Download it, then open the game again. Nothing was spent."]
	return ["This version is out of date", "The game has been updated and this version can't start new runs any more. Download the new version, then open the game again. Nothing was spent."]


static func open_download() -> void:
	if open_url_hook.is_valid():
		open_url_hook.call(DOWNLOAD_URL)
	else:
		OS.shell_open(DOWNLOAD_URL)


## Shows (or replaces) the modal on `host`. `on_close` (optional) runs after Close (e.g. back to Land).
static func show(host: Node, code := "version", on_close: Callable = Callable()) -> Node:
	if host == null or not host.is_inside_tree():
		return null
	var old := host.get_node_or_null(NODE_NAME)
	if old != null:
		host.remove_child(old)
		old.queue_free()
	var layer := CanvasLayer.new()
	layer.name = NODE_NAME
	layer.layer = 120   # above NetNotice (100) and the run HUD layers
	var t := texts_for(code)
	var close := UI3.button("Close", &"secondary", &"M")
	close.name = "CloseButton"
	var dl := UI3.button("Download the new version", &"primary", &"M")
	dl.name = "DownloadButton"
	var m := UI3.modal(String(t[0]), String(t[1]), [close, dl], 1)
	layer.add_child(m)
	dl.pressed.connect(open_download)
	var dismiss := func() -> void:
		if is_instance_valid(layer):
			layer.queue_free()
		if on_close.is_valid():
			on_close.call()
	close.pressed.connect(dismiss)
	m.cancelled.connect(dismiss)
	host.add_child(layer)
	return layer
