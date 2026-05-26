extends RefCounted
class_name QuestListSend

var arg1: int # BYTE
var arg2: String # ASCII

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader: StreamPeerBuffer) -> void:
	arg1 = reader.get_u8()
	if arg1 > 0:
		arg2 = Utils.GetUnicodeString(reader)
	else:
		arg2 = ""
