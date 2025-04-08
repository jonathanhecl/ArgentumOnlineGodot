extends RefCounted
class_name MapData

class Sprite:
	var x:int
	var y:int
	var grhId:int
	
	func _init(pX:int = 0, pY:int = 0, pGrhId:int = 0) -> void:
		x = pX
		y = pY
		grhId = pGrhId

var layer1:PackedInt32Array
var layer2:PackedInt32Array
var layer3:Array[Sprite]
var layer4:Array[Sprite]
var flags:PackedByteArray

func _init() -> void:
	layer1.resize(100 * 100)
	layer2.resize(100 * 100)
	flags.resize(100 * 100)
