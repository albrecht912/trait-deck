class_name Hand
extends Control

signal card_answer_submitted(card: CardUI)

## ==========================================
## EXPORT PARAMETERS (set in Inspector)
## ==========================================

@export var hand_curve: Curve
@export var rotation_curve: Curve
@export var max_rotation_degrees: float = 5.0
@export var x_separation: float = 10.0
@export var y_min: float = 0.0
@export var y_max: float = -15.0
@onready var swipe: AudioStreamPlayer = $"../../Sounds/swipe"
@onready var swoosh: AudioStreamPlayer = $"../../Sounds/swoosh"

## ==========================================
## CONSTANTS
## ==========================================

const CARD_SCENE: PackedScene = preload("res://scenes/card_ui/card_ui.tscn")

# The screen-space origin of the CardDrawpile asset (bottom-left corner).
const PILE_POSITION: Vector2 = Vector2(49.0, 778.0)

# Fixed card footprint — must match CardUI custom_minimum_size.
const CARD_WIDTH: float  = 150.0
const CARD_HEIGHT: float = 210.0

# Stagger delay between each card leaving the pile.
const DEAL_STAGGER: float = 0.075

# Base delay before the first card starts moving.
const DEAL_BASE_DELAY: float = 0.3

# Duration of each card's flight tween.
const DEAL_DURATION: float = 0.45

## ==========================================
## NODE REFERENCES
## ==========================================

@onready var drop_zone: Area2D = get_parent().get_node_or_null("DropZone") as Area2D

## ==========================================
## LIFECYCLE
## ==========================================

func _ready() -> void:
	update_fan_layout()

## ==========================================
## HAND POPULATION — staggered deal animation
## ==========================================

func populate_hand_with_choices(cards_data_array: Array) -> void:
	# 1. Flush leftover cards from the previous question.
	for child in get_children():
		child.queue_free()

	var total_cards: int = cards_data_array.size()
	if total_cards == 0:
		print("[TraitDeck] Warning: populate_hand_with_choices called with empty array.")
		return

	# 2. Pre-calculate the fan layout targets for every slot so we can feed
	#    them into the deal tweens without running the layout loop twice.
	var fan_targets: Array = _compute_fan_targets(total_cards)

	# 3. Instantiate, configure, and deal each card with a staggered tween.
	for i in range(total_cards):
		var data_packet: Dictionary = cards_data_array[i]

		var card: CardUI = CARD_SCENE.instantiate() as CardUI

		# Bind database fields.
		card.card_db_id   = data_packet["card_id"]
		card.likert_value = data_packet["likert_value"]
		card.set_dialogue_text(data_packet["dialogue_text"])
		card.drop_zone  = drop_zone
		card.hand_index = i

		# Connect signals before adding to tree.
		card.reparent_requested.connect(_on_card_reparent_requested)
		card.answer_submitted.connect(_on_card_answer_submitted)

		# Add to Hand so it is part of the scene tree.
		add_child(card)
		swoosh.play()

		# --- Initial state: card sits at the pile, invisible (scale zero) ---
		# top_level = true frees it from the Hand container's layout so we can
		# drive global_position directly during the flight animation.
		card.top_level        = true
		card.global_position  = PILE_POSITION
		card.rotation         = 0.0
		card.scale            = Vector2.ZERO
		# Block input until the deal animation finishes.
		card.mouse_filter     = Control.MOUSE_FILTER_IGNORE

		# Retrieve the pre-calculated fan slot for this index.
		var target: Dictionary = fan_targets[i]
		var final_pos: Vector2 = target["position"]      # local position inside Hand
		var rot_rad: float     = target["rotation_rad"]  # target rotation in radians

		# Convert the local fan position to global so we can tween global_position.
		var final_global_pos: Vector2 = global_position + final_pos

		# --- Build the parallel deal tween ---
		var deal_tween: Tween = card.create_tween()
		deal_tween.set_parallel(true)
		deal_tween.set_ease(Tween.EASE_IN_OUT)
		deal_tween.set_trans(Tween.TRANS_CUBIC)

		var delay: float = DEAL_BASE_DELAY + (float(i) * DEAL_STAGGER)

		# Fly from pile to fan slot.
		deal_tween.tween_property(card, "global_position", final_global_pos, DEAL_DURATION)\
			.set_delay(delay)
			
		# Rotate from flat to fan angle.
		deal_tween.tween_property(card, "rotation", rot_rad, DEAL_DURATION)\
			.set_delay(delay)

		# Scale up from zero to full size.
		deal_tween.tween_property(card, "scale", Vector2.ONE, DEAL_DURATION)\
			.set_delay(delay)

		# --- Post-animation cleanup (fires after the last property finishes) ---
		# Switch to sequential so the callback runs after all parallel tweens complete.
		deal_tween.set_parallel(false)
		deal_tween.tween_callback(func() -> void:
			# Re-attach to the Hand container layout.
			card.top_level = false
			# Snap local position to the exact fan slot so the layout is pixel-perfect.
			card.position  = final_pos
			card.rotation  = rot_rad
			card.scale     = Vector2.ONE
			# Mark the card as ready for interaction.
			card.drag_state            = CardUI.DragState.IDLE
			card.original_global_position = card.global_position
			card.mouse_filter          = Control.MOUSE_FILTER_STOP
			swipe.play()
		)

