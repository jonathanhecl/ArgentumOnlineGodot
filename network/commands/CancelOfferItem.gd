extends RefCounted
class_name CancelOfferItem

var slot:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader:StreamPeerBuffer) -> void:
	slot = reader.get_u8()
