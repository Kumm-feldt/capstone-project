extends Control

@export var base_text: String = "Searching..."
var current_text = ""
var text_index = 0
var delay_per_letter = 0.1
var delay_on_complete = 1.0

# ============================================
# RESOURCES
# ============================================
var host_request_row = preload("res://scenes/Networking/Join/JoinRequestRow.tscn")
@onready var timer = $Panel/BlinkTimer
@onready var label = $Panel/OldComputerLabel
@onready var vbox = $VBoxContainer/ScrollContainer/VBoxContainer/MarginContainer

func connect_signals():
	"""Connect to NetworkManager signals"""
	NetworkManager.connect("game_ready", _on_game_ready)
	NetworkManager.connect("discovered_servers_ui", _on_discovered_servers_ui)
	if NetworkManager.discovered_servers.size() > 0:
		_on_discovered_servers_ui(NetworkManager.discovered_servers)
	
func _ready():
	print("Join screen _ready")
	connect_signals()
	# Safety check: if already connected by the time scene loads
	if NetworkManager.players.size() >= 2:
		_on_game_ready()
	label.text = ""
	timer.timeout.connect(_on_timer_timeout)


func _process(delta):
	if !timer.is_stopped():
		return  # wait for timer

	if text_index < base_text.length():
		text_index += 1
		current_text = base_text.left(text_index)
		label.text = current_text
		timer.start(delay_per_letter)
	elif text_index == base_text.length():
		text_index += 1
		timer.start(delay_on_complete)
	else:
		# Entire text just disappeared, reset
		text_index = 0
		current_text = ""
		label.text = ""

func _on_timer_timeout():
	_process(0.0)


func _on_game_ready():
	print("Join hitted")
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _on_discovered_servers_ui(servers):
	# Clear existing rows
	for child in vbox.get_children():
		child.queue_free()
	"""Create a row within VBoxContainer"""
	for ip in servers.keys():
		var info = servers[ip]  # e.g. {"name": "Creeper Match", "port": 7777}
		# instantiate scene
		var row_instance = host_request_row.instantiate()
		# Get nodes inside the row
		var username_label: Label = row_instance.get_node("Panel/HBoxContainer/Username")
		var join_button: Button = row_instance.get_node("Panel/HBoxContainer/JoinButton")
		username_label.text = info.get("host")
		# Connect button to a callback, passing the ip
		join_button.pressed.connect(_on_join_button_pressed.bind(ip))
		# add scene to vboxcontainer
		vbox.add_child(row_instance)
	
	
func _on_join_button_pressed(ip):
	NetworkManager.join_game(ip)


func _on_back_button_pressed() -> void:
	# stop searching for game
	get_tree().change_scene_to_file("res://scenes/GameMode/GameMode.tscn")
