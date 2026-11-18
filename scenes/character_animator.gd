class_name CharacterAnimator
extends RefCounted

## Builds "idle" and "walk" clips for a character model on its own AnimationPlayer and starts idle.
##   idle (4.8 s): breathing, weight shift, slow head turn; kitten ear twitch + tail swish.
##   walk (0.5 s, two steps): legs swing from HipPivot*, arms counter-swing from ShoulderPivot*,
##        body bobs at each passing step and squashes slightly on each footfall.
## Pivot empties come from art/src/build_characters.py. Keys are offsets from each node's rest pose,
## so crowd students pre-rotated to face each other keep their facing. Both clips key the same
## body/head/limb properties, so blending between them always settles back to the rest pose.

const IDLE_LENGTH := 4.8
const WALK_LENGTH := 0.5
const BLEND := 0.15

static func attach(model: Node3D) -> AnimationPlayer:
	var heads := model.find_children("HeadPivot*", "Node3D", true, false)
	if heads.is_empty():
		return null
	var idle := _clip(IDLE_LENGTH)
	var walk := _clip(WALK_LENGTH)
	var it := [0.0, 1.2, 2.4, 3.6, 4.8]
	var wt := [0.0, 0.125, 0.25, 0.375, 0.5]  # contact, passing, contact, passing, contact
	for hp: Node3D in heads:
		var body := hp.get_parent() as Node3D
		var s := body.scale
		var r := body.rotation
		var p := body.position
		var h := hp.rotation
		var breathe := s * Vector3(1.015, 1.03, 1.015)
		var lean := Vector3(0, 0, deg_to_rad(2.0))
		_track(idle, model, body, "scale", it, [s, breathe, s, breathe, s])
		_track(idle, model, body, "rotation", it, [r, r + lean, r, r - lean, r])
		_track(idle, model, body, "position", [0.0, IDLE_LENGTH], [p, p])
		_track(idle, model, hp, "rotation", [0.0, 1.0, 2.0, 2.8, 3.8, 4.8],
			[h, h + Vector3(0.05, deg_to_rad(14), 0), h + Vector3(0.05, deg_to_rad(14), 0), h, h + Vector3(-0.03, deg_to_rad(-9), 0), h])
		var squash := s * Vector3(1.04, 0.95, 1.04)
		var roll := Vector3(0, 0, deg_to_rad(3.0))
		var up := p + Vector3(0, 0.06, 0)
		var nod := h + Vector3(0.06, 0, 0)
		_track(walk, model, body, "scale", wt, [squash, s, squash, s, squash])
		_track(walk, model, body, "rotation", wt, [r + roll, r, r - roll, r, r + roll])
		_track(walk, model, body, "position", wt, [p, up, p, up, p])
		_track(walk, model, hp, "rotation", wt, [h, nod, h, nod, h])
		for limb: Node3D in body.get_children().filter(func(n): return n is Node3D and (n.name.begins_with("HipPivot") or n.name.begins_with("ShoulderPivot"))):
			var rest := limb.rotation
			var left := limb.name.contains("PivotL")
			var amp := deg_to_rad(28.0) if limb.name.begins_with("Hip") else deg_to_rad(-22.0)  # arms swing opposite the legs
			var fwd := rest - Vector3(amp if left else -amp, 0, 0)  # rotating -X swings a limb toward +Z (forward)
			var back := rest + Vector3(amp if left else -amp, 0, 0)
			_track(walk, model, limb, "rotation", wt, [fwd, rest, back, rest, fwd])
			_track(idle, model, limb, "rotation", [0.0, IDLE_LENGTH], [rest, rest])
	for ear: Node3D in model.find_children("EarPivot*", "Node3D", true, false):
		var e := ear.rotation
		var at := 3.0 if ear.name.begins_with("EarPivotL") else 1.5
		_track(idle, model, ear, "rotation", [0.0, at, at + 0.08, at + 0.2, IDLE_LENGTH],
			[e, e, e + Vector3(deg_to_rad(-25), 0, 0), e, e])
	for tail: Node3D in model.find_children("TailPivot*", "Node3D", true, false):
		var t := tail.rotation
		var keys: Array = []
		for i in 9:
			keys.append(t + Vector3(0, 0, deg_to_rad(18) * (1 if i % 2 else -1) * (0 if i in [0, 8] else 1)))
		_track(idle, model, tail, "rotation", [0.0, 0.6, 1.2, 1.8, 2.4, 3.0, 3.6, 4.2, 4.8], keys)
	var lib := AnimationLibrary.new()
	lib.add_animation(&"idle", idle)
	lib.add_animation(&"walk", walk)
	var player := AnimationPlayer.new()
	player.name = "CharacterAnimation"
	model.add_child(player)  # root_node defaults to "..", i.e. the model
	player.add_animation_library(&"", lib)
	player.speed_scale = randf_range(0.85, 1.15)  # so a crowd does not breathe in sync
	player.play(&"idle")
	player.seek(randf() * IDLE_LENGTH, true)
	return player

## Switch between idle and walk with a short blend; repeated calls with the same state do nothing.
static func set_walking(player: AnimationPlayer, walking: bool) -> void:
	if player:
		player.play(&"walk" if walking else &"idle", BLEND)

static func _clip(length: float) -> Animation:
	var a := Animation.new()
	a.length = length
	a.loop_mode = Animation.LOOP_LINEAR
	return a

static func _track(anim: Animation, model: Node3D, node: Node3D, prop: String, times: Array, values: Array) -> void:
	var i := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(i, NodePath(str(model.get_path_to(node)) + ":" + prop))
	anim.track_set_interpolation_type(i, Animation.INTERPOLATION_CUBIC)
	for k in times.size():
		anim.track_insert_key(i, times[k], values[k])
