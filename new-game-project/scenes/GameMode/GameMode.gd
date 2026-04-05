extends Control

@onready var dim_overlay = $DimOverlay
@onready var ai_mode_popup = $AIOptionPopup   # or use preload if it's a separate scene
@onready var ai_mode_button = $Buttons/AIModeButton
@onready var online_mode_popup = $OnlineOptionPopup
@onready var back_button = $Buttons/BackButton
@onready var light_button = $BlinkLight
@onready var off_panel = $off_panel

var colorScreenScene = load("res://scenes/ColorPicker/ColorSelectionScreen.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dim_overlay.visible = false
	ai_mode_popup.visible = false
	online_mode_popup.visible = false
	light_button.turn_off_light.connect(_on_turn_off_light)


func _on_turn_off_light():
	if off_panel.visible:
		off_panel.visible = false
	else:
		off_panel.visible = true
	
	
func _on_ai_mode_button_pressed() -> void:
	dim_overlay.visible = true
	ai_mode_popup.visible = true
	# Connect the signal if not already connected
	if not ai_mode_popup.popup_closed.is_connected(_on_popup_closed):
		ai_mode_popup.popup_closed.connect(_on_popup_closed)

func _on_popup_closed():
	ai_mode_popup.visible = false
	online_mode_popup.visible = false
	dim_overlay.visible = false
	
	
func _on_online_mode_pressed() -> void:
	dim_overlay.visible = true
	online_mode_popup.visible = true
	GameManager.GAME_MODE = GameManager.Mode.Multiplayer
	# Connect the signal if not already connected
	if not online_mode_popup.popup_closed.is_connected(_on_popup_closed):
		online_mode_popup.popup_closed.connect(_on_popup_closed)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu/MainMenu.tscn")


func _on_local_play_mode_button_pressed() -> void:
	GameManager.GAME_MODE = GameManager.Mode.Local
	
	var colorScreen = colorScreenScene.instantiate()
	colorScreen.setGamemode("Local")
	
	var root = get_tree().root
	var current = get_tree().current_scene
	current.queue_free()
	
	get_tree().root.add_child(colorScreen)
	get_tree().current_scene = colorScreen
	
	# Below method is from before the colorScreen was added.
	#get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
	

func _on_ai_tournament_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/AI/a_ivs_ai_console.tscn")
	# call to softserve activator
	pass
