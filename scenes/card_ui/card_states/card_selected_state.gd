extends CardState

## ==========================================
## SELECTED STATE (card placed in drop zone, awaiting confirmation)
## ==========================================
## • Entered when the card is released over a valid drop zone Area2D.
## • The card snaps to the center of the viewport and sits flat (no rotation).
## • Left-click → confirm and submit the answer (emits answer_submitted).
## • Right-click → cancel, return the card to its original hand slot (BASE).

func enter() -> void:
	card_ui.color.color = Color.GOLD
	card_ui.state.text  = "SELECTED"

	# Stop the drop-zone detector — we're already placed.
	card_ui.drop_point_detector.monitoring = false

	# Flatten the card rotation so it sits cleanly in the center.
	card_ui.rotation = 0.0

	# Reset pivot so global_position math is straightforward.
	card_ui.pivot_offset = Vector2.ZERO

	# Snap the card to the center of the viewport.
	var viewport_size: Vector2 = card_ui.get_viewport_rect().size
	var card_size: Vector2     = card_ui.size
	card_ui.global_position    = (viewport_size / 2.0) - (card_size / 2.0)

func on_input(event: InputEvent) -> void:
	# --- Right-click: cancel placement, return card to hand ---
	if event.is_action_pressed("right_mouse"):
		transition_requested.emit(self, CardState.State.BASE)

	# --- Left-click: confirm and submit the answer ---
	elif event.is_action_pressed("left_mouse"):
		get_viewport().set_input_as_handled()
		card_ui.answer_submitted.emit(card_ui)
