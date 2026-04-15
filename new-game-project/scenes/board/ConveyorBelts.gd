extends TileMapLayer

var itemIncrement = 3
var lastItem = 0;
var runningTotal = 0

var randomObject = preload("res://scenes/board/ConveyorItem.tscn");

@onready var pathLR = $PathLowerRight
@onready var pathLL = $PathLowerLeft
@onready var pathUL = $PathUpperLeft

func _process(delta:float) -> void:
	lastItem += delta;
	if lastItem >= itemIncrement:
		lastItem = 0;
		var newObject = randomObject.instantiate();
		match runningTotal % 3:
			0:
				pathLR.add_child(newObject);
			1: 
				pathLL.add_child(newObject);
			2:
				pathUL.add_child(newObject);
		newObject.setup();
		runningTotal += 1;
