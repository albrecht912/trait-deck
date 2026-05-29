extends CardState

## ==========================================
## CLICKED STATE (brief moment between press and drag)
## ==========================================
## • Entered immediately on left-click in BASE state.
## • Enables the drop-zone detector and reparents the card to the UI layer
##   so it can move freely over the full screen without being clipped by Hand.
## • Any mouse movement → DRAGGING state.
## • Right-click → cancel back to BASE.

func enter() -> void:
	card_ui.color.color = Color.ORANGE
	card_ui.state.text  = "CLICKED"

	# Enable the Area2D detector so it can register drop-zone overlaps while dragging.
	card_ui.drop_point_detector.monitoring = true

	# Reparent to the CanvasLayer (ui_layer group) so the card renders above everything
	# and is no longer constrained by the Hand Control's layout bounds.
	var ui_layer: Node = get_tree().get_first_node_in_group("ui_layer")
	if ui_layer:
		card_ui.reparent(ui_layer)

func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Any mouse movement after the click begins the drag.
		transition_requested.emit(self, CardState.State.DRAGGING)
	elif event.is_action_pressed("right_mouse"):
		# Right-click immediately cancels and returns the card to its hand slot.
		transition_requested.emit(self, CardState.State.BASE)
