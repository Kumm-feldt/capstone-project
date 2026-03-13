extends Control

@onready var username_input = $Panel/LineEdit

@onready var message_label = $Panel/MessageLabel
var ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVqbW9yYmx1aHpta2Vlc3hremhjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMzNDY3MzIsImV4cCI6MjA4ODkyMjczMn0.JEyjYV-xzy-wNOKMP-oR2YBfNDFGJu7HtKV1ptRJeHk"
var URL = "https://ujmorbluhzmkeesxkzhc.supabase.co/rest/v1/players"
var http_check = HTTPRequest.new()
var http_register = HTTPRequest.new()
var HEADERS = [
"Content-Type: application/json",
"apikey: "+ANON_KEY,
"Authorization: Bearer "+ANON_KEY,
"Prefer: return=representation"   # tells Supabase to return the new row
]

func _ready() -> void:
	add_child(http_check)
	add_child(http_register)
	http_check.request_completed.connect(_on_username_check_done)
	http_register.request_completed.connect(_on_register_done)

func check_username_exists(username):
	var url = URL + "?username=eq."+username +"&select=id"
	print("url prepared")
	http_check.request(url, HEADERS, HTTPClient.METHOD_GET)

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
	
	var err = http_register.request(URL,
				HEADERS, HTTPClient.METHOD_POST, body)
				
	if err != OK:
		push_error("An error occurred in the HTTP request.")
		emit_signal("error", "An error occurred in the HTTP request.")
	

func _on_register_done(result, response_code, headers, body):
	var response = JSON.parse_string(body.get_string_from_utf8())
	print("Response code: ", response_code)
	print("Response body: ", response)
	if response_code == 201:
		print("Successfully registered!")
		var config = ConfigFile.new()
		config.set_value("player", "username", username_input.text)
		config.set_value("player", "id", response[0]["id"])
		config.save("user://save.cfg")
		get_tree().change_scene_to_file("res://scenes/GameMode/GameMode.tscn")

	else:
		print("Failed. Code: ", response_code, " | Body: ", response)

func _on_accept_button_pressed() -> void:
	# check if username is in DB, if not insert it

	check_username_exists(username_input.text)

		
