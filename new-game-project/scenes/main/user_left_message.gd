extends Control

func _on_button_pressed() -> void:
	GameState.reset_game()
	Music.play_button_sound()
	get_tree().change_scene_to_file("res://scenes/GameMode/GameMode.tscn")
