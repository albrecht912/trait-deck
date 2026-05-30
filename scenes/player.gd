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

## ==========================================
## LIFECYCLE
## ==========================================

func _ready() -> void:
	# NavigationAgent3D requires one deferred frame after the scene tree is
	# ready before its path queries are valid.
	nav_agent.velocity_computed.connect(_on_velocity_computed)

## ==========================================
## PUBLIC API
## ==========================================

## Called by MouseClickDetector when the player left-clicks a navigable surface.
## Feeds the 3D world-space hit point into the navigation agent as the new goal.
func set_movement_target(target_point: Vector3) -> void:
	nav_agent.target_position = target_point

## ==========================================
## PHYSICS LOOP
## ==========================================

func _physics_process(_delta: float) -> void:
	# Nothing to do if the agent has already reached its destination.
	if nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		move_and_slide()
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

	# Feed the desired velocity into the avoidance system (if enabled).
	# nav_agent.set_velocity(velocity)  ← uncomment if RVO avoidance is active.

	move_and_slide()

## ==========================================
## AVOIDANCE CALLBACK (optional)
## ==========================================

## Called by NavigationAgent3D when RVO avoidance computes a safe velocity.
## Only fires if nav_agent.avoidance_enabled = true.
func _on_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = safe_velocity
	move_and_slide()
