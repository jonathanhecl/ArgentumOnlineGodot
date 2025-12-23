extends RefCounted
class_name MultiMessage

var index:int
var arg1:int
var arg2:int
var arg3:int
var string_arg1:String

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	# El MultiMessage es un paquete batch que contiene otros paquetes
	# Solo leemos el encabezado y dejamos el resto del buffer intacto
	
	# Guardar posición inicial
	var start_pos = reader.get_position()
	
	# Leer solo el encabezado del MultiMessage
	index = reader.get_u8()  # Índice del mensaje (7 en este caso)
	
	# Calcular cuántos bytes quedan para los paquetes incrustados
	var remaining_bytes = reader.get_size() - reader.get_position()
	
	print("⚠️ MultiMessage: Índice ", index, " procesado. Quedan ", remaining_bytes, " bytes de datos del personaje.")
	
	# NO consumir más bytes del buffer. Los paquetes incrustados serán procesados
	# por el protocol_handler principal que continuará leyendo desde aquí.
