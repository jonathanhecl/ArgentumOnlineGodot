extends Node

var currentScreen:Node

func SwitchScreen(screen:Node) -> void:
	var screen_name = "Unknown"
	if screen and screen.get_script():
		screen_name = screen.get_script().get_path().get_file()
	
	print("🎭 ScreenController: Cambiando a pantalla: ", screen_name)
	print("🎭 ScreenController: Tipo de nodo: ", screen.get_class())
	
	if currentScreen:
		var current_name = "Unknown"
		if currentScreen and currentScreen.get_script():
			current_name = currentScreen.get_script().get_path().get_file()
		print("🎭 ScreenController: Liberando pantalla actual: ", current_name)
		currentScreen.queue_free()
		
	currentScreen = screen
	# Agregar como hijo de Main para asegurar renderizado correcto de CanvasLayers
	var main_node = get_tree().root.get_node("Main")
	if main_node:
		main_node.add_child(currentScreen)
		print("🎭 ScreenController: Pantalla agregada como hija de Main")
	else:
		# Fallback: agregar al root si Main no existe
		get_tree().root.add_child(currentScreen)
		print("🎭 ScreenController: Main no encontrado, agregando al root")
	print("🎭 ScreenController: ¡Pantalla cambiada exitosamente!")
	print("🎭 ScreenController: Hijos en root: ", get_tree().root.get_child_count())
