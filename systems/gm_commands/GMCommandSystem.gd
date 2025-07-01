extends Node
class_name GMCommandSystem

# Sistema de comandos GM para Argentum Online Godot
# Basado en ProtocolCmdParse.bas del cliente original

signal command_executed(command: String, result: String)
signal show_gm_panel()
signal show_info_window(data: Dictionary)

# Categorías de comandos
enum CommandCategory {
	MESSAGING,
	TELEPORT_MOVEMENT,
	PLAYER_INFO,
	PUNISHMENT,
	CHARACTER_MOD,
	SERVER_CONTROL,
	WORLD_MANIPULATION,
	AUDIO_VISUAL,
	FACTION_MANAGEMENT,
	ADMINISTRATIVE
}

# Estructura de comando
class GMCommand:
	var name: String
	var category: CommandCategory
	var description: String
	var usage: String
	var parameters: Array[String]
	var requires_target: bool
	var admin_only: bool
	
	func _init(cmd_name: String, cmd_category: CommandCategory, cmd_desc: String, cmd_usage: String, cmd_params: Array[String] = [], target_required: bool = false, admin_required: bool = false):
		name = cmd_name
		category = cmd_category
		description = cmd_desc
		usage = cmd_usage
		parameters = cmd_params
		requires_target = target_required
		admin_only = admin_required

# Diccionario de comandos registrados
var registered_commands: Dictionary = {}
var command_history: Array[String] = []

func _ready():
	_register_all_commands()

