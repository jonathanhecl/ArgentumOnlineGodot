extends RefCounted
class_name CharacterChange

var charIndex:int
var body:int
var head:int
var heading:int
var weapon:int
var shield:int
var helmet:int
var fxId:int
var fxLoops:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	charIndex = reader.get_16()
	body = reader.get_16()
	head = reader.get_16()
	heading = reader.get_u8()
	weapon = reader.get_16()
	shield = reader.get_16()
	helmet = reader.get_16()
	fxId = reader.get_16()
	fxLoops = reader.get_16()
