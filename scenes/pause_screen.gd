class_name PauseScreen
extends CanvasLayer

## ==========================================
## PauseScreen.gd
## Attached to the root Control node of pause_screen.tscn.
##
## IMPORTANT — Inspector setup required:
##   Set this node's Process Mode to "When Paused"
##   (Node > Process Mode > When Paused / PROCESS_MODE_WHEN_PAUSED)
##   so the UI remains interactive while get_tree().paused = true.
## ==========================================

## ==========================================
## NODE REFERENCES
## ==========================================

@onready var resume_button: Button = $ResumeButton
@onready var quit_button: Button   = $QuitButton
@onready var click: AudioStreamPlayer = $Sounds/click

## ==========================================
## LIFECYCLE
## ==========================================

func _ready() -> void:
	# Pause the engine the moment this overlay appears.
	get_tree().paused = true

	# --- Wire button signals with double-connection guards ---
	if not resume_button.pressed.is_connected(_on_resume_button_pressed):
		resume_button.pressed.connect(_on_resume_button_pressed)

	if not quit_button.pressed.is_connected(_on_quit_button_pressed):
		quit_button.pressed.connect(_on_quit_button_pressed)

	# Give the Resume button immediate keyboard/gamepad focus so the player
	# can navigate the menu without needing to click first.
	resume_button.grab_focus()

## ==========================================
## KEYBOARD / GAMEPAD SHORTCUT
## ==========================================

## Listens for the "pause" input action (or Escape) while the overlay is active.
## Because this node's process_mode is WHEN_PAUSED, _unhandled_input still fires
## even though the rest of the scene tree is frozen.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# ui_cancel is bound to Escape by default — treat it as a resume toggle.
		_on_resume_button_pressed()

## ==========================================
## BUTTON HANDLERS
## ==========================================

## Unpauses the engine and removes this overlay from the scene tree.
func _on_resume_button_pressed() -> void:
	click.play()
	get_tree().paused = false
	queue_free()

## Exits the application immediately.
func _on_quit_button_pressed() -> void:
	# Unpause first so the engine shuts down cleanly without hanging.
	click.play()
	get_tree().paused = false
	get_tree().quit()
