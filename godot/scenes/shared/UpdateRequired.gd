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


## True on the browser build: there the fix is a page reload, not a download.
static var web_override := -1   ## tests: 0 = desktop, 1 = web, -1 = real platform


static func is_web() -> bool:
	return OS.has_feature("web") if web_override < 0 else web_override == 1


## [title, body] for `code`. Pure (a test can check both). Says that nothing was lost.
static func texts_for(code: String) -> Array:
	var how := "Reload the page to get it" if is_web() else "Download it, then open the game again"
	if code == "mission_needs_update":
		return ["This version is out of date", "Missions need the newest version of the game. %s. Nothing was spent." % how]
	return ["This version is out of date", "The game has been updated and this version can't start new runs any more. %s. Nothing was spent." % how]


static func open_download() -> void:
	if is_web() and not open_url_hook.is_valid():
		JavaScriptBridge.eval("window.location.reload()")
		return
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
	var dl := UI3.button("Reload the page" if is_web() else "Download the new version", &"primary", &"M")
	dl.name = "DownloadButton"
	var m := UI3.modal(String(t[0]), String(t[1]), [close, dl], 1)
	layer.add_child(m)
	dl.pressed.connect(open_download)
	var dismiss := func() -> void:
		var tree := host.get_tree()
		if is_instance_valid(layer):
			layer.queue_free()
		show_bar(tree)   # S4-12: after Close a thin bar stays on every screen
		if on_close.is_valid():
			on_close.call()
	close.pressed.connect(dismiss)
	m.cancelled.connect(dismiss)
	host.add_child(layer)
	return layer


const BAR_NAME := "UpdateRequiredBar"


## "Update required" bar: thin, bottom-centre, on its own layer on the tree root so it outlives the scene
## change that follows Close. One at a time. Its button does the same as the modal's primary button.
static func show_bar(tree: SceneTree) -> Node:
	if tree == null or tree.root == null:
		return null
	var old := tree.root.get_node_or_null(BAR_NAME)
	if old != null:
		return old
	var layer := CanvasLayer.new()
	layer.name = BAR_NAME
	layer.layer = 110
	var bottom := CenterContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -72
	bottom.offset_bottom = -16
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(bottom)
	var panel := UI3.plate(&"notice")
	panel.name = "Panel"
	bottom.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)
	row.add_child(UI3.label("Update required. New runs are blocked on this version."))
	var b := UI3.button("Reload the page" if is_web() else "Download", &"secondary", &"S")
	b.name = "BarButton"
	b.pressed.connect(open_download)
	row.add_child(b)
	tree.root.add_child(layer)
	return layer
