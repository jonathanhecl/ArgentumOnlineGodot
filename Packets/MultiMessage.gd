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
		Enums.Messages.NPCHitUser:
			arg1 = reader.get_u8()
			arg2 = reader.get_16()
			
		Enums.Messages.UserHitNPC:
			arg1 = reader.get_32()
			
		Enums.Messages.UserAttackedSwing:
			arg1 = reader.get_16()
			
		Enums.Messages.UserHittedByUser, Enums.Messages.UserHittedUser:
			arg1 = reader.get_16()
			arg2 = reader.get_u8()
			arg3 = reader.get_16()
			
		Enums.Messages.WorkRequestTarget:
			arg1 = reader.get_u8()
			
		Enums.Messages.HaveKilledUser:
			arg1 = reader.get_16()
			arg2 = reader.get_32()
			
		Enums.Messages.UserKill:
			arg1 = reader.get_16()
			
		Enums.Messages.Home:
			arg1 = reader.get_u8()
			arg2 = reader.get_16()
			string_arg1 = Utils.GetUnicodeString(reader)
