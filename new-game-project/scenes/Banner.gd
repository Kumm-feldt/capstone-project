extends CanvasLayer
const WinScreen = preload("res://scenes/WinScreen.tscn")
@onready var turn_label = $PanelContainer/Control/TurnLabel
@onready var invalid_label = $PanelContainer/Control/InvalidaLabel
@onready var pause_button = $PanelContainer/Control/PauseButton
@onready var pause_menu = $"/root/Main/PauseMenu"

@onready var led1 = $PanelContainer/LED1
@onready var led2 = $PanelContainer/LED2
@onready var led3 = $PanelContainer/LED3

var current = 0
var leds = []
var colors = [Color.RED, Color.GREEN, Color.BLUE]
func _on_timer_timeout():
	current = (current + 1) % leds.size()
	_update_leds()

func _update_leds():
	for i in leds.size():
		leds[i].modulate = colors[i] if i == current else Color(0.89, 0.871, 0.0, 0.4)

		
func _ready() -> void:
	leds = [led1, led2, led3]
	$Timer.wait_time = 0.4
	$Timer.start()
	_update_leds()
	GameState.connect("turn_changed", _on_turn_changed)
	GameState.connect("invalid_move", _on_invalid_move)
	GameState.connect("valid_move", _on_valid_move)
	GameState.connect("game_paused_changed", _on_pause_changed)
	pause_button.pressed.connect(_on_pause_button_pressed)
	# default text in banner
	var player 
	if GameManager.GAME_MODE == GameManager.Mode.Multiplayer:
		# if it is hosting, special case
		if GameManager.hosting:
			player = "Your"
		else:
			player = GameManager.multiplayer_username+"'s"
	elif GameManager.GAME_MODE == GameManager.Mode.AI:
		player = "Your"
	elif GameManager.GAME_MODE == GameManager.Mode.Local:
		player = "Player 1" 
	turn_label.text = "%s\nTurn" % player

func _on_pause_button_pressed():
	GameState.toggle_pause()

func _on_pause_changed(is_paused: bool):
	#pause_button.text = "Resume" if is_paused else "Pause"
	if is_paused:
		pause_menu.show()
	else:
		pause_menu.hide()

func _on_turn_changed(player):
	var player_color 
	if GameManager.GAME_MODE == GameManager.Mode.Multiplayer:
		# fall backs 
		if not GameManager.multiplayer_username:
			GameManager.multiplayer_username = "unknown"
		if not GameManager.username:
			GameManager.username = "my name"
		# if it is hosting, special case
		if GameManager.hosting:
			player_color = "Your" if player == "x" else GameManager.multiplayer_username +"'s"
		else:
			player_color = GameManager.multiplayer_username+"'s" if player == 'x' else "Your"
	elif GameManager.GAME_MODE == GameManager.Mode.AI:
		player_color = "Your" if player == 'x' else "CPU"
	elif GameManager.GAME_MODE == GameManager.Mode.Local:
		player_color = "Player 1" if player == 'o' else "Player 2"
	turn_label.text = "%s\nTurn" % player_color

func _on_invalid_move(text):
	invalid_label.text = text

func _on_valid_move():
	invalid_label.text = ""
	
