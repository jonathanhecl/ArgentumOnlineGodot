extends Node

signal resources_loaded()

@export var progressBar:ProgressBar 

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)	
	
	if !DirAccess.dir_exists_absolute("user://screenshots"):
		DirAccess.make_dir_absolute("user://screenshots")

	var packages = {
		"Index": "res://index.pck",
		"Graphics": "res://graphics.pck",
		"Sounds": "res://sounds.pck",
		"Maps": "res://maps.pck",
	}

	progressBar.value = 0
	progressBar.max_value = packages.size()

	for package in packages:
		if FileAccess.file_exists(packages[package]):
			var ok = ProjectSettings.load_resource_pack(packages[package])
			if ok:
				print("%s loaded" % package)
			else:
				print("%s could not be loaded" % package)
		else:
			print("%s not found" % package)
		progressBar.value += 1
	
	# Emitir señal cuando todo esté listo
	resources_loaded.emit()

	await get_tree().create_timer(0.25).timeout
	progressBar.hide()
	
	#LoginScreen
	var screen = load("uid://cd452cndcck7v").instantiate() 
	ScreenController.SwitchScreen(screen)
