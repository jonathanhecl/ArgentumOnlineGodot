extends RefCounted
class_name CharacterInfo

var name: String
var race: int
var job: int
var gender: int
var level: int
var gold: int
var bank_gold: int
var reputation: int
var requests: String
var current_guild: String
var member_info: String
var armada: bool
var caos: bool
var citizens_killed: int
var criminals_killed: int

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader: StreamPeerBuffer) -> void:
	name = Utils.GetUnicodeString(reader)
	race = reader.get_u8()
	job = reader.get_u8()
	gender = reader.get_u8()
	level = reader.get_u8()
	gold = reader.get_32()
	bank_gold = reader.get_32()
	reputation = reader.get_32()
	requests = Utils.GetUnicodeString(reader)
	current_guild = Utils.GetUnicodeString(reader)
	member_info = Utils.GetUnicodeString(reader)
	armada = reader.get_u8() != 0
	caos = reader.get_u8() != 0
	citizens_killed = reader.get_32()
	criminals_killed = reader.get_32()
