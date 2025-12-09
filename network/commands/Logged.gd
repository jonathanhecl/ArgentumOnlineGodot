extends RefCounted
class_name Logged

# NOTA: El servidor AOGolang NO envía el byte de Redundance (AntiExternos está deshabilitado)
# Si tu servidor SÍ lo envía, descomenta la línea de Security.set_redundance

var userClass:int
var intervaloInvi:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	# Si el servidor tiene AntiExternos habilitado, descomentar esta línea:
	# var new_key = reader.get_u8()
	# Security.set_redundance(new_key)
	
	# Leer la clase del usuario
	userClass = reader.get_u8()
	
	# Leer el intervalo de invisibilidad (Long = 4 bytes)
	intervaloInvi = reader.get_32()
