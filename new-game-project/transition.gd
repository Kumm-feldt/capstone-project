extends CanvasLayer


signal transition_finished

@onready var left_gate = $LeftGate
@onready var right_gate = $RightGate

func _ready():
	# Gates start closed covering full screen
	var screen_size = get_viewport().get_visible_rect().size
	left_gate.size = Vector2(screen_size.x / 2, screen_size.y)
	left_gate.position = Vector2(0, 0)
	right_gate.size = Vector2(screen_size.x / 2, screen_size.y)
	right_gate.position = Vector2(screen_size.x / 2, 0)

func play_open(target_scene: String):
	"""Slide gates open then load scene"""
	var screen_size = get_viewport().get_visible_rect().size
	var tween = create_tween()
	tween.set_parallel(true)  # both gates move at same time
	tween.tween_property(left_gate, "position:x", -screen_size.x / 2, 0.8)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(right_gate, "position:x", screen_size.x, 0.8)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	emit_signal("transition_finished")
	get_tree().change_scene_to_file(target_scene)
	queue_free()

func play_close():
	"""Slide gates closed — call this on scene entry"""
	var screen_size = get_viewport().get_visible_rect().size
	# Start gates off screen
	left_gate.position = Vector2(-screen_size.x / 2, 0)
	right_gate.position = Vector2(screen_size.x, 0)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(left_gate, "position:x", 0.0, 0.8)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(right_gate, "position:x", screen_size.x / 2, 0.8)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_CUBIC)
	await tween.finished
