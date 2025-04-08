extends RefCounted
class_name CreateFx

var charIndex:int
var fx:int
var fxLoops:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void: 
	charIndex = reader.get_16()
	fx = reader.get_16()
	fxLoops = reader.get_16()
