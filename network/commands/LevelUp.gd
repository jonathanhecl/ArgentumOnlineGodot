extends RefCounted
class_name LevelUp

var skillPoints:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	skillPoints = reader.get_16()
	
	# Guardar los skill points en global.gd
	Global.skillPoints = skillPoints
