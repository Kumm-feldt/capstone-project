extends Node2D

#When this scene is instantiated, both player colors are chosen
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

var selectedColor: Color
var playerOneColor: Color
var playerTwoColor: Color
var playerOneConfirmed = false
var playerTwoConfirmed = false
var gamemode = "Local" # This should be "Network", "VersusAI", or "Local"
var messageBox:Label
@onready var label_player_1 = $LabelPlayer1
@onready var label_player_2 = $LabelPlayer2



# Find out the selected gamemode, to say the right things

func setGamemode(givenGamemode:String) -> void:
	gamemode = givenGamemode;

func _ready() -> void:
	#Connect to menuPanelScene
	$MenuPanelScene.connect("powerOff", _on_powerPause);
	#First, print the correct message
	messageBox = get_node("InstructionBox/InstructionBoxText");
	setFirstMessage();
	if GameManager.GAME_MODE == GameManager.Mode.AI:
		label_player_1.text = "You"
		label_player_2.text = "CPU"
	elif GameManager.GAME_MODE == GameManager.Mode.Multiplayer:
		label_player_1.text = "You"
		label_player_2.text =  "Opponent"
		
	#Make sure to set the robots to their base color, light grey
	
	#Then allow player to click a color.
	
	# When the user clicks a color once, move a "P1 Color" indicator
	# ...onto the box to indicate the selection. May need a way to make the
	# ...player confirm their selection, for user-friendliness.
	# Chosen color should not be selectable anymore.
	
	#Set player color to the appropriate color, and update the p1 image.
	#First, change the instructions

	return Color("#ffffff")
	

func _on_powerPause(on: bool) -> void:
	if on:
		$ColorGrid.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		$ColorGrid.process_mode = Node.PROCESS_MODE_INHERIT


func setFirstMessage() -> void:
	if (gamemode == "EasyAI" || gamemode == "HardAI" 
	|| gamemode == "NetworkHost" || gamemode == "NetworkJoin"):
		setMessageBoxText("Choose Your Color!")
	else:
		setMessageBoxText("Choose Player One's Color!")
		
func setSecondMessage() -> void:
	if (gamemode == "EasyAI" || gamemode == "HardAI"):
		setMessageBoxText("AI choosing color...")
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
	
func get_random_color_excluding(excluded: Color) -> Color:
	var available = COLORS.filter(func(hex): return Color(hex) != excluded)
	return Color(available[randi() % available.size()])
	#return Color(available[randi() % available.size()])
	
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
				# if AI select random color
				if(GameManager.GAME_MODE == GameManager.Mode.AI):
					playerTwoColor = get_random_color_excluding(playerOneColor)  # ← excludes player's color					playerTwoConfirmed = true;
					$Player2Demo.setColorPickerRobot(playerTwoColor);
					$Player2Demo.confirmColor();
					transitionToNextScene();
				setSecondMessage();
			else:
				
				playerTwoColor = color;
				playerTwoConfirmed = true;
				$Player2Demo.setColorPickerRobot(color);
				$Player2Demo.confirmColor();
				transitionToNextScene();
			
		pass # Replace with function body.

func transitionToNextScene() -> void:
	#Set the colors into stone so they can be used later
	GameManager.player1_color = playerOneColor;
	GameManager.player2_color = playerTwoColor;
	
	#Disable the swatches so no more color picking happens
	$ColorGrid.disableSwatches();
	#Then, update the message
	setTransitionMessage()
	#Then, wait a few seconds to transition to the next scene
	await get_tree().create_timer(2).timeout
	
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


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/GameMode/GameMode.tscn")
