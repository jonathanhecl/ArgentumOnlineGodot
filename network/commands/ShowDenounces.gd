extends RefCounted
class_name ShowDenounces

var denounces: String

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader: StreamPeerBuffer) -> void:
	denounces = Utils.GetUnicodeString(reader)
