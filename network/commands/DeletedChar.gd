extends RefCounted
class_name DeletedChar

var arg1:int # BYTE

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader:StreamPeerBuffer) -> void:
	arg1 = reader.get_u8()
