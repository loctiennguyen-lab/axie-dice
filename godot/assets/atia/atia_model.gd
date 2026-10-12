extends Node3D
## Root script of every assets/atia/<key>/<key>.tscn wrapper (L1 lane C).
## The Atia FBX files ship without their texture linked (Unity linked it through a .mat that did
## not come along), so the wrapper carries the albedo and this applies it to every mesh.

@export var albedo: Texture2D


func _ready() -> void:
	if albedo == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = albedo
	mat.roughness = 0.9
	for n in find_children("*", "MeshInstance3D", true, false):
		(n as MeshInstance3D).material_override = mat
