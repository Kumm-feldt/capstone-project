extends Control

signal popup_closed  # define the custom signal

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
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")



func _on_hard_button_pressed() -> void:
	GameManager.GAME_MODE = GameManager.Mode.AI
	GameManager.AI_MODE_LEVEL = GameManager.AILevel.Difficult
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
