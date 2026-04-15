extends Control

@onready var ai_mode_popup = $AIOptionPopup   # or use preload if it's a separate scene
@onready var ai_mode_button = $Buttons/AIModeButton
@onready var online_mode_popup = $OnlineOptionPopup
@onready var back_button = $Buttons/BackButton
@onready var light_button = $BlinkLight
@onready var off_panel = $off_panel
@onready var options = $points_received
@onready var profile_tab = $Profile


# Preload at the top of your script — loads the file once, reuses it
const POPUP_SCENE = preload("res://scenes/Settings/Settings.tscn")
const POPUP_SCENE_WARNING = preload("res://scenes/Profile/LogoutWarningWindow.tscn")


# Track the instance so you can close it later
var active_popup: Control = null
var active_popup_warning: Control = null


var colorScreenScene = load("res://scenes/ColorPicker/ColorSelectionScreen.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ai_mode_popup.visible = false
	online_mode_popup.visible = false
	light_button.turn_off_light.connect(_on_turn_off_light)
	options.show_settings.connect(_on_show_settings)
	options.logout_message.connect(_on_logout_message)
	profile_tab.set_icon()
	if not Music.is_playing_track(GameManager.TrackMode.Default):
		Music.play_track(GameManager.TrackMode.Default)
	#const Transition = preload("res://scenes/Transition.tscn")
func _on_logout_message():
	toggle_light()
	if active_popup_warning:
		return
	# Create the instance
	active_popup_warning = POPUP_SCENE_WARNING.instantiate()
	# Add it to the current scene as a child
	add_child(active_popup_warning)
	# Center it on screen
	active_popup_warning.position = (get_viewport().get_visible_rect().size / 2) - (active_popup_warning.size / 2)
	
	# Connect the popup's close button signal
	active_popup_warning.get_node("Panel/ExitButton").pressed.connect(_close_pop_up_warning)
	active_popup_warning.get_node("Panel/AcceptButton").pressed.connect(_close_pop_up_warning)
	
func _on_show_settings():
	toggle_light()
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
	
	# Connect the popup's close button signal
	active_popup.get_node("Panel/ExitButton").pressed.connect(_close_popup)
	active_popup.get_node("Panel/CustomizePanel/ScrollContainer/VBoxContainer/AcceptButton").pressed.connect(_close_popup)
	
func _close_popup() -> void:
	if active_popup:
		toggle_light()
		
		active_popup.queue_free()
		active_popup = null
		
func _close_pop_up_warning()-> void:
	if active_popup_warning:
		toggle_light()
		active_popup_warning.queue_free()
		active_popup_warning = null
		
		
func _on_turn_off_light():
	if off_panel.visible:
		off_panel.visible = false
	else:
		off_panel.visible = true
	
func toggle_light():
	if off_panel.visible:
		off_panel.visible = false
	else:
		off_panel.visible = true
	
func _on_ai_mode_button_pressed() -> void:
	toggle_light()
	ai_mode_popup.visible = true
	# Connect the signal if not already connected
	if not ai_mode_popup.popup_closed.is_connected(_on_popup_closed):
		ai_mode_popup.popup_closed.connect(_on_popup_closed)

func _on_popup_closed():
	ai_mode_popup.visible = false
	online_mode_popup.visible = false
	toggle_light()
	
func _on_online_mode_pressed() -> void:
	toggle_light()
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
	#var transition = Transition.instantiate()
	#get_tree().root.add_child(transition)
	#transition.play_open("res://Board/Game.tscn")
	# Below method is from before the colorScreen was added.
	#get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
	

func _on_ai_tournament_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/AI/a_ivs_ai_console.tscn")
	# call to softserve activator
	pass
