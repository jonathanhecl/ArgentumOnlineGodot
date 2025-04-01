extends RefCounted
class_name UpdateMana

var min_mana:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader:StreamPeerBuffer) -> void: 
	min_mana = reader.get_16()
