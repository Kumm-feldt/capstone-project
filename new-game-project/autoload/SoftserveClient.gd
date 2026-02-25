extends Node

var SOFTSERVE_URL = "https://softserve.harding.edu"
var PLAYER_NAME = "aivai-demo-player-5"
var PLAYER_EMAIL = "akummerfeldt@harding.edu"

var EVENT_NAME = "mirror"
var TOKEN = ""
var _current_request = ""

# ============================================
# AI Instance
# ============================================
@onready var http_request: HTTPRequest = $HTTPRequest
@onready var ai = $CreeperAI  # C# node

func _ready():
	print("Hello... from softserve")
	# connect to client
	http_request.request_completed.connect(_on_request_completed)
	# get token
	get_token()
	# Now that we have our token, we can start the /aivai loop
	#request_state_softserve()
	
	

# ============================================
# 1. GET TOKEN
# ============================================
# Try to load TOKEN from file, 
# if loaded correctly returns the content, 
# otherwise null
func load_TOKEN_from_file():
	print("loading TOKEN...")
	var file = FileAccess.open("user://%s_TOKEN.txt" % PLAYER_NAME, FileAccess.READ)
	if not file:
		print("Not file...")
		return null
	var content = file.get_as_text()
	return content
	
func save_to_file(content):
	print("save_to_file")
	var file = FileAccess.open("user://%s_TOKEN.txt" % PLAYER_NAME, FileAccess.WRITE)
	file.store_string(content)	

func get_token():
	TOKEN = load_TOKEN_from_file()
	if TOKEN == null:    
		print("TOKEN == null")
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
	print(ProjectSettings.globalize_path("user://"))
		
# ============================================
# 2. /aivai LOOP
# ============================================
func request_state_softserve():
	var body = JSON.stringify({
		"event": EVENT_NAME,
		"player": PLAYER_NAME,
		"TOKEN" : TOKEN})
	var headers = ["Content-Type: application/json"]
	_current_request = "request_state_softserve"
	
	var err = http_request.request(
		SOFTSERVE_URL+"/aivai/play-state",
		headers,
		HTTPClient.METHOD_POST, 
		body)
	
	if err != OK:
		push_error("An error occurred in the HTTP request.")
	
	# call our AI
	# Send that action back to Softserve with /aivai/submit-action
	# https://softserve.harding.edu/docs#/aivai/aivai_submit_action_aivai_submit_action_post
	

	

func send_action_to_softserve(action, action_id):
	var body = JSON.stringify({
		"action": action,
		"actionid": action_id,
		"player": PLAYER_NAME,
		"TOKEN": TOKEN})
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

	if _current_request == "player_create":
		if response_code != 200:
			push_error("player/create failed: %s" % response_code)
			return
		TOKEN = json["TOKEN"]
		save_to_file(TOKEN)
		print("Got TOKEN: ", TOKEN)
		# Now you can start the aivai loop, e.g. request_state_softserve()
	
	if _current_request == "request_state_softserve":
		# Check for HTTP 204, which means that no games are currently
		# waiting for our player to move; try again in a few seconds
		if response_code == 204:
			# wait 2 seconds
			await get_tree().create_timer(2).timeout 
			print("code 204... trying again")
			request_state_softserve()
			return
		else:
			var action_id = json["action_id"]
			var state = json["state"]
			var action = request_ai_action(state) # Get the next move from Slither AI
			send_action_to_softserve(action, action_id) # send the action to SoftServe
			
	if _current_request == "send_action_to_softserve":
		#GameState.move_pin(state, GameState.current_player)
		request_state_softserve()
		
		

# ============================================
# REQUEST AI ACTION
# ============================================
func request_ai_action(state):	
	var action_str: String = ai.GetMove(state)  
	if action_str == null:
		print("ERROR obtaining move")
		
	return action_str

	
