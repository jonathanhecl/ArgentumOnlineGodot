extends RefCounted
class_name GuildLeaderInfo

## Comando de red para recibir información del líder del clan
## Replica HandleGuildLeaderInfo del Protocol.bas VB6

var guild_names: Array = []
var guild_members: Array = []
var guild_news: String = ""
var guild_requests: Array = []

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader: StreamPeerBuffer) -> void:
	print("[DEBUG] GuildLeaderInfo.Deserialize iniciado")
	
	# Leer lista de clanes como string único y hacer split
	var guilds_string = Utils.GetUnicodeString(reader)
	print("[DEBUG] guilds_string recibido, length: ", guilds_string.length())
	if !guilds_string.is_empty():
		# Split por Chr(0) que es el SEPARATOR en VB6
		guild_names = guilds_string.split(char(0), false)
		print("[DEBUG] guild_names count: ", guild_names.size())
	else:
		guild_names = []
	
	# Leer lista de miembros
	var members_string = Utils.GetUnicodeString(reader)
	print("[DEBUG] members_string recibido, length: ", members_string.length())
	if !members_string.is_empty():
		guild_members = members_string.split(char(0), false)
		print("[DEBUG] guild_members count: ", guild_members.size())
	else:
		guild_members = []
	
	# Leer noticias del clan
	guild_news = Utils.GetUnicodeString(reader)
	print("[DEBUG] guild_news recibido, length: ", guild_news.length())
	
	# Leer lista de solicitudes
	var requests_string = Utils.GetUnicodeString(reader)
	print("[DEBUG] requests_string recibido, length: ", requests_string.length())
	if !requests_string.is_empty():
		guild_requests = requests_string.split(char(0), false)
		print("[DEBUG] guild_requests count: ", guild_requests.size())
	else:
		guild_requests = []
	
	print("[DEBUG] GuildLeaderInfo.Deserialize completado exitosamente")
