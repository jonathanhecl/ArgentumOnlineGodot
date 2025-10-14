extends RefCounted
class_name TrainerCreatureList

## Comando de red para recibir lista de criaturas de entrenamiento
## Replica HandleTrainerCreatureList del Protocol.bas VB6
## Se envía cuando el jugador pide entrenar con un NPC maestro

var creatures: Array[String] = []

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader: StreamPeerBuffer) -> void:
	var creatures_string = Utils.GetUnicodeString(reader)
	if !creatures_string.is_empty():
		var packed_creatures = creatures_string.split(char(0), false)  # SEPARATOR es vbNullChar (Chr(0))
		creatures.assign(packed_creatures)  # Convertir PackedStringArray a Array[String]
