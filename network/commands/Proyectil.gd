extends RefCounted
class_name Proyectil

var arg1:int # INT
var arg2:int # INT
var arg3:int # INT

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader:StreamPeerBuffer) -> void:
	arg1 = reader.get_16()
	arg2 = reader.get_16()
	arg3 = reader.get_16()
