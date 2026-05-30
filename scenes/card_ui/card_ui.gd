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

var card_db_id: int = -1

# Original sibling index in Hand — used to restore slot order on cancel.
var hand_index: int = -1

## ==========================================
## LIKERT VALUE (drives both corner labels)
## ==========================================

# Set this to automatically update both LikertValTopLeft and LikertValBottomRight.
var likert_value: int = -1 :
	set(value):
		likert_value = value
		# Guard: nodes may not be ready yet during instantiation.
		if is_node_ready():
			_update_likert_labels()

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

@onready var answer_label: Label          = $AnswerLabel
@onready var likert_top_left: Label       = $LikertValTopLeft
@onready var likert_bottom_right: Label   = $LikertValBottomRight

## ==========================================
## LIFECYCLE
## ==========================================

func _ready() -> void:
	# Apply any likert_value that was set before the node was ready.
	_update_likert_labels()
	# Ensure drag state is clean on spawn.
	drag_state = DragState.IDLE

## ==========================================
## INPUT HANDLING
## ==========================================

func _gui_input(event: InputEvent) -> void:
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
		# Use the saved offset so the card stays locked to the exact grab point.
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
	top_level = true

	# Step 3: Immediately re-lock the card to the cursor using the saved offset
	# so there is zero visual jump on the frame top_level is applied.
	global_position = get_global_mouse_position() + _drag_offset

	drag_state = DragState.DRAGGING

func _end_drag() -> void:
	drag_state = DragState.RELEASED

	if _is_over_drop_zone():
		_place_card()
	else:
		_cancel_drag()

func _place_card() -> void:
	drag_state = DragState.PLACED

	# Re-attach to the layout so the card is part of the CanvasLayer space again.
	top_level = false

	# Snap the card's center to the center of the DropZone.
	if drop_zone:
		var zone_center: Vector2 = drop_zone.global_position
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

	drag_state = DragState.IDLE
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

	var card_rect: Rect2 = Rect2(global_position, size)

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
## LIKERT LABEL HELPER
## ==========================================

## Syncs both corner labels to the current likert_value.
## Called from the setter and from _ready() to handle deferred assignment.
func _update_likert_labels() -> void:
	var display_text: String = str(likert_value) if likert_value >= 0 else ""
	if likert_top_left:
		likert_top_left.text = display_text
	if likert_bottom_right:
		likert_bottom_right.text = display_text

## ==========================================
## DATABASE HELPER
## ==========================================

func set_dialogue_text(new_text: String) -> void:
	if answer_label:
		answer_label.text = new_text
	else:
		get_node("AnswerLabel").text = new_text
