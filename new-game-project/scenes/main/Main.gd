# scenes/main/Main.gd
# Attached to Main (Node2D) root node
extends Node2D
var win_screen_scene = preload("res://scenes/WinScreen.tscn")
#@onready var turn_label = $CanvasLayer/UI/TurnLabel
#@onready var debug_label = $CanvasLayer/UI/DebugLabel
#@onready var reset_button = $CanvasLayer/UI/ResetButton
@onready var userleftmessage = $UserLeftMessage
@onready var dim_overlay = $DimOverlay
@onready var game_theme: AudioStreamPlayer2D = $GameTheme
@onready var end_stinger: AudioStreamPlayer2D = $EndStinger

var WIN_POINTS = 100
var LOSS_POINTS = 30
var victory_stinger
var defeat_stinger

func _ready():
	# Connect to GameState
	dim_overlay.visible = false
	print("Connecting end_match... in _ready")
	GameState.connect("game_over", _on_game_over)
	NetworkManager.connect("end_match",on_match_ended )
	
	# signal to close the window
	NetworkManager.connect("ready_to_leave", _on_ready_to_leave)

	# load end stingers
	victory_stinger = preload("res://Sound/Music/stinger_victory_v2.wav")
	defeat_stinger = preload("res://Sound/Music/stinger_defeat_v2.wav")


	
func _on_ready_to_leave():
	# host asked for it
	get_tree().change_scene_to_file("res://scenes/GameMode/GameMode.tscn")
	
func _on_turn_changed(_player: String):
	"""Handle turn change"""

func _on_game_over(winner: String):
	print("_on_game_over: WINNER : ", winner)
	var canvas = CanvasLayer.new()
	canvas.layer = 10  # renders above everything
	get_tree().root.add_child(canvas)
	var win_screen = win_screen_scene.instantiate()
	canvas.add_child(win_screen)
	win_screen.set_anchors_preset(Control.PRESET_CENTER)
	win_screen.setup(winner)
	game_theme.stop()

	if (GameManager.GAME_MODE == GameManager.Mode.AI ):
		print("username: ", GameManager.username)
		DBService.update_user_info(GameManager.username, "add", WIN_POINTS)
		if (winner == "o"):
			end_stinger.stream = victory_stinger
			end_stinger.play()
		else:
			end_stinger.stream = defeat_stinger
			end_stinger.play()
	elif(GameManager.GAME_MODE == GameManager.Mode.Multiplayer):
		print("multi")
		# TODO: Learn how network play shows if you won and play the correct stinger
		end_stinger.stream = victory_stinger
		end_stinger.play()
	elif(GameManager.GAME_MODE == GameManager.Mode.Local):
		end_stinger.stream = victory_stinger
		end_stinger.play()


	
func _on_reset_pressed():
	"""Reset game button"""
	
func on_match_ended(username):
	print("3) end_match signal on Main.gd")
	print("message is suposse to show")
	userleftmessage.visible = true
	userleftmessage.get_node("UserLeftMessagePanel/Label").text = username + " left the match"
	
func _process(_delta):
	"""Debug display (remove for production)"""
	
