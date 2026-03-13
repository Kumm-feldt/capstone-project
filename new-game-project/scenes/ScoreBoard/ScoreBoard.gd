extends Control
var ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVqbW9yYmx1aHpta2Vlc3hremhjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMzNDY3MzIsImV4cCI6MjA4ODkyMjczMn0.JEyjYV-xzy-wNOKMP-oR2YBfNDFGJu7HtKV1ptRJeHk"
var URL = "https://ujmorbluhzmkeesxkzhc.supabase.co/rest/v1/players"
var http_check = HTTPRequest.new()

var HEADERS = [
"Content-Type: application/json",
"apikey: "+ANON_KEY,
"Authorization: Bearer "+ANON_KEY,
"Prefer: return=representation"   # tells Supabase to return the new row
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(http_check)
	http_check.request_completed.connect(_on_get_players_done)
	http_check.request(URL, HEADERS, HTTPClient.METHOD_GET)

func _on_get_players_done(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
			push_error("HTTP transport failed. Result code: %d (see HTTPRequest.Result enum)" % result)
			emit_signal("error", "HTTP transport failed. Result code: %d (see HTTPRequest.Result enum)" % result)
			return
	# start creating rows
	#print(JSON.parse_string(body.get_string_from_utf8()))
	ui_create_rows(JSON.parse_string(body.get_string_from_utf8()))
	
func ui_create_rows(rows):
	for row in rows:
		print(row["username"])
		
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