# Registrar todos los comandos GM
func _register_all_commands():
	# MESSAGING COMMANDS
	_register_command("GMSG", CommandCategory.MESSAGING, "Enviar mensaje GM", "/gmsg MENSAJE", ["mensaje"])
	_register_command("RMSG", CommandCategory.MESSAGING, "Enviar mensaje del servidor", "/rmsg MENSAJE", ["mensaje"])
	_register_command("MAPMSG", CommandCategory.MESSAGING, "Enviar mensaje al mapa actual", "/mapmsg MENSAJE", ["mensaje"])
	_register_command("REALMSG", CommandCategory.MESSAGING, "Enviar mensaje al Ejército Real", "/realmsg MENSAJE", ["mensaje"])
	_register_command("CAOSMSG", CommandCategory.MESSAGING, "Enviar mensaje a la Legión Oscura", "/caosmsg MENSAJE", ["mensaje"])
	_register_command("CIUMSG", CommandCategory.MESSAGING, "Enviar mensaje a ciudadanos", "/ciumsg MENSAJE", ["mensaje"])
	_register_command("CRIMSG", CommandCategory.MESSAGING, "Enviar mensaje a criminales", "/crimsg MENSAJE", ["mensaje"])
	_register_command("SMSG", CommandCategory.MESSAGING, "Enviar mensaje del sistema", "/smsg MENSAJE", ["mensaje"])
	_register_command("TALKAS", CommandCategory.MESSAGING, "Hablar como NPC", "/talkas MENSAJE", ["mensaje"])
	
	# TELEPORT & MOVEMENT
	_register_command("TELEP", CommandCategory.TELEPORT_MOVEMENT, "Teletransportar jugador", "/telep [NICK] MAPA X Y", ["nick", "mapa", "x", "y"])
	_register_command("TELEPLOC", CommandCategory.TELEPORT_MOVEMENT, "Teletransportarse al objetivo", "/teleploc", [])
	_register_command("IRA", CommandCategory.TELEPORT_MOVEMENT, "Ir hacia un personaje", "/ira NICK", ["nick"], true)
	_register_command("IRCERCA", CommandCategory.TELEPORT_MOVEMENT, "Ir cerca de un personaje", "/ircerca NICK", ["nick"], true)
	_register_command("SUM", CommandCategory.TELEPORT_MOVEMENT, "Invocar personaje", "/sum NICK", ["nick"], true)
	
	# PLAYER INFORMATION
	_register_command("INFO", CommandCategory.PLAYER_INFO, "Información del personaje", "/info NICK", ["nick"], true)
	_register_command("STAT", CommandCategory.PLAYER_INFO, "Estadísticas del personaje", "/stat NICK", ["nick"], true)
	_register_command("BAL", CommandCategory.PLAYER_INFO, "Oro del personaje", "/bal NICK", ["nick"], true)
	_register_command("INV", CommandCategory.PLAYER_INFO, "Inventario del personaje", "/inv NICK", ["nick"], true)
	_register_command("BOV", CommandCategory.PLAYER_INFO, "Bóveda del personaje", "/bov NICK", ["nick"], true)
	_register_command("SKILLS", CommandCategory.PLAYER_INFO, "Habilidades del personaje", "/skills NICK", ["nick"], true)
	_register_command("DONDE", CommandCategory.PLAYER_INFO, "Ubicación del personaje", "/donde NICK", ["nick"], true)
	_register_command("LASTIP", CommandCategory.PLAYER_INFO, "Última IP del personaje", "/lastip NICK", ["nick"], true)
	_register_command("LASTEMAIL", CommandCategory.PLAYER_INFO, "Último email del personaje", "/lastemail NICK", ["nick"], true)
	
	# PUNISHMENT & MODERATION
	_register_command("CARCEL", CommandCategory.PUNISHMENT, "Encarcelar jugador", "/carcel NICK@MOTIVO@TIEMPO", ["nick", "motivo", "tiempo"], true)
	_register_command("BAN", CommandCategory.PUNISHMENT, "Banear personaje", "/ban NICK@MOTIVO", ["nick", "motivo"], true)
	_register_command("UNBAN", CommandCategory.PUNISHMENT, "Desbanear personaje", "/unban NICK", ["nick"], true)
	_register_command("BANIP", CommandCategory.PUNISHMENT, "Banear IP", "/banip IP/NICK MOTIVO", ["ip_o_nick", "motivo"])
	_register_command("UNBANIP", CommandCategory.PUNISHMENT, "Desbanear IP", "/unbanip IP", ["ip"])
	_register_command("ECHAR", CommandCategory.PUNISHMENT, "Expulsar jugador", "/echar NICK", ["nick"], true)
	_register_command("EJECUTAR", CommandCategory.PUNISHMENT, "Ejecutar jugador", "/ejecutar NICK", ["nick"], true)
	_register_command("ADVERTENCIA", CommandCategory.PUNISHMENT, "Advertir usuario", "/advertencia NICK@MOTIVO", ["nick", "motivo"], true)
	_register_command("SILENCIAR", CommandCategory.PUNISHMENT, "Silenciar jugador", "/silenciar NICK", ["nick"], true)
	_register_command("ESTUPIDO", CommandCategory.PUNISHMENT, "Hacer estúpido", "/estupido NICK", ["nick"], true)
	_register_command("NOESTUPIDO", CommandCategory.PUNISHMENT, "Quitar estúpido", "/noestupido NICK", ["nick"], true)
	
	# CHARACTER MODIFICATION
	_register_command("MOD", CommandCategory.CHARACTER_MOD, "Modificar personaje", "/mod NICK ATRIBUTO VALOR [EXTRA]", ["nick", "atributo", "valor", "extra"], true)
	_register_command("REVIVIR", CommandCategory.CHARACTER_MOD, "Revivir personaje", "/revivir NICK", ["nick"], true)
	_register_command("PERDON", CommandCategory.CHARACTER_MOD, "Perdonar personaje", "/perdon NICK", ["nick"], true)
	_register_command("CONDEN", CommandCategory.CHARACTER_MOD, "Convertir en criminal", "/conden NICK", ["nick"], true)
	_register_command("RAJAR", CommandCategory.CHARACTER_MOD, "Resetear facciones", "/rajar NICK", ["nick"], true)
	_register_command("RAJARCLAN", CommandCategory.CHARACTER_MOD, "Expulsar de clan", "/rajarclan NICK", ["nick"], true)
	
	# SERVER CONTROL
	_register_command("SHOW", CommandCategory.SERVER_CONTROL, "Mostrar listas", "/show TIPO", ["tipo"])
	_register_command("PANELGM", CommandCategory.SERVER_CONTROL, "Abrir panel GM", "/panelgm", [])
	_register_command("ONLINEGM", CommandCategory.SERVER_CONTROL, "GMs online", "/onlinegm", [])
	_register_command("ONLINEMAP", CommandCategory.SERVER_CONTROL, "Jugadores en mapa", "/onlinemap [MAPA]", ["mapa"])
	_register_command("ONLINEREAL", CommandCategory.SERVER_CONTROL, "Ejército Real online", "/onlinereal", [])
	_register_command("ONLINECAOS", CommandCategory.SERVER_CONTROL, "Legión Oscura online", "/onlinecaos", [])
	_register_command("HABILITAR", CommandCategory.SERVER_CONTROL, "Alternar servidor abierto", "/habilitar", [], false, true)
	_register_command("APAGAR", CommandCategory.SERVER_CONTROL, "Apagar servidor", "/apagar", [], false, true)
	
	# WORLD MANIPULATION
	_register_command("CI", CommandCategory.WORLD_MANIPULATION, "Crear objeto", "/ci OBJETO", ["objeto"])
	_register_command("DEST", CommandCategory.WORLD_MANIPULATION, "Destruir objetos", "/dest", [])
	_register_command("ACC", CommandCategory.WORLD_MANIPULATION, "Crear NPC", "/acc NPC", ["npc"])
	_register_command("RACC", CommandCategory.WORLD_MANIPULATION, "Crear NPC con respawn", "/racc NPC", ["npc"])
	_register_command("RMATA", CommandCategory.WORLD_MANIPULATION, "Matar NPC", "/rmata", [])
	_register_command("MATA", CommandCategory.WORLD_MANIPULATION, "Matar NPC sin respawn", "/mata", [])
	_register_command("MASSKILL", CommandCategory.WORLD_MANIPULATION, "Matar NPCs cercanos", "/masskill", [])
	_register_command("LIMPIAR", CommandCategory.WORLD_MANIPULATION, "Limpiar mundo", "/limpiar", [])
	_register_command("RESETINV", CommandCategory.WORLD_MANIPULATION, "Resetear inventario NPC", "/resetinv", [])
	
	# AUDIO/VISUAL
	_register_command("FORCEMIDI", CommandCategory.AUDIO_VISUAL, "Forzar MIDI a todos", "/forcemidi MIDI", ["midi"])
	_register_command("FORCEWAV", CommandCategory.AUDIO_VISUAL, "Forzar WAV a todos", "/forcewav WAV", ["wav"])
	_register_command("FORCEMIDIMAP", CommandCategory.AUDIO_VISUAL, "Forzar MIDI al mapa", "/forcemidimap MIDI [MAPA]", ["midi", "mapa"])
	_register_command("FORCEWAVMAP", CommandCategory.AUDIO_VISUAL, "Forzar WAV al mapa", "/forcewavmap WAV [MAPA] [X] [Y]", ["wav", "mapa", "x", "y"])
	_register_command("LLUVIA", CommandCategory.AUDIO_VISUAL, "Alternar lluvia", "/lluvia", [])
	
	# FACTION MANAGEMENT
	_register_command("ACEPTCONSE", CommandCategory.FACTION_MANAGEMENT, "Aceptar consejero real", "/aceptconse NICK", ["nick"], true)
	_register_command("ACEPTCONSECAOS", CommandCategory.FACTION_MANAGEMENT, "Aceptar consejero caos", "/aceptconsecaos NICK", ["nick"], true)
	_register_command("KICKCONSE", CommandCategory.FACTION_MANAGEMENT, "Expulsar consejero", "/kickconse NICK", ["nick"], true)
	_register_command("NOCAOS", CommandCategory.FACTION_MANAGEMENT, "Expulsar de Legión Oscura", "/nocaos NICK", ["nick"], true)
	_register_command("NOREAL", CommandCategory.FACTION_MANAGEMENT, "Expulsar de Ejército Real", "/noreal NICK", ["nick"], true)
	
	# ADMINISTRATIVE
	_register_command("INVISIBLE", CommandCategory.ADMINISTRATIVE, "Alternar invisibilidad", "/invisible", [])
	_register_command("TRABAJANDO", CommandCategory.ADMINISTRATIVE, "Alternar trabajando", "/trabajando", [])
	_register_command("OCULTANDO", CommandCategory.ADMINISTRATIVE, "Alternar ocultando", "/ocultando", [])
	_register_command("SHOWNAME", CommandCategory.ADMINISTRATIVE, "Mostrar nombre", "/showname", [])
	_register_command("HORA", CommandCategory.ADMINISTRATIVE, "Mostrar hora del servidor", "/hora", [])
	_register_command("REM", CommandCategory.ADMINISTRATIVE, "Agregar comentario", "/rem COMENTARIO", ["comentario"])
	_register_command("NENE", CommandCategory.ADMINISTRATIVE, "Criaturas en mapa", "/nene [MAPA]", ["mapa"])
	_register_command("PISO", CommandCategory.ADMINISTRATIVE, "Objetos en el suelo", "/piso", [])
	_register_command("BLOQ", CommandCategory.ADMINISTRATIVE, "Alternar tile bloqueado", "/bloq", [])
	_register_command("TRIGGER", CommandCategory.ADMINISTRATIVE, "Configurar trigger", "/trigger [NUMERO]", ["numero"])
	_register_command("CENTINELAACTIVADO", CommandCategory.ADMINISTRATIVE, "Alternar centinela", "/centinelaactivado", [])
	_register_command("SLOT", CommandCategory.ADMINISTRATIVE, "Verificar slot", "/slot NICK@SLOT", ["nick", "slot"], true)

