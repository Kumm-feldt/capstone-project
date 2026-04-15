extends Node2D

var sourceNumber:int

@onready var loadingText = $LoadingScreen/LoadingText
@onready var registerText = $LoadingScreen/RegisteringText
@onready var loadingBar = $LoadingScreen/LoadingBar

@onready var powerLightOff = $Bezel/PowerLightOff


var isLoadingScreenOn = false;

func _ready() -> void:
	powerLightOff = get_node("MenuPanel/PowerLightOff")
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
	var blackScreen = $BlackScreen
	var bootLogo = $BlackScreen/BootLogo
	#When the game opens, start on a dark screen for 0.5 seconds
	blackScreen.visible = true;
	var blackGlow = Color("#2e222f")
	var tween = get_tree().create_tween()
	await get_tree().create_timer(0.5).timeout
	tween.tween_property(blackScreen, "color", blackGlow, 0)
	
	#A little bit later, fade in logo and hold
	await get_tree().create_timer(1).timeout
	bootLogo.visible = true
	bootLogo.play("fadeIn")
	await bootLogo.animation_finished;
	await get_tree().create_timer(3).timeout
	#Fade out logo
	bootLogo.play("fadeOut")
	await bootLogo.animation_finished;
	
	#Dark screen goes away
	await get_tree().create_timer(1).timeout
	blackScreen.visible = false
	bootLogo.visible = false
	
	

#Call this when the game is starting to prevent menuPanel features
func loadingMode() -> void:
	pass
	

func _on_power_button_toggled(toggled_on: bool) -> void:
	if (toggled_on):
		monitor_power_on()
	else:
		monitor_power_off()

func monitor_power_on() -> void:
	# Display the power-on light
	powerLightOff.visible = false;
	# Re-enable the display?

func monitor_power_off() -> void:
	# Disable the power-on light
	powerLightOff.visible = true;
	# Hide and disable the display?

func on_source_changed() -> void:
	# Turn on the black screen for a split second
	# Display SOURCE label
	# Switch menu contents to next item
	
	pass
