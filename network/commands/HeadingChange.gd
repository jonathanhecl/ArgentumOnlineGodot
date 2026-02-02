extends RefCounted
class_name HeadingChange

var charIndex: int
var heading: int

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader:
		Deserialize(reader)

func Deserialize(reader: StreamPeerBuffer) -> void:
	charIndex = reader.get_16()
	heading = reader.get_u8()
