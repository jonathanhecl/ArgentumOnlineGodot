extends RefCounted
class_name DiceRoll

var strength: int
var agility: int
var intelligence: int
var charisma: int
var constitution: int

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader: StreamPeerBuffer) -> void:
	strength = reader.get_u8()
	agility = reader.get_u8()
	intelligence = reader.get_u8()
	charisma = reader.get_u8()
	constitution = reader.get_u8()
