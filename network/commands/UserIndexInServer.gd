extends RefCounted
class_name UserIndexInServer

var userIndex:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	userIndex = reader.get_16()
