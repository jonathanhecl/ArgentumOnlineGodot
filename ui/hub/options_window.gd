extends AcceptDialog
class_name OptionsWindow

@onready var sliderVolume = $VBox/hbox_volume/SliderVolume
@onready var sliderFontSize = $VBox/hbox_font_size/SliderFontSize
@onready var sliderConsoleFontSize = $VBox/hbox_console_font_size/SliderConsoleFontSize
@onready var sliderNameFontSize = $VBox/hbox_name_font_size/SliderNameFontSize

# Los checkbox se crearán dinámicamente
var checkCustomCursor: CheckBox
var checkShowPlayerNames: CheckBox
var checkShowFPS: CheckBox
var checkInstantDialog: CheckBox
var checkNpcDialogConsole: CheckBox
var checkMoveWhileTalking: CheckBox
var checkShowShadows: CheckBox
# Botón de configuración de hotkeys
var hotkeyConfigButton: Button
# Botón de PING
var pingButton: Button

func _ready() -> void:
	# Configurar la ventana como no-exclusiva para permitir inputs globales
	exclusive = false
	# Permitir cerrar con la X de la ventana
	close_requested.connect(hide)
	# Asegurar que la X sea visible y funcional
	title = "Opciones"
	
	get_ok_button().text = "Guardar"
	
	var bus = AudioServer.get_bus_index("Master")
	sliderVolume.value = db_to_linear(AudioServer.get_bus_volume_db(bus))
	sliderVolume.connect("value_changed", Callable(self, "_on_slider_value_changed"))
	sliderFontSize.value = Global.dialogFontSize
	sliderFontSize.connect("value_changed", Callable(self, "_on_slider_font_size_changed"))
	sliderConsoleFontSize.value = Global.consoleFontSize
	sliderConsoleFontSize.connect("value_changed", Callable(self, "_on_slider_console_font_size_changed"))
	sliderNameFontSize.value = Global.nameFontSize
	sliderNameFontSize.connect("value_changed", Callable(self, "_on_slider_name_font_size_changed"))
	
	# Crear dinámicamente el checkbox para cursor personalizado
	_create_custom_cursor_option()
	
	# Crear dinámicamente el checkbox para mostrar nombres
	_create_show_player_names_option()
	
	# Crear dinámicamente el checkbox para mostrar FPS
	_create_show_fps_option()
	
	# Configurar checkbox para diálogo instantáneo
	_setup_instant_dialog_option()

	# Crear checkbox para mostrar diálogo de NPC en consola
	_create_npc_dialog_console_option()

	# Crear checkbox para movimiento mientras se habla
	_create_move_while_talking_option()

	# Crear checkbox para visibilidad de sombras
	_create_show_shadows_option()
	
	# Crear botón de PING
	_create_ping_button()
	
	# Crear botón de configuración de hotkeys
	_create_hotkey_config_button()
	
	# Guardar configuración al confirmar
	connect("confirmed", Callable(self, "_on_save_settings"))

func _on_slider_value_changed(value: float) -> void:
	var bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))

func _on_slider_font_size_changed(value: float) -> void:
	Global.dialogFontSize = int(value)

func _on_slider_console_font_size_changed(value: float) -> void:
	Global.consoleFontSize = int(value)

func _on_slider_name_font_size_changed(value: float) -> void:
	Global.nameFontSize = int(value)

func _on_custom_cursor_toggled(button_pressed: bool) -> void:
	Global.useCustomCursor = button_pressed

func _on_show_player_names_toggled(button_pressed: bool) -> void:
	Global.show_player_names = button_pressed

func _on_show_fps_toggled(button_pressed: bool) -> void:
	Global.show_fps_counter = button_pressed

func _on_instant_dialog_toggled(button_pressed: bool) -> void:
	Global.animatedDialog = button_pressed

func _on_npc_dialog_console_toggled(button_pressed: bool) -> void:
	Global.showNpcDialogInConsole = button_pressed

func _on_move_while_talking_toggled(button_pressed: bool) -> void:
	Global.moveWhileTalking = button_pressed

func _on_show_shadows_toggled(button_pressed: bool) -> void:
	Global.show_shadows = button_pressed

