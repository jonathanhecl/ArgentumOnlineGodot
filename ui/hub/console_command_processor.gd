extends Node
class_name ConsoleCommandProcessor

static var command_handler:Dictionary[String, Callable] = {
	"salir": quit,
	"est": request_stats,
	"invisible": invisible,
	"meditar": meditate,
	"desc": change_description,
	"boveda": open_vault,
	"depositar": deposit_gold,
	"retirar": withdraw_gold,
	"balance": request_balance,
	"online": request_online,
	"apostar": gamble,
	"resucitar": resucitate,
	"salirclan": guild_leave,
	"curar": heal,
	"comerciar": start_commerce,
	"quieto": pet_stand,
	"acompañar": pet_follow,
	"liberar": release_pet,
	"entrenar": train_list,
	"descansar": rest,
	"consulta": consultation,
	"ayuda": help,
	"enlistar": enlist,
	"informacion": information,
	"recompensa": reward,
	"motd": request_motd,
	"uptime": uptime,
	"salirparty": party_leave,
	"crearparty": party_create,
	"party": party_join,
	"compartirnpc": share_npc,
	"nocompartirnpc": stop_sharing_npc,
	"encuesta": inquiry,
	"cmsg": guild_message,
	"pmsg": party_message,
	"centinela": centinel_report,
	"onlineclan": guild_online,
	"onlineparty": party_online,
	"bmsg": council_message,
	"rol": role_master_request,
	"gm": gm_request,
	"_bug": bug_report,
	"voto": guild_vote,
	"penas": punishments,
	"contraseña": change_password,
	"retirarfaccion": leave_faction,
	"denunciar": denounce,
	"fundarclan": guild_fundate,
	"echarparty": party_kick,
	"partylider": party_set_leader,
	"acceptparty": party_accept_member,
	"ping": ping
}

static func process(newText: String, hub_controller:HubController, game_context:GameContext) -> bool:
	var text = newText.strip_edges()
	
	if text.begins_with("/"):
		if text.length() == 1:
			return false
			
		# Convertir a minúsculas para hacer comandos insensibles a mayúsculas/minúsculas
		var command_name = text.substr(1).split(" ")[0].to_lower()
		var args = ChatCommandArgs.new()
		args.parameters = text.substr(1).split(" ")
		args.parameters.remove_at(0)
		args.game_context = game_context
		args.hub_controller = hub_controller
		
		# Primero verificar comandos regulares
		if command_handler.has(command_name): 
			command_handler[command_name].call(args)
			return true
		
		# Si no es un comando regular, intentar como comando GM
		# El servidor validará permisos y ejecutará el comando
		if _try_gm_command(command_name, args):
			return true
		
	return false
	
		
static func quit(args:ChatCommandArgs) -> void:
	GameProtocol.WriteQuit()
	
	
static func request_stats(args:ChatCommandArgs) -> void:
	GameProtocol.WriteRequestStats()

	
static func invisible(args:ChatCommandArgs) -> void:
	GameProtocol.write_invisible()


static func meditate(args:ChatCommandArgs) -> void:
	if args.game_context.player_stats.mana == args.game_context.player_stats.max_mana:
		return
		
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡Estas muerto!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteMeditate()
	
static func resucitate(args:ChatCommandArgs) -> void:
	if args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡Ya estás vivo!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteResucitate()


