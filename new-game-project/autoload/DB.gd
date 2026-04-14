extends Node
var ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVqbW9yYmx1aHpta2Vlc3hremhjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMzNDY3MzIsImV4cCI6MjA4ODkyMjczMn0.JEyjYV-xzy-wNOKMP-oR2YBfNDFGJu7HtKV1ptRJeHk"
var URL = "https://ujmorbluhzmkeesxkzhc.supabase.co/rest/v1/players"

var HEADERS = [
"Content-Type: application/json",
"apikey: "+ANON_KEY,
"Authorization: Bearer "+ANON_KEY,
"Prefer: return=representation"   # tells Supabase to return the new row
]

var http_check_points = HTTPRequest.new() 
var http_check = HTTPRequest.new()
var http_patch = HTTPRequest.new()
var http_update_player = HTTPRequest.new()


var points = 0
var losses = 0
var draws = 0
var wins = 0

var pending_username
var pending_points
var pending_action

signal points_received
signal player_updated

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(http_check) 
	add_child(http_patch) 
	add_child(http_check_points)
	add_child(http_update_player)
	http_update_player.request_completed.connect(_on_update_player_done)
	http_check_points.request_completed.connect(_on_check_points_done)
	http_patch.request_completed.connect(_on_update_points_done)
	http_check.request_completed.connect(on_update_user_info)

func _on_update_player_done(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("HTTP transport failed. Result code: %d (see HTTPRequest.Result enum)" % result)
		emit_signal("error", "HTTP transport failed. Result code: %d (see HTTPRequest.Result enum)" % result)
		return
	emit_signal("player_updated")  # Notify listeners
	
func update_player_colors(username, color, background_color, picture):
	var body = JSON.stringify({
		"color":color,
		"background": background_color,
		"picture": picture
	})	
	var url = URL + "?username=eq."+username 
	http_update_player.request(url, DBService.HEADERS, HTTPClient.METHOD_PATCH, body)
	
func update_user_info(username, action, points_):
	print("udpated_user_info - started")
	pending_username = username
	pending_points = points_
	pending_action = action
	
	var url = URL + "?username=eq."+username 
	http_check.request(url, DBService.HEADERS, HTTPClient.METHOD_GET)
	
func check_points(username):
	var url = URL + "?username=eq."+username 
	http_check_points.request(url, DBService.HEADERS, HTTPClient.METHOD_GET)
	
func _on_check_points_done(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("HTTP transport failed. Result code: %d (see HTTPRequest.Result enum)" % result)
		emit_signal("error", "HTTP transport failed. Result code: %d (see HTTPRequest.Result enum)" % result)
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	print(data)
	var points_username = data[0]["points"]
	GameManager.current_score = points_username
	GameManager.background_color = data[0]["background"] 
	GameManager.icon_color = data[0]["color"]
	GameManager.profile_picture = data[0]["picture"] 
	
	emit_signal("points_received", points_username)  # Notify listeners
	
	
	
func on_update_user_info(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
			push_error("HTTP transport failed. Result code: %d (see HTTPRequest.Result enum)" % result)
			emit_signal("error", "HTTP transport failed. Result code: %d (see HTTPRequest.Result enum)" % result)
			return
	var data = JSON.parse_string(body.get_string_from_utf8())[0]
	points = data["points"]
	wins = data["wins"]
	losses = data["losses"]
	draws = data["draws"]
	update_points()
	
	
# we are sure that the user is sending the right amount of points to be >= 0
func update_points():
	var statement 
	var value
	var upd_points = 0
	if pending_action == "reduce":
		upd_points = points - pending_points
		statement = "losses"
		value = losses +1
 
	elif pending_action == "add":
		upd_points = points + pending_points 
		statement = "wins"
		value = wins +1
		
	else:
		upd_points = points 
		statement = "draws"
		value = draws +1
		
	var body = JSON.stringify({
		"points": int(upd_points),
		statement: int(value)
	})	
	GameManager.current_score = int(upd_points)
	var url = URL + "?username=eq."+pending_username 
	http_patch.request(url, DBService.HEADERS, HTTPClient.METHOD_PATCH, body)
	
		
func _on_update_points_done(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("HTTP transport failed. Result code: %d (see HTTPRequest.Result enum)" % result)
		emit_signal("error", "HTTP transport failed. Result code: %d (see HTTPRequest.Result enum)" % result)
		return
		
	
	
