extends RefCounted
class_name UserCommerceInit

var trading_username:String

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader:StreamPeerBuffer) -> void:
	trading_username = Utils.GetUnicodeString(reader)
