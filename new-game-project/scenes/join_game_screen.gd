extends Control

@export var base_text = "Searching..."
var current_text = ""
var text_index = 0
var delay_per_letter = 0.1
var delay_on_complete = 1.0

@onready var timer = $Panel/BlinkTimer
@onready var label = $Panel/OldComputerLabel

func _ready():
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
