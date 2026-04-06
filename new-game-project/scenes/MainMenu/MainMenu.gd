extends Control

var is_config = true

func _ready() -> void:
	await check_first_launch() 
	
func check_first_launch():
	var config = ConfigFile.new()
	if config.load("user://save.cfg") != OK:
		# Show new username scene
		is_config = false
	else:
		GameManager.username = config.get_value("player", "username", "default")
		GameManager.color = config.get_value("player", "color", "ffffff")
		GameManager.background_color = config.get_value("player", "background_color", "000000")
		

func _on_start_pressed() -> void:
	if is_config:
		get_tree().change_scene_to_file("res://scenes/GameMode/GameMode.tscn")
	else:
		# Show new username scene
		get_tree().change_scene_to_file("res://scenes/NewUser/NewUserScreen.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ColorPicker/ColorPicker.tscn")


func _on_about_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Instructions/GameInstructions.tscn")
	
