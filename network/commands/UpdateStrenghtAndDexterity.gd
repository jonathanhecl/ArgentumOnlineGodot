extends RefCounted
class_name UpdateStrengthAndDexterity

var strength:int
var dexterity:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	strength = reader.get_u8()
	dexterity = reader.get_u8()
