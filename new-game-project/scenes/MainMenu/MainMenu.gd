extends Control

var is_config = true
var testing = false	# REMOVE FOR FINAL BUILD!! - Only here to skip intro animation

# Preload at the top of your script — loads the file once, reuses it
const POPUP_SCENE = preload("res://scenes/Settings/Settings.tscn")
# Track the instance so you can close it later
var active_popup: Control = null

@onready var music_slider = $Panel/ColorPicker/MusicSlider  # adjust path
@onready var sfx_slider = $Panel/ColorPicker/SFXSlider      # adjust path
@onready var off_panel = $off_panel

func _ready() -> void:
	if not GameManager.GAME_OPENED:	
		if not testing:
			await $MenuPanelScene.on_game_opened()
			GameManager.GAME_OPENED = true;
	print("not setted yet")
	check_first_launch() 
	apply_saved_audio()
	print("Everything setted")

func _on_any_button_pressed():
	Music.play_button_sound()
		
func check_first_launch():
	var config = ConfigFile.new()
	if config.load("user://save.cfg") != OK:
		# Show new username scene
		is_config = false
	else:
		GameManager.username = config.get_value("player", "username", "default")
		#GameManager.color = config.get_value("player", "color", "ffffff")
		GameManager.background_color = config.get_value("player", "background_color", "000000")
		GameManager.icon_color = config.get_value("player", "color", "ffffff")
		GameManager.profile_picture = config.get_value("player", "picture", "Derby")
		print("gamemanager is set!")

		
func apply_saved_audio():
	var config = ConfigFile.new()
	if config.load("user://save.cfg") == OK:
		var music_vol = config.get_value("audio", "music_volume", 1.0)
		var sfx_vol = config.get_value("audio", "sfx_volume", 1.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_vol))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_vol))
		
func _on_start_pressed() -> void:
	Music.play_button_sound()
	if is_config:
		get_tree().change_scene_to_file("res://scenes/GameMode/GameMode.tscn")
	else:
		# Show new username scene
		get_tree().change_scene_to_file("res://scenes/NewUser/NewUserScreen.tscn")


func _on_exit_button_pressed() -> void:
	Music.play_button_sound()
	get_tree().quit()

func _on_show_settings(instructions=false):
	if active_popup:
		return
	# Create the instance
	active_popup = POPUP_SCENE.instantiate()
	# Add it to the current scene as a child
	add_child(active_popup)
	# Center it on screen
	# Anchoring to full rect + centered is handled inside the popup scene itself
	# OR manually center it here:
	active_popup.position = (get_viewport().get_visible_rect().size / 2) - (active_popup.size / 2)
	if instructions == true:
		active_popup.get_node("Panel/InstructionsPanel").visible = true
		active_popup.get_node("Panel/SettingsPanel").visible = false
		active_popup.get_node("Panel/InstructionsPanel/BackButton").visible = false
		
		active_popup.get_node("Panel/TopTitleLabel").text = "Instructions"
	# Connect the popup's close button signal
	active_popup.get_node("Panel/ExitButton").pressed.connect(_close_popup)
	active_popup.get_node("Panel/CustomizePanel/ScrollContainer/VBoxContainer/AcceptButton").pressed.connect(_close_popup)
	
func _close_popup() -> void:
	toggle_light()
	if active_popup:
		active_popup.queue_free()
		active_popup = null
		
func _on_settings_button_pressed() -> void:
	toggle_light()
	
	Music.play_button_sound()
	_on_show_settings()

func _on_about_button_pressed() -> void:
	toggle_light()
	Music.play_button_sound()
	_on_show_settings(true)
	
func toggle_light():
	if off_panel.visible:
		off_panel.visible = false
	else:
		off_panel.visible = true
