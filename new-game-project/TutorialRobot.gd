extends AnimatedSprite2D


func wakeUp() -> void:
	self.play("wakeUp")
	await animation_finished
	self.play("idle")

func say(givenString: String) -> void:
	#Make Toot say something by bringing up the speech bubble,
	# 	and then setting the text appropriately.
	
	# Make sure to close the previous bubble when bringing up a new one.
	
	# It may be more sensible to dynamically create the speechbubble 
	# 	and text at runtime but I'll leave that up to you. 
	
	# Do your best soldier, and may God be with you. :salute:
	pass
