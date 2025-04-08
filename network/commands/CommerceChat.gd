extends RefCounted
class_name CommerceChat

var message:String
var font_index:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader:StreamPeerBuffer) -> void:
	message = Utils.GetUnicodeString(reader)
	font_index = reader.get_u8()
