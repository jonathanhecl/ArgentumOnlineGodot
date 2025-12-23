extends RefCounted
class_name InitCraftman

var arg1:int # LONG
var arg2:int # INT
var arg3:String # ASCII
var arg4:int # LONG
var arg5:int # INT
var arg6:int # BYTE
var arg7:String # ASCII
var arg8:int # LONG
var arg9:int # INT
var arg10:int # INT

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader:StreamPeerBuffer) -> void:
	arg1 = reader.get_32()
	arg2 = reader.get_16()
	arg3 = Utils.GetUnicodeString(reader)
	arg4 = reader.get_32()
	arg5 = reader.get_16()
	arg6 = reader.get_u8()
	arg7 = Utils.GetUnicodeString(reader)
	arg8 = reader.get_32()
	arg9 = reader.get_16()
	arg10 = reader.get_16()
