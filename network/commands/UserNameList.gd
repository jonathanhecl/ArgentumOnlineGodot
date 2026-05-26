extends RefCounted
class_name UserNameList

var user_list: String

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader: StreamPeerBuffer) -> void:
	user_list = Utils.GetUnicodeString(reader)
