extends RefCounted
class_name EnviarListDeAmigos

var arg1:int # BYTE
var arg2:String # ASCII

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader:StreamPeerBuffer) -> void:
	arg1 = reader.get_u8()
	arg2 = Utils.GetUnicodeString(reader)
