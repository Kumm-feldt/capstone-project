extends CanvasLayer
@onready var resume_button = $Panel/ResumeButton
@onready var quit_button = $Panel/QuitButton

func _ready():
	resume_button.pressed.connect(_on_resume)
	quit_button.pressed.connect(_on_quit)



func _on_resume():
	GameState.unpause_game()
	hide()

func _on_quit():
	get_tree().quit()
