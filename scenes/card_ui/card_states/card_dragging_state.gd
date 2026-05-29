extends CardState

## ==========================================
## DRAGGING STATE (card follows the mouse cursor)
## ==========================================
## • Card position tracks the mouse every frame.
## • Right-click → cancel, return to BASE (hand slot).
## • Left mouse released → RELEASED state (checks drop zone).
## A minimum drag time prevents an accidental immediate release.

const DRAG_MINIMUM_THRESHOLD: float = 0.05

var _minimum_drag_time_elapsed: bool = false

func enter() -> void:
	card_ui.color.color = Color.NAVY_BLUE
	card_ui.state.text  = "DRAGGING"

	# Set pivot to card center so it sits naturally under the cursor.
	card_ui.pivot_offset = card_ui.size / 2.0

	# Brief timer prevents the card from snapping back immediately if the player
	# clicks and releases very quickly without moving the mouse.
	_minimum_drag_time_elapsed = false
	var threshold_timer: SceneTreeTimer = get_tree().create_timer(DRAG_MINIMUM_THRESHOLD, false)
	threshold_timer.timeout.connect(func() -> void: _minimum_drag_time_elapsed = true)

func on_input(event: InputEvent) -> void:
	# --- Follow the mouse ---
	if event is InputEventMouseMotion:
		# Position the card so its center sits under the cursor.
		card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.pivot_offset
		return

	# --- Cancel: right-click returns card to hand ---
	if event.is_action_pressed("right_mouse"):
		transition_requested.emit(self, CardState.State.BASE)
		return

	# --- Release: left mouse button up → evaluate drop zone ---
	if _minimum_drag_time_elapsed and event.is_action_released("left_mouse"):
		get_viewport().set_input_as_handled()
		transition_requested.emit(self, CardState.State.RELEASED)
