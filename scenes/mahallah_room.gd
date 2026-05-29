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
## ==========================================

## Camera mode string — reserved for future use ("Static", "Follow", etc.)
@export var camera_mode: String = "Static"

## World-space position the Camera3D should snap to when this room loads.
@export var custom_camera_position: Vector3 = Vector3(0.0, 3.0, 6.0)

## Euler rotation in degrees the Camera3D should adopt when this room loads.
@export var custom_camera_rotation: Vector3 = Vector3(-15.0, 0.0, 0.0)
