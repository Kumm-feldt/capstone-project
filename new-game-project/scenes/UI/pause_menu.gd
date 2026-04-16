extends CanvasLayer
@onready var resume_button = $Panel/MarginContainer/VBoxContainer/ResumeButton
@onready var quit_button = $Panel/MarginContainer/VBoxContainer/QuitButton
@onready var quit_message = $QuitGameMessage
@onready var pause_menu = $Panel

# Preload at the top of your script — loads the file once, reuses it
const POPUP_SCENE = preload("res://scenes/Settings/Settings.tscn")
var canvas = null

func _ready():
	
	resume_button.pressed.connect(_on_resume)
	quit_button.pressed.connect(_on_quit)
	quit_message.resume_match.connect(_on_resume_match)

func _on_resume_match():
	# hide everything
	resume_button.pressed.connect(_on_resume)
	GameState.unpause_game()
	quit_message.visible = false
	pause_menu.visible = true
	hide()
	

func _on_resume():
	GameState.unpause_game()
	hide()

func _on_quit():
	# show message
	quit_message.visible = true
	pause_menu.visible = false
	


func _on_win_button_pressed() -> void:
	Music.play_button_sound()
	hide()
	if GameManager.Mode.Local or GameManager.Mode.AI:
		GameState.force_game_over("o")
	elif GameManager.Mode.Multiplayer:
		if multiplayer.is_server():
			GameState.force_game_over("x")
		else:
			GameState.force_game_over("o")
			
func _on_lose_button_pressed() -> void:
	Music.play_button_sound()
	hide()
	if GameManager.Mode.Local or GameManager.Mode.AI:
		GameState.force_game_over("x")
	elif GameManager.Mode.Multiplayer:
		if multiplayer.is_server():
			GameState.force_game_over("o")
		else:
			GameState.force_game_over("x")

func _on_close_instructions():
	if canvas and is_instance_valid(canvas):
		canvas.queue_free()
		canvas = null
	# Restore pause menu
	pause_menu.visible = true
	show()
	GameState.pause_game()

	
func _on_instructions_button_pressed() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 100
	get_tree().root.add_child(canvas)
	
	var settings_scene = POPUP_SCENE.instantiate()
	settings_scene.close_instructions.connect(_on_close_instructions)
	canvas.add_child(settings_scene)

	# Pass the canvas reference so the scene can clean itself up
	settings_scene.setup(canvas)

	settings_scene._on_instructions_button_pressed()
	GameState.unpause_game()
	hide()

	
