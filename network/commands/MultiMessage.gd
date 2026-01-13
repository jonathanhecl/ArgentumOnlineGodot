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
	# MultiMessage tiene argumentos variables según el tipo de mensaje
	# Debemos consumir TODOS los bytes del mensaje para no desincronizar el stream
	
	index = reader.get_u8()
	
	# Consumir argumentos según el tipo de mensaje (basado en VB6 HandleMultiMessage)
	match index:
		Enums.Messages.NPCSwing, \
		Enums.Messages.NPCKillUser, \
		Enums.Messages.BlockedWithShieldUser, \
		Enums.Messages.BlockedWithShieldOther, \
		Enums.Messages.UserSwing, \
		Enums.Messages.SafeModeOn, \
		Enums.Messages.SafeModeOff, \
		Enums.Messages.ResuscitationSafeOff, \
		Enums.Messages.ResuscitationSafeOn, \
		Enums.Messages.NobilityLost, \
		Enums.Messages.CantUseWhileMeditating, \
		Enums.Messages.NPCKill, \
		Enums.Messages.CancelGoHome, \
		Enums.Messages.FinishHome, \
		Enums.Messages.UserMuerto, \
		Enums.Messages.NpcInmune:
			# Sin argumentos adicionales
			pass
		
		Enums.Messages.NPCHitUser:
			# BodyPart (byte) + Damage (integer/2 bytes)
			arg1 = reader.get_u8()  # body part
			arg2 = reader.get_16()  # damage
		
		Enums.Messages.UserHitNPC:
			# Damage (long/4 bytes)
			arg1 = reader.get_32()
		
		Enums.Messages.UserAttackedSwing:
			# CharIndex (integer/2 bytes)
			arg1 = reader.get_16()
		
		Enums.Messages.UserHittedByUser, \
		Enums.Messages.UserHittedUser:
			# CharIndex (integer) + BodyPart (byte) + Damage (integer)
			arg1 = reader.get_16()  # char index
			arg2 = reader.get_u8()  # body part
			arg3 = reader.get_16()  # damage
		
		Enums.Messages.WorkRequestTarget:
			# SkillId (byte)
			arg1 = reader.get_u8()
		
		Enums.Messages.HaveKilledUser:
			# CharIndex (integer) + Exp (long)
			arg1 = reader.get_16()  # killed user index
			arg2 = reader.get_32()  # exp gained
		
		Enums.Messages.UserKill:
			# CharIndex (integer)
			arg1 = reader.get_16()
		
		Enums.Messages.EarnExp:
			# Exp (long/4 bytes)
			arg1 = reader.get_32()
		
		Enums.Messages.GoHome:
			# Distance (byte) + Time (integer) + HomeName (string)
			arg1 = reader.get_u8()   # distance
			arg2 = reader.get_16()   # time in seconds
			string_arg1 = Utils.GetUnicodeString(reader)  # home name
		
		Enums.Messages.Hechizo_HechiceroMSG_NOMBRE:
			# SpellIndex (byte) + Name (string)
			arg1 = reader.get_u8()
			string_arg1 = Utils.GetUnicodeString(reader)
		
		Enums.Messages.Hechizo_HechiceroMSG_ALGUIEN, \
		Enums.Messages.Hechizo_HechiceroMSG_CRIATURA, \
		Enums.Messages.Hechizo_PropioMSG:
			# SpellIndex (byte)
			arg1 = reader.get_u8()
		
		Enums.Messages.Hechizo_TargetMSG:
			# SpellIndex (byte) + Name (string)
			arg1 = reader.get_u8()
			string_arg1 = Utils.GetUnicodeString(reader)
		
		_:
			print("⚠️ MultiMessage: Índice desconocido ", index, " - posible desincronización")
