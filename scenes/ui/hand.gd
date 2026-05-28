class_name Hand
extends Control

signal card_answer_submitted(card: CardUI)

# ==========================================
## EXPORT PARAMETERS (set in Inspector)
# ==========================================

@export var hand_curve: Curve
@export var rotation_curve: Curve
@export var max_rotation_degrees: float = 5.0
@export var x_separation: float = 10.0
@export var y_min: float = 0.0
@export var y_max: float = -15.0

# Fixed card footprint — must match CardUI custom_minimum_size
const CARD_WIDTH: float = 150.0

# Preload the card scene for dynamic instantiation
const CARD_SCENE = preload("res://scenes/card_ui/card_ui.tscn")

# ==========================================
## LIFECYCLE
# ==========================================

func _ready() -> void:
	update_fan_layout()

# ==========================================
## HAND POPULATION (called by SessionManager)
# ==========================================

func populate_hand_with_choices(cards_data_array: Array) -> void:
	# 1. Flush any leftover card nodes from the previous question
	for child in get_children():
		child.queue_free()

	# 2. Guard: nothing to render
	var total_cards: int = cards_data_array.size()
	if total_cards == 0:
		print("[TraitDeck] Warning: Attempted to populate hand with an empty dataset.")
		return

	# 3. Instantiate and configure each card
	for index in range(total_cards):
		var data_packet: Dictionary = cards_data_array[index]

		var new_card: CardUI = CARD_SCENE.instantiate() as CardUI

		# Bind database fields to the card instance
		new_card.card_db_id   = data_packet["card_id"]
		new_card.likert_value = data_packet["likert_value"]
		new_card.set_dialogue_text(data_packet["dialogue_text"])

		# Connect reparent signal (cancel → return to hand)
		new_card.reparent_requested.connect(_on_card_ui_reparent_requested)

		# Connect answer submission signal (confirm → bubble up to SessionManager)
		new_card.answer_submitted.connect(_on_card_answer_submitted)

		# Add to scene tree
		add_child(new_card)

		# Store original hand slot so cancel can restore the correct position
		new_card.hand_index = index

	# 4. Run the layout algorithm on the freshly populated hand
	update_fan_layout()

# ==========================================
## SIGNAL HANDLERS
# ==========================================

func _on_card_ui_reparent_requested(child: CardUI) -> void:
	# Return the card to the Hand node
	child.reparent(self)

	# Restore the card to its original sibling index so the fan order is preserved
	if child.hand_index >= 0:
		move_child(child, child.hand_index)

	# Reset transform state so update_fan_layout can position it cleanly
	child.pivot_offset = Vector2(CARD_WIDTH / 2.0, child.size.y / 2.0)
	child.rotation     = 0.0

	update_fan_layout()

func _on_card_answer_submitted(card: CardUI) -> void:
	# Bubble the signal up to SessionManager for DB commit and progression
	card_answer_submitted.emit(card)

# ==========================================
## CARD FANNING LAYOUT (GodotGameLab formula)
# ==========================================

func update_fan_layout() -> void:
	# --- Filter: only operate on live cards; ignore nodes pending queue_free() ---
	# This prevents deferred-deletion ghosts from corrupting the width math when
	# populate_hand_with_choices() clears the old hand and spawns new cards in the
	# same frame.
	var active_cards: Array = []
	for child in get_children():
		if child is CardUI and not child.is_queued_for_deletion():
			active_cards.append(child)

	var num_cards: int = active_cards.size()

	if num_cards == 0:
		return

	# Use a local constant so engine text-scaling cannot alter the width math.
	var card_width: float = 150.0

	# --- Single-card edge case: centre it, no curve needed ---
	if num_cards == 1:
		var card: CardUI = active_cards[0] as CardUI
		if card:
			card.position         = Vector2((custom_minimum_size.x - card_width) / 2.0, y_min)
			card.rotation_degrees = 0.0
		return

	# --- Step 1: Calculate the natural (uncompressed) total span ---
	var total_width: float = (card_width * float(num_cards)) + (x_separation * float(num_cards - 1))

	# --- Step 2: Overflow compression ---
	# If the cards spill past the container width, squeeze the spacing so they fit exactly.
	var final_x_sep: float = x_separation
	if total_width > custom_minimum_size.x:
		final_x_sep = (custom_minimum_size.x - (card_width * float(num_cards))) / float(num_cards - 1)
		total_width  = custom_minimum_size.x   # locked to container edge

	# --- Step 3: Centering offset ---
	# When the hand is narrower than the container, shift it right so it stays centred.
	var x_offset: float = (custom_minimum_size.x - total_width) / 2.0

	# --- Step 4: Per-card curve sampling loop (active cards only) ---
	for i in range(num_cards):
		var card: CardUI = active_cards[i] as CardUI
		if not card:
			continue

		# Normalised 0.0 → 1.0 weight for curve sampling
		var ratio: float = float(i) / float(num_cards - 1)

		# Sample the two exported curves
		var y_curve_value: float = hand_curve.sample(ratio)
		var r_curve_value: float = rotation_curve.sample(ratio)

		# Final position
		var final_x: float = x_offset + (float(i) * (card_width + final_x_sep))
		var final_y: float = y_min + (y_curve_value * y_max)

		card.position         = Vector2(final_x, final_y)
		card.rotation_degrees = r_curve_value * max_rotation_degrees
