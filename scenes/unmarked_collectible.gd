extends Area3D

## Hidden pickup: no waypoint arrow, just a faint glint. Walking onto it collects it.
## If res://assets/collectibles/<item_id>.glb exists it replaces the placeholder sphere.

const VISUAL_PATH := "res://assets/collectibles/%s.glb"
const GLINT := preload("res://shaders/collectible_glint.gdshader")
const GLINT_RANGE := 4.0  # metres at which the glint starts to strengthen

@export var item_id: String

var _glint: ShaderMaterial
var _player: Node3D

func _ready() -> void:
	add_to_group("collectible")  # TelemetryTracker counts available collectibles via this group
	if InventoryManager.was_found(item_id):
		queue_free()
		return
	body_entered.connect(_on_body_entered)
	var path := VISUAL_PATH % item_id
	if ResourceLoader.exists(path):
		$MeshInstance3D.hide()
		var visual := (load(path) as PackedScene).instantiate()
		add_child(visual)
		FloorSnap.snap(self, visual)
		_glint = ShaderMaterial.new()
		_glint.shader = GLINT
		for m in visual.find_children("*", "MeshInstance3D"):
			(m as MeshInstance3D).material_overlay = _glint
		return
	set_process(false)
	var mesh: MeshInstance3D = $MeshInstance3D
	var mat := mesh.material_override.duplicate() as StandardMaterial3D
	mesh.material_override = mat
	var tween := create_tween().set_loops()
	tween.tween_property(mat, "emission_energy_multiplier", 0.5, 1.2)
	tween.tween_property(mat, "emission_energy_multiplier", 2.0, 1.2)

func _process(_delta: float) -> void:
	if _player == null:
		# shortcut: searches the tree each frame until a Player exists; fine for one per room
		_player = get_tree().root.find_child("Player", true, false) as Node3D
		return
	var d := global_position.distance_to(_player.global_position)
	_glint.set_shader_parameter("proximity", clampf(1.0 - d / GLINT_RANGE, 0.0, 1.0))

func _on_body_entered(body: Node3D) -> void:
	if not (body is CharacterBody3D and body.name == "Player"):
		return
	InventoryManager.add(item_id)
	print("[TraitDeck] Collected ", item_id)
	queue_free()
