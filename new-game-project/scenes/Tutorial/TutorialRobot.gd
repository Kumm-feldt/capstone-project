extends AnimatedSprite2D

@onready var speech_bubble = $SpeechBubble
@onready var dialogue_label = $SpeechBubble/TootWords
@onready var continue_label = $SpeechBubble/Continue
var pixel_font = preload("res://fonts/5x5_pixel/5x5_pixel.ttf")

func _ready():
	dialogue_label.add_theme_font_override("font", pixel_font)
	dialogue_label.add_theme_font_size_override("font_size", 9)
	continue_label.add_theme_font_override("font", pixel_font)
	continue_label.add_theme_font_size_override("font_size", 9)
	dialogue_label.add_theme_color_override("font_color", Color.BLACK)
	continue_label.add_theme_color_override("font_color", Color.BLACK)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	continue_label.text = "▼ click"
	speech_bubble.visible = false
func wakeUp() -> void:
	self.play("wakeUp")
	await animation_finished
	self.play("idle")

func say(givenString: String) -> void:
	dialogue_label.text = givenString
	speech_bubble.visible = true

func say_wait_for_move(givenString: String) -> void:
	dialogue_label.text = givenString
	continue_label.text = "make a move..."
	speech_bubble.visible = true

func hide_bubble() -> void:
	speech_bubble.visible = false
	continue_label.text = "▼ click"
