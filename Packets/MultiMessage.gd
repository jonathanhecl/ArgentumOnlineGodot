extends RefCounted
class_name MultiMessage

var index:int
var arg1:int
var arg2:int
var arg3:int
var string_arg1:String

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	index = reader.get_u8()
	
	match index:
		12:
			arg1 = reader.get_u8()
			arg2 = reader.get_16()
		13:
			arg1 = reader.get_32()
		14:
			arg1 = reader.get_16()
		15, 16:
			arg1 = reader.get_16()
			arg2 = reader.get_u8()
			arg3 = reader.get_16()
		17:
			arg1 = reader.get_16()
		18:
			arg1 = reader.get_16()
			arg2 = reader.get_32()
		19:
			arg1 = reader.get_16()
		21:
			arg1 = reader.get_u8()
			arg2 = reader.get_16()
			string_arg1 = reader.get_utf8_string()
