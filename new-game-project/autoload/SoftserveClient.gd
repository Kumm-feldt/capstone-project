extends Node

var SOFTSERVE_URL = "https://softserve.harding.edu"
var PLAYER_NAME = ""  # change if necessary
var PLAYER_EMAIL = "@harding.edu" # enter your email

# ai_vs_ai signals
signal error(error)
signal updateBoard(state)
signal ai_battle_move(boardString)


var EVENT_NAME = "" # event name will be given to you the day of the event
var TOKEN = ""
var _current_request = ""
var counter = 0
var AI_PLAYING = true

# ============================================
# AI Instance
# ============================================
@onready var http_request: HTTPRequest = $HTTPRequest
@onready var ai = $CreeperAI

func _ready():
	print("onready")
	# connect to client
	http_request.request_completed.connect(_on_request_completed)
	# get token
	get_token()
	# Now that we have our token, we can start the /aivai loop
	"""
	request_state_softserve():
		- starts the /aivai loop
		- request our AI for a move
		- submits the move to /aivai/submit-action
	"""
	
func ai_loop() -> void:
	await request_state_softserve()
	await get_tree().create_timer(0.2).timeout

# ============================================
# 1. GET TOKEN
# ============================================
# Try to load TOKEN from file, 
# if loaded correctly returns the content, 
# otherwise null
func load_token_from_file():
	var file = FileAccess.open("user://%s_token.txt" % PLAYER_NAME, FileAccess.READ)
	if not file:
		return null
	var content = file.get_as_text()
	if content.is_empty():
		return null   # treat empty file as no token
	return content
	
func save_to_file(content):
	var file = FileAccess.open("user://%s_token.txt" % PLAYER_NAME, FileAccess.WRITE)
	file.store_string(content)	

func get_token():
	TOKEN = load_token_from_file()
	if TOKEN == null:    
		_current_request = "player_create"
		var body = JSON.stringify({
			"name": PLAYER_NAME,
			"email": PLAYER_EMAIL
			})
		var headers = ["Content-Type: application/json"]
		var err = http_request.request(
		SOFTSERVE_URL + "/player/create",
		headers,
		HTTPClient.METHOD_POST,
		body
		)
		if err != OK:
			push_error("An error occurred in the HTTP request.")
			emit_signal("error", "An error occurred in the HTTP request.")
	else:
		ai_loop()
		
# ============================================
# 2. /aivai LOOP
# ============================================
func request_state_softserve():
	var body = JSON.stringify({
		"event": EVENT_NAME,
		"player": PLAYER_NAME,
		"token" : TOKEN})
	var headers = ["Content-Type: application/json"]
	_current_request = "request_state_softserve"
	
	var err = http_request.request(
		SOFTSERVE_URL+"/aivai/play-state",
		headers,
		HTTPClient.METHOD_POST, 
		body)
	
	if err != OK:
		push_error("An error occurred in the HTTP request.")
		emit_signal("error", "An error occurred in the HTTP request.")
		
func send_action_to_softserve(action, action_id):
	var body = JSON.stringify({
		"action": action,
		"action_id": action_id,
		"player": PLAYER_NAME,
		"token": TOKEN})
	var headers = ["Content-Type: application/json"]
	_current_request = "send_action_to_softserve"
	var err = http_request.request(
		SOFTSERVE_URL+"/aivai/submit-action",
		headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		push_error("An error occurred in the HTTP request.")
		emit_signal("error","An error occurred in the HTTP request.")

func _on_request_completed(result, response_code, headers, body):
		if result != HTTPRequest.RESULT_SUCCESS:
			push_error("HTTP transport failed. Result code: %d (see HTTPRequest.Result enum)" % result)
			emit_signal("error", "HTTP transport failed. Result code: %d (see HTTPRequest.Result enum)" % result)
			return
		var text = body.get_string_from_utf8()
		# --- player_create ---
		if _current_request == "player_create":
			if response_code != 200:
				push_error("player/create failed: %s" % response_code)
				emit_signal("error", "player/create failed: %s" % response_code)
				return
			var json = JSON.parse_string(text)
			if json == null:
				push_error("player/create: failed to parse JSON")
				emit_signal("error", "player/create: failed to parse JSON")
				return
			TOKEN = json["token"]
			save_to_file(TOKEN)
			ai_loop()

		# --- request_state_softserve ---
		elif _current_request == "request_state_softserve":
			print("request_state_softserve...")
			# ✅ Handle 204 BEFORE parsing — body is empty here
			if response_code == 204:
				await get_tree().create_timer(2).timeout
				print("code 204... trying again")
				await request_state_softserve()
				return

			var json = JSON.parse_string(text)
			if json == null:
				var error = "request_state: failed to parse JSON. Body was: " + text
				push_error(error)
				emit_signal("error", error)
				return

			var action_id = json["action_id"]
			var state = json["state"]
			var action = request_ai_action(state)
			#emit_signal("ai_battle_move", state)
			emit_signal("updateBoard", state)
			send_action_to_softserve(action, action_id)
			counter += 1

		# --- send_action_to_softserve ---
		elif _current_request == "send_action_to_softserve":
			if response_code != 200:
				print("submit-action failed: ", response_code)
				return
			var json = JSON.parse_string(text)
			if json == null:
				var error = "submit-action: failed to parse JSON. Body was: " + text
				push_error(error)
				emit_signal("error", error)
				return
			if json.has("winner"):
				if json["winner"] != "none":
					AI_PLAYING = false
					return
				await request_state_softserve()
			else:
				print("No 'winner' in response; treating as error.")
				AI_PLAYING = false

# ============================================
# REQUEST AI ACTION
# ============================================
func request_ai_action(state):	
	var action_str: String = ai.GetMove(state) 
	if action_str == null:
		print("ERROR obtaining move")
	return action_str
