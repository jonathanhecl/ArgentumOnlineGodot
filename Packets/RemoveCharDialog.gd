extends RefCounted
class_name RemoveCharDialog

var charIndex:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	charIndex = reader.get_16()	
