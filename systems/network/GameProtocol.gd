extends Node
class_name GMProtocol

# Protocolo de red para comandos GM de Argentum Online
# Basado en las funciones Write* del cliente original

signal message_received(message_type: String, data: Dictionary)

# Tipos de mensajes del protocolo
enum MessageType {
	# GM Messages
	GM_MESSAGE = 1,
	SERVER_MESSAGE = 2,
	MAP_MESSAGE = 3,
	FACTION_MESSAGE = 4,
	
	# Teleport & Movement
	WARP_CHAR = 10,
	GO_TO_CHAR = 11,
	SUMMON_CHAR = 12,
	
	# Player Information
	REQUEST_CHAR_INFO = 20,
	REQUEST_CHAR_STATS = 21,
	REQUEST_CHAR_GOLD = 22,
	REQUEST_CHAR_INVENTORY = 23,
	REQUEST_CHAR_BANK = 24,
	REQUEST_CHAR_SKILLS = 25,
	WHERE_CHAR = 26,
	REQUEST_LAST_IP = 27,
	REQUEST_LAST_EMAIL = 28,
	
	# Punishment & Moderation
	JAIL_CHAR = 30,
	BAN_CHAR = 31,
	UNBAN_CHAR = 32,
	BAN_IP = 33,
	UNBAN_IP = 34,
	KICK_CHAR = 35,
	EXECUTE_CHAR = 36,
	WARN_USER = 37,
	SILENCE_CHAR = 38,
	MAKE_DUMB = 39,
	REMOVE_DUMB = 40,
	
	# Character Modification
	MODIFY_CHAR = 50,
	REVIVE_CHAR = 51,
	FORGIVE_CHAR = 52,
	CONDEMN_CHAR = 53,
	RESET_FACTIONS = 54,
	KICK_FROM_GUILD = 55,
	
	# Server Control
	SHOW_LIST = 60,
	ONLINE_GM = 61,
	ONLINE_MAP = 62,
	ONLINE_FACTION = 63,
	TOGGLE_SERVER = 64,
	SHUTDOWN_SERVER = 65,
	
	# World Manipulation
	CREATE_ITEM = 70,
	DESTROY_ITEMS = 71,
	CREATE_NPC = 72,
	CREATE_NPC_RESPAWN = 73,
	KILL_NPC = 74,
	KILL_NPC_NO_RESPAWN = 75,
	MASS_KILL = 76,
	CLEAN_WORLD = 77,
	RESET_NPC_INVENTORY = 78,
	
	# Audio/Visual
	FORCE_MIDI = 80,
	FORCE_WAV = 81,
	FORCE_MIDI_MAP = 82,
	FORCE_WAV_MAP = 83,
	TOGGLE_RAIN = 84,
	
	# Faction Management
	ACCEPT_COUNCIL_MEMBER = 90,
	KICK_COUNCIL_MEMBER = 91,
	KICK_FROM_FACTION = 92,
	
	# Administrative
	TOGGLE_INVISIBLE = 100,
	TOGGLE_WORKING = 101,
	TOGGLE_HIDING = 102,
	SHOW_NAME = 103,
	SERVER_TIME = 104,
	ADD_COMMENT = 105,
	SHOW_CREATURES = 106,
	SHOW_FLOOR_ITEMS = 107,
	TOGGLE_TILE_BLOCKED = 108,
	SET_TRIGGER = 109,
	TOGGLE_SENTINEL = 110,
	CHECK_SLOT = 111
}

# Referencia al cliente de red
var network_client: Node

func _ready():
	# Obtener referencia al cliente de red cuando esté disponible
	# TODO: Conectar con el sistema de red del juego
	pass

# === MESSAGING COMMANDS ===

func WriteGMMessage(message: String):
	_send_message(MessageType.GM_MESSAGE, {"message": message})

func WriteServerMessage(message: String):
	_send_message(MessageType.SERVER_MESSAGE, {"message": message})

func WriteMapMessage(message: String):
	_send_message(MessageType.MAP_MESSAGE, {"message": message})

func WriteFactionMessage(faction: String, message: String):
	_send_message(MessageType.FACTION_MESSAGE, {"faction": faction, "message": message})

# === TELEPORT & MOVEMENT ===

func WriteWarpChar(nick: String, map_id: int, x: int, y: int):
	_send_message(MessageType.WARP_CHAR, {
		"nick": nick,
		"map": map_id,
		"x": x,
		"y": y
	})

func WriteGoToChar(nick: String):
	_send_message(MessageType.GO_TO_CHAR, {"nick": nick})

func WriteSummonChar(nick: String):
	_send_message(MessageType.SUMMON_CHAR, {"nick": nick})

# === PLAYER INFORMATION ===

func WriteRequestCharInfo(nick: String):
	_send_message(MessageType.REQUEST_CHAR_INFO, {"nick": nick})

func WriteRequestCharStats(nick: String):
	_send_message(MessageType.REQUEST_CHAR_STATS, {"nick": nick})

