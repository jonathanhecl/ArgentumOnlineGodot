extends RefCounted
class_name ChangeBankSlot

var slot:int
var index:int
var name:String
var amount:int 
var grhId:int
var type:int

var minHit:int
var maxHit:int

var maxDef:int
var minDef:int

var valor:int  # Valor del item (ReadLong en VB6)
var incompatible:bool  # Campo faltante del protocolo VB6

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	slot = reader.get_u8();
	index = reader.get_16();
	name = Utils.GetUnicodeString(reader)
	amount = reader.get_16();
	grhId = reader.get_32();  # ReadLong() en VB6 = 4 bytes
	type = reader.get_u8();
	maxHit = reader.get_16();
	minHit = reader.get_16();
	maxDef = reader.get_16();
	minDef = reader.get_16();
	valor = reader.get_32();  # ReadLong() en VB6 = 4 bytes
	incompatible = reader.get_u8();  # ReadBoolean() en VB6
