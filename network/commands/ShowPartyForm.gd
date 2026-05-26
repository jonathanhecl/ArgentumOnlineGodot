extends RefCounted
class_name ShowPartyForm

var is_party_leader: bool
var members: String
var total_exp: int

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader: StreamPeerBuffer) -> void:
	is_party_leader = reader.get_u8() != 0
	members = Utils.GetUnicodeString(reader)
	total_exp = reader.get_32()
