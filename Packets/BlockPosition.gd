extends RefCounted
class_name BlockPosition

var x:int
var y:int
var blocked:bool

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	x = reader.get_u8()
	y = reader.get_u8()
	blocked = reader.get_u8()
