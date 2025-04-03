extends RefCounted
class_name ErrorMsg

var message:String

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader:StreamPeerBuffer) -> void:
	message = Utils.GetUnicodeString(reader)
