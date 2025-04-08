extends RefCounted
class_name ShowSignal

var message:String
var unknown:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader:StreamPeerBuffer) -> void:
	message = Utils.GetUnicodeString(reader)
	unknown = reader.get_16()
