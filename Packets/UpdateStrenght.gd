extends RefCounted
class_name UpdateStrenght

var strenght:int 

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	strenght = reader.get_u8() 
