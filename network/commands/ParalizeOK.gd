extends RefCounted
class_name ParalizeOK

var timeRemaining: int

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader: StreamPeerBuffer) -> void:
	timeRemaining = reader.get_16()
