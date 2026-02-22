extends Control

@onready var dim_overlay = $DimOverlay
@onready var ai_mode_popup = $AIOptionPopup   # or use preload if it's a separate scene
@onready var ai_mode_button = $ModeOptions/AIModeButton
@onready var online_mode_popup = $OnlineOptionPopup


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dim_overlay.visible = false
	ai_mode_popup.visible = false
	online_mode_popup.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_ai_mode_button_pressed() -> void:
	dim_overlay.visible = true
	ai_mode_popup.visible = true
	# Connect the signal if not already connected
	if not ai_mode_popup.popup_closed.is_connected(_on_popup_closed):
		ai_mode_popup.popup_closed.connect(_on_popup_closed)

func _on_popup_closed():
	ai_mode_popup.visible = false
	online_mode_popup.visible = false
	dim_overlay.visible = false
	
func _on_online_mode_pressed() -> void:
	dim_overlay.visible = true
	online_mode_popup.visible = true
	# Connect the signal if not already connected
	if not online_mode_popup.popup_closed.is_connected(_on_popup_closed):
		online_mode_popup.popup_closed.connect(_on_popup_closed)
