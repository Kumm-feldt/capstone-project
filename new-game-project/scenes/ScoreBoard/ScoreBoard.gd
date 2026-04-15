extends Control
var http_check = HTTPRequest.new()
var score_row_scene = preload("res://scenes/ScoreBoard/ScoreRow.tscn")
@onready var vbox = $Panel/VBoxContainer/ScrollContainer/VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(http_check)
	var url = DBService.URL + "?order=points.desc&limit=10"
	http_check.request_completed.connect(_on_get_players_done)
	http_check.request(url, DBService.HEADERS, HTTPClient.METHOD_GET)

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
		# instantiate row
		var instance_row = score_row_scene.instantiate()
		# instantiate elements inside row
		var icon_sprite = instance_row.get_node("Panel/MarginContainer/HBoxContainer/Panel/UserSprite")
		var panel_bg = instance_row.get_node("Panel/MarginContainer/HBoxContainer/Panel")
		var style = StyleBoxFlat.new()
		# get user info
		var rank = instance_row.get_node("Panel/MarginContainer/HBoxContainer/RankLabel")
		var username = instance_row.get_node("Panel/MarginContainer/HBoxContainer/UsernameLabel")
		var points  =instance_row.get_node("Panel/MarginContainer/HBoxContainer/ScoreLabel")
		var profile_pic = row["picture"]
		var color_icon = GameManager.get_safe_color(row["color"])
		var background_color = GameManager.get_safe_color(row["background"])
		
		style.bg_color = background_color
		panel_bg.add_theme_stylebox_override("panel", style)
		icon_sprite.setIcon(profile_pic, GameManager.get_safe_color(color_icon))
		
		rank.text = "#" + str(counter)
		points.text = str(row["points"]) + "pts"
		username.text = row["username"]
		
		counter = counter + 1
		vbox.add_child(instance_row)
	

func _on_back_button_pressed() -> void:
	Music.play_button_sound()
	get_tree().change_scene_to_file("res://scenes/GameMode/GameMode.tscn")
