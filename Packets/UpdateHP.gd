extends Node
class_name UpdateHP

var hp:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	hp = reader.get_16()	
