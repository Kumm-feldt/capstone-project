extends CanvasLayer

@onready var turn_label = $PanelContainer/MarginContainer/Control/TurnLabel
@onready var invalid_label = $PanelContainer/MarginContainer/Control/InvalidaLabel


func _on_turn_changed(player):
	var player_color = ""
	if player == 'o':
		player_color = "Red"
	else:
		player_color = "Blue"
	turn_label.text = "%s's turn" % player_color
	

func _on_invalid_move(text):
	invalid_label.text = text
func _on_valid_move():
	invalid_label.text = ""



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.connect("turn_changed", _on_turn_changed)
	GameState.connect("invalid_move", _on_invalid_move)
	GameState.connect("valid_move", _on_valid_move)
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
