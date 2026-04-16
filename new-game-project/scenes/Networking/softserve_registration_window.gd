extends Control

@onready var name_label = $Panel/NameLabel/LineEdit
@onready var email_label = $Panel/EmailLabel/LineEdit
@onready var event_label = $Panel/EventLabel/LineEdit
@onready var message_label = $Panel/ErrorMessageLabel
@onready var checkbox = $Panel/showBoard/CheckButton
@onready var accept_button = $AcceptButton

var testing = false
func _ready() -> void:
	checkbox.button_pressed = false  # default: board visible


func _on_show_board_toggled(pressed: bool):
	GameManager.show_ai_tournament = pressed
	print("show ai: ", GameManager.show_ai_tournament)
	
func _on_accept_button_pressed() -> void:
	if testing:
		SoftserveClient.connect("ready_to_play", _on_ready_to_play, CONNECT_ONE_SHOT)
		SoftserveClient.ai_vs_ai("AnthonyTeam5", "akummerfeldt@harding.edu", "mirror")
	else:
		# Trim leading/trailing spaces
		var name = name_label.text.strip_edges() 
		var email = email_label.text.strip_edges()  
		var event = event_label.text.strip_edges()
		
		if validate_input(name) and validate_input(email) and validate_input(event):
			SoftserveClient.connect("ready_to_play", _on_ready_to_play, CONNECT_ONE_SHOT)
			SoftserveClient.ai_vs_ai(name, email, event)
		
func _on_ready_to_play():
	if checkbox.button_pressed:
		_show_error("showing board")
		get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
	else:
		_show_error("Game running in the background.")
		accept_button.visible = false
		
	
func _show_error(msg: String) -> void:
	message_label.visible = true
	message_label.text = msg

func validate_input(input: String) -> bool:
	# Empty check
	if input.length() == 0:
		_show_error("Username cannot be empty.")
		return false

	# Space check
	if " " in input:
		_show_error("Username cannot contain spaces.")
		return false

	return true
