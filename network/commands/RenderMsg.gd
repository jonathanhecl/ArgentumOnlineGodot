extends RefCounted
class_name RenderMsg

var arg1:String # ASCII
var arg2:int # INT

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader:StreamPeerBuffer) -> void:
	arg1 = Utils.GetUnicodeString(reader)
	arg2 = reader.get_16()
