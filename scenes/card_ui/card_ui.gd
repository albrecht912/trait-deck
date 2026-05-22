class_name CardUI
extends Control

signal reparent_requested(which_card_ui: CardUI)
signal answer_submitted(which_card_ui: CardUI)

# ==========================================
## BFI-2 DATABASE TRACKING PROPERTIES
# ==========================================
var card_db_id: int = -1
var likert_value: int = -1

# Tracks the original sibling index in the Hand so we can restore position on cancel
var hand_index: int = -1

# Your existing state components
@onready var color: ColorRect = $Color
@onready var state: Label = $State
@onready var drop_point_detector: Area2D = $DropPointDetector
@onready var card_state_machine: CardStateMachine = $CardStateMachine as CardStateMachine
@onready var targets: Array[Node] = []
@onready var answer_label: Label = $AnswerLabel

# Optional: Grab a reference to a label inside your card template to display the dialogue text
# If your text label is named something else (e.g. "DialogueText"), update this path!
@onready var text_label: Label = $Label

func _ready() -> void:
	card_state_machine.init(self)
	
func _input(event: InputEvent) -> void:
	card_state_machine.on_input(event)

func _on_gui_input(event: InputEvent) -> void:
	card_state_machine.on_gui_input(event)

func _on_mouse_entered() -> void:
	card_state_machine.on_mouse_entered()

func _on_mouse_exited() -> void:
	card_state_machine.on_mouse_exited()

func _on_drop_point_detector_area_entered(area: Area2D) -> void:
	if not targets.has(area):
		targets.append(area)

func _on_drop_point_detector_area_exited(area: Area2D) -> void:
	targets.erase(area)

# ==========================================
## DATABASE HELPER FUNCTIONS
# ==========================================
func set_dialogue_text(new_text: String) -> void:
	# Safely updates the text component without breaking if the reference is unassigned
	if answer_label:
		answer_label.text = new_text
	else:
		#fallback
		get_node("AnswerLabel").text = new_text
