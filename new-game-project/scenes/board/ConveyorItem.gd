extends PathFollow2D

func setup() -> void:
	#Set the sprite for this item as one of the random items
	var rand = randi_range(0, 8);
	$ConveyorItem.region_rect.position = Vector2(rand * 25, 0)
	
	#Set the tween and off it goes!
	var tween = get_tree().create_tween()
	tween.tween_property(self, "progress_ratio", 1, 7);
	pass
