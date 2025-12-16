extends RefCounted
class_name ChangeMap

var mapId:int
var nameMap:String
var zone:String

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	mapId = reader.get_16()  # ReadInteger() en VB6
	nameMap = Utils.GetUnicodeString(reader)  # ReadASCIIString() en VB6
	zone = Utils.GetUnicodeString(reader)  # ReadASCIIString() en VB6
