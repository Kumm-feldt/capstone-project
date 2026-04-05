extends Control

signal popup_closed  # define the custom signal

var colorScreenScene = load("res://scenes/ColorPicker/ColorSelectionScreen.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_exit_button_pressed() -> void:
	emit_signal("popup_closed")  # tell the parent to handle cleanup


func _on_easy_ai_button_pressed() -> void:
	GameManager.GAME_MODE = GameManager.Mode.AI
	GameManager.AI_MODE_LEVEL = GameManager.AILevel.Easy
	
	var colorScreen = colorScreenScene.instantiate()
	colorScreen.setGamemode("EasyAI")
	
	var root = get_tree().root
	var current = get_tree().current_scene
	current.queue_free()
	
	get_tree().root.add_child(colorScreen)
	get_tree().current_scene = colorScreen
	
	# Below method is from before colorSelectionScreen.
	#get_tree().change_scene_to_file("res://scenes/main/Main.tscn")



func _on_hard_button_pressed() -> void:
	GameManager.GAME_MODE = GameManager.Mode.AI
	GameManager.AI_MODE_LEVEL = GameManager.AILevel.Difficult
	
	var colorScreen = colorScreenScene.instantiate()
	colorScreen.setGamemode("HardAI")
	
	var root = get_tree().root
	var current = get_tree().current_scene
	current.queue_free()
	
	get_tree().root.add_child(colorScreen)
	get_tree().current_scene = colorScreen
	# Below method is from before colorSelectionScreen.
	#get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
