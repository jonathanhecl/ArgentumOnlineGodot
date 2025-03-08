extends RefCounted
class_name UpdateBankGold

var gold:int 

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	gold = reader.get_32() 
