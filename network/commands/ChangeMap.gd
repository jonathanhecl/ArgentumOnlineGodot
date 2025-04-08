extends RefCounted
class_name ChangeMap

var mapId:int
var version:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	mapId = reader.get_16()
	version = reader.get_16()
