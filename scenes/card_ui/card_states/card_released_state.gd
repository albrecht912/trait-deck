extends CardState

## ==========================================
## RELEASED STATE (evaluate drop zone on mouse-up)
## ==========================================
## • Entered when the player releases the left mouse button while dragging.
## • If the card's Area2D (DropPointDetector) is overlapping a valid drop zone
##   Area2D, transition to SELECTED (snap to center, await confirm).
## • If released outside any drop zone, snap back to BASE (return to hand).

func enter() -> void:
	card_ui.color.color = Color.DARK_VIOLET
	card_ui.state.text  = "RELEASED"

	if not card_ui.targets.is_empty():
		# Card is over a valid drop zone → advance to the placement/confirm state.
		print("[CardUI] Released over drop zone. Targets: ", card_ui.targets)
		transition_requested.emit(self, CardState.State.SELECTED)
	else:
		# Card was dropped in empty space → return it to the hand.
		print("[CardUI] Released outside drop zone. Returning to hand.")
		transition_requested.emit(self, CardState.State.BASE)
