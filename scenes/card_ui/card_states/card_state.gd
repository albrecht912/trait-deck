class_name CardState
extends Node

enum State {BASE, CLICKED, DRAGGING, AIMING, RELEASED, SELECTED}

# silence the compiler:
@warning_ignore("unused_signal")
signal transition_requested(from: CardState, to: State)  # Unused — FSM uses direct method calls.

@export var state: State

var card_ui: CardUI

func enter() -> void:
	pass

func exit() -> void:
	pass

func on_input(_event: InputEvent) -> void:
	pass

func on_gui_input(_event: InputEvent) -> void:
	pass

func on_mouse_entered() -> void:
	pass

func on_mouse_exited() -> void:
	pass