static func change_description(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡Estas muerto!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var description = " ".join(args.parameters) if args.parameters.size() else ""
	GameProtocol.change_description(description)


static func open_vault(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡Estás muerto!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteBankStart()


static func deposit_gold(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡Estás muerto!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	if args.parameters.size() == 0:
		args.hub_controller.ShowConsoleMessage("Faltan parámetros. Utilice /depositar CANTIDAD.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var amount_str = args.parameters[0]
	if !amount_str.is_valid_int():
		args.hub_controller.ShowConsoleMessage("Cantidad incorrecta. Utilice /depositar CANTIDAD.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var amount = amount_str.to_int()
	if amount <= 0:
		args.hub_controller.ShowConsoleMessage("Cantidad incorrecta. Utilice /depositar CANTIDAD.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteBankDepositGold(amount)


static func withdraw_gold(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡Estás muerto!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	if args.parameters.size() == 0:
		args.hub_controller.ShowConsoleMessage("Faltan parámetros. Utilice /retirar CANTIDAD.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var amount_str = args.parameters[0]
	if !amount_str.is_valid_int():
		args.hub_controller.ShowConsoleMessage("Cantidad incorrecta. Utilice /retirar CANTIDAD.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var amount = amount_str.to_int()
	if amount <= 0:
		args.hub_controller.ShowConsoleMessage("Cantidad incorrecta. Utilice /retirar CANTIDAD.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteBankExtractGold(amount)


static func request_balance(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡Estás muerto!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteRequestAccountState()


static func request_online(args:ChatCommandArgs) -> void:
	GameProtocol.WriteOnline()


static func guild_leave(args:ChatCommandArgs) -> void:
	GameProtocol.WriteGuildLeave()


static func heal(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		GameProtocol.WriteResucitate()
		return
	
	GameProtocol.WriteHeal()


static func start_commerce(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡¡Estás muerto!!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	if args.game_context.trading:
		args.hub_controller.ShowConsoleMessage("Ya estás comerciando", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteCommerceStart()


static func gamble(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡¡Estás muerto!!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	if args.parameters.size() == 0:
		args.hub_controller.ShowConsoleMessage("Faltan parámetros. Utilice /apostar CANTIDAD.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var amount_str = args.parameters[0]
	if !amount_str.is_valid_int():
		args.hub_controller.ShowConsoleMessage("Cantidad incorrecta. Utilice /apostar CANTIDAD.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var amount = amount_str.to_int()
	if amount <= 0:
		args.hub_controller.ShowConsoleMessage("Cantidad incorrecta. Utilice /apostar CANTIDAD.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteGamble(amount)


# ===== COMANDOS DE MASCOTAS =====
static func pet_stand(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡¡Estás muerto!!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WritePetStand()


static func pet_follow(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡¡Estás muerto!!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WritePetFollow()


static func release_pet(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡¡Estás muerto!!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteReleasePet()


# ===== COMANDOS DE ENTRENAMIENTO Y DESCANSO =====
static func train_list(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡¡Estás muerto!!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteTrainList()


static func rest(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡¡Estás muerto!!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteRest()


# ===== COMANDOS DE INFORMACIÓN =====
static func consultation(args:ChatCommandArgs) -> void:
	GameProtocol.WriteConsultation()


static func help(args:ChatCommandArgs) -> void:
	GameProtocol.WriteHelp()


static func enlist(args:ChatCommandArgs) -> void:
	GameProtocol.WriteEnlist()


static func information(args:ChatCommandArgs) -> void:
	GameProtocol.WriteInformation()


static func reward(args:ChatCommandArgs) -> void:
	GameProtocol.WriteReward()


static func request_motd(args:ChatCommandArgs) -> void:
	GameProtocol.WriteRequestMOTD()


static func uptime(args:ChatCommandArgs) -> void:
	GameProtocol.WriteUpTime()


# ===== COMANDOS DE PARTY =====
static func party_leave(args:ChatCommandArgs) -> void:
	GameProtocol.WritePartyLeave()


static func party_create(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡¡Estás muerto!!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WritePartyCreate()


static func party_join(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡¡Estás muerto!!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WritePartyJoin()


static func share_npc(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡¡Estás muerto!!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteShareNpc()


static func stop_sharing_npc(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡¡Estás muerto!!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteStopSharingNpc()


static func party_kick(args:ChatCommandArgs) -> void:
	if args.parameters.size() == 0:
		args.hub_controller.ShowConsoleMessage("Faltan parámetros. Utilice /echarparty NICKNAME.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var nickname = args.parameters[0]
	GameProtocol.WritePartyKick(nickname)


static func party_set_leader(args:ChatCommandArgs) -> void:
	if args.parameters.size() == 0:
		args.hub_controller.ShowConsoleMessage("Faltan parámetros. Utilice /partylider NICKNAME.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var nickname = args.parameters[0]
	GameProtocol.WritePartySetLeader(nickname)


static func party_accept_member(args:ChatCommandArgs) -> void:
	if args.parameters.size() == 0:
		args.hub_controller.ShowConsoleMessage("Faltan parámetros. Utilice /acceptparty NICKNAME.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var nickname = args.parameters[0]
	GameProtocol.WritePartyAcceptMember(nickname)


# ===== COMANDOS DE ENCUESTAS Y MENSAJES =====
static func inquiry(args:ChatCommandArgs) -> void:
	if args.parameters.size() == 0:
		# Version sin argumentos: Inquiry
		GameProtocol.WriteInquiry()
	else:
		# Version con argumentos: InquiryVote
		var vote_str = args.parameters[0]
		if !vote_str.is_valid_int():
			args.hub_controller.ShowConsoleMessage("Para votar una opción, escribe /encuesta NUMERODEOPCION, por ejemplo para votar la opción 1, escribe /encuesta 1.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
			return
		
		var vote = vote_str.to_int()
		GameProtocol.WriteInquiryVote(vote)


static func guild_message(args:ChatCommandArgs) -> void:
	var message = " ".join(args.parameters) if args.parameters.size() > 0 else ""
	GameProtocol.WriteGuildMessage(message)


static func party_message(args:ChatCommandArgs) -> void:
	var message = " ".join(args.parameters) if args.parameters.size() > 0 else ""
	GameProtocol.WritePartyMessage(message)


static func centinel_report(args:ChatCommandArgs) -> void:
	if args.parameters.size() == 0:
		args.hub_controller.ShowConsoleMessage("Faltan parámetros. Utilice /centinela X, siendo X el código de verificación.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var code_str = args.parameters[0]
	if !code_str.is_valid_int():
		args.hub_controller.ShowConsoleMessage("El código de verificación debe ser numérico. Utilice /centinela X, siendo X el código de verificación.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var code = code_str.to_int()
	GameProtocol.WriteCentinelReport(code)


static func guild_online(args:ChatCommandArgs) -> void:
	GameProtocol.WriteGuildOnline()


static func party_online(args:ChatCommandArgs) -> void:
	GameProtocol.WritePartyOnline()


static func council_message(args:ChatCommandArgs) -> void:
	if args.parameters.size() == 0:
		args.hub_controller.ShowConsoleMessage("Escriba un mensaje.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var message = " ".join(args.parameters)
	GameProtocol.WriteCouncilMessage(message)


static func role_master_request(args:ChatCommandArgs) -> void:
	if args.parameters.size() == 0:
		args.hub_controller.ShowConsoleMessage("Escriba una pregunta.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var question = " ".join(args.parameters)
	GameProtocol.WriteRoleMasterRequest(question)


static func gm_request(args:ChatCommandArgs) -> void:
	GameProtocol.WriteGMRequest()


static func bug_report(args:ChatCommandArgs) -> void:
	if args.parameters.size() == 0:
		args.hub_controller.ShowConsoleMessage("Escriba una descripción del bug.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var description = " ".join(args.parameters)
	GameProtocol.WriteBugReport(description)


# ===== COMANDOS DE CLAN =====
static func guild_vote(args:ChatCommandArgs) -> void:
	if args.parameters.size() == 0:
		args.hub_controller.ShowConsoleMessage("Faltan parámetros. Utilice /voto NICKNAME.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var nickname = args.parameters[0]
	GameProtocol.WriteGuildVote(nickname)


static func punishments(args:ChatCommandArgs) -> void:
	if args.parameters.size() == 0:
		args.hub_controller.ShowConsoleMessage("Faltan parámetros. Utilice /penas NICKNAME.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var nickname = args.parameters[0]
	GameProtocol.WritePunishments(nickname)


static func guild_fundate(args:ChatCommandArgs) -> void:
	if args.game_context.player_level >= 25:
		GameProtocol.WriteGuildFundate()
	else:
		args.hub_controller.ShowConsoleMessage("Para fundar un clan tenés que ser nivel 25 y tener 90 skills en liderazgo.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])


# ===== COMANDOS VARIOS =====
static func change_password(args:ChatCommandArgs) -> void:
	args.hub_controller.show_password_change_window()


static func leave_faction(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡¡Estás muerto!!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteLeaveFaction()


static func denounce(args:ChatCommandArgs) -> void:
	if args.parameters.size() == 0:
		args.hub_controller.ShowConsoleMessage("Formule su denuncia.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var denounce_text = " ".join(args.parameters)
	GameProtocol.WriteDenounce(denounce_text)


# Comando ping para verificar latencia con el servidor
static func ping(args:ChatCommandArgs) -> void:
	# Enviar ping al servidor
	GameProtocol.WritePing()
	
	# Mostrar mensaje al usuario
	args.hub_controller.ShowConsoleMessage("Ping enviado al servidor...", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])

# Intenta ejecutar un comando GM usando los enums específicos del protocolo
static func _try_gm_command(command_name: String, args: Variant) -> bool:
	var cmd = command_name.to_upper()
	
	# Comandos GM específicos que tienen funciones dedicadas en el protocolo
	match cmd:
		"TELEP":
			if args.parameters.size() >= 3:
				var username = args.parameters[0]
				var map_num = int(args.parameters[1])
				var x = int(args.parameters[2])
				var y = int(args.parameters[3]) if args.parameters.size() > 3 else x
				# Usar la implementación estática para mantener consistencia con el resto del código
				GameProtocol.WriteWarpChar(username, map_num, x, y)
				args.hub_controller.ShowConsoleMessage("Teletransportando " + username, GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
				return true
		"INVISIBLE":
			# Verificar si existe la función en el protocolo estático
			if Global.game_protocol:
				Global.game_protocol.WriteInvisible()
				args.hub_controller.ShowConsoleMessage("Alternando invisibilidad", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
				return true
		"PANELGM":
			# Abrir panel GM local
			if Global.gm_command_system:
				Global.gm_command_system.show_gm_panel()
				args.hub_controller.ShowConsoleMessage("Abriendo panel GM", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
				return true
		_:
			# Para otros comandos GM, usar función genérica
			return _send_generic_gm_command(command_name, args)
	
	return false

# Envía un comando GM genérico usando el sistema de enums
static func _send_generic_gm_command(command_name: String, args: Variant) -> bool:
	# Crear el comando completo como string
	var full_command = "/" + command_name
	if args.parameters.size() > 0:
		full_command += " " + " ".join(args.parameters)
	
	# Usar el protocolo para enviar comando GM genérico
	_write_gm_command_generic(full_command)
	args.hub_controller.ShowConsoleMessage("Comando GM enviado: " + full_command, GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
	return true

# Función auxiliar para enviar comando GM genérico
static func _write_gm_command_generic(command: String) -> void:
	# Usar el protocolo para enviar un comando GM genérico
	# Crear un paquete GM_MESSAGE con el comando completo como texto
	GameProtocol.WriteGMCommand(command)
