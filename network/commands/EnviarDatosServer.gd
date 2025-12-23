extends RefCounted
class_name EnviarDatosServer

var arg1:String # ASCII
var arg2:String # ASCII
var arg3:String # ASCII
var arg4:int # INT
var arg5:int # INT
var arg6:int # INT
var arg7:int # INT
var arg8:int # INT
var arg9:int # INT

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader:StreamPeerBuffer) -> void:
	arg1 = Utils.GetUnicodeString(reader)
	arg2 = Utils.GetUnicodeString(reader)
	arg3 = Utils.GetUnicodeString(reader)
	arg4 = reader.get_16()
	arg5 = reader.get_16()
	arg6 = reader.get_16()
	arg7 = reader.get_16()
	arg8 = reader.get_16()
	arg9 = reader.get_16()
