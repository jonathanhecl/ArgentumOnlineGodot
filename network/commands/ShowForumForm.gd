extends RefCounted
class_name ShowForumForm

var privileges: int
var canPostSticky: int

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader: StreamPeerBuffer) -> void:
	privileges = reader.get_u8()
	canPostSticky = reader.get_u8()
