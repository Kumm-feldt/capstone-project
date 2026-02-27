extends Node

var SOFTSERVE_URL = "https://softserve.harding.edu"
var PLAYER_NAME = "aivai-test-kummerfeldt-2"
var PLAYER_EMAIL = "akummerfeldt@harding.edu"

signal ai_battle_move(boardString)

var EVENT_NAME = "mirror"
var TOKEN = ""
var _current_request = ""
var counter = 0
var AI_PLAYING = true

# ============================================
# AI Instance
# ============================================
@onready var http_request: HTTPRequest = $HTTPRequest
@onready var ai = $CreeperAI

func ai_battle_start():
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

func _on_request_completed(result, response_code, headers, body):
	var text = body.get_string_from_utf8()
	var json = JSON.parse_string(text)
	#print("task: ", _current_request)
	if _current_request == "player_create":
		if response_code != 200:
			push_error("player/create failed: %s" % response_code)
			return
		TOKEN = json["token"]
		save_to_file(TOKEN)
		# Now you can start the aivai loop, e.g. request_state_softserve()
		ai_loop() 
	
	elif _current_request == "request_state_softserve":
		if response_code == 204:
			await get_tree().create_timer(2).timeout
			print("code 204... trying again")
			await request_state_softserve()
			return  # ← MUST return here, do not fall through

		# Only reach here if response_code != 204
		if json == null:
			push_error("Failed to parse JSON response")
			return

		var action_id = json["action_id"]
		var state = json["state"]
		var action = request_ai_action(state)
		emit_signal("ai_battle_move", state)
		await get_tree().create_timer(3).timeout
		send_action_to_softserve(action, action_id)
		counter += 1
	elif _current_request == "send_action_to_softserve":
		if response_code != 200:
			print("submit‑action failed: ", response_code)
			return
		if json.has("winner"):
			if json["winner"] != "none":
				AI_PLAYING = false
				return
			elif json["winner"] in ["h", "t", "draw"]:
				print("Winner: ", json["winner"])
				AI_PLAYING = false
				return
				
			await request_state_softserve()
			
		else:
			print("No 'winner' in response; treating as error.")
			AI_PLAYING = false
			return
		

# ============================================
# REQUEST AI ACTION
# ============================================
func request_ai_action(state):	
	var action_str: String = ai.GetMove(state) 
	if action_str == null:
		print("ERROR obtaining move")
	return action_str
