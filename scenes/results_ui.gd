extends Control

signal restart_requested

@onready var e_value: Label = $CenterContainer/MainLayout/ScoresGrid/E_Value
@onready var n_value: Label = $CenterContainer/MainLayout/ScoresGrid/N_Value
@onready var a_value: Label = $CenterContainer/MainLayout/ScoresGrid/A_Value
@onready var c_value: Label = $CenterContainer/MainLayout/ScoresGrid/C_Value
@onready var o_value: Label = $CenterContainer/MainLayout/ScoresGrid/O_Value
@onready var restart_button: Button = $CenterContainer/MainLayout/RestartButton

func _ready() -> void:
	restart_button.pressed.connect(func(): restart_requested.emit())

func display_scores(e: float, n: float, a: float, c: float, o: float) -> void:
	e_value.text = "%.2f / 5.0" % e
	n_value.text = "%.2f / 5.0" % n
	a_value.text = "%.2f / 5.0" % a
	c_value.text = "%.2f / 5.0" % c
	o_value.text = "%.2f / 5.0" % o
