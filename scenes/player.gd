class_name Player
extends CharacterBody3D

## ==========================================
## Player.gd
## Point-and-click CharacterBody3D controller.
## Receives a 3D world-space target from MouseClickDetector and navigates
## to it along the room's pre-baked NavigationRegion3D navmesh.
## ==========================================

## ==========================================
## EXPORT PROPERTIES
## ==========================================

## Movement speed in metres per second.
@export var speed: float = 5.0

## ==========================================
## NODE REFERENCES
## ==========================================

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

## Idle/walk clips on the protagonist model (see CharacterAnimator).
var _anim: AnimationPlayer

## How fast the body turns to face its walking direction (higher = snappier).
const TURN_SPEED := 12.0

## ==========================================
## LIFECYCLE
## ==========================================

func _ready() -> void:
	# NavigationAgent3D requires one deferred frame after the scene tree is
	# ready before its path queries are valid.
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	_anim = CharacterAnimator.attach(self)

## ==========================================
## PUBLIC API
## ==========================================

## Called by MouseClickDetector when the player left-clicks a navigable surface.
## Feeds the 3D world-space hit point into the navigation agent as the new goal.
func set_movement_target(target_point: Vector3) -> void:
	nav_agent.target_position = target_point

## Instantly relocates the player to a world-space position without any
## movement lag or residual velocity artifacts.
## Called by SessionManager after each room loads to snap the player to SpawnPoint.
func teleport_to_position(target_global_pos: Vector3) -> void:
	# 1. Override position cleanly.
	global_position = target_global_pos

	# 2. Halt all momentum so the player doesn't slide on arrival, and face the camera again.
	velocity = Vector3.ZERO
	rotation.y = 0.0
	CharacterAnimator.set_walking(_anim, false)

	# 3. Flush the navigation agent's waypoint cache so it doesn't try to
	#    resume a stale path from the previous room.
	if has_node("NavigationAgent3D"):
		$NavigationAgent3D.target_position = target_global_pos

## ==========================================
## PHYSICS LOOP
## ==========================================

func _physics_process(delta: float) -> void:
	# Nothing to do if the agent has already reached its destination.
	if nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		move_and_slide()
		CharacterAnimator.set_walking(_anim, false)
		return

	# Retrieve the next waypoint along the baked navmesh path.
	var next_waypoint: Vector3 = nav_agent.get_next_path_position()

	# Compute a flat horizontal direction vector toward the waypoint.
	var direction: Vector3 = (next_waypoint - global_position)
	direction.y = 0.0          # Ignore vertical component — floor-plane movement only.
	direction = direction.normalized()

	# Apply speed and let move_and_slide() handle collision response.
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y = 0.0           # No gravity — navmesh keeps the agent on the floor.

	# Face the walking direction (the model faces +Z) and play the walk cycle.
	if direction.length_squared() > 0.0:
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), clampf(TURN_SPEED * delta, 0.0, 1.0))
	CharacterAnimator.set_walking(_anim, direction.length_squared() > 0.0)

	move_and_slide()

## ==========================================
## AVOIDANCE CALLBACK (optional)
## ==========================================

## Called by NavigationAgent3D when RVO avoidance computes a safe velocity.
## Only fires if nav_agent.avoidance_enabled = true.
func _on_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = safe_velocity
	move_and_slide()
