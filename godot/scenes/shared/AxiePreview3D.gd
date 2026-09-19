class_name AxiePreview3D
extends Control
## Live 3D preview of one real Axie, built from its gene string. The picture the Vault screen
## shows when a player types an Axie ID.
##
## WHY THE ADDON'S RENDERER AND NOT ANOTHER SUBVIEWPORT
## ---------------------------------------------------
## `tools/render_portraits.gd` builds its own SubViewport + camera + lights, and copying that here
## was the first plan. It was the wrong one: the vendored addon already ships `AxieAvatarRenderer`
## + `AxieAvatarRenderParams` for exactly this, ported from Unity's `AxieAvatarRenderer`, and
## `third_party/…/examples/avatars_demo.gd` is this use case verbatim — an Axie from genes drawn
## into a `TextureRect`, static and realtime. Hand-rolling it would have duplicated the addon and
## quietly diverged from its framing convention, which is the one every other Axie tool renders to.
##
## The die portraits keep their own tool for a different reason: they are baked PNGs of six fixed
## class rigs, produced offline and shipped as assets. This is a live view of an arbitrary Axie.
##
## HOW IT AVOIDS SHOWING UP IN THE GAME
## ------------------------------------
## `AxieAvatarRenderer` isolates the character with a render-layer cull mask, and its viewport
## shares the ROOT world (`own_world_3d = false`) — it has to, that is how it sees the character.
## So the character really does stand in whatever world the host scene lives in, and the addon's
## own header notes that avatar layer 20 is inside the DEFAULT camera cull mask. A preview opened
## in a scene that has a Camera3D would therefore put an Axie on screen next to the real ones.
##
## Two things prevent that, and both are needed:
##   - the stage sits at `STAGE_ORIGIN`, far under the floor. The avatar camera is placed in the
##     character's LOCAL frame (see AxieAvatarRenderer._place_camera), so moving the character
##     cannot change the framing — this costs nothing.
##   - the key light's `light_cull_mask` is narrowed to the avatar layer, so a DirectionalLight3D
##     added for the preview cannot re-light a battlefield. A directional light has no position;
##     the offset above would not have contained it.
##
## WHAT IT REPORTS
## ---------------
## `set_genes()` returns (and `preview_updated` carries) the full `AxieGenePreview.inspect()`
## report, and the badge shows `AxieGenePreview.warning_text()` whenever the rig did not come out
## whole. A part-less Axie reads as "a strange Axie" otherwise, and this project has paid for that
## kind of silence more than once.

signal preview_updated(report: Dictionary)

## Far below any playfield. Only has to be outside a game camera's frustum; the avatar camera
## follows the character's own transform, so the value is not a framing parameter.
const STAGE_ORIGIN := Vector3(0.0, -1000.0, 0.0)

## Distance between two previews' stages.
##
## WHY PREVIEWS MUST NOT SHARE A SPOT — a bug this cost a capture to find, and one no assertion in
## `t_axie_gene_preview` could ever have seen. `AxieAvatarRenderer` isolates a character with a
## render LAYER, and every preview uses the same layer in the same world. Two previews standing at
## the same coordinates are therefore both inside both cameras' cull masks, and each one renders
## the two of them on top of each other. The report said "Fuzzy, colour 4, 6/6 parts" while the
## picture was four Axies composited into one — right numbers, wrong animal, no error anywhere.
##
## The avatar camera is orthographic with a 4-unit deep slab and a ~2-unit wide view, so a stage
## this far away falls outside both; 100 is chosen for headroom, not because the frustum needs it.
const STAGE_SPACING := 100.0

## Slot bookkeeping, shared by every preview alive at once. A free list rather than an ever-rising
## counter: a Vault screen opened and closed repeatedly would otherwise walk the stages out to
## coordinates where float precision starts to show.
static var _slots_in_use: Dictionary = {}

## Model-space view. `(0, 0, -1)` puts the camera on the model's +Z side looking back at it — the
## front, matching `examples/avatars_demo.gd`'s first snapshot and `collection_demo.gd`'s comment
## that "front is +Z". A preview of the back of an Axie's head would be the same picture for every
## Axie, which is the same argument that put the die portraits face-on.
const VIEW_DIRECTION := Vector3(0.0, -0.18, -1.0)
const VIEW_CENTER := Vector3(0.0, 0.78, 0.0)
const RENDER_SIZE := 512

## Preview refresh rate, deliberately far below the display's.
##
## WHY THIS IS NOT 60fps. Each `render()` re-arms a 512x512 SubViewport AND makes the addon walk
## the character's entire mesh tree to re-stamp a layer bitmask it already stamped last frame
## (`AxieAvatarRenderer._tag_visuals`). A vault holds up to twenty records, `ScrollContainer` does
## NOT cull the rows scrolled out of sight, and `is_visible_in_tree()` stays true for every one of
## them — so the naive version was twenty full viewport passes and twenty whole-tree walks per
## frame, most of them for Axies nobody could see. An idle animation reads as alive at 12fps; the
## other 48 frames were paying for nothing.
const REFRESH_HZ := 12.0

@onready var _frame: TextureRect = $Frame
@onready var _warning: PanelContainer = $Warning
@onready var _warning_label: Label = $Warning/Margin/WarningLabel

var _stage: Node3D
var _sun: DirectionalLight3D
var _character: AxieCharacter3D
var _renderer: AxieAvatarRenderer
var _params: AxieAvatarRenderParams
var _report: Dictionary = {}
var _slot := -1
## Genes handed to `set_genes()` before this node entered the tree. See `_ready()`.
var _pending_genes := ""
var _has_pending := false
var _since_render := 0.0
## The scrolling region this preview lives in, if any. Found once — a preview never moves between
## containers, and walking the ancestors every frame would be its own small version of the problem
## this field exists to fix.
var _clip_rect_source: Control = null


