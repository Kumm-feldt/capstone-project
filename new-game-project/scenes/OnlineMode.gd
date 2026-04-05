extends Control

signal popup_closed  # define the custom signal

var colorScreenScene = load("res://scenes/ColorPicker/ColorSelectionScreen.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_exit_button_pressed() -> void:
	emit_signal("popup_closed")  # tell the parent to handle cleanup


func _on_join_button_pressed() -> void:
	var colorScreen = colorScreenScene.instantiate()
	colorScreen.setGamemode("NetworkJoin")
	
	var root = get_tree().root
	var current = get_tree().current_scene
	current.queue_free()
	
	get_tree().root.add_child(colorScreen)
	get_tree().current_scene = colorScreen
	
	#This opened up the scene directly before,
	# similarly to the _on_host_button_pressed method.



func _on_host_button_pressed() -> void:
	var colorScreen = colorScreenScene.instantiate()
	colorScreen.setGamemode("NetworkHost")
	
	var root = get_tree().root
	var current = get_tree().current_scene
	current.queue_free()
	
	get_tree().root.add_child(colorScreen)
	get_tree().current_scene = colorScreen
	
	#below method is from before color picker.
	#get_tree().change_scene_to_file("res://scenes/HostGameScreen.tscn")
	
