class_name Hand
extends Control

# Export curves to edit them visually in the Inspector
@export var width_curve: Curve
@export var height_curve: Curve
@export var rotation_curve: Curve

# Sizing boundaries for 2d fanning
@export var max_hand_width: float = 500.0
@export var max_hand_height: float = 60.0
@export var max_hand_rotation: float = 12.0

#preload cards so we can easily instantiate copies
const CARD_SCENE = preload("res://scenes/card_ui/card_ui.tscn")

#run through an assign variable to current children
func _ready() -> void:
	# initial layout update
	update_fan_layout()

#populate hand
func populate_hand_with_choices(cards_data_array: Array) -> void:
	# 1. Flush any leftover active card nodes out of the rendering tree
	for child in get_children():
		child.queue_free()
		
	# 2. Re-verify that we have a standard 5-card item package array to render
	var total_cards = cards_data_array.size()
	if total_cards == 0:
		print("[TraitDeck] Warning: Attempted to populate hand with an empty dataset.")
		return
		
	# 3. Dynamic layout allocation loop
	for index in range(total_cards):
		var data_packet = cards_data_array[index]
		
		# Instantiate a fresh instance copy of your CardUI panel component
		var new_card = CARD_SCENE.instantiate() as CardUI
		
		# Assign your critical data metrics straight to the card instance variables
		new_card.card_db_id = data_packet["card_id"]
		new_card.likert_value = data_packet["likert_value"]
		
		# Safely inject the text string column directly from your SQLite results array
		new_card.set_dialogue_text(data_packet["dialogue_text"])

		# Add to tree and connect existing reparent signals
		add_child(new_card)
		
		# Check your CardUI script for your exact text assignment method:
		if new_card.has_method("set_dialogue_text"):
			new_card.set_dialogue_text(data_packet["dialogue_text"])
		else:
			# Direct fallback injection if you manage a label node inside CardUI
			new_card.get_node("Label").text = data_packet["dialogue_text"]
			
		# Connect your existing reparenting signal tracking hooks
		new_card.reparent_requested.connect(_on_card_ui_reparent_requested)
		
		# Append the newly constructed card to your active scene node layout stack
		add_child(new_card)
		
	# 4. Trigger the fanning layout algorithm across the newly populated tree
	update_fan_layout()

func _on_card_ui_reparent_requested(child: CardUI) -> void:
	child.reparent(self)
	update_fan_layout()
	
# =================
# Card fanning logic
# =================
func update_fan_layout() -> void:
	var cards = get_children()
	var total_cards = cards.size()
	
	if total_cards == 0:
		return

	for index in range(total_cards):
		var card = cards[index] as Control
		if not card:
			continue
			
		# 1. Compute the index weight factor between 0.0 and 1.0
		var card_weight: float = 0.5
		if total_cards > 1:
			card_weight = float(index) / float(total_cards - 1)
			
		# 2. Sample curves to determine structural pixel placements
		var x_offset = width_curve.sample(card_weight) * max_hand_width
		# Negative Y values pull the center cards UP, forming a clean arc
		var y_offset = -height_curve.sample(card_weight) * max_hand_height
		
		#enforce bottom center pivot values
		var card_pivot = Vector2(card.size.x/2.0, card.size.y)
		card.pivot_offset = card_pivot
		
		# 3. Apply spatial metrics to the child Node target positions
		card.position = Vector2(x_offset, y_offset) - card_pivot
		card.rotation_degrees = rotation_curve.sample(card_weight) * max_hand_rotation
