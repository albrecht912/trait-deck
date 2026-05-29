extends Camera3D

## ==========================================
## Camera3D.gd
## Attached to the Camera3D node in MainScene.
## Receives room-specific camera configuration from SessionManager
## and smoothly interpolates to the target position each physics frame.
## ==========================================

@export var smooth_speed: float = 5.0

# Current operating mode — forced to "Static" globally for now.
var active_mode: String = "Static"

# The world-space position this camera should converge toward.
var target_base_position: Vector3 = Vector3.ZERO

## Called by SessionManager immediately after a new room is loaded.
## Snaps the camera to the room's configured position and rotation.
func setup_camera_for_room(mode: String, room_pos: Vector3, room_rot: Vector3) -> void:
	# Force static behaviour globally until other modes are implemented.
	active_mode = "Static"

	# Apply rotation immediately so the view snaps to the correct angle.
	rotation_degrees = room_rot

	# Store the target position for smooth interpolation.
	target_base_position = room_pos

	# Snap global_position instantly on room load to avoid a visible slide-in.
	global_position = room_pos

## Smoothly interpolates toward the target position every physics tick.
func _physics_process(delta: float) -> void:
	global_position = global_position.lerp(target_base_position, smooth_speed * delta)
