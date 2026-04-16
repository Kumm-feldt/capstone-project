extends Control

signal popup_closed  # define the custom signal

var colorScreenScene = load("res://scenes/ColorPicker/ColorSelectionScreen.tscn")

# ============================================
# Input handling (ESC)
# ============================================
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("close"):
		_on_exit_button_pressed()

func _on_exit_button_pressed() -> void:
	Music.play_button_sound()
	emit_signal("popup_closed")  # tell the parent to handle cleanup

func _on_easy_ai_button_pressed() -> void:
	Music.play_button_sound()
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
	Music.play_button_sound()
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
