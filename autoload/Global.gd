extends Node

# Autoload global para Argentum Online Godot
# Maneja el estado global del juego y sistemas principales

# Referencias a sistemas principales
var gm_command_system: GMCommandSystem
var game_protocol: GameProtocol
var gm_panel: GMPanel
var player_info_window: PlayerInfoWindow

# Estado del jugador
var player_name: String = ""
var is_gm: bool = false
var is_admin: bool = false
var gm_level: int = 0

# Estado del juego
var is_connected: bool = false
var current_map: int = 0
var player_position: Vector2 = Vector2.ZERO

# Configuración
var auto_save_enabled: bool = true
var debug_mode: bool = false

signal player_connected()
signal player_disconnected()
signal gm_status_changed(is_gm: bool, level: int)

func _ready():
	_initialize_systems()
	_setup_input_handling()

func _initialize_systems():
	# Inicializar sistema de comandos GM
	gm_command_system = preload("res://systems/gm_commands/GMCommandSystem.gd").new()
	gm_command_system.name = "GMCommandSystem"
	add_child(gm_command_system)
	
	# Inicializar protocolo de red para comandos GM
	game_protocol = preload("res://systems/network/GameProtocol.gd").new()
	game_protocol.name = "GMProtocolInstance"
	add_child(game_protocol)
	
	# Nota: El protocolo original está disponible como clase estática GameProtocol
	# y se usa para comandos básicos del juego como login
	
	# Conectar señales
	gm_command_system.show_gm_panel.connect(_show_gm_panel)
	gm_command_system.show_info_window.connect(_show_info_window)
	
	print("Sistemas GM inicializados correctamente")

func _setup_input_handling():
	# Configurar manejo de entrada global para comandos GM
	pass

func _input(event):
	if event is InputEventKey and event.pressed:
		# Atajos globales para GMs
		if is_gm and event.ctrl_pressed:
			match event.keycode:
				KEY_F1:
					toggle_gm_panel()
				KEY_F2:
					if event.shift_pressed:
						toggle_invisible()
				KEY_F3:
					if event.shift_pressed:
						show_online_gms()

# === FUNCIONES DE GM ===

func set_gm_status(gm_status: bool, level: int = 1):
	is_gm = gm_status
	gm_level = level
	is_admin = level >= 3  # Nivel 3+ son administradores
	
	gm_status_changed.emit(is_gm, level)
	
	if is_gm:
		print("Estado GM activado - Nivel: ", level)
	else:
		print("Estado GM desactivado")

func toggle_gm_panel():
	if not is_gm:
		print("No tienes permisos de GM")
		return
	
	if not gm_panel:
		_create_gm_panel()
	
	if gm_panel.visible:
		gm_panel.hide()
	else:
		gm_panel.show_panel()

func _show_gm_panel():
	if not gm_panel:
		_create_gm_panel()
	gm_panel.show_panel()

func _create_gm_panel():
	var gm_panel_scene = preload("res://ui/gm/gm_panel.tscn")
	gm_panel = gm_panel_scene.instantiate()
	get_tree().root.add_child(gm_panel)

func _show_info_window(data: Dictionary):
	if not player_info_window:
		_create_player_info_window()
	
	var player_name = data.get("player", "")
	var info_type = data.get("type", "general")
	
	player_info_window.show_player_info(player_name, info_type)

func _create_player_info_window():
	var info_window_scene = preload("res://ui/gm/player_info_window.tscn")
	player_info_window = info_window_scene.instantiate()
	get_tree().root.add_child(player_info_window)

# Comandos GM rápidos
func execute_gm_command(command: String) -> bool:
	if not is_gm:
		print("No tienes permisos de GM")
		return false
	
	return gm_command_system.execute_command(command)

func toggle_invisible():
	if is_gm:
		execute_gm_command("/invisible")

func show_online_gms():
	if is_gm:
		execute_gm_command("/onlinegm")

func go_to_player(nick: String):
	if is_gm:
		execute_gm_command("/ira " + nick)

func summon_player(nick: String):
	if is_gm:
		execute_gm_command("/sum " + nick)

func show_player_info(nick: String):
	if is_gm:
		execute_gm_command("/info " + nick)

# === FUNCIONES DE UTILIDAD ===

func is_valid_player_name(name: String) -> bool:
	if name.length() < 3 or name.length() > 20:
		return false
	
	# Solo letras, números y algunos caracteres especiales
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9_-]+$")
	return regex.search(name) != null

func format_gold(amount: int) -> String:
	# Formatear oro con separadores de miles
	var gold_str = str(amount)
	var formatted = ""
	var count = 0
	
	for i in range(gold_str.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "." + formatted
		formatted = gold_str[i] + formatted
		count += 1
	
	return formatted

func get_time_string() -> String:
	var time = Time.get_datetime_dict_from_system()
	return "%02d:%02d:%02d" % [time.hour, time.minute, time.second]

func get_date_string() -> String:
	var time = Time.get_datetime_dict_from_system()
	return "%02d/%02d/%04d" % [time.day, time.month, time.year]

# === CONFIGURACIÓN ===

func save_config():
	var config = ConfigFile.new()
	
	config.set_value("player", "name", player_name)
	config.set_value("gm", "is_gm", is_gm)
	config.set_value("gm", "level", gm_level)
	config.set_value("game", "auto_save", auto_save_enabled)
	config.set_value("game", "debug_mode", debug_mode)
	
	config.save("user://config.cfg")

func load_config():
	var config = ConfigFile.new()
	
	if config.load("user://config.cfg") != OK:
		print("No se pudo cargar la configuración, usando valores por defecto")
		return
	
	player_name = config.get_value("player", "name", "")
	is_gm = config.get_value("gm", "is_gm", false)
	gm_level = config.get_value("gm", "level", 0)
	auto_save_enabled = config.get_value("game", "auto_save", true)
	debug_mode = config.get_value("game", "debug_mode", false)

# === EVENTOS DE CONEXIÓN ===

func on_player_connected(name: String):
	player_name = name
	is_connected = true
	player_connected.emit()
	print("Jugador conectado: ", name)

func on_player_disconnected():
	is_connected = false
	player_disconnected.emit()
	print("Jugador desconectado")

# === FUNCIONES DE DEBUG ===

func debug_print(message: String):
	if debug_mode:
		print("[DEBUG] ", message)

func toggle_debug_mode():
	debug_mode = not debug_mode
	print("Modo debug: ", "ACTIVADO" if debug_mode else "DESACTIVADO")

# === LIMPIEZA ===

func _exit_tree():
	save_config()
	
	if gm_panel:
		gm_panel.queue_free()
	
	if player_info_window:
		player_info_window.queue_free()
