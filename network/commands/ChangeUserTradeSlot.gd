extends RefCounted
class_name ChangeUserTradeSlot

# Estructura según PROTOCOL_DOCS_NUEVO.txt:
# BYTE, BYTE, INT, LONG, LONG, BYTE, INT, INT, INT, INT, LONG, ASCII, BOOLEAN

var arg1:int # BYTE
var arg2:int # BYTE
var arg3:int # INT
var arg4:int # LONG
var arg5:int # LONG
var arg6:int # BYTE
var arg7:int # INT
var arg8:int # INT
var arg9:int # INT
var arg10:int # INT
var arg11:int # LONG
var arg12:String # ASCII
var arg13:bool # BOOLEAN

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader:StreamPeerBuffer) -> void:
	arg1 = reader.get_u8()
	arg2 = reader.get_u8()
	arg3 = reader.get_16()
	arg4 = reader.get_32()
	arg5 = reader.get_32()
	arg6 = reader.get_u8()
	arg7 = reader.get_16()
	arg8 = reader.get_16()
	arg9 = reader.get_16()
	arg10 = reader.get_16()
	arg11 = reader.get_32()
	arg12 = Utils.GetUnicodeString(reader)
	arg13 = reader.get_u8() != 0
