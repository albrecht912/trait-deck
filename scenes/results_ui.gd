extends Control

signal restart_requested

@onready var e_value: Label = $CenterContainer/MainLayout/ScoresGrid/E_Value
@onready var n_value: Label = $CenterContainer/MainLayout/ScoresGrid/N_Value
@onready var a_value: Label = $CenterContainer/MainLayout/ScoresGrid/A_Value
@onready var c_value: Label = $CenterContainer/MainLayout/ScoresGrid/C_Value
@onready var o_value: Label = $CenterContainer/MainLayout/ScoresGrid/O_Value

@onready var archetype_label: Label = $CenterContainer/MainLayout/Archetype
@onready var summary_label: Label = $CenterContainer/MainLayout/Summary

@onready var restart_button: Button = $CenterContainer/MainLayout/RestartButton
# 1. Grab a clean reference to the ReturnButton node path
@onready var return_button: Button = $CenterContainer/MainLayout/ReturnButton
@onready var click: AudioStreamPlayer = $Sounds/click

func _ready() -> void:
	# Wire up the restart signal handler safely
	if not restart_button.pressed.is_connected(_on_restart_pressed):
		restart_button.pressed.connect(_on_restart_pressed)
		
	# 2. Wire up the Return to Title scene transition safely
	if not return_button.pressed.is_connected(_on_return_button_pressed):
		return_button.pressed.connect(_on_return_button_pressed)

func display_scores(e: float, n: float, a: float, c: float, o: float) -> void:
	e_value.text = "%.2f / 5.0" % e
	n_value.text = "%.2f / 5.0" % n
	a_value.text = "%.2f / 5.0" % a
	c_value.text = "%.2f / 5.0" % c
	o_value.text = "%.2f / 5.0" % o

func display_profile(archetype: String, summary: String) -> void:
	archetype_label.text = archetype
	summary_label.text = summary

func _on_restart_pressed() -> void:
	click.play()
	restart_requested.emit()

# 3. Add the callback method to execution switch back to your title layout file
func _on_return_button_pressed() -> void:
	click.play()
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _on_quit_button_pressed() -> void:
	click.play()
	get_tree().quit()
