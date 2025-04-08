extends RefCounted
class_name SendNight

var value:bool

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader:StreamPeerBuffer) -> void:
	value = reader.get_u8()
