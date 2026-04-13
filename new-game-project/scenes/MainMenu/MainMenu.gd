extends Control

var is_config = true
var testing = true	# REMOVE FOR FINAL BUILD!! - Only here to skip intro animation

func _ready() -> void:
	if not GameManager.GAME_OPENED:	
		if not testing:
			await $MenuPanelScene.on_game_opened()
			GameManager.GAME_OPENED = true;
	
	await check_first_launch() 
	apply_saved_audio()
@onready var music_slider = $Panel/ColorPicker/MusicSlider  # adjust path
@onready var sfx_slider = $Panel/ColorPicker/SFXSlider      # adjust path
	
func check_first_launch():
	var config = ConfigFile.new()
	if config.load("user://save.cfg") != OK:
		# Show new username scene
		is_config = false
	else:
		GameManager.username = config.get_value("player", "username", "default")
		GameManager.color = config.get_value("player", "color", "ffffff")
		GameManager.background_color = config.get_value("player", "background_color", "000000")
		
func apply_saved_audio():
	var config = ConfigFile.new()
	if config.load("user://save.cfg") == OK:
		var music_vol = config.get_value("audio", "music_volume", 1.0)
		var sfx_vol = config.get_value("audio", "sfx_volume", 1.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_vol))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_vol))
		
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
	
