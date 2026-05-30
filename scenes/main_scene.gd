extends Node3D

# 1. Preload the pause screen scene asset so it is cached and ready to instantiate
const PAUSE_SCREEN_SCENE: PackedScene = preload("res://scenes/pause_screen.tscn")

# Keep track of the active instance so we don't open duplicate pause menus
var _active_pause_screen: Node = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	# 2. Check for your pause action mapping or Escape (ui_cancel is Escape by default)
	if event.is_action_pressed("ui_cancel"):
		# Ensure the game isn't already paused and an overlay doesn't already exist
		if _active_pause_screen == null:
			_open_pause_menu()


func _open_pause_menu() -> void:
	print("[TraitDeck] MainScene: Instantiating Pause Screen.")
	
	# 3. Create a fresh runtime copy of the pause screen scene
	_active_pause_screen = PAUSE_SCREEN_SCENE.instantiate()
	
	# 4. Add it to the top UI layer of your main scene tree
	add_child(_active_pause_screen)
