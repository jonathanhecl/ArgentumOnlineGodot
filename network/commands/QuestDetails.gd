extends RefCounted
class_name QuestDetails

var arg1:int # BYTE
var arg2:String # ASCII
var arg3:String # ASCII
var arg4:int # BYTE
var arg5:int # BYTE
var arg6:int # INT
var arg7:int # INT
var arg8:int # BYTE
var arg9:int # INT
var arg10:int # LONG
var arg11:int # LONG
var arg12:int # BYTE
var arg13:int # INT

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader:StreamPeerBuffer) -> void:
	arg1 = reader.get_u8()
	arg2 = Utils.GetUnicodeString(reader)
	arg3 = Utils.GetUnicodeString(reader)
	arg4 = reader.get_u8()
	arg5 = reader.get_u8()
	arg6 = reader.get_16()
	arg7 = reader.get_16()
	arg8 = reader.get_u8()
	arg9 = reader.get_16()
	arg10 = reader.get_32()
	arg11 = reader.get_32()
	arg12 = reader.get_u8()
	arg13 = reader.get_16()
