@tool
extends GridContainer

const COLORS = [
	"#7f708a",	#darkGray
	"#eaaded",	#pink
	"#ab947a",	#brown
	"#e83b3b",	#red
	"#fbb954",	#orange
	"#fbff86",	#yellow
	"#91db69", #lime
	"#8ff8e2",	#lightTurquoise
	"#0eaf9b",	#darkTurquoise
	"#4d9be6",	#blue
	"#a884f3",	#purple
	"#c7dcd0"	#gray (BASE COLOR)
]

var Swatch: PackedScene = preload("res://scenes/ColorPicker/ColorSwatch.tscn")
var selectedColor:= Color.WHITE

signal colorChanged(color: Color, confirm: bool);

func _ready() -> void:
	fillColorGrid();
	
func disableSwatches() -> void:
	var swatches = get_children();
	for swatch in swatches:
		if swatch is ColorSwatch:
			swatch.disabled = true;
	
func fillColorGrid() -> void:
	for color in COLORS:
		var swatch: Button = Swatch.instantiate()
		swatch.color = color
		add_child(swatch)
		swatch.mouse_entered.connect(on_ColorSwatch_mouse_entered.bind(swatch))
		swatch.pressed.connect(on_ColorSwatch_pressed.bind(swatch))
		

func on_ColorSwatch_mouse_entered(swatch: ColorSwatch) -> void:
	selectedColor = swatch.color;
	colorChanged.emit(swatch.color, false);
	pass
	
		
func on_ColorSwatch_pressed(swatch: ColorSwatch) -> void:
	selectedColor = swatch.color;
	swatch.pressed.disconnect(on_ColorSwatch_pressed)
	swatch.disabled = true;
	colorChanged.emit(swatch.color, true);
	#Make an indicator to show that the color can't be chosen again
	pass
