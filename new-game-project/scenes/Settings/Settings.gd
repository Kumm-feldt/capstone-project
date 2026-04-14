extends Control

@onready var settings_panel = $Panel/SettingsPanel
@onready var customize_panel = $Panel/CustomizePanel
@onready var instructions_panel = $Panel/InstructionsPanel
@onready var music_slider = $Panel/SettingsPanel/OptionsPanel/VBoxContainer/MusicHBox/MusicSlider
@onready var sfx_slider = $Panel/SettingsPanel/OptionsPanel/VBoxContainer/SFXHBox/SFXSlider

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
var active_sprite_name: String = ""

var active_button: Button = null

var original_color: Color 
var original_button_color: Color 


@export var row_1_container: HBoxContainer
@export var row_2_container: HBoxContainer

# Seed defaults from GameManager in _ready()
func _ready() -> void:
	settings_panel.visible = true
	customize_panel.visible = false
	instructions_panel.visible = false
	_setup_button_row(row_1_container)
	_setup_button_row(row_2_container)
	_initialize_color_grid()
	_initialize_background_color_grid()
	print("GameManager.prof: ", GameManager.profile_picture)
	active_sprite_name = GameManager.profile_picture

	# Seed from actual saved values so Accept is a no-op if nothing changed
	original_color = GameManager.icon_color if GameManager.icon_color is Color else Color.WHITE
	original_button_color = GameManager.background_color if GameManager.background_color is Color else Color.GRAY
	
	# Load saved audio values
	var config = ConfigFile.new()
	if config.load("user://save.cfg") == OK:
		music_slider.value = config.get_value("audio", "music_volume", 1.0)
		sfx_slider.value = config.get_value("audio", "sfx_volume", 1.0)
	else:
		music_slider.value = 1.0
		sfx_slider.value = 1.0
	
	# Connect sliders
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

# ============================================
# AUDIO
# ============================================
func _on_music_changed(value: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))
	_save_audio()

func _on_sfx_changed(value: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))
	_save_audio()

func _save_audio():
	var config = ConfigFile.new()
	config.load("user://save.cfg")
	config.set_value("audio", "music_volume", music_slider.value)
	config.set_value("audio", "sfx_volume", sfx_slider.value)
	config.save("user://save.cfg")

# ============================================
# BACKGROUND COLOR HELPERS
# ============================================

func _initialize_background_color_grid() -> void:
	for child in background_color_grid.get_children():
		child.queue_free()

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
	active_sprite_name = str(target_sprite.name) 
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
	

# ============================================
# BUTTON PRESSED
# ============================================
func _on_instructions_button_pressed() -> void:
	settings_panel.visible = false
	instructions_panel.visible = true
	top_title.text = "Instructions"


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
			var sprite: Sprite2D = child.find_child("*") as Sprite2D
			child.pressed.connect(_on_any_button_pressed.bind(child))
			
			if sprite:
				#  connect the signal and bind the specific sprite to the function call
				child.pressed.connect(_on_any_character_button_pressed.bind(sprite))
			else:
				push_warning("Button found without a Sprite2D child: ", child.name)


# accept customize button
func _on_accept_button_pressed() -> void:
	var config = ConfigFile.new()
	config.load("user://save.cfg")
	# Track what actually changed using a dirty flag instead of null check
	var saved_icon_color = GameManager.get_safe_color(GameManager.icon_color)
	var saved_bg_color   = GameManager.get_safe_color(GameManager.background_color)

	var color_changed = original_color       != saved_icon_color
	var bg_changed    = original_button_color != saved_bg_color
	var name_changed  = active_sprite_name   != GameManager.profile_picture

	if color_changed:
		GameManager.icon_color = original_color
		config.set_value("player", "color", original_color.to_html())

	if bg_changed:
		GameManager.background_color = original_button_color
		config.set_value("player", "background_color", original_button_color.to_html())

	if name_changed:
		GameManager.profile_picture = active_sprite_name
		config.set_value("player", "picture", active_sprite_name)
	
	config.save("user://save.cfg")
	
	if color_changed or bg_changed or name_changed:
		DBService.update_player_colors(
		GameManager.username,
		GameManager.icon_color.to_html(),
		GameManager.background_color.to_html(),
		GameManager.profile_picture
		)
	# Close the customize panel and return to settings
	customize_panel.visible = false
	settings_panel.visible = true
	top_title.text = "Settings"


func _on_back_customize_button_pressed() -> void:
	settings_panel.visible = true
	customize_panel.visible = false
	top_title.text = "Settings"


func _on_back_instructions_button_pressed() -> void:
	settings_panel.visible = true
	instructions_panel.visible = false
	top_title.text = "Settings"


func _on_tutorial_mode_button_pressed() -> void:
	GameManager.GAME_MODE = GameManager.Mode.AI
	GameManager.AI_MODE_LEVEL = GameManager.AILevel.Easy  # AILevel not Difficulty
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
