extends RefCounted
class_name PlayWave

var wave:int
var x:int
var y:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	wave = reader.get_u8()	
	x = reader.get_u8()
	y = reader.get_u8()