func _on_ping_button_pressed() -> void:
	# Obtener el game_context desde game_screen (el padre directo)
	var game_screen = get_parent()
	if game_screen and game_screen._gameContext:
		# Crear args falsos con el game_context
		var fake_args = ChatCommandArgs.new()
		fake_args.game_context = game_screen._gameContext
		ConsoleCommandProcessor.ping(fake_args)
	else:
		# Si no hay contexto, mostrar error
		print("ERROR: No se puede acceder al game_context para PING")
		# Como fallback, intentar ping sin contexto (no mostrará tiempo correcto)
		ConsoleCommandProcessor.ping_from_button()

# Función para crear dinámicamente el checkbox de cursor personalizado
func _create_custom_cursor_option() -> void:
	# Crear directamente el checkbox
	checkCustomCursor = CheckBox.new()
	checkCustomCursor.name = "CheckCustomCursor"
	checkCustomCursor.text = "Usar cursor personalizado"
	checkCustomCursor.button_pressed = Global.useCustomCursor
	checkCustomCursor.connect("toggled", Callable(self, "_on_custom_cursor_toggled"))
	
	# Añadir el checkbox directamente al VBox principal
	$VBox.add_child(checkCustomCursor)

# Función para crear dinámicamente el checkbox de visibilidad de nombres
func _create_show_player_names_option() -> void:
	# Crear directamente el checkbox
	checkShowPlayerNames = CheckBox.new()
	checkShowPlayerNames.name = "CheckShowPlayerNames"
	checkShowPlayerNames.text = "Mostrar nombres de personajes"
	checkShowPlayerNames.button_pressed = Global.show_player_names
	checkShowPlayerNames.connect("toggled", Callable(self, "_on_show_player_names_toggled"))
	
	# Añadir el checkbox directamente al VBox principal
	$VBox.add_child(checkShowPlayerNames)

# Función para crear dinámicamente el checkbox de visibilidad de FPS
func _create_show_fps_option() -> void:
	# Crear directamente el checkbox
	checkShowFPS = CheckBox.new()
	checkShowFPS.name = "CheckShowFPS"
	checkShowFPS.text = "Mostrar contador FPS"
	checkShowFPS.button_pressed = Global.show_fps_counter
	checkShowFPS.connect("toggled", Callable(self, "_on_show_fps_toggled"))
	
	# Añadir el checkbox directamente al VBox principal
	$VBox.add_child(checkShowFPS)

func _create_npc_dialog_console_option() -> void:
	checkNpcDialogConsole = CheckBox.new()
	checkNpcDialogConsole.name = "CheckNpcDialogConsole"
	checkNpcDialogConsole.text = "Mostrar diálogos de NPC en consola"
	checkNpcDialogConsole.button_pressed = Global.showNpcDialogInConsole
	checkNpcDialogConsole.connect("toggled", Callable(self, "_on_npc_dialog_console_toggled"))
	$VBox.add_child(checkNpcDialogConsole)

func _create_move_while_talking_option() -> void:
	checkMoveWhileTalking = CheckBox.new()
	checkMoveWhileTalking.name = "CheckMoveWhileTalking"
	checkMoveWhileTalking.text = "Moverse al hablar"
	checkMoveWhileTalking.button_pressed = Global.moveWhileTalking
	checkMoveWhileTalking.connect("toggled", Callable(self, "_on_move_while_talking_toggled"))
	$VBox.add_child(checkMoveWhileTalking)

func _create_show_shadows_option() -> void:
	checkShowShadows = CheckBox.new()
	checkShowShadows.name = "CheckShowShadows"
	checkShowShadows.text = "Mostrar sombras"
	checkShowShadows.button_pressed = Global.show_shadows
	checkShowShadows.connect("toggled", Callable(self, "_on_show_shadows_toggled"))
	$VBox.add_child(checkShowShadows)

# Función para crear el botón de PING
func _create_ping_button() -> void:
	# Crear el botón
	pingButton = Button.new()
	pingButton.name = "PingButton"
	pingButton.text = "PING"
	pingButton.connect("pressed", Callable(self, "_on_ping_button_pressed"))
	
	# Añadir el botón al VBox principal
	$VBox.add_child(pingButton)

