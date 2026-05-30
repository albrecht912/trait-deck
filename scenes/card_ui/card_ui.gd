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

var likert_value: int = -1 :
	set(value):
		likert_value = value
		if is_node_ready():
			_update_likert_labels()

## ==========================================
## DRAG TRACKING
## ==========================================

var drag_state: DragState = DragState.IDLE

# World-space position of the card when the player first clicks it.
var original_global_position: Vector2 = Vector2.ZERO

# Offset between the card's global_position and the cursor at the moment of click.
var _drag_offset: Vector2 = Vector2.ZERO

# Reference to the DropZone Area2D inside AnswerUI — set by Hand.gd after spawn.
var drop_zone: Area2D = null

## ==========================================
## TILT SHADER PARAMETERS
## ==========================================

var angle_x_max: float = deg_to_rad(15.0)
var angle_y_max: float = deg_to_rad(15.0)

## ==========================================
## SHADOW PARAMETERS
## ==========================================

var max_offset_shadow: float    = 20.0
var base_shadow_y_offset: float = 10.0

## ==========================================
## LABEL PARALLAX TRACKING
## ==========================================

# Stores the resting local position of each text label so they can snap back.
var base_label_positions: Dictionary = {}

## ==========================================
## HOVER / ROTATION TWEEN HANDLES
## ==========================================

var tween_hover: Tween
var tween_rot: Tween

## ==========================================
## NODE REFERENCES
## ==========================================

@onready var card_texture: TextureRect  = $CardBackground
@onready var card_shadow: TextureRect   = $Shadow

# Labels are children of CardBackground.
@onready var answer_label: Label        = $CardBackground/AnswerLabel
@onready var likert_top_left: Label     = $CardBackground/LikertValTopLeft
@onready var likert_bottom_right: Label = $CardBackground/LikertValBottomRight

## ==========================================
## LIFECYCLE
## ==========================================

func _ready() -> void:
	# --- Isolate shader resources: each card gets its own material instance ---
	if card_texture.material:
		card_texture.material = card_texture.material.duplicate()
	if card_shadow.material:
		card_shadow.material = card_shadow.material.duplicate()

	# --- Capture resting positions of all text labels for parallax reset ---
	base_label_positions["answer"]       = answer_label.position
	base_label_positions["likert_tl"]    = likert_top_left.position
	base_label_positions["likert_br"]    = likert_bottom_right.position

	_update_likert_labels()
	drag_state = DragState.IDLE
	# mouse_entered.connect(_on_mouse_entered)
	# mouse_exited.connect(_on_mouse_exited)

## ==========================================
## PROCESS (shadow update every frame)
## ==========================================

func _process(delta: float) -> void:
	handle_shadow(delta)

## ==========================================
## SHADOW HANDLER
## ==========================================

## Dynamically repositions the Shadow TextureRect based on the card's screen
## position and current hover scale, simulating a perspective elevation effect.
func handle_shadow(delta: float) -> void:
	var center: Vector2 = get_viewport_rect().size / 2.0
	var distance: float = global_position.x - center.x

	# Horizontal: shadow shifts away from the screen center proportionally.
	card_shadow.position.x = lerp(
		0.0,
		-sign(distance) * max_offset_shadow,
		abs(distance / center.x)
	)

	# Vertical: shadow drops further when the card is scaled up (hover/drag),
	# simulating the card lifting off the surface.
	var height_factor: float = (scale.x - 1.0) * 50.0
	card_shadow.position.y = base_shadow_y_offset + height_factor

## ==========================================
## INPUT HANDLING
## ==========================================