## ==========================================
## FAN LAYOUT CALCULATION (returns target dicts)
## ==========================================

## Computes the local position and rotation for each card slot in the fan.
## Returns an Array of Dictionaries: [{position: Vector2, rotation_rad: float}, ...]
func _compute_fan_targets(num_cards: int) -> Array:
	var targets: Array = []

	if num_cards == 0:
		return targets

	# Single-card edge case: centre it flat.
	if num_cards == 1:
		targets.append({
			"position":     Vector2((custom_minimum_size.x - CARD_WIDTH) / 2.0, y_min),
			"rotation_rad": 0.0
		})
		return targets

	# Multi-card fan layout.
	var total_width: float = (CARD_WIDTH * float(num_cards)) + (x_separation * float(num_cards - 1))
	var final_x_sep: float = x_separation

	if total_width > custom_minimum_size.x:
		final_x_sep = (custom_minimum_size.x - (CARD_WIDTH * float(num_cards))) / float(num_cards - 1)
		total_width  = custom_minimum_size.x

	var x_offset: float = (custom_minimum_size.x - total_width) / 2.0

	for i in range(num_cards):
		var ratio: float = float(i) / float(num_cards - 1)

		var y_curve_value: float = hand_curve.sample(ratio)
		var r_curve_value: float = rotation_curve.sample(ratio)

		var final_x: float = x_offset + (float(i) * (CARD_WIDTH + final_x_sep))
		var final_y: float = y_min + (y_curve_value * y_max)
		var rot_deg: float = r_curve_value * max_rotation_degrees

		targets.append({
			"position":     Vector2(final_x, final_y),
			"rotation_rad": deg_to_rad(rot_deg)
		})

	return targets

## ==========================================
## SIGNAL HANDLERS
## ==========================================

func _on_card_reparent_requested(child: CardUI) -> void:
	if child.hand_index >= 0 and child.get_parent() == self:
		move_child(child, child.hand_index)

	child.pivot_offset = Vector2.ZERO
	child.rotation     = 0.0

	update_fan_layout()

func _on_card_answer_submitted(card: CardUI) -> void:
	card_answer_submitted.emit(card)

## ==========================================
## CARD FANNING LAYOUT (live update for IDLE cards)
## ==========================================

func update_fan_layout() -> void:
	var active_cards: Array = []
	for child in get_children():
		if child is CardUI and not child.is_queued_for_deletion():
			var c := child as CardUI
			if c.drag_state == CardUI.DragState.IDLE:
				active_cards.append(c)

	var num_cards: int = active_cards.size()
	if num_cards == 0:
		return

	if num_cards == 1:
		var card: CardUI = active_cards[0] as CardUI
		if card:
			card.position         = Vector2((custom_minimum_size.x - CARD_WIDTH) / 2.0, y_min)
			card.rotation_degrees = 0.0
		return

	var total_width: float = (CARD_WIDTH * float(num_cards)) + (x_separation * float(num_cards - 1))
	var final_x_sep: float = x_separation

	if total_width > custom_minimum_size.x:
		final_x_sep = (custom_minimum_size.x - (CARD_WIDTH * float(num_cards))) / float(num_cards - 1)
		total_width  = custom_minimum_size.x

	var x_offset: float = (custom_minimum_size.x - total_width) / 2.0

	for i in range(num_cards):
		var card: CardUI = active_cards[i] as CardUI
		if not card:
			continue

		var ratio: float = float(i) / float(num_cards - 1)

		var y_curve_value: float = hand_curve.sample(ratio)
		var r_curve_value: float = rotation_curve.sample(ratio)

		var final_x: float = x_offset + (float(i) * (CARD_WIDTH + final_x_sep))
		var final_y: float = y_min + (y_curve_value * y_max)

		card.position         = Vector2(final_x, final_y)
		card.rotation_degrees = r_curve_value * max_rotation_degrees
