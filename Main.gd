extends Node

func _ready() -> void:
	#RenderingServer.set_default_clear_color(Color.BLACK)	
	
	var screen = load("uid://b2dyxo3826bub").instantiate() 
	ScreenController.SwitchScreen(screen)
