extends Node
## Arena v2 background preloading (lane C): ArenaV2Diorama.preload_biomes / packed_scene.
## Checks dedupe, the 2-biome cap, that the stage uses the same resource the preload returned,
## and (forced threaded path, also under --headless) that a finished request is collected.

var _fails: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_arena_preload: start ===")
	var journey: Array = CombatArena3D.registry().get("journey", [])
	_assert(journey.size() >= 3, "journey has fewer than 3 biomes")
	for forced in [false, true]:
		ArenaV2Diorama.force_threaded = forced
		ArenaV2Diorama.clear_preload()
		await _run(journey, forced)
	ArenaV2Diorama.force_threaded = false
	ArenaV2Diorama.clear_preload()
	print("=== t_arena_preload: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_arena_preload: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_arena_preload: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)


func _wait_ready(id: String) -> void:
	for _i in 600:
		if ArenaV2Diorama.is_ready(id):
			return
		await get_tree().process_frame


func _run(journey: Array, forced: bool) -> void:
	var tag := "[threaded=%s] " % forced
	var a := String(journey[0])
	var b := String(journey[1])
	var c := String(journey[2])
	var first := ArenaV2Diorama.preload_biomes([a, b, c, a, "nope"])
	_assert(first == [a, b], tag + "first request should start exactly the first 2 biomes, got %s" % [first])
	_assert(not ArenaV2Diorama.is_requested(c), tag + "third biome must not be requested (cap 2)")
	_assert(not ArenaV2Diorama.is_requested("nope"), tag + "unknown biome must be ignored")
	_assert(ArenaV2Diorama.preload_biomes([a, b]).is_empty(), tag + "second request must be a no-op")
	await _wait_ready(a)
	_assert(ArenaV2Diorama.is_ready(a), tag + "biome a never became ready")
	_assert(ArenaV2Diorama.preload_biomes([a, b]).is_empty(), tag + "request after ready must be a no-op")
	var ps := ArenaV2Diorama.packed_scene(a)
	_assert(ps != null, tag + "packed_scene(a) null")
	_assert(ArenaV2Diorama.packed_scene(a) == ps, tag + "packed_scene must return the same resource every time")
	_assert(ps == load(ArenaV2Diorama.scene_path(a)), tag + "preloaded scene differs from load() (cache not shared)")
	# The stage must build from that very resource.
	var d := ArenaV2Diorama.new()
	add_child(d)
	_assert(d.build(a, false), tag + "build(a) failed")
	_assert(d.get_node("Diorama").scene_file_path == ps.resource_path, tag + "built node not from the preloaded scene")
	d.queue_free()
	# Moving on: wanting only b + c drops a from the cache but keeps b; never more than 2 at once.
	var next := ArenaV2Diorama.preload_biomes([b, c])
	_assert(next == [c], tag + "moving on should request only c, got %s" % [next])
	_assert(not ArenaV2Diorama.is_requested(a), tag + "a should be released once it is no longer wanted")
	_assert(ArenaV2Diorama.is_requested(b) and ArenaV2Diorama.is_requested(c), tag + "b and c should be held")
	await _wait_ready(c)
	_assert(ArenaV2Diorama.packed_scene(c) != null, tag + "packed_scene(c) null")
	# Not preloaded at all: packed_scene falls back to a sync load.
	ArenaV2Diorama.clear_preload()
	_assert(ArenaV2Diorama.packed_scene(a) != null, tag + "sync fallback returned null")
