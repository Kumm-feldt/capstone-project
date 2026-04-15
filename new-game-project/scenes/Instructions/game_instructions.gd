extends Control

@onready var left_arrow = $Panel/left_arrow
@onready var right_arrow = $Panel/right_arrow
@onready var page_image = $Panel/PageImage
@onready var scroll_container = $Panel/ScrollContainer2

var current_page = 0
var pages = [
	{
		"image": null
	},
	{
		"image": preload("res://Images/Game Pieces/node1Blue.png")  # page 0 - blank/title page
	},
	{
		"image": null  # replace with preload("res://path/to/image2.png")
	},
]

func _ready() -> void:
	left_arrow.pressed.connect(_on_left_arrow_pressed)
	right_arrow.pressed.connect(_on_right_arrow_pressed)
	update_instructions_page()

func update_instructions_page():
	var page = pages[current_page]
	
	if current_page == 0:
		scroll_container.visible = true
		page_image.visible = false
	else:
		scroll_container.visible = false
		if page["image"] != null:
			page_image.texture = page["image"]
			page_image.visible = true
		else:
			page_image.visible = false

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

func _process(delta: float) -> void:
	pass

func _on_back_button_pressed() -> void:
	Music.play_button_sound()
	get_tree().change_scene_to_file("res://scenes/MainMenu/MainMenu.tscn")

func _on_button_pressed() -> void:
	Music.play_button_sound()
	GameManager.GAME_MODE = GameManager.Mode.AI
	GameManager.AI_MODE_LEVEL = GameManager.AILevel.Easy
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
