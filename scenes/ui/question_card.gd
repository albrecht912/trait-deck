class_name QuestionCard
extends Control

## ==========================================
## QuestionCard.gd
## Attached to the root of question_card.tscn.
## Provides a clean setup_question() API so SessionManager never needs to
## reach into the sub-scene's node tree directly.
## ==========================================

## ==========================================
## NODE REFERENCES
## ==========================================

@onready var prompt_label: Label        = $CardBackground/PromptLabel
@onready var q_number_top_left: Label   = $CardBackground/QNumberTopLeft
@onready var q_number_bottom_right: Label = $CardBackground/QNumberBottomRight

## ==========================================
## PUBLIC API
## ==========================================

## Called by SessionManager after every DB query to populate the question card.
## text   — the full context_text string from the ITEM table.
## number — the current item_id (1-indexed) used for the corner counter labels.
func setup_question(text: String, number: int) -> void:
	if prompt_label:
		prompt_label.text = text

	var q_num_str: String = str(number)

	if q_number_top_left:
		q_number_top_left.text = q_num_str

	if q_number_bottom_right:
		q_number_bottom_right.text = q_num_str
