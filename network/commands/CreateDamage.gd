extends RefCounted
class_name CreateDamage

var x: int
var y: int
var damage: int
var color: int

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader:
		Deserialize(reader)

func Deserialize(reader: StreamPeerBuffer) -> void:
	# VB6 HandleCreateDamage: byte x, byte y, long damage, byte color
	x = reader.get_u8()
	y = reader.get_u8()
	damage = reader.get_32()
	color = reader.get_u8()
