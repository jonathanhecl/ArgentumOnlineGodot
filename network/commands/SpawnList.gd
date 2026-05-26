extends RefCounted
class_name SpawnList

var creatures: String

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader: StreamPeerBuffer) -> void:
	creatures = Utils.GetUnicodeString(reader)