# Función para crear el botón de configuración de hotkeys
func _create_hotkey_config_button() -> void:
	# Crear el botón
	hotkeyConfigButton = Button.new()
	hotkeyConfigButton.name = "HotkeyConfigButton"
	hotkeyConfigButton.text = "Configurar Teclas..."
	hotkeyConfigButton.connect("pressed", Callable(self, "_on_hotkey_config_pressed"))
	
	# Añadir el botón al VBox principal
	$VBox.add_child(hotkeyConfigButton)

func _on_hotkey_config_pressed() -> void:
	# Crear y mostrar la ventana de configuración de hotkeys
	var hotkey_window = preload("res://ui/hub/hotkey_config_window.tscn").instantiate()
	add_child(hotkey_window)
	hotkey_window.show_hotkey_config()

func _on_save_settings() -> void:
	var cfg = ConfigFile.new()
	var is_web = OS.has_feature("web")
	var config_path = "user://options.cfg"
	
	# Cargar existente (si hay) y actualizar valores
	var err = cfg.load(config_path)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		print("[Options] Advertencia: No se pudo cargar config existente: ", err)
	
	cfg.set_value("audio", "volume_db", linear_to_db(sliderVolume.value))
	cfg.set_value("ui", "dialog_font_size", sliderFontSize.value)
	cfg.set_value("ui", "console_font_size", sliderConsoleFontSize.value)
	cfg.set_value("ui", "name_font_size", sliderNameFontSize.value)
	cfg.set_value("ui", "use_custom_cursor", checkCustomCursor.button_pressed)
	cfg.set_value("ui", "show_player_names", checkShowPlayerNames.button_pressed)
	cfg.set_value("ui", "show_fps_counter", checkShowFPS.button_pressed)
	cfg.set_value("ui", "animated_dialog", checkInstantDialog.button_pressed)
	cfg.set_value("ui", "show_npc_dialog_in_console", checkNpcDialogConsole.button_pressed)
	cfg.set_value("ui", "move_while_talking", checkMoveWhileTalking.button_pressed)
	cfg.set_value("ui", "show_shadows", checkShowShadows.button_pressed)
	
	# En web, usar localStorage para compatibilidad mejorada
	if is_web:
		_save_to_local_storage(cfg)
	else:
		err = cfg.save(config_path)
		if err != OK:
			print("[Options] Error guardando configuración: ", err)

func _save_to_local_storage(cfg: ConfigFile) -> void:
	# Guardar secciones en localStorage del navegador
	for section in cfg.get_sections():
		for key in cfg.get_section_keys(section):
			var value = cfg.get_value(section, key)
			var storage_key = "ao_config_%s_%s" % [section, key]
			JavaScriptBridge.eval("localStorage.setItem('%s', '%s')" % [storage_key, str(value).replace("'", "\\'")])

func _load_from_local_storage(cfg: ConfigFile) -> void:
	# Intentar cargar desde localStorage
	var sections = ["audio", "ui"]
	for section in sections:
		var keys = ["volume_db", "dialog_font_size", "console_font_size", "name_font_size", 
					"use_custom_cursor", "show_player_names", "show_fps_counter", 
					"animated_dialog", "show_npc_dialog_in_console", "move_while_talking", "show_shadows"]
		for key in keys:
			var storage_key = "ao_config_%s_%s" % [section, key]
			var value = JavaScriptBridge.eval("localStorage.getItem('%s')" % storage_key)
			if value != null and value != "":
				# Convertir valores numéricos
				if key.contains("size") or key == "volume_db":
					cfg.set_value(section, key, float(value))
				elif key.contains("cursor") or key.contains("show") or key.contains("animated"):
					cfg.set_value(section, key, value == "true")
				else:
					cfg.set_value(section, key, value)

func _setup_instant_dialog_option() -> void:
	checkInstantDialog = $VBox/hbox_instant_dialog/CheckInstantDialog
	checkInstantDialog.button_pressed = Global.animatedDialog
	checkInstantDialog.toggled.connect(_on_instant_dialog_toggled)
