extends Control

@onready var settings_panel = $Panel/SettingsPanel
@onready var customize_panel = $Panel/CustomizePanel
@onready var instructions_panel = $Panel/InstructionsPanel
@onready var music_slider = $Panel/SettingsPanel/OptionsPanel/VBoxContainer/MusicHBox/MusicSlider
@onready var sfx_slider = $Panel/SettingsPanel/OptionsPanel/VBoxContainer/SFXHBox/SFXSlider
@onready var top_title = $Panel/TopTitleLabel
@onready var custom_player_button = $Panel/SettingsPanel/OptionsPanel/VBoxContainer/CustomizePlayerButton

@onready var instructions_title = $Panel/InstructionsPanel/TitleLabel
@onready var instructions_body = $Panel/InstructionsPanel/HBoxContainer/BodyLabel
@onready var instructions_image = $Panel/InstructionsPanel/PageImage
@onready var left_arrow = $Panel/InstructionsPanel/left_arrow
@onready var right_arrow = $Panel/InstructionsPanel/right_arrow
@onready var page_image = $Panel/InstructionsPanel/PageImage
@onready var scroll_container = $Panel/InstructionsPanel/ScrollContainer2

@export var background_color_grid: GridContainer
@export var color_grid: GridContainer
@export var colors: Array[Color] = [
    "#0eaf9b",
    "#4d9be6",
    "#905ea9",
    "#f79627",
    "#fca790",
    "#eaaded",
    "#f79627",
    "#fbff16",
]
@export var background_colors: Array[Color] = [
    "#fca790",
    "#eaaded",
    "#f04f78",
    "#e83b3b",
    "#f79617",
    "#fbff86",
    "#91db69",
    "#30e1b9",
]

# State tracking
var active_sprite: Sprite2D = null
var active_sprite_name: String = ""
var active_button: Button = null
var original_color: Color
var original_button_color: Color
var first_launch = false

@export var row_1_container: HBoxContainer
@export var row_2_container: HBoxContainer

# ============================================
# INSTRUCTIONS PAGES
# ============================================
var current_page = 0
var pages = [
    {
        "title": "Goal of the Game",
        "body": "Connect your snake's head and tail \n(at opposite corners of the board)\n with an unbroken chain of your nodes.\n\nOnly orthogonal connections count - \nup, down, left and right.\n\nThe first player to complete their chain wins!",
        "image": null  # preload("res://path/to/goal_image.png")
    },
    {
        "title": "Diagonal Jumps",
        "body": "Move a robot one space diagonally to an empty intersection.\n\nAs it moves, it passes over one grid space.\nIf empty, your node is placed there!\n\nIf the space has your opponent's node, it flips to your color.",
        "image": null  # preload("res://path/to/diagonal_image.png")
    },
    {
        "title": "Orthogonal Moves",
        "body": "Move a robot one space up, down, left, or right.\n\nOrthogonal moves do not place or flip any nodes.\n\nUse them to reposition your robots\nfor better diagonal jumps later.",
        "image": null  # preload("res://path/to/orthogonal_image.png")
    },
    {
        "title": "Robot Captures",
        "body": "If an opponent's robot is orthogonally adjacent to yours,\n you can jump over it,\ntaking it out of the game!\n\nThere must be an empty space for your robot to land.\n\nNo multi-jumps allowed.",
        "image": null  # preload("res://path/to/capture_image.png")
    },
    {
        "title": "Other Rules",
        "body": "Be careful - destroying all of the other player's robots will result in a draw!\n\nDiagonal connections between nodes\ndo not count toward your chain.\n\nYou may only move ONE robot per turn.",
        "image": null  # preload("res://path/to/other_image.png")
    },
]
# ============================================
# Check first launch
# ============================================
func check_first_launch():
    var config = ConfigFile.new()
    if config.load("user://save.cfg") != OK:
        first_launch = true
        
func update_instructions_page():
    var page = pages[current_page]
    instructions_title.text = page["title"]
    instructions_body.text = page["body"]
    if page["image"] != null:
        instructions_image.texture = page["image"]
        instructions_image.visible = true
    else:
        instructions_image.visible = false
    left_arrow.disabled = current_page == 0
    right_arrow.disabled = current_page == pages.size() - 1

func _on_left_arrow_pressed():
    if current_page > 0:
        current_page -= 1
        update_instructions_page()

func _on_right_arrow_pressed():
    if current_page < pages.size() - 1:
        current_page += 1
        update_instructions_page()

# ============================================
# READY
# ============================================
func _ready() -> void:
    check_first_launch()
    settings_panel.visible = true
    customize_panel.visible = false
    instructions_panel.visible = false
    
    if not first_launch:
        _setup_button_row(row_1_container)
        _setup_button_row(row_2_container)
        _initialize_color_grid()
        _initialize_background_color_grid()
        custom_player_button.visible = true
        original_color = GameManager.icon_color if GameManager.icon_color is Color else Color.WHITE
        original_button_color = GameManager.background_color if GameManager.background_color is Color else Color.GRAY

    # Load saved audio values
    var config = ConfigFile.new()
    if config.load("user://save.cfg") == OK:
        music_slider.value = config.get_value("audio", "music_volume",1.0)
        sfx_slider.value = config.get_value("audio", "sfx_volume", 1.0)
    else:
        music_slider.value = 1.0
        sfx_slider.value = 1.0

    # Connect sliders
    music_slider.value_changed.connect(_on_music_changed)
    sfx_slider.value_changed.connect(_on_sfx_changed)

    # Connect arrow buttons
    left_arrow.pressed.connect(_on_left_arrow_pressed)
    right_arrow.pressed.connect(_on_right_arrow_pressed)
    
    var inst_font = preload("res://fonts/CyberpunkCraftpixPixel.otf")
    var inst_color = Color("374e4a")
    instructions_title.add_theme_font_size_override("font_size", 32)
    instructions_body.add_theme_font_size_override("font_size", 17)
    instructions_title.add_theme_font_override("font", inst_font)
    instructions_title.add_theme_color_override("font_color", inst_color)

    instructions_body.add_theme_font_override("font", inst_font)
    instructions_body.add_theme_color_override("font_color", inst_color)
