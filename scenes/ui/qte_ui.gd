extends CanvasLayer
class_name QTEUI

## Reusable timed Quick Time Event overlay. Press the button (or Space/Enter) before the bar runs out.
## run_sequence() plays a named crisis and logs Negative Emotionality (reaction), plus
## Conscientiousness for QTEs marked "c" and for preparation items carried into the crisis.

signal _resolved(result: Dictionary)

## Crisis sequences, keyed by the name in SessionManager's timeline entry.
const SEQUENCES := {
	"rain_collapse": {
		"qtes": [
			{"id": "catch_haris", "prompt": "Haris's knees buckle — catch him before he hits the tiles!", "action": "CATCH HIM", "window": 1.5},
			{"id": "check_vitals", "prompt": "He's breathing, barely. Check his pulse and open his bag for his Medical Alert Card!", "action": "CHECK HIS BAG", "window": 3.0, "c": true},
		],
		"prep_items": ["umbrella", "electrolyte_sachet", "flashlight_whistle"],
	},
}

@onready var _prompt: Label = $Root/Box/Prompt
@onready var _bar: ProgressBar = $Root/Box/Bar
@onready var _button: Button = $Root/Box/Action

var _run_id := 0
var _active := false
var _t0 := 0
var _window := 0.0

## Fast success -> 1 (composed), slow success -> up to 4, miss -> 5 (panic/freeze).
static func reaction_to_n(reaction_sec: float, window_sec: float, success: bool) -> float:
	if not success:
		return 5.0
	return 1.0 + 3.0 * clampf(reaction_sec / window_sec, 0.0, 1.0)

func _ready() -> void:
	visible = false
	_button.pressed.connect(press)

func _process(_delta: float) -> void:
	if _active:
		_bar.value = maxf(_window - (Time.get_ticks_msec() - _t0) / 1000.0, 0.0)

func _unhandled_input(event: InputEvent) -> void:
	if _active and event.is_action_pressed("ui_accept"):
		press()
		get_viewport().set_input_as_handled()

## Shows one prompt and resolves to {"success": bool, "reaction_sec": float}.
func run(prompt: String, action: String, window_sec: float) -> Dictionary:
	_run_id += 1
	var my_id := _run_id
	_prompt.text = prompt
	_button.text = action
	_bar.max_value = window_sec
	_bar.value = window_sec
	_window = window_sec
	_t0 = Time.get_ticks_msec()
	_active = true
	visible = true
	# Bound to this run so a stale timer can't fail a later QTE.
	get_tree().create_timer(window_sec).timeout.connect(func(): if my_id == _run_id: _finish(false))
	var result: Dictionary = await _resolved
	visible = false
	return result

func press() -> void:
	_finish(true)

func _finish(success: bool) -> void:
	if not _active:
		return
	_active = false
	_resolved.emit({"success": success, "reaction_sec": (Time.get_ticks_msec() - _t0) / 1000.0})

func run_sequence(sequence_name: String) -> void:
	var seq: Dictionary = SEQUENCES[sequence_name]
	for q in seq["qtes"]:
		await get_tree().create_timer(0.6).timeout  # beat between prompts
		var r: Dictionary = await run(q["prompt"], q["action"], q["window"])
		var meta := {"qte": q["id"], "success": r["success"], "reaction_sec": r["reaction_sec"], "window": q["window"]}
		print("[TraitDeck] QTE %s: %s" % [q["id"], meta])
		DatabaseManager.log_event("Negative Emotionality", "qte_reaction", reaction_to_n(r["reaction_sec"], q["window"], r["success"]), 1.0, meta)
		if q.get("c", false):
			DatabaseManager.log_event("Conscientiousness", "qte_action", 5.0 if r["success"] else 1.0, 1.0, meta)

	# Preparation payoff: share of the crisis items the player could have found that they carried.
	var available: Array = seq["prep_items"].filter(func(id): return TelemetryTracker.available["collectible"].has(id))
	if not available.is_empty():
		var held: Array = available.filter(func(id): return InventoryManager.has(id))
		print("[TraitDeck] Crisis preparation: %d/%d items carried" % [held.size(), available.size()])
		DatabaseManager.log_event("Conscientiousness", "crisis_preparation", TelemetryTracker.ratio_to_value(held.size(), available.size()), 1.0,
			{"held": held, "available": available})
