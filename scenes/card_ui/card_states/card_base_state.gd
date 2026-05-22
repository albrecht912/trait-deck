extends CardState

func enter() -> void:
	if not card_ui.is_node_ready():
		await card_ui.ready
	
	#returns to base state if relased outside drop area or rmb is pressed during drag
	card_ui.reparent_requested.emit(card_ui)
	card_ui.color.color = Color.WEB_GREEN
	card_ui.state.text = "BASE"
	#snap card to where we clicked on the card
	card_ui.pivot_offset = Vector2.ZERO

#transition to selected state on left click (snap to center)
func on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		# Save the current sibling index before leaving the hand, so we can restore it on cancel
		card_ui.hand_index = card_ui.get_index()
		# Reparent to ui_layer so the card can move freely over the whole screen
		var ui_layer := get_tree().get_first_node_in_group("ui_layer")
		if ui_layer:
			card_ui.reparent(ui_layer)
		transition_requested.emit(self, CardState.State.SELECTED)
	
