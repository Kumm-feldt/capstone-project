extends Sprite2D

@export var blink_speed: float = 1.0       # blinks per second
@export var on_color  = Color(0.0, 1.0, 0.2, 1.0)   # bright green
@export var off_color = Color(0.0, 0.149, 0.051, 0.0)  # dim green (not full black)

var _timer: float = 0.0
var _is_on: bool = true

func _process(delta):
	_timer += delta
	if _timer >= (1.0 / blink_speed):
		_timer = 0.0
		_is_on = !_is_on
		modulate = on_color if _is_on else off_color
