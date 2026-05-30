class_name QuestionCard
extends Control

## ==========================================
## QuestionCard.gd
## Manages the question prompt card's slide-in / slide-out animations.
## Attach to the root Control node of question_card.tscn.
## ==========================================

## ==========================================
## SIGNALS
## ==========================================

# Emitted when the slide-out tween finishes so SessionManager can await it.
signal slide_out_finished

## ==========================================
## POSITION CONSTANTS
## ==========================================

# Resting center position on screen.
const POS_CENTER: Vector2    = Vector2(760.0, 170.0)

# Fully off-screen to the right — used for spawn point.
const POS_OFF_RIGHT: Vector2 = Vector2(1950.0, 170.0)

# Fully off-screen to the left — used for exit target.
const POS_OFF_LEFT: Vector2 = Vector2(-30.0, 170.0)

## ==========================================
## ANIMATION DURATIONS
## ==========================================

const SLIDE_IN_DURATION: float  = 0.5
const SLIDE_OUT_DURATION: float = 0.35

## ==========================================
## NODE REFERENCES
## ==========================================

@onready var prompt_label: Label            = $CardBackground/PromptLabel
@onready var q_number_top_left: Label       = $CardBackground/QNumberTopLeft
@onready var q_number_bottom_right: Label   = $CardBackground/QNumberBottomRight

## ==========================================
## LIFECYCLE
## ==========================================

func _ready() -> void:
	# Start off-screen so the first slide_in_from_right() call is seamless.
	position = POS_OFF_RIGHT

## ==========================================
## PUBLIC API
## ==========================================

## Instantly snaps the card off-screen right, updates its text content,
## then tweens it to the center resting position.
## Call this at the end of _load_scenario() in SessionManager.
func slide_in_from_right(text: String, question_number: int) -> void:
	# Snap to the off-screen spawn point immediately (no visual flash).
	position = POS_OFF_RIGHT

	# Update label content while the card is hidden off-screen.
	_update_labels(text, question_number)

	# Tween the card into its resting center position.
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", POS_CENTER, SLIDE_IN_DURATION)

## Sweeps the card off-screen to the right, then emits slide_out_finished.
## SessionManager should `await question_card.slide_out_finished` after calling this.
func slide_out_to_left() -> void:
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", POS_OFF_LEFT, SLIDE_OUT_DURATION)
	# Emit the signal once the card is fully off-screen.
	tween.tween_callback(func() -> void:
		slide_out_finished.emit()
	)

## ==========================================
## INTERNAL HELPERS
## ==========================================

func _update_labels(text: String, number: int) -> void:
	var q_num_str: String = str(number)

	if prompt_label:
		prompt_label.text = text
	if q_number_top_left:
		q_number_top_left.text = q_num_str
	if q_number_bottom_right:
		q_number_bottom_right.text = q_num_str

## Legacy helper kept for compatibility — delegates to slide_in_from_right.
func setup_question(text: String, number: int) -> void:
	slide_in_from_right(text, number)
