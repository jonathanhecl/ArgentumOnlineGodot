extends RefCounted
class_name PlayMp3

var mp3Id: int
var loops: int

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader: StreamPeerBuffer) -> void:
	mp3Id = reader.get_16()
	loops = reader.get_16()
