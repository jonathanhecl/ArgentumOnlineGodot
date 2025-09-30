extends RefCounted
class_name AllianceProposalsList

## Comando de red para recibir lista de propuestas de alianza
## Replica HandleAlianceProposalsList del Protocol.bas VB6
## Lista de clanes que han propuesto alianza

var guilds: Array = []

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader: StreamPeerBuffer) -> void:
	var guilds_string = Utils.GetUnicodeString(reader)
	if !guilds_string.is_empty():
		guilds = guilds_string.split(char(0), false)  # SEPARATOR es vbNullChar (Chr(0))
	else:
		guilds = []
