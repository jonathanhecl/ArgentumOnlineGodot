extends RefCounted
class_name EquitandoToggle

var arg1:int # LONG

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader:StreamPeerBuffer) -> void:
	arg1 = reader.get_32()
