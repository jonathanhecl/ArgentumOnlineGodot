extends RefCounted
class_name ChatOverHead

var chat:String
var charIndex:int
var color:Color

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void: 
	chat = Utils.GetUnicodeString(reader)
	charIndex = reader.get_16()
	color = Color.from_rgba8(reader.get_u8(), reader.get_u8(), reader.get_u8())