func _ready() -> void:
	_slot = _take_slot()
	_stage = Node3D.new()
	_stage.name = "PreviewStage"
	_stage.position = STAGE_ORIGIN + Vector3(_slot * STAGE_SPACING, 0.0, 0.0)
	add_child(_stage)

	_sun = DirectionalLight3D.new()
	_sun.name = "PreviewKeyLight"
	_sun.rotation_degrees = Vector3(-38.0, -28.0, 0.0)
	_sun.light_energy = 1.35
	# See the header: without this the preview's light spills onto the whole world.
	_sun.light_cull_mask = 1 << (AxieAvatarRenderer.AVATAR_LAYER - 1)
	_sun.shadow_enabled = false
	_stage.add_child(_sun)

	_params = AxieAvatarRenderParams.new()
	_params.width = RENDER_SIZE
	_params.height = RENDER_SIZE
	_params.view_center = VIEW_CENTER
	_params.view_direction = VIEW_DIRECTION

	_warning.visible = false
	set_process(false)
	_clip_rect_source = _find_scroll_ancestor()

	# A caller that configured this preview while building a row — before the row was added to
	# anything — gets its Axie now. Without this the call lands on a node whose `_ready()` has not
	# run: `_stage` and the two @onready children are null, the rig is never built, and the panel
	# sits there empty. The Vault screen builds its rows exactly that way, and the only symptom
	# was four `add_child on a null value` lines that a passing test scrolled straight past.
	if _has_pending:
		var genes := _pending_genes
		_has_pending = false
		_pending_genes = ""
		set_genes(genes)


func _exit_tree() -> void:
	_release()
	if _slot >= 0:
		_slots_in_use.erase(_slot)
		_slot = -1


static func _take_slot() -> int:
	var i := 0
	while _slots_in_use.has(i):
		i += 1
	_slots_in_use[i] = true
	return i


## The whole public surface. Returns the inspection report so a caller that needs the numbers
## (how many parts resolved, whether the gene was empty) does not have to wait for the signal.
func set_genes(genes: String) -> Dictionary:
	_report = AxieGenePreview.inspect(genes)
	if _stage == null:
		# Called before `_ready()`. The report is still correct and still returned — it is pure —
		# but the rig cannot be built until this node is in the tree. Remember and do it there.
		_pending_genes = genes
		_has_pending = true
		preview_updated.emit(_report)
		return _report
	_release()

	# Explicit `as`, not an implicit Variant assignment: if `inspect()` ever returns something
	# else under "descriptor", this yields null and the branch below reports a failed build,
	# instead of failing somewhere later with no connection to the change that caused it.
	var desc := _report.get("descriptor") as AxieDescriptor
	if desc != null:
		_character = AxieCharacter3D.from_descriptor(desc)
	if _character != null and _character.root != null:
		_stage.add_child(_character.root)
		_character.root.position = Vector3.ZERO
		_character.root.rotation_degrees.y = 0.0   # front toward the avatar camera
		if _character.playable != null:
			_character.playable.set_default(AnimNames.Idle)
			_character.playable.play(AnimNames.Idle, "", true)
		_renderer = AxieAvatarRenderer.new(_character)
		set_process(true)
	else:
		# Nothing to draw. Clear the frame rather than leaving the previous Axie on screen, which
		# would read as "this ID is that Axie".
		_frame.texture = null
		set_process(false)

	var warning := AxieGenePreview.warning_text(_report)
	_warning.visible = not warning.is_empty()
	_warning_label.text = warning

	preview_updated.emit(_report)
	return _report


## The last report, for a caller that wants to re-read it (the Vault list deciding whether an
## entry may be added, for instance).
func report() -> Dictionary:
	return _report


## Clears the preview back to empty — used when the ID field is cleared.
func clear_preview() -> void:
	_release()
	_pending_genes = ""
	_has_pending = false        # or a queued Axie would appear the moment the node enters the tree
	_report = {}
	if _frame != null:
		_frame.texture = null
	if _warning != null:
		_warning.visible = false


func _process(delta: float) -> void:
	if _renderer == null or not is_visible_in_tree():
		return
	# `is_visible_in_tree()` is NOT enough inside a ScrollContainer: it stays true for rows that
	# have been scrolled completely out of view, because the container clips them rather than
	# hiding them. Ask whether this row actually overlaps the visible region.
	if not _is_on_screen():
		return
	_since_render += delta
	if _since_render < 1.0 / REFRESH_HZ:
		return
	_since_render = 0.0
	# `render()` arms the viewport for one draw; calling it repeatedly is how the addon's own
	# realtime example animates (examples/avatars_demo.gd:_process).
	var tex := _renderer.render(null, _params)
	if tex != null:
		_frame.texture = tex


func _is_on_screen() -> bool:
	var mine := get_global_rect()
	if mine.size.x <= 0.0 or mine.size.y <= 0.0:
		return false
	var region := _clip_rect_source.get_global_rect() if _clip_rect_source != null \
		else get_viewport_rect()
	return mine.intersects(region)


func _find_scroll_ancestor() -> Control:
	var n := get_parent()
	while n != null:
		if n is ScrollContainer:
			return n as Control
		n = n.get_parent()
	return null


func _release() -> void:
	set_process(false)
	if _renderer != null:
		_renderer.dispose()
		_renderer = null
	if _character != null:
		_character.dispose()
		_character = null
