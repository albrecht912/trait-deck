extends Node

## ==========================================
## SessionManager.gd
## Core game loop orchestrator — no player/navigation code.
##
## Two-phase loop per question:
##   EXPLORE PHASE  → AnswerUI hidden, player walks freely to ActiveWaypoint
##   ASSESS PHASE   → Player frozen, AnswerUI slides in, player answers a card
##
## Flow: _load_scenario() → [player walks] → _on_player_reached_waypoint()
##       → [player answers] → _on_card_answer_submitted() → _advance_to_next_scenario()
##       → _load_scenario() (next item)
## ==========================================

## ==========================================
## STATE VARIABLES
## ==========================================

var active_session_id: int = -1
var current_item_id: int   = 1
const TOTAL_ITEMS: int     = 12

## Active player name — resolved from the database on _ready().
var current_student_name: String = ""

## Cached question text for the current item — populated in _load_scenario()
## and consumed in _on_player_reached_waypoint().
var _current_question_text: String = ""
var _current_card_rows: Array      = []

## ==========================================
## PROGRESSION TIMELINE MAP
## ==========================================

var session_timeline: Dictionary = {
	1:  "res://scenes/mo_office.tscn",
	2:  "res://scenes/mo_office.tscn",
	3:  "res://scenes/mahallah_room.tscn",
	4:  "res://scenes/icc_outside.tscn",
	5:  "res://scenes/cafe.tscn",
	6:  "res://scenes/icc_inside.tscn",
	7:  "res://scenes/sports_centre.tscn",
	8:  "res://scenes/musolla.tscn",
	9:  "res://scenes/musolla.tscn",
	10: "res://scenes/musolla.tscn",
	11: "res://scenes/mahallah_room.tscn",
	12: "res://scenes/icc_inside.tscn",
}

## ==========================================
## NODE REFERENCES
## ==========================================

@onready var current_room_slot: Node3D        = $"../CurrentRoom"
@onready var camera_3d: Camera3D              = $"../Camera3D"
@onready var player: Player                   = $"../Player"
@onready var answer_ui: CanvasLayer           = $"../AnswerUI"
@onready var question_card: QuestionCard      = $"../AnswerUI/QuestionCard"
@onready var hand: Hand                       = $"../AnswerUI/Hand"
@onready var results_ui: Control              = $"../ResultsUI"
@onready var mouse_click_detector: Node       = $"../MouseClickDetector"
@onready var world_environment: WorldEnvironment   = $"../WorldEnvironment"
@onready var directional_light: DirectionalLight3D = $"../DirectionalLight3D"

## ==========================================
## LIFECYCLE
## ==========================================

func _ready() -> void:
	results_ui.visible = false
	results_ui.restart_requested.connect(_on_restart_requested)

	_clear_player_responses()

	# --- Resolve the active player name from the database ---
	# TitleScreen inserts a SESSION row before changing scenes.
	# We query the most recent row here to retrieve that name.
	var name_sql: String = "SELECT student_name FROM SESSION ORDER BY session_id DESC LIMIT 1;"
	DatabaseManager.db.query(name_sql)

	if DatabaseManager.db.query_result.size() > 0:
		var latest_row: Dictionary = DatabaseManager.db.query_result[0]
		current_student_name = str(latest_row.get("student_name", ""))
		print("[TraitDeck] SessionManager: Successfully synced session data for student: ", current_student_name)
	else:
		push_error("[TraitDeck] SessionManager: No active session row found in the database!")
		current_student_name = "Guest"

	_start_new_playthrough(current_student_name)

	hand.card_answer_submitted.connect(_on_card_answer_submitted)

	current_item_id = 1
	_load_scenario(current_item_id)

## ==========================================
## 1. SESSION INITIALISATION
## ==========================================

func _clear_player_responses() -> void:
	DatabaseManager.db.query("DELETE FROM PLAYER_RESPONSE;")
	print("[TraitDeck] PLAYER_RESPONSE table cleared for new run.")

func _start_new_playthrough(student_name: String) -> void:
	var sql: String = "INSERT INTO SESSION (student_name, current_scene) VALUES ('%s', 1);" % student_name
	DatabaseManager.db.query(sql)
	active_session_id = DatabaseManager.db.get_last_insert_rowid()
	print("[TraitDeck] Session started. active_session_id = %d" % active_session_id)

## ==========================================
## 2. SCENARIO LOADING — EXPLORE PHASE
## Loads the room, teleports the player, hides the UI, and enables movement.
## The assessment phase begins only when the player reaches the ActiveWaypoint.
## This function is async to allow physics-frame deferral after teleport.
## ==========================================

