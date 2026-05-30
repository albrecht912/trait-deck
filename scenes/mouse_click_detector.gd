extends Node

## ==========================================
## MouseClickDetector.gd
## Attach to a Node child of MainScene (e.g. a Node named "MouseClickDetector").
## Casts a 3D physics ray from the fixed Camera3D into the room geometry on
## every left mouse click, then forwards the hit position to Player.gd.
##
## UI Guard: clicks consumed by CanvasLayer UI elements (cards, buttons) are
## automatically ignored because _unhandled_input only fires when no Control
## node has already handled the event.
## ==========================================

## ==========================================
## NODE REFERENCES
## Set these in the Inspector or adjust the paths to match your scene tree.
## ==========================================

@onready var camera_3d: Camera3D = $"../Camera3D"
@onready var player: Player      = $"../Player"

## ==========================================
## RAY CAST DEPTH
## ==========================================

## How far (in metres) the ray travels into the scene before giving up.
const RAY_LENGTH: float = 1000.0

## ==========================================
## INPUT HANDLER
## ==========================================

## _unhandled_input fires ONLY when no Control / CanvasLayer node has already
## consumed the event — this is the built-in UI guard for free.
func _unhandled_input(event: InputEvent) -> void:
	# Only react to a left mouse button press.
	if not (event is InputEventMouseButton):
		return

	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return

	# Cast the ray and move the player if we hit something.
	_cast_ray_and_move(mb.position)

## ==========================================
## RAY CAST LOGIC
## ==========================================

## Projects a ray from the camera through the 2D screen position into 3D space.
## If the ray hits a physics body (floor mesh, collision surface), the hit point
## is forwarded to Player.set_movement_target().
func _cast_ray_and_move(screen_pos: Vector2) -> void:
	if camera_3d == null:
		push_warning("[MouseClickDetector] camera_3d reference is null.")
		return

	if player == null:
		push_warning("[MouseClickDetector] player reference is null.")
		return

	# --- Build the ray in world space ---
	var from: Vector3 = camera_3d.project_ray_origin(screen_pos)
	var to: Vector3   = from + camera_3d.project_ray_normal(screen_pos) * RAY_LENGTH

	# --- Query the 3D physics world ---
	var space_state: PhysicsDirectSpaceState3D = camera_3d.get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D     = PhysicsRayQueryParameters3D.create(from, to)

	# Exclude the player's own collision body so it doesn't block the ray.
	query.exclude = [player.get_rid()]

	var result: Dictionary = space_state.intersect_ray(query)

	# --- Forward the hit position to the player ---
	if result.has("position"):
		var hit_point: Vector3 = result["position"]
		player.set_movement_target(hit_point)
		print("[MouseClickDetector] Move target → %s" % hit_point)
