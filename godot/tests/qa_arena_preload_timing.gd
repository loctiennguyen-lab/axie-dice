extends Node
## Lane C QA: first-fight diorama cost per biome, cold sync load vs the cost after a background
## preload. Not headless-meaningful (headless loads sync): run through with_lock.sh without --headless.
## Prints the main-thread time of ArenaV2Diorama.build() (the hitch the player feels).

func _ready() -> void:
	var journey: Array = CombatArena3D.registry().get("journey", [])
	await get_tree().process_frame
	print("--- cold: build() loads the GLB on the spot ---")
	var cold := {}
	for b in journey:
		ArenaV2Diorama.clear_preload()
		cold[b] = _time_build(String(b))
	print("--- warm: preload_biomes(), wait for the thread, then build() ---")
	for b in journey:
		ArenaV2Diorama.clear_preload()
		ArenaV2Diorama.preload_biomes([b])
		var frames := 0
		while not ArenaV2Diorama.is_ready(String(b)) and frames < 1200:
			await get_tree().process_frame
			frames += 1
		var warm := _time_build(String(b))
		print("%-9s cold %6.1f ms   warm %6.1f ms   (ready after %d frames)" % [b, cold[b], warm, frames])
	get_tree().quit(0)


func _time_build(id: String) -> float:
	var d := ArenaV2Diorama.new()
	add_child(d)
	var t0 := Time.get_ticks_usec()
	d.build(id, false)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	d.queue_free()
	return ms
