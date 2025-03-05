extends RefCounted
class_name UpdateHungerAndThirst

var maxAgua:int
var minAgua:int

var maxHam:int
var minHam:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	maxAgua = reader.get_u8();
	minAgua = reader.get_u8();
	maxHam  = reader.get_u8();
	minHam  = reader.get_u8();
