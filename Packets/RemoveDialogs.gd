extends Node
class_name RemoveDialogs

var charIndex:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	charIndex = reader.get_16()
