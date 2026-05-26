extends RefCounted
class_name FXtoMap

var loops: int
var x: int
var y: int
var fx_index: int

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader: StreamPeerBuffer) -> void:
	loops = reader.get_u8()
	x = reader.get_16()
	y = reader.get_16()
	fx_index = reader.get_16()
