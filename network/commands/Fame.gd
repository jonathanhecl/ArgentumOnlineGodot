extends RefCounted
class_name Fame

var AsesinoRep:int
var BandidoRep:int
var BurguesRep:int
var LadronesRep:int
var NobleRep:int
var PlebeRep:int
var Promedio:int

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader:
		Deserialize(reader)

func Deserialize(reader: StreamPeerBuffer) -> void:
	AsesinoRep = reader.get_32()
	BandidoRep = reader.get_32()
	BurguesRep = reader.get_32()
	LadronesRep = reader.get_32()
	NobleRep = reader.get_32()
	PlebeRep = reader.get_32()
	Promedio = reader.get_32()
