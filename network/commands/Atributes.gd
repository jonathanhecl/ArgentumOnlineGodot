extends RefCounted
class_name Atributes

var attributes: Array[int] = []  # [Fuerza, Agilidad, Inteligencia, Carisma, Constitución]

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader:
		Deserialize(reader)

func Deserialize(reader: StreamPeerBuffer) -> void:
	# En el cliente clásico se leen NUMATRIBUTES bytes. Aquí usamos 5 (FAICC).
	attributes.clear()
	for i in range(5):
		attributes.append(reader.get_u8())
