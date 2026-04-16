# scenes/main/Main.gd
# Attached to Main (Node2D) root node
extends Node2D
var win_screen_scene = preload("res://scenes/WinScreen.tscn")
var lose_screen_scene = preload("res://scenes/WinScreen.tscn")

#@onready var turn_label = $CanvasLayer/UI/TurnLabel
#@onready var debug_label = $CanvasLayer/UI/DebugLabel
#@onready var reset_button = $CanvasLayer/UI/ResetButton
@onready var userleftmessage = $UserLeftMessage
@onready var dim_overlay = $DimOverlay
@onready var board = $Board

func _ready():
	GameState.reset_game()
	# Connect to GameState
	dim_overlay.visible = false
	GameState.connect("game_over", _on_game_over)
	NetworkManager.connect("end_match",on_match_ended )
	# signal to close the window
	NetworkManager.connect("ready_to_leave", _on_ready_to_leave)
	# signal to change current track
	Music.play_track(GameManager.TrackMode.Match)

	
func _on_ready_to_leave():
	# host asked for it
	get_tree().change_scene_to_file("res://scenes/GameMode/GameMode.tscn")
	Music.play_track(GameManager.TrackMode.Default)

func _on_game_over(winner: String):
	winEffects(winner);
	print("winner: ", GameManager.winner)
	if GameManager.winner != GameManager.username:
		print("---- WE LOST ----, do i know?")
	else:
		print("---- WE WON ----, do i know?")
		
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	get_tree().root.add_child(canvas)
	
	var win_screen = win_screen_scene.instantiate()
	var lose_screen = lose_screen_scene.instantiate()
	
	canvas.add_child(win_screen)
	win_screen.set_anchors_preset(Control.PRESET_CENTER)
	win_screen.setup(winner)
	
	# Wait one frame so the panel's size is calculated before we move it
	await get_tree().process_frame
	var screen_width = get_viewport().get_visible_rect().size.x
	# Start fully off-screen to the right
	win_screen.position.x = screen_width
	# Tween it to its anchor position (x = 0 when using PRESET_CENTER)
	var tween = create_tween()
	tween.tween_property(
		win_screen,
		"position:x",
		850,
		1.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	if (GameManager.GAME_MODE == GameManager.Mode.AI ):
		if (winner == "o"):
			Music.play_track(GameManager.TrackMode.Victory)
		else:
			Music.play_track(GameManager.TrackMode.Defeat)
	elif(GameManager.GAME_MODE == GameManager.Mode.Multiplayer):
		# TODO: Learn how network play shows if you won and play the correct stinger
		Music.play_track(GameManager.TrackMode.Victory)
	elif(GameManager.GAME_MODE == GameManager.Mode.Local):
		Music.play_track(GameManager.TrackMode.Victory)
		

func winEffects(winner:String) -> void:
	board.winningPinsRejoice(winner);
	# TODO: win animation
	pass

	
func on_match_ended(username):
	userleftmessage.visible = true
	userleftmessage.get_node("UserLeftMessagePanel/Label").text = username + " left the match"
