extends CardState

## ==========================================
## BASE STATE (card is resting in the Hand fan)
## ==========================================
## • Entering this state returns the card to the Hand container.
## • Left-click on the card → CLICKED state (begins drag pipeline).
## • Right-click is a no-op here (card is already home).

func enter() -> void:
	if not card_ui.is_node_ready():
		await card_ui.ready

	# Emit reparent signal so Hand.gd can move the card back into its slot.
	card_ui.reparent_requested.emit(card_ui)

	# Visual debug feedback
	card_ui.color.color = Color.WEB_GREEN
	card_ui.state.text  = "BASE"

	# Reset pivot so the fan layout can position the card cleanly.
	card_ui.pivot_offset = Vector2.ZERO

	# Stop the drop-zone detector while the card is at rest.
	card_ui.drop_point_detector.monitoring = false

## Left-click on the card body starts the interaction pipeline.
func on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		# Capture the current sibling index so we can restore it on cancel.
		card_ui.hand_index = card_ui.get_index()

		# Store the card's current global position as the "home" to snap back to.
		card_ui.original_position = card_ui.global_position

		transition_requested.emit(self, CardState.State.CLICKED)
