extends RefCounted
class_name Logged
var userClass:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	# Leer la clave de cifrado del servidor (como en VB6: Security.Redundance = incomingData.ReadByte())
	var new_key = reader.get_u8()
	Security.set_redundance(new_key)
	
	# Leer la clase del usuario
	userClass = reader.get_u8()
