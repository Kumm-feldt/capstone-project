extends Control

@onready var winner_label = $Panel/MarginContainer/VBoxContainer/WinnerLabel
@onready var play_again_button = $Panel/MarginContainer/VBoxContainer/PlayAgainButton
@onready var main_menu_button = $Panel/MarginContainer/VBoxContainer/MainMenuButton
@onready var quit_button = $Panel/MarginContainer/VBoxContainer/QuitButton

var winner = "undefined"

const menu_panel_scene = preload("res://scenes/MainMenu/menu_panel.tscn")

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	if GameManager.Mode.Multiplayer == GameManager.GAME_MODE:
		play_again_button.visible = false
	play_again_button.pressed.connect(_on_play_again)
	main_menu_button.pressed.connect(_on_main_menu)
	quit_button.pressed.connect(_on_quit)
	
func setup(player: String):
	if GameManager.GAME_MODE == GameManager.Mode.Multiplayer:
		# fall backs 
		if not GameManager.multiplayer_username:
			GameManager.multiplayer_username = "unknown"
		if not GameManager.username:
			GameManager.username = "my name"
		# if it is hosting, special case
		if GameManager.hosting:
			# Host is always "x", Guest is always "o"
			if player == "x":
				set_winner(GameManager.username)          # host (you) won
			elif player == "o":
				set_winner(GameManager.multiplayer_username)  # guest won
			else:
				set_winner("draw")
		else:
			# Guest is "o", Host is "x"
			if player == 'o':
				set_winner(GameManager.username)          # guest (you) won
			elif player == 'x':
				set_winner(GameManager.multiplayer_username)  # host won
			else:
				set_winner("draw")

	elif GameManager.GAME_MODE == GameManager.Mode.AI:
		winner = "You Won!" if player == 'o' else "CPU Wins!"
	else:
		winner = "Player 1\nWins!" if player == 'o' else "Player 2\nWins!"
	winner_label.text = winner

func _on_play_again():

	hide()
	# show loading scene...
	var canvas = CanvasLayer.new()
	canvas.layer = 100  # on top of everything
	get_tree().root.add_child(canvas)
	
	var menu_panel = menu_panel_scene.instantiate()
	canvas.add_child(menu_panel)
	
	menu_panel.toggleLoadingScreen()
	await get_tree().create_timer(1).timeout

	# reset game and change scene to show game
	GameState.reset_game()
	menu_panel.queue_free()
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")  

func _on_main_menu():
	hide()
	GameState.reset_game()
	get_tree().change_scene_to_file("res://scenes/GameMode/GameMode.tscn")  # adjust to your main menu path
	
	if multiplayer.is_server():
		await NetworkManager.stop_hosting()
	else:
		await NetworkManager.stop_searching()
		
func _on_quit():
	GameState.reset_game()
	if multiplayer.is_server():
		await NetworkManager.stop_hosting()
	else:
		await NetworkManager.stop_searching()
	hide()
	# show loading scene...
	var canvas = CanvasLayer.new()
	canvas.layer = 100  # on top of everything
	get_tree().root.add_child(canvas)
	
	var menu_panel = menu_panel_scene.instantiate()
	canvas.add_child(menu_panel)
	
	menu_panel.toggleLoadingScreen()
	await get_tree().create_timer(1).timeout

	# reset game and change scene to show game
	GameState.reset_game()
	menu_panel.queue_free()
	get_tree().change_scene_to_file("res://scenes/MainMenu/MainMenu.tscn")  # adjust to your main menu path

func add_points(user):
	DBService.update_user_info(user, "add", GameManager.WIN_POINTS)
	
func reduce_points(user):
	DBService.update_user_info(user, "reduce", GameManager.LOSE_POINTS)

func set_winner(user):
	#quit_game()
	print("MULTIPLAYER GAMEMANAGER ", GameManager.multiplayer_username)
	if user == GameManager.username:
		winner = "You Won!" 
		print("set winner: ", user, " - add points to: ", GameManager.username)
		GameManager.winner = GameManager.username
	elif user == GameManager.multiplayer_username:
		print("set winner: ", user, " - add points to: ", GameManager.multiplayer_username)
		winner = GameManager.multiplayer_username+"\nWins!" 
		GameManager.winner = GameManager.multiplayer_username
	else:
		print("Draw")
		winner = "Draw!" 
		GameManager.winner = "Draw"
	
	# Only the host writes to DB — client just shows the result
	if multiplayer.is_server():
		_award_points()
		
func _award_points():
	if GameManager.winner == GameManager.username:
		add_points(GameManager.username)
		reduce_points(GameManager.multiplayer_username)
	elif GameManager.winner == GameManager.multiplayer_username:
		add_points(GameManager.multiplayer_username)
		reduce_points(GameManager.username)


	
