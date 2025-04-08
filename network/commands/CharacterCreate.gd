extends RefCounted
class_name CharacterCreate

var charIndex:int
var name:String

var body:int
var head:int
var helmet:int
var weapon:int
var shield:int

var x:int
var y:int
var heading:int

var fx:int
var fxLoops:int

var nickColor:int
var privileges:int

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	charIndex = reader.get_16();
	body = reader.get_16();
	head = reader.get_16();  
	heading = reader.get_u8();
	x = reader.get_u8()
	y = reader.get_u8()
	weapon = reader.get_16();
	shield = reader.get_16();
	helmet = reader.get_16();
	fx = reader.get_16();
	fxLoops = reader.get_16();
	name = Utils.GetUnicodeString(reader)
	nickColor = reader.get_u8()
	privileges = reader.get_u8()
