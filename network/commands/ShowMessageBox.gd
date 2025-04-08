extends RefCounted
class_name ShowMessageBox

var message:String

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	message = Utils.GetUnicodeString(reader)
