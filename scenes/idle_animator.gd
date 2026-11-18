class_name IdleAnimator
extends RefCounted

## Gives a character model a looping "idle" clip on its own AnimationPlayer:
## breathing (body scale), weight shift (body roll), a slow head turn (HeadPivot),
## and for the kitten an ear twitch (EarPivot*) and tail swish (TailPivot).
## Pivots come from art/src/build_characters.py. Keys are offsets from each node's current
## transform, so crowd students pre-rotated to face each other keep their facing.

const LENGTH := 4.8
const T := [0.0, 1.2, 2.4, 3.6, 4.8]

static func attach(model: Node3D) -> AnimationPlayer:
	var heads := model.find_children("HeadPivot*", "Node3D", true, false)
	if heads.is_empty():
		return null
	var anim := Animation.new()
	anim.length = LENGTH
	anim.loop_mode = Animation.LOOP_LINEAR
	for hp: Node3D in heads:
		var body := hp.get_parent() as Node3D
		var s := body.scale
		var breathe := s * Vector3(1.015, 1.03, 1.015)
		_track(anim, model, body, "scale", T, [s, breathe, s, breathe, s])
		var r := body.rotation
		var lean := deg_to_rad(2.0)
		_track(anim, model, body, "rotation", T, [r, r + Vector3(0, 0, lean), r, r - Vector3(0, 0, lean), r])
		var h := hp.rotation
		_track(anim, model, hp, "rotation", [0.0, 1.0, 2.0, 2.8, 3.8, 4.8],
			[h, h + Vector3(0.05, deg_to_rad(14), 0), h + Vector3(0.05, deg_to_rad(14), 0), h, h + Vector3(-0.03, deg_to_rad(-9), 0), h])
	for ear: Node3D in model.find_children("EarPivot*", "Node3D", true, false):
		var e := ear.rotation
		var at := 3.0 if ear.name.begins_with("EarPivotL") else 1.5
		_track(anim, model, ear, "rotation", [0.0, at, at + 0.08, at + 0.2, LENGTH],
			[e, e, e + Vector3(deg_to_rad(-25), 0, 0), e, e])
	for tail: Node3D in model.find_children("TailPivot*", "Node3D", true, false):
		var t := tail.rotation
		var keys: Array = []
		for i in 9:
			keys.append(t + Vector3(0, 0, deg_to_rad(18) * (1 if i % 2 else -1) * (0 if i in [0, 8] else 1)))
		_track(anim, model, tail, "rotation", [0.0, 0.6, 1.2, 1.8, 2.4, 3.0, 3.6, 4.2, 4.8], keys)
	var lib := AnimationLibrary.new()
	lib.add_animation(&"idle", anim)
	var player := AnimationPlayer.new()
	player.name = "IdleAnimation"
	model.add_child(player)  # root_node defaults to "..", i.e. the model
	player.add_animation_library(&"", lib)
	player.speed_scale = randf_range(0.85, 1.15)  # so a crowd does not breathe in sync
	player.play(&"idle")
	player.seek(randf() * LENGTH, true)
	return player

static func _track(anim: Animation, model: Node3D, node: Node3D, prop: String, times: Array, values: Array) -> void:
	var i := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(i, NodePath(str(model.get_path_to(node)) + ":" + prop))
	anim.track_set_interpolation_type(i, Animation.INTERPOLATION_CUBIC)
	for k in times.size():
		anim.track_insert_key(i, times[k], values[k])
