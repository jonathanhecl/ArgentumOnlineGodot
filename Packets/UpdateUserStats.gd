extends RefCounted
class_name UpdateUserStats

var maxHp:int
var minHp:int

var maxMana:int
var minMana:int

var maxSta:int
var minSta:int

var gold:int
var elv:int
var elu:int
var experience:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	maxHp = reader.get_16();
	minHp = reader.get_16();
	maxMana = reader.get_16();
	minMana = reader.get_16();
	maxSta = reader.get_16();
	minSta = reader.get_16();
	gold = reader.get_32();
	elv = reader.get_u8();
	elu = reader.get_32();
	experience = reader.get_32();