func _register_command(name: String, category: CommandCategory, desc: String, usage: String, params: Array[String] = [], target_req: bool = false, admin_req: bool = false):
	var cmd = GMCommand.new(name, category, desc, usage, params, target_req, admin_req)
	registered_commands[name.to_upper()] = cmd

# Ejecutar comando GM
func execute_command(raw_command: String) -> bool:
	if raw_command.is_empty() or not raw_command.begins_with("/"):
		return false
	
	# Parsear comando
	var parts = raw_command.substr(1).split(" ", false, 1)
	var command_name = parts[0].to_upper()
	var arguments = parts[1] if parts.size() > 1 else ""
	
	# Verificar si el comando existe
	if not registered_commands.has(command_name):
		_show_error("Comando desconocido: /" + command_name)
		return false
	
	var command: GMCommand = registered_commands[command_name]
	
	# Verificar permisos de administrador
	if command.admin_only and not Global.is_admin:
		_show_error("No tienes permisos para ejecutar este comando.")
		return false
	
	# Validar argumentos
	if not _validate_arguments(command, arguments):
		_show_error("Uso incorrecto. " + command.usage)
		return false
	
	# Ejecutar comando específico
	var result = _execute_specific_command(command_name, arguments)
	
	# Agregar al historial
	command_history.append(raw_command)
	if command_history.size() > 50:  # Limitar historial
		command_history.pop_front()
	
	command_executed.emit(raw_command, result)
	return true

