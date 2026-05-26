extends RefCounted
class_name ShowUserRequest

var request: String

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader: StreamPeerBuffer) -> void:
	request = Utils.GetUnicodeString(reader)
