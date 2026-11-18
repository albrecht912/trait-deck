extends SceneTree
# Run: godot --headless --path <project> -s res://tests/test_animation.gd
# Character clips: idle and walk are built from a model's pivots, loop, keep a pre-rotated body's facing,
# swing legs and arms in opposition, and settle back to rest when switching to idle.
# Wind: foliage meshes get the shared sway material and set_strength reaches it.

const CharacterAnimator := preload("res://scenes/character_animator.gd")
const WindSway := preload("res://scenes/wind_sway.gd")

var failed := false

func check(name: String, ok: bool) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
	if not ok:
		failed = true

func pivot(parent: Node, name: String) -> Node3D:
	var n := Node3D.new(); n.name = name; parent.add_child(n); return n

func _initialize() -> void:
	await process_frame
	var model := Node3D.new()
	var body := pivot(model, "Student0"); body.rotation = Vector3(0, 0, 1.2)  # crowd student facing inward
	var head := pivot(body, "HeadPivot_003")
	var hip_l := pivot(body, "HipPivotL"); var hip_r := pivot(body, "HipPivotR")
	var arm_l := pivot(body, "ShoulderPivotL")
	var tail := pivot(model, "TailPivot")
	root.add_child(model)
	var p := CharacterAnimator.attach(model)
	check("player created and playing idle", p != null and p.is_playing() and p.current_animation == "idle")
	check("idle and walk loop", p.get_animation(&"idle").loop_mode == Animation.LOOP_LINEAR and p.get_animation(&"walk").loop_mode == Animation.LOOP_LINEAR)
	p.speed_scale = 1.0
	p.seek(0.0, true)
	check("body keeps its facing at t=0", is_equal_approx(body.rotation.z, 1.2))
	p.seek(1.0, true)
	check("head turns", absf(head.rotation.y) > deg_to_rad(5))
	p.seek(1.2, true)
	check("body breathes", body.scale.y > 1.01)
	check("tail swishes", absf(tail.rotation.z) > deg_to_rad(5))
	check("limbs at rest while idle", absf(hip_l.rotation.x) < 0.001 and absf(arm_l.rotation.x) < 0.001)

	p.play(&"walk")  # no blend, so seek() shows the clip itself
	p.seek(0.0, true)
	check("left leg forward, right leg back", hip_l.rotation.x < -0.3 and hip_r.rotation.x > 0.3)
	check("left arm swings opposite the left leg", arm_l.rotation.x > 0.2)
	check("walk keeps the body's facing", absf(body.rotation.z - 1.2) < deg_to_rad(4))
	p.seek(0.125, true)
	check("body bobs up at the passing step", body.position.y > 0.04)
	p.seek(0.25, true)
	check("legs swap at the next contact", hip_l.rotation.x > 0.3 and hip_r.rotation.x < -0.3)
	p.seek(0.125, true)  # mid-step: body up, limbs passing
	CharacterAnimator.set_walking(p, true)  # already walking: must not restart or blend
	check("set_walking(true) while walking keeps the clip running", p.current_animation == "walk" and is_equal_approx(p.current_animation_position, 0.125))
	p.seek(0.25, true)
	CharacterAnimator.set_walking(p, false)
	await create_timer(0.4).timeout  # let real frames run past the 0.15 s blend
	check("back to idle", p.current_animation == "idle")
	check("limbs settle to rest after walking", absf(hip_l.rotation.x) < 0.01 and absf(arm_l.rotation.x) < 0.01)
	check("squash released after walking", body.scale.y > 0.99)

	var bare := Node3D.new()
	check("no pivots -> no player", CharacterAnimator.attach(bare) == null)
	CharacterAnimator.set_walking(null, true)  # must not crash for models without pivots
	bare.free()
	model.free()

	var room := Node3D.new()
	var leaf := MeshInstance3D.new(); leaf.name = "Tree0Leaf2"; leaf.mesh = SphereMesh.new()
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.36, 0.68, 0.29)
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