func WriteRequestCharGold(nick: String):
	_send_message(MessageType.REQUEST_CHAR_GOLD, {"nick": nick})

func WriteRequestCharInventory(nick: String):
	_send_message(MessageType.REQUEST_CHAR_INVENTORY, {"nick": nick})

func WriteRequestCharBank(nick: String):
	_send_message(MessageType.REQUEST_CHAR_BANK, {"nick": nick})

func WriteRequestCharSkills(nick: String):
	_send_message(MessageType.REQUEST_CHAR_SKILLS, {"nick": nick})

func WriteWhereChar(nick: String):
	_send_message(MessageType.WHERE_CHAR, {"nick": nick})

func WriteRequestLastIP(nick: String):
	_send_message(MessageType.REQUEST_LAST_IP, {"nick": nick})

func WriteRequestLastEmail(nick: String):
	_send_message(MessageType.REQUEST_LAST_EMAIL, {"nick": nick})

# === PUNISHMENT & MODERATION ===

func WriteJailChar(nick: String, reason: String, time: int):
	_send_message(MessageType.JAIL_CHAR, {
		"nick": nick,
		"reason": reason,
		"time": time
	})

func WriteBanChar(nick: String, reason: String):
	_send_message(MessageType.BAN_CHAR, {
		"nick": nick,
		"reason": reason
	})

func WriteUnbanChar(nick: String):
	_send_message(MessageType.UNBAN_CHAR, {"nick": nick})

func WriteBanIP(ip_or_nick: String, reason: String):
	_send_message(MessageType.BAN_IP, {
		"target": ip_or_nick,
		"reason": reason
	})

func WriteUnbanIP(ip: String):
	_send_message(MessageType.UNBAN_IP, {"ip": ip})

func WriteKickChar(nick: String):
	_send_message(MessageType.KICK_CHAR, {"nick": nick})

func WriteExecuteChar(nick: String):
	_send_message(MessageType.EXECUTE_CHAR, {"nick": nick})

func WriteWarnUser(nick: String, reason: String):
	_send_message(MessageType.WARN_USER, {
		"nick": nick,
		"reason": reason
	})

func WriteSilenceChar(nick: String):
	_send_message(MessageType.SILENCE_CHAR, {"nick": nick})

func WriteMakeDumb(nick: String):
	_send_message(MessageType.MAKE_DUMB, {"nick": nick})

func WriteRemoveDumb(nick: String):
	_send_message(MessageType.REMOVE_DUMB, {"nick": nick})

# === CHARACTER MODIFICATION ===

func WriteModifyChar(nick: String, attribute: String, value: String, extra: String = ""):
	_send_message(MessageType.MODIFY_CHAR, {
		"nick": nick,
		"attribute": attribute,
		"value": value,
		"extra": extra
	})

func WriteReviveChar(nick: String):
	_send_message(MessageType.REVIVE_CHAR, {"nick": nick})

func WriteForgiveChar(nick: String):
	_send_message(MessageType.FORGIVE_CHAR, {"nick": nick})

func WriteCondemnChar(nick: String):
	_send_message(MessageType.CONDEMN_CHAR, {"nick": nick})

func WriteResetFactions(nick: String):
	_send_message(MessageType.RESET_FACTIONS, {"nick": nick})

func WriteKickFromGuild(nick: String):
	_send_message(MessageType.KICK_FROM_GUILD, {"nick": nick})

# === SERVER CONTROL ===

func WriteShowList(list_type: String):
	_send_message(MessageType.SHOW_LIST, {"type": list_type})

func WriteOnlineGM():
	_send_message(MessageType.ONLINE_GM, {})

func WriteOnlineMap(map_id: int = -1):
	_send_message(MessageType.ONLINE_MAP, {"map": map_id})

func WriteOnlineFaction(faction: String):
	_send_message(MessageType.ONLINE_FACTION, {"faction": faction})

func WriteToggleServer():
	_send_message(MessageType.TOGGLE_SERVER, {})

func WriteShutdownServer():
	_send_message(MessageType.SHUTDOWN_SERVER, {})

# === WORLD MANIPULATION ===

func WriteCreateItem(item_id: int):
	_send_message(MessageType.CREATE_ITEM, {"item_id": item_id})

func WriteDestroyItems():
	_send_message(MessageType.DESTROY_ITEMS, {})

func WriteCreateNPC(npc_id: int):
	_send_message(MessageType.CREATE_NPC, {"npc_id": npc_id})

func WriteCreateNPCRespawn(npc_id: int):
	_send_message(MessageType.CREATE_NPC_RESPAWN, {"npc_id": npc_id})

func WriteKillNPC():
	_send_message(MessageType.KILL_NPC, {})

func WriteKillNPCNoRespawn():
	_send_message(MessageType.KILL_NPC_NO_RESPAWN, {})

func WriteMassKill():
	_send_message(MessageType.MASS_KILL, {})

func WriteCleanWorld():
	_send_message(MessageType.CLEAN_WORLD, {})

