extends Node3D
class_name BaseRoom

## ==========================================
## BaseRoom.gd
## Shared template script for all environment scenes in TraitDeck.
## Attach this script (or a script that extends it) to the root node
## of every room scene (mahallah_room.tscn, mo_office.tscn, etc.).
##
## SessionManager reads the three exported variables below to:
##   1. Configure the Camera3D position and rotation for this room.
##   2. Teleport the player to the SpawnPoint Marker3D child node.
##
## The ActiveWaypoint/Area3D body_entered signal should be connected
## to _on_area_3d_body_entered() in the Godot editor for each room scene.
## ==========================================

## Camera mode string — reserved for future use ("Static", "Follow", etc.)
@export var camera_mode: String = "Static"

## World-space position the Camera3D should snap to when this room loads.
@export var custom_camera_position: Vector3 = Vector3(0.0, 3.0, 6.0)

## Euler rotation in degrees the Camera3D should adopt when this room loads.
@export var custom_camera_rotation: Vector3 = Vector3(-15.0, 0.0, 0.0)

## ==========================================
## ACTIVE WAYPOINT TRIGGER
## ==========================================

## Connected to ActiveWaypoint/Area3D body_entered signal in the editor.
## Fires when any CharacterBody3D enters the waypoint collision volume.
## Relays the event to SessionManager to trigger the assessment phase.
func _on_area_3d_body_entered(body: Node3D) -> void:
	# Only react to the Player character — ignore other physics bodies.
	if not (body is CharacterBody3D and body.name == "Player"):
		return

	print("[TraitDeck] Player reached waypoint inside: ", name)

	# Reach up to SessionManager and trigger the assessment phase.
	var session_mgr: Node = get_node_or_null("/root/MainScene/SessionManager")
	if session_mgr and session_mgr.has_method("_on_player_reached_waypoint"):
		session_mgr._on_player_reached_waypoint()
	else:
		push_warning("[TraitDeck] Could not find SessionManager or _on_player_reached_waypoint method.")