func _load_scenario(item_id: int) -> void:
	# --- Guard: assessment complete ---
	if not session_timeline.has(item_id):
		push_warning("[TraitDeck] No room mapped for item_id=%d. Triggering completion." % item_id)
		_on_assessment_completed()
		return

	# --- Step A: Resolve scene path ---
	var target_scene_path: String = session_timeline[item_id]

	# --- Step B: Hard-purge old room — always, even for identical scene paths.
	# remove_child + queue_free forces the PhysicsServer to flush the previous
	# room's overlap cache tables, preventing stale collision hits on reload.
	for old_child in current_room_slot.get_children():
		current_room_slot.remove_child(old_child)
		old_child.queue_free()

	# --- Step C: Lock player input and freeze movement immediately ---
	# Prevents the player from clicking during the transition frame.
	if mouse_click_detector:
		mouse_click_detector.input_enabled = false
	if player:
		player.velocity = Vector3.ZERO

	# --- Step D: Load and instance new room ---
	var packed: PackedScene = load(target_scene_path) as PackedScene
	if packed == null:
		push_error("[TraitDeck] Failed to load scene: %s" % target_scene_path)
		return

	var new_room: Node = packed.instantiate()

	if not (new_room is BaseRoom):
		push_error("[TraitDeck] Scene root is not a BaseRoom: %s" % target_scene_path)
		new_room.queue_free()
		return

	current_room_slot.add_child(new_room)
	print("[TraitDeck] Loaded room: %s" % target_scene_path)

	# --- Step E: Disable the ActiveWaypoint Area3D BEFORE teleporting ---
	# This prevents the physics server from firing body_entered while the player
	# is being repositioned on top of or near the waypoint volume.
	var waypoint_area: Area3D = null
	var waypoint_node: Node = new_room.find_child("ActiveWaypoint", true, false)
	if waypoint_node:
		waypoint_area = waypoint_node.get_node_or_null("Area3D") as Area3D
	if waypoint_area:
		waypoint_area.monitoring = false
		print("[TraitDeck] ActiveWaypoint monitoring disabled for safe teleport.")

	# --- Step F: Teleport player to SpawnPoint and flush nav agent cache ---
	var spawn_node: Node3D = new_room.find_child("SpawnPoint", true, false) as Node3D
	if spawn_node:
		if player and player.has_method("teleport_to_position"):
			player.teleport_to_position(spawn_node.global_position)
			print("[TraitDeck] Player snapped to SpawnPoint: %s" % spawn_node.global_position)
	else:
		push_warning("[TraitDeck] Room '%s' is missing a 'SpawnPoint' node!" % new_room.name)

	# --- Step G: Sync camera ---
	camera_3d.setup_camera_for_room(
		new_room.camera_mode,
		new_room.custom_camera_position,
		new_room.custom_camera_rotation
	)

	# --- Step H: Await two physics frames so the PhysicsServer fully updates
	# the world matrix and clears any lingering collision overlap flags from
	# the previous room or the teleport repositioning.
	await get_tree().process_frame
	await get_tree().process_frame

	# --- Step I: Re-enable the waypoint Area3D now that the player is anchored ---
	if waypoint_area:
		waypoint_area.monitoring = true
		print("[TraitDeck] ActiveWaypoint monitoring re-enabled.")

	# --- Step J: Pre-fetch and cache question data for this item ---
	# Fetched after the physics settle so DB work doesn't block the frame deferral.
	var item_sql: String = "SELECT item_id, context_text FROM ITEM WHERE item_id = %d;" % item_id
	DatabaseManager.db.query(item_sql)

	if DatabaseManager.db.query_result.is_empty():
		push_warning("[TraitDeck] No ITEM found for item_id=%d." % item_id)
		_on_assessment_completed()
		return

	_current_question_text = DatabaseManager.db.query_result[0]["context_text"]

	var cards_sql: String = (
		"SELECT card_id, item_id, likert_value, dialogue_text "
		+ "FROM CARD_OPTION "
		+ "WHERE item_id = %d " % item_id
		+ "ORDER BY likert_value ASC;"
	)
	DatabaseManager.db.query(cards_sql)
	_current_card_rows = DatabaseManager.db.query_result
	print("[TraitDeck] Cached %d card options for item_id=%d." % [_current_card_rows.size(), item_id])

	# --- Step K: EXPLORE PHASE — hide UI, unlock player movement ---
	answer_ui.visible = false
	if mouse_click_detector:
		mouse_click_detector.input_enabled = true

	# --- Step L: Update global lighting ---
	_process_environmental_updates()

