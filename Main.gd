extends Node

func _ready() -> void:
	#RenderingServer.set_default_clear_color(Color.BLACK)	
	
	var screen = load("uid://cd452cndcck7v").instantiate() 
	ScreenController.SwitchScreen(screen)
