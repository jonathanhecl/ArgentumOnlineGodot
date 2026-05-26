extends RefCounted
class_name PalabrasMagicas

var spell: int
var char_index: int

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader: StreamPeerBuffer) -> void:
	spell = reader.get_u8()
	char_index = reader.get_16()
