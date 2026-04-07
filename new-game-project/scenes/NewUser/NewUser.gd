extends Control
@onready var username_input = $Panel/LineEdit
@onready var message_label = $Panel/MessageLabel

var http_check = HTTPRequest.new()
var http_register = HTTPRequest.new()

var default_color = "e83c84ff"
var default_background_color = "f0ebd8"


func _ready() -> void:
	add_child(http_check)
	add_child(http_register)
	http_check.request_completed.connect(_on_username_check_done)
	http_register.request_completed.connect(_on_register_done)

func check_username_exists(username):
	var url = DBService.URL + "?username=eq."+username +"&select=id"
	http_check.request(url, DBService.HEADERS, HTTPClient.METHOD_GET)

func _on_username_check_done(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
			push_error("HTTP transport failed. Result code: %d (see HTTPRequest.Result enum)" % result)
			emit_signal("error", "HTTP transport failed. Result code: %d (see HTTPRequest.Result enum)" % result)
			return
			
	var json = JSON.parse_string(body.get_string_from_utf8())

	if json.size() > 0:
		# Array is NOT empty, username is taken
		message_label.visible = true
		print("Taken")
	else:
		# Array is empty, username is available, proceed to register
		register_player(username_input.text)
		print("Ready to go to next scene...")

		

func register_player(username: String):
	var body = JSON.stringify({
		"username": username,
		"points": 0,
		"wins": 0,
		"losses": 0,
		"draws": 0
	})	
	
	var err = http_register.request(DBService.URL,
				DBService.HEADERS, HTTPClient.METHOD_POST, body)
				
	if err != OK:
		push_error("An error occurred in the HTTP request.")
		emit_signal("error", "An error occurred in the HTTP request.")
	

func _on_register_done(result, response_code, headers, body):
	var raw = body.get_string_from_utf8()
	print("Raw body: ", raw)  # <-- Add this to debug

	var response = JSON.parse_string(body.get_string_from_utf8())
	print("Response code: ", response_code)
	print("Response body: ", response)
	if response_code == 201:
		print("Successfully registered!")
		var config = ConfigFile.new()
		GameManager.username = username_input.text
		GameManager.color = default_color
		GameManager.background_color = default_background_color
		
		config.set_value("player", "username", username_input.text)
		config.set_value("player", "id", response[0]["id"])
		config.set_value("player", "color", default_color)
		config.set_value("player", "background_color", default_background_color)
		config.save("user://save.cfg")
		
		get_tree().change_scene_to_file("res://scenes/GameMode/GameMode.tscn")

	else:
		print("Failed. Code: ", response_code, " | Body: ", response)

func check_size(username):
	if username.length() > 10:
		message_label.visible = true
		message_label.text = "Username needs to be less\nthan 10 chars."
		return false
	else:
		return true

func _on_accept_button_pressed() -> void:
	# check if username is in DB, if not insert it
	if check_size(username_input.text):
		check_username_exists(username_input.text)
