extends RefCounted
class_name ShowGMPanelForm

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(_reader: StreamPeerBuffer) -> void:
	pass