# Validar argumentos del comando
func _validate_arguments(command: GMCommand, arguments: String) -> bool:
	if command.parameters.is_empty():
		return true  # No requiere argumentos
	
	var required_params = command.parameters.filter(func(p): return not p.begins_with("["))
	
	if required_params.is_empty():
		return true  # Todos los parámetros son opcionales
	
	if arguments.is_empty():
		return false  # Faltan argumentos requeridos
	
	return true  # Validación básica pasada

# Ejecutar comando específico
func _execute_specific_command(command_name: String, arguments: String) -> String:
	match command_name:
		# MESSAGING
		"GMSG":
			return _execute_gmsg(arguments)
		"RMSG":
			return _execute_rmsg(arguments)
		"MAPMSG":
			return _execute_mapmsg(arguments)
		
		# TELEPORT & MOVEMENT
		"TELEP":
			return _execute_telep(arguments)
		"IRA":
			return _execute_ira(arguments)
		"SUM":
			return _execute_sum(arguments)
		
		# PLAYER INFO
		"INFO":
			return _execute_info(arguments)
		"STAT":
			return _execute_stat(arguments)
		"BAL":
			return _execute_bal(arguments)
		
		# SERVER CONTROL
		"PANELGM":
			return _execute_panelgm()
		"ONLINEGM":
			return _execute_onlinegm()
		
		# ADMINISTRATIVE
		"INVISIBLE":
			return _execute_invisible()
		"HORA":
			return _execute_hora()
		
		_:
			return _execute_generic_command(command_name, arguments)

