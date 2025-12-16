extends RefCounted
class_name ObjectCreate

var x:int
var y:int
var grhId:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	x = reader.get_u8()
	y = reader.get_u8()
	grhId = reader.get_32()  # ReadLong() en VB6 = 4 bytes
