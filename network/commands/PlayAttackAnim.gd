extends RefCounted
class_name PlayAttackAnim

var char_index: int

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader: StreamPeerBuffer) -> void:
	char_index = reader.get_16()
