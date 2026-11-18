extends Area3D

## Room-tidying task: walking onto the messy object tweens it to its tidy spot.
## TelemetryTracker scores done/total tidy tasks as Conscientiousness when the room ends.

@export var task_id: String
## Tidy transform, in the parent's space.
@export var tidy_position: Vector3
@export var tidy_rotation_deg: Vector3

## Optional model res://assets/props/tidy_<task_id>.glb with "Messy" and "Tidy" child nodes.
const VISUAL_PATH := "res://assets/props/tidy_%s.glb"
var _visual: Node3D

func _ready() -> void:
	assert(task_id != "", "TidyTask needs a task_id")
	add_to_group("tidy_task")
	var path := VISUAL_PATH % task_id
	if ResourceLoader.exists(path):
		$MeshInstance3D.hide()
		_visual = (load(path) as PackedScene).instantiate()
		add_child(_visual)
		_show_tidy(false)
	if TelemetryTracker.tidied.has(task_id):
		_snap_tidy()
		return
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not (body is CharacterBody3D and body.name == "Player"):
		return
	body_entered.disconnect(_on_body_entered)
	TelemetryTracker.tidied[task_id] = true
	print("[TraitDeck] Tidied ", task_id)
	_show_tidy(true)
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position", tidy_position, 0.4)
	tween.tween_property(self, "rotation_degrees", tidy_rotation_deg, 0.4)
	$CollisionShape3D.set_deferred("disabled", true)

func _snap_tidy() -> void:
	position = tidy_position
	rotation_degrees = tidy_rotation_deg
	$CollisionShape3D.disabled = true
	_show_tidy(true)

func _show_tidy(tidy: bool) -> void:
	if _visual == null:
		return
	# Prefix match: Blender may export them as "Messy.001" (imported as "Messy_001").
	_visual.find_child("Messy*", true, false).visible = not tidy
	_visual.find_child("Tidy*", true, false).visible = tidy
