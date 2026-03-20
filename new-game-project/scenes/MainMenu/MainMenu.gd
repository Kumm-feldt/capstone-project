extends Control


func check_first_launch():
	var config = ConfigFile.new()

	if config.load("user://save.cfg") != OK:
		# Show new username scene
		get_tree().change_scene_to_file("res://scenes/NewUser/NewUser.tscn")
	else:
		GameManager.username = config.get_value("player", "username")
		GameManager.color = config.get_value("player", "color")
		GameManager.background_color = config.get_value("player", "background_color")
		get_tree().change_scene_to_file("res://scenes/GameMode/GameMode.tscn")

func _on_start_pressed() -> void:
	await check_first_launch() 