func _gui_input(event: InputEvent) -> void:
	# --- Handle click/drag/cancel inputs ---
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton

		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			if drag_state == DragState.IDLE:
				_begin_drag()
			elif drag_state == DragState.PLACED:
				_confirm_answer()

		elif mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			if drag_state == DragState.DRAGGING:
				_end_drag()

		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if drag_state == DragState.DRAGGING or drag_state == DragState.PLACED:
				_cancel_drag()

	# --- Tilt shader: skip when dragging or placed ---
	if drag_state == DragState.DRAGGING or drag_state == DragState.PLACED:
		return
	if not event is InputEventMouseMotion:
		return

	# --- Compute perspective tilt from local mouse position ---
	var mouse_pos: Vector2 = get_local_mouse_position()

	var lerp_val_x: float = remap(mouse_pos.x, 0.0, size.x, 0.0, 1.0)
	var lerp_val_y: float = remap(mouse_pos.y, 0.0, size.y, 0.0, 1.0)

	var rot_x: float = rad_to_deg(lerp_angle(-angle_x_max, angle_x_max, lerp_val_x))
	var rot_y: float = rad_to_deg(lerp_angle(angle_y_max, -angle_y_max, lerp_val_y))

	_set_tilt(rot_y, rot_x)

	# --- 3D parallax emulation: shift all text labels opposite to the tilt ---
	var text_offset_x: float = rot_y * 0.4
	var text_offset_y: float = -rot_x * 0.4
	var parallax_offset: Vector2 = Vector2(text_offset_x, text_offset_y)

	answer_label.position      = base_label_positions["answer"]    + parallax_offset
	likert_top_left.position   = base_label_positions["likert_tl"] + parallax_offset
	likert_bottom_right.position = base_label_positions["likert_br"] + parallax_offset

func _input(event: InputEvent) -> void:
	# Track mouse movement globally while dragging.
	if drag_state == DragState.DRAGGING and event is InputEventMouseMotion:
		global_position = get_global_mouse_position() + _drag_offset

		# Juice B: Velocity-driven wobble — card leans in the direction of mouse movement.
		var mouse_velocity: Vector2 = event.relative
		var target_wobble: float = clampf(mouse_velocity.x * 0.15, -25.0, 25.0)
		DampedOscillator.animate(self, "rotation_degrees", 200.0, 10.0, target_wobble, 1.0)

## ==========================================
## HOVER ANIMATIONS
## ==========================================

func _on_mouse_entered() -> void:
	if drag_state == DragState.DRAGGING or drag_state == DragState.PLACED:
		return

	if tween_hover and tween_hover.is_running():
		tween_hover.kill()

	tween_hover = create_tween()
	tween_hover.set_ease(Tween.EASE_OUT)
	tween_hover.set_trans(Tween.TRANS_ELASTIC)
	tween_hover.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)

func _on_mouse_exited() -> void:
	# --- Reset shader tilt rotation and label parallax ---
	if tween_rot and tween_rot.is_running():
		tween_rot.kill()

	if card_texture and card_texture.material:
		tween_rot = create_tween()
		tween_rot.set_ease(Tween.EASE_OUT)
		tween_rot.set_trans(Tween.TRANS_BACK)
		tween_rot.set_parallel(true)
		tween_rot.tween_property(card_texture.material, "shader_parameter/x_rot", 0.0, 0.5)
		tween_rot.tween_property(card_texture.material, "shader_parameter/y_rot", 0.0, 0.5)
		# Return all text labels to their resting positions.
		tween_rot.tween_property(answer_label,        "position", base_label_positions["answer"],    0.5)
		tween_rot.tween_property(likert_top_left,     "position", base_label_positions["likert_tl"], 0.5)
		tween_rot.tween_property(likert_bottom_right, "position", base_label_positions["likert_br"], 0.5)

	# --- Reset card scale ---
	if tween_hover and tween_hover.is_running():
		tween_hover.kill()

	tween_hover = create_tween()
	tween_hover.set_ease(Tween.EASE_OUT)
	tween_hover.set_trans(Tween.TRANS_ELASTIC)
	tween_hover.tween_property(self, "scale", Vector2.ONE, 0.55)

## ==========================================
## DRAG LIFECYCLE METHODS
## ==========================================

func _begin_drag() -> void:
	original_global_position = global_position
	_drag_offset = global_position - get_global_mouse_position()
	top_level = true
	global_position = get_global_mouse_position() + _drag_offset
	drag_state = DragState.DRAGGING
	_kill_hover_tweens()
	scale = Vector2.ONE
	_reset_tilt()
	_reset_label_positions()

	# Juice A: Squash-and-stretch pickup spring — card elastically pops up on lift.
	DampedOscillator.animate(self, "scale", 250.0, 12.0, 18.0, 1.15)

