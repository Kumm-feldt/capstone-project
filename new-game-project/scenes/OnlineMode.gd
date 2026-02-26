extends Control

signal popup_closed  # define the custom signal

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_exit_button_pressed() -> void:
	emit_signal("popup_closed")  # tell the parent to handle cleanup


func _on_join_button_pressed() -> void:
	GameManager.GAME_MODE = GameManager.Mode.Join


func _on_host_button_pressed() -> void:
	GameManager.GAME_MODE = GameManager.Mode.Host
