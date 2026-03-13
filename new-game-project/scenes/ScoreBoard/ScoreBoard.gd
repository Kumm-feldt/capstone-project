extends Control
var ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVqbW9yYmx1aHpta2Vlc3hremhjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMzNDY3MzIsImV4cCI6MjA4ODkyMjczMn0.JEyjYV-xzy-wNOKMP-oR2YBfNDFGJu7HtKV1ptRJeHk"
var URL = "https://ujmorbluhzmkeesxkzhc.supabase.co/rest/v1/players"
var http_check = HTTPRequest.new()

var score_row_scene = preload("res://scenes/ScoreBoard/ScoreRow.tscn")
@onready var vbox = $Panel/VBoxContainer/ScrollContainer/VBoxContainer

var HEADERS = [
"Content-Type: application/json",
"apikey: "+ANON_KEY,
"Authorization: Bearer "+ANON_KEY,
"Prefer: return=representation"   # tells Supabase to return the new row
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(http_check)
	var url = URL + "?order=points.desc"
	http_check.request_completed.connect(_on_get_players_done)
	http_check.request(url, HEADERS, HTTPClient.METHOD_GET)

func _on_get_players_done(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
			push_error("HTTP transport failed. Result code: %d (see HTTPRequest.Result enum)" % result)
			emit_signal("error", "HTTP transport failed. Result code: %d (see HTTPRequest.Result enum)" % result)
			return
	# start creating rows
	#print(JSON.parse_string(body.get_string_from_utf8()))
	ui_create_rows(JSON.parse_string(body.get_string_from_utf8()))
	
func ui_create_rows(rows):
	var counter =1
	for row in rows:
		var instance_row = score_row_scene.instantiate()
		var rank = instance_row.get_node("Panel/MarginContainer/HBoxContainer/RankLabel")
		var username = instance_row.get_node("Panel/MarginContainer/HBoxContainer/UsernameLabel")
		var points  =instance_row.get_node("Panel/MarginContainer/HBoxContainer/ScoreLabel")
		
		rank.text = "#" + str(counter)
		points.text = str(row["points"]) + "pts"
		username.text = row["username"]
		counter = counter + 1
		vbox.add_child(instance_row)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
