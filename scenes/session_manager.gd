extends Node

## ==========================================
## SessionManager.gd
## Core game loop orchestrator — no player/navigation code.
## Flow: room load → camera sync → DB query → card UI → answer → next room
## ==========================================

## ==========================================
## STATE VARIABLES
## ==========================================

var active_session_id: int = -1
# Tracks which ITEM (question) the player is currently answering (1-indexed)
var current_item_id: int = 1
# Total number of items in the BFI-2 scale (update if your dataset changes)
const TOTAL_ITEMS: int = 12

## ==========================================
## PROGRESSION TIMELINE MAP
## Maps each item_id to the room scene that should be loaded for that question.
## Add or reorder entries here as your level list grows.
## ==========================================

var session_timeline: Dictionary = {
	1:  "res://scenes/mo_office.tscn",   # Item 1 : mo
	2:  "res://scenes/mo_office.tscn",       # Item 2 : MO Office
	3:  "res://scenes/mahallah_room.tscn",      # Item 3 : ICC Inside
	4:  "res://scenes/icc_outside.tscn",   # Item 4 : Sports Centre
	5:  "res://scenes/cafe.tscn",            # Item 5 : Cafe
	6:  "res://scenes/icc_inside.tscn",         # Item 6 : Musolla
	7:  "res://scenes/sports_centre.tscn",     # Item 7 : ICC Outside
	8:  "res://scenes/musolla.tscn",   # Item 8 : (repeat / placeholder)
	9:  "res://scenes/musolla.tscn",       # Item 9 : (repeat / placeholder)
	10: "res://scenes/musolla.tscn",      # Item 10: (repeat / placeholder)
	11: "res://scenes/mahallah_room.tscn",   # Item 11: (repeat / placeholder)
	12: "res://scenes/icc_inside.tscn",            # Item 12: (repeat / placeholder)
}

## ==========================================
## NODE REFERENCES
## ==========================================

@onready var current_room_slot: Node3D   = $"../CurrentRoom"
@onready var camera_3d: Camera3D         = $"../Camera3D"
@onready var player: Player              = $"../Player"
@onready var answer_ui: CanvasLayer      = $"../AnswerUI"
@onready var question_card: QuestionCard = $"../AnswerUI/QuestionCard"
@onready var hand: Hand                  = $"../AnswerUI/Hand"
@onready var results_ui: Control         = $"../ResultsUI"
@onready var world_environment: WorldEnvironment   = $"../WorldEnvironment"
@onready var directional_light: DirectionalLight3D = $"../DirectionalLight3D"

## ==========================================
## LIFECYCLE
## ==========================================

func _ready() -> void:
	# Hide the results screen until the assessment is finished.
	results_ui.visible = false

	# Wire the ResultsUI restart button signal back into this manager.
	results_ui.restart_requested.connect(_on_restart_requested)

	# Step 1: Wipe any leftover responses from a previous run so every session starts clean.
	# ITEM and CARD_OPTION seed data is preserved; only runtime responses are cleared.
	_clear_player_responses()

	# Step 2: Create a fresh session record for this playthrough.
	# In production, pass the real student name from a login screen instead.
	_start_new_playthrough("Syaqeer")

	# Step 3: Connect the Hand's answer-submission signal before loading the first scenario.
	hand.card_answer_submitted.connect(_on_card_answer_submitted)

	# Step 4: Load the first room and its associated question.
	current_item_id = 1
	_load_scenario(current_item_id)

## ==========================================
## 1. SESSION INITIALISATION
## ==========================================

func _clear_player_responses() -> void:
	# SQL: Delete every row from PLAYER_RESPONSE so this run starts from a blank slate.
	DatabaseManager.db.query("DELETE FROM PLAYER_RESPONSE;")
	print("[TraitDeck] PLAYER_RESPONSE table cleared for new run.")

func _start_new_playthrough(student_name: String) -> void:
	# SQL: Insert a new SESSION row and capture its auto-incremented primary key.
	var sql: String = "INSERT INTO SESSION (student_name, current_scene) VALUES ('%s', 1);" % student_name
	DatabaseManager.db.query(sql)
	active_session_id = DatabaseManager.db.get_last_insert_rowid()
	print("[TraitDeck] Session started. active_session_id = %d" % active_session_id)

## ==========================================
## 2. SCENARIO LOADING (room → camera → UI)
## ==========================================

