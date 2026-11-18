class_name WindSway
extends RefCounted

## Swaps the baked palette materials on a room's tree/bush meshes for the foliage_sway shader.
## One ShaderMaterial per palette colour is shared by every room, so set_strength() reaches them all.

const SHADER := preload("res://shaders/foliage_sway.gdshader")
const NAMES := ["Leaf", "Trunk", "Hedge", "Bush"]  # mesh names written by art/src/build_*.py

static var _materials: Dictionary = {}  # Color -> ShaderMaterial
static var _strength := 1.0

static func apply(room: Node) -> void:
	for mi: MeshInstance3D in room.find_children("*", "MeshInstance3D", true, false):
		if not NAMES.any(func(n: String) -> bool: return mi.name.contains(n)):
			continue
		var base := mi.get_active_material(0) as BaseMaterial3D
		if base:
			mi.material_override = _material_for(base.albedo_color)

static func set_strength(strength: float) -> void:
	_strength = strength
	for m: ShaderMaterial in _materials.values():
		m.set_shader_parameter("wind_strength", strength)

static func _material_for(color: Color) -> ShaderMaterial:
	if not _materials.has(color):
		var m := ShaderMaterial.new()
		m.shader = SHADER
		m.set_shader_parameter("albedo", color)
		m.set_shader_parameter("wind_strength", _strength)
		_materials[color] = m
	return _materials[color]
