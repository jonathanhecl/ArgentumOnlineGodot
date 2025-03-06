extends RefCounted
class_name SendSkills

class Skill:
	var level:int
	var experience:int

var skills:Array[Skill]

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void: 
	for i in Consts.MaxSkills:
		var skill = Skill.new()
		skill.level = reader.get_u8()
		skill.experience = reader.get_u8() 
		skills.append(skill) 
