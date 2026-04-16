extends Control

@onready var name_label = $Panel/NameLabel/LineEdit
@onready var email_label = $Panel/EmailLabel/LineEdit
@onready var event_label = $Panel/EventLabel/LineEdit
@onready var message_label = $Panel/ErrorMessageLabel

func _on_accept_button_pressed() -> void:
	# Trim leading/trailing spaces
	var name = name_label.text.strip_edges() 
	var email = email_label.text.strip_edges()  
	var event = event_label.text.strip_edges()
	
	if validate_input(name) and validate_input(email) and validate_input(event):
		SoftserveClient.ai_vs_ai(name, email, event)
		_show_error("Check email for link")
		get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
		

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

	# Optional: only allow letters, numbers, underscores
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9_]+$")
	if not regex.search(input):
		_show_error("Only letters, numbers, and underscores allowed.")
		return false
	return true
