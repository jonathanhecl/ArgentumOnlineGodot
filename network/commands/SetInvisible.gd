extends RefCounted
class_name SetInvisible

var charIndex:int
var invisible:bool

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	charIndex = reader.get_16()
	invisible = reader.get_u8()
