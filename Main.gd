extends Node

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)	
	
	if !DirAccess.dir_exists_absolute("user://screenshots"):
		DirAccess.make_dir_absolute("user://screenshots")
	
	#LoginScreen
	var screen = load("uid://cd452cndcck7v").instantiate() 
	ScreenController.SwitchScreen(screen)
