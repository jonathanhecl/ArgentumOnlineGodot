extends RefCounted
class_name AddSlots

var max_inventory_slots: int

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader: StreamPeerBuffer) -> void:
	max_inventory_slots = reader.get_u8()