func _end_drag() -> void:
	drag_state = DragState.RELEASED
	if _is_over_drop_zone():
		_place_card()
	else:
		_cancel_drag()

func _place_card() -> void:
	drag_state = DragState.PLACED
	top_level = false

	if drop_zone:
		var zone_center: Vector2 = drop_zone.global_position
		global_position = zone_center - size / 2.0
	else:
		global_position = (get_viewport_rect().size / 2.0) - (size / 2.0)

	rotation = 0.0
	scale = Vector2.ONE
	_reset_tilt()
	_reset_label_positions()

func _cancel_drag() -> void:
	top_level = false
	global_position = original_global_position
	drag_state = DragState.IDLE
	scale = Vector2.ONE
	_reset_label_positions()

	# Juice C: Snap-back bounce — card settles into its slot with a rubber-band spring.
	DampedOscillator.animate(self, "scale", 300.0, 8.0, 20.0, 1.0)
	DampedOscillator.animate(self, "rotation_degrees", 250.0, 9.0, 15.0, 0.0)

	reparent_requested.emit(self)

func _confirm_answer() -> void:
	# Dissolve plays FIRST — answer_submitted is emitted only at the very end
	# of the tween so SessionManager advances the level only after the card
	# has become completely invisible.
	animate_dissolve_and_free()

## ==========================================
## ASYNC DISSOLVE DESTRUCTION
## ==========================================

## Plays a shader dissolve animation, then emits answer_submitted and frees the node.
## The signal is deferred to the final tween callback so the level never advances
## before the burn-away completes visually.
func animate_dissolve_and_free() -> void:
	# Prevent any further mouse interaction during the dissolve.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Save screen coordinates BEFORE escaping the container layout so the card
	# stays exactly where it was placed when top_level recalculates its transform.
	var current_global_pos: Vector2 = global_position
	top_level = true
	global_position = current_global_pos

	# Guard: if the material doesn't support dissolve_value, emit and free immediately.
	if not (card_texture and card_texture.material):
		answer_submitted.emit(self)
		queue_free()
		return

	# Tween dissolve_value from 1.0 (fully visible) → 0.0 (fully dissolved).
	var tween_dissolve: Tween = create_tween()
	tween_dissolve.set_ease(Tween.EASE_IN)
	tween_dissolve.set_trans(Tween.TRANS_QUAD)
	tween_dissolve.tween_property(
		card_texture.material,
		"shader_parameter/dissolve_value",
		0.0,
		0.6
	)
	# Emit the answer signal and free the node only after the dissolve finishes.
	tween_dissolve.tween_callback(func() -> void:
		answer_submitted.emit(self)
		queue_free()
	)

## ==========================================
## DROP ZONE DETECTION
## ==========================================

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
## TILT SHADER HELPERS
## ==========================================

func _set_tilt(x_rot: float, y_rot: float) -> void:
	if card_texture and card_texture.material:
		card_texture.material.set_shader_parameter("x_rot", x_rot)
		card_texture.material.set_shader_parameter("y_rot", y_rot)
	if card_shadow and card_shadow.material:
		card_shadow.material.set_shader_parameter("x_rot", x_rot)
		card_shadow.material.set_shader_parameter("y_rot", y_rot)

func _reset_tilt() -> void:
	_set_tilt(0.0, 0.0)

## ==========================================
## LABEL POSITION HELPERS
## ==========================================

func _reset_label_positions() -> void:
	answer_label.position        = base_label_positions["answer"]
	likert_top_left.position     = base_label_positions["likert_tl"]
	likert_bottom_right.position = base_label_positions["likert_br"]

## ==========================================
## TWEEN CLEANUP HELPER
## ==========================================

func _kill_hover_tweens() -> void:
	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	if tween_rot and tween_rot.is_running():
		tween_rot.kill()

## ==========================================
## LIKERT LABEL HELPER
## ==========================================

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
		get_node("CardBackground/AnswerLabel").text = new_text
