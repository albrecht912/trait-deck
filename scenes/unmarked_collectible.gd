extends Area3D

## Hidden pickup: no waypoint arrow, just a faint glint. Walking onto it collects it.

@export var item_id: String

func _ready() -> void:
	if InventoryManager.was_found(item_id):
		queue_free()
		return
	var mesh: MeshInstance3D = $MeshInstance3D
	var mat := mesh.material_override.duplicate() as StandardMaterial3D
	mesh.material_override = mat
	var tween := create_tween().set_loops()
	tween.tween_property(mat, "emission_energy_multiplier", 0.5, 1.2)
	tween.tween_property(mat, "emission_energy_multiplier", 2.0, 1.2)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not (body is CharacterBody3D and body.name == "Player"):
		return
	InventoryManager.add(item_id)
	print("[TraitDeck] Collected ", item_id)
	queue_free()
