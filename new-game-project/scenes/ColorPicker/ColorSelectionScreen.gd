extends Node2D

#When this scene is instantiated, both player colors are chosen
const COLORS = [
	"#fca790",	#peach
	"#eaaded",	#pink
	"#f04f78",	#magenta
	"#e83b3b",	#red
	"#f79617",	#orange
	"#fbff86",	#yellow
	"#91db69", #lime
	"#30e1b9",	#lightTurquoise
	"#0eaf9b",	#darkTurquoise
	"#4d9be6",	#blue
	"#905ea9",	#purple
	"#9babb2"	#gray
]

var Swatch: PackedScene = preload("res://scenes/ColorPicker/ColorSwatch.tscn")

var selectedColor: Color
var playerOneColor: Color
var playerTwoColor: Color
var playerOneConfirmed = false
var playerTwoConfirmed = false
var gamemode = "Local" # This should be "Network", "VersusAI", or "Local"
var messageBox:Label

# Find out the selected gamemode, to say the right things

func setGamemode(givenGamemode:String) -> void:
	gamemode = givenGamemode;

func _ready() -> void:
	#First, print the correct message
	messageBox = get_node("InstructionBox/InstructionBoxText");
	
	setFirstMessage();
	#Make sure to set the robots to their base color, light grey
	

func selectPlayerOneColor() -> Color:
	#Then allow player to click a color.
	
	# When the user clicks a color once, move a "P1 Color" indicator
	# ...onto the box to indicate the selection. May need a way to make the
	# ...player confirm their selection, for user-friendliness.
	# Chosen color should not be selectable anymore.
	
	#Set player color to the appropriate color, and update the p1 image.
	
	return Color("#ffffff")
	
func selectPlayerTwoColor() -> Color:
	#First, change the instructions
	if (gamemode == "VersusAI" || gamemode == "Network"):
		setMessageBoxText("Choose Opponent's Color!")
	else:
		setMessageBoxText("Choose Player Two's Color!")
	return Color("#ffffff")
	
func setFirstMessage() -> void:
	if (gamemode == "EasyAI" || gamemode == "HardAI" 
	|| gamemode == "NetworkHost" || gamemode == "NetworkJoin"):
		setMessageBoxText("Choose Your Color!")
	else:
		setMessageBoxText("Choose Player One's Color!")
		
func setSecondMessage() -> void:
	if (gamemode == "EasyAI" || gamemode == "HardAI"):
		setMessageBoxText("Choose Opponent's Color!")
	if (gamemode == "NetworkHost" || gamemode == "NetworkJoin"):
		setMessageBoxText("Choose Opponent's Color!")
		$InstructionBox/NetworkDisclaimer.visible = true;
	
	if (gamemode == "Local"):
		setMessageBoxText("Choose Player Two's Color!")
		
func setTransitionMessage() -> void:
	$InstructionBox/NetworkDisclaimer.visible = false;
	setMessageBoxText("Game Starting!")

func setMessageBoxText(givenText:String) -> void:
	messageBox.text = givenText;
	pass

func _on_colorChanged(color: Color, confirm: bool) -> void:
	if (not playerOneConfirmed || not playerTwoConfirmed):
		if (confirm == false):
			if (playerOneConfirmed == false):
				$Player1Demo.setColorPickerRobot(color)
				playerOneColor = color;
			else:
				$Player2Demo.setColorPickerRobot(color)
				playerTwoColor = color;
		else:
			if (playerOneConfirmed == false):
				playerOneColor = color;
				playerOneConfirmed = true;
				$Player1Demo.setColorPickerRobot(color);
				$Player1Demo.confirmColor();
				setSecondMessage();
			else:
				playerTwoColor = color;
				playerTwoConfirmed = true;
				$Player2Demo.setColorPickerRobot(color);
				$Player2Demo.confirmColor();
				transitionToNextScene();
			
		pass # Replace with function body.

func transitionToNextScene() -> void:
	#Disable the swatches so no more color picking happens
	$ColorGrid.disableSwatches();
	#Then, update the message
	setTransitionMessage()
	#Then, wait a few seconds to transition to the next scene
	await get_tree().create_timer(5).timeout
	
	#Transition to next scene based on data from earlier
	switchScenes()
	
func switchScenes():
	if (gamemode == "EasyAI"):
		get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
	if (gamemode == "HardAI"):
		get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
	if (gamemode == "NetworkHost"):
		get_tree().change_scene_to_file("res://scenes/HostGameScreen.tscn")
	if (gamemode == "NetworkJoin"):
		get_tree().change_scene_to_file("res://scenes/JoinGameScreen.tscn")
	if (gamemode == "Local"):
		get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
		pass
	
	print("ERROR: Unexpected value for gamemode in switchScenes")
