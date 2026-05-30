class_name TitleScreen
extends Control

## ==========================================
## TitleScreen.gd
## Attached to the root Control node of TitleScreen.tscn.
## Handles player name entry, database session creation, and scene transition.
## ==========================================

## ==========================================
## CONSTANTS
## ==========================================

const MAIN_SCENE_PATH: String = "res://scenes/main_scene.tscn"

## ==========================================
## NODE REFERENCES
## ==========================================

@onready var start_button: Button   = $StartButton
@onready var quit_button: Button    = $QuitButton
@onready var name_field: LineEdit   = $LineEdit

## ==========================================
## RUNTIME-CREATED NODES
## ==========================================

# Procedurally instantiated warning dialog — no scene dependency needed.
var _warning_dialog: AcceptDialog

## ==========================================
## LIFECYCLE
## ==========================================

func _ready() -> void:
	# --- Wire button signals safely (Prevents double-connection errors) ---
	if not start_button.pressed.is_connected(_on_start_button_pressed):
		start_button.pressed.connect(_on_start_button_pressed)
		
	if not quit_button.pressed.is_connected(_on_quit_button_pressed):
		quit_button.pressed.connect(_on_quit_button_pressed)

	# --- Wire Enter key inside the LineEdit to the same validation flow ---
	if not name_field.text_submitted.is_connected(_on_name_field_text_submitted):
		name_field.text_submitted.connect(_on_name_field_text_submitted)

	# --- Build the warning modal at runtime ---
	_warning_dialog = AcceptDialog.new()
	_warning_dialog.title       = "Name Required"
	_warning_dialog.dialog_text = "Please enter your name before starting the evaluation phase!"
	add_child(_warning_dialog)

	# Focus the name field so the player can type immediately.
	name_field.grab_focus()

## ==========================================
## BUTTON HANDLERS
## ==========================================

func _on_start_button_pressed() -> void:
	# Strip leading/trailing whitespace before validation.
	var player_name: String = name_field.text.strip_edges()

	# --- Case A: Empty name — show warning and abort ---
	if player_name.is_empty():
		_warning_dialog.popup_centered()
		return

	# --- Case B: Valid name — persist to DB, then transition ---
	# SessionManager will query the latest SESSION row on startup to retrieve the name.
	_save_session_to_database(player_name)
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

## ==========================================
## DATABASE WRITE
## ==========================================

## Inserts a new session row with the validated player name.
## SessionManager will later update this row with the active session data.
func _save_session_to_database(player_name: String) -> void:
	# Escape single quotes in the name to prevent SQL injection.
	var safe_name: String = player_name.replace("'", "''")

	var sql: String = "INSERT INTO SESSION (student_name) VALUES ('%s');" % safe_name
	DatabaseManager.db.query(sql)

	print("[TraitDeck] TitleScreen: Session created for player '%s'." % player_name)


## Called when the player presses Enter inside the LineEdit.
## Delegates directly to the same validation flow as the Start button.
func _on_name_field_text_submitted(_new_text: String) -> void:
	_on_start_button_pressed()
