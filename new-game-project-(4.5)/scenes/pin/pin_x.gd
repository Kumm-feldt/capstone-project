extends Node2D
@onready var highlight = $Highlight

func show_highlight():
	highlight.visible = true

func hide_highlight():
	highlight.visible = false
