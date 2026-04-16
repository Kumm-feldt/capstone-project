extends CanvasLayer
const WinScreen = preload("res://scenes/WinScreen.tscn")
@onready var turn_label = $PanelContainer/Control/TurnLabel
@onready var invalid_label = $PanelContainer/Control/InvalidaLabel
@onready var pause_button = $PanelContainer/Control/PauseButton
@onready var pause_menu = $"/root/Main/PauseMenu"

@onready var led1 = $PanelContainer/LED1
@onready var led2 = $PanelContainer/LED2
@onready var led3 = $PanelContainer/LED3

@onready var player_icon = $PlayerIcon


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
	
	# do not show on tournament
	if GameManager.TOURNAMENT:
		return
		
	# default text in banner
	var player 
	if GameManager.GAME_MODE == GameManager.Mode.Multiplayer:
		# if it is hosting, special case
		if GameManager.hosting:
			player = GameManager.multiplayer_username+"'s"
			player_icon.setIcon(GameManager.multiplayer_icon, GameManager.player2_color)
		else:
			player = "Your"
			player_icon.setIcon(GameManager.profile_picture, GameManager.player1_color)
			
	elif GameManager.GAME_MODE == GameManager.Mode.AI:
		player = "Your"
		player_icon.setIcon(GameManager.profile_picture, GameManager.player1_color)

	elif GameManager.GAME_MODE == GameManager.Mode.Local:
		player = "Player 1" 
		player_icon.setIcon(GameManager.profile_picture, GameManager.player1_color)

	turn_label.text = "%s\nTurn" % player

func _on_pause_button_pressed():
	Music.play_button_sound()
	GameState.toggle_pause()

func _on_pause_changed(is_paused: bool):
	#pause_button.text = "Resume" if is_paused else "Pause"
	if is_paused:
		pause_menu.show()
	else:
		pause_menu.hide()

func _on_turn_changed(player):
	# do not show on tournament
	if GameManager.TOURNAMENT:
		return
		
	var player_color 
	if GameManager.GAME_MODE == GameManager.Mode.Multiplayer:
		# fall backs 
		if not GameManager.multiplayer_username:
			GameManager.multiplayer_username = "unknown"
		if not GameManager.username:
			GameManager.username = "my name"
			
		# if it is hosting, special case
		if GameManager.hosting:
			if player == "x":
				player_color = "Your"
				player_icon.setIcon(GameManager.profile_picture, GameManager.player1_color)
			else:
				player_color = GameManager.multiplayer_username +"'s"
				if GameManager.multiplayer_icon == null:
					GameManager.multiplayer_icon = "Happy"
				player_icon.setIcon(GameManager.multiplayer_icon, GameManager.player2_color)
		else:
			if player == 'x':
				player_color = GameManager.multiplayer_username+"'s"
				if GameManager.multiplayer_icon == null:
					GameManager.multiplayer_icon = "Happy"
				player_icon.setIcon(GameManager.multiplayer_icon, GameManager.player2_color)
			else:
				player_color = "Your"
				player_icon.setIcon(GameManager.profile_picture, GameManager.player1_color)

	elif GameManager.GAME_MODE == GameManager.Mode.AI:
		await get_tree().create_timer(1.5).timeout
		if player == 'o':
			player_color = "Your"
			player_icon.setIcon(GameManager.profile_picture, GameManager.player1_color)
		else:
			player_color = "CPU"
			# change to a presetted picture
			player_icon.setIcon(GameManager.ai_icon, GameManager.player2_color)
	elif GameManager.GAME_MODE == GameManager.Mode.Local:
		if player == 'o':
			player_color = "Player 1" 
			player_icon.setIcon(GameManager.profile_picture, GameManager.player1_color)
		else:
			player_color =  "Player 2"
			player_icon.setIcon(GameManager.profile_picture, GameManager.player2_color)

	turn_label.text = "%s\nTurn" % player_color

func _on_invalid_move(text):
	invalid_label.text = text

func _on_valid_move():
	invalid_label.text = ""
	
