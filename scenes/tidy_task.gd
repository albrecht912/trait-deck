extends Area3D

## Room-tidying task: walking onto the messy object tweens it to its tidy spot.
## TelemetryTracker scores done/total tidy tasks as Conscientiousness when the room ends.

@export var task_id: String
## Tidy transform, in the parent's space.
@export var tidy_position: Vector3
@export var tidy_rotation_deg: Vector3

func _ready() -> void:
	assert(task_id != "", "TidyTask needs a task_id")
	add_to_group("tidy_task")
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
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position", tidy_position, 0.4)
	tween.tween_property(self, "rotation_degrees", tidy_rotation_deg, 0.4)
	$CollisionShape3D.set_deferred("disabled", true)

func _snap_tidy() -> void:
	position = tidy_position
	rotation_degrees = tidy_rotation_deg
	$CollisionShape3D.disabled = true
