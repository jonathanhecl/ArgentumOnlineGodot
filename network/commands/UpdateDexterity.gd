extends RefCounted
class_name UpdateDexterity

var dexterity:int 

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	dexterity = reader.get_u8() 
	reader.get_32() # Unused LONG param 
