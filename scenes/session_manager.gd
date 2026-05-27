extends Node

## ==========================================
## STATE VARIABLES
## ==========================================

var active_session_id: int = -1
# Tracks which ITEM (question) the player is currently answering (1-indexed)
var current_item_id: int = 1
# Total number of items in the BFI-2 scale (update if your dataset changes)
const TOTAL_ITEMS: int = 12

## ==========================================
## NODE REFERENCES
## ==========================================

@onready var prompt_label: Label = $"../AnswerUI/PromptLabel"
@onready var hand: Hand = $"../AnswerUI/Hand"
@onready var world_environment: WorldEnvironment = $"../WorldEnvironment"
@onready var directional_light: DirectionalLight3D = $"../DirectionalLight3D"

## ==========================================
## LIFECYCLE
## ==========================================

func _ready() -> void:
	# Step 1: Wipe any leftover responses from a previous run so every session starts clean.
	# The ITEM and CARD_OPTION seed data is preserved; only runtime responses are cleared.
	_clear_player_responses()

	# Step 2: Create a fresh session record for this playthrough.
	# In production, pass the real student name from a login screen instead.
	_start_new_playthrough("Syaqeer")

	# Step 3: Connect the Hand's answer-submission signal before loading the first scenario.
	hand.card_answer_submitted.connect(_on_card_answer_submitted)

	# Step 4: Load and display the very first question.
	current_item_id = 1
	_load_scenario(current_item_id)

## ==========================================
## 1. SESSION INITIALISATION
## ==========================================

func _clear_player_responses() -> void:
	# SQL: Delete every row from PLAYER_RESPONSE so this run starts from a blank slate.
	# ITEM and CARD_OPTION seed rows are untouched.
	DatabaseManager.db.query("DELETE FROM PLAYER_RESPONSE;")
	print("[TraitDeck] PLAYER_RESPONSE table cleared for new run.")

func _start_new_playthrough(student_name: String) -> void:
	# SQL: Insert a new SESSION row and capture its auto-incremented primary key.
	var sql: String = "INSERT INTO SESSION (student_name, current_scene) VALUES ('%s', 1);" % student_name
	DatabaseManager.db.query(sql)
	active_session_id = DatabaseManager.db.get_last_insert_rowid()
	print("[TraitDeck] Session started. active_session_id = %d" % active_session_id)

## ==========================================
## 2. SCENARIO LOADING
## ==========================================

func _load_scenario(item_id: int) -> void:
	# --- Guard: check whether this item actually exists ---
	var item_sql: String = "SELECT item_id, context_text FROM ITEM WHERE item_id = %d;" % item_id
	DatabaseManager.db.query(item_sql)

	if DatabaseManager.db.query_result.is_empty():
		# No more items → assessment is finished.
		push_warning("[TraitDeck] No ITEM found for item_id=%d. Triggering completion." % item_id)
		_on_assessment_completed()
		return

	# Display the scenario prompt text on the UI label.
	prompt_label.text = DatabaseManager.db.query_result[0]["context_text"]
	print("[TraitDeck] Loaded item_id=%d onto PromptLabel." % item_id)

	# --- Fetch the 5 answer cards for this item, ordered by Likert value ---
	var cards_sql: String = (
		"SELECT card_id, item_id, likert_value, dialogue_text "
		+ "FROM CARD_OPTION "
		+ "WHERE item_id = %d " % item_id
		+ "ORDER BY likert_value ASC;"
	)
	DatabaseManager.db.query(cards_sql)

	var card_rows: Array = DatabaseManager.db.query_result
	print("[TraitDeck] Retrieved %d card options for item_id=%d." % [card_rows.size(), item_id])

	# Hand off the data array to Hand.gd which will instantiate and fan the cards.
	hand.populate_hand_with_choices(card_rows)

## ==========================================
## 3. ANSWER SUBMISSION HANDLER
## ==========================================

func _on_card_answer_submitted(card: CardUI) -> void:
	print("[TraitDeck] Card submitted → card_db_id=%d | item_id (via likert)=%d | likert_value=%d"
		% [card.card_db_id, current_item_id, card.likert_value])

	# Step A: Persist the player's choice to the database.
	_save_response(card.card_db_id)

	# Step B: Remove the submitted card node from the scene tree.
	card.queue_free()

	# Step C: Advance to the next item, or end the assessment if all items are done.
	current_item_id += 1
	if current_item_id <= TOTAL_ITEMS:
		_load_scenario(current_item_id)
	else:
		_on_assessment_completed()

## ==========================================
## 4. DATABASE WRITE
## ==========================================

func _save_response(played_card_id: int) -> void:
	if active_session_id == -1:
		push_error("[TraitDeck] Cannot save response: no active session.")
		return

	# SQL: Insert a bridge row linking this session to the chosen card.
	# The PLAYER_RESPONSE table schema: (session_id, card_id, timestamp)
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
	# Placeholder: replace with your end-screen transition, results display, etc.
	print("[TraitDeck] *** Assessment complete! All %d items answered. ***" % TOTAL_ITEMS)
	# TODO: Show results screen, play completion animation, etc.

## ==========================================
## 6. REAL-TIME BFI-2 CALCULATIONS
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
## 7. DYNAMIC 3D ENVIRONMENT MOOD SHIFTS
## ==========================================

func _process_environmental_updates() -> void:
	var extraversion_avg: float = _get_domain_average("Extraversion")
	var neuroticism_avg: float  = _get_domain_average("Negative Emotionality")

	print("[TraitDeck] Domain averages → Extraversion: %.2f | Neuroticism: %.2f"
		% [extraversion_avg, neuroticism_avg])

	_update_3d_atmosphere(extraversion_avg, neuroticism_avg)

func _update_3d_atmosphere(e_score: float, n_score: float) -> void:
	# Normalise 1–5 Likert range to 0.0–1.0 blend factors.
	var energy_factor: float = (e_score - 1.0) / 4.0
	var stress_factor: float = (n_score - 1.0) / 4.0

	# --- Directional light colour & energy (driven by Extraversion) ---
	if directional_light:
		var vibrant_gold := Color(1.0, 0.93, 0.82)
		var reserved_dim := Color(0.48, 0.52, 0.60)
		directional_light.light_color  = reserved_dim.lerp(vibrant_gold, energy_factor)
		directional_light.light_energy = lerp(0.6, 1.3, energy_factor)

	# --- Fog density & colour (driven by Negative Emotionality) ---
	if world_environment and world_environment.environment:
		var env: Environment = world_environment.environment
		env.fog_enabled     = true
		env.fog_density     = lerp(0.002, 0.06, stress_factor)
		env.fog_light_color = Color(0.55, 0.55, 0.55).lerp(Color(0.18, 0.20, 0.25), stress_factor)