# ============================================
# AUDIO
# ============================================
func _on_music_changed(value: float):
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value/50))
    _save_audio()

func _on_sfx_changed(value: float):
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value/10))
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
        background_color_grid.add_child(color_btn)

func _set_button_color(button: Button, color: Color) -> void:
    var style = StyleBoxFlat.new()
    style.bg_color = color
    button.add_theme_stylebox_override("normal", style)
    button.add_theme_stylebox_override("hover", style)
    button.add_theme_stylebox_override("pressed", style)
    button.add_theme_stylebox_override("focus", style)
    button.add_theme_stylebox_override("disabled", style)

func set_active_button(target_button: Button) -> void:
    active_button = target_button
    var existing_style = target_button.get_theme_stylebox("normal")
    if existing_style is StyleBoxFlat:
        original_button_color = existing_style.bg_color
    else:
        original_button_color = Color.GRAY

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

func _on_any_button_pressed(target_button: Button) -> void:
    Music.play_button_sound()
    set_active_button(target_button)

# ============================================
# SPRITE COLOR
# ============================================
func _initialize_color_grid() -> void:
    for child in color_grid.get_children():
        child.queue_free()
    for color in colors:
        var color_btn = ColorRect.new()
        color_btn.custom_minimum_size = Vector2(50, 50)
        color_btn.color = color
        color_btn.focus_mode = Control.FOCUS_NONE
        color_btn.mouse_entered.connect(_on_color_hovered.bind(color))
        color_btn.mouse_exited.connect(_on_color_exited)
        color_btn.gui_input.connect(_on_color_clicked.bind(color))
        color_grid.add_child(color_btn)

func set_active_sprite(target_sprite: Sprite2D) -> void:
    active_sprite = target_sprite
    active_sprite_name = str(target_sprite.name)
    original_color = active_sprite.modulate

func _on_color_hovered(hovered_color: Color) -> void:
    if active_sprite:
        active_sprite.modulate = hovered_color

func _on_color_exited() -> void:
    if active_sprite:
        active_sprite.modulate = original_color

func _on_color_clicked(event: InputEvent, confirmed_color: Color) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        if active_sprite:
            active_sprite.modulate = confirmed_color
            original_color = confirmed_color

func _on_any_character_button_pressed(target_sprite: Sprite2D) -> void:
    Music.play_button_sound()
    set_active_sprite(target_sprite)

# ============================================
# BUTTON PRESSED
# ============================================
func _on_instructions_button_pressed() -> void:
    Music.play_button_sound()
    settings_panel.visible = false
    instructions_panel.visible = true
    top_title.text = "Instructions"
    current_page = 0
    update_instructions_page()

func _on_customize_player_button_pressed() -> void:
    Music.play_button_sound()
    settings_panel.visible = false
    customize_panel.visible = true
    top_title.text = "Customize Player"

func _setup_button_row(row: HBoxContainer) -> void:
    if not row:
        push_error("HBoxContainer is missing!")
        return
    for child in row.get_children():
        if child is Button:
            var sprite: Sprite2D = child.find_child("*") as Sprite2D
            child.pressed.connect(_on_any_button_pressed.bind(child))
            if sprite:
                child.pressed.connect(_on_any_character_button_pressed.bind(sprite))
            else:
                push_warning("Button found without a Sprite2D child: ", child.name)

func _on_accept_button_pressed() -> void:
    Music.play_button_sound()
    var config = ConfigFile.new()
    config.load("user://save.cfg")
    var saved_icon_color = GameManager.get_safe_color(GameManager.icon_color)
    var saved_bg_color = GameManager.get_safe_color(GameManager.background_color)
    var color_changed = original_color != saved_icon_color
    var bg_changed = original_button_color != saved_bg_color
    var name_changed = active_sprite_name != GameManager.profile_picture
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
    customize_panel.visible = false
    settings_panel.visible = true
    top_title.text = "Settings"

func _on_back_customize_button_pressed() -> void:
    Music.play_button_sound()
    settings_panel.visible = true
    customize_panel.visible = false
    top_title.text = "Settings"

func _on_back_instructions_button_pressed() -> void:
    Music.play_button_sound()
    settings_panel.visible = true
    instructions_panel.visible = false
    top_title.text = "Settings"

func _on_tutorial_mode_button_pressed() -> void:
    Music.play_button_sound()
    GameManager.GAME_MODE = GameManager.Mode.AI
    GameManager.AI_MODE_LEVEL = GameManager.AILevel.Easy
    GameManager.IS_TUTORIAL= true
    get_tree().change_scene_to_file("res://scenes/main/Main.tscn")


func _on_tutorial_mode_pressed() -> void:
    Music.play_button_sound()
    GameManager.GAME_MODE = GameManager.Mode.AI
    GameManager.AI_MODE_LEVEL = GameManager.AILevel.Easy
    GameManager.IS_TUTORIAL= true
    get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
    
