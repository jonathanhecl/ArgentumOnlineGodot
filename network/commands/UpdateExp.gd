extends RefCounted
class_name UpdateExp

var experience:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	experience = reader.get_32() 
