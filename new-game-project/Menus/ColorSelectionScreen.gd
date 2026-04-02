extends Node2D


#When this scene is instantiated, both player colors are chosen

var playerOneColor: Color
var playerTwoColor: Color
var gamemode:String # This should be "Network", "VersusAI", or "Local"
var messageBox:Label
var colorGrid:GridContainer

# Find out the selected gamemode, to say the right things
func _init(selectedGamemode:String) -> void:
	gamemode = selectedGamemode;


func _ready() -> void:
	messageBox = get_node("InstructionBox/InstructionBoxText");
	colorGrid = get_node("ColorGrid");
	playerOneColor = selectPlayerOneColor();
	playerTwoColor = selectPlayerTwoColor();
	#Then, start the game, passing the relevant variables
	
func selectPlayerOneColor() -> Color:
	#First, change the instructions
	if (gamemode == "VersusAI" || gamemode == "Network"):
		setMessageBoxText("Choose Your Color!")
	else:
		setMessageBoxText("Choose Player One's Color!")
	#Then allow player to click a color.
	
	# When the user clicks a color once, move a "P1 Color" indicator
	# ...onto the box to indicate the selection. May need a way to make the
	# ...player confirm their selection, for user-friendliness.
	# Chosen color should not be selectable anymore.
	
	#Set player color to the appropriate color, and update the p1 image.
	
	pass
	
func selectPlayerTwoColor() -> Color:
	#First, change the instructions
	if (gamemode == "VersusAI" || gamemode == "Network"):
		setMessageBoxText("Choose Opponent's Color!")
	else:
		setMessageBoxText("Choose Player Two's Color!")
	pass
	
func setMessageBoxText(givenText:String) -> void:
	messageBox.text = givenText;
	pass
