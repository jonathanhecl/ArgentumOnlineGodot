extends RefCounted
class_name GuildChat

var chat:String

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	chat = Utils.GetUnicodeString(reader)
