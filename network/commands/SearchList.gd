extends RefCounted
class_name SearchList

var arg1:int # INT
var arg2:bool # BOOLEAN
var arg3:String # ASCII

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader:StreamPeerBuffer) -> void:
	arg1 = reader.get_16()
	arg2 = reader.get_u8() != 0
	arg3 = Utils.GetUnicodeString(reader)