func _load_scenario(item_id: int) -> void:
	# --- Guard: if item_id is not in the timeline, the assessment is complete ---
	if not session_timeline.has(item_id):
		push_warning("[TraitDeck] No room mapped for item_id=%d. Triggering completion." % item_id)
		_on_assessment_completed()
		return

	# --- Step A: Resolve the scene path for this item ---
	var target_scene_path: String = session_timeline[item_id]

	# --- Step B: Clear the old room from the slot ---
	for old_child in current_room_slot.get_children():
		old_child.queue_free()

	# --- Step C: Load and instance the new room scene ---
	var packed: PackedScene = load(target_scene_path) as PackedScene
	if packed == null:
		push_error("[TraitDeck] Failed to load scene: %s" % target_scene_path)
		return

	var new_room: Node = packed.instantiate()

	# --- Step D: Type-check and add the new room ---
	if not (new_room is BaseRoom):
		push_error("[TraitDeck] Scene root is not a BaseRoom: %s" % target_scene_path)
		new_room.queue_free()
		return

	current_room_slot.add_child(new_room)
	print("[TraitDeck] Loaded room: %s" % target_scene_path)

	# --- Step D.5: Teleport the player to the room's SpawnPoint ---
	# This runs synchronously before any UI animation so the camera sees the
	# player in the correct position the exact frame the question card slides in.
	var spawn_node: Node3D = new_room.find_child("SpawnPoint", true, false) as Node3D
	if spawn_node:
		if player and player.has_method("teleport_to_position"):
			player.teleport_to_position(spawn_node.global_position)
			print("[TraitDeck] Player snapped to SpawnPoint: %s" % spawn_node.global_position)
	else:
		push_warning("[TraitDeck] Room '%s' is missing a 'SpawnPoint' node!" % new_room.name)

	# --- Step E: Sync camera to the room's exported configuration ---
	camera_3d.setup_camera_for_room(
		new_room.camera_mode,
		new_room.custom_camera_position,
		new_room.custom_camera_rotation
	)

	# --- Step F: Fetch the question prompt text from the database ---
	var item_sql: String = "SELECT item_id, context_text FROM ITEM WHERE item_id = %d;" % item_id
	DatabaseManager.db.query(item_sql)

	if DatabaseManager.db.query_result.is_empty():
		push_warning("[TraitDeck] No ITEM found for item_id=%d." % item_id)
		_on_assessment_completed()
		return

	var question_text: String = DatabaseManager.db.query_result[0]["context_text"]

	# Slide the QuestionCard in from the right with fresh content.
	# The card snaps off-screen, updates its labels, then tweens to center.
	if question_card:
		question_card.slide_in_from_right(question_text, item_id)

	print("[TraitDeck] Sliding QuestionCard in for item_id=%d." % item_id)

	# --- Step G: Fetch the 5 answer cards for this item ---
	var cards_sql: String = (
		"SELECT card_id, item_id, likert_value, dialogue_text "
		+ "FROM CARD_OPTION "
		+ "WHERE item_id = %d " % item_id
		+ "ORDER BY likert_value ASC;"
	)
	DatabaseManager.db.query(cards_sql)

	var card_rows: Array = DatabaseManager.db.query_result
	print("[TraitDeck] Retrieved %d card options for item_id=%d." % [card_rows.size(), item_id])

	# Ensure the gameplay UI is visible and populate the card hand.
	answer_ui.visible = true
	hand.populate_hand_with_choices(card_rows)

	# --- Step H: Sync global MainScene lighting to the player's current Extraversion score ---
	_process_environmental_updates()

## ==========================================
## 3. ANSWER SUBMISSION HANDLER
## ==========================================

func _on_card_answer_submitted(card: CardUI) -> void:
	print("[TraitDeck] Card submitted → card_db_id=%d | item_id=%d | likert_value=%d"
		% [card.card_db_id, current_item_id, card.likert_value])

	# Step A: Persist the player's choice to the database.
	_save_response(card.card_db_id)

	# Step B: The submitted card's dissolve animation (0.6s) has already finished
	# and queue_free() has been called by CardUI.animate_dissolve_and_free() before
	# this signal fires. Now slide the QuestionCard out and wait for it to leave
	# the screen before loading the next scenario.
	_advance_to_next_scenario()

## Async advance: slide the QuestionCard out, then load the next scenario.
## Using a separate function keeps _on_card_answer_submitted non-async.
func _advance_to_next_scenario() -> void:
	# Slide the question card off-screen to the right and wait for it to finish.
	if question_card:
		question_card.slide_out_to_left()
		await question_card.slide_out_finished

	# Advance the item counter and load the next room + scenario.
	# _load_scenario() calls slide_in_from_right() and _process_environmental_updates().
	current_item_id += 1
	_load_scenario(current_item_id)

## ==========================================
## 4. DATABASE WRITE
## ==========================================

