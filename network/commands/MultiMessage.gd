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
	
	# Debug para TODOS los mensajes
	print("⚠️ MultiMessage: Procesando índice ", index)
	
	# Debug para identificar mensajes no reconocidos
	if index >= 48:  # El enum Messages solo va hasta 47
		print("⚠️ MultiMessage: Índice no reconocido ", index, ". Consumiendo bytes restantes...")
		var remaining = reader.get_size() - reader.get_position()
		print("⚠️ MultiMessage: Consumiendo ", remaining, " bytes restantes")
		reader.seek(reader.get_size())  # Saltar todos los bytes restantes
		return
	
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