func WriteResetNPCInventory():
	_send_message(MessageType.RESET_NPC_INVENTORY, {})

# === AUDIO/VISUAL ===

func WriteForceMIDI(midi_id: int):
	_send_message(MessageType.FORCE_MIDI, {"midi_id": midi_id})

func WriteForceWAV(wav_id: int):
	_send_message(MessageType.FORCE_WAV, {"wav_id": wav_id})

func WriteForceMIDIMap(midi_id: int, map_id: int = -1):
	_send_message(MessageType.FORCE_MIDI_MAP, {
		"midi_id": midi_id,
		"map": map_id
	})

func WriteForceWAVMap(wav_id: int, map_id: int = -1, x: int = -1, y: int = -1):
	_send_message(MessageType.FORCE_WAV_MAP, {
		"wav_id": wav_id,
		"map": map_id,
		"x": x,
		"y": y
	})

func WriteToggleRain():
	_send_message(MessageType.TOGGLE_RAIN, {})

# === FACTION MANAGEMENT ===

func WriteAcceptCouncilMember(nick: String, faction: String):
	_send_message(MessageType.ACCEPT_COUNCIL_MEMBER, {
		"nick": nick,
		"faction": faction
	})

func WriteKickCouncilMember(nick: String):
	_send_message(MessageType.KICK_COUNCIL_MEMBER, {"nick": nick})

func WriteKickFromFaction(nick: String, faction: String):
	_send_message(MessageType.KICK_FROM_FACTION, {
		"nick": nick,
		"faction": faction
	})

# === ADMINISTRATIVE ===

func WriteInvisible():
	_send_message(MessageType.TOGGLE_INVISIBLE, {})

func WriteWorking():
	_send_message(MessageType.TOGGLE_WORKING, {})

func WriteHiding():
	_send_message(MessageType.TOGGLE_HIDING, {})

func WriteShowName():
	_send_message(MessageType.SHOW_NAME, {})

func WriteServerTime():
	_send_message(MessageType.SERVER_TIME, {})

func WriteAddComment(comment: String):
	_send_message(MessageType.ADD_COMMENT, {"comment": comment})

func WriteShowCreatures(map_id: int = -1):
	_send_message(MessageType.SHOW_CREATURES, {"map": map_id})

func WriteShowFloorItems():
	_send_message(MessageType.SHOW_FLOOR_ITEMS, {})

func WriteToggleTileBlocked():
	_send_message(MessageType.TOGGLE_TILE_BLOCKED, {})

func WriteSetTrigger(trigger_id: int = -1):
	_send_message(MessageType.SET_TRIGGER, {"trigger": trigger_id})

func WriteToggleSentinel():
	_send_message(MessageType.TOGGLE_SENTINEL, {})

func WriteCheckSlot(nick: String, slot: int):
	_send_message(MessageType.CHECK_SLOT, {
		"nick": nick,
		"slot": slot
	})

# === UTILIDADES ===

# Enviar mensaje al servidor
func _send_message(msg_type: MessageType, data: Dictionary):
	var message = {
		"type": msg_type,
		"data": data,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# TODO: Implementar envío real al servidor
	print("Enviando comando GM: ", MessageType.keys()[msg_type], " - ", data)
	
	# Simular respuesta del servidor para testing
	_simulate_server_response(msg_type, data)

# Simular respuesta del servidor (para testing)
func _simulate_server_response(msg_type: MessageType, data: Dictionary):
	await get_tree().create_timer(0.1).timeout
	
	var response_data = {}
	var response_message = ""
	
	match msg_type:
		MessageType.GM_MESSAGE:
			response_message = "Mensaje GM enviado: " + data.message
		MessageType.GO_TO_CHAR:
			response_message = "Teletransportándose a " + data.nick
		MessageType.SUMMON_CHAR:
			response_message = "Invocando a " + data.nick
		MessageType.REQUEST_CHAR_INFO:
			response_message = "Información de " + data.nick + " solicitada"
			response_data = {
				"nick": data.nick,
				"level": 50,
				"class": "Mago",
				"guild": "Los Magos Supremos",
				"status": "Online"
			}
		MessageType.ONLINE_GM:
			response_message = "GMs Online: Admin, GameMaster1, GameMaster2"
		MessageType.SERVER_TIME:
			response_message = "Hora del servidor: " + Time.get_datetime_string_from_system()
		_:
			response_message = "Comando ejecutado correctamente"
	
	message_received.emit(MessageType.keys()[msg_type], {
		"message": response_message,
		"data": response_data
	})

# Validar número
func ValidNumber(value: String, number_type: String) -> bool:
	match number_type:
		"integer":
			return value.is_valid_int()
		"float":
			return value.is_valid_float()
		"byte":
			var num = value.to_int()
			return value.is_valid_int() and num >= 0 and num <= 255
		_:
			return false

# Mostrar mensaje en consola
func ShowConsoleMsg(message: String):
	print("Console: " + message)
	# TODO: Mostrar en la consola del juego
