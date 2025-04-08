extends Node

var currentScreen:Node

func SwitchScreen(screen:Node) -> void:
	if currentScreen:
		currentScreen.queue_free()
		
	currentScreen = screen
	add_child(currentScreen)
