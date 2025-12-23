extends RefCounted
class_name ShowProcess

var arg1:String # ASCII
var arg2:String # ASCII

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader:StreamPeerBuffer) -> void:
	arg1 = Utils.GetUnicodeString(reader)
	arg2 = Utils.GetUnicodeString(reader)