func _save_response(played_card_id: int) -> void:
	if active_session_id == -1:
		push_error("[TraitDeck] Cannot save response: no active session.")
		return

	# SQL: Insert a bridge row linking this session to the chosen card.
	var sql: String = (
		"INSERT INTO PLAYER_RESPONSE (session_id, card_id) VALUES (%d, %d);"
		% [active_session_id, played_card_id]
	)
	DatabaseManager.db.query(sql)
	print("[TraitDeck] Saved response → session_id=%d, card_id=%d" % [active_session_id, played_card_id])

	# Trigger real-time environmental mood update after each answer.
	_process_environmental_updates()

## ==========================================
## 5. ASSESSMENT COMPLETION
## ==========================================

func _on_assessment_completed() -> void:
	print("[TraitDeck] *** Assessment complete! All %d items answered. ***" % TOTAL_ITEMS)

	# Query the final BFI-2 domain averages for all five Big Five dimensions.
	var extraversion: float      = _get_domain_average("Extraversion")
	var neuroticism: float       = _get_domain_average("Negative Emotionality")
	var agreeableness: float     = _get_domain_average("Agreeableness")
	var conscientiousness: float = _get_domain_average("Conscientiousness")
	var openness: float          = _get_domain_average("Open-Mindedness")

	print("[TraitDeck] Final scores → E:%.2f N:%.2f A:%.2f C:%.2f O:%.2f"
		% [extraversion, neuroticism, agreeableness, conscientiousness, openness])

	# Pass the computed scores into the ResultsUI component for display.
	results_ui.display_scores(extraversion, neuroticism, agreeableness, conscientiousness, openness)

	# Swap visibility: hide the gameplay UI, reveal the results screen.
	answer_ui.visible  = false
	results_ui.visible = true

## ==========================================
## 6. RESTART HANDLER
## ==========================================

func _on_restart_requested() -> void:
	print("[TraitDeck] Restart requested. Resetting session...")

	# Hide results, restore the gameplay UI.
	results_ui.visible = false
	answer_ui.visible  = true

	# Flush all previous responses and start a brand-new session record.
	_clear_player_responses()
	_start_new_playthrough("Syaqeer")

	# Reset progression counter and reload the first room + scenario.
	current_item_id = 1
	_load_scenario(current_item_id)

## ==========================================
## 7. REAL-TIME BFI-2 CALCULATIONS
## ==========================================

func _get_domain_average(domain_name: String) -> float:
	# SQL: Compute the running BFI-2 average for a domain, reversing scored items where needed.
	var sql: String = """
		SELECT AVG(
			CASE
				WHEN i.is_reverse = 1 THEN (6 - c.likert_value)
				ELSE c.likert_value
			END
		) AS domain_average
		FROM PLAYER_RESPONSE pr
		JOIN CARD_OPTION c ON pr.card_id = c.card_id
		JOIN ITEM i ON c.item_id = i.item_id
		JOIN DOMAIN d ON i.domain_id = d.domain_id
		WHERE pr.session_id = %d AND d.name = '%s';
	""" % [active_session_id, domain_name]

	DatabaseManager.db.query(sql)

	if not DatabaseManager.db.query_result.is_empty():
		var result = DatabaseManager.db.query_result[0].get("domain_average")
		if result != null:
			return float(result)

	# Neutral midpoint fallback when no answers have been recorded yet.
	return 3.0

## ==========================================
## 8. GLOBAL LIGHTING — Extraversion-driven (MainScene DirectionalLight3D)
## ==========================================

## Called at the end of every _load_scenario() and after each _save_response().
## Reads the player's running Extraversion score and adjusts the MainScene's
## permanent DirectionalLight3D colour and energy accordingly.
## No room-local light scanning — operates purely on the global rig.
func _process_environmental_updates() -> void:
	var extraversion_avg: float = _get_domain_average("Extraversion")

	# Normalise 1–5 Likert scale to a 0.0–1.0 blend factor.
	var blend: float = clampf((extraversion_avg - 1.0) / 4.0, 0.0, 1.0)

	print("[TraitDeck] Lighting update → Extraversion: %.2f | Blend: %.2f" % [extraversion_avg, blend])

	if directional_light:
		var introverted_color := Color(0.6, 0.75, 1.0)   # Soft cool blue  (low E)
		var extroverted_color := Color(1.0, 0.85, 0.6)   # Warm amber gold (high E)

		directional_light.light_color  = introverted_color.lerp(extroverted_color, blend)
		directional_light.light_energy = lerp(0.5, 1.5, blend)

		print("[TraitDeck] DirectionalLight3D → color=%s | energy=%.2f"
			% [directional_light.light_color, directional_light.light_energy])
