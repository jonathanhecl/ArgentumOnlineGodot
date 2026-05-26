extends RefCounted
class_name RecordDetails

var creator: String
var description: String
var online: bool
var ip: String
var time_on: String
var observations: String

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader: StreamPeerBuffer) -> void:
	creator = Utils.GetUnicodeString(reader)
	description = Utils.GetUnicodeString(reader)
	online = reader.get_u8() != 0
	ip = Utils.GetUnicodeString(reader)
	time_on = Utils.GetUnicodeString(reader)
	observations = Utils.GetUnicodeString(reader)
