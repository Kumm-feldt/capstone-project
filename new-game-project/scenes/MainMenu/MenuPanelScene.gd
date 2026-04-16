extends Node2D

var sourceNumber:int

@onready var loadingText = $LoadingScreen/LoadingText
@onready var registerText = $LoadingScreen/RegisteringText
@onready var loadingBar = $LoadingScreen/LoadingBar

@onready var powerLightOff = $Bezel/PowerLightOff
@onready var blackScreen = $BlackScreen

@onready var bootScreen = $BootScreen

var snakeGameOn = false;
var isLoadingScreenOn = false;

var power = false;

var volume = 0;

func _ready() -> void:
	sourceNumber = 0;

# To-Do: fully implement the power-off feature
# To-Do: add a source change feature w/ something fun. Animation? Minigame?
func toggleRegisteringScreen() -> void:
	loadingText.visible = false;
	registerText.visible = true;
	if isLoadingScreenOn:
		$LoadingScreen.visible = false;
		registerText.stop();
		loadingBar.stop();
		isLoadingScreenOn = false;
	else:
		$LoadingScreen.visible = true;
		registerText.play("default");
		loadingBar.play("default");
		isLoadingScreenOn = true;
	pass

func toggleLoadingScreen() -> void:
	loadingText.visible = true;
	registerText.visible = false;
	if isLoadingScreenOn:
		$LoadingScreen.visible = false;
		loadingText.stop();
		loadingBar.stop();
		isLoadingScreenOn = false;
	else:
		$LoadingScreen.visible = true;
		loadingText.play("default");
		loadingBar.play("default");
		isLoadingScreenOn = true;
	pass

func on_game_opened() -> void:
	var bootLogo = $BootScreen/BootLogo
	#When the game opens, start on a dark screen for 0.5 seconds
	bootScreen.visible = true;
	var blackGlow = Color("#2e222f")
	await get_tree().create_timer(0.5).timeout
	var tween = get_tree().create_tween()
	tween.tween_property(bootScreen, "color", blackGlow, 0.1)
	
	#A little bit later, fade in logo and hold
	await get_tree().create_timer(1).timeout
	bootLogo.visible = true
	bootLogo.play("fadeIn")
	await bootLogo.animation_finished;
	await get_tree().create_timer(2.5).timeout
	#Fade out logo
	bootLogo.play("fadeOut")
	await bootLogo.animation_finished;
	
	#Dark screen goes away
	await get_tree().create_timer(1).timeout
	bootScreen.visible = false
	bootScreen.color = Color("#0b220e");
	bootLogo.visible = false
	
	
signal powerPause(on: bool);

#Call this when the game is starting to prevent menuPanel features
func loadingMode() -> void:
	pass
	
var poweringOn = false;
func _on_power_button_pressed() -> void:
	if poweringOn:
		return

	poweringOn = true;

	if power:
		power = false;
		powerLightOff.visible = false;
		blackScreen.visible = false;
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), false)
		emit_signal("powerPause", false);
		await on_game_opened()
	else:
		power = true;
		powerLightOff.visible = true;
		blackScreen.visible = true;
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), true)
		emit_signal("powerPause", true);

	poweringOn = false;
	

func _exit_tree() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), false)


func _on_source_button_pressed() -> void:
	if snakeGameOn:
		snakeGameOn = false;
	else:
		snakeGameOn = true;

	$Snake.visible = snakeGameOn;
	
	pass # Replace with function body.