## ==========================================
## 3. ASSESS PHASE — triggered by ActiveWaypoint Area3D
## Called by BaseRoom._on_area_3d_body_entered() when the player reaches the waypoint.
## ==========================================

func _on_player_reached_waypoint() -> void:
	print("[TraitDeck] Waypoint reached — entering assessment phase for item_id=%d." % current_item_id)

	# --- Lock player movement ---
	if mouse_click_detector:
		mouse_click_detector.input_enabled = false

	# Stop any residual navigation momentum.
	if player:
		player.velocity = Vector3.ZERO

	# --- Show the AnswerUI ---
	answer_ui.visible = true

	# --- Slide the QuestionCard in with cached question data ---
	if question_card:
		question_card.slide_in_from_right(_current_question_text, current_item_id)

	# --- Populate the card hand with cached answer options ---
	hand.populate_hand_with_choices(_current_card_rows)

## ==========================================
## 4. ANSWER SUBMISSION HANDLER
## ==========================================

func _on_card_answer_submitted(card: CardUI) -> void:
	print("[TraitDeck] Card submitted → card_db_id=%d | item_id=%d | likert_value=%d"
		% [card.card_db_id, current_item_id, card.likert_value])

	_save_response(card.card_db_id)
	_advance_to_next_scenario()

## Async advance: slide the QuestionCard out, then load the next scenario.
func _advance_to_next_scenario() -> void:
	if question_card:
		question_card.slide_out_to_left()
		await question_card.slide_out_finished

	current_item_id += 1
	_load_scenario(current_item_id)

## ==========================================
## 5. DATABASE WRITE
## ==========================================

func _save_response(played_card_id: int) -> void:
	if active_session_id == -1:
		push_error("[TraitDeck] Cannot save response: no active session.")
		return

	var sql: String = (
		"INSERT INTO PLAYER_RESPONSE (session_id, card_id) VALUES (%d, %d);"
		% [active_session_id, played_card_id]
	)
	DatabaseManager.db.query(sql)
	print("[TraitDeck] Saved response → session_id=%d, card_id=%d" % [active_session_id, played_card_id])

	_process_environmental_updates()

## ==========================================
## 6. ASSESSMENT COMPLETION
## ==========================================

func _on_assessment_completed() -> void:
	print("[TraitDeck] *** Assessment complete! All %d items answered. ***" % TOTAL_ITEMS)

	var extraversion: float      = _get_domain_average("Extraversion")
	var neuroticism: float       = _get_domain_average("Negative Emotionality")
	var agreeableness: float     = _get_domain_average("Agreeableness")
	var conscientiousness: float = _get_domain_average("Conscientiousness")
	var openness: float          = _get_domain_average("Open-Mindedness")

	print("[TraitDeck] Final scores → E:%.2f N:%.2f A:%.2f C:%.2f O:%.2f"
		% [extraversion, neuroticism, agreeableness, conscientiousness, openness])

	results_ui.display_scores(extraversion, neuroticism, agreeableness, conscientiousness, openness)

	answer_ui.visible  = false
	results_ui.visible = true

## ==========================================
## 7. RESTART HANDLER
## ==========================================

func _on_restart_requested() -> void:
	print("[TraitDeck] Restart requested. Resetting session...")

	results_ui.visible = false
	answer_ui.visible  = false

	_clear_player_responses()
	_start_new_playthrough(current_student_name)

	current_item_id = 1
	_load_scenario(current_item_id)

## ==========================================
## 8. REAL-TIME BFI-2 CALCULATIONS
## ==========================================

func _get_domain_average(domain_name: String) -> float:
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

	return 3.0

## ==========================================
## 9. GLOBAL LIGHTING — Extraversion-driven
## ==========================================

func _process_environmental_updates() -> void:
	var extraversion_avg: float = _get_domain_average("Extraversion")
	var blend: float = clampf((extraversion_avg - 1.0) / 4.0, 0.0, 1.0)

	print("[TraitDeck] Lighting update → Extraversion: %.2f | Blend: %.2f" % [extraversion_avg, blend])

	if directional_light:
		var introverted_color := Color(0.6, 0.75, 1.0)
		var extroverted_color := Color(1.0, 0.85, 0.6)

		directional_light.light_color  = introverted_color.lerp(extroverted_color, blend)
		directional_light.light_energy = lerp(0.5, 1.5, blend)

		print("[TraitDeck] DirectionalLight3D → color=%s | energy=%.2f"
			% [directional_light.light_color, directional_light.light_energy])
