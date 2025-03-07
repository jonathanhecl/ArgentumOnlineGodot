extends RefCounted
class_name ForceCharMove

var heading:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void: 
	heading = reader.get_u8()
