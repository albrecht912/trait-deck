extends SceneTree
# Run: godot --headless --path <project> -s res://tests/test_idle.gd
# Idle clip: built from a model's pivots, loops, animates the head, keeps a pre-rotated body's facing.
# Wind: foliage meshes get the shared sway material and set_strength reaches it.

const IdleAnimator := preload("res://scenes/idle_animator.gd")
const WindSway := preload("res://scenes/wind_sway.gd")

var failed := false

func check(name: String, ok: bool) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
	if not ok:
		failed = true

func _initialize() -> void:
	await process_frame
	var model := Node3D.new()
	var body := Node3D.new(); body.name = "Student0"; body.rotation = Vector3(0, 0, 1.2)  # crowd student facing inward
	var head := Node3D.new(); head.name = "HeadPivot_003"
	var tail := Node3D.new(); tail.name = "TailPivot"
	model.add_child(body); body.add_child(head); model.add_child(tail)
	root.add_child(model)
	var p := IdleAnimator.attach(model)
	check("player created and playing idle", p != null and p.is_playing() and p.current_animation == "idle")
	var anim := p.get_animation(&"idle")
	check("idle loops", anim.loop_mode == Animation.LOOP_LINEAR)
	p.speed_scale = 1.0
	p.seek(0.0, true)
	check("body keeps its facing at t=0", is_equal_approx(body.rotation.z, 1.2))
	p.seek(1.0, true)
	check("head turns", absf(head.rotation.y) > deg_to_rad(5))
	p.seek(1.2, true)
	check("body breathes", body.scale.y > 1.01)
	check("tail swishes", absf(tail.rotation.z) > deg_to_rad(5))
	var bare := Node3D.new()
	check("no pivots -> no player", IdleAnimator.attach(bare) == null)
	bare.free()
	model.free()

	var room := Node3D.new()
	var leaf := MeshInstance3D.new(); leaf.name = "Tree0Leaf2"; leaf.mesh = SphereMesh.new()
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.36, 0.68, 0.29); leaf.material_override = null
	leaf.mesh.surface_set_material(0, mat)
	var wall := MeshInstance3D.new(); wall.name = "WallBack"; wall.mesh = BoxMesh.new()
	room.add_child(leaf); room.add_child(wall)
	WindSway.apply(room)
	var sway := leaf.material_override as ShaderMaterial
	check("foliage gets the sway material", sway != null and sway.shader.resource_path.ends_with("foliage_sway.gdshader"))
	check("other meshes untouched", wall.material_override == null)
	check("albedo carried over", sway != null and sway.get_shader_parameter("albedo") == Color(0.36, 0.68, 0.29))
	WindSway.set_strength(3.0)
	check("storm strength reaches material", sway != null and sway.get_shader_parameter("wind_strength") == 3.0)
	WindSway.set_strength(1.0)
	sway.shader.get_shader_uniform_list()  # forces the compile; a SHADER ERROR would print here
	room.free()
	quit(1 if failed else 0)
