extends Node

var SOFTSERVE_URL = "https://softserve.harding.edu"
var PLAYER_NAME = "aivai-demo-player-5"
var PLAYER_EMAIL = "akummerfeldt@harding.edu"

var EVENT_NAME = "mirror"
var token = ""
@onready var http_request = $"."

# ============================================
# 1. GET TOKEN
# ============================================
# Try to load token from file, 
# if loaded correctly returns the content, 
# otherwise null
func load_token_from_file():
	var file = FileAccess.open("./res://%s_token.txt" % PLAYER_NAME, FileAccess.READ)
	if not file:
		return null
	var content = file.get_as_text()
	return content
	
func save_to_file(content):
	var file = FileAccess.open("./res://%s_token.txt" % PLAYER_NAME, FileAccess.WRITE)
	file.store_string(content)	

func get_token():
	token = load_token_from_file()
	if token == null:
		var body = JSON.stringify({
			"name": PLAYER_NAME,
			"email": PLAYER_EMAIL
			})
		var _request = http_request.request(SOFTSERVE_URL + "/player/create", 
		body, HTTPClient.METHOD_GET)
		
		if _request != OK:
			push_error("An error occurred in the HTTP request.")
		
		token = JSON.parse_string(_request.get_string_from_utf8())
		
		# save token into file 
		save_to_file(token)
		
		token = token[0]
	print(token)
	
	
# ============================================
# 2. /aivai LOOP
# ============================================
func request_state_softserve():
	var body = JSON.stringify({
		"event": EVENT_NAME,
		"player": PLAYER_NAME})
		
	var _request = http_request.request(SOFTSERVE_URL+"/aivai/play-state",
	body, HTTPClient.METHOD_GET)
	
	if _request != OK:
		push_error("An error occurred in the HTTP request.")
	
	# Check for HTTP 204, which means that no games are currently
	# waiting for our player to move; try again in a few seconds
	if _request.get_http_client_status() == 204:
		# wait 2 seconds
		await get_tree().create_timer(2).timeout 
	var json = JSON.parse_string(_request.get_string_from_utf8())
	var state = json["state"]
	var action_id = json["action_id"]
	
	print("State: %s" %state)
	# call our AI
	# Send that action back to Softserve with /aivai/submit-action
	# https://softserve.harding.edu/docs#/aivai/aivai_submit_action_aivai_submit_action_post
	
	var action = request_ai_action()
	
	body = JSON.stringify({
		"action": action,
		"action_id": action_id,
		"player": PLAYER_NAME,
		"token": token})
	
	_request = http_request.request(SOFTSERVE_URL+"/aivai/submit-action",
	body, HTTPClient.METHOD_GET)
	
	if _request != OK:
		push_error("An error occurred in the HTTP request.")
		
		
# ============================================
# REQUEST AI ACTION
# ============================================
func request_ai_action():
	var action = "x.....x" # get action from AI
	return action
	
	
