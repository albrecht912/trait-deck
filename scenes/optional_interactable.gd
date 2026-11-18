extends Area3D

## Optional point of interest or NPC: walking onto it shows a line and logs the first visit.

@export_enum("poi", "npc") var kind: String = "poi"
@export var interact_id: String
@export_multiline var line: String
## Optional model: res://assets/characters/<character>.glb replaces the placeholder capsule.
@export var character: String

func _ready() -> void:
	assert(interact_id != "", "OptionalInteractable needs an interact_id")
	add_to_group("optional_" + kind)
	$MeshInstance3D.visible = kind == "npc"
	var path := "res://assets/characters/%s.glb" % character
	if character != "" and ResourceLoader.exists(path):
		$MeshInstance3D.hide()
		var model := (load(path) as PackedScene).instantiate() as Node3D
		add_child(model)
		FloorSnap.snap(self, model)
		CharacterAnimator.attach(model)
	$Label3D.text = line
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not (body is CharacterBody3D and body.name == "Player"):
		return
	$Label3D.visible = true
	TelemetryTracker.mark_interacted(kind, interact_id)
	await get_tree().create_timer(4.0).timeout
	$Label3D.visible = false
