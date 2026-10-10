extends SceneTree
## Spike helper: prints the world-space AABB size of every scene in spike_assets.txt.
## godot --headless --path godot --script prototypes/land_spike/measure.gd

func _init() -> void:
	var f := FileAccess.open("res://prototypes/land_spike/spike_assets.txt", FileAccess.READ)
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var path := "res://prototypes/land_spike/homeland/" + line
		var ps := load(path) as PackedScene
		if ps == null:
			print("LOAD FAIL ", path)
			continue
		var n: Node3D = ps.instantiate()
		root.add_child(n)
		var box := _aabb(n, Transform3D.IDENTITY)
		print("%-40s size=(%.2f, %.2f, %.2f) pos=(%.2f, %.2f, %.2f)" % [line.get_file(),
			box.size.x, box.size.y, box.size.z, box.position.x, box.position.y, box.position.z])
		n.queue_free()
	quit()


func _aabb(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is VisualInstance3D:
		var b: AABB = t * (n as VisualInstance3D).get_aabb()
		out = b
		first = false
	for c in n.get_children():
		var cb := _aabb(c, t)
		if cb.size == Vector3.ZERO:
			continue
		if first:
			out = cb
			first = false
		else:
			out = out.merge(cb)
	return out
