class_name UpdateRequired
extends RefCounted
## "Bản này cũ, tải bản mới" modal. Shown whenever the Worker refuses this build: POST /api/run answers
## 409 `version` (the client's rules version is no longer served) or 409 `mission_needs_update` (a Mission run
## only takes the newest rules while normal runs still accept the older one). Never shows a raw error code.
## One entry point for every place that calls a run: NetNotice (in-run and Continue), RunSetup (Begin),
## MissionsScreen (stake). `UpdateRequired.show(host)` builds a UI3 modal on its own CanvasLayer.

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")

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
	# UI-05 18-update: Scrim + dialog (Title, Body, Footer in 2 rows: UpdateButton full width with the Space keycap, Close under it).
	var root := UI3.ModalRoot.new()
	root.name = "Modal"
	root.theme = UI3Theme.get_theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_to_group("ui3_modal")
	root.add_child(NetParts.scrim())
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var pad := UI3Theme.space("32")
	var dlg := PanelParts.panel(PanelParts.plate_box("xl", pad), "UpdateRequiredMissions" if code == "mission_needs_update" else NODE_NAME)
	dlg.custom_minimum_size.x = UI3Theme.size_of("defeat_panel_w")
	center.add_child(dlg)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("20"))
	dlg.add_child(col)
	var head := VBoxContainer.new()
	head.name = "Head"
	head.add_theme_constant_override("separation", UI3Theme.space("12"))
	col.add_child(head)
	var ttl := Ui5Text.label(String(t[0]), "text_banner", "text", true)
	ttl.name = "Title"
	ttl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(ttl)
	var body := Ui5Text.label(String(t[1]), "text_body", "text")
	body.name = "Body"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	head.add_child(body)
	var close := PanelParts.button("Close", &"secondary", &"M")
	close.name = "CloseButton"
	var dl := PanelParts.button("Reload the page" if is_web() else "Download the new version", &"primary", &"M")
	dl.name = "UpdateButton"
	col.add_child(Ui5ModalFooter.make(dl, close, true))
	root.actions = [close, dl]
	root.focus_index = 1   # the primary: Space presses it
	layer.add_child(root)
	dl.pressed.connect(open_download)
	var m := root
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
	NetParts.place_space_cap(dl)   # Space presses the focused primary
	return layer


const BAR_NAME := "UpdateRequiredBar"


## "Update required" bar: thin, top-centre, on its own layer on the tree root so it outlives the scene
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
	var top := CenterContainer.new()
	top.name = "Top"
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = UI3Theme.space("screen")
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(top)
	# 18-update--bar: pill plate with a warn rim, [ToneDisc, message, UpdateButton]; stays after Close on every screen.
	var panel := PanelParts.panel(NetParts.hud_box("pill", UI3Theme.space("4"), UI3Theme.space("16"), UI3Theme.space("8"), true, UI3Theme.space("4") + int(PanelParts.lip(Color.BLACK).y)), "UpdateBar")
	panel.custom_minimum_size.y = UI3Theme.size_of("update_bar_h")
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE   # only the button takes clicks
	top.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("12"))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	row.add_child(Ui5ToneDisc.make(&"warn"))
	var msg := Ui5Text.label("Update required. New runs are blocked on this version.", "text_body", "text")
	msg.name = "Message"
	row.add_child(msg)
	var b := UI3.button("Reload the page" if is_web() else "Download", &"secondary", &"S")
	b.name = "UpdateButton"
	b.pressed.connect(open_download)
	row.add_child(b)
	tree.root.add_child(layer)
	return layer
