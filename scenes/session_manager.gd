extends Node

# Active playthrough data tracking states
var active_session_id: int = -1
var current_item_db_id: int = 1 # Increments as the student moves through Ta'aruf week scenes

# Node references mapped exactly to your current scene tree layout
@onready var prompt_label = $"../AnswerUI/PromptLabel"
@onready var hand = $"../AnswerUI/Hand" # Points to your script-driven Hand node
@onready var world_environment = $"../WorldEnvironment" # Rooted directly under MainScene now
@onready var directional_light = $"../DirectionalLight3D" # Rooted directly under MainScene nowers

func _ready():
	# Verification Test: Automatically initializes a test student run upon compiling/booting
	# In production, call this function from your Main Menu login UI instead
	start_new_playthrough("Syaqeer")
	# Automatically fetch and render the initial BFI-2 scenario question on boot
	load_active_scenario(current_item_db_id)

## ==========================================
## 1. PERSISTENT TRANSACTION DATA PIPELINE
## ==========================================

func start_new_playthrough(student_name: String):
	# Generates a new unique session entry string inside the SQLite database
	var query_string = "INSERT INTO SESSION (student_name, current_scene) VALUES ('%s', 1);" % student_name
	DatabaseManager.db.query(query_string)
	
	# Extract and save the auto-incremented primary key assigned to this active run
	active_session_id = DatabaseManager.db.get_last_insert_rowid()
	print("[TraitDeck] Production session initialized. Active Session ID: ", active_session_id)

func load_active_scenario(item_id: int):
	# 1. Fetch the main background scenario prompt text from the ITEM table
	var item_query = "SELECT context_text FROM ITEM WHERE item_id = %d;" % item_id
	DatabaseManager.db.query(item_query)
	
	if DatabaseManager.db.query_result.size() > 0:
		prompt_label.text = DatabaseManager.db.query_result[0]["context_text"]
		print("[TraitDeck] Loaded Item ID %d text onto UI." % item_id)
	else:
		push_error("[TraitDeck] Error: Requested Item ID %d not found in database rows." % item_id)
		return
		
	# 2. Fetch all 5 dialogue choices mapped to this specific item from the CARD_OPTION table
	var cards_query = "SELECT card_id, likert_value, dialogue_text FROM CARD_OPTION WHERE item_id = %d ORDER BY likert_value ASC;" % item_id
	DatabaseManager.db.query(cards_query)
	
	var dataset_results = DatabaseManager.db.query_result
	print("[TraitDeck] Retrieved %d active dialogue rows from database." % dataset_results.size())
	
	# 3. Hand the data records down to Hand.gd to spawn and fan the 5 cards programmatically
	hand.populate_hand_with_choices(dataset_results)

func commit_card_selection_to_db(played_card_id: int):
	# Validates that an active session context exists before attempting database entry
	if active_session_id == -1:
		push_error("[TraitDeck] Error: Attempted to log a choice without an active student session.")
		return
		
	# Commits the bridge record linking this session instance to the specific card ID selected
	var query_string = "INSERT INTO PLAYER_RESPONSE (session_id, card_id) VALUES (%d, %d);" % [active_session_id, played_card_id]
	DatabaseManager.db.query(query_string)
	print("[TraitDeck] Card transaction ID %d successfully saved to database." % played_card_id)
	
	# Recalculate traits in real-time to update the surrounding 3D environment's aesthetic mood
	process_running_environmental_updates()

## ==========================================
## 2. REAL-TIME REAL-TIME CALCULATIONS (BFI-2)
## ==========================================

func get_realtime_domain_average(domain_name: String) -> float:
	# Automated processing query executing standard BFI-2 calculations
	# Safely handles false-keyed items by flipping raw 1-5 ratings into true psychometric values (6 - score)
	var sql = """
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
	
	# Parse the floating-point result array securely out of the plugin wrapper dictionary layout
	if DatabaseManager.db.query_result.size() > 0:
		var result = DatabaseManager.db.query_result[0].get("domain_average")
		if result != null:
			return float(result)
			
	return 3.0 # Fallback neutral midpoint baseline if no scale questions have been answered yet

## ==========================================
## 3. DYNAMIC 3D ENVIRONMENTAL MOOD SHIFTS
## ==========================================

func process_running_environmental_updates():
	# Fetch running floating-point average scores for targeted dimensions
	var extraversion_avg = get_realtime_domain_average("Extraversion")
	var neuroticism_avg = get_realtime_domain_average("Negative Emotionality")
	
	print("[TraitDeck] Psychometric Averages Updated -> Extraversion: %.2f | Neuroticism: %.2f" % [extraversion_avg, neuroticism_avg])
	
	# Execute visual transitions across your 3D world parameters based on active traits
	update_3d_lighting_and_atmosphere(extraversion_avg, neuroticism_avg)

func update_3d_lighting_and_atmosphere(e_score: float, n_score: float):
	# Normalize domain variables (ranges 1.0 to 5.0) down to simple 0.0 to 1.0 weight factors
	var energy_factor = (e_score - 1.0) / 4.0
	var stress_factor = (n_score - 1.0) / 4.0
	
	# 1. Modulate World Ambient Directional Lighting (Driven by Extraversion)
	if directional_light and directional_light is DirectionalLight3D:
		var vibrant_gold = Color(1.0, 0.93, 0.82)
		var reserved_dim = Color(0.48, 0.52, 0.60)
		# Blend light spectrum and downscale raw energy as Extraversion drops
		directional_light.light_color = reserved_dim.lerp(vibrant_gold, energy_factor)
		directional_light.light_energy = lerp(0.6, 1.3, energy_factor)
		
	# 2. Modulate Environmental Fog Concentration (Driven by Negative Emotionality / Anxiety)
	if world_environment and world_environment.environment:
		var env = world_environment.environment
		env.fog_enabled = true
		
		# Pull volumetric fog density significantly tighter around the view camera during spikes in student stress
		env.fog_density = lerp(0.002, 0.06, stress_factor)
		env.fog_light_color = Color(0.55, 0.55, 0.55).lerp(Color(0.18, 0.20, 0.25), stress_factor)
