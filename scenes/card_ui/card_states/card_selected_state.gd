extends CardState

# The card snaps to the center of the viewport when entering this state.
# Left click again -> confirm/submit the answer
# Right click -> cancel, return to BASE (back to hand)

var _viewport_center: Vector2

func enter() -> void:
	card_ui.color.color = Color.GOLD
	card_ui.state.text = "SELECTED"
	card_ui.drop_point_detector.monitoring = false

	# Reset rotation so the card sits flat in the center
	card_ui.rotation = 0.0

	# Calculate the viewport center and snap the card there
	var viewport_size = card_ui.get_viewport_rect().size
	_viewport_center = viewport_size / 2.0

	# Center the card on screen (accounting for card size)
	var card_size = card_ui.size
	card_ui.global_position = _viewport_center - card_size / 2.0

	# Reset pivot so it doesn't offset the position
	card_ui.pivot_offset = Vector2.ZERO

func on_input(event: InputEvent) -> void:
	if event.is_action_pressed("right_mouse"):
		# Cancel: return card to hand
		transition_requested.emit(self, CardState.State.BASE)
	elif event.is_action_pressed("left_mouse"):
		# Confirm: submit the answer
		get_viewport().set_input_as_handled()
		card_ui.answer_submitted.emit(card_ui)
