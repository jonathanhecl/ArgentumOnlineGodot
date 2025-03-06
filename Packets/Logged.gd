extends Node
class_name Logged
var userClass:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	userClass = reader.get_u8()
