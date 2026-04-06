extends Control


@onready var music_slider = $Panel/VBoxContainer/HBoxContainer/MusicSlider
@onready var sfx_slider = $Panel/VBoxContainer/HBoxContainer2/SFXSlider
@onready var back_button = $Panel/VBoxContainer/BackButton


const SAVE_PATH = "user://save.cfg"


func _ready():
	back_button.pressed.connect(_on_back_pressed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	
	# Slider setup
	music_slider.min_value = 0
	music_slider.max_value = 1
	music_slider.step = 0.01
	sfx_slider.min_value = 0
	sfx_slider.max_value = 1
	sfx_slider.step = 0.01
	
	# Load saved values
	load_settings()
	
func load_settings():
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		music_slider.value = config.get_value("audio", "music_volume", 1.0)
		sfx_slider.value = config.get_value("audio", "sfx_volume", 1.0)
	else:
		music_slider.value = 1.0
		sfx_slider.value = 1.0

func save_settings():
	var config = ConfigFile.new()
	config.load(SAVE_PATH)  # load existing so we dont overwrite player data
	config.set_value("audio", "music_volume", music_slider.value)
	config.set_value("audio", "sfx_volume", sfx_slider.value)
	config.save(SAVE_PATH)
	
	
func _on_music_changed(value: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))
	save_settings()

func _on_sfx_changed(value: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))
	save_settings()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu/MainMenu.tscn")
