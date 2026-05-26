extends RefCounted
class_name ShowMOTDEditionForm

var motd: String

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader: StreamPeerBuffer) -> void:
	motd = Utils.GetUnicodeString(reader)
