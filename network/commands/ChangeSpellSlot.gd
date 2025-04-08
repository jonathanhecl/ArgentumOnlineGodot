extends RefCounted
class_name ChangeSpellSlot

var slot:int
var spellId:int
var name:String

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	slot = reader.get_u8();
	spellId = reader.get_16();
	name = Utils.GetUnicodeString(reader)