# Implementaciones específicas de comandos
func _execute_gmsg(message: String) -> String:
	if message.is_empty():
		return "Error: Escriba un mensaje."
	Global.game_protocol.WriteGMMessage(message)
	return "Mensaje GM enviado: " + message

func _execute_rmsg(message: String) -> String:
	if message.is_empty():
		return "Error: Escriba un mensaje."
	Global.game_protocol.WriteServerMessage(message)
	return "Mensaje del servidor enviado: " + message

func _execute_mapmsg(message: String) -> String:
	if message.is_empty():
		return "Error: Escriba un mensaje."
	Global.game_protocol.WriteMapMessage(message)
	return "Mensaje enviado al mapa actual: " + message

func _execute_telep(arguments: String) -> String:
	var args = arguments.split(" ")
	if args.size() < 2:
		return "Error: Faltan parámetros. Use /telep [NICK] MAPA X Y"
	
	# TODO: Implementar lógica de teletransporte
	# Nota: Requiere implementación del protocolo de red
	return "Comando de teletransporte ejecutado (pendiente implementación de red)"

func _execute_ira(nick: String) -> String:
	if nick.is_empty():
		return "Error: Especifique un nickname."
	Global.game_protocol.WriteGoToChar(nick)
	return "Yendo hacia: " + nick

func _execute_sum(nick: String) -> String:
	if nick.is_empty():
		return "Error: Especifique un nickname."
	Global.game_protocol.WriteSummonChar(nick)
	return "Invocando a: " + nick

func _execute_info(nick: String) -> String:
	if nick.is_empty():
		return "Error: Especifique un nickname."
	Global.game_protocol.WriteRequestCharInfo(nick)
	return "Solicitando información de: " + nick

func _execute_stat(nick: String) -> String:
	if nick.is_empty():
		return "Error: Especifique un nickname."
	Global.game_protocol.WriteRequestCharStats(nick)
	return "Solicitando estadísticas de: " + nick

func _execute_bal(nick: String) -> String:
	if nick.is_empty():
		return "Error: Especifique un nickname."
	Global.game_protocol.WriteRequestCharGold(nick)
	return "Solicitando oro de: " + nick

func _execute_panelgm() -> String:
	show_gm_panel.emit()
	return "Abriendo panel GM"

func _execute_onlinegm() -> String:
	Global.game_protocol.WriteOnlineGM()
	return "Solicitando lista de GMs online"

func _execute_invisible() -> String:
	Global.game_protocol.WriteInvisible()
	return "Alternando invisibilidad"

func _execute_hora() -> String:
	Global.game_protocol.WriteServerTime()
	return "Solicitando hora del servidor"

func _execute_generic_command(command_name: String, arguments: String) -> String:
	# Para comandos que aún no tienen implementación específica
	return "Comando " + command_name + " ejecutado (implementación genérica)"

# Obtener lista de comandos por categoría
func get_commands_by_category(category: CommandCategory) -> Array[GMCommand]:
	var commands: Array[GMCommand] = []
	for cmd in registered_commands.values():
		if cmd.category == category:
			commands.append(cmd)
	return commands

# Obtener comando por nombre
func get_command(name: String) -> GMCommand:
	return registered_commands.get(name.to_upper(), null)

# Obtener sugerencias de comandos
func get_command_suggestions(partial: String) -> Array[String]:
	var suggestions: Array[String] = []
	var partial_upper = partial.to_upper()
	
	for cmd_name in registered_commands.keys():
		if cmd_name.begins_with(partial_upper):
			suggestions.append("/" + cmd_name.to_lower())
	
	return suggestions

# Mostrar error
func _show_error(message: String):
	print("GM Command Error: " + message)
	# TODO: Mostrar en consola del juego

# Obtener historial de comandos
func get_command_history() -> Array[String]:
	return command_history.duplicate()

# Limpiar historial
func clear_history():
	command_history.clear()
