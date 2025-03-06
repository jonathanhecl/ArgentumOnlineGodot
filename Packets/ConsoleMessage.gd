extends RefCounted
class_name ConsoleMessage

var message:String
var fontIndex:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	message = Utils.GetUnicodeString(reader)
	fontIndex = reader.get_u8()
