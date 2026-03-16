extends Control

func connect_signals():
	"""Connect to NetworkManager signals"""
	NetworkManager.connect("game_ready", _on_game_ready)
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect_signals()
	# call Host
	NetworkManager.host_game()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_game_ready():
	print("Host hitted")
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
