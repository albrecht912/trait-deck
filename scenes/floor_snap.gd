class_name FloorSnap
extends Node3D

## Drops a bottom-pivot model onto whatever collider lies under it (the rooms' -col/-colonly meshes).
## Attach this script to a placed model, or call FloorSnap.snap(anchor, model) from another script.
## Room markers were placed for old centred placeholders and float 0.1-0.8 m above the floor.

func _ready() -> void:
	FloorSnap.snap(self, self)
	IdleAnimator.attach(self)  # placed characters/crowds idle too; no-op for models without a HeadPivot

static func snap(anchor: Node3D, model: Node3D) -> void:
	await anchor.get_tree().physics_frame  # room collision bodies enter the physics space one frame after load
	if not is_instance_valid(anchor) or not is_instance_valid(model):
		return
	var from := anchor.global_position + Vector3.UP * 0.5
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 3.0)
	var hit := anchor.get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		model.global_position.y = hit.position.y
