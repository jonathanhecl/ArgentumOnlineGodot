extends RefCounted
class_name CharacterChangeNick

var char_index:int
var char_name:String

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader:StreamPeerBuffer) -> void:
	char_index = reader.get_16()
	char_name = Utils.GetUnicodeString(reader)
