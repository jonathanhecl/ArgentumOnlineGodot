extends RefCounted
class_name InitCarpenting

var arg1:int # INT
var arg2:String # ASCII
var arg3:int # LONG
var arg4:int # INT
var arg5:int # INT
var arg6:int # INT
var arg7:int # INT

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader:StreamPeerBuffer) -> void:
	arg1 = reader.get_16()
	arg2 = Utils.GetUnicodeString(reader)
	arg3 = reader.get_32()
	arg4 = reader.get_16()
	arg5 = reader.get_16()
	arg6 = reader.get_16()
	arg7 = reader.get_16()
