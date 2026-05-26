extends RefCounted
class_name ShowSOSForm

var sos_list: String

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader: StreamPeerBuffer) -> void:
	sos_list = Utils.GetUnicodeString(reader)
