extends RefCounted
class_name GuildNews

## Comando de red para recibir noticias del clan
## Replica HandleGuildNews del Protocol.bas VB6
## Parsea noticias, enemigos y aliados

var news: String = ""
var enemy_guilds: Array = []
var allied_guilds: Array = []

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader: StreamPeerBuffer) -> void:
	# Leer noticias del clan
	news = Utils.GetUnicodeString(reader)
	
	# Leer lista de clanes enemigos (separados por SEPARATOR)
	var enemies_string = Utils.GetUnicodeString(reader)
	if !enemies_string.is_empty():
		enemy_guilds = enemies_string.split(char(0), false)  # SEPARATOR es vbNullChar (Chr(0))
	else:
		enemy_guilds = []
	
	# Leer lista de clanes aliados (separados por SEPARATOR)
	var allies_string = Utils.GetUnicodeString(reader)
	if !allies_string.is_empty():
		allied_guilds = allies_string.split(char(0), false)
	else:
		allied_guilds = []
