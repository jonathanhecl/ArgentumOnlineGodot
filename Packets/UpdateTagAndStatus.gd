extends RefCounted
class_name UpdateTagAndStatus

var charIndex:int
var nickColor:int
var userTag:String

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	charIndex = reader.get_16()
	nickColor = reader.get_u8()
	userTag = Utils.GetUnicodeString(reader)
