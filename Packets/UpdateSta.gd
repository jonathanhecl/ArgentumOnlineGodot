extends RefCounted
class_name UpdateSta

var stamina:int 

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	stamina = reader.get_16() 
