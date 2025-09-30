extends RefCounted
class_name GuildMemberInfo

## Comando de red para recibir información de miembro de clan
## Replica HandleGuildMemberInfo del Protocol.bas VB6
## Se envía cuando el jugador tiene clan pero NO es líder

var guild_names: Array = []
var guild_members: Array = []

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader: StreamPeerBuffer) -> void:
	# Leer lista de clanes (separados por SEPARATOR)
	var guilds_string = Utils.GetUnicodeString(reader)
	if !guilds_string.is_empty():
		guild_names = guilds_string.split(char(0), false)  # SEPARATOR es vbNullChar (Chr(0))
	else:
		guild_names = []
	
	# Leer lista de miembros del clan (separados por SEPARATOR)
	var members_string = Utils.GetUnicodeString(reader)
	if !members_string.is_empty():
		guild_members = members_string.split(char(0), false)
	else:
		guild_members = []
