extends Node2D

var powerLightOff:Sprite2D

func _ready() -> void:
	powerLightOff = get_node("MenuPanel/PowerLightOff")

# To-Do: fully implement the power-off feature
# To-Do: add a source change feature w/ something fun. Animation? Minigame?

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
