extends Control
var settings_pressed = false

@onready var settings_panel = $Panel/SettingsPanel
@onready var customize_panel = $Panel/CustomizePanel
@onready var top_title = $Panel/TopTitleLabel


@export var background_color_grid: GridContainer
@export var color_grid: GridContainer
@export var colors: Array[Color] = [
	"#0eaf9b",	#darkTurquoise
	"#4d9be6",	#blue
	"#905ea9",	#purple
	"#f79627",	#gray
	"#fca790",	#peach
	"#eaaded",	#pink
	"#f79627",	
	"#fbff16",	
]
@export var background_colors: Array[Color] = [
	"#fca790",	#peach
	"#eaaded",	#pink
	"#f04f78",	#magenta
	"#e83b3b",	#red
	"#f79617",	#orange
	"#fbff86",	#yellow
	"#91db69", #lime
	"#30e1b9",	#lightTurquoise
]

# State tracking
var active_sprite: Sprite2D = null
var active_button: Button = null

var original_color: Color = Color.WHITE
var original_button_color: Color = Color.GRAY


@export var row_1_container: HBoxContainer
@export var row_2_container: HBoxContainer

func _ready() -> void:
	_setup_button_row(row_1_container)
	_setup_button_row(row_2_container)
	_initialize_color_grid()
	_initialize_background_color_grid()
	
# ============================================
# BACKGROUND COLOR HELPERS
# ============================================

func _initialize_background_color_grid() -> void:
	for child in background_color_grid.get_children():
		child.queue_free()

	# THIS LOOP IS MISSING FROM YOUR CODE
	for color in background_colors:
		var color_btn = ColorRect.new()
		color_btn.custom_minimum_size = Vector2(50, 50)
		color_btn.color = color
		color_btn.focus_mode = Control.FOCUS_NONE

		color_btn.mouse_entered.connect(_on_background_color_hovered.bind(color))
		color_btn.mouse_exited.connect(_on_background_color_exited)
		color_btn.gui_input.connect(_on_background_color_clicked.bind(color))

		background_color_grid.add_child(color_btn)  # ← background_color_grid, not color_grid
# Call this instead of using self_modulate
func _set_button_color(button: Button, color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	
	# Override all states so hover/pressed don't revert to the default theme
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	button.add_theme_stylebox_override("disabled", style)

func set_active_button(target_button: Button) -> void:
	active_button = target_button
	# Save original color — read it from the existing StyleBox if it exists
	var existing_style = target_button.get_theme_stylebox("normal")
	if existing_style is StyleBoxFlat:
		original_button_color = existing_style.bg_color
	else:
		original_button_color = Color.GRAY  # Fallback if no StyleBoxFlat yet

func _on_background_color_hovered(hovered_color: Color) -> void:
	if active_button:
		_set_button_color(active_button, hovered_color)

func _on_background_color_exited() -> void:
	if active_button:
		_set_button_color(active_button, original_button_color)

func _on_background_color_clicked(event: InputEvent, confirmed_color: Color) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if active_button:
			_set_button_color(active_button, confirmed_color)
			original_button_color = confirmed_color

# ONE function to handle all 8 buttons
func _on_any_button_pressed(target_button: Button) -> void:
	# Call your existing function from the previous step
	set_active_button(target_button)
	print("Dynamically selected sprite from button!")




# ============================================
# SPRITE COLOR	
# ============================================
func _initialize_color_grid() -> void:
	# Clear placeholder children if any exist
	for child in color_grid.get_children():
		child.queue_free()
		
	# Dynamically build the 8 color buttons
	for color in colors:
		var color_btn = ColorRect.new()
		color_btn.custom_minimum_size = Vector2(50, 50)
		color_btn.color = color
		
		# Set Focus mode to none so it doesn't trap keyboard navigation if using mouse
		color_btn.focus_mode = Control.FOCUS_NONE 
		
		# Connect Godot 4 signals with bound arguments
		color_btn.mouse_entered.connect(_on_color_hovered.bind(color))
		color_btn.mouse_exited.connect(_on_color_exited)
		color_btn.gui_input.connect(_on_color_clicked.bind(color))
		
		color_grid.add_child(color_btn)

# Call this from your Sprite Button's "pressed" signal
func set_active_sprite(target_sprite: Sprite2D) -> void:
	active_sprite = target_sprite
	original_color = active_sprite.modulate

func _on_color_hovered(hovered_color: Color) -> void:
	if active_sprite:
		# Temporarily preview the color
		active_sprite.modulate = hovered_color


func _on_color_exited() -> void:
	# Revert to original color if the mouse leaves without clicking
	if active_sprite:
		active_sprite.modulate = original_color

func _on_color_clicked(event: InputEvent, confirmed_color: Color) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if active_sprite:
			# Commit the color change
			active_sprite.modulate = confirmed_color
			original_color = confirmed_color

# ONE function to handle all 8 buttons
func _on_any_character_button_pressed(target_sprite: Sprite2D) -> void:
	# Call your existing function from the previous step
	set_active_sprite(target_sprite)
	print("Dynamically selected sprite from button!")


# ============================================
# BUTTON PRESSED
# ============================================
func _on_instructions_button_pressed() -> void:
	pass # Replace with function body.


func _on_customize_player_button_pressed() -> void:
	settings_panel.visible = false
	customize_panel.visible = true
	top_title.text = "Customize Player"

	
func _setup_button_row(row: HBoxContainer) -> void:
	if not row:
		push_error("HBoxContainer is missing!")
		return
		
	for child in row.get_children():
		# Ensure we are only connecting actual Buttons 
		if child is Button:
			# Get the sprite inside the button. 
			# Using get_node("Sprite2D") is okay here because the relationship (Button -> Sprite) is strictly local and encapsulated.
			var sprite: Sprite2D = child.get_node_or_null("Sprite2D")
			child.pressed.connect(_on_any_button_pressed.bind(child))
			if sprite:
				#  connect the signal and bind the specific sprite to the function call
				child.pressed.connect(_on_any_character_button_pressed.bind(sprite))
			else:
				push_warning("Button found without a Sprite2D child: ", child.name)


func _on_accept_button_pressed() -> void:
	var config = ConfigFile.new()
	if config.load("user://save.cfg") != OK:
		print("error loading config file")
		return
		
	if original_color != null:
		print("seted pending color")
		GameManager.color = original_color
		config.set_value("player", "color", original_color)
		
	if original_button_color != null:
		print("seted pending background")
		GameManager.background_color = original_button_color
		config.set_value("player", "background_color", original_button_color)
	# save config file
	config.save("user://save.cfg")


func _on_back_customize_button_pressed() -> void:
	settings_panel.visible = true
	customize_panel.visible = false
	top_title.text = "Settings"
