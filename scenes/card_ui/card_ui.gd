class_name CardUI
extends Control

## ==========================================
## SIGNALS
## ==========================================

signal answer_submitted(which_card_ui: CardUI)
# Still emitted so Hand.gd can restore the card's slot on cancel.
signal reparent_requested(which_card_ui: CardUI)

## ==========================================
## DRAG STATE ENUM
## ==========================================

enum DragState { IDLE, DRAGGING, RELEASED, PLACED }

## ==========================================
## BFI-2 DATABASE TRACKING PROPERTIES
## ==========================================

var card_db_id: int    = -1
var likert_value: int  = -1

# Original sibling index in Hand — used to restore slot order on cancel.
var hand_index: int = -1

## ==========================================
## DRAG TRACKING
## ==========================================

var drag_state: DragState = DragState.IDLE

# World-space position of the card when the player first clicks it.
# Used to snap back on cancel or failed drop.
var original_global_position: Vector2 = Vector2.ZERO

# Offset between the card's global_position and the cursor at the moment of click.
# Keeps the card locked to the exact grab point throughout the drag.
var _drag_offset: Vector2 = Vector2.ZERO

# Reference to the DropZone Area2D inside AnswerUI — set by Hand.gd after spawn.
var drop_zone: Area2D = null

## ==========================================
## NODE REFERENCES
## ==========================================

@onready var color_rect: ColorRect = $Color
@onready var state_label: Label    = $State
@onready var answer_label: Label   = $AnswerLabel

## ==========================================
## LIFECYCLE
## ==========================================

func _ready() -> void:
	# Ensure the card starts in a clean idle state.
	_set_drag_state(DragState.IDLE)

## ==========================================
## INPUT HANDLING
## ==========================================

func _gui_input(event: InputEvent) -> void:
	# ---- LEFT MOUSE DOWN: begin drag ----
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton

		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			if drag_state == DragState.IDLE:
				_begin_drag()
			elif drag_state == DragState.PLACED:
				# Second left-click while placed → confirm submission.
				_confirm_answer()

		elif mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			if drag_state == DragState.DRAGGING:
				_end_drag()

		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if drag_state == DragState.DRAGGING or drag_state == DragState.PLACED:
				_cancel_drag()

func _input(event: InputEvent) -> void:
	# Track mouse movement globally while dragging so the card follows even if
	# the cursor leaves the card's own rect.
	if drag_state == DragState.DRAGGING and event is InputEventMouseMotion:
		# Use the saved offset so the card stays locked to the exact grab point,
		# not just centered under the cursor.
		global_position = get_global_mouse_position() + _drag_offset

## ==========================================
## DRAG LIFECYCLE METHODS
## ==========================================

func _begin_drag() -> void:
	# Capture the current world-space position as the "home" to return to on cancel.
	original_global_position = global_position

	# Step 1: Record the offset between the card's screen position and the cursor
	# BEFORE setting top_level. This preserves the grab point so the card doesn't jump.
	_drag_offset = global_position - get_global_mouse_position()

	# Step 2: Break free from the Hand container's layout.
	# top_level = true makes the Control ignore its parent's transform/layout.
	top_level = true

	# Step 3: Immediately re-lock the card to the cursor using the saved offset
	# so there is zero visual jump on the frame top_level is applied.
	global_position = get_global_mouse_position() + _drag_offset

	_set_drag_state(DragState.DRAGGING)

func _end_drag() -> void:
	_set_drag_state(DragState.RELEASED)

	# Check whether the card is overlapping the DropZone.
	if _is_over_drop_zone():
		_place_card()
	else:
		_cancel_drag()

func _place_card() -> void:
	_set_drag_state(DragState.PLACED)

	# Re-attach to the layout (top_level = false) so the card is part of the
	# CanvasLayer coordinate space again.
	top_level = false

	# Snap the card's center to the center of the DropZone.
	if drop_zone:
		var zone_center: Vector2 = drop_zone.global_position
		# Offset by half the card size so the card is centered on the zone.
		global_position = zone_center - size / 2.0
	else:
		# Fallback: snap to viewport center.
		global_position = (get_viewport_rect().size / 2.0) - (size / 2.0)

	# Flatten rotation for a clean placed look.
	rotation = 0.0

func _cancel_drag() -> void:
	# Re-attach to the layout immediately.
	top_level = false

	# Instantly snap back to the position the card was at before dragging began.
	global_position = original_global_position

	# Reset state and notify Hand.gd to restore the sibling index.
	_set_drag_state(DragState.IDLE)
	reparent_requested.emit(self)

func _confirm_answer() -> void:
	# Emit the answer signal — SessionManager will handle DB write and progression.
	answer_submitted.emit(self)

## ==========================================
## DROP ZONE DETECTION
## ==========================================

## Returns true if this card's bounding rect overlaps the DropZone's rect.
## Works entirely in CanvasLayer/screen space — no physics needed.
func _is_over_drop_zone() -> bool:
	if drop_zone == null:
		return false

	# Build a screen-space rect for the card.
	var card_rect: Rect2 = Rect2(global_position, size)

	# Build a screen-space rect for the drop zone using its CollisionShape2D child.
	var shape_node: CollisionShape2D = drop_zone.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return false

	var zone_shape := shape_node.shape as RectangleShape2D
	if zone_shape == null:
		return false

	var zone_half: Vector2 = zone_shape.size / 2.0
	var zone_rect: Rect2   = Rect2(shape_node.global_position - zone_half, zone_shape.size)

	return card_rect.intersects(zone_rect)

## ==========================================
## STATE VISUAL FEEDBACK
## ==========================================

func _set_drag_state(new_state: DragState) -> void:
	drag_state = new_state
	match drag_state:
		DragState.IDLE:
			color_rect.color = Color.WEB_GREEN
			state_label.text = "IDLE"
		DragState.DRAGGING:
			color_rect.color = Color.NAVY_BLUE
			state_label.text = "DRAGGING"
		DragState.RELEASED:
			color_rect.color = Color.DARK_VIOLET
			state_label.text = "RELEASED"
		DragState.PLACED:
			color_rect.color = Color.GOLD
			state_label.text = "PLACED"

## ==========================================
## DATABASE HELPER
## ==========================================

func set_dialogue_text(new_text: String) -> void:
	if answer_label:
		answer_label.text = new_text
	else:
		get_node("AnswerLabel").text = new_text
